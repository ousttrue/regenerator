module dexporter;
import std.string;
import std.stdio;
import std.path;
import std.file;
import std.algorithm;
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

string DPointer(Parser parser, Pointer t)
{
    return format("%s*", parser.DType(t.m_typeref.type));
}

string DArray(Parser parser, Array t)
{
    return format("%s[%d]", parser.DType(t.m_typeref.type), t.m_size);
}

string DType(Parser parser, Decl t)
{
    return castSwitch!((Pointer decl) => parser.DPointer(decl),
            (Array decl) => parser.DArray(decl), (UserDecl decl) => decl.m_name, //
            (Void _) => "void", (Bool _) => "bool", (Int8 _) => "byte",
            (Int16 _) => "short", (Int32 _) => "int", (Int64 _) => "long",
            (UInt8 _) => "ubyte", (UInt16 _) => "ushort", (UInt32 _) => "uint",
            (UInt64 _) => "ulong", (Float _) => "float", (Double _) => "double", //
            () => format("unknown(%s)", t))(t);
}

void DTypedefDecl(Parser parser, File* f, Typedef t)
{
    // return format("alias %s = %s;", t.m_name, DType(t.m_typeref.type, parser));
    auto dst = parser.DType(t.m_typeref.type);
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
    // DDecl(f, t.m_typeref.type, parser);
    // int a = 0;
    // throw new Exception("");
}

void DStructDecl(Parser parser, File* f, Struct decl, string typedefName = null)
{
    auto name = typedefName ? typedefName : decl.m_name;
    if (!name)
    {
        f.writeln("// struct nameless");
        return;
    }

    if (decl.m_iid.empty())
    {
        if (decl.m_fields.empty())
        {
            return;
        }

        f.writefln("struct %s", name);
        f.writeln("{");
        foreach (field; decl.m_fields)
        {
            f.writefln("   %s %s;", parser.DType(field.type), DEscapeName(field.name));
        }
        f.writeln("}");
    }
    else
    {
        f.writefln("interface %s", name);
        f.writeln("{");
        foreach (field; decl.m_fields)
        {
            f.writefln("   %s %s;", parser.DType(field.type), DEscapeName(field.name));
        }
        f.writeln("}");
    }
}

void DEnumDecl(Parser _, File* f, Enum decl)
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

void DFucntionDecl(Parser parser, File* f, Function decl)
{
    if (!decl.m_dllExport)
    {
        return;
    }
    if (decl.m_externC)
    {
        f.write("extern(C) ");
    }
    f.write(parser.DType(decl.m_ret));
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
        f.write(format("%s %s", parser.DType(param.typeRef.type), DEscapeName(param.name)));
    }
    f.writeln(");");
}

void DDecl(Parser parser, File* f, Decl decl)
{
    castSwitch!((Typedef decl) => parser.DTypedefDecl(f, decl),
            (Enum decl) => parser.DEnumDecl(f, decl), (Struct decl) => parser.DStructDecl(f,
                decl), (Function decl) => parser.DFucntionDecl(f, decl))(decl);
}

class DSource
{
    bool m_windef;
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

    void addDecl(UserDecl type)
    {
        if (m_types.find(type).any())
        {
            return;
        }
        m_types ~= type;
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

    void writeTo(string dir, Parser parser)
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

            if (m_windef)
            {
                // HRESULT, DWORD, LONG ... etc
                f.writeln("import core.sys.windows.windows;");
            }

            foreach (src; m_imports)
            {
                f.writefln("import %s.%s;", packageName, src.getName());
            }

            foreach (decl; m_types)
            {
                parser.DDecl(&f, decl);
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
            if (!pointer)
            {
                return decl;
            }

            decl = pointer.m_typeref.type;
        }

        // throw new Exception("not reach here");
    }

    void addDecl(Decl _decl, DSource[] from = [])
    {
        auto decl = cast(UserDecl) stripPointer(_decl);
        if (!decl)
        {
            return;
        }

        auto dsource = getOrCreateSource(decl.m_path);
        dsource.addDecl(decl);
        foreach (f; from)
        {
            f.addImport(dsource);
        }
        from ~= dsource;

        Function functionDecl = cast(Function) decl;
        Typedef typedefDecl = cast(Typedef) decl;
        Struct structDecl = cast(Struct) decl;
        if (functionDecl)
        {
            addDecl(functionDecl.m_ret, from);
            foreach (param; functionDecl.m_params)
            {
                addDecl(param.typeRef.type, from);
            }
        }
        else if (typedefDecl)
        {
            addDecl(typedefDecl.m_typeref.type, from);
        }
        else if (structDecl)
        {
            foreach (field; structDecl.m_fields)
            {
                addDecl(field.type, from);
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

        // resolve typedef
        foreach (k, v; m_parser.declMap)
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

        // gather export items
        debug auto parsedHeaders = makeView(m_parser.m_headers);
        foreach (header; headers)
        {
            Header mainHeader = m_parser.getHeader(header);
            if (mainHeader)
            {
                foreach (decl; mainHeader.types)
                {
                    addDecl(decl);
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
            dsource.writeTo(dir, m_parser);
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
