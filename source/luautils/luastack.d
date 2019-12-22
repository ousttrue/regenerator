module luautils.luastack;
import std.traits;
import std.conv;
import std.string;
import std.exception;
import lua;
import luamacros;

template rawtype(T)
{
    static if (isPointer!T)
    {
        alias rawtype = rawtype!(PointerTarget!T);
    }
    else
    {
        alias rawtype = T;
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

//
// primitives
//

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

//
// collection
//

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

int lua_push(T : T[])(lua_State* L, T[] values)
{
    lua_createtable(L, cast(int) values.length, 0);
    foreach (i, ref value; values)
    {
        lua_push(L, &value);
        lua_seti(L, -2, i + 1);
    }
    return 1;
}

//
// usertype
//
//
// # class T(by pointer)
// ## push: class T
// &t
// ## push: class T*
// t
// ## to: class T
// *t
// ## to: class T*
// t
//
// # struct T(by value)
// ## push: class T
// t
// ## push: class T*
// *t
// ## to: class T
// t
// ## to: class T*
// &t

///
/// push Object
///
int lua_push(T : Object)(lua_State* L, T* value)
{
    auto p = cast(T**) lua_newuserdata(L, T.sizeof);
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

T lua_to(T)(lua_State* L, int idx)
{
    static if (isPointer!T)
    {
        return lua_to_object_pointer!(rawtype!T)(L, idx);
    }
    else
    {
        throw new Exception("lua_to!T");
    }
}

T* lua_to_object_pointer(T : Object)(lua_State* L, int idx)
{
    auto t = lua_type(L, idx);
    if (t == LUA_TUSERDATA)
    {
        if (!lua_getmetatable(L, idx))
        {
            return null;
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
                auto p = cast(T**) lua_touserdata(L, idx);
                debug
                {
                    auto a = 0;
                }
                return *p;
            }
        }
        else
        {
            return null;
        }
    }
    else
    {
        return null;
    }
}
