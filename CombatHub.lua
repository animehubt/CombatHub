--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--// PLAYER & CAMERA
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

--// VARIABLES
local menuOpen = false
local locked = false
local hardLock = true
local showCross = true
local rotateSpeed = 15
local lockPart = "HumanoidRootPart"
local target = nil

--// ================= GUI CONSTRUCTION =================
local gui = Instance.new("ScreenGui")
gui.Name = "CombatHub_Pro"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 300, 0, 380)
main.Position = UDim2.new(0.5, -150, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(100, 60, 180)
stroke.Thickness = 2

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "COMBAT HUB V2"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(200, 150, 255)
title.BackgroundTransparency = 1

--// DRAGGING SYSTEM
local dragging, dragInput, dragStart, startPos
main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local container = Instance.new("ScrollingFrame", main)
container.Size = UDim2.new(1, -20, 1, -50)
container.Position = UDim2.new(0, 10, 0, 45)
container.BackgroundTransparency = 1
container.ScrollBarThickness = 2
container.CanvasSize = UDim2.new(0,0,0,400)

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

--// UTILS
local function createButton(text, callback)
	local b = Instance.new("TextButton", container)
	b.Size = UDim2.new(1, -10, 0, 35)
	b.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
	b.Text = text .. ": OFF"
	b.Font = Enum.Font.GothamSemibold
	b.TextColor3 = Color3.new(1,1,1)
	b.TextSize = 13
	Instance.new("UICorner", b)
	
	local state = false
	b.MouseButton1Click:Connect(function()
		state = not state
		b.Text = text .. (state and ": ON" or ": OFF")
		b.BackgroundColor3 = state and Color3.fromRGB(100, 50, 180) or Color3.fromRGB(40, 30, 60)
		callback(state)
	end)
end

--// CROSSHAIR
local cross = Instance.new("Frame", gui)
cross.Size = UDim2.new(0,20,0,20)
cross.BackgroundTransparency = 1
cross.Visible = false
local ch1 = Instance.new("Frame", cross)
ch1.Size = UDim2.new(0,2,1,0)
ch1.Position = UDim2.new(0.5,-1,0,0)
ch1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
local ch2 = Instance.new("Frame", cross)
ch2.Size = UDim2.new(1,0,0,2)
ch2.Position = UDim2.new(0,0,0.5,-1)
ch2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

--// LOGIC FUNCTIONS
local function getClosestTarget()
	local closest = nil
	local dist = math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local hum = p.Character:FindFirstChild("Humanoid")
			if hum and hum.Health > 0 then
				local pos, onScreen = camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
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

--// GUI CONTENT
createButton("Aim Lock", function(v) locked = v end)
createButton("Hard Tracking", function(v) hardLock = v end)
createButton("Show Crosshair", function(v) showCross = v end)

--// KEYBIND LISTENER
UIS.InputBegan:Connect(function(i, processed)
	if processed then return end
	
	if i.KeyCode == Enum.KeyCode.K then
		menuOpen = not menuOpen
		main.Visible = menuOpen
		UIS.MouseIconEnabled = not menuOpen
	end
	
	if i.KeyCode == Enum.KeyCode.Q and locked then
		target = getClosestTarget()
	end
end)

--// MAIN LOOP
RunService.RenderStepped:Connect(function(dt)
	if locked and target and target:FindFirstChild(lockPart) then
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChild("Humanoid")
		
		if root and hum then
			-- Check if target is dead
			if target.Humanoid.Health <= 0 then
				target = nil
				return
			end
			
			hum.AutoRotate = false
			local lookPos = target[lockPart].Position
			local goal = CFrame.lookAt(root.Position, Vector3.new(lookPos.X, root.Position.Y, lookPos.Z))
			root.CFrame = root.CFrame:Lerp(goal, math.clamp(dt * rotateSpeed, 0, 1))
			
			if showCross then
				local pos, onScreen = camera:WorldToViewportPoint(lookPos)
				if onScreen then
					cross.Visible = true
					cross.Position = UDim2.new(0, pos.X - 10, 0, pos.Y - 10)
				else
					cross.Visible = false
				end
			end
		end
	else
		cross.Visible = false
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.AutoRotate = true
		end
	end
end)
