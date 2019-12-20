module luahelper;
import std.string;
import std.typecons;
import std.conv;
import std.experimental.logger;
import lua;
import luamacros;

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

    void doScript(string file)
    {
        auto result = luaL_dofile(L, file.toStringz);
        if (result != 0)
        {
            log(to!string(lua_tostring(L, -1)));
        }
    }
}

struct UserTypeDummy
{
}

alias LuaFunc = int delegate(lua_State*) @system;

/// 汎用Closure。upvalue#1 から LuaFunc を得て実行する
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

Tuple!ARGS lua_to(ARGS...)(lua_State* L, int idx)
{
    return tuple!ARGS();
}

struct StaticMethodMap
{
private:
    LuaFunc[string] m_methodMap;

public:
    void staticMethod(string name, const LuaFunc lf)
    {
        m_methodMap[name] = lf;
    }

    // stack#1: userdata
    // stack#2: key
    int dispatch(lua_State* L)
    {
        auto key = to!string(lua_tostring(L, 2));
        if (key)
        {
            auto found = key in m_methodMap;
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
                auto func = delegate(lua_State* L) {
                    auto value = lua_to!int(L, -1);
                    logf("#%d => %s", lua_gettop(L), value);
                    return 0;
                };
                lua_pushlightuserdata(L, &func);
                lua_pushcclosure(L, &LuaFuncClosure, 1);
                return 1;

                // lua_pushstring(L, "'%s' not found".format(key).toStringz);
                // lua_error(L);
                // return 1;
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

int lua_push(T)(lua_State* L, T value)
{
    return 0;
}

LuaFunc to_luafunc(R, ARGS...)(R delegate(ARGS) f)
{
    return delegate(lua_State* L) {
        auto args = lua_to!(Tuple!ARGS)(L, 1);
        static if (ARGS.length == 0)
        {
            auto value = f();
        }
        else
        {
            auto value = f(ARGS);
        }
        return lua_push!R(L, value);
    };
}

class UserType(T)
{
private:
    StaticMethodMap m_staticMethods;
    LuaFunc m_typeIndexClosure;

    void create_type_metatable(lua_State* L)
    {
        // 型に対するmetatableを作成して stacktop にセットする
        auto created = luaL_newmetatable(L, typeid(T).name.toStringz);
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

public:
    this()
    {
        m_typeIndexClosure = (lua_State* L) => m_staticMethods.dispatch(L);
    }

    void staticMethod(RET, ARGS...)(string name, RET delegate(ARGS) method)
    {
        m_staticMethods.staticMethod(name, to_luafunc(method));
    }

    void push(lua_State* L)
    {
        // auto name = typeid(T).name;
        auto p = cast(UserTypeDummy*) lua_newuserdata(L, UserTypeDummy.sizeof);
        // int metatable = lua_gettop(L);
        // assert(metatable == 1);
        assert(lua_gettop(L) == 1);

        create_type_metatable(L);
        assert(lua_gettop(L) == 2);

        // // push userdata for Type
        // // set metatable to type userdata
        // auto pushedType = luaL_getmetatable(L, typeid(T).name());
        lua_setmetatable(L, -2);
        assert(lua_gettop(L) == 1);
    }
}
