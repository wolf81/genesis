local PATH = (...):match("(.-)[^%.]+$") 

local mmin, mmax, msqrt = math.min, math.max, math.sqrt
local Map = require(PATH .. 'map')

local lmath = love and love.math or lovr.math

local NoiseMap = {}
NoiseMap.__index = Map

local function fBm(x, y, z, octaves, frequency, amplitude)
	local gain = 0.5
	local lacunarity = 2.0

	local v = 0
	local f = frequency or 1.25
	local a = amplitude or 0.5

	for i = 0, octaves do
		v = v + a * lmath.noise(x * f, y * f, z * f)
		f = f * lacunarity
		a = a * gain
	end

	return v
end

local function noise(size, seed, octaves, frequency)
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

				local dab = msqrt(a * a + b * b)
				local dabc = msqrt(dab * dab + c * c)
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
					octaves,
					frequency
				)

				values[face][x][y] = value

				min = mmin(min, value)
				max = mmax(max, value)
			end
		end
	end

	return values, min, max
end

function NoiseMap:new(size, seed, octaves, frequency)
	local values, min, max = noise(size, seed or 0, octaves or 4, frequency or 1.25)
	local super = Map(values, size, min, max)

	return setmetatable(super, NoiseMap)
end

function NoiseMap:getSize()
	return self._size, self._size
end

return setmetatable(NoiseMap, {
	__call = NoiseMap.new
})