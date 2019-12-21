print('hello lua')
print(Vector3)
-- local v = Vector3.new(4)
-- print(v)
local zero = Vector3.zero()
print(zero)
for k, v in pairs(getmetatable(zero)) do
    print(k, v)
end
