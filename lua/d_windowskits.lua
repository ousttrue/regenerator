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
    "shared/dxgi.h",
    "shared/dxgi1_2.h",
    "shared/dxgi1_3.h",
    "shared/dxgi1_4.h",
    "um/d3d12.h",
    "um/d3d11.h",
    "um/d3dcompiler.h",
    "um/d3d11shader.h",
    "um/d3d10shader.h",
    --
    "um/wincodec.h",
    "um/documenttarget.h",
    "um/dwrite.h",
    "um/d2d1.h",
    "um/d2d1effectauthor.h",
    "um/d2d1_2.h"
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
        if startswith(decl.name, "operator") then
            return false
        end 
        return decl.isExternC or decl.dllExport
    else
        return true
    end
end

local param_map = {
    D2D1_BITMAP_INTERPOLATION_MODE_LINEAR = "D2D1_BITMAP_INTERPOLATION_MODE._LINEAR",
    D2D1_DRAW_TEXT_OPTIONS_NONE = "D2D1_DRAW_TEXT_OPTIONS._NONE",
    D2D1_INTERPOLATION_MODE_LINEAR = "D2D1_INTERPOLATION_MODE._LINEAR",
    D2D1_COMPOSITE_MODE_SOURCE_OVER = "D2D1_COMPOSITE_MODE._SOURCE_OVER",
    D2D1_PIXEL_OPTIONS_NONE = "D2D1_PIXEL_OPTIONS._NONE",
    DWRITE_MEASURING_MODE_NATURAL = "DWRITE_MEASURING_MODE._NATURAL"
}

local option = {
    filter = filter,
    omitEnumPrefix = true,
    macro_map = {
        D3D_COMPILE_STANDARD_FILE_INCLUDE = "enum D3D_COMPILE_STANDARD_FILE_INCLUDE = cast(void*)1;",
        DWRITE_EXPORT = "// enum DWRITE_EXPORT = __declspec ( dllimport ) WINAPI;"
    },
    param_map = function(param, value)
        if #value == 0 then
            return
        end
        local found = param_map[value]
        if found then
            -- printf("%s: %s => %s", param, value, found)
            return found
        end
        return value
    end,
    injection = {
        d3dcommon = [[
            // alias ID3DBlob = ID3D10Blob;
        ]]
    }
}

D.Generate(sourceMap, dir, option)
