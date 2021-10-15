local Noise = require 'accidental/noise'
local ImplicitBasisFunction = require 'accidental/implicit_basis_function'

local ImplicitFractal = {}
ImplicitFractal.__index = ImplicitFractal

local function clamp(v, min, max)
	return math.min(math.max(v, min), max)
end 

local function fractionalBrownianMotionCalculateWeights(self)
	for i = 0, Noise.MAX_SOURCES - 1 do
		self._expArray[i] = math.pow(self._lacunarity, -i * self._h)		
	end	

	local minValue = 0.00
	local maxValue = 0.00
	for i = 0, Noise.MAX_SOURCES - 1 do
		minValue = minValue + (-1.0 * self._expArray[i])
		maxValue = maxValue + (1.0 * self._expArray[i])

		local a = -1.0
		local b = 1.0
		local scale = (b - a) / (maxValue - minValue)
		local bias = a - minValue * scale
		self._correct[i][0] = scale
		self._correct[i][1] = bias
	end
end 

local function multiCalculateWeights(self)
	for i = 0, Noise.MAX_SOURCES - 1 do
		self._expArray[i] = math.pow(self._lacunarity, -i * self._h)		
	end	

	local minValue = 1.0
	local maxValue = 1.0

	for i = 0, Noise.MAX_SOURCES - 1 do
		minValue = minValue * (-1.0 * self._expArray[i] + 1.0)
		maxValue = maxValue * (1.0 * self._expArray[i] + 1.0)

		local a = -1.0
		local b = 1.0
		local scale = (b - a) / (maxValue - minValue)
		local bias = a - minValue * scale
		self._correct[i][0] = scale
		self._correct[i][1] = bias
	end
end

local function setAllSourceTypes(self, newBasisType, newInterpolationType)	
	for i = 0, Noise.MAX_SOURCES - 1 do
		self._basisFunctions[i] = ImplicitBasisFunction(newBasisType, newInterpolationType, self._seed) 
	end
end 

local function resetAllSources(self)
	for c = 0, Noise.MAX_SOURCES - 1 do
		self._sources[c] = self._basisFunctions[c]
	end
end

local function multiGet(self, x, y)
	local value = 1.00
	x = x * self._frequency
	y = y * self._frequency

	for i = 0, self._octaves - 1 do		
		value = value * (self._sources[i]:get2D(x, y) * self._expArray[i] + 1.0)
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
	print('new ImplicitFractal', seed)

	local correct = {}
	local expArray = {}
	for i = 0, Noise.MAX_SOURCES - 1 do
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
		_type = nil,
		_basisFunctions = {},
		_sources = {},
		_expArray = expArray,
		_correct = correct,
	}, ImplicitFractal)

	instance:setOcataves(octaves)
	instance:setType(fractalType or FractalType.FRACTIONALBROWNIANMOTION)

	setAllSourceTypes(instance, basisType, interpolationType)
	resetAllSources(instance)

	return instance
end

function ImplicitFractal:setSeed(value)
	self._seed = value
	for source = 0, Noise.MAX_SOURCES - 1 do
		self._sources[i]:setSeed(value + source * 300)
	end
end

function ImplicitFractal:setType(value)
	self._type = value

	if value == FractalType.FRACTIONALBROWNIANMOTION then
		error('not implemented')
	elseif value == FractalType.RIDGEDMULTI then
		error('not implemented')
	elseif value == FractalType.BILLOW then
		error('not implemented')
	elseif value == FractalType.MULTI then
		self._h = 1.00
		self._gain = 0.00
		self._offset = 0.00
		multiCalculateWeights(self)
	elseif value == FractalType.HYBRIDMULTI then
		error('not implemented')
	else
		self._h = 1.00
		self._gain = 0.00
		self._offset = 0.00
		fractionalBrownianMotionCalculateWeights(self)
	end
end

function ImplicitFractal:setOcataves(value)
	value = math.min(value, Noise.MAX_SOURCES - 1) -- TODO: maybe should not have -1 here?

	self._octaves = value
end

function ImplicitFractal:get2D(x, y)	
	local v = nil

	if self._type == FractalType.FRACTIONALBROWNIANMOTION then
		error('not implemented')
		-- v = fractionalBrownianMotionGet(self, x, y)
	elseif self._type == FractalType.RIDGEDMULTI then
		error('not implemented')
		-- v = ridgedMultiGet(self, x, y)
	elseif self._type == FractalType.BILLOW then
		error('not implemented')
		-- v = billowGet(self, x, y)
	elseif self._type == FractalType.MULTI then	
		v = multiGet(self, x, y)
	elseif self._type == FractalType.HYBRIDMULTI then
		error('not implemented')
		-- v = hybridMultiGet(self, x, y)
	else 
		error('not implemented')
		-- v = fractionalBrownianMotionGet(self, x, y)
	end

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