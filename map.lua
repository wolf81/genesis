local Map = {}
Map.__index = Map

Map.normalize = function(values, vmin, vmax)
	for face = 1, 6 do
		for x = 0, #values[face] - 1 do
			for y = 0, #values[face] - 1 do
				local v = values[face][x][y]
				values[face][x][y] = (v - vmin) / (vmax - vmin)
			end
		end		
	end

	return values
end

function Map:new(values)	
	return setmetatable({
		_size = #values[1],
		_values = values,
	}, Map)
end

function Map:getSize()
	return self._size, self._size
end

function Map:getValue(face, x, y)
	return self._values[face][x][y]
end

return setmetatable(Map, {
	__call = Map.new
})