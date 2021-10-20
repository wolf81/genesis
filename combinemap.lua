local mmin, mmax = math.min, math.max

require 'utility'

local Map = require 'map'

local CombineMap = {}
CombineMap.__index = Map

local function multiply(maps)
	local w, h = maps[1]:getSize()
	local mapCount = #maps

	local values = {}

	local min, max = math.huge, -math.huge

	for face = 1, 6 do
		values[face] = {}

		for x = 0, w - 1 do
			values[face][x] = {}

			for y = 0, h - 1 do
				local v = 0
				for i = 1, mapCount do
					v = v + maps[i]:getTile(face, x, y):getValue()
				end
				v = v / mapCount				
				values[face][x][y] = v

				min = mmin(min, v)
				max = mmax(max, v)
			end
		end
	end

	-- for i = 1, 6 do
	-- 	printArray2(values[i])		
	-- end

	return values, min, max
end

function CombineMap:new(...)
	local maps = {...}
	local size = maps[1]:getSize()
	local values, min, max = multiply(maps)
	local super = Map(values, size, min, max)

	return setmetatable(super, CombineMap)
end

return setmetatable(CombineMap, {
	__call = CombineMap.new
})