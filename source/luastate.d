module luastate;
import lua;
import luamacros;
import std.conv;
import std.string;
import std.experimental.logger;

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
        args = args[2 .. $];

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
