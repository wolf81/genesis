local Generator = require 'generator'
local TextureGen = require 'texturegen'

local ImplicitFractal = require 'accidental/implicit_fractal'
require 'accidental/enums'

local Noise = require 'accidental/noise'

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

math.randomseed(os.time())
love.math.setRandomSeed(os.time())

local mapSize = 9

local heightMap = nil
local heatMap = nil
local moistureMap = nil

local width, height = 10, 10
local points = {}

function love.load()
	love.window.setTitle('Genesis')

	local _ = love.window.setMode(1280, 800, {})

	local octaves = 6
	local frequency = 1.25
	local seed = math.random() * 100

	local heightMap = ImplicitFractal(
		FractalType.MULTI, 
		BasisType.SIMPLEX, 
		InterpolationType.QUINTIC, 
		octaves, 
		frequency, 
		seed
	)

	local v1 = Noise.SimplexNoise2D(0, 0, 300)
	local v2 = Noise.SimplexNoise2D(50, 322, 300)
	local v3 = Noise.SimplexNoise2D(-53, 15, 300)
	print(v1, v2, v3)


	--[[
	for x = 0, width do
		for y = 0, height do
			local c = heightMap:get2D(x, y)
			print(c)
			points[#points + 1] = {x, y, c, c, c, 1.0 }
		end
	end
	--]]

	--[[
	local generator = Generator(mapSize)
	width = generator:getWidth()
	height = generator:getHeight()
	generator:generate()

	heightMap = TextureGen():generateHeightMap(width, height, generator:getTiles())
	heatMap = TextureGen():generateHeatMap(width, height, generator:getTiles())
	moistureMap = TextureGen():generateMoistureMap(width, height, generator:getTiles())
	]]
end

function love.draw()

	love.graphics.points(points)
	--[[
	local scale = 0.75

	local xOffset = width * scale
	local yOffset = height * scale

	love.graphics.draw(heightMap, xOffset * 0, 0, 0, scale, scale)
	love.graphics.draw(heatMap, xOffset * 1, 0, 0, scale, scale)
	love.graphics.draw(moistureMap, xOffset * 2, 0, 0, scale, scale)
	]]
end