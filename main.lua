local DiamondSquare = require 'diamondsquare'

math.randomseed(os.time())

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

local size = 8

local maps = {}

local faceInfo = {
	min = math.huge,
	max = -math.huge,

	offsets = {
					{ 1, 0 },
		{ 0, 1 }, 	{ 1, 1 },	{ 2, 1 },	{ 3, 1 },
					{ 1, 2 },
	}
}

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

local function normalizeMap(map)
    -- normalize values in range 0.0 - 1.0
    for x = 0, map.w do        
        for y = 0, map.h do
            local v = map[y][x]
            map[y][x] = (v - faceInfo.min) / (faceInfo.max - faceInfo.min)
        end
    end
end

function love.load()
	love.window.setTitle('Genesis')

	local _ = love.window.setMode(1280, 800, {})

	local vmin, vmax = 1.0, 0.0

	for i = 1, 6 do
		local f = nil

		if i == 2 then
			f = function(map)
				for j = 0, map.h do
					map[j][0] = maps[1][0][j]
				end
			end
		elseif i == 3 then
			f = function(map)
				for j = 0, map.w do
					map[j][0] = maps[1][j][map.h]
					map[0][j] = maps[2][map.w][j]
				end
			end			
		elseif i == 4 then
			f = function(map)
				for j = 0, map.h do
					map[0][j] = maps[3][map.w][j]
					map[j][0] = maps[1][map.w][map.w - j]
				end
			end					
		elseif i == 5 then
			f = function(map)
				for j = 0, map.h do
					map[0][j] = maps[4][map.w][j]
					map[j][0] = maps[1][map.w - j][0]
					map[map.w][j] = maps[2][0][j]
				end
			end
		elseif i == 6 then
			f = function(map)
				for j = 0, map.w do
					map[j][0] = maps[3][j][map.h]
					map[0][j] = maps[2][map.w - j][map.h]
					map[map.w][j] = maps[4][j][map.h]
					map[j][map.h] = maps[5][map.w - j][map.h]
				end
			end			
		end

		map = DiamondSquare.create(size, f)

		faceInfo.min = math.min(faceInfo.min, map.min)
		faceInfo.max = math.max(faceInfo.max, map.max)

		maps[#maps + 1] = map

		map.ox = (i - 1) % 4
		map.oy = math.floor((i - 1) / 4)

		--printMap(map)
	end

	for i = 1, 6 do
		normalizeMap(maps[i])
		--printMap(maps[i])
	end
end

function love.draw()
	for i, map in ipairs(maps) do
		local ox, oy = unpack(faceInfo.offsets[i])

		for x = 0, map.w do
			for y = 0, map.h do
				local v = map[x][y]
				local xi = x + (ox * map.w) --[[+ (ox * 2)--]] + 0.5
				local yi = y + (oy * map.h) --[[+ (oy * 2)--]] + 0.5

				love.graphics.setColor(v, v, v, 1.0)
				love.graphics.points(xi, yi)
			end
		end
	end
end