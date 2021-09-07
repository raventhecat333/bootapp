require 'scripts/helpers/httphelper.lua'
require 'scripts/utils/functions.lua'

-- overrides of GUI functions to fix inverted stick on axis Y
require 'scripts/gui/gui_inputs.lua'

function GUI:isUpPressed()
	return GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_PAD_UP, GUI.KEY_THRESHOLD) or GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_AXIS_Y, GUI.AXIS_THRESHOLD)
end

function GUI:isDownPressed()
	return GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_PAD_DOWN, GUI.KEY_THRESHOLD) or GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_AXIS_Y, -GUI.AXIS_THRESHOLD)
end


--------------------------------------------------------------------------------
-- LightningPlayer Object script
--! @class LightningPlayer
--!
--! Attributes
--! @variable {Component} 	bgmSound background music SoundComponent
--! @variable {WorldNode} 	catalogPage 	a WN
--! @variable {WorldNode} 	playbackPage 	a WN
--! @variable {Component} 	catalog Script CatalogHandler
--! @variable {Component} 	camera_touch [Camera]
--! @variable {WorldNode} 	splashPage 1-splashPage
--! @variable {Component} 	splashText Label @MSG_WAITING_MESSAGE
--! @variable {WorldNode} 	langPage 3-langPage
--! @variable {LuaTable} 	currentlyPlayingScript Script CurrentlyPlaying
--! @variable {LuaTable} 	[PCPinCodeScript] Script PCPinCode
--! @variable {LuaTable}	errorNotifier Script ErrorNotifier
--! @variable {LuaTable}	networkErrorNotifier Script ErrorNotifier for when the connection to the Internet fails
--! @variable {LuaTable}	questionBox Script  QuestionBox
--! @variable {LuaTable}	parentalControlBox Script parental control QuestionBox
--! @variable {WorldNode}	topCatalogNode 01-top
--! @variable {WorldNode}	catalogResumeButton a WN
--! @variable {WorldNode}	resumeButton
--! @variable {WorldNode}	settingsPage Settings WN
--! @variable {LuaTable}	settingsTable Settings LuaTable
--! @variable {Component} 	infoSound opening sound of an informative box or a question box SoundComponent
--! @variable {Component} 	errorSound opening sound of an error box SoundComponent
--------------------------------------------------------------------------------

SPLASH_PAGE = 0
CATALOG_PAGE = 1
LANG_PAGE = 2
PLAYBACK_PAGE = 3
SETTINGS_PAGE = 4

LightningPlayer = class(HttpHelper)

-- Callback when object is added to the world
function LightningPlayer:start()
	--- A script on the catalogPage, which is a Lua object, right?
	--self.catalogTable = nil
	--self.langPage = nil
	--self.menu = nil -- instance of LightningPlayer

	print('LightningPlayer:start()')
	if (os ~= nil) then
		print('Home: ' .. (os.getenv('home') or ''))
	end
	--print('Date: ' .. tostring(os.time("*t")))
	--print('Date: ' .. tostring(Application_getSystemTime()))
	--print('js: ' .. (js or 'js is not set'))
	
	LightningPlayer.menu = self
	self.isFirstFrame = true

	-- HTTP setup with the SSL certificate list
	self:httpInit()
	HTTP_addServerCertificateFile(Application_getDataPath('/certificates/gandi-standard-ssl-ca.cer'))
	HTTP_addServerCertificateFile(Application_getDataPath('/certificates/dm13bvvnwveun.cloudfront.net.cer'))
	HTTP_addServerCertificateFile(Application_getDataPath('/certificates/DigiCertHighAssuranceEVRootCA.crt'))
	HTTP_addServerCertificateFile(Application_getDataPath('/certificates/NOETestCa.cer'))
	if HOST_PLATFORM_IS_3DS then
		HTTP_addServerCertificateBuiltin(CACERT_NINTENDO_CLASS2_CA_G3)
	end
	
	-- Forbid screenshot post
	if HOST_PLATFORM_IS_3DS then
		Application_enableScreenShotPost(false)
	end

	-- GUI setup
	GUI.roundedUnits = true
	GUI.clickMode = "release"
	GUI.dragThresholdX = 6
	GUI.dragThresholdY = 6
	GUI.hasAutomaticNavigation = true
	GUI.AXIS_THRESHOLD = 0.5
	
	self.frameEvent = Event:new()

	self.fade = new(TweenState);
	self.fade2 = new(TweenState);
	--self.ga:postAppStart()	-- too early the GA script is not initialized
	
	TweenManager:registerProperty('alpha', VisualComponent_getAlpha, VisualComponent_setAlpha)
	TweenManager:registerProperty('volume', SoundComponent_getVolume, SoundComponent_setVolume)
end

-- Callback when object is removed from the world
function LightningPlayer:stop()
	self.ga:postAppQuit()
	print('LightningPlayer:stop()')
end

-- Callback called every frames
function LightningPlayer:update(dt)
	self.frameEvent:raise()

	-- Soft start
	if self.isFirstFrame == true then
		
		-- We switch to the SplashPage already, otherwise the starting page is pretty strange.
		if self.currentPage ~= self.splashPage then
			self:switchPage(SPLASH_PAGE)
		end
		
		-- There is no use to start Lightning before the network connection is ready. It can cause the network error reporting to fail.
		if ReedPlayer_isNetworkReady() then
			coroutine.wrap(self.startupApp)(self)
			self.isFirstFrame = false
		end
		
	end

	self.fade:update(dt)
	self.fade2:update(dt)
end

function LightningPlayer:notifyUser(text, sound, withRetry)
	local co = coroutine.running()
	local listener = {notificationDismissed  = 	function()
													coroutine.resume(co)
												end}
	if withRetry then
		self.networkErrorNotifier:notify(text, sound, listener)
	else
		self.errorNotifier:notify(text, sound, listener)
	end
	coroutine.yield()
end

function LightningPlayer:askUser(lowerBodyText, upperBodyText, leftButtonText, rightButtonText, sound)
	local co = coroutine.running()
	self.questionBox:ask(lowerBodyText, upperBodyText, leftButtonText, rightButtonText, sound,
		{
			notificationDismissed = function()
				coroutine.resume(co)
			end
		})
	coroutine.yield()
end

function LightningPlayer:askUserParentalControl(lowerBodyText, upperBodyText, leftButtonText, rightButtonText, sound)
	local co = coroutine.running()
	self.parentalControlBox:ask(lowerBodyText, upperBodyText, leftButtonText, rightButtonText, sound,
		{
			notificationDismissed = function()
				coroutine.resume(co)
			end
		})
	coroutine.yield()
end

function LightningPlayer:startupApp()	
	--self:switchPage(SPLASH_PAGE)
	
	self:getSplashObject():playLoadingSound()

	self.frameEvent:reset()
	self.frameEvent:wait()
	
	self:getSplashObject():loadingSoundVolumeDown()
	
	self.isParentalControlRestricted = false -- true means "Video other than non-rated or 0+ are restricted"
	self.PCPinCodeScript:init()
	
	if Application_isVideoWatchUnderParentalControl() then
		self.isParentalControlRestricted = true --Now, let's see if we can change that.
		
		--Check if there is a Pin Code in the save data and if it is correct
		local pinCode = self.PCPinCodeScript:getSaveData()
		local pinCodeIsCorrect = (pinCode ~= nil and Application_checkParentControlPinCode(pinCode))
		
		if not pinCodeIsCorrect then
			self:parentalControlFlow(); -- this sets self.isParentalControlRestricted accordingly
		else
			self.isParentalControlRestricted = false
		end
	end
	
	--It is important that the catalog is downloaded after the question of Parental Control is handled because otherwise it could appear restricted (or not) when it shouldn't be (or should).
	--If you want to do in another order, be careful about this. (Ulysse)
	while not self:connectingToNetworkFlow() do		
		self:notifyUser(__("MSG_NO_NETWORK"), self.errorSound, true)
	end
	
	--Now that the real loading start, we put the loading icon and sound.
	self:getSplashObject():loadingSoundVolumeUp()

	self:getCatalog()
	
	self:getSplashObject():fadeOutLoadingSound()
end

--------------------------------------------------------------------------------
-- Flow helpers
--------------------------------------------------------------------------------

function LightningPlayer:parentalControlFlow()
	local pinCodeIsCorrect = false
	
	--During all those input boxes, we lower the sound
	-- self:getSplashObject():loadingSoundVolumeDown()
	
	--In this question, "cancel" is "I want to enter the PIN to remove the restriction."
	self:askUserParentalControl( __("MSG_PARENTAL_CONTROL_HOW_TO_UNLOCK"),__("MSG_PARENTAL_CONTROL_APP_DESCRIPTION"), __("MSG_PARENTAL_CONTROL_HOW_TO_UNLOCK_CONFIRMATION_B"), __("MSG_PARENTAL_CONTROL_HOW_TO_UNLOCK_CONFIRMATION_A"), self.infoSound)
	
	if self.parentalControlBox.userChoice == "cancel" then
		--Present the PIN keyboard
		local tries = 0
		local pincode
		while not pinCodeIsCorrect and tries < 3 do
			pincode = Application_openPinCodeKeyboard()
			
			if pincode == "" then
				-- "" means that the user pushed "Cancel"
				break
			else
				pinCodeIsCorrect = Application_checkParentControlPinCode(pincode)
				
				if not pinCodeIsCorrect then
					tries = tries+1
					if tries < 3 then
						self:notifyUser(__("MSG_PARENTAL_CONTROL_PIN_INCORRECT"), self.errorSound)
					else
						self:notifyUser(__("MSG_PARENTAL_CONTROL_PIN_INCORRECT_GO_TO_SETTINGS"), self.errorSound)
					end
				end
			end
		end
		
		if pinCodeIsCorrect then
			self.isParentalControlRestricted = false
			self:notifyUser(__("MSG_PARENTAL_CONTROL_ALL_CONTENT_AVAILABLE"), self.infoSound)
			
			-- We start by displaying things, then we save to hide the save time from the user into the normal loading process.
			--self:getSplashObject():loadingSoundVolumeUp()
			self.PCPinCodeScript:saveData(pincode)
			--self:getSplashObject():loadingSoundVolumeDown()
		end
	end
	-- self:getSplashObject():loadingSoundVolumeUp()
end

-- Try to connect to the Internet and request a service token. Return false if it wasn't possible and the application can't be launched.
-- In that case, an error message was displayed.
function LightningPlayer:connectingToNetworkFlow()
	
	if not ReedPlayer_isNetworkAvailable() then
		
		if ReedPlayer_getNetworkStatusCode ~= nil then
			local code = ReedPlayer_getNetworkStatusCode()
			if code ~= 0 then
				print('Network is unavailable : code ' .. code)
				Application_displayNetworkErrorFromCode(code)	
			end
		end
		return false
	end
	
	return true
end

function LightningPlayer:isAPopupOpen()
	return self.questionBox:isNotifying() or self.networkErrorNotifier:isNotifying() or self.errorNotifier:isNotifying() or self.parentalControlBox:isNotifying()
end

function LightningPlayer:closePopups()
	if self.questionBox:isNotifying() then
		self.questionBox:close("cancel")
	end
	
	if self.networkErrorNotifier:isNotifying() then
		self.networkErrorNotifier:close("cancel")
	end
	
	if self.errorNotifier:isNotifying() then
		self.errorNotifier:close("cancel")
	end
	
	if self.parentalControlBox:isNotifying() then
		self.parentalControlBox:close("ok") --The Parental Control question is inverted: "cancel" means I want to enter my PIN.
	end
end

--------------------------------------------------------------------------------
-- Interaction
--------------------------------------------------------------------------------

-- Catalog coroutine to download, then setup the UI
function LightningPlayer:getCatalog()
	self.handler = ScriptComponent_getScriptTable(self.catalog)
	self.catalogTable = WorldNode_getScriptComponent(self.catalogPage, 'CatalogPage')
	local catalogData = self.handler:getRoot()  -- get service token, download and parse

	-- TODO: separate get service token from downloading the catalog and insert postAppStart in between
	self.ga:postAppStart()

	if self.handler:isEndOfService() == true then
		--self:switchPage(CATALOG_PAGE)
		--WorldNode_setEnabled(self.topCatalogNode, false)
		--WorldNode_setEnabled(self.catalogResumeButton, false)
		self.errorNotifier:notify("090-2902\n\n" .. __("MSG_SERVICEENDMESSAGE"), LightningPlayer.menu.infoSound)
	elseif (#catalogData > 0) then
		self.catalogTable:createCatalogPanel(catalogData, self.handler)
		self:goToCatalog()
	else 
		print('*** DOWNLOAD FAILED, allow restart and do nothing')
		if (self.handler.i_error == 0) then
			LightningPlayer.menu.catalogTable:printStatus(__('MSG_CATALOG_DL_FAILED'))		
			--LightningPlayer.menu.catalogTable:showReloadButton()
		else 
			print('Error was already displayed')
		end
	end
end

--- Go to the catalog
-- @public
function LightningPlayer:goToCatalog()
	self.catalogTable:selectCurrentItem(false)
	self:switchPage(CATALOG_PAGE)
	local playbackPage = self:getPlaybackObject()
	playbackPage:onClose()
	HTTP_resumeShelvedRequests()
end

--- Go to the catalog
-- @public
function LightningPlayer:goToPlayback()
	local playbackPage = self:getPlaybackObject()
	self:switchPage(PLAYBACK_PAGE)
end

-- Go to the language selection page
function LightningPlayer:askForLanguage(videoData, adBannerData, isFromPlayback)
	-- Close the video if playing
	if isFromPlayback then
		WorldNode_setEnabled(self.splashPage, 		false)
		WorldNode_setEnabled(self.catalogPage, 		false)
		WorldNode_setEnabled(self.langPage, 		true)
		WorldNode_setEnabled(self.playbackPage, 	true)
		WorldNode_setEnabled(self.settingsPage,		false)
		self.currentPage = self.langPage
		self:getLanguageObject():onFocus()
	else
		self:switchPage(LANG_PAGE)
	end

	-- Open the language menu
	local languageTable = self:getLanguageObject()
	print('LightningPlayer:askForLanguage(' .. tostring(videoData.id) .. ')')
	languageTable:setCurrentVideoElementAndPlay(videoData, adBannerData, isFromPlayback)
end

-- Stops any pending sound bgm tween animation
function LightningPlayer:stopBgmTweens()
	if self.fadeInTweenHandle ~= nil then
		TweenManager.manager:stopTween(self.fadeInTweenHandle)
		self.fadeInTweenHandle = nil
	end
	
	if self.fadeOutTweenHandle ~= nil then
		TweenManager.manager:stopTween(self.fadeOutTweenHandle)
		self.fadeOutTweenHandle = nil
	end
end

function LightningPlayer:fadeInBgm()
	self:stopBgmTweens()
	self.fadeInTweenHandle = Tween:animate(self.bgmSound, 1, "to", { volume = 1 }, Ease.linear):start()
end

function LightningPlayer:fadeOutBgm()
	self:stopBgmTweens()
	self.fadeOutTweenHandle = Tween:animate(self.bgmSound, 0.4, "to", { volume = 0 }, Ease.linear):callback(SoundComponent_pause, self.bgmSound):start()
end

--- Start playing a video
-- Called by LanguagePage
function LightningPlayer:playVideo(videoUrl, videoData, adBannerData, resume)
	print('LightningPlayer:playVideo(' .. tostring(videoUrl) .. ')')
	HTTP_shelveRequests()
	coroutine.wrap(self.incrementViewCount)(self, videoData.id)

	local playbackPage = self:getPlaybackObject()
	playbackPage:onOpen(videoUrl, videoData, adBannerData, resume)

	self:switchPage(PLAYBACK_PAGE)
end

-- Launch a request to increment the view count
function LightningPlayer:incrementViewCount(id)
	self.handler:incrementViewCount(id)
end

function LightningPlayer:getCatalogHandler() 
	if not self.catalogHandler then
		self.catalogHandler = ScriptComponent_getScriptTable(self.catalog)
	end
	return self.catalogHandler
end

function LightningPlayer:getCatalogObject() 
	if not self.catalogTable then
		self.catalogTable = WorldNode_getScriptComponent(self.catalogPage, 'CatalogPage')
	end
	return self.catalogTable
end

function LightningPlayer:getLanguageObject() 
	if not self.languageTable then
		self.languageTable = WorldNode_getScriptComponent(self.langPage, 'LanguagePage')
	end
	return self.languageTable
end

function LightningPlayer:getSplashObject()
	if not self.splashTable then
		self.splashTable = WorldNode_getScriptComponent(self.splashPage, 'SplashPage')
	end
	return self.splashTable
end

function LightningPlayer:getPlaybackObject()
	if not self.playbackTable then
		self.playbackTable = WorldNode_getScriptComponent(self.playbackPage, 'PlaybackPage')
	end
	return self.playbackTable
end

--------------------------------------------------------------------------------
-- Page management
--------------------------------------------------------------------------------

-- Set the correct world nodes
function LightningPlayer:switchPage(page, disable_from)
	if disable_from == nil then disable_from = true end

	-- not good, bacause while fading both pages are active
	--local currentPage = self:getCurrentPage()
	GUI.disabled = false
	if page == SPLASH_PAGE then
		print('********************LightningPlayer:switchPage(SPLASH_PAGE)')
		WorldNode_setEnabled(self.splashPage,		true)
		WorldNode_setEnabled(self.catalogPage,		false)
		WorldNode_setEnabled(self.langPage,			false)
		WorldNode_setEnabled(self.playbackPage,		false)
		WorldNode_setEnabled(self.settingsPage,		false)
		Component_setEnabled(self.bgmSound,			false)
		GUI.hasAutomaticNavigation = true
		self.currentPage = self.splashPage
		local splashClass = self:getSplashObject()
		splashClass:onFocus()
	elseif page == CATALOG_PAGE then
		print('********************LightningPlayer:switchPage(CATALOG_PAGE)')
		local previousPage = self.currentPage
		local splashComponent = self:getSplashObject()
		splashComponent:onBlur()

		self:xFade(self.currentPage, self.catalogPage, 'CatalogPage')
		GUI.hasAutomaticNavigation = false					-- we will handle the navigation manually in CatalogPage

		-- only after CatalogPage WN is enabled (where the sound component resides)
		-- force playing if from playback page
		Component_setEnabled(self.bgmSound, true)
		if not SoundComponent_isPlaying(self.bgmSound) or previousPage == self.playbackPage then
			SoundComponent_play(self.bgmSound)
			if (previousPage == self.splashPage) then
				SoundComponent_setVolume(self.bgmSound, 1.1)
			else
				SoundComponent_setVolume(self.bgmSound, 0)
				
				self:fadeInBgm()
			end
		end
		WorldNode_setEnabled(self.playbackPage, false)
	elseif page == LANG_PAGE then
		print('*********************LightningPlayer:switchPage(LANG_PAGE)')
		--WorldNode_setEnabled(self.splashPage, 	false)
		--WorldNode_setEnabled(self.catalogPage, 	false)
		--WorldNode_setEnabled(self.langPage, 		true)
		--WorldNode_setEnabled(self.playbackPage, 	false)
		self:xFade(self.currentPage, self.langPage, 'LanguagePage')
		GUI.hasAutomaticNavigation = false
	elseif page == PLAYBACK_PAGE then
		print('**********************LightningPlayer:switchPage(PLAYBACK_PAGE)')
		--WorldNode_setEnabled(self.splashPage, 	false)
		--WorldNode_setEnabled(self.catalogPage, 	false)
		--WorldNode_setEnabled(self.langPage, 		false)
		--WorldNode_setEnabled(self.playbackPage, 	true)
		self:xFade(self.currentPage, self.playbackPage)
		GUI.hasAutomaticNavigation = true
		
		--SoundComponent_pause(self.bgmSound)	-- fadeout is called
		
		--Component_setEnabled(self.bgmSound, false)
		print("SoundComponent_isPlaying(self.bgmSound): " .. tostring(SoundComponent_isPlaying(self.bgmSound)))
	elseif page == SETTINGS_PAGE then
		print('**********************LightningPlayer:switchPage(SETTINGS_PAGE)')
		self:xFade(self.currentPage, self.settingsPage, 'SettingsPage', disable_from)
		GUI.hasAutomaticNavigation = true
	else
		print('NO handling for page: ' .. tostring(page))
	end
end

--- CTR is not capable of changing alpha of 300+ components in 0.5 seconds without framerate drop
-- @param from 			WorldNode which will be disabled
-- @param to 			WorldNode which will be enabled
-- @param scriptName	string of the script name which must reside on the "to" page. 
--						It's onFocus() method will be called
function LightningPlayer:xFade(from, to, scriptName, disable_from)
	print('xFade(' .. tostring(from) .. ', ' .. tostring(to) .. ')')
	if (from ~= nil and to ~= nil) then
		local toName = WorldNode_getName(to)
		print('xFade(' .. tostring(WorldNode_getName(from)) .. ', ' .. tostring(toName) .. ')')
		self.ga:postPageSwitch(toName)
	end
	if false then
		local xFadeTime = 0.5
		self.fade:init(from, xFadeTime, {
			eventHandler = function()
				if disable_from ~= false then
					WorldNode_setEnabled(from, 	false)
				end
				WorldNode_setEnabled(to, 	true)
			end
		})
		self.fade.reverse = true
		self.fade:start()		

		self.fade2:init(to, xFadeTime, {
			eventHandler = function()
			end
		})
		self.fade2.reverse = false
		self.fade2:start()		
		WorldNode_setEnabled(to, true)
	else
		if disable_from ~= false then
			WorldNode_setEnabled(from, false)
		end
		WorldNode_setEnabled(to, true)
	end
	if (scriptName) then 
		local scriptComponent = WorldNode_getScriptComponent(to, scriptName)	-- get script object from WN
		if (scriptComponent) then
			scriptComponent:onFocus()
		end
	end
	self.currentPage = to
end

function LightningPlayer:getCurrentPage()
	if WorldNode_isEnabled(self.splashPage) then
		return self.splashPage
	elseif WorldNode_isEnabled(self.catalogPage) then
		return self.catalogPage
	elseif WorldNode_isEnabled(self.langPage) then
		return self.langPage
	elseif WorldNode_isEnabled(self.playbackPage) then
		return self.playbackPage
	elseif WorldNode_isEnabled(self.settingPage) then
		return self.settingsPage
	else
		print('ERROR: LightningPlayer:getCurrentPage returns nil')
		return nil
	end
end
