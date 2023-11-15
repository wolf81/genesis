local PATH = (...):match('(.-)[^%.]+$') 
local noiseMap = require(PATH .. 'noisemap')
local gradientMap = require(PATH .. 'gradientmap')
local combineMap = require(PATH .. 'combinemap')
local util = require(PATH .. 'util')
local BitmaskOffsets = require(PATH .. 'bitmaskoffsets')
local BiomeType = require(PATH .. 'biometype')
local cubeMapHelper = require(PATH .. 'cubemaphelper')

local bbor, blshift = bit.bor, bit.lshift

local HEAT_THRESHOLDS 	  = { 0.15, 0.30, 0.45, 0.60, 0.75 } -- cold to hot
local MOISTURE_THRESHOLDS = { 0.27, 0.40, 0.60, 0.80, 0.90 } -- dry to wet

local mmin, mmax = math.min, math.max

local generator = {}

-- normalize a value to 0.0 .. 1.0 range
local function normalize(value, min, max)
	return (value - min) / (max - min)
end

-- generate a tile map based on size and optionally seed & sea level
-- TODO: seed, seaLevel should be part of an options table
generator.generate = function(size, seed, seaLevel)
	local tileMaps = {}

	-- set seed if needed and ensure an integer value is used
	seed = seed or math.random()
	if seed < 1.0 then
		 seed = math.floor(seed * 255)
	end

	seaLevel = seaLevel or 0.6
	local oceanLevel = seaLevel * 0.7
	local coastLevel = seaLevel + 0.02
	local shoreLevel = seaLevel + 0.1

	local heightMap, heightMin, heightMax = noiseMap.generate(size, seed % 127, 6, 0.5)

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
				local biome = 0

				-- increase moisture above water and coastal areas
				if height <= oceanLevel then
					moisture = mmin(moisture + 8 * height, 1.0)
					biome = BiomeType.DEEP_WATER
				elseif height <= seaLevel then
					moisture = mmin(moisture + 3 * height, 1.0)
					biome = BiomeType.SHALLOW_WATER
				elseif height <= coastLevel then
					moisture = mmin(moisture + height, 1.0)
				elseif height <= shoreLevel then
					moisture = mmin(moisture + height / 4, 1.0)
				end

				-- above coast level: decrease temperature as height increases
				local heatOffset = (1.0 - seaLevel) / 4				
				if height >= (seaLevel + heatOffset * 3) then
					heat = mmax(heat - height * 0.4, 0.0)
				elseif height >= (seaLevel + heatOffset * 2) then
					heat = mmax(heat - height * 0.3, 0.0)
				elseif height >= (seaLevel + heatOffset) then
					heat = mmax(heat - height * 0.2, 0.0)
				elseif height >= coastLevel then
					heat = mmax(heat - height * 0.1, 0.0)
				end

				-- for heat value assign the index of closest heat threshold
				local heatIdx = #HEAT_THRESHOLDS
				for i = #HEAT_THRESHOLDS, 1, -1 do
					if heat > HEAT_THRESHOLDS[i] then
						break						
					end
					heatIdx = i
				end
				heat = heatIdx

				-- for moisture value assign the index of closest moisture threshold
				local moistureIdx = #MOISTURE_THRESHOLDS
				for i = #MOISTURE_THRESHOLDS, 1, -1 do
					if moisture > MOISTURE_THRESHOLDS[i] then
						break
					end
					moistureIdx = i
				end
				moisture = moistureIdx

				-- assign terrestial biomes for land above sea level
				if height > seaLevel then
					biome = util.getBiomeType(moisture, heat)
				end

				-- set tile value based on biome, height, heat, moisture, ...
				tileMap[face][x][y] = bbor(
					blshift(biome, BitmaskOffsets.BIOME),			-- 4 bits
					blshift(height * 255, BitmaskOffsets.HEIGHT),	-- 8 bits
					blshift(heat, BitmaskOffsets.HEAT),				-- 3 bits
					moisture) 										-- 3 bits
				--[[ 
					remaining 14 bits for: 
					- height type (3 bits): 
						- DeepWater (0.2), 
						- ShallowWater (0.4), 
						- Sand (0.5), 
						- Grass (0.7), 
						- Forest (0.8), 
						- Rock (0.9), 
						- Snow (1.0)
					- neighbor equal biome flags (4 bits)
					- neighbor equal height flags (4 bits)
					- ?
				--]] 
			end
		end
	end

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

	return tileMap
end

return generator
