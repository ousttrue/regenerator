require "predefine"
local CS = require "csharp"

------------------------------------------------------------------------------
-- command line
------------------------------------------------------------------------------
local dir = table.unpack {...}

local USAGE = "regenerator.exe cs_windowskits.lua {cs_dst_dir}"
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

------------------------------------------------------------------------------
-- libclang CIndex
------------------------------------------------------------------------------
local headers = {
    "um/d3d11.h",
    "um/d3dcompiler.h",
    "um/d3d11shader.h",
    "um/d3d10shader.h",
    "shared/dxgi.h",
    --
    "um/timeapi.h",
    "um/winuser.h"
}
for i, f in ipairs(headers) do
    local header = string.format("%s/%s", src, f)
    print(header)
    headers[i] = header
end
local sourceMap =
    ClangParse {
    headers = headers
}
if not sourceMap then
    error("no sourceMap")
end

------------------------------------------------------------------------------
-- export to dlang
------------------------------------------------------------------------------
local ignoreTypes = {}
local function filter(decl)
    if ignoreTypes[decl.name] then
        return false
    end

    if decl.class == "Function" then
        return decl.isExternC
    else
        return true
    end
end
local function remove_MAKEINTRESOURCE(prefix, tokens)
    local items = {}
    for _, t in ipairs(tokens) do
        if t == "MAKEINTRESOURCE" then
        else
            table.insert(items, t)
        end
    end
    return table.concat(items, " ")
end
local function rename_values(prefix, tokens)
    local items = {}
    for _, t in ipairs(tokens) do
        local rename = string.gsub(t, "^" .. prefix .. "_", "")
        if rename ~= t then
            -- 数字で始まる場合があるので
            rename = "_" .. rename
        end
        if rename:sub(#rename) == "L" then
            rename = string.sub(rename, 1, #rename - 1)
        end
        table.insert(items, rename)
    end
    return table.concat(items, " ")
end
local function rename_values_dm(prefix, tokens)
    local items = {}
    for _, t in ipairs(tokens) do
        if t == "WM_USER" then
            table.insert(items, "WM._USER")
        else
            local rename = string.gsub(t, "^" .. prefix .. "_", "")
            if rename ~= t then
                -- 数字で始まる場合があるので
                rename = "_" .. rename
            end
            if rename:sub(#rename) == "L" then
                rename = string.sub(rename, 1, #rename - 1)
            end
            table.insert(items, rename)
        end
    end
    return table.concat(items, " ")
end
local const = {
    IDC = {
        value = remove_MAKEINTRESOURCE
    },
    WS = {
        value = rename_values,
        type = "uint"
    },
    WM = {
        value = rename_values,
        type = "uint"
    },
    DM = {
        value = rename_values_dm,
        type = "uint"
    }
}
local overload = {
    LoadCursorW = [[
        public static IntPtr LoadCursorW(
            IntPtr hInstance,
            int lpCursorName
        )
        {
            Span<int> src = stackalloc int[1];
            src[0] = lpCursorName;
            var cast = MemoryMarshal.Cast<int, ushort>(src);
            return LoadCursorW(hInstance, ref cast[0]);
        }
    ]]
}
local option = {
    filter = filter,
    omitEnumPrefix = true,
    macro_map = {
        D3D_COMPILE_STANDARD_FILE_INCLUDE = "public static IntPtr D3D_COMPILE_STANDARD_FILE_INCLUDE = new IntPtr(1);",
        DXGI_RESOURCE_PRIORITY_HIGH = "public const int DXGI_RESOURCE_PRIORITY_HIGH = unchecked ((int) 0xa0000000 );",
        DXGI_RESOURCE_PRIORITY_MAXIMUM = "public const int DXGI_RESOURCE_PRIORITY_MAXIMUM = unchecked ((int) 0xc8000000 );",
        DXGI_MAP_READ = "public const int DXGI_MAP_READ = ( 1 );",
        DXGI_MAP_WRITE = "public const int DXGI_MAP_WRITE = ( 2 );",
        DXGI_MAP_DISCARD = "public const int DXGI_MAP_DISCARD = ( 4 );",
        DXGI_ENUM_MODES_INTERLACED = "public const int DXGI_ENUM_MODES_INTERLACED = ( 1 );",
        DXGI_ENUM_MODES_SCALING = "public const int DXGI_ENUM_MODES_SCALING = ( 2 );",
        SETWALLPAPER_DEFAULT = "public static readonly IntPtr SETWALLPAPER_DEFAULT = new IntPtr(- 1);",
        TIMERR_NOCANDO = "public const int TIMERR_NOCANDO = ( /*TIMERR_BASE*/96 + 1 );",
        TIMERR_STRUCT = "public const int TIMERR_STRUCT = ( /*TIMERR_BASE*/96 + 33 );",
        LB_CTLCODE = "public const int LB_CTLCODE = 0;",
        WHEEL_PAGESCROLL = "public const int WHEEL_PAGESCROLL = unchecked( /*UINT_MAX*/(int)0xfffffff );",
        --
        LBS_STANDARD = "public const long LBS_STANDARD = ( LBS_NOTIFY | LBS_SORT | (long)WS._VSCROLL | (long)WS._BORDER );"
    },
    dir = dir,
    const = const,
    overload = overload,
    dll_map = {
        winuser = "user32",
        timeapi = "winmm"
    }
}

CS.Generate(sourceMap, option)
