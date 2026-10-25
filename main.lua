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
    -- 1. Farm Telur
    autoSteal         = true,
    stealDelay        = 0.15,
    autoHatch         = true,
    hatchAmount       = 1,
    autoTeleport      = true,

    -- 2. Server Hop (Identik Nasi Rendang)
    autoHop           = true,
    hopWhen           = "Any",              -- "Any" | "After Steal Count" | "Interval" | "No Match"
    hopNoMatchDelay   = 60,                 -- detik tanpa klaim telur
    hopInterval       = 12,                 -- menit
    hopSteals         = 40,                 -- klaim telur
    hopMinPlayers     = 3,                  -- min pemain (0 = off)
    hopMaxPlayers     = 6,                  -- max pemain (0 = off)
    hopPreferEmpty    = true,               -- prefer server sepi

    -- 3. Auto Chat (Identik Nasi Rendang)
    autoChat          = false,
    chatInterval      = 25,
    chatText          = "Yancok Steal An Egg - 100% Free & Keyless!",
    chatText2         = "Farming Eggs AFK",
    chatText3         = "",

    -- 4. Camera (Identik Nasi Rendang)
    camLock           = false,
    camOffX           = 0,
    camOffY           = 35,
    camOffZ           = 0,
    camFov            = 70,

    -- 5. Misc & FPS (Identik Nasi Rendang)
    fpsBoost          = true,
    autoAcceptFriends = true,
    antiAfk           = true,
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

-- ==================== LOOP PENGECEKAN KONDISI AUTO-HOP ====================
local hopCountLbl, statusLbl
task.spawn(function()
    local startTime = os.clock()
    hopBaseClaims = totalClaims
    while getgenv()[SCRIPT_ID] == RUN_ID do
        task.wait(2)
        local elapsedSec = os.clock() - startTime
        local claimsGained = totalClaims - hopBaseClaims
        local noMatchSec = os.clock() - lastClaimTime

        if Settings.autoHop and not hopping then
            local ready = false
            local mode = Settings.hopWhen or "Any"
            if mode == "Interval" then
                ready = (elapsedSec >= (Settings.hopInterval or 12) * 60)
            elseif mode == "After Steal Count" then
                ready = (claimsGained >= (Settings.hopSteals or 40))
            elseif mode == "No Match" then
                ready = (claimsGained > 0 or elapsedSec > 90) and (noMatchSec >= (Settings.hopNoMatchDelay or 60))
            else -- Any
                ready = (elapsedSec >= (Settings.hopInterval or 12) * 60)
                     or (claimsGained >= (Settings.hopSteals or 40))
                     or ((claimsGained > 0 or elapsedSec > 90) and noMatchSec >= (Settings.hopNoMatchDelay or 60))
            end

            if ready then
                local started = doServerHop(function(s)
                    if hopCountLbl then hopCountLbl.Text = s end
                end)
                if started then
                    startTime = os.clock()
                    hopBaseClaims = totalClaims
                end
            end
        end

        -- Update Countdown Labels
        if hopCountLbl then
            if Settings.autoHop then
                local remain = math.max(0, math.ceil((Settings.hopInterval or 12) * 60 - elapsedSec))
                local mins = math.floor(remain / 60)
                local secs = remain % 60
                hopCountLbl.Text = ("next hop in %d:%02d (%d/%d steals)"):format(mins, secs, claimsGained, Settings.hopSteals or 40)
            else
                hopCountLbl.Text = "hop off"
            end
        end
        if statusLbl then
            statusLbl.Text = ("claims: %d | total: %d"):format(claimsGained, totalClaims)
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
                        if Settings.autoAcceptFriends and typeof(plr) == "Instance" and plr:IsA("Player") then
                            pcall(function() StarterGui:SetCore("PromptSendFriendRequest", plr) end)
                        end
                    end)
                end
            end
        end
    end)
end

-- Auto Chat Loop
local chatCountLbl
task.spawn(function()
    local lastChat = 0
    local msgIndex = 0
    while getgenv()[SCRIPT_ID] == RUN_ID do
        task.wait(1)
        if Settings.autoChat and (os.clock() - lastChat) >= math.max(5, Settings.chatInterval or 25) then
            local msgs = {}
            for _, m in ipairs({ Settings.chatText, Settings.chatText2, Settings.chatText3 }) do
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

        if chatCountLbl then
            if Settings.autoChat then
                local remain = math.max(0, math.ceil(math.max(5, Settings.chatInterval or 25) - (os.clock() - lastChat)))
                chatCountLbl.Text = "next chat in " .. remain .. "s"
            else
                chatCountLbl.Text = "chat off"
            end
        end
    end
end)

-- Anti-AFK Protection
pcall(function()
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if Settings.antiAfk then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end)

-- ============================ CAMERA LOCK POV ===============================
local cam = Workspace.CurrentCamera
RunService.RenderStepped:Connect(function()
    if Settings.camLock and cam and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            cam.CameraType = Enum.CameraType.Custom
            cam.FieldOfView = Settings.camFov or 70
            cam.CFrame = CFrame.new(root.Position + Vector3.new(Settings.camOffX or 0, Settings.camOffY or 35, Settings.camOffZ or 0), root.Position)
        end
    end
end)

-- ================================= GUI PANEL ================================
-- Layout Horizontal 2-Kolom Berbasis Tab (Persis Nasi Rendang, Posisi Tengah Layar)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YancokEgg_Panel"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = GuiParent

local function addCorner(r, p)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
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

-- =========================== FLOATING MINI BADGE ============================
local MiniBar = Instance.new("Frame")
MiniBar.Name = "MiniBar"
MiniBar.AnchorPoint = Vector2.new(0.5, 1)
MiniBar.Position = UDim2.new(0.5, 0, 1, -15)
MiniBar.Size = UDim2.new(0, 180, 0, 28)
MiniBar.BackgroundColor3 = Theme.Background
MiniBar.BorderSizePixel = 0
MiniBar.Active = true
MiniBar.Visible = false
MiniBar.Parent = ScreenGui
addCorner(8, MiniBar)
addStroke(Theme.Accent, 1.2, MiniBar)

local MiniLabel = Instance.new("TextLabel")
MiniLabel.Text = "🔥 Yancok: 0 Telur ⚡"
MiniLabel.Font = FONT_BOLD
MiniLabel.TextSize = 11
MiniLabel.TextColor3 = Theme.Accent
MiniLabel.Size = UDim2.new(1, 0, 1, 0)
MiniLabel.BackgroundTransparency = 1
MiniLabel.Parent = MiniBar

local MiniBtn = Instance.new("TextButton")
MiniBtn.Size = UDim2.new(1, 0, 1, 0)
MiniBtn.BackgroundTransparency = 1
MiniBtn.Text = ""
MiniBtn.Parent = MiniBar

-- =========================== MAIN WINDOW (CENTERED) =========================
local WIN_W, WIN_H = 620, 260
local Window = Instance.new("Frame")
Window.Name = "Window"
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.Position = UDim2.new(0.5, 0, 0.5, 0) -- TEPAT DI TENGAH LAYAR
Window.Size = UDim2.new(0, WIN_W, 0, WIN_H)
Window.BackgroundColor3 = Theme.Background
Window.BorderSizePixel = 0
Window.Active = true
Window.Parent = ScreenGui
addCorner(12, Window)
addStroke(Theme.Accent, 1.5, Window)

-- Responsiveness: Otomatis scale jika layar mobile / resolusi kecil
local WinScale = Instance.new("UIScale")
WinScale.Parent = Window
local function updateScale()
    pcall(function()
        local vp = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
        if vp and (vp.X < 680 or vp.Y < 380) then
            WinScale.Scale = math.clamp(math.min(vp.X / 680, vp.Y / 320), 0.55, 0.95)
        else
            WinScale.Scale = 1
        end
    end)
end
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end
updateScale()

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
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(MiniBar, MiniBar)

-- TopBar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Theme.Header
TopBar.BorderSizePixel = 0
TopBar.Parent = Window
addCorner(12, TopBar)
makeDraggable(Window, TopBar)

local Title = Instance.new("TextLabel")
Title.Text = "🔥 YANCOK — STEAL AN EGG (100% FREE & KEYLESS)"
Title.Font = FONT_BOLD
Title.TextSize = 12
Title.TextColor3 = Theme.Accent
Title.Position = UDim2.new(0, 14, 0, 0)
Title.Size = UDim2.new(1, -75, 1, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Text = "—"
MinBtn.Font = FONT_BOLD
MinBtn.TextSize = 12
MinBtn.TextColor3 = Theme.TextSub
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -56, 0, 6)
MinBtn.BackgroundColor3 = Theme.Card
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TopBar
addCorner(6, MinBtn)
MinBtn.MouseButton1Click:Connect(function()
    setMinimized(true)
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.Font = FONT_BOLD
CloseBtn.TextSize = 11
CloseBtn.TextColor3 = Theme.TextSub
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0, 6)
CloseBtn.BackgroundColor3 = Theme.Card
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TopBar
addCorner(6, CloseBtn)
CloseBtn.MouseButton1Click:Connect(function()
    setMinimized(true)
end)

-- ---- TAB BAR HORIZONTAL ----
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -16, 0, 28)
TabBar.Position = UDim2.new(0, 8, 0, 42)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Window

local TabList = Instance.new("UIListLayout")
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.Padding = UDim.new(0, 6)
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Parent = TabBar

local Pages, TabBtns, activeTab = {}, {}, nil
local ContentHost = Instance.new("Frame")
ContentHost.Size = UDim2.new(1, -16, 1, -80)
ContentHost.Position = UDim2.new(0, 8, 0, 74)
ContentHost.BackgroundTransparency = 1
ContentHost.Parent = Window

local function showTab(name)
    for n, pg in pairs(Pages) do pg.Visible = (n == name) end
    for n, b in pairs(TabBtns) do
        b.BackgroundColor3 = (n == name) and Theme.Accent or Theme.Card
        b.TextColor3 = (n == name) and Color3.fromRGB(0, 0, 0) or Theme.TextSub
    end
    activeTab = name
end

-- Tiap halaman = 2 KOLOM (kiri & kanan) yang masing-masing scroll secara independen
local function makePage(name, order)
    local pg = Instance.new("Frame")
    pg.Size = UDim2.new(1, 0, 1, 0)
    pg.BackgroundTransparency = 1
    pg.Visible = false
    pg.Parent = ContentHost

    local function col(isRight)
        local c = Instance.new("ScrollingFrame")
        c.Size = UDim2.new(0.5, -6, 1, 0)
        c.Position = isRight and UDim2.new(0.5, 6, 0, 0) or UDim2.new(0, 0, 0, 0)
        c.BackgroundTransparency = 1
        c.BorderSizePixel = 0
        c.ScrollBarThickness = 3
        c.ScrollBarImageColor3 = Theme.Accent
        c.CanvasSize = UDim2.new(0, 0, 0, 0)
        c.AutomaticCanvasSize = Enum.AutomaticSize.Y
        c.Parent = pg
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 5)
        l.Parent = c
        return c
    end

    local L, R = col(false), col(true)
    Pages[name] = pg

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 108, 1, 0)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = Theme.Card
    btn.BorderSizePixel = 0
    btn.Font = FONT_BOLD
    btn.Text = name
    btn.TextSize = 11.5
    btn.TextColor3 = Theme.TextSub
    btn.AutoButtonColor = false
    btn.Parent = TabBar
    addCorner(6, btn)

    btn.MouseButton1Click:Connect(function() showTab(name) end)
    TabBtns[name] = btn
    return L, R
end

-- ======================== HELPER KOMPONEN UI ================================
local function section(parent, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 0, 18)
    l.BackgroundTransparency = 1
    l.Font = FONT_BOLD
    l.Text = string.upper(text)
    l.TextColor3 = Theme.TextSub
    l.TextSize = 10.5
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function toggle(parent, label, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 26)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -50, 1, 0)
    l.Position = UDim2.new(0, 2, 0, 0)
    l.BackgroundTransparency = 1
    l.Font = FONT_MED
    l.Text = label
    l.TextColor3 = Theme.Text
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 40, 0, 20)
    pill.Position = UDim2.new(1, -42, 0.5, -10)
    pill.BackgroundColor3 = Settings[key] and Theme.Accent or Theme.Border
    pill.BorderSizePixel = 0
    pill.Parent = row
    addCorner(10, pill)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = Settings[key] and UDim2.new(1, -7, 0.5, 0) or UDim2.new(0, 7, 0.5, 0)
    knob.BackgroundColor3 = Settings[key] and Color3.new(0, 0, 0) or Theme.Text
    knob.BorderSizePixel = 0
    knob.Parent = pill
    addCorner(7, knob)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = row

    btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        pill.BackgroundColor3 = Settings[key] and Theme.Accent or Theme.Border
        knob.Position = Settings[key] and UDim2.new(1, -7, 0.5, 0) or UDim2.new(0, 7, 0.5, 0)
        knob.BackgroundColor3 = Settings[key] and Color3.new(0, 0, 0) or Theme.Text
        saveConfig()
        if key == "fpsBoost" and Settings.fpsBoost then applyFpsBoost() end
    end)
    return row
end

local function slider(parent, label, key, minV, maxV, step)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 38)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local val = Settings[key] or minV

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -50, 0, 16)
    l.Position = UDim2.new(0, 2, 0, 0)
    l.BackgroundTransparency = 1
    l.Font = FONT_MED
    l.Text = label
    l.TextColor3 = Theme.Text
    l.TextSize = 11.5
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 44, 0, 16)
    valLbl.Position = UDim2.new(1, -44, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = FONT_BOLD
    valLbl.Text = tostring(val)
    valLbl.TextColor3 = Theme.Accent
    valLbl.TextSize = 11.5
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -6, 0, 6)
    track.Position = UDim2.new(0, 3, 0, 24)
    track.BackgroundColor3 = Theme.Border
    track.BorderSizePixel = 0
    track.Parent = row
    addCorner(3, track)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((val - minV) / math.max(1, maxV - minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Theme.Text
    knob.BorderSizePixel = 0
    knob.Parent = track
    addCorner(7, knob)

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 22)
    hit.Position = UDim2.new(0, 0, 0, 16)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.Parent = row

    hit.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            local rel = math.clamp((inp.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            local v = minV + rel * (maxV - minV)
            if step then v = math.floor(v / step + 0.5) * step end
            if step and step < 1 then
                v = tonumber(string.format("%.2f", v))
            else
                v = math.floor(v + 0.5)
            end
            Settings[key] = math.clamp(v, minV, maxV)
            valLbl.Text = tostring(Settings[key])
            knob.Position = UDim2.new((Settings[key] - minV) / math.max(1, maxV - minV), 0, 0.5, 0)
            saveConfig()
        end
    end)

    return function()
        valLbl.Text = tostring(Settings[key])
        knob.Position = UDim2.new((Settings[key] - minV) / math.max(1, maxV - minV), 0, 0.5, 0)
    end
end

local function textbox(parent, label, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 26)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.38, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Font = FONT_MED
    l.Text = label
    l.TextColor3 = Theme.Text
    l.TextSize = 11.5
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.62, -4, 1, 0)
    box.Position = UDim2.new(0.38, 4, 0, 0)
    box.BackgroundColor3 = Theme.Card
    box.BorderSizePixel = 0
    box.Font = FONT_REG
    box.Text = Settings[key] or ""
    box.PlaceholderText = "isi teks..."
    box.TextColor3 = Theme.Text
    box.PlaceholderColor3 = Theme.TextSub
    box.TextSize = 11
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = row
    addCorner(6, box)

    box.FocusLost:Connect(function()
        Settings[key] = box.Text
        saveConfig()
    end)
end

local function dropdown(parent, label, key, options)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 26)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.44, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Font = FONT_MED
    l.Text = label
    l.TextColor3 = Theme.Text
    l.TextSize = 11.5
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.56, -4, 1, 0)
    btn.Position = UDim2.new(0.44, 4, 0, 0)
    btn.BackgroundColor3 = Theme.Card
    btn.BorderSizePixel = 0
    btn.Font = FONT_BOLD
    btn.Text = tostring(Settings[key])
    btn.TextSize = 11.5
    btn.TextColor3 = Theme.Accent
    btn.AutoButtonColor = false
    btn.Parent = row
    addCorner(6, btn)

    btn.MouseButton1Click:Connect(function()
        local cur = Settings[key]
        local idx = 1
        for i, opt in ipairs(options) do
            if tostring(opt) == tostring(cur) then idx = i break end
        end
        local nextOpt = options[(idx % #options) + 1]
        Settings[key] = nextOpt
        btn.Text = tostring(nextOpt)
        saveConfig()
    end)
end

local function button(parent, label, onClick)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -8, 0, 28)
    b.BackgroundColor3 = Theme.AccentDim
    b.BorderSizePixel = 0
    b.Font = FONT_BOLD
    b.Text = label
    b.TextSize = 12
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.AutoButtonColor = false
    b.Parent = parent
    addCorner(6, b)

    b.MouseButton1Click:Connect(function() pcall(onClick) end)
    return b
end

-- ===================== SUSUNAN HALAMAN MENU (5 TAB LENGKAP) =================
-- TAB 1: Farm Telur
local farmL, farmR = makePage("Farm Telur", 1)
section(farmL, "Auto Steal Telur")
toggle(farmL, "Auto Steal Telur", "autoSteal")
slider(farmL, "Jeda Ambil Telur (s)", "stealDelay", 0.05, 1.0, 0.05)
toggle(farmL, "Teleport ke Posisi Telur", "autoTeleport")

section(farmR, "Auto Hatch & Klaim")
toggle(farmR, "Auto Hatch Telur", "autoHatch")
dropdown(farmR, "Jumlah Sekali Hatch", "hatchAmount", { 1, 3, 8 })

local ClaimsCard = Instance.new("Frame")
ClaimsCard.Size = UDim2.new(1, -8, 0, 42)
ClaimsCard.BackgroundColor3 = Theme.Card
ClaimsCard.BorderSizePixel = 0
ClaimsCard.Parent = farmR
addCorner(6, ClaimsCard)

local EggCountLbl = Instance.new("TextLabel")
EggCountLbl.Text = "Telur Terklaim: 0"
EggCountLbl.Font = FONT_BOLD
EggCountLbl.TextSize = 13
EggCountLbl.TextColor3 = Theme.Green
EggCountLbl.Position = UDim2.new(0, 10, 0, 4)
EggCountLbl.Size = UDim2.new(1, -20, 0, 18)
EggCountLbl.TextXAlignment = Enum.TextXAlignment.Left
EggCountLbl.BackgroundTransparency = 1
EggCountLbl.Parent = ClaimsCard

local EggRateLbl = Instance.new("TextLabel")
EggRateLbl.Text = "Status: 100% Standalone | Bebas Key"
EggRateLbl.Font = FONT_REG
EggRateLbl.TextSize = 10
EggRateLbl.TextColor3 = Theme.TextSub
EggRateLbl.Position = UDim2.new(0, 10, 0, 22)
EggRateLbl.Size = UDim2.new(1, -20, 0, 16)
EggRateLbl.TextXAlignment = Enum.TextXAlignment.Left
EggRateLbl.BackgroundTransparency = 1
EggRateLbl.Parent = ClaimsCard

task.spawn(function()
    while getgenv()[SCRIPT_ID] == RUN_ID do
        task.wait(1)
        EggCountLbl.Text = "Telur Terklaim: " .. tostring(totalClaims)
        MiniLabel.Text = "🔥 Yancok: " .. tostring(totalClaims) .. " ⚡"
    end
end)

-- TAB 2: Server Hop (Persis Nasi Rendang)
local hopL, hopR = makePage("Server Hop", 2)
section(hopL, "Trigger Pindah Server")
toggle(hopL, "Auto Server Hop", "autoHop")
dropdown(hopL, "Hop When", "hopWhen", { "Any", "After Steal Count", "Interval", "No Match" })
slider(hopL, "No Match Delay (s)", "hopNoMatchDelay", 5, 180, 5)
slider(hopL, "Hop Interval (min)", "hopInterval", 1, 60, 1)
slider(hopL, "Steals Target", "hopSteals", 10, 200, 5)

section(hopR, "Target Server")
slider(hopR, "Min Player (0=off)", "hopMinPlayers", 0, 20, 1)
slider(hopR, "Max Player (0=off)", "hopMaxPlayers", 0, 20, 1)
toggle(hopR, "Prefer Server Paling Sepi", "hopPreferEmpty")

button(hopR, "🚀 Hop Server Sekarang", function()
    doServerHop(function(s)
        if hopCountLbl then hopCountLbl.Text = s end
    end)
end)

hopCountLbl = Instance.new("TextLabel")
hopCountLbl.Size = UDim2.new(1, -8, 0, 16)
hopCountLbl.BackgroundTransparency = 1
hopCountLbl.Font = FONT_MED
hopCountLbl.Text = "hop off"
hopCountLbl.TextColor3 = Theme.TextSub
hopCountLbl.TextSize = 11.5
hopCountLbl.TextXAlignment = Enum.TextXAlignment.Left
hopCountLbl.Parent = hopR

statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -8, 0, 16)
statusLbl.BackgroundTransparency = 1
statusLbl.Font = FONT_MED
statusLbl.Text = "claims: 0"
statusLbl.TextColor3 = Theme.TextSub
statusLbl.TextSize = 11.5
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = hopR

-- TAB 3: Auto Chat (Persis Nasi Rendang)
local chatL, chatR = makePage("Auto Chat", 3)
section(chatL, "Broadcast Chat Otomatis")
toggle(chatL, "Auto Send Chat", "autoChat")
slider(chatL, "Interval Chat (s)", "chatInterval", 5, 300, 5)

chatCountLbl = Instance.new("TextLabel")
chatCountLbl.Size = UDim2.new(1, -8, 0, 16)
chatCountLbl.BackgroundTransparency = 1
chatCountLbl.Font = FONT_MED
chatCountLbl.Text = "chat off"
chatCountLbl.TextColor3 = Theme.TextSub
chatCountLbl.TextSize = 11.5
chatCountLbl.TextXAlignment = Enum.TextXAlignment.Left
chatCountLbl.Parent = chatL

section(chatR, "Pesan (Rotasi Anti-Spam)")
textbox(chatR, "Pesan 1", "chatText")
textbox(chatR, "Pesan 2", "chatText2")
textbox(chatR, "Pesan 3", "chatText3")

-- TAB 4: Kamera POV (Persis Nasi Rendang)
local camL, camR = makePage("Kamera POV", 4)
section(camL, "Sudut Kamera AFK")
toggle(camL, "Kunci Sudut Kamera", "camLock")

local updCamX, updCamY, updCamZ, updCamFov
button(camL, "📸 Ambil Sudut POV Saat Ini", function()
    local chr = LocalPlayer.Character
    local r = chr and chr:FindFirstChild("HumanoidRootPart")
    local c = Workspace.CurrentCamera
    if r and c then
        local off = c.CFrame.Position - r.Position
        Settings.camOffX = math.floor(off.X + 0.5)
        Settings.camOffY = math.floor(off.Y + 0.5)
        Settings.camOffZ = math.floor(off.Z + 0.5)
        Settings.camFov = math.floor(c.FieldOfView + 0.5)
        if updCamX then updCamX(); updCamY(); updCamZ(); updCamFov() end
        saveConfig()
        print(("[Yancok] POV captured: %d, %d, %d | FOV %d"):format(Settings.camOffX, Settings.camOffY, Settings.camOffZ, Settings.camFov))
    end
end)

section(camR, "Offset & Zoom")
updCamX = slider(camR, "Offset X", "camOffX", -200, 200, 1)
updCamY = slider(camR, "Offset Y", "camOffY", -100, 200, 1)
updCamZ = slider(camR, "Offset Z", "camOffZ", -200, 200, 1)
updCamFov = slider(camR, "FOV Kamera", "camFov", 30, 120, 1)

-- TAB 5: Misc & FPS
local miscL, miscR = makePage("Misc & FPS", 5)
section(miscL, "Performa & Hemat Resource")
toggle(miscL, "Extreme FPS Booster", "fpsBoost")
toggle(miscL, "Anti-AFK (Anti Kick 20 Menit)", "antiAfk")

section(miscR, "Pertemanan & Rejoin")
toggle(miscR, "Auto Terima Pertemanan", "autoAcceptFriends")
button(miscR, "🔄 Rejoin Server Ini", function()
    pcall(function() TeleportService:TeleportToPlaceInstance(PLACE_ID, CURRENT_JOB, LocalPlayer) end)
end)

-- Tab default pertama
showTab("Farm Telur")

-- ==================== OVERLAY COUNTDOWN (TENGAH ATAS) =======================
local OverlayLbl = Instance.new("TextLabel")
OverlayLbl.Name = "NextHopOverlay"
OverlayLbl.AnchorPoint = Vector2.new(0.5, 0)
OverlayLbl.Position = UDim2.new(0.5, 0, 0, 18)
OverlayLbl.Size = UDim2.new(0, 360, 0, 24)
OverlayLbl.BackgroundTransparency = 1
OverlayLbl.Font = FONT_BOLD
OverlayLbl.Text = "Next Hop: off"
OverlayLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
OverlayLbl.TextSize = 13
OverlayLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
OverlayLbl.TextStrokeTransparency = 0
OverlayLbl.Parent = ScreenGui

task.spawn(function()
    while getgenv()[SCRIPT_ID] == RUN_ID do
        task.wait(1)
        if OverlayLbl and OverlayLbl.Parent then
            if Settings.autoHop and hopCountLbl and hopCountLbl.Text ~= "hop off" then
                OverlayLbl.Text = "⚡ " .. string.upper(hopCountLbl.Text)
            else
                OverlayLbl.Text = "⚡ YANCOK: " .. tostring(totalClaims) .. " TELUR TERCURI"
            end
        end
    end
end)

-- Toggle Shortcut Keyboard (RightShift)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift and ScreenGui.Parent then
        Window.Visible = not Window.Visible
        if not Window.Visible then
            MiniBar.Visible = false
        end
    end
end)

print("[Yancok] Suite lengkap ala Nasi Rendang aktif di TENGAH layar! Tekan [RightShift] untuk sembunyikan/tampilkan.")
