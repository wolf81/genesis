require 'utility'

local min, max = math.min, math.max

-- based on: https://ronvalstar.nl/creating-tileable-noise-maps

local NoiseMap = {}
NoiseMap.__index = NoiseMap

local function fBm(x, y, z, frequency, amplitude)
	local gain = 0.5
	local lacunarity = 2.0

	local v = 0
	local f = frequency
	local a = amplitude

	for i = 0, 8 do
		v = v + a * love.math.noise(x * f, y * f, z * f)
		f = f * lacunarity
		a = a * gain
	end

	return v
end

local function simplex(size)
	local map = {}

	local vmin = math.huge
	local vmax = -math.huge

	local hsize = size / 2
	local aa, bb, cc = 0, 0, 0 -- seed values

	for face = 1, 6 do
		map[face] = {}
		for x = 0, size - 1 do
			map[face][x] = {}
			for y = 0, size - 1 do
				local a = -hsize + x + 0.5
				local b = -hsize + y + 0.5
				local c = -hsize

				local dab = math.sqrt(a * a + b * b)
				local dabc = math.sqrt(dab * dab + c * c)
				local drds = 0.5 * dabc
				local v = 1.0

				a = a / drds
				b = b / drds
				c = c / drds

				local noisePos = {
					{  a,  b,  c },
					{ -c,  b,  a },
					{ -a,  b, -c },
					{  c,  b, -a },
					{  a,  c, -b },
					{  a, -c,  b },
				}

				local value = fBm(
					aa + noisePos[face][1], 
					bb + noisePos[face][2],
					cc + noisePos[face][3],
					0.5,
					0.5
				)

				map[face][x][y] = value

				vmin = math.min(vmin, value)
				vmax = math.max(vmax, value)
			end
		end
	end

	-- normalize to 0.0 ... 1.0 range
	for face = 1, 6 do
		for x = 0, size - 1 do
			for y = 0, size - 1 do
				local v = map[face][x][y]
				map[face][x][y] = (v - vmin) / (vmax - vmin)
			end
		end		
	end

	-- printArray2(map)

	return map, vmin, vmax
end

function NoiseMap:new(size, seed)
	local size = 2 ^ size
	local map, vmin, vmax = simplex(size)

	return setmetatable({
		_map = map,
		_min = vmin,
		_max = vmax,
		_size = size,
	}, NoiseMap)
end

function NoiseMap:getValue(face, x, y)
	return self._map[face][x][y]
end

function NoiseMap:getMin()
	return self._min
end

function NoiseMap:getSize()
	return self._size, self._size
end

function NoiseMap:getMax()
	return self._max
end

return setmetatable(NoiseMap, {
	__call = NoiseMap.new
})