require '../core/core.lua'
require '../core/pool.lua'

--------------------------------------------------------------------------------
--! TweenLoopNode
--! A tween instance which repeats a tween instance multiple times.
--------------------------------------------------------------------------------
TweenLoopNode = class()

createPooledNewAndFreeMethods(TweenLoopNode, true)

--------------------------------------------------------------------------------
--! @brief Creates a tween instance from a tween description.
--! @param desc The tween description.
--! @param objMapping The mapping from name to object.
--------------------------------------------------------------------------------
function TweenLoopNode:init(desc, objMapping)
    self.curLoops = 0
    self.loopCount = desc.loopCount
    self.tween = desc.tween.klass.new(desc.tween, objMapping)
end

function TweenLoopNode:destroy()
	self.tween:free()
end

--------------------------------------------------------------------------------
--! @brief Returns the duration of the tween.
--------------------------------------------------------------------------------
function TweenLoopNode:getDuration()
    return self.loopCount * self.tween:getDuration()
end

--------------------------------------------------------------------------------
--! @brief Called just before the tween instance starts running so that it can prepare its internal values if required.
--------------------------------------------------------------------------------
function TweenLoopNode:reset()
    self.curLoops = 0
    self.tween:reset()
end

--------------------------------------------------------------------------------
--! @brief Updates the tween instance by the specified time.
--! @param dt The amount of time to advance in seconds.
--! @return Returns the amount of time left after the update and whether the instance has finished or is still running.
--------------------------------------------------------------------------------
function TweenLoopNode:update(dt)
    while dt > 0 and self.curLoops < self.loopCount do
        local finished
        dt, finished = self.tween:update(dt)
        if finished then
            self.curLoops = self.curLoops + 1
            if self.curLoops < self.loopCount then
                self.tween:reset()
            end
        end
    end
    return dt, self.curLoops >= self.loopCount
end
