require 'scripts/helpers/httphelper.lua'
require 'scripts/utils/State.lua'

--------------------------------------------------------------------------------
-- Main CatalogItem data
--- Single video thumbnail. Clickable.
--------------------------------------------------------------------------------

--! Attributes
--! @variable {Component} 	[decideSound] Sound component for the second click
--! @variable {WorldNode} 	[selectedOverlay] Object
--! @variable {Component} 	[thumbnail] Component
--! @variable {LuaTable}	[buttonScript] LuaTable
--! @variable {Component} 	[clickAnimation] Component
--! @variable {WorldNode} 	[emptyBackground] Object
--
-- @property resource
-- @property catalogPage
-- @property catalogRow
-- @property title
-- @property currentItem
-- @property adBannerData
CatalogItem = class(HttpHelper)
CatalogItem.selected = nil		  -- will store the single currently selected CatalogItem instance

CatalogItem.imageMetaData = { CTR = { region = "FCRAM" } }


function CatalogItem:start()
	--- this is called videoData in other places
	self.currentItem = nil

	self:httpInit()
	self.clickAnimationState = new(State)
	self.clickAnimationState:init(self.clickAnimation, self, self.triggerPageSwitch)
	
	--print('HOST_PLATFORM_IS_WINDOWS: '..tostring(HOST_PLATFORM_IS_WINDOWS))
	--print('HOST_PLATFORM_IS_3DS: '..tostring(HOST_PLATFORM_IS_3DS))
end


-- We need to properly remove twwens that still existed while shutting down
function CatalogItem:stop()
	if self.loadedTween ~= nil then
		TweenManager.manager:stopTween(self.loadedTween)
		self.loadedTween = nil
	end
end


--------------------------------------------------------------------------------
-- Thumbnail logic
--------------------------------------------------------------------------------

-- Download and display this thumbnail
function CatalogItem:getThumbnail(url)
	if (HOST_PLATFORM_IS_WINDOWS) or (HOST_PLATFORM_IS_EMSCRIPTEN) then
		url = url:gsub(".3dst", ".png")
		--print(url)
	end
	
	self.imageUrl = url

	if url ~= nil then
		self.loadCoroutine = coroutine.wrap(CatalogItem.loadThumbnail)
		self:loadCoroutine(url)
	end
end


--------------------------------------------------------------------------------
-- Button events
--------------------------------------------------------------------------------

-- Prepare the button with the relevant info
--/*
-- * @param catalogPage integer
-- * @param catalogRow
-- * @param title string
-- * @param itemData = {rowPos: integer, itemPos: integer, description: string}
-- * @param adBannerData: array of several ad banners
-- * @param duration integer - duration in minutes
-- * @param viewCount integer - view counter
function CatalogItem:initialize(catalogPage, catalogRow, title, itemData, adBannerData, duration, viewCount, availableAllAges)
	self.catalogPage = catalogPage
	self.catalogRow = catalogRow
	self.title = title
	self.currentItem = itemData
	self.adBannerData = adBannerData
	self.duration = duration
	self.viewCount = viewCount
	self.availableAllAges = availableAllAges
	-- #3658: disable manual audio fade as it conflicts with the new tween system
	--self.clickAnimationState:fadeMusic(self.catalogPage.bgmSound)	-- which sound to fade-out

	--print('CatalogItem:initialize() ' .. self.currentItem.rowPos .. ', ' .. self.currentItem.itemPos)
end

function CatalogItem:loadThumbnail(url)
	-- wait for the component to be visible
	while not VisualComponent_isCulled(self.visibilityComponent) do
	--while self.loadCoroutine do 		-- debug
		coroutine.yield()
	end

	-- load the resource
	local resource = getImageFromPathAdvanced(url, {}, CatalogItem.imageMetaData)
	ResourceHandle_link(resource)

	-- wait for the resource to be loaded
	while ResourceHandle_isLoading(resource) do
		coroutine.yield()
	end

	if ResourceHandle_isLoaded(resource) then
		TextureComponent_setTexture(self.thumbnail, resource)
		Component_enable(self.thumbnail)
		WorldNode_setEnabled(self.emptyBackground, false)

		if self.buttonScript.currentState == "idle" then
			self.loadedTween = Tween:scaleTo(self.worldNode, 2, 1, 1, Ease.outElastic, 0.4):start()
		end
	else
		print('CatalogItem:loadThumbnail(), failed to load thumbnail ' .. url)
	end

	self.loadCoroutine = nil
end

-- Update the button state
function CatalogItem:update()
	if self.loadCoroutine ~= nil then
		self:loadCoroutine()
	end

	WorldNode_setEnabled(self.restrictedLogo, LightningPlayer.menu.isParentalControlRestricted and not self.availableAllAges)

	self.clickAnimationState:update()
end

--- called from CatalogPage when navigating
-- @param selected boolean
function CatalogItem:setSelected(selected, play_sound)
	local oldIsSelected = self.isSelected
	self.isSelected = selected
	WorldNode_setEnabled(self.selectedOverlay, selected)

	if selected == true then
		local prevSelected = CatalogItem.selected
		if prevSelected and prevSelected ~= self  then
			prevSelected.buttonScript.clickedSound = nil
			prevSelected:setSelected(false, play_sound)
		end
		CatalogItem.selected = self
		
		SoundComponent_stop(self.selectedSound)
		-- sound effect will be played only if the element is not already selected
		if oldIsSelected ~= self.isSelected and (play_sound == nil or play_sound) then
			SoundComponent_play(self.selectedSound)
		end
		
		self.catalogPage:setData(self.title, self.currentItem.description, self.duration, self.viewCount)
		self.catalogPage:setCurrentItem(self.currentItem.rowPos, self.currentItem.itemPos)

		-- update the language options
		LightningPlayer.menu:getLanguageObject():setCurrentVideoElement(self.currentItem, nil, false)
		self.buttonScript.clickedSound = self.decideSound
	end
end

function CatalogItem:onElementFocus(element)
	if self.isSelected == false then
		self:setSelected(true)
		self.catalogPage:scrollToItem(self.currentItem.rowPos, self.currentItem.itemPos)
	end
end

function CatalogItem:onButtonPress(button)
	if self.loadedTween ~= nil then
		TweenManager.manager:stopTween(self.loadedTween)
		self.loadedTween = nil
	end
end

--- first time you click, it's only selected
-- second click - switch page
function CatalogItem:onButtonClick(button)
	-- somehow CatalogItem receives (A) events even when on the PlaybackPage
	print('Current Page: ' .. tostring(LightningPlayer.menu.currentPage))
	print('CatalogPage: ' .. tostring(LightningPlayer.menu.catalogPage))
	if LightningPlayer.menu.currentPage ~= LightningPlayer.menu.catalogPage then
		return
	end
	if CatalogItem.selected ~= self then
		self:setSelected(true)
		self.catalogPage:scrollToItem(self.currentItem.rowPos, self.currentItem.itemPos)
		self.catalogRow:getBackground()
	else
		if LightningPlayer.menu.isParentalControlRestricted and not self.availableAllAges then
			--restricted, not playing, jump to Parental Control flow
			coroutine.wrap(LightningPlayer.menu.parentalControlFlow)(LightningPlayer.menu)
		else
			LightningPlayer.menu.ga:postSelectEpisode(self.currentItem.id)
			-- immediate animation start
			if false then
				Component_enable(self.clickAnimation)
				AnimatorComponent_reset(self.clickAnimation)
				AnimatorComponent_play(self.clickAnimation)
				self:triggerPageSwitch()
			else
				-- delayed page switch after the animation is done
				-- SoundComponent_stop(self.decideSound)
				-- SoundComponent_play(self.decideSound)
				self.clickAnimationState:start()
				Component_disable(self.buttonScript._ptr)
				GUI.disabled = true
				LightningPlayer.menu:fadeOutBgm()
			end
		end
	end
end

--- start playback
-- @see PlaybackPage:onOpen()
-- this is set as a callback in self.clickAnimationState
-- we need to reset the zoom level so that when [Back] is pressed it looks OK
function CatalogItem:triggerPageSwitch()
	--AnimatorComponent_reset(self.animation)	-- done in State
	--VisualComponent_setAlpha(self.selectedOverlay, 1)	-- wrong reference
	WorldNode_setLocalScale(self.worldNode, 1, 1)
	--local randomBanner = self.adBannerData[1]	-- original
	LightningPlayer.menu:askForLanguage(self.currentItem, self:getRandomBanner(), false)
	LightningPlayer.menu:getLanguageObject():setBackPage(CATALOG_PAGE)
	LightningPlayer.menu:getLanguageObject():setNextPage(PLAYBACK_PAGE)
end

function CatalogItem:getRandomBanner()
	local randomBanner = self.adBannerData[math.random(1, #self.adBannerData)]
	var_dump(randomBanner)
	return randomBanner
end

function debug_browseChildren()
	local CatalogItemNode = self.worldNode
	local currentComponent = WorldNode_getFirstChildNode(CatelogItemNode)
	repeat
		if (currentComponent) then
			print('Component: ' .. WorldNode_getName(currentComponent))
			currentComponent = WorldNode_getSiblingNode(currentComponent)
		end
	until (currentComponent == nil)
end

function debug_browseComponents()
	--debug(self)
	--var_dump(self)
	print('self: ', self) -- table
	local node = self.worldNode
	print('self.worldNode: ', node) -- lightuserdata
	local node2 = Component_getNode(self.thumbnail)
	print('Component_getNode: ', node2) -- different lightuserdata
	local animation1 = WorldNode_getComponentByTypeName(node, 'animator')
	print('animation1: ', animation1) -- nil
	local animations = WorldNode_getComponentsByTypeName(node, 'animator')
	print('animations: ', animations) -- different table
	var_dump(animations)
	--debug(animations)	// crash
	for key, value in pairs(animations) do
		print(key, value)
		var_dump(key)
		var_dump(value)
	end
end

--- Test
-- local ci = new(CatalogItem)
-- ci:onButtonClick('asd')
-- ci:onButtonClick('asd')

