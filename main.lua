local Grid = require 'grid'
local TerrainGen = require 'terraingen'

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

math.randomseed(os.time())

local g1 = nil
local g2 = nil

function love.load()
	local gridSize = 17

	g1 = Grid(gridSize)

	local t = TerrainGen(g1)
	t:generate()
	print(g1)

	g2 = Grid(gridSize)

	for x = 0, gridSize - 1 do
		local value = g1:getValue(x, gridSize - 1)
		g2:setValue(x, 0, value)
	end

	t = TerrainGen(g2)
	t:generate()

	print(g2)
end

function love.draw()
	local scale = 8

	local size = g1:getSize()	
	for x = 1, size - 1 do
		for y = 1, size - 1 do
			do
				local v = g1:getValue(x, y)

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

				love.graphics.rectangle('fill', x * scale, y * scale, scale, scale)
			end

			do
				local v = g2:getValue(x, y)

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

				love.graphics.rectangle('fill', x * scale, (y + size) * scale, scale, scale)				
			end
		end
	end
end