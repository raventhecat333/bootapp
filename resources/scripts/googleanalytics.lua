local url = require 'scripts/utils/url.lua'
local guid = require 'scripts/utils/guid.lua'

GoogleAnalytics = class(HttpHelper)

function GoogleAnalytics:start()
	print('GoogleAnalytics:start')
	self.serviceUrl = 'https://www.google-analytics.com/collect'
	self.tid = 'UA-57945472-1'
	self.cid = guid.generate()
	self.version = '1'
	self:httpInit()
	print(TweenState:getISOTime())
	-- https://pki.google.com/GIAG2.crt
	HTTP_addServerCertificateFile(Application_getDataPath('/certificates/GIAG2.crt'))
end

function GoogleAnalytics:update(dt)
end

---
-- @see https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide#page
function GoogleAnalytics:post(category, action, eventLabel, eventValue)
	if not self.serviceUrl then return false end
	local postData = {
		v 		= 1,             							-- Version.
		tid 	= self.tid,  								-- Tracking ID / Property ID.
		cid 	= self.cid,        							-- Anonymous Client ID.
		uip 	= ReedPlayer_GetLocalIPAddress(),			-- IP Address
		ua 		= 'Lightning v' .. self.version,			-- UserAgent
		an 		= 'Lightning',								-- Application Name
		aid 	= 'com.nintendo.lightning',					-- Application ID
		av 		= self.version,								-- Application Version
		t 		= 'event',									-- Hit Type.
		ec 		= category,
		ea 		= action,
		el 		= eventLabel,
		ev 		= eventValue,
	}
	--var_dump(postData, 'postData')
	local postString = self:build_http_query(postData)
	print('GoogleAnalytics:post(' .. self.serviceUrl .. '?' .. postString)
	local httpHeaders = {}
	local result, error = self:httpPost(self.serviceUrl, postString, httpHeaders)
	if error == 0 then
		print('GoogleAnalytics result: ' .. tostring(result))
		return true
	else 
		print('GoogleAnalytics:post(' .. tostring(eventName) .. ') failed with ' .. tostring(error))
		return false
	end
end

---
-- v=1             // Version.
-- &tid=UA-XXXX-Y  // Tracking ID / Property ID.
-- &cid=555        // Anonymous Client ID.

-- &t=pageview     // Pageview hit type.
-- &dh=mydemo.com  // Document hostname.
-- &dp=/home       // Page.
-- &dt=homepage    // Title.
function GoogleAnalytics:postView(page)
	if not self.serviceUrl then return false end
	local postData = {
		v 		= 1,             							-- Version.
		tid 	= self.tid,  								-- Tracking ID / Property ID.
		cid 	= self.cid,        	-- Anonymous Client ID.
		uip 	= ReedPlayer_GetLocalIPAddress(),			-- IP Address
		ua 		= 'Lightning v' .. self.version,			-- UserAgent
		an 		= 'Lightning',								-- Application Name
		aid 	= 'com.nintendo.lightning',					-- Application ID
		av 		= self.version,								-- Application Version
		t 		= 'pageview',								-- Hit Type.
		dp 		= '/' .. page,								-- Page name in case t = 'pageview'
		dt 		= page,
		dh 		= 'front-lightning.nintendo.eu'
	}
	--var_dump(postData, 'postData')
	local postString = self:build_http_query(postData)
	print('GoogleAnalytics:postView(' .. self.serviceUrl .. '?' .. postString)
	local httpHeaders = {}
	local result, error = self:httpPost(self.serviceUrl, postString, httpHeaders)
	if error == 0 then
		print('GoogleAnalytics result: ' .. tostring(result))
		return true
	else 
		print('GoogleAnalytics:postView(' .. tostring(page) .. ') failed with ' .. tostring(error))
		return false
	end
end

function GoogleAnalytics:build_http_query(params) 
	return url.buildQuery(params)
end

function GoogleAnalytics:postAppStart()
	return self:post('Global', 'AppStart')
end

function GoogleAnalytics:postAppQuit()
	coroutine.wrap(self.post)(self, 'Global', 'AppQuit')
end

function GoogleAnalytics:postPageSwitch(pageName)
	coroutine.wrap(self.postView)(self, pageName)
end

function GoogleAnalytics:postSelectEpisode(episodeID)
	coroutine.wrap(self.post)(self, 'Catalog', 'SelectEpisode', 'EpisodeID', episodeID)
end

function GoogleAnalytics:postVideoStart(episodeID)
	coroutine.wrap(self.post)(self, 'Playback', 'VideoStart', 'EpisodeID', episodeID)
end

function GoogleAnalytics:postVideoStop(episodeID)
	coroutine.wrap(self.post)(self, 'Playback', 'VideoStop', 'EpisodeID', episodeID)
end

function GoogleAnalytics:postVideoPause(episodeID)
	--self.post('Playback', 'VideoPause', 'EpisodeID', episodeID)
	coroutine.wrap(self.post)(self, 'Playback', 'VideoPause', 'EpisodeID', episodeID)
end

function GoogleAnalytics:postVideoResume(episodeID)
	coroutine.wrap(self.post)(self, 'Playback', 'VideoResume', 'EpisodeID', episodeID)
end
