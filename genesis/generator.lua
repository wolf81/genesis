local PATH = (...):match('(.-)[^%.]+$') 
local NoiseMap = require(PATH .. 'noisemap')
local GradientMap = require(PATH .. 'gradientmap')
local CombineMap = require(PATH .. 'combinemap')
local BitmaskOffsets = require(PATH .. 'bitmaskoffsets')
local EqualityFlags = require(PATH .. 'equalityflags')
local BiomeType = require(PATH .. 'biometype')
local HeightType = require(PATH .. 'heighttype')
local CubeMap = require(PATH .. 'cubemap')
local Group = require(PATH .. 'group')

local bbor, bband, blshift, brshift = bit.bor, bit.band, bit.lshift, bit.rshift
local mmin, mmax, mfloor, mrandom = math.min, math.max, math.floor, math.random

local M = {}

local HEAT_THRESHOLDS 	  = { 0.15, 0.30, 0.45, 0.60, 0.75, 1.00 } -- cold to hot
local MOISTURE_THRESHOLDS = { 0.27, 0.40, 0.60, 0.80, 0.90, 1.00 } -- dry to wet
local HEIGHT_THRESHOLDS   = { 0.20, 0.48, 0.52, 0.70, 0.80, 0.90, 1.00 } -- low to high

local MIN_GROUP_SIZE = 32

local GroupType = {
	LAND 	= 1,
	WATER 	= 2,
}

local Direction = {
	Up 		= {  0, -1 },
	Down 	= {  0,  1 },
	Left 	= { -1,  0 },
	Right 	= {  1,  0 },
}

local Directions = { Direction.Left, Direction.Right, Direction.Up, Direction.Down }

local BiomeTypeInfo = {
--	  COLDEST		 COLDER			   COLD 					HOT							HOTTER						HOTTEST	
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.GRASSLAND,     BiomeType.DESERT, 			BiomeType.DESERT, 			BiomeType.DESERT 		  }, -- DRYEST
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.GRASSLAND,     BiomeType.DESERT, 			BiomeType.DESERT, 			BiomeType.DESERT 		  }, -- DRYER
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.WOODLAND,      BiomeType.WOODLAND, 		BiomeType.SAVANNA, 			BiomeType.SAVANNA 		  }, -- DRY
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.WOODLAND, 		BiomeType.SAVANNA, 			BiomeType.SAVANNA 		  }, -- WET
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.SEASONAL_FOREST, 	BiomeType.TROP_RAINFOREST, 	BiomeType.TROP_RAINFOREST }, -- WETTER
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.TEMP_RAINFOREST, 	BiomeType.TROP_RAINFOREST, 	BiomeType.TROP_RAINFOREST }, -- WETTEST
}

-- normalize a value to 0.0 .. 1.0 range
local function normalize(value, min, max)
	return (value - min) / (max - min)
end

local function round(a, b)
	 return (a - a % b) / b
end

local function getBiomeType(moistureType, heatType)
	return BiomeTypeInfo[moistureType][heatType] 
end

local function getKey(face, x, y)
	return bbor(blshift(face, 28), blshift(x, 14), y)
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
		face, x, y = CubeMap.getCoordDx(size, face, x, y, dx)
	end

	if dy ~= 0 then
		face, x, y = CubeMap.getCoordDy(size, face, x, y, dy)
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

	-- mark coord as processed
	fillInfo[getKey(face, x, y)] = group.id

	-- add coord to current group coords
	Group.add(group, face, x, y)

	-- add neighbors to the stack, if they are of similar group type
	for _, direction in ipairs(Directions) do
		local face, x, y = CubeMap.getCoord(size, face, x, y, unpack(direction))
		if fillInfo[getKey(face, x, y)] ~= nil then goto continue end

		local height = heightMap[face][x][y]
		if getGroupType(height) ~= group.type then goto continue end

		stack[#stack + 1] = { face, x, y }

		::continue::
	end
end

local function generateGroups(heightMap, size, heightMin, heightMax, didRemoveSmallGroups)
	local fillInfo, landGroups, waterGroups, stack = {}, {}, {}, {}

	-- shore starts at top of shallow water
	local shoreHeight = heightMin + HEIGHT_THRESHOLDS[2] * (heightMax - heightMin) 

	-- determine group type for current height value, based on minimum & maximum height values
	local getGroupType = function(height)
		return (height >= shoreHeight) and GroupType.LAND or GroupType.WATER
	end

	-- generate land & water groups
	for face, x, y, height in CubeMap.iter(heightMap) do
		-- skip already processed coords
		if fillInfo[getKey(face, x, y)] ~= nil then goto continue end 

		-- create a new group for the current group type
		local group = Group.new(getGroupType(height))

		-- add the initial coord to the stack, that will have neighbors added
		stack[#stack + 1] = { face, x, y }

		-- process neighbors until border is reached for current group type
		while #stack > 0 do
			floodFill(heightMap, size, table.remove(stack), group, getGroupType, fillInfo, stack)
		end

		-- only store groups with multiple coords
		if group.size > 0 then
			if group.type == GroupType.LAND then
				landGroups[#landGroups + 1] = group
			else
				waterGroups[#waterGroups + 1] = group
			end
		end

		::continue::
	end

	-- remove tiny & small islands and lakes
	if not didRemoveSmallGroups then
		for _, groups in ipairs({ landGroups, waterGroups }) do
			for _, group in ipairs(groups) do
				local v = group.type == GroupType.WATER and 0.05 or -0.05

				if group.size < MIN_GROUP_SIZE then
					for face, x, y in Group.iter(group) do
						heightMap[face][x][y] = heightMap[face][x][y] + v
					end
				end
			end
		end

		return generateGroups(heightMap, size, heightMin, heightMax, true)
	end

	print('landGroups: ' .. #landGroups, 'waterGroups: ' .. #waterGroups)

	return landGroups, waterGroups
end

local function generateRivers(heightMap, size, landGroups, heightMin, heightMax)
	-- rivers start in mountains
	local rockHeight = heightMin + HEIGHT_THRESHOLDS[5] * (heightMax - heightMin) 

	-- rivers end in the sea
	local shoreHeight = heightMin + HEIGHT_THRESHOLDS[2] * (heightMax - heightMin) 

	for _, landGroup in ipairs(landGroups) do
		local coords = {}

		-- find coords of mountains
		for face, x, y in Group.iter(landGroup) do
			if heightMap[face][x][y] > rockHeight then
				coords[#coords + 1] = { face, x, y }
			end
		end		

		-- if no mountain coords were found, can try next land group
		if #coords == 0 then goto continue end

		local riverCount = mfloor(math.log(landGroup.size) / math.log(10))

		for i = 1, riverCount do
			-- choose a random coord from the mountain coords
			local coord = coords[mrandom(#coords)]

			-- choose a random direction
			local angle = mrandom(math.pi * 2)
			local dx, dy = math.cos(angle), math.sin(angle)

			-- store river path
			local path = { coord }

			-- try find a path towards the sea based on current coord and angle
			local face, x, y = unpack(coord)
			for i = 1, size * 4 do
				local face1, x1, y1 = CubeMap.getCoord(size, face, x, y, round(i * dx, 1), round(i * dy, 1))
				local height = heightMap[face1][x1][y1]

				local lastCoord = path[#path]
				if lastCoord[1] ~= face1 or lastCoord[2] ~= x1 or lastCoord[3] ~= y1 then
					path[#path + 1] = { face1, x1, y1 }
				end 

				heightMap[face1][x1][y1] = shoreHeight - 0.1

				if height < shoreHeight then
					break
				end
			end

			-- for _, coord in ipairs(path) do
			-- 	print(unpack(coord))
			-- end

			-- print()

			-- 1. for each path, find a mid point
			-- 2. find intersecting vector 
			-- 3. check both sides of vector for some distance to find lowest point
			-- 4. create new path between path start and end point with mid point
			-- 5. rinse and repeat 

			-- TODO: how can we get mid point between 2 coords from cube map?
			--	issue, we need to know the angle between 2 points in cube map, which is different if 
			-- 	each point is on different face
			--	probably need to "flatten" the faces  

			::continue::			
		end

		::continue::
	end

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
	generateRivers(heightMap, size, landGroups, heightMin, heightMax)

	-- could be a 2 dimensional array, the face could be an x-offset
	local tileMap = CubeMap.new(size, function(face, x, y) 
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
			blshift(heatType, BitmaskOffsets.HEAT_TYPE),			-- 3 bits
			blshift(moistureType, BitmaskOffsets.MOISTURE_TYPE),	-- 3 bits
			blshift(heightType, BitmaskOffsets.HEIGHT_TYPE),		-- 4 bits
			blshift(biomeType, BitmaskOffsets.BIOME_TYPE),			-- 4 bits
			mfloor(height * 255))									-- 8 bits
	end)

	-- set adjacency flags for biome type & height type
	for face, x, y, tile in CubeMap.iter(tileMap) do
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

	return tileMap, groups
end

return M
