require 'gui.lua'

--------------------------------------------------------------------------------
-- GUIList Object script
--! @class GUIList
--! @parent GUIElement
--! 
--! States
--! * idle
--! * disabled
--!
--! Attributes
--! @variable {String}    [direction] either "horizontal" or "vertical" or "both". Default : "horizontal"
--! @variable {WorldNode} [elements] world node that will contain all the list elements. If not provided, it will be automatically created
--! @variable {Component} [scroll] reference to the GUIScroll element
--! @variable {Component} [scrollBarH] reference to the GUISlider element used for the horizontal scrollbar (optional) 
--! @variable {Component} [scrollBarV] reference to the GUISlider element used for the vertical scrollbar (optional)
--! 
--! Events
--! * onElementFocus(element)
--! * onElementUnfocus(element)
--!
--------------------------------------------------------------------------------

GUIList = class(GUIElement)

--------------------------------------------------------------------------------
-- start
--! @brief Callback when the object is added to the world
--------------------------------------------------------------------------------
function GUIList:start()

	if GUI.DEBUG_LEVEL.runtime then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIList:start()") end
	
	if not self.scroll then
		GUI:error("GUIList must have a reference to a GUIScroll element")
		return
	end
	
	self.scroll = ScriptComponent_getScriptTable(self.scroll)
	self:enforceListenerToSelf(self.scroll, "GUIList", "GUIScroll")
	self.scroll.preListener = self

	if self.scrollBarH then
		self.scrollBarH = ScriptComponent_getScriptTable(self.scrollBarH)
		self.scrollBarH.direction = "horizontal"
		self:enforceListenerToSelf(self.scrollBarH, "GUIList", "GUISlider")
		self.scrollBarH.preListener = self
		self.scrollBarH:setValue(1 - self.scroll.scrollXValue)
	end
	if self.scrollBarV then
		self.scrollBarV = ScriptComponent_getScriptTable(self.scrollBarV)
		self.scrollBarV.direction = "vertical"
		self:enforceListenerToSelf(self.scrollBarV, "GUIList", "GUISlider")
		self.scrollBarV.preListener = self
		self.scrollBarV:setValue(1 - self.scroll.scrollYValue)
	end
	
	GUIElement.start(self)

end

--------------------------------------------------------------------------------
--! @brief callback on slider pressed
--! @param slider the pressed slider
--! @param value current value of slider
--------------------------------------------------------------------------------
function GUIList:onSliderPressed(slider, value)
	self.scroll:stopScroll()
end

--------------------------------------------------------------------------------
--! @brief callback on slider changes
--! @param slider slider of which value has changed
--! @param value new value of slider
--------------------------------------------------------------------------------
function GUIList:onSliderValueChange(slider, value)
	if slider == self.scrollBarH then
		self.scroll:scrollPercentX(1 - value)
	elseif slider == self.scrollBarV then
		self.scroll:scrollPercentY(1 - value)
	end
end

--------------------------------------------------------------------------------
--! @brief callback on scrolling
--! @param scroll scroll element which scrolled
--! @param valueX scroll value on horizontal axis
--! @param valueY scroll value on vertical axis
--------------------------------------------------------------------------------
function GUIList:onScroll(scroll, valueX, valueY)
	if scroll == self.scroll then
		if self.scrollBarH then
			self.scrollBarH:setValue(1 - valueX)
		end
		if self.scrollBarV then
			self.scrollBarV:setValue(1 - valueY)
		end
	end
end

--------------------------------------------------------------------------------
--! @brief Sets the scrolling values on both axises
--! @param valueX normalized scroll value on horizontal axis
--! @param valueY normalized scroll value on vertical axis
--------------------------------------------------------------------------------
function GUIList:setScrollValues(valueX, valueY)
	if self.scrollBarH then
		self:setScrollX(valueX)
	end
	if self.scrollBarV then
		self:setScrollY(valueY)
	end
end

--------------------------------------------------------------------------------
--! @brief Returns the current scroll value on horizontal axis
--! @return Normalized scroll value
--------------------------------------------------------------------------------
function GUIList:getScrollX()
	return self.scrollBarH.currentValue
end

--------------------------------------------------------------------------------
--! @brief Sets the scroll value on horizontal axis
--! @param valueX Normalized scroll value
--------------------------------------------------------------------------------
function GUIList:setScrollX(valueX)
	self.scrollBarH:setValue(valueX)
	self.scroll:scrollPercentX(1 - valueX)
end

--------------------------------------------------------------------------------
--! @brief Returns the current scroll value on vertical axis
--! @return Normalized scroll value
--------------------------------------------------------------------------------
function GUIList:getScrollY()
	return self.scrollBarV.currentValue
end

--------------------------------------------------------------------------------
--! @brief Sets the scroll value on vertical axis
--! @param valueY Normalized scroll value
--------------------------------------------------------------------------------
function GUIList:setScrollY(valueY)
	self.scrollBarV:setValue(valueY)
	self.scroll:scrollPercentY(1 - valueY)
end
