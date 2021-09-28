local Tile = {}
Tile.__index = Tile

function Tile:new(x, y, heightValue, heatValue)
	return setmetatable({
		_heightValue = heightValue,
		_heatValue = heatValue,
		_isFloodFilled = false,
		_coord = { x, y },
	}, Tile)
end

function Tile:isCollidable()
	local heightType = self:getHeightType()
	return (
		heightType ~= 'deepWater' and 
		heightType ~= 'shallowWater'
	)
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

function Tile:getHeatValue()
	return self._heatValue
end

function Tile:setHeatValue(heatValue)
	self._heatValue = heatValue
end

function Tile:getHeightType()
	if self._heightValue < 0.35 then return 'deepWater', false
	elseif self._heightValue < 0.55 then return 'shallowWater', false
	elseif self._heightValue < 0.6 then return 'sand', true
	elseif self._heightValue < 0.7 then return 'grass', true
	elseif self._heightValue < 0.8 then return 'forest', true
	elseif self._heightValue < 0.9 then return 'mountain', true
	else return 'snow', true
	end
end

function Tile:getHeatType()
	if self._heatValue < 0.15 then return 'coldest'
	elseif self._heatValue < 0.30 then return 'colder'
	elseif self._heatValue < 0.45 then return 'cold'
	elseif self._heatValue < 0.60 then return 'warm'
	elseif self._heatValue < 0.75 then return 'warmer'
	else return 'warmest' end
end

function Tile:getBitmask()
	return self._bitmask
end

function Tile:updateBitmask()
	local count = 0	

	local heightType = self:getHeightType()
	
	if self._topTile:getHeightType() == heightType then
		count = count + 1
	end

	if self._rightTile:getHeightType() == heightType then
		count = count + 2
	end

	if self._bottomTile:getHeightType() == heightType then
		count = count + 4
	end

	if self._leftTile:getHeightType() == heightType then
		count = count + 8
	end

	self._bitmask = count
end

return setmetatable(Tile, {
	__call = Tile.new
})