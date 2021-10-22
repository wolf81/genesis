local mpi, mcos, msin = math.pi, math.cos, math.sin
local r1, r2 = 0, 1.0
local g1, g2 = -math.sqrt(3) / 2, -0.5
local b1, b2 = math.sqrt(3) / 2, -0.5

function lerp(a, b, t)
	return a + (b - a) * t
end

--[[--
  @param h a real number between 0 and 2*pi
  @param s a real number between 0 and 1
  @param v a real number between 0 and 1
  @return r g b a
]]
function hsv(h, s, v, a)
  h = h + mpi / 2 --because the r vector is up
  
  local r, g, b = 1.0, 1.0, 1.0
  local h1, h2 = mcos(h), msin(h)
  
  --hue
  r = h1 * r1 + h2 * r2
  g = h1 * g1 + h2 * g2
  b = h1 * b1 + h2 * b2

  --saturation
  r = r + (1 - r) * s
  g = g + (1 - g) * s
  b = b + (1 - b) * s
  
  r, g, b = r * v, g * v, b * v
  
  return { r, g, b, a }
end