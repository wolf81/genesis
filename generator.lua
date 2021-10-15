require 'constants'

local MapData = require 'mapdata'
local TextureGen = require 'texturegen'
local Tile = require 'tile'
local TileGroup = require 'tilegroup'
local ImplicitFractal = require 'accidental/implicit_fractal'
local Noise = require 'accidental/noise'

local Generator = {}
Generator.__index = Generator

local function getLeftTile(self, x, y)
	local x = (x - 1) % self._width
	return self._tiles[y][x]
end

local function getRightTile(self, x, y)
	local x = (x + 1) % self._width
	return self._tiles[y][x]
end

local function getTopTile(self, x, y)
	local y = (y - 1) % self._height
	return self._tiles[y][x]
end

local function getBottomTile(self, x, y)
	local y = (y + 1) % self._height
	return self._tiles[y][x]
end

local function floodFillGroup(tile, tileGroup, stack)
	if tile:isFloodFilled() then
		return
	elseif tileGroup:getType() == 'land' and not tile:isCollidable() then
		return
	elseif TileGroup:getType() == 'water' and tile:isCollidable() then
		return
	end

	tileGroup:add(tile)
	tile:floodFill()

	local adjacentTiles = { 
		tile:getTopTile(), 
		tile:getBottomTile(),
		tile:getLeftTile(),
		tile:getRightTile(),
	}

	for _, adjacentTile in ipairs(adjacentTiles) do
		if not adjacentTile:isFloodFilled() and adjacentTile:isCollidable() == tile:isCollidable() then
		stack[#stack + 1] = adjacentTile		
		end
	end
end

local function floodFill(self)
	local stack = {}

	for y = 0, self._height - 1 do
		for x = 0, self._width - 1 do
			local tile = self._tiles[y][x]

			if not tile:isFloodFilled() then
				if tile:isCollidable() then
					local tileGroup = TileGroup('land')
					stack[#stack + 1] = tile

					while #stack > 0 do
						floodFillGroup(table.remove(stack), tileGroup, stack)
					end

					if tileGroup:getSize() > 0 then
						self._landTiles[#self._landTiles + 1] = tileGroup
					end
				else
					local tileGroup = TileGroup('water')
					stack[#stack + 1] = tile

					while #stack > 0 do
						floodFillGroup(table.remove(stack), tileGroup, stack)
					end

					if tileGroup:getSize() > 0 then
						self._waterTiles[#self._waterTiles + 1] = tileGroup
					end					
				end
			end
		end
	end
end

local function updateBitmasks(self)
	for y = 0, self._height - 1 do
		for x = 0, self._width - 1 do
			local tile = self._tiles[y][x]
			tile:updateBitmask()
		end
	end
end

local function initialize(self)
	local octaves = 6
	local frequency = 1.25
	local seed = math.random()

	self._heightMap = ImplicitFractal(
		FractalType.MULTI, 
		BasisType.SIMPLEX, 
		InterpolationType.QUINTIC, 
		octaves, 
		frequency, 
		seed
	)
	-- Noise.generate(self._n, 1.6)
	self._heatMap = self._heightMap -- Noise.generate(self._n, 0.5)
	self._moistureMap = self._heightMap -- Noise.generate(self._n, 2.0)
end

local function getData(self)
	self._heightData = MapData(self._width , self._height)
	self._heatData = MapData(self._width, self._height)
	self._moistureData = MapData(self._width, self._height)

	for y = 0, self._height - 1 do
		for x = 0, self._width - 1 do
			local heightValue = self._heightMap:get2D(x, y) -- [x][y]		
			self._heightData:setValue(x, y, heightValue)

			local heatValue = self._heatMap:get2D(x, y) -- [x][y]
			local h = self._height - 1
			local factor = 0.5 - math.abs(y - h / 2) / h
			self._heatData:setValue(x, y, factor + heatValue)			

			local moistureValue = self._moistureMap:get2D(x, y) -- [x][y]
			self._moistureData:setValue(x, y, moistureValue)
		end
	end

	--[[
	print(heightData)
	print(moistureData)
	print(heatData)
	]]
end

local function loadTiles(self)
	local normalize = function(value, min, max)
		return (value - min) / (max - min)
	end

	self._tiles = {}
	for y = 0, self._height - 1 do
		self._tiles[y] = {}
		for x = 0, self._width - 1 do
			local tile = Tile(x, y)

			do -- normalize tile heights to range 0 .. 1
				local heightValue = self._heightData:getValue(x, y)
				local heightMin = self._heightData:getMin()
				local heightMax = self._heightData:getMax()
				heightValue = normalize(heightValue, heightMin, heightMax)
				tile:setHeightValue(heightValue)
			end

			do -- set terrain type based on tile height value
				local heightValue = tile:getHeightValue()
				if heightValue < TerrainType.DEEP_WATER then
					tile:setTerrainType(TerrainType.DEEP_WATER)
					tile:setCollidable(false)
				elseif heightValue < TerrainType.SHALLOW_WATER then
					tile:setTerrainType(TerrainType.SHALLOW_WATER)
					tile:setCollidable(false)
				elseif heightValue < TerrainType.SAND then
					tile:setTerrainType(TerrainType.SAND)
				elseif heightValue < TerrainType.GRASS then
					tile:setTerrainType(TerrainType.GRASS)
				elseif heightValue < TerrainType.FOREST	then
					tile:setTerrainType(TerrainType.FOREST)
				elseif heightValue < TerrainType.ROCK then
					tile:setTerrainType(TerrainType.ROCK)
				else
					tile:setTerrainType(TerrainType.SNOW)
				end
			end

			do -- adjust heat based on terrain, e.g. mountains are colder
				local terrainType = tile:getTerrainType()
				local heatValue = self._heatData:getValue(x, y)
				local heightValue = tile:getHeightValue()
				if terrainType == TerrainType.FOREST then
					self._heatData:setValue(x, y, heatValue - 0.10 * heightValue)
				elseif terrainType == TerrainType.ROCK then
					self._heatData:setValue(x, y, heatValue - 0.25 * heightValue)
				elseif terrainType == TerrainType.SNOW then
					self._heatData:setValue(x, y, heatValue - 0.40 * heightValue)
				else
					self._heatData:setValue(x, y, heatValue + 0.01 * heightValue)
				end
			end

			do -- adjust moisture based on height
				local terrainType = tile:getTerrainType()
				local moistureValue = self._moistureData:getValue(x, y)
				local heightValue = tile:getHeightValue()
				
				if terrainType == TerrainType.DEEP_WATER then
					self._moistureData:setValue(x, y, moistureValue + 8 * heightValue)
				elseif terrainType == TerrainType.SHALLOW_WATER then
					self._moistureData:setValue(x, y, moistureValue + 3 * heightValue)
				elseif terrainType == TerrainType.SAND then
					self._moistureData:setValue(x, y, moistureValue + 0.2 * heightValue)
				end
			end

			do -- moisture
				local moistureValue = self._moistureData:getValue(x, y)

				tile:setMoistureValue(moistureValue)

				if moistureValue < MoistureType.DRYER then
					tile:setMoistureType(MoistureType.DRYEST)
				elseif moistureValue < MoistureType.DRY then
					tile:setMoistureType(MoistureType.DRYER)
				elseif moistureValue < MoistureType.WET then
					tile:setMoistureType(MoistureType.DRY)
				elseif moistureValue < MoistureType.WETTER then
					tile:setMoistureType(MoistureType.WET)
				elseif moistureValue < MoistureType.WETTEST then
					tile:setMoistureType(MoistureType.WETTER)
				else
					tile:setMoistureType(MoistureType.WETTEST)
				end
			end

			do -- set the tile heat value
				local heatValue = self._heatData:getValue(x, y)
				local heatMin = self._heatData:getMin()
				local heatMax = self._heatData:getMax()
				tile:setHeatValue(normalize(heatValue, heatMin, heatMax))
			end

			do -- set heat type
				local heatValue = tile:getHeatValue()
				if heatValue < HeatType.COLDEST then
					tile:setHeatType(HeatType.COLDEST)
				elseif heatValue < HeatType.COLDER then
					tile:setHeatType(HeatType.COLDER)
				elseif heatValue < HeatType.COLD then
					tile:setHeatType(HeatType.COLD)
				elseif heatValue < HeatType.WARM then
					tile:setHeatType(HeatType.WARM)
				elseif heatValue < HeatType.WARMER then
					tile:setHeatType(HeatType.WARMER)
				else
					tile:setHeatType(HeatType.WARMEST)
				end
			end

			do -- moisture
				local moistureValue = self._moistureData:getValue(x, y)
				tile:setMoistureValue(moistureValue)
			end

			self._tiles[y][x] = tile
		end
	end
end

local function updateNeighbours(self)
	for y = 0, self._height - 1 do
		for x = 0, self._width - 1 do
			local tile = self._tiles[y][x]
			tile:setTopTile(getTopTile(self, x, y))
			tile:setBottomTile(getBottomTile(self, x, y))
			tile:setLeftTile(getLeftTile(self, x, y))
			tile:setRightTile(getRightTile(self, x, y))
			tile:updateBitmask()
		end
	end
end

function Generator:new(n)	
	local width = n
	local height = n
	print(width, height)

	return setmetatable({
		_n = n,
		_width = width,
		_height = height,
		_tiles = {},
		_waterTiles = {},
		_landTiles = {},

		_heatData = MapData(0, 0),
		_heightData = MapData(0, 0),
		_moistureData = MapData(0, 0),

		_heatMap = function() return 0 end,
		_heightMap = function() return 0 end,
		_moistureMap = function() return 0 end,
	}, Generator)
end

function Generator:getWidth()
	return self._width
end

function Generator:getHeight()
	return self._height
end

function Generator:getTiles()
	return self._tiles
end

function Generator:getLandTiles()
	return self._landTiles
end

function Generator:getWaterTiles()
	return self._waterTiles
end

function Generator:generate()
	print('generate')

	initialize(self)
	getData(self)
	loadTiles(self)
	updateNeighbours(self)
	floodFill(self)
	updateBitmasks(self)
end

return setmetatable(Generator, {
	__call = Generator.new
})