import std.getopt;
import std.array;
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
import exporter.omitenumprefix;
import liblua;
import luamacros;
import luautils;
import core.memory;

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

Struct getForwardDecl(ref Source[string] map)
{
	foreach (k, s; map)
	{
		foreach (t; s.m_types)
		{
			auto decl = cast(Struct) t;
			if (decl)
			{
				if (decl.forwardDecl)
				{
					if (decl.definition)
					{
						return decl;
					}
				}
			}
		}
	}
	return null;
}

Tuple!(clangdecl.Typedef, Decl) getDefTag(ref Source[string] map)
{
	foreach (k, s; map)
	{
		foreach (t; s.m_types)
		{
			auto def = cast(clangdecl.Typedef) t;
			if (def)
			{
				if (def.name == "D3D10_RECT" || def.name == "D3D11_RECT")
				{
					continue;
				}
				auto tag = def.typeref.type;
				if (cast(clangdecl.Typedef) tag || cast(Function) tag)
				{
				}
				else
				{
					return tuple(def, tag);
				}
			}
		}
	}
	return Tuple!(clangdecl.Typedef, Decl)();
}

void resolve(ref Source[string] map, UserDecl from, Decl to)
{
	// logf("remove: %s", from.name);
	// logf("replace %s => %s", from.hash, to.getName);

	foreach (k, s; map)
	{
		// remove from (typedef or forward decl)
		s.m_types = s.m_types.remove!(t => t == from);

		foreach (t; s.m_types)
		{
			// typedef, struct fields, function params
			t.replace(from, to);
		}
	}
}

void resolveForwardDeclaration(ref Source[string] map)
{
	while (true)
	{
		auto forwardDecl = map.getForwardDecl();
		if (!forwardDecl)
		{
			break;
		}
		map.resolve(forwardDecl, forwardDecl.definition);
	}
}

void resolveStructTag(ref Source[string] map)
{
	while (true)
	{
		auto def_tag = map.getDefTag();
		if (!def_tag[0])
		{
			break;
		}

		map.resolve(def_tag[0], def_tag[1]);
		auto tag = cast(UserDecl) def_tag[1];
		if (tag)
		{
			if (tag.name != def_tag[0].name)
			{
				// logf("rename: %s => %s", tag.name, def_tag[0].name);
				tag.name = def_tag[0].name;
			}
		}
	}
}

int push(lua_State* L, Source[string] values)
{
	lua_createtable(L, 0, cast(int) values.length);
	auto table = lua_gettop(L);
	foreach (k, ref v; values)
	{
		lua_push(L, &v);
		lua_setfield(L, table, k.toStringz);
	}
	return 1;
}

// keep GC
Source[string] g_sourceMap;

// parse(headers, includes, defines, externC);
extern (C) int luaFunc_parse(lua_State* L)
{
	// 型情報を集める
	auto headers = lua_to!(string[])(L, 1);
	auto includes = lua_to!(string[])(L, 2);
	auto defines = lua_to!(string[])(L, 3);
	auto externC = lua_to!bool(L, 4);
	auto parser = new Parser();
	parser.parse(headers, includes, defines, externC);

	// 出力する情報を整理する
	auto isD = lua_to!bool(L, 5);
	g_sourceMap = process(parser, headers, isD);

	// process で 解決済み
	// resolveForwardDeclaration(sourceMap); 

	// TODO: struct tag っぽい typedef を解決する
	resolveStructTag(g_sourceMap);

	// TODO: primitive の名前変えを解決する

	// GC.collect();

	// array を table として push
	return push(L, g_sourceMap);
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

extern (C) int luaFunc_ls(lua_State* L)
{
	auto path = lua_to!string(L, 1);
	auto entries = dirEntries(path, SpanMode.shallow).array;
	lua_createtable(L, cast(int) entries.length, 0);
	foreach (i, e; entries)
	{
		lua_push(L, e.name);
		lua_seti(L, -2, i + 1);
	}
	return 1;
}

extern (C) int luaFunc_isDir(lua_State* L)
{
	auto path = lua_to!string(L, 1);
	lua_push(L, isDir(path));
	return 1;
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

	lua_pushcclosure(L, &luaFunc_ls, 0);
	lua_setfield(L, -2, "ls");

	lua_pushcclosure(L, &luaFunc_isDir, 0);
	lua_setfield(L, -2, "isDir");

	lua_setglobal(L, "file");
}

void push_clangdecl(lua_State* L, Decl decl)
{
	castSwitch!( //
			(Void decl) => lua_push(L, decl), //
			(Bool decl) => lua_push(L, decl), //
			(Int8 decl) => lua_push(L, decl), //
			(Int16 decl) => lua_push(L, decl), //
			(Int32 decl) => lua_push(L, decl), //
			(Int64 decl) => lua_push(L, decl), //
			(UInt8 decl) => lua_push(L, decl), //
			(UInt16 decl) => lua_push(L, decl), //
			(UInt32 decl) => lua_push(L, decl), //
			(UInt64 decl) => lua_push(L,
				decl), //
			(Float decl) => lua_push(L, decl), //
			(Double decl) => lua_push(L, decl), //
			(Pointer decl) => lua_push(L,
				decl), //
			(Reference decl) => lua_push(L, decl), //
			(Array decl) => lua_push(L, decl), //
			(clangdecl.Typedef decl) => lua_push(L,
				decl), //
			(Enum decl) => lua_push(L, decl), //
			(Struct decl) => lua_push(L,
				decl), //
			(Function decl) => lua_push(L, decl) //
			)(decl);
}

string get_last(string src)
{
	auto p = src.lastIndexOf('.');
	if (p == -1)
	{
		return src;
	}
	return src[p + 1 .. $];
}

Decl GetTypedefSource(Decl decl)
{
	while (true)
	{
		auto typedefDecl = cast(clangdecl.Typedef) decl;
		if (!typedefDecl)
		{
			break;
		}
		decl = typedefDecl.typeref.type;
	}
	return decl;
}

string getName(Decl decl)
{
	auto userDecl = cast(UserDecl) decl;
	if (!userDecl)
	{
		return "";
	}
	return userDecl.name;
}

UserType!T register_type(T : Decl)(lua_State* L)
{
	auto user = new UserType!T;

	auto name = get_last(typeid(T).name);
	user.instance.Getter("class", (T* self) => name);
	user.metaMethod(LuaMetaKey.tostring, (T* self) => self.toString);

	user.instance.Getter("name", (T* self) => (*self).getName);
	user.instance.Getter("typedefSource", (lua_State* L) {
		auto self = lua_to!T(L, 1);
		auto source = self.GetTypedefSource;
		if (!source)
		{
			return 0;
		}
		push_clangdecl(L, source);
		return 1;
	});

	user.push(L);
	lua_setglobal(L, name.toStringz);
	return user;
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
	source.instance.Getter("empty", (Source* self) => self.empty);
	source.instance.Getter("name", (Source* self) => self.getName);
	source.instance.Getter("imports", (Source* self) => self.m_imports);
	source.instance.Getter("modules", (Source* self) => self.m_modules);
	source.instance.Getter("macros", (Source* self) => self.m_macros);
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
	macroDef.instance.Getter("name", (MacroDefinition* m) => m.name);
	macroDef.instance.Getter("tokens", (MacroDefinition* m) => m.tokens);
	macroDef.push(lua.L);
	lua_setglobal(lua.L, "MacroDefinition");

	// export class UserDecl
	auto typeRef = new UserType!TypeRef;
	typeRef.instance.Getter("isConst", (TypeRef* self) => self.isConst);
	typeRef.instance.Getter("hasConstRecursive", (TypeRef* self) => self.hasConstRecursive);
	typeRef.instance.Getter("type", (lua_State* L) {
		auto self = lua_to!(TypeRef*)(L, 1);
		push_clangdecl(L, self.type);
		return 1;
	});
	typeRef.push(lua.L);
	lua_setglobal(lua.L, "TypeRef");

	auto vo = register_type!Void(lua.L);
	auto bl = register_type!Bool(lua.L);
	auto s8 = register_type!Int8(lua.L);
	auto s16 = register_type!Int16(lua.L);
	auto s32 = register_type!Int32(lua.L);
	auto s64 = register_type!Int64(lua.L);
	auto u8 = register_type!UInt8(lua.L);
	auto u16 = register_type!UInt16(lua.L);
	auto u32 = register_type!UInt32(lua.L);
	auto u64 = register_type!UInt64(lua.L);
	auto f32 = register_type!Float(lua.L);
	auto f64 = register_type!Double(lua.L);

	auto pt = register_type!Pointer(lua.L);
	pt.instance.Getter("ref", (Pointer* self) => self.typeref);

	auto rf = register_type!Reference(lua.L);
	rf.instance.Getter("ref", (Reference* self) => self.typeref);

	auto ar = register_type!Array(lua.L);
	ar.instance.Getter("ref", (Array* self) => self.typeref);
	ar.instance.Getter("size", (Array* self) => self.size);

	auto typedefType = register_type!(clangdecl.Typedef)(lua.L);
	typedefType.instance.Getter("useCount", (clangdecl.Typedef* self) => self.useCount);
	typedefType.instance.Getter("ref", (clangdecl.Typedef* self) => self.typeref);

	auto enumValue = new UserType!EnumValue;
	enumValue.instance.Getter("name", (EnumValue* self) => self.name);
	enumValue.instance.Getter("value", (EnumValue* self) => self.value);
	enumValue.push(lua.L);
	lua_setglobal(lua.L, "EnumValue");

	auto enumType = register_type!Enum(lua.L);
	enumType.instance.Getter("useCount", (Enum* self) => self.useCount);
	enumType.instance.Getter("values", (Enum* self) => self.values);
	enumType.instance.Method("omit", (Enum* self) => omit(*self));

	auto field = new UserType!Field;
	field.instance.Getter("offset", (Field* self) => self.offset);
	field.instance.Getter("name", (Field* self) => self.name);
	field.instance.Getter("ref", (lua_State* L) {
		auto self = lua_to!(Field*)(L, 1);
		lua_push(L, &self.typeref);
		return 1;
	});
	field.push(lua.L);
	lua_setglobal(lua.L, "Field");

	auto structType = register_type!Struct(lua.L);
	structType.instance.Getter("useCount", (Struct* self) => self.useCount);
	structType.instance.Getter("hash", (Struct* self) => self.hash);
	structType.instance.Getter("namespace", (Struct* self) => self.namespace);
	structType.instance.Getter("isInterface", (Struct* self) => self.isInterface);
	structType.instance.Getter("isForwardDecl", (Struct* self) => self.forwardDecl);
	structType.instance.Getter("isUnion", (Struct* self) => self.isUnion);
	structType.instance.Getter("base", (lua_State* L) {
		auto self = lua_to!(Struct*)(L, 1);
		if (!self.base)
		{
			return 0;
		}
		push_clangdecl(L, self.base);
		return 1;
	});
	structType.instance.Getter("iid", (lua_State* L) {
		auto self = lua_to!Struct(L, 1);
		if (self.iid.empty)
		{
			return 0;
		}
		lua_push(L, self.iid.toString);
		return 1;
	});
	structType.instance.Getter("methods", (Struct* self) => self.methods);
	structType.instance.Getter("fields", (Struct* self) => self.fields);
	structType.instance.Getter("definition", (lua_State* L) {
		auto self = lua_to!Struct(L, 1);
		if (!self.definition)
		{
			return 0;
		}
		push_clangdecl(L, self.definition);
		return 1;
	});

	auto param = new UserType!Param;
	param.instance.Getter("name", (Param* self) => self.name);
	param.instance.Getter("ref", (Param* self) => self.typeref);
	param.instance.Getter("values", (Param* self) => self.values);
	param.push(lua.L);
	lua_setglobal(lua.L, "Param");

	auto funcType = register_type!Function(lua.L);
	funcType.instance.Getter("dllExport", (Function* self) => self.dllExport);
	funcType.instance.Getter("isExternC", (Function* self) => self.externC);
	funcType.instance.Getter("params", (Function* self) => self.params);
	funcType.instance.Getter("namespace", (Function* self) => self.namespace);
	funcType.instance.Getter("ret", (lua_State* L) {
		auto self = lua_to!Function(L, 1);
		// if (!self.ret)
		// {
		// 	return 0;
		// }
		push_clangdecl(L, self.ret);
		return 1;
	});

	// parse
	lua_register(lua.L, "parse", &luaFunc_parse);

	// run
	lua.cmdline(args);

	return 0;
}
