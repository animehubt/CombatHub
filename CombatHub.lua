--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--// CONFIG
local Config = {
	Enabled = true,
	HardLock = true,
	RotateSpeed = 25,
	FOV = 150,
	Theme = Color3.fromRGB(140, 60, 255),
	MenuKey = Enum.KeyCode.K,
	LockKey = Enum.KeyCode.C
}

--// PLAYER & VARS
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local targetObj = nil
local targetPos = nil
local menuOpen = false

--// GUI SETUP (AIRHUB V3 STYLE)
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "AirHub_V3"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 380, 0, 420)
main.Position = UDim2.new(0.5, -190, 0.4, -210)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
main.BorderSizePixel = 0
main.Visible = false

local corner = Instance.new("UICorner", main)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Config.Theme
stroke.Thickness = 2

-- Header
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
title.Text = "  AIRHUB V3 | PREMIUM"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", title)

-- Scrolling Container
local container = Instance.new("ScrollingFrame", main)
container.Size = UDim2.new(1, -20, 1, -65)
container.Position = UDim2.new(0, 10, 0, 55)
container.BackgroundTransparency = 1
container.ScrollBarThickness = 2
container.CanvasSize = UDim2.new(0, 0, 0, 500)
Instance.new("UIListLayout", container).Padding = UDim.new(0, 8)

-- Target HUD
local hud = Instance.new("Frame", gui)
hud.Size = UDim2.new(0, 180, 0, 50)
hud.Position = UDim2.new(0.5, 200, 0.5, -25)
hud.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
hud.Visible = false
Instance.new("UICorner", hud)
Instance.new("UIStroke", hud).Color = Config.Theme

local hudName = Instance.new("TextLabel", hud)
hudName.Size = UDim2.new(1, 0, 0.5, 0)
hudName.Text = "No Target"
hudName.TextColor3 = Color3.new(1, 1, 1)
hudName.Font = Enum.Font.GothamBold
hudName.BackgroundTransparency = 1

local healthBar = Instance.new("Frame", hud)
healthBar.Size = UDim2.new(0.8, 0, 0, 6)
healthBar.Position = UDim2.new(0.1, 0, 0.7, 0)
healthBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
local fill = Instance.new("Frame", healthBar)
fill.Size = UDim2.new(1, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(0, 255, 120)

--// UI HELPERS
local function createToggle(text, callback, initial)
	local btn = Instance.new("TextButton", container)
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	btn.Text = "  " .. text .. (initial and " ✅" or " ❌")
	btn.Font = Enum.Font.GothamSemibold
	btn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	btn.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UICorner", btn)
	btn.MouseButton1Click:Connect(function()
		callback()
		btn.Text = "  " .. text .. (Config.HardLock and " ✅" or " ❌")
	end)
end

-- Create Hard Lock Toggle
createToggle("Hard Lock", function()
	Config.HardLock = not Config.HardLock
	if not Config.HardLock then
		targetObj = nil
		targetPos = nil
	end
end, Config.HardLock)

--// AIM LOGIC
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

--// INPUTS
UIS.InputBegan:Connect(function(i, g)
	if g then return end
	if i.KeyCode == Config.MenuKey then
		main.Visible = not main.Visible
	end
	if i.KeyCode == Config.LockKey and Config.Enabled and Config.HardLock then
		if targetObj then
			targetObj = nil
			targetPos = nil
		else
			targetObj = getClosest()
			if targetObj then
				targetPos = targetObj.HumanoidRootPart.Position
			end
		end
	end
end)

--// MANUAL NAME BOX
local nameInput = Instance.new("TextBox", container)
nameInput.Size = UDim2.new(1, 0, 0, 40)
nameInput.PlaceholderText = "Search Username..."
nameInput.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
nameInput.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", nameInput)
nameInput.FocusLost:Connect(function(enter)
	if enter then
		for _, v in pairs(Players:GetPlayers()) do
			if v.Name:lower():find(nameInput.Text:lower()) or v.DisplayName:lower():find(nameInput.Text:lower()) then
				targetObj = v.Character
				if targetObj then
					targetPos = targetObj.HumanoidRootPart.Position
				end
				break
			end
		end
	end
end)

--// MAIN ENGINE
RunService.Stepped:Connect(function(dt)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	
	if targetObj and root and hum and Config.HardLock then
		if targetObj:FindFirstChild("HumanoidRootPart") then
			targetPos = targetObj.HumanoidRootPart.Position
			
			-- Update HUD
			hud.Visible = true
			hudName.Text = targetObj.Name
			local tHum = targetObj:FindFirstChild("Humanoid")
			if tHum then
				fill.Size = UDim2.new(math.clamp(tHum.Health / tHum.MaxHealth, 0, 1), 0, 1, 0)
			end
		else
			-- If target despawns, keep looking for them
			for _, p in pairs(Players:GetPlayers()) do
				if p.Character and p.Character == targetObj then
					targetObj = p.Character
					targetPos = targetObj.HumanoidRootPart.Position
				end
			end
		end
		
		-- Rotation (Overrides Combat Game Scripts)
		local lookCF = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
		root.CFrame = root.CFrame:Lerp(lookCF, 0.25)
		hum.AutoRotate = false
	else
		hud.Visible = false
		if hum then hum.AutoRotate = true end
	end
end)

print("AirHub Ultimate V3 Loaded Successfully with GUI Hard Lock Toggle.")
