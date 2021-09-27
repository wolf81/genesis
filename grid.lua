local Grid = {}
Grid.__index = Grid

local function clear(values, size)
	for y = 0, size - 1 do
		values[y] = {}
		for x = 0, size - 1 do
			values[y][x] = 0/0
		end
	end

	return values
end

function Grid:smooth()
	local possibleIndexes = {
		{ x = -1, y = -1 },
		{ x = -1, y = 0  },
		{ x = -1, y = 1  },
		{ x = 0,  y = -1 },
		{ x = 0,  y = 0  },
		{ x = 0,  y = 1  },
		{ x = 1,  y = -1 },
		{ x = 1,  y = 0  },
		{ x = 1,  y = 1  },
	}

	for x = 0, self._size - 1 do
		for y = 0, self._size - 1 do
			local sum = 0
			local count = 0

			for _, index in ipairs(possibleIndexes) do
				if self:isInGrid(x + index.x, y + index.y) then
					sum = sum + self:getValue(x + index.x, y + index.y)
					count = count + 1				
				end
			end

			self:setValue(x, y, sum / count)
		end
	end
end

function Grid:new(size)
	local size = size or 3
	local values = clear({}, size)

	return setmetatable({
		_size = size,
		_values = values,
	}, Grid)
end

function Grid:getValue(x, y)
	if not self:isInGrid(x, y) then
		error('coordinates outside of grid:', x, y)
	end

	return self._values[y][x]
end

function Grid:setValue(x, y, value)
	if not self:isInGrid(x, y) then
		error('coordinates outside of grid:', x, y)
	end

	self._values[y][x] = value
end

function Grid:getSize()
	return self._size
end

function Grid:clear()
	clear(self._values, self._size)
end

function Grid:isInGrid(x, y)
	return x >= 0 and x < self._size and y >= 0 and y < self._size
end

function Grid:__tostring()
	local s = ''

	for y = 0, self._size - 1 do
		for x = 0, self._size - 1 do
			local v = self._values[y][x]
			s = s .. string.format('%.2f', v) .. '\t'
		end
		s = s .. '\n'
	end

	return s
end

return setmetatable(Grid, {
	__call = Grid.new
})