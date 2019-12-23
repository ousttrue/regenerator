module luautils.luastate;
import liblua;
import luamacros;
import std.conv;
import std.string;
import std.experimental.logger;
import luautils.luastack;

extern (C) int traceback(lua_State* L)
{
    lua_pushglobaltable(L);
    lua_getfield(L, -1, "debug");
    lua_getfield(L, -1, "traceback");
    lua_pushvalue(L, 1);
    lua_pushinteger(L, 2);
    lua_call(L, 2, 1);
    auto msg = lua_to!string(L, -1);
    errorf("%s", msg);
    return 1;
}

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

    void doScript(string src)
    {
        // parse script
        auto chunk = luaL_loadstring(L, src.toStringz);
        if (chunk)
        {
            // error
            error(to!string(lua_tostring(L, -1)));
            return;
        }

        // execute chunk
        auto result = lua_pcall(L, 0, LUA_MULTRET, 0);
        if (result)
        {
            error(to!string(lua_tostring(L, -1)));
            return;
        }
    }

    void cmdline(string[] args)
    {
        if (args.length < 2)
        {
            // error
            error("usage: regenerator.exe script.lua [args...]");
            return;
        }

        auto file = args[1];
        args = args[2 .. $];

        // parse script
        auto chunk = luaL_loadfile(L, file.toStringz);
        if (chunk)
        {
            // error
            error(to!string(lua_tostring(L, -1)));
            return;
        }

        // lua_pushcfunction(L, &traceback);
        // auto handler = lua_gettop(L);

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
