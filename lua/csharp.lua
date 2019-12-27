local function ComUtil()
end

local function CSSource()
    return true
end

local function CSProj(f)
    f:write([[
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
  </PropertyGroup>

</Project>
    ]])
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
