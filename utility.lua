-- not a number
nan = 0/0

-- check if value v is not a number
function isnan(v)
    return v ~= v
end

-- create a 2-dimensional zero-indexed array with default value v or 0
function newArray2(w, h, v)
	local t = {}

	for y = 0, h - 1 do
		t[y] = {}
		for x = 0, w - 1 do
			t[y][x] = v or 0
		end
	end

	return t
end

-- print contents of 2-dimensional array
function printArray2(map)
    local s = ''
    for x = 0, #map do
        for y = 0, #map[0] do
            local v = map[y][x]
            s = s .. string.format('%.2f\t', v)
        end
        s = s .. '\n'
    end 
    print(s)
end