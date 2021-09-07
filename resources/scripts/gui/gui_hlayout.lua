require 'gui_layout.lua'

local MathHuge = math.huge

GUIHLayout = class(GUILayout)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUIHLayout:refresh()
	local xMin = MathHuge
	local xMax = -MathHuge
	local yMin = MathHuge
	local yMax = -MathHuge
	
	local nodesIndexes = self.nodesIndexes
	local nodeCount = #nodesIndexes
	
	local currentGridX = 0
	local currentGridY = 0

	local columnsCount = self.columnsCount
	
	-- reset all infos
	self.rowInfos = {}
	self.columnInfos = {}
	
	local row = 1
	local column = 1
	
	local rowInfo = { height = 0, posY = 0 }
	self.rowInfos[row] = rowInfo
	
	-- First loop to determine boundaries
	for i = 1, nodeCount do
		local nodeInfo = nodesIndexes[i]
		
		local nodeLeft = nodeInfo.width * nodeInfo.centerX
		local nodeUp = nodeInfo.height * nodeInfo.centerY
		
		if i == 1 then
			currentGridX = -nodeLeft
			currentGridY = nodeUp
		end

		local columnInfo = { width = nodeInfo.width, posX = currentGridX + nodeLeft }
		self.columnInfos[column] = columnInfo
		
		local posX = columnInfo.posX
		local posY = rowInfo.posY

		nodeInfo.posX = posX
		nodeInfo.posY = posY
		
		WorldNode_setLocalPosition(nodeInfo.node, posX, posY)
		
		local nodeMinX = currentGridX
		local nodeMaxY = currentGridY
		local nodeMaxX = nodeMinX + nodeInfo.width
		local nodeMinY = nodeMaxY - nodeInfo.height
		
		if nodeMinX < xMin then
			xMin = nodeMinX
		end
		if nodeMaxX > xMax then
			xMax = nodeMaxX
		end
		if nodeMinY < yMin then
			yMin = nodeMinY
		end
		if nodeMaxY > yMax then
			yMax = nodeMaxY
		end
		
		if nodeInfo.width > columnInfo.width then
			columnInfo.width = nodeInfo.width
		end

		column = column + 1
		currentGridX = currentGridX + columnInfo.width

	end
	
	self.xMin = xMin
	self.xMax = xMax
	self.yMin = yMin
	self.yMax = yMax
end


