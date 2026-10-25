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
local lastFetchTime, cachedServers = 0, nil

local function fetchServerList()
    local now = os.clock()
    if cachedServers and (now - lastFetchTime) < 15 and #cachedServers > 0 then
        return cachedServers
    end

    local list = {}
    local function getBody(url)
        local body = nil
        pcall(function()
            local fn = request or http_request or (http and http.request) or (syn and syn.request)
            if fn then
                local res = fn({ Url = url, Method = "GET" })
                body = res and (res.Body or res.body)
            end
        end)
        if not (body and #body > 0) then
            pcall(function() body = game:HttpGet(url) end)
        end
        return body
    end

    local endpoints = {
        ("https://games.roproxy.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PLACE_ID),
        ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PLACE_ID),
    }

    for _, url in ipairs(endpoints) do
        local body = getBody(url)
        if body and type(body) == "string" and #body > 0 then
            local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
            if ok and type(data) == "table" and type(data.data) == "table" and #data.data > 0 then
                for _, s in ipairs(data.data) do
                    if s.id and s.id ~= CURRENT_JOB and type(s.playing) == "number" and s.playing < (s.maxPlayers or 999) then
                        list[#list + 1] = s
                    end
                end
                if #list > 0 then break end
            end
        end
    end

    lastFetchTime = now
    cachedServers = list
    return list
end

local function doServerHop(statusCallback)
    if hopping then return false end
    hopping = true

    if type(statusCallback) == "function" then statusCallback("Mencari server...") end

    -- Re-inject diri sendiri di server baru via queueonteleport
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
    local candidates = {}

    if serverList and #serverList > 0 then
        -- Filter sesuai preferensi min/max player
        for _, s in ipairs(serverList) do
            local minOk = (Settings.hopMinPlayers or 0) <= 0 or s.playing >= Settings.hopMinPlayers
            local maxOk = (Settings.hopMaxPlayers or 0) <= 0 or s.playing <= Settings.hopMaxPlayers
            if minOk and maxOk then
                candidates[#candidates + 1] = s
            end
        end

        -- Relaksasi filter jika tidak ada server yang memenuhi
        if #candidates == 0 then
            for _, s in ipairs(serverList) do
                candidates[#candidates + 1] = s
            end
        end

        -- Urutkan server sepi jika hopPreferEmpty aktif
        if Settings.hopPreferEmpty then
            table.sort(candidates, function(a, b) return a.playing < b.playing end)
            local minP = candidates[1].playing
            local tier = {}
            for _, s in ipairs(candidates) do
                if s.playing <= minP + 2 then tier[#tier + 1] = s end
            end
            candidates = tier
        end

        -- Acak kandidat
        for i = #candidates, 2, -1 do
            local j = math.random(i)
            candidates[i], candidates[j] = candidates[j], candidates[i]
        end
    end

    local candidateIdx = 0
    local failConn = nil

    local function tryNextServer()
        candidateIdx = candidateIdx + 1
        local target = candidates[candidateIdx]

        if not target then
            -- Habis semua kandidat: coba Teleport default roblox
            if failConn then pcall(function() failConn:Disconnect() end) end
            if type(statusCallback) == "function" then statusCallback("Matchmaking acak...") end
            print("[Yancok AutoHop] Mencoba Teleport native...")
            local ok = pcall(function() TeleportService:Teleport(PLACE_ID, LocalPlayer) end)
            if not ok then
                hopping = false
                cachedServers = nil
                if type(statusCallback) == "function" then statusCallback("Gagal, coba lagi") end
            end
            return
        end

        local msg = ("Server #%d (%d plr)..."):format(candidateIdx, target.playing)
        if type(statusCallback) == "function" then statusCallback(msg) end
        print("[Yancok AutoHop] " .. msg .. " [ID: " .. tostring(target.id) .. "]")

        pcall(function()
            TeleportService:TeleportToPlaceInstance(PLACE_ID, target.id, LocalPlayer)
        end)
    end

    failConn = TeleportService.TeleportInitFailed:Connect(function(plr, result, errMsg)
        if plr == LocalPlayer then
            print("[Yancok AutoHop] Server gagal/penuh, mencoba server berikutnya...")
            task.wait(0.5)
            tryNextServer()
        end
    end)

    -- Safety timeout guard: lepas status hopping jika macet
    task.delay(20, function()
        if hopping then
            hopping = false
            cachedServers = nil
            if failConn then pcall(function() failConn:Disconnect() end) end
            if type(statusCallback) == "function" then statusCallback("Timeout, coba lagi") end
            print("[Yancok AutoHop] Timeout hop dilepas.")
        end
    end)

    tryNextServer()
    return true
end

-- Loop pengecekan kondisi auto-hop
task.spawn(function()
    local startTime = os.clock()
    hopBaseClaims = totalClaims
    while getgenv()[SCRIPT_ID] == RUN_ID do
        task.wait(4)
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
                -- Jangan hop di No Match jika pemain baru join atau belum pernah claim
                ready = (claimsGained > 0 or elapsedSec > 90) and (noMatchSec >= Settings.hopNoMatchDelay)
            else -- Any
                ready = (elapsedSec >= Settings.hopInterval * 60)
                     or (claimsGained >= Settings.hopSteals)
                     or ((claimsGained > 0 or elapsedSec > 90) and noMatchSec >= Settings.hopNoMatchDelay)
            end

            if ready then
                local started = doServerHop()
                if started then
                    startTime = os.clock()
                    hopBaseClaims = totalClaims
                end
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

-- =========================== MINI BAR (FLOATING BADGE) =======================
local MiniBar = Instance.new("Frame")
MiniBar.Name = "MiniBar"
MiniBar.AnchorPoint = Vector2.new(1, 1)
MiniBar.Position = UDim2.new(1, -12, 1, -12)
MiniBar.Size = UDim2.new(0, 155, 0, 26)
MiniBar.BackgroundColor3 = Theme.Background
MiniBar.BorderSizePixel = 0
MiniBar.Active = true
MiniBar.Visible = false
MiniBar.Parent = ScreenGui
addCorner(6, MiniBar)
addStroke(Theme.Accent, 1, MiniBar)

local MiniLabel = Instance.new("TextLabel")
MiniLabel.Text = "🔥 Yancok: 0 Telur ⚡"
MiniLabel.Font = FONT_BOLD
MiniLabel.TextSize = 10
MiniLabel.TextColor3 = Theme.Accent
MiniLabel.Size = UDim2.new(1, 0, 1, 0)
MiniLabel.BackgroundTransparency = 1
MiniLabel.Parent = MiniBar

local MiniBtn = Instance.new("TextButton")
MiniBtn.Size = UDim2.new(1, 0, 1, 0)
MiniBtn.BackgroundTransparency = 1
MiniBtn.Text = ""
MiniBtn.Parent = MiniBar

-- =========================== MAIN WINDOW (COMPACT) ==========================
local Window = Instance.new("Frame")
Window.Name = "Window"
Window.AnchorPoint = Vector2.new(1, 1)
Window.Position = UDim2.new(1, -12, 1, -12)
Window.Size = UDim2.new(0, 210, 0, 225)
Window.BackgroundColor3 = Theme.Background
Window.BorderSizePixel = 0
Window.Active = true
Window.ClipsDescendants = true
Window.Parent = ScreenGui
addCorner(8, Window)
addStroke(Theme.Border, 1.2, Window)

-- Minimize / Restore handler
local function setMinimized(mini)
    Window.Visible = not mini
    MiniBar.Visible = mini
end

MiniBtn.MouseButton1Click:Connect(function()
    setMinimized(false)
end)

-- Draggable handler
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.AnchorPoint = Vector2.new(0, 0)
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(MiniBar, MiniBar)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 26)
Header.BackgroundColor3 = Theme.Header
Header.BorderSizePixel = 0
Header.Parent = Window
addCorner(8, Header)
makeDraggable(Window, Header)

local Title = Instance.new("TextLabel")
Title.Text = "🔥 YANCOK (Keyless)"
Title.Font = FONT_BOLD
Title.TextSize = 10
Title.TextColor3 = Theme.Accent
Title.Position = UDim2.new(0, 8, 0, 0)
Title.Size = UDim2.new(1, -52, 1, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = Header

local MinBtn = Instance.new("TextButton")
MinBtn.Text = "—"
MinBtn.Font = FONT_BOLD
MinBtn.TextSize = 11
MinBtn.TextColor3 = Theme.TextSub
MinBtn.Size = UDim2.new(0, 20, 0, 20)
MinBtn.Position = UDim2.new(1, -44, 0, 3)
MinBtn.BackgroundColor3 = Theme.Card
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Header
addCorner(4, MinBtn)
MinBtn.MouseButton1Click:Connect(function()
    setMinimized(true)
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.Font = FONT_BOLD
CloseBtn.TextSize = 10
CloseBtn.TextColor3 = Theme.TextSub
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -22, 0, 3)
CloseBtn.BackgroundColor3 = Theme.Card
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header
addCorner(4, CloseBtn)
CloseBtn.MouseButton1Click:Connect(function()
    setMinimized(true)
end)

-- Main Scroll Body
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -10, 1, -32)
Scroll.Position = UDim2.new(0, 5, 0, 29)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Theme.Accent
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Window

local List = Instance.new("UIListLayout")
List.Padding = UDim.new(0, 4)
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Parent = Scroll

-- Counter Card
local ClaimCard = Instance.new("Frame")
ClaimCard.Size = UDim2.new(1, 0, 0, 24)
ClaimCard.BackgroundColor3 = Theme.Card
ClaimCard.BorderSizePixel = 0
ClaimCard.Parent = Scroll
addCorner(5, ClaimCard)

local ClaimLabel = Instance.new("TextLabel")
ClaimLabel.Text = "Telur: 0  |  AFK Aktif"
ClaimLabel.Font = FONT_BOLD
ClaimLabel.TextSize = 10
ClaimLabel.TextColor3 = Theme.Green
ClaimLabel.Size = UDim2.new(1, -10, 1, 0)
ClaimLabel.Position = UDim2.new(0, 8, 0, 0)
ClaimLabel.TextXAlignment = Enum.TextXAlignment.Left
ClaimLabel.BackgroundTransparency = 1
ClaimLabel.Parent = ClaimCard

task.spawn(function()
    while getgenv()[SCRIPT_ID] == RUN_ID do
        task.wait(1)
        ClaimLabel.Text = "Telur: " .. tostring(totalClaims) .. "  |  AFK Aktif"
        MiniLabel.Text = "🔥 Yancok: " .. tostring(totalClaims) .. " ⚡"
    end
end)

-- Helper Toggle Compact
local function createToggle(title, initialVal, onToggle)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 26)
    card.BackgroundColor3 = Theme.Card
    card.BorderSizePixel = 0
    card.Parent = Scroll
    addCorner(5, card)

    local lbl = Instance.new("TextLabel")
    lbl.Text = title
    lbl.Font = FONT_BOLD
    lbl.TextSize = 9.5
    lbl.TextColor3 = Theme.Text
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    lbl.Parent = card

    local btn = Instance.new("TextButton")
    btn.Text = initialVal and "ON" or "OFF"
    btn.Font = FONT_BOLD
    btn.TextSize = 9
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = initialVal and Theme.Green or Theme.Danger
    btn.Size = UDim2.new(0, 36, 0, 18)
    btn.Position = UDim2.new(1, -42, 0.5, -9)
    btn.BorderSizePixel = 0
    btn.Parent = card
    addCorner(4, btn)

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

-- Toggles (Ringkas & Efisien)
createToggle("Auto Steal Telur", Settings.autoSteal, function(val)
    Settings.autoSteal = val
end)

createToggle("Auto Hatch Telur", Settings.autoHatch, function(val)
    Settings.autoHatch = val
end)

createToggle("Smart Auto Hop", Settings.autoHop, function(val)
    Settings.autoHop = val
end)

createToggle("Extreme FPS Boost", Settings.fpsBoost, function(val)
    Settings.fpsBoost = val
    if val then applyFpsBoost() end
end)

createToggle("Auto Terima Teman", Settings.autoAccept, function(val)
    Settings.autoAccept = val
end)

createToggle("Auto Broadcast Chat", Settings.autoChat, function(val)
    Settings.autoChat = val
end)

createToggle("Camera POV Lock", Settings.camLock, function(val)
    Settings.camLock = val
end)

-- Button Manual Hop
local HopNowCard = Instance.new("Frame")
HopNowCard.Size = UDim2.new(1, 0, 0, 28)
HopNowCard.BackgroundColor3 = Theme.Card
HopNowCard.BorderSizePixel = 0
HopNowCard.Parent = Scroll
addCorner(5, HopNowCard)

local HopBtn = Instance.new("TextButton")
HopBtn.Text = "🚀 PINDAH SERVER"
HopBtn.Font = FONT_BOLD
HopBtn.TextSize = 9.5
HopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HopBtn.BackgroundColor3 = Theme.AccentDim
HopBtn.Size = UDim2.new(1, -12, 0, 20)
HopBtn.Position = UDim2.new(0, 6, 0, 4)
HopBtn.BorderSizePixel = 0
HopBtn.Parent = HopNowCard
addCorner(4, HopBtn)

HopBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        doServerHop(function(status)
            HopBtn.Text = status
        end)
    end)
end)

-- Toggle Shortcut Keyboard
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift and ScreenGui.Parent then
        if Window.Visible then
            setMinimized(true)
        else
            setMinimized(false)
        end
    end
end)

print("[Yancok] UI ringkas & Server Hopper siap! Tekan [RightShift] untuk minimize/restore.")
