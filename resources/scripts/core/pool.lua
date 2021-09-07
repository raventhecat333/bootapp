require 'core.lua'

local pairs = pairs
local setmetatable = setmetatable

Pool = class()

function Pool:alloc()
	local n = self[0]
	--print('pool(' .. tostring(self) .. '):alloc(), n = ' .. tostring(n))
	if n == nil then
		local mt = self.mt
		if mt then
			local result = setmetatable({}, mt)
			--print('  result = ' .. tostring(result))
			return result
		else
			local result = {}
			--print('  result = ' .. tostring(result))
			return result
		end
	elseif n == 1 then
		local result = self[1]
		self[1] = nil
		self[0] = nil
		--print('  result = ' .. tostring(result))
		return result
	else
		local result = self[n]
		self[n] = nil
		self[0] = n - 1
		--print('  result = ' .. tostring(result))
		return result
	end
end

function Pool:free(tbl)
	if not self.keepContents then
		for i = #tbl, 1, -1 do
			tbl[i] = nil
		end
		for k in pairs(tbl) do
			tbl[k] = nil
		end
	end
	local n = self[0]
	--print('pool(' .. tostring(self) .. '):free(' .. tostring(tbl) .. '), n = ' .. tostring(n))
	if n == nil then
		self[0] = 1
		self[1] = tbl
	else
		self[0] = n + 1
		self[n + 1] = tbl
	end
end

function createPooledNewAndFreeMethods(klass, keepContents)
	local pool = new(Pool)
	pool.mt = klass
	pool.keepContents = keepContents
	
	klass.new = function(...)
		local inst = pool:alloc()
		if inst.init then
			inst:init(...)
		end
		return inst
	end
	
	klass.free = function(self)
		if self.destroy then
			self:destroy()
		end
		pool:free(self)
	end
end
