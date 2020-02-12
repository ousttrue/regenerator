require "predefine"
local D = require "dlang"

------------------------------------------------------------------------------
-- command line
------------------------------------------------------------------------------
local args = {...}
print_table(args)

local USAGE = "regenerator.exe d_imgui.lua {imgui_dir} {d_dst_dir}"
local src = args[1]
local dir = args[2]
if not dir then
    error(USAGE)
end

------------------------------------------------------------------------------
-- libclang CIndex
------------------------------------------------------------------------------
local defines = {"IMGUI_API=__declspec(dllexport)"}
local headers = {
    "imgui.h",
    "examples/imgui_impl_win32.h",
    "examples/imgui_impl_dx11.h",
    "examples/imgui_impl_dx12.h"
}
for i, f in ipairs(headers) do
    local header = string.format("%s/%s", src, f)
    print(header)
    headers[i] = header
end
local sourceMap =
    ClangParse {
    isD = true,
    headers = headers,
    defines = defines
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
local imgui_injection = [[
enum FLT_MAX = 3.402823466e+38F;
]]

local option = {
    macro_map = {
        ImDrawCallback_ResetRenderState = "enum ImDrawCallback_ResetRenderState = cast( ImDrawCallback ) ( - 1 );"
    },
    omitEnumPrefix = true,
    filter = function(decl)
        if decl.class == "Function" then
            return decl.dllExport
        else
            return true
        end
    end,
    injection = {
        imgui = imgui_injection
    }
}

D.Generate(sourceMap, dir, option)
