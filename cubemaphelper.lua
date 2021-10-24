local CubeMapHelper = {}

local adjacentFaceMap = {
	--[[
	this map helps find neighbour faces for a given face number
	the key is the current face number and the values are adjacent face 
	numbers in order TOP, LEFT, BOTTOM, RIGHT
	--]]
	[1] = { 5, 4, 6, 2 },
	[2] = { 5, 1, 6, 3 },
	[3] = { 5, 2, 6, 4 },
	[4] = { 5, 3, 6, 1 },
	[5] = { 3, 4, 1, 2 },
	[6] = { 1, 4, 3, 2 },
}

--[[
The following tables are used to figure out x and y coordinates when changing 
the face of the cubemap.

Each table row is indexed by face number and has either 4 or 8 entries.

The first 4 entries are to be used for the primary axis, the remaining entries 
are to be used for the secondary axis.

The primary axis is the axis that we move over. The secondary axis might be 
affected when moving over primary axis and if this is true, entries are added.
If the secondary axis is not affected, it's value remains unchanged.

The entries are to be used as follows:
- 1: primary axis size multiplier
- 2: primary axis x-coord multiplier
- 3: primary axis y-coord multiplier
- 4: primary axis offset
- 5: secondary axis size multiplier
- 6: secondary axis x-coord multiplier
- 7: secondary axis y-coord multiplier
- 8: secondary axis offset
--]]

local topFaceModifiers = { 
	[1] = {  1,  0,  0, -1,  				},
	[2] = {  1, -1,  0, -1,	 1,  0,  0, -1  },
	[3] = {  0,  0,  0,  0,  1, -1,  0, -1  },
	[4] = {  0,  1,  0,  0,  0,  0,  0,  0  },
	[5] = {  0,  0,  0,  0,  1, -1,  0, -1  },
	[6] = {  1,  0,  0, -1,  				},
}

local bottomFaceModifiers = {
	[1] = {  0,  0,  0,  0,  				},
	[2] = {  0,  1,  0,  0,	 1,  0,  0, -1  },
	[3] = {  1,  0,  0, -1,  1, -1,  0, -1  },
	[4] = {  1, -1,  0, -1,  0,  0,  0,  0  },
	[5] = {  0,  0,  0,  0,  				},
	[6] = {  1,  0,  0, -1,  1, -1,  0, -1  },
}

local leftFaceModifiers = {
	[1] = {  1,  0,  0, -1,  				},
	[2] = {  1,  0,  0, -1,	 				},
	[3] = {  1,  0,  0, -1,  				},
	[4] = {  1,  0,  0, -1,  				},
	[5] = {  0,  0,  1,  0,  0,  0,  0,  0  },
	[6] = {  1,  0, -1, -1,  1,  0,  0, -1  },
}

local rightFaceModifiers = {
	[1] = {  0,  0,  0,  0,  				},
	[2] = {  0,  0,  0,  0,	 				},
	[3] = {  0,  0,  0,  0,  				},
	[4] = {  0,  0,  0,  0,  				},
	[5] = {  1,  0, -1, -1,  1,  0,  0, -1  },
	[6] = {  1,  0, -1, -1,  1,  0,  0, -1  },	
}

function CubeMapHelper.getCoord(face, size, x, y, dx, dy)
	local face, x, y = CubeMapHelper.getCoordDx(face, size, x, y, dx)
	return CubeMapHelper.getCoordDy(face, size, x, y, dy)
end

function CubeMapHelper.getCoordDx(face, size, x, y, dx)
	-- TODO: dx/dy should never be greater than size, to simplify calculations
	local ax, ay = x, y
	local nx = x + dx

	if nx < 0 then
		local xSizeF, xXF, xYF, xOff, ySizeF, yXF, yYF, yOff = unpack(leftFaceModifiers[face])
		x = size * xSizeF + ax * xXF + ay * xYF + xOff

		if ySizeF then			
			y = size * ySizeF + ax * yXF + ay * yYF + yOff
		end

		face = adjacentFaceMap[face][2]
	elseif nx >= size then
		local xSizeF, xXF, xYF, xOff, ySizeF, yXF, yYF, yOff = unpack(rightFaceModifiers[face])
		x = size * xSizeF + ax * xXF + ay * xYF + xOff

		if ySizeF then			
			y = size * ySizeF + ax * yXF + ay * yYF + yOff
		end

		face = adjacentFaceMap[face][4]
	else
		x = nx
	end

	return face, x, y
end

function CubeMapHelper.getCoordDy(face, size, x, y, dy)
	-- TODO: dx/dy should never be greater than size, to simplify calculations
	local ax, ay = x, y
	local ny = y + dy

	if ny < 0 then
		local ySizeF, yXF, yYF, yOff, xSizeF, xXF, xYF, xOff = unpack(topFaceModifiers[face])
		y = size * ySizeF + ax * yXF + ay * yYF + yOff

		if xSizeF then			
			x = size * xSizeF + ax * xXF + ay * xYF + xOff
		end

		face = adjacentFaceMap[face][1]
	elseif ny >= size then
		local ySizeF, yXF, yYF, yOff, xSizeF, xXF, xYF, xOff = unpack(bottomFaceModifiers[face])
		y = size * ySizeF + ax * yXF + ay * yYF + yOff

		if xSizeF then			
			x = size * xSizeF + ax * xXF + ay * xYF + xOff
		end

		face = adjacentFaceMap[face][3]
	else
		y = ny
	end

	return face, x, y
end

return CubeMapHelper