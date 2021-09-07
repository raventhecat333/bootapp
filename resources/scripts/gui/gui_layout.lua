require 'scripts/core/core.lua'

GUILayout = class()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUILayout:initialize()
	self.nodes = {}
	self.nodesIndexes = {}
	
	self.columnsInfos = {}
	self.rowInfos = {}
	
	self.xMin = math.huge
	self.xMax = -math.huge
	self.yMin = math.huge
	self.yMax = -math.huge

end

function GUILayout:getWidth()
	return self.xMax - self.xMin
end

function GUILayout:getHeight()
	return self.yMax - self.yMin
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUILayout:suspend()
	self.refreshSuspended = true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUILayout:resume()
	self.refreshSuspended = false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUILayout:setElementSize(element, width, height)
	local nodeInfo = self.nodes[element]
	
	if not nodeInfo then
		GUI:error("[" .. tostring(self) .. "]\tGUILayout:setElementSize() : node does not exist in the nodes list")
		return
	end
	
	nodeInfo.width = width
	nodeInfo.height = height

	if not self.refreshSuspended then
		self:refresh()
	end
	
end
	
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUILayout:pushBackElement(element, width, height, centerX, centerY)
	
	local index = #self.nodesIndexes + 1
	local nodeInfo = { node = element, index = index, width = width, height = height, centerX = centerX, centerY = centerY }
	self.nodes[element] = nodeInfo
	table.insert(self.nodesIndexes, nodeInfo )
	
	if REED_DEBUG then
		self:checkConsistency()
	end
	
	if not self.refreshSuspended then
		self:refresh()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUILayout:insertElement(index, element, width, height, centerX, centerY)
	
	local nodeInfo = { node = element, index = index, width = width, height = height, centerX = centerX, centerY = centerY }
	self.nodes[element] = nodeInfo
	table.insert(self.nodesIndexes, _index, nodeInfo )
	
	for i=_index+1, #self.nodesIndexes do
		self.nodesIndexes[i].index = self.nodesIndexes[i].index + 1
	end
	
	if REED_DEBUG then
		self:checkConsistency()
	end
	
	if not self.refreshSuspended then
		self:refresh()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUILayout:removeByIndex(nodeIndex)
	local node = self.nodesIndexes[nodeIndex].node
	self.nodes[node] = nil
	table.remove(self.nodesIndexes, nodeIndex)

	for i=nodeIndex, #self.nodesIndexes do
		self.nodesIndexes[i].index = self.nodesIndexes[i].index - 1
	end
	
	if REED_DEBUG then
		self:checkConsistency()
	end
	
	if not self.refreshSuspended then
		self:refresh()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUILayout:removeElement(element)
	local nodeInfo = self.nodes[node]
	if not nodeInfo then
		GUI:error("[" .. tostring(self) .. "]\tGUILayout:removeElement() : element does not exist in the elements list")
		return
	end
	
	self:removeByIndex(nodeInfo.index)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function GUILayout:clear()
	self.nodes = {}
	self.nodesIndexes = {}
end

if REED_DEBUG then
--------------------------------------------------------------------------------
-- checkConsistency
--! @brief Checks the consistency of the internal lists
--------------------------------------------------------------------------------
	function GUILayout:checkConsistency()
		for i=1, #self.nodesIndexes do
			if self.nodesIndexes[i].index ~= i then
				GUI:error("[" .. tostring(self) .. "]\tGUIScroll:checkConsistency() failed at index ".. tostring(i) .. " ;currentIndex = " .. self.nodesIndexes[i].index)
				return
			end
		end
	end
end
