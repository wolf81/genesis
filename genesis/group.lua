local bbor, blshift = bit.bor, bit.lshift

local M = {}

local id = 0

local function getKey(face, x, y)
    -- TODO: maybe need a coord offsets? Or move the key functions to a separate coord module
    return bbor(blshift(face, 28), blshift(x, 14), y)
end

M.add = function(group, face, x, y)
    group.coords[getKey(face, x, y)] = { face, x, y }
    group.size = group.size + 1
end

M.remove = function(group, face, x, y)
    if M.contains(group, face, x, y) then
        group.coords[getKey(face, x, y)] = nil
        group.size = group.size - 1
    end
end

M.contains = function(group, face, x, y)
    return group.coordInfo[getKey(face, x, y)] ~= nil
end

M.iter = function(group)
    local k,v = nil, nil 

    return function()
        k, v = next(group.coords, k)

        if k == nil then return nil end

        return unpack(v)
    end
end

M.new = function(type)
    id = id + 1

    return {
        id = id,
        type = type,
        coords = {},
        size = 0,
    }
end

return M
