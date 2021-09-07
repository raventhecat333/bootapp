--
-- Conversion helper from HTTP codes to Lightning specific error codes.
-- Note that we omit the "090-" at the beginning to return only the last four digits.

function convertToLightningErrorCode(httpCode)
	local hundred = math.floor(httpCode / 100)
	local remainder = math.floor(httpCode % 100)
	if hundred == 4 and remainder <= 39 then
		return 2800 + remainder
	elseif hundred == 5 and remainder <= 19 then
		return 2840 + remainder
	elseif hundred == 3 and remainder <= 9 then
		return 2860 + remainder
	elseif hundred == 2 and remainder <= 9 then
		return 2870 + remainder
	elseif hundred == 1 and remainder <= 9 then
		return 2880 + remainder
	end
	
	return 2890 + hundred;
end