local Generator = require 'generator'
local TextureGen = require 'texturegen'

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

math.randomseed(os.time())
love.math.setRandomSeed(os.time())

local mapSize = 9

local heightMap = nil
local heatMap = nil
local moistureMap = nil

local width, height = 0, 0

function love.load()
	love.window.setTitle('Genesis')

	local _ = love.window.setMode(1280, 800, {})

	local generator = Generator(mapSize)
	width = generator:getWidth()
	height = generator:getHeight()
	generator:generate()

	heightMap = TextureGen():generateHeightMap(width, height, generator:getTiles())
	heatMap = TextureGen():generateHeatMap(width, height, generator:getTiles())
	moistureMap = TextureGen():generateMoistureMap(width, height, generator:getTiles())
end

function love.draw()
	local scale = 0.75

	local xOffset = width * scale
	local yOffset = height * scale

	love.graphics.draw(heightMap, xOffset * 0, 0, 0, scale, scale)
	love.graphics.draw(heatMap, xOffset * 1, 0, 0, scale, scale)
	love.graphics.draw(moistureMap, xOffset * 2, 0, 0, scale, scale)
end