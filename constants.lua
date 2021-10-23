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

TileFlags = {
	["EQ_TOP"] = bit.lshift(1, 0),		--> 1
	["EQ_LEFT"] = bit.lshift(1, 1),		--> 2
	["EQ_RIGHT"] = bit.lshift(1, 2),	--> 4
	["EQ_BOTTOM"] = bit.lshift(1, 3),	--> 8
	["EQ_ALL"] = bit.bor(				--> 15
		bit.lshift(1, 0), -- EQ_TOP
		bit.lshift(1, 1), -- EQ_LEFT
		bit.lshift(1, 2), -- EQ_RIGHT
		bit.lshift(1, 3)  -- EQ_BOTTOM
	),
}