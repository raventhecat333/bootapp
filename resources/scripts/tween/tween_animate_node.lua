require '../core/core.lua'
require '../core/pool.lua'

local accessors = {
	worldNodeEnabled = { get = WorldNode_isEnabled,         set = WorldNode_setEnabled        },
	componentEnabled = { get = Component_isEnabled,         set = Component_setEnabled        },
	localPositionX   = { get = WorldNode_getLocalPositionX, set = WorldNode_setLocalPositionX },
	localPositionY   = { get = WorldNode_getLocalPositionY, set = WorldNode_setLocalPositionY },
	localScaleX      = { get = WorldNode_getLocalScaleX,    set = WorldNode_setLocalScaleX    },
	localScaleY      = { get = WorldNode_getLocalScaleY,    set = WorldNode_setLocalScaleY    },
	localRotation    = { get = WorldNode_getLocalRotation,  set = WorldNode_setLocalRotation  },
	red              = { get = VisualComponent_getColorR,   set = VisualComponent_setColorR   },
	green            = { get = VisualComponent_getColorG,   set = VisualComponent_setColorG   },
	blue             = { get = VisualComponent_getColorB,   set = VisualComponent_setColorB   },
	alpha            = { get = VisualComponent_getAlpha,    set = VisualComponent_setAlpha    },
}


--------------------------------------------------------------------------------
--! @brief Adds accessor methods for a new property
--! @param name property name
--! @param getter method to retrieve the property's value
--! @param setter method to set the property's value
--------------------------------------------------------------------------------
function addTweenPropertyAccessor(name, getter, setter)
	accessors[name] = { get = getter, set = setter }
end

--------------------------------------------------------------------------------
--! TweenAnimateNode
--! A tween instance which is animating properties on an object.
--------------------------------------------------------------------------------
TweenAnimateNode = class()

createPooledNewAndFreeMethods(TweenAnimateNode, true)

local propertiesArrayPool = new(Pool)
local propertiesPool = new(Pool)

--------------------------------------------------------------------------------
--! @brief Creates a tween instance from a tween description.
--! @param desc The tween description.
--! @param objMapping The mapping from name to object.
--------------------------------------------------------------------------------
function TweenAnimateNode:init(desc, objMapping)
	self.currentTime = 0
	if type(desc.obj) == 'string' then
		self.obj = objMapping[desc.obj]
	else
		self.obj = desc.obj
	end
	self.duration = desc.duration
	self.easeFunction = desc.easeFunction
	self.easeFunctionArgCount = desc.easeFunctionArgCount
	self.easeFunctionArgs = desc.easeFunctionArgs
	self.kind = desc.kind
    self.properties = propertiesArrayPool:alloc()
	if desc.properties then
        for prop, val in pairs(desc.properties) do
			if type(val) == 'string' then
				val = objMapping[val]
			end
			local property = propertiesPool:alloc()
			property.get = accessors[prop].get
            property.set = accessors[prop].set
			property.targetValue = val
            self.properties[#self.properties + 1] = property
        end
    end
end

function TweenAnimateNode:destroy()
	for i = 1, #self.properties do
		propertiesPool:free(self.properties[i])
	end
	propertiesArrayPool:free(self.properties)
end

--------------------------------------------------------------------------------
--! @brief Returns the duration of the tween.
--------------------------------------------------------------------------------
function TweenAnimateNode:getDuration()
    return self.duration
end

--------------------------------------------------------------------------------
--! @brief Called just before the tween instance starts running so that it can prepare its internal values if required.
--------------------------------------------------------------------------------
function TweenAnimateNode:reset()
	self.currentTime = 0
	if self.obj then
		for i = 1, #self.properties do
			local prop = self.properties[i]
			if self.kind == 'to' then
				prop.begValue = prop.get(self.obj)
				prop.endValue = prop.targetValue
			elseif self.kind == 'from' then
				prop.begValue = prop.targetValue
				prop.endValue = prop.get(self.obj)
			elseif self.kind == 'by' then
				prop.begValue = prop.get(self.obj)
				if type(prop.begValue) == 'number' then
					prop.endValue = prop.begValue + prop.targetValue
				else
					prop.endValue = prop.targetValue
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
--! @brief Updates the tween instance by the specified time.
--! @param dt The amount of time to advance in seconds.
--! @return Returns the amount of time left after the update and whether the instance has finished or is still running.
--------------------------------------------------------------------------------
function TweenAnimateNode:update(dt)
	if self.currentTime <= self.duration then
		self.currentTime = self.currentTime + dt
        if self.obj then
            local curTime = math.min(self.currentTime, self.duration)
            for i = 1, #self.properties do
                local prop = self.properties[i]
                if type(prop.begValue) == 'number' then
                	if self.duration > 0 then
                		prop.set(self.obj, self.easeFunction(curTime, prop.begValue, prop.endValue - prop.begValue, self.duration, unpack(self.easeFunctionArgs, 1, self.easeFunctionArgCount)))
                	else
                		prop.set(self.obj, self.easeFunction(1, prop.begValue, prop.endValue - prop.begValue, 1, unpack(self.easeFunctionArgs, 1, self.easeFunctionArgCount)))
                	end
                else
                	if self.currentTime < self.duration then
                		prop.set(self.obj, prop.begValue)
                	else
                		prop.set(self.obj, prop.endValue)
                	end
                end
            end
        end
        return math.max(0, self.currentTime - self.duration), self.currentTime > self.duration
	else
		return 0, true
	end
end
