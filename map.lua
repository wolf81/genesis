local Tile = require 'tile'

local Map = {}
Map.__index = Map

local neighbourMap = {
	-- face = { T, L, B, R }
	[1] = { 5, 4, 2, 6 },
	[2] = { 5, 1, 3, 6 },
	[3] = { 5, 2, 4, 6 },
	[4] = { 5, 3, 1, 6 },
	[5] = { 3, 4, 2, 1 },
	[6] = { 1, 4, 2, 3 },
}

local function getTop(self, tile)
	local size = self._size

	local face, x, y = tile:getPosition()
	if y > 0 then
		return self:getTile(face, x, y - 1)
	else 
		local nextFace = x == 0 and neighbourMap[face][2] or neighbourMap[face][1]
		local x = x == 0 and size - 1 or x
		local y = x == 0 and 0 or size - 1
		return self:getTile(nextFace, x, y)
	end
end

local function getLeft(self, tile)
	local size = self._size

	local face, x, y = tile:getPosition()
	if x > 0 then
		return self:getTile(face, x - 1, y)
	else
		local nextFace = y == size - 1 and neighbourMap[face][4] or neighbourMap[face][2]
		local x = y == size - 1 and 0 or size - 1
		local y = y == size - 1 and 0 or y
		return self:getTile(nextFace, x, y)
	end
end

local function getRight(self, tile)
	local size = self._size

	local face, x, y = tile:getPosition()
	if x < size - 1 then
		return self:getTile(face, x + 1, y)
	else
		local nextFace = y == 0 and neighbourMap[face][1] or neighbourMap[face][3]
		local x = y == 0 and size - 1 or 0
		local y = y == 0 and size - 1 or y
		return self:getTile(nextFace, x, y)
	end
end

local function getBottom(self, tile)
	local size = self._size

	local face, x, y = tile:getPosition()
	if y < size - 1 then
		return self:getTile(face, x, y + 1)
	else
		local nextFace = x == size - 1 and neighbourMap[face][3] or neighbourMap[face][4]
		local x = x == size - 1 and 0 or x
		local y = x == size - 1 and size - 1 or 0
		return self:getTile(nextFace, x, y)
	end
end

local function updateNeighbours(self)
	local size = self._size

	for face = 1, 6 do
		for x = 0, size - 1 do
			for y = 0, size - 1 do
				local tile = self._tiles[face][x][y]
				tile:setTop(getTop(self, tile))
				tile:setLeft(getLeft(self, tile))
				tile:setRight(getRight(self, tile))
				tile:setBottom(getBottom(self, tile))
			end
		end
	end
end

local function updateBitmasks(self)
	local size = self._size

	for face = 1, 6 do
		for x = 0, size - 1 do
			for y = 0, size - 1 do
				local tile = self._tiles[face][x][y]
				tile:updateBitmask()
			end
		end
	end	
end 

local function loadTiles(values, size, min, max)
	local tiles = {}
	
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

function Map:new(values, size, min, max)
	-- TODO: add assertions, maybe for 3D array (?)
	local instance = setmetatable({
		_size = size,
		_tiles = loadTiles(values, size, min, max),
	}, Map)

	updateNeighbours(instance)
	updateBitmasks(instance)

	return instance
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