require 'scripts/helpers/savehelper.lua'

CurrentlyPlaying = class(SaveHelper)
CurrentlyPlaying.initialized = false

--- According to Gwennaël, Reed player can't access Lua classes if they are not components.
-- It needs to access this class because of the save/load callback.
-- @deprecated because createComponentFromType() can't be linked to this Lua class
-- Solution: insert Script Component to the defaultScene.scene and get reference to it.
function CurrentlyPlaying:initOld()
	if not CurrentlyPlaying.initialized then
		self.scriptComponent = createComponentFromType(COMPONENT_TYPE_SCRIPT)
		var_dump(self)
		--self:saveInit()
		CurrentlyPlaying.initialized = true
	end
end

function CurrentlyPlaying:init()
	self.saveFilename = 'currentlyPlaying.txt'
	if string.len(self.saveFilename) > 16 then
		print('Warning: save filename too long, will be truncated')
		self.saveFilename = string.sub(self.saveFilename, 0, 16)
	end
	self:saveInit()
	print('Save Init OK')
end

function CurrentlyPlaying:hasSaveData()
	--print('CurrentlyPlaying:hasSaveData()')
	local data = self:loadSaveData()
	if data ~= nil then
		self.data = jsonDecode(data)
		--var_dump(self.data, 'json decoded')
	end
	return self.data ~= nil
end

--- This must be called from a couritine
-- Otherwise we will create one, but it's not tested
function CurrentlyPlaying:loadSaveData()
	--var_dump(self, 'CurrentlyPlaying')
	--print('self.loadCurrentPlayingTime: ' .. tostring(self.loadCurrentPlayingTime))
	local data = nil
	local currentCoroutine = coroutine.running()
	if currentCoroutine then
		data = self:loadCurrentPlayingTime()
	else
		data = coroutine.wrap(self.loadCurrentPlayingTime)(self)
	end
	--print('CurrentlyPlaying:loadSaveData() coroutine ended')
	--var_dump(data, 'json loaded')
	return data
end

function CurrentlyPlaying:getSaveData()
	if not self.data then
		self:hasSaveData()	-- load
	end
	return self.data
end

--- Coroutine
function CurrentlyPlaying:loadCurrentPlayingTime()
	--print('CurrentlyPlaying:loadCurrentPlayingTime')
	local fh = self:createSaveFile(self.saveFilename)
	local result, data = self:readSaveFile(fh)
	--print('Loading done, result: ' .. tostring(result) .. ', data: ' .. tostring(data))
	self:closeSaveFile(fh)
	if result == 0 then
		return data
	else
		return nil
	end
end

function CurrentlyPlaying:saveEpisodeAndTime(currentTime)
	print('CurrentlyPlaying:saveEpisodeAndTime(' .. tostring(currentTime) .. ')')
	print('')
	print('')
	local playerInstance = LightningPlayer.menu
	local catalogInstance = playerInstance.catalogTable
	local currentItem = catalogInstance:getCurrentItemObj()									-- object of type CatalogItem

	if currentItem ~= nil and currentItem.currentItem ~= nil then
		local data = {}
		data.episodeID = currentItem.currentItem.id
		data.episodeRowPos = currentItem.currentItem.rowPos
		data.episodeItemPos = currentItem.currentItem.itemPos
		data.currentTime = currentTime
		
		local languageInstance = playerInstance.languageTable
		data.currentLanguage = languageInstance.currentLang

		--var_dump(data);

		self.data = data  			-- save in this object to use after the back button

		local json = jsonEncode(data)
		local currentCoroutine = coroutine.running()
		if currentCoroutine then
			--print('Saving json directly')
			self:saveCurrentPlayingTime(json)
		else
			--print('Saving json by making and calling a new coroutine')
			coroutine.wrap(self.saveCurrentPlayingTime)(self, json)
		end
		print('CurrentlyPlaying:saveEpisodeAndTime() done')
	end
end

--- Coroutine
function CurrentlyPlaying:saveCurrentPlayingTime(json)
	--print('CurrentlyPlaying:saveCurrentPlayingTime()')
	local fh = self:createSaveFile(self.saveFilename)
	self:writeSaveFile(fh, json)
	self:closeSaveFile(fh)
	--print('CurrentlyPlaying:saveCurrentPlayingTime() done 1')
end

