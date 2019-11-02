module dexporter;
import std.string;
import std.stdio;
import std.path;
import std.file;
import std.algorithm;
import clangtypes;
import clangparser;

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

string DPointer(Pointer t, Parser parser)
{
    return format("%s*", DType(t.m_typeref.type, parser));
}

string DArray(Array t, Parser parser)
{
    return format("%s[%d]", DType(t.m_typeref.type, parser), t.m_size);
}

string DType(Type t, Parser parser)
{
    return castSwitch!((Pointer decl) => DPointer(decl, parser),
            (Array decl) => DArray(decl, parser), (UserType decl) => decl.m_name, //
            (Void _) => "void", (Bool _) => "bool", (Int8 _) => "byte",
            (Int16 _) => "short", (Int32 _) => "int", (Int64 _) => "long",
            (UInt8 _) => "ubyte", (UInt16 _) => "ushort", (UInt32 _) => "uint",
            (UInt64 _) => "ulong", (Float _) => "float", (Double _) => "double", //
            () => format("unknown(%s)", t))(t);
}

void DTypedefDecl(File* f, Typedef t, Parser parser)
{
    // return format("alias %s = %s;", t.m_name, DType(t.m_typeref.type, parser));
    auto dst = DType(t.m_typeref.type, parser);
    if (dst)
    {
        if (t.m_name == dst)
        {
            f.writeln("// samename");
        }
        else
        {
            f.writefln("alias %s = %s;", t.m_name, dst);
        }
        return;
    }

    auto structDecl = cast(Struct) t.m_typeref.type;
    if (structDecl)
    {
        DStructDecl(f, structDecl, parser, t.m_name);
        return;
    }

    // nameless
    f.writeln("// typedef nameless");
    // DDecl(f, t.m_typeref.type, parser);
    // int a = 0;
    // throw new Exception("");
}

void DStructDecl(File* f, Struct decl, Parser parser, string typedefName = null)
{
    auto name = typedefName ? typedefName : decl.m_name;
    if (!name)
    {
        f.writeln("// struct nameless");
        return;
    }
    f.writefln("struct %s", name);
    f.writeln("{");
    foreach (field; decl.m_fields)
    {
        f.writefln("   %s %s;", DType(field.type, parser), DEscapeName(field.name));
    }
    f.writeln("}");
}

void DEnumDecl(File* f, Enum decl, Parser _)
{
    if (!decl.m_name)
    {
        f.writeln("// enum nameless");
        return;
    }
    f.writefln("enum %s", decl.m_name);
    f.writeln("{");
    foreach (value; decl.m_values)
    {
        f.writefln("    %s = 0x%x,", value.name, value.value);
    }
    f.writeln("}");
}

void DFucntionDecl(File* f, Function decl, Parser parser)
{
    if (decl.m_externC)
    {
        f.write("extern(C) ");
    }
    f.write(DType(decl.m_ret, parser));
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
        f.write(format("%s %s", DType(param.typeRef.type, parser), DEscapeName(param.name)));
    }
    f.writeln(");");
}

void DDecl(File* f, Type decl, Parser parser)
{
    castSwitch!((Typedef decl) => DTypedefDecl(f, decl, parser),
            (Enum decl) => DEnumDecl(f, decl, parser), (Struct decl) => DStructDecl(f,
                decl, parser), (Function decl) => DFucntionDecl(f, decl, parser))(decl);
}

class DSource
{
    string m_path;
    UserType[] m_types;
    DSource[] m_imports;

    this(string path)
    {
        m_path = path;
    }

    void addDecl(UserType type)
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
        // open
        auto name = m_path.baseName().stripExtension();
        auto stem = format("%s/%s.d", dir, name);
        // writeln(stem);
        writefln("writeTo: %s(%d)", stem, m_types.length);

        mkdirRecurse(dir);
        {
            auto f = File(stem, "w");
            f.writefln("module %s;", m_path.baseName.stripExtension);

            foreach (src; m_imports)
            {
                f.writefln("import %s;", src.m_path.baseName.stripExtension);
            }

            foreach (decl; m_types)
            {
                DDecl(&f, decl, parser);
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

    void addDecl(UserType decl, DSource from = null)
    {
        auto dsource = getOrCreateSource(decl.m_path);
        dsource.addDecl(decl);

        if (from)
        {
            from.addImport(dsource);
        }

        Function functionDecl = cast(Function) decl;
        Typedef typedefDecl = cast(Typedef) decl;
        if (functionDecl)
        {
            UserType retDecl = cast(UserType) functionDecl.m_ret;
            if (retDecl)
            {
                addDecl(retDecl, dsource);
            }
        }
        else if (typedefDecl)
        {
            UserType dstDecl = cast(UserType) typedefDecl.m_typeref.type;
            if (dstDecl)
            {
                addDecl(dstDecl, dsource);
            }
        }
    }

    void exportD(string header, string dir)
    {
        Header parsed_header = m_parser.headers[header];
        if (!parsed_header)
        {
            throw new Exception("header not found");
        }

        if (exists(dir))
        {
            // clear dir
            writefln("rmdir %s ...", dir);
            rmdirRecurse(dir);
        }

        foreach (decl; parsed_header.types)
        {
            addDecl(decl);
        }

        foreach (k, dsource; m_sourceMap)
        {
            dsource.writeTo(dir, m_parser);
        }
    }
}
