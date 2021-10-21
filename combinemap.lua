local mmin, mmax = math.min, math.max
local Map = require 'map'

local CombineMap = {}
CombineMap.__index = Map

local function multiply(size, maps)
	local mapCount = #maps

	local values = {}

	local min, max = math.huge, -math.huge

	for face = 1, 6 do
		values[face] = {}

		for x = 0, size - 1 do
			values[face][x] = {}

			for y = 0, size - 1 do
				local v = 0
				for i = 1, mapCount do
					v = v + maps[i]:getValue(face, x, y)
				end
				v = v / mapCount				
				values[face][x][y] = v

				min = mmin(min, v)
				max = mmax(max, v)
			end
		end
	end

	return values, min, max
end

function CombineMap:new(size, ...)
	local maps = {...}
	local values, min, max = multiply(size, maps)
	local super = Map(values, size, min, max)

	return setmetatable(super, CombineMap)
end

return setmetatable(CombineMap, {
	__call = CombineMap.new
})