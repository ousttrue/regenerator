local INT_MAX = 2147483647

local function CSConstant(f, macroDefinition, macro_map)
    if not isFirstAlpha(macroDefinition.tokens[1]) then
        local text = macro_map[macroDefinition.name]
        if text then
            writefln(f, "        %s", text)
        else
            local value = table.concat(macroDefinition.tokens, " ")
            local valueType = "int"
            if string.find(value, '%"') then
                valueType = "string"
            elseif string.find(value, "f") then
                valueType = "float"
            elseif string.find(value, "%.") then
                valueType = "double"
            elseif string.find(value, "UL") then
                valueType = "ulong"
            end
            if valueType == "int" then
                local num = tonumber(value)
                if num > INT_MAX then
                    valueType = "uint"
                end
            end
            writefln(f, "        public const %s %s = %s;", valueType, macroDefinition.name, value)
        end
    end
end

local function CSSource(f, packageName, source, option)
    macro_map = option["macro_map"] or {}
    declFilter = option["filter"]
    omitEnumPrefix = option["omitEnumPrefix"]

    writeln(f, HEADLINE)
    writefln(f, "namespace %s {", packageName)
    writeln(f, "    static partial class Constants {")

    if option.injection then
        local inejection = option.injection[source.name]
        if inejection then
            writefln(f, inejection)
        end
    end

    -- const
    for j, macroDefinition in ipairs(source.macros) do
        CSConstant(f, macroDefinition, macro_map)
    end

    -- types
    -- local funcs = {}
    -- for j, decl in ipairs(source.types) do
    --     if not declFilter or declFilter(decl) then
    --         if decl.class == "Function" then
    --             table.insert(funcs, decl)
    --         else
    --             DDecl(f, decl, option)
    --         end
    --     end
    -- end
    -- local function pred(a, b)
    --     return table.concat(a.namespace, ",") < table.concat(b.namespace, ".")
    -- end
    -- table.sort(funcs, pred)
    -- local lastNS = nil
    -- for i, decl in ipairs(funcs) do
    --     if not option.externC then
    --         local ns = table.concat(decl.namespace, ".")
    --         if ns ~= lastNS then
    --             if lastNS then
    --                 writefln(f, "} // %s", lastNS)
    --             end
    --             if string.match(ns, "^%s*$") then
    --                 writefln(f, "extern(C++) {", ns)
    --             else
    --                 writefln(f, "extern(C++, %s) {", ns)
    --             end
    --             lastNS = ns
    --         end
    --     end
    --     DDecl(f, decl, option)
    -- end
    -- if lastNS then
    --     writefln(f, "} // %s", lastNS)
    -- end

    writeln(f, "    }")
    writeln(f, "}")

    return hasComInterface
end

local function ComUtil()
end

local function CSProj(f)
    f:write(
        [[
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
  </PropertyGroup>

</Project>
    ]]
    )
end

local function CSGenerate(sourceMap, dir, option)
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
            local path = string.format("%s/%s.cs", dir, source.name)
            printf("writeTo: %s", path)
            file.mkdirRecurse(dir)

            do
                -- open
                local f = io.open(path, "w")
                if CSSource(f, packageName, source, option) then
                    hasComInterface = true
                end
                io.close(f)
            end
        end
    end

    if hasComInterface then
        -- write utility
        local path = string.format("%s/ComUtil.cs", dir)
        local f = io.open(path, "w")
        ComUtil(f, packageName)
        io.close(f)
    end

    do
        -- csproj
        local path = string.format("%s/ShrimpDX.csproj", dir)
        local f = io.open(path, "w")
        CSProj(f)
        io.close(f)
    end
end

return {
    Generate = CSGenerate
}
