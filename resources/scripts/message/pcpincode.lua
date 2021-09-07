require 'scripts/helpers/savehelper.lua'

PCPinCode = class(SaveHelper)
PCPinCode.initialized = false

--------------------------------------------------------------------------------
-- PCPinCode Object script
--! @class PCPinCode

--Handke the saving and retrieving of the Parental Control PIN code.
--------------------------------------------------------------------------------

function PCPinCode:init()
	self.saveFilename = 'PCPinCode.txt'
	if string.len(self.saveFilename) > 16 then
		print('Warning: save filename "' .. self.saveFilename ..'" too long, will be truncated')
		self.saveFilename = string.sub(self.saveFilename, 0, 16)
	end
	self:saveInit()
	--print('PIN Save Init OK')
end

function PCPinCode:hasSaveData()
	--print('PCPinCode:hasSaveData()')
	if self.pinCode ~= nil then
		return true
	end
	
	local data = self:loadSaveData()
	if data ~= nil then
		local decodedData = jsonDecode(data)
		--var_dump(decodedData, 'PIN json decoded')
		self.pinCode = decodedData.pinCode
	end
	return self.pinCode ~= nil
end

--- This must be called from a couritine
-- Otherwise we will create one, but it's not tested
function PCPinCode:loadSaveData()
	local data = nil
	local currentCoroutine = coroutine.running()
	if currentCoroutine then
		data = self:loadDataInternal()
	else
		data = coroutine.wrap(self.loadDataInternal)(self)
	end
	--print('PCPinCode:loadSaveData() coroutine ended')
	--var_dump(data, 'json loaded')
	return data
end

function PCPinCode:getSaveData()
	if not self.pinCode then
		self:hasSaveData()	-- load
	end
	print('PCPinCode saved pin is ' .. (self.pinCode or "[NO PINCODE]"))
	return self.pinCode
end

--- Coroutine
function PCPinCode:loadDataInternal()
	--print('PCPinCode:loadDataInternal')
	local fh = self:createSaveFile(self.saveFilename)
	local result, data = self:readSaveFile(fh)
	print('Loading done, result: ' .. tostring(result) .. ', data: ' .. tostring(data))
	self:closeSaveFile(fh)
	if result == 0 then
		return data
	else
		print('PIN Read save data failed. Error: ' .. result)
		return nil
	end
end

function PCPinCode:saveData(pinCode)
	--print('PCPinCode:saveData()')

	local data = {}
	data.pinCode = pinCode

	local json = jsonEncode(data)
	local currentCoroutine = coroutine.running()
	if currentCoroutine then
		--print('Saving json directly')
		self:saveDataInternal(json)
	else
		--print('Saving json by making and calling a new coroutine')
		coroutine.wrap(self.saveDataInternal)(self, json)
	end
	
	self.pinCode = pinCode  			-- save in this object to not read the file everytime
	--print('PCPinCode:saveData() done')
end

--- Coroutine
function PCPinCode:saveDataInternal(json)
	--print('PCPinCode:saveDataInternal()')
	local fh = self:createSaveFile(self.saveFilename)
	self:writeSaveFile(fh, json)
	self:closeSaveFile(fh)
	--print('PCPinCode:saveDataInternal() done 1')
end

-- We write emptiness, we don't erase the file.
function PCPinCode:eraseData()
	local data = {}

	local json = jsonEncode(data)
	local currentCoroutine = coroutine.running()
	if currentCoroutine then
		--print('Saving empty json directly')
		self:saveDataInternal(json)
	else
		--print('Saving empty json by making and calling a new coroutine')
		coroutine.wrap(self.saveDataInternal)(self, json)
	end
	
	self.pinCode = nil  			-- remember we removed the data
	--print('PCPinCode:saveData() done')
end


