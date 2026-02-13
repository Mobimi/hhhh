local Players, RunService, UserInputService, CoreGui, ReplicatedStorage, TweenService, HttpService, TeleportService, Lighting, VirtualUser = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("CoreGui"), game:GetService("ReplicatedStorage"), game:GetService("TweenService"), game:GetService("HttpService"), game:GetService("TeleportService"), game:GetService("Lighting"), game:GetService("VirtualUser")
local player, currentTab, guiVisible = Players.LocalPlayer, 1, true
local char = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(c) char = c end)
local ui_controls, configFolder, configFileName, allStrokes, allBtnStrokes = {}, "j4f", "j4f/config_j4f.json", {}, {}
local hitboxEnabled, hitboxSize, showHitbox = {self = false, others = false, mob = false}, {self = 10, others = 10, mob = 10}, {self = false, others = false, mob = false}
local selectedBodyParts = {
    self = {Head = false, Torso = false, ["Left Arm"] = false, ["Right Arm"] = false, ["Left Leg"] = false, ["Right Leg"] = false, HumanoidRootPart = false},
    others = {Head = false, Torso = false, ["Left Arm"] = false, ["Right Arm"] = false, ["Left Leg"] = false, ["Right Leg"] = false, HumanoidRootPart = false},
    mob = {Head = false, Torso = false, ["Left Arm"] = false, ["Right Arm"] = false, ["Left Leg"] = false, ["Right Leg"] = false, HumanoidRootPart = false}
}
local mobPath, originalProperties, processedParts, mobCache = "workspace", setmetatable({}, {__mode = "k"}), {}, {lastScan = 0, list = {}}
local auraEnabled, auraRadius, auraDelay, lastHitTime, hitCount, auraMode = true, 1000, 0.01, 0, 0, "Unencode"
local auraFruitEnabled, auraFruitRadius, auraFruitDelay = true, 500, 0.01
local attackRemote, hitRemote, auraConnection, isSpamming, spamConnection, lastAttack = nil, nil, nil, false, nil, 0
local proxyRemote, seedVal, attackRemoteDirect, hitRemoteDirect = nil, nil, nil, nil
local selectedAttacks, fastM1Enabled, fastMeleeMultiplier, fastFruitMultiplier = {true, true, true, true, true}, false, 1, 1
local boatSpeed, tpEnabled, tpSpeed, autoRaceV3Enabled, autoBusoEnabled, infinityJumpEnabled, antiAfkEnabled = 200, false, 2, false, true, false, true
local jumpHeightEnabled, jumpHeightValue, dashLengthValue, waterWalkEnabled, antiWaterEnabled, antiWaterThreshold = false, 7.2, 0, true, true, -0.807
local flyBoatEnabled, flyBoatSpeed, flyBoatHeight, currentBoat, flyBoatStyle, isPlayerOnBoat = false, 200, 125, nil, "Default", false
local islandTweenEnabled, islandTweenSpeed = {["Mirage Island"] = false, ["Kitsune Island"] = false, ["Prehistoric Island"] = false}, 360
local espSettings, espConnection, espBillboards = { Enabled = false, ShowText = true, ShowBar = true }, nil, {}
local islandEspSettings, islandEspBillboards = { Enabled = false, ESP_List = {["Mirage Island"] = false, ["Kitsune Island"] = false, ["Prehistoric Island"] = false} }, {}
local autoChestMirage, autoChestStyle, autoChestType, autoActiveV4Enabled, autoTradeBonesEnabled, autoStoreFruitEnabled, autoDungeonEnabled = false, "Tween", "All", false, false, false, false
local autoBossEnabled, autoBossHopEnabled, customBossEnabled, selectedBosses = false, false, false, {}
local autoUpgradeRaceEnabled = false
local autoFarmBonesEnabled, autoBoneTargetObj = false, nil
local boneMobs = {"Reborn Skeleton", "Demonic Soul", "Posessed Mummy", "Living Zombie"}
local autoBossTargetObj, lastBossDeadTime, masterBossList = nil, 0, {}
local autoCakeFarmEnabled, autoCakeSpawnEnabled, autoCakeTargetObj = false, false, nil
local cakeMobs = {"Cake Prince", "Baking Staff", "Cake Guard", "Cookie Crafter", "Head Baker"}
local autoEquipType = "Melee" 
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local baseScanInterval = isMobile and 0.8 or 0.5
local scanInterval, espInterval = baseScanInterval, isMobile and 1.0 or 0.5
local characterParts, lastFoamState, safeHeight = {}, nil, 15
local THEME = { GREEN = Color3.fromRGB(34,139,34), RED = Color3.fromRGB(178,34,34), ACCENT = Color3.fromRGB(255,215,0), TEXT_DIM = Color3.fromRGB(80,80,80) }
local function corner(p, r) local c = Instance.new("UICorner", p) c.CornerRadius = UDim.new(0, r or 8) return c end

-- WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "j4f.luau |  BETA",
    Author = "by tiktok: @realayako",
    Folder = "j4f_configs",
    Icon = "bird",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    HideSearchBar = true,
    NewElements = true,
    OpenButton = {
        Title = "j4f",
        Enabled = true,
        Draggable = true,
        CornerRadius = UDim.new(0, 12),
        Scale = 0.5,
    },
    Topbar = { Height = 44, ButtonsType = "Mac" },
})

-- Section
local Nav = Window:Section({ Title = "Menu" })

-- Hitbox Logic
local function saveOriginal(p) if not originalProperties[p] then originalProperties[p] = {Size=p.Size, Transparency=p.Transparency, CanCollide=p.CanCollide, Color=p.Color, Material=p.Material} end end
local function applyHitbox(p, s, sh, c) if p.Size ~= Vector3.new(s,s,s) then p.Size = Vector3.new(s,s,s) end p.Transparency, p.CanCollide = sh and 0.5 or 1, false if sh then p.Color, p.Material = c, Enum.Material.ForceField end end
local function restoreHitbox(p) if originalProperties[p] then local o = originalProperties[p] p.Size, p.Transparency, p.CanCollide, p.Color, p.Material = o.Size, o.Transparency, o.CanCollide, o.Color, o.Material end end
local function expandHitbox(tt)
    if tt == "self" then 
        if not char then return end 
        for n,e in selectedBodyParts.self do 
            if e then 
                local p = char:FindFirstChild(n) 
                if p and p:IsA("BasePart") then 
                    saveOriginal(p) 
                    if p.Size ~= Vector3.new(hitboxSize.self, hitboxSize.self, hitboxSize.self) then
                        applyHitbox(p, hitboxSize.self, showHitbox.self, Color3.new(0,1,0)) 
                    end
                end 
            end 
        end
    elseif tt == "others" then 
        for _,p in Players:GetPlayers() do 
            if p ~= player and p.Character then 
                for n,e in selectedBodyParts.others do 
                    if e then 
                        local pt = p.Character:FindFirstChild(n) 
                        if pt and pt:IsA("BasePart") then 
                            saveOriginal(pt) 
                            if pt.Size ~= Vector3.new(hitboxSize.others, hitboxSize.others, hitboxSize.others) then
                                applyHitbox(pt, hitboxSize.others, showHitbox.others, Color3.new(1,0,0)) 
                            end
                        end 
                    end 
                end 
            end 
        end
    elseif tt == "mob" then
        if tick() - (mobCache.lastScan or 0) > (isMobile and 2 or 1.5) then 
            mobCache.lastScan = tick() 
            mobCache.list = {} 
            pcall(function() 
                local folder = workspace:FindFirstChild("Enemies") or workspace
                for _,d in ipairs(folder:GetChildren()) do 
                    if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") then 
                        table.insert(mobCache.list, d) 
                    elseif d:IsA("Folder") or d.Name == "Enemies" then -- Spare check
                        for _, e in ipairs(d:GetChildren()) do
                             if e:IsA("Model") and e:FindFirstChildOfClass("Humanoid") then table.insert(mobCache.list, e) end
                        end
                    end 
                end 
            end) 
        end
        for _,m in ipairs(mobCache.list) do 
            if m.Parent and m:FindFirstChildOfClass("Humanoid") and m:FindFirstChildOfClass("Humanoid").Health > 0 then 
                for n,e in selectedBodyParts.mob do 
                    if e then 
                        local pt = m:FindFirstChild(n) 
                        if pt and pt:IsA("BasePart") then 
                            saveOriginal(pt) 
                            if pt.Size ~= Vector3.new(hitboxSize.mob, hitboxSize.mob, hitboxSize.mob) then
                                applyHitbox(pt, hitboxSize.mob, showHitbox.mob, Color3.new(1,0.65,0)) 
                            end
                        end 
                    end 
                end 
            end 
        end
    end
end
local function disableHitbox(tt)
    if tt == "self" then if char then for n,_ in selectedBodyParts.self do local p = char:FindFirstChild(n) if p then restoreHitbox(p) end end end
    elseif tt == "others" then for _,p in Players:GetPlayers() do if p.Character then for n,_ in selectedBodyParts.others do local pt = p.Character:FindFirstChild(n) if pt then restoreHitbox(pt) end end end end
    elseif tt == "mob" then pcall(function() local c = game for s in string.gmatch(mobPath, "[^%.]+") do c = c:FindFirstChild(s) or c:WaitForChild(s, 1) end for _,d in c:GetDescendants() do if d:IsA("Model") then for n,_ in selectedBodyParts.mob do local pt = d:FindFirstChild(n) if pt then restoreHitbox(pt) end end end end end) end
end

local function generateID()
    local chars, id = "0123456789abcdef", ""
    for i = 1, 8 do local r = math.random(1, 16) id = id .. chars:sub(r, r) end
    return id
end

local function encodeName(remoteName)
    local serverTime = workspace:GetServerTimeNow()
    local key = math.floor(serverTime / 10 % 10) + 1
    local encoded = ""
    for i = 1, #remoteName do
        encoded = encoded .. string.char(bit32.bxor(string.byte(remoteName, i), key))
    end
    return encoded
end

task.spawn(function()
    while true do
        pcall(function()
            local folders = {"Util", "Remotes", "Assets", "Common", "FX"}
            local found = false
            for _, fName in folders do
                local f = ReplicatedStorage:FindFirstChild(fName)
                if f then
                    for _, obj in f:GetChildren() do
                        if obj:IsA("RemoteEvent") and tonumber(obj.Name) and obj:GetAttribute("Id") then
                            proxyRemote = obj
                            found = true
                            break
                        end
                    end
                end
                if found then break end
            end
            local netMod = ReplicatedStorage:FindFirstChild("Modules")
            if netMod and netMod:FindFirstChild("Net") then
                local sRem = netMod.Net:FindFirstChild("seed")
                if sRem and sRem:IsA("RemoteFunction") then
                    local s = sRem:InvokeServer()
                    if s then seedVal = tonumber(s) end
                end
                attackRemoteDirect = netMod.Net:FindFirstChild("RE/RegisterAttack")
                hitRemoteDirect = netMod.Net:FindFirstChild("RE/RegisterHit")
            end
        end)
        task.wait(5)
    end
end)

local function getBodyPart(model)
    local parts = {"RightUpperArm", "RightFoot", "RightHand", "LeftUpperArm", "HumanoidRootPart", "Torso"}
    for _, name in parts do
        local p = model:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p end
    end
    return model:FindFirstChildOfClass("BasePart")
end
local function getTargets(): {Model}
    local targets = {}
    if not char or not char:FindFirstChild("HumanoidRootPart") then return targets end
    local myPos = char.HumanoidRootPart.Position
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, e in enemies:GetChildren() do
            if e:IsA("Model") then
                local eHRP = e:FindFirstChild("HumanoidRootPart")
                local eHum = e:FindFirstChildOfClass("Humanoid")
                if eHRP and eHum and eHum.Health > 0 then
                    local d = (myPos - eHRP.Position).Magnitude
                    if d <= auraRadius then table.insert(targets, {model = e, dist = d}) end
                end
            end
        end
    end
    for _, p in Players:GetPlayers() do
        if p ~= player and p.Character then
            local pChar = p.Character
            local pHRP = pChar:FindFirstChild("HumanoidRootPart")
            local pHum = pChar:FindFirstChildOfClass("Humanoid")
            if pHRP and pHum and pHum.Health > 0 then
                local d = (myPos - pHRP.Position).Magnitude
                if d <= auraRadius then table.insert(targets, {model = pChar, dist = d}) end
            end
        end
    end
    table.sort(targets, function(a, b) return a.dist < b.dist end)
    local result = {}
    for _, t in ipairs(targets) do table.insert(result, t.model) end
    return result
end

local function performHit()
    if not auraEnabled then return end
    local now = tick()
    if now - lastHitTime < auraDelay then return end
    lastHitTime = now
    local targets = getTargets()
    if #targets == 0 then return end
    local multiTargets, firstPart = {}, nil
    for _, model in ipairs(targets) do
        local part = getBodyPart(model)
        if part then
            if not firstPart then firstPart = part end
            table.insert(multiTargets, {model, part})
        end
    end
    if not firstPart then return end
    if auraMode == "Encode" then
        if proxyRemote and seedVal then
            local rId = tonumber(proxyRemote:GetAttribute("Id"))
            if rId then
                local atkN = encodeName("RE/RegisterAttack")
                local hitN = encodeName("RE/RegisterHit")
                local arg2 = bit32.bxor(rId + 909090, seedVal * 2)
                pcall(function()
                    proxyRemote:FireServer(atkN, arg2)
                    proxyRemote:FireServer(hitN, arg2, firstPart, multiTargets, nil, generateID())
                end)
            end
        end
        if attackRemoteDirect and hitRemoteDirect then
            pcall(function()
                attackRemoteDirect:FireServer()
                hitRemoteDirect:FireServer(firstPart, multiTargets, nil, generateID())
            end)
        end
    elseif auraMode == "Unencode" then
        if attackRemoteDirect and hitRemoteDirect then
            pcall(function()
                attackRemoteDirect:FireServer()
                hitRemoteDirect:FireServer(firstPart, multiTargets, nil, generateID())
            end)
        end
    end
end

local function applyFastM1()
    if not char then return end
    char:SetAttribute("AttackSpeedMultiplier", fastM1Enabled and fastMeleeMultiplier or 1)
    char:SetAttribute("FruitTAPCooldown", fastM1Enabled and fastFruitMultiplier or 1)
end

local function getCurrentTool()
    if char then
        for _, t in char:GetChildren() do
            if t:IsA("Tool") and t:FindFirstChild("LeftClickRemote") then
                return t, t.LeftClickRemote
            end
        end
    end
    for _, t in player.Backpack:GetChildren() do
        if t:IsA("Tool") and t:FindFirstChild("LeftClickRemote") then
            return t, t.LeftClickRemote
        end
    end
    return nil, nil
end

local function getNearestTarget()
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos, nearest, minDist = char.HumanoidRootPart.Position, nil, 9999
    if workspace:FindFirstChild("Enemies") then
        for _, e in workspace.Enemies:GetChildren() do
            if e:IsA("Model") and e:FindFirstChild("HumanoidRootPart") then
                local h = e:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then
                    local d = (myPos - e.HumanoidRootPart.Position).Magnitude
                    if d < minDist then minDist = d; nearest = e.HumanoidRootPart end
                end
            end
        end
    end
    for _, p in Players:GetPlayers() do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                local d = (myPos - p.Character.HumanoidRootPart.Position).Magnitude
                if d < minDist then minDist = d; nearest = p.Character.HumanoidRootPart end
            end
        end
    end
    return nearest
end

local function spamFruit()
    if not auraFruitEnabled then return end
    local now = tick()
    if now - lastAttack < auraFruitDelay then return end
    lastAttack = now
    local tool, remote = getCurrentTool()
    if not tool or not remote then return end
    local target = getNearestTarget()
    if not target or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local dist = (target.Position - char.HumanoidRootPart.Position).Magnitude
    if dist > auraFruitRadius then return end
    
    local dir = (target.Position - char.HumanoidRootPart.Position).Unit
    for i = 1, 5 do if selectedAttacks[i] then pcall(function() remote:FireServer(dir, i, true) end) end end
end

local boatStatusLabel
local function updateBoatSpeeds()
    if not workspace:FindFirstChild("Boats") then 
        if boatStatusLabel then boatStatusLabel.Text = "Khong thay thuyen" boatStatusLabel.TextColor3 = THEME.RED end
        return 
    end
    local count = 0
    for _, b in workspace.Boats:GetChildren() do
        local vs = b:FindFirstChild("VehicleSeat")
        if vs and vs:IsA("VehicleSeat") then vs.MaxSpeed = boatSpeed; count += 1 end
    end
    if boatStatusLabel then
        if count > 0 then boatStatusLabel.Text = "Speed: "..count.." boats" boatStatusLabel.TextColor3 = THEME.GREEN
        else boatStatusLabel.Text = "No boats" boatStatusLabel.TextColor3 = THEME.RED end
    end
end

local function clearESP() for _, b in pairs(espBillboards) do if b then b:Destroy() end end espBillboards = {} end

local function updateESP()
    for _, p in Players:GetPlayers() do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            if not espBillboards[p] or not espBillboards[p].Parent then
                local bb = Instance.new("BillboardGui", head)
                bb.Adornee = head; bb.Size = UDim2.new(0, 110, 0, 50); bb.StudsOffset = Vector3.new(0, 3.5, 0)
                bb.AlwaysOnTop = true; bb.MaxDistance = math.huge
                
                local hbBg = Instance.new("Frame", bb)
                hbBg.Name = "HPBarBg"; hbBg.Size = UDim2.new(0.9, 0, 0, 6); hbBg.Position = UDim2.new(0.05, 0, 0, 2)
                hbBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40); hbBg.BorderSizePixel = 0
                corner(hbBg, 3)
                
                local hbFill = Instance.new("Frame", hbBg)
                hbFill.Name = "HPBarFill"; hbFill.Size = UDim2.new(1, 0, 1, 0)
                hbFill.BackgroundColor3 = THEME.GREEN; hbFill.BorderSizePixel = 0
                corner(hbFill, 3)

                local nl = Instance.new("TextLabel", bb)
                nl.Name = "NameLabel"; nl.Size = UDim2.new(1, 0, 0, 20); nl.Position = UDim2.new(0, 0, 0, 10)
                nl.BackgroundTransparency = 1; nl.Text = p.Name; nl.TextColor3 = THEME.ACCENT
                nl.Font = Enum.Font.GothamBold; nl.TextSize = 12
                
                local il = Instance.new("TextLabel", bb)
                il.Name = "InfoLabel"; il.Size = UDim2.new(1, 0, 0, 15); il.Position = UDim2.new(0, 0, 0, 28)
                il.BackgroundTransparency = 1; il.Font = Enum.Font.GothamMedium; il.TextSize = 10
                espBillboards[p] = bb
            end
            
            local bb, hrp, hum = espBillboards[p], p.Character:FindFirstChild("HumanoidRootPart"), p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and char and char:FindFirstChild("HumanoidRootPart") then
                local dist = math.floor((char.HumanoidRootPart.Position - hrp.Position).Magnitude / 10)
                local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local hbBg = bb:FindFirstChild("HPBarBg")
                if hbBg then
                    hbBg.Visible = espSettings.ShowBar
                    local hbFill = hbBg:FindFirstChild("HPBarFill")
                    if hbFill then hbFill.Size = UDim2.new(hpPercent, 0, 1, 0); hbFill.BackgroundColor3 = hpPercent > 0.5 and THEME.GREEN or THEME.RED end
                end
                local il = bb:FindFirstChild("InfoLabel")
                if il then
                    il.Visible = true
                    local infoText = espSettings.ShowText and math.floor(hum.Health) .. " HP | " or ""
                    il.Text = infoText .. dist .. " m"; il.TextColor3 = Color3.new(1,1,1)
                end
            end
        end
    end
    for p, b in espBillboards do if not p or not p.Parent or not p.Character then if b then b:Destroy() end espBillboards[p] = nil end end
end

local hopStatusLabel, lastHopTime, HOP_COOLDOWN, hoppedServers = nil, 0, 10, {}

local function findTargetServer()
    local placeId = game.PlaceId
    local serverBrowser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
    if serverBrowser then
        if hopStatusLabel then hopStatusLabel.Text = "Scanning 100 pages..." end
        local allInternalServers, threads, maxPages = {}, 0, 100
        for i = 1, maxPages do
            task.spawn(function()
                local success, data = pcall(function() return serverBrowser:InvokeServer(i) end)
                if success and data then
                    for jobId, info in data do
                        local count, maxP = info.Count or 0, info.MaxPlayers or 12
                        if jobId ~= game.JobId and not table.find(hoppedServers, jobId) and count < maxP - 1 then
                            table.insert(allInternalServers, {id = jobId, playing = count})
                        end
                    end
                end
                threads = threads + 1
            end)
        end
        local start = tick()
        repeat task.wait() until threads >= maxPages or tick() - start > 4
        if #allInternalServers > 0 then
            table.sort(allInternalServers, function(a, b) return a.playing < b.playing end)
            return allInternalServers[math.random(1, math.min(#allInternalServers, 5))]
        end
    end

    local cursor, allServers = "", {}
    for i = 1, 15 do
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100&cursor=%s", placeId, cursor)
        local success, result = pcall(function() return game:HttpGet(url) end)
        if success and result then
            local decoded = HttpService:JSONDecode(result)
            if not decoded or not decoded.data then break end
            for _, s in decoded.data do
                if s.id ~= game.JobId and not table.find(hoppedServers, s.id) and (s.playing or 0) < (s.maxPlayers or 12) - 1 then
                    table.insert(allServers, s)
                end
            end
            cursor = decoded.nextPageCursor or ""
            if not cursor or cursor == "" then break end
        end
        task.wait(0.2)
    end
    if #allServers > 0 then
        table.sort(allServers, function(a, b) return a.playing < b.playing end)
        return allServers[math.random(1, math.min(#allServers, 10))]
    end
    return nil
end

local function findOldServer(mode: string): {{id: string, playing: number, maxPlayers: number}}
    local servers, cursor, attempts, maxServers = {}, "", 0, (mode == "4h") and 20 or 50
    repeat
        attempts += 1
        local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then url ..= "&cursor="..cursor end
        local success, result = pcall(function() return game:HttpGet(url) end)
        if success then
            local data = HttpService:JSONDecode(result)
            for _, s in data.data do
                if s.id ~= game.JobId and #servers < maxServers and s.playing < s.maxPlayers - 2 then
                    table.insert(servers, {id = s.id, playing = s.playing, maxPlayers = s.maxPlayers})
                end
            end
            cursor = data.nextPageCursor or ""
        else break end
        task.wait(0.1)
    until cursor == "" or #servers >= maxServers or attempts > 3
    return servers
end

local function hopToOldServer(mode)
    if not hopStatusLabel then return end
    hopStatusLabel.Text = "Scanning "..mode.."..."
    task.spawn(function()
        local oldServers = findOldServer(mode)
        if #oldServers > 0 then
            local target = oldServers[math.random(1, math.min((mode == "4h" and 3 or 10), #oldServers))]
            hopStatusLabel.Text = "Found "..mode.."! Hopping..."
            task.wait(0.5) TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, player)
        else hopStatusLabel.Text = "No server "..mode.." found" end
    end)
end

local function executeHop()
    local now = tick()
    if now - lastHopTime < HOP_COOLDOWN then
        if hopStatusLabel then hopStatusLabel.Text = "Cooldown " .. math.ceil(HOP_COOLDOWN - (now - lastHopTime)) .. "s" end
        return
    end
    lastHopTime = now
    if not hopStatusLabel then return end
    hopStatusLabel.Text = "Finding empty server..."
    task.spawn(function()
        local target = findTargetServer()
        if target then
            table.insert(hoppedServers, target.id)
            hopStatusLabel.TextColor3 = THEME.GREEN
            local attempts = 0
            repeat
                attempts += 1
                hopStatusLabel.Text = "Hopping (attempt "..attempts..")..."
                local success = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, player) end)
                if not success then task.wait(3) end
            until attempts >= 3
        else
            hopStatusLabel.Text = "No server found"
            hopStatusLabel.TextColor3 = THEME.RED
        end
    end)
end

local function findIsland(islandName)
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    local patterns = {
        ["Mirage Island"] = {"MysticIsland", "MirageIsland", "mystic", "mirage"},
        ["Kitsune Island"] = {"KitsuneIsland", "kitsune"},
        ["Prehistoric Island"] = {"PrehistoricIsland", "prehistoric"}
    }
    local targets = patterns[islandName]
    for _, n in targets do
        local obj = map:FindFirstChild(n)
        if obj and obj:IsA("Model") then return obj end
    end
    -- Fallback
    for _, child in map:GetChildren() do
        if child:IsA("Model") or child:IsA("Folder") then
            local ln = child.Name:lower()
            for _, p in targets do
                if ln:find(p:lower()) then return child end
            end
        end
    end
    return nil
end

local function updateIslandESP()
    local anyEnabled = false
    for _, v in islandEspSettings.ESP_List do if v then anyEnabled = true; break end end
    if not anyEnabled then 
        for obj, b in islandEspBillboards do if b then b:Destroy() end end 
        islandEspBillboards = {}; return 
    end
    local islandNames = {"Mirage Island", "Kitsune Island", "Prehistoric Island"}
    local currentActive = {}
    
    for _, name in islandNames do
        if islandEspSettings.ESP_List[name] then
            local obj = findIsland(name)
            if obj then
                currentActive[obj] = name
                if not islandEspBillboards[obj] or not islandEspBillboards[obj].Parent then
                    local posPart = obj:FindFirstChild("MainPart") or obj:FindFirstChildOfClass("BasePart") or obj:FindFirstChildOfClass("MeshPart")
                    if posPart then
                        local bb = Instance.new("BillboardGui", posPart)
                        bb.Name = "IslandESP"; bb.Adornee = posPart; bb.Size = UDim2.new(0, 150, 0, 40)
                        bb.AlwaysOnTop = true; bb.MaxDistance = math.huge
                        local l = Instance.new("TextLabel", bb)
                        l.Size = UDim2.new(1, 0, 1, 0); l.BackgroundTransparency = 1; l.TextColor3 = Color3.fromRGB(0, 255, 255)
                        l.Font = Enum.Font.GothamBold; l.TextSize = 14
                        Instance.new("UIStroke", l).Thickness = 2
                        islandEspBillboards[obj] = bb
                    end
                end
                local bb = islandEspBillboards[obj]
                if bb and char and char:FindFirstChild("HumanoidRootPart") then
                    local l = bb:FindFirstChildOfClass("TextLabel")
                    if l then
                        local dist = math.floor((char.HumanoidRootPart.Position - bb.Adornee.Position).Magnitude / 10)
                        l.Text = name .. "\n" .. dist .. "m"
                    end
                end
            end
        end
    end
    for obj, b in islandEspBillboards do if not currentActive[obj] then if b then b:Destroy() end islandEspBillboards[obj] = nil end end
end

-- Tabs
local TabHitbox = Nav:Tab({ Title = "j4f", Icon = "box", Border = true })
local TabSpecialFarm = Nav:Tab({ Title = "Special Farm", Icon = "star", Border = true })
local TabBlox = Nav:Tab({ Title = "Blox Fruit", Icon = "sword", Border = true })
local TabUtils = Nav:Tab({ Title = "Utils", Icon = "settings", Border = true })
local TabSettings = Nav:Tab({ Title = "Settings", Icon = "sliders-horizontal", Border = true })

-- Hitbox Tab
local currentHBT = "self"
local hbToggleUi, hbSizeUi, hbShowUi, partToggles = nil, nil, nil, {}

local HBTarget = TabHitbox:Section({ Title = "Target Settings", Box = true, Opened = true })
HBTarget:Dropdown({ Title = "Select Target", Values = {"Self", "Players", "Mobs"}, Value = "Self", Callback = function(v)
    local mapping = {["Self"]="self",["Players"]="others",["Mobs"]="mob"}
    currentHBT = mapping[v] or "self"
    if hbToggleUi then hbToggleUi:Set(hitboxEnabled[currentHBT]) end
    if hbSizeUi then hbSizeUi:Set(hitboxSize[currentHBT]) end
    if hbShowUi then hbShowUi:Set(showHitbox[currentHBT]) end
    for p, toggle in pairs(partToggles) do toggle:Set(selectedBodyParts[currentHBT][p]) end
end})

local HBCtrl = TabHitbox:Section({ Title = "Hitbox Controls", Box = true, Opened = true })
hbToggleUi = HBCtrl:Toggle({ Title = "Enabled", Value = false, Callback = function(v) hitboxEnabled[currentHBT] = v if not v then disableHitbox(currentHBT) end end })
hbSizeUi = HBCtrl:Slider({ Title = "Size", Step = 1, Value = {Min=5, Max=500, Default=10}, Callback = function(v) hitboxSize[currentHBT] = v end })
hbShowUi = HBCtrl:Toggle({ Title = "Show Hitbox", Value = false, Callback = function(v) showHitbox[currentHBT] = v end })

local HBParts = TabHitbox:Section({ Title = "Part Selection", Box = true, Opened = false })
local parts = {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg","HumanoidRootPart"}
for _, p in ipairs(parts) do
    partToggles[p] = HBParts:Toggle({ Title = p, Value = false, Callback = function(v) selectedBodyParts[currentHBT][p] = v end })
end

local HBMob = TabHitbox:Section({ Title = "Mob Settings", Box = true, Opened = false })
HBMob:Input({ Title = "Mob Path", Value = mobPath, Placeholder = "workspace.Enemies", Callback = function(v) mobPath = v end })

TabHitbox:Button({ Title = "Reset Hitbox", Color = Color3.fromHex("#ff4830"), Callback = function()
    hitboxEnabled[currentHBT], hitboxSize[currentHBT], showHitbox[currentHBT] = false, 10, false
    for p, _ in pairs(selectedBodyParts[currentHBT]) do selectedBodyParts[currentHBT][p] = false end
    disableHitbox(currentHBT)
    if hbToggleUi then hbToggleUi:Set(false) end
    if hbSizeUi then hbSizeUi:Set(10) end
    if hbShowUi then hbShowUi:Set(false) end
    for _, toggle in pairs(partToggles) do toggle:Set(false) end
end})

-- Blox Fruit Tab
local CombatSec = TabBlox:Section({ Title = "Combat Config", Box = true, Opened = true })
CombatSec:Dropdown({ Title = "Auto Equip Weapon", Values = {"Melee","Sword","Blox Fruit"}, Value = "Melee", Callback = function(v) autoEquipType = v end })
CombatSec:Space()
CombatSec:Toggle({ Title = "Aura Melee", Value = true, Callback = function(v) auraEnabled = v if v then auraConnection = RunService.Heartbeat:Connect(performHit) elseif auraConnection then auraConnection:Disconnect() auraConnection = nil end end })
if auraEnabled then auraConnection = RunService.Heartbeat:Connect(performHit) end
CombatSec:Slider({ Title = "Aura Range", Step = 1, Value = {Min=5,Max=1000,Default=1000}, Callback = function(v) auraRadius = v end })
CombatSec:Slider({ Title = "Aura Delay", Step = 0.01, Value = {Min=0.01,Max=1,Default=0.01}, Callback = function(v) auraDelay = v end })
CombatSec:Dropdown({ Title = "Aura Mode", Values = {"Unencode","Encode"}, Value = "Unencode", Callback = function(v) auraMode = v end })
CombatSec:Space()
CombatSec:Toggle({ Title = "Aura Fruit", Value = true, Callback = function(v) auraFruitEnabled = v if v then spamConnection = RunService.Heartbeat:Connect(spamFruit) elseif spamConnection then spamConnection:Disconnect() spamConnection = nil end end })
if auraFruitEnabled then spamConnection = RunService.Heartbeat:Connect(spamFruit) end
CombatSec:Slider({ Title = "Fruit Delay", Step = 0.01, Value = {Min=0.01,Max=10,Default=0.01}, Callback = function(v) auraFruitDelay = v end })
CombatSec:Dropdown({ Title = "Select Skill", Values = {"Skill 1","Skill 2","Skill 3","Skill 4","Skill 5"}, Value = "Skill 1", Callback = function(v) local s = tonumber(v:match("%d+")) for i=1,5 do selectedAttacks[i] = (i==s) end end })

local AbilitySec = TabBlox:Section({ Title = "Auto Ability", Box = true, Opened = false })
AbilitySec:Toggle({ Title = "Auto Race V3", Value = false, Callback = function(v) autoRaceV3Enabled = v end })
AbilitySec:Toggle({ Title = "Auto Active V4", Value = false, Callback = function(v) autoActiveV4Enabled = v end })
AbilitySec:Toggle({ Title = "Auto Buso", Value = true, Callback = function(v) autoBusoEnabled = v end })

local FastM1Sec = TabBlox:Section({ Title = "Fast M1", Box = true, Opened = false })
FastM1Sec:Toggle({ Title = "Enable Fast M1", Value = false, Callback = function(v) fastM1Enabled = v applyFastM1() end })
FastM1Sec:Slider({ Title = "Melee/Gun Multi", Step = 1, Value = {Min=1,Max=5,Default=1}, Callback = function(v) fastMeleeMultiplier = v applyFastM1() end })
FastM1Sec:Slider({ Title = "Fruit Multi", Step = 1, Value = {Min=1,Max=5,Default=1}, Callback = function(v) fastFruitMultiplier = v applyFastM1() end })

local IslandSec = TabBlox:Section({ Title = "Secret Island", Box = true, Opened = false })
IslandSec:Toggle({ Title = "Mirage Island ESP", Value = false, Callback = function(v) islandEspSettings.ESP_List["Mirage Island"] = v end })
IslandSec:Toggle({ Title = "Kitsune Island ESP", Value = false, Callback = function(v) islandEspSettings.ESP_List["Kitsune Island"] = v end })
IslandSec:Toggle({ Title = "Prehistoric Island ESP", Value = false, Callback = function(v) islandEspSettings.ESP_List["Prehistoric Island"] = v end })
IslandSec:Space()
IslandSec:Toggle({ Title = "Tween Mirage Island", Value = false, Callback = function(v) islandTweenEnabled["Mirage Island"] = v end })
IslandSec:Toggle({ Title = "Tween Kitsune Island", Value = false, Callback = function(v) islandTweenEnabled["Kitsune Island"] = v end })
IslandSec:Toggle({ Title = "Tween Prehistoric Island", Value = false, Callback = function(v) islandTweenEnabled["Prehistoric Island"] = v end })
IslandSec:Slider({ Title = "Tween Speed", Step = 1, Value = {Min=200,Max=500,Default=360}, Callback = function(v) islandTweenSpeed = v end })
IslandSec:Space()
IslandSec:Toggle({ Title = "Auto Chest Mirage", Value = false, Callback = function(v) autoChestMirage = v end })
IslandSec:Dropdown({ Title = "Chest Style", Values = {"TP","Tween"}, Value = "Tween", Callback = function(v) autoChestStyle = v end })
IslandSec:Dropdown({ Title = "Chest Type", Values = {"All","Fragment","Mirage"}, Value = "All", Callback = function(v) autoChestType = v end })

local TrialSec = TabBlox:Section({ Title = "Trial", Box = true, Opened = false })
TrialSec:Toggle({ Title = "Auto Upgrade Race", Value = false, Callback = function(v) autoUpgradeRaceEnabled = v end })
TrialSec:Button({ Title = "TP On Top Great Tree", Callback = function()
    pcall(function() task.spawn(function()
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local map = workspace:FindFirstChild("Map")
            if not (map and (map:FindFirstChild("Great Tree") or map:FindFirstChild("Ice Cream Island"))) then hrp.CFrame = CFrame.new(-5027,317,-3207) task.wait(2.5) end
            local treePos = Vector3.new(3035,2281,-7328)
            repeat local dt = task.wait() for _,v in ipairs(characterParts) do v.CanCollide = false end local d = (hrp.Position-treePos).Magnitude local dir = (treePos-hrp.Position).Unit if dir.X==dir.X then hrp.CFrame = hrp.CFrame+(dir*math.min((islandTweenSpeed or 360)*dt,d)) hrp.Velocity = Vector3.zero end until (hrp.Position-treePos).Magnitude < 7
            hrp.CFrame = CFrame.new(treePos)
        end
    end) end)
end})
TrialSec:Button({ Title = "TP to Ancient One", Callback = function()
    pcall(function() task.spawn(function()
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp, tp = char.HumanoidRootPart, Vector3.new(28974.22265625,14878.984375,-119.06900024414062)
            repeat local dt = task.wait() for _,v in ipairs(characterParts) do v.CanCollide = false end local d = (hrp.Position-tp).Magnitude local dir = (tp-hrp.Position).Unit if dir.X==dir.X then hrp.CFrame = hrp.CFrame+(dir*math.min((islandTweenSpeed or 360)*dt,d)) hrp.Velocity = Vector3.zero end until (hrp.Position-tp).Magnitude < 8
            hrp.CFrame = CFrame.new(tp)
        end
    end) end)
end})
TrialSec:Button({ Title = "TP to Clocks", Callback = function()
    pcall(function() task.spawn(function()
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp, tp = char.HumanoidRootPart, Vector3.new(29560.439453125,15090.95703125,-86.406005859375)
            repeat local dt = task.wait() for _,v in ipairs(characterParts) do v.CanCollide = false end local d = (hrp.Position-tp).Magnitude local dir = (tp-hrp.Position).Unit if dir.X==dir.X then hrp.CFrame = hrp.CFrame+(dir*math.min((islandTweenSpeed or 360)*dt,d)) hrp.Velocity = Vector3.zero end until (hrp.Position-tp).Magnitude < 8
            hrp.CFrame = CFrame.new(tp)
        end
    end) end)
end})

local LPSec = TabBlox:Section({ Title = "LocalPlayer", Box = true, Opened = false })
LPSec:Toggle({ Title = "Infinity Sky Jump", Value = false, Callback = function(v) infinityJumpEnabled = v if not v and char then char:SetAttribute("SkyjumpBoost", nil) end end })
LPSec:Toggle({ Title = "Jump Height Enabled", Value = false, Callback = function(v) jumpHeightEnabled = v end })
LPSec:Slider({ Title = "Jump Height", Step = 0.1, Value = {Min=7.2,Max=1000,Default=7.2}, Callback = function(v) jumpHeightValue = v end })
LPSec:Slider({ Title = "Dash Length", Step = 1, Value = {Min=0,Max=500,Default=0}, Callback = function(v) dashLengthValue = v end })
LPSec:Toggle({ Title = "Water Walk", Value = true, Callback = function(v) waterWalkEnabled = v end })
LPSec:Toggle({ Title = "Anti Water", Value = true, Callback = function(v) antiWaterEnabled = v end })

local FruitSec = TabBlox:Section({ Title = "Fruit", Box = true, Opened = false })
local function storeAllFruits()
    if not char then return end
    local items = {}
    for _, v in player.Backpack:GetChildren() do table.insert(items, v) end
    for _, v in char:GetChildren() do table.insert(items, v) end
    for _, item in items do
        if item:IsA("Tool") and item.Name:lower():find("fruit") then
            local baseName = item.Name:gsub(" Fruit", ""):gsub(" ", "")
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", baseName.."-"..baseName, item) end)
        end
    end
end
FruitSec:Toggle({ Title = "Auto Store Fruit", Value = false, Callback = function(v) autoStoreFruitEnabled = v end })
FruitSec:Button({ Title = "Store All Fruits (1 Click)", Callback = function() storeAllFruits() end })
FruitSec:Toggle({ Title = "Auto Random Fruit", Value = false, Callback = function(v) autoRandomFruitEnabled = v end })
FruitSec:Button({ Title = "Random Fruit (1 Click)", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin","Buy","DLCBoxData") end) end })

local SeaSec = TabBlox:Section({ Title = "Sea Event", Box = true, Opened = false })
local boatStatusLabel = nil
SeaSec:Slider({ Title = "Boat Speed", Step = 1, Value = {Min=200,Max=600,Default=200}, Callback = function(v) boatSpeed = v updateBoatSpeeds() end })
SeaSec:Button({ Title = "Buy Marine Boat", Callback = function() pcall(function() if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = CFrame.new(-16919,9,503) task.wait(0.1) ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("BuyBoat","MarineGrandBrigade") end end) end })
SeaSec:Button({ Title = "TP Boat to Player", Callback = function()
    pcall(function()
        local boats, hrp = workspace:FindFirstChild("Boats"), char:FindFirstChild("HumanoidRootPart")
        if boats and hrp then
            for _, boat in boats:GetChildren() do
                if boat:FindFirstChild("Owner") and tostring(boat.Owner.Value) == player.Name then
                    local op = hrp.CFrame
                    local seat = boat:FindFirstChildOfClass("VehicleSeat") or boat:FindFirstChild("VehicleSeat", true)
                    if seat then hrp.CFrame = seat.CFrame + Vector3.new(0,3,0) task.wait(0.2) hrp.CFrame = op task.wait(0.1) if flyBoatEnabled then cache.boatTarget = hrp.Position end end
                    break
                end
            end
        end
    end)
end})
local flyboatToggle
flyboatToggle = SeaSec:Toggle({ Title = "Fly Boat", Value = false, Callback = function(v)
    flyBoatEnabled = v
    if v then
        local boats = workspace:FindFirstChild("Boats")
        if not boats or not char or not char:FindFirstChild("HumanoidRootPart") then flyBoatEnabled = false if flyboatToggle then flyboatToggle:Set(false) end return end
        local hrp, closest, dist = char.HumanoidRootPart, nil, 200
        for _, boat in boats:GetChildren() do if boat:IsA("Model") then local part = boat.PrimaryPart or boat:FindFirstChildWhichIsA("BasePart") if part then local d = (part.Position - hrp.Position).Magnitude if d < dist then dist = d; closest = boat end end end end
        if closest then currentBoat = closest; cache.boatTarget = (currentBoat.PrimaryPart or currentBoat:FindFirstChildWhichIsA("BasePart")).Position
        else flyBoatEnabled = false if flyboatToggle then flyboatToggle:Set(false) end end
    else currentBoat, cache.boatTarget = nil, nil end
end})
SeaSec:Slider({ Title = "Fly Boat Speed", Step = 1, Value = {Min=100,Max=1000,Default=200}, Callback = function(v) flyBoatSpeed = v end })
SeaSec:Slider({ Title = "Boat Height", Step = 1, Value = {Min=20,Max=600,Default=125}, Callback = function(v) flyBoatHeight = v end })
SeaSec:Dropdown({ Title = "Fly Style", Values = {"Default","Custom"}, Value = "Default", Callback = function(v) flyBoatStyle = v end })
SeaSec:Button({ Title = "Remove Rocks", Callback = function() pcall(function() for _,v in workspace:GetDescendants() do if v.Name == "Rocks" then pcall(function() v:Destroy() end) end end end) end })

local ShopSec = TabBlox:Section({ Title = "Shop", Box = true, Opened = false })
ShopSec:Button({ Title = "Reset Stat (Buy)", Callback = function() pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("BlackbeardReward","Refund","2") end) end })

local DungeonSec = TabBlox:Section({ Title = "Dungeon", Box = true, Opened = false })
DungeonSec:Toggle({ Title = "Auto Dungeon", Value = false, Callback = function(v) autoDungeonEnabled = v end })

-- Special Farm Tab
local BossSec = TabSpecialFarm:Section({ Title = "Auto Boss Config", Box = true, Opened = true })
BossSec:Toggle({ Title = "Auto Boss", Value = false, Callback = function(v) autoBossEnabled = v if not v then autoBossTargetObj = nil end end })
BossSec:Toggle({ Title = "Auto Boss (Hop Server)", Value = false, Callback = function(v) autoBossHopEnabled = v end })
BossSec:Toggle({ Title = "Custom Boss (Selection)", Value = false, Callback = function(v) customBossEnabled = v end })
BossSec:Button({ Title = "Refresh Boss List", Callback = function()
    local spawns = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("EnemySpawns")
    if spawns then for _,v in spawns:GetChildren() do if v.Name:find("%[Boss%]") then if not selectedBosses[v.Name] then selectedBosses[v.Name] = false end end end end
end})

local BoneSec = TabSpecialFarm:Section({ Title = "Bone Farm", Box = true, Opened = false })
BoneSec:Toggle({ Title = "Auto Farm Bones", Value = false, Callback = function(v) autoFarmBonesEnabled = v end })
BoneSec:Toggle({ Title = "Auto Trade Bones", Value = false, Callback = function(v) autoTradeBonesEnabled = v end })

local KataSec = TabSpecialFarm:Section({ Title = "Katakuri (Cake Prince)", Box = true, Opened = false })
KataSec:Toggle({ Title = "Auto Farm Katakuri", Value = false, Callback = function(v) autoCakeFarmEnabled = v if not v then autoCakeTargetObj = nil end end })
KataSec:Toggle({ Title = "Auto Spawn Katakuri", Value = false, Callback = function(v) autoCakeSpawnEnabled = v end })

-- Utils Tab
local MoveSec = TabUtils:Section({ Title = "Movement", Box = true, Opened = true })
MoveSec:Toggle({ Title = "TP Walk", Value = false, Callback = function(v) tpEnabled = v end })
MoveSec:Slider({ Title = "TP Speed Multi", Step = 0.1, Value = {Min=1,Max=8,Default=2}, Callback = function(v) tpSpeed = v end })

local VisualSec = TabUtils:Section({ Title = "Visuals", Box = true, Opened = false })
VisualSec:Toggle({ Title = "Player ESP", Value = false, Callback = function(v) espSettings.Enabled = v if not v then clearESP() end end })
VisualSec:Toggle({ Title = "Show HP Text", Value = true, Callback = function(v) espSettings.ShowText = v end })
VisualSec:Toggle({ Title = "Show HP Bar", Value = true, Callback = function(v) espSettings.ShowBar = v end })

local OtherSec = TabUtils:Section({ Title = "Others", Box = true, Opened = true })
OtherSec:Toggle({ Title = "Anti-AFK", Value = true, Callback = function(v) antiAfkEnabled = v end })
OtherSec:Button({ Title = "Remove Fog & Effects", Callback = function()
    for _, v in Lighting:GetChildren() do if v:IsA("Atmosphere") or v.Name:find("Fog") then pcall(function() v:Destroy() end) end end
    Lighting.FogEnd, Lighting.FogStart, Lighting.GlobalShadows, Lighting.ExposureCompensation = 9e9, 0, false, 1
end})
OtherSec:Button({ Title = "Infinite Yield", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end })

local HopSec = TabUtils:Section({ Title = "Server Hopper", Box = true, Opened = false })
local hopStatusLabel = nil
HopSec:Button({ Title = "Small Server Hop", Callback = function() executeHop() end })
HopSec:Button({ Title = "Old-like (Low Population)", Callback = function() hopToOldServer("4h") end })
HopSec:Button({ Title = "Old-like (Fast Scan)", Callback = function() hopToOldServer("3h45") end })

-- Settings Tab
local SettingSec = TabSettings:Section({ Title = "Settings", Box = true, Opened = true })
SettingSec:Input({ Title = "Custom Toggle Button Icon ID", Value = "84053545044369", Placeholder = "Paste Asset ID here...", Callback = function(v)
    -- Icon ID for external use
end})

-- Runtime
local cache = { mirage = nil, kitsune = nil, prehistoric = nil, chest = nil, lastScan = 0, boatTarget = nil, boatParts = {}, touchedChests = {}, lastLootTime = 0, dState = "", dTick = 0, lastDeath = 0 }
local function updateCharParts()
    characterParts = {}
    if char then for _, v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") then table.insert(characterParts, v) end end end
end
local function setupDeathListener(c)
    local hum = c:WaitForChild("Humanoid", 10)
    if hum then hum.Died:Connect(function() cache.lastDeath = tick() end) end
    updateCharParts()
end
player.CharacterAdded:Connect(function(c) updateCharParts() c.AttributeChanged:Connect(function() updateCharParts() end) end)
if player.Character then updateCharParts() player.Character.AttributeChanged:Connect(function() updateCharParts() end) end

local dungeonCache = { charParts = {}, lastPartsCached = 0, baseHeight = 13, lastHeightCalc = 0, stuckTimer = 0, lastPosition = nil, mapChildCount = 0 }

RunService.Heartbeat:Connect(function(dt)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    for name, enabled in islandTweenEnabled do
        if enabled then
            local obj = (name == "Mirage Island" and cache.mirage) or (name == "Kitsune Island" and cache.kitsune) or (name == "Prehistoric Island" and cache.prehistoric)
            if obj then
                local posPart = obj:FindFirstChild("MainPart", true) or obj:FindFirstChildWhichIsA("BasePart", true) or obj.PrimaryPart
                if posPart then
                    for _, v in ipairs(characterParts) do v.CanCollide = false end
                    hrp.Velocity *= 0.1
                    local target = posPart.Position + Vector3.new(0, 250, 0)
                    local dist = (hrp.Position - target).Magnitude
                    if dist > 5 then hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, target) * CFrame.new(0, 0, -dist), math.min((islandTweenSpeed * dt) / dist, 1)) end
                end
            end
        end
    end

    if autoChestMirage and cache.mirage then
        for _, v in ipairs(characterParts) do v.CanCollide = false end
        hrp.Velocity *= 0.1
        local miragePos = cache.mirage:GetModelCFrame().Position
        local distToMirage = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(miragePos.X, miragePos.Z)).Magnitude
        if distToMirage > 1500 then
            local tp = miragePos + Vector3.new(0, 250, 0)
            local d = (hrp.Position - tp).Magnitude
            if d > 5 then hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, tp) * CFrame.new(0,0,-d), math.min((islandTweenSpeed*dt)/d,1)) end
        elseif cache.chest then
            local tp = cache.chest.Position
            local dc = (hrp.Position - tp).Magnitude
            if autoChestStyle == "TP" then
                if tick() - cache.lastLootTime >= 1.5 then hrp.CFrame = CFrame.new(tp) if dc < 5 then cache.touchedChests[cache.chest.Parent] = true; cache.chest = nil; cache.lastLootTime = tick() end end
            else
                local hD = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(tp.X, tp.Z)).Magnitude
                local fT = (hD > 50) and Vector3.new(tp.X, 250, tp.Z) or tp
                local tD = (hrp.Position - fT).Magnitude
                if hD <= 50 and tD < 5 then cache.touchedChests[cache.chest.Parent] = true; cache.chest = nil
                elseif tD > 5 then hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, fT) * CFrame.new(0,0,-tD), math.min((islandTweenSpeed*dt)/tD,1)) end
            end
        else
            local tp = miragePos + Vector3.new(0, 250, 0)
            local d = (hrp.Position - tp).Magnitude
            if d > 5 then hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, tp) * CFrame.new(0,0,-d), math.min((islandTweenSpeed*dt)/d,1)) end
        end
    end

    if flyBoatEnabled and currentBoat and currentBoat.Parent then
        local seat = currentBoat:FindFirstChildOfClass("VehicleSeat") or currentBoat:FindFirstChild("VehicleSeat", true)
        isPlayerOnBoat = (seat and seat.Occupant ~= nil)
        if isPlayerOnBoat then
            if not cache.boatTarget then cache.boatTarget = hrp.Position end
            if #cache.boatParts == 0 then for _, v in ipairs(currentBoat:GetDescendants()) do if v:IsA("BasePart") then table.insert(cache.boatParts, v) end end end
            local cam, moveDir = workspace.CurrentCamera, Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
            if moveDir.Magnitude > 0 then cache.boatTarget += moveDir.Unit * flyBoatSpeed * dt end
            for _, v in ipairs(cache.boatParts) do v.Anchored, v.Velocity, v.RotVelocity = false, Vector3.zero, Vector3.zero end
            if flyBoatStyle == "Custom" then hrp.CFrame = CFrame.lookAt(cache.boatTarget, cache.boatTarget + cam.CFrame.LookVector)
            else cache.boatTarget = Vector3.new(cache.boatTarget.X, flyBoatHeight, cache.boatTarget.Z) hrp.CFrame = CFrame.new(cache.boatTarget) * CFrame.lookAt(Vector3.zero, Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)).Rotation end
        else
            cache.boatTarget = (currentBoat.PrimaryPart or currentBoat:FindFirstChildWhichIsA("BasePart")).Position
            for _, v in ipairs(cache.boatParts) do if not v.Anchored then v.Anchored = true end end
        end
    end

    if fastM1Enabled then applyFastM1() end
    if tpEnabled and hum.MoveDirection.Magnitude > 0 then local extra = (tpSpeed-1)*hum.WalkSpeed if extra > 0 then hrp.CFrame += hum.MoveDirection*extra*dt end end
    if waterWalkEnabled then
        if antiWaterEnabled and hrp.Position.Y < antiWaterThreshold then hrp.Velocity = Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z) hrp.CFrame = CFrame.new(hrp.Position.X,1,hrp.Position.Z) end
        if lastFoamState ~= true then pcall(function() workspace._WorldOrigin["Foam;"].CanCollide = true end) lastFoamState = true end
    elseif lastFoamState ~= false then pcall(function() workspace._WorldOrigin["Foam;"].CanCollide = false end) lastFoamState = false end
    if infinityJumpEnabled then char:SetAttribute("SkyjumpBoost", 3000) end
    if dashLengthValue > 0 then char:SetAttribute("DashLength", dashLengthValue) end
    if hum then if jumpHeightEnabled then hum.UseJumpPower, hum.JumpHeight = false, jumpHeightValue else hum.UseJumpPower = true end end

    -- Boss/Bone/Cake tween
    local function tweenToTarget(target)
        if not target then return end
        local tH = target:IsA("Model") and target:FindFirstChildOfClass("Humanoid")
        if tH and tH.Health <= 0 then return false end
        local tp = target:IsA("Model") and (target.PrimaryPart or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")) or target
        if tp then
            for _, v in ipairs(characterParts) do v.CanCollide = false end
            hrp.Velocity = Vector3.zero
            local tPos = tp.Position + Vector3.new(0, safeHeight, 0)
            local d = (hrp.Position - tPos).Magnitude
            if d > 0.5 then local spd = (d<140) and 1300 or 360 local dir = (tPos-hrp.Position).Unit if dir.X==dir.X then hrp.CFrame += dir*math.min(spd*dt,d) end end
        end
        return true
    end
    if autoBossEnabled and autoBossTargetObj then if not tweenToTarget(autoBossTargetObj) then autoBossTargetObj = nil end
    elseif autoFarmBonesEnabled and autoBoneTargetObj then if not tweenToTarget(autoBoneTargetObj) then autoBoneTargetObj = nil end end
    if autoCakeFarmEnabled and autoCakeTargetObj then if not tweenToTarget(autoCakeTargetObj) then autoCakeTargetObj = nil end end
end)

-- Scheduler
task.spawn(function()
    while true do
        local dt = task.wait(0.1)
        if autoDungeonEnabled and char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local myHRP = char.HumanoidRootPart
                local dungeonMap = workspace.Map:FindFirstChild("Dungeon")
                local enemies = (workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren()) or {}
                local function spamAllPortals()
                    if dungeonMap then for _, room in dungeonMap:GetChildren() do local portal = room:FindFirstChild("ExitTeleporter") or room:FindFirstChild("ExitTeleport") local root = portal and portal:FindFirstChild("Root") if root then pcall(function() firetouchinterest(myHRP, root, 0) firetouchinterest(myHRP, root, 1) end) end end end
                end
                if (tick()-cache.lastDeath < 5) or (tick()-cache.dTick < 2) then spamAllPortals() end
                local nearestDist, bestTarget = math.huge, nil
                for _, e in ipairs(enemies) do
                    local eHRP, eHum = e:FindFirstChild("HumanoidRootPart"), e:FindFirstChildOfClass("Humanoid")
                    if eHRP and eHum and eHum.Health > 0 and not (e.Name:lower():find("shadow") or e.Name:lower():find("blank")) then
                        local isPriority = (e.Name == "PropHitboxPlaceholder")
                        local d = (myHRP.Position - eHRP.Position).Magnitude
                        if (isPriority and 0 or d) < nearestDist then nearestDist = (isPriority and 0 or d); bestTarget = eHRP end
                        if isPriority then break end
                    end
                end
                if bestTarget then
                    local tp = bestTarget.Position + Vector3.new(0, dungeonCache.baseHeight, 0)
                    for _, v in ipairs(characterParts) do v.CanCollide = false end myHRP.Velocity = Vector3.zero
                    local d = (myHRP.Position - tp).Magnitude
                    if d > 0.1 then local spd = (d<5) and 150 or (d<25 and 450 or 350) local a = math.clamp((spd*dt)/d,0,0.8) local lk = Vector3.new(tp.X,myHRP.Position.Y,tp.Z) myHRP.CFrame = myHRP.CFrame:Lerp(CFrame.new(myHRP.Position,lk)*CFrame.new(0,0,-d)*CFrame.new(0,tp.Y-myHRP.Position.Y,0),a) end
                else spamAllPortals() end
            end)
        end

        if autoBossEnabled and char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local myHRP = char.HumanoidRootPart
                local foundTarget, minDist = nil, math.huge
                local spawns = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("EnemySpawns")
                if spawns then for _, s in spawns:GetChildren() do if s.Name:find("%[Boss%]") then local cn = s.Name:gsub("%[.-%]",""):match("^%s*(.-)%s*$") masterBossList[cn] = s.Name end end end
                local enemies = workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}
                for _, e in ipairs(enemies) do
                    local cn = e.Name:gsub("%[.-%]",""):match("^%s*(.-)%s*$")
                    local fn = masterBossList[cn] or (e.Name:find("%[Boss%]") and e.Name)
                    if fn and (not customBossEnabled or selectedBosses[fn]) then
                        local h = e:FindFirstChildOfClass("Humanoid")
                        if h and h.Health > 0 then local d = (myHRP.Position-e.HumanoidRootPart.Position).Magnitude if d < minDist then minDist = d; foundTarget = e end end
                    end
                end
                if foundTarget then autoBossTargetObj = foundTarget; lastBossDeadTime = 0
                else
                    local spT, spD = nil, math.huge
                    if spawns then for _, s in spawns:GetChildren() do if s.Name:find("%[Boss%]") and (not customBossEnabled or selectedBosses[s.Name]) then local d = (myHRP.Position-s.Position).Magnitude if d < spD then spD = d; spT = s end end end end
                    if spT then autoBossTargetObj = spT; lastBossDeadTime = 0
                    else autoBossTargetObj = nil; if autoBossHopEnabled then if lastBossDeadTime == 0 then lastBossDeadTime = tick() end if tick()-lastBossDeadTime > 5 then executeHop(); lastBossDeadTime = 0 end end end
                end
            end)
        end

        if autoFarmBonesEnabled and char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local myHRP = char.HumanoidRootPart
                local ft, md = nil, math.huge
                local function isBone(n) for _,m in boneMobs do if n:find(m) then return true end end return false end
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then for _, e in enemies:GetChildren() do if isBone(e.Name) then local h = e:FindFirstChildOfClass("Humanoid") if h and h.Health > 0 and e:FindFirstChild("HumanoidRootPart") then local d = (myHRP.Position-e.HumanoidRootPart.Position).Magnitude if d < md then md = d; ft = e end end end end end
                if ft then autoBoneTargetObj = ft
                else
                    local sp, sd = nil, math.huge
                    local spawns = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("EnemySpawns")
                    if spawns then for _, s in spawns:GetChildren() do if isBone(s.Name) then local d = (myHRP.Position-s.Position).Magnitude if d < sd then sd = d; sp = s end end end end
                    autoBoneTargetObj = sp
                end
            end)
        else autoBoneTargetObj = nil end

        if autoCakeFarmEnabled and char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local myHRP = char.HumanoidRootPart
                local ft = nil
                local enemies, map = workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("Map")
                local mirror = map and map:FindFirstChild("MirrorDimension")
                local function findCake(n) if enemies then for _, e in enemies:GetChildren() do if e.Name:find(n) then local h = e:FindFirstChildOfClass("Humanoid") if h and h.Health > 0 and e:FindFirstChild("HumanoidRootPart") then return e end end end end return nil end
                if mirror then ft = findCake("Cake Prince") if not ft then ft = mirror.PrimaryPart or mirror:FindFirstChildWhichIsA("BasePart") or mirror end
                else
                    local md = math.huge
                    if enemies then for _, e in enemies:GetChildren() do local nm = false for i=2,#cakeMobs do if e.Name:find(cakeMobs[i]) then nm = true break end end if nm then local h = e:FindFirstChildOfClass("Humanoid") if h and h.Health > 0 and e:FindFirstChild("HumanoidRootPart") then local d = (myHRP.Position-e.HumanoidRootPart.Position).Magnitude if d < md then md = d; ft = e end end end end end
                    if not ft then local spawns = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("EnemySpawns") if spawns then local sd = math.huge for _, s in spawns:GetChildren() do local nm = false for i=2,#cakeMobs do if s.Name:find(cakeMobs[i]) then nm = true break end end if nm then local d = (myHRP.Position-s.Position).Magnitude if d < sd then sd = d; ft = s end end end end end
                end
                autoCakeTargetObj = ft
            end)
        else autoCakeTargetObj = nil end

        if char and char:FindFirstChild("HumanoidRootPart") then
            local target = autoBossTargetObj or autoBoneTargetObj or autoCakeTargetObj
            if target then
                local tP = target:IsA("Model") and (target.PrimaryPart or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")) or target
                if tP and (char.HumanoidRootPart.Position - tP.Position).Magnitude < 150 then
                    local bp = player:FindFirstChild("Backpack")
                    local function eq(tt) local tool = nil for _,t in char:GetChildren() do if t:IsA("Tool") and t.ToolTip==tt then tool = t break end end if not tool and bp then for _,t in bp:GetChildren() do if t:IsA("Tool") and t.ToolTip==tt then tool = t char.Humanoid:EquipTool(t) break end end end if tool then pcall(function() local ev = tool:FindFirstChild("EquipEvent") if ev then ev:FireServer(true) end end) end end
                    eq(autoEquipType)
                end
            end
        end
        if espSettings.Enabled then updateESP() end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then safeHeight = (root:FindFirstChild("Buddha") or root:FindFirstChild("Buddha2")) and 35 or 15 end
        if autoBusoEnabled and char and not char:FindFirstChild("HasBuso") then pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end) end
        for t, e in pairs(hitboxEnabled) do if e then expandHitbox(t) end end
        updateBoatSpeeds()
        updateIslandESP()
        if autoChestMirage or islandEspSettings.Enabled then
            cache.mirage = findIsland("Mirage Island") cache.kitsune = findIsland("Kitsune Island") cache.prehistoric = findIsland("Prehistoric Island")
            if autoChestMirage and cache.mirage then
                local cf = workspace:FindFirstChild("ChestModels")
                if cf then for _, ch in cf:GetChildren() do if not cache.touchedChests[ch] then local n = ch.Name:lower() if autoChestType=="All" or (autoChestType=="Fragment" and n:find("fragment")) or (autoChestType=="Mirage" and n:find("mirage")) then local p = ch:FindFirstChildWhichIsA("BasePart") or ch.PrimaryPart if p then cache.chest = p; break end end end end if #cf:GetChildren()==0 or tick()%300<1 then cache.touchedChests = {} end end
            end
        end
    end
end)

task.spawn(function() while true do task.wait(1) if autoCakeSpawnEnabled then pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("CakePrinceSpawner", true) task.wait(0.1) ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("CakePrinceSpawner") end) end end end)

local autoRandomFruitEnabled = false
local last10s, last2s = 0, 0
task.spawn(function()
    while true do
        task.wait(1)
        local now = tick()
        if autoRaceV3Enabled then pcall(function() ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility") end) end
        if autoStoreFruitEnabled then storeAllFruits() end
        if autoUpgradeRaceEnabled then pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("UpgradeRace","Buy") end) end
        if autoActiveV4Enabled then pcall(function() local c = player.Character if c then local aw = player.Backpack:FindFirstChild("Awakening") or c:FindFirstChild("Awakening") if aw then local rf = aw:FindFirstChild("RemoteFunction",true) if rf then pcall(function() rf:InvokeServer(true) end) end end end end) end
        if autoTradeBonesEnabled and now-last2s >= 2 then last2s = now pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("Bones","Buy",1,1) end) end
        if autoRandomFruitEnabled and now-last10s >= 10 then last10s = now pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin","Buy","DLCBoxData") end) end
        if now % 1200 < 1 then hoppedServers = {} end
    end
end)

player.Idled:Connect(function()
    if antiAfkEnabled then pcall(function() VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame) task.wait(1) VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end) end
end)

Window:SelectTab(1)

-- Toggle GUI: RightControl
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        Window:ToggleWindow()
    end
end)
