local Noise = {}
Noise.__index = Noise

Noise.MAX_SOURCES = 20

Noise.QuinticInterpolation = function(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

Noise.HashCoordinates2D = function(x, y, seed)
	error('not implemented')
end

local function lerp(s, v1, v2)
	return v1 + s * (v2 - v1)
end 

local function interpolateX2(x, y, xs, x0, x1, iy, seed, noiseFunc)
	local v1 = noiseFunc(x, y, x0, iy, seed)
	local v2 = noiseFunc(x, y, x1, iy, seed)
	return lerp(xs, v1, v2)
end

local function interpolateXY2(x, y, xs, ys, x0, x1, y0, y1, seed, noiseFunc)
	local v1 = interpolateX2(x, y, xs, x0, x1, y0, seed, noiseFunc)
	local v2 = interpolateX2(x, y, xs, x0, x1, y1, seed, noiseFunc)
	return lerp(ys, v1, v2)
end

local function internalGradientNoise2D(x, y, ix, iy, seed)
	local hash = Noise.HashCoordinates(ix, iy, seed)
	local dx = x - ix
	local dy = y - iy
	
	return (
		dx + NoiseLookupTable.Gradient2D[hash][0] + 
		dy + NoiseLookupTable.Gradient2D[hash][1]
	)
end

Noise.GradientNoise2D = function(x, y, seed, interp)
	local x0 = math.floor(x)
	local y0 = math.floor(y)

	local x1 = x0 + 1
	local y1 = y0 + 1

	local xs = interp((x - x0))
	local ys = interp((y - y0))

	return interpolate_XY_2(x, y, xs, ys, x0, x1, y0, y1, seed, internalGradientNoise)
end

Noise.GradientNoise3D = function() error('not implemented') end
Noise.GradientNoise4D = function() error('not implemented') end
Noise.GradientNoise6D = function() error('not implemented') end

function Noise:new()
	print('new Noise')

	return setmetatable({
	}, Noise)
end

return setmetatable(Noise, {
	__call = Noise.new,
})