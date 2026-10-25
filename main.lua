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

local LocalPlayer = Players.LocalPlayer
local PLACE_ID    = game.PlaceId
local CURRENT_JOB = game.JobId

-- ============================ CONTAINER PROTEKSI ============================
-- Prioritaskan gethui() dari Delta / executor agar 100% luput dari scan PlayerGui game (Persis Nasi Rendang)
local CoreParent = LocalPlayer:WaitForChild("PlayerGui")
pcall(function()
    if type(gethui) == "function" then
        local h = gethui()
        if h then CoreParent = h end
    elseif type(get_hidden_gui) == "function" then
        local h = get_hidden_gui()
        if h then CoreParent = h end
    end
end)

-- Bersihkan instance GUI lama secara bersih
if getgenv().__YANCOK_GUI then
    pcall(function() getgenv().__YANCOK_GUI:Destroy() end)
    getgenv().__YANCOK_GUI = nil
end

-- ============================== TEMA & WARNA ===============================
local Theme = {
    Background = Color3.fromRGB(16, 18, 22),
    Header     = Color3.fromRGB(22, 26, 32),
    Card       = Color3.fromRGB(26, 30, 38),
    Control    = Color3.fromRGB(36, 42, 54),
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
    -- 1. Farm Telur & Stealth
    autoSteal         = true,               -- ON (Langsung otomatis jalan)
    rarityTarget      = "👑 Divine + ⚡ Eternal + 🔮 Secret", -- Target rarity
    targetDivine      = true,               -- 👑 Ambil Divine
    targetEternal     = true,               -- ⚡ Ambil Eternal
    targetSecret      = true,               -- 🔮 Ambil Secret
    onlyTargetRarity  = false,              -- Jika true, hanya ambil rarity terpilih
    movementMode      = "Safe Walk",        -- "Safe Walk" | "Smooth Glide" | "Instant CFrame"
    safeMode          = true,               -- Anti-Cheat Protection
    stealDelay        = 0.4,                -- Jeda aman
    maxDistance       = 250,                -- Radius aman pencarian telur
    autoHatch         = false,              -- OFF
    hatchAmount       = 1,

    -- 2. Server Hop
    autoHop           = false,              -- OFF
    hopWhen           = "Any",              -- "Any" | "After Steal Count" | "Interval" | "No Match"
    hopNoMatchDelay   = 60,                 -- detik
    hopInterval       = 12,                 -- menit
    hopSteals         = 40,                 -- klaim telur
    hopMinPlayers     = 3,                  -- min pemain
    hopMaxPlayers     = 6,                  -- max pemain
    hopPreferEmpty    = true,

    -- 3. Auto Chat
    autoChat          = false,              -- OFF
    chatInterval      = 25,
    chatText          = "Yancok Steal An Egg - 100% Free & Keyless!",
    chatText2         = "Farming Eggs AFK",
    chatText3         = "",

    -- 4. Camera
    camLock           = false,              -- OFF
    camOffX           = 0,
    camOffY           = 35,
    camOffZ           = 0,
    camFov            = 70,

    -- 5. Misc & FPS
    fpsBoost          = false,              -- OFF
    autoAcceptFriends = false,              -- OFF
    antiAfk           = false,              -- OFF
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
                for k, v in pairs(tbl) do
                    if Settings[k] ~= nil then
                        Settings[k] = v
                    end
                end
            end
        end
    end)
    -- Pastikan autoSteal aktif secara default saat pertama kali di-run
    if Settings.autoSteal == nil then
        Settings.autoSteal = true
    end
    if Settings.targetDivine == nil then
        Settings.targetDivine = true
    end
    if Settings.targetEternal == nil then
        Settings.targetEternal = true
    end
    if Settings.targetSecret == nil then
        Settings.targetSecret = true
    end
    if Settings.rarityTarget == nil then
        Settings.rarityTarget = "👑 Divine + ⚡ Eternal + 🔮 Secret"
    end
    if Settings.onlyTargetRarity == nil then
        Settings.onlyTargetRarity = false
    end
end
loadConfig()

-- ============================ CLAIM / STEAL TRACKER ========================
local totalClaims = 0
local lastClaimTime = os.clock()
local hopBaseClaims = 0
local lastClaimedRarity = "Belum Ada"
local rarityStats = {
    Divine    = 0,
    Eternal   = 0,
    Secret    = 0,
    Cosmic    = 0,
    Mythic    = 0,
    Legendary = 0,
    Epic      = 0,
    Rare      = 0,
    Uncommon  = 0,
    Common    = 0,
}

local function registerClaim(rName)
    totalClaims = totalClaims + 1
    lastClaimTime = os.clock()
    if rName and rName ~= "" then
        lastClaimedRarity = rName
        if rarityStats[rName] then
            rarityStats[rName] = rarityStats[rName] + 1
        end
    end
end

-- Pelacakan klaim telur murni via trigger aksi stealEgg (100% bebas dari hook remote network yang memicu BAC)

-- ==================== SISTEM RARITY STEAL AN EGG (LENGKAP) ===================
-- Kasta Rarity: Divine > Eternal > Secret > Cosmic > Mythic > Legendary > Epic > Rare > Uncommon > Common
local function getEggRarity(obj)
    if not obj then return 1, "Common", "⚪" end

    local text = string.lower(obj.Name or "")

    -- Cek attributes & value objects
    pcall(function()
        for attrName, attrVal in pairs(obj:GetAttributes()) do
            text = text .. " " .. string.lower(tostring(attrName)) .. " " .. string.lower(tostring(attrVal))
        end
    end)
    pcall(function()
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("StringValue") or child:IsA("IntValue") then
                text = text .. " " .. string.lower(child.Name) .. " " .. string.lower(tostring(child.Value))
            end
        end
    end)

    -- Cek ProximityPrompt (ActionText / ObjectText)
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        text = text .. " " .. string.lower(prompt.ActionText or "") .. " " .. string.lower(prompt.ObjectText or "")
    end

    -- 1. Divine (Kasta Tertinggi: Pendapatan Miliaran - Puluhan Miliar $/s)
    if string.find(text, "divine") or string.find(text, "devine")
        or string.find(text, "spirit world guardian") or string.find(text, "voidseer")
        or string.find(text, "skeletal sabertooth") or string.find(text, "royal skywhale")
        or string.find(text, "mecha scrambler") or string.find(text, "bone emperor")
        or string.find(text, "aetheron") or string.find(text, "luminous cthulhu")
        or string.find(text, "archangel") or string.find(text, "world burner")
        or string.find(text, "shattered colossus") or string.find(text, "kitsune")
        or string.find(text, "nightflame") or string.find(text, "unicorn") then
        return 10, "Divine", "👑"
    end

    -- 2. Eternal (Kasta Dewa: Pendapatan Ratusan Juta - Miliaran $/s)
    if string.find(text, "eternal")
        or string.find(text, "octophant") or string.find(text, "rhinobear")
        or string.find(text, "void serpent") or string.find(text, "gorilla king")
        or string.find(text, "shattered drake") or string.find(text, "oni tiger")
        or string.find(text, "world eater") or string.find(text, "dreadscale")
        or string.find(text, "abomination kong") then
        return 9, "Eternal", "⚡"
    end

    -- 3. Secret (Tersembunyi & Sangat Langka)
    if string.find(text, "secret") or string.find(text, "galaxy") or string.find(text, "rift") or string.find(text, "celestial") or string.find(text, "abyss") then
        return 8, "Secret", "🔮"
    end

    -- 4. Cosmic (Luar Angkasa)
    if string.find(text, "cosmic") or string.find(text, "supernova") or string.find(text, "nebula") then
        return 7, "Cosmic", "🌌"
    end

    -- 5. Mythic (Mitos)
    if string.find(text, "mythic") or string.find(text, "hydra") or string.find(text, "pegasus") or string.find(text, "chimera") then
        return 6, "Mythic", "🌟"
    end

    -- 6. Legendary (Legendaris)
    if string.find(text, "legendary") or string.find(text, "dragon") or string.find(text, "phoenix") then
        return 5, "Legendary", "🔥"
    end

    -- 7. Epic (Epik)
    if string.find(text, "epic") or string.find(text, "golem") or string.find(text, "griffin") then
        return 4, "Epic", "💎"
    end

    -- 8. Rare (Langka)
    if string.find(text, "rare") then
        return 3, "Rare", "🔹"
    end

    -- 9. Uncommon (Menengah)
    if string.find(text, "uncommon") or string.find(text, "fennec") then
        return 2, "Uncommon", "🟢"
    end

    return 1, "Common", "⚪"
end

local function isEggTargeted(score, rName)
    local targetStr = tostring(Settings.rarityTarget or "")
    local s = string.lower(targetStr)

    -- Cek pill buttons multi-select (Divine, Eternal, Secret)
    if score == 10 and (Settings.targetDivine == true or s:find("divine")) then return true end
    if score == 9 and (Settings.targetEternal == true or s:find("eternal")) then return true end
    if score == 8 and (Settings.targetSecret == true or s:find("secret")) then return true end

    -- Cek tier lainnya jika dipilih di dropdown
    if s:find("cosmic") and score >= 7 then return true end
    if s:find("mythic") and score >= 6 then return true end
    if s:find("legendary") and score >= 5 then return true end
    if s:find("epic") and score >= 4 then return true end
    if s:find("rare") and score >= 3 then return true end
    if s:find("uncommon") and score >= 2 then return true end

    -- Jika Semua (Prioritas)
    if s:find("semua") or s:find("prioritas") then
        return true
    end

    return false
end

local function hasHighTierEggInServer()
    local found = false
    local function check(obj)
        if found or not obj then return end
        local score = getEggRarity(obj)
        if score >= 9 then -- Eternal (9) atau Divine (10)
            found = true
        end
    end
    local containers = {
        Workspace:FindFirstChild("Eggs"),
        Workspace:FindFirstChild("FieldEggs"),
        Workspace:FindFirstChild("SpawnedEggs"),
        Workspace:FindFirstChild("EggsFolder"),
        Workspace:FindFirstChild("Nests"),
        Workspace:FindFirstChild("EggWorld"),
        Workspace:FindFirstChild("Map"),
    }
    for _, folder in ipairs(containers) do
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                check(item)
                if found then return true end
            end
        end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            check(obj)
            if found then return true end
        end
    end
    return found
end

-- ==================== NATIVE STEAL & EGG ENGINE (100% CLEAN) ===================
-- 100% Native Luau: Tanpa holy.lua, tanpa key, dan bebas dari dependensi nrlscript
local function getHrp()
    local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return chr and chr:FindFirstChild("HumanoidRootPart")
end

-- Temukan telur terdekat secara dinamis dengan filter & prioritas Rarity
local function getClosestEgg(maxDist)
    local hrp = getHrp()
    if not hrp then return nil, 9999, "Common" end

    local myPos = hrp.Position
    local bestEgg = nil
    local bestDist = maxDist or (Settings.maxDistance or 250)
    local bestScore = -1
    local bestRarityName = "Common"

    local onlyTarget = Settings.onlyTargetRarity == true

    local function checkObj(obj)
        if not (obj and obj.Parent) then return end
        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if not (prompt and prompt.Enabled) then return end

        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
        if not part then return end

        local d = (myPos - part.Position).Magnitude
        if d > (Settings.maxDistance or 250) then return end

        local score, rName = getEggRarity(obj)
        local isTarget = isEggTargeted(score, rName)

        -- Jika mode "Hanya Ambil Rarity Ini" aktif: abaikan telur yang tidak ditargetkan
        if onlyTarget and not isTarget then
            return
        end

        local isBetter = false
        if not onlyTarget then
            local currentTarget = isTarget
            local bestTarget = (bestScore >= 0 and isEggTargeted(bestScore, bestRarityName))

            if currentTarget and not bestTarget then
                isBetter = true
            elseif currentTarget and bestTarget then
                if score > bestScore then
                    isBetter = true
                elseif score == bestScore and d < bestDist then
                    isBetter = true
                end
            elseif not currentTarget and not bestTarget then
                if score > bestScore then
                    isBetter = true
                elseif score == bestScore and d < bestDist then
                    isBetter = true
                end
            end
        else
            -- Mode strict: hanya telur yang matches target
            if score > bestScore then
                isBetter = true
            elseif score == bestScore and d < bestDist then
                isBetter = true
            end
        end

        if isBetter then
            bestEgg = obj
            bestDist = d
            bestScore = score
            bestRarityName = rName
        end
    end

    local containers = {
        Workspace:FindFirstChild("Eggs"),
        Workspace:FindFirstChild("FieldEggs"),
        Workspace:FindFirstChild("SpawnedEggs"),
        Workspace:FindFirstChild("EggsFolder"),
        Workspace:FindFirstChild("Nests"),
        Workspace:FindFirstChild("EggWorld"),
        Workspace:FindFirstChild("Map"),
    }
    for _, folder in ipairs(containers) do
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                checkObj(item)
                if item:IsA("Folder") or item:IsA("Model") then
                    for _, sub in ipairs(item:GetChildren()) do
                        checkObj(sub)
                    end
                end
            end
        end
    end

    if not bestEgg then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if (obj:IsA("Model") or obj:IsA("Folder") or obj:IsA("BasePart")) and not (LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character)) then
                checkObj(obj)
                if obj:IsA("Model") or obj:IsA("Folder") then
                    for _, sub in ipairs(obj:GetChildren()) do
                        checkObj(sub)
                    end
                end
            end
        end
    end

    -- Fallback: Scan langsung semua ProximityPrompt yang ada di Workspace
    if not bestEgg then
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local p = prompt.Parent
                if p and not (LocalPlayer.Character and p:IsDescendantOf(LocalPlayer.Character)) then
                    checkObj(p)
                end
            end
        end
    end

    return bestEgg, bestDist, bestRarityName
end

-- Sistem Navigasi Alami Manusiawi (Smart Pathfinding & Obstacle Avoidance)
local function moveToTarget(targetPos, stopDist)
    local chr = LocalPlayer.Character
    if not chr then return false end
    local hrp = chr:FindFirstChild("HumanoidRootPart")
    local hum = chr:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum) then return false end

    stopDist = stopDist or 5.0
    local dist = (hrp.Position - targetPos).Magnitude
    if dist <= stopDist then return true end

    local rawMode = tostring(Settings.movementMode or "Safe Walk")
    local isSmoothGlide = rawMode:find("Smooth Glide") ~= nil or rawMode:find("Meluncur") ~= nil
    local isInstant = rawMode:find("Instant CFrame") ~= nil or rawMode:find("Teleport") ~= nil

    if not isSmoothGlide and not isInstant then
        -- 100% Menggunakan Navigasi Fisik Humanoid Roblox Asli (Tidak memicu delta CFrame, bebas BAC-3515 & BAC-4515)
        if dist <= 15 then
            hum:MoveTo(targetPos)
            local t0 = os.clock()
            while (os.clock() - t0) < 2.0 do
                if not chr or not hrp or (hrp.Position - targetPos).Magnitude <= stopDist then
                    return true
                end
                task.wait(0.08)
            end
            return (hrp.Position - targetPos).Magnitude <= (stopDist + 1.5)
        end

        -- 2. Jarak sedang / jauh: Gunakan PathfindingService agar belok menghindari tembok, pagar & rintangan
        local path = nil
        local pathOk = pcall(function()
            local pfs = game:GetService("PathfindingService")
            path = pfs:CreatePath({
                AgentRadius = 2.0,
                AgentHeight = 5.0,
                AgentCanJump = true,
                WaypointSpacing = 4.0,
            })
            path:ComputeAsync(hrp.Position, targetPos)
        end)

        if pathOk and path and path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            for i = 2, #waypoints do
                if not Settings.autoSteal or getgenv()[SCRIPT_ID] ~= RUN_ID then return false end
                local wp = waypoints[i]

                -- Sudah sampai dalam radius aman interaksi
                if (hrp.Position - targetPos).Magnitude <= stopDist then
                    return true
                end

                -- Jika rintangan memerlukan lompat (misal tangga / pembatas rendah)
                if wp.Action == Enum.PathWaypointAction.Jump then
                    hum.Jump = true
                end

                hum:MoveTo(wp.Position)

                local reached = false
                local t0 = os.clock()
                while (os.clock() - t0) < 1.6 do
                    if (hrp.Position - wp.Position).Magnitude <= 3.5 or (hrp.Position - targetPos).Magnitude <= stopDist then
                        reached = true
                        break
                    end
                    task.wait(0.06)
                end

                -- Jika stuck di rintangan, beri bantuan lompat kecil
                if not reached and (hrp.Position - targetPos).Magnitude > 10 then
                    hum.Jump = true
                    task.wait(0.12)
                end
            end
            return (hrp.Position - targetPos).Magnitude <= (stopDist + 2.0)
        else
            -- Fallback natural jalan lurus jika pathfinding gagal (area terbuka lapang)
            hum:MoveTo(targetPos)
            local t0 = os.clock()
            local ws = (hum.WalkSpeed and hum.WalkSpeed > 0) and hum.WalkSpeed or 16
            local maxWait = math.clamp(dist / ws, 0.8, 6.0)
            while (os.clock() - t0) < maxWait do
                if not chr or not hrp or (hrp.Position - targetPos).Magnitude <= stopDist then
                    return true
                end
                task.wait(0.1)
            end
            return (hrp.Position - targetPos).Magnitude <= (stopDist + 2.0)
        end

    elseif mode == "Smooth Glide" then
        -- Kecepatan lari alami terkalibrasi (18 studs/detik, sejajar tanah, tidak memicu Freefall)
        local speed = 18
        local duration = math.clamp(dist / speed, 0.2, 3.5)
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local groundTarget = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
        local tween = TweenService:Create(hrp, tweenInfo, { CFrame = CFrame.new(groundTarget) })
        tween:Play()
        task.wait(duration)
        return true

    else
        -- Instant CFrame (Direct Snap - gunakan jika di private server / ingin tercepat)
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 1.0, 0))
        task.wait(0.04)
        return true
    end
end

-- Interaksi Telur yang 100% Imun terhadap Anti-Cheat BAC-7581 & Tampak Alami
local function stealEgg(eggObj, eggRarity)
    if not (eggObj and eggObj.Parent) then return false end
    local hrp = getHrp()
    if not hrp then return false end

    local targetPart = eggObj:IsA("BasePart") and eggObj or eggObj:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart then return false end

    local prompt = eggObj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not (prompt and prompt.Enabled) then return false end

    -- Jarak interaksi natural (5 - 8 studs)
    local maxActivation = prompt.MaxActivationDistance or 10
    local stopDistance = math.clamp(maxActivation * 0.7, 4.5, 7.5)

    -- Gerak ke target dengan navigasi cerdas
    local arrived = moveToTarget(targetPart.Position, stopDistance)
    local currentDist = (hrp.Position - targetPart.Position).Magnitude

    -- Jika belum tepat di stopDistance tapi sudah dalam jangkauan prompt, tetap lanjut steal!
    if currentDist > maxActivation then
        if not arrived then return false end
    end

    -- Hadapkan karakter ke arah telur secara alami
    pcall(function()
        local lookPos = Vector3.new(targetPart.Position.X, hrp.Position.Y, targetPart.Position.Z)
        hrp.CFrame = CFrame.lookAt(hrp.Position, lookPos)
    end)

    -- Jeda micro-reaction manusiawi sebelum menekan tombol (0.05 - 0.12 detik)
    task.wait(math.random(5, 12) / 100)

    local success = false
    pcall(function()
        if not (prompt and prompt.Parent and prompt.Enabled) then return end
        local holdTime = prompt.HoldDuration or 0

        if holdTime > 0 then
            if type(fireproximityprompt) == "function" then
                pcall(function() fireproximityprompt(prompt, holdTime) end)
                task.wait(holdTime + 0.05)
                success = true
            elseif type(prompt.InputHoldBegin) == "function" and type(prompt.InputHoldEnd) == "function" then
                pcall(function() prompt:InputHoldBegin() end)
                task.wait(holdTime + 0.1)
                pcall(function() prompt:InputHoldEnd() end)
                success = true
            end
        else
            if type(fireproximityprompt) == "function" then
                pcall(function() fireproximityprompt(prompt, 0) end)
                pcall(function() fireproximityprompt(prompt) end)
                success = true
            elseif type(prompt.InputHoldBegin) == "function" and type(prompt.InputHoldEnd) == "function" then
                pcall(function()
                    prompt:InputHoldBegin()
                    task.wait(0.04)
                    prompt:InputHoldEnd()
                end)
                success = true
            end
        end
    end)
    if success then
        registerClaim(eggRarity)
    end
    return success
end

-- Loop Auto Steal Telur Dinamis (Selalu mengambil telur terdekat terlebih dahulu)
task.spawn(function()
    while getgenv()[SCRIPT_ID] == RUN_ID do
        if Settings.autoSteal then
            local closestEgg, dist, eggRarity = getClosestEgg(Settings.maxDistance or 250)
            if closestEgg and closestEgg.Parent then
                stealEgg(closestEgg, eggRarity)
                -- Jeda acak manusiawi (human-like debounce) antar pengambilan telur
                local delayVal = Settings.stealDelay or 0.4
                if Settings.safeMode then
                    delayVal = delayVal + (math.random(10, 28) / 100) -- variasi 0.10 - 0.28s
                end
                task.wait(delayVal)
            else
                -- Tidak ada telur dalam radius pandang, tunggu sejenak sebelum scan lagi
                task.wait(0.5)
            end
        else
            task.wait(0.5)
        end
    end
end)

-- Loop Auto Hatch Telur (Aman: Hanya berinteraksi jika berdiri di dekat Egg Stand / Incubator)
task.spawn(function()
    while getgenv()[SCRIPT_ID] == RUN_ID do
        if Settings.autoHatch then
            pcall(function()
                local hrp = getHrp()
                if not hrp then return end

                -- Cari Egg Stand / Incubator terdekat dengan ProximityPrompt aktif
                local myPos = hrp.Position
                local foundPrompt = nil

                local searchRoots = {
                    Workspace:FindFirstChild("EggStands"),
                    Workspace:FindFirstChild("Incubators"),
                    Workspace:FindFirstChild("HatchArea"),
                    Workspace:FindFirstChild("Eggs"),
                }
                for _, root in ipairs(searchRoots) do
                    if root then
                        for _, obj in ipairs(root:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                local p = obj.Parent
                                local part = p and (p:IsA("BasePart") and p or p:FindFirstChildWhichIsA("BasePart", true))
                                if part and (myPos - part.Position).Magnitude <= 12 then
                                    local name = string.lower(obj.ActionText .. " " .. obj.ObjectText .. " " .. obj.Name .. " " .. p.Name)
                                    if string.find(name, "hatch") or string.find(name, "open") or string.find(name, "incub") or string.find(name, "buy") then
                                        foundPrompt = obj
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if foundPrompt then break end
                end

                if foundPrompt then
                    -- Interaksi aman melalui input resmi ProximityPrompt game (Bukan tembak remote liar)
                    local holdTime = foundPrompt.HoldDuration or 0
                    if holdTime > 0 then
                        if type(foundPrompt.InputHoldBegin) == "function" and type(foundPrompt.InputHoldEnd) == "function" then
                            pcall(function() foundPrompt:InputHoldBegin() end)
                            task.wait(holdTime + 0.1)
                            pcall(function() foundPrompt:InputHoldEnd() end)
                        elseif type(fireproximityprompt) == "function" then
                            pcall(function() fireproximityprompt(foundPrompt, holdTime) end)
                        end
                    else
                        if type(foundPrompt.InputHoldBegin) == "function" and type(foundPrompt.InputHoldEnd) == "function" then
                            pcall(function()
                                foundPrompt:InputHoldBegin()
                                task.wait(0.06)
                                foundPrompt:InputHoldEnd()
                            end)
                        elseif type(fireproximityprompt) == "function" then
                            pcall(function() fireproximityprompt(foundPrompt, 0) end)
                        end
                    end
                end
            end)
        end
        task.wait(2.2)
    end
end)

-- ============================ FPS BOOSTER ENGINE ===========================
-- Dibuat non-destruktif agar tidak merusak integritas Workspace (Aman dari Map Integrity Check)
local boostWatcher = nil
local function stripObject(v)
    pcall(function()
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
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
            local mode = tostring(Settings.hopWhen or "Any")
            if mode == "Interval" or mode:find("Waktu") then
                ready = (elapsedSec >= (Settings.hopInterval or 12) * 60)
            elseif mode == "After Steal Count" or mode:find("Target") then
                ready = (claimsGained >= (Settings.hopSteals or 40))
            elseif mode == "No Match" or mode:find("Telur") then
                ready = (claimsGained > 0 or elapsedSec > 90) and (noMatchSec >= (Settings.hopNoMatchDelay or 60))
            elseif mode:find("Divine") or mode:find("Eternal") then
                -- Tunggu minimal 15 detik setelah load server agar folder telur sempat spawn
                if elapsedSec >= 15 then
                    local hasHighTier = hasHighTierEggInServer()
                    if not hasHighTier then
                        ready = true
                    end
                end
            else -- Any / Bebas
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

-- =========================== AUTO CHAT =====================================
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

-- Anti-AFK Protection (Safe: Tanpa VirtualUser yang memicu blacklist BAC)
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if Settings.antiAfk then
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                if vim then
                    vim:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
                    task.wait(0.05)
                    vim:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
                end
            end)
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
-- Layout Horizontal 2-Kolom Berbasis Tab (Super Rapih, Modern, Posisi Tengah Layar)
local ScreenGui = Instance.new("ScreenGui")
local randomTag = string.sub(HttpService:GenerateGUID(false):gsub("-", ""), 1, 6)
ScreenGui.Name = "App_" .. randomTag
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 1000
ScreenGui.Parent = CoreParent
getgenv().__YANCOK_GUI = ScreenGui

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

-- ===================== FLOATING MOBILE TOGGLE ICON (DELTA / TOUCH) =====================
-- Tombol sentuh bulat di tepi layar agar user mobile / Delta bisa buka/tutup menu
local MobileToggle = Instance.new("TextButton")
MobileToggle.Name = "BtnToggle"
MobileToggle.Size = UDim2.new(0, 38, 0, 38)
MobileToggle.Position = UDim2.new(0, 14, 0.5, -19)
MobileToggle.BackgroundColor3 = Theme.Header
MobileToggle.BackgroundTransparency = 0.15
MobileToggle.BorderSizePixel = 0
MobileToggle.Text = "🥚"
MobileToggle.TextSize = 20
MobileToggle.TextColor3 = Theme.Accent
MobileToggle.Parent = ScreenGui
addCorner(19, MobileToggle)
addStroke(Theme.Accent, 1.5, MobileToggle)

-- Dragging untuk Mobile Toggle Icon
do
    local dragging = false
    local dragInput, dragStart, startPos

    MobileToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MobileToggle.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    MobileToggle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MobileToggle.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- =========================== FLOATING MINI BADGE ============================
local MiniBar = Instance.new("Frame")
MiniBar.Name = "StatusBar"
MiniBar.AnchorPoint = Vector2.new(0.5, 1)
MiniBar.Position = UDim2.new(0.5, 0, 1, -6)
MiniBar.Size = UDim2.new(0, 150, 0, 24)
MiniBar.BackgroundColor3 = Theme.Header
MiniBar.BackgroundTransparency = 0.2
MiniBar.BorderSizePixel = 0
MiniBar.Active = true
MiniBar.Visible = false
MiniBar.Parent = ScreenGui
addCorner(12, MiniBar)
addStroke(Theme.Accent, 1.2, MiniBar)

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

-- =========================== IN-GAME TOAST NOTIFICATIONS ======================
local ToastContainer = Instance.new("Frame")
ToastContainer.Name = "Toasts"
ToastContainer.AnchorPoint = Vector2.new(0.5, 0)
ToastContainer.Position = UDim2.new(0.5, 0, 0, 14)
ToastContainer.Size = UDim2.new(0, 340, 0, 0)
ToastContainer.BackgroundTransparency = 1
ToastContainer.Parent = ScreenGui

local function showToast(title, desc, dur)
    pcall(function()
        local toast = Instance.new("Frame")
        toast.Size = UDim2.new(1, 0, 0, 46)
        toast.BackgroundColor3 = Theme.Header
        toast.BackgroundTransparency = 0.1
        toast.BorderSizePixel = 0
        toast.Parent = ToastContainer
        addCorner(8, toast)
        addStroke(Theme.Accent, 1.2, toast)

        local tLbl = Instance.new("TextLabel")
        tLbl.Text = title
        tLbl.Font = FONT_BOLD
        tLbl.TextSize = 12
        tLbl.TextColor3 = Theme.Accent
        tLbl.Position = UDim2.new(0, 12, 0, 5)
        tLbl.Size = UDim2.new(1, -24, 0, 16)
        tLbl.BackgroundTransparency = 1
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.Parent = toast

        local dLbl = Instance.new("TextLabel")
        dLbl.Text = desc
        dLbl.Font = FONT_REG
        dLbl.TextSize = 11
        dLbl.TextColor3 = Theme.TextSub
        dLbl.Position = UDim2.new(0, 12, 0, 23)
        dLbl.Size = UDim2.new(1, -24, 0, 16)
        dLbl.BackgroundTransparency = 1
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.Parent = toast

        task.delay(dur or 4, function()
            if toast and toast.Parent then
                TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
                TweenService:Create(tLbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
                TweenService:Create(dLbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
                task.wait(0.32)
                if toast and toast.Parent then toast:Destroy() end
            end
        end)
    end)
end

-- =========================== MAIN WINDOW (CENTERED & COMPACT) =========================
local WIN_W, WIN_H = 540, 255
local Window = Instance.new("Frame")
Window.Name = "Window"
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.Position = UDim2.new(0.5, 0, 0.44, 0) -- Lebih naik ke atas, tidak mentok ke bawah layar
Window.Size = UDim2.new(0, WIN_W, 0, WIN_H)
Window.BackgroundColor3 = Theme.Background
Window.BorderSizePixel = 0
Window.Active = true
Window.Visible = true -- Langsung terbuka agar menu dan toggle terlihat jelas saat execute
Window.Parent = ScreenGui
addCorner(10, Window)
addStroke(Theme.Accent, 1.2, Window)

-- Responsiveness: Otomatis scale jika layar mobile / resolusi kecil
local WinScale = Instance.new("UIScale")
WinScale.Parent = Window
local function updateScale()
    pcall(function()
        local vp = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
        if vp and (vp.X < 580 or vp.Y < 420) then
            WinScale.Scale = math.clamp(math.min(vp.X / 560, vp.Y / 300), 0.65, 0.95)
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

-- TopBar (Super Ringkas 28px)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 28)
TopBar.BackgroundColor3 = Theme.Header
TopBar.BorderSizePixel = 0
TopBar.Parent = Window
addCorner(10, TopBar)
makeDraggable(Window, TopBar)

local Title = Instance.new("TextLabel")
Title.Text = "🔥 YANCOK — STEAL AN EGG"
Title.Font = FONT_BOLD
Title.TextSize = 11
Title.TextColor3 = Theme.Accent
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Size = UDim2.new(1, -60, 1, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Text = "—"
MinBtn.Font = FONT_BOLD
MinBtn.TextSize = 10
MinBtn.TextColor3 = Theme.TextSub
MinBtn.Size = UDim2.new(0, 18, 0, 18)
MinBtn.Position = UDim2.new(1, -44, 0, 5)
MinBtn.BackgroundColor3 = Theme.Card
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TopBar
addCorner(4, MinBtn)
MinBtn.MouseButton1Click:Connect(function()
    setMinimized(true)
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.Font = FONT_BOLD
CloseBtn.TextSize = 9.5
CloseBtn.TextColor3 = Theme.TextSub
CloseBtn.Size = UDim2.new(0, 18, 0, 18)
CloseBtn.Position = UDim2.new(1, -22, 0, 5)
CloseBtn.BackgroundColor3 = Theme.Card
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TopBar
addCorner(4, CloseBtn)
CloseBtn.MouseButton1Click:Connect(function()
    setMinimized(true)
end)

-- ---- TAB BAR CONTAINER (RINGKAS & TEPAT) ----
local TabBarFrame = Instance.new("Frame")
TabBarFrame.Size = UDim2.new(1, -16, 0, 24)
TabBarFrame.Position = UDim2.new(0, 8, 0, 32)
TabBarFrame.BackgroundColor3 = Theme.Header
TabBarFrame.BackgroundTransparency = 0.4
TabBarFrame.BorderSizePixel = 0
TabBarFrame.Parent = Window
addCorner(6, TabBarFrame)
addStroke(Theme.Border, 1, TabBarFrame)

local TabList = Instance.new("UIListLayout")
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.Padding = UDim.new(0, 3)
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Parent = TabBarFrame

local Pages, TabBtns, activeTab = {}, {}, nil
local ContentHost = Instance.new("Frame")
ContentHost.Size = UDim2.new(1, -16, 1, -64)
ContentHost.Position = UDim2.new(0, 8, 0, 58)
ContentHost.BackgroundTransparency = 1
ContentHost.Parent = Window

local function showTab(name)
    for n, pg in pairs(Pages) do pg.Visible = (n == name) end
    for n, b in pairs(TabBtns) do
        local isSel = (n == name)
        b.BackgroundColor3 = isSel and Theme.Accent or Theme.Header
        b.BackgroundTransparency = isSel and 0 or 1
        b.TextColor3 = isSel and Color3.fromRGB(15, 17, 21) or Theme.TextSub
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
        c.Size = UDim2.new(0.5, -4, 1, 0)
        c.Position = isRight and UDim2.new(0.5, 4, 0, 0) or UDim2.new(0, 0, 0, 0)
        c.BackgroundTransparency = 1
        c.BorderSizePixel = 0
        c.ScrollBarThickness = 2
        c.ScrollBarImageColor3 = Theme.Accent
        c.CanvasSize = UDim2.new(0, 0, 0, 0)
        c.AutomaticCanvasSize = Enum.AutomaticSize.Y
        c.Parent = pg
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 3)
        l.Parent = c
        return c
    end

    local L, R = col(false), col(true)
    Pages[name] = pg

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.2, -3, 1, -2)
    btn.Position = UDim2.new(0, 1, 0, 1)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = Theme.Header
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Font = FONT_BOLD
    btn.Text = name
    btn.TextSize = 10
    btn.TextColor3 = Theme.TextSub
    btn.AutoButtonColor = false
    btn.Parent = TabBarFrame
    addCorner(5, btn)

    btn.MouseButton1Click:Connect(function() showTab(name) end)
    TabBtns[name] = btn
    return L, R
end

-- ======================== HELPER KOMPONEN UI RAPIH & RINGKAS ==========================
local function section(parent, text)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, -4, 0, 16)
    header.BackgroundTransparency = 1
    header.Parent = parent

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0, 10)
    bar.Position = UDim2.new(0, 2, 0.5, -5)
    bar.BackgroundColor3 = Theme.Accent
    bar.BorderSizePixel = 0
    bar.Parent = header
    addCorner(2, bar)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -12, 1, 0)
    l.Position = UDim2.new(0, 9, 0, 0)
    l.BackgroundTransparency = 1
    l.Font = FONT_BOLD
    l.Text = string.upper(text)
    l.TextColor3 = Theme.Accent
    l.TextSize = 9.5
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = header
    return header
end

local function toggle(parent, label, key)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 26)
    card.BackgroundColor3 = Theme.Card
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel = 0
    card.Parent = parent
    addCorner(5, card)
    addStroke(Theme.Border, 1, card)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -46, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Font = FONT_MED
    l.Text = label
    l.TextColor3 = Theme.Text
    l.TextSize = 10.5
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = card

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 30, 0, 15)
    pill.Position = UDim2.new(1, -38, 0.5, -7.5)
    pill.BackgroundColor3 = Settings[key] and Theme.Accent or Theme.Control
    pill.BorderSizePixel = 0
    pill.Parent = card
    addCorner(8, pill)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 11, 0, 11)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = Settings[key] and UDim2.new(1, -6.5, 0.5, 0) or UDim2.new(0, 6.5, 0.5, 0)
    knob.BackgroundColor3 = Settings[key] and Color3.new(0, 0, 0) or Theme.TextSub
    knob.BorderSizePixel = 0
    knob.Parent = pill
    addCorner(6, knob)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = card

    btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        pill.BackgroundColor3 = Settings[key] and Theme.Accent or Theme.Control
        knob.Position = Settings[key] and UDim2.new(1, -6.5, 0.5, 0) or UDim2.new(0, 6.5, 0.5, 0)
        knob.BackgroundColor3 = Settings[key] and Color3.new(0, 0, 0) or Theme.TextSub
        saveConfig()
        if key == "fpsBoost" and Settings.fpsBoost then applyFpsBoost() end
    end)
    return card
end

local function slider(parent, label, key, minV, maxV, step)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 32)
    card.BackgroundColor3 = Theme.Card
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel = 0
    card.Parent = parent
    addCorner(5, card)
    addStroke(Theme.Border, 1, card)

    local val = Settings[key] or minV

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -50, 0, 14)
    l.Position = UDim2.new(0, 8, 0, 3)
    l.BackgroundTransparency = 1
    l.Font = FONT_MED
    l.Text = label
    l.TextColor3 = Theme.Text
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = card

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 36, 0, 13)
    badge.Position = UDim2.new(1, -42, 0, 3)
    badge.BackgroundColor3 = Theme.Control
    badge.BorderSizePixel = 0
    badge.Parent = card
    addCorner(3, badge)

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, 0, 1, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = FONT_BOLD
    valLbl.Text = tostring(val)
    valLbl.TextColor3 = Theme.Accent
    valLbl.TextSize = 9.5
    valLbl.TextXAlignment = Enum.TextXAlignment.Center
    valLbl.Parent = badge

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -16, 0, 4)
    track.Position = UDim2.new(0, 8, 0, 21)
    track.BackgroundColor3 = Theme.Control
    track.BorderSizePixel = 0
    track.Parent = card
    addCorner(2, track)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((val - minV) / math.max(1, maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    addCorner(2, fill)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(1, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = fill
    addCorner(5, knob)

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 16)
    hit.Position = UDim2.new(0, 0, 0, 16)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.Parent = card

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
            fill.Size = UDim2.new((Settings[key] - minV) / math.max(1, maxV - minV), 0, 1, 0)
            saveConfig()
        end
    end)

    return function()
        valLbl.Text = tostring(Settings[key])
        fill.Size = UDim2.new((Settings[key] - minV) / math.max(1, maxV - minV), 0, 1, 0)
    end
end

local function textbox(parent, label, key)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 26)
    card.BackgroundColor3 = Theme.Card
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel = 0
    card.Parent = parent
    addCorner(5, card)
    addStroke(Theme.Border, 1, card)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.38, 0, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Font = FONT_MED
    l.Text = label
    l.TextColor3 = Theme.Text
    l.TextSize = 10.5
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = card

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.62, -14, 0, 18)
    box.Position = UDim2.new(0.38, 6, 0.5, -9)
    box.BackgroundColor3 = Theme.Control
    box.BorderSizePixel = 0
    box.Font = FONT_REG
    box.Text = Settings[key] or ""
    box.PlaceholderText = "isi..."
    box.TextColor3 = Theme.Text
    box.PlaceholderColor3 = Theme.TextSub
    box.TextSize = 10
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = card
    addCorner(4, box)

    box.FocusLost:Connect(function()
        Settings[key] = box.Text
        saveConfig()
    end)
end

local function dropdown(parent, label, key, options)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 26)
    card.BackgroundColor3 = Theme.Card
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel = 0
    card.Parent = parent
    addCorner(5, card)
    addStroke(Theme.Border, 1, card)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.44, 0, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Font = FONT_MED
    l.Text = label
    l.TextColor3 = Theme.Text
    l.TextSize = 10.5
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.56, -14, 0, 18)
    btn.Position = UDim2.new(0.44, 6, 0.5, -9)
    btn.BackgroundColor3 = Theme.Control
    btn.BorderSizePixel = 0
    btn.Font = FONT_BOLD
    btn.Text = tostring(Settings[key])
    btn.TextSize = 9.5
    btn.TextColor3 = Theme.Accent
    btn.AutoButtonColor = false
    btn.Parent = card
    addCorner(4, btn)

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
        if type(onChange) == "function" then
            pcall(onChange, nextOpt)
        end
    end)
    return btn
end

local function button(parent, label, onClick)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 24)
    b.BackgroundColor3 = Theme.AccentDim
    b.BorderSizePixel = 0
    b.Font = FONT_BOLD
    b.Text = label
    b.TextSize = 10.5
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.AutoButtonColor = false
    b.Parent = parent
    addCorner(5, b)

    b.MouseButton1Click:Connect(function() pcall(onClick) end)
    return b
end

-- ===================== SUSUNAN HALAMAN MENU (5 TAB LENGKAP) =================
-- TAB 1: Ambil Telur
local farmL, farmR = makePage("🥚 Telur", 1)
section(farmL, "Ambil Telur Otomatis")
toggle(farmL, "Ambil Telur Otomatis", "autoSteal")
dropdown(farmL, "Cara Jalan Karakter", "movementMode", { "Jalan Santai (Paling Aman)", "Meluncur Mulus", "Teleport Kilat" })
toggle(farmL, "Mode Halus (Anti-Cheat)", "safeMode")
slider(farmL, "Jeda Ambil Telur (detik)", "stealDelay", 0.1, 1.5, 0.05)
slider(farmL, "Jarak Telur Terjauh", "maxDistance", 50, 600, 25)

section(farmR, "Filter Rarity (Pilih 3 Sekaligus)")

local refreshPills

dropdown(farmR, "Target Rarity", "rarityTarget", {
    "👑 Divine + ⚡ Eternal + 🔮 Secret",
    "👑 Divine + ⚡ Eternal",
    "👑 Hanya Divine",
    "⚡ Hanya Eternal",
    "🔮 Hanya Secret",
    "Semua (Prioritas)",
    "🌌 Cosmic+",
    "🌟 Mythic+",
    "🔥 Legendary+",
    "⚪ Semua Telur"
}, function(opt)
    local s = string.lower(tostring(opt))
    if s:find("divine") and s:find("eternal") and s:find("secret") then
        Settings.targetDivine = true
        Settings.targetEternal = true
        Settings.targetSecret = true
    elseif s:find("divine") and s:find("eternal") then
        Settings.targetDivine = true
        Settings.targetEternal = true
        Settings.targetSecret = false
    elseif s:find("hanya divine") or opt == "👑 Divine" then
        Settings.targetDivine = true
        Settings.targetEternal = false
        Settings.targetSecret = false
    elseif s:find("hanya eternal") or opt == "⚡ Eternal" then
        Settings.targetDivine = false
        Settings.targetEternal = true
        Settings.targetSecret = false
    elseif s:find("hanya secret") or opt == "🔮 Secret" then
        Settings.targetDivine = false
        Settings.targetEternal = false
        Settings.targetSecret = true
    end
    if refreshPills then refreshPills() end
end)

-- 3 Tombol Pill Sekaligus (Multi-Select Divine, Eternal, Secret)
local TrioBar = Instance.new("Frame")
TrioBar.Size = UDim2.new(1, -4, 0, 24)
TrioBar.BackgroundTransparency = 1
TrioBar.Parent = farmR

local pillBtns = {}
local function makePill(text, key, posX, width)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(width, -3, 1, 0)
    btn.Position = UDim2.new(posX, 0, 0, 0)
    btn.BorderSizePixel = 0
    btn.Font = FONT_BOLD
    btn.Text = text
    btn.TextSize = 9.5
    btn.AutoButtonColor = false
    btn.Parent = TrioBar
    addCorner(4, btn)

    local function updateView()
        local on = Settings[key] == true
        btn.BackgroundColor3 = on and Theme.Accent or Theme.Control
        btn.TextColor3 = on and Color3.fromRGB(0, 0, 0) or Theme.TextSub
    end
    updateView()
    pillBtns[key] = updateView

    btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        updateView()
        saveConfig()
    end)
end

makePill("👑 Divine", "targetDivine", 0, 0.333)
makePill("⚡ Eternal", "targetEternal", 0.333, 0.333)
makePill("🔮 Secret", "targetSecret", 0.666, 0.334)

refreshPills = function()
    for _, fn in pairs(pillBtns) do
        pcall(fn)
    end
end

toggle(farmR, "Hanya Ambil Rarity Ini", "onlyTargetRarity")

section(farmR, "Buka Telur (Hatch)")
toggle(farmR, "Buka Telur Otomatis", "autoHatch")
dropdown(farmR, "Sekali Buka Berapa Telur", "hatchAmount", { 1, 3, 8 })

section(farmR, "Hasil Panen")
local ClaimsCard = Instance.new("Frame")
ClaimsCard.Size = UDim2.new(1, -4, 0, 48)
ClaimsCard.BackgroundColor3 = Theme.Card
ClaimsCard.BackgroundTransparency = 0.25
ClaimsCard.BorderSizePixel = 0
ClaimsCard.Parent = farmR
addCorner(5, ClaimsCard)
addStroke(Theme.Border, 1, ClaimsCard)

local EggCountLbl = Instance.new("TextLabel")
EggCountLbl.Text = "Telur Terkumpul: 0"
EggCountLbl.Font = FONT_BOLD
EggCountLbl.TextSize = 10.5
EggCountLbl.TextColor3 = Theme.Green
EggCountLbl.Position = UDim2.new(0, 8, 0, 2)
EggCountLbl.Size = UDim2.new(1, -16, 0, 14)
EggCountLbl.TextXAlignment = Enum.TextXAlignment.Left
EggCountLbl.BackgroundTransparency = 1
EggCountLbl.Parent = ClaimsCard

local EggRarityLbl = Instance.new("TextLabel")
EggRarityLbl.Text = "👑 Div: 0 | ⚡ Eter: 0 | 🔮 Sec: 0"
EggRarityLbl.Font = FONT_BOLD
EggRarityLbl.TextSize = 9
EggRarityLbl.TextColor3 = Theme.Accent
EggRarityLbl.Position = UDim2.new(0, 8, 0, 17)
EggRarityLbl.Size = UDim2.new(1, -16, 0, 14)
EggRarityLbl.TextXAlignment = Enum.TextXAlignment.Left
EggRarityLbl.BackgroundTransparency = 1
EggRarityLbl.Parent = ClaimsCard

local EggRateLbl = Instance.new("TextLabel")
EggRateLbl.Text = "Terakhir: Siap Panen"
EggRateLbl.Font = FONT_REG
EggRateLbl.TextSize = 8.5
EggRateLbl.TextColor3 = Theme.TextSub
EggRateLbl.Position = UDim2.new(0, 8, 0, 32)
EggRateLbl.Size = UDim2.new(1, -16, 0, 13)
EggRateLbl.TextXAlignment = Enum.TextXAlignment.Left
EggRateLbl.BackgroundTransparency = 1
EggRateLbl.Parent = ClaimsCard

task.spawn(function()
    while getgenv()[SCRIPT_ID] == RUN_ID do
        task.wait(1)
        EggCountLbl.Text = "Telur Terkumpul: " .. tostring(totalClaims)
        EggRarityLbl.Text = string.format("👑 Div: %d | ⚡ Eter: %d | 🔮 Sec: %d", rarityStats.Divine or 0, rarityStats.Eternal or 0, rarityStats.Secret or 0)
        EggRateLbl.Text = "Terakhir: " .. tostring(lastClaimedRarity)
        MiniLabel.Text = "🔥 Yancok: " .. tostring(totalClaims) .. " ⚡"
    end
end)

-- TAB 2: Pindah Server
local hopL, hopR = makePage("🚀 Pindah", 2)
section(hopL, "Kapan Pindah Server?")
toggle(hopL, "Pindah Server Otomatis", "autoHop")
dropdown(hopL, "Pindah Kalau", "hopWhen", { "Bebas / Kapan Saja", "Target Tercapai", "Waktu Habis", "Telur Habis", "Tidak Ada Divine/Eternal" })
slider(hopL, "Tunggu Telur Baru (detik)", "hopNoMatchDelay", 5, 180, 5)
slider(hopL, "Lama di Server (menit)", "hopInterval", 1, 60, 1)
slider(hopL, "Target Jumlah Telur", "hopSteals", 10, 200, 5)

section(hopR, "Pilih Server")
slider(hopR, "Minimal Pemain", "hopMinPlayers", 0, 20, 1)
slider(hopR, "Maksimal Pemain", "hopMaxPlayers", 0, 20, 1)
toggle(hopR, "Pilih Server Paling Sepi", "hopPreferEmpty")

button(hopR, "🚀 Pindah Server Sekarang", function()
    doServerHop(function(s)
        if hopCountLbl then hopCountLbl.Text = s end
    end)
end)

local StatCard = Instance.new("Frame")
StatCard.Size = UDim2.new(1, -4, 0, 30)
StatCard.BackgroundColor3 = Theme.Card
StatCard.BackgroundTransparency = 0.25
StatCard.BorderSizePixel = 0
StatCard.Parent = hopR
addCorner(5, StatCard)
addStroke(Theme.Border, 1, StatCard)

hopCountLbl = Instance.new("TextLabel")
hopCountLbl.Size = UDim2.new(1, -16, 0, 14)
hopCountLbl.Position = UDim2.new(0, 8, 0, 2)
hopCountLbl.BackgroundTransparency = 1
hopCountLbl.Font = FONT_MED
hopCountLbl.Text = "hop off"
hopCountLbl.TextColor3 = Theme.Text
hopCountLbl.TextSize = 9.5
hopCountLbl.TextXAlignment = Enum.TextXAlignment.Left
hopCountLbl.Parent = StatCard

statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -16, 0, 13)
statusLbl.Position = UDim2.new(0, 8, 0, 15)
statusLbl.BackgroundTransparency = 1
statusLbl.Font = FONT_REG
statusLbl.Text = "claims: 0"
statusLbl.TextColor3 = Theme.TextSub
statusLbl.TextSize = 9
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = StatCard

-- TAB 3: Auto Chat
local chatL, chatR = makePage("💬 Chat", 3)
section(chatL, "Kirim Chat Sendiri")
toggle(chatL, "Kirim Chat Otomatis", "autoChat")
slider(chatL, "Jeda Kirim Chat (detik)", "chatInterval", 5, 300, 5)

local ChatStatusCard = Instance.new("Frame")
ChatStatusCard.Size = UDim2.new(1, -4, 0, 24)
ChatStatusCard.BackgroundColor3 = Theme.Card
ChatStatusCard.BackgroundTransparency = 0.25
ChatStatusCard.BorderSizePixel = 0
ChatStatusCard.Parent = chatL
addCorner(5, ChatStatusCard)
addStroke(Theme.Border, 1, ChatStatusCard)

chatCountLbl = Instance.new("TextLabel")
chatCountLbl.Size = UDim2.new(1, -16, 1, 0)
chatCountLbl.Position = UDim2.new(0, 8, 0, 0)
chatCountLbl.BackgroundTransparency = 1
chatCountLbl.Font = FONT_MED
chatCountLbl.Text = "chat off"
chatCountLbl.TextColor3 = Theme.TextSub
chatCountLbl.TextSize = 9.5
chatCountLbl.TextXAlignment = Enum.TextXAlignment.Left
chatCountLbl.Parent = ChatStatusCard

section(chatR, "Isi Pesan Chat")
textbox(chatR, "Pesan 1", "chatText")
textbox(chatR, "Pesan 2", "chatText2")
textbox(chatR, "Pesan 3", "chatText3")

-- TAB 4: Kamera
local camL, camR = makePage("📹 Kamera", 4)
section(camL, "Kunci Pandangan")
toggle(camL, "Kunci Kamera Dari Atas", "camLock")

local updCamX, updCamY, updCamZ, updCamFov
button(camL, "📸 Kunci Posisi Kamera Sekarang", function()
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

section(camR, "Atur Posisi Kamera")
updCamX = slider(camR, "Geser Kiri/Kanan", "camOffX", -200, 200, 1)
updCamY = slider(camR, "Tinggi Kamera", "camOffY", -100, 200, 1)
updCamZ = slider(camR, "Maju/Mundur", "camOffZ", -200, 200, 1)
updCamFov = slider(camR, "Zoom Kamera (FOV)", "camFov", 30, 120, 1)

-- TAB 5: Anti-Lag & AFK
local miscL, miscR = makePage("⚡ Anti-Lag", 5)
section(miscL, "Biar Lancar & Enteng")
toggle(miscL, "Anti Lag (Hapus Efek Berat)", "fpsBoost")
toggle(miscL, "Anti-Kick 20 Menit (Bisa Ditinggal)", "antiAfk")

section(miscR, "Teman & Masuk Ulang")
toggle(miscR, "Otomatis Terima Teman", "autoAcceptFriends")
button(miscR, "🔄 Masuk Ulang Server Ini", function()
    pcall(function() TeleportService:TeleportToPlaceInstance(PLACE_ID, CURRENT_JOB, LocalPlayer) end)
end)

-- Tab default pertama
showTab("🥚 Telur")

-- Hubungkan Mobile Toggle Icon (Sentuh layar di Delta / Mobile)
MobileToggle.MouseButton1Click:Connect(function()
    Window.Visible = not Window.Visible
end)

-- Toggle Shortcut Keyboard (RightShift jika di PC)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift and ScreenGui.Parent then
        Window.Visible = not Window.Visible
    end
end)

-- Notifikasi in-game bersih saat execute
showToast("🥚 Yancok Aktif", "Auto Steal ON! Karakter otomatis mencari & mengambil telur.", 4)

print("[Yancok Stealth] Script aktif dengan proteksi Anti-Cheat! Ketuk tombol 🥚 atau tekan [RightShift] untuk buka/tutup menu.")
