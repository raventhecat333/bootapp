---
-- @param something scalar}table
-- @param name string name describing the debug output (what's being debugged)
-- @see https://gist.github.com/lunixbochs/5b0bb27861a396ab7a86
function var_dump(something, name, padding, limit)
    if (padding == nil) then
        padding = 0
    end
    if (limit == nil) then
        limit = 2
    end
    if type(something) == 'table' then
        print(string.rep('\t', padding) .. type(something) .. ' "' .. (name or '') .. '" {')
        for k, v in pairs(something) do
            print(string.rep('\t', padding+1) .. '[' .. k .. '](' .. type(v) .. '): ' .. tostring(v))
            if type(v) == 'table' and limit > 0 then
                var_dump(v, (name or '') .. '[' .. k .. ']', padding + 2, limit - 1)
            end
        end
        print(string.rep('\t', padding) .. '}')
    else
        print(string.rep('\t', padding) .. (name or '') .. '(' .. type(something) .. '): ' .. tostring(something))
    end
end

--- Reteives the localized text for the supplied MSG_* key
-- @param msg
-- Two underscores is a standard function name for localization retrieval in PHP frameworks
function __(msg)
    --print('Message: ' .. tostring(msg) .. ' Locale: ' .. Localization_getLocale())
    return Localization_getText(msg)
end

---
-- Improved and optimized
-- @see http://snipplr.com/view/13092/strlpad--pad-string-to-the-left/
string.lpad = function(str, len, char)
    if char == nil then char = ' ' end
    str = tostring(str)
    return string.rep(char, len - #str) .. str
end

string.rpad = function(str, len, char)
    if char == nil then char = ' ' end
    str = tostring(str)
    return str .. string.rep(char, len - #str)
end
