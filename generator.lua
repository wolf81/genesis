local Tile = require 'tile'
local NoiseMap = require 'noisemap'
local GradientMap = require 'gradientmap'
local CombineMap = require 'combinemap'

local Generator = {}
Generator.__index = Generator

local neighbourFaceMap = {
	-- face = { T, L, B, R }
	[1] = { 5, 4, 2, 6 },
	[2] = { 5, 1, 3, 6 },
	[3] = { 5, 2, 4, 6 },
	[4] = { 5, 3, 1, 6 },
	[5] = { 3, 4, 2, 1 },
	[6] = { 1, 4, 2, 3 },
}

local function getTerrainType(heightValue)
	if heightValue >= 0.9 then return 1 -- snow
	elseif heightValue >= 0.8 then return 2 -- mountain
	elseif heightValue >= 0.7 then return 3 -- forest
	elseif heightValue >= 0.62 then return 4 -- grass
	elseif heightValue >= 0.6 then return 5 -- beach
	elseif heightValue >= 0.3 then return 6 -- shallow ocean
	else return 7 -- deep ocean
	end	
end 

local function getTop(self, tile)
	local size = self._size

	local face, x, y = tile:getPosition()
	if y > 0 then
		return self:getTile(face, x, y - 1)
	else 
		local nextFace = x == 0 and neighbourFaceMap[face][2] or neighbourFaceMap[face][1]
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
		local nextFace = y == size - 1 and neighbourFaceMap[face][4] or neighbourFaceMap[face][2]
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
		local nextFace = y == 0 and neighbourFaceMap[face][1] or neighbourFaceMap[face][3]
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
		local nextFace = x == size - 1 and neighbourFaceMap[face][3] or neighbourFaceMap[face][4]
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

local function getData(self)
	self._heightMap = NoiseMap(self._size, math.random() * 100)
	self._heatMap = CombineMap(self._size, 
		NoiseMap(self._size, math.random() * 100), 
		GradientMap(self._size)
	)
end

local function loadTiles(self, seed)
	local tiles = {}

	for face = 1, 6 do 
		tiles[face] = {}

		for x = 0, self._size - 1 do
			tiles[face][x] = {}

			for y = 0, self._size - 1 do
				local heightValue, min, max = self._heightMap:getValue(face, x, y)
				heightValue = (heightValue - min) / (max - min)

				local tile = Tile(face, x, y, heightValue)			
				tile:setTerrainType(getTerrainType(heightValue))

				local heatValue = self._heatMap:getValue(face, x, y)
				if tile:getTerrainType() == 3 then
					heatValue = heatValue - heightValue * 0.1
				elseif tile:getTerrainType() == 2 then
					heatValue = heatValue - heightValue * 0.25
				elseif tile:getTerrainType() == 1 then
					heatValue = heatValue - heightValue * 0.4
				else
					heatValue = heatValue + heightValue * 0.01
				end

				tile:setHeatValue(heatValue)

				tiles[face][x][y] = tile
			end
		end
	end

	self._tiles = tiles
end

function Generator:new()
	return setmetatable({
		_size = 0,
		_tiles = {}
	}, Generator)
end

function Generator:generate(size, seed)
	self._size = 2 ^ size + 1

	getData(self)

	loadTiles(self, seed)

	updateNeighbours(self)
	updateBitmasks(self)
end

function Generator:getTile(face, x, y)
	return self._tiles[face][x][y]
end

function Generator:getSize()
	return self._size, self._size
end

return setmetatable(Generator, {
	__call = Generator.new
})