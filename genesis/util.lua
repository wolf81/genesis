local PATH = (...):match('(.-)[^%.]+$') 
local BiomeType = require(PATH .. 'biometype')

local util = {}

local BiomeInfo = {
--		COLDEST			COLDER				COLD 					HOT								HOTTER							HOTTEST	
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.GRASSLAND,     BiomeType.DESERT, 				BiomeType.DESERT, 			   BiomeType.DESERT },				-- DRYEST
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.GRASSLAND,     BiomeType.DESERT, 				BiomeType.DESERT, 			   BiomeType.DESERT },				-- DRYER
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.WOODLAND,      BiomeType.WOODLAND, 			BiomeType.SAVANNA, 			   BiomeType.SAVANNA },				-- DRY
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.WOODLAND, 			BiomeType.SAVANNA, 			   BiomeType.SAVANNA },				-- WET
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.SEASONAL_FOREST, 		BiomeType.TROPICAL_RAINFOREST, BiomeType.TROPICAL_RAINFOREST },	-- WETTER
	{ BiomeType.ICE, BiomeType.TUNDRA, BiomeType.BOREAL_FOREST, BiomeType.TEMPERATE_RAINFOREST, BiomeType.TROPICAL_RAINFOREST, BiomeType.TROPICAL_RAINFOREST },	-- WETTEST
}

util.getBiomeType = function(moisture, heat)
	return BiomeInfo[moisture][heat] 
end

return util