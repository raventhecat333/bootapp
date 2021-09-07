-- Scripts/Bootstrap.lua
require 'core/core.lua'

--------------------------------------------------------------------------------
--! @brief Bootstrap Bootstraps loading of the defaultScene
--! @class Bootstrap
--! @variable {Resource} defaultScene Link to the scene to load
--------------------------------------------------------------------------------

Bootstrap = class()

local firstFrame = true
local ANIM_DURATION = 1.0

--! @brief Callback when object is added to the world
function Bootstrap:start()
	ReedPlayer_setStereoscopyEnabled(false)
	
	print "[Bootstrap] Loading defaultScene"
	ResourceHandle_link(self.defaultScene)
	
	TweenManager:registerProperty('volume', SoundComponent_getVolume, SoundComponent_setVolume)
	
		
end

--! @brief Callback called every frame
function Bootstrap:update(dt)
	if firstFrame then
		SoundComponent_play(self.loadingSound)
		Tween:animate(self.loadingSound, ANIM_DURATION, "to", { volume = 1.0 }, Ease.inExpo):start()
		Tween:colorTo(self.loadingIcon, ANIM_DURATION, 1.0, 1.0, 1.0, 1.0, Ease.inExpo):start()
		Tween:colorTo(self.backgroundTop, ANIM_DURATION, 1.0, 1.0, 1.0, 1.0, Ease.inExpo):start()
		Tween:colorTo(self.backgroundBottom, ANIM_DURATION, 1.0, 1.0, 1.0, 1.0, Ease.inExpo):start()
		firstFrame = false
	elseif ResourceHandle_isLoaded(self.defaultScene) then 
		print "[Bootstrap] Loaded, switching to defaultScene"
		WorldNode_setEnabled(self.worldNode, false)
		WorldNode_destroy(self.worldNode)
		
		local defaultSceneRootNode = Scene_instantiate(self.defaultScene)
		WorldNodeManager_addHierarchyToWorld(defaultSceneRootNode)
		
		-- Lightning
		-- Improve sound transition from bootstrap to defaultScene
		local bootstrapSoundNode = WorldNode_getChildByName(self.worldNode, "sound")
		WorldNode_detachComponent(bootstrapSoundNode, self.loadingSound)
		
		
		local defaultSceneSoundNode = WorldNode_getChildByName(defaultSceneRootNode, "Sound")
		WorldNode_attachComponent(defaultSceneSoundNode, self.loadingSound)
		
		WorldNode_detachComponent(self.worldNode, self.tweenComponent)
		WorldNode_attachComponent(defaultSceneRootNode, self.tweenComponent)
		
		local splashPageNode = WorldNode_getChildByName(defaultSceneRootNode, "1-splashPage")
		local splashPageScriptComponent = WorldNode_getComponentByTypeName(splashPageNode, "script")
		local variables = ScriptComponent_getScriptTable(splashPageScriptComponent)
		variables.loadingSound = self.loadingSound
	end
end

