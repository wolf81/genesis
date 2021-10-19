local NoiseMap = require 'noisemap'
local GradientMap = require 'gradientmap'

math.randomseed(os.time())

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

local maps = {}

-- config
local size = 8
local colorize = false
local invert = false
local mapType = 1

local faceInfo = {
	-- drawing offsets for each face when applied to a cube
	offsets = {
					{ 1, 0 },
		{ 0, 1 }, 	{ 1, 1 },	{ 2, 1 },	{ 3, 1 },
					{ 1, 2 },
	}
}

local function getTerrainColor(v)
	if v < 0.35 then 
		return { 0.0, 0.0, 0.5, 1.0 }
	elseif v < 0.6 then return 
		{ 25/255, 25/255, 150/255, 1.0 }
	elseif v < 0.61 then return 
		{ 240/255, 240/255, 64/255, 1.0 } 
	elseif v < 0.7 then return 
		{ 50/255, 220/255, 20/255, 1.0 }
	elseif v < 0.88 then return 
		{ 16/255, 160/255, 0.0, 1.0 }
	elseif v < 0.98 then return 
		{ 0.5, 0.5, 0.5, 1.0 }
	else return 
		{ 1.0, 1.0, 1.0, 1.0 }
	end
end

local function normalizeMap(map, min, max)
    -- normalize values in range 0.0 ... 1.0
    for x = 0, map.w do        
        for y = 0, map.h do
            local v = map[y][x]
            v = math.max(math.min(v, max), min)
            map[y][x] = (v - min) / (max - min)
        end
    end
end

local function generate()
	maps = {}

	local vmin, vmax = 1.0, 0.0

	-- generate 6 maps, 1 for each face of a cube
	for i = 1, 6 do
		local f = nil

		-- use initializer functions to stitch maps together
		if i == 2 then
			f = function(map)
				for j = 0, map.h do
					map[j][0] = maps[1][0][j]
				end
			end
		elseif i == 3 then
			f = function(map)
				for j = 0, map.w do
					map[j][0] = maps[1][j][map.h]
					map[0][j] = maps[2][map.w][j]
				end
			end			
		elseif i == 4 then
			f = function(map)
				for j = 0, map.h do
					map[0][j] = maps[3][map.w][j]
					map[j][0] = maps[1][map.w][map.w - j]
				end
			end					
		elseif i == 5 then
			f = function(map)
				for j = 0, map.h do
					map[0][j] = maps[4][map.w][j]
					map[j][0] = maps[1][map.w - j][0]
					map[map.w][j] = maps[2][0][j]
				end
			end
		elseif i == 6 then
			f = function(map)
				for j = 0, map.w do
					map[j][0] = maps[3][j][map.h]
					map[0][j] = maps[2][map.w - j][map.h]
					map[map.w][j] = maps[4][j][map.h]
					map[j][map.h] = maps[5][map.w - j][map.h]
				end
			end			
		end

		if mapType == 1 then
			maps[#maps + 1] = NoiseMap.create(size, f)
		else
			maps[#maps + 1] = GradientMap.create(size, i == 1 or i == 6)
		end
	end

	-- calculate average minimum & maximum
	local min, max = 0, 0
	for _, map in ipairs(maps) do
		min = min + map.min
		max = max + map.max
	end
	min = min / #maps
	max = max / #maps

	-- normalize map values in 0.0 ... 1.0 range
	for i = 1, 6 do
		normalizeMap(maps[i], min, max)
	end	
end

function love.load()
	love.window.setTitle('Genesis')

	local _ = love.window.setMode(1280, 800, {})

	generate()
end

function love.draw()
	if #maps < 6 then return end

	for i, map in ipairs(maps) do
		local ox, oy = unpack(faceInfo.offsets[i])

		for x = 0, map.w do
			for y = 0, map.h do
				local v = map[x][y]
				if invert then v = 1 - v end
				local c = colorize and getTerrainColor(v) or { v, v, v, 1.0 }

				local xi = x + (ox * map.w) + 0.5
				local yi = y + (oy * map.h) + 0.5

				love.graphics.setColor(c)
				love.graphics.points(xi, yi)
			end
		end
	end
end

function love.keypressed(key, code)
    if key == 'g' then
    	generate()
    end

    if key == 'c' then
    	colorize = not colorize
    end

    if key == 'i' then
    	invert = not invert
    end

    if key == 't' then
    	mapType = (mapType + 1) % 2
    	generate()
    end
end
