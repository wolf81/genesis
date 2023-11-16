local PATH = (...):match('(.-)[^%.]+$') 
local noiseMap = require(PATH .. 'noisemap')
local gradientMap = require(PATH .. 'gradientmap')
local combineMap = require(PATH .. 'combinemap')
local BitmaskOffsets = require(PATH .. 'bitmaskoffsets')
local BiomeType = require(PATH .. 'biometype')
local HeightType = require(PATH .. 'heighttype')
local cubeMapHelper = require(PATH .. 'cubemaphelper')

local bbor, blshift = bit.bor, bit.lshift
local mmin, mmax = math.min, math.max

local generator = {}

local HEAT_THRESHOLDS 	  = { 0.15, 0.30, 0.45, 0.60, 0.75 } -- cold to hot
local MOISTURE_THRESHOLDS = { 0.27, 0.40, 0.60, 0.80, 0.90 } -- dry to wet

local BiomeTypeLookupTable = {
--		COLDEST			COLDER				COLD 					HOT								HOTTER							HOTTEST	
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.GRASSLAND,     BiomeType.DESERT, 				BiomeType.DESERT, 			   BiomeType.DESERT },				-- DRYEST
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.GRASSLAND,     BiomeType.DESERT, 				BiomeType.DESERT, 			   BiomeType.DESERT },				-- DRYER
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.WOODLAND,      BiomeType.WOODLAND, 			BiomeType.SAVANNA, 			   BiomeType.SAVANNA },				-- DRY
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.WOODLAND, 			BiomeType.SAVANNA, 			   BiomeType.SAVANNA },				-- WET
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.SEASONAL_FOREST, 		BiomeType.TROPICAL_RAINFOREST, BiomeType.TROPICAL_RAINFOREST },	-- WETTER
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.TEMPERATE_RAINFOREST, BiomeType.TROPICAL_RAINFOREST, BiomeType.TROPICAL_RAINFOREST },	-- WETTEST
}

-- normalize a value to 0.0 .. 1.0 range
local function normalize(value, min, max)
	return (value - min) / (max - min)
end

local function getBiomeType(moistureType, heatType)
	return BiomeTypeLookupTable[moistureType][heatType] 
end

local function getHeatType(heat)
	-- for heat value assign the index of closest heat threshold
	local heatIdx = #HEAT_THRESHOLDS
	for i = #HEAT_THRESHOLDS, 1, -1 do
		if heat > HEAT_THRESHOLDS[i] then
			break						
		end
		heatIdx = i
	end
	return heatIdx
end

local function getMoistureType(moisture)
	-- for moisture value assign the index of closest moisture threshold
	local moistureIdx = #MOISTURE_THRESHOLDS
	for i = #MOISTURE_THRESHOLDS, 1, -1 do
		if moisture > MOISTURE_THRESHOLDS[i] then
			break
		end
		moistureIdx = i
	end
	return moistureIdx
end

local function getHeightType(height)
	if height <= 0.2 then return HeightType.DEEP_WATER
	elseif height <= 0.4 then return HeightType.SHALLOW_WATER
	elseif height <= 0.5 then return HeightType.SHORE
	elseif height <= 0.7 then return HeightType.GRASS
	elseif height <= 0.8 then return HeightType.FOREST
	elseif height <= 0.9 then return HeightType.ROCK
	elseif height <= 1.0 then return HeightType.SNOW
	else return 0 end
end

-- generate a tile map based on size and optionally seed & sea level
-- TODO: seed, seaLevel should be part of an options table
generator.generate = function(size, seed)
	local tileMaps = {}

	-- set seed if needed and ensure an integer value is used
	seed = seed or math.random()
	if seed < 1.0 then
		 seed = math.floor(seed * 255)
	end

	local heightMap, heightMin, heightMax = noiseMap.generate(size, seed % 127, 6)

	local heatNoiseMap, _, _ = noiseMap.generate(size, seed % 63, 4, 2.0)
	local heatGradientMap, _, _ = gradientMap.generate(size, 4, 3.0)
	local heatMap, heatMin, heatMax = combineMap.generate(size, heatNoiseMap, heatGradientMap)

	local moistureMap, moistureMin, moistureMax = noiseMap.generate(size, seed % 31, 4, 2.0)

	-- could be a 2 dimensional array, the face could be an x-offset

	local tileMap = {}

	for face = 1, 6 do
		tileMap[face] = {}

		for x = 1, size do
			tileMap[face][x] = {}

			for y = 1, size do
				local height = normalize(heightMap[face][x][y], heightMin, heightMax)
				local heat = normalize(heatMap[face][x][y], heatMin, heatMax)
				local moisture = normalize(moistureMap[face][x][y], moistureMin, moistureMax)
				local biomeType = 0

				local heightType = getHeightType(height)

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

				local moistureType = getMoistureType(moisture)
				local heatType = getHeatType(heat)

				-- assign terrestial biomes for land above sea level
				if biomeType == 0 then
					biomeType = getBiomeType(moistureType, heatType)
				end

				-- set tile value based on biomeType, heightType, heatType, moistureType, height ...
				tileMap[face][x][y] = bbor(
					blshift(biomeType, BitmaskOffsets.BIOME_TYPE),						-- 4 bits
					blshift(getMoistureType(moisture), BitmaskOffsets.MOISTURE_TYPE),	-- 3 bits
					blshift(getHeatType(heat), BitmaskOffsets.HEAT_TYPE),				-- 3 bits
					blshift(getHeightType(height), BitmaskOffsets.HEIGHT_TYPE),			-- 3 bits
					height * 255)														-- 8 bits
				--[[ 
					remaining bits for: 
					- biomeType adjadency flags (4 bits)
					- heightType adjadency flags (4 bits)
					- ?
				--]] 
			end
		end
	end

	--[[
	-- calculate adjacency flags
	for face = 1, 6 do
		for x = 1, size do
			for y = 1, size do
				local tile = tileMap[face][x][y]
				--local biome = bband(brshift(tile, BitmaskOffsets.BIOME), 0xF)

				local adjFace, adjX, adjY = cubeMapHelper.getCoordDx(face, size, x, y, -1)
				local adjTile = tileMap[adjFace][adjX][adjY]
				--local adjBiome = bband(brshift(adjTile, BitmaskOffsets.BIOME), 0xF)

				adjFace, adjX, adjY = cubeMapHelper.getCoordDx(face, size, x, y, 1)
				adjTile = tileMap[adjFace][adjX][adjY]
				--adjBiome = bband(brshift(adjTile, BitmaskOffsets.BIOME), 0xF)

				adjFace, adjX, adjY = cubeMapHelper.getCoordDy(face, size, x, y, 1)
				adjTile = tileMap[adjFace][adjX][adjY]
				--adjBiome = bband(brshift(adjTile, BitmaskOffsets.BIOME), 0xF)

				adjFace, adjX, adjY = cubeMapHelper.getCoordDy(face, size, x, y, -1)
				adjTile = tileMap[adjFace][adjX][adjY]
				--adjBiome = bband(brshift(adjTile, BitmaskOffsets.BIOME), 0xF)
			end
		end
	end
	--]]

	return tileMap
end

return generator
