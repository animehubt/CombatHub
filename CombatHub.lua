--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--// CONFIG
local Config = {
	Enabled = true,
	RotateSpeed = 25,
	FOV = 300, -- Increased FOV for easier selection
	Theme = Color3.fromRGB(140, 60, 255),
	MenuKey = Enum.KeyCode.K,
	LockKey = Enum.KeyCode.C
}

--// PLAYER & VARS
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- We track the PLAYER instance, not the character, so it persists through death
local LockedPlayer = nil 
local IsLocked = false
local menuOpen = false

--// GUI SETUP (AIRHUB V3 STYLE)
local gui = Instance.new("ScreenGui")
gui.Name = "AirHub_V3_Persistent"
gui.ResetOnSpawn = false -- Keeps GUI when YOU die
gui.Parent = player:WaitForChild("PlayerGui")
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
title.Text = "  AIRHUB V3 | PERSISTENT LOCK"
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
hud.Size = UDim2.new(0, 200, 0, 60)
hud.Position = UDim2.new(0.5, 200, 0.5, -30)
hud.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
hud.Visible = false
Instance.new("UICorner", hud)
Instance.new("UIStroke", hud).Color = Config.Theme

local hudName = Instance.new("TextLabel", hud)
hudName.Size = UDim2.new(1, 0, 0.5, 0)
hudName.Text = "Target: None"
hudName.TextColor3 = Color3.new(1, 1, 1)
hudName.Font = Enum.Font.GothamBold
hudName.BackgroundTransparency = 1

local hudStatus = Instance.new("TextLabel", hud)
hudStatus.Size = UDim2.new(1, 0, 0.3, 0)
hudStatus.Position = UDim2.new(0,0,0.5,0)
hudStatus.Text = "Status: Alive"
hudStatus.TextColor3 = Color3.fromRGB(200,200,200)
hudStatus.Font = Enum.Font.Gotham
hudStatus.BackgroundTransparency = 1

local healthBar = Instance.new("Frame", hud)
healthBar.Size = UDim2.new(0.8, 0, 0, 4)
healthBar.Position = UDim2.new(0.1, 0, 0.85, 0)
healthBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
local fill = Instance.new("Frame", healthBar)
fill.Size = UDim2.new(1, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(0, 255, 120)

--// LOGIC FUNCTIONS

local function getClosestPlayer()
	local targetP = nil
	local nearest = Config.FOV
	
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local pos, vis = camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
			if vis then
				local dist = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
				if dist < nearest then
					nearest = dist
					targetP = p -- Return the PLAYER, not the character
				end
			end
		end
	end
	return targetP
end

-- GUI BUTTONS
local toggleBtn = Instance.new("TextButton", container)
toggleBtn.Size = UDim2.new(1, 0, 0, 45)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
toggleBtn.Text = "  [OFF] Toggle Lock"
toggleBtn.Font = Enum.Font.GothamSemibold
toggleBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
toggleBtn.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", toggleBtn)

local function UpdateToggleStatus()
	if IsLocked then
		toggleBtn.Text = "  [ON] Locked: " .. (LockedPlayer and LockedPlayer.Name or "Scanning...")
		toggleBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
	else
		toggleBtn.Text = "  [OFF] Toggle Lock"
		toggleBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
		hud.Visible = false
	end
end

local function ToggleLockLogic()
	IsLocked = not IsLocked
	
	if IsLocked then
		-- If we don't have a target, find one
		if not LockedPlayer then
			LockedPlayer = getClosestPlayer()
		end
	else
		-- If turning off, clear everything
		LockedPlayer = nil
		hud.Visible = false
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.AutoRotate = true
		end
	end
	UpdateToggleStatus()
end

toggleBtn.MouseButton1Click:Connect(ToggleLockLogic)

--// MANUAL NAME BOX
local nameInput = Instance.new("TextBox", container)
nameInput.Size = UDim2.new(1, 0, 0, 40)
nameInput.PlaceholderText = "Type Username to Lock..."
nameInput.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
nameInput.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", nameInput)

nameInput.FocusLost:Connect(function(enter)
	if enter and nameInput.Text ~= "" then
		for _, v in pairs(Players:GetPlayers()) do
			if v.Name:lower():find(nameInput.Text:lower()) or v.DisplayName:lower():find(nameInput.Text:lower()) then
				LockedPlayer = v
				IsLocked = true
				UpdateToggleStatus()
				break
			end
		end
	end
end)

--// INPUTS
UIS.InputBegan:Connect(function(i, g)
	if g then return end
	if i.KeyCode == Config.MenuKey then
		main.Visible = not main.Visible
	end
	if i.KeyCode == Config.LockKey and Config.Enabled then
		ToggleLockLogic()
	end
end)

--// MAIN ENGINE
RunService.Stepped:Connect(function(dt)
	-- Self Character Checks
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	
	if IsLocked and LockedPlayer and root and hum then
		
		-- Check if Target exists in game (did they leave?)
		if not Players:FindFirstChild(LockedPlayer.Name) then
			IsLocked = false
			LockedPlayer = nil
			UpdateToggleStatus()
			return
		end

		-- Target Character Checks
		local tChar = LockedPlayer.Character
		local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
		local tHum = tChar and tChar:FindFirstChild("Humanoid")

		if tRoot and tHum and tHum.Health > 0 then
			-- PLAYER IS ALIVE AND NEARBY
			
			-- Update HUD
			hud.Visible = true
			hudName.Text = LockedPlayer.DisplayName
			hudStatus.Text = "Status: Locked"
			hudStatus.TextColor3 = Color3.fromRGB(80, 255, 80)
			fill.Size = UDim2.new(math.clamp(tHum.Health / tHum.MaxHealth, 0, 1), 0, 1, 0)
			
			-- ROTATION LOGIC
			local targetPos = tRoot.Position
			local lookCF = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
			root.CFrame = root.CFrame:Lerp(lookCF, 0.5) -- Smoothness
			hum.AutoRotate = false
			
		else
			-- PLAYER IS DEAD OR DESPAWNED (BUT WE KEEP LOCK ON)
			hud.Visible = true
			hudName.Text = LockedPlayer.Name
			hudStatus.Text = "Status: Waiting for Respawn..."
			hudStatus.TextColor3 = Color3.fromRGB(255, 150, 0)
			
			-- Allow normal movement while waiting
			hum.AutoRotate = true
		end
	else
		-- Not locked
		hud.Visible = false
		if hum then hum.AutoRotate = true end
	end
end)

print("Persistent Lock Loaded. Press K for Menu, C to Toggle Lock.")
