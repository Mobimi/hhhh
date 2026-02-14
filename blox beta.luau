local Players, RunService, UserInputService, CoreGui, ReplicatedStorage, TweenService, HttpService, TeleportService, Lighting, VirtualUser = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("CoreGui"), game:GetService("ReplicatedStorage"), game:GetService("TweenService"), game:GetService("HttpService"), game:GetService("TeleportService"), game:GetService("Lighting"), game:GetService("VirtualUser")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(c) char = c end)
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
local autoRandomFruitEnabled = false
-- Load RedzUI Library
local redzlib = loadstring(game:HttpGet("https://raw.githubusercontent.com/hihiae/36var/refs/heads/main/RedzUi5s"))()

local Window = redzlib:MakeWindow({
    Name = "j4f",
    SubTitle = "by tiktok: @realayako",
    SaveFolder = "j4f_config"
})

-- Toggle Button (show/hide GUI)
local ToggleBtnInfo = Window:AddMinimizeButton({
    Button = {
        Image = "rbxassetid://84053545044369",
        Size = UDim2.fromOffset(45, 45), -- Thu nhỏ nút lại
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        BackgroundTransparency = 0.2
    }
})
local ToggleBtn = ToggleBtnInfo.Button
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 10)
local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Color = Color3.fromRGB(255, 215, 0)
ToggleStroke.Thickness = 1.5
ToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Logic
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
                local folder = game
                for s in string.gmatch(mobPath, "[^%.]+") do folder = folder:FindFirstChild(s) or folder:WaitForChild(s, 1) end
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
        if boatStatusLabel then boatStatusLabel.Text = "❌ Không thấy thuyền" boatStatusLabel.TextColor3 = THEME.RED end
        return 
    end
    local count = 0
    for _, b in workspace.Boats:GetChildren() do
        local vs = b:FindFirstChild("VehicleSeat")
        if vs and vs:IsA("VehicleSeat") then vs.MaxSpeed = boatSpeed; count += 1 end
    end
    if boatStatusLabel then
        if count > 0 then boatStatusLabel.Text = "✅ Đang tăng tốc: "..count.." thuyền" boatStatusLabel.TextColor3 = THEME.GREEN
        else boatStatusLabel.Text = "❌ Không có thuyền nào" boatStatusLabel.TextColor3 = THEME.RED end
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
        if hopStatusLabel then hopStatusLabel.Text = "🚀 Đang săn server vắng (100 trang)..." end
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
    hopStatusLabel.Text = "🔍 Đang săn server "..mode.."..."
    task.spawn(function()
        local oldServers = findOldServer(mode)
        if #oldServers > 0 then
            local target = oldServers[math.random(1, math.min((mode == "4h" and 3 or 10), #oldServers))]
            hopStatusLabel.Text = "✅ Đã thấy "..mode.."! Đang nhảy..."
            task.wait(0.5) TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, player)
        else hopStatusLabel.Text = "❌ Không tìm thấy server "..mode.."!" end
    end)
end

local function executeHop()
    local now = tick()
    if now - lastHopTime < HOP_COOLDOWN then
        if hopStatusLabel then hopStatusLabel.Text = "⏳ Chờ " .. math.ceil(HOP_COOLDOWN - (now - lastHopTime)) .. "s..." end
        return
    end
    lastHopTime = now
    if not hopStatusLabel then return end
    hopStatusLabel.Text = "🔍 Đang tìm server vắng mới..."
    task.spawn(function()
        local target = findTargetServer()
        if target then
            table.insert(hoppedServers, target.id)
            hopStatusLabel.TextColor3 = THEME.GREEN
            local attempts = 0
            repeat
                attempts += 1
                hopStatusLabel.Text = "✅ Đang nhảy (Lần "..attempts..")..."
                local success = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, player) end)
                if not success then task.wait(3) end
            until attempts >= 3
        else
            hopStatusLabel.Text = "❌ Không tìm thấy server mới!"
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
    -- Fallback loop stricter
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

local TabHitbox = Window:MakeTab({Title = "j4f", Icon = "crosshair"})
local TabSpecialFarm = Window:MakeTab({Title = "Special Farm", Icon = "bomb"})
local TabBlox = Window:MakeTab({Title = "Blox Fruit", Icon = "swords"})
local TabUtils = Window:MakeTab({Title = "Utils", Icon = "cog"})
local TabSettings = Window:MakeTab({Title = "Settings", Icon = "settings"})

-- HITBOX TAB
local currentHBT = "self"
local hbToggleUi, hbSizeUi, hbShowUi, partToggles = nil, nil, nil, {}

TabHitbox:AddSection({Name = "Target Settings"})
TabHitbox:AddDropdown({
    Title = "Select Target",
    Options = {"Self", "Players", "Mobs"},
    Default = "Self",
    Callback = function(v)
        local mapping = {["Self"] = "self", ["Players"] = "others", ["Mobs"] = "mob"}
        currentHBT = mapping[v] or "self"
        if hbToggleUi then hbToggleUi:Set(hitboxEnabled[currentHBT]) end
        if hbSizeUi then hbSizeUi:Set(hitboxSize[currentHBT]) end
        if hbShowUi then hbShowUi:Set(showHitbox[currentHBT]) end
        for p, toggle in pairs(partToggles) do toggle:Set(selectedBodyParts[currentHBT][p]) end
    end
})

TabHitbox:AddSection({Name = "Hitbox Controls"})
hbToggleUi = TabHitbox:AddToggle({Title = "Enabled", Default = false, Callback = function(v) hitboxEnabled[currentHBT] = v if not v then disableHitbox(currentHBT) end end})
hbSizeUi = TabHitbox:AddSlider({Title = "Size", Min = 5, Max = 500, Default = 10, Increase = 1, Callback = function(v) hitboxSize[currentHBT] = v end})
hbShowUi = TabHitbox:AddToggle({Title = "Show Hitbox", Default = false, Callback = function(v) showHitbox[currentHBT] = v end})

TabHitbox:AddSection({Name = "Part Selection"})
local parts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart"}
for _, p in ipairs(parts) do 
    partToggles[p] = TabHitbox:AddToggle({Title = p, Default = false, Callback = function(v) selectedBodyParts[currentHBT][p] = v end})
end

TabHitbox:AddSection({Name = "Mob Settings"})
TabHitbox:AddTextBox({Title = "Mob Path", Default = mobPath, PlaceholderText = "workspace.Enemies", Callback = function(v) mobPath = v end})

TabHitbox:AddSection({Name = "Danger Zone"})
TabHitbox:AddButton({Title = "Reset Hitbox Configuration", Callback = function()
    hitboxEnabled[currentHBT], hitboxSize[currentHBT], showHitbox[currentHBT] = false, 10, false
    for p, _ in pairs(selectedBodyParts[currentHBT]) do selectedBodyParts[currentHBT][p] = false end
    disableHitbox(currentHBT)
    if hbToggleUi then hbToggleUi:Set(false) end
    if hbSizeUi then hbSizeUi:Set(10) end
    if hbShowUi then hbShowUi:Set(false) end
    for p, toggle in pairs(partToggles) do toggle:Set(false) end
end})

-- BLOX FRUIT TAB
TabBlox:AddSection({Name = "Combat Config"})

-- Auto Equip
TabBlox:AddDropdown({Title = "Auto Equip Weapon", Options = {"Melee", "Sword", "Blox Fruit"}, Default = "Melee", Callback = function(v) autoEquipType = v end})

-- Aura Melee
TabBlox:AddSection({Name = "Aura Melee"})
TabBlox:AddToggle({Title = "Aura Melee Enabled", Default = true, Callback = function(v) auraEnabled = v if v then auraConnection = RunService.Heartbeat:Connect(performHit) elseif auraConnection then auraConnection:Disconnect() auraConnection = nil end end})
if auraEnabled then auraConnection = RunService.Heartbeat:Connect(performHit) end
TabBlox:AddSlider({Title = "Range", Min = 5, Max = 1000, Default = 1000, Increase = 1, Callback = function(v) auraRadius = v end})
TabBlox:AddSlider({Title = "Delay", Min = 0.01, Max = 1, Default = 0.01, Increase = 0.01, Callback = function(v) auraDelay = v end})
TabBlox:AddDropdown({Title = "Mode", Options = {"Fast Attack Unencode", "Fast Attack Encode"}, Default = "Fast Attack Unencode", Callback = function(v) auraMode = v:find("Encode") and "Encode" or "Unencode" end})

-- Aura Fruit
TabBlox:AddSection({Name = "Aura Fruit"})
TabBlox:AddToggle({Title = "Aura Fruit Enabled", Default = true, Callback = function(v) auraFruitEnabled = v if v then spamConnection = RunService.Heartbeat:Connect(spamFruit) elseif spamConnection then spamConnection:Disconnect() spamConnection = nil end end})
if auraFruitEnabled then spamConnection = RunService.Heartbeat:Connect(spamFruit) end
TabBlox:AddSlider({Title = "Fruit Delay", Min = 0.01, Max = 10, Default = 0.01, Increase = 0.01, Callback = function(v) auraFruitDelay = v end})
TabBlox:AddDropdown({Title = "Select Skill", Options = {"Skill 1", "Skill 2", "Skill 3", "Skill 4", "Skill 5"}, Default = "Skill 1", Callback = function(v) local s = tonumber(v:match("%d+")) for i = 1, 5 do selectedAttacks[i] = (i == s) end end})

-- Auto Ability
TabBlox:AddSection({Name = "Auto Ability"})
TabBlox:AddToggle({Title = "Auto Race V3", Default = false, Callback = function(v) autoRaceV3Enabled = v end})
TabBlox:AddToggle({Title = "Auto Active V4", Default = false, Callback = function(v) autoActiveV4Enabled = v end})
TabBlox:AddToggle({Title = "Auto Buso", Default = true, Callback = function(v) autoBusoEnabled = v end})

-- Fast M1
TabBlox:AddSection({Name = "Fast M1"})
TabBlox:AddToggle({Title = "Enable Fast M1", Default = false, Callback = function(v) fastM1Enabled = v applyFastM1() end})
TabBlox:AddSlider({Title = "Melee/Gun Multi", Min = 1, Max = 5, Default = 1, Increase = 1, Callback = function(v) fastMeleeMultiplier = math.floor(v + 0.5) applyFastM1() end})
TabBlox:AddSlider({Title = "Fruit Multi", Min = 1, Max = 5, Default = 1, Increase = 1, Callback = function(v) fastFruitMultiplier = math.floor(v + 0.5) applyFastM1() end})

-- Bone Farm (Special Farm Tab)
TabSpecialFarm:AddSection({Name = "Bone Farm"})
TabSpecialFarm:AddToggle({Title = "Auto Farm Bones", Default = false, Callback = function(v) autoFarmBonesEnabled = v end})
TabSpecialFarm:AddToggle({Title = "Auto Trade Bones", Default = false, Callback = function(v) autoTradeBonesEnabled = v end})

TabBlox:AddSection({Name = "Secret Island"})
TabBlox:AddToggle({Title = "Mirage Island ESP", Default = false, Callback = function(v) islandEspSettings.ESP_List["Mirage Island"] = v end})
TabBlox:AddToggle({Title = "Kitsune Island ESP", Default = false, Callback = function(v) islandEspSettings.ESP_List["Kitsune Island"] = v end})
TabBlox:AddToggle({Title = "Prehistoric Island ESP", Default = false, Callback = function(v) islandEspSettings.ESP_List["Prehistoric Island"] = v end})

TabBlox:AddSection({Name = "Island Tween"})
local function islandTween(islandName, enabled) islandTweenEnabled[islandName] = enabled end
TabBlox:AddToggle({Title = "Tween Mirage Island", Default = false, Callback = function(v) islandTween("Mirage Island", v) end})
TabBlox:AddToggle({Title = "Tween Kitsune Island", Default = false, Callback = function(v) islandTween("Kitsune Island", v) end})
TabBlox:AddToggle({Title = "Tween Prehistoric Island", Default = false, Callback = function(v) islandTween("Prehistoric Island", v) end})
TabBlox:AddSlider({Title = "Tween Speed", Min = 200, Max = 500, Default = 360, Increase = 1, Callback = function(v) islandTweenSpeed = v end})

TabBlox:AddSection({Name = "Auto Chest Mirage"})
TabBlox:AddToggle({Title = "Enabled Auto Chest", Default = false, Callback = function(v) autoChestMirage = v end})
TabBlox:AddDropdown({Title = "Chest Style", Options = {"TP", "Tween"}, Default = "Tween", Callback = function(v) autoChestStyle = v end})
TabBlox:AddDropdown({Title = "Chest Type", Options = {"All", "Fragment", "Mirage"}, Default = "All", Callback = function(v) autoChestType = v end})

TabBlox:AddSection({Name = "Trial"})
TabBlox:AddToggle({Title = "Auto Upgrade Race", Default = false, Callback = function(v) autoUpgradeRaceEnabled = v end})
TabBlox:AddButton({Title = "TP On Top Great Tree", Callback = function()
    pcall(function()
        task.spawn(function()
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local map = workspace:FindFirstChild("Map")
                local isNear = map and (map:FindFirstChild("Great Tree") or map:FindFirstChild("Ice Cream Island"))
                
                if not isNear then
                    -- Bước 1: Dịch chuyển vào tâm Cổng Castle
                    hrp.CFrame = CFrame.new(-5027, 317, -3207)
                    -- Bước 2: Chờ qua Hydra
                    task.wait(2.5)
                end
                
                -- Bước 3: Tween lên đỉnh Great Tree với Noclip
                local treePos = Vector3.new(3035, 2281, -7328)
                repeat
                    local dt = task.wait()
                    -- Kích hoạt Noclip xuyên núi
                    for _, v in ipairs(characterParts) do v.CanCollide = false end
                    
                    local dist = (hrp.Position - treePos).Magnitude
                    local speed = islandTweenSpeed or 360
                    local moveDist = math.min(speed * dt, dist)
                    local direction = (treePos - hrp.Position).Unit
                    if direction.X == direction.X then 
                        hrp.CFrame = hrp.CFrame + (direction * moveDist)
                        hrp.Velocity = Vector3.new(0,0,0)
                    end
                until (hrp.Position - treePos).Magnitude < 7
                hrp.CFrame = CFrame.new(treePos)
            end
        end)
    end)
end})

TabBlox:AddButton({Title = "TP to Ancient One", Callback = function()
    pcall(function()
        task.spawn(function()
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local targetPos = Vector3.new(28974.22265625, 14878.984375, -119.06900024414062)
                
                -- Bắt đầu lướt gió xuyên vật thể ngay lập tức
                repeat
                    local dt = task.wait()
                    -- Noclip Mode ON
                    for _, v in ipairs(characterParts) do v.CanCollide = false end
                    
                    local dist = (hrp.Position - targetPos).Magnitude
                    local speed = islandTweenSpeed or 360
                    local moveDist = math.min(speed * dt, dist)
                    local direction = (targetPos - hrp.Position).Unit
                    
                    if direction.X == direction.X then 
                        hrp.CFrame = hrp.CFrame + (direction * moveDist)
                        hrp.Velocity = Vector3.new(0,0,0)
                    end
                until (hrp.Position - targetPos).Magnitude < 8
                hrp.CFrame = CFrame.new(targetPos)
            end
        end)
    end)
end})

TabBlox:AddButton({Title = "TP to Clocks", Callback = function()
    pcall(function()
        task.spawn(function()
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local targetPos = Vector3.new(29560.439453125, 15090.95703125, -86.406005859375)
                
                -- Bắt đầu lướt gió xuyên vật thể ngay lập tức
                repeat
                    local dt = task.wait()
                    -- Noclip Mode ON
                    for _, v in ipairs(characterParts) do v.CanCollide = false end
                    
                    local dist = (hrp.Position - targetPos).Magnitude
                    local speed = islandTweenSpeed or 360
                    local moveDist = math.min(speed * dt, dist)
                    local direction = (targetPos - hrp.Position).Unit
                    
                    if direction.X == direction.X then 
                        hrp.CFrame = hrp.CFrame + (direction * moveDist)
                        hrp.Velocity = Vector3.new(0,0,0)
                    end
                until (hrp.Position - targetPos).Magnitude < 8
                hrp.CFrame = CFrame.new(targetPos)
            end
        end)
    end)
end})

-- SPECIAL FARM TAB (Boss)
TabSpecialFarm:AddSection({Name = "Auto Boss Config"})
TabSpecialFarm:AddToggle({Title = "Auto Boss", Default = false, Callback = function(v) autoBossEnabled = v if not v then autoBossTargetObj = nil end end})
TabSpecialFarm:AddToggle({Title = "Auto Boss (Hop Server)", Default = false, Callback = function(v) autoBossHopEnabled = v end})
TabSpecialFarm:AddToggle({Title = "Custom Boss (Selection)", Default = false, Callback = function(v) customBossEnabled = v end})

TabSpecialFarm:AddSection({Name = "Katakuri (Cake Prince) Farm"})
TabSpecialFarm:AddToggle({Title = "Auto Farm Katakuri", Default = false, Callback = function(v) autoCakeFarmEnabled = v if not v then autoCakeTargetObj = nil end end})
TabSpecialFarm:AddToggle({Title = "Auto Spawn Katakuri", Default = false, Callback = function(v) autoCakeSpawnEnabled = v end})

local cache = { mirage = nil, kitsune = nil, prehistoric = nil, chest = nil, lastScan = 0, boatTarget = nil, boatParts = {}, touchedChests = {}, lastLootTime = 0, dState = "", dTick = 0, lastDeath = 0 }
local function updateCharParts()
    characterParts = {}
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then table.insert(characterParts, v) end
        end
    end
end
local function setupDeathListener(c)
    local hum = c:WaitForChild("Humanoid", 10)
    if hum then hum.Died:Connect(function() cache.lastDeath = tick() end) end
    updateCharParts()
end
player.CharacterAdded:Connect(function(c) 
    updateCharParts()
    c.AttributeChanged:Connect(function() updateCharParts() end)
end)
if player.Character then 
    updateCharParts()
    player.Character.AttributeChanged:Connect(function() updateCharParts() end)
end

local dungeonCache = {
    charParts = {},
    lastPartsCached = 0,
    baseHeight = 13,
    lastHeightCalc = 0,
    stuckTimer = 0,
    lastPosition = nil,
    mapChildCount = 0
}

RunService.Heartbeat:Connect(function(dt)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- Per-Frame Smooth Logic (Lerp/Tween/Fly)

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
                    if dist > 5 then
                        local alpha = math.min((islandTweenSpeed * dt) / dist, 1)
                        hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, target) * CFrame.new(0, 0, -dist), alpha)
                    end
                end
            end
        end
    end

    -- Auto Chest Mirage
    if autoChestMirage and cache.mirage then
        for _, v in ipairs(characterParts) do v.CanCollide = false end
        hrp.Velocity *= 0.1
        local miragePos = cache.mirage:GetModelCFrame().Position
        local distToMirage = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(miragePos.X, miragePos.Z)).Magnitude
        if distToMirage > 1500 then
            local targetPos = miragePos + Vector3.new(0, 250, 0)
            local dist = (hrp.Position - targetPos).Magnitude
            if dist > 5 then
                local alpha = math.min((islandTweenSpeed * dt) / dist, 1)
                hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, targetPos) * CFrame.new(0, 0, -dist), alpha)
            end
        elseif cache.chest then
            local targetPos = cache.chest.Position
            local distToChest = (hrp.Position - targetPos).Magnitude
            if autoChestStyle == "TP" then
                if tick() - cache.lastLootTime >= 1.5 then
                    hrp.CFrame = CFrame.new(targetPos)
                    if distToChest < 5 then cache.touchedChests[cache.chest.Parent] = true; cache.chest = nil; cache.lastLootTime = tick() end
                end
            else
                local hDist = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(targetPos.X, targetPos.Z)).Magnitude
                local fTarget = (hDist > 50) and Vector3.new(targetPos.X, 250, targetPos.Z) or targetPos
                local tDist = (hrp.Position - fTarget).Magnitude
                if hDist <= 50 and tDist < 5 then cache.touchedChests[cache.chest.Parent] = true; cache.chest = nil
                elseif tDist > 5 then
                    local alpha = math.min((islandTweenSpeed * dt) / tDist, 1)
                    hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, fTarget) * CFrame.new(0, 0, -tDist), alpha)
                end
            end
        else
            local targetPos = miragePos + Vector3.new(0, 250, 0)
            if (hrp.Position - targetPos).Magnitude > 5 then
                local alpha = math.min((islandTweenSpeed * dt) / (hrp.Position - targetPos).Magnitude, 1)
                hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, targetPos) * CFrame.new(0, 0, -(hrp.Position - targetPos).Magnitude), alpha)
            end
        end
    end

    if flyBoatEnabled and currentBoat and currentBoat.Parent then
        local seat = currentBoat:FindFirstChildOfClass("VehicleSeat") or currentBoat:FindFirstChild("VehicleSeat", true)
        isPlayerOnBoat = (seat and seat.Occupant ~= nil)
        if isPlayerOnBoat then
            if not cache.boatTarget then cache.boatTarget = hrp.Position end
            if #cache.boatParts == 0 then for _, v in ipairs(currentBoat:GetDescendants()) do if v:IsA("BasePart") then table.insert(cache.boatParts, v) end end end
            local cam, moveDir = workspace.CurrentCamera, Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
            if moveDir.Magnitude > 0 then cache.boatTarget = cache.boatTarget + (moveDir.Unit * flyBoatSpeed * dt) end
            for _, v in ipairs(cache.boatParts) do v.Anchored, v.Velocity, v.RotVelocity = false, Vector3.zero, Vector3.zero end
            if flyBoatStyle == "Custom" then hrp.CFrame = CFrame.lookAt(cache.boatTarget, cache.boatTarget + cam.CFrame.LookVector)
            else cache.boatTarget = Vector3.new(cache.boatTarget.X, flyBoatHeight, cache.boatTarget.Z) hrp.CFrame = CFrame.new(cache.boatTarget) * CFrame.lookAt(Vector3.zero, Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)).Rotation end
        else
            cache.boatTarget = (currentBoat.PrimaryPart or currentBoat:FindFirstChildWhichIsA("BasePart")).Position
            for _, v in ipairs(cache.boatParts) do if not v.Anchored then v.Anchored = true end end
        end
    end

    -- Combat & Movement
    if fastM1Enabled then applyFastM1() end
    if tpEnabled and hum and hum.MoveDirection.Magnitude > 0 then
        local extra = (tpSpeed - 1) * hum.WalkSpeed
        if extra > 0 then hrp.CFrame = hrp.CFrame + (hum.MoveDirection * extra * dt) end
    end
    
    if waterWalkEnabled then
        if antiWaterEnabled and hrp.Position.Y < antiWaterThreshold then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
            hrp.CFrame = CFrame.new(hrp.Position.X, 1, hrp.Position.Z)
        end
        if lastFoamState ~= true then
            pcall(function() workspace._WorldOrigin["Foam;"].CanCollide = true end)
            lastFoamState = true
        end
    elseif lastFoamState ~= false then
        pcall(function() workspace._WorldOrigin["Foam;"].CanCollide = false end)
        lastFoamState = false
    end
    
    if infinityJumpEnabled then char:SetAttribute("SkyjumpBoost", 3000) end
    if dashLengthValue > 0 then char:SetAttribute("DashLength", dashLengthValue) end
    if hum then 
        if jumpHeightEnabled then hum.UseJumpPower, hum.JumpHeight = false, jumpHeightValue
        else hum.UseJumpPower = true end
    end

    -- Auto Boss Tween (Real-time tracking)
    if autoBossEnabled and autoBossTargetObj then
        local tH = autoBossTargetObj:IsA("Model") and autoBossTargetObj:FindFirstChildOfClass("Humanoid")
        if tH and tH.Health <= 0 then autoBossTargetObj = nil return end
        
        local targetPart = autoBossTargetObj:IsA("Model") and (autoBossTargetObj.PrimaryPart or autoBossTargetObj:FindFirstChild("HumanoidRootPart") or autoBossTargetObj:FindFirstChildWhichIsA("BasePart")) or autoBossTargetObj
        if targetPart then
            for _, v in ipairs(characterParts) do v.CanCollide = false end
            hrp.Velocity = Vector3.new(0, 0, 0)
            local targetPos = targetPart.Position + Vector3.new(0, safeHeight, 0)
            local dist = (hrp.Position - targetPos).Magnitude
            if dist > 0.5 then
                local speed = (dist < 140) and 1300 or 360
                local moveDist = math.min(speed * dt, dist)
                local direction = (targetPos - hrp.Position).Unit
                if direction.X == direction.X then hrp.CFrame = hrp.CFrame + (direction * moveDist) end
            end
        end
    elseif autoFarmBonesEnabled and autoBoneTargetObj then
        local tH = autoBoneTargetObj:IsA("Model") and autoBoneTargetObj:FindFirstChildOfClass("Humanoid")
        if tH and tH.Health <= 0 then autoBoneTargetObj = nil return end
        
        local targetPart = autoBoneTargetObj:IsA("Model") and (autoBoneTargetObj.PrimaryPart or autoBoneTargetObj:FindFirstChild("HumanoidRootPart") or autoBoneTargetObj:FindFirstChildWhichIsA("BasePart")) or autoBoneTargetObj
        if targetPart then
            for _, v in ipairs(characterParts) do v.CanCollide = false end
            hrp.Velocity = Vector3.new(0, 0, 0)
            local targetPos = targetPart.Position + Vector3.new(0, safeHeight, 0)
            local dist = (hrp.Position - targetPos).Magnitude
            if dist > 0.5 then
                local speed = (dist < 140) and 1300 or 360
                local moveDist = math.min(speed * dt, dist)
                local direction = (targetPos - hrp.Position).Unit
                if direction.X == direction.X then hrp.CFrame = hrp.CFrame + (direction * moveDist) end
            end
        end
    end
    
    if autoCakeFarmEnabled and autoCakeTargetObj then
        local tH = autoCakeTargetObj:IsA("Model") and autoCakeTargetObj:FindFirstChildOfClass("Humanoid")
        if tH and tH.Health <= 0 then autoCakeTargetObj = nil return end
        
        local targetPart = autoCakeTargetObj:IsA("Model") and (autoCakeTargetObj.PrimaryPart or autoCakeTargetObj:FindFirstChild("HumanoidRootPart") or autoCakeTargetObj:FindFirstChildWhichIsA("BasePart")) or autoCakeTargetObj
        if targetPart then
            for _, v in ipairs(characterParts) do v.CanCollide = false end
            hrp.Velocity = Vector3.new(0, 0, 0)
            local targetPos = targetPart.Position + Vector3.new(0, safeHeight, 0)
            local dist = (hrp.Position - targetPos).Magnitude
            if dist > 0.5 then
                local speed = (dist < 140) and 1300 or 360
                local moveDist = math.min(speed * dt, dist)
                local direction = (targetPos - hrp.Position).Unit
                if direction.X == direction.X then hrp.CFrame = hrp.CFrame + (direction * moveDist) end
            end
        end
    end

end)

-- Background Scheduler (Heavy tasks moved here)
task.spawn(function()
    while true do
        local dt = task.wait(0.1)
        if autoDungeonEnabled and char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local myHRP = char.HumanoidRootPart
                local dungeonMap = workspace.Map:FindFirstChild("Dungeon")
                local enemies = (workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren()) or {}
                
                local function spamAllPortals()
                    if dungeonMap then
                        for _, room in dungeonMap:GetChildren() do
                            local portal = room:FindFirstChild("ExitTeleporter") or room:FindFirstChild("ExitTeleport")
                            local root = portal and portal:FindFirstChild("Root")
                            if root then pcall(function() firetouchinterest(myHRP, root, 0) firetouchinterest(myHRP, root, 1) end) end
                        end
                    end
                end

                if (tick() - cache.lastDeath < 5) or (tick() - cache.dTick < 2) then spamAllPortals() end
                
                local nearestDist, bestTarget = math.huge, nil
                for _, e in ipairs(enemies) do
                    local eHRP = e:FindFirstChild("HumanoidRootPart")
                    local eHum = e:FindFirstChildOfClass("Humanoid")
                    if eHRP and eHum and eHum.Health > 0 then
                        local isPriority = (e.Name == "PropHitboxPlaceholder")
                        if not (e.Name:lower():find("shadow") or e.Name:lower():find("blank")) then
                            local d = (myHRP.Position - eHRP.Position).Magnitude
                            if (isPriority and 0 or d) < nearestDist then
                                nearestDist = (isPriority and 0 or d); bestTarget = eHRP
                            end
                            if isPriority then break end
                        end
                    end
                end
                
                if bestTarget then
                    local targetPos = bestTarget.Position + Vector3.new(0, dungeonCache.baseHeight, 0)
                    for _, v in ipairs(characterParts) do v.CanCollide = false end
                    myHRP.Velocity = Vector3.zero
                    local dist = (myHRP.Position - targetPos).Magnitude
                    if dist > 0.1 then
                        local spd = (dist < 5) and 150 or (dist < 25 and 450 or 350)
                        local alpha = math.clamp((spd * dt) / dist, 0, 0.8)
                        local look = Vector3.new(targetPos.X, myHRP.Position.Y, targetPos.Z)
                        myHRP.CFrame = myHRP.CFrame:Lerp(CFrame.new(myHRP.Position, look) * CFrame.new(0, 0, -dist) * CFrame.new(0, targetPos.Y - myHRP.Position.Y, 0), alpha)
                    end
                else spamAllPortals() end
            end)
        end

        -- Logic Auto Boss Selector
        if autoBossEnabled and char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local myHRP = char.HumanoidRootPart
                local foundTarget = nil
                local minTargetDist = math.huge
                
                -- Cập nhật danh sách Boss tổng thể từ EnemySpawns
                local spawns = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("EnemySpawns")
                if spawns then
                    for _, s in ipairs(spawns:GetChildren()) do
                        if s.Name:find("%[Boss%]") then
                            local fn = s.Name
                            local cn = fn:gsub("%[.-%]", ""):match("^%s*(.-)%s*$")
                            masterBossList[cn] = fn
                        end
                    end
                end

                -- Tìm Boss trong Enemies (Ưu tiên hàng đầu - Tìm con GẦN NHẤT)
                local enemies = workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}
                for _, e in ipairs(enemies) do
                    local cn = e.Name:gsub("%[.-%]", ""):match("^%s*(.-)%s*$")
                    local fullName = masterBossList[cn] or (e.Name:find("%[Boss%]") and e.Name)
                    if fullName then
                        if not customBossEnabled or selectedBosses[fullName] then
                            local hum = e:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                local d = (myHRP.Position - e.HumanoidRootPart.Position).Magnitude
                                if d < minTargetDist then
                                    minTargetDist = d
                                    foundTarget = e
                                end
                            end
                        end
                    end
                end
                

                if foundTarget then
                    autoBossTargetObj = foundTarget
                    lastBossDeadTime = 0
                else
                    -- Nếu không thấy trong Enemies, tìm Boss gần nhất trong EnemySpawns để bay tới đợi
                    local spawnTarget = nil
                    local minSpawnDist = math.huge
                    if spawns then
                        for _, s in ipairs(spawns:GetChildren()) do
                            if s.Name:find("%[Boss%]") then
                                if not customBossEnabled or selectedBosses[s.Name] then
                                    local d = (myHRP.Position - s.Position).Magnitude
                                    if d < minSpawnDist then
                                        minSpawnDist = d
                                        spawnTarget = s
                                    end
                                end
                            end
                        end
                    end
                    
                    if spawnTarget then
                        autoBossTargetObj = spawnTarget
                        lastBossDeadTime = 0
                    else
                        autoBossTargetObj = nil
                        if autoBossHopEnabled then
                            if lastBossDeadTime == 0 then lastBossDeadTime = tick() end
                            if tick() - lastBossDeadTime > 5 then
                                executeHop()
                                lastBossDeadTime = 0
                            end
                        end
                    end
                end
            end)
        end

        -- Logic Auto Farm Bones Selector
        if autoFarmBonesEnabled and char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local myHRP = char.HumanoidRootPart
                local foundTarget = nil
                local minTargetDist = math.huge
                local enemies = workspace:FindFirstChild("Enemies")
                local function isTarget(n)
                    for _, m in ipairs(boneMobs) do if n:find(m) then return true end end
                    return false
                end
                if enemies then
                    for _, e in ipairs(enemies:GetChildren()) do
                        if isTarget(e.Name) then
                            local hum = e:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 and e:FindFirstChild("HumanoidRootPart") then
                                local d = (myHRP.Position - e.HumanoidRootPart.Position).Magnitude
                                if d < minTargetDist then minTargetDist = d; foundTarget = e end
                            end
                        end
                    end
                end
                if foundTarget then autoBoneTargetObj = foundTarget
                else
                    local spawnTarget = nil
                    local minSpawnDist = math.huge
                    local spawns = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("EnemySpawns")
                    if spawns then
                        for _, s in ipairs(spawns:GetChildren()) do
                            if isTarget(s.Name) then
                                local d = (myHRP.Position - s.Position).Magnitude
                                if d < minSpawnDist then minSpawnDist = d; spawnTarget = s end
                            end
                        end
                    end
                    autoBoneTargetObj = spawnTarget
                end
            end)
        else autoBoneTargetObj = nil end

        -- Logic Auto Cake Prince Selector
        if autoCakeFarmEnabled and char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local myHRP = char.HumanoidRootPart
                local foundTarget = nil
                local enemies = workspace:FindFirstChild("Enemies")
                local map = workspace:FindFirstChild("Map")
                local mirrorDimension = map and map:FindFirstChild("MirrorDimension")
                
                local function findCakeMob(name)
                    if enemies then
                        for _, e in ipairs(enemies:GetChildren()) do
                            if e.Name:find(name) then
                                local hum = e:FindFirstChildOfClass("Humanoid")
                                if hum and hum.Health > 0 and e:FindFirstChild("HumanoidRootPart") then return e end
                            end
                        end
                    end
                    return nil
                end

                if mirrorDimension then
                    foundTarget = findCakeMob("Cake Prince")
                    if not foundTarget then
                        foundTarget = mirrorDimension.PrimaryPart or mirrorDimension:FindFirstChildWhichIsA("BasePart") or mirrorDimension
                    end
                else
                    local minTargetDist = math.huge
                    if enemies then
                        for _, e in ipairs(enemies:GetChildren()) do
                            local nameMatch = false
                            for i = 2, #cakeMobs do -- Index 2 to 5 are normal mobs
                                if e.Name:find(cakeMobs[i]) then nameMatch = true break end
                            end
                            if nameMatch then
                                local hum = e:FindFirstChildOfClass("Humanoid")
                                if hum and hum.Health > 0 and e:FindFirstChild("HumanoidRootPart") then
                                    local d = (myHRP.Position - e.HumanoidRootPart.Position).Magnitude
                                    if d < minTargetDist then minTargetDist = d; foundTarget = e end
                                end
                            end
                        end
                    end
                    
                    if not foundTarget then
                        local spawns = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("EnemySpawns")
                        if spawns then
                            local minSpawnDist = math.huge
                            for _, s in ipairs(spawns:GetChildren()) do
                                local nameMatch = false
                                for i = 2, #cakeMobs do
                                    if s.Name:find(cakeMobs[i]) then nameMatch = true break end
                                end
                                if nameMatch then
                                    local d = (myHRP.Position - s.Position).Magnitude
                                    if d < minSpawnDist then minSpawnDist = d; foundTarget = s end
                                end
                            end
                        end
                    end
                end
                autoCakeTargetObj = foundTarget
            end)
        else autoCakeTargetObj = nil end

        -- Sync Auto Equip (0.1s)
        if char and char:FindFirstChild("HumanoidRootPart") then
            local target = autoBossTargetObj or autoBoneTargetObj or autoCakeTargetObj
            if target then
                local tPart = target:IsA("Model") and (target.PrimaryPart or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")) or target
                if tPart and (char.HumanoidRootPart.Position - tPart.Position).Magnitude < 150 then
                    local function equip(tt)
                        local backpack = player:FindFirstChild("Backpack")
                        local tool = nil
                        for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") and t.ToolTip == tt then tool = t break end end
                        if not tool and backpack then
                            for _, t in ipairs(backpack:GetChildren()) do
                                if t:IsA("Tool") and t.ToolTip == tt then tool = t char.Humanoid:EquipTool(t) break end
                            end
                        end
                        if tool then
                            pcall(function()
                                local ev = tool:FindFirstChild("EquipEvent")
                                if ev then ev:FireServer(true) end
                            end)
                        end
                    end
                    equip(autoEquipType)
                end
            end
        end

        -- Smooth Player ESP (0.1s)
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
            cache.mirage = findIsland("Mirage Island")
            cache.kitsune = findIsland("Kitsune Island")
            cache.prehistoric = findIsland("Prehistoric Island")
            if autoChestMirage and cache.mirage then
                local chestFolder = workspace:FindFirstChild("ChestModels")
                if chestFolder then
                    for _, chest in ipairs(chestFolder:GetChildren()) do
                        if not cache.touchedChests[chest] then
                            local n = chest.Name:lower()
                            if (autoChestType == "All") or (autoChestType == "Fragment" and n:find("fragment")) or (autoChestType == "Mirage" and n:find("mirage")) then
                                local p = chest:FindFirstChildWhichIsA("BasePart") or chest.PrimaryPart
                                if p then cache.chest = p; break end
                            end
                        end
                    end
                    if #chestFolder:GetChildren() == 0 or tick() % 300 < 1 then cache.touchedChests = {} end
                end
            end
        end
    end
end)

-- CAKE PRINCE SPAWNER LOOP
task.spawn(function()
    while true do
        task.wait(1)
        if autoCakeSpawnEnabled then
            pcall(function()
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("CakePrinceSpawner", true)
                task.wait(0.1)
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("CakePrinceSpawner")
            end)
        end
    end
end)

-- LocalPlayer Section
TabBlox:AddSection({Name = "LocalPlayer"})
TabBlox:AddToggle({Title = "Infinity Sky Jump", Default = false, Callback = function(v) infinityJumpEnabled = v if not v and char then char:SetAttribute("SkyjumpBoost", nil) end end})
TabBlox:AddToggle({Title = "Jump Height Enabled", Default = false, Callback = function(v) jumpHeightEnabled = v end})
TabBlox:AddSlider({Title = "Jump Height", Min = 7.2, Max = 1000, Default = 7.2, Increase = 0.1, Callback = function(v) jumpHeightValue = v end})
TabBlox:AddSlider({Title = "Dash Length", Min = 0, Max = 500, Default = 0, Increase = 0.1, Callback = function(v) dashLengthValue = v end})
TabBlox:AddToggle({Title = "Water Walk", Default = true, Callback = function(v) waterWalkEnabled = v end})
TabBlox:AddToggle({Title = "Anti Water", Default = true, Callback = function(v) antiWaterEnabled = v end})

-- Fruit Section
TabBlox:AddSection({Name = "Fruit"})
local function storeAllFruits()
    if not char then return end
    local items = {}
    for _, v in player.Backpack:GetChildren() do table.insert(items, v) end
    for _, v in char:GetChildren() do table.insert(items, v) end
    for _, item in items do
        if item:IsA("Tool") and item.Name:lower():find("fruit") then
            local baseName = item.Name:gsub(" Fruit", ""):gsub(" ", "")
            local formattedName = baseName .. "-" .. baseName
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", formattedName, item) end)
        end
    end
end
TabBlox:AddToggle({Title = "Auto Store Fruit", Default = false, Callback = function(v) autoStoreFruitEnabled = v end})
TabBlox:AddButton({Title = "Store All Fruits (1 Click)", Callback = function() storeAllFruits() end})
TabBlox:AddToggle({Title = "Auto Random Fruit", Default = false, Callback = function(v) autoRandomFruitEnabled = v end})
TabBlox:AddButton({Title = "Random Fruit (1 Click)", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy", "DLCBoxData") end) end})

-- Sea Event Section
TabBlox:AddSection({Name = "Sea Event"})
TabBlox:AddSlider({Title = "Boat Speed", Min = 200, Max = 600, Default = 200, Increase = 1, Callback = function(v) boatSpeed = v updateBoatSpeeds() end})
TabBlox:AddButton({Title = "Buy Marine Boat", Callback = function() pcall(function() if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = CFrame.new(-16919, 9, 503) task.wait(0.1) ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("BuyBoat", "MarineGrandBrigade") end end) end})
TabBlox:AddButton({Title = "TP Boat to Player", Callback = function()
    pcall(function()
        local boats = workspace:FindFirstChild("Boats")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if boats and hrp then
            for _, boat in boats:GetChildren() do
                if boat:FindFirstChild("Owner") and tostring(boat.Owner.Value) == player.Name then
                    local originalPos = hrp.CFrame
                    local seat = boat:FindFirstChildOfClass("VehicleSeat") or boat:FindFirstChild("VehicleSeat", true)
                    if seat then
                        hrp.CFrame = seat.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.2)
                        hrp.CFrame = originalPos
                        task.wait(0.1)
                        if flyBoatEnabled then cache.boatTarget = hrp.Position end
                    end
                    break
                end
            end
        end
    end)
end})
TabBlox:AddToggle({Title = "Fly Boat", Default = false, Callback = function(v)
    flyBoatEnabled = v
    if v then
        local boats = workspace:FindFirstChild("Boats")
        if not boats or not char or not char:FindFirstChild("HumanoidRootPart") then flyBoatEnabled = false return end
        local hrp, closest, dist = char.HumanoidRootPart, nil, 200
        for _, boat in boats:GetChildren() do
            if boat:IsA("Model") then
                local part = boat.PrimaryPart or boat:FindFirstChildWhichIsA("BasePart")
                if part then local d = (part.Position - hrp.Position).Magnitude if d < dist then dist = d; closest = boat end end
            end
        end
        if closest then 
            currentBoat = closest
            local part = currentBoat.PrimaryPart or currentBoat:FindFirstChildWhichIsA("BasePart")
            cache.boatTarget = part.Position
        else flyBoatEnabled = false end
    else currentBoat, cache.boatTarget = nil, nil end
end})
TabBlox:AddSlider({Title = "Speed Flyboat", Min = 100, Max = 1000, Default = 200, Increase = 1, Callback = function(v) flyBoatSpeed = v end})
TabBlox:AddSlider({Title = "Boat Height", Min = 20, Max = 600, Default = 125, Increase = 1, Callback = function(v) flyBoatHeight = v end})
TabBlox:AddDropdown({Title = "Fly Style", Options = {"Default", "Custom"}, Default = "Default", Callback = function(v) flyBoatStyle = v end})
TabBlox:AddButton({Title = "Remove Rocks", Callback = function()
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name == "Rocks" then pcall(function() v:Destroy() end) end
        end
    end)
end})

-- Shop Section
TabBlox:AddSection({Name = "Shop"})
TabBlox:AddButton({Title = "Reset Stat (Buy)", Callback = function()
    pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("BlackbeardReward", "Refund", "2") end)
end})

-- Dungeon Section
TabBlox:AddSection({Name = "Dungeon"})
TabBlox:AddToggle({Title = "Auto Dungeon", Default = false, Callback = function(v) autoDungeonEnabled = v end})

-- UTILS TAB
TabUtils:AddSection({Name = "Movement"})
TabUtils:AddToggle({Title = "TP Walk Enabled", Default = false, Callback = function(v) tpEnabled = v end})
TabUtils:AddSlider({Title = "Speed Mult", Min = 1, Max = 8, Default = 2, Increase = 0.1, Callback = function(v) tpSpeed = v end})

TabUtils:AddSection({Name = "Visuals"})
TabUtils:AddToggle({Title = "Player ESP", Default = false, Callback = function(v) espSettings.Enabled = v if not v then clearESP() end end})
TabUtils:AddToggle({Title = "Show HP Text", Default = true, Callback = function(v) espSettings.ShowText = v end})
TabUtils:AddToggle({Title = "Show HP Bar", Default = true, Callback = function(v) espSettings.ShowBar = v end})

TabUtils:AddSection({Name = "Others"})
TabUtils:AddToggle({Title = "Anti-AFK", Default = true, Callback = function(v) antiAfkEnabled = v end})
TabUtils:AddButton({Title = "Remove Fog & Effects", Callback = function()
    for _, v in Lighting:GetChildren() do if v:IsA("Atmosphere") or v.Name:find("Fog") then pcall(function() v:Destroy() end) end end
    Lighting.FogEnd, Lighting.FogStart, Lighting.GlobalShadows, Lighting.ExposureCompensation = 9e9, 0, false, 1
end})
TabUtils:AddButton({Title = "Infinite Yield", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end})

TabUtils:AddSection({Name = "Server Hopper"})
TabUtils:AddButton({Title = "Small Server Hop", Callback = function() executeHop() end})
TabUtils:AddButton({Title = "Old-like (Low Population)", Callback = function() hopToOldServer("4h") end})
TabUtils:AddButton({Title = "Old-like (Fast Scan)", Callback = function() hopToOldServer("3h45") end})

TabSettings:AddSection({Name = "Custom Button Icon"})
TabSettings:AddParagraph({Title = "Hướng dẫn", Text = "📖 Hướng dẫn lấy ID:\n1. Mở Roblox Website > Create > Dashboard\n2. Chọn Development Items > Decals\n3. Copy dãy số (ID) của ảnh bạn muốn dán vào đây."})
TabSettings:AddTextBox({Title = "Icon Button ID", Default = "84053545044369", PlaceholderText = "Dán ID số vào đây...", Callback = function(v)
    local idOnly = v:match("%d+")
    if idOnly then
        pcall(function() ToggleBtn.Image = "rbxthumb://type=Asset&id=" .. idOnly .. "&w=420&h=420" end)
    end
end})

local last10s, last2s = 0, 0
task.spawn(function()
    while true do
        task.wait(1)
        local now = tick()
        if autoRaceV3Enabled then pcall(function() ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility") end) end
        if autoStoreFruitEnabled then storeAllFruits() end
        if autoUpgradeRaceEnabled then pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("UpgradeRace", "Buy") end) end
        if autoActiveV4Enabled then
            pcall(function()
                local character = player.Character
                if character then
                    local awakening = player.Backpack:FindFirstChild("Awakening") or character:FindFirstChild("Awakening")
                    if awakening then
                        local rf = awakening:FindFirstChild("RemoteFunction", true)
                        if rf then pcall(function() rf:InvokeServer(true) end) end
                    end
                end
            end)
        end
        if autoTradeBonesEnabled and now - last2s >= 2 then
            last2s = now
            pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("Bones", "Buy", 1, 1) end)
        end
        if autoRandomFruitEnabled and now - last10s >= 10 then
            last10s = now
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy", "DLCBoxData") end)
        end
        if now % 1200 < 1 then hoppedServers = {} end
    end
end)

player.Idled:Connect(function()
    if antiAfkEnabled then
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    end
end)

Window:SelectTab(1)
