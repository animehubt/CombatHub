--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--// CONFIGURATION
local Config = {
    Enabled = true,
    HardLock = true,
    WallCheck = true,
    FOVRadius = 150,
    RotateSpeed = 25,
    LockPart = "HumanoidRootPart",
    ThemeColor = Color3.fromRGB(130, 50, 255),
    MenuKey = Enum.KeyCode.K,
    LockKey = Enum.KeyCode.C
}

--// INTERNAL VARIABLES
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local targetPos = nil 
local targetObj = nil 
local menuOpen = false

--// ================= GUI CONSTRUCTION (AIRHUB PRO) =================
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "AirHub_Final_Edition"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 420, 0, 480)
main.Position = UDim2.new(0.5, -210, 0.5, -240)
main.BackgroundColor3 = Color3.fromRGB(15, 10, 25)
main.BorderSizePixel = 0
main.Visible = false

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Config.ThemeColor
stroke.Thickness = 2

-- Header
local header = Instance.new("TextLabel", main)
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = Color3.fromRGB(25, 15, 45)
header.Text = "  AIRHUB V2.0 | ULTIMATE BATTLEGROUNDS"
header.TextColor3 = Color3.new(1, 1, 1)
header.Font = Enum.Font.GothamBold
header.TextSize = 14
header.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", header)

-- Scrolling Container
local container = Instance.new("ScrollingFrame", main)
container.Size = UDim2.new(1, -20, 1, -65)
container.Position = UDim2.new(0, 10, 0, 55)
container.BackgroundTransparency = 1
container.ScrollBarThickness = 2
container.CanvasSize = UDim2.new(0, 0, 0, 600)

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- ================= TARGET HUD =================
local targetHUD = Instance.new("Frame", gui)
targetHUD.Size = UDim2.new(0, 200, 0, 60)
targetHUD.Position = UDim2.new(0.5, 150, 0.5, -30) -- Appears next to character
targetHUD.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
targetHUD.Visible = false
Instance.new("UICorner", targetHUD)
local hudStroke = Instance.new("UIStroke", targetHUD)
hudStroke.Color = Config.ThemeColor

local hudName = Instance.new("TextLabel", targetHUD)
hudName.Size = UDim2.new(1, -10, 0, 25)
hudName.Position = UDim2.new(0, 5, 0, 5)
hudName.Text = "Target: None"
hudName.TextColor3 = Color3.new(1, 1, 1)
hudName.Font = Enum.Font.GothamBold
hudName.TextScaled = true
hudName.BackgroundTransparency = 1

local healthBarBack = Instance.new("Frame", targetHUD)
healthBarBack.Size = UDim2.new(0.9, 0, 0, 10)
healthBarBack.Position = UDim2.new(0.05, 0, 0.7, 0)
healthBarBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Instance.new("UICorner", healthBarBack)

local healthFill = Instance.new("Frame", healthBarBack)
healthFill.Size = UDim2.new(1, 0, 1, 0)
healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
Instance.new("UICorner", healthFill)

-- ================= UI BUILDER FUNCTIONS =================
local function createToggle(name, default, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
    btn.Text = "  " .. name .. ": " .. (default and "ON" or "OFF")
    btn.Font = Enum.Font.GothamSemibold
    btn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn)
    
    local s = default
    btn.MouseButton1Click:Connect(function()
        s = not s
        btn.Text = "  " .. name .. ": " .. (s and "ON" or "OFF")
        btn.BackgroundColor3 = s and Config.ThemeColor or Color3.fromRGB(30, 20, 50)
        callback(s)
    end)
end

local function createNameBox()
    local box = Instance.new("TextBox", container)
    box.Size = UDim2.new(1, -10, 0, 40)
    box.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
    box.PlaceholderText = "TYPE USERNAME TO LOCK..."
    box.Text = ""
    box.Font = Enum.Font.GothamSemibold
    box.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", box)
    local s = Instance.new("UIStroke", box)
    s.Color = Config.ThemeColor
    
    box.FocusLost:Connect(function(enter)
        if enter and box.Text ~= "" then
            local text = box.Text:lower()
            for _, v in pairs(Players:GetPlayers()) do
                if v.Name:lower():find(text) or v.DisplayName:lower():find(text) then
                    if v.Character and v.Character:FindFirstChild(Config.LockPart) then
                        targetObj = v.Character
                        targetPos = v.Character[Config.LockPart].Position
                        box.Text = "LOCKED: " .. v.DisplayName
                        break
                    end
                end
            end
        end
    end)
end

-- ================= LOGIC =================
local function getTarget()
    local closest, dist = nil, Config.FOVRadius
    local mPos = UIS:GetMouseLocation()
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild(Config.LockPart) then
            local part = p.Character[Config.LockPart]
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local curDist = (Vector2.new(pos.X, pos.Y) - mPos).Magnitude
                    if curDist < dist then
                        dist = curDist
                        closest = p.Character
                    end
                end
            end
        end
    end
    return closest
end

-- Initialize UI Elements
createToggle("Master Lock", true, function(v) Config.Enabled = v end)
createToggle("Hard Persistence", true, function(v) Config.HardLock = v end)
createToggle("Wall Check", true, function(v) Config.WallCheck = v end)
createNameBox()

-- Input Listener
UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Config.MenuKey then
        menuOpen = not menuOpen
        main.Visible = menuOpen
        UIS.MouseIconEnabled = not menuOpen
    end
    if i.KeyCode == Config.LockKey and Config.Enabled then
        if targetPos then
            targetPos, targetObj = nil, nil
        else
            targetObj = getTarget()
            if targetObj then targetPos = targetObj[Config.LockPart].Position end
        end
    end
end)

-- Main Loop
RunService.RenderStepped:Connect(function(dt)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if targetPos and root and hum then
        -- Update Target Info
        if targetObj and targetObj:FindFirstChild(Config.LockPart) then
            targetPos = targetObj[Config.LockPart].Position
            
            -- Update HUD
            targetHUD.Visible = true
            hudName.Text = targetObj.Name
            local tHum = targetObj:FindFirstChild("Humanoid")
            if tHum then
                local hpPercent = tHum.Health / tHum.MaxHealth
                healthFill.Size = UDim2.new(hpPercent, 0, 1, 0)
                healthFill.BackgroundColor3 = Color3.fromHSV(hpPercent * 0.3, 1, 1)
            end
        else
            -- Target despawned/died but HardLock is on
            if not Config.HardLock then 
                targetPos = nil
                targetHUD.Visible = false
            end
        end

        -- Actual Aim Logic
        local lookAt = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
        root.CFrame = root.CFrame:Lerp(lookAt, math.clamp(dt * Config.RotateSpeed, 0, 1))
        hum.AutoRotate = false 
    else
        targetHUD.Visible = false
        if hum then hum.AutoRotate = true end
    end
end)
