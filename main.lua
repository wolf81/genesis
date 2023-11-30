-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

local genesis = require 'genesis'

local Generator = genesis.Generator

local SIZE = 200

local FaceOffsets = {
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

local title = ''

local isBusy = false

local Colors = {
	Height = {
		{ 0.0, 0.0, 0.5, 1.0 },
		{ 0.1, 0.1, 0.6, 1.0 },
		{ 0.9, 0.9, 0.3, 1.0 },
		{ 0.2, 0.9, 0.1, 1.0 },
		{ 0.1, 0.6, 0.0, 1.0 },
		{ 0.5, 0.5, 0.5, 1.0 },            
		{ 1.0, 1.0, 1.0, 1.0 },
		{ 0.0, 0.0, 1.0, 1.0 },
	},
	Moisture = {
		{ 1.0, 0.5, 0.1, 1.0 },
		{ 1.0, 1.0, 0.1, 1.0 },
		{ 0.3, 1.0, 0.0, 1.0 },
		{ 0.3, 1.0, 1.0, 1.0 },
		{ 0.1, 0.3, 1.0, 1.0 },
		{ 0.0, 0.0, 0.4, 1.0 },
	},
	Heat = {
		{ 0.0, 1.0, 1.0, 1.0 },
		{ 0.7, 1.0, 1.0, 1.0 },
		{ 0.0, 0.9, 0.5, 1.0 },
		{ 1.0, 1.0, 0.4, 1.0 },
		{ 1.0, 0.4, 0.0, 1.0 },
		{ 0.9, 0.0, 0.0, 1.0 },
	},
	Biome = {
		{ 1.0, 1.0, 1.0, 1.0 },
		{ 0.4, 0.5, 0.5, 1.0 },
		{ 0.6, 0.9, 0.4, 1.0 },
		{ 0.9, 0.9, 0.5, 1.0 },
		{ 0.5, 0.7, 0.4, 1.0 },
		{ 0.7, 0.8, 0.4, 1.0 },
		{ 0.4, 0.5, 0.2, 1.0 },
		{ 0.3, 0.5, 0.1, 1.0 },
		{ 0.3, 0.9, 0.1, 1.0 },
		{ 0.1, 0.3, 0.2, 1.0 },
		{ 0.1, 0.1, 0.6, 1.0 },
		{ 0.0, 0.0, 0.5, 1.0 },
	},
}

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function generate()
	isBusy = true

	tileMap = Generator.generate(SIZE)

	isBusy = false
end

local function render() 
	isBusy = true

	if tileMapType == 0 then
		title = 'height value'
	elseif tileMapType == 1 then
		title = 'height type'
	elseif tileMapType == 2 then
		title = 'moisture type'
	elseif tileMapType == 3 then
		title = 'heat type'
	elseif tileMapType == 4 then
		title = 'biome type'
	end

	local adjFlagsFunc = function() return genesis.EqualityFlags.EQ_ALL end
	local colorFunc = function(tile)
		local value = genesis.getHeightValue(tile) 
		return { value / 255, value / 255, value / 255, 1.0 } 
	end

	if tileMapType == 1 then
		adjFlagsFunc = genesis.getAdjHeightFlags
		colorFunc = function(tile) return Colors.Height[genesis.getHeightType(tile)] end
	elseif tileMapType == 2 then
		adjFlagsFunc = genesis.getAdjHeightFlags
		colorFunc = function(tile) return Colors.Moisture[genesis.getMoistureType(tile)] end
	elseif tileMapType == 3 then
		adjFlagsFunc = genesis.getAdjHeightFlags
		colorFunc = function(tile) return Colors.Heat[genesis.getHeatType(tile)] end
	elseif tileMapType == 4 then
		adjFlagsFunc = genesis.getAdjBiomeFlags	
		colorFunc = function(tile) return Colors.Biome[genesis.getBiomeType(tile)] end
	end

	for face = 1, 6 do
		local canvas = love.graphics.newCanvas(SIZE, SIZE)		
		canvas:renderTo(function()
			for x = 1, SIZE do
				for y = 1, SIZE do
					local tile = tileMap[face][x][y]
					local color = colorFunc(tile)

					-- draw border at biome or height type edges
					if adjFlagsFunc(tile) ~= genesis.EqualityFlags.EQ_ALL then
						color = {
							lerp(color[1], 0.0, 0.4),
							lerp(color[2], 0.0, 0.4),
							lerp(color[3], 0.0, 0.4),
							1.0,
						}
					end

					love.graphics.setColor(unpack(color))
					love.graphics.points(x - 0.5, y - 0.5)
				end
			end
		end)
		textures[face] = canvas
	end

	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

	isBusy = false
end

local function toggle()
	tileMapType = (tileMapType + 1) % 5
end

function love.load(args)
	generate()
	render()
end

function love.keyreleased(key)
	if key == 'g' and not isBusy then
		generate()
		render()
	end

	if key == 't' and not isBusy then
		toggle()
		render()
	end

	if key == "escape" then
		love.event.quit()
	end
end

function love.draw()
	if isBusy then return end

	love.graphics.print(title, 10, 10)

	love.graphics.push()
	love.graphics.scale(1)
	for face = 1, 6 do
		local ox, oy = unpack(FaceOffsets[face])
		love.graphics.draw(textures[face], ox * SIZE, oy * SIZE)
	end
	love.graphics.pop()
end
