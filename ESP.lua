local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TTPPOS"
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 370)
Frame.Position = UDim2.new(0.5, -125, 0.5, -185)
Frame.BackgroundColor3 = Color3.new(0,0,0)
Frame.BackgroundTransparency = 0.3
Frame.BorderSizePixel = 2
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0,0,0,0)
Title.BackgroundTransparency = 1
Title.Text = "TTPPOS (IY 同款底层 Fly 版)"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

local Input = Instance.new("TextBox")
Input.Size = UDim2.new(0.6, 0, 0, 35)
Input.Position = UDim2.new(0.05, 0, 0.15, 0)
Input.PlaceholderText = "距离"
Input.Text = "10" 
Input.BackgroundColor3 = Color3.new(1,1,1)
Input.TextColor3 = Color3.new(0,0,0)
Input.Parent = Frame

-- 速度输入框
local SpeedInput = Instance.new("TextBox")
SpeedInput.Size = UDim2.new(0.3, 0, 0, 35)
SpeedInput.Position = UDim2.new(0.68, 0, 0.15, 0)
SpeedInput.PlaceholderText = "速度"
SpeedInput.Text = "0.1" 
SpeedInput.BackgroundColor3 = Color3.new(1,1,1)
SpeedInput.TextColor3 = Color3.new(0,0,0)
SpeedInput.Parent = Frame

-- ========== 功能开关 ==========
local keepPosition = false
local autoGetWeapon = false
local lastPosition = Vector3.new(0,0,0)
local isMoving = false

-- 独立纵向飞行的控制分量
local buttonFlyDir = Vector3.new(0,0,0)

-- 防拉回按钮
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0.05,0,0.88,0)
ToggleBtn.BackgroundColor3 = Color3.new(1,0.4,0.4)
ToggleBtn.Text = "防拉回：关闭"
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Parent = Frame

ToggleBtn.MouseButton1Click:Connect(function()
    keepPosition = not keepPosition
    if keepPosition then
        ToggleBtn.BackgroundColor3 = Color3.new(0.4,1,0.4)
        ToggleBtn.Text = "防拉回：开启"
        local char = lp.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            lastPosition = char.HumanoidRootPart.Position
        end
    else
        ToggleBtn.BackgroundColor3 = Color3.new(1,0.4,0.4)
        ToggleBtn.Text = "防拉回：关闭"
    end
end)

-- 自动拿武器按钮
local AutoBtn = Instance.new("TextButton")
AutoBtn.Size = UDim2.new(0.9, 0, 0, 30)
AutoBtn.Position = UDim2.new(0.05,0,0.78,0)
AutoBtn.BackgroundColor3 = Color3.new(1,0.4,0.4)
AutoBtn.Text = "自动拿武器：关闭"
AutoBtn.TextColor3 = Color3.new(1,1,1)
AutoBtn.Font = Enum.Font.SourceSansBold
AutoBtn.Parent = Frame

AutoBtn.MouseButton1Click:Connect(function()
    autoGetWeapon = not autoGetWeapon
    if autoGetWeapon then
        AutoBtn.BackgroundColor3 = Color3.new(0.4,1,0.4)
        AutoBtn.Text = "自动拿武器：开启"
    else
        AutoBtn.BackgroundColor3 = Color3.new(1,0.4,0.4)
        AutoBtn.Text = "自动拿武器：关闭"
    end
end)

-- 防拉回循环
RunService.Heartbeat:Connect(function()
    if not keepPosition then return end
    if isMoving then return end
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    hrp.CanCollide = false
    hrp.CFrame = CFrame.new(lastPosition) * hrp.CFrame.Rotation
    hrp.Velocity = Vector3.new(0,0,0)
    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
end)

-- 核心移动
local function Move(targetCF, time)
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    hrp.CanCollide = false

    local root = hrp
    local seat = char:FindFirstChildOfClass("VehicleSeat")
    if seat then
        root = seat.Parent
        root.CanCollide = false
    end

    local startCF = root.CFrame
    local elapsed = 0

    isMoving = true

    while elapsed < time do
        local delta = RunService.Heartbeat:Wait()
        elapsed = elapsed + delta
        local alpha = elapsed / time
        root.CFrame = startCF:Lerp(targetCF, alpha)
        if root.Velocity then
            root.Velocity = Vector3.new(0,0,0)
        end
        if root.AssemblyLinearVelocity then
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end

    isMoving = false

    if keepPosition then
        lastPosition = targetCF.Position
    end
end

-- 检测是否已有武器与拿武器（保留原脚本功能）
local function HasWeapon()
    return lp.Backpack:FindFirstChild("Kriss Vector") ~= nil 
        or (lp.Character and lp.Character:FindFirstChild("Kriss Vector") ~= nil)
end

local function WeaponExists()
    return workspace:FindFirstChild("Prison_ITEMS") 
        and workspace.Prison_ITEMS:FindFirstChild("giver") 
        and workspace.Prison_ITEMS.giver:FindFirstChild("Kriss Vector") 
        and workspace.Prison_ITEMS.giver:FindFirstChild("Kriss Vector"):FindFirstChild("Kriss Vector") ~= nil
end

local function GetWeapon()
    local args = {
        workspace:WaitForChild("Prison_ITEMS"):WaitForChild("giver"):WaitForChild("Kriss Vector"):WaitForChild("Kriss Vector"),
        "GetTool"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Interact"):InvokeServer(unpack(args))
end

-- 手动传送按钮
local TeleportBtn = Instance.new("TextButton")
TeleportBtn.Size = UDim2.new(0.9, 0, 0, 30)
TeleportBtn.Position = UDim2.new(0.05,0,0.68,0)
TeleportBtn.BackgroundColor3 = Color3.new(1,0.6,0)
TeleportBtn.Text = "传送到指定位置"
TeleportBtn.TextColor3 = Color3.new(1,1,1)
TeleportBtn.Font = Enum.Font.SourceSansBold
TeleportBtn.Parent = Frame

TeleportBtn.MouseButton1Click:Connect(function()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targetCF = CFrame.new(802.329224, 292.388916, 173.544601) * CFrame.fromMatrix(Vector3.new(), Vector3.new(0, 0, -1), Vector3.new(0, 1, 0), Vector3.new(1, 0, 0))
    local speed = tonumber(SpeedInput.Text) or 0.5

    Move(targetCF, speed)
    task.wait(0.05)
    GetWeapon()
end)

-- 自动循环
spawn(function()
    while task.wait(0.01) do 
        if not autoGetWeapon then continue end
        if isMoving then continue end
        if HasWeapon() then continue end       
        if not WeaponExists() then continue end 

        local char = lp.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local targetCF = CFrame.new(802.329224, 292.388916, 173.544601) * CFrame.fromMatrix(Vector3.new(), Vector3.new(0, 0, -1), Vector3.new(0, 1, 0), Vector3.new(1, 0, 0))
        local speed = tonumber(SpeedInput.Text) or 0.5

        Move(targetCF, speed)
        task.wait(0.05)
        GetWeapon() 
    end
end)


-- =======================================================
-- 🌟 IY 核心逻辑复刻：直接基于最底层的系统级物理输入计算
-- =======================================================
RunService.RenderStepped:Connect(function()
    if isMoving then return end 
    
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera
    if not hrp or not cam then return end

    local dist = tonumber(Input.Text) or 10
    local moveSpeed = tonumber(SpeedInput.Text) or 0.1
    
    -- 核心：直接在这里初始化我们的飞行动向向量
    local finalDir = Vector3.new(0,0,0)
    
    -- 1. PC 键盘输入映射 (最坚固的物理层，100%不可能被游戏脚本干扰)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then finalDir = finalDir + cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then finalDir = finalDir - cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then finalDir = finalDir - cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then finalDir = finalDir + cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then finalDir = finalDir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then finalDir = finalDir - Vector3.new(0,1,0) end

    -- 2. 手机轮盘自适应映射
    -- 通过绕过 ControlModule，直接去读取 Roblox 系统级生成的 Humanoid 期望移动方向
    -- 虽然 MoveDirection 偶尔被干预，但它的世界坐标基准不会骗人
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.MoveDirection.Magnitude > 0 then
        -- 既然 MoveDirection 已经是包含方向的世界坐标
        -- 如果玩家推动了手机摇杆，我们就直接借用它的运动趋势结合 LookVector 补偿
        local rawMove = hum.MoveDirection
        -- 判断玩家是在前推还是后拉：利用 LookVector 的平面点积
        local dotForward = rawMove:Dot(Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit)
        local dotRight = rawMove:Dot(Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit)
        
        -- 直接将手机轴向映射绑定到相机的 LookVector 和 RightVector（完美的绝对轴映射）
        finalDir = finalDir + (cam.CFrame.LookVector * dotForward) + (cam.CFrame.RightVector * dotRight)
    end

    -- 3. 混合独立 UI 按钮控制
    if buttonFlyDir.Magnitude > 0 then
        finalDir = finalDir + buttonFlyDir
    end

    -- 执行位置平滑瞬移飞行
    if finalDir.Magnitude > 0 then
        finalDir = finalDir.Unit
        local targetPos = hrp.Position + finalDir * dist
        
        -- 身体旋转保持水平面向，防止穿模
        local lookDir = Vector3.new(finalDir.X, 0, finalDir.Z)
        local targetCF
        if lookDir.Magnitude > 0 then
            targetCF = CFrame.new(targetPos) * CFrame.lookAt(Vector3.new(), lookDir.Unit).Rotation
        else
            targetCF = CFrame.new(targetPos) * hrp.CFrame.Rotation
        end
        
        Move(targetCF, moveSpeed)
    end
end)


-- 辅助方向按钮
local function Btn(name, pos, getVec)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 40)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.new(0.2,0.6,1)
    btn.Text = name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Parent = Frame
    
    btn.MouseButton1Click:Connect(function()
        local char = lp.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local cam = workspace.CurrentCamera
        
        local dist = tonumber(Input.Text) or 10
        local moveSpeed = tonumber(SpeedInput.Text) or 0.5 
        
        if getVec == "u" then
            buttonFlyDir = Vector3.new(0, 1, 0)
            task.wait(moveSpeed + 0.05)
            buttonFlyDir = Vector3.new(0, 0, 0)
        elseif getVec == "d" then
            buttonFlyDir = Vector3.new(0, -1, 0)
            task.wait(moveSpeed + 0.05)
            buttonFlyDir = Vector3.new(0, 0, 0)
        else
            local moveDir = Vector3.new(0,0,0)
            if getVec == "l" then moveDir = -cam.CFrame.RightVector end
            if getVec == "r" then moveDir = cam.CFrame.RightVector end
            
            local dir = moveDir.Unit
            local targetPos = char.HumanoidRootPart.Position + dir * dist
            local targetCF = CFrame.new(targetPos) * CFrame.lookAt(Vector3.new(), Vector3.new(dir.X, 0, dir.Z)).Rotation
            Move(targetCF, moveSpeed)
        end
    end)
end

Btn("←", UDim2.new(0.18,0,0.38,0), "l")
Btn("→", UDim2.new(0.52,0,0.38,0), "r")
Btn("🡅", UDim2.new(0.75,0,0.25,0), "u") 
Btn("🡇", UDim2.new(0.75,0,0.50,0), "d")

print("✅ 彻底斩断 Controls 依赖！100% 免疫魔改的 IY 同款纯输入 Fly 算法已加载！")
