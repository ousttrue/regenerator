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
        D3D_COMPILE_STANDARD_FILE_INCLUDE = "public static System.IntPtr D3D_COMPILE_STANDARD_FILE_INCLUDE = new System.IntPtr(1);"
    }
}

CS.Generate(sourceMap, dir, option)
