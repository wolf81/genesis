local PATH = (...):gsub('%.init$', '')

local M = {
    _VERSION = "0.1.1",
    _DESCRIPTION = "A random world generator",
    _URL = "https://github.com/wolf81/genesis",
    _LICENSE = [[ 
MIT License

Copyright (c) 2018 Wolftrail

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

-- TODO: it's a bit ugly the way Constants & Functions are loaded into the global namespace
M.Genesis = require(PATH .. '.genesis')
M.Functions = require(PATH .. '.functions')
M.CubemapHelper = require(PATH .. '.cubemaphelper')
M.Tile = require(PATH .. '.tile')

return M