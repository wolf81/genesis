local Map = require 'map'

local CombineMap = {}
CombineMap.__index = Map

local function multiply(maps)
	local w, h = maps[1]:getSize()
	local mapCount = #maps

	local values = {}

	for face = 1, 6 do
		values[face] = {}

		for x = 0, w - 1 do
			values[face][x] = {}

			for y = 0, h - 1 do
				local v = 0
				for i = 1, mapCount do
					v = v + maps[i]:getValue(face, x, y)
				end
				values[face][x][y] = v / mapCount
			end
		end
	end

	return values
end

function CombineMap:new(...)
	local values = multiply({ ... })
	local super = Map(values)

	return setmetatable(super, CombineMap)
end

return setmetatable(CombineMap, {
	__call = CombineMap.new
})