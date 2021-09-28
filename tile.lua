local Tile = {}
Tile.__index = Tile

function Tile:new(x, y, heightValue, heightType, collidable)
	return setmetatable({
		_heightValue = heightValue,
		_heightType = heightType,
		_isCollidable = collidable,
		_isFloodFilled = false,
		_coord = { x, y },
	}, Tile)
end

function Tile:isCollidable()
	return self._isCollidable
end

function Tile:isFloodFilled()
	return self._isFloodFilled
end

function Tile:floodFill()
	self._isFloodFilled = true
end

function Tile:setTopTile(tile)
	self._topTile = tile
end

function Tile:setBottomTile(tile)
	self._bottomTile = tile
end

function Tile:setLeftTile(tile)
	self._leftTile = tile
end

function Tile:setRightTile(tile)
	self._rightTile = tile
end

function Tile:getTopTile()
	return self._topTile
end

function Tile:getBottomTile()
	return self._bottomTile
end

function Tile:getLeftTile()
	return self._leftTile
end

function Tile:getRightTile()
	return self._rightTile
end

function Tile:getCoord()
	return unpack(self._coord)
end

function Tile:getHeightValue()
	return self._heightValue
end

function Tile:setHeightType(heightType)
	self._heightType = heightType
end

function Tile:getHeightType()
	return self._heightType
end

function Tile:getBitmask()
	return self._bitmask
end

function Tile:updateBitmask()
	local count = 0	
	
	if self._topTile:getHeightType() == self._heightType then
		count = count + 1
	end

	if self._rightTile:getHeightType() == self._heightType then
		count = count + 2
	end

	if self._bottomTile:getHeightType() == self._heightType then
		count = count + 4
	end

	if self._leftTile:getHeightType() == self._heightType then
		count = count + 8
	end

	self._bitmask = count
end

return setmetatable(Tile, {
	__call = Tile.new
})