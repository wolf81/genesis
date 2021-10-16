-- LuaJIT 2.1 required
local ffi = require'ffi'

local NoiseLookupTable = require 'accidental/noise_lookup_table'

local Noise = {}
Noise.__index = Noise

local FNV_32_PRIME = 0x01000193
local FNV_32_INIT = 2166136261 
local FNV_MASK_8 = bit.lshift(1, 8) - 1 -- (1 << 8) - 1;

local F2 = 0.36602540378443864676372317075294
local G2 = 0.21132486540518711774542560974902
local F3 = 1.0 / 3.0
local G3 = 1.0 / 6.0

Noise.MAX_SOURCES = 20

   local _sign_helper = ffi.new("union { double d; uint64_t ul; int64_t l; }[1]")
    local function sign(num)
        -- to get access to the bit representation of double
        _sign_helper[0].d = num

        -- reinterpret it as ulong to access the sign bit
        -- 1. move the bit down to the first bit
        -- 2. multiply by -2 to move the range from 0/1 to 0/-2
        -- 4. add 1 to reduce the range to -1/1 

        -- one test version for NaN handling (might be faster, did not test.)
        -- return num ~= num and num or (tonumber(bit.rshift(_sign_helper[0].ul, 63)) * -2 + 1)
        
        -- branchless version: num - num will always be 0 except for nan.
        return (tonumber(bit.rshift(_sign_helper[0].ul, 63)) * -2 + 1) * ((num - num + 1) / 1)
    end

Noise.QuinticInterpolation = function(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

local function fastfloor(x)
	if x > 0 then
		return tonumber(ffi.cast('int', x))
	else
		return tonumber(ffi.cast('int', x)-1)
	end
end

-- The "new" FNV-1A hashing
local function FNV32Buffer(data, size_in_bytes)
   data = ffi.cast('uint8_t*', data)
   local hval = 0x811C9DC5LL
   for j = 0, size_in_bytes - 1 do
      hval = bit.bxor(hval, data[j]) * 0x01000193LL
   end
   return tonumber(bit.band(2^32-1, hval))
end

local function XORFoldHash(hash)
	local r = bit.bxor(
		bit.rshift(hash, 8), 
		bit.band(hash, FNV_MASK_8)
	)	
	return tonumber(bit.band(2^8-1, r))
end

--[[
        internal static Byte XORFoldHash(UInt32 hash)
        {
            // Implement XOR-folding to reduce from 32 to 8-bit hash
            return (byte)((hash >> 8) ^ (hash & FNV_MASK_8));
        }
]]

Noise.HashCoordinates2D = function(x, y, seed)
	local bufferSize = 3 -- 3 arguments: x, y, seed
	local d = ffi.new("int32_t[?]", bufferSize, x, y, seed)
	return XORFoldHash(FNV32Buffer(d, ffi.sizeof(d)))
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

local function internalValueNoise2D(x, y, ix, iy, seed)
	local noise = Noise.HashCoordinates2D(ix, iy, seed) / 255.0
	return noise * 2.0 - 1.0
end

local function arrayDot(arr, a, b)
	return a * arr[1] + b * arr[2]
end

local function internalGradientNoise2D(x, y, ix, iy, seed)
	local hash = Noise.HashCoordinates2D(ix, iy, seed)
	print('hash', hash)

	local dx = x - ix
	local dy = y - iy
	local gx, gy = unpack(NoiseLookupTable.Gradient2D[hash])

	return (dx + gx + dy + gy)
end

Noise.SimplexNoise2D = function(x, y, seed, interp)
	--print('SimplexNoise2D', x, y, seed)
	--print(x, y, sign(x), sign(y))

	local s = (x + y) * F2
	local i = fastfloor(x + s)
	local j = fastfloor(y + s)
	--print(i + j)

	local t = (i + j) * G2
	local x0 = x - (i - t)
	local y0 = y - (j - t)
	--print(string.format("%.2f", x), string.format("%.2f", y), string.format("%.2f", i), string.format("%.2f", j), string.format("%.2f", s), string.format("%.2f", t))

	local i1, j1
	if x0 > y0 then 
		i1, j1 = 1, 0
	else 
		i1, j1 = 0, 1
	end

	local x1 = x0 - i1 + G2
	local y1 = y0 - j1 + G2
	local x2 = x0 - 1.0 + 2.0 * G2
	local y2 = y0 - 1.0 + 2.0 * G2
--[[	print(
		string.format("%.2f", i), string.format("%.2f", j), 
		string.format("%.2f", i + i1), string.format("%.2f", j + j1),
		string.format("%.2f", i + 1), string.format("%.2f", j + 1)
		)
--]]	--print(i, j, i + i1, j + j1, i + 1, j + 1)

	local h0 = Noise.HashCoordinates2D(i, j, seed)
	local h1 = Noise.HashCoordinates2D(i + i1, j + j1, seed)
	local h2 = Noise.HashCoordinates2D(i + 1, j + 1, seed)
	--print(h0, h1, h2)

	local g0 = NoiseLookupTable.Gradient2D[h0]
	local g1 = NoiseLookupTable.Gradient2D[h1]
	local g2 = NoiseLookupTable.Gradient2D[h2]

	local n0, n1, n2
	
	local t0 = 0.5 - x0 * x0 - y0 * y0
	if t0 < 0 then n0 = 0 
	else
		t0 = t0 * t0
		n0 = t0 * t0 * arrayDot(g0, x0, y0)
	end

	local t1 = 0.5 - x1 * x1 - y1 * y1
	if t1 < 0 then n1 = 0
	else
		t1 = t1 * t1
		n1 = t1 * t1 * arrayDot(g1, x1, y1)
	end

	local t2 = 0.5 - x2 * x2 - y2 * y2
	if t2 < 0 then n2 = 0
	else
		t2 = t2 * t2
		n2 = t2 * t2 * arrayDot(g2, x2, y2)
	end

	return (70.0 * (n0 + n1 + n2)) * 1.42188695 + 0.001054489
end

Noise.SimplexNoise3D = function() error('not implemented') end
Noise.SimplexNoise4D = function() error('not implemented') end
Noise.SimplexNoise6D = function() error('not implemented') end

Noise.GradientNoise2D = function(x, y, seed, interp)
	print('GradientNoise2D', x, y, seed)

	local x0 = math.floor(x)
	local y0 = math.floor(y)

	local x1 = x0 + 1
	local y1 = y0 + 1

	local xs = interp(x - x0)
	local ys = interp(y - y0)

	local r = Noise.HashCoordinates2D(x, y, seed)

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