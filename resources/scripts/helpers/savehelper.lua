require 'scripts/core/core.lua'

SaveHelper = class()

--------------------------------------------------------------------------------
-- saveInit
--! @brief Initialize the save API
--------------------------------------------------------------------------------
function SaveHelper:saveInit()
	self.saveActionsWaiting = {}
end

--------------------------------------------------------------------------------
-- createSaveFile
--! @brief Create a file interface and returns its ID
--! @param fileName Name of the file to create
--! @return Identifier of the new save file
--------------------------------------------------------------------------------
function SaveHelper:createSaveFile(fileName)
	print("SaveHelper::createSaveFile " .. fileName)
	return Save_create(fileName, 512)
end

--------------------------------------------------------------------------------
-- readSaveFile
--! @brief Get the text content of a save file interface
--! @param id Identifier of the save file
--! @return (result, Read data)
--! @usage local result, data = self:readSaveFile(fh)
--------------------------------------------------------------------------------
function SaveHelper:readSaveFile(id)
	local currentCoroutine = coroutine.running()
	if not currentCoroutine then
		error('SaveHelper:readSaveFile : Must be called inside a coroutine')
	end
	
	self.saveActionsWaiting[id] = currentCoroutine
	Save_read(self._ptr, id)
	return coroutine.yield()
end

--------------------------------------------------------------------------------
-- writeSaveFile
--! @brief Write text onto a save file
--! @param id Identifier of the save file
--! @param buffer Data to write
--------------------------------------------------------------------------------
function SaveHelper:writeSaveFile(id, buffer)
	local currentCoroutine = coroutine.running()
	if not currentCoroutine then
		error('SaveHelper:writeSaveFile : Must be called inside a coroutine')
	end
	
	self.saveActionsWaiting[id] = currentCoroutine
	Save_write(self._ptr, id, buffer)
	return coroutine.yield()
end

--------------------------------------------------------------------------------
-- deleteSaveFile
--! @brief Delete a save file
--! @param id Identiier of the save file
--------------------------------------------------------------------------------
function SaveHelper:deleteSaveFile(id)
	local currentCoroutine = coroutine.running()
	if not currentCoroutine then
		error('SaveHelper:deleteSaveFile : Must be called inside a coroutine')
	end
	
	self.saveActionsWaiting[id] = currentCoroutine
	Save_delete(self._ptr, id)
	return coroutine.yield()
end

--------------------------------------------------------------------------------
-- closeSaveFile
--! @brief Close a save interface and release the associated data
--! @param id Identifier of the save file
--------------------------------------------------------------------------------
function SaveHelper:closeSaveFile(id)
	return Save_release(id)
end

--------------------------------------------------------------------------------
-- onSaveActionDone
--! @brief Internal callback
--------------------------------------------------------------------------------
function SaveHelper:onSaveActionDone(id, result, buffer, bufferSize)
	local status, errCode = coroutine.resume(self.saveActionsWaiting[id], result, buffer)
	if status == false then
		error(tostring(errCode))
	end
end
