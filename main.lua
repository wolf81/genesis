local NoiseMap = require 'noisemap'
local GradientMap = require 'gradientmap'
local CombineMap = require 'combinemap'
local Generator = require 'generator'

require 'functions'

math.randomseed(os.time())

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

-- config
local size = 7
local colorize = false
local mapType = 1

local generator = Generator()

local faceInfo = {
	-- drawing offsets for each face when applied to a cube
	offsets = {
		{ 1, 1 }, { 2, 1 }, { 3, 1 }, { 0, 1 },	{ 1, 0 }, { 1, 2 },
	}
}

local function getTemperatureColor(tile)
	local v = tile:getHeatValue()
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

local terrainColorMap = {
	[1] = { 1.0, 1.0, 1.0, 1.0 },
	[2] = { 0.5, 0.5, 0.5, 1.0 },
	[3] = { 16/255, 160/255, 0.0, 1.0 },
	[4] = { 50/255, 220/255, 20/255, 1.0 },
	[5] = { 240/255, 240/255, 64/255, 1.0 },
	[6] = { 25/255, 25/255, 150/255, 1.0 },
	[7] = { 0.0, 0.0, 0.5, 1.0 },
}

local function getTerrainColor(tile)
	local t = tile:getTerrainType()
	local c = terrainColorMap[t]
	return c or {1.0, 0.0, 0.0, 0.0}
end

local function generate()
	generator:generate(size, math.random() * 171)
end

function love.load()
	love.window.setTitle('Genesis')

	local _ = love.window.setMode(1280, 800, {})

	generate()
end

function love.draw()
	local w, h = generator:getSize()

	for face = 1, 6 do
		local ox, oy = unpack(faceInfo.offsets[face])

		for x = 0, w - 1 do
			for y = 0, h - 1 do
				local tile = generator:getTile(face, x, y)

				local c = mapType == 1 and getTerrainColor(tile) or getTemperatureColor(tile)

				-- draw borders around land terrain
				if tile:getBitmask() ~= 15 and tile:getTerrainType() < 6 then
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
    if key == 'g' then
    	generate()
    end


    if key == 't' then
    	mapType = (mapType + 1) % 2
    end
end
