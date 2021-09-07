require 'scripts/core/core.lua'

--------------------------------------------------------------------------------
-- GUI Commands
--------------------------------------------------------------------------------
GUI_COMMAND_FOCUS = "COMMAND_FOCUS"
GUI_COMMAND_UNFOCUS = "COMMAND_UNFOCUS"
GUI_COMMAND_PRESS = "COMMAND_PRESS"
GUI_COMMAND_DRAG = "COMMAND_DRAG"
GUI_COMMAND_RELEASE = "COMMAND_RELEASE"
GUI_COMMAND_CLICK = "COMMAND_CLICK"
GUI_COMMAND_LEFT = "COMMAND_LEFT"
GUI_COMMAND_RIGHT = "COMMAND_RIGHT"
GUI_COMMAND_UP = "COMMAND_UP"
GUI_COMMAND_DOWN = "COMMAND_DOWN"


--------------------------------------------------------------------------------
--! @class GUI
--!
--! Attributes 
--! @variable {Component} inputCamera The camera used for input detection
--!
--------------------------------------------------------------------------------
GUI = class()
GUI.pressedCommandTarget = nil
GUI.focusedElement = nil
GUI.clickMode = "release" --< "release" or "push"
GUI.buttonMode = "push"   --< "release" or "push"
GUI.dragThresholdX = 4
GUI.dragThresholdY = 4
GUI.hasAutomaticNavigation = false
--! Flag to round scrolled elements position to integer units
GUI.roundedUnits = false

-- Neighbour finding
GUI_NEIGHBOUR_SELECTIVITY = 0.5

-- debug verbosity : set a category to true for more verbose
GUI.DEBUG_LEVEL =
{
	runtime = false,
	hit_test_ll = false,
	hit_test = false,
	inputs = false,
	input_repeat = false,
	dragging = false,
	commands = false,
	actions = false,
	states = false,
	callbacks = false,
	animations = false,
	info = false,
	scroll_layout = false,
	neighbors = false,
	focus = false,
	sounds = false
}

local pairs = pairs
local g_tempCommand = {}

local function makeCommand(id)
	for k in pairs(g_tempCommand) do g_tempCommand[k] = nil end
	g_tempCommand.id = id
	return g_tempCommand
end

local function makeCommandPress(posX, posY, overstep)
	local cmd = makeCommand(GUI_COMMAND_PRESS)
	cmd.posX = posX
	cmd.posY = posY
	cmd.overstep = overstep
	return cmd
end

local function makeCommandRelease(posX, posY, endDrag, overstep)
	local cmd = makeCommand(GUI_COMMAND_RELEASE)
	cmd.posX = posX
	cmd.posY = posY
	cmd.endDrag = endDrag
	cmd.overstep = overstep
	return cmd
end

local function makeCommandClick(posX, posY)
	local cmd = makeCommand(GUI_COMMAND_CLICK)
	cmd.posX = posX
	cmd.posY = posY
	return cmd
end

local function makeCommandDrag(previousPosX, previousPosY, posX, posY, first)
	local cmd = makeCommand(GUI_COMMAND_DRAG)
	cmd.previousPosX = previousPosX
	cmd.previousPosY = previousPosY
	cmd.posX = posX
	cmd.posY = posY
	cmd.first = first
	return cmd
end

--! @brief Callback when object is added to the world
function GUI:start()
	
	if GUI.manager ~= nil then
		GUI:error("Trying to start GUI manager, but one already exists ('" .. WorldNode_getName(GUI.manager.worldNode) .. "')")
	end
	
	GUI.manager = self
	
	GUI:reset()
	GUI:setInputCamera(self.inputCamera)
end

--! @brief Callback when object is removed from the world
function GUI:stop()
	GUI.manager = nil
end

--! @brief Callback called every frame
function GUI:update(dt)
	GUI:updateInputs(dt)
end

function GUI:reset()
	self.pressedCommandTarget = nil
	self.focusedElement = nil
	self.buttonTable = nil
end

--------------------------------------------------------------------------------
-- debugPrint
--! @brief Prints a text for debugging purposes
--! @param text text to print
--! @param level debug level of the message
--------------------------------------------------------------------------------
function GUI:debugPrint(text, level)
	if not level or GUI.DEBUG_LEVEL[level] == true then
		print("<GUI> " .. text)
	end
end

--------------------------------------------------------------------------------
-- warning
--! @brief Prints a warning text
--! @param text text to print
--------------------------------------------------------------------------------
function GUI:warning(text)
	print("<GUI> <WARNING> " .. text)
end

--------------------------------------------------------------------------------
-- error
--! @brief Prints a error text and throws a lua error
--! @param text text to print
--------------------------------------------------------------------------------
function GUI:error(text)
	error("<GUI> <ERROR> " .. text)
end

--------------------------------------------------------------------------------
-- getGUIElementsOnNode
--! @brief Returns the list of GUIElements attached to the specified world node
--! @param node World node on which to get GUIElements
--! @return An array of GUIElement tables attached to the specified world node
--------------------------------------------------------------------------------
function GUI:getGUIElementsOnNode(node)
	local scripts = WorldNode_getScriptComponents(node)

	local guiElements = {}
	
	for i = 1, #scripts do
	    if scripts[i].isGUIElement then
	    	guiElements[#guiElements + 1] = scripts[i]
	    end
	end
	
	return guiElements
end

--------------------------------------------------------------------------------
-- registerButton
--! @brief Adds a button to the list of candidates
--! @param button Button to register
--------------------------------------------------------------------------------
function GUI:registerButton(button)
	if self.buttonTable == nil then
		self.buttonTable = {}
	end
	self.buttonTable[button] = true
end

--------------------------------------------------------------------------------
-- unregisterButton
--! @brief Removes a button from the list of candidates
--! @param button Button to unregister
--------------------------------------------------------------------------------
function GUI:unregisterButton(button)
	if self.buttonTable then
		self.buttonTable[button] = nil
	end
end

--------------------------------------------------------------------------------
-- getButtonCenter
--! @brief Get the center of a button in screen space
--! @param button Button to compute
--! @return screenspace position X, screenspace position Y
--------------------------------------------------------------------------------
function GUI:getButtonCenter(button)
	local x, y = WorldNode_getWorldPosition(button.worldNode)
	local lX, lY = ClickableComponent_getCenter(button.clickable)
	x = x + lX;
	y = y + lY;
	x, y = CameraComponent_worldToScreenPosition(self.camera, x, y)
	return x, y
end

--------------------------------------------------------------------------------
-- getButtonCorners
--! @brief Get a list of all corners in a button, in screen-space
--! @param button Button to use
--! @param outputList Table of {button, screenspace x, screenspace y)
--------------------------------------------------------------------------------
function GUI:getButtonCorners(button, outputList)
	
	local x, y = WorldNode_getWorldPosition(button.worldNode)
	local lX, lY = ClickableComponent_getCenter(button.clickable)
	local w, h = ClickableComponent_getBoxShapeSize(button.clickable)
	x = x + lX;
	y = y + lY;
	
	local tx, ty = CameraComponent_worldToScreenPosition(self.camera, x + w / 2, y + h / 2)
	table.insert(outputList, {tx, ty})
	tx, ty =  CameraComponent_worldToScreenPosition(self.camera, x + w / 2, y - h / 2)
	table.insert(outputList, {tx, ty})
	tx, ty =  CameraComponent_worldToScreenPosition(self.camera, x - w / 2, y - h / 2)
	table.insert(outputList, {tx, ty})
	tx, ty =  CameraComponent_worldToScreenPosition(self.camera, x - w / 2, y + h / 2)
	table.insert(outputList, {tx, ty})
end

--------------------------------------------------------------------------------
-- getButtonNearestCorner
--! @brief  Get the nearest corner from a reference
--! @param cornerList List of corners defining a button
--! @param xRef screenspace X of reference
--! @param yRef screenspace Y of reference
--! @return screenspace xmin, screenspace ymin
--------------------------------------------------------------------------------
function GUI:getButtonNearestCorner(cornerList, xRef, yRef)
	
	local xBestDistance = math.huge
	local yBestDistance = math.huge
	local xMin = 0
	local yMin = 0
	
	for i = 1, #cornerList do
		local xDistance = math.abs(cornerList[i][1] - xRef)
		local yDistance = math.abs(cornerList[i][2] - yRef)
		
		if xDistance < xBestDistance then
			xBestDistance = xDistance
			xMin = cornerList[i][1]
		end
		if yDistance < yBestDistance then
			yBestDistance = yDistance
			yMin = cornerList[i][2]
		end
	end
	
	return xMin, yMin
end

--------------------------------------------------------------------------------
-- getMinMax
--! @brief  Get a table of the min and max coordinates
--! @param cornerList List of corners defining a button
--! @return screenspace xmin, screenspace ymin, screenspace xmax, screenspace ymax
--------------------------------------------------------------------------------
function GUI:getMinMax(cornerList)
	
	local xMin = math.huge
	local yMin = math.huge
	local xMax = -math.huge
	local yMax = -math.huge
	
	for i = 1, #cornerList do
		local xDistance = cornerList[i][1]
		local yDistance = cornerList[i][2]
		
		if xDistance < xMin then
			xMin = xDistance
		end
		if xDistance > xMax then
			xMax = xDistance
		end
		if yDistance < yMin then
			yMin = yDistance
		end
		if yDistance > yMax then
			yMax = yDistance
		end
	end

	return {xMin, xMax, yMin, yMax}
end

--------------------------------------------------------------------------------
-- isInPartition
--! @brief  Check if a button is in a partition
--! @param cornerList List of corners defining the candidate button
--! @param sourceCornerList List of corners defining the partitionnibng button
--! @param side Direction to check
--! @return true if in partition else false
--------------------------------------------------------------------------------
function GUI:isInPartition(cornerList, sourceCornerList, side)
	
	local candidateAABB = self:getMinMax(cornerList)
	local sourceAABB = self:getMinMax(sourceCornerList)
	
	if     side == "GUI_DIRECTION_LEFT" and candidateAABB[2] < sourceAABB[1] then
		return true
	elseif side == "GUI_DIRECTION_RIGHT" and candidateAABB[1] > sourceAABB[2]  then
		return true
	elseif side == "GUI_DIRECTION_DOWN" and candidateAABB[4] < sourceAABB[3]  then
		return true
	elseif side == "GUI_DIRECTION_UP" and candidateAABB[3] > sourceAABB[4]  then
		return true
	else
		return false
	end
end

--------------------------------------------------------------------------------
-- findAutoNeighbour
--! @brief Finds the best match for a neighbor according to a given direction
--! @param buttonTable Table of all buttons
--! @param button Current focus
--! @param side Direction to check
--! @return the new button, or nil
--------------------------------------------------------------------------------
function GUI:findAutoNeighbour(buttonTable, button, side)

	if not GUI.hasAutomaticNavigation then
		return nil
	end
	
	local bestButton = nil
	local bestScore = math.huge
	local sourceCornerList = {}
	self:getButtonCorners(button, sourceCornerList)
	local buttonX, buttonY = self:getButtonCenter(button)
	
	-- Evaluate all candidate buttons
	for tempButton in pairs(buttonTable) do
		
		-- Partition test
		local cornerList = {}
		
		if Component_isEnabled(tempButton._ptr) == true and tempButton:isAutoFocusDisabled() == false then
			self:getButtonCorners(tempButton, cornerList)
			if self:isInPartition(cornerList, sourceCornerList, side) then
				
				-- Nearest corner test
				local minX, minY = self:getButtonNearestCorner(cornerList, buttonX, buttonY)
				
				-- Distance from corner
				local score = 0
				local distX = math.abs(buttonX - minX)
				local distY = math.abs(buttonY - minY)
				
				-- Compute score
				if side == "GUI_DIRECTION_LEFT" or side == "GUI_DIRECTION_RIGHT" then
					score = GUI_NEIGHBOUR_SELECTIVITY * distX + distY
				else
					score = GUI_NEIGHBOUR_SELECTIVITY * distY + distX
				end
				
			 	-- Nearest button
				if score < bestScore then
					bestScore = score
					bestButton = tempButton
				end
	 		end
	 	end
	end

	-- Result
	if bestButton == nil then
		if GUI.DEBUG_LEVEL.neighbors then GUI:debugPrint('No neighbour found') end
	else
		if GUI.DEBUG_LEVEL.neighbors then GUI:debugPrint('Neighbour button is ' .. tostring(button) .. ' in ' .. WorldNode_getName(bestButton.worldNode)) end
	end
	return bestButton
end

--------------------------------------------------------------------------------
--! getNeighborElement
--! @brief Returns the neighbor for a given element.
--! @param element to retrieve the neighbor from
--! @param direction direction to search the neighbor for
--! @return returns the neighbor that has been defined by the user. If not defined and if automatic navigation is activated, it returns the best match.
--------------------------------------------------------------------------------
function GUI:getNeighborElement(element, direction)
	
	local nextElement
	if direction == "GUI_DIRECTION_LEFT" then
		nextElement = element.leftElement
	elseif direction == "GUI_DIRECTION_RIGHT" then
		nextElement = element.rightElement
	elseif direction == "GUI_DIRECTION_DOWN" then
		nextElement = element.downElement
	elseif direction == "GUI_DIRECTION_UP" then
		nextElement = element.upElement
	end
	
	while nextElement and nextElement ~= element and (nextElement.currentState == "disabled" or not Component_isEnabled(nextElement._ptr)) do
		if direction == "GUI_DIRECTION_LEFT" then
			nextElement = nextElement.leftElement
		elseif direction == "GUI_DIRECTION_RIGHT" then
			nextElement = nextElement.rightElement
		elseif direction == "GUI_DIRECTION_DOWN" then
			nextElement = nextElement.downElement
		elseif direction == "GUI_DIRECTION_UP" then
			nextElement = nextElement.upElement
		end
	end
	
	if nextElement and nextElement.currentState ~= "disabled" and Component_isEnabled(nextElement._ptr) then
		return nextElement
	end
	
	if GUI.hasAutomaticNavigation then
		return self:findAutoNeighbour(self.buttonTable, element, direction)
	end
end

--------------------------------------------------------------------------------
-- setInputCamera
--! @brief Sets the camera that is used for input detection
--! @param camera camera component reference
--------------------------------------------------------------------------------
function GUI:setInputCamera(camera)
	self.camera = camera
	local inputScreen = CameraComponent_getTargetScreen(camera)
	self.screenWidth, self.screenHeight = getScreenSize(inputScreen)
end

--------------------------------------------------------------------------------
-- inputToElementLocalPosition
--! @brief Converts a screen position to the element local coordinate system
--! @param element gui element
--! @param posX Screen position X
--! @param posY Screen position Y
--! @return local position X, local position Y
--------------------------------------------------------------------------------
function GUI:inputToElementLocalPosition(element, posX, posY)
	local screenPosX = posX
	local screenPosY = self.screenHeight - posY

	if GUI.DEBUG_LEVEL.hit_test_ll then GUI:debugPrint("screen pos = " .. tostring(screenPosX) .. ", " .. tostring(screenPosY)) end
	
	local worldPosX, worldPosY = CameraComponent_screenToWorldPosition(self.camera, screenPosX, screenPosY)
	
	return WorldNode_worldToLocalPosition(element.worldNode, worldPosX, worldPosY)
end

--------------------------------------------------------------------------------
-- getClickableAt
--! @brief Returns the clickable under a provided screen position
--! @param posX Screen position X
--! @param posY Screen position Y
--! @return clickable component [, local hit position X, local hit position Y]
--------------------------------------------------------------------------------
function GUI:getClickableAt(posX, posY)
	
	if GUI.DEBUG_LEVEL.hit_test_ll then GUI:debugPrint("touch pos = " .. tostring(posX) .. ", " .. tostring(posY)) end

	local screenPosX = posX
	local screenPosY = self.screenHeight - posY

	if GUI.DEBUG_LEVEL.hit_test_ll then GUI:debugPrint("screen pos = " .. tostring(screenPosX) .. ", " .. tostring(screenPosY)) end
	
	local worldPosX, worldPosY = CameraComponent_screenToWorldPosition(self.camera, screenPosX, screenPosY)
	
	if GUI.DEBUG_LEVEL.hit_test_ll then GUI:debugPrint("world pos = " .. tostring(worldPosX) .. ", " .. tostring(worldPosY)) end
	
	local hitClickable = ClickableComponentManager_raycastNearest(worldPosX, worldPosY)
	
	-- local localPosX = 0
	-- local localPosY = 0
	
	-- if hitClickable ~= nil then
	-- 	localPosX, localPosY = WorldNode_worldToLocalPosition(Component_getNode(hitClickable), worldPosX, worldPosY)
	-- end
	
	return hitClickable, worldPosX, worldPosY
end

--------------------------------------------------------------------------------
-- getElementAt
--! @brief Returns a gui element under a provided screen position
--! @param posX Screen position X
--! @param posY Screen position Y
--! @return gui element [, local hit position X, local hit position Y]
--------------------------------------------------------------------------------
function GUI:getElementAt(posX, posY)
	
	local clickable, worldPosX, worldPosY = self:getClickableAt(posX, posY)
	
	if clickable ~= nil then

		if GUI.DEBUG_LEVEL.hit_test then GUI:debugPrint("hit clickable " .. tostring(clickable)) end
			
		local scriptComp = ClickableComponent_getClickListener(clickable)
		
		if scriptComp ~= nil then
			local element = ScriptComponent_getScriptTable(scriptComp)
			
			if element.isGUIElement then -- Check it is a valid gui element
				return element, worldPosX, worldPosY
			end
		end
		
	end
	
	return nil, worldPosX, worldPosY
end

--------------------------------------------------------------------------------
-- sendCommand
--! @brief Sends a GUI command to a gui element and returns whether this command was handled or not.
--! @param element gui element to send the command to
--! @param command command to send
--! @return true if the command was handled, else false
--------------------------------------------------------------------------------
function GUI:sendCommand(element, command)
	
	if element.currentState ~= "disabled" then
		return element:sendCommand(command)
	end
	
end

--------------------------------------------------------------------------------
-- sendBubbleCommand
--! @brief Sends a GUI command to a gui element and fallback onto parents when command is not handled.
--! @param element gui element to send the command to
--! @param command command to send
--! @return element which handled this command. nil if the command has not been handled by any element in the ancestors hierarchy
--------------------------------------------------------------------------------
function GUI:sendBubbleCommand(element, command)
	
	if element.currentState ~= "disabled" then
		while element ~= nil and not element:sendCommand(command) do
			element = element.parent
		end
		
		if element then
			return element
		end
	end

	return nil	
end

--------------------------------------------------------------------------------
-- pressElement
--! @brief Simulates a press action on the given element
--------------------------------------------------------------------------------
function GUI:pressElement(element)
	self:sendCommand(element, makeCommand(GUI_COMMAND_PRESS))
	if self.buttonMode == "push" then
		self:sendCommand(element, makeCommand(GUI_COMMAND_CLICK))
	end
end

--------------------------------------------------------------------------------
-- releaseElement
--! @brief Simulates a release action on the given element
--------------------------------------------------------------------------------
function GUI:releaseElement(element)
	if self.buttonMode == "release" then
		self:sendCommand(element, makeCommand(GUI_COMMAND_CLICK))
	end
	self:sendCommand(element, makeCommand(GUI_COMMAND_RELEASE))
end

--------------------------------------------------------------------------------
-- clickElement
--! @brief Simulates a press/release action on the given element
--------------------------------------------------------------------------------
function GUI:clickElement(element)
	self:sendCommand(element, makeCommand(GUI_COMMAND_CLICK))
end

--------------------------------------------------------------------------------
-- updateInputs
--! @brief Performs processing of the user inputs and send the commands accordingly to the corresponding elements
--! @param dt delta Time since last update
--------------------------------------------------------------------------------
function GUI:updateInputs(dt)
	
	if self.disabled then
		return
	end
	
	self.dt = dt
	self.currentTime = self.currentTime + dt
	self.repeatedThisFrame = false
	
	local focusedElement = self.focusedElement
	
	local isTouched = GUI:isTouched()
	local wasTouched = GUI:wasTouched()
	
	local isTouchPressed = isTouched and not wasTouched
	local isTouchReleased = not isTouched and wasTouched
	
	-- Handle key buttons events
	if focusedElement ~= nil then
		if GUI:isLeftPressed() then
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("Key left pressed") end
			if not self:sendCommand(focusedElement, makeCommand(GUI_COMMAND_LEFT)) then
				local neighbour = self:getNeighborElement(focusedElement, "GUI_DIRECTION_LEFT")
				if neighbour ~= nil then
					self:focusElement(neighbour)
				end
			end
		elseif GUI:isRightPressed() then
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("Key right pressed") end
			if not self:sendCommand(focusedElement, makeCommand(GUI_COMMAND_RIGHT)) then
				local neighbour = self:getNeighborElement(focusedElement, "GUI_DIRECTION_RIGHT")
				if neighbour ~= nil then
					self:focusElement(neighbour)
				end
			end
		elseif GUI:isUpPressed() then
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("Key up pressed") end
			if not self:sendCommand(focusedElement, makeCommand(GUI_COMMAND_UP)) then
				local neighbour = self:getNeighborElement(focusedElement, "GUI_DIRECTION_UP")
				if neighbour ~= nil then
					self:focusElement(neighbour)
				end
			end
		elseif GUI:isDownPressed() then
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("Key down pressed") end
			if not self:sendCommand(focusedElement, makeCommand(GUI_COMMAND_DOWN)) then
				local neighbour = self:getNeighborElement(focusedElement, "GUI_DIRECTION_DOWN")
				if neighbour ~= nil then
					self:focusElement(neighbour)
				end
			end
		elseif GUI:isValidatePressed() then
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("Key validate pressed") end
			if focusedElement ~= nil then
				self.validatedTarget = focusedElement
				self:sendCommand(focusedElement, makeCommand(GUI_COMMAND_PRESS))
				if self.buttonMode == "push" then
					self:sendCommand(focusedElement, makeCommand(GUI_COMMAND_CLICK))
				end
			end
		elseif GUI:isValidateDown() then
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("Key validate down") end
			-- self:sendCommand(focusedElement, makeCommand(GUI_COMMAND_PRESS))
		elseif GUI:isValidateReleased() then
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("Key validate released") end
			if self.validatedTarget ~= nil then
				if self.buttonMode == "release" then
					self:sendCommand(self.validatedTarget, makeCommand(GUI_COMMAND_CLICK))
				end
				self:sendCommand(self.validatedTarget, makeCommand(GUI_COMMAND_RELEASE))
				self.validatedTarget = nil
			end
		end
	end
	
	-- Handle touch/pointer events
	if isTouchPressed or isTouchReleased then

		local touchPosX = 0
		local touchPosY = 0

		if isTouchPressed then
			touchPosX = Input_getState(TOUCH_DEVICE, TOUCH_X)
			touchPosY = Input_getState(TOUCH_DEVICE, TOUCH_Y)
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("Touch pressed " .. touchPosX .. ", " .. touchPosY) end
			
			-- Unfocus
			self:focusElement(nil)
			
		elseif isTouchReleased then
			touchPosX = Input_getPreviousState(TOUCH_DEVICE, TOUCH_X)
			touchPosY = Input_getPreviousState(TOUCH_DEVICE, TOUCH_Y)
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("Touch released " .. touchPosX .. ", " .. touchPosY) end
		end
		
		local element, worldPosX, worldPosY = self:getElementAt(touchPosX, touchPosY)
			
		if element ~= nil then
				
			if GUI.DEBUG_LEVEL.hit_test then GUI:debugPrint("element found " .. tostring(element)) end
			
			if isTouchPressed then
				self.pressedCommandTarget = element
				self.lastTouchedTarget = element
				self:sendCommand(element, makeCommandPress(worldPosX, worldPosY))

				if self.clickMode == "push" then
					self:sendCommand(element, makeCommandClick(worldPosX, worldPosY))
				end
				
				self.startDragPosX = worldPosX
				self.startDragPosY = worldPosY
				self.isDragging = false
			elseif isTouchReleased then
				if self.isDragging then -- Send release on dragged element
					self.pressedCommandTarget = nil
					self:sendCommand(self.dragCommandTarget, makeCommandRelease(worldPosX, worldPosY, true))
				elseif element == self.pressedCommandTarget then
					self.pressedCommandTarget = nil
					
					if self.clickMode == "release" then
						self:sendCommand(element, makeCommandClick(worldPosX, worldPosY))
					end

					self:sendCommand(element, makeCommandRelease(worldPosX, worldPosY))
				end
			end
		else
			if GUI.DEBUG_LEVEL.hit_test then GUI:debugPrint("non gui component") end
			
			if isTouchReleased then
				if self.isDragging then -- Send release on dragged element
					self.pressedCommandTarget = nil
					self:sendCommand(self.dragCommandTarget, makeCommandRelease(worldPosX, worldPosY, true))
				end
			end
		end
			
	elseif isTouched then -- drag
		if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("Touch down") end
		
		local touchPosX = Input_getState(TOUCH_DEVICE, TOUCH_X)
		local touchPosY = Input_getState(TOUCH_DEVICE, TOUCH_Y)

		local element, worldPosX, worldPosY = GUI:getElementAt(touchPosX, touchPosY)
		
		if element then
			 if GUI.DEBUG_LEVEL.hit_test then GUI:debugPrint("element touched " .. tostring(element) .. " pressedTarget " .. tostring(self.pressedCommandTarget)) end
		end
		
		if self.pressedCommandTarget ~= nil or self.dragCommandTarget ~= nil then

			if not self.isDragging then
				-- Handle entering and leaving target click area
				if element ~= self.pressedCommandTarget then
					if self.lastTouchedTarget == self.pressedCommandTarget then -- Ensure RELEASE command is sent only once after leaving the pressedCommandTarget
						self:sendCommand(self.pressedCommandTarget, makeCommandRelease(nil, nil, nil, true))
					end
				else
					if self.lastTouchedTarget ~= self.pressedCommandTarget then -- Ensure PRESS command is sent only once after entering the pressedCommandTarget
						self:sendCommand(self.pressedCommandTarget, makeCommandPress(worldPosX, worldPosY, true))
					end
				end
			
				if not self.dragHasFailed then
				
					-- Test if threshold has been reached for dragging
					if math.abs(self.startDragPosX - worldPosX) > GUI.dragThresholdX or
					   math.abs(self.startDragPosY - worldPosY) > GUI.dragThresholdY then
					   	
					   	if element then
					   		self.dragCommandTarget = self:sendBubbleCommand(element, makeCommandDrag(self.startDragPosX, self.startDragPosY, worldPosX, worldPosY, true))
					   	end
					   		
					   	-- If drag command has a response
					   	if self.dragCommandTarget ~= nil then
					   		if GUI.DEBUG_LEVEL.dragging then GUI:debugPrint("Start dragging target " .. tostring(self.dragCommandTarget)) end
							self.isDragging = true
							self.startDragPosX = worldPosX
							self.startDragPosY = worldPosY
							
							if self.lastTouchedTarget == self.pressedCommandTarget then -- Release pressed target if not already released
								self:sendCommand(self.pressedCommandTarget, makeCommand(GUI_COMMAND_RELEASE))
							end
							
							self.pressedCommandTarget = nil
						elseif element ~= self.pressedCommandTarget then
							self.dragHasFailed = true
						end
					end
				end
			else -- Handle dragging
				self:sendCommand(self.dragCommandTarget, makeCommandDrag(self.startDragPosX, self.startDragPosY, worldPosX, worldPosY))
				self.startDragPosX = worldPosX
				self.startDragPosY = worldPosY
			end

		end
	
		self.lastTouchedTarget = element

	else
		self.pressedCommandTarget = nil
		self.dragCommandTarget = nil
		self.isDragging = false
		self.dragHasFailed = false
	end
end

--------------------------------------------------------------------------------
-- focusElement
--! @brief Focus a gui element. Focused element will first receive validation commands. (ie. A button on a common Pad device)
--! @note Can't focus a disabled element (ie. that is in the disabled state). Nothing is performed if a gui element is in pressed state (or is the pressed target).
--! @param element Element to focus. Can be nil to force unfocus.
--------------------------------------------------------------------------------
function GUI:focusElement(element)
	if GUI.DEBUG_LEVEL.focus then GUI:debugPrint("Focus element " .. tostring(element)) end
	local focusedElement = self.focusedElement
	if focusedElement ~= element and self.pressedCommandTarget == nil  then

		if focusedElement ~= nil then
			self:sendCommand(focusedElement, makeCommand(GUI_COMMAND_UNFOCUS))
		end
		
		if element ~= nil and element.currentState ~= "disabled" then
			focusedElement = element
		else
			focusedElement = element
		end
		self.focusedElement = focusedElement
		
		if focusedElement ~= nil then
			self:sendCommand(focusedElement, makeCommand(GUI_COMMAND_FOCUS))
		end
	end
end

--------------------------------------------------------------------------------
-- enforceListenerToSelf
--! @brief Makes sure that the provided element listener is referencing a given listener. It warns the user if it was referencing another object
--! @param element element to enforce the listener attribute
--! @param listener listener object that must referenced
--! @param element_type name of the element
--! @param sub_element_type name of element to enforce
--------------------------------------------------------------------------------
function GUI:enforceListener(element, listener, element_type, sub_element_type)
	if element.listener ~= nil and element.listener ~= listener then
		GUI:warning("Warning! the listener of the " .. tostring(sub_element_type) .. " associated to a " .. tostring(element_type) .. " script does not reference the " .. tostring(element_type) .. ". Value will be overriden.")
	end
	
	element.listener = listener
end