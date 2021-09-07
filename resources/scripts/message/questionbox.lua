require 'scripts/message/messagebox.lua'

--------------------------------------------------------------------------------
-- QuestionBox Object script
--! @class QuestionBox
--! @parent MessageBox
--!
--! Attributes
--! @variable {Component}	[topLabel] reference to the text label for the upper screen.
--! @variable {WorldNode}	topBox reference to the box for the upper screen.
--------------------------------------------------------------------------------

QuestionBox = class(MessageBox)


--------------------------------------------------------------------------------
-- notify
--! @brief Display a question dialog
--! @param lowerBodyText text to display in the lower box
--! @param upperBodyText text to display in the upper box (nil to not have an upper box)
--! @param leftButtonText text to display on the left side button
--! @param rightButtonText text to display on the right side button
--------------------------------------------------------------------------------
function QuestionBox:ask(lowerBodyText, upperBodyText, leftButtonText, rightButtonText, sound, listener)
	GUI:debugPrint("[" .. tostring(self) .. "]\tQuestionBox:notify()")
	
	self:setBehaviour(POPUP_BEHAVIOUR_CHOOSE)
	self.answerListener = listener
	self.userChoice = ""
	
	if leftButtonText ~= nil then
		LabelComponent_setText(self.invalidate_button.label, leftButtonText) 
	else
		LabelComponent_setText(self.invalidate_button.label, __("MSG_B_CANCEL")) 
	end
	if rightButtonText ~= nil then
		LabelComponent_setText(self.validate_button.label, rightButtonText) 
	else
		LabelComponent_setText(self.validate_button.label, __("MSG_A_OK")) 		
	end
	
	if sound then
		SoundComponent_stop(sound)
		SoundComponent_play(sound)
	end
	
	-- Open the lower popup
	self.listener = self
	self:setText(lowerBodyText)
	self:openPopup()
	
	-- Open the upper popup if required
	if upperBodyText then
		WorldNode_setEnabled(self.topBox, true)
		LabelComponent_setText(self.topLabel, upperBodyText) 
	else
		WorldNode_setEnabled(self.topBox, false)
	end
	
end

--------------------------------------------------------------------------------
-- stopNotify
--! @brief Close the blocking dialog
--------------------------------------------------------------------------------
function QuestionBox:stopNotify()
	GUI:debugPrint("[" .. tostring(self) .. "]\tQuestionBox:stopNotify()")
	self:closePopup()
end

--------------------------------------------------------------------------------
-- isNotifying
--! @brief Check whether we are notifying the user or not
--------------------------------------------------------------------------------
function QuestionBox:isNotifying()
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
function QuestionBox:onPopupClose(popup, answer)
	GUI:debugPrint("[" .. tostring(self) .. "]\tQuestionBox:onPopupClose() " .. tostring(answer))

	self.answerListener:notificationDismissed()
end

--------------------------------------------------------------------------------
-- update
--! @brief Performs processing on each frame
--! @param dt delta Time since last update
--------------------------------------------------------------------------------
function QuestionBox:update(dt)
	
	MessageBox.update(self, dt)
	
	if self.state == POPUP_STATE_IDLE then
		GUI:focusElement(nil)
	end
	
end