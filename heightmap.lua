local MapData = require 'mapdata'
local TextureGen = require 'texturegen'
local Tile = require 'tile'

local HeightMap = {}
HeightMap.__index = HeightMap

local function generateMapData(self)
	local mapData = MapData(self._width, self._height)
	
	local z = math.random()

	local maxr = 1
	local minr = 0.5
	local yrad = 2 * maxr - minr
	local ox = 200 * math.random() - 10
	local oy = 20 * math.random() - 10
	local oz = 20 * math.random() - 10

	for y = 0, self._height - 1 do
		local beta = 2 * y / self._height * math.pi

		for x = 0, self._width - 1 do
			local alpha = 2 * x / self._width * math.pi

			local x1 = x / self._width
			local y1 = y / self._height

			local yy = oy + yrad * math.sin(beta)
			local ur = maxr - minr * math.cos(beta)
			local xx = ox + ur * math.cos(alpha)
			local zz = oz + ur * math.sin(alpha)

			-- octaves ?
			local u1 = love.math.noise(xx, yy, zz)
			local u2 = love.math.noise(xx * 2, yy * 2, zz * 2)
			local u3 = love.math.noise(xx * 4, yy * 4, zz * 4)
			local u4 = love.math.noise(xx * 8, yy * 8, zz * 8)
			local u5 = love.math.noise(xx * 16, yy * 16, zz * 16)
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