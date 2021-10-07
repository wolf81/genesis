local Generator = require 'generator'
local TextureGen = require 'texturegen'
local Noise = require 'noise'

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

math.randomseed(os.time())
love.math.setRandomSeed(os.time())

local mapSize = 256

local heightMap = nil
local heatMap = nil
local moistureMap = nil

function love.load()
	love.window.setTitle('Genesis')

	local _ = love.window.setMode(1280, 800, {})

	local noise = Noise.generate(3, 0.5, 0.1)
	local size = #noise
	local s = ''
	for x = 0, size - 1 do
		for y = 0, size - 1 do
			s = s .. string.format('%.2f\t', noise[x][y])
		end
		s = s .. '\n'
	end
	print(s)

	local generator = Generator(mapSize, mapSize)
	generator:generate()

	heightMap = TextureGen():generateHeightMap(mapSize, mapSize, generator:getTiles())
	heatMap = TextureGen():generateHeatMap(mapSize, mapSize, generator:getTiles())
	moistureMap = TextureGen():generateMoistureMap(mapSize, mapSize, generator:getTiles())
end

function love.draw()
	local scale = 1.0

	local xOffset = mapSize * scale

	love.graphics.draw(heightMap, xOffset * 0, 0, 0, scale, scale)
	love.graphics.draw(heatMap, xOffset * 1, 0, 0, scale, scale)
	love.graphics.draw(moistureMap, xOffset * 2, 0, 0, scale, scale)
end