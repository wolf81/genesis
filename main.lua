-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

local genesis = require 'genesis'

local SIZE = 100

local FACE_OFFSETS = {
	{ 1, 1 }, 
	{ 2, 1 }, 
	{ 3, 1 }, 
	{ 0, 1 },
	{ 1, 0 }, 
	{ 1, 2 },
}

local textures = {}

local tileMap = nil

local tileMapType = 0

local isRendering = false

local MoistureColors = {
	{ 1.0, 139/255, 17/255, 1.0 },
	{ 245/255, 245/255, 23/255, 1.0 },
	{ 80/255, 1.0, 0.0, 1.0 },
	{ 85/255, 1.0, 1.0, 1.0 },
	{ 20/255, 70/255, 1.0, 1.0 },
	{ 0.0, 0.0, 100/255, 1.0 },
}

local HeatColors = {
	{ 0.0, 1.0, 1.0, 1.0 },
	{ 170/255, 1.0, 1.0, 1.0 },
	{ 0.0, 229/255, 133/255, 1.0 },
	{ 1.0, 1.0, 100/255, 1.0 },
	{ 1.0, 100/255, 0.0, 1.0 },
	{ 241/255, 12/255, 0.0, 1.0 },
}

local HeightColors = {
	{ 0.0, 0.0, 0.5, 1.0 },
	{ 25/255, 25/255, 150/255, 1.0 },
	{ 240 / 255, 240 / 255, 64 / 255, 1.0 },
	{ 0 / 255, 220 / 255, 20 / 255, 1.0 },
	{ 16 / 255, 160 / 255, 0.0, 1.0 },
	{ 0.5, 0.5, 0.5, 1.0 },            
	{ 1.0, 1.0, 1.0, 1.0 },
}

local BiomeColors = {
	{ 1.0, 1.0, 1.0, 1.0 },
	{ 96/255, 131/255, 112/255, 1.0 },
	{ 164/255, 225/255, 99/255, 1.0 },
	{ 238/255, 218/255, 130/255, 1.0 },
	{ 139/255, 175/255, 90/255, 1.0 },
	{ 177/255, 209/255, 110/255, 1.0 },
	{ 95/255, 115/255, 62/255, 1.0 },
	{ 66/255, 123/255, 25/255, 1.0 },
	{ 73/255, 100/255, 35/255, 1.0 },
	{ 29/255, 73/255, 40/255, 1.0 },
	{ 25/255, 25/255, 150/255, 1.0 },
	{ 0.0, 0.0, 0.5, 1.0 },
}

local function generate()
	tileMap = genesis.generate(SIZE)
end

local function render() 
	isRendering = true

	if tileMapType == 0 then
		print('height')
	elseif tileMapType == 1 then
		print('moisture')
	elseif tileMapType == 2 then
		print('heat')
	elseif tileMapType == 3 then
		print('biome')
	end					

	for face = 1, 6 do
		local canvas = love.graphics.newCanvas(SIZE, SIZE)		
		canvas:renderTo(function()
			for x = 1, SIZE do
				for y = 1, SIZE do
					local tile = tileMap[face][x][y]

					if tileMapType == 0 then
						local value = genesis.getHeightValue(tile) / 255
						love.graphics.setColor(value, value, value, 1.0)
					elseif tileMapType == 1 then						
						local value = genesis.getMoistureValue(tile)
						love.graphics.setColor(unpack(MoistureColors[value]))
					elseif tileMapType == 2 then
						local value = genesis.getHeatValue(tile)
						love.graphics.setColor(unpack(HeatColors[value]))						
					elseif tileMapType == 3 then
						local value = genesis.getBiomeType(tile)
						love.graphics.setColor(unpack(BiomeColors[value]))
					end

					love.graphics.points(x - 1, y)
				end
			end
		end)
		textures[face] = canvas
	end

	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

	isRendering = false
end

local function toggle()
	tileMapType = (tileMapType + 1) % 4
	render()
end

function love.load(args)
	generate()
	render()
end

function love.keyreleased(key)
	if key == 'g' then
		generate()
		render()
	end

	if key == 't' then
		toggle()
	end

	if key == "escape" then
		love.event.quit()
	end
end

function love.draw()
	if isRendering then return end

	love.graphics.push()
	love.graphics.scale(2)
	for face = 1, 6 do
		local ox, oy = unpack(FACE_OFFSETS[face])
		love.graphics.draw(textures[face], ox * SIZE, oy * SIZE)
	end
	love.graphics.pop()
end
