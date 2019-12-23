module luamacros;
import liblua;

int lua_pcall(lua_State* L, int n, int r, int f)
{
    return lua_pcallk(L, (n), (r), (f), 0, null);
}

/*
** {==============================================================
** some useful macros
** ===============================================================
*/

// #define lua_getextraspace(L)	((void *)((char *)(L) - LUA_EXTRASPACE))

// #define lua_tonumber(L,i)	lua_tonumberx(L,(i),NULL)
// #define lua_tointeger(L,i)	lua_tointegerx(L,(i),NULL)

void lua_pop(lua_State* L, int n)
{
    lua_settop(L, -(n) - 1);
}

// #define lua_newtable(L)		lua_createtable(L, 0, 0)

void lua_register(lua_State* L, const char* n, lua_CFunction f)
{
    lua_pushcfunction(L, (f)), lua_setglobal(L, (n));
}

void lua_pushcfunction(lua_State* L, lua_CFunction f)
{
    lua_pushcclosure(L, (f), 0);
}

// #define lua_isfunction(L,n)	(lua_type(L, (n)) == LUA_TFUNCTION)
// #define lua_istable(L,n)	(lua_type(L, (n)) == LUA_TTABLE)
// #define lua_islightuserdata(L,n)	(lua_type(L, (n)) == LUA_TLIGHTUSERDATA)
// #define lua_isnil(L,n)		(lua_type(L, (n)) == LUA_TNIL)
// #define lua_isboolean(L,n)	(lua_type(L, (n)) == LUA_TBOOLEAN)
// #define lua_isthread(L,n)	(lua_type(L, (n)) == LUA_TTHREAD)
// #define lua_isnone(L,n)		(lua_type(L, (n)) == LUA_TNONE)
// #define lua_isnoneornil(L, n)	(lua_type(L, (n)) <= 0)

// #define lua_pushliteral(L, s)	lua_pushstring(L, "" s)

// #define lua_pushglobaltable(L)  \
// 	((void)lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS))

char* lua_tostring(lua_State* L, int i)
{
    return lua_tolstring(L, (i), null);
}

// #define lua_insert(L,idx)	lua_rotate(L, (idx), 1)

// #define lua_remove(L,idx)	(lua_rotate(L, (idx), -1), lua_pop(L, 1))

// #define lua_replace(L,idx)	(lua_copy(L, -1, (idx)), lua_pop(L, 1))

int luaL_loadfile(lua_State* L, const char* f)
{
    return luaL_loadfilex(L, f, null);
}

int lua_upvalueindex(int i)
{
    return LUA_REGISTRYINDEX - i;
}

/*
** ===============================================================
** some useful macros
** ===============================================================
*/

// #define luaL_newlibtable(L,l)	\
//   lua_createtable(L, 0, sizeof(l)/sizeof((l)[0]) - 1)

// #define luaL_newlib(L,l)  \
//   (luaL_checkversion(L), luaL_newlibtable(L,l), luaL_setfuncs(L,l,0))

// #define luaL_argcheck(L, cond,arg,extramsg)	\
// 		((void)((cond) || luaL_argerror(L, (arg), (extramsg))))
// #define luaL_checkstring(L,n)	(luaL_checklstring(L, (n), NULL))
// #define luaL_optstring(L,n,d)	(luaL_optlstring(L, (n), (d), NULL))

// #define luaL_typename(L,i)	lua_typename(L, lua_type(L,(i)))

int luaL_dofile(lua_State* L, const char* fn)
{
    return (luaL_loadfile(L, fn) || lua_pcall(L, 0, LUA_MULTRET, 0));
}

int luaL_dostring(lua_State* L, const char* s)
{
    return (luaL_loadstring(L, s) || lua_pcall(L, 0, LUA_MULTRET, 0));
}

// #define luaL_getmetatable(L,n)	(lua_getfield(L, LUA_REGISTRYINDEX, (n)))

// #define luaL_opt(L,f,n,d)	(lua_isnoneornil(L,(n)) ? (d) : f(L,(n)))

// #define luaL_loadbuffer(L,s,sz,n)	luaL_loadbufferx(L,s,sz,n,NULL)
