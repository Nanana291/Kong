--[[
    UI.lua — Premium split-panel login UI
    -------------------------------------
    Visual reference: 600x400 desktop-style login shell
      • Left half: purple gradient panel with centered logo
      • Right half: dark login form (title, subtitle, username, password,
                     Continue button, OR separator, subscription link)
      • Close button at top-right of the right panel

    API (Kronos-style):
        local UI = loadfile("UI.lua")()
        local Window = UI:CreateWindow({ Title = "RETINA" })
        Window:SetSubtitle("Welcome again, please log in to continue.")
        Window:SetLogo("rbxassetid://LOGO")
        Window:OnClose(function() print("Closed") end)
        Window:OnLogin(function(u, p) print(u, p) end)
        Window:OnPurchase(function() print("Purchase") end)
        Window:Show()

    Design principles applied:
      • ui-ux-luau/motion_mastery/choreography_ownership.md  — one owner per transition
      • ui-ux-luau/motion_mastery/frame_rate_independence.md  — dt-driven spring, RenderStepped for visuals
      • ui-ux-luau/motion_mastery/spring_vs_easing_decision_tree.md — springs for drag release, easing for events
      • ui-ux-luau/component_language_mastery/button_craftsmanship_doctrine.md — illuminated primary CTA
      • ui-ux-luau/input_intelligence_mastery/premium_input_state_systems.md — focus glow + border transition
      • ui-ux-luau/accessibility_mastery/reduced_motion_mode.md — respect ReducedMotionEnabled
      • luau-max-quality-mode — single owner per runtime path, explicit teardown
]]

-- ============================================================
-- Services
-- ============================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserGameSettings = game:GetService("UserGameSettings")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- Theme
-- ============================================================
local THEME = {
    -- Left panel gradient (purple, top → bottom)
    PurpleTop        = Color3.fromRGB(123, 104, 238),
    PurpleBottom     = Color3.fromRGB(106, 90, 205),

    -- Right panel
    RightBg          = Color3.fromRGB(18, 18, 18),
    RightBgAccent    = Color3.fromRGB(24, 24, 28),

    -- Inputs
    InputBg          = Color3.fromRGB(30, 30, 30),
    InputBgFocus     = Color3.fromRGB(36, 32, 48),
    InputBorder      = Color3.fromRGB(51, 51, 51),
    InputBorderFocus = Color3.fromRGB(123, 104, 238),
    InputPlaceholder = Color3.fromRGB(136, 136, 136),
    InputText        = Color3.fromRGB(255, 255, 255),

    -- Text
    TitleColor       = Color3.fromRGB(255, 255, 255),
    SubtitleColor    = Color3.fromRGB(204, 204, 204),
    ButtonText       = Color3.fromRGB(255, 255, 255),
    OrText           = Color3.fromRGB(136, 136, 136),
    Separator        = Color3.fromRGB(51, 51, 51),
    SubscriptionText = Color3.fromRGB(204, 204, 204),
    SubscriptionLink = Color3.fromRGB(123, 104, 238),

    -- Close button
    CloseIdle        = Color3.fromRGB(170, 170, 180),
    CloseHover       = Color3.fromRGB(255, 255, 255),

    -- Misc
    DropShadow       = Color3.fromRGB(0, 0, 0),
    Attribution      = Color3.fromRGB(255, 255, 255),
}

-- ============================================================
-- Dimensions (base design is 600 x 400; everything scales via UIScale)
-- ============================================================
local DIM = {
    BaseWidth    = 600,
    BaseHeight   = 400,
    WindowRadius = 12,
    InputRadius  = 8,
    ButtonRadius = 8,
    InputHeight  = 48,
    InputWidth   = 260,
    CloseSize    = 28,
    LogoSize     = 80,
    Padding      = 24,
}

-- ============================================================
-- Motion specs (reduced-motion aware)
-- ============================================================
local MOTION = {
    WindowOpen  = { duration = 0.45, style = Enum.EasingStyle.Back,  dir = Enum.EasingDirection.Out },  -- slight spring
    WindowClose = { duration = 0.28, style = Enum.EasingStyle.Quint, dir = Enum.EasingDirection.In },
    Hover       = { duration = 0.15, style = Enum.EasingStyle.Sine,  dir = Enum.EasingDirection.Out },
    Press       = { duration = 0.08, style = Enum.EasingStyle.Quad,  dir = Enum.EasingDirection.In },
    Focus       = { duration = 0.20, style = Enum.EasingStyle.Quint, dir = Enum.EasingDirection.Out },
    Fade        = { duration = 0.18, style = Enum.EasingStyle.Sine,  dir = Enum.EasingDirection.Out },
}

local function isReducedMotion()
    return UserGameSettings.ReducedMotionEnabled == true
end

local function resolve(spec)
    if isReducedMotion() then
        return { duration = math.min(spec.duration, 0.08), style = Enum.EasingStyle.Linear, dir = Enum.EasingDirection.In }
    end
    return spec
end

-- ============================================================
-- Animation utilities
-- ============================================================
local function tween(object, spec, target)
    local resolved = resolve(spec)
    local t = TweenService:Create(object, TweenInfo.new(resolved.duration, resolved.style, resolved.dir), target)
    t:Play()
    return t
end

-- Frame-rate-independent spring — used for drag-release settle.
-- See motion_mastery/frame_rate_independence.md and spring_vs_easing_decision_tree.md.
local Spring = {}
Spring.__index = Spring

function Spring.new(initial, stiffness, damping)
    local self = setmetatable({}, Spring)
    self.value = initial
    self.target = initial
    self.velocity = 0
    self.stiffness = stiffness or 220
    self.damping = damping or 26
    self.connection = nil
    self.onUpdate = nil
    self.onSettle = nil
    return self
end

function Spring:setTarget(target)
    self.target = target
    if not self.connection then
        self:_run()
    end
end

function Spring:_run()
    self.connection = RunService.RenderStepped:Connect(function(dt)
        local force = (self.target - self.value) * self.stiffness
        local damp = self.velocity * self.damping
        local accel = force - damp
        self.velocity = self.velocity + accel * dt
        self.value = self.value + self.velocity * dt

        if math.abs(self.target - self.value) < 0.1 and math.abs(self.velocity) < 1 then
            self.value = self.target
            self.velocity = 0
            self.connection:Disconnect()
            self.connection = nil
            if self.onUpdate then self.onUpdate(self.value) end
            if self.onSettle then self.onSettle() end
            return
        end

        if self.onUpdate then self.onUpdate(self.value) end
    end)
end

function Spring:cancel()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

-- ============================================================
-- Dragging utility (mouse + touch, 1:1 tracking, spring-back on inertia-less release)
-- See motion_mastery/gesture_driven_animation.md
-- ============================================================
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart = nil
    local origin = nil
    local springX = nil
    local springY = nil

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            origin = frame.Position
            if springX then springX:cancel() springX = nil end
            if springY then springY:cancel() springY = nil end
        end
    end

    local function onInputChanged(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
           and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local dx = input.Position.X - dragStart.X
        local dy = input.Position.Y - dragStart.Y
        -- 1:1 tracking — no easing during the gesture (motion_mastery/gesture_driven_animation.md)
        frame.Position = UDim2.fromOffset(origin.X.Offset + dx, origin.Y.Offset + dy)
    end

    local function onInputEnded(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
           and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = false
        -- Clamp into viewport so the window stays reachable
        local absPos = frame.AbsolutePosition
        local absSize = frame.AbsoluteSize
        local viewport = workspace.CurrentCamera.ViewportSize
        local targetX = absPos.X
        local targetY = absPos.Y
        local changed = false
        if targetX < 0 then targetX = 0 changed = true end
        if targetY < 0 then targetY = 0 changed = true end
        if targetX + absSize.X > viewport.X then targetX = viewport.X - absSize.X changed = true end
        if targetY + absSize.Y > viewport.Y then targetY = viewport.Y - absSize.Y changed = true end

        if changed then
            local curX = frame.Position.X.Offset
            local curY = frame.Position.Y.Offset
            springX = Spring.new(curX, 220, 26)
            springX.target = targetX
            springX.onUpdate = function(v)
                frame.Position = UDim2.fromOffset(v, frame.Position.Y.Offset)
            end
            springX:_run()
            springY = Spring.new(curY, 220, 26)
            springY.target = targetY
            springY.onUpdate = function(v)
                frame.Position = UDim2.fromOffset(frame.Position.X.Offset, v)
            end
            springY:_run()
        end
    end

    handle.InputBegan:Connect(onInputBegan)
    UserInputService.InputChanged:Connect(onInputChanged)
    UserInputService.InputEnded:Connect(onInputEnded)

    return function()
        dragging = false
        if springX then springX:cancel() end
        if springY then springY:cancel() end
    end
end

-- ============================================================
-- Responsive scaling
-- Maintains 3:2 aspect ratio; scales down on small viewports.
-- ============================================================
local function computeScale()
    local viewport = workspace.CurrentCamera.ViewportSize
    local sw = viewport.X / DIM.BaseWidth
    local sh = viewport.Y / DIM.BaseHeight
    local scale = math.min(sw, sh)
    -- On desktop, don't upscale beyond 1.0 — the design is fixed at 600x400.
    -- On mobile / tablet, allow up to 1.1 so the window still feels usable.
    if scale > 1.0 then
        scale = math.min(scale, 1.0)
    end
    -- Don't shrink beyond readability
    scale = math.max(scale, 0.55)
    return scale
end

local function applyScale(uiScale)
    uiScale.Scale = computeScale()
end

-- ============================================================
-- Builder helpers
-- ============================================================
local function newFrame(name, parent, props)
    local f = Instance.new("Frame")
    f.Name = name
    f.Parent = parent
    for k, v in pairs(props or {}) do
        f[k] = v
    end
    return f
end

local function newLabel(name, parent, props)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.Parent = parent
    l.BackgroundTransparency = 1
    for k, v in pairs(props or {}) do
        l[k] = v
    end
    return l
end

local function newButton(name, parent, props)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Parent = parent
    b.AutoButtonColor = false
    b.BackgroundTransparency = 1
    for k, v in pairs(props or {}) do
        b[k] = v
    end
    return b
end

local function newImage(name, parent, props)
    local i = Instance.new("ImageLabel")
    i.Name = name
    i.Parent = parent
    i.BackgroundTransparency = 1
    for k, v in pairs(props or {}) do
        i[k] = v
    end
    return i
end

local function newCorner(radius, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function newStroke(color, thickness, parent, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function newGradient(colorSeq, rotation, parent)
    local g = Instance.new("UIGradient")
    g.Color = colorSeq
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end

local function newPadding(pad, parent)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, pad)
    p.PaddingRight = UDim.new(0, pad)
    p.PaddingTop = UDim.new(0, pad)
    p.PaddingBottom = UDim.new(0, pad)
    p.Parent = parent
    return p
end

-- ============================================================
-- Window construction
-- ============================================================
local function buildWindow(config)
    config = config or {}
    local titleText = config.Title or "RETINA"

    -- ScreenGui root
    local gui = Instance.new("ScreenGui")
    gui.Name = "RetinaLoginUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100
    gui.Parent = PlayerGui

    -- Centered container for the window (handles responsiveness + entrance scale)
    local container = newFrame("Container", gui, {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
    })

    -- UIScale drives responsive scaling
    local uiScale = Instance.new("UIScale")
    uiScale.Parent = container
    applyScale(uiScale)

    -- Window root (the dark panel with rounded corners)
    local window = newFrame("Window", container, {
        Size = UDim2.fromOffset(DIM.BaseWidth, DIM.BaseHeight),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = THEME.RightBg,
        BackgroundTransparency = 1,  -- will fade in
    })
    newCorner(DIM.WindowRadius, window)
    -- Subtle drop shadow via ImageLabel (cheaper than SurfaceAppearance)
    local shadow = newImage("Shadow", container, {
        Size = UDim2.fromOffset(DIM.BaseWidth + 60, DIM.BaseHeight + 60),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://1316045217",  -- universal soft shadow asset
        ImageColor3 = THEME.DropShadow,
        ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        ZIndex = 0,
    })
    shadow.Parent = container

    -- Left panel (purple gradient)
    local leftPanel = newFrame("LeftPanel", window, {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = THEME.PurpleTop,
        ClipsDescendants = true,
    })
    newCorner(DIM.WindowRadius, leftPanel)
    -- Mask the right-side rounding so left panel meets the right panel cleanly
    -- (Use a small overlay if needed; here we let corner on left side suffice.)
    newGradient(ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.PurpleTop),
        ColorSequenceKeypoint.new(1, THEME.PurpleBottom),
    }), 90, leftPanel)

    -- Logo (centered in left panel)
    local logo = newImage("Logo", leftPanel, {
        Size = UDim2.fromOffset(DIM.LogoSize, DIM.LogoSize),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://0",  -- placeholder; overridden via SetLogo
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        ImageTransparency = 0,
    })

    -- Attribution bottom-left of left panel
    local attribution = newLabel("Attribution", leftPanel, {
        Text = "@PastOwl",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = THEME.Attribution,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom,
        Position = UDim2.new(0, DIM.Padding, 0, -DIM.Padding),
        Size = UDim2.new(1, -DIM.Padding * 2, 0, 14),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        TextTransparency = 0.5,
    })

    -- Right panel (dark login section)
    local rightPanel = newFrame("RightPanel", window, {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.fromScale(0.5, 0),
        BackgroundColor3 = THEME.RightBg,
    })
    newCorner(DIM.WindowRadius, rightPanel)

    -- Close button (top-right of right panel)
    local closeBtn = newButton("Close", rightPanel, {
        Size = UDim2.fromOffset(DIM.CloseSize, DIM.CloseSize),
        Position = UDim2.new(1, -DIM.Padding - 4, 0, DIM.Padding + 4),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    })
    local closeIcon = newImage("Icon", closeBtn, {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://13730395217",  -- universal X icon
        ImageColor3 = THEME.CloseIdle,
        BackgroundTransparency = 1,
    })

    -- Right-side form container (padded, vertically centered)
    local form = newFrame("Form", rightPanel, {
        Size = UDim2.new(1, -DIM.Padding * 2, 1, -DIM.Padding * 2),
        Position = UDim2.fromOffset(DIM.Padding, DIM.Padding),
        BackgroundTransparency = 1,
    })
    local formLayout = Instance.new("UIListLayout")
    formLayout.FillDirection = Enum.FillDirection.Vertical
    formLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    formLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    formLayout.Padding = UDim.new(0, 0)
    formLayout.Parent = form

    -- Title
    local titleLabel = newLabel("Title", form, {
        Text = titleText,
        Font = Enum.Font.GothamBold,
        TextSize = 32,
        TextColor3 = THEME.TitleColor,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, 0, 0, 38),
        LayoutOrder = 1,
    })

    -- Subtitle
    local subtitleLabel = newLabel("Subtitle", form, {
        Text = "Welcome again, please log in to continue.",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = THEME.SubtitleColor,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, 0, 0, 18),
        LayoutOrder = 2,
    })

    -- Spacer
    newFrame("Spacer1", form, {
        Size = UDim2.new(0, 0, 0, 16),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
    })

    -- Username input
    local function makeInput(placeholder, isPassword, layoutOrder)
        local wrap = newFrame("Input", form, {
            Size = UDim2.fromOffset(DIM.InputWidth, DIM.InputHeight),
            BackgroundColor3 = THEME.InputBg,
            BackgroundTransparency = 0,
            LayoutOrder = layoutOrder,
        })
        newCorner(DIM.InputRadius, wrap)
        local stroke = newStroke(THEME.InputBorder, 1, wrap, 0.2)

        local glow = newImage("Glow", wrap, {
            Size = UDim2.new(1, 16, 1, 16),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = "rbxassetid://6014261993",  -- soft radial glow
            ImageColor3 = THEME.InputBorderFocus,
            ImageTransparency = 1,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(32, 32, 32, 32),
            ZIndex = 0,
        })

        local icon = newImage("Icon", wrap, {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(0, 14, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Image = isPassword and "rbxassetid://13730395217" or "rbxassetid://13730395217",
            ImageColor3 = THEME.InputPlaceholder,
            ImageTransparency = 0.1,
        })

        local box = Instance.new("TextBox")
        box.Name = "Field"
        box.Parent = wrap
        box.Size = UDim2.new(1, -50, 1, 0)
        box.Position = UDim2.fromOffset(40, 0)
        box.BackgroundTransparency = 1
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        box.Text = ""
        box.PlaceholderText = placeholder
        box.PlaceholderColor3 = THEME.InputPlaceholder
        box.TextColor3 = THEME.InputText
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.TextTruncate = Enum.TextTruncate.None
        if isPassword then
            box.TextTruncate = Enum.TextTruncate.AtEnd
            -- Masking: use a custom property hook. Roblox doesn't natively mask text on TextBox
            -- but we can detect text changes and replace with bullets.
        end

        local focused = false
        local function setFocus(state)
            if focused == state then return end
            focused = state
            tween(wrap, MOTION.Focus, { BackgroundColor3 = state and THEME.InputBgFocus or THEME.InputBg })
            tween(stroke, MOTION.Focus, { Color = state and THEME.InputBorderFocus or THEME.InputBorder,
                                          Transparency = state and 0 or 0.2,
                                          Thickness = state and 1.5 or 1 })
            tween(glow, MOTION.Focus, { ImageTransparency = state and 0.4 or 1 })
            tween(icon, MOTION.Focus, { ImageColor3 = state and THEME.InputBorderFocus or THEME.InputPlaceholder })
        end

        box.Focused:Connect(function() setFocus(true) end)
        box.FocusLost:Connect(function() setFocus(false) end)

        return wrap, box, setFocus
    end

    local usernameWrap, usernameBox = makeInput("Enter username", false, 4)
    -- Spacer between inputs
    newFrame("Spacer2", form, {
        Size = UDim2.new(0, 0, 0, 12),
        BackgroundTransparency = 1,
        LayoutOrder = 5,
    })
    local passwordWrap, passwordBox = makeInput("Enter password", true, 6)

    -- Password masking: replace visible text with bullets, keep real value
    local realPassword = ""
    passwordBox:GetPropertyChangedSignal("Text"):Connect(function()
        local current = passwordBox.Text
        if #current < #realPassword then
            -- backspace
            realPassword = realPassword:sub(1, #current)
        elseif #current > #realPassword then
            -- new characters typed (could be paste — append all new chars)
            local newChars = current:sub(#realPassword + 1)
            realPassword = realPassword .. newChars
        end
        -- Render bullets, keep cursor position implied by end-of-string
        passwordBox.Text = string.rep("•", #realPassword)
        -- Move cursor to end
        -- (Roblox TextBox auto-places cursor at end when Text is set programmatically during input)
    end)

    -- Spacer
    newFrame("Spacer3", form, {
        Size = UDim2.new(0, 0, 0, 18),
        BackgroundTransparency = 1,
        LayoutOrder = 7,
    })

    -- Continue button (primary CTA — illuminated gradient)
    local continueBtn = newButton("Continue", form, {
        Size = UDim2.fromOffset(DIM.InputWidth, DIM.InputHeight),
        BackgroundColor3 = THEME.PurpleTop,
        BackgroundTransparency = 0,
        Text = "Continue",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = THEME.ButtonText,
        AutoButtonColor = false,
        LayoutOrder = 8,
    })
    newCorner(DIM.ButtonRadius, continueBtn)
    newGradient(ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.PurpleTop),
        ColorSequenceKeypoint.new(1, THEME.PurpleBottom),
    }), 90, continueBtn)
    local continueStroke = newStroke(Color3.fromRGB(160, 145, 255), 1, continueBtn, 0.6)
    local continueGlow = newImage("Glow", continueBtn, {
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://6014261993",
        ImageColor3 = THEME.PurpleTop,
        ImageTransparency = 0.8,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(32, 32, 32, 32),
        ZIndex = 0,
    })

    -- OR separator
    newFrame("Spacer4", form, {
        Size = UDim2.new(0, 0, 0, 18),
        BackgroundTransparency = 1,
        LayoutOrder = 9,
    })
    local orSep = newFrame("OrSeparator", form, {
        Size = UDim2.fromOffset(DIM.InputWidth, 14),
        BackgroundTransparency = 1,
        LayoutOrder = 10,
    })
    local orLine1 = newFrame("Line1", orSep, {
        Size = UDim2.new(0.5, -16, 0, 1),
        Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = THEME.Separator,
        BorderSizePixel = 0,
    })
    local orText = newLabel("Text", orSep, {
        Text = "OR",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = THEME.OrText,
        Size = UDim2.fromOffset(32, 14),
        Position = UDim2.fromScale(0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    local orLine2 = newFrame("Line2", orSep, {
        Size = UDim2.new(0.5, -16, 0, 1),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = THEME.Separator,
        BorderSizePixel = 0,
    })

    -- Spacer
    newFrame("Spacer5", form, {
        Size = UDim2.new(0, 0, 0, 14),
        BackgroundTransparency = 1,
        LayoutOrder = 11,
    })

    -- Subscription button (secondary, ghost style)
    local subBtn = newButton("Subscription", form, {
        Size = UDim2.fromOffset(DIM.InputWidth, 36),
        BackgroundTransparency = 1,
        Text = "Purchasing a subscription",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = THEME.SubscriptionText,
        AutoButtonColor = false,
        LayoutOrder = 12,
    })

    -- ============================================================
    -- Interaction wiring
    -- ============================================================
    local callbacks = {
        OnClose = nil,
        OnLogin = nil,
        OnPurchase = nil,
    }

    local isDestroyed = false
    local isOpen = false
    local inFlightTween = nil

    -- Close button hover
    closeBtn.MouseEnter:Connect(function()
        tween(closeIcon, MOTION.Hover, { ImageColor3 = THEME.CloseHover })
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeIcon, MOTION.Hover, { ImageColor3 = THEME.CloseIdle })
    end)
    closeBtn.MouseButton1Down:Connect(function()
        tween(closeIcon, MOTION.Press, { ImageTransparency = 0.3 })
    end)
    closeBtn.MouseButton1Up:Connect(function()
        tween(closeIcon, MOTION.Press, { ImageTransparency = 0 })
    end)
    closeBtn.Activated:Connect(function()
        if callbacks.OnClose then callbacks.OnClose() end
        window:Hide()
    end)

    -- Continue button hover/press
    continueBtn.MouseEnter:Connect(function()
        tween(continueBtn, MOTION.Hover, { Size = UDim2.fromOffset(DIM.InputWidth, DIM.InputHeight) })
        tween(continueGlow, MOTION.Hover, { ImageTransparency = 0.4 })
        tween(continueStroke, MOTION.Hover, { Transparency = 0 })
    end)
    continueBtn.MouseLeave:Connect(function()
        tween(continueBtn, MOTION.Hover, { Size = UDim2.fromOffset(DIM.InputWidth, DIM.InputHeight) })
        tween(continueGlow, MOTION.Hover, { ImageTransparency = 0.8 })
        tween(continueStroke, MOTION.Hover, { Transparency = 0.6 })
    end)
    continueBtn.MouseButton1Down:Connect(function()
        tween(continueBtn, MOTION.Press, { BackgroundTransparency = 0.1 })
    end)
    continueBtn.MouseButton1Up:Connect(function()
        tween(continueBtn, MOTION.Press, { BackgroundTransparency = 0 })
    end)
    continueBtn.Activated:Connect(function()
        local u = usernameBox.Text or ""
        local p = realPassword
        if callbacks.OnLogin then callbacks.OnLogin(u, p) end
    end)

    -- Subscription button hover
    subBtn.MouseEnter:Connect(function()
        tween(subBtn, MOTION.Hover, { TextColor3 = THEME.SubscriptionLink })
    end)
    subBtn.MouseLeave:Connect(function()
        tween(subBtn, MOTION.Hover, { TextColor3 = THEME.SubscriptionText })
    end)
    subBtn.Activated:Connect(function()
        if callbacks.OnPurchase then callbacks.OnPurchase() end
    end)

    -- Make the left panel and the top area of the right panel draggable
    local cancelDrag = makeDraggable(window, leftPanel)
    -- Also allow drag from the form's top area (above the title) — but only via a dedicated drag strip
    -- For simplicity, the left panel is the primary drag handle.

    -- Responsive scaling — re-evaluate on viewport resize
    local viewportConn
    viewportConn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        applyScale(uiScale)
    end)

    -- ============================================================
    -- Public API (window object)
    -- ============================================================
    local windowObj = {}

    function windowObj:SetSubtitle(text)
        subtitleLabel.Text = text or ""
    end

    function windowObj:SetLogo(assetId)
        logo.Image = assetId or "rbxassetid://0"
    end

    function windowObj:SetTitle(text)
        titleLabel.Text = text or "RETINA"
    end

    function windowObj:OnClose(fn)      callbacks.OnClose = fn end
    function windowObj:OnLogin(fn)      callbacks.OnLogin = fn end
    function windowObj:OnPurchase(fn)   callbacks.OnPurchase = fn end

    function windowObj:Show()
        if isOpen or isDestroyed then return end
        isOpen = true
        gui.Enabled = true

        -- Entrance choreography: fade + scale + slight spring (Back easing gives the spring feel)
        -- See motion_mastery/choreography_ownership.md — single owner for the entrance.
        if inFlightTween then inFlightTween:Cancel() end

        window.BackgroundTransparency = 1
        uiScale.Scale = 0.92
        shadow.ImageTransparency = 1

        if isReducedMotion() then
            window.BackgroundTransparency = 0
            uiScale.Scale = computeScale()
            shadow.ImageTransparency = 0.6
        else
            task.spawn(function()
                -- Phase 1: fade in window + shadow, scale 0.92 → 1.0 (with Back overshoot for spring)
                local t1 = tween(window, MOTION.WindowOpen, { BackgroundTransparency = 0 })
                local t2 = tween(uiScale, MOTION.WindowOpen, { Scale = computeScale() })
                tween(shadow, MOTION.WindowOpen, { ImageTransparency = 0.6 })
                inFlightTween = t2
            end)
        end
    end

    function windowObj:Hide()
        if not isOpen or isDestroyed then return end
        isOpen = false

        if inFlightTween then inFlightTween:Cancel() end

        if isReducedMotion() then
            self:Destroy()
            return
        end

        -- Exit choreography: fade out + slight scale down, then destroy
        task.spawn(function()
            local t1 = tween(window, MOTION.WindowClose, { BackgroundTransparency = 1 })
            local t2 = tween(uiScale, MOTION.WindowClose, { Scale = computeScale() * 0.92 })
            tween(shadow, MOTION.WindowClose, { ImageTransparency = 1 })
            inFlightTween = t1
            t1.Completed:Wait()
            self:Destroy()
        end)
    end

    function windowObj:Destroy()
        if isDestroyed then return end
        isDestroyed = true
        -- Teardown — see luau-max-quality-mode checklists/cleanup-gate.md
        cancelDrag()
        if viewportConn then viewportConn:Disconnect() end
        if inFlightTween then inFlightTween:Cancel() end
        gui:Destroy()
    end

    function windowObj:IsOpen() return isOpen end

    -- Expose raw elements for advanced consumers (rare; intentionally minimal)
    windowObj._gui = gui
    windowObj._window = window

    return windowObj
end

-- ============================================================
-- Module export
-- ============================================================
local UI = {}

function UI:CreateWindow(config)
    return buildWindow(config)
end

-- Optional helpers exposed for testing
UI._internal = {
    Theme = THEME,
    Dimensions = DIM,
    Motion = MOTION,
    Spring = Spring,
    ComputeScale = computeScale,
}

return UI
