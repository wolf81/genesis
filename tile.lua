require 'constants'

local bbor = bit.bor

local Tile = {}
Tile.__index = Tile

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
		_flags = 0,
		_floodFilled = false,
		_collidable = false,
		_rivers = {},
		_riverSize = 0,

		_biomeType = nil,
	}, Tile)	
end

function Tile:getBiomeType()
	return self._biomeType
end

function Tile:setBiomeType(t)
	self._biomeType = t
end

function Tile:getLowestNeighbourDirection()
	local lhv = self._left:getHeightValue()
	local rhv = self._right:getHeightValue()
	local thv = self._top:getHeightValue()
	local bhv = self._bottom:getHeightValue()

	if lhv < rhv and lhv < thv and lhv < bhv then
		return Direction.LEFT
	elseif rhv < lhv and rhv < thv and lhv < bhv then
		return Direction.TOP
	elseif thv < lhv and thv < rhv and thv < bhv then
		return Direction.RIGHT
	elseif bhv < lhv and bhv < thv and bhv < rhv then
		return Direction.BOTTOM -- or RIGHT?
	end

	return Direction.BOTTOM
end

function Tile:getRiverSize()
	return self._riverSize
end

function Tile:digRiver(river, size)
	self:setRiverTile(self, river)
	self._riverSize = size

	if size == 1 then
		self._bottom:setRiverTile(river)
		self._right:setRiverTile(river)
		self._bottom:getRight():setRiverTile(river)
	elseif size == 2 then
		self._bottom:setRiverTile(river)
		self._right:setRiverTile(river)
		self._bottom:getRight():setRiverTile(river)
		self._top:setRiverTile(river)
		self._top:getLeft():setRiverTile(river)
		self._left:setRiverTile(river)
		self._left:getBottom():setRiverTile(river)
	elseif size == 3 then
		self._bottom:setRiverTile(river)
		self._right:setRiverTile(river)
		self._bottom:getRight():setRiverTile(river)
		self._top:setRiverTile(river)
		self._top:getLeft():setRiverTile(river)
		self._left:setRiverTile(river)
		self._left:getBottom():setRiverTile(river)
		self._right:getRight():setRiverTile(river)
		self._right:getRight():getBottom():setRiverTile(river)
		self._bottom:getBottom():setRiverTile(river)
		self._bottom:getBottom():getRight():setRiverTile(river)
	elseif size == 4 then
		self._bottom:setRiverTile(river)
		self._right:setRiverTile(river)
		self._bottom:getRight():setRiverTile(river)
		self._top:setRiverTile(river)
		self._top:getLeft():setRiverTile(river)
		self._left:setRiverTile(river)
		self._left:getBottom():setRiverTile(river)
		self._right:getRight():setRiverTile(river)
		self._right:getRight():getBottom():setRiverTile(river)
		self._bottom:getBottom():setRiverTile(river)
		self._bottom:getBottom():getRight():setRiverTile(river)
		self._left:getBottom():getBottom():setRiverTile(river)
		self._left:getLeft():getBottom():setRiverTile(river)
		self._left:getLeft():setRiverTile(river)
		self._left:getLeft():getTop():setRiverTile(river)
		self._left:getTop():setRiverTile(river)
		self._left:getTop():getTop():setRiverTile(river)
		self._top:getTop():setRiverTile(river)
		self._top:getTop():getRight():setRiverTile(river)
		self._top:getRight():getRight():setRiverTile(river)
	end
end

function Tile:setRiverTile(river)
	self:setRiverPath(river)

	self._heightType = HeightType.RIVER
	self._heightValue = 0
	self._collidable = false
end

function Tile:removeRiver(river)
	for i, r in ipairs(self._rivers) do
		if r == river then
			table.remove(self._rivers, i)
			break
		end
	end
end

function Tile:containsRiver(river)
	for _, r in ipairs(self._rivers) do
		if r == river then return true end
	end

	return false
end

function Tile:getRivers()
	return self._rivers
end

function Tile:getRiverNeighbourCount(river)
	local count = 0

	if #self._top:getRivers() > 0 and self._top:containsRiver(river) then
		count = count + 1
	end

	if #self._left:getRivers() > 0 and self._left:containsRiver(river) then
		count = count + 1
	end

	if #self._right:getRivers() > 0 and self._right:containsRiver(river) then
		count = count + 1
	end

	if #self._bottom:getRivers() > 0 and self._bottom:containsRiver(river) then
		count = count + 1
	end

	return count
end

function Tile:addRiver(river)
	table.insert(self._rivers, river)
end

function Tile:setRiverPath(river)
	if not self._collidable then return end

	if not self:containsRiver(river) then
		table.insert(self._rivers, river)		
	end
end

function Tile:isCollidable()
	return self._collidable
end

function Tile:setCollidable(v)
	self._collidable = v
end

function Tile:isFloodFilled()
	return self._floodFilled
end

function Tile:floodFill()
	self._floodFilled = true
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

function Tile:setHeightValue(v)
	self._heightValue = v
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

function Tile:getFlags()
	return self._flags
end

function Tile:updateHeightFlags()
	local flags = self._flags

	if self:getTop():getHeightType() == self._heightType then
		flags = bbor(flags, TileFlags.EQ_HEIGHT_TOP)
	end

	if self:getLeft():getHeightType() == self._heightType then
		flags = bbor(flags, TileFlags.EQ_HEIGHT_LEFT)
	end

	if self:getRight():getHeightType() == self._heightType then
		flags = bbor(flags, TileFlags.EQ_HEIGHT_RIGHT)
	end

	if self:getBottom():getHeightType() == self._heightType then
		flags = bbor(flags, TileFlags.EQ_HEIGHT_BOTTOM)
	end

	self._flags = flags
end

function Tile:updateBiomeFlags()
	local flags = self._flags

	if self:getTop():getBiomeType() == self._biomeType then
		flags = bbor(flags, TileFlags.EQ_BIOME_TOP)
	end

	if self:getLeft():getBiomeType() == self._biomeType then
		flags = bbor(flags, TileFlags.EQ_BIOME_LEFT)
	end

	if self:getRight():getBiomeType() == self._biomeType then
		flags = bbor(flags, TileFlags.EQ_BIOME_RIGHT)
	end

	if self:getBottom():getBiomeType() == self._biomeType then
		flags = bbor(flags, TileFlags.EQ_BIOME_BOTTOM)
	end

	self._flags = flags
end

return setmetatable(Tile, {
	__call = Tile.new
})
