-- =============================================================================
-- 【Build_Absolute_Fixer_v7_1.lua】 仅修复建筑名称正则过滤流
-- =============================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local buildRemote = ReplicatedStorage:WaitForChild("BuildingSystem"):WaitForChild("RemoteEvents"):WaitForChild("Build")

-- 🏆 全局旋转状态机变量兜底
_G.OfficialRotationState = _G.OfficialRotationState or 1

-- 1. 【翻译字典】增强容错性，全面兼容带数字和不带数字的输入
local nameMap = {
    ["squarerender"] = "Square Foundation",
    ["squarefloor"] = "Square Foundation",
    ["trianglerender"] = "Triangle Foundation",
    ["squareroofrender"] = "Square Roof",
    ["triangleroofrender"] = "Triangle Roof",
    ["wallrender"] = "Wall",
    ["windowrender"] = "Window",
    ["doorwayrender"] = "Doorway",
    ["framrender"] = "Frame",
    ["framerender"] = "Frame",
    ["ustairsrender"] = "UStairs",
    ["stairsrender"] = "Stairs",
}

-- 2. 获取 Camera 内部官方预览模型
local function getOfficialRenderModel()
    for _, child in ipairs(camera:GetChildren()) do
        if child:IsA("Model") and string.find(child.Name, "Render") then
            return child
        end
    end
    return nil
end

-- 3. 强发内核
local function forcedFireServer()
    local renderModel = getOfficialRenderModel()
    if not renderModel then
        warn("⚠️ [提示] 当前屏幕上没有活跃的官方预览蓝图。")
        return
    end

    -- =============================================================================
    -- 🔥【核心修复】完全替换为你提供的精准正则去数字过滤流
    -- =============================================================================
    local cleanName = string.gsub(renderModel.Name, "%d+$", "") -- 去掉尾部数字 (如 WallRender1 -> WallRender)
    local rawNameLower = string.lower(cleanName)
    local serverName = nameMap[rawNameLower] or string.gsub(cleanName, "Render", "")
    
    print("----------------------------------------")
    print("🏗️ [建筑名称清洗拦截] 原始名: " .. renderModel.Name .. " => 转换后: " .. serverName)
    print("----------------------------------------")

    -- 临时采用当前的 Pivot 坐标数据，本次测试不做修改
    local finalCFrame = renderModel.PrimaryPart and renderModel.PrimaryPart.CFrame or renderModel:GetPivot()
    
    local needRotationParam = {
        ["Wall"] = true, ["Window"] = true, ["Doorway"] = true,
        ["Frame"] = true, ["UStairs"] = true, ["Stairs"] = true
    }

    local args = { serverName, finalCFrame }
    if needRotationParam[serverName] then
        table.insert(args, 3, _G.OfficialRotationState)
    end

    pcall(function()
        buildRemote:FireServer(unpack(args))
    end)
end

-- 4. 🧭【原生按钮绝对劫持】
local playerGui = localPlayer:WaitForChild("PlayerGui")
local mobileControls = playerGui:WaitForChild("MobileControls")
local frame = mobileControls:WaitForChild("Frame")
local officialPlaceButton = frame:FindFirstChild("PlaceBuild")

if officialPlaceButton and (officialPlaceButton:IsA("TextButton") or officialPlaceButton:IsA("ImageButton")) then
    print("🎯 [原生对接成功] 已经捕获原生 MobileControls 放置按钮。")
    
    if getconnections then
        for _, connection in ipairs(getconnections(officialPlaceButton.Activated)) do
            connection:Disable()
        end
        for _, connection in ipairs(getconnections(officialPlaceButton.MouseButton1Click)) do
            connection:Disable()
        end
        print("✂️ 官方原本的点击阻断已成功剥离！")
    end

    officialPlaceButton.Activated:Connect(forcedFireServer)
    officialPlaceButton.MouseButton1Click:Connect(forcedFireServer)
    print("🎉 【建筑名修正拦截器】注入完毕，等待测试！")
else
    warn("❌ 未能通过路径定位到 MobileControls.Frame.PlaceBuild 按钮！")
end

