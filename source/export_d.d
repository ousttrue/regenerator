module export_d;
import std.string;
import std.stdio;
import std.path;
import std.file;
import std.algorithm;
import clangtypes;
import clangparser;

string DPointer(Pointer t, Parser parser)
{
    return format("%s*", DType(t.m_typeref.type, parser));
}

string DType(Type t, Parser parser)
{
    return castSwitch!((Pointer decl) => DPointer(decl, parser),
            (UserType decl) => decl.m_name, //
            (Void _) => "void", (Bool _) => "bool",
            (Int8 _) => "byte", (Int16 _) => "short", (Int32 _) => "int",
            (Int64 _) => "long", (UInt8 _) => "ubyte", (UInt16 _) => "ushort",
            (UInt32 _) => "uint", (UInt64 _) => "ulong", (Float _) => "float",
            (Double _) => "double", //
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

    // nameless
    f.writeln("// typedef nameless");
    // DDecl(f, t.m_typeref.type, parser);
    // int a = 0;
    // throw new Exception("");
}

void DStructDecl(File* f, Struct decl, Parser parser)
{
    if (!decl.m_name)
    {
        f.writeln("// struct nameless");
        return;
    }
    f.writefln("struct %s{", decl.m_name);
    foreach (field; decl.m_fields)
    {
        f.writefln("   %s %s;", DType(field.type, parser), field.name);
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
    f.write("enum ");
    f.write(decl.m_name);
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
        f.write(format("%s %s", DType(param.typeRef.type, parser), param.name));
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

    this(string path)
    {
        m_path = path;
    }

    void addDecl(UserType type)
    {
        m_types ~= type;
    }

    void writeTo(string dir, Parser parser)
    {
        writeln(dir);
        writeln(m_path);

        mkdirRecurse(dir);

        // open
        auto name = m_path.baseName().stripExtension();
        auto stem = format("%s/%s.d", dir, name);
        // writeln(stem);

        auto f = File(stem, "w");

        foreach (decl; m_types)
        {
            DDecl(&f, decl, parser);
        }
    }
}

void exportD(Parser parser, string header, string dir)
{
    auto parsed_header = parser.headers[header];
    if (!parsed_header)
    {
        return;
    }

    if (exists(dir))
    {
        // clear dir
        writefln("rmdir %s ...", dir);
        rmdirRecurse(dir);
    }

    auto dsource = new DSource(header);
    foreach (decl; parsed_header.types)
    {
        dsource.addDecl(decl);
    }
    dsource.writeTo(dir, parser);
}
