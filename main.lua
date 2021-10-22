local Genesis = require 'genesis'
local Tile = require 'tile'

local bband = bit.band

require 'functions'
require 'constants'

math.randomseed(os.time())

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

-- config
local scale = 8
local mapType = 1

local genesis = Genesis()

local faceInfo = {
	-- drawing offsets for each face when applied to a cube
	offsets = {
		{ 1, 1 }, { 2, 1 }, { 3, 1 }, { 0, 1 },	{ 1, 0 }, { 1, 2 },
	}
}

local heatColorMap = {
	[HeatType.WARMEST] = { 241/255, 12/255, 0.0, 1.0 },
	[HeatType.WARMER] = { 1.0, 100/255, 0.0, 1.0 },
	[HeatType.WARM] = { 1.0, 1.0, 100/255, 1.0 },
	[HeatType.COLD] = { 0.0, 229/255, 133/255, 1.0 },
	[HeatType.COLDER] = { 170/255, 1.0, 1.0, 1.0 },
	[HeatType.COLDEST] = { 0.0, 1.0, 1.0, 1.0 }
}

local heightColorMap = {
	[HeightType.SNOW] = { 1.0, 1.0, 1.0, 1.0 },
	[HeightType.MOUNTAIN] = { 0.5, 0.5, 0.5, 1.0 },
	[HeightType.FOREST] = { 16/255, 160/255, 0.0, 1.0 },
	[HeightType.PLAIN] = { 50/255, 220/255, 20/255, 1.0 },
	[HeightType.COAST] = { 240/255, 240/255, 64/255, 1.0 },
	[HeightType.SHALLOW_WATER] = { 25/255, 25/255, 150/255, 1.0 },
	[HeightType.DEEP_WATER] = { 0.0, 0.0, 0.5, 1.0 },
}

local moistureColorMap = {
	[MoistureType.WETTEST] = { 0.0, 0.0, 100/255, 1.0 },
	[MoistureType.WETTER] = { 20/255, 70/255, 1.0, 1.0 },
	[MoistureType.WET] = { 85/255, 1.0, 1.0, 1.0 },
	[MoistureType.DRY] = { 80/255, 1.0, 0.0, 1.0 },
	[MoistureType.DRYER] = { 245/255, 245/255, 23/255, 1.0 },
	[MoistureType.DRYEST] = { 1.0, 139/255, 17/255, 1.0 },
}

local landColorMap = {}

local waterColorMap = {}

local function getHeatColor(tile)
	local t = tile:getHeatType()
	return heatColorMap[t] or { 1.0, 0.0, 1.0, 1.0 }
end

local function getHeightColor(tile)
	local t = tile:getHeightType()
	return heightColorMap[t] or { 1.0, 0.0, 1.0, 1.0 }
end

local function getMoistureColor(tile)
	local t = tile:getMoistureType()
	return moistureColorMap[t] or { 1.0, 0.0, 1.0, 1.0 }
end 

local function getWaterGroupColor(index)
	return waterColorMap[index] or { 1.0, 0.0, 1.0, 1.0 }
end

local function getLandGroupColor(index)
	return landColorMap[index] or { 1.0, 0.0, 1.0, 1.0 }
end

local function generate()
	love.graphics.clear(0, 0, 0, 1.0)

	local size = 2 ^ scale + 1
	genesis:generate(size, math.random())

	landColorMap = {}
	local landGroupCount = #genesis:getLandGroups()
	local step = (math.pi * 2) / (landGroupCount - 1)
	for i = 0, landGroupCount - 1 do
		local rgb = hsv(step * i, 0.8, 0.5)
		table.insert(landColorMap, rgb)
	end

	waterColorMap = {}
	local waterGroupCount = #genesis:getWaterGroups()
	local step = (math.pi * 2) / (waterGroupCount - 1)
	for i = 0, waterGroupCount - 1 do
		local rgb = hsv(step * i, 0.6, 0.8)
		table.insert(waterColorMap, rgb)
	end
end

function love.load()
	love.window.setTitle('Genesis')

	local _ = love.window.setMode(1280, 800, {})

	generate()
end

function love.draw()
	local w, h = genesis:getSize()

	if mapType > 2 then
		local getWaterColor = mapType == 3 and getWaterGroupColor or function()
			return { 0.0, 0.0, 0.1, 1.0 }
		end

		local getLandColor = mapType == 4 and getLandGroupColor or function()
			return { 0.0, 0.1, 0.0, 1.0 }
		end

		for i, tileGroup in ipairs(genesis:getWaterGroups()) do
			local c = getWaterColor(i)

			for _, tile in ipairs(tileGroup:getTiles()) do
				local face, x, y = tile:getPosition()
				local ox, oy = unpack(faceInfo.offsets[face])

				local xi = x + (ox * w) + 0.5
				local yi = y + (oy * h) + 0.5

				love.graphics.setColor(c)
				love.graphics.points(xi, yi)	
			end
		end

		for i, tileGroup in ipairs(genesis:getLandGroups()) do
			local c = getLandColor(i)

			for _, tile in ipairs(tileGroup:getTiles()) do
				local face, x, y = tile:getPosition()
				local ox, oy = unpack(faceInfo.offsets[face])

				local xi = x + (ox * w) + 0.5
				local yi = y + (oy * h) + 0.5

				love.graphics.setColor(c)
				love.graphics.points(xi, yi)	
			end
		end

		return
	end

	local getColor = (
		mapType == 1 and getHeightColor or 
		mapType == 2 and getHeatColor or 
		getMoistureColor
	)

	for face = 1, 6 do
		local ox, oy = unpack(faceInfo.offsets[face])

		for x = 0, w - 1 do
			for y = 0, h - 1 do
				local tile = genesis:getTile(face, x, y)			
				local c = getColor(tile)

				if bband(tile:getFlags(), TileFlags.EQ_ALL) ~= TileFlags.EQ_ALL and tile:getHeightType().id < 6 then
					c = { lerp(c[1], 0.0, 0.4), lerp(c[2], 0.0, 0.4), lerp(c[3], 0.0, 0.4), 1.0 }
				end

				local xi = x + (ox * w) + 0.5
				local yi = y + (oy * h) + 0.5

				love.graphics.setColor(c)
				love.graphics.points(xi, yi)					
			end
		end
	end
end

function love.keypressed(key, code)
	-- generate a new random terrain
    if key == 'g' then
    	generate()
    end

    -- toggle between heightmap, heatmap, moisture map, water groups, land groups
    if key == 't' then
    	mapType = (mapType + 1) % 5
    end
end
