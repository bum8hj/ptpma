-- convert rgb to hex --
function rgbToHex(red, green, blue, alpha)
	if ((red < 0 or red > 255 or green < 0 or green > 255 or blue < 0 or blue > 255) or (alpha and (alpha < 0 or alpha > 255))) then
		return nil
	end
	if alpha then
		return string.format("#%.2X%.2X%.2X%.2X", red, green, blue, alpha)
	else
		return string.format("#%.2X%.2X%.2X", red, green, blue)
	end
end

-- remove hex --
function removeHex(s)
    return s:gsub ("#%x%x%x%x%x%x", "") or false
end

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------

local PREFIX = "[PTP MA]"

-- create ptp teams --
local teamsList = {
    ["President"]      = {255, 255, 0},
    ["Secret Service"] = {0, 30, 200},
    ["Police"]         = {0, 170, 255},
    ["Terrorists"]     = {200, 0, 0},
    ["Civilians"]      = {255, 255, 255},
    ["Medics"]         = {0, 255, 0},
}

-- store spawn points --
local spawnPointsPTP = {
    ["President"]      = {},
    ["Secret Service"] = {},
    ["Police"]         = {},
    ["Terrorists"]     = {},
    ["Civilians"]      = {},
    ["Medics"]         = {},
}

local allowedTeams = {
    ["President"]      = true,
    ["Secret Service"] = true,
    ["Police"]         = true,
    ["Terrorists"]     = true,
    ["Civilians"]      = true,
    ["Medics"]         = true,
}

-- map variables --
local lastMap = nil
local loadedMap = nil
local loadedMap_isBunker = false
local loadedMap_totalSpawns = 0


addEventHandler("onResourceStart", getResourceRootElement(getThisResource()),
    function(res)
        for name, colors in pairs(teamsList) do
            createTeam(name, unpack(colors))
        end
        for _, player in ipairs(getElementsByType("player")) do
            setPlayerNametagText(player, removeHex(getPlayerName(player), 6))
            setPlayerNametagColor(player, false)
            
            if getPlayerTeam(player) then return end
            
            local teams = getElementsByType("team")
            setPlayerTeam(player, teams[math.random(#teams)])
        end
    end
)

-----------------------------------
-- GET SPAWN POINTS FROM PTP MAP --
-----------------------------------

function getMapSpawnPoints(map)

    -- list to check for missing spawn points --
    local spawnsAvailable = { ["President"] = false, ["Secret Service"] = false, ["Police"] = false, ["Terrorists"] = false, ["Civilians"] = false, ["Medics"] = false, }
    
    -- store spawn points temporarily --
    local mapSpawnPoints = {
        ["President"]      = {},
        ["Secret Service"] = {},
        ["Police"]         = {},
        ["Terrorists"]     = {},
        ["Civilians"]      = {},
        ["Medics"]         = {},
    }

    -- get markers from the loaded map --
    for _,marker in ipairs(getElementsByType("marker", getResourceRootElement(map))) do
        if getMarkerType(marker) == "cylinder" then

            -- marker variables --
            local x,y,z = getElementPosition(marker)
            local r,g,b,a = getMarkerColor(marker)

            for team_name, team_color in pairs(teamsList) do

                local r2,g2,b2 = unpack(team_color)  -- team's spawn marker color

                -- if correct colors --
                if r == r2 and g == g2 and b == b2 then
                    table.insert(mapSpawnPoints[team_name], {x, y, z}) -- add spawn point
                end

                -- spawn points for this team are available --
                if not spawnsAvailable[team_name] then
                    spawnsAvailable[team_name] = true
                end

            end

        end
    end

    -- return the spawn points, and spawn point avalibility table --
    return mapSpawnPoints, spawnsAvailable

end



function getTotalSpawnPoints(spawn_points_table)
    local total = 0
    for _, spawn_points in pairs(spawn_points_table) do
        total = total + #spawn_points
    end
    return total
end


function isMapBunker(map)
    local map_description = getResourceInfo(map, "description")
    if map_description and string.find(map_description, "#bunker") then
        return true
    else
        return false
    end
end


function getMapValidity(map)

    -- resource info --
    local res_name = getResourceName(map)
    local res_type = getResourceInfo(map, "type")
    local map_name = getResourceInfo(map, "name")
    
    -- ignore this resource, and non-maps --
    if map == getThisResource() or (res_type and res_type ~= "map") then
        return "type"
    end

    -- if the map has no name --
    if not map_name then
        return "name"
    end
    
    -- if map name doesn't have [PTP] prefix --
    if string.sub(map_name, 1, 5) ~= "[PTP]" then
        return "prefix"
    end

    return "valid"

end

function testMap(map)

    local map_name = getResourceInfo(map, "name")
    local map_result = 3 -- | 1 = warnings | 2 = suggestions | 3 = no issues |
    local heavy_vehicles = false
    local limousine = false

    local vehicleCount = {
        ["Shamal"] = 0,
        ["Rustler"] = 0,
    }
    
    -- get map spawn points and spawn point avalibility --
    local table_spawnPoints, table_spawnAvalibility = getMapSpawnPoints(map)
    local total_spawnPoints = getTotalSpawnPoints(table_spawnPoints)

    outputChatBox("\n-- TEST RESULTS --", getRootElement(), 255,100,100, true)

    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------

    -- check markers --
    if total_spawnPoints < 20 then
        if map_result > 1 then map_result = 1 end -- warn
        outputChatBox("**#878787 " .. total_spawnPoints .. "#ffffff spawn points are not enough, please add more.", getRootElement(), 255,100,100, true)
    end

    -- go through map vehicles --
    for _,vehicle in ipairs(getElementsByType("vehicle", getResourceRootElement(map))) do

        local model = getElementModel(vehicle)
        
        -- search for heavy vehicles --
        if not heavy_vehicles and (model == 425 or model == 432 or model == 520) then -- hunter, rhino, hydra
            heavy_vehicles = true
        end

        -- search for planes --
        if model == 519 then -- shamal
            vehicleCount.Shamal = vehicleCount.Shamal + 1
        elseif model == 476 then -- rustler
            vehicleCount.Rustler = vehicleCount.Rustler + 1
        end

        if not limousine and model == 409 then -- stretch (limo)
            limousine = true
        end

    end

    -- no limousine found --
    if not isMapBunker(map) and not limousine then
        if map_result > 1 then map_result = 1 end -- warn
        outputChatBox("**#ffffff President limousine not found!", getRootElement(), 255,100,100, true)
    end

    -- heavy vehicle(s) found --
    if heavy_vehicles then
        if map_result > 2 then map_result = 2 end -- suggest
        outputChatBox("*#ffffff Hunter, Hydra or Rhino detected. PTP does not spawn them.", getRootElement(), 255,100,100, true)
    end

    -- too many shamals --
    if vehicleCount.Shamal > 10 then
        if map_result > 2 then map_result = 2 end -- suggest
        outputChatBox("*#ffffff Too many#878787 Shamals#ffffff, we suggest removing some.", getRootElement(), 255,100,100, true)
    end

    -- too many rustlers --
    if vehicleCount.Rustler > 8 then
        if map_result > 2 then map_result = 2 end -- suggest
        outputChatBox("*#ffffff Too many#878787 Rustlers#ffffff, we suggest removing some.", getRootElement(), 255,100,100, true)
    end

    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------

    -- evaluate the map --
    if     map_result == 1 then
        outputChatBox("#ff0000Major issues found with#878787 " .. map_name, getRootElement(), 255,100,100, true)
    elseif map_result == 2 then
        outputChatBox("#ff9600Minor issues found with#878787 " .. map_name, getRootElement(), 255,100,100, true)
    elseif map_result == 3 then
        outputChatBox("#7aff69No issues found with#878787 " .. map_name, getRootElement(), 255,100,100, true)
    end
    outputChatBox(" ")

end

-- check and load the PTP map --
function loadPTPMap(res)

    -- info --
    local res_name = getResourceName(res)
    local map_name = getResourceInfo(res, "name")
    
    -- ignore this resource, and non-maps --
    if getMapValidity(res) == "type" then return end

    -- if another map is already loaded --
    if loadedMap and res ~= loadedMap then
        local loadedMap_name = getResourceInfo(loadedMap, "name")
        outputChatBox(PREFIX.."#ffffff Another map is already loaded. However, you can still test#878787 " .. map_name, getRootElement(), 255,100,100, true)
        return
    end

    -- if the map has no name --
    if getMapValidity(res) == "name" then
        outputChatBox(PREFIX.."#ff0000 Map name for#878787 " .. res_name .. "#ff0000 is missing!", getRootElement(), 255,100,100, true)
        return
    end
    
    -- if map name doesn't have [PTP] prefix --
    if getMapValidity(res) == "prefix" then
        outputChatBox(PREFIX.."#ff0000 Map ignored because name doesn't start with#878787 [PTP]", getRootElement(), 255,100,100, true)
        return
    end
    
    -- get map spawn points and spawn point avalibility --
    local table_spawnPoints, table_spawnAvalibility = getMapSpawnPoints(res)
    local total_spawnPoints = getTotalSpawnPoints(table_spawnPoints)

    -- update the loaded map spawn points --
    spawnPointsPTP = table_spawnPoints

    -- check if a team is missing spawn points --
    for teamName, available in pairs(table_spawnAvalibility) do
        if not available then
            local team_color = rgbToHex(unpack(teamsList[teamName]))
            outputChatBox(PREFIX.."#ff0000 No spawn points found for " .. team_color .. teamName .. "#ff0000, check your marker colors!", getRootElement(), 255,100,100, true)
            return
        end
    end

    ------------------------------------------------------------------------------------------------------------------------
    -- MAP IS VALID
    ------------------------------------------------------------------------------------------------------------------------

    loadedMap = res -- update loaded map
    loadedMap_totalSpawns = total_spawnPoints -- update total spawn points

    -- output how many spawn points are there --
    if loadedMap_totalSpawns > 0 then
        outputChatBox(PREFIX .. "#ffffff Added#878787 " .. loadedMap_totalSpawns .. "#ffffff spawn points from#878787 " .. map_name, getRootElement(), 255,100,100, true)
    end

    -- check if bunker --
    if isMapBunker(res) then
        loadedMap_isBunker = true
        outputChatBox(PREFIX .. "#ffffff Map marked as#878787 bunker#ffffff by the author", getRootElement(), 255,100,100, true)
    else
        loadedMap_isBunker = false
        -- guess if bunker --
        if string.find(string.lower(map_name), "bunker") then
            outputChatBox(PREFIX .. "#ffffff Is this a bunker? Use#878787 /pma#ff6666bunker#ffffff to mark it", getRootElement(), 255,100,100, true)
        end
    end

    -- auto map test --
    outputChatBox(PREFIX .. "#ffffff Use#878787 /pma#ff6666testmap#ffffff to test the map", getRootElement(), 255,100,100, true)

end
addEventHandler("onResourceStart", getRootElement(), loadPTPMap)

----------------
-- TEST A MAP --
----------------

addCommandHandler("pmatestmap", 
    function(source, commandName, res_name)
        
        -- prevent spam --
        if isTimer(mapTestingTimer) and getTimerDetails(mapTestingTimer) then return end

        -- specified map --
        if res_name then

            local res = getResourceFromName(res_name) -- get the resource

            if res then

                -- map validity checks --
                if getMapValidity(res) ~= "valid" then
                    if getMapValidity(res) == "type" then
                        outputChatBox(PREFIX .. "#ff0000 Not a valid map!", getRootElement(), 255,100,100, true)
                    elseif getMapValidity(res) == "name" then
                        outputChatBox(PREFIX .. "#ff0000 Missing map name!", getRootElement(), 255,100,100, true)
                    elseif getMapValidity(res) == "prefix" then
                        outputChatBox(PREFIX .. "#ff0000 Missing#878787 [PTP]#ff0000 in map name!", getRootElement(), 255,100,100, true)
                    end
                    return
                end

                -- test map --
                if getResourceState(res) == "running" then
                    outputChatBox(PREFIX .. "#ffffff Testing#878787 " .. getResourceInfo(res, "name") .. "#ffffff...", getRootElement(), 255,100,100, true)
                    mapTestingTimer = setTimer(function()
                        testMap(res)
                    end, 2000, 1)
                else
                    outputChatBox(PREFIX .. "#ff0000 The map is not running!", getRootElement(), 255,100,100, true)
                end

            else
                outputChatBox(PREFIX .. "#ff0000 Could not find the specified map! Try#878787 /refresh", getRootElement(), 255,100,100, true)
            end

        -- loaded map --
        else
            if loadedMap then
                outputChatBox(PREFIX.."#ffffff Testing loaded map...", getRootElement(), 255,100,100, true)
                mapTestingTimer = setTimer(function()
                    testMap(loadedMap)
                end, 2000, 1)
            else
                outputChatBox(PREFIX.."#ff0000 Load your map first!", getRootElement(), 255,100,100, true)
            end
        end
    end
)

---------------------------
-- MARK/UNMARK AS BUNKER --
---------------------------

addCommandHandler("pmabunker", 
    function(source, commandName)
        loadedMap_isBunker = true
        outputChatBox(PREFIX.."#ffffff Map marked as#878787 bunker#ffffff. Use#878787 /pma#ff6666notbunker#ffffff to unmark it", getRootElement(), 255,100,100, true)
    end
)

addCommandHandler("pmanotbunker", 
    function(source, commandName)
        loadedMap_isBunker = false
        outputChatBox(PREFIX.."#ffffff Map marked as#878787 not bunker#ffffff", getRootElement(), 255,100,100, true)
    end
)

addEventHandler("onResourceStop", getRootElement(),
    function(res)

        local res_type = getResourceInfo(res, "type")
        if res == getThisResource() or (res_type and res_type ~= "map") then return end

        if res == loadedMap then

            local map_name = getResourceInfo(res, "name")
            lastMap = res
            loadedMap = nil
            
        end

        -- clear spawn points --
        loadedMap_totalSpawns = 0
        spawnPointsPTP = {
            ["President"]      = {},
            ["Secret Service"] = {},
            ["Police"]         = {},
            ["Terrorists"]     = {},
            ["Civilians"]      = {},
            ["Medics"]         = {},
        }

    end
)

function getRandomSpawn(teamName)
    local teamSpawns = spawnPointsPTP[tostring(teamName)]
    return unpack(teamSpawns[math.random(1, #teamSpawns)])
end

function spawnPlayerPTP(source, _, ...)

    local team_name = table.concat({...}, " ")
    local team = getTeamFromName(team_name)
    local rx, ry, rz = getElementRotation(source)
    local sx, sy, sz = getElementPosition(source)

    -- team name specified --
    if #team_name > 0 then
        
        -- valid team name --
        if allowedTeams[team_name] then

            if not getPlayerTeam(source) or getTeamName(getPlayerTeam(source)) ~= team_name then
                outputChatBox(PREFIX .. "#ffffff Spawned in team: " .. rgbToHex(getTeamColor(team)) .. team_name, source, 255,100,100, true)
            end
            
            -- if no spawn points --
            if loadedMap_totalSpawns == 0 then
                outputChatBox(PREFIX.."#ff0000 No spawn markers available!", source, 255,100,100, true)
            else
                sx, sy, sz = getRandomSpawn(team_name)
            end

        else
            outputChatBox(PREFIX .. "#ff0000 Enter a valid PTP team!", source, 255,100,100, true)
        end
    
    -- no team name specified --
    else

        -- already in a PTP team --
        if getPlayerTeam(source) and allowedTeams[getTeamName(getPlayerTeam(source))] then
            if loadedMap_totalSpawns > 0 then
                sx, sy, sz = getRandomSpawn(getTeamName(getPlayerTeam(source)))
            end
        else
            outputChatBox(PREFIX .. "#ffffff Use #878787/pma#ff6666spawn [team name]#ffffff to spawn in a PTP team.", source, 255,100,100, true)
        end

    end

    -- spawn the player --
    spawnPlayer(source, sx, sy, sz + 0.2, rz, 0, 0, 0, team or nil)

    ---------
    fadeCamera(source, true)
    setCameraTarget(source)
    setElementRotation(source, 0,0,0)
end

function putInRandomTeam()
    local teams = getElementsByType("team")
    setPlayerTeam(source, teams[math.random(2, #teams)])
    triggerClientEvent("enterSpawnSelection", source)
end

------------------------------
-- AUTO ASSIGN TEAM ON JOIN --
------------------------------

addEventHandler("onPlayerJoin", getRootElement(),
    function()
        local teams = getElementsByType("team")
        setPlayerTeam(source, teams[math.random(2, #teams)])
    end
)

------------------
-- SET INTERIOR --
------------------

addCommandHandler("pmainterior", 
    function(source, commandName, interior)
        setElementInterior(source, interior or 0)
    end
)

----------------------------------------------------------------------------------------------------------------------------

addEvent("onPlayerSpawnInTeam", true)

addEventHandler("onPlayerSpawnInTeam", getRootElement(), spawnPlayerPTP)
addEventHandler("onPlayerJoin", getRootElement(), putInRandomTeam)

addCommandHandler("pmaspawn", spawnPlayerPTP)
