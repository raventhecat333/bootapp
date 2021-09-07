require 'scripts/core/core.lua'

--------------------------------------------------------------------------------
-- Main CatalogPage data
--! @class CatalogPage
--! @variable {LinkedResource} 	catalogRowPrefab Reference to the catalog row (=channel) prefab
--! @variable {LinkedResource} 	catalogItemPrefab Reference to the catatog item (=episode) prefab
--! @variable {WorldNode} 		catalogObject Reference to the catalog node
--! @variable {Component} 		textComponent Reference to the episode description label component
--! @variable {Component} 		errorComponent Reference to the error message component (different from above)
--! @variable {Component} 		titleComponent Reference to the episode title label component
--! @variable {Component} 		durationComponent Reference to the episode duration label component
--! @variable {Component} 		viewCountComponent Reference to the episode view count label component
--! @variable {Component} 		backgroundSprite Reference to the channel image sprite component
--! @variable {LuaTable} 		catalogList GUIScroll Reference to the catalog scroll script object
--! @variable {LuaTable} 		resumeButton Reference to the resume button script object
--! @variable {WorldNode}		reloadButton Reference to the world node with a reload button
--! @variable {Component}		bgmSound Reference to the background music component for the fade-out effect
--! @variable {LuaTable}		settingsButton bla-bla
--! @variable {WorldNode}		topDescriptionNode Reference to the whole top screen
--! @variable {Component}		errorSound bla-bla
--! @variable {LuaTable}		descriptionScroll bla-bla
--!
--! States
--!
--! Attributes
--! * titleComponent :
--! * textComponent :
--! * resumeButton : a worldnode which will be visible only if resume data is loaded from file
--!
--! Events
--! Properties
--! * self.rowList = {}
--! * self.catalogItemList = {}
--! * self.catalogList.scrollXValue = 1
--! * self.catalogList.scrollYValue = 1
--! * self.currentRow integer
--! * self.currentItem integer
--!
--------------------------------------------------------------------------------

-- Catalog layout constants
ROW_WIDTH = 320
ROW_HEIGHT = 100
ITEM_WIDTH = 120
ITEM_HEIGHT = 80

CatalogPage = class()

-- Callback when object is added to the world
function CatalogPage:start()
	print('CatalogPage:start()')

	-- setup description scrolling
	local w, h = VisualComponent_getSize(self.textComponent)
	local textComponentWN = Component_getNode(self.textComponent)

	print("textComponentNode = " .. tostring(textComponentWN))
	self.descriptionScroll:pushBackNode(textComponentWN, w, h, 0.5, 0)

	TweenManager:registerProperty("scrollX", GUIScroll.getScrollX, GUIScroll.scrollPercentX)
	TweenManager:registerProperty("scrollY", GUIScroll.getScrollY, GUIScroll.scrollPercentY)

	self.scrollPerChannel = {}

	self.scrollDownIconDisplayed = false

	self.originalIconPosX, self.originalIconPosY = WorldNode_getLocalPosition(self.scrollDownIcon)

	self.scrollTweenDesc = Tween:parallel(
		Tween:animate("scrollXObj", 0.4, "to", { scrollX = "scrollX" }, Ease.outCubic),
		Tween:animate("scrollYObj", 0.4, "to", { scrollY = "scrollY" }, Ease.outSine))
	self.scrollTweenDescMapping = {}
end

-- Callback when object is removed from the world
function CatalogPage:stop()
	print('CatalogPage:stop()')
end

function CatalogPage:onFocus()
	self.active = true
	WorldNode_setEnabled(self.topDescriptionNode, true)
	--SoundComponent_play(self.bgmSound)

	self.resumeButton:resetAnimations()

	print('CatalogPage:onFocus()')
	local currentItem = self:getCurrentItemObj()
	if currentItem then
		print('Reset animation')
		AnimatorComponent_reset(currentItem.clickAnimation)	-- not working

		-- @see ThumbnailClick.sceneanim
		WorldNode_setLocalScale(currentItem.worldNode, 1, 1)
		print('currentItem.selectedOverlay: ' .. tostring(WorldNode_getName(currentItem.selectedOverlay)))
		local SelectedSprite = WorldNode_getComponentByTypeName(currentItem.selectedOverlay, 'sheet_sprite')	-- WN
		if (SelectedSprite) then
			print('SelectedSprite')
			VisualComponent_setAlpha(SelectedSprite, 1.0)
		end
	end
end

--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------

-- Set the title and description data from the catalog
function CatalogPage:setData(title, description, duration, viewCount)
	local textComponent = self.textComponent
	LabelComponent_setText(self.titleComponent, title)
	LabelComponent_setText(textComponent, description)
	--[[
	--var_dump(duration)
	if duration and duration > 0 then
		local hours = math.floor(duration / 60)
		local minutes = duration % 60;
		LabelComponent_setText(self.durationComponent, hours .. ':' .. minutes)
	else
		LabelComponent_setText(self.durationComponent, '')
	end
	--var_dump(viewCount)
	if viewCount then
		LabelComponent_setText(self.viewCountComponent, viewCount .. ' ' .. __('MSG_VIEWS'))
	end
	--]]

	-- Setup description scrolling
	local w, h = VisualComponent_getSize(textComponent)
	local textComponentNode = Component_getNode(textComponent)
	self.descriptionScroll:setNodeSize(textComponentNode, w, h)
	self.descriptionScroll:scrollPercentXY(0.5, 0)

	local _, areaHeight = ClickableComponent_getBoxShapeSize(self.descriptionScroll.clickable)

	local displayScrollDownIcon = h > areaHeight

	WorldNode_setEnabled(self.scrollDownIcon, displayScrollDownIcon)

	-- if self.scrollDownIconDisplayed ~= displayScrollDownIcon then
	-- 	if self.scrollIconTween then
	-- 		TweenManager.manager:stopTween(self.scrollIconTween)
	-- 		self.scrollIconTween = nil
	-- 	end
	-- 	if displayScrollDownIcon then
	-- 		WorldNode_setEnabled(self.scrollDownIcon, true)
	-- 		WorldNode_setLocalPosition(self.scrollDownIcon, self.originalIconPosX, self.originalIconPosY)
	-- 		if not self.scrollIconTweenShowDesc then
	-- 			self.scrollIconTweenShowDesc = Tween:moveBy(self.scrollDownIcon, 0.5, -40, 0, Ease.outBounce)
	-- 		end
	-- 		self.scrollIconTween = self.scrollIconTweenShowDesc:start()
	-- 	else
	-- 		if not self.scrollIconTweenHideDesc then
	-- 			self.scrollIconTweenHideDesc = Tween:moveBy(self.scrollDownIcon, 0.5, 40, 0, Ease.outQuint):callback(WorldNode_setEnabled, self.scrollDownIcon, false)
	-- 		end
	-- 		self.scrollIconTween = self.scrollIconTweenHideDesc:start()
	-- 	end
	-- end

	-- self.scrollDownIconDisplayed = displayScrollDownIcon
end

---
-- @brief Used to display error messages
function CatalogPage:printStatus(status)
	--LabelComponent_setText(self.titleComponent, __("MSG_ERROR"))
	LabelComponent_setTextFromStringId(self.titleComponent, "MSG_ERROR")
	LabelComponent_setText(self.errorComponent, "")
	Component_setEnabled(self.errorComponent, true)
	Component_setEnabled(self.textComponent, false)
	LabelComponent_setText(self.durationComponent, '')
	LabelComponent_setText(self.viewCountComponent, '')
	WorldNode_setEnabled(self.resumeButton.worldNode, false)	-- [Resume] button hide
	Component_setEnabled(self.resumeButton._ptr, false)			-- [Resume] button hide
	SoundComponent_stop(self.bgmSound)
	SoundComponent_play(self.errorSound)						-- (Task #3481)
	--Component_setEnabled(self.settingsButton._ptr, false)		-- no effect
	WorldNode_setEnabled(self.settingsButton.worldNode, false)

	local listener = {notificationDismissed  = 	function()
													if LightningPlayer.menu.currentPage == LightningPlayer.menu.splashPage then
														LightningPlayer.menu.isFirstFrame = true
													else
														if LightningPlayer.menu.currentPage ~= LightningPlayer.menu.catalogPage then
															LightningPlayer.menu:goToCatalog()
														end
														print("Simulating click on reload button for automatic retry.")
														LightningPlayer.menu.catalogTable:clickReloadButton()
													end
												end}
	LightningPlayer.menu.networkErrorNotifier:notify(status, LightningPlayer.menu.errorSound, listener)
end

function CatalogPage:showReloadButton()
	WorldNode_setEnabled(self.reloadButton, true)
	print('reloadButton: ' .. tostring(WorldNode_isEnabled(self.reloadButton)))
end

-- Callback when object is a button and is released
function CatalogPage:onReleased()
end

-- Create the catalog menu on the bottom screen
function CatalogPage:createCatalogPanel(catalog)
	print('CatalogPage:createCatalogPanel()')

	--Re-enabling everything that could have been disabled when an error occured
	WorldNode_setEnabled(self.reloadButton, false)		-- hide reload button
	Component_setEnabled(self.errorComponent, false)		-- hide error message on top (Bug #3510)
	Component_setEnabled(self.textComponent, true)
	WorldNode_setEnabled(self.settingsButton.worldNode, true)
	self.playerInstance = LightningPlayer.menu

	if self.currentScrollTween ~= nil then
		TweenManager.manager:stopTween(self.currentScrollTween)
		self.currentScrollTween = nil
	end

	--Before filling a new one, removing the current catalog (if exist) to clean up
	if self.rowList then
		for rowIter = 1, #self.rowList do
			local currentElement = WorldNode_getFirstChildNode(self.rowList[rowIter].scroll.elements)
			repeat
				if (currentElement) then
					WorldNode_destroy(currentElement)
					currentElement = WorldNode_getSiblingNode(currentElement)
				end
			until (currentElement == nil)
			self.rowList[rowIter].scroll:clear()
		end
	end
	local currentElement = WorldNode_getFirstChildNode(self.catalogList.elements)
			repeat
				if (currentElement) then
					WorldNode_destroy(currentElement)
					currentElement = WorldNode_getSiblingNode(currentElement)
				end
			until (currentElement == nil)
	self.catalogList:clear()

	CatalogItem.selected = nil

	self.rowList = {}
	self.catalogItemList = {}
	self.catalogList.scrollXValue = 1
	self.catalogList.scrollYValue = 1

	-- Stops the layout computation
	self.catalogList:suspendLayout()

	-- Create the tiles
	for rowIter = 1, #catalog do
		row = rowIter

		-- Create a new scrollable row
		local newRow, rowattributes = Scene_instantiate(self.catalogRowPrefab)
		--var_dump(rowattributes)
		local rowScriptComp = rowattributes.catalog --WorldNode_getScriptComponent(newRow, 'CatalogRow')
		rowScriptComp:initialize(rowIter, self.backgroundSprite, catalog[row].imageUrls.default)
		LabelComponent_setText(rowScriptComp.title, catalog[row].title)

		--Register the row component
		self.rowList[row] = rowattributes.list 			-- where this "list" property comes from?
		self.rowList[row].rowScriptComp = rowScriptComp
		if row == 1 then
			print('rowScriptComp:getBackground() ' .. tostring(rowIter) .. ' ' .. tostring(row))
			rowScriptComp:getBackground()
		end

		-- Prepare the row
		self.catalogList:pushBackNode(newRow, ROW_WIDTH, ROW_HEIGHT)

		self.catalogItemList[row] = {}

		-- Stops the layout computation
		self.rowList[row].scroll:suspendLayout()

		-- Fill the row with the channel's contents
		for item = 1, #catalog[row].children do
			-- Prepare data
			local currentItem = catalog[row].children[item]

			--if (item == 1) then var_dump(currentItem) end
			currentItem.rowPos = row
			currentItem.itemPos = item

			-- Create the object
			local newItem, attributes = Scene_instantiate(self.catalogItemPrefab)
			self.rowList[row].scroll:pushBackNode(newItem, ITEM_WIDTH, ITEM_HEIGHT)
			local currentCatalogItemScript = WorldNode_getScriptComponent(newItem, 'CatalogItem')

			-- handling of special case "Coming Soon"
			local episodeNumber = tostring(currentItem.number)
			local title = nil
			if episodeNumber == "999" then
				-- #3673
				WorldNode_setEnabled(attributes.circleNode, false)	-- prefab property
				title = currentItem.title 					-- "Coming Soon"
			else
				title = tostring(episodeNumber) .. ' - ' .. currentItem.title
				LabelComponent_setText(attributes.numberText, episodeNumber)
			end

			-- Register data on the object
			currentCatalogItemScript:getThumbnail(currentItem.imageUrls.default)
			currentCatalogItemScript:initialize(self,
				rowScriptComp,
				title,
				currentItem,
				catalog[row].eshopLinks,
				currentItem.duration or 0,
				currentItem.viewCount,
				not (currentItem.ageRate ~= nil and tonumber(currentItem.ageRate) > 0))
			self.catalogItemList[row][item] = currentCatalogItemScript
		end

		-- Recompute row layout
		self.rowList[row].scroll:resumeLayout()
		self.rowList[row].scroll:refreshLayout()

		self.rowList[row]:setScrollValues(0, 0)
	end
	if #catalog then
		self:showResumeButton()
	end

	-- Recompute the catalog layout
	self.catalogList:resumeLayout()
	self.catalogList:refreshLayout()

	-- Ending
	self:setCurrentItem(1, 1)
	self:selectCurrentItem()
	self.catalogList:scrollPercentXY(0, 0)

	-- set initial scroll position PER channel to 1
	for i = 1, #self.rowList do
		self.scrollPerChannel[i] = 1
	end

	print('CatalogPage:createCatalogPanel() done')
end

function CatalogPage:showResumeButton()
	self.playerInstance = LightningPlayer.menu
	self.playerInstance.currentlyPlayingScript:init()				-- must be LuaTable in the IDE
	print('**************Checking hasSaveData')
	local hasSaveData = self.playerInstance.currentlyPlayingScript:hasSaveData()
	print('**************Has Save Data: ' .. tostring(hasSaveData))

	if hasSaveData then
		local saveData = self.playerInstance.currentlyPlayingScript:getSaveData()
		--self:selectItem(saveData.episodeRowPos, saveData.episodeItemPos)
		--local catalogItem = self:getCurrentItemObj()
		local catalogItem = self:elementExists(saveData.episodeRowPos, saveData.episodeItemPos)
		if catalogItem then
			WorldNode_setEnabled(self.resumeButton.worldNode, true)
		else
			WorldNode_setEnabled(self.resumeButton.worldNode, false)	-- save data exists, but the catalog entry not
		end

		-- restore saved language as default
		if (saveData.currentLanguage) then
			local languageTable = self.playerInstance:getLanguageObject()
			languageTable.currentLang = saveData.currentLanguage
		end
	else
		WorldNode_setEnabled(self.resumeButton.worldNode, false)
	end
end

-- Focus the first tile
function CatalogPage:setCurrentItem(row, item)
--	print('CatalogPage:setCurrentItem(' .. row .. ', ' .. item .. ')')
	self.currentRow = row
	self.currentItem = item
end

function CatalogPage:getCurrentItem()
	--print('CatalogPage:getCurrentItem: ' .. row .. ', ' .. item)
	return self.currentRow, self.currentItem
end

---
-- @return int
function CatalogPage:getCurrentEpisode()
	print('CatalogPage:getCurrentEpisode: ' .. self.currentItem)
	return self.currentItem
end

---
-- @return boolean
	function CatalogPage:hasPrevItem()
	local hasPrevItem = self:getPrevItem() ~= nil
	--print(debug.getinfo(1, "n").name .. ': ' .. (hasPrevItem and 'yes' or 'no'))
	return hasPrevItem
end

---
-- @return boolean
function CatalogPage:hasNextItem()
	local hasNextItem = self:getNextItem() ~= nil
	--print(debug.getinfo(1, "n").name .. ': ' .. (hasNextItem and 'yes' or 'no'))
	return hasNextItem
end

---
-- @return CatalogItem
function CatalogPage:getCurrentItemObj()
	local cRow = self.currentRow
	local nItem = self.currentItem
	if self:elementExists(cRow, nItem) then
		return self.catalogItemList[cRow][nItem]
	end
end

function CatalogPage:elementExists(cRow, nItem)
	if self.catalogItemList ~= nil then
		if self.catalogItemList[cRow] ~= nil then
			if self.catalogItemList[cRow][nItem] ~= nil then
				return true
			end
		end
	end
end

---
-- @return CatalogItem
function CatalogPage:getNextItem()
	local cRow = self.currentRow
	local nItem = self.currentItem + 1
	return self.catalogItemList[cRow][nItem]
end

---
-- @return CatalogItem
function CatalogPage:getPrevItem()
	local cRow = self.currentRow
	local nItem = self.currentItem - 1
	return self.catalogItemList[cRow][nItem]
end

--- Focus the first tile
function CatalogPage:selectCurrentItem(animate)
	self:selectItem(self.currentRow, self.currentItem, true, animate)
end

function CatalogPage:selectPrevItem()
	if (self:hasPrevItem()) then
		local ok = self:selectItem(self.currentRow, self.currentItem - 1)
		self.scrollPerChannel[self.currentRow] = self.currentItem
		--var_dump(self.scrollPerChannel)
	else
		print('Can not select prev item.')
	end
end

function CatalogPage:selectNextItem()
	if (self:hasNextItem()) then
		local ok = self:selectItem(self.currentRow, self.currentItem + 1)
		self.scrollPerChannel[self.currentRow] = self.currentItem
		--var_dump(self.scrollPerChannel)
	else
		print('Can not select next item.')
	end
end

function CatalogPage:selectClosestItemInRow(rowIndex)
	local currentItem = self:getCurrentItemObj()
	local rowList = self.rowList[rowIndex]
	if rowList and currentItem then
		local worldX = WorldNode_getWorldPosition(currentItem.worldNode)
		local localX = WorldNode_worldToLocalPosition(rowList.scroll.elements, worldX, 0)
		local itemIndex = math.floor((localX / ITEM_WIDTH) + 0.5) + 1
		itemIndex = Math.clamp(itemIndex, 1, #self.catalogItemList[rowIndex])
		self:selectItem(rowIndex, itemIndex)
	end
end

--- Focus a specific tile
-- @return boolean - was able to select the item or not
function CatalogPage:selectItem(row, item, play_sound, animate)
	if self.catalogItemList ~= nil then
		if self.catalogItemList[row] ~= nil then
			if self.catalogItemList[row][item] ~= nil then
				self.catalogItemList[row][item]:setSelected(true, play_sound)
				self:scrollToItem(row, item, animate)
				self.rowList[row].rowScriptComp:getBackground()
				return true
			else
				return false
			end
		end
	end
	return false
end

-- Scroll to a specific tile
function CatalogPage:scrollToItem(row, item, animate)

	if animate == nil then animate = true end

	self.rowList[row].scroll:stopScroll()
	self.catalogList:stopScroll()

	if self.currentScrollTween then
		TweenManager.manager:stopTween(self.currentScrollTween)
	end

	local catalogItem = self.catalogItemList[row][item]

	local x = WorldNode_getWorldPosition(catalogItem.worldNode)
	local _, y = WorldNode_getWorldPosition(self.rowList[row].worldNode)

	local clickableCenterX, clickableCenterY = ClickableComponent_getCenter(self.catalogList.clickable)
	local clickableWidth, clickableHeight = ClickableComponent_getBoxShapeSize(self.catalogList.clickable)

	local xMin = clickableCenterX - clickableWidth / 2
	local xMax = clickableCenterX + clickableWidth / 2
	local yMin = clickableCenterY - clickableHeight / 2
	local yMax = clickableCenterY + clickableHeight / 2

	-- distances from screen borders
	local left   = (x - ITEM_WIDTH  / 2) - xMin
	local right  = xMax - (x + ITEM_WIDTH  / 2)
	local bottom = (y - ROW_HEIGHT / 2) - yMin
	local top    = yMax - (y + ROW_HEIGHT / 2)

	if left >= 0 and right >= 0 and bottom >= 0 and top >= 0 then
		return -- don't scroll if item is completely in screen
	end

	local scrollX = 0
	local scrollY = 0

	if left < 0 then
		scrollX = -left
	elseif right < 0 then
		scrollX = right
	end

	if bottom < 0 then
		scrollY = -bottom
	elseif top < 0 then
		scrollY = top
	end

	local clampXMin, clampXMax = self.rowList[row].scroll:getBoundaries()
	scrollX = self.rowList[row].scroll:getScrollX() + scrollX / (clampXMax - clampXMin)

	local _, _, clampYMin, clampYMax = self.catalogList:getBoundaries()
	print('scrollY: ' .. scrollY)
	local clampDiff = clampYMax - clampYMin
	if (clampDiff ~= 0) then
		scrollY = self.catalogList:getScrollY() + scrollY / clampDiff
	else
		scrollY = self.catalogList:getScrollY() + scrollY
	end
	print('getScrollY(): ' .. tostring(self.catalogList:getScrollY()))
	print('clampYMax: ' .. clampYMax)
	print('clampYMin: ' .. clampYMin)
	print('scrollY: ' .. scrollY)

	if animate then
		self.scrollTweenDescMapping.scrollXObj = self.rowList[row].scroll
		self.scrollTweenDescMapping.scrollYObj = self.catalogList
		self.scrollTweenDescMapping.scrollX = scrollX
		self.scrollTweenDescMapping.scrollY = scrollY
		self.currentScrollTween = self.scrollTweenDesc:start(self.scrollTweenDescMapping)
	else
		self.rowList[row].scroll:scrollPercentX(scrollX)
		self.catalogList:scrollPercentY(scrollY)
	end
end

--- Functions below don't react on ThumbPad
function CatalogPage:isUp()
	return GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_PAD_UP, GUI.KEY_THRESHOLD)
end

function CatalogPage:isDown()
	return GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_PAD_DOWN, GUI.KEY_THRESHOLD)
end

function CatalogPage:isLeft()
	return GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_PAD_LEFT, GUI.KEY_THRESHOLD)
end

function CatalogPage:isRight()
	return GUI:isControlPressedRepeat(PAD_DEVICE, GAMEPAD_PAD_RIGHT, GUI.KEY_THRESHOLD)
end

--- We know the structure of the catalog and therefore we will handle next/prev/up/down manually
function CatalogPage:update()
	local isOnErrorPage = WorldNode_isEnabled(self.reloadButton)
	if not GUI.disabled and self.active and not LightningPlayer.menu:isAPopupOpen() and not isOnErrorPage then

		--GUI.DEBUG_LEVEL['inputs'] = true
		-- Handle key buttons events
		if self:isLeft() then
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("CP Key left pressed") end
			self:selectPrevItem()
		elseif self:isRight() then
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("CP Key right pressed") end
			self:selectNextItem()
		elseif self:isUp() then
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("CP Key up pressed") end
			self:selectClosestItemInRow(self.currentRow - 1)
		elseif self:isDown() then
			if GUI.DEBUG_LEVEL.inputs then GUI:debugPrint("CP Key down pressed") end
			self:selectClosestItemInRow(self.currentRow + 1)
		elseif GUI:isValidatePressed() then
			if CatalogItem.selected ~= nil then
				GUI:clickElement(CatalogItem.selected.buttonScript)
			end
		elseif GUI:isKeyPressed(PAD_DEVICE, GAMEPAD_Y) then
			GUI:clickElement(self.settingsButton)
		elseif GUI:isKeyPressed(PAD_DEVICE, GAMEPAD_B) then
			self:dumpCatalog()
		end

		-- description scrolling
		local axisY = Input_getState(PAD_DEVICE, GAMEPAD_AXIS_Y)
		if math.abs(axisY) > GUI.AXIS_THRESHOLD then
			self.descriptionScroll:impulse(0, -100 * axisY)
		end


	end
end

function CatalogPage:onButtonClick(button)
	print("clicked button: " .. tostring(button))
	local playerInstance = LightningPlayer.menu
	if button == self.resumeButton then
		self:clickResumeButton()
	elseif button.worldNode == self.reloadButton then
		self:clickReloadButton()
	elseif button == self.settingsButton then
		self:openSettings()
	else
		print('CatalogPage does not handle this button: ' .. WorldNode_getName(button.worldNode))
	end
end

function CatalogPage:openSettings()
	local playerInstance = LightningPlayer.menu
	self.active = false
	WorldNode_setEnabled(self.topDescriptionNode, false)
	playerInstance:switchPage(SETTINGS_PAGE, false)
	playerInstance.settingsTable:setBackPage(CATALOG_PAGE)
	local langPage = playerInstance:getLanguageObject()
	langPage.isFromPlayback = false
end

function CatalogPage:clickResumeButton()
	print('Resume button is clicked')
	local playerInstance = LightningPlayer.menu
	local saveData = self.playerInstance.currentlyPlayingScript:getSaveData()
	self:selectItem(saveData.episodeRowPos, saveData.episodeItemPos, false)
	local catalogItem = self:getCurrentItemObj()
	if catalogItem then
		--check that Parental Control does not prevent the reading of that video
		if playerInstance.isParentalControlRestricted and not catalogItem.availableAllAges then
			--restricted, not playing, jump to Parental Control flow
			coroutine.wrap(LightningPlayer.menu.parentalControlFlow)(LightningPlayer.menu)
		else
			playerInstance:fadeOutBgm()
			catalogItem:triggerPageSwitch()
			if saveData.currentTime > 0 then
				print('Seeing to ' .. tostring(saveData.currentTime))
				local playbackPage = playerInstance:getPlaybackObject()
				VideoComponent_seekAsSeconds(playbackPage.player, saveData.currentTime)
			end
		end
	end -- catalog has changed and doesn't have the entry for the saved episode
end

function CatalogPage:clickReloadButton()
	print('Reload button is clicked')
	--WorldNode_setEnabled(self.reloadButton, false)
	self.playerInstance = LightningPlayer.menu

	-- debug, make first time fail
	--local catalogHandler = self.playerInstance:getCatalogHandler()
	--catalogHandler.serviceUrl = catalogHandler.serviceUrl1	-- dirty hack which should be removed

	self.playerInstance.isFirstFrame = true	 				-- will initiate downloading in update()
end

function CatalogPage:dumpCatalog()
	self2 = {
		scrollPerChannel 	= self.scrollPerChannel,
		active 				= self.active,
		rowList 			= self.rowList,
		scrollXValue		= self.catalogList.scrollXValue,
		scrollYValue		= self.catalogList.scrollYValue,
	}
	var_dump(self2)
end
