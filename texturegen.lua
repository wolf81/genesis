local TextureGen = {}
TextureGen.__index = TextureGen

local function getColor(heightType)
	if heightType == 'deepWater' then 
		return { 0.0, 0.0, 0.5, 1.0 }
	elseif heightType == 'shallowWater' then 
		return { 25/255, 25/255, 150/255, 1.0 }
	elseif heightType == 'sand' then 
		return { 240/255, 240/255, 64/255, 1.0 }
	elseif heightType == 'grass' then 
		return { 50/255, 220/255, 20/255, 1.0 }
	elseif heightType == 'forest' then 
		return { 16/255, 160/255, 0.0, 1.0 }
	elseif heightType == 'mountain' then 
		return { 0.5, 0.5, 0.5, 1.0 }
	end
	
	return { 1.0, 1.0, 1.0, 1.0 }
end

function TextureGen:new()
	return setmetatable({}, TextureGen)
end

function TextureGen:generateHeatmap(width, height, tiles)
	local texture = love.graphics.newCanvas(width, height)

	love.graphics.setCanvas(texture)
	do
		for y = 0, height - 1 do
			for x = 0, width - 1 do
				local tile = tiles[y][x]

				local heatValue = tile:getHeatValue()
				local g = 1.0 - 2 * math.abs((y / height) - 0.5);
				local r = (1.0 - heatValue) * g
				local b = 1.0 - r
				local color = { r, 0.0, b, 1.0 }

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

function TextureGen:generateHeightmap(width, height, tiles)
	local texture = love.graphics.newCanvas(width, height)

	love.graphics.setCanvas(texture)
	do
		love.graphics.clear()

		for y = 0, height - 1 do
			for x = 0, width - 1 do
				local tile = tiles[y][x]
				local heightType = tile:getHeightType()
				local color = getColor(heightType)

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