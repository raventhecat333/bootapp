require 'gui.lua'

--------------------------------------------------------------------------------
-- GUI inputs constants
--------------------------------------------------------------------------------
GUI.AXIS_THRESHOLD = math.cos(math.pi / 4) -- 0.707
GUI.TOUCH_THRESHOLD = 0.2
GUI.KEY_THRESHOLD = 0.1

GUI.REPEAT_DELAY = 0.5
GUI.REPEAT_RATE = 0.1

GUI.REPEAT_TIME = 0.2

GUI.currentTime = 0
GUI.startPressedTime = 0
GUI.state = 0
GUI.devicePressed = 0
GUI.controlPressed = 0

--------------------------------------------------------------------------------
-- isControlPressed
--! @brief Returns whether a specified control on a specified device has been pressed on the previous frame
--! @param device device id
--! @param control control id
--! @param threshold threshold value
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isControlPressed(device, control, threshold)
	return (threshold >= 0 and Input_getState(device, control) >= threshold and Input_getPreviousState(device, control) < threshold) or (threshold < 0 and Input_getState(device, control) <= threshold and Input_getPreviousState(device, control) > threshold)
end

--------------------------------------------------------------------------------
-- isControlReleased
--! @brief Returns whether a specified control on a specified device has been released on the previous frame
--! @param device device id
--! @param control control id
--! @param threshold threshold value
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isControlReleased(device, control, threshold)
	return (threshold >= 0 and Input_getState(device, control) <= threshold and Input_getPreviousState(device, control) > threshold) or (threshold < 0 and Input_getState(device, control) >= threshold and Input_getPreviousState(device, control) < threshold)
end

--------------------------------------------------------------------------------
-- isControlDown
--! @brief Returns whether a specified control on a specified device has a down state
--! @param device device id
--! @param control control id
--! @param threshold threshold value
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isControlDown(device, control, threshold)
	return (threshold >= 0 and Input_getState(device, control) > threshold) or (threshold < 0 and Input_getState(device, control) < threshold)
end

--------------------------------------------------------------------------------
-- isControlUp
--! @brief Returns whether a specified control on a specified device has a up state
--! @param device device id
--! @param control control id
--! @param threshold threshold value
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isControlUp(device, control, threshold)
	return (threshold >= 0 and Input_getState(device, control) <= threshold) or (threshold < 0 and Input_getState(device, control) >= threshold)
end

--------------------------------------------------------------------------------
-- wasControlDown
--! @brief Returns whether a specified control on a specified device had a down state on the previous frame
--! @param device device id
--! @param control control id
--! @param threshold threshold value
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:wasControlDown(device, control, threshold)
	return (threshold >= 0 and Input_getPreviousState(device, control) > threshold) or (threshold < 0 and Input_getPreviousState(device, control) < threshold)
end

--------------------------------------------------------------------------------
-- wasControlUp
--! @brief Returns whether a specified control on a specified device had a up state on the previous frame
--! @param device device id
--! @param control control id
--! @param threshold threshold value
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:wasControlUp(device, control, threshold)
	return (threshold >= 0 and Input_getPreviousState(device, control) <= threshold) or (threshold < 0 and Input_getPreviousState(device, control) >= threshold)
end

--------------------------------------------------------------------------------
-- isControlPressedRepeat
--! @brief Returns whether a specified control on a specified device has been pressed on the previous frame or if it entered a repeat state
--! @param device device id
--! @param control control id
--! @param threshold threshold value
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isControlPressedRepeat(device, control, threshold)
	local pressed = GUI:isControlPressed(device, control, threshold)
	local down = GUI:isControlDown(device, control, threshold)

	local orientation = threshold >= 0
	

	
	if pressed then
		GUI.controlPressed = control
		GUI.devicePressed = device
		GUI.orientation = orientation
		GUI.state = 1
		
		GUI.startPressedTime = GUI.currentTime
		
		if GUI.DEBUG_LEVEL.input_repeat then GUI:debugPrint("state 0 : pressed") end
		
		return true
	end
	
	if GUI.state ~= 0 and GUI.devicePressed == device and GUI.controlPressed == control and GUI.orientation == orientation then
		if GUI.repeatedThisFrame then
			return true
		end
		if GUI.state == 1 then
			if not down then
				if GUI.DEBUG_LEVEL.input_repeat then GUI:debugPrint("state 1 : not down") end
				GUI.state = 0
			elseif GUI.currentTime - GUI.startPressedTime > GUI.REPEAT_DELAY then
				GUI.state = 2
				GUI.startPressedTime = GUI.currentTime
				if GUI.DEBUG_LEVEL.input_repeat then GUI:debugPrint("state 1 : repeat delay reached") end
				GUI.repeatedThisFrame = true
				return true
			end
		elseif GUI.state == 2 then
			if not down then
				if GUI.DEBUG_LEVEL.input_repeat then GUI:debugPrint("state 2 : not down") end
				GUI.state = 0
			elseif GUI.currentTime - GUI.startPressedTime > GUI.REPEAT_RATE then
				GUI.startPressedTime = GUI.currentTime
				if GUI.DEBUG_LEVEL.input_repeat then GUI:debugPrint("state 2 : repeat rate reached") end
				GUI.repeatedThisFrame = true
				return true
			end
		end
	end

	return false

end

--------------------------------------------------------------------------------
-- isKeyPressed
--! @brief Returns whether the specified key has been pressed during the last frame
--! @param device device id
--! @param control control id
--! @param threshold threshold value
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isKeyPressed(device, control)
	return GUI:isControlPressed(device, control, GUI.KEY_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isKeyPressedRepeat
--! @brief Returns whether the specified key has been pressed during the last frame or if is in repeat mode
--! @param device device id
--! @param control control id
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isKeyPressedRepeat(device, control)
	return GUI:isControlPressedRepeat(device, control, GUI.KEY_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isKeyReleased
--! @brief Returns whether the specified key has been release during the last frame
--! @param device device id
--! @param control control id
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isKeyReleased(device, control)
	return GUI:isControlReleased(device, control, GUI.KEY_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isTouched
--! @brief Returns whether the touch device has a touched state
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isTouched()
	return GUI:isControlDown(TOUCH_DEVICE, TOUCH_TOUCHED, GUI.TOUCH_THRESHOLD)
end

--------------------------------------------------------------------------------
-- wasTouched
--! @brief Returns whether the touch device has a touched state
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:wasTouched()
	return GUI:wasControlDown(TOUCH_DEVICE, TOUCH_TOUCHED, GUI.TOUCH_THRESHOLD)
end


--------------------------------------------------------------------------------
-- isLeftDown
--! @brief Returns whether the left key is in a down state
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isLeftDown()
	return GUI:isControlDown(PAD_DEVICE, GAMEPAD_PAD_LEFT, GUI.KEY_THRESHOLD) or GUI:isControlDown(PAD_DEVICE, GAMEPAD_AXIS_X, -GUI.AXIS_THRESHOLD) or GUI:isControlDown(PAD_DEVICE, GAMEPAD_RAXIS_X, -GUI.AXIS_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isLeftPressed
--! @brief Returns whether the left key has been pressed (can be repeated)
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isLeftPressed()
	return GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_PAD_LEFT, GUI.KEY_THRESHOLD) or GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_AXIS_X, -GUI.AXIS_THRESHOLD) or GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_RAXIS_X, -GUI.AXIS_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isRightDown
--! @brief Returns whether the right key is in a down state
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isRightDown()
	return GUI:isControlDown(PAD_DEVICE, GAMEPAD_PAD_RIGHT, GUI.KEY_THRESHOLD) or GUI:isControlDown(PAD_DEVICE, GAMEPAD_AXIS_X, GUI.AXIS_THRESHOLD) or GUI:isControlDown(PAD_DEVICE, GAMEPAD_RAXIS_X, GUI.AXIS_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isRightPressed
--! @brief Returns whether the right key has been pressed (can be repeated)
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isRightPressed()
	return GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_PAD_RIGHT, GUI.KEY_THRESHOLD) or GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_AXIS_X, GUI.AXIS_THRESHOLD) or GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_RAXIS_X, GUI.AXIS_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isUpDown
--! @brief Returns whether the up key is in a down state
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isUpDown()
	return GUI:isControlDown(PAD_DEVICE, GAMEPAD_PAD_UP, GUI.KEY_THRESHOLD) or GUI:isControlDown(PAD_DEVICE, GAMEPAD_AXIS_Y, -GUI.AXIS_THRESHOLD) or GUI:isControlDown(PAD_DEVICE, GAMEPAD_RAXIS_Y, -GUI.AXIS_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isUpPressed
--! @brief Returns whether the up key has been pressed (can be repeated)
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isUpPressed()
	return GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_PAD_UP, GUI.KEY_THRESHOLD) or GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_AXIS_Y, -GUI.AXIS_THRESHOLD) or GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_RAXIS_Y, -GUI.AXIS_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isDownDown
--! @brief Returns whether the down key is in a down state
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isDownDown()
	return GUI:isControlDown(PAD_DEVICE, GAMEPAD_PAD_DOWN, GUI.KEY_THRESHOLD) or GUI:isControlDown(PAD_DEVICE, GAMEPAD_AXIS_Y, GUI.AXIS_THRESHOLD) or GUI:isControlDown(PAD_DEVICE, GAMEPAD_RAXIS_Y, GUI.AXIS_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isDownPressed
--! @brief Returns whether the down key has been pressed (can be repeated)
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isDownPressed()
	return GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_PAD_DOWN, GUI.KEY_THRESHOLD) or GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_AXIS_Y, GUI.AXIS_THRESHOLD) or GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_RAXIS_Y, GUI.AXIS_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isValidateDown
--! @brief Returns whether the validate key is in a down state
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isValidateDown()
	return not GUI:isTouched() and GUI:isControlDown(PAD_DEVICE, GAMEPAD_A, GUI.KEY_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isValidatePressed
--! @brief Returns whether the validate key has been pressed during the last frame
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isValidatePressed()
	return GUI:isKeyPressed(PAD_DEVICE, GAMEPAD_A, GUI.KEY_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isValidateReleased
--! @brief Returns whether the validate key has been released during the last frame
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isValidateReleased()
	return GUI:isControlReleased(PAD_DEVICE, GAMEPAD_A, GUI.KEY_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isCancelPressed
--! @brief Returns whether the cancel key has been pressed during the last frame
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isCancelPressed()
	return GUI:isKeyPressed(PAD_DEVICE, GAMEPAD_B, GUI.KEY_THRESHOLD)
end

--------------------------------------------------------------------------------
-- isAnythingPressed
--! @brief Returns whether any key has been pressed during the last frame
--! @return boolean value
--------------------------------------------------------------------------------
function GUI:isAnythingPressed()
	return self:isLeftPressed() or self:isRightPressed() or self:isUpPressed() or self:isDownPressed() or self:isValidatePressed() or self:isCancelPressed() or self:isTouched()
end


