module luautils.luastack;
import std.traits;
import std.conv;
import std.string;
import std.exception;
import std.experimental.logger;
import liblua;
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

int lua_push(T : long)(lua_State* L, T value)
{
    lua_pushinteger(L, value);
    return 1;
}

int lua_push(T : float)(lua_State* L, T value)
{
    lua_pushnumber(L, value);
    return 1;
}

int lua_push(T : bool)(lua_State* L, T value)
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
        static if (is(T : Object))
        {
            lua_push(L, &value);
        }
        else
        {
            lua_push(L, value);
        }
        lua_seti(L, -2, i + 1);
    }
    return 1;
}

int lua_push(T : T[string])(lua_State* L, in T[string] values)
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

//
// usertype
//
// # class T(by pointer)
// TODO: keep reference for GC
// ## push: class T
// &t
// ## push: class T*
// t
// ## to: class T
// *t
// ## to: class T*
// t
//
// # struct not POD(must pointer)
// TODO:
//
// # struct POD(by value)
// ## push: class T
// t
// ## push: class T*
// *t
// ## to: class T
// t
// ## to: class T*
// &t

template ClassOrStruct(T)
{
    immutable tIsPointer = isPointer!T;
    static if (tIsPointer)
    {
        alias TT = PointerTarget!T;
    }
    else
    {
        alias TT = T;
    }

    // double pointer is not implemented
    static assert(!isPointer!TT);

    immutable tIsPOD = __traits(isPOD, TT);

    // class
    int push(lua_State* L, T value)
    {
        static if (tIsPointer)
        {
            if (value == null)
            {
                return 0;
            }
        }

        // set metatable to type userdata
        static if (!tIsPOD)
        {
            // class
            auto size = (TT*).sizeof;
            auto p = cast(TT**) lua_newuserdata(L, size);
            auto hasMetatable = lua_getmetatable_from_type!TT(L);
            if (hasMetatable)
            {
                static if (tIsPointer)
                {
                    // pointer
                    *p = value;
                    lua_setmetatable(L, -2);
                }
                else
                {
                    // pointer
                    *p = &value;
                    lua_setmetatable(L, -2);
                }
                return 1;
            }
        }
        else
        {
            // POD
            auto p = cast(TT*) lua_newuserdata(L, TT.sizeof);
            auto hasMetatable = lua_getmetatable_from_type!TT(L);
            if (hasMetatable)
            {
                static if (tIsPointer)
                {
                    // copy
                    *p = *value;
                    lua_setmetatable(L, -2);
                }
                else
                {
                    // copy
                    *p = value;
                    lua_setmetatable(L, -2);
                }
                return 1;
            }
        }

        // no metatable
        lua_pop(L, 1);

        // error
        lua_pushstring(L, "push unknown type [%s]".format(typeid(T)).toStringz);
        lua_error(L);
        return 1;
    }

    T defReturn()
    {
        T value;
        return value;
    }

    T to(lua_State* L, int idx)
    {
        auto t = lua_type(L, idx);
        if (t != LUA_TUSERDATA)
        {
            return defReturn();
        }
        if (!lua_getmetatable(L, idx))
        {
            return defReturn();
        }

        lua_getmetatable_from_type!TT(L);
        auto isEqual = lua_rawequal(L, -1, -2);
        lua_pop(L, 2); // remove both metatables
        if (!isEqual)
        {
            return defReturn();
        }

        static if (!tIsPOD)
        {
            // class
            auto p = cast(TT**) lua_touserdata(L, idx);
            static if (tIsPointer)
            {
                return *p;
            }
            else
            {
                return **p;
            }
        }
        else
        {
            // struct
            auto p = cast(TT*) lua_touserdata(L, idx);
            static if (tIsPointer)
            {
                return p;
            }
            else
            {
                return *p;
            }
        }
    }
}

int lua_push(T)(lua_State* L, T value)
{
    return ClassOrStruct!T.push(L, value);
}

T lua_to(T)(lua_State* L, int idx)
{
    return ClassOrStruct!T.to(L, idx);
}
