local HEADLINE = "// This source code was generated by regenerator"

local DESCAPE_SYMBOLS = {module = true, ref = true, ["in"] = true}

local function DEscapeName(src)
    if DESCAPE_SYMBOLS[src] then
        return "_" .. src
    end
    return src
end

local DTYPE_MAP = {
    Void = "void",
    Bool = "bool",
    Int8 = "char",
    Int16 = "short",
    Int32 = "int",
    Int64 = "long",
    UInt8 = "ubyte",
    UInt16 = "ushort",
    UInt32 = "uint",
    UInt64 = "ulong",
    Float = "float",
    Double = "double"
}

local function isInterface(decl)
    decl = decl.typedefSource

    if decl.class ~= "Struct" then
        return false
    end

    if decl.definition then
        -- resolve forward decl
        decl = decl.definition
    end

    return decl.isInterface
end

local function DType(t, isParam)
    local name = DTYPE_MAP[t.class]
    if name then
        return name
    end
    if t.class == "Pointer" then
        -- return DPointer(t)
        if t.ref.type.name == "ID3DInclude" then
            return "void*   "
        elseif isInterface(t.ref.type) then
            return string.format("%s", DType(t.ref.type, isParam))
        else
            local typeName = DType(t.ref.type, isParam)
            if t.ref.isConst then
                typeName = string.format("const(%s)", typeName)
            end
            return string.format("%s*", typeName)
        end
    elseif t.class == "Reference" then
        -- return DPointer(t)
        local typeName = DType(t.ref.type, isParam)
        if t.ref.isConst and isParam then
            typeName = string.format("in %s", typeName)
        else
            typeName = string.format("ref %s", typeName)
        end
        return typeName
    elseif t.class == "Array" then
        -- return DArray(t)
        local a = t
        return string.format("%s[%d]", DType(a.ref.type, isParam), a.size)
    else
        if #t.name == 0 then
            return nil
        end
        return t.name
    end
end

local function DTypedefDecl(f, t)
    -- print(t, t.ref)
    local dst = DType(t.ref.type)
    if dst then
        if t.name == dst then
            -- f.writefln("// samename: %s", t.m_name);
            return
        end

        writefln(f, "alias %s = %s;", t.name, dst)
        return
    end

    -- nameless
    writeln(f, "// typedef target nameless")
end

local function DEnumDecl(f, decl, omitEnumPrefix)
    if not decl.name then
        writeln(f, "// enum nameless")
        return
    end

    writef(f, "enum %s", decl.name)
    writeln(f)

    if omitEnumPrefix then
        decl.omit()
    end

    writeln(f, "{")
    for i, value in ipairs(decl.values) do
        writefln(f, "    %s = 0x%x,", value.name, value.value)
    end
    writeln(f, "}")
end

local function getValue(param, param_map)
    local value = ""
    local values = param.values
    if #values > 0 then
        if #values == 1 and values[1] == "NULL" then
            value = "=null"
        else
            if values[1] == "sizeof" then
                values = {table.unpack(values, 2, #values)}
                table.insert(values, ".sizeof")
            end
            value = "=" .. table.concat(values, "")
        end
    end
    if param_map then
        local newValue = param_map(param, value)
        if newValue then
            value = newValue
        end
    end
    return value
end

local function DFunctionDecl(f, decl, indent, isMethod, option)
    indent = indent or ""

    f:write(indent)
    if not isMethod then
        if decl.isExternC then
            f:write("extern(C) ")
        else
            f:write(string.format("extern(C++) ", ns))
        end
    end

    f:write(DType(decl.ret))
    f:write(" ")
    f:write(decl.name)
    f:write("(")

    local isFirst = true
    for i, param in ipairs(decl.params) do
        if isFirst then
            isFirst = false
        else
            f:write(", ")
        end

        local dst = DType(param.ref.type, true)
        if param.ref.isConst then
            dst = string.format("const(%s)", dst)
        end
        f:write(string.format("%s %s%s", dst, DEscapeName(param.name), getValue(param, option.param_map)))
    end
    writeln(f, ");")
end

local SKIP_METHODS = {QueryInterface = true, AddRef = true, Release = true}

local function DStructDecl(f, decl, option)
    -- assert(!decl.m_forwardDecl);
    local name = decl.name
    if not name or #name == 0 then
        writeln(f, "// struct nameless")
        return
    end

    if decl.isInterface then
        -- com interface
        if decl.isForwardDecl then
            return
        end

        -- interface
        writef(f, "interface %s", name)
        if decl.base then
            writef(f, ": %s", decl.base.name)
        end

        writeln(f)
        writeln(f, "{")
        if decl.iid then
            writefln(f, '    static const iidof = parseGUID("%s");', decl.iid)
        end

        -- methods
        for i, method in ipairs(decl.methods) do
            if SKIP_METHODS[method.name] then
                writefln(f, "    // skip %s", method.name)
            else
                DFunctionDecl(f, method, "    ", true, option)
            end
        end
        writeln(f, "}")
    else
        if decl.isForwardDecl then
            -- forward decl
            if #decl.fields > 0 then
                error("forward decl has fields")
            end
            writefln(f, "struct %s;", name)
        else
            writefln(f, "struct %s", name)
            writeln(f, "{")
            for i, field in ipairs(decl.fields) do
                local typeName = DType(field.ref.type)
                if not typeName then
                    local fieldType = field.ref.type
                    if fieldType.class == "Struct" then
                        if fieldType.isUnion then
                            writefln(f, "    union {")
                            for i, unionField in ipairs(fieldType.fields) do
                                local unionFieldTypeName = DType(unionField.ref.type)
                                writefln(f, "        %s %s;", unionFieldTypeName, DEscapeName(unionField.name))
                            end
                            writefln(f, "    }")
                        else
                            writefln(f, "   // anonymous struct %s;", DEscapeName(field.name))
                        end
                    else
                        error("unknown")
                    end
                else
                    if field.ref.isConst then
                        typeName = "const(" .. typeName .. ")"
                    end

                    writefln(f, "    %s %s;", typeName, DEscapeName(field.name))
                end
            end

            writeln(f, "}")
        end
    end
end

local function DDecl(f, decl, option)
    if decl.class == "Typedef" then
        DTypedefDecl(f, decl)
    elseif decl.class == "Enum" then
        DEnumDecl(f, decl, option.omitEnumPrefix)
    elseif decl.class == "Struct" then
        DStructDecl(f, decl, option)
    elseif decl.class == "Function" then
        DFunctionDecl(f, decl, "", false, option)
    else
        error("unknown", decl)
    end
end

local function DImport(f, packageName, src, modules)
    if not src.empty then
        -- inner package
        writefln(f, "import %s.%s;", packageName, src.name)
    end

    local hasComInterface = false
    for j, m in ipairs(src.modules) do
        -- core.sys.windows.windef etc...
        if not modules[m] then
            modules[m] = true
            writefln(f, "import %s;", m)
        end
        if m == "core.sys.windows.unknwn" then
            writefln(f, "import %s.guidutil;", packageName)
            hasComInterface = true
        end
    end
    return hasComInterface
end

local function DConstant(f, macroDefinition, macro_map)
    if not isFirstAlpha(macroDefinition.tokens[1]) then
        local p = macro_map[macroDefinition.name]
        if p then
            writeln(f, p)
        else
            writefln(f, "enum %s = %s;", macroDefinition.name, table.concat(macroDefinition.tokens, " "))
        end
    end
end

local function DSource(f, packageName, source, option)
    macro_map = option["macro_map"] or {}
    declFilter = option["filter"]
    omitEnumPrefix = option["omitEnumPrefix"]

    writeln(f, HEADLINE)
    writefln(f, "module %s.%s;", packageName, source.name)

    -- imports
    local hasComInterface = false
    local modules = {}
    for i, src in ipairs(source.imports) do
        if DImport(f, packageName, src, modules) then
            hasComInterface = true
        end
    end

    if option.injection then
        local inejection = option.injection[source.name]
        if inejection then
            writefln(f, inejection)
        end
    end

    -- const
    for j, macroDefinition in ipairs(source.macros) do
        DConstant(f, macroDefinition, option.macro_map)
    end

    -- types
    local funcs = {}
    for j, decl in ipairs(source.types) do
        if not declFilter or declFilter(decl) then
            if decl.class == "Function" then
                table.insert(funcs, decl)
            else
                DDecl(f, decl, option)
            end
        end
    end
    local function pred(a, b)
        return table.concat(a.namespace, ",") < table.concat(b.namespace, ".")
    end
    table.sort(funcs, pred)
    local lastNS = nil
    for i, decl in ipairs(funcs) do
        if not option.externC then
            local ns = table.concat(decl.namespace, ".")
            if ns ~= lastNS then
                if lastNS then
                    writefln(f, "} // %s", lastNS)
                end
                if string.match(ns, "^%s*$") then
                    writefln(f, "extern(C++) {", ns)
                else
                    writefln(f, "extern(C++, %s) {", ns)
                end
                lastNS = ns
            end
        end
        DDecl(f, decl, option)
    end
    if lastNS then
        writefln(f, "} // %s", lastNS)
    end

    return hasComInterface
end

local function DPackage(f, packageName, sourceMap)
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
end

local function DGuidUtil(f, packageName)
    writefln(f, "module %s.guidutil;", packageName)
    writeln(
        f,
        [[

import std.uuid;
import core.sys.windows.basetyps;

GUID parseGUID(string guid)
{
    return toGUID(parseUUID(guid));
}
GUID toGUID(immutable std.uuid.UUID uuid)
{
    ubyte[8] data=uuid.data[8..$];
    return GUID(
                uuid.data[0] << 24
                |uuid.data[1] << 16
                |uuid.data[2] << 8
                |uuid.data[3],

                uuid.data[4] << 8
                |uuid.data[5],

                uuid.data[6] << 8
                |uuid.data[7],

                data
                );
}
]]
    )
end

return {
    Decl = DDecl,
    Import = DImport,
    Const = DConstant,
    Package = DPackage,
    Source = DSource,
    GuidUtil = DGuidUtil
}
