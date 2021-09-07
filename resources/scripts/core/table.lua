
-- Print a table
function printTable(tbl, depth)
	
	if depth == nil then
		depth = 0
	end
	
	local spaceIn = string.rep('    ', depth + 1)
	local spaceOut = string.rep('    ', depth)
    print(spaceOut .. '{')
    
    for key, val in pairs(tbl) do
        if type(val) == 'table' then
        	if type(key) == 'string' then
            	print(spaceIn .. tostring(key) .. ' = ')
           	end
            printTable(val, depth + 1)
        else
            print(spaceIn .. tostring(key) .. ' = ' .. tostring(val))
        end
    end
    
    print(spaceOut .. '}')
end

