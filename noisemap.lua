local mmin, mmax = math.min, math.max
local Map = require 'map'

-- based on: https://ronvalstar.nl/creating-tileable-noise-maps

local NoiseMap = {}
NoiseMap.__index = Map

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

local function noise(size, seed)
	local values = {}

	local min, max = math.huge, -math.huge

	local hsize = size / 2
	local aa, bb, cc = seed % 173, seed % 71, seed % 17 -- seed values

	for face = 1, 6 do
		values[face] = {}
		for x = 0, size - 1 do
			values[face][x] = {}
			for y = 0, size - 1 do
				local a = -hsize + x + 0.5
				local b = -hsize + y + 0.5
				local c = -hsize

				local dab = math.sqrt(a * a + b * b)
				local dabc = math.sqrt(dab * dab + c * c)
				local drds = 0.5 * dabc

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

				values[face][x][y] = value

				min = mmin(min, value)
				max = mmax(max, value)
			end
		end
	end

	return values, min, max
end

function NoiseMap:new(size, seed)
	local values, min, max = noise(size, seed or 0)
	local super = Map(values, size, min, max)

	return setmetatable(super, NoiseMap)
end

function NoiseMap:getSize()
	return self._size, self._size
end

return setmetatable(NoiseMap, {
	__call = NoiseMap.new
})