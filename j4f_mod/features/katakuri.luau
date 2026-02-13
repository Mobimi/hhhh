-- KATAKURI.LUAU
-- Chứa toàn bộ logic triệu hồi và farm Katakuri (Cake Prince)
local Katakuri = {}
local Globals = loadstring(readfile("j4f_mod/globals.luau"))()

function Katakuri.startSpawner()
    task.spawn(function()
        while true do
            task.wait(1)
            if Globals.autoCakeSpawnEnabled then
                pcall(function()
                    Globals.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("CakePrinceSpawner", true)
                    task.wait(0.1)
                    Globals.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("CakePrinceSpawner")
                end)
            end
        end
    end)
end

function Katakuri.getSelector()
    if Globals.autoCakeFarmEnabled and Globals.char and Globals.char:FindFirstChild("HumanoidRootPart") then
        pcall(function()
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
                local boss = findCakeMob("Cake Prince")
                if boss then 
                    Globals.autoCakeTargetObj = boss 
                else
                    Globals.autoCakeTargetObj = mirrorDimension.PrimaryPart or mirrorDimension:FindFirstChildWhichIsA("BasePart") or mirrorDimension
                end
            else
                -- Farm quái thường
                local found = nil
                local minD = math.huge
                if enemies then
                    for _, e in ipairs(enemies:GetChildren()) do
                        local match = false
                        for i = 2, #Globals.cakeMobs do if e.Name:find(Globals.cakeMobs[i]) then match = true break end end
                        if match then
                            local hum = e:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 and e:FindFirstChild("HumanoidRootPart") then
                                local d = (Globals.char.HumanoidRootPart.Position - e.HumanoidRootPart.Position).Magnitude
                                if d < minD then minD = d; found = e end
                            end
                        end
                    end
                end
                Globals.autoCakeTargetObj = found
            end
        end)
    else
        Globals.autoCakeTargetObj = nil
    end
end

return Katakuri
