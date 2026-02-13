-- GLOBALS.LUAU
-- Chứa toàn bộ Service và Biến hệ thống dùng chung
local Globals = {}

-- Services
Globals.Players = game:GetService("Players")
Globals.RunService = game:GetService("RunService")
Globals.UserInputService = game:GetService("UserInputService")
Globals.CoreGui = game:GetService("CoreGui")
Globals.ReplicatedStorage = game:GetService("ReplicatedStorage")
Globals.TweenService = game:GetService("TweenService")
Globals.HttpService = game:GetService("HttpService")
Globals.TeleportService = game:GetService("TeleportService")
Globals.Lighting = game:GetService("Lighting")
Globals.VirtualUser = game:GetService("VirtualUser")

-- Player Data
Globals.player = Globals.Players.LocalPlayer
Globals.char = Globals.player.Character or Globals.player.CharacterAdded:Wait()
Globals.player.CharacterAdded:Connect(function(c) Globals.char = c end)

-- UI States & Folders
Globals.ui_controls = {}
Globals.allStrokes = {}
Globals.allBtnStrokes = {}
Globals.guiVisible = true
Globals.THEME = {
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

-- Farm Configs
Globals.autoCakeFarmEnabled = false
Globals.autoCakeSpawnEnabled = false
Globals.autoCakeTargetObj = nil
Globals.cakeMobs = {"Cake Prince", "Baking Staff", "Cake Guard", "Cookie Crafter", "Head Baker"}
Globals.safeHeight = 15
Globals.characterParts = {}

return Globals
