-- INIT.LUAU
-- Loader trung tâm của j4f Modular System
print("🚩 J4F MODULAR STARTING... 🚩")

local baseUrl = "https://raw.githubusercontent.com/Mobimi/hhhh/refs/heads/main/j4f_mod/"

local Globals = loadstring(game:HttpGet(baseUrl .. "globals.luau"))()
local Utils = loadstring(game:HttpGet(baseUrl .. "utils.luau"))()
local Katakuri = loadstring(game:HttpGet(baseUrl .. "features/katakuri.luau"))()

-- Khởi động các vòng lặp đặc trưng
Katakuri.startSpawner()

-- Heartbeat chính để xử lý di chuyển
Globals.RunService.Heartbeat:Connect(function(dt)
    if not Globals.char or not Globals.char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = Globals.char.HumanoidRootPart
    
    -- Xử lý Katakuri Move
    if Globals.autoCakeFarmEnabled and Globals.autoCakeTargetObj then
        local target = Globals.autoCakeTargetObj
        local tPart = target:IsA("Model") and (target.PrimaryPart or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")) or target
        
        if tPart then
            for _, v in ipairs(Globals.characterParts) do v.CanCollide = false end
            hrp.Velocity = Vector3.new(0,0,0)
            local targetPos = tPart.Position + Vector3.new(0, Globals.safeHeight, 0)
            local dist = (hrp.Position - targetPos).Magnitude
            if dist > 0.5 then
                local speed = (dist < 140) and 1300 or 360
                hrp.CFrame = hrp.CFrame + (targetPos - hrp.Position).Unit * math.min(speed * dt, dist)
            end
        end
    end
end)

-- Scheduler 0.1s
task.spawn(function()
    while true do
        local dt = task.wait(0.1)
        Katakuri.getSelector()
        Utils.updateCharParts()
    end
end)

print("✅ J4F MODULAR LOADED SUCCESSFULLY! ✅")
