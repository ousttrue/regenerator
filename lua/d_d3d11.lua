require "predefine"
local D = require "dlang"

------------------------------------------------------------------------------
-- command line
------------------------------------------------------------------------------
local args = {...}
print_table(args)

local USAGE = "regenerator.exe d_d3d11.lua {d_dst_dir}"
local dir = args[1]
if not dir then
    error(USAGE)
end

local function getLatestKits()
    local kits = "C:/Program Files (x86)/Windows Kits/10/Include"
    local entries = file.ls(kits)
    table.sort(
        entries,
        function(a, b)
            return (a > b)
        end
    )
    -- print_table(entries)
    for i, e in ipairs(entries) do
        if file.isDir(e) then
            return e
        end
    end
end

local src = getLatestKits()

------------------------------------------------------------------------------
-- libclang CIndex
------------------------------------------------------------------------------
local LUA_HEADERS = {
    "um/d3d11.h",
    "um/d3dcompiler.h",
    "um/d3d11shader.h",
    "um/d3d10shader.h",
    "shared/dxgi.h"
}
local defines = {}
local headers = {}
for i, f in ipairs(LUA_HEADERS) do
    local header = string.format("%s/%s", src, f)
    print(header)
    table.insert(headers, header)
end
local includes = {}
local externC = false
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
        return decl.isExternC
    else
        return true
    end
end

local option = {
    filter = filter,
    omitEnumPrefix = true,
    macro_map = {
        D3D_COMPILE_STANDARD_FILE_INCLUDE = "enum D3D_COMPILE_STANDARD_FILE_INCLUDE = cast(void*)1;"
    }
}

-- clear dir
if file.exists(dir) then
    printf("rmdir %s", dir)
    file.rmdirRecurse(dir)
end

local packageName = basename(dir)
local hasComInterface = false
for k, source in pairs(sourceMap) do
    -- write each source
    if not source.empty then
        local path = string.format("%s/%s.d", dir, source.name)
        printf("writeTo: %s", path)
        file.mkdirRecurse(dir)

        do
            -- open
            local f = io.open(path, "w")
            if D.Source(f, packageName, source, option) then
                hasComInterface = true
            end
            io.close(f)
        end
    end
end

if hasComInterface then
    -- write utility
    local path = string.format("%s/guidutil.d", dir)
    local f = io.open(path, "w")
    D.GuidUtil(f, packageName)
    io.close(f)
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
