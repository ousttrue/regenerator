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
printf("use: %s", src)

------------------------------------------------------------------------------
-- libclang CIndex
------------------------------------------------------------------------------
local headers = {
    "um/d3d11.h",
    "um/d3dcompiler.h",
    "um/d3d11shader.h",
    "um/d3d10shader.h",
    "shared/dxgi.h"
}
for i, f in ipairs(headers) do
    local header = string.format("%s/%s", src, f)
    headers[i] = header
end

local sourceMap =
    ClangParse {
    headers = headers,
    isD = true
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

D.Generate(sourceMap, dir, option)
