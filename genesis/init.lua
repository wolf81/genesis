local bband, brshift = bit.band, bit.rshift

local PATH = (...):gsub('%.init$', '')
local BitmaskOffsets = require(PATH .. '.bitmaskoffsets')
local generator = require(PATH .. '.generator')

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

M.Generator = generator

M.HeatType = require(PATH .. '.heattype')
M.BiomeType = require(PATH .. '.biometype')
M.HeightType = require(PATH .. '.heighttype')
M.MoistureType = require(PATH .. '.moisturetype')
M.EqualityFlags = require(PATH .. '.equalityflags')
M.CubeMapHelper = require(PATH .. '.cubemaphelper')

M.getBiomeType = function(tile)
    return bband(brshift(tile, BitmaskOffsets.BIOME_TYPE), 0xF)
end

M.getHeightType = function(tile)
    return bband(brshift(tile, BitmaskOffsets.HEIGHT_TYPE), 0xF)
end

M.getHeatType = function(tile)
    return bband(brshift(tile, BitmaskOffsets.HEAT_TYPE), 0x7)
end

M.getMoistureType = function(tile)
    return bband(brshift(tile, BitmaskOffsets.MOISTURE_TYPE), 0x7)
end

M.getHeightValue = function(tile)
    return bband(tile, 0xFF)
end

M.getBiomeAdjFlags = function(tile)
    return bband(brshift(tile, BitmaskOffsets.ADJ_BIOME_FLAGS), 0xF)
end

M.getHeightAdjFlags = function(tile)
    return bband(brshift(tile, BitmaskOffsets.ADJ_HEIGHT_FLAGS), 0xF)
end

return M
