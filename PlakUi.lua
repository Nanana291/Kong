-- PlakUi — a client-side loader frontend. Authentication and product execution belong to the host.
-- Callbacks may yield. Progress is host-reported; SetExpiry never grants or revokes a license.
-- Optional storefront: ShowLicenses(), SetLicenseOfferEnabled(boolean), SetLicenseStoreLink(httpsURL).
-- Prices are presentation only; checkout and license entitlement remain with the store/host.
-- PLAK is native GUI geometry. Catalog thumbnails are real Roblox content; optional HTTP only enriches metadata.
local Loader = {}
local Services = {
    Players = game:GetService("Players"),
    Tween = game:GetService("TweenService"),
    Input = game:GetService("UserInputService"),
    Text = game:GetService("TextService"),
}
local Theme = {
    Surface = Color3.fromRGB(17, 17, 19),
    Input = Color3.fromRGB(26, 25, 30),
    Elevated = Color3.fromRGB(30, 28, 34),
    Inactive = Color3.fromRGB(39, 36, 43),
    Text = Color3.fromRGB(239, 237, 239),
    Secondary = Color3.fromRGB(146, 140, 150),
    Muted = Color3.fromRGB(92, 86, 98),
    Line = Color3.fromRGB(51, 44, 53),
    Accent = Color3.fromRGB(225, 60, 99),
    AccentDark = Color3.fromRGB(126, 40, 65),
    AccentText = Color3.fromRGB(195, 65, 95),
    Warning = Color3.fromRGB(213, 168, 108),
    Radius = 10,
    Font = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Bold = Enum.Font.GothamBold,
    Display = Enum.Font.Arcade,
}
local Motion = {
    Hover = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Press = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Enter = TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Exit = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
    Page = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Progress = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Drag = TweenInfo.new(0.055, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    DecodeDuration = 0.64,
}
local Settings = {
    Title = "PLAK",
    Version = "",
    KeyLink = "",
    Expiry = 0,
    Language = "en",
    User = "Past Owl",
    Artwork = nil,
    SuccessBehavior = "destroy",
    ToggleKey = Enum.KeyCode.RightShift,
    SupportLink = "",
    SocialLinks = { discord = "https://dsc.gg/plak" },
    LicenseOfferEnabled = true,
    LicenseStoreLink = "https://plak-hub.mysellauth.com/",
    CommunityEnabled = true,
    CommunityDismissed = false,
    UIScale = 1,
    ReducedMotion = false,
    KeyVisible = false,
}
local State = {
    Name = "Initializing",
    Alive = true,
    Visible = true,
    Page = "Auth",
    Activity = "Idle",
    Modal = nil,
    Focused = false,
    AuthFeedback = nil,
    Authorized = false,
    ValidationToken = 0,
    LaunchToken = 0,
    PageToken = 0,
    ModalToken = 0,
    VisibilityToken = 0,
    DecodeToken = 0,
    TitleCustom = false,
    Progress = 0,
    Indeterminate = false,
    Products = {},
    SelectedProduct = nil,
    WindowCenter = nil,
    Drag = nil,
    Layout = {},
    Callbacks = {},
}
local UI = {}
local Experience
local Community
local LicenseOffer
local LanguageController
local Scope = {}
Scope.__index = Scope
function Scope.new()
    return setmetatable({ Alive = true, Connections = {}, Tasks = {}, Finalizers = {} }, Scope)
end
function Scope:Connect(signal, callback)
    if not self.Alive or not State.Alive then
        return nil
    end
    local connection = signal:Connect(function(...)
        if self.Alive and State.Alive then
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
    if not self.Alive or not State.Alive then
        return nil
    end
    local thread
    thread = task.delay(seconds, function()
        self.Tasks[thread] = nil
        if self.Alive and State.Alive then
            callback()
        end
    end)
    self.Tasks[thread] = true
    return thread
end
function Scope:Run(callback)
    if not self.Alive or not State.Alive then
        return nil
    end
    local thread
    thread = task.defer(function()
        if self.Alive and State.Alive then
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
    for _, callback in ipairs(self.Finalizers) do
        pcall(callback)
    end
    table.clear(self.Connections)
    table.clear(self.Tasks)
    table.clear(self.Finalizers)
end
local Runtime = Scope.new()
local Animation = { Objects = {} }
function Animation:Cancel(record)
    if not record or record.Cancelled then
        return
    end
    record.Cancelled = true
    if record.Connection then
        record.Connection:Disconnect()
    end
    record.Tween:Cancel()
    record.Tween:Destroy()
    local map = self.Objects[record.Object]
    if map then
        for key in pairs(record.Goals) do
            if map[key] == record then
                map[key] = nil
            end
        end
        if next(map) == nil then
            self.Objects[record.Object] = nil
        end
    end
end
function Animation:To(object, goals, preset, completed)
    if not State.Alive or not object.Parent then
        return
    end
    preset = preset or Motion.Hover
    local map = self.Objects[object]
    -- Layout/hover can request the same destination many times. Preserve the
    -- original easing clock instead of destroying and restarting that tween.
    if map and not completed and not Settings.ReducedMotion then
        local candidate
        local same = true
        for key, value in pairs(goals) do
            local record = map[key]
            if
                not record
                or record.Completed
                or record.Preset ~= preset
                or record.Goals[key] ~= value
                or (candidate and candidate ~= record)
            then
                same = false
                break
            end
            candidate = record
        end
        if same and candidate then
            for key, value in pairs(candidate.Goals) do
                if goals[key] ~= value then
                    same = false
                    break
                end
            end
            if same then
                return candidate
            end
        end
    end
    if map then
        for key in pairs(goals) do
            self:Cancel(map[key])
        end
    end
    if Settings.ReducedMotion then
        for key, value in pairs(goals) do
            object[key] = value
        end
        if completed then
            completed()
        end
        return
    end
    if not completed then
        local settled = true
        for key, value in pairs(goals) do
            if object[key] ~= value then
                settled = false
                break
            end
        end
        if settled then
            return
        end
    end
    map = self.Objects[object] or {}
    self.Objects[object] = map
    local record = {
        Object = object,
        Goals = goals,
        Completed = completed,
        Preset = preset,
        Tween = Services.Tween:Create(object, preset, goals),
    }
    for key in pairs(goals) do
        map[key] = record
    end
    record.Connection = record.Tween.Completed:Connect(function(playback)
        if record.Cancelled then
            return
        end
        self:Cancel(record)
        if State.Alive and playback == Enum.PlaybackState.Completed and completed then
            completed()
        end
    end)
    record.Tween:Play()
    return record
end
function Animation:CancelTree(root)
    local records = {}
    for object, map in pairs(self.Objects) do
        if object == root or object:IsDescendantOf(root) then
            for _, record in pairs(map) do
                records[record] = true
            end
        end
    end
    for record in pairs(records) do
        self:Cancel(record)
    end
end
function Animation:CancelProperty(object, key)
    local map = self.Objects[object]
    if map then
        self:Cancel(map[key])
    end
end
function Animation:Destroy()
    local records = {}
    for _, map in pairs(self.Objects) do
        for _, record in pairs(map) do
            records[record] = true
        end
    end
    for record in pairs(records) do
        self:Cancel(record)
    end
end
function Animation:Finish()
    local records = {}
    for _, map in pairs(self.Objects) do
        for _, record in pairs(map) do
            records[record] = true
        end
    end
    for record in pairs(records) do
        if not record.Cancelled and record.Object.Parent then
            self:Cancel(record)
            for key, value in pairs(record.Goals) do
                record.Object[key] = value
            end
            if State.Alive and record.Completed then
                record.Completed()
            end
        end
    end
end
local function create(class, properties, parent)
    local object = Instance.new(class)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end
local function corner(object, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or Theme.Radius) }, object)
end
local function stroke(object, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Theme.Line,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, object)
end
local function frame(parent, name, color)
    return create("Frame", { Name = name, BorderSizePixel = 0, BackgroundColor3 = color or Theme.Surface }, parent)
end
local function label(parent, name, text, size, color, font)
    return create("TextLabel", {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = text or "",
        TextSize = size or 14,
        TextColor3 = color or Theme.Text,
        Font = font or Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        RichText = false,
        TextWrapped = false,
    }, parent)
end
local function place(object, x, y, w, h)
    local position = UDim2.fromOffset(x, y)
    local size = UDim2.fromOffset(w, h)
    if object.Position ~= position then
        object.Position = position
    end
    if object.Size ~= size then
        object.Size = size
    end
end
local function group(parent, name)
    return create(
        "CanvasGroup",
        { Name = name, BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 0 },
        parent
    )
end
local function gradient(object, startColor, endColor, rotation)
    -- UIGradient multiplies its parent's color; a neutral base preserves the sampled palette.
    object.BackgroundColor3 = Color3.new(1, 1, 1)
    return create("UIGradient", { Color = ColorSequence.new(startColor, endColor), Rotation = rotation or 0 }, object)
end
local function trim(value)
    return type(value) == "string" and value:gsub("^%s+", ""):gsub("%s+$", "") or ""
end
local function safeText(value, limit)
    local text = tostring(value or ""):gsub("[%z\1-\8\11\12\14-\31]", "")
    local valid, length = pcall(utf8.len, text)
    if not valid or not length then
        text = text:gsub("[\128-\255]", "?")
    end
    if limit and #text > limit then
        local boundary = utf8.offset(text, 0, limit + 1)
        text = text:sub(1, (boundary or limit + 1) - 1)
    end
    return text
end
local function finite(value, fallback)
    value = tonumber(value)
    return value and value == value and math.abs(value) < math.huge and value or fallback
end
local function assetId(value)
    if type(value) == "number" and value > 0 then
        return "rbxassetid://" .. tostring(math.floor(value))
    end
    if
        type(value) == "string"
        and (
            value:match("^rbxassetid://%d+$")
            or value:match("^rbxasset://")
            or value:match("^rbxasset:///")
            or value:match("^rbxthumb://")
            or value:match("^rbxassetid://")
        )
    then
        return value
    end
    if type(value) == "string" and value:match("^%d+$") then
        return "rbxassetid://" .. value
    end
    return nil
end
local function capability(name)
    local ok, environment = pcall(function()
        return type(getgenv) == "function" and getgenv()
    end)
    if ok and type(environment) == "table" and type(environment[name]) == "function" then
        return environment[name]
    end
    local global = _G and _G[name]
    if type(global) == "function" then
        return global
    end
    -- getfenv includes executor globals which are intentionally absent from _G on some Android executors.
    local env = getfenv and getfenv(0)
    return env and type(env[name]) == "function" and env[name] or nil
end
local function reconcile()
    if not State.Alive then
        State.Name = "Destroyed"
    elseif not State.Visible then
        State.Name = "Hidden"
    elseif State.Activity == "Validating" then
        State.Name = "Validating"
    elseif State.Activity == "Completing" then
        State.Name = "AuthCompleting"
    elseif State.Activity == "ForgettingKey" then
        State.Name = "ForgettingKey"
    elseif State.Activity == "Launching" then
        State.Name = "ProductLaunching"
    elseif State.Modal == "progress" then
        State.Name = "ProductProgress"
    elseif State.Modal then
        State.Name = "ModalOpen"
    elseif State.Page == "Products" then
        State.Name = "ProductBrowser"
    elseif State.Focused then
        State.Name = "AuthFocused"
    elseif State.Authorized then
        State.Name = "Authorized"
    else
        State.Name = "AuthIdle"
    end
    if State.Modal and LanguageController and LanguageController.Open then
        LanguageController:SetOpen(false)
    end
    if UI.AuthArtwork and UI.AuthArtwork.SetState and State.Alive then
        UI.AuthArtwork:SetState(
            State.Activity == "Validating" and "validating"
                or State.AuthError and "error"
                or State.Authorized and "authorized"
                or State.Focused and "focused"
                or "idle"
        )
    end
end
local function canInteract()
    return State.Alive and State.Visible and State.Activity == "Idle" and not State.Modal
end
local Icon = {}
function Icon.new(parent, name, color, size)
    local root = frame(parent, "Icon_" .. name)
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromOffset(size or 20, size or 20)
    local parts = {}
    local function line(x1, y1, x2, y2, thickness)
        local dx, dy = x2 - x1, y2 - y1
        local part = frame(root, "Segment", color or Theme.Muted)
        part.AnchorPoint = Vector2.new(0.5, 0.5)
        part.Position = UDim2.fromScale((x1 + x2) / 40, (y1 + y2) / 40)
        part.Size = UDim2.new(math.sqrt(dx * dx + dy * dy) / 20, 0, 0, thickness or 1.6)
        part.Rotation = math.deg(math.atan2(dy, dx))
        corner(part, 2)
        parts[#parts + 1] = part
    end
    local function path(points, closed)
        for i = 1, #points - 1 do
            line(points[i][1], points[i][2], points[i + 1][1], points[i + 1][2])
        end
        if closed then
            line(points[#points][1], points[#points][2], points[1][1], points[1][2])
        end
    end
    local function circle(x, y, r, solid)
        local part = frame(root, "Circle", color or Theme.Muted)
        part.AnchorPoint = Vector2.new(0.5, 0.5)
        part.Position = UDim2.fromScale(x / 20, y / 20)
        part.Size = UDim2.fromScale(r / 10, r / 10)
        corner(part, 100)
        if not solid then
            part.BackgroundTransparency = 1
            parts[#parts + 1] = stroke(part, color or Theme.Muted, 1.5)
        else
            parts[#parts + 1] = part
        end
    end
    if name == "home" then
        path({ { 3, 8 }, { 10, 3 }, { 17, 8 }, { 15, 17 }, { 5, 17 } }, true)
    elseif name == "grid" then
        for _, p in ipairs({ { 3, 3 }, { 12, 3 }, { 3, 12 }, { 12, 12 } }) do
            path({ { p[1], p[2] }, { p[1] + 5, p[2] }, { p[1] + 5, p[2] + 5 }, { p[1], p[2] + 5 } }, true)
        end
    elseif name == "key" then
        circle(13, 6, 4)
        path({ { 10, 9 }, { 3, 16 }, { 3, 18 }, { 6, 18 }, { 6, 15 }, { 9, 15 }, { 10, 12 } })
    elseif name == "eye" or name == "eye-off" then
        path({ { 2, 10 }, { 5, 6 }, { 10, 4 }, { 15, 6 }, { 18, 10 }, { 15, 14 }, { 10, 16 }, { 5, 14 } }, true)
        circle(10, 10, 2.6)
        if name == "eye-off" then
            line(3, 3, 17, 17, 1.8)
        end
    elseif name == "minimize" then
        line(4, 12, 16, 12, 1.8)
    elseif name == "play" then
        path({ { 6, 3 }, { 16, 10 }, { 6, 17 } }, true)
    elseif name == "check" or name == "shield-check" then
        if name == "shield-check" then
            path({ { 10, 2 }, { 17, 5 }, { 16, 12 }, { 10, 18 }, { 4, 12 }, { 3, 5 } }, true)
        end
        path({ { 6, 10 }, { 9, 13 }, { 14, 7 } })
    elseif name == "x" or name == "shield-alert" then
        if name == "shield-alert" then
            path({ { 10, 2 }, { 17, 5 }, { 16, 12 }, { 10, 18 }, { 4, 12 }, { 3, 5 } }, true)
            line(10, 6, 10, 10)
            circle(10, 13, 0.7, true)
        else
            line(5, 5, 15, 15)
            line(15, 5, 5, 15)
        end
    elseif name == "clock" then
        circle(10, 10, 7)
        path({ { 10, 5 }, { 10, 10 }, { 14, 12 } })
    elseif name == "refresh" then
        path({ { 16, 7 }, { 13, 3 }, { 7, 3 }, { 3, 7 }, { 3, 11 } })
        path({ { 4, 13 }, { 7, 17 }, { 13, 17 }, { 17, 13 }, { 17, 9 } })
        path({ { 12, 7 }, { 17, 7 }, { 17, 2 } })
        path({ { 8, 13 }, { 3, 13 }, { 3, 18 } })
    elseif name == "chevron" then
        path({ { 5, 8 }, { 10, 13 }, { 15, 8 } })
    elseif name == "support" then
        path({ { 3, 12 }, { 3, 8 }, { 5, 4 }, { 10, 2 }, { 15, 4 }, { 17, 8 }, { 17, 14 }, { 14, 17 }, { 10, 17 } })
        path({ { 3, 9 }, { 6, 9 }, { 6, 14 }, { 3, 14 } }, true)
        path({ { 14, 9 }, { 17, 9 }, { 17, 14 }, { 14, 14 } }, true)
    elseif name == "user-x" then
        circle(8, 6, 3)
        path({ { 2, 17 }, { 3, 13 }, { 8, 11 }, { 11, 12 } })
        circle(15, 15, 4)
        line(12, 12, 18, 18)
    elseif name == "warning" then
        path({ { 10, 2 }, { 19, 17 }, { 1, 17 } }, true)
        line(10, 7, 10, 11)
        circle(10, 14, 0.7, true)
    elseif name == "link" then
        path({ { 7, 12 }, { 4, 15 }, { 2, 13 }, { 2, 9 }, { 7, 4 }, { 11, 4 }, { 13, 6 } })
        path({ { 13, 8 }, { 16, 5 }, { 18, 7 }, { 18, 11 }, { 13, 16 }, { 9, 16 }, { 7, 14 } })
        line(7, 13, 13, 7)
    elseif name == "send" then
        path({ { 2, 8 }, { 18, 3 }, { 14, 18 }, { 9, 12 }, { 2, 8 } }, false)
        line(9, 12, 18, 3)
    elseif name == "youtube" then
        path({ { 2, 5 }, { 18, 5 }, { 18, 15 }, { 2, 15 } }, true)
        path({ { 8, 7 }, { 13, 10 }, { 8, 13 } }, true)
    elseif name == "discord" then
        path({
            { 6, 5 },
            { 3, 6 },
            { 2, 14 },
            { 6, 16 },
            { 7, 14 },
            { 13, 14 },
            { 14, 16 },
            { 18, 14 },
            { 17, 6 },
            {
                14,
                5,
            },
        }, true)
        circle(7, 10, 1.2, true)
        circle(13, 10, 1.2, true)
        line(7, 4, 6, 6)
        line(13, 4, 14, 6)
    elseif name == "rosette" then
        circle(10, 10, 8)
        for i = 0, 7 do
            local a = i * math.pi / 4
            line(10 + math.cos(a) * 2, 10 + math.sin(a) * 2, 10 + math.cos(a) * 7, 10 + math.sin(a) * 7, 1.7)
        end
    elseif name == "owl" then
        circle(10, 10, 8)
        line(5, 7, 8, 9, 3)
        line(15, 7, 12, 9, 3)
        circle(7, 12, 1, true)
        circle(13, 12, 1, true)
        path({ { 9, 14 }, { 10, 16 }, { 11, 14 } })
    elseif name == "tools" then
        path({
            { 4, 3 },
            { 3, 7 },
            { 7, 10 },
            { 3, 16 },
            { 5, 18 },
            { 11, 12 },
            { 15, 13 },
            { 18, 10 },
            { 14, 10 },
            {
                12,
                8,
            },
            {
                12,
                4,
            },
            {
                9,
                2,
            },
            {
                9,
                6,
            },
            {
                7,
                7,
            },
        }, false)
    else
        circle(10, 10, 7)
        line(10, 8, 10, 14)
        circle(10, 5, 0.7, true)
    end
    return {
        Root = root,
        SetColor = function(_, value)
            for _, part in ipairs(parts) do
                if part:IsA("UIStroke") then
                    part.Color = value
                else
                    part.BackgroundColor3 = value
                end
            end
        end,
    }
end
local Button = {}
function Button.new(parent, name, text, accent, iconName, onActivated, scope, allowed)
    scope = scope or Runtime
    local self = { Disabled = false, Hovered = false, Pressed = false }
    self.Root = create("TextButton", {
        Name = name,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        BackgroundColor3 = accent and Theme.Accent or Theme.Input,
        Active = true,
        Selectable = true,
    }, parent)
    corner(self.Root, Theme.Radius)
    self.Scale = create("UIScale", { Scale = 1 }, self.Root)
    if accent then
        self.Gradient = gradient(self.Root, Theme.Accent, Theme.AccentDark)
    end
    self.Label = label(self.Root, "Label", text, 12, Theme.Text, Theme.Medium)
    self.Label.TextXAlignment = Enum.TextXAlignment.Center
    self.Label.TextTruncate = Enum.TextTruncate.AtEnd
    self.Label.Size = UDim2.fromScale(1, 1)
    if iconName then
        self.Icon = Icon.new(self.Root, iconName, Theme.Text, 18)
        self.Icon.Root.AnchorPoint = Vector2.new(0, 0.5)
        self.Icon.Root.Position = UDim2.new(0, 14, 0.5, 0)
        self.Label.Position = UDim2.fromOffset(24, 0)
        self.Label.Size = UDim2.new(1, -28, 1, 0)
    end
    function self:Apply()
        local base = accent and Color3.new(1, 1, 1)
            or self.ContextHovered and Theme.Accent
            or self.BaseColor
            or Theme.Input
        local color = self.Disabled and base:Lerp(Theme.Surface, 0.48)
            or self.Pressed and base:Lerp(Theme.Surface, 0.18)
            or self.Hovered and base:Lerp(Theme.Text, 0.07)
            or base
        Animation:To(self.Root, { BackgroundColor3 = color }, Motion.Hover)
        if self.Gradient then
            Animation:To(
                self.Gradient,
                { Offset = Vector2.new(self.Hovered and not self.Disabled and 0.045 or 0, 0) },
                Motion.Hover
            )
        end
        self.Label.TextColor3 = self.Disabled and Theme.Secondary or Theme.Text
        self.Root.Selectable = not self.Disabled
        Animation:To(self.Scale, { Scale = self.Pressed and not self.Disabled and 0.985 or 1 }, Motion.Press)
    end
    function self:SetDisabled(value)
        self.Disabled = value == true
        self.Pressed = false
        self:Apply()
    end
    local function enabled()
        return not self.Disabled and (allowed or canInteract)()
    end
    scope:Connect(self.Root.MouseEnter, function()
        if enabled() then
            self.Hovered = true
            self:Apply()
        end
    end)
    scope:Connect(self.Root.MouseLeave, function()
        self.Hovered = false
        self.Pressed = false
        self:Apply()
    end)
    scope:Connect(self.Root.SelectionGained, function()
        if enabled() then
            self.Hovered = true
            self:Apply()
        end
    end)
    scope:Connect(self.Root.SelectionLost, function()
        self.Hovered = false
        self.Pressed = false
        self:Apply()
    end)
    scope:Connect(self.Root.InputBegan, function(input)
        if
            enabled()
            and (
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            )
        then
            self.Pressed = true
            self:Apply()
        end
    end)
    scope:Connect(self.Root.InputEnded, function()
        if self.Pressed then
            self.Pressed = false
            self:Apply()
        end
    end)
    scope:Connect(self.Root.Activated, function()
        if enabled() then
            self.Pressed = false
            self:Apply()
            onActivated()
        end
    end)
    return self
end
local Translations = {
    en = {
        brand = "PLAK",
        main = "Main",
        authorization = "User authorization",
        product = "Product",
        umbrella = "Umbrella",
        game = "Game",
        gameCopy = "A supported Roblox experience. Select to launch.",
        metadataLoading = "Loading game details…",
        metadataUnavailable = "Game details are unavailable.",
        heroA = "Experience",
        heroB = "the madness",
        copy = "Log in to continue your journey through our products",
        keyHint = "Insert your key here",
        keyHintCompact = "License key",
        keyHintTiny = "Key",
        signIn = "SIGN IN",
        getKey = "GET A KEY",
        validating = "VALIDATING",
        waiting = "Waiting for authorization",
        rights = "All rights reserved",
        empty = "Please enter a key",
        emptyDescription = "Enter your license key before signing in.",
        ready = "Authorization",
        noValidator = "Authorization is not configured",
        noValidatorCopy = "The application has not registered a validation callback.",
        granted = "Access granted",
        invalid = "Authorization failed",
        genericError = "The request could not be completed. Please try again.",
        access = "The account is disabled",
        accessCopy = "Account access is currently disabled. This may be due to an expired license.",
        support = "SUPPORT",
        supportCopy = "Do you think this is a mistake? Contact support",
        report = "REPORT A PROBLEM",
        problems = "Having problems with the loader?",
        continue = "CONTINUE",
        close = "CLOSE",
        success = "Successful session!",
        successCopy = "We would appreciate your feedback on our website.",
        failure = "Unsuccessful session",
        failureCopy = "If this happens, you may need to wait a while and try again.",
        warning = "Please note",
        info = "Information",
        website = "Our website",
        loading = "Loading all the necessary data",
        available = "Secure access",
        limited = "Limited access",
        development = "In development",
        updating = "Updating",
        disabled = "Disabled",
        productCopy = "Our greatest pride is our advanced gameplay scenarios for each character. Developed in collaboration with highly-rated players and eSports athletes.",
        unavailable = "This product is not available for launch.",
        launchMissing = "The application has not configured product launch.",
        signInFirst = "Sign in to launch this product.",
        copied = "Copied to clipboard",
        keyCopied = "The key link is ready to open in your browser.",
        noClipboard = "Copy this link",
        noLink = "No key link has been configured.",
        supportTitle = "Contact support",
        supportHelp = "Share these details with the application's support team. Your license key is not included.",
        copyDetails = "COPY DETAILS",
        session = "Session configuration",
        seconds = "seconds",
        refreshed = "Catalog refreshed",
        busy = "Please wait for the current request.",
        showKey = "Show key",
        hideKey = "Hide key",
        minimize = "Minimize loader",
        restore = "Restore loader",
    },
    ru = {
        brand = "PLAK",
        main = "Главная",
        authorization = "Авторизация пользователя",
        product = "Продукт",
        umbrella = "Амбрелла",
        game = "Игра",
        gameCopy = "Поддерживаемая игра Roblox. Выберите для запуска.",
        metadataLoading = "Загрузка сведений об игре…",
        metadataUnavailable = "Сведения об игре недоступны.",
        heroA = "Испытайте",
        heroB = "Безумие",
        copy = "Авторизуйтесь для доступа ко всем продуктам",
        keyHint = "Введите ключ в это поле",
        keyHintCompact = "Ключ лицензии",
        keyHintTiny = "Ключ",
        signIn = "ВОЙТИ",
        getKey = "ПОЛУЧИТЬ КЛЮЧ",
        validating = "ПРОВЕРКА",
        waiting = "Ожидание авторизации",
        rights = "Все права защищены",
        empty = "Пожалуйста, введите ключ",
        emptyDescription = "Введите лицензионный ключ для входа.",
        ready = "Авторизация",
        noValidator = "Авторизация не настроена",
        noValidatorCopy = "Приложение не зарегистрировало функцию проверки ключа.",
        granted = "Доступ разрешён",
        invalid = "Ошибка авторизации",
        genericError = "Не удалось выполнить запрос. Попробуйте ещё раз.",
        access = "Аккаунт отключён",
        accessCopy = "Доступ к аккаунту отключён. Возможно, срок лицензии истёк.",
        support = "ПОДДЕРЖКА",
        supportCopy = "Считаете это ошибкой? Свяжитесь с поддержкой",
        report = "СООБЩИТЬ ОБ ОШИБКЕ",
        problems = "Имеете проблемы с загрузчиком?",
        continue = "ПРОДОЛЖИТЬ",
        close = "ЗАКРЫТЬ",
        success = "Успешная сессия!",
        successCopy = "Мы будем рады любому отзыву у нас на сайте.",
        failure = "Неудачная сессия",
        failureCopy = "Если такое произошло, возможно, нужно подождать какое-то время и повторить.",
        warning = "Обратите внимание",
        info = "Информация",
        website = "Наш сайт",
        loading = "Загрузка всех необходимых данных",
        available = "Безопасный доступ",
        limited = "Ограниченный доступ",
        development = "В разработке",
        updating = "В обновлении",
        disabled = "Отключено",
        productCopy = "Наша главная гордость — продвинутые игровые сценарии для каждого персонажа. Все функции разработаны совместно с топовыми игроками и киберспортсменами.",
        unavailable = "Этот продукт недоступен для запуска.",
        launchMissing = "Приложение не настроило запуск продукта.",
        signInFirst = "Войдите, чтобы запустить этот продукт.",
        copied = "Скопировано",
        keyCopied = "Ссылка на ключ готова к открытию в браузере.",
        noClipboard = "Скопируйте ссылку",
        noLink = "Ссылка для получения ключа не настроена.",
        supportTitle = "Связаться с поддержкой",
        supportHelp = "Отправьте эти данные в поддержку приложения. Лицензионный ключ не включён.",
        copyDetails = "КОПИРОВАТЬ ДАННЫЕ",
        session = "Настройки сессии",
        seconds = "секунд",
        refreshed = "Каталог обновлён",
        busy = "Дождитесь завершения текущего запроса.",
        showKey = "Показать ключ",
        hideKey = "Скрыть ключ",
        minimize = "Свернуть загрузчик",
        restore = "Открыть загрузчик",
    },
    es = {
        brand = "PLAK",
        main = "Inicio",
        authorization = "Autorización de usuario",
        product = "Producto",
        umbrella = "Umbrella",
        game = "Juego",
        gameCopy = "Una experiencia de Roblox compatible. Selecciona para iniciar.",
        metadataLoading = "Cargando detalles del juego…",
        metadataUnavailable = "Los detalles del juego no están disponibles.",
        heroA = "Vive",
        heroB = "la locura",
        copy = "Inicia sesión para continuar tu recorrido por nuestros productos",
        keyHint = "Introduce tu clave aquí",
        keyHintCompact = "Clave de licencia",
        keyHintTiny = "Clave",
        signIn = "INICIAR SESIÓN",
        getKey = "OBTENER CLAVE",
        validating = "VALIDANDO",
        waiting = "Esperando autorización",
        rights = "Todos los derechos reservados",
        empty = "Introduce una clave",
        emptyDescription = "Introduce tu clave de licencia antes de iniciar sesión.",
        ready = "Autorización",
        noValidator = "La autorización no está configurada",
        noValidatorCopy = "La aplicación no ha registrado una función de validación.",
        granted = "Acceso concedido",
        invalid = "Error de autorización",
        genericError = "No se pudo completar la solicitud. Inténtalo de nuevo.",
        access = "La cuenta está deshabilitada",
        accessCopy = "El acceso a la cuenta está deshabilitado. Puede deberse a una licencia vencida.",
        support = "SOPORTE",
        supportCopy = "¿Crees que es un error? Contacta con soporte",
        report = "REPORTAR UN PROBLEMA",
        problems = "¿Tienes problemas con el loader?",
        continue = "CONTINUAR",
        close = "CERRAR",
        success = "¡Sesión exitosa!",
        successCopy = "Agradeceríamos tus comentarios en nuestro sitio web.",
        failure = "La sesión no pudo completarse",
        failureCopy = "Es posible que debas esperar un poco antes de volver a intentarlo.",
        warning = "Ten en cuenta",
        info = "Información",
        website = "Nuestro sitio web",
        loading = "Cargando los datos necesarios",
        available = "Acceso seguro",
        limited = "Acceso limitado",
        development = "En desarrollo",
        updating = "Actualizando",
        disabled = "Deshabilitado",
        productCopy = "Nuestro mayor orgullo son los escenarios de juego avanzados para cada personaje. Desarrollados con jugadores destacados y profesionales de eSports.",
        unavailable = "Este producto no está disponible para iniciar.",
        launchMissing = "La aplicación no ha configurado el inicio del producto.",
        signInFirst = "Inicia sesión para abrir este producto.",
        copied = "Copiado al portapapeles",
        keyCopied = "El enlace de la clave está listo para abrirse en tu navegador.",
        noClipboard = "Copia este enlace",
        noLink = "No se ha configurado un enlace para obtener la clave.",
        supportTitle = "Contactar con soporte",
        supportHelp = "Comparte estos datos con el equipo de soporte. Tu clave de licencia no está incluida.",
        copyDetails = "COPIAR DATOS",
        session = "Configuración de sesión",
        seconds = "segundos",
        refreshed = "Catálogo actualizado",
        busy = "Espera a que termine la solicitud actual.",
        showKey = "Mostrar clave",
        hideKey = "Ocultar clave",
        minimize = "Minimizar loader",
        restore = "Restaurar loader",
    },
    pt = {
        brand = "PLAK",
        main = "Início",
        authorization = "Autorização do usuário",
        product = "Produto",
        umbrella = "Umbrella",
        game = "Jogo",
        gameCopy = "Uma experiência Roblox compatível. Selecione para iniciar.",
        metadataLoading = "Carregando detalhes do jogo…",
        metadataUnavailable = "Os detalhes do jogo não estão disponíveis.",
        heroA = "Viva",
        heroB = "a loucura",
        copy = "Entre para continuar sua jornada pelos nossos produtos",
        keyHint = "Digite sua chave aqui",
        keyHintCompact = "Chave de licença",
        keyHintTiny = "Chave",
        signIn = "ENTRAR",
        getKey = "OBTER CHAVE",
        validating = "VALIDANDO",
        waiting = "Aguardando autorização",
        rights = "Todos os direitos reservados",
        empty = "Digite uma chave",
        emptyDescription = "Digite sua chave de licença antes de entrar.",
        ready = "Autorização",
        noValidator = "A autorização não está configurada",
        noValidatorCopy = "O aplicativo não registrou uma função de validação.",
        granted = "Acesso autorizado",
        invalid = "Falha na autorização",
        genericError = "Não foi possível concluir a solicitação. Tente novamente.",
        access = "A conta está desativada",
        accessCopy = "O acesso à conta está desativado. Isso pode ocorrer devido a uma licença expirada.",
        support = "SUPORTE",
        supportCopy = "Acha que isso é um erro? Entre em contato com o suporte",
        report = "RELATAR UM PROBLEMA",
        problems = "Está com problemas no loader?",
        continue = "CONTINUAR",
        close = "FECHAR",
        success = "Sessão concluída!",
        successCopy = "Agradeceríamos seu feedback em nosso site.",
        failure = "Não foi possível concluir a sessão",
        failureCopy = "Talvez seja necessário esperar um pouco antes de tentar novamente.",
        warning = "Atenção",
        info = "Informação",
        website = "Nosso site",
        loading = "Carregando os dados necessários",
        available = "Acesso seguro",
        limited = "Acesso limitado",
        development = "Em desenvolvimento",
        updating = "Atualizando",
        disabled = "Desativado",
        productCopy = "Nosso maior orgulho são os cenários de jogo avançados para cada personagem. Desenvolvidos com jogadores de destaque e atletas de eSports.",
        unavailable = "Este produto não está disponível para iniciar.",
        launchMissing = "O aplicativo não configurou a inicialização do produto.",
        signInFirst = "Entre para iniciar este produto.",
        copied = "Copiado para a área de transferência",
        keyCopied = "O link da chave está pronto para abrir no navegador.",
        noClipboard = "Copie este link",
        noLink = "Nenhum link para obter a chave foi configurado.",
        supportTitle = "Falar com o suporte",
        supportHelp = "Compartilhe estes dados com a equipe de suporte. Sua chave de licença não está incluída.",
        copyDetails = "COPIAR DADOS",
        session = "Configuração da sessão",
        seconds = "segundos",
        refreshed = "Catálogo atualizado",
        busy = "Aguarde a conclusão da solicitação atual.",
        showKey = "Mostrar chave",
        hideKey = "Ocultar chave",
        minimize = "Minimizar loader",
        restore = "Restaurar loader",
    },
}
do
    local additions = {
        en = {
            authReady = "Enter your key to continue",
            authChecking = "Waiting for authentication response…",
            authSlow = "The response is taking longer. Your request is still pending.",
            authGranted = "Access verified",
            authFailed = "Could not verify access",
            pasteKey = "Paste",
            forgetKey = "Forget",
            options = "Options",
            keyForgotten = "Saved key removed. This does not revoke an active session.",
            keyForgetFailed = "Could not remove the saved key",
            keyForgetUnavailable = "Saved-key removal is unavailable",
            clipboardUnavailable = "Clipboard reading unavailable — paste directly into the field",
            clipboardEmpty = "Clipboard is empty or does not contain a single key",
            prefSaved = "Preferences saved · scale fits your screen",
            prefUnsaved = "Could not save preferences · using this session",
            prefSession = "Session preferences · scale fits your screen",
            prefPending = "Saving preferences…",
            languageOption = "Language",
            scaleOption = "Scale",
            motionFull = "Full motion",
            motionReduced = "Reduced motion",
            resetOptions = "Reset options",
            currentGame = "Current experience",
            inCatalog = "Supported · in this catalog",
            notInCatalog = "Not listed in this catalog",
            expiresIn = "Time left:",
            accessPremium = "Premium access",
            accessFree = "Free access",
            accessKeyless = "Keyless access",
            networkHint = "Check your connection and try again when the request finishes.",
            serviceHint = "Check that the FlowAuth runtime and loader are available.",
            keyErrorHint = "Check the key or get a new one.",
            errorHint = "Try again or contact support.",
        },
        es = {
            authReady = "Introduce tu key para continuar",
            authChecking = "Esperando la respuesta de autenticación…",
            authSlow = "La respuesta está tardando. Tu solicitud sigue pendiente.",
            authGranted = "Acceso verificado",
            authFailed = "No se pudo verificar el acceso",
            pasteKey = "Pegar",
            forgetKey = "Olvidar",
            options = "Opciones",
            keyForgotten = "Key guardada eliminada. No revoca una sesión activa.",
            keyForgetFailed = "No se pudo eliminar la key guardada",
            keyForgetUnavailable = "No se puede eliminar la key guardada",
            clipboardUnavailable = "Lectura del portapapeles no disponible: pega en el campo",
            clipboardEmpty = "El portapapeles está vacío o no contiene una sola key",
            prefSaved = "Preferencias guardadas · escala ajustada a la pantalla",
            prefUnsaved = "No se pudo guardar · se aplicó para esta sesión",
            prefSession = "Preferencias de sesión · escala ajustada a la pantalla",
            prefPending = "Guardando preferencias…",
            languageOption = "Idioma",
            scaleOption = "Escala",
            motionFull = "Animaciones completas",
            motionReduced = "Movimiento reducido",
            resetOptions = "Restablecer",
            currentGame = "Experiencia actual",
            inCatalog = "Compatible · en este catálogo",
            notInCatalog = "No aparece en este catálogo",
            expiresIn = "Tiempo restante:",
            accessPremium = "Acceso Premium",
            accessFree = "Acceso Free",
            accessKeyless = "Acceso sin key",
            networkHint = "Revisa tu conexión e inténtalo de nuevo al terminar la solicitud.",
            serviceHint = "Comprueba que el runtime y el loader de FlowAuth estén disponibles.",
            keyErrorHint = "Revisa tu key u obtén una nueva.",
            errorHint = "Reintenta o contacta con soporte.",
        },
        pt = {
            authReady = "Insira sua key para continuar",
            authChecking = "Aguardando resposta da autenticação…",
            authSlow = "A resposta está demorando. Sua solicitação continua pendente.",
            authGranted = "Acesso verificado",
            authFailed = "Não foi possível verificar o acesso",
            pasteKey = "Colar",
            forgetKey = "Esquecer",
            options = "Opções",
            keyForgotten = "Key salva removida. Isso não revoga uma sessão ativa.",
            keyForgetFailed = "Não foi possível remover a key salva",
            keyForgetUnavailable = "Remoção da key salva indisponível",
            clipboardUnavailable = "Leitura do clipboard indisponível: cole no campo",
            clipboardEmpty = "Clipboard vazio ou não contém uma única key",
            prefSaved = "Preferências salvas · escala ajustada à tela",
            prefUnsaved = "Não foi possível salvar · aplicado nesta sessão",
            prefSession = "Preferências da sessão · escala ajustada à tela",
            prefPending = "Salvando preferências…",
            languageOption = "Idioma",
            scaleOption = "Escala",
            motionFull = "Animações completas",
            motionReduced = "Movimento reduzido",
            resetOptions = "Redefinir",
            currentGame = "Experiência atual",
            inCatalog = "Compatível · neste catálogo",
            notInCatalog = "Não listado neste catálogo",
            expiresIn = "Tempo restante:",
            accessPremium = "Acesso Premium",
            accessFree = "Acesso Free",
            accessKeyless = "Acesso sem key",
            networkHint = "Verifique sua conexão e tente novamente quando a solicitação terminar.",
            serviceHint = "Verifique se o runtime e loader do FlowAuth estão disponíveis.",
            keyErrorHint = "Verifique a key ou obtenha uma nova.",
            errorHint = "Tente novamente ou contate o suporte.",
        },
        ru = {
            authReady = "Введите ключ для продолжения",
            authChecking = "Ожидание ответа авторизации…",
            authSlow = "Ответ задерживается. Запрос всё ещё выполняется.",
            authGranted = "Доступ подтверждён",
            authFailed = "Не удалось подтвердить доступ",
            pasteKey = "Вставить",
            forgetKey = "Забыть",
            options = "Настройки",
            keyForgotten = "Сохранённый ключ удалён. Активный доступ не отозван.",
            keyForgetFailed = "Не удалось удалить сохранённый ключ",
            keyForgetUnavailable = "Удаление сохранённого ключа недоступно",
            clipboardUnavailable = "Чтение буфера недоступно: вставьте ключ в поле",
            clipboardEmpty = "Буфер пуст или не содержит один ключ",
            prefSaved = "Настройки сохранены · масштаб под размер экрана",
            prefUnsaved = "Сохранение не удалось · действует в этой сессии",
            prefSession = "Настройки сессии · масштаб под размер экрана",
            prefPending = "Сохранение настроек…",
            languageOption = "Язык",
            scaleOption = "Масштаб",
            motionFull = "Все анимации",
            motionReduced = "Меньше движения",
            resetOptions = "Сбросить",
            currentGame = "Текущая игра",
            inCatalog = "Поддерживается · в каталоге",
            notInCatalog = "Нет в этом каталоге",
            expiresIn = "Осталось:",
            accessPremium = "Доступ Premium",
            accessFree = "Доступ Free",
            accessKeyless = "Доступ без ключа",
            networkHint = "Проверьте подключение и повторите после завершения запроса.",
            serviceHint = "Проверьте доступность runtime и loader FlowAuth.",
            keyErrorHint = "Проверьте ключ или получите новый.",
            errorHint = "Повторите или обратитесь в поддержку.",
        },
    }
    for language, values in pairs(additions) do
        for key, value in pairs(values) do
            Translations[language][key] = value
        end
    end
end

do
    local additions = {
        en = {
            communityTitle = "PLAK COMMUNITY",
            communityIntro = "A place to ask for help, share ideas and follow Plak.",
            communityNews = "NEW IN THIS LOADER",
            communityNewsAuth = "Clearer key validation and success feedback",
            communityNewsPrefs = "Saved language, scale and motion preferences",
            communityNewsGame = "Current-game details and catalog compatibility",
            communityJoin = "Join Discord",
            communityJoinShort = "Join",
            communityCopied = "Copied",
            communitySupport = "Support",
            communitySuggest = "Suggest",
            communityOptional = "Joining is optional. Your key stays independent.",
            communityDockTitle = "Discord",
            communityDockSubtitle = "Support · ideas · updates",
            communityDetails = "See the community and loader updates",
            communityDismiss = "Hide this invitation; remember my choice",
            communityRestore = "Show community",
            communityHide = "Hide community",
            communityInviteCopied = "Invitation copied",
            communityJoinCopy = "Paste the invitation into Discord to join.",
            communitySupportCopy = "Paste the invitation into Discord, then describe your issue.",
            communitySuggestCopy = "Paste the invitation into Discord, then share your game idea.",
        },
        es = {
            communityTitle = "COMUNIDAD PLAK",
            communityIntro = "Un lugar para pedir ayuda, compartir ideas y seguir Plak.",
            communityNews = "NOVEDADES DEL LOADER",
            communityNewsAuth = "Validación de key y confirmación más claras",
            communityNewsPrefs = "Idioma, escala y animaciones guardados",
            communityNewsGame = "Juego actual y compatibilidad del catálogo",
            communityJoin = "Unirme a Discord",
            communityJoinShort = "Unirme",
            communityCopied = "Copiado",
            communitySupport = "Soporte",
            communitySuggest = "Sugerir",
            communityOptional = "Unirte es opcional. Tu key es independiente.",
            communityDockTitle = "Discord",
            communityDockSubtitle = "Ayuda · ideas · novedades",
            communityDetails = "Ver la comunidad y las novedades del loader",
            communityDismiss = "Ocultar esta invitación y recordar mi elección",
            communityRestore = "Mostrar comunidad",
            communityHide = "Ocultar comunidad",
            communityInviteCopied = "Invitación copiada",
            communityJoinCopy = "Pega la invitación en Discord para unirte.",
            communitySupportCopy = "Pega la invitación en Discord y describe el problema.",
            communitySuggestCopy = "Pega la invitación en Discord y comparte tu idea de juego.",
        },
        pt = {
            communityTitle = "COMUNIDADE PLAK",
            communityIntro = "Um lugar para pedir ajuda, compartilhar ideias e acompanhar Plak.",
            communityNews = "NOVIDADES DO LOADER",
            communityNewsAuth = "Validação da key e confirmação mais claras",
            communityNewsPrefs = "Idioma, escala e animações salvos",
            communityNewsGame = "Jogo atual e compatibilidade do catálogo",
            communityJoin = "Entrar no Discord",
            communityJoinShort = "Entrar",
            communityCopied = "Copiado",
            communitySupport = "Suporte",
            communitySuggest = "Sugerir",
            communityOptional = "Entrar é opcional. Sua key é independente.",
            communityDockTitle = "Discord",
            communityDockSubtitle = "Ajuda · ideias · novidades",
            communityDetails = "Ver comunidade e novidades do loader",
            communityDismiss = "Ocultar convite e lembrar minha escolha",
            communityRestore = "Mostrar comunidade",
            communityHide = "Ocultar comunidade",
            communityInviteCopied = "Convite copiado",
            communityJoinCopy = "Cole o convite no Discord para entrar.",
            communitySupportCopy = "Cole o convite no Discord e descreva o problema.",
            communitySuggestCopy = "Cole o convite no Discord e compartilhe sua ideia de jogo.",
        },
        ru = {
            communityTitle = "СООБЩЕСТВО PLAK",
            communityIntro = "Место для помощи, идей и новостей Plak.",
            communityNews = "НОВОЕ В ЗАГРУЗЧИКЕ",
            communityNewsAuth = "Понятная проверка ключа и подтверждение",
            communityNewsPrefs = "Сохранение языка, масштаба и анимаций",
            communityNewsGame = "Текущая игра и совместимость каталога",
            communityJoin = "В Discord",
            communityJoinShort = "Войти",
            communityCopied = "Готово",
            communitySupport = "Помощь",
            communitySuggest = "Идеи",
            communityOptional = "Вступление добровольное. Ключ независим.",
            communityDockTitle = "Discord",
            communityDockSubtitle = "Помощь · идеи · новости",
            communityDetails = "Посмотреть сообщество и новости загрузчика",
            communityDismiss = "Скрыть приглашение и запомнить выбор",
            communityRestore = "Показать сообщество",
            communityHide = "Скрыть сообщество",
            communityInviteCopied = "Приглашение скопировано",
            communityJoinCopy = "Вставьте приглашение в Discord, чтобы вступить.",
            communitySupportCopy = "Вставьте приглашение в Discord и опишите проблему.",
            communitySuggestCopy = "Вставьте приглашение в Discord и предложите игру.",
        },
    }
    for language, values in pairs(additions) do
        for key, value in pairs(values) do
            Translations[language][key] = value
        end
    end
end

local Languages = {
    { Id = "en", Name = "English", Aliases = { "english", "en-us", "en-gb" } },
    { Id = "ru", Name = "Русский", Aliases = { "russian", "русский", "ru-ru" } },
    { Id = "es", Name = "Español", Aliases = { "spanish", "español", "espanol", "es-es", "es-mx" } },
    { Id = "pt", Name = "Português", Aliases = { "portuguese", "português", "portugues", "pt-br", "pt-pt" } },
}
local LanguageAliases = {}
for _, language in ipairs(Languages) do
    LanguageAliases[language.Id] = language.Id
    LanguageAliases[language.Name] = language.Id
    for _, alias in ipairs(language.Aliases) do
        LanguageAliases[alias] = language.Id
    end
end
do
    local offers = {
        en = {
            offerLicenses = "LICENSES",
            offerHeroA = "Your access.",
            offerHeroB = "Your way.",
            offerSubhead = "Choose the license that fits you.",
            offerOneTime = "ONE-TIME PAYMENT",
            offerUSD = "USD",
            offerPerMonth = "USD / month",
            offerLifetimeTerm = "Lifetime license",
            offerMonthlyTerm = "Monthly license",
            offerChooseLifetime = "Choose Lifetime",
            offerChooseMonthly = "Choose Monthly",
            offerTerms = "Prices in USD. Review the terms in the store.",
            offerNotNow = "Not now",
            offerView = "View license keys",
            offerCopied = "Link copied",
            offerStoreCopied = "Store link copied",
            offerLifetimeCopy = "Open it in your browser and select your Lifetime license.",
            offerMonthlyCopy = "Open it in your browser and select your Monthly license.",
            offerStoreCopy = "Open the store link in your browser.",
            offerStore = "Store",
            offerJumpLifetime = "Lifetime · $12",
            offerJumpMonthly = "Monthly · $5",
        },
        es = {
            offerLicenses = "LICENCIAS",
            offerHeroA = "Tu acceso.",
            offerHeroB = "A tu manera.",
            offerSubhead = "Elige la licencia que va contigo.",
            offerOneTime = "PAGO ÚNICO",
            offerUSD = "USD",
            offerPerMonth = "USD / mes",
            offerLifetimeTerm = "Licencia Lifetime",
            offerMonthlyTerm = "Licencia Monthly",
            offerChooseLifetime = "Elegir Lifetime",
            offerChooseMonthly = "Elegir Monthly",
            offerTerms = "Precios en USD. Revisa los términos en la tienda.",
            offerNotNow = "Ahora no",
            offerView = "Ver licencias",
            offerCopied = "Enlace copiado",
            offerStoreCopied = "Enlace de tienda copiado",
            offerLifetimeCopy = "Ábrelo en tu navegador y selecciona tu licencia Lifetime.",
            offerMonthlyCopy = "Ábrelo en tu navegador y selecciona tu licencia Monthly.",
            offerStoreCopy = "Abre el enlace de la tienda en tu navegador.",
            offerStore = "Tienda",
            offerJumpLifetime = "Lifetime · $12",
            offerJumpMonthly = "Monthly · $5",
        },
        pt = {
            offerLicenses = "LICENÇAS",
            offerHeroA = "Seu acesso.",
            offerHeroB = "Do seu jeito.",
            offerSubhead = "Escolha a licença que combina com você.",
            offerOneTime = "PAGAMENTO ÚNICO",
            offerUSD = "USD",
            offerPerMonth = "USD / mês",
            offerLifetimeTerm = "Licença Lifetime",
            offerMonthlyTerm = "Licença Monthly",
            offerChooseLifetime = "Escolher Lifetime",
            offerChooseMonthly = "Escolher Monthly",
            offerTerms = "Preços em USD. Consulte os termos na loja.",
            offerNotNow = "Agora não",
            offerView = "Ver licenças",
            offerCopied = "Link copiado",
            offerStoreCopied = "Link da loja copiado",
            offerLifetimeCopy = "Abra no navegador e selecione sua licença Lifetime.",
            offerMonthlyCopy = "Abra no navegador e selecione sua licença Monthly.",
            offerStoreCopy = "Abra o link da loja no navegador.",
            offerStore = "Loja",
            offerJumpLifetime = "Lifetime · $12",
            offerJumpMonthly = "Monthly · $5",
        },
        ru = {
            offerLicenses = "ЛИЦЕНЗИИ",
            offerHeroA = "Ваш доступ.",
            offerHeroB = "Ваш выбор.",
            offerSubhead = "Выберите подходящую лицензию.",
            offerOneTime = "РАЗОВЫЙ ПЛАТЁЖ",
            offerUSD = "USD",
            offerPerMonth = "USD / месяц",
            offerLifetimeTerm = "Лицензия Lifetime",
            offerMonthlyTerm = "Лицензия Monthly",
            offerChooseLifetime = "Выбрать Lifetime",
            offerChooseMonthly = "Выбрать Monthly",
            offerTerms = "Цены в USD. Ознакомьтесь с условиями в магазине.",
            offerNotNow = "Не сейчас",
            offerView = "Посмотреть лицензии",
            offerCopied = "Ссылка скопирована",
            offerStoreCopied = "Ссылка магазина скопирована",
            offerLifetimeCopy = "Откройте ссылку в браузере и выберите лицензию Lifetime.",
            offerMonthlyCopy = "Откройте ссылку в браузере и выберите лицензию Monthly.",
            offerStoreCopy = "Откройте ссылку магазина в браузере.",
            offerStore = "Магазин",
            offerJumpLifetime = "Lifetime · $12",
            offerJumpMonthly = "Monthly · $5",
        },
    }
    for language, values in pairs(offers) do
        for key, value in pairs(values) do
            Translations[language][key] = value
        end
    end
end
local function resolveLanguage(value)
    if type(value) ~= "string" then
        return nil
    end
    local exact = trim(value)
    local normalized = exact:lower():gsub("_", "-")
    local canonical = LanguageAliases[exact] or LanguageAliases[normalized]
    if canonical then
        return canonical
    end
    local prefix = normalized:match("^(%a%a)%-[%a%d%-]+$")
    return prefix and LanguageAliases[prefix] or nil
end
local Localization = { Bindings = {}, Thread = nil }
function Localization:Get(key)
    return Translations[Settings.Language][key] or Translations.en[key] or key
end
function Localization:Bind(object, key, property, resolver)
    local binding = { Object = object, Key = key, Property = property or "Text", Resolve = resolver }
    self.Bindings[object] = binding
    object[binding.Property] = resolver and resolver() or self:Get(key)
    return binding
end
function Localization:Forget(root)
    for object in pairs(self.Bindings) do
        if object == root or object:IsDescendantOf(root) then
            self.Bindings[object] = nil
        end
    end
end
local function characters(text)
    local output = {}
    for _, code in utf8.codes(text) do
        output[#output + 1] = utf8.char(code)
    end
    return output
end
function Localization:Refresh(animate)
    State.DecodeToken = State.DecodeToken + 1
    local token = State.DecodeToken
    Runtime:Cancel(self.Thread)
    self.Thread = nil
    local entries = {}
    for object, binding in pairs(self.Bindings) do
        if object.Parent then
            local target = binding.Resolve and binding.Resolve() or self:Get(binding.Key)
            if animate and not Settings.ReducedMotion and target ~= "" and binding.Property == "Text" then
                entries[#entries + 1] = {
                    Object = object,
                    Binding = binding,
                    Property = binding.Property,
                    Target = target,
                    Chars = characters(target),
                    Buffer = {},
                }
            else
                object[binding.Property] = target
            end
        end
    end
    if #entries == 0 then
        return
    end
    self.Thread = Runtime:Run(function()
        local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789?+*/"
        for tick = 1, 20 do
            if token ~= State.DecodeToken then
                return
            end
            for _, entry in ipairs(entries) do
                if entry.Object.Parent and self.Bindings[entry.Object] == entry.Binding then
                    local settled = math.floor(#entry.Chars * math.clamp((tick - 3) / 17, 0, 1))
                    for i, char in ipairs(entry.Chars) do
                        if i <= settled or char == " " or char == "\n" then
                            entry.Buffer[i] = char
                        else
                            local index = math.random(1, #alphabet)
                            entry.Buffer[i] = alphabet:sub(index, index)
                        end
                    end
                    entry.Object[entry.Property] = tick == 20 and entry.Target or table.concat(entry.Buffer)
                end
            end
            if tick < 20 then
                task.wait(Motion.DecodeDuration / 20)
            end
        end
    end)
end
local function localized(parent, name, key, size, color, font)
    local object = label(parent, name, "", size, color, font)
    Localization:Bind(object, key)
    return object
end
local function localizedValue(value, fallback)
    if type(value) == "table" then
        return safeText(value[Settings.Language] or value.en or fallback or "", 1024)
    end
    return safeText(value ~= nil and value or fallback or "", 1024)
end
local Artwork = {}
function Artwork.new(parent, name, assetName, override)
    local self = { Scope = Scope.new() }
    self.Root = frame(parent, name, Theme.Surface)
    corner(self.Root, 10)
    self.Root.ClipsDescendants = true
    self.Fallback = frame(self.Root, "Fallback", Theme.Surface)
    self.Fallback.Size = UDim2.fromScale(1, 1)
    gradient(self.Fallback, Color3.fromRGB(36, 24, 32), Theme.Surface, 75)
    local sigil = Icon.new(self.Fallback, "grid", Theme.AccentDark, 72)
    sigil.Root.AnchorPoint = Vector2.new(0.5, 0.5)
    sigil.Root.Position = UDim2.fromScale(0.5, 0.35)
    self.Image = create("ImageLabel", {
        Name = "Artwork",
        BackgroundTransparency = 1,
        Image = "",
        Visible = false,
        Size = UDim2.fromScale(1, 1),
        ScaleType = Enum.ScaleType.Crop,
    }, self.Root)
    corner(self.Image, 10)
    self.Scope:Connect(self.Image:GetPropertyChangedSignal("IsLoaded"), function()
        if self.Image.Parent then
            self.Fallback.Visible = self.Image.Image == "" or not self.Image.IsLoaded
            if self.Image.IsLoaded and self.Image.Image ~= "" then
                self.Image.ImageTransparency = 1
                Animation:To(self.Image, { ImageTransparency = 0 }, Motion.Page)
            end
        end
    end)
    function self:Set(value)
        local image = assetId(value) or ""
        if self.Image.Image ~= image then
            Animation:CancelProperty(self.Image, "ImageTransparency")
            self.Image.ImageTransparency = 0
            self.Image.Image = image
        end
        self.Image.Visible = image ~= ""
        self.Fallback.Visible = image == "" or not self.Image.IsLoaded
    end
    function self:Destroy()
        self.Scope:Destroy()
        Animation:CancelTree(self.Root)
        self.Root:Destroy()
    end
    self:Set(override)
    return self
end
-- Native letterpress artwork: the wordmark is geometry, not a texture or a font.
local BrandArt = {}
BrandArt.__index = BrandArt
BrandArt.Glyphs = {
    P = {
        { 0, 0, 24, 130 },
        { 24, 0, 88, 24 },
        { 88, 0, 24, 90 },
        { 24, 66, 88, 24 },
    },
    L = { { 0, 0, 24, 130 }, { 24, 106, 88, 24 } },
    A = {
        { 11, 132, 56, -2, 24, true },
        { 56, -2, 101, 132, 24, true },
        { 29, 82, 83, 82, 24, true },
    },
    K = {
        { 0, 0, 24, 130 },
        { 25, 72, 104, -3, 24, true },
        { 26, 59, 108, 132, 24, true },
    },
}

function BrandArt:CancelReveal()
    self.RevealToken = self.RevealToken + 1
    for thread in pairs(self.Tasks) do
        Runtime:Cancel(thread)
    end
    table.clear(self.Tasks)
    if self.Underline then
        Animation:CancelProperty(self.Underline, "Size")
        self.Underline.Size = UDim2.fromOffset(self.RuleWidth or 72, 2)
    end
    for _, glyph in ipairs(self.Letters) do
        Animation:CancelProperty(glyph.Root, "Position")
        Animation:CancelProperty(glyph.Root, "GroupTransparency")
        glyph.Root.Position = glyph.Position
        glyph.Root.GroupTransparency = 0
    end
end

function BrandArt:Layout(width, height)
    if not self.Alive then
        return
    end
    width = math.max(1, width or self.Root.AbsoluteSize.X)
    height = math.max(1, height or self.Root.AbsoluteSize.Y)
    if self.LayoutWidth == width and self.LayoutHeight == height then
        return
    end
    self.LayoutWidth, self.LayoutHeight = width, height
    self:CancelReveal()
    self.Root.Size = UDim2.fromOffset(width, height)
    local scale = math.min(width / 360, height / 452)
    self.Scale.Scale = scale
    self.Stage.Position = UDim2.fromOffset((width - 360 * scale) / 2, (height - 452 * scale) / 2)
    self.Caption.TextSize = math.clamp(10 / scale, 10, 19)
    self.Serial.TextSize = self.Caption.TextSize
    self.Signature.TextSize = math.clamp(9 / scale, 9, 17)
    self.Caption.Visible = width >= 142
    self.Serial.Visible = width >= 142
    self.Signature.Visible = width >= 142
end

function BrandArt:Reveal(instant)
    if not self.Alive or not State.Alive then
        return
    end
    self:CancelReveal()
    if instant or Settings.ReducedMotion or not State.Visible or not self.Root.Visible then
        return
    end
    local token = self.RevealToken
    for index, glyph in ipairs(self.Letters) do
        glyph.Root.GroupTransparency = 1
        glyph.Root.Position = UDim2.fromOffset(glyph.Position.X.Offset, glyph.Position.Y.Offset + 16)
        local thread
        thread = Runtime:Later((index - 1) * 0.045, function()
            self.Tasks[thread] = nil
            if self.Alive and self.RevealToken == token and glyph.Root.Parent then
                Animation:To(glyph.Root, { Position = glyph.Position, GroupTransparency = 0 }, Motion.Enter)
            end
        end)
        if thread then
            self.Tasks[thread] = true
        else
            glyph.Root.Position = glyph.Position
            glyph.Root.GroupTransparency = 0
        end
    end
    Animation:CancelProperty(self.Underline, "Size")
    self.Underline.Size = UDim2.fromOffset(0, 2)
    Animation:To(self.Underline, { Size = UDim2.fromOffset(self.RuleWidth or 72, 2) }, Motion.Enter)
end

function BrandArt:SetState(value)
    if not self.Alive or not State.Alive then
        return
    end
    local name = tostring(value or "idle"):lower()
    if self.VisualState == name then
        return
    end
    self.VisualState = name
    local active = name == "focused"
        or name == "authfocused"
        or name == "validating"
        or name == "success"
        or name == "authorized"
    local failed = name == "error" or name == "autherror" or name == "failure"
    Animation:To(self.Border, { Transparency = failed and 0.35 or active and 0.52 or 0.84 }, Motion.Hover)
    Animation:To(self.Edge, { BackgroundTransparency = failed and 0.1 or active and 0.28 or 0.6 }, Motion.Hover)
    self.RuleWidth = name == "validating" and 110 or (name == "success" or name == "authorized") and 96 or 72
    Animation:To(self.Underline, {
        BackgroundColor3 = failed and Theme.Accent or active and Theme.Text or Theme.Accent,
        Size = UDim2.fromOffset(self.RuleWidth, 2),
    }, Motion.Page)
    for index, dot in ipairs(self.Ticks) do
        local lit = active or failed or index == 1
        Animation:To(dot, { BackgroundTransparency = lit and 0.15 or 0.7 }, Motion.Hover)
    end
end

function BrandArt:Destroy()
    if not self.Alive then
        return
    end
    self:CancelReveal()
    self.Alive = false
    Animation:CancelTree(self.Root)
    self.Root:Destroy()
    table.clear(self.Letters)
    table.clear(self.Ticks)
end

function BrandArt.new(parent, name)
    local self = setmetatable({ Alive = true, RevealToken = 0, Tasks = {}, Letters = {}, Ticks = {} }, BrandArt)
    self.Root = frame(parent, name or "PlakWordmark", Color3.fromRGB(19, 15, 21))
    self.Root.ClipsDescendants = true
    corner(self.Root, 10)
    gradient(self.Root, Color3.fromRGB(29, 17, 25), Color3.fromRGB(13, 13, 17), 74)
    self.Border = stroke(self.Root, Theme.AccentDark, 1, 0.84)
    self.Stage = frame(self.Root, "Geometry")
    self.Stage.BackgroundTransparency = 1
    self.Stage.Size = UDim2.fromOffset(360, 452)
    self.Scale = create("UIScale", { Scale = 1 }, self.Stage)

    -- Two diagonal planes align with the A/K angles. They are material, not camera motion.
    local plane = frame(self.Stage, "BurgundyPlane", Theme.AccentDark)
    plane.AnchorPoint = Vector2.new(0.5, 0.5)
    place(plane, 284, 261, 130, 620)
    plane.Rotation = 22
    plane.BackgroundTransparency = 0.73
    local seam = frame(self.Stage, "PlaneSeam", Theme.AccentDark)
    seam.AnchorPoint = Vector2.new(0.5, 0.5)
    place(seam, 216, 269, 1, 620)
    seam.Rotation = 22
    seam.BackgroundTransparency = 0.54
    local inset = frame(self.Stage, "InkField", Color3.fromRGB(15, 13, 18))
    place(inset, 28, 68, 304, 332)
    inset.BackgroundTransparency = 0
    corner(inset, 4)
    local edge = frame(self.Stage, "LeftRegistration", Theme.Accent)
    place(edge, 27, 90, 1, 78)
    edge.BackgroundTransparency = 0.6
    self.Edge = edge
    local topRail = frame(self.Stage, "TopRegistration", Theme.AccentDark)
    place(topRail, 28, 67, 38, 1)
    topRail.BackgroundTransparency = 0.38
    local bottomRail = frame(self.Stage, "BottomRegistration", Theme.AccentDark)
    place(bottomRail, 285, 400, 47, 1)
    bottomRail.BackgroundTransparency = 0.4

    self.Caption = label(self.Stage, "BrandCaption", "PLAK", 10, Theme.Secondary, Theme.Medium)
    place(self.Caption, 28, 29, 96, 16)
    self.Serial = label(self.Stage, "PlateIndex", "01 / 04", 10, Theme.Muted, Theme.Medium)
    self.Serial.TextXAlignment = Enum.TextXAlignment.Right
    place(self.Serial, 252, 29, 80, 16)
    for index = 1, 3 do
        local dot = frame(self.Stage, "Register_" .. index, Theme.Accent)
        place(dot, 293 + (index - 1) * 14, 50, 7, 3)
        dot.BackgroundTransparency = index == 1 and 0.15 or 0.7
        self.Ticks[index] = dot
    end

    local function bevel(parentObject, dx, dy)
        for _, y in ipairs({ 0, 90 }) do
            local cut = frame(parentObject, "CornerCounter", Color3.fromRGB(15, 13, 18))
            cut.AnchorPoint = Vector2.new(0.5, 0.5)
            place(cut, 112 + dx, y + dy, math.sqrt(2) * 18, math.sqrt(2) * 18)
            cut.Rotation = 45
        end
    end
    local function segment(parentObject, spec, color, dx, dy, face)
        local piece = frame(parentObject, face and "Face" or "Extrusion", color)
        if spec[6] then
            local vx, vy = spec[3] - spec[1], spec[4] - spec[2]
            piece.AnchorPoint = Vector2.new(0.5, 0.5)
            place(
                piece,
                (spec[1] + spec[3]) / 2 + dx,
                (spec[2] + spec[4]) / 2 + dy,
                math.sqrt(vx * vx + vy * vy),
                spec[5]
            )
            piece.Rotation = math.deg(math.atan2(vy, vx))
        else
            place(piece, spec[1] + dx, spec[2] + dy, spec[3], spec[4])
        end
        if face then
            gradient(piece, color, color:Lerp(Theme.AccentDark, 0.16), 90)
        end
        return piece
    end
    for index, data in ipairs({ { "P", 43, 85 }, { "L", 193, 85 }, { "A", 43, 244 }, { "K", 193, 244 } }) do
        local letter = group(self.Stage, "Letter_" .. data[1])
        place(letter, data[2], data[3], 123, 142)
        letter.ClipsDescendants = true
        local face = index <= 2 and Color3.fromRGB(239, 226, 231) or Theme.Accent
        for _, spec in ipairs(BrandArt.Glyphs[data[1]]) do
            segment(letter, spec, Color3.fromRGB(96, 30, 51), 7, 9, false)
        end
        if data[1] == "P" then
            bevel(letter, 7, 9)
        end
        for _, spec in ipairs(BrandArt.Glyphs[data[1]]) do
            segment(letter, spec, face, 0, 0, true)
        end
        if data[1] == "P" then
            bevel(letter, 0, 0)
        end
        self.Letters[index] = { Root = letter, Position = letter.Position }
    end

    self.Underline = frame(self.Stage, "AccentRule", Theme.Accent)
    place(self.Underline, 28, 419, 72, 2)
    self.Signature = label(self.Stage, "PlateSignature", "P / L / A / K", 9, Theme.Muted, Theme.Medium)
    self.Signature.TextXAlignment = Enum.TextXAlignment.Right
    place(self.Signature, 190, 411, 142, 17)
    self:Layout(360, 452)
    table.insert(Runtime.Finalizers, function()
        self:Destroy()
    end)
    return self
end

-- Keep the optional legacy artwork setter without making the default wordmark image-dependent.
function BrandArt:Set(value)
    local image = assetId(value)
    Runtime:Disconnect(self.OverrideConnection)
    self.OverrideConnection = nil
    if self.OverrideImage then
        Animation:CancelTree(self.OverrideImage)
        self.OverrideImage:Destroy()
        self.OverrideImage = nil
    end
    self.Stage.Visible = true
    if not image then
        return
    end
    self.OverrideImage = create("ImageLabel", {
        Name = "HostArtwork",
        Image = image,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ScaleType = Enum.ScaleType.Fit,
    }, self.Root)
    corner(self.OverrideImage, 10)
    local function settle()
        if self.Alive and self.OverrideImage then
            self.Stage.Visible = not self.OverrideImage.IsLoaded
        end
    end
    settle()
    self.OverrideConnection = Runtime:Connect(self.OverrideImage:GetPropertyChangedSignal("IsLoaded"), settle)
end
local Modal = { Config = nil, ProgressHandle = nil }
local Navigation = {}
local Responsive = {}
local Toasts = { Items = {}, Queue = {} }
local Statuses = {
    Available = { Key = "available", Icon = "shield-check", Launch = true },
    LimitedAccess = { Key = "limited", Icon = "user-x", Launch = false },
    Development = { Key = "development", Icon = "tools", Launch = false },
    Updating = { Key = "updating", Icon = "clock", Launch = false },
    Disabled = { Key = "disabled", Icon = "shield-alert", Launch = false },
}
local Cards = {}
-- Supported experiences are configured here, not fetched from a remote catalog.
local function productName(product)
    product = product or {}
    return localizedValue(
        product.Name or product.ResolvedName or product.FallbackName,
        Localization:Get(product.GameId and "game" or "umbrella")
    )
end
local SupportedGames = {
    { Id = "roll-a-fisherman", GameId = 90920025162454, FallbackName = "Roll a Fisherman", Status = "Available" },
}
local GameMedia = { Ready = false, Cache = {}, Pending = {}, Queue = {}, Bindings = {}, Active = nil, Serial = 0 }
function GameMedia:PlaceId(value)
    local id = finite(value, 0)
    return id > 0 and id < 9007199254740992 and id == math.floor(id) and id or nil
end
function GameMedia:Thumbnail(id)
    -- GameThumbnail uses a placeId; GameIcon uses a universeId. Native content works without file APIs.
    return "rbxthumb://type=GameThumbnail&id=" .. string.format("%.0f", id) .. "&w=768&h=432"
end
function GameMedia:RequestFunction()
    local direct = capability("request") or capability("http_request")
    if direct then
        return direct
    end
    local ok, environment = pcall(function()
        return type(getgenv) == "function" and getgenv() or nil
    end)
    local environments = { ok and environment or {}, _G or {}, getfenv and getfenv(0) or {} }
    for _, env in ipairs(environments) do
        for _, name in ipairs({ "syn", "fluxus", "http" }) do
            local holder = env[name]
            if type(holder) == "table" and type(holder.request) == "function" then
                return holder.request
            end
        end
    end
    return nil
end
function GameMedia:Get(url, json, valid)
    if not valid() then
        return nil
    end
    local requestFn = self:RequestFunction()
    local ok, response
    if requestFn then
        ok, response = pcall(requestFn, {
            Url = url,
            Method = "GET",
            Headers = { Accept = json and "application/json" or "image/png" },
            Timeout = 8,
        })
        if not ok or type(response) ~= "table" then
            return nil
        end
        local code = tonumber(response.StatusCode or response.Status or response.status_code or 200)
        if not code or code < 200 or code >= 300 then
            return nil
        end
        response = response.Body or response.body
    else
        -- Studio client HTTP may be unavailable. Failure is bounded and never blocks the UI.
        ok, response = pcall(function()
            return game:HttpGet(url)
        end)
        if not ok then
            return nil
        end
    end
    if not valid() or type(response) ~= "string" or response == "" or #response > (json and 262144 or 3000000) then
        return nil
    end
    if not json then
        return response
    end
    local decoded, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(response)
    end)
    return decoded and type(data) == "table" and data or nil
end
function GameMedia:Resolve(placeId, valid, partial)
    local info = partial or { Image = self:Thumbnail(placeId) }
    local universe = self:Get(
        "https://apis.roblox.com/universes/v1/places/" .. string.format("%.0f", placeId) .. "/universe",
        true,
        valid
    )
    local universeId = universe and self:PlaceId(universe.universeId)
    if universeId then
        info.UniverseId = universeId
        local suffix = string.format("%.0f", universeId)
        local games = self:Get("https://games.roblox.com/v1/games?universeIds=" .. suffix, true, valid)
        local item = games and type(games.data) == "table" and games.data[1]
        if
            type(item) == "table"
            and tonumber(item.id) == universeId
            and type(item.name) == "string"
            and trim(item.name) ~= ""
        then
            info.Name = safeText(item.name, 160)
        end
        local thumbnails = self:Get(
            "https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds="
                .. suffix
                .. "&countPerUniverse=1&defaults=true&size=768x432&format=Png&isCircular=false",
            true,
            valid
        )
        local set = thumbnails and type(thumbnails.data) == "table" and thumbnails.data[1]
        local thumb = type(set) == "table"
            and tonumber(set.universeId) == universeId
            and type(set.thumbnails) == "table"
            and set.thumbnails[1]
        local url = type(thumb) == "table" and thumb.state == "Completed" and thumb.imageUrl
        local host = type(url) == "string" and url:match("^https://([^/]+)/")
        local write, custom = capability("writefile"), capability("getcustomasset") or capability("getsynasset")
        -- Only Roblox's image CDN is eligible for file materialization, never an arbitrary JSON URL.
        if
            host
            and (host == "rbxcdn.com" or host:match("^[%w%-%.]+%.rbxcdn%.com$"))
            and write
            and custom
            and valid()
        then
            local bytes = self:Get(url, false, valid)
            if bytes and bytes:sub(1, 8) == "\137PNG\13\10\26\10" and valid() then
                local imageOk, image = pcall(function()
                    local path = "PlakUi_game_" .. string.format("%.0f", placeId) .. "_" .. self.Serial .. ".png"
                    if not valid() then
                        return nil
                    end
                    write(path, bytes)
                    if not valid() then
                        return nil
                    end
                    return custom(path)
                end)
                if imageOk and valid() and assetId(image) then
                    info.Image = image
                end
            end
        end
    end
    if not info.Name and valid() then
        local ok, data = pcall(function()
            local marketplace = game:GetService("MarketplaceService")
            local query = marketplace.GetProductInfoAsync or marketplace.GetProductInfo
            return query(marketplace, placeId, Enum.InfoType.Asset)
        end)
        if ok and type(data) == "table" and type(data.Name) == "string" and trim(data.Name) ~= "" then
            info.Name = safeText(data.Name, 160)
        end
    end
    return info
end
function GameMedia:Apply(card, info)
    if not card.Scope.Alive or not card.Root.Parent or not State.Alive then
        return
    end
    local product = card.Product
    if product.Name == nil and info.Name then
        product.ResolvedName = info.Name
    end
    product.UniverseId = info.UniverseId
    if product.Artwork == nil then
        card.Artwork:Set(info.Image)
    end
    -- Rebinding invalidates only this name's captured decode target when asynchronous metadata arrives.
    Localization:Bind(card.Name, "game", "Text", function()
        return productName(product)
    end)
    if UI.Breadcrumb then
        Navigation:Refresh()
    end
    if Experience then
        Experience:RefreshGame()
    end
end
function GameMedia:Drain()
    if
        not State.Alive
        or not self.Ready
        or self.Active
        or #self.Queue == 0
        or State.Activity == "Validating"
        or State.Activity == "Completing"
    then
        return
    end
    local id = table.remove(self.Queue, 1)
    self.Serial = self.Serial + 1
    local job = { Id = id, Scope = Scope.new(), Serial = self.Serial, Partial = { Image = self:Thumbnail(id) } }
    self.Active = job
    local function valid()
        return State.Alive and job.Scope.Alive and self.Active == job
    end
    local function finish(info)
        if not valid() then
            return
        end
        self.Active = nil
        self.Pending[id] = nil
        job.Scope:Destroy()
        -- A thumbnail timeout must not discard a game name that was already resolved.
        info = info or job.Partial
        info.Expires = os.clock() + (info.Name and 300 or 30)
        self.Cache[id] = info
        for card, placeId in pairs(self.Bindings) do
            if placeId == id then
                self:Apply(card, info)
            end
        end
        self:Drain()
    end
    job.Scope:Later(12, function()
        finish(nil)
    end)
    job.Scope:Run(function()
        local ok, info = pcall(function()
            return self:Resolve(id, valid, job.Partial)
        end)
        if valid() then
            -- Do not cancel the currently executing worker in Scope:Destroy.
            job.Scope.Tasks[coroutine.running()] = nil
            finish(ok and info or nil)
        end
    end)
end
function GameMedia:Watch(card)
    local id = self:PlaceId(card.Product.GameId)
    if not id then
        return
    end
    self.Bindings[card] = id
    card.Scope.Finalizers[#card.Scope.Finalizers + 1] = function()
        self.Bindings[card] = nil
    end
    local cached = self.Cache[id]
    if cached and cached.Expires > os.clock() then
        self:Apply(card, cached)
        return
    end
    if not self.Pending[id] then
        self.Pending[id] = true
        self.Queue[#self.Queue + 1] = id
    end
    self:Drain()
end
function GameMedia:Destroy()
    if self.Active then
        self.Active.Scope:Destroy()
    end
    self.Active = nil
    table.clear(self.Cache)
    table.clear(self.Pending)
    table.clear(self.Queue)
    table.clear(self.Bindings)
end

local function cleanMessage(message, fallback)
    if type(message) ~= "string" or trim(message) == "" then
        return fallback
    end
    return safeText(message, 1000)
end
local TextMetrics = { Values = {}, Count = 0 }
function TextMetrics:Get(text, size, font, width)
    local key = text .. "\0" .. tostring(size) .. "\0" .. tostring(font) .. "\0" .. tostring(width)
    local cached = self.Values[key]
    if cached then
        return cached
    end
    local ok, value = pcall(function()
        return Services.Text:GetTextSize(text, size, font, Vector2.new(width, 10000))
    end)
    if not ok then
        -- Font/service failures are retryable, never permanent cache entries.
        return nil
    end
    if self.Count >= 192 then
        table.clear(self.Values)
        self.Count = 0
    end
    self.Values[key] = value
    self.Count = self.Count + 1
    return value
end
local function measure(text, size, font, width)
    local value = TextMetrics:Get(text, size, font, width)
    return value and value.Y or math.ceil(#text * size * 0.54 / math.max(1, width)) * size * 1.3
end
function Toasts:Layout()
    if not UI.Stage then
        return
    end
    local size = UI.Stage.AbsoluteSize
    local width = math.min(380, math.max(160, size.X - 24))
    local y = 12
    for _, item in ipairs(self.Items) do
        local titleHeight = math.min(40, math.max(18, measure(item.Title, 14, Theme.Medium, width - 90)))
        local subHeight = math.min(88, math.max(18, measure(item.Subtitle, 12, Theme.Font, width - 90)))
        subHeight = math.min(subHeight, math.max(18, size.Y - titleHeight - 54))
        item.Height = math.min(size.Y - 24, math.max(80, 24 + titleHeight + subHeight + 6))
        item.Root.Size = UDim2.fromOffset(width, item.Height)
        place(item.TitleLabel, 52, 13, width - 90, titleHeight)
        place(item.SubLabel, 52, 17 + titleHeight, width - 90, subHeight)
        place(item.Close.Root, width - 48, 6, 44, 44)
        if not item.Closing then
            Animation:To(item.Root, { Position = UDim2.fromOffset(size.X - width - 12, y) }, Motion.Enter)
        end
        y = y + item.Height + 10
    end
    -- Bound visible notifications to the available height, not a fixed desktop-only stack count.
    if y > size.Y - 12 and #self.Items > 1 then
        self:Close(self.Items[1], true)
    end
end
function Toasts:Close(item, immediate)
    if item.Removed or (item.Closing and not immediate) then
        return
    end
    item.Closing = true
    item.Scope:Cancel(item.Timer)
    local function remove()
        if item.Removed then
            return
        end
        item.Removed = true
        for index, value in ipairs(self.Items) do
            if value == item then
                table.remove(self.Items, index)
                break
            end
        end
        item.Scope:Destroy()
        Animation:CancelTree(item.Root)
        item.Root:Destroy()
        self:Layout()
        self:Drain()
    end
    if immediate then
        remove()
    else
        Animation:To(
            item.Root,
            { GroupTransparency = 1, Position = item.Root.Position + UDim2.fromOffset(20, 0) },
            Motion.Exit,
            remove
        )
    end
end
function Toasts:Drain()
    if not State.Alive or not UI.ToastLayer then
        return
    end
    local limit = math.clamp(math.floor(UI.Stage.AbsoluteSize.Y / 120), 1, 4)
    while #self.Items < limit and #self.Queue > 0 do
        self:Create(table.remove(self.Queue, 1))
    end
end
function Toasts:Create(config)
    local item = {
        Scope = Scope.new(),
        Title = cleanMessage(config.Title, Localization:Get("info")),
        Subtitle = cleanMessage(config.Subtitle, ""),
        Closing = false,
    }
    item.Root = group(UI.ToastLayer, "Toast")
    item.Root.BackgroundColor3 = Theme.Input
    item.Root.BackgroundTransparency = 0
    item.Root.GroupTransparency = 1
    item.Root.Position = UDim2.fromOffset(UI.Stage.AbsoluteSize.X, 12)
    corner(item.Root, 10)
    stroke(item.Root, Theme.Line, 1)
    local accent = config.Type == "warning" and Theme.Warning or Theme.Accent
    local rail = frame(item.Root, "Accent", accent)
    place(rail, 0, 12, 3, 58)
    corner(rail, 2)
    local icon = Icon.new(
        item.Root,
        config.Icon
            or (
                config.Type == "success" and "check"
                or config.Type == "error" and "shield-alert"
                or config.Type == "warning" and "warning"
                or "info"
            ),
        accent,
        22
    )
    place(icon.Root, 16, 17, 22, 22)
    item.TitleLabel = label(item.Root, "Title", item.Title, 14, Theme.Text, Theme.Medium)
    item.TitleLabel.TextWrapped = true
    item.TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    item.SubLabel = label(item.Root, "Subtitle", item.Subtitle, 12, Theme.Secondary)
    item.SubLabel.TextWrapped = true
    item.SubLabel.TextYAlignment = Enum.TextYAlignment.Top
    item.SubLabel.TextTruncate = Enum.TextTruncate.AtEnd
    item.Close = Button.new(
        item.Root,
        "Dismiss",
        "",
        false,
        "x",
        function()
            self:Close(item)
        end,
        item.Scope,
        function()
            return State.Alive
        end
    )
    item.Close.Root.BackgroundTransparency = 1
    item.Close.Icon.Root.Position = UDim2.new(0.5, -9, 0.5, 0)
    self.Items[#self.Items + 1] = item
    self:Layout()
    Animation:To(item.Root, { GroupTransparency = 0 }, Motion.Enter)
    item.Timer = item.Scope:Later(math.clamp(finite(config.Duration, 4), 0.5, 30), function()
        self:Close(item)
    end)
    item.CloseToast = function()
        self:Close(item)
    end
    return item
end
local function setButtonKey(button, key)
    Localization:Bind(button.Label, key)
end
function Modal:Layout(settleMotion)
    if State.Modal == "licenses" then
        LicenseOffer:Layout(settleMotion)
        return
    end
    local size = UI.Stage.AbsoluteSize
    if settleMotion then
        if not State.Modal and UI.Overlay.Visible then
            self:Close(true)
        end
        if State.Modal then
            Animation:CancelProperty(UI.Result, "Position")
            Animation:CancelProperty(UI.ResultScale, "Scale")
            Animation:CancelProperty(UI.ProgressPanel, "Position")
            UI.Result.GroupTransparency = 0
            UI.ProgressPanel.GroupTransparency = 0
        end
    end
    local width = math.min(348, math.max(200, size.X - 28))
    local height = math.min(364, math.max(180, size.Y - 28))
    local center = State.WindowCenter or size / 2
    center = Vector2.new(
        math.clamp(center.X, width / 2 + 8, math.max(width / 2 + 8, size.X - width / 2 - 8)),
        math.clamp(center.Y, height / 2 + 8, math.max(height / 2 + 8, size.Y - height / 2 - 8))
    )
    UI.Result.Size = UDim2.fromOffset(width, height)
    UI.Result.Position = UDim2.fromOffset(center.X, center.Y)
    UI.ResultScale.Scale = 1
    local innerWidth = width - 40
    local short = height < 300
    local hasLink = self.Config
        and type(self.Config.Link) == "string"
        and self.Config.Link ~= ""
        and not self.Config.CopyText
        and height >= 344
    local iconSize = short and 34 or 50
    place(UI.ResultSymbol, math.floor((width - iconSize) / 2), short and 18 or 52, iconSize, iconSize)
    place(UI.ResultIcon.Root, iconSize * 0.27, iconSize * 0.27, iconSize * 0.46, iconSize * 0.46)
    place(UI.ResultTitle, 20, short and 58 or hasLink and 108 or 124, innerWidth, short and 38 or 44)
    local descriptionY = short and 99 or hasLink and 154 or 168
    local descriptionHeight = math.max(32, height - 117 - descriptionY - (hasLink and 60 or 12))
    place(UI.ResultDescription, 20, descriptionY, innerWidth, descriptionHeight)
    place(UI.ResultCopy, 20, descriptionY, innerWidth, descriptionHeight)
    place(UI.ResultLink.Root, 20, descriptionY + descriptionHeight + 4, innerWidth, 44)
    UI.ResultLink.Root.Visible = hasLink == true
    place(UI.ResultDivider, 20, height - 117, innerWidth, 1)
    place(UI.ResultSupport, 20, height - 106, innerWidth, 28)
    UI.ResultDivider.Visible = not short
    UI.ResultSupport.Visible = not short
    place(UI.ResultAction.Root, 20, height - 66, innerWidth, 44)
    place(UI.ResultClose.Root, width - 48, 4, 44, 44)
    local progressWidth = math.min(496, math.max(200, size.X - 28))
    local progressCenter = Vector2.new(
        math.clamp(center.X, progressWidth / 2 + 8, math.max(progressWidth / 2 + 8, size.X - progressWidth / 2 - 8)),
        center.Y
    )
    local authCompletion = self.AuthCompletion == true
    UI.ProgressPanel.Size = UDim2.fromOffset(progressWidth, authCompletion and 104 or 76)
    UI.ProgressPanel.Position = UDim2.fromOffset(progressCenter.X, progressCenter.Y)
    place(UI.ProgressText, authCompletion and 54 or 20, 12, progressWidth - (authCompletion and 74 or 100), 27)
    if UI.ProgressCheck then
        place(UI.ProgressCheck.Root, 20, 14, 24, 24)
        place(UI.ProgressLicense, 20, 43, progressWidth - 40, 24)
        UI.ProgressLicense.Visible = authCompletion
        UI.ProgressPercent.Visible = not authCompletion
    end
    place(UI.ProgressPercent, progressWidth - 80, 12, 60, 27)
    place(UI.ProgressTrack, 20, authCompletion and 78 or 48, progressWidth - 40, 7)
end
function Modal:Refresh()
    local config = self.Config
    if not config then
        return
    end
    local kind = config.Type or "info"
    local titleKey = config.TitleKey
        or (
            kind == "success" and "success"
            or kind == "error" and "failure"
            or kind == "disabled" and "access"
            or kind == "warning" and "warning"
            or "info"
        )
    local descriptionKey = kind == "success" and "successCopy"
        or kind == "error" and "failureCopy"
        or kind == "disabled" and "accessCopy"
        or "genericError"
    Localization:Bind(UI.ResultTitle, titleKey, "Text", function()
        return config.Title and localizedValue(config.Title) or Localization:Get(titleKey)
    end)
    Localization:Bind(UI.ResultDescription, descriptionKey, "Text", function()
        return config.Description and localizedValue(config.Description) or Localization:Get(descriptionKey)
    end)
    setButtonKey(UI.ResultAction, config.ActionKey or (kind == "disabled" and "support" or "report"))
    Localization:Bind(UI.ResultSupport, kind == "disabled" and "supportCopy" or "problems")
    UI.ResultIcon.Root:Destroy()
    UI.ResultIcon = Icon.new(
        UI.ResultSymbol,
        config.Icon
            or (
                kind == "success" and "check"
                or kind == "error" and "x"
                or kind == "disabled" and "user-x"
                or kind == "warning" and "warning"
                or "info"
            ),
        Theme.Surface,
        24
    )
    UI.ResultCopy.Visible = config.CopyText ~= nil
    UI.ResultCopy.Text = config.CopyText or ""
    self:Layout()
    UI.ResultDescription.Visible = config.CopyText == nil
end
function Modal:Open(config)
    if not State.Alive then
        return
    end
    State.ModalToken = State.ModalToken + 1
    if LicenseOffer then
        LicenseOffer:CancelReveal()
    end
    if UI.LicensePanel then
        Animation:CancelTree(UI.LicensePanel)
        UI.LicensePanel.Visible = false
    end
    self.Config = config or {}
    self.ActionBusy = false
    State.Modal = "result"
    reconcile()
    UI.Overlay.Visible = State.Visible
    UI.ProgressPanel.Visible = false
    UI.Result.Visible = true
    UI.ResultAction:SetDisabled(false)
    Animation:CancelTree(UI.ProgressPanel)
    self:Refresh()
    UI.Result.GroupTransparency = 1
    UI.ResultScale.Scale = 0.96
    local destination = UI.Result.Position
    UI.Result.Position = destination + UDim2.fromOffset(0, 38)
    Animation:To(UI.Backdrop, { BackgroundTransparency = 0.48 }, Motion.Enter)
    Animation:To(UI.Result, { GroupTransparency = 0, Position = destination }, Motion.Enter)
    Animation:To(UI.ResultScale, { Scale = 1 }, Motion.Enter)
end
function Modal:Close(immediate)
    if not State.Alive then
        return
    end
    State.ModalToken = State.ModalToken + 1
    local token = State.ModalToken
    if LicenseOffer then
        LicenseOffer:CancelReveal()
    end
    self.Config = nil
    State.Modal = nil
    reconcile()
    local function finish()
        if token == State.ModalToken then
            UI.Overlay.Visible = false
            if UI.LicensePanel then
                UI.LicensePanel.Visible = false
            end
            UI.Result.Visible = false
            UI.ProgressPanel.Visible = false
            Localization.Bindings[UI.ResultTitle] = nil
            Localization.Bindings[UI.ResultDescription] = nil
        end
    end
    if immediate or not State.Visible then
        Animation:CancelTree(UI.Overlay)
        finish()
    else
        UI.ResultAction:SetDisabled(true)
        Animation:To(UI.Backdrop, { BackgroundTransparency = 1 }, Motion.Exit)
        local panel = UI.LicensePanel and UI.LicensePanel.Visible and UI.LicensePanel
            or UI.Result.Visible and UI.Result
            or UI.ProgressPanel
        Animation:To(
            panel,
            { GroupTransparency = 1, Position = panel.Position + UDim2.fromOffset(0, 32) },
            Motion.Exit,
            finish
        )
    end
end
function Modal:Loading(config)
    if not State.Alive then
        return
    end
    if type(config) == "string" then
        config = { Text = config }
    end
    config = config or {}
    if LicenseOffer then
        LicenseOffer:CancelReveal()
    end
    if UI.LicensePanel then
        Animation:CancelTree(UI.LicensePanel)
        UI.LicensePanel.Visible = false
    end
    self.AuthCompletion = config.AuthCompletion == true
    if UI.ProgressCheck then
        UI.ProgressCheck.Root.Visible = false
    end
    State.ModalToken = State.ModalToken + 1
    State.Modal = "progress"
    reconcile()
    self.Config = nil
    UI.Overlay.Visible = State.Visible
    UI.Result.Visible = false
    UI.ProgressPanel.Visible = true
    Animation:CancelTree(UI.Result)
    UI.ProgressPanel.GroupTransparency = 1
    self:Layout()
    local destination = UI.ProgressPanel.Position
    UI.ProgressPanel.Position = destination + UDim2.fromOffset(0, 32)
    Animation:To(UI.ProgressPanel, { GroupTransparency = 0, Position = destination }, Motion.Enter)
    Animation:To(UI.Backdrop, { BackgroundTransparency = 0.48 }, Motion.Enter)
    self:SetText(config.Text)
    self:SetProgress(finite(config.Progress, 0), true)
    local generation = State.ModalToken
    local handle = {}
    function handle:SetProgress(value)
        if State.Alive and State.ModalToken == generation then
            Modal:SetProgress(value)
        end
        return self
    end
    function handle:SetText(value)
        if State.Alive and State.ModalToken == generation then
            Modal:SetText(value)
        end
        return self
    end
    function handle:Complete(result)
        if State.Alive and State.ModalToken == generation then
            result = result or { Type = "success" }
            if result.Type == "error" or result.Type == "disabled" then
                Modal:Open(result)
            else
                Modal:SetProgress(1)
                Runtime:Later(Settings.ReducedMotion and 0 or 0.22, function()
                    if State.ModalToken == generation then
                        Modal:Open(result)
                    end
                end)
            end
        end
        return self
    end
    function handle:Close()
        if State.Alive and State.ModalToken == generation then
            Modal:Close()
        end
    end
    self.ProgressHandle = handle
    return handle
end
function Modal:SetProgress(value, instant)
    value = math.clamp(finite(value, State.Progress), 0, 1)
    State.Progress = value
    State.Indeterminate = false
    UI.ProgressPercent.Text = string.format("%d%%", math.floor(value * 100 + 0.5))
    if instant then
        Animation:CancelTree(UI.ProgressFill)
        UI.ProgressFill.Size = UDim2.fromScale(value, 1)
    else
        Animation:To(UI.ProgressFill, { Size = UDim2.fromScale(value, 1) }, Motion.Progress)
    end
end
function Modal:SetText(value)
    Localization:Bind(UI.ProgressText, "loading", "Text", function()
        return value and localizedValue(value) or Localization:Get("loading")
    end)
end
local function openLink(url, config)
    if type(url) ~= "string" or trim(url) == "" then
        Loader:Toast({ Type = "warning", Subtitle = Localization:Get("noLink") })
        return false
    end
    local copy = capability("setclipboard") or capability("toclipboard")
    local ok, returned = false, nil
    if copy then
        ok, returned = pcall(copy, url)
        ok = ok and returned ~= false
    end
    if ok then
        Loader:Toast({
            Type = "success",
            Icon = "link",
            Title = config and config.Title or Localization:Get("copied"),
            Subtitle = config and config.Subtitle or Localization:Get("keyCopied"),
        })
    elseif config and config.InlineFallback then
        Loader:Toast({ Type = "warning", Title = Localization:Get("noClipboard"), Subtitle = url })
    else
        Modal:Open({
            Type = "info",
            Title = Localization:Get("noClipboard"),
            Description = url,
            CopyText = url,
            ActionKey = "close",
            OnAction = function()
                Modal:Close()
            end,
        })
    end
    return ok == true
end
local function invokeHost(callback, ...)
    if type(callback) ~= "function" then
        return
    end
    local args = table.pack(...)
    -- Host work is not an animation task: destroying the frontend must not cancel Script() inside a host callback.
    task.defer(function()
        if not State.Alive then
            return
        end
        local ok = pcall(callback, table.unpack(args, 1, args.n))
        if not ok and State.Alive then
            Loader:Toast({
                Type = "error",
                Title = Localization:Get("invalid"),
                Subtitle = Localization:Get("genericError"),
            })
        end
    end)
end
local function diagnosticText()
    return string.format(
        "%s %s\nLanguage: %s\nUI: %s\nProduct: %s\nSession duration: %ss",
        Settings.Title,
        Settings.Version,
        Settings.Language,
        State.Name,
        State.SelectedProduct and State.SelectedProduct.Id or "none",
        tostring(Settings.Expiry)
    )
end
local function support()
    if State.Callbacks.Support then
        invokeHost(State.Callbacks.Support, Loader, diagnosticText())
        Modal:Close()
        return
    end
    if Settings.SupportLink ~= "" then
        Modal:Close()
        openLink(Settings.SupportLink)
        return
    end
    local details = diagnosticText()
    Modal:Open({
        Type = "info",
        Title = Localization:Get("supportTitle"),
        Description = Localization:Get("supportHelp"),
        CopyText = details,
        ActionKey = "copyDetails",
        OnAction = function()
            local copy = capability("setclipboard") or capability("toclipboard")
            if copy and pcall(copy, details) then
                Loader:Toast({ Type = "success", Title = Localization:Get("copied") })
                Modal:Close()
            else
                UI.ResultCopy:CaptureFocus()
            end
        end,
    })
end
local function buildModal()
    UI.Overlay = frame(UI.Stage, "Overlay")
    UI.Overlay.BackgroundTransparency = 1
    UI.Overlay.Size = UDim2.fromScale(1, 1)
    UI.Overlay.ZIndex = 20
    UI.Overlay.Visible = false
    UI.Backdrop = create("TextButton", {
        Name = "Backdrop",
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Active = true,
        Selectable = false,
    }, UI.Overlay)
    Runtime:Connect(UI.Backdrop.Activated, function()
        if (State.Modal == "result" or State.Modal == "licenses") and State.Activity == "Idle" then
            Modal:Close()
        end
    end)
    UI.Result = group(UI.Overlay, "ResultModal")
    UI.Result.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.Result.BackgroundTransparency = 0
    UI.Result.Active = true
    UI.Result.BackgroundColor3 = Theme.Surface
    UI.Result.ZIndex = 2
    UI.Result.Visible = false
    corner(UI.Result, 10)
    stroke(UI.Result, Theme.Accent, 3)
    UI.ResultScale = create("UIScale", { Scale = 1 }, UI.Result)
    UI.ResultSymbol = frame(UI.Result, "Symbol", Theme.Accent)
    corner(UI.ResultSymbol, 100)
    UI.ResultIcon = Icon.new(UI.ResultSymbol, "check", Theme.Surface, 24)
    UI.ResultTitle = label(UI.Result, "Title", "", 17, Theme.Text, Theme.Medium)
    UI.ResultTitle.TextXAlignment = Enum.TextXAlignment.Center
    UI.ResultTitle.TextWrapped = true
    UI.ResultTitle.TextTruncate = Enum.TextTruncate.AtEnd
    UI.ResultDescription = label(UI.Result, "Description", "", 13, Theme.Secondary)
    UI.ResultDescription.TextWrapped = true
    UI.ResultDescription.TextYAlignment = Enum.TextYAlignment.Top
    UI.ResultDescription.TextXAlignment = Enum.TextXAlignment.Center
    UI.ResultDescription.TextTruncate = Enum.TextTruncate.AtEnd
    UI.ResultCopy = create("TextBox", {
        Name = "SelectableDetails",
        Text = "",
        TextEditable = false,
        ClearTextOnFocus = false,
        MultiLine = true,
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.Secondary,
        BackgroundTransparency = 1,
        TextWrapped = true,
        ClipsDescendants = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Visible = false,
    }, UI.Result)
    UI.ResultDivider = frame(UI.Result, "Divider", Theme.Line)
    UI.ResultSupport = label(UI.Result, "Support", "", 12, Theme.Secondary)
    UI.ResultSupport.TextXAlignment = Enum.TextXAlignment.Center
    UI.ResultSupport.TextWrapped = true
    UI.ResultAction = Button.new(
        UI.Result,
        "Action",
        "",
        true,
        nil,
        function()
            local config = Modal.Config
            if not config or Modal.ActionBusy then
                return
            end
            Modal.ActionBusy = true
            UI.ResultAction:SetDisabled(true)
            if type(config.OnAction) == "function" then
                task.defer(function()
                    if not State.Alive or Modal.Config ~= config then
                        return
                    end
                    local ok = pcall(config.OnAction, Loader)
                    if State.Alive and Modal.Config == config then
                        Modal.ActionBusy = false
                        UI.ResultAction:SetDisabled(false)
                        if not ok then
                            Loader:Toast({ Type = "error", Subtitle = Localization:Get("genericError") })
                        end
                    end
                end)
            else
                support()
            end
        end,
        Runtime,
        function()
            return State.Alive and State.Visible and State.Modal == "result" and State.Activity == "Idle"
        end
    )
    UI.ResultLink = Button.new(
        UI.Result,
        "Website",
        Localization:Get("website"),
        false,
        nil,
        function()
            if Modal.Config and Modal.Config.Link then
                openLink(Modal.Config.Link)
            end
        end,
        Runtime,
        function()
            return State.Alive and State.Visible and State.Modal == "result"
        end
    )
    UI.ResultLink.Root.BackgroundTransparency = 1
    UI.ResultLink.Label.TextColor3 = Theme.Accent
    Localization:Bind(UI.ResultLink.Label, "website")
    UI.ResultClose = Button.new(
        UI.Result,
        "Close",
        "",
        false,
        "x",
        function()
            Modal:Close()
        end,
        Runtime,
        function()
            return State.Alive and State.Visible and State.Modal == "result" and State.Activity == "Idle"
        end
    )
    UI.ResultClose.Root.BackgroundTransparency = 1
    UI.ResultClose.Icon.Root.Position = UDim2.new(0.5, -9, 0.5, 0)
    UI.ProgressPanel = group(UI.Overlay, "ProgressModal")
    UI.ProgressPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.ProgressPanel.Active = true
    UI.ProgressPanel.BackgroundColor3 = Theme.Surface
    UI.ProgressPanel.BackgroundTransparency = 0
    UI.ProgressPanel.ZIndex = 2
    UI.ProgressPanel.Visible = false
    corner(UI.ProgressPanel, 9)
    stroke(UI.ProgressPanel, Theme.Accent, 3)
    UI.ProgressText = localized(UI.ProgressPanel, "Status", "loading", 14, Theme.Text, Theme.Medium)
    UI.ProgressText.TextTruncate = Enum.TextTruncate.AtEnd
    UI.ProgressPercent = label(UI.ProgressPanel, "Percentage", "0%", 14, Theme.Text, Theme.Medium)
    UI.ProgressCheck = Icon.new(UI.ProgressPanel, "check", Theme.Accent, 24)
    UI.ProgressCheck.Root.Visible = false
    UI.ProgressCheckScale = create("UIScale", { Scale = 1 }, UI.ProgressCheck.Root)
    UI.ProgressLicense = label(UI.ProgressPanel, "VerifiedLicense", "", 12, Theme.Secondary)
    UI.ProgressLicense.TextTruncate = Enum.TextTruncate.AtEnd
    UI.ProgressLicense.Visible = false
    UI.ProgressPercent.TextXAlignment = Enum.TextXAlignment.Right
    UI.ProgressTrack = frame(UI.ProgressPanel, "Track", Theme.Input)
    corner(UI.ProgressTrack, 3)
    UI.ProgressFill = frame(UI.ProgressTrack, "Fill", Theme.Accent)
    UI.ProgressFill.Size = UDim2.fromScale(0, 1)
    corner(UI.ProgressFill, 3)
    UI.ToastLayer = frame(UI.Stage, "Toasts")
    UI.ToastLayer.BackgroundTransparency = 1
    UI.ToastLayer.Size = UDim2.fromScale(1, 1)
    UI.ToastLayer.ZIndex = 40
end
local function flag(parent, language)
    local root = group(parent, "Flag")
    root.Size = UDim2.fromOffset(26, 26)
    root.ClipsDescendants = true
    root.BackgroundTransparency = 0
    root.BackgroundColor3 = Color3.fromRGB(28, 34, 62)
    corner(root, 100)
    if language == "ru" then
        for i, color in ipairs({
            Color3.fromRGB(240, 239, 243),
            Color3.fromRGB(42, 110, 205),
            Color3.fromRGB(216, 49, 77),
        }) do
            local stripe = frame(root, "Stripe", color)
            stripe.Position = UDim2.fromScale(0, (i - 1) / 3)
            stripe.Size = UDim2.fromScale(1, 1 / 3)
        end
    elseif language == "es" then
        root.BackgroundColor3 = Color3.fromRGB(191, 37, 48)
        local stripe = frame(root, "GoldBand", Color3.fromRGB(244, 195, 57))
        stripe.Position = UDim2.fromScale(0, 0.25)
        stripe.Size = UDim2.fromScale(1, 0.5)
        local crest = frame(root, "Crest", Color3.fromRGB(183, 46, 53))
        crest.Position = UDim2.fromScale(0.25, 0.39)
        crest.Size = UDim2.fromScale(0.13, 0.24)
        corner(crest, 1)
    elseif language == "pt" then
        root.BackgroundColor3 = Color3.fromRGB(194, 43, 51)
        local green = frame(root, "Green", Color3.fromRGB(37, 123, 78))
        green.Size = UDim2.fromScale(0.4, 1)
        local seal = frame(root, "Seal", Color3.fromRGB(230, 193, 66))
        seal.AnchorPoint = Vector2.new(0.5, 0.5)
        seal.Position = UDim2.fromScale(0.4, 0.5)
        seal.Size = UDim2.fromScale(0.3, 0.3)
        corner(seal, 100)
        local shield = frame(seal, "Shield", Color3.fromRGB(238, 235, 222))
        shield.Position = UDim2.fromScale(0.25, 0.2)
        shield.Size = UDim2.fromScale(0.5, 0.62)
        corner(shield, 1)
    else
        for _, rotation in ipairs({ 45, -45 }) do
            local white = frame(root, "Saltire", Theme.Text)
            white.AnchorPoint = Vector2.new(0.5, 0.5)
            white.Position = UDim2.fromScale(0.5, 0.5)
            white.Size = UDim2.fromScale(1.5, 0.22)
            white.Rotation = rotation
            local red = frame(white, "Red", Color3.fromRGB(214, 43, 71))
            red.AnchorPoint = Vector2.new(0.5, 0.5)
            red.Position = UDim2.fromScale(0.5, 0.5)
            red.Size = UDim2.fromScale(1, 0.38)
        end
        local cross = frame(root, "Horizontal", Theme.Text)
        cross.Position = UDim2.fromScale(0, 0.33)
        cross.Size = UDim2.fromScale(1, 0.34)
        local upright = frame(root, "Vertical", Theme.Text)
        upright.Position = UDim2.fromScale(0.33, 0)
        upright.Size = UDim2.fromScale(0.34, 1)
        local redH = frame(root, "RedH", Color3.fromRGB(214, 43, 71))
        redH.Position = UDim2.fromScale(0, 0.42)
        redH.Size = UDim2.fromScale(1, 0.16)
        local redV = frame(root, "RedV", Color3.fromRGB(214, 43, 71))
        redV.Position = UDim2.fromScale(0.42, 0)
        redV.Size = UDim2.fromScale(0.16, 1)
    end
    return root
end
local function updateFooter()
    Localization:Bind(UI.Copyright, "rights", "Text", function()
        local brand = State.TitleCustom and Settings.Title or Localization:Get("brand")
        return brand .. " © 2020 " .. Localization:Get("rights")
    end)
    UI.Version.Text = Settings.Version ~= "" and "v" .. Settings.Version or ""
end
LanguageController = { Open = false, Hovered = false, Pressed = false, Token = 0, ChevronParts = {} }
function LanguageController:Paint()
    if not UI.LanguageChevron then
        return
    end
    local color = self.Open and Theme.Accent or self.Hovered and Theme.Text or Theme.Secondary
    UI.LanguageToggle:SetAttribute("Expanded", self.Open)
    Animation:To(UI.LanguageChevron.Root, { Rotation = self.Open and 180 or 0 }, Motion.Hover)
    Animation:To(UI.LanguageChevronScale, { Scale = self.Pressed and 0.82 or self.Hovered and 1.08 or 1 }, Motion.Hover)
    for _, part in ipairs(self.ChevronParts) do
        Animation:To(part, { BackgroundColor3 = color }, Motion.Hover)
    end
    for id, button in pairs(UI.LanguageOptions or {}) do
        button.Selected = id == Settings.Language
        button.Root.Active = self.Open
        if not self.Open then
            button.Hovered = false
            button.Pressed = false
        end
        button.Root:SetAttribute("Selected", button.Selected)
        button.Check.Root.Visible = button.Selected
        button:Apply()
    end
end
function LanguageController:Layout(width, height, rail)
    local menuWidth = math.min(188, math.max(108, width - 16))
    local menuHeight = math.min(200, math.max(56, height - 16))
    local x = math.min(rail + 8, math.max(8, width - menuWidth - 8))
    local y = math.max(8, height - menuHeight - 12)
    self.Position = UDim2.fromOffset(x, y)
    Animation:CancelProperty(UI.LanguageMenu, "Position")
    UI.LanguageMenu.Position = self.Position
    UI.LanguageMenu.Size = UDim2.fromOffset(menuWidth, menuHeight)
    UI.LanguageList.Size = UDim2.fromScale(1, 1)
    UI.LanguageList.CanvasSize = UDim2.fromOffset(0, #Languages * 48 + 8)
    self.Scrollable = menuHeight < #Languages * 48 + 8
    UI.LanguageList.ScrollingEnabled = self.Open and self.Scrollable
    if not self.Scrollable then
        UI.LanguageList.CanvasPosition = Vector2.new(0, 0)
    end
    for index, language in ipairs(Languages) do
        local button = UI.LanguageOptions[language.Id]
        place(button.Root, 4, (index - 1) * 48 + 4, menuWidth - 8, 44)
        place(button.Check.Root, menuWidth - 32, 16, 12, 12)
    end
end
function LanguageController:SetOpen(value)
    value = value == true and canInteract()
    if self.Open == value then
        return
    end
    self.Open = value
    self.Pressed = false
    self.Token = self.Token + 1
    local token = self.Token
    if not State.Visible then
        self.Hovered = false
    end
    UI.LanguageList.Active = value
    UI.LanguageList.ScrollingEnabled = value and self.Scrollable == true
    self:Paint()
    if value then
        if not UI.LanguageMenu.Visible then
            UI.LanguageMenu.GroupTransparency = 1
            UI.LanguageMenu.Position = (self.Position or UDim2.new()) + UDim2.fromOffset(0, 8)
            UI.LanguageMenuScale.Scale = 0.965
        end
        UI.LanguageMenu.Visible = true
        UI.LanguageMenu.Active = true
        Animation:To(UI.LanguageMenuScale, { Scale = 1 }, Motion.Enter)
        Animation:To(UI.LanguageMenu, { Position = self.Position or UI.LanguageMenu.Position }, Motion.Enter)
        Animation:To(UI.LanguageMenu, { GroupTransparency = 0 }, Motion.Enter)
    else
        UI.LanguageMenu.Active = false
        Animation:To(UI.LanguageMenuScale, { Scale = 0.975 }, Motion.Exit)
        Animation:To(UI.LanguageMenu, {
            Position = (self.Position or UI.LanguageMenu.Position) + UDim2.fromOffset(0, 6),
        }, Motion.Exit)
        Animation:To(UI.LanguageMenu, { GroupTransparency = 1 }, Motion.Exit, function()
            if token == self.Token and not self.Open then
                UI.LanguageMenu.Visible = false
            end
        end)
    end
end
local function closeLanguage()
    LanguageController:SetOpen(false)
end
local function buildShell(parent)
    UI.Gui = create(
        "ScreenGui",
        { Name = "PlakUi", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 90 },
        parent
    )
    UI.Gui:SetAttribute("PlakUiOwned", true)
    pcall(function()
        UI.Gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
        UI.Gui.ClipToDeviceSafeArea = true
    end)
    UI.Stage = frame(UI.Gui, "SafeStage")
    UI.Stage.BackgroundTransparency = 1
    UI.Stage.Size = UDim2.fromScale(1, 1)
    UI.Window = group(UI.Stage, "Window")
    UI.Window.BackgroundTransparency = 0
    UI.Window.BackgroundColor3 = Theme.Surface
    UI.Window.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.Window.ClipsDescendants = true
    UI.Window.GroupTransparency = 1
    corner(UI.Window, 18)
    UI.Scale = create("UIScale", { Scale = 1 }, UI.Window)
    UI.Header = frame(UI.Window, "Header")
    UI.Header.BackgroundTransparency = 1
    UI.Header.Active = true
    UI.BrandLogo = Icon.new(UI.Header, "rosette", Theme.Accent, 28)
    UI.Brand = localized(UI.Header, "Brand", "brand", 14, Theme.Text, Theme.Medium)
    UI.Brand.TextTruncate = Enum.TextTruncate.AtEnd
    UI.User = label(UI.Header, "User", Settings.User, 13, Theme.Text, Theme.Medium)
    UI.User.TextXAlignment = Enum.TextXAlignment.Right
    UI.User.TextTruncate = Enum.TextTruncate.AtEnd
    UI.Avatar = Icon.new(UI.Header, "owl", Theme.Accent, 36)
    UI.Minimize = Button.new(
        UI.Header,
        "Minimize",
        "",
        false,
        "minimize",
        function()
            Loader:Hide()
        end,
        Runtime,
        function()
            return State.Alive and State.Visible
        end
    )
    UI.Minimize.Icon.Root.Position = UDim2.new(0.5, -9, 0.5, 0)
    Localization:Bind(UI.Minimize.Label, "minimize")
    UI.Minimize.Label.Visible = false
    -- A sibling of Window remains reachable when the full window (including its modal) is hidden.
    UI.RestoreDock = group(UI.Stage, "RestoreDock")
    UI.RestoreDock.Visible = false
    UI.RestoreDock.ZIndex = 25
    UI.RestoreDock.GroupTransparency = 1
    UI.Restore = Button.new(
        UI.RestoreDock,
        "RestoreLoader",
        "",
        false,
        "rosette",
        function()
            Loader:Show()
        end,
        Runtime,
        function()
            return State.Alive and not State.Visible
        end
    )
    UI.Restore.Root.Size = UDim2.fromScale(1, 1)
    corner(UI.Restore.Root, 14)
    stroke(UI.Restore.Root, Theme.Line, 1)
    UI.Restore.Icon.Root.Size = UDim2.fromOffset(28, 28)
    UI.Restore.Icon.Root.Position = UDim2.new(0.5, -14, 0.5, 0)
    UI.Restore.Icon:SetColor(Theme.Accent)
    Localization:Bind(UI.Restore.Label, "restore")
    UI.Restore.Label.Visible = false
    UI.UserAction = create(
        "TextButton",
        { Name = "UserAction", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Visible = false },
        UI.Header
    )
    Runtime:Connect(UI.UserAction.Activated, function()
        if canInteract() then
            invokeHost(State.Callbacks.User, Loader)
        end
    end)
    UI.Sidebar = frame(UI.Window, "Sidebar")
    UI.Sidebar.BackgroundTransparency = 1
    UI.ContextIcon = Icon.new(UI.Sidebar, "home", Theme.Muted, 18)
    UI.ActiveNav = frame(UI.Sidebar, "Active", Theme.AccentDark)
    UI.ActiveNav.BackgroundTransparency = 0.7
    corner(UI.ActiveNav, 100)
    UI.AuthNav = Button.new(UI.Sidebar, "Authorization", "", false, "home", function()
        Navigation:Go("Auth")
    end)
    UI.ProductsNav = Button.new(UI.Sidebar, "Products", "", false, "grid", function()
        Navigation:Go("Products")
    end)
    UI.RefreshNav = Button.new(UI.Sidebar, "Refresh", "", false, "refresh", function()
        if State.Callbacks.Refresh then
            invokeHost(State.Callbacks.Refresh, Loader)
        else
            Cards:Rebuild()
            Loader:Toast({ Type = "info", Title = Localization:Get("refreshed"), Duration = 2 })
        end
    end)
    for _, button in ipairs({ UI.AuthNav, UI.ProductsNav, UI.RefreshNav }) do
        button.Root.BackgroundTransparency = 1
        button.Icon.Root.Position = UDim2.new(0.5, -10, 0.5, 0)
        button.Icon:SetColor(Theme.Muted)
    end
    UI.ProductMark = frame(UI.Sidebar, "ProductMark", Theme.Accent)
    corner(UI.ProductMark, 100)
    UI.ProductMark.Visible = false
    local mark = Icon.new(UI.ProductMark, "play", Theme.Surface, 16)
    place(mark.Root, 8, 8, 16, 16)
    UI.Breadcrumb = label(UI.Window, "Breadcrumb", "", 12, Theme.Muted, Theme.Medium)
    UI.Social = {}
    for _, name in ipairs({ "discord", "send", "youtube" }) do
        local id = name == "send" and "telegram" or name
        local button = Button.new(UI.Window, "Social_" .. id, "", false, name, function()
            if State.Callbacks.Social then
                invokeHost(State.Callbacks.Social, id, Loader)
            elseif Settings.SocialLinks[id] then
                openLink(Settings.SocialLinks[id])
            end
        end)
        button.Root.Visible = false
        button.Root.BackgroundTransparency = 1
        button.Icon.Root.Position = UDim2.new(0.5, -8, 0.5, 0)
        button.Icon.Root.Size = UDim2.fromOffset(16, 16)
        button.Icon:SetColor(Theme.Muted)
        UI.Social[id] = button
    end
    UI.Pages = frame(UI.Window, "Pages")
    UI.Pages.BackgroundTransparency = 1
    UI.Pages.ClipsDescendants = true
    UI.Copyright = localized(UI.Window, "Copyright", "rights", 11, Theme.Muted)
    UI.Copyright.TextTruncate = Enum.TextTruncate.AtEnd
    UI.Version = label(UI.Window, "Version", "", 11, Theme.Muted)
    UI.Version.TextXAlignment = Enum.TextXAlignment.Right
    UI.Version.TextTruncate = Enum.TextTruncate.AtEnd
    UI.LanguageToggle = create(
        "TextButton",
        { Name = "Language", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Selectable = true },
        UI.Sidebar
    )
    UI.LanguageFlag = flag(UI.LanguageToggle, Settings.Language)
    UI.LanguageChevron = Icon.new(UI.LanguageToggle, "chevron", Theme.Secondary, 12)
    UI.LanguageChevronScale = create("UIScale", { Scale = 1 }, UI.LanguageChevron.Root)
    for _, part in ipairs(UI.LanguageChevron.Root:GetChildren()) do
        if part:IsA("Frame") then
            LanguageController.ChevronParts[#LanguageController.ChevronParts + 1] = part
        end
    end
    UI.LanguageMenu = group(UI.Window, "LanguageMenu")
    UI.LanguageMenu.BackgroundColor3 = Theme.Input
    UI.LanguageMenu.BackgroundTransparency = 0
    UI.LanguageMenu.ZIndex = 10
    UI.LanguageMenu.Visible = false
    UI.LanguageMenu.GroupTransparency = 1
    corner(UI.LanguageMenu, 10)
    stroke(UI.LanguageMenu, Theme.Line, 1)
    UI.LanguageMenuScale = create("UIScale", { Scale = 1 }, UI.LanguageMenu)
    UI.LanguageList = create("ScrollingFrame", {
        Name = "LanguageList",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.AccentDark,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.fromOffset(0, #Languages * 48 + 8),
        CanvasPosition = Vector2.new(0, 0),
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
    }, UI.LanguageMenu)
    UI.LanguageOptions = {}
    for _, descriptor in ipairs(Languages) do
        local language = descriptor.Id
        local button = Button.new(
            UI.LanguageList,
            "Language_" .. language,
            descriptor.Name,
            false,
            nil,
            function()
                closeLanguage()
                Loader:SetLanguage(language)
            end,
            nil,
            function()
                return canInteract() and LanguageController.Open
            end
        )
        local markFlag = flag(button.Root, language)
        place(markFlag, 10, 9, 26, 26)
        button.Check = Icon.new(button.Root, "check", Theme.Accent, 12)
        button.Label.Position = UDim2.fromOffset(44, 0)
        button.Label.Size = UDim2.new(1, -72, 1, 0)
        button.Label.TextXAlignment = Enum.TextXAlignment.Left
        function button:Apply()
            local base = self.Selected and Theme.Input:Lerp(Theme.Accent, 0.09) or Theme.Input
            local color = self.Pressed and base:Lerp(Theme.Accent, 0.12)
                or self.Hovered and base:Lerp(Theme.Text, 0.07)
                or base
            Animation:To(self.Root, { BackgroundColor3 = color }, Motion.Hover)
            Animation:To(self.Label, { TextColor3 = self.Selected and Theme.Accent or Theme.Text }, Motion.Hover)
            self.Root.Selectable = LanguageController.Open and not self.Disabled
        end
        UI.LanguageOptions[language] = button
    end
    Runtime:Connect(UI.LanguageToggle.Activated, function()
        if canInteract() then
            LanguageController:SetOpen(not LanguageController.Open)
        end
    end)
    Runtime:Connect(UI.LanguageToggle.MouseEnter, function()
        if canInteract() then
            LanguageController.Hovered = true
            LanguageController:Paint()
        end
    end)
    Runtime:Connect(UI.LanguageToggle.MouseLeave, function()
        LanguageController.Hovered = false
        LanguageController.Pressed = false
        LanguageController:Paint()
    end)
    Runtime:Connect(UI.LanguageToggle.SelectionGained, function()
        if canInteract() then
            LanguageController.Hovered = true
            LanguageController:Paint()
        end
    end)
    Runtime:Connect(UI.LanguageToggle.SelectionLost, function()
        LanguageController.Hovered = false
        LanguageController.Pressed = false
        LanguageController:Paint()
    end)
    Runtime:Connect(UI.LanguageToggle.InputBegan, function(input)
        if
            canInteract()
            and (
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            )
        then
            LanguageController.Pressed = true
            LanguageController:Paint()
        end
    end)
    Runtime:Connect(UI.LanguageToggle.InputEnded, function()
        if LanguageController.Pressed then
            LanguageController.Pressed = false
            LanguageController:Paint()
        end
    end)
    LanguageController:Paint()
    updateFooter()
end
local function classifyFailure(message)
    local text = message:lower()
    if
        text:find("expired", 1, true)
        or text:find("disabled", 1, true)
        or text:find("premium", 1, true)
        or text:find("access", 1, true)
        or text:find("истёк", 1, true)
        or text:find("отключ", 1, true)
    then
        return "disabled"
    end
    if
        text:find("request failed", 1, true)
        or text:find("timeout", 1, true)
        or text:find("connection", 1, true)
        or text:find("network", 1, true)
    then
        return "network"
    end
    if
        text:find("runtime is unavailable", 1, true)
        or text:find("not configured", 1, true)
        or text:find("requirekey is unavailable", 1, true)
    then
        return "service"
    end
    if text:find("invalid", 1, true) or text:find("incorrect", 1, true) then
        return "key"
    end
    return "error"
end
local AuthField = {}
function AuthField.Interactive()
    return canInteract() and State.Page == "Auth"
end
-- Community actions never authenticate, delay Script(), or claim membership.
-- Storefront presentation only. No purchase, entitlement or auth result is inferred here.
LicenseOffer = { RevealTasks = {}, Revealing = false }
function LicenseOffer:Enabled()
    return Settings.LicenseOfferEnabled and Settings.LicenseStoreLink ~= ""
end
function LicenseOffer:Interactive()
    return State.Alive and State.Visible and State.Modal == "licenses" and State.Activity == "Idle"
end
function LicenseOffer:CancelReveal()
    for _, thread in ipairs(self.RevealTasks) do
        Runtime:Cancel(thread)
    end
    table.clear(self.RevealTasks)
    self.Revealing = false
end
function LicenseOffer:Refresh()
    if UI.LicenseNav then
        UI.LicenseNav:SetDisabled(not self:Enabled() or State.Activity ~= "Idle")
        UI.LicenseNav.Root:SetAttribute("ActionLabel", Localization:Get("offerLicenses"))
        UI.LicenseInline:SetDisabled(not self:Enabled() or State.Activity ~= "Idle")
        UI.LicenseInline.Root.Visible = self:Enabled()
    end
    if not UI.LicensePanel then
        return
    end
    Localization:Bind(UI.LicenseStore.Label, "offerStore", "Text", function()
        return Settings.LicenseStoreLink:gsub("^https://", ""):gsub("/$", "")
    end)
    local copied = self.CopyTask ~= nil and self.CopiedLink == Settings.LicenseStoreLink
    for _, card in ipairs(UI.LicenseCards) do
        Localization:Bind(
            card.Buy.Label,
            copied and "offerCopied" or card.Primary and "offerChooseLifetime" or "offerChooseMonthly"
        )
        card.Buy:SetDisabled(copied or not self:Enabled())
    end
    UI.LicenseStore:SetDisabled(copied or not self:Enabled())
end
function LicenseOffer:Copy(plan)
    if not self:Interactive() or not self:Enabled() then
        return false, "unavailable"
    end
    if self.CopyTask and self.CopiedLink == Settings.LicenseStoreLink then
        return false, "cooldown"
    end
    local link = Settings.LicenseStoreLink
    local ok = openLink(link, {
        Title = Localization:Get("offerStoreCopied"),
        Subtitle = Localization:Get(
            plan == "lifetime" and "offerLifetimeCopy" or plan == "monthly" and "offerMonthlyCopy" or "offerStoreCopy"
        ),
    })
    if not ok then
        return false, "clipboard_unavailable"
    end
    self.CopiedLink = link
    Runtime:Cancel(self.CopyTask)
    self.CopyTask = Runtime:Later(2, function()
        self.CopyTask = nil
        self.CopiedLink = nil
        self:Refresh()
    end)
    self:Refresh()
    return true
end
function LicenseOffer:Paint(card, hovered)
    card.Hovered = hovered == true
    Animation:To(card.Border, { Transparency = hovered and 0.08 or card.Primary and 0.22 or 0.55 }, Motion.Hover)
    Animation:To(card.SealScale, { Scale = hovered and 1.04 or 1 }, Motion.Hover)
end
function LicenseOffer:BuildMark(parent)
    local root = frame(parent, "PlakGeometry")
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromOffset(114, 30)
    for index, name in ipairs({ "P", "L", "A", "K" }) do
        for _, data in ipairs(BrandArt.Glyphs[name]) do
            local part = frame(root, "Glyph" .. name, Theme.Accent)
            local x = (index - 1) * 30
            if data[6] then
                local dx, dy = data[3] - data[1], data[4] - data[2]
                part.AnchorPoint = Vector2.new(0.5, 0.5)
                part.Position = UDim2.fromOffset(x + (data[1] + data[3]) * 0.105, (data[2] + data[4]) * 0.105)
                part.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) * 0.21, data[5] * 0.21)
                part.Rotation = math.deg(math.atan2(dy, dx))
            else
                place(part, x + data[1] * 0.21, data[2] * 0.21, data[3] * 0.21, data[4] * 0.21)
            end
        end
    end
    return root
end
function LicenseOffer:BuildCard(primary)
    local card = { Primary = primary }
    card.Root = group(UI.LicenseBody, primary and "Lifetime" or "Monthly")
    card.Root.BackgroundTransparency = 0
    card.Root.ClipsDescendants = true
    corner(card.Root, 12)
    gradient(card.Root, primary and Color3.fromRGB(47, 21, 32) or Theme.Elevated, Color3.fromRGB(18, 17, 22), 35)
    card.Border = stroke(card.Root, primary and Theme.Accent or Theme.Line, 1, primary and 0.22 or 0.55)
    card.Scale = create("UIScale", { Scale = 1 }, card.Root)
    card.Badge = frame(card.Root, "PaymentBadge", Theme.AccentDark)
    corner(card.Badge, 7)
    card.Badge.Visible = primary
    card.BadgeLabel = localized(card.Badge, "Payment", "offerOneTime", 11, Theme.Text, Theme.Medium)
    card.BadgeLabel.TextXAlignment = Enum.TextXAlignment.Center
    card.BadgeLabel.TextTruncate = Enum.TextTruncate.AtEnd
    card.Title = label(card.Root, "Plan", primary and "LIFETIME" or "MONTHLY", 28, Theme.Text, Theme.Bold)
    card.Price =
        label(card.Root, "Price", primary and "$12" or "$5", 82, primary and Theme.Accent or Theme.Text, Theme.Bold)
    card.Currency =
        localized(card.Root, "Currency", primary and "offerUSD" or "offerPerMonth", 14, Theme.Secondary, Theme.Medium)
    card.Currency.TextTruncate = Enum.TextTruncate.AtEnd
    card.Term =
        localized(card.Root, "LicenseTerm", primary and "offerLifetimeTerm" or "offerMonthlyTerm", 13, Theme.Secondary)
    card.Term.TextTruncate = Enum.TextTruncate.AtEnd
    card.Seal = Icon.new(card.Root, "key", primary and Theme.AccentDark or Theme.Muted, 72)
    card.SealScale = create("UIScale", { Scale = 1 }, card.Seal.Root)
    card.Buy = Button.new(
        card.Root,
        "Choose",
        "",
        primary,
        nil,
        function()
            self:Copy(primary and "lifetime" or "monthly")
        end,
        Runtime,
        function()
            return self:Interactive()
        end
    )
    if not primary then
        card.Buy.BaseColor = Theme.Inactive
        card.Buy:Apply()
    end
    Runtime:Connect(card.Root.MouseEnter, function()
        if self:Interactive() then
            self:Paint(card, true)
        end
    end)
    Runtime:Connect(card.Root.MouseLeave, function()
        self:Paint(card, false)
    end)
    return card
end
function LicenseOffer:Build()
    if UI.LicensePanel then
        return
    end
    local function allowed()
        return self:Interactive()
    end
    UI.LicensePanel = group(UI.Overlay, "LicenseOffers")
    UI.LicensePanel.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.LicensePanel.BackgroundTransparency = 0
    UI.LicensePanel.BackgroundColor3 = Theme.Surface
    UI.LicensePanel.Active = true
    UI.LicensePanel.ZIndex = 2
    UI.LicensePanel.Visible = false
    UI.LicensePanel.ClipsDescendants = true
    corner(UI.LicensePanel, 14)
    stroke(UI.LicensePanel, Theme.Line, 1, 0.15)
    UI.LicenseScale = create("UIScale", { Scale = 1 }, UI.LicensePanel)
    UI.LicenseMark = self:BuildMark(UI.LicensePanel)
    UI.LicenseTag = localized(UI.LicensePanel, "Category", "offerLicenses", 12, Theme.Secondary, Theme.Medium)
    UI.LicenseDivider = frame(UI.LicensePanel, "HeaderDivider", Theme.Line)
    UI.LicenseClose = Button.new(UI.LicensePanel, "Close", "", false, "x", function()
        Modal:Close()
    end, Runtime, allowed)
    UI.LicenseClose.Root.BackgroundTransparency = 1
    UI.LicenseClose.Label.Visible = false
    UI.LicenseClose.Root:SetAttribute("ActionLabel", Localization:Get("close"))
    UI.LicenseScroll = create("ScrollingFrame", {
        Name = "OfferContent",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.AccentDark,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        VerticalScrollBarInset = Enum.ScrollBarInset.None,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
    }, UI.LicensePanel)
    UI.LicenseBody = frame(UI.LicenseScroll, "Body")
    UI.LicenseBody.BackgroundTransparency = 1
    UI.LicenseHeroA = localized(UI.LicenseBody, "HeroA", "offerHeroA", 40, Theme.Text, Theme.Bold)
    UI.LicenseHeroB = localized(UI.LicenseBody, "HeroB", "offerHeroB", 40, Theme.Accent, Theme.Bold)
    UI.LicenseSubhead = localized(UI.LicenseBody, "Subhead", "offerSubhead", 14, Theme.Secondary)
    UI.LicenseHeroA.TextTruncate = Enum.TextTruncate.AtEnd
    UI.LicenseHeroB.TextTruncate = Enum.TextTruncate.AtEnd
    UI.LicenseSubhead.TextWrapped = true
    UI.LicenseSubhead.TextTruncate = Enum.TextTruncate.AtEnd
    UI.LicenseJumpLife = Button.new(UI.LicenseBody, "LifetimeShortcut", "Lifetime · $12", false, nil, function()
        UI.LicenseScroll.CanvasPosition = Vector2.new(0, math.max(0, UI.LicenseCards[1].Rest.Y.Offset - 8))
    end, Runtime, allowed)
    UI.LicenseJumpMonth = Button.new(UI.LicenseBody, "MonthlyShortcut", "Monthly · $5", false, nil, function()
        UI.LicenseScroll.CanvasPosition = Vector2.new(0, math.max(0, UI.LicenseCards[2].Rest.Y.Offset - 8))
    end, Runtime, allowed)
    Localization:Bind(UI.LicenseJumpLife.Label, "offerJumpLifetime")
    Localization:Bind(UI.LicenseJumpMonth.Label, "offerJumpMonthly")
    UI.LicenseCards = { self:BuildCard(true), self:BuildCard(false) }
    UI.LicenseTerms = localized(UI.LicenseBody, "Terms", "offerTerms", 12, Theme.Secondary)
    UI.LicenseTerms.TextWrapped = true
    UI.LicenseTerms.TextTruncate = Enum.TextTruncate.AtEnd
    UI.LicenseTerms.TextXAlignment = Enum.TextXAlignment.Center
    UI.LicenseStore = Button.new(UI.LicensePanel, "Storefront", "", false, "link", function()
        self:Copy()
    end, Runtime, allowed)
    UI.LicenseStore.BaseColor = Theme.Surface
    UI.LicenseStore:Apply()
    UI.LicenseNotNow = Button.new(UI.LicensePanel, "NotNow", "", false, nil, function()
        Modal:Close()
    end, Runtime, allowed)
    UI.LicenseNotNow.Root.BackgroundTransparency = 1
    Localization:Bind(UI.LicenseNotNow.Label, "offerNotNow")
    self:Refresh()
end
function LicenseOffer:Layout(settle)
    if not UI.LicensePanel then
        return
    end
    if settle then
        self:CancelReveal()
        Animation:CancelProperty(UI.LicensePanel, "Position")
        Animation:CancelProperty(UI.LicenseScale, "Scale")
        UI.LicensePanel.GroupTransparency = 0
        UI.LicenseScale.Scale = 1
    end
    local safe = UI.Stage.AbsoluteSize
    local width = math.max(160, math.min(920, safe.X - 24))
    local height = math.max(180, math.min(640, safe.Y - 24))
    local inner = width - 40
    local stacked = width < 650
    local compact = width < 420
    local footer = compact and 112 or 68
    local viewportHeight = math.max(40, height - 72 - footer - 12)
    UI.LicensePanel.Size = UDim2.fromOffset(width, height)
    UI.LicensePanel.Position = UDim2.fromOffset(safe.X / 2, safe.Y / 2)
    place(UI.LicenseMark, 20, 20, 114, 30)
    place(UI.LicenseTag, 160, 22, math.max(1, width - 230), 28)
    UI.LicenseTag.Visible = width >= 420
    place(UI.LicenseClose.Root, width - 56, 12, 44, 44)
    place(UI.LicenseDivider, 0, 65, width, 1)
    place(UI.LicenseScroll, 20, 74, inner, viewportHeight)
    local font = math.clamp(math.floor(inner / 16), 22, 40)
    UI.LicenseHeroA.TextSize, UI.LicenseHeroB.TextSize = font, font
    local heroHeight = font + 10
    local first = TextMetrics:Get(Localization:Get("offerHeroA"), font, Theme.Bold, 10000)
    local second = TextMetrics:Get(Localization:Get("offerHeroB"), font, Theme.Bold, 10000)
    local oneLine = first and second and first.X + second.X + 14 <= inner
    if oneLine then
        local left = math.max(0, (inner - first.X - second.X - 14) / 2)
        place(UI.LicenseHeroA, left, 0, first.X + 2, heroHeight)
        place(UI.LicenseHeroB, left + first.X + 14, 0, second.X + 2, heroHeight)
    else
        place(UI.LicenseHeroA, 0, 0, inner, heroHeight)
        place(UI.LicenseHeroB, 0, heroHeight, inner, heroHeight)
    end
    local subtitleY = oneLine and heroHeight + 8 or heroHeight * 2 + 6
    place(UI.LicenseSubhead, 0, subtitleY, inner, 38)
    UI.LicenseSubhead.TextXAlignment = Enum.TextXAlignment.Center
    UI.LicenseHeroA.TextXAlignment = oneLine and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
    UI.LicenseHeroB.TextXAlignment = UI.LicenseHeroA.TextXAlignment
    UI.LicenseJumpLife.Root.Visible, UI.LicenseJumpMonth.Root.Visible = stacked, stacked
    local cardsY = subtitleY + 54
    if stacked then
        local half = (inner - 8) / 2
        place(UI.LicenseJumpLife.Root, 0, cardsY, half, 44)
        place(UI.LicenseJumpMonth.Root, half + 8, cardsY, half, 44)
        cardsY = cardsY + 56
    end
    local cardHeight = stacked and 320 or 330
    local gap = 16
    local lifeWidth = stacked and inner or math.floor((inner - gap) * 0.57)
    local monthlyWidth = stacked and inner or inner - gap - lifeWidth
    for index, card in ipairs(UI.LicenseCards) do
        local cardWidth = index == 1 and lifeWidth or monthlyWidth
        local x = (index == 1 or stacked) and 0 or lifeWidth + gap
        local y = stacked and cardsY + (index - 1) * (cardHeight + gap) or cardsY
        card.Rest = UDim2.fromOffset(x, y)
        if settle then
            Animation:CancelProperty(card.Root, "Position")
            Animation:CancelProperty(card.Root, "GroupTransparency")
            Animation:CancelProperty(card.Scale, "Scale")
        end
        card.Root.Position = card.Rest
        card.Root.Size = UDim2.fromOffset(cardWidth, cardHeight)
        card.Root.GroupTransparency = settle and 0 or card.Root.GroupTransparency
        card.Scale.Scale = settle and 1 or card.Scale.Scale
        local small = cardWidth < 280
        local priceSize = small and 62 or stacked and 72 or 82
        card.Price.TextSize = priceSize
        card.Title.TextSize = small and 24 or 28
        place(card.Badge, 20, 18, math.min(164, cardWidth - 40), 26)
        place(card.BadgeLabel, 8, 0, math.max(1, card.Badge.Size.X.Offset - 16), 26)
        place(card.Title, 20, 58, cardWidth - 40, 40)
        place(card.Price, 20, 101, cardWidth - 40, priceSize + 12)
        local currencyY = 101 + priceSize + 16
        place(card.Currency, 22, currencyY, cardWidth - 44, 24)
        place(card.Term, 22, currencyY + 28, cardWidth - 44, 24)
        card.Seal.Root.Visible = cardWidth >= 280
        place(card.Seal.Root, cardWidth - 94, 105, 64, 64)
        place(card.Buy.Root, 20, cardHeight - 64, cardWidth - 40, 44)
        self:Paint(card, card.Hovered)
    end
    local notesY = cardsY + (stacked and cardHeight * 2 + gap or cardHeight) + 16
    place(UI.LicenseTerms, 0, notesY, inner, 42)
    local canvasHeight = notesY + 50
    UI.LicenseBody.Size = UDim2.fromOffset(inner, canvasHeight)
    UI.LicenseScroll.CanvasSize = UDim2.fromOffset(0, canvasHeight)
    UI.LicenseScroll.ScrollingEnabled = canvasHeight > viewportHeight
    if compact then
        place(UI.LicenseStore.Root, 20, height - 106, inner, 44)
        place(UI.LicenseNotNow.Root, 20, height - 56, inner, 44)
    else
        place(UI.LicenseStore.Root, 20, height - 56, math.max(1, inner - 124), 44)
        place(UI.LicenseNotNow.Root, width - 132, height - 56, 112, 44)
    end
end
function LicenseOffer:Open()
    if not State.Alive or not State.Visible or State.Activity ~= "Idle" or not self:Enabled() then
        return false, "unavailable"
    end
    if State.Modal == "licenses" then
        return true
    end
    Modal:Close(true)
    UI.Key:ReleaseFocus(false)
    closeLanguage()
    self:Build() -- Lazy: never construct pricing cards on the cold auth path.
    self:CancelReveal()
    State.ModalToken = State.ModalToken + 1
    local generation = State.ModalToken
    State.Modal = "licenses"
    Modal.Config = nil
    reconcile()
    UI.Overlay.Visible = true
    UI.Result.Visible, UI.ProgressPanel.Visible = false, false
    UI.LicensePanel.Visible = true
    self:Layout(false)
    self:Refresh()
    UI.LicensePanel.GroupTransparency = Settings.ReducedMotion and 0 or 1
    UI.LicenseScale.Scale = Settings.ReducedMotion and 1 or 0.97
    local destination = UI.LicensePanel.Position
    UI.LicensePanel.Position = destination + UDim2.fromOffset(0, Settings.ReducedMotion and 0 or 18)
    Animation:To(UI.Backdrop, { BackgroundTransparency = 0.48 }, Motion.Enter)
    Animation:To(UI.LicensePanel, { GroupTransparency = 0, Position = destination }, Motion.Enter)
    Animation:To(UI.LicenseScale, { Scale = 1 }, Motion.Enter)
    UI.LicenseScroll.CanvasPosition = Vector2.new(0, 0)
    for index, card in ipairs(UI.LicenseCards) do
        card.Root.GroupTransparency = Settings.ReducedMotion and 0 or 1
        card.Root.Position = card.Rest + UDim2.fromOffset(0, Settings.ReducedMotion and 0 or 10)
        card.Scale.Scale = Settings.ReducedMotion and 1 or 0.985
        local thread = Runtime:Later(Settings.ReducedMotion and 0 or 0.035 * index, function()
            if State.Modal == "licenses" and generation == State.ModalToken then
                Animation:To(card.Root, { GroupTransparency = 0, Position = card.Rest }, Motion.Enter)
                Animation:To(card.Scale, { Scale = 1 }, Motion.Enter)
            end
        end)
        self.RevealTasks[#self.RevealTasks + 1] = thread
    end
    return true
end
function LicenseOffer:BuildTriggers()
    UI.LicenseNav = Button.new(UI.Sidebar, "Licenses", "", false, "key", function()
        self:Open()
    end)
    UI.LicenseNav.Root.BackgroundTransparency = 1
    UI.LicenseNav.Label.Visible = false
    UI.LicenseNav.Icon.Root.Position = UDim2.new(0.5, -10, 0.5, 0)
    UI.LicenseNav.Icon:SetColor(Theme.Accent)
    UI.LicenseInline = Button.new(UI.AuthBody, "LicenseKeys", "", false, "key", function()
        self:Open()
    end, Runtime, AuthField.Interactive)
    UI.LicenseInline.BaseColor = Theme.Surface
    UI.LicenseInline:Apply()
    UI.LicenseInline.Icon:SetColor(Theme.Accent)
    Localization:Bind(UI.LicenseInline.Label, "offerView")
    self:Refresh()
end

Community = { Generation = 0, CardHeight = 300, CardRevealed = false, DockRevealed = false }
function Community:Link()
    local link = Settings.SocialLinks.discord
    return type(link) == "string" and #link <= 2048 and link:match("^https?://") and link or ""
end
function Community:Enabled()
    return Settings.CommunityEnabled and not Settings.CommunityDismissed and self:Link() ~= ""
end
function Community:Interactive()
    return State.Alive
        and State.Visible
        and State.Page == "Auth"
        and not State.Modal
        and State.Activity ~= "Completing"
        and not self.Hiding
end
function Community:Refresh()
    if not UI.CommunityCard then
        return
    end
    local copied = self.CopyThread ~= nil and self.CopiedLink == self:Link()
    Localization:Bind(UI.CommunityJoin.Label, copied and "communityCopied" or "communityJoin")
    Localization:Bind(UI.CommunityDockJoin.Label, copied and "communityCopied" or "communityJoinShort")
    Localization:Bind(UI.CommunityRestore.Label, Settings.CommunityDismissed and "communityRestore" or "communityHide")
    for _, button in ipairs({ UI.CommunityJoin, UI.CommunitySupport, UI.CommunitySuggest, UI.CommunityDockJoin }) do
        button:SetDisabled(copied or self:Link() == "")
    end
    UI.CommunityRestore:SetDisabled(State.Activity ~= "Idle" or not Settings.CommunityEnabled or self:Link() == "")
    UI.CommunityClose.Root:SetAttribute("ActionLabel", Localization:Get("communityDismiss"))
    UI.CommunityDockClose.Root:SetAttribute("ActionLabel", Localization:Get("communityDismiss"))
    UI.CommunityOpen.Root:SetAttribute("ActionLabel", Localization:Get("communityDetails"))
end
function Community:Copy(kind)
    if not self:Interactive() or not self:Enabled() then
        return false, "unavailable"
    end
    local link = self:Link()
    if self.CopyThread and self.CopiedLink == link then
        return false, "cooldown"
    end
    local copied = openLink(link, {
        Title = Localization:Get("communityInviteCopied"),
        Subtitle = Localization:Get(
            kind == "support" and "communitySupportCopy"
                or kind == "suggest" and "communitySuggestCopy"
                or "communityJoinCopy"
        ),
        -- A pending authentication must never be covered by an unclosable modal.
        InlineFallback = State.Activity ~= "Idle",
    })
    if not copied then
        return false, "clipboard_unavailable"
    end
    self.CopiedLink = link
    Runtime:Cancel(self.CopyThread)
    self.CopyThread = Runtime:Later(2, function()
        self.CopyThread = nil
        self.CopiedLink = nil
        self:Refresh()
    end)
    self:Refresh()
    return true
end
function Community:Paint(hovered)
    if UI.CommunityBorder then
        Animation:To(UI.CommunityBorder, { Transparency = hovered and 0.28 or 0.58 }, Motion.Hover)
        Animation:To(UI.CommunityAvatarScale, { Scale = hovered and 1.04 or 1 }, Motion.Hover)
    end
end
function Community:RevealCard()
    if not self:Enabled() or not self:Interactive() or self.CardRevealed or not State.Layout.Height then
        return
    end
    local scrollY = UI.AuthScroll.CanvasPosition.Y
    local y = UI.CommunityCard.Position.Y.Offset
    if y > scrollY + UI.AuthScroll.AbsoluteSize.Y or y + self.CardHeight < scrollY then
        return
    end
    self.CardRevealed = true
    UI.CommunityCard.GroupTransparency = Settings.ReducedMotion and 0 or 1
    UI.CommunityScale.Scale = Settings.ReducedMotion and 1 or 0.97
    Animation:To(UI.CommunityCard, { GroupTransparency = 0 }, Motion.Enter)
    Animation:To(UI.CommunityScale, { Scale = 1 }, Motion.Enter)
end
function Community:Open()
    if not self:Interactive() or not self:Enabled() then
        return false
    end
    UI.Key:ReleaseFocus(false)
    UI.AuthScroll.CanvasPosition = Vector2.new(0, math.max(0, UI.CommunityCard.Position.Y.Offset - 12))
    self:RevealCard()
    return true
end
function Community:Dismiss()
    if not self:Interactive() or not self:Enabled() then
        return false
    end
    Settings.CommunityDismissed = true
    self.Hiding = true
    self.Generation = self.Generation + 1
    local generation = self.Generation
    Experience:PreferenceChanged()
    self:Refresh()
    Animation:To(UI.CommunityDockScale, { Scale = 0.94 }, Motion.Exit)
    Animation:To(UI.CommunityCard, { GroupTransparency = 1 }, Motion.Exit, function()
        if generation == self.Generation then
            self.Hiding = false
            Responsive:Update()
        end
    end)
    return true
end
function Community:Restore()
    if not State.Alive then
        return
    end
    self.Generation = self.Generation + 1
    self.Hiding = false
    self.CardRevealed = false
    self.DockRevealed = false
    Animation:CancelTree(UI.CommunityCard)
    Animation:CancelTree(UI.CommunityDock)
    Settings.CommunityDismissed = false
    Experience:PreferenceChanged()
    self:Refresh()
    Responsive:Update()
end
function Community:DockHeight(width, height)
    return (self:Enabled() or self.Hiding) and State.Page == "Auth" and width >= 180 and height >= 350 and 64 or 0
end
function Community:Height()
    return (self:Enabled() or self.Hiding) and (self.CardHeight + 12) or 0
end
function Community:Measure(width)
    if self.MeasuredWidth == width and self.MeasuredLanguage == Settings.Language then
        return
    end
    self.MeasuredWidth, self.MeasuredLanguage = width, Settings.Language
    local inner = math.max(1, width - 32)
    self.IntroHeight = math.clamp(measure(Localization:Get("communityIntro"), 12, Theme.Font, inner), 30, 62)
    self.NewsHeights = self.NewsHeights or {}
    local joinY = 63 + self.IntroHeight + 16 + 27
    for index, key in ipairs({ "communityNewsAuth", "communityNewsPrefs", "communityNewsGame" }) do
        local rowHeight = math.clamp(measure(Localization:Get(key), 12, Theme.Font, inner - 14), 20, 48)
        self.NewsHeights[index] = rowHeight
        joinY = joinY + rowHeight + 5
    end
    self.CardHeight = joinY + 8 + 137
end
function Community:Layout(width, y)
    local enabled = self:Enabled() or self.Hiding
    UI.CommunityCard.Visible = enabled
    if not enabled then
        return
    end
    self:Measure(width)
    local compact = width < 260
    Localization:Bind(UI.CommunityTitle, compact and "communityDockTitle" or "communityTitle")
    UI.CommunityAvatar.Visible = not compact
    place(UI.CommunityAvatar, 16, 16, 36, 36)
    place(UI.CommunityDiscord.Root, 6, 6, 24, 24)
    place(UI.CommunityClose.Root, width - 52, 8, 44, 44)
    place(UI.CommunityTitle, compact and 16 or 66, 16, math.max(1, width - (compact and 72 or 122)), 40)
    local inner = math.max(1, width - 32)
    local introHeight = self.IntroHeight
    place(UI.CommunityIntro, 16, 63, inner, introHeight)
    local newsY = 63 + introHeight + 16
    place(UI.CommunityRule, 16, newsY - 7, inner, 1)
    place(UI.CommunityNewsHeading, 16, newsY, inner, 22)
    newsY = newsY + 27
    for index, key in ipairs({ "communityNewsAuth", "communityNewsPrefs", "communityNewsGame" }) do
        local rowHeight = self.NewsHeights[index]
        place(UI.CommunityNewsDots[index], 16, newsY + 7, 4, 4)
        place(UI.CommunityNews[index], 30, newsY, inner - 14, rowHeight)
        newsY = newsY + rowHeight + 5
    end
    local joinY = newsY + 8
    place(UI.CommunityJoin.Root, 16, joinY, inner, 44)
    local half = (inner - 8) / 2
    place(UI.CommunitySupport.Root, 16, joinY + 52, half, 44)
    place(UI.CommunitySuggest.Root, 24 + half, joinY + 52, half, 44)
    place(UI.CommunityOptional, 16, joinY + 103, inner, 22)
    self.CardHeight = joinY + 137
    place(UI.CommunityCard, 0, y, width, self.CardHeight)
    self:RevealCard()
end
function Community:LayoutDock(x, y, width, height)
    local show = self:DockHeight(width, height) > 0
        and State.Visible
        and not State.Modal
        and State.Activity ~= "Completing"
    UI.CommunityDock.Visible = show
    if not show then
        return
    end
    place(UI.CommunityDock, x, y, width, 54)
    local compact = width < 300
    UI.CommunityDockIcon.Root.Visible = not compact
    UI.CommunityDockSubtitle.Visible = not compact
    place(UI.CommunityDockIcon.Root, 14, 15, 24, 24)
    local start = compact and 12 or 48
    place(UI.CommunityDockTitle, start, compact and 15 or 6, math.max(1, width - start - 132), 24)
    place(UI.CommunityDockSubtitle, start, 29, math.max(1, width - start - 132), 18)
    place(UI.CommunityOpen.Root, 0, 0, math.max(1, width - 128), 54)
    place(UI.CommunityDockJoin.Root, width - 124, 5, 72, 44)
    place(UI.CommunityDockClose.Root, width - 48, 5, 44, 44)
    if not self.DockRevealed then
        self.DockRevealed = true
        UI.CommunityDockScale.Scale = Settings.ReducedMotion and 1 or 0.96
        Animation:To(UI.CommunityDockScale, { Scale = 1 }, Motion.Enter)
    end
end
function Community:Build()
    local function allowed()
        return self:Interactive()
    end
    local function secondary(parent, name, key, callback, icon)
        local button = Button.new(parent, name, "", false, icon, callback, Runtime, allowed)
        button.BaseColor = Theme.Surface
        button:Apply()
        if key ~= "empty" then
            Localization:Bind(button.Label, key)
        end
        return button
    end
    UI.CommunityCard = group(UI.AuthBody, "PlakCommunity")
    UI.CommunityCard.BackgroundTransparency = 0
    UI.CommunityCard.BackgroundColor3 = Theme.Input
    UI.CommunityCard.GroupTransparency = 1
    UI.CommunityCard.ClipsDescendants = true
    corner(UI.CommunityCard, 12)
    UI.CommunityBorder = stroke(UI.CommunityCard, Theme.AccentDark, 1, 0.58)
    UI.CommunityScale = create("UIScale", { Scale = 1 }, UI.CommunityCard)
    UI.CommunityAvatar = frame(UI.CommunityCard, "DiscordMark", Theme.AccentDark)
    corner(UI.CommunityAvatar, 10)
    gradient(UI.CommunityAvatar, Theme.AccentDark, Color3.fromRGB(55, 27, 41), 65)
    UI.CommunityAvatarScale = create("UIScale", { Scale = 1 }, UI.CommunityAvatar)
    UI.CommunityDiscord = Icon.new(UI.CommunityAvatar, "discord", Theme.Text, 24)
    UI.CommunityTitle = localized(UI.CommunityCard, "Title", "communityTitle", 15, Theme.Text, Theme.Bold)
    UI.CommunityTitle.TextWrapped = true
    UI.CommunityTitle.TextTruncate = Enum.TextTruncate.AtEnd
    UI.CommunityIntro = localized(UI.CommunityCard, "Intro", "communityIntro", 12, Theme.Secondary)
    UI.CommunityIntro.TextWrapped = true
    UI.CommunityIntro.TextYAlignment = Enum.TextYAlignment.Top
    UI.CommunityIntro.TextTruncate = Enum.TextTruncate.AtEnd
    UI.CommunityClose = secondary(UI.CommunityCard, "Dismiss", "empty", function()
        self:Dismiss()
    end, "x")
    UI.CommunityClose.Label.Visible = false
    UI.CommunityClose.Root.BackgroundTransparency = 1
    UI.CommunityRule = frame(UI.CommunityCard, "Rule", Theme.Line)
    UI.CommunityNewsHeading =
        localized(UI.CommunityCard, "ReleaseHeading", "communityNews", 12, Theme.Text, Theme.Medium)
    UI.CommunityNews, UI.CommunityNewsDots = {}, {}
    for index, key in ipairs({ "communityNewsAuth", "communityNewsPrefs", "communityNewsGame" }) do
        UI.CommunityNews[index] = localized(UI.CommunityCard, "Release" .. index, key, 12, Theme.Secondary)
        UI.CommunityNews[index].TextWrapped = true
        UI.CommunityNews[index].TextYAlignment = Enum.TextYAlignment.Top
        UI.CommunityNews[index].TextTruncate = Enum.TextTruncate.AtEnd
        UI.CommunityNewsDots[index] = frame(UI.CommunityCard, "Dot" .. index, Theme.Accent)
        corner(UI.CommunityNewsDots[index], 4)
    end
    UI.CommunityJoin = Button.new(UI.CommunityCard, "JoinDiscord", "", true, nil, function()
        self:Copy("join")
    end, Runtime, allowed)
    UI.CommunitySupport = secondary(UI.CommunityCard, "CommunitySupport", "communitySupport", function()
        self:Copy("support")
    end)
    UI.CommunitySuggest = secondary(UI.CommunityCard, "SuggestGame", "communitySuggest", function()
        self:Copy("suggest")
    end)
    UI.CommunityOptional = localized(UI.CommunityCard, "Optional", "communityOptional", 12, Theme.Secondary)
    UI.CommunityOptional.TextXAlignment = Enum.TextXAlignment.Center
    UI.CommunityDock = frame(UI.Window, "CommunityDock", Theme.Input)
    UI.CommunityDock.ClipsDescendants = true
    corner(UI.CommunityDock, 10)
    stroke(UI.CommunityDock, Theme.AccentDark, 1, 0.65)
    UI.CommunityDockScale = create("UIScale", { Scale = 1 }, UI.CommunityDock)
    UI.CommunityDockIcon = Icon.new(UI.CommunityDock, "discord", Theme.Accent, 24)
    UI.CommunityDockTitle = localized(UI.CommunityDock, "Title", "communityDockTitle", 13, Theme.Text, Theme.Medium)
    UI.CommunityDockTitle.TextTruncate = Enum.TextTruncate.AtEnd
    UI.CommunityDockSubtitle = localized(UI.CommunityDock, "Subtitle", "communityDockSubtitle", 12, Theme.Secondary)
    UI.CommunityDockSubtitle.TextTruncate = Enum.TextTruncate.AtEnd
    UI.CommunityOpen = secondary(UI.CommunityDock, "Details", "empty", function()
        self:Open()
    end)
    UI.CommunityOpen.Root.BackgroundTransparency = 1
    UI.CommunityOpen.Label.Visible = false
    UI.CommunityDockJoin = Button.new(UI.CommunityDock, "JoinDiscord", "", true, nil, function()
        self:Copy("join")
    end, Runtime, allowed)
    UI.CommunityDockClose = secondary(UI.CommunityDock, "Dismiss", "empty", function()
        self:Dismiss()
    end, "x")
    UI.CommunityDockClose.Root.BackgroundTransparency = 1
    UI.CommunityDockClose.Label.Visible = false
    UI.CommunityRestore = secondary(UI.Preferences, "CommunityVisibility", "communityHide", function()
        if Settings.CommunityDismissed then
            self:Restore()
        else
            self:Dismiss()
        end
    end)
    Runtime:Connect(UI.AuthScroll:GetPropertyChangedSignal("CanvasPosition"), function()
        self:RevealCard()
    end)
    Runtime:Connect(UI.CommunityCard.MouseEnter, function()
        if self:Interactive() then
            self:Paint(true)
        end
    end)
    Runtime:Connect(UI.CommunityCard.MouseLeave, function()
        self:Paint(false)
    end)
    self:Refresh()
end

-- One owner for frontend-only UX. No license decision or FlowAuth request lives here.
Experience = { Stage = "authReady", OptionsOpen = false, PrefDirty = false }
function Experience:SetStage(stage)
    self.Stage = stage
    if UI.AuthStatus then
        Localization:Bind(UI.AuthStatus, stage)
        UI.AuthStatus.TextColor3 = stage == "authFailed" and Theme.Warning
            or stage == "authGranted" and Theme.Text
            or Theme.Secondary
    end
end
function Experience:LicenseText()
    if not State.Authorized then
        return ""
    end
    local info = State.AuthInfo
    if not info then
        return Localization:Get("authGranted")
    end
    local tier = info.tier
    local text = Localization:Get(
        tier == "premium" and "accessPremium"
            or tier == "free" and "accessFree"
            or tier == "keyless" and "accessKeyless"
            or "authGranted"
    )
    if info.secondsLeft ~= nil then
        local remaining = math.max(0, info.secondsLeft - (os.clock() - info.ReceivedAt))
        local duration = remaining >= 86400 and (math.floor(remaining / 86400) .. "d")
            or remaining >= 3600 and (math.floor(remaining / 3600) .. "h")
            or remaining >= 60 and (math.floor(remaining / 60) .. "m")
            or remaining > 0 and "<1m"
            or "0m"
        text = text .. "  •  " .. Localization:Get("expiresIn") .. " " .. duration
    end
    return text
end
function Experience:Refresh()
    self:SetStage(self.Stage)
    if UI.AuthLicense then
        Localization:Bind(UI.AuthLicense, "empty", "Text", function()
            return self:LicenseText()
        end)
    end
    if UI.ProgressLicense and Modal.AuthCompletion then
        UI.ProgressLicense.Text = self:LicenseText()
    end
    self:RefreshGame()
    self:RefreshOptions()
    Community:Refresh()
    LicenseOffer:Refresh()
end
function Experience:RefreshGame()
    if not UI.CurrentGame then
        return
    end
    local id = GameMedia:PlaceId(game.PlaceId)
    local matched
    for _, product in ipairs(State.Products) do
        if id and product.GameId == id then
            matched = product
            break
        end
    end
    Localization:Bind(UI.GameName, "currentGame", "Text", function()
        return matched and productName(matched)
            or self.CurrentGameCard and self.CurrentGameCard.Product.ResolvedName
            or Localization:Get("currentGame")
    end)
    Localization:Bind(UI.GameSupport, matched and "inCatalog" or "notInCatalog")
    UI.GameSupport.TextColor3 = matched and Theme.Accent or Theme.Secondary
    local image = id and GameMedia:Thumbnail(id) or ""
    if UI.GameImage.Image ~= image then
        UI.GameImage.Image = image
    end
    UI.GameImage.Visible = image ~= "" and UI.GameImage.IsLoaded
end
function Experience:SavePrefs()
    if not self.PrefDirty then
        return true
    end
    local write = capability("writefile")
    if not write then
        self.PrefSaveState = "prefSession"
        self:RefreshOptions()
        return false
    end
    local ok = pcall(function()
        local make = capability("makefolder")
        local exists = capability("isfolder")
        if make and (not exists or not exists("PLAK")) then
            pcall(make, "PLAK")
        end
        local http = game:GetService("HttpService")
        -- Whitelist only UI preferences. Never persist tier, authorization or key.
        write(
            "PLAK/ui_preferences.json",
            http:JSONEncode({
                Version = 1,
                Language = Settings.Language,
                UIScale = Settings.UIScale,
                ReducedMotion = Settings.ReducedMotion,
                CommunityDismissed = Settings.CommunityDismissed,
            })
        )
    end)
    if ok then
        self.PrefDirty = false
    end
    self.PrefSaveState = ok and "prefSaved" or "prefUnsaved"
    self:RefreshOptions()
    return ok
end
function Experience:LoadPrefs()
    local read, exists = capability("readfile"), capability("isfile")
    if not read or not exists then
        return
    end
    pcall(function()
        if not exists("PLAK/ui_preferences.json") then
            return
        end
        local raw = read("PLAK/ui_preferences.json")
        if type(raw) ~= "string" or #raw > 4096 then
            return
        end
        local data = game:GetService("HttpService"):JSONDecode(raw)
        if type(data) ~= "table" or data.Version ~= 1 then
            return
        end
        local language = resolveLanguage(data.Language)
        if language then
            Settings.Language = language
        end
        Settings.UIScale = math.clamp(finite(data.UIScale, 1), 0.85, 1.15)
        if type(data.ReducedMotion) == "boolean" then
            Settings.ReducedMotion = data.ReducedMotion
        end
        if type(data.CommunityDismissed) == "boolean" then
            Settings.CommunityDismissed = data.CommunityDismissed
        end
    end)
end
function Experience:PreferenceChanged()
    self.PrefDirty = true
    self.PrefSaveState = "prefPending"
    Runtime:Cancel(self.PrefTimer)
    self.PrefTimer = Runtime:Later(0.25, function()
        self.PrefTimer = nil
        self:SavePrefs()
    end)
    self:RefreshOptions()
end
function Experience:RefreshOptions()
    if not UI.Preferences then
        return
    end
    UI.Preferences.Visible = self.OptionsOpen
    Localization:Bind(UI.PreferenceLanguage.Label, "languageOption", "Text", function()
        return Localization:Get("languageOption") .. ": " .. Settings.Language:upper()
    end)
    Localization:Bind(UI.PreferenceScale.Label, "scaleOption", "Text", function()
        return Localization:Get("scaleOption") .. ": " .. math.floor(Settings.UIScale * 100 + 0.5) .. "%"
    end)
    Localization:Bind(UI.PreferenceMotion.Label, Settings.ReducedMotion and "motionReduced" or "motionFull")
    Localization:Bind(UI.PreferenceNote, self.PrefSaveState or "prefSession")
    local busy = State.Activity ~= "Idle"
    UI.PasteKey:SetDisabled(busy or not capability("getclipboard"))
    UI.ForgetKey:SetDisabled(busy or type(State.Callbacks.ForgetKey) ~= "function")
    UI.Options:SetDisabled(busy)
    if UI.CommunityRestore then
        UI.CommunityRestore:SetDisabled(busy or not Settings.CommunityEnabled or Community:Link() == "")
    end
    for _, button in ipairs({ UI.PreferenceLanguage, UI.PreferenceScale, UI.PreferenceMotion, UI.PreferenceReset }) do
        button:SetDisabled(busy)
    end
    UI.PasteKey.Root:SetAttribute(
        "DisabledReason",
        not capability("getclipboard") and Localization:Get("clipboardUnavailable") or ""
    )
    UI.ForgetKey.Root:SetAttribute(
        "DisabledReason",
        type(State.Callbacks.ForgetKey) ~= "function" and Localization:Get("keyForgetUnavailable") or ""
    )
    Localization:Bind(UI.KeyActionsNote, "empty", "Text", function()
        if not capability("getclipboard") then
            return Localization:Get("clipboardUnavailable")
        elseif type(State.Callbacks.ForgetKey) ~= "function" then
            return Localization:Get("keyForgetUnavailable")
        end
        return ""
    end)
end
function Experience:Paste()
    if not AuthField.Interactive() then
        return false, "busy"
    end
    local read = capability("getclipboard")
    if not read then
        return false, "clipboard_unavailable"
    end
    local ok, value = pcall(read)
    value = ok and trim(value) or ""
    if value == "" or #value > 4096 or value:find("[%z\r\n]") then
        Loader:Toast({ Type = "warning", Subtitle = Localization:Get("clipboardEmpty") })
        return false, "invalid_clipboard"
    end
    UI.Key.Text = value
    AuthField:SetVisible(false)
    AuthField:Feedback(nil)
    UI.Key:CaptureFocus()
    return true
end
function Experience:Forget()
    if not AuthField.Interactive() then
        return false, "busy"
    end
    local callback = State.Callbacks.ForgetKey
    if type(callback) ~= "function" then
        return false, "callback_unavailable"
    end
    -- Prevent duplicate clicks even if the host callback yields.
    State.Activity = "ForgettingKey"
    reconcile()
    self:RefreshOptions()
    local ok, removed = pcall(callback, Loader)
    if not State.Alive then
        return false, "destroyed"
    end
    State.Activity = "Idle"
    reconcile()
    self:RefreshOptions()
    if ok and removed == true then
        UI.Key.Text = ""
        AuthField:SetVisible(false)
        AuthField:Feedback(nil)
        Loader:Toast({ Type = "info", Subtitle = Localization:Get("keyForgotten") })
        -- This only removes the saved credential; it does not revoke a session.
        return true
    end
    Loader:Toast({ Type = "warning", Subtitle = Localization:Get("keyForgetFailed") })
    return false, "delete_failed"
end
function Experience:SuccessCheck()
    if not UI.ProgressCheck or not Modal.AuthCompletion then
        return
    end
    UI.ProgressCheck.Root.Visible = true
    UI.ProgressCheckScale.Scale = Settings.ReducedMotion and 1 or 0.78
    Animation:To(UI.ProgressCheckScale, { Scale = 1 }, Motion.Page)
    UI.ProgressLicense.Text = self:LicenseText()
end
function Experience:Height()
    return 228 + (LicenseOffer:Enabled() and 52 or 0) + Community:Height() + (self.OptionsOpen and 194 or 0)
end
function Experience:Layout(width, y)
    if not UI.CurrentGame then
        return
    end
    local actionWidth = (width - 16) / 3
    for index, button in ipairs({ UI.PasteKey, UI.ForgetKey, UI.Options }) do
        place(button.Root, (index - 1) * (actionWidth + 8), y, actionWidth, 44)
    end
    if LicenseOffer:Enabled() then
        place(UI.LicenseInline.Root, 0, y + 52, width, 44)
        y = y + 52
    end
    place(UI.KeyActionsNote, 0, y + 46, width, 24)
    place(UI.AuthStatus, 0, y + 74, width, 44)
    place(UI.AuthLicense, 0, y + 120, width, 24)
    place(UI.CurrentGame, 0, y + 152, width, 64)
    place(UI.GamePlaceholder, 8, 8, 48, 48)
    place(UI.GameFallback.Root, 14, 14, 20, 20)
    place(UI.GameImage, 0, 0, 48, 48)
    place(UI.GameName, 68, 8, math.max(1, width - 80), 24)
    place(UI.GameSupport, 68, 34, math.max(1, width - 80), 22)
    Community:Layout(width, y + 228)
    place(UI.Preferences, 0, y + 228 + Community:Height(), width, 184)
    local half = (width - 8) / 2
    place(UI.PreferenceLanguage.Root, 0, 0, half, 44)
    place(UI.PreferenceScale.Root, half + 8, 0, half, 44)
    place(UI.PreferenceMotion.Root, 0, 52, half, 44)
    place(UI.PreferenceReset.Root, half + 8, 52, half, 44)
    place(UI.CommunityRestore.Root, 0, 102, width, 44)
    place(UI.PreferenceNote, 0, 153, width, 28)
end
function Experience:Build()
    local function secondary(name, key, callback, parent)
        local button = Button.new(parent or UI.AuthBody, name, "", false, nil, callback, Runtime, AuthField.Interactive)
        button.BaseColor = Theme.Surface
        button:Apply()
        Localization:Bind(button.Label, key)
        return button
    end
    UI.PasteKey = secondary("PasteKey", "pasteKey", function()
        self:Paste()
    end)
    UI.ForgetKey = secondary("ForgetKey", "forgetKey", function()
        self:Forget()
    end)
    UI.Options = secondary("PreferencesToggle", "options", function()
        Loader:ShowPreferences(not self.OptionsOpen)
    end)
    UI.KeyActionsNote = label(UI.AuthBody, "KeyActionsNote", "", 12, Theme.Secondary)
    UI.KeyActionsNote.TextTruncate = Enum.TextTruncate.AtEnd
    UI.AuthStatus = label(UI.AuthBody, "AuthStatus", "", 12, Theme.Secondary)
    UI.AuthStatus.TextWrapped = true
    UI.AuthStatus.TextTruncate = Enum.TextTruncate.AtEnd
    UI.AuthLicense = label(UI.AuthBody, "AuthLicense", "", 12, Theme.Text)
    UI.AuthLicense.TextTruncate = Enum.TextTruncate.AtEnd
    UI.CurrentGame = frame(UI.AuthBody, "CurrentGame", Theme.Input)
    corner(UI.CurrentGame, 10)
    UI.GamePlaceholder = frame(UI.CurrentGame, "Thumbnail", Theme.Elevated)
    UI.GamePlaceholder.ClipsDescendants = true
    corner(UI.GamePlaceholder, 8)
    UI.GameFallback = Icon.new(UI.GamePlaceholder, "grid", Theme.Secondary, 20)
    UI.GameImage = create(
        "ImageLabel",
        { Name = "GameImage", BackgroundTransparency = 1, Image = "", Visible = false, ScaleType = Enum.ScaleType.Crop },
        UI.GamePlaceholder
    )
    corner(UI.GameImage, 8)
    UI.GameName = label(UI.CurrentGame, "Name", "", 13, Theme.Text, Theme.Medium)
    UI.GameSupport = label(UI.CurrentGame, "Support", "", 12, Theme.Secondary)
    UI.GameName.TextTruncate = Enum.TextTruncate.AtEnd
    UI.GameSupport.TextTruncate = Enum.TextTruncate.AtEnd
    local currentId = GameMedia:PlaceId(game.PlaceId)
    if currentId then
        local card = {
            Product = { GameId = currentId },
            Scope = Scope.new(),
            Root = UI.CurrentGame,
            Name = UI.GameName,
            Artwork = { Set = function() end }, -- Native thumbnail already owns the image.
        }
        self.CurrentGameCard = card
        Runtime.Finalizers[#Runtime.Finalizers + 1] = function()
            card.Scope:Destroy()
            self.CurrentGameCard = nil
        end
        -- Reuse the bounded/coalesced metadata worker, never add an auth-time request.
        GameMedia:Watch(card)
    end
    Runtime:Connect(UI.GameImage:GetPropertyChangedSignal("IsLoaded"), function()
        UI.GameImage.Visible = UI.GameImage.Image ~= "" and UI.GameImage.IsLoaded
    end)
    UI.Preferences = frame(UI.AuthBody, "Preferences")
    UI.Preferences.BackgroundTransparency = 1
    UI.Preferences.Visible = false
    UI.PreferenceLanguage = secondary("Language", "languageOption", function()
        local order = { en = "es", es = "pt", pt = "ru", ru = "en" }
        Loader:SetLanguage(order[Settings.Language] or "en")
    end, UI.Preferences)
    UI.PreferenceScale = secondary("Scale", "scaleOption", function()
        local nextScale = Settings.UIScale < 0.95 and 1 or Settings.UIScale < 1.05 and 1.1 or 0.9
        Loader:SetUIScale(nextScale)
    end, UI.Preferences)
    UI.PreferenceMotion = secondary("Motion", "motionFull", function()
        Loader:SetReducedMotion(not Settings.ReducedMotion)
    end, UI.Preferences)
    UI.PreferenceReset = secondary("Reset", "resetOptions", function()
        Loader:SetLanguage("en")
        Loader:SetUIScale(1)
        Loader:SetReducedMotion(false)
        Community:Restore()
        self:PreferenceChanged()
    end, UI.Preferences)
    UI.PreferenceNote = label(UI.Preferences, "SaveState", "", 12, Theme.Secondary)
    UI.PreferenceNote.TextWrapped = true
    Community:Build()
    LicenseOffer:BuildTriggers()
    self:Refresh()
end

function AuthField:Hint()
    local width = State.Layout.KeyWidth or math.huge
    return Localization:Get(width < 96 and "keyHintTiny" or width < 180 and "keyHintCompact" or "keyHint")
end
function AuthField:SyncMask()
    if not State.Alive or not UI.KeyMask then
        return
    end
    -- Visual privacy only: the native TextBox keeps editing/IME and the host receives the unmodified key.
    -- Never copy key material to a second text object or to diagnostic/status labels.
    local key = UI.Key.Text
    local hidden = not Settings.KeyVisible and key ~= ""
    UI.Key.TextTransparency = hidden and 1 or 0
    UI.KeyMask.Visible = hidden
    if hidden then
        local ok, length = pcall(utf8.len, key)
        UI.KeyMask.Text = string.rep("•", math.min(128, ok and length or #key))
        local size = UI.KeyMask.AbsoluteSize.X
        local bounds = TextMetrics:Get(UI.KeyMask.Text, UI.KeyMask.TextSize, UI.KeyMask.Font, 10000)
        local textWidth = bounds and bounds.X or math.min(128, ok and length or #key) * UI.KeyMask.TextSize * 0.6
        UI.KeyMask.TextXAlignment = textWidth > size and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    else
        UI.KeyMask.Text = ""
    end
    UI.RevealEye.Root.Visible = not Settings.KeyVisible
    UI.ConcealEye.Root.Visible = Settings.KeyVisible
    UI.RevealKey.Root:SetAttribute("ActionLabel", Localization:Get(Settings.KeyVisible and "hideKey" or "showKey"))
end
function AuthField:Feedback(key, message)
    if not key and not message and not State.AuthFeedback and not State.AuthError then
        return
    end
    State.AuthFeedback = (key or message) and { Key = key, Message = message } or nil
    State.AuthError = State.AuthFeedback ~= nil
    if State.AuthError and State.Page ~= "Auth" then
        Navigation:Go("Auth", true)
    end
    if not UI.KeyFeedback then
        return
    end
    Localization:Bind(UI.KeyFeedback, "empty", "Text", function()
        local feedback = State.AuthFeedback
        return feedback and (feedback.Message or Localization:Get(feedback.Key)) or ""
    end)
    UI.KeyFeedback.Visible = State.AuthError
    if State.AuthError then
        UI.KeyFeedback.TextTransparency = 1
        Animation:To(UI.KeyFeedback, { TextTransparency = 0 }, Motion.Hover)
    end
    UI.KeyIcon:SetColor((State.AuthError or State.Focused) and Theme.Accent or Theme.Muted)
    Animation:To(UI.KeyStroke, {
        Color = Theme.Accent,
        Transparency = State.AuthError and 0.2 or State.Focused and 0.28 or 1,
    }, Motion.Hover)
    reconcile()
    Responsive:Update()
end
function AuthField:SetVisible(value)
    Settings.KeyVisible = value == true
    self:SyncMask()
end
local function authBusy(value)
    UI.Validate:SetDisabled(value)
    UI.GetKey:SetDisabled(value)
    UI.RevealKey:SetDisabled(value)
    UI.Key.TextEditable = State.Visible and not value and State.Page == "Auth"
    UI.Key.Active = UI.Key.TextEditable
    UI.AuthNav:SetDisabled(value)
    UI.ProductsNav:SetDisabled(value)
    UI.RefreshNav:SetDisabled(value)
    LicenseOffer:Refresh()
    UI.AuthBusyTrack.Visible = value
    Experience:SetStage(value and "authChecking" or "authReady")
    Experience:RefreshOptions()
    if value then
        Animation:To(UI.Validate.Scale, { Scale = 0.97 }, Motion.Press, function()
            Animation:To(UI.Validate.Scale, { Scale = 1 }, Motion.Hover)
        end)
        AuthField:SetVisible(false)
        UI.Key:ReleaseFocus(false)
        Localization:Bind(UI.Validate.Label, "validating")
        UI.AuthBusyFill.Position = UDim2.fromScale(Settings.ReducedMotion and 0.325 or -0.35, 0)
        UI.AuthBusyFill.Size = UDim2.fromScale(0.35, 1)
        if not Settings.ReducedMotion then
            State.AuthSpinner = Animation:To(
                UI.AuthBusyFill,
                { Position = UDim2.fromScale(1, 0) },
                TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false)
            )
        end
        Animation:To(UI.Auth, { GroupTransparency = 0.12 }, Motion.Page)
    else
        Animation:Cancel(State.AuthSpinner)
        State.AuthSpinner = nil
        Localization:Bind(UI.Validate.Label, "signIn")
        Animation:To(UI.Auth, { GroupTransparency = 0 }, Motion.Page)
    end
end
local function validate(key)
    if not State.Alive then
        return false, "destroyed"
    end
    if State.Activity ~= "Idle" then
        return false, "busy"
    end
    if State.Modal then
        Modal:Close(true)
    end
    key = trim(key)
    if key == "" then
        AuthField:Feedback("empty")
        if State.Visible then
            UI.Key:CaptureFocus()
        end
        return false, "empty_key"
    end
    local callback = State.Callbacks.Validate
    if type(callback) ~= "function" then
        AuthField:Feedback("noValidator")
        Modal:Open({
            Type = "warning",
            TitleKey = "noValidator",
            DescriptionKey = "noValidatorCopy",
            ActionKey = "close",
            OnAction = function()
                Modal:Close()
            end,
        })
        return false, "callback_unavailable"
    end
    State.ValidationToken = State.ValidationToken + 1
    local token = State.ValidationToken
    State.Activity = "Validating"
    -- A new submission must not display metadata from a previous key/session.
    State.Authorized = false
    State.AuthInfo = nil
    Experience:Refresh()
    AuthField:Feedback(nil)
    UI.Key.Text = key
    closeLanguage()
    authBusy(true)
    reconcile()
    Runtime:Cancel(State.SlowAuthTimer)
    State.SlowAuthTimer = Runtime:Later(8, function()
        State.SlowAuthTimer = nil
        if token == State.ValidationToken and State.Activity == "Validating" then
            Experience:SetStage("authSlow")
        end
    end)
    -- Lock before scheduling: Activated, Enter and AutoValidate all share this one submission path.
    task.defer(function()
        if not State.Alive or token ~= State.ValidationToken then
            return
        end
        local ok, success, message = pcall(callback, key)
        if not State.Alive or token ~= State.ValidationToken then
            return
        end
        Runtime:Cancel(State.SlowAuthTimer)
        State.SlowAuthTimer = nil
        State.Activity = "Idle"
        authBusy(false)
        if ok and success == true then
            State.Authorized = true
            Experience:SetStage("authGranted")
            Experience:Refresh()
            AuthField:Feedback(nil)
            reconcile()
            local resultMessage = cleanMessage(message, Localization:Get("authGranted"))
            if Settings.SuccessBehavior == "hide" or Settings.SuccessBehavior == "destroy" then
                -- This is a frontend exit transition, not simulated backend progress.
                -- The validator must return before Script() starts; use SetOnAuthorized.
                local behavior = Settings.SuccessBehavior
                local authorized = State.Callbacks.Authorized
                State.Activity = "Completing"
                reconcile()
                Experience:RefreshOptions()
                Modal:Loading({ Text = resultMessage, Progress = 0, AuthCompletion = true })
                Runtime:Later(Settings.ReducedMotion and 0 or 0.35, function()
                    if token == State.ValidationToken then
                        Modal:SetProgress(1)
                        Experience:SuccessCheck()
                    end
                end)
                Runtime:Later(Settings.ReducedMotion and 0 or 0.7, function()
                    if token ~= State.ValidationToken then
                        return
                    end
                    Loader:Hide()
                    Runtime:Later(Settings.ReducedMotion and 0 or Motion.Exit.Time, function()
                        if token ~= State.ValidationToken then
                            return
                        end
                        -- Capture host work before Destroy clears callbacks. It must not
                        -- be scoped to the frontend or skipped because the UI is gone.
                        if behavior == "destroy" then
                            Loader:Destroy()
                        else
                            State.Activity = "Idle"
                            reconcile()
                            Experience:RefreshOptions()
                        end
                        if type(authorized) == "function" then
                            task.defer(function()
                                local ran = pcall(authorized, key, resultMessage, Loader)
                                if not ran then
                                    warn("[PLAK] Authorized callback failed to initialize the script")
                                end
                            end)
                        end
                    end)
                end)
                return
            else
                Modal:Open({
                    Type = "success",
                    TitleKey = "granted",
                    Description = resultMessage,
                    ActionKey = "continue",
                    OnAction = function()
                        Modal:Close(true)
                        if Settings.SuccessBehavior == "products" then
                            Navigation:Go("Products")
                        end
                    end,
                })
            end
            if State.Alive and State.Callbacks.Authorized then
                invokeHost(State.Callbacks.Authorized, key, resultMessage, Loader)
            end
        else
            State.AuthError = true
            State.Authorized = false
            State.AuthInfo = nil
            Experience:SetStage("authFailed")
            Experience:Refresh()
            reconcile()
            -- Do not display raw Lua exceptions, stack traces, key material or arbitrary non-string return values.
            local resultMessage = ok and cleanMessage(message, Localization:Get("genericError"))
                or Localization:Get("genericError")
            local kind = classifyFailure(resultMessage)
            local generic = Localization:Get("genericError")
            if #key >= 4 and resultMessage:find(key, 1, true) then
                resultMessage = generic
            end
            local adviceKey = kind == "network" and "networkHint"
                or kind == "service" and "serviceHint"
                or kind == "key" and "keyErrorHint"
                or "errorHint"
            resultMessage = safeText(resultMessage, 240) .. "\n" .. Localization:Get(adviceKey)
            AuthField:Feedback(nil, safeText(resultMessage, 360))
            if kind == "disabled" then
                Modal:Open({ Type = "disabled", TitleKey = "access", Description = resultMessage })
            end
        end
        GameMedia:Drain()
    end)
    return true
end
local function buildAuth()
    UI.Auth = group(UI.Pages, "Authorization")
    UI.Auth.Size = UDim2.fromScale(1, 1)
    UI.AuthScroll = create("ScrollingFrame", {
        Name = "AuthContent",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.AccentDark,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        VerticalScrollBarInset = Enum.ScrollBarInset.None,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
    }, UI.Auth)
    UI.AuthBody = frame(UI.AuthScroll, "Body")
    UI.AuthBody.BackgroundTransparency = 1
    UI.HeroA = localized(UI.AuthBody, "HeroAccent", "heroA", 46, Theme.AccentText, Theme.Display)
    UI.HeroB = localized(UI.AuthBody, "HeroWhite", "heroB", 46, Theme.Text, Theme.Display)
    UI.HeroA.TextYAlignment = Enum.TextYAlignment.Top
    UI.HeroB.TextYAlignment = Enum.TextYAlignment.Top
    UI.AuthCopy = localized(UI.AuthBody, "Copy", "copy", 12, Theme.Secondary)
    UI.AuthCopy.TextWrapped = true
    UI.AuthCopy.TextYAlignment = Enum.TextYAlignment.Bottom
    UI.KeyContainer = frame(UI.AuthBody, "KeyField", Theme.Input)
    corner(UI.KeyContainer, 10)
    UI.KeyStroke = stroke(UI.KeyContainer, Theme.Line, 1, 1)
    UI.KeyIcon = Icon.new(UI.KeyContainer, "key", Theme.Muted, 19)
    place(UI.KeyIcon.Root, 15, 15, 19, 19)
    UI.Key = create("TextBox", {
        Name = "Key",
        Text = "",
        PlaceholderText = "",
        PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Theme.Medium,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        MultiLine = false,
        ClipsDescendants = true,
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.fromOffset(45, 0),
    }, UI.KeyContainer)
    pcall(function()
        UI.Key.ShowNativeInput = false
    end)
    Localization:Bind(UI.Key, "keyHint", "PlaceholderText", function()
        return AuthField:Hint()
    end)
    UI.KeyMask = label(UI.KeyContainer, "KeyMask", "", 13, Theme.Text, Theme.Medium)
    UI.KeyMask.Active = false
    UI.KeyMask.Selectable = false
    UI.KeyMask.TextTruncate = Enum.TextTruncate.AtEnd
    UI.KeyMask.ZIndex = 2
    UI.KeyMask.Visible = false
    UI.RevealKey = Button.new(UI.KeyContainer, "RevealKey", "", false, nil, function()
        AuthField:SetVisible(not Settings.KeyVisible)
    end, Runtime, AuthField.Interactive)
    UI.RevealKey.Root.BackgroundTransparency = 1
    UI.RevealKey.Root.ZIndex = 3
    UI.RevealKey.Label.Visible = false
    UI.RevealEye = Icon.new(UI.RevealKey.Root, "eye", Theme.Secondary, 19)
    UI.ConcealEye = Icon.new(UI.RevealKey.Root, "eye-off", Theme.Accent, 19)
    place(UI.RevealEye.Root, 12, 12, 19, 19)
    place(UI.ConcealEye.Root, 12, 12, 19, 19)
    UI.KeyFeedback = label(UI.AuthBody, "KeyFeedback", "", 12, Theme.Accent, Theme.Medium)
    UI.KeyFeedback.TextWrapped = true
    UI.KeyFeedback.TextYAlignment = Enum.TextYAlignment.Top
    UI.KeyFeedback.TextTruncate = Enum.TextTruncate.AtEnd
    UI.KeyFeedback.Visible = false
    Runtime:Connect(UI.Key:GetPropertyChangedSignal("Text"), function()
        AuthField:SyncMask()
        if State.Activity == "Idle" then
            if State.AuthFeedback then
                AuthField:Feedback(nil)
            end
            if not State.Authorized then
                Experience:SetStage("authReady")
            end
        end
    end)
    AuthField:SyncMask()
    Runtime:Connect(UI.Key.Focused, function()
        if not AuthField.Interactive() then
            UI.Key:ReleaseFocus(false)
            return
        end
        State.Focused = true
        reconcile()
        Animation:To(
            UI.KeyStroke,
            { Color = Theme.Accent, Transparency = State.AuthError and 0.2 or 0.28 },
            Motion.Hover
        )
        UI.KeyIcon:SetColor(Theme.Accent)
        Responsive:Update()
    end)
    Runtime:Connect(UI.Key.FocusLost, function(enter)
        State.Focused = false
        reconcile()
        UI.KeyIcon:SetColor(State.AuthError and Theme.Accent or Theme.Muted)
        Animation:To(UI.KeyStroke, { Transparency = State.AuthError and 0.2 or 1 }, Motion.Hover)
        if enter and AuthField.Interactive() then
            validate(UI.Key.Text)
        end
        Responsive:Update()
    end)
    Runtime:Connect(UI.KeyContainer.MouseEnter, function()
        if not State.Focused and canInteract() then
            Animation:To(UI.KeyContainer, { BackgroundColor3 = Theme.Elevated }, Motion.Hover)
        end
    end)
    Runtime:Connect(UI.KeyContainer.MouseLeave, function()
        Animation:To(UI.KeyContainer, { BackgroundColor3 = Theme.Input }, Motion.Hover)
    end)
    UI.Validate = Button.new(UI.AuthBody, "Validate", "", true, nil, function()
        validate(UI.Key.Text)
    end, Runtime, AuthField.Interactive)
    Localization:Bind(UI.Validate.Label, "signIn")
    UI.GetKey = Button.new(UI.AuthBody, "GetKey", "", false, "support", function()
        openLink(Settings.KeyLink)
    end, Runtime, AuthField.Interactive)
    Localization:Bind(UI.GetKey.Label, "getKey")
    UI.AuthBusyTrack = frame(UI.Validate.Root, "WaitingTrack", Theme.AccentDark)
    UI.AuthBusyTrack.Position = UDim2.new(0, 14, 1, -8)
    UI.AuthBusyTrack.Size = UDim2.new(1, -28, 0, 3)
    UI.AuthBusyTrack.ClipsDescendants = true
    UI.AuthBusyTrack.Visible = false
    corner(UI.AuthBusyTrack, 2)
    UI.AuthBusyFill = frame(UI.AuthBusyTrack, "IndeterminateFill", Theme.Text)
    corner(UI.AuthBusyFill, 2)
    UI.AuthArtwork = BrandArt.new(UI.AuthBody, "HeroArtwork")
    UI.AuthArtwork:Set(Settings.Artwork)
    Experience:Build()
end
function Cards:Clear()
    for _, card in ipairs(self) do
        card.Scope:Destroy()
        Localization:Forget(card.Root)
        card.Artwork:Destroy()
        Animation:CancelTree(card.Root)
        card.Root:Destroy()
    end
    for index = #self, 1, -1 do
        self[index] = nil
    end
    self.Hovered = nil
end
local function launchProduct(product)
    if not canInteract() then
        return false, "busy"
    end
    State.SelectedProduct = product
    local status = Statuses[product.Status] or Statuses.Disabled
    if not status.Launch then
        Modal:Open({
            Type = (product.Status == "LimitedAccess" or product.Status == "Disabled") and "disabled" or "warning",
            Title = productName(product),
            Description = Localization:Get("unavailable"),
        })
        return false, "unavailable"
    end
    if product.RequireAuth ~= false and not State.Authorized then
        Loader:Toast({
            Type = "warning",
            Icon = "key",
            Title = Localization:Get("ready"),
            Subtitle = Localization:Get("signInFirst"),
        })
        Navigation:Go("Auth")
        return false, "authorization_required"
    end
    local callback = product.OnLaunch or State.Callbacks.ProductLaunch
    if type(callback) ~= "function" then
        Modal:Open({
            Type = "info",
            Title = productName(product),
            Description = Localization:Get("launchMissing"),
            ActionKey = "close",
            OnAction = function()
                Modal:Close()
            end,
        })
        return false, "callback_unavailable"
    end
    State.LaunchToken = State.LaunchToken + 1
    local token = State.LaunchToken
    State.Activity = "Launching"
    local handle = Modal:Loading({ Text = product.LoadingText })
    reconcile()
    task.defer(function()
        if not State.Alive or token ~= State.LaunchToken then
            return
        end
        local ok, success, message = pcall(callback, product, handle, Loader)
        if not State.Alive or token ~= State.LaunchToken then
            return
        end
        State.Activity = "Idle"
        reconcile()
        if success == "pending" and ok then
            return
        end
        if ok and success == true then
            handle:Complete({
                Type = "success",
                Description = cleanMessage(message, Localization:Get("successCopy")),
                Link = product.Website,
            })
        else
            handle:Complete({
                Type = "error",
                Description = ok and cleanMessage(message, Localization:Get("failureCopy"))
                    or Localization:Get("genericError"),
            })
        end
    end)
    return true
end
function Cards:Create(product, index)
    local card = { Scope = Scope.new(), Product = product, Index = index }
    card.Root = group(UI.Catalog, "Product_" .. product.Id)
    card.Root.BackgroundTransparency = 0
    card.Root.BackgroundColor3 = Theme.AccentDark
    card.Root.ClipsDescendants = true
    corner(card.Root, 10)
    card.Artwork = Artwork.new(
        card.Root,
        "ProductArtwork",
        nil,
        product.Artwork or (product.GameId and GameMedia:Thumbnail(product.GameId))
    )
    card.Artwork.Root.Size = UDim2.fromScale(1, 1)
    card.Artwork.Image.ImageColor3 = Color3.fromRGB(245, 235, 240)
    card.Shade = frame(card.Root, "Shade", Color3.new(0, 0, 0))
    card.Shade.Size = UDim2.fromScale(1, 1)
    card.Shade.BackgroundTransparency = 0.2
    local shadeGradient = create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.99),
            NumberSequenceKeypoint.new(0.4, 0.87),
            NumberSequenceKeypoint.new(1, 0.16),
        }),
    }, card.Shade)
    card.Logo = Icon.new(card.Root, "rosette", Theme.Text, 25)
    card.Name = label(card.Root, "ProductName", "", 16, Theme.Text, Theme.Bold)
    card.Name.TextTruncate = Enum.TextTruncate.AtEnd
    Localization:Bind(card.Name, "umbrella", "Text", function()
        return productName(product)
    end)
    card.Description = label(card.Root, "Description", "", 11, Theme.Text)
    card.Description.TextWrapped = true
    card.Description.TextYAlignment = Enum.TextYAlignment.Top
    card.Description.TextTruncate = Enum.TextTruncate.AtEnd
    Localization:Bind(card.Description, "productCopy", "Text", function()
        return localizedValue(product.Description, Localization:Get(product.GameId and "gameCopy" or "productCopy"))
    end)
    local status = Statuses[product.Status] or Statuses.Disabled
    card.Status = frame(card.Root, "Status", Theme.Surface)
    corner(card.Status, 5)
    card.StatusLabel = localized(card.Status, "StatusText", status.Key, 10, Theme.Text, Theme.Medium)
    card.StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    card.StatusIconBox = frame(card.Root, "StatusIcon", Theme.Surface)
    corner(card.StatusIconBox, 5)
    card.StatusIcon = Icon.new(card.StatusIconBox, status.Icon, Theme.Secondary, 16)
    card.Open = Button.new(
        card.Root,
        "Launch",
        "",
        false,
        "play",
        function()
            launchProduct(product)
        end,
        card.Scope,
        function()
            return canInteract() and State.Page == "Products"
        end
    )
    card.Open.BaseColor = Theme.Surface
    card.Open.Root.BackgroundColor3 = Theme.Surface
    card.Open.Icon.Root.Position = UDim2.new(0.5, -9, 0.5, 0)
    card.Dim = frame(card.Root, "InactiveShade", Theme.Surface)
    card.Dim.BackgroundTransparency = 1
    card.Dim.Size = UDim2.fromScale(1, 1)
    card.Dim.ZIndex = 2
    card.Dim.Active = false
    local function hover(value)
        if value and (not canInteract() or State.Page ~= "Products") then
            return
        end
        Cards.Hovered = value and card or nil
        for _, other in ipairs(Cards) do
            Animation:To(other.Dim, { BackgroundTransparency = value and other ~= card and 0.48 or 1 }, Motion.Page)
            Animation:To(
                other.Artwork.Image,
                { ImageColor3 = value and other == card and Color3.new(1, 1, 1) or Color3.fromRGB(245, 235, 240) },
                Motion.Hover
            )
        end
        for _, other in ipairs(Cards) do
            other.Open.ContextHovered = value and other == card
            other.Open:Apply()
        end
    end
    card.Scope:Connect(card.Root.MouseEnter, function()
        hover(true)
    end)
    card.Scope:Connect(card.Root.MouseLeave, function()
        if Cards.Hovered == card then
            hover(false)
        end
    end)
    card.Scope:Connect(card.Open.Root.SelectionGained, function()
        hover(true)
    end)
    card.Scope:Connect(card.Open.Root.SelectionLost, function()
        if Cards.Hovered == card then
            hover(false)
        end
    end)
    self[#self + 1] = card
    GameMedia:Watch(card)
    return card
end
function Cards:SettleReveal(card)
    card.RevealToken = (card.RevealToken or 0) + 1
    card.Scope:Cancel(card.RevealThread)
    card.RevealThread = nil
    Animation:CancelProperty(card.Root, "Position")
    Animation:CancelProperty(card.Root, "GroupTransparency")
    if card.RestPosition then
        card.Root.Position = card.RestPosition
    end
    card.Root.GroupTransparency = 0
end
function Cards:Reveal()
    if not State.Alive or not State.Visible or State.Page ~= "Products" then
        return
    end
    for index, card in ipairs(self) do
        self:SettleReveal(card)
        if not Settings.ReducedMotion and card.RestPosition then
            local token = card.RevealToken
            card.Root.GroupTransparency = 1
            card.Root.Position = card.RestPosition + UDim2.fromOffset(0, 10)
            card.RevealThread = card.Scope:Later(math.min(index - 1, 5) * 0.035, function()
                card.RevealThread = nil
                if State.Visible and State.Page == "Products" and token == card.RevealToken then
                    Animation:To(card.Root, { GroupTransparency = 0, Position = card.RestPosition }, Motion.Enter)
                else
                    self:SettleReveal(card)
                end
            end)
        end
    end
end
function Cards:Layout()
    local width = UI.Catalog.AbsoluteSize.X / math.max(0.1, UI.Scale.Scale)
    local columns = width >= 590 and #self > 1 and 2 or 1
    local gap = 18
    local cardWidth = math.floor((width - gap * (columns - 1)) / columns)
    if #self == 1 and width >= 590 then
        cardWidth = math.min(cardWidth, 548)
    end
    local cardHeight = math.clamp(math.floor(cardWidth * 0.55), 202, 242)
    if #self == 1 and self[1].Product.GameId then
        cardHeight = math.clamp(math.floor(cardWidth * 9 / 16), 202, 308)
    end
    local availableHeight = UI.Catalog.AbsoluteSize.Y / math.max(0.1, UI.Scale.Scale)
    if columns == 2 and #self <= 4 and availableHeight >= 422 then
        cardHeight = math.min(cardHeight, math.floor((availableHeight - gap) / 2))
    end
    for index, card in ipairs(self) do
        self:SettleReveal(card)
        place(
            card.Root,
            (
                #self == 1 and width >= 590 and math.floor((width - cardWidth) / 2)
                or ((index - 1) % columns) * (cardWidth + gap)
            ),
            math.floor((index - 1) / columns) * (cardHeight + gap),
            cardWidth,
            cardHeight
        )
        card.RestPosition = card.Root.Position
        place(card.Logo.Root, 16, cardHeight - 99, 24, 24)
        place(card.Name, 48, cardHeight - 102, cardWidth - 72, 29)
        place(card.Description, 16, cardHeight - 66, cardWidth - 82, 53)
        place(card.Open.Root, cardWidth - 59, cardHeight - 60, 44, 44)
        local text = Localization:Get((Statuses[card.Product.Status] or Statuses.Disabled).Key)
        local statusMaximum = math.max(40, cardWidth - 68)
        local statusWidth = math.clamp(#characters(text) * 5.5 + 20, math.min(88, statusMaximum), statusMaximum)
        place(card.Status, cardWidth - statusWidth - 58, 14, statusWidth, 28)
        place(card.StatusLabel, 6, 0, statusWidth - 12, 28)
        place(card.StatusIconBox, cardWidth - 46, 14, 30, 28)
        place(card.StatusIcon.Root, 7, 6, 16, 16)
    end
    local rows = math.ceil(#self / columns)
    UI.Catalog.CanvasSize = UDim2.fromOffset(0, math.max(0, rows * (cardHeight + gap) - gap + 2))
end
function Cards:Rebuild()
    self:Clear()
    self.Hovered = nil
    for index, product in ipairs(State.Products) do
        self:Create(product, index)
    end
    self:Layout()
    self:Reveal()
end
local function buildProducts()
    UI.Products = group(UI.Pages, "Products")
    UI.Products.Size = UDim2.fromScale(1, 1)
    UI.Products.Visible = false
    UI.Catalog = create("ScrollingFrame", {
        Name = "Catalog",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.AccentDark,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        VerticalScrollBarInset = Enum.ScrollBarInset.None,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
    }, UI.Products)
    UI.CatalogEmpty = localized(UI.Products, "Empty", "unavailable", 14, Theme.Secondary)
    UI.CatalogEmpty.TextWrapped = true
    UI.CatalogEmpty.TextXAlignment = Enum.TextXAlignment.Center
    UI.CatalogEmpty.Size = UDim2.fromScale(1, 1)
    UI.CatalogEmpty.Visible = false
end
function Navigation:Refresh()
    Localization:Bind(UI.Breadcrumb, "authorization", "Text", function()
        return State.Page == "Auth" and (Localization:Get("main") .. "  •  " .. Localization:Get("authorization"))
            or (Localization:Get("product") .. "  •  " .. productName(State.SelectedProduct or State.Products[1]))
    end)
    UI.AuthNav.Icon:SetColor(State.Page == "Auth" and Theme.Accent or Theme.Muted)
    UI.ProductsNav.Icon:SetColor(State.Page == "Products" and Theme.Accent or Theme.Muted)
    UI.ProductMark.Visible = State.Page == "Products" and State.Layout.Height >= 380
    UI.Copyright.Visible = State.Page == "Auth" and State.Layout.Height >= 320
    if UI.ContextPage ~= State.Page then
        UI.ContextIcon.Root:Destroy()
        UI.ContextIcon = Icon.new(UI.Sidebar, State.Page == "Auth" and "home" or "grid", Theme.Muted, 18)
        UI.ContextPage = State.Page
    end
    if State.Layout.ContextY then
        place(UI.ContextIcon.Root, State.Layout.Rail / 2 - 9, State.Layout.ContextY, 18, 18)
    end
    UI.ContextIcon.Root.Visible = State.Layout.Height >= 380
    local selected = State.Page == "Auth" and UI.AuthNav.Root or UI.ProductsNav.Root
    Animation:To(UI.ActiveNav, { Position = selected.Position + UDim2.fromOffset(4, 4) }, Motion.Page)
end
function Navigation:Go(page, force)
    if not State.Alive or (not force and not canInteract()) then
        return false
    end
    if page ~= "Auth" and page ~= "Products" then
        return false
    end
    closeLanguage()
    UI.AuthArtwork:CancelReveal()
    State.PageToken = State.PageToken + 1
    local token = State.PageToken
    local previous = State.Page == "Auth" and UI.Auth or UI.Products
    local destination = page == "Auth" and UI.Auth or UI.Products
    State.Page = page
    State.Focused = false
    UI.Key.TextEditable = State.Visible and page == "Auth" and State.Activity ~= "Validating"
    UI.Key.Active = UI.Key.TextEditable
    UI.Key:ReleaseFocus(false)
    reconcile()
    self:Refresh()
    if previous == destination then
        destination.Visible = true
        Animation:To(destination, { GroupTransparency = 0 }, Motion.Page)
        return true
    end
    previous.Visible = false
    Animation:CancelTree(previous)
    destination.Visible = true
    destination.GroupTransparency = 1
    destination.Position = UDim2.fromOffset(0, 6)
    Animation:To(destination, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, Motion.Page, function()
        if token == State.PageToken then
            previous.Visible = false
        end
    end)
    for _, card in ipairs(Cards) do
        card.Dim.BackgroundTransparency = 1
        card.Open.ContextHovered = false
        card.Open:Apply()
    end
    Cards.Hovered = nil
    Responsive:Update()
    if page == "Auth" then
        UI.AuthArtwork:Reveal()
    else
        Cards:Reveal()
    end
    return true
end
local function displayFontSize(text, width, maximum)
    local size = math.min(maximum, math.floor(width / math.max(1, #characters(text))))
    local bounds = TextMetrics:Get(text, size, Theme.Display, 10000)
    if bounds and bounds.X > width then
        size = math.floor(size * width / bounds.X)
    end
    return math.max(16, size)
end
function Responsive:Auth(width, height, narrow)
    local bodyWidth = width
    local heroWidth, heroHeight, copyY, inputY, buttonsY, artY, artHeight, leftWidth
    local stackedButtons = narrow and width < 340
    if narrow then
        leftWidth = width
        heroWidth = width
        heroHeight = math.min(112, width * 0.25)
        copyY = heroHeight + 16
        inputY = copyY + 44
        buttonsY = inputY + 62
        artY = buttonsY + (stackedButtons and 106 or 48) + 24
        artHeight = math.clamp(width * 0.65, 156, 248)
        local artWidth = math.min(width, artHeight * 0.793)
        place(UI.AuthArtwork.Root, math.floor((width - artWidth) / 2), artY, artWidth, artHeight)
        UI.AuthArtwork.Root.Visible = height >= 220
        UI.AuthArtwork:Layout(artWidth, artHeight)
        UI.AuthBody.Size = UDim2.fromOffset(bodyWidth, artY + artHeight + 8)
        UI.AuthScroll.CanvasSize = UDim2.fromOffset(0, artY + artHeight + 8)
    else
        local artVisible = width >= 490 and height >= 180
        leftWidth = math.floor(math.min(artVisible and width * 0.52 or width, 414))
        artHeight = height
        local artWidth = math.min(artHeight * 0.793, width * 0.425)
        heroWidth = math.min(leftWidth + 46, artVisible and width - artWidth - 16 or width)
        heroHeight = math.clamp(height * 0.27, 76, 120)
        copyY = math.max(heroHeight + 24, math.floor(height * 0.445))
        inputY = copyY + 32
        buttonsY = inputY + 64
        place(UI.AuthArtwork.Root, width - artWidth, 0, artWidth, artHeight)
        UI.AuthArtwork.Root.Visible = artVisible
        UI.AuthArtwork:Layout(artWidth, artHeight)
        local bodyHeight = math.max(height, buttonsY + 50)
        UI.AuthBody.Size = UDim2.fromOffset(bodyWidth, bodyHeight)
        UI.AuthScroll.CanvasSize = UDim2.fromOffset(0, bodyHeight)
    end
    local heroASize = displayFontSize(Localization:Get("heroA"), heroWidth, 56)
    local heroBSize = displayFontSize(Localization:Get("heroB"), heroWidth, narrow and 56 or 64)
    local compact = not narrow and height < 270
    local controlHeight = compact and 44 or 50
    local buttonHeight = compact and 44 or 48
    if compact then
        local compactFont = math.clamp(math.floor((height - 138) / 2), 24, 36)
        heroASize = math.min(heroASize, compactFont)
        heroBSize = math.min(heroBSize, compactFont)
        heroHeight = (math.max(heroASize, heroBSize) + 6) * 2 + 2
        copyY = heroHeight + 2
        inputY = copyY + 22
        buttonsY = inputY + 52
        local bodyHeight = math.max(height, buttonsY + buttonHeight)
        UI.AuthBody.Size = UDim2.fromOffset(bodyWidth, bodyHeight)
        UI.AuthScroll.CanvasSize = UDim2.fromOffset(0, bodyHeight)
    end
    -- Short translated headings can reach a larger font than the original EN/RU lines.
    -- Reflow downstream content from the measured two-line extent, never from a guessed hero height.
    local titleBottom = heroASize + heroBSize + 14
    if titleBottom > copyY then
        local shift = titleBottom + (compact and 2 or 16) - copyY
        copyY = copyY + shift
        inputY = inputY + shift
        buttonsY = buttonsY + shift
        if narrow then
            artY = artY + shift
        end
    end
    local feedback = State.AuthFeedback
    local feedbackText = feedback and (feedback.Message or Localization:Get(feedback.Key)) or ""
    local feedbackHeight = feedback and math.clamp(measure(feedbackText, 12, Theme.Medium, leftWidth) + 3, 20, 54) or 0
    local feedbackExtra = feedbackHeight > 0 and feedbackHeight + 8 or 0
    buttonsY = buttonsY + feedbackExtra
    Community:Measure(leftWidth)
    local extrasHeight = Experience:Height()
    if narrow then
        artY = artY + feedbackExtra + extrasHeight
        UI.AuthArtwork.Root.Position = UDim2.fromOffset(UI.AuthArtwork.Root.Position.X.Offset, artY)
        local bodyHeight = artY + artHeight + 8
        UI.AuthBody.Size = UDim2.fromOffset(bodyWidth, bodyHeight)
        UI.AuthScroll.CanvasSize = UDim2.fromOffset(0, bodyHeight)
    else
        local bodyHeight = math.max(height, buttonsY + buttonHeight + 2 + extrasHeight)
        UI.AuthBody.Size = UDim2.fromOffset(bodyWidth, bodyHeight)
        UI.AuthScroll.CanvasSize = UDim2.fromOffset(0, bodyHeight)
    end
    place(UI.KeyFeedback, 0, inputY + controlHeight + 6, leftWidth, feedbackHeight)
    UI.Key.Size = UDim2.new(1, -96, 1, 0)
    State.Layout.KeyWidth = leftWidth - 96
    UI.Key.PlaceholderText = AuthField:Hint()
    UI.KeyMask.Position = UI.Key.Position
    UI.KeyMask.Size = UI.Key.Size
    place(UI.RevealKey.Root, leftWidth - 47, (controlHeight - 44) / 2, 44, 44)
    AuthField:SyncMask()
    UI.HeroA.TextSize = heroASize
    UI.HeroB.TextSize = heroBSize
    local firstHeight = heroASize + 6
    place(UI.HeroA, 0, 0, heroWidth, firstHeight)
    place(UI.HeroB, 0, firstHeight + 2, heroWidth, heroBSize + 6)
    place(UI.AuthCopy, 0, copyY, leftWidth, narrow and 36 or compact and 18 or 24)
    place(UI.KeyContainer, 0, inputY, leftWidth, controlHeight)
    place(UI.KeyIcon.Root, 15, (controlHeight - 19) / 2, 19, 19)
    if stackedButtons then
        place(UI.Validate.Root, 0, buttonsY, leftWidth, 48)
        place(UI.GetKey.Root, 0, buttonsY + 58, leftWidth, 48)
    else
        local buttonWidth = math.floor((leftWidth - 16) / 2)
        place(UI.Validate.Root, 0, buttonsY, buttonWidth, buttonHeight)
        place(UI.GetKey.Root, buttonWidth + 16, buttonsY, leftWidth - buttonWidth - 16, buttonHeight)
    end
    Experience:Layout(leftWidth, buttonsY + (stackedButtons and 106 or buttonHeight) + 12)
    UI.AuthScroll.ScrollingEnabled = UI.AuthScroll.CanvasSize.Y.Offset > height + 1
    if State.Focused and height < 300 then
        UI.AuthScroll.CanvasPosition = Vector2.new(0, math.max(0, inputY - 28))
    elseif not State.Focused and not UI.AuthScroll.ScrollingEnabled then
        UI.AuthScroll.CanvasPosition = Vector2.new(0, 0)
    end
end
local function safeSize()
    local size = UI.Stage.AbsoluteSize
    if size.X < 1 or size.Y < 1 then
        local camera = workspace.CurrentCamera
        size = camera and camera.ViewportSize or Vector2.new(1280, 720)
    end
    local height = size.Y
    pcall(function()
        if Services.Input.VirtualKeyboardVisible and State.Focused then
            local position = Services.Input.VirtualKeyboardPosition
            if position.Y > 0 then
                height = math.min(height, position.Y - UI.Stage.AbsolutePosition.Y - 8)
            end
        end
    end)
    return Vector2.new(math.max(160, size.X), math.max(160, height))
end
function Responsive:Clamp(center, size, windowSize)
    local half = windowSize / 2
    return Vector2.new(
        math.clamp(center.X, half.X + 8, math.max(half.X + 8, size.X - half.X - 8)),
        math.clamp(center.Y, half.Y + 8, math.max(half.Y + 8, size.Y - half.Y - 8))
    )
end
function Responsive:Update()
    if not State.Alive or not UI.Pages then
        return
    end
    local safe = safeSize()
    local narrow = (safe.X < 620 and safe.X / safe.Y < 1.35) or (safe.X < 850 and safe.X / safe.Y < 1.22)
    local width, height, scale
    if narrow then
        width = math.min(560, safe.X - 20)
        height = math.min(720, safe.Y - 20)
        scale = 1
    elseif safe.X >= 1000 and safe.Y >= 660 then
        width = 912
        height = 543
        scale = math.min(1, (safe.X - 24) / width, (safe.Y - 24) / height)
    else
        width = math.min(912, safe.X - 20)
        height = math.min(543, safe.Y - 20)
        scale = 1
    end
    scale = math.min(scale * Settings.UIScale, (safe.X - 20) / width, (safe.Y - 20) / height)
    local rail = width >= 780 and 72 or 56
    local header = height >= 500 and 72 or 54
    local pageTop = height >= 500 and 128 or 106
    if height < 400 then
        header = 44
        pageTop = 90
    end
    if height < 260 then
        pageTop = 82
    end
    local footer = height >= 500 and not narrow and 18 or 54
    local contentWidth = width - rail - 18
    local contentHeight = math.max(52, height - pageTop - footer)
    State.Layout = {
        Width = width,
        Height = height,
        Scale = scale,
        Rail = rail,
        Narrow = narrow,
        ContextY = header + 10,
        Safe = safe,
    }
    UI.Window.Size = UDim2.fromOffset(width, height)
    UI.Scale.Scale = scale
    local center = State.WindowCenter or safe / 2
    center = self:Clamp(center, safe, Vector2.new(width * scale, height * scale))
    State.WindowCenter = center
    State.Drag = nil
    Animation:CancelProperty(UI.Window, "Position")
    UI.Window.Position = UDim2.fromOffset(center.X, center.Y)
    -- Resize settles the shell reveal but never resets page/modal state or recreates the component tree.
    -- Visibility alpha belongs exclusively to Show/Hide, including during keyboard resize.
    place(UI.Header, 0, 0, width, header)
    place(UI.BrandLogo.Root, rail / 2 - 14, header / 2 - 14, 28, 28)
    local userWidth = width < 480 and math.clamp(math.floor(width * 0.22), 44, 92) or 112
    UI.Minimize.Root.Visible = narrow or Services.Input.TouchEnabled == true
    local extra = UI.Minimize.Root.Visible and 50 or 0
    local avatarX = width - 52 - extra
    local userX = width - 64 - userWidth - extra
    UI.User.Visible = userX - rail >= 64
    if not UI.User.Visible then
        userX = avatarX
    end
    place(UI.Brand, rail, 0, math.max(20, userX - rail - 12), header)
    place(UI.User, userX, 0, UI.User.Visible and userWidth or 0, header)
    place(UI.Avatar.Root, avatarX, header / 2 - 18, 36, 36)
    place(UI.UserAction, userX - 4, 0, avatarX + 40 - userX, header)
    place(UI.Minimize.Root, width - 52, (header - 44) / 2, 44, 44)
    local restoreY = math.clamp(center.Y - 28, 8, math.max(8, safe.Y - 64))
    pcall(function()
        if Services.Input.VirtualKeyboardVisible then
            local keyboardTop = Services.Input.VirtualKeyboardPosition.Y - UI.Stage.AbsolutePosition.Y
            if keyboardTop > 0 then
                restoreY = math.max(8, math.min(restoreY, keyboardTop - 64))
            end
        end
    end)
    place(UI.RestoreDock, math.max(8, safe.X - 68), restoreY, 56, 56)
    UI.Minimize.Root:SetAttribute("ActionLabel", Localization:Get("minimize"))
    UI.Restore.Root:SetAttribute("ActionLabel", Localization:Get("restore"))
    if UI.CustomAvatar then
        UI.CustomAvatar.Position = UI.Avatar.Root.Position
        UI.CustomAvatar.Size = UI.Avatar.Root.Size
    end
    place(UI.Sidebar, 0, 0, rail, height)
    local navY = height >= 380 and header + 50 or header + 22
    place(UI.AuthNav.Root, rail / 2 - 22, navY, 44, 44)
    place(UI.ProductsNav.Root, rail / 2 - 22, navY + 48, 44, 44)
    place(UI.RefreshNav.Root, rail / 2 - 22, navY + (State.Page == "Products" and height >= 380 and 132 or 96), 44, 44)
    UI.ProductsNav.Root.Visible = height >= 280
    UI.RefreshNav.Root.Visible = height >= 350
    place(UI.LicenseNav.Root, rail / 2 - 22, navY + (State.Page == "Products" and 180 or 144), 44, 44)
    UI.LicenseNav.Root.Visible = LicenseOffer:Enabled() and height >= 380
    place(UI.ActiveNav, rail / 2 - 18, (State.Page == "Auth" and navY or navY + 48) + 4, 36, 36)
    place(UI.ProductMark, rail / 2 - 16, navY + 94, 32, 32)
    place(UI.Breadcrumb, rail, header + 6, contentWidth - 8, 28)
    UI.Breadcrumb.TextTruncate = Enum.TextTruncate.AtEnd
    local hasSocial = false
    for index, id in ipairs({ "discord", "telegram", "youtube" }) do
        local button = UI.Social[id]
        button.Root.Visible = (State.Callbacks.Social ~= nil or Settings.SocialLinks[id] ~= nil) and contentWidth >= 450
        place(button.Root, width - 14 - (4 - index) * 44, header - 1, 44, 44)
        hasSocial = hasSocial or button.Root.Visible
    end
    if hasSocial then
        UI.Breadcrumb.Size = UDim2.fromOffset(math.max(80, contentWidth - 152), 28)
    end
    place(UI.Pages, rail, pageTop, contentWidth, contentHeight)
    local footerWidth = narrow and contentWidth or math.min(math.floor(contentWidth * 0.52), 414)
    place(UI.Copyright, rail, height - 45, math.max(50, footerWidth - (Settings.Version ~= "" and 84 or 0)), 26)
    place(UI.Version, rail + footerWidth - 72, height - 45, 72, 26)
    UI.Version.Visible = State.Page == "Auth" and height >= 320
    place(UI.LanguageToggle, rail / 2 - 22, height - 82, 44, 74)
    place(UI.LanguageChevron.Root, 16, 4, 12, 12)
    place(UI.LanguageFlag, 9, 38, 26, 26)
    LanguageController:Layout(width, height, rail)
    local communityDockHeight = Community:DockHeight(contentWidth, height)
    local authHeight = math.max(52, contentHeight - communityDockHeight)
    UI.AuthScroll.Size = UDim2.new(1, 0, 1, -communityDockHeight)
    self:Auth(contentWidth, authHeight, narrow)
    Community:LayoutDock(rail, pageTop + contentHeight - communityDockHeight, contentWidth, height)
    Navigation:Refresh()
    Cards:Layout()
    Modal:Layout(true)
    Toasts:Layout()
end
function Responsive:Request()
    if not State.Alive or self.Pending then
        return
    end
    self.Pending = Runtime:Later(0, function()
        self.Pending = nil
        self:Update()
    end)
end
local function pointer(input)
    local value = input.Position
    return Vector2.new(value.X, value.Y) - UI.Stage.AbsolutePosition
end
local function bindInput()
    Runtime:Connect(UI.Stage:GetPropertyChangedSignal("AbsoluteSize"), function()
        Responsive:Request()
    end)
    Runtime:Connect(UI.Stage:GetPropertyChangedSignal("AbsolutePosition"), function()
        Responsive:Request()
    end)
    for _, property in ipairs({ "VirtualKeyboardVisible", "VirtualKeyboardPosition", "VirtualKeyboardSize" }) do
        pcall(function()
            Runtime:Connect(Services.Input:GetPropertyChangedSignal(property), function()
                Responsive:Request()
            end)
        end)
    end
    pcall(function()
        Runtime:Connect(Services.Input:GetPropertyChangedSignal("TouchEnabled"), function()
            Responsive:Request()
        end)
    end)
    Runtime:Connect(UI.Header.InputBegan, function(input)
        local kind = input.UserInputType
        if not State.Visible or State.Modal or State.Drag or Services.Input:GetFocusedTextBox() then
            return
        end
        if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
            return
        end
        local pos = pointer(input)
        for _, button in ipairs({ UI.UserAction, UI.Minimize.Root }) do
            if button.Visible then
                local hit = button.AbsolutePosition - UI.Stage.AbsolutePosition
                local size = button.AbsoluteSize
                if pos.X >= hit.X and pos.X <= hit.X + size.X and pos.Y >= hit.Y and pos.Y <= hit.Y + size.Y then
                    return
                end
            end
        end
        Animation:CancelProperty(UI.Window, "Position")
        closeLanguage()
        State.Drag = {
            Input = input,
            Start = pos,
            Center = Vector2.new(UI.Window.Position.X.Offset, UI.Window.Position.Y.Offset),
        }
    end)
    Runtime:Connect(Services.Input.InputChanged, function(input)
        local drag = State.Drag
        if not drag then
            return
        end
        if input ~= drag.Input and input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        if drag.Input.UserInputType == Enum.UserInputType.Touch and input ~= drag.Input then
            return
        end
        local size = Vector2.new(State.Layout.Width * State.Layout.Scale, State.Layout.Height * State.Layout.Scale)
        local center = Responsive:Clamp(drag.Center + pointer(input) - drag.Start, safeSize(), size)
        State.WindowCenter = center
        Animation:To(UI.Window, { Position = UDim2.fromOffset(center.X, center.Y) }, Motion.Drag)
        if State.Modal then
            Modal:Layout()
        end
    end)
    Runtime:Connect(Services.Input.InputEnded, function(input)
        if
            State.Drag
            and (
                input == State.Drag.Input
                or (
                    State.Drag.Input.UserInputType == Enum.UserInputType.MouseButton1
                    and input.UserInputType == Enum.UserInputType.MouseButton1
                )
            )
        then
            State.Drag = nil
        end
    end)
    Runtime:Connect(Services.Input.WindowFocusReleased, function()
        State.Drag = nil
    end)
    Runtime:Connect(Services.Input.InputBegan, function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == Enum.KeyCode.Escape then
            if LanguageController.Open then
                closeLanguage()
            elseif (State.Modal == "result" or State.Modal == "licenses") and State.Activity == "Idle" then
                Modal:Close()
            end
        elseif input.KeyCode == Settings.ToggleKey and not Services.Input:GetFocusedTextBox() then
            if State.Visible then
                Loader:Hide()
            else
                Loader:Show()
            end
        elseif LanguageController.Open then
            local kind = input.UserInputType
            if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
                local p = pointer(input)
                local origin = UI.LanguageMenu.AbsolutePosition - UI.Stage.AbsolutePosition
                local size = UI.LanguageMenu.AbsoluteSize
                local toggle = UI.LanguageToggle.AbsolutePosition - UI.Stage.AbsolutePosition
                local toggleSize = UI.LanguageToggle.AbsoluteSize
                local inMenu = p.X >= origin.X
                    and p.X <= origin.X + size.X
                    and p.Y >= origin.Y
                    and p.Y <= origin.Y + size.Y
                local inToggle = p.X >= toggle.X
                    and p.X <= toggle.X + toggleSize.X
                    and p.Y >= toggle.Y
                    and p.Y <= toggle.Y + toggleSize.Y
                if not inMenu and not inToggle then
                    closeLanguage()
                end
            end
        end
    end)
end
local function restoreAffordance(visible)
    if visible then
        UI.RestoreDock.Visible = true
        Animation:To(UI.RestoreDock, { GroupTransparency = 0 }, Motion.Enter)
    else
        Animation:To(UI.RestoreDock, { GroupTransparency = 1 }, Motion.Exit, function()
            if State.Visible then
                UI.RestoreDock.Visible = false
            end
        end)
    end
end
function Loader:SetKeyVisible(visible)
    if not State.Alive then
        return self, false
    end
    if visible == true and not AuthField.Interactive() then
        return self, false
    end
    AuthField:SetVisible(visible)
    return self, true
end
function Loader:IsKeyVisible()
    return Settings.KeyVisible
end
function Loader:SetTitle(title)
    if not State.Alive then
        return self
    end
    Settings.Title = safeText(title, 96)
    State.TitleCustom = true
    Localization:Bind(UI.Brand, "brand", "Text", function()
        return Settings.Title
    end)
    updateFooter()
    return self
end
function Loader:SetVersion(version)
    if State.Alive then
        Settings.Version = safeText(version, 48)
        updateFooter()
        Responsive:Update()
    end
    return self
end
function Loader:SetKeyLink(url)
    if State.Alive then
        Settings.KeyLink = type(url) == "string" and url:sub(1, 4096) or ""
    end
    return self
end
function Loader:SetExpiry(seconds)
    if State.Alive then
        Settings.Expiry = math.max(0, finite(seconds, 0))
    end
    return self
end
function Loader:GetExpiry()
    return Settings.Expiry
end
-- Validation only: return true/false and a message; do not run long-lived Script() here.
function Loader:SetOnValidate(callback)
    assert(callback == nil or type(callback) == "function", "SetOnValidate expects a function or nil")
    if State.Alive then
        State.Callbacks.Validate = callback
    end
    return self
end
function Loader:AutoValidate(key)
    return validate(key)
end
function Loader:Validate(key)
    if not State.Alive then
        return false, "destroyed"
    end
    return validate(key ~= nil and key or UI.Key.Text)
end
function Loader:Toast(config)
    if not State.Alive then
        return nil
    end
    config = type(config) == "table" and config or { Subtitle = tostring(config or "") }
    local item = {
        Type = config.Type,
        Icon = type(config.Icon) == "string" and config.Icon or nil,
        Title = config.Title,
        Subtitle = config.Subtitle,
        Duration = config.Duration,
    }
    if #Toasts.Queue >= 20 then
        table.remove(Toasts.Queue, 1)
    end
    Toasts.Queue[#Toasts.Queue + 1] = item
    Toasts:Drain()
    return self
end
function Loader:ClearToasts()
    table.clear(Toasts.Queue)
    for index = #Toasts.Items, 1, -1 do
        Toasts:Close(Toasts.Items[index], true)
    end
    return self
end
function Loader:ShowLicenses()
    return LicenseOffer:Open()
end
function Loader:SetLicenseOfferEnabled(enabled)
    if State.Alive then
        Settings.LicenseOfferEnabled = enabled == true
        if not LicenseOffer:Enabled() and State.Modal == "licenses" then
            Modal:Close(true)
        end
        LicenseOffer:Refresh()
        Responsive:Update()
    end
    return self
end
function Loader:SetLicenseStoreLink(link)
    if not State.Alive then
        return self, false
    end
    if type(link) ~= "string" then
        return self, false
    end
    link = trim(link)
    if #link > 2048 or link:find("[%z\r\n]") or (link ~= "" and not link:match("^https://[^/%s]+")) then
        return self, false
    end
    Settings.LicenseStoreLink = link
    if not LicenseOffer:Enabled() and State.Modal == "licenses" then
        Modal:Close(true)
    end
    LicenseOffer:Refresh()
    Responsive:Update()
    return self, true
end
function Loader:SetLanguage(language)
    if not State.Alive then
        return self
    end
    language = resolveLanguage(language)
    if not Translations[language] then
        return self, false
    end
    if Settings.Language == language then
        return self, true
    end
    Settings.Language = language
    closeLanguage()
    Animation:CancelTree(UI.LanguageFlag)
    UI.LanguageFlag:Destroy()
    UI.LanguageFlag = flag(UI.LanguageToggle, language)
    LanguageController:Paint()
    updateFooter()
    Navigation:Refresh()
    if State.Modal == "result" then
        Modal:Refresh()
    end
    Responsive:Update()
    Localization:Refresh(true)
    Experience:Refresh()
    Experience:PreferenceChanged()
    return self, true
end
function Loader:GetLanguage()
    return Settings.Language
end
function Loader:SetUser(user, avatar)
    if not State.Alive then
        return self
    end
    if type(user) == "table" then
        avatar = user.Avatar
        user = user.Name
    end
    Settings.User = safeText(user or "Past Owl", 96)
    UI.User.Text = Settings.User
    Runtime:Disconnect(UI.AvatarConnection)
    UI.AvatarConnection = nil
    if UI.CustomAvatar then
        UI.CustomAvatar:Destroy()
        UI.CustomAvatar = nil
    end
    local source = assetId(avatar)
    UI.Avatar.Root.Visible = source == nil
    if source then
        UI.CustomAvatar = create("ImageLabel", {
            Name = "Avatar",
            Image = source,
            BackgroundTransparency = 1,
            Position = UI.Avatar.Root.Position,
            Size = UI.Avatar.Root.Size,
            ScaleType = Enum.ScaleType.Crop,
        }, UI.Header)
        corner(UI.CustomAvatar, 100)
        UI.Avatar.Root.Visible = not UI.CustomAvatar.IsLoaded
        UI.AvatarConnection = Runtime:Connect(UI.CustomAvatar:GetPropertyChangedSignal("IsLoaded"), function()
            if UI.CustomAvatar then
                UI.Avatar.Root.Visible = not UI.CustomAvatar.IsLoaded
            end
        end)
    end
    return self
end
function Loader:SetArtwork(artwork)
    if State.Alive then
        Settings.Artwork = artwork
        UI.AuthArtwork:Set(artwork)
    end
    return self
end
function Loader:SetProducts(products)
    if not State.Alive then
        return self
    end
    assert(type(products) == "table", "SetProducts expects an array of product configurations")
    local normalized, used = {}, {}
    for index, config in ipairs(products) do
        if index > 48 then
            break
        end
        if type(config) == "table" then
            local id = tostring(config.Id or index):sub(1, 96)
            if not used[id] then
                used[id] = true
                normalized[#normalized + 1] = {
                    Id = id,
                    GameId = GameMedia:PlaceId(config.GameId or config.PlaceId),
                    FallbackName = config.FallbackName,
                    Name = config.Name,
                    Description = config.Description,
                    Status = Statuses[config.Status] and config.Status or "Disabled",
                    Artwork = config.Artwork,
                    AssetName = config.AssetName,
                    RequireAuth = config.RequireAuth,
                    OnLaunch = type(config.OnLaunch) == "function" and config.OnLaunch or nil,
                    Website = config.Website,
                    LoadingText = config.LoadingText,
                }
            end
        end
    end
    State.Products = normalized
    State.SelectedProduct = nil
    if UI.Catalog then
        Cards:Rebuild()
        UI.CatalogEmpty.Visible = #normalized == 0
        Navigation:Refresh()
        Experience:RefreshGame()
    end
    return self
end
function Loader:SetProduct(product)
    if not State.Alive then
        return self
    end
    if type(product) == "table" then
        return self:SetProducts({ product })
    end
    for _, candidate in ipairs(State.Products) do
        if candidate.Id == tostring(product) then
            State.SelectedProduct = candidate
            Navigation:Go("Products")
            break
        end
    end
    return self
end
function Loader:LaunchProduct(id)
    if not State.Alive then
        return false, "destroyed"
    end
    for _, product in ipairs(State.Products) do
        if product.Id == tostring(id) then
            return launchProduct(product)
        end
    end
    return false, "product_not_found"
end
function Loader:SetStatus(status, productId)
    if not State.Alive then
        return self
    end
    if productId then
        for _, product in ipairs(State.Products) do
            if product.Id == tostring(productId) then
                product.Status = Statuses[status] and status or "Disabled"
            end
        end
        Cards:Rebuild()
    else
        Modal:SetText(status)
    end
    return self
end
function Loader:ShowProducts()
    Navigation:Go("Products")
    return self
end
function Loader:ShowAuth()
    Navigation:Go("Auth")
    return self
end
function Loader:ShowLoading(config)
    return Modal:Loading(config)
end
function Loader:SetProgress(value)
    if State.Alive then
        Modal:SetProgress(value)
    end
    return self
end
function Loader:HideLoading()
    if State.Alive and State.Modal == "progress" then
        Modal:Close()
    end
    return self
end
function Loader:ShowResult(config)
    Modal:Open(type(config) == "table" and config or { Type = "info", Description = tostring(config or "") })
    return self
end
function Loader:CloseModal()
    if State.Alive and State.Activity == "Idle" then
        Modal:Close()
    end
    return self
end
function Loader:SetSuccessBehavior(behavior)
    assert(
        behavior == "products" or behavior == "stay" or behavior == "hide" or behavior == "destroy",
        "Unknown success behavior"
    )
    if State.Alive then
        Settings.SuccessBehavior = behavior
    end
    return self
end
function Loader:SetReducedMotion(value)
    if State.Alive then
        Settings.ReducedMotion = value == true
        if Settings.ReducedMotion then
            -- Settle destinations and lifecycle finalizers; cancelling alone strands exiting notifications.
            Animation:Finish()
            UI.AuthArtwork:CancelReveal()
            for _, card in ipairs(Cards) do
                Cards:SettleReveal(card)
            end
            Localization:Refresh(false)
            UI.Window.GroupTransparency = State.Visible and 0 or 1
            UI.Auth.GroupTransparency = State.Activity == "Validating" and 0.12 or 0
            UI.Products.GroupTransparency = 0
            UI.Result.GroupTransparency = 0
            UI.ResultScale.Scale = 1
            UI.ProgressPanel.GroupTransparency = 0
            UI.Backdrop.BackgroundTransparency = State.Modal and 0.48 or 1
            if State.Modal == "licenses" then
                LicenseOffer:Layout(true)
            end
        end
        if State.Activity == "Validating" then
            authBusy(true)
        end
        Experience:PreferenceChanged()
    end
    return self
end
function Loader:SetToggleKey(keyCode)
    if State.Alive and typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode then
        Settings.ToggleKey = keyCode
    end
    return self
end
function Loader:SetOnSupport(callback)
    assert(callback == nil or type(callback) == "function", "SetOnSupport expects a function or nil")
    if State.Alive then
        State.Callbacks.Support = callback
    end
    return self
end
function Loader:SetSupportLink(url)
    if State.Alive then
        Settings.SupportLink = type(url) == "string" and url or ""
    end
    return self
end
function Loader:SetOnSocial(callback)
    assert(callback == nil or type(callback) == "function", "SetOnSocial expects a function or nil")
    if State.Alive then
        State.Callbacks.Social = callback
        Responsive:Update()
    end
    return self
end
function Loader:SetSocialLinks(links)
    if State.Alive and type(links) == "table" then
        Settings.SocialLinks = {}
        for _, id in ipairs({ "discord", "telegram", "youtube" }) do
            if type(links[id]) == "string" and links[id] ~= "" then
                Settings.SocialLinks[id] = links[id]
            end
        end
        Community:Refresh()
        Responsive:Update()
    end
    return self
end
function Loader:SetOnProductLaunch(callback)
    assert(callback == nil or type(callback) == "function", "SetOnProductLaunch expects a function or nil")
    if State.Alive then
        State.Callbacks.ProductLaunch = callback
    end
    return self
end
-- Runs after the success transition and UI teardown in destroy/hide mode.
-- Register before AutoValidate; the host owns Script() and its error handling.
function Loader:SetOnAuthorized(callback)
    assert(callback == nil or type(callback) == "function", "SetOnAuthorized expects a function or nil")
    if State.Alive then
        State.Callbacks.Authorized = callback
    end
    return self
end
function Loader:SetOnRefresh(callback)
    assert(callback == nil or type(callback) == "function", "SetOnRefresh expects a function or nil")
    if State.Alive then
        State.Callbacks.Refresh = callback
    end
    return self
end
function Loader:SetOnUser(callback)
    assert(callback == nil or type(callback) == "function", "SetOnUser expects a function or nil")
    if State.Alive then
        State.Callbacks.User = callback
        UI.UserAction.Visible = callback ~= nil
    end
    return self
end
-- Pass only metadata returned by the host's successful RequireKey call.
-- This display method never authorizes a key or unlocks premium features.
function Loader:SetAuthInfo(info)
    if not State.Alive then
        return self
    end
    State.AuthInfo = nil
    if type(info) == "table" then
        local tier = info.tier or info.keyTier
        local seconds = finite(info.secondsLeft, nil)
        State.AuthInfo = {
            tier = (tier == "premium" or tier == "free" or tier == "keyless") and tier or nil,
            secondsLeft = seconds and seconds >= 0 and seconds or nil,
            scriptName = type(info.scriptName) == "string" and safeText(info.scriptName, 100) or nil,
            scriptVersion = type(info.scriptVersion) == "string" and safeText(info.scriptVersion, 40) or nil,
            ReceivedAt = os.clock(),
        }
        if type(info.isUserPremium) == "boolean" then
            State.AuthInfo.isUserPremium = info.isUserPremium
        end
    end
    Experience:Refresh()
    return self
end
-- Host callback returns true only when saved-key removal succeeds.
-- Forgetting a stored credential is not a FlowAuth license revocation.
function Loader:SetOnForgetKey(callback)
    assert(callback == nil or type(callback) == "function", "SetOnForgetKey expects a function or nil")
    if State.Alive then
        State.Callbacks.ForgetKey = callback
        Experience:RefreshOptions()
    end
    return self
end
function Loader:PasteKey()
    return Experience:Paste()
end
function Loader:ForgetSavedKey()
    return Experience:Forget()
end
function Loader:SetUIScale(value)
    if State.Alive then
        Settings.UIScale = math.clamp(finite(value, 1), 0.85, 1.15)
        Responsive:Update()
        Experience:PreferenceChanged()
    end
    return self
end
function Loader:ShowPreferences(visible)
    if not AuthField.Interactive() then
        return self, false
    end
    Experience.OptionsOpen = visible ~= false
    Experience:RefreshOptions()
    Responsive:Update()
    return self, true
end

-- Community invitations are optional; these methods never verify Discord membership.
function Loader:SetCommunityEnabled(enabled)
    if State.Alive then
        Settings.CommunityEnabled = enabled == true
        if Settings.CommunityEnabled then
            Community:Restore()
        else
            Community.Generation = Community.Generation + 1
            Community.Hiding = false
            Animation:CancelTree(UI.CommunityCard)
            Animation:CancelTree(UI.CommunityDock)
            Community:Refresh()
            Responsive:Update()
        end
    end
    return self
end
function Loader:SetCommunityLink(link)
    if not State.Alive then
        return self, false
    end
    link = trim(link)
    if link ~= "" and (#link > 2048 or not link:match("^https?://") or link:find("[%z\r\n]")) then
        return self, false
    end
    Settings.SocialLinks.discord = link ~= "" and link or nil
    Community:Refresh()
    Responsive:Update()
    return self, true
end
function Loader:GetCommunityLink()
    return Community:Link()
end

function Loader:GetState()
    return {
        Name = State.Name,
        Page = State.Page,
        Activity = State.Activity,
        Visible = State.Visible,
        KeyVisible = Settings.KeyVisible,
        AuthError = State.AuthError == true,
        Authorized = State.Authorized,
        Language = Settings.Language,
        UIScale = Settings.UIScale,
        ReducedMotion = Settings.ReducedMotion,
        CommunityEnabled = Community:Enabled(),
        CommunityDockVisible = UI.CommunityDock and UI.CommunityDock.Visible or false,
        CommunityDismissed = Settings.CommunityDismissed,
        AuthStage = Experience.Stage,
        AccessTier = State.Authorized and State.AuthInfo and State.AuthInfo.tier or nil,
        ExpirySeconds = Settings.Expiry,
        Progress = State.Progress,
        Modal = State.Modal,
        ProductId = State.SelectedProduct and State.SelectedProduct.Id or nil,
    }
end
function Loader:Show()
    if not State.Alive then
        return self
    end
    State.VisibilityToken = State.VisibilityToken + 1
    State.Visible = true
    reconcile()
    restoreAffordance(false)
    UI.Window.Visible = true
    UI.Key.TextEditable = State.Activity ~= "Validating" and State.Page == "Auth"
    UI.Key.Active = UI.Key.TextEditable
    Responsive:Update()
    UI.Overlay.Visible = State.Modal ~= nil
    Animation:To(UI.Window, { GroupTransparency = 0 }, Motion.Enter)
    if State.Page == "Auth" then
        UI.AuthArtwork:Reveal()
    else
        Cards:Reveal()
    end
    return self
end
function Loader:Hide()
    if not State.Alive then
        return self
    end
    State.VisibilityToken = State.VisibilityToken + 1
    local token = State.VisibilityToken
    State.Visible = false
    State.Drag = nil
    State.Focused = false
    reconcile()
    closeLanguage()
    AuthField:SetVisible(false)
    UI.AuthArtwork:CancelReveal()
    for _, card in ipairs(Cards) do
        Cards:SettleReveal(card)
    end
    UI.Key:ReleaseFocus(false)
    UI.Key.TextEditable = false
    Responsive:Update()
    restoreAffordance(true)
    UI.Overlay.Visible = false
    Animation:To(UI.Window, { GroupTransparency = 1 }, Motion.Exit, function()
        if State.VisibilityToken == token and not State.Visible then
            UI.Window.Visible = false
        end
    end)
    return self
end
function Loader:Destroy()
    if not State.Alive then
        return
    end
    Runtime:Cancel(Experience.PrefTimer)
    Experience.PrefTimer = nil
    Experience:SavePrefs()
    State.AuthInfo = nil
    State.SlowAuthTimer = nil
    State.Alive = false
    State.Visible = false
    State.Drag = nil
    State.Activity = "Idle"
    State.Modal = nil
    State.ValidationToken = State.ValidationToken + 1
    State.LaunchToken = State.LaunchToken + 1
    State.DecodeToken = State.DecodeToken + 1
    State.ModalToken = State.ModalToken + 1
    reconcile()
    Runtime:Destroy()
    Animation:Destroy()
    for _, item in ipairs(Toasts.Items) do
        item.Scope:Destroy()
    end
    for _, card in ipairs(Cards) do
        card.Scope:Destroy()
    end
    table.clear(Toasts.Items)
    table.clear(Toasts.Queue)
    table.clear(Localization.Bindings)
    table.clear(TextMetrics.Values)
    TextMetrics.Count = 0
    Responsive.Pending = nil
    GameMedia:Destroy()
    table.clear(State.Callbacks)
    table.clear(State.Products)
    State.SelectedProduct = nil
    State.AuthFeedback = nil
    State.AuthError = false
    Settings.KeyVisible = false
    State.AuthSpinner = nil
    Cards.Hovered = nil
    Modal.Config = nil
    Modal.ProgressHandle = nil
    if UI.Key then
        pcall(function()
            UI.Key:ReleaseFocus(false)
            UI.Key.Text = ""
        end)
    end
    if UI.Gui then
        UI.Gui:Destroy()
    end
    local env = State.Registry
    if env and rawget(env, "__PlakUiLoader") == self then
        env.__PlakUiLoader = nil
    end
    State.Registry = nil
    Settings.Artwork = nil
    Settings.KeyLink = ""
    table.clear(Settings.SocialLinks)
    table.clear(UI)
end
local function findParent()
    local candidates = {}
    local hidden = capability("gethui")
    if hidden then
        local ok, parent = pcall(hidden)
        if ok and typeof(parent) == "Instance" then
            candidates[#candidates + 1] = parent
        end
    end
    local ok, core = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok then
        candidates[#candidates + 1] = core
    end
    local player = Services.Players.LocalPlayer
    local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        candidates[#candidates + 1] = playerGui
    end
    local chosen
    local function tryParent(parent)
        local probe = Instance.new("ScreenGui")
        local allowed = pcall(function()
            probe.Parent = parent
        end)
        probe:Destroy()
        if allowed and not chosen then
            chosen = parent
        end
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") and child:GetAttribute("PlakUiOwned") == true then
                    local dispose = child:FindFirstChild("PlakDispose")
                    if dispose and dispose:IsA("BindableEvent") then
                        dispose:Fire()
                    end
                    child:Destroy()
                end
            end
        end)
    end
    for _, parent in ipairs(candidates) do
        tryParent(parent)
    end
    if not chosen and not playerGui and player then
        local lateGui = player:WaitForChild("PlayerGui", 5)
        if lateGui then
            tryParent(lateGui)
        end
    end
    assert(chosen, "PlakUi requires a client with an accessible UI parent")
    return chosen
end
local function initialize()
    local ok, environment = pcall(function()
        return type(getgenv) == "function" and getgenv() or _G
    end)
    if ok and type(environment) == "table" then
        local previous = rawget(environment, "__PlakUiLoader")
        if type(previous) == "table" and previous.__PlakOwned and type(previous.Destroy) == "function" then
            pcall(previous.Destroy, previous)
        end
        State.Registry = environment
        environment.__PlakUiLoader = Loader
    end
    Loader.__PlakOwned = true
    Experience:LoadPrefs()
    local parent = findParent()
    buildShell(nil)
    buildModal()
    buildAuth()
    buildProducts()
    UI.Gui.Parent = parent
    bindInput()
    local dispose = create("BindableEvent", { Name = "PlakDispose" }, UI.Gui)
    Runtime:Connect(dispose.Event, function()
        Loader:Destroy()
    end)
    Runtime:Connect(UI.Gui.Destroying, function()
        Loader:Destroy()
    end)
    Responsive:Update()
    Loader:SetProducts(SupportedGames)
    reconcile()
    if State.Visible then
        Animation:To(UI.Window, { GroupTransparency = 0 }, Motion.Enter)
        UI.AuthArtwork:Reveal()
    end
    Runtime:Later(Settings.ReducedMotion and 0 or Motion.Enter.Time, function()
        GameMedia.Ready = true
        GameMedia:Drain()
    end)
    Toasts:Drain()
end

-- Embedded assets contain artwork only, never interface text or controls.

local initialized, failure = pcall(initialize)
if not initialized then
    Loader:Destroy()
    error("PlakUi could not initialize: " .. tostring(failure), 0)
end
return Loader
