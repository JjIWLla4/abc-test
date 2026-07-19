local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local character
local rootPart
local humanoid

-- ====================================================================
-- 📦 核心解耦数据字典
-- ====================================================================
local CurrentTarget = nil 
local coolDownTrees = {} 

-- UI数据统计
local Stat_WLLTPCount = 0 
local Stat_CurrentTreeName = "无"
local Stat_CurrentDistance = 0
local Stat_NavStatus = "等待脚本启动..."

_G.AutoFarmEnabled = false
_G.AttackSpeed = 0.28 -- 完美对齐官方挥砍判定时钟
_G.MoveSpeed = 50 

-- ====================================================================
-- ⚡ 物理参数隔离与自适应射线
-- ====================================================================
local GroundRayParams = RaycastParams.new()
GroundRayParams.FilterType = Enum.RaycastFilterType.Exclude

local ObstacleRayParams = RaycastParams.new()
ObstacleRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function UpdateAllRayParams()
    if character then
        local ignoreList = {character}
        GroundRayParams.FilterDescendantsInstances = ignoreList
        ObstacleRayParams.FilterDescendantsInstances = ignoreList
    end
end

-- ====================================================================
-- 🔄 重生绑定
-- ====================================================================
local nextRadarScan = 0

local function OnCharacterAdded(newCharacter)
    character = newCharacter
    rootPart = newCharacter:WaitForChild("HumanoidRootPart")
    humanoid = newCharacter:WaitForChild("Humanoid")
    
    UpdateAllRayParams()
    
    Stat_CurrentTreeName = "无"
    Stat_CurrentDistance = 0
    Stat_NavStatus = "✨ 重生成功..."
    
    CurrentTarget = nil 
    table.clear(coolDownTrees)
    nextRadarScan = 0 
end

if LocalPlayer.Character then OnCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

-- ====================================================================
-- 🛠️ UI Panel
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")

ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "AutoFarmMatrixUI"

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 80)
MainFrame.BorderSizePixel = 1
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
MainFrame.Size = UDim2.new(0, 240, 0, 245)
MainFrame.Active = true
MainFrame.Draggable = true 

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
Title.Text = " 🪓 AI黄金架构回归版 v37"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local Container = Instance.new("Frame")
Container.Parent = MainFrame
Container.BackgroundTransparency = 1
Container.Position = UDim2.new(0, 10, 0, 35)
Container.Size = UDim2.new(1, -20, 1, -45)

UIListLayout.Parent = Container
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)

local function CreateStatLabel(text, order)
    local label = Instance.new("TextLabel")
    label.Parent = Container
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(180, 180, 200)
    label.TextSize = 13
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = order
    return label
end

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = Container
ToggleBtn.Size = UDim2.new(1, 0, 0, 28)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ToggleBtn.Text = "状态: ❌ 已关闭"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 14
ToggleBtn.LayoutOrder = 1

local Lbl_NavStatus = CreateStatLabel("🤖 状态: 挂机关闭", 3)
local Lbl_CurrentTree = CreateStatLabel("🌲 目标: 无", 4)
local Lbl_WLLTP = CreateStatLabel("🚀 智能折跃熔断数: 0", 5)
local Lbl_FPS = CreateStatLabel("🖥️ 渲染帧率: -- FPS", 6)

ToggleBtn.MouseButton1Click:Connect(function()
    _G.AutoFarmEnabled = not _G.AutoFarmEnabled
    ToggleBtn.BackgroundColor3 = _G.AutoFarmEnabled and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(180, 50, 50)
    ToggleBtn.Text = _G.AutoFarmEnabled and "状态: 🟢 运行中" or "状态: ❌ 已关闭"
    
    if _G.AutoFarmEnabled then
        Stat_NavStatus = "🚀 雷达扫瞄中..."
        CurrentTarget = nil
        table.clear(coolDownTrees)
        nextRadarScan = 0
    else 
        Stat_NavStatus = "挂机已关闭" 
        CurrentTarget = nil
    end
end)

local fpsCount = 0
local nextUpdate = os.clock() + 1
RunService.RenderStepped:Connect(function()
    fpsCount += 1
    if os.clock() >= nextUpdate then
        Lbl_FPS.Text = "🖥️ 渲染帧率: " .. fpsCount .. " FPS"
        fpsCount = 0
        nextUpdate = os.clock() + 1
    end
    
    Lbl_NavStatus.Text = "🤖 状态: " .. Stat_NavStatus
    if _G.AutoFarmEnabled then
        Lbl_CurrentTree.Text = string.format("🌲 目标: %s | 距: %.1fm", Stat_CurrentTreeName, Stat_CurrentDistance)
        Lbl_WLLTP.Text = "🚀 智能折跃熔断数: " .. Stat_WLLTPCount
    else
        Lbl_CurrentTree.Text = "🌲 目标: 无"
    end
end)

-- ====================================================================
-- ⚙️ 地表自适应射线探测（多层材质与穿透过滤）
-- ====================================================================
local function getExactGroundHeight(x, z, targetTree)
    local rayOriginY = 500
    local targetY = nil
    
    local localExclude = {character}
    local tempParams = RaycastParams.new()
    tempParams.FilterType = Enum.RaycastFilterType.Exclude
    
    for depth = 1, 8 do
        tempParams.FilterDescendantsInstances = localExclude
        local origin = Vector3.new(x, rayOriginY, z)
        local direction = Vector3.new(0, -1000, 0)
        
        local result = Workspace:Raycast(origin, direction, tempParams)
        if not result then break end
        
        local inst = result.Instance
        local isTargetTreePart = targetTree and inst:IsDescendantOf(targetTree)
        local isLeaf = (inst.Name == "Leaf" or inst.Name == "Leaves" or inst.Material == Enum.Material.Grass and inst.Parent.Name == "Tree")
        local isWoodPlank = (inst.Material == Enum.Material.WoodPlanks)
        
        if isTargetTreePart or isLeaf or isWoodPlank then
            table.insert(localExclude, inst)
            rayOriginY = result.Position.Y - 0.01
        else
            targetY = result.Position.Y + 3.2
            break
        end
    end
    
    return targetY
end

-- ====================================================================
-- 🚀 WLLTP 智能缓冲投影折跃 (高度自适应落点 + 5.2 studs 攻击缘)
-- ====================================================================
local function performSkyWLLTP(targetTree)
    if not rootPart or not targetTree or not targetTree.Parent then return false end
    Stat_WLLTPCount += 1
    Stat_NavStatus = "🛰️ 穿梭中：300m高空平移..."
    
    local treePos = targetTree:GetPivot().Position
    local startPos = rootPart.Position
    
    -- 🌟 像素级还原：基于玩家方向动态计算落点，绝不卡墙
    local dirToPlayer = (startPos - treePos)
    local horizontalDir = Vector3.new(dirToPlayer.X, 0, dirToPlayer.Z)
    if horizontalDir.Magnitude < 0.1 then
        horizontalDir = Vector3.new(1, 0, 0) 
    end
    
    -- 🌟 优化修正：降落线设在 5.2 studs 黄金攻击缘，落地直接触发判定
    local safeLandingPos = treePos + horizontalDir.Unit * 5.2
    
    local skyY = math.max(startPos.Y, treePos.Y) + 300
    
    rootPart.CFrame = CFrame.new(startPos.X, skyY, startPos.Z)
    task.wait(0.02)
    
    rootPart.CFrame = CFrame.new(safeLandingPos.X, skyY, safeLandingPos.Z)
    task.wait(0.02)
    
    local landingY = getExactGroundHeight(safeLandingPos.X, safeLandingPos.Z, targetTree)
    if not landingY then
        landingY = math.max(treePos.Y, startPos.Y) 
    end
    
    rootPart.CFrame = CFrame.lookAt(Vector3.new(safeLandingPos.X, landingY, safeLandingPos.Z), Vector3.new(treePos.X, landingY, treePos.Z))
    task.wait(0.05)
    return true
end

-- ====================================================================
-- ⚙️ 双模自适应推进引擎（v34 完整保留：扇形探路预判 + 贴地补走步进）
-- ====================================================================
local function ttposMoveTo(nearestTree)
    if not rootPart then return false end
    
    local treePos = nearestTree:GetPivot().Position
    local currentPos = rootPart.Position
    local pathVec = (treePos - currentPos)
    
    -- 7 根扇形探路雷达
    local angles = {0, 10, 20, 30, -10, -20, -30}
    local hitsCount = 0
    local maxDetectDistance = math.min(pathVec.Magnitude, 25.0)
    
    for _, angle in ipairs(angles) do
        local dirUnit = CFrame.Angles(0, math.rad(angle), 0) * pathVec.Unit
        local rayOrigin = currentPos + Vector3.new(0, 2.5, 0)
        local rayDirection = dirUnit * maxDetectDistance
        
        local result = Workspace:Raycast(rayOrigin, rayDirection, ObstacleRayParams)
        if result then
            local hit = result.Instance
            local isTargetTreePart = hit:IsDescendantOf(nearestTree)
            local isTerrain = (hit.ClassName == "Terrain" or hit.Name == "Terrain" or hit.Name == "Grass")
            local isGentleSlope = (result.Normal.Y > 0.8)
            
            if not isTargetTreePart and not isTerrain and not isGentleSlope then
                hitsCount += 1
                if hitsCount >= 2 then 
                    break
                end
            end
        end
    end
    
    if hitsCount >= 2 then
        Stat_NavStatus = "📡 雷达扫到山体，直接起飞穿梭..."
        local success = performSkyWLLTP(nearestTree)
        if success then
            currentPos = rootPart.Position 
        else
            return false
        end
    end

    -- 极简贴地步进循环
    while _G.AutoFarmEnabled and rootPart and character and character.Parent and CurrentTarget == nearestTree do
        currentPos = rootPart.Position
        
        local distanceToTreeCenter = (currentPos - treePos).Magnitude
        Stat_CurrentDistance = distanceToTreeCenter
        
        -- 🌟 回归黄金判定线：进入 5.5 studs 后平稳移交攻击核心
        if distanceToTreeCenter <= 5.5 then
            print("🚀 [TTPOS] 满足导航判定圈 (<= 5.5 studs):", distanceToTreeCenter)
            return true
        end
        
        -- DeltaTime 自适应步进
        local deltaTime = RunService.Heartbeat:Wait()
        local moveStep = _G.MoveSpeed * deltaTime
        
        -- 平滑朝树挪动
        local directionToTree = (treePos - currentPos)
        if moveStep > (distanceToTreeCenter - 5.2) then
            moveStep = (distanceToTreeCenter - 5.2)
        end
        
        local nextStepPos = currentPos + (directionToTree.Unit * moveStep)
        
        -- 地表高度贴合
        local groundY = getExactGroundHeight(nextStepPos.X, nextStepPos.Z, nearestTree)
        if groundY then
            local clampedY = currentPos.Y + math.clamp(groundY - currentPos.Y, -4.0, 4.0)
            nextStepPos = Vector3.new(nextStepPos.X, clampedY, nextStepPos.Z)
        end
        
        if rootPart then
            rootPart.CFrame = CFrame.lookAt(nextStepPos, Vector3.new(treePos.X, nextStepPos.Y, treePos.Z))
        end
    end
    return false
end

local replicatedStorage = game:GetService("ReplicatedStorage")
local toolSystem = replicatedStorage:FindFirstChild("ToolSystem")
local remoteEvents = toolSystem and toolSystem:FindFirstChild("RemoteEvents")
local swingEvent = remoteEvents and remoteEvents:FindFirstChild("Swing")

-- ====================================================================
-- 🔄 第四部分：主控制核心（完全恢复 v34 高精对齐逻辑）
-- ====================================================================
task.spawn(function()
    while true do
        if _G.AutoFarmEnabled then
            if rootPart and character and character.Parent then
                local myPosition = rootPart.Position
                
                local targetValid = CurrentTarget and CurrentTarget.Parent
                if targetValid then
                    local dist = (CurrentTarget:GetPivot().Position - myPosition).Magnitude
                    if dist > 180 then targetValid = false end
                else
                    targetValid = false
                end
                
                -- 🚀 实时无缓存扫描
                if not targetValid and os.clock() >= nextRadarScan then
                    Stat_NavStatus = "🔍 雷达高精扫描中..."
                    
                    local nearestTree = nil
                    local shortestDistance = 180 
                    
                    for _, desc in ipairs(Workspace:GetDescendants()) do
                        if desc.Name == "Tree" and desc:IsA("Model") then
                            if desc.Parent and not coolDownTrees[desc] then
                                local distance = (desc:GetPivot().Position - myPosition).Magnitude
                                if distance < shortestDistance then
                                    shortestDistance = distance
                                    nearestTree = desc
                                end
                            end
                        end
                    end
                    
                    if nearestTree then
                        CurrentTarget = nearestTree
                        Stat_NavStatus = "🎯 锁定目标，正在前往" 
                    else
                        Stat_NavStatus = "⚠️ 周边没有可砍伐的树"
                    end
                    
                    nextRadarScan = os.clock() + 0.15 
                end

                -- 推进与砍伐
                if CurrentTarget then
                    local treePos = CurrentTarget:GetPivot().Position
                    Stat_CurrentTreeName = CurrentTarget.Name
                    
                    local currentDistanceToTree = (rootPart.Position - treePos).Magnitude
                    local arrived = false
                    
                    if currentDistanceToTree > 5.5 then
                        arrived = ttposMoveTo(CurrentTarget)
                    else
                        arrived = true 
                    end
                    
                    -- 到达执行砍伐
                    if arrived and rootPart and CurrentTarget and CurrentTarget.Parent then
                        
                        -- 工具软获取，不强拦截
                        local currentTool = character:FindFirstChildOfClass("Tool")
                        local toolName = currentTool and currentTool.Name or "Metal Hatchet"
                        
                        print("⚔️ [开始物理对齐] 工具 ->", toolName)
                        
                        -- 🌟 完美恢复：连续 5 帧深度视口锁定 + 前顶补偿微调（防抖、防空气砍）
                        local function AlignViewport()
                            if not rootPart or not CurrentTarget then return end
                            local freshTreePos = CurrentTarget:GetPivot().Position
                            local dir = (freshTreePos - rootPart.Position).Unit
                            -- 向树干方向前顶微调，并保持面朝目标
                            local adjustedCFrame = CFrame.lookAt(rootPart.Position + dir * 0.5, Vector3.new(freshTreePos.X, rootPart.Position.Y, freshTreePos.Z))
                            rootPart.CFrame = adjustedCFrame
                            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Vector3.new(freshTreePos.X, Camera.CFrame.Position.Y, freshTreePos.Z))
                            if humanoid then humanoid.AutoRotate = false end
                        end

                        for i = 1, 5 do
                            AlignViewport()
                            RunService.Heartbeat:Wait()
                        end

                        Stat_NavStatus = "⚔️ 挥刀中"
                        local initialDescendantCount = #CurrentTarget:GetDescendants()
                        
                        local function getTreeHealth(target)
                            if not target or not target.Parent then return 0 end
                            local h = target:GetAttribute("Health") or target:FindFirstChild("Health")
                            if typeof(h) == "Instance" then return h.Value end
                            if typeof(h) == "number" then return h end
                            return nil
                        end
                        
                        local treeLock = CurrentTarget 
                        local startHealth = getTreeHealth(treeLock)
                        local lastHealthCheckTime = os.clock()
                        local lastCheckTime = os.clock()
                        local compensationSteps = 0 
                        
                        -- 🌟 完美恢复：带有血量监控、未同步步进补偿的智能循环（砍完才走，绝不掐断）
                        while _G.AutoFarmEnabled and rootPart and CurrentTarget == treeLock and treeLock.Parent do
                            local currentHealth = getTreeHealth(treeLock)
                            if currentHealth and currentHealth <= 0 then 
                                print("🎉 [生命周期结束]: 树木已确认倒下，正常退出循环。")
                                break 
                            end
                            
                            -- 未同步补偿推进（若服务器没掉血，则继续向树心微调前顶）
                            if os.clock() - lastHealthCheckTime >= 0.6 then
                                lastHealthCheckTime = os.clock()
                                
                                if currentHealth and startHealth and currentHealth >= startHealth then
                                    if compensationSteps < 3 then
                                        compensationSteps += 1
                                        Stat_NavStatus = string.format("⚠️ 未同步，前顶 %.1f米", compensationSteps * 0.5)
                                        local freshTreePos = treeLock:GetPivot().Position
                                        local dir = (freshTreePos - rootPart.Position).Unit
                                        rootPart.CFrame = CFrame.lookAt(rootPart.Position + dir * 0.5, Vector3.new(freshTreePos.X, rootPart.Position.Y, freshTreePos.Z))
                                        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Vector3.new(freshTreePos.X, Camera.CFrame.Position.Y, freshTreePos.Z))
                                        task.wait(0.05)
                                    else
                                        print("⚠️ [反卡死机制]: 伤害长时间未同步，强制释放当前树木。")
                                        break
                                    end
                                else
                                    startHealth = currentHealth
                                end
                            end
                            
                            -- 子级消亡判定（防断联备份）
                            if os.clock() - lastCheckTime >= 10.0 then
                                lastCheckTime = os.clock()
                                if #treeLock:GetDescendants() < (initialDescendantCount * 0.7) then break end
                            end
                            
                            if swingEvent then
                                local freshTreePos = treeLock:GetPivot().Position
                                rootPart.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(freshTreePos.X, rootPart.Position.Y, freshTreePos.Z))
                                
                                -- 🌟 完美恢复：高频实时获取 freshCFrame 发包，跟随服务器物理抖动
                                local freshCFrame = treeLock:GetPivot()
                                swingEvent:FireServer(freshCFrame, 0.28, toolName, Workspace.Terrain)
                            end
                            task.wait(_G.AttackSpeed) 
                        end
                        
                        if humanoid then humanoid.AutoRotate = true end

                        -- 标记冷却，释放资源
                        local finalCompletedTree = treeLock
                        coolDownTrees[finalCompletedTree] = true
                        task.delay(3.0, function() 
                            coolDownTrees[finalCompletedTree] = nil 
                        end)
                    end
                    
                    -- 释放锁定
                    CurrentTarget = nil 
                    nextRadarScan = 0 
                    task.wait(0.02) 
                else
                    nextRadarScan = 0 
                    task.wait(0.1)
                end
            else
                CurrentTarget = nil
                Stat_NavStatus = "⏳ 连接角色躯干..."
                task.wait(0.2)
            end
        else
            task.wait(0.4)
        end
    end
end)

