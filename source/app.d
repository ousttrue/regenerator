import std.getopt;
import std.string;
import std.experimental.logger;
import clangparser;
import exporter.processor;
import exporter.dlangexporter;

int main(string[] args)
{
	string[] headers;
	string dir;
	string[] includes;
	string[] defines;
	bool omitEnumPrefix = false;
	bool externC = false;
	getopt(args, //
			"include|I", &includes, //
			"define|D", &defines, //
			"outdir", &dir, //
			"omitEnumPrefix|E", &omitEnumPrefix, //
			"externC|C", &externC, //
			std.getopt.config.required, // 
			"header|H", &headers //
			);

	auto parser = new Parser();

	// 型情報を集める
	log("parse...");
	parser.parse(headers, includes, defines, externC);

	// 出力する情報を整理する
	log("process...");
	auto sourceMap = process(parser, headers);

	if (dir)
	{
		if (sourceMap.empty)
		{
			throw new Exception("empty");
		}

		// D言語に変換する
		log("generate dlang...");
		dlangExport(sourceMap, dir, omitEnumPrefix);
	}

	return 0;
}
