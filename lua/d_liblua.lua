require "predefine"
local D = require "dlang"

------------------------------------------------------------------------------
-- command line
------------------------------------------------------------------------------
local args = {...}
print_table(args)

USAGE = "regenerator.exe d_liblua.lua {lua_source_dir} {d_dst_dir}"
local src = args[1]
local dir = args[2]
if not dir then
    error(USAGE)
end

------------------------------------------------------------------------------
-- libclang CIndex
------------------------------------------------------------------------------
LUA_HEADERS = {"lua.h", "lauxlib.h", "lualib.h"}
LUA_DEFINES = {"LUA_BUILD_AS_DLL=1"} -- public functions has __declspec(dllexport)
local headers = {}
for i, f in ipairs(LUA_HEADERS) do
    table.insert(headers, string.format("%s/%s", src, f))
end
local includes = {}
local externC = true
local sourceMap = parse(headers, includes, LUA_DEFINES, externC)
if sourceMap.empty then
    error("empty")
end

------------------------------------------------------------------------------
-- export to dlang
------------------------------------------------------------------------------
if not dir then
    return
end

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
            D.Source(f, packageName, source)
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
