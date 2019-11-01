import std.getopt;
import std.string;
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
		parser.exportD(header, dir);
	}

	return 0;
}
