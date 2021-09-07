Math = {}

--! @brief Performs a linear interpolation between from and to using ratio t
--! @param from first value
--! @param to second value
--! @param t ratio value
--! @return interpolated value
function Math.lerp(from, to, t)
	return from + (to - from) * t
end

--! @brief Clamps a value inside a given range
--! @param value value to clamp
--! @param min range minimum value
--! @param max range maximum value
--! @return Clamped value
function Math.clamp(value, min, max)
	if value <= min then
		return min
	elseif value >= max then
		return max
	else
		return value
	end
end

--! @brief Rounds a value to the nearest provided multiple value
--! @param num value to round
--! @param idp multiple value to round to
--! @return rounded value
function Math.round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end