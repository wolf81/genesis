local TerrainGen = {}
TerrainGen.__index = TerrainGen

local function getRandomValue(magnitude)
	return math.random() * magnitude - (magnitude / 2)
end

local function average(values)
	local total = 0
	local n = 0

	for _, v in ipairs(values) do
		total = total + v
		n = n + 1
	end

	return total / n
end

local function diamond(grid, scale)
	local steps = math.floor(grid:getSize() / (scale - 1))
	local magnitude = scale / grid:getSize()

	for y = 0, steps - 1 do
		for x = 0, steps - 1 do
			local maxLength = scale - 1
			local xCoord = x * maxLength
			local yCoord = y * maxLength

			local values = {
				grid:getValue(xCoord, yCoord),
				grid:getValue(xCoord + maxLength, yCoord),
				grid:getValue(xCoord + maxLength, yCoord + maxLength),
				grid:getValue(xCoord, yCoord + maxLength),
			}

			local value = average(values) + getRandomValue(magnitude)
			local offset = bit.rshift(scale, 1)
			grid:setValue(xCoord + offset, yCoord + offset, value)
		end
	end
end

local function square(grid, scale)
	local steps = math.floor(grid:getSize() / (scale - 1))
	local magnitude = scale / grid:getSize()

	for y = 0, steps - 1 do
		for x = 0, steps - 1 do
			local maxLength = scale - 1
			local xCoord = x * maxLength
			local yCoord = y * maxLength
			local halfSize = bit.rshift(scale, 1)

			do
				local values = {
					grid:getValue(xCoord, yCoord),
					grid:getValue(xCoord + maxLength, yCoord),
					grid:getValue(xCoord + halfSize, yCoord + halfSize),
				}

				if grid:isInGrid(xCoord + halfSize, yCoord - halfSize) then
					values[#values + 1] = grid:getValue(xCoord + halfSize, yCoord - halfSize)
				end

				local value = average(values) + getRandomValue(magnitude)
				grid:setValue(xCoord + halfSize, yCoord, value)
			end

			do
				local values = {
					grid:getValue(xCoord, yCoord + maxLength),
					grid:getValue(xCoord + maxLength, yCoord + maxLength),
					grid:getValue(xCoord + halfSize, yCoord + halfSize),
				}

				if grid:isInGrid(xCoord + halfSize, yCoord + maxLength + halfSize) then
					values[#values + 1] = grid:getValue(xCoord + halfSize, yCoord + maxLength + halfSize)
				end

				local value = average(values) + getRandomValue(magnitude)
				grid:setValue(xCoord + halfSize, yCoord + maxLength, value)
			end

			do
				local values = {
					grid:getValue(xCoord, yCoord),
					grid:getValue(xCoord, yCoord + maxLength),
					grid:getValue(xCoord + halfSize, yCoord + halfSize),
				}

				if grid:isInGrid(xCoord - halfSize, yCoord + halfSize) then
					values[#values + 1] = grid:getValue(xCoord - halfSize, yCoord + halfSize)
				end

				local value = average(values) + getRandomValue(magnitude)
				grid:setValue(xCoord, yCoord + halfSize, value)
			end

			do
				local values = {
					grid:getValue(xCoord + maxLength, yCoord),
					grid:getValue(xCoord + maxLength, yCoord + maxLength),
					grid:getValue(xCoord + halfSize, yCoord + halfSize),
				}

				if grid:isInGrid(xCoord + maxLength + halfSize, yCoord + halfSize) then
					grid:getValue(xCoord + maxLength + halfSize, yCoord + halfSize)
				end

				local value = average(values) + getRandomValue(magnitude)
				grid:setValue(xCoord + maxLength, yCoord + halfSize, value)
			end
		end
	end
end

local function step(grid, scale)
	if scale <= 2 then return end

	diamond(grid, scale)
	square(grid, scale)

	step(grid, math.ceil(scale / 2))
end

local function initialize(grid)
	local gridSize = grid:getSize()

	grid:setValue(0, 0, math.random())
	grid:setValue(gridSize - 1, 0, math.random())
	grid:setValue(gridSize - 1, gridSize - 1, math.random())
	grid:setValue(0, gridSize - 1, math.random())
end

function TerrainGen:new(grid)
	return setmetatable({
		_grid = grid,
	}, TerrainGen)
end

function TerrainGen:generate()
	self._grid:clear()
	
	initialize(self._grid)
	
	local scale = self._grid:getSize()
	step(self._grid, scale)

	self._grid:smooth()
end

return setmetatable(TerrainGen, {
	__call = TerrainGen.new
})