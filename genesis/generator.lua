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
local mmin, mmax, mfloor, mrandom, mabs = math.min, math.max, math.floor, math.random, math.abs

local M = {}

local HEAT_THRESHOLDS 	  = { 0.15, 0.30, 0.45, 0.60, 0.75, 1.00 } -- cold to hot
local MOISTURE_THRESHOLDS = { 0.27, 0.40, 0.60, 0.80, 0.90, 1.00 } -- dry to wet
local HEIGHT_THRESHOLDS   = { 0.20, 0.48, 0.52, 0.70, 0.80, 0.90, 1.00 } -- low to high

local EPSILON = 0.01

local Direction = {
	Up 		= {  0, -1 },
	Down 	= {  0,  1 },
	Left 	= { -1,  0 },
	Right 	= {  1,  0 },
}

local BiomeTypeLookupTable = {
--		COLDEST			COLDER				COLD 					HOT								HOTTER							HOTTEST	
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.GRASSLAND,     BiomeType.DESERT, 				BiomeType.DESERT, 			   BiomeType.DESERT },				-- DRYEST
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.GRASSLAND,     BiomeType.DESERT, 				BiomeType.DESERT, 			   BiomeType.DESERT },				-- DRYER
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.WOODLAND,      BiomeType.WOODLAND, 			BiomeType.SAVANNA, 			   BiomeType.SAVANNA },				-- DRY
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.WOODLAND, 			BiomeType.SAVANNA, 			   BiomeType.SAVANNA },				-- WET
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.SEASONAL_FOREST, 		BiomeType.TROPICAL_RAINFOREST, BiomeType.TROPICAL_RAINFOREST },	-- WETTER
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.TEMPERATE_RAINFOREST, BiomeType.TROPICAL_RAINFOREST, BiomeType.TROPICAL_RAINFOREST },	-- WETTEST
}

-- create a deep copy
local function deepCopy(value)
	local type = type(value)
    local copy
    if type == 'table' then
        copy = {}
        for tblKey, tblValue in next, value, nil do
            copy[deepCopy(tblKey)] = deepCopy(tblValue)
        end
        setmetatable(copy, deepCopy(getmetatable(value)))
    else -- number, string, boolean, etc
        copy = value
    end
    return copy
end

local function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = mrandom(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

-- normalize a value to 0.0 .. 1.0 range
local function normalize(value, min, max)
	return (value - min) / (max - min)
end

local function getRandomDirection()
	local directions = { Direction.Up, Direction.Down, Direction.Left, Direction.Right }
	return directions[mrandom(#directions)]
end

local function getBiomeType(moistureType, heatType)
	return BiomeTypeLookupTable[moistureType][heatType] 
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

local function getTile(tileMap, size, face, x, y, direction)
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
	local adjTile, adjFace, adjX, adjY = getTile(tileMap, size, face, x, y, direction)
	local adjBiome = bband(brshift(adjTile, BitmaskOffsets.BIOME_TYPE), 0xF)
	local adjHeight = bband(brshift(adjTile, BitmaskOffsets.HEIGHT_TYPE), 0x7)
	return adjBiome, adjHeight
end

local function planchonDarboux(heightMap, size)
	local surface = {}

	-- configure initial surface
	for face = 1, 6 do
		surface[face] = {}
		for x = 1, size do
			surface[face][x] = {}
			for y = 1, size do
				surface[face][x][y] = math.huge				
				if x == 1 and y == 1 then
					surface[face][x][y] = heightMap[face][x][y]
				end
			end
		end
	end

	local directions = { Direction.Left, Direction.Right, Direction.Up, Direction.Down }

	do repeat
		local changeCount = 0

		for face = 1, 6 do
			for x = 1, size do
				for y = 1, size do
					local height = surface[face][x][y]

					for _, direction in ipairs(directions) do
						local dx, dy = unpack(direction)
						local adjFace, adjX, adjY = CubeMapHelper.getCoord(size, face, x, y, dx, dy)
						local adjHeight = heightMap[adjFace][adjX][adjY]

						if height > adjHeight + EPSILON then
							surface[face][x][y] = adjHeight + EPSILON
							changeCount = changeCount + 1
							goto continue
						end
					end

					::continue::
				end
			end
		end
		print('changeCount: ', changeCount)
	until changeCount == 0 end

	return surface
end

local function fillDepressions(heightMap, size)
	local surface = planchonDarboux(heightMap, size)

	-- determine minimum & maximum height values
	local heightMin = math.huge
	local heightMax = -math.huge

	for face = 1, 6 do
		for x = 1, size do
			for y = 1, size do
				local height = surface[face][x][y]
				heightMin = mmin(height, heightMin)
				heightMax = mmax(height, heightMax)
			end
		end
	end

	return surface, heightMin, heightMax
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

	-- TODO: instead of modifying the heightmap, maybe use the map purely to generate rivers
	heightMap, heightMin, heightMax = fillDepressions(heightMap, size)

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

				-- set tile value based on biomeType, heightType, heatType, moistureType, height ...
				tileMap[face][x][y] = bbor(
					blshift(biomeType, BitmaskOffsets.BIOME_TYPE),			-- 4 bits
					blshift(moistureType, BitmaskOffsets.MOISTURE_TYPE),	-- 3 bits
					blshift(heatType, BitmaskOffsets.HEAT_TYPE),			-- 3 bits
					blshift(heightType, BitmaskOffsets.HEIGHT_TYPE),		-- 3 bits
					mfloor(height * 255))									-- 8 bits
			end
		end
	end

	-- set adjacency flags for biome type & height type
	for face = 1, 6 do
		for x = 1, size do
			for y = 1, size do
				local tile = tileMap[face][x][y]
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
			end
		end
	end

	return tileMap
end

return M
