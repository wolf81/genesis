require 'enum'

Direction = enum {
	"TOP",
	"LEFT",
	"BOTTOM",
	"RIGHT"
}

HeightType = enum { 
	"SNOW", 
	"MOUNTAIN", 
	"FOREST", 
	"PLAIN", 
	"COAST", 
	"RIVER",
	"SHALLOW_WATER", 
	"DEEP_WATER",
}

HeatType = enum {
	"WARMEST",
	"WARMER",
	"WARM",
	"COLD",
	"COLDER",
	"COLDEST",
}

MoistureType = enum {
	"DRYEST",
	"DRYER",
	"DRY",
	"WET",
	"WETTER",
	"WETTEST",
}

TileGroupType = enum {
	"WATER",
	"LAND",
}

BiomeType = enum {
	"DESERT",
	"SAVANNA",
	"TROPICAL_RAINFOREST",
	"GRASSLAND",
	"WOODLAND",
	"SEASONAL_FOREST",
	"TEMPERATE_RAINFOREST",
	"BOREAL_FOREST",
	"TUNDRA",
	"ICE",
}

TileFlags = {
	-- height flags
	["EQ_HEIGHT_TOP"] = bit.lshift(1, 0),		--> 1
	["EQ_HEIGHT_LEFT"] = bit.lshift(1, 1),		--> 2
	["EQ_HEIGHT_RIGHT"] = bit.lshift(1, 2),		--> 4
	["EQ_HEIGHT_BOTTOM"] = bit.lshift(1, 3),	--> 8
	["EQ_HEIGHT_ALL"] = bit.bor(				--> 15
		bit.lshift(1, 0), -- EQ_HEIGHT_TOP
		bit.lshift(1, 1), -- EQ_HEIGHT_LEFT
		bit.lshift(1, 2), -- EQ_HEIGHT_RIGHT
		bit.lshift(1, 3)  -- EQ_HEIGHT_BOTTOM
	),
	-- biome flags
	["EQ_BIOME_TOP"] = bit.lshift(1, 4),		--> 32
	["EQ_BIOME_LEFT"] = bit.lshift(1, 5),		--> 32
	["EQ_BIOME_RIGHT"] = bit.lshift(1, 6),		--> 32
	["EQ_BIOME_BOTTOM"] = bit.lshift(1, 7),		--> 32
	["EQ_BIOME_ALL"] = bit.bor(
		bit.lshift(1, 4), -- EQ_HEIGHT_TOP
		bit.lshift(1, 5), -- EQ_HEIGHT_LEFT
		bit.lshift(1, 6), -- EQ_HEIGHT_RIGHT
		bit.lshift(1, 7)  -- EQ_HEIGHT_BOTTOM		
	),
}