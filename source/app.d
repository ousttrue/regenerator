import std.stdio;
import std.string;
import std.path;
import std.file;
import std.getopt;
import std.conv;
import std.algorithm;
import clangtypes;
import clangparser;

void DFucntion(File f, Function decl)
{
	auto extern_c = decl.m_externC ? "extern(C) " : "";
	f.writefln("// %s%s %s()", extern_c, decl.m_ret, decl.m_name);
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
					(Function decl) => DFucntion(f, decl), () => f.writefln("// %s", decl))(decl);
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
