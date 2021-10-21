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