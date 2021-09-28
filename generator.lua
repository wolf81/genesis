local MapData = require 'mapdata'
local TextureGen = require 'texturegen'
local Tile = require 'tile'
local TileGroup = require 'tilegroup'

local Generator = {}
Generator.__index = Generator

local function getLeftTile(self, x, y)
	local x = (x - 1) % self._width
	return self._tiles[y][x]
end

local function getRightTile(self, x, y)
	local x = (x + 1) % self._width
	return self._tiles[y][x]
end

local function getTopTile(self, x, y)
	local y = (y - 1) % self._height
	return self._tiles[y][x]
end

local function getBottomTile(self, x, y)
	local y = (y + 1) % self._height
	return self._tiles[y][x]
end

local function floodFill2(tile, tileGroup, stack)
	if tile:isFloodFilled() then
		return
	elseif tileGroup:getType() == 'land' and not tile:isCollidable() then
		return
	elseif TileGroup:getType() == 'water' and tile:isCollidable() then
		return
	end

	tileGroup:add(tile)
	tile:floodFill()

	local adjacentTiles = { 
		tile:getTopTile(), 
		tile:getBottomTile(),
		tile:getLeftTile(),
		tile:getRightTile(),
	}

	for _, adjacentTile in ipairs(adjacentTiles) do
		if not adjacentTile:isFloodFilled() and adjacentTile:isCollidable() == tile:isCollidable() then
		stack[#stack + 1] = adjacentTile		
		end
	end
end

local function floodFill(self)
	local stack = {}

	for y = 0, self._height - 1 do
		for x = 0, self._width - 1 do
			local tile = self._tiles[y][x]

			if not tile:isFloodFilled() then
				if tile:isCollidable() then
					local tileGroup = TileGroup('land')
					stack[#stack + 1] = tile

					while #stack > 0 do
						floodFill2(table.remove(stack), tileGroup, stack)
					end

					if tileGroup:getSize() > 0 then
						self._landTiles[#self._landTiles + 1] = tileGroup
					end
				else
					local tileGroup = TileGroup('water')
					stack[#stack + 1] = tile

					while #stack > 0 do
						floodFill2(table.remove(stack), tileGroup, stack)
					end

					if tileGroup:getSize() > 0 then
						self._waterTiles[#self._waterTiles + 1] = tileGroup
					end					
				end
			end
		end
	end
end

--[[
local function updateBitmasks()
	for y = 0, self._height - 1 do
		for x = 0, self._width - 1 do
			local tile = self._tiles[y][x]
			tile:updateBitmask()
		end
	end
end
]]

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

function Generator:new(width, height)
	return setmetatable({
		_width = width,
		_height = height,
		_tiles = {},
		_waterTiles = {},
		_landTiles = {},
	}, Generator)
end

function Generator:getWidth()
	return self._width
end

function Generator:getHeight()
	return self._height
end

function Generator:getTiles()
	return self._tiles
end

function Generator:getLandTiles()
	return self._landTiles
end

function Generator:getWaterTiles()
	return self._waterTiles
end

function Generator:generate()
	print('->', self._width, self._height)

	local mapData = generateMapData(self)

	self._tiles = {}
	for y = 0, self._height - 1 do
		self._tiles[y] = {}
		for x = 0, self._width - 1 do
			local heightValue = mapData:getNormalizedValue(x, y)			
			local heatValue = 1.0 - 2 * math.abs((y / self._height) - 0.5);

			local tile = Tile(x, y, heightValue, heatValue)
			local heightType = tile:getHeightType()
			if heightType == 'grass' then
				heatValue = heatValue - 0.1 * heightValue
			elseif heightType == 'forest' then
				heatValue = heatValue - 0.2 * heightValue
			elseif heightType == 'mountain' then
				heatValue = heatValue - 0.3 * heightValue
			elseif heightType == 'snow' then
				heatValue = heatValue - 0.4 * heightValue				
			end
			tile:setHeatValue(heatValue)
			
			self._tiles[y][x] = tile
		end
	end

	for y = 0, self._height - 1 do
		for x = 0, self._width - 1 do
			local tile = self._tiles[y][x]
			tile:setTopTile(getTopTile(self, x, y))
			tile:setBottomTile(getBottomTile(self, x, y))
			tile:setLeftTile(getLeftTile(self, x, y))
			tile:setRightTile(getRightTile(self, x, y))
			tile:updateBitmask()
		end
	end

	floodFill(self)
end

return setmetatable(Generator, {
	__call = Generator.new
})