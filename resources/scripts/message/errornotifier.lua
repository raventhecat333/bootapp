require 'scripts/message/messagebox.lua'

--------------------------------------------------------------------------------
-- ErrorNotifier Object script
--! @class ErrorNotifier
--! @parent MessageBox
--------------------------------------------------------------------------------

ErrorNotifier = class(MessageBox)


--------------------------------------------------------------------------------
-- notify
--! @brief Display a confirmation dialog
--! @param text text to display
--! @param listener If present, the user can dismiss the notification, which will call "notificationDismissed" on the listener
--------------------------------------------------------------------------------
function ErrorNotifier:notify(text, sound, listener)
	GUI:debugPrint("[" .. tostring(self) .. "]\tErrorNotifier:notify()")
	
	-- Setup the right behaviour
	if listener then
		self.errorNotifier = listener
		self:setBehaviour(POPUP_BEHAVIOUR_CONFIRM)
	else
		self:setBehaviour(POPUP_BEHAVIOUR_BLOCKING)
	end
	
	if sound then
		SoundComponent_stop(sound)
		SoundComponent_play(sound)
	end
	
	-- Open the popup
	self.listener = self
	self:setText(text)
	self:openPopup()
end

--------------------------------------------------------------------------------
-- stopNotify
--! @brief Close the blocking dialog
--------------------------------------------------------------------------------
function ErrorNotifier:stopNotify()
	GUI:debugPrint("[" .. tostring(self) .. "]\tErrorNotifier:stopNotify()")
	self:closePopup()
end

--------------------------------------------------------------------------------
-- isNotifying
--! @brief Check whether we are notifying the user or not
--------------------------------------------------------------------------------
function ErrorNotifier:isNotifying()
	if WorldNode_isEnabled(self.worldNode) == true then
		return true
	else
		return false
	end
end

--------------------------------------------------------------------------------
-- onPopupClose
--! @brief The user has closed the popup
--! @param popup Popup reference
--! @brief answer Result
--------------------------------------------------------------------------------
function ErrorNotifier:onPopupClose(popup, answer)
	GUI:debugPrint("[" .. tostring(self) .. "]\tErrorNotifier:onPopupClose() " .. tostring(answer))

	if answer == "ok" or answer == "yes" then
		if self.errorNotifier then
			self.errorNotifier:notificationDismissed()
		end
	end
end

--------------------------------------------------------------------------------
-- update
--! @brief Performs processing on each frame
--! @param dt delta Time since last update
--------------------------------------------------------------------------------
function ErrorNotifier:update(dt)
	
	MessageBox.update(self, dt)
	
	if self.state == POPUP_STATE_IDLE then
		GUI:focusElement(nil)
	end
	
end


