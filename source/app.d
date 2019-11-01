import std.getopt;
import std.string;
import clangparser;
import dexporter;

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
		auto exporter = new DExporter(parser);
		exporter.exportD(header, dir);
	}

	return 0;
}
