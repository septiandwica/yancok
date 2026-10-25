--[[
    ============================================================================
    🔥 YANCOK — STEAL AN EGG (100% FREE & KEYLESS STANDALONE)
    GitHub: https://github.com/septiandwica
    ============================================================================
    Fitur Utama:
      - 100% KEYLESS: Langsung jalan tanpa popup kode / linkvertise / checkpoint.
      - Core Egg Automation: Auto claim, steal, & hatch telur (holy engine).
      - Smart Auto Hop: Pindah server otomatis saat target tercapai / sepi.
      - Extreme FPS Boost: Hapus tekstur, shadow, & partikel agar enteng AFK.
      - Auto Chat Anti-Spam: Rotasi 3 pesan otomatis di chat Roblox.
      - Auto Accept Friends: Otomatis terima friend request untuk gifting telur.
      - Top-Down Camera Lock: Sudut pandang kamera stabil saat ditinggal AFK.
      - Persistent Teleport: Menggunakan queueonteleport ke server baru.
    ============================================================================
--]]

-- ========================== SINGLE INSTANCE GUARD ==========================
local SCRIPT_ID = "__YANCOK_STEAL_AN_EGG"
local RUN_ID = os.clock()
getgenv()[SCRIPT_ID] = RUN_ID

-- ============================ GITHUB URL CONFIG ============================
local GITHUB_USER = "septiandwica"
local GITHUB_REPO = "yancok"
local GITHUB_BRANCH = "main"

local BASE_URL = string.format("https://raw.githubusercontent.com/%s/%s/refs/heads/%s", GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH)
local MAIN_URL = BASE_URL .. "/main.lua"

-- ============================== ROBLOX SERVICES ============================
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local HttpService        = game:GetService("HttpService")
local TeleportService    = game:GetService("TeleportService")
local Lighting           = game:GetService("Lighting")
local Workspace          = game:GetService("Workspace")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local StarterGui         = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PLACE_ID    = game.PlaceId
local CURRENT_JOB = game.JobId

-- ============================ CONTAINER PROTEKSI ============================
local GuiParent = LocalPlayer:WaitForChild("PlayerGui")
pcall(function()
    if gethui then
        GuiParent = gethui()
    elseif game:GetService("CoreGui") then
        GuiParent = game:GetService("CoreGui")
    end
end)

-- Bersihkan GUI lama jika ada
do
    local roots = { GuiParent, LocalPlayer:FindFirstChildOfClass("PlayerGui") }
    pcall(function() roots[#roots + 1] = game:GetService("CoreGui") end)
    local cleaned = {}
    for _, root in ipairs(roots) do
        if root and not cleaned[root] then
            cleaned[root] = true
            for _, child in ipairs(root:GetChildren()) do
                if child.Name == "YancokEgg_UI" then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

-- ============================== TEMA & WARNA ===============================
local Theme = {
    Background = Color3.fromRGB(16, 18, 22),
    Header     = Color3.fromRGB(22, 26, 32),
    Card       = Color3.fromRGB(26, 30, 38),
    Border     = Color3.fromRGB(42, 48, 60),
    Accent     = Color3.fromRGB(255, 180, 50),     -- Egg Golden Yellow
    AccentDim  = Color3.fromRGB(150, 95, 20),
    Green      = Color3.fromRGB(50, 205, 120),
    Danger     = Color3.fromRGB(240, 75, 75),
    Text       = Color3.fromRGB(245, 245, 250),
    TextSub    = Color3.fromRGB(145, 155, 170),
}

local FONT_BOLD = Enum.Font.GothamBold
local FONT_MED  = Enum.Font.GothamMedium
local FONT_REG  = Enum.Font.Gotham

-- ============================ KONFIGURASI LOKAL ============================
local CFG_FOLDER = "Yancok_StealAnEgg"
local CFG_PATH   = CFG_FOLDER .. "/config.json"

local Settings = {
    autoSteal       = true,               -- Auto farm & ambil telur di map
    stealDelay      = 0.18,               -- Kecepatan delay antar klaim telur (detik)
    autoHatch       = true,               -- Auto tetaskan telur

    autoHop         = true,
    hopMode         = "Any",              -- "Interval" | "After Steals" | "No Match" | "Any"
    hopInterval     = 12,                 -- menit
    hopSteals       = 40,                 -- klaim telur
    hopNoMatchDelay = 60,                 -- detik tanpa klaim telur
    hopMinPlayers   = 3,
    hopMaxPlayers   = 6,
    hopPreferEmpty  = true,

    autoChat        = false,
    chatInterval    = 25,
    chatText1       = "Yancok Steal An Egg - 100% Keyless!",
    chatText2       = "Farming Eggs AFK",
    chatText3       = "",

    fpsBoost        = true,               -- default aktif agar sangat hemat resource
    autoAccept      = true,
    camLock         = false,
    camOffX         = 0,
    camOffY         = 35,
    camOffZ         = 0,
    camFov          = 70,
}

local function saveConfig()
    pcall(function()
        if type(makefolder) == "function" then pcall(makefolder, CFG_FOLDER) end
        if type(writefile) == "function" then
            writefile(CFG_PATH, HttpService:JSONEncode(Settings))
        end
    end)
end

local function loadConfig()
    pcall(function()
        if type(readfile) == "function" and isfile and isfile(CFG_PATH) then
            local data = readfile(CFG_PATH)
            local tbl = HttpService:JSONDecode(data)
            if type(tbl) == "table" then
                for k, v in pairs(tbl) do Settings[k] = v end
            end
        end
    end)
end
loadConfig()

-- ============================ CLAIM / STEAL TRACKER ========================
local totalClaims = 0
local lastClaimTime = os.clock()
local hopBaseClaims = 0

local function registerClaim()
    totalClaims = totalClaims + 1
    lastClaimTime = os.clock()
end

-- Deteksi remote event klaim telur (Tahan update game)
do
    local function hookRemote(ev)
        if ev and ev:IsA("RemoteEvent") then
            ev.OnClientEvent:Connect(function(res)
                if res == nil or res == true or (type(res) == "table" and res.Ok ~= false) then
                    registerClaim()
                end
            end)
        end
    end

    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Networking")
        if net then
            for _, c in ipairs(net:GetChildren()) do
                local n = string.lower(c.Name)
                if string.find(n, "egg") or string.find(n, "redeem") or string.find(n, "verdict") or string.find(n, "claim") then
                    hookRemote(c)
                end
            end
        end
    end)

    -- Fallback scan seluruh ReplicatedStorage
    pcall(function()
        for _, c in ipairs(ReplicatedStorage:GetDescendants()) do
            local n = string.lower(c.Name)
            if c:IsA("RemoteEvent") and (string.find(n, "fieldeggredeem") or string.find(n, "eggclaim") or string.find(n, "eggworld")) then
                hookRemote(c)
            end
        end
    end)

    -- Cadangan: polling telur milik pemain
    task.spawn(function()
        local ES
        pcall(function() ES = require(ReplicatedStorage.Client.EggState) end)
        if ES and type(ES.ReadOwnedEggs) == "function" then
            local function countEggs()
                local count = 0
                pcall(function()
                    for _, egg in pairs(ES.ReadOwnedEggs() or {}) do
                        if type(egg) == "table" and egg.OwnerUserId == LocalPlayer.UserId and type(egg.Records) == "table" then
                            for _ in pairs(egg.Records) do count = count + 1 end
                        end
                    end
                end)
                return count
            end
            local prev = countEggs()
            while getgenv()[SCRIPT_ID] == RUN_ID do
                task.wait(2)
                local cur = countEggs()
                if cur > prev then
                    for _ = 1, (cur - prev) do registerClaim() end
                end
                prev = cur
            end
        end
    end)
end

-- ==================== NATIVE STEAL & EGG ENGINE (100% CLEAN) ===================
-- 100% Native Luau: Tanpa holy.lua, tanpa key, dan bebas dari dependensi nrlscript
local function getHrp()
    local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return chr and chr:FindFirstChild("HumanoidRootPart")
end

local function findEggTargets()
    local targets = {}
    local seen = {}

    local function addTarget(obj)
        if obj and not seen[obj] then
            seen[obj] = true
            targets[#targets + 1] = obj
        end
    end

    -- 1. Wadah umum telur di game Steal An Egg
    local containers = {
        Workspace:FindFirstChild("Eggs"),
        Workspace:FindFirstChild("FieldEggs"),
        Workspace:FindFirstChild("SpawnedEggs"),
        Workspace:FindFirstChild("EggsFolder"),
        Workspace:FindFirstChild("Nests"),
        Workspace:FindFirstChild("Debris"),
        Workspace:FindFirstChild("Map"),
    }
    for _, folder in ipairs(containers) do
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                if item:IsA("Model") or item:IsA("BasePart") then
                    addTarget(item)
                end
            end
        end
    end

    -- 2. Scan umum di Workspace jika wadah spesifik belum ditemukan
    if #targets == 0 then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local name = string.lower(obj.Name)
                if string.find(name, "egg") or obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
                    if not (LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character)) then
                        addTarget(obj)
                    end
                end
            end
        end
    end

    return targets
end

local function stealEgg(eggObj)
    if not (eggObj and eggObj.Parent) then return false end
    local hrp = getHrp()
    if not hrp then return false end

    local targetPart = eggObj:IsA("BasePart") and eggObj or eggObj:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart then return false end

    local success = false
    pcall(function()
        -- Teleport karakter langsung ke posisi telur
        hrp.CFrame = targetPart.CFrame + Vector3.new(0, 2.5, 0)
        task.wait(0.06)

        -- 1. Trigger ProximityPrompt (E)
        local prompt = eggObj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            if type(fireproximityprompt) == "function" then
                fireproximityprompt(prompt, 0)
                fireproximityprompt(prompt)
                success = true
            end
        end

        -- 2. Trigger TouchInterest fisik
        if targetPart:FindFirstChild("TouchInterest") or eggObj:FindFirstChildWhichIsA("TouchTransmitter", true) then
            if type(firetouchinterest) == "function" then
                firetouchinterest(hrp, targetPart, 0)
                task.wait(0.02)
                firetouchinterest(hrp, targetPart, 1)
                success = true
            end
        end

        -- 3. Trigger RemoteEvent jika ada di Packages.Networking / ReplicatedStorage
        local net = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Networking")
        if net then
            for _, r in ipairs(net:GetChildren()) do
                if r:IsA("RemoteEvent") then
                    local rn = string.lower(r.Name)
                    if string.find(rn, "redeem") or string.find(rn, "claim") or string.find(rn, "fieldegg") or string.find(rn, "steal") then
                        r:FireServer(eggObj)
                        r:FireServer(targetPart)
                        r:FireServer(eggObj.Name)
                        success = true
                    end
                end
            end
        end
    end)
    return success
end

-- Loop Auto Steal Telur
task.spawn(function()
    while getgenv()[SCRIPT_ID] == RUN_ID do
        if Settings.autoSteal then
            local eggs = findEggTargets()
            for _, egg in ipairs(eggs) do
                if not Settings.autoSteal or getgenv()[SCRIPT_ID] ~= RUN_ID then break end
                if egg and egg.Parent then
                    stealEgg(egg)
                    task.wait(Settings.stealDelay or 0.18)
                end
            end
        end
        task.wait(0.5)
    end
end)

-- Loop Auto Hatch Telur
task.spawn(function()
    while getgenv()[SCRIPT_ID] == RUN_ID do
        if Settings.autoHatch then
            pcall(function()
                local net = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Networking")
                if net then
                    for _, r in ipairs(net:GetChildren()) do
                        if r:IsA("RemoteEvent") then
                            local rn = string.lower(r.Name)
                            if string.find(rn, "hatch") or string.find(rn, "openegg") then
                                r:FireServer(1)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)

-- ============================ FPS BOOSTER ENGINE ===========================
local boostWatcher = nil
local function stripObject(v)
    pcall(function()
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
            if v:IsA("MeshPart") then v.TextureID = "" end
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("SurfaceAppearance") then
            v:Destroy()
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        elseif v:IsA("PostEffect") then
            v.Enabled = false
        end
    end)
end

local function applyFpsBoost()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Technology = Enum.Technology.Compatibility
        local terr = Workspace:FindFirstChildOfClass("Terrain")
        if terr then
            terr.WaterWaveSize = 0
            terr.WaterWaveSpeed = 0
            terr.WaterReflectance = 0
            terr.WaterTransparency = 1
            terr.Decoration = false
        end
    end)

    for _, v in ipairs(Workspace:GetDescendants()) do
        if not (LocalPlayer.Character and v:IsDescendantOf(LocalPlayer.Character)) then
            stripObject(v)
        end
    end

    if not boostWatcher then
        boostWatcher = Workspace.DescendantAdded:Connect(function(v)
            if Settings.fpsBoost then
                task.wait()
                stripObject(v)
            end
        end)
    end
end

if Settings.fpsBoost then
    task.spawn(applyFpsBoost)
end

-- ============================ SERVER HOP ENGINE ============================
local hopping = false

local function fetchServerList()
    local endpoints = {
        ("https://games.roproxy.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PLACE_ID),
        ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PLACE_ID),
        ("https://games.roproxy.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100"):format(PLACE_ID),
    }
    for _, url in ipairs(endpoints) do
        local body = nil
        pcall(function()
            local fn = request or http_request or (http and http.request)
            if fn then
                local res = fn({ Url = url, Method = "GET" })
                if res and res.Body and #res.Body > 0 then body = res.Body end
            end
        end)
        if not body then
            pcall(function() body = game:HttpGet(url) end)
        end
        if body and #body > 0 then
            local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
            if ok and type(data) == "table" and type(data.data) == "table" and #data.data > 0 then
                return data.data
            end
        end
        task.wait(0.2)
    end
    return nil
end

local function doServerHop()
    if hopping then return false end
    hopping = true

    -- Auto-execute persistence di server baru
    if type(queueonteleport) == "function" then
        pcall(queueonteleport, string.format([[
            task.spawn(function()
                pcall(function() if not game:IsLoaded() then game.Loaded:Wait() end end)
                task.wait(2)
                loadstring(game:HttpGet(%q))()
            end)
        ]], MAIN_URL))
    end

    local serverList = fetchServerList()
    local targetServerId = nil

    if serverList and #serverList > 0 then
        local candidates = {}
        -- Filter tahap 1: Sesuai filter pemain yang ditentukan
        for _, s in ipairs(serverList) do
            if s.id and s.id ~= CURRENT_JOB and type(s.playing) == "number" and s.playing < (s.maxPlayers or 999) then
                if s.playing >= (Settings.hopMinPlayers or 1) and (Settings.hopMaxPlayers <= 0 or s.playing <= Settings.hopMaxPlayers) then
                    candidates[#candidates + 1] = s
                end
            end
        end

        -- Filter tahap 2 (Relaxation): Jika filter terlalu sempit, ambil server mana pun yang ada slot
        if #candidates == 0 then
            for _, s in ipairs(serverList) do
                if s.id and s.id ~= CURRENT_JOB and type(s.playing) == "number" and s.playing < (s.maxPlayers or 999) then
                    candidates[#candidates + 1] = s
                end
            end
        end

        if #candidates > 0 then
            if Settings.hopPreferEmpty then
                table.sort(candidates, function(a, b) return a.playing < b.playing end)
                local minPlayers = candidates[1].playing
                local tier = {}
                for _, s in ipairs(candidates) do
                    if s.playing <= minPlayers + 2 then tier[#tier + 1] = s end
                end
                targetServerId = tier[math.random(#tier)].id
            else
                targetServerId = candidates[math.random(#candidates)].id
            end
        end
    end

    -- Listener jika instance teleportasi gagal
    local failConn = nil
    failConn = TeleportService.TeleportInitFailed:Connect(function(plr, result, msg)
        if plr == LocalPlayer then
            print("[Yancok AutoHop] Gagal ke instance spesifik, mencoba matchmaking acak...")
            if failConn then pcall(function() failConn:Disconnect() end) end
            task.wait(1)
            pcall(function() TeleportService:Teleport(PLACE_ID, LocalPlayer) end)
        end
    end)

    -- Safety timeout (15 detik)
    task.delay(15, function()
        if hopping then
            hopping = false
            if failConn then pcall(function() failConn:Disconnect() end) end
        end
    end)

    if targetServerId then
        print("[Yancok AutoHop] Berpindah ke server: " .. tostring(targetServerId))
        pcall(function() TeleportService:TeleportToPlaceInstance(PLACE_ID, targetServerId, LocalPlayer) end)
    else
        print("[Yancok AutoHop] Menggunakan native Teleport matchmaking...")
        pcall(function() TeleportService:Teleport(PLACE_ID, LocalPlayer) end)
    end
    return true
end

-- Loop pengecekan kondisi auto-hop
task.spawn(function()
    local startTime = os.clock()
    hopBaseClaims = totalClaims
    while getgenv()[SCRIPT_ID] == RUN_ID do
        task.wait(3)
        if Settings.autoHop and not hopping then
            local elapsedSec = os.clock() - startTime
            local claimsGained = totalClaims - hopBaseClaims
            local noMatchSec = os.clock() - lastClaimTime

            local ready = false
            if Settings.hopMode == "Interval" then
                ready = (elapsedSec >= Settings.hopInterval * 60)
            elseif Settings.hopMode == "After Steals" then
                ready = (claimsGained >= Settings.hopSteals)
            elseif Settings.hopMode == "No Match" then
                ready = (noMatchSec >= Settings.hopNoMatchDelay)
            else -- Any
                ready = (elapsedSec >= Settings.hopInterval * 60)
                     or (claimsGained >= Settings.hopSteals)
                     or (noMatchSec >= Settings.hopNoMatchDelay)
            end

            if ready then
                doServerHop()
                startTime = os.clock()
                hopBaseClaims = totalClaims
            end
        end
    end
end)

-- =========================== AUTO CHAT & AUTO ACCEPT ========================
-- Auto Accept Friends
do
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Networking")
        if net then
            for _, c in ipairs(net:GetChildren()) do
                if c:IsA("RemoteEvent") and string.find(string.lower(c.Name), "friend") then
                    c.OnClientEvent:Connect(function(plr)
                        if Settings.autoAccept and typeof(plr) == "Instance" and plr:IsA("Player") then
                            pcall(function() StarterGui:SetCore("PromptSendFriendRequest", plr) end)
                        end
                    end)
                end
            end
        end
    end)
end

-- Auto Chat Loop
task.spawn(function()
    local lastChat = 0
    local msgIndex = 0
    while getgenv()[SCRIPT_ID] == RUN_ID do
        task.wait(1)
        if Settings.autoChat and (os.clock() - lastChat) >= math.max(10, Settings.chatInterval) then
            local msgs = {}
            for _, m in ipairs({ Settings.chatText1, Settings.chatText2, Settings.chatText3 }) do
                if type(m) == "string" and #m > 0 then msgs[#msgs + 1] = m end
            end
            if #msgs > 0 then
                lastChat = os.clock()
                msgIndex = (msgIndex % #msgs) + 1
                local text = msgs[msgIndex]
                pcall(function()
                    local tcs = game:GetService("TextChatService")
                    local ch = tcs.TextChannels and tcs.TextChannels:FindFirstChild("RBXGeneral")
                    if ch and ch.SendAsync then
                        ch:SendAsync(text)
                    else
                        Players:Chat(text)
                    end
                end)
            end
        end
    end
end)

-- ============================ CAMERA LOCK POV ===============================
local cam = Workspace.CurrentCamera
RunService.RenderStepped:Connect(function()
    if Settings.camLock and cam and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            cam.CameraType = Enum.CameraType.Custom
            cam.FieldOfView = Settings.camFov or 70
            cam.CFrame = CFrame.new(root.Position + Vector3.new(Settings.camOffX, Settings.camOffY, Settings.camOffZ), root.Position)
        end
    end
end)

-- ================================= GUI PANEL ================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YancokEgg_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = GuiParent

local function addCorner(r, p)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
    return c
end

local function addStroke(col, th, p)
    local s = Instance.new("UIStroke")
    s.Color = col or Theme.Border
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

-- Panel Pos Keeper (Pojok Kanan Bawah)
local Window = Instance.new("Frame")
Window.Name = "Window"
Window.AnchorPoint = Vector2.new(1, 1)
Window.Position = UDim2.new(1, -12, 1, -12)
Window.Size = UDim2.new(0, 320, 0, 360)
Window.BackgroundColor3 = Theme.Background
Window.BorderSizePixel = 0
Window.Active = true
Window.ClipsDescendants = true
Window.Parent = ScreenGui
addCorner(8, Window)
addStroke(Theme.Border, 1.5, Window)

-- Draggable
do
    local dragging, dragStart, startPos = false, nil, nil
    Window.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mPos = UserInputService:GetMouseLocation()
            if mPos.Y - Window.AbsolutePosition.Y <= 38 then
                dragging = true
                dragStart = input.Position
                startPos = Window.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Window.AnchorPoint = Vector2.new(0, 0)
            Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Theme.Header
Header.BorderSizePixel = 0
Header.Parent = Window
addCorner(8, Header)

local Title = Instance.new("TextLabel")
Title.Text = "🔥 YANCOK — STEAL AN EGG"
Title.Font = FONT_BOLD
Title.TextSize = 13
Title.TextColor3 = Theme.Accent
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.Font = FONT_BOLD
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Theme.TextSub
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -30, 0, 6)
CloseBtn.BackgroundColor3 = Theme.Card
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header
addCorner(4, CloseBtn)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Main Scroll Body
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -48)
Scroll.Position = UDim2.new(0, 8, 0, 42)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Theme.Accent
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Window

local List = Instance.new("UIListLayout")
List.Padding = UDim.new(0, 6)
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Parent = Scroll

-- Claim Counter Card
local ClaimCard = Instance.new("Frame")
ClaimCard.Size = UDim2.new(1, 0, 0, 48)
ClaimCard.BackgroundColor3 = Theme.Card
ClaimCard.BorderSizePixel = 0
ClaimCard.Parent = Scroll
addCorner(6, ClaimCard)

local ClaimLabel = Instance.new("TextLabel")
ClaimLabel.Text = "Telur Terklaim: 0"
ClaimLabel.Font = FONT_BOLD
ClaimLabel.TextSize = 13
ClaimLabel.TextColor3 = Theme.Green
ClaimLabel.Position = UDim2.new(0, 10, 0, 6)
ClaimLabel.Size = UDim2.new(1, -20, 0, 18)
ClaimLabel.TextXAlignment = Enum.TextXAlignment.Left
ClaimLabel.BackgroundTransparency = 1
ClaimLabel.Parent = ClaimCard

local RateLabel = Instance.new("TextLabel")
RateLabel.Text = "Status: 100% Keyless | GitHub: @" .. GITHUB_USER
RateLabel.Font = FONT_REG
RateLabel.TextSize = 10
RateLabel.TextColor3 = Theme.TextSub
RateLabel.Position = UDim2.new(0, 10, 0, 26)
RateLabel.Size = UDim2.new(1, -20, 0, 16)
RateLabel.TextXAlignment = Enum.TextXAlignment.Left
RateLabel.BackgroundTransparency = 1
RateLabel.Parent = ClaimCard

task.spawn(function()
    while getgenv()[SCRIPT_ID] == RUN_ID do
        task.wait(1)
        ClaimLabel.Text = "Telur Terklaim: " .. tostring(totalClaims)
    end
end)

-- Helper untuk Card Toggle
local function createToggle(title, desc, initialVal, onToggle)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 50)
    card.BackgroundColor3 = Theme.Card
    card.BorderSizePixel = 0
    card.Parent = Scroll
    addCorner(6, card)

    local l1 = Instance.new("TextLabel")
    l1.Text = title
    l1.Font = FONT_BOLD
    l1.TextSize = 11
    l1.TextColor3 = Theme.Text
    l1.Position = UDim2.new(0, 10, 0, 8)
    l1.Size = UDim2.new(1, -85, 0, 16)
    l1.TextXAlignment = Enum.TextXAlignment.Left
    l1.BackgroundTransparency = 1
    l1.Parent = card

    local l2 = Instance.new("TextLabel")
    l2.Text = desc
    l2.Font = FONT_REG
    l2.TextSize = 9
    l2.TextColor3 = Theme.TextSub
    l2.Position = UDim2.new(0, 10, 0, 26)
    l2.Size = UDim2.new(1, -85, 0, 16)
    l2.TextXAlignment = Enum.TextXAlignment.Left
    l2.BackgroundTransparency = 1
    l2.Parent = card

    local btn = Instance.new("TextButton")
    btn.Text = initialVal and "ON" or "OFF"
    btn.Font = FONT_BOLD
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = initialVal and Theme.Green or Theme.Danger
    btn.Size = UDim2.new(0, 60, 0, 26)
    btn.Position = UDim2.new(1, -70, 0.5, -13)
    btn.BorderSizePixel = 0
    btn.Parent = card
    addCorner(5, btn)

    local state = initialVal
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Theme.Green or Theme.Danger
        onToggle(state)
        saveConfig()
    end)
    return card
end

-- Toggles
createToggle("Auto Steal / Farm Telur", "Ambil & klaim semua telur di map otomatis", Settings.autoSteal, function(val)
    Settings.autoSteal = val
end)

createToggle("Auto Hatch Telur", "Tetaskan telur otomatis untuk pet baru", Settings.autoHatch, function(val)
    Settings.autoHatch = val
end)

createToggle("Auto Server Hop", "Pindah server saat target tercapai / sepi", Settings.autoHop, function(val)
    Settings.autoHop = val
end)

createToggle("Extreme FPS Booster", "Hapus texture/particle agar hemat RAM & GPU", Settings.fpsBoost, function(val)
    Settings.fpsBoost = val
    if val then applyFpsBoost() end
end)

createToggle("Auto Accept Friends", "Terima friend request untuk gift telur", Settings.autoAccept, function(val)
    Settings.autoAccept = val
end)

createToggle("Auto Chat Broadcast", "Kirim pesan berkala di chat server", Settings.autoChat, function(val)
    Settings.autoChat = val
end)

createToggle("Camera Lock (Top-Down)", "Kunci POV atas karakter saat AFK", Settings.camLock, function(val)
    Settings.camLock = val
end)

-- Button Manual Hop
local HopNowCard = Instance.new("Frame")
HopNowCard.Size = UDim2.new(1, 0, 0, 42)
HopNowCard.BackgroundColor3 = Theme.Card
HopNowCard.BorderSizePixel = 0
HopNowCard.Parent = Scroll
addCorner(6, HopNowCard)

local HopBtn = Instance.new("TextButton")
HopBtn.Text = "🚀 PINDAH SERVER SEKARANG"
HopBtn.Font = FONT_BOLD
HopBtn.TextSize = 11
HopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HopBtn.BackgroundColor3 = Theme.AccentDim
HopBtn.Size = UDim2.new(1, -16, 0, 28)
HopBtn.Position = UDim2.new(0, 8, 0, 7)
HopBtn.BorderSizePixel = 0
HopBtn.Parent = HopNowCard
addCorner(5, HopBtn)

HopBtn.MouseButton1Click:Connect(function()
    HopBtn.Text = "Mencari server..."
    task.spawn(function()
        local ok = doServerHop()
        if not ok then
            HopBtn.Text = "Gagal (Coba Lagi)"
            task.wait(2)
            HopBtn.Text = "🚀 PINDAH SERVER SEKARANG"
        end
    end)
end)

-- Toggle Shortcut Keyboard
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift and ScreenGui.Parent then
        Window.Visible = not Window.Visible
    end
end)

print("[Yancok] Steal An Egg standalone siap! Tekan [RightShift] untuk sembunyikan UI.")
