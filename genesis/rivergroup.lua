local RiverGroup = {}
RiverGroup.__index = RiverGroup

function RiverGroup:new()
	return setmetatable({
		_rivers = {}
	}, RiverGroup)
end

function RiverGroup:getRivers()
	return self._rivers
end

function RiverGroup:getRiver(idx)
	return self.__index[idx]
end

function RiverGroup:containsRiver(river)
	for _, r in ipairs(self._rivers) do
		if r == river then return true end
	end

	return false
end

function RiverGroup:addRiver(river)
	table.insert(self._rivers, river)
end

return setmetatable(RiverGroup, {
	__call = RiverGroup.new
})
