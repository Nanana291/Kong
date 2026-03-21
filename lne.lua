--!optimize 2

local function __INIT__()

local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local mathClamp = math.clamp
local mathFloor = math.floor

local TI = {
    Fast = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Medium = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Snappy = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    FadeIn = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

local Theme = {
    BG = Color3.fromRGB(12, 14, 20),
    Surface = Color3.fromRGB(18, 20, 28),
    SurfaceLight = Color3.fromRGB(24, 26, 36),
    SurfaceHover = Color3.fromRGB(30, 32, 44),
    Border = Color3.fromRGB(38, 40, 54),
    BorderLight = Color3.fromRGB(48, 50, 66),
    Accent = Color3.fromHex("#c953d4"),
    AccentDim = Color3.fromRGB(140, 50, 150),
    AccentGlow = Color3.fromRGB(220, 100, 230),
    Text = Color3.fromRGB(230, 232, 240),
    TextSub = Color3.fromRGB(140, 142, 158),
    TextMuted = Color3.fromRGB(80, 82, 100),
    TextDark = Color3.fromRGB(50, 52, 68),
    SliderTrack = Color3.fromRGB(35, 37, 50),
    SliderFill = Color3.fromHex("#c953d4"),
    ToggleOn = Color3.fromHex("#c953d4"),
    ToggleOff = Color3.fromRGB(50, 52, 68),
    InputBG = Color3.fromRGB(14, 16, 22),
    InputBorder = Color3.fromRGB(40, 42, 58),
    InputFocus = Color3.fromHex("#c953d4"),
    Error = Color3.fromRGB(220, 60, 60),
    Success = Color3.fromRGB(64, 180, 80),
}

local State = {
    Dragging = false,
    DragStart = Vector2.zero,
    DragOrigin = UDim2.new(),
    Connections = {},
    Tweens = {},
}

local Gui = Instance.new("ScreenGui")
Gui.Name = "ImpHubLoader"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 9999
Gui.IgnoreGuiInset = true

do
    local ok = pcall(function() Gui.Parent = game:GetService("CoreGui") end)
    if not ok then
        Gui.Parent = LP:WaitForChild("PlayerGui")
    end
end

local function Conn(c)
    State.Connections[#State.Connections + 1] = c
    return c
end

local function New(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function Corner(parent, radius)
    return New("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = parent})
end

local function Stroke(parent, color, thickness)
    return New("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function Pad(parent, t, r, b, l)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, l or 0),
        Parent = parent,
    })
end

local function Tween(inst, ti, props)
    local t = TS:Create(inst, ti, props)
    t:Play()
    return t
end

local Overlay = New("Frame", {
    Name = "Overlay",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    ZIndex = 0,
    Parent = Gui,
})

local Window = New("Frame", {
    Name = "Window",
    Size = UDim2.fromOffset(820, 480),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = Theme.BG,
    ClipsDescendants = true,
    BackgroundTransparency = 1,
    Parent = Gui,
})
Corner(Window, 12)

local UIScale = New("UIScale", {
    Scale = 1,
    Parent = Window,
})

local function UpdateScale()
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local scaleX = vp.X / 880
    local scaleY = vp.Y / 560
    local s = mathClamp(math.min(scaleX, scaleY), 0.45, 1.2)
    UIScale.Scale = s
end

UpdateScale()
if workspace.CurrentCamera then
    Conn(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale))
end

local WindowStroke = Stroke(Window, Theme.Border, 1)

local TopBar = New("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    ZIndex = 10,
    Parent = Window,
})
Corner(TopBar, 12)

New("Frame", {
    Name = "TopBarFill",
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.new(0, 0, 1, -16),
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    ZIndex = 10,
    Parent = TopBar,
})

local LogoCircle = New("Frame", {
    Name = "LogoCircle",
    Size = UDim2.fromOffset(22, 22),
    Position = UDim2.fromOffset(14, 9),
    BackgroundColor3 = Theme.Accent,
    ZIndex = 11,
    Parent = TopBar,
})
Corner(LogoCircle, 11)

New("Frame", {
    Name = "LogoDot",
    Size = UDim2.fromOffset(8, 8),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = Theme.BG,
    ZIndex = 12,
    Parent = LogoCircle,
})
Corner(LogoCircle:FindFirstChild("LogoDot"), 4)

local TitleLabel = New("TextLabel", {
    Name = "Title",
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.fromOffset(44, 0),
    BackgroundTransparency = 1,
    Text = "IMP HUB X",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 11,
    Parent = TopBar,
})

local CloseBtn = New("TextButton", {
    Name = "Close",
    Size = UDim2.fromOffset(32, 32),
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -8, 0.5, 0),
    BackgroundColor3 = Theme.SurfaceLight,
    BackgroundTransparency = 1,
    Text = "X",
    TextColor3 = Theme.TextSub,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    ZIndex = 11,
    Parent = TopBar,
})
Corner(CloseBtn, 6)

local ContentFrame = New("Frame", {
    Name = "Content",
    Size = UDim2.new(1, 0, 1, -40),
    Position = UDim2.fromOffset(0, 40),
    BackgroundTransparency = 1,
    ZIndex = 2,
    Parent = Window,
})

local Sidebar = New("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 44, 1, 0),
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = ContentFrame,
})

New("Frame", {
    Name = "SidebarBorder",
    Size = UDim2.new(0, 1, 1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    BackgroundColor3 = Theme.Border,
    BorderSizePixel = 0,
    ZIndex = 4,
    Parent = Sidebar,
})

local SidebarLayout = New("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Padding = UDim.new(0, 6),
    Parent = Sidebar,
})
Pad(Sidebar, 12, 0, 12, 0)

local SideIcons = {
    {Shape = "cross", Active = true},
    {Shape = "heart"},
    {Shape = "circle"},
    {Shape = "grid"},
}

for idx, iconData in ipairs(SideIcons) do
    local btn = New("Frame", {
        Name = "SideIcon_" .. idx,
        Size = UDim2.fromOffset(32, 32),
        BackgroundTransparency = 1,
        LayoutOrder = idx,
        ZIndex = 5,
        Parent = Sidebar,
    })
    Corner(btn, 8)

    local dot = New("Frame", {
        Name = "Indicator",
        Size = UDim2.fromOffset(4, 4),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = iconData.Active and Theme.Accent or Theme.TextMuted,
        ZIndex = 6,
        Parent = btn,
    })
    Corner(dot, 2)

    if iconData.Shape == "cross" then
        New("Frame", {
            Size = UDim2.fromOffset(12, 2),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundColor3 = iconData.Active and Theme.Accent or Theme.TextMuted,
            BorderSizePixel = 0,
            ZIndex = 7,
            Parent = btn,
        })
        New("Frame", {
            Size = UDim2.fromOffset(2, 12),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundColor3 = iconData.Active and Theme.Accent or Theme.TextMuted,
            BorderSizePixel = 0,
            ZIndex = 7,
            Parent = btn,
        })
        dot.Visible = false
    end
end

local LeftPanel = New("Frame", {
    Name = "LeftPanel",
    Size = UDim2.new(0.52, -44, 1, 0),
    Position = UDim2.fromOffset(44, 0),
    BackgroundTransparency = 1,
    ZIndex = 2,
    Parent = ContentFrame,
})

local CopyrightLabel = New("TextLabel", {
    Name = "Copyright",
    Size = UDim2.new(1, -28, 0, 16),
    Position = UDim2.fromOffset(14, 8),
    BackgroundTransparency = 1,
    Text = "@2022-2025",
    TextColor3 = Theme.TextDark,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
    Parent = LeftPanel,
})

local WelcomeLabel = New("TextLabel", {
    Name = "WelcomeTitle",
    Size = UDim2.new(1, -28, 0, 22),
    Position = UDim2.fromOffset(14, 28),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = Theme.Accent,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    RichText = true,
    ZIndex = 3,
    Parent = LeftPanel,
})

local ProfileCard = New("Frame", {
    Name = "ProfileCard",
    Size = UDim2.new(1, -28, 0, 280),
    Position = UDim2.fromOffset(14, 56),
    BackgroundColor3 = Theme.Surface,
    ZIndex = 3,
    Parent = LeftPanel,
})
Corner(ProfileCard, 10)
Stroke(ProfileCard, Theme.Border, 1)

local AvatarSection = New("Frame", {
    Name = "AvatarSection",
    Size = UDim2.new(1, 0, 0, 120),
    BackgroundTransparency = 1,
    ZIndex = 4,
    Parent = ProfileCard,
})

local AvatarGlow = New("Frame", {
    Name = "AvatarGlow",
    Size = UDim2.fromOffset(78, 78),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 2),
    BackgroundColor3 = Theme.Accent,
    BackgroundTransparency = 0.7,
    ZIndex = 4,
    Parent = AvatarSection,
})
Corner(AvatarGlow, 39)

local AvatarFrame = New("Frame", {
    Name = "AvatarFrame",
    Size = UDim2.fromOffset(70, 70),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 2),
    BackgroundColor3 = Theme.SurfaceLight,
    ZIndex = 5,
    Parent = AvatarSection,
})
Corner(AvatarFrame, 35)
Stroke(AvatarFrame, Theme.BorderLight, 2)

local AvatarImage = New("ImageLabel", {
    Name = "Avatar",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image = "",
    ZIndex = 6,
    Parent = AvatarFrame,
})
Corner(AvatarImage, 35)

do
    local userId = LP.UserId
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size150x150
    local ok, content = pcall(Players.GetUserThumbnailAsync, Players, userId, thumbType, thumbSize)
    if ok and content then
        AvatarImage.Image = content
    end
end

local NameSection = New("Frame", {
    Name = "NameSection",
    Size = UDim2.new(1, 0, 0, 36),
    Position = UDim2.fromOffset(0, 120),
    BackgroundTransparency = 1,
    ZIndex = 4,
    Parent = ProfileCard,
})

local NameHoverBtn = New("TextButton", {
    Name = "NameHover",
    Size = UDim2.new(0, 180, 0, 28),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = Theme.SurfaceLight,
    AutoButtonColor = false,
    Text = "",
    ZIndex = 5,
    Parent = NameSection,
})
Corner(NameHoverBtn, 6)
Stroke(NameHoverBtn, Theme.Border, 1)

local NameHidden = New("TextLabel", {
    Name = "NameHidden",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = string.rep("\226\128\162 ", 8),
    TextColor3 = Theme.TextMuted,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ZIndex = 7,
    Parent = NameHoverBtn,
})

local NameRevealed = New("TextLabel", {
    Name = "NameRevealed",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = LP.DisplayName,
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextTransparency = 1,
    ZIndex = 8,
    Parent = NameHoverBtn,
})

local HintLabel = New("TextLabel", {
    Name = "HoverHint",
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.fromOffset(0, 150),
    BackgroundTransparency = 1,
    Text = "hover to reveal",
    TextColor3 = Theme.TextDark,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    ZIndex = 4,
    Parent = ProfileCard,
})

do
    local nameRevealed = false
    local revealIn = TS:Create(NameRevealed, TI.Fast, {TextTransparency = 0})
    local revealOut = TS:Create(NameRevealed, TI.Fast, {TextTransparency = 1})
    local hideIn = TS:Create(NameHidden, TI.Fast, {TextTransparency = 1})
    local hideOut = TS:Create(NameHidden, TI.Fast, {TextTransparency = 0})
    local btnIn = TS:Create(NameHoverBtn, TI.Fast, {BackgroundColor3 = Theme.SurfaceHover})
    local btnOut = TS:Create(NameHoverBtn, TI.Fast, {BackgroundColor3 = Theme.SurfaceLight})

    Conn(NameHoverBtn.MouseEnter:Connect(function()
        nameRevealed = true
        revealIn:Play()
        hideIn:Play()
        btnIn:Play()
    end))

    Conn(NameHoverBtn.MouseLeave:Connect(function()
        nameRevealed = false
        revealOut:Play()
        hideOut:Play()
        btnOut:Play()
    end))
end

local Divider = New("Frame", {
    Name = "Divider",
    Size = UDim2.new(1, -32, 0, 1),
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 174),
    BackgroundColor3 = Theme.Border,
    BorderSizePixel = 0,
    ZIndex = 4,
    Parent = ProfileCard,
})

local StatsSection = New("Frame", {
    Name = "Stats",
    Size = UDim2.new(1, -32, 0, 88),
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 184),
    BackgroundTransparency = 1,
    ZIndex = 4,
    Parent = ProfileCard,
})

local StatsLayout = New("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
    Parent = StatsSection,
})

local LiveLabels = {}

local function CreateStatRow(parent, label, order)
    local row = New("Frame", {
        Name = "Stat_" .. label,
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = Theme.SurfaceLight,
        LayoutOrder = order,
        ZIndex = 5,
        Parent = parent,
    })
    Corner(row, 6)

    New("TextLabel", {
        Size = UDim2.new(0.5, -8, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.TextMuted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
        Parent = row,
    })

    local val = New("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0.5, -8, 1, 0),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 0),
        BackgroundTransparency = 1,
        Text = "...",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 6,
        Parent = row,
    })

    LiveLabels[label] = val
    return row
end

CreateStatRow(StatsSection, "Server Time", 1)
CreateStatRow(StatsSection, "Server Size", 2)
CreateStatRow(StatsSection, "FPS", 3)

do
    local fpsBuffer = {}
    local bufferIdx = 0
    local BUFFER_SIZE = 20
    local osDate = os.date
    local tick = tick

    for i = 1, BUFFER_SIZE do
        fpsBuffer[i] = 60
    end

    local lastTick = tick()

    Conn(RS.Heartbeat:Connect(function()
        local now = tick()
        local dt = now - lastTick
        lastTick = now

        bufferIdx = bufferIdx % BUFFER_SIZE + 1
        fpsBuffer[bufferIdx] = dt > 0 and (1 / dt) or 60

        local sum = 0
        for i = 1, BUFFER_SIZE do
            sum = sum + fpsBuffer[i]
        end
        local avgFps = mathFloor(sum / BUFFER_SIZE)

        if LiveLabels["FPS"] then
            LiveLabels["FPS"].Text = tostring(avgFps)
            LiveLabels["FPS"].TextColor3 = avgFps >= 50 and Theme.Success
                or avgFps >= 30 and Color3.fromRGB(220, 180, 40)
                or Theme.Error
        end

        if LiveLabels["Server Time"] then
            LiveLabels["Server Time"].Text = osDate("%H:%M:%S")
        end

        if LiveLabels["Server Size"] then
            local cur = #Players:GetPlayers()
            local mx = Players.MaxPlayers
            LiveLabels["Server Size"].Text = cur .. "/" .. mx
        end
    end))
end

do
    local glowIn = TS:Create(AvatarGlow, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        BackgroundTransparency = 0.4,
        Size = UDim2.fromOffset(84, 84),
    })
    glowIn:Play()
end

local FooterSection = New("Frame", {
    Name = "Footer",
    Size = UDim2.new(1, 0, 0, 50),
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 3,
    Parent = LeftPanel,
})

New("TextLabel", {
    Name = "Tagline",
    Size = UDim2.new(1, -28, 0, 16),
    Position = UDim2.fromOffset(14, 4),
    BackgroundTransparency = 1,
    Text = "MAKE YOUR GAME EASIER WITH US",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
    Parent = FooterSection,
})

New("TextLabel", {
    Name = "SubTagline",
    Size = UDim2.new(1, -28, 0, 14),
    Position = UDim2.fromOffset(14, 22),
    BackgroundTransparency = 1,
    Text = "WE ARE ALWAYS IMPROVING OUR DESIGN FOR YOUR SAFETY.",
    TextColor3 = Theme.TextDark,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
    Parent = FooterSection,
})

local RightPanel = New("Frame", {
    Name = "RightPanel",
    Size = UDim2.new(0.48, 0, 1, 0),
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    ZIndex = 2,
    Parent = ContentFrame,
})

New("Frame", {
    Name = "RightBorder",
    Size = UDim2.new(0, 1, 1, 0),
    BackgroundColor3 = Theme.Border,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = RightPanel,
})

local AuthContainer = New("Frame", {
    Name = "AuthContainer",
    Size = UDim2.new(1, -60, 0, 320),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundTransparency = 1,
    ZIndex = 4,
    Parent = RightPanel,
})

New("TextLabel", {
    Name = "AuthTitle",
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "AUTHORIZATION",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 5,
    Parent = AuthContainer,
})

New("TextLabel", {
    Name = "AuthSub",
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.fromOffset(0, 34),
    BackgroundTransparency = 1,
    Text = "G L A D   T O   S E E   Y O U   A G A I N",
    TextColor3 = Theme.TextMuted,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 5,
    Parent = AuthContainer,
})

local KeyInputFrame = New("Frame", {
    Name = "KeyInputFrame",
    Size = UDim2.new(1, 0, 0, 44),
    Position = UDim2.fromOffset(0, 90),
    BackgroundColor3 = Theme.InputBG,
    ZIndex = 5,
    Parent = AuthContainer,
})
Corner(KeyInputFrame, 8)
local KeyInputStroke = Stroke(KeyInputFrame, Theme.InputBorder, 1)

local KeyIcon = New("Frame", {
    Name = "KeyIcon",
    Size = UDim2.fromOffset(20, 20),
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 14, 0.5, 0),
    BackgroundColor3 = Theme.Accent,
    ZIndex = 7,
    Parent = KeyInputFrame,
})
Corner(KeyIcon, 10)

New("Frame", {
    Name = "KeyHole",
    Size = UDim2.fromOffset(6, 6),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.45),
    BackgroundColor3 = Theme.InputBG,
    ZIndex = 8,
    Parent = KeyIcon,
})
Corner(KeyIcon:FindFirstChild("KeyHole"), 3)

local KeyTextBox = New("TextBox", {
    Name = "KeyInput",
    Size = UDim2.new(1, -52, 1, 0),
    Position = UDim2.fromOffset(44, 0),
    BackgroundTransparency = 1,
    Text = "",
    PlaceholderText = "Enter your key...",
    PlaceholderColor3 = Theme.TextMuted,
    TextColor3 = Theme.Text,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 7,
    Parent = KeyInputFrame,
})

local ValidateBtn = New("TextButton", {
    Name = "ValidateBtn",
    Size = UDim2.new(1, 0, 0, 44),
    Position = UDim2.fromOffset(0, 150),
    BackgroundColor3 = Theme.Accent,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 5,
    Parent = AuthContainer,
})
Corner(ValidateBtn, 8)

local ValidateBtnLabel = New("TextLabel", {
    Name = "Label",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "VALIDATE",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    ZIndex = 6,
    Parent = ValidateBtn,
})

local StatusLabel = New("TextLabel", {
    Name = "Status",
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.fromOffset(0, 202),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = Theme.Error,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextTransparency = 1,
    ZIndex = 5,
    Parent = AuthContainer,
})

local VersionLabel = New("TextLabel", {
    Name = "Version",
    Size = UDim2.fromOffset(60, 16),
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 12, 1, -8),
    BackgroundTransparency = 1,
    Text = "1.0.0",
    TextColor3 = Theme.TextDark,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5,
    Parent = RightPanel,
})

local DiscordFrame = New("Frame", {
    Name = "DiscordIcon",
    Size = UDim2.fromOffset(24, 24),
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -12, 1, -8),
    BackgroundColor3 = Theme.SurfaceHover,
    ZIndex = 5,
    Parent = RightPanel,
})
Corner(DiscordFrame, 6)

New("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "DC",
    TextColor3 = Theme.TextSub,
    Font = Enum.Font.GothamBold,
    TextSize = 8,
    ZIndex = 6,
    Parent = DiscordFrame,
})

Conn(KeyTextBox.Focused:Connect(function()
    Tween(KeyInputStroke, TI.Fast, {Color = Theme.InputFocus, Thickness = 1.5})
    Tween(KeyIcon, TI.Fast, {BackgroundColor3 = Theme.AccentGlow})
end))

Conn(KeyTextBox.FocusLost:Connect(function()
    Tween(KeyInputStroke, TI.Fast, {Color = Theme.InputBorder, Thickness = 1})
    Tween(KeyIcon, TI.Fast, {BackgroundColor3 = Theme.Accent})
end))

do
    local hoverTweenIn = TS:Create(ValidateBtn, TI.Fast, {BackgroundColor3 = Theme.AccentGlow})
    local hoverTweenOut = TS:Create(ValidateBtn, TI.Fast, {BackgroundColor3 = Theme.Accent})

    Conn(ValidateBtn.MouseEnter:Connect(function()
        hoverTweenIn:Play()
    end))

    Conn(ValidateBtn.MouseLeave:Connect(function()
        hoverTweenOut:Play()
    end))
end

do
    local closeHoverIn = TS:Create(CloseBtn, TI.Fast, {BackgroundTransparency = 0, TextColor3 = Theme.Text})
    local closeHoverOut = TS:Create(CloseBtn, TI.Fast, {BackgroundTransparency = 1, TextColor3 = Theme.TextSub})

    Conn(CloseBtn.MouseEnter:Connect(function()
        closeHoverIn:Play()
    end))

    Conn(CloseBtn.MouseLeave:Connect(function()
        closeHoverOut:Play()
    end))
end

local LoadingScreen = New("Frame", {
    Name = "LoadingScreen",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Theme.BG,
    BackgroundTransparency = 0.15,
    Visible = false,
    ZIndex = 50,
    Parent = Window,
})

local LoadingInner = New("Frame", {
    Name = "LoadingInner",
    Size = UDim2.fromOffset(100, 110),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundTransparency = 1,
    ZIndex = 51,
    Parent = LoadingScreen,
})

local SPINNER_SIZE = 44
local DOT_COUNT = 10
local DOT_RADIUS = 18
local DOT_SIZE = 5

local SpinnerFrame = New("Frame", {
    Name = "Spinner",
    Size = UDim2.fromOffset(SPINNER_SIZE, SPINNER_SIZE),
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 0),
    BackgroundTransparency = 1,
    ZIndex = 52,
    Parent = LoadingInner,
})

local mathRad = math.rad
local mathCos = math.cos
local mathSin = math.sin

for i = 0, DOT_COUNT - 1 do
    local angle = mathRad(i * (360 / DOT_COUNT) - 90)
    local alpha = 1 - (i / DOT_COUNT)
    local sz = DOT_SIZE * (0.6 + 0.4 * alpha)
    local d = New("Frame", {
        Name = "Dot" .. i,
        Size = UDim2.fromOffset(sz, sz),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, mathCos(angle) * DOT_RADIUS, 0.5, mathSin(angle) * DOT_RADIUS),
        BackgroundColor3 = i == 0 and Theme.AccentGlow or Theme.Accent,
        BackgroundTransparency = 1 - alpha,
        ZIndex = 53,
        Parent = SpinnerFrame,
    })
    Corner(d, math.ceil(sz / 2))
end

local spinnerTween = TS:Create(SpinnerFrame,
    TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    {Rotation = 360})

local RingBG = New("Frame", {
    Name = "RingBG",
    Size = UDim2.fromOffset(SPINNER_SIZE - 4, SPINNER_SIZE - 4),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = Theme.SurfaceLight,
    BackgroundTransparency = 0.5,
    ZIndex = 51,
    Parent = SpinnerFrame,
})
Corner(RingBG, (SPINNER_SIZE - 4) / 2)

local LoadingText = New("TextLabel", {
    Name = "LoadingText",
    Size = UDim2.new(1, 0, 0, 16),
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 56),
    BackgroundTransparency = 1,
    Text = "Validating...",
    TextColor3 = Theme.TextSub,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    ZIndex = 52,
    Parent = LoadingInner,
})

local LoadingDots = New("TextLabel", {
    Name = "Dots",
    Size = UDim2.new(1, 0, 0, 14),
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 72),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = Theme.Accent,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    ZIndex = 52,
    Parent = LoadingInner,
})

local loadingDotsConn = nil

local function ShowLoading(text)
    LoadingText.Text = text or "Validating..."
    LoadingScreen.BackgroundTransparency = 1
    LoadingScreen.Visible = true

    SpinnerFrame.Rotation = 0
    SpinnerFrame.Visible = true
    LoadingText.TextTransparency = 1
    LoadingDots.TextTransparency = 1

    Tween(LoadingScreen, TI.Medium, {BackgroundTransparency = 0.15})

    spinnerTween:Play()

    task.delay(0.1, function()
        Tween(LoadingText, TI.Fast, {TextTransparency = 0})
        Tween(LoadingDots, TI.Fast, {TextTransparency = 0})
    end)

    if loadingDotsConn then loadingDotsConn:Disconnect() end
    local dotState = 0
    local dotPatterns = {"", "\194\183", "\194\183 \194\183", "\194\183 \194\183 \194\183"}
    local elapsed = 0
    loadingDotsConn = RS.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed >= 0.4 then
            elapsed = 0
            dotState = dotState % 4 + 1
            LoadingDots.Text = dotPatterns[dotState]
        end
    end)
end

local function HideLoading(callback)
    if loadingDotsConn then
        loadingDotsConn:Disconnect()
        loadingDotsConn = nil
    end

    spinnerTween:Cancel()

    Tween(LoadingText, TI.Fast, {TextTransparency = 1})
    Tween(LoadingDots, TI.Fast, {TextTransparency = 1})

    local fade = Tween(LoadingScreen, TI.Medium, {BackgroundTransparency = 1})
    fade.Completed:Once(function()
        LoadingScreen.Visible = false
        SpinnerFrame.Rotation = 0
        if type(callback) == "function" then callback() end
    end)
end

local DragHandle = New("TextButton", {
    Name = "DragHandle",
    Size = UDim2.new(1, -40, 1, 0),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    Active = true,
    ZIndex = 12,
    Parent = TopBar,
})

do
    local dragging = false
    local dragStart = Vector2.zero
    local startPos = UDim2.new()

    Conn(DragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
        end
    end))

    Conn(UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            Window.Position = startPos + UDim2.fromOffset(delta.X / UIScale.Scale, delta.Y / UIScale.Scale)
        end
    end))

    Conn(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

local Loader = {}
Loader.OnValidate = nil

Conn(ValidateBtn.MouseButton1Click:Connect(function()
    local key = KeyTextBox.Text
    if key == "" then
        StatusLabel.TextColor3 = Theme.Error
        StatusLabel.Text = "Please enter a key."
        Tween(StatusLabel, TI.Fast, {TextTransparency = 0})
        task.delay(3, function()
            Tween(StatusLabel, TI.Medium, {TextTransparency = 1})
        end)
        return
    end

    ValidateBtnLabel.Text = "VALIDATING..."
    Tween(ValidateBtn, TI.Fast, {BackgroundColor3 = Theme.AccentDim})
    ShowLoading("Validating key...")

    if type(Loader.OnValidate) == "function" then
        coroutine.resume(coroutine.create(function()
            local success, msg = Loader.OnValidate(key)

            HideLoading(function()
                if success then
                    StatusLabel.TextColor3 = Theme.Success
                    StatusLabel.Text = msg or "Key validated!"
                    Tween(StatusLabel, TI.Fast, {TextTransparency = 0})
                    ValidateBtnLabel.Text = "SUCCESS"
                    Tween(ValidateBtn, TI.Fast, {BackgroundColor3 = Theme.Success})

                    task.delay(1.2, function()
                        Tween(Window, TI.Medium, {BackgroundTransparency = 1})
                        Tween(Overlay, TI.Medium, {BackgroundTransparency = 1})

                        for _, desc in ipairs(Window:GetDescendants()) do
                            if desc:IsA("GuiObject") then
                                pcall(function()
                                    Tween(desc, TI.Medium, {BackgroundTransparency = 1})
                                end)
                            end
                            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                                pcall(function()
                                    Tween(desc, TI.Medium, {TextTransparency = 1})
                                end)
                            end
                            if desc:IsA("UIStroke") then
                                pcall(function()
                                    Tween(desc, TI.Medium, {Transparency = 1})
                                end)
                            end
                        end

                        task.delay(0.5, function()
                            Gui:Destroy()
                        end)
                    end)
                else
                    StatusLabel.TextColor3 = Theme.Error
                    StatusLabel.Text = msg or "Invalid key."
                    Tween(StatusLabel, TI.Fast, {TextTransparency = 0})
                    ValidateBtnLabel.Text = "VALIDATE"
                    Tween(ValidateBtn, TI.Fast, {BackgroundColor3 = Theme.Accent})
                    task.delay(4, function()
                        Tween(StatusLabel, TI.Medium, {TextTransparency = 1})
                    end)
                end
            end)
        end))
    else
        HideLoading(function()
            StatusLabel.TextColor3 = Theme.Error
            StatusLabel.Text = "No validation handler set."
            Tween(StatusLabel, TI.Fast, {TextTransparency = 0})
            ValidateBtnLabel.Text = "VALIDATE"
            Tween(ValidateBtn, TI.Fast, {BackgroundColor3 = Theme.Accent})
            task.delay(3, function()
                Tween(StatusLabel, TI.Medium, {TextTransparency = 1})
            end)
        end)
    end
end))

Conn(CloseBtn.MouseButton1Click:Connect(function()
    Tween(Window, TI.Medium, {BackgroundTransparency = 1})
    for _, desc in ipairs(Window:GetDescendants()) do
        if desc:IsA("GuiObject") then
            pcall(function()
                Tween(desc, TI.Fast, {BackgroundTransparency = 1})
            end)
        end
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            pcall(function()
                Tween(desc, TI.Fast, {TextTransparency = 1})
            end)
        end
        if desc:IsA("UIStroke") then
            pcall(function()
                Tween(desc, TI.Fast, {Transparency = 1})
            end)
        end
    end
    Tween(Overlay, TI.Medium, {BackgroundTransparency = 1})
    task.delay(0.5, function()
        if loadingDotsConn then loadingDotsConn:Disconnect() end
        spinnerTween:Cancel()
        for _, c in ipairs(State.Connections) do
            c:Disconnect()
        end
        Gui:Destroy()
    end)
end))

do
    Window.BackgroundTransparency = 1
    WindowStroke.Transparency = 1
    Overlay.BackgroundTransparency = 1

    local allDesc = Window:GetDescendants()
    local origTransparency = {}
    local origTextTransparency = {}
    local origStrokeTransparency = {}

    for _, desc in ipairs(allDesc) do
        if desc:IsA("GuiObject") then
            origTransparency[desc] = desc.BackgroundTransparency
            desc.BackgroundTransparency = 1
        end
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            origTextTransparency[desc] = desc.TextTransparency
            desc.TextTransparency = 1
        end
        if desc:IsA("UIStroke") then
            origStrokeTransparency[desc] = desc.Transparency
            desc.Transparency = 1
        end
    end

    task.delay(0.1, function()
        Tween(Overlay, TI.Slow, {BackgroundTransparency = 0.4})
        Tween(Window, TI.FadeIn, {BackgroundTransparency = 0})
        Tween(WindowStroke, TI.FadeIn, {Transparency = 0})

        task.delay(0.15, function()
            for desc, orig in pairs(origTransparency) do
                if desc and desc.Parent then
                    Tween(desc, TI.FadeIn, {BackgroundTransparency = orig})
                end
            end
            for desc, orig in pairs(origTextTransparency) do
                if desc and desc.Parent and desc ~= WelcomeLabel then
                    Tween(desc, TI.FadeIn, {TextTransparency = orig})
                end
            end
            for desc, orig in pairs(origStrokeTransparency) do
                if desc and desc.Parent then
                    Tween(desc, TI.FadeIn, {Transparency = orig})
                end
            end

            origTransparency = nil
            origTextTransparency = nil
            origStrokeTransparency = nil

            task.delay(0.4, function()
                local fullText = "WELCOME, " .. LP.DisplayName:upper()
                local strSub = string.sub
                WelcomeLabel.TextTransparency = 0

                for i = 1, #fullText do
                    WelcomeLabel.Text = strSub(fullText, 1, i) .. '<font color="#555">|</font>'
                    task.wait(0.035)
                end

                WelcomeLabel.Text = fullText

                task.delay(0.3, function()
                    local glowTween = TS:Create(WelcomeLabel, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                        TextColor3 = Theme.AccentGlow,
                    })
                    glowTween:Play()
                end)
            end)
        end)
    end)
end

function Loader:SetVersion(v)
    VersionLabel.Text = tostring(v)
end

function Loader:SetTitle(t)
    TitleLabel.Text = tostring(t)
end

function Loader:SetOnValidate(fn)
    Loader.OnValidate = fn
end

local TOAST_W = 280
local TOAST_GAP = 6

local TOAST_FALLBACK = {
    info = "\226\132\185",
    success = "\226\156\147",
    warning = "\226\154\160",
    error = "\226\156\151",
}

local TOAST_COLORS = {
    info = Theme.Accent,
    success = Theme.Success,
    warning = Color3.fromRGB(220, 170, 40),
    error = Theme.Error,
}

local LucideCache = {}
local LUCIDE_CDN = "https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/"

local lucideSupported = false
do
    local ok = pcall(function()
        return writefile and isfile and getcustomasset
    end)
    if ok and writefile and isfile and getcustomasset then
        lucideSupported = true
    end
end

local folderReady = false

local function EnsureLucideFolder()
    if folderReady or not lucideSupported then return folderReady end
    local ok = pcall(function()
        if not isfile("ImpHubIcons/init.txt") then
            if makefolder then
                makefolder("ImpHubIcons")
            end
            writefile("ImpHubIcons/init.txt", "1")
        end
    end)
    folderReady = ok
    return ok
end

local function FetchLucideIcon(name)
    if LucideCache[name] then return LucideCache[name] end
    if not lucideSupported then return nil end
    if not folderReady then EnsureLucideFolder() end
    if not folderReady then return nil end

    local path = "ImpHubIcons/" .. name .. ".svg"
    local asset = nil

    local ok = pcall(function()
        if not isfile(path) then
            local data = game:HttpGet(LUCIDE_CDN .. name .. ".svg")
            if data and #data > 0 then
                writefile(path, data)
            end
        end
        if isfile(path) then
            asset = getcustomasset(path)
        end
    end)

    if ok and asset then
        LucideCache[name] = asset
        return asset
    end
    return nil
end

local function IsLucideName(str)
    if not str or str == "" then return false end
    if string.byte(str, 1) > 127 then return false end
    return string.match(str, "^[a-z][a-z0-9%-]*$") ~= nil
end

local ToastContainer = New("Frame", {
    Name = "ToastContainer",
    Size = UDim2.new(0, TOAST_W + 16, 1, -16),
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -8, 0, 8),
    BackgroundTransparency = 1,
    ZIndex = 100,
    ClipsDescendants = false,
    Parent = Gui,
})

New("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    FillDirection = Enum.FillDirection.Vertical,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0, TOAST_GAP),
    Parent = ToastContainer,
})

local toastOrder = 0

local function CreateToast(config)
    toastOrder = toastOrder + 1

    local toastType = config.Type or "info"
    local accentColor = config.Color or TOAST_COLORS[toastType] or Theme.Accent
    local rawIcon = config.Icon
    local title = config.Title or ""
    local subtitle = config.Subtitle or ""
    local description = config.Description or ""
    local duration = config.Duration or 4

    local hasSubtitle = subtitle ~= ""
    local hasDesc = description ~= ""
    local contentH = 12
    if title ~= "" then contentH = contentH + 16 end
    if hasSubtitle then contentH = contentH + 14 end
    if hasDesc then contentH = contentH + 4 + 14 end
    local cardH = math.max(contentH + 16, 48)

    local card = New("Frame", {
        Name = "Toast_" .. toastOrder,
        Size = UDim2.fromOffset(TOAST_W, cardH),
        BackgroundColor3 = Theme.Surface,
        LayoutOrder = toastOrder,
        ClipsDescendants = true,
        ZIndex = 101,
        Parent = ToastContainer,
    })
    Corner(card, 8)
    Stroke(card, Theme.Border, 1)

    New("Frame", {
        Name = "Accent",
        Size = UDim2.new(0, 3, 1, -12),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 6, 0.5, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        ZIndex = 102,
        Parent = card,
    })
    Corner(card:FindFirstChild("Accent"), 2)

    local iconBG = New("Frame", {
        Name = "IconBG",
        Size = UDim2.fromOffset(28, 28),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 16, 0.5, 0),
        BackgroundColor3 = accentColor,
        BackgroundTransparency = 0.85,
        ZIndex = 102,
        Parent = card,
    })
    Corner(iconBG, 8)

    local iconName = nil
    local iconEmoji = nil

    if rawIcon then
        if IsLucideName(rawIcon) then
            iconName = rawIcon
        else
            iconEmoji = rawIcon
        end
    elseif TOAST_FALLBACK[toastType] then
        iconEmoji = TOAST_FALLBACK[toastType]
    end

    if iconName then
        local fallbackLetter = string.upper(string.sub(iconName, 1, 1))

        local fallback = New("TextLabel", {
            Name = "Fallback",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = fallbackLetter,
            TextColor3 = accentColor,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            ZIndex = 103,
            Parent = iconBG,
        })

        local img = New("ImageLabel", {
            Name = "LucideIcon",
            Size = UDim2.fromOffset(16, 16),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = accentColor,
            ImageTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 104,
            Parent = iconBG,
        })

        coroutine.resume(coroutine.create(function()
            local asset = FetchLucideIcon(iconName)
            if not asset or not img.Parent then return end
            img.Image = asset
            task.wait(0.3)
            if not img.Parent then return end
            local loaded = pcall(function() return img.IsLoaded end)
            if loaded and img.IsLoaded then
                Tween(img, TI.Fast, {ImageTransparency = 0})
                Tween(fallback, TI.Fast, {TextTransparency = 1})
            end
        end))
    else
        New("TextLabel", {
            Name = "Icon",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = iconEmoji or TOAST_FALLBACK.info,
            TextColor3 = accentColor,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            ZIndex = 103,
            Parent = iconBG,
        })
    end

    local textX = 52
    local textW = TOAST_W - textX - 12
    local yOff = 8

    if title ~= "" then
        New("TextLabel", {
            Name = "Title",
            Size = UDim2.fromOffset(textW, 16),
            Position = UDim2.fromOffset(textX, yOff),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 102,
            Parent = card,
        })
        yOff = yOff + 16
    end

    if hasSubtitle then
        New("TextLabel", {
            Name = "Subtitle",
            Size = UDim2.fromOffset(textW, 13),
            Position = UDim2.fromOffset(textX, yOff),
            BackgroundTransparency = 1,
            Text = subtitle,
            TextColor3 = Theme.TextMuted,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 102,
            Parent = card,
        })
        yOff = yOff + 14
    end

    if hasDesc then
        yOff = yOff + 4
        New("TextLabel", {
            Name = "Description",
            Size = UDim2.fromOffset(textW, cardH - yOff - 8),
            Position = UDim2.fromOffset(textX, yOff),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = Theme.TextSub,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 102,
            Parent = card,
        })
    end

    local progressBG = New("Frame", {
        Name = "ProgressBG",
        Size = UDim2.new(1, 0, 0, 2),
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.SurfaceLight,
        BorderSizePixel = 0,
        ZIndex = 103,
        Parent = card,
    })

    local progressFill = New("Frame", {
        Name = "Fill",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        ZIndex = 104,
        Parent = progressBG,
    })

    card.Position = UDim2.fromOffset(TOAST_W + 20, 0)
    card.BackgroundTransparency = 0.1

    Tween(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.fromOffset(0, 0)})

    TS:Create(progressFill,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0, 0, 1, 0)}):Play()

    task.delay(duration, function()
        if not card.Parent then return end
        local exitTween = Tween(card,
            TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {Position = UDim2.fromOffset(TOAST_W + 20, 0), BackgroundTransparency = 1})
        exitTween.Completed:Once(function()
            card:Destroy()
        end)
    end)

    return card
end

function Loader:Toast(config)
    if type(config) == "string" then
        config = {Title = config}
    end
    return CreateToast(config)
end

function Loader:Destroy()
    if loadingDotsConn then loadingDotsConn:Disconnect() end
    spinnerTween:Cancel()
    for _, c in ipairs(State.Connections) do
        c:Disconnect()
    end
    Gui:Destroy()
end

return Loader

end

local ok, result = xpcall(__INIT__, function(err)
    local trace = debug.traceback(err, 2)
    local msg = "[IMP HUB X] LOAD ERROR:\n" .. tostring(trace)

    pcall(function()
        warn(msg)
    end)

    pcall(function()
        local errGui = Instance.new("ScreenGui")
        errGui.Name = "ImpHubError"
        errGui.ResetOnSpawn = false
        errGui.DisplayOrder = 99999
        errGui.IgnoreGuiInset = true

        local pOk = pcall(function() errGui.Parent = game:GetService("CoreGui") end)
        if not pOk then
            errGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end

        local bg = Instance.new("Frame")
        bg.Size = UDim2.fromScale(1, 1)
        bg.BackgroundColor3 = Color3.new(0, 0, 0)
        bg.BackgroundTransparency = 0.3
        bg.ZIndex = 1
        bg.Parent = errGui

        local card = Instance.new("Frame")
        card.Size = UDim2.fromOffset(500, 260)
        card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.Position = UDim2.fromScale(0.5, 0.5)
        card.BackgroundColor3 = Color3.fromRGB(18, 12, 12)
        card.ZIndex = 2
        card.Parent = errGui
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

        local stripe = Instance.new("Frame")
        stripe.Size = UDim2.new(1, 0, 0, 3)
        stripe.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        stripe.BorderSizePixel = 0
        stripe.ZIndex = 3
        stripe.Parent = card

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -24, 0, 22)
        title.Position = UDim2.fromOffset(12, 14)
        title.BackgroundTransparency = 1
        title.Text = "IMP HUB X  —  Script Error"
        title.TextColor3 = Color3.fromRGB(220, 60, 60)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.ZIndex = 3
        title.Parent = card

        local body = Instance.new("TextLabel")
        body.Size = UDim2.new(1, -24, 1, -80)
        body.Position = UDim2.fromOffset(12, 44)
        body.BackgroundTransparency = 1
        body.Text = tostring(trace)
        body.TextColor3 = Color3.fromRGB(200, 200, 210)
        body.Font = Enum.Font.Code
        body.TextSize = 11
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.TextWrapped = true
        body.ZIndex = 3
        body.Parent = card

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(1, -24, 0, 28)
        closeBtn.AnchorPoint = Vector2.new(0.5, 1)
        closeBtn.Position = UDim2.new(0.5, 0, 1, -10)
        closeBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
        closeBtn.Text = "CLOSE"
        closeBtn.TextColor3 = Color3.fromRGB(220, 60, 60)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 11
        closeBtn.ZIndex = 3
        closeBtn.Parent = card
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

        closeBtn.MouseButton1Click:Connect(function()
            errGui:Destroy()
        end)
    end)

    return nil
end)

if not ok then
    return nil
end

return result
