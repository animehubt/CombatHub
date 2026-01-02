--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--// SETTINGS & CONFIG
local Config = {
    Enabled = false,
    HardLock = true,
    ShowFOV = true,
    FOVRadius = 150,
    RotateSpeed = 18,
    LockPart = "HumanoidRootPart",
    ThemeColor = Color3.fromRGB(180, 100, 255)
}

--// VARIABLES
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
local target = nil
local menuOpen = false

--// FOV CIRCLE
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = Config.ThemeColor
FOVCircle.Filled = false
FOVCircle.Transparency = 0.7
FOVCircle.Visible = Config.ShowFOV

--// GUI SETUP
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "CombatHub_V3"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 320, 0, 400)
main.Position = UDim2.new(0.5, -160, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
main.BorderSizePixel = 0
main.Visible = false
Instance.new("UICorner", main)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Config.ThemeColor
stroke.Thickness = 2

--// TARGET HUD (Quality of Life)
local targetHud = Instance.new("Frame", gui)
targetHud.Size = UDim2.new(0, 150, 0, 50)
targetHud.BackgroundColor3 = Color3.fromRGB(0,0,0)
targetHud.BackgroundTransparency = 0.5
targetHud.Visible = false
Instance.new("UICorner", targetHud)

local targetName = Instance.new("TextLabel", targetHud)
targetName.Size = UDim2.new(1, 0, 0.5, 0)
targetName.TextColor3 = Color3.new(1,1,1)
targetName.BackgroundTransparency = 1
targetName.Font = Enum.Font.GothamBold

--// TARGETING LOGIC
local function getTarget()
    local closest = nil
    local dist = Config.FOVRadius

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild(Config.LockPart) then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local pos, onScreen = camera:WorldToViewportPoint(p.Character[Config.LockPart].Position)
                if onScreen then
                    local mouseDist = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                    if mouseDist < dist then
                        dist = mouseDist
                        closest = p.Character
                    end
                end
            end
        end
    end
    return closest
end

--// INPUT HANDLER
UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.K then
        menuOpen = not menuOpen
        main.Visible = menuOpen
        UIS.MouseIconEnabled = not menuOpen
    end
    if i.KeyCode == Enum.KeyCode.Q then
        target = (not target and Config.Enabled) and getTarget() or nil
    end
end)

--// MAIN RENDER LOOP
RunService.RenderStepped:Connect(function(dt)
    -- Update FOV Circle
    FOVCircle.Position = UIS:GetMouseLocation()
    FOVCircle.Radius = Config.FOVRadius
    FOVCircle.Visible = Config.ShowFOV and menuOpen == false
    
    if target and target:FindFirstChild(Config.LockPart) and target.Humanoid.Health > 0 then
        local root = player.Character.HumanoidRootPart
        local aimPos = target[Config.LockPart].Position
        
        -- Smooth Rotation (The "Lock")
        local lookAt = CFrame.lookAt(root.Position, Vector3.new(aimPos.X, root.Position.Y, aimPos.Z))
        root.CFrame = root.CFrame:Lerp(lookAt, math.clamp(dt * Config.RotateSpeed, 0, 1))
        
        -- Target HUD Update
        targetHud.Visible = true
        targetHud.Position = UDim2.new(0, UIS:GetMouseLocation().X + 20, 0, UIS:GetMouseLocation().Y + 20)
        targetName.Text = target.Name .. " | " .. math.floor((root.Position - aimPos).Magnitude) .. " studs"
    else
        target = nil
        targetHud.Visible = false
    end
end)

--// GUI BUTTONS (Example of how to link to Config)
-- You can add the toggle functions here to change Config.Enabled, Config.FOVRadius, etc.
