require '../core/core.lua'

--------------------------------------------------------------------------------
--! @class TweenManager
--------------------------------------------------------------------------------
TweenManager = class()

--------------------------------------------------------------------------------
--! @brief Starts the TweenManager when the object it is attached to is started
--------------------------------------------------------------------------------
function TweenManager:start()

	if TweenManager.manager ~= nil then
		error("Trying to start a TweenManager, but one already exists ('" .. WorldNode_getName(TweenManager.manager.worldNode) .. "')")
	end

	TweenManager.manager = self

	self:init()
end

--------------------------------------------------------------------------------
--! @brief Setups initial values
--------------------------------------------------------------------------------
function TweenManager:init()
	self.activeTweens = {}
	self.lastId = 0
	self.globalSpeed = 1
end

--------------------------------------------------------------------------------
--! @brief Registers a new animatable property into the Tween system
--! @param name property name
--! @param getter method to retrieve the property's value
--! @param setter method to set the property's value
--------------------------------------------------------------------------------
function TweenManager:registerProperty(name, getter, setter)
	addTweenPropertyAccessor(name, getter, setter)
end

--------------------------------------------------------------------------------
--! @brief Registers a new tween node to be updated
--! @param node tween node to register
--------------------------------------------------------------------------------
function TweenManager:startTween(node)
	local id = self.lastId
	self.lastId = id + 1
	
	node:reset()
	node.id = id
	
	self.activeTweens[#self.activeTweens + 1] = node
	
	return id
end

--------------------------------------------------------------------------------
--! @brief Unregisters a given tween node from update
--! @param node tween node to unregister
--------------------------------------------------------------------------------
function TweenManager:stopTween(id)
	local activeTweens = self.activeTweens
	local count = #activeTweens
	for i = 1, count do
		if activeTweens[i].id == id then
			activeTweens[i].dead = true
			return
		end
	end
end

--------------------------------------------------------------------------------
--! @brief Updates the manager and updates all registered tween nodes
--! @param dt delta time
--------------------------------------------------------------------------------
function TweenManager:update(dt)
	dt = dt * self.globalSpeed
	
	local activeTweens = self.activeTweens
	local i = 1
	
	while i <= #activeTweens do
		local tween = activeTweens[i]
		local finished = tween.dead
		if not finished then
			local _, updateFinished = tween:update(dt)
			finished = updateFinished
		end
		if finished then
			tween.dead = false
			tween:free()
			activeTweens[i] = activeTweens[#activeTweens]
			activeTweens[#activeTweens] = nil
		else
			i = i + 1
		end
	end
end
