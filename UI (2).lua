--[[
========================================================================
    UI.lua  —  Retina Login UI
========================================================================
    A clean, modern Roblox login interface built in a single file.
    Premium animations, full drag support (mouse + touch), responsive
    scaling, and a Kronos-style API.

------------------------------------------------------------------------
    USAGE
------------------------------------------------------------------------
    local UI = loadfile("UI.lua")()

    local Window = UI:CreateWindow({
        Title = "RETINA",
        Subtitle = "Welcome again, please log in to continue.",
        Logo = "rbxassetid://LOGO",
        Footer = "@PastOwl",
    })

    Window:OnClose(function()
        print("Closed")
    end)

    Window:OnLogin(function(username, password)
        print(username, password)
    end)

    Window:OnPurchase(function()
        print("Purchase")
    end)

    Window:Show()

------------------------------------------------------------------------
    API REFERENCE
------------------------------------------------------------------------
    UI:CreateWindow(config)          -> Window
        config.Title      (string)   — main title text ("RETINA")
        config.Subtitle   (string)   — subtitle under the title
        config.Logo       (string)   — rbxassetid for the left-panel logo
        config.Footer     (string)   — small text at bottom of left panel

    Window:SetTitle(text)
    Window:SetSubtitle(text)
    Window:SetLogo(assetId)
    Window:SetFooter(text)
    Window:OnClose(callback)         — fired after the close animation
    Window:OnLogin(callback)         — callback(username, password)
    Window:OnPurchase(callback)      — fired when subscription btn pressed
    Window:Show()                    — plays the open animation
    Window:Hide()                    — plays the close animation, then destroys
    Window:Destroy()                 — instantly destroys the UI
========================================================================
]]

-- ============================================================
-- SERVICES
-- ============================================================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- THEME  (tuned to match the reference mockup)
-- ============================================================
local Theme = {
    Window        = Color3.fromRGB(20, 20, 26),
    LeftPanelTop  = Color3.fromRGB(140, 122, 255),
    LeftPanelBot  = Color3.fromRGB(98, 80, 200),
    RightPanel    = Color3.fromRGB(20, 20, 26),
    Accent        = Color3.fromRGB(124, 105, 240),
    AccentHover   = Color3.fromRGB(140, 122, 255),
    Text          = Color3.fromRGB(255, 255, 255),
    TextDim       = Color3.fromRGB(160, 160, 170),
    Border        = Color3.fromRGB(48, 48, 56),
    BorderFocus   = Color3.fromRGB(124, 105, 240),
    Secondary     = Color3.fromRGB(36, 36, 44),
    SecondaryHov  = Color3.fromRGB(52, 52, 62),
    Close         = Color3.fromRGB(160, 160, 170),
    CloseHover    = Color3.fromRGB(232, 72, 72),
    Divider       = Color3.fromRGB(60, 60, 70),
}

-- ============================================================
-- TWEEN HELPER
-- ============================================================
local function tween(instance, props, duration, style, direction)
    local info = TweenInfo.new(
        duration  or 0.2,
        style     or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

-- ============================================================
-- RESPONSIVE UTILITY
-- Scales the window down on small viewports so it never clips.
-- ============================================================
local function bindResponsiveScale(uiscale, baseW, baseH, margin)
    local camera = workspace.CurrentCamera
    local function update()
        local vp = camera.ViewportSize
        local availX = vp.X - (margin or 32)
        local availY = vp.Y - (margin or 32)
        local s = math.min(availX / baseW, availY / baseH, 1)
        uiscale.Scale = s
    end
    update()
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
end

-- ============================================================
-- DRAGGING UTILITY
-- Smooth, jitter-free dragging for mouse + touch. Skips drag when
-- the press lands on an interactive element (button / textbox).
-- ============================================================
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragInput, dragStart, startPos

    local function isOverInteractive(pos)
        local objects = UserInputService:GetGuiObjectsAtPosition(pos.X, pos.Y)
        for _, obj in ipairs(objects) do
            if obj:IsA("TextButton") or obj:IsA("TextBox") or obj:IsA("ImageButton") then
                return true
            end
        end
        return false
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if isOverInteractive(input.Position) then return end
            dragging = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- PRIMITIVE FACTORIES
-- ============================================================
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function gradient(parent, c1, c2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end

-- ============================================================
-- BUTTON FACTORY
-- Hover: color fade + 1.02 scale. Press: 0.96 scale with a small
-- spring-back on release.
-- ============================================================
local function makeButton(props)
    local b = Instance.new("TextButton")
    b.Name             = props.Name or "Button"
    b.AutoButtonColor  = false
    b.BackgroundColor3 = props.Color or Theme.Accent
    b.BackgroundTransparency = props.Transparency or 0
    b.BorderSizePixel  = 0
    b.Text             = props.Text or ""
    b.TextColor3       = props.TextColor or Theme.Text
    b.Font             = props.Font or Enum.Font.GothamMedium
    b.TextSize         = props.TextSize or 15
    b.Size             = props.Size or UDim2.new(1, 0, 0, 44)
    b.Position         = props.Position or UDim2.new(0, 0, 0, 0)
    b.AnchorPoint      = props.AnchorPoint or Vector2.new(0, 0)
    b.LayoutOrder      = props.LayoutOrder or 0
    b.Parent           = props.Parent
    corner(b, props.Radius or 10)

    if props.Stroke then
        stroke(b, props.Stroke.Color, props.Stroke.Thickness, props.Stroke.Transparency)
    end
    if props.Gradient then
        gradient(b, props.Gradient[1], props.Gradient[2], props.Gradient.Rotation or 90)
    end

    -- UIScale drives all hover/press scale animation
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = b

    local baseColor  = b.BackgroundColor3
    local hoverColor = props.HoverColor or Theme.AccentHover

    b.MouseEnter:Connect(function()
        tween(b, { BackgroundColor3 = hoverColor }, 0.18)
        tween(scale, { Scale = 1.02 }, 0.18)
    end)
    b.MouseLeave:Connect(function()
        tween(b, { BackgroundColor3 = baseColor }, 0.18)
        tween(scale, { Scale = 1 }, 0.18)
    end)
    b.MouseButton1Down:Connect(function()
        tween(scale, { Scale = 0.96 }, 0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    end)
    b.MouseButton1Up:Connect(function()
        tween(scale, { Scale = 1.02 }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    return b
end

-- ============================================================
-- INPUT FACTORY
-- Focus: stroke color animates to accent + thickness grows, and a
-- soft purple glow blooms behind the field.
-- ============================================================
local function makeInput(props)
    local container = Instance.new("Frame")
    container.Name             = props.Name or "Input"
    container.Size             = props.Size or UDim2.new(1, 0, 0, 44)
    container.Position         = props.Position or UDim2.new(0, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.LayoutOrder      = props.LayoutOrder or 0
    container.Parent           = props.Parent

    -- Glow halo (sits behind the field, invisible until focus)
    local glow = Instance.new("Frame")
    glow.Name             = "Glow"
    glow.Size             = UDim2.new(1, 8, 1, 8)
    glow.Position         = UDim2.new(0, -4, 0, -4)
    glow.BackgroundColor3 = Theme.Accent
    glow.BackgroundTransparency = 1
    glow.BorderSizePixel  = 0
    glow.ZIndex           = 0
    corner(glow, 14)
    glow.Parent = container

    -- Field background
    local bg = Instance.new("Frame")
    bg.Name             = "Background"
    bg.Size             = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Theme.Secondary
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel  = 0
    bg.ZIndex           = 1
    corner(bg, 10)
    bg.Parent = container

    local st = stroke(bg, Theme.Border, 1, 0)

    -- Textbox
    local box = Instance.new("TextBox")
    box.Name                  = "TextBox"
    box.Size                  = UDim2.new(1, -24, 1, 0)
    box.Position              = UDim2.new(0, 12, 0, 0)
    box.BackgroundTransparency = 1
    box.Text                  = ""
    box.PlaceholderText       = props.Placeholder or ""
    box.PlaceholderColor3     = Theme.TextDim
    box.TextColor3            = Theme.Text
    box.Font                  = Enum.Font.Gotham
    box.TextSize              = 14
    box.ClearTextOnFocus      = false
    box.TextXAlignment        = Enum.TextXAlignment.Left
    box.ClipsDescendants      = true
    box.ZIndex                = 2
    box.Parent = bg

    box.Focused:Connect(function()
        tween(st, { Color = Theme.BorderFocus, Thickness = 1.5 }, 0.2)
        tween(glow, { BackgroundTransparency = 0.85 }, 0.3)
    end)
    box.FocusLost:Connect(function()
        tween(st, { Color = Theme.Border, Thickness = 1 }, 0.2)
        tween(glow, { BackgroundTransparency = 1 }, 0.3)
    end)

    return container, box
end

-- ============================================================
-- WINDOW FACTORY  (the main entry point)
-- ============================================================
local function createWindow(config)
    config = config or {}

    local callbacks = {
        onClose    = nil,
        onLogin    = nil,
        onPurchase = nil,
    }

    local BASE_W = 720
    local BASE_H = 460

    -- ===== ScreenGui =====
    local gui = Instance.new("ScreenGui")
    gui.Name             = "RetinaLogin"
    gui.ResetOnSpawn     = false
    gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset   = true

    pcall(function()
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
    if not gui.Parent then
        gui.Parent = workspace
    end

    -- ===== Backdrop (dim overlay) =====
    local backdrop = Instance.new("Frame")
    backdrop.Name                  = "Backdrop"
    backdrop.Size                  = UDim2.new(1, 0, 1, 0)
    backdrop.Position              = UDim2.new(0, 0, 0, 0)
    backdrop.BackgroundColor3      = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 1   -- hidden until Show()
    backdrop.BorderSizePixel       = 0
    backdrop.ZIndex                = 0
    backdrop.Parent = gui

    -- ===== Holder (CanvasGroup for whole-window fade) =====
    local holder = Instance.new("CanvasGroup")
    holder.Name             = "Holder"
    holder.Size             = UDim2.new(0, BASE_W, 0, BASE_H)
    holder.Position         = UDim2.new(0.5, 0, 0.5, 0)
    holder.AnchorPoint      = Vector2.new(0.5, 0.5)
    holder.BackgroundTransparency = 1
    holder.GroupTransparency = 1
    holder.ZIndex           = 1
    holder.Parent = gui

    local uiscale = Instance.new("UIScale")
    uiscale.Scale = 1
    uiscale.Parent = holder
    bindResponsiveScale(uiscale, BASE_W, BASE_H, 32)

    -- ===== Window (the visible dark panel) =====
    local window = Instance.new("Frame")
    window.Name             = "Window"
    window.Size             = UDim2.new(1, 0, 1, 0)
    window.BackgroundColor3 = Theme.Window
    window.BorderSizePixel  = 0
    window.Parent = holder
    corner(window, 14)
    stroke(window, Color3.fromRGB(40, 40, 50), 1, 0.4)

    -- Soft drop shadow (9-slice image)
    local shadow = Instance.new("ImageLabel")
    shadow.Name             = "Shadow"
    shadow.Size             = UDim2.new(1, 64, 1, 64)
    shadow.Position         = UDim2.new(0, -32, 0, -32)
    shadow.BackgroundTransparency = 1
    shadow.Image            = "rbxassetid://1316045217"
    shadow.ImageColor3      = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.45
    shadow.ScaleType        = Enum.ScaleType.Slice
    shadow.SliceCenter      = Rect.new(10, 10, 118, 118)
    shadow.ZIndex           = -1
    shadow.Parent = window

    -- ============= LEFT PANEL (Purple branding) =============
    local leftPanel = Instance.new("Frame")
    leftPanel.Name             = "LeftPanel"
    leftPanel.Size             = UDim2.new(0.5, 0, 1, 0)
    leftPanel.Position         = UDim2.new(0, 0, 0, 0)
    leftPanel.BackgroundColor3 = Theme.LeftPanelTop
    leftPanel.BorderSizePixel  = 0
    leftPanel.Parent = window
    corner(leftPanel, 14)
    gradient(leftPanel, Theme.LeftPanelTop, Theme.LeftPanelBot, 120)

    -- Square off the interior right edge so it meets RightPanel cleanly
    local leftCover = Instance.new("Frame")
    leftCover.Name             = "RightEdgeCover"
    leftCover.Size             = UDim2.new(0, 14, 1, 0)
    leftCover.Position         = UDim2.new(1, -14, 0, 0)
    leftCover.BackgroundColor3 = Theme.LeftPanelTop
    leftCover.BorderSizePixel  = 0
    leftCover.Parent = leftPanel
    gradient(leftCover, Theme.LeftPanelTop, Theme.LeftPanelBot, 120)

    -- Logo (centered)
    local logo = Instance.new("ImageLabel")
    logo.Name             = "Logo"
    logo.Size             = UDim2.new(0, 110, 0, 110)
    logo.Position         = UDim2.new(0.5, 0, 0.5, 0)
    logo.AnchorPoint      = Vector2.new(0.5, 0.5)
    logo.BackgroundTransparency = 1
    logo.Image            = config.Logo or ""
    logo.ImageColor3      = Color3.fromRGB(255, 255, 255)
    logo.Parent = leftPanel

    -- Footer text (bottom-left credit)
    local footer = Instance.new("TextLabel")
    footer.Name             = "Footer"
    footer.Size             = UDim2.new(0, 200, 0, 20)
    footer.Position         = UDim2.new(0, 22, 1, -28)
    footer.BackgroundTransparency = 1
    footer.Text             = config.Footer or "@PastOwl"
    footer.TextColor3       = Color3.fromRGB(255, 255, 255)
    footer.TextTransparency = 0.25
    footer.Font             = Enum.Font.Gotham
    footer.TextSize         = 12
    footer.TextXAlignment   = Enum.TextXAlignment.Left
    footer.Parent = leftPanel

    -- ============= RIGHT PANEL (Login form) =============
    local rightPanel = Instance.new("Frame")
    rightPanel.Name             = "RightPanel"
    rightPanel.Size             = UDim2.new(0.5, 0, 1, 0)
    rightPanel.Position         = UDim2.new(0.5, 0, 0, 0)
    rightPanel.BackgroundColor3 = Theme.RightPanel
    rightPanel.BorderSizePixel  = 0
    rightPanel.Parent = window
    corner(rightPanel, 14)

    -- Square off the interior left edge
    local rightCover = Instance.new("Frame")
    rightCover.Name             = "LeftEdgeCover"
    rightCover.Size             = UDim2.new(0, 14, 1, 0)
    rightCover.Position         = UDim2.new(0, 0, 0, 0)
    rightCover.BackgroundColor3 = Theme.RightPanel
    rightCover.BorderSizePixel  = 0
    rightCover.Parent = rightPanel

    -- ===== Close button (top-right) =====
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name             = "Close"
    closeBtn.Size             = UDim2.new(0, 30, 0, 30)
    closeBtn.Position         = UDim2.new(1, -18, 0, 18)
    closeBtn.AnchorPoint      = Vector2.new(1, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.Text             = ""
    closeBtn.AutoButtonColor  = false
    closeBtn.ZIndex           = 5
    closeBtn.Parent = rightPanel
    corner(closeBtn, 8)

    -- Draw the X with two rotated Frames (reliable across fonts)
    local closeLine1 = Instance.new("Frame")
    closeLine1.Name             = "Line1"
    closeLine1.Size             = UDim2.new(0, 12, 0, 2)
    closeLine1.Position         = UDim2.new(0.5, 0, 0.5, 0)
    closeLine1.AnchorPoint      = Vector2.new(0.5, 0.5)
    closeLine1.BackgroundColor3 = Theme.Close
    closeLine1.BorderSizePixel  = 0
    closeLine1.Rotation         = 45
    closeLine1.Parent = closeBtn

    local closeLine2 = Instance.new("Frame")
    closeLine2.Name             = "Line2"
    closeLine2.Size             = UDim2.new(0, 12, 0, 2)
    closeLine2.Position         = UDim2.new(0.5, 0, 0.5, 0)
    closeLine2.AnchorPoint      = Vector2.new(0.5, 0.5)
    closeLine2.BackgroundColor3 = Theme.Close
    closeLine2.BorderSizePixel  = 0
    closeLine2.Rotation         = -45
    closeLine2.Parent = closeBtn

    local closeScale = Instance.new("UIScale")
    closeScale.Scale = 1
    closeScale.Parent = closeBtn

    local closeWhite = Color3.fromRGB(255, 255, 255)
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, { BackgroundColor3 = Theme.CloseHover, BackgroundTransparency = 0 }, 0.15)
        tween(closeLine1, { BackgroundColor3 = closeWhite }, 0.15)
        tween(closeLine2, { BackgroundColor3 = closeWhite }, 0.15)
        tween(closeScale, { Scale = 1.08 }, 0.15)
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(40, 40, 48), BackgroundTransparency = 0.5 }, 0.15)
        tween(closeLine1, { BackgroundColor3 = Theme.Close }, 0.15)
        tween(closeLine2, { BackgroundColor3 = Theme.Close }, 0.15)
        tween(closeScale, { Scale = 1 }, 0.15)
    end)
    closeBtn.MouseButton1Down:Connect(function()
        tween(closeScale, { Scale = 0.9 }, 0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    end)
    closeBtn.MouseButton1Up:Connect(function()
        tween(closeScale, { Scale = 1.08 }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    -- ===== Right panel content =====
    local content = Instance.new("Frame")
    content.Name             = "Content"
    content.Size             = UDim2.new(1, -56, 1, -56)
    content.Position         = UDim2.new(0, 28, 0, 28)
    content.BackgroundTransparency = 1
    content.Parent = rightPanel

    -- RETINA title
    local title = Instance.new("TextLabel")
    title.Name             = "Title"
    title.Size             = UDim2.new(1, 0, 0, 36)
    title.Position         = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text             = config.Title or "RETINA"
    title.TextColor3       = Theme.Text
    title.Font             = Enum.Font.GothamBlack
    title.TextSize         = 28
    title.TextXAlignment   = Enum.TextXAlignment.Left
    title.Parent = content

    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name             = "Subtitle"
    subtitle.Size             = UDim2.new(1, 0, 0, 20)
    subtitle.Position         = UDim2.new(0, 0, 0, 38)
    subtitle.BackgroundTransparency = 1
    subtitle.Text             = config.Subtitle or "Welcome again, please log in to continue."
    subtitle.TextColor3       = Theme.TextDim
    subtitle.Font             = Enum.Font.Gotham
    subtitle.TextSize         = 13
    subtitle.TextXAlignment   = Enum.TextXAlignment.Left
    subtitle.Parent = content

    -- ===== Form layout (fixed pixel math, scales via UIScale) =====
    local formY   = 78
    local inputH  = 44
    local gap     = 12

    local _, userInput = makeInput({
        Parent      = content,
        Size        = UDim2.new(1, 0, 0, inputH),
        Position    = UDim2.new(0, 0, 0, formY),
        Placeholder = "Enter username",
        Name        = "Username",
    })

    local _, passInput = makeInput({
        Parent      = content,
        Size        = UDim2.new(1, 0, 0, inputH),
        Position    = UDim2.new(0, 0, 0, formY + inputH + gap),
        Placeholder = "Enter password",
        Name        = "Password",
    })
    passInput.TextSecure = true

    local continueBtn = makeButton({
        Parent     = content,
        Size       = UDim2.new(1, 0, 0, inputH),
        Position   = UDim2.new(0, 0, 0, formY + (inputH + gap) * 2),
        Text       = "Continue",
        Color      = Theme.Accent,
        HoverColor = Theme.AccentHover,
        TextSize   = 15,
        Font       = Enum.Font.GothamMedium,
        Radius     = 10,
        Gradient   = { Theme.Accent, Theme.AccentHover, Rotation = 90 },
    })

    -- ===== OR separator =====
    local sepY = formY + (inputH + gap) * 2 + inputH + 18

    local orLeft = Instance.new("Frame")
    orLeft.Name             = "OrLineLeft"
    orLeft.Size             = UDim2.new(0.42, 0, 0, 1)
    orLeft.Position         = UDim2.new(0, 0, 0, sepY + 9)
    orLeft.BackgroundColor3 = Theme.Divider
    orLeft.BorderSizePixel  = 0
    orLeft.Parent = content

    local orText = Instance.new("TextLabel")
    orText.Name             = "OrText"
    orText.Size             = UDim2.new(0.16, 0, 0, 20)
    orText.Position         = UDim2.new(0.42, 0, 0, sepY)
    orText.BackgroundTransparency = 1
    orText.Text             = "OR"
    orText.TextColor3       = Theme.TextDim
    orText.Font             = Enum.Font.GothamMedium
    orText.TextSize         = 12
    orText.Parent = content

    local orRight = Instance.new("Frame")
    orRight.Name             = "OrLineRight"
    orRight.Size             = UDim2.new(0.42, 0, 0, 1)
    orRight.Position         = UDim2.new(0.58, 0, 0, sepY + 9)
    orRight.BackgroundColor3 = Theme.Divider
    orRight.BorderSizePixel  = 0
    orRight.Parent = content

    -- ===== Purchase subscription button =====
    local purchaseY = sepY + 30
    local purchaseBtn = makeButton({
        Parent     = content,
        Size       = UDim2.new(1, 0, 0, inputH),
        Position   = UDim2.new(0, 0, 0, purchaseY),
        Text       = "Purchasing a subscription",
        Color      = Theme.Secondary,
        HoverColor = Theme.SecondaryHov,
        TextColor  = Theme.Text,
        TextSize   = 14,
        Font       = Enum.Font.GothamMedium,
        Radius     = 10,
        Stroke     = { Color = Theme.Border, Thickness = 1, Transparency = 0 },
    })

    -- ===== Dragging (whole window, skips interactive elements) =====
    makeDraggable(holder, window)

    -- ===== Behavior wiring =====
    continueBtn.Activated:Connect(function()
        if callbacks.onLogin then
            callbacks.onLogin(userInput.Text, passInput.Text)
        end
    end)
    passInput.FocusLost:Connect(function(enter)
        if enter and callbacks.onLogin then
            callbacks.onLogin(userInput.Text, passInput.Text)
        end
    end)
    purchaseBtn.Activated:Connect(function()
        if callbacks.onPurchase then
            callbacks.onPurchase()
        end
    end)

    -- ===== Open / Close animations =====
    local isShown   = false
    local isClosing = false

    local function animateOpen()
        holder.GroupTransparency      = 1
        uiscale.Scale                 = 0.9
        backdrop.BackgroundTransparency = 1

        tween(uiscale,   { Scale = 1 }, 0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tween(holder,    { GroupTransparency = 0 }, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tween(backdrop,  { BackgroundTransparency = 0.5 }, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    local function animateClose(onDone)
        isClosing = true
        tween(uiscale, { Scale = 0.92 }, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local t = tween(holder, { GroupTransparency = 1 }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(backdrop, { BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Once(function()
            if onDone then onDone() end
            gui:Destroy()
        end)
    end

    closeBtn.Activated:Connect(function()
        if isClosing then return end
        animateClose(function()
            if callbacks.onClose then callbacks.onClose() end
        end)
    end)

    -- ===== Window API =====
    local Window = {}

    function Window:SetTitle(text)
        title.Text = text
    end

    function Window:SetSubtitle(text)
        subtitle.Text = text
    end

    function Window:SetLogo(assetId)
        logo.Image = assetId
    end

    function Window:SetFooter(text)
        footer.Text = text
    end

    function Window:OnClose(cb)    callbacks.onClose    = cb end
    function Window:OnLogin(cb)    callbacks.onLogin    = cb end
    function Window:OnPurchase(cb) callbacks.onPurchase = cb end

    function Window:Show()
        if isShown then return end
        isShown = true
        animateOpen()
        return self
    end

    function Window:Hide()
        if not isShown or isClosing then return end
        isShown = false
        animateClose()
        return self
    end

    function Window:Destroy()
        gui:Destroy()
    end

    -- Exposed for advanced consumers
    Window._gui    = gui
    Window._holder = holder
    Window._window = window

    return Window
end

-- ============================================================
-- MODULE EXPORT
-- The file returns its table directly so that
-- `local UI = loadfile("UI.lua")()` gives you the API table.
-- ============================================================
return {
    CreateWindow = createWindow,
    Theme        = Theme,
}
