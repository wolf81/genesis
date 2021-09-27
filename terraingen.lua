-- Based on: https://asyncdrink.com/blog/diamond-square-algorithm

local TerrainGen = {}
TerrainGen.__index = TerrainGen

local function getRandomValue(magnitude)
	return math.random() * magnitude - (magnitude / 2)
end

local function isnan(v) return v ~= v end

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

			if isnan(grid:getValue(xCoord + offset, yCoord + offset)) then
				grid:setValue(xCoord + offset, yCoord + offset, value)
			end
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

				if isnan(grid:getValue(xCoord + halfSize, yCoord)) then
					local value = average(values) + getRandomValue(magnitude)
					grid:setValue(xCoord + halfSize, yCoord, value)
				end
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

				if isnan(grid:getValue(xCoord + halfSize, yCoord + maxLength)) then
					local value = average(values) + getRandomValue(magnitude)
					grid:setValue(xCoord + halfSize, yCoord + maxLength, value)
				end
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

				if isnan(grid:getValue(xCoord, yCoord + halfSize)) then
					local value = average(values) + getRandomValue(magnitude)
					grid:setValue(xCoord, yCoord + halfSize, value)
				end
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

				if isnan(grid:getValue(xCoord + maxLength, yCoord + halfSize)) then
					local value = average(values) + getRandomValue(magnitude)
					grid:setValue(xCoord + maxLength, yCoord + halfSize, value)
				end
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

local function initialize(grid, configure)
	local gridSize = grid:getSize()

	local coords = {
		{ x = 0, y = 0 },
		{ x = gridSize - 1, y = 0 },
		{ x = gridSize - 1, y = gridSize - 1 },
		{ x = 0, y = gridSize - 1 },
	}

	for _, coord in ipairs(coords) do
		local value = grid:getValue(coord.x, coord.y)
		if isnan(value) then grid:setValue(coord.x, coord.y, math.random()) end
	end
end

function TerrainGen:new(grid)
	return setmetatable({
		_grid = grid,
	}, TerrainGen)
end

function TerrainGen:generate()
	--self._grid:clear()
	
	initialize(self._grid)
	
	local scale = self._grid:getSize()
	step(self._grid, scale)

	self._grid:smooth()
end

return setmetatable(TerrainGen, {
	__call = TerrainGen.new
})