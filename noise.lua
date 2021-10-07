local M = {}

local function printData(data)
	local size = #data
	local s = ''
	for x = 0, size - 1 do
		for y = 0, size - 1 do
			s = s .. string.format('%.2f\t', data[x][y])
		end
		s = s .. '\n'
	end
	print(s)
end

local function diamondSquare(data, n, roughness, seed)
	data[0][0] = seed or math.random()
	data[0][n - 1] = seed or math.random()
	data[n - 1][0] = seed or math.random()
	data[n - 1][n - 1] = seed or math.random()

	--printData(data)

	local h = roughness

	local sideLength = #data[0] - 1
	while sideLength >= 2 do
		local halfSide = sideLength / 2

		-- generate square values
		local x = 0
		while x < n - 1 do
			local y = 0
			while y < n - 1 do
				local v1 = data[x][y]
				local v2 = data[x + sideLength][y]
				local v3 = data[x][y + sideLength]
				local v4 = data[x + sideLength][y + sideLength]
				local avg = (v1 + v2 + v3 + v4) / 4

				data[x + halfSide][y + halfSide] = avg + (love.math.random() * 2 * h) - h

				y = y + sideLength
			end

			x = x + sideLength			
		end

		-- generate diamond values
		local x = 0
		while x < n - 1 do
			local y = (x + halfSide) % sideLength
			while y < n - 1 do
				local v1 = data[(x - halfSide + n) % n][y]
				local v2 = data[(x + halfSide) % n][y]
				local v3 = data[x][(y + halfSide) % n]
				local v4 = data[x][(y - halfSide + n) % n]
				local avg = (v1 + v2 + v3 + v4) / 4

				data[x][y] = avg + (love.math.random() * 2 * h) - h

				if x == 0 then
					data[n - 1][y] = avg
				end

				if y == 0 then
					data[x][n - 1] = avg
				end

				y = y + sideLength
			end

			x = x + halfSide
		end


		sideLength = sideLength / 2
		h = h / 2

		--print('h', h)
	end
end

function M.generate(size, seed, roughness)
	local data = {}

	local n = 2 ^ size + 1

	for x = 0, n do
		data[x] = {}
		for y = 0, n do
			data[x][y] = 0
		end
	end

	diamondSquare(data, n, seed, roughness or 0.5)

	return data
end

return M