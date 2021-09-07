require 'scripts/helpers/httphelper.lua'

CatalogRow = class(HttpHelper)

CatalogRow.imageMetaData = { CTR = { region = "FCRAM" } }

-- Callback when object is added to the world
function CatalogRow:start()
	print('CatalogRow:start()')
end

-- Callback when object is removed from the world
function CatalogRow:stop()
	print('CatalogRow:stop()')
end


--------------------------------------------------------------------------------
-- Backgrond download
--------------------------------------------------------------------------------

-- Register the background sprite
function CatalogRow:initialize(row, backgroundSprite, url)
	self.row = row
	self:httpInit()
	self.backgroundSprite = backgroundSprite
	self.mustShowSprite = false
	self.url = url
	self.lastUrl = nil
end

-- Download and display this thumbnail
function CatalogRow:getBackground()
	--print('CatalogRow:getBackground(' .. tostring(self.row) .. ')')
	
	if self.resource == nil or self.lastUrl ~= self.url then
		self.resource = getImageFromPathAdvanced(self.url, {},  CatalogRow.imageMetaData)
		ResourceHandle_link(self.resource)
		self.lastUrl = self.url
		print('CatalogRow:getBackground() linking ' .. self.url)
	end

	self.mustShowSprite = true
end

-- Callback called every frames
function CatalogRow:update(dt)
	if self.mustShowSprite == true and self.resource ~= nil and ResourceHandle_isLoaded(self.resource) == true then
		--print('CatalogRow:update(' .. tostring(self.row) .. '), setting background')
		Component_enable(self.backgroundSprite)
		TextureComponent_setTexture(self.backgroundSprite, self.resource)
		self.mustShowSprite = false
	end
end

