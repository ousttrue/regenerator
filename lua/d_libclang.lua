require "predefine"
local D = require "dlang"

------------------------------------------------------------------------------
-- command line
------------------------------------------------------------------------------
local args = {...}
print_table(args)

local USAGE = "regenerator.exe d_libclang.lua {lua_source_dir} {d_dst_dir}"
local src = args[1]
local dir = args[2]
if not dir then
    error(USAGE)
end

------------------------------------------------------------------------------
-- libclang CIndex
------------------------------------------------------------------------------
local LUA_HEADERS = {"clang-c/Index.h", "clang-c/CXString.h"}
local LUA_DEFINES = {}
local headers = {}
for i, f in ipairs(LUA_HEADERS) do
    table.insert(headers, string.format("%s/%s", src, f))
end
local includes = {src}
local externC = false
local sourceMap = parse(headers, includes, LUA_DEFINES, externC)
if sourceMap.empty then
    error("empty")
end

local omitEnumPrefix = true

------------------------------------------------------------------------------
-- export to dlang
------------------------------------------------------------------------------
if not dir then
    return
end

-- avoid c style cast
local DMACRO_MAP = {
    D3D_COMPILE_STANDARD_FILE_INCLUDE = "enum D3D_COMPILE_STANDARD_FILE_INCLUDE = cast(void*)1;",
    ImDrawCallback_ResetRenderState = "enum ImDrawCallback_ResetRenderState = cast( ImDrawCallback ) ( - 1 );",
    LUA_VERSION = 'enum LUA_VERSION = "Lua " ~ LUA_VERSION_MAJOR ~ "." ~ LUA_VERSION_MINOR;',
    LUA_REGISTRYINDEX = "enum LUA_REGISTRYINDEX = ( - 1000000 - 1000 );",
    LUAL_NUMSIZES = "enum LUAL_NUMSIZES = ( ( lua_Integer ).sizeof  * 16 + ( lua_Number ).sizeof  );",
    LUA_VERSUFFIX = 'enum LUA_VERSUFFIX = "_" ~ LUA_VERSION_MAJOR ~ "_" ~ LUA_VERSION_MINOR;'
}

-- clear dir
if file.exists(dir) then
    printf("rmdir %s", dir)
    file.rmdirRecurse(dir)
end

local function filter(decl)
    if decl.class == "Function" then
        return decl.dllExport
    else
        return true
    end
end
-- if (not isMethod) and (not decl.dllExport) then
--     -- filtering functions
--     -- target library(d3d11.h, libclang.h, lua.h) specific...

--     -- for D3D11CreateDevice ... etc
--     local retType = decl.ret
--     -- if (!retType)
--     -- {
--     --     return;
--     -- }
--     if retType.name ~= "HRESULT" then
--         return
--     end
-- -- debug auto isCom = true;
-- end

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
            D.Source(f, packageName, source, DMACRO_MAP, filter, omitEnumPrefix)
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
