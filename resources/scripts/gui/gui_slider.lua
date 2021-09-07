require 'gui_element.lua'

--------------------------------------------------------------------------------
-- GUISlider Object script
--! @class GUISlider
--! @parent GUIElement
--! States
--! * idle
--!
--! Attributes
--! @variable {Component} thumbElement script component of the thumb node
--! @variable {String}    [direction] either "horizontal" or "vertical". Default horizontal.
--! @variable {Number}    [startValue] value at left/bottom end. Default 0
--! @variable {Number}    [endValue] value at right/top end. Default 1
--! @variable {Number}    [currentValue] initial value. Default 0
--! @variable {Number}    [dragThreshold] minimum move value in pixels to start thumb manipulation. Default 4
--! @variable {Number}    [increment] value offset when direction keys are pressed. Default 0.2
--!
--! Events
--! * onSliderPressed(slider, current_value)
--! * onSliderDragStart(slider, current_value)
--! * onSliderReleased(slider, current_value)
--! * onSliderValueChange(slider, newValue)
--!
--------------------------------------------------------------------------------

GUISlider = class(GUIElement)

GUISlider.states = class(GUIElement.states)

--------------------------------------------------------------------------------
-- State disabled callbacks
--------------------------------------------------------------------------------
GUISlider.states.disabled = class()
GUISlider.states.disabled.enter = function(element, previousState)
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("GUISlider : Enter disabled " .. tostring(element) .. " previousState = " .. tostring(previousState)) end
	
	GUIElement.states.disabled.enter(element, previousState)
	
	element.thumbElement:setState('disabled')
end
GUISlider.states.disabled.leave = function(element, nextState)
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("GUISlider : leave disabled " .. tostring(element)) end
	
	GUIElement.states.disabled.leave(element, nextState)
	
	element.thumbElement:setState(nextState)
end

--------------------------------------------------------------------------------
-- start
--! @brief Callback when the object is added to the world
--------------------------------------------------------------------------------
function GUISlider:start()
	
	if GUI.DEBUG_LEVEL.runtime then GUI:debugPrint("[" .. tostring(self) .. "]\tGUISlider:start()") end
	
	if self.thumbElement == nil then
		GUI:error(" GUISlider does not have a reference to a thumb element")
		return
	else
		self.thumbElement = ScriptComponent_getScriptTable(self.thumbElement)
		if self.thumbElement.idleVisual ~= nil then
			self.thumbElementWidth, self.thumbElementHeight = VisualComponent_getSize(self.thumbElement.idleVisual)
		end
		
		self:enforceListenerToSelf(self.thumbElement, "GUISlider", "Thumb")
		self.thumbElement.preListener = self
	end
	
	if self.direction == nil then
		self.direction = "horizontal"
	end
	
	if self.startValue == nil then
		self.startValue = 0
	end
	
	if self.endValue == nil then
		self.endValue = 1
	end
	
	self:setValueBounds(self.startValue, self.endValue)
	
	if self.dragThreshold == nil then
		self.dragThreshold = 4
	end
	
	if self.increment == nil then
		self.increment = 0.02
	end

	if self.states == nil then
		self.states = GUIElement.element_states
	end
	
	self:setupClickableArea()
	
	GUIElement.start(self)
	
	if self.currentValue == nil then
		self.currentValue = 0
	end
	
	self:setValue(self.currentValue)
	
	self.isDragEngaged = false
	self.isDragging = false

end

--------------------------------------------------------------------------------
-- onCommand
--! @brief Function to handle a gui command sent by the GUI system to the element
--! @param command command to handle
--------------------------------------------------------------------------------
function GUISlider:onCommand(command)
	
	if GUI.DEBUG_LEVEL.commands then GUI:debugPrint("[" .. tostring(self) .. "]\tGUISlider:onCommand() " .. tostring(command.id)) end
	
	if command.id == GUI_COMMAND_FOCUS or command.id == GUI_COMMAND_UNFOCUS then
		return self.thumbElement:sendCommand(command)
	elseif command.id == GUI_COMMAND_CLICK then
		
		if command.posX and command.posY then
			local localPosX, localPosY = WorldNode_worldToLocalPosition(self.worldNode, command.posX, command.posY)
			self:moveThumb(localPosX, localPosY)
			
			if self.listener ~= nil and self.listener.onSliderValueChange ~= nil then
				self.listener:onSliderValueChange(self, self.currentValue)
			end
		end
		return self.thumbElement:sendCommand(command)
		
	elseif command.id == GUI_COMMAND_DRAG then
		local localPosX, localPosY = WorldNode_worldToLocalPosition(self.worldNode, command.posX, command.posY)
		
		if command.first then
			self.isDragEngaged = false
		end
		
		if not self.isDragging then
			if not self.isDragEngaged then
				local localPrevPosX, localPrevPosY = WorldNode_worldToLocalPosition(self.worldNode, command.previousPosX, command.previousPosY)

				self.isDragEngaged = true
				local isHorizontalDrag = math.abs(localPosX - localPrevPosX) > math.abs(localPosY - localPrevPosY)
				
				if self.direction == "horizontal" and not isHorizontalDrag or
				   self.direction == "vertical" and isHorizontalDrag then
				   	return false
				end
				
				self.isDragging = true
				
				if self.listener ~= nil and self.listener.onSliderDragStart ~= nil then
					self.listener:onSliderDragStart(self, self.currentValue)
				end
				
			end	
		else
			self:moveThumb(localPosX, localPosY)
			
			if self.listener ~= nil and self.listener.onSliderValueChange ~= nil then
				self.listener:onSliderValueChange(self, self.currentValue)
			end
			return true
		end
	elseif command.id == GUI_COMMAND_RELEASE then
		if GUI.DEBUG_LEVEL.actions then GUI:debugPrint("[" .. tostring(self) .. "]\tGUISlider release ") end
		if self.listener ~= nil and self.listener.onSliderReleased ~= nil then
			self.listener:onSliderReleased(self, self.currentValue)
		end
		self.isDragEngaged = false
		self.isDragging = false
		return self.thumbElement:sendCommand(command)
	elseif command.id == GUI_COMMAND_LEFT and self.direction == "horizontal" and self.currentValue > 0.0 then
		if GUI.DEBUG_LEVEL.actions then GUI:debugPrint("[" .. tostring(self) .. "]\tGUISlider Key left " .. tostring(self)) end
		self:setValue(self.currentValue - self.increment)
		return true
	elseif command.id == GUI_COMMAND_RIGHT and self.direction == "horizontal" and self.currentValue < 1.0 then
		if GUI.DEBUG_LEVEL.actions then GUI:debugPrint("[" .. tostring(self) .. "]\tGUISlider Key right " .. tostring(self)) end
		self:setValue(self.currentValue + self.increment)
		return true
	elseif command.id == GUI_COMMAND_UP and self.direction == "vertical" and self.currentValue > 0.0 then
		if GUI.DEBUG_LEVEL.actions then GUI:debugPrint("[" .. tostring(self) .. "]\tGUISlider Key up " .. tostring(self)) end
		self:setValue(self.currentValue - self.increment)
		return true
	elseif command.id == GUI_COMMAND_DOWN and self.direction == "vertical" and self.currentValue < 1.0 then
		if GUI.DEBUG_LEVEL.actions then GUI:debugPrint("[" .. tostring(self) .. "]\tGUISlider Key down " .. tostring(self)) end
		self:setValue(self.currentValue + self.increment)
		return true
	-- elseif command.id == GUI_COMMAND_RELEASE then
		
	else
		return GUIElement.onCommand(self, command)
	end
	
end

--------------------------------------------------------------------------------
-- onButtonPress
--! @brief Callback when a button is pressed
--! @param button Button that is pressed
--------------------------------------------------------------------------------
function GUISlider:onButtonPress(button, posX, posY)
	
	if not posX or not posY then
		return
	end
	
	if button == self.thumbElement then
		if GUI.DEBUG_LEVEL.callbacks then GUI:debugPrint("[" .. tostring(self) .. "]\tGUISlider -> thumb pressed @ " .. posX .. "," .. posY) end
		local thumbPosX, thumbPosY = WorldNode_getLocalPosition(self.thumbElement.worldNode)
		sliderPosX = thumbPosX + posX
		sliderPosY = thumbPosY + posY
		
		if not self.thumbPressedStarted then
			self.thumbPressedStarted = true
			
			--Component_disable(self.thumbElement.clickable)
			
			self.thumbPressedStartPosX = sliderPosX
			self.thumbPressedStartPosY = sliderPosY
			
			if self.listener ~= nil and self.listener.onSliderPressed ~= nil then
				self.listener:onSliderPressed(self, self.currentValue)
			end
		elseif not self.thumbDragStarted then
			if self.direction == "horizontal" and math.abs(self.thumbPressedStartPosX - sliderPosX) > self.dragThreshold then
				self.thumbDragStarted = true
			elseif self.direction == "vertical" and math.abs(self.thumbPressedStartPosY, sliderPosY) > self.dragThreshold then
				self.thumbDragStarted = true
			end
		else
			self:moveThumb(sliderPosX, sliderPosY)
			
			if self.listener ~= nil and self.listener.onSliderValueChange ~= nil then
				self.listener:onSliderValueChange(self, self.currentValue)
			end

			-- self:sendCommand({id = GUI_COMMAND_PRESS, posX = sliderPosX, posY = sliderPosY })
		end
	end
	
end

--------------------------------------------------------------------------------
-- onButtonRelease
--! @brief Callback when a button has been released
--! @param button Button that is released
--------------------------------------------------------------------------------
function GUISlider:onButtonRelease(button)
	if button == self.thumbElement then
		if GUI.DEBUG_LEVEL.callbacks then GUI:debugPrint("[" .. tostring(self) .. "]\tGUISlider -> Thumb released") end
		--Component_enable(self.thumbElement.clickable)
		
		self.thumbPressedStarted = false
		self.thumbDragStarted = false
	end
end

--------------------------------------------------------------------------------
-- setValueBounds
--! @brief Sets the start and end value of the slider
--! @param startValue value at left/bottom end of the slider
--! @param endValue   value at right/top end of the slider
--------------------------------------------------------------------------------
function GUISlider:setValueBounds(startValue, endValue)
	self.startValue = startValue
	self.endValue = endValue
	
	self.minValue = math.min(self.startValue, self.endValue)
	self.maxValue = math.max(self.startValue, self.endValue)
end

--------------------------------------------------------------------------------
-- getNormalizedValue
--! @brief Returns the current slider value normalized between 0 and 1
--------------------------------------------------------------------------------
function GUISlider:getNormalizedValue()
	return (self.currentValue - self.startValue) / (self.endValue - self.startValue)
end

--------------------------------------------------------------------------------
-- setNormalizedValue
--! @brief Changes the slider normalized value
--! @param normalizedValue value between 0 and 1
--------------------------------------------------------------------------------
function GUISlider:setNormalizedValue(normalizedValue)
	self:setValue(self.startValue * (1 - normalizedValue) + self.endValue * normalizedValue)
end

--------------------------------------------------------------------------------
-- setValue
--! @brief Changes the slider value position
--! @param newValue value between startValue and endValue
--------------------------------------------------------------------------------
function GUISlider:setValue(newValue)
	
	self.currentValue = Math.clamp(newValue, self.minValue, self.maxValue)
	
	local normalizedValue = self:getNormalizedValue()
	
	local width, height = ClickableComponent_getBoxShapeSize(self.clickable)
	
	if self.direction == "horizontal" then
		local posX = width * normalizedValue - width / 2
		WorldNode_setLocalPosition(self.thumbElement.worldNode, posX, 0)
	elseif self.direction == "vertical" then
		local posY = height * normalizedValue - height / 2
		WorldNode_setLocalPosition(self.thumbElement.worldNode, 0, posY)
	end
	
end

--------------------------------------------------------------------------------
-- moveThumb
--! @brief Moves the thumb object within the slider area
--! @param posX slider local position X
--! @param posY slider local position Y
--------------------------------------------------------------------------------
function GUISlider:moveThumb(posX, posY)
	local width, height = ClickableComponent_getBoxShapeSize(self.clickable)
	if self.direction == "horizontal" then
		posX = Math.clamp(posX, -width / 2, width / 2)
		WorldNode_setLocalPosition(self.thumbElement.worldNode, posX, 0)
		local normalizedValue = (posX + width / 2) / width
		self.currentValue = self.startValue * (1 - normalizedValue) + self.endValue * normalizedValue
	elseif self.direction == "vertical" then
		posY = Math.clamp(posY, -height / 2, height / 2)
		WorldNode_setLocalPosition(self.thumbElement.worldNode, 0, posY)
		local normalizedValue = (posY + height / 2) / height
		self.currentValue = self.startValue * (1 - normalizedValue) + self.endValue * normalizedValue
	end
end

