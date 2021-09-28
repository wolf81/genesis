local TileGroup = {}
TileGroup.__index = TileGroup

function TileGroup:new(type)
	return setmetatable({
		_tiles = {},
		_type = type,
	}, TileGroup)
end

function TileGroup:add(tile)
	self._tiles[#self._tiles + 1] = tile
end

function TileGroup:getType()
	return self._type
end

function TileGroup:getTiles()
	return self._tiles
end

function TileGroup:getSize()
	return #self._tiles
end

return setmetatable(TileGroup, {
	__call = TileGroup.new
})