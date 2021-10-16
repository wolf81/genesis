local Generator = require 'generator'
local TextureGen = require 'texturegen'

local ImplicitFractal = require 'accidental/implicit_fractal'
require 'accidental/enums'

local Noise = require 'accidental/noise'
local Fractal = require 'noise/fractal'

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

math.randomseed(os.time())
love.math.setRandomSeed(os.time())

local mapSize = 600

local heightMap = nil
local heatMap = nil
local moistureMap = nil

local minValue, maxValue = 0.0, -1.0

local points = {}

local colorMap = {
	{ 0.0, 0.0, 0.5, 1.0 },
	{ 25/255, 25/255, 150/255, 1.0 },
	{ 240/255, 240/255, 64/255, 1.0 },
	{ 50/255, 220/255, 20/255, 1.0 },
	{ 16/255, 160/255, 0.0, 1.0 },
	{ 0.5, 0.5, 0.5, 1.0 },
	{ 1.0, 1.0, 1.0, 1.0 },	
}

function love.load()
	love.window.setTitle('Genesis')

	local _ = love.window.setMode(1280, 800, {})

	local vmin, vmax = 1.0, 0.0

	local fractal = Fractal(6, 0.4, 10, 50000)
	local map = fractal:generate2(mapSize, mapSize)

	local s = ''
	for x = 0, mapSize - 1 do
		for y = 0, mapSize - 1 do
			local v = 1.0 - map[x][y]

			local color = colorMap[7]
			if v < 0.4 then color = colorMap[1]
			elseif v < 0.6 then color = colorMap[2]
			elseif v < 0.63 then color = colorMap[3]
			elseif v < 0.7 then color = colorMap[4]
			elseif v < 0.8 then color = colorMap[5]
			elseif v < 0.9 then color = colorMap[6]
			end
			points[#points + 1] = { x, y, unpack(color) }			
			-- s = s .. string.format('%.2f\t', v)

			--points[#points + 1] = { x, y, v, v, v, 1.0 }			
		end
		s = s .. '\n'
	end

	print(s)

	--print(v1, v2, v3)
	--print()

	--[[
	local heightMap = ImplicitFractal(
		FractalType.MULTI, 
		BasisType.SIMPLEX, 
		InterpolationType.QUINTIC, 
		octaves, 
		frequency, 
		seed
	)
	]]

	--[[
	--local v1 = Noise.SimplexNoise2D(0, 0, 300)
	--local v2 = Noise.SimplexNoise2D(50, 322, 300)
	--local v3 = Noise.SimplexNoise2D(-53, 15, 300)
	--print(v1, v2, v3)

	local s = ''

	for x = 0, width - 1 do
		for y = 0, height - 1 do
			local c = heightMap:get2D(x, y)
			if c < minValue then minValue = c end
			if c > maxValue then maxValue = c end

			points[#points + 1] = { x, y, c, c, c, 1.0 }

			--s = s .. string.format('%.2f\t', c)
		end
		--s = s .. '\n'
	end	
	--]]

	--print(s)

--[[	for _, point in ipairs(points) do
		local c = (point[3] - minValue) / (maxValue - minValue)
		point[3] = c
		point[4] = c
		point[5] = c
	end
--]]	--]]

--[[	local generator = Generator(mapSize)
	width = generator:getWidth()
	height = generator:getHeight()
	generator:generate()

	heightMap = TextureGen():generateHeightMap(width, height, generator:getTiles())
--]]	--heatMap = TextureGen():generateHeatMap(width, height, generator:getTiles())
	--moistureMap = TextureGen():generateMoistureMap(width, height, generator:getTiles())
end

function love.draw()

	love.graphics.points(points)
	-- local scale = 5.0

	-- local xOffset = width * scale
	-- local yOffset = height * scale

	-- love.graphics.draw(heightMap, xOffset * 0, 0, 0, scale, scale)
	--love.graphics.draw(heatMap, xOffset * 1, 0, 0, scale, scale)
	--love.graphics.draw(moistureMap, xOffset * 2, 0, 0, scale, scale)
end