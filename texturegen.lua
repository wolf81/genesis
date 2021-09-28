local TextureGen = {}
TextureGen.__index = TextureGen

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
				local value = 1.0 - tile:getHeightValue()

				love.graphics.setColor(value, value, value, 1.0)
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