-- KALNZ HUB v1.0
-- Rebuilt from NamelessHub | Wind-style UI
-- by Kalmz

if _G.KalnzHubLoaded then return end
_G.KalnzHubLoaded = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChild("Humanoid")
local root = character:FindFirstChild("HumanoidRootPart")
if not (humanoid and root) then return end

-- ════════════════════════════════════════
-- SETTINGS
-- ════════════════════════════════════════
local settingsFile = "KalnzHubSettings.json"
local defaultSettings = {
    walkspeedEnabled = false,
    currentWalkSpeed = 80,
    infiniteJumpEnabled = false,
    boostJumpEnabled = false,
    currentBoostStrength = 150,
    espEnabled = false,
    timerEspEnabled = false,
    webSlingerAutoAimEnabled = false,
    antiTrapEnabled = false,
    antiHitEnabled = false,
    brainrotEspEnabled = false,
    flingEnabled = false,
    guiPosition = {0, 20, 0.5, -25}
}

local function saveSettings(s)
    pcall(function() writefile(settingsFile, HttpService:JSONEncode(s)) end)
end

local function loadSettings()
    if isfile(settingsFile) then
        local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(settingsFile)) end)
        if ok and decoded then
            for k, v in pairs(defaultSettings) do
                if decoded[k] == nil then decoded[k] = v end
            end
            return decoded
        end
    end
    return defaultSettings
end

local cfg = loadSettings()

-- ════════════════════════════════════════
-- DESTROY OLD GUI
-- ════════════════════════════════════════
local oldGui = PlayerGui:FindFirstChild("KalnzHubGui")
if oldGui then oldGui:Destroy() end

-- ════════════════════════════════════════
-- THEME
-- ════════════════════════════════════════
local T = {
    BG       = Color3.fromRGB(12, 12, 16),
    Panel    = Color3.fromRGB(18, 18, 24),
    Card     = Color3.fromRGB(26, 26, 34),
    CardHov  = Color3.fromRGB(34, 34, 46),
    Accent   = Color3.fromRGB(99, 102, 241),   -- indigo
    AccentDim= Color3.fromRGB(67, 70, 180),
    Green    = Color3.fromRGB(52, 211, 153),
    Red      = Color3.fromRGB(248, 113, 113),
    Text     = Color3.fromRGB(240, 240, 255),
    TextDim  = Color3.fromRGB(140, 140, 170),
    Border   = Color3.fromRGB(40, 40, 58),
    Pill     = Color3.fromRGB(99, 102, 241),
}

-- ════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════
local walkspeedEnabled        = cfg.walkspeedEnabled
local walkspeedConnection     = nil
local flingEnabled            = cfg.flingEnabled
local flingConnection         = nil
local espEnabled              = cfg.espEnabled
local espConnections          = {}
local espBillboards           = {}
local timerEspEnabled         = cfg.timerEspEnabled
local activeConnections       = {}
local webSlingerAutoAimEnabled= cfg.webSlingerAutoAimEnabled
local webSlingerConnection    = nil
local infiniteJumpEnabled     = cfg.infiniteJumpEnabled
local infiniteJumpConnection  = nil
local boostJumpEnabled        = cfg.boostJumpEnabled
local boostJumpConnections    = {}
local currentWalkSpeed        = cfg.currentWalkSpeed
local currentBoostStrength    = cfg.currentBoostStrength
local antiTrapEnabled         = cfg.antiTrapEnabled
local antiTrapConnection      = nil
local antiHitEnabled          = cfg.antiHitEnabled
local brainrotEspEnabled      = cfg.brainrotEspEnabled
local currentBase             = nil
local currentStatGui          = nil

-- ════════════════════════════════════════
-- SCREEN GUI
-- ════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KalnzHubGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- ════════════════════════════════════════
-- HELPER: TWEEN SHORTCUT
-- ════════════════════════════════════════
local function tween(obj, t, props, style, dir)
    style = style or Enum.EasingStyle.Quint
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t, style, dir), props):Play()
end

local function corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 10)
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or T.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=dur or 2})
    end)
end

-- ════════════════════════════════════════
-- FLOATING PILL BUTTON
-- ════════════════════════════════════════
local pillFrame = Instance.new("Frame")
pillFrame.Name = "KH_Pill"
pillFrame.Size = UDim2.new(0, 110, 0, 38)
pillFrame.Position = UDim2.new(cfg.guiPosition[1], cfg.guiPosition[2], cfg.guiPosition[3], cfg.guiPosition[4])
pillFrame.AnchorPoint = Vector2.new(0, 0.5)
pillFrame.BackgroundColor3 = T.Pill
pillFrame.BorderSizePixel = 0
pillFrame.Parent = screenGui
corner(pillFrame, 19)

-- glow effect
local pillGlow = Instance.new("ImageLabel", pillFrame)
pillGlow.Size = UDim2.new(1, 30, 1, 30)
pillGlow.Position = UDim2.new(0, -15, 0, -15)
pillGlow.BackgroundTransparency = 1
pillGlow.Image = "rbxassetid://5028857084"
pillGlow.ImageColor3 = T.Accent
pillGlow.ImageTransparency = 0.6
pillGlow.ZIndex = 0

local pillIcon = Instance.new("TextLabel", pillFrame)
pillIcon.Size = UDim2.new(0, 32, 1, 0)
pillIcon.Position = UDim2.new(0, 8, 0, 0)
pillIcon.BackgroundTransparency = 1
pillIcon.Text = "⚡"
pillIcon.TextScaled = true
pillIcon.Font = Enum.Font.GothamBold
pillIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
pillIcon.ZIndex = 3

local pillText = Instance.new("TextLabel", pillFrame)
pillText.Size = UDim2.new(1, -44, 1, 0)
pillText.Position = UDim2.new(0, 38, 0, 0)
pillText.BackgroundTransparency = 1
pillText.Text = "KH"
pillText.TextScaled = true
pillText.Font = Enum.Font.GothamBold
pillText.TextColor3 = Color3.fromRGB(255, 255, 255)
pillText.ZIndex = 3

local pillButton = Instance.new("TextButton", pillFrame)
pillButton.Size = UDim2.new(1, 0, 1, 0)
pillButton.BackgroundTransparency = 1
pillButton.Text = ""
pillButton.ZIndex = 4

-- drag pill
local dragging, dragStart, startPos = false, nil, nil
pillButton.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inp.Position
        startPos = pillFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - dragStart
        local np = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        pillFrame.Position = np
        cfg.guiPosition = {np.X.Scale, np.X.Offset, np.Y.Scale, np.Y.Offset}
        saveSettings(cfg)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ════════════════════════════════════════
-- MAIN PANEL
-- ════════════════════════════════════════
local panel = Instance.new("Frame")
panel.Name = "KH_Panel"
panel.Size = UDim2.new(0, 360, 0, 440)
panel.Position = UDim2.new(0, 140, 0.5, -220)
panel.BackgroundColor3 = T.BG
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Visible = false
panel.Parent = screenGui
corner(panel, 14)
stroke(panel, T.Border, 1)

-- ── panel header ──
local header = Instance.new("Frame", panel)
header.Size = UDim2.new(1, 0, 0, 54)
header.BackgroundColor3 = T.Panel
header.BorderSizePixel = 0
corner(header, 14)

-- fix bottom corners of header
local headerBot = Instance.new("Frame", header)
headerBot.Size = UDim2.new(1, 0, 0, 14)
headerBot.Position = UDim2.new(0, 0, 1, -14)
headerBot.BackgroundColor3 = T.Panel
headerBot.BorderSizePixel = 0

local hIcon = Instance.new("TextLabel", header)
hIcon.Size = UDim2.new(0, 36, 0, 36)
hIcon.Position = UDim2.new(0, 12, 0, 9)
hIcon.BackgroundColor3 = T.Accent
hIcon.Text = "⚡"
hIcon.TextScaled = true
hIcon.Font = Enum.Font.GothamBold
hIcon.TextColor3 = Color3.fromRGB(255,255,255)
corner(hIcon, 10)

local hTitle = Instance.new("TextLabel", header)
hTitle.Size = UDim2.new(0, 150, 0, 22)
hTitle.Position = UDim2.new(0, 56, 0, 9)
hTitle.BackgroundTransparency = 1
hTitle.Text = "KALNZ HUB"
hTitle.Font = Enum.Font.GothamBold
hTitle.TextSize = 16
hTitle.TextColor3 = T.Text
hTitle.TextXAlignment = Enum.TextXAlignment.Left

local hSub = Instance.new("TextLabel", header)
hSub.Size = UDim2.new(0, 150, 0, 16)
hSub.Position = UDim2.new(0, 57, 0, 30)
hSub.BackgroundTransparency = 1
hSub.Text = "v1.0 | Wind UI"
hSub.Font = Enum.Font.Gotham
hSub.TextSize = 11
hSub.TextColor3 = T.TextDim
hSub.TextXAlignment = Enum.TextXAlignment.Left

-- close button
local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0, 13)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.TextColor3 = T.Red
closeBtn.BorderSizePixel = 0
corner(closeBtn, 8)

-- ── tab bar ──
local tabBar = Instance.new("Frame", panel)
tabBar.Size = UDim2.new(1, -16, 0, 34)
tabBar.Position = UDim2.new(0, 8, 0, 60)
tabBar.BackgroundColor3 = T.Panel
tabBar.BorderSizePixel = 0
corner(tabBar, 8)
stroke(tabBar, T.Border, 1)

local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 2)

local tabPad = Instance.new("UIPadding", tabBar)
tabPad.PaddingLeft = UDim.new(0, 4)
tabPad.PaddingRight = UDim.new(0, 4)
tabPad.PaddingTop = UDim.new(0, 4)
tabPad.PaddingBottom = UDim.new(0, 4)

-- ── content area ──
local contentArea = Instance.new("Frame", panel)
contentArea.Size = UDim2.new(1, -16, 1, -108)
contentArea.Position = UDim2.new(0, 8, 0, 102)
contentArea.BackgroundTransparency = 1

-- ════════════════════════════════════════
-- TAB SYSTEM
-- ════════════════════════════════════════
local tabs = {}
local tabPages = {}
local activeTab = nil

local TAB_DEFS = {"Main", "ESP", "Settings", "Info"}

local function createTabBtn(name, order)
    local btn = Instance.new("TextButton", tabBar)
    btn.Size = UDim2.new(0.25, -3, 1, 0)
    btn.BackgroundColor3 = T.Panel
    btn.Text = name
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextColor3 = T.TextDim
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    corner(btn, 6)

    -- page
    local page = Instance.new("ScrollingFrame", contentArea)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = T.Accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false

    local layout = Instance.new("UIListLayout", page)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)

    tabs[name] = btn
    tabPages[name] = page

    btn.MouseButton1Click:Connect(function()
        if activeTab == name then return end
        -- deactivate old
        if activeTab then
            tween(tabs[activeTab], 0.2, {BackgroundColor3 = T.Panel, TextColor3 = T.TextDim})
            tabPages[activeTab].Visible = false
        end
        activeTab = name
        tween(btn, 0.2, {BackgroundColor3 = T.Accent, TextColor3 = Color3.fromRGB(255,255,255)})
        page.Visible = true
    end)

    return btn, page
end

for i, name in ipairs(TAB_DEFS) do
    createTabBtn(name, i)
end

-- ════════════════════════════════════════
-- WIDGET BUILDERS
-- ════════════════════════════════════════
local function sectionLabel(page, text)
    local f = Instance.new("Frame", page)
    f.Size = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1
    f.LayoutOrder = 0

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  " .. text:upper()
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = T.Accent
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return f
end

local widgetOrder = {}
local function nextOrder(page)
    widgetOrder[page] = (widgetOrder[page] or 0) + 1
    return widgetOrder[page]
end

local function makeToggle(page, labelText, initState, onEnable, onDisable)
    local card = Instance.new("Frame", page)
    card.Size = UDim2.new(1, 0, 0, 44)
    card.BackgroundColor3 = T.Card
    card.BorderSizePixel = 0
    card.LayoutOrder = nextOrder(page)
    corner(card, 8)

    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    -- toggle track
    local track = Instance.new("Frame", card)
    track.Size = UDim2.new(0, 44, 0, 24)
    track.Position = UDim2.new(1, -56, 0.5, -12)
    track.BackgroundColor3 = initState and T.Green or T.CardHov
    track.BorderSizePixel = 0
    corner(track, 12)

    local thumb = Instance.new("Frame", track)
    thumb.Size = UDim2.new(0, 18, 0, 18)
    thumb.Position = initState and UDim2.new(0, 23, 0, 3) or UDim2.new(0, 3, 0, 3)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    corner(thumb, 9)

    local state = initState
    local hitbox = Instance.new("TextButton", card)
    hitbox.Size = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""

    hitbox.MouseButton1Click:Connect(function()
        state = not state
        if state then
            tween(track, 0.25, {BackgroundColor3 = T.Green})
            tween(thumb, 0.25, {Position = UDim2.new(0, 23, 0, 3)})
            onEnable()
        else
            tween(track, 0.25, {BackgroundColor3 = T.CardHov})
            tween(thumb, 0.25, {Position = UDim2.new(0, 3, 0, 3)})
            onDisable()
        end
    end)

    hitbox.MouseEnter:Connect(function()
        tween(card, 0.15, {BackgroundColor3 = T.CardHov})
    end)
    hitbox.MouseLeave:Connect(function()
        tween(card, 0.15, {BackgroundColor3 = T.Card})
    end)

    return card, function(s)
        state = s
        if s then
            tween(track, 0.25, {BackgroundColor3 = T.Green})
            tween(thumb, 0.25, {Position = UDim2.new(0, 23, 0, 3)})
        else
            tween(track, 0.25, {BackgroundColor3 = T.CardHov})
            tween(thumb, 0.25, {Position = UDim2.new(0, 3, 0, 3)})
        end
    end
end

local function makeSlider(page, labelText, min, max, default, onChange)
    local card = Instance.new("Frame", page)
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = T.Card
    card.BorderSizePixel = 0
    card.LayoutOrder = nextOrder(page)
    corner(card, 8)

    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(0.7, 0, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", card)
    valLbl.Size = UDim2.new(0.3, -12, 0, 20)
    valLbl.Position = UDim2.new(0.7, 0, 0, 8)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextColor3 = T.Accent
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame", card)
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 38)
    track.BackgroundColor3 = T.CardHov
    track.BorderSizePixel = 0
    corner(track, 3)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = T.Accent
    fill.BorderSizePixel = 0
    corner(fill, 3)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    corner(knob, 7)

    local sliding = false
    local hitbox = Instance.new("TextButton", track)
    hitbox.Size = UDim2.new(1, 0, 0, 20)
    hitbox.Position = UDim2.new(0, 0, 0.5, -10)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.ZIndex = 5

    local function updateSlider(inputPos)
        local trackAbsPos = track.AbsolutePosition
        local trackAbsSize = track.AbsoluteSize
        local relX = math.clamp((inputPos.X - trackAbsPos.X) / trackAbsSize.X, 0, 1)
        local val = math.floor(min + (max - min) * relX)
        valLbl.Text = tostring(val)
        tween(fill, 0.05, {Size = UDim2.new(relX, 0, 1, 0)})
        tween(knob, 0.05, {Position = UDim2.new(relX, -7, 0.5, -7)})
        onChange(val)
    end

    hitbox.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateSlider(inp.Position)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(inp.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    return card
end

local function makeButton(page, labelText, color, onClick)
    color = color or T.Accent
    local card = Instance.new("Frame", page)
    card.Size = UDim2.new(1, 0, 0, 40)
    card.BackgroundColor3 = T.Card
    card.BorderSizePixel = 0
    card.LayoutOrder = nextOrder(page)
    corner(card, 8)

    local btn = Instance.new("TextButton", card)
    btn.Size = UDim2.new(1, -16, 0, 28)
    btn.Position = UDim2.new(0, 8, 0, 6)
    btn.BackgroundColor3 = color
    btn.Text = labelText
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BorderSizePixel = 0
    corner(btn, 6)

    btn.MouseButton1Click:Connect(onClick)
    btn.MouseEnter:Connect(function() tween(btn, 0.15, {BackgroundColor3 = Color3.new(color.R*1.15, color.G*1.15, color.B*1.15)}) end)
    btn.MouseLeave:Connect(function() tween(btn, 0.15, {BackgroundColor3 = color}) end)
    btn.MouseButton1Down:Connect(function() tween(btn, 0.1, {BackgroundColor3 = Color3.new(color.R*0.8, color.G*0.8, color.B*0.8)}) end)
    btn.MouseButton1Up:Connect(function() tween(btn, 0.15, {BackgroundColor3 = color}) end)

    return card
end

local function makeInfoCard(page, labelText, value)
    local card = Instance.new("Frame", page)
    card.Size = UDim2.new(1, 0, 0, 36)
    card.BackgroundColor3 = T.Card
    card.BorderSizePixel = 0
    card.LayoutOrder = nextOrder(page)
    corner(card, 8)

    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(0.55, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = T.TextDim
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local val = Instance.new("TextLabel", card)
    val.Size = UDim2.new(0.45, -12, 1, 0)
    val.Position = UDim2.new(0.55, 0, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = value
    val.Font = Enum.Font.GothamBold
    val.TextSize = 12
    val.TextColor3 = T.Text
    val.TextXAlignment = Enum.TextXAlignment.Right

    return card
end

-- ════════════════════════════════════════
-- FEATURE LOGIC (ported from NamelessHub)
-- ════════════════════════════════════════

-- WALKSPEED
local function disableWalkspeed()
    if walkspeedConnection then walkspeedConnection:Disconnect(); walkspeedConnection = nil end
    local char = player.Character
    if char then
        local r = char:FindFirstChild("HumanoidRootPart")
        if r then
            local vf = r:FindFirstChild("ConstantMoveForce")
            if vf then vf:Destroy() end
            local att = r:FindFirstChildOfClass("Attachment")
            if att then att:Destroy() end
        end
    end
    walkspeedEnabled = false; cfg.walkspeedEnabled = false; saveSettings(cfg)
end

local function enableWalkspeed()
    if walkspeedConnection then walkspeedConnection:Disconnect(); walkspeedConnection = nil end
    local char = player.Character or player.CharacterAdded:Wait()
    local r = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")
    local FORCE_MULTIPLIER, AIR_DRAG = 100, 0.9
    local att = Instance.new("Attachment", r)
    local vf = Instance.new("VectorForce")
    vf.Name = "ConstantMoveForce"
    vf.Attachment0 = att
    vf.RelativeTo = Enum.ActuatorRelativeTo.World
    vf.ApplyAtCenterOfMass = true
    vf.Force = Vector3.zero
    vf.Parent = r
    walkspeedConnection = RunService.RenderStepped:Connect(function()
        local md = hum.MoveDirection
        if md.Magnitude > 0 then
            local tv = md.Unit * currentWalkSpeed
            local cv = r.Velocity
            local fv = Vector3.new(cv.X, 0, cv.Z)
            local diff = tv - fv
            vf.Force = Vector3.new((diff * FORCE_MULTIPLIER - fv * AIR_DRAG).X, 0, (diff * FORCE_MULTIPLIER - fv * AIR_DRAG).Z)
        else
            vf.Force = Vector3.zero
        end
    end)
    walkspeedEnabled = true; cfg.walkspeedEnabled = true; saveSettings(cfg)
end

-- INFINITE JUMP
local function enableInfiniteJump()
    if infiniteJumpConnection then infiniteJumpConnection:Disconnect(); infiniteJumpConnection = nil end
    infiniteJumpEnabled = true
    infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            local hrp = char.HumanoidRootPart
            if char.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                hrp.Velocity = Vector3.new(hrp.Velocity.X, 50, hrp.Velocity.Z)
            end
        end
    end)
    cfg.infiniteJumpEnabled = true; saveSettings(cfg)
end

local function disableInfiniteJump()
    if infiniteJumpConnection then infiniteJumpConnection:Disconnect(); infiniteJumpConnection = nil end
    infiniteJumpEnabled = false; cfg.infiniteJumpEnabled = false; saveSettings(cfg)
end

-- BOOST JUMP
local function enableBoostJump()
    for _, c in pairs(boostJumpConnections) do c:Disconnect() end
    boostJumpConnections = {}
    boostJumpEnabled = true
    local canBoost = true
    boostJumpConnections["Stepped"] = RunService.Stepped:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            local st = char.Humanoid:GetState()
            canBoost = (st==Enum.HumanoidStateType.Running or st==Enum.HumanoidStateType.RunningNoPhysics or st==Enum.HumanoidStateType.Landed or st==Enum.HumanoidStateType.PlatformStanding)
        end
    end)
    boostJumpConnections["Jump"] = UserInputService.JumpRequest:Connect(function()
        if not canBoost then return end
        local char = player.Character
        if not (char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid")) then return end
        local hrp = char.HumanoidRootPart
        local moving = hrp.Velocity.Magnitude > 1
        local bv = Vector3.new(0, currentBoostStrength, 0)
        if moving then bv = bv + hrp.CFrame.LookVector * 50 end
        hrp.Velocity = bv; canBoost = false
    end)
    cfg.boostJumpEnabled = true; saveSettings(cfg)
end

local function disableBoostJump()
    for _, c in pairs(boostJumpConnections) do c:Disconnect() end
    boostJumpConnections = {}; boostJumpEnabled = false; cfg.boostJumpEnabled = false; saveSettings(cfg)
end

-- FLING
local function enableFling()
    flingEnabled = true
    pcall(function()
        local hum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.AutoJumpEnabled = false end
    end)
    if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
        local m = Instance.new("Decal"); m.Name = "juisdfj0i32i0eidsuf0iok"; m.Parent = ReplicatedStorage
    end
    flingConnection = RunService.Heartbeat:Connect(function()
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local v = hrp.Velocity
            hrp.Velocity = v * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = v
            RunService.Stepped:Wait()
            hrp.Velocity = v + Vector3.new(0, 0.1, 0)
        end
    end)
    cfg.flingEnabled = true; saveSettings(cfg)
end

local function disableFling()
    if flingConnection then flingConnection:Disconnect(); flingConnection = nil end
    flingEnabled = false; cfg.flingEnabled = false; saveSettings(cfg)
end

-- ANTI TRAP
local function enableAntiTrap()
    if antiTrapConnection then antiTrapConnection:Disconnect(); antiTrapConnection = nil end
    antiTrapEnabled = true
    antiTrapConnection = RunService.Heartbeat:Connect(function()
        local trap = workspace:FindFirstChild("Trap")
        if trap and trap:IsA("Model") then trap:Destroy() end
    end)
    cfg.antiTrapEnabled = true; saveSettings(cfg)
end

local function disableAntiTrap()
    if antiTrapConnection then antiTrapConnection:Disconnect(); antiTrapConnection = nil end
    antiTrapEnabled = false; cfg.antiTrapEnabled = false; saveSettings(cfg)
end

-- ESP
local function getRandomColor()
    return Color3.fromRGB(math.random(80, 255), math.random(80, 255), math.random(80, 255))
end

local function enableESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local h = p.Character:FindFirstChild("ESPHighlight"); if h then h:Destroy() end
            local bb = espBillboards[p]; if bb then bb:Destroy(); espBillboards[p] = nil end
        end
    end
    for _, c in pairs(espConnections) do c:Disconnect() end
    espConnections = {}; espEnabled = true

    local function addHighlight(p)
        if p == player or not p.Character then return end
        local rc = getRandomColor()
        local hl = Instance.new("Highlight"); hl.Name = "ESPHighlight"; hl.FillColor = rc
        hl.OutlineColor = rc; hl.FillTransparency = 0.35; hl.OutlineTransparency = 0
        hl.Adornee = p.Character; hl.Parent = p.Character
        local bb = Instance.new("BillboardGui"); bb.Name = "ESPName"
        bb.Adornee = p.Character:FindFirstChild("Head"); bb.Size = UDim2.new(0,100,0,50)
        bb.StudsOffset = Vector3.new(0,2,0); bb.AlwaysOnTop = true; bb.Parent = p.Character
        local nl = Instance.new("TextLabel", bb); nl.Size = UDim2.new(1,0,1,0)
        nl.BackgroundTransparency = 1; nl.Text = p.DisplayName
        nl.Font = Enum.Font.GothamBold; nl.TextSize = 14
        nl.TextColor3 = rc; nl.TextStrokeTransparency = 0.5
        espBillboards[p] = bb
    end

    for _, p in pairs(Players:GetPlayers()) do addHighlight(p) end
    table.insert(espConnections, Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function() task.wait(1); addHighlight(p) end)
    end))
    table.insert(espConnections, Players.PlayerRemoving:Connect(function(p)
        local bb = espBillboards[p]; if bb then bb:Destroy(); espBillboards[p] = nil end
    end))
    cfg.espEnabled = true; saveSettings(cfg)
end

local function disableESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local h = p.Character:FindFirstChild("ESPHighlight"); if h then h:Destroy() end
        end
        local bb = espBillboards[p]; if bb then bb:Destroy(); espBillboards[p] = nil end
    end
    for _, c in pairs(espConnections) do c:Disconnect() end
    espConnections = {}; espEnabled = false; cfg.espEnabled = false; saveSettings(cfg)
end

-- TIMER ESP (ported directly)
local function updateBillboard(base, contentText, highlight)
    local existing = base:FindFirstChild("RemainingTimeGui")
    if highlight and contentText and contentText ~= "" then
        if not existing then
            local bgui = Instance.new("BillboardGui"); bgui.Name = "RemainingTimeGui"
            bgui.Size = UDim2.new(0,120,0,40); bgui.StudsOffset = Vector3.new(0,6,0)
            bgui.AlwaysOnTop = true; bgui.Adornee = base; bgui.Parent = base
            local lbl = Instance.new("TextLabel", bgui); lbl.Name = "Text"
            lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
            lbl.Text = contentText; lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 14; lbl.TextColor3 = T.Green; lbl.TextStrokeTransparency = 0.5
        else
            local lbl = existing:FindFirstChild("Text"); if lbl then lbl.Text = contentText end
        end
    else
        if existing then existing:Destroy() end
    end
end

local function findLowestValidRemainingTime(purchases)
    local lowest, lowestY = nil, nil
    for _, p in pairs(purchases:GetChildren()) do
        local main = p:FindFirstChild("Main")
        local gui = main and main:FindFirstChild("BillboardGui")
        local remTime = gui and gui:FindFirstChild("RemainingTime")
        local locked = gui and gui:FindFirstChild("Locked")
        if main and remTime and locked and remTime:IsA("TextLabel") and locked:IsA("GuiObject") and locked.Visible then
            local y = main.Position.Y
            if not lowestY or y < lowestY then
                lowest = {remTime=remTime, locked=locked, main=main}; lowestY = y
            end
        end
    end
    return lowest
end

local function scanAndConnect()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, plot in pairs(plots:GetChildren()) do
        local purchases = plot:FindFirstChild("Purchases")
        if purchases then
            local selected = findLowestValidRemainingTime(purchases)
            for _, purchase in pairs(purchases:GetChildren()) do
                local main = purchase:FindFirstChild("Main")
                local gui = main and main:FindFirstChild("BillboardGui")
                local remTime = gui and gui:FindFirstChild("RemainingTime")
                local locked = gui and gui:FindFirstChild("Locked")
                if main and remTime and locked and remTime:IsA("TextLabel") and locked:IsA("GuiObject") then
                    local isTarget = selected and remTime == selected.remTime
                    updateBillboard(main, remTime.Text, isTarget)
                    local key = remTime:GetDebugId()
                    if isTarget and not activeConnections[key] then
                        local function refresh()
                            local stillTarget = (findLowestValidRemainingTime(purchases) or {}).remTime == remTime
                            updateBillboard(main, remTime.Text, stillTarget and locked.Visible)
                        end
                        activeConnections[key] = {
                            remTime:GetPropertyChangedSignal("Text"):Connect(refresh),
                            locked:GetPropertyChangedSignal("Visible"):Connect(refresh)
                        }
                    end
                end
            end
        end
    end
end

local function enableTimerESP()
    timerEspEnabled = true
    task.spawn(function()
        while timerEspEnabled do pcall(scanAndConnect); task.wait(5) end
    end)
    cfg.timerEspEnabled = true; saveSettings(cfg)
end

local function disableTimerESP()
    timerEspEnabled = false
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in pairs(plots:GetChildren()) do
            local purchases = plot:FindFirstChild("Purchases")
            if purchases then
                for _, p in pairs(purchases:GetChildren()) do
                    local main = p:FindFirstChild("Main")
                    if main then local g = main:FindFirstChild("RemainingTimeGui"); if g then g:Destroy() end end
                end
            end
        end
    end
    for _, conns in pairs(activeConnections) do for _, c in ipairs(conns) do c:Disconnect() end end
    activeConnections = {}; cfg.timerEspEnabled = false; saveSettings(cfg)
end

-- BRAINROT ESP
local mutationColors = {
    Gold = Color3.fromRGB(255,215,0), Diamond = Color3.fromRGB(0,255,255),
    Lava = Color3.fromRGB(255,100,0), Bloodrot = Color3.fromRGB(255,0,0)
}

local function extractNumber(str)
    if not str then return 0 end
    local ns = str:match("%$(.-)/s"); if not ns then return 0 end
    ns = ns:gsub("%s",""); local mul = 1
    if ns:lower():find("k") then mul = 1000; ns = ns:gsub("[kK]","")
    elseif ns:lower():find("m") then mul = 1000000; ns = ns:gsub("[mM]","")
    elseif ns:lower():find("b") then mul = 1000000000; ns = ns:gsub("[bB]","") end
    return (tonumber(ns) or 0) * mul
end

local function getMutationTextAndColor(mutation)
    if not mutation or mutation.Visible == false or mutation.Text == "" then return "Default", Color3.fromRGB(255,255,255), false end
    if mutation.Text == "Rainbow" then return "Rainbow", Color3.new(1,1,1), true end
    return mutation.Text, mutationColors[mutation.Text] or Color3.fromRGB(255,255,255), false
end

local function createStatGui(base, labels)
    if base:FindFirstChild("StatGui") then base.StatGui:Destroy() end
    local gui = Instance.new("BillboardGui"); gui.Name = "StatGui"
    gui.Size = UDim2.new(0,200,0,60); gui.StudsOffset = Vector3.new(0,3,0)
    gui.AlwaysOnTop = true; gui.Adornee = base; gui.Parent = base
    local lblList = {}
    local function makeL(order, text)
        local lbl = Instance.new("TextLabel", gui)
        lbl.Size = UDim2.new(1,0,0.25,0); lbl.Position = UDim2.new(0,0,0.25*(order-1),0)
        lbl.BackgroundTransparency = 1; lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBold; lbl.TextStrokeTransparency = 0.5
        lbl.Text = text or "N/A"; lbl.TextColor3 = Color3.fromRGB(255,255,255)
        table.insert(lblList, lbl)
    end
    makeL(1, labels.DisplayName); makeL(2, labels.Generation)
    makeL(3, labels.Mutation); makeL(4, labels.Rarity)
    local _, color, isRainbow = getMutationTextAndColor({Text=labels.Mutation, Visible=true})
    if not isRainbow then
        for _, l in ipairs(lblList) do l.TextColor3 = color end
    else
        local t = 0
        RunService.RenderStepped:Connect(function(dt)
            if gui.Parent == nil then return end
            t += dt * 0.2
            for _, l in ipairs(lblList) do l.TextColor3 = Color3.fromHSV(t%1,1,1) end
        end)
    end
end

local function getAllPodiums()
    local podiums = {}
    for _, plot in pairs(workspace:WaitForChild("Plots"):GetChildren()) do
        local ap = plot:FindFirstChild("AnimalPodiums")
        if ap then
            for _, pod in pairs(ap:GetChildren()) do
                local base = pod:FindFirstChild("Base")
                if base and base:FindFirstChild("Spawn") then
                    local att = base.Spawn:FindFirstChild("Attachment")
                    if att and att:FindFirstChild("AnimalOverhead") then
                        table.insert(podiums, att.AnimalOverhead)
                    end
                end
            end
        end
    end
    return podiums
end

local function enableBrainrotEsp()
    brainrotEspEnabled = true
    task.spawn(function()
        while brainrotEspEnabled do
            local bestPodium, bestValue, bestLabels, bestBase = nil, -math.huge, nil, nil
            for _, overhead in pairs(getAllPodiums()) do
                local base = overhead.Parent.Parent.Parent
                if base and (base:IsA("BasePart") or base:IsA("Model")) then
                    local gl = overhead:FindFirstChild("Generation")
                    if gl then
                        local gv = extractNumber(gl.Text)
                        local mut = overhead:FindFirstChild("Mutation")
                        local mt, _, _ = getMutationTextAndColor(mut)
                        if gv > bestValue then
                            bestValue = gv; bestPodium = overhead; bestBase = base
                            bestLabels = {
                                DisplayName = overhead:FindFirstChild("DisplayName") and overhead.DisplayName.Text or "Unknown",
                                Generation = gl.Text,
                                Mutation = mt,
                                Rarity = overhead:FindFirstChild("Rarity") and overhead.Rarity.Text or "None"
                            }
                        end
                    end
                end
            end
            if bestPodium and bestBase then
                if currentBase ~= bestBase then
                    if currentStatGui and currentStatGui.Parent then currentStatGui:Destroy() end
                    currentBase = bestBase; createStatGui(bestBase, bestLabels)
                    currentStatGui = bestBase:FindFirstChild("StatGui")
                end
            else
                if currentStatGui and currentStatGui.Parent then currentStatGui:Destroy() end
                currentBase = nil; currentStatGui = nil
            end
            task.wait(1)
        end
    end)
    cfg.brainrotEspEnabled = true; saveSettings(cfg)
end

local function disableBrainrotEsp()
    brainrotEspEnabled = false
    if currentStatGui and currentStatGui.Parent then currentStatGui:Destroy() end
    currentBase = nil; currentStatGui = nil; cfg.brainrotEspEnabled = false; saveSettings(cfg)
end

-- ANTI HIT
local function enableAntiHit()
    antiHitEnabled = true
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoidRoot = char:WaitForChild("HumanoidRootPart")
    local remote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/UseItem")
    local buyRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/CoinsShopService/RequestBuy")
    local webName = "Web Slinger"
    local function getWebTool() for _, t in ipairs(player.Backpack:GetChildren()) do if t:IsA("Tool") and t.Name == webName then return t end end end
    local function ensureWebTool() if not getWebTool() then pcall(function() buyRemote:InvokeServer(webName) end) end end
    local function equipWebSlinger()
        local ct = char:FindFirstChildOfClass("Tool"); if ct and ct.Name ~= webName then ct.Parent = player.Backpack end
        local tool = getWebTool(); if tool then tool.Parent = char end
    end
    local function useWebSlinger()
        local tool = char:FindFirstChild(webName)
        if tool and tool:FindFirstChild("Handle") then
            remote:FireServer(vector.create(-391.2049865722656, -7.293223857879639, 124.80510711669922), char:WaitForChild("UpperTorso"))
        end
    end
    local existingGui = PlayerGui:FindFirstChild("WebSlingerGUI"); if existingGui then existingGui:Destroy() end
    local gui = Instance.new("ScreenGui", PlayerGui); gui.Name = "WebSlingerGUI"; gui.ResetOnSpawn = false
    local holder = Instance.new("Frame", gui); holder.Size = UDim2.new(0,180,0,60)
    holder.Position = UDim2.new(1,-20,0,10); holder.AnchorPoint = Vector2.new(1,0)
    holder.BackgroundColor3 = T.BG; holder.BackgroundTransparency = 0.1; holder.BorderSizePixel = 0
    holder.Active = true; holder.Draggable = true; holder.ZIndex = 3
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 16)
    local mainBtn = Instance.new("TextButton", holder); mainBtn.Size = UDim2.new(1,-20,0,35)
    mainBtn.Position = UDim2.new(0,10,0,10); mainBtn.Text = "🎯 Anti Hit"
    mainBtn.BackgroundColor3 = T.Red; mainBtn.TextColor3 = Color3.new(1,1,1)
    mainBtn.Font = Enum.Font.GothamBold; mainBtn.TextSize = 16; mainBtn.BorderSizePixel = 0; mainBtn.ZIndex = 4
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 10)
    local autoMode = false
    local autoBtn = Instance.new("TextButton", holder); autoBtn.Size = UDim2.new(0,60,0,22)
    autoBtn.Position = UDim2.new(1,-65,1,4); autoBtn.AnchorPoint = Vector2.new(0,0)
    autoBtn.Text = "Auto: OFF"; autoBtn.BackgroundColor3 = T.CardHov
    autoBtn.TextColor3 = Color3.new(1,1,1); autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 12; autoBtn.BorderSizePixel = 0; autoBtn.ZIndex = 5
    Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0,8)
    autoBtn.MouseButton1Click:Connect(function()
        autoMode = not autoMode; autoBtn.Text = "Auto: "..(autoMode and "ON" or "OFF")
        autoBtn.BackgroundColor3 = autoMode and T.Green or T.CardHov
    end)
    mainBtn.MouseButton1Click:Connect(function()
        ensureWebTool(); task.wait(0.3); equipWebSlinger(); task.wait(0.1); useWebSlinger()
    end)
    local lastTriggered = 0
    RunService.Heartbeat:Connect(function()
        if autoMode then
            local tf = humanoidRoot:FindFirstChild("TrappedTag")
            local main = tf and tf:FindFirstChild("MainFrame")
            local timeObj = main and main:FindFirstChild("Time")
            if not timeObj and (tick()-lastTriggered) >= 3.5 then
                lastTriggered = tick(); ensureWebTool(); task.wait(0.3); equipWebSlinger(); task.wait(3.5); useWebSlinger()
            end
        end
    end)
    task.defer(function()
        RunService.RenderStepped:Connect(function()
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.PlatformStand then hum.PlatformStand = false end
        end)
    end)
    cfg.antiHitEnabled = true; saveSettings(cfg)
end

local function disableAntiHit()
    antiHitEnabled = false
    local eg = PlayerGui:FindFirstChild("WebSlingerGUI"); if eg then eg:Destroy() end
    cfg.antiHitEnabled = false; saveSettings(cfg)
end

-- DESYNC
local DESYNC_FLAGS = {
    LargeReplicatorEnabled9 = true,
    GameNetDontSendRedundantNumTimes = 1,
    MaxTimestepMultiplierAcceleration = 2147483647,
    InterpolationFrameVelocityThresholdMillionth = 5,
    CheckPVDifferencesForInterpolationMinRotVelThresholdRadsPerSecHundredth = 1,
    TimestepArbiterVelocityCriteriaThresholdTwoDt = 2147483646,
    GameNetPVHeaderLinearVelocityZeroCutoffExponent = -5000,
    TimestepArbiterHumanoidTurningVelThreshold = 1,
    LargeReplicatorSerializeWrite4 = true,
    SimExplicitlyCappedTimestepMultiplier = 2147483646,
    InterpolationFrameRotVelocityThresholdMillionth = 5,
    ServerMaxBandwith = 52,
    LargeReplicatorSerializeRead3 = true,
    GameNetDontSendRedundantDeltaPositionMillionth = 1,
    PhysicsSenderMaxBandwidthBps = 20000,
    CheckPVCachedVelThresholdPercent = 10,
    NextGenReplicatorEnabledWrite4 = true,
    LargeReplicatorWrite5 = true,
    MaxMissedWorldStepsRemembered = -2147483648,
    StreamJobNOUVolumeCap = 2147483647,
    CheckPVLinearVelocityIntegrateVsDeltaPositionThresholdPercent = 1,
    DisableDPIScale = true,
    WorldStepMax = 30,
    InterpolationFramePositionThresholdMillionth = 5,
    MaxAcceptableUpdateDelay = 1,
    TimestepArbiterOmegaThou = 1073741823,
    CheckPVCachedRotVelThresholdPercent = 10,
    StreamJobNOUVolumeLengthCap = 2147483647,
    S2PhysicsSenderRate = 15000,
    MaxTimestepMultiplierBuoyancy = 2147483647,
    SimOwnedNOUCountThresholdMillionth = 2147483647,
    ReplicationFocusNouExtentsSizeCutoffForPauseStuds = 2147483647,
    LargeReplicatorRead5 = true,
    CheckPVDifferencesForInterpolationMinVelThresholdStudsPerSecHundredth = 1,
    MaxDataPacketPerSend = 2147483647,
    MaxTimestepMultiplierContstraint = 2147483647,
    DebugSendDistInSteps = -2147483648,
    GameNetPVHeaderRotationalVelocityZeroCutoffExponent = -5000,
    AngularVelociryLimit = 360
}

local desyncActive = false

local function runDesyncEngine()
    for key, value in pairs(DESYNC_FLAGS) do
        pcall(function()
            setfflag(tostring(key), tostring(value))
        end)
    end
end

local function createDesyncIndicator()
    if screenGui:FindFirstChild("KH_DesyncIndicator") then return end

    local indicator = Instance.new("Frame", screenGui)
    indicator.Name = "KH_DesyncIndicator"
    indicator.Size = UDim2.new(0, 210, 0, 48)
    indicator.Position = UDim2.new(0.5, -105, 0, 10)
    indicator.BackgroundColor3 = T.BG
    indicator.BackgroundTransparency = 0.1
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 999
    corner(indicator, 12)

    local borderStroke = Instance.new("UIStroke", indicator)
    borderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    borderStroke.Thickness = 2
    borderStroke.Color = T.Accent
    borderStroke.Transparency = 0.3

    local grad = Instance.new("UIGradient", borderStroke)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(139, 92, 246)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 102, 241)),
    })

    task.spawn(function()
        while indicator.Parent do
            for i = 0, 360, 3 do
                if not indicator.Parent then break end
                grad.Rotation = i
                task.wait(0.01)
            end
        end
    end)

    local iconLbl = Instance.new("TextLabel", indicator)
    iconLbl.Size = UDim2.new(0, 32, 0, 32)
    iconLbl.Position = UDim2.new(0, 10, 0.5, -16)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = "⚡"
    iconLbl.TextScaled = true
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.TextColor3 = T.Accent
    iconLbl.ZIndex = 1000

    local titleLbl = Instance.new("TextLabel", indicator)
    titleLbl.Size = UDim2.new(1, -52, 0, 20)
    titleLbl.Position = UDim2.new(0, 50, 0, 7)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "Desync V3"
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextColor3 = T.Text
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 1000

    local statusLbl = Instance.new("TextLabel", indicator)
    statusLbl.Size = UDim2.new(1, -52, 0, 14)
    statusLbl.Position = UDim2.new(0, 50, 0, 28)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "ACTIVE • NO LAGBACK"
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.TextSize = 10
    statusLbl.TextColor3 = T.Green
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.ZIndex = 1000

    -- fade in
    indicator.BackgroundTransparency = 1
    iconLbl.TextTransparency = 1
    titleLbl.TextTransparency = 1
    statusLbl.TextTransparency = 1
    borderStroke.Transparency = 1

    tween(indicator, 0.4, {BackgroundTransparency = 0.1})
    tween(borderStroke, 0.4, {Transparency = 0.3})
    tween(iconLbl, 0.4, {TextTransparency = 0})
    tween(titleLbl, 0.4, {TextTransparency = 0})
    tween(statusLbl, 0.4, {TextTransparency = 0})

    -- pulse icon
    task.spawn(function()
        while indicator.Parent do
            tween(iconLbl, 1, {TextColor3 = Color3.fromRGB(139, 92, 246)}, Enum.EasingStyle.Sine)
            task.wait(1)
            tween(iconLbl, 1, {TextColor3 = T.Accent}, Enum.EasingStyle.Sine)
            task.wait(1)
        end
    end)
end

local function enableDesync()
    if desyncActive then
        notify("KALNZ HUB", "Desync already active!", 2)
        return
    end
    desyncActive = true
    task.spawn(runDesyncEngine)
    task.spawn(createDesyncIndicator)
    notify("KALNZ HUB", "Desync V3 Enabled!", 3)
end

-- WEB SLINGER AUTO AIM
local function enableWebSlingerAutoAim()
    if webSlingerConnection then webSlingerConnection:Disconnect(); webSlingerConnection = nil end
    local tool = player.Backpack:FindFirstChild("Web Slinger") or (player.Character and player.Character:FindFirstChild("Web Slinger"))
    if not tool then
        pcall(function()
            ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/CoinsShopService/RequestBuy"):InvokeServer("Web Slinger")
        end)
        task.wait(1)
        tool = player.Backpack:FindFirstChild("Web Slinger") or (player.Character and player.Character:FindFirstChild("Web Slinger"))
        if not tool then notify("Web Slinger","Failed to acquire!"); return end
    end
    webSlingerAutoAimEnabled = true
    local handle = tool:WaitForChild("Handle")
    local function findNearest()
        local closest, closestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hum = p.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local dist = (handle.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist < closestDist then closestDist = dist; closest = p end
                end
            end
        end
        return closest
    end
    webSlingerConnection = tool.Activated:Connect(function()
        local t = findNearest()
        if t and t.Character then
            local tp = t.Character:WaitForChild("HumanoidRootPart")
            if tp then
                local pos = tp.Position
                ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/UseItem"):FireServer(vector.create(pos.X,pos.Y,pos.Z), tp, handle)
            end
        end
    end)
    cfg.webSlingerAutoAimEnabled = true; saveSettings(cfg)
end

local function disableWebSlingerAutoAim()
    if webSlingerConnection then webSlingerConnection:Disconnect(); webSlingerConnection = nil end
    webSlingerAutoAimEnabled = false; cfg.webSlingerAutoAimEnabled = false; saveSettings(cfg)
end

-- ════════════════════════════════════════
-- BUILD TAB PAGES
-- ════════════════════════════════════════
local pgMain     = tabPages["Main"]
local pgESP      = tabPages["ESP"]
local pgSettings = tabPages["Settings"]
local pgInfo     = tabPages["Info"]

-- padding
for _, pg in pairs(tabPages) do
    local pad = Instance.new("UIPadding", pg)
    pad.PaddingLeft = UDim.new(0, 2); pad.PaddingRight = UDim.new(0, 2)
    pad.PaddingTop = UDim.new(0, 4); pad.PaddingBottom = UDim.new(0, 8)
end

-- ── MAIN TAB ──
sectionLabel(pgMain, "Movement")
makeToggle(pgMain, "Infinite Jump", infiniteJumpEnabled, enableInfiniteJump, disableInfiniteJump)
makeToggle(pgMain, "Boost Jump", boostJumpEnabled, enableBoostJump, disableBoostJump)
makeToggle(pgMain, "Custom Walkspeed", walkspeedEnabled, enableWalkspeed, disableWalkspeed)
makeSlider(pgMain, "Walk Speed", 16, 250, currentWalkSpeed, function(v) currentWalkSpeed = v; cfg.currentWalkSpeed = v; saveSettings(cfg) end)
makeSlider(pgMain, "Boost Strength", 50, 300, currentBoostStrength, function(v) currentBoostStrength = v; cfg.currentBoostStrength = v; saveSettings(cfg) end)

sectionLabel(pgMain, "Combat")
makeToggle(pgMain, "Touch Fling", flingEnabled, enableFling, disableFling)
makeToggle(pgMain, "Anti Trap", antiTrapEnabled, enableAntiTrap, disableAntiTrap)
makeToggle(pgMain, "Anti Hit", antiHitEnabled, enableAntiHit, disableAntiHit)
makeToggle(pgMain, "Web Slinger Auto Aim", webSlingerAutoAimEnabled, enableWebSlingerAutoAim, disableWebSlingerAutoAim)

-- ── ESP TAB ──
sectionLabel(pgESP, "Visual")
makeToggle(pgESP, "Player ESP", espEnabled, enableESP, disableESP)
makeToggle(pgESP, "Timer ESP", timerEspEnabled, enableTimerESP, disableTimerESP)
makeToggle(pgESP, "Highest Value ESP", brainrotEspEnabled, enableBrainrotEsp, disableBrainrotEsp)

-- ── SETTINGS TAB ──
sectionLabel(pgSettings, "Desync")
makeButton(pgSettings, "⚡ Enable Desync V3", T.Accent, function()
    enableDesync()
end)

sectionLabel(pgSettings, "GUI")
makeButton(pgSettings, "Destroy GUI", T.Red, function()
    tween(panel, 0.3, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
    tween(pillFrame, 0.3, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
    task.wait(0.4)
    screenGui:Destroy()
    _G.KalnzHubLoaded = nil
end)
makeButton(pgSettings, "Save Settings", T.Green, function()
    saveSettings(cfg)
    notify("KALNZ HUB", "Settings saved!", 2)
end)

-- ── INFO TAB ──
sectionLabel(pgInfo, "About")
makeInfoCard(pgInfo, "Hub", "KALNZ HUB")
makeInfoCard(pgInfo, "Version", "v1.0")
makeInfoCard(pgInfo, "UI Style", "Wind UI")
makeInfoCard(pgInfo, "Base", "NamelessHub")
sectionLabel(pgInfo, "Status")
makeInfoCard(pgInfo, "Player", player.DisplayName)
makeInfoCard(pgInfo, "User", "@" .. player.Name)
makeInfoCard(pgInfo, "Game", tostring(game.PlaceId))

-- ════════════════════════════════════════
-- OPEN / CLOSE PANEL ANIMATION
-- ════════════════════════════════════════
local panelOpen = false

local function openPanel()
    if panelOpen then return end
    panelOpen = true
    panel.Size = UDim2.new(0, 0, 0, 0)
    panel.Visible = true
    panel.BackgroundTransparency = 1
    tween(panel, 0.4, {Size = UDim2.new(0, 360, 0, 440), BackgroundTransparency = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.wait(0.15)
    -- activate first tab
    local firstTabBtn = tabs["Main"]
    firstTabBtn:GetPropertyChangedSignal("BackgroundColor3"):Wait() -- yield until tween done
end

local function closePanel()
    if not panelOpen then return end
    panelOpen = false
    tween(panel, 0.3, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, Enum.EasingStyle.Quint)
    task.wait(0.32)
    if not panelOpen then panel.Visible = false end
end

-- pill toggles panel
local clickTime = 0
pillButton.MouseButton1Click:Connect(function()
    local now = tick()
    if now - clickTime < 0.3 then return end -- debounce drag vs click
    clickTime = now
    if not panelOpen then
        openPanel()
        -- switch to Main tab on open
        if activeTab ~= "Main" then
            tabs["Main"]:GetPropertyChangedSignal("Size")  -- dummy wait
        end
        if not activeTab then
            tabs["Main"].MouseButton1Click:Fire()
        end
    else
        closePanel()
    end
end)

closeBtn.MouseButton1Click:Connect(closePanel)

-- ════════════════════════════════════════
-- INIT: ACTIVATE FIRST TAB PROPERLY
-- ════════════════════════════════════════
-- simulate click on Main tab
task.defer(function()
    activeTab = "Main"
    tween(tabs["Main"], 0.2, {BackgroundColor3 = T.Accent, TextColor3 = Color3.fromRGB(255,255,255)})
    tabPages["Main"].Visible = true
end)

-- ════════════════════════════════════════
-- AUTO-RESTORE SAVED FEATURES
-- ════════════════════════════════════════
task.wait(1)
if cfg.walkspeedEnabled then enableWalkspeed() end
if cfg.infiniteJumpEnabled then enableInfiniteJump() end
if cfg.boostJumpEnabled then enableBoostJump() end
if cfg.espEnabled then enableESP() end
if cfg.timerEspEnabled then enableTimerESP() end
if cfg.webSlingerAutoAimEnabled then enableWebSlingerAutoAim() end
if cfg.antiTrapEnabled then enableAntiTrap() end
if cfg.antiHitEnabled then enableAntiHit() end
if cfg.brainrotEspEnabled then enableBrainrotEsp() end
if cfg.flingEnabled then enableFling() end

-- open GUI on start
openPanel()
