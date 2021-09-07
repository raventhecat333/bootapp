require '../core/core.lua'
require '../core/pool.lua'

--------------------------------------------------------------------------------
--! TweenResumeCoroutineNode
--! A tween instance which resumes the coroutine that started the tween.
--------------------------------------------------------------------------------
TweenResumeCoroutineNode = class()

createPooledNewAndFreeMethods(TweenResumeCoroutineNode, true)

--------------------------------------------------------------------------------
--! @brief Creates a tween instance from a tween description.
--! @param desc The tween description.
--! @param objMapping The mapping from name to object.
--------------------------------------------------------------------------------
function TweenResumeCoroutineNode:init(desc, objMapping)
	self.coroutineToResume = coroutine.running()
end

--------------------------------------------------------------------------------
--! @brief Returns the duration of the tween.
--------------------------------------------------------------------------------
function TweenResumeCoroutineNode:getDuration()
    return 0
end

--------------------------------------------------------------------------------
--! @brief Called just before the tween instance starts running so that it can prepare its internal values if required.
--------------------------------------------------------------------------------
function TweenResumeCoroutineNode:reset()
end

--------------------------------------------------------------------------------
--! @brief Updates the tween instance by the specified time.
--! @param dt The amount of time to advance in seconds.
--! @return Returns the amount of time left after the update and whether the instance has finished or is still running.
--------------------------------------------------------------------------------
function TweenResumeCoroutineNode:update(dt)
    coroutine.resume(self.coroutineToResume)
    return dt, true
end
