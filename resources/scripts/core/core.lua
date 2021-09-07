
--------------------------------------------------------------------------------
-- class
--! @brief Creates a new table inheriting metatable from another table
--! @param baseClass base class to inherit metatable from. Can be nil
--------------------------------------------------------------------------------
function class(baseClass)
	local result = {}
	result.__index = result
	setmetatable(result, baseClass)
	return result
end

--------------------------------------------------------------------------------
-- new
--! @brief Creates a new table given a base table to get metatable from
--------------------------------------------------------------------------------
function new(type)
	local result = {}
	setmetatable(result, type)
	return result
end


--------------------------------------------------------------------------------
-- set
--! @brief Creates a set from an array.
--! @param table array table
--------------------------------------------------------------------------------
function set(table)
	local result = {}
	for i = 1, #table do
		result[table[i]] = true
	end
	
	return result
end
