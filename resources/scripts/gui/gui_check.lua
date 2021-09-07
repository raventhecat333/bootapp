require 'gui_button.lua'

--------------------------------------------------------------------------------
-- GUICheckButton Object script
--! @class GUICheckButton
--! @parent GUIButton
--! 
--! States
--! * idle
--! * disabled
--! * pressed
--!
--! Attributes
--! @variable {Component} [checkedVisual] visual for checked state
--! @variable {Component} [uncheckedVisual] visual for unchecked state
--! @variable {Component} [checkedPressVisual] visual for checked state in pressed mode. If not provided, it fallbacks on checkVisual
--! @variable {Component} [uncheckedPressVisual] visual for unchecked state. If not provided, it fallbacks on idleVisual
--! @variable {Boolean}   [checked] initial check state. Default false
--! @variable {Component} [checkedAnimation] Reference to animator component that is played on checked
--! @variable {Component} [uncheckedAnimation] Reference to animator component that is played on unchecked
--! @variable {Component} [checkedSound] Reference to sound component that is played on checked
--! @variable {Component} [uncheckedSound] Reference to sound component that is played on unchecked

--!
--! Events
--! * onButtonPress(button, positionX, positionY)
--! * onButtonRelease(button, positionX, positionY)
--! * onButtonClick(button)
--! * onCheckToggle(check, checked_flag)
--!
--------------------------------------------------------------------------------

GUICheckButton = class(GUIButton)

GUICheckButton.states = class(GUIButton.states)

--------------------------------------------------------------------------------
-- State idle callbacks
--------------------------------------------------------------------------------
GUICheckButton.states.idle = class(GUIButton.states.idle) 
GUICheckButton.states.idle.enter = function(checkButton, previousState)
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("GUICheckButton : enter idle " .. tostring(checkButton)) end
	
	checkButton:updateVisual(false)	
end

GUICheckButton.states.idle.leave = function(checkButton, nextState)
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("GUICheckButton : leave idle " .. tostring(checkButton)) end

	checkButton:disableVisual(checkButton.checkedVisual)
	checkButton:disableVisual(checkButton.uncheckedVisual)

end


--------------------------------------------------------------------------------
-- State pressed callbacks
--------------------------------------------------------------------------------
GUICheckButton.states.pressed = class(GUIButton.states.pressed)
GUICheckButton.states.pressed.enter = function(checkButton, previousState, ...)
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("GUICheckButton : enter pressed " .. tostring(checkButton)) end
		
	checkButton:updateVisual(true)
	
	local overstep = select(1, ...)

	if overstep and checkButton.enteredSound then
		if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUICheckButton : play entered sound") end
		SoundComponent_stop(checkButton.enteredSound)
		SoundComponent_play(checkButton.enteredSound)
	elseif checkButton.pressedSound ~= nil then
		if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUICheckButton : play pressed sound") end
		SoundComponent_stop(checkButton.pressedSound)
		SoundComponent_play(checkButton.pressedSound)
	end
end
	
GUICheckButton.states.pressed.leave = function(checkButton, nextState, ...)
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("GUICheckButton : leave pressed " .. tostring(checkButton)) end
	
	checkButton:disableVisual(checkButton.checkedPressVisual)
	checkButton:disableVisual(checkButton.uncheckedPressVisual)

	local overstep = select(1, ...)

	if overstep and checkButton.exitedSound then
		if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUICheckButton : play exited sound") end
		SoundComponent_stop(checkButton.exitedSound)
		SoundComponent_play(checkButton.exitedSound)
	elseif checkButton.releasedSound ~= nil then
		if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUICheckButton : play released sound") end
		SoundComponent_stop(checkButton.releasedSound)
		SoundComponent_play(checkButton.releasedSound)
	end

end
	
--------------------------------------------------------------------------------
-- start
--! @brief Callback when the object is added to the world
--------------------------------------------------------------------------------
function GUICheckButton:start()
	if GUI.DEBUG_LEVEL.runtime then GUI:debugPrint("[" .. tostring(self) .. "]\tGUICheckButton:start()") end

	if not self.uncheckedVisual then
		self.uncheckedVisual = self.idleVisual
	end

	if not self.uncheckedPressVisual then
		self.uncheckedPressVisual = self.pressedVisual
	end
	if not self.uncheckedPressVisual then
		self.uncheckedPressVisual = self.idleVisual
	end
	
	if not self.checkedPressVisual then
		self.checkedPressVisual = self.checkedVisual
	end

	self:disableVisual(self.checkedPressVisual)
	self:disableVisual(self.uncheckedPressVisual)
	self:disableVisual(self.checkedVisual)
	self:disableVisual(self.uncheckedVisual)
	
	GUIButton.start(self)

	if self.checked == nil then
		self:setChecked(false)
	else
		self:setChecked(self.checked)
	end
	
end

--------------------------------------------------------------------------------
-- updateVisual
--! @ brief Enables the proper visual according to current check button state
--! @param pressed Indicates whether the checkButton is pressed or not
--------------------------------------------------------------------------------
function GUICheckButton:updateVisual(pressed)
	
	if pressed == nil then
		pressed = (self.currentState == "pressed")
	end
	
	if not pressed then
		if not self.checked then
			self:disableVisual(self.checkedVisual)
			self:enableVisual(self.uncheckedVisual)
		else
			self:disableVisual(self.uncheckedVisual)
			self:enableVisual(self.checkedVisual)
		end
	else
		if not self.checked then
			self:disableVisual(self.checkedPressVisual)
			self:enableVisual(self.uncheckedPressVisual)
		else
			self:disableVisual(self.uncheckedPressVisual)
			self:enableVisual(self.checkedPressVisual)
		end
	end
end


--------------------------------------------------------------------------------
-- playClickedEffects
--! @brief Plays the clicked animation and sound of this button according to its state
--------------------------------------------------------------------------------
function GUICheckButton:playClickedEffects()

	if self.checked then
		if not self:playCheckedSound() then
			self:playClickedSound()
		end
		if not self:playCheckedAnimation() then
			self:playClickedAnimation()
		end
	else
		if not self:playUncheckedSound() then
			self:playClickedSound()
		end
		if not self:playUncheckedAnimation() then
			self:playClickedAnimation()
		end
	end
end

--------------------------------------------------------------------------------
-- playCheckedSound
-- @brief Plays the checked sound if exists
--------------------------------------------------------------------------------
function GUICheckButton:playCheckedSound()
	if self.checkedSound ~= nil then
		if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUICheckButton : play checked sound") end
		SoundComponent_stop(self.checkedSound)
		SoundComponent_play(self.checkedSound)
		return true
	end
end

--------------------------------------------------------------------------------
-- playUncheckedSound
-- @brief Plays the unchecked sound if exists
--------------------------------------------------------------------------------
function GUICheckButton:playUncheckedSound()
	if self.uncheckedSound ~= nil then
		if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUICheckButton : play unchecked sound") end
		SoundComponent_stop(self.uncheckedSound)
		SoundComponent_play(self.uncheckedSound)
		return true
	end
end

--------------------------------------------------------------------------------
-- playCheckedAnimation
-- @brief Plays the checked animation if exists
--------------------------------------------------------------------------------
function GUICheckButton:playCheckedAnimation()
	if self.checkedAnimation ~= nil then
		if GUI.DEBUG_LEVEL.animations then GUI:debugPrint("GUICheckButton : play checked animation") end
		self:playAnimation(self.checkedAnimation)
		return true
	end
end

--------------------------------------------------------------------------------
-- playUncheckedAnimation
-- @brief Plays the uncheckedAnimation if exists
--------------------------------------------------------------------------------
function GUICheckButton:playUncheckedAnimation()
	if self.uncheckedAnimation ~= nil then
		if GUI.DEBUG_LEVEL.animations then GUI:debugPrint("GUICheckButton : play unchecked animation") end
		self:playAnimation(self.uncheckedAnimation)
		return true
	end
end

--------------------------------------------------------------------------------
-- onCommand
--! @brief Function to handle a gui command sent by the GUI system to the element
--! @param command command to handle
--------------------------------------------------------------------------------
function GUICheckButton:onCommand(command)
	if GUI.DEBUG_LEVEL.commands then GUI:debugPrint("[" .. tostring(self) .. "]\tGUICheckButton:onCommand() " .. tostring(command.id)) end
		
	if command.id == GUI_COMMAND_CLICK then
		if GUI.DEBUG_LEVEL.actions then GUI:debugPrint("[" .. tostring(self) .. "]\tGUICheckButton clicked ") end
		
		self:setChecked(not self.checked)

		self:updateVisual()

		self:playClickedEffects()
		
		if self.listener ~= nil and self.listener.onCheckToggle ~= nil then
			self.listener:onCheckToggle(self, self.checked)
		end

		return true
		
	else 
		return GUIButton.onCommand(self, command)
	end
	
end

--------------------------------------------------------------------------------
-- setChecked
--! @brief Sets the checked flag and change the visual accordingly
--! @param checked new flag
--------------------------------------------------------------------------------
function GUICheckButton:setChecked(checked)
	
	if self.checked == checked then
		return
	end
	
	self.checked = checked
	
	if not self.checked then
		self:disableVisual(self.checkedVisual)
		self:enableVisual(self.uncheckedVisual)
	else
		self:disableVisual(self.uncheckedVisual)
		self:enableVisual(self.checkedVisual)
	end
		
end

--------------------------------------------------------------------------------
-- isChecked
--! @brief Returns whether the button is checked or not
--------------------------------------------------------------------------------
function GUICheckButton:isChecked()
	return self.checked
end

