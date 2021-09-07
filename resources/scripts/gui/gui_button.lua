require 'gui_element.lua'

--------------------------------------------------------------------------------
-- GUIButton Object script
--! @class GUIButton
--! @parent GUIElement
--! 
--! States
--! * idle
--! * disabled
--! * pressed
--!
--! Attributes 
--! @variable {Component} [pressedVisual] visual for pressed state.
--! @variable {Component} [pressedAnimation] reference to the animator to launch on press
--! @variable {Component} [releasedAnimation] reference to the animator to launch on release
--! @variable {Component} [clickedAnimation] reference to the animator to launch on click
--! @variable {Component} [pressedSound] reference to the sound component to launch on press
--! @variable {Component} [releasedSound] reference to the sound component to launch on release
--! @variable {Component} [clickedSound] reference to the sound component to launch on click
--! @variable {Component} [exitedSound] reference to the sound component to launch when the touch point goes out the button area
--! @variable {Component} [enteredSound] reference to the sound component to launch when the touch point reenters the button area
--!
--! Events
--! * onElementFocus(element)
--! * onElementUnfocus(element)
--! * onButtonPress(button, positionX, positionY)
--! * onButtonRelease(button, positionX, positionY)
--! * onButtonClick(button)
--!
--------------------------------------------------------------------------------

GUIButton = class(GUIElement)

GUIButton.states = class(GUIElement.states)

--------------------------------------------------------------------------------
-- State pressed callbacks
--------------------------------------------------------------------------------
GUIButton.states.pressed = class()

GUIButton.states.pressed.enter = function(element, previousState, ...)
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("GUIButton : enter pressed " .. tostring(element)) end
	if element.pressedVisual ~= nil then
		element:enableVisual(element.pressedVisual)
	else
		element:enableVisual(element.idleVisual)
	end
	
	if element.pressedAnimation ~= nil then
		if GUI.DEBUG_LEVEL.animations then GUI:debugPrint("GUIButton : play pressed animation") end
		Component_enable(element.pressedAnimation)
		AnimatorComponent_setSpeed(element.pressedAnimation, 1.0)
		AnimatorComponent_play(element.pressedAnimation)
	end
	
	local overstep = select(1, ...)

	if overstep and element.enteredSound then
		if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUIButton : play entered sound") end
		SoundComponent_stop(element.enteredSound)
		SoundComponent_play(element.enteredSound)
	elseif element.pressedSound ~= nil then
		if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUIButton : play pressed sound") end
		SoundComponent_stop(element.pressedSound)
		SoundComponent_play(element.pressedSound)
	end
end
	
GUIButton.states.pressed.leave = function(element, nextState, ...)
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("GUIButton : leave pressed " .. tostring(element)) end
	if element.pressedVisual ~= nil then
		element:disableVisual(element.pressedVisual)
	else
		element:disableVisual(element.idleVisual)
	end
	
	if element.pressedAnimation ~= nil then --and (not element.clickedAnimation or not Component_isEnabled(element.clickedAnimation) or not AnimatorComponent_isPlaying(element.clickedAnimation)) then
		if GUI.DEBUG_LEVEL.animations then GUI:debugPrint("GUIButton : play released animation") end
		--Component_enable(element.releasedAnimation)
		--AnimatorComponent_play(element.releasedAnimation)
		AnimatorComponent_setSpeed(element.pressedAnimation, -1.0)
		AnimatorComponent_play(element.pressedAnimation)
	end
	
	local overstep = select(1, ...)

	if overstep and element.exitedSound then
		if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUIButton : play exited sound") end
		SoundComponent_stop(element.exitedSound)
		SoundComponent_play(element.exitedSound)
	elseif element.releasedSound ~= nil and (element.clickedSound == nil or not SoundComponent_isPlaying(element.clickedSound)) then
		if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUIButton : play released sound") end
		SoundComponent_stop(element.releasedSound)
		SoundComponent_play(element.releasedSound)
	end
end



--------------------------------------------------------------------------------
-- start
--! @brief Callback when the object is added to the world
--------------------------------------------------------------------------------
function GUIButton:start()

	if GUI.DEBUG_LEVEL.runtime then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIButton:start()") end
	self:setupClickableArea()
	self:disableVisual(self.pressedVisual)
	
	self:setupAnimator(self.clickedAnimation)
	self:setupAnimator(self.pressedAnimation)
	self:setupAnimator(self.releasedAnimation)
	
	GUIElement.start(self)
	
	GUI:registerButton(self)
	
end

--------------------------------------------------------------------------------
-- stop
--! @brief Callback when the object is removed from to the world
--------------------------------------------------------------------------------
function GUIButton:stop()
	
	GUI:unregisterButton(self)
	
	GUIElement.stop(self)
end

--------------------------------------------------------------------------------
-- playClickedEffects
--! @brief Plays the clicked animation and clicked sound of this button, if any
--------------------------------------------------------------------------------
function GUIButton:playClickedEffects()
	self:playClickedAnimation()
	self:playClickedSound()
end

--------------------------------------------------------------------------------
-- playClickedAnimation
--! @brief Plays the clicked animation referenced by the clickedAnimation attribute
--------------------------------------------------------------------------------
function GUIButton:playClickedAnimation()
	if self.clickedAnimation ~= nil then
		if GUI.DEBUG_LEVEL.animations then GUI:debugPrint("GUIButton : play clicked animation") end
		self:playAnimation(self.clickedAnimation)
	end
end

--------------------------------------------------------------------------------
-- playClickedSound
--! @brief Plays the clicked sound referenced by the clickedSound attribute
--------------------------------------------------------------------------------
function GUIButton:playClickedSound()
	if self.clickedSound then
		if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUIButton : play clicked sound") end
		SoundComponent_stop(self.clickedSound)
		SoundComponent_play(self.clickedSound)
	end
end

--------------------------------------------------------------------------------
-- resetAnimation()
--! @brief Resets all button animations to their initial state
--------------------------------------------------------------------------------
function GUIButton:resetAnimations()
	if self.clickedAnimation then
		self:resetAnimation(self.clickedAnimation)
	end
	if self.pressedAnimation then
		self:resetAnimation(self.pressedAnimation)
	end
	if self.releasedAnimation then
		self:resetAnimation(self.releasedAnimation)
	end
end

--------------------------------------------------------------------------------
-- onCommand
--! @brief Function to handle a gui command sent by the GUI system to the element
--! @param command command to handle
--------------------------------------------------------------------------------
function GUIButton:onCommand(command)
	if GUI.DEBUG_LEVEL.commands then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIButton:onCommand() " .. tostring(command.id)) end
		
	if command.id == GUI_COMMAND_PRESS then
		if GUI.DEBUG_LEVEL.actions then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIButton pressed ") end
		self:setState("pressed", command.overstep)
		if self.listener ~= nil and self.listener.onButtonPress ~= nil then
			self.listener:onButtonPress(self, command.posX, command.posY)
		end

		return true
		
	elseif command.id == GUI_COMMAND_RELEASE then
		if GUI.DEBUG_LEVEL.actions then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIButton released ") end
		self:setState("idle", command.overstep)
		if self.listener ~= nil and self.listener.onButtonRelease ~= nil then
			self.listener:onButtonRelease(self, command.posX, command.posY)
		end

		
		return true
		
	elseif command.id == GUI_COMMAND_CLICK then
		if GUI.DEBUG_LEVEL.actions then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIButton clicked ") end
		
		self:playClickedEffects()

		if self.listener ~= nil and self.listener.onButtonClick ~= nil then
			self.listener:onButtonClick(self)
		end

		return true
	else 
		return GUIElement.onCommand(self, command)
	end
	
end
