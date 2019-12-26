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
local LUA_HEADERS = {"lua.h", "lauxlib.h", "lualib.h"}
local defines = {"LUA_BUILD_AS_DLL=1"} -- public functions has __declspec(dllexport)
local headers = {}
for i, f in ipairs(LUA_HEADERS) do
    table.insert(headers, string.format("%s/%s", src, f))
end
local includes = {}
local externC = true
local sourceMap = parse(headers, includes, defines, externC)
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

local option = {
    macro_map = {
        LUA_VERSION = 'enum LUA_VERSION = "Lua " ~ LUA_VERSION_MAJOR ~ "." ~ LUA_VERSION_MINOR;',
        LUA_REGISTRYINDEX = "enum LUA_REGISTRYINDEX = ( - 1000000 - 1000 );",
        LUAL_NUMSIZES = "enum LUAL_NUMSIZES = ( ( lua_Integer ).sizeof  * 16 + ( lua_Number ).sizeof  );",
        LUA_VERSUFFIX = 'enum LUA_VERSUFFIX = "_" ~ LUA_VERSION_MAJOR ~ "_" ~ LUA_VERSION_MINOR;'
    },
    filter = filter,
    externC = externC,
}

-- clear dir
if file.exists(dir) then
    printf("rmdir %s", dir)
    file.rmdirRecurse(dir)
end

local packageName = basename(dir)
for k, source in pairs(sourceMap) do
    -- write each source
    if not source.empty then
        local path = string.format("%s/%s.d", dir, source.name)
        printf("writeTo: %s", path)
        file.mkdirRecurse(dir)

        do
            -- open
            local f = io.open(path, "w")
            D.Source(f, packageName, source, option)
            io.close(f)
        end
    end
end

do
    -- write package.d
    local path = string.format("%s/package.d", dir)
    printf("writeTo: %s", path)
    file.mkdirRecurse(dir)

    do
        -- open
        local f = io.open(path, "w")
        D.Package(f, packageName, sourceMap)
        io.close(f)
    end
end
