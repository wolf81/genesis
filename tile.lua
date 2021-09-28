local Tile = {}
Tile.__index = Tile

function Tile:new(x, y, heightValue)
	return setmetatable({
		_heightValue = heightValue,
		_coord = { x, y },
	}, Tile)
end

function Tile:getCoord()
	return unpack(self._coord)
end

function Tile:getHeightValue()
	return self._heightValue
end

return setmetatable(Tile, {
	__call = Tile.new
})