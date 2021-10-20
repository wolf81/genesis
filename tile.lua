local Tile = {}
Tile.__index = Tile

local function getTerrainType(value)
	if value >= 0.9 then return 1 -- snow
	elseif value >= 0.8 then return 2 -- mountain
	elseif value >= 0.7 then return 3 -- forest
	elseif value >= 0.62 then return 4 -- grass
	elseif value >= 0.6 then return 5 -- beach
	elseif value >= 0.3 then return 6 -- shallow ocean
	else return 7 -- deep ocean
	end	
end 

function Tile:new(face, x, y, value)
	local value = value or 0.0
	
	local instance = setmetatable({
		_position = { face, x, y },
		_value = value,
		-- neighbour tiles
		_left = nil,
		_right = nil,
		_top = nil,
		_bottom = nil,
		_terrainType = getTerrainType(value),
		_bitmask = 0,
	}, Tile)	

	return instance
end

function Tile:getTerrainType()
	return self._terrainType
end

function Tile:getValue()
	return self._value
end

function Tile:setLeft(t)
	self._left = t
end

function Tile:getLeft()
	return self._left
end

function Tile:setRight(t)
	self._right = t
end

function Tile:getRight()
	return self._right
end

function Tile:setTop(t)
	self._top = t
end

function Tile:getTop()
	return self._top
end

function Tile:setBottom(t)
	self._bottom = t
end

function Tile:getBottom()
	return self._bottom
end

function Tile:getPosition()
	return unpack(self._position)
end

function Tile:getBitmask()
	return self._bitmask
end

function Tile:updateBitmask()
	local count = 0

	if self:getTop():getTerrainType() == self:getTerrainType() then
		count = count + 1		
	end

	if self:getLeft():getTerrainType() == self:getTerrainType() then
		count = count + 2		
	end

	if self:getRight():getTerrainType() == self:getTerrainType() then
		count = count + 4		
	end

	if self:getBottom():getTerrainType() == self:getTerrainType() then
		count = count + 8
	end

	self._bitmask = count
end

return setmetatable(Tile, {
	__call = Tile.new
})
