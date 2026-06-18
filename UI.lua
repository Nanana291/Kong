--!strict
--[[
    UI.lua — RETINA Key System Login
    Premium single-file UI library for Roblox. Recreates the RETINA login
    surface with desktop-grade animations, drag (mouse + touch), and
    responsive scaling.

    Usage:
        local UI = loadfile("UI.lua")()
        local Window = UI:CreateWindow({ Title = "RETINA" })
        Window:SetSubtitle("Welcome again, please log in to continue.")
        Window:SetLogo("rbxassetid://LOGO")
        Window:OnClose(function() print("Closed") end)
        Window:OnLogin(function(username, password) print(username, password) end)
        Window:OnPurchase(function() print("Purchase") end)
        Window:Show()
]]

-- ═══════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
local gethuiSafe        = gethui or function() return CoreGui end

-- ═══════════════════════════════════════════════════════════
-- UTILITIES
-- ═══════════════════════════════════════════════════════════

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function tween(obj, props, duration, easingStyle, easingDir)
    local info = TweenInfo.new(
        duration or 0.18,
        easingStyle or Enum.EasingStyle.Quint,
        easingDir or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function lighten(color, amount)
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    return Color3.fromRGB(
        clamp(math.floor(r + (255 - r) * amount), 0, 255),
        clamp(math.floor(g + (255 - g) * amount), 0, 255),
        clamp(math.floor(b + (255 - b) * amount), 0, 255)
    )
end

local function darken(color, amount)
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    return Color3.fromRGB(
        clamp(math.floor(r * (1 - amount)), 0, 255),
        clamp(math.floor(g * (1 - amount)), 0, 255),
        clamp(math.floor(b * (1 - amount)), 0, 255)
    )
end

local function disconnectAll(list)
    for _, c in list do
        if c and c.Disconnect then pcall(function() c:Disconnect() end) end
    end
    table.clear(list)
end

-- ═══════════════════════════════════════════════════════════
-- DESIGN TOKENS
-- ═══════════════════════════════════════════════════════════

local TOKENS = {
    Color = {
        WindowBg         = Color3.fromRGB(13, 13, 17),
        LeftPanel        = Color3.fromRGB(155, 138, 255),
        InputBg          = Color3.fromRGB(20, 20, 26),
        InputBgFocus     = Color3.fromRGB(26, 26, 34),
        AccentGlow       = Color3.fromRGB(155, 138, 255),
        Button           = Color3.fromRGB(155, 138, 255),
        ButtonHover      = Color3.fromRGB(172, 156, 255),
        ButtonPress      = Color3.fromRGB(135, 118, 235),
        GhostBg          = Color3.fromRGB(20, 20, 28),
        GhostBgHover     = Color3.fromRGB(28, 28, 38),
        GhostBorder      = Color3.fromRGB(70, 70, 90),
        Text             = Color3.fromRGB(255, 255, 255),
        TextMuted        = Color3.fromRGB(150, 150, 165),
        TextSubtle       = Color3.fromRGB(110, 110, 130),
        White            = Color3.fromRGB(255, 255, 255),
    },
    Motion = {
        Fast   = 0.12,
        Normal = 0.20,
        Slow   = 0.30,
        Open   = 0.45,
        Close  = 0.25,
    },
    Radius = {
        Window = 18,
        Panel  = 14,
        Input  = 10,
        Button = 12,
    },
}

-- ═══════════════════════════════════════════════════════════
-- RESPONSIVE
-- ═══════════════════════════════════════════════════════════

local function applyResponsive(root, baseW, baseH)
    local scale = Instance.new("UIScale")
    scale.Name = "ResponsiveScale"
    scale.Parent = root

    local function update()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        -- Fit within viewport, never upscale, floor at 0.55 for very tiny screens
        local s = math.min(vp.X / baseW, vp.Y / baseH, 1)
        scale.Scale = math.max(s, 0.55)
    end
    update()
    cam:GetPropertyChangedSignal("ViewportSize"):Connect(update)
    return scale
end

-- ═══════════════════════════════════════════════════════════
-- DRAG CONTROLLER (mouse + touch, threshold, no jitter)
-- ═══════════════════════════════════════════════════════════

local DragController = {}
DragController.__index = DragController

function DragController.new(target, handle)
    local self = setmetatable({}, DragController)
    self._target  = target
    self._handle  = handle
    self._conns   = {}
    self._dragging = false
    self._threshold = 4
    self:_bind()
    return self
end

function DragController:_bind()
    local target = self._target
    local handle = self._handle
    local dragging = false
    local startInput, startTarget

    local function isDragInput(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
    end

    local function begin(input)
        if not isDragInput(input) then return end
        startInput  = Vector2.new(input.Position.X, input.Position.Y)
        startTarget = target.Position
        dragging    = true
    end

    local function update(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local dx = input.Position.X - startInput.X
        local dy = input.Position.Y - startInput.Y
        if not self._dragging and math.abs(dx) < self._threshold and math.abs(dy) < self._threshold then
            return
        end
        self._dragging = true
        target.Position = UDim2.new(
            startTarget.X.Scale, startTarget.X.Offset + dx,
            startTarget.Y.Scale, startTarget.Y.Offset + dy
        )
    end

    local function endDrag(input)
        if not isDragInput(input) then return end
        dragging = false
        self._dragging = false
    end

    table.insert(self._conns, handle.InputBegan:Connect(begin))
    table.insert(self._conns, UserInputService.InputChanged:Connect(update))
    table.insert(self._conns, UserInputService.InputEnded:Connect(endDrag))
end

function DragController:Destroy()
    disconnectAll(self._conns)
end

-- ═══════════════════════════════════════════════════════════
-- BUTTON COMPONENT
-- ═══════════════════════════════════════════════════════════

local Button = {}
Button.__index = Button

function Button.new(parent, props)
    local self = setmetatable({}, Button)
    self._conns = {}

    local bg        = props.BackgroundColor or TOKENS.Color.GhostBg
    local hover     = props.HoverColor     or lighten(bg, 0.06)
    local press     = props.PressColor     or darken(bg, 0.12)
    local size      = props.Size           or UDim2.new(1, 0, 0, 40)
    local radius    = props.CornerRadius   or TOKENS.Radius.Button
    local font      = props.Font           or Enum.Font.GothamMedium
    local textSize  = props.TextSize       or 14

    local button = Instance.new("TextButton")
    button.Name                 = props.Name or "Button"
    button.AutoButtonColor      = false
    button.Font                 = font
    button.TextSize             = textSize
    button.Text                 = props.Text or ""
    button.TextColor3           = props.TextColor or TOKENS.Color.Text
    button.Size                 = size
    button.BackgroundColor3     = bg
    button.BackgroundTransparency = props.BackgroundTransparency or 0
    button.BorderSizePixel      = 0
    button.Parent               = parent
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, radius)

    if props.Stroke then
        local s = Instance.new("UIStroke", button)
        s.Color   = props.Stroke
        s.Thickness = 1
        s.Transparency = 0.35
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        self._stroke = s
    end

    local pressedSize = UDim2.new(
        size.X.Scale, size.X.Offset - 2,
        size.Y.Scale, size.Y.Offset - 2
    )
    local baseTransparency = props.BackgroundTransparency or 0

    table.insert(self._conns, button.MouseEnter:Connect(function()
        tween(button, { BackgroundColor3 = hover, BackgroundTransparency = baseTransparency }, TOKENS.Motion.Fast)
    end))
    table.insert(self._conns, button.MouseLeave:Connect(function()
        tween(button, { BackgroundColor3 = bg, BackgroundTransparency = baseTransparency, Size = size }, TOKENS.Motion.Fast)
    end))
    table.insert(self._conns, button.MouseButton1Down:Connect(function()
        tween(button, { BackgroundColor3 = press, Size = pressedSize }, TOKENS.Motion.Fast)
    end))
    table.insert(self._conns, button.MouseButton1Up:Connect(function()
        tween(button, { BackgroundColor3 = hover, Size = size }, TOKENS.Motion.Fast)
    end))
    table.insert(self._conns, button.MouseButton1Click:Connect(function()
        if props.OnClick then props.OnClick() end
    end))

    self._instance = button
    return self
end

function Button:Destroy()
    disconnectAll(self._conns)
    if self._instance then self._instance:Destroy() end
end

-- ═══════════════════════════════════════════════════════════
-- INPUT COMPONENT
-- ═══════════════════════════════════════════════════════════

local Input = {}
Input.__index = Input

function Input.new(parent, props)
    local self = setmetatable({}, Input)
    self._conns = {}

    local size   = props.Size        or UDim2.new(1, 0, 0, 40)
    local radius = props.CornerRadius or TOKENS.Radius.Input
    local padding = 16

    local container = Instance.new("Frame")
    container.Name              = props.Name or "Input"
    container.Size              = size
    container.BackgroundColor3  = TOKENS.Color.InputBg
    container.BorderSizePixel   = 0
    container.ClipsDescendants  = true
    container.Parent            = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, radius)

    local stroke = Instance.new("UIStroke", container)
    stroke.Color   = TOKENS.Color.White
    stroke.Thickness = 1
    stroke.Transparency = 0.93
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    self._stroke = stroke

    -- Bottom glow line that lights up on focus
    local glow = Instance.new("Frame", container)
    glow.Name = "FocusGlow"
    glow.BackgroundColor3 = TOKENS.Color.AccentGlow
    glow.BackgroundTransparency = 1
    glow.BorderSizePixel = 0
    glow.Size = UDim2.new(0.5, 0, 0, 1)
    glow.Position = UDim2.new(0.25, 0, 1, -1)
    glow.AnchorPoint = Vector2.new(0, 0)
    Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 1)
    self._glow = glow

    local textBox = Instance.new("TextBox")
    textBox.Name                  = "TextBox"
    textBox.Size                  = UDim2.new(1, -padding * 2, 1, 0)
    textBox.Position              = UDim2.new(0, padding, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.Font                  = props.Font or Enum.Font.Gotham
    textBox.TextSize              = props.TextSize or 14
    textBox.TextColor3            = TOKENS.Color.Text
    textBox.PlaceholderText       = props.Placeholder or ""
    textBox.PlaceholderColor3     = TOKENS.Color.TextSubtle
    textBox.Text                  = props.Default or ""
    textBox.TextXAlignment        = Enum.TextXAlignment.Left
    textBox.TextYAlignment        = Enum.TextYAlignment.Center
    textBox.ClearTextOnFocus      = false
    textBox.TextTruncate          = Enum.TextTruncate.AtEnd
    textBox.Parent                = container

    self._textBox   = textBox
    self._container = container

    table.insert(self._conns, textBox.Focused:Connect(function()
        tween(container, { BackgroundColor3 = TOKENS.Color.InputBgFocus }, TOKENS.Motion.Fast)
        tween(stroke,    { Transparency = 0.55, Color = TOKENS.Color.AccentGlow }, TOKENS.Motion.Normal)
        tween(glow,      { BackgroundTransparency = 0.4 }, TOKENS.Motion.Normal)
    end))
    table.insert(self._conns, textBox.FocusLost:Connect(function(enterPressed)
        tween(container, { BackgroundColor3 = TOKENS.Color.InputBg }, TOKENS.Motion.Fast)
        tween(stroke,    { Transparency = 0.93, Color = TOKENS.Color.White }, TOKENS.Motion.Normal)
        tween(glow,      { BackgroundTransparency = 1 }, TOKENS.Motion.Normal)
        if props.OnSubmit then props.OnSubmit(textBox.Text, enterPressed) end
    end))

    return self
end

function Input:GetValue() return self._textBox.Text end
function Input:SetValue(v) self._textBox.Text = v end

function Input:Destroy()
    disconnectAll(self._conns)
    if self._container then self._container:Destroy() end
end

-- ═══════════════════════════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════════════════════════

local Window = {}
Window.__index = Window

function Window.new(props)
    local self = setmetatable({}, Window)
    self._props = props or {}
    self._conns = {}
    self._cleanedUp = false
    self:_build()
    return self
end

function Window:_build()
    local baseW, baseH = 720, 420
    self._baseW, self._baseH = baseW, baseH

    -- Screen gui
    local gui = Instance.new("ScreenGui")
    gui.Name              = "UI_Login"
    gui.ZIndexBehavior    = Enum.ZIndexBehavior.Global
    gui.ResetOnSpawn      = false
    gui.IgnoreGuiInset    = true
    gui.Parent            = gethuiSafe()
    self._gui = gui

    -- Outer container (positioned, scaled, fades the whole UI on open/close)
    local container = Instance.new("Frame")
    container.Name              = "Container"
    container.AnchorPoint       = Vector2.new(0.5, 0.5)
    container.Position          = UDim2.new(0.5, 0, 0.5, 0)
    container.Size              = UDim2.new(0, baseW, 0, baseH)
    container.BackgroundTransparency = 1
    container.Parent            = gui
    self._container = container

    -- Animation wrapper (scale anim for open/close)
    local wrapper = Instance.new("Frame")
    wrapper.Name              = "AnimWrapper"
    wrapper.AnchorPoint       = Vector2.new(0.5, 0.5)
    wrapper.Position          = UDim2.new(0.5, 0, 0.5, 0)
    wrapper.Size              = UDim2.new(0.94, 0, 0.94, 0) -- start small for open pop
    wrapper.BackgroundTransparency = 1
    wrapper.Parent            = container
    self._wrapper = wrapper

    -- Soft drop shadow behind window
    local shadow = Instance.new("ImageLabel")
    shadow.Name                  = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image                 = "rbxassetid://5554236805"
    shadow.ImageColor3           = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency     = 1 -- animated in on Show
    shadow.ScaleType             = Enum.ScaleType.Slice
    shadow.SliceCenter           = Rect.new(23, 23, 277, 277)
    shadow.SliceScale            = 0.7
    shadow.Size                  = UDim2.new(1, 48, 1, 48)
    shadow.Position              = UDim2.new(0.5, 0, 0.5, 8)
    shadow.AnchorPoint           = Vector2.new(0.5, 0.5)
    shadow.ZIndex                = -1
    shadow.Parent                = container
    self._shadow = shadow

    -- Main window frame
    local window = Instance.new("Frame")
    window.Name                  = "Window"
    window.Size                  = UDim2.new(1, 0, 1, 0)
    window.BackgroundColor3      = TOKENS.Color.WindowBg
    window.BorderSizePixel       = 0
    window.Active                = true
    window.Parent                = wrapper
    Instance.new("UICorner", window).CornerRadius = UDim.new(0, TOKENS.Radius.Window)

    local wStroke = Instance.new("UIStroke", window)
    wStroke.Color   = TOKENS.Color.White
    wStroke.Thickness = 1
    wStroke.Transparency = 0.92
    wStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- ── LEFT PANEL (lavender) ──
    local left = Instance.new("Frame")
    left.Name                  = "LeftPanel"
    left.Size                  = UDim2.new(0.485, 0, 1, -16)
    left.Position              = UDim2.new(0, 8, 0, 8)
    left.BackgroundColor3      = TOKENS.Color.LeftPanel
    left.BorderSizePixel       = 0
    left.ClipsDescendants      = true
    left.Parent                = window
    Instance.new("UICorner", left).CornerRadius = UDim.new(0, TOKENS.Radius.Panel)

    -- subtle top-bright / bottom-deeper gradient for material depth
    local lGrad = Instance.new("UIGradient", left)
    lGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 0, 0)),
    })
    lGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.86),
        NumberSequenceKeypoint.new(0.5, 0.96),
        NumberSequenceKeypoint.new(1,   0.82),
    })
    lGrad.Rotation = 90
    self._leftPanel = left

    -- Default geometric logo
    local logo = self:_buildDefaultLogo()
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position    = UDim2.new(0.5, 0, 0.5, -8)
    logo.Size        = UDim2.new(0, 140, 0, 140)
    logo.Parent      = left
    self._logo = logo

    -- @PestOwl brand text
    local brand = Instance.new("TextLabel", left)
    brand.Name              = "Brand"
    brand.Size              = UDim2.new(0, 200, 0, 18)
    brand.Position          = UDim2.new(0, 22, 1, -30)
    brand.BackgroundTransparency = 1
    brand.Font              = Enum.Font.Gotham
    brand.TextSize          = 12
    brand.TextColor3        = TOKENS.Color.White
    brand.TextTransparency  = 0.25
    brand.TextXAlignment    = Enum.TextXAlignment.Left
    brand.Text              = "@PestOwl"

    -- ── RIGHT PANEL (dark, transparent BG, content only) ──
    local right = Instance.new("Frame")
    right.Name              = "RightPanel"
    right.Size              = UDim2.new(0.515, -16, 1, -16)
    right.Position          = UDim2.new(0.485, 8, 0, 8)
    right.BackgroundTransparency = 1
    right.Parent            = window
    self._rightPanel = right

    local padding = 40

    -- Title (RETINA)
    local title = Instance.new("TextLabel", right)
    title.Name              = "Title"
    title.Size              = UDim2.new(1, -padding * 2, 0, 36)
    title.Position          = UDim2.new(0, padding, 0, 64)
    title.BackgroundTransparency = 1
    title.Font              = Enum.Font.GothamBold
    title.TextSize          = 28
    title.TextColor3        = TOKENS.Color.Text
    title.TextXAlignment    = Enum.TextXAlignment.Left
    title.Text              = (self._props.Title) or "RETINA"
    self._title = title

    -- Subtitle
    local subtitle = Instance.new("TextLabel", right)
    subtitle.Name              = "Subtitle"
    subtitle.Size              = UDim2.new(1, -padding * 2, 0, 20)
    subtitle.Position          = UDim2.new(0, padding, 0, 100)
    subtitle.BackgroundTransparency = 1
    subtitle.Font              = Enum.Font.Gotham
    subtitle.TextSize          = 13
    subtitle.TextColor3        = TOKENS.Color.TextMuted
    subtitle.TextXAlignment    = Enum.TextXAlignment.Left
    subtitle.Text              = "Welcome again, please log in to continue."
    self._subtitle = subtitle

    -- ── FORM (username + password + continue) ──
    local form = Instance.new("Frame", right)
    form.Name              = "Form"
    form.Size              = UDim2.new(1, -padding * 2, 0, 140)
    form.Position          = UDim2.new(0, padding, 0, 150)
    form.BackgroundTransparency = 1

    local listLayout = Instance.new("UIListLayout", form)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding   = UDim.new(0, 10)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Username row
    local usernameRow = Instance.new("Frame", form)
    usernameRow.Name              = "UsernameRow"
    usernameRow.LayoutOrder       = 1
    usernameRow.Size              = UDim2.new(1, 0, 0, 40)
    usernameRow.BackgroundTransparency = 1
    self._username = Input.new(usernameRow, {
        Name       = "Username",
        Placeholder = "Enter username",
        Size       = UDim2.new(1, 0, 1, 0),
    })

    -- Password row
    local passwordRow = Instance.new("Frame", form)
    passwordRow.Name              = "PasswordRow"
    passwordRow.LayoutOrder       = 2
    passwordRow.Size              = UDim2.new(1, 0, 0, 40)
    passwordRow.BackgroundTransparency = 1
    self._password = Input.new(passwordRow, {
        Name       = "Password",
        Placeholder = "Enter password",
        Secure     = true,
        Size       = UDim2.new(1, 0, 1, 0),
    })

    -- Continue button
    local continueRow = Instance.new("Frame", form)
    continueRow.Name              = "ContinueRow"
    continueRow.LayoutOrder       = 3
    continueRow.Size              = UDim2.new(1, 0, 0, 40)
    continueRow.BackgroundTransparency = 1
    self._continue = Button.new(continueRow, {
        Name        = "Continue",
        Text        = "Continue",
        TextColor   = TOKENS.Color.White,
        BackgroundColor = TOKENS.Color.Button,
        HoverColor  = TOKENS.Color.ButtonHover,
        PressColor  = TOKENS.Color.ButtonPress,
        Size        = UDim2.new(1, 0, 1, 0),
        CornerRadius = 12,
        Font        = Enum.Font.GothamMedium,
        TextSize    = 14,
        OnClick = function()
            if self._onLogin then
                self._onLogin(self._username:GetValue(), self._password:GetValue())
            end
        end,
    })

    -- OR separator
    local orFrame = Instance.new("Frame", right)
    orFrame.Name              = "ORSep"
    orFrame.Size              = UDim2.new(1, -padding * 2, 0, 16)
    orFrame.Position          = UDim2.new(0, padding, 0, 315)
    orFrame.BackgroundTransparency = 1
    local orText = Instance.new("TextLabel", orFrame)
    orText.Name              = "OR"
    orText.Size              = UDim2.new(1, 0, 1, 0)
    orText.BackgroundTransparency = 1
    orText.Font              = Enum.Font.Gotham
    orText.TextSize          = 11
    orText.TextColor3        = TOKENS.Color.TextMuted
    orText.Text              = "OR"

    -- Purchase button
    local purchaseRow = Instance.new("Frame", right)
    purchaseRow.Name              = "PurchaseRow"
    purchaseRow.Size              = UDim2.new(1, -padding * 2, 0, 40)
    purchaseRow.Position          = UDim2.new(0, padding, 0, 345)
    purchaseRow.BackgroundTransparency = 1
    self._purchase = Button.new(purchaseRow, {
        Name        = "Purchase",
        Text        = "Purchasing a subscription",
        TextColor   = TOKENS.Color.White,
        BackgroundColor = TOKENS.Color.GhostBg,
        HoverColor  = TOKENS.Color.GhostBgHover,
        PressColor  = TOKENS.Color.InputBg,
        Size        = UDim2.new(1, 0, 1, 0),
        CornerRadius = 12,
        Font        = Enum.Font.GothamMedium,
        TextSize    = 13,
        Stroke      = TOKENS.Color.GhostBorder,
        OnClick = function()
            if self._onPurchase then self._onPurchase() end
        end,
    })

    -- ── CLOSE BUTTON ──
    local closeBtn = Instance.new("TextButton", window)
    closeBtn.Name              = "Close"
    closeBtn.Size              = UDim2.new(0, 28, 0, 28)
    closeBtn.Position          = UDim2.new(1, -14, 0, 14)
    closeBtn.AnchorPoint       = Vector2.new(1, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.BorderSizePixel   = 0
    closeBtn.Text              = "×"
    closeBtn.TextColor3        = TOKENS.Color.White
    closeBtn.TextTransparency  = 0.35
    closeBtn.Font              = Enum.Font.GothamBold
    closeBtn.TextSize          = 16
    closeBtn.AutoButtonColor   = false
    self._closeBtn = closeBtn

    table.insert(self._conns, closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, { TextTransparency = 0 }, TOKENS.Motion.Fast)
    end))
    table.insert(self._conns, closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, { TextTransparency = 0.35 }, TOKENS.Motion.Fast)
    end))
    table.insert(self._conns, closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end))

    -- Drag (window Frame is the handle; inputs/buttons capture their own clicks first)
    self._drag = DragController.new(container, window)

    -- Responsive scale on the container
    applyResponsive(container, baseW, baseH)

    -- Initial state for Show animation
    self._container.GroupTransparency = 1
end

function Window:_buildDefaultLogo()
    local frame = Instance.new("Frame")
    frame.Name = "LogoDefault"
    frame.BackgroundTransparency = 1

    -- Two rotated white rectangles forming a stylized K-like mark.
    -- Approximates the geometric logo shown in the reference.
    local piece1 = Instance.new("Frame", frame)
    piece1.Name              = "Piece1"
    piece1.Size              = UDim2.new(0, 28, 0, 110)
    piece1.BackgroundColor3  = TOKENS.Color.White
    piece1.BorderSizePixel   = 0
    piece1.Rotation          = 18
    piece1.AnchorPoint       = Vector2.new(0.5, 0.5)
    piece1.Position          = UDim2.new(0.5, -20, 0.5, 0)
    Instance.new("UICorner", piece1).CornerRadius = UDim.new(0, 4)

    local piece2 = Instance.new("Frame", frame)
    piece2.Name              = "Piece2"
    piece2.Size              = UDim2.new(0, 28, 0, 90)
    piece2.BackgroundColor3  = TOKENS.Color.White
    piece2.BorderSizePixel   = 0
    piece2.Rotation          = -18
    piece2.AnchorPoint       = Vector2.new(0.5, 0.5)
    piece2.Position          = UDim2.new(0.5, 20, 0.5, 0)
    Instance.new("UICorner", piece2).CornerRadius = UDim.new(0, 4)

    return frame
end

-- ── Public API ──

function Window:SetSubtitle(text)
    if self._subtitle then self._subtitle.Text = text end
end

function Window:SetTitle(text)
    if self._title then self._title.Text = text end
end

function Window:SetLogo(assetId)
    if not self._leftPanel then return end
    if self._logo then self._logo:Destroy() end
    local img = Instance.new("ImageLabel")
    img.Name              = "Logo"
    img.AnchorPoint       = Vector2.new(0.5, 0.5)
    img.Position          = UDim2.new(0.5, 0, 0.5, -8)
    img.Size              = UDim2.new(0, 140, 0, 140)
    img.BackgroundTransparency = 1
    img.Image             = assetId
    img.Parent            = self._leftPanel
    self._logo = img
end

function Window:OnClose(fn)    self._onClose    = fn end
function Window:OnLogin(fn)    self._onLogin    = fn end
function Window:OnPurchase(fn) self._onPurchase = fn end

function Window:Show()
    if self._shown then return end
    self._shown = true

    local wrapper = self._wrapper

    -- Size: 0.94 → 1.0 with spring (Back.Out)
    tween(wrapper, { Size = UDim2.new(1, 0, 1, 0) }, TOKENS.Motion.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    -- Fade: GroupTransparency 1 → 0
    tween(self._container, { GroupTransparency = 0 }, TOKENS.Motion.Open, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    -- Shadow: ImageTransparency 1 → 0.55
    tween(self._shadow, { ImageTransparency = 0.55 }, TOKENS.Motion.Open, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

function Window:Close()
    if self._cleanedUp then return end
    self._cleanedUp = true

    local wrapper = self._wrapper
    tween(wrapper, { Size = UDim2.new(0.94, 0, 0.94, 0) }, TOKENS.Motion.Close, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    tween(self._container, { GroupTransparency = 1 }, TOKENS.Motion.Close, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    tween(self._shadow, { ImageTransparency = 1 }, TOKENS.Motion.Close, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

    task.delay(TOKENS.Motion.Close, function()
        if self._onClose then pcall(self._onClose) end
        self:Destroy()
    end)
end

function Window:Destroy()
    disconnectAll(self._conns)
    if self._drag then self._drag:Destroy() end
    if self._username then self._username:Destroy() end
    if self._password then self._password:Destroy() end
    if self._continue then self._continue:Destroy() end
    if self._purchase then self._purchase:Destroy() end
    if self._gui then self._gui:Destroy() end
end

-- ═══════════════════════════════════════════════════════════
-- UI MODULE
-- ═══════════════════════════════════════════════════════════

local UI = {}
UI.__index = UI

function UI:CreateWindow(props)
    return Window.new(props)
end

return UI
