
---
TweenState = class()

--- A constructor
-- @param component - world node which fill fade-out all it's components
-- @param triggerObject callback object
-- @param triggerMethod callback function
function TweenState:init(component, duration, callback)
	print('TweenState:init()')
	if self.started then
		self:stop()
	end
	self.component = component
	self.duration = duration
	self.callback = callback
	self.started = false
	self.tween = nil
	self.reverse = false
	self.visualComponents = {}
	self:collectAllVisualComponents(self.component, WorldNode_getName(self.component))
	print('TweenState:collectAllVisualComponents() done. Collected: ' .. #self.visualComponents .. ' components')
end

function TweenState:collectAllVisualComponents(from, name)
	local currentComponent = WorldNode_getFirstChildNode(from)
	repeat
		if (currentComponent) then
			local currentName = WorldNode_getName(currentComponent)
			--print('WorldNode child: ' .. currentName)
			
			self:getVisualComponentsFrom(currentComponent, 'sprite')
			self:getVisualComponentsFrom(currentComponent, 'sheet_sprite')
			self:getVisualComponentsFrom(currentComponent, 'animated_sprite')
			self:getVisualComponentsFrom(currentComponent, 'label')
			self:getVisualComponentsFrom(currentComponent, 'video')
			self:collectAllVisualComponents(currentComponent, name .. '/' .. currentName)

			currentComponent = WorldNode_getSiblingNode(currentComponent)
		end
	until (currentComponent == nil)
end

--- get components
function TweenState:getVisualComponentsFrom(currentComponent, type)
	local components = WorldNode_getComponentsByTypeName(currentComponent, type)
	for key, value in pairs(components) do
		self.visualComponents[#self.visualComponents + 1] = value
	end
	--print('#self.visualComponents: ' .. #self.visualComponents)
end

function TweenState:start()
	print('TweenState:start()')
	self.started = true
	self.startTime = self:getTimestamp()
	print('Start Time: ' .. tostring(self.startTime))
	--self.tween = Tween:alphaTo(self.visualComponents, self.duration, 0, Ease.linear)
	--self.tween:start()
end

function TweenState:getTimestamp() 
	local startTime = Application_getSystemTime()
	--var_dump(startTime, 'startTime')
	local timestamp = 	startTime.year 		* 60 * 60 * 24 * 365 +
						startTime.month 	* 60 * 60 * 24 * 12 + 
						startTime.day 		* 60 * 60 * 24 + 
						startTime.hours 	* 60 * 60 + 
						startTime.minutes 	* 60 + 
						startTime.seconds 	* 1 + 
						startTime.millisecs / 1000
	return timestamp
end

function TweenState:getISOTime() 
	local startTime = Application_getSystemTime()
	--var_dump(startTime, 'startTime')
	local time = 	startTime.year 							.. '-' ..
					string.lpad(startTime.month+1, 2, 0) 	.. '-' ..
					string.lpad(startTime.day+1, 2, 0)		.. ' ' ..
					string.lpad(startTime.hours, 2, 0) 		.. ':' ..
					string.lpad(startTime.minutes, 2, 0)	.. ':' ..
					string.lpad(startTime.seconds, 2, 0) 	.. '.' ..
					startTime.millisecs
	return time
end

function TweenState:update(dt)
	--print('TweenState:update(' .. tostring(dt) .. ')')
	if self.started then
		local newTime = self:getTimestamp()
		local timeSince = newTime - self.startTime
		local alpha = timeSince / self.duration;		-- [0..1]
		if self.reverse then
			alpha = 1 - alpha
		end
		for i = 1, #self.visualComponents do
			VisualComponent_setAlpha(self.visualComponents[i], alpha)
		end

		if timeSince >= self.duration then
			print('TweenState ended. Time since: ' .. timeSince)
			self:stop()
		end
	end
end

function TweenState:stop() 
	self.started = false
	self.callback:eventHandler()
end
