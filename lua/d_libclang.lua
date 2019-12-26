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
local defines = {}
for i, f in ipairs(headers) do
    headers[i] = string.format("%s/%s", src, f)
end
local includes = {src}
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

-- clear dir
if file.exists(dir) then
    printf("rmdir %s", dir)
    file.rmdirRecurse(dir)
end

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
            D.Source(f, packageName, source, option)
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
