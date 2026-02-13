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
local auraEnabled, auraFruitEnabled = true, true
local fastMeleeMultiplier, fastFruitMultiplier = 1, 1
local selectedAttacks = {true, false, false, false, false}
local last2s, last10s = 0, 0
local attackRemote, hitRemote, auraConnection, isSpamming, spamConnection, lastAttack = nil, nil, nil, false, nil, 0
local proxyRemote, seedVal, attackRemoteDirect, hitRemoteDirect = nil, nil, nil, nil
local boatSpeed = 200
local flags = {
    autoRaceV3 = false, autoBuso = true, infinityJump = false, antiAfk = true,
    jumpHeight = false, waterWalk = true, antiWater = true, flyBoat = false,
    autoActiveV4 = false, autoTradeBones = false, autoStoreFruit = false, autoDungeon = false,
    autoBoss = false, autoBossHop = false, customBoss = false, autoUpgradeRace = false,
    autoFarmBones = false, autoCakeFarm = false, autoCakeSpawn = false, autoRandomFruit = false,
    fastM1 = false, tpEnabled = false
}
local vals = {
    jumpHeight = 7.2, dashLength = 0, antiWaterThreshold = -0.807,
    flyBoatSpeed = 200, flyBoatHeight = 125, flyBoatStyle = "Default",
    autoChestMirage = false, autoChestStyle = "Tween", autoChestType = "All",
    autoEquipType = "Melee", auraRadius = 1000, auraDelay = 0.01, auraMode = "Unencode",
    auraFruitRadius = 500, auraFruitDelay = 0.01
}
local islandFlags = {["Mirage Island"] = false, ["Kitsune Island"] = false, ["Prehistoric Island"] = false}
local islandEspFlags = {["Mirage Island"] = false, ["Kitsune Island"] = false, ["Prehistoric Island"] = false}
local espSettings = { Enabled = false, ShowText = true, ShowBar = true }
local boneMobs = {"Reborn Skeleton", "Demonic Soul", "Posessed Mummy", "Living Zombie"}
local cakeMobs = {"Cake Prince", "Baking Staff", "Cake Guard", "Cookie Crafter", "Head Baker"}
local selectedBosses = {}
local autoBoneTargetObj, autoCakeTargetObj, autoBossTargetObj = nil, nil, nil
local lastBossDeadTime, masterBossList = 0, {}
local characterParts = {}
local THEME = {
    BG_MAIN = Color3.fromRGB(255, 255, 255),
    BG_SIDE = Color3.fromRGB(245, 245, 250),
    BG_CONTENT = Color3.fromRGB(255, 255, 255),
    ACCENT = Color3.fromRGB(255, 215, 0),
    TEXT = Color3.fromRGB(0, 0, 0),
    TEXT_DIM = Color3.fromRGB(80, 80, 80),
    GREEN = Color3.fromRGB(34, 139, 34),
    RED = Color3.fromRGB(178, 34, 34),
    DARK_ITEM = Color3.fromRGB(235, 235, 240)
}

local function corner(p, r) local c = Instance.new("UICorner", p) c.CornerRadius = UDim.new(0, r or 8) return c end
local function stroke(p, c, t, b) local s = Instance.new("UIStroke", p) s.Color = c or (THEME.ACCENT) s.Thickness = t or 1 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border return s end
local function toHex(c3) return string.format("#%02X%02X%02X", c3.R*255, c3.G*255, c3.B*255) end
local function fromHex(h) h = h:gsub("#","") local r,g,b = tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16) return Color3.fromRGB(r or 255, g or 255, b or 255) end
local function tween(o, p, d) TweenService:Create(o, TweenInfo.new(d or 0.3, Enum.EasingStyle.Quart), p):Play() end
local function makeDraggable(o)
    local drag, dInput, dStart, sPos
    o.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag, dStart, sPos = true, i.Position, o.Position i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end) end end)
    o.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then dInput = i end end)
    UserInputService.InputChanged:Connect(function(i) if i == dInput and drag then local d = i.Position - dStart o.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y) end end)
end
local function refreshUI()
    if ScreenGui:FindFirstChild("MainFrame") then
        local m = ScreenGui.MainFrame m.BackgroundColor3, m.BackgroundTransparency = THEME.BG_MAIN, 0.3
        local s = m:FindFirstChild("Sidebar") if s then s.BackgroundColor3, s.BackgroundTransparency = THEME.BG_SIDE, 0.4 local l = s:FindFirstChild("SidebarLabel") if l then l.TextColor3 = THEME.ACCENT end end
        for _,v in allStrokes or {} do v.Color = THEME.ACCENT end
        for _,v in allBtnStrokes or {} do v.Color = THEME.ACCENT end
    end
end

local ScreenGui = Instance.new("ScreenGui", CoreGui) ScreenGui.Name, ScreenGui.ResetOnSpawn = "HB_PRO_V3", false
local ToggleBtn = Instance.new("ImageButton", ScreenGui) ToggleBtn.Size, ToggleBtn.Position, ToggleBtn.BackgroundColor3, ToggleBtn.BackgroundTransparency, ToggleBtn.Image, ToggleBtn.ScaleType, ToggleBtn.ZIndex = UDim2.new(0,60,0,60), UDim2.new(0.02,0,0.5,-30), THEME.BG_SIDE, 0.2, "rbxthumb://type=Asset&id=84053545044369&w=420&h=420", Enum.ScaleType.Fit, 15
corner(ToggleBtn,12) stroke(ToggleBtn,THEME.ACCENT,2,true) makeDraggable(ToggleBtn)
local MainFrame = Instance.new("Frame", ScreenGui) MainFrame.Name, MainFrame.Size, MainFrame.Position, MainFrame.BackgroundColor3, MainFrame.BackgroundTransparency, MainFrame.BorderSizePixel, MainFrame.ClipsDescendants = "MainFrame", UDim2.new(0,540,0,340), UDim2.new(0.5,-270,0.5,-170), THEME.BG_MAIN, 0.3, 0, true
corner(MainFrame,12) stroke(MainFrame,THEME.ACCENT,2,false) makeDraggable(MainFrame)
local Sidebar = Instance.new("Frame", MainFrame) Sidebar.Size, Sidebar.BackgroundColor3, Sidebar.BackgroundTransparency, Sidebar.BorderSizePixel = UDim2.new(0,110,1,0), THEME.BG_SIDE, 0.4, 0 corner(Sidebar,12)
local SidebarLabel = Instance.new("TextLabel", Sidebar) SidebarLabel.Size, SidebarLabel.Position, SidebarLabel.BackgroundTransparency, SidebarLabel.Text, SidebarLabel.TextColor3, SidebarLabel.Font, SidebarLabel.TextSize = UDim2.new(1,0,0,35), UDim2.new(0,0,0,5), 1, "j4f", THEME.ACCENT, Enum.Font.GothamBold, 22
local AuthorLabel = Instance.new("TextLabel", Sidebar) AuthorLabel.Size, AuthorLabel.Position, AuthorLabel.BackgroundTransparency, AuthorLabel.Text, AuthorLabel.TextColor3, AuthorLabel.Font, AuthorLabel.TextSize = UDim2.new(1,0,0,20), UDim2.new(0,0,0,35), 1, "by tiktok: @realayako", THEME.TEXT_DIM, Enum.Font.GothamMedium, 10
local TabContainer = Instance.new("Frame", Sidebar) TabContainer.Size, TabContainer.Position, TabContainer.BackgroundTransparency = UDim2.new(1,0,1,-70), UDim2.new(0,0,0,70), 1
local TabLayout = Instance.new("UIListLayout", TabContainer) TabLayout.Padding, TabLayout.HorizontalAlignment = UDim.new(0,6), Enum.HorizontalAlignment.Center
ToggleBtn.MouseButton1Click:Connect(function() guiVisible = not guiVisible MainFrame.Visible = guiVisible tween(ToggleBtn, {BackgroundTransparency = guiVisible and 0.3 or 0.2}, 0.2) end)
local ContentArea = Instance.new("Frame", MainFrame) ContentArea.Size, ContentArea.Position, ContentArea.BackgroundTransparency = UDim2.new(1,-125,1,-15), UDim2.new(0,120,0,10), 1
local pages, tabBtns = {}, {}
local function createTab(name)
    local b = Instance.new("TextButton", TabContainer) b.Size, b.BackgroundColor3, b.BackgroundTransparency, b.Text, b.TextColor3, b.Font, b.TextSize = UDim2.new(0.85,0,0,36), THEME.DARK_ITEM, 1, name, THEME.TEXT_DIM, Enum.Font.GothamBold, 12 corner(b,8) stroke(b,THEME.DARK_ITEM,1,true)
    local p = Instance.new("ScrollingFrame", ContentArea) p.Size, p.BackgroundTransparency, p.Visible, p.ScrollBarThickness, p.ScrollBarImageColor3, p.AutomaticCanvasSize = UDim2.new(1,0,1,0), 1, false, 2, THEME.ACCENT, Enum.AutomaticSize.Y
    local l = Instance.new("UIListLayout", p) l.Padding, l.SortOrder = UDim.new(0,8), Enum.SortOrder.LayoutOrder
    b.MouseButton1Click:Connect(function() for _,x in pages do x.Visible = false end for _,x in tabBtns do tween(x,{BackgroundTransparency=1,TextColor3=THEME.TEXT_DIM},0.2) end p.Visible, b.BackgroundTransparency, b.TextColor3 = true, 0, THEME.ACCENT end)
    table.insert(pages, p) table.insert(tabBtns, b) return p
end

local function addSection(parent, title)
    local f = Instance.new("Frame", parent) f.Size, f.BackgroundTransparency = UDim2.new(1,0,0,26), 1
    local l = Instance.new("TextLabel", f) l.Size, l.Position, l.BackgroundTransparency, l.Text, l.TextColor3, l.Font, l.TextSize, l.TextXAlignment = UDim2.new(1,0,1,-4), UDim2.new(0,4,0,0), 1, title:upper(), THEME.ACCENT, Enum.Font.GothamBold, 10, 0
    local line = Instance.new("Frame", f) line.Size, line.Position, line.BackgroundColor3, line.BackgroundTransparency, line.BorderSizePixel = UDim2.new(1,0,0,1), UDim2.new(0,0,1,-2), THEME.ACCENT, 0.5, 0 return f
end

local function addToggle(p, t, d, c)
    local f = Instance.new("Frame", p) f.Size, f.BackgroundColor3, f.BackgroundTransparency = UDim2.new(1,0,0,30), THEME.BG_CONTENT, 0.4 corner(f,6) stroke(f, THEME.ACCENT)
    local l = Instance.new("TextLabel", f) l.Size, l.Position, l.BackgroundTransparency, l.Text, l.TextColor3, l.Font, l.TextSize, l.TextXAlignment = UDim2.new(1,-50,1,0), UDim2.new(0,10,0,0), 1, t, THEME.TEXT, Enum.Font.Gotham, 11, 0
    local b = Instance.new("TextButton", f) b.Size, b.Position, b.BackgroundColor3, b.Text = UDim2.new(0,30,0,16), UDim2.new(1,-40,0.5,-8), d and THEME.ACCENT or Color3.fromRGB(200,200,200), "" corner(b,8) stroke(b, THEME.ACCENT)
    local o = Instance.new("Frame", b) o.Size, o.Position, o.BackgroundColor3 = UDim2.new(0,12,0,12), UDim2.new(d and 1 or 0, d and -14 or 2, 0.5, -6), Color3.new(1,1,1) corner(o,6)
    local en = d b.MouseButton1Click:Connect(function() en = not en tween(b,{BackgroundColor3=en and THEME.ACCENT or Color3.fromRGB(200,200,200)},0.2) tween(o,{Position=UDim2.new(en and 1 or 0, en and -14 or 2, 0.5,-6)},0.2) c(en) end)
    return {Set = function(v) en = v b.BackgroundColor3 = en and THEME.ACCENT or Color3.fromRGB(200,200,200) o.Position = UDim2.new(en and 1 or 0, en and -14 or 2, 0.5,-6) end}
end
local function addSlider(p, t, min, max, d, dec, c)
    local f = Instance.new("Frame", p) f.Size, f.BackgroundColor3, f.BackgroundTransparency = UDim2.new(1,0,0,42), THEME.BG_CONTENT, 0.4 corner(f,6) stroke(f, THEME.ACCENT)
    local l = Instance.new("TextLabel", f) l.Size, l.Position, l.BackgroundTransparency, l.Text, l.TextColor3, l.Font, l.TextSize, l.TextXAlignment = UDim2.new(1,-20,0,20), UDim2.new(0,10,0,4), 1, t..": "..d, THEME.TEXT, Enum.Font.Gotham, 11, 0
    local bg = Instance.new("Frame", f) bg.Size, bg.Position, bg.BackgroundColor3 = UDim2.new(1,-20,0,3), UDim2.new(0,10,0,30), Color3.new(0,0,0) corner(bg,2)
    local fill = Instance.new("Frame", bg) fill.Size, fill.BackgroundColor3 = UDim2.new((d-min)/(max-min),0,1,0), THEME.ACCENT corner(fill,2)
    local btn = Instance.new("Frame", bg) btn.Size, btn.Position, btn.BackgroundColor3 = UDim2.new(0,10,0,10), UDim2.new((d-min)/(max-min),-5,0.5,-5), THEME.ACCENT corner(btn,5)
    local tr = Instance.new("TextButton", f) tr.Size, tr.BackgroundTransparency, tr.Text = UDim2.new(1,0,1,0), 1, ""
    local prec, drag = 10^(dec or 0), false
    local function fV(v) return (dec or 0) <= 0 and tostring(math.round(v)) or tostring(math.floor(v*prec+0.5)/prec) end
    local function up(i) local rel = math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X, 0, 1) local v = math.floor((min+(max-min)*rel)*prec+0.5)/prec l.Text, fill.Size, btn.Position = t..": "..fV(v), UDim2.new(rel,0,1,0), UDim2.new(rel,-5,0.5,-5) c(v) end
    tr.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true up(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
    UserInputService.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then up(i) end end)
    return {Set = function(v) local rel = math.clamp((v-min)/(max-min), 0,1) l.Text, fill.Size, btn.Position = t..": "..fV(v), UDim2.new(rel,0,1,0), UDim2.new(rel,-5,0.5,-5) end}
end
local function addInput(p, t, d, ph, c)
    local f = Instance.new("Frame", p) f.Size, f.BackgroundColor3 = UDim2.new(1,0,0,55), THEME.BG_CONTENT corner(f,6)
    local l = Instance.new("TextLabel", f) l.Size, l.Position, l.BackgroundTransparency, l.Text, l.TextColor3, l.Font, l.TextSize, l.TextXAlignment = UDim2.new(1,-20,0,25), UDim2.new(0,12,0,5), 1, t, THEME.TEXT, Enum.Font.Gotham, 13, 0
    local i = Instance.new("TextBox", f) i.Size, i.Position, i.BackgroundColor3, i.Text, i.PlaceholderText, i.TextColor3, i.Font, i.TextSize, i.ClearTextOnFocus = UDim2.new(1,-24,0,24), UDim2.new(0,12,0,26), THEME.BG_MAIN, d, ph, THEME.TEXT, Enum.Font.Gotham, 12, false corner(i,4) i.FocusLost:Connect(function() c(i.Text) end) return i
end
local function addButton(p, t, cl, c)
    local b = Instance.new("TextButton", p) b.Size, b.BackgroundColor3, b.Text, b.TextColor3, b.Font, b.TextSize = UDim2.new(1,0,0,30), cl or THEME.DARK_ITEM, t, THEME.TEXT, Enum.Font.GothamBold, 11 corner(b,6)
    b.MouseButton1Click:Connect(function() tween(b,{BackgroundTransparency=0.5},0.1) task.wait(0.1) tween(b,{BackgroundTransparency=0},0.1) c() end) return b
end
local function addDropdown(p, t, is, d, c)
    local f = Instance.new("Frame", p) f.Size, f.BackgroundColor3, f.BackgroundTransparency, f.ClipsDescendants = UDim2.new(1,0,0,32), THEME.BG_CONTENT, 0.4, true corner(f,6) stroke(f, THEME.ACCENT)
    local l = Instance.new("TextButton", f) l.Size, l.BackgroundTransparency, l.Text, l.TextColor3, l.Font, l.TextSize, l.TextXAlignment = UDim2.new(1,0,0,32), 1, "  "..t..": "..d, THEME.TEXT, Enum.Font.Gotham, 11, 0
    local list = Instance.new("Frame", f) list.Size, list.Position, list.BackgroundTransparency = UDim2.new(1,0,0,#is*26), UDim2.new(0,0,0,32), 1 Instance.new("UIListLayout", list)
    for _,v in is do
        local ib = Instance.new("TextButton", list) ib.Size, ib.BackgroundColor3, ib.BackgroundTransparency, ib.BorderSizePixel, ib.Text, ib.TextColor3, ib.Font, ib.TextSize, ib.TextXAlignment = UDim2.new(1,0,0,26), THEME.DARK_ITEM, 0.5, 0, "    "..tostring(v), THEME.TEXT_DIM, Enum.Font.Gotham, 10, 0
        ib.MouseButton1Click:Connect(function() l.Text = "  "..t..": "..tostring(v) tween(f,{Size=UDim2.new(1,0,0,32)},0.2) c(v) end)
    end
    local op = false l.MouseButton1Click:Connect(function() op = not op tween(f,{Size=UDim2.new(1,0,0,op and (32+#is*26) or 32)},0.2) end)
    return {Set = function(v) l.Text = "  "..t..": "..tostring(v) end}
end
local function addCollapsible(p, ti)
    local c = Instance.new("Frame", p) c.Size, c.BackgroundColor3, c.BackgroundTransparency, c.ClipsDescendants, c.BorderSizePixel = UDim2.new(1,0,0,30), THEME.BG_CONTENT, 0.4, true, 0 corner(c,6) stroke(c, THEME.ACCENT)
    local b = Instance.new("TextButton", c) b.Size, b.BackgroundTransparency, b.Text, b.TextColor3, b.Font, b.TextSize, b.TextXAlignment = UDim2.new(1,0,0,30), 1, "  "..ti.." ▼", THEME.TEXT, Enum.Font.GothamBold, 10, 0
    local con = Instance.new("Frame", c) con.Position, con.Size, con.BackgroundTransparency = UDim2.new(0,0,0,30), UDim2.new(1,0,0,0), 1 local ly = Instance.new("UIListLayout", con) ly.Padding = UDim.new(0,4)
    local op = false b.MouseButton1Click:Connect(function() op = not op local h = op and (30+ly.AbsoluteContentSize.Y+8) or 30 tween(c,{Size=UDim2.new(1,0,0,h)},0.3) b.Text, b.TextColor3 = "  "..ti..(op and " ▲" or " ▼"), op and THEME.ACCENT or THEME.TEXT end)
    ly:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() if op then c.Size = UDim2.new(1,0,0,30+ly.AbsoluteContentSize.Y+8) end end) return con
end

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

local function GetCommF()
    return ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("CommF_", 5)
end
local function GetCommE()
    return ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("CommE", 5)
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
                if d <= vals.auraRadius then table.insert(targets, {model = pChar, dist = d}) end
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
    if now - lastHitTime < vals.auraDelay then return end
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
    if vals.auraMode == "Encode" then
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
    elseif vals.auraMode == "Unencode" then
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
    char:SetAttribute("AttackSpeedMultiplier", flags.fastM1 and fastMeleeMultiplier or 1)
    char:SetAttribute("FruitTAPCooldown", flags.fastM1 and fastFruitMultiplier or 1)
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
    if now - lastAttack < vals.auraFruitDelay then return end
    lastAttack = now
    local tool, remote = getCurrentTool()
    if not tool or not remote then return end
    local target = getNearestTarget()
    if not target or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local dist = (target.Position - char.HumanoidRootPart.Position).Magnitude
    if dist > vals.auraFruitRadius then return end
    
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
        if vs and vs:IsA("VehicleSeat") then vs.MaxSpeed = vals.flyBoatSpeed; count += 1 end
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

local TabHitbox = createTab("j4f")
local TabSpecialFarm = createTab("Special Farm")
local TabBlox = createTab("Blox Fruit")
local TabUtils = createTab("Utils")
local TabSettings = createTab("Settings")

-- HITBOX TAB
local currentHBT = "self"
local hbToggleUi, hbSizeUi, hbShowUi, hbPathUi, hbMobSection, partToggles = nil, nil, nil, nil, nil, {}

addSection(TabHitbox, "Target Settings")
addDropdown(TabHitbox, "Select Target", {"Self", "Players", "Mobs"}, "Self", function(v)
    local mapping = {["Self"] = "self", ["Players"] = "others", ["Mobs"] = "mob"}
    currentHBT = mapping[v] or "self"
    hbToggleUi.Set(hitboxEnabled[currentHBT]) hbSizeUi.Set(hitboxSize[currentHBT]) hbShowUi.Set(showHitbox[currentHBT])
    local isMob = (currentHBT == "mob")
    if hbMobSection then hbMobSection.Visible = isMob end
    if hbPathUi then hbPathUi.Parent.Visible = isMob end
    for p, toggle in pairs(partToggles) do toggle.Set(selectedBodyParts[currentHBT][p]) end
end)

addSection(TabHitbox, "Hitbox Controls")
hbToggleUi = addToggle(TabHitbox, "Enabled", false, function(v) hitboxEnabled[currentHBT] = v if not v then disableHitbox(currentHBT) end end) ui_controls.hbToggle = hbToggleUi
hbSizeUi = addSlider(TabHitbox, "Size", 5, 500, 10, 0, function(v) hitboxSize[currentHBT] = v end) ui_controls.hbSize = hbSizeUi
hbShowUi = addToggle(TabHitbox, "Show Hitbox", false, function(v) showHitbox[currentHBT] = v end) ui_controls.hbShow = hbShowUi

addSection(TabHitbox, "Part Selection")
local partList = addCollapsible(TabHitbox, "Select Body Parts")
local parts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart"}
for _, p in ipairs(parts) do 
    partToggles[p] = addToggle(partList, p, false, function(v) selectedBodyParts[currentHBT][p] = v end)
    ui_controls["part_"..p] = partToggles[p]
end

hbMobSection = addSection(TabHitbox, "Mob Settings")
hbPathUi = addInput(TabHitbox, "Mob Path", mobPath, "workspace.Enemies", function(v) mobPath = v end) ui_controls.hbPath = hbPathUi
hbMobSection.Visible = false hbPathUi.Parent.Visible = false

addSection(TabHitbox, "Danger Zone")
addButton(TabHitbox, "Reset Hitbox Configuration", THEME.RED, function()
    hitboxEnabled[currentHBT], hitboxSize[currentHBT], showHitbox[currentHBT] = false, 10, false
    for p, _ in pairs(selectedBodyParts[currentHBT]) do selectedBodyParts[currentHBT][p] = false end
    disableHitbox(currentHBT) hbToggleUi.Set(false) hbSizeUi.Set(10) hbShowUi.Set(false)
    for p, toggle in pairs(partToggles) do toggle.Set(false) end
end)

-- BLOX FRUIT TAB
addSection(TabBlox, "Blox Fruit Config")
local combatConfig = addCollapsible(TabBlox, "Config")

-- 1. Auto Equip
ui_controls.autoEquip = addDropdown(combatConfig, "Auto Equip Weapon", {"Melee", "Sword", "Blox Fruit"}, "Melee", function(v) vals.autoEquipType = v end)

-- 2. Aura Melee (Fast Attack)
addSection(combatConfig, "Aura Melee")
ui_controls.auraEnabled = addToggle(combatConfig, "Enabled", true, function(v) auraEnabled = v if v then auraConnection = RunService.Heartbeat:Connect(performHit) elseif auraConnection then auraConnection:Disconnect() auraConnection = nil end end)
if auraEnabled then auraConnection = RunService.Heartbeat:Connect(performHit) end
ui_controls.auraRadius = addSlider(combatConfig, "Range", 5, 1000, 1000, 0, function(v) vals.auraRadius = v end)
ui_controls.auraDelay = addSlider(combatConfig, "Delay", 0.01, 1, 0.01, 2, function(v) vals.auraDelay = v end)
ui_controls.auraMode = addDropdown(combatConfig, "Mode", {"Fast Attack Unencode", "Fast Attack Encode"}, "Fast Attack Unencode", function(v) vals.auraMode = v:find("Encode") and "Encode" or "Unencode" end)

-- 3. Aura Fruit (Fast Attack Fruit)
addSection(combatConfig, "Aura Fruit")
ui_controls.fruitEnabled = addToggle(combatConfig, "Enabled", true, function(v) auraFruitEnabled = v if v then spamConnection = RunService.Heartbeat:Connect(spamFruit) elseif spamConnection then spamConnection:Disconnect() spamConnection = nil end end)
if auraFruitEnabled then spamConnection = RunService.Heartbeat:Connect(spamFruit) end
ui_controls.fruitDelay = addSlider(combatConfig, "Delay", 0.01, 1, 0.01, 2, function(v) vals.auraFruitDelay = v end)
addDropdown(combatConfig, "Select Skill", {"Skill 1", "Skill 2", "Skill 3", "Skill 4", "Skill 5"}, "Skill 1", function(v) local s = tonumber(v:match("%d+")) for i = 1, 5 do selectedAttacks[i] = (i == s) end end)

-- 4. Auto Ability
addSection(combatConfig, "Auto Ability")
ui_controls.autoRaceV3 = addToggle(combatConfig, "Auto Race V3", false, function(v) flags.autoRaceV3 = v end)
ui_controls.autoActiveV4 = addToggle(combatConfig, "Auto Active V4", false, function(v) flags.autoActiveV4 = v end)
ui_controls.autoBuso = addToggle(combatConfig, "Auto Buso", true, function(v) flags.autoBuso = v end)

-- 5. Fast M1
addSection(combatConfig, "Fast M1")
ui_controls.fastM1Enabled = addToggle(combatConfig, "Enable Fast M1", false, function(v) flags.fastM1 = v applyFastM1() end)
ui_controls.fastMelee = addSlider(combatConfig, "Melee/Gun Multi", 1, 5, 1, 0, function(v) fastMeleeMultiplier = math.floor(v + 0.5) applyFastM1() end)
ui_controls.fastFruit = addSlider(combatConfig, "Fruit Multi", 1, 5, 1, 0, function(v) fastFruitMultiplier = math.floor(v + 0.5) applyFastM1() end)

-- 6. Bone Farm
local boneFarmConfig = addCollapsible(TabSpecialFarm, "Bone Farm")
ui_controls.autoFarmBones = addToggle(boneFarmConfig, "Auto Farm Bones", false, function(v) flags.autoFarmBones = v end)
ui_controls.autoTradeBones = addToggle(boneFarmConfig, "Auto Trade Bones", false, function(v) flags.autoTradeBones = v end)

local secretIslandList = addCollapsible(TabBlox, "Secret Island")
ui_controls.mirageEsp = addToggle(secretIslandList, "Mirage Island ESP", false, function(v) islandEspSettings.ESP_List["Mirage Island"] = v end)
ui_controls.kitsuneEsp = addToggle(secretIslandList, "Kitsune Island ESP", false, function(v) islandEspSettings.ESP_List["Kitsune Island"] = v end)
ui_controls.prehistoricEsp = addToggle(secretIslandList, "Prehistoric Island ESP", false, function(v) islandEspSettings.ESP_List["Prehistoric Island"] = v end)

addSection(secretIslandList, "Island Tween")
local function islandTween(islandName, enabled) islandTweenEnabled[islandName] = enabled end
ui_controls.tweenMirage = addToggle(secretIslandList, "Tween Mirage Island", false, function(v) islandTween("Mirage Island", v) end)
ui_controls.tweenKitsune = addToggle(secretIslandList, "Tween Kitsune Island", false, function(v) islandTween("Kitsune Island", v) end)
ui_controls.tweenPrehistoric = addToggle(secretIslandList, "Tween Prehistoric Island", false, function(v) islandTween("Prehistoric Island", v) end)
ui_controls.tweenSpeed = addSlider(secretIslandList, "Tween Speed", 200, 500, 360, 0, function(v) islandTweenSpeed = v end)

addSection(secretIslandList, "Auto Chest Mirage")
ui_controls.autoChest = addToggle(secretIslandList, "Enabled Auto Chest", false, function(v) vals.autoChestMirage = v end)
ui_controls.autoChestStyle = addDropdown(secretIslandList, "Chest Style", {"TP", "Tween"}, "Tween", function(v) vals.autoChestStyle = v end)
ui_controls.autoChestType = addDropdown(secretIslandList, "Chest Type", {"All", "Fragment", "Mirage"}, "All", function(v) vals.autoChestType = v end)

local trialSection = addCollapsible(TabBlox, "Trial")
ui_controls.autoUpgradeRace = addToggle(trialSection, "Auto Upgrade Race", false, function(v) flags.autoUpgradeRace = v end)
addButton(trialSection, "TP On Top Great Tree", THEME.ACCENT, function()
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
                    local speed = vals.islandTweenSpeed or 360
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
end)

addButton(trialSection, "TP to Ancient One", THEME.ACCENT, function()
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
                    local speed = vals.islandTweenSpeed or 360
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
end)

addButton(trialSection, "TP to Clocks", THEME.ACCENT, function()
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
end)

do -- SPECIAL FARM TAB
    local bossFarmList = addCollapsible(TabSpecialFarm, "Auto Boss Config")
    ui_controls.autoBoss = addToggle(bossFarmList, "Auto Boss", false, function(v) flags.autoBoss = v if not v then autoBossTargetObj = nil end end)
    ui_controls.autoBossHop = addToggle(bossFarmList, "Auto Boss (Hop Server)", false, function(v) flags.autoBossHop = v end)
    ui_controls.customBoss = addToggle(bossFarmList, "Custom Boss (Selection)", false, function(v) 
        flags.customBoss = v 
        if ui_controls.bossSelectFrame then ui_controls.bossSelectFrame.Visible = v end
    end)

    local bossSelectContainer = addCollapsible(bossFarmList, "Select Bosses")
    ui_controls.bossSelectFrame = bossSelectContainer.Parent
    ui_controls.bossSelectFrame.Visible = false

    local function refreshBossList()
        for _, child in ipairs(bossSelectContainer:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        local spawns = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("EnemySpawns")
        if spawns then
            for _, v in ipairs(spawns:GetChildren()) do
                if v.Name:find("%[Boss%]") then
                    local bName = v.Name
                    if not selectedBosses[bName] then selectedBosses[bName] = false end
                    addToggle(bossSelectContainer, bName, selectedBosses[bName], function(en)
                        selectedBosses[bName] = en
                    end)
                end
            end
        end
    end
    refreshBossList()
    addButton(bossFarmList, "Refresh Boss List", THEME.ACCENT, function() refreshBossList() end)

    local katakuriConfig = addCollapsible(TabSpecialFarm, "Katakuri (Cake Prince) Farm")
    ui_controls.autoCakeFarm = addToggle(katakuriConfig, "Auto Farm Katakuri", false, function(v) flags.autoCakeFarm = v if not v then autoCakeTargetObj = nil end end)
    ui_controls.autoCakeSpawn = addToggle(katakuriConfig, "Auto Spawn Katakuri", false, function(v) flags.autoCakeSpawn = v end)
end

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

    for name, enabled in pairs(islandFlags) do
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
                        local alpha = math.min((vals.islandTweenSpeed * dt) / dist, 1)
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
                local alpha = math.min((vals.islandTweenSpeed * dt) / (hrp.Position - targetPos).Magnitude, 1)
                hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, targetPos) * CFrame.new(0, 0, -(hrp.Position - targetPos).Magnitude), alpha)
            end
        end
    end

    if flags.flyBoat and currentBoat and currentBoat.Parent then
        local seat = currentBoat:FindFirstChildOfClass("VehicleSeat") or currentBoat:FindFirstChild("VehicleSeat", true)
        local isPlayerOnBoat = (seat and seat.Occupant ~= nil)
        if isPlayerOnBoat then
            if not cache.boatTarget then cache.boatTarget = hrp.Position end
            if #cache.boatParts == 0 then for _, v in ipairs(currentBoat:GetDescendants()) do if v:IsA("BasePart") then table.insert(cache.boatParts, v) end end end
            local cam, moveDir = workspace.CurrentCamera, Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
            if moveDir.Magnitude > 0 then cache.boatTarget = cache.boatTarget + (moveDir.Unit * vals.flyBoatSpeed * dt) end
            for _, v in ipairs(cache.boatParts) do v.Anchored, v.Velocity, v.RotVelocity = false, Vector3.zero, Vector3.zero end
            if vals.flyBoatStyle == "Custom" then hrp.CFrame = CFrame.lookAt(cache.boatTarget, cache.boatTarget + cam.CFrame.LookVector)
            else cache.boatTarget = Vector3.new(cache.boatTarget.X, vals.flyBoatHeight, cache.boatTarget.Z) hrp.CFrame = CFrame.new(cache.boatTarget) * CFrame.lookAt(Vector3.zero, Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)).Rotation end
        else
            cache.boatTarget = (currentBoat.PrimaryPart or currentBoat:FindFirstChildWhichIsA("BasePart")).Position
            for _, v in ipairs(cache.boatParts) do if not v.Anchored then v.Anchored = true end end
        end
    end

    -- Combat & Movement
    if flags.fastM1 then applyFastM1() end
    if flags.tpEnabled and hum and hum.MoveDirection.Magnitude > 0 then
        local extra = (vals.tpSpeed - 1) * hum.WalkSpeed
        if extra > 0 then hrp.CFrame = hrp.CFrame + (hum.MoveDirection * extra * dt) end
    end
    
    if flags.waterWalk then
        if flags.antiWater and hrp.Position.Y < vals.antiWaterThreshold then
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
    
    if flags.infinityJump then char:SetAttribute("SkyjumpBoost", 3000) end
    if vals.dashLength > 0 then char:SetAttribute("DashLength", vals.dashLength) end
    if hum then 
        if flags.jumpHeight then hum.UseJumpPower, hum.JumpHeight = false, vals.jumpHeight
        else hum.UseJumpPower = true end
    end

    -- Auto Boss Tween (Real-time tracking)
    if flags.autoBoss and autoBossTargetObj then
        local tH = autoBossTargetObj:IsA("Model") and autoBossTargetObj:FindFirstChildOfClass("Humanoid")
        if tH and tH.Health <= 0 then autoBossTargetObj = nil return end
        
        local targetPart = autoBossTargetObj:IsA("Model") and (autoBossTargetObj.PrimaryPart or autoBossTargetObj:FindFirstChild("HumanoidRootPart") or autoBossTargetObj:FindFirstChildWhichIsA("BasePart")) or autoBossTargetObj
        if targetPart then
            for _, v in ipairs(characterParts) do v.CanCollide = false end
            hrp.Velocity = Vector3.new(0, 0, 0)
            local targetPos = targetPart.Position + Vector3.new(0, vals.safeHeight, 0)
            local dist = (hrp.Position - targetPos).Magnitude
            if dist > 0.5 then
                local speed = (dist < 140) and 1300 or 360
                local moveDist = math.min(speed * dt, dist)
                local direction = (targetPos - hrp.Position).Unit
                if direction.X == direction.X then hrp.CFrame = hrp.CFrame + (direction * moveDist) end
            end
        end
    elseif flags.autoFarmBones and autoBoneTargetObj then
        local tH = autoBoneTargetObj:IsA("Model") and autoBoneTargetObj:FindFirstChildOfClass("Humanoid")
        if tH and tH.Health <= 0 then autoBoneTargetObj = nil return end
        
        local targetPart = autoBoneTargetObj:IsA("Model") and (autoBoneTargetObj.PrimaryPart or autoBoneTargetObj:FindFirstChild("HumanoidRootPart") or autoBoneTargetObj:FindFirstChildWhichIsA("BasePart")) or autoBoneTargetObj
        if targetPart then
            for _, v in ipairs(characterParts) do v.CanCollide = false end
            hrp.Velocity = Vector3.new(0, 0, 0)
            local targetPos = targetPart.Position + Vector3.new(0, vals.safeHeight, 0)
            local dist = (hrp.Position - targetPos).Magnitude
            if dist > 0.5 then
                local speed = (dist < 140) and 1300 or 360
                local moveDist = math.min(speed * dt, dist)
                local direction = (targetPos - hrp.Position).Unit
                if direction.X == direction.X then hrp.CFrame = hrp.CFrame + (direction * moveDist) end
            end
        end
    elseif flags.autoCakeFarm and autoCakeTargetObj then
        local tH = autoCakeTargetObj:IsA("Model") and autoCakeTargetObj:FindFirstChildOfClass("Humanoid")
        if tH and tH.Health <= 0 then autoCakeTargetObj = nil return end
        
        local targetPart = autoCakeTargetObj:IsA("Model") and (autoCakeTargetObj.PrimaryPart or autoCakeTargetObj:FindFirstChild("HumanoidRootPart") or autoCakeTargetObj:FindFirstChildWhichIsA("BasePart")) or autoCakeTargetObj
        if targetPart then
            for _, v in ipairs(characterParts) do v.CanCollide = false end
            hrp.Velocity = Vector3.new(0, 0, 0)
            local targetPos = targetPart.Position + Vector3.new(0, vals.safeHeight, 0)
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
        if flags.autoDungeon and char and char:FindFirstChild("HumanoidRootPart") then
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
        if flags.autoBoss and char and char:FindFirstChild("HumanoidRootPart") then
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
                        if not flags.customBoss or selectedBosses[fullName] then
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
                                if not flags.customBoss or selectedBosses[s.Name] then
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
                        if flags.autoBossHop then
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
        if flags.autoFarmBones and char and char:FindFirstChild("HumanoidRootPart") then
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
        if flags.autoCakeFarm and char and char:FindFirstChild("HumanoidRootPart") then
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
                    equip(vals.autoEquipType)
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
        if root then vals.safeHeight = (root:FindFirstChild("Buddha") or root:FindFirstChild("Buddha2")) and 35 or 15 end
        if flags.autoBuso and char then 
            pcall(function() 
                local rem = GetCommF()
                if rem and not char:FindFirstChild("HasBuso") then rem:InvokeServer("Buso") end
            end) 
        end
        for t, e in pairs(hitboxEnabled) do if e then expandHitbox(t) end end
        updateBoatSpeeds()
        updateIslandESP()
        if vals.autoChestMirage or islandEspSettings.Enabled then
            cache.mirage = findIsland("Mirage Island")
            cache.kitsune = findIsland("Kitsune Island")
            cache.prehistoric = findIsland("Prehistoric Island")
            if vals.autoChestMirage and cache.mirage then
                local chestFolder = workspace:FindFirstChild("ChestModels")
                if chestFolder then
                    for _, chest in ipairs(chestFolder:GetChildren()) do
                        if not cache.touchedChests[chest] then
                            local n = chest.Name:lower()
                            if (vals.autoChestType == "All") or (vals.autoChestType == "Fragment" and n:find("fragment")) or (vals.autoChestType == "Mirage" and n:find("mirage")) then
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
        if flags.autoCakeSpawn then
            pcall(function()
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("CakePrinceSpawner", true)
                task.wait(0.1)
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("CakePrinceSpawner")
            end)
        end
    end
end)

do -- LOCAL PLAYER TAB
    local lpList = addCollapsible(TabBlox, "LocalPlayer")
    addToggle(lpList, "Infinity Sky Jump", false, function(v) flags.infinityJump = v if not v and char then char:SetAttribute("SkyjumpBoost", nil) end end)
    addToggle(lpList, "Jump Height Enabled", false, function(v) flags.jumpHeight = v end)
    addSlider(lpList, "Jump Height", 7.2, 1000, 7.2, 1, function(v) vals.jumpHeight = v end)
    addSlider(lpList, "Dash Length", 0, 500, 0, 1, function(v) vals.dashLength = v end)
    ui_controls.waterWalk = addToggle(lpList, "Water Walk", true, function(v) flags.waterWalk = v end)
    ui_controls.antiWater = addToggle(lpList, "Anti Water", true, function(v) flags.antiWater = v end)
end

do -- FRUIT TAB
    local fruitSection = addCollapsible(TabBlox, "Fruit")
    ui_controls.autoStoreFruit = addToggle(fruitSection, "Auto Store Fruit", false, function(v) flags.autoStoreFruit = v end)
    addButton(fruitSection, "Store All Fruits (1 Click)", THEME.ACCENT, function() storeAllFruits() end)
    ui_controls.autoRandomFruit = addToggle(fruitSection, "Auto Random Fruit", false, function(v) flags.autoRandomFruit = v end)
    addButton(fruitSection, "Random Fruit (1 Click)", THEME.ACCENT, function() 
        pcall(function() 
            local rem = GetCommF()
            if rem then rem:InvokeServer("Cousin", "Buy", "DLCBoxData") end
        end) 
    end)
end

do -- SEA EVENT TAB
    local seaEventList = addCollapsible(TabBlox, "Sea Event")
    local boatStatusF = Instance.new("Frame", seaEventList)
    boatStatusF.Size = UDim2.new(1, 0, 0, 25) boatStatusF.BackgroundTransparency = 1
    local boatStatusLabel = Instance.new("TextLabel", boatStatusF) -- Localize within do block
    boatStatusLabel.Size, boatStatusLabel.BackgroundTransparency = UDim2.new(1,0,1,0), 1
    boatStatusLabel.Text = "🔍 Quét thuyền..." boatStatusLabel.TextColor3 = THEME.TEXT_DIM boatStatusLabel.Font = Enum.Font.Gotham boatStatusLabel.TextSize = 12
    
    ui_controls.boatSpeed = addSlider(seaEventList, "Boat Speed", 200, 600, 200, 0, function(v) boatSpeed = v updateBoatSpeeds() end)
    addButton(seaEventList, "Buy Marine Boat", THEME.ACCENT, function() pcall(function() if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = CFrame.new(-16919, 9, 503) task.wait(0.1) ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("BuyBoat", "MarineGrandBrigade") end end) end)
    
    addButton(seaEventList, "TP Boat to Player", THEME.ACCENT, function()
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
                            if flags.flyBoat then cache.boatTarget = hrp.Position end
                        end
                        break
                    end
                end
            end
        end)
    end)
    
    ui_controls.flyboat = addToggle(seaEventList, "flyboat", false, function(v)
        flags.flyBoat = v
        if v then
            local boats = workspace:FindFirstChild("Boats")
            if not boats or not char or not char:FindFirstChild("HumanoidRootPart") then flags.flyBoat = false if ui_controls.flyboat then ui_controls.flyboat.Set(false) end return end
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
            else flags.flyBoat = false if ui_controls.flyboat then ui_controls.flyboat.Set(false) end end
        else currentBoat, cache.boatTarget = nil, nil end
    end)
    
    ui_controls.flyboatSpeed = addSlider(seaEventList, "speed flyboat", 100, 1000, 200, 0, function(v) vals.flyBoatSpeed = v end)
    ui_controls.flyboatHeight = addSlider(seaEventList, "boat height", 20, 600, 125, 0, function(v) vals.flyBoatHeight = v end)
    ui_controls.flyboatStyle = addDropdown(seaEventList, "Fly Style", {"Default", "Custom"}, "Default", function(v) flyBoatStyle = v end)
    
    addButton(seaEventList, "Remove Rocks", THEME.ACCENT, function()
        pcall(function()
            for _, v in ipairs(workspace:GetDescendants()) do
                if v.Name == "Rocks" then pcall(function() v:Destroy() end) end
            end
        end)
    end)
end

local shopList = addCollapsible(TabBlox, "Shop")
addButton(shopList, "Reset Stat (Buy)", THEME.ACCENT, function()
    pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("BlackbeardReward", "Refund", "2") end)
end)

do -- UTILS TAB
    addSection(TabUtils, "Movement")
    local tpWalkList = addCollapsible(TabUtils, "TP Walk")
    ui_controls.tpEnabled = addToggle(tpWalkList, "Enabled", false, function(v) flags.tpEnabled = v end)
    ui_controls.tpSpeed = addSlider(tpWalkList, "Speed Mult", 1, 8, 2, 1, function(v) vals.tpSpeed = v end)
    
    addSection(TabUtils, "Visuals")
    local espList = addCollapsible(TabUtils, "Player ESP")
    ui_controls.espEnabled = addToggle(espList, "Enabled", false, function(v) espSettings.Enabled = v if not v then clearESP() end end)
    ui_controls.espText = addToggle(espList, "Show HP Text", true, function(v) espSettings.ShowText = v end)
    ui_controls.espBar = addToggle(espList, "Show HP Bar", true, function(v) espSettings.ShowBar = v end)
    
    addSection(TabUtils, "Others")
    ui_controls.antiAfk = addToggle(TabUtils, "Anti-AFK", true, function(v) flags.antiAfk = v end)
    addButton(TabUtils, "Remove Fog & Effects", THEME.ACCENT, function()
        for _, v in Lighting:GetChildren() do if v:IsA("Atmosphere") or v.Name:find("Fog") then pcall(function() v:Destroy() end) end end
        Lighting.FogEnd, Lighting.FogStart, Lighting.GlobalShadows, Lighting.ExposureCompensation = 9e9, 0, false, 1
    end)
    addButton(TabUtils, "Infinite Yield", THEME.ACCENT, function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)
end

addSection(TabUtils, "Server Hopper")
local hopFrame = Instance.new("Frame", TabUtils)
hopFrame.Size, hopFrame.BackgroundTransparency = UDim2.new(1, 0, 0, 25), 1
hopStatusLabel = Instance.new("TextLabel", hopFrame)
hopStatusLabel.Size, hopStatusLabel.BackgroundTransparency = UDim2.new(1, 0, 1, 0), 1
hopStatusLabel.Text, hopStatusLabel.TextColor3, hopStatusLabel.Font, hopStatusLabel.TextSize = "Bấm để săn server vắng nhất", THEME.TEXT_DIM, Enum.Font.Gotham, 12

addButton(TabUtils, "Small Server Hop", THEME.ACCENT, function() executeHop() end)
addButton(TabUtils, "Old-like (Low Population)", THEME.DARK_ITEM, function() hopToOldServer("4h") end)
addButton(TabUtils, "Old-like (Fast Scan)", THEME.DARK_ITEM, function() hopToOldServer("3h45") end)

do -- SETTINGS & DUNGEON
    local dungeonSection = addCollapsible(TabBlox, "Dungeon") -- Back to Blox Fruit tab
    ui_controls.autoDungeon = addToggle(dungeonSection, "Auto Dungeon", false, function(v) flags.autoDungeon = v end)

    local customIconList = addCollapsible(TabSettings, "Custom Button Icon")
    local helpLabel = Instance.new("TextLabel", customIconList)
    helpLabel.Size, helpLabel.BackgroundTransparency = UDim2.new(1,0,0,80), 1
    helpLabel.Text = "📖 Hướng dẫn lấy ID:\n1. Mở Roblox Website > Create > Dashboard\n2. Chọn Development Items > Decals\n3. Copy dãy số (ID) của ảnh bạn muốn dán vào đây."
    helpLabel.TextColor3, helpLabel.Font, helpLabel.TextSize, helpLabel.TextWrapped = THEME.TEXT_DIM, Enum.Font.Gotham, 11, true

    addInput(customIconList, "Icon Button ID", "84053545044369", "Dán ID số vào đây...", function(v)
        local idOnly = v:match("%d+")
        if idOnly then
            ToggleBtn.Image = "rbxthumb://type=Asset&id=" .. idOnly .. "&w=420&h=420"
        end
    end)
end

local last10s, last2s = 0, 0
task.spawn(function()
    while true do
        task.wait(1)
        local now = tick()
        if flags.autoRaceV3 then 
            pcall(function() 
                local rem = GetCommE()
                if rem then rem:FireServer("ActivateAbility") end
            end) 
        end
        if flags.autoStoreFruit then storeAllFruits() end
        if flags.autoUpgradeRace then 
            pcall(function() 
                local rem = GetCommF()
                if rem then rem:InvokeServer("UpgradeRace", "Buy") end
            end) 
        end
        if flags.autoActiveV4 then
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
        if flags.autoTradeBones and now - last2s >= 2 then
            last2s = now
            pcall(function() 
                local rem = GetCommF()
                if rem then rem:InvokeServer("Bones", "Buy", 1, 1) end
            end)
        end
        if flags.autoRandomFruit and now - last10s >= 10 then
            last10s = now
            pcall(function() 
                local rem = GetCommF()
                if rem then rem:InvokeServer("Cousin", "Buy", "DLCBoxData") end
            end)
        end
        if now % 1200 < 1 then hoppedServers = {} end
    end
end)

player.Idled:Connect(function()
    if flags.antiAfk then
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    end
end)


if #tabBtns > 0 then
    for _, p in pages do p.Visible = false end
    for _, b in tabBtns do b.BackgroundTransparency = 1; b.TextColor3 = THEME.TEXT_DIM end
    pages[1].Visible = true
    tabBtns[1].BackgroundTransparency = 0
    tabBtns[1].TextColor3 = THEME.ACCENT
end

