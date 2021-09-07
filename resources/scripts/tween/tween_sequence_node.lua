require '../core/core.lua'
require '../core/pool.lua'

TweenSequenceNode = class()

createPooledNewAndFreeMethods(TweenSequenceNode, true)

local elemsPool = new(Pool)

--------------------------------------------------------------------------------
--! @brief Creates a tween instance from a tween description.
--! @param desc The tween description.
--! @param objMapping The mapping from name to object.
--------------------------------------------------------------------------------
function TweenSequenceNode:init(desc, objMapping)
	self.currentElem = 1
    self.elems = elemsPool:alloc()
    self.speed = 1
    for i = 1, #desc.elems do
        local node = desc.elems[i].klass.new(desc.elems[i], objMapping)
        self.elems[i] = node
	end
end

function TweenSequenceNode:destroy()
	for i = 1, #self.elems do
		self.elems[i]:free()
	end
	elemsPool:free(self.elems)
end

--------------------------------------------------------------------------------
--! @brief Returns the duration of the tween.
--------------------------------------------------------------------------------
function TweenSequenceNode:getDuration()
    local duration = 0
    for i = 1, #self.elems do
        duration = duration + self.elems[i]:getDuration()
    end
    return duration
end

--------------------------------------------------------------------------------
--! @brief Called just before the tween instance starts running so that it can prepare its internal values if required.
--------------------------------------------------------------------------------
function TweenSequenceNode:reset()
	self.currentElem = 1
    if #self.elems > 0 then
        self.elems[1]:reset()
    end
end

--------------------------------------------------------------------------------
--! @brief Updates the tween instance by the specified time.
--! @param dt The amount of time to advance in seconds.
--! @return Returns the amount of time left after the update and whether the instance has finished or is still running.
--------------------------------------------------------------------------------
function TweenSequenceNode:update(dt)
	local finished = false
	dt = dt * self.speed
	while dt > 0 and self.currentElem <= #self.elems do
		dt, finished = self.elems[self.currentElem]:update(dt)
		if finished then
			self.currentElem = self.currentElem + 1
			if self.currentElem <= #self.elems then
				self.elems[self.currentElem]:reset()
			end
		end
	end
	return dt / self.speed, self.currentElem > #self.elems
end
