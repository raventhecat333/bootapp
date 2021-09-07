require '../core/core.lua'
require '../core/pool.lua'

--------------------------------------------------------------------------------
--! TweenCallbackNode
--! A tween instance which calls a function.
--------------------------------------------------------------------------------
TweenCallbackNode = class()

createPooledNewAndFreeMethods(TweenCallbackNode, true)

--------------------------------------------------------------------------------
--! @brief Creates a tween instance from a tween description.
--! @param desc The tween description.
--! @param objMapping The mapping from name to object.
--------------------------------------------------------------------------------
function TweenCallbackNode:init(desc, objMapping)
	self.func = desc.func
    self.argCount = desc.argCount
    self.args = desc.args
end

--------------------------------------------------------------------------------
--! @brief Returns the duration of the tween.
--------------------------------------------------------------------------------
function TweenCallbackNode:getDuration()
    return 0
end

--------------------------------------------------------------------------------
--! @brief Called just before the tween instance starts running so that it can prepare its internal values if required.
--------------------------------------------------------------------------------
function TweenCallbackNode:reset()
end

--------------------------------------------------------------------------------
--! @brief Updates the tween instance by the specified time.
--! @param dt The amount of time to advance in seconds.
--! @return Returns the amount of time left after the update and whether the instance has finished or is still running.
--------------------------------------------------------------------------------
function TweenCallbackNode:update(dt)
    self.func(unpack(self.args, 1, self.argCount))
    return dt, true
end
