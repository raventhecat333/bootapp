-- Scripts/LanguageButton.lua
require 'scripts/gui/gui_button.lua'
--------------------------------------------------------------------------------
--! @brief LanguageButton Object script
--! @class LanguageButton
--! @parent GUIButton
--! @variable {Component} selectedVisual visual to display when the language is the selected one
--! @variable {Component} selectedSound sound to play when it becomes selected
--------------------------------------------------------------------------------

LanguageButton = class(GUIButton)
LanguageButton.selected = nil

function LanguageButton:start()
	if self.selectedVisual then
		self:disableVisual(self.selectedVisual)
	end
	
	GUIButton.start(self)
end


function LanguageButton:select(animate)
	if animate == nil then animate = true end

	if LanguageButton.selected and LanguageButton.selected ~= self then
		LanguageButton.selected:unselect(animate)
		SoundComponent_stop(self.selectedSound)
		SoundComponent_play(self.selectedSound)
	end
	if self.selectedVisual then
		Component_enable(self.selectedVisual)
		if self.runningTween then
			TweenManager.manager:stopTween(self.runningTween)
		end
		if animate then
			self.runningTween = Tween:alphaTo(self.selectedVisual, 0.5, 1, Ease.outQuint):start()
		else
			VisualComponent_setAlpha(self.selectedVisual, 1)
		end
	end

	LanguageButton.selected = self
end

function LanguageButton:unselect(animate)
	if animate == nil then animate = true end

	if self.selectedVisual then
		if self.runningTween then
			TweenManager.manager:stopTween(self.runningTween)
		end
		if animate then
			self.runningTween = Tween:alphaTo(self.selectedVisual, 0.5, 0, Ease.outQuint):callback(Component_disable, self.selectedVisual):start()
		else
			VisualComponent_setAlpha(self.selectedVisual, 0)
			Component_disable(self.selectedVisual)
		end
	end
	LanguageButton.selected = nil
end
