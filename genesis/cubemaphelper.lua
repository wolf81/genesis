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

function CubeMapHelper.getCoord(face, size, x, y, dx, dy)
	local face, x, y = CubeMapHelper.getCoordDx(face, size, x, y, dx)
	return CubeMapHelper.getCoordDy(face, size, x, y, dy)
end

function CubeMapHelper.getCoordDx(face, size, x, y, dx)
	local x = x + dx

	if x > size then
		dx = x - size

		local nextFace = adjacentFaceMap[face][4]

		if face == 5 then
			face, x, y = CubeMapHelper.getCoordDy(nextFace, size, size - y + 1, 1, dx)
		elseif face == 6 then			
			face, x, y = CubeMapHelper.getCoordDy(nextFace, size, y, size, -(dx))
		else
			face, x, y = CubeMapHelper.getCoordDx(nextFace, size, 1, y, dx)
		end

	elseif x < 1 then
		dx = x + size

		local nextFace = adjacentFaceMap[face][2]

		if face == 5 then
			face, x, y = CubeMapHelper.getCoordDy(nextFace, size, y, 1, size - dx)
		elseif face == 6 then
			face, x, y = CubeMapHelper.getCoordDy(nextFace, size, size - y + 1, size, -(size - dx))
		else
			face, x, y = CubeMapHelper.getCoordDx(nextFace, size, size, y, -(size - dx))
		end
	end

	return face, x, y
end

function CubeMapHelper.getCoordDy(face, size, x, y, dy)
	local y = y + dy

	if y > size then		
		dy = y - size

		local nextFace = adjacentFaceMap[face][3]

		if face == 2 then
			face, x, y = CubeMapHelper.getCoordDx(nextFace, size, size, x, -(dy))			
		elseif face == 3 then
			face, x, y = CubeMapHelper.getCoordDy(nextFace, size, size - x + 1, size, -(dy))
		elseif face == 4 then
			face, x, y = CubeMapHelper.getCoordDx(nextFace, size, 1, size - x + 1, dy)			
		elseif face == 6 then
			face, x, y = CubeMapHelper.getCoordDy(nextFace, size, size - x + 1, size, -(dy))
		else -- face: 2, 5
			face, x, y = CubeMapHelper.getCoordDy(nextFace, size, x, 1, dy)
		end
	elseif y < 1 then
		dy = y + size

		local nextFace = adjacentFaceMap[face][1]

		if face == 3 then
			face, x, y = CubeMapHelper.getCoordDy(nextFace, size, size - x + 1, 1, size - dy)
		elseif face == 2 then
			face, x, y = CubeMapHelper.getCoordDx(nextFace, size, size, size - x + 1, -(size - dy))
		elseif face == 4 then
			face, x, y = CubeMapHelper.getCoordDx(nextFace, size, 1, x, size - dy)	
		elseif face == 5 then
			face, x, y = CubeMapHelper.getCoordDy(nextFace, size, size - x + 1, 1, size - dy)
		else -- face: 1, 6
			face, x, y = CubeMapHelper.getCoordDy(nextFace, size, x, size, -(size - dy))
		end
	end

	return face, x, y
end

function CubeMapHelper.each(size)
	local finished = false

	local face, x, y = 1, 0, 1

	return function()
		while not finished do
			x = x + 1

			if x > size then
				y = y + 1
				x = 1

				if y > size then
					face = face + 1
					y = 1

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
