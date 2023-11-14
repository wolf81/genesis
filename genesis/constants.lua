local PATH = (...):match('(.-)[^%.]+$') 
local readonly = require(PATH .. 'readonly')

-- local HeightType = readonly {
-- 	SNOW,
-- 	MOUNTAIN,
-- 	FOREST,
-- 	PLAIN,
-- 	COAST,
-- 	RIVER,
-- 	SHALLOW_WATER,
-- 	DEEP_WATER,
-- }

-- local Flags = readonly {
-- 	HEIGHT 	 = 0x00FF0000,
-- 	HEAT     = 0x0000FF00,
-- 	MOISTURE = 0x000000FF,
-- }