local url = require 'scripts/utils/url.lua'
local guid = require 'scripts/utils/guid.lua'

PushHit = class(HttpHelper)

function PushHit:start()
	print('PushHit:start')
	self:httpInit()
	self.serviceUrl = LightningPlayer.menu:getCatalogHandler().serviceUrl
	self.guid = tostring(Application_getPrincipalID())
end

function PushHit:update(dt)
end

---
-- @see https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide#page
function PushHit:post(category, action, eventLabel, eventValue)
	return nil
end

function PushHit:neverUsed(category, action, eventLabel, eventValue)
	print('PushHit:post(' .. self.serviceUrl .. ')')
	if not self.serviceUrl then return false end
	local postData = {
		principalID 		= self.guid,
		ip 					= ReedPlayer_GetLocalIPAddress(),			-- IP Address
		ec 					= category,
		ea 					= action,
		el 					= eventLabel,
		ev 					= eventValue,
		clientTime			= TweenState:getISOTime()
	}
	var_dump(postData, 'postData')
	--local postString = jsonEncode(postData)
	postString = LightningPlayer.menu:getCatalogHandler():encodeMOPPMessage({}, {{
		pushHit = postData
	}})
	--print(postString)

	local serviceToken = LightningPlayer.menu:getCatalogHandler().serviceToken

	if serviceToken ~= nil and serviceToken > '' then
		local httpHeaders = {
			['Content-Type'] = "vnd.nerd.nppmessage+json",
			['X-Service-Token'] = serviceToken
		}
		var_dump(httpHeaders)
		local result, error = self:httpPost(self.serviceUrl, postString, httpHeaders)
		if error == 0 then
			print('PushHit result: ' .. tostring(result))
			local json = jsonDecode(result)
			if json ~= nil then
				var_dump(json)
			end
			return true
		else
			print('PushHit:post(' .. tostring(eventName) .. ') failed with ' .. tostring(error))
			return false
		end
	end
end

function PushHit:postAppStart()
	return self:post('Global', 'AppStart')
end

function PushHit:postAppQuit()
	coroutine.wrap(self.post)(self, 'Global', 'AppQuit')
end

function PushHit:postPageSwitch(pageName)
	coroutine.wrap(self.post)(self, 'PageSwitch', 'PageSwitch', 'PageName', pageName)
end

function PushHit:postSelectEpisode(episodeID)
	coroutine.wrap(self.post)(self, 'Catalog', 'SelectEpisode', 'EpisodeID', episodeID)
end

function PushHit:postVideoStart(episodeID)
	coroutine.wrap(self.post)(self, 'Playback', 'VideoStart', 'EpisodeID', episodeID)
end

function PushHit:postVideoStop(episodeID)
	coroutine.wrap(self.post)(self, 'Playback', 'VideoStop', 'EpisodeID', episodeID)
end

function PushHit:postVideoPause(episodeID)
	coroutine.wrap(self.post)(self, 'Playback', 'VideoPause', 'EpisodeID', episodeID)
end

function PushHit:postVideoResume(episodeID)
	coroutine.wrap(self.post)(self, 'Playback', 'VideoResume', 'EpisodeID', episodeID)
end
