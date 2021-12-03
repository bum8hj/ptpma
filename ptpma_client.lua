
-- ui variables --
local screenX_dev = 1600
local screenY_dev = 900

local screenX, screenY = guiGetScreenSize()

local scaleValue = screenY / screenY_dev
scaleValue = math.max(scaleValue, 0.65) -- minimum scaleValue

setDevelopmentMode(true)

function removeHex(s)
    return s:gsub ("#%x%x%x%x%x%x", "") or false
end

local PREFIX = "[PTP MA]"

-- useful commands --
local commandList = {
    {"update"      , "download and install updates"},
    {"testmap"     , "test your map"},
    {"bunker"      , "mark a map as bunker"},
    {"notbunker"   , "mark a map as not bunker"},
    {"spawn"       , "re-spawn your player"},
    {"examine"     , "output info on elements you double-click"},
    {"consoledebug", "show debug messages in the console"},
    {"call"        , "call a player's cellphone"},
    {"interior"    , "set your interior"},
    {"contact"     , "who to contact and how"},
}

-- disable them when F2 is open --
local mainControls = {
    "fire", "aim_weapon", "next_weapon", "previous_weapon", "forwards",
    "backwards", "left", "right", "change_camera", "jump", "sprint", "look_behind",
    "crouch", "action", "walk"
}

-- ptp teams --
local IDtoTeam = { "President", "Secret Service", "Police", "Terrorists", "Civilians", "Medics" }
local teamList = {
    ["President"]      = {255, 255, 0},
    ["Secret Service"] = {0, 30, 200},
    ["Police"]         = {0, 170, 255},
    ["Terrorists"]     = {200, 0, 0},
    ["Civilians"]      = {255, 255, 255},
    ["Medics"]         = {0, 255, 0},
}

-- team variables --
local teamID = 1
local teamName = IDtoTeam[teamID]
local team = getTeamFromName(teamName)

-- other variables --
local inSpawnSelection = false
local spawnSelectionPed = nil
local spawn = {
    x = 2000.58,
    y = 1565.85,
    z = 15.34,
}

addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), function()
    -- welcome message --
    outputChatBox("------", 255,100,100, true)
    outputChatBox("PTP Mapping Assistant#ffffff by #878787JessePinkman #ff6666& #878787ApeLsiN4eG", 255,100,100, true)
    outputChatBox("Use #878787/pma#ff6666help#ffffff to get a list of helpful commands", 255,255,255, true)
    outputChatBox("------", 255,100,100, true)

    outputChatBox(PREFIX.."#ffffff Press#878787 F2#ffffff to change your team", 255,100,100, true)
    setPlayerHudComponentVisible("area_name", false)
    setPlayerHudComponentVisible("vehicle_name", false)
end)

addEventHandler("onClientResourceStop", getResourceRootElement(getThisResource()), function()
    spawnSelection()
    setPlayerHudComponentVisible("area_name", true)
    setPlayerHudComponentVisible("vehicle_name", true)
end)

function toggleMovementControls(state)
    for i,v in ipairs(mainControls) do
        toggleControl(v, state)
    end
end

function toggleSpawnSelection(state)
    toggleMovementControls(not state)
    inSpawnSelection = state
    -- enter spawn selection --
    if state == true then
        spawnSelectionPed = createPed(getElementModel(localPlayer), spawn.x,spawn.y,spawn.z)
        setElementRotation(spawnSelectionPed, 0,0,180)
        setElementFrozen(localPlayer, true)
        setElementAlpha(localPlayer, 180)
        setCameraMatrix(spawn.x-1,spawn.y-6,spawn.z+1, spawn.x,spawn.y,spawn.z+0.5)
    -- exit spawn selection --
    else
        setCameraTarget(localPlayer)
        setElementFrozen(localPlayer, false)
        setElementAlpha(localPlayer, 255)
        destroyElement(spawnSelectionPed)
    end
end

function toggleSpawnSelectionBinds(state)
    if state == true then
        bindKey("arrow_u", "down", changeTeam, -1)
        bindKey("arrow_d", "down", changeTeam, 1)
        bindKey("space", "down", ptpSpawnPlayer)
        addEventHandler("onClientRender", root, drawClassName)
    else
        unbindKey("arrow_u", "down", changeTeam, -1)
        unbindKey("arrow_d", "down", changeTeam, 1)
        unbindKey("space", "down", ptpSpawnPlayer)
        removeEventHandler("onClientRender", root, drawClassName)
    end
end

function spawnSelection()
    if source and source ~= localPlayer then return end
    teamID = 1
    teamName = IDtoTeam[teamID]
    team = getTeamFromName(teamName)
    if inSpawnSelection then
        toggleSpawnSelection(false)
        toggleSpawnSelectionBinds(false)
    else
        toggleSpawnSelection(true)
        toggleSpawnSelectionBinds(true)
    end
end

function ptpSpawnPlayer()
    fadeCamera(false, 0.3)
    toggleSpawnSelectionBinds(false)
    setTimer(function()
        toggleSpawnSelection(false)
        triggerServerEvent("onPlayerSpawnInTeam", localPlayer, localPlayer, "F2", teamName)
    end, 300, 1)
end

function changeTeam(key, state, direction)
    -- switch --
    teamID = teamID + direction
    -- loop back --
    if teamID > #IDtoTeam then teamID = 1 end
    if teamID < 1 then teamID = #IDtoTeam end
    -- update variables --
    teamName = IDtoTeam[teamID]
    team = getTeamFromName(teamName)
end

function drawClassName()
	dxDrawText (teamName, (685/1366)*screenX, (700/768)*screenY, (685/1366)*screenX, (700/768)*screenY, tocolor ( 6, 6, 6, 255 ), (screenX/1366)*3, "default-bold","center","center",false,false,false)
	dxDrawText (teamName, (684/1366)*screenX, (700/768)*screenY, (684/1366)*screenX, (700/768)*screenY, tocolor ( teamList[teamName][1],teamList[teamName][2],teamList[teamName][3], 255 ), (screenX/1366)*3, "default-bold","center","center",false,false,false)
    -- use arrow keys --
    dxDrawText ("use ⬆⬇ arrow keys to change teams", (685/1366)*screenX, (740/768)*screenY, (685/1366)*screenX, (740/768)*screenY, tocolor ( 6, 6, 6, 255 ), (screenX/1366)*1.8, "default-bold","center","center",false,false,false,true)
	dxDrawText ("use#ff6666 ⬆⬇ arrow keys#ffffff to change teams", (684/1366)*screenX, (740/768)*screenY, (684/1366)*screenX, (740/768)*screenY, tocolor ( 255, 255, 255, 255 ), (screenX/1366)*1.8, "default-bold","center","center",false,false,false,true)
end

addEvent("enterSpawnSelection", true)
addEventHandler("enterSpawnSelection", getRootElement(), spawnSelection)
bindKey("F2", "down", spawnSelection)

------------------------
-- CONSOLE DEBUG MODE --
------------------------

local consoleDebugMode = false

function debugToConsole(message)
    outputConsole(message, localPlayer)
end

addCommandHandler("pmaconsoledebug",
    function()
        if consoleDebugMode then
            outputChatBox(PREFIX.."#ffffff Debug messages in console #ff2e2edisabled", 255,100,100, true)
            removeEventHandler("onClientDebugMessage", getRootElement(), debugToConsole)
            consoleDebugMode = false
        else
            outputChatBox(PREFIX.."#ffffff Debug messages in console #7aff69enabled", 255,100,100, true)
            addEventHandler("onClientDebugMessage", getRootElement(), debugToConsole)
            consoleDebugMode = true
        end
    end
)

--------------------------
-- ELEMENT EXAMINE MODE --
--------------------------

local examineMode = false
local padding = 20 * scaleValue
local examineInfoTable = {}

function examineElement()

    -- hold RMB to examine --
    if getKeyState("mouse2") then
        showCursor(true)
    else
        showCursor(false)
    end

    if isCursorShowing() then

        local cursorx, cursory, worldx, worldy, worldz = getCursorPosition()
        local cursorx, cursory = cursorx*screenX, cursory*screenY
        local px, py, pz = getCameraMatrix()
        local hit, x, y, z, element, _, _, _, material, lighting, piece = processLineOfSight ( px, py, pz, worldx, worldy, worldz )

        if hit then
            if element then
                
                -- info --
                local elementType = getElementType(element)
                local       model = (elementType ~= "vehicle" and getElementModel(element)) or (getElementModel(element) .. "#878787 |#ffffff Name:#ff6666 " .. (elementType == "vehicle" and getVehicleName(element) or ""))
                local          id = getElementID(element) or (elementType == "player" and removeHex(getPlayerName(element))) or "nil"
                local       x,y,z = getElementPosition(element)
                local    xr,yr,zr = getElementRotation(element)
                local         pos = string.format("%s, %s, %s", math.ceil(x), math.ceil(y), math.ceil(z))
                local         rot = string.format("%s, %s, %s", math.ceil(xr), math.ceil(yr), math.ceil(zr))

                examineInfoTable = {
                    "Type:#ff6666 " .. elementType .. (elementType == "player" and "#878787 |#ffffff Nick:#ff6666 " or "#878787 |#ffffff ID:#ff6666 ") .. id,
                    "Model:#ff6666 " .. model,
                    "Position:#ff6666 " .. pos,
                    "Rotation:#ff6666 " .. rot,
                    "Material:#ff6666 " .. material .. "#878787 |#ffffff Piece:#ff6666 " .. piece .. "#878787 |#ffffff Lighting:#ff6666 " .. lighting,
                }

                dxDrawText("#878787Double click to output to chat", cursorx+6, cursory+6-padding, cursorx+6, cursory+6-padding, tocolor(0,0,0,255), 1, "default", "left", "center", false, false, false, true)

                -- draw the info --
                for i=1, #examineInfoTable do
                    local offset = i * padding
                    dxDrawText(removeHex(examineInfoTable[i]), cursorx+6, cursory+6+offset, cursorx+6, cursory+6+offset, tocolor(0,0,0,255), 1, "default", "left", "center", false, false, false, true)
                    dxDrawText(examineInfoTable[i], cursorx+5, cursory+5+offset, cursorx+5, cursory+5+offset, tocolor(255,255,255,255), 1, "default", "left", "center", false, false, false, true)
                end

            else
                dxDrawText("Find an element (vehicle, player, etc.)", cursorx+6, cursory+6+padding, cursorx+6, cursory+6+padding, tocolor(0,0,0,255), 1, "default", "left", "center", false, false, false, true)
                dxDrawText("Find an element (vehicle, player, etc.)", cursorx+5, cursory+5+padding, cursorx+5, cursory+5+padding, tocolor(255,255,255,255), 1, "default", "left", "center", false, false, false, true)
            end
        end
    end

end

function examineElementOnDoubleClick(button, _, _, _, _, _, element)
    if examineMode and button == "left" and element then
        outputChatBox(" ")
        -- type, model and id --
        outputChatBox(PREFIX .. "#ffffff " .. examineInfoTable[1], 255,100,100, true)
        -- model --
        outputChatBox(examineInfoTable[2], 255,255,255, true)
        -- position --
        outputChatBox(examineInfoTable[3], 255,255,255, true)
        -- rotation --
        outputChatBox(examineInfoTable[4], 255,255,255, true)
        -- other --
        outputChatBox(examineInfoTable[5], 255,255,255, true)
        outputChatBox(" ")
	end
end

addCommandHandler("pmaexamine",
    function()
        if examineMode then
            outputChatBox(PREFIX .. "#ffffff Examine Mode#ff2e2e disabled", 255,100,100, true)
            removeEventHandler("onClientRender", getRootElement(), examineElement)
            removeEventHandler("onClientDoubleClick", getRootElement(), examineElementOnDoubleClick)
            showCursor(false)
            examineMode = false
        else
            outputChatBox(PREFIX .. "#ffffff Examine Mode#7aff69 enabled#ffffff. Hold#878787 RMB#ffffff to examine elements", 255,100,100, true)
            addEventHandler("onClientRender", getRootElement(), examineElement)
            addEventHandler("onClientDoubleClick", getRootElement(), examineElementOnDoubleClick)
            examineMode = true
        end
    end
)

function drawUI()
    local loadedMapName = ""
    dxDrawText("Current Map:#878787 " .. loadedMapName, screenX/2, 15*scaleValue, nil, nil, tocolor(255,255,255,255), scaleValue*1.4, "default", "center", "center", false, false, false, true)
end
--addEventHandler("onClientRender", getRootElement(), drawUI)

--------------
-- DRAW FPS --
--------------

local fps = 0

function getCurrentFPS() return fps end

function updateFPS(msSinceLastFrame)
    fps = (1 / msSinceLastFrame) * 1000
end

function drawFPS()
    if not getCurrentFPS() then return end
    local roundedFPS = math.floor(getCurrentFPS())
    dxDrawText(roundedFPS, 0, screenY - dxGetTextWidth(roundedFPS))
end

addEventHandler("onClientPreRender", root, updateFPS)
addEventHandler("onClientHUDRender", root, drawFPS)

------------------
-- HELP COMMAND --
------------------

addCommandHandler("pmahelp",
    function()
        outputChatBox(PREFIX.."#ffffff Useful Commands:", 255,100,100, true)
        for _,v in ipairs(commandList) do
            outputChatBox("#878787/pma#ff6666"..v[1].."#ffffff - "..v[2], 255,255,255, true)
        end
    end
)

---------------------
-- CONTACT COMMAND --
---------------------

addCommandHandler("pmacontact",
    function()
        outputChatBox(PREFIX.."#ffffff Hit me up on#7289DA Discord#878787 JessePinkman#ff6666#8269 #ffffffor#878787 ffs.gg", 255,100,100, true)
    end
)

---------------------------------
-- MINIMIZE/MAXIMIZE INDICATOR --
---------------------------------

-- sound --
addEventHandler("onClientMinimize", root, function()
    triggerServerEvent("onMinimizePlaySound", resourceRoot, localPlayer)
end)

addEventHandler("onClientRestore", root, function()
    triggerServerEvent("onRestorePlaySound", resourceRoot, localPlayer)
end)

-- message --
function minimizeMessage (playerName)
	minimizeSound = playSFX("script", 144, 1, false)
    setSoundVolume(minimizeSound, 0.4)
    displayText(playerName.."#FFFFFF minimized MTA", 5000)
end

function maximizeMessage (playerName)
	restoreSound = playSFX("script", 144, 2, false)
	setSoundVolume(restoreSound, 0.4)
    displayText(playerName.."#FFFFFF is back", 5000)
end

addEvent("onRestoreTrigger", true)
addEvent("onMinimizeTrigger", true)
addEventHandler("onMinimizeTrigger", localPlayer, minimizeMessage, playerName)
addEventHandler("onRestoreTrigger", localPlayer, maximizeMessage, playerName)

-----------------
-- CALL PLAYER --
-----------------

local ringtones = {
    {93,  0},
    {105, 0},
    {94,  4},
}

function playSound(caller)
    if getElementData(localPlayer, "phoneIsRinging") ~= 1 then
        local randomTone = ringtones[math.random(#ringtones)]
		chatSound = playSFX3D ("script", randomTone[1], randomTone[2], getElementPosition(localPlayer))
		setElementData(localPlayer, "phoneIsRinging", 1)
		setTimer(function()
			setElementData(localPlayer, "phoneIsRinging", 0)
		end, 5000, 1)
		setSoundVolume (chatSound, 0.5)
		attachElements(chatSound, localPlayer)
        setSoundMaxDistance(chatSound, 30)
        local caller_unhexed = removeHex(getPlayerName(caller))
        outputChatBox(PREFIX.."#7aff69 "..caller_unhexed.."#ffffff is calling you!", 255,100,100, true)
	end
end

addEvent("playSoundClient", true)
addEventHandler("playSoundClient", localPlayer, playSound, caller)

---------------------
-- DRAW VEHICLE HP --
---------------------

local vehicleHPDrawn = false

addEventHandler("onClientVehicleEnter", getRootElement(),
function (player, seat)
	if player ~= localPlayer then return end
    if not vehicleHPDrawn then
        addEventHandler("onClientRender", getRootElement(), drawHP)
        vehicleHPDrawn = true
    end
end)

addEventHandler("onClientVehicleStartExit", getRootElement(),
function (player, seat)
	if player ~= localPlayer then return end
    if vehicleHPDrawn then
        removeEventHandler("onClientRender", getRootElement(), drawHP)
        vehicleHPDrawn = false
    end
end)

function drawHP ()
    if getPedOccupiedVehicle(localPlayer) then
        local health = math.floor(getElementHealth(getPedOccupiedVehicle(localPlayer))) or ""
        dxDrawText(health, (1190/1366)*screenX, (150/768)*screenY, (1190/1366)*screenX, (150/768)*screenY, tocolor(255,255,255, 255), (screenX/1366)*1.5, "tahoma","center","bottom", false, false, false, true)
    end
end

--local counter = 0
function newDebug(message, level, file, line)
    if isDebugViewActive() then return end
    counter = counter + 1
    if not isTimer(debugTimer) or not getTimerDetails(debugTimer) then
        debugTimer = setTimer(function()
            if counter > 0 and counter < 30 then
                outputChatBox("[Debug Messages Available]", 255, 46, 46)
            end
        end, 5000, 1)
    end
    if counter ~= 30 then return end
    killTimer(debugTimer)
    outputChatBox("[Debug Messages Available]", 255, 46, 46)
    counter = 0
end
--addEventHandler("onClientDebugMessage", root, newDebug)

--------------------
--- DISPLAY TEXT ---
--------------------

function displayText (text, time)
	if renderTextDrawn then
        stopRenderingText()
        resetTimer(stopDisplayingTimer)
    end
    addEventHandler ( "onClientRender", root, renderText )
    theText = text
    renderTextDrawn = true
    if time then
        stopDisplayingTimer = setTimer(stopRenderingText, time, 1)
    end
end

function stopRenderingText()
	if renderTextDrawn then
		removeEventHandler ( "onClientRender", root, renderText )
		renderTextDrawn = false
	end
end

function renderText ()
	dxDrawText(theText, (15/1366)*screenX, (753/768)*screenY, (15/1366)*screenX, (753/768)*screenY, tocolor(0,0,0, 255), (screenX/1366)*1.8, "tahoma","left","bottom",false,false,false,true)
	dxDrawText(theText, (15/1366)*screenX, (753/768)*screenY, (15/1366)*screenX, (753/768)*screenY, tocolor(255,255,255, 255), (screenX/1366)*1.8, "tahoma","left","bottom",false,false,false,true)
end
