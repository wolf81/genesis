local GradientMap = {}
GradientMap.__index = GradientMap

--[[
local function square(size) 
    local map = {}

    local hsize = math.floor(size / 2)

    for face = 1, 6 do
    	map[face] = {}

    	if face < 5 then
		    for x = 0, size - 1 do
	    		map[face][x] = {}
	    		for y = 0, size - 1 do
	    			local v = (y < hsize and 
	    				1.0 - y / hsize or 
	    				(y - hsize) / hsize
	    			)
		    		map[face][x][y] = 1.0 - (v * 0.5)
		    	end
		    end
		else
			for x = 0, size - 1 do
				map[face][x] = {}
				for y = 0, size - 1 do
					map[face][x][y] = 0
				end
			end

	    	local ox, oy = hsize, hsize
		    for n = hsize, 0, -1 do
		    	local d = hsize - n

		    	local y1, y2 = hsize - d, hsize + d
		    	local x1, x2 = hsize - d, hsize + d

		    	local v = 0.5 - ((hsize - d) / hsize * 0.5)

		    	for x = x1, x2 do
		    		map[face][x][y1] = v
		    		map[face][x][y2] = v
		    	end

		    	for y = y1, y2 do
		    		map[face][x1][y] = v
		    		map[face][x2][y] = v
		    	end
		    end			
    	end
    end

    -- for i = 1, 6 do
    -- 	printArray2(map[i])
    -- end

    return map
end
--]]

local function gradient(size)
	local map = {}

	local vmin = math.huge
	local vmax = -math.huge

	local hsize = size / 2

	for face = 1, 6 do
		map[face] = {}
		for x = 0, size - 1 do
			map[face][x] = {}
			for y = 0, size - 1 do
				local a = -hsize + x + 0.5
				local b = -hsize + y + 0.5
				local c = -hsize

				local dab = math.sqrt(a * a + b * b)
				local dabc = math.sqrt(dab * dab + c * c)
				local drds = 0.5 * dabc

				b = b / drds
				c = c / drds

				local gradientPos = { b, b, b, b, c, -c }

				local value = math.cos(gradientPos[face])

				map[face][x][y] = value

				vmin = math.min(vmin, value)
				vmax = math.max(vmax, value)
			end
		end
	end

	-- normalize to 0.0 ... 1.0 range
	for face = 1, 6 do
		for x = 0, size - 1 do
			for y = 0, size - 1 do
				local v = map[face][x][y]
				map[face][x][y] = (v - vmin) / (vmax - vmin)
			end
		end		
	end

	-- printArray2(map)

	return map   
end

function GradientMap:new(size)
	local size = 2 ^ size + 1

	return setmetatable({
		_size = size,
		_map = gradient(size)
	}, GradientMap)
end

function GradientMap:getSize()
	return self._size, self._size
end

function GradientMap:getValue(face, x, y)
	return self._map[face][x][y]
end

return setmetatable(GradientMap, {
	__call = GradientMap.new
})
