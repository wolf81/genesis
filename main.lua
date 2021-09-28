local Generator = require 'generator'
local TextureGen = require 'texturegen'

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

math.randomseed(os.time())
love.math.setRandomSeed(os.time())

local texture1 = nil

function love.load()
	love.window.setTitle('Genesis')

	local _ = love.window.setMode(1280, 800, {})

	local generator = Generator(512, 512)
	generator:generate()

	texture1 = TextureGen():generateHeightmap(generator:getWidth(), generator:getHeight(), generator:getTiles())
	texture2 = TextureGen():generateHeatmap(generator:getWidth(), generator:getHeight(), generator:getTiles())
end

function love.draw()
	local scale = 1.0
	
	love.graphics.draw(texture1, 0, 0, 0, scale, scale)
	love.graphics.draw(texture2, texture1:getWidth() * scale, 0, 0, scale, scale)
end