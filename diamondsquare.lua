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
        if   0 <= y-d   then sum, num = sum + map[y-d][x-d], num + 1 end
        if y+d <= map.h then sum, num = sum + map[y+d][x-d], num + 1 end
    end
    if x+d <= map.w then
        if   0 <= y-d   then sum, num = sum + map[y-d][x+d], num + 1 end
        if y+d <= map.h then sum, num = sum + map[y+d][x+d], num + 1 end
    end
    map[y][x] = sum/num + random(d)
end

-- Diamond step
-- Sets map[x][y] from diamond of radius d using height function f
local function diamond(map, x, y, d, f)
    local sum, num = 0, 0
    if   0 <= x-d   then sum, num = sum + map[y][x-d], num + 1 end
    if x+d <= map.w then sum, num = sum + map[y][x+d], num + 1 end
    if   0 <= y-d   then sum, num = sum + map[y-d][x], num + 1 end
    if y+d <= map.h then sum, num = sum + map[y+d][x], num + 1 end
    map[y][x] = sum/num + random(d)
end

local function printMap(map)
    local s = ''
    for x = 0, map.w do
        for y = 0, map.h do
            local v = map[y][x]
            s = s .. string.format('%.2f\t', v)
        end
        s = s .. '\n'
    end 
    print(s)
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
    map[0][0] = random(d)
    map[0][d] = random(d)
    map[d][0] = random(d)
    map[d][d] = random(d)
    d = d/2

    -- call initializer function
    f(map)

    -- perform square and diamond steps
    while 1 <= d do
        for x = d, map.w-1, 2*d do
            for y = d, map.h-1, 2*d do
                if isnan(map[y][x]) then
                    square(map, x, y, d, f)
                end
            end
        end

        for x = d, map.w-1, 2*d do
            for y = 0, map.h, 2*d do
                if isnan(map[y][x]) then
                    diamond(map, x, y, d, f)
                end
            end
        end

        for x = 0, map.w, 2*d do
            for y = d, map.h-1, 2*d do
                if isnan(map[y][x]) then
                    diamond(map, x, y, d, f)
                end
            end
        end
        
        d = d/2
    end

    -- find min and max values
    local vmin = math.huge
    local vmax = -math.huge
    for x = 0, map.w do
        for y = 0, map.h do
            local v = map[y][x]
            vmin = min(v, vmin)
            vmax = max(v, vmax)
        end
    end

    map.max = vmax
    map.min = vmin

    return map
end

function DiamondSquare.create(size, f)
    return diamondsquare(2 ^ size, f or function(map) end)
end

return DiamondSquare