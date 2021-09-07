require 'scripts/helpers/httphelper.lua'
require 'scripts/utils/pausebutton.lua'
require 'scripts/helpers/savehelper.lua'
require 'scripts/utils/ErrorConverter.lua' 

--------------------------------------------------------------------------------
-- PlaybackPage Object script
--! @class PlaybackPage
--! @variable {LuaTable}       back_button Back button script object reference
--! @variable {Component}      player Video component reference
--! @variable {LuaTable}       pause_button Pause button script object reference
--! @variable {LuaTable}       seek_bar Seek bar slider script object reference
--! @variable {Component}      debugState Debug Only : reference to state label component
--! @variable {LuaTable}       banner banner script object reference
--! @variable {LuaTable}       eshop_button Go to eShop button script object reference
--! @variable {Component}      progress_bar Reference to the progress bar slice sprite
--! @variable {LuaTable}       lang_button Language button script object reference
--! @variable {LinkedResource} confirmationPrefab Reference to the confirmation popup prefab resource
--! @variable {LuaTable}       nextEpisode Next episode button script object reference
--! @variable {Component}      episodeNumberComponent Episode number label reference
--! @variable {LuaTable}       restart_button Replay button script object reference
--! @variable {WorldNode}      loading_node Reference to the loading icon node
--! @variable {WorldNode}      ageRating Reference to the loading icon node

--!
--! Params
--! * player: video component
--!
--! States
--!
--! Attributes
--! * back_button :
--! * player :
--! * pause_button :
--! * seek_bar :
--! * debugState :
--! * banner :
--! * eshop_button :
--! * progress_bar :
--! * lang_button :
--! * confirmationPrefab :
--! * nextEpisode :
--!
--! * restart_button: this doesn't need to be linked by the ID, it will be retrieved as a child node of playbackControlButton
--!
--! Events
--!
--------------------------------------------------------------------------------


PlaybackPage = class()	-- SaveHelper

-- why are these global?
totalTime = 0
paused = false
playing = false

local localeFrameName = {
	en = "LearnMore_en",
	fr = "LearnMore_fr",
	de = "LearnMore_de",
	es = "LearnMore_es",
	it = "LearnMore_it",
	nl = "LearnMore_nl",
	pt = "LearnMore_pt",
	ru = "LearnMore_ru"
}

-- Callback when object is added to the world
function PlaybackPage:start()
	print('PlaybackPage:start()')

	self.progress_node = Component_getNode(self.progress_bar)
	local dummy
	dummy, self.progress_height = VisualComponent_getSize(self.progress_bar)

	self.delta = 0
	self.currentDragTime = 0
	self.playingRatingClip = false
	self.prevVideoState = 0
	self.initialized = false
	self.autoSeekTarget = 0
	self.progressValue = 0
	self.videoStarted = false
	self.networkErrorCount = 0
	
	--- update in onEverySecond in order for the stop() method to know the current playing time
	-- as it's too late to query it
	self.currentTime = 0

	-- Localize learn more banner label
	local language = Localization_getUserLocale()
	local spriteName = localeFrameName[language]
	local sprite = self[spriteName]
	
	if sprite then
		SpriteComponent_setSprite(self.learnmore_sprite, sprite)
	end
	
	self.pauseButtonClickTweenDesc = Tween
		:callback(GUI.pressElement, GUI, self.pause_button)
		:wait(0.2)
		:callback(GUI.releaseElement, GUI, self.pause_button)
		
	self.restartButtonClickTweenDesc = Tween
		:callback(GUI.pressElement, GUI, self.restart_button)
		:wait(0.2)
		:callback(GUI.releaseElement, GUI, self.restart_button)
	
	-- Set up the specific header to access CDNetworks
	local httpHeaders = {['X-LightningSesame'] = "LVftRJvCte7n8LhZE52bU5YHfXrXZMsPrbjZ5p253R42BBfpRLcdBjvjQfNnqE5C"}
	VideoComponent_setHttpHeaders(self.player, httpHeaders)
end

-- Callback when object is opened by a switch page
function PlaybackPage:onOpen(video, videoData, adBannerData, resume)
	print('PlaybackPage:onOpen(' .. tostring(video) .. ')')

	-- hide the restart button in the beginning of the video, it will be enable at the end of the video
	local playbackControlButton = self.pause_button.worldNode
	--self.restart_button = WorldNode_getFirstChildNode(playbackControlButton)
	WorldNode_setEnabled(self.restart_button.worldNode, false)  -- must have highest z-index

	self.back_button:setState('idle')
	AnimatorComponent_setSpeed(self.back_button.pressedAnimation, 1.0)
	AnimatorComponent_reset(self.back_button.pressedAnimation)
	AnimatorComponent_stop(self.back_button.pressedAnimation)

	self.videoUrl = video
	self.videoData = videoData
	self.adBannerData = adBannerData
	if adBannerData ~= nil then
		self.banner:setData(adBannerData.imageUrl, adBannerData.id)
	end

	local storeSeekPosition = nil
	if (resume == true) then
		storeSeekPosition = VideoComponent_getCurrentTimeAsSeconds(self.player)
		print('storeSeekPosition: ' .. tostring(storeSeekPosition))
	else 
		self:setSeekBarValue(0)
	end

	self.seekToTimeout = nil

	self.delta = 0
	self.currentDragTime = 0

	if string.len(videoData.agePrerollVideo) > 0 then
		self:loadVideo(videoData.agePrerollVideo)
		self.playingRatingClip = true
	else
		self:loadVideo(video)
		self.playingRatingClip = false
		print('Seeking to ' .. tostring(storeSeekPosition))
		if (storeSeekPosition ~= nil and storeSeekPosition > 0) then
			VideoComponent_seekAsSeconds(self.player, storeSeekPosition)
		end
	end

	TextVariableManager_setIntVariable("CURRENT_MINUTES", 0)
	TextVariableManager_setIntVariable("CURRENT_SECONDS", 0)
	TextVariableManager_setIntVariable("TOTAL_MINUTES", 0)
	TextVariableManager_setIntVariable("TOTAL_SECONDS", 0)

	local catalogPage = LightningPlayer.menu.catalogTable
	LabelComponent_setText(self.episodeNumberComponent, __("MSG_EPISODE") .. ' ' .. catalogPage:getCurrentEpisode())

	self:checkDisableNextButton()

	self:postInit()

	if (videoData.ageRate ~= nil and videoData.ageRate >= 0) then 			-- -1 for disabled
		TextVariableManager_setIntVariable("AGE", videoData.ageRate)
		WorldNode_setEnabled(self.ageRating, true)
	else
		WorldNode_setEnabled(self.ageRating, false)
	end

	LightningPlayer.menu.ga:postVideoStart(self.videoData.id)
end

--- Called only once when starting playing the first video
function PlaybackPage:postInit()
	-- make sure the init is called
	if not self.initialized then
		print('PlaybackPage:postInit()')
		self.initialized = true
		--self.sh = new(SaveHelper)
		--self:saveInit()
		--local cp = new(CurrentlyPlaying)	-- will not work, @see CurrentlyPlaying:initOld() comment
		--cp:init()

		-- make sure the player has initialized itself
		-- @deprecated since sleep is not defined
		-- local socket = require "socket"

		--function sleep(sec)
		--    socket.select(nil, nil, sec)
		--end
		--repeat
		--	self.playerInstance = LightningPlayer.menu
		--	sleep(0.1)
		--until self.playerInstance ~= nil

		self.playerInstance = LightningPlayer.menu
		-- already initialized in CatalogPage when checking hasSaveData()
		--self.playerInstance.currentlyPlayingScript:init()				-- must be LuaTable in the IDE
	end
end

-- Callback when object is closed by a switch page
function PlaybackPage:onClose()
	print('PlaybackPage:onClose()')
	self.nextEpisode:setState('idle')		-- restart the button which could have been disabled by the script
	self:closeVideo()
	if self.videoData then
		LightningPlayer.menu.ga:postVideoStop(self.videoData.id)
	end
end

-- Callback when object is removed from the world
-- Storing last retrieved self.currentTime because VideoComponent functions are not giving the correct result
function PlaybackPage:stop()
	print('PlaybackPage:stop()')
	print('currentTime: ' .. tostring(self.currentTime))
	self.playerInstance = LightningPlayer.menu
	self.playerInstance.currentlyPlayingScript:saveEpisodeAndTime(self.currentTime)
end

function PlaybackPage:setProgressValue(value)
	self.progressValue = value
	local width, height = VisualComponent_getSize(self.seek_bar.idleVisual)
	local newWidth = width * value
	local x, y = WorldNode_getLocalPosition(self.progress_node)
	WorldNode_setLocalPosition(self.progress_node, newWidth / 2 - width / 2, y)
	SpriteComponent_setSize(self.progress_bar, newWidth, self.progress_height)
end

---
-- @param value float [0..1]
function PlaybackPage:setSeekBarValue(value)
	self:setProgressValue(value)
	self.seek_bar:setValue(value)
end

-- Callback called every frame
function PlaybackPage:update(dt)
	self.currentDragTime = self.currentDragTime + dt 			-- used in the onSliderValueChange()

	self:postInit()

	--local seconds = Math.round(self.currentDragTime)			-- reduces the frame rate dramatically
	local seconds = math.floor(self.currentDragTime)			
	if seconds ~= self.prevSeconds then
		--print('every second: ' .. tostring(self.currentDragTime) .. ' ' .. tostring(seconds))
		self:onEverySecond(seconds)
		self.prevSeconds = seconds
	end

	local videoState = VideoComponent_getState(self.player)
	if (videoState ~= self.prevVideoState) then
		self:onVideoStateChange(videoState)
	end

	-- Other states then playing should block the slider
	if videoState == VIDEO_STATE_PLAYING then
		self:updateScreenWhilePlaying(dt)
	end

	-- If error or stopped during a rating clip open the actual video
	if self.playingRatingClip == true then
		if videoState == VIDEO_STATE_STOPPED or videoState == VIDEO_STATE_ERROR then
			self:loadVideo(self.videoUrl)
			self:setSeekBarValue(0)
			self.delta = 0
			self.currentDragTime = 0
			self.playingRatingClip = false
		end
	end

	if 		self.popup == nil 
		and LightningPlayer.menu.currentPage == self.worldNode 
		and not LightningPlayer.menu:isAPopupOpen() then
		-- Exit this menu
		if GUI:isCancelPressed() == true then
			GUI:clickElement(self.back_button)
		elseif GUI:isKeyPressed(PAD_DEVICE, GAMEPAD_Y) then
			print('self.lang_button.releasedSound: ' .. tostring(self.lang_button.clickedSound))
			SoundComponent_stop(self.lang_button.clickedSound)
			SoundComponent_play(self.lang_button.clickedSound)

			print('PlaybackPage:GAMEPAD_Y pressed')
			--var_dump(self.videoData, 'PlaybackPage.videoData')
			--LightningPlayer.menu:askForLanguage(self.videoData, self.adBannerData, true)
			GUI:clickElement(self.lang_button)
		elseif GUI:isKeyPressed(PAD_DEVICE, GAMEPAD_X) then
			GUI:clickElement(self.eshop_button)
		elseif GUI:isKeyPressed(PAD_DEVICE, GAMEPAD_A) then
			if WorldNode_isEnabled(self.restart_button.worldNode) then
				if self.restartButtonClickTween then
					TweenManager.manager:stopTween(self.restartButtonClickTween)
					self.restartButtonClickTween = nil
				end
				self.restartButtonClickTween = self.restartButtonClickTweenDesc:start()
			else
				if self.pauseButtonClickTween then
					TweenManager.manager:stopTween(self.pauseButtonClickTween)
					self.pauseButtonClickTween = nil
				end
				self.pauseButtonClickTween = self.pauseButtonClickTweenDesc:start()
			end
		end

		-- debug
		-- if REED_DEBUG then
		-- 	if GUI:isKeyPressed(PAD_DEVICE, CTR_GAMEPAD_LEFT_TRIGGER) then
		-- 		VisualComponent_setZIndex(self.banner.sprite, 100)
		-- 	end
		-- 	if GUI:isKeyPressed(PAD_DEVICE, CTR_GAMEPAD_RIGHT_TRIGGER) then
		-- 		VisualComponent_setZIndex(self.banner.sprite, 1)		-- check Z index in ReedIDE
		-- 	end
		-- end

		if videoState == VIDEO_STATE_PLAYING or videoState == VIDEO_STATE_BUFFERING or videoState == VIDEO_STATE_BUSY or videoState == VIDEO_STATE_FINISHED then
			if GUI:isKeyPressedRepeat(PAD_DEVICE, GAMEPAD_PAD_LEFT) then
				self:seekToDelayed(-30)
			end
			if GUI:isKeyPressedRepeat(PAD_DEVICE, GAMEPAD_PAD_RIGHT) then
				self:seekToDelayed(30)
			end
		end
	end

	-- Debug label
	if REED_DEBUG then
		LabelComponent_setText(self.debugState, tostring(videoState))
	end

	self:checkTimeout()

	self.prevVideoState = videoState
end

function PlaybackPage:getDuration() 
	if (self.duration <= 0) then
		self.duration = VideoComponent_getLengthAsSeconds(self.player)
	end
	return self.duration
end

-- when clicking the button we store where the user wants to seek to 
-- and wait if he's going to seek more
-- @see setTimeout in javascript
function PlaybackPage:seekToDelayed(plusTime) 
	print('PlaybackPage:seekToDelayed(' .. plusTime .. ')')
	if self.seekToTimeout ~= nil then 						-- already seeked a bit
		self.seekToTarget = self.seekToTarget + plusTime
	else
		local currentTime = self.progressValue * self:getDuration()
		self.seekToTarget = currentTime + plusTime
	end
	self.seekToTarget = math.max(self.seekToTarget, 0)	
	self.seekToTarget = math.min(self.seekToTarget, self:getDuration())
	self.seekToTimeout = TweenState:getTimestamp() + 1.0	-- 1 second delay before seeking action
	print('self.seekToTimeout: ' .. tostring(self.seekToTimeout) .. ' self.seekToTarget: ' .. tostring(self.seekToTarget))
end

--- after seek waiting time is over we call the actual seek operation
function PlaybackPage:checkTimeout()
	if self.seekToTimeout then
		self:updateCurrentTime(self.seekToTarget)							-- seconds
		self:setSeekBarValue(self.seekToTarget / self:getDuration())		-- [0..1]
		local timestamp = TweenState:getTimestamp()
		if (timestamp >= self.seekToTimeout) then
			self:seekTo(self.seekToTarget)
			self.seekToTimeout = nil
		end
	end
end

function PlaybackPage:seekTo(currentTime)	
	local newSeek = currentTime / self:getDuration()	-- in %
	print('PlaybackPage:seekTo(' .. tostring(currentTime) .. ') ' .. tostring(self:getDuration()) .. ' = ' .. tostring(newSeek))
	if newSeek >= 0 and newSeek <= 1 then
		self:onSliderDragStart(nil, nil)
		self:onSliderValueChange(nil, newSeek)
		self:onSliderReleased(nil, newSeek)
	end
end

function PlaybackPage:updateScreenWhilePlaying(dt) 
	local currentTime = VideoComponent_getCurrentTimeAsSeconds(self.player)
	
	-- We only do this once, because it is expensive
	if totalTime == 0 then
		self.duration = -1 -- clear previous duration
		totalTime = self:getDuration()
		local totalMinutes = math.floor(totalTime / 60)
		local totalSeconds = totalTime % 60
	
		TextVariableManager_setIntVariable("TOTAL_MINUTES", totalMinutes)
		TextVariableManager_setIntVariable("TOTAL_SECONDS", totalSeconds)
		
		totalTime = totalTime - 0.3			-- fix for video not playing till the very end
	end
	
	-- don't change time while we're dragging the seekbar or buffering or shortly after drag stopped
	local videoState = VideoComponent_getState(self.player)
	--print('videoState: ' .. tostring(videoState) .. ' isDragging: ' .. tostring(self.isDragging) .. ' videoSought: ' .. tostring(self.videoSought))
	if (self.isDragging == nil or not self.isDragging)
		and videoState == VIDEO_STATE_PLAYING 
		and (self.videoSought == nil or not self.videoSought) then

		local ratio = currentTime / totalTime
		self.delta = self.delta + dt
		if self.delta > 0.5 then
			self:setSeekBarValue(ratio)
			self.delta = 0
			self:updateCurrentTime(currentTime)
		end
	end

	local fadeoutSeconds = 2
	if (totalTime - currentTime) < fadeoutSeconds then
		local alpha = (totalTime - currentTime) / fadeoutSeconds
		--print(tostring(self) .. ' ' .. totalTime .. ' - ' .. currentTime .. ' alpha: ' .. alpha)
		VisualComponent_setAlpha(self.player, alpha)
	else
		VisualComponent_setAlpha(self.player, 1)		-- quick and dirty
	end
end

function PlaybackPage:updateCurrentTime(currentTime)
	local currentMinutes = math.floor(currentTime / 60)
	local currentSeconds = currentTime % 60

	TextVariableManager_setIntVariable("CURRENT_MINUTES", currentMinutes)
	TextVariableManager_setIntVariable("CURRENT_SECONDS", currentSeconds)
end

function PlaybackPage:openEShop()
	print('PlaybackPage:openEShop()')
	print('self.popupNode: ' .. tostring(self.popupNode))
	print('self.banner.eshopId: ' .. tostring(self.banner.eshopId))
	if self.popupNode == nil and self.banner.eshopId ~= nil then
		print("PlaybackPage : Opening confirmation popup")
		self.popupNode = Scene_instantiate(self.confirmationPrefab)
		WorldNodeManager_addHierarchyToWorld(self.popupNode)
		self.popup = WorldNode_getScriptComponent(self.popupNode, "MessageBox")
		self.popup.listener = self
	end
end

--- Called when a video playback status changes. It's called once(!) and not every frame.
-- @param newState
function PlaybackPage:onVideoStateChange(newState)
	local newStateNameMap = {}
	newStateNameMap[0] = "VIDEO_STATE_IDLE"
	newStateNameMap[1] = "VIDEO_STATE_PLAYING"
	newStateNameMap[2] = "VIDEO_STATE_PAUSED"
	newStateNameMap[3] = "VIDEO_STATE_STOPPED"
	newStateNameMap[4] = "VIDEO_STATE_BUSY"
	newStateNameMap[5] = "VIDEO_STATE_ERROR"
	newStateNameMap[6] = "VIDEO_STATE_LOADING"
	newStateNameMap[7] = "VIDEO_STATE_BUFFERING"
	newStateNameMap[8] = "VIDEO_STATE_FINISHED"

	local newStateName = newStateNameMap[newState]				 .. ' (' .. (newState or 'nil') .. ')'
	local prevStateName = newStateNameMap[self.prevVideoState]	 .. ' (' .. (self.prevVideoState or 'nil') .. ')'
	print('Video playback status changed from ' .. prevStateName .. ' to ' .. newStateName)
	
	-- Loading in progress
	if (newState == VIDEO_STATE_LOADING) then
		WorldNode_setEnabled(self.loading_node, true)
		self.seek_bar:setState('disabled')
		totalTime = 0
		self.networkErrorCount = 0
	else
		self.seek_bar:setState('idle')
	end
		
	-- Decoding in progress
	if (newState == VIDEO_STATE_BUSY) then
		WorldNode_setEnabled(self.loading_node, true)

	-- Auto-seek
	elseif (newState == VIDEO_STATE_BUFFERING) then
		self.networkErrorCount = 0
		WorldNode_setEnabled(self.loading_node, true)
		self.duration = VideoComponent_getLengthAsSeconds(self.player)
		
		if self.autoSeekTarget > 0 then
			print("Auto seek : seeking at " .. self.autoSeekTarget)
			VideoComponent_seekAsSeconds(self.player, self.autoSeekTarget)
			playing = true
			paused = false
			self.autoSeekTarget = 0
		end
		
	-- Playing a video
	elseif (newState == VIDEO_STATE_PLAYING) then
		print('*** Hiding loading indicator')
		WorldNode_setEnabled(self.loading_node, false)
		WorldNode_setEnabled(self.ageRating, false)
		
		if self.prevVideoState == VIDEO_STATE_LOADING then
			self:onVideoStart()
		end
	
	-- Video has done playing
	elseif (newState == VIDEO_STATE_FINISHED) then
		print('*** Video has played to the end')
	end
	
	WorldNode_setEnabled(self.restart_button.worldNode, newState == VIDEO_STATE_FINISHED)  -- must have highest z-index
end

-- Callback called when the video playback starts after it has been opened (from LOADING to PLAYING)
function PlaybackPage:onVideoStart()
	self.playerInstance.currentlyPlayingScript:saveEpisodeAndTime(0)
	self.videoStarted = true
end

-- Callback when object is a button and is pressed
function PlaybackPage:onButtonClick(button)
	print("clicked button node: " .. tostring(WorldNode_getName(button.worldNode)))
	--print("restart button " .. tostring(self.restart_button))
	--print("pause button " .. tostring(self.pause_button))
	--print("eshop button " .. tostring(self.eshop_button))
	local playerInstance = LightningPlayer.menu
	if button == self.back_button then
		playerInstance:goToCatalog()
	-- this is a settings button now
	elseif button == self.lang_button then
		--playerInstance:askForLanguage(self.videoData, self.adBannerData, true)
		--Scene_instantiate(self.settingsPage)
		self:savePauseState()
		playerInstance:switchPage(SETTINGS_PAGE, false)
		playerInstance.settingsTable:setBackPage(PLAYBACK_PAGE)
		playerInstance:getLanguageObject().isFromPlayback = true
	elseif button == self.eshop_button then		
		-- Manage jumping to eshop
		self:openEShop()
	elseif button == self.nextEpisode then
		self:gotToNextEpisode()
	
	elseif button == self.restart_button then
		print('Restart button pressed')
		local catalogInstance = playerInstance.catalogTable
		-- object of type CatalogItem
		local currentItem = catalogInstance:getCurrentItemObj()									
		-- currentItem.currentItem
		playerInstance:askForLanguage(currentItem.currentItem, currentItem:getRandomBanner(), false)	
	else
		print('onButtonClick is not handling this button: ')
		var_dump(button, 'button')
	end
end

function PlaybackPage:gotToNextEpisode()
	print("PlaybackPage: nextEpisode pressed")
	local playerInstance = LightningPlayer.menu
	--debug(LightningPlayer)	-- static reference
	--var_dump(playerInstance, 'playerInstance') -- instance
	--var_dump(playerInstance.catalogTable, 'playerInstance.catalogTable')
	if playerInstance.catalogTable:hasNextItem() then
		local nextItem = playerInstance.catalogTable:getNextItem()
		--var_dump(nextItem, 'nextItem')
		--var_dump(nextItem.currentItem, 'nextItem.currentItem')
		playerInstance.catalogTable:selectNextItem()   			--		 to update CatalogPage when clicking [Back]
		
		--Make sure the next episode is not blocked by Parental Control
		if playerInstance.isParentalControlRestricted and not nextItem.availableAllAges then
			--restricted, not playing, jump to Parental Control flow
			coroutine.wrap(LightningPlayer.menu.parentalControlFlow)(LightningPlayer.menu)
			playerInstance:goToCatalog()
		else
			self:checkDisableNextButton()
			local videoData = nextItem.currentItem
			-- this is asking for a language every time (not good)
			--playerInstance:askForLanguage(videoData, nextItem.adBannerData, true)
			-- starts playing the next episode without asking for a language
			--local langPage = WorldNode_getScriptComponent(playerInstance.langPage, 'LanguagePage')
			--local langCode = langPage.currentLang
			--totalTime = 0
			--playerInstance:playVideo(videoData.mediaUrls[langCode], videoData, nextItem.adBannerData)
			
			local languagePage = LightningPlayer.menu:getLanguageObject()
			languagePage:setCurrentVideoElementAndPlay(videoData, nextItem:getRandomBanner(), false)
		end
	else
		print('no next item')
	end
end

function PlaybackPage:checkDisableNextButton()
	local playerInstance = LightningPlayer.menu
	local hasNextItemAfter = playerInstance.catalogTable:hasNextItem();
   	--print('hasNextItemAfter', hasNextItemAfter)
	if not hasNextItemAfter then		-- new next item
		--local m_table = ScriptComponent_getScriptTable(self.nextEpisode)	-- wrong
		-- self.nextEpisode is a LuaTable, which is a class
		-- to get to the component we need to use ._ptr
		local m_table = self.nextEpisode._ptr								-- this is a ScriptComponent
		Component_disable(m_table)											-- does nothing, a bug
		--print(Component_isEnabled(m_table))

		self.nextEpisode:setState('disabled')

		--WorldNode_setEnabled(self.nextEpisode.worldNode, false)			-- whole button disappears, not OK
	end
end

-- Callback when object is a button and is released
function PlaybackPage:onPopupClose(popup, answer)
	
	if self.popupNode then
		print("PlaybackPage : Popup closed with " .. tostring(answer))
	
		if answer == "ok" or answer == "yes" then
	
			if popup == self.popup then
				print("PlaybackPage : Jump to eShop")
				if self.banner.eshopId ~= nil then
					Application_jumpToShop(self.banner.eshopId)
				end
			end
		end
	
		WorldNode_destroy(self.popupNode)
	end
	self.popupNode = nil
	self.popup = nil
end

---
-- @param slider unused
-- @param value float [0..1]
function PlaybackPage:onSliderDragStart(slider, value)
	--print('PlaybackPage:onSliderDragStart()')
	-- FIX #3584: don't do anything on drag start since onSliderValueChange will be triggered
	--self.currentDragTime = 0
	--self.videoSought = false
	--self.lastValue = nil
	--self.isDragging = true
end

---
-- @param slider
-- @param value float [0..1]
function PlaybackPage:onSliderValueChange(slider, value)
	print("onSliderValueChange: " .. tostring(value))
	self:setProgressValue(value)

	-- first time or moved more that 1%
	if self.lastValue == nil or math.abs(value - self.lastValue) > 0.01 then
		print("move detected")
		self.lastValue = value
		self.currentDragTime = 0
		self.videoSought = false
		SoundComponent_play(self.dragSound);
		self.isDragging = true								-- onSliderDragStart() is not called on single touch
		self:updateCurrentTime(self:getDuration() * value)	-- the other one in updateScreenWhilePlaying() depends on self.isDragging
		--self:setSeekBarValue(value)		-- [0..1]	-- done while sliding see above this "if"
	end

	-- when holding the slider for too long (10 seconds), it will react as released
	if self.currentDragTime > 10.0 and not self.videoSought then
		print("seek at " .. value)
		VideoComponent_seekAsSeconds(self.player, value * self:getDuration())
		self.delta = 0
		playing = true
		paused = false
		self.videoSought = true
		self.isDragging = false
	end
end

---
-- @param slider unused
-- @param value float [0..1]
function PlaybackPage:onSliderReleased(slider, value)
	if not self.videoSought then
		
		-- Check the current state before seeking
		local videoState = VideoComponent_getState(self.player)
		if (videoState == VIDEO_STATE_BUSY or videoState == VIDEO_STATE_LOADING) then
			print("Drag Stop : will seek later at " .. value)
			self.autoSeekTarget = value * self:getDuration()
			self.delta = 0
			self.lastValue = nil
		else
			print("Drag Stop : seek at " .. value)
			VideoComponent_seekAsSeconds(self.player, value * self:getDuration())
			playing = true
			paused = false
			self.lastValue = nil
		end
	end
	self.isDragging = false
end


--------------------------------------------------------------------------------
-- Video Object script
--------------------------------------------------------------------------------

--- never executed???
function PlaybackPage:loadVideo(path)
	VideoComponent_close(self.player)
	VideoComponent_open(self.player, path)
	
	self.duration = VideoComponent_getLengthAsSeconds(self.player)		-- will be 0
	print("duration = " .. tostring(self.duration))

	self.pause_button:setChecked(true)
	playing = true
	paused = false
end

function PlaybackPage:closeVideo()
	print('PlaybackPage:closeVideo')
	if (playing) then
		local currentTime = VideoComponent_getCurrentTimeAsSeconds(self.player)
		print('currentTime: ' .. tostring(currentTime))
		self.playerInstance = LightningPlayer.menu
		
		-- save only if the video has really finished initial loading
		if self.videoStarted then
			self.playerInstance.currentlyPlayingScript:saveEpisodeAndTime(currentTime)
		end
		
		VideoComponent_close(self.player)
	end
	--VideoComponent_close(self.player)
	playing = false
	paused = false
	totalTime = 0
	self.videoStarted = false
end

function PlaybackPage:savePauseState()
	self.savedPauseSate = paused
end

function PlaybackPage:restoreAndClearPauseState()
	if self.savedPauseSate ~= nil then
		if self.savedPauseSate ~= paused then
			self:setPauseVideo(self.savedPauseSate)
		end
		self.savedPauseSate = nil
	end
end

function PlaybackPage:setPauseVideo(newstate)
	if (self.videoData) then
		if newstate == false then
			LightningPlayer.menu.ga:postVideoResume(self.videoData.id)
			VideoComponent_resume(self.player)
		else
			LightningPlayer.menu.ga:postVideoPause(self.videoData.id)
			VideoComponent_pause(self.player)
		end
		if self.pause_button.clickedSound then
			print('self.pause_button.clickedSound')
			SoundComponent_stop(self.pause_button.clickedSound)
			SoundComponent_play(self.pause_button.clickedSound)
		end
		paused = newstate
	end
end

function PlaybackPage:onCheckToggle(check, state)
	print("toggle " .. tostring(playing))
	if playing == true then
		self:setPauseVideo(not state)
	end
end

--- Called every second from the update() function
function PlaybackPage:onEverySecond(seconds)
	
	-- Loading error detection
	local videoState = VideoComponent_getState(self.player)
	if videoState == VIDEO_STATE_LOADING or videoState == VIDEO_STATE_BUFFERING or videoState == VIDEO_STATE_BUSY then
		local videoNetworkStatus = VideoComponent_getLastNetworkError(self.player) % 1024
		local networkStatus = ReedPlayer_getNetworkStatusCode()
		
		if videoNetworkStatus > 0 and not LightningPlayer.menu.networkErrorNotifier:isNotifying() then --If there is a pop-up opened already, we suppress the error.
			print('PlaybackPage:onEverySecond() : loading failed with error ' .. videoNetworkStatus)
			
			-- HTTP errors
			if videoNetworkStatus >= 100 then
				local message = __('MSG_CATALOG_DL_FAILED')
				if videoNetworkStatus == 403 then --We consider 403 as One-Time URL outdated, even though it is not necessarily the case.
					message = __('MSG_OUTDATED_1TU_SERVICE_TOKEN')
				end
				self:closeWithError(convertToLightningErrorCode(videoNetworkStatus), message, true)

			-- Network may be down
			elseif networkStatus > 0 then
				self:closeWithNetworkError(networkStatus)
				
			-- There was an error but networking is fine, we are not in code 2 (HttpRequestManagerShutdown)
			elseif videoNetworkStatus > 2 then
				self.networkErrorCount = self.networkErrorCount + 1
				print('PlaybackPage:onEverySecond() : connection failed ( ' .. self.networkErrorCount .. ')')
				
				if self.networkErrorCount >= 3 then
					self:closeWithError(2930, __('MSG_CATALOG_DL_FAILED'), false)
				end
			end
		
		end
	end

	if self.playerInstance and VideoComponent_getState(self.player) == VIDEO_STATE_PLAYING then
		self.currentTime = VideoComponent_getCurrentTimeAsSeconds(self.player)
	end
	
	if seconds > 0 and 0 == (seconds % 20) then
		--print('Every 20 seconds')
		-- don't save the playback position repeatedly when video has finished playing
		if (false) then 		-- disabled because we save when exiting the playback page
			if self.playerInstance and VideoComponent_getState(self.player) == VIDEO_STATE_PLAYING then
				local currentTime = VideoComponent_getCurrentTimeAsSeconds(self.player)
				self.playerInstance.currentlyPlayingScript:saveEpisodeAndTime(currentTime)
			end
		end
	end
end


-- Suspend all popups, HTTP requests, video, and open an appropriate error message
function PlaybackPage:closeWithError(userError, message, reload)
	
	-- Close popups
	if self.popup then
		GUIPopup.close(self.popup, "cancel")
	end
	LightningPlayer.menu:closePopups()
	
	-- Reload the catalog
	local reloadCatalog = {notificationDismissed = function()
													LightningPlayer.menu:goToCatalog()
													print("Simulating click on reload button for automatic retry.")
													LightningPlayer.menu.catalogTable:clickReloadButton()
												end}
												
	-- Just go to the catalog										
	local goToCatalog = {notificationDismissed = function()
													LightningPlayer.menu:goToCatalog()
												end}
	
	-- Notify
	local listener = goToCatalog
	if reload then
		listener = reloadCatalog
	end
	LightningPlayer.menu.networkErrorNotifier:notify("090-" .. userError .. "\n\n" .. message, LightningPlayer.menu.errorSound, listener)

	if reload then
		-- We cancel all other HTTP requests to prevent connection to other servers to trigger more actions.
		HTTP_clearRequests()
	end
	
	-- I am closing the video to make sure it doesn't recover in my back: I wouldn't now how to treat this. 
	-- Might be changed later to detect that video is now working and cancel the pop-up. But it could then lead to flashing pop-ups: not great.
	-- Also, it keeps the log cleaner and reduce the calls to the server.
	self:closeVideo()
end

-- Network is down
function PlaybackPage:closeWithNetworkError(networkError)
	self:closeVideo() -- Same reasons as above.
	Application_displayNetworkErrorFromCode(networkError)
	
	if self.popup then
		GUIPopup.close(self.popup, "cancel")
	end
	LightningPlayer.menu:closePopups()
	LightningPlayer.menu:goToCatalog()
end
