--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

--// SETTINGS
local Config = {
	Enabled = true,
	RotateSpeed = 15,
	LockPart = "HumanoidRootPart", -- Can be "Head" or "HumanoidRootPart"
	MenuKey = Enum.KeyCode.K,
	LockKey = Enum.KeyCode.Q
}

--// VARIABLES
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local target = nil
local menuOpen = false

--// ================= GUI SETUP =================
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalCombatHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Main Menu Frame
local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 250, 0, 180)
main.Position = UDim2.new(0.5, -125, 0.4, -90)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Visible = false -- Controlled by 'K'

local corner = Instance.new("UICorner", main)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(130, 80, 255)
stroke.Thickness = 2

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "COMBAT HUB PRO"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1

-- Status Label
local status = Instance.new("TextLabel", main)
status.Size = UDim2.new(1, 0, 0, 30)
status.Position = UDim2.new(0, 0, 0, 40)
status.Text = "Status: READY"
status.TextColor3 = Color3.fromRGB(150, 150, 150)
status.Font = Enum.Font.Gotham
status.BackgroundTransparency = 1

local hint = Instance.new("TextLabel", main)
hint.Size = UDim2.new(1, 0, 0, 80)
hint.Position = UDim2.new(0, 0, 0, 80)
hint.Text = "[K] Close Menu\n[Q] Lock Onto Closest\n[Q] Again to Unlock"
hint.TextColor3 = Color3.fromRGB(100, 100, 100)
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.BackgroundTransparency = 1

--// ================= TARGETING LOGIC =================
local function getClosestPlayerToCursor()
	local closestPlayer = nil
	local shortestDistance = math.huge
	local mousePos = UIS:GetMouseLocation()

	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and v.Character and v.Character:FindFirstChild(Config.LockPart) then
			local root = v.Character[Config.LockPart]
			local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
			
			if onScreen then
				local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
				if distance < shortestDistance then
					closestPlayer = v.Character
					shortestDistance = distance
				end
			end
		end
	end
	return closestPlayer
end

--// ================= INPUTS =================
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	
	-- Toggle Menu
	if input.KeyCode == Config.MenuKey then
		menuOpen = not menuOpen
		main.Visible = menuOpen
	end
	
	-- Toggle Lock
	if input.KeyCode == Config.LockKey then
		if target then
			target = nil
			status.Text = "Status: UNLOCKED"
			status.TextColor3 = Color3.fromRGB(200, 50, 50)
		else
			target = getClosestPlayerToCursor()
			if target then
				status.Text = "Status: LOCKED -> " .. target.Name
				status.TextColor3 = Color3.fromRGB(50, 200, 50)
			end
		end
	end
end)

--// ================= MAIN LOOP =================
RunService.RenderStepped:Connect(function(dt)
	if target and target:FindFirstChild(Config.LockPart) then
		local myChar = player.Character
		if myChar and myChar:FindFirstChild("HumanoidRootPart") then
			local myRoot = myChar.HumanoidRootPart
			local aimAt = target[Config.LockPart].Position
			
			-- Only rotate the character's facing direction (Horizontal Lock)
			local goalCF = CFrame.lookAt(myRoot.Position, Vector3.new(aimAt.X, myRoot.Position.Y, aimAt.Z))
			myRoot.CFrame = myRoot.CFrame:Lerp(goalCF, math.clamp(dt * Config.RotateSpeed, 0, 1))
			
			-- Force character to stay upright
			if myChar:FindFirstChild("Humanoid") then
				myChar.Humanoid.AutoRotate = false
			end
		end
	else
		-- Reset AutoRotate if not locking
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.AutoRotate = true
		end
	end
end)

print("Combat Hub Loaded. Press K to hide/show menu.")
