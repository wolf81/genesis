local mmin, mmax, msqrt, mcos = math.min, math.max, math.sqrt, math.cos

local M = {}

--[[
local function squareGradient(size) 
    local values = {}

    local hsize = math.floor(size / 2)

    for face = 1, 6 do
        values[face] = {}

        if face < 5 then
            for x = 1, size do
                values[face][x] = {}
                for y = 1, size do
                    local v = y < hsize and 1.0 - y / hsize or (y - hsize) / hsize
                    values[face][x][y] = 1.0 - (v * 0.5)
                end
            end
        else
            for x = 1, size do
                values[face][x] = {}
                for y = 1, size do
                    values[face][x][y] = 0
                end
            end

            local ox, oy = hsize, hsize
            for n = hsize, 0, -1 do
                local d = hsize - n

                local y1, y2 = hsize - d, hsize + d
                local x1, x2 = hsize - d, hsize + d

                local v = 0.5 - ((hsize - d) / hsize * 0.5)

                for x = x1, x2 do
                    values[face][x][y1] = v
                    values[face][x][y2] = v
                end

                for y = y1, y2 do
                    values[face][x1][y] = v
                    values[face][x2][y] = v
                end
            end         
        end
    end

    return values, 0.0, 1.0
end
--]]

local function radialGradient(size)
    local values = {}

    local min, max = math.huge, -math.huge

    local hsize = size / 2

    for face = 1, 6 do
        values[face] = {}
        for x = 1, size do
            values[face][x] = {}
            for y = 1, size do
                local a = -hsize + x + 0.5
                local b = -hsize + y + 0.5
                local c = -hsize

                local dab = msqrt(a * a + b * b)
                local dabc = msqrt(dab * dab + c * c)
                local drds = 0.5 * dabc

                b = b / drds
                c = c / drds

                local gradientPos = { b, b, b, b, c, -c }

                local value = mcos(gradientPos[face])

                values[face][x][y] = value

                min = mmin(min, value)
                max = mmax(max, value)
            end
        end
    end

    return values, min, max
end

M.generate = function(size)
    local values, min, max = radialGradient(size)
    return values, min, max 
end

return M
