import std.getopt;
import std.string;
import std.experimental.logger;
import std.conv;
import std.format;
import std.typecons;
import clangparser;
import exporter.processor;
import exporter.dlangexporter;
import lua;
import luahelper;

struct Vector3
{
	float x;
	float y;
	float z;
}

int lua_push(T : Vector3)(lua_State* L, T value)
{
	return 0;
}

int main(string[] args)
{
	string[] headers;
	string dir;
	string[] includes;
	string[] defines;
	string script;
	bool omitEnumPrefix = false;
	bool externC = false;
	getopt(args, //
			"include|I", &includes, //
			"define|D", &defines, //
			"outdir", &dir, //
			"omitEnumPrefix|E", &omitEnumPrefix, //
			"externC|C", &externC, //
			"lua",
			&script, //
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

	if (!script.empty)
	{
		auto lua = new LuaState();

		auto vec3 = new UserType!Vector3;
		vec3.staticMethod("zero", () => Vector3(0, 0, 0));
		vec3.push(lua.L);

		lua_setglobal(lua.L, "Vector3");

		auto a = lua_gettop(lua.L);

		lua.doScript(script);
	}

	return 0;
}
