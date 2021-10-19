local GradientMap = {}

local function gradient(size, iscenter)
    local map = newArray2(size + 1, size + 1, nan)
    map.w = size
    map.h = size

    local half = map.h / 2 

    if not iscenter then
	    for y = 0, map.h do
	    	for x = 0, map.w do
	    		if y < half then
	    			map[x][y] = 1.0 - y / half
	    		else
	    			map[x][y] = ((y - half) / half)
	    		end

	    		map[x][y] = map[x][y] * 0.5
	    	end
	    end
	else
	    local ox, oy = half, half
	    for n = half, 0, -1 do
	    	local d = half - n

	    	local y1, y2 = half - d, half + d
	    	local x1, x2 = half - d, half + d

	    	local v = ((half - d) / half * 0.5) + 0.5

	    	for x = x1, x2 do
	    		map[x][y1] = v
	    		map[x][y2] = v
	    	end

	    	for y = y1 + 1, y2 - 1 do
	    		map[x1][y] = v
	    		map[x2][y] = v
	    	end
	    end
    end

    map.min = 0.0
    map.max = 1.0

    -- printArray2(map)

    return map
end

function GradientMap.create(size, iscenter)
    return gradient(2 ^ size, iscenter)
end

return GradientMap