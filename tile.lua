local Tile = {}
Tile.__index = Tile

function Tile:new(face, x, y, value)
	return setmetatable({
		_position = { face, x, y },
		_value = value or 0.0,
	}, Tile)	
end

function Tile:getValue()
	return self._value
end

function Tile:getPosition()
	return unpack(self._position)
end

return setmetatable(Tile, {
	__call = Tile.new
})
