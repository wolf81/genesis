local Grid = require 'grid'
local TerrainGen = require 'terraingen'

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

math.randomseed(os.time())

local g1 = nil -- mid
local g2 = nil -- bot
local g3 = nil -- left
local g4 = nil -- top
local g5 = nil -- right1
local g6 = nil -- right2

function love.load()
	local gridSize = 33

	g1 = Grid(gridSize)
	local t = TerrainGen(g1)
	t:generate()

	g2 = Grid(gridSize)
	for x = 0, gridSize - 1 do
		local value = g1:getValue(x, gridSize - 1)
		g2:setValue(x, 0, value)
	end
	t = TerrainGen(g2)
	t:generate()

	g3 = Grid(gridSize)
	for y = 0, gridSize - 1 do
		local value = g1:getValue(0, y)
		g3:setValue(gridSize - 1, y, value)

		value = g2:getValue(0, y)
		g3:setValue(gridSize - y - 1, gridSize - 1, value)
	end
	t = TerrainGen(g3)
	t:generate()

	g4 = Grid(gridSize)
	for x = 0, gridSize - 1 do
		local value = g1:getValue(x, 0)
		g4:setValue(x, gridSize - 1, value)

		value = g3:getValue(x, 0)
		g4:setValue(0, x, value)
	end
	t = TerrainGen(g4)
	t:generate()

	g5 = Grid(gridSize)
	for y = 0, gridSize - 1 do
		local value = g1:getValue(gridSize - 1, y)
		g5:setValue(0, y, value)

		value = g2:getValue(gridSize - 1, y)
		g5:setValue(y, gridSize - 1, value)

		value = g4:getValue(gridSize - 1, y)
		g5:setValue(gridSize - y - 1, 0, value)
	end
	t = TerrainGen(g5)
	t:generate()

	g6 = Grid(gridSize)
	for y = 0, gridSize - 1 do
		local value = g5:getValue(gridSize - 1, y)
		g6:setValue(0, y, value)

		value = g4:getValue(y, 0)
		g6:setValue(gridSize - y - 1, 0, value)

		value = g2:getValue(y, gridSize - 1)
		g6:setValue(gridSize - y - 1, gridSize - 1, value)

		value = g3:getValue(0, y)
		g6:setValue(gridSize - 1, y, value)
	end
	t = TerrainGen(g6)
	t:generate()
end

function love.draw()
	local scale = 4

	local size = g1:getSize() - 1
	for x = 1, size do
		for y = 1, size do
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
				else
					love.graphics.setColor(1.0, 1.0, 1.0)
				end

				love.graphics.rectangle('fill', (x + size) * scale, (y + size) * scale, scale, scale)
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
				else
					love.graphics.setColor(1.0, 1.0, 1.0)
				end

				love.graphics.rectangle('fill', (x + size) * scale, (y + size * 2) * scale, scale, scale)				
			end

			do 
				local v = g3:getValue(x, y)

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
				else
					love.graphics.setColor(1.0, 1.0, 1.0)
				end

				love.graphics.rectangle('fill', x * scale, (y + size) * scale, scale, scale)				
			end

			do
				local v = g4:getValue(x, y)

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
				else
					love.graphics.setColor(1.0, 1.0, 1.0)
				end

				love.graphics.rectangle('fill', (x + size) * scale, y * scale, scale, scale)				
			end

			do
				local v = g5:getValue(x, y)

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
				else
					love.graphics.setColor(1.0, 1.0, 1.0)
				end

				love.graphics.rectangle('fill', (x + size * 2) * scale, (y + size) * scale, scale, scale)				
			end

			do
				local v = g6:getValue(x, y)

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
				else
					love.graphics.setColor(1.0, 1.0, 1.0)
				end

				love.graphics.rectangle('fill', (x + size * 3) * scale, (y + size) * scale, scale, scale)				
			end			
		end
	end
end