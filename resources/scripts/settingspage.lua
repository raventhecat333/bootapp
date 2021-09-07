SettingsPage = class(HttpHelper)

function SettingsPage:start()
	self.backPage = nil		

	--- Used to prevent (Y) button which switched to the settings page
	-- to be handled again inside seetings page and go to the language page
	self.stillPressed = nil		
end

--- where the back button should switch to (CATALOG_PAGE, PLAYBACK_PAGE)
function SettingsPage:setBackPage(pageID)
	print('SettingsPage:setBackPage(' .. pageID .. ')')
	self.backPage = pageID
end

function SettingsPage:update()
	if not LightningPlayer.menu:isAPopupOpen() then
		if GUI:isCancelPressed() then
			GUI:clickElement(self.backButton)
		elseif GUI:isKeyPressed(PAD_DEVICE, GAMEPAD_Y) and not self.stillPressed then
			GUI:clickElement(self.langButton)
		else 
			self.stillPressed = false
		end
	end
end

function SettingsPage:onFocus()
	print('SettingsPage:onFocus')
	-- animations keep playing otherwise
	-- Ponch patch : should be handled in a better way
	self.langButton:resetAnimations()
	self.backButton:resetAnimations()
	self.resetButton:resetAnimations()

	-- prevent pressed button to register twice
	if GUI:isKeyPressed(PAD_DEVICE, GAMEPAD_Y) then
		self.stillPressed = true
	end

	-- checking if we should gray out the "Reset Parental Control" button
	print("checking if we should gray out the Reset Parental Control button")
	print("restricted " .. (LightningPlayer.menu.isParentalControlRestricted and "true" or "false"))
	print("saved PIN " .. (LightningPlayer.menu.PCPinCodeScript:hasSaveData() and "true" or "false"))
	if LightningPlayer.menu.isParentalControlRestricted or not LightningPlayer.menu.PCPinCodeScript:hasSaveData() then
		self.resetButton:setState('disabled')
		print("disabling")
	else
		self.resetButton:setState('idle')
		print("enabling")
	end

	print('setPauseVideo');
	LightningPlayer.menu:getPlaybackObject():setPauseVideo(true)
end

function SettingsPage:onButtonClick(button)
	print('SettingsPage:onButtonClick(' .. tostring(button:getName()) .. ')')
	print('self.backButton: ' .. tostring(self.backButton))
	print('self.langButton: ' .. tostring(self.langButton))
	print('self.resetButton: ' .. tostring(self.resetButton))
	if button == self.backButton then
		print('unPauseVideo');
		LightningPlayer.menu:getPlaybackObject():restoreAndClearPauseState()
		LightningPlayer.menu:switchPage(self.backPage)
	
	elseif button == self.langButton then
		LightningPlayer.menu:switchPage(LANG_PAGE)
	
	elseif button == self.resetButton then
		coroutine.wrap(self.ConfirmPINReset)(self)
	end
end

function SettingsPage:ConfirmPINReset()
	local co = coroutine.running()
	LightningPlayer.menu.questionBox:ask(__('MSG_PARENTAL_CONTROL_RESET_MESSAGE'), nil, nil, nil, LightningPlayer.menu.infoSound, 
		{
			notificationDismissed = function()
				if LightningPlayer.menu.questionBox.userChoice == "ok" then
					LightningPlayer.menu.PCPinCodeScript:eraseData() -- we do it here because it takes a bit of time and we'd rather stay on the pop-up until it is done.
				end
				coroutine.resume(co)
				
			end
		})
	coroutine.yield()
	
	print("Coming back from question. Answer is " .. LightningPlayer.menu.questionBox.userChoice)
	if LightningPlayer.menu.questionBox.userChoice == "ok" then
		--LightningPlayer.menu.PCPinCodeScript:eraseData()
		LightningPlayer.menu.isParentalControlRestricted = Application_isVideoWatchUnderParentalControl()
		LightningPlayer.menu:switchPage(CATALOG_PAGE)
	end
end
