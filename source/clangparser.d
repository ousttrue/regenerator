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
            parseStruct(cursor);
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

    Type[uint] typeMap;
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

    Type kindToType(CXCursor cursor, CXType type)
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
            auto pointee = kindToType(cursor, pointeeType);
            if (!pointee)
            {
                auto location = getCursorLocation(cursor);
                auto spelling = getCursorSpelling(cursor);
                throw new Exception("no pointee");
            }
            // auto typeName = pointee.toString();
            return new Pointer(pointee, isConst != 0);
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
                if (childKind == CXCursorKind.CXCursor_TypeRef)
                {
                    auto referenced = clang_getCursorReferenced(child);
                    auto hash = clang_hashCursor(referenced);
                    auto decl = typeMap[hash];
                    return decl;
                }
                else
                {
                    auto childKindName = getCursorKindName(childKind);
                    int a = 0;
                }
            }

            throw new Exception("no TypeRef");
        }

        if (type.kind == CXTypeKind.CXType_FunctionProto)
        {
            return new Pointer(new Void());
        }

        int a = 0;
        throw new Exception("not implemented");
    }

    Header[string] headers;

    Header getOrCreateHeader(CXCursor cursor)
    {
        auto location = getCursorLocation(cursor);
        auto found = headers.get(location.path, null);
        if (found)
        {
            return found;
        }

        found = new Header();
        headers[location.path] = found;
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
        auto type = kindToType(cursor, underlying);
        pushTypedef(cursor, type);
    }

    void parseStruct(CXCursor cursor)
    {
        auto location = getCursorLocation(cursor);
        auto name = getCursorSpelling(cursor);
        auto decl = new Struct(location.path, location.line, name);
        auto hash = clang_hashCursor(cursor);
        typeMap[hash] = decl;
        auto header = getOrCreateHeader(cursor);
        header.types ~= decl;
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
        auto ret = kindToType(cursor, retType);

        Param[] params;
        foreach (child; CXCursorIterator(cursor))
        {
            auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
            switch (childKind)
            {
            case CXCursorKind.CXCursor_ParmDecl:
                {
                    auto paramName = getCursorSpelling(cursor);
                    auto paramCursorType = clang_getCursorType(cursor);
                    auto paramType = kindToType(cursor, paramCursorType);
                    auto paramConst = clang_isConstQualifiedType(paramCursorType);
                    auto param = Param(paramName, TypeRef(paramType, paramConst != 0));
                    params ~= param;
                }
                break;

            default:
                writeln(childKind);
                break;
            }
        }

        auto decl = new Function(location.path, location.line, name, ret, params);
        decl.m_externC = externC;

        auto header = getOrCreateHeader(cursor);
        header.types ~= decl;
    }

    bool parse(string header, string[] params)
    {
        auto index = clang_createIndex(0, 1);
        scope (exit)
            clang_disposeIndex(index);

        auto tu = getTU(index, header, params);
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
