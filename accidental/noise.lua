local NoiseLookupTable = require 'accidental/noise_lookup_table'

local Noise = {}
Noise.__index = Noise

local FNV_32_PRIME = 0x01000193
local FNV_32_INIT = 2166136261 
local FNV_MASK_8 = bit.lshift(1, 8) - 1 -- (1 << 8) - 1;

Noise.MAX_SOURCES = 20

Noise.QuinticInterpolation = function(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

--[[
local bit = require "bit"
local bxor = bit.bxor

local OFFSET_BASIS = 2166136261
local FNV_PRIME = 16777619

-- FNV hash
local function hash(i, j, k)
    return ( bxor(
                bxor(
                  bxor(OFFSET_BASIS, i)*FNV_PRIME, j
                ) * FNV_PRIME
             , k) * FNV_PRIME )
end
]]

local function XORFoldHash(hash)
	print('hash', string.format('%x', hash))
	error('not implemented')	
end

local function FNV32Buffer(buffer, len)
	local hval = FNV_32_INIT

	for i = 1, len do
		hval = hval ^ buffer[i]
		hval = hval * FNV_32_PRIME
	end

	print('hval ->', string.format("%x", hval))

	return hval
end 

--[[
        internal static Byte XORFoldHash(UInt32 hash)
        {
            // Implement XOR-folding to reduce from 32 to 8-bit hash
            return (byte)((hash >> 8) ^ (hash & FNV_MASK_8));
        }
]]

Noise.HashCoordinates2D = function(x, y, seed)
	local bufferSize = 3 -- ? sizeof(Int32) * 3)
	local d = { x, y, seed }
	return XORFoldHash(FNV32Buffer(d, bufferSize))

-- Int32[] d = { x, y, seed };
-- return XORFoldHash(FNV32Buffer(d, sizeof(Int32) * 3));
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
	local hash = Noise.HashCoordinates2D(ix, iy, seed)
	local dx = x - ix
	local dy = y - iy
	
	-- hash should be value between 0 .. 512 

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

	return interpolateXY2(x, y, xs, ys, x0, x1, y0, y1, seed, internalGradientNoise2D)
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