local Map = {}
Map.__index = Map

function Map:new(size)
	print('new map')

	local size = size or 5
	local values = {}

	return setmetatable({
		_size = size,
		_values = values,
	}, Map)
end

function Map:clear()
	for y = 1, self._size do
		self._values[y] = {}
		for x = 1, self._size do
			self._values[y][x] = -1
		end
	end
end

function Map:setValue(x, y, value)
	if not self:isValidPosition(x, y) then
		error('position outside of valid range')
	end
	
	print('set', x, y, value)

	self._values[y][x] = value
end

function Map:getValue(x, y)	
	if not self:isValidPosition(x, y) then
		error('position outside of valid range')
	end

	return self._values[y][x]
end

function Map:isValidPosition(x, y)
	return x > 0 and x <= self._size and y > 0 and y <= self._size
end

function Map:getSize()
	return self._size
end

function Map:__tostring()
	local s = ''
	for _, values in ipairs(self._values) do
		for _, value in ipairs(values) do
			s = s .. '\t' .. string.format("%.2f", value)
		end
		s = s .. '\n'
	end

	return s
end

return setmetatable(Map, {
	__call = Map.new
})