require 'enum'

HeightType = enum { 
	"SNOW", 
	"MOUNTAIN", 
	"FOREST", 
	"PLAIN", 
	"COAST", 
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

TileFlags = {
	["EQ_TOP"] = bit.lshift(1, 0),
	["EQ_LEFT"] = bit.lshift(1, 1),
	["EQ_RIGHT"] = bit.lshift(1, 2),
	["EQ_BOTTOM"] = bit.lshift(1, 3),
	["EQ_ALL"] = bit.bor(
		bit.lshift(1, 0), -- EQ_TOP
		bit.lshift(1, 1), -- EQ_LEFT
		bit.lshift(1, 2), -- EQ_RIGHT
		bit.lshift(1, 3)  -- EQ_BOTTOM
	),
}