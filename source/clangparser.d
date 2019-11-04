module clangparser;
import std.file;
import std.string;
import std.array;
import std.stdio;
import std.uni;
import std.uuid;
import libclang;
import clangcursor;
import clangdecl;
import clanghelper;
import sliceview;

class Header
{
    string source;
    UserDecl[] types;
}

auto D3D11_KEY = "MIDL_INTERFACE(\"";
auto D2D1_KEY = "DX_DECLARE_INTERFACE(\"";
auto DWRITE_KEY = "DWRITE_DECLARE_INTERFACE(\"";

UUID getUUID(string src)
{
    if (src.startsWith(D3D11_KEY))
    {
        return parseUUID(src[D3D11_KEY.length .. $ - 2]);
    }
    else if (src.startsWith(D2D1_KEY))
    {
        return parseUUID(src[D2D1_KEY.length .. $ - 2]);
    }
    else if (src.startsWith(DWRITE_KEY))
    {
        return parseUUID(src[DWRITE_KEY.length .. $ - 2]);
    }
    else
    {
        return UUID();
    }
}

class Parser
{
    string getSource(CXCursor cursor)
    {
        auto location = getCursorLocation(cursor);
        auto header = getOrCreateHeader(cursor);
        if (!header.source)
        {
            header.source = readText(location.path);
        }

        auto src = header.source[location.begin .. location.end];
        return src;
    }

    void traverse(CXCursor cursor, Context context = Context())
    {
        // auto context = parentContext.getChild();
        auto tu = clang_Cursor_getTranslationUnit(cursor);
        auto cursorKind = cast(CXCursorKind) clang_getCursorKind(cursor);
        auto _ = getCursorKindName(cursorKind);

        auto spelling = getCursorSpelling(cursor);
        debug
        {
            if (spelling == "EXCEPTION_RECORD")
            {
                auto a = 0;
            }
            else if (spelling == "_EXCEPTION_RECORD")
            {
                auto a = 0;
            }
            else if (spelling == "PMemoryAllocator")
            {
                auto a = 0;
            }
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
        case CXCursorKind.CXCursor_UsingDeclaration:
            // skip
            break;

        case CXCursorKind.CXCursor_Namespace:
            {
                foreach (child; CXCursorIterator(cursor))
                {
                    traverse(child, context.getChild());
                }
                break;
            }

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
        case CXCursorKind.CXCursor_UnionDecl:
        case CXCursorKind.CXCursor_ClassDecl:
            parseStruct(cursor, context.enterStruct());
            break;

        case CXCursorKind.CXCursor_EnumDecl:
            parseEnum(cursor);
            break;

        case CXCursorKind.CXCursor_VarDecl:
            break;

        default:
            throw new Exception("unknwon CXCursorKind");
        }
    }

    private Decl[uint] m_declMap;
    Decl[uint] declMap()
    {
        return m_declMap;
    }

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

    void pushDecl(CXCursor cursor, Decl decl)
    {
        auto hash = clang_hashCursor(cursor);
        m_declMap[hash] = decl;
    }

    Decl getDeclFromCursor(CXCursor cursor)
    {
        // cursor = getRootCanonical(cursor);
        // hash = clang_hashCursor(cursor);
        // return m_declMap[hash];
        auto current = cursor;
        while (true)
        {
            auto hash = clang_hashCursor(current);
            auto decl = m_declMap.get(hash, null);
            if (decl)
            {
                return decl;
            }

            auto canonical = clang_getCanonicalCursor(current);
            if (canonical == current)
            {
                throw new Exception("not found");
            }
            current = canonical;
        }
    }

    Decl typeToDecl(CXCursor cursor, CXType type)
    {
        auto primitive = KindToPrimitive(type.kind);
        if (primitive)
        {
            return primitive;
        }

        if (type.kind == CXTypeKind.CXType_Pointer || type.kind == CXTypeKind
                .CXType_LValueReference)
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

        if (type.kind == CXTypeKind.CXType_IncompleteArray)
        {
            // treat as pointer
            auto isConst = clang_isConstQualifiedType(type);
            auto arrayType = clang_getArrayElementType(type);
            auto arrayDecl = typeToDecl(cursor, arrayType);
            auto arraySize = clang_getArraySize(type);
            return new Pointer(arrayDecl, isConst != 0);
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
                auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
                if (childKind == CXCursorKind.CXCursor_TypeRef)
                {
                    auto referenced = clang_getCursorReferenced(child);
                    return getDeclFromCursor(referenced);
                }
                else
                {
                    return getDeclFromCursor(child);
                }
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
                        return getDeclFromCursor(child);
                    }

                case CXCursorKind.CXCursor_TypeRef:
                    {
                        auto referenced = clang_getCursorReferenced(child);
                        // auto referencedName = getCursorSpelling(referenced);
                        // auto referencedKind = cast(CXCursorKind) clang_getCursorKind(referenced);
                        return getDeclFromCursor(referenced);
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
                        return getDeclFromCursor(referenced);
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

        if (type.kind == CXTypeKind.CXType_Unexposed)
        {
            // nullptr_t
            return new Pointer(new Void());
        }

        int a = 0;
        throw new Exception("not implemented");
    }

    Header[string] m_headers;

    string escapePath(string src)
    {
        auto escaped = src.replace("\\", "/");
        version (Windows)
        {
            escaped = escaped.toLower();
        }
        return escaped;
    }

    Header getHeader(string path)
    {
        auto escaped = escapePath(path);
        auto header = m_headers.get(escaped, null);
        if (header)
        {
            return header;
        }
        debug auto view = makeView(m_headers);
        return null;
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

    void pushTypedef(CXCursor cursor, Decl type)
    {
        auto location = getCursorLocation(cursor);
        auto name = getCursorSpelling(cursor);
        auto decl = new Typedef(location.path, location.line, name, type);
        pushDecl(cursor, decl);
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
        pushDecl(cursor, decl);
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

            case CXCursorKind.CXCursor_UnexposedAttr:
                {
                    auto src = getSource(child);
                    // auto spelling = getCursorSpelling(child);
                    // auto tokens = getTokens(child);
                    auto uuid = getUUID(src);
                    if (!uuid.empty())
                    {
                        decl.m_iid = uuid;
                    }
                }
                break;

            case CXCursorKind.CXCursor_CXXMethod:
            case CXCursorKind.CXCursor_Constructor:
            case CXCursorKind.CXCursor_Destructor:
            case CXCursorKind.CXCursor_ConversionFunction:
                break;

            case CXCursorKind.CXCursor_ObjCClassMethodDecl:
            case CXCursorKind.CXCursor_UnexposedExpr:
            case CXCursorKind.CXCursor_AlignedAttr:
            case CXCursorKind.CXCursor_CXXBaseSpecifier:
            case CXCursorKind.CXCursor_CXXAccessSpecifier:
                break;

            default:
                traverse(child, context);
                break;
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
        pushDecl(cursor, decl);
        auto header = getOrCreateHeader(cursor);
        header.types ~= decl;
    }

    void parseFunction(CXCursor cursor, bool externC)
    {
        auto location = getCursorLocation(cursor);
        auto name = getCursorSpelling(cursor);

        auto retType = clang_getCursorResultType(cursor);
        auto ret = typeToDecl(cursor, retType);

        bool dllExport = false;
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

            case CXCursorKind.CXCursor_DLLImport:
            case CXCursorKind.CXCursor_DLLExport:
                dllExport = true;
                break;

            default:
                // writeln(childKind);
                break;
            }
        }

        auto decl = new Function(location.path, location.line, name, ret,
                params, dllExport, externC);

        auto header = getOrCreateHeader(cursor);
        header.types ~= decl;
    }

    bool parse(string[] headers, string[] includes)
    {
        auto index = clang_createIndex(0, 1);
        scope (exit)
            clang_disposeIndex(index);

        string[] params = [
            "-x", "c++", "-target", "x86_64-windows-msvc",
            "-fms-compatibility-version=18", "-fdeclspec", "-fms-compatibility",
        ];
        foreach (include; includes)
        {
            params ~= format("-I%s", include);
        }

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
