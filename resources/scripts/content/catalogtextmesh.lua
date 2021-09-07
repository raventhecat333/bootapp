require 'core/core.lua'

--------------------------------------------------------------------------------
--! @brief CatalogTextMesh Object script
--! @class CatalogTextMesh
--! @variable {LinkedResource} renderTarget The render target texture to use.
--------------------------------------------------------------------------------

CatalogTextMesh = class()

local function strip(width, height, y0, y1, topColor, botColor)
	local topY = y0 * height
	local botY = y1 * height
	return {
		    0, topY, topColor, topColor, topColor, topColor, 0, 1-y0,
		width, topY, topColor, topColor, topColor, topColor, 1, 1-y0,
		    0, botY, botColor, botColor, botColor, botColor, 0, 1-y1,
		
		    0, botY, botColor, botColor, botColor, botColor, 0, 1-y1,
		width, topY, topColor, topColor, topColor, topColor, 1, 1-y0,
		width, botY, botColor, botColor, botColor, botColor, 1, 1-y1
	}
end

--! @brief Callback when object is added to the world
function CatalogTextMesh:start()
	local mesh = addNewComponentToNode(self.worldNode, COMPONENT_TYPE_MESH)
	MeshComponent_setTexture(mesh, self.renderTarget)
	VisualComponent_setZIndex(mesh, 20)
	VisualComponent_setBlendPreset(mesh, BLEND_PREMULTIPLY)
	
	local w, h = 400, 130
	local margin = 0.1
	local vertices = {}
	for _, x in ipairs(strip(w, h, 0, margin, 0, 1)) do
		vertices[#vertices + 1] = x
	end
	for _, x in ipairs(strip(w, h, margin, 1 - margin, 1, 1)) do
		vertices[#vertices + 1] = x
	end
	for _, x in ipairs(strip(w, h, 1 - margin, 1, 1, 0)) do
		vertices[#vertices + 1] = x
	end
	
	MeshComponent_setTriangles(mesh, vertices);
end
