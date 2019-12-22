import std.getopt;
import std.string;
import std.experimental.logger;
import std.conv;
import std.format;
import std.typecons;
import std.file;
import std.algorithm;
import clangparser;
import clangdecl;
import exporter.processor;
import exporter.dlangexporter;
import exporter.source;
import lua;
import luamacros;
import luautils;

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

extern (C) int luaFunc_mkdirRecurse(lua_State* L)
{
	auto path = lua_to!string(L, 1);
	mkdirRecurse(path);
	return 0;
}

void open_file(lua_State* L)
{
	lua_createtable(L, 0, 0);

	lua_pushcclosure(L, &luaFunc_exists, 0);
	lua_setfield(L, -2, "exists");

	lua_pushcclosure(L, &luaFunc_rmdirRecurse, 0);
	lua_setfield(L, -2, "rmdirRecurse");

	lua_pushcclosure(L, &luaFunc_mkdirRecurse, 0);
	lua_setfield(L, -2, "mkdirRecurse");

	lua_setglobal(L, "file");
}

void push_clangdecl(lua_State* L, Decl decl)
{
	castSwitch!( //
			(Void decl) => lua_push(L, decl), //
			(Bool decl) => lua_push(L, decl), //
			(Int8 decl) => lua_push(L, decl), //
			(Int16 decl) => lua_push(L,
				decl), //
			(Int32 decl) => lua_push(L, decl), //
			(Int64 decl) => lua_push(L,
				decl), //
			(UInt8 decl) => lua_push(L, decl), //
			(UInt16 decl) => lua_push(L, decl), //
			(UInt32 decl) => lua_push(L,
				decl), //
			(UInt64 decl) => lua_push(L, decl), //
			(Float decl) => lua_push(L, decl), //
			(Double decl) => lua_push(L,
				decl), //
			(Pointer decl) => lua_push(L, decl), //
			(Array decl) => lua_push(L, decl), //
			(clangdecl.Typedef decl) => lua_push(L,
				decl), //
			(Enum decl) => lua_push(L, decl), //
			(Struct decl) => lua_push(L, decl), //
			(Function decl) => lua_push(L, decl) //
			)(decl);
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
	source.instance.Getter("name", (Source* s) => s.getName);
	source.instance.Getter("imports", (Source* s) => s.m_imports);
	source.instance.Getter("modules", (Source* s) => s.m_modules);
	source.instance.Getter("macros", (Source* s) => s.m_macros);
	source.instance.Getter("types", (lua_State* L) {
		auto s = lua_to!(Source*)(L, 1);
		lua_createtable(L, cast(int) s.m_types.length, 0);
		foreach (i, ref decl; s.m_types)
		{
			push_clangdecl(L, decl);
			lua_seti(L, -2, i + 1);
		}
		return 1;
	});
	source.push(lua.L);
	lua_setglobal(lua.L, "Source");

	// export struct MacroDefinition
	auto macroDef = new UserType!MacroDefinition;
	macroDef.metaMethod(LuaMetaKey.tostring, (MacroDefinition* m) => m.toString);
	macroDef.instance.Getter("name", (MacroDefinition* m) => m.name);
	macroDef.instance.Getter("tokens", (MacroDefinition* m) => m.tokens);
	macroDef.push(lua.L);
	lua_setglobal(lua.L, "MacroDefinition");

	// export class UserDecl
	auto typeRef = new UserType!TypeRef;
	typeRef.instance.Getter("type", (lua_State* L) {
		auto s = lua_to!(TypeRef*)(L, 1);
		push_clangdecl(L, s.type);
		return 1;
	});
	typeRef.push(lua.L);
	lua_setglobal(lua.L, "TypeRef");

	auto typeDef = new UserType!(clangdecl.Typedef);
	typeDef.instance.Getter("type", (clangdecl.Typedef* d) => "Typedef");
	typeDef.instance.Getter("name", (clangdecl.Typedef* d) => d.name);
	typeDef.instance.Getter("ref", (clangdecl.Typedef* d) => d.typeRef);
	typeDef.push(lua.L);
	lua_setglobal(lua.L, "Typedef");

	auto enumType = new UserType!(Enum);
	enumType.instance.Getter("type", s => "Enum");
	enumType.push(lua.L);
	lua_setglobal(lua.L, "Enum");

	auto structType = new UserType!(Struct);
	structType.instance.Getter("type", s => "Struct");
	structType.push(lua.L);
	lua_setglobal(lua.L, "Struct");

	auto func = new UserType!(Function);
	func.instance.Getter("type", s => "Function");
	func.push(lua.L);
	lua_setglobal(lua.L, "Function");

	// parse
	lua_register(lua.L, "parse", &luaFunc_parse);

	// run
	lua.doScript(args);

	return 0;
}
