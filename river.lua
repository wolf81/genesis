local River = {}
River.__index = River

function River:new(id)
	return setmetatable({
		_id = id,
		_currentDirection = nil,
		_tiles = {},
		_turns = 0,
		_length = 0,
		_intersections = 0,
	}, River)
end

function River:getId()
	return self._id
end

function River:setLength(n)
	self._length = n
end

function River:getLength()
	return self._length
end

function River:setCurrentDirection(direction)
	self._currentDirection = direction
end

function River:getCurrentDirection()
	return self._currentDirection
end

function River:incrementIntersections()
	self._intersections = self._intersections + 1
end

function River:incrementTurns()
	self._turns = self._turns + 1
end

function River:getIntersections()
	return self._intersections
end

function River:getTurns()
	return self._turns
end

function River:containsTile(tile)
	for _, t in ipairs(self._tiles) do
		if t == tile then return true end
	end

	return false
end

function River:getTiles()
	return self._tiles
end

function River:addTile(tile)
	tile:setRiverPath(self)
	self._tiles[#self._tiles + 1] = tile
end

return setmetatable(River, {
	__call = River.new
})
