local URL = "https://ffs.gg/threads/104304"
local PREFIX = "[PTP MA] "
local updateIsInstalled = false

--[[addEvent("sendUrl", true)
addEventHandler("sendUrl", resourceRoot, function()
	triggerClientEvent("receiveUrl", resourceRoot, URL)
end)]]

function string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = tonumber(c) end) -- added tonumber()
   return fields
end


local function sendVersionInfo(calledByUser)
	triggerClientEvent("receiveVersionInfo", resourceRoot, getResourceInfo(resource, "version"), calledByUser)
end

local function onUpdateDownloadComplete(responsData, code)
	if code > 0 then
		outputChatBox( PREFIX .. "#ff0000Error while downloading the update! Please contact#878787 JessePinkman#5156 #ff0000on #7289DADiscord", root, 255, 100, 100, true)
		return
	end

	outputChatBox( PREFIX .. "#ffffffInstalling...", root, 255,100,100, true )

	local meta = zzlib.unzip(responsData, "meta.xml")
	local metaFile = fileCreate("updater/temp/meta.xml")
    fileWrite(metaFile, meta)
    fileClose(metaFile)
    

    local metaXML = xmlLoadFile("updater/temp/meta.xml", true)
    local metaNodes = xmlNodeGetChildren(metaXML)
    local files = {}
    for i,node in ipairs(metaNodes) do
    	local nodeName = xmlNodeGetName(node)
    	if nodeName == "file" or nodeName == "script" then
    		local filePath = xmlNodeGetAttribute(node, "src")
        	table.insert(files, {path = filePath, name = string.match(filePath, ".-/?(.+)")})
        end
    end
    xmlUnloadFile(metaXML)

    for i=1, #files do
    	local fileName, filePath = files[i].name, files[i].path
    	local fileData = zzlib.unzip(responsData, filePath)
    	local file = fileCreate("updater/temp/" .. fileName)
	    fileWrite(file, fileData)
	    fileClose(file)
	    if fileExists(filePath) then
		    fileCopy(filePath, "updater/backup/" .. filePath, true)
		end
		fileCopy("updater/temp/" .. fileName, filePath, true)
	    fileDelete("updater/temp/" .. fileName)
    end
    fileCopy("meta.xml", "updater/backup/meta.xml", true)
    fileCopy("updater/temp/meta.xml", "meta.xml", true)
    fileDelete("updater/temp/meta.xml")

	outputChatBox( PREFIX .. "#ffffffUpdate is installed! Type#878787 /restart " .. getResourceName(getThisResource()) .. "#ffffff to apply changes. For more info visit #878787" .. URL, root, 255,100,100, true )
	updateIsInstalled = true
end

local function downloadUpdate()
	outputChatBox( PREFIX .. "#ffffffDownloading the update...", root, 255,100,100, true )
	fetchRemote(URL, function (responsData, code)
		local _, mainPost = string.find(responsData, "post_message_")
		-- ( ) . % + - * ? [ ^ $                                         ! * ' ( ) ; : @ & = + $ , / ? % # [ ]
		local downloadLink = string.match(responsData, '<a href="(http[%w%-_%.~!%*\'%(%);:@&=%+$,/%?%%#%[%]"]-)" target="_blank">%d%.%d.%d</a>', mainPost)
		fetchRemote(downloadLink, onUpdateDownloadComplete)
	end)
end

local function checkVersion(calledByUser)
	fetchRemote(URL, function(responsData, code)
		if code > 0 then
			if calledByUser then 
				outputChatBox( PREFIX .. "#ff0000Error while checking for updates! Check internet connection or contact#878787 JessePinkman#5156 #ff0000on #7289DADiscord", root, 255, 100, 100, true)
			end
			return
		end
		local _, mainPost = string.find(responsData, "post_message_")
		local actualVersion = string.match(responsData, 'target="_blank">(%d%.%d.%d)</a>', mainPost)

		local actualVersion = actualVersion:split(".")
		local currentVersion = getResourceInfo(resource, "version"):split(".")

	    --print("actualVersion:", inspect(actualVersion))
	    --print("currentVersion: ", inspect(currentVersion))
	    if actualVersion[3] > currentVersion[3] or actualVersion[2] > currentVersion[2] or actualVersion[1] > currentVersion[1] then
	    	if calledByUser then
	    		outputChatBox( PREFIX .. "#ffffffUpdate found", root, 255,100,100, true )
	    		downloadUpdate()
	    	else
	    		outputChatBox( PREFIX .. "#ffffffUpdate is available! Type #878787/pma#ff6666update #ffffffto install it. Visit #878787" .. URL .. " #fffffffor more info", root, 255,100,100, true )
	    	end
	    else
	    	if calledByUser then
	    		outputChatBox( PREFIX .. "#ffffffNo updates found", root, 255,100,100, true )
	    	end
	    end	
	end)
end

local function initChecks(calledByUser)
	if updateIsInstalled then return end
	if hasObjectPermissionTo(resource, "function.fetchRemote") then
		checkVersion(calledByUser)
	else
		sendVersionInfo(calledByUser)
	end
end

function update(player)
	--[[if not hasObjectPermissionTo(player, "ptpupdater.update") then
		outputChatBox( PREFIX .. "#ff0000You don't have permission to do so!", root, 255, 100, 100, true)
		return
	end]]

	if updateIsInstalled then
		outputChatBox( PREFIX .. "#ffffffResource is already updated! Type#878787 /restart " .. getResourceName(getThisResource()) .. "#ffffff to apply changes", root, 255,100,100, true )
		return
	end
	local calledByUser = player and getElementType(player) == "player"
	if calledByUser then
		outputChatBox( PREFIX .. "#ffffffChecking for updates...", root, 255,100,100, true )
	end
	initChecks(calledByUser)
end

local function init()
	addCommandHandler("pmaupdate", update)
	setTimer(initChecks, 5000, 1)
	setTimer(initChecks, 300000, 0)

	--[[if fileExists("updater/updatelink") then
		local linkFile = fileOpen("updater/updatelink")
	    local count = fileGetSize(linkFile)
	    local link = fileRead(linkFile, count)
	    fileClose(linkFile)
		
		if not string.find(link, "http.+") then
			outputChatBox( PREFIX .. "#ff0000Error while initializing the updater! Make sure you didn't edit #ffffffupdatelink #ff0000file", root, 255, 100, 100, true)
			return
		end
		URL = link
		addCommandHandler("pmaupdate", update)
		setTimer(initChecks, 5000, 1)
		setTimer(initChecks, 300000, 0)
	else
		outputChatBox( PREFIX .. "#ff0000Error while initializing the updater! Make sure you didn't remove #ffffffupdatelink #ff0000file", root, 255, 100, 100, true)
	end]]
end
init()


