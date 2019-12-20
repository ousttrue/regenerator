import std.getopt;
import std.string;
import std.experimental.logger;
import std.conv;
import std.format;
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
			log(to!string(lua_tostring(L, -1)));
		}
	}
}

struct UserTypeDummy
{
}

alias LuaFunc = int delegate(lua_State*);

/// 汎用Closure。upvalue#1 から LuaFunc を得て実行する
extern (C) int LuaFuncClosure(lua_State* L)
{
	try
	{
		auto lf = cast(LuaFunc*) lua_touserdata(L, lua_upvalueindex(1));
		return (*lf)(L);
	}
	catch (Exception ex)
	{
		lua_pushfstring(L, ex.msg.toStringz);
		lua_error(L);
		return 1;
	}
}

struct StaticMethodMap
{
private:
	LuaFunc[string] m_methodMap;

public:
	void StaticMethod(string name, const LuaFunc lf)
	{
		m_methodMap[name] = lf;
	}

	// stack#1: userdata
	// stack#2: key
	int Dispatch(lua_State* L)
	{
		auto key = to!string(lua_tostring(L, 2));
		if (key)
		{
			auto found = key in m_methodMap;
			if (found)
			{
				// upvalue#1
				lua_pushlightuserdata(L, found);

				// return closure
				lua_pushcclosure(L, &LuaFuncClosure, 1);
				return 1;
			}
			else
			{
				lua_pushstring(L, "'%s' not found".format(key).toStringz);
				lua_error(L);
				return 1;
			}
		}
		else
		{
			lua_pushstring(L, "unknown key type '%s'".format(lua_typename(L, 2)).toStringz);
			lua_error(L);
			return 1;
		}
	}
}

class UserType(T)
{
private:
	StaticMethodMap m_staticMethods;
	LuaFunc m_typeIndexClosure;

	this()
	{
		m_typeIndexClosure = L => m_staticMethods.Dispatch(L);
	}

	void create_type_metatable(lua_State* L)
	{
		// 型に対するmetatableを作成して stacktop にセットする
		auto created = luaL_newmetatable(L, typeid(T).name.toStringz);
		assert(created == 1);

		int metatable = lua_gettop(L);
		assert(lua_gettop(L) == 2);

		// upvalue#1
		lua_pushlightuserdata(L, &m_typeIndexClosure);
		// closure
		lua_pushcclosure(L, &LuaFuncClosure, 1);
		// metatable.__inex = closure(upvalue#1)
		lua_setfield(L, metatable, "__index");
		assert(lua_gettop(L) == 2);
	}

public:
	void push(lua_State* L)
	{
		// auto name = typeid(T).name;
		auto p = cast(UserTypeDummy*) lua_newuserdata(L, UserTypeDummy.sizeof);
		// int metatable = lua_gettop(L);
		// assert(metatable == 1);
		assert(lua_gettop(L) == 1);

		create_type_metatable(L);
		assert(lua_gettop(L) == 2);

		// // push userdata for Type
		// // set metatable to type userdata
		// auto pushedType = luaL_getmetatable(L, typeid(T).name());
		lua_setmetatable(L, -2);
		assert(lua_gettop(L) == 1);
	}
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

		auto vec3 = new UserType!Vector3;

		vec3.push(lua.L);
		lua_setglobal(lua.L, "Vector3");

		auto a = lua_gettop(lua.L);

		lua.doScript(script);
	}

	return 0;
}
