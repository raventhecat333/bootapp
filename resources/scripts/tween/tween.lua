require '../core/core.lua'
require 'tween_ease.lua'
require 'tween_sequence_node.lua'
require 'tween_parallel_node.lua'
require 'tween_animate_node.lua'
require 'tween_callback_node.lua'
require 'tween_loop_node.lua'
require 'tween_manager.lua'

--------------------------------------------------------------------------------
--! Tween
--!
--! This class represents a description of a tween. 
--------------------------------------------------------------------------------
Tween = class()

Tween.elems = {}

local function extendSequence(seq, desc)
    local result = new(Tween)
    result.klass = TweenSequenceNode
    result.elems = {}
    for i = 1, #seq.elems do
        result.elems[i] = seq.elems[i]
    end
    result.elems[#result.elems + 1] = desc
    return result
end

--------------------------------------------------------------------------------
--! @brief Describes a number of tweens which run at the same time.
--! @param ... The tweens to run in parallel.
--------------------------------------------------------------------------------
function Tween:parallel(...)
    return extendSequence(self, {
        klass = TweenParallelNode,
        elems = { ... }
    })
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which animates a bunch of properties on an object.
--! @param obj The object whose properties which will be animated. If this parameter is a string then it will be filled in later when the tween is started using the objMapping passed to start. If this parameter is a reference to an actual object then it will be used directly. If this parameter is nil then the tween will be a wait and not animate at all.
--! @param kind This parameter specifies how the properties table is interpreted. The possible values are:
--!   * <code><b>"to"</b></code>: Animates from the current value of the property to the specified value.
--!   * <code><b>"from"</b></code>: Animates from the specified value back to the current value of the property.
--!   * <code><b>"by"</b></code>: Animates from the current value of the property to the sum of the current value and the specified value.
--! @param duration The duration of the tween in seconds.
--! @param properties A table of the properties to animate.
--! @param easeFunction The ease function to use. The default is Ease.linear.
--! @param ... Extra parameters passed to the easing function.
--------------------------------------------------------------------------------
function Tween:animate(obj, duration, kind, properties, easeFunction, ...)
    return extendSequence(self, {
        klass = TweenAnimateNode,
        obj = obj,
        duration = duration,
        easeFunction = easeFunction or Ease.linear,
        easeFunctionArgCount = select('#', ...),
        easeFunctionArgs = { ... },
        properties = properties,
		kind = kind,
    })
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which calls a function.
--! @param func The function to be called.
--! @param ... Parameters passed to the function.
--------------------------------------------------------------------------------
function Tween:callback(func, ...)
    return extendSequence(self, {
        klass = TweenCallbackNode,
        func = func,
        argCount = select('#', ...),
        args = { ... }
    })
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which will play the given tween multiple times.
--! @param loopCount The number of times to loop.
--! @param tween The tween to loop.
--------------------------------------------------------------------------------
function Tween:loop(loopCount, tween)
    return extendSequence(self, {
        klass = TweenLoopNode,
        loopCount = loopCount,
        tween = tween
    })
end

--------------------------------------------------------------------------------
--! @brief Describes a number of tweens which run one after the other.
--! @param ... The tweens to run in a sequence.
--------------------------------------------------------------------------------
function Tween:sequence(...)
    local args = { ... }
    local result = new(Tween)
    result.klass = TweenSequenceNode
    result.elems = {}
    for i = 1, #self.elems do
        result.elems[i] = self.elems[i]
    end
    for i = 1, #args do
        for j = 1, #args[i].elems do
            result.elems[#result.elems + 1] = args[i].elems[j]
        end
    end
    return result
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which waits and does nothing.
--! @param duration The duration in seconds to wait.
--------------------------------------------------------------------------------
function Tween:wait(duration)
	return self:animate(nil, duration)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the enabled property of a WorldNode from the specified value to the current value.
--! @param obj The WorldNode to tween or a string to be replace from objMapping passed during start.
--! @param enabled The value to animate from.
--------------------------------------------------------------------------------
function Tween:worldNodeEnabledFrom(obj, duration, enabled)
	return self:animate(obj, duration, 'from', { worldNodeEnabled = enabled })
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the enabled property of a Component from the specified value to the current value.
--! @param obj The Component to tween or a string to be replace from objMapping passed during start.
--! @param enabled The value to animate from.
--------------------------------------------------------------------------------
function Tween:componentEnabledFrom(obj, duration, enabled)
	return self:animate(obj, duration, 'from', { componentEnabled = enabled })
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the local position of a WorldNode from the specified value to the current value.
--! @param obj The WorldNode to tween or a string to be replace from objMapping passed during start.
--! @param x The local x-coordinate.
--! @param y The local y-coordinate.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:moveFrom(obj, duration, x, y, easeFunction, ...)
	return self:animate(obj, duration, 'from', { localPositionX = x, localPositionY = y }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the local scale of a WorldNode from the specified value to the current value.
--! @param obj The WorldNode to tween or a string to be replace from objMapping passed during start.
--! @param x The local x-coordinate.
--! @param y The local y-coordinate.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:scaleFrom(obj, duration, x, y, easeFunction, ...)
	return self:animate(obj, duration, 'from', { localScaleX = x, localScaleY = y }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the local rotation of a WorldNode from the specified value to the current value.
--! @param obj The WorldNode to tween or a string to be replace from objMapping passed during start.
--! @param angle The rotation angle.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:rotateFrom(obj, duration, angle, easeFunction, ...)
	return self:animate(obj, duration, 'from', { localRotation = angle }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the color of a visual component from the specified value to the current value.
--! @param obj The visual component to tween or a string to be replace from objMapping passed during start.
--! @param r The red value between 0 and 1.
--! @param g The green value between 0 and 1.
--! @param b The blue value between 0 and 1.
--! @param a The alpha value between 0 and 1.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:colorFrom(obj, duration, r, g, b, a, easeFunction, ...)
	return self:animate(obj, duration, 'from', { red = r, green = g, blue = b, alpha = a }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the alpha of a visual component from the specified value to the current value.
--! @param obj The visual component to tween or a string to be replace from objMapping passed during start.
--! @param a The alpha value between 0 and 1.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:alphaFrom(obj, duration, a, easeFunction, ...)
	return self:animate(obj, duration, 'from', { alpha = a }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the enabled property of a WorldNode from the current value to the specified value.
--! @param obj The WorldNode to tween or a string to be replace from objMapping passed during start.
--! @param enabled The value to animate from.
--------------------------------------------------------------------------------
function Tween:worldNodeEnabledTo(obj, duration, enabled)
	return self:animate(obj, duration, 'to', { worldNodeEnabled = enabled })
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the enabled property of a Component from the current value to the specified value.
--! @param obj The Component to tween or a string to be replace from objMapping passed during start.
--! @param enabled The value to animate from.
--------------------------------------------------------------------------------
function Tween:componentEnabledTo(obj, duration, enabled)
	return self:animate(obj, duration, 'to', { componentEnabled = enabled })
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the local position of a WorldNode from the current value to the specified value.
--! @param obj The WorldNode to tween or a string to be replace from objMapping passed during start.
--! @param x The local x-coordinate.
--! @param y The local y-coordinate.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:moveTo(obj, duration, x, y, easeFunction, ...)
	return self:animate(obj, duration, 'to', { localPositionX = x, localPositionY = y }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the local scale of a WorldNode from the current value to the specified value.
--! @param obj The WorldNode to tween or a string to be replace from objMapping passed during start.
--! @param x The local x-coordinate.
--! @param y The local y-coordinate.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:scaleTo(obj, duration, x, y, easeFunction, ...)
	return self:animate(obj, duration, 'to', { localScaleX = x, localScaleY = y }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the local rotation of a WorldNode from the current value to the specified value.
--! @param obj The WorldNode to tween or a string to be replace from objMapping passed during start.
--! @param angle The rotation angle.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:rotateTo(obj, duration, angle, easeFunction, ...)
	return self:animate(obj, duration, 'to', { localRotation = angle }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the color of a visual component from the current value to the specified value.
--! @param obj The visual component to tween or a string to be replace from objMapping passed during start.
--! @param r The red value between 0 and 1.
--! @param g The green value between 0 and 1.
--! @param b The blue value between 0 and 1.
--! @param a The alpha value between 0 and 1.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:colorTo(obj, duration, r, g, b, a, easeFunction, ...)
	return self:animate(obj, duration, 'to', { red = r, green = g, blue = b, alpha = a }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the alpha of a visual component from the current value to the specified value.
--! @param obj The visual component to tween or a string to be replace from objMapping passed during start.
--! @param a The alpha value between 0 and 1.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:alphaTo(obj, duration, a, easeFunction, ...)
	return self:animate(obj, duration, 'to', { alpha = a }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the local position of a WorldNode from the current value to the sum of the current value and the specified value.
--! @param obj The WorldNode to tween or a string to be replace from objMapping passed during start.
--! @param x The local x-coordinate.
--! @param y The local y-coordinate.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:moveBy(obj, duration, x, y, easeFunction, ...)
	return self:animate(obj, duration, 'by', { localPositionX = x, localPositionY = y }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the local scale of a WorldNode from the current value to the sum of the current value and the specified value.
--! @param obj The WorldNode to tween or a string to be replace from objMapping passed during start.
--! @param x The local x-coordinate.
--! @param y The local y-coordinate.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:scaleBy(obj, duration, x, y, easeFunction, ...)
	return self:animate(obj, duration, 'by', { localScaleX = x, localScaleY = y }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the local rotation of a WorldNode from the current value to the sum of the current value and the specified value.
--! @param obj The WorldNode to tween or a string to be replace from objMapping passed during start.
--! @param angle The rotation angle.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:rotateBy(obj, duration, angle, easeFunction, ...)
	return self:animate(obj, duration, 'by', { localRotation = angle }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the color of a visual component from the current value to the sum of the current value and the specified value.
--! @param obj The visual component to tween or a string to be replace from objMapping passed during start.
--! @param r The red value between 0 and 1.
--! @param g The green value between 0 and 1.
--! @param b The blue value between 0 and 1.
--! @param a The alpha value between 0 and 1.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:colorBy(obj, duration, r, g, b, a, easeFunction, ...)
	return self:animate(obj, duration, 'by', { red = r, green = g, blue = b, alpha = a }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which changes the alpha of a visual component from the current value to the sum of the current value and the specified value.
--! @param obj The visual component to tween or a string to be replace from objMapping passed during start.
--! @param a The alpha value between 0 and 1.
--! @param easeFunction The easing function to use. The default is Ease.linear.
--! @param ... Extra parameters to pass to the easing function.
--------------------------------------------------------------------------------
function Tween:alphaBy(obj, duration, a, easeFunction, ...)
	return self:animate(obj, duration, 'by', { alpha = a }, easeFunction, ...)
end

--------------------------------------------------------------------------------
--! @brief Creates a new instance of this tween and starts it running.
--! @param objMapping A table mapping strings to objects which will be used to replace any strings used for <code>obj</code> parameters in the description.
--! @return The tween instance.
--------------------------------------------------------------------------------
function Tween:start(objMapping)
    local inst = self.klass.new(self, objMapping)
    local id = TweenManager.manager:startTween(inst)
	return id
end

--------------------------------------------------------------------------------
--! @brief Describes a tween which resumes up the coroutine which started the tween instance.
--------------------------------------------------------------------------------
function Tween:resumeCoroutine()
	return extendSequence(self, {
        klass = TweenResumeCoroutineNode
    })
end

--------------------------------------------------------------------------------
--! @brief Creates a new instance of this tween and starts it running, then immediately yields from the current coroutine. The current coroutine will be resumed after the tween is finished.
--! @return The tween instance.
--------------------------------------------------------------------------------
function Tween:startCoroutine(objMapping)
	local inst = self:resumeCoroutine():start(objMapping)
	coroutine.yield()
	return inst.id
end

