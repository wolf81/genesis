local Grid = require 'grid'
local TerrainGen = require 'terraingen'

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

math.randomseed(os.time())

local g = nil

function love.load()
	g = Grid(129)

	local t = TerrainGen(g)
	t:generate()
	--print(g)

	--t = Terrain(4)
	--t:generate(0.3)
	--print(t)
end

function love.draw()
	local size = g:getSize()
	for x = 1, size - 1 do
		for y = 1, size - 1 do
			local v = g:getValue(x, y)

			if v < 0.4 then
				love.graphics.setColor(0, 0, 1.0)
			elseif v < 0.41 then
				love.graphics.setColor(160/255, 160/255, 9/255)
			elseif v < 0.7 then
				love.graphics.setColor(0, 1.0, 0)
			elseif v < 0.95 then
				love.graphics.setColor(64/255, 192/255, 64/255)
			elseif v < 0.98 then
				love.graphics.setColor(0.5, 0.5, 0.5)
			elseif v ~= -1 then
				love.graphics.setColor(1.0, 1.0, 1.0)
			end

			love.graphics.rectangle('fill', x * 4, y * 4, 4, 4)
		end
	end
end