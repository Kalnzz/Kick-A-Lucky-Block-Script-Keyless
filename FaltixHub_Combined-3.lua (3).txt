if _G.FaltixHubLoaded then return end
_G.FaltixHubLoaded = true

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local RepStorage       = game:GetService("ReplicatedStorage")

local LP         = Players.LocalPlayer
local MyUsername = LP.Name

local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function HRP() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function HUM() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function zeroVel(h)
    h.AssemblyLinearVelocity  = Vector3.zero
    h.AssemblyAngularVelocity = Vector3.zero
end
local function setAnalog(state)
    local tg = LP.PlayerGui:FindFirstChild("TouchGui")
    if tg then
        local f = tg:FindFirstChild("TouchControlFrame")
        if f then f.Visible = state end
    end
end

-- ============================================================
-- WindUI
-- ============================================================
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title        = "Faltix Hub",
    Icon         = "rbxassetid://4483362458",
    Author       = "Combined Edition",
    Folder       = "FaltixHub",
    Size         = UDim2.fromOffset(560, 460),
    Transparent  = true,
    Theme        = "Crimson",
    SideBarWidth = 185,
})

local HomeTab   = Window:Tab({ Title = "Home",        Icon = "house"    })
local V1Tab     = Window:Tab({ Title = "AutoFarm V1", Icon = "sword"    })
local V2Tab     = Window:Tab({ Title = "AutoFarm V2", Icon = "zap"      })
local TrainTab  = Window:Tab({ Title = "AutoTrain",   Icon = "activity" })
local PlayerTab = Window:Tab({ Title = "Player",      Icon = "user"     })
local MiscTab   = Window:Tab({ Title = "Misc",        Icon = "settings" })

-- ============================================================
-- HOME
-- ============================================================
HomeTab:Section({ Title = "Faltix Hub - Combined Edition" })
HomeTab:Paragraph({
    Title   = "Info",
    Content = "AutoFarm V1  |  AutoFarm V2  |  AutoTrain\nWindUI - Theme Crimson",
})

-- ============================================================
-- SHARED TARGET
-- ============================================================
local TARGET_CF = CFrame.new(
    690.649963, 3.000007, 232.611252,
    -0.054131, 0,  0.998534,
    0,          1,  0,
    -0.998534,  0, -0.054131
)
local TARGET_ROT do
    local _,_,_,a,b,c,d,e,f,g,h,i = TARGET_CF:GetComponents()
    TARGET_ROT = CFrame.new(0,0,0,a,b,c,d,e,f,g,h,i)
end

-- Walk ke TARGET_CF (dipakai V1 & V2)
local function walkToTarget(isActiveFunc, onDone)
    local tPos = TARGET_CF.Position
    setAnalog(false)
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not isActiveFunc() then
            conn:Disconnect() setAnalog(true) onDone() return
        end
        local h   = HRP()
        local hum = HUM()
        if not h or not hum then
            conn:Disconnect() setAnalog(true) onDone() return
        end
        local pos  = h.Position
        local dx   = tPos.X - pos.X
        local dz   = tPos.Z - pos.Z
        local dist = math.sqrt(dx*dx + dz*dz)
        if dist < 0.6 then
            zeroVel(h)
            h.CFrame = CFrame.new(tPos.X, pos.Y, tPos.Z) * TARGET_ROT
            conn:Disconnect() setAnalog(true) onDone() return
        end
        local spd  = math.max(hum.WalkSpeed, 1)
        local step = math.min(spd * dt, dist)
        zeroVel(h)
        h.CFrame = CFrame.new(
            pos.X + (dx/dist)*step,
            pos.Y,
            pos.Z + (dz/dist)*step
        ) * TARGET_ROT
    end)
    return conn
end

-- Jalan mundur lurus (arah -Z relatif ke facing karakter)
-- terus sampai tsunami kill, lalu tunggu respawn, lalu jalan ke target
local function walkBackThenRespawn(isActiveFunc, onDone)
    setAnalog(false)

    local h = HRP()
    if not h then onDone() return end

    -- Ambil arah mundur dari facing karakter saat ini
    local backDir = -h.CFrame.LookVector
    backDir = Vector3.new(backDir.X, 0, backDir.Z).Unit

    local BACK_SPEED = 20
    local conn

    -- Phase 1: jalan mundur sampai karakter mati (Health <= 0)
    conn = RunService.Heartbeat:Connect(function(dt)
        if not isActiveFunc() then
            conn:Disconnect() setAnalog(true) onDone() return
        end
        local hrp = HRP()
        local hum = HUM()
        if not hrp or not hum then
            -- Karakter udah hilang (mati), masuk phase 2
            conn:Disconnect()
            -- Phase 2: tunggu respawn
            LP.CharacterAdded:Wait()
            local newChar = getChar()
            newChar:WaitForChild("HumanoidRootPart")
            task.wait(0.5) -- kasih waktu load
            -- Phase 3: jalan ke target
            walkToTarget(isActiveFunc, onDone)
            return
        end
        if hum.Health <= 0 then
            conn:Disconnect()
            LP.CharacterAdded:Wait()
            local newChar = getChar()
            newChar:WaitForChild("HumanoidRootPart")
            task.wait(0.5)
            walkToTarget(isActiveFunc, onDone)
            return
        end
        -- Move mundur
        zeroVel(hrp)
        hrp.CFrame = CFrame.new(
            hrp.Position + backDir * BACK_SPEED * dt,
            hrp.Position + backDir * BACK_SPEED * dt + backDir
        )
    end)
end

local function fireKick()
    pcall(function()
        RepStorage
            :WaitForChild("Shared",        5)
            :WaitForChild("Packages",      5)
            :WaitForChild("Network",       5)
            :WaitForChild("rev_KickEvent", 5)
            :FireServer(1, 1)
    end)
end

-- ============================================================
-- AUTOFARM V1
-- ============================================================
local farmV1   = false
local autoCash = false
local autoUpg  = false

local function doOneCycleV1(nextCycle)
    if not farmV1 then return end
    local h = HRP()
    if not h then task.wait(1) nextCycle() return end

    zeroVel(h)
    h.CFrame = TARGET_CF
    task.wait(0.35)

    fireKick()

    -- Deteksi studs
    repeat
        RunService.Heartbeat:Wait()
        if not farmV1 then return end
        local y = h.Position.Y
        if y <= -6.9 and y >= -8.2 then break end
    until false

    -- Jalan ke target & ulang
    walkToTarget(function() return farmV1 end, function()
        task.wait(0.1)
        nextCycle()
    end)
end

local function startLoopV1()
    if not farmV1 then return end
    doOneCycleV1(function() task.spawn(startLoopV1) end)
end

V1Tab:Section({ Title = "Farm" })
V1Tab:Toggle({
    Title    = "Auto Farm V1",
    Value    = false,
    Callback = function(v)
        farmV1 = v
        if v then task.spawn(startLoopV1) else setAnalog(true) end
    end,
})

V1Tab:Section({ Title = "Collect & Upgrade" })
V1Tab:Toggle({
    Title    = "Auto Collect Cash",
    Value    = false,
    Callback = function(v)
        autoCash = v
        if not v then return end
        task.spawn(function()
            while autoCash do
                for i = 1, 50 do
                    pcall(function()
                        RepStorage:WaitForChild("Shared"):WaitForChild("Packages")
                            :WaitForChild("Network"):WaitForChild("rev_B_Collect"):FireServer(i)
                    end)
                    task.wait(0.05)
                end
                task.wait(3)
            end
        end)
    end,
})
V1Tab:Toggle({
    Title    = "Auto Upgrade Brainrot",
    Value    = false,
    Callback = function(v)
        autoUpg = v
        if not v then return end
        task.spawn(function()
            while autoUpg do
                for i = 1, 50 do
                    pcall(function()
                        RepStorage:WaitForChild("Shared"):WaitForChild("Packages")
                            :WaitForChild("Network"):WaitForChild("rev_B_Upgrade"):FireServer(i)
                    end)
                    task.wait(0.05)
                end
                task.wait(5)
            end
        end)
    end,
})

V1Tab:Section({ Title = "Extra" })
V1Tab:Button({
    Title    = "God Mode (Invisible)",
    Callback = function()
        -- Method: sembunyikan semua part karakter -> server tidak bisa target
        -- + restore health tiap frame lewat Heartbeat
        local function applyGodMode(char)
            if not char then return end
            -- Buat semua part transparan (invisible)
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                    part.CanCollide   = false
                end
            end
            -- Lock health
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.MaxHealth = math.huge
                hum.Health    = math.huge
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                hum.BreakJointsOnDeath = false
                -- Kecuali HRP tetap solid buat movement
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CanCollide   = true
                    hrp.Transparency = 1
                end
            end
        end

        applyGodMode(LP.Character)

        -- Heartbeat: restore health terus
        RunService.Heartbeat:Connect(function()
            local char = LP.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.MaxHealth = math.huge
                hum.Health    = math.huge
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            end
        end)

        -- Auto reapply saat respawn
        LP.CharacterAdded:Connect(function(char)
            task.wait(0.3)
            applyGodMode(char)
        end)
    end,
})

-- ============================================================
-- AUTOFARM V2 (Scan + Select per Rarity + Walk Back jika skip)
-- ============================================================
local farmV2Active     = false
local selectedBrainrot = {}

local CATEGORIES = {
    { name = "OG",        list = {
        "Karkerkar Kurkur","Blackhole Goat","Compactoroni Daskaloni",
        "Cappuccino Clownino","Nucleoro Dinossauro","Los Noo My Hotspotsitos",
        "Chillin Chilli","Crazyone Pizaione","Corn Sahur","Meowl",
        "Strawberry Elephant",
    }},
    { name = "Secret",    list = {
        "Bombini Gusini","Castlino Fortini","Tuff Toucan","Fryuro","Burguro",
        "Guest666","Zibra Zubra Zibrallni","Cavallo Virtuoso",
        "Gorillo Watermelondrillo","Cocofanto Elefanto","Bambu Sahur",
    }},
    { name = "Divine",    list = {
        "WL","Girafa Celeste","Tralero Tralala","Tralalerita Tralala",
        "Peant Jarro","Dipperl Chiperini","Rexosaurus","1x1x1x1",
        "Matteo","Espresso Signora",
    }},
    { name = "Hacked",    list = {
        "Alessio","Tripi Tropi Tropa Tripa","Swag Soda","Stoppo Luminino",
        "Torrtuginni Dragonfrutini","Tictac Sahur","Cactus Pingo",
        "Los Primos Blue","La Vacca Saturno Saturnita","Agarrini La Palini",
        "Bottellini",
    }},
    { name = "Celestial", list = {
        "Dragonfrutina Dolphinita","Guerriro Digitale","Chicleteira Bicicleteira",
        "Pot Hotspot","Krupuk Pagi Pagi","Beluga Beluga","Tralaledon",
        "Anpali Babel","Ketchuru and Musturu","Los Primos",
        "Mastodontico Telepiedone",
    }},
    { name = "Eternal",   list = {
        "Ketupat Kepat","Professora 67","Astro Tim","Baba Yaga","Kicky",
    }},
}

local BRAINROT_SET = {}
for _, cat in ipairs(CATEGORIES) do
    for _, name in ipairs(cat.list) do
        BRAINROT_SET[name]     = true
        selectedBrainrot[name] = false
    end
end

local function scanDebris()
    local debris = workspace:FindFirstChild("Debris")
    if not debris then return nil end
    for _, child in ipairs(debris:GetChildren()) do
        if BRAINROT_SET[child.Name] then return child.Name end
        if child:IsA("Folder") or child:IsA("Model") then
            for _, inner in ipairs(child:GetChildren()) do
                if BRAINROT_SET[inner.Name] then return inner.Name end
            end
        end
    end
    return nil
end

local function doOneCycleV2(nextCycle)
    if not farmV2Active then return end
    local h = HRP()
    if not h then task.wait(1) nextCycle() return end

    -- 1. Teleport ke target
    zeroVel(h)
    h.CFrame = TARGET_CF
    task.wait(0.35)

    -- 2. Kick
    fireKick()

    -- 3. Scan Debris max 3 detik
    local matched = nil
    local tStart  = tick()
    repeat
        task.wait(0.08)
        if not farmV2Active then return end
        matched = scanDebris()
    until matched ~= nil or (tick() - tStart) > 3

    if not farmV2Active then return end

    -- 4. Brainrot yang kita mau: jalan ke target & lanjut
    if matched and selectedBrainrot[matched] then
        walkToTarget(function() return farmV2Active end, function()
            task.wait(0.1)
            nextCycle()
        end)
    else
        -- 5. Skip: jalan mundur -> tsunami kill -> respawn -> jalan ke target -> ulang
        walkBackThenRespawn(function() return farmV2Active end, function()
            task.wait(0.1)
            nextCycle()
        end)
    end
end

local function startLoopV2()
    if not farmV2Active then return end
    doOneCycleV2(function() task.spawn(startLoopV2) end)
end

-- UI V2: Dropdown multi-select per rarity
V2Tab:Section({ Title = "Select Brainrot per Rarity" })

for _, cat in ipairs(CATEGORIES) do
    V2Tab:Dropdown({
        Title     = cat.name,
        Values    = cat.list,
        Value     = {},
        Multi     = true,
        AllowNone = true,
        Callback  = function(selected)
            for _, name in ipairs(cat.list) do selectedBrainrot[name] = false end
            if type(selected) == "table" then
                for _, name in ipairs(selected) do selectedBrainrot[name] = true end
            end
        end,
    })
end

V2Tab:Section({ Title = "Control" })
V2Tab:Toggle({
    Title    = "AutoFarm V2 ON/OFF",
    Value    = false,
    Callback = function(val)
        farmV2Active = val
        if val then task.spawn(startLoopV2) else setAnalog(true) end
    end,
})

-- ============================================================
-- AUTOTRAIN
-- ============================================================
local autoTrainEnabled = false
local weightList = {
    "Giant Gold Star Barbell","Golden Barbell","Bone Barbell",
    "Copper Plate","Donut Barbell","Emerald Barbell",
    "Heaven Plate","Ice Barbell","Iron Plate",
    "Mega Golden Barbell","Neon Pulse","Stone Block","Wooden Stick",
}
local weightSet = {}
for _, w in ipairs(weightList) do weightSet[w] = true end

local function autoEquipWeight()
    local char     = LP.Character
    local backpack = LP:FindFirstChild("Backpack")
    if not char or not backpack then return end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and not weightSet[obj.Name] then obj.Parent = backpack end
    end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and weightSet[obj.Name] then return end
    end
    for _, tool in ipairs(backpack:GetChildren()) do
        if weightSet[tool.Name] then tool.Parent = char return end
    end
end

local function runAutoTrain()
    local remote = nil
    pcall(function()
        remote = RepStorage:WaitForChild("Shared"):WaitForChild("Packages")
            :WaitForChild("Network"):WaitForChild("rev_TaviMishkal")
    end)
    while autoTrainEnabled do
        autoEquipWeight()
        if remote then
            pcall(function() remote:FireServer() end)
            pcall(function() remote:FireServer() end)
        end
        pcall(function()
            local gui = LP.PlayerGui:FindFirstChild("KickUpgrades")
            if not gui then return end
            local bonuses = {}
            for _, c in ipairs(gui:GetChildren()) do
                if c.Name == "Bonus" then bonuses[#bonuses+1] = c end
            end
            if #bonuses == 0 then return end
            local btn = bonuses[#bonuses]
            if firesignal then
                firesignal(btn.MouseButton1Click)
                firesignal(btn.Activated)
            else
                pcall(function() btn:SimulateClick() end)
            end
        end)
        task.wait(0.02)
    end
end

TrainTab:Section({ Title = "Train" })
TrainTab:Toggle({
    Title    = "Auto Train + Bonus",
    Value    = false,
    Callback = function(val)
        autoTrainEnabled = val
        if val then
            task.spawn(runAutoTrain)
        else
            local char     = LP.Character
            local backpack = LP:FindFirstChild("Backpack")
            if char and backpack then
                for _, obj in ipairs(char:GetChildren()) do
                    if obj:IsA("Tool") and weightSet[obj.Name] then obj.Parent = backpack end
                end
            end
        end
    end,
})

-- ============================================================
-- PLAYER
-- ============================================================
local wsEnabled = false
local wsValue   = 16
local jpEnabled = false
local jpValue   = 50
local noclip    = false
local infjump   = false

PlayerTab:Section({ Title = "WalkSpeed" })
PlayerTab:Toggle({ Title = "Enable WalkSpeed", Value = false, Callback = function(v) wsEnabled = v end })
PlayerTab:Slider({ Title = "WalkSpeed", Step = 1, Value = { Min = 16, Max = 150, Default = 16 }, Callback = function(v) wsValue = v end })

PlayerTab:Section({ Title = "JumpPower" })
PlayerTab:Toggle({ Title = "Enable JumpPower", Value = false, Callback = function(v) jpEnabled = v end })
PlayerTab:Slider({ Title = "JumpPower", Step = 1, Value = { Min = 50, Max = 300, Default = 50 }, Callback = function(v) jpValue = v end })

PlayerTab:Section({ Title = "Movement" })
PlayerTab:Toggle({ Title = "No Clip",       Value = false, Callback = function(v) noclip  = v end })
PlayerTab:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(v) infjump = v end })

RunService.RenderStepped:Connect(function()
    if not wsEnabled or farmV1 or farmV2Active then return end
    local char = LP.Character if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    hum.WalkSpeed = wsValue
    if hum.MoveDirection.Magnitude > 0 then
        hrp.Velocity = Vector3.new(hum.MoveDirection.X * wsValue, hrp.Velocity.Y, hum.MoveDirection.Z * wsValue)
    end
end)

RunService.RenderStepped:Connect(function()
    if not jpEnabled then return end
    local char = LP.Character if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.UseJumpPower = true hum.JumpPower = jpValue end
end)

RunService.Stepped:Connect(function()
    if not noclip then return end
    local char = LP.Character if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then v.CanCollide = false end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if not infjump then return end
    local char = LP.Character if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ============================================================
-- MISC
-- ============================================================
MiscTab:Section({ Title = "Server" })
MiscTab:Button({
    Title    = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end,
})
MiscTab:Section({ Title = "UI" })
MiscTab:Button({
    Title    = "Destroy UI",
    Callback = function() WindUI:Destroy() end,
})

-- Anti AFK
for _, v in pairs(getconnections(LP.Idled)) do v:Disable() end

print("FALTIX HUB LOADED")
