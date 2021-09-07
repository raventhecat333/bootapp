require '../core/core.lua'
require '../core/pool.lua'

TweenParallelNode = class()

createPooledNewAndFreeMethods(TweenParallelNode, true)

local elemsPool = new(Pool)

--------------------------------------------------------------------------------
--! @brief Creates a tween instance from a tween description.
--! @param desc The tween description.
--! @param objMapping The mapping from name to object.
--------------------------------------------------------------------------------
function TweenParallelNode:init(desc, objMapping)
    self.elems = elemsPool:alloc()
	for i = 1, #desc.elems do
        local node = desc.elems[i].klass.new(desc.elems[i], objMapping)
		self.elems[#self.elems + 1] = node
		node.finished = false
	end
end

function TweenParallelNode:destroy()
	for i = 1, #self.elems do
		self.elems[i]:free()
	end
	elemsPool:free(self.elems)
end

--------------------------------------------------------------------------------
--! @brief Returns the duration of the tween.
--------------------------------------------------------------------------------
function TweenParallelNode:getDuration()
    local duration = 0
    for i = 1, #self.elems do
        duration = math.max(duration, self.elems[i]:getDuration())
    end
    return duration
end

--------------------------------------------------------------------------------
--! @brief Called just before the tween instance starts running so that it can prepare its internal values if required.
--------------------------------------------------------------------------------
function TweenParallelNode:reset()
	for i = 1, #self.elems do
		self.elems[i]:reset()
		self.elems[i].finished = false
	end
end

--------------------------------------------------------------------------------
--! @brief Updates the tween instance by the specified time.
--! @param dt The amount of time to advance in seconds.
--! @return Returns the amount of time left after the update and whether the instance has finished or is still running.
--------------------------------------------------------------------------------
function TweenParallelNode:update(dt)
	local minDt = dt
	local allFinished = true
	for i = 1, #self.elems do
		if not self.elems[i].finished then
			local newDt, finished = self.elems[i]:update(dt)
			minDt = math.min(minDt, newDt)
			self.elems[i].finished = finished
			if not finished then
				allFinished = false
			end
		end
	end
	return minDt, allFinished
end
