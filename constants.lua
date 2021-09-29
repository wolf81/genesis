HeatType = {
	COLDEST = 0.15,
	COLDER = 0.30,
	COLD = 0.45,
	WARM = 0.60,
	WARMER = 0.75,
	WARMEST = 1.0,

	getColor = function(heatType)
		if heatType == HeatType.COLDEST then
			return { 0.0, 1.0, 1.0, 1.0 }
		elseif heatType == HeatType.COLDER then
			return { 170/255, 1.0, 1.0, 1.0 }
		elseif heatType == HeatType.COLD then
			return { 0.0, 229/255, 133/255, 1.0 }
		elseif heatType == HeatType.WARM then
			return { 1.0, 1.0, 100/255, 1.0 }
		elseif heatType == HeatType.WARMER then
			return { 1.0, 100/255, 0.0, 1.0 }
		else -- HeatType.WARMEST
			return { 241/255, 12/255, 0.0, 1.0 }
		end
	end
}

TerrainType = {
	DEEP_WATER = 0.4,
	SHALLOW_WATER = 0.6,
	SAND = 0.65,
	GRASS = 0.7,
	FOREST = 0.8,
	ROCK = 0.9,
	SNOW = 1.0,

	getColor = function(terrainType)
		if terrainType == TerrainType.DEEP_WATER then 
			return { 0.0, 0.0, 0.5, 1.0 }
		elseif terrainType == TerrainType.SHALLOW_WATER then 
			return { 25/255, 25/255, 150/255, 1.0 }
		elseif terrainType == TerrainType.SAND then 
			return { 240/255, 240/255, 64/255, 1.0 }
		elseif terrainType == TerrainType.GRASS then 
			return { 50/255, 220/255, 20/255, 1.0 }
		elseif terrainType == TerrainType.FOREST then 
			return { 16/255, 160/255, 0.0, 1.0 }
		elseif terrainType == TerrainType.ROCK then 
			return { 0.5, 0.5, 0.5, 1.0 }
		else -- TerrainType.SNOW
			return { 1.0, 1.0, 1.0, 1.0 }
		end
	end
}

MoistureType = {
	DRYEST = 0,
	DRYER = 0.27,
	DRY = 0.4,
	WET = 0.6,
	WETTER = 0.8,
	WETTEST = 0.9,

	getColor = function(moistureType)
		return { 0.0, 0.5, 0.5, 1.0 }
	end
}