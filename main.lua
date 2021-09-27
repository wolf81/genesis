local Terrain = require 'terrain'
local Map = require 'map'

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

love.math.setRandomSeed(love.timer.getTime())

local t = nil

function love.load()
	t = Terrain(4)
	t:generate(0.3)

	print(t)
end

function love.draw()
	local size = t:getSize() - 1
	local n = 0
	for x = 1, size do
		for y = 1, size do
			local v = t:getValue(x, y)
			n = n + 1
			print(v)
			love.graphics.points(1, 1)
			love.graphics.points(1, 2)
		end
	end
	print('1111')
end