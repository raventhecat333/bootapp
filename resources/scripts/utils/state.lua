
---
-- You attach an animation and a callback to a state object
-- call start() to start the animation
-- and it will trigger the callback once the animation is finished
-- Useful to make a delay for animation to complete before performing some action
State = class()

--- A constructor
-- @param animation Component
-- @param triggerObject callback object
-- @param triggerMethod callback function
function State:init(animation, triggerObject, triggerMethod)
	--print('State:init()')
	self.animation = animation
	self.triggerObject = triggerObject
	self.triggerMethod = triggerMethod
	self.started = false
	self.duration = 0.5						-- use AnimatorComponent_getDuration() when it's available
	self.timeStart = nil
	self.fadeSound = nil
end

function State:fadeMusic(sound) 
	self.fadeSound = sound
end

function State:start()
	if not self.started then
		print('State:start()')
		self.started = true
		Component_enable(self.animation)
		AnimatorComponent_reset(self.animation)
		AnimatorComponent_play(self.animation)
		self.timeStart = TweenState:getTimestamp()
	end
end

function State:update()
	--print('State:update()')
	if self.started then
		if self.fadeSound then
			local currentTime = TweenState:getTimestamp()
			local alpha = 1 - ((currentTime - self.timeStart) / self.duration)
			--print(tostring(self) .. ' ' .. currentTime .. ' / ' .. self.duration .. ' = ' .. alpha)
			SoundComponent_setVolume(self.fadeSound, alpha)
		end
		if AnimatorComponent_isStopped(self.animation) then
			self.started = false
			AnimatorComponent_reset(self.animation)
			self.triggerMethod(self.triggerObject)
		end
	end
end
