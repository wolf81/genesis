local Tile = {}
Tile.__index = Tile

function Tile:new(x, y)
	return setmetatable({
		_heightValue = 0,
		_heatValue = 0,
		_moistureValue = 0,
		_isFloodFilled = false,
		_isCollidable = true,
		_coord = { x, y },
	}, Tile)
end

function Tile:setCollidable(collidable)
	self._isCollidable = collidable
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

function Tile:getTopTile()
	return self._topTile
end

function Tile:setTopTile(tile)
	self._topTile = tile
end

function Tile:getBottomTile()
	return self._bottomTile
end

function Tile:setBottomTile(tile)
	self._bottomTile = tile
end

function Tile:getLeftTile()
	return self._leftTile
end

function Tile:setLeftTile(tile)
	self._leftTile = tile
end

function Tile:getRightTile()
	return self._rightTile
end

function Tile:setRightTile(tile)
	self._rightTile = tile
end

function Tile:getCoord()
	return unpack(self._coord)
end

function Tile:getHeightValue()
	return self._heightValue
end

function Tile:setHeightValue(value)
	self._heightValue = math.min(math.max(value, 0.0), 1.0)
end

function Tile:getHeatValue()
	return self._heatValue
end

function Tile:setHeatValue(value)
	self._heatValue = math.min(math.max(value, 0.0), 1.0)
end

function Tile:getMoistureValue()
	return self._moistureValue
end

function Tile:setMoistureValue(value)
	self._moistureValue = math.min(math.max(value, 0.0), 1.0)
end

function Tile:getTerrainType()
	return self._terraintType
end

function Tile:setTerrainType(terrainType)
	self._terraintType = terrainType
end

function Tile:getHeatType()
	return self._heatType
end

function Tile:setHeatType(heatType)
	self._heatType = heatType
end

function Tile:getBitmask()
	return self._bitmask
end

function Tile:updateBitmask()
	local count = 0	

	local terrainType = self:getTerrainType()
	
	if self._topTile:getTerrainType() == terrainType then
		count = count + 1
	end

	if self._rightTile:getTerrainType() == terrainType then
		count = count + 2
	end

	if self._bottomTile:getTerrainType() == terrainType then
		count = count + 4
	end

	if self._leftTile:getTerrainType() == terrainType then
		count = count + 8
	end

	self._bitmask = count
end

return setmetatable(Tile, {
	__call = Tile.new
})