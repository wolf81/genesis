local MapData = require 'mapdata'
local TextureGen = require 'texturegen'
local Tile = require 'tile'

local HeightMap = {}
HeightMap.__index = HeightMap

local function generateMapData(self)
	local mapData = MapData(self._width, self._height)

	local r = math.random() * 256
	
	for y = 0, self._height - 1 do
		for x = 0, self._width - 1 do
			local x1 = 0
			local x2 = 5
			local y1 = 0
			local y2 = 5
			local dx = x2 - x1
			local dy = y2 - y1

			local s = x / self._width
			local t = y / self._height

			local nx = x1 + math.cos(s * 2 * math.pi) * dx / (2 * math.pi) + r
			local ny = y1 + math.cos(t * 2 * math.pi) * dy / (2 * math.pi) + r
			local nz = x1 + math.sin(s * 2 * math.pi) * dx / (2 * math.pi) + r
			local nw = y1 + math.sin(t * 2 * math.pi) * dy / (2 * math.pi) + r


			-- octaves ?
			local u1 = love.math.noise(nx, ny, nz, nw)
			local u2 = love.math.noise(nx * 2, ny * 2, nz * 2, nw * 2)
			local u3 = love.math.noise(nx * 4, ny * 4, nz * 4, nw * 4)
			local u4 = love.math.noise(nx * 8, ny * 8, nz * 8, nw * 8)
			local u5 = love.math.noise(nx * 16, ny * 16, nz * 16, nw * 16)
			--local u6 = love.math.noise(xx * 32, yy * 32, zz * 32)
			local u = u1 + u2 / 2 + u3 / 4 + u4 / 8 + u5 / 16 -- + u6 / 32

			local f = 1.25 -- frequency?

			mapData:setValue(x, y, u / f)
		end
	end

	return mapData
end

function HeightMap:new(width, height)
	return setmetatable({
		_width = width,
		_height = height,
	}, HeightMap)
end

function HeightMap:generate()
	print(self._width, self._height)

	local mapData = generateMapData(self)

	local tiles = {}
	for y = 0, self._height - 1 do
		tiles[y] = {}
		for x = 0, self._width - 1 do
			local heightValue = mapData:getNormalizedValue(x, y)
			local tile = Tile(x, y, heightValue)
			tiles[y][x] = tile
		end
	end

	local texture = TextureGen(self._width, self._height, tiles):generate()

	return texture
end

return setmetatable(HeightMap, {
	__call = HeightMap.new
})