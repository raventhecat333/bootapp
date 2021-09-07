require 'scripts/core/core.lua'

Event = class()

function Event:new()
	return setmetatable({ raised = false, waiting = false }, self)
end

function Event:wait()
	if not self.raised then
		self.waiting = coroutine.running()
		coroutine.yield()
	end
	self.raised = false
end

function Event:raise()
	self.raised = true
	if self.waiting then
		local coroutineToResume = self.waiting
		self.waiting = false
		local status, errorCode = coroutine.resume(coroutineToResume)
		if not status then
			error(errorCode)
		end
	end
end

function Event:reset()
	self.raised = false
end

Semaphore = class()

function Semaphore:new(count)
	return setmetatable({ count = count or 0, event = Event:new() }, self)
end

function Semaphore:wait()
	if self.count > 0 then
		self.event:wait()
	end
end

function Semaphore:notify()
	if self.count <= 0 then
		error("Semaphore count is negative!")
	end
	self.count = self.count - 1
	if self.count == 0 then
		self.event:raise()
	end
end