--[[
The CubeMapHelper class provides utility functions for dealing with cube maps. 
In order to better understand the functions, we should realize the cubemap faces 
are ordered as such:
    
    5
	1 2 3 4
	6

In the above representation we see faces 1 to 4 are horizontally aligned with 
one another. Face 5 is the top face and face 6 is the bottom face.
]]

local CubeMapHelper = {}

--[[
The adjactent face map helps find neighbour faces for a given face number. The 
key is the current face number and the values are adjacent face numbers in order 
TOP, LEFT, BOTTOM, RIGHT.
--]]
local adjacentFaceMap = {
	[1] = { 5, 4, 6, 2 },
	[2] = { 5, 1, 6, 3 },
	[3] = { 5, 2, 6, 4 },
	[4] = { 5, 3, 6, 1 },
	[5] = { 3, 4, 1, 2 },
	[6] = { 1, 4, 3, 2 },
}

--[[
The following tables are used to translate x and y coordinates when moving 
across faces on the cube.

In order to better understand the translation tables remember the faces of the 
cubemap are ordered as such:

    5
	1 2 3 4
	6

Moving from face 1 vertically to face 5 or 6 is trivial. The x coordinate stays 
the same, but the y coordinate changes. Likewise moving horizontally across 
faces 1 to 4 is trivial as well, the x coordinate changes but the y coordinate 
stays the same.

The situation becomes more tricky when moving from, say, face 2 to 5. In this 
case the top x coordinates of face 2 are adjacent to the right y coordinates of 
face 5. So in this case we need to translate the coordinates. For this reason we
can use the translation tables, to simplify these calculations.

Each table row is indexed by face number and has either 4 or 8 entries.

The first 4 entries are to be used for the primary axis, the remaining entries 
are to be used for the secondary axis. 

The primary axis is the axis that we move over. The secondary axis might be 
affected when moving over primary axis and if this is true, entries are added.
If the secondary axis is not affected from movement across faces, it's value 
remains unchanged.

The entries are to be used as follows:
- 1: primary axis size multiplier
- 2: primary axis x-coord multiplier
- 3: primary axis y-coord multiplier
- 4: primary axis offset multiplier
- 5: secondary axis size multiplier
- 6: secondary axis x-coord multiplier
- 7: secondary axis y-coord multiplier
- 8: secondary axis offset multiplier
--]]

local topFaceTranslation = { 
	[1] = {  1,  0,  0,  1,  				},
	[2] = {  1, -1,  0,  1,	 1,  0,  0,  1  },
	[3] = {  0,  0,  0,  0,  1, -1,  0,  1  },
	[4] = {  0,  1,  0,  0,  0,  0,  0,  0  },
	[5] = {  0,  0,  0,  0,  1, -1,  0,  1  },
	[6] = {  1,  0,  0,  1,  				},
}

local bottomFaceTranslation = {
	[1] = {  0,  0,  0,  0,  				},
	[2] = {  0,  1,  0,  0,	 1,  0,  0,  1  },
	[3] = {  1,  0,  0,  1,  1, -1,  0,  1  },
	[4] = {  1, -1,  0,  1,  0,  0,  0,  0  },
	[5] = {  0,  0,  0,  0,  				},
	[6] = {  1,  0,  0,  1,  1, -1,  0,  1  },
}

local leftFaceTranslation = {
	[1] = {  1,  0,  0,  1,  				},
	[2] = {  1,  0,  0,  1,	 				},
	[3] = {  1,  0,  0,  1,  				},
	[4] = {  1,  0,  0,  1,  				},
	[5] = {  0,  0,  1,  0,  0,  0,  0,  0  },
	[6] = {  1,  0, -1,  1,  1,  0,  0,  1  },
}

local rightFaceTranslation = {
	[1] = {  0,  0,  0,  0,  				},
	[2] = {  0,  0,  0,  0,	 				},
	[3] = {  0,  0,  0,  0,  				},
	[4] = {  0,  0,  0,  0,  				},
	[5] = {  1,  0, -1,  1,  1,  0,  0,  1  },
	[6] = {  1,  0, -1,  1,  1,  0,  0,  1  },	
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
		local xSizeF, xXF, xYF, xOff, ySizeF, yXF, yYF, yOff = unpack(leftFaceTranslation[face])
		x = size * xSizeF + ax * xXF + ay * xYF + xOff * dx

		if ySizeF then			
			y = size * ySizeF + ax * yXF + ay * yYF + yOff * dx
		end

		face = adjacentFaceMap[face][2]
	elseif nx >= size then
		local xSizeF, xXF, xYF, xOff, ySizeF, yXF, yYF, yOff = unpack(rightFaceTranslation[face])
		x = size * xSizeF + ax * xXF + ay * xYF - xOff * dx

		if ySizeF then			
			y = size * ySizeF + ax * yXF + ay * yYF - yOff * dx
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
		local ySizeF, yXF, yYF, yOff, xSizeF, xXF, xYF, xOff = unpack(topFaceTranslation[face])
		y = size * ySizeF + ax * yXF + ay * yYF + yOff * dy

		if xSizeF then			
			x = size * xSizeF + ax * xXF + ay * xYF + xOff * dy
		end

		face = adjacentFaceMap[face][1]
	elseif ny >= size then
		local ySizeF, yXF, yYF, yOff, xSizeF, xXF, xYF, xOff = unpack(bottomFaceTranslation[face])
		y = size * ySizeF + ax * yXF + ay * yYF - yOff * dy

		if xSizeF then			
			x = size * xSizeF + ax * xXF + ay * xYF - xOff * dy
		end

		face = adjacentFaceMap[face][3]
	else
		y = ny
	end

	return face, x, y
end

function CubeMapHelper.each(size)
	local finished = false

	local face, x, y, size = 1, -1, 0, size - 1

	return function()
		while not finished do
			x = x + 1

			if x > size then
				y = y + 1
				x = 0

				if y > size then
					face = face + 1
					y = 0

					if face > 6 then
						finished = true
					end
				end
			end

			if not finished then
				return face, x, y
			end
		end

		return nil
	end
end

return CubeMapHelper