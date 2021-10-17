--local DiamondSquare = require 'diamondsquare'

local DiamondSquare = require 'diamondsquare'

math.randomseed(os.time())

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

local size = 2
local map = nil

function love.load()
	love.window.setTitle('Genesis')

	local _ = love.window.setMode(1280, 800, {})

	local vmin, vmax = 1.0, 0.0

	map = DiamondSquare.create(2 ^ size, 2 ^ size)

	local s = ''
	for x = 0, map.w do
		for y = 0, map.h do
			local v = map[x][y]
			s = s .. string.format('%.2f\t', v)
		end
		s = s .. '\n'
	end	
	print(s)
end

function love.draw()
end