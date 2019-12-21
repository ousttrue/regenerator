module luautils.luafunc;
import std.string;
import std.typecons;
import lua;
import luamacros;
import luautils.luastack;

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

//
// tuple
//

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

LuaFunc to_luafunc(R, ARGS...)(R delegate(ARGS) f)
{
    return delegate(lua_State* L) {
        auto args = lua_totuple!ARGS(L, 1);
        auto value = f(args.expand);
        return lua_push!R(L, value);
    };
}
