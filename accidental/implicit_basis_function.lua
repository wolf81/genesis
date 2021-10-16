local Noise = require 'accidental/noise'

local msin, mcos, mpi = math.sin, math.cos, math.pi

local ImplicitBasisFunction = {}
ImplicitBasisFunction.__index = ImplicitBasisFunction

local function setRotationAngle(self, x, y, z, angle)
	self._rotationMatrix[0][0] = 1 + (1 - mcos(angle)) * (x * x - 1)
	self._rotationMatrix[1][0] = -z * msin(angle) + (1 - mcos(angle)) * x * y
	self._rotationMatrix[2][0] = y * msin(angle) + (1 - mcos(angle)) * x * z

	self._rotationMatrix[0][1] = z * msin(angle) + (1 - mcos(angle)) * x * y
	self._rotationMatrix[1][1] = 1 + (1 - mcos(angle)) * (y * y - 1)
	self._rotationMatrix[2][1] = -x * msin(angle) + (1 - mcos(angle)) * y * z

	self._rotationMatrix[0][2] = -y * msin(angle) + (1 - mcos(angle)) * x * z
	self._rotationMatrix[1][2] = x * msin(angle) + (1 - mcos(angle)) * y * z
	self._rotationMatrix[2][2] = 1 + (1 - mcos(angle)) * (z * z - 1)
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
        self._noise2D = Noise.GradientNoise2D
        self._noise3D = Noise.GradientNoise3D
        self._noise4D = Noise.GradientNoise4D
        self._noise6D = Noise.GradientNoise6D
	elseif self._basisType == BasisType.GRADIENTVALUE then
		error('not implemented')
		--[[
        this.noise2D = Noise.GradientValueNoise;
        this.noise3D = Noise.GradientValueNoise;
        this.noise4D = Noise.GradientValueNoise;
        this.noise6D = Noise.GradientValueNoise;
		]]
	elseif self._basisType == BasisType.WHITE then
		error('not implemented')
		--[[
        this.noise2D = Noise.WhiteNoise;
        this.noise3D = Noise.WhiteNoise;
        this.noise4D = Noise.WhiteNoise;
        this.noise6D = Noise.WhiteNoise;
        ]]		
	elseif self._basisType == BasisType.SIMPLEX then
        self._noise2D = Noise.SimplexNoise2D
        self._noise3D = Noise.SimplexNoise3D
        self._noise4D = Noise.SimplexNoise4D
        self._noise6D = Noise.SimplexNoise6D		
	else 
		self._noise2D = Noise.GradientNoise2D
		self._noise3D = Noise.GradientNoise3D
		self._noise4D = Noise.GradientNoise4D
		self._noise6D = Noise.GradientNoise6D
	end
	setMagicNumbers(self, self._basisType)
end

local function setSeed(self, value)
	self._seed = value
	math.randomseed(value)

	local ax = math.random()
	local ay = math.random()
	local az = math.random()
	local len = math.sqrt(ax * ax + ay * ay + az * az)
	ax = ax / len
	ay = ay / len
	az = az / len

	setRotationAngle(self, ax, ay, az, math.random() * mpi * 2.0)
	local angle = math.random() * mpi * 2.0
	self._cos2D = mcos(angle)
	self._sin2D = msin(angle)
end

function ImplicitBasisFunction:new(basisType, interpolationType, seed)
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
	return love.math.noise(x, y)

	--[[
	local nx = x * self._cos2D - y * self._sin2D
	local ny = y * self._cos2D + x * self._sin2D

	return self._noise2D(nx, ny, self._seed, self._interpolator)
	--]]	
end

return setmetatable(ImplicitBasisFunction, {
	__call = ImplicitBasisFunction.new
})