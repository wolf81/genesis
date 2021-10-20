require 'utility'

local min, max = math.min, math.max

-- based on: https://ronvalstar.nl/creating-tileable-noise-maps

local NoiseMap = {}

local function fbm(x, y, z, frequency, amplitude)
	local gain = 0.5
	local lacunarity = 2.0

	local v = 0
	local f = frequency
	local a = amplitude

	for i = 0, 4 do
		v = v + a * love.math.noise(x * f, y * f, z * f)
		f = f * lacunarity
		a = a * gain
	end

	return v
end

local function simplex(size, face)
	local map = {}
	map.w = size
	map.h = size

	local vmin = math.huge
	local vmax = -math.huge

	-- print('size', size)

	local hsize = size / 2
	local aa, bb, cc = 123, 231, 321

	-- print('face', face)

	local l = size * size
	-- print('l', l)
	for i = 0, l - 1 do
		local x = i % size
		local y = math.floor(i / size)
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

--[[		for n, m in ipairs(noisePos[face]) do
			print(n, m)
		end
--]]
		if map[x] == nil then
			map[x] = {}
		end

		map[x][y] = fbm(
			aa + noisePos[face][1], 
			bb + noisePos[face][2],
			cc + noisePos[face][3],
			1.25,
			0.5
			)

--[[		map[x][y] = love.math.noise(
				aa + noisePos[face][1],
				bb + noisePos[face][2],
				cc + noisePos[face][3],
			)
--]]
		vmin = math.min(vmin, map[x][y])
		vmax = math.max(vmax, map[x][y])
		--[[	
		for j = 1, 6 do
			cubemap[face] = {}
			cubemap[face][1] = {}

			local v = love.math.noise(
				aa + noisePos[j][1], 
				bb + noisePos[j][2], 
				cc + noisePos[j][3]
			)
			cubemap[face][y * x + x] = v
		end
		--]]
	end

	map.min = vmin
	map.max = vmax

	return map
end

function NoiseMap.create(size, face)
    return simplex(2 ^ size, face)
end

return NoiseMap