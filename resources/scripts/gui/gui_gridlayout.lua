require 'scripts/core/core.lua'

GUIGridLayout = class()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUIGridLayout:initialize()
	self.nodes = {}
	self.nodesIndexes = {}
	
	self.columnsInfos = {}
	self.rowInfos = {}
	
	self.xMin = math.huge
	self.xMax = -math.huge
	self.yMin = math.huge
	self.yMax = -math.huge
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUIGridLayout:pushbackElement(layoutElement)
	
	local index = #self.nodesIndexes + 1
	local nodeInfo = { node = _node, index = index, width = _width, height = _height, centerX = _centerX, centerY = _centerY }
	self.nodes[_node] = nodeInfo
	table.insert(self.nodesIndexes, nodeInfo )
	
	if REED_DEBUG then
		self:checkConsistency()
	end
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUIGridLayout:insertElement(layoutElement, posX, posY)
	
	local nodeInfo = { node = _node, index = _index, width = _width, height = _height, centerX = _centerX, centerY = _centerY }
	self.nodes[_node] = nodeInfo
	table.insert(self.nodesIndexes, _index, nodeInfo )
	
	for i=_index+1, #self.nodesIndexes do
		self.nodesIndexes[i].index = self.nodesIndexes[i].index + 1
	end
	
	if REED_DEBUG then
		self:checkConsistency()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUIGridLayout:removeByIndex(nodeIndex)
	local node = self.nodesIndexes[nodeIndex].node
	self.nodes[node] = nil
	table.remove(self.nodesIndexes, nodeIndex)

	for i=nodeIndex, #self.nodesIndexes do
		self.nodesIndexes[i].index = self.nodesIndexes[i].index - 1
	end
	
	if REED_DEBUG then
		self:checkConsistency()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUIGridLayout:removeElement(element)
	local nodeInfo = self.nodes[node]
	if not nodeInfo then
		GUI:error("[" .. tostring(self) .. "]\tGUIScroll:removeNode() : node does not exist in the nodes list")
		return
	end
	
	self:removeByIndex(nodeInfo.index)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUIGridLayout:refresh()

	local xMin = 0
	local xMax = -math.huge
	local yMin = 0
	local yMax = -math.huge
	
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
	
	-- First loop to determine boundaries
	for i = 1, nodeCount do
		local nodeInfo = nodesIndexes[i]
		

		local rowInfo = self.rowInfos[row]
		local columnInfo = self.columnInfos[column]
		
		if not columnInfo then
			columnInfo = { width = 0, posX = 0 }
			self.columnInfos[column] = columnInfo
		end

		if not rowInfo then
			rowInfo = { height = 0, posY = 0 }
			self.rowInfos[row] = rowInfo
		end

		local nodePosX = nodeInfo.width * nodeInfo.centerX + currentGridX
		local nodePosY = nodeInfo.height * nodeInfo.centerY +  currentGridY
		
		if nodePosX > columnInfo.posX then
			columnInfo.posX = nodePosX
		end
		if nodePosY > rowInfo.posY then
			rowInfo.posY = nodePosY
		end

		local columnMaxX = columnInfo.posX + nodeInfo.width * (1 - nodeInfo.centerX) - currentGridX
		local rowMaxY = rowInfo.posY + nodeInfo.height * (1 - nodeInfo.centerY) - currentGridY
		
		if columnMaxX > columnInfo.width then
			columnInfo.width = columnMaxX
		end
		if rowMaxY > rowInfo.height then
			rowInfo.height = rowMaxY
		end
		
		column = column + 1
		currentGridX = currentGridX + columnInfo.width
		
		-- next row
		if column > columnsCount then
			xMax = currentGridX
			column = 1
			currentGridX = 0
			row = row + 1
			currentGridY = currentGridY + rowInfo.height
		end
		
	end
	
	yMax = currentGridY
	
	row = 1
	column = 1
	
	-- Second loop to set elements position
	for i = 1, nodeCount do
		local nodeInfo = nodesIndexes[i]
		
		local posX = self.columnInfos[column].posX 
		local posY = self.rowInfos[row].posY
		
		nodeInfo.posX = posX
	 	nodeInfo.posY = posY
	 	WorldNode_setLocalPosition(nodeInfo.node, posX, posY)
	
		column = column + 1

		-- next row
		if column > columnsCount then
			column = 1
			row = row + 1
		end
	end

	self.xMin = xMin
	self.xMax = xMax
	self.yMin = yMin
	self.yMax = yMax
end
