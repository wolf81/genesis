local DiamondSquare = require 'diamondsquare'

math.randomseed(os.time())

-- show live output in console, don't wait for app to close
io.stdout:setvbuf("no")

local size = 8

local maps = {}

local faceOffsets = {
	{ ox = 1, oy = 0 },
	{ ox = 0, oy = 1 },
	{ ox = 1, oy = 1 },
	{ ox = 2, oy = 1 },
	{ ox = 3, oy = 1 },
	{ ox = 1, oy = 2 },
}

local function printMap(map)
	local s = ''
	for x = 0, map.w do
		for y = 0, map.h do
			local v = map[x][y]
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
            local v = map[x][y]
            map[x][y] = (v - map.min) / (map.max - map.min)
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
				end
			end			
		end

		map = DiamondSquare.create(size, f)

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
		local ox, oy = faceOffsets[i].ox, faceOffsets[i].oy

		for x = 0, map.w do
			for y = 0, map.h do
				local v = map[x][y]
				local xi = x + (ox * map.w) + (ox * 2) + 0.5
				local yi = y + (oy * map.h) + (oy * 2) + 0.5

				love.graphics.setColor(v, v, v, 1.0)
				love.graphics.points(xi, yi)
			end
		end
	end
end