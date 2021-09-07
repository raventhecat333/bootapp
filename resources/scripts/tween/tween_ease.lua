--
-- Adapted from
-- Tweener's easing functions (Penner's Easing Equations)
-- and http://code.google.com/p/tweener/ (jstweener javascript version)
--

--[[
Disclaimer for Robert Penner's Easing Equations license:
TERMS OF USE - EASING EQUATIONS
Open source under the BSD License.
Copyright © 2001 Robert Penner
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

local sin = math.sin
local cos = math.cos
local pi = math.pi
local sqrt = math.sqrt
local abs = math.abs
local asin  = math.asin

--! Ease module
Ease = class()

--! @brief simple linear tweening - no easing, no acceleration
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.linear(t, b, c, d)
  return c * t / d + b
end

--! @brief quadratic easing in - accelerating from zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inQuad(t, b, c, d)
  t = t / d
  return c * (t * t) + b
end

--! @brief quadratic easing out - decelerating to zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outQuad(t, b, c, d)
  t = t / d
  return -c * t * (t - 2) + b
end

--! @brief quadratic easing in/out - acceleration until halfway, then deceleration
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inOutQuad(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * (t * t) + b
  else
    return -c / 2 * ((t - 1) * (t - 3) - 1) + b
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outInQuad(t, b, c, d)
  if t < d / 2 then
    return Ease.outQuad (t * 2, b, c / 2, d)
  else
    return Ease.inQuad((t * 2) - d, b + c / 2, c / 2, d)
  end
end

--! @brief cubic easing in - accelerating from zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inCubic (t, b, c, d)
  t = t / d
  return c * (t * t * t) + b
end

--! @brief cubic easing out - decelerating to zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outCubic(t, b, c, d)
  t = t / d - 1
  return c * (t * t * t + 1) + b
end

--! @brief cubic easing in/out - acceleration until halfway, then deceleration
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inOutCubic(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * t * t * t + b
  else
    t = t - 2
    return c / 2 * (t * t * t + 2) + b
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outInCubic(t, b, c, d)
  if t < d / 2 then
    return Ease.outCubic(t * 2, b, c / 2, d)
  else
    return Ease.inCubic((t * 2) - d, b + c / 2, c / 2, d)
  end
end

--! @brief quartic easing in - accelerating from zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inQuart(t, b, c, d)
  t = t / d
  return c * (t * t * t * t) + b
end

--! @brief quartic easing out - decelerating to zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outQuart(t, b, c, d)
  t = t / d - 1
  return -c * ((t * t * t * t) - 1) + b
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inOutQuart(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * (t * t * t * t) + b
  else
    t = t - 2
    return -c / 2 * ((t * t * t * t) - 2) + b
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outInQuart(t, b, c, d)
  if t < d / 2 then
    return Ease.outQuart(t * 2, b, c / 2, d)
  else
    return Ease.inQuart((t * 2) - d, b + c / 2, c / 2, d)
  end
end

--! @brief quintic easing in - accelerating from zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inQuint(t, b, c, d)
  t = t / d
  return c * (t * t * t * t * t) + b
end

--! @brief quintic easing out - decelerating to zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outQuint(t, b, c, d)
  t = t / d - 1
  return c * ((t * t * t * t * t) + 1) + b
end

--! @brief quintic easing in/out - acceleration until halfway, then deceleration
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inOutQuint(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * (t * t * t * t * t) + b
  else
    t = t - 2
    return c / 2 * ((t * t * t * t * t) + 2) + b
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outInQuint(t, b, c, d)
  if t < d / 2 then
    return Ease.outQuint(t * 2, b, c / 2, d)
  else
    return Ease.inQuint((t * 2) - d, b + c / 2, c / 2, d)
  end
end

--! @brief sinusoidal easing in - accelerating from zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inSine(t, b, c, d)
  return -c * cos(t / d * (pi / 2)) + c + b
end

--! @brief sinusoidal easing out - decelerating to zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outSine(t, b, c, d)
  return c * sin(t / d * (pi / 2)) + b
end

--! @brief sinusoidal easing in/out - accelerating until halfway, then decelerating
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inOutSine(t, b, c, d)
  return -c / 2 * (cos(pi * t / d) - 1) + b
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outInSine(t, b, c, d)
  if t < d / 2 then
    return Ease.outSine(t * 2, b, c / 2, d)
  else
    return Ease.inSine((t * 2) -d, b + c / 2, c / 2, d)
  end
end

--! @brief exponential easing in - accelerating from zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inExpo(t, b, c, d)
  if t == 0 then
    return b
  else
    return c * 2 ^ (10 * (t / d - 1)) + b - c * 0.001
  end
end

--! @brief exponential easing out - decelerating to zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outExpo(t, b, c, d)
  if t == d then
    return b + c
  else
    return c * 1.001 * (-2 ^ (-10 * t / d) + 1) + b
  end
end

--! @brief exponential easing in/out - accelerating until halfway, then decelerating
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inOutExpo(t, b, c, d)
  if t == 0 then return b end
  if t == d then return b + c end
  t = t / d * 2
  if t < 1 then
    return c / 2 * 2 ^ (10 * (t - 1)) + b - c * 0.0005
  else
    t = t - 1
    return c / 2 * 1.0005 * (-(2 ^ (-10 * t)) + 2) + b
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outInExpo(t, b, c, d)
  if t < d / 2 then
    return Ease.outExpo(t * 2, b, c / 2, d)
  else
    return Ease.inExpo((t * 2) - d, b + c / 2, c / 2, d)
  end
end

--! @brief circular easing in - accelerating from zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inCirc(t, b, c, d)
  t = t / d
  return(-c * (sqrt(1 - (t * t)) - 1) + b)
end

--! @brief circular easing out - decelerating to zero velocity
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outCirc(t, b, c, d)
  t = t / d - 1
  return(c * sqrt(1 - (t * t)) + b)
end

--! @brief circular easing in/out - acceleration until halfway, then deceleration
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inOutCirc(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return -c / 2 * (sqrt(1 - t * t) - 1) + b
  else
    t = t - 2
    return c / 2 * (sqrt(1 - t * t) + 1) + b
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outInCirc(t, b, c, d)
  if t < d / 2 then
    return Ease.outCirc(t * 2, b, c / 2, d)
  else
    return Ease.inCirc((t * 2) - d, b + c / 2, c / 2, d)
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
--! @param a amplitud
--! @param p period
function Ease.inElastic(t, b, c, d, a, p)
  if t == 0 then return b end

  t = t / d

  if t == 1  then return b + c end

  if not p then p = d * 0.3 end

  local s

  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c/a)
  end

  t = t - 1

  return -(a * 2 ^ (10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
--! @param a amplitud
--! @param p period
function Ease.outElastic(t, b, c, d, a, p)
  if t == 0 then return b end

  t = t / d

  if t == 1 then return b + c end

  if not p then p = d * 0.3 end

  local s

  if not a or abs(a) < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c/a)
  end

  return a * 2 ^ (-10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
--! @param a amplitud
--! @param p period
function Ease.inOutElastic(t, b, c, d, a, p)
  if t == 0 then return b end

  t = t / d * 2

  if t == 2 then return b + c end

  if not p then p = d * (0.3 * 1.5) end
  if not a then a = 0 end

  local s

  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c / a)
  end

  if t < 1 then
    t = t - 1
    return -0.5 * (a * 2 ^ (10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
  else
    t = t - 1
    return a * 2 ^ (-10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
--! @param a amplitud
--! @param p period
function Ease.outInElastic(t, b, c, d, a, p)
  if t < d / 2 then
    return Ease.outElastic(t * 2, b, c / 2, d, a, p)
  else
    return Ease.inElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d
  return c * t * t * ((s + 1) * t - s) + b
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d - 1
  return c * (t * t * ((s + 1) * t + s) + 1) + b
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inOutBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  s = s * 1.525
  t = t / d * 2
  if t < 1 then
    return c / 2 * (t * t * ((s + 1) * t - s)) + b
  else
    t = t - 2
    return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outInBack(t, b, c, d, s)
  if t < d / 2 then
    return Ease.outBack(t * 2, b, c / 2, d, s)
  else
    return Ease.inBack((t * 2) - d, b + c / 2, c / 2, d, s)
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outBounce(t, b, c, d)
  t = t / d
  if t < 1 / 2.75 then
    return c * (7.5625 * t * t) + b
  elseif t < 2 / 2.75 then
    t = t - (1.5 / 2.75)
    return c * (7.5625 * t * t + 0.75) + b
  elseif t < 2.5 / 2.75 then
    t = t - (2.25 / 2.75)
    return c * (7.5625 * t * t + 0.9375) + b
  else
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inBounce(t, b, c, d)
  return c - Ease.outBounce(d - t, 0, c, d) + b
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.inOutBounce(t, b, c, d)
  if t < d / 2 then
    return Ease.inBounce(t * 2, 0, c, d) * 0.5 + b
  else
    return Ease.outBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
  end
end

--! @brief 
--! @param t elapsed time
--! @param b begin value
--! @param c change == ending - beginning
--! @param d duration
function Ease.outInBounce(t, b, c, d)
  if t < d / 2 then
    return Ease.outBounce(t * 2, b, c / 2, d)
  else
    return Ease.inBounce((t * 2) - d, b + c / 2, c / 2, d)
  end
end
