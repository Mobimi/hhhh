-- UTILS.LUAU
-- Chứa các hàm hỗ trợ vẽ UI và logic di chuyển cơ bản
local Utils = {}
local baseUrl = "https://raw.githubusercontent.com/Mobimi/hhhh/refs/heads/main/j4f_mod/"
local Globals = loadstring(game:HttpGet(baseUrl .. "globals.luau"))()

function Utils.corner(p, r) 
    local c = Instance.new("UICorner", p) 
    c.CornerRadius = UDim.new(0, r or 8) 
    return c 
end

function Utils.stroke(p, c, t, b) 
    local s = Instance.new("UIStroke", p) 
    s.Color = c or (Globals.THEME.ACCENT) 
    s.Thickness = t or 1 
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border 
    return s 
end

function Utils.tween(o, p, d) 
    Globals.TweenService:Create(o, TweenInfo.new(d or 0.3, Enum.EasingStyle.Quart), p):Play() 
end

function Utils.makeDraggable(o)
    local drag, dInput, dStart, sPos
    o.InputBegan:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
            drag, dStart, sPos = true, i.Position, o.Position 
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end) 
        end 
    end)
    o.InputChanged:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then dInput = i end 
    end)
    Globals.UserInputService.InputChanged:Connect(function(i) 
        if i == dInput and drag then 
            local d = i.Position - dStart 
            o.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y) 
        end 
    end)
end

function Utils.updateCharParts()
    Globals.characterParts = {}
    if Globals.char then
        for _, v in ipairs(Globals.char:GetDescendants()) do
            if v:IsA("BasePart") then table.insert(Globals.characterParts, v) end
        end
    end
end

return Utils
