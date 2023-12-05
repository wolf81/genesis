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
local River = require(PATH .. 'river')

local bbor, bband, blshift, brshift = bit.bor, bit.band, bit.lshift, bit.rshift
local mmin, mmax, mfloor, mrandom = math.min, math.max, math.floor, math.random

local M = {}

local HEAT_THRESHOLDS 	  = { 0.15, 0.30, 0.45, 0.60, 0.75, 1.00 } -- cold to hot
local MOISTURE_THRESHOLDS = { 0.27, 0.40, 0.60, 0.80, 0.90, 1.00 } -- dry to wet
local HEIGHT_THRESHOLDS   = { 0.20, 0.48, 0.52, 0.70, 0.80, 0.90, 1.00 } -- low to high

local MIN_GROUP_SIZE = 32
local MAX_RIVER_ATTEMPTS = 1000
local MIN_RIVER_LENGTH = 10
local MIN_RIVER_TURNS = 3

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

local function getValue(tileMap, size, face, x, y, direction)
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
	local adjTile, adjFace, adjX, adjY = getValue(tileMap, size, face, x, y, direction)
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

local function getLowestNeighbor(heightMap, size, face, x, y)
	local neighbors = {}

	for _, direction in ipairs(Directions) do
		local height, face, x, y = getValue(heightMap, size, face, x, y, direction)
		neighbors[#neighbors + 1] = { 
			direction = direction, 
			coord = { face, x, y }, 
			height = height,
			-- key = getKey(face, x, y),
		}
	end

	table.sort(neighbors, function(a, b) return a.height < b.height end)

	return neighbors[1]
end

local function getRiverNeighborCount(size, face, x, y, riverInfo)	
	local count = 0

	local face1, x1, y1 = CubeMap.getCoordDx(size, face, x, y, -1) -- left
	if riverInfo[getKey(face1, x1, y1)] ~= nil then count = count + 1 end

	local face2, x2, y2 = CubeMap.getCoordDx(size, face, x, y, 1)  -- right
	if riverInfo[getKey(face2, x2, y2)] ~= nil then count = count + 1 end

	local face3, x3, y3 = CubeMap.getCoordDy(size, face, x, y, -1) -- up
	if riverInfo[getKey(face3, x3, y3)] ~= nil then count = count + 1 end

	local face4, x4, y4 = CubeMap.getCoordDy(size, face, x, y, 1)  -- down
	if riverInfo[getKey(face4, x4, y4)] ~= nil then count = count + 1 end

	return count
end

local function findPathToWater(heightMap, size, face, x, y, river, riverInfo, shoreHeight)
	local key = getKey(face, x, y)

	-- TODO: in riverInfo should store list of river ids and check if river.id is stored here
	if riverInfo[key] ~= nil then return false end

	-- TODO: add intersection if other river.ids exist
	River.add(river, face, x, y)

	local face1, x1, y1 = CubeMap.getCoordDx(size, face, x, y, -1) -- left
	local face2, x2, y2 = CubeMap.getCoordDx(size, face, x, y, 1)  -- right
	local face3, x3, y3 = CubeMap.getCoordDy(size, face, x, y, -1) -- up
	local face4, x4, y4 = CubeMap.getCoordDy(size, face, x, y, 1)  -- down

	local height1, height2, height3, height4 = math.huge, math.huge, math.huge, math.huge

	local neighborRiverInfo = {
		left = getRiverNeighborCount(size, face1, x1, y1, riverInfo),
		right = getRiverNeighborCount(size, face2, x2, y2, riverInfo),
		up = getRiverNeighborCount(size, face3, x3, y3, riverInfo),
		down = getRiverNeighborCount(size, face4, x4, y4, riverInfo),
	}

	-- set height if it's not already part of river and if tile contains at most one neighbor river
	if not River.contains(river, face1, x1, y1) and neighborRiverInfo.left < 2 then 
		height1 = heightMap[face1][x1][y1] 
	end
	if not River.contains(river, face2, x2, y2) and neighborRiverInfo.right < 2 then 
		height2 = heightMap[face2][x2][y2] 
	end
	if not River.contains(river, face3, x3, y3) and neighborRiverInfo.up < 2 then 
		height3 = heightMap[face3][x3][y3] 
	end
	if not River.contains(river, face4, x4, y4) and neighborRiverInfo.down < 2 then 
		height4 = heightMap[face4][x4][y4] 
	end

	-- TODO: if neighbor is existing river that is not this one, flow into it

	-- override flow direction if significantly lower
	if river.direction == Direction.Left then
		if math.abs(height2 - height1) < 0.1 then height2 = math.huge end
	elseif river.direction == Direction.Right then
		if math.abs(height2 - height1) < 0.1 then height1 = math.huge end
	elseif river.direction == Direction.Top then
		if math.abs(height4 - height3) < 0.1 then height4 = math.huge end
	elseif river.direction == Direction.Bottom then
		if math.abs(height4 - height3) < 0.1 then height3 = math.huge end
	end

	-- find minimum height
	local neighbors = {
		{ face = face1, x = x1, y = y1, height = height1, direction = Direction.Left },
		{ face = face2, x = x2, y = y2, height = height2, direction = Direction.Right },
		{ face = face3, x = x3, y = y3, height = height3, direction = Direction.Top },
		{ face = face4, x = x4, y = y4, height = height4, direction = Direction.Bottom },
	}
	table.sort(neighbors, function(a, b) return a.height < b.height end)

	local neighbor = neighbors[1]

	-- if no minimum height found, exit
	if neighbor.height == math.huge then return false end

	-- stop when sea is reached
	if neighbor.height < shoreHeight then return true end

	-- move to next neighbor
	if river.direction ~= neighbor.direction then
		river.turnCount = river.turnCount + 1
		river.direction = neighbor.direction
	end

	return findPathToWater(heightMap, size, neighbor.face, neighbor.x, neighbor.y, river, riverInfo, shoreHeight)
end

local function generateRivers(heightMap, size, heightMin, heightMax)
	-- rivers start in mountains
	local rockHeight = heightMin + HEIGHT_THRESHOLDS[5] * (heightMax - heightMin) 

	-- rivers end in the sea
	local shoreHeight = heightMin + HEIGHT_THRESHOLDS[2] * (heightMax - heightMin) 

	-- calculate river count and remaining attempts based on map area
	local area = size * 6
	local riverCount = mfloor(math.sqrt(area))
	local attemptsRemaining = mfloor(math.sqrt(size) * area) 

	local rivers = {}
	local riverInfo = {}

	while riverCount > 0 and attemptsRemaining > 0 do
		attemptsRemaining = attemptsRemaining - 1

		-- get a random coord
		local face, x, y = mrandom(6), mrandom(size), mrandom(size)

		-- skip coord if occupied by river
		if riverInfo[getKey(face, x, y)] == true then goto continue end

		-- skip coord if not starting in mountain
		if heightMap[face][x][y] < rockHeight then goto continue end

		-- flow towards lowest neighbor
		local lowestNeighbor = getLowestNeighbor(heightMap, size, face, x, y)
		local river = River.new(lowestNeighbor.direction)

		-- ... and flow towards sea
		if not findPathToWater(heightMap, size, face, x, y, river, riverInfo, shoreHeight) then
			goto continue 
		end

		-- validate river
		if river.turnCount < MIN_RIVER_TURNS or river.length < MIN_RIVER_LENGTH then 
			goto continue 
		end
		
		-- TODO: intersections check
		print('add river', river.id)

		-- add river
		rivers[#rivers + 1] = river

		-- update river info with river coords
		for key, _ in pairs(river.coordInfo) do
			riverInfo[key] = true
		end

		riverCount = riverCount - 1

		::continue::
	end

	return rivers, riverInfo
end

local function addMoisture(tileMap, face, x, y, radius)
	for x = 1, radius do
		local moisture = 0.025 / 1.0 -- magnitude ( math.sqrt(math.pow(v1, 2) - math.pow(v2, 2)) )
		
		-- each neighbor ...
	end
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
	local rivers, riverInfo = generateRivers(heightMap, size, heightMin, heightMax)

	-- could be a 2 dimensional array, the face could be an x-offset
	local tileMap = CubeMap.new(size, function(face, x, y) 
		local height = normalize(heightMap[face][x][y], heightMin, heightMax)
		local heat = normalize(heatMap[face][x][y], heatMin, heatMax)
		local moisture = normalize(moistureMap[face][x][y], moistureMin, moistureMax)
		local biomeType = 0

		local heightType = getTypeForValue(height, HEIGHT_THRESHOLDS)
		if riverInfo[getKey(face, x, y)] ~= nil then
			heightType = HeightType.RIVER
		end

		-- increase moisture above water and coastal areas
		if heightType == HeightType.DEEP_WATER then
			moisture = mmin(moisture + 8 * height, 1.0)
			biomeType = BiomeType.DEEP_WATER
		elseif heightType == HeightType.SHALLOW_WATER then
			moisture = mmin(moisture + 3 * height, 1.0)
			biomeType = BiomeType.SHALLOW_WATER
		elseif heightType == HeightType.SHORE then
			moisture = mmin(moisture + 0.25 * height, 1.0)
		elseif heightType == HeightType.RIVER then
			addMoisture(tileMap, face, x, y, 60)
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
