require 'scripts/core/core.lua'

HttpHelper = class()

function HttpHelper:httpInit()
	self.httpRequestsWaiting = {}
	self.httpRequestsUniqueId = 0
end

function HttpHelper:httpDownload(url, headers)
	if headers == nil then
		headers = {}
	end

	local currentCoroutine = coroutine.running()
	if not currentCoroutine then
		error('Cannot call httpDownload from the main thread! You have to use it inside a coroutine.')
	end

	self.httpRequestsWaiting[self.httpRequestsUniqueId] = currentCoroutine
	HTTP_download(url, self._ptr, self.httpRequestsUniqueId, headers)
	self.httpRequestsUniqueId = self.httpRequestsUniqueId + 1
	return coroutine.yield()
end

function HttpHelper:httpGet(url, headers, cached)
	if headers == nil then
		headers = {}
	end
	
	if cached == nil then
		cached = false
	end

	local currentCoroutine = coroutine.running()
	if not currentCoroutine then
		error('Cannot call httpGet from the main thread! You have to use it inside a coroutine.')
	end
	self.httpRequestsWaiting[self.httpRequestsUniqueId] = currentCoroutine
	HTTP_get(url, self._ptr, self.httpRequestsUniqueId, headers, cached)
	self.httpRequestsUniqueId = self.httpRequestsUniqueId + 1
	return coroutine.yield()
end

function HttpHelper:httpPost(url, postData, headers, cached)
	if headers == nil then
		headers = {}
	end

	if postData == nil then
		postData = ""
	end
	
	if cached == nil then
		cached = false
	end

	local currentCoroutine = coroutine.running()
	if not currentCoroutine then
		error('Cannot call httpPost from the main thread! You have to use it inside a coroutine.')
	end
	self.httpRequestsWaiting[self.httpRequestsUniqueId] = currentCoroutine
	HTTP_post(url, self._ptr, self.httpRequestsUniqueId, headers, postData, cached)
	self.httpRequestsUniqueId = self.httpRequestsUniqueId + 1
	return coroutine.yield()
end

function HttpHelper:onHttpRequestResult(identifier, errorCode, response)
	local status, errCode = coroutine.resume(self.httpRequestsWaiting[identifier], response, errorCode)
	if status == false then
		error(tostring(errCode))
	end
	self.httpRequestsWaiting[identifier] = nil
end
