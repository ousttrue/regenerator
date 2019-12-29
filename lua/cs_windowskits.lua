require "predefine"
local CS = require "csharp"

------------------------------------------------------------------------------
-- command line
------------------------------------------------------------------------------
local dir = table.unpack {...}

local USAGE = "regenerator.exe cs_windowskits.lua {cs_dst_dir}"
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
local headers = {
    "um/d3d11.h",
    "um/d3dcompiler.h",
    "um/d3d11shader.h",
    "um/d3d10shader.h",
    "shared/dxgi.h"
}
for i, f in ipairs(headers) do
    local header = string.format("%s/%s", src, f)
    print(header)
    headers[i] = header
end
local sourceMap =
    ClangParse {
    headers = headers
}
if not sourceMap then
    error("no sourceMap")
end

------------------------------------------------------------------------------
-- export to dlang
------------------------------------------------------------------------------
local ignoreTypes = {
ID3D10Include = true,
ID3DInclude = true,
ID3DBlob = true,
}
local function filter(decl)
    if ignoreTypes[decl.name] then
        return false
    end

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
        D3D_COMPILE_STANDARD_FILE_INCLUDE = "public static IntPtr D3D_COMPILE_STANDARD_FILE_INCLUDE = new IntPtr(1);",
        DXGI_RESOURCE_PRIORITY_HIGH = "public const int DXGI_RESOURCE_PRIORITY_HIGH = unchecked ((int) 0xa0000000 );",
        DXGI_RESOURCE_PRIORITY_MAXIMUM = "public const int DXGI_RESOURCE_PRIORITY_MAXIMUM = unchecked ((int) 0xc8000000 );"
    }
}

CS.Generate(sourceMap, dir, option)
