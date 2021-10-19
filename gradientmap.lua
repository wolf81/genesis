local GradientMap = {}

local function gradient(size, orgin)
    local map = newArray2(size + 1, size + 1, nan)
    map.w = size
    map.h = size

    local half = map.h / 2 

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

    map.min = 0.0
    map.max = 1.0

    -- printArray2(map)

    return map
end

function GradientMap.create(size, origin)
    return gradient(2 ^ size, origin or { 0.5, 0.5 })
end

return GradientMap