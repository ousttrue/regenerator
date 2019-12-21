local args = {...}
for i, arg in ipairs(args) do
    print(i, arg)
end

print('hello lua')
print(Vector3)
local vec = Vector3.new(1, 2, 3)
print(vec)
local zero = Vector3.zero()
print(zero)
for k, v in pairs(getmetatable(zero)) do
    print(k, v)
end

-- local v = Vector3.new(1)
print(vec + vec)
print(vec.x)
