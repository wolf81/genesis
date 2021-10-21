local bbor = bit.bor

local Tile = {}
Tile.__index = Tile

Tile.MASK_EQ_TOP = bit.lshift(1, 0)
Tile.MASK_EQ_LEFT = bit.lshift(1, 1)
Tile.MASK_EQ_RIGHT = bit.lshift(1, 2)
Tile.MASK_EQ_BOTTOM = bit.lshift(1, 3)
Tile.MASK_EQ_ALL = bit.bor(
	Tile.MASK_EQ_TOP, 
	Tile.MASK_EQ_LEFT, 
	Tile.MASK_EQ_RIGHT, 
	Tile.MASK_EQ_BOTTOM
)

function Tile:new(face, x, y, heightValue, heatValue, moistureValue)	
	return setmetatable({
		_position = { face, x, y },
		-- values
		_heightValue = heightValue or 0.0,
		_heatValue = heatValue or 0.0,
		_moistureValue = moistureValue or 0.0,
		-- adjacent tiles
		_left = nil,
		_right = nil,
		_top = nil,
		_bottom = nil,
		-- tile info
		_heightType = 0,
		_heatType = 0,
		_moistureType = 0,
		_bitmask = 0,
	}, Tile)	
end

function Tile:getHeatType()
	return self._heatType
end

function Tile:setHeatType(v)
	self._heatType = v
end

function Tile:getHeightType()
	return self._heightType
end

function Tile:setHeightType(v)
	self._heightType = v
end

function Tile:getMoistureType()
	return self._moistureType
end

function Tile:setMoistureType(v)
	self._moistureType = v
end

function Tile:getHeightValue()
	return self._heightValue
end

function Tile:getHeatValue()
	return self._heatValue
end

function Tile:setHeatValue(v)
	self._heatValue = v
end

function Tile:getMoistureValue()
	return self._moistureValue
end

function Tile:setMoistureValue(v)
	self._moistureValue = v
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
	local bitmask = 0

	if self:getTop():getHeightType() == self._heightType then
		bitmask = bbor(bitmask, Tile.MASK_EQ_TOP)
	end

	if self:getLeft():getHeightType() == self._heightType then
		bitmask = bbor(bitmask, Tile.MASK_EQ_LEFT)
	end

	if self:getRight():getHeightType() == self._heightType then
		bitmask = bbor(bitmask, Tile.MASK_EQ_RIGHT)
	end

	if self:getBottom():getHeightType() == self._heightType then
		bitmask = bbor(bitmask, Tile.MASK_EQ_BOTTOM)
	end

	self._bitmask = bitmask
end

return setmetatable(Tile, {
	__call = Tile.new
})
