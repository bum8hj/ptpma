local URL = "https://ffs.gg/threads/104304"
local PREFIX = "[PTP MA] "


function string:split(sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = tonumber(c) end) -- added tonumber()
	return fields
end

local function checkVersion(responsData, code, currentVersion, calledByUser)
	if code > 0 then
		if calledByUser then
			outputChatBox( PREFIX .. "#ff0000Error while checking for updates! Check internet connection or contact#878787 JessePinkman#5156 #ff0000on #7289DADiscord", 255, 100, 100, true)
		end
		return
	end

	local _, mainPost = string.find(responsData, "post_message_")
	local actualVersion = string.match(responsData, 'target="_blank">(%d%.%d.%d)</a>', mainPost)

	local actualVersion = actualVersion:split(".")
	local currentVersion = currentVersion:split(".")

	--print("actualVersion:", inspect(actualVersion))
	--print("currentVersion: ", inspect(currentVersion))
	if actualVersion[3] > currentVersion[3] or actualVersion[2] > currentVersion[2] or actualVersion[1] > currentVersion[1] then
		outputChatBox( PREFIX .. "#ffffffThere is an update! Visit #878787" .. URL .. " #fffffffor more info", 255,100,100, true )
		outputChatBox( PREFIX .. "#ffffffTo allow auto-downloading the latest version, enter the following in the console window:", 255,100,100, true )
		outputChatBox( "aclrequest allow " .. getResourceName(getThisResource()) .. " function.fetchRemote", 255,100,100, true )
	else
		if calledByUser then
			outputChatBox( PREFIX .. "#ffffffNo updates found", 255,100,100, true )
		end
	end
end

addEvent("receiveVersionInfo", true)
addEventHandler("receiveVersionInfo", resourceRoot, function(currentVersion, calledByUser)
	fetchRemote(URL, checkVersion, nil, nil, currentVersion, calledByUser)
end)

--[[addEvent("receiveUrl", true)
addEventHandler("receiveUrl", resourceRoot, function(url)
	URL = url
end)

local function init()
	triggerServerEvent("sendUrl", resourceRoot)
end


addEventHandler("onClientResourceStart", resourceRoot, function()
	init()
end)]]