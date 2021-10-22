require 'constants'

local TileGroup = {}
TileGroup.__index = TileGroup

function TileGroup:new(type)
	return setmetatable({
		_tiles = {},
		_type = type or 0, 
	}, TileGroup)
end

function TileGroup:getTileCount()
	return #self._tiles
end

function TileGroup:getTiles()
	return self._tiles
end

function TileGroup:getType()
	return self._type
end

function TileGroup:addTile(tile)
	self._tiles[#self._tiles + 1] = tile
end

return setmetatable(TileGroup, {
	__call = TileGroup.new
})