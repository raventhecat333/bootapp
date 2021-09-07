
--------------------------------------------------------------------------------
-- SplashPage Object script
--! @class SplashPage
--!
--! Attributes
--! @variable {Nil} 		loadingSound	Sound that goes with the loading animation.
--! @variable {WorldNode} 	loadingAnim 	WorldNode to the loading animation
--------------------------------------------------------------------------------

SplashPage = class()

function SplashPage:start()
	self.time = 0
	self.pTime = 0
end

function SplashPage:update(dt)
	self.time = self.time + dt
	if (math.floor(self.time) ~= self.pTime) then	-- once a second
		self.pTime = self.time
		-- (Feature Proposal #3193)
		--local quality = ReedPlayer_getNetworkQuality()
		--print('quality: ' .. tostring(quality))
	end
end

function SplashPage:onFocus()
	print('SplashPage:onFocus')
	--self:loadingSoundVolumeDown() --rather starting low then increasing than the other way around
	if self.loadingSound then
		SoundComponent_play(self.loadingSound)
	end
	WorldNode_setEnabled(self.loadingAnim, true)
end

function SplashPage:onBlur()
	print('SplashPage:onBlur')
	-- fade out
	
	WorldNode_setEnabled(self.loadingAnim, false)
end

function SplashPage:playLoadingSound()
	SoundComponent_play(self.loadingSound)
	SoundComponent_setVolume(self.loadingSound, 1)
end

function SplashPage:fadeOutLoadingSound()
	Tween:animate(self.loadingSound, 1, "to", { volume = 0 }, Ease.linear):callback(SoundComponent_stop, self.loadingSound):start()
end

function SplashPage:onButtonClick(button)
end

function SplashPage:loadingSoundVolumeDown()
	Tween:animate(self.loadingSound, 0.5, "to", { volume = 0.1 }, Ease.outCubic):start()
end

function SplashPage:loadingSoundVolumeUp()
	Tween:animate(self.loadingSound, 0.5, "to", { volume = 1 }, Ease.outCubic):start()
end
