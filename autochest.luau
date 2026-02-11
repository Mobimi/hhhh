local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- [[ SEA RECOGNITION ]]
local SEA2_ID = 4442272183
local function isCorrectSea()
    return game.PlaceId == SEA2_ID
end
local islands = {
    {name = "Cafe", pos = Vector3.new(-287, 306, 598), directTP = true},
    {name = "Đảo Tuyết", pos = Vector3.new(1176, 430, -4638)},
    {name = "Đảo Nóng Lạnh", pos = Vector3.new(-5333, 29, -5268)},
    {name = "Đảo Nhỏ", pos = Vector3.new(-5333, 29, -5268)},
    {name = "Đảo Đầu Lâu", pos = Vector3.new(-2956, 116, -10003)},
    {name = "Lâu Đài Băng Giá", pos = Vector3.new(5545, 29, -6384)},
    {name = "Đảo Zombie", pos = Vector3.new(-5711, 126, -792)},
    {name = "Tàu Ma", pos = Vector3.new(921, 125, 32851), directTP = true, exitPos = Vector3.new(-6509, 83, -133)},
    {name = "Đảo Thực Vật", pos = Vector3.new(-2277, 73, -3013)}
}

-- [[ CONFIGURATION & SAVING ]]
local HttpService = game:GetService("HttpService")
local CONFIG_FOLDER = "autochest"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.cfg"

getgenv().Config = {
    AutoChest = true,
    PriorityGhostShip = true,
    NormalSpeed = 350,
    BoostSpeed = 800,
    DetectionRadius = 140, -- Rương trong vòng này sẽ bay tốc độ Boost
    RingColor = Color3.fromRGB(0, 255, 255),
    RingTransparency = 0.7,
    GhostShipY = 124.65
}

local function SaveConfig()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    local success, data = pcall(function()
        local saveTable = {}
        for k, v in pairs(getgenv().Config) do
            if typeof(v) == "Color3" then
                saveTable[k] = {r = v.R, g = v.G, b = v.B}
            else
                saveTable[k] = v
            end
        end
        return HttpService:JSONEncode(saveTable)
    end)
    if success then writefile(CONFIG_FILE, data) end
end

local function LoadConfig()
    if isfile(CONFIG_FILE) then
        local success, data = pcall(function()
            local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
            for k, v in pairs(decoded) do
                if type(v) == "table" and v.r then
                    getgenv().Config[k] = Color3.new(v.r, v.g, v.b)
                else
                    getgenv().Config[k] = v
                end
            end
        end)
    end
end

LoadConfig()

-- Startup Check
if not isCorrectSea() then
    warn("!!! SAI MAP: Script nay chi danh cho SEA 2. Auto Chest da bi khoa !!!")
    getgenv().Config.AutoChest = false
    return
else
    print("-----------------------------------------")
    print("DA NHAN DIEN SEA 2 - KHOI DONG AUTO CHEST")
    print("-----------------------------------------")
end

-- [[ WINDUI INTEGRATION ]]
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Auto Chest Tweaker",
    Icon = "solar:box-minimalistic-bold",
    Folder = "autochest",
    Theme = "Dark",
    OpenButton = { Enabled = true, Draggable = true }
})

local MainTab = Window:Tab({ Title = "Main", Icon = "solar:home-2-bold" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "solar:settings-bold" })

MainTab:Toggle({
    Title = "Auto Chest",
    Value = getgenv().Config.AutoChest,
    Callback = function(v) getgenv().Config.AutoChest = v SaveConfig() end
})

MainTab:Toggle({
    Title = "Priority Ghost Ship",
    Value = getgenv().Config.PriorityGhostShip,
    Callback = function(v) getgenv().Config.PriorityGhostShip = v SaveConfig() end
})

SettingsTab:Slider({
    Title = "Normal Speed",
    Value = { Min = 100, Max = 1000, Default = getgenv().Config.NormalSpeed },
    Callback = function(v) getgenv().Config.NormalSpeed = v SaveConfig() end
})

SettingsTab:Slider({
    Title = "Boost Speed",
    Value = { Min = 300, Max = 2000, Default = getgenv().Config.BoostSpeed },
    Callback = function(v) getgenv().Config.BoostSpeed = v SaveConfig() end
})

SettingsTab:Slider({
    Title = "Detection Radius",
    Value = { Min = 10, Max = 500, Default = getgenv().Config.DetectionRadius },
    Callback = function(v) getgenv().Config.DetectionRadius = v SaveConfig() end
})

local CHEST_PATH = workspace:WaitForChild("ChestModels", 10) or workspace
local visited, collected = {}, {}

-- Create Detection Ring Visual
local Ring = Instance.new("Part")
Ring.Name = "ChestRangeRing"
Ring.Anchored = true
Ring.CanCollide = false
Ring.Transparency = getgenv().Config.RingTransparency
Ring.Material = Enum.Material.Neon
Ring.Color = getgenv().Config.RingColor
Ring.Shape = Enum.PartType.Cylinder
Ring.Size = Vector3.new(0.2, getgenv().Config.DetectionRadius * 2, getgenv().Config.DetectionRadius * 2)
Ring.Orientation = Vector3.new(0, 0, 90)
Ring.Parent = workspace

local function hasDarkness()
    for _, list in ipairs({player.Backpack:GetChildren(), character:GetChildren()}) do
        for _, item in ipairs(list) do
            if item:IsA("Tool") and item.Name:lower():find("darkness") then return true end
        end
    end
    return false
end

local function tp(pos)
    if character:FindFirstChild("HumanoidRootPart") then character.HumanoidRootPart.CFrame = CFrame.new(pos) end
end

local function tween(target, canBoost, object)
    local hrp = character.HumanoidRootPart
    local cfg = getgenv().Config
    local startT = tick()
    
    -- Tạo platform chống rớt biển
    local plat = Instance.new("Part", workspace)
    plat.Size = Vector3.new(10, 1, 10)
    plat.Anchored = true
    plat.Transparency = 1
    plat.CanCollide = true
    
    while true do
        if not cfg.AutoChest or hasDarkness() then break end
        if (object and not object.Parent) or (tick() - startT > 10) then break end
        
        local dt = RunService.Heartbeat:Wait()
        hrp.Velocity = Vector3.new(0,0,0)
        
        local dist = (target - hrp.Position).Magnitude
        if dist <= 2.5 then 
            hrp.CFrame = CFrame.new(target)
            task.wait(0.12) -- Nghỉ cực ngắn để server nhận touch
            break 
        end
        
        local speed = (canBoost and dist <= cfg.DetectionRadius) and cfg.BoostSpeed or cfg.NormalSpeed
        local step = speed * dt
        
        if step >= dist then
            hrp.CFrame = CFrame.new(target)
            task.wait(0.12)
            break
        end
        
        local nextPos = hrp.Position + (target - hrp.Position).Unit * step
        hrp.CFrame = CFrame.new(nextPos, target)
        plat.CFrame = hrp.CFrame * CFrame.new(0, -3.5, 0)
    end
    plat:Destroy()
end

local function getChest()
    local near, dist = nil, math.huge
    for _, v in pairs(CHEST_PATH:GetChildren()) do
        if not collected[v] and (v.Name:find("Chest")) then
            local s, p = pcall(function() return v:GetPivot().Position end)
            if s then
                local d = (character.HumanoidRootPart.Position - p).Magnitude
                if d < dist then dist, near = d, v end
            end
        end
    end
    return near
end

local function hop()
    local servers = {}
    pcall(function()
        local data = game:GetService("HttpService"):JSONDecode(request({Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100", Method = "GET"}).Body)
        for _, s in pairs(data.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then table.insert(servers, s.id) end
        end
        if #servers > 0 then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)]) end
    end)
end

local function getIsland()
    local cfg = getgenv().Config
    if cfg.PriorityGhostShip then
        for _, i in ipairs(islands) do if i.name == "Tàu Ma" and not visited[i.name] then cfg.PriorityGhostShip = false return i end end
    end
    local near, dist = nil, math.huge
    for _, i in ipairs(islands) do
        if not visited[i.name] then
            local d = (character.HumanoidRootPart.Position - i.pos).Magnitude
            if d < dist then dist, near = d, i end
        end
    end
    if not near then hop() task.wait(5) visited = {} return getIsland() end
    return near
end

task.spawn(function()
    while true do
        task.wait()
        local cfg = getgenv().Config
        if cfg and cfg.AutoChest and character and character:FindFirstChild("HumanoidRootPart") then
            -- Update Ring Position & Dynamic Scaling
            Ring.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, -3.2, 0) * CFrame.Angles(0, 0, math.rad(90))
            Ring.Size = Vector3.new(0.2, cfg.DetectionRadius * 2, cfg.DetectionRadius * 2)
            Ring.Color = cfg.RingColor
            Ring.Transparency = cfg.RingTransparency
            
            -- Anti-Collision and Anti-Sit
            for _, v in pairs(character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
            if character:FindFirstChild("Humanoid") then character.Humanoid.Sit = false end
        else
            Ring.Transparency = 1
        end
    end
end)

local function collect(c)
    local p = c:GetPivot().Position
    collected[c] = tick() -- Đánh dấu ngay lập tức
    tween(p, true, c) -- Chuyền object rương vào để check
end

while getgenv().Config.AutoChest do
    task.wait()
    local cfg = getgenv().Config
    character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then continue end
    if hasDarkness() then tp(Vector3.new(-287, 306, 598)) cfg.AutoChest = false break end
    
    -- Ưu tiên đi Tàu Ma trước nếu chưa đi
    local c = (not cfg.PriorityGhostShip) and getChest() or nil
    
    if c then
        collect(c)
    else
        local i = getIsland()
        if i.directTP then tp(i.pos) else
            local last = 0
            while (i.pos - character.HumanoidRootPart.Position).Magnitude > 50 do
                if not cfg.AutoChest or hasDarkness() then break end
                if tick() - last > 0.3 then
                    last = tick()
                    local nc = getChest()
                    if nc and (nc:GetPivot().Position - character.HumanoidRootPart.Position).Magnitude < 500 then break end
                end
                local dt = RunService.Heartbeat:Wait()
                local hrp = character.HumanoidRootPart
                hrp.Velocity = Vector3.new(0,0,0)
                hrp.CFrame = CFrame.new(hrp.Position + (i.pos - hrp.Position).Unit * (cfg.NormalSpeed * dt), i.pos)
            end
        end
        visited[i.name] = true
        if i.name == "Cafe" then task.wait(1.6) end
        if i.name == "Tàu Ma" then
            local function checkAndMoveToGhostShip()
                -- Đợi map load nế chưa thấy Interior
                local it = tick()
                while not workspace.Map:FindFirstChild("GhostShipInterior") and tick() - it < 5 do
                    task.wait(0.5)
                end

                local ghostShip = workspace.Map:FindFirstChild("GhostShipInterior")
                if not ghostShip then return false end
                
                local center = ghostShip:GetPivot().Position
                local targetMiddle = Vector3.new(center.X, cfg.GhostShipY, center.Z)
                local hrp = character.HumanoidRootPart
                
                -- Check distance, if too far, re-TP (3 times to ensure stability)
                if (hrp.Position - center).Magnitude > 1000 then
                    for attempt = 1, 3 do
                        if not cfg.AutoChest or hasDarkness() then break end
                        tp(i.pos)
                        hrp.Velocity = Vector3.new(0,0,0) -- Triệt tiêu lực đẩy
                        task.wait(1.2)
                    end
                end
                
                -- Fly to center with fixed Y
                local sT = tick()
                while (targetMiddle - hrp.Position).Magnitude > 10 and tick() - sT < 10 do
                    if not cfg.AutoChest or hasDarkness() then break end
                    local dt = RunService.Heartbeat:Wait()
                    hrp.Velocity = Vector3.new(0,0,0)
                    local dir = (targetMiddle - hrp.Position).Unit
                    hrp.CFrame = CFrame.new(Vector3.new(hrp.Position.X, cfg.GhostShipY, hrp.Position.Z) + dir * (cfg.NormalSpeed * dt), targetMiddle)
                end
                return true
            end

            if checkAndMoveToGhostShip() then
                local sT = tick()
                while tick() - sT < 5 do
                    local nc = getChest()
                    -- Kiểm tra xem rương có gần nhân vật không (trong tàu)
                    if nc and (nc:GetPivot().Position - hrp.Position).Magnitude < 1500 then break end
                    task.wait(0.5)
                end
                sT = tick()
                while tick() - sT < 15 do
                    local nc = getChest()
                    if nc and (nc:GetPivot().Position - hrp.Position).Magnitude < 1500 then 
                        collect(nc) 
                        sT = tick() 
                    else 
                        break 
                    end
                    task.wait(0.1)
                end
            end
            tp(i.exitPos)
            task.wait(1) -- Chờ 1s để lượm nốt rương ở đảo đó sau khi ra khỏi tàu
        end
    end
end
