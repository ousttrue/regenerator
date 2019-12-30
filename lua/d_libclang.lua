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
local headers = {"clang-c/Index.h", "clang-c/CXString.h"}
for i, f in ipairs(headers) do
    headers[i] = string.format("%s/%s", src, f)
end
local includes = {src}
local sourceMap = ClangParse{
    isD = true,
    headers=headers, 
    includes=includes,
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
        -- export functions only dllExport
        return decl.dllExport
    else
        return true
    end
end

local option = {
    omitEnumPrefix = true,
    filter = filter
}

D.Generate(sourceMap, dir, option)
