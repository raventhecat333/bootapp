require 'gui.lua'

--------------------------------------------------------------------------------
-- GUIPopup Object script
--! @class GUIPopup
--! 
--! Attributes
--! @variable {Component} [blockingClickable] clickable area blocking access to below elements. If not defined it is automatically created. Its size is GUI.screenWidth x GUI.screenHeight
--! @variable {Number}    [layer] minimum layer of popup. Every clickable objects below this layer won't be accessible. Default 0
--! @variable {Component} [ok_button] reference to the ok button
--! @variable {Component} [cancel_button] reference to the cancel button
--! @variable {Component} [yes_button] reference to the yes button
--! @variable {Component} [no_button] reference to the no button
--! 
--! Events
--! * onPopupClose(popup, userChoice)
--!
--------------------------------------------------------------------------------

GUIPopup = class()

--------------------------------------------------------------------------------
-- start
--! @brief Callback when the object is added to the world
--------------------------------------------------------------------------------
function GUIPopup:start()
	if GUI.DEBUG_LEVEL.runtime then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIPopup:start()") end
	if not self.layer then
		self.layer = 0
	end
	
	if self.ok_button then
		self.ok_button = ScriptComponent_getScriptTable(self.ok_button)
		GUI:enforceListener(self.ok_button, self, "GUIPopup", "GUIButton")
	end
	
	if self.cancel_button then
		self.cancel_button = ScriptComponent_getScriptTable(self.cancel_button)
		GUI:enforceListener(self.cancel_button, self, "GUIPopup", "GUIButton")
	end
	
	if self.yes_button then
		self.yes_button = ScriptComponent_getScriptTable(self.yes_button)
		GUI:enforceListener(self.yes_button, self, "GUIPopup", "GUIButton")
	end
	
	if self.no_button then
		self.no_button = ScriptComponent_getScriptTable(self.no_button)
		GUI:enforceListener(self.no_button, self, "GUIPopup", "GUIButton")
	end
	
	if self.blockingClickable == nil then
		if GUI.DEBUG_LEVEL.hit_test then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIPopup create blocking area") end
		self.blockingClickable = addNewComponentToNode(self.worldNode, COMPONENT_TYPE_CLICKABLE)
		ClickableComponent_setLayer(self.blockingClickable, self.layer)
		ClickableComponent_setBoxShape(self.blockingClickable, GUI.screenWidth, GUI.screenHeight)
	end
	
	GUI:focusElement(nil)
end

--------------------------------------------------------------------------------
-- stop
--! @brief Callback when object is removed from the world
--------------------------------------------------------------------------------
function GUIPopup:stop()
	if GUI.DEBUG_LEVEL.runtime then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIPopup:stop()") end
	
	if self.blockingClickable ~= nil then
		removeAndDestroyComponentFromNode(self.worldNode, self.blockingClickable)
	end
	
end

--------------------------------------------------------------------------------
-- close
--! @brief Closes the popup using the given choice and call listener callback
--! @param choice
--------------------------------------------------------------------------------
function GUIPopup:close(choice)
	WorldNode_setEnabled(self.worldNode, false)

	if self.listener ~= nil then
		self.listener:onPopupClose(self, choice)
	end
end

--------------------------------------------------------------------------------
-- onButtonClick
--! @brief Callback when a button is clicked
--! @param button Button that has been clicked
--------------------------------------------------------------------------------
function GUIPopup:onButtonClick(button)
	if GUI.DEBUG_LEVEL.callbacks then GUI:debugPrint("[" .. tostring(self) .. "]\tGUIPopup:onButtonClick()") end
	if button == self.ok_button then
		self:close("ok")
	elseif button == self.cancel_button then
		self:close("cancel")
	elseif button == self.yes_button then
		self:close("yes")
	elseif button == self.no_button then
		self:close("no")
	end
	
end

--------------------------------------------------------------------------------
-- enable
--! @brief Enable the entire popup by set all buttons in enabled state
--------------------------------------------------------------------------------
function GUIPopup:enable()
	if self.ok_button then
		self.ok_button:setState("enabled")
	end
	if self.cancel_button then
		self.cancel_button:setState("enabled")
	end
	if self.yes_button then
		self.yes_button:setState("enabled")
	end
	if self.no_button then
		self.no_button:setState("enabled")
	end
end

--------------------------------------------------------------------------------
-- disabled
--! @brief Disables the entire popup by set all buttons in disabled state
--------------------------------------------------------------------------------
function GUIPopup:disable()
	if self.ok_button then
		self.ok_button:setState("disabled")
	end
	if self.cancel_button then
		self.cancel_button:setState("disabled")
	end
	if self.yes_button then
		self.yes_button:setState("disabled")
	end
	if self.no_button then
		self.no_button:setState("disabled")
	end
end

--------------------------------------------------------------------------------
-- enable
--! @brief Enables the entire popup by set all buttons in idle state
--------------------------------------------------------------------------------
function GUIPopup:enable()
	if self.ok_button then
		self.ok_button:setState("idle")
	end
	if self.cancel_button then
		self.cancel_button:setState("idle")
	end
	if self.yes_button then
		self.yes_button:setState("idle")
	end
	if self.no_button then
		self.no_button:setState("idle")
	end
end

