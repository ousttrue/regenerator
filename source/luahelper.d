module luahelper;
import std.string;
import std.typecons;
import std.conv;
import std.traits;
import std.experimental.logger;
import lua;
import luamacros;

///
/// UserType has 2 metatables.
///          
/// # 1. metatable for type userdata
/// * A type userdata is created in setup and set type metatable
/// * metatable.__index dispatch static methods(Vector3.new, Vector3.cross ... etc)
///
/// # 2. metatable for instance userdata
/// * A instance userdata is created in script and set instance metatable
/// * metatable.__index dispatch instance methods, getters and setters
///
/// # get instance userdata from lua stack
/// * type == UserData
/// * compare userdata.metatable == getmetatable!T
/// * cast(T*)lua_touserdata(L, idx)
///

enum LuaMetaKey
{
    tostring = "__tostring",
    add = "__add",
}

ulong get_hash(T)()
{
    static if (isPointer!T)
    {
        auto ti = typeid(PointerTarget!T);
    }
    else
    {
        auto ti = typeid(T);
    }
    auto hash = ti.toHash();
    // logf("%s => %d", ti.name, hash);
    return hash;
}

// ulong get_hash(T : T*)()
// {
//     auto hash = typeid(T).toHash();
//     logf("%s => %d", typeid(T).name, hash);
//     return hash;
// }

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

    void doScript(string[] args)
    {
        if (args.length < 2)
        {
            // error
            error("usage: regenerator.exe script.lua [args...]");
            return;
        }

        auto file = args[1];
        args = args[2..$];

        // parse script
        auto chunk = luaL_loadfile(L, file.toStringz);
        if (chunk)
        {
            // error
            error(to!string(lua_tostring(L, -1)));
            return;
        }

        // push arguments
        foreach (arg; args)
        {
            lua_pushstring(L, arg.toStringz);
        }

        // execute chunk
        auto result = lua_pcall(L, cast(int) args.length, LUA_MULTRET, 0);
        if (result)
        {
            error(to!string(lua_tostring(L, -1)));
            return;
        }
    }
}

struct UserTypeDummy
{
}

alias LuaFunc = int delegate(lua_State*) @system;

/// 汎用Closure。upvalue#1 から LuaFunc を得て実行する
/// 状態は、LuaFuncに埋めてある。
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

T lua_to(T : string)(lua_State* L, int idx)
{
    auto value = lua_tostring(L, idx);
    return to!string(value);
}

T lua_to(T : int)(lua_State* L, int idx)
{
    auto value = luaL_checkinteger(L, idx);
    return cast(int) value;
}

T lua_to(T : float)(lua_State* L, int idx)
{
    auto value = luaL_checknumber(L, idx);
    return cast(float) value;
}

T lua_to(T)(lua_State* L, int idx)
{
    auto t = lua_type(L, idx);
    if (t == LUA_TUSERDATA)
    {
        if (!lua_getmetatable(L, idx))
        {
            return T();
        }
        lua_getmetatable_from_type!T(L);
        auto isEqual = lua_rawequal(L, -1, -2);
        lua_pop(L, 2); // remove both metatables
        if (isEqual)
        {
            // userdata metatable and metatable from type is same
            static if (isPointer!T)
            {
                // throw new NotImplementedError("isPointer");
                return cast(T) lua_touserdata(L, idx);
            }
            else
            {
                auto p = cast(T*) lua_touserdata(L, idx);
                return *p;
            }
        }
        else
        {
            return T();
        }
    }
    else
    {
        return T();
    }
}

auto lua_totuple()(lua_State* L, int idx)
{
    return tuple();
}

Tuple!A lua_totuple(A)(lua_State* L, int idx)
{
    A first = lua_to!A(L, idx);
    return tuple(first);
}

Tuple!ARGS lua_totuple(ARGS...)(lua_State* L, int idx)
{
    auto first = lua_to!(ARGS[0])(L, idx);
    auto rest = lua_totuple!(ARGS[1 .. $])(L, idx + 1);
    return tuple(first) ~ rest;
}

int lua_push(T : string)(lua_State* L, T value)
{
    lua_pushstring(L, value.toStringz);
    return 1;
}

int lua_push(T : float)(lua_State* L, T value)
{
    lua_pushnumber(L, value);
    return 1;
}

int lua_push(T)(lua_State* L, T value)
{
    auto p = cast(T*) lua_newuserdata(L, T.sizeof);
    auto pushedType = lua_getmetatable_from_type!T(L);
    if (pushedType)
    {
        // set metatable to type userdata
        lua_setmetatable(L, -2);
        *p = value;
        return 1;
    }
    else
    {
        // no metatable
        lua_pop(L, 1);

        // error
        lua_pushstring(L, "push unknown type [%s]".format(typeid(T)).toStringz);
        lua_error(L);
        return 1;
    }
}

LuaFunc to_luafunc(R, ARGS...)(R delegate(ARGS) f)
{
    return delegate(lua_State* L) {
        auto args = lua_totuple!ARGS(L, 1);
        auto value = f(args.expand);
        return lua_push!R(L, value);
    };
}

int lua_getmetatable_from_type(T)(lua_State* L)
{
    lua_pushinteger(L, get_hash!T);
    return lua_gettable(L, LUA_REGISTRYINDEX);
}

struct StaticMethodMap
{
    LuaFunc[string] Map;

    // stack#1: userdata
    // stack#2: key
    int dispatch(lua_State* L)
    {
        auto key = to!string(lua_tostring(L, 2));
        if (key)
        {
            LuaFunc* found = key in Map;
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

struct IndexDispatcher(T)
{
    void Getter(S)(string name, S delegate(T*) f)
    {
        m_map[name] = MetaValue(true, to_luafunc(f));
    }

    // stack#1: userdata
    // stack#2: key
    int dispatch(lua_State* L)
    {
        if (lua_isinteger(L, 2))
        {
            return dispatchIndex(L);
        }

        if (lua_isstring(L, 2))
        {
            return dispatchStringKey(L);
        }

        lua_pushstring(L, "unknown key type '%s'".format(lua_typename(L, 2)).toStringz);
        lua_error(L);
        return 1;
    }

private:
    struct MetaValue
    {
        bool isProperty;
        LuaFunc func;
    }

    MetaValue[string] m_map;

    int dispatchIndex(lua_State* L)
    {
        throw new NotImplementedError("dispatchIndex");
    }

    int dispatchStringKey(lua_State* L)
    {
        auto key = lua_to!string(L, 2);
        auto found = key in m_map;
        if (!found)
        {
            lua_pushstring(L, "'%s' is not found in __index".format(key).toStringz);
            lua_error(L);
            return 1;
        }

        if (found.isProperty)
        {
            try
            {
                // execute getter or setter
                return found.func(L);
            }
            catch (Exception ex)
            {
                lua_pushfstring(L, ex.msg.toStringz);
                lua_error(L);
                return 1;
            }
        }

        // upvalue#1: body
        lua_pushlightuserdata(L, &found.func);
        // upvalue#2: userdata
        lua_pushvalue(L, -3);
        // closure
        lua_pushcclosure(L, &LuaFuncClosure, 2);
        return 1;
    }
}

class UserType(T)
{
    IndexDispatcher!T instance;

private:
    StaticMethodMap m_staticMethods;
    LuaFunc m_typeIndexClosure;

    LuaFunc[LuaMetaKey] m_metamethodMap;

    LuaFunc m_instanceIndexClosure;

    void create_type_metatable(lua_State* L)
    {
        // 型に対するmetatableを作成して stacktop にセットする
        auto created = luaL_newmetatable(L, (typeid(T).name ~ ":type").toStringz);
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

    int create_instance_metatable(lua_State* L)
    {
        if (lua_getmetatable_from_type!T(L) != LUA_TNIL)
        {
            // name already in use?
            return 0; // leave previous value on top, but return 0
        }
        lua_pop(L, 1);

        // create metatable
        lua_createtable(L, 0, 2);
        lua_pushstring(L, (typeid(T).name ~ ":instance").toStringz);
        lua_setfield(L, -2, "__name"); // metatable.__name = tname

        lua_pushinteger(L, get_hash!T);
        lua_pushvalue(L, -2);
        lua_settable(L, LUA_REGISTRYINDEX); // registry[hash] = metatable

        foreach (k, ref v; m_metamethodMap)
        {
            LuaFunc* func = &v;
            lua_pushlightuserdata(L, func);
            lua_pushcclosure(L, &LuaFuncClosure, 1);
            lua_setfield(L, 1, k.toStringz);
        }

        {
            // metatalbe indexer
            lua_pushlightuserdata(L, &m_instanceIndexClosure);
            lua_pushcclosure(L, &LuaFuncClosure, 1);
            lua_setfield(L, 1, "__index");
        }

        return 1;
    }

public:
    this()
    {
        m_typeIndexClosure = (lua_State* L) => m_staticMethods.dispatch(L);
        m_instanceIndexClosure = (lua_State* L) => instance.dispatch(L);
    }

    void staticMethod(RET, ARGS...)(string name, RET delegate(ARGS) method)
    {
        m_staticMethods.Map[name] = to_luafunc(method);
    }

    void metaMethod(RET, ARGS...)(LuaMetaKey key, RET delegate(ARGS) method)
    {
        m_metamethodMap[key] = to_luafunc(method);
    }

    void push(lua_State* L)
    {
        {
            // create instance metatable
            auto create = create_instance_metatable(L);
            assert(create == 1);

            // clear stack
            lua_pop(L, 1);
            assert(lua_gettop(L) == 0);
        }

        // create type userdata
        auto p = cast(UserTypeDummy*) lua_newuserdata(L, UserTypeDummy.sizeof);
        assert(lua_gettop(L) == 1);

        // create type metatable
        create_type_metatable(L);
        assert(lua_gettop(L) == 2);

        // set metatable to type userdata
        lua_setmetatable(L, -2);
        assert(lua_gettop(L) == 1);
    }
}
