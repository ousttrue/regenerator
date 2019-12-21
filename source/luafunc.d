module luafunc;
import std.string;
import lua;
import luamacros;
import luastack;

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

LuaFunc to_luafunc(R, ARGS...)(R delegate(ARGS) f)
{
    return delegate(lua_State* L) {
        auto args = lua_totuple!ARGS(L, 1);
        auto value = f(args.expand);
        return lua_push!R(L, value);
    };
}
