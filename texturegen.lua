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

function TextureGen:new(width, height, tiles)
	return setmetatable({
		_width = width,
		_height = height,
		_tiles = tiles,
	}, TextureGen)
end

function TextureGen:generate()
	local texture = love.graphics.newCanvas(self._width, self._height)

	love.graphics.setCanvas(texture)
	do
		love.graphics.clear()

		for y = 0, self._height - 1 do
			for x = 0, self._width - 1 do
				local tile = self._tiles[y][x]
				local heightType = tile:getHeightType()
				local color = getColor(heightType)

				if tile:getBitmask() ~= 15 then
					color = { color[1] * 0.4, color[2] * 0.4, color[3] * 0.7, 1 }
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