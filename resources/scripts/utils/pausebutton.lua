require 'scripts/gui/gui.lua'
require 'scripts/gui/gui_check.lua'

--------------------------------------------------------------------------------
--! @brief Pause button 
--! @class PauseButton
--! @parent GUICheckButton
--------------------------------------------------------------------------------

PauseButton = class(GUICheckButton)

function PauseButton:start()
	GUICheckButton.start(self)
end

function PauseButton:stop()
	GUICheckButton.stop(self)
end

function PauseButton:update(dt)
	self:setChecked(not paused)
	GUICheckButton.update(self, dt)
end

