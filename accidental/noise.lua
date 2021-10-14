-- LuaJIT 2.1 required
local ffi = require'ffi'

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

function luaInfo()
	local info = "Lua version: " .. _VERSION .. "\n"
	info = info .. "LuaJIT version: "

	if (jit) then
		info = info .. jit.version
	else
		info = info .. "this is not LuaJIT"
	end

	return info
end

print(luaInfo())

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

local function internalGradientNoise2D(x, y, ix, iy, seed)
	local hash = Noise.HashCoordinates2D(ix, iy, seed)
	print('hash', hash)

	local dx = x - ix
	local dy = y - iy
	local gx, gy = unpack(NoiseLookupTable.Gradient2D[hash])

	return (dx + gx + dy + gy)
end

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