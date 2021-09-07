
--------------------------------------------------------------------------------
-- Main LanguagePage data
--------------------------------------------------------------------------------

--- @variables
-- message
-- dutchFlag
-- englishFlag
-- frenchFlag
-- germanFlag
-- italianFlag
-- ptFlag
-- ruFlag
--
-- backButton
-- upperContainer

LanguagePage = class()

function LanguagePage:start()
	--- just LightningPlayer object
	self.player = nil
	self.currentLang = nil
	self.availableLanguages = {}
	table.insert(self.availableLanguages, 'en')
	table.insert(self.availableLanguages, 'fr')
	table.insert(self.availableLanguages, 'de')
	table.insert(self.availableLanguages, 'es')
	table.insert(self.availableLanguages, 'it')
	table.insert(self.availableLanguages, 'nl')
	table.insert(self.availableLanguages, 'pt')
	table.insert(self.availableLanguages, 'ru')

	self.back_button = ScriptComponent_getScriptTable(self.backButton)

	self.currentLang = nil
	self.isFromPlayback = false
	
	self.backPage = SETTINGS_PAGE

	--- Defines a page to go to when the language button is pressed
	-- It's usually a catalog page if isFromPlayback is false
	-- And it's usually a playback page if isFromPlayback is true
	-- But it must be PLAYBACK_PAGE in case we are to start playing video, but language needs to be shown
	-- @see CatalogItem:triggerPageSwitch()
	-- @use LanguagePage:setNextPage() to change
	self.nextPage = CATALOG_PAGE
end

function LanguagePage:onFocus()
	-- self.currentLang = 'fr'
	-- self:setSelectedLanguage()
	
	self.back_button:resetAnimations()
	self.englishFlag:resetAnimations()
	self.frenchFlag:resetAnimations()
	self.dutchFlag:resetAnimations()
	self.germanFlag:resetAnimations()
	self.spanishFlag:resetAnimations()
	self.italianFlag:resetAnimations()
	self.ptFlag:resetAnimations()
	self.ruFlag:resetAnimations()
	
	-- set default value, use setBackPage() to change
	self.backPage = SETTINGS_PAGE
	
	local player = LightningPlayer.menu
	
	if LanguageButton.selected ~= nil then
		LanguageButton.selected:unselect(false)
	end
	
	local button = self:getButton(self.currentLang)
	--local currentItem = player.catalogTable:getCurrentItemObj()
	if button then
		if button.currentState ~= "disabled" then
			button:select(false)
		--elseif self.isFromPlayback then
			-- local currentItem = player.catalogTable:getCurrentItemObj()
			
			-- local key, _ = next(currentItem.currentItem.mediaUrls)
			-- button = self:getButton(self.currentLang)
			-- if button then
			-- 	button:select()
			-- end
		end
		
	end
end


-- Callback called every frames
function LanguagePage:update(dt)
	if not self.player then
		self.player = LightningPlayer.menu
	end
	
	if not self.player:isAPopupOpen() then
		if GUI:isLeftPressed() then
			if LanguageButton.selected ~= nil then
				local neighbour = GUI:getNeighborElement(LanguageButton.selected, "GUI_DIRECTION_LEFT")
				if neighbour ~= nil then
					neighbour:select()
				end
			end
		elseif GUI:isRightPressed() then
			if LanguageButton.selected ~= nil then
				local neighbour = GUI:getNeighborElement(LanguageButton.selected, "GUI_DIRECTION_RIGHT")
				if neighbour ~= nil then
					neighbour:select()
				end
			end
		elseif GUI:isUpPressed() then
			if LanguageButton.selected ~= nil then
				local neighbour = GUI:getNeighborElement(LanguageButton.selected, "GUI_DIRECTION_UP")
				if neighbour ~= nil then
					neighbour:select()
				end
			end
		elseif GUI:isDownPressed() then
			if LanguageButton.selected ~= nil then
				local neighbour = GUI:getNeighborElement(LanguageButton.selected, "GUI_DIRECTION_DOWN")
				if neighbour ~= nil then
					neighbour:select()
				end
			end
		elseif GUI:isValidatePressed() then
			if LanguageButton.selected ~= nil then
				GUI:clickElement(LanguageButton.selected)
			end
		elseif GUI:isCancelPressed() then
			print('(B) pressed')
			GUI:clickElement(self.back_button)
			Input_freeze()
		end
	end
end

--- Go to the correct page
function LanguagePage:goBack()
	if self.backPage == CATALOG_PAGE then
		self.player:goToCatalog()
	else
		LightningPlayer.menu:switchPage(self.backPage)
	end
end

--------------------------------------------------------------------------------
-- Flag management
--------------------------------------------------------------------------------

---
-- This is onFocus() handler when browsing the catalog
-- Enter the language page with the data for the video to play
-- @param videoData - structure from JSON with video information and languages
-- @param bannerData - structure with banner data
-- @param isFromPlayback - boolean, to show the upper screen of the language page or keep video on top
function LanguagePage:setCurrentVideoElement(videoData, bannerData, isFromPlayback)
	-- Store data
	self.player = LightningPlayer.menu
	self.videoData = videoData
	--var_dump(self.videoData, 'self.videoData')
	self.bannerData = bannerData
	self.isFromPlayback = isFromPlayback
	print('isFromPlayback: ' .. tostring(self.isFromPlayback))

	-- set default value, use setNextPage() to change
	if isFromPlayback then 
		self.nextPage = PLAYBACK_PAGE 
	else 
		self.nextPage = CATALOG_PAGE 
	end
	print('nextPage: ' .. tostring(self.nextPage))

	return self:setCurrentLanguage()
	-- we don't start playing the video here
end

function LanguagePage:setCurrentVideoElementAndPlay(videoData, bannerData, isFromPlayback)
	print('LanguagePage:setCurrentVideoElementAndPlay()')
	local oneLanguage = self:setCurrentVideoElement(videoData, bannerData, isFromPlayback)

	-- Jump to the video if we found the system language or if only one is there
	if self.isFromPlayback then
		print("LanguagePage:setCurrentVideoElementAndPlay - self.isFromPlayback = true, Waiting for language choice")
		self:setSelectedLanguage()
	else 	-- this is from the catalog page
		if oneLanguage then
			self.player:playVideo(videoData.mediaUrls[self.currentLang], videoData, bannerData)
		else
			print("LanguagePage:setCurrentVideoElementAndPlay - Waiting for language choice")
			self:setSelectedLanguage()
		end
	end
end

---
-- Will disable all languge buttons
-- Will check which languages are available and enable those
-- Will check if it's clearly possible to detect the user desired language
-- @return boolean  - true if only one language is possible
--					- false if multiple languages are possible
function LanguagePage:setCurrentLanguage()
	-- Disable all buttons first
	for i = 1, #self.availableLanguages do
		local button = self:getButton(self.availableLanguages[i])
		if (button ~= nil) then
			button:setState('disabled')
		end
	end

	-- Search data
	local langCode = ''
	local langCounter = 0
	local systemLanguage, systemCountry = Localization_getLocale()
	if self.videoData ~= nil then
		print('LanguagePage:setCurrentLanguage: videoData is available')
		local catalogVideos = self.videoData.mediaUrls

		-- Enable languages that we know exist
		local foundSystemLanguage = false
		local foundCurrentLang = false
		for key, value in pairs(catalogVideos) do
			if (value > '') then	-- handle missing mediaUrl for a language which is usually available
				langCode = key
				print('Language: [' .. key .. ']: ' .. tostring(value))
				langCounter = langCounter + 1
				local button = self:getButton(key)
				if (button ~= nil) then
					button:setState('idle')
				end

				if key == systemLanguage then
					foundSystemLanguage = true
				end
				if self.currentLang ~= nil and key == self.currentLang then
					foundCurrentLang = true
				end
			end
		end

		if foundCurrentLang and self.currentLang then	-- language was already selected previously
			print("LanguagePage:setCurrentVideoElementAndPlay - Found current language : " .. tostring(self.currentLang))
		elseif foundSystemLanguage == true then
			print("LanguagePage:setCurrentVideoElementAndPlay - Found system language : " .. tostring(systemLanguage))
			self.currentLang = systemLanguage
		elseif langCounter == 1 then
			print("LanguagePage:setCurrentVideoElementAndPlay - Only one language : " .. tostring(langCode))
			self.currentLang = langCode
		else
			return false
		end
	else
		print('LanguagePage:setCurrentLanguage: videoData not available')
	end
	return true
end

-- The user has selected a language
function LanguagePage:onButtonClick(button)
	if not self.player then
		self.player = LightningPlayer.menu
	end
	if button == self.back_button then
		print('LanguagePage:onButtonClick()')
		self:goBack()
	else
		self:activateSelectedLanguageVideo(button)
	end
end

---
-- Jump to the video
-- Important: WorldNode name is the language code (don't rename it)
function LanguagePage:activateSelectedLanguageVideo(button)
	local langCode = button.language
	self.currentLang = langCode		-- update currentLang, important
	print("LanguagePage:onButtonPress() - langCode " .. langCode)
	print('self.isFromPlayback: ' .. tostring(self.isFromPlayback))
	--var_dump(self.videoData, 'self.videoData')
	local wantsToPlay = (self.nextPage == PLAYBACK_PAGE) or (self.isFromPlayback)
	if wantsToPlay and self.videoData ~= nil then
		local mediaURL = self.videoData.mediaUrls[langCode];
		print("MediaURL: " .. tostring(mediaURL))
		if (mediaURL) then
			self:setSelectedLanguage()
			
			local pressedButton = button
			print('pressedButton: ' .. tostring(pressedButton))
			if (pressedButton) then
				self.mediaURL = mediaURL 	-- for self.triggerPageSwitch
				print('LanguagePage:activateSelectedLanguageVideo playVideo(' .. tostring(self.mediaURL) .. ')')
				print('LanguagePage.videoData: ' .. tostring(self.videoData.id))
				self.player:playVideo(self.mediaURL, self.videoData, self.bannerData, true)
			end

		else
			print('No video for the selected language')
			var_dump(self.videoData.mediaUrls)
		end
	else 	-- otherwise we are not watching any video yet (catalog page -> settings)
		print('not from playback, go to ' .. tostring(self.nextPage))
		if (self.nextPage == PLAYBACK_PAGE) then
			self.player:goToPlayback();
		else 
			self.player:goToCatalog()
		end
	end
end

function LanguagePage:setBackPage(page) 
	self.backPage = page
end

function LanguagePage:setNextPage(page) 
	self.nextPage = page
	print('nextPage: ' .. self.nextPage)
end

--- Get the button script component table from a language code
function LanguagePage:getButton(lang)
	local button = nil

	if lang == "en" then
		button = self.englishFlag
	elseif lang == "fr" then
		button = self.frenchFlag
	elseif lang == "de" then
		button = self.germanFlag
	elseif lang == "es" then
		button = self.spanishFlag
	elseif lang == "it" then
		button = self.italianFlag
	elseif lang == "nl" then
		button = self.dutchFlag
	elseif lang == "pt" then
		button = self.ptFlag
	elseif lang == "ru" then
		button = self.ruFlag
	end

	return button
end

function LanguagePage:setSelectedLanguage()
	print('LanguagePage:setSelectedLanguage('..tostring(self.currentLang)..')')
	if (self.currentLang) then
		local currentButton = self:getButton(self.currentLang)
		if currentButton and currentButton.currentState ~= "disabled" then
			currentButton:select()
		end
	end
end
