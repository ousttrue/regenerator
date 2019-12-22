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
import std.conv;
import std.bigint;
import std.experimental.logger;

struct MacroDefinition
{
    string name;
    string[] tokens;

    string toString() const
    {
        if (tokens.length == 1)
        {
            return "%s = %s".format(name, tokens[0]);
        }
        else
        {
            return "%s = %s".format(name, tokens);
        }
    }
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

int fromHex(string src)
{
    if (src[$ - 1] == 'L')
    {
        src = src[0 .. $ - 1];
    }
    auto b = BigInt(src);
    auto i = cast(int) b.toLong();
    return i;
}

UUID tokensToUUID(string[] t)
{
    auto n = fromHex("0xA1841308");
    assert(t.length == 22);
    auto src = format("%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X",
            fromHex(t[0]), fromHex(t[2]), fromHex(t[4]), fromHex(t[6]),
            fromHex(t[8]), fromHex(t[10]), fromHex(t[12]), fromHex(t[14]),
            fromHex(t[16]), fromHex(t[18]), fromHex(t[20]));
    return parseUUID(src);
    // 138, 179, 6, 14, 44, 186, 79, 35, 183, 76, 181, 45, 179, 189, 251, 70
    // ]);
}

class Parser
{
    Header[string] m_headers;
    private Decl[uint] m_declMap;
    UUID[string] m_uuidMap;

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
        debug
        {
            auto location = getCursorLocation(cursor);
            if (location.path.endsWith("d3dcompiler.h"))
            {
                if (cursorKind == CXCursorKind._MacroDefinition
                        || cursorKind == CXCursorKind._MacroExpansion)
                {
                }
                else
                {
                    int a = 0;
                }
            }
        }

        auto spelling = getCursorSpelling(cursor);

        // writefln("%s%s", context.getIndent(), kind);
        switch (cursorKind)
        {
        case CXCursorKind._InclusionDirective:
        case CXCursorKind._ClassTemplate:
        case CXCursorKind._ClassTemplatePartialSpecialization:
        case CXCursorKind._FunctionTemplate:
        case CXCursorKind._UsingDeclaration:
        case CXCursorKind._StaticAssert:
            // skip
            break;

        case CXCursorKind._MacroDefinition:
            parseMacroDefinition(cursor);
            break;

        case CXCursorKind._MacroExpansion:
            if (spelling == "DEFINE_GUID")
            {
                auto tokens = getTokens(cursor);
                scope (exit)
                    clang_disposeTokens(tu, tokens.ptr, cast(uint) tokens.length);
                string[] tokenSpellings = tokens.map!(t => tokenToString(cursor, t)).array();
                if (tokens.length == 26)
                {
                    auto name = tokenSpellings[2];
                    if (name.startsWith("IID_"))
                    {
                        name = name[4 .. $];
                    }
                    m_uuidMap[name] = tokensToUUID(tokenSpellings[4 .. $]);
                }
                else
                {
                    auto a = 0;
                }
            }
            break;

        case CXCursorKind._Namespace:
            {
                foreach (child; cursor.getChildren())
                {
                    traverse(child, context.getChild());
                }
                break;
            }

        case CXCursorKind._UnexposedDecl:
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
                foreach (child; cursor.getChildren())
                {
                    traverse(child, context.getChild());
                }
            }
            break;

        case CXCursorKind._TypedefDecl:
            parseTypedef(cursor);
            break;

        case CXCursorKind._FunctionDecl:
            debug if (spelling == "D3DCompile")
            {
                auto a = 0;
            }
            {
                auto decl = parseFunction(cursor, context.isExternC);
                if (decl)
                {
                    auto header = getOrCreateHeader(cursor);
                    header.types ~= decl;
                }
            }
            break;

        case CXCursorKind._StructDecl:
        case CXCursorKind._ClassDecl:
            parseStruct(cursor, context.enterStruct(), false);
            break;

        case CXCursorKind._UnionDecl:
            parseStruct(cursor, context.enterStruct(), true);
            break;

        case CXCursorKind._EnumDecl:
            parseEnum(cursor);
            break;

        case CXCursorKind._VarDecl:
            break;

        default:
            throw new Exception("unknwon CXCursorKind");
        }
    }

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

        if (type.kind == CXTypeKind._Pointer || type.kind == CXTypeKind._LValueReference)
        {
            // pointer
            auto pointeeType = clang_getPointeeType(type);
            auto isConst = clang_isConstQualifiedType(pointeeType);
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

        if (type.kind == CXTypeKind._IncompleteArray)
        {
            // treat as pointer
            auto isConst = clang_isConstQualifiedType(type);
            auto arrayType = clang_getArrayElementType(type);
            auto arrayDecl = typeToDecl(cursor, arrayType);
            auto arraySize = clang_getArraySize(type);
            return new Pointer(arrayDecl, isConst != 0);
        }

        if (type.kind == CXTypeKind._ConstantArray)
        {
            auto arrayType = clang_getArrayElementType(type);
            auto arrayDecl = typeToDecl(cursor, arrayType);
            auto arraySize = clang_getArraySize(type);
            return new Array(arrayDecl, arraySize);
        }

        if (type.kind == CXTypeKind._Record)
        {
            auto children = cursor.getChildren();
            foreach (child; children)
            {
                auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
                if (childKind == CXCursorKind._TypeRef)
                {
                    auto referenced = clang_getCursorReferenced(child);
                    return getDeclFromCursor(referenced);
                }
                // else
                // {
                //     return getDeclFromCursor(child);
                // }
            }

            int a = 0;
            throw new Exception("record");
        }

        if (type.kind == CXTypeKind._Elaborated)
        {
            // struct
            foreach (child; cursor.getChildren())
            {
                auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
                auto childKindName = getCursorKindName(childKind);
                // writeln(kind);
                switch (childKind)
                {
                case CXCursorKind._StructDecl:
                case CXCursorKind._UnionDecl:
                case CXCursorKind._EnumDecl:
                    {
                        return getDeclFromCursor(child);
                    }

                case CXCursorKind._TypeRef:
                    {
                        auto referenced = clang_getCursorReferenced(child);
                        debug auto referencedName = getCursorSpelling(referenced);
                        debug auto referencedKind = cast(CXCursorKind) clang_getCursorKind(
                                referenced);
                        return getDeclFromCursor(referenced);
                    }

                case CXCursorKind._DLLImport:
                case CXCursorKind._DLLExport:
                case CXCursorKind._UnexposedAttr:
                    // skip
                    break;

                default:
                    {
                        throw new Exception("not implemented");
                    }
                }
            }

            throw new Exception("not implemented");
        }

        if (type.kind == CXTypeKind._Typedef)
        {
            foreach (child; cursor.getChildren())
            {
                auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
                switch (childKind)
                {
                case CXCursorKind._TypeRef:
                    {
                        auto referenced = clang_getCursorReferenced(child);
                        return getDeclFromCursor(referenced);
                    }

                case CXCursorKind._DLLImport:
                case CXCursorKind._DLLExport:
                case CXCursorKind._UnexposedAttr:
                    break;

                default:
                    throw new Exception("unknown");
                }
            }
            throw new Exception("no TypeRef");
        }

        if (type.kind == CXTypeKind._FunctionProto)
        {
            // return new Function(null, 0, null, null, null);
            return new Void();
        }

        if (type.kind == CXTypeKind._Unexposed)
        {
            // nullptr_t
            return new Pointer(new Void());
        }

        int a = 0;
        throw new Exception("not implemented");
    }

    Header getHeader(string path)
    {
        auto header = m_headers.get(path, null);
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
        m_headers[location.path] = found;
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
                if (userType && !userType.name)
                {
                    // set typedef name
                    userType.name = typedefDecl.name;
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
        decl.isUnion = isUnion;
        decl.forwardDecl = is_forward_declaration(cursor);
        if (!decl.forwardDecl)
        {
            auto canonical = clang_getCanonicalCursor(cursor);
            if (canonical != cursor)
            {
                Struct forwardDecl = cast(Struct) m_declMap[clang_hashCursor(canonical)];
                forwardDecl.definition = decl;
            }
        }
        pushDecl(cursor, decl);
        auto header = getOrCreateHeader(cursor);
        header.types ~= decl;

        // after fields
        foreach (child; cursor.getChildren())
        {
            auto fieldName = getCursorSpelling(child);
            auto fieldKind = cast(CXCursorKind) clang_getCursorKind(child);
            auto fieldType = clang_getCursorType(child);
            switch (fieldKind)
            {
            case CXCursorKind._FieldDecl:
                {
                    auto fieldDecl = typeToDecl(child, fieldType);
                    decl.fields ~= Field(fieldName, fieldDecl);
                    break;
                }

            case CXCursorKind._UnexposedAttr:
                {
                    auto src = getSource(child);
                    auto uuid = getUUID(src);
                    if (!uuid.empty())
                    {
                        decl.iid = uuid;
                    }
                }
                break;

            case CXCursorKind._CXXMethod:
                {
                    Function method = parseFunction(child, false);
                    decl.methods ~= method;
                }
                break;

            case CXCursorKind._Constructor:
            case CXCursorKind._Destructor:
            case CXCursorKind._ConversionFunction:
                break;

            case CXCursorKind._ObjCClassMethodDecl:
            case CXCursorKind._UnexposedExpr:
            case CXCursorKind._AlignedAttr:
            case CXCursorKind._CXXAccessSpecifier:
                break;

            case CXCursorKind._CXXBaseSpecifier:
                {
                    foreach (base; child.getChildren())
                    {
                        auto baseKind = cast(CXCursorKind) clang_getCursorKind(base);
                        if (baseKind == CXCursorKind._TypeRef)
                        {
                            auto referenced = clang_getCursorReferenced(base);
                            auto referencedKind = cast(CXCursorKind) clang_getCursorKind(referenced);
                            debug auto referencedKindName = getCursorKindName(referencedKind);
                            auto baseDecl = cast(UserDecl) getDeclFromCursor(referenced);
                            assert(baseDecl);
                            decl.base = baseDecl;
                        }
                    }
                }
                break;

            default:
                traverse(child, context);
                if (CXCursorKind._StructDecl || CXCursorKind._ClassDecl || CXCursorKind._UnionDecl)
                {
                    if (fieldName == "")
                    {
                        // anonymous
                        auto fieldDecl = getDeclFromCursor(child);
                        decl.fields ~= Field(fieldName, fieldDecl);
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
        foreach (child; cursor.getChildren())
        {
            auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
            switch (childKind)
            {
            case CXCursorKind._EnumConstantDecl:
                {
                    auto childName = getCursorSpelling(child);
                    auto childValue = clang_getEnumConstantDeclUnsignedValue(child);
                    values ~= EnumValue(childName, childValue);
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
            if (name == "D3DDisassemble10Effect")
            {
                return null;
            }
        }

        auto retType = clang_getCursorResultType(cursor);
        auto ret = typeToDecl(cursor, retType);

        bool dllExport = false;
        Param[] params;
        foreach (child; cursor.getChildren())
        {
            debug auto tmp = name;
            auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
            auto childName = getCursorSpelling(child);
            switch (childKind)
            {
            case CXCursorKind._TypeRef:
            case CXCursorKind._WarnUnusedResultAttr:
                break;

            case CXCursorKind._ParmDecl:
                {
                    auto paramCursorType = clang_getCursorType(child);
                    auto paramType = typeToDecl(child, paramCursorType);
                    auto paramConst = clang_isConstQualifiedType(paramCursorType);
                    auto param = Param(childName, TypeRef(paramType, paramConst != 0));
                    params ~= param;
                }
                break;

            case CXCursorKind._DLLImport:
            case CXCursorKind._DLLExport:
                dllExport = true;
                break;

            case CXCursorKind._UnexposedAttr:
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

        if (clang_Cursor_isMacroFunctionLike(cursor))
        {
            return;
        }

        // auto src = getSource(cursor);
        auto tu = clang_Cursor_getTranslationUnit(cursor);
        auto tokens = getTokens(cursor);
        scope (exit)
            clang_disposeTokens(tu, tokens.ptr, cast(uint) tokens.length);
        // assert(tokens.length);
        if (tokens.length == 1)
        {
            // #define DEBUG
            return;
        }

        string[] tokenSpellings = tokens.map!(t => tokenToString(cursor, t)).array();

        // debug if (tokenSpellings[0] == "MAKE_D3D11_HRESULT")
        // {
        //     auto a = 0;
        // }

        // debug auto view = makeView(tokenSpellings);

        auto header = getOrCreateHeader(cursor);
        header.m_macros ~= MacroDefinition(tokenSpellings[0], tokenSpellings[1 .. $]);
    }

    bool parse(string[] headers, string[] includes, string[] defines, bool externC)
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
        foreach (define; defines)
        {
            params ~= format("-D%s", define);
        }

        log(params);
        auto tu = getTU(index, headers, params);
        if (!tu)
        {
            return false;
        }
        scope (exit)
            clang_disposeTranslationUnit(tu);

        auto rootCursor = clang_getTranslationUnitCursor(tu);
        auto children = rootCursor.getChildren();
        foreach (cursor; children)
        {
            traverse(cursor, Context(0, externC, false));
        }
        return true;
    }
}
