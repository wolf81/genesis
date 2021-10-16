local Fractal = {}
Fractal.__index = Fractal

local function getNoise2D(x, y, frequency, amplitude)
	return love.math.noise(x / frequency, y / frequency) * amplitude
end

local function getNoise4D(x, y, z, w, frequency, amplitude)
	return love.math.noise(x / frequency, y / frequency, z / frequency, w / frequency) * amplitude
end

function Fractal:new(ocataves, frequency, amplitude, seed)
	return setmetatable({
		_octaves = ocataves or 6,
		_frequency = frequency or 32,
		_amplitude = amplitude or 128,
		_seed = seed or 300,
		_map = {}
	}, Fractal)
end

function Fractal:generate(width, height)	
	local map = {}

	local vmin, vmax = math.huge, -math.huge

	for x = 0, width - 1 do
		map[x] = {}
		for y = 0, height - 1 do
			local v = 0

			for i = 1, self._octaves do
				v = v + getNoise2D(x + self._seed, y + self._seed, self._frequency / i, self._amplitude / i)
			end

			map[x][y] = v
			vmin = math.min(vmin, v)
			vmax = math.max(vmax, v)			
		end
	end

	for x = 0, width - 1 do
		for y = 0, height - 1 do
			local v1 = map[x][y]
			local v2 = (v1 - vmin) / (vmax - vmin)
			map[x][y] = v2
		end
	end

	return map
end

function Fractal:generate2(width, height)
	local map = {}

	local vmin, vmax = math.huge, -math.huge

	local mpi2 = 2 * math.pi

	for x = 0, width - 1 do
		map[x] = {}
		for y = 0, height - 1 do
			local x1, x2 = 0, 2
			local y1, y2 = 0, 2
			local dx = x2 - x1
			local dy = y2 - y1

			local s = x / width
			local t = y / height

			local nx = x1 + math.cos(s * mpi2) * dx / mpi2
			local ny = y1 + math.cos(t * mpi2) * dy / mpi2
			local nz = x1 + math.sin(s * mpi2) * dx / mpi2
			local nw = y1 + math.sin(t * mpi2) * dy / mpi2

			local v = 0

			for i = 1, self._octaves do
				v = v + getNoise4D(nx + self._seed, ny + self._seed, nz + self._seed, nw + self._seed, self._frequency / i, self._amplitude / i)
			end

			map[x][y] = v
			vmin = math.min(vmin, v)
			vmax = math.max(vmax, v)			
		end
	end

	for x = 0, width - 1 do
		for y = 0, height - 1 do
			local v1 = map[x][y]
			local v2 = (v1 - vmin) / (vmax - vmin)
			map[x][y] = v2
		end
	end

	return map
end

--[[
function Fractal:get2D(x, y)
	local value = 0.0
	local f = self._frequency
	local a = 0.5

	for i = 0, self._octaves - 1 do
		value = value + a * getNoise2D(x * f, y * f)
		f = f * self._lacunarity
		a = a * self._gain
	end

	return value
end
]]

return setmetatable(Fractal, {
	__call = Fractal.new
})