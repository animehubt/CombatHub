--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--// FULL CONFIGURATION
local Config = {
    Enabled = true,
    HardLock = true,
    WallCheck = true,
    RotateSpeed = 25,
    Smoothness = 0.2, -- Lower is smoother
    FOV = 150,
    Theme = Color3.fromRGB(140, 60, 255),
    MenuKey = Enum.KeyCode.K,
    LockKey = Enum.KeyCode.C
}

--// VARIABLES
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local targetObj = nil
local targetPos = nil
local menuOpen = false

--// ================= PREMIUM GUI =================
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "AirHub_Ultimate_Full"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 450, 0, 350)
main.Position = UDim2.new(0.5, -225, 0.4, -175)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
main.BorderSizePixel = 0
main.Visible = false

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Config.Theme
stroke.Thickness = 2

-- Header Section
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Instance.new("UICorner", header)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.Text = "AIRHUB PREMIUM | V3.2"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.BackgroundTransparency = 1

-- Content Area (Scrolling)
local content = Instance.new("ScrollingFrame", main)
content.Size = UDim2.new(1, -20, 1, -70)
content.Position = UDim2.new(0, 10, 0, 60)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 2
content.ScrollBarImageColor3 = Config.Theme

local layout = Instance.new("UIListLayout", content)
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

--// UI COMPONENTS
local function createToggle(text, default, callback)
    local btn = Instance.new("TextButton", content)
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Text = "  " .. text .. ": " .. (default and "ON" or "OFF")
    btn.Font = Enum.Font.GothamSemibold
    btn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn)
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = "  " .. text .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Config.Theme or Color3.fromRGB(30, 30, 40)
        callback(state)
    end)
end

--// COMBAT ENGINE
local function getClosest()
    local target, nearest = nil, Config.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pos, vis = camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if vis then
                local dist = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                if dist < nearest then
                    nearest = dist
                    target = p.Character
                end
            end
        end
    end
    return target
end

--// MAIN LOOP
RunService.RenderStepped:Connect(function(dt)
    if Config.Enabled and targetPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local root = player.Character.HumanoidRootPart
        
        -- Update position if target is still in-game
        if targetObj and targetObj:FindFirstChild("HumanoidRootPart") then
            targetPos = targetObj.HumanoidRootPart.Position
        end
        
        -- The "Hard Lock" Rotation Logic
        local lookCF = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
        root.CFrame = root.CFrame:Lerp(lookCF, Config.Smoothness)
        
        if player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.AutoRotate = false
        end
    elseif player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.AutoRotate = true
    end
end)

--// INPUT HANDLING
UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Config.MenuKey then
        menuOpen = not menuOpen
        main.Visible = menuOpen
        -- Simple Slide Animation
        if menuOpen then
            main.Position = UDim2.new(0.5, -225, 0.35, -175)
            TweenService:Create(main, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -225, 0.4, -175)}):Play()
        end
    end
    
    if i.KeyCode == Config.LockKey and Config.Enabled then
        if targetPos then
            targetPos, targetObj = nil, nil
        else
            targetObj = getClosest()
            if targetObj then targetPos = targetObj.HumanoidRootPart.Position end
        end
    end
end)

--// INITIALIZE CONTENT
createToggle("Aimbot Enabled", true, function(v) Config.Enabled = v end)
createToggle("Hard Lock (Stay on Death)", true, function(v) Config.HardLock = v end)
createToggle("Wall Check", true, function(v) Config.WallCheck = v end)

local nameBox = Instance.new("TextBox", content)
nameBox.Size = UDim2.new(1, -10, 0, 40)
nameBox.PlaceholderText = "Target Username..."
nameBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
nameBox.TextColor3 = Color3.new(1,1,1)
nameBox.Font = Enum.Font.Gotham
Instance.new("UICorner", nameBox)

nameBox.FocusLost:Connect(function()
    for _, v in pairs(Players:GetPlayers()) do
        if v.Name:lower():find(nameBox.Text:lower()) then
            targetObj = v.Character
            targetPos = v.Character.HumanoidRootPart.Position
        end
    end
end)

local credits = Instance.new("TextLabel", content)
credits.Size = UDim2.new(1, 0, 0, 50)
credits.Text = "Credits: AirHub Team\nLast Updated: 2026"
credits.TextColor3 = Color3.fromRGB(100, 100, 100)
credits.BackgroundTransparency = 1
credits.Font = Enum.Font.GothamItalic

print("AirHub Premium Loaded. Keybind: K")
