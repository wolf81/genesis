--[[
The cubeMapHelper class provides utility functions for dealing with cube maps. 
In order to better understand the functions, we should realize the cubemap faces 
are ordered as such:
    
    5
	1 2 3 4
	6

In the above representation we see faces 1 to 4 are horizontally aligned with 
one another. Face 5 is the top face and face 6 is the bottom face.
]]

local cubeMapHelper = {}

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

function cubeMapHelper.getCoord(face, size, x, y, dx, dy)
	face, x, y = CubeMapHelper.getCoordDx(face, size, x, y, dx)
	return CubeMapHelper.getCoordDy(face, size, x, y, dy)
end

function cubeMapHelper.getCoordDx(face, size, x, y, dx)
	-- print('getCoordDx', face, x, y, dx)
	x = x + dx
	
	if x > size then
		local nextFace = adjacentFaceMap[face][4]
		
		if face == 5 then
			return cubeMapHelper.getCoordDy(nextFace, size, size - y + 1, 0, x - size)
		elseif face == 6 then
			return cubeMapHelper.getCoordDy(nextFace, size, y, size, size - x + 1)
		else
			return cubeMapHelper.getCoordDx(nextFace, size, 0, y, x - size) -- (?) 1, x - size + 1
		end
	elseif x < 1 then
		local nextFace = adjacentFaceMap[face][2]

		if face == 5 then
			return cubeMapHelper.getCoordDy(nextFace, size, y, 1, -x)
		elseif face == 6 then
			return cubeMapHelper.getCoordDy(nextFace, size, size - y + 1, size, x)
		else
			return cubeMapHelper.getCoordDx(nextFace, size, size, y, x)
		end
	end

	return face, x, y
end

function cubeMapHelper.getCoordDy(face, size, x, y, dy)
	-- print('getCoordDy', face, x, y, dy)
	y = y + dy

	if y > size then
		local nextFace = adjacentFaceMap[face][3]

		if face == 2 then
			face, x, y = cubeMapHelper.getCoordDx(nextFace, size, size, x, size - y + 1)			
		elseif face == 3 then
			face, x, y = cubeMapHelper.getCoordDy(nextFace, size, size - x + 1, size, size - y + 1)
		elseif face == 4 then
			face, x, y = cubeMapHelper.getCoordDx(nextFace, size, 0, size - x + 1, y - size) -- (?)			
		elseif face == 6 then
			face, x, y = cubeMapHelper.getCoordDy(nextFace, size, size - x + 1, size, size - y + 1)
		else -- face: 1, 5
			face, x, y = cubeMapHelper.getCoordDy(nextFace, size, x, 0, y - size) -- (?) 1, y - size + 1
		end
	elseif y < 1 then
		local nextFace = adjacentFaceMap[face][1]

		if face == 3 then
			face, x, y = cubeMapHelper.getCoordDy(nextFace, size, size - x + 1, 1, -y)
		elseif face == 2 then
			face, x, y = cubeMapHelper.getCoordDx(nextFace, size, size, size - x + 1, y)
		elseif face == 4 then
			face, x, y = cubeMapHelper.getCoordDx(nextFace, size, 1, x, -y)	
		elseif face == 5 then
			face, x, y = cubeMapHelper.getCoordDy(nextFace, size, size - x + 1, 1, -y)
		else -- face: 1, 6
			face, x, y = cubeMapHelper.getCoordDy(nextFace, size, x, size, y)
		end
	end

	return face, x, y
end

return cubeMapHelper
