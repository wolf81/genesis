--[[
The CubeMap module provides functions for generating and dealing with cube maps. In order to better 
understand the functions, we should realize the cube map faces are ordered as such:
    
    5
	1 2 3 4
	6

In the above representation we see faces 1 to 4 are horizontally aligned with one another. Face 5 
is the top face and face 6 is the bottom face.

For each face, x- and y-coordinates go from top left to bottom right, as such:

	(1, 1), (2, 1), (3, 1)
	(1, 2), (2, 2), (3, 2)
	(1, 3), (2, 3), (3, 3) 

The CubeMap module can figure out the adjacent coordinate when moving between faces.
]]

local M = {}

--[[
The adjacent face map helps find neighbour faces for a given face number. The key is the current 
face number and the values are adjacent face numbers in order TOP, LEFT, BOTTOM, RIGHT.
--]]
local adjacentFaceMap = {
	[1] = { 5, 4, 6, 2 },
	[2] = { 5, 1, 6, 3 },
	[3] = { 5, 2, 6, 4 },
	[4] = { 5, 3, 6, 1 },
	[5] = { 3, 4, 1, 2 },
	[6] = { 1, 4, 3, 2 },
}

-- TODO: Maybe use a CubeMap layout as in GLSL, in which we have x-, y- and z-coords and coords run
-- from -x to +x, -y to +y, -z to +z. This approach might make it a bit more complicated to figure
-- out which face we're on, but perhaps this is not important. On the other hand, distance 
-- calculations might become easier / possible, which is something we don't have right now.

-- Find a coordinate on the cube map based on size, current coordinate & delta x- and y-values.
M.getCoord = function(size, face, x, y, dx, dy)
	face, x, y = M.getCoordDx(size, face, x, y, dx)
	return M.getCoordDy(size, face, x, y, dy)
end

-- Find a coordinate on the cube map based on size, current coordiante & delta x-value.
M.getCoordDx = function(size, face, x, y, dx)
	x = x + dx
	
	if x > size then
		local nextFace = adjacentFaceMap[face][4]
		
		if face == 5 then
			return M.getCoordDy(size, nextFace, size - y + 1, 0, x - size)
		elseif face == 6 then
			return M.getCoordDy(size, nextFace, y, size, size - x + 1)
		else
			return M.getCoordDx(size, nextFace, 0, y, x - size) -- (?) 1, x - size + 1
		end
	elseif x < 1 then
		local nextFace = adjacentFaceMap[face][2]

		if face == 5 then
			return M.getCoordDy(size, nextFace, y, 1, -x)
		elseif face == 6 then
			return M.getCoordDy(size, nextFace, size - y + 1, size, x)
		else
			return M.getCoordDx(size, nextFace, size, y, x)
		end
	end

	return face, x, y
end

-- Find a coordinate on the cube map based on size, current coordinate & delta y-value.
M.getCoordDy = function(size, face, x, y, dy)
	y = y + dy

	if y > size then
		local nextFace = adjacentFaceMap[face][3]

		if face == 2 then
			face, x, y = M.getCoordDx(size, nextFace, size, x, size - y + 1)			
		elseif face == 3 then
			face, x, y = M.getCoordDy(size, nextFace, size - x + 1, size, size - y + 1)
		elseif face == 4 then
			face, x, y = M.getCoordDx(size, nextFace, 0, size - x + 1, y - size) -- (?)			
		elseif face == 6 then
			face, x, y = M.getCoordDy(size, nextFace, size - x + 1, size, size - y + 1)
		else -- face: 1, 5
			face, x, y = M.getCoordDy(size, nextFace, x, 0, y - size) -- (?) 1, y - size + 1
		end
	elseif y < 1 then
		local nextFace = adjacentFaceMap[face][1]

		if face == 3 then
			face, x, y = M.getCoordDy(size, nextFace, size - x + 1, 1, -y)
		elseif face == 2 then
			face, x, y = M.getCoordDx(size, nextFace, size, size - x + 1, y)
		elseif face == 4 then
			face, x, y = M.getCoordDx(size, nextFace, 1, x, -y)	
		elseif face == 5 then
			face, x, y = M.getCoordDy(size, nextFace, size - x + 1, 1, -y)
		else -- face: 1, 6
			face, x, y = M.getCoordDy(size, nextFace, x, size, y)
		end
	end

	return face, x, y
end

-- Iterate over positions and values in a cube map, which can be done as follows:
--
-- 	for face, x, y, val in CubeMap.iter do
--	   -- do something
-- 	end
M.iter = function(cubeMap)
	local face, x, y = 1, 0, 1
	local size = #cubeMap[1]

	return function()
		while true do
			x = x + 1
			if x > size then
				y = y + 1
				x = 1
				if y > size then
					face = face + 1
					x = 1
					y = 1
					if face > 6 then return nil end
				end
			end

			return face, x, y, cubeMap[face][x][y]
		end
	end
end

-- Create a new CubeMap of a given size. Optionally provide a function to set a value at a position.
-- If no function is provided, all values will be initially set to 0. Use as such:
--
--	var cubeMap = CubeMap.new(25, function(face, x, y) return x + y end)
--    --or--
-- 	var cubeMap = CubeMap.new(50)
M.new = function(size, fn)
	local cubeMap = {}

	fn = fn or function() return 0 end

	for face = 1, 6 do
		cubeMap[face] = {}
		for x = 1, size do
			cubeMap[face][x] = {}
			for y = 1, size do
				cubeMap[face][x][y] = fn(face, x, y)
			end
		end
	end

	return cubeMap
end

return M
