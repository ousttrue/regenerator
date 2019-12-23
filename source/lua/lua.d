// This source code was generated by regenerator
module lua.lua;
import lua.vcruntime;
import lua.vadefs;
enum LUA_VERSION_MAJOR = "5";
enum LUA_VERSION_MINOR = "3";
enum LUA_VERSION_NUM = 503;
enum LUA_VERSION_RELEASE = "5";
enum LUA_VERSION = "Lua " ~ LUA_VERSION_MAJOR ~ "." ~ LUA_VERSION_MINOR;
enum LUA_AUTHORS = "R. Ierusalimschy, L. H. de Figueiredo, W. Celes";
enum LUA_SIGNATURE = "\x1bLua";
enum LUA_MULTRET = ( - 1 );
enum LUA_REGISTRYINDEX = ( - 1000000 - 1000 );
enum LUA_OK = 0;
enum LUA_YIELD = 1;
enum LUA_ERRRUN = 2;
enum LUA_ERRSYNTAX = 3;
enum LUA_ERRMEM = 4;
enum LUA_ERRGCMM = 5;
enum LUA_ERRERR = 6;
enum LUA_TNONE = ( - 1 );
enum LUA_TNIL = 0;
enum LUA_TBOOLEAN = 1;
enum LUA_TLIGHTUSERDATA = 2;
enum LUA_TNUMBER = 3;
enum LUA_TSTRING = 4;
enum LUA_TTABLE = 5;
enum LUA_TFUNCTION = 6;
enum LUA_TUSERDATA = 7;
enum LUA_TTHREAD = 8;
enum LUA_NUMTAGS = 9;
enum LUA_MINSTACK = 20;
enum LUA_RIDX_MAINTHREAD = 1;
enum LUA_RIDX_GLOBALS = 2;
enum LUA_OPADD = 0;
enum LUA_OPSUB = 1;
enum LUA_OPMUL = 2;
enum LUA_OPMOD = 3;
enum LUA_OPPOW = 4;
enum LUA_OPDIV = 5;
enum LUA_OPIDIV = 6;
enum LUA_OPBAND = 7;
enum LUA_OPBOR = 8;
enum LUA_OPBXOR = 9;
enum LUA_OPSHL = 10;
enum LUA_OPSHR = 11;
enum LUA_OPUNM = 12;
enum LUA_OPBNOT = 13;
enum LUA_OPEQ = 0;
enum LUA_OPLT = 1;
enum LUA_OPLE = 2;
enum LUA_GCSTOP = 0;
enum LUA_GCRESTART = 1;
enum LUA_GCCOLLECT = 2;
enum LUA_GCCOUNT = 3;
enum LUA_GCCOUNTB = 4;
enum LUA_GCSTEP = 5;
enum LUA_GCSETPAUSE = 6;
enum LUA_GCSETSTEPMUL = 7;
enum LUA_GCISRUNNING = 9;
enum LUA_HOOKCALL = 0;
enum LUA_HOOKRET = 1;
enum LUA_HOOKLINE = 2;
enum LUA_HOOKCOUNT = 3;
enum LUA_HOOKTAILCALL = 4;
enum LUA_MASKCALL = ( 1 << LUA_HOOKCALL );
enum LUA_MASKRET = ( 1 << LUA_HOOKRET );
enum LUA_MASKLINE = ( 1 << LUA_HOOKLINE );
enum LUA_MASKCOUNT = ( 1 << LUA_HOOKCOUNT );
struct lua_State;
alias lua_Number = double;
alias lua_Integer = long;
alias lua_Unsigned = ulong;
alias lua_KContext = ptrdiff_t;
alias lua_CFunction = void*;
alias lua_KFunction = void*;
alias lua_Reader = void*;
alias lua_Writer = void*;
alias lua_Alloc = void*;
extern(C) lua_State* lua_newstate(lua_Alloc f, void* ud);
extern(C) void lua_close(lua_State* L);
extern(C) lua_State* lua_newthread(lua_State* L);
extern(C) lua_CFunction lua_atpanic(lua_State* L, lua_CFunction panicf);
extern(C) lua_Number* lua_version(lua_State* L);
extern(C) int lua_absindex(lua_State* L, int idx);
extern(C) int lua_gettop(lua_State* L);
extern(C) void lua_settop(lua_State* L, int idx);
extern(C) void lua_pushvalue(lua_State* L, int idx);
extern(C) void lua_rotate(lua_State* L, int idx, int n);
extern(C) void lua_copy(lua_State* L, int fromidx, int toidx);
extern(C) int lua_checkstack(lua_State* L, int n);
extern(C) void lua_xmove(lua_State* from, lua_State* to, int n);
extern(C) int lua_isnumber(lua_State* L, int idx);
extern(C) int lua_isstring(lua_State* L, int idx);
extern(C) int lua_iscfunction(lua_State* L, int idx);
extern(C) int lua_isinteger(lua_State* L, int idx);
extern(C) int lua_isuserdata(lua_State* L, int idx);
extern(C) int lua_type(lua_State* L, int idx);
extern(C) char* lua_typename(lua_State* L, int tp);
extern(C) lua_Number lua_tonumberx(lua_State* L, int idx, int* isnum);
extern(C) lua_Integer lua_tointegerx(lua_State* L, int idx, int* isnum);
extern(C) int lua_toboolean(lua_State* L, int idx);
extern(C) char* lua_tolstring(lua_State* L, int idx, size_t* len);
extern(C) size_t lua_rawlen(lua_State* L, int idx);
extern(C) lua_CFunction lua_tocfunction(lua_State* L, int idx);
extern(C) void* lua_touserdata(lua_State* L, int idx);
extern(C) lua_State* lua_tothread(lua_State* L, int idx);
extern(C) void* lua_topointer(lua_State* L, int idx);
extern(C) void lua_arith(lua_State* L, int op);
extern(C) int lua_rawequal(lua_State* L, int idx1, int idx2);
extern(C) int lua_compare(lua_State* L, int idx1, int idx2, int op);
extern(C) void lua_pushnil(lua_State* L);
extern(C) void lua_pushnumber(lua_State* L, lua_Number n);
extern(C) void lua_pushinteger(lua_State* L, lua_Integer n);
extern(C) char* lua_pushlstring(lua_State* L, const char* s, size_t len);
extern(C) char* lua_pushstring(lua_State* L, const char* s);
extern(C) char* lua_pushvfstring(lua_State* L, const char* fmt, va_list argp);
extern(C) char* lua_pushfstring(lua_State* L, const char* fmt);
extern(C) void lua_pushcclosure(lua_State* L, lua_CFunction fn, int n);
extern(C) void lua_pushboolean(lua_State* L, int b);
extern(C) void lua_pushlightuserdata(lua_State* L, void* p);
extern(C) int lua_pushthread(lua_State* L);
extern(C) int lua_getglobal(lua_State* L, const char* name);
extern(C) int lua_gettable(lua_State* L, int idx);
extern(C) int lua_getfield(lua_State* L, int idx, const char* k);
extern(C) int lua_geti(lua_State* L, int idx, lua_Integer n);
extern(C) int lua_rawget(lua_State* L, int idx);
extern(C) int lua_rawgeti(lua_State* L, int idx, lua_Integer n);
extern(C) int lua_rawgetp(lua_State* L, int idx, const void* p);
extern(C) void lua_createtable(lua_State* L, int narr, int nrec);
extern(C) void* lua_newuserdata(lua_State* L, size_t sz);
extern(C) int lua_getmetatable(lua_State* L, int objindex);
extern(C) int lua_getuservalue(lua_State* L, int idx);
extern(C) void lua_setglobal(lua_State* L, const char* name);
extern(C) void lua_settable(lua_State* L, int idx);
extern(C) void lua_setfield(lua_State* L, int idx, const char* k);
extern(C) void lua_seti(lua_State* L, int idx, lua_Integer n);
extern(C) void lua_rawset(lua_State* L, int idx);
extern(C) void lua_rawseti(lua_State* L, int idx, lua_Integer n);
extern(C) void lua_rawsetp(lua_State* L, int idx, const void* p);
extern(C) int lua_setmetatable(lua_State* L, int objindex);
extern(C) void lua_setuservalue(lua_State* L, int idx);
extern(C) void lua_callk(lua_State* L, int nargs, int nresults, lua_KContext ctx, lua_KFunction k);
extern(C) int lua_pcallk(lua_State* L, int nargs, int nresults, int errfunc, lua_KContext ctx, lua_KFunction k);
extern(C) int lua_load(lua_State* L, lua_Reader reader, void* dt, const char* chunkname, const char* mode);
extern(C) int lua_dump(lua_State* L, lua_Writer writer, void* data, int strip);
extern(C) int lua_yieldk(lua_State* L, int nresults, lua_KContext ctx, lua_KFunction k);
extern(C) int lua_resume(lua_State* L, lua_State* from, int narg);
extern(C) int lua_status(lua_State* L);
extern(C) int lua_isyieldable(lua_State* L);
extern(C) int lua_gc(lua_State* L, int what, int data);
extern(C) int lua_error(lua_State* L);
extern(C) int lua_next(lua_State* L, int idx);
extern(C) void lua_concat(lua_State* L, int n);
extern(C) void lua_len(lua_State* L, int idx);
extern(C) size_t lua_stringtonumber(lua_State* L, const char* s);
extern(C) lua_Alloc lua_getallocf(lua_State* L, void** ud);
extern(C) void lua_setallocf(lua_State* L, lua_Alloc f, void* ud);
struct lua_Debug
{
    int event;
    char* name;
    char* namewhat;
    char* what;
    char* source;
    int currentline;
    int linedefined;
    int lastlinedefined;
    ubyte nups;
    ubyte nparams;
    char isvararg;
    char istailcall;
    char[60] short_src;
    CallInfo* i_ci;
}
struct CallInfo;
alias lua_Hook = void*;
extern(C) int lua_getstack(lua_State* L, int level, lua_Debug* ar);
extern(C) int lua_getinfo(lua_State* L, const char* what, lua_Debug* ar);
extern(C) char* lua_getlocal(lua_State* L, const lua_Debug* ar, int n);
extern(C) char* lua_setlocal(lua_State* L, const lua_Debug* ar, int n);
extern(C) char* lua_getupvalue(lua_State* L, int funcindex, int n);
extern(C) char* lua_setupvalue(lua_State* L, int funcindex, int n);
extern(C) void* lua_upvalueid(lua_State* L, int fidx, int n);
extern(C) void lua_upvaluejoin(lua_State* L, int fidx1, int n1, int fidx2, int n2);
extern(C) void lua_sethook(lua_State* L, lua_Hook func, int mask, int count);
extern(C) lua_Hook lua_gethook(lua_State* L);
extern(C) int lua_gethookmask(lua_State* L);
extern(C) int lua_gethookcount(lua_State* L);
