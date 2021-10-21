local Genesis = require 'genesis'

require 'functions'

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
	[1] = { 241/255, 12/255, 0.0, 1.0 },
	[2] = { 1.0, 100/255, 0.0, 1.0 },
	[3] = { 1.0, 1.0, 100/255, 1.0 },
	[4] = { 0.0, 229/255, 133/255, 1.0 },
	[5] = { 170/255, 1.0, 1.0, 1.0 },
	[6] = { 0.0, 1.0, 1.0, 1.0 }
}

local heightColorMap = {
	[1] = { 1.0, 1.0, 1.0, 1.0 },
	[2] = { 0.5, 0.5, 0.5, 1.0 },
	[3] = { 16/255, 160/255, 0.0, 1.0 },
	[4] = { 50/255, 220/255, 20/255, 1.0 },
	[5] = { 240/255, 240/255, 64/255, 1.0 },
	[6] = { 25/255, 25/255, 150/255, 1.0 },
	[7] = { 0.0, 0.0, 0.5, 1.0 },
}

local moistureColorMap = {
	[1] = { 0.0, 0.0, 100/255, 1.0 },
	[2] = { 20/255, 70/255, 1.0, 1.0 },
	[3] = { 85/255, 1.0, 1.0, 1.0 },
	[4] = { 80/255, 1.0, 0.0, 1.0 },
	[5] = { 245/255, 245/255, 23/255, 1.0 },
	[6] = { 1.0, 139/255, 17/255, 1.0 },
}

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

local function generate()
	local size = 2 ^ scale + 1
	genesis:generate(size, math.random())
end

function love.load()
	love.window.setTitle('Genesis')

	local _ = love.window.setMode(1280, 800, {})

	generate()
end

function love.draw()
	local w, h = genesis:getSize()

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

				-- draw borders around different types of land terrain
				if tile:getBitmask() ~= 15 and tile:getHeightType() < 6 then
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

    -- toggle between heightmap and heatmap
    if key == 't' then
    	mapType = (mapType + 1) % 3
    end
end
