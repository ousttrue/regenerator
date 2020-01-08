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
import std.exception;

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
    private UserDecl[uint] m_declMap;
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
                    debug auto a = 0;
                }
            }
            break;

        case CXCursorKind._Namespace:
            {
                context = context.enterNamespace(spelling);
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
            {
                auto decl = parseFunction(cursor, &context);
                if (decl)
                {
                    auto header = getOrCreateHeader(cursor);
                    header.types ~= decl;
                }
            }
            break;

        case CXCursorKind._StructDecl:
        case CXCursorKind._ClassDecl:
            parseStruct(cursor, context.enterNamespace(spelling), false);
            break;

        case CXCursorKind._UnionDecl:
            parseStruct(cursor, context.enterNamespace(spelling), true);
            break;

        case CXCursorKind._EnumDecl:
            parseEnum(cursor);
            break;

        case CXCursorKind._VarDecl:
            break;

        default:
            throw new Exception("unknown CXCursorKind");
        }
    }

    UserDecl[uint] declMap()
    {
        return m_declMap;
    }

    uint pushDecl(CXCursor cursor, UserDecl decl)
    {
        auto hash = clang_hashCursor(cursor);
        assert(hash !in m_declMap);
        assert(decl);
        decl.hash = hash;
        m_declMap[hash] = decl;
        return hash;
    }

    UserDecl getDeclFromCursor(CXCursor cursor)
    {
        auto current = cursor;
        while (true)
        {
            auto hash = clang_hashCursor(current);
            auto decl = m_declMap.get(hash, null);
            if (decl)
            {
                decl.useCount++;
                return decl;
            }

            // Get forward decl.
            // May not yet have a complete definition.
            auto canonical = clang_getCanonicalCursor(current);
            if (canonical == current)
            {
                throw new Exception("not found");
            }
            current = canonical;
        }
    }

    ///
    /// * Primitiveを得る
    /// * 参照型を構築する(Pointer, Reference, Array...)
    /// * User型(Struct, Enum, Typedef)への参照を得る(cursor.children の CXCursorKind._TypeRef から)
    /// * 無名型(Struct)への参照を得る
    /// * Functionの型(struct field, function param/return, typedef)を得る
    ///
    Decl typeToDecl(CXType type, CXCursor cursor)
    {
        auto primitive = KindToPrimitive(type.kind);
        if (primitive)
        {
            return primitive;
        }

        if (type.kind == CXTypeKind._Unexposed)
        {
            // nullptr_t
            return new Pointer(new Void());
        }

        if (type.kind == CXTypeKind._Pointer)
        {
            auto pointeeType = clang_getPointeeType(type);
            auto isConst = clang_isConstQualifiedType(pointeeType);
            auto pointeeDecl = typeToDecl(pointeeType, cursor);
            enforce(pointeeDecl, "pointer type not found");
            return new Pointer(pointeeDecl, isConst != 0);
        }

        if (type.kind == CXTypeKind._LValueReference)
        {
            auto pointeeType = clang_getPointeeType(type);
            auto isConst = clang_isConstQualifiedType(pointeeType);
            auto pointeeDecl = typeToDecl(pointeeType, cursor);
            enforce(pointeeDecl, "reference type not found");
            return new Reference(pointeeDecl, isConst != 0);
        }

        if (type.kind == CXTypeKind._IncompleteArray)
        {
            auto arrayType = clang_getArrayElementType(type);
            auto isConst = clang_isConstQualifiedType(type);
            auto pointeeDecl = typeToDecl(arrayType, cursor);
            enforce(pointeeDecl, "array[] type not found");
            // auto arraySize = clang_getArraySize(type);
            return new Pointer(pointeeDecl, isConst != 0);
        }

        if (type.kind == CXTypeKind._ConstantArray)
        {
            auto arrayType = clang_getArrayElementType(type);
            auto pointeeDecl = typeToDecl(arrayType, cursor);
            auto arraySize = clang_getArraySize(type);
            enforce(pointeeDecl, "array[x] type not found");
            return new Array(pointeeDecl, arraySize);
        }

        if (type.kind == CXTypeKind._FunctionProto)
        {
            auto dummy = Context();
            auto decl = parseFunction(cursor, &dummy);
            return decl;
        }

        // 子カーソルから型を得る
        foreach (child; cursor.getChildren())
        {
            auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
            switch (childKind)
            {
            case CXCursorKind._StructDecl:
            case CXCursorKind._UnionDecl:
            case CXCursorKind._EnumDecl:
                {
                    // 宣言
                    // tag名無し？
                    enforce(type.kind == CXTypeKind._Elaborated, "not elaborated");
                    return getDeclFromCursor(child);
                }

            case CXCursorKind._TypeRef:
                {
                    enforce(type.kind == CXTypeKind._Record || type.kind == CXTypeKind._Typedef
                            || type.kind == CXTypeKind._Elaborated, "not record or typedef");
                    // auto referenced = clang_getCursorReferenced(child);
                    // return getDeclFromCursor(referenced);
                    // auto referenced = clang_getCursorReferenced(child);
                    // return getDeclFromCursor(referenced);
                    auto referenced = clang_getCursorReferenced(child);
                    return getDeclFromCursor(referenced);
                }

                // case CXCursorKind._DLLImport:
                // case CXCursorKind._DLLExport:
                // case CXCursorKind._UnexposedAttr:
                //     // skip
                //     break;

            default:
                {
                    // debug auto a = 0;
                    // throw new Exception("unknown");
                    break;
                }
            }
        }

        debug
        {
            int a = 0;
        }
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
                UserDecl userType = cast(UserDecl) typedefDecl.typeref.type;
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
        auto type = typeToDecl(underlying, cursor);
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

        auto decl = new Struct(location.path, location.line, name);
        decl.namespace = context.namespace;
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
        // push before fields
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
                    auto fieldOffset = clang_Cursor_getOffsetOfField(child);
                    auto fieldDecl = typeToDecl(fieldType, child);
                    auto fieldConst = clang_isConstQualifiedType(fieldType);
                    decl.fields ~= Field(fieldOffset, fieldName,
                            TypeRef(fieldDecl, fieldConst != 0));
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
                    Function method = parseFunction(child, &context);
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
                            auto baseDecl = getDeclFromCursor(referenced);
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
                        auto fieldOffset = clang_Cursor_getOffsetOfField(child);
                        auto fieldDecl = getDeclFromCursor(child);
                        auto fieldConst = clang_isConstQualifiedType(fieldType);
                        decl.fields ~= Field(fieldOffset, fieldName,
                                TypeRef(fieldDecl, fieldConst != 0));
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

    Function parseFunction(CXCursor cursor, const Context* context)
    {
        auto location = getCursorLocation(cursor);
        auto name = getCursorSpelling(cursor);

        auto retType = clang_getCursorResultType(cursor);
        auto ret = retType.kind == CXTypeKind._Invalid ? new Void() : typeToDecl(retType, cursor);
        auto tu = clang_Cursor_getTranslationUnit(cursor);

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
                    debug
                    {
                        if (name == "ShowDemoWindow")
                        {
                        }
                    }
                    auto paramCursorType = clang_getCursorType(child);
                    auto paramType = typeToDecl(paramCursorType, child);
                    auto paramConst = clang_isConstQualifiedType(paramCursorType);

                    auto param = Param(childName, TypeRef(paramType, paramConst != 0));

                    foreach (x; getChildren(child))
                    {
                        auto xKind = cast(CXCursorKind) clang_getCursorKind(x);
                        // if (xKind == CXCursorKind._FirstExpr)
                        {
                            // default value
                            auto tokens = getTokens(child);
                            scope (exit)
                                clang_disposeTokens(tu, tokens.ptr, cast(uint) tokens.length);
                            string[] tokenSpellings = tokens.map!(t => tokenToString(child,
                                    t)).array();
                            auto found = tokenSpellings.countUntil!(a => a == "=");
                            if (found != -1)
                            {
                                param.values = tokenSpellings[found + 1 .. $];
                                debug auto a = 0;
                            }
                            else
                            {
                                debug auto a = 0;
                            }
                        }
                        break;
                    }

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
                debug int a = 0;
                throw new Exception("unknown param type");
            }
        }

        auto decl = new Function(location.path, location.line, name, ret,
                params, dllExport, context.isExternC);
        decl.namespace = context.namespace;
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

        auto tu = clang_Cursor_getTranslationUnit(cursor);
        auto tokens = getTokens(cursor);
        scope (exit)
            clang_disposeTokens(tu, tokens.ptr, cast(uint) tokens.length);
        if (tokens.length == 1)
        {
            return;
        }

        string[] tokenSpellings = tokens.map!(t => tokenToString(cursor, t)).array();

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
            traverse(cursor, Context(0, externC));
        }
        return true;
    }
}
