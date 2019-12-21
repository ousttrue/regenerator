module luautils.luastack;
import std.traits;
import std.conv;
import std.string;
import std.typecons;
import lua;
import luamacros;

template rawtype(T)
{
    static if (isPointer!T)
    {
        rawtype!(PointerTarget!T) rawtype;
    }
    else
    {
        T rawtype;
    }
}

ulong get_hash(T)()
{
    auto ti = typeid(T);
    auto hash = ti.toHash();
    // logf("%s => %d", ti.name, hash);
    return hash;
}

int lua_getmetatable_from_type(T)(lua_State* L)
{
    lua_pushinteger(L, get_hash!T);
    return lua_gettable(L, LUA_REGISTRYINDEX);
}

string lua_to(T : string)(lua_State* L, int idx)
{
    auto value = lua_tostring(L, idx);
    return to!string(value);
}

bool lua_to(T : bool)(lua_State* L, int idx)
{
    return lua_toboolean(L, idx) != 0;
}

int lua_to(T : int)(lua_State* L, int idx)
{
    auto value = luaL_checkinteger(L, idx);
    return cast(int) value;
}

T lua_to(T : float)(lua_State* L, int idx)
{
    auto value = luaL_checknumber(L, idx);
    return cast(float) value;
}

T[] lua_to(T : T[])(lua_State* L, int idx)
{
    T[] values;
    auto t = lua_type(L, idx);
    if (t == LUA_TTABLE)
    {
        auto n = lua_rawlen(L, idx);
        for (int i = 1; i <= n; ++i)
        {
            lua_geti(L, idx, i);
            values ~= lua_to!T(L, lua_gettop(L));
            lua_pop(L, 1);
        }
    }
    else if (t == LUA_TNIL)
    {

    }
    else
    {
        // non table value
        values ~= lua_to!T(L, idx);
    }
    return values;
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
            // static if (isPointer!T)
            // {
            //     // throw new NotImplementedError("isPointer");
            //     return cast(T) lua_touserdata(L, idx);
            // }
            // else
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

bool lua_push(T : bool)(lua_State* L, T value)
{
    lua_pushboolean(L, value);
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
