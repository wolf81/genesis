require 'constants'

local TextureGen = {}
TextureGen.__index = TextureGen

function TextureGen:new()
	return setmetatable({}, TextureGen)
end

function TextureGen:generateHeatMap(width, height, tiles)
	local texture = love.graphics.newCanvas(width, height)

	love.graphics.setCanvas(texture)
	do
		for y = 0, height - 1 do
			for x = 0, width - 1 do
				local tile = tiles[y][x]

				local heatType = tile:getHeatType()
				local color = HeatType.getColor(heatType)

				if tile:getBitmask() ~= 15 then
					color = { color[1] * 0.4, color[2] * 0.4, color[3] * 0.4, 1 }
				end

				love.graphics.setColor(color)
				love.graphics.points(x + 0.5, y + 0.5)
			end
		end

		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	end
	love.graphics.setCanvas()

	return texture
end

function TextureGen:generateHeightMap(width, height, tiles)
	local texture = love.graphics.newCanvas(width, height)

	love.graphics.setCanvas(texture)
	do
		love.graphics.clear()

		for y = 0, height - 1 do
			for x = 0, width - 1 do
				local tile = tiles[y][x]
				local terrainType = tile:getTerrainType()
				local color = TerrainType.getColor(terrainType)

				if tile:getBitmask() ~= 15 then
					color = { color[1] * 0.4, color[2] * 0.4, color[3] * 0.4, 1 }
				end

				love.graphics.setColor(color)
				love.graphics.points(x + 0.5, y + 0.5)
			end
		end

		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	end
	love.graphics.setCanvas()

	return texture
end

function TextureGen:generateMoistureMap(width, height, tiles)
	local texture = love.graphics.newCanvas(width, height)

	love.graphics.setCanvas(texture)
	do
		love.graphics.clear()

		for y = 0, height - 1 do
			for x = 0, width - 1 do
				local tile = tiles[y][x]
				local color = { 0.5, 0.5, 0.5, 1.0 }

				if tile:getBitmask() ~= 15 then
					color = { color[1] * 0.4, color[2] * 0.4, color[3] * 0.4, 1 }
				end

				love.graphics.setColor(color)
				love.graphics.points(x + 0.5, y + 0.5)
			end
		end

		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	end		
	love.graphics.setCanvas()

	return texture
end

return setmetatable(TextureGen, {
	__call = TextureGen.new
})