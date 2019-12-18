import std.getopt;
import std.string;
import std.experimental.logger;
import clangparser;
import exporter.processor;
import exporter.dlangexporter;
import lua;
import luamacros;

class LuaState
{
	lua_State* L;

	this()
	{
		L = luaL_newstate();
		luaL_requiref(L, "_G", &luaopen_base, 1);
		lua_pop(L, 1);
	}

	~this()
	{
		lua_close(L);
	}

	void doScript(string file)
	{
		auto result = luaL_dofile(L, file.toStringz);
		if (result != 0)
		{
			// PrintLuaError();
		}
	}
}

int main(string[] args)
{
	string[] headers;
	string dir;
	string[] includes;
	string[] defines;
	string lua;
	bool omitEnumPrefix = false;
	bool externC = false;
	getopt(args, //
			"include|I", &includes, //
			"define|D", &defines, //
			"outdir", &dir, //
			"omitEnumPrefix|E", &omitEnumPrefix, //
			"externC|C", &externC, //
			"lua",
			&lua, //
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

	if (!lua.empty)
	{
		auto l = new LuaState();
		l.doScript(lua);
	}

	return 0;
}
