require 'scripts/gui/gui_popup.lua'

--------------------------------------------------------------------------------
-- MessageBox Object script
--! @class MessageBox
--! @parent GUIPopup
--! 
--! Attributes
--! @variable {Component} 	[label] reference to the text label
--! @variable {Boolean}   	[autoOpen] opens automatically. Default false
--! @variable {Component}	[ok_button] (A) OK
--! @variable {Component}	[cancel_button] (B) Cancel
--! 
--------------------------------------------------------------------------------

MessageBox = class(GUIPopup)


POPUP_STATE_IDLE                = 0
POPUP_STATE_ANIM_OPEN           = 1
POPUP_STATE_ANIM_CLOSING        = 2
POPUP_STATE_ANIM_CLOSED         = 3

POPUP_BEHAVIOUR_BLOCKING        = 0
POPUP_BEHAVIOUR_CONFIRM         = 1
POPUP_BEHAVIOUR_CHOOSE          = 2


--------------------------------------------------------------------------------
-- setText
--! @brief Set the text to display in the pop-up message
--! @param text Text to set
--------------------------------------------------------------------------------
function MessageBox:setText(text)
	if self.label then
		LabelComponent_setText(self.label, text)
	end
end

--------------------------------------------------------------------------------
-- setBehaviour
--! @brief Configure the type of behaviour that we expect from this command
--! @param config Behaviour to set
--------------------------------------------------------------------------------
function MessageBox:setBehaviour(behaviour)
	
	self.popupBehaviour = behaviour
	
	-- No buttons available
	if behaviour == POPUP_BEHAVIOUR_BLOCKING then
		if self.invalidate_button then
			WorldNode_setEnabled(self.invalidate_button.worldNode, false)
		end
		if self.validate_button then
			WorldNode_setEnabled(self.validate_button.worldNode, false)
		end
		
	-- Only an OK button
	elseif behaviour == POPUP_BEHAVIOUR_CONFIRM then
		if self.invalidate_button then
			WorldNode_setEnabled(self.invalidate_button.worldNode, false)
		end
		if self.validate_button then
			WorldNode_setEnabled(self.validate_button.worldNode, true)
			WorldNode_setLocalPosition(self.validate_button.worldNode, 0, self.initialValidatePosY)
		end
	
	-- Two buttons, OK and back
	elseif behaviour == POPUP_BEHAVIOUR_CHOOSE then
		if self.invalidate_button then
			WorldNode_setEnabled(self.invalidate_button.worldNode, true)
		end
		if self.validate_button then
			WorldNode_setEnabled(self.validate_button.worldNode, true)
			WorldNode_setLocalPosition(self.validate_button.worldNode, self.initialValidatePosX, self.initialValidatePosY)
		end
	end
	
end

--------------------------------------------------------------------------------
-- start
--! @brief Object is added to the world
--------------------------------------------------------------------------------
function MessageBox:start()
	GUIPopup.start(self)

	self.validate_button = self.ok_button or self.yes_button
	self.invalidate_button = self.cancel_button or self.no_button
	self.initialValidatePosX, self.initialValidatePosY = WorldNode_getLocalPosition(self.validate_button.worldNode)

	self:setBehaviour(POPUP_BEHAVIOUR_CHOOSE)
	
	if self.autoOpen == true then
		self:openPopup()
	else
		WorldNode_setEnabled(self.worldNode, false)
	end
end

--------------------------------------------------------------------------------
-- openPopup
--! @brief Open the popup with an animation
--------------------------------------------------------------------------------
function MessageBox:openPopup()
	self:enable()
	WorldNode_setEnabled(self.worldNode, true)
	
	GUI:focusElement(nil)
	
	self.state = POPUP_STATE_ANIM_OPEN
	Component_enable(self.popup_open_animation)
	AnimatorComponent_setSpeed(self.popup_open_animation, 1)
	AnimatorComponent_play(self.popup_open_animation)
end

--------------------------------------------------------------------------------
-- closePopup
--! @brief Close the popup with an animation and trigger the closing process
--------------------------------------------------------------------------------
function MessageBox:closePopup()
	self:disable()
	self.state = POPUP_STATE_ANIM_CLOSING
	
	GUI:focusElement(nil)
	
	Component_enable(self.popup_open_animation)
	AnimatorComponent_setSpeed(self.popup_open_animation, -1)
	AnimatorComponent_play(self.popup_open_animation)
end

--------------------------------------------------------------------------------
-- close
--! @brief Closes the popup using the given choice and call listener callback
--! @param choice
--------------------------------------------------------------------------------
function MessageBox:close(userChoice)
	self.userChoice = userChoice
	self:closePopup()
end

--------------------------------------------------------------------------------
-- update
--! @brief Performs processing on each frame
--! @param dt delta Time since last update
--------------------------------------------------------------------------------
function MessageBox:update(dt)
	if self.state == POPUP_STATE_ANIM_OPEN then
		if not AnimatorComponent_isPlaying(self.popup_open_animation) then
			self.state = POPUP_STATE_IDLE
		end
	elseif self.state == POPUP_STATE_ANIM_CLOSING then
		if not AnimatorComponent_isPlaying(self.popup_open_animation) then
			self.state = POPUP_STATE_CLOSED
			GUIPopup.close(self, self.userChoice)
		end
	elseif self.state == POPUP_STATE_IDLE then
		if GUI.pressedCommandTarget == nil then -- disable keys when a touch button is pressed

			if GUI:isLeftPressed() or GUI:isRightPressed() or GUI:isUpPressed() or GUI:isDownPressed() then
				self:focusAction()
			elseif GUI:isCancelPressed() and self.popupBehaviour == POPUP_BEHAVIOUR_CHOOSE then
				self:cancelAction()
			elseif GUI.focusedElement == nil and GUI:isValidatePressed() and self.popupBehaviour ~= POPUP_BEHAVIOUR_BLOCKING then
				self:validateAction()
			end
		end
	end
end

function MessageBox:focusAction()
	if self.invalidate_button and self.popupBehaviour == POPUP_BEHAVIOUR_CHOOSE then
		if GUI:isLeftPressed() then
			GUI:focusElement(self.invalidate_button)
		elseif GUI:isRightPressed() then
			GUI:focusElement(self.validate_button)
		end
	elseif self.popupBehaviour ~= POPUP_BEHAVIOUR_BLOCKING then
		GUI:focusElement(self.validate_button)
	end
end

function MessageBox:cancelAction() 
	local isValidateButtonFocused = GUI.focusedElement ~= nil and GUI.focusedElement == self.validate_button

	if isValidateButtonFocused and self.invalidate_button then
		print('Just change focus?')
		GUI:focusElement(self.invalidate_button)
	else
		Input_freeze()

		GUI:focusElement(nil)

		if self.invalidate_button then
			print('self.invalidate_button:playClickedEffects()')
			self.invalidate_button:playClickedEffects()
			self:close("cancel")
		elseif self.validate_button then
			print('self.validate_button:playClickedEffects()')
			self.validate_button:playClickedEffects()
			self:close("ok")
		end
	end
end

function MessageBox:validateAction()
	Input_freeze()
	GUI:focusElement(nil)
	if self.validate_button then
		self.validate_button:playClickedEffects()
		self:close("ok")
	end
end



