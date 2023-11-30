-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

local genesis = require 'genesis'
local cubeMapHelper = require 'genesis.cubemaphelper'
local EqualityFlags = require 'genesis.equalityflags'

local SIZE = 200

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

local didTileMapChange = true

local HeightColors = {
	{ 0, 0, 0.5, 1 },
	{ 25/255, 25/255, 150/255, 1 },
	{ 240 / 255, 240 / 255, 64 / 255, 1 },
	{ 50 / 255, 220 / 255, 20 / 255, 1 },
	{ 16 / 255, 160 / 255, 0, 1 },
	{ 0.5, 0.5, 0.5, 1 },            
	{ 1, 1, 1, 1 },
}

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

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function generate()
	tileMap = genesis.generate(SIZE)
end

local function render() 
	isRendering = true

	if didTileMapChange then
		if tileMapType == 0 then
			print('height')
		elseif tileMapType == 1 then
			print('moisture')
		elseif tileMapType == 2 then
			print('heat')
		elseif tileMapType == 3 then
			print('biome')
		end
		didTileMapChange = false					
	end

	local valueFunc = genesis.getHeightType
	local flagsFunc = genesis.getHeightAdjFlags
	local colorTable = HeightColors

	if tileMapType == 1 then
		valueFunc = genesis.getMoistureValue
		colorTable = MoistureColors
	elseif tileMapType == 2 then
		valueFunc = genesis.getHeatValue
		colorTable = HeatColors
	elseif tileMapType == 3 then
		valueFunc = genesis.getBiomeType
		flagsFunc = genesis.getBiomeAdjFlags	
		colorTable = BiomeColors
	end

	for face = 1, 6 do
		local canvas = love.graphics.newCanvas(SIZE, SIZE)		
		canvas:renderTo(function()
			for x = 1, SIZE do
				for y = 1, SIZE do
					local tile = tileMap[face][x][y]
					local color = colorTable[valueFunc(tile)]

					-- draw border at biome or height type edges
					if flagsFunc(tile) ~= EqualityFlags.EQ_ALL then
						color = {
							lerp(color[1], 0.0, 0.35),
							lerp(color[2], 0.0, 0.35),
							lerp(color[3], 0.0, 0.35),
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

	isRendering = false
end

local function toggle()
	tileMapType = (tileMapType + 1) % 4
	didTileMapChange = true
	render()
end

function love.load(args)
	generate()
	render()
end

function love.keyreleased(key)
	if key == 'g' and not isRendering then
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
	love.graphics.scale(1)
	for face = 1, 6 do
		local ox, oy = unpack(FACE_OFFSETS[face])
		love.graphics.draw(textures[face], ox * SIZE, oy * SIZE)
	end
	love.graphics.pop()
end
