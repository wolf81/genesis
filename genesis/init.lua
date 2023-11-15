local bband, brshift = bit.band, bit.rshift

local PATH = (...):gsub('%.init$', '')
local BitmaskOffsets = require(PATH .. '.bitmaskoffsets')

local M = {
    _VERSION = '0.1.0',
    _DESCRIPTION = 'A random world generator',
    _URL = 'https://github.com/wolf81/genesis',
    _LICENSE = [[ 
MIT License

Copyright (c) 2023 Wolftrail

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
    ]], 
}

local generator = require(PATH .. '.generator')

M.generate = generator.generate

M.BiomeType = require(PATH .. '.biometype')

M.getBiomeType = function(tile)
    return bband(brshift(tile, BitmaskOffsets.BIOME), 0xF)
end

M.getHeightValue = function(tile)
    return bband(brshift(tile, BitmaskOffsets.HEIGHT), 0xFF)
end

M.getHeatValue = function(tile)
    return bband(brshift(tile, BitmaskOffsets.HEAT), 0x7)
end

M.getMoistureValue = function(tile)
    return bband(tile, 0x7)
end

M.eachTile = function(tileMap, fn)
    local size = #tileMap[face]
    
    for face = 1, 6 do
        for x = 1, size do
            for y = 1, size do
                fn(tileMap[face][x][y], face, x, y)
            end
        end
    end
end

return M
