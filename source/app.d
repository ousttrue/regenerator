import std.getopt;
import std.string;
import std.conv;
import clangparser;
import export_d;

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
		parser.exportD(header, to!string(y.ptr));
	}

	return 0;
}
