local showMyIcon = true
local drawDistance = 1000
local chatIconFor = {}

local screenSizex, screenSizey = guiGetScreenSize()
local globalscale = 1
local globalalpha = .85

local function chatCheckPulse()
	local chatState = isChatBoxInputActive() or isConsoleActive()
	if chatState == localPlayer:getData("ChatIcon:Chatting") then
		return
	end
	localPlayer:setData("ChatIcon:Chatting", chatState)
end

addEventHandler("onClientResourceStart", resourceRoot,
	function()
		setTimer(chatCheckPulse, 200, 0)
	end
)

local function showTextIcon()
	local x, y, z = getElementPosition(localPlayer)

	for _, player in ipairs(getElementsWithinRange(x, y, z, 300, "player")) do
		if ((player == localPlayer and showMyIcon) or player ~= localPlayer) and player:getData("ChatIcon:Chatting") then
			if not isElement(chatIconFor[player]) then
				chatIconFor[player] = guiCreateStaticImage(0, 0, 0, 0, "chat/chat.png", false) -- change to "chat2.png" to use the included, modern icon
			end
			local x2, y2, z2 = getPedBonePosition(player, 6)
			local clear = isLineOfSightClear(x, y, z, x2, y2, z2, true, false, false, true)
			local sw, sh, dist = getScreenFromWorldPosition(x2, y2, z2 + 0.08)
			if sw and sh and dist and clear and dist < drawDistance then
				local scaled = screenSizex * (1 / (2 * (dist + 5))) * .85
				local relx, rely = scaled * globalscale, scaled * globalscale
				guiSetPosition(chatIconFor[player], sw - relx / 2, sh - rely, false)
				guiSetSize(chatIconFor[player], relx, rely, false)
				guiSetAlpha(chatIconFor[player], globalalpha)
				guiSetVisible(chatIconFor[player], true)
			else
				guiSetVisible(chatIconFor[player], false)
			end
		elseif isElement(chatIconFor[player]) then
			chatIconFor[player]:destroy()
			chatIconFor[player] = nil
		end
	end
end
addEventHandler("onClientRender", getRootElement(), showTextIcon)

local function toggleIcon()
	showMyIcon = not showMyIcon
	outputChatBox("Your icon is " .. (showMyIcon and "" or "in") .. "visible!", (showMyIcon and 0 or 255), (showMyIcon and 255 or 0), 0)
end
addCommandHandler("toggleicon", toggleIcon, false)

local function resizeIcon(command, newSize)
	if tonumber(newSize) then
		globalscale = tonumber(newSize) / 100
	end
	outputChatBox("Chat icons are " .. (globalscale * 100) .. "% normal size")
end
addCommandHandler("resizeicon", resizeIcon, false)

local function setIconAlpha(command, newSize)
	if tonumber(newSize) then
		globalalpha = tonumber(newSize) / 100
	end
	outputChatBox("Chat icons are " .. (globalalpha * 100) .. "% visible")
end
addCommandHandler("seticonvis", setIconAlpha, false)

local function removeChatIcon()
	if getElementType(source) ~= "player" then
		return
	end

	if isElement(chatIconFor[source]) then
		chatIconFor[source]:destroy()
		chatIconFor[source] = nil
	end
end
addEventHandler("onClientElementStreamOut", getRootElement(), removeChatIcon)
addEventHandler("onClientPlayerQuit", getRootElement(), removeChatIcon)