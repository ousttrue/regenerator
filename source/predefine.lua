function printf(fmt, ...)
    print(string.format(fmt, ...))
end

--
-- -X => opt[X] = true
-- -X 1 => opt[X] = 1
-- -XY => error. use --XY
-- --YY => opt[YY] = true
-- --YY "hello" => opt[YY] = "hello"
--
function getopt(arg)
    local opt = {}
    function push_value(key, value)
        local lastvalue = opt[key]
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
                    opt[key] = value
                else
                    -- push
                    opt[key] = {lastvalue, value}
                end
            end
        else
            opt[key] = value
        end
    end

    local lastkey = nil
    for k, v in ipairs(arg) do
        if string.sub(v, 1, 2) == "--" then
            lastkey = string.sub(v, 3)
            push_value(lastkey, true)
        elseif string.sub(v, 1, 1) == "-" then
            key = string.sub(v, 2)
            if string.len(key) > 1 then
                error(string.format('"%s" option name must 1 length. use "-%s"', v, v))
            end
            lastkey = key
            push_value(lastkey, true)
        else
            if lastkey then
                push_value(lastkey, v)
            end
            lastkey = nil
        end
    end
    return opt
end

function print_table(t, indent)
    indent = indent or ""
    for k, v in pairs(t) do
        printf("%s%s => %s", indent, k, v)
        if type(v) == "table" then
            print_table(v, indent .. "  ")
        end
    end
end
