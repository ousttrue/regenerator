module clangparser;
import std.array;
import std.stdio;
import libclang;
import clangcursor;
import clangtypes;
import clanghelper;

class Header
{
    UserType[] types;
}

class Parser
{
    void traverse(CXCursor cursor, Context context = Context())
    {
        // auto context = parentContext.getChild();
        auto tu = clang_Cursor_getTranslationUnit(cursor);
        auto cursorKind = cast(CXCursorKind) clang_getCursorKind(cursor);
        auto _ = getCursorKindName(cursorKind);

        auto spelling = getCursorSpelling(cursor);
        if (spelling == "EXCEPTION_RECORD")
        {
            auto a = 0;
        }
        else if (spelling == "_EXCEPTION_RECORD")
        {
            auto a = 0;
        }

        // writefln("%s%s", context.getIndent(), kind);
        switch (cursorKind)
        {
        case CXCursorKind.CXCursor_InclusionDirective:
        case CXCursorKind.CXCursor_MacroDefinition:
        case CXCursorKind.CXCursor_MacroExpansion:
        case CXCursorKind.CXCursor_ClassTemplate:
        case CXCursorKind.CXCursor_ClassTemplatePartialSpecialization:
        case CXCursorKind.CXCursor_FunctionTemplate:
            // skip
            break;

        case CXCursorKind.CXCursor_UnexposedDecl:
            {
                auto tokens = getTokens(cursor);
                scope (exit)
                    clang_disposeTokens(tu, tokens.ptr, cast(uint) tokens.length);

                if (tokens.length >= 2)
                {
                    // extern C
                    auto token0 = CXStringToString(clang_getTokenSpelling(tu, tokens[0]));
                    auto token1 = CXStringToString(clang_getTokenSpelling(tu, tokens[1]));
                    if (token0 == "extern" && token1 == "\"C\"")
                    {
                        context.isExternC = true;
                    }
                }
                foreach (child; CXCursorIterator(cursor))
                {
                    traverse(child, context.getChild());
                }
            }
            break;

        case CXCursorKind.CXCursor_TypedefDecl:
            parseTypedef(cursor);
            break;

        case CXCursorKind.CXCursor_FunctionDecl:
            parseFunction(cursor, context.isExternC);
            break;

        case CXCursorKind.CXCursor_StructDecl:
            parseStruct(cursor, context.getChild());
            break;

        case CXCursorKind.CXCursor_EnumDecl:
            parseEnum(cursor);
            break;

        case CXCursorKind.CXCursor_VarDecl:
            break;

        default:
            throw new Exception("");
        }
    }

    private Type[uint] m_typeMap;
    CXCursor getRootCanonical(CXCursor cursor)
    {
        auto current = cursor;
        while (true)
        {
            auto canonical = clang_getCanonicalCursor(current);
            if (canonical == current)
            {
                return current;
            }
            current = canonical;
        }
    }

    Type getFromCursor(CXCursor cursor)
    {
        auto hash = clang_hashCursor(child);
        auto decl = m_typeMap[hash];
        return decl;
    }

    Type typeToDecl(CXCursor cursor, CXType type)
    {
        auto primitive = KindToPrimitive(type.kind);
        if (primitive)
        {
            return primitive;
        }

        if (type.kind == CXTypeKind.CXType_Pointer)
        {
            // pointer
            auto isConst = clang_isConstQualifiedType(type);
            auto pointeeType = clang_getPointeeType(type);
            auto pointeeDecl = typeToDecl(cursor, pointeeType);
            if (!pointeeDecl)
            {
                auto location = getCursorLocation(cursor);
                auto spelling = getCursorSpelling(cursor);
                throw new Exception("no pointee");
            }
            // auto typeName = pointeeDecl.toString();
            return new Pointer(pointeeDecl, isConst != 0);
        }

        if (type.kind == CXTypeKind.CXType_ConstantArray)
        {
            auto arrayType = clang_getArrayElementType(type);
            auto arrayDecl = typeToDecl(cursor, arrayType);
            auto arraySize = clang_getArraySize(type);
            return new Array(arrayDecl, arraySize);
        }

        if (type.kind == CXTypeKind.CXType_Record)
        {
            auto children = CXCursorIterator(cursor).array();
            foreach (child; children)
            {
                return getFromCursor(child);
            }

            int a = 0;
            throw new Exception("record");
        }

        if (type.kind == CXTypeKind.CXType_Elaborated)
        {
            // struct
            auto children = CXCursorIterator(cursor).array();
            foreach (child; children)
            {
                auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
                auto childKindName = getCursorKindName(childKind);
                // writeln(kind);
                switch (childKind)
                {
                case CXCursorKind.CXCursor_StructDecl:
                case CXCursorKind.CXCursor_UnionDecl:
                case CXCursorKind.CXCursor_EnumDecl:
                    {
                        auto hash = clang_hashCursor(child);
                        auto decl = typeMap[hash];
                        return decl;
                    }

                case CXCursorKind.CXCursor_TypeRef:
                    {
                        auto referenced = clang_getCursorReferenced(child);
                        auto referencedName = getCursorSpelling(referenced);
                        auto referencedKind = cast(CXCursorKind) clang_getCursorKind(referenced);
                        auto hash = clang_hashCursor(referenced);
                        auto decl = typeMap[hash];
                        return decl;
                    }

                case CXCursorKind.CXCursor_DLLImport:
                case CXCursorKind.CXCursor_DLLExport:
                case CXCursorKind.CXCursor_UnexposedAttr:
                    // skip
                    break;

                default:
                    {
                        writeln("hoge");
                        throw new Exception("not implemented");
                    }
                }
            }

            throw new Exception("not implemented");
        }

        if (type.kind == CXTypeKind.CXType_Typedef)
        {
            auto children = CXCursorIterator(cursor).array();
            foreach (child; children)
            {
                auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
                switch (childKind)
                {
                case CXCursorKind.CXCursor_TypeRef:
                    {
                        auto referenced = clang_getCursorReferenced(child);
                        auto hash = clang_hashCursor(referenced);
                        auto decl = typeMap[hash];
                        return decl;
                    }

                case CXCursorKind.CXCursor_DLLImport:
                case CXCursorKind.CXCursor_DLLExport:
                case CXCursorKind.CXCursor_UnexposedAttr:
                    break;

                default:
                    throw new Exception("unknown");
                }
            }
            throw new Exception("no TypeRef");
        }

        if (type.kind == CXTypeKind.CXType_FunctionProto)
        {
            // return new Function(null, 0, null, null, null);
            return new Void();
        }

        int a = 0;
        throw new Exception("not implemented");
    }

    private Header[string] m_headers;

    string escapePath(string src)
    {
        return src.replace("\\", "/");
    }

    Header getHeader(string path)
    {
        return m_headers.get(escapePath(path), null);
    }

    Header getOrCreateHeader(CXCursor cursor)
    {
        auto location = getCursorLocation(cursor);
        auto found = getHeader(location.path);
        if (found)
        {
            return found;
        }

        found = new Header();
        m_headers[escapePath(location.path)] = found;
        return found;
    }

    void pushTypedef(CXCursor cursor, Type type)
    {
        auto location = getCursorLocation(cursor);
        auto name = getCursorSpelling(cursor);
        auto decl = new Typedef(location.path, location.line, name, type);
        auto hash = clang_hashCursor(cursor);
        typeMap[hash] = decl;
        auto header = getOrCreateHeader(cursor);
        header.types ~= decl;
    }

    void parseTypedef(CXCursor cursor)
    {
        auto underlying = clang_getTypedefDeclUnderlyingType(cursor);
        auto type = typeToDecl(cursor, underlying);
        pushTypedef(cursor, type);
    }

    void parseStruct(CXCursor cursor, Context context)
    {
        auto location = getCursorLocation(cursor);
        auto name = getCursorSpelling(cursor);

        // first regist
        auto decl = new Struct(location.path, location.line, name, []);
        auto hash = clang_hashCursor(cursor);
        typeMap[hash] = decl;
        auto header = getOrCreateHeader(cursor);
        header.types ~= decl;
 
        // after fields
        foreach (child; CXCursorIterator(cursor))
        {
            auto fieldName = getCursorSpelling(child);
            auto fieldKind = cast(CXCursorKind) clang_getCursorKind(child);
            auto fieldType = clang_getCursorType(child);
            switch (fieldKind)
            {
            case CXCursorKind.CXCursor_FieldDecl:
                {
                    auto fieldDecl = typeToDecl(child, fieldType);
                    decl.m_fields ~= Field(fieldName, fieldDecl);
                    break;
                }

            case CXCursorKind.CXCursor_StructDecl:
                traverse(child, context);
                break;

            case CXCursorKind.CXCursor_ObjCClassMethodDecl:
                break;

            default:
                // traverse(con)
                throw new Exception("unknown");
            }
        }

   }

    void parseEnum(CXCursor cursor)
    {
        auto location = getCursorLocation(cursor);
        auto name = getCursorSpelling(cursor);

        EnumValue[] values;
        foreach (child; CXCursorIterator(cursor))
        {
            auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
            switch (childKind)
            {
            case CXCursorKind.CXCursor_EnumConstantDecl:
                {
                    auto name = getCursorSpelling(child);
                    auto value = clang_getEnumConstantDeclValue(child);
                    values ~= EnumValue(name, value);
                }
                break;

            default:
                throw new Exception("unknown");
            }
        }

        auto decl = new Enum(location.path, location.line, name, values);
        auto hash = clang_hashCursor(cursor);
        typeMap[hash] = decl;
        auto header = getOrCreateHeader(cursor);
        header.types ~= decl;
    }

    void parseFunction(CXCursor cursor, bool externC)
    {
        auto location = getCursorLocation(cursor);
        auto name = getCursorSpelling(cursor);

        auto retType = clang_getCursorResultType(cursor);
        auto ret = typeToDecl(cursor, retType);

        Param[] params;
        foreach (child; CXCursorIterator(cursor))
        {
            auto tmp = name;
            auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
            switch (childKind)
            {
            case CXCursorKind.CXCursor_ParmDecl:
                {
                    auto paramName = getCursorSpelling(child);
                    auto paramCursorType = clang_getCursorType(child);
                    auto paramType = typeToDecl(child, paramCursorType);
                    auto paramConst = clang_isConstQualifiedType(paramCursorType);
                    auto param = Param(paramName, TypeRef(paramType, paramConst != 0));
                    params ~= param;
                }
                break;

            default:
                // writeln(childKind);
                break;
            }
        }

        auto decl = new Function(location.path, location.line, name, ret, params);
        decl.m_externC = externC;

        auto header = getOrCreateHeader(cursor);
        header.types ~= decl;
    }

    bool parse(string[] headers, string[] params)
    {
        auto index = clang_createIndex(0, 1);
        scope (exit)
            clang_disposeIndex(index);

        auto tu = getTU(index, headers, params);
        if (!tu)
        {
            return false;
        }
        scope (exit)
            clang_disposeTranslationUnit(tu);

        auto rootCursor = clang_getTranslationUnitCursor(tu);

        foreach (cursor; CXCursorIterator(rootCursor))
        {
            traverse(cursor);
        }

        return true;
    }

}
