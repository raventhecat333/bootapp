require 'gui.lua'

local MathAbs = math.abs
local MathRound = Math.round
local MathClamp = Math.clamp
local MathLerp = Math.lerp
local MathMin = math.min
local MathMax = math.max
local MathHuge = math.huge

--------------------------------------------------------------------------------
-- GUIScroll Object script
--! @class GUIScroll
--! @parent GUIElement
--! 
--! States
--! * idle
--! * disabled
--!
--! Attributes
--! @variable {String}    [direction] either "horizontal" or "vertical" or "both". Default : "horizontal"
--! @variable {WorldNode} [elements] world node that will contain all the list elements. If not defined, it will be automatically created
--! @variable {String}    [layout] determines the elements arrangement within the list. Supported values : "horizontal_list", "vertical_list", "grid". Default value is according to direction
--! @variable {Boolean}   [hasInertia] determines if the scroll should have inertia when drag is released
--! @variable {Number}    [friction] friction value for inertia computation
--! @variable {Number}    [dragTreshold] minimum drag value before actually drag the content. Default 5 world units
--! @variable {Number}    [dragFactorX] factor to be applied on drag for X axis
--! @variable {Number}    [dragFactorY] factor to be applied on drag for Y axis
--! @variable {Number}    [columnsCount] Default : 2 if layout == "grid"
--! @variable {Number}    [rowsCount] Default : 2 if layout == "grid"
--! @variable {Boolean}   [hasInnerScroll] Scroll if content is smaller than the scroll area. Default : false
--!
--! Events
--! * onElementFocus(element)
--! * onElementUnfocus(element)
--! * onScroll(scroller, valueX, valueY)
--!
--------------------------------------------------------------------------------

GUIScroll = class(GUIElement)

--------------------------------------------------------------------------------
-- start
--! @brief Callback when the object is added to the world
--------------------------------------------------------------------------------
function GUIScroll:start()

	if GUI.DEBUG_LEVEL.runtime then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:start()") end

	GUIElement.start(self)
	
	self.scrollXValue = 0
	self.scrollYValue = 0
	
	self.speedX = 0
	self.speedY = 0
	
	self.startX = 0
	self.startY = 0
	
	self.width = 0
	self.height = 0
	
	self.elementsCount = 0
	
	self.isDragging = false
	self.isDragEngaged = false
	
	self.computeInertia = false
	
	if not self.dragTreshold then
		self.dragTreshold = 5
	end
	
	if not self.direction then
		self.direction = "horizontal"
	end
	
	if not self.layout then
		if self.direction == "horizontal" then
			self.layout = "horizontal_list"
		elseif self.direction == "vertical" then
			self.layout = "vertical_list"
		end
	end

	if self.layout == "horizontal_list" then
		self.rowsCount = 1
		self.columnsCount = MathHuge
		self.layoutObj = new(GUIHLayout)
	elseif self.layout == "vertical_list" then
		self.rowsCount = MathHuge
		self.columnsCount = 1
		self.layoutObj = new(GUIVLayout)
	elseif self.layout == "grid" then
		if self.rowsCount == nil then
			self.rowsCount = 2
		end
		
		if self.columnsCount == nil then
			self.columnsCount = 2
		end
	end

	self.layoutObj:initialize()

	if not self.hasInnerScroll then
		self.hasInnerScroll = false
	end

	if not self.elements then
		self.elements = WorldNode_getChildByName(self.worldNode, "elements")
		if not self.elements then
			self.elements = createWorldNode("elements")
			WorldNode_addChildNode(self.worldNode, self.elements)
		end
	end
	
	self:setupClickableArea()
	
	local clickWidth, clickHeight = ClickableComponent_getBoxShapeSize(self.clickable)
	
	if not self.maxWidth then
		self.maxWidth = clickWidth
	end
	if not self.maxHeight then
		self.maxHeight = clickHeight
	end
	
	if self.dragFactorX == nil then self.dragFactorX = 1 end
	if self.dragFactorY == nil then self.dragFactorY = 1 end

	if self.friction == nil then self.friction = 5 end

end

--------------------------------------------------------------------------------
-- update
--! @brief Callback when the object is updated
--------------------------------------------------------------------------------
function GUIScroll:update(dt)
	self.dt  = dt
	
	if self.hasInertia and self.computeInertia then -- apply inertia
		local speedX = self.speedX
		local speedY = self.speedY
		local friction = self.friction
		
		self:scrollBy(speedX * dt, speedY * dt)
		speedX = MathLerp(speedX, 0, dt * friction)
		speedY = MathLerp(speedY, 0, dt * friction)
		
		if MathAbs(speedX) < 1 and MathAbs(speedY) < 1 then
			self.computeInertia = false
		end
		
		self.speedX = speedX
		self.speedY = speedY
	end

--	GUIElement.update(self, dt)
end

--------------------------------------------------------------------------------
-- stopScroll
--! @brief Stops the current scroll motion, if any
--------------------------------------------------------------------------------
function GUIScroll:stopScroll()
	self.computeInertia = false
	self.speedX = 0
	self.speedY = 0
end

--------------------------------------------------------------------------------
-- onElementCommand
--! @brief Function to receive the commands of this scroll's elements
--! @param element the element which is receiving the command
--! @param command the received command
--! @return true if command was handled, false otherwise
--------------------------------------------------------------------------------
function GUIScroll:onElementCommand(element, command)

	if self:forwardCommandToPreListener(command) then
		return true
	end

	if command.id == GUI_COMMAND_PRESS then
		self:stopScroll()
		return false
	end

	return false
end

--------------------------------------------------------------------------------
-- onCommand
--! @brief Function to handle a gui command sent by the GUI system to the element
--! @param command command to handle
--------------------------------------------------------------------------------
function GUIScroll:onCommand(command)
	if GUI.DEBUG_LEVEL.commands then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:onCommand() " .. tostring(command.id)) end
	
	if command.id == GUI_COMMAND_PRESS then
		self:stopScroll()
		return true
	elseif command.id == GUI_COMMAND_DRAG then
		
		local localPosX, localPosY = WorldNode_worldToLocalPosition(self.worldNode, command.posX, command.posY)
		local localPrevPosX, localPrevPosY = WorldNode_worldToLocalPosition(self.worldNode, command.previousPosX, command.previousPosY)
		
		if command.first then
			self.isDragEngaged = false
		end
		
		if not self.isDragging then
			
			if not self.isDragEngaged then
			
				self.isDragEngaged = true
				if GUI.DEBUG_LEVEL.dragging then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll drag engaged") end
				
				local isHorizontalDrag = MathAbs(localPosX - localPrevPosX) > MathAbs(localPosY - localPrevPosY)
				
				if self.direction == "horizontal" and not isHorizontalDrag or
				   self.direction == "vertical" and isHorizontalDrag then
				   	if GUI.DEBUG_LEVEL.dragging then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll wrong direction ") end
				   	return false
				end
				
				local clickWidth, clickHeight = ClickableComponent_getBoxShapeSize(self.clickable)
				-- if isHorizontalDrag and (not self.hasInnerScroll and (self.xMax - self.xMin) < clickWidth) then
				if isHorizontalDrag and (not self.hasInnerScroll and self.layoutObj:getWidth() < clickWidth) then
					return false
				end
				
				-- if not isHorizontalDrag and (not self.hasInnerScroll and (self.yMax - self.yMin) < clickHeight) then
				if not isHorizontalDrag and (not self.hasInnerScroll and self.layoutObj:getHeight() < clickHeight) then
					return false
				end
				
				self.startX = localPrevPosX
				self.startY = localPrevPosY
					
				self:stopScroll()
				
				self.isDragging = true
				
			else
				if GUI.DEBUG_LEVEL.dragging then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll drag already engaged") end
				return false
			end
			
		else
		
			local dx = localPosX - localPrevPosX
			local dy = localPosY - localPrevPosY
	
			self.speedX = dx / self.dt
			self.speedY = dy / self.dt
			
			self.startX = localPosX
			self.startY = localPosY
			
			self:scrollBy(dx, dy)
			
			if GUI.DEBUG_LEVEL.dragging then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll dragging ") end
		end

		return true
	elseif command.id == GUI_COMMAND_RELEASE then
		if GUI.DEBUG_LEVEL.actions then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll released ") end
		
		self.computeInertia = true
		self.isDragging = false
		self.isDragEngaged = false
		
		return true
	end
	
	return GUIElement.onCommand(self, command)
end

--------------------------------------------------------------------------------
-- getBoundaries
--! @brief Gets the scroll area boundaries
--! @return minX, maxX, minY, maxY
--------------------------------------------------------------------------------
function GUIScroll:getBoundaries()
	local clickableCenterX, clickableCenterY = ClickableComponent_getCenter(self.clickable)
	local clickableWidth, clickableHeight = ClickableComponent_getBoxShapeSize(self.clickable)
	
	local borderXMin = -clickableWidth / 2 + clickableCenterX - self.layoutObj.xMin
	local borderXMax = clickableWidth / 2 + clickableCenterX - self.layoutObj.xMax
	local borderYMin = -clickableHeight / 2 + clickableCenterY - self.layoutObj.yMin
	local borderYMax = clickableHeight / 2 + clickableCenterY - self.layoutObj.yMax
	local clampXMin = MathMin(borderXMin, borderXMax)
	local clampXMax = MathMax(borderXMin, borderXMax)
	local clampYMin = MathMin(borderYMin, borderYMax)
	local clampYMax = MathMax(borderYMin, borderYMax)

	return clampXMin, clampXMax, clampYMin, clampYMax
end

--------------------------------------------------------------------------------
--! @brief Returns the scroll value on horizontal axis
--! @return Normalized scroll value
--------------------------------------------------------------------------------
function GUIScroll:getScrollX()
	return self.scrollXValue
end

--------------------------------------------------------------------------------
--! @brief Returns the scroll value on vertical axis
--! @return Normalized scroll value
--------------------------------------------------------------------------------
function GUIScroll:getScrollY()
	return self.scrollYValue
end

--------------------------------------------------------------------------------
-- scrollBy
--! @brief Scrolls the elements by the provided world unit increments. Applies the direction constraint.
--! @param dx scroll value on X (world unit)
--! @param dy scroll value on Y (world unit)
--------------------------------------------------------------------------------
function GUIScroll:scrollBy(dx, dy)
	--local clickableWidth, clickableHeight = ClickableComponent_getBoxShapeSize(self.clickable)
	
	if self.direction == "vertical" then
		dx = 0
	end
	if self.direction == "horizontal" then
		dy = 0
	end
	
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:scrollBy() " .. tostring(dx) .. " " ..tostring(dy)) end
	local x, y = WorldNode_getLocalPosition(self.elements)
	self:scrollTo(x + dx * self.dragFactorX, y + dy * self.dragFactorY)
end

--------------------------------------------------------------------------------
-- scrollTo
--! @brief Scrolls the elements to the specified position in world units
--! @param x position on x axis (world unit)
--! @param y position on y axis (world unit)
--------------------------------------------------------------------------------
function GUIScroll:scrollTo(x, y)
	
	local clampXMin , clampXMax , clampYMin , clampYMax = self:getBoundaries()
	
	local x = MathClamp(x, clampXMin, clampXMax)
	local y = MathClamp(y, clampYMin, clampYMax)
	
	if clampXMax ~= clampXMin then
		self.scrollXValue = (x - clampXMin) / (clampXMax - clampXMin)
	else
		self.scrollXValue = 0
	end
	
	if clampYMax ~= clampYMin then
		self.scrollYValue = (y - clampYMin) / (clampYMax - clampYMin)
	else
		self.scrollYValue = 0
	end
	
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:scrollTo() : scroll values = " .. tostring(self.scrollXValue) .. "," .. tostring(self.scrollYValue)) end
	
	if GUI.roundedUnits then
		WorldNode_setLocalPosition(self.elements, MathRound(x), MathRound(y))
	else
		WorldNode_setLocalPosition(self.elements, x, y)
	end
	
	if self.listener ~= nil and self.listener.onScroll ~= nil then
		self.listener:onScroll(self, self.scrollXValue, self.scrollYValue)
	end
end

--------------------------------------------------------------------------------
-- scrollPercentXY
--! @brief Scrolls the elements to the specified ratios on X and Y axises
--! @param scrollXValue ratio in range [0, 1] on the X axis
--! @param scrollYValue ratio in range [0, 1] on the Y axis
--------------------------------------------------------------------------------
function GUIScroll:scrollPercentXY(scrollXValue, scrollYValue)
	
	local clickWidth, clickHeight = ClickableComponent_getBoxShapeSize(self.clickable)
	
	if self.layoutObj:getWidth() < clickWidth then
		self.scrollXValue = 1 - MathClamp(scrollXValue, 0, 1)
	else
		self.scrollXValue = MathClamp(scrollXValue, 0, 1)
	end
	if self.layoutObj:getHeight() < clickHeight then
		self.scrollYValue = 1 - MathClamp(scrollYValue, 0, 1)
	else
		self.scrollYValue = MathClamp(scrollYValue, 0, 1)
	end
	
	local clampXMin , clampXMax , clampYMin , clampYMax = self:getBoundaries()
	
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:scrollXY() : clamp X = [" .. clampXMin .. ":" .. clampXMax .. "]") end
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:scrollXY() : clamp Y = [" .. clampYMin .. ":" .. clampYMax .. "]") end
	
	local x = self.scrollXValue * (clampXMax - clampXMin) + clampXMin
	local y = self.scrollYValue * (clampYMax - clampYMin) + clampYMin
	
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:scrollXY() : pos  = " .. tostring(x) .. "," .. tostring(y)) end
	
	if GUI.roundedUnits then
		WorldNode_setLocalPosition(self.elements, MathRound(x), MathRound(y))
	else
		WorldNode_setLocalPosition(self.elements, x, y)
	end

	if self.listener ~= nil and self.listener.onScroll ~= nil then
		self.listener:onScroll(self, self.scrollXValue, self.scrollYValue)
	end
end

--------------------------------------------------------------------------------
-- scrollPercentX
--! @brief Scrolls the elements to the specified normalized value on horizontal axis
--! @param scrollXValue value in range [0, 1] on the X axis
--------------------------------------------------------------------------------
function GUIScroll:scrollPercentX(scrollXValue)
	
	local clickWidth, clickHeight = ClickableComponent_getBoxShapeSize(self.clickable)
	
	if self.layoutObj:getWidth() < clickWidth then
		self.scrollXValue = 1 - MathClamp(scrollXValue, 0, 1)
	else
		self.scrollXValue = MathClamp(scrollXValue, 0, 1)
	end

	local clampXMin , clampXMax , clampYMin , clampYMax = self:getBoundaries()
	
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:scrollXY() : clamp X = [" .. clampXMin .. ":" .. clampXMax .. "]") end
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:scrollXY() : clamp Y = [" .. clampYMin .. ":" .. clampYMax .. "]") end
	
	local x = self.scrollXValue * (clampXMax - clampXMin) + clampXMin
	local y = self.scrollYValue * (clampYMax - clampYMin) + clampYMin
	
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:scrollXY() : pos  = " .. tostring(x) .. "," .. tostring(y)) end
	
	if GUI.roundedUnits then
		WorldNode_setLocalPosition(self.elements, MathRound(x), MathRound(y))
	else
		WorldNode_setLocalPosition(self.elements, x, y)
	end

	if self.listener ~= nil and self.listener.onScroll ~= nil then
		self.listener:onScroll(self, self.scrollXValue, self.scrollYValue)
	end
end

--------------------------------------------------------------------------------
-- scrollPercentY
--! @brief Scrolls the elements to the specified normalized value on vertical axis
--! @param scrollYValue value in range [0, 1] on the Y axis
--------------------------------------------------------------------------------
function GUIScroll:scrollPercentY(scrollYValue)
	
	local clickWidth, clickHeight = ClickableComponent_getBoxShapeSize(self.clickable)
	
	if self.layoutObj:getHeight() < clickHeight then
		self.scrollYValue = 1 - MathClamp(scrollYValue, 0, 1)
	else
		self.scrollYValue = MathClamp(scrollYValue, 0, 1)
	end
	
	local clampXMin , clampXMax , clampYMin , clampYMax = self:getBoundaries()
	
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:scrollXY() : clamp X = [" .. clampXMin .. ":" .. clampXMax .. "]") end
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:scrollXY() : clamp Y = [" .. clampYMin .. ":" .. clampYMax .. "]") end
	
	local x = self.scrollXValue * (clampXMax - clampXMin) + clampXMin
	local y = self.scrollYValue * (clampYMax - clampYMin) + clampYMin
	
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIScroll:scrollXY() : pos  = " .. tostring(x) .. "," .. tostring(y)) end
	
	if GUI.roundedUnits then
		WorldNode_setLocalPosition(self.elements, MathRound(x), MathRound(y))
	else
		WorldNode_setLocalPosition(self.elements, x, y)
	end

	if self.listener ~= nil and self.listener.onScroll ~= nil then
		self.listener:onScroll(self, self.scrollXValue, self.scrollYValue)
	end
end

--------------------------------------------------------------------------------
--! @brief Impulses a scrolling given a speed
--! @param speedX initial speed on X
--! @param speedY initial speed on Y
--------------------------------------------------------------------------------
function GUIScroll:impulse(speedX, speedY)
	
	if not self.hasInnerScroll then
		local clickWidth, clickHeight = ClickableComponent_getBoxShapeSize(self.clickable)
	
		if MathAbs(speedX) > 0 and self.layoutObj:getWidth() < clickWidth then
			return
		end
		
		if MathAbs(speedY) > 0 and self.layoutObj:getHeight() < clickHeight then
			return
		end
	end
				
	self.computeInertia = true
	self.isDragging = false
	self.isDragEngaged = false
	
	self.speedX = speedX
	self.speedY = speedY
end

--------------------------------------------------------------------------------
-- setNodeSize
--! @brief Changes the size of a given node
--! @param node node to set size of
--! @param width new width of the node
--! @param height new height of the node
--------------------------------------------------------------------------------
function GUIScroll:setNodeSize(node, width, height)
	self.layoutObj:setElementSize(node, width, height)
end

--------------------------------------------------------------------------------
-- insertNode
--! @brief Inserts a new node into the elements at the specified position in the list
--! @param _node node to insert
--! @param _index index in the list to insert
--! @param _width width of the node
--! @param _height height of the node
--------------------------------------------------------------------------------
function GUIScroll:insertNode(_node, _index, _width, _height, pivotX, pivotY)
	
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUISCroll:insertNode() : " .. tostring(_node)) end
	
	if not pivotX then
		pivotX = 0.5
	end
	if not pivotY then
		pivotY = 0.5
	end

	self.layoutObj:insertElement(_index, _node, _width, _height, pivotX, pivotY)
	
	WorldNode_setNewParent(_node, self.elements)
	
	self:setupPreListenerToSelf(_node)
	
	-- Re-compute all elements position
	if not self.layoutObj.refreshSuspended then
		-- Compute new scroll position
		self:scrollPercentXY(self.scrollXValue, self.scrollYValue)
	end
end

--------------------------------------------------------------------------------
-- pushBackNode
--! @brief Adds a node at the end of the list
--! @param _node node to insert
--! @param _width width of the node
--! @param _height height of the node
--------------------------------------------------------------------------------
function GUIScroll:pushBackNode(_node, _width, _height, pivotX, pivotY)
	
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUISCroll:pushBackNode() : " .. tostring(_node)) end
	
	if not pivotX then
		pivotX = 0.5
	end
	if not pivotY then
		pivotY = 0.5
	end
	
	self.layoutObj:pushBackElement(_node, _width, _height, pivotX, pivotY)

	WorldNode_setNewParent(_node, self.elements)
	
	self:setupPreListenerToSelf(_node)
	
	-- Re-compute all elements position
	if not self.layoutObj.refreshSuspended then
		-- Compute new scroll position
		self:scrollPercentXY(self.scrollXValue, self.scrollYValue)
	end
end

--------------------------------------------------------------------------------
-- removeNodeByIndex
--! @brief Removes a node from the list given its index
--! @param nodeIndex index of the node to remove
--------------------------------------------------------------------------------
function GUIScroll:removeNodeByIndex(nodeIndex)
	
	if GUI.DEBUG_LEVEL.scroll_layout then GUI:debugPrint("[" .. tostring(self) .. "]\tGUISCroll:removeNodeByIndex() : @ " .. tostring(nodeIndex)) end

	self.layoutObj:removeByIndex(nodeIndex)

	WorldNode_removeChildNode(self.elements, node)
	
	-- Re-compute all elements position
	if not self.layoutObj.refreshSuspended then
		-- Compute new scroll position
		self:scrollPercentXY(self.scrollXValue, self.scrollYValue)
	end
end

--------------------------------------------------------------------------------
-- removeNode
--! @brief Removes the specified node from the list
--! @param node node to remove
--------------------------------------------------------------------------------
function GUIScroll:removeNode(node)
	self.layoutObj:removeElement(node)
	
	WorldNode_removeChildNode(self.elements, node)
	
	-- Re-compute all elements position
	if not self.layoutObj.refreshSuspended then

		-- Compute new scroll position
		self:scrollPercentXY(self.scrollXValue, self.scrollYValue)
	end
	
end

--------------------------------------------------------------------------------
-- setupPreListenerToSelf
--! @brief Setups the pre-listener of GUIElements attached to the specified world node
--! @param node world node to setup
--------------------------------------------------------------------------------
function GUIScroll:setupPreListenerToSelf(node)
	local guiElements = GUI:getGUIElementsOnNode(node)

	for i = 1, #guiElements do
		guiElements[i].preListener = self
	end
end

--------------------------------------------------------------------------------
-- clear
--! @brief Removes all nodes from the scroll
--------------------------------------------------------------------------------
function GUIScroll:clear()
	self.layoutObj:clear()
end

--------------------------------------------------------------------------------
-- suspendLayout
--! @brief Suspends the layout computation after a element is added or removed
--------------------------------------------------------------------------------
function GUIScroll:suspendLayout()
	self.layoutObj:suspend()
end

--------------------------------------------------------------------------------
-- resumeLayout
--! @brief Resumes the layout computation after a element is added or removed
--------------------------------------------------------------------------------
function GUIScroll:resumeLayout()
	self.layoutObj:resume()
end

--------------------------------------------------------------------------------
-- refreshLayout
--! @brief Recomputes the position of all elements in the list according to the layout
--------------------------------------------------------------------------------
function GUIScroll:refreshLayout()
	self.layoutObj:refresh()
end
