local Tile = require 'tile'

local Map = {}
Map.__index = Map

Map.normalize = function(values, vmin, vmax)
	for face = 1, 6 do
		for x = 0, #values[face] - 1 do
			for y = 0, #values[face] - 1 do
				local v = values[face][x][y]
				values[face][x][y] = (v - vmin) / (vmax - vmin)
			end
		end		
	end

	return values
end

local function loadTiles(values, min, max)
	local tiles = {}

	local size = #values[1]
	
	for face = 1, 6 do
		tiles[face] = {}

		for x = 0, size - 1 do
			tiles[face][x] = {}

			for y = 0, size - 1 do
				local value = values[face][x][y]
				value = (value - min) / (max - min)
				tiles[face][x][y] = Tile(face, x, y, value)
			end
		end
	end

	return tiles
end

function Map:new(values, min, max)
	local tiles = loadTiles(values, min, max)
	-- TODO: add assertions, maybe for 3D array (?)
	return setmetatable({
		_size = #values[1],
		_tiles = loadTiles(values, min, max),
	}, Map)
end

function Map:getSize()
	return self._size, self._size
end

function Map:getTile(face, x, y)
	return self._tiles[face][x][y]
end

return setmetatable(Map, {
	__call = Map.new
})