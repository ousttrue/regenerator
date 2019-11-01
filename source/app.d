import std.stdio;
import std.string;
import std.path;
import std.file;
import std.getopt;
import std.conv;
import std.algorithm;
import std.array;
import clangtypes;
import clangparser;

string DPointer(Pointer t)
{
	return format("%s*", DType(t.m_typeref.type));
}

string DEnum(Enum t)
{
	return t.toString();
}

string DStruct(Struct t)
{
	return t.toString();
}

string DTypedef(Typedef t)
{
	return t.toString();
}

string DType(Type t)
{
	return castSwitch!((Pointer decl) => DPointer(decl),
			(Typedef decl) => DTypedef(decl), (Enum decl) => DEnum(decl),
			(Struct decl) => DStruct(decl), (Function decl) => DFucntion(decl),
			//
			(Void _) => "void", (Bool _) => "bool", (Int8 _) => "byte",
			(Int16 _) => "short", (Int32 _) => "int", (Int64 _) => "long",
			(UInt8 _) => "ubyte", (UInt16 _) => "ushort", (UInt32 _) => "uint",
			(UInt64 _) => "ulong", (Float _) => "float", (Double _) => "double",
			//
			() => format("unknown(%s)", t))(t);
}

string DFucntion(Function decl, bool extern_c = false)
{
	auto sb = appender!string;
	if (extern_c)
	{
		sb.put("extern(C) ");
	}
	sb.put(DType(decl.m_ret));
	sb.put(" ");
	sb.put(decl.m_name);
	sb.put("(");

	auto isFirst = true;
	foreach (param; decl.m_params)
	{
		if (isFirst)
		{
			isFirst = false;
		}
		else
		{
			sb.put(", ");
		}
		sb.put(format("%s %s", DType(param.typeRef.type), param.name));
	}
	sb.put(");");
	return sb.data;
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

	void writeTo(string dir)
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
			castSwitch!((Typedef decl) => f.writefln("// typedef %s",
					decl.m_name), (Enum decl) => f.writefln("// enum %s", decl.m_name),
					(Struct decl) => f.writefln("// struct %s", decl.m_name),
					(Function decl) => f.writefln("// %s", DFucntion(decl)))(decl);
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
	dsource.writeTo(dir);
}

int main(string[] args)
{
	string header;
	string dir;
	string[] includes;
	getopt(args, "include|I", &includes, "outdir", &dir,
			std.getopt.config.required, "header|H", &header);

	string[] params = ["-x", "c++"];
	foreach (include; includes)
	{
		params ~= format("-I%s", include);
	}

	auto parser = new Parser();
	parser.parse(header, params);

	if (dir)
	{
		auto x = toStringz(dir);
		auto y = x[0 .. dir.length + 1];
		exportD(parser, header, to!string(y.ptr));
	}

	return 0;
}
