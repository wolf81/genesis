local NoiseMap = require 'noisemap'
local GradientMap = require 'gradientmap'
local CombineMap = require 'combinemap'
local Tile = require 'tile'
local TileGroup = require 'tilegroup'
local River = require 'river'
local RiverGroup = require 'rivergroup'
local CubeMapHelper = require 'cubemaphelper'

require 'constants'

local mmin, mfloor, mrandom, mhuge = math.min, math.floor, math.random, math.huge

local Genesis = {}
Genesis.__index = Genesis

local biomeMap = {
	{ 	BiomeType.ICE, 					BiomeType.TUNDRA, 				BiomeType.GRASSLAND, 	
		BiomeType.DESERT, 				BiomeType.DESERT, 				BiomeType.DESERT },
	{ 	BiomeType.ICE, 					BiomeType.TUNDRA, 				BiomeType.GRASSLAND, 	
		BiomeType.DESERT, 				BiomeType.DESERT, 				BiomeType.DESERT },
	{ 	BiomeType.ICE, 					BiomeType.TUNDRA, 				BiomeType.WOODLAND, 		
		BiomeType.WOODLAND, 			BiomeType.SAVANNA, 				BiomeType.SAVANNA },
	{ 	BiomeType.ICE, 					BiomeType.TUNDRA, 				BiomeType.BOREAL_FOREST, 
		BiomeType.WOODLAND, 			BiomeType.SAVANNA, 				BiomeType.SAVANNA, },
	{ 	BiomeType.ICE, 					BiomeType.TUNDRA, 				BiomeType.BOREAL_FOREST, 
		BiomeType.SEASONAL_FOREST, 		BiomeType.TROPICAL_RAINFOREST, 	BiomeType.TROPICAL_RAINFOREST },
	{ 	BiomeType.ICE, 					BiomeType.TUNDRA, 				BiomeType.BOREAL_FOREST, 
		BiomeType.TEMPERATE_RAINFOREST, BiomeType.TROPICAL_RAINFOREST, 	BiomeType.TROPICAL_RAINFOREST },	
}

local function getBiome(tile)
	return biomeMap[tile:getMoistureType().id][6 - tile:getHeatType().id + 1]
end

local function generateBiomeMap(self)
	for face, x, y in CubeMapHelper.each(self._size) do
		local tile = self._tiles[face][x][y]

		if tile:isCollidable() then
			tile:setBiomeType(getBiome(tile))
		end
	end
end 

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

local function addMoisture(self, tile, radius)
	local _, x, y = tile:getPosition()
	-- TODO: to implement
end

local function adjustMoistureMap(self)
	for face, x, y in CubeMapHelper.each(self._size) do
		local tile = self._tiles[face][x][y]
		if tile:getHeightType() == HeightType.RIVER then
			addMoisture(self, tile, 60)
		end
	end
end

local function getTop(self, face, x, y)
	local face, x, y = CubeMapHelper.getCoordDy(face, self._size, x, y, -1)
	return self:getTile(face, x, y)
end

local function getLeft(self, face, x, y)
	local face, x, y = CubeMapHelper.getCoordDx(face, self._size, x, y, -1)
	return self:getTile(face, x, y)
end

local function getRight(self, face, x, y)
	local face, x, y = CubeMapHelper.getCoordDx(face, self._size, x, y, 1)
	return self:getTile(face, x, y)
end

local function getBottom(self, face, x, y)
	local face, x, y = CubeMapHelper.getCoordDy(face, self._size, x, y, 1)
	return self:getTile(face, x, y)
end

local function updateNeighbours(self)
	for face, x, y in CubeMapHelper.each(self._size) do
		local tile = self._tiles[face][x][y]
		tile:setTop(getTop(self, face, x, y))
		tile:setLeft(getLeft(self, face, x, y))
		tile:setRight(getRight(self, face, x, y))
		tile:setBottom(getBottom(self, face, x, y))
	end
end

local function updateTileHeightFlags(self)
	for face, x, y in CubeMapHelper.each(self._size) do
		local tile = self._tiles[face][x][y]
		tile:updateHeightFlags()
	end
end 

local function updateTileBiomeFlags(self)
	for face, x, y in CubeMapHelper.each(self._size) do
		local tile = self._tiles[face][x][y]
		tile:updateBiomeFlags()
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
				tile:setHeightValue(heightValue)

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

	for face, x, y in CubeMapHelper.each(self._size) do
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

local function findPathToWater(tile, direction, river)
	if tile:containsRiver(river) then return end

	if #tile:getRivers() > 0 then 
		river:incrementIntersections()
	end

	river:addTile(tile)

	local top = tile:getTop()
	local left = tile:getLeft()
	local right = tile:getRight()
	local bottom = tile:getBottom()

	local leftValue, rightValue, topValue, bottomValue = mhuge, mhuge, mhuge, mhuge

	if top:getRiverNeighbourCount(river) < 2 and not river:containsTile(top) then
		topValue = top:getHeightValue()
	end

	if left:getRiverNeighbourCount(river) < 2 and not river:containsTile(left) then
		leftValue = left:getHeightValue()
	end

	if right:getRiverNeighbourCount(river) < 2 and not river:containsTile(right) then
		rightValue = right:getHeightValue()
	end

	if bottom:getRiverNeighbourCount(river) < 2 and not river:containsTile(bottom) then
		bottomValue = bottom:getHeightValue()
	end

	if #top:getRivers() == 0 and not top:isCollidable() then
		topValue = 0
	end

	if #left:getRivers() == 0 and not left:isCollidable() then
		leftValue = 0
	end

	if #right:getRivers() == 0 and not right:isCollidable() then
		rightValue = 0
	end

	if #bottom:getRivers() == 0 and not bottom:isCollidable() then
		bottomValue = 0
	end

	-- TODO: override flow dir...

	-- find minimum
	local min = mmin(mmin(mmin(topValue, bottomValue), leftValue), rightValue)

	if min == mhuge then return end

	if min == topValue then
		if top:isCollidable() then
			if river:getCurrentDirection() ~= Direction.TOP then
				river:incrementTurns()
				river:setCurrentDirection(Direction.TOP)
			end
			findPathToWater(top, direction, river)
		end
	elseif min == leftValue then 
		if left:isCollidable() then
			if river:getCurrentDirection() ~= Direction.LEFT then
				river:incrementTurns()
				river:setCurrentDirection(Direction.LEFT)
			end
			findPathToWater(left, direction, river)
		end
	elseif min == rightValue then
		if right:isCollidable() then
			if river:getCurrentDirection() ~= Direction.RIGHT then
				river:incrementTurns()
				river:setCurrentDirection(Direction.RIGHT)
			end
			findPathToWater(right, direction, river)
		end
	elseif min == bottomValue then
		if bottom:isCollidable() then
			if river:getCurrentDirection() ~= Direction.BOTTOM then
				river:incrementTurns()
				river:setCurrentDirection(Direction.BOTTOM)
			end
			findPathToWater(bottom, direction, river)
		end
	end
end

local function buildRiverGroups(self)
	local riverGroups = {}

	local size = self._size

	for face = 1, 6 do
		for x = 0, size - 1 do
			for y = 0, size - 1 do
				local tile = self._tiles[face][x][y]
				if #tile:getRivers() > 1 then
					-- intersection
					local riverGroup = nil

					-- does a rivergroup already exists for this group
					for _, tileRiver in ipairs(tile:getRivers()) do
						for _, rg in ipairs(riverGroups) do
							for _, river in ipairs(rg:getRivers()) do
								if river:getId() == tileRiver:getId() then
									riverGroup = rg
								end
								if riverGroup ~= nil then break end
							end
							if riverGroup ~= nil then break end
						end
						if riverGroup ~= nil then break end
					end

					if riverGroup ~= nil then
						for _, river in ipairs(tile:getRivers()) do
							if not riverGroup:containsRiver(river) then
								riverGroup:addRiver(river)
							end
						end
					else
						riverGroup = RiverGroup()
						for _, river in ipairs(tile:getRivers()) do
							riverGroup:addRiver(river)
						end
						table.insert(riverGroups, riverGroup)
					end
				end
			end
		end
	end

	self._riverGroups = riverGroups

	print("rivergroups:", #self._riverGroups)
end 

local function digRiver(self, river)
	local counter = 0

	local size = mfloor(mrandom() * 4 + 1)
	river:setLength(#river:getTiles())

	local two = river:getLength() / 2
	local three = two / 2
	local four = three / 2
	local five = four / 2

	local twomin = two / 3
	local threemin = three / 3
	local fourmin = four / 3
	local fivemin = five / 3

	local count1 = mfloor(mrandom() * (five - fivemin) + fivemin) 
	if size < 4 then count1 = 0 end

	local count2 = count1 + mfloor(mrandom() * (four - fourmin) + fourmin) 
	if size < 3 then count1, count2 = 0, 0 end

	local count3 = count2 + mfloor(mrandom() * (three - threemin) + threemin) 
	if size < 2 then count1, count2, count3 = 0, 0, 0 end

	local count4 = count3 + mfloor(mrandom() * (two - twomin) + twomin) 

	if count4 > river:getLength() then
		local extra = count4 - river:getLength()
		while extra > 0 do
			if count1 > 0 then 
				count1 = count1 - 1
				count2 = count2 - 1
				count3 = count3 - 1
				count4 = count4 - 1
				extra = extra - 1
			elseif count2 > 0 then
				count2 = count2 - 1
				count3 = count3 - 1
				count4 = count4 - 1
				extra = extra - 1
			elseif count3 > 0 then
				count3 = count3 - 1
				count4 = count4 - 1
				extra = extra - 1
			elseif count4 > 0 then
				count4 = count4 - 1
				extra = extra - 1				
			end
		end
	end

	local riverTiles = river:getTiles()
	for i = #river:getTiles(), 1, -1 do
		local tile = riverTiles[i]

		if counter < count1 then
			tile:digRiver(river, 4)
		elseif counter < count2 then
			tile:digRiver(river, 3)
		elseif counter < count3 then
			tile:digRiver(river, 2)
		elseif counter < count4 then
			tile:digRiver(river, 1)
		else
			tile:digRiver(river, 0)
		end

		counter = counter + 1
	end
end

local function digRiverBranch(self, river, parent)
	print('dig river branch')

	local intersectionId = 0
	local intersectionSize = 0

	for i, tile in ipairs(river:getTiles()) do
		for _, parentTile in ipairs(parent:getTiles()) do
			if tile == parentTile then
				intersectionId = i
				intersectionSize = parentTile:getRiverSize()
			end
		end
	end

	local counter = 0
	local intersectionCount = #river:getTiles() - intersectionId
	local size = mfloor(mrandom() * (5 - intersectionSize)) + intersectionSize
	river:setLength(#river:getTiles())

	local two = river:getLength() / 2
	local three = two / 2
	local four = three / 2
	local five = four / 2

	local twomin = two / 3
	local threemin = three / 3
	local fourmin = four / 3
	local fivemin = five / 3

	local count1 = mfloor(mrandom() * (five - fivemin) + fivemin) 
	if size < 4 then count1 = 0 end

	local count2 = count1 + mfloor(mrandom() * (four - fourmin) + fourmin) 
	if size < 3 then count1, count2 = 0, 0 end

	local count3 = count2 + mfloor(mrandom() * (three - threemin) + threemin) 
	if size < 2 then count1, count2, count3 = 0, 0, 0 end

	local count4 = count3 + mfloor(mrandom() * (two - twomin) + twomin) 

	if count4 > river:getLength() then
		local extra = count4 - river:getLength()
		while extra > 0 do
			if count1 > 0 then 
				count1 = count1 - 1
				count2 = count2 - 1
				count3 = count3 - 1
				count4 = count4 - 1
				extra = extra - 1
			elseif count2 > 0 then
				count2 = count2 - 1
				count3 = count3 - 1
				count4 = count4 - 1
				extra = extra - 1
			elseif count3 > 0 then
				count3 = count3 - 1
				count4 = count4 - 1
				extra = extra - 1
			elseif count4 > 0 then
				count4 = count4 - 1
				extra = extra - 1				
			end
		end
	end

	if intersectionSize == 1 then
		count4 = intersectionCount
		count3 = 0
		count2 = 0
		count1 = 0
	elseif intersectionSize == 2 then
		count3 = intersectionCount
		count2 = 0
		count1 = 0
	elseif intersectionSize == 3 then
		count2 = intersectionCount
		count1 = 0
	elseif intersectionSize == 4 then
		count1 = intersectionCount
	else
		count4 = 0
		count3 = 0
		count2 = 0
		count1 = 0
	end

	local riverTiles = river:getTiles()
	for i = #river:getTiles(), 1, -1 do
		local tile = riverTiles[i]

		if counter < count1 then
			tile:digRiver(river, 4)
		elseif counter < count2 then
			tile:digRiver(river, 3)
		elseif counter < count3 then
			tile:digRiver(river, 2)
		elseif counter < count4 then
			tile:digRiver(river, 1)
		else
			tile:digRiver(river, 0)
		end

		counter = counter + 1
	end
end 

local function digRiverGroups(self)
	for _, riverGroup in ipairs(self._riverGroups) do
		local longest = nil

		for _, river in ipairs(riverGroup:getRivers()) do
			if longest == nil then
				longest = river
			elseif #longest:getTiles() < #river:getTiles() then
				longest = river
			end
		end

		if longest ~= nil then
			digRiver(self, longest)

			for _, river in ipairs(riverGroup:getRivers()) do
				if river ~= longest then
					print('branch')
					digRiverBranch(self, river, longest)
				end
			end
		end
	end 
end 

local function generateRivers(self)
	local attempts = 0

	-- rivercount 40
	-- min river height: 0.6
	-- max attemts 1000,
	-- min turns 18,
	-- min length 20,
	-- max intersections 2

	local riverCount = 40
	local rivers = {}

	local size = self._size

	while riverCount > 0 and attempts < 1000 do
		local face = mfloor(mrandom() * 6) + 1
		local x = mfloor(mrandom() * size)
		local y = mfloor(mrandom() * size)
		local tile = self._tiles[face][x][y]

		if tile:isCollidable() and #tile:getRivers() == 0 then
			if tile:getHeightValue() > 0.6 then
				local river = River(riverCount)

				-- figure out water direction
				local direction = tile:getLowestNeighbourDirection()
				river:setCurrentDirection(direction)

				-- recursively find path to water
				findPathToWater(tile, direction, river)

				-- validate river
				if river:getTurns() < 18 or #river:getTiles() < 20 or river:getIntersections() > 2 then
					for _, riverTile in ipairs(river:getTiles()) do
						riverTile:removeRiver(river)
					end
				elseif #river:getTiles() >= 20 then
					table.insert(rivers, river)
					tile:addRiver(river)
					riverCount = riverCount - 1
				end
			end

			attempts = attempts + 1
		end
	end

	print('add rivers:', #rivers)

	self._rivers = rivers
end

function Genesis:new()
	return setmetatable({
		_size = 0,
		_tiles = {},
		_waterGroups = {},
		_landGroups = {},
		_riverGroups = {},
		_rivers = {},
	}, Genesis)
end

function Genesis:generate(size, seed)
	self._size = size

	-- get values for height map, heat map, moisture map
	local seed = seed or math.random()
	print('generate height, heat, moisture values based on seed:', seed)
	getData(self, seed)

	-- generate the tile map
	print('create tiles')
	loadTiles(self)

	print('set tile neighbours')
	updateNeighbours(self)

	print('generate rivers')
	generateRivers(self)

	print('build river groups')
	buildRiverGroups(self)

	print('dig river groups')
	digRiverGroups(self)

	print('update tile neighbour height flags')
	updateTileHeightFlags(self)

	print('set land & water groups')
	floodFill(self)

	print('generate biomes')
	generateBiomeMap(self)

	print('update tile neighbour biome flags')
	updateTileBiomeFlags(self)
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