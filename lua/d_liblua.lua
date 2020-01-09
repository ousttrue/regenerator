require "predefine"
local D = require "dlang"

------------------------------------------------------------------------------
-- command line
------------------------------------------------------------------------------
local args = {...}
print_table(args)

local USAGE = "regenerator.exe d_liblua.lua {lua_source_dir} {d_dst_dir}"
local src = args[1]
local dir = args[2]
if not dir then
    error(USAGE)
end

------------------------------------------------------------------------------
-- libclang CIndex
------------------------------------------------------------------------------
local defines = {"LUA_BUILD_AS_DLL=1"} -- public functions has __declspec(dllexport)
local headers = {"lua.h", "lauxlib.h", "lualib.h"}
for i, f in ipairs(headers) do
    headers[i] = string.format("%s/%s", src, f)
end
local sourceMap =
    ClangParse {
    isD = true,
    defines = defines,
    externC = true,
    headers = headers
}
if sourceMap.empty then
    error("empty")
end

if not dir then
    return
end

------------------------------------------------------------------------------
-- export to dlang
------------------------------------------------------------------------------
local function filter(decl)
    if decl.class == "Function" then
        -- export functions only dllExport
        -- LUA_BUILD_AS_DLL=1
        return decl.dllExport
    else
        return true
    end
end

local injection_lua = [[
alias lua_Number = double;
alias lua_Integer = long;
]]

local option = {
    macro_map = {
        LUA_VERSION = 'enum LUA_VERSION = "Lua " ~ LUA_VERSION_MAJOR ~ "." ~ LUA_VERSION_MINOR;',
        LUA_REGISTRYINDEX = "enum LUA_REGISTRYINDEX = ( - 1000000 - 1000 );",
        LUAL_NUMSIZES = "enum LUAL_NUMSIZES = ( ( lua_Integer ).sizeof  * 16 + ( lua_Number ).sizeof  );",
        LUA_VERSUFFIX = 'enum LUA_VERSUFFIX = "_" ~ LUA_VERSION_MAJOR ~ "_" ~ LUA_VERSION_MINOR;'
    },
    filter = filter,
    externC = externC,
    injection = {
        lua = injection_lua
    }
}

D.Generate(sourceMap, dir, option)
