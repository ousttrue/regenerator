local util = require "predefine"
-- import to global
for k, v in pairs(util) do
    _G[k] = v
end

------------------------------------------------------------------------------
-- command line
------------------------------------------------------------------------------
local args = {...}
print_table(args)

USAGE = "regenerator.exe d_liblua.lua {lua_source_dir} {d_dst_dir}"
local src = args[1]
local dir = args[2]
if not dir then
    error(USAGE)
end

------------------------------------------------------------------------------
-- libclang CIndex
------------------------------------------------------------------------------
LUA_HEADERS = {"lua.h", "lauxlib.h", "lualib.h"}
LUA_DEFINES = {"LUA_BUILD_AS_DLL=1"} -- public functions has __declspec(dllexport)
local headers = {}
for i, f in ipairs(LUA_HEADERS) do
    table.insert(headers, string.format("%s/%s", src, f))
end
local includes = {}
local externC = true
local sourceMap = parse(headers, includes, LUA_DEFINES, externC)
if sourceMap.empty then
    error("empty")
end

------------------------------------------------------------------------------
-- export to dlang
------------------------------------------------------------------------------
if not dir then
    return
end

local omitEnumPrefix = true

print("generate dlang...")

-- clear dir
if file.exists(dir) then
    printf("rmdir %s", dir)
    file.rmdirRecurse(dir)
end

-- write each source
for k, source in pairs(sourceMap) do
    -- source.writeTo(dir);
    if not source.empty then
        -- print(k, source)
        local packageName = basename(dir)

        -- open
        local path = string.format("%s/%s.d", dir, source.name)
        printf("writeTo: %s", path)
        file.mkdirRecurse(dir)

        local f = io.open(path, "w")
        writeln(f, HEADLINE)
        writefln(f, "module %s.%s;", packageName, source.name)

        -- imports
        local modules = {}
        for i, src in ipairs(source.imports) do
            if not src.empty then
                -- inner package
                writefln(f, "import %s.%s;", packageName, src.name)
            end

            for j, m in ipairs(src.modules) do
                -- core.sys.windows.windef etc...
                if modules.find(m).empty then
                    writefln(f, "import %s;", m)
                    table.insert(modules, m)
                end
            end
        end

        -- const
        for j, macroDefinition in ipairs(source.macros) do
            if not isFirstAlpha(macroDefinition.tokens[1]) then
                local p = DMACRO_MAP[macroDefinition.name]
                if p then
                    writeln(f, p)
                else
                    writefln(f, "enum %s = %s;", macroDefinition.name, table.concat(macroDefinition.tokens, " "))
                end
            end
        end

        -- types
        for j, decl in ipairs(source.types) do
            DDecl(f, decl, omitEnumPrefix)
        end

        io.close(f)
    end

    -- write package.d
    do
        local packageName = basename(dir)
        local path = string.format("%s/package.d", dir)
        local f = io.open(path, "w")
        writeln(f, HEADLINE)
        writefln(f, "module %s;", packageName)
        local keys = {}
        for k, source in pairs(sourceMap) do
            table.insert(keys, k)
       end
        table.sort(keys)
        for i, k in ipairs(keys) do
            local source = sourceMap[k]
            if not source.empty then
                writefln(f, "public import %s.%s;", packageName, source.name)
            end
         end
        io.close(f)
    end
end
