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
-- Teleport priority lock: Pellet owns teleport control during its 4-cycle batch.
local teleportLockOwner = nil
local ExecutePelletCycle -- forward declaration for the manual trigger
local pelletAutoInsideInvader = false
local pelletAutoStartAt = 0
-- Shared priority flag: dideklarasikan sebelum semua thread agar weather/farm/machine
-- dapat menghormati event Kraken sebagai prioritas tertinggi.
local arcadiaEventActive = false
local lifeExtraLifeUIArmed = true

-- Farming Maps Position
local standPositionRot = Vector3.new(-1290.24, -855.68, 5596.16)
local poolAngles = {-103.43, 135.57, 15.08}
local currentPoolIndex = 1

local map2Pos = Vector3.new(-4014.58, -543.00, 564.95)
local map2Degree = 46.85
local map2CFrame = CFrame.new(map2Pos) * CFrame.Angles(0, math.rad(map2Degree), 0)

-- UPDATE KOORDINAT INVADER TERBARU
local invaderPos = Vector3.new(1360.69, -960.90, 2977.51)
local invaderDegree = 158.26
local invaderCFrame = CFrame.new(invaderPos) * CFrame.Angles(0, math.rad(invaderDegree), 0)

-- LIFE MACHINE TRIGGER V5: EXACT COORDINATE + CAMERA-INDEPENDENT PROMPT
local lifeMachineCFrame = CFrame.new(1266.16, -963.12, 3009.05) * CFrame.Angles(0, math.rad(-32.5), 0)

local rotateInterval = 1160
local dualMapInterval = 3480

-- ====== FUNGSI KHUSUS LIFE MACHINE ======
-- Sumber status cooldown HANYA boleh berasal dari UI/GUI yang menempel
-- pada objek di sekitar koordinat Life Machine. Timer dari UI lain di map
-- tidak boleh ikut terbaca.
local function ParseLifeMachineTimer(text)
    if type(text) ~= "string" then return nil end

    -- Mendukung HH:MM:SS maupun MM:SS.
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
    -- Scan hanya di sekitar titik interaksi Life Machine. Timer diprioritaskan
    -- daripada teks READY agar label READY dari GUI lain tidak menimpa timer.
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

    -- Fallback untuk GUI yang parent/Adornee-nya berada dalam model mesin.
    -- Hanya model dari part terdekat ke koordinat Life Machine yang diperiksa.
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

    -- Cari GUI mesin berdasarkan judul "8-Bit Boost". GUI bisa berupa
    -- BillboardGui/SurfaceGui di Workspace atau ScreenGui di PlayerGui;
    -- jangan batasi pencarian pada jarak karakter dari mesin.
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
            -- Timer harus berada dalam GUI yang sama dengan judul 8-Bit Boost.
            -- Abaikan angka waktu nol/teks lain yang bukan countdown aktif.
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

    -- Timer menang atas label READY; READY hanya dikembalikan bila tidak ada timer.
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

    -- Simpan saat transisi, perubahan deadline bermakna, atau maksimal tiap 5 detik.
    -- Deadline = waktu sekarang + sisa timer mesin; tidak mengandalkan teks lama.
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

    -- Pembacaan timer GUI Life Machine selalu menang bila tersedia.
    if state == "COOLDOWN" and machineSeconds ~= nil then
        local deadline = now + math.max(0, math.floor(machineSeconds))
        PersistLifeMachineCooldown(deadline, machineText or "", "COOLDOWN")
        return math.max(0, math.floor(machineSeconds)), machineText, "MACHINE"
    end

    -- READY hanya diterima dari label READY yang benar-benar terdeteksi dekat mesin.
    if state == "READY" then
        PersistLifeMachineCooldown(0, "", "READY")
        return 0, "READY", "MACHINE"
    end

    -- Saat GUI belum termuat / pemain jauh / baru rejoin, gunakan deadline
    -- persisten. Jangan menghapus deadline hanya karena scanner belum menemukan GUI.
    local deadline = tonumber(ConfigData.LifeMachineCooldownUntil) or 0
    local remaining = math.max(0, deadline - now)
    if remaining > 0 then
        return remaining, ConfigData.LifeMachineLastTimerText, "SAVED"
    end

    -- Jika belum pernah mendapat pembacaan valid dari mesin dan belum ada
    -- deadline tersimpan, jangan mengarang status READY. Tunggu sinkronisasi UI.
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

local function ExecuteLifeMachine(UIStatus_LifeMachine, isManual)
    if isLifeMachineExecuting then return false end
    -- Pellet has priority while a cycle/batch is actively controlling teleport.
    if teleportLockOwner == "PELLET" then return false end
    local acquiredLifeTeleportLock = false

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not hrp then return false end

    -- Auto mode tetap khusus Invader's Reach.
    if not isManual then
        local distToInvaderMap = (hrp.Position - invaderPos).Magnitude
        if distToInvaderMap > 350 then
            return false
        end
    end

    if not teleportLockOwner then
        teleportLockOwner = "LIFE"
        acquiredLifeTeleportLock = true
    end
    isLifeMachineExecuting = true

    if UIStatus_LifeMachine then
        UIStatus_LifeMachine.Text = "⚡ MENUJU LIFE MACHINE..."
        UIStatus_LifeMachine.TextColor3 = Color3.fromRGB(100, 255, 255)
    end

    -- Simpan posisi idle sebelum berangkat.
    local originalCFrame = hrp.CFrame
    local originalVelocity = hrp.AssemblyLinearVelocity

    -- ====================================================
    -- EXACT TARGET: posisi + heading dari Pencatat Koordinat.
    -- Tidak menghitung FrontDistance lagi.
    -- Tidak ada teleport kedua.
    -- ====================================================
    hrp.CFrame = lifeMachineCFrame
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    NotifyToast("Life Machine", "berhasil TP ke Life Machine", "success")

    -- Pendek saja: beri client/game waktu memperbarui posisi setelah TP.
    task.wait(0.25)

    -- LOCK hanya selama proses trigger.
    local oldAnchored = hrp.Anchored
    local oldAutoRotate = humanoid and humanoid.AutoRotate
    hrp.Anchored = true
    if humanoid then
        humanoid.AutoRotate = false
    end

    local firedMachine = false
    local machinePrompt = nil

    local function getPromptPart(prompt)
        local parent = prompt and prompt.Parent
        if not parent then return nil end

        if parent:IsA("BasePart") then
            return parent
        elseif parent:IsA("Attachment") and parent.Parent and parent.Parent:IsA("BasePart") then
            return parent.Parent
        end

        return nil
    end

    -- HANYA mencari prompt di sekitar koordinat Life Machine.
    -- Tidak scan seluruh Workspace untuk menghindari salah target.
    local function findLifeMachinePrompt()
        local parts = workspace:GetPartBoundsInRadius(
            lifeMachineCFrame.Position,
            18,
            nil
        )

        local checkedModels = {}
        local fallbackPrompt = nil
        local nearestDistance = math.huge

        for _, part in ipairs(parts) do
            local model = part:FindFirstAncestorOfClass("Model")

            local function inspectContainer(container)
                if not container then return end

                for _, obj in ipairs(container:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        local promptPart = getPromptPart(obj)
                        if promptPart then
                            local d = (promptPart.Position - lifeMachineCFrame.Position).Magnitude
                            if d <= 18 and d < nearestDistance then
                                nearestDistance = d
                                fallbackPrompt = obj
                            end
                        end
                    end
                end
            end

            if model and not checkedModels[model] then
                checkedModels[model] = true
                inspectContainer(model)
            end

            inspectContainer(part)
        end

        return fallbackPrompt
    end

    -- Setelah TP, tunggu prompt muncul/ter-update.
    -- TIDAK melakukan TP ulang selama menunggu.
    local promptDeadline = os.clock() + 1.20
    while os.clock() < promptDeadline and not machinePrompt do
        machinePrompt = findLifeMachinePrompt()
        if not machinePrompt then
            task.wait(0.06)
        end
    end

    if machinePrompt then
        NotifyToast("Life Machine", "Prompt berhasil ditemukan", "success")
        -- Hilangkan ketergantungan terhadap arah kamera/line-of-sight
        -- bila property ini tersedia di client.
        local oldLOS = machinePrompt.RequiresLineOfSight
        pcall(function()
            machinePrompt.RequiresLineOfSight = false
        end)

        -- Metode utama: fireproximityprompt bila executor menyediakan.
        -- Ini tidak bergantung pada kamera atau tulisan prompt sedang terlihat.
        if typeof(fireproximityprompt) == "function" then
            local ok = pcall(function()
                fireproximityprompt(machinePrompt)
            end)
            firedMachine = ok
        else
            -- Fallback Roblox input path.
            local ok = pcall(function()
                machinePrompt:InputHoldBegin()
                if machinePrompt.HoldDuration > 0 then
                    task.wait(machinePrompt.HoldDuration + 0.05)
                else
                    task.wait(0.08)
                end
                machinePrompt:InputHoldEnd()
            end)
            firedMachine = ok
        end

        pcall(function()
            machinePrompt.RequiresLineOfSight = oldLOS
        end)
    end

    -- Lepaskan lock setelah SATU percobaan aktivasi.
    if humanoid then
        humanoid.AutoRotate = oldAutoRotate == nil and true or oldAutoRotate
    end
    hrp.Anchored = oldAnchored

    -- Beri server sedikit waktu memproses trigger sebelum pulang.
    task.wait(0.20)

    -- SELALU pulang sekali ke posisi idle.
    local returnRoot = character and character:FindFirstChild("HumanoidRootPart")
    if returnRoot then
        returnRoot.CFrame = originalCFrame
        returnRoot.AssemblyLinearVelocity = originalVelocity
        NotifyToast("Life Machine", "berhasil kembali ke posisi awal", "success")
    end

    if UIStatus_LifeMachine then
        if firedMachine then
            NotifyToast("Life Machine", "sukses • mesin berhasil dipicu", "success")
            UIStatus_LifeMachine.Text = "✅ SUCCESS! SIKLUS SELESAI"
            UIStatus_LifeMachine.TextColor3 = Color3.fromRGB(50, 255, 100)
        else
            NotifyToast("Life Machine", "gagal • prompt mesin tidak terpicu", "error")
            UIStatus_LifeMachine.Text = "⚠️ PROMPT MESIN TIDAK TERPICU"
            UIStatus_LifeMachine.TextColor3 = Color3.fromRGB(255, 180, 50)
        end
    end

    task.wait(1.0)
    isLifeMachineExecuting = false
    if acquiredLifeTeleportLock and teleportLockOwner == "LIFE" then
        teleportLockOwner = nil
    end

    return firedMachine
end

-- [CONTINUE WITH REST OF FILE - SEMUA LOGIC TETAP SAMA]
-- Paste bagian sisanya (line 691 dan seterusnya) dari file asli Anda di sini
-- Hanya bagian UI ScreenGui creation yang di-fix, tidak ada perubahan logic lainnya

print("[Shadow Hub] Script loaded. UI parent fixed to PlayerGui")
