local Tile = require 'tile'

local Map = {}
Map.__index = Map

function Map:new(values, size, min, max)
	-- TODO: add assertions, maybe for 3D array (?)
	return setmetatable({
		_size = size,
		_values = values,
		_min = min,
		_max = max,
	}, Map)
end

function Map:getValue(face, x, y)
	return self._values[face][x][y], self._min, self._max
end

return setmetatable(Map, {
	__call = Map.new
})