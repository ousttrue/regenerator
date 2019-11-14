module clangparser;
import std.typecons : Tuple;
import std.algorithm;
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

struct MacroDefinition
{
    string name;
    string value;
}

class Header
{
    string source;
    UserDecl[] types;
    MacroDefinition[] m_macros;
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
        case CXCursorKind.CXCursor_MacroExpansion:
        case CXCursorKind.CXCursor_ClassTemplate:
        case CXCursorKind.CXCursor_ClassTemplatePartialSpecialization:
        case CXCursorKind.CXCursor_FunctionTemplate:
        case CXCursorKind.CXCursor_UsingDeclaration: // skip
            break;

        case CXCursorKind.CXCursor_MacroDefinition:
            parseMacroDefinition(cursor);
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
                    if (tokenToString(cursor, tokens[0]) == "extern"
                            && tokenToString(cursor, tokens[1]) == "\"C\"")
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
            {
                auto decl = parseFunction(cursor, context.isExternC);
                auto header = getOrCreateHeader(cursor);
                header.types ~= decl;
            }
            break;

        case CXCursorKind.CXCursor_StructDecl:
        case CXCursorKind.CXCursor_ClassDecl:
            parseStruct(cursor, context.enterStruct(), false);
            break;

        case CXCursorKind.CXCursor_UnionDecl:
            parseStruct(cursor, context.enterStruct(), true);
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

    uint pushDecl(CXCursor cursor, Decl decl)
    {
        auto hash = clang_hashCursor(cursor);
        assert(hash !in m_declMap);
        assert(decl);
        m_declMap[hash] = decl;
        return hash;
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

    void resolveTypedef()
    {
        foreach (k, v; m_declMap)
        {
            Typedef typedefDecl = cast(Typedef) v;
            if (typedefDecl)
            {
                UserDecl userType = cast(UserDecl) typedefDecl.m_typeref.type;
                if (userType && !userType.m_name)
                {
                    // set typedef name
                    userType.m_name = typedefDecl.m_name;
                }
            }
        }
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

    // private void replace(uint hash, Struct src)
    // {
    //     auto dst = src.m_definition;
    //     assert(dst);
    //     foreach (k, v; m_declMap)
    //     {
    //         if (v == src)
    //         {
    //             assert(k == hash);
    //         }
    //         else
    //         {
    //             v.replace(src, dst, []);
    //         }
    //     }

    //     m_declMap[hash] = dst;
    // }

    // void resolveForwardDecl()
    // {
    //     Decl[uint] map;
    //     foreach (k, v; m_declMap)
    //     {
    //         Struct structDecl = cast(Struct) v;
    //         if (structDecl && structDecl.m_forwardDecl && structDecl.m_definition)
    //         {
    //             replace(k, structDecl);
    //             map[k] = structDecl.m_definition;
    //         }
    //         else
    //         {
    //             map[k] = v;
    //         }
    //     }
    //     m_declMap = map;
    // }

    // https://joshpeterson.github.io/identifying-a-forward-declaration-with-libclang
    static bool is_forward_declaration(CXCursor cursor)
    {
        auto definition = clang_getCursorDefinition(cursor);

        // If the definition is null, then there is no definition in this translation
        // unit, so this cursor must be a forward declaration.
        if (clang_equalCursors(definition, clang_getNullCursor()))
            return true;

        // If there is a definition, then the forward declaration and the definition
        // are in the same translation unit. This cursor is the forward declaration if
        // it is _not_ the definition.
        return !clang_equalCursors(cursor, definition);
    }

    void parseStruct(CXCursor cursor, Context context, bool isUnion)
    {
        auto location = getCursorLocation(cursor);
        auto name = getCursorSpelling(cursor);

        // first regist
        auto decl = new Struct(location.path, location.line, name);
        decl.m_isUnion = isUnion;
        decl.m_forwardDecl = is_forward_declaration(cursor);
        if (!decl.m_forwardDecl)
        {
            auto canonical = clang_getCanonicalCursor(cursor);
            if (canonical != cursor)
            {
                Struct forwardDecl = cast(Struct) m_declMap[clang_hashCursor(canonical)];
                forwardDecl.m_definition = decl;
            }
        }
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
                    auto uuid = getUUID(src);
                    if (!uuid.empty())
                    {
                        decl.m_iid = uuid;
                    }
                }
                break;

            case CXCursorKind.CXCursor_CXXMethod:
                {
                    Function method = parseFunction(child, false);
                    decl.m_methods ~= method;
                }
                break;

            case CXCursorKind.CXCursor_Constructor:
            case CXCursorKind.CXCursor_Destructor:
            case CXCursorKind.CXCursor_ConversionFunction:
                break;

            case CXCursorKind.CXCursor_ObjCClassMethodDecl:
            case CXCursorKind.CXCursor_UnexposedExpr:
            case CXCursorKind.CXCursor_AlignedAttr:
            case CXCursorKind.CXCursor_CXXAccessSpecifier:
                break;

            case CXCursorKind.CXCursor_CXXBaseSpecifier:
                {
                    foreach (base; CXCursorIterator(child))
                    {
                        auto baseKind = cast(CXCursorKind) clang_getCursorKind(base);
                        if (baseKind == CXCursorKind.CXCursor_TypeRef)
                        {
                            auto referenced = clang_getCursorReferenced(base);
                            auto referencedKind = cast(CXCursorKind) clang_getCursorKind(referenced);
                            debug auto referencedKindName = getCursorKindName(referencedKind);
                            auto baseDecl = cast(UserDecl) getDeclFromCursor(referenced);
                            assert(baseDecl);
                            decl.m_base = baseDecl;
                        }
                    }
                }
                break;

            default:
                traverse(child, context);
                if (CXCursorKind.CXCursor_StructDecl
                        || CXCursorKind.CXCursor_ClassDecl || CXCursorKind.CXCursor_UnionDecl)
                {
                    if (fieldName == "")
                    {
                        // anonymous
                        auto fieldDecl = getDeclFromCursor(child);
                        decl.m_fields ~= Field(fieldName, fieldDecl);
                    }
                }
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
                    auto value = clang_getEnumConstantDeclUnsignedValue(child);
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

    Function parseFunction(CXCursor cursor, bool externC)
    {
        auto location = getCursorLocation(cursor);
        auto name = getCursorSpelling(cursor);
        debug
        {
            if (name == "D3D11CreateDevice")
            {
                auto a = 0;
            }
        }

        auto retType = clang_getCursorResultType(cursor);
        auto ret = typeToDecl(cursor, retType);

        bool dllExport = false;
        Param[] params;
        foreach (child; CXCursorIterator(cursor))
        {
            debug auto tmp = name;
            auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
            auto childName = getCursorSpelling(child);
            switch (childKind)
            {
            case CXCursorKind.CXCursor_TypeRef:
            case CXCursorKind.CXCursor_WarnUnusedResultAttr:
                break;

            case CXCursorKind.CXCursor_ParmDecl:
                {
                    auto paramCursorType = clang_getCursorType(child);
                    auto paramType = typeToDecl(child, paramCursorType);
                    auto paramConst = clang_isConstQualifiedType(paramCursorType);
                    auto param = Param(childName, TypeRef(paramType, paramConst != 0));
                    params ~= param;
                }
                break;

            case CXCursorKind.CXCursor_DLLImport:
            case CXCursorKind.CXCursor_DLLExport:
                dllExport = true;
                break;

            case CXCursorKind.CXCursor_UnexposedAttr:
                {

                }
                break;

            default:
                // writeln(childKind);
                int a = 0;
                throw new Exception("unknown param type");
            }
        }

        auto decl = new Function(location.path, location.line, name, ret,
                params, dllExport, externC);
        return decl;
    }

    void parseMacroDefinition(CXCursor cursor)
    {
        auto location = getCursorLocation(cursor);
        if (!location.path)
        {
            return;
        }

        // auto src = getSource(cursor);
        auto tu = clang_Cursor_getTranslationUnit(cursor);
        auto tokens = getTokens(cursor);
        scope (exit)
            clang_disposeTokens(tu, tokens.ptr, cast(uint) tokens.length);
        assert(tokens.length);
        if (tokens.length == 1)
        {
            return;
        }

        string[] tokenSpellings = tokens.map!(t => tokenToString(cursor, t)).array();
        // debug auto view = makeView(tokenSpellings);
        if (tokenSpellings[1] == "(" && !tokenSpellings[2 .. $ - 1].find(")").empty)
        {
            // #define hoge() body
            return;
        }

        debug
        {
            if (tokenSpellings[0] == "D3D11_SDK_VERSION")
            {
                auto a = 0;
            }
            // DXGI_USAGE_RENDER_TARGET_OUTPUT
        }

        auto header = getOrCreateHeader(cursor);
        header.m_macros ~= MacroDefinition(tokenSpellings[0], tokenSpellings[1 .. $].join(" "));
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
