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

struct UserTypeDummy
{
}

void usertype_push(T)(lua_State* L)
{
	// auto name = typeid(T).name;
	auto p = cast(UserTypeDummy*) lua_newuserdata(L, UserTypeDummy.sizeof);
	// int metatable = lua_gettop(L);
	// assert(metatable == 1);
	assert(lua_gettop(L) == 1);
}

struct Vector3
{
	float x;
	float y;
	float z;
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

		usertype_push!Vector3(lua.L);
		lua_setglobal(lua.L, "Vector3");

		auto a = lua_gettop(lua.L);

		lua.doScript(script);
	}

	return 0;
}
