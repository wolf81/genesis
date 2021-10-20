local NoiseMap = require 'noisemap'
local GradientMap = require 'gradientmap'
local CombineMap = require 'combinemap'

math.randomseed(os.time())

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

local map = {}

-- config
local size = 7
local colorize = false
local invert = false
local mapType = 1

local faceInfo = {
	-- drawing offsets for each face when applied to a cube
	offsets = {
		{ 1, 1 }, { 2, 1 }, { 3, 1 }, { 0, 1 },	{ 1, 0 }, { 1, 2 },
	}
}

local function getTemperatureColor(v)
	if v < 0.15 then
		return { 0.0, 1.0, 1.0, 1.0 }
	elseif v < 0.30 then
		return { 170/255, 1.0, 1.0, 1.0 }
	elseif v < 0.45 then
		return { 0.0, 229/255, 133/255, 1.0 }
	elseif v < 0.60 then
		return { 1.0, 1.0, 100/255, 1.0 }
	elseif v < 0.75 then
		return { 1.0, 100/255, 0.0, 1.0 }
	else
		return { 241/255, 12/255, 0.0, 1.0 }
	end
end

local function getTerrainColor(v)
	if v < 0.3 then 
		return { 0.0, 0.0, 0.5, 1.0 }
	elseif v < 0.6 then return 
		{ 25/255, 25/255, 150/255, 1.0 }
	elseif v < 0.62 then return 
		{ 240/255, 240/255, 64/255, 1.0 } 
	elseif v < 0.7 then return 
		{ 50/255, 220/255, 20/255, 1.0 }
	elseif v < 0.8 then return 
		{ 16/255, 160/255, 0.0, 1.0 }
	elseif v < 0.9 then return 
		{ 0.5, 0.5, 0.5, 1.0 }
	else return 
		{ 1.0, 1.0, 1.0, 1.0 }
	end
end

local function generate()
	if mapType == 1 then
		map = NoiseMap(size, math.random() * 100)
	else
		local map1 = NoiseMap(size, math.random() * 100)
		local map2 = GradientMap(size)
		map = CombineMap(map1, map2)
	end
end

function love.load()
	love.window.setTitle('Genesis')

	local _ = love.window.setMode(1280, 800, {})

	generate()
end

function love.draw()
	local getColor = function(v) return { v, v, v, 1.0 } end

	if colorize then
		getColor = mapType == 1 and getTerrainColor or getTemperatureColor
	end

	for face = 1, 6 do
		local ox, oy = unpack(faceInfo.offsets[face])
		local w, h = map:getSize()

		for x = 0, w - 1 do
			for y = 0, h - 1 do
				local v = map:getTile(face, x, y):getValue()

				if invert then v = 1 - v end
				local c = getColor(v)

				local xi = x + (ox * w) + 0.5
				local yi = y + (oy * h) + 0.5

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
