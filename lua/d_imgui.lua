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
    "imgui.h"
}
for i, f in ipairs(headers) do
    local header = string.format("%s/%s", src, f)
    print(header)
    headers[i] = header
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
local imgui_injection =
    [[
enum FLT_MAX = 3.402823466e+38F;
]]

local param_map = {
}

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
    },
    param_map = function(param, value)
        if param.ref.hasConstRecursive then
            if param_map[value] then
                value = param_map[value]
            end
        end
        return value
    end
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
