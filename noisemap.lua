require 'utility'

local NoiseMap = {}

local min, max, huge = math.min, math.max, math.huge

local function random(scale)
    return (math.random() - 0.5) * scale
end 

local function getMinMaxValues(map)
    local vmin = huge
    local vmax = -huge
    for x = 0, map.w do
        for y = 0, map.h do
            local v = map[y][x]
            vmin = min(v, vmin)
            vmax = max(v, vmax)
        end
    end

    return vmin, vmax
end

-- Square step
-- Sets map[x][y] from square of radius d using height function f
local function square(map, x, y, d, f)
    local sum, num = 0, 0
    if 0 <= x - d then
        if 0 <= y - d then sum, num = sum + map[y - d][x - d], num + 1 end
        if y + d <= map.h then sum, num = sum + map[y + d][x - d], num + 1 end
    end
    if x + d <= map.w then
        if 0 <= y - d then sum, num = sum + map[y - d][x + d], num + 1 end
        if y + d <= map.h then sum, num = sum + map[y + d][x + d], num + 1 end
    end
    map[y][x] = sum / num + random(d)
end

-- Diamond step
-- Sets map[x][y] from diamond of radius d using height function f
local function diamond(map, x, y, d, f)
    local sum, num = 0, 0
    if 0 <= x-d then sum, num = sum + map[y][x - d], num + 1 end
    if x + d <= map.w then sum, num = sum + map[y][x + d], num + 1 end
    if 0 <= y-d then sum, num = sum + map[y - d][x], num + 1 end
    if y + d <= map.h then sum, num = sum + map[y + d][x], num + 1 end
    map[y][x] = sum / num + random(d)
end

-- Diamond square algorithm generates cloud/plasma fractal heightmap
-- http://en.wikipedia.org/wiki/Diamond-square_algorithm
-- Size must be power of two
-- Height function f must look like f(map, x, y, d, h) and return h'
local function diamondSquare(size, f)
    -- create 2d array
    local map = newArray2(size + 1, size + 1, nan)
    map.w = size
    map.h = size

    -- seed four corners
    local d = size
    map[0][0] = random(d)
    map[0][d] = random(d)
    map[d][0] = random(d)
    map[d][d] = random(d)
    d = d/2

    -- call initializer function
    f(map)

    -- perform square and diamond steps
    while 1 <= d do
        local d2 = 2 * d

        for y = d, map.h - 1, d2 do
            for x = d, map.w - 1, d2 do
                if isnan(map[y][x]) then
                    square(map, x, y, d, f)
                end
            end
        end

        for y = 0, map.h, d2 do
            for x = d, map.w - 1, d2 do
                if isnan(map[y][x]) then
                    diamond(map, x, y, d, f)
                end
            end
        end

        for y = d, map.h - 1, d2 do
            for x = 0, map.w, d2 do
                if isnan(map[y][x]) then
                    diamond(map, x, y, d, f)
                end
            end
        end
        
        d = d/2
    end

    -- find min and max values
    local vmin, vmax = getMinMaxValues(map)
    map.max = vmax
    map.min = vmin

    --printArray2(map)

    return map
end

function NoiseMap.create(size, f)
    return diamondSquare(2 ^ size, f or function(map) end)
end

return NoiseMap