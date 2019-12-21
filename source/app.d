import std.getopt;
import std.string;
import std.experimental.logger;
import std.conv;
import std.format;
import std.typecons;
import std.file;
import clangparser;
import exporter.processor;
import exporter.dlangexporter;
import exporter.source;
import lua;
import luamacros;
import luastack;
import luahelper;
import luastate;

struct Vector3
{
	float x;
	float y;
	float z;

	Vector3 opBinary(string op)(const ref Vector3 rhs)
	{
		static if (op == "+")
			return Vector3(x + rhs.x, y + rhs.y, z + rhs.z);
		else
			static assert(0, "Operator " ~ op ~ " not implemented");
	}

	string toString() const
	{
		return "Vector3{%f, %f, %f}".format(x, y, z);
	}
}

// parse(headers, includes, defines, externC);
extern (C) int luaFunc_parse(lua_State* L)
{
	log("call");

	auto headers = lua_to!(string[])(L, 1);
	auto includes = lua_to!(string[])(L, 2);
	auto defines = lua_to!(string[])(L, 3);
	auto externC = lua_to!bool(L, 4);

	// string dir;
	// bool omitEnumPrefix = false;

	auto parser = new Parser();

	// 型情報を集める
	log("parse...");
	parser.parse(headers, includes, defines, externC);

	// // 出力する情報を整理する
	log("process...");
	auto sourceMap = process(parser, headers);

	lua_createtable(L, 0, cast(int) sourceMap.length);
	auto table = lua_gettop(L);
	foreach (k, ref v; sourceMap)
	{
		lua_push(L, &v);
		lua_setfield(L, table, k.toStringz);
	}

	return 1;
}

extern (C) int luaFunc_exists(lua_State* L)
{
	auto path = lua_to!string(L, 1);
	lua_pushboolean(L, exists(path) ? true : false);
	return 1;
}

extern (C) int luaFunc_rmdirRecurse(lua_State* L)
{
	auto path = lua_to!string(L, 1);
	rmdirRecurse(path);
	return 0;
}

void open_file(lua_State* L)
{
	lua_createtable(L, 0, 0);

	lua_pushcclosure(L, &luaFunc_exists, 0);
	lua_setfield(L, -2, "exists");

	lua_pushcclosure(L, &luaFunc_rmdirRecurse, 0);
	lua_setfield(L, -2, "rmdirRecurse");

	lua_setglobal(L, "file");
}

int main(string[] args)
{
	auto lua = new LuaState();

	// default libraries
	luaL_openlibs(lua.L);

	// utility
	open_file(lua.L);

	// export class Source
	auto source = new UserType!Source;
	source.instance.Getter("empty", (Source* s) => s.empty);
	source.push(lua.L);
	lua_setglobal(lua.L, "Source");

	// parse
	lua_register(lua.L, "parse", &luaFunc_parse);

	// run
	lua.doScript(args);

	return 0;
}
