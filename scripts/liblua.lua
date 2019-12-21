local args = {...}

function getopt(arg)
    local tab = {}
    function push_value(key, value)
        local lastvalue = tab[key]
        if lastvalue then
            if type(lastvalue) == "table" then
                if lastvalue[#lastvalue] == true then
                    -- replace
                    lastvalue[#lastvalue] = value
                else
                    -- push
                    table.insert(lastvalue, value)
                end
            else
                if lastvalue == true then
                    -- replace
                    tab[key] = value
                else
                    -- push
                    tab[key] = {lastvalue, value}
                end
            end
        else
            tab[key] = value
        end
    end

    local lastkey = nil
    for k, v in ipairs(arg) do
        if string.sub(v, 1, 2) == "--" then
            lastkey = string.sub(v, 3)
            push_value(lastkey, true)
        elseif string.sub(v, 1, 1) == "-" then
            local y = 2
            local l = string.len(v)
            while (y <= l) do
                lastkey = string.sub(v, y, y)
                push_value(lastkey, true)
                y = y + 1
            end
        else
            if lastkey then
                push_value(lastkey, v)
            end
            lastkey = nil
        end
    end
    return tab
end

local opts = getopt(args)
function show_table(t, indent)
    for k, v in pairs(t) do
        print(string.format("%s%s => %s", indent, k, v))
        if type(v) == "table" then
            show_table(v, indent .. "  ")
        end
    end
end
show_table(opts, "")

-- print("hello lua")
-- print(Vector3)
-- local vec = Vector3.new(1, 2, 3)
-- print(vec)
-- local zero = Vector3.zero()
-- print(zero)
-- for k, v in pairs(getmetatable(zero)) do
--     print(k, v)
-- end

-- -- local v = Vector3.new(1)
-- print(vec + vec)
-- print(vec.x)
