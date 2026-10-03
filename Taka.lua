--[[
    Takataka UI — a premium Roblox interface library.
    Near-black graphite shell · restrained violet/magenta accent language ·
    one token table · one layout authority · one motion system · one cleanup owner.

    Public API:
        local Takataka = loadstring(game:HttpGet("..."))()
        local Window = Takataka:CreateWindow({ Title = "Takataka", Subtitle = "Premium Interface" })
        local Page = Window:AddPage({ Name = "Home", Icon = "home" })
        local Section = Page:AddSection({ Name = "General" })
        Section:AddToggle({ Name = "Enabled", Default = false, Callback = function(value) end })
        Window:Notify({ Title = "Ready", Text = "Takataka loaded", Type = "success" })
        Takataka:Demo()      -- optional showcase (never runs automatically)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local CoreGuiService = game:GetService("CoreGui")

local Library = {}
Library.__index = Library
Library.Version = "1.0.0"
Library.Name = "Takataka"

local Util = {}
local Theme = {}
local Motion = {}
local Scope = {}
local Anim = {}
local Prim = {}
local Layers = {}
local Components = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- Util — small, allocation-light helpers used everywhere else
-- ══════════════════════════════════════════════════════════════════════════════

function Util.clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    elseif value > maximum then
        return maximum
    end
    return value
end

function Util.round(value)
    return math.floor(value + 0.5)
end

function Util.trim(value)
    if type(value) == "string" then
        return (value:gsub("^%s+", ""):gsub("%s+$", ""))
    end
    return ""
end

function Util.finite(value, fallback)
    local number = tonumber(value)
    if number and number == number and number ~= math.huge and number ~= -math.huge then
        return number
    end
    return fallback
end

function Util.lerp(a, b, alpha)
    return a + (b - a) * alpha
end

-- UTF-8-safe truncation: never split a multi-byte character in half.
function Util.text(value, limit)
    local result = tostring(value == nil and "" or value)
    result = result:gsub("[%z\1-\8\11\12\14-\31]", "")
    local ok, length = pcall(utf8.len, result)
    if not ok or not length then
        result = result:gsub("[\128-\255]", "?")
    end
    if limit and #result > limit then
        local boundary = utf8.offset(result, 0, limit + 1)
        result = result:sub(1, (boundary or (limit + 1)) - 1)
    end
    return result
end

-- Measured text height with a formula fallback when TextService is unavailable.
function Util.measureHeight(text, size, font, width)
    local ok, bounds = pcall(function()
        return TextService:GetTextSize(text, size, font, Vector2.new(math.max(1, width), 10000))
    end)
    if ok and bounds then
        return bounds.Y
    end
    local perLine = math.max(1, math.floor(width / math.max(1, size * 0.52)))
    local lines = math.ceil(math.max(1, #tostring(text)) / perLine)
    return lines * size * 1.32
end

function Util.measureWidth(text, size, font)
    local ok, bounds = pcall(function()
        return TextService:GetTextSize(text, size, font, Vector2.new(10000, 10000))
    end)
    if ok and bounds then
        return bounds.X
    end
    return #tostring(text) * size * 0.52
end

function Util.clear(target)
    for key in pairs(target) do
        target[key] = nil
    end
    return target
end

function Util.count(target)
    local total = 0
    for _ in pairs(target) do
        total = total + 1
    end
    return total
end

function Util.copy(source)
    local output = {}
    for key, value in pairs(source) do
        output[key] = value
    end
    return output
end

function Util.merge(base, patch)
    for key, value in pairs(patch or {}) do
        base[key] = value
    end
    return base
end

-- Executor capabilities are optional enhancements, never hard dependencies.
function Util.capability(name)
    local ok, environment = pcall(function()
        return type(getgenv) == "function" and getgenv() or nil
    end)
    if ok and type(environment) == "table" and type(environment[name]) == "function" then
        return environment[name]
    end
    if type(_G) == "table" and type(_G[name]) == "function" then
        return _G[name]
    end
    local environment2 = getfenv and getfenv(0) or nil
    if environment2 and type(environment2[name]) == "function" then
        return environment2[name]
    end
    return nil
end

function Util.guard(callback, ...)
    if type(callback) ~= "function" then
        return true
    end
    local args = table.pack(...)
    local ok, failure = pcall(function()
        callback(unpack(args, 1, args.n))
    end)
    if not ok then
        warn("[Takataka] callback error: " .. tostring(failure))
    end
    return ok
end

function Util.safeCall(fn, ...)
    local args = table.pack(...)
    local ok, a, b, c = pcall(function()
        return fn(unpack(args, 1, args.n))
    end)
    if ok then
        return true, a, b, c
    end
    return false, a
end

function Util.hit(point, object)
    if not object or not object.Parent then
        return false
    end
    local origin = object.AbsolutePosition
    local size = object.AbsoluteSize
    return point.X >= origin.X
        and point.X <= origin.X + size.X
        and point.Y >= origin.Y
        and point.Y <= origin.Y + size.Y
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Theme — the single token table. Everything visual reads from here.
-- ══════════════════════════════════════════════════════════════════════════════

Theme.Color = {
    Bg = Color3.fromRGB(10, 10, 14),
    Canvas = Color3.fromRGB(14, 14, 18),
    Surface = Color3.fromRGB(19, 19, 24),
    SurfaceRaised = Color3.fromRGB(25, 25, 31),
    SurfaceInteractive = Color3.fromRGB(32, 32, 40),
    SurfaceHover = Color3.fromRGB(38, 38, 48),
    SurfacePressed = Color3.fromRGB(45, 45, 57),
    Input = Color3.fromRGB(23, 23, 29),
    InputFocus = Color3.fromRGB(28, 28, 36),
    Stroke = Color3.fromRGB(34, 34, 42),
    StrokeStrong = Color3.fromRGB(53, 53, 65),
    Text = Color3.fromRGB(242, 240, 246),
    TextSecondary = Color3.fromRGB(165, 160, 176),
    TextMuted = Color3.fromRGB(110, 105, 124),
    OnAccent = Color3.fromRGB(15, 12, 20),
    Accent = Color3.fromRGB(168, 139, 250),
    AccentHover = Color3.fromRGB(190, 166, 255),
    AccentPressed = Color3.fromRGB(142, 110, 232),
    AccentDeep = Color3.fromRGB(96, 68, 186),
    Magenta = Color3.fromRGB(232, 121, 200),
    Peach = Color3.fromRGB(240, 169, 140),
    Success = Color3.fromRGB(126, 217, 87),
    Warning = Color3.fromRGB(240, 179, 126),
    Danger = Color3.fromRGB(240, 80, 110),
    DangerDeep = Color3.fromRGB(74, 24, 34),
    Shadow = Color3.fromRGB(0, 0, 0),
    White = Color3.fromRGB(255, 255, 255),
}

Theme.Radius = {
    Small = 6,
    Medium = 10,
    Large = 14,
    Pill = 100,
}

Theme.Space = {
    XS = 4,
    S = 6,
    M = 8,
    L = 12,
    XL = 16,
    XXL = 20,
    XXXL = 24,
}

Theme.Font = {
    Regular = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Bold = Enum.Font.GothamBold,
    Mono = Enum.Font.Code,
}

Theme.Type = {
    Display = 30,
    Title = 21,
    Subtitle = 16,
    Body = 13,
    Small = 12,
    Caption = 11,
    Micro = 10,
}

Theme.Palette = {
    violet = Color3.fromRGB(168, 139, 250),
    magenta = Color3.fromRGB(232, 121, 200),
    lime = Color3.fromRGB(150, 214, 120),
    amber = Color3.fromRGB(238, 180, 118),
    mint = Color3.fromRGB(126, 217, 87),
}

Theme.Art = {
    mono = {
        base = Color3.fromRGB(26, 26, 33),
        orb = Color3.fromRGB(58, 58, 72),
        orb2 = Color3.fromRGB(36, 36, 46),
        stripe = Color3.fromRGB(255, 255, 255),
        stripeAlpha = 0.94,
        mark = Color3.fromRGB(122, 122, 140),
        markAlpha = 0.5,
    },
    accent = {
        base = Color3.fromRGB(34, 25, 48),
        orb = Color3.fromRGB(168, 139, 250),
        orb2 = Color3.fromRGB(232, 121, 200),
        stripe = Color3.fromRGB(255, 255, 255),
        stripeAlpha = 0.9,
        mark = Color3.fromRGB(226, 214, 255),
        markAlpha = 0.75,
    },
}

Theme.Metric = {
    WindowWidth = 1000,
    WindowHeight = 620,
    HeaderHeight = 52,
    ChipHeight = 26,
    RowHeight = 40,
    ControlHeight = 38,
    InputHeight = 40,
    Pad = 20,
    Gap = 12,
    CardRadius = 12,
    Scrollbar = 3,
    TouchTarget = 44,
    CloseButton = 38,
    Launcher = 52,
    IconButton = 30,
}

Theme.Layer = {
    Content = 1,
    Floating = 5,
    Header = 6,
    Backdrop = 10,
    Modal = 12,
    Popover = 16,
    Notification = 20,
    Tooltip = 24,
    Context = 28,
    Launcher = 32,
}

Theme.AccentStops = { Theme.Color.Magenta, Theme.Color.Accent }
Theme.AuroraStops = { Theme.Color.Magenta, Theme.Color.Peach, Theme.Color.Accent, Theme.Color.Magenta }

function Theme.Set(patch)
    if type(patch) ~= "table" then
        return
    end
    if type(patch.Color) == "table" then
        Util.merge(Theme.Color, patch.Color)
    end
    if type(patch.Radius) == "table" then
        Util.merge(Theme.Radius, patch.Radius)
    end
    if type(patch.Space) == "table" then
        Util.merge(Theme.Space, patch.Space)
    end
    if type(patch.Type) == "table" then
        Util.merge(Theme.Type, patch.Type)
    end
    if type(patch.Metric) == "table" then
        Util.merge(Theme.Metric, patch.Metric)
    end
    Theme.AccentStops = { Theme.Color.Magenta, Theme.Color.Accent }
    Theme.AuroraStops = { Theme.Color.Magenta, Theme.Color.Peach, Theme.Color.Accent, Theme.Color.Magenta }
    Theme.Art.accent.orb = Theme.Color.Accent
    Theme.Art.accent.orb2 = Theme.Color.Magenta
    Library:SetAccent(Theme.Color.Accent, true)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Motion — one deliberate family for the whole product.
-- ══════════════════════════════════════════════════════════════════════════════

Motion.Instant = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Motion.Micro = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Motion.Fast = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Motion.Normal = TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
Motion.Emphasized = TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
Motion.Exit = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
Motion.Drag = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Motion.Ambient = TweenInfo.new(22, Enum.EasingStyle.Linear)
Motion.Spin = TweenInfo.new(0.85, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)

Motion.Reduced = false

function Motion.SetReduced(value)
    Motion.Reduced = value == true
    if Motion.Reduced then
        Anim.FinishAll()
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Scope — owns every side effect. Nothing connects without a scope.
-- ══════════════════════════════════════════════════════════════════════════════

Scope.__index = Scope

function Scope.new(parent)
    return setmetatable({
        Alive = true,
        Connections = {},
        Tasks = {},
        Finalizers = {},
        Children = {},
        Parent = parent,
    }, Scope)
end

function Scope:Connect(signal, callback)
    if not self.Alive or not signal then
        return nil
    end
    local connection = signal:Connect(function(...)
        if self.Alive then
            callback(...)
        end
    end)
    self.Connections[connection] = true
    return connection
end

function Scope:Disconnect(connection)
    if connection then
        connection:Disconnect()
        self.Connections[connection] = nil
    end
end

function Scope:Later(seconds, callback)
    if not self.Alive then
        return nil
    end
    local thread
    thread = task.delay(seconds, function()
        self.Tasks[thread] = nil
        if self.Alive then
            callback()
        end
    end)
    self.Tasks[thread] = true
    return thread
end

function Scope:Run(callback)
    if not self.Alive then
        return nil
    end
    local thread
    thread = task.defer(function()
        if self.Alive then
            callback()
        end
        self.Tasks[thread] = nil
    end)
    self.Tasks[thread] = true
    return thread
end

function Scope:Cancel(thread)
    if thread and self.Tasks[thread] then
        self.Tasks[thread] = nil
        pcall(task.cancel, thread)
    end
end

function Scope:AddFinalizer(callback)
    if self.Alive and type(callback) == "function" then
        table.insert(self.Finalizers, callback)
    end
end

function Scope:Add(child)
    if self.Alive and child then
        table.insert(self.Children, child)
    end
    return child
end

function Scope:Destroy()
    if not self.Alive then
        return
    end
    self.Alive = false
    for connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    for thread in pairs(self.Tasks) do
        pcall(task.cancel, thread)
    end
    for index = #self.Children, 1, -1 do
        local child = self.Children[index]
        if type(child) == "table" and type(child.Destroy) == "function" then
            pcall(child.Destroy, child)
        end
    end
    for _, finalizer in ipairs(self.Finalizers) do
        pcall(finalizer)
    end
    Util.clear(self.Connections)
    Util.clear(self.Tasks)
    Util.clear(self.Children)
    Util.clear(self.Finalizers)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Anim — single tween entry. Cancels conflicting properties, never fights.
-- ══════════════════════════════════════════════════════════════════════════════

Anim.Records = {}
Anim.Ambient = {}

function Anim.Cancel(record)
    if not record or record.Cancelled then
        return
    end
    record.Cancelled = true
    if record.Connection then
        record.Connection:Disconnect()
        record.Connection = nil
    end
    if record.Tween then
        pcall(function()
            record.Tween:Cancel()
        end)
    end
    local map = Anim.Records[record.Object]
    if map then
        for key in pairs(record.Goals) do
            if map[key] == record then
                map[key] = nil
            end
        end
        if Util.count(map) == 0 then
            Anim.Records[record.Object] = nil
        end
    end
end

function Anim.CancelProperty(object, key)
    local map = Anim.Records[object]
    if map and map[key] then
        Anim.Cancel(map[key])
    end
end

function Anim.CancelTree(root)
    local seen = {}
    for object, map in pairs(Anim.Records) do
        local match = object == root
        if not match then
            local ok, descendant = pcall(function()
                return object:IsDescendantOf(root)
            end)
            match = ok and descendant
        end
        if match then
            for _, record in pairs(map) do
                seen[record] = true
            end
        end
    end
    for record in pairs(seen) do
        Anim.Cancel(record)
    end
end

-- Anim.To(object, goals, tweenInfo, onCompleted)
-- Only one tween per object+property may exist; new goals cancel the old record for those keys.
function Anim.To(object, goals, info, onCompleted, allowWhileLocked)
    if not object or not object.Parent then
        return nil
    end
    if Motion.Reduced and not allowWhileLocked then
        for key, value in pairs(goals) do
            object[key] = value
        end
        if onCompleted then
            local ok = Util.safeCall(onCompleted)
        end
        return nil
    end
    local map = Anim.Records[object]
    if map then
        for key in pairs(goals) do
            if map[key] then
                Anim.Cancel(map[key])
            end
        end
    end
    map = Anim.Records[object]
    if not map then
        map = {}
        Anim.Records[object] = map
    end
    local record = {
        Object = object,
        Goals = goals,
        Completed = onCompleted,
        Tween = TweenService:Create(object, info or Motion.Micro, goals),
    }
    for key in pairs(goals) do
        map[key] = record
    end
    record.Connection = record.Tween.Completed:Connect(function(state)
        if record.Cancelled then
            return
        end
        Anim.Cancel(record)
        if state == Enum.PlaybackState.Completed and record.Completed then
            Util.safeCall(record.Completed)
        end
    end)
    record.Tween:Play()
    return record
end

function Anim.Snap(object, props)
    for key, value in pairs(props) do
        Anim.CancelProperty(object, key)
        object[key] = value
    end
end

-- Ambient loops (aurora gradients, spinners) are owned, cancellable, and reduced-motion aware.
function Anim.Loop(object, goals, info, onCycle)
    if Motion.Reduced or not object or not object.Parent then
        return nil
    end
    local loopInfo = info or Motion.Ambient
    local record
    local function cycle()
        if not record or record.Cancelled or not object.Parent then
            return
        end
        record.Tween = TweenService:Create(object, loopInfo, goals)
        record.Connection = record.Tween.Completed:Connect(function()
            if record.Cancelled then
                return
            end
            if onCycle then
                Util.safeCall(onCycle)
            end
            cycle()
        end)
        record.Tween:Play()
    end
    record = { Object = object, Cancelled = false, Ambient = true }
    table.insert(Anim.Ambient, record)
    cycle()
    return record
end

function Anim.StopLoop(record)
    if not record or record.Cancelled then
        return
    end
    record.Cancelled = true
    if record.Connection then
        record.Connection:Disconnect()
    end
    if record.Tween then
        pcall(function()
            record.Tween:Cancel()
        end)
    end
    for index = #Anim.Ambient, 1, -1 do
        if Anim.Ambient[index] == record then
            table.remove(Anim.Ambient, index)
        end
    end
end

function Anim.FinishAll()
    local seen = {}
    for _, map in pairs(Anim.Records) do
        for _, record in pairs(map) do
            seen[record] = true
        end
    end
    for record in pairs(seen) do
        if not record.Cancelled and record.Object.Parent then
            Anim.Cancel(record)
            for key, value in pairs(record.Goals) do
                record.Object[key] = value
            end
            if record.Completed then
                Util.safeCall(record.Completed)
            end
        end
    end
end

function Anim.DestroyAll()
    local seen = {}
    for _, map in pairs(Anim.Records) do
        for _, record in pairs(map) do
            seen[record] = true
        end
    end
    for record in pairs(seen) do
        Anim.Cancel(record)
    end
    for index = #Anim.Ambient, 1, -1 do
        Anim.StopLoop(Anim.Ambient[index])
    end
    Util.clear(Anim.Records)
    Util.clear(Anim.Ambient)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Prim — the only place instances are constructed.
-- ══════════════════════════════════════════════════════════════════════════════

function Prim.new(className, properties, parent)
    local object = Instance.new(className)
    if properties then
        for key, value in pairs(properties) do
            object[key] = value
        end
    end
    object.Parent = parent
    return object
end

function Prim.corner(object, radius)
    return Prim.new("UICorner", { CornerRadius = UDim.new(0, radius or Theme.Radius.Medium) }, object)
end

function Prim.stroke(object, color, thickness, transparency)
    return Prim.new("UIStroke", {
        Color = color or Theme.Color.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, object)
end

function Prim.frame(parent, name, color)
    return Prim.new("Frame", {
        Name = name,
        BackgroundColor3 = color or Theme.Color.Surface,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
    }, parent)
end

function Prim.group(parent, name)
    return Prim.new("CanvasGroup", {
        Name = name,
        BackgroundColor3 = Theme.Color.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 0,
    }, parent)
end

function Prim.label(parent, name, text, size, color, font)
    local object = Prim.new("TextLabel", {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = text or "",
        TextSize = size or Theme.Type.Body,
        TextColor3 = color or Theme.Color.Text,
        Font = font or Theme.Font.Regular,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        RichText = false,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
    return object
end

function Prim.place(object, x, y, width, height)
    -- Layout owns geometry: cancel any in-flight tween on these properties first.
    Anim.CancelProperty(object, "Position")
    Anim.CancelProperty(object, "Size")
    object.Position = UDim2.fromOffset(x, y)
    object.Size = UDim2.fromOffset(width, height)
    return object
end

function Prim.gradient(object, stops, rotation, transparency)
    object.BackgroundColor3 = Color3.new(1, 1, 1)
    return Prim.new("UIGradient", {
        Color = Prim.sequence(stops),
        Rotation = rotation or 0,
        Transparency = transparency,
    }, object)
end

-- Accent gradients are registered so a runtime accent change recolors every surface.
Prim.Fills = {}

-- Roblox only accepts Color3 | Color3+Color3 | keypoint array, never a bare Color3 array.
function Prim.sequence(stops)
    local points = {}
    local count = #stops
    if count == 0 then
        return ColorSequence.new(Theme.Color.White)
    end
    for index = 1, count do
        points[index] = ColorSequenceKeypoint.new((index - 1) / math.max(1, count - 1), stops[index])
    end
    return ColorSequence.new(points)
end

function Prim.TrackFill(gradient, kind)
    Prim.Fills[gradient] = kind
    return gradient
end

function Prim.RefreshFills()
    for gradient, kind in pairs(Prim.Fills) do
        if gradient.Parent then
            gradient.Color = Prim.sequence(kind == "aurora" and Theme.AuroraStops or Theme.AccentStops)
        else
            Prim.Fills[gradient] = nil
        end
    end
end

-- A horizontal accent gradient (magenta -> violet) used for selected/emphasis surfaces.
function Prim.accentFill(object, rotation)
    return Prim.TrackFill(Prim.gradient(object, Theme.AccentStops, rotation or 0), "accent")
end

-- Aurora surfaces slowly drift through the accent family (reduced-motion safe).
function Prim.aurora(object, scope, rotation)
    local gradient = Prim.gradient(object, Theme.AuroraStops, rotation or 0, NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.06),
        NumberSequenceKeypoint.new(1, 0),
    }))
    Prim.TrackFill(gradient, "aurora")
    if scope then
        local record = Anim.Loop(gradient, { Offset = Vector2.new(1, 0) }, Motion.Ambient, function()
            gradient.Offset = Vector2.new(-1, 0)
        end)
        scope:AddFinalizer(function()
            Anim.StopLoop(record)
            Prim.Fills[gradient] = nil
        end)
    end
    return gradient
end

function Prim.scroller(parent, name)
    local object = Prim.new("ScrollingFrame", {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = Theme.Metric.Scrollbar,
        ScrollBarImageColor3 = Theme.Color.AccentDeep,
        ScrollBarImageTransparency = 0.35,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollingEnabled = true,
        VerticalScrollBarInset = Enum.ScrollBarInset.None,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
        ClipsDescendants = true,
    }, parent)
    return object
end

function Prim.scaleConstraint(object, minimum, maximum)
    local constraint = Prim.new("UISizeConstraint", {
        MinSize = Vector2.new(minimum or 0, minimum or 0),
        MaxSize = Vector2.new(maximum or 1e6, maximum or 1e6),
    }, object)
    return constraint
end

function Prim.aspect(object, ratio)
    return Prim.new("UIAspectRatioConstraint", { AspectRatio = ratio }, object)
end

-- Pixel-perfect hairline: a 1px frame in token stroke color.
function Prim.hairline(parent, color, transparency)
    local line = Prim.frame(parent, "Hairline", color or Theme.Color.Stroke)
    line.BackgroundTransparency = transparency or 0.35
    return line
end

Prim.Icon = {}

local ICON_PATHS = {
    home = { { 3, 9 }, { 10, 3 }, { 17, 9 }, { 17, 17 }, { 3, 17 }, { 3, 9 } },
    grid = { { 3, 3 }, { 8, 3 }, { 8, 8 }, { 3, 8 }, { 3, 3 } },
    grid2 = { { 12, 3 }, { 17, 3 }, { 17, 8 }, { 12, 8 }, { 12, 3 } },
    grid3 = { { 3, 12 }, { 8, 12 }, { 8, 17 }, { 3, 17 }, { 3, 12 } },
    grid4 = { { 12, 12 }, { 17, 12 }, { 17, 17 }, { 12, 17 }, { 12, 12 } },
    layers = { { 10, 2 }, { 17, 6 }, { 10, 10 }, { 3, 6 }, { 10, 2 } },
    settings = { { 3, 8 }, { 17, 8 } },
    sliders = { { 3, 6 }, { 17, 6 } },
    bolt = { { 11, 2 }, { 5, 11 }, { 9, 11 }, { 8, 18 }, { 15, 9 }, { 11, 9 }, { 11, 2 } },
    check = { { 4, 10 }, { 8, 14 }, { 16, 6 } },
    chevron = { { 6, 8 }, { 10, 12 }, { 14, 8 } },
    arrow = { { 4, 10 }, { 15, 10 } },
    arrowLeft = { { 16, 10 }, { 5, 10 } },
    plus = { { 10, 4 }, { 10, 16 } },
    close = { { 5, 5 }, { 15, 15 } },
    minus = { { 5, 10 }, { 15, 10 } },
    square = { { 5, 5 }, { 15, 5 }, { 15, 15 }, { 5, 15 }, { 5, 5 } },
    lock = { { 5, 9 }, { 15, 9 }, { 15, 16 }, { 5, 16 }, { 5, 9 } },
    mail = { { 3, 6 }, { 17, 6 }, { 17, 14 }, { 3, 14 }, { 3, 6 } },
    shield = { { 10, 2 }, { 16, 5 }, { 16, 11 }, { 10, 18 }, { 4, 11 }, { 4, 5 }, { 10, 2 } },
    warning = { { 10, 3 }, { 18, 17 }, { 2, 17 }, { 10, 3 } },
    info = { { 10, 3 }, { 10, 17 } },
    star = { { 10, 3 }, { 12, 8 }, { 17, 8 }, { 13, 12 }, { 15, 17 }, { 10, 14 }, { 5, 17 }, { 7, 12 }, { 3, 8 }, { 8, 8 }, { 10, 3 } },
    play = { { 6, 4 }, { 16, 10 }, { 6, 16 }, { 6, 4 } },
    pause = { { 6, 4 }, { 6, 16 } },
    eye = { { 3, 10 }, { 6, 6 }, { 10, 4 }, { 14, 6 }, { 17, 10 }, { 14, 14 }, { 10, 16 }, { 6, 14 }, { 3, 10 } },
    eyeOff = { { 3, 10 }, { 6, 6 }, { 10, 4 }, { 14, 6 }, { 17, 10 }, { 14, 14 }, { 10, 16 }, { 6, 14 }, { 3, 10 } },
    key = { { 4, 12 }, { 9, 7 }, { 14, 7 }, { 17, 10 }, { 14, 13 }, { 11, 13 }, { 9, 11 } },
    user = { { 6, 6 }, { 6, 6 } },
    users = { { 6, 6 }, { 6, 6 } },
    monitor = { { 3, 5 }, { 17, 5 }, { 17, 14 }, { 3, 14 }, { 3, 5 } },
    phone = { { 7, 3 }, { 13, 3 }, { 13, 17 }, { 7, 17 }, { 7, 3 } },
    download = { { 10, 3 }, { 10, 14 } },
    globe = { { 10, 3 }, { 10, 17 } },
    cart = { { 4, 6 }, { 16, 6 }, { 14, 16 }, { 6, 16 }, { 4, 6 } },
    tag = { { 4, 8 }, { 10, 4 }, { 16, 8 }, { 16, 14 }, { 4, 14 }, { 4, 8 } },
    bookmark = { { 6, 4 }, { 14, 4 }, { 14, 17 }, { 10, 13 }, { 6, 17 }, { 6, 4 } },
    refresh = { { 16, 7 }, { 13, 3 }, { 7, 3 }, { 4, 7 }, { 4, 11 } },
    search = { { 4, 9 }, { 8, 5 }, { 13, 5 }, { 16, 9 }, { 13, 13 }, { 8, 13 }, { 4, 9 } },
    copy = { { 7, 4 }, { 15, 4 }, { 15, 12 }, { 7, 12 }, { 7, 4 } },
    trash = { { 5, 6 }, { 15, 6 }, { 14, 17 }, { 6, 17 }, { 5, 6 } },
    rocket = { { 10, 3 }, { 15, 9 }, { 13, 16 }, { 7, 16 }, { 5, 9 }, { 10, 3 } },
    spark = { { 10, 2 }, { 12, 8 }, { 18, 10 }, { 12, 12 }, { 10, 18 }, { 8, 12 }, { 2, 10 }, { 8, 8 }, { 10, 2 } },
    crown = { { 4, 14 }, { 5, 6 }, { 9, 11 }, { 11, 11 }, { 15, 6 }, { 16, 14 }, { 4, 14 } },
    dot = { { 10, 10 } },
}

local CIRCLE_ICONS = {
    eye = true,
    eyeOff = true,
    info = true,
    dot = true,
    refresh = true,
    globe = true,
    shield = true,
    user = true,
    users = true,
    lock = true,
    copy = true,
    search = true,
    monitor = true,
    phone = true,
}

-- Icons are native geometry (frames), so they never wait on assets and always match the theme.
function Prim.Icon.new(parent, name, color, size, thickness)
    local root = Prim.frame(parent, "Icon_" .. tostring(name), color or Theme.Color.TextSecondary)
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromOffset(size or 18, size or 18)
    local parts = {}
    local unit = (size or 18) / 20
    local strokeWidth = thickness or math.max(1, math.floor(unit * 1.7))

    local function segment(x1, y1, x2, y2, width)
        local dx, dy = x2 - x1, y2 - y1
        local length = math.sqrt(dx * dx + dy * dy)
        if length < 0.001 then
            return nil
        end
        local piece = Prim.frame(root, "Seg", color or Theme.Color.TextSecondary)
        piece.AnchorPoint = Vector2.new(0.5, 0.5)
        piece.Position = UDim2.fromOffset(((x1 + x2) / 2) * unit, ((y1 + y2) / 2) * unit)
        piece.Size = UDim2.fromOffset(length * unit, width or strokeWidth)
        piece.Rotation = math.deg(math.atan2(dy, dx))
        Prim.corner(piece, 100)
        parts[#parts + 1] = piece
        return piece
    end

    local path = ICON_PATHS[name]
    if name == "grid" then
        path = nil
        segment(3, 3, 8, 3)
        segment(8, 3, 8, 8)
        segment(8, 8, 3, 8)
        segment(3, 8, 3, 3)
        segment(12, 3, 17, 3)
        segment(17, 3, 17, 8)
        segment(17, 8, 12, 8)
        segment(12, 8, 12, 3)
        segment(3, 12, 8, 12)
        segment(8, 12, 8, 17)
        segment(8, 17, 3, 17)
        segment(3, 17, 3, 12)
        segment(12, 12, 17, 12)
        segment(17, 12, 17, 17)
        segment(17, 17, 12, 17)
        segment(12, 17, 12, 12)
    elseif name == "close" or name == "plus" or name == "minus" then
        path = nil
        if name == "close" then
            segment(5, 5, 15, 15)
            segment(15, 5, 5, 15)
        else
            segment(5, 10, 15, 10)
            if name == "plus" then
                segment(10, 5, 10, 15)
            end
        end
    elseif name == "settings" then
        path = nil
        segment(3, 8, 17, 8)
        segment(3, 13, 17, 13)
    elseif name == "sliders" then
        path = nil
        segment(3, 7, 17, 7)
        segment(3, 13, 17, 13)
    elseif name == "mail" then
        path = nil
        segment(3, 6, 17, 6)
        segment(17, 6, 17, 14)
        segment(17, 14, 3, 14)
        segment(3, 14, 3, 6)
        segment(3, 6, 10, 11)
        segment(10, 11, 17, 6)
    elseif name == "lock" then
        path = nil
        segment(5, 9, 15, 9)
        segment(15, 9, 15, 16)
        segment(15, 16, 5, 16)
        segment(5, 16, 5, 9)
        segment(7, 9, 7, 6)
        segment(13, 9, 13, 6)
        segment(7, 6, 13, 6)
    elseif name == "shield" then
        path = nil
        segment(10, 2, 16, 5)
        segment(16, 5, 16, 11)
        segment(16, 11, 10, 18)
        segment(10, 18, 4, 11)
        segment(4, 11, 4, 5)
        segment(4, 5, 10, 2)
    elseif name == "warning" then
        path = nil
        segment(10, 3, 18, 17)
        segment(18, 17, 2, 17)
        segment(2, 17, 10, 3)
        segment(10, 9, 10, 13)
    elseif name == "check" then
        segment(4, 10, 8, 14)
        segment(8, 14, 16, 6)
    elseif name == "chevron" then
        segment(6, 8, 10, 12)
        segment(10, 12, 14, 8)
    elseif name == "arrow" then
        segment(4, 10, 15, 10)
        segment(11, 6, 15, 10)
        segment(15, 10, 11, 14)
    elseif name == "arrowLeft" then
        segment(16, 10, 5, 10)
        segment(9, 6, 5, 10)
        segment(5, 10, 9, 14)
    elseif name == "play" then
        segment(6, 4, 16, 10)
        segment(16, 10, 6, 16)
    elseif name == "pause" then
        path = nil
        segment(7, 4, 7, 16, math.max(2, strokeWidth + 1))
        segment(13, 4, 13, 16, math.max(2, strokeWidth + 1))
    elseif name == "download" then
        path = nil
        segment(10, 3, 10, 14)
        segment(6, 10, 10, 14)
        segment(14, 10, 10, 14)
        segment(4, 17, 16, 17)
    elseif name == "cart" then
        path = nil
        segment(4, 6, 16, 6)
        segment(16, 6, 14, 16)
        segment(14, 16, 6, 16)
        segment(6, 16, 4, 6)
    elseif name == "tag" then
        path = nil
        segment(4, 8, 10, 4)
        segment(10, 4, 16, 8)
        segment(16, 8, 16, 14)
        segment(16, 14, 4, 14)
        segment(4, 14, 4, 8)
    elseif name == "bookmark" then
        path = nil
        segment(6, 4, 14, 4)
        segment(14, 4, 14, 17)
        segment(14, 17, 10, 13)
        segment(10, 13, 6, 17)
        segment(6, 17, 6, 4)
    elseif name == "refresh" then
        path = nil
        segment(16, 7, 13, 3)
        segment(13, 3, 7, 3)
        segment(7, 3, 4, 7)
        segment(4, 11, 4, 7)
        segment(4, 13, 7, 17)
        segment(7, 17, 13, 17)
        segment(13, 17, 16, 13)
    elseif name == "search" then
        path = nil
        segment(4, 9, 8, 5)
        segment(8, 5, 12, 5)
        segment(12, 5, 16, 9)
        segment(16, 9, 16, 12)
        segment(16, 12, 12, 16)
        segment(12, 16, 8, 16)
        segment(8, 16, 4, 12)
        segment(4, 12, 4, 9)
        segment(15, 15, 18, 18)
    elseif name == "monitor" then
        path = nil
        segment(3, 5, 17, 5)
        segment(17, 5, 17, 13)
        segment(17, 13, 3, 13)
        segment(3, 13, 3, 5)
        segment(10, 13, 10, 17)
        segment(7, 17, 13, 17)
    elseif name == "phone" then
        path = nil
        segment(7, 3, 13, 3)
        segment(13, 3, 13, 17)
        segment(13, 17, 7, 17)
        segment(7, 17, 7, 3)
        segment(9, 15, 11, 15)
    elseif name == "layers" then
        segment(10, 2, 17, 6)
        segment(17, 6, 10, 10)
        segment(10, 10, 3, 6)
        segment(3, 6, 10, 2)
        segment(3, 11, 10, 15)
        segment(10, 15, 17, 11)
    elseif name == "bolt" then
        segment(11, 2, 6, 11)
        segment(6, 11, 9, 11)
        segment(9, 11, 8, 18)
        segment(8, 18, 15, 9)
        segment(15, 9, 11, 9)
        segment(11, 9, 11, 2)
    elseif name == "rocket" then
        segment(10, 3, 15, 9)
        segment(15, 9, 13, 16)
        segment(13, 16, 7, 16)
        segment(7, 16, 5, 9)
        segment(5, 9, 10, 3)
        segment(8, 13, 12, 13)
    elseif name == "crown" then
        segment(4, 14, 5, 6)
        segment(5, 6, 9, 11)
        segment(9, 11, 11, 11)
        segment(11, 11, 15, 6)
        segment(15, 6, 16, 14)
        segment(16, 14, 4, 14)
    elseif name == "spark" or name == "star" then
        segment(10, 2, 12, 8)
        segment(12, 8, 18, 10)
        segment(18, 10, 12, 12)
        segment(12, 12, 10, 18)
        segment(10, 18, 8, 12)
        segment(8, 12, 2, 10)
        segment(2, 10, 8, 8)
        segment(8, 8, 10, 2)
    elseif name == "trash" then
        path = nil
        segment(5, 6, 15, 6)
        segment(6, 6, 7, 17)
        segment(7, 17, 13, 17)
        segment(13, 17, 14, 6)
        segment(8, 4, 12, 4)
    elseif name == "key" then
        path = nil
        segment(4, 12, 8, 8)
        segment(8, 8, 11, 8)
        segment(11, 8, 13, 10)
        segment(13, 10, 15, 8)
        segment(14, 11, 16, 13)
    elseif name == "dot" then
        path = nil
        local dot = Prim.frame(root, "Dot", color or Theme.Color.Text)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.fromOffset(10 * unit, 10 * unit)
        dot.Size = UDim2.fromOffset(3 * unit, 3 * unit)
        Prim.corner(dot, 100)
        parts[#parts + 1] = dot
    elseif name == "eye" or name == "eyeOff" then
        path = nil
        segment(3, 10, 6, 6)
        segment(6, 6, 10, 4)
        segment(10, 4, 14, 6)
        segment(14, 6, 17, 10)
        segment(17, 10, 14, 14)
        segment(14, 14, 10, 16)
        segment(10, 16, 6, 14)
        segment(6, 14, 3, 10)
        if name == "eyeOff" then
            segment(4, 4, 16, 16)
        end
    elseif name == "info" then
        path = nil
        segment(10, 9, 10, 15)
    elseif name == "globe" then
        path = nil
        segment(10, 3, 10, 17)
        segment(3, 10, 17, 10)
    elseif name == "user" then
        path = nil
        segment(6, 5, 9, 3)
        segment(9, 3, 13, 5)
        segment(13, 5, 12, 9)
        segment(12, 9, 8, 10)
        segment(8, 10, 6, 7)
        segment(6, 7, 6, 5)
        segment(4, 17, 5, 13)
        segment(5, 13, 9, 12)
        segment(9, 12, 14, 14)
        segment(14, 14, 16, 17)
    elseif name == "users" then
        path = nil
        segment(5, 5, 7, 4)
        segment(7, 4, 9, 6)
        segment(9, 6, 7, 8)
        segment(7, 8, 5, 6)
        segment(3, 17, 4, 13)
        segment(4, 13, 9, 12)
        segment(9, 12, 12, 14)
        segment(13, 6, 15, 5)
        segment(15, 5, 17, 7)
        segment(17, 7, 15, 9)
        segment(11, 16, 12, 13)
        segment(12, 13, 15, 12)
        segment(15, 12, 18, 14)
    elseif name == "copy" then
        path = nil
        segment(7, 4, 15, 4)
        segment(15, 4, 15, 12)
        segment(15, 12, 7, 12)
        segment(7, 12, 7, 4)
        segment(5, 7, 5, 16)
        segment(5, 16, 13, 16)
    elseif name == "square" then
        path = nil
        segment(5, 5, 15, 5)
        segment(15, 5, 15, 15)
        segment(15, 15, 5, 15)
        segment(5, 15, 5, 5)
    end

    if path then
        for index = 1, #path - 1 do
            local a, b = path[index], path[index + 1]
            segment(a[1], a[2], b[1], b[2])
        end
    end

    if CIRCLE_ICONS[name] and name ~= "dot" and name ~= "square" then
        local ring = Prim.frame(root, "Ring", color or Theme.Color.TextSecondary)
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.fromOffset(10 * unit, 10 * unit)
        ring.Size = UDim2.fromOffset(13 * unit, 13 * unit)
        ring.BackgroundTransparency = 1
        Prim.corner(ring, 100)
        Prim.stroke(ring, color or Theme.Color.TextSecondary, strokeWidth)
        parts[#parts + 1] = ring
    end

    local icon = { Root = root, Parts = parts }
    function icon:SetColor(value)
        for _, part in ipairs(parts) do
            if part:IsA("UIStroke") then
                part.Color = value
            else
                part.BackgroundColor3 = value
            end
        end
    end
    function icon:SetTransparency(value)
        for _, part in ipairs(parts) do
            if part:IsA("UIStroke") then
                part.Transparency = value
            else
                part.BackgroundTransparency = value
            end
        end
    end
    function icon:Destroy()
        root:Destroy()
    end
    return icon
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Layers — one owner per floating surface, deliberate ZIndex ladder.
-- ══════════════════════════════════════════════════════════════════════════════

Layers.Root = nil
Layers.Overlay = nil
Layers.Backdrop = nil
Layers.ModalHost = nil
Layers.NotifyHost = nil
Layers.TooltipHost = nil
Layers.ContextHost = nil
Layers.Floating = nil
Layers.Scope = nil

function Layers.Mount(root, scope)
    Layers.Root = root
    Layers.Scope = scope
    Layers.Overlay = Prim.new("Frame", {
        Name = "Overlay",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = Theme.Layer.Backdrop,
        Visible = false,
    }, root)
    Layers.Backdrop = Prim.new("TextButton", {
        Name = "Backdrop",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.Shadow,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = Theme.Layer.Backdrop,
        Active = false,
        Selectable = false,
    }, Layers.Overlay)
    Layers.ModalHost = Prim.new("Frame", {
        Name = "ModalHost",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = Theme.Layer.Modal,
    }, Layers.Overlay)
    Layers.Floating = Prim.new("Frame", {
        Name = "Floating",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = Theme.Layer.Floating,
    }, root)
    Layers.NotifyHost = Prim.new("Frame", {
        Name = "NotifyHost",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = Theme.Layer.Notification,
    }, root)
    Layers.TooltipHost = Prim.new("Frame", {
        Name = "TooltipHost",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = Theme.Layer.Tooltip,
    }, root)
    Layers.ContextHost = Prim.new("Frame", {
        Name = "ContextHost",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = Theme.Layer.Context,
    }, root)
end

function Layers.ShowBackdrop(visible, animate, onDismiss, scope)
    if not Layers.Overlay then
        return
    end
    Layers.Backdrop.Active = visible == true
    if visible then
        Layers.Overlay.Visible = true
        if Motion.Reduced then
            Layers.Backdrop.BackgroundTransparency = 0.55
        else
            Anim.To(Layers.Backdrop, { BackgroundTransparency = 0.55 }, Motion.Normal, nil, true)
        end
    else
        Layers.Overlay.Visible = false
        Layers.Backdrop.BackgroundTransparency = 1
    end
    if onDismiss and scope then
        if Layers.DismissConnection then
            Layers.DismissConnection:Disconnect()
            Layers.DismissConnection = nil
        end
        Layers.DismissConnection = scope:Connect(Layers.Backdrop.Activated, onDismiss)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Notify — one queue, bounded stack, reflowing, self-cleaning.
-- ══════════════════════════════════════════════════════════════════════════════

local Notify = {
    Items = {},
    Queue = {},
    Limit = 4,
    MaxQueue = 24,
    LastMessage = nil,
    LastAt = 0,
}
Library.__internal = Library.__internal or {}
Library.__internal.Notify = Notify

local NOTIFY_STYLE = {
    info = { accent = Theme.Color.Accent, icon = "info" },
    success = { accent = Theme.Color.Success, icon = "check" },
    warning = { accent = Theme.Color.Warning, icon = "warning" },
    error = { accent = Theme.Color.Danger, icon = "warning" },
    neutral = { accent = Theme.Color.TextMuted, icon = "dot" },
}

function Notify.Layout()
    if not Layers.NotifyHost then
        return
    end
    local host = Layers.Root and Layers.Root.AbsoluteSize or Vector2.new(1280, 720)
    local width = math.min(352, math.max(200, host.X - 32))
    local y = 16
    for _, item in ipairs(Notify.Items) do
        if item.Root and item.Root.Parent then
            item.Root.Size = UDim2.fromOffset(width, item.Height)
            Anim.To(item.Root, { Position = UDim2.fromOffset(host.X - width - 16, y) }, Motion.Normal)
            y = y + item.Height + 8
        end
    end
    if y > host.Y - 16 and #Notify.Items > 1 then
        Notify.Close(Notify.Items[1], true)
    end
end

function Notify.Close(item, immediate)
    if not item or item.Removed or (item.Closing and not immediate) then
        return
    end
    item.Closing = true
    item.Scope:Cancel(item.Timer)
    local function remove()
        if item.Removed then
            return
        end
        item.Removed = true
        for index, value in ipairs(Notify.Items) do
            if value == item then
                table.remove(Notify.Items, index)
                break
            end
        end
        item.Scope:Destroy()
        Anim.CancelTree(item.Root)
        if item.Root.Parent then
            item.Root:Destroy()
        end
        Notify.Layout()
        Notify.Drain()
    end
    if immediate or Motion.Reduced or not item.Root.Parent then
        remove()
    else
        -- Fade the body (fade-owned) and slide the root (layout-owned) separately.
        Anim.To(item.Body, { GroupTransparency = 1 }, Motion.Exit, remove)
        Anim.To(item.Root, { Position = item.Root.Position + UDim2.fromOffset(24, 0) }, Motion.Exit)
    end
end

function Notify.Create(config)
    local style = NOTIFY_STYLE[config.Type] or NOTIFY_STYLE.info
    local item = { Scope = Scope.new() }
    local width = 352
    local titleText = Util.text(config.Title or "", 80)
    local bodyText = Util.text(config.Text or config.Subtitle or "", 180)
    local titleHeight = titleText ~= "" and math.max(17, Util.measureHeight(titleText, Theme.Type.Body, Theme.Font.Bold, width - 76)) or 0
    local bodyHeight = bodyText ~= "" and math.max(15, Util.measureHeight(bodyText, Theme.Type.Small, Theme.Font.Regular, width - 76)) or 0
    item.Height = math.max(56, 16 + titleHeight + (bodyText ~= "" and (bodyHeight + 4) or 0) + 16)

    item.Root = Prim.frame(Layers.NotifyHost, "Notification", Theme.Color.SurfaceRaised)
    item.Root.Size = UDim2.fromOffset(width, item.Height)
    Prim.corner(item.Root, Theme.Radius.Medium)
    Prim.stroke(item.Root, Theme.Color.Stroke, 1, 0.15)
    item.Body = Prim.group(item.Root, "Body")
    item.Body.BackgroundTransparency = 1
    item.Body.GroupTransparency = Motion.Reduced and 0 or 1
    item.Body.Size = UDim2.fromScale(1, 1)
    local rail = Prim.frame(item.Body, "Rail", style.accent)
    Prim.place(rail, 0, 12, 3, item.Height - 24)
    Prim.corner(rail, 2)

    local icon = Prim.Icon.new(item.Body, config.Icon or style.icon, style.accent, 16, 1.6)
    Prim.place(icon.Root, 16, 16, 16, 16)

    local textX = 42
    if titleText ~= "" then
        local title = Prim.label(item.Body, "Title", titleText, Theme.Type.Body, Theme.Color.Text, Theme.Font.Bold)
        title.TextWrapped = true
        title.TextYAlignment = Enum.TextYAlignment.Top
        title.TextTruncate = Enum.TextTruncate.AtEnd
        Prim.place(title, textX, 14, width - textX - 16, titleHeight + 2)
    end
    if bodyText ~= "" then
        local body = Prim.label(item.Body, "Body", bodyText, Theme.Type.Small, Theme.Color.TextSecondary)
        body.TextWrapped = true
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.TextTruncate = Enum.TextTruncate.AtEnd
        Prim.place(body, textX, 14 + titleHeight + 3, width - textX - 16, bodyHeight + 2)
    end

    if config.Dismissible ~= false then
        local close = Prim.new("TextButton", {
            Name = "Dismiss",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(Theme.Metric.CloseButton, Theme.Metric.CloseButton),
            Position = UDim2.fromOffset(width - Theme.Metric.CloseButton - 2, 6),
            ZIndex = 2,
        }, item.Body)
        local closeIcon = Prim.Icon.new(close, "close", Theme.Color.TextMuted, 12, 1.5)
        closeIcon.Root.AnchorPoint = Vector2.new(0.5, 0.5)
        closeIcon.Root.Position = UDim2.fromScale(0.5, 0.5)
        item.Scope:Connect(close.MouseEnter, function()
            closeIcon:SetColor(Theme.Color.Text)
        end)
        item.Scope:Connect(close.MouseLeave, function()
            closeIcon:SetColor(Theme.Color.TextMuted)
        end)
        item.Scope:Connect(close.Activated, function()
            Notify.Close(item)
        end)
    end

    local host = Layers.Root and Layers.Root.AbsoluteSize or Vector2.new(1280, 720)
    item.Root.Position = UDim2.fromOffset(host.X - width - 16 + 24, 16)
    table.insert(Notify.Items, item)
    Notify.Layout()
    Anim.To(item.Body, { GroupTransparency = 0 }, Motion.Normal)
    Anim.To(item.Root, { Position = UDim2.fromOffset(host.X - width - 16, 16) }, Motion.Normal)
    item.Timer = item.Scope:Later(Util.clamp(Util.finite(config.Duration, 4), 0.5, 30), function()
        Notify.Close(item)
    end)
    return item
end

function Notify.Drain()
    if not Layers.NotifyHost then
        return
    end
    local host = Layers.Root and Layers.Root.AbsoluteSize or Vector2.new(1280, 720)
    Notify.Limit = Util.clamp(math.floor(host.Y / 120), 1, 4)
    while #Notify.Items < Notify.Limit and #Notify.Queue > 0 do
        Notify.Create(table.remove(Notify.Queue, 1))
    end
end

function Notify.Push(config)
    if type(config) ~= "table" then
        config = { Text = tostring(config or "") }
    end
    local signature = tostring(config.Title or "") .. "|" .. tostring(config.Text or config.Subtitle or "")
    local now = os.clock()
    if Notify.LastMessage == signature and (now - Notify.LastAt) < 0.8 then
        return nil
    end
    Notify.LastMessage = signature
    Notify.LastAt = now
    if #Notify.Queue >= Notify.MaxQueue then
        table.remove(Notify.Queue, 1)
    end
    table.insert(Notify.Queue, config)
    Notify.Drain()
    return true
end

function Notify.Clear()
    Util.clear(Notify.Queue)
    for index = #Notify.Items, 1, -1 do
        Notify.Close(Notify.Items[index], true)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Tooltip — one instance, hover + touch-hold, viewport clamped.
-- ══════════════════════════════════════════════════════════════════════════════

local Tooltip = { Current = nil, Scope = Scope.new() }

function Tooltip.Hide()
    if not Tooltip.Current then
        return
    end
    local item = Tooltip.Current
    Tooltip.Current = nil
    item.Scope:Destroy()
    if item.Root.Parent then
        Anim.CancelTree(item.Root)
        item.Root:Destroy()
    end
end

function Tooltip.Show(anchor, text)
    if not Layers.TooltipHost or not text or text == "" then
        return
    end
    if Tooltip.Current and Tooltip.Current.Anchor == anchor then
        return
    end
    Tooltip.Hide()
    local item = { Scope = Scope.new(), Anchor = anchor }
    local maxWidth = 240
    local width = math.min(maxWidth, math.max(60, Util.measureWidth(text, Theme.Type.Small, Theme.Font.Regular) + 20))
    local height = math.max(26, Util.measureHeight(text, Theme.Type.Small, Theme.Font.Regular, width - 16) + 12)
    item.Root = Prim.group(Layers.TooltipHost, "Tooltip")
    item.Root.BackgroundColor3 = Theme.Color.SurfaceInteractive
    item.Root.GroupTransparency = 1
    item.Root.Size = UDim2.fromOffset(width, height)
    item.Root.Active = false
    Prim.corner(item.Root, Theme.Radius.Small)
    Prim.stroke(item.Root, Theme.Color.StrokeStrong, 1, 0.25)
    local label = Prim.label(item.Root, "Text", text, Theme.Type.Small, Theme.Color.Text)
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    Prim.place(label, 8, 0, width - 16, height)

    local host = Layers.Root.AbsoluteSize
    local position = anchor.AbsolutePosition
    local size = anchor.AbsoluteSize
    local x = Util.clamp(position.X + size.X / 2 - width / 2, 8, math.max(8, host.X - width - 8))
    local y = position.Y - height - 8
    if y < 8 then
        y = position.Y + size.Y + 8
    end
    item.Root.Position = UDim2.fromOffset(x, y + 6)
    Tooltip.Current = item
    Anim.To(item.Root, { GroupTransparency = 0, Position = UDim2.fromOffset(x, y) }, Motion.Micro, nil, true)
    return item
end

function Tooltip.Attach(scope, anchor, text)
    if not text or text == "" then
        return
    end
    scope:Connect(anchor.MouseEnter, function()
        if Motion.Reduced then
            return
        end
        scope:Cancel(scope.TooltipThread)
        scope.TooltipThread = scope:Later(0.35, function()
            Tooltip.Show(anchor, text)
        end)
    end)
    scope:Connect(anchor.MouseLeave, function()
        scope:Cancel(scope.TooltipThread)
        if Tooltip.Current and Tooltip.Current.Anchor == anchor then
            Tooltip.Hide()
        end
    end)
    scope:Connect(anchor.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            scope:Cancel(scope.TooltipThread)
            scope.TooltipThread = scope:Later(0.5, function()
                Tooltip.Show(anchor, text)
            end)
        end
    end)
    scope:Connect(anchor.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            scope:Cancel(scope.TooltipThread)
            if Tooltip.Current and Tooltip.Current.Anchor == anchor then
                Tooltip.Hide()
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- ContextMenu — right click / long press action layer.
-- ══════════════════════════════════════════════════════════════════════════════

local Context = { Current = nil }

function Context.Close()
    if not Context.Current then
        return
    end
    local menu = Context.Current
    Context.Current = nil
    menu.Scope:Destroy()
    if menu.Root.Parent then
        Anim.CancelTree(menu.Root)
        menu.Root:Destroy()
    end
end

function Context.Open(items, position)
    if not Layers.ContextHost or type(items) ~= "table" or #items == 0 then
        return
    end
    Context.Close()
    local menu = { Scope = Scope.new() }
    local width = 180
    local rowHeight = 32
    local height = #items * rowHeight + 10
    menu.Root = Prim.group(Layers.ContextHost, "ContextMenu")
    menu.Root.BackgroundColor3 = Theme.Color.SurfaceRaised
    menu.Root.GroupTransparency = 1
    menu.Root.Size = UDim2.fromOffset(width, height)
    menu.Root.Active = true
    Prim.corner(menu.Root, Theme.Radius.Medium)
    Prim.stroke(menu.Root, Theme.Color.StrokeStrong, 1, 0.2)
    local host = Layers.Root.AbsoluteSize
    local x = Util.clamp(position.X, 8, math.max(8, host.X - width - 8))
    local y = Util.clamp(position.Y, 8, math.max(8, host.Y - height - 8))
    menu.Root.Position = UDim2.fromOffset(x, y + 6)
    for index, entry in ipairs(items) do
        if entry.Separator then
            local line = Prim.hairline(menu.Root, Theme.Color.Stroke, 0.3)
            Prim.place(line, 8, (index - 1) * rowHeight + 5, width - 16, 1)
        else
            local row = Prim.new("TextButton", {
                Name = "Item",
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(width - 8, rowHeight - 2),
                Position = UDim2.fromOffset(4, (index - 1) * rowHeight + 5),
                Active = entry.Disabled ~= true,
                Selectable = entry.Disabled ~= true,
            }, menu.Root)
            Prim.corner(row, Theme.Radius.Small)
            local color = entry.Disabled and Theme.Color.TextMuted or (entry.Danger and Theme.Color.Danger or Theme.Color.Text)
            local label = Prim.label(row, "Label", Util.text(entry.Text, 34), Theme.Type.Small, color)
            Prim.place(label, 10, 0, width - 40, rowHeight - 2)
            local shortcut = entry.Shortcut
            if shortcut then
                local hint = Prim.label(row, "Shortcut", shortcut, Theme.Type.Micro, Theme.Color.TextMuted)
                hint.TextXAlignment = Enum.TextXAlignment.Right
                Prim.place(hint, width - 56, 0, 44, rowHeight - 2)
            end
            if not entry.Disabled then
                menu.Scope:Connect(row.MouseEnter, function()
                    Anim.To(row, { BackgroundColor3 = Theme.Color.SurfaceInteractive }, Motion.Micro)
                end)
                menu.Scope:Connect(row.MouseLeave, function()
                    Anim.To(row, { BackgroundColor3 = Theme.Color.SurfaceRaised }, Motion.Micro)
                end)
                menu.Scope:Connect(row.Activated, function()
                    Context.Close()
                    Util.guard(entry.Callback)
                end)
            end
        end
    end
    Context.Current = menu
    Anim.To(menu.Root, { GroupTransparency = 0, Position = UDim2.fromOffset(x, y) }, Motion.Normal, nil, true)
end


-- ══════════════════════════════════════════════════════════════════════════════
-- Components — shared anatomy. Every control is a table with:
--   Root, Scope, Apply(), Set/Get, SetDisabled, SetVisible, SetText, Destroy
-- State lives in plain fields; Apply() derives every visual from tokens.
-- ══════════════════════════════════════════════════════════════════════════════

Components.Registry = {}

function Components.Register(object)
    Components.Registry[object] = true
    return object
end

-- Wrapper rows (button/segmented rows) proxy the inner control's public API so
-- consumers never receive a half-object from Section:Add*.
Components.PUBLIC_METHODS = {
    "Set", "Get", "SetValue", "GetValue", "SetDisabled", "SetVisible", "SetText",
    "SetBusy", "SetOptions", "SetRange", "SetSelected", "SetType", "SetLoading",
    "SetStatus", "Open", "Close", "SetHeader", "SetProgress",
}

function Components.Expose(wrapper, source, extra)
    for _, name in ipairs(Components.PUBLIC_METHODS) do
        if source[name] then
            wrapper[name] = function(_, ...)
                return source[name](source, ...)
            end
        end
    end
    for key, value in pairs(extra or {}) do
        wrapper[key] = value
    end
    -- own fields win; anything else (Busy, Value, Selected, Root internals) proxies to the control
    local existing = getmetatable(wrapper)
    if not existing or not existing.__exposed then
        setmetatable(wrapper, { __exposed = true, __index = source })
    end
    return wrapper
end

function Components.Unregister(object)
    Components.Registry[object] = nil
end

function Components.RefreshAll()
    for object in pairs(Components.Registry) do
        if object.Apply and object.Root and object.Root.Parent then
            pcall(object.Apply, object)
        end
    end
end

-- A layered surface: Base (neutral) + Fill (accent gradient, transparent when off) + content above.
function Components.Surface(scope, parent, options)
    options = options or {}
    local radius = options.Radius or Theme.Radius.Medium
    local root = Prim.frame(parent, options.Name or "Surface", options.Base or Theme.Color.Surface)
    root.ZIndex = options.ZIndex or 1
    Prim.corner(root, radius)
    if options.Stroke ~= false then
        root.Stroke = Prim.stroke(root, options.StrokeColor or Theme.Color.Stroke, options.StrokeWidth or 1, options.StrokeTransparency or 0)
    end
    local fill
    if options.Fill ~= false then
        fill = Prim.frame(root, "AccentFill", Theme.Color.White)
        fill.ZIndex = root.ZIndex + 1
        fill.BackgroundTransparency = 1
        Prim.corner(fill, radius)
        Prim.aurora(fill, scope, options.FillRotation or 0)
    end
    local surface = { Root = root, Fill = fill, Selected = false, Scope = scope }
    function surface:SetSelected(selected, animate)
        self.Selected = selected == true
        if not self.Fill then
            return
        end
        if self.Selected then
            self.Fill.BackgroundTransparency = animate and 1 or 0
            if animate then
                Anim.To(self.Fill, { BackgroundTransparency = 0 }, Motion.Fast)
            end
        elseif animate then
            Anim.To(self.Fill, { BackgroundTransparency = 1 }, Motion.Fast)
        else
            Anim.CancelProperty(self.Fill, "BackgroundTransparency")
            self.Fill.BackgroundTransparency = 1
        end
    end
    return surface
end

-- Base row: label (+icon, tooltip, value area). Shared by every control.
function Components.Row(scope, parent, config)
    config = config or {}
    local row = {
        Scope = scope,
        Disabled = false,
        Hovered = false,
        Pressed = false,
        Visible = true,
        Height = config.Height or Theme.Metric.RowHeight,
    }
    row.Root = Prim.new("TextButton", {
        Name = config.Name or "Row",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, row.Height),
        Active = config.Interactive ~= false,
        Selectable = false,
    }, parent)
    Prim.corner(row.Root, Theme.Radius.Small)

    local labelX = Theme.Space.L
    if config.Icon then
        row.Icon = Prim.Icon.new(row.Root, config.Icon, Theme.Color.TextMuted, 15, 1.5)
        Prim.place(row.Icon.Root, Theme.Space.L, (row.Height - 15) / 2, 15, 15)
        labelX = Theme.Space.L + 15 + Theme.Space.M
    end
    row.Label = Prim.label(row.Root, "Label", Util.text(config.Name or "", 64), config.LabelSize or Theme.Type.Body, Theme.Color.Text, Theme.Font.Medium)
    row.Label.Position = UDim2.fromOffset(labelX, 0)
    row.Label.Size = UDim2.new(1, -(labelX + 120), 1, 0)
    row.Label.TextTruncate = Enum.TextTruncate.AtEnd

    -- right-aligned value / control area
    row.Value = Prim.label(row.Root, "Value", "", Theme.Type.Small, Theme.Color.TextMuted, Theme.Font.Medium)
    row.Value.TextXAlignment = Enum.TextXAlignment.Right
    row.Value.AnchorPoint = Vector2.new(1, 0.5)
    row.Value.Position = UDim2.new(1, -Theme.Space.L, 0.5, 0)
    row.Value.Size = UDim2.fromOffset(96, row.Height)
    row.Value.Visible = config.Value or false

    function row:Apply()
        local labelColor = Theme.Color.Text
        if self.Disabled then
            labelColor = Theme.Color.TextMuted
        elseif self.Hovered and config.Interactive ~= false then
            labelColor = Theme.Color.Text
        end
        self.Label.TextColor3 = labelColor
        if self.Icon then
            self.Icon:SetColor(self.Disabled and Theme.Color.TextMuted or (self.Hovered and Theme.Color.TextSecondary or Theme.Color.TextMuted))
        end
        if config.Interactive ~= false then
            local background = self.Hovered and Theme.Color.Surface or Theme.Color.Surface
            local transparency = self.Disabled and 1 or (self.Pressed and 0.55 or (self.Hovered and 0.72 or 1))
            Anim.To(self.Root, {
                BackgroundColor3 = background,
                BackgroundTransparency = transparency,
            }, Motion.Micro)
        end
    end

    function row:SetDisabled(value)
        self.Disabled = value == true
        self.Root.Active = not self.Disabled and config.Interactive ~= false
        self:Apply()
    end

    function row:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end

    function row:HideRow()
        self.Root.Visible = false
        self.Root.Size = UDim2.fromOffset(0, 0)
    end

    function row:Destroy()
        Components.Unregister(self)
        self.Scope = nil
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    if config.Interactive ~= false then
        row.Root.Selectable = true
        scope:Connect(row.Root.MouseEnter, function()
            if row.Disabled then
                return
            end
            row.Hovered = true
            row:Apply()
            if config.OnHover then
                config.OnHover(true)
            end
        end)
        scope:Connect(row.Root.MouseLeave, function()
            row.Hovered = false
            row.Pressed = false
            row:Apply()
            if config.OnHover then
                config.OnHover(false)
            end
        end)
        scope:Connect(row.Root.SelectionGained, function()
            if row.Disabled then
                return
            end
            row.Hovered = true
            row:Apply()
        end)
        scope:Connect(row.Root.SelectionLost, function()
            row.Hovered = false
            row.Pressed = false
            row:Apply()
        end)
        scope:Connect(row.Root.InputBegan, function(input)
            if row.Disabled then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                row.Pressed = true
                row:Apply()
            end
        end)
        scope:Connect(row.Root.InputEnded, function()
            if row.Pressed then
                row.Pressed = false
                row:Apply()
            end
        end)
        if config.OnActivate then
            scope:Connect(row.Root.Activated, function()
                if row.Disabled then
                    return
                end
                row.Pressed = false
                row:Apply()
                config.OnActivate()
            end)
        end
    end
    if config.Tooltip then
        Tooltip.Attach(scope, row.Root, config.Tooltip)
    end
    return row
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Button — primary / secondary / ghost / danger, icon support, busy state.
-- ══════════════════════════════════════════════════════════════════════════════

local BUTTON_STYLE = {
    primary = { base = Theme.Color.SurfaceInteractive, text = Theme.Color.Text, fill = true },
    secondary = { base = Theme.Color.Surface, text = Theme.Color.Text, fill = false },
    ghost = { base = Theme.Color.Surface, text = Theme.Color.TextSecondary, fill = false, transparent = true },
    danger = { base = Theme.Color.DangerDeep, text = Theme.Color.Danger, fill = false },
    success = { base = Theme.Color.SurfaceInteractive, text = Theme.Color.Success, fill = false },
}

function Components.Button(scope, parent, config)
    config = config or {}
    local style = BUTTON_STYLE[config.Style or "secondary"] or BUTTON_STYLE.secondary
    local button = {
        Scope = scope,
        Disabled = false,
        Hovered = false,
        Pressed = false,
        Busy = false,
        Visible = true,
        Text = Util.text(config.Text or config.Name or "Button", 40),
        Height = config.Height or Theme.Metric.ControlHeight,
    }
    button.Root = Prim.new("TextButton", {
        Name = config.Name or "Button",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = style.base,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(config.Width or 140, button.Height),
        Active = true,
        Selectable = true,
    }, parent)
    Prim.corner(button.Root, config.Radius or Theme.Radius.Medium)
    button.Stroke = Prim.stroke(button.Root, Theme.Color.Stroke, 1, 0.2)
    button.Scale = Prim.new("UIScale", { Scale = 1 }, button.Root)

    -- primary buttons carry the accent gradient fill
    if style.fill then
        local fill = Prim.frame(button.Root, "AccentFill", Theme.Color.White)
        fill.BackgroundTransparency = 1
        fill.ZIndex = 1
        Prim.corner(fill, config.Radius or Theme.Radius.Medium)
        Prim.aurora(fill, scope, 0)
        button.Fill = fill
    end

    local textX = 0
    local contentWidth = 0
    if config.Icon then
        button.Icon = Prim.Icon.new(button.Root, config.Icon, style.text, 15, 1.5)
        button.Icon.Root.AnchorPoint = Vector2.new(0, 0.5)
        button.Icon.Root.Position = UDim2.new(0.5, -1, 0.5, 0)
        button.Icon.Root.ZIndex = 3
        contentWidth = contentWidth + 20
    end
    button.Label = Prim.label(button.Root, "Label", button.Text, config.TextSize or Theme.Type.Small, style.text, Theme.Font.Bold)
    button.Label.TextXAlignment = Enum.TextXAlignment.Center
    button.Label.TextTruncate = Enum.TextTruncate.AtEnd
    button.Label.ZIndex = 3
    if config.Icon then
        button.Label.Size = UDim2.new(1, -34, 1, 0)
        button.Label.Position = UDim2.fromOffset(16, 0)
        button.Label.TextXAlignment = Enum.TextXAlignment.Left
    else
        button.Label.Size = UDim2.fromScale(1, 1)
    end

    if config.Style == "primary" then
        button.Label.TextColor3 = Theme.Color.Text
    end

    function button:Apply()
        local accent = style.fill and button.Fill
        local transparency = button.Disabled and 0.6 or (button.Hovered and 0.78 or (style.transparent and 1 or 0.35))
        if style.fill and accent then
            local target = button.Disabled and 0.75 or (button.Hovered and 0.02 or 0.18)
            Anim.To(accent, { BackgroundTransparency = target }, Motion.Micro)
            button.Label.TextColor3 = button.Disabled and Theme.Color.TextMuted or Theme.Color.Text
        else
            local base = button.Disabled and Theme.Color.Surface
                or (button.Pressed and Theme.Color.SurfacePressed or (button.Hovered and Theme.Color.SurfaceHover or style.base))
            Anim.To(button.Root, { BackgroundColor3 = base, BackgroundTransparency = transparency }, Motion.Micro)
            button.Label.TextColor3 = button.Disabled and Theme.Color.TextMuted or style.text
        end
        Anim.To(button.Scale, { Scale = (button.Pressed and not button.Disabled) and 0.985 or 1 }, Motion.Instant)
        button.Stroke.Transparency = button.Disabled and 0.75 or (button.Hovered and 0.05 or 0.2)
        if button.Icon then
            button.Icon:SetColor(button.Disabled and Theme.Color.TextMuted or style.text)
        end
        if button.Busy then
            button.Root.Active = false
        else
            button.Root.Active = not button.Disabled
        end
    end

    function button:SetDisabled(value)
        self.Disabled = value == true
        self:Apply()
    end

    function button:SetBusy(value)
        self.Busy = value == true
        if self.Busy then
            if self.Label.Text ~= "" then
                self.SavedText = self.Label.Text
            end
            self.Label.Text = ""
            if not self.Spinner then
                local spinnerRoot = Prim.frame(self.Root, "Spinner", Theme.Color.Text)
                spinnerRoot.BackgroundTransparency = 1
                spinnerRoot.Size = UDim2.fromOffset(16, 16)
                spinnerRoot.AnchorPoint = Vector2.new(0.5, 0.5)
                spinnerRoot.Position = UDim2.fromScale(0.5, 0.5)
                spinnerRoot.ZIndex = 4
                local arc = Prim.frame(spinnerRoot, "Arc", Theme.Color.Text)
                arc.Size = UDim2.fromOffset(16, 2)
                arc.Position = UDim2.fromOffset(0, 0)
                Prim.corner(arc, 2)
                local arc2 = Prim.frame(spinnerRoot, "Arc2", Theme.Color.Text)
                arc2.AnchorPoint = Vector2.new(0.5, 0.5)
                arc2.Size = UDim2.fromOffset(2, 16)
                arc2.Position = UDim2.fromOffset(8, 8)
                Prim.corner(arc2, 2)
                self.Spinner = spinnerRoot
                self.SpinnerLoop = Anim.Loop(spinnerRoot, { Rotation = 360 }, Motion.Spin, function()
                    spinnerRoot.Rotation = 0
                end)
            end
            self.Spinner.Visible = true
        else
            if self.SpinnerLoop then
                Anim.StopLoop(self.SpinnerLoop)
                self.SpinnerLoop = nil
            end
            if self.Spinner then
                self.Spinner.Visible = false
                self.Spinner.Rotation = 0
            end
            if self.SavedText then
                self.Label.Text = self.SavedText
                self.SavedText = nil
            end
        end
        self:Apply()
    end

    function button:SetText(value)
        self.Text = Util.text(value, 40)
        if not self.Busy then
            self.Label.Text = self.Text
        end
    end

    function button:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end

    function button:Destroy()
        Components.Unregister(self)
        if self.SpinnerLoop then
            Anim.StopLoop(self.SpinnerLoop)
        end
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    scope:Connect(button.Root.MouseEnter, function()
        if button.Disabled or button.Busy then
            return
        end
        button.Hovered = true
        button:Apply()
    end)
    scope:Connect(button.Root.MouseLeave, function()
        button.Hovered = false
        button.Pressed = false
        button:Apply()
    end)
    scope:Connect(button.Root.SelectionGained, function()
        if button.Disabled then
            return
        end
        button.Hovered = true
        button:Apply()
    end)
    scope:Connect(button.Root.SelectionLost, function()
        button.Hovered = false
        button.Pressed = false
        button:Apply()
    end)
    scope:Connect(button.Root.InputBegan, function(input)
        if button.Disabled or button.Busy then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            button.Pressed = true
            button:Apply()
        end
    end)
    scope:Connect(button.Root.InputEnded, function()
        if button.Pressed then
            button.Pressed = false
            button:Apply()
        end
    end)
    scope:Connect(button.Root.Activated, function()
        if button.Disabled or button.Busy then
            return
        end
        if config.Callback then
            Util.guard(config.Callback, button)
        end
    end)
    if config.Tooltip then
        Tooltip.Attach(scope, button.Root, config.Tooltip)
    end
    button:Apply()
    return Components.Register(button)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- IconButton — 34x34 square, hover wash, accent selected state.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.IconButton(scope, parent, config)
    config = config or {}
    local button = { Scope = scope, Disabled = false, Hovered = false, Pressed = false, Selected = false }
    local size = config.Size or 34
    button.Root = Prim.new("TextButton", {
        Name = config.Name or "IconButton",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(size, size),
        Active = true,
        Selectable = true,
    }, parent)
    Prim.corner(button.Root, Theme.Radius.Small)
    button.Icon = Prim.Icon.new(button.Root, config.Icon or "dot", config.Color or Theme.Color.TextSecondary, config.IconSize or 15, 1.5)
    button.Icon.Root.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Icon.Root.Position = UDim2.fromScale(0.5, 0.5)

    function button:Apply()
        local transparency = self.Disabled and 1 or (self.Selected and 0.75 or (self.Hovered and 0.82 or 1))
        local base = self.Selected and Theme.Color.SurfaceInteractive or (self.Pressed and Theme.Color.SurfacePressed or Theme.Color.SurfaceHover)
        Anim.To(self.Root, { BackgroundColor3 = base, BackgroundTransparency = transparency }, Motion.Micro)
        local color = config.Color or Theme.Color.TextSecondary
        if self.Disabled then
            color = Theme.Color.TextMuted
        elseif self.Selected then
            color = Theme.Color.Accent
        elseif self.Hovered then
            color = Theme.Color.Text
        end
        self.Icon:SetColor(color)
    end

    function button:SetSelected(value)
        self.Selected = value == true
        self:Apply()
    end

    function button:SetDisabled(value)
        self.Disabled = value == true
        self:Apply()
    end

    function button:SetVisible(value)
        self.Root.Visible = value ~= false
    end

    function button:Destroy()
        Components.Unregister(self)
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    scope:Connect(button.Root.MouseEnter, function()
        if button.Disabled then return end
        button.Hovered = true
        button:Apply()
    end)
    scope:Connect(button.Root.MouseLeave, function()
        button.Hovered = false
        button.Pressed = false
        button:Apply()
    end)
    scope:Connect(button.Root.InputBegan, function(input)
        if button.Disabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            button.Pressed = true
            button:Apply()
        end
    end)
    scope:Connect(button.Root.InputEnded, function()
        if button.Pressed then
            button.Pressed = false
            button:Apply()
        end
    end)
    scope:Connect(button.Root.Activated, function()
        if button.Disabled then return end
        if config.Callback then
            Util.guard(config.Callback, button)
        end
    end)
    if config.Tooltip then
        Tooltip.Attach(scope, button.Root, config.Tooltip)
    end
    button:Apply()
    return Components.Register(button)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Toggle — animated track + knob, silent-aware SetValue.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Toggle(scope, parent, config)
    config = config or {}
    local toggle = {
        Scope = scope,
        Value = config.Default == true,
        Disabled = false,
        Visible = true,
        Height = config.Height or Theme.Metric.RowHeight,
    }
    toggle.Row = Components.Row(scope, parent, {
        Name = config.Name,
        Icon = config.Icon,
        Tooltip = config.Tooltip,
        Height = toggle.Height,
        OnActivate = function()
            toggle:SetValue(not toggle.Value)
        end,
    })
    toggle.Root = toggle.Row.Root
    toggle.Row.Value.Visible = false

    local trackWidth, trackHeight = 34, 19
    toggle.Track = Prim.frame(toggle.Root, "Track", Theme.Color.SurfaceInteractive)
    toggle.Track.AnchorPoint = Vector2.new(1, 0.5)
    toggle.Track.Position = UDim2.new(1, -Theme.Space.L, 0.5, 0)
    toggle.Track.Size = UDim2.fromOffset(trackWidth, trackHeight)
    toggle.Track.ZIndex = 3
    Prim.corner(toggle.Track, 100)
    toggle.TrackFill = Prim.frame(toggle.Track, "Fill", Theme.Color.White)
    toggle.TrackFill.Size = UDim2.fromScale(1, 1)
    toggle.TrackFill.BackgroundTransparency = 1
    Prim.corner(toggle.TrackFill, 100)
    Prim.aurora(toggle.TrackFill, scope, 0)
    toggle.Knob = Prim.frame(toggle.Track, "Knob", Theme.Color.Text)
    toggle.Knob.AnchorPoint = Vector2.new(0, 0.5)
    toggle.Knob.Position = UDim2.fromOffset(3, 0)
    toggle.Knob.Size = UDim2.fromOffset(13, 13)
    toggle.Knob.ZIndex = 4
    Prim.corner(toggle.Knob, 100)

    function toggle:Apply()
        local on = self.Value
        local off = self.Disabled and 1 or (self.Row.Hovered and 0.15 or 0.45)
        Anim.To(self.Track, { BackgroundTransparency = self.Disabled and 0.7 or 0.35 }, Motion.Micro)
        if self.TrackFill then
            local target = 1
            if on then
                target = self.Disabled and 0.55 or 0
            end
            Anim.To(self.TrackFill, { BackgroundTransparency = target }, Motion.Fast)
        end
        Anim.To(self.Knob, {
            Position = UDim2.fromOffset(on and (trackWidth - 16) or 3, 0),
            BackgroundColor3 = on and Theme.Color.Text or Theme.Color.TextSecondary,
        }, Motion.Fast)
    end

    function toggle:SetValue(value, silent)
        value = value == true
        if value == self.Value then
            return
        end
        self.Value = value
        self:Apply()
        if not silent and config.Callback then
            Util.guard(config.Callback, value)
        end
    end

    function toggle:Get() return self.Value end
    function toggle:Set(value, silent) return self:SetValue(value, silent) end
    function toggle:SetDisabled(value) self.Disabled = value == true; self.Row:SetDisabled(value); self:Apply() end
    function toggle:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end
    function toggle:SetText(value)
        self.Row.Label.Text = Util.text(value, 64)
    end
    function toggle:Destroy()
        Components.Unregister(self)
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end
    toggle:Apply()
    return Components.Register(toggle)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Checkbox — compact square + label (auth "remember me" pattern).
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Checkbox(scope, parent, config)
    config = config or {}
    local box = { Scope = scope, Value = config.Default == true, Disabled = false, Hovered = false }
    box.Root = Prim.new("TextButton", {
        Name = config.Name or "Checkbox",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(config.Width or 160, config.Height or 28),
        Active = true,
        Selectable = true,
    }, parent)
    box.Height = config.Height or 28
    box.Box = Prim.frame(box.Root, "Box", Theme.Color.SurfaceInteractive)
    box.Box.Size = UDim2.fromOffset(16, 16)
    box.Box.Position = UDim2.fromOffset(0, (box.Height - 16) / 2)
    Prim.corner(box.Box, Theme.Radius.Small)
    box.BoxStroke = Prim.stroke(box.Box, Theme.Color.StrokeStrong, 1, 0.2)
    box.Fill = Prim.frame(box.Box, "Fill", Theme.Color.White)
    box.Fill.Size = UDim2.fromScale(1, 1)
    box.Fill.BackgroundTransparency = 1
    Prim.corner(box.Fill, Theme.Radius.Small)
    Prim.aurora(box.Fill, scope, 0)
    box.Check = Prim.Icon.new(box.Box, "check", Theme.Color.OnAccent, 10, 2)
    box.Check.Root.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Check.Root.Position = UDim2.fromScale(0.5, 0.5)
    box.Check.Root.Visible = false
    box.Label = Prim.label(box.Root, "Label", Util.text(config.Text or "", 40), Theme.Type.Small, Theme.Color.TextSecondary, Theme.Font.Medium)
    box.Label.Position = UDim2.fromOffset(24, 0)
    box.Label.Size = UDim2.new(1, -24, 1, 0)

    function box:Apply()
        Anim.To(self.Fill, { BackgroundTransparency = self.Value and (self.Disabled and 0.5 or 0) or 1 }, Motion.Fast)
        self.Check.Root.Visible = self.Value
        self.Label.TextColor3 = self.Disabled and Theme.Color.TextMuted or (self.Value and Theme.Color.Text or Theme.Color.TextSecondary)
        self.BoxStroke.Transparency = self.Value and 0.9 or (self.Hovered and 0.05 or 0.25)
        self.Box.BackgroundTransparency = self.Value and 1 or 0
    end

    function box:SetValue(value, silent)
        value = value == true
        if value == self.Value then return end
        self.Value = value
        self:Apply()
        if not silent and config.Callback then
            Util.guard(config.Callback, value)
        end
    end
    function box:Get() return self.Value end
    function box:Set(value, silent) return self:SetValue(value, silent) end
    function box:SetDisabled(value) self.Disabled = value == true; self.Root.Active = not self.Disabled; self:Apply() end
    function box:SetVisible(value) self.Root.Visible = value ~= false end
    function box:SetText(value) self.Label.Text = Util.text(value, 40) end
    function box:Destroy()
        Components.Unregister(self)
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    scope:Connect(box.Root.MouseEnter, function() box.Hovered = true; box:Apply() end)
    scope:Connect(box.Root.MouseLeave, function() box.Hovered = false; box:Apply() end)
    scope:Connect(box.Root.Activated, function()
        if box.Disabled then return end
        box:SetValue(not box.Value)
    end)
    box:Apply()
    return Components.Register(box)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Badge / Chip — status chips with type tints.
-- ══════════════════════════════════════════════════════════════════════════════

local BADGE_STYLE = {
    neutral = { bg = Theme.Color.SurfaceInteractive, fg = Theme.Color.TextSecondary, alpha = 0 },
    accent = { bg = Theme.Color.AccentDeep, fg = Theme.Color.Accent, alpha = 0.35 },
    success = { bg = Theme.Color.Success, fg = Theme.Color.OnAccent, alpha = 0 },
    warning = { bg = Theme.Color.Warning, fg = Theme.Color.OnAccent, alpha = 0 },
    danger = { bg = Theme.Color.DangerDeep, fg = Theme.Color.Danger, alpha = 0 },
}

function Components.Badge(scope, parent, config)
    config = config or {}
    local style = BADGE_STYLE[config.Type or "neutral"] or BADGE_STYLE.neutral
    local badge = { Scope = scope }
    local text = Util.text(config.Text or "", 20)
    local width = config.Width or (Util.measureWidth(text, Theme.Type.Micro, Theme.Font.Bold) + (config.Icon and 30 or 20))
    local height = config.Height or 22
    badge.Root = Prim.frame(parent, config.Name or "Badge", style.bg)
    badge.Root.BackgroundTransparency = style.alpha
    badge.Root.Size = UDim2.fromOffset(width, height)
    Prim.corner(badge.Root, config.Pill == false and Theme.Radius.Small or 100)
    local textX = 10
    if config.Icon then
        badge.Icon = Prim.Icon.new(badge.Root, config.Icon, style.fg, 11, 1.6)
        Prim.place(badge.Icon.Root, 9, (height - 11) / 2, 11, 11)
        textX = 24
    end
    badge.Label = Prim.label(badge.Root, "Text", text, Theme.Type.Micro, style.fg, Theme.Font.Bold)
    badge.Label.Size = UDim2.new(1, -textX - 10, 1, 0)
    badge.Label.Position = UDim2.fromOffset(textX, 0)
    function badge:SetText(value)
        self.Label.Text = Util.text(value, 20)
    end
    function badge:SetType(value)
        local nextStyle = BADGE_STYLE[value] or BADGE_STYLE.neutral
        self.Root.BackgroundColor3 = nextStyle.bg
        self.Label.TextColor3 = nextStyle.fg
        if self.Icon then self.Icon:SetColor(nextStyle.fg) end
    end
    function badge:SetVisible(value) self.Root.Visible = value ~= false end
    function badge:Destroy()
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end
    return badge
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Label / Paragraph / Divider — text blocks used inside sections and pages.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Label(scope, parent, config)
    config = config or {}
    local label = { Scope = scope, Height = config.Height or 18 }
    label.Root = Prim.label(parent, config.Name or "Label", Util.text(config.Text or "", 200), config.Size or Theme.Type.Body, config.Color or Theme.Color.TextSecondary, config.Font or Theme.Font.Regular)
    label.Root.TextWrapped = config.Wrap ~= false
    label.Root.TextYAlignment = Enum.TextYAlignment.Top
    function label:SetText(value)
        self.Root.Text = Util.text(value, 200)
    end
    function label:Layout(width)
        local size = self.Root.TextSize
        local height = math.max(size + 4, Util.measureHeight(self.Root.Text, size, self.Root.Font, width))
        self.Height = height
        self.Root.Size = UDim2.fromOffset(width, height)
        return height
    end
    function label:Destroy()
        self.Root:Destroy()
    end
    return label
end

function Components.Paragraph(scope, parent, config)
    config = config or {}
    local paragraph = { Scope = scope }
    paragraph.Root = Prim.frame(parent, config.Name or "Paragraph", Theme.Color.Surface)
    paragraph.Root.BackgroundTransparency = 1
    local title = Util.text(config.Title or config.Name or "", 60)
    local body = Util.text(config.Text or config.Description or "", 400)
    paragraph.Title = Prim.label(paragraph.Root, "Title", title, config.TitleSize or Theme.Type.Body, Theme.Color.Text, Theme.Font.Medium)
    paragraph.Body = Prim.label(paragraph.Root, "Body", body, Theme.Type.Small, Theme.Color.TextSecondary)
    paragraph.Body.TextWrapped = true
    paragraph.Body.TextYAlignment = Enum.TextYAlignment.Top
    function paragraph:Layout(width)
        local y = 0
        if title ~= "" then
            local titleHeight = math.max(17, Util.measureHeight(title, config.TitleSize or Theme.Type.Body, Theme.Font.Medium, width))
            Prim.place(self.Title, 0, 0, width, titleHeight)
            y = titleHeight + 3
        else
            self.Title.Visible = false
        end
        local bodyHeight = body ~= "" and math.max(15, Util.measureHeight(body, Theme.Type.Small, Theme.Font.Regular, width)) or 0
        Prim.place(self.Body, 0, y, width, bodyHeight)
        self.Body.Visible = body ~= ""
        self.Height = y + bodyHeight
        self.Root.Size = UDim2.fromOffset(width, self.Height)
        return self.Height
    end
    function paragraph:SetText(value)
        body = Util.text(value, 400)
        self.Body.Text = body
    end
    function paragraph:SetTitle(value)
        title = Util.text(value, 60)
        self.Title.Text = title
    end
    function paragraph:Destroy()
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end
    paragraph:Layout(config.Width or 300)
    return paragraph
end

function Components.Divider(scope, parent, config)
    config = config or {}
    local divider = { Scope = scope }
    divider.Root = Prim.frame(parent, "Divider", Theme.Color.Stroke)
    divider.Root.BackgroundTransparency = 0.4
    divider.Root.Size = UDim2.new(1, 0, 0, 1)
    local label = Util.text(config.Text or "", 40)
    if label ~= "" then
        divider.Label = Prim.label(parent, "DividerLabel", label, Theme.Type.Micro, Theme.Color.TextMuted, Theme.Font.Bold)
        divider.Label.TextXAlignment = Enum.TextXAlignment.Left
    end
    function divider:Layout(width)
        local height = 20
        if self.Label then
            Prim.place(self.Root, 0, 9, width, 1)
            Prim.place(self.Label, 0, 0, width, 18)
            height = 24
        else
            Prim.place(self.Root, 0, 0, width, 1)
            height = 1
        end
        self.Height = height
        return height
    end
    function divider:Destroy()
        self.Root:Destroy()
        if self.Label then self.Label:Destroy() end
    end
    divider.Height = 1
    return divider
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Progress — determinate + indeterminate bar.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Progress(scope, parent, config)
    config = config or {}
    local progress = { Scope = scope, Value = Util.clamp(Util.finite(config.Default, 0), 0, 1), Indeterminate = config.Indeterminate == true }
    progress.Root = Prim.frame(parent, config.Name or "Progress", Theme.Color.Surface)
    progress.Root.BackgroundTransparency = 1
    progress.Track = Prim.frame(progress.Root, "Track", Theme.Color.SurfaceInteractive)
    progress.Track.Size = UDim2.new(1, 0, 0, 4)
    Prim.corner(progress.Track, 100)
    progress.Fill = Prim.frame(progress.Track, "Fill", Theme.Color.White)
    progress.Fill.Size = UDim2.fromScale(progress.Value, 1)
    Prim.corner(progress.Fill, 100)
    Prim.gradient(progress.Fill, Theme.AccentStops, 0)

    function progress:Layout(width)
        Prim.place(self.Root, 0, 0, width, 4)
        self.Height = 4
        return 4
    end
    function progress:SetValue(value, silent)
        value = Util.clamp(Util.finite(value, self.Value), 0, 1)
        if value == self.Value then return end
        self.Value = value
        Anim.To(self.Fill, { Size = UDim2.fromScale(value, 1) }, Motion.Fast)
        if not silent and config.Callback then
            Util.guard(config.Callback, value)
        end
    end
    function progress:Get() return self.Value end
    function progress:Set(value, silent) return self:SetValue(value, silent) end
    function progress:Destroy()
        if self.Loop then Anim.StopLoop(self.Loop) end
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end
    return Components.Register(progress)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Skeleton — shimmer placeholder for loading states.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Skeleton(scope, parent, config)
    config = config or {}
    local skeleton = { Scope = scope }
    skeleton.Root = Prim.frame(parent, "Skeleton", Theme.Color.SurfaceRaised)
    Prim.corner(skeleton.Root, config.Radius or Theme.Radius.Small)
    local shimmer = Prim.frame(skeleton.Root, "Shimmer", Theme.Color.White)
    shimmer.Size = UDim2.fromScale(0.4, 1)
    shimmer.BackgroundTransparency = 0.94
    Prim.corner(shimmer, config.Radius or Theme.Radius.Small)
    if not Motion.Reduced then
        skeleton.Loop = Anim.Loop(shimmer, { Position = UDim2.fromScale(1, 0) }, TweenInfo.new(1.5, Enum.EasingStyle.Linear), function()
            shimmer.Position = UDim2.fromScale(-0.4, 0)
        end)
    end
    function skeleton:SetVisible(value)
        self.Root.Visible = value ~= false
    end
    function skeleton:Destroy()
        if self.Loop then Anim.StopLoop(self.Loop) end
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end
    return skeleton
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Banner — inline notice with type tint and optional action.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Banner(scope, parent, config)
    config = config or {}
    local style = BADGE_STYLE[config.Type or "neutral"] or BADGE_STYLE.neutral
    local banner = { Scope = scope, Visible = true }
    banner.Root = Prim.frame(parent, "Banner", Theme.Color.SurfaceRaised)
    Prim.corner(banner.Root, Theme.Radius.Medium)
    banner.Stroke = Prim.stroke(banner.Root, Theme.Color.Stroke, 1, 0.2)
    banner.Rail = Prim.frame(banner.Root, "Rail", style.fg)
    Prim.place(banner.Rail, 0, 14, 3, 20)
    Prim.corner(banner.Rail, 2)
    banner.Icon = Prim.Icon.new(banner.Root, config.Icon or "info", style.fg, 15, 1.6)
    Prim.place(banner.Icon.Root, 16, 16, 15, 15)
    banner.Title = Prim.label(banner.Root, "Title", Util.text(config.Title or "", 60), Theme.Type.Body, Theme.Color.Text, Theme.Font.Medium)
    banner.Body = Prim.label(banner.Root, "Body", Util.text(config.Text or "", 240), Theme.Type.Small, Theme.Color.TextSecondary)
    banner.Body.TextWrapped = true
    banner.Body.TextYAlignment = Enum.TextYAlignment.Top

    function banner:Layout(width)
        local inner = width - 44 - 24
        local titleHeight = math.max(17, Util.measureHeight(banner.Title.Text, Theme.Type.Body, Theme.Font.Medium, inner))
        local bodyText = banner.Body.Text
        local bodyHeight = bodyText ~= "" and math.max(15, Util.measureHeight(bodyText, Theme.Type.Small, Theme.Font.Regular, inner)) or 0
        local height = 16 + titleHeight + (bodyHeight > 0 and (bodyHeight + 2) or 0) + 16
        self.Height = height
        self.Root.Size = UDim2.fromOffset(width, height)
        Prim.place(self.Title, 42, 15, inner, titleHeight)
        Prim.place(self.Body, 42, 15 + titleHeight + 2, inner, bodyHeight)
        self.Body.Visible = bodyHeight > 0
        Prim.place(self.Rail, 0, 16, 3, height - 32)
        return height
    end
    function banner:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end
    function banner:Destroy()
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end
    banner.Height = 56
    return banner
end

-- ══════════════════════════════════════════════════════════════════════════════
-- EmptyState — centered icon + copy + optional action.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.EmptyState(scope, parent, config)
    config = config or {}
    local state = { Scope = scope }
    state.Root = Prim.frame(parent, "EmptyState", Theme.Color.Surface)
    state.Root.BackgroundTransparency = 1
    state.IconWrap = Prim.frame(state.Root, "IconWrap", Theme.Color.SurfaceRaised)
    Prim.corner(state.IconWrap, 100)
    state.Icon = Prim.Icon.new(state.IconWrap, config.Icon or "search", Theme.Color.TextMuted, 20, 1.6)
    state.Icon.Root.AnchorPoint = Vector2.new(0.5, 0.5)
    state.Icon.Root.Position = UDim2.fromScale(0.5, 0.5)
    state.Title = Prim.label(state.Root, "Title", Util.text(config.Title or "Nothing here", 60), Theme.Type.Body, Theme.Color.Text, Theme.Font.Medium)
    state.Title.TextXAlignment = Enum.TextXAlignment.Center
    state.Body = Prim.label(state.Root, "Body", Util.text(config.Text or "", 200), Theme.Type.Small, Theme.Color.TextMuted)
    state.Body.TextXAlignment = Enum.TextXAlignment.Center
    state.Body.TextWrapped = true
    state.Body.TextYAlignment = Enum.TextYAlignment.Top

    function state:Layout(width)
        local height = 132
        self.Height = height
        self.Root.Size = UDim2.fromOffset(width, height)
        Prim.place(self.IconWrap, width / 2 - 20, 16, 40, 40)
        Prim.place(self.Title, 0, 66, width, 18)
        local bodyHeight = math.max(15, Util.measureHeight(self.Body.Text, Theme.Type.Small, Theme.Font.Regular, math.min(width - 40, 260)))
        Prim.place(self.Body, width / 2 - math.min(width - 40, 260) / 2, 86, math.min(width - 40, 260), bodyHeight)
        return height
    end
    function state:SetVisible(value)
        self.Root.Visible = value ~= false
    end
    function state:Destroy()
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end
    state.Height = 132
    return state
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Segmented — compact option group, accent-selected.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Segmented(scope, parent, config)
    config = config or {}
    local group = {
        Scope = scope,
        Options = config.Options or {},
        Value = config.Default,
        Disabled = false,
        Buttons = {},
        Height = config.Height or 32,
    }
    group.Root = Prim.frame(parent, config.Name or "Segmented", Theme.Color.Surface)
    group.Root.BackgroundTransparency = 1
    group.Wrap = Prim.frame(group.Root, "Track", Theme.Color.SurfaceRaised)
    group.Wrap.Size = UDim2.new(1, 0, 1, 0)
    Prim.corner(group.Wrap, Theme.Radius.Medium)
    group.Indicator = Prim.frame(group.Wrap, "Indicator", Theme.Color.White)
    group.Indicator.Size = UDim2.fromOffset(0, group.Height - 6)
    group.Indicator.Position = UDim2.fromOffset(3, 3)
    group.Indicator.ZIndex = 1
    Prim.corner(group.Indicator, Theme.Radius.Small)
    Prim.aurora(group.Indicator, scope, 0)

    function group:Layout(width, height)
        self.Width = width
        self.Height = height or self.Height
        self.Root.Size = UDim2.fromOffset(width, self.Height)
        Prim.place(self.Wrap, 0, 0, width, self.Height)
        local count = math.max(1, #self.Options)
        local cellWidth = (width - 6) / count
        for index, entry in ipairs(self.Buttons) do
            Prim.place(entry.Root, 3 + (index - 1) * cellWidth, 3, cellWidth, self.Height - 6)
        end
        self:Apply(false)
        return self.Height
    end

    function group:Apply(animate)
        local count = math.max(1, #self.Options)
        local width = (self.Width or 200) - 6
        local cellWidth = width / count
        local index = 1
        for position, entry in ipairs(self.Options) do
            if entry.Value == self.Value or entry == self.Value then
                index = position
                break
            end
        end
        local indicatorWidth = self.Indicator.Size.X.Offset
        if indicatorWidth == 0 then
            self.Indicator.Size = UDim2.fromOffset(cellWidth, self.Height - 6)
        end
        local target = UDim2.fromOffset(3 + (index - 1) * cellWidth, 3)
        if animate == false or Motion.Reduced then
            Anim.Snap(self.Indicator, { Position = target, Size = UDim2.fromOffset(cellWidth, self.Height - 6) })
        else
            Anim.To(self.Indicator, { Position = target, Size = UDim2.fromOffset(cellWidth, self.Height - 6) }, Motion.Fast)
        end
        for position, entry in ipairs(self.Buttons) do
            local selected = position == index
            entry.Selected = selected
            entry:Apply()
        end
    end

    function group:SetOptions(options, keepValue)
        self.Options = options or {}
        for _, entry in ipairs(self.Buttons) do
            entry:Destroy()
        end
        self.Buttons = {}
        for position, option in ipairs(self.Options) do
            local value = type(option) == "table" and option.Value or option
            local text = type(option) == "table" and (option.Text or tostring(option.Value)) or tostring(option)
            local disabled = type(option) == "table" and option.Disabled == true
            local entry = Components.SegmentedButton(scope, self.Wrap, {
                Text = text,
                Disabled = disabled,
                OnActivate = function()
                    if group.Disabled then return end
                    if disabled then return end
                    group:SetValue(value)
                end,
            })
            entry.Value = value
            table.insert(self.Buttons, entry)
        end
        if not keepValue then
            self.Value = self.Options[1] and (type(self.Options[1]) == "table" and self.Options[1].Value or self.Options[1]) or nil
        end
        self:Layout(self.Width or 200)
    end

    function group:SetValue(value, silent)
        if value == self.Value then
            return
        end
        self.Value = value
        self:Apply(true)
        if not silent and config.Callback then
            Util.guard(config.Callback, value)
        end
    end
    function group:Get() return self.Value end
    function group:Set(value, silent) return self:SetValue(value, silent) end
    function group:SetDisabled(value)
        self.Disabled = value == true
        for _, entry in ipairs(self.Buttons) do
            entry:SetDisabled(self.Disabled)
        end
    end
    function group:SetVisible(value) self.Root.Visible = value ~= false end
    function group:Destroy()
        for _, entry in ipairs(self.Buttons) do
            entry:Destroy()
        end
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end
    group:SetOptions(group.Options, true)
    if group.Value == nil and #group.Options > 0 then
        group.Value = type(group.Options[1]) == "table" and group.Options[1].Value or group.Options[1]
    end
    return Components.Register(group)
end

function Components.SegmentedButton(scope, parent, config)
    local entry = { Scope = scope, Selected = false, Hovered = false, Pressed = false, Disabled = config.Disabled == true }
    entry.Root = Prim.new("TextButton", {
        Name = "Segment",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = not entry.Disabled,
        Selectable = not entry.Disabled,
        ZIndex = 2,
    }, parent)
    Prim.corner(entry.Root, Theme.Radius.Small)
    entry.Label = Prim.label(entry.Root, "Label", Util.text(config.Text, 22), Theme.Type.Small, Theme.Color.TextSecondary, Theme.Font.Medium)
    entry.Label.TextXAlignment = Enum.TextXAlignment.Center
    entry.Label.Size = UDim2.fromScale(1, 1)
    entry.Label.ZIndex = 3
    function entry:Apply()
        Anim.To(self.Root, {
            BackgroundTransparency = self.Selected and 1 or (self.Disabled and 1 or (self.Hovered and 0.82 or 1)),
            BackgroundColor3 = Theme.Color.SurfaceHover,
        }, Motion.Micro)
        if self.Disabled then
            self.Label.TextColor3 = Theme.Color.TextMuted
        elseif self.Selected then
            self.Label.TextColor3 = Theme.Color.OnAccent
        elseif self.Hovered then
            self.Label.TextColor3 = Theme.Color.Text
        else
            self.Label.TextColor3 = Theme.Color.TextSecondary
        end
    end
    function entry:SetDisabled(value)
        self.Disabled = value == true
        self.Root.Active = not self.Disabled
        self:Apply()
    end
    function entry:Destroy()
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end
    scope:Connect(entry.Root.MouseEnter, function() if entry.Disabled then return end entry.Hovered = true; entry:Apply() end)
    scope:Connect(entry.Root.MouseLeave, function() entry.Hovered = false; entry:Apply() end)
    scope:Connect(entry.Root.Activated, function()
        if entry.Disabled then return end
        if config.OnActivate then Util.guard(config.OnActivate) end
    end)
    entry:Apply()
    return entry
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Popover — the deliberate overlay strategy for menus. Lives above the window,
-- never clipped by a section, viewport clamped, flip-aware, single instance.
-- ══════════════════════════════════════════════════════════════════════════════

local Popover = { Current = nil, Token = 0 }
Library.__internal.Popover = Popover

function Popover.Close(immediate)
    local menu = Popover.Current
    Popover.Current = nil
    Popover.Token = Popover.Token + 1
    if not menu then
        return
    end
    menu.Scope:Destroy()
    if menu.OnClose then
        Util.guard(menu.OnClose)
    end
    local function remove()
        -- the closure owns this menu: destroy it regardless of later opens
        Anim.CancelTree(menu.Root)
        if menu.Root.Parent then
            menu.Root:Destroy()
        end
    end
    if immediate or Motion.Reduced or not menu.Root.Parent then
        remove()
    else
        Anim.To(menu.Root, { GroupTransparency = 1 }, Motion.Exit, remove)
    end
end

function Popover.Open(config)
    if not Layers.Floating then
        return nil
    end
    Popover.Close(true)
    local host = Layers.Root
    local anchor = config.Anchor
    local hostSize = host.AbsoluteSize
    local origin = host.AbsolutePosition
    local anchorPosition = anchor.AbsolutePosition - origin
    local anchorSize = anchor.AbsoluteSize
    local desiredWidth = config.Width or anchorSize.X
    local width = Util.clamp(desiredWidth, 120, math.max(140, hostSize.X - 24))
    local maxHeight = Util.finite(config.MaxHeight, 260)
    local height = math.min(maxHeight, math.max(40, Util.finite(config.Height, 200)))
    local gap = 6
    local spaceBelow = hostSize.Y - (anchorPosition.Y + anchorSize.Y) - 12
    local spaceAbove = anchorPosition.Y - 12
    local openBelow = spaceBelow >= math.min(height, spaceAbove) or spaceAbove < 80
    local finalHeight = Util.clamp(openBelow and math.min(height, spaceBelow) or math.min(height, spaceAbove), 40, height)
    local x = Util.clamp(anchorPosition.X, 12, math.max(12, hostSize.X - width - 12))
    local y = openBelow and (anchorPosition.Y + anchorSize.Y + gap) or (anchorPosition.Y - finalHeight - gap)
    y = Util.clamp(y, 12, math.max(12, hostSize.Y - finalHeight - 12))

    local menu = { Scope = Scope.new(), Anchor = anchor, Width = width, Height = finalHeight, OnClose = config.OnClose }
    menu.Root = Prim.group(Layers.Floating, "Popover")
    menu.Root.BackgroundColor3 = Theme.Color.SurfaceRaised
    menu.Root.GroupTransparency = 1
    menu.Root.Active = true
    menu.Root.Size = UDim2.fromOffset(width, finalHeight)
    menu.Root.Position = UDim2.fromOffset(x, y + 6)
    Prim.corner(menu.Root, Theme.Radius.Medium)
    Prim.stroke(menu.Root, Theme.Color.StrokeStrong, 1, 0.15)
    menu.Scale = Prim.new("UIScale", { Scale = Motion.Reduced and 1 or 0.98 }, menu.Root)

    local content = Prim.frame(menu.Root, "Content", Theme.Color.SurfaceRaised)
    content.BackgroundTransparency = 1
    content.Size = UDim2.fromScale(1, 1)
    menu.Content = content
    menu.Scroller = Prim.scroller(content, "Scroller")
    menu.Body = Prim.frame(menu.Scroller, "Body", Theme.Color.SurfaceRaised)
    menu.Body.BackgroundTransparency = 1
    menu.Body.Size = UDim2.new(1, 0, 0, 0)

    Popover.Current = menu
    if config.Fill then
        Util.guard(config.Fill, menu, menu.Body, width - 8, finalHeight)
    end
    Anim.To(menu.Root, { GroupTransparency = 0, Position = UDim2.fromOffset(x, y) }, Motion.Normal, nil, true)
    Anim.To(menu.Scale, { Scale = 1 }, Motion.Normal, nil, true)
    return menu
end

-- Outside click / escape dismissal is centralised so every menu behaves the same.
function Popover.Bind(runtimeScope)
    runtimeScope:Connect(UserInputService.InputBegan, function(input, gameProcessed)
        local menu = Popover.Current
        if not menu then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local point = input.Position
            if not Util.hit(point, menu.Root) and not Util.hit(point, menu.Anchor) then
                Popover.Close()
            end
        end
    end)
    runtimeScope:Connect(UserInputService.InputBegan, function(input)
        if Popover.Current and input.KeyCode == Enum.KeyCode.Escape then
            Popover.Close()
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Slider — capture-based dragging, click-to-jump, keyboard, clamp-safe math.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Slider(scope, parent, config)
    config = config or {}
    local slider = {
        Scope = scope,
        Min = Util.finite(config.Min, 0),
        Max = Util.finite(config.Max, 100),
        Step = math.max(0.0001, Util.finite(config.Step, 1)),
        Disabled = false,
        Visible = true,
        Dragging = false,
        Height = config.Height or 58,
        Suffix = config.Suffix,
        Format = config.Format,
    }
    if slider.Max < slider.Min then
        slider.Max, slider.Min = slider.Min, slider.Max
    end
    slider.Value = Util.clamp(Util.finite(config.Default, slider.Min), slider.Min, slider.Max)

    slider.Root = Prim.frame(parent, config.Name or "Slider", Theme.Color.Surface)
    slider.Root.BackgroundColor3 = Theme.Color.Surface
    slider.Root.BackgroundTransparency = 1
    slider.Root.Size = UDim2.new(1, 0, 0, slider.Height)

    slider.HitArea = Prim.new("TextButton", {
        Name = "HitArea",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.fromOffset(0, 26),
        Active = true,
        Selectable = true,
    }, slider.Root)
    slider.Label = Prim.label(slider.Root, "Label", Util.text(config.Name or "", 64), Theme.Type.Body, Theme.Color.Text, Theme.Font.Medium)
    Prim.place(slider.Label, Theme.Space.L, 0, 200, 24)
    slider.Label.Size = UDim2.new(0.55, 0, 0, 24)
    slider.Value2 = Prim.label(slider.Root, "Value", "", Theme.Type.Small, Theme.Color.Text, Theme.Font.Medium)
    slider.Value2.TextXAlignment = Enum.TextXAlignment.Right
    Prim.place(slider.Value2, -1, 0, 200, 24)
    slider.Value2.Position = UDim2.new(1, -Theme.Space.L, 0, 4)
    slider.Value2.Size = UDim2.new(0.45, -Theme.Space.L, 0, 24)

    slider.Track = Prim.frame(slider.HitArea, "Track", Theme.Color.SurfaceInteractive)
    slider.Track.Size = UDim2.new(1, -Theme.Space.L * 2, 0, 4)
    slider.Track.Position = UDim2.new(0, Theme.Space.L, 0.5, -2)
    Prim.corner(slider.Track, 100)
    slider.Fill = Prim.frame(slider.Track, "Fill", Theme.Color.White)
    slider.Fill.Size = UDim2.fromScale(0, 1)
    Prim.corner(slider.Fill, 100)
    Prim.gradient(slider.Fill, Theme.AccentStops, 0)
    slider.Knob = Prim.frame(slider.HitArea, "Knob", Theme.Color.Text)
    slider.Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    slider.Knob.Size = UDim2.fromOffset(13, 13)
    Prim.corner(slider.Knob, 100)

    function slider:FormatValue()
        if self.Format then
            return self.Format(self.Value)
        end
        local rounded = Util.round(self.Value)
        local text
        if math.abs(self.Value - rounded) < 0.001 then
            text = string.format("%d", rounded)
        else
            text = string.format("%.2f", self.Value)
        end
        return self.Suffix and (text .. self.Suffix) or text
    end

    function slider:Apply()
        local span = math.max(1e-6, self.Max - self.Min)
        local alpha = Util.clamp((self.Value - self.Min) / span, 0, 1)
        Anim.To(self.Fill, { Size = UDim2.fromScale(alpha, 1) }, Motion.Micro)
        local trackWidth = math.max(1, self.Track.AbsoluteSize.X)
        local knobX = self.Track.Position.X.Offset + trackWidth * alpha
        Anim.To(self.Knob, { Position = UDim2.new(0, knobX, 0.5, 0), BackgroundColor3 = self.Disabled and Theme.Color.TextMuted or Theme.Color.Text }, Motion.Micro)
        self.Value2.Text = self:FormatValue()
        self.Value2.TextColor3 = self.Disabled and Theme.Color.TextMuted or Theme.Color.Text
        self.Label.TextColor3 = self.Disabled and Theme.Color.TextMuted or Theme.Color.Text
        self.Knob.Size = UDim2.fromOffset(self.Dragging and 15 or 13, self.Dragging and 15 or 13)
    end

    local function valueAtX(x)
        local trackLeft = slider.Track.AbsolutePosition.X
        local trackWidth = math.max(1, slider.Track.AbsoluteSize.X)
        local alpha = Util.clamp((x - trackLeft) / trackWidth, 0, 1)
        local raw = slider.Min + alpha * (slider.Max - slider.Min)
        local stepped = slider.Min + slider.Step * math.floor((raw - slider.Min) / slider.Step + 0.5)
        return Util.clamp(stepped, slider.Min, slider.Max)
    end

    function slider:SetValue(value, silent)
        value = Util.clamp(Util.finite(value, self.Value), self.Min, self.Max)
        local stepped = self.Min + self.Step * math.floor((value - self.Min) / self.Step + 0.5)
        value = Util.clamp(stepped, self.Min, self.Max)
        if math.abs(value - self.Value) < 1e-9 then
            return
        end
        self.Value = value
        self:Apply()
        if not silent and config.Callback then
            Util.guard(config.Callback, value)
        end
    end

    function slider:Get() return self.Value end
    function slider:Set(value, silent) return self:SetValue(value, silent) end
    function slider:SetRange(minimum, maximum, step)
        self.Min = Util.finite(minimum, self.Min)
        self.Max = Util.finite(maximum, self.Max)
        self.Step = math.max(0.0001, Util.finite(step, self.Step))
        self:SetValue(self.Value, true)
        self:Apply()
    end
    function slider:SetDisabled(value)
        self.Disabled = value == true
        self.HitArea.Active = not self.Disabled
        self:Apply()
    end
    function slider:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end
    function slider:SetText(value)
        self.Label.Text = Util.text(value, 64)
    end
    function slider:Destroy()
        Components.Unregister(self)
        slider.EndCapture()
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    function slider.EndCapture()
        slider.Dragging = false
        if slider.CaptureConnection then
            slider.CaptureConnection:Disconnect()
            slider.CaptureConnection = nil
        end
        if slider.EndConnection then
            slider.EndConnection:Disconnect()
            slider.EndConnection = nil
        end
        slider:Apply()
    end

    function slider.BeginCapture(x)
        if slider.Disabled then
            return
        end
        slider.Dragging = true
        slider:SetValue(valueAtX(x))
        if slider.CaptureConnection then
            slider.CaptureConnection:Disconnect()
            slider.CaptureConnection = nil
        end
        if slider.EndConnection then
            slider.EndConnection:Disconnect()
            slider.EndConnection = nil
        end
        slider.CaptureConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                slider:SetValue(valueAtX(input.Position.X))
            end
        end)
        slider.EndConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                slider.EndCapture()
            end
        end)
        slider:Apply()
    end

    scope:Connect(slider.HitArea.InputBegan, function(input)
        if slider.Disabled then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            slider.BeginCapture(input.Position.X)
        end
    end)
    scope:Connect(slider.HitArea.SelectionGained, function()
        slider.KeyboardActive = true
        slider.Knob.Size = UDim2.fromOffset(15, 15)
    end)
    scope:Connect(slider.HitArea.SelectionLost, function()
        slider.KeyboardActive = false
        slider:Apply()
    end)
    scope:Connect(UserInputService.InputBegan, function(input)
        if not slider.KeyboardActive or slider.Disabled then
            return
        end
        local code = input.KeyCode
        local delta = 0
        if code == Enum.KeyCode.Left or code == Enum.KeyCode.A then
            delta = -slider.Step
        elseif code == Enum.KeyCode.Right or code == Enum.KeyCode.D then
            delta = slider.Step
        end
        if delta ~= 0 then
            slider:SetValue(slider.Value + delta)
        end
    end)
    scope:Connect(slider.HitArea.MouseEnter, function()
        if slider.Disabled then return end
        Anim.To(slider.Knob, { BackgroundColor3 = Theme.Color.White }, Motion.Micro)
    end)
    scope:Connect(slider.HitArea.MouseLeave, function()
        if slider.Disabled then return end
        Anim.To(slider.Knob, { BackgroundColor3 = Theme.Color.Text }, Motion.Micro)
    end)
    if config.Tooltip then
        Tooltip.Attach(scope, slider.Root, config.Tooltip)
    end
    slider:Apply()
    return Components.Register(slider)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Dropdown / MultiDropdown — popover list, searchable when long, no clipping.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Dropdown(scope, parent, config)
    config = config or {}
    local multi = config.Multi == true
    local dropdown = {
        Scope = scope,
        Options = {},
        Disabled = false,
        Visible = true,
        IsOpen = false,
        Multi = multi,
        Values = {},
        Height = config.Height or 46,
        Placeholder = config.Placeholder or "Select",
    }

    dropdown.Root = Prim.new("TextButton", {
        Name = config.Name or "Dropdown",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, dropdown.Height),
        Active = true,
        Selectable = true,
    }, parent)
    Prim.corner(dropdown.Root, Theme.Radius.Small)
    dropdown.Label = Prim.label(dropdown.Root, "Label", Util.text(config.Name or "", 64), Theme.Type.Body, Theme.Color.Text, Theme.Font.Medium)
    dropdown.Label.Size = UDim2.new(0.5, 0, 1, 0)
    Prim.place(dropdown.Label, Theme.Space.L, 0, 200, dropdown.Height)
    dropdown.Label.Size = UDim2.new(0.52, -Theme.Space.L, 1, 0)

    dropdown.ValueLabel = Prim.label(dropdown.Root, "Value", "", Theme.Type.Small, Theme.Color.TextSecondary, Theme.Font.Medium)
    dropdown.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    dropdown.ValueLabel.AnchorPoint = Vector2.new(1, 0.5)
    dropdown.ValueLabel.Position = UDim2.new(1, -30, 0.5, 0)
    dropdown.ValueLabel.Size = UDim2.fromOffset(140, dropdown.Height)
    dropdown.Chevron = Prim.Icon.new(dropdown.Root, "chevron", Theme.Color.TextMuted, 12, 1.5)
    dropdown.Chevron.Root.AnchorPoint = Vector2.new(1, 0.5)
    dropdown.Chevron.Root.Position = UDim2.new(1, -12, 0.5, 0)

    function dropdown:Normalize(options)
        local normalized = {}
        for index, option in ipairs(options or {}) do
            if type(option) == "table" then
                table.insert(normalized, {
                    Value = option.Value ~= nil and option.Value or option.Text or index,
                    Text = Util.text(option.Text or tostring(option.Value or index), 34),
                    Disabled = option.Disabled == true,
                    Hint = option.Hint,
                })
            else
                table.insert(normalized, { Value = option, Text = Util.text(tostring(option), 34) })
            end
        end
        return normalized
    end

    function dropdown:Find(value)
        for _, option in ipairs(self.Options) do
            if option.Value == value then
                return option
            end
        end
        return nil
    end

    function dropdown:DisplayText()
        if self.Multi then
            local total = 0
            for _ in pairs(self.Values) do
                total = total + 1
            end
            if total == 0 then
                return self.Placeholder
            end
            if total == 1 then
                for value in pairs(self.Values) do
                    local option = self:Find(value)
                    return option and option.Text or tostring(value)
                end
            end
            return tostring(total) .. " selected"
        end
        local option = self:Find(self.Value)
        if option then
            return option.Text
        end
        return self.Value ~= nil and tostring(self.Value) or self.Placeholder
    end

    function dropdown:Apply()
        self.ValueLabel.Text = self:DisplayText()
        local empty = (self.Multi and next(self.Values) == nil) or (not self.Multi and self.Value == nil)
        self.ValueLabel.TextColor3 = empty and Theme.Color.TextMuted or (self.IsOpen and Theme.Color.Accent or Theme.Color.Text)
        self.Label.TextColor3 = self.Disabled and Theme.Color.TextMuted or Theme.Color.Text
        Anim.To(self.Chevron.Root, { Rotation = self.IsOpen and 180 or 0 }, Motion.Micro)
        self.Chevron:SetColor(self.IsOpen and Theme.Color.Accent or Theme.Color.TextMuted)
        Anim.To(self.Root, {
            BackgroundTransparency = self.Disabled and 0.7 or (self.IsOpen and 0.78 or (self.Hovered and 0.8 or 1)),
            BackgroundColor3 = Theme.Color.Surface,
        }, Motion.Micro)
    end

    local function buildMenu(menu, body, width, maxHeight)
        local searchable = #dropdown.Options > 11
        local searchHeight = searchable and 40 or 0
        local rowHeight = 34
        local listHeight = #dropdown.Options * rowHeight
        local visibleHeight = math.min(listHeight, maxHeight - searchHeight - 8)
        menu.Body.Size = UDim2.new(1, 0, 0, visibleHeight + searchHeight + 4)
        local y = 4
        if searchable then
            local searchWrap = Prim.frame(body, "SearchWrap", Theme.Color.SurfaceInteractive)
            Prim.place(searchWrap, 4, 4, width, 32)
            Prim.corner(searchWrap, Theme.Radius.Small)
            local searchIcon = Prim.Icon.new(searchWrap, "search", Theme.Color.TextMuted, 12, 1.5)
            Prim.place(searchIcon.Root, 9, 10, 12, 12)
            local box = Prim.new("TextBox", {
                Name = "Search",
                Text = "",
                PlaceholderText = "Search",
                PlaceholderColor3 = Theme.Color.TextMuted,
                TextColor3 = Theme.Color.Text,
                TextSize = Theme.Type.Small,
                Font = Theme.Font.Regular,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(28, 0),
                Size = UDim2.new(1, -36, 1, 0),
            }, searchWrap)
            searchWrap.Visible = true
            y = 44
            menu.Scope:Connect(box:GetPropertyChangedSignal("Text"), function()
                local term = string.lower(Util.trim(box.Text))
                local cursor = y
                for _, row in ipairs(menu.Rows or {}) do
                    local matches = term == "" or string.find(string.lower(row.Option.Text), term, 1, true) ~= nil
                    row.Root.Visible = matches
                    if matches then
                        Prim.place(row.Root, 4, cursor, width, rowHeight - 2)
                        cursor = cursor + rowHeight
                    end
                end
                local needed = cursor + 4
                body.Size = UDim2.new(1, 0, 0, math.min(needed, maxHeight))
                menu.Body.Size = UDim2.new(1, 0, 0, math.min(needed, maxHeight))
            end)
        end
        menu.Rows = {}
        for _, option in ipairs(dropdown.Options) do
            local selected = dropdown.Multi and dropdown.Values[option.Value] == true or (not dropdown.Multi and dropdown.Value == option.Value)
            local row = Prim.new("TextButton", {
                Name = "Option",
                Text = "",
                AutoButtonColor = false,
                BackgroundColor3 = Theme.Color.SurfaceRaised,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(width, rowHeight - 2),
                Position = UDim2.fromOffset(4, y),
                Active = not option.Disabled,
                Selectable = not option.Disabled,
            }, body)
            Prim.corner(row, Theme.Radius.Small)
            row.Selected = selected
            if dropdown.Multi then
                local mark = Prim.frame(row, "Mark", Theme.Color.SurfaceInteractive)
                Prim.place(mark, 10, (rowHeight - 2 - 15) / 2, 15, 15)
                Prim.corner(mark, Theme.Radius.Small)
                local fill = Prim.frame(mark, "Fill", Theme.Color.White)
                fill.Size = UDim2.fromScale(1, 1)
                fill.BackgroundTransparency = selected and 0 or 1
                Prim.corner(fill, Theme.Radius.Small)
                Prim.aurora(fill, menu.Scope, 0)
                local check = Prim.Icon.new(mark, "check", Theme.Color.OnAccent, 9, 2)
                check.Root.AnchorPoint = Vector2.new(0.5, 0.5)
                check.Root.Position = UDim2.fromScale(0.5, 0.5)
                check.Root.Visible = selected
                row.Mark, row.MarkFill, row.MarkCheck = mark, fill, check
            else
                local dot = Prim.frame(row, "Dot", Theme.Color.Accent)
                dot.AnchorPoint = Vector2.new(0.5, 0.5)
                Prim.place(dot, 17, (rowHeight - 2) / 2, 6, 6)
                Prim.corner(dot, 100)
                dot.BackgroundTransparency = selected and 0 or 1
                row.Dot = dot
            end
            local label = Prim.label(row, "Text", option.Text, Theme.Type.Small, option.Disabled and Theme.Color.TextMuted or (selected and Theme.Color.Text or Theme.Color.TextSecondary), selected and Theme.Font.Medium or Theme.Font.Regular)
            Prim.place(label, dropdown.Multi and 34 or 30, 0, width - 44, rowHeight - 2)
            if option.Hint then
                local hint = Prim.label(row, "Hint", Util.text(option.Hint, 24), Theme.Type.Micro, Theme.Color.TextMuted)
                hint.TextXAlignment = Enum.TextXAlignment.Right
                Prim.place(hint, width - 60, 0, 50, rowHeight - 2)
            end
            row.Option = option
            table.insert(menu.Rows, { Root = row, Option = option, Label = label, Selected = selected })
            if not option.Disabled then
                menu.Scope:Connect(row.MouseEnter, function()
                    Anim.To(row, { BackgroundTransparency = 0.78 }, Motion.Micro)
                end)
                menu.Scope:Connect(row.MouseLeave, function()
                    Anim.To(row, { BackgroundTransparency = 1 }, Motion.Micro)
                end)
                menu.Scope:Connect(row.Activated, function()
                    dropdown:Choose(option)
                end)
            end
            y = y + rowHeight
        end
        menu.Body.Size = UDim2.new(1, 0, 0, y + 4)
    end

    function dropdown:Open()
        if self.Disabled or self.IsOpen then
            return
        end
        self.IsOpen = true
        self:Apply()
        local optionCount = #self.Options
        local desiredHeight = math.min(320, optionCount * 34 + 12 + (#self.Options > 11 and 40 or 0))
        Popover.Open({
            Anchor = self.Root,
            Width = math.max(180, self.Root.AbsoluteSize.X),
            Height = desiredHeight,
            MaxHeight = math.min(360, math.max(120, Layers.Root.AbsoluteSize.Y - 40)),
            Fill = function(menu, body, width, maxHeight)
                buildMenu(menu, body, width, maxHeight)
            end,
            OnClose = function()
                dropdown.IsOpen = false
                dropdown:Apply()
            end,
        })
    end

    function dropdown:Choose(option)
        if option.Disabled then
            return
        end
        if self.Multi then
            if self.Values[option.Value] then
                self.Values[option.Value] = nil
            else
                self.Values[option.Value] = true
            end
            self:Apply()
            if config.Callback then
                local list = {}
                for index, entry in ipairs(self.Options) do
                    if self.Values[entry.Value] then
                        table.insert(list, entry.Value)
                    end
                end
                Util.guard(config.Callback, list)
            end
            -- keep the menu open for multi-select, but refresh the check marks
            if Popover.Current then
                for _, row in ipairs(Popover.Current.Rows or {}) do
                    local selected = self.Values[row.Option.Value] == true
                    row.Selected = selected
                    if row.Root.MarkFill then
                        row.Root.MarkFill.BackgroundTransparency = selected and 0 or 1
                        row.Root.MarkCheck.Visible = selected
                    end
                    row.Label.TextColor3 = selected and Theme.Color.Text or Theme.Color.TextSecondary
                end
            end
        else
            local changed = self.Value ~= option.Value
            self.Value = option.Value
            self:Apply()
            Popover.Close()
            if changed and config.Callback then
                Util.guard(config.Callback, option.Value)
            end
        end
    end

    -- Re-publishing options never silently drops a still-valid selection.
    function dropdown:SetOptions(options, resetSelection)
        self.Options = self:Normalize(options)
        if self.Multi then
            local pruned = {}
            for value in pairs(self.Values) do
                if self:Find(value) then
                    pruned[value] = true
                end
            end
            self.Values = pruned
        elseif resetSelection == true or (self.Value ~= nil and not self:Find(self.Value)) then
            self.Value = self.Options[1] and self.Options[1].Value or nil
        elseif self.Value == nil then
            self.Value = self.Options[1] and self.Options[1].Value or nil
        end
        self:Apply()
    end

    function dropdown:SetValue(value, silent)
        if self.Multi then
            local values = {}
            if type(value) == "table" then
                for _, entry in ipairs(value) do
                    values[entry] = true
                end
            elseif value ~= nil then
                values[value] = true
            end
            self.Values = values
            self:Apply()
            if not silent and config.Callback then
                Util.guard(config.Callback, value)
            end
            return
        end
        if self.Value == value then
            return
        end
        self.Value = value
        self:Apply()
        if not silent and config.Callback then
            Util.guard(config.Callback, value)
        end
    end

    function dropdown:Get()
        if self.Multi then
            local list = {}
            for index, entry in ipairs(self.Options) do
                if self.Values[entry.Value] then
                    table.insert(list, entry.Value)
                end
            end
            return list
        end
        return self.Value
    end
    function dropdown:Set(value, silent) return self:SetValue(value, silent) end
    function dropdown:SetDisabled(value)
        self.Disabled = value == true
        self.Root.Active = not self.Disabled
        if self.Disabled then
            Popover.Close()
        end
        self:Apply()
    end
    function dropdown:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end
    function dropdown:SetText(value)
        self.Label.Text = Util.text(value, 64)
    end
    function dropdown:Close()
        if self.IsOpen then
            Popover.Close()
        end
    end

    function dropdown:Destroy()
        Components.Unregister(self)
        if self.IsOpen then
            Popover.Close(true)
        end
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    scope:Connect(dropdown.Root.MouseEnter, function()
        dropdown.Hovered = true
        dropdown:Apply()
    end)
    scope:Connect(dropdown.Root.MouseLeave, function()
        dropdown.Hovered = false
        dropdown:Apply()
    end)
    scope:Connect(dropdown.Root.Activated, function()
        if dropdown.Disabled then return end
        if dropdown.IsOpen then
            Popover.Close()
        else
            dropdown:Open()
        end
    end)
    if config.Tooltip then
        Tooltip.Attach(scope, dropdown.Root, config.Tooltip)
    end
    dropdown:SetOptions(config.Options or {})
    if config.Default ~= nil then
        dropdown:SetValue(config.Default, true)
    elseif #dropdown.Options > 0 and not multi then
        dropdown:SetValue(dropdown.Options[1].Value, true)
    elseif config.Defaults ~= nil then
        dropdown:SetValue(config.Defaults, true)
    end
    dropdown:Apply()
    return Components.Register(dropdown)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Textbox / SearchBox — focus stroke, enter submit, numeric clamp.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Textbox(scope, parent, config)
    config = config or {}
    local textbox = {
        Scope = scope,
        Disabled = false,
        Visible = true,
        Focused = false,
        Numeric = config.Numeric == true,
        Height = config.Height or 46,
        Value = tostring(config.Default ~= nil and config.Default or ""),
    }
    textbox.Root = Prim.frame(parent, config.Name or "Textbox", Theme.Color.Surface)
    textbox.Root.BackgroundTransparency = 1
    textbox.Root.Size = UDim2.new(1, 0, 0, textbox.Height)

    local full = config.Full == true
    local hasLabel = config.Name ~= nil and config.Name ~= ""
    textbox.HasLabel = hasLabel
    textbox.Full = full
    textbox.Label = Prim.label(textbox.Root, "Label", Util.text(config.Name or "", 64), Theme.Type.Body, Theme.Color.Text, Theme.Font.Medium)
    textbox.Label.Visible = hasLabel

    textbox.Field = Prim.frame(textbox.Root, "Field", Theme.Color.Input)
    if full then
        textbox.Field.Size = UDim2.new(1, 0, 0, 40)
        textbox.Field.Position = UDim2.fromOffset(0, hasLabel and 24 or 0)
    else
        textbox.Field.AnchorPoint = Vector2.new(1, 0.5)
        textbox.Field.Position = UDim2.new(1, -Theme.Space.L, 0.5, 0)
        textbox.Field.Size = UDim2.fromOffset(190, 34)
        Prim.place(textbox.Label, Theme.Space.L, 0, 200, textbox.Height)
        textbox.Label.Size = UDim2.new(0.42, -Theme.Space.L, 1, 0)
    end
    Prim.corner(textbox.Field, Theme.Radius.Small)
    textbox.FieldStroke = Prim.stroke(textbox.Field, Theme.Color.StrokeStrong, 1, 0.75)

    local iconOffset = 0
    if config.Icon then
        textbox.Icon = Prim.Icon.new(textbox.Field, config.Icon, Theme.Color.TextMuted, 13, 1.5)
        textbox.Icon.Root.AnchorPoint = Vector2.new(0, 0.5)
        textbox.Icon.Root.Position = UDim2.new(0, 10, 0.5, 0)
        iconOffset = 20
    end
    textbox.Input = Prim.new("TextBox", {
        Name = "Input",
        Text = textbox.Value,
        PlaceholderText = Util.text(config.Placeholder or "", 40),
        PlaceholderColor3 = Theme.Color.TextMuted,
        TextColor3 = Theme.Color.Text,
        TextSize = Theme.Type.Small,
        Font = config.Mono and Theme.Font.Mono or Theme.Font.Regular,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        MultiLine = false,
        ClipsDescendants = true,
        Size = UDim2.new(1, -(20 + iconOffset), 1, 0),
        Position = UDim2.fromOffset(10 + iconOffset, 0),
    }, textbox.Field)

    function textbox:Apply()
        local focused = self.Focused and not self.Disabled
        Anim.To(self.Field, {
            BackgroundColor3 = focused and Theme.Color.InputFocus or Theme.Color.Input,
            BackgroundTransparency = self.Disabled and 0.5 or 0,
        }, Motion.Micro)
        Anim.To(self.FieldStroke, {
            Color = focused and Theme.Color.Accent or Theme.Color.StrokeStrong,
            Transparency = self.Disabled and 1 or (focused and 0.35 or 0.75),
        }, Motion.Micro)
        if self.Icon then
            self.Icon:SetColor(focused and Theme.Color.Accent or Theme.Color.TextMuted)
        end
        self.Label.TextColor3 = self.Disabled and Theme.Color.TextMuted or Theme.Color.Text
        self.Input.TextEditable = not self.Disabled
        self.Input.Active = not self.Disabled
    end

    function textbox:Commit()
        local raw = self.Input.Text
        if self.Numeric then
            local number = Util.finite(tonumber(raw), nil)
            if number == nil then
                number = Util.finite(tonumber(config.Default), 0)
            end
            if config.Min then
                number = math.max(config.Min, number)
            end
            if config.Max then
                number = math.min(config.Max, number)
            end
            if config.Round then
                number = Util.round(number)
            end
            raw = tostring(number)
            if self.Input.Text ~= raw then
                self.Input.Text = raw
            end
        end
        if raw ~= self.Value then
            self.Value = raw
            if config.Callback then
                Util.guard(config.Callback, self.Numeric and tonumber(raw) or raw)
            end
        end
    end

    function textbox:SetValue(value, silent)
        local text = tostring(value == nil and "" or value)
        self.Value = text
        self.Input.Text = text
        if not silent and config.Callback then
            Util.guard(config.Callback, self.Numeric and tonumber(text) or text)
        end
    end
    function textbox:Get()
        if self.Numeric then
            return tonumber(self.Input.Text) or tonumber(self.Value)
        end
        return self.Input.Text
    end
    function textbox:Set(value, silent) return self:SetValue(value, silent) end
    function textbox:SetDisabled(value)
        self.Disabled = value == true
        if self.Disabled and self.Focused then
            self.Input:ReleaseFocus(false)
        end
        self:Apply()
    end
    function textbox:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end
    function textbox:SetText(value)
        self.Label.Text = Util.text(value, 64)
    end
    function textbox:Destroy()
        Components.Unregister(self)
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    scope:Connect(textbox.Input.Focused, function()
        textbox.Focused = true
        textbox:Apply()
    end)
    scope:Connect(textbox.Input.FocusLost, function(enterPressed)
        textbox.Focused = false
        textbox:Apply()
        if enterPressed then
            textbox:Commit()
        end
    end)
    scope:Connect(textbox.Input:GetPropertyChangedSignal("Text"), function()
        if config.Live and config.Callback then
            Util.guard(config.Callback, textbox.Input.Text)
        end
    end)
    if config.Tooltip then
        Tooltip.Attach(scope, textbox.Root, config.Tooltip)
    end
    textbox:Apply()
    return Components.Register(textbox)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Keybind — click to capture, escape cancels, stored EnumItem.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Keybind(scope, parent, config)
    config = config or {}
    local keybind = {
        Scope = scope,
        Disabled = false,
        Visible = true,
        Capturing = false,
        Key = config.Default or Enum.KeyCode.F,
        Height = config.Height or Theme.Metric.RowHeight,
    }
    keybind.Root = Prim.frame(parent, config.Name or "Keybind", Theme.Color.Surface)
    keybind.Root.BackgroundTransparency = 1
    keybind.Root.Size = UDim2.new(1, 0, 0, keybind.Height)
    keybind.Label = Prim.label(keybind.Root, "Label", Util.text(config.Name or "", 64), Theme.Type.Body, Theme.Color.Text, Theme.Font.Medium)
    Prim.place(keybind.Label, Theme.Space.L, 0, 200, keybind.Height)
    keybind.Label.Size = UDim2.new(0.5, 0, 1, 0)
    keybind.Chip = Prim.new("TextButton", {
        Name = "KeyChip",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.SurfaceInteractive,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(96, 26),
        Position = UDim2.fromOffset(0, 0),
        Active = true,
        Selectable = true,
    }, keybind.Root)
    keybind.Chip.AnchorPoint = Vector2.new(1, 0.5)
    keybind.Chip.Position = UDim2.new(1, -Theme.Space.L, 0.5, 0)
    Prim.corner(keybind.Chip, Theme.Radius.Small)
    keybind.Stroke = Prim.stroke(keybind.Chip, Theme.Color.Stroke, 1, 0.5)
    keybind.ChipLabel = Prim.label(keybind.Chip, "Key", "", Theme.Type.Small, Theme.Color.TextSecondary, Theme.Font.Medium)
    keybind.ChipLabel.TextXAlignment = Enum.TextXAlignment.Center
    keybind.ChipLabel.Size = UDim2.fromScale(1, 1)

    function keybind:KeyName()
        if self.Capturing then
            return "Press a key"
        end
        if self.Key == nil then
            return "None"
        end
        return tostring(self.Key.Name or self.Key)
    end

    function keybind:Apply()
        self.ChipLabel.Text = self:KeyName()
        self.ChipLabel.TextColor3 = self.Capturing and Theme.Color.Accent or (self.Disabled and Theme.Color.TextMuted or Theme.Color.Text)
        Anim.To(self.Chip, {
            BackgroundColor3 = self.Capturing and Theme.Color.SurfaceHover or Theme.Color.SurfaceInteractive,
            BackgroundTransparency = self.Disabled and 0.6 or 0,
        }, Motion.Micro)
        Anim.To(self.Stroke, { Transparency = self.Capturing and 0.2 or 0.5 }, Motion.Micro)
        self.Chip.Active = not self.Disabled
    end

    function keybind:SetCapturing(value)
        self.Capturing = value == true
        self:Apply()
    end

    function keybind:SetValue(key, silent)
        if key == self.Key then
            return
        end
        self.Key = key
        self:Apply()
        if not silent and config.Callback then
            Util.guard(config.Callback, key)
        end
    end
    function keybind:Get() return self.Key end
    function keybind:Set(value, silent) return self:SetValue(value, silent) end
    function keybind:SetDisabled(value)
        self.Disabled = value == true
        if self.Disabled then
            self.Capturing = false
        end
        self:Apply()
    end
    function keybind:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end
    function keybind:SetText(value)
        self.Label.Text = Util.text(value, 64)
    end
    function keybind:Destroy()
        Components.Unregister(self)
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    scope:Connect(keybind.Chip.Activated, function()
        if keybind.Disabled then return end
        keybind:SetCapturing(not keybind.Capturing)
    end)
    scope:Connect(UserInputService.InputBegan, function(input, gameProcessed)
        if not keybind.Capturing or keybind.Disabled then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if input.KeyCode == Enum.KeyCode.Escape then
            keybind:SetCapturing(false)
            return
        end
        keybind:SetCapturing(false)
        keybind:SetValue(input.KeyCode)
    end)
    scope:Connect(keybind.Chip.MouseEnter, function()
        if keybind.Disabled then return end
        Anim.To(keybind.Chip, { BackgroundColor3 = Theme.Color.SurfaceHover }, Motion.Micro)
    end)
    scope:Connect(keybind.Chip.MouseLeave, function()
        if keybind.Disabled then return end
        keybind:Apply()
    end)
    if config.Tooltip then
        Tooltip.Attach(scope, keybind.Chip, config.Tooltip)
    end
    keybind:Apply()
    return Components.Register(keybind)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SelectRow — label + value + chevron that opens a popover list (settings pattern).
-- ══════════════════════════════════════════════════════════════════════════════

function Components.SelectRow(scope, parent, config)
    config = config or {}
    local select = {
        Scope = scope,
        Disabled = false,
        Visible = true,
        Options = {},
        Height = config.Height or Theme.Metric.RowHeight,
    }
    select.Root = Prim.new("TextButton", {
        Name = config.Name or "SelectRow",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.SurfaceRaised,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, select.Height),
        Active = true,
        Selectable = true,
    }, parent)
    Prim.corner(select.Root, Theme.Radius.Small)
    select.Label = Prim.label(select.Root, "Label", Util.text(config.Name or "", 40), Theme.Type.Small, Theme.Color.TextMuted, Theme.Font.Medium)
    Prim.place(select.Label, Theme.Space.L, 0, 120, select.Height)
    select.Label.Size = UDim2.new(0.45, -Theme.Space.L, 1, 0)
    select.ValueLabel = Prim.label(select.Root, "Value", "", Theme.Type.Small, Theme.Color.Text, Theme.Font.Bold)
    select.ValueLabel.AnchorPoint = Vector2.new(1, 0.5)
    select.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    select.ValueLabel.Position = UDim2.new(1, -30, 0.5, 0)
    select.ValueLabel.Size = UDim2.fromOffset(140, select.Height)
    select.Chevron = Prim.Icon.new(select.Root, "chevron", Theme.Color.TextMuted, 11, 1.5)
    select.Chevron.Root.AnchorPoint = Vector2.new(1, 0.5)
    select.Chevron.Root.Position = UDim2.new(1, -11, 0.5, 0)

    function select:SetOptions(options)
        self.Options = {}
        for index, option in ipairs(options or {}) do
            if type(option) == "table" then
                table.insert(self.Options, { Value = option.Value, Text = tostring(option.Text), Disabled = option.Disabled == true })
            else
                table.insert(self.Options, { Value = option, Text = tostring(option) })
            end
        end
        if self.Value == nil and self.Options[1] then
            self:SetValue(self.Options[1].Value, true)
        end
    end

    function select:Apply()
        local text = self.Value ~= nil and tostring(self.Value) or "—"
        for _, option in ipairs(self.Options) do
            if option.Value == self.Value then
                text = option.Text
                break
            end
        end
        self.ValueLabel.Text = text
        self.Label.TextColor3 = self.Disabled and Theme.Color.TextMuted or Theme.Color.TextMuted
        self.ValueLabel.TextColor3 = self.Disabled and Theme.Color.TextMuted or Theme.Color.Text
        Anim.To(self.Root, {
            BackgroundColor3 = self.Hovered and Theme.Color.SurfaceHover or Theme.Color.SurfaceRaised,
            BackgroundTransparency = self.Disabled and 0.6 or 0,
        }, Motion.Micro)
    end

    function select:Open()
        if self.Disabled then return end
        Popover.Open({
            Anchor = self.Root,
            Width = math.max(160, self.Root.AbsoluteSize.X),
            Height = math.min(320, #self.Options * 34 + 12),
            MaxHeight = 340,
            Fill = function(menu, body, width)
                local y = 4
                for _, option in ipairs(self.Options) do
                    local selected = option.Value == self.Value
                    local row = Prim.new("TextButton", {
                        Name = "Option",
                        Text = "",
                        AutoButtonColor = false,
                        BackgroundTransparency = 1,
                        BackgroundColor3 = Theme.Color.SurfaceRaised,
                        BorderSizePixel = 0,
                        Size = UDim2.fromOffset(width, 32),
                        Position = UDim2.fromOffset(4, y),
                        Active = not option.Disabled,
                        Selectable = not option.Disabled,
                    }, body)
                    Prim.corner(row, Theme.Radius.Small)
                    local label = Prim.label(row, "Text", Util.text(option.Text, 34), Theme.Type.Small, option.Disabled and Theme.Color.TextMuted or (selected and Theme.Color.Text or Theme.Color.TextSecondary), selected and Theme.Font.Medium or Theme.Font.Regular)
                    Prim.place(label, 12, 0, width - 40, 32)
                    if selected then
                        local check = Prim.Icon.new(row, "check", Theme.Color.Accent, 11, 1.7)
                        check.Root.AnchorPoint = Vector2.new(1, 0.5)
                        check.Root.Position = UDim2.new(1, -12, 0.5, 0)
                    end
                    if not option.Disabled then
                        menu.Scope:Connect(row.MouseEnter, function()
                            Anim.To(row, { BackgroundTransparency = 0.78 }, Motion.Micro)
                        end)
                        menu.Scope:Connect(row.MouseLeave, function()
                            Anim.To(row, { BackgroundTransparency = 1 }, Motion.Micro)
                        end)
                        menu.Scope:Connect(row.Activated, function()
                            Popover.Close()
                            self:SetValue(option.Value)
                        end)
                    end
                    y = y + 34
                end
                body.Size = UDim2.new(1, 0, 0, y + 4)
            end,
        })
    end

    function select:SetValue(value, silent)
        if value == self.Value then return end
        self.Value = value
        self:Apply()
        if not silent and config.Callback then
            Util.guard(config.Callback, value)
        end
    end
    function select:Get() return self.Value end
    function select:Set(value, silent) return self:SetValue(value, silent) end
    function select:SetDisabled(value)
        self.Disabled = value == true
        self.Root.Active = not self.Disabled
        self:Apply()
    end
    function select:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end
    function select:SetText(value)
        self.Label.Text = Util.text(value, 40)
    end
    function select:Destroy()
        Components.Unregister(self)
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    scope:Connect(select.Root.MouseEnter, function() select.Hovered = true; select:Apply() end)
    scope:Connect(select.Root.MouseLeave, function() select.Hovered = false; select:Apply() end)
    scope:Connect(select.Root.Activated, function() select:Open() end)
    select:SetOptions(config.Options or {})
    if config.Default ~= nil then
        select:SetValue(config.Default, true)
    end
    select:Apply()
    return Components.Register(select)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Stat / MetadataGrid — muted label + value pairs aligned in columns.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Stat(scope, parent, config)
    config = config or {}
    local stat = { Scope = scope, Root = Prim.frame(parent, "Stat", Theme.Color.Surface) }
    stat.Root.BackgroundTransparency = 1
    stat.Label = Prim.label(stat.Root, "Label", Util.text(config.Label or "", 30), Theme.Type.Micro, Theme.Color.TextMuted)
    stat.Value = Prim.label(stat.Root, "Value", Util.text(config.Value or "", 30), Theme.Type.Small, Theme.Color.Text, Theme.Font.Medium)
    stat.Value.TextWrapped = true
    stat.Value.TextYAlignment = Enum.TextYAlignment.Top
    function stat:Layout(width)
        local labelWidth = math.floor(width * 0.58)
        Prim.place(self.Label, 0, 1, labelWidth, 16)
        local valueHeight = math.max(16, Util.measureHeight(self.Value.Text, Theme.Type.Small, Theme.Font.Medium, width - labelWidth - 6))
        Prim.place(self.Value, labelWidth + 6, 0, width - labelWidth - 6, valueHeight)
        self.Height = math.max(18, valueHeight + 2)
        self.Root.Size = UDim2.fromOffset(width, self.Height)
        return self.Height
    end
    function stat:SetValue(value)
        self.Value.Text = Util.text(value, 30)
    end
    function stat:Destroy()
        self.Root:Destroy()
    end
    return stat
end

function Components.MetadataGrid(scope, parent, config)
    config = config or {}
    local grid = { Scope = scope, Items = {}, Columns = config.Columns or 3 }
    grid.Root = Prim.frame(parent, "MetadataGrid", Theme.Color.Surface)
    grid.Root.BackgroundTransparency = 1
    for _, entry in ipairs(config.Items or {}) do
        table.insert(grid.Items, Components.Stat(scope, grid.Root, entry))
    end
    function grid:Add(item)
        local stat = Components.Stat(self.Scope, self.Root, item)
        table.insert(self.Items, stat)
        return stat
    end
    function grid:Layout(width)
        local columns = self.Columns
        if width < 340 then
            columns = 1
        elseif width < 560 then
            columns = math.min(2, self.Columns)
        end
        local gap = 14
        local cellWidth = (width - gap * (columns - 1)) / columns
        local y = 0
        local rowHeight = 0
        for index, stat in ipairs(self.Items) do
            local column = (index - 1) % columns
            if column == 0 then
                y = y + rowHeight + (index > 1 and 10 or 0)
                rowHeight = 0
            end
            local height = stat:Layout(cellWidth)
            Prim.place(stat.Root, column * (cellWidth + gap), y, cellWidth, height)
            rowHeight = math.max(rowHeight, height)
        end
        self.Height = y + rowHeight
        self.Root.Size = UDim2.fromOffset(width, self.Height)
        return self.Height
    end
    function grid:Destroy()
        for _, stat in ipairs(self.Items) do
            stat:Destroy()
        end
        self.Root:Destroy()
    end
    grid.Height = 0
    return grid
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Artwork — procedural cover compositions (no assets required) with an optional
-- real image that fades in when it loads. Two tones: mono (resting) / accent (hover).
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Artwork(scope, parent, config)
    config = config or {}
    local art = { Scope = scope, Tone = config.Tone or "mono" }
    art.Root = Prim.frame(parent, "Artwork", Theme.Art.mono.base)
    art.Root.ClipsDescendants = true
    Prim.corner(art.Root, config.Radius or Theme.Radius.Medium)

    art.Base = Prim.frame(art.Root, "Base", Theme.Art.mono.base)
    art.Base.Size = UDim2.fromScale(1, 1)
    Prim.corner(art.Base, config.Radius or Theme.Radius.Medium)

    -- diagonal light plane
    art.Plane = Prim.frame(art.Root, "Plane", Theme.Art.mono.orb2)
    art.Plane.AnchorPoint = Vector2.new(0.5, 0.5)
    art.Plane.Size = UDim2.fromScale(1.6, 0.5)
    art.Plane.Position = UDim2.fromScale(0.5, 0.62)
    art.Plane.Rotation = -18
    art.Plane.BackgroundTransparency = 0.55

    -- orb cluster
    art.Orb = Prim.frame(art.Root, "Orb", Theme.Art.mono.orb)
    art.Orb.AnchorPoint = Vector2.new(0.5, 0.5)
    art.Orb.Size = UDim2.fromScale(0.62, 0.62)
    art.Orb.Position = UDim2.fromScale(config.Focus and config.Focus.X or 0.62, config.Focus and config.Focus.Y or 0.42)
    Prim.corner(art.Orb, 100)
    art.Orb.BackgroundTransparency = 0.15
    Prim.gradient(art.Orb, { Theme.Art.mono.orb, Theme.Art.mono.orb2 }, 120)

    art.OrbSmall = Prim.frame(art.Root, "OrbSmall", Theme.Art.mono.orb2)
    art.OrbSmall.AnchorPoint = Vector2.new(0.5, 0.5)
    art.OrbSmall.Size = UDim2.fromScale(0.3, 0.3)
    art.OrbSmall.Position = UDim2.fromScale(0.32, 0.68)
    Prim.corner(art.OrbSmall, 100)
    art.OrbSmall.BackgroundTransparency = 0.35

    -- diagonal stripes (echo of the reference's platform card texture, original geometry)
    art.Stripes = {}
    for index = 1, 4 do
        local stripe = Prim.frame(art.Root, "Stripe" .. index, Theme.Art.mono.stripe)
        stripe.AnchorPoint = Vector2.new(0.5, 0.5)
        stripe.Size = UDim2.fromScale(0.02, 1.6)
        stripe.Position = UDim2.fromScale(0.12 + index * 0.2, 0.5)
        stripe.Rotation = 22
        stripe.BackgroundTransparency = 0.94
        art.Stripes[index] = stripe
    end

    -- monogram
    art.Mark = Prim.label(art.Root, "Mark", Util.text(config.Mark or "", 2), config.MarkSize or 46, Theme.Art.mono.mark, Theme.Font.Bold)
    art.Mark.TextXAlignment = Enum.TextXAlignment.Left
    art.Mark.TextYAlignment = Enum.TextYAlignment.Bottom
    art.Mark.TextTransparency = 0.5
    Prim.place(art.Mark, 14, 0, 120, 70)

    -- vignette keeps text readable over artwork
    art.Vignette = Prim.frame(art.Root, "Vignette", Color3.new(0, 0, 0))
    art.Vignette.Size = UDim2.fromScale(1, 1)
    art.Vignette.BackgroundTransparency = 0.1
    Prim.new("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.35),
            NumberSequenceKeypoint.new(0.55, 0.85),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, art.Vignette)

    if config.Image then
        art.Image = Prim.new("ImageLabel", {
            Name = "Image",
            BackgroundTransparency = 1,
            Image = config.Image,
            ImageTransparency = 1,
            ScaleType = Enum.ScaleType.Crop,
            Size = UDim2.fromScale(1, 1),
        }, art.Root)
        Prim.corner(art.Image, config.Radius or Theme.Radius.Medium)
        if art.Image.IsLoaded then
            art.Image.ImageTransparency = 0
        else
            scope:Connect(art.Image:GetPropertyChangedSignal("IsLoaded"), function()
                if art.Image.IsLoaded then
                    Anim.To(art.Image, { ImageTransparency = 0 }, Motion.Fast)
                end
            end)
        end
    end

    function art:SetTone(tone, animate)
        tone = Theme.Art[tone] and tone or "mono"
        if self.Tone == tone then
            return
        end
        self.Tone = tone
        local palette = Theme.Art[tone]
        local info = animate and Motion.Fast or Motion.Instant
        Anim.To(self.Base, { BackgroundColor3 = palette.base }, info)
        Anim.To(self.Plane, { BackgroundColor3 = palette.orb2 }, info)
        Anim.To(self.Orb, { BackgroundColor3 = palette.orb }, info)
        Anim.To(self.OrbSmall, { BackgroundColor3 = palette.orb2 }, info)
        local orbGradient = self.Orb:FindFirstChildOfClass("UIGradient")
        if orbGradient then
            Anim.Snap(orbGradient, { Color = ColorSequence.new(palette.orb, palette.orb2) })
        end
        for _, stripe in ipairs(self.Stripes) do
            Anim.To(stripe, { BackgroundTransparency = palette.stripeAlpha }, info)
        end
        if self.Mark.Text ~= "" then
            Anim.To(self.Mark, { TextColor3 = palette.mark, TextTransparency = palette.markAlpha }, info)
        end
    end

    function art:Destroy()
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end
    art:SetTone(config.Tone or "mono", false)
    return art
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Hero — editorial headline with accent words, supporting copy, artwork.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Hero(scope, parent, config)
    config = config or {}
    local hero = { Scope = scope }
    hero.Root = Prim.group(parent, "Hero")
    hero.Root.BackgroundTransparency = 1
    hero.Height = config.Height or 200

    hero.Art = Components.Artwork(scope, hero.Root, {
        Tone = "accent",
        Focus = Vector2.new(0.66, 0.4),
        Radius = Theme.Radius.Large,
        Mark = config.Mark,
        MarkSize = 120,
        Image = config.Image,
    })
    hero.Art.Root.BackgroundTransparency = 1
    hero.Art.Root.ClipsDescendants = true

    hero.Text = Prim.frame(hero.Root, "Text", Theme.Color.Surface)
    hero.Text.BackgroundTransparency = 1

    -- headline lines: { { text = "...", accent = true }, ... } or a plain string
    hero.Lines = {}
    local lines = config.Headline or {}
    if type(lines) == "string" then
        lines = { { text = lines } }
    end
    for index, line in ipairs(lines) do
        local label = Prim.label(hero.Text, "Line" .. index, "", config.HeadlineSize or Theme.Type.Display, Theme.Color.Text, Theme.Font.Bold)
        label.TextWrapped = true
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.RichText = false
        hero.Lines[index] = label
    end
    hero.Copy = Prim.label(hero.Text, "Copy", Util.text(config.Copy or "", 220), config.CopySize or Theme.Type.Small, Theme.Color.TextSecondary)
    hero.Copy.TextWrapped = true
    hero.Copy.TextYAlignment = Enum.TextYAlignment.Top
    hero.Copy.TextTruncate = Enum.TextTruncate.AtEnd

    function hero:Layout(width, compact)
        local height = config.Height or (compact and 236 or 196)
        self.Height = height
        self.Root.Size = UDim2.fromOffset(width, height)
        local textWidth = compact and width or math.floor(width * 0.58)
        Prim.place(self.Text, 0, compact and 0 or 4, textWidth, height)
        -- artwork occupies the right side; on compact it sits behind the copy
        if compact then
            Prim.place(self.Art.Root, 0, 0, width, height)
            self.Art.Root.BackgroundTransparency = 0.35
        else
            Prim.place(self.Art.Root, math.floor(width * 0.56), 0, math.floor(width * 0.44), height)
            self.Art.Root.BackgroundTransparency = 0
        end
        local y = 0
        local size = config.HeadlineSize or Theme.Type.Display
        if compact then
            size = math.min(size, 24)
        end
        for index, line in ipairs(self.Lines) do
            local spec = config.Headline[index]
            local text = type(spec) == "table" and (spec.Text or spec.text) or tostring(spec)
            line.Text = Util.text(text, 60)
            line.TextSize = size
            line.TextColor3 = (type(spec) == "table" and spec.Accent) and Theme.Color.Accent or Theme.Color.Text
            local lineHeight = math.max(size, Util.measureHeight(text, size, Theme.Font.Bold, textWidth))
            Prim.place(line, 0, y, textWidth, lineHeight + 2)
            y = y + lineHeight + (size > 24 and 2 or 1)
        end
        y = y + 8
        local copyText = self.Copy.Text
        if copyText ~= "" then
            local copyHeight = math.max(15, Util.measureHeight(copyText, config.CopySize or Theme.Type.Small, Theme.Font.Regular, textWidth))
            Prim.place(self.Copy, 0, y, textWidth, math.min(copyHeight, 46))
            y = y + math.min(copyHeight, 46)
        end
        self.Copy.Visible = copyText ~= ""
        self.ContentHeight = y
        return height
    end

    function hero:SetHeadline(lines)
        config.Headline = lines
        for _, line in ipairs(self.Lines) do
            line:Destroy()
        end
        self.Lines = {}
        for index, line in ipairs(lines) do
            local label = Prim.label(self.Text, "Line" .. index, "", config.HeadlineSize or Theme.Type.Display, Theme.Color.Text, Theme.Font.Bold)
            label.TextWrapped = true
            label.TextYAlignment = Enum.TextYAlignment.Top
            self.Lines[index] = label
        end
        self:Layout(self.Width or 600, self.Compact)
    end

    function hero:SetCopy(value)
        self.Copy.Text = Util.text(value, 220)
        self:Layout(self.Width or 600, self.Compact)
    end

    function hero:SetVisible(value)
        self.Root.Visible = value ~= false
    end

    function hero:Destroy()
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end
    hero:Layout(config.Width or 600)
    return hero
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Card — flexible surface: media, chip, title, copy, footer, action buttons.
-- Variants: photo (cover + caption), color (flat tone), gradient (aurora), plain.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Card(scope, parent, config)
    config = config or {}
    local card = { Scope = scope, Hovered = false, Pressed = false, Visible = true }
    card.Variant = config.Variant or "plain"
    card.Root = Prim.new("TextButton", {
        Name = config.Name or "Card",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.Surface,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Active = config.Interactive ~= false,
        Selectable = config.Interactive ~= false,
    }, parent)
    Prim.corner(card.Root, Theme.Radius.Medium)
    card.Stroke = Prim.stroke(card.Root, Theme.Color.Stroke, 1, 0.35)
    card.Dim = Prim.frame(card.Root, "Dim", Theme.Color.Shadow)
    card.Dim.Size = UDim2.fromScale(1, 1)
    card.Dim.BackgroundTransparency = 1
    card.Dim.ZIndex = 8

    if card.Variant == "gradient" then
        local gradientFill = Prim.frame(card.Root, "Fill", Theme.Color.White)
        gradientFill.Size = UDim2.fromScale(1, 1)
        gradientFill.ZIndex = 0
        Prim.corner(gradientFill, Theme.Radius.Medium)
        Prim.aurora(gradientFill, scope, 0)
        card.Fill = gradientFill
        card.Stroke.Transparency = 0.8
    elseif card.Variant == "color" then
        card.Root.BackgroundColor3 = config.Tone or Theme.Color.SurfaceRaised
        card.Stroke.Transparency = 0.85
    end

    if card.Variant == "photo" or card.Variant == "art" then
        card.Art = Components.Artwork(scope, card.Root, {
            Tone = config.Tone == "accent" and "accent" or "mono",
            Image = config.Image,
            Mark = config.Mark,
            Radius = Theme.Radius.Medium,
        })
        card.Art.Root.Size = UDim2.fromScale(1, 1)
    end

    card.Content = Prim.frame(card.Root, "Content", Theme.Color.Surface)
    card.Content.BackgroundTransparency = 1
    card.Content.Size = UDim2.fromScale(1, 1)
    card.Content.ZIndex = 2

    if config.Chip then
        card.Chip = Components.Badge(scope, card.Content, {
            Text = config.Chip,
            Type = config.ChipType or "neutral",
            Icon = config.ChipIcon,
        })
        card.Chip.Root.ZIndex = 4
    end

    if config.Title then
        card.Title = Prim.label(card.Content, "Title", Util.text(config.Title, 40), config.TitleSize or Theme.Type.Subtitle, Theme.Color.Text, Theme.Font.Bold)
        card.Title.TextWrapped = true
        card.Title.TextYAlignment = Enum.TextYAlignment.Top
        card.Title.TextTruncate = Enum.TextTruncate.AtEnd
    end
    if config.Text then
        card.Text = Prim.label(card.Content, "Text", Util.text(config.Text, 160), config.TextSize or Theme.Type.Small, config.TextColor or Theme.Color.TextSecondary)
        card.Text.TextWrapped = true
        card.Text.TextYAlignment = Enum.TextYAlignment.Top
        card.Text.TextTruncate = Enum.TextTruncate.AtEnd
    end
    if config.Pill then
        card.Pill = Components.Badge(scope, card.Content, { Text = config.Pill, Type = config.PillType or "neutral" })
        card.Pill.Root.ZIndex = 4
    end
    if config.Arrow ~= false and config.Interactive ~= false and card.Variant ~= "photo" then
        card.Arrow = Prim.Icon.new(card.Content, "arrow", Theme.Color.TextMuted, 13, 1.6)
    end
    if config.Actions then
        card.Actions = {}
        for index, action in ipairs(config.Actions) do
            card.Actions[index] = Components.IconButton(scope, card.Content, {
                Icon = action.Icon,
                Tooltip = action.Tooltip,
                Size = 30,
                IconSize = 13,
                Callback = action.Callback,
            })
        end
    end

    function card:Apply()
        if self.Variant == "gradient" then
            Anim.To(self.Dim, { BackgroundTransparency = 1 }, Motion.Micro)
        else
            local transparency = self.Hovered and 0.88 or 1
            Anim.To(self.Dim, { BackgroundTransparency = transparency }, Motion.Fast)
        end
        Anim.To(self.Stroke, { Transparency = self.Disabled and 0.85 or (self.Hovered and 0.1 or 0.35) }, Motion.Micro)
        if self.Arrow then
            Anim.To(self.Arrow.Root, {
                Position = UDim2.fromOffset((self.Width or 200) - (self.Hovered and 18 or 20), (self.Height or 100) - 26),
            }, Motion.Micro)
            self.Arrow:SetColor(self.Hovered and Theme.Color.Text or Theme.Color.TextMuted)
        end
    end

    function card:Layout(width, height)
        self.Width, self.Height = width, height
        self.Root.Size = UDim2.fromOffset(width, height)
        local pad = config.Pad or Theme.Space.L
        if card.Variant == "photo" then
            -- caption block at the bottom over the artwork
            if self.Chip then
                Prim.place(self.Chip.Root, pad, pad, self.Chip.Root.AbsoluteSize.X, 22)
            end
            local footerHeight = 0
            if self.Text then
                local textHeight = math.min(34, Util.measureHeight(self.Text.Text, Theme.Type.Small, Theme.Font.Bold, width - pad * 2 - 40))
                Prim.place(self.Text, pad, height - pad - textHeight - (self.Pill and 26 or 0), width - pad * 2 - 40, textHeight)
                self.Text.TextColor3 = Theme.Color.Text
                self.Text.Visible = true
                footerHeight = textHeight
            end
            if self.Pill then
                Prim.place(self.Pill.Root, pad, height - pad - 22, self.Pill.Root.AbsoluteSize.X, 22)
            end
            if self.Title then
                self.Title.Visible = false
            end
        else
            local y = pad
            if self.Chip then
                Prim.place(self.Chip.Root, pad, y, self.Chip.Root.AbsoluteSize.X, 22)
                y = y + 30
            end
            if self.Title then
                local titleHeight = math.max(18, Util.measureHeight(self.Title.Text, config.TitleSize or Theme.Type.Subtitle, Theme.Font.Bold, width - pad * 2 - 20))
                Prim.place(self.Title, pad, y, width - pad * 2 - 20, titleHeight)
                y = y + titleHeight + 4
            end
            if self.Text then
                local limit = math.max(14, height - y - pad - (self.Pill and 30 or 0) - 4)
                local textHeight = math.min(limit, Util.measureHeight(self.Text.Text, config.TextSize or Theme.Type.Small, Theme.Font.Regular, width - pad * 2 - 20))
                Prim.place(self.Text, pad, y, width - pad * 2 - 20, textHeight)
                y = y + textHeight
            end
            if self.Pill then
                Prim.place(self.Pill.Root, pad, height - pad - 22, self.Pill.Root.AbsoluteSize.X, 22)
            end
            if self.Actions then
                local offset = width - pad
                for index = #self.Actions, 1, -1 do
                    offset = offset - 30
                    Prim.place(self.Actions[index].Root, offset, pad - 2, 30, 30)
                    offset = offset - 4
                end
            end
        end
        self:Apply()
    end

    function card:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end
    function card:SetDisabled(value)
        self.Disabled = value == true
        self.Root.Active = not self.Disabled
        self:Apply()
    end
    function card:SetSelected(value)
        self.Selected = value == true
        if self.Fill then
            Anim.To(self.Fill, { BackgroundTransparency = self.Selected and 0.5 or 1 }, Motion.Fast)
        end
    end
    function card:Destroy()
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    if config.Interactive ~= false then
        scope:Connect(card.Root.MouseEnter, function()
            card.Hovered = true
            if card.Art then
                card.Art:SetTone("accent", true)
            end
            card:Apply()
            if config.OnHover then
                Util.guard(config.OnHover, true)
            end
        end)
        scope:Connect(card.Root.MouseLeave, function()
            card.Hovered = false
            if card.Art then
                card.Art:SetTone(config.Tone == "accent" and "accent" or "mono", true)
            end
            card:Apply()
            if config.OnHover then
                Util.guard(config.OnHover, false)
            end
        end)
        scope:Connect(card.Root.Activated, function()
            if card.Disabled then
                return
            end
            if config.Callback then
                Util.guard(config.Callback, card)
            end
        end)
    end
    if config.Tooltip then
        Tooltip.Attach(scope, card.Root, config.Tooltip)
    end
    return Components.Register(card)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- ProductTile — catalog tile: status corner glyph, artwork, title row + arrow.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.ProductTile(scope, parent, config)
    config = config or {}
    local tile = { Scope = scope, Hovered = false, Visible = true, Loading = false }
    tile.Root = Prim.new("TextButton", {
        Name = config.Name or "Tile",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.Surface,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(180, 230),
        Active = true,
        Selectable = true,
    }, parent)
    Prim.corner(tile.Root, Theme.Radius.Medium)
    tile.Stroke = Prim.stroke(tile.Root, Theme.Color.Stroke, 1, 0.45)
    tile.Dim = Prim.frame(tile.Root, "Dim", Theme.Color.Shadow)
    tile.Dim.Size = UDim2.fromScale(1, 1)
    tile.Dim.BackgroundTransparency = 1
    tile.Dim.ZIndex = 6

    tile.Art = Components.Artwork(scope, tile.Root, {
        Tone = "mono",
        Image = config.Image,
        Mark = config.Mark,
        MarkSize = 64,
        Focus = Vector2.new(0.5, 0.45),
        Radius = Theme.Radius.Medium,
    })
    tile.Art.Root.Size = UDim2.fromScale(1, 1)
    tile.Art.Root.BackgroundTransparency = 1

    -- status glyph in the corner (state indicator, not decoration)
    if config.Status then
        tile.StatusWrap = Prim.frame(tile.Root, "StatusWrap", Theme.Color.Surface)
        tile.StatusWrap.BackgroundTransparency = 0.35
        Prim.corner(tile.StatusWrap, Theme.Radius.Small)
        tile.StatusWrap.ZIndex = 7
        local statusColor = config.Status == "ready" and Theme.Color.Success
            or config.Status == "updating" and Theme.Color.Warning
            or Theme.Color.TextMuted
        tile.StatusIcon = Prim.Icon.new(tile.StatusWrap, config.StatusIcon or (config.Status == "ready" and "check" or config.Status == "updating" and "refresh" or "dot"), statusColor, 10, 1.6)
        tile.StatusIcon.Root.AnchorPoint = Vector2.new(0.5, 0.5)
        tile.StatusIcon.Root.Position = UDim2.fromScale(0.5, 0.5)
    end

    tile.Footer = Prim.frame(tile.Root, "Footer", Theme.Color.Surface)
    tile.Footer.BackgroundTransparency = 1
    tile.Footer.ZIndex = 4
    tile.Title = Prim.label(tile.Footer, "Title", Util.text(config.Title or "", 28), Theme.Type.Small, Theme.Color.Text, Theme.Font.Medium)
    tile.Title.TextTruncate = Enum.TextTruncate.AtEnd
    tile.Subtitle = Prim.label(tile.Footer, "Subtitle", Util.text(config.Subtitle or "", 28), Theme.Type.Micro, Theme.Color.TextMuted)
    tile.Subtitle.TextTruncate = Enum.TextTruncate.AtEnd
    tile.Subtitle.TextYAlignment = Enum.TextYAlignment.Bottom
    tile.Arrow = Prim.Icon.new(tile.Footer, "arrow", Theme.Color.TextMuted, 13, 1.6)

    function tile:Apply()
        local base = self.Hovered and Theme.Color.SurfaceRaised or Theme.Color.Surface
        Anim.To(self.Root, { BackgroundColor3 = base }, Motion.Micro)
        Anim.To(self.Stroke, { Transparency = self.Hovered and 0.15 or 0.45 }, Motion.Micro)
        Anim.To(self.Art.Root, { BackgroundTransparency = self.Loading and 0.4 or 0 }, Motion.Fast)
        if self.Arrow then
            self.Arrow:SetColor(self.Hovered and Theme.Color.Accent or Theme.Color.TextMuted)
        end
    end

    function tile:Layout(width, height)
        self.Width, self.Height = width, height
        self.Root.Size = UDim2.fromOffset(width, height)
        local footerHeight = config.Subtitle and 40 or 30
        Prim.place(self.Footer, 0, height - footerHeight, width, footerHeight)
        Prim.place(self.Title, Theme.Space.L, config.Subtitle and 3 or 6, width - Theme.Space.L * 2 - 20, 17)
        if config.Subtitle then
            Prim.place(self.Subtitle, Theme.Space.L, 20, width - Theme.Space.L * 2 - 20, 16)
        else
            self.Subtitle.Visible = false
        end
        Prim.place(self.Arrow.Root, width - Theme.Space.L - 13, footerHeight / 2 - 8, 13, 13)
        if self.StatusWrap then
            Prim.place(self.StatusWrap, Theme.Space.M, Theme.Space.M, 20, 20)
        end
        self:Apply()
        return height
    end

    function tile:SetLoading(value)
        self.Loading = value == true
        if self.Loading and not self.Skeleton then
            self.Skeleton = Components.Skeleton(scope, self.Root, { Radius = Theme.Radius.Medium })
            self.Skeleton.Root.Size = UDim2.fromScale(1, 1)
            self.Skeleton.Root.ZIndex = 8
        elseif self.Skeleton then
            self.Skeleton:SetVisible(self.Loading)
        end
        self:Apply()
    end

    function tile:SetStatus(status)
        if not self.StatusIcon then
            return
        end
        local color = status == "ready" and Theme.Color.Success or status == "updating" and Theme.Color.Warning or Theme.Color.TextMuted
        self.StatusIcon:SetColor(color)
    end

    function tile:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end

    function tile:Destroy()
        if self.Skeleton then
            self.Skeleton:Destroy()
        end
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    scope:Connect(tile.Root.MouseEnter, function()
        tile.Hovered = true
        tile.Art:SetTone("accent", true)
        tile:Apply()
    end)
    scope:Connect(tile.Root.MouseLeave, function()
        tile.Hovered = false
        tile.Art:SetTone("mono", true)
        tile:Apply()
    end)
    scope:Connect(tile.Root.Activated, function()
        if config.Callback then
            Util.guard(config.Callback, tile)
        end
    end)
    if config.Tooltip then
        Tooltip.Attach(scope, tile.Root, config.Tooltip)
    end
    tile:Apply()
    return Components.Register(tile)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- MediaPreview — 16:9 media panel with optional player chrome.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.MediaPreview(scope, parent, config)
    config = config or {}
    local media = { Scope = scope, Playing = config.Playing ~= false, Progress = Util.finite(config.Progress, 0), Duration = Util.finite(config.Duration, 60), Elapsed = Util.finite(config.Elapsed, 0) }
    media.Root = Prim.frame(parent, "MediaPreview", Theme.Color.SurfaceRaised)
    Prim.corner(media.Root, Theme.Radius.Medium)
    media.Stroke = Prim.stroke(media.Root, Theme.Color.Stroke, 1, 0.4)
    media.Root.ClipsDescendants = true
    media.Art = Components.Artwork(scope, media.Root, {
        Tone = "accent",
        Image = config.Image,
        Mark = config.Mark,
        MarkSize = 90,
        Radius = Theme.Radius.Medium,
    })
    media.Art.Root.Size = UDim2.fromScale(1, 1)
    media.Art.Root.BackgroundTransparency = 1

    media.PlayButton = Prim.new("TextButton", {
        Name = "Play",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.Shadow,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(44, 44),
        Active = true,
        Selectable = true,
        ZIndex = 5,
    }, media.Root)
    Prim.corner(media.PlayButton, 100)
    media.PlayIcon = Prim.Icon.new(media.PlayButton, "play", Theme.Color.Text, 16, 2)
    media.PlayIcon.Root.AnchorPoint = Vector2.new(0.5, 0.5)
    media.PlayIcon.Root.Position = UDim2.fromScale(0.52, 0.5)

    media.Chrome = Prim.frame(media.Root, "Chrome", Theme.Color.Surface)
    media.Chrome.BackgroundTransparency = 1
    media.Chrome.ZIndex = 6
    media.Scrim = Prim.frame(media.Chrome, "Scrim", Color3.new(0, 0, 0))
    media.Scrim.Size = UDim2.fromScale(1, 1)
    media.Scrim.BackgroundTransparency = 0.2
    Prim.new("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.62, 0.92),
            NumberSequenceKeypoint.new(1, 0.45),
        }),
    }, media.Scrim)
    media.PauseGlyph = Prim.Icon.new(media.Chrome, "pause", Theme.Color.Text, 12, 2)
    media.PlayGlyph = Prim.Icon.new(media.Chrome, "play", Theme.Color.Text, 12, 2)
    media.PlayGlyph.Root.Visible = false
    media.Time = Prim.label(media.Chrome, "Time", "0:00 / 1:00", Theme.Type.Micro, Theme.Color.Text, Theme.Font.Medium)
    media.Track = Prim.frame(media.Chrome, "Track", Theme.Color.Text)
    media.Track.BackgroundTransparency = 0.7
    media.Track.Size = UDim2.new(1, -120, 0, 3)
    Prim.corner(media.Track, 100)
    media.Fill = Prim.frame(media.Track, "Fill", Theme.Color.Text)
    media.Fill.Size = UDim2.fromScale(0.4, 1)
    Prim.corner(media.Fill, 100)
    media.Volume = Prim.Icon.new(media.Chrome, "info", Theme.Color.Text, 12, 1.6)
    media.Fullscreen = Prim.Icon.new(media.Chrome, "square", Theme.Color.Text, 12, 1.6)

    function media:Layout(width)
        local height = math.floor(width * (config.Aspect or 0.5625))
        self.Height = height
        self.Width = width
        self.Root.Size = UDim2.fromOffset(width, height)
        self.PlayButton.AnchorPoint = Vector2.new(0.5, 0.5)
        self.PlayButton.Position = UDim2.fromScale(0.5, 0.5)
        Prim.place(self.Chrome, 0, height - 32, width, 32)
        Prim.place(self.Scrim, 0, 0, width, 32)
        Prim.place(self.PauseGlyph.Root, 12, 10, 12, 12)
        Prim.place(self.PlayGlyph.Root, 12, 10, 12, 12)
        Prim.place(self.Time, 30, 0, 90, 32)
        Prim.place(self.Track, 12, height - 6, width - 24, 3)
        Prim.place(self.Volume.Root, width - 44, 10, 12, 12)
        Prim.place(self.Fullscreen.Root, width - 26, 10, 12, 12)
        Anim.Snap(self.Fill, { Size = UDim2.fromScale(self.Progress, 1) })
        return height
    end

    function media:SetProgress(value, elapsed)
        self.Progress = Util.clamp(Util.finite(value, self.Progress), 0, 1)
        Anim.To(self.Fill, { Size = UDim2.fromScale(self.Progress, 1) }, Motion.Fast)
        local total = math.max(1, self.Duration)
        local current = elapsed or (self.Progress * total)
        self.Time.Text = string.format("%d:%02d / %d:%02d", math.floor(current / 60), math.floor(current % 60), math.floor(total / 60), math.floor(total % 60))
    end

    function media:SetPlaying(value)
        self.Playing = value == true
        media.PauseGlyph.Root.Visible = self.Playing
        media.PlayGlyph.Root.Visible = not self.Playing
        media.PlayButton.BackgroundTransparency = self.Playing and 0.72 or 0.35
        media.PlayIcon.Root.Visible = not self.Playing
    end

    scope:Connect(media.PlayButton.MouseEnter, function()
        Anim.To(media.PlayButton, { BackgroundTransparency = 0.15 }, Motion.Micro)
    end)
    scope:Connect(media.PlayButton.MouseLeave, function()
        Anim.To(media.PlayButton, { BackgroundTransparency = media.Playing and 0.72 or 0.35 }, Motion.Micro)
    end)
    scope:Connect(media.PlayButton.Activated, function()
        media:SetPlaying(not media.Playing)
        if config.OnToggle then
            Util.guard(config.OnToggle, media.Playing)
        end
    end)
    media:SetProgress(media.Progress, media.Elapsed)
    media:SetPlaying(media.Playing)
    return Components.Register(media)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Grid — responsive columns over any block factory.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Grid(scope, parent, config)
    config = config or {}
    local grid = { Scope = scope, Items = {}, ColumnWidth = config.ColumnWidth or 168, MaxColumns = config.MaxColumns or 4, Gap = config.Gap or Theme.Space.L }
    grid.Root = Prim.frame(parent, "Grid", Theme.Color.Surface)
    grid.Root.BackgroundTransparency = 1
    grid.Empty = Components.EmptyState(scope, grid.Root, config.Empty or { Title = "Nothing here", Text = "No items to show." })
    grid.Empty.Root.Visible = false

    function grid:Add(item)
        table.insert(self.Items, item)
        return item
    end

    function grid:Columns(width)
        local columns = math.floor((width + self.Gap) / (self.ColumnWidth + self.Gap))
        return Util.clamp(columns, 1, self.MaxColumns)
    end

    function grid:Layout(width)
        local columns = self:Columns(width)
        local cellWidth = math.floor((width - self.Gap * (columns - 1)) / columns)
        local rowHeight = config.RowHeight or math.floor(cellWidth / 0.78)
        local visible = 0
        for index, item in ipairs(self.Items) do
            if item.Visible ~= false then
                visible = visible + 1
            end
        end
        grid.Empty.Root.Visible = visible == 0
        if visible == 0 then
            self.Empty:Layout(width)
            self.Height = self.Empty.Height
            self.Root.Size = UDim2.fromOffset(width, self.Height)
            return self.Height
        end
        local slot = 0
        for _, item in ipairs(self.Items) do
            if item.Visible ~= false then
                local column = slot % columns
                local row = math.floor(slot / columns)
                local height = rowHeight
                if item.Layout then
                    item:Layout(cellWidth, height)
                end
                Prim.place(item.Root, column * (cellWidth + self.Gap), row * (rowHeight + self.Gap), cellWidth, height)
                slot = slot + 1
            end
        end
        local rows = math.ceil(visible / columns)
        self.Height = rows * rowHeight + math.max(0, rows - 1) * self.Gap
        self.Root.Size = UDim2.fromOffset(width, self.Height)
        return self.Height
    end

    function grid:Destroy()
        for _, item in ipairs(self.Items) do
            if item.Destroy then
                item:Destroy()
            end
        end
        self.Empty:Destroy()
        self.Root:Destroy()
    end
    grid.Height = 0
    return grid
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CardRow — asymmetric editorial row (wide + featured + accent panel).
-- ══════════════════════════════════════════════════════════════════════════════

function Components.CardRow(scope, parent, config)
    config = config or {}
    local row = { Scope = scope, Cards = {}, Visible = true }
    row.Root = Prim.frame(parent, "CardRow", Theme.Color.Surface)
    row.Root.BackgroundTransparency = 1
    row.Weights = config.Weights or { 0.42, 0.29, 0.29 }
    row.Footer = Prim.frame(row.Root, "Footer", Theme.Color.Surface)
    row.Footer.BackgroundTransparency = 1
    row.Dots = {}
    if config.Dots then
        for index = 1, config.Dots do
            local dot = Prim.frame(row.Footer, "Dot" .. index, Theme.Color.Text)
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            dot.Size = UDim2.fromOffset(5, 5)
            Prim.corner(dot, 100)
            dot.BackgroundTransparency = index == 1 and 0 or 0.65
            row.Dots[index] = dot
        end
    end

    function row:Add(card)
        table.insert(self.Cards, card)
        return card
    end

    function row:SetDot(index)
        for position, dot in ipairs(self.Dots) do
            local active = position == index
            Anim.To(dot, {
                Size = UDim2.fromOffset(active and 16 or 5, 5),
                BackgroundTransparency = active and 0 or 0.65,
            }, Motion.Fast)
        end
    end

    function row:Layout(width, height, compact)
        self.Width = width
        height = height or config.Height or 152
        local footerHeight = #self.Dots > 0 and 24 or 0
        self.Height = height + footerHeight
        self.Root.Size = UDim2.fromOffset(width, self.Height)
        local gap = Theme.Space.L
        local total = 0
        local weights = compact and nil or self.Weights
        if compact then
            -- narrow: split evenly, wrap is not needed for 3 cards at this size
            weights = { 1, 1, 1 }
        end
        for _, weight in ipairs(weights) do
            total = total + weight
        end
        local x = 0
        for index, card in ipairs(self.Cards) do
            local weight = weights[index] or 1
            local cardWidth = math.floor((width - gap * (#self.Cards - 1)) * (weight / total))
            if index == #self.Cards then
                cardWidth = width - x
            end
            if card.Layout then
                card:Layout(cardWidth, height)
            end
            Prim.place(card.Root, x, 0, cardWidth, height)
            x = x + cardWidth + gap
        end
        Prim.place(self.Footer, 0, height + 4, width, footerHeight)
        if #self.Dots > 0 then
            local dotsWidth = 0
            for index = 1, #self.Dots do
                dotsWidth = dotsWidth + (index == 1 and 16 or 5) + 6
            end
            local startX = width / 2 - dotsWidth / 2
            for index, dot in ipairs(self.Dots) do
                local dotWidth = index == 1 and 16 or 5
                Prim.place(dot, 0, 0, dotWidth, 5)
                dot.Position = UDim2.fromOffset(startX + dotWidth / 2, footerHeight / 2 - 4)
                startX = startX + dotWidth + 6
            end
        end
        self:SetDot(self.ActiveDot or 1)
        return self.Height
    end

    function row:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end

    function row:Destroy()
        for _, card in ipairs(self.Cards) do
            if card.Destroy then
                card:Destroy()
            end
        end
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end
    row.Height = config.Height or 152
    return row
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Modal / Dialog — one at a time, backdrop ownership, action states, busy guard.
-- ══════════════════════════════════════════════════════════════════════════════

local Modal = {
    IsOpen = false,
    Config = nil,
    Token = 0,
    Dismissible = true,
}
Library.__internal.Modal = Modal

local MODAL_WIDTH = { small = 340, medium = 420, large = 560 }

function Modal.Layout()
    local config = Modal.Config
    if not config or not Layers.ModalHost then
        return
    end
    local host = Layers.Root.AbsoluteSize
    local desired = config.Width or MODAL_WIDTH[config.Size or "medium"] or 420
    local width = math.min(desired, math.max(220, host.X - 32))
    local maxHeight = math.max(160, host.Y - 40)
    local headerHeight = 0
    if Modal.Title and Modal.Title.Text ~= "" then
        headerHeight = 30
    end
    local bodyHeight = Modal.MeasuredBody or 0
    local actionHeight = Modal.Actions and 56 or 20
    local descriptionHeight = Modal.MeasuredText or 0
    local height = math.min(maxHeight, 22 + headerHeight + descriptionHeight + bodyHeight + actionHeight + (Modal.Icon and 44 or 0))
    Modal.Root.Size = UDim2.fromOffset(width, height)
    Modal.Frame.Size = UDim2.fromOffset(width, height)
    local y = 22
    if Modal.Icon then
        Prim.place(Modal.Icon.Root, width / 2 - 22, y, 44, 44)
        y = y + 44 + 8
    end
    if Modal.Title and Modal.Title.Text ~= "" then
        Prim.place(Modal.Title, 20, y, width - 40, 28)
        y = y + 30
    end
    if Modal.Text then
        local textHeight = Modal.MeasuredText or 0
        Prim.place(Modal.Text, 20, y, width - 40, textHeight)
        y = y + textHeight
    end
    if Modal.Body and Modal.MeasuredBody then
        Prim.place(Modal.Body, 20, y, width - 40, Modal.MeasuredBody)
        y = y + Modal.MeasuredBody
    end
    if Modal.Actions then
        local actionsWidth = 0
        for _, action in ipairs(Modal.Actions) do
            actionsWidth = actionsWidth + (action.Width or 116) + 8
        end
        local x = width - 20 - actionsWidth + 8
        for _, action in ipairs(Modal.Actions) do
            action.Button.Root.AnchorPoint = Vector2.new(1, 0.5)
            Prim.place(action.Button.Root, x + (action.Width or 116) - 116, height - 40, action.Width or 116, 38)
            action.Button.Root.Position = UDim2.new(1, 0, 1, -38)
            action.Button.Root.Size = UDim2.fromOffset(action.Width or 116, 38)
            x = x + (action.Width or 116) + 8
        end
        Modal.ActionRow.Position = UDim2.new(0, 0, 1, 0)
        Prim.place(Modal.ActionRow, 20, height - 46, width - 40, 40)
    end
end

function Modal.Close(immediate, silent)
    -- Ownership: this closure destroys the panel it captured, so a modal opened
    -- during the exit animation can never strand its predecessor in the tree.
    local panel = Modal.Root
    local frame = Modal.Frame
    local scale = Modal.Scale
    local scope = Modal.Scope
    if not panel and not Modal.IsOpen then
        return
    end
    Modal.Token = Modal.Token + 1
    local token = Modal.Token
    Modal.IsOpen = false
    local config = Modal.Config
    Modal.Config = nil
    Modal.Root, Modal.Frame, Modal.Scale, Modal.Scope = nil, nil, nil, nil
    local actions = Modal.Actions
    Modal.Actions, Modal.Body, Modal.Title, Modal.Text, Modal.Icon = nil, nil, nil, nil, nil
    Modal.MeasuredBody, Modal.MeasuredText = 0, 0
    local function finish()
        if scope then
            scope:Destroy()
        end
        for _, action in ipairs(actions or {}) do
            if action.Button then
                action.Button:Destroy()
            end
        end
        if panel and panel.Parent then
            Anim.CancelTree(panel)
            panel:Destroy()
        end
        if token == Modal.Token and not Modal.IsOpen then
            Layers.ShowBackdrop(false, false)
        end
        if config and config.OnClose and not silent then
            Util.guard(config.OnClose)
        end
    end
    if immediate or Motion.Reduced or not panel or not frame then
        finish()
    else
        if token == Modal.Token then
            Layers.ShowBackdrop(false, false)
        end
        Anim.To(frame, { GroupTransparency = 1 }, Motion.Exit, finish)
        Anim.To(scale, { Scale = 0.97 }, Motion.Exit)
    end
end

function Modal.Open(config)
    if not Layers.ModalHost then
        return nil
    end
    Modal.Close(true, true)   -- deterministic: never two panels in the host
    config = config or {}
    Modal.Token = Modal.Token + 1
    local token = Modal.Token
    Modal.Config = config
    Modal.IsOpen = true
    Modal.Dismissible = config.Dismissible ~= false
    Modal.Scope = Scope.new()

    Modal.Root = Prim.new("Frame", {
        Name = "Modal",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    }, Layers.ModalHost)
    Modal.Frame = Prim.group(Modal.Root, "Panel")
    Modal.Frame.BackgroundColor3 = Theme.Color.SurfaceRaised
    Modal.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Modal.Frame.Position = UDim2.fromScale(0.5, 0.5)
    Modal.Frame.GroupTransparency = Motion.Reduced and 0 or 1
    Prim.corner(Modal.Frame, Theme.Radius.Large)
    Prim.stroke(Modal.Frame, Theme.Color.StrokeStrong, 1, 0.25)
    Modal.Scale = Prim.new("UIScale", { Scale = Motion.Reduced and 1 or 0.965 }, Modal.Frame)

    local accent = config.Type == "danger" and Theme.Color.Danger
        or config.Type == "success" and Theme.Color.Success
        or config.Type == "warning" and Theme.Color.Warning
        or Theme.Color.Accent
    if config.Icon then
        local symbol = Prim.frame(Modal.Frame, "Symbol", Theme.Color.SurfaceInteractive)
        Prim.corner(symbol, 100)
        local icon = Prim.Icon.new(symbol, config.Icon, accent, 20, 1.8)
        icon.Root.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Root.Position = UDim2.fromScale(0.5, 0.5)
        Modal.Icon = { Root = symbol, Icon = icon }
    end

    Modal.Title = Prim.label(Modal.Frame, "Title", Util.text(config.Title or "", 48), config.TitleSize or Theme.Type.Subtitle, Theme.Color.Text, Theme.Font.Bold)
    Modal.Title.TextXAlignment = Enum.TextXAlignment.Center
    Modal.Title.TextWrapped = true
    Modal.MeasuredText = 0
    Modal.Text = Prim.label(Modal.Frame, "Text", Util.text(config.Text or "", 260), Theme.Type.Small, Theme.Color.TextSecondary)
    Modal.Text.TextXAlignment = Enum.TextXAlignment.Center
    Modal.Text.TextWrapped = true
    Modal.Text.TextYAlignment = Enum.TextYAlignment.Top

    Modal.Body = nil
    Modal.MeasuredBody = 0
    if config.Body then
        Modal.Body = Prim.frame(Modal.Frame, "Body", Theme.Color.Surface)
        Modal.Body.BackgroundTransparency = 1
    end

    Modal.ActionRow = Prim.frame(Modal.Frame, "Actions", Theme.Color.Surface)
    Modal.ActionRow.BackgroundTransparency = 1
    Modal.Actions = {}
    for index, action in ipairs(config.Actions or {}) do
        local button = Components.Button(Modal.Scope, Modal.Frame, {
            Name = "Action" .. index,
            Text = action.Text,
            Style = action.Style or (index == #(config.Actions or {}) and "primary" or "secondary"),
            Width = action.Width or 116,
            Height = 38,
            Callback = function()
                if action.Close ~= false and action.Style ~= "primary" then
                    Modal.Close()
                end
                if action.Callback then
                    Util.guard(action.Callback, Modal)
                end
                if action.Close ~= false and action.Style == "primary" then
                    Modal.Close()
                end
            end,
        })
        table.insert(Modal.Actions, { Button = button, Width = action.Width or 116, Config = action })
    end

    -- measure text blocks against the final width
    local host = Layers.Root.AbsoluteSize
    local width = math.min(config.Width or MODAL_WIDTH[config.Size or "medium"] or 420, math.max(220, host.X - 32))
    local inner = width - 40
    if Modal.Text.Text ~= "" then
        Modal.MeasuredText = math.min(140, math.max(16, Util.measureHeight(Modal.Text.Text, Theme.Type.Small, Theme.Font.Regular, inner) + 6))
    end
    if Modal.Body and config.Body then
        Modal.MeasuredBody = Util.finite(config.BodyHeight, 0)
        if config.BuildBody then
            local built = Util.safeCall(config.BuildBody, Modal.Body, inner, function(height)
                Modal.MeasuredBody = math.max(Modal.MeasuredBody, height)
                Modal.Layout()
            end)
            if not built then
                Modal.MeasuredBody = Util.finite(config.BodyHeight, 120)
            end
        end
        if Modal.MeasuredBody == 0 then
            Modal.MeasuredBody = 120
        end
    end

    Modal.Layout()
    Layers.ShowBackdrop(true, true, function()
        if Modal.IsOpen and Modal.Dismissible then
            Modal.Close()
        end
    end, Modal.Scope)
    Anim.To(Modal.Frame, { GroupTransparency = 0 }, Motion.Emphasized, nil, true)
    Anim.To(Modal.Scale, { Scale = 1 }, Motion.Emphasized, nil, true)
    Modal.Scope:Connect(UserInputService.InputBegan, function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == Enum.KeyCode.Escape and Modal.IsOpen and Modal.Dismissible and token == Modal.Token then
            Modal.Close()
        end
    end)
    return Modal
end

function Modal.Confirm(config)
    config = config or {}
    return Modal.Open({
        Title = config.Title or "Are you sure?",
        Text = config.Text,
        Icon = config.Icon or "warning",
        Type = config.Type or "warning",
        Size = "small",
        Dismissible = config.Dismissible ~= false,
        Actions = {
            { Text = config.CancelText or "Cancel", Style = "secondary", Callback = config.OnCancel },
            { Text = config.ConfirmText or "Confirm", Style = config.ConfirmStyle or "primary", Callback = config.OnConfirm },
        },
    })
end

function Modal.Alert(config)
    config = config or {}
    return Modal.Open({
        Title = config.Title or "Notice",
        Text = config.Text,
        Icon = config.Icon or "info",
        Type = config.Type or "info",
        Size = "small",
        Actions = {
            { Text = config.ActionText or "OK", Style = "primary", Callback = config.OnAction },
        },
    })
end

-- SetState drives progressive feedback on a modal action (idle -> busy -> success/danger).
function Modal.SetActionState(index, state, text)
    local action = Modal.Actions and Modal.Actions[index]
    if not action or not action.Button then
        return
    end
    if text then
        action.Button:SetText(text)
    end
    if state == "busy" then
        action.Button:SetBusy(true)
        for _, other in ipairs(Modal.Actions) do
            if other ~= action then
                other.Button:SetDisabled(true)
            end
        end
    elseif state == "success" then
        action.Button:SetBusy(false)
        action.Button:SetText(text or "Done")
        action.Button.Label.TextColor3 = Theme.Color.Success
    elseif state == "error" then
        action.Button:SetBusy(false)
        action.Button:SetText(text or "Retry")
    else
        action.Button:SetBusy(false)
        for _, other in ipairs(Modal.Actions) do
            other.Button:SetDisabled(false)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Section — a card that owns a stack of rows. Manual stacking keeps row heights
-- exact (variable-height rows and two-column bodies break list layouts).
-- ══════════════════════════════════════════════════════════════════════════════

function Components.Section(scope, parent, config)
    config = config or {}
    local section = {
        Scope = scope,
        Rows = {},
        Visible = true,
        Pad = config.Pad or Theme.Space.XL,
        Gap = config.Gap or 2,
        Name = config.Name or "Section",
    }
    section.Root = Prim.group(parent, "Section_" .. tostring(config.Name or "Unnamed"))
    section.Root.BackgroundColor3 = Theme.Color.Surface
    section.Root.BackgroundTransparency = 0
    section.Panel = Prim.frame(section.Root, "Panel", Theme.Color.Surface)
    section.Panel.Size = UDim2.fromScale(1, 1)
    Prim.corner(section.Panel, Theme.Radius.Medium)
    section.PanelStroke = Prim.stroke(section.Panel, Theme.Color.Stroke, 1, 0.55)

    section.Header = Prim.frame(section.Panel, "Header", Theme.Color.Surface)
    section.Header.BackgroundTransparency = 1
    local headerVisible = config.Name ~= nil or config.Icon ~= nil
    if headerVisible then
        if config.Icon then
            local icon = Prim.Icon.new(section.Header, config.Icon, Theme.Color.Accent, 14, 1.6)
            Prim.place(icon.Root, 0, 4, 14, 14)
            section.HeaderIcon = icon
        end
        section.Title = Prim.label(section.Header, "Title", Util.text(config.Name or "", 40), Theme.Type.Body, Theme.Color.Text, Theme.Font.Bold)
        Prim.place(section.Title, config.Icon and 22 or 0, 0, 240, 22)
        section.Title.Size = UDim2.new(1, config.Icon and -22 or 0, 0, 22)
        if config.Description then
            section.Description = Prim.label(section.Header, "Description", Util.text(config.Description, 80), Theme.Type.Caption, Theme.Color.TextMuted)
            section.Description.TextWrapped = true
            section.Description.TextYAlignment = Enum.TextYAlignment.Top
        end
    end
    section.Body = Prim.frame(section.Panel, "Body", Theme.Color.Surface)
    section.Body.BackgroundTransparency = 1

    function section:Add(row)
        table.insert(self.Rows, row)
        -- a control added at runtime must appear immediately on a visible page
        if self.PageRef then
            self.PageRef:RequestLayout()
        end
        return row
    end

    function section:AddDivider(text)
        return self:Add(Components.Divider(scope, section.Body, { Text = text }))
    end

    function section:AddLabel(value)
        return self:Add(Components.Label(scope, section.Body, {
            Text = value.Text or value,
            Color = value.Color,
            Size = value.Size,
            Name = value.Name,
        }))
    end

    function section:AddParagraph(value)
        return self:Add(Components.Paragraph(scope, section.Body, value))
    end

    function section:AddToggle(value)
        return self:Add(Components.Toggle(scope, section.Body, value))
    end

    function section:AddCheckbox(value)
        return self:Add(Components.Checkbox(scope, section.Body, value))
    end

    function section:AddSlider(value)
        return self:Add(Components.Slider(scope, section.Body, value))
    end

    function section:AddDropdown(value)
        return self:Add(Components.Dropdown(scope, section.Body, value))
    end

    function section:AddMultiDropdown(value)
        value.Multi = true
        return self:Add(Components.Dropdown(scope, section.Body, value))
    end

    function section:AddTextbox(value)
        return self:Add(Components.Textbox(scope, section.Body, value))
    end

    function section:AddKeybind(value)
        return self:Add(Components.Keybind(scope, section.Body, value))
    end

    function section:AddButton(value)
        local button = Components.Button(scope, section.Body, value)
        local wrapper = { Root = button.Root, Button = button, Height = value.Height or Theme.Metric.ControlHeight }
        function wrapper:Layout(width)
            local targetWidth = value.Full and width or value.Width or math.min(width, 168)
            local x = value.Full and 0 or (width - targetWidth)
            Prim.place(self.Root, x, 0, targetWidth, self.Height)
            return self.Height
        end
        function wrapper:Destroy()
            button:Destroy()
        end
        Components.Expose(wrapper, button)
        return self:Add(wrapper)
    end

    function section:AddSegmented(value)
        local wrapper = { Root = Prim.frame(section.Body, "SegmentedRow", Theme.Color.Surface), Height = value.Height or 34 }
        wrapper.Root.BackgroundTransparency = 1
        local segmented = Components.Segmented(scope, wrapper.Root, value)
        wrapper.Segmented = segmented
        function wrapper:Layout(width)
            Prim.place(self.Root, 0, 0, width, self.Height)
            self.Segmented:Layout(width, self.Height)
            return self.Height
        end
        function wrapper:Destroy()
            segmented:Destroy()
            self.Root:Destroy()
        end
        Components.Expose(wrapper, segmented)
        return self:Add(wrapper)
    end

    function section:AddSelectRow(value)
        return self:Add(Components.SelectRow(scope, section.Body, value))
    end

    function section:AddProgress(value)
        return self:Add(Components.Progress(scope, section.Body, value))
    end

    function section:AddMetadata(value)
        return self:Add(Components.MetadataGrid(scope, section.Body, value))
    end

    function section:AddBanner(value)
        return self:Add(Components.Banner(scope, section.Body, value))
    end

    function section:AddEmpty(value)
        return self:Add(Components.EmptyState(scope, section.Body, value))
    end

    function section:AddSpacer(height)
        local spacer = { Height = height or 8 }
        spacer.Root = Prim.frame(section.Body, "Spacer", Theme.Color.Surface)
        spacer.Root.BackgroundTransparency = 1
        function spacer:Layout(width)
            Prim.place(self.Root, 0, 0, width, self.Height)
            return self.Height
        end
        function spacer:Destroy()
            self.Root:Destroy()
        end
        return self:Add(spacer)
    end

    function section:AddCustom(value)
        return self:Add(value)
    end

    function section:Layout(width)
        local pad = self.Pad
        local inner = math.max(40, width - pad * 2)
        local y = pad
        if headerVisible then
            local titleHeight = 22
            local descriptionHeight = 0
            if self.Description then
                descriptionHeight = math.max(14, Util.measureHeight(self.Description.Text, Theme.Type.Caption, Theme.Font.Regular, inner - 4))
            end
            local headerHeight = titleHeight + (descriptionHeight > 0 and (descriptionHeight + 4) or 0)
            Prim.place(self.Header, 0, y - 6, inner, headerHeight + 6)
            Prim.place(self.Title, config.Icon and 22 or 0, 4, inner - (config.Icon and 22 or 0), titleHeight)
            if self.HeaderIcon then
                Prim.place(self.HeaderIcon.Root, 0, 7, 14, 14)
            end
            if self.Description then
                Prim.place(self.Description, 0, titleHeight + 6, inner, descriptionHeight)
            end
            y = y + headerHeight + Theme.Space.L
        end
        for index, row in ipairs(self.Rows) do
            if row.Root ~= nil or row.Layout ~= nil then
                local rowHeight
                if row.Layout then
                    rowHeight = row:Layout(inner)
                elseif row.Height then
                    rowHeight = row.Height
                    if row.Root then
                        Prim.place(row.Root, 0, 0, inner, rowHeight)
                    end
                else
                    rowHeight = 0
                end
                if rowHeight and rowHeight > 0 and row.Root then
                    row.Root.Position = UDim2.fromOffset(pad, y)
                    row.Root.Size = UDim2.fromOffset(inner, rowHeight)
                    y = y + rowHeight + (row.Gap or self.Gap)
                end
            end
        end
        local height = y + pad - self.Gap
        self.Height = height
        self.Width = width
        self.Root.Size = UDim2.fromOffset(width, height)
        Prim.place(self.Panel, 0, 0, width, height)
        return height
    end

    function section:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end

    function section:SetTitle(value)
        if self.Title then
            self.Title.Text = Util.text(value, 40)
        end
    end

    function section:Clear()
        for _, row in ipairs(self.Rows) do
            if row.Destroy then
                row:Destroy()
            end
        end
        self.Rows = {}
    end

    function section:Destroy()
        self:Clear()
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    section.Height = config.Pad or Theme.Space.XL
    return section
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Page — scroll surface + block flow engine (single or two-column).
-- ══════════════════════════════════════════════════════════════════════════════

local Page = {}
Page.__index = Page

function Page.new(scope, parent, config)
    config = config or {}
    local page = setmetatable({
        Scope = scope,
        Name = config.Name or "Page",
        Icon = config.Icon,
        Hidden = config.Hidden == true,
        Blocks = {},
        Side = config.Side,
        Visible = false,
        ScrollPosition = 0,
    }, Page)
    page.Root = Prim.group(parent, "Page_" .. tostring(config.Name or "Page"))
    page.Root.BackgroundTransparency = 1
    page.Root.Size = UDim2.fromScale(1, 1)
    page.Root.Visible = false

    page.HeaderRow = Prim.frame(page.Root, "PageHeader", Theme.Color.Surface)
    page.HeaderRow.BackgroundTransparency = 1
    page.HeaderRow.Visible = false
    page.HeaderRow.Height = 0
    page.BackChip = Prim.new("TextButton", {
        Name = "Back",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.SurfaceRaised,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(96, 28),
        Position = UDim2.fromOffset(0, 0),
        Active = true,
        Selectable = true,
    }, page.HeaderRow)
    Prim.corner(page.BackChip, Theme.Radius.Small)
    page.BackIcon = Prim.Icon.new(page.BackChip, "arrowLeft", Theme.Color.TextSecondary, 12, 1.6)
    Prim.place(page.BackIcon.Root, 10, 8, 12, 12)
    page.BackLabel = Prim.label(page.BackChip, "Label", "", Theme.Type.Small, Theme.Color.TextSecondary, Theme.Font.Medium)
    Prim.place(page.BackLabel, 28, 0, 60, 28)
    page.HeaderTitle = Prim.label(page.HeaderRow, "Title", "", Theme.Type.Title, Theme.Color.Text, Theme.Font.Bold)
    Prim.place(page.HeaderTitle, 108, 2, 400, 24)
    page.HeaderTitle.TextTruncate = Enum.TextTruncate.AtEnd
    page.HeaderSubtitle = Prim.label(page.HeaderRow, "Subtitle", "", Theme.Type.Caption, Theme.Color.TextMuted)
    Prim.place(page.HeaderSubtitle, 108, 27, 400, 16)

    page.Scroll = Prim.scroller(page.Root, "Scroll")
    page.Body = Prim.frame(page.Scroll, "Body", Theme.Color.Surface)
    page.Body.BackgroundTransparency = 1

    page.Scope:Connect(page.BackChip.MouseEnter, function()
        Anim.To(page.BackChip, { BackgroundColor3 = Theme.Color.SurfaceHover }, Motion.Micro)
        page.BackIcon:SetColor(Theme.Color.Text)
        page.BackLabel.TextColor3 = Theme.Color.Text
    end)
    page.Scope:Connect(page.BackChip.MouseLeave, function()
        Anim.To(page.BackChip, { BackgroundColor3 = Theme.Color.SurfaceRaised }, Motion.Micro)
        page.BackIcon:SetColor(Theme.Color.TextSecondary)
        page.BackLabel.TextColor3 = Theme.Color.TextSecondary
    end)
    page.Scope:Connect(page.BackChip.Activated, function()
        if page.OnBack then
            Util.guard(page.OnBack)
        end
    end)
    page.Scope:Connect(page.Scroll:GetPropertyChangedSignal("CanvasPosition"), function()
        page.ScrollPosition = page.Scroll.CanvasPosition.Y
        if Popover.Current then
            Popover.Close(true)
        end
    end)
    return page
end

function Page:RequestLayout()
    if self.Destroyed or self.PendingLayout then
        return
    end
    self.PendingLayout = true
    self.Scope:Run(function()
        self.PendingLayout = false
        if self.Destroyed then
            return
        end
        local owner = self.Owner
        if owner and not owner.Destroyed then
            owner:Layout()
        end
    end)
end

function Page:AddBlock(block, side)
    block.Side = side or block.Side or "Left"
    table.insert(self.Blocks, block)
    return block
end

function Page:RemoveBlock(block)
    for index, entry in ipairs(self.Blocks) do
        if entry == block then
            table.remove(self.Blocks, index)
            break
        end
    end
    if block.Destroy then
        block:Destroy()
    end
    self:Reflow()
end

function Page:Clear()
    for _, block in ipairs(self.Blocks) do
        if block.Destroy then
            block:Destroy()
        end
    end
    self.Blocks = {}
    self:Reflow()
end

function Page:AddSection(config)
    config = config or {}
    local section = Components.Section(self.Scope, self.Body, config)
    section.PageRef = self
    section.Owner = self
    return self:AddBlock(section, config.Side)
end

function Page:AddHero(config)
    return self:AddBlock(Components.Hero(self.Scope, self.Body, config))
end

function Page:AddCardRow(config)
    return self:AddBlock(Components.CardRow(self.Scope, self.Body, config))
end

function Page:AddCard(config)
    return self:AddBlock(Components.Card(self.Scope, self.Body, config), config.Side)
end

function Page:AddGrid(config)
    return self:AddBlock(Components.Grid(self.Scope, self.Body, config), config.Side)
end

function Page:AddBanner(config)
    return self:AddBlock(Components.Banner(self.Scope, self.Body, config), config.Side)
end

function Page:AddText(config)
    return self:AddBlock(Components.Paragraph(self.Scope, self.Body, config), config.Side)
end

function Page:AddDivider(text)
    return self:AddBlock(Components.Divider(self.Scope, self.Body, { Text = text }), nil)
end

function Page:AddMedia(config)
    return self:AddBlock(Components.MediaPreview(self.Scope, self.Body, config), config.Side)
end

function Page:AddMetadata(config)
    return self:AddBlock(Components.MetadataGrid(self.Scope, self.Body, config), config.Side)
end

function Page:AddEmpty(config)
    return self:AddBlock(Components.EmptyState(self.Scope, self.Body, config), config.Side)
end

function Page:AddButton(config)
    config = config or {}
    local holder = Prim.frame(self.Body, "PageButton", Theme.Color.Surface)
    holder.BackgroundTransparency = 1
    local button = Components.Button(self.Scope, holder, config)
    local height = config.Height or Theme.Metric.ControlHeight
    local wrapper = { Root = holder, Button = button, Height = height }
    function wrapper:Layout(width)
        Prim.place(self.Root, 0, 0, width, height)
        local targetWidth = config.Full and width or math.min(width, config.Width or 168)
        Prim.place(self.Button.Root, 0, 0, targetWidth, height)
        return height
    end
    function wrapper:Destroy()
        button:Destroy()
        holder:Destroy()
    end
    Components.Expose(wrapper, button)
    return self:AddBlock(wrapper, config.Side)
end

function Page:AddQuantity(config)
    local group = Components.Segmented(self.Scope, self.Body, config)
    local wrapper = {
        Root = group.Root,
        Segmented = group,
        Height = group.Height,
    }
    function wrapper:Layout(width)
        self.Segmented:Layout(width, self.Height)
        return self.Height
    end
    function wrapper:Destroy()
        self.Segmented:Destroy()
    end
    Components.Expose(wrapper, group)
    return self:AddBlock(wrapper, config and config.Side)
end

function Page:SetHeader(config)
    config = config or {}
    self.HeaderConfig = config
    self.OnBack = config.OnBack
    local visible = config.Title ~= nil or config.Back ~= nil
    self.HeaderRow.Visible = visible
    if not visible then
        self.HeaderRow.Height = 0
        self:Reflow()
        return
    end
    self.HeaderRow.Height = 52
    self.BackChip.Visible = config.Back ~= nil
    if config.Back then
        self.BackLabel.Text = Util.text(config.Back, 12)
        local width = math.max(74, Util.measureWidth(config.Back, Theme.Type.Small, Theme.Font.Medium) + 42)
        self.BackChip.Size = UDim2.fromOffset(width, 28)
    end
    self.HeaderTitle.Text = Util.text(config.Title or "", 60)
    self.HeaderTitle.Visible = config.Title ~= nil
    self.HeaderSubtitle.Text = Util.text(config.Subtitle or "", 80)
    self.HeaderSubtitle.Visible = config.Subtitle ~= nil
    self:Reflow()
end

function Page:SetVisible(value)
    self.Visible = value == true
    self.Root.Visible = self.Visible
    if self.Visible then
        self.Scroll.CanvasPosition = Vector2.new(0, self.ScrollPosition or 0)
    end
end

function Page:Reflow()
    self.NeedsReflow = true
end

function Page:Layout(width, height, compact)
    local headerHeight = self.HeaderRow.Visible and 52 or 0
    Prim.place(self.HeaderRow, 0, 0, width, headerHeight)
    if headerHeight > 0 then
        Prim.place(self.HeaderTitle, self.HeaderConfig and self.HeaderConfig.Back and (self.BackChip.Size.X.Offset + 16) or 0, 2, width - 140, 24)
        Prim.place(self.HeaderSubtitle, self.HeaderConfig and self.HeaderConfig.Back and (self.BackChip.Size.X.Offset + 16) or 0, 27, width - 140, 16)
    end
    local contentWidth = width
    local contentHeight = math.max(40, height - headerHeight)
    Prim.place(self.Scroll, 0, headerHeight, contentWidth, contentHeight)

    local gap = Theme.Space.L
    local leftWeight, rightWeight = 0, 0
    for _, block in ipairs(self.Blocks) do
        local weight = block.Weight or 1
        if block.Side == "Right" then
            rightWeight = rightWeight + weight
        else
            leftWeight = leftWeight + weight
        end
    end
    local twoColumn = rightWeight > 0 and contentWidth >= 620 and not compact
    if not twoColumn and rightWeight > 0 then
        -- collapse to a single flow: keep left blocks first, then right blocks
        leftWeight = leftWeight + rightWeight
        rightWeight = 0
    end

    local leftWidth, rightWidth
    if twoColumn then
        local usable = contentWidth - gap
        leftWidth = math.floor(usable * (leftWeight / (leftWeight + rightWeight)))
        rightWidth = usable - leftWidth
    else
        leftWidth = contentWidth
        rightWidth = 0
    end

    local cursors = { Left = 0, Right = 0 }
    local order = {}
    for _, block in ipairs(self.Blocks) do
        table.insert(order, block)
    end
    for _, block in ipairs(order) do
        local side = block.Side or "Left"
        if rightWidth == 0 then
            side = "Left"
        end
        local targetWidth = side == "Right" and rightWidth or leftWidth
        local height = 0
        if block.Layout then
            local ok, result = Util.safeCall(block.Layout, block, targetWidth, nil, compact)
            if ok and type(result) == "number" then
                height = result
            elseif type(block.Height) == "number" then
                height = block.Height
            end
        elseif type(block.Height) == "number" then
            height = block.Height
        end
        if block.Root then
            local x = side == "Right" and (leftWidth + gap) or 0
            block.Root.Position = UDim2.fromOffset(x, cursors[side])
            if height and height > 0 then
                block.Root.Size = UDim2.fromOffset(targetWidth, height)
            end
        end
        cursors[side] = cursors[side] + (height or 0) + gap
    end
    local totalHeight = math.max(cursors.Left, cursors.Right) - gap
    totalHeight = math.max(totalHeight, 0)
    self.Body.Size = UDim2.fromOffset(contentWidth, totalHeight)
    self.Scroll.CanvasSize = UDim2.fromOffset(0, totalHeight)
    local scrollable = totalHeight > contentHeight + 1
    self.Scroll.ScrollingEnabled = scrollable
    if not scrollable then
        self.Scroll.CanvasPosition = Vector2.new(0, 0)
    end
    self.NeedsReflow = false
    self.Height = totalHeight
    self.Width = contentWidth
    self.Compact = compact
    return totalHeight
end

function Page:Destroy()
    self:Clear()
    Anim.CancelTree(self.Root)
    self.Root:Destroy()
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Window — the application shell. One layout authority, one router, one drag
-- engine, one minimize/restore path, one teardown.
-- ══════════════════════════════════════════════════════════════════════════════

local WindowClass = {}
WindowClass.__index = WindowClass
WindowClass.Active = nil

local BAND_WIDE = { width = 1040, height = 640 }
local BAND_STANDARD = { width = 940, height = 600 }

-- Single source of truth for the usable viewport (stage → camera → keyboard clamp).
local function MeasureStage(window)
    local raw
    if window and window.Root then
        raw = window.Root.AbsoluteSize
    end
    if not raw or raw.X < 2 or raw.Y < 2 then
        local camera = workspace.CurrentCamera
        raw = (camera and camera.ViewportSize) or Vector2.new(1280, 720)
    end
    local width = math.max(280, raw.X)
    local height = math.max(240, raw.Y)
    pcall(function()
        if UserInputService.VirtualKeyboardVisible and UserInputService.VirtualKeyboardPosition.Y > 0 then
            height = math.min(height, UserInputService.VirtualKeyboardPosition.Y - 8)
        end
    end)
    return Vector2.new(width, math.max(220, height))
end

local function ClampToStage(position, stage, width, height, margin)
    local halfWidth, halfHeight = width / 2, height / 2
    return Vector2.new(
        Util.clamp(position.X, halfWidth + margin, math.max(halfWidth + margin, stage.X - halfWidth - margin)),
        Util.clamp(position.Y, halfHeight + margin, math.max(halfHeight + margin, stage.Y - halfHeight - margin))
    )
end

function WindowClass.new(library, config, parent)
    config = config or {}
    local window = setmetatable({
        Library = library,
        Config = config,
        Scope = Scope.new(),
        Pages = {},
        PageIndex = {},
        Current = nil,
        Visible = true,
        Minimized = false,
        Busy = false,
        Accent = config.Accent or Theme.Color.Accent,
        Drag = nil,
        Token = 0,
        Destroyed = false,
        UserScale = 1,
    }, WindowClass)

    window.Screen = Prim.new("ScreenGui", {
        Name = "Takataka",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 90,
        IgnoreGuiInset = false,
    }, parent)
    pcall(function()
        window.Screen.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
        window.Screen.ClipToDeviceSafeArea = true
    end)
    window.Screen:SetAttribute("TakatakaOwned", true)

    window.Root = Prim.frame(window.Screen, "Root", Theme.Color.Surface)
    window.Root.BackgroundTransparency = 1
    window.Root.Size = UDim2.fromScale(1, 1)
    Layers.Mount(window.Root, window.Scope)
    Popover.Bind(window.Scope)

    window.Shadow = Prim.frame(window.Root, "Shadow", Theme.Color.Shadow)
    window.Shadow.BackgroundTransparency = 0.86
    window.Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    window.Shadow.ZIndex = 0
    Prim.corner(window.Shadow, Theme.Radius.Large + 4)

    window.Window = Prim.group(window.Root, "App")
    window.Window.BackgroundColor3 = Theme.Color.Bg
    window.Window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.Window.Position = UDim2.fromScale(0.5, 0.5)
    window.Window.GroupTransparency = 1
    window.Window.ClipsDescendants = true
    window.Window.ZIndex = 1
    Prim.corner(window.Window, Theme.Radius.Large)
    window.WindowStroke = Prim.stroke(window.Window, Theme.Color.StrokeStrong, 1, 0.45)
    window.Scale = Prim.new("UIScale", { Scale = 1 }, window.Window)

    window.TopBar = Prim.frame(window.Window, "TopBar", Theme.Color.Bg)
    window.TopBar.BackgroundTransparency = 1
    window.TopBar.Active = true
    window.TopBar.ZIndex = Theme.Layer.Header

    window.Logo = Prim.frame(window.TopBar, "Logo", Theme.Color.White)
    window.Logo.Size = UDim2.fromOffset(26, 26)
    Prim.corner(window.Logo, Theme.Radius.Small)
    Prim.aurora(window.Logo, window.Scope, 0)
    window.LogoMark = Prim.label(window.Logo, "Mark", "", 13, Theme.Color.OnAccent, Theme.Font.Bold)
    window.LogoMark.TextXAlignment = Enum.TextXAlignment.Center
    window.LogoMark.Size = UDim2.fromScale(1, 1)

    window.Nav = Prim.frame(window.TopBar, "Nav", Theme.Color.Bg)
    window.Nav.BackgroundTransparency = 1

    window.Identity = Prim.frame(window.TopBar, "Identity", Theme.Color.Bg)
    window.Identity.BackgroundTransparency = 1
    window.IdentityName = Prim.label(window.Identity, "Name", "", Theme.Type.Small, Theme.Color.TextSecondary, Theme.Font.Medium)
    window.IdentityName.TextXAlignment = Enum.TextXAlignment.Right
    window.Avatar = Prim.frame(window.Identity, "Avatar", Theme.Color.White)
    window.Avatar.Size = UDim2.fromOffset(28, 28)
    Prim.corner(window.Avatar, 100)
    Prim.aurora(window.Avatar, window.Scope, 0)
    window.AvatarMark = Prim.label(window.Avatar, "Mark", "", 12, Theme.Color.OnAccent, Theme.Font.Bold)
    window.AvatarMark.TextXAlignment = Enum.TextXAlignment.Center
    window.AvatarMark.Size = UDim2.fromScale(1, 1)

    window.SettingsButton = Components.IconButton(window.Scope, window.TopBar, {
        Name = "Settings",
        Icon = "settings",
        Tooltip = "Interface settings",
        Size = 30,
        IconSize = 14,
        Callback = function()
            window:ToggleSettings()
        end,
    })
    window.MinButton = Components.IconButton(window.Scope, window.TopBar, {
        Name = "Minimize",
        Icon = "minus",
        Tooltip = "Minimize",
        Size = 30,
        IconSize = 14,
        Callback = function()
            window:Minimize()
        end,
    })

    window.Content = Prim.frame(window.Window, "Content", Theme.Color.Canvas)
    window.Content.BackgroundTransparency = 1
    window.Content.ClipsDescendants = true
    window.Content.ZIndex = Theme.Layer.Content

    window.Launcher = Prim.new("TextButton", {
        Name = "Launcher",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.White,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(Theme.Metric.Launcher, Theme.Metric.Launcher),
        Visible = false,
        Active = true,
        Selectable = true,
        ZIndex = Theme.Layer.Launcher,
    }, window.Root)
    Prim.corner(window.Launcher, Theme.Radius.Medium)
    Prim.aurora(window.Launcher, window.Scope, 0)
    window.LauncherStroke = Prim.stroke(window.Launcher, Theme.Color.StrokeStrong, 1, 0.3)
    window.LauncherMark = Prim.label(window.Launcher, "Mark", "", 20, Theme.Color.OnAccent, Theme.Font.Bold)
    window.LauncherMark.TextXAlignment = Enum.TextXAlignment.Center
    window.LauncherMark.Size = UDim2.fromScale(1, 1)
    window.LauncherScale = Prim.new("UIScale", { Scale = 1 }, window.Launcher)

    window:BindDrag()
    window:BindResponsive()
    window:SetTitle(config.Title or "Takataka", config.Subtitle)
    window:SetIdentity(config.Identity)
    if config.Accent then
        window:SetAccent(config.Accent)
    end
    WindowClass.Active = window
    return window
end

-- ── layout authority ─────────────────────────────────────────────────────────

function WindowClass:Layout()
    if self.Destroyed or not self.Window or not self.Window.Parent then
        return
    end
    local stage = MeasureStage(self)
    local compact = stage.X < 640 or stage.Y < 460
    local margin = compact and 8 or 20
    local width, height, scale
    if compact then
        width = math.max(280, stage.X - margin * 2)
        height = math.max(220, stage.Y - margin * 2)
        scale = math.min(1, self.UserScale or 1)
    else
        local band = (stage.X >= 1240 and stage.Y >= 760) and BAND_WIDE or BAND_STANDARD
        width, height = band.width, band.height
        scale = math.min(1, (stage.X - margin * 2) / width, (stage.Y - margin * 2) / height, self.UserScale or 1)
        scale = math.max(0.6, scale)
    end
    local design = {
        Width = width,
        Height = height,
        Scale = scale,
        Compact = compact,
        Stage = stage,
        Margin = margin,
    }
    self.Design = design

    local scaledWidth, scaledHeight = width * scale, height * scale
    self.Window.Size = UDim2.fromOffset(width, height)
    self.Scale.Scale = scale
    self.Position = ClampToStage(self.Position or Vector2.new(stage.X / 2, stage.Y / 2), stage, scaledWidth, scaledHeight, margin)
    Anim.Snap(self.Window, { Position = UDim2.fromOffset(self.Position.X, self.Position.Y) })
    Anim.Snap(self.Shadow, {
        Size = UDim2.fromOffset(scaledWidth + 10, scaledHeight + 12),
        Position = UDim2.fromOffset(self.Position.X, self.Position.Y + 7),
    })

    local topHeight = compact and 48 or 54
    local inset = compact and Theme.Space.L or Theme.Space.XXL
    Prim.place(self.TopBar, 0, 0, width, topHeight)
    Prim.place(self.Logo, 12, topHeight / 2 - 13, 26, 26)
    Prim.place(self.LogoMark, 0, 0, 26, 26)

    local identityWidth = width < 560 and 60 or 150
    Prim.place(self.Identity, width - identityWidth - 84, 0, identityWidth, topHeight)
    Prim.place(self.IdentityName, 0, 0, math.max(0, identityWidth - 34), topHeight)
    Prim.place(self.Avatar, identityWidth - 30, topHeight / 2 - 14, 28, 28)
    Prim.place(self.AvatarMark, 0, 0, 28, 28)
    -- Touch devices get larger header targets, spaced so hit areas never overlap.
    local actionSize = UserInputService.TouchEnabled and 36 or 32
    local actionGap = actionSize + 6
    Prim.place(self.SettingsButton.Root, width - 16 - actionGap - actionSize, topHeight / 2 - actionSize / 2, actionSize, actionSize)
    Prim.place(self.MinButton.Root, width - 16 - actionSize, topHeight / 2 - actionSize / 2, actionSize, actionSize)

    local navX = 50
    local navWidth = math.max(40, width - navX - identityWidth - 92)
    Prim.place(self.Nav, navX, 0, navWidth, topHeight)
    self:LayoutNav(navWidth, topHeight)

    local contentHeight = math.max(120, height - topHeight - (compact and Theme.Space.M or Theme.Space.L))
    Prim.place(self.Content, inset, topHeight, width - inset * 2, contentHeight)
    for _, page in ipairs(self.Pages) do
        page:Layout(width - inset * 2, contentHeight, compact)
    end
    Notify.Layout()
    if Modal.IsOpen then
        Modal.Layout()
    end
    self:LayoutLauncher()
end

function WindowClass:LayoutNav(available, topHeight)
    local gap = 4
    local total = 0
    for _, page in ipairs(self.Pages) do
        if not page.Hidden then
            page.NavChipWidth = math.min(170, Util.measureWidth(page.Name, Theme.Type.Small, Theme.Font.Medium) + (page.Icon and 46 or 26))
            total = total + page.NavChipWidth + gap
        end
    end
    local iconOnly = total > available
    local x = 0
    for _, page in ipairs(self.Pages) do
        if not page.Hidden then
            local chipWidth = iconOnly and 34 or page.NavChipWidth
            page.NavChip:Layout(chipWidth, 30, iconOnly, topHeight)
            page.NavChip.Root.Position = UDim2.fromOffset(x, topHeight / 2 - 15)
            x = x + chipWidth + gap
        end
    end
end

function WindowClass:BindResponsive()
    self.Scope:Connect(self.Root:GetPropertyChangedSignal("AbsoluteSize"), function()
        self:Layout()
    end)
    self.Scope:Connect(self.Root:GetPropertyChangedSignal("AbsolutePosition"), function()
        self:Layout()
    end)
    for _, property in ipairs({ "VirtualKeyboardVisible", "VirtualKeyboardPosition", "VirtualKeyboardSize", "TouchEnabled" }) do
        pcall(function()
            self.Scope:Connect(UserInputService:GetPropertyChangedSignal(property), function()
                self:Layout()
            end)
        end)
    end
    pcall(function()
        local camera = workspace.CurrentCamera
        if camera then
            self.Scope:Connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
                self:Layout()
            end)
        end
    end)
end

-- ── drag engine (window and launcher share one set of connections) ───────────

function WindowClass:BindDrag()
    local window = self
    window.Scope:Connect(window.TopBar.InputBegan, function(input)
        local kind = input.UserInputType
        if not window.Visible or window.Minimized or window.Drag then
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end
        if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
            return
        end
        local point = input.Position
        if Util.hit(point, window.SettingsButton.Root) or Util.hit(point, window.MinButton.Root) or Util.hit(point, window.Avatar) then
            return
        end
        for _, page in ipairs(window.Pages) do
            if page.NavChip and page.NavChip.Root.Visible and Util.hit(point, page.NavChip.Root) then
                return
            end
        end
        Popover.Close(true)
        window.Drag = { Input = input, Start = point, From = window.Position }
    end)
    window.Scope:Connect(window.Launcher.InputBegan, function(input)
        local kind = input.UserInputType
        if not window.Minimized then
            return
        end
        if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
            return
        end
        window.LauncherDrag = { Input = input, Start = input.Position, From = window.Launcher.Position, Moved = false }
    end)
    window.Scope:Connect(UserInputService.InputChanged, function(input)
        if window.Drag then
            local drag = window.Drag
            if drag.Input.UserInputType == Enum.UserInputType.Touch then
                if input ~= drag.Input then
                    return
                end
            elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
                return
            end
            local design = window.Design
            if not design then
                return
            end
            local delta = input.Position - drag.Start
            local target = ClampToStage(
                drag.From + delta,
                design.Stage,
                design.Width * design.Scale,
                design.Height * design.Scale,
                design.Margin
            )
            window.Position = target
            Anim.To(window.Window, { Position = UDim2.fromOffset(target.X, target.Y) }, Motion.Drag)
            Anim.Snap(window.Shadow, { Position = UDim2.fromOffset(target.X, target.Y + 7) })
            if Modal.IsOpen then
                Modal.Layout()
            end
        elseif window.LauncherDrag then
            local drag = window.LauncherDrag
            if drag.Input.UserInputType == Enum.UserInputType.Touch then
                if input ~= drag.Input then
                    return
                end
            elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
                return
            end
            local delta = input.Position - drag.Start
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
                drag.Moved = true
            end
            local stage = MeasureStage(window)
            local target = drag.From + delta
            target = Vector2.new(
                Util.clamp(target.X, 8, math.max(8, stage.X - 60)),
                Util.clamp(target.Y, 8, math.max(8, stage.Y - 60))
            )
            window.LauncherPosition = target
            Anim.Snap(window.Launcher, { Position = target })
        end
    end)
    window.Scope:Connect(UserInputService.InputEnded, function(input)
        if window.Drag and (input == window.Drag.Input or input.UserInputType == Enum.UserInputType.MouseButton1) then
            window.Drag = nil
        end
        if window.LauncherDrag and (input == window.LauncherDrag.Input or input.UserInputType == Enum.UserInputType.MouseButton1) then
            window.LauncherDrag = nil
        end
    end)
    window.Scope:Connect(UserInputService.WindowFocusReleased, function()
        window.Drag = nil
        window.LauncherDrag = nil
    end)
    window.Scope:Connect(window.Launcher.Activated, function()
        if window.Minimized and not (window.LauncherDrag and window.LauncherDrag.Moved) then
            window:Restore()
        end
    end)
    window.Scope:Connect(window.Launcher.MouseEnter, function()
        if window.Minimized then
            Anim.To(window.LauncherScale, { Scale = 1.06 }, Motion.Micro)
        end
    end)
    window.Scope:Connect(window.Launcher.MouseLeave, function()
        Anim.To(window.LauncherScale, { Scale = 1 }, Motion.Micro)
    end)
end

function WindowClass:LayoutLauncher()
    if not self.Minimized then
        return
    end
    local stage = MeasureStage(self)
    local design = self.Design or {}
    local position = self.LauncherPosition
    if not position then
        local anchorX = (self.Position and self.Position.X or stage.X / 2)
            + (design.Width or 900) * (design.Scale or 1) / 2 - 66
        position = Vector2.new(anchorX, self.Position and self.Position.Y or 40)
    end
    position = Vector2.new(
        Util.clamp(position.X, 8, math.max(8, stage.X - 60)),
        Util.clamp(position.Y, 8, math.max(8, stage.Y - 60))
    )
    self.LauncherPosition = position
    Prim.place(self.Launcher, position.X, position.Y, Theme.Metric.Launcher, Theme.Metric.Launcher)
end

-- ── navigation ───────────────────────────────────────────────────────────────

function WindowClass:AddPage(config)
    config = config or {}
    local page = Page.new(self.Scope, self.Content, config)
    page.Name = Util.text(config.Name or "Page", 22)
    page.Icon = config.Icon
    page.Hidden = config.Hidden == true
    page.Owner = self
    page.NavChip = Components.NavChip(self.Scope, self.Nav, {
        Name = page.Name,
        Icon = page.Icon,
        Callback = function()
            self:SetPage(page)
        end,
    })
    if page.Hidden then
        page.NavChip.Root.Visible = false
    end
    table.insert(self.Pages, page)
    self.PageIndex[page.Name] = page
    if not self.Current then
        self.Current = page
        page:SetVisible(true)
        page.NavChip:SetActive(true, false)
    else
        page:SetVisible(false)
    end
    self:Layout()
    return page
end

function WindowClass:SetPage(target, force)
    if self.Destroyed then
        return false
    end
    if type(target) == "string" then
        target = self.PageIndex[target]
    end
    if not target then
        return false
    end
    if self.Current == target and not force then
        return true
    end
    self.Token = self.Token + 1
    local token = self.Token
    local previous = self.Current
    self.Current = target
    Popover.Close(true)
    if previous then
        previous.NavChip:SetActive(false)
        Anim.To(previous.Root, { GroupTransparency = 1 }, Motion.Fast, function()
            if previous ~= self.Current then
                previous:SetVisible(false)
                previous.Root.GroupTransparency = 0
            end
        end)
    end
    target:SetVisible(true)
    if target.Layout then
        target:Layout(self.Content.AbsoluteSize.X, self.Content.AbsoluteSize.Y, self.Design and self.Design.Compact)
    end
    target.Root.GroupTransparency = Motion.Reduced and 0 or 1
    target.NavChip:SetActive(true)
    Anim.To(target.Root, { GroupTransparency = 0 }, Motion.Normal)
    if Motion.Reduced then
        target.Root.GroupTransparency = 0
    end
    if target.OnShow then
        Util.guard(target.OnShow)
    end
    return true
end

function WindowClass:GetPage()
    return self.Current
end

-- ── identity / chrome ────────────────────────────────────────────────────────

function WindowClass:SetTitle(title, subtitle)
    self.Config.Title = title or self.Config.Title or "Takataka"
    self.Config.Subtitle = subtitle or self.Config.Subtitle
    local text = Util.text(self.Config.Title, 26)
    local initial = text:sub(1, 1):upper()
    self.LogoMark.Text = initial
    self.LauncherMark.Text = initial
    return self
end

function WindowClass:SetIdentity(identity)
    self.Identity = identity or self.Identity or {}
    local name = Util.text(self.Identity.Name or "Guest", 24)
    self.IdentityName.Text = name
    self.AvatarMark.Text = name:sub(1, 1):upper()
    return self
end

function WindowClass:SetAccent(color)
    if typeof(color) ~= "Color3" then
        return self
    end
    self.Accent = color
    Theme.Color.Accent = color
    Theme.Color.AccentHover = color:Lerp(Color3.new(1, 1, 1), 0.18)
    Theme.Color.AccentPressed = color:Lerp(Color3.new(0, 0, 0), 0.18)
    Theme.Color.AccentDeep = color:Lerp(Color3.new(0, 0, 0), 0.45)
    Theme.AccentStops = { Theme.Color.Magenta, color }
    Theme.AuroraStops = { Theme.Color.Magenta, Theme.Color.Peach, color, Theme.Color.Magenta }
    Components.RefreshAll()
    return self
end

function WindowClass:ToggleSettings()
    if Popover.Current or self.Minimized then
        Popover.Close(true)
        return
    end
    local rows = {}
    Popover.Open({
        Anchor = self.SettingsButton.Root,
        Width = 268,
        Height = 236,
        MaxHeight = 320,
        Fill = function(menu, container, width)
            local y = 6
            local function add(row, height)
                row.Height = height
                row.Root.Position = UDim2.fromOffset(4, y)
                row.Root.Size = UDim2.fromOffset(width, height)
                if row.Layout then
                    row:Layout(width)
                end
                y = y + height + 6
                table.insert(rows, row)
            end
            add(Components.SelectRow(menu.Scope, container, {
                Name = "Interface scale",
                Options = { { Value = 1, Text = "100%" }, { Value = 0.9, Text = "90%" }, { Value = 0.8, Text = "80%" }, { Value = 1.12, Text = "112%" } },
                Default = self.UserScale or 1,
                Callback = function(value)
                    self.UserScale = value
                    self:Layout()
                end,
            }), 38)
            add(Components.Toggle(menu.Scope, container, {
                Name = "Reduce motion",
                Default = Motion.Reduced,
                Height = 34,
                Callback = function(value)
                    Motion.SetReduced(value)
                    Components.RefreshAll()
                end,
            }), 34)
            add(Components.SelectRow(menu.Scope, container, {
                Name = "Accent",
                Options = { { Value = "violet", Text = "Violet" }, { Value = "magenta", Text = "Magenta" }, { Value = "lime", Text = "Lime" }, { Value = "amber", Text = "Amber" } },
                Default = "violet",
                Callback = function(value)
                    if Theme.Palette[value] then
                        self:SetAccent(Theme.Palette[value])
                    end
                end,
            }), 38)
            container.Size = UDim2.new(1, 0, 0, y + 4)
        end,
    })
    return self
end

-- ── visibility / minimize / restore ──────────────────────────────────────────

function WindowClass:SetVisible(value)
    value = value ~= false
    if self.Visible == value and not self.Minimized then
        return self
    end
    self.Visible = value
    if value then
        self.Window.Visible = true
        self.Window.GroupTransparency = Motion.Reduced and 0 or 1
        Anim.To(self.Window, { GroupTransparency = 0 }, Motion.Emphasized)
        Popover.Close(true)
    else
        Popover.Close(true)
        self.Token = self.Token + 1
        Anim.To(self.Window, { GroupTransparency = 1 }, Motion.Exit, function()
            if not self.Visible and not self.Minimized then
                self.Window.Visible = false
            end
        end)
    end
    return self
end

function WindowClass:IsVisible()
    return self.Visible and not self.Minimized and not self.Destroyed
end

function WindowClass:Minimize()
    if self.Destroyed or self.Minimized then
        return self
    end
    self.Minimized = true
    self.Visible = false
    self.Drag = nil
    self.Token = self.Token + 1
    Popover.Close(true)
    if Modal.IsOpen then
        Modal.Close(true)
    end
    local design = self.Design or {}
    local scale = design.Scale or 1
    local position = self.Position or Vector2.new(0, 0)
    local stage = MeasureStage(self)
    local launcherX = position.X + (design.Width or 900) * scale / 2 - 66
    self.LauncherPosition = Vector2.new(
        Util.clamp(launcherX, 8, math.max(8, stage.X - 60)),
        Util.clamp(position.Y, 8, math.max(8, stage.Y - 60))
    )
    self:LayoutLauncher()
    self.Launcher.Visible = true
    self.LauncherScale.Scale = Motion.Reduced and 1 or 0.72
    self.Launcher.GroupTransparency = Motion.Reduced and 0 or 1
    Anim.To(self.Launcher, { GroupTransparency = 0 }, Motion.Normal)
    Anim.To(self.LauncherScale, { Scale = 1 }, Motion.Normal)
    Anim.To(self.Window, { GroupTransparency = 1 }, Motion.Fast, function()
        if self.Minimized then
            self.Window.Visible = false
        end
    end)
    return self
end

function WindowClass:Restore()
    if self.Destroyed or not self.Minimized then
        return self
    end
    self.Minimized = false
    self.Visible = true
    self.Token = self.Token + 1
    self.Window.Visible = true
    self.Window.GroupTransparency = Motion.Reduced and 0 or 1
    Anim.To(self.Window, { GroupTransparency = 0 }, Motion.Normal)
    Anim.To(self.Launcher, { GroupTransparency = 1 }, Motion.Fast, function()
        if not self.Minimized then
            self.Launcher.Visible = false
        end
    end)
    self:Layout()
    return self
end

function WindowClass:ToggleMinimize()
    if self.Minimized then
        return self:Restore()
    end
    return self:Minimize()
end

function WindowClass:Notify(config)
    if self.Destroyed then
        return nil
    end
    return Notify.Push(config)
end

function WindowClass:OpenModal(config)
    return Modal.Open(config)
end

function WindowClass:CloseModal()
    Modal.Close()
end

function WindowClass:Confirm(config)
    return Modal.Confirm(config)
end

function WindowClass:Alert(config)
    return Modal.Alert(config)
end

function WindowClass:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    self.Token = self.Token + 1
    Notify.Clear()
    Popover.Close(true)
    Tooltip.Hide()
    Context.Close()
    if Modal.IsOpen then
        Modal.Close(true, true)
    end
    for _, page in ipairs(self.Pages) do
        page:Destroy()
    end
    self.Pages = {}
    self.PageIndex = {}
    self.Current = nil
    self.Scope:Destroy()
    Anim.CancelTree(self.Root)
    if self.Screen then
        self.Screen:Destroy()
    end
    self.Screen = nil
    if WindowClass.Active == self then
        WindowClass.Active = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NavChip — compact top navigation entry. Active = accent fill + on-accent text.
-- ══════════════════════════════════════════════════════════════════════════════

function Components.NavChip(scope, parent, config)
    config = config or {}
    local chip = { Scope = scope, Active = false, Hovered = false, Pressed = false, Visible = true }
    chip.Root = Prim.new("TextButton", {
        Name = "Nav_" .. tostring(config.Name or "Page"),
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Color.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(96, 30),
        Active = true,
        Selectable = true,
    }, parent)
    Prim.corner(chip.Root, Theme.Radius.Small)
    chip.Fill = Prim.frame(chip.Root, "Fill", Theme.Color.White)
    chip.Fill.Size = UDim2.fromScale(1, 1)
    chip.Fill.BackgroundTransparency = 1
    Prim.corner(chip.Fill, Theme.Radius.Small)
    Prim.aurora(chip.Fill, scope, 0)
    local labelX = 12
    if config.Icon then
        chip.Icon = Prim.Icon.new(chip.Root, config.Icon, Theme.Color.TextMuted, 13, 1.6)
        chip.Icon.Root.AnchorPoint = Vector2.new(0, 0.5)
        chip.Icon.Root.ZIndex = 2
    end
    chip.Label = Prim.label(chip.Root, "Label", Util.text(config.Name or "", 20), Theme.Type.Small, Theme.Color.TextSecondary, Theme.Font.Medium)
    chip.Label.ZIndex = 2
    chip.IconOnly = false

    function chip:Layout(width, height, iconOnly, topHeight)
        self.Width = width
        self.IconOnly = iconOnly == true
        self.Root.Size = UDim2.fromOffset(width, height)
        local scale = (topHeight and topHeight < 60) and 0.86 or 1
        self.Label.TextSize = math.max(10, math.floor(Theme.Type.Small * scale))
        if self.Icon then
            if iconOnly then
                Prim.place(self.Icon.Root, width / 2 - 7, height / 2 - 7, 14, 14)
                self.Label.Visible = false
            else
                Prim.place(self.Icon.Root, 12, height / 2 - 7, 13, 13)
                self.Label.Visible = true
                Prim.place(self.Label, 31, 0, width - 40, height)
            end
        else
            self.Label.Visible = true
            Prim.place(self.Label, iconOnly and 0 or 12, 0, iconOnly and width or (width - 20), height)
            self.Label.TextXAlignment = iconOnly and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        end
        self:Apply()
    end

    function chip:Apply()
        local fillTarget = self.Active and 0 or 1
        Anim.To(self.Fill, { BackgroundTransparency = fillTarget }, Motion.Fast)
        Anim.To(self.Root, {
            BackgroundTransparency = self.Active and 1 or (self.Hovered and 0.8 or 1),
            BackgroundColor3 = self.Pressed and Theme.Color.SurfacePressed or Theme.Color.SurfaceHover,
        }, Motion.Micro)
        local color = Theme.Color.TextSecondary
        if self.Active then
            color = Theme.Color.OnAccent
        elseif self.Hovered then
            color = Theme.Color.Text
        end
        self.Label.TextColor3 = color
        if self.Icon then
            self.Icon:SetColor(color)
        end
    end

    function chip:SetActive(value, animate)
        local next = value == true
        if self.Active == next then
            return
        end
        self.Active = next
        if animate == false or Motion.Reduced then
            Anim.Snap(self.Fill, { BackgroundTransparency = self.Active and 0 or 1 })
        end
        self:Apply()
    end

    function chip:SetVisible(value)
        self.Visible = value ~= false
        self.Root.Visible = self.Visible
    end

    function chip:Destroy()
        Anim.CancelTree(self.Root)
        self.Root:Destroy()
    end

    scope:Connect(chip.Root.MouseEnter, function()
        chip.Hovered = true
        chip:Apply()
    end)
    scope:Connect(chip.Root.MouseLeave, function()
        chip.Hovered = false
        chip.Pressed = false
        chip:Apply()
    end)
    scope:Connect(chip.Root.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            chip.Pressed = true
            chip:Apply()
        end
    end)
    scope:Connect(chip.Root.InputEnded, function()
        if chip.Pressed then
            chip.Pressed = false
            chip:Apply()
        end
    end)
    scope:Connect(chip.Root.Activated, function()
        if config.Callback then
            Util.guard(config.Callback)
        end
    end)
    chip:Apply()
    return Components.Register(chip)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Library — public surface. Small, consistent, fluent.
-- ══════════════════════════════════════════════════════════════════════════════

-- Internals are exposed read-only for diagnostics and offline test harnesses.
Library.__internal.Anim = Anim
Library.__internal.Prim = Prim
Library.__internal.Scope = Scope
Library.__internal.Theme = Theme
Library.__internal.Motion = Motion
Library.__internal.Util = Util
Library.__internal.Components = Components
Library.__internal.Layers = Layers
Library.__internal.Page = Page
Library.__internal.Window = WindowClass
Library.__internal.Tooltip = Tooltip
Library.__internal.Context = Context

function Library.resolveParent()
    local candidates = {}
    local hidden = Util.capability("gethui")
    if hidden then
        local ok, parent = pcall(hidden)
        if ok and typeof(parent) == "Instance" then
            table.insert(candidates, parent)
        end
    end
    local ok, core = pcall(function()
        return CoreGuiService
    end)
    if ok and core then
        table.insert(candidates, core)
    end
    local player = Players.LocalPlayer
    local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        table.insert(candidates, playerGui)
    end
    local chosen
    for _, parent in ipairs(candidates) do
        local probe = Instance.new("ScreenGui")
        local allowed = pcall(function()
            probe.Parent = parent
        end)
        probe:Destroy()
        if allowed and not chosen then
            chosen = parent
        end
    end
    if not chosen and player then
        local lateGui = player:WaitForChild("PlayerGui", 5)
        if lateGui then
            chosen = lateGui
        end
    end
    return chosen or (player and player:FindFirstChildOfClass("PlayerGui"))
end

-- Removes any UI left behind by a previous execution of this file.
function Library.cleanupPrevious(parent)
    for _, candidate in ipairs({ CoreGuiService, parent }) do
        pcall(function()
            for _, child in ipairs(candidate:GetChildren()) do
                if child:IsA("ScreenGui") and child:GetAttribute("TakatakaOwned") then
                    local dispose = child:FindFirstChild("TakatakaDispose")
                    if dispose and dispose:IsA("BindableEvent") then
                        dispose:Fire()
                    end
                    child:Destroy()
                end
            end
        end)
    end
end

function Library:CreateWindow(config)
    config = config or {}
    local environment = (type(getgenv) == "function" and getgenv()) or _G
    if type(environment) == "table" then
        local previous = rawget(environment, "__TakatakaUi")
        if type(previous) == "table" and previous.__TakatakaOwned and type(previous.DestroyWindow) == "function" then
            pcall(previous.DestroyWindow, previous)
        end
        environment.__TakatakaUi = self
    end
    self.__TakatakaOwned = true
    if self.Window and not self.Window.Destroyed then
        self.Window:Destroy()
    end
    local parent = self.resolveParent()
    if not parent then
        error("[Takataka] no accessible UI parent (CoreGui / PlayerGui unavailable)", 0)
    end
    self.cleanupPrevious(parent)
    local window = WindowClass.new(self, config, parent)
    self.Window = window
    local dispose = Prim.new("BindableEvent", { Name = "TakatakaDispose" }, window.Screen)
    window.Scope:Connect(dispose.Event, function()
        window:Destroy()
    end)
    window.Scope:Connect(window.Screen.Destroying, function()
        window:Destroy()
    end)
    window:Layout()
    task.defer(function()
        if window.Screen and window.Screen.Parent then
            Anim.To(window.Window, { GroupTransparency = 0 }, Motion.Emphasized)
        end
    end)
    return window
end

function Library:GetWindow()
    return self.Window
end

function Library:DestroyWindow()
    if self.Window and not self.Window.Destroyed then
        self.Window:Destroy()
    end
    self.Window = nil
end

function Library:Destroy()
    self:DestroyWindow()
    Notify.Clear()
    Popover.Close(true)
    Tooltip.Hide()
    Context.Close()
    Anim.DestroyAll()
    local environment = (type(getgenv) == "function" and getgenv()) or _G
    if type(environment) == "table" and rawget(environment, "__TakatakaUi") == self then
        environment.__TakatakaUi = nil
    end
end

function Library:Notify(config)
    return Notify.Push(config)
end

function Library:ClearNotifications()
    Notify.Clear()
end

function Library:OpenModal(config)
    return Modal.Open(config)
end

function Library:CloseModal()
    Modal.Close()
    return self
end

function Library:Confirm(config)
    return Modal.Confirm(config)
end

function Library:Alert(config)
    return Modal.Alert(config)
end

function Library:SetAccent(color, silent)
    Theme.Color.Accent = color
    Theme.Color.AccentHover = color:Lerp(Color3.new(1, 1, 1), 0.18)
    Theme.Color.AccentPressed = color:Lerp(Color3.new(0, 0, 0), 0.18)
    Theme.Color.AccentDeep = color:Lerp(Color3.new(0, 0, 0), 0.45)
    Theme.AccentStops = { Theme.Color.Magenta, color }
    Theme.AuroraStops = { Theme.Color.Magenta, Theme.Color.Peach, color, Theme.Color.Magenta }
    Theme.Art.accent.orb = color
    Theme.Art.accent.orb2 = Theme.Color.Magenta
    Prim.RefreshFills()
    if not silent then
        Components.RefreshAll()
        if self.Window then
            self.Window:SetAccent(color)
        end
    end
end

function Library:SetReducedMotion(value)
    Motion.SetReduced(value)
    Components.RefreshAll()
end

function Library:GetTheme()
    return Theme
end

function Library:SetArtTone(tone, patch)
    if type(Theme.Art[tone]) == "table" and type(patch) == "table" then
        Util.merge(Theme.Art[tone], patch)
        Components.RefreshAll()
    end
end

function Library:SetTheme(patch)
    Theme.Set(patch)
    Components.RefreshAll()
    if self.Window then
        self.Window:Layout()
    end
end

function Library:GetScale()
    return self.Window and self.Window.UserScale or 1
end

function Library:SetScale(value)
    if self.Window then
        self.Window.UserScale = Util.clamp(Util.finite(value, 1), 0.6, 1.4)
        self.Window:Layout()
    end
end

-- ── bootstrap ────────────────────────────────────────────────────────────────

local BOOT_OK, BOOT_ERROR = pcall(function()
    local environment = (type(getgenv) == "function" and getgenv()) or _G
    if type(environment) == "table" then
        local previous = rawget(environment, "__TakatakaUi")
        if type(previous) == "table" and previous.__TakatakaOwned and type(previous.DestroyWindow) == "function" then
            pcall(previous.DestroyWindow, previous)
        end
        environment.__TakatakaUi = Library
    end
    Library.__TakatakaOwned = true
end)

if not BOOT_OK then
    warn("[Takataka] bootstrap error: " .. tostring(BOOT_ERROR))
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Demo — an opt-in showcase built entirely from public components.
-- Nothing here runs unless Library:Demo() is called.
-- ══════════════════════════════════════════════════════════════════════════════

local DEMO_MODULES = {
    { Id = "aurora", Name = "Aurora", Category = "Visual", Status = "ready", Tone = "visual", Mark = "A",
      Copy = "Scene grading, adaptive contrast and weather-aware lighting.",
      Meta = { { Label = "Render", Value = "Deferred" }, { Label = "Cost", Value = "Low" }, { Label = "Build", Value = "2.4.1" } } },
    { Id = "nomad", Name = "Nomad", Category = "Movement", Status = "ready", Tone = "movement", Mark = "N",
      Copy = "Traversal assist with predictive pathing and terrain memory.",
      Meta = { { Label = "Latency", Value = "12 ms" }, { Label = "Cost", Value = "Low" }, { Label = "Build", Value = "3.0.0" } } },
    { Id = "vertex", Name = "Vertex", Category = "Utility", Status = "updating", Tone = "utility", Mark = "V",
      Copy = "Inventory intelligence, sorting rules and container automation.",
      Meta = { { Label = "Queue", Value = "Batched" }, { Label = "Cost", Value = "Medium" }, { Label = "Build", Value = "1.9.7" } } },
    { Id = "halcyon", Name = "Halcyon", Category = "Visual", Status = "ready", Tone = "visual", Mark = "H",
      Copy = "Long-range perception layer with confidence-weighted overlays.",
      Meta = { { Label = "Range", Value = "480 m" }, { Label = "Cost", Value = "Medium" }, { Label = "Build", Value = "4.1.0" } } },
    { Id = "lumen", Name = "Lumen", Category = "Utility", Status = "ready", Tone = "utility", Mark = "L",
      Copy = "Readable telemetry for sessions that run for hours.",
      Meta = { { Label = "Sample", Value = "10 Hz" }, { Label = "Cost", Value = "Low" }, { Label = "Build", Value = "2.0.3" } } },
    { Id = "cascade", Name = "Cascade", Category = "Movement", Status = "updating", Tone = "movement", Mark = "C",
      Copy = "Momentum preservation for vertical routes and chained drops.",
      Meta = { { Label = "Impulse", Value = "Soft" }, { Label = "Cost", Value = "Low" }, { Label = "Build", Value = "1.4.2" } } },
    { Id = "onyx", Name = "Onyx", Category = "Combat", Status = "ready", Tone = "combat", Mark = "O",
      Copy = "Deterministic engagement timing with reaction budgeting.",
      Meta = { { Label = "Window", Value = "±40 ms" }, { Label = "Cost", Value = "High" }, { Label = "Build", Value = "5.2.0" } } },
    { Id = "prism", Name = "Prism", Category = "Combat", Status = "ready", Tone = "combat", Mark = "P",
      Copy = "Shot grouping analysis and recoil envelope modelling.",
      Meta = { { Label = "Samples", Value = "1 024" }, { Label = "Cost", Value = "Medium" }, { Label = "Build", Value = "2.8.5" } } },
}

local DEMO_CATEGORIES = { "All", "Visual", "Movement", "Utility", "Combat" }

function Library:Demo()
    if self.DemoWindow and not self.DemoWindow.Destroyed then
        self.DemoWindow:Restore()
        self.DemoWindow:SetVisible(true)
        return self.DemoWindow
    end

    local window = self:CreateWindow({
        Title = "Takataka",
        Subtitle = "Premium Interface",
        Mark = "T",
        Identity = { Name = "Guest" },
    })
    self.DemoWindow = window

    local state = {
        Category = "All",
        Query = "",
        Selected = DEMO_MODULES[1],
        LaunchBusy = false,
        SignedIn = false,
        Progress = 0.34,
    }

    -- ── Home ─────────────────────────────────────────────────────────────────
    local home = window:AddPage({ Name = "Home", Icon = "home" })
    local hero = home:AddHero({
        Headline = {
            { Text = "Sharper tools for" },
            { Text = "quieter sessions", Accent = true },
            { Text = "that stay precise" },
        },
        Copy = "A restrained interface for long automation runs. Every control is measured, every state is legible, and nothing shouts for attention.",
        Mark = "T",
        Height = 214,
    })
    local row = home:AddCardRow({ Weights = { 0.42, 0.29, 0.29 }, Height = 154, Dots = 3 })
    local announcement = row:Add(Components.Card(window.Scope, row.Root, {
        Name = "Announcement",
        Variant = "photo",
        Tone = "accent",
        Mark = "A",
        Chip = "Release 5.2",
        ChipType = "neutral",
        Text = "Prism 2.8 adds recoil envelopes and a calmer overlay.",
        Pill = "Updated today",
        Callback = function()
            window:SetPage("Catalog")
        end,
    }))
    row:Add(Components.Card(window.Scope, row.Root, {
        Name = "Featured",
        Variant = "color",
        Tone = Theme.Palette.mint,
        Title = "Onyx",
        Text = "Deterministic engagement timing.",
        Chip = "Module of the week",
        ChipType = "neutral",
        Actions = {
            { Icon = "bookmark", Tooltip = "Save to workspace", Callback = function()
                window:Notify({ Title = "Saved", Text = "Onyx added to your workspace", Type = "success" })
            end },
            { Icon = "arrow", Tooltip = "Open module", Callback = function()
                window:SetPage("Catalog")
            end },
        },
        Callback = function()
            window:SetPage("Catalog")
        end,
    }))
    row:Add(Components.Card(window.Scope, row.Root, {
        Name = "Platforms",
        Variant = "gradient",
        Title = "Runs anywhere",
        Text = "Desktop, tablet and phone layouts ship together.",
    }))
    row.ActiveDot = 1
    state.DotIndex = 1
    local function advanceDots()
        if window.Destroyed then
            return
        end
        state.DotIndex = (state.DotIndex % 3) + 1
        row:SetDot(state.DotIndex)
        window.Scope:Later(4.5, advanceDots)
    end
    window.Scope:Later(4.5, advanceDots)

    home:AddBanner({
        Type = "accent",
        Icon = "spark",
        Title = "Sign in to sync your workspace",
        Text = "Profiles, saved modules and interface preferences follow you between sessions.",
    })
    home:AddButton({ Name = "Sign in", Text = "Sign in", Style = "primary", Callback = function()
        Library.openAuthModal(window, state)
    end })
    home:AddText({ Title = "About this showcase", Text = "Every control on the Settings page is live: toggles persist in memory, sliders clamp, dropdowns open above the content, notifications stack and the window minimizes into a draggable launcher." })

    -- ── Catalog ──────────────────────────────────────────────────────────────
    local catalog = window:AddPage({ Name = "Catalog", Icon = "grid" })
    local catalogHeader = catalog:AddSection({
        Name = "Module catalog",
        Description = "Filter by discipline or search by name.",
    })
    catalogHeader:AddSegmented({
        Options = DEMO_CATEGORIES,
        Default = "All",
        Callback = function(value)
            state.Category = value
            catalog.OnShow()
        end,
    })
    catalogHeader:AddTextbox({
        Name = "Search",
        Icon = "search",
        Placeholder = "Find a module",
        Callback = function(value)
            state.Query = string.lower(Util.trim(value))
            catalog.OnShow()
        end,
    })
    catalogHeader:AddSpacer(4)

    local grid = catalog:AddGrid({ ColumnWidth = 168, MaxColumns = 4, Gap = Theme.Space.L, RowHeight = 232,
        Empty = { Title = "No modules found", Text = "Adjust the filter or clear the search to see the full catalog." } })
    for _, entry in ipairs(DEMO_MODULES) do
        local tile = Components.ProductTile(window.Scope, grid.Root, {
            Name = entry.Name,
            Title = entry.Name,
            Subtitle = entry.Category,
            Mark = entry.Mark,
            Status = entry.Status,
            StatusIcon = entry.Status == "ready" and "check" or "refresh",
            Callback = function()
                state.Selected = entry
                window:SetPage("Detail")
            end,
        })
        tile.Module = entry
        -- Contextual action layer: right click (desktop) or long press (touch).
        local holdThread
        local function openContext(position)
            Context.Open({
                { Text = "Open module", Shortcut = "Enter", Callback = function()
                    state.Selected = entry
                    window:SetPage("Detail")
                end },
                { Text = "Save to workspace", Callback = function()
                    window:Notify({ Title = "Saved", Text = entry.Name .. " added to your workspace", Type = "success" })
                end },
                { Separator = true },
                { Text = "Copy build id", Shortcut = "⌘C", Callback = function()
                    local copy = Util.capability("setclipboard") or Util.capability("toclipboard")
                    local ok = copy and pcall(copy, entry.Id)
                    window:Notify({
                        Title = ok and "Copied" or "Copy unavailable",
                        Text = ok and (entry.Id .. " is on your clipboard") or "Clipboard access is blocked here",
                        Type = ok and "success" or "warning",
                    })
                end },
                { Text = "Remove", Danger = true, Callback = function()
                    window:Confirm({
                        Title = "Remove " .. entry.Name .. "?",
                        Text = "This only affects the current workspace.",
                        ConfirmText = "Remove",
                        ConfirmStyle = "danger",
                        OnConfirm = function()
                            window:Notify({ Title = "Removed", Text = entry.Name .. " left the workspace", Type = "neutral" })
                        end,
                    })
                end },
            }, position)
        end
        tile.Scope:Connect(tile.Root.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                openContext(input.Position)
            elseif input.UserInputType == Enum.UserInputType.Touch then
                holdThread = tile.Scope:Later(0.5, function()
                    openContext(Vector2.new(tile.Root.AbsolutePosition.X + 40, tile.Root.AbsolutePosition.Y + 40))
                end)
            end
        end)
        tile.Scope:Connect(tile.Root.InputEnded, function()
            if holdThread then
                tile.Scope:Cancel(holdThread)
                holdThread = nil
            end
        end)
        grid:Add(tile)
    end
    catalog.OnShow = function()
        if window.Destroyed then
            return
        end
        if not state.SkeletonDone then
            state.SkeletonDone = true
            for _, tile in ipairs(grid.Items) do
                if tile.Module.Status == "updating" then
                    tile:SetLoading(true)
                end
            end
            window.Scope:Later(1.4, function()
                if window.Destroyed then
                    return
                end
                for _, tile in ipairs(grid.Items) do
                    tile:SetLoading(false)
                end
            end)
        end
        local visible = 0
        for _, tile in ipairs(grid.Items) do
            local entry = tile.Module
            local matchesCategory = state.Category == "All" or entry.Category == state.Category
            local matchesQuery = state.Query == "" or string.find(string.lower(entry.Name), state.Query, 1, true) ~= nil
            tile:SetVisible(matchesCategory and matchesQuery)
            if matchesCategory and matchesQuery then
                visible = visible + 1
            end
        end
        grid:Layout(catalog.Width or 800)
        catalog:Reflow()
        catalog:Layout(window.Content.AbsoluteSize.X, window.Content.AbsoluteSize.Y, window.Design and window.Design.Compact)
    end

    -- ── Detail (hidden page with a breadcrumb) ───────────────────────────────
    local detail = window:AddPage({ Name = "Detail", Icon = "layers", Hidden = true })
    detail:SetHeader({
        Back = "Catalog",
        OnBack = function()
            window:SetPage("Catalog")
        end,
    })
    local media = detail:AddMedia({ Aspect = 0.5, Duration = 60, Progress = 0.42, Playing = false, Mark = "T" })
    local infoSection = detail:AddSection({ Name = "Information", Side = "Right", Weight = 1 })
    infoSection:AddSegmented({
        Options = {
            { Value = "lite", Text = "Lite" },
            { Value = "raid", Text = "Raid" },
            { Value = "lab", Text = "Experimental", Disabled = true },
        },
        Default = "lite",
        Callback = function(value)
            window:Notify({ Title = "Profile", Text = value .. " profile selected", Type = "neutral", Duration = 2 })
        end,
    })
    infoSection:AddSpacer(2)
    local keyField = infoSection:AddTextbox({ Name = "Access key", Icon = "lock", Placeholder = "Enter key" })
    local launchProgress = infoSection:AddProgress({ Default = 0 })
    local launchButton = infoSection:AddButton({
        Name = "Start session",
        Text = "START",
        Style = "primary",
        Full = true,
        Callback = function(self)
            if state.LaunchBusy then
                return
            end
            if keyField:Get() == "" then
                window:Notify({ Title = "Key required", Text = "Enter an access key to continue", Type = "warning" })
                return
            end
            state.LaunchBusy = true
            self:SetBusy(true)
            local steps = 0
            launchProgress:SetValue(0, true)
            local stepThread
            stepThread = window.Scope:Later(0.5, function()
                if window.Destroyed then
                    return
                end
                steps = steps + 1
                launchProgress:SetValue(math.min(1, steps * 0.25))
                if steps < 4 then
                    stepThread = window.Scope:Later(0.5, stepThread)
                else
                    state.LaunchBusy = false
                    if self.SetBusy then
                        self:SetBusy(false)
                    end
                    launchProgress:SetValue(1)
                    window:Notify({ Title = "Session ready", Text = "Handshake accepted", Type = "success" })
                end
            end)
        end,
    })
    infoSection:AddButton({ Name = "Compare builds", Text = "Compare builds", Style = "secondary", Full = true, Callback = function()
        window:Alert({ Title = "Build comparison", Text = "Prism 2.8.5 is 4% faster than 2.8.4 on the same workload.", Icon = "info" })
    end })
    infoSection:AddSpacer(2)
    local detailMeta = detail:AddMetadata({ Columns = 3, Side = "Left", Items = {
        { Label = "Processor", Value = "Ryzen 5" },
        { Label = "Graphics", Value = "RTX 3060" },
        { Label = "Memory", Value = "16 GB" },
        { Label = "Runtime", Value = "Luau 0.6" },
        { Label = "Storage", Value = "320 MB" },
        { Label = "Network", Value = "12 ms" },
    } })
    local detailTitle = detail:AddSection({ Name = "Prism", Side = "Left", Icon = "spark", Description = "Shot grouping analysis and recoil envelope modelling." })
    local statusBadge = detailTitle:AddLabel({ Text = "Verified build · 5.2.0", Color = Theme.Color.TextMuted, Size = Theme.Type.Caption })
    detailTitle:AddSpacer(4)
    detail.OnShow = function()
        if window.Destroyed then
            return
        end
        local entry = state.Selected
        detail:SetHeader({ Back = "Catalog", Title = entry.Name, Subtitle = entry.Category,
            OnBack = function()
                window:SetPage("Catalog")
            end })
        detailTitle:SetTitle(entry.Name)
        statusBadge:SetText((entry.Status == "ready" and "Verified build · " or "Update queued · ") .. tostring(entry.Meta[3].Value))
        media:SetProgress(entry.Status == "ready" and 0.42 or 0.12)
        local index = 1
        for _, item in ipairs(detailMeta.Items) do
            item:SetValue(entry.Meta[index] and entry.Meta[index].Value or "—")
            index = index + 1
            if index > #entry.Meta then
                index = 1
            end
        end
        detail:Reflow()
        detail:Layout(window.Content.AbsoluteSize.X, window.Content.AbsoluteSize.Y, window.Design and window.Design.Compact)
    end

    -- ── Settings ─────────────────────────────────────────────────────────────
    local settings = window:AddPage({ Name = "Settings", Icon = "sliders" })
    local general = settings:AddSection({ Name = "General", Icon = "settings", Description = "Core toggles and continuous values." })
    general:AddToggle({ Name = "Enable automation", Default = true, Tooltip = "Master switch for automated routines.", Callback = function(value)
        if value then
            window:Notify({ Title = "Automation on", Text = "Routines will queue normally", Type = "success", Duration = 2 })
        end
    end })
    general:AddToggle({ Name = "Keep interface on top", Default = true, Tooltip = "Pins the window above other overlays." })
    general:AddCheckbox({ Name = "Compact spacing", Default = false, Tooltip = "Reduces padding across sections." })
    general:AddSlider({ Name = "Reaction budget", Min = 20, Max = 400, Default = 140, Step = 5, Suffix = " ms", Callback = function(value)
        state.Reaction = value
    end })
    general:AddDropdown({ Name = "Profile", Options = { "Balanced", "Aggressive", "Conservative", "Tournament" }, Default = "Balanced", Tooltip = "Weights timing vs. safety." })
    general:AddMultiDropdown({ Name = "Modules", Options = { "Aurora", "Nomad", "Vertex", "Halcyon", "Lumen" }, Defaults = { "Aurora", "Lumen" }, Tooltip = "Modules enabled for this profile." })
    general:AddKeybind({ Name = "Toggle interface", Default = Enum.KeyCode.RightShift, Tooltip = "Show or hide the window." })
    general:AddSelectRow({ Name = "Language", Options = { "English", "Deutsch", "Español", "Português" }, Default = "English" })
    general:AddDropdown({
        Name = "Region",
        Options = { "Amsterdam", "Atlanta", "Bahrain", "Frankfurt", "Hong Kong", "Johannesburg", "London", "Los Angeles",
                    "Madrid", "Mumbai", "Paris", "São Paulo", "Singapore", "Sydney", "Tokyo", "Toronto", "Warsaw" },
        Default = "Frankfurt",
        Tooltip = "Long lists become searchable automatically.",
    })

    local input = settings:AddSection({ Name = "Input & output", Icon = "bolt", Description = "Fields, groups and progress." })
    input:AddTextbox({ Name = "Session label", Default = "Evening run", Placeholder = "Name this session", Tooltip = "Used in logs and exports." })
    input:AddTextbox({ Name = "Batch size", Default = "24", Numeric = true, Min = 1, Max = 200, Round = true, Tooltip = "Items per pass." })
    input:AddSegmented({ Options = { "Live", "Preview", "Offline" }, Default = "Live", Callback = function(value)
        window:Notify({ Title = "Mode", Text = value .. " mode engaged", Type = "info", Duration = 2 })
    end })
    local demoProgress = input:AddProgress({ Default = 0.34 })
    input:AddButton({ Name = "Advance progress", Text = "Advance", Style = "secondary", Callback = function()
        state.Progress = state.Progress >= 1 and 0.1 or state.Progress + 0.2
        demoProgress:SetValue(state.Progress)
    end })
    input:AddDivider("Status")
    input:AddMetadata({ Columns = 2, Items = {
        { Label = "Session", Value = "Evening run" },
        { Label = "Uptime", Value = "2 h 14 m" },
        { Label = "Actions", Value = "1 284" },
        { Label = "Errors", Value = "0" },
    } })

    local interface = settings:AddSection({ Name = "Interface", Icon = "layers", Description = "Motion, scale and accent." })
    interface:AddToggle({ Name = "Reduce motion", Default = false, Tooltip = "Settles animations instantly.", Callback = function(value)
        Motion.SetReduced(value)
        Components.RefreshAll()
    end })
    interface:AddSegmented({ Options = { "Violet", "Magenta", "Lime", "Amber" }, Default = "Violet", Callback = function(value)
        if Theme.Palette[string.lower(value)] then
            window:SetAccent(Theme.Palette[string.lower(value)])
        end
    end })
    interface:AddSlider({ Name = "Interface scale", Min = 80, Max = 112, Default = 100, Step = 4, Suffix = "%", Callback = function(value)
        window.UserScale = value / 100
        window:Layout()
    end })
    interface:AddSpacer(2)
    interface:AddBanner({ Type = "warning", Icon = "warning", Title = "Motion is a preference", Text = "Reduced motion also settles in-flight transitions instead of stranding them." })

    local telemetry = settings:AddSection({ Name = "Notifications", Icon = "info", Description = "Signal without noise." })
    telemetry:AddButton({ Name = "Success", Text = "Success", Style = "success", Callback = function()
        window:Notify({ Title = "Profile saved", Text = "Tournament profile is now active", Type = "success" })
    end })
    telemetry:AddButton({ Name = "Warning", Text = "Warning", Style = "secondary", Callback = function()
        window:Notify({ Title = "Key expires soon", Text = "3 days remaining on this key", Type = "warning" })
    end })
    telemetry:AddButton({ Name = "Error", Text = "Error", Style = "danger", Callback = function()
        window:Notify({ Title = "Connection lost", Text = "Retrying in 5 seconds", Type = "error" })
    end })
    telemetry:AddButton({ Name = "Burst", Text = "Burst of 8", Style = "primary", Callback = function()
        for index = 1, 8 do
            window:Notify({
                Title = "Burst " .. index,
                Text = "Stacked notifications reflow as they arrive",
                Type = index % 3 == 0 and "warning" or (index % 2 == 0 and "success" or "info"),
                Duration = 4,
            })
        end
    end })

    local dialogs = settings:AddSection({ Name = "Dialogs & window", Icon = "layers", Description = "Modal flows and window control." })
    dialogs:AddButton({ Name = "Open dialog", Text = "Alert", Style = "secondary", Callback = function()
        window:Alert({ Title = "Session summary", Text = "1 284 actions completed with no errors.", Icon = "check", Type = "success" })
    end })
    dialogs:AddButton({ Name = "Confirm", Text = "Confirm", Style = "secondary", Callback = function()
        window:Confirm({ Title = "Reset workspace?", Text = "Saved modules will return to defaults.", ConfirmText = "Reset", OnConfirm = function()
            window:Notify({ Title = "Workspace reset", Text = "Defaults restored", Type = "neutral" })
        end })
    end })
    dialogs:AddButton({ Name = "Auth modal", Text = "Authentication", Style = "primary", Callback = function()
        Library.openAuthModal(window, state)
    end })
    dialogs:AddButton({ Name = "Minimize", Text = "Minimize", Style = "secondary", Callback = function()
        window:Minimize()
    end })
    dialogs:AddButton({ Name = "Restore", Text = "Restore", Style = "secondary", Callback = function()
        window:Restore()
    end })

    -- ── route + entrance ─────────────────────────────────────────────────────
    window:SetPage(home)
    window:Layout()
    return window
end

-- Authentication modal — a complete demo flow (validation → processing → result).
function Library.openAuthModal(window, state)
    local mode = "signin"
    return window:OpenModal({
        Title = mode == "signin" and "Authentication" or "Create account",
        Size = "medium",
        Dismissible = true,
        BodyHeight = 268,
        BuildBody = function(container, width, requestLayout)
            local fields = {}
            local y = 2
            local function place(row, height)
                row.Root.Position = UDim2.fromOffset(0, y)
                row.Root.Size = UDim2.fromOffset(width, height)
                if row.Layout then
                    row:Layout(width)
                end
                y = y + height + 6
            end
            local function fieldLayout(field)
                return function()
                    field.Root.Size = UDim2.new(1, 0, 0, 40)
                    field.Field.Position = UDim2.fromOffset(0, 0)
                    field.Field.Size = UDim2.new(1, 0, 0, 40)
                    return 40
                end
            end
            local email = Components.Textbox(window.Scope, container, {
                Icon = "mail",
                Placeholder = "you@example.com",
                Full = true,
                Height = 40,
            })
            email.Layout = fieldLayout(email)
            place(email, 40)
            local password = Components.Textbox(window.Scope, container, {
                Icon = "lock",
                Placeholder = "Password",
                Full = true,
                Height = 40,
            })
            password.Layout = fieldLayout(password)
            place(password, 40)
            local remember = Components.Checkbox(window.Scope, container, { Text = "Remember this device", Default = true, Width = width })
            remember.Root.Size = UDim2.fromOffset(width, 22)
            remember.Height = 22
            remember.Layout = function()
                remember.Root.Size = UDim2.fromOffset(width, 22)
                return 22
            end
            place(remember, 22)
            local error = Prim.label(container, "Error", "", Theme.Type.Caption, Theme.Color.Danger)
            error.TextWrapped = true
            error.Visible = false
            error.Height = 0
            place(error, 0)
            fields.email, fields.password, fields.remember, fields.error = email, password, remember, error
            local feedback = Prim.label(container, "Feedback", "", Theme.Type.Small, Theme.Color.TextSecondary)
            feedback.TextWrapped = true
            feedback.TextXAlignment = Enum.TextXAlignment.Center
            feedback.Height = 0
            place(feedback, 0)
            fields.feedback = feedback
            container.Size = UDim2.new(1, 0, 0, y)
            if requestLayout then
                requestLayout(y + 8)
            end
            return fields
        end,
        Actions = {
            { Text = "Register instead", Style = "ghost", Close = false, Width = 128, Callback = function()
                window:CloseModal()
                task.delay(0.12, function()
                    window:Notify({ Title = "Registration", Text = "Registration uses the same validation flow", Type = "neutral", Duration = 3 })
                end)
            end },
            { Text = "NEXT", Style = "primary", Close = false, Width = 116, Callback = function(modal)
                local body = modal.Body
                local email = body and body.email
                if not email then
                    Modal.Close()
                    return
                end
                local address = email:Get()
                local secret = body.password:Get()
                email:SetDisabled(true)
                body.password:SetDisabled(true)
                Modal.SetActionState(2, "busy", "Checking")
                body.error.Visible = false
                window.Scope:Later(0.75, function()
                    if not Modal.IsOpen then
                        return
                    end
                    email:SetDisabled(false)
                    body.password:SetDisabled(false)
                    if address == "" then
                        body.error.Text = "Enter the email address tied to your key."
                        body.error.Visible = true
                        Modal.SetActionState(2, "error", "NEXT")
                        return
                    end
                    if not string.find(address, "@", 1, true) then
                        body.error.Text = "That address is missing an \"@\"."
                        body.error.Visible = true
                        Modal.SetActionState(2, "error", "NEXT")
                        return
                    end
                    if #secret < 4 then
                        body.error.Text = "Passwords need at least 4 characters."
                        body.error.Visible = true
                        Modal.SetActionState(2, "error", "NEXT")
                        return
                    end
                    Modal.SetActionState(2, "success", "SUCCESS")
                    body.feedback.Text = "Signed in as " .. address
                    body.feedback.TextColor3 = Theme.Color.Success
                    body.feedback.Visible = true
                    if state then
                        state.SignedIn = true
                    end
                    window:SetIdentity({ Name = address:match("^([^@]*)") })
                    window:Notify({ Title = "Signed in", Text = "Workspace synced", Type = "success" })
                    window.Scope:Later(0.6, function()
                        Modal.Close()
                    end)
                end)
            end },
        },
    })
end

-- The library table is the module result.
return Library

