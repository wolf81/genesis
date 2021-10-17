-- Heightmap module
-- Copyright (C) 2011 Marc Lepage
local DiamondSquare = {}

local min, max = math.min, math.max

local nan = 0/0

local function isnan(v)
    return v ~= v
end

local function random(magnitude)
    return (math.random() - 0.5) * magnitude
end 

-- Find power of two sufficient for size
local function pot(size)
    local pot = 2
    while true do
        if size <= pot then return pot end
        pot = 2*pot
    end
end

-- Create a table with 0 to n zero values
local function tcreate(n)
    local t = {}
    for i = 0, n do t[i] = nan end
    return t
end

-- Square step
-- Sets map[x][y] from square of radius d using height function f
local function square(map, x, y, d, f)
    local sum, num = 0, 0
    if 0 <= x-d then
        if   0 <= y-d   then sum, num = sum + map[x-d][y-d], num + 1 end
        if y+d <= map.h then sum, num = sum + map[x-d][y+d], num + 1 end
    end
    if x+d <= map.w then
        if   0 <= y-d   then sum, num = sum + map[x+d][y-d], num + 1 end
        if y+d <= map.h then sum, num = sum + map[x+d][y+d], num + 1 end
    end
    map[x][y] = sum/num + random(d)

    return map[x][y]
end

-- Diamond step
-- Sets map[x][y] from diamond of radius d using height function f
local function diamond(map, x, y, d, f)
    local sum, num = 0, 0
    if   0 <= x-d   then sum, num = sum + map[x-d][y], num + 1 end
    if x+d <= map.w then sum, num = sum + map[x+d][y], num + 1 end
    if   0 <= y-d   then sum, num = sum + map[x][y-d], num + 1 end
    if y+d <= map.h then sum, num = sum + map[x][y+d], num + 1 end
    map[x][y] = sum/num + random(d)

    return map[x][y]
end

-- Diamond square algorithm generates cloud/plasma fractal heightmap
-- http://en.wikipedia.org/wiki/Diamond-square_algorithm
-- Size must be power of two
-- Height function f must look like f(map, x, y, d, h) and return h'
local function diamondsquare(size, f)
    -- create map
    local map = { w = size, h = size }
    for c = 0, size do map[c] = tcreate(size) end
    -- seed four corners
    local d = size
    local v1, v2, v3, v4 = random(d), random(d), random(d), random(d)
    map[0][0] = v1
    map[0][d] = v2
    map[d][0] = v3
    map[d][d] = v4
    d = d/2

    local vmin = math.huge
    local vmax = -math.huge + 1
    local values = { v1, v2, v3, v4 }
    for _, v in ipairs(values) do
        vmin = math.min(vmin, v)
        vmax = math.max(vmax, v)
    end

    -- perform square and diamond steps
    while 1 <= d do

        for x = d, map.w-1, 2*d do
            for y = d, map.h-1, 2*d do
                local v = square(map, x, y, d, f)
                vmin = min(v, vmin)
                vmax = max(v, vmax)
            end
        end

        for x = d, map.w-1, 2*d do
            for y = 0, map.h, 2*d do
                local v = diamond(map, x, y, d, f)
                vmin = min(v, vmin)
                vmax = max(v, vmax)
            end
        end

        for x = 0, map.w, 2*d do
            for y = d, map.h-1, 2*d do
                local v = diamond(map, x, y, d, f)
                vmin = min(v, vmin)
                vmax = max(v, vmax)
            end
        end
        
        d = d/2
    end

    -- normalize values
    for x = 0, map.w do        
        for y = 0, map.h do
            local v = map[x][y]
            map[x][y] = (v - vmin) / (vmax - vmin)
        end
    end

    return map
end

-- Create a heightmap using the specified height function (or default)
-- map[x][y] where x from 0 to map.w and y from 0 to map.h
function DiamondSquare.create(size, f)
    return diamondsquare(2 ^ size)
end

return DiamondSquare