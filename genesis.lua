local Tile = require 'tile'
local NoiseMap = require 'noisemap'
local GradientMap = require 'gradientmap'
local CombineMap = require 'combinemap'
local TileGroup = require 'tilegroup'

require 'constants'

local mmin = math.min

local Genesis = {}
Genesis.__index = Genesis

local function getHeightType(heightValue)
	if heightValue >= 0.9 then return HeightType.SNOW
	elseif heightValue >= 0.8 then return HeightType.MOUNTAIN
	elseif heightValue >= 0.7 then return HeightType.FOREST
	elseif heightValue >= 0.62 then return HeightType.PLAIN
	elseif heightValue >= 0.6 then return HeightType.COAST
	elseif heightValue >= 0.3 then return HeightType.SHALLOW_WATER
	else return HeightType.DEEP_WATER
	end	
end 

local function getHeatType(heatValue)
	if heatValue >= 0.75 then return HeatType.WARMEST
	elseif heatValue >= 0.60 then return HeatType.WARMER
	elseif heatValue >= 0.45 then return HeatType.WARM
	elseif heatValue >= 0.30 then return HeatType.COLD
	elseif heatValue >= 0.15 then return HeatType.COLDER
	else return HeatType.COLDEST
	end
end

local function getMoistureType(moistureValue)
	if moistureValue >= 0.9 then return MoistureType.WETTEST
	elseif moistureValue >= 0.8 then return MoistureType.WETTER
	elseif moistureValue >= 0.6 then return MoistureType.WET
	elseif moistureValue >= 0.4 then return MoistureType.DRY
	elseif moistureValue >= 0.27 then return MoistureType.DRYER
	else return MoistureType.DRYEST
	end
end

local neighbourFaceMap = {
	--[[
	this map helps find neighbour faces for a given face number
	the key is the current face number and the values are adjacent face 
	numbers in order TOP, LEFT, BOTTOM, RIGHT
	--]]
	[1] = { 5, 4, 2, 6 },
	[2] = { 5, 1, 3, 6 },
	[3] = { 5, 2, 4, 6 },
	[4] = { 5, 3, 1, 6 },
	[5] = { 3, 4, 2, 1 },
	[6] = { 1, 4, 2, 3 },
}

local function getTop(self, face, x, y)
	local size = self._size

	if y > 0 then
		return self:getTile(face, x, y - 1)
	else 
		local nextFace = x == 0 and neighbourFaceMap[face][2] or neighbourFaceMap[face][1]
		local x = x == 0 and size - 1 or x
		local y = x == 0 and 0 or size - 1
		return self:getTile(nextFace, x, y)
	end
end

local function getLeft(self, face, x, y)
	local size = self._size

	if x > 0 then
		return self:getTile(face, x - 1, y)
	else
		local nextFace = y == size - 1 and neighbourFaceMap[face][4] or neighbourFaceMap[face][2]
		local x = y == size - 1 and 0 or size - 1
		local y = y == size - 1 and 0 or y
		return self:getTile(nextFace, x, y)
	end
end

local function getRight(self, face, x, y)
	local size = self._size

	if x < size - 1 then
		return self:getTile(face, x + 1, y)
	else
		local nextFace = y == 0 and neighbourFaceMap[face][1] or neighbourFaceMap[face][3]
		local x = y == 0 and size - 1 or 0
		local y = y == 0 and size - 1 or y
		return self:getTile(nextFace, x, y)
	end
end

local function getBottom(self, face, x, y)
	local size = self._size

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
				tile:setTop(getTop(self, face, x, y))
				tile:setLeft(getLeft(self, face, x, y))
				tile:setRight(getRight(self, face, x, y))
				tile:setBottom(getBottom(self, face, x, y))
			end
		end
	end
end

local function updateTileFlags(self)
	local size = self._size

	for face = 1, 6 do
		for x = 0, size - 1 do
			for y = 0, size - 1 do
				local tile = self._tiles[face][x][y]
				tile:updateFlags()
			end
		end
	end	
end 

local function getData(self, seed)
	if seed < 1.0 then seed = seed * 256 end

	self._heightMap = NoiseMap(self._size, seed % 128, 6, 0.5)
	
	self._heatMap = CombineMap(self._size, 
		NoiseMap(self._size, seed % 64), 
		GradientMap(self._size, 4, 3.0)
	)

	self._moistureMap = NoiseMap(self._size, seed % 32, 4, 2.0)
end

local function loadTiles(self)
	local tiles = {}

	for face = 1, 6 do 
		tiles[face] = {}

		for x = 0, self._size - 1 do
			tiles[face][x] = {}

			for y = 0, self._size - 1 do
				-- set height value & type
				local heightValue, min, max = self._heightMap:getValue(face, x, y)
				heightValue = (heightValue - min) / (max - min)

				local tile = Tile(face, x, y)

				local heightType = getHeightType(heightValue)
				tile:setHeightType(heightType)

				tile:setCollidable(
					heightType ~= HeightType.DEEP_WATER and 
					heightType ~= HeightType.SHALLOW_WATER
				)

				-- set heat value & type
				local heatValue = self._heatMap:getValue(face, x, y)

				if heightType == HeightType.FOREST then
					heatValue = heatValue - heightValue * 0.1
				elseif heightType == HeightType.MOUNTAIN then
					heatValue = heatValue - heightValue * 0.25
				elseif heightType == HeightType.SNOW then
					heatValue = heatValue - heightValue * 0.4
				else
					heatValue = heatValue + heightValue * 0.01
				end

				tile:setHeatValue(heatValue)
				tile:setHeatType(getHeatType(heatValue))

				-- set moisture value & type
				local moistureValue, min, max = self._moistureMap:getValue(face, x, y)
				moistureValue = (moistureValue - min) / (max - min)

				if heightType == HeightType.DEEP_WATER then 
					moistureValue = mmin(moistureValue + 8 * heightValue, 1.0)
				elseif heightType == HeightType.SHALLOW_WATER then 
					moistureValue = mmin(moistureValue + 3 * heightValue, 1.0)
				elseif heightType == HeightType.COAST then 
					moistureValue = mmin(moistureValue + 1 * heightValue, 1.0)
				end

				tile:setMoistureValue(moistureValue)
				tile:setMoistureType(getMoistureType(moistureValue))

				tiles[face][x][y] = tile
			end
		end
	end

	self._tiles = tiles
end

local function floodFillTile(tile, tileGroup, stack)
	if tile:isFloodFilled() then return end

	if tileGroup:getType() == TileGroupType.LAND and not tile:isCollidable() then
		return
	end

	if tileGroup:getType() == TileGroupType.WATER and tile:isCollidable() then
		return
	end

	tileGroup:addTile(tile)
	tile:floodFill()

	local tileTop = tile:getTop()
	if not tileTop:isFloodFilled() and tileTop:isCollidable() == tile:isCollidable() then
		table.insert(stack, tileTop)
	end

	local tileLeft = tile:getLeft()
	if not tileLeft:isFloodFilled() and tileLeft:isCollidable() == tile:isCollidable() then
		table.insert(stack, tileLeft)
	end

	local tileRight = tile:getRight()
	if not tileRight:isFloodFilled() and tileRight:isCollidable() == tile:isCollidable() then
		table.insert(stack, tileRight)
	end

	local tileBottom = tile:getBottom()
	if not tileBottom:isFloodFilled() and tileBottom:isCollidable() == tile:isCollidable() then
		table.insert(stack, tileBottom)
	end
end

local function floodFill(self)
	local stack = {}

	self._landGroups = {}
	self._waterGroups = {}

	local size = self._size
	for face = 1, 6 do
		for x = 0, size - 1 do
			for y = 0, size - 1 do
				local tile = self._tiles[face][x][y]

				if not tile:isFloodFilled() then
					if tile:isCollidable() then
						local tileGroup = TileGroup(TileGroupType.LAND)
						stack[#stack + 1] = tile

						while #stack > 0 do
							floodFillTile(table.remove(stack), tileGroup, stack)
						end

						if tileGroup:getTileCount() > 0 then
							table.insert(self._landGroups, tileGroup)
						end
					else						
						local tileGroup = TileGroup(TileGroupType.WATER)
						stack[#stack + 1] = tile

						while #stack > 0 do
							floodFillTile(table.remove(stack), tileGroup, stack)
						end

						if tileGroup:getTileCount() > 0 then
							table.insert(self._waterGroups, tileGroup)
						end
					end
				end
			end
		end
	end
end

function Genesis:new()
	return setmetatable({
		_size = 0,
		_tiles = {},
		_waterGroups = {},
		_landGroups = {},
	}, Genesis)
end

function Genesis:generate(size, seed)
	self._size = size

	-- get values for height map, heat map, moisture map
	getData(self, seed or math.random())

	-- generate the tile map
	loadTiles(self)
	updateNeighbours(self)
	updateTileFlags(self)

	floodFill(self)
end

function Genesis:getTile(face, x, y)
	return self._tiles[face][x][y]
end

function Genesis:getWaterGroups()
	return self._waterGroups
end

function Genesis:getLandGroups()
	return self._landGroups
end

function Genesis:getSize()
	return self._size, self._size
end

return setmetatable(Genesis, {
	__call = Genesis.new
})