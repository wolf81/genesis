local Noise = require 'accidental/noise'

local ImplicitBasisFunction = {}
ImplicitBasisFunction.__index = ImplicitBasisFunction

local function setRotationAngle(self, x, y, z, angle)
	self._rotationMatrix[0][0] = 1 + (1 - math.cos(angle)) * (x * x - 1)
	self._rotationMatrix[1][0] = -z * math.sin(angle) + (1 - math.cos(angle)) * x * y
	self._rotationMatrix[2][0] = y * math.sin(angle) + (1 - math.cos(angle)) * x * z

	self._rotationMatrix[0][1] = z * math.sin(angle) + (1 - math.cos(angle)) * x * y
	self._rotationMatrix[1][1] = 1 + (1 - math.cos(angle)) * (y * y - 1)
	self._rotationMatrix[2][1] = -x * math.sin(angle) + (1 - math.cos(angle)) * y * z

	self._rotationMatrix[0][2] = -y * math.sin(angle) + (1 - math.cos(angle)) * x * z
	self._rotationMatrix[1][2] = x * math.sin(angle) + (1 - math.cos(angle)) * y * z
	self._rotationMatrix[2][2] = 1 + (1 - math.cos(angle)) * (z * z - 1)
end

local function setInterpolationType(self, value)
	self._interpolationType = value

	if self._interpolationType == InterpolationType.NONE then
		error('not implemented')
		-- this.interpolator = Noise.NoInterpolation;
	elseif self._interpolationType == InterpolationType.LINEAR then
		error('not implemented')
		-- this.interpolator = Noise.LinearInterpolation;
	elseif self._interpolationType == InterpolationType.CUBIC then
		error('not implemented')
		-- this.interpolator = Noise.HermiteInterpolation;
	else
		self._interpolator = Noise.QuinticInterpolation
	end
end

local function setMagicNumbers(self, type)
	--[[
	This function is a damned hack.
	The underlying noise functions don't return values in the range [-1,1] 
	cleanly, and the ranges vary depending on basis type and dimensionality. 
	There's probably a better way to correct the ranges, but for now I'm just
	setting the magic numbers scale and offset manually to empirically 
	determined magic numbers.
	]]

	if type == BasisType.VALUE then
		error("not implemented")
	elseif type == BasisType.GRADIENT then
		error("not implemented")
	elseif type == BasisType.GRADIENTVALUE then
		error("not implemented")
	elseif type == BasisType.WHITE then
		error("not implemented")
	else
		self._scale[0] = 1.0
		self._offset[0] = 0.0
		self._scale[1] = 1.0
		self._offset[1] = 0.0
		self._scale[2] = 1.0
		self._offset[2] = 0.0
		self._scale[3] = 1.0
		self._offset[3] = 0.0
	end
end

--[[
private void SetMagicNumbers(BasisType type)
{
    switch (type)
    {
        case BasisType.VALUE:
            this.scale[0] = 1.0;
            this.offset[0] = 0.0;
            this.scale[1] = 1.0;
            this.offset[1] = 0.0;
            this.scale[2] = 1.0;
            this.offset[2] = 0.0;
            this.scale[3] = 1.0;
            this.offset[3] = 0.0;
            break;

        case BasisType.GRADIENT:
            this.scale[0] = 1.86848;
            this.offset[0] = -0.000118;
            this.scale[1] = 1.85148;
            this.offset[1] = -0.008272;
            this.scale[2] = 1.64127;
            this.offset[2] = -0.01527;
            this.scale[3] = 1.92517;
            this.offset[3] = 0.03393;
            break;

        case BasisType.GRADIENTVALUE:
            this.scale[0] = 0.6769;
            this.offset[0] = -0.00151;
            this.scale[1] = 0.6957;
            this.offset[1] = -0.133;
            this.scale[2] = 0.74622;
            this.offset[2] = 0.01916;
            this.scale[3] = 0.7961;
            this.offset[3] = -0.0352;
            break;

        case BasisType.WHITE:
            this.scale[0] = 1.0;
            this.offset[0] = 0.0;
            this.scale[1] = 1.0;
            this.offset[1] = 0.0;
            this.scale[2] = 1.0;
            this.offset[2] = 0.0;
            this.scale[3] = 1.0;
            this.offset[3] = 0.0;
            break;

        default:
            break;
    }
}
]]

local function setBasisType(self, value)
	self._basisType = value

	if self._basisType == BasisType.VALUE then
		error('not implemented')
		--[[
        this.noise2D = Noise.ValueNoise;
        this.noise3D = Noise.ValueNoise;
        this.noise4D = Noise.ValueNoise;
        this.noise6D = Noise.ValueNoise;
		]]
	elseif self._basisType == BasisType.GRADIENT then
		error('not implemented')
		--[[
        this.noise2D = Noise.GradientNoise;
        this.noise3D = Noise.GradientNoise;
        this.noise4D = Noise.GradientNoise;
        this.noise6D = Noise.GradientNoise;
		]]
	elseif self._basisType == GRADIENTVALUE then
		error('not implemented')
		--[[
        this.noise2D = Noise.GradientValueNoise;
        this.noise3D = Noise.GradientValueNoise;
        this.noise4D = Noise.GradientValueNoise;
        this.noise6D = Noise.GradientValueNoise;
		]]
	elseif self._basisType == WHITE then
		error('not implemented')
		--[[
        this.noise2D = Noise.WhiteNoise;
        this.noise3D = Noise.WhiteNoise;
        this.noise4D = Noise.WhiteNoise;
        this.noise6D = Noise.WhiteNoise;
        ]]		
	elseif self._basisType == SIMPLEX then
		error('not implemented')
		--[[
        this.noise2D = Noise.SimplexNoise;
        this.noise3D = Noise.SimplexNoise;
        this.noise4D = Noise.SimplexNoise;
        this.noise6D = Noise.SimplexNoise;		
		]]
	else 
		self._noise2D = Noise.GradientNoise2D
		self._noise3D = Noise.GradientNoise3D
		self._noise4D = Noise.GradientNoise4D
		self._noise6D = Noise.GradientNoise6D
	end
	setMagicNumbers(self, self._basisType)
end

--[[
public BasisType BasisType
{
    get { return this.basisType; }
    set
    {
        this.basisType = value;
        switch (this.basisType)
        {
            case BasisType.VALUE:
                this.noise2D = Noise.ValueNoise;
                this.noise3D = Noise.ValueNoise;
                this.noise4D = Noise.ValueNoise;
                this.noise6D = Noise.ValueNoise;
                break;
            case BasisType.GRADIENT:
                this.noise2D = Noise.GradientNoise;
                this.noise3D = Noise.GradientNoise;
                this.noise4D = Noise.GradientNoise;
                this.noise6D = Noise.GradientNoise;
                break;
            case BasisType.GRADIENTVALUE:
                this.noise2D = Noise.GradientValueNoise;
                this.noise3D = Noise.GradientValueNoise;
                this.noise4D = Noise.GradientValueNoise;
                this.noise6D = Noise.GradientValueNoise;
                break;
            case BasisType.WHITE:
                this.noise2D = Noise.WhiteNoise;
                this.noise3D = Noise.WhiteNoise;
                this.noise4D = Noise.WhiteNoise;
                this.noise6D = Noise.WhiteNoise;
                break;
            case BasisType.SIMPLEX:
                this.noise2D = Noise.SimplexNoise;
                this.noise3D = Noise.SimplexNoise;
                this.noise4D = Noise.SimplexNoise;
                this.noise6D = Noise.SimplexNoise;
                break;

            default:
                this.noise2D = Noise.GradientNoise;
                this.noise3D = Noise.GradientNoise;
                this.noise4D = Noise.GradientNoise;
                this.noise6D = Noise.GradientNoise;
                break;
        }
        SetMagicNumbers(this.basisType);
    }
}

public InterpolationType InterpolationType
{
    get { return this.interpolationType; }
    set
    {
        this.interpolationType = value;
        switch (this.interpolationType)
        {
            case InterpolationType.NONE: this.interpolator = Noise.NoInterpolation; break;
            case InterpolationType.LINEAR: this.interpolator = Noise.LinearInterpolation; break;
            case InterpolationType.CUBIC: this.interpolator = Noise.HermiteInterpolation; break;
            default: this.interpolator = Noise.QuinticInterpolation; break;
        }
    }
}
]]

local function setSeed(self, value)
	self._seed = value

	local function nextRandom() return math.random() * value end

	local ax = nextRandom()
	local ay = nextRandom()
	local az = nextRandom()
	local len = math.sqrt(ax * ax + ay * ay + az * az)
	ax = ax / len
	ay = ay / len
	az = az / len

	setRotationAngle(self, ax, ay, az, nextRandom() * math.pi * 2.0)
	local angle = nextRandom() * math.pi * 2.0
	self._cos2D = math.cos(angle)
	self._sin2D = math.sin(angle)
end

function ImplicitBasisFunction:new(basisType, interpolationType, seed)
	print('new ImplicitBasisFunction')

	local rotationMatrix = {}
	for i = 0, 3 do
		rotationMatrix[i] = {}
		for j = 0, 3 do
			rotationMatrix[i][j] = 0
		end
	end

	local scale, offset = {}, {}
	for i = 0, 4 do
		scale[i] = 1.0
		offset[i] = 0.0
	end

	local instance = setmetatable({
		_basisType = nil,
		_interpolationType = nil,		
		_seed = nil,
		_interpolator = nil,
		_noise2D = nil,
		_noise3D = nil,
		_noise4D = nil,
		_noise6D = nil,
		_sin2D = 0,
		_cos2D = 0,
		_rotationMatrix = rotationMatrix,
		_scale = scale,
		_offset = offset,
	}, ImplicitBasisFunction)

	setSeed(instance, seed)
	setInterpolationType(instance, interpolationType)
	setBasisType(instance, basisType)

	return instance
end

function ImplicitBasisFunction:get2D(x, y)
	local nx = x * self._cos2D - y * self._sin2D
	local ny = y * self._cos2D + x * self._sin2D
	return 0
end

return setmetatable(ImplicitBasisFunction, {
	__call = ImplicitBasisFunction.new
})