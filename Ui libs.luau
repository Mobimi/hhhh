local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local Lib = {}

Lib.THEME = {
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

local function corner(p, r) 
    local c = Instance.new("UICorner", p) 
    c.CornerRadius = UDim.new(0, r or 8) 
    return c 
end

local function stroke(p, c, t, b) 
    local s = Instance.new("UIStroke", p) 
    s.Color = c or (Lib.THEME.ACCENT) 
    s.Thickness = t or 1 
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border 
    return s 
end

local function tween(o, p, d) 
    TweenService:Create(o, TweenInfo.new(d or 0.3, Enum.EasingStyle.Quart), p):Play() 
end

local function makeDraggable(o)
    local drag, dInput, dStart, sPos
    o.InputBegan:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
            drag, dStart, sPos = true, i.Position, o.Position 
            i.Changed:Connect(function() 
                if i.UserInputState == Enum.UserInputState.End then drag = false end 
            end) 
        end 
    end)
    o.InputChanged:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then 
            dInput = i 
        end 
    end)
    UserInputService.InputChanged:Connect(function(i) 
        if i == dInput and drag then 
            local d = i.Position - dStart 
            o.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y) 
        end 
    end)
end

function Lib:CreateWindow(title, author, iconId)
    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "HB_PRO_V" .. math.random(100, 999)
    ScreenGui.ResetOnSpawn = false
    
    local guiVisible = true
    
    local ToggleBtn = Instance.new("ImageButton", ScreenGui)
    ToggleBtn.Size = UDim2.new(0, 60, 0, 60)
    ToggleBtn.Position = UDim2.new(0.02, 0, 0.5, -30)
    ToggleBtn.BackgroundColor3 = Lib.THEME.BG_SIDE
    ToggleBtn.BackgroundTransparency = 0.2
    ToggleBtn.Image = "rbxthumb://type=Asset&id=" .. (iconId or "84053545044369") .. "&w=420&h=420"
    ToggleBtn.ScaleType = Enum.ScaleType.Fit
    ToggleBtn.ZIndex = 15
    corner(ToggleBtn, 12)
    stroke(ToggleBtn, Lib.THEME.ACCENT, 2, true)
    makeDraggable(ToggleBtn)
    
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 540, 0, 340)
    MainFrame.Position = UDim2.new(0.5, -270, 0.5, -170)
    MainFrame.BackgroundColor3 = Lib.THEME.BG_MAIN
    MainFrame.BackgroundTransparency = 0.3
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    corner(MainFrame, 12)
    stroke(MainFrame, Lib.THEME.ACCENT, 2, false)
    makeDraggable(MainFrame)
    
    ToggleBtn.MouseButton1Click:Connect(function() 
        guiVisible = not guiVisible 
        MainFrame.Visible = guiVisible 
        tween(ToggleBtn, {BackgroundTransparency = guiVisible and 0.3 or 0.2}, 0.2) 
    end)
    
    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.Size = UDim2.new(0, 110, 1, 0)
    Sidebar.BackgroundColor3 = Lib.THEME.BG_SIDE
    Sidebar.BackgroundTransparency = 0.4
    Sidebar.BorderSizePixel = 0
    corner(Sidebar, 12)
    
    local SidebarLabel = Instance.new("TextLabel", Sidebar)
    SidebarLabel.Size = UDim2.new(1, 0, 0, 35)
    SidebarLabel.Position = UDim2.new(0, 0, 0, 5)
    SidebarLabel.BackgroundTransparency = 1
    SidebarLabel.Text = title or "Script"
    SidebarLabel.TextColor3 = Lib.THEME.ACCENT
    SidebarLabel.Font = Enum.Font.GothamBold
    SidebarLabel.TextSize = 22
    
    local AuthorLabel = Instance.new("TextLabel", Sidebar)
    AuthorLabel.Size = UDim2.new(1, 0, 0, 20)
    AuthorLabel.Position = UDim2.new(0, 0, 0, 35)
    AuthorLabel.BackgroundTransparency = 1
    AuthorLabel.Text = "by " .. (author or "realayako")
    AuthorLabel.TextColor3 = Lib.THEME.TEXT_DIM
    AuthorLabel.Font = Enum.Font.GothamMedium
    AuthorLabel.TextSize = 10
    
    local TabContainer = Instance.new("Frame", Sidebar)
    TabContainer.Size = UDim2.new(1, 0, 1, -70)
    TabContainer.Position = UDim2.new(0, 0, 0, 70)
    TabContainer.BackgroundTransparency = 1
    local TabLayout = Instance.new("UIListLayout", TabContainer)
    TabLayout.Padding = UDim.new(0, 6)
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local ContentArea = Instance.new("Frame", MainFrame)
    ContentArea.Size = UDim2.new(1, -125, 1, -15)
    ContentArea.Position = UDim2.new(0, 120, 0, 10)
    ContentArea.BackgroundTransparency = 1
    
    local pages = {}
    local tabBtns = {}
    
    local Window = {}
    
    function Window:CreateTab(name)
        local b = Instance.new("TextButton", TabContainer)
        b.Size = UDim2.new(0.85, 0, 0, 36)
        b.BackgroundColor3 = Lib.THEME.DARK_ITEM
        b.BackgroundTransparency = 1
        b.Text = name
        b.TextColor3 = Lib.THEME.TEXT_DIM
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        corner(b, 8)
        stroke(b, Lib.THEME.DARK_ITEM, 1, true)
        
        local p = Instance.new("ScrollingFrame", ContentArea)
        p.Size = UDim2.new(1, 0, 1, 0)
        p.BackgroundTransparency = 1
        p.Visible = false
        p.ScrollBarThickness = 2
        p.ScrollBarImageColor3 = Lib.THEME.ACCENT
        p.AutomaticCanvasSize = Enum.AutomaticSize.Y
        
        local l = Instance.new("UIListLayout", p)
        l.Padding = UDim.new(0, 8)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        
        b.MouseButton1Click:Connect(function() 
            for _, x in ipairs(pages) do x.Visible = false end 
            for _, x in ipairs(tabBtns) do tween(x, {BackgroundTransparency = 1, TextColor3 = Lib.THEME.TEXT_DIM}, 0.2) end 
            p.Visible = true
            b.BackgroundTransparency = 0
            b.TextColor3 = Lib.THEME.ACCENT 
        end)
        
        table.insert(pages, p)
        table.insert(tabBtns, b)
        
        local Tab = {}
        
        function Tab:AddSection(title)
            local f = Instance.new("Frame", p)
            f.Size = UDim2.new(1, 0, 0, 26)
            f.BackgroundTransparency = 1
            local label = Instance.new("TextLabel", f)
            label.Size = UDim2.new(1, 0, 1, -4)
            label.Position = UDim2.new(0, 4, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = title:upper()
            label.TextColor3 = Lib.THEME.ACCENT
            label.Font = Enum.Font.GothamBold
            label.TextSize = 10
            label.TextXAlignment = 0
            local line = Instance.new("Frame", f)
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, 1, -2)
            line.BackgroundColor3 = Lib.THEME.ACCENT
            line.BackgroundTransparency = 0.5
            line.BorderSizePixel = 0
            return f
        end
        
        function Tab:AddToggle(t, d, c)
            local f = Instance.new("Frame", p)
            f.Size = UDim2.new(1, 0, 0, 30)
            f.BackgroundColor3 = Lib.THEME.BG_CONTENT
            f.BackgroundTransparency = 0.4
            corner(f, 6)
            stroke(f, Lib.THEME.ACCENT)
            
            local l = Instance.new("TextLabel", f)
            l.Size = UDim2.new(1, -50, 1, 0)
            l.Position = UDim2.new(0, 10, 0, 0)
            l.BackgroundTransparency = 1
            l.Text = t
            l.TextColor3 = Lib.THEME.TEXT
            l.Font = Enum.Font.Gotham
            l.TextSize = 11
            l.TextXAlignment = 0
            
            local btn = Instance.new("TextButton", f)
            btn.Size = UDim2.new(0, 30, 0, 16)
            btn.Position = UDim2.new(1, -40, 0.5, -8)
            btn.BackgroundColor3 = d and Lib.THEME.ACCENT or Color3.fromRGB(200, 200, 200)
            btn.Text = ""
            corner(btn, 8)
            stroke(btn, Lib.THEME.ACCENT)
            
            local o = Instance.new("Frame", btn)
            o.Size = UDim2.new(0, 12, 0, 12)
            o.Position = UDim2.new(d and 1 or 0, d and -14 or 2, 0.5, -6)
            o.BackgroundColor3 = Color3.new(1, 1, 1)
            corner(o, 6)
            
            local en = d
            btn.MouseButton1Click:Connect(function() 
                en = not en 
                tween(btn, {BackgroundColor3 = en and Lib.THEME.ACCENT or Color3.fromRGB(200, 200, 200)}, 0.2) 
                tween(o, {Position = UDim2.new(en and 1 or 0, en and -14 or 2, 0.5, -6)}, 0.2) 
                c(en) 
            end)
            
            return {
                Set = function(v) 
                    en = v 
                    btn.BackgroundColor3 = en and Lib.THEME.ACCENT or Color3.fromRGB(200, 200, 200) 
                    o.Position = UDim2.new(en and 1 or 0, en and -14 or 2, 0.5, -6) 
                end
            }
        end
        
        function Tab:AddSlider(t, min, max, d, dec, c)
            local f = Instance.new("Frame", p)
            f.Size = UDim2.new(1, 0, 0, 42)
            f.BackgroundColor3 = Lib.THEME.BG_CONTENT
            f.BackgroundTransparency = 0.4
            corner(f, 6)
            stroke(f, Lib.THEME.ACCENT)
            
            local l = Instance.new("TextLabel", f)
            l.Size = UDim2.new(1, -20, 0, 20)
            l.Position = UDim2.new(0, 10, 0, 4)
            l.BackgroundTransparency = 1
            l.Text = t .. ": " .. d
            l.TextColor3 = Lib.THEME.TEXT
            l.Font = Enum.Font.Gotham
            l.TextSize = 11
            l.TextXAlignment = 0
            
            local bg = Instance.new("Frame", f)
            bg.Size = UDim2.new(1, -20, 0, 3)
            bg.Position = UDim2.new(0, 10, 0, 30)
            bg.BackgroundColor3 = Color3.new(0, 0, 0)
            corner(bg, 2)
            
            local fill = Instance.new("Frame", bg)
            fill.Size = UDim2.new((d - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = Lib.THEME.ACCENT
            corner(fill, 2)
            
            local b = Instance.new("Frame", bg)
            b.Size = UDim2.new(0, 10, 0, 10)
            b.Position = UDim2.new((d - min) / (max - min), -5, 0.5, -5)
            b.BackgroundColor3 = Lib.THEME.ACCENT
            corner(b, 5)
            
            local tr = Instance.new("TextButton", f)
            tr.Size = UDim2.new(1, 0, 1, 0)
            tr.BackgroundTransparency = 1
            tr.Text = ""
            
            local prec, drag = 10 ^ (dec or 0), false
            local function fV(v) 
                return (dec or 0) <= 0 and tostring(math.round(v)) or tostring(math.floor(v * prec + 0.5) / prec) 
            end
            
            local function up(i) 
                local rel = math.clamp((i.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1) 
                local v = math.floor((min + (max - min) * rel) * prec + 0.5) / prec 
                l.Text, fill.Size, b.Position = t .. ": " .. fV(v), UDim2.new(rel, 0, 1, 0), UDim2.new(rel, -5, 0.5, -5) 
                c(v) 
            end
            
            tr.InputBegan:Connect(function(i) 
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
                    drag = true 
                    up(i) 
                end 
            end)
            UserInputService.InputEnded:Connect(function(i) 
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
                    drag = false 
                end 
            end)
            UserInputService.InputChanged:Connect(function(i) 
                if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then 
                    up(i) 
                end 
            end)
            
            return {
                Set = function(v) 
                    local rel = math.clamp((v - min) / (max - min), 0, 1) 
                    l.Text, fill.Size, b.Position = t .. ": " .. fV(v), UDim2.new(rel, 0, 1, 0), UDim2.new(rel, -5, 0.5, -5) 
                end
            }
        end
        
        function Tab:AddInput(t, d, ph, c)
            local f = Instance.new("Frame", p)
            f.Size = UDim2.new(1, 0, 0, 55)
            f.BackgroundColor3 = Lib.THEME.BG_CONTENT
            corner(f, 6)
            local label = Instance.new("TextLabel", f)
            label.Size = UDim2.new(1, -20, 0, 25)
            label.Position = UDim2.new(0, 12, 0, 5)
            label.BackgroundTransparency = 1
            label.Text = t
            label.TextColor3 = Lib.THEME.TEXT
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextXAlignment = 0
            local i = Instance.new("TextBox", f)
            i.Size = UDim2.new(1, -24, 0, 24)
            i.Position = UDim2.new(0, 12, 0, 26)
            i.BackgroundColor3 = Lib.THEME.BG_MAIN
            i.Text = d
            i.PlaceholderText = ph
            i.TextColor3 = Lib.THEME.TEXT
            i.Font = Enum.Font.Gotham
            i.TextSize = 12
            i.ClearTextOnFocus = false
            corner(i, 4)
            i.FocusLost:Connect(function() c(i.Text) end)
            return i
        end
        
        function Tab:AddButton(t, cl, c)
            local b = Instance.new("TextButton", p)
            b.Size = UDim2.new(1, 0, 0, 30)
            b.BackgroundColor3 = cl or Lib.THEME.DARK_ITEM
            b.Text = t
            b.TextColor3 = Lib.THEME.TEXT
            b.Font = Enum.Font.GothamBold
            b.TextSize = 11
            corner(b, 6)
            b.MouseButton1Click:Connect(function() 
                tween(b, {BackgroundTransparency = 0.5}, 0.1) 
                task.wait(0.1) 
                tween(b, {BackgroundTransparency = 0}, 0.1) 
                c() 
            end)
            return b
        end
        
        function Tab:AddDropdown(t, items, d, c)
            local f = Instance.new("Frame", p)
            f.Size = UDim2.new(1, 0, 0, 32)
            f.BackgroundColor3 = Lib.THEME.BG_CONTENT
            f.BackgroundTransparency = 0.4
            f.ClipsDescendants = true
            corner(f, 6)
            stroke(f, Lib.THEME.ACCENT)
            
            local l = Instance.new("TextButton", f)
            l.Size = UDim2.new(1, 0, 0, 32)
            l.BackgroundTransparency = 1
            l.Text = "  " .. t .. ": " .. d
            l.TextColor3 = Lib.THEME.TEXT
            l.Font = Enum.Font.Gotham
            l.TextSize = 11
            l.TextXAlignment = 0
            
            local list = Instance.new("Frame", f)
            list.Size = UDim2.new(1, 0, 0, #items * 26)
            list.Position = UDim2.new(0, 0, 0, 32)
            list.BackgroundTransparency = 1
            Instance.new("UIListLayout", list)
            
            for _, v in ipairs(items) do
                local ib = Instance.new("TextButton", list)
                ib.Size = UDim2.new(1, 0, 0, 26)
                ib.BackgroundColor3 = Lib.THEME.DARK_ITEM
                ib.BackgroundTransparency = 0.5
                ib.BorderSizePixel = 0
                ib.Text = "    " .. tostring(v)
                ib.TextColor3 = Lib.THEME.TEXT_DIM
                ib.Font = Enum.Font.Gotham
                ib.TextSize = 10
                ib.TextXAlignment = 0
                ib.MouseButton1Click:Connect(function() 
                    l.Text = "  " .. t .. ": " .. tostring(v) 
                    tween(f, {Size = UDim2.new(1, 0, 0, 32)}, 0.2) 
                    c(v) 
                end)
            end
            
            local op = false
            l.MouseButton1Click:Connect(function() 
                op = not op 
                tween(f, {Size = UDim2.new(1, 0, 0, op and (32 + #items * 26) or 32)}, 0.2) 
            end)
            
            return {
                Set = function(v) l.Text = "  " .. t .. ": " .. tostring(v) end
            }
        end
        
        function Tab:AddCollapsible(ti)
            local c = Instance.new("Frame", p)
            c.Size = UDim2.new(1, 0, 0, 30)
            c.BackgroundColor3 = Lib.THEME.BG_CONTENT
            c.BackgroundTransparency = 0.4
            c.ClipsDescendants = true
            c.BorderSizePixel = 0
            corner(c, 6)
            stroke(c, Lib.THEME.ACCENT)
            
            local btn = Instance.new("TextButton", c)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundTransparency = 1
            btn.Text = "  " .. ti .. " ▼"
            btn.TextColor3 = Lib.THEME.TEXT
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 10
            btn.TextXAlignment = 0
            
            local con = Instance.new("Frame", c)
            con.Position = UDim2.new(0, 0, 0, 30)
            con.Size = UDim2.new(1, 0, 0, 0)
            con.BackgroundTransparency = 1
            local ly = Instance.new("UIListLayout", con)
            ly.Padding = UDim.new(0, 4)
            
            local op = false
            btn.MouseButton1Click:Connect(function() 
                op = not op 
                local h = op and (30 + ly.AbsoluteContentSize.Y + 8) or 30 
                tween(c, {Size = UDim2.new(1, 0, 0, h)}, 0.3) 
                btn.Text, btn.TextColor3 = "  " .. ti .. (op and " ▲" or " ▼"), op and Lib.THEME.ACCENT or Lib.THEME.TEXT 
            end)
            
            ly:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
                if op then c.Size = UDim2.new(1, 0, 0, 30 + ly.AbsoluteContentSize.Y + 8) end 
            end)
            
            return con
        end
        
        return Tab
    end
    
    function Window:SelectTab(num)
        if #tabBtns >= num then
            for _, x in ipairs(pages) do x.Visible = false end
            for _, x in ipairs(tabBtns) do x.BackgroundTransparency = 1; x.TextColor3 = Lib.THEME.TEXT_DIM end
            pages[num].Visible = true
            tabBtns[num].BackgroundTransparency = 0
            tabBtns[num].TextColor3 = Lib.THEME.ACCENT
        end
    end
    
    function Lib:SetIconButton(id)
        ToggleBtn.Image = "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
    end

    return Window
end

return Lib
