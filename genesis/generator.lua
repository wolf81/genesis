local PATH = (...):match('(.-)[^%.]+$') 
local noiseMap = require(PATH .. 'noisemap')
local gradientMap = require(PATH .. 'gradientmap')
local combineMap = require(PATH .. 'combinemap')

local mmin, mmax = math.min, math.max

local generator = {}

local function normalize(value, min, max)
	return (value - min) / (max - min)
end

generator.generate = function(size, seed, seaLevel)
	local tileMaps = {}

	seaLevel = seaLevel or 0.6
	local oceanLevel = seaLevel * 0.7
	local coastLevel = seaLevel + 0.02

	local heightMap, heightMin, heightMax = noiseMap.generate(size, seed % 128, 6, 0.5)

	local heatNoiseMap, _, _ = noiseMap.generate(size, seed % 64, 4, 2.0)
	local heatGradientMap, _, _ = gradientMap.generate(size, 4, 3.0)
	local heatMap, heatMin, heatMax = combineMap.generate(size, heatNoiseMap, heatGradientMap)

	local moistureMap, moistureMin, moistureMax = noiseMap.generate(size, seed % 32, 4, 2.0)

	-- could be a 2 dimensional array, the face could be an x-offset

	local tileMap = {}

	for face = 1, 6 do
		tileMap[face] = {}

		for x = 1, size do
			tileMap[face][x] = {}

			for y = 1, size do
				local height = normalize(heightMap[face][x][y], heightMin, heightMax)
				local heat = normalize(heatMap[face][x][y], heatMin, heatMax)
				local moisture = normalize(moistureMap[face][x][y], moistureMin, moistureMax)

				if height <= oceanLevel then
					moisture = mmin(moisture + 8 * height, 1.0)
				elseif height <= seaLevel then
					moisture = mmin(moisture + 3 * height, 1.0)
				elseif height <= coastLevel then
					moisture = mmin(moisture + height, 1.0)
				end

				local heatOffset = (1.0 - seaLevel) / 4

				if height >= (seaLevel + heatOffset * 3) then
					heat = mmax(heat - height * 0.4, 0.0)
				elseif height >= (seaLevel + heatOffset * 2) then
					heat = mmax(heat - height * 0.3, 0.0)
				elseif height >= (seaLevel + heatOffset) then
					heat = mmax(heat - height * 0.2, 0.0)
				elseif height >= coastLevel then
					heat = mmax(heat - height * 0.1, 0.0)
				end				

				tileMap[face][x][y] = bit.bor(
					bit.lshift(height * 255, 16),
					bit.lshift(heat * 255, 8),
					moisture * 255)

				--[[ 
				remaining 8 bits for: ?
				- isCollidable
				- neighbours
				- ?
				--]] 
			end
		end
	end

	return tileMap
end

return generator
