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

local tileMaps = nil

local tileMapType = 0

local isRendering = false

local function generate()
	tileMap = genesis.generate(SIZE, love.math.random() * 100, 0.5)
end

local function render() 
	isRendering = true

	for face = 1, 6 do
		local canvas = love.graphics.newCanvas(SIZE, SIZE)		
		canvas:renderTo(function()
			for x = 1, SIZE do
				for y = 1, SIZE do
					local tile = tileMap[face][x][y]
					local value = 0

					if tileMapType == 0 then
						value = genesis.getHeightValue(tile) / 255
					elseif tileMapType == 1 then
						value = genesis.getMoistureValue(tile) / 255
					elseif tileMapType == 2 then
						value = genesis.getHeatValue(tile) / 255
					end					

					love.graphics.setColor(value, value, value, 1.0)
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
	tileMapType = (tileMapType + 1) % 3
	render()

	if tileMapType == 0 then
		print('height')
	elseif tileMapType == 1 then
		print('moisture')
	elseif tileMapType == 2 then
		print('heat')
	end					
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
