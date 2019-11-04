module dexporter;
import std.string;
import std.stdio;
import std.path;
import std.file;
import std.algorithm;
import core.sys.windows.windef;
import core.sys.windows.basetyps;
import clangdecl;
import clangparser;
import sliceview;

string DEscapeName(string src)
{
    switch (src)
    {
    case "module":
        return "_module";

    default:
        return src;
    }
}

static bool isInterface(Decl decl)
{
    Typedef typedefDecl = cast(Typedef) decl;
    if (typedefDecl)
    {
        debug
        {
            if (typedefDecl.m_name == "ID3D11DeviceContext")
            {
                auto a = 0;
            }
        }
        decl = typedefDecl.m_typeref.type;
    }

    Struct structDecl = cast(Struct) decl;
    if (!structDecl)
    {
        return false;
    }

    if (structDecl.m_definition)
    {
        // resolve forward decl
        structDecl = structDecl.m_definition;
    }

    bool empty = structDecl.m_iid.empty();
    return !empty;
}

string DPointer(Pointer t)
{
    if (isInterface(t.m_typeref.type))
    {
        return format("%s", DType(t.m_typeref.type));
    }
    else
    {
        return format("%s*", DType(t.m_typeref.type));
    }
}

string DArray(Array t)
{
    return format("%s[%d]", DType(t.m_typeref.type), t.m_size);
}

string DType(Decl t)
{
    return castSwitch!((Pointer decl) => DPointer(decl),
            (Array decl) => DArray(decl), (UserDecl decl) => decl.m_name, //
            (Void _) => "void", (Bool _) => "bool", (Int8 _) => "byte",
            (Int16 _) => "short", (Int32 _) => "int", (Int64 _) => "long",
            (UInt8 _) => "ubyte", (UInt16 _) => "ushort", (UInt32 _) => "uint",
            (UInt64 _) => "ulong", (Float _) => "float", (Double _) => "double", //
            () => format("unknown(%s)", t))(t);
}

void DTypedefDecl(File* f, Typedef t)
{
    auto dst = DType(t.m_typeref.type);
    if (dst)
    {
        if (t.m_name == dst)
        {
            // f.writefln("// samename: %s", t.m_name);
            return;
        }

        f.writefln("alias %s = %s;", t.m_name, dst);
        return;
    }

    // nameless
    f.writeln("// typedef target nameless");
}

void DStructDecl(File* f, Struct decl, string typedefName = null)
{
    // assert(!decl.m_forwardDecl);
    auto name = typedefName ? typedefName : decl.m_name;
    if (!name)
    {
        f.writeln("// struct nameless");
        return;
    }
    debug
    {
        if (name == "IDXGIAdapter")
        {
            auto a = 0;
        }
    }

    if (decl.m_iid.empty())
    {
        // struct
        if (decl.m_fields.empty())
        {
            return;
        }

        f.writefln("struct %s", name);
        f.writeln("{");
        foreach (field; decl.m_fields)
        {
            auto typeName = DType(field.type);
            if (!typeName)
            {
                // anonymous union, struct
                f.writefln("   // anonymous %s;", DEscapeName(field.name));
            }
            else
            {
                f.writefln("   %s %s;", typeName, DEscapeName(field.name));
            }
        }
        f.writeln("}");
    }
    else
    {
        // interface
        f.writefln("interface %s", name);
        f.writeln("{");
        // methods
        foreach (method; decl.m_methods)
        {
            DFucntionDecl(f, method, "    ");
        }
        f.writeln("}");
    }
}

void DEnumDecl(File* f, Enum decl)
{
    if (!decl.m_name)
    {
        f.writeln("// enum nameless");
        return;
    }

    debug auto values = makeView(decl.m_values);

    f.writef("enum %s", decl.m_name);
    auto maxValue = decl.maxValue;
    if (maxValue > uint.max)
    {
        f.write(": ulong");
    }
    f.writeln();
    f.writeln("{");
    foreach (value; decl.m_values)
    {
        f.writefln("    %s = 0x%x,", value.name, value.value);
    }
    f.writeln("}");
}

void DFucntionDecl(File* f, Function decl, string indent)
{
    if (!decl.m_dllExport)
    {
        auto retType = cast(UserDecl) decl.m_ret;
        if (!retType)
        {
            return;
        }
        if (retType.m_name != "HRESULT")
        {
            return;
        }
        debug auto isCom = true; // D3D11CreateDevice ... etc
    }
    f.write(indent);
    if (decl.m_externC)
    {
        f.write("extern(C) ");
    }
    f.write(DType(decl.m_ret));
    f.write(" ");
    f.write(decl.m_name);
    f.write("(");

    auto isFirst = true;
    foreach (param; decl.m_params)
    {
        if (isFirst)
        {
            isFirst = false;
        }
        else
        {
            f.write(", ");
        }
        f.write(format("%s %s", DType(param.typeRef.type), DEscapeName(param.name)));
    }
    f.writeln(");");
}

void DDecl(File* f, Decl decl)
{
    castSwitch!((Typedef decl) => DTypedefDecl(f, decl),
            (Enum decl) => DEnumDecl(f, decl), (Struct decl) => DStructDecl(f,
                decl), (Function decl) => DFucntionDecl(f, decl, ""))(decl);
}

class DSource
{
    string[] m_modules;
    string m_path;
    string getName()
    {
        return m_path.baseName.stripExtension;
    }

    UserDecl[] m_types;
    DSource[] m_imports;

    this(string path)
    {
        m_path = path;
    }

    static WINDEF = "core.sys.windows.windef";
    static string[] windowsSymbols = [__traits(allMembers, core.sys.windows.windef)];
    bool includeWindef(string name)
    {
        // import core.sys.windows.windows;
        // に含まれていれば追加せずにフラグを立てる
        debug auto symbols = makeView(windowsSymbols);
        auto found = windowsSymbols.find(name);
        if (!found.empty)
        {
            if (!m_modules.find(WINDEF).empty())
            {
                m_modules ~= WINDEF;
                return true;
            }
        }
        return false;
    }
    static BASETYPS = "core.sys.windows.basetyps";
    static string[] basetypsSymbols = [__traits(allMembers, core.sys.windows.basetyps)];
    bool includeBasetyps(string name)
    {
        if(!basetypsSymbols.find(name).empty)
        {
            if(!m_modules.find(BASETYPS).empty)
            {
                m_modules ~= BASETYPS;
                return true;
            }
        }
        return false;
    }

    void addDecl(UserDecl type)
    {
        if (m_types.find(type).any())
        {
            return;
        }

        if (includeWindef(type.m_name))
        {
            return;
        }
        if (includeBasetyps(type.m_name))
        {
            return;
        }

        m_types ~= type;
        return;
    }

    void addImport(DSource source)
    {
        if (m_path == source.m_path)
        {
            return;
        }
        if (m_imports.find(source).any())
        {
            return;
        }
        m_imports ~= source;
    }

    void writeTo(string dir)
    {
        auto packageName = dir.baseName.stripExtension;

        // open
        auto path = format("%s/%s.d", dir, getName());
        // writeln(stem);
        writefln("writeTo: %s(%d)", path, m_types.length);

        mkdirRecurse(dir);
        {
            auto f = File(path, "w");
            f.writefln("module %s.%s;", packageName, getName());

            string[] modules;
            foreach (src; m_imports)
            {
                f.writefln("import %s.%s;", packageName, src.getName());
                foreach(m; src.m_modules)
                {
                    if(modules.find(m).empty)
                    {
                        f.writefln("import %s;", m);
                        modules ~= m;
                    }
                }
            }
            foreach (decl; m_types)
            {
                DDecl(&f, decl);
            }
        }
    }
}

class DExporter
{
    Parser m_parser;

    this(Parser parser)
    {
        m_parser = parser;
    }

    DSource[string] m_sourceMap;

    DSource getOrCreateSource(string path)
    {
        auto source = m_sourceMap.get(path, null);
        if (!source)
        {
            source = new DSource(path);
            m_sourceMap[path] = source;
        }
        return source;
    }

    Decl stripPointer(Decl decl)
    {
        while (true)
        {
            Pointer pointer = cast(Pointer) decl;
            Array array = cast(Array) decl;
            if (pointer)
            {
                decl = pointer.m_typeref.type;
            }
            else if (array)
            {
                decl = array.m_typeref.type;
            }
            else
            {
                return decl;
            }
        }

        // throw new Exception("not reach here");
    }

    UserDecl getDefinition(UserDecl decl)
    {
        Struct structdecl = cast(Struct) decl;
        if (!structdecl)
        {
            return decl;
        }
        if (!structdecl.m_forwardDecl)
        {
            return decl;
        }

        auto definition = structdecl.m_definition;
        debug
        {
            if (decl.m_name == "IDXGIAdapter")
            {
                auto a = 0;
            }
        }
        return definition;
    }

    void addDecl(Decl[] _decl, DSource[] from = [])
    {
        foreach (d; _decl[0 .. $ - 1])
        {
            if (d == _decl[$ - 1])
            {
                // stop resursion
                return;
            }
        }

        auto decl = cast(UserDecl) stripPointer(_decl[$ - 1]);
        if (!decl)
        {
            return;
        }
        decl = getDefinition(decl);

        auto dsource = getOrCreateSource(decl.m_path);
        dsource.addDecl(decl);

        bool found = false;
        foreach (f; from)
        {
            f.addImport(dsource);
            if (f == dsource)
            {
                found = true;
            }
        }
        if (!found)
        {
            from ~= dsource;
        }

        Function functionDecl = cast(Function) decl;
        Typedef typedefDecl = cast(Typedef) decl;
        Struct structDecl = cast(Struct) decl;
        if (functionDecl)
        {
            addDecl(_decl ~ functionDecl.m_ret, from);
            foreach (param; functionDecl.m_params)
            {
                addDecl(_decl ~ param.typeRef.type, from);
            }
        }
        else if (typedefDecl)
        {
            addDecl(_decl ~ typedefDecl.m_typeref.type, from);
        }
        else if (structDecl)
        {
            foreach (field; structDecl.m_fields)
            {
                addDecl(_decl ~ field.type, from);
            }
            foreach (method; structDecl.m_methods)
            {
                addDecl(_decl ~ method.m_ret, from);
                foreach (param; method.m_params)
                {
                    addDecl(_decl ~ param.typeRef.type, from);
                }
            }
        }
    }

    void exportD(string[] headers, string dir)
    {
        if (exists(dir))
        {
            // clear dir
            writefln("rmdir %s ...", dir);
            rmdirRecurse(dir);
        }

        // prepare
        m_parser.resolveTypedef();

        // gather export items
        debug auto parsedHeaders = makeView(m_parser.m_headers);
        foreach (header; headers)
        {
            Header mainHeader = m_parser.getHeader(header);
            if (mainHeader)
            {
                foreach (decl; mainHeader.types)
                {
                    addDecl([decl]);
                }
            }
            else
            {
                writefln("%s: not found", header);
            }
        }
        if (m_sourceMap.empty)
        {
            throw new Exception("empty");
        }

        // write each source
        // auto sourcemap = makeView(m_sourceMap);
        foreach (k, dsource; m_sourceMap)
        {
            dsource.writeTo(dir);
        }

        // write package.d
        {
            auto packageName = dir.baseName.stripExtension;
            auto path = format("%s/package.d", dir);
            auto f = File(path, "w");
            f.writefln("module %s;", packageName);
            foreach (k, dsource; m_sourceMap)
            {
                f.writefln("public import %s.%s;", packageName, dsource.getName());
            }
        }
    }
}
