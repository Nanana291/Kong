--[[
    TestingUI.lua
    Reusable Roblox Luau UI library for premium desktop-style script hub interfaces.
    Content agnostic: scripts create windows, tabs, subtabs, sections, controls, color pickers, and notifications dynamically.
]]

local Library = {}
Library.Version = "1.0.0"
Library.Options = {}
Library.Windows = {}
Library.Connections = {}
Library.Notifications = {}
Library.Flags = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Theme = {
    Background = Color3.fromRGB(10, 10, 14),
    BackgroundSoft = Color3.fromRGB(14, 14, 20),
    Surface = Color3.fromRGB(18, 18, 25),
    Surface2 = Color3.fromRGB(24, 24, 33),
    Surface3 = Color3.fromRGB(31, 31, 42),
    SurfaceHover = Color3.fromRGB(38, 38, 51),
    Stroke = Color3.fromRGB(50, 50, 65),
    StrokeSoft = Color3.fromRGB(42, 42, 55),
    Text = Color3.fromRGB(245, 246, 252),
    SubText = Color3.fromRGB(156, 158, 174),
    Muted = Color3.fromRGB(92, 94, 110),
    Disabled = Color3.fromRGB(58, 59, 72),
    Accent = Color3.fromRGB(255, 87, 90),
    AccentDark = Color3.fromRGB(156, 42, 50),
    AccentSoft = Color3.fromRGB(255, 120, 122),
    White = Color3.fromRGB(255, 255, 255),
    Success = Color3.fromRGB(85, 230, 160),
    Warning = Color3.fromRGB(255, 190, 90),
    Error = Color3.fromRGB(255, 87, 90),
}

local Icons = {
    Target = "◎",
    Combat = "◎",
    Trigger = "◌",
    Eye = "◉",
    Visuals = "◉",
    Settings = "⚙",
    Search = "⌕",
    User = "◍",
    Home = "⌂",
    Folder = "▱",
    Misc = "✦",
    Shield = "◆",
    Color = "◐",
    Bell = "◒",
    Code = "<>",
    Gear = "⚙",
    Star = "✦",
    NoRecoil = "◈",
    Default = "•",
}

local function resolveParent()
    local ok, result = pcall(function()
        if gethui then
            return gethui()
        end
        if get_hidden_ui then
            return get_hidden_ui()
        end
    end)
    if ok and result then
        return result
    end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    return playerGui or CoreGui
end

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return true
    end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(function()
            callback(table.unpack(args, 1, args.n))
        end)
        if not ok then
            warn("[TestingUI] Callback error:", err)
            if Library.Notify then
                Library:Notify({
                    Title = "Callback Error",
                    Content = tostring(err),
                    Duration = 5,
                    Type = "error",
                })
            end
        end
    end)
    return true
end

local function addConnection(owner, connection)
    if not connection then
        return connection
    end
    owner.Connections = owner.Connections or {}
    table.insert(owner.Connections, connection)
    return connection
end

local function disconnectAll(owner)
    if not owner or not owner.Connections then
        return
    end
    for _, connection in ipairs(owner.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    owner.Connections = {}
end

local function create(className, props, children)
    local instance = Instance.new(className)
    props = props or {}
    for key, value in pairs(props) do
        instance[key] = value
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    return instance
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = parent })
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or Theme.Stroke,
        Transparency = transparency or 0.55,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function gradient(parent, colorA, colorB, rotation, transparency)
    local grad = create("UIGradient", {
        Color = ColorSequence.new(colorA, colorB),
        Rotation = rotation or 90,
        Parent = parent,
    })
    if transparency then
        grad.Transparency = transparency
    end
    return grad
end

local function padding(parent, left, top, right, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or left or 0),
        Parent = parent,
    })
end

local function list(parent, fillDirection, paddingSize, horizontalAlignment, verticalAlignment)
    return create("UIListLayout", {
        FillDirection = fillDirection or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, paddingSize or 8),
        HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Left,
        VerticalAlignment = verticalAlignment or Enum.VerticalAlignment.Top,
        Parent = parent,
    })
end

local function tween(instance, properties, duration, style, direction)
    if not instance or not instance.Parent then
        return nil
    end
    local info = TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
    local tw = TweenService:Create(instance, info, properties)
    tw:Play()
    return tw
end

local function clamp(value, min, max)
    if value < min then
        return min
    end
    if value > max then
        return max
    end
    return value
end

local function roundTo(value, increment)
    increment = increment or 1
    return math.floor((value / increment) + 0.5) * increment
end

local function formatNumber(value, precision)
    precision = precision or 0
    if precision <= 0 then
        return tostring(math.floor(value + 0.5))
    end
    local mult = 10 ^ precision
    local rounded = math.floor(value * mult + 0.5) / mult
    return string.format("%." .. tostring(precision) .. "f", rounded)
end

local function getIcon(name)
    if type(name) == "string" then
        return Icons[name] or name
    end
    return Icons.Default
end

local function setTableClear(tbl)
    if table.clear then
        table.clear(tbl)
    else
        for key in pairs(tbl) do
            tbl[key] = nil
        end
    end
end

local function makeText(parent, text, size, color, weight)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        Font = weight == "bold" and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        TextSize = size or 13,
        TextColor3 = color or Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = parent,
    })
end

local function makeGlass(parent, radius, baseColor, strokeTransparency)
    local frame = create("Frame", {
        BackgroundColor3 = baseColor or Theme.Surface,
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent,
    })
    corner(frame, radius or 16)
    stroke(frame, Theme.StrokeSoft, strokeTransparency or 0.58, 1)
    gradient(
        frame,
        Theme.Surface2,
        Theme.BackgroundSoft,
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.52, 0.12),
            NumberSequenceKeypoint.new(1, 0.22),
        })
    )
    local reflection = create("Frame", {
        BackgroundColor3 = Theme.White,
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.fromOffset(0, 0),
        Parent = frame,
    })
    return frame, reflection
end

local function makeShadow(parent, radius, transparency)
    local shadow = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = transparency or 0.62,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 10),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = (parent.ZIndex or 1) - 1,
        Parent = parent.Parent,
    })
    corner(shadow, radius or 22)
    return shadow
end

local function viewportSize()
    local cam = workspace.CurrentCamera
    if cam then
        return cam.ViewportSize
    end
    return Vector2.new(1920, 1080)
end

local function applyResponsiveScale(scaleObject, baseW, baseH)
    local size = viewportSize()
    local x = size.X / (baseW or 900)
    local y = size.Y / (baseH or 620)
    scaleObject.Scale = clamp(math.min(x, y, 1), 0.62, 1)
end

local function connectLayoutCanvas(scroller, layout, extra)
    local function update()
        task.defer(function()
            if scroller and scroller.Parent and layout and layout.Parent then
                scroller.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + (extra or 26))
            end
        end)
    end
    update()
    return layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
end

local function rgbToHex(color)
    return string.format(
        "#%02X%02X%02X",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
    )
end

local function hexToColor(hex)
    if type(hex) ~= "string" then
        return nil
    end
    local clean = hex:gsub("#", "")
    if #clean ~= 6 then
        return nil
    end
    local r = tonumber(clean:sub(1, 2), 16)
    local g = tonumber(clean:sub(3, 4), 16)
    local b = tonumber(clean:sub(5, 6), 16)
    if not r or not g or not b then
        return nil
    end
    return Color3.fromRGB(r, g, b)
end

local function makeHitbox(parent)
    return create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        Parent = parent,
    })
end

local function pointInside(guiObject, position)
    if not guiObject or not guiObject.Parent then
        return false
    end
    local abs = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    return position.X >= abs.X and position.X <= abs.X + size.X and position.Y >= abs.Y and position.Y <= abs.Y + size.Y
end

local function createRootGui()
    local gui = create("ScreenGui", {
        Name = "TestingUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999,
    })
    gui.Parent = resolveParent()
    return gui
end

local function makeToastHolder(gui)
    local holder = create("Frame", {
        Name = "ToastHolder",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -24, 0, 24),
        Size = UDim2.fromOffset(340, 600),
        Parent = gui,
        ZIndex = 1000,
    })
    local layout = list(holder, Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Right)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    return holder
end

Library.GUI = nil
Library.ToastHolder = nil

function Library:_ensureGui()
    if self.GUI and self.GUI.Parent then
        return self.GUI
    end
    self.GUI = createRootGui()
    self.ToastHolder = makeToastHolder(self.GUI)
    return self.GUI
end

function Library:_registerOption(id, option)
    if id then
        self.Options[id] = option
        self.Flags[id] = option.Value
    end
end

function Library:SafeCallback(callback, ...)
    return safeCall(callback, ...)
end

function Library:Notify(config)
    config = config or {}
    local gui = self:_ensureGui()
    if not self.ToastHolder or not self.ToastHolder.Parent then
        self.ToastHolder = makeToastHolder(gui)
    end

    local duration = config.Duration or 4
    local toast = create("Frame", {
        Name = "Notification",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(330, config.Content and 88 or 70),
        Parent = self.ToastHolder,
        ZIndex = 1001,
    })
    toast.LayoutOrder = -math.floor(os.clock() * 1000)

    local body = makeGlass(toast, 18, Theme.Surface, 0.44)
    body.Size = UDim2.fromScale(1, 1)
    body.ZIndex = 1002
    padding(body, 16, 13, 16, 13)

    local accent = Theme.Accent
    if config.Type == "success" then
        accent = Theme.Success
    end
    if config.Type == "warning" then
        accent = Theme.Warning
    end
    if config.Type == "error" then
        accent = Theme.Error
    end

    local icon = create("TextLabel", {
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.88,
        Text = getIcon(config.Icon or (config.Type == "success" and "Shield" or "Bell")),
        TextColor3 = accent,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.fromOffset(0, 2),
        ZIndex = 1003,
        Parent = body,
    })
    corner(icon, 13)
    stroke(icon, accent, 0.55, 1)

    local title = makeText(body, config.Title or "Notification", 14, Theme.Text, "bold")
    title.Position = UDim2.fromOffset(50, 0)
    title.Size = UDim2.new(1, -56, 0, 22)
    title.ZIndex = 1003

    local content = makeText(body, config.Content or config.Subtitle or "", 12, Theme.SubText)
    content.Position = UDim2.fromOffset(50, 24)
    content.Size = UDim2.new(1, -56, 0, 34)
    content.TextWrapped = true
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.ZIndex = 1003

    local progressBack = create("Frame", {
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 16, 1, -8),
        Size = UDim2.new(1, -32, 0, 2),
        ZIndex = 1003,
        Parent = body,
    })
    corner(progressBack, 2)
    local progress = create("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 1004,
        Parent = progressBack,
    })
    corner(progress, 2)

    body.Position = UDim2.fromOffset(24, 0)
    toast.Size = UDim2.fromOffset(0, config.Content and 88 or 70)
    tween(toast, { Size = UDim2.fromOffset(330, config.Content and 88 or 70) }, 0.34, Enum.EasingStyle.Quint)
    tween(body, { Position = UDim2.fromOffset(0, 0) }, 0.34, Enum.EasingStyle.Quint)
    for _, desc in ipairs(body:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local original = desc.TextTransparency
            desc.TextTransparency = 1
            tween(desc, { TextTransparency = original }, 0.28)
        elseif desc:IsA("Frame") then
            local original = desc.BackgroundTransparency
            desc.BackgroundTransparency = 1
            tween(desc, { BackgroundTransparency = original }, 0.28)
        elseif desc:IsA("UIStroke") then
            local original = desc.Transparency
            desc.Transparency = 1
            tween(desc, { Transparency = original }, 0.28)
        end
    end
    tween(progress, { Size = UDim2.fromScale(0, 1) }, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        if not toast or not toast.Parent then
            return
        end
        tween(body, { Position = UDim2.fromOffset(18, 0) }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        for _, desc in ipairs(body:GetDescendants()) do
            if desc:IsA("TextLabel") then
                tween(desc, { TextTransparency = 1 }, 0.18)
            elseif desc:IsA("Frame") then
                tween(desc, { BackgroundTransparency = 1 }, 0.18)
            elseif desc:IsA("UIStroke") then
                tween(desc, { Transparency = 1 }, 0.18)
            end
        end
        task.delay(0.22, function()
            if toast then
                toast:Destroy()
            end
        end)
    end)

    return toast
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local SubTab = {}
SubTab.__index = SubTab

local Section = {}
Section.__index = Section

local BaseControl = {}
BaseControl.__index = BaseControl

function BaseControl:Destroy()
    disconnectAll(self)
    if self.Instance then
        self.Instance:Destroy()
    end
    if self.Id and Library.Options[self.Id] == self then
        Library.Options[self.Id] = nil
        Library.Flags[self.Id] = nil
    end
end

function BaseControl:OnChanged(callback)
    self.ChangedCallbacks = self.ChangedCallbacks or {}
    table.insert(self.ChangedCallbacks, callback)
    return self
end

function BaseControl:_fire(value)
    self.Value = value
    if self.Id then
        Library.Flags[self.Id] = value
    end
    if self.Callback then
        safeCall(self.Callback, value)
    end
    if self.ChangedCallbacks then
        for _, callback in ipairs(self.ChangedCallbacks) do
            safeCall(callback, value)
        end
    end
end

local function makeControlRow(section, titleText, description, height)
    local row = create("Frame", {
        Name = "ControlRow",
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.42,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 58),
        ClipsDescendants = true,
        Parent = section.Content,
    })
    corner(row, 14)
    stroke(row, Theme.StrokeSoft, 0.76, 1)
    gradient(
        row,
        Theme.Surface2,
        Theme.BackgroundSoft,
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 0.28),
        })
    )

    local title = makeText(row, titleText or "Control", 13, Theme.Text, "bold")
    title.Position = UDim2.fromOffset(16, description and 9 or 0)
    title.Size = UDim2.new(0.58, -20, 0, 22)
    if not description then
        title.AnchorPoint = Vector2.new(0, 0.5)
        title.Position = UDim2.new(0, 16, 0.5, 0)
        title.Size = UDim2.new(0.58, -20, 0, 22)
    end

    local descLabel
    if description then
        descLabel = makeText(row, description, 11, Theme.Muted)
        descLabel.Position = UDim2.fromOffset(16, 31)
        descLabel.Size = UDim2.new(0.62, -24, 0, 18)
    end

    local holder = create("Frame", {
        Name = "ControlHolder",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0.38, -8, 1, -12),
        Parent = row,
    })

    local hover = makeHitbox(row)
    hover.ZIndex = 0
    addConnection(
        section.Window,
        hover.MouseEnter:Connect(function()
            tween(row, { BackgroundTransparency = 0.30 }, 0.16)
        end)
    )
    addConnection(
        section.Window,
        hover.MouseLeave:Connect(function()
            tween(row, { BackgroundTransparency = 0.42 }, 0.16)
        end)
    )

    return row, holder, title, descLabel, hover
end

function Section:_control(id, object)
    object.Id = id
    object.Section = self
    object.Window = self.Window
    if id then
        Library:_registerOption(id, object)
    end
    return object
end

function Section:CreateToggle(id, config)
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local row, holder, _, _, hitbox = makeControlRow(self, config.Title or id or "Toggle", config.Description, 58)
    local toggle = setmetatable(
        { Value = not not config.Default, Callback = config.Callback, ChangedCallbacks = {}, Instance = row },
        BaseControl
    )

    local shell = create("Frame", {
        BackgroundColor3 = toggle.Value and Theme.Accent or Theme.Surface3,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(46, 26),
        Parent = holder,
    })
    corner(shell, 18)
    local shellStroke =
        stroke(shell, toggle.Value and Theme.AccentSoft or Theme.Stroke, toggle.Value and 0.35 or 0.7, 1)
    local thumb = create("Frame", {
        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(18, 18),
        Position = toggle.Value and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 4, 0.5, -9),
        Parent = shell,
    })
    corner(thumb, 18)

    function toggle:SetValue(value)
        value = not not value
        self.Value = value
        tween(shell, { BackgroundColor3 = value and Theme.Accent or Theme.Surface3 }, 0.22)
        tween(
            shellStroke,
            { Color = value and Theme.AccentSoft or Theme.Stroke, Transparency = value and 0.35 or 0.7 },
            0.22
        )
        tween(
            thumb,
            { Position = value and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 4, 0.5, -9) },
            0.22,
            Enum.EasingStyle.Back
        )
        self:_fire(value)
    end

    local function clicked()
        toggle:SetValue(not toggle.Value)
    end
    hitbox.ZIndex = 5
    addConnection(self.Window, hitbox.MouseButton1Click:Connect(clicked))
    addConnection(
        self.Window,
        shell.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                clicked()
            end
        end)
    )

    return self:_control(id, toggle)
end

function Section:CreateSlider(id, config)
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local min = tonumber(config.Min) or 0
    local max = tonumber(config.Max) or 100
    local default = clamp(tonumber(config.Default) or min, min, max)
    local precision = tonumber(config.Precision) or tonumber(config.Rounding) or 0
    local row, holder = makeControlRow(self, config.Title or id or "Slider", config.Description, 76)
    holder.Size = UDim2.new(0.46, -8, 1, -12)

    local slider = setmetatable(
        { Value = default, Callback = config.Callback, ChangedCallbacks = {}, Instance = row },
        BaseControl
    )
    local valueLabel =
        makeText(row, formatNumber(default, precision) .. (config.Suffix or ""), 12, Theme.SubText, "bold")
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, -18, 0, 12)
    valueLabel.Size = UDim2.fromOffset(90, 18)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local track = create("Frame", {
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.62, 0),
        Size = UDim2.new(1, 0, 0, 8),
        Parent = holder,
    })
    corner(track, 8)
    local fill = create(
        "Frame",
        { BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), Parent = track }
    )
    corner(fill, 8)
    gradient(fill, Theme.AccentSoft, Theme.Accent, 0)
    local knob = create("Frame", {
        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(14, 18),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Parent = track,
    })
    corner(knob, 8)
    stroke(knob, Theme.White, 0.55, 1)

    local dragging = false
    local function setFromRatio(ratio, fire)
        ratio = clamp(ratio, 0, 1)
        local value = roundTo(min + (max - min) * ratio, 10 ^ -precision)
        value = clamp(value, min, max)
        slider.Value = value
        local finalRatio = (value - min) / (max - min)
        tween(fill, { Size = UDim2.fromScale(finalRatio, 1) }, fire == false and 0 or 0.08)
        tween(knob, { Position = UDim2.fromScale(finalRatio, 0.5) }, fire == false and 0 or 0.08)
        valueLabel.Text = formatNumber(value, precision) .. (config.Suffix or "")
        if fire ~= false then
            slider:_fire(value)
        end
    end
    function slider:SetValue(value)
        value = clamp(tonumber(value) or min, min, max)
        setFromRatio((value - min) / (max - min), true)
    end

    setFromRatio((default - min) / (max - min), false)

    local hit = makeHitbox(holder)
    local function update(input)
        local ratio = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
        setFromRatio(ratio, true)
    end
    addConnection(
        self.Window,
        hit.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                dragging = true
                update(input)
                tween(knob, { Size = UDim2.fromOffset(16, 20) }, 0.12)
            end
        end)
    )
    addConnection(
        self.Window,
        UserInputService.InputChanged:Connect(function(input)
            if
                dragging
                and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                )
            then
                update(input)
            end
        end)
    )
    addConnection(
        self.Window,
        UserInputService.InputEnded:Connect(function(input)
            if
                dragging
                and (
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                )
            then
                dragging = false
                tween(knob, { Size = UDim2.fromOffset(14, 18) }, 0.12)
            end
        end)
    )

    return self:_control(id, slider)
end

function Section:CreateInput(id, config)
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local row, holder = makeControlRow(self, config.Title or id or "Input", config.Description, 58)
    local input = setmetatable(
        { Value = config.Default or "", Callback = config.Callback, ChangedCallbacks = {}, Instance = row },
        BaseControl
    )
    local box = create("TextBox", {
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Theme.Text,
        PlaceholderText = config.Placeholder or "Type...",
        PlaceholderColor3 = Theme.Muted,
        Text = tostring(config.Default or ""),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClipsDescendants = true,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 34),
        Parent = holder,
    })
    corner(box, 11)
    local boxStroke = stroke(box, Theme.Stroke, 0.7, 1)
    padding(box, 12, 0, 12, 0)

    function input:SetValue(value)
        value = tostring(value or "")
        self.Value = value
        box.Text = value
        self:_fire(value)
    end
    addConnection(
        self.Window,
        box.Focused:Connect(function()
            tween(boxStroke, { Color = Theme.Accent, Transparency = 0.35 }, 0.16)
            tween(box, { BackgroundTransparency = 0.16 }, 0.16)
        end)
    )
    addConnection(
        self.Window,
        box.FocusLost:Connect(function(enterPressed)
            tween(boxStroke, { Color = Theme.Stroke, Transparency = 0.7 }, 0.16)
            tween(box, { BackgroundTransparency = 0.28 }, 0.16)
            input.Value = box.Text
            input:_fire(box.Text)
        end)
    )
    if not config.Finished then
        addConnection(
            self.Window,
            box:GetPropertyChangedSignal("Text"):Connect(function()
                input.Value = box.Text
                input:_fire(box.Text)
            end)
        )
    end

    return self:_control(id, input)
end

function Section:_closeDropdowns()
    if self.Window and self.Window.OpenDropdownCleanup then
        pcall(self.Window.OpenDropdownCleanup)
        self.Window.OpenDropdownCleanup = nil
    end
    if self.Window and self.Window.OpenDropdown and self.Window.OpenDropdown.Parent then
        self.Window.OpenDropdown:Destroy()
        self.Window.OpenDropdown = nil
    end
end

function Section:CreateDropdown(id, config)
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local values = config.Values or config.Options or {}
    local multi = config.Multi == true
    local default = config.Default
    if multi and type(default) ~= "table" then
        default = {}
    end
    if not multi and default == nil then
        default = values[1]
    end

    local row, holder = makeControlRow(self, config.Title or id or "Dropdown", config.Description, 58)
    local dropdown = setmetatable({
        Value = default,
        Values = values,
        Multi = multi,
        Callback = config.Callback,
        ChangedCallbacks = {},
        Instance = row,
    }, BaseControl)

    local button = create("TextButton", {
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 34),
        Parent = holder,
    })
    corner(button, 11)
    local bstroke = stroke(button, Theme.Stroke, 0.7, 1)
    local label = makeText(button, "", 12, Theme.Text, "bold")
    label.Position = UDim2.fromOffset(12, 0)
    label.Size = UDim2.new(1, -36, 1, 0)
    local arrow = makeText(button, "⌄", 14, Theme.SubText, "bold")
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -12, 0.5, -1)
    arrow.Size = UDim2.fromOffset(16, 16)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local function contains(tbl, value)
        for _, item in ipairs(tbl) do
            if item == value then
                return true
            end
        end
        return false
    end
    local function displayValue(value)
        if multi then
            local parts = {}
            if type(value) == "table" then
                for _, item in ipairs(value) do
                    table.insert(parts, tostring(item))
                end
            end
            return #parts > 0 and table.concat(parts, ", ") or (config.Placeholder or "Select...")
        end
        return value ~= nil and tostring(value) or (config.Placeholder or "Select...")
    end
    local function refreshLabel()
        label.Text = displayValue(dropdown.Value)
    end
    refreshLabel()

    function dropdown:SetValue(value)
        if multi then
            if type(value) ~= "table" then
                value = {}
            end
            self.Value = value
        else
            self.Value = value
        end
        refreshLabel()
        self:_fire(self.Value)
    end
    function dropdown:SetValues(newValues)
        self.Values = newValues or {}
        values = self.Values
    end

    local function openMenu()
        self:_closeDropdowns()
        local root = self.Window.Overlay
        local abs = button.AbsolutePosition
        local size = button.AbsoluteSize
        local menu = create("Frame", {
            Name = "DropdownMenu",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(abs.X - root.AbsolutePosition.X, abs.Y - root.AbsolutePosition.Y + size.Y + 8),
            Size = UDim2.fromOffset(math.max(size.X, 210), config.Search and 260 or 220),
            Parent = root,
            ZIndex = 300,
        })
        self.Window.OpenDropdown = menu
        local overlayOwner = { Connections = {} }
        local function bind(connection)
            table.insert(overlayOwner.Connections, connection)
            return connection
        end
        local function cleanupOverlay()
            disconnectAll(overlayOwner)
            if self.Window.OpenDropdown == menu then
                self.Window.OpenDropdown = nil
            end
            if self.Window.OpenDropdownCleanup == cleanupOverlay then
                self.Window.OpenDropdownCleanup = nil
            end
        end
        self.Window.OpenDropdownCleanup = cleanupOverlay
        bind(menu.AncestryChanged:Connect(function(_, parent)
            if parent == nil then
                cleanupOverlay()
            end
        end))
        bind(UserInputService.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                if not pointInside(menu, input.Position) and not pointInside(button, input.Position) then
                    self:_closeDropdowns()
                end
            end
        end))
        local body = makeGlass(menu, 14, Theme.Surface, 0.42)
        body.Size = UDim2.fromScale(1, 1)
        body.ZIndex = 301
        padding(body, 8, 8, 8, 8)
        local searchBox
        local topOffset = 0
        if config.Search then
            searchBox = create("TextBox", {
                BackgroundColor3 = Theme.Surface3,
                BackgroundTransparency = 0.22,
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                Text = "",
                PlaceholderText = "Search...",
                PlaceholderColor3 = Theme.Muted,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 32),
                Parent = body,
                ZIndex = 302,
            })
            corner(searchBox, 10)
            padding(searchBox, 10, 0, 10, 0)
            topOffset = 40
        end
        local scroll = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, topOffset),
            Size = UDim2.new(1, 0, 1, -topOffset),
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Accent,
            Parent = body,
            ZIndex = 302,
        })
        local content = create(
            "Frame",
            { BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 0), Parent = scroll, ZIndex = 303 }
        )
        local layout = list(content, Enum.FillDirection.Vertical, 5)
        bind(connectLayoutCanvas(scroll, layout, 8))

        local function rebuild(filter)
            for _, child in ipairs(content:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            filter = string.lower(filter or "")
            for _, value in ipairs(values) do
                if filter == "" or string.find(string.lower(tostring(value)), filter, 1, true) then
                    local selected = multi and type(dropdown.Value) == "table" and contains(dropdown.Value, value)
                        or dropdown.Value == value
                    local item = create("TextButton", {
                        BackgroundColor3 = selected and Theme.Accent or Theme.Surface2,
                        BackgroundTransparency = selected and 0.12 or 0.55,
                        BorderSizePixel = 0,
                        Text = "",
                        AutoButtonColor = false,
                        Size = UDim2.new(1, 0, 0, 32),
                        Parent = content,
                        ZIndex = 304,
                    })
                    corner(item, 9)
                    local itxt = makeText(item, tostring(value), 12, selected and Theme.White or Theme.SubText, "bold")
                    itxt.Position = UDim2.fromOffset(10, 0)
                    itxt.Size = UDim2.new(1, -38, 1, 0)
                    itxt.ZIndex = 305
                    if multi then
                        local check = makeText(item, selected and "✓" or "", 13, Theme.White, "bold")
                        check.AnchorPoint = Vector2.new(1, 0.5)
                        check.Position = UDim2.new(1, -10, 0.5, 0)
                        check.Size = UDim2.fromOffset(20, 20)
                        check.TextXAlignment = Enum.TextXAlignment.Center
                        check.ZIndex = 305
                    end
                    addConnection(
                        self.Window,
                        item.MouseEnter:Connect(function()
                            tween(item, { BackgroundTransparency = selected and 0.06 or 0.34 }, 0.12)
                        end)
                    )
                    addConnection(
                        self.Window,
                        item.MouseLeave:Connect(function()
                            tween(item, { BackgroundTransparency = selected and 0.12 or 0.55 }, 0.12)
                        end)
                    )
                    addConnection(
                        self.Window,
                        item.MouseButton1Click:Connect(function()
                            if multi then
                                local nextValue = {}
                                if type(dropdown.Value) == "table" then
                                    for _, old in ipairs(dropdown.Value) do
                                        table.insert(nextValue, old)
                                    end
                                end
                                if contains(nextValue, value) then
                                    for i = #nextValue, 1, -1 do
                                        if nextValue[i] == value then
                                            table.remove(nextValue, i)
                                        end
                                    end
                                else
                                    table.insert(nextValue, value)
                                end
                                dropdown:SetValue(nextValue)
                                rebuild(searchBox and searchBox.Text or "")
                            else
                                dropdown:SetValue(value)
                                self:_closeDropdowns()
                            end
                        end)
                    )
                end
            end
        end
        rebuild("")
        if searchBox then
            addConnection(
                self.Window,
                searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    rebuild(searchBox.Text)
                end)
            )
        end
        body.Position = UDim2.fromOffset(0, -6)
        body.BackgroundTransparency = 1
        tween(body, { BackgroundTransparency = 0.06, Position = UDim2.fromOffset(0, 0) }, 0.2)
    end

    addConnection(
        self.Window,
        button.MouseEnter:Connect(function()
            tween(button, { BackgroundTransparency = 0.16 }, 0.14)
            tween(bstroke, { Color = Theme.Accent, Transparency = 0.5 }, 0.14)
        end)
    )
    addConnection(
        self.Window,
        button.MouseLeave:Connect(function()
            tween(button, { BackgroundTransparency = 0.28 }, 0.14)
            tween(bstroke, { Color = Theme.Stroke, Transparency = 0.7 }, 0.14)
        end)
    )
    addConnection(self.Window, button.MouseButton1Click:Connect(openMenu))

    return self:_control(id, dropdown)
end

function Section:CreateButton(id, config)
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local row = create("Frame", {
        Name = "ButtonRow",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 44),
        Parent = self.Content,
    })
    local button = makeGlass(row, 14, Theme.Surface2, 0.58)
    button.Size = UDim2.fromScale(1, 1)
    local label = makeText(button, config.Title or id or "Button", 13, Theme.Text, "bold")
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Size = UDim2.fromScale(1, 1)
    local hit = makeHitbox(button)
    hit.ZIndex = 20
    local control = setmetatable({ Value = nil, Callback = config.Callback, Instance = row }, BaseControl)
    addConnection(
        self.Window,
        hit.MouseEnter:Connect(function()
            tween(button, { BackgroundColor3 = Theme.SurfaceHover }, 0.16)
        end)
    )
    addConnection(
        self.Window,
        hit.MouseLeave:Connect(function()
            tween(button, { BackgroundColor3 = Theme.Surface2 }, 0.16)
        end)
    )
    addConnection(
        self.Window,
        hit.MouseButton1Down:Connect(function()
            tween(button, { Size = UDim2.new(1, -4, 1, -4), Position = UDim2.fromOffset(2, 2) }, 0.08)
        end)
    )
    addConnection(
        self.Window,
        hit.MouseButton1Up:Connect(function()
            tween(
                button,
                { Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, 0) },
                0.12,
                Enum.EasingStyle.Back
            )
        end)
    )
    addConnection(
        self.Window,
        hit.MouseButton1Click:Connect(function()
            control:_fire(true)
        end)
    )
    return self:_control(id, control)
end

function Section:CreateParagraph(id, config)
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local frame = makeGlass(self.Content, 14, Theme.Surface2, 0.72)
    frame.Size = UDim2.new(1, 0, 0, 90)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    padding(frame, 16, 14, 16, 14)
    local title = makeText(frame, config.Title or id or "Paragraph", 13, Theme.Text, "bold")
    title.Size = UDim2.new(1, 0, 0, 20)
    local content = makeText(frame, config.Content or config.Text or "", 12, Theme.SubText)
    content.Position = UDim2.fromOffset(0, 26)
    content.Size = UDim2.new(1, 0, 0, 44)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.TextWrapped = true
    content.TextYAlignment = Enum.TextYAlignment.Top
    local paragraph = setmetatable({ Value = config.Content or config.Text or "", Instance = frame }, BaseControl)
    function paragraph:SetValue(value)
        self.Value = tostring(value or "")
        content.Text = self.Value
        self:_fire(self.Value)
    end
    return self:_control(id, paragraph)
end

function Section:CreateKeybind(id, config)
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local row, holder = makeControlRow(self, config.Title or id or "Keybind", config.Description, 58)
    local keybind = setmetatable({
        Value = config.Default or "NONE",
        Mode = config.Mode or "Toggle",
        Callback = config.Callback,
        ChangedCallbacks = {},
        Instance = row,
        Listening = false,
        Held = false,
        Toggled = false,
    }, BaseControl)
    local button = create("TextButton", {
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Text = "[" .. tostring(keybind.Value) .. "]",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(96, 34),
        Parent = holder,
    })
    corner(button, 11)
    stroke(button, Theme.Stroke, 0.7, 1)

    function keybind:SetValue(value)
        self.Value = value or "NONE"
        button.Text = "[" .. tostring(self.Value) .. "]"
        self:_fire(self.Value)
    end
    function keybind:SetMode(mode)
        self.Mode = mode or "Toggle"
    end

    addConnection(
        self.Window,
        button.MouseButton1Click:Connect(function()
            keybind.Listening = true
            button.Text = "[...]"
            tween(button, { TextColor3 = Theme.Accent }, 0.12)
        end)
    )
    addConnection(
        self.Window,
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed and not keybind.Listening then
                return
            end
            if keybind.Listening then
                local keyName = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or input.UserInputType.Name
                keybind.Listening = false
                keybind:SetValue(keyName)
                tween(button, { TextColor3 = Theme.SubText }, 0.12)
                return
            end
            if keybind.Value ~= "NONE" and input.KeyCode.Name == keybind.Value then
                if keybind.Mode == "Hold" then
                    keybind.Held = true
                    keybind:_fire(true)
                elseif keybind.Mode == "Toggle" then
                    keybind.Toggled = not keybind.Toggled
                    keybind:_fire(keybind.Toggled)
                elseif keybind.Mode == "Always" then
                    keybind:_fire(true)
                end
            end
        end)
    )
    addConnection(
        self.Window,
        UserInputService.InputEnded:Connect(function(input)
            if keybind.Mode == "Hold" and keybind.Value ~= "NONE" and input.KeyCode.Name == keybind.Value then
                keybind.Held = false
                keybind:_fire(false)
            end
        end)
    )

    return self:_control(id, keybind)
end

function Section:CreateColorpicker(id, config)
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local default = config.Default or Color3.fromRGB(255, 87, 90)
    local alpha = config.Transparency or config.Alpha or 0
    local row, holder = makeControlRow(self, config.Title or id or "Color", config.Description, 58)
    local picker = setmetatable(
        { Value = default, Transparency = alpha, Callback = config.Callback, ChangedCallbacks = {}, Instance = row },
        BaseControl
    )
    local preview = create("TextButton", {
        BackgroundColor3 = default,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(72, 34),
        Parent = holder,
    })
    corner(preview, 12)
    stroke(preview, Theme.White, 0.62, 1)
    local hex = makeText(preview, rgbToHex(default), 11, Theme.White, "bold")
    hex.TextXAlignment = Enum.TextXAlignment.Center
    hex.Size = UDim2.fromScale(1, 1)

    function picker:SetValue(color, trans)
        if typeof(color) ~= "Color3" then
            return
        end
        self.Value = color
        if trans ~= nil then
            self.Transparency = trans
        end
        preview.BackgroundColor3 = color
        hex.Text = rgbToHex(color)
        self:_fire(color)
    end

    local function openPicker()
        self:_closeDropdowns()
        local root = self.Window.Overlay
        local abs = preview.AbsolutePosition
        local menu = create("Frame", {
            Name = "Colorpicker",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(abs.X - root.AbsolutePosition.X - 210, abs.Y - root.AbsolutePosition.Y + 44),
            Size = UDim2.fromOffset(292, 390),
            Parent = root,
            ZIndex = 330,
        })
        self.Window.OpenDropdown = menu
        local overlayOwner = { Connections = {} }
        local function bind(connection)
            table.insert(overlayOwner.Connections, connection)
            return connection
        end
        local function cleanupOverlay()
            disconnectAll(overlayOwner)
            if self.Window.OpenDropdown == menu then
                self.Window.OpenDropdown = nil
            end
            if self.Window.OpenDropdownCleanup == cleanupOverlay then
                self.Window.OpenDropdownCleanup = nil
            end
        end
        self.Window.OpenDropdownCleanup = cleanupOverlay
        bind(menu.AncestryChanged:Connect(function(_, parent)
            if parent == nil then
                cleanupOverlay()
            end
        end))
        bind(UserInputService.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                if not pointInside(menu, input.Position) and not pointInside(preview, input.Position) then
                    self:_closeDropdowns()
                end
            end
        end))
        local body = makeGlass(menu, 18, Theme.Surface, 0.42)
        body.Size = UDim2.fromScale(1, 1)
        body.ZIndex = 331
        padding(body, 14, 14, 14, 14)

        local h, s, v = picker.Value:ToHSV()
        local currentAlpha = picker.Transparency or 0

        local sat = create("Frame", {
            BackgroundColor3 = Color3.fromHSV(h, 1, 1),
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 0, 178),
            Parent = body,
            ZIndex = 332,
        })
        corner(sat, 16)
        stroke(sat, Theme.White, 0.74, 1)
        gradient(sat, Theme.White, Color3.fromHSV(h, 1, 1), 0)
        local blackOverlay = create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            Parent = sat,
            ZIndex = 333,
        })
        corner(blackOverlay, 16)
        gradient(
            blackOverlay,
            Color3.new(1, 1, 1),
            Color3.new(0, 0, 0),
            90,
            NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
        )
        local satDot = create("Frame", {
            BackgroundColor3 = Theme.White,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(12, 12),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(s, 1 - v),
            Parent = sat,
            ZIndex = 334,
        })
        corner(satDot, 12)
        stroke(satDot, Color3.new(0, 0, 0), 0.3, 1)

        local hue = create("Frame", {
            BackgroundColor3 = Theme.White,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 192),
            Size = UDim2.new(1, 0, 0, 14),
            Parent = body,
            ZIndex = 332,
        })
        corner(hue, 10)
        gradient(hue, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 0, 0), 0)
        local hueGrad = hue:FindFirstChildOfClass("UIGradient")
        hueGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        })
        local hueDot = create("Frame", {
            BackgroundColor3 = Theme.White,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(8, 20),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(h, 0.5),
            Parent = hue,
            ZIndex = 333,
        })
        corner(hueDot, 6)

        local alphaBar = create("Frame", {
            BackgroundColor3 = picker.Value,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 222),
            Size = UDim2.new(1, 0, 0, 14),
            Parent = body,
            ZIndex = 332,
        })
        corner(alphaBar, 10)
        gradient(alphaBar, picker.Value, Theme.Surface3, 0)
        local alphaDot = create("Frame", {
            BackgroundColor3 = Theme.White,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(8, 20),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(1 - currentAlpha, 0.5),
            Parent = alphaBar,
            ZIndex = 333,
        })
        corner(alphaDot, 6)

        local hexBox = create("TextBox", {
            BackgroundColor3 = Theme.Surface3,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            Text = rgbToHex(picker.Value),
            PlaceholderText = "#FFFFFF",
            ClearTextOnFocus = false,
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            Position = UDim2.fromOffset(0, 254),
            Size = UDim2.new(0.62, -6, 0, 36),
            Parent = body,
            ZIndex = 332,
        })
        corner(hexBox, 12)
        stroke(hexBox, Theme.Stroke, 0.7, 1)
        padding(hexBox, 12, 0, 12, 0)
        local alphaLabel =
            makeText(body, tostring(math.floor((1 - currentAlpha) * 100)) .. "%", 12, Theme.SubText, "bold")
        alphaLabel.TextXAlignment = Enum.TextXAlignment.Center
        alphaLabel.BackgroundColor3 = Theme.Surface3
        alphaLabel.BackgroundTransparency = 0.2
        alphaLabel.Position = UDim2.new(0.62, 6, 0, 254)
        alphaLabel.Size = UDim2.new(0.38, -6, 0, 36)
        corner(alphaLabel, 12)
        stroke(alphaLabel, Theme.Stroke, 0.7, 1)

        local presets = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 306),
            Size = UDim2.new(1, 0, 0, 34),
            Parent = body,
            ZIndex = 332,
        })
        local presetsLayout = list(presets, Enum.FillDirection.Horizontal, 8)
        presetsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        local presetColors = config.Presets
            or {
                Theme.Accent,
                Color3.fromRGB(255, 120, 122),
                Color3.fromRGB(255, 160, 160),
                Color3.fromRGB(255, 205, 205),
                Color3.fromRGB(120, 170, 255),
            }
        for _, pc in ipairs(presetColors) do
            local pbtn = create("TextButton", {
                BackgroundColor3 = pc,
                BorderSizePixel = 0,
                Text = "",
                Size = UDim2.fromOffset(28, 28),
                AutoButtonColor = false,
                Parent = presets,
                ZIndex = 333,
            })
            corner(pbtn, 28)
            stroke(pbtn, Theme.White, 0.55, 1)
            addConnection(
                self.Window,
                pbtn.MouseButton1Click:Connect(function()
                    h, s, v = pc:ToHSV()
                    picker:SetValue(pc, currentAlpha)
                    sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    alphaBar.BackgroundColor3 = pc
                    hexBox.Text = rgbToHex(pc)
                    satDot.Position = UDim2.fromScale(s, 1 - v)
                    hueDot.Position = UDim2.fromScale(h, 0.5)
                end)
            )
        end

        local function apply()
            local c = Color3.fromHSV(h, s, v)
            picker:SetValue(c, currentAlpha)
            sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            alphaBar.BackgroundColor3 = c
            hexBox.Text = rgbToHex(c)
            alphaLabel.Text = tostring(math.floor((1 - currentAlpha) * 100)) .. "%"
        end
        local satDrag, hueDrag, alphaDrag = false, false, false
        local function updateSat(input)
            s = clamp((input.Position.X - sat.AbsolutePosition.X) / sat.AbsoluteSize.X, 0, 1)
            v = 1 - clamp((input.Position.Y - sat.AbsolutePosition.Y) / sat.AbsoluteSize.Y, 0, 1)
            satDot.Position = UDim2.fromScale(s, 1 - v)
            apply()
        end
        local function updateHue(input)
            h = clamp((input.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
            hueDot.Position = UDim2.fromScale(h, 0.5)
            apply()
        end
        local function updateAlpha(input)
            currentAlpha = 1 - clamp((input.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
            alphaDot.Position = UDim2.fromScale(1 - currentAlpha, 0.5)
            apply()
        end
        addConnection(
            self.Window,
            sat.InputBegan:Connect(function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    satDrag = true
                    updateSat(input)
                end
            end)
        )
        addConnection(
            self.Window,
            hue.InputBegan:Connect(function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    hueDrag = true
                    updateHue(input)
                end
            end)
        )
        addConnection(
            self.Window,
            alphaBar.InputBegan:Connect(function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    alphaDrag = true
                    updateAlpha(input)
                end
            end)
        )
        addConnection(
            self.Window,
            UserInputService.InputChanged:Connect(function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    if satDrag then
                        updateSat(input)
                    elseif hueDrag then
                        updateHue(input)
                    elseif alphaDrag then
                        updateAlpha(input)
                    end
                end
            end)
        )
        addConnection(
            self.Window,
            UserInputService.InputEnded:Connect(function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    satDrag = false
                    hueDrag = false
                    alphaDrag = false
                end
            end)
        )
        addConnection(
            self.Window,
            hexBox.FocusLost:Connect(function()
                local c = hexToColor(hexBox.Text)
                if c then
                    h, s, v = c:ToHSV()
                    picker:SetValue(c, currentAlpha)
                    sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    alphaBar.BackgroundColor3 = c
                    satDot.Position = UDim2.fromScale(s, 1 - v)
                    hueDot.Position = UDim2.fromScale(h, 0.5)
                else
                    hexBox.Text = rgbToHex(picker.Value)
                end
            end)
        )
    end

    addConnection(self.Window, preview.MouseButton1Click:Connect(openPicker))
    return self:_control(id, picker)
end

function Section:Destroy()
    disconnectAll(self)
    for _, child in ipairs(self.Content:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    if self.Instance then
        self.Instance:Destroy()
    end
    if self.SubTab then
        self.SubTab:_updateCanvas()
    end
end

function SubTab:_updateCanvas()
    task.defer(function()
        if not self.Scroll or not self.Scroll.Parent then
            return
        end
        local leftY = self.LeftLayout.AbsoluteContentSize.Y
        local rightY = self.RightLayout.AbsoluteContentSize.Y
        local height = math.max(leftY, rightY) + 28
        self.Content.Size = UDim2.new(1, -8, 0, height)
        self.Scroll.CanvasSize = UDim2.fromOffset(0, height)
    end)
end

function SubTab:CreateSection(config)
    config = config or {}
    if type(config) == "string" then
        config = { Title = config }
    end
    local side = string.lower(config.Side or "Left") == "right" and "Right" or "Left"
    local parent = side == "Right" and self.RightColumn or self.LeftColumn
    local section = setmetatable(
        { Window = self.Window, Tab = self.Tab, SubTab = self, Side = side, Controls = {}, Connections = {} },
        Section
    )
    local frame = makeGlass(parent, 18, Theme.Surface, 0.64)
    frame.Name = "Section"
    frame.Size = UDim2.new(1, 0, 0, 80)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    padding(frame, 14, 13, 14, 14)
    local title = makeText(frame, config.Title or "Section", 13, Theme.Text, "bold")
    title.Size = UDim2.new(1, 0, 0, 22)
    local content = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 32),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = frame,
    })
    local layout = list(content, Enum.FillDirection.Vertical, 8)
    section.Instance = frame
    section.Content = content
    section.Layout = layout
    addConnection(
        self.Window,
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            content.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
            self:_updateCanvas()
        end)
    )
    addConnection(
        self.Window,
        frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            self:_updateCanvas()
        end)
    )
    table.insert(self.Sections, section)
    self:_updateCanvas()
    return section
end

SubTab.AddSection = SubTab.CreateSection

function SubTab:Destroy()
    disconnectAll(self)
    for _, section in ipairs(self.Sections) do
        pcall(function()
            section:Destroy()
        end)
    end
    if self.Button then
        self.Button:Destroy()
    end
    if self.Scroll then
        self.Scroll:Destroy()
    end
end

function SubTab:Select()
    if self.Tab then
        self.Tab:SelectSubTab(self)
    end
end

function Tab:_ensureDefaultSubTab()
    if self.DefaultSubTab then
        return self.DefaultSubTab
    end
    self.DefaultSubTab = self:CreateSubTab({ Title = "Main" })
    return self.DefaultSubTab
end

function Tab:CreateSection(config)
    return self:_ensureDefaultSubTab():CreateSection(config)
end

function Tab:Select()
    if self.Window then
        self.Window:SelectTab(self)
    end
end

Tab.AddSection = Tab.CreateSection

function Tab:CreateSubTab(config)
    config = config or {}
    if type(config) == "string" then
        config = { Title = config }
    end
    local sub = setmetatable(
        { Window = self.Window, Tab = self, Title = config.Title or "Sub Tab", Sections = {}, Connections = {} },
        SubTab
    )

    local button = create("TextButton", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.62,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromOffset(math.max(96, 42 + #sub.Title * 8), 42),
        Parent = self.SubTabBar,
    })
    corner(button, 16)
    local bstroke = stroke(button, Theme.StrokeSoft, 0.9, 1)
    local label = makeText(button, sub.Title, 12, Theme.Muted, "bold")
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Size = UDim2.fromScale(1, 1)

    local scroll = create("ScrollingFrame", {
        Name = "SubTabContent",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 58),
        Size = UDim2.new(1, 0, 1, -58),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.18,
        Visible = false,
        Parent = self.ContentHost,
    })
    local content = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -8, 0, 0),
        Parent = scroll,
    })
    local columns = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = content })
    local colLayout = list(columns, Enum.FillDirection.Horizontal, 14)
    colLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    local leftColumn = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -7, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = columns,
    })
    local rightColumn = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -7, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = columns,
    })
    local leftLayout = list(leftColumn, Enum.FillDirection.Vertical, 14)
    local rightLayout = list(rightColumn, Enum.FillDirection.Vertical, 14)

    sub.Button = button
    sub.ButtonLabel = label
    sub.ButtonStroke = bstroke
    sub.Scroll = scroll
    sub.Content = content
    sub.Columns = columns
    sub.LeftColumn = leftColumn
    sub.RightColumn = rightColumn
    sub.LeftLayout = leftLayout
    sub.RightLayout = rightLayout

    addConnection(
        self.Window,
        leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            sub:_updateCanvas()
        end)
    )
    addConnection(
        self.Window,
        rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            sub:_updateCanvas()
        end)
    )
    addConnection(
        self.Window,
        button.MouseButton1Click:Connect(function()
            self:SelectSubTab(sub)
        end)
    )
    addConnection(
        self.Window,
        button.MouseEnter:Connect(function()
            if self.ActiveSubTab ~= sub then
                tween(button, { BackgroundTransparency = 0.48 }, 0.14)
            end
        end)
    )
    addConnection(
        self.Window,
        button.MouseLeave:Connect(function()
            if self.ActiveSubTab ~= sub then
                tween(button, { BackgroundTransparency = 0.62 }, 0.14)
            end
        end)
    )

    table.insert(self.SubTabs, sub)
    if not self.ActiveSubTab then
        self:SelectSubTab(sub, true)
    end
    return sub
end

Tab.AddSubTab = Tab.CreateSubTab
Tab.AddSubtab = Tab.CreateSubTab

function Tab:SelectSubTab(sub, instant)
    if self.ActiveSubTab == sub then
        return
    end
    if self.ActiveSubTab then
        local old = self.ActiveSubTab
        tween(old.Button, { BackgroundTransparency = 0.62 }, 0.18)
        tween(old.ButtonStroke, { Transparency = 0.9, Color = Theme.StrokeSoft }, 0.18)
        tween(old.ButtonLabel, { TextColor3 = Theme.Muted }, 0.18)
        old.Scroll.Visible = false
    end
    self.ActiveSubTab = sub
    sub.Scroll.Visible = true
    sub:_updateCanvas()
    tween(
        sub.Button,
        { BackgroundTransparency = 0.08, BackgroundColor3 = Theme.Surface3 },
        instant and 0 or 0.22,
        Enum.EasingStyle.Quint
    )
    tween(sub.ButtonStroke, { Transparency = 0.46, Color = Theme.Accent }, instant and 0 or 0.22)
    tween(sub.ButtonLabel, { TextColor3 = Theme.Text }, instant and 0 or 0.22)
end

function Tab:Destroy()
    for _, sub in ipairs(self.SubTabs) do
        if sub.Scroll then
            sub.Scroll:Destroy()
        end
        if sub.Button then
            sub.Button:Destroy()
        end
    end
    if self.Button then
        self.Button:Destroy()
    end
end

function Window:_setActiveTabVisual(tab, active)
    if not tab then
        return
    end
    tween(tab.Button, { BackgroundTransparency = active and 0.1 or 1 }, 0.22)
    tween(tab.ActiveBar, {
        BackgroundTransparency = active and 0 or 1,
        Size = active and UDim2.fromOffset(4, 30) or UDim2.fromOffset(4, 12),
    }, 0.22, Enum.EasingStyle.Quint)
    tween(tab.IconLabel, { TextColor3 = active and Theme.Accent or Theme.Muted }, 0.22)
    tween(tab.TitleLabel, { TextColor3 = active and Theme.Text or Theme.Muted }, 0.22)
end

function Window:SelectTab(tab)
    if type(tab) == "string" then
        for _, t in ipairs(self.Tabs) do
            if t.Title == tab then
                tab = t
                break
            end
        end
    end
    if not tab or self.ActiveTab == tab then
        return
    end
    if self.ActiveTab then
        self.ActiveTab.Page.Visible = false
        self:_setActiveTabVisual(self.ActiveTab, false)
    end
    self.ActiveTab = tab
    tab.Page.Visible = true
    self:_setActiveTabVisual(tab, true)
end

function Window:CreateTab(config)
    config = config or {}
    if type(config) == "string" then
        config = { Title = config }
    end
    local tab = setmetatable({ Window = self, Title = config.Title or "Tab", SubTabs = {}, Connections = {} }, Tab)

    local button = create("TextButton", {
        Name = "TabButton",
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 54),
        Parent = self.SidebarList,
    })
    corner(button, 17)
    local active = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(4, 12),
        Parent = button,
    })
    corner(active, 4)
    local icon = makeText(button, getIcon(config.Icon or config.Title), 17, Theme.Muted, "bold")
    icon.Position = UDim2.fromOffset(20, 0)
    icon.Size = UDim2.fromOffset(24, 54)
    icon.TextXAlignment = Enum.TextXAlignment.Center
    local title = makeText(button, tab.Title, 13, Theme.Muted, "bold")
    title.Position = UDim2.fromOffset(58, 0)
    title.Size = UDim2.new(1, -66, 1, 0)

    local page = create("Frame", {
        Name = "TabPage",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = self.PageHost,
    })
    local subBar = create(
        "Frame",
        { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 48), Parent = page }
    )
    local subLayout = list(subBar, Enum.FillDirection.Horizontal, 10)
    subLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    local contentHost = create(
        "Frame",
        { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromScale(1, 1), Parent = page }
    )

    tab.Button = button
    tab.ActiveBar = active
    tab.IconLabel = icon
    tab.TitleLabel = title
    tab.Page = page
    tab.SubTabBar = subBar
    tab.ContentHost = contentHost

    addConnection(
        self,
        button.MouseButton1Click:Connect(function()
            self:SelectTab(tab)
        end)
    )
    addConnection(
        self,
        button.MouseEnter:Connect(function()
            if self.ActiveTab ~= tab then
                tween(button, { BackgroundTransparency = 0.68 }, 0.14)
            end
        end)
    )
    addConnection(
        self,
        button.MouseLeave:Connect(function()
            if self.ActiveTab ~= tab then
                tween(button, { BackgroundTransparency = 1 }, 0.14)
            end
        end)
    )

    table.insert(self.Tabs, tab)
    if not self.ActiveTab then
        self:SelectTab(tab)
    end
    return tab
end

Window.AddTab = Window.CreateTab

function Window:Notify(config)
    return self.Library:Notify(config)
end

function Window:_makeHeader(config)
    local header = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(28, 22),
        Size = UDim2.new(1, -56, 0, 76),
        Parent = self.Main,
    })
    local logoWrap = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(44, 44),
        Position = UDim2.fromOffset(0, 10),
        Parent = header,
    })
    corner(logoWrap, 15)
    stroke(logoWrap, Theme.Accent, 0.54, 1)
    if config.Logo then
        create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = config.Logo,
            Size = UDim2.fromOffset(26, 26),
            Position = UDim2.fromOffset(9, 9),
            Parent = logoWrap,
        })
    else
        local l = makeText(logoWrap, string.sub(config.Title or "T", 1, 1), 20, Theme.Accent, "bold")
        l.TextXAlignment = Enum.TextXAlignment.Center
        l.Size = UDim2.fromScale(1, 1)
    end
    local title = makeText(header, config.Title or "Testing UI", 15, Theme.Text, "bold")
    title.Position = UDim2.fromOffset(58, 11)
    title.Size = UDim2.fromOffset(220, 22)
    local sub = makeText(header, config.SubTitle or config.Subtitle or "Premium UI Library", 11, Theme.Muted)
    sub.Position = UDim2.fromOffset(58, 34)
    sub.Size = UDim2.fromOffset(260, 18)

    local profile = create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 5),
        Size = UDim2.fromOffset(250, 54),
        Parent = header,
    })
    local avatar = create("Frame", {
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(44, 44),
        Parent = profile,
    })
    corner(avatar, 44)
    stroke(avatar, Theme.White, 0.82, 1)
    local avIcon = makeText(avatar, getIcon(config.UserIcon or "User"), 18, Theme.Text, "bold")
    avIcon.TextXAlignment = Enum.TextXAlignment.Center
    avIcon.Size = UDim2.fromScale(1, 1)
    local pTitle = makeText(profile, config.UserName or "Past Owl", 13, Theme.Text, "bold")
    pTitle.AnchorPoint = Vector2.new(1, 0)
    pTitle.Position = UDim2.new(1, -54, 0, 8)
    pTitle.Size = UDim2.fromOffset(160, 18)
    pTitle.TextXAlignment = Enum.TextXAlignment.Right
    local pSub = makeText(profile, config.UserSubTitle or config.UserSubtitle or "Premium member", 11, Theme.Muted)
    pSub.AnchorPoint = Vector2.new(1, 0)
    pSub.Position = UDim2.new(1, -54, 0, 28)
    pSub.Size = UDim2.fromOffset(170, 16)
    pSub.TextXAlignment = Enum.TextXAlignment.Right

    local search = create("TextButton", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.42,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 86),
        Size = UDim2.fromOffset(42, 42),
        Parent = self.Main,
    })
    corner(search, 15)
    stroke(search, Theme.Stroke, 0.78, 1)
    local sIcon = makeText(search, getIcon("Search"), 18, Theme.Muted, "bold")
    sIcon.TextXAlignment = Enum.TextXAlignment.Center
    sIcon.Size = UDim2.fromScale(1, 1)
    addConnection(
        self,
        search.MouseEnter:Connect(function()
            tween(search, { BackgroundTransparency = 0.24 }, 0.16)
            tween(sIcon, { TextColor3 = Theme.Text }, 0.16)
        end)
    )
    addConnection(
        self,
        search.MouseLeave:Connect(function()
            tween(search, { BackgroundTransparency = 0.42 }, 0.16)
            tween(sIcon, { TextColor3 = Theme.Muted }, 0.16)
        end)
    )
    addConnection(
        self,
        search.MouseButton1Click:Connect(function()
            safeCall(config.SearchCallback or config.OnSearch, self)
        end)
    )

    return header
end

function Window:_enableDrag(handle)
    local dragging, dragInput, startPos, startMouse = false, nil, nil, nil
    addConnection(
        self,
        handle.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                dragging = true
                dragInput = input
                startPos = self.Root.Position
                startMouse = input.Position
            end
        end)
    )
    addConnection(
        self,
        handle.InputChanged:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                dragInput = input
            end
        end)
    )
    addConnection(
        self,
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input == dragInput then
                local delta = input.Position - startMouse
                self.Root.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    )
    addConnection(
        self,
        UserInputService.InputEnded:Connect(function(input)
            if
                input == dragInput
                or input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                dragging = false
            end
        end)
    )
end

function Window:Close()
    if self.Closed then
        return
    end
    self.Closed = true
    tween(
        self.Root,
        { Size = UDim2.fromOffset(self.Width * 0.96, self.Height * 0.96) },
        0.22,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.In
    )
    for _, desc in ipairs(self.Root:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            pcall(function()
                tween(desc, { TextTransparency = 1 }, 0.18)
            end)
        elseif desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
            pcall(function()
                tween(desc, { BackgroundTransparency = 1 }, 0.18)
            end)
        elseif desc:IsA("UIStroke") then
            pcall(function()
                tween(desc, { Transparency = 1 }, 0.18)
            end)
        elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
            pcall(function()
                tween(desc, { ImageTransparency = 1 }, 0.18)
            end)
        end
    end
    task.delay(0.24, function()
        self:Destroy()
    end)
end

function Window:Destroy()
    disconnectAll(self)
    if self.Root then
        self.Root:Destroy()
    end
    for i = #Library.Windows, 1, -1 do
        if Library.Windows[i] == self then
            table.remove(Library.Windows, i)
        end
    end
end

Section.AddToggle = Section.CreateToggle
Section.AddSlider = Section.CreateSlider
Section.AddDropdown = Section.CreateDropdown
Section.AddInput = Section.CreateInput
Section.AddKeybind = Section.CreateKeybind
Section.AddButton = Section.CreateButton
Section.AddParagraph = Section.CreateParagraph
Section.AddColorpicker = Section.CreateColorpicker
Section.AddColorPicker = Section.CreateColorpicker
Section.CreateColorPicker = Section.CreateColorpicker

function Section:CreateMultiDropdown(id, config)
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    config.Multi = true
    return self:CreateDropdown(id, config)
end

Section.AddMultiDropdown = Section.CreateMultiDropdown

function Library:CreateWindow(config)
    config = config or {}
    local gui = self:_ensureGui()
    local width = config.Width or (config.Size and config.Size.X.Offset > 0 and config.Size.X.Offset) or 820
    local height = config.Height or (config.Size and config.Size.Y.Offset > 0 and config.Size.Y.Offset) or 520
    local window = setmetatable(
        { Library = self, Width = width, Height = height, Tabs = {}, Connections = {}, Closed = false },
        Window
    )

    local root = create("Frame", {
        Name = "Window",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, height),
        Parent = gui,
        ClipsDescendants = false,
        ZIndex = 10,
    })
    local scale = create("UIScale", { Parent = root })
    applyResponsiveScale(scale, 960, 640)
    addConnection(
        window,
        Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            applyResponsiveScale(scale, 960, 640)
        end)
    )

    local shadow1 = create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 16),
        Size = UDim2.fromScale(1, 1),
        Parent = root,
        ZIndex = 8,
    })
    corner(shadow1, 30)
    local main = makeGlass(root, 26, Theme.Background, 0.28)
    main.Name = "Main"
    main.Size = UDim2.fromScale(1, 1)
    main.ZIndex = 10
    stroke(main, Theme.Accent, 0.92, 1)
    window.Root = root
    window.Main = main
    window.Scale = scale

    local dragSurface =
        create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 104), Parent = main, ZIndex = 25 })
    window:_enableDrag(dragSurface)
    window:_makeHeader(config)

    local sidebar = makeGlass(main, 22, Theme.Surface, 0.76)
    sidebar.Name = "Sidebar"
    sidebar.Position = UDim2.fromOffset(22, 112)
    sidebar.Size = UDim2.new(0, 176, 1, -136)
    sidebar.ZIndex = 12
    padding(sidebar, 12, 14, 12, 14)
    local sidebarList = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = sidebar })
    local sidebarLayout = list(sidebarList, Enum.FillDirection.Vertical, 8)
    window.Sidebar = sidebar
    window.SidebarList = sidebarList

    local content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(218, 112),
        Size = UDim2.new(1, -244, 1, -134),
        Parent = main,
        ZIndex = 12,
    })
    window.Content = content
    window.PageHost =
        create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = content, ZIndex = 13 })
    window.Overlay = create(
        "Frame",
        { Name = "Overlay", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = main, ZIndex = 250 }
    )

    root.Size = UDim2.fromOffset(width * 0.96, height * 0.96)
    tween(root, { Size = UDim2.fromOffset(width, height) }, 0.38, Enum.EasingStyle.Back)

    table.insert(self.Windows, window)
    return window
end

function Library:Destroy()
    for _, window in ipairs(self.Windows) do
        pcall(function()
            window:Destroy()
        end)
    end
    setTableClear(self.Windows)
    disconnectAll(self)
    if self.GUI then
        self.GUI:Destroy()
    end
    self.GUI = nil
    self.ToastHolder = nil
    setTableClear(self.Options)
    setTableClear(self.Flags)
end

function Library:SetTheme(overrides)
    if type(overrides) == "table" then
        for key, value in pairs(overrides) do
            if typeof(value) == "Color3" then
                Theme[key] = value
            end
        end
    end
end

return Library
