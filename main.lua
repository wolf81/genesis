local Generator = require 'generator'
local TextureGen = require 'texturegen'

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