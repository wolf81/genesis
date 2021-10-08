local Noise = require 'accidental/noise'
local ImplicitBasisFunction = require 'accidental/implicit_basis_function'

local ImplicitFractal = {}
ImplicitFractal.__index = ImplicitFractal

local function clamp(v, min, max)
	return math.max(math.max(v, min), max)
end 

local function setAllSourceTypes(self, newBasisType, newInterpolationType)	
	for i = 0, Noise.MAX_SOURCES do
		self._basisFunctions[i] = ImplicitBasisFunction(newBasisType, newInterpolationType, self._seed) 
	end
end 

local function resetAllSources(self)
	for c = 0, Noise.MAX_SOURCES do
		self._sources[c] = self._basisFunctions[c]
	end
end

local function multiGet(self, x, y)
	local value = 1.00
	x = x * self._frequency
	y = y * self._frequency

	for i = 0, self._octaves do
		value = self._sources[i]:get2D(x, y) + self._expArray[i] + 1.0
		x = x * self._lacunarity
		y = y * self._lacunarity
	end

	return (
		value * 
		self._correct[self._octaves - 1][0] + 
		self._correct[self._octaves - 1][1]
	)
end

function ImplicitFractal:new(fractalType, basisType, interpolationType, octaves, frequency, seed)
	print('new ImplicitFractal')

	local correct = {}
	local expArray = {}
	for i = 0, Noise.MAX_SOURCES do
		expArray[i] = 0
		correct[i] = {}

		for j = 0, 2 do
			correct[i][j] = 0
		end
	end

	local instance = setmetatable({
		_seed = seed,
		_octaves = octaves,
		_frequency = frequency,
		_lacunarity = 2.00,
		_type = fractalType or FractalType.FRACTIONALBROWNIANMOTION,
		_basisFunctions = {},
		_sources = {},
		_expArray = expArray,
		_correct = correct,
	}, ImplicitFractal)

	setAllSourceTypes(instance, basisType, interpolationType)
	resetAllSources(instance)

	return instance
end

function ImplicitFractal:get2D(x, y)
	local v = nil

	if self._type == FractalType.FRACTIONALBROWNIANMOTION then
		error('not implemented')
	elseif self._type == FractalType.RIDGEDMULTI then
		error('not implemented')
	elseif self._type == FractalType.BILLOW then
		error('not implemented')
	elseif self._type == FractalType.MULTI then
		v = multiGet(self, x, y)
	elseif self._type == FractalType.HYBRIDMULTI then
		error('not implemented')
	else error('invalid type: ', self._type) end

	return clamp(v, -1.0, 1.0)
end

--[[
private Double Multi_Get(Double x, Double y)
{
    var value = 1.00;
    x *= Frequency;
    y *= Frequency;

    for (var i = 0; i < octaves; ++i)
    {
        value *= sources[i].Get(x, y) * expArray[i] + 1.0;
        x *= Lacunarity;
        y *= Lacunarity;

    }

    return value * correct[octaves - 1, 0] + correct[octaves - 1, 1];
}
]]

--[[
Double v;
switch (type)
{
    case FractalType.FRACTIONALBROWNIANMOTION:
        v = FractionalBrownianMotion_Get(x, y);
        break;
    case FractalType.RIDGEDMULTI:
        v = RidgedMulti_Get(x, y);
        break;
    case FractalType.BILLOW:
        v = Billow_Get(x, y);
        break;
    case FractalType.MULTI:
        v = Multi_Get(x, y);
        break;
    case FractalType.HYBRIDMULTI:
        v = HybridMulti_Get(x, y);
        break;
    default:
        v = FractionalBrownianMotion_Get(x, y);
        break;
}
return MathHelper.Clamp(v, -1.0, 1.0);

]]

return setmetatable(ImplicitFractal, {
	__call = ImplicitFractal.new,
})