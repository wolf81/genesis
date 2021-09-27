local Terrain = {}
Terrain.__index = Terrain

local function average(values)
	local total = 0
	local n = 0
	for _, v in ipairs(values) do
		if v ~= -1 then
			total = total + v
			n = n + 1
		end
	end

	return total / n
end

function Terrain:new(detail)
	print('new')

	-- only works properly when detail is power of 2

	local size = detail ^ 2 + 1
	print('size', size)
	local max = size - 1

	local map = {}
	for i = 0, size * size do
		map[i] = 0
	end

	return setmetatable({
		_size = size,
		_max = max,
		_map = map,
	}, Terrain)
end

function Terrain:getSize()
	return self._size
end

function Terrain:getValue(x, y)
	if x < 0 or x > self._max or y < 0 or y > self._max then 
		return -1 
	end

	return self._map[x + self._size * y + 1]
end

function Terrain:setValue(x, y, value)
	self._map[x + self._size * y + 1] = value
end

function Terrain:square(x, y, size, offset)
	local avg = average({
		self:getValue(x - size, y - size),
		self:getValue(x + size, y - size),
		self:getValue(x + size, y + size),
		self:getValue(x - size, y + size),
	})
	self:setValue(x, y, avg + offset)
end

function Terrain:diamond(x, y, size, offset)
	local avg = average({
		self:getValue(x, y - size),
		self:getValue(x + size, y),
		self:getValue(x, y + size),
		self:getValue(x - size, y),
	})
	self:setValue(x, y, avg + offset)
end

function Terrain:generate(roughness)
	local roughness = roughness or 0.5

	self:setValue(0, 0, self._max)
	self:setValue(self._max, 0, self._max / 2)
	self:setValue(self._max, self._max, 0)
	self:setValue(0, self._max, self._max / 2)

	function divide(size)
		local half = bit.rshift(size, 1)
		local scale = roughness * size
		if half < 1 then return end

		for y = half, self._max, size do
			for x = half, self._max, size do
				self:square(x, y, half, math.random(scale * 2 - scale))
			end
		end

		for y = 0, self._max, half do
			for x = (y + half) % size, self._max, size do
				self:diamond(x, y, half, math.random(scale * 2 - scale))
			end
		end

		divide(half)
	end

	divide(self._max)
end

function Terrain:__tostring()
	local s = ''

	for i, v in ipairs(self._map) do
		s = s .. '\t' .. string.format("%.2f", v)

		if i % self._size == 0 then
			s = s .. '\n'
		end
	end

	return s
end

return setmetatable(Terrain, {
	__call = Terrain.new 
})