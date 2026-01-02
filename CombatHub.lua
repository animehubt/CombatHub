--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

--// PLAYER
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// CHARACTER
local function getChar()
	return player.Character or player.CharacterAdded:Wait()
end

--// ================= GUI =================
local gui = Instance.new("ScreenGui")
gui.Name = "CombatHub"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 420, 0, 420)
main.Position = UDim2.new(0.5, -210, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(25, 10, 40)
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "COMBAT HUB"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(200, 120, 255)
title.BackgroundTransparency = 1

local y = 50

local function label(text)
	local l = Instance.new("TextLabel", main)
	l.Position = UDim2.new(0, 20, 0, y)
	l.Size = UDim2.new(1, -40, 0, 22)
	l.Text = text
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = Color3.fromRGB(170, 100, 255)
	l.TextXAlignment = Left
	l.BackgroundTransparency = 1
	y += 26
end

local function toggle(text, callback)
	local b = Instance.new("TextButton", main)
	b.Position = UDim2.new(0, 20, 0, y)
	b.Size = UDim2.new(1, -40, 0, 28)
	b.Text = text .. ": OFF"
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(45, 20, 70)
	b.BorderSizePixel = 0
	Instance.new("UICorner", b)

	local state = false
	b.MouseButton1Click:Connect(function()
		state = not state
		b.Text = text .. (state and ": ON" or ": OFF")
		b.BackgroundColor3 = state and Color3.fromRGB(80, 30, 120) or Color3.fromRGB(45, 20, 70)
		callback(state)
	end)
	y += 34
end

local function dropdown(text, options, callback)
	local b = Instance.new("TextButton", main)
	b.Position = UDim2.new(0, 20, 0, y)
	b.Size = UDim2.new(1, -40, 0, 28)
	b.Text = text .. ": " .. options[1]
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(45, 20, 70)
	b.BorderSizePixel = 0
	Instance.new("UICorner", b)

	local i = 1
	b.MouseButton1Click:Connect(function()
		i = i % #options + 1
		b.Text = text .. ": " .. options[i]
		callback(options[i])
	end)
	y += 34
end

local function slider(text, min, max, value, callback)
	local bar = Instance.new("Frame", main)
	bar.Position = UDim2.new(0, 20, 0, y)
	bar.Size = UDim2.new(1, -40, 0, 10)
	bar.BackgroundColor3 = Color3.fromRGB(45,20,70)
	bar.BorderSizePixel = 0
	Instance.new("UICorner", bar)

	local fill = Instance.new("Frame", bar)
	fill.BackgroundColor3 = Color3.fromRGB(200,120,255)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new((value-min)/(max-min),0,1,0)
	Instance.new("UICorner", fill)

	local dragging = false
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

	RunService.RenderStepped:Connect(function()
		if dragging then
			local x = math.clamp((UIS:GetMouseLocation().X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
			fill.Size = UDim2.new(x,0,1,0)
			callback(min + (max-min)*x)
		end
	end)

	y += 22
end

--// ================= LOCK SYSTEM =================
local locked = false
local hardLock = true
local showCross = true
local rotateSpeed = 12
local lockPart = "HumanoidRootPart"

local target = nil
local lastPos = nil
local targets = {}
local index = 1

local cross = Instance.new("Frame", gui)
cross.Size = UDim2.new(0,26,0,26)
cross.BackgroundTransparency = 1
cross.Visible = false
for _,v in pairs({true,false}) do
	local f = Instance.new("Frame", cross)
	f.Size = v and UDim2.new(0,2,1,0) or UDim2.new(1,0,0,2)
	f.Position = v and UDim2.new(0.5,-1,0,0) or UDim2.new(0,0,0.5,-1)
	f.BackgroundColor3 = Color3.fromRGB(200,120,255)
	f.BorderSizePixel = 0
end

local function refreshTargets()
	targets = {}
	local char = getChar()
	for _,m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and m ~= char and m:FindFirstChild("Humanoid") and m:FindFirstChild("HumanoidRootPart") then
			table.insert(targets, m)
		end
	end
end

--// ================= GUI CONTENT =================
label("Lock Settings")

toggle("Lock On", function(v)
	locked = v
	local hum = getChar():FindFirstChild("Humanoid")
	if v then
		refreshTargets()
		target = targets[1]
		if hum then hum.AutoRotate = false end
	else
		if hum then hum.AutoRotate = true end
	end
end)

toggle("Hard Lock", function(v) hardLock = v end)
toggle("Crosshair", function(v) showCross = v cross.Visible = v end)

dropdown("Lock Part", {"Torso","Head"}, function(v)
	lockPart = v == "Head" and "Head" or "HumanoidRootPart"
end)

label("Rotation Speed")
slider("Speed", 2, 25, rotateSpeed, function(v)
	rotateSpeed = v
end)

--// ================= INPUT =================
UIS.InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode == Enum.KeyCode.K then
		gui.Enabled = not gui.Enabled
	end
	if i.KeyCode == Enum.KeyCode.E and locked then
		index = index % #targets + 1
		target = targets[index]
	end
	if i.KeyCode == Enum.KeyCode.Q and locked then
		index = (index - 2) % #targets + 1
		target = targets[index]
	end
end)

--// ================= MAIN LOOP =================
RunService.RenderStepped:Connect(function(dt)
	if not locked then return end
	local char = getChar()
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	if not root or not hum then return end

	hum.AutoRotate = false

	local aim
	if target and target:FindFirstChild(lockPart) then
		aim = target[lockPart].Position
		lastPos = aim
	elseif hardLock then
		aim = lastPos
	end
	if not aim then return end

	local d = aim - root.Position
	local flat = Vector3.new(d.X,0,d.Z)
	root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, root.Position+flat), math.clamp(dt*rotateSpeed,0,1))

	if showCross then
		local s,on = camera:WorldToViewportPoint(aim)
		if on then
			cross.Visible = true
			cross.Position = UDim2.new(0,s.X-13,0,s.Y-13)
		end
	end
end)
