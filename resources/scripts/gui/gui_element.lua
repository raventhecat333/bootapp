require 'scripts/core/core.lua'

--------------------------------------------------------------------------------
-- GUIElement Object script
--! @class GUIElement
--! 
--! States
--! * idle
--! * disabled
--!
--! Attributes
--! @variable {LuaTable}  [preListener] script component that listens and validates the commands the element receives.
--! @variable {Component} [listener] script component that listens to the element events.
--! @variable {Component} [clickable] area for click detection. If not defined, it is automatically created.
--! @variable {Boolean}   [autoAdjustClickableArea] flag that determines automatic adjusment of the clickable area according to the currrent visual. Default true when no clickable is defined else false.
--! @variable {Component} [idleVisual] visual for idle state.
--! @variable {Component} [focusedVisual] visual for focused state.
--! @variable {Component} [disabledVisual] visual for disabled state.
--! @variable {Component} [focusedAnimation] reference to the animator to launch on focus
--! @variable {Component} [focusedSound] reference to the sound component to launch on focus
--! @variable {Component} [unfocusedSound] reference to the sound component to launch on unfocus
--! @variable {Boolean}   [autoFocusDisabled] cannot be auto-focused through key navigation. Default false
--! @variable {LuaTable}  [leftElement] Element to navigate to when a left command is triggered
--! @variable {LuaTable}  [rightElement] Element to navigate to when a right command is triggered
--! @variable {LuaTable}  [upElement] Element to navigate to when an up command is triggered
--! @variable {LuaTable}  [downElement] Element to navigate to when a down command is triggered
--! 
--! Events
--! * onElementFocus(element)
--! * onElementUnfocus(element)
--!
--! Pre-listener events
--! * onElementCommand(element, command)
--------------------------------------------------------------------------------

GUIElement = class()
GUIElement.states = class()
GUIElement.isGUIElement = true
--------------------------------------------------------------------------------
-- State idle callbacks
--------------------------------------------------------------------------------
GUIElement.states.idle = class()
GUIElement.states.idle.enter = function(element, previousState)
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("GUIElement : Enter idle " .. tostring(element) .. " previousState = " .. tostring(previousState)) end
	element:enableVisual(element.idleVisual)
end
GUIElement.states.idle.leave = function(element, nextState)
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("GUIElement : leave idle " .. tostring(element)) end
	element:disableVisual(element.idleVisual)
end
--------------------------------------------------------------------------------
-- State disabled callbacks
--------------------------------------------------------------------------------
GUIElement.states.disabled = class()
GUIElement.states.disabled.enter = function(element, previousState)
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("GUIElement : Enter disabled " .. tostring(element) .. " previousState = " .. tostring(previousState)) end
	if element.disabledVisual then
		element:enableVisual(element.disabledVisual)
	else
		element:enableVisual(element.idleVisual)
	end
	Component_disable(element.clickable)
end
GUIElement.states.disabled.leave = function(element, nextState)
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("GUIElement : leave disabled " .. tostring(element)) end
	if element.disabledVisual then
		element:disableVisual(element.disabledVisual)
	else
		element:disableVisual(element.idleVisual)
	end
	Component_enable(element.clickable)
end


--------------------------------------------------------------------------------
-- start
--! @brief Callback when the object is added to the world
--------------------------------------------------------------------------------
function GUIElement:start()

	self.currentState = "none"

	if GUI.DEBUG_LEVEL.runtime then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIElement:start()") end
	
	self:disableVisual(self.idleVisual)
	self:disableVisual(self.disabledVisual)
	if self.focusedVisual ~= nil then
		Component_disable(self.focusedVisual)
	end
	
	if self.listener ~= nil then
		self.listener = ScriptComponent_getScriptTable(self.listener)
	end
	
	if self.ownClickable == nil then
		self.ownClickable = false
	end
	
	if not self.parent then
		self:findParentElement()
	end
	
	if not self.autoFocusDisabled then
		self.autoFocusDisabled = false
	end
	
	self:setupAnimator(self.focusedAnimation)

	self:setState("idle")
end

--------------------------------------------------------------------------------
-- stop
--! @brief Callback when object is removed from the world
--------------------------------------------------------------------------------
function GUIElement:stop()
	if GUI.DEBUG_LEVEL.runtime then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIElement:stop()") end
	
	if self.clickable ~= nil and self.ownClickable then
		removeAndDestroyComponentFromNode(self.worldNode, self.clickable)
	end
	
end

--------------------------------------------------------------------------------
-- update
--! @brief Callback called every frames
--! @param dt delta time since last frame
--------------------------------------------------------------------------------
function GUIElement:update(dt)
	
	local states = self.states
	if states ~= nil then
		local currentState = states[self.currentState]
		if currentState ~= nil and currentState.update ~= nil then
			currentState:update(self, dt)
		end
	end
	
end

--------------------------------------------------------------------------------
--! getName
--! @brief Returns the element node's name
--! return name as a string
--------------------------------------------------------------------------------
function GUIElement:getName()
	return WorldNode_getName(self.worldNode)
end

--------------------------------------------------------------------------------
-- setState
--! @brief Changes the current state of the element calling the appropriate
--!        state callbacks.
--! @note Nothing is performed if the provided state is the current one
--! @param newState state to change to
--------------------------------------------------------------------------------
function GUIElement:setState(newState, ...)
	
	if newState == self.currentState then
		return
	end
	
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIElement:setState() setState = " .. newState) end
	if GUI.DEBUG_LEVEL.states then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIElement:setState() curState = " .. self.currentState) end

	if self.states[self.currentState] ~= nil and self.states[self.currentState].leave ~= nil then
		self.states[self.currentState].leave(self, newState, ...)
	end
	
	local previousState = self.currentState
	self.currentState = newState
	
	if self.states[self.currentState] ~= nil and self.states[self.currentState].enter ~= nil then
		self.states[self.currentState].enter(self, previousState, ...)
	end
	
end

--------------------------------------------------------------------------------
-- setupClickableArea
--! @brief Creates a clickable component that is linked to this GUI element (as a listener).
--!        If already exist, check that its listener references the gui element
--------------------------------------------------------------------------------
function GUIElement:setupClickableArea()
	if self.clickable == nil then
		if GUI.DEBUG_LEVEL.hit_test then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIElement:setupClickableArea()") end
		self.clickable = addNewComponentToNode(self.worldNode, COMPONENT_TYPE_CLICKABLE)
		self.ownClickable = true
		ClickableComponent_setClickListener(self.clickable, self._ptr)
		if self.autoAdjustClickableArea == nil then
			self.autoAdjustClickableArea = true
		end
	else
		local listener = ClickableComponent_getClickListener(self.clickable)
		if listener ~= nil and listener ~= self._ptr then
			GUI:warning("Warning! the listener of a clickable associated to a GUIButton script does not reference the GUIButton. Overriding...")
		end
		ClickableComponent_setClickListener(self.clickable, self._ptr)
		if self.autoAdjustClickableArea == nil then
			self.autoAdjustClickableArea = false
		end
		
		self.ownClickable = false
	end
	
	Component_setEnabled(self.clickable, Component_isSelfEnabled(self._ptr))
end

--------------------------------------------------------------------------------
-- setupAnimator
--! @brief First disables the animator component and links it to the gui element by setting its event listener
--! @param animator Animator component to setup
--------------------------------------------------------------------------------
function GUIElement:setupAnimator(animator)
	if animator ~= nil then
		Component_disable(animator)
		local listener = AnimatorComponent_getEventListener(animator)
		if listener ~= nil and listener ~= self._ptr then
			GUI:warning("Warning! the event listener of an animator associated to a GUIElement script does not reference the GUIElement. Overriding...")
		end
		AnimatorComponent_setEventListener(animator, self._ptr)
	end
end

--------------------------------------------------------------------------------
-- enforceListenerToSelf
--! @brief Makes sure that the provided element listener is referencing self
--! @param element element to enforce the listener attribute
--! @param element_type name of the element
--! @param sub_element_type name of element to enforce
--------------------------------------------------------------------------------
function GUIElement:enforceListenerToSelf(element, element_type, sub_element_type)
	GUI:enforceListener(element, self, element_type, sub_element_type)
end

--------------------------------------------------------------------------------
-- playAnimation
--! @brief Starts the provided animator
--! @param animator Animator component controlling the animation
--------------------------------------------------------------------------------
function GUIElement:playAnimation(animator)
	if animator ~= nil then
		Component_enable(animator)
		AnimatorComponent_reset(animator)
		AnimatorComponent_play(animator)
	end
end

--------------------------------------------------------------------------------
-- playAnimation
--! @brief Restores the given animator to its initial state
--! @param animator Animator component controlling the animation
--------------------------------------------------------------------------------
function GUIElement:resetAnimation(animator, speed)
	local test = speed or 1.0
	AnimatorComponent_stop(animator)
	AnimatorComponent_setSpeed(animator, speed or 1.0)
	AnimatorComponent_reset(animator)
end

--------------------------------------------------------------------------------
-- enableVisual
--! @brief Enables the provided visual component
--! @note It adjusts the clickable component size according to the visual size if the attribute autoAdjustClickableArea is true
--! @param visual Visual to enable
--------------------------------------------------------------------------------
function GUIElement:enableVisual(visual)
	if visual ~= nil then
		Component_enable(visual)
		self.currentVisual = visual
		if self.clickable ~= nil then
			local layer = VisualComponent_getLayer(visual)
			
			ClickableComponent_setLayer(self.clickable, layer)
			
			local areaWidth, areaHeight = ClickableComponent_getBoxShapeSize(self.clickable)
			
			if self.autoAdjustClickableArea or areaWidth == 0 or areaHeight == 0 then
				local sizeX, sizeY = VisualComponent_getSize(visual)
				if GUI.DEBUG_LEVEL.hit_test then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIElement clickableArea size = " .. tostring(sizeX) .. " " .. tostring(sizeY)) end
				ClickableComponent_setBoxShape(self.clickable, sizeX, sizeY)
			end
			
		end
	end
end

--------------------------------------------------------------------------------
-- disableVisual
--! @brief Disables the provided visual component
--! @param visual Visual to disable. if nil, the current visual is disabled
--------------------------------------------------------------------------------
function GUIElement:disableVisual(visual)
	if visual ~= nil then
		Component_disable(visual)
		self.currentVisual = nil
	end
end

--------------------------------------------------------------------------------
-- isautoFocusDisabled
--! @brief Return true if we can't autofocus this
--------------------------------------------------------------------------------
function GUIElement:isAutoFocusDisabled()
	return (self.autoFocusDisabled == true)
end

--------------------------------------------------------------------------------
-- forwardToPreListener
--! @brief Forwards the specified command to this element's pre-listener, if there is one
--! @param command command to forward
--! @return true if command was handled, false otherwise
--------------------------------------------------------------------------------
function GUIElement:forwardCommandToPreListener(command)
	if self.preListener ~= nil and self.preListener.onElementCommand ~= nil then
		--if GUI.DEBUG_LEVEL.commands then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIElement:forwardCommandToPreListener " .. tostring(command.id)) end
		return self.preListener:onElementCommand(self, command)
	end

	return false
end

--------------------------------------------------------------------------------
-- onElementCommand
--! @brief Function to receive the commands of other elements when set as a pre-listener on them.
--!        Default implementation only forwards the command to the pre-listener.
--! @param element the element which is receiving the command
--! @param command the received command
--! @return true if command was handled, false otherwise
--------------------------------------------------------------------------------
function GUIElement:onElementCommand(element, command)
	return self:forwardCommandToPreListener(command)
end

--------------------------------------------------------------------------------
-- sendCommand
--! @brief Function to handle a gui command sent by the GUI system to the element.
--!        The command is first sent to the pre-listener, which can consume the command.
--! @param command command to handle
--! @return true if command is supported by the element
--------------------------------------------------------------------------------
function GUIElement:sendCommand(command)
	if self:forwardCommandToPreListener(command) then
		return true
	end

	return self:onCommand(command)
end

--------------------------------------------------------------------------------
-- onCommand
--! @brief Function to handle a gui command sent by the GUI system to the element
--! @param command command to handle
--! @return true if command is supported by the element
--------------------------------------------------------------------------------
function GUIElement:onCommand(command)
	if GUI.DEBUG_LEVEL.commands then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIElement:onCommand " .. tostring(command.id)) end
		
	if command.id == GUI_COMMAND_FOCUS then
		if GUI.DEBUG_LEVEL.actions then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIElement focused " .. tostring(self)) end
		if self.focusedVisual ~= nil then
			Component_enable(self.focusedVisual)
		end
		if self.listener ~= nil and self.listener.onElementFocus ~= nil then
			self.listener:onElementFocus(self)
		end
		
		if self.focusedAnimation ~= nil then
			if GUI.DEBUG_LEVEL.animations then GUI:debugPrint("GUIElement : play focused animation") end
			Component_enable(self.focusedAnimation)
			AnimatorComponent_setSpeed(self.focusedAnimation, 1.0)
			AnimatorComponent_play(self.focusedAnimation)
		end
		
		if self.focusedSound ~= nil then
			if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUIElement : play focused sound") end
			SoundComponent_stop(self.focusedSound)
			SoundComponent_play(self.focusedSound)
		end
		
	elseif command.id == GUI_COMMAND_UNFOCUS then
		if GUI.DEBUG_LEVEL.actions then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIElement unfocused " .. tostring(self)) end
		if self.focusedVisual ~= nil then
			Component_disable(self.focusedVisual)
		end
		if self.listener ~= nil and self.listener.onElementUnfocus ~= nil then
			self.listener:onElementUnfocus(self)
		end
		
		if self.focusedAnimation ~= nil then
			if GUI.DEBUG_LEVEL.animations then GUI:debugPrint("GUIElement : play unfocused animation") end
			AnimatorComponent_setSpeed(self.focusedAnimation, -1.0)
			AnimatorComponent_play(self.focusedAnimation)
		end
		
		if self.unfocusedSound ~= nil then
			if GUI.DEBUG_LEVEL.sounds then GUI:debugPrint("GUIElement : play unfocused sound") end
			SoundComponent_stop(self.unfocusedSound)
			SoundComponent_play(self.unfocusedSound)
		end
	end

	return false
end

--------------------------------------------------------------------------------
-- findParentElement
--! @brief Finds the parent gui element if the direct parent node has a gui element script.
--------------------------------------------------------------------------------
function GUIElement:findParentElement()
	local parent = WorldNode_getParentNode(self.worldNode)
	local hasScript = false
	local script
	
	while parent ~= nil and not hasScript do
		local components = WorldNode_getComponentsByTypeName(parent, "script")
		
		for i = 1, #components do
			script = ScriptComponent_getScriptTable(components[i])
				
			if script.isGUIElement then
				hasScript = true
				break
			end
		end
		
		if not hasScript then
			parent = WorldNode_getParentNode(parent)
		end
	end
	
	if hasScript then
		self.parent = script
	else
		self.parent = nil
	end
end

--------------------------------------------------------------------------------
-- getCurrentSize
--! @brief Returns the current size of the element according to the current visual
--! @return width, height
--------------------------------------------------------------------------------
function GUIElement:getCurrentSize()
	if self.currentVisual then
		return VisualComponent_getSize(self.currentVisual)
	end
	
	return 0, 0
end
