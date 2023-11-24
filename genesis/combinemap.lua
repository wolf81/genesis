local mmin, mmax = math.min, math.max

local combineMap = {}

local function multiply(size, maps)
    local mapCount = #maps

    local values = {}

    local min, max = math.huge, -math.huge

    for face = 1, 6 do
        values[face] = {}

        for x = 1, size do
            values[face][x] = {}

            for y = 1, size do
                local v = 0
                for i = 1, mapCount do
                    v = v + maps[i][face][x][y]
                end
                v = v / mapCount                
                values[face][x][y] = v

                min = mmin(min, v)
                max = mmax(max, v)
            end
        end
    end

    return values, min, max
end

combineMap.generate = function(size, ...)
    local maps = {...}
    local values, min, max = multiply(size, maps)
    return values, min, max
end

return combineMap
