local PATH = (...):match('(.-)[^%.]+$') 
local NoiseMap = require(PATH .. 'noisemap')
local GradientMap = require(PATH .. 'gradientmap')
local CombineMap = require(PATH .. 'combinemap')
local BitmaskOffsets = require(PATH .. 'bitmaskoffsets')
local EqualityFlags = require(PATH .. 'equalityflags')
local BiomeType = require(PATH .. 'biometype')
local HeightType = require(PATH .. 'heighttype')
local CubeMapHelper = require(PATH .. 'cubemaphelper')

local bbor, bband, blshift, brshift = bit.bor, bit.band, bit.lshift, bit.rshift
local mmin, mmax, mfloor, mrandom = math.min, math.max, math.floor, math.random

local M = {}

local HEAT_THRESHOLDS 	  = { 0.15, 0.30, 0.45, 0.60, 0.75, 1.00 } -- cold to hot
local MOISTURE_THRESHOLDS = { 0.27, 0.40, 0.60, 0.80, 0.90, 1.00 } -- dry to wet
local HEIGHT_THRESHOLDS   = { 0.20, 0.48, 0.52, 0.70, 0.80, 0.90, 1.00 } -- low to high

local GroupType = {
	LAND 	= 1,
	WATER = 2,
}

local Direction = {
	Up 		= {  0, -1 },
	Down 	= {  0,  1 },
	Left 	= { -1,  0 },
	Right = {  1,  0 },
}

local Direction = {
	Up 		= {  0, -1 },
	Down 	= {  0,  1 },
	Left 	= { -1,  0 },
	Right = {  1,  0 },
}

local BiomeTypeInfo = {
--		COLDEST						COLDER							COLD 										HOT														HOTTER													HOTTEST	
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.GRASSLAND,     BiomeType.DESERT, 							BiomeType.DESERT, 			   			BiomeType.DESERT },								-- DRYEST
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.GRASSLAND,     BiomeType.DESERT, 							BiomeType.DESERT, 			   			BiomeType.DESERT },								-- DRYER
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.WOODLAND,      BiomeType.WOODLAND, 						BiomeType.SAVANNA, 			   			BiomeType.SAVANNA },							-- DRY
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.WOODLAND, 						BiomeType.SAVANNA, 			   			BiomeType.SAVANNA },							-- WET
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.SEASONAL_FOREST, 			BiomeType.TROPICAL_RAINFOREST, 	BiomeType.TROPICAL_RAINFOREST },	-- WETTER
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.TEMPERATE_RAINFOREST, BiomeType.TROPICAL_RAINFOREST, 	BiomeType.TROPICAL_RAINFOREST },	-- WETTEST
}

-- TODO: rename?
-- TROPRN_FOREST
-- TEMPRN_FOREST
-- SEASON_FOREST
-- BOREAL_FOREST

local function newTileMap(size, fn)
	local tileMap = {}
	for face = 1, 6 do
		tileMap[face] = {}
		for x = 1, size do
			tileMap[face][x] = {}
			for y = 1, size do
				tileMap[face][x][y] = fn(face, x, y)
			end
		end
	end
	return tileMap
end

local function forEachTile(tileMap, fn)
	local size = #tileMap[1]
	for face = 1, 6 do
		for x = 1, size do
			for y = 1, size do
				fn(tileMap[face][x][y], face, x, y)
			end
		end
	end
end

-- normalize a value to 0.0 .. 1.0 range
local function normalize(value, min, max)
	return (value - min) / (max - min)
end

local function getBiomeType(moistureType, heatType)
	return BiomeTypeInfo[moistureType][heatType] 
end

local function getBiomeType(moistureType, heatType)
	return BiomeTypeInfo[moistureType][heatType] 
end

local function getKey(face, x, y)
	return face * y + x -- bbor(blshift(face, 28), blshift(x, 14), y)
end

local function getCoord(key)
	local face = bit.rshift(key, 28)
	local x = bband(bit.rshift(key, 14), 0x3FFF)
	local y = bband(key, 0x3FFF)
	return face, x, y
end

local function getTypeForValue(value, thresholds)
	local idx = #thresholds
	for i = #thresholds, 1, -1 do
		if value >= thresholds[i] then
			break
		end
		idx = i
	end
	return idx
end

local function getTileValue(tileMap, size, face, x, y, direction)
	local dx, dy = unpack(direction)

	if dx ~= 0 then
		face, x, y = CubeMapHelper.getCoordDx(size, face, x, y, dx)
	end

	if dy ~= 0 then
		face, x, y = CubeMapHelper.getCoordDy(size, face, x, y, dy)
	end

	return tileMap[face][x][y], face, x, y
end

local function getAdjFlags(tileMap, size, face, x, y, direction)
	local adjTile, adjFace, adjX, adjY = getTileValue(tileMap, size, face, x, y, direction)
	local adjBiome = bband(brshift(adjTile, BitmaskOffsets.BIOME_TYPE), 0xF)
	local adjHeight = bband(brshift(adjTile, BitmaskOffsets.HEIGHT_TYPE), 0x7)
	return adjBiome, adjHeight
end

local function floodFill(heightMap, size, coord, group, getGroupType, fillInfo, stack)
	local face, x, y = unpack(coord)

	-- ignore processed coords
	local key = getKey(face, x, y)
	if fillInfo[key] then return end

	-- mark coord as processed
	fillInfo[key] = group.id

	-- ensure the group type at current coord matches the type of the group
	local height = heightMap[face][x][y]	
	if group.type ~= getGroupType(height) then return end

	-- add coord to current group coords
	group.coords[#group.coords + 1] = { face, x, y }

	-- add neighbors to the stack, if they are of similar group type
	local directions = { Direction.Left, Direction.Right, Direction.Up, Direction.Down }
	for _, direction in ipairs(directions) do
		local value, face, x, y = getTileValue(heightMap, size, face, x, y, direction)
		if getGroupType(value) == group.type then
			stack[#stack + 1] = { face, x, y }
		end
	end
end

local function generateGroups(heightMap, size, heightMin, heightMax)
	local fillInfo, groups, stack = {}, {}, {}

	-- shore starts at top of shallow water
	local shoreHeight = heightMin + HEIGHT_THRESHOLDS[2] * (heightMax - heightMin) 

	-- determine group type for current height value, based on minimum & maximum height values
	local getGroupType = function(height) 
		return height >= shoreHeight and GroupType.LAND or GroupType.WATER
	end

	-- generate land & water groups
	forEachTile(heightMap, function(height, face, x, y)
		-- skip already processed coords
		if fillInfo[getKey(face, x, y)] then return end 

		-- create a new group for the current group type and add intial coord
		local group = {
			id = #groups + 1,
			type = height < shoreHeight and GroupType.WATER or GroupType.LAND,
			coords = { { face, x, y } },
		}

		-- add the initial coord to the stack, that will have neighbors added
		stack[#stack + 1] = group.coords[1]

		-- process neighbors until border is reached for current group type
		while #stack > 0 do
			floodFill(heightMap, size, table.remove(stack, 1), group, getGroupType, fillInfo, stack)
		end

		-- only store groups with multiple coords
		if #group.coords > 0 then
			groups[#groups + 1] = group
		end
	end)

	print('groups:', #groups)
	print()

	for _, group in ipairs(groups) do
		print('group', group.id, #group.coords)
	end

	return groups
end

local function generateRivers(heightMap, size)
	--[[
	-- 1. first figure out highest points in the map
	-- 2. choose a random start point A from the highest points values
	-- 2. for a given point, figure out the boundary (coast) - we can cache this ("islands")
	--		easiest way to figure out boundary would be to implement the island / continent algorithm
	-- 3. choose a random end point B
	-- 4. repeat until river is completed (all connected):
	--		4.1 get midpoint between A and B
	--		4.2 find lowest position perpendicular to midpoint, this will be point C 
	--		4.3 return to 4, for midpoints between A and C, B and C
	--]] 
end

-- generate tile maps based on size and optionally seed & sea level
-- TODO: consider adding options table for thresholds, rivers, etc...
M.generate = function(size, seed)
	local tileMaps = {}

	-- TODO: assert a minimum size

	-- set seed if needed and ensure an integer value is used
	seed = seed or mrandom()
	if seed < 1.0 then
		seed = mfloor(seed * 255)
	end

	local heightMap, heightMin, heightMax = NoiseMap.generate(size, seed % 127, 6)
	local heatNoiseMap, _, _ = NoiseMap.generate(size, seed % 63, 4, 2.0)
	local heatGradientMap, _, _ = GradientMap.generate(size, 4, 3.0)
	local heatMap, heatMin, heatMax = CombineMap.generate(size, heatNoiseMap, heatGradientMap)
	local moistureMap, moistureMin, moistureMax = NoiseMap.generate(size, seed % 31, 4, 2.0)

	local landGroups, waterGroups = generateGroups(heightMap, size, heightMin, heightMax)
	generateRivers(heightMap, size)

	-- could be a 2 dimensional array, the face could be an x-offset
	local tileMap = newTileMap(size, function(face, x, y) 
		local height = normalize(heightMap[face][x][y], heightMin, heightMax)
		local heat = normalize(heatMap[face][x][y], heatMin, heatMax)
		local moisture = normalize(moistureMap[face][x][y], moistureMin, moistureMax)
		local biomeType = 0

		local heightType = getTypeForValue(height, HEIGHT_THRESHOLDS)

		-- increase moisture above water and coastal areas
		if heightType == HeightType.DEEP_WATER then
			moisture = mmin(moisture + 8 * height, 1.0)
			biomeType = BiomeType.DEEP_WATER
		elseif heightType == HeightType.SHALLOW_WATER then
			moisture = mmin(moisture + 3 * height, 1.0)
			biomeType = BiomeType.SHALLOW_WATER
		elseif heightType == HeightType.SHORE then
			moisture = mmin(moisture + 0.25 * height, 1.0)
		end

		-- above coast level: decrease temperature as height increases
		if heightType == HeightType.SNOW then
			heat = mmax(heat - height * 0.4, 0.0)
		elseif heightType == HeightType.ROCK then
			heat = mmax(heat - height * 0.3, 0.0)
		elseif heightType == HeightType.FOREST then
			heat = mmax(heat - height * 0.2, 0.0)
		elseif heightType == HeightType.GRASS then
			heat = mmax(heat - height * 0.1, 0.0)
		end			

		local moistureType = getTypeForValue(moisture, MOISTURE_THRESHOLDS)
		local heatType = getTypeForValue(heat, HEAT_THRESHOLDS)

		-- assign terrestial biomes for land above sea level
		if biomeType == 0 then
			biomeType = getBiomeType(moistureType, heatType)
		end

		-- calculate tile value based on biomeType, heightType, heatType, moistureType, height ...
		return bbor(
			blshift(heatType, BitmaskOffsets.HEAT_TYPE),					-- 3 bits
			blshift(moistureType, BitmaskOffsets.MOISTURE_TYPE),	-- 3 bits
			blshift(heightType, BitmaskOffsets.HEIGHT_TYPE),			-- 4 bits
			blshift(biomeType, BitmaskOffsets.BIOME_TYPE),				-- 4 bits
			mfloor(height * 255))																	-- 8 bits
	end)

	-- set adjacency flags for biome type & height type
	forEachTile(tileMap, function(tile, face, x, y) 
		local biome = bband(brshift(tile, BitmaskOffsets.BIOME_TYPE), 0xF)
		local height = bband(brshift(tile, BitmaskOffsets.HEIGHT_TYPE), 0xF)
		local biomeFlags, heightFlags = 0, 0

		local adjBiome, adjHeight = getAdjFlags(tileMap, size, face, x, y, Direction.Left)
		if biome == adjBiome then biomeFlags = bbor(biomeFlags, EqualityFlags.EQ_LEFT) end
		if height == adjHeight then heightFlags = bbor(heightFlags, EqualityFlags.EQ_LEFT) end

		local adjBiome, adjHeight = getAdjFlags(tileMap, size, face, x, y, Direction.Right)
		if biome == adjBiome then biomeFlags = bbor(biomeFlags, EqualityFlags.EQ_RIGHT) end
		if height == adjHeight then heightFlags = bbor(heightFlags, EqualityFlags.EQ_RIGHT) end

		local adjBiome, adjHeight = getAdjFlags(tileMap, size, face, x, y, Direction.Up)
		if biome == adjBiome then biomeFlags = bbor(biomeFlags, EqualityFlags.EQ_UP) end
		if height == adjHeight then heightFlags = bbor(heightFlags, EqualityFlags.EQ_UP) end

		local adjBiome, adjHeight = getAdjFlags(tileMap, size, face, x, y, Direction.Down)
		if biome == adjBiome then biomeFlags = bbor(biomeFlags, EqualityFlags.EQ_DOWN) end
		if height == adjHeight then heightFlags = bbor(heightFlags, EqualityFlags.EQ_DOWN) end

		tileMap[face][x][y] = bbor(tile, 
			blshift(biomeFlags, BitmaskOffsets.ADJ_BIOME_FLAGS),
			blshift(heightFlags, BitmaskOffsets.ADJ_HEIGHT_FLAGS))	
	end)

	return tileMap
end

return M
