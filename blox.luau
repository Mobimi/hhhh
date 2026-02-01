local Players, RunService, UserInputService, CoreGui, ReplicatedStorage, TweenService, HttpService, TeleportService, Lighting = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("CoreGui"), game:GetService("ReplicatedStorage"), game:GetService("TweenService"), game:GetService("HttpService"), game:GetService("TeleportService"), game:GetService("Lighting")
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
local mobPath, originalProperties, processedParts, mobCache = "workspace", {}, {}, {lastScan = 0, list = {}}
local auraEnabled, auraRadius, auraDelay, lastHitTime, hitCount = false, 20, 0.01, 0, 0
local attackRemote, hitRemote, auraConnection, isSpamming, spamConnection, fruitDelay, lastAttack = nil, nil, nil, false, nil, 0.01, 0
local selectedAttacks, fastM1Enabled, fastMeleeMultiplier, fastFruitMultiplier = {true, true, true, true, true}, false, 1, 1
local boatSpeed, tpEnabled, tpSpeed, autoRaceV3Enabled, infinityJumpEnabled = 200, false, 2, false, false
local jumpHeightEnabled, jumpHeightValue, dashLengthValue, waterWalkEnabled, antiWaterEnabled, antiWaterThreshold = false, 7.2, 0, true, true, -0.807
local flyBoatEnabled, flyBoatSpeed, flyBoatHeight, currentBoat, flyBoatStyle, isPlayerOnBoat = false, 200, 125, nil, "Default", false
local islandTweenEnabled, islandTweenSpeed = {["Mirage Island"] = false, ["Kitsune Island"] = false, ["Prehistoric Island"] = false}, 300
local espSettings, espConnection, espBillboards = { Enabled = false, ShowText = true, ShowBar = true }, nil, {}
local islandEspSettings, islandEspBillboards = { Enabled = false, ESP_List = {["Mirage Island"] = false, ["Kitsune Island"] = false, ["Prehistoric Island"] = false} }, {}
local autoChestMirage, autoChestStyle, autoChestType, autoActiveV4Enabled, autoTradeBonesEnabled, autoStoreFruitEnabled, autoDungeonEnabled = false, "Tween", "All", false, false, false, false
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local baseScanInterval = isMobile and 0.8 or 0.5
local scanInterval, espInterval = baseScanInterval, isMobile and 1.0 or 0.5
local THEME = {BG_MAIN = Color3.fromRGB(15,15,20), BG_SIDE = Color3.fromRGB(22,22,28), BG_CONTENT = Color3.fromRGB(26,26,32), ACCENT = Color3.fromRGB(255,30,60), TEXT = Color3.fromRGB(255,255,255), TEXT_DIM = Color3.fromRGB(160,160,160), GREEN = Color3.fromRGB(60,230,120), RED = Color3.fromRGB(255,80,80), DARK_ITEM = Color3.fromRGB(35,35,45)}

local THEME = {
    BG_MAIN = Color3.fromRGB(15, 15, 20),
    BG_SIDE = Color3.fromRGB(22, 22, 28),
    BG_CONTENT = Color3.fromRGB(26, 26, 32),
    ACCENT = Color3.fromRGB(255, 30, 60),
    TEXT = Color3.fromRGB(255, 255, 255),
    TEXT_DIM = Color3.fromRGB(160, 160, 160),
    GREEN = Color3.fromRGB(60, 230, 120),
    RED = Color3.fromRGB(255, 80, 80),
    DARK_ITEM = Color3.fromRGB(35, 35, 45)
}

local function corner(p, r) local c = Instance.new("UICorner", p) c.CornerRadius = UDim.new(0, r or 8) return c end
local function stroke(p, c, t, b) local s = Instance.new("UIStroke", p) s.Color = c or (b and THEME.ACCENT or Color3.fromRGB(50,50,60)) s.Thickness = t or 1 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border return s end
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
        local m = ScreenGui.MainFrame m.BackgroundColor3, m.BackgroundTransparency = THEME.BG_MAIN, 0
        local s = m:FindFirstChild("Sidebar") if s then s.BackgroundColor3, s.BackgroundTransparency = THEME.BG_SIDE, 0 local l = s:FindFirstChild("SidebarLabel") if l then l.TextColor3 = THEME.ACCENT end end
        for _,v in allStrokes or {} do v.Color = Color3.fromRGB(50,50,60) end
        for _,v in allBtnStrokes or {} do v.Color = THEME.ACCENT end
    end
end

local ScreenGui = Instance.new("ScreenGui", CoreGui) ScreenGui.Name, ScreenGui.ResetOnSpawn = "HB_PRO_V3", false
local ToggleBtn = Instance.new("ImageButton", ScreenGui) ToggleBtn.Size, ToggleBtn.Position, ToggleBtn.BackgroundColor3, ToggleBtn.BackgroundTransparency, ToggleBtn.Image, ToggleBtn.ScaleType, ToggleBtn.ZIndex = UDim2.new(0,60,0,60), UDim2.new(0.02,0,0.5,-30), THEME.BG_SIDE, 0.2, "rbxthumb://type=Asset&id=84053545044369&w=420&h=420", Enum.ScaleType.Fit, 15
corner(ToggleBtn,12) stroke(ToggleBtn,THEME.ACCENT,2,true) makeDraggable(ToggleBtn)
local MainFrame = Instance.new("Frame", ScreenGui) MainFrame.Name, MainFrame.Size, MainFrame.Position, MainFrame.BackgroundColor3, MainFrame.BorderSizePixel, MainFrame.ClipsDescendants = "MainFrame", UDim2.new(0,540,0,340), UDim2.new(0.5,-270,0.5,-170), THEME.BG_MAIN, 0, true
corner(MainFrame,12) stroke(MainFrame,THEME.ACCENT,2,false) makeDraggable(MainFrame)
local Sidebar = Instance.new("Frame", MainFrame) Sidebar.Size, Sidebar.BackgroundColor3, Sidebar.BorderSizePixel = UDim2.new(0,110,1,0), THEME.BG_SIDE, 0 corner(Sidebar,12)
local SidebarLabel = Instance.new("TextLabel", Sidebar) SidebarLabel.Size, SidebarLabel.Position, SidebarLabel.BackgroundTransparency, SidebarLabel.Text, SidebarLabel.TextColor3, SidebarLabel.Font, SidebarLabel.TextSize = UDim2.new(1,0,0,35), UDim2.new(0,0,0,5), 1, "j4f", THEME.ACCENT, Enum.Font.GothamBold, 22
local AuthorLabel = Instance.new("TextLabel", Sidebar) AuthorLabel.Size, AuthorLabel.Position, AuthorLabel.BackgroundTransparency, AuthorLabel.Text, AuthorLabel.TextColor3, AuthorLabel.Font, AuthorLabel.TextSize = UDim2.new(1,0,0,20), UDim2.new(0,0,0,35), 1, "by tiktok: @realayako", THEME.TEXT_DIM, Enum.Font.GothamMedium, 10
local TabContainer = Instance.new("Frame", Sidebar) TabContainer.Size, TabContainer.Position, TabContainer.BackgroundTransparency = UDim2.new(1,0,1,-70), UDim2.new(0,0,0,70), 1
local TabLayout = Instance.new("UIListLayout", TabContainer) TabLayout.Padding, TabLayout.HorizontalAlignment = UDim.new(0,6), Enum.HorizontalAlignment.Center
ToggleBtn.MouseButton1Click:Connect(function() guiVisible = not guiVisible MainFrame.Visible = guiVisible tween(ToggleBtn, {BackgroundColor3 = guiVisible and THEME.BG_SIDE or Color3.fromRGB(30,30,35)}, 0.2) end)
local ContentArea = Instance.new("Frame", MainFrame) ContentArea.Size, ContentArea.Position, ContentArea.BackgroundTransparency = UDim2.new(1,-125,1,-15), UDim2.new(0,120,0,10), 1
local pages, tabBtns = {}, {}
local function createTab(name)
    local b = Instance.new("TextButton", TabContainer) b.Size, b.BackgroundColor3, b.BackgroundTransparency, b.Text, b.TextColor3, b.Font, b.TextSize = UDim2.new(0.85,0,0,36), THEME.DARK_ITEM, 1, name, THEME.TEXT_DIM, Enum.Font.GothamBold, 12 corner(b,8) stroke(b,THEME.DARK_ITEM,1,true)
    local p = Instance.new("ScrollingFrame", ContentArea) p.Size, p.BackgroundTransparency, p.Visible, p.ScrollBarThickness, p.ScrollBarImageColor3, p.AutomaticCanvasSize = UDim2.new(1,0,1,0), 1, false, 2, THEME.ACCENT, Enum.AutomaticSize.Y
    Instance.new("UIListLayout", p).Padding, Instance.new("UIListLayout", p).SortOrder = UDim.new(0,8), Enum.SortOrder.LayoutOrder
    b.MouseButton1Click:Connect(function() for _,x in pages do x.Visible = false end for _,x in tabBtns do tween(x,{BackgroundTransparency=1,TextColor3=THEME.TEXT_DIM},0.2) end p.Visible, b.BackgroundTransparency, b.TextColor3 = true, 0, THEME.ACCENT end)
    table.insert(pages, p) table.insert(tabBtns, b) return p
end

local function addSection(parent, title)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 30)
    f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = title:upper()
    l.TextColor3 = THEME.ACCENT
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    
    local line = Instance.new("Frame", f)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -2)
    line.BackgroundColor3 = THEME.ACCENT
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0
    stroke(f, THEME.ACCENT, 1, false)
    return f
end

local function addToggle(p, t, d, c)
    local f = Instance.new("Frame", p) f.Size, f.BackgroundColor3 = UDim2.new(1,0,0,40), THEME.BG_CONTENT corner(f,6)
    local l = Instance.new("TextLabel", f) l.Size, l.Position, l.BackgroundTransparency, l.Text, l.TextColor3, l.Font, l.TextSize, l.TextXAlignment = UDim2.new(1,-60,1,0), UDim2.new(0,12,0,0), 1, t, THEME.TEXT, Enum.Font.Gotham, 13, 0
    local b = Instance.new("TextButton", f) b.Size, b.Position, b.BackgroundColor3, b.Text = UDim2.new(0,36,0,20), UDim2.new(1,-48,0.5,-10), d and THEME.ACCENT or Color3.fromRGB(60,60,70), "" corner(b,10)
    local o = Instance.new("Frame", b) o.Size, o.Position, o.BackgroundColor3 = UDim2.new(0,16,0,16), UDim2.new(d and 1 or 0, d and -18 or 2, 0.5, -8), Color3.new(1,1,1) corner(o,8)
    local en = d b.MouseButton1Click:Connect(function() en = not en tween(b,{BackgroundColor3=en and THEME.ACCENT or Color3.fromRGB(60,60,70)},0.2) tween(o,{Position=UDim2.new(en and 1 or 0, en and -18 or 2, 0.5,-8)},0.2) c(en) end)
    return {Set = function(v) en = v b.BackgroundColor3 = en and THEME.ACCENT or Color3.fromRGB(60,60,70) o.Position = UDim2.new(en and 1 or 0, en and -18 or 2, 0.5,-8) end}
end
local function addSlider(p, t, min, max, d, dec, c)
    local f = Instance.new("Frame", p) f.Size, f.BackgroundColor3 = UDim2.new(1,0,0,55), THEME.BG_CONTENT corner(f,6)
    local l = Instance.new("TextLabel", f) l.Size, l.Position, l.BackgroundTransparency, l.Text, l.TextColor3, l.Font, l.TextSize, l.TextXAlignment = UDim2.new(1,-20,0,25), UDim2.new(0,12,0,5), 1, t..": "..d, THEME.TEXT, Enum.Font.Gotham, 13, 0
    local bg = Instance.new("Frame", f) bg.Size, bg.Position, bg.BackgroundColor3 = UDim2.new(1,-24,0,4), UDim2.new(0,12,0,38), Color3.fromRGB(45,45,55) corner(bg,2)
    local fill = Instance.new("Frame", bg) fill.Size, fill.BackgroundColor3 = UDim2.new((d-min)/(max-min),0,1,0), THEME.ACCENT corner(fill,2)
    local btn = Instance.new("Frame", bg) btn.Size, btn.Position, btn.BackgroundColor3 = UDim2.new(0,14,0,14), UDim2.new((d-min)/(max-min),-7,0.5,-7), Color3.new(1,1,1) corner(btn,7)
    local tr = Instance.new("TextButton", f) tr.Size, tr.BackgroundTransparency, tr.Text = UDim2.new(1,0,1,0), 1, ""
    local prec, drag = 10^(dec or 0), false
    local function fV(v) return (dec or 0) <= 0 and tostring(math.round(v)) or tostring(math.floor(v*prec+0.5)/prec) end
    local function up(i) local rel = math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X, 0, 1) local v = math.floor((min+(max-min)*rel)*prec+0.5)/prec l.Text, fill.Size, btn.Position = t..": "..fV(v), UDim2.new(rel,0,1,0), UDim2.new(rel,-7,0.5,-7) c(v) end
    tr.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true up(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
    UserInputService.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then up(i) end end)
    return {Set = function(v) local rel = math.clamp((v-min)/(max-min), 0,1) l.Text, fill.Size, btn.Position = t..": "..fV(v), UDim2.new(rel,0,1,0), UDim2.new(rel,-7,0.5,-7) end}
end
local function addInput(p, t, d, ph, c)
    local f = Instance.new("Frame", p) f.Size, f.BackgroundColor3 = UDim2.new(1,0,0,55), THEME.BG_CONTENT corner(f,6)
    local l = Instance.new("TextLabel", f) l.Size, l.Position, l.BackgroundTransparency, l.Text, l.TextColor3, l.Font, l.TextSize, l.TextXAlignment = UDim2.new(1,-20,0,25), UDim2.new(0,12,0,5), 1, t, THEME.TEXT, Enum.Font.Gotham, 13, 0
    local i = Instance.new("TextBox", f) i.Size, i.Position, i.BackgroundColor3, i.Text, i.PlaceholderText, i.TextColor3, i.Font, i.TextSize, i.ClearTextOnFocus = UDim2.new(1,-24,0,24), UDim2.new(0,12,0,26), THEME.BG_MAIN, d, ph, THEME.TEXT, Enum.Font.Gotham, 12, false corner(i,4) i.FocusLost:Connect(function() c(i.Text) end) return i
end
local function addButton(p, t, cl, c)
    local b = Instance.new("TextButton", p) b.Size, b.BackgroundColor3, b.Text, b.TextColor3, b.Font, b.TextSize = UDim2.new(1,0,0,36), cl or THEME.DARK_ITEM, t, THEME.TEXT, Enum.Font.GothamBold, 13 corner(b,6)
    b.MouseButton1Click:Connect(function() tween(b,{BackgroundTransparency=0.5},0.1) task.wait(0.1) tween(b,{BackgroundTransparency=0},0.1) c() end) return b
end
local function addDropdown(p, t, is, d, c)
    local f = Instance.new("Frame", p) f.Size, f.BackgroundColor3, f.ClipsDescendants = UDim2.new(1,0,0,40), THEME.BG_CONTENT, true corner(f,6)
    local l = Instance.new("TextButton", f) l.Size, l.BackgroundTransparency, l.Text, l.TextColor3, l.Font, l.TextSize, l.TextXAlignment = UDim2.new(1,0,0,40), 1, "  "..t..": "..d, THEME.TEXT, Enum.Font.Gotham, 13, 0
    local list = Instance.new("Frame", f) list.Size, list.Position, list.BackgroundTransparency = UDim2.new(1,0,0,#is*30), UDim2.new(0,0,0,40), 1 Instance.new("UIListLayout", list)
    for _,v in is do
        local ib = Instance.new("TextButton", list) ib.Size, ib.BackgroundColor3, ib.BorderSizePixel, ib.Text, ib.TextColor3, ib.Font, ib.TextSize, ib.TextXAlignment = UDim2.new(1,0,0,30), Color3.fromRGB(35,35,45), 0, "    "..tostring(v), THEME.TEXT_DIM, Enum.Font.Gotham, 12, 0
        ib.MouseButton1Click:Connect(function() l.Text = "  "..t..": "..tostring(v) tween(f,{Size=UDim2.new(1,0,0,40)},0.2) c(v) end)
    end
    local op = false l.MouseButton1Click:Connect(function() op = not op tween(f,{Size=UDim2.new(1,0,0,op and (40+#is*30) or 40)},0.2) end)
    return {Set = function(v) l.Text = "  "..t..": "..tostring(v) end}
end
local function addCollapsible(p, ti)
    local c = Instance.new("Frame", p) c.Size, c.BackgroundColor3, c.ClipsDescendants, c.BorderSizePixel = UDim2.new(1,0,0,36), THEME.BG_CONTENT, true, 0 corner(c,6)
    local b = Instance.new("TextButton", c) b.Size, b.BackgroundTransparency, b.Text, b.TextColor3, b.Font, b.TextSize, b.TextXAlignment = UDim2.new(1,0,0,36), 1, "  "..ti.." ▼", THEME.TEXT, Enum.Font.GothamBold, 12, 0
    local con = Instance.new("Frame", c) con.Position, con.Size, con.BackgroundTransparency = UDim2.new(0,0,0,36), UDim2.new(1,0,0,0), 1 local ly = Instance.new("UIListLayout", con) ly.Padding = UDim.new(0,4)
    local op = false b.MouseButton1Click:Connect(function() op = not op local h = op and (36+ly.AbsoluteContentSize.Y+8) or 36 tween(c,{Size=UDim2.new(1,0,0,h)},0.3) b.Text, b.TextColor3 = "  "..ti..(op and " ▲" or " ▼"), op and THEME.ACCENT or THEME.TEXT end)
    ly:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() if op then c.Size = UDim2.new(1,0,0,36+ly.AbsoluteContentSize.Y+8) end end) return con
end

-- HITBOX LOGIC
local function saveOriginal(p) if not originalProperties[p] then originalProperties[p] = {Size=p.Size, Transparency=p.Transparency, CanCollide=p.CanCollide, Color=p.Color, Material=p.Material} end end
local function applyHitbox(p, s, sh, c) if p.Size ~= Vector3.new(s,s,s) then p.Size = Vector3.new(s,s,s) end p.Transparency, p.CanCollide = sh and 0.5 or 1, false if sh then p.Color, p.Material = c, Enum.Material.ForceField end end
local function restoreHitbox(p) if originalProperties[p] then local o = originalProperties[p] p.Size, p.Transparency, p.CanCollide, p.Color, p.Material = o.Size, o.Transparency, o.CanCollide, o.Color, o.Material end end
local function expandHitbox(tt)
    if tt == "self" then if not char then return end for n,e in selectedBodyParts.self do if e then local p = char:FindFirstChild(n) if p and p:IsA("BasePart") then saveOriginal(p) applyHitbox(p, hitboxSize.self, showHitbox.self, Color3.new(0,1,0)) end end end
    elseif tt == "others" then for _,p in Players:GetPlayers() do if p ~= player and p.Character then for n,e in selectedBodyParts.others do if e then local pt = p.Character:FindFirstChild(n) if pt and pt:IsA("BasePart") then saveOriginal(pt) applyHitbox(pt, hitboxSize.others, showHitbox.others, Color3.new(1,0,0)) end end end end end
    elseif tt == "mob" then
        if tick() - (mobCache.lastScan or 0) > (isMobile and 1.5 or 1) then mobCache.lastScan = tick() mobCache.list = {} pcall(function() local c = game for s in string.gmatch(mobPath, "[^%.]+") do c = c:FindFirstChild(s) or c:WaitForChild(s, 1) end for _,d in c:GetDescendants() do if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") then table.insert(mobCache.list, d) end end end) end
        for _,m in mobCache.list do if m.Parent and m:FindFirstChildOfClass("Humanoid") and m:FindFirstChildOfClass("Humanoid").Health > 0 then for n,e in selectedBodyParts.mob do if e then local pt = m:FindFirstChild(n) if pt and pt:IsA("BasePart") then saveOriginal(pt) applyHitbox(pt, hitboxSize.mob, showHitbox.mob, Color3.new(1,0.65,0)) end end end end end
    end
end
local function disableHitbox(tt)
    if tt == "self" then if char then for n,_ in selectedBodyParts.self do local p = char:FindFirstChild(n) if p then restoreHitbox(p) end end end
    elseif tt == "others" then for _,p in Players:GetPlayers() do if p.Character then for n,_ in selectedBodyParts.others do local pt = p.Character:FindFirstChild(n) if pt then restoreHitbox(pt) end end end end
    elseif tt == "mob" then pcall(function() local c = game for s in string.gmatch(mobPath, "[^%.]+") do c = c:FindFirstChild(s) or c:WaitForChild(s, 1) end for _,d in c:GetDescendants() do if d:IsA("Model") then for n,_ in selectedBodyParts.mob do local pt = d:FindFirstChild(n) if pt then restoreHitbox(pt) end end end end end) end
end

-- COMBAT LOGIC
local function generateID()
    local chars, id = "0123456789abcdef", ""
    for i = 1, 8 do local r = math.random(1, 16) id = id .. chars:sub(r, r) end
    return id
end

local function getTargets(): {Model}
    local targets = {}
    if not char or not char:FindFirstChild("HumanoidRootPart") then return targets end
    local myPos = char.HumanoidRootPart.Position
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, e in enemies:GetChildren() do
            if e:IsA("Model") and e:FindFirstChild("HumanoidRootPart") then
                local h = e:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then
                    local d = (myPos - e.HumanoidRootPart.Position).Magnitude
                    if d <= auraRadius then table.insert(targets, {model = e, dist = d}) end
                end
            end
        end
    end
    for _, p in Players:GetPlayers() do
        if p ~= player and p.Character then
            local pHrp = p.Character:FindFirstChild("HumanoidRootPart")
            local pHum = p.Character:FindFirstChildOfClass("Humanoid")
            if pHrp and pHum and pHum.Health > 0 then
                local d = (myPos - pHrp.Position).Magnitude
                if d <= auraRadius then table.insert(targets, {model = p.Character, dist = d}) end
            end
        end
    end
    table.sort(targets, function(a, b) return a.dist < b.dist end)
    local result = {}
    for _, t in targets do table.insert(result, t.model) end
    return result
end

local function performHit()
    if not auraEnabled then return end
    local now = tick()
    if now - lastHitTime < auraDelay then return end
    lastHitTime = now
    local targets = getTargets()
    if #targets == 0 then return end
    if not attackRemote or not hitRemote then
        pcall(function()
            attackRemote = ReplicatedStorage.Modules.Net["RE/RegisterAttack"]
            hitRemote = ReplicatedStorage.Modules.Net["RE/RegisterHit"]
        end)
        if not attackRemote or not hitRemote then return end
    end
    pcall(function() attackRemote:FireServer() end)
    local multiTargets, firstPart = {}, nil
    for _, t in ipairs(targets) do
        local p = t:FindFirstChild("HumanoidRootPart") or t:FindFirstChild("Torso")
        if p then if not firstPart then firstPart = p end table.insert(multiTargets, {t, p}) end
    end
    if firstPart and #multiTargets > 0 then pcall(function() hitRemote:FireServer(firstPart, multiTargets, nil, generateID()) end) end
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
    if not isSpamming then return end
    local now = tick()
    if now - lastAttack < fruitDelay then return end
    lastAttack = now
    local tool, remote = getCurrentTool()
    if not tool or not remote then return end
    local target = getNearestTarget()
    if not target or not char:FindFirstChild("HumanoidRootPart") then return end
    local dir = (target.Position - char.HumanoidRootPart.Position).Unit
    for i = 1, 5 do if selectedAttacks[i] then pcall(function() remote:FireServer(dir, i, true) end) end end
end

-- SEA LOGIC
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

-- ESP LOGIC
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
                Instance.new("UIStroke", nl).Thickness = 1.2
                
                local il = Instance.new("TextLabel", bb)
                il.Name = "InfoLabel"; il.Size = UDim2.new(1, 0, 0, 15); il.Position = UDim2.new(0, 0, 0, 28)
                il.BackgroundTransparency = 1; il.Font = Enum.Font.GothamMedium; il.TextSize = 10
                Instance.new("UIStroke", il).Thickness = 1
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
                    if hbFill then tween(hbFill, {Size = UDim2.new(hpPercent, 0, 1, 0), BackgroundColor3 = hpPercent > 0.5 and THEME.GREEN or THEME.RED}, 0.2) end
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

-- SERVER HOPPER
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
                        if jobId ~= game.JobId and not table.find(hoppedServers, jobId) and count > 0 and count < maxP - 1 then
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
            return allInternalServers[math.random(1, math.min(#allInternalServers, 15))]
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
                if s.id ~= game.JobId and not table.find(hoppedServers, s.id) and (s.playing or 0) > 0 and (s.playing or 0) < (s.maxPlayers or 12) - 1 then
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
            hopStatusLabel.Text = "✅ Nhảy vào server " .. target.playing .. " người..."
            hopStatusLabel.TextColor3 = THEME.GREEN
            task.wait(0.5) TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, player)
        else
            hopStatusLabel.Text = "❌ Không tìm thấy server mới nào!"
            hopStatusLabel.TextColor3 = THEME.RED
        end
    end)
end

-- ISLAND ESP
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
        if child:IsA("Model") then
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

-- TABS
local TabHitbox = createTab("j4f")
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
addSection(TabBlox, "Combat Tools")
local auraMeleeList = addCollapsible(TabBlox, "Aura Melee")
ui_controls.auraEnabled = addToggle(auraMeleeList, "Enabled", false, function(v) auraEnabled = v if v then auraConnection = RunService.Heartbeat:Connect(performHit) elseif auraConnection then auraConnection:Disconnect() auraConnection = nil end end)
ui_controls.auraRadius = addSlider(auraMeleeList, "Radius", 5, 1000, 20, 0, function(v) auraRadius = v end)
ui_controls.auraDelay = addSlider(auraMeleeList, "Delay", 0.01, 10, 0.01, 2, function(v) auraDelay = v end)

local auraFruitList = addCollapsible(TabBlox, "Aura Fruit")
ui_controls.fruitEnabled = addToggle(auraFruitList, "Enabled", false, function(v) isSpamming = v if v then spamConnection = RunService.Heartbeat:Connect(spamFruit) elseif spamConnection then spamConnection:Disconnect() spamConnection = nil end end)
ui_controls.fruitDelay = addSlider(auraFruitList, "Spam Delay", 0.01, 10, 0.01, 2, function(v) fruitDelay = v end)
addDropdown(auraFruitList, "Select Skill", {"Skill 1", "Skill 2", "Skill 3", "Skill 4", "Skill 5"}, "Skill 1", function(v) local s = tonumber(v:match("%d+")) for i = 1, 5 do selectedAttacks[i] = (i == s) end end)

local fastM1List = addCollapsible(TabBlox, "Fast M1")
ui_controls.fastM1Enabled = addToggle(fastM1List, "Enabled", false, function(v) fastM1Enabled = v applyFastM1() end)
ui_controls.fastMelee = addSlider(fastM1List, "M1 Melee/Gun", 1, 5, 1, 0, function(v) fastMeleeMultiplier = math.floor(v + 0.5) applyFastM1() end)
ui_controls.fastFruit = addSlider(fastM1List, "M1 Fruit", 1, 5, 1, 0, function(v) fastFruitMultiplier = math.floor(v + 0.5) applyFastM1() end)

local secretIslandList = addCollapsible(TabBlox, "Secret Island")
ui_controls.mirageEsp = addToggle(secretIslandList, "Mirage Island ESP", false, function(v) islandEspSettings.ESP_List["Mirage Island"] = v end)
ui_controls.kitsuneEsp = addToggle(secretIslandList, "Kitsune Island ESP", false, function(v) islandEspSettings.ESP_List["Kitsune Island"] = v end)
ui_controls.prehistoricEsp = addToggle(secretIslandList, "Prehistoric Island ESP", false, function(v) islandEspSettings.ESP_List["Prehistoric Island"] = v end)

addSection(secretIslandList, "Island Tween")
local function islandTween(islandName, enabled)
    islandTweenEnabled[islandName] = enabled
end

ui_controls.tweenMirage = addToggle(secretIslandList, "Tween Mirage Island", false, function(v) islandTween("Mirage Island", v) end)
ui_controls.tweenKitsune = addToggle(secretIslandList, "Tween Kitsune Island", false, function(v) islandTween("Kitsune Island", v) end)
ui_controls.tweenPrehistoric = addToggle(secretIslandList, "Tween Prehistoric Island", false, function(v) islandTween("Prehistoric Island", v) end)
ui_controls.tweenSpeed = addSlider(secretIslandList, "Tween Speed", 250, 450, 350, 0, function(v) islandTweenSpeed = v end)

addSection(secretIslandList, "Auto Chest Mirage")
ui_controls.autoChest = addToggle(secretIslandList, "Enabled Auto Chest", false, function(v) autoChestMirage = v end)
ui_controls.autoChestStyle = addDropdown(secretIslandList, "Chest Style", {"TP", "Tween"}, "Tween", function(v) autoChestStyle = v end)
ui_controls.autoChestType = addDropdown(secretIslandList, "Chest Type", {"All", "Fragment", "Mirage"}, "All", function(v) autoChestType = v end)

-- HEARTBEAT
local cache = { mirage = nil, chest = nil, lastScan = 0, boatTarget = nil, boatParts = {}, touchedChests = {}, lastLootTime = 0, dState = "", dTick = 0 }

RunService.Heartbeat:Connect(function(dt: number)
    local myChar = player.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

    -- AUTO DUNGEON
    if autoDungeonEnabled and myHRP then
        local dungeonTargetPos = nil
        
        local dungeonMap = workspace.Map:FindFirstChild("Dungeon")
        if dungeonMap then
            local names = {} for _,v in dungeonMap:GetChildren() do table.insert(names, v.Name) end
            local curState = table.concat(names, ",")
            if curState ~= cache.dState then cache.dState, cache.dTick = curState, tick() end
            
            if tick() - cache.dTick < 2 then
                for _, roomFolder in dungeonMap:GetChildren() do
                    local exitPortal = roomFolder:FindFirstChild("ExitTeleporter") or roomFolder:FindFirstChild("ExitTeleport")
                    local rootPart = exitPortal and exitPortal:FindFirstChild("Root")
                    if rootPart then pcall(function() firetouchinterest(myHRP, rootPart, 0) firetouchinterest(myHRP, rootPart, 1) end) end
                end
            end
        end

        local baseHeight = 13 
        if myHRP.Size.Y > 2 then
            baseHeight = baseHeight + (myHRP.Size.Y * 1.5)
        elseif hitboxEnabled.self then
            baseHeight = baseHeight + (hitboxSize.self * 0.8)
        end

        local enemiesFolder = workspace:FindFirstChild("Enemies")
        local enemies = enemiesFolder and enemiesFolder:GetChildren() or {}
        local nearestDist = math.huge
        
        for _, e in enemies do
            local eHRP = e:FindFirstChild("HumanoidRootPart")
            if eHRP then
                local name = e.Name:lower()
                local isAlly = name:find("shadow") or name:find("blank") or name:find("buddy")
                if not isAlly then
                    local eHum = e:FindFirstChildOfClass("Humanoid")
                    if eHum and eHum.Health > 0 then
                        local d = (myHRP.Position - eHRP.Position).Magnitude
                        if d < nearestDist then
                            nearestDist = d
                            dungeonTargetPos = eHRP.Position + Vector3.new(0, baseHeight, 0)
                        end
                    end
                end
            end
        end
        if dungeonTargetPos then
            for _, v in char:GetDescendants() do if v:IsA("BasePart") then v.CanCollide = false end end
            myHRP.Velocity = Vector3.new(0,0,0)
            local dist = (myHRP.Position - dungeonTargetPos).Magnitude
            if dist > 0.1 then
                local spd = (dist < 5) and 150 or 350
                local alpha = math.min((spd * dt) / dist, 1)
                local lookAt = Vector3.new(dungeonTargetPos.X, myHRP.Position.Y, dungeonTargetPos.Z)
                if (lookAt - myHRP.Position).Magnitude < 0.5 then lookAt = myHRP.Position + myHRP.CFrame.LookVector end
                local targetCF = CFrame.new(myHRP.Position, lookAt) * CFrame.new(0, 0, -dist) * CFrame.new(0, dungeonTargetPos.Y - myHRP.Position.Y, 0)
                myHRP.CFrame = myHRP.CFrame:Lerp(targetCF, alpha)
            end
        else myHRP.Velocity = Vector3.zero end
    end

    -- Hitbox & Combat
    for t, e in hitboxEnabled do if e then expandHitbox(t) end end
    if fastM1Enabled then applyFastM1() end
    
    -- ESP & Chest Scanning (adaptive)
    if tick() - cache.lastScan > scanInterval then
        updateIslandESP()
        if autoChestMirage then
            cache.mirage = findIsland("Mirage Island")
            if cache.mirage then
                local chestFolder = workspace:FindFirstChild("ChestModels")
                cache.chest = nil
                if chestFolder then
                    for _, chest in chestFolder:GetChildren() do
                        if not cache.touchedChests[chest] then
                            local name = chest.Name:lower()
                            local isMatch = (autoChestType == "All") or (autoChestType == "Fragment" and name:find("fragment")) or (autoChestType == "Mirage" and name:find("mirage"))
                            if isMatch then
                                local p = chest:FindFirstChildWhichIsA("BasePart") or chest.PrimaryPart
                                if p then cache.chest = p; break end
                            end
                        end
                    end
                    if #chestFolder:GetChildren() == 0 then cache.touchedChests = {} end
                end
            end
        end
        cache.lastScan = tick()
    end

    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp, hum = char.HumanoidRootPart, char:FindFirstChildOfClass("Humanoid")
    
    -- TP Speed
    if tpEnabled and hum and hum.MoveDirection.Magnitude > 0 then
        local extraSpeed = (tpSpeed - 1) * hum.WalkSpeed
        if extraSpeed > 0 then hrp.CFrame = hrp.CFrame + (hum.MoveDirection * extraSpeed * dt) end
    end
    
    if waterWalkEnabled then
        if antiWaterEnabled and hrp.Position.Y < antiWaterThreshold then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
            hrp.CFrame = CFrame.new(hrp.Position.X, 1, hrp.Position.Z)
        end
        pcall(function() if workspace._WorldOrigin["Foam;"].CanCollide == false then workspace._WorldOrigin["Foam;"].CanCollide = true end end)
    else
        pcall(function() if workspace._WorldOrigin["Foam;"].CanCollide == true then workspace._WorldOrigin["Foam;"].CanCollide = false end end)
    end
    
    if infinityJumpEnabled then char:SetAttribute("SkyjumpBoost", 3000) end
    if dashLengthValue > 0 then char:SetAttribute("DashLength", dashLengthValue) end
    if hum then 
        if jumpHeightEnabled then hum.UseJumpPower, hum.JumpHeight = false, jumpHeightValue
        else hum.UseJumpPower = true end
    end

    -- Island Tween
    for name, enabled in islandTweenEnabled do
        if enabled then
            local obj = findIsland(name)
            if obj then
                local posPart = obj:FindFirstChild("MainPart") or obj:FindFirstChildOfClass("BasePart") or obj.PrimaryPart
                if posPart then
                    for _, v in char:GetDescendants() do if v:IsA("BasePart") then v.CanCollide = false end end
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
        for _, v in char:GetDescendants() do if v:IsA("BasePart") then v.CanCollide = false end end
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
                    if distToChest < 5 then
                        cache.touchedChests[cache.chest.Parent] = true
                        cache.chest = nil
                        cache.lastLootTime = tick()
                    end
                end
            else
                local horizontalDist = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(targetPos.X, targetPos.Z)).Magnitude
                local finalTarget = (horizontalDist > 50) and Vector3.new(targetPos.X, 250, targetPos.Z) or targetPos
                local totalDist = (hrp.Position - finalTarget).Magnitude
                
                if horizontalDist <= 50 and totalDist < 5 then
                    cache.touchedChests[cache.chest.Parent] = true
                    cache.chest = nil
                elseif totalDist > 5 then
                    local alpha = math.min((islandTweenSpeed * dt) / totalDist, 1)
                    hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, finalTarget) * CFrame.new(0, 0, -totalDist), alpha)
                end
            end
        else
            local targetPos = miragePos + Vector3.new(0, 250, 0)
            local dist = (hrp.Position - targetPos).Magnitude
            if dist > 5 then
                local alpha = math.min((islandTweenSpeed * dt) / dist, 1)
                hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, targetPos) * CFrame.new(0, 0, -dist), alpha)
            end
        end
    end

    if flyBoatEnabled and currentBoat and currentBoat.Parent then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local seat = currentBoat:FindFirstChildOfClass("VehicleSeat") or currentBoat:FindFirstChild("VehicleSeat", true)
            isPlayerOnBoat = (seat and seat.Occupant ~= nil)
            if isPlayerOnBoat then
                if not cache.boatTarget then cache.boatTarget = hrp.Position end
                if #cache.boatParts == 0 then
                    for _, v in currentBoat:GetDescendants() do if v:IsA("BasePart") then table.insert(cache.boatParts, v) end end
                end
                
                local cam, moveDir = workspace.CurrentCamera, Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                if moveDir.Magnitude > 0 then cache.boatTarget = cache.boatTarget + (moveDir.Unit * flyBoatSpeed * dt) end
                
                for _, v in cache.boatParts do 
                    v.Anchored, v.Velocity, v.RotVelocity = false, Vector3.zero, Vector3.zero 
                end

                if flyBoatStyle == "Custom" then hrp.CFrame = CFrame.lookAt(cache.boatTarget, cache.boatTarget + cam.CFrame.LookVector)
                else
                    cache.boatTarget = Vector3.new(cache.boatTarget.X, flyBoatHeight, cache.boatTarget.Z)
                    hrp.CFrame = CFrame.new(cache.boatTarget) * CFrame.lookAt(Vector3.zero, Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)).Rotation
                end
            else
                cache.boatTarget = (currentBoat.PrimaryPart or currentBoat:FindFirstChildWhichIsA("BasePart")).Position
                for _, v in ipairs(cache.boatParts) do if not v.Anchored then v.Anchored = true end end
            end
        end
    elseif not flyBoatEnabled and currentBoat then
        if currentBoat.Parent then for _, v in ipairs(cache.boatParts) do v.Anchored = false end end
        currentBoat, isPlayerOnBoat, cache.boatTarget, cache.boatParts = nil, false, nil, {}
    end
end)

local lpList = addCollapsible(TabBlox, "LocalPlayer")
ui_controls.autoActiveV4 = addToggle(lpList, "Auto Active V4", false, function(v) autoActiveV4Enabled = v end)
ui_controls.autoRaceV3 = addToggle(lpList, "Auto Race V3", false, function(v) autoRaceV3Enabled = v end)
addToggle(lpList, "Infinity Sky Jump", false, function(v) infinityJumpEnabled = v if not v and char then char:SetAttribute("SkyjumpBoost", nil) end end)
addToggle(lpList, "Jump Height Enabled", false, function(v) jumpHeightEnabled = v end)
addSlider(lpList, "Jump Height", 7.2, 1000, 7.2, 1, function(v) jumpHeightValue = v end)
addSlider(lpList, "Dash Length", 0, 500, 0, 1, function(v) dashLengthValue = v end)
ui_controls.waterWalk = addToggle(lpList, "Water Walk", true, function(v) waterWalkEnabled = v end)
ui_controls.antiWater = addToggle(lpList, "Anti Water", true, function(v) antiWaterEnabled = v end)

local fruitSection = addCollapsible(TabBlox, "Fruit")
local function storeAllFruits()
    if not char then return end
    local items = {}
    for _, v in player.Backpack:GetChildren() do table.insert(items, v) end
    for _, v in char:GetChildren() do table.insert(items, v) end
    
    for _, item in items do
        if item:IsA("Tool") and item.Name:lower():find("fruit") then
            -- Loại bỏ chữ " Fruit" và các khoảng trắng dư thừa
            local baseName = item.Name:gsub(" Fruit", ""):gsub(" ", "")
            local formattedName = baseName .. "-" .. baseName
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", formattedName, item) end)
        end
    end
end
ui_controls.autoStoreFruit = addToggle(fruitSection, "Auto Store Fruit", false, function(v) autoStoreFruitEnabled = v end)
addButton(fruitSection, "Store All Fruits (1 Click)", THEME.ACCENT, function() storeAllFruits() end)
ui_controls.autoRandomFruit = addToggle(fruitSection, "Auto Random Fruit", false, function(v) autoRandomFruitEnabled = v end)
addButton(fruitSection, "Random Fruit (1 Click)", THEME.ACCENT, function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy", "DLCBoxData") end) end)

local seaEventList = addCollapsible(TabBlox, "Sea Event")
local boatStatusF = Instance.new("Frame", seaEventList)
boatStatusF.Size = UDim2.new(1, 0, 0, 25) boatStatusF.BackgroundTransparency = 1
boatStatusLabel = Instance.new("TextLabel", boatStatusF)
boatStatusLabel.Size = UDim2.new(1, 0, 1, 0) boatStatusLabel.BackgroundTransparency = 1
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
                        if flyBoatEnabled then cache.boatTarget = hrp.Position end
                    end
                    break
                end
            end
        end
    end)
end)
ui_controls.flyboat = addToggle(seaEventList, "flyboat", false, function(v)
    flyBoatEnabled = v
    if v then
        local boats = workspace:FindFirstChild("Boats")
        if not boats or not char or not char:FindFirstChild("HumanoidRootPart") then flyBoatEnabled = false if ui_controls.flyboat then ui_controls.flyboat.Set(false) end return end
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
        else flyBoatEnabled = false if ui_controls.flyboat then ui_controls.flyboat.Set(false) end end
    else currentBoat, cache.boatTarget = nil, nil end
end)
ui_controls.flyboatSpeed = addSlider(seaEventList, "speed flyboat", 100, 1000, 200, 0, function(v) flyBoatSpeed = v end)
ui_controls.flyboatHeight = addSlider(seaEventList, "boat height", 20, 600, 125, 0, function(v) flyBoatHeight = v end)
ui_controls.flyboatStyle = addDropdown(seaEventList, "Fly Style", {"Default", "Custom"}, "Default", function(v) flyBoatStyle = v end)
addButton(seaEventList, "Remove Rocks", THEME.ACCENT, function()
    for _, v in workspace:GetDescendants() do
        if v.Name == "Rocks" then
            pcall(function() v:ClearAllChildren() end)
        end
    end
end)

local shopList = addCollapsible(TabBlox, "Shop")
ui_controls.autoTradeBones = addToggle(shopList, "Auto Trade Bones", false, function(v) autoTradeBonesEnabled = v end)
addButton(shopList, "Reset Stat (Buy)", THEME.ACCENT, function()
    pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("BlackbeardReward", "Refund", "2") end)
end)

-- UTILS TAB
addSection(TabUtils, "Movement")
local tpWalkList = addCollapsible(TabUtils, "TP Walk")
ui_controls.tpEnabled = addToggle(tpWalkList, "Enabled", false, function(v) tpEnabled = v end)
ui_controls.tpSpeed = addSlider(tpWalkList, "Speed Mult", 1, 8, 2, 1, function(v) tpSpeed = v end)

addSection(TabUtils, "Visuals")
local espList = addCollapsible(TabUtils, "Player ESP")
ui_controls.espEnabled = addToggle(espList, "Enabled", false, function(v) espSettings.Enabled = v if v then espConnection = RunService.Heartbeat:Connect(updateESP) else if espConnection then espConnection:Disconnect() espConnection = nil end clearESP() end end)
ui_controls.espText = addToggle(espList, "Show HP Text", true, function(v) espSettings.ShowText = v end)
ui_controls.espBar = addToggle(espList, "Show HP Bar", true, function(v) espSettings.ShowBar = v end)

addButton(TabUtils, "Remove Fog & Effects", THEME.ACCENT, function()
    for _, v in Lighting:GetChildren() do
        if v:IsA("Atmosphere") or v.Name:find("Fog") then
            pcall(function() v:Destroy() end)
        end
    end
    Lighting.FogEnd = 9e9
    Lighting.FogStart = 0
    Lighting.GlobalShadows = false
    Lighting.ExposureCompensation = 1
end)

addSection(TabUtils, "Others")
addButton(TabUtils, "Infinite Yield", THEME.ACCENT, function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)

addSection(TabUtils, "Server Hopper")
local hopFrame = Instance.new("Frame", TabUtils)
hopFrame.Size = UDim2.new(1, 0, 0, 30) hopFrame.BackgroundTransparency = 1
hopStatusLabel = Instance.new("TextLabel", hopFrame)
hopStatusLabel.Size = UDim2.new(1, 0, 1, 0) hopStatusLabel.BackgroundTransparency = 1
hopStatusLabel.Text = "Bấm để săn server vắng nhất" hopStatusLabel.TextColor3 = THEME.TEXT_DIM hopStatusLabel.Font = Enum.Font.Gotham hopStatusLabel.TextSize = 12
addButton(TabUtils, "Small Server Hop", THEME.ACCENT, function() executeHop() end)
addButton(TabUtils, "Old Server (4H+)", THEME.DARK_ITEM, function() hopToOldServer("4h") end)
addButton(TabUtils, "Old Server (3H45+)", THEME.DARK_ITEM, function() hopToOldServer("3h45") end)

-- SETTINGS TAB


-- Logic Task Start
local customIconList = addCollapsible(TabSettings, "Custom Button Icon")

local helpLabel = Instance.new("TextLabel", customIconList)
helpLabel.Size = UDim2.new(1, 0, 0, 80)
helpLabel.BackgroundTransparency = 1
helpLabel.Text = "📖 Hướng dẫn lấy ID:\n1. Mở Roblox Website > Create > Dashboard\n2. Chọn Development Items > Decals\n3. Copy dãy số (ID) của ảnh bạn muốn dán vào đây."
helpLabel.TextColor3 = THEME.TEXT_DIM helpLabel.Font = Enum.Font.Gotham helpLabel.TextSize = 11
helpLabel.TextWrapped = true

-- Xóa hàm getDungeonTeleporter cũ vì đã dùng logic FireTouch toàn bộ

local dungeonSection = addCollapsible(TabBlox, "Dungeon")
ui_controls.autoDungeon = addToggle(dungeonSection, "Auto Dungeon", false, function(v) autoDungeonEnabled = v end)

addInput(customIconList, "Icon Button ID", "84053545044369", "Dán ID số vào đây...", function(v)
    local idOnly = v:match("%d+")
    if idOnly then
        ToggleBtn.Image = "rbxthumb://type=Asset&id=" .. idOnly .. "&w=420&h=420"
    end
end)

task.spawn(function() while task.wait(0.5) do updateBoatSpeeds() end end)
task.spawn(function() while task.wait(1) do if autoRaceV3Enabled then pcall(function() ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility") end) end end end)
task.spawn(function() while task.wait(10) do if autoRandomFruitEnabled then pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy", "DLCBoxData") end) end end end)
task.spawn(function()
    while true do
        task.wait(0.5) -- 0.5s là đủ nhanh và an toàn
        if autoActiveV4Enabled then
            pcall(function()
                local character = player.Character
                if character then
                    local awakening = player.Backpack:FindFirstChild("Awakening") or character:FindFirstChild("Awakening")
                    if awakening then
                        local rf = awakening:FindFirstChild("RemoteFunction", true)
                        if rf then
                            -- Dùng task.spawn để tránh việc InvokeServer làm đứng loop
                            task.spawn(function()
                                pcall(function() rf:InvokeServer(true) end)
                            end)
                        end
                    end
                end
            end)
        end
    end
end)
task.spawn(function() while task.wait(2) do if autoTradeBonesEnabled then pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("Bones", "Buy", 1, 1) end) end end end)
task.spawn(function() while task.wait(1) do if autoStoreFruitEnabled then storeAllFruits() end end end)


-- INITIALIZE
if #tabBtns > 0 then
    for _, p in pages do p.Visible = false end
    for _, b in tabBtns do b.BackgroundTransparency = 1; b.TextColor3 = THEME.TEXT_DIM end
    pages[1].Visible = true
    tabBtns[1].BackgroundTransparency = 0
    tabBtns[1].TextColor3 = THEME.ACCENT
end
