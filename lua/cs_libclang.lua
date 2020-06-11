require 'predefine'
local CS = require 'csharp'

------------------------------------------------------------------------------
-- command line
------------------------------------------------------------------------------
local src, dir = table.unpack {...}

print_table({...})
local USAGE = 'regenerator.exe cs_libclang.lua {LLVM_DIR} {cs_dst_dir}'
if not dir then
    error(USAGE)
end

------------------------------------------------------------------------------
-- libclang CIndex
------------------------------------------------------------------------------
local headers = {"clang-c/Index.h", "clang-c/CXString.h"}
for i, f in ipairs(headers) do
    local header = string.format('%s/%s', src, f)
    print(header)
    headers[i] = header
end
local sourceMap = ClangParse {headers = headers, defines = {}}
if not sourceMap then
    error('no sourceMap')
end

------------------------------------------------------------------------------
-- export to dlang
------------------------------------------------------------------------------
local option = {
    omitEnumPrefix = true,
    macro_map = {},
    dir = dir,
    const = {},
    overload = {},
    dll_map = {
        index = "libclang",
        cxstring = "libclang",
    }
}

CS.Generate(sourceMap, option)
