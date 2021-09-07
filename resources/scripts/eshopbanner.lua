require 'scripts/core/core.lua'
require 'scripts/helpers/httphelper.lua'

--------------------------------------------------------------------------------
-- Main eShopBanner data
--------------------------------------------------------------------------------
--! @class eShopBanner
--! @variable {Component} 	sprite 

eShopBanner = class(HttpHelper)

eShopBanner.imageMetaData = { CTR = { region = "FCRAM" } }

function eShopBanner:start()
	self:httpInit()
	self.oldResources = {} 
end


--------------------------------------------------------------------------------
-- Clicked
--------------------------------------------------------------------------------

-- Set the data to download
function eShopBanner:setData(imageUrl, eshopId)
	print("eShopBanner:setData(" .. tostring(imageUrl) .. ', ' .. tostring(eshopId) .. ')')
	self.imageUrl = imageUrl
	self.eshopId = eshopId

	if imageUrl ~= nil then
		self.loadCoroutine = coroutine.wrap(eShopBanner.loadImage)
		self:loadCoroutine(imageUrl)
	end
end

function eShopBanner:loadImage(url)
	-- load the resource
	local resource = getImageFromPathAdvanced(url, {}, eShopBanner.imageMetaData)
	ResourceHandle_link(resource)
	self.oldResources[url] = resource
	
	Component_disable(self.sprite)

	-- wait for the resource to be loaded
	while ResourceHandle_isLoading(resource) do
		coroutine.yield()
	end

	if ResourceHandle_isLoaded(resource) then
		TextureComponent_setTexture(self.sprite, resource)
		Component_enable(self.sprite)
		
		-- Fade in nicely
		VisualComponent_setAlpha(self.sprite, 0)
		Tween:animate(self.sprite, 0.2, "to", { alpha = 1 }, Ease.linear):start()
		
		
	else
		print('eShopBanner:loadImage(), failed to load image ' .. url)
	end

	self.loadCoroutine = nil
end

-- Update the resource state
function eShopBanner:update()
	if self.loadCoroutine ~= nil then
		self:loadCoroutine()
	end
end
