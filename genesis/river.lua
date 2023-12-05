local bbor, blshift = bit.bor, bit.lshift

local M = {}

local id = 0

local function getKey(face, x, y)
    return bbor(blshift(face, 28), blshift(x, 14), y)
end

M.contains = function(river, face, x, y)
    return river.coordInfo[getKey(face, x, y)] ~= nil
end

M.add = function(river, face, x, y)
    river.coordInfo[getKey(face, x, y)] = true

    -- TODO: does it make sense if river crosses itself?
    river.path[#river.path + 1] = { face, x, y }
    river.length = river.length + 1
end

M.new = function(direction)
    id = math.max(id + 1, 1) -- rivers always start at index 1, never negative

    return {
        direction = direction,
        id = id,
        turnCount = 0,
        length = 0,
        path = {},
        coordInfo = {},
        isValid = true,
    }
end

return M
