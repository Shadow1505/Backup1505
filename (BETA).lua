-- Delay auto-execution so the game can finish loading.
task.wait(8)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local MaterialService = game:GetService("MaterialService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- ========================================================
-- 1. CONFIG SYSTEM & ANTI-DC RESET
-- ========================================================
local ConfigFolderName = "ShadowHub_Configs"
local ConfigFileName = ConfigFolderName .. "/ShadowHub_Config.json"
local UI_Updaters = {}

local DefaultConfig = {
    AutoTP = false,
    AutoArcadia = false, 
    AutoPellet = false,
    AutoLifeMachine = false,
    LifeMachineCooldownUntil = 0,
    LifeMachineLastTimerText = "",
    AutoFishingToggle = false,
    SelectedFarmingMode = "Map 1 (Throne Room)",
    AutoRotate = false,
    AutoMap2 = false,
    AutoDualMap = false,
    AutoTripleMap = false,
    FPSBooster = false,
    ClayPotato = false,
    Disable3D = false,
    ClearWater = false,
    Limit30FPS = false,
    AutoRAM = false,
    AntiAFK = true,
    WebhookURL = "",
    WebhookPlayer = false,
    WebhookJoinLeave = false,
    UISizeX = 520,
    UISizeY = 320,
    AutoTeleportSpawn = false,
    
    FarmMapCurrent = "Canyon",
    DualMapTimer = 0,
    DualMapSubTimer = 0,
    DualMapPoolIndex = 1,
    
    StaffDetector = false,
    AutoReconnect = false,
    Freecam = false,
    UnlimitedZoom = true,
    
    SprintToggle = false,
    SprintSpeed = 16,
    FlyMode = false,
    FlySpeed = 50,
    InfiniteJump = false,
    NoClip = false,
    Invisible = false,
    LavaImmunity = false,
    
    HideStats = false,
    CustomName = "HiddenShadow",
    CustomLevel = "999",
    RobloxPlusBadge = false,
    
    SelectedTheme = "Default"
}

if makefolder and not isfolder(ConfigFolderName) then
    makefolder(ConfigFolderName)
end

local ConfigData = {}
for k, v in pairs(DefaultConfig) do ConfigData[k] = v end

local function SaveConfig()
    if writefile then
        pcall(function() writefile(ConfigFileName, HttpService:JSONEncode(ConfigData)) end)
    end
end

local function LoadConfig()
    if isfile and isfile(ConfigFileName) and readfile then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(ConfigFileName))
            for k, v in pairs(decoded) do ConfigData[k] = v end
            
            if ConfigData.SelectedFarmingMode == "Map 1 (Rotate)" then
                ConfigData.SelectedFarmingMode = "Map 1 (Throne Room)"
            elseif ConfigData.SelectedFarmingMode == "Dual Map (Switch)" then
                ConfigData.SelectedFarmingMode = "Dual Map (Canyon, Throne)"
            end
        end)
    end
end

-- ========================================================
-- PERSISTENT CUSTOM SAVED LOCATION
-- ========================================================
local function SerializeCFrame(cf)
    if not cf then return nil end
    local components = {cf:GetComponents()}
    return components
end

local function DeserializeCFrame(data)
    if type(data) ~= "table" or #data ~= 12 then return nil end
    local ok, result = pcall(function()
        return CFrame.new(table.unpack(data))
    end)
    return ok and result or nil
end

local forceFarmTP = false

local function ResetConfig()
    for k, v in pairs(DefaultConfig) do 
        ConfigData[k] = v 
        if UI_Updaters[k] then UI_Updaters[k](v) end
    end
    ConfigData.DualMapTimer = 0
    ConfigData.DualMapSubTimer = 0
    ConfigData.DualMapPoolIndex = 1
    ConfigData.FarmMapCurrent = "Canyon"
    ConfigData.SavedCustomLocation = nil
    forceFarmTP = true
    SaveConfig()
end

LoadConfig()

ConfigData.AutoRotate = false
ConfigData.AutoMap2 = false
ConfigData.AutoDualMap = false
ConfigData.AutoTripleMap = false

-- ========================================================
-- THEME MANAGER SYSTEM
-- ========================================================
local Themes = {
    ["Default"] = {
        bg = Color3.fromRGB(15, 15, 18), sidebar = Color3.fromRGB(20, 20, 24), content = Color3.fromRGB(25, 25, 30),
        accent = Color3.fromRGB(140, 60, 255), text = Color3.fromRGB(240, 240, 240), subtext = Color3.fromRGB(170, 170, 170), stroke = Color3.fromRGB(40, 40, 50)
    },
    ["Elegant Gold"] = {
        bg = Color3.fromRGB(20, 18, 15), sidebar = Color3.fromRGB(26, 23, 20), content = Color3.fromRGB(36, 30, 25),
        accent = Color3.fromRGB(212, 175, 55), text = Color3.fromRGB(250, 245, 235), subtext = Color3.fromRGB(180, 170, 150), stroke = Color3.fromRGB(50, 45, 30)
    },
    ["Crimson Blood"] = {
        bg = Color3.fromRGB(18, 10, 10), sidebar = Color3.fromRGB(24, 15, 15), content = Color3.fromRGB(30, 20, 20),
        accent = Color3.fromRGB(220, 20, 60), text = Color3.fromRGB(240, 230, 230), subtext = Color3.fromRGB(170, 150, 150), stroke = Color3.fromRGB(50, 30, 30)
    },
    ["Ocean Blue"] = {
        bg = Color3.fromRGB(10, 15, 20), sidebar = Color3.fromRGB(15, 22, 30), content = Color3.fromRGB(20, 30, 40),
        accent = Color3.fromRGB(0, 150, 255), text = Color3.fromRGB(230, 240, 250), subtext = Color3.fromRGB(150, 170, 190), stroke = Color3.fromRGB(30, 40, 50)
    },
    ["Neon Cyber"] = {
        bg = Color3.fromRGB(10, 10, 15), sidebar = Color3.fromRGB(15, 15, 25), content = Color3.fromRGB(20, 20, 35),
        accent = Color3.fromRGB(0, 255, 255), text = Color3.fromRGB(240, 255, 255), subtext = Color3.fromRGB(150, 180, 200), stroke = Color3.fromRGB(30, 30, 50)
    }
}

local currentTheme = Themes[ConfigData.SelectedTheme] or Themes["Default"]
local c_bg, c_sidebar, c_content, c_accent, c_text, c_subtext = currentTheme.bg, currentTheme.sidebar, currentTheme.content, currentTheme.accent, currentTheme.text, currentTheme.subtext
local RefreshAllToastThemes

local function ApplyTheme()
    local t = Themes[ConfigData.SelectedTheme] or Themes["Default"]
    c_bg, c_sidebar, c_content, c_accent, c_text, c_subtext = t.bg, t.sidebar, t.content, t.accent, t.text, t.subtext
    
    local gui = PlayerGui:FindFirstChild("Shadow_Panel_V8")
    if not gui then return end
    
    for _, obj in ipairs(gui:GetDescendants()) do
        local role = obj:GetAttribute("ThemeRole")
        if not role then continue end
        
        if role == "bg" then pcall(function() obj.BackgroundColor3 = c_bg end)
        elseif role == "sidebar" then pcall(function() obj.BackgroundColor3 = c_sidebar end)
        elseif role == "content" then pcall(function() obj.BackgroundColor3 = c_content end)
        elseif role == "accent_bg" then pcall(function() obj.BackgroundColor3 = c_accent end)
        elseif role == "text" then 
            pcall(function() 
                obj.TextColor3 = c_text 
                if obj:IsA("TextButton") then obj.BackgroundColor3 = c_content end
            end)
        elseif role == "subtext" then pcall(function() obj.TextColor3 = c_subtext end)
        elseif role == "accent_text" then pcall(function() obj.TextColor3 = c_accent end)
        elseif role == "stroke" then pcall(function() obj.Color = t.stroke end)
        elseif role == "scroll" then pcall(function() obj.ScrollBarImageColor3 = c_accent end)
        elseif role == "none" then pcall(function() obj.BackgroundColor3 = Color3.fromRGB(60, 60, 70) end)
        end
    end
end

-- ========================================================
-- 2. DATA KOORDINAT, DETEKSI MAP & HELPERS
-- ========================================================
local spotKordinat = {
    Board = CFrame.lookAt(Vector3.new(-855.63, 44.43, 5187.01), Vector3.new(-855.63, 44.43, 5187.01) + Vector3.new(0, 0, 1)),
    Volcano = CFrame.lookAt(Vector3.new(-813.46, 59.37, 5271.69), Vector3.new(-813.46, 59.37, 5271.69) + Vector3.new(1, 0, 1)),
    Storm = CFrame.lookAt(Vector3.new(-864.27, 56.06, 5309.37), Vector3.new(-864.27, 56.06, 5309.37) + Vector3.new(-1, 0, 1)),
    Blizzard = CFrame.lookAt(Vector3.new(-968.19, 45.83, 5345.58), Vector3.new(-968.19, 45.83, 5345.58) + Vector3.new(-1, 0, -1)),
    Arcadia = CFrame.new(Vector3.new(1338.43, 14.29, 3004.07)) * CFrame.Angles(0, math.rad(-0), 75),
    PelletMachine = CFrame.new(1323.34, 13.34, 2968.82)
}
local DatabaseIconCuaca = {["118379404229807"] = "Blizzard", ["105076841543450"] = "Storm", ["76632496002371"] = "Volcano"}
local posisiSimpanan = nil
local posisiSimpananArcadia = nil

local isWeatherTPBusy = false
local isArcadiaTPBusy = false
local isPelletExecuting = false
local isLifeMachineExecuting = false
local teleportLockOwner = nil
local ExecutePelletCycle -- forward declaration
local pelletAutoInsideInvader = false
local pelletAutoStartAt = 0
local arcadiaEventActive = false
local lifeExtraLifeUIArmed = true

local standPositionRot = Vector3.new(-1290.24, -855.68, 5596.16)
local poolAngles = {-103.43, 135.57, 15.08}
local currentPoolIndex = 1

local map2Pos = Vector3.new(-4014.58, -543.00, 564.95)
local map2Degree = 46.85
local map2CFrame = CFrame.new(map2Pos) * CFrame.Angles(0, math.rad(map2Degree), 0)

local invaderPos = Vector3.new(1360.69, -960.90, 2977.51)
local invaderDegree = 158.26
local invaderCFrame = CFrame.new(invaderPos) * CFrame.Angles(0, math.rad(invaderDegree), 0)

local lifeMachineCFrame = CFrame.new(1266.16, -963.12, 3009.05) * CFrame.Angles(0, math.rad(-32.5), 0)

local rotateInterval = 1160
local dualMapInterval = 3480

-- ====== FUNGSI KHUSUS LIFE MACHINE ======
local function ParseLifeMachineTimer(text)
    if type(text) ~= "string" then return nil end
    local h, m, sec = text:match("(%d+):(%d%d):(%d%d)")
    if h and m and sec then
        return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(sec)
    end
    m, sec = text:match("(%d+):(%d%d)")
    if m and sec then
        return (tonumber(m) * 60) + tonumber(sec)
    end
    return nil
end

local function GetLifeMachineWorldStatus()
    local radius = 12
    local parts = workspace:GetPartBoundsInRadius(lifeMachineCFrame.Position, radius)
    local nearestTimerDistance = math.huge
    local nearestTimerText, nearestTimerSeconds = nil, nil
    local nearestReadyDistance = math.huge
    local foundReady = false
    local seenGui = {}

    local function resolveGuiPart(gui, fallbackPart)
        local adornee = gui.Adornee
        if adornee and adornee:IsA("BasePart") then return adornee end
        local parent = gui.Parent
        while parent and parent ~= workspace do
            if parent:IsA("BasePart") then return parent end
            parent = parent.Parent
        end
        if fallbackPart and fallbackPart:IsA("BasePart") then return fallbackPart end
        return nil
    end

    local function inspectGui(gui, fallbackPart)
        if seenGui[gui] then return end
        seenGui[gui] = true
        local guiPart = resolveGuiPart(gui, fallbackPart)
        if not guiPart then return end
        local distance = (guiPart.Position - lifeMachineCFrame.Position).Magnitude
        if distance > radius then return end

        for _, label in ipairs(gui:GetDescendants()) do
            if (label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox")) and label.Visible then
                local value = tostring(label.Text or "")
                local seconds = ParseLifeMachineTimer(value)
                if seconds ~= nil and distance < nearestTimerDistance then
                    nearestTimerDistance = distance
                    nearestTimerText = value
                    nearestTimerSeconds = seconds
                elseif string.find(string.lower(value), "ready", 1, true) and distance < nearestReadyDistance then
                    nearestReadyDistance = distance
                    foundReady = true
                end
            end
        end
    end

    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            for _, obj in ipairs(part:GetChildren()) do
                if obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
                    inspectGui(obj, part)
                end
            end
            for _, obj in ipairs(part:GetDescendants()) do
                if obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
                    inspectGui(obj, part)
                end
            end
        end
    end

    local nearestPart, nearestPartDistance = nil, math.huge
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            local d = (part.Position - lifeMachineCFrame.Position).Magnitude
            if d < nearestPartDistance then
                nearestPart, nearestPartDistance = part, d
            end
        end
    end
    local machineModel = nearestPart and nearestPart:FindFirstAncestorOfClass("Model")
    if machineModel then
        for _, obj in ipairs(machineModel:GetDescendants()) do
            if obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
                inspectGui(obj, nearestPart)
            end
        end
    end

    local guiRoots = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") or obj:IsA("ScreenGui") then
            table.insert(guiRoots, obj)
        end
    end
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, obj in ipairs(playerGui:GetDescendants()) do
            if obj:IsA("ScreenGui") or obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
                table.insert(guiRoots, obj)
            end
        end
    end

    local bestMachineTimer, bestMachineSeconds = nil, nil
    for _, guiRoot in ipairs(guiRoots) do
        local labels = {}
        local hasBoostTitle = false
        for _, label in ipairs(guiRoot:GetDescendants()) do
            if label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox") then
                table.insert(labels, label)
                local titleText = string.lower(tostring(label.Text or "")):gsub("%s+", " ")
                if string.find(titleText, "8-bit boost", 1, true)
                    or string.find(titleText, "8 bit boost", 1, true) then
                    hasBoostTitle = true
                end
            end
        end

        if hasBoostTitle then
            for _, label in ipairs(labels) do
                local value = tostring(label.Text or "")
                local seconds = ParseLifeMachineTimer(value)
                if seconds ~= nil and seconds > 0 then
                    bestMachineTimer = value
                    bestMachineSeconds = seconds
                    break
                end
            end
        end
        if bestMachineSeconds ~= nil then break end
    end

    if bestMachineSeconds ~= nil then
        return "COOLDOWN", bestMachineTimer, bestMachineSeconds
    end

    if nearestTimerSeconds ~= nil then
        return "COOLDOWN", nearestTimerText, nearestTimerSeconds
    elseif foundReady then
        return "READY", "READY", 0
    end
    return nil, nil, nil
end

local lifeMachineLastPersistedUntil = tonumber(ConfigData.LifeMachineCooldownUntil) or 0
local lifeMachineLastPersistedState = (lifeMachineLastPersistedUntil > os.time()) and "COOLDOWN" or "READY"
local lifeMachineLastSaveClock = 0

local function PersistLifeMachineCooldown(untilTime, timerText, state)
    local oldUntil = tonumber(ConfigData.LifeMachineCooldownUntil) or 0
    local oldText = tostring(ConfigData.LifeMachineLastTimerText or "")
    ConfigData.LifeMachineCooldownUntil = tonumber(untilTime) or 0
    ConfigData.LifeMachineLastTimerText = tostring(timerText or "")

    local nowClock = os.clock()
    local shouldSave = (state ~= lifeMachineLastPersistedState)
        or (math.abs((tonumber(untilTime) or 0) - oldUntil) >= 2)
        or (state == "COOLDOWN" and nowClock - lifeMachineLastSaveClock >= 5)
        or (state == "READY" and oldText ~= "")

    if shouldSave then
        lifeMachineLastPersistedUntil = ConfigData.LifeMachineCooldownUntil
        lifeMachineLastPersistedState = state or "READY"
        lifeMachineLastSaveClock = nowClock
        SaveConfig()
    end
end

local function GetLifeMachineCooldownRemaining()
    local now = os.time()
    local state, machineText, machineSeconds = GetLifeMachineWorldStatus()

    if state == "COOLDOWN" and machineSeconds ~= nil then
        local deadline = now + math.max(0, math.floor(machineSeconds))
        PersistLifeMachineCooldown(deadline, machineText or "", "COOLDOWN")
        return math.max(0, math.floor(machineSeconds)), machineText, "MACHINE"
    end

    if state == "READY" then
        PersistLifeMachineCooldown(0, "", "READY")
        return 0, "READY", "MACHINE"
    end

    local deadline = tonumber(ConfigData.LifeMachineCooldownUntil) or 0
    local remaining = math.max(0, deadline - now)
    if remaining > 0 then
        return remaining, ConfigData.LifeMachineLastTimerText, "SAVED"
    end

    if deadline > 0 then
        return 0, "READY", "SAVED"
    end
    return 0, "SYNCING", "UNKNOWN"
end

local function GetMachineTimerText()
    local remaining, text = GetLifeMachineCooldownRemaining()
    if remaining > 0 then
        return text or formatSecondsToText(remaining), remaining
    end
    return "READY", 0
end

local NotifyToast

local function formatSecondsToText(seconds)
    local h = math.floor(seconds / 3600); local m = math.floor((seconds % 3600) / 60); local s = seconds % 60
    if h > 0 then return string.format("%02dh %02dm %02ds", h, m, s) else return string.format("%02dm %02ds", m, s) end
end

-- ========================================================
-- 5. UI SYSTEM (SHADOW PANEL V8)
-- ========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Shadow_Panel_V8"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- ========================================================
-- TOAST NOTIFICATION SYSTEM
-- ========================================================
local ToastHolder = Instance.new("Frame")
ToastHolder.Name = "ToastHolder"
ToastHolder.Size = UDim2.new(0, 250, 0, 185)
ToastHolder.Position = UDim2.new(1, -10, 1, -10)
ToastHolder.AnchorPoint = Vector2.new(1, 1)
ToastHolder.BackgroundTransparency = 1
ToastHolder.BorderSizePixel = 0
ToastHolder.ZIndex = 1000
ToastHolder.Parent = ScreenGui

local ToastLayout = Instance.new("UIListLayout")
ToastLayout.FillDirection = Enum.FillDirection.Vertical
ToastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.Padding = UDim.new(0, 5)
ToastLayout.Parent = ToastHolder

local toastSerial = 0
local activeToasts = {}
local queuedToasts = {}
local toastBurstUntil = 0

local function SafeToastTween(instance, info, props)
    pcall(function()
        TweenService:Create(instance, info, props):Play()
    end)
end

local function BuildToast(title, message, kind)
    toastSerial = toastSerial + 1
    local toast = Instance.new("Frame")
    toast.Name = "Toast_" .. tostring(toastSerial)
    toast.Size = UDim2.new(0, 250, 0, 40)
    toast.BackgroundTransparency = 1
    toast.BorderSizePixel = 0
    toast.LayoutOrder = toastSerial
    toast.ZIndex = 1000
    toast.Parent = ToastHolder

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(1, 0, 1, 0)
    card.Position = UDim2.new(0, 22, 0, 0)
    card.BackgroundColor3 = c_content
    card.BackgroundTransparency = 0.12
    card.BorderSizePixel = 0
    card.ZIndex = 1001
    card.Parent = toast
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)

    local stroke = Instance.new("UIStroke")
    stroke.Color = c_accent
    stroke.Transparency = 0.35
    stroke.Thickness = 1
    stroke.Parent = card

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, -12)
    accent.Position = UDim2.new(0, 5, 0, 6)
    accent.BackgroundColor3 = c_accent
    accent.BorderSizePixel = 0
    accent.ZIndex = 1002
    accent.Parent = card
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 22, 1, 0)
    icon.Position = UDim2.new(0, 13, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = (kind == "error" and "!") or (kind == "info" and "i") or "✓"
    icon.TextColor3 = c_accent
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 14
    icon.ZIndex = 1002
    icon.Parent = card

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -48, 1, -6)
    label.Position = UDim2.new(0, 38, 0, 3)
    label.BackgroundTransparency = 1
    label.Text = tostring(title) .. "  •  " .. tostring(message)
    label.TextColor3 = c_text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.ZIndex = 1002
    label.Parent = card

    return toast
end

local function RemoveToast(toast)
    for i = #activeToasts, 1, -1 do
        if activeToasts[i] == toast then
            table.remove(activeToasts, i)
            break
        end
    end

    if toast and toast.Parent then
        local card = toast:FindFirstChild("Card")
        if card then
            SafeToastTween(card, TweenInfo.new(0.12), {
                Position = UDim2.new(0, 24, 0, 0),
                BackgroundTransparency = 1
            })
        end
        task.delay(0.14, function()
            pcall(function()
                if toast and toast.Parent then toast:Destroy() end
            end)
        end)
    end
end

local function ShowToast(data)
    if #activeToasts >= 4 then return false end

    local toast = BuildToast(data.title, data.message, data.kind)
    table.insert(activeToasts, toast)

    local card = toast:FindFirstChild("Card")
    if card then
        SafeToastTween(card, TweenInfo.new(0.12), {
            Position = UDim2.new(0, 0, 0, 0)
        })
    end

    local fast = (#activeToasts >= 4) or (#queuedToasts > 0) or (os.clock() < toastBurstUntil)
    local lifetime = fast and 1.15 or 2.0

    task.delay(lifetime, function()
        RemoveToast(toast)
        if #queuedToasts > 0 then
            local nextData = table.remove(queuedToasts, 1)
            task.defer(function()
                ShowToast(nextData)
            end)
        end
    end)

    return true
end

NotifyToast = function(title, message, kind)
    pcall(function()
        title = tostring(title or "Shadow Hub")
        message = tostring(message or "")
        kind = kind or "success"

        if #activeToasts >= 3 then
            toastBurstUntil = os.clock() + 0.8
        end

        local data = {title = title, message = message, kind = kind}
        if #activeToasts < 4 then
            ShowToast(data)
        else
            table.insert(queuedToasts, data)
        end
    end)
end

-- ========================================================
-- MAIN UI FRAME
-- ========================================================
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "ShadowHub_Main"
MainFrame.Size = UDim2.new(0, ConfigData.UISizeX or 520, 0, ConfigData.UISizeY or 320)
MainFrame.Position = UDim2.new(0.5, -(ConfigData.UISizeX or 520)/2, 0.5, -(ConfigData.UISizeY or 320)/2)
MainFrame.BackgroundColor3 = c_bg
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame:SetAttribute("ThemeRole", "bg")
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MS = Instance.new("UIStroke", MainFrame); MS.Color = Color3.fromRGB(40, 40, 50); MS.Thickness = 1
MS:SetAttribute("ThemeRole", "stroke")

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40); Header.BackgroundTransparency = 1

local TitleLabel = Instance.new("TextLabel", Header)
TitleLabel.Size = UDim2.new(0.6, 0, 1, 0); TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1; TitleLabel.Text = "⚜️ SHADOW HUB 🚀"; TitleLabel.TextColor3 = c_accent
TitleLabel:SetAttribute("ThemeRole", "accent_text")
TitleLabel.Font = Enum.Font.GothamBold; TitleLabel.TextSize = 13; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 40, 0, 40); CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "—"; CloseBtn.TextColor3 = c_accent
CloseBtn:SetAttribute("ThemeRole", "accent_text")
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 16

local LogoBtn = Instance.new("TextButton", ScreenGui)
LogoBtn.Size = UDim2.new(0, 45, 0, 45); LogoBtn.Position = UDim2.new(0, 15, 0.45, 0)
LogoBtn.BackgroundColor3 = c_sidebar; LogoBtn.Text = "SHDW\n🚀"; LogoBtn.TextColor3 = c_accent
LogoBtn:SetAttribute("ThemeRole", "sidebar")
LogoBtn.Font = Enum.Font.GothamBlack; LogoBtn.TextSize = 11; LogoBtn.Active = true; LogoBtn.Draggable = true; LogoBtn.Visible = false
Instance.new("UICorner", LogoBtn).CornerRadius = UDim.new(0, 10)

LogoBtn.MouseButton1Click:Connect(function() MainFrame.Visible = true; LogoBtn.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; LogoBtn.Visible = true end)

-- ========================================================
-- SIDEBAR & TABS
-- ========================================================
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 120, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = c_sidebar
Sidebar.BorderSizePixel = 0
Sidebar:SetAttribute("ThemeRole", "sidebar")

local SidebarList = Instance.new("UIListLayout", Sidebar)
SidebarList.FillDirection = Enum.FillDirection.Vertical
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding = UDim.new(0, 3)

-- CONTENT AREA
local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -120, 1, -40)
ContentArea.Position = UDim2.new(0, 120, 0, 40)
ContentArea.BackgroundColor3 = c_content
ContentArea.BorderSizePixel = 0
ContentArea:SetAttribute("ThemeRole", "content")

local ContentScroll = Instance.new("ScrollingFrame", ContentArea)
ContentScroll.Size = UDim2.new(1, 0, 1, 0)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 8
ContentScroll.ScrollBarImageColor3 = c_accent
ContentScroll:SetAttribute("ThemeRole", "scroll")
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local ContentLayout = Instance.new("UIListLayout", ContentScroll)
ContentLayout.FillDirection = Enum.FillDirection.Vertical
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 8)

-- ========================================================
-- TAB SYSTEM
-- ========================================================
local Tabs = {}
local CurrentTab = nil

local function CreateTab(name, active)
    local TabBtn = Instance.new("TextButton", Sidebar)
    TabBtn.Name = name .. "_TabBtn"
    TabBtn.Size = UDim2.new(1, -6, 0, 35)
    TabBtn.BackgroundColor3 = active and c_accent or c_content
    TabBtn.Text = name
    TabBtn.TextColor3 = active and Color3.fromRGB(15, 15, 18) or c_text
    TabBtn:SetAttribute("ThemeRole", "content")
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.TextSize = 10
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 5)
    
    local TabContent = Instance.new("Frame", ContentScroll)
    TabContent.Name = name .. "_Content"
    TabContent.Size = UDim2.new(1, 0, 0, 0)
    TabContent.BackgroundTransparency = 1
    TabContent.BorderSizePixel = 0
    TabContent.Visible = active

    local TabLayout = Instance.new("UIListLayout", TabContent)
    TabLayout.FillDirection = Enum.FillDirection.Vertical
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 5)

    Tabs[name] = {
        Button = TabBtn,
        Content = TabContent,
        Layout = TabLayout
    }

    TabBtn.MouseButton1Click:Connect(function()
        if CurrentTab and Tabs[CurrentTab] then
            Tabs[CurrentTab].Content.Visible = false
            Tabs[CurrentTab].Button.BackgroundColor3 = c_content
            Tabs[CurrentTab].Button.TextColor3 = c_text
        end
        CurrentTab = name
        TabContent.Visible = true
        TabBtn.BackgroundColor3 = c_accent
        TabBtn.TextColor3 = Color3.fromRGB(15, 15, 18)
    end)

    return TabContent
end

-- ========================================================
-- CREATE TABS
-- ========================================================
local AutoTab = CreateTab("AUTO", true)
CurrentTab = "AUTO"

local SettingsTab = CreateTab("SETTINGS", false)
local ToolsTab = CreateTab("TOOLS", false)
local ThemeTab = CreateTab("THEME", false)

-- ========================================================
-- POPULATE AUTO TAB
-- ========================================================
local function CreateToggle(parent, text, configKey, callback)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1, -10, 0, 25)
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0

    local Label = Instance.new("TextLabel", Container)
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = c_text
    Label:SetAttribute("ThemeRole", "text")
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 9
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local ToggleBtn = Instance.new("TextButton", Container)
    ToggleBtn.Size = UDim2.new(0, 30, 0, 15)
    ToggleBtn.Position = UDim2.new(1, -35, 0.5, -7.5)
    ToggleBtn.BackgroundColor3 = ConfigData[configKey] and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(150, 150, 150)
    ToggleBtn.Text = ""
    ToggleBtn.BorderSizePixel = 0
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 7)

    ToggleBtn.MouseButton1Click:Connect(function()
        ConfigData[configKey] = not ConfigData[configKey]
        ToggleBtn.BackgroundColor3 = ConfigData[configKey] and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(150, 150, 150)
        SaveConfig()
        if callback then callback(ConfigData[configKey]) end
    end)

    UI_Updaters[configKey] = function(value)
        ToggleBtn.BackgroundColor3 = value and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(150, 150, 150)
    end
end

CreateToggle(AutoTab, "Auto TP", "AutoTP", nil)
CreateToggle(AutoTab, "Auto Arcadia", "AutoArcadia", nil)
CreateToggle(AutoTab, "Auto Pellet", "AutoPellet", nil)
CreateToggle(AutoTab, "Auto Life Machine", "AutoLifeMachine", nil)
CreateToggle(AutoTab, "Auto Fishing", "AutoFishingToggle", nil)
CreateToggle(AutoTab, "AntiAFK", "AntiAFK", nil)

-- ========================================================
-- POPULATE SETTINGS TAB
-- ========================================================
local function CreateButton(parent, text, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size = UDim2.new(1, -10, 0, 30)
    Btn.BackgroundColor3 = c_accent
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    Btn:SetAttribute("ThemeRole", "accent_bg")
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 10
    Btn.BorderSizePixel = 0
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    Btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return Btn
end

CreateButton(SettingsTab, "Reset Config", function()
    ResetConfig()
    NotifyToast("Settings", "Config Reset!", "success")
end)

CreateButton(SettingsTab, "Save Config", function()
    SaveConfig()
    NotifyToast("Settings", "Config Saved!", "success")
end)

-- ========================================================
-- POPULATE THEME TAB
-- ========================================================
local function CreateSelector(parent, titleText, items, onSelect)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, -10, 0, 80)
    Frame.BackgroundTransparency = 1
    Frame.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, 0, 0, 20)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = c_accent
    Title:SetAttribute("ThemeRole", "accent_text")
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 10

    local SelectBtn = Instance.new("TextButton", Frame)
    SelectBtn.Size = UDim2.new(1, 0, 0, 25)
    SelectBtn.Position = UDim2.new(0, 0, 0, 25)
    SelectBtn.BackgroundColor3 = c_content
    SelectBtn.Text = items[1]
    SelectBtn.TextColor3 = c_text
    SelectBtn:SetAttribute("ThemeRole", "text")
    SelectBtn.Font = Enum.Font.GothamSemibold
    SelectBtn.TextSize = 9
    SelectBtn.BorderSizePixel = 0
    Instance.new("UICorner", SelectBtn).CornerRadius = UDim.new(0, 5)

    local DropdownList = Instance.new("Frame", Frame)
    DropdownList.Size = UDim2.new(1, 0, 0, 0)
    DropdownList.Position = UDim2.new(0, 0, 0, 50)
    DropdownList.BackgroundColor3 = c_sidebar
    DropdownList.BorderSizePixel = 0
    DropdownList.Visible = false
    Instance.new("UICorner", DropdownList).CornerRadius = UDim.new(0, 5)

    local ListLayout = Instance.new("UIListLayout", DropdownList)
    ListLayout.FillDirection = Enum.FillDirection.Vertical
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function populate(newItems)
        DropdownList:ClearAllChildren()
        ListLayout = Instance.new("UIListLayout", DropdownList)
        ListLayout.FillDirection = Enum.FillDirection.Vertical
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

        for _, item in ipairs(newItems) do
            local Option = Instance.new("TextButton", DropdownList)
            Option.Size = UDim2.new(1, 0, 0, 25)
            Option.BackgroundColor3 = c_content
            Option.Text = item
            Option.TextColor3 = c_text
            Option:SetAttribute("ThemeRole", "text")
            Option.Font = Enum.Font.GothamSemibold
            Option.TextSize = 9
            Option.BorderSizePixel = 0

            Option.MouseButton1Click:Connect(function()
                SelectBtn.Text = item
                DropdownList.Visible = false
                if onSelect then onSelect(item) end
            end)
        end
        DropdownList.CanvasSize = UDim2.new(0, 0, 0, #newItems * 25)
    end

    populate(items)

    SelectBtn.MouseButton1Click:Connect(function()
        DropdownList.Visible = not DropdownList.Visible
    end)

    return Frame, populate, SelectBtn
end

-- Themes list
local ThemeNames = {"Default", "Elegant Gold", "Crimson Blood", "Ocean Blue", "Neon Cyber"}
CreateSelector(ThemeTab, "Select Theme", ThemeNames, function(selected)
    ConfigData.SelectedTheme = selected
    SaveConfig()
    ApplyTheme()
    NotifyToast("Theme", "Changed to " .. selected, "success")
end)

print("[Shadow Hub] UI fully loaded and ready!")
