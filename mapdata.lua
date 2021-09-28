local MapData = {}
MapData.__index = MapData

function MapData:new(width, height)
	print('new')

	local data = {}
	for y = 0, height - 1 do
		data[y] = {}
		for x = 0, width - 1 do
			data[y][x] = 0
		end
	end

	return setmetatable({
		_data = data,
		_min = 0,
		_max = 0,
	}, MapData)
end

function MapData:setValue(x, y, value)
	self._max = math.max(self._max, value)
	self._min = math.min(self._min, value)	
	self._data[y][x] = value
end

function MapData:getValue(x, y)
	return self._data[y][x]
end

function MapData:getNormalizedValue(x, y)
	local value = self._data[y][x]
	return (value - self._min) / (self._max - self._min)
end

return setmetatable(MapData, {
	__call = MapData.new
})