if _G.FaltixHubLoaded then return end
_G.FaltixHubLoaded = true

-- Services
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local RepStorage       = game:GetService("ReplicatedStorage")

local LP         = Players.LocalPlayer
local MyUsername = LP.Name

-- Helpers
local function getChar()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function HRP()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function HUM()
    return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
end

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

-- WindUI
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

-- Tabs
local HomeTab   = Window:Tab({ Title = "Home",        Icon = "house"    })
local V1Tab     = Window:Tab({ Title = "AutoFarm V1", Icon = "sword"    })
local V2Tab     = Window:Tab({ Title = "AutoFarm V2", Icon = "zap"      })
local TrainTab  = Window:Tab({ Title = "AutoTrain",   Icon = "activity" })
local PlayerTab = Window:Tab({ Title = "Player",      Icon = "user"     })
local MiscTab   = Window:Tab({ Title = "Misc",        Icon = "settings" })

-- ==============================================
-- HOME
-- ==============================================
HomeTab:Section({ Title = "Faltix Hub" })
HomeTab:Label({ Title = "AutoFarm V1 | AutoFarm V2 | AutoTrain" })
HomeTab:Label({ Title = "WindUI - Theme Crimson" })

-- ==============================================
-- AUTOFARM V1
-- ==============================================
local farmV1      = false
local autoCash    = false
local autoUpgrade = false

V1Tab:Section({ Title = "Farm" })

V1Tab:Toggle({
    Title    = "Perfect Kick + Auto Farm",
    Default  = false,
    Callback = function(v)
        farmV1 = v
        if not v then return end
        task.spawn(function()
            while farmV1 do
                local char     = getChar()
                local hrp      = char:WaitForChild("HumanoidRootPart")
                local hum      = char:WaitForChild("Humanoid")
                local targetCF = CFrame.new(699.39, 2.99, 233.38)

                hrp.CFrame = targetCF
                task.wait(0.4)

                pcall(function()
                    RepStorage
                        :WaitForChild("Shared")
                        :WaitForChild("Packages")
                        :WaitForChild("Network")
                        :WaitForChild("rev_KickEvent")
                        :FireServer(1, 1)
                end)

                repeat
                    RunService.Heartbeat:Wait()
                    if not farmV1 then return end
                    local y = hrp.Position.Y
                    if y <= -6.9 and y >= -8.2 then break end
                until false

                repeat
                    RunService.Heartbeat:Wait()
                    if not farmV1 then return end
                    local pos = hrp.Position
                    hrp.CFrame = CFrame.new(pos.X, 2.99, pos.Z)
                until math.abs(hrp.Position.Y - 2.99) <= 0.15

                repeat
                    RunService.Heartbeat:Wait()
                    if not farmV1 then return end
                    local pos      = hrp.Position
                    local t2D      = Vector3.new(targetCF.Position.X, 0, targetCF.Position.Z)
                    local c2D      = Vector3.new(pos.X, 0, pos.Z)
                    local dist     = (c2D - t2D).Magnitude
                    if dist <= 4 then break end
                    local dir      = (t2D - c2D).Unit
                    hrp.Velocity   = Vector3.new(dir.X * 40, 0, dir.Z * 40)
                    hrp.CFrame     = CFrame.new(pos.X, 2.99, pos.Z)
                    hum:MoveTo(targetCF.Position)
                until false

                task.wait(1)
            end
        end)
    end
})

V1Tab:Section({ Title = "Collect & Upgrade" })

V1Tab:Toggle({
    Title    = "Auto Collect Cash",
    Default  = false,
    Callback = function(v)
        autoCash = v
        if not v then return end
        task.spawn(function()
            while autoCash do
                for i = 1, 50 do
                    pcall(function()
                        RepStorage
                            :WaitForChild("Shared")
                            :WaitForChild("Packages")
                            :WaitForChild("Network")
                            :WaitForChild("rev_B_Collect")
                            :FireServer(i)
                    end)
                    task.wait(0.05)
                end
                task.wait(3)
            end
        end)
    end
})

V1Tab:Toggle({
    Title    = "Auto Upgrade Brainrot",
    Default  = false,
    Callback = function(v)
        autoUpgrade = v
        if not v then return end
        task.spawn(function()
            while autoUpgrade do
                for i = 1, 50 do
                    pcall(function()
                        RepStorage
                            :WaitForChild("Shared")
                            :WaitForChild("Packages")
                            :WaitForChild("Network")
                            :WaitForChild("rev_B_Upgrade")
                            :FireServer(i)
                    end)
                    task.wait(0.05)
                end
                task.wait(5)
            end
        end)
    end
})

V1Tab:Section({ Title = "Extra" })

V1Tab:Button({
    Title    = "God Mode",
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/tA8rFr6j"))()
    end
})

-- ==============================================
-- AUTOFARM V2
-- ==============================================
local farmV2Active     = false
local selectedBrainrot = {}
local walkConn         = nil

local TARGET_CF = CFrame.new(
    690.649963, 3.000007, 232.611252,
    -0.054131, 0,  0.998534,
    0,          1,  0,
    -0.998534,  0, -0.054131
)
do
    local _,_,_,a,b,c,d,e,f,g,h,i = TARGET_CF:GetComponents()
    TARGET_CF = CFrame.new(
        690.649963, 3.000007, 232.611252,
        a,b,c,d,e,f,g,h,i
    )
end
local TARGET_ROT do
    local _,_,_,a,b,c,d,e,f,g,h,i = TARGET_CF:GetComponents()
    TARGET_ROT = CFrame.new(0,0,0,a,b,c,d,e,f,g,h,i)
end

-- Brainrot list per kategori
local CATEGORIES = {
    {
        name = "OG Brainrot",
        list = {
            "Karkerkar Kurkur","Blackhole Goat","Compactoroni Daskaloni",
            "Cappuccino Clownino","Nucleoro Dinossauro","Los Noo My Hotspotsitos",
            "Chillin Chilli","Crazyone Pizaione","Corn Sahur","Meowl",
            "Strawberry Elephant",
        }
    },
    {
        name = "Secret Brainrot",
        list = {
            "Bombini Gusini","Castlino Fortini","Tuff Toucan","Fryuro","Burguro",
            "Guest666","Zibra Zubra Zibrallni","Cavallo Virtuoso",
            "Gorillo Watermelondrillo","Cocofanto Elefanto","Bambu Sahur",
        }
    },
    {
        name = "Divine Brainrot",
        list = {
            "WL","Girafa Celeste","Tralero Tralala","Tralalerita Tralala",
            "Peant Jarro","Dipperl Chiperini","Rexosaurus","1x1x1x1",
            "Matteo","Espresso Signora",
        }
    },
    {
        name = "HACKED Brainrot",
        list = {
            "Alessio","Tripi Tropi Tropa Tripa","Swag Soda","Stoppo Luminino",
            "Torrtuginni Dragonfrutini","Tictac Sahur","Cactus Pingo",
            "Los Primos Blue","La Vacca Saturno Saturnita","Agarrini La Palini",
            "Bottellini",
        }
    },
    {
        name = "Celestial Brainrot",
        list = {
            "Dragonfrutina Dolphinita","Guerriro Digitale","Chicleteira Bicicleteira",
            "Pot Hotspot","Krupuk Pagi Pagi","Beluga Beluga","Tralaledon",
            "Anpali Babel","Ketchuru and Musturu","Los Primos",
            "Mastodontico Telepiedone",
        }
    },
    {
        name = "Eternal",
        list = {
            "Ketupat Kepat","Professora 67","Astro Tim","Baba Yaga","Kicky",
        }
    },
}

-- Build lookup set untuk deteksi cepat
local BRAINROT_SET = {}
for _, cat in ipairs(CATEGORIES) do
    for _, name in ipairs(cat.list) do
        BRAINROT_SET[name] = true
    end
end

-- Deteksi brainrot di Workspace.Debris
-- Model langsung ada di dalam Debris sebagai children
-- Nama model = nama brainrot (exact match)
local function scanDebris()
    local debris = workspace:FindFirstChild("Debris")
    if not debris then return nil end

    for _, child in ipairs(debris:GetChildren()) do
        -- Cek langsung nama child
        if BRAINROT_SET[child.Name] then
            return child.Name
        end
        -- Jika child adalah folder/model yang punya children lagi
        if child:IsA("Folder") or child:IsA("Model") then
            for _, inner in ipairs(child:GetChildren()) do
                if BRAINROT_SET[inner.Name] then
                    return inner.Name
                end
            end
        end
    end
    return nil
end

local function walkToTargetV2(onDone)
    if walkConn then walkConn:Disconnect() end
    setAnalog(false)
    local tPos = TARGET_CF.Position

    walkConn = RunService.Heartbeat:Connect(function(dt)
        if not farmV2Active then
            walkConn:Disconnect()
            setAnalog(true)
            onDone()
            return
        end
        local h   = HRP()
        local hum = HUM()
        if not h or not hum then
            walkConn:Disconnect()
            setAnalog(true)
            onDone()
            return
        end

        local pos  = h.Position
        local dx   = tPos.X - pos.X
        local dz   = tPos.Z - pos.Z
        local dist = math.sqrt(dx*dx + dz*dz)

        if dist < 0.6 then
            zeroVel(h)
            h.CFrame = CFrame.new(tPos.X, pos.Y, tPos.Z) * TARGET_ROT
            walkConn:Disconnect()
            setAnalog(true)
            onDone()
            return
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
end

local function doOneCycleV2(nextCycle)
    if not farmV2Active then return end

    local h = HRP()
    if not h then task.wait(1) nextCycle() return end

    -- TP + kick
    zeroVel(h)
    h.CFrame = TARGET_CF
    task.wait(0.35)

    pcall(function()
        RepStorage
            :WaitForChild("Shared",        5)
            :WaitForChild("Packages",      5)
            :WaitForChild("Network",       5)
            :WaitForChild("rev_KickEvent", 5)
            :FireServer(1, 1)
    end)

    -- Scan debris max 3 detik
    local matched = nil
    local tStart  = tick()
    repeat
        task.wait(0.08)
        if not farmV2Active then return end
        matched = scanDebris()
    until matched ~= nil or (tick() - tStart) > 3

    if not farmV2Active then return end

    if matched and selectedBrainrot[matched] then
        -- Brainrot yang kita mau: jalan ke target
        walkToTargetV2(function()
            task.wait(0.1)
            nextCycle()
        end)
    else
        -- Skip
        task.wait(0.25)
        nextCycle()
    end
end

local function startLoopV2()
    if not farmV2Active then return end
    doOneCycleV2(function()
        task.spawn(startLoopV2)
    end)
end

-- UI V2: toggle pilih brainrot per kategori
for _, cat in ipairs(CATEGORIES) do
    V2Tab:Section({ Title = cat.name })
    for _, brainrotName in ipairs(cat.list) do
        selectedBrainrot[brainrotName] = false
        V2Tab:Toggle({
            Title    = brainrotName,
            Default  = false,
            Callback = function(val)
                selectedBrainrot[brainrotName] = val
            end,
        })
    end
end

V2Tab:Section({ Title = "Control" })

V2Tab:Toggle({
    Title    = "AutoFarm V2 ON/OFF",
    Default  = false,
    Callback = function(val)
        farmV2Active = val
        if val then
            task.spawn(startLoopV2)
        else
            setAnalog(true)
            if walkConn then walkConn:Disconnect() end
        end
    end,
})

-- ==============================================
-- AUTOTRAIN
-- ==============================================
local autoTrainEnabled = false

local weightList = {
    "Giant Gold Star Barbell","Golden Barbell","Bone Barbell",
    "Copper Plate","Donut Barbell","Emerald Barbell",
    "Heaven Plate","Ice Barbell","Iron Plate",
    "Mega Golden Barbell","Neon Pulse","Stone Block","Wooden Stick",
}

local function autoEquipWeight()
    local char     = LP.Character
    local backpack = LP:FindFirstChild("Backpack")
    if not char or not backpack then return end

    local weightSet = {}
    for _, w in ipairs(weightList) do weightSet[w] = true end

    -- Unequip semua tool yang bukan weight
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and not weightSet[obj.Name] then
            obj.Parent = backpack
        end
    end

    -- Cek apakah sudah pegang weight
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and weightSet[obj.Name] then return end
    end

    -- Equip weight dari backpack
    for _, tool in ipairs(backpack:GetChildren()) do
        if weightSet[tool.Name] then
            tool.Parent = char
            return
        end
    end
end

local function runAutoTrain()
    local remote = nil
    pcall(function()
        remote = RepStorage
            :WaitForChild("Shared")
            :WaitForChild("Packages")
            :WaitForChild("Network")
            :WaitForChild("rev_TaviMishkal")
    end)

    while autoTrainEnabled do
        autoEquipWeight()

        if remote then
            pcall(function() remote:FireServer() end)
            pcall(function() remote:FireServer() end)
        end

        -- Klik bonus terakhir di KickUpgrades
        pcall(function()
            local gui = LP.PlayerGui:FindFirstChild("KickUpgrades")
            if not gui then return end
            local bonuses = {}
            for _, c in ipairs(gui:GetChildren()) do
                if c.Name == "Bonus" then
                    bonuses[#bonuses+1] = c
                end
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
    Default  = false,
    Callback = function(val)
        autoTrainEnabled = val
        if val then
            task.spawn(runAutoTrain)
        else
            -- Turunkan semua weight ke backpack
            local char     = LP.Character
            local backpack = LP:FindFirstChild("Backpack")
            if char and backpack then
                local weightSet = {}
                for _, w in ipairs(weightList) do weightSet[w] = true end
                for _, obj in ipairs(char:GetChildren()) do
                    if obj:IsA("Tool") and weightSet[obj.Name] then
                        obj.Parent = backpack
                    end
                end
            end
        end
    end,
})

-- ==============================================
-- PLAYER
-- ==============================================
local wsEnabled = false
local wsValue   = 16
local jpEnabled = false
local jpValue   = 50
local noclip    = false
local infjump   = false

PlayerTab:Section({ Title = "WalkSpeed" })

PlayerTab:Toggle({
    Title    = "Enable WalkSpeed",
    Default  = false,
    Callback = function(v) wsEnabled = v end,
})

PlayerTab:Slider({
    Title    = "WalkSpeed",
    Step     = 1,
    Value    = { Min = 16, Max = 150, Default = 16 },
    Callback = function(v) wsValue = v end,
})

PlayerTab:Section({ Title = "JumpPower" })

PlayerTab:Toggle({
    Title    = "Enable JumpPower",
    Default  = false,
    Callback = function(v) jpEnabled = v end,
})

PlayerTab:Slider({
    Title    = "JumpPower",
    Step     = 1,
    Value    = { Min = 50, Max = 300, Default = 50 },
    Callback = function(v) jpValue = v end,
})

PlayerTab:Section({ Title = "Movement" })

PlayerTab:Toggle({
    Title    = "No Clip",
    Default  = false,
    Callback = function(v) noclip = v end,
})

PlayerTab:Toggle({
    Title    = "Infinite Jump",
    Default  = false,
    Callback = function(v) infjump = v end,
})

-- RenderStepped: WalkSpeed
RunService.RenderStepped:Connect(function()
    if not wsEnabled then return end
    if farmV1 or farmV2Active then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    hum.WalkSpeed = wsValue
    if hum.MoveDirection.Magnitude > 0 then
        hrp.Velocity = Vector3.new(
            hum.MoveDirection.X * wsValue,
            hrp.Velocity.Y,
            hum.MoveDirection.Z * wsValue
        )
    end
end)

-- RenderStepped: JumpPower
RunService.RenderStepped:Connect(function()
    if not jpEnabled then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.UseJumpPower = true
    hum.JumpPower    = jpValue
end)

-- Stepped: NoClip
RunService.Stepped:Connect(function()
    if not noclip then return end
    local char = LP.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if not infjump then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ==============================================
-- MISC
-- ==============================================
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
    Callback = function()
        WindUI:Destroy()
    end,
})

-- ==============================================
-- ANTI AFK
-- ==============================================
for _, v in pairs(getconnections(LP.Idled)) do
    v:Disable()
end

print("FALTIX HUB LOADED")
