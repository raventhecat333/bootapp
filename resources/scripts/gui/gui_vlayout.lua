require 'gui_layout.lua'

local MathHuge = math.huge

GUIVLayout = class(GUILayout)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUIVLayout:refresh()
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
	if not self.rowInfos or #self.rowInfos ~= nodeCount then
		self.rowInfos = {}
	end
	
	if not self.columnInfos then
		self.columnInfos = {}
	end
	
	local row = 1
	local column = 1
	
	local columnInfo = self.columnInfos[column] or {}
	columnInfo.width = 0
	columnInfo.posX = 0
	self.columnInfos[column] = columnInfo
	
	-- First loop to determine boundaries
	for i = 1, nodeCount do
		local nodeInfo = nodesIndexes[i]
		
		local nodeLeft = nodeInfo.width * nodeInfo.centerX
		local nodeUp = nodeInfo.height * nodeInfo.centerY
		
		if i == 1 then
			currentGridX = -nodeLeft
			currentGridY = nodeUp
		end

		local rowInfo = self.rowInfos[row] or {}
		rowInfo.height = nodeInfo.height
		rowInfo.posY = currentGridY - nodeUp
		self.rowInfos[row] = rowInfo

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

		row = row + 1
		currentGridY = currentGridY - rowInfo.height

	end
	
	self.xMin = xMin
	self.xMax = xMax
	self.yMin = yMin
	self.yMax = yMax
end


