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
    
    local gui = CoreGui:FindFirstChild("Shadow_Panel_V8")
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
-- 5. UI SYSTEM (SHADOW PANEL V8)
-- ========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Shadow_Panel_V8"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- ========================================================
-- COMPACT TOAST NOTIFICATION SYSTEM
-- Safe/global notification layer: max 4 visible, FIFO queue, never drops.
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

local LogoBtn = Instance.new("TextButton", ScreenGui)
LogoBtn.Size = UDim2.new(0, 45, 0, 45); LogoBtn.Position = UDim2.new(0, 15, 0.45, 0)
LogoBtn.BackgroundColor3 = c_sidebar; LogoBtn.Text = "SHDW\n🚀"; LogoBtn.TextColor3 = c_accent
LogoBtn:SetAttribute("ThemeRole", "sidebar")
LogoBtn.Font = Enum.Font.GothamBlack; LogoBtn.TextSize = 11; LogoBtn.Active = true; LogoBtn.Draggable = true; LogoBtn.Visible = false
Instance.new("UICorner", LogoBtn).CornerRadius = UDim.new(0, 10)

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

LogoBtn.MouseButton1Click:Connect(function() MainFrame.Visible = true; LogoBtn.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; LogoBtn.Visible = true end)

local ResizeHandle = Instance.new("TextButton", MainFrame)
ResizeHandle.Size = UDim2.new(0, 20, 0, 20); ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
ResizeHandle.BackgroundTransparency = 1; ResizeHandle.Text = "◢"; ResizeHandle.TextColor3 = c_subtext
ResizeHandle:SetAttribute("ThemeRole", "subtext")
ResizeHandle.TextSize = 14; ResizeHandle.Font = Enum.Font.GothamBold

-- continue rest of file unchanged...
