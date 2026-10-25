-- PlakUi — a client-side loader frontend. Authentication and product execution belong to the host.
-- Callbacks may yield. Progress is host-reported; SetExpiry never grants or revokes a license.
-- Dedicated third tab after Supported Games: ShowLicenses(), SetLicenseOfferEnabled(boolean), SetLicenseStoreLink(httpsURL).
-- Prices are presentation only; checkout and license entitlement remain with the store/host.
-- PLAK is native GUI geometry. Catalog thumbnails are real Roblox content; optional HTTP only enriches metadata.
local ModuleStartedAt = os.clock()
-- Product policy: public reward gateway is fixed, independent of FlowAuth helper/host overrides.
local KEY_REWARD_URL = "https://flowauth.net/v1/projects/3405/rewards/public/complete/407?reward=reward-mv4jrbf3"
local Loader =
    { AuthHandoffVersion = 2, FlowInitVersion = 1, FlowInitPromptVersion = 1, VerifiedPresentationVersion = 1 }
local Services = {
    Players = game:GetService("Players"),
    Tween = game:GetService("TweenService"),
    Input = game:GetService("UserInputService"),
    Text = game:GetService("TextService"),
    Http = game:GetService("HttpService"),
}
-- Plak access studio: graphic charcoal/lavender, native geometry, host-owned auth.
local Theme = {
    Surface = Color3.fromRGB(15, 15, 21),
    Sidebar = Color3.fromRGB(19, 19, 26),
    Header = Color3.fromRGB(17, 17, 24),
    Content = Color3.fromRGB(12, 12, 17),
    Input = Color3.fromRGB(24, 24, 33),
    Elevated = Color3.fromRGB(28, 27, 38),
    Inactive = Color3.fromRGB(33, 31, 45),
    Hover = Color3.fromRGB(39, 36, 52),
    Edge = Color3.fromRGB(43, 40, 56),
    Line = Color3.fromRGB(55, 51, 69),
    WindowEdge = Color3.fromRGB(64, 59, 77),
    Rim = Color3.fromRGB(193, 185, 211),
    MaterialLow = Color3.fromRGB(239, 237, 245),
    Text = Color3.fromRGB(240, 238, 247),
    Secondary = Color3.fromRGB(178, 175, 192),
    Muted = Color3.fromRGB(133, 129, 152),
    Accent = Color3.fromRGB(145, 131, 226),
    AccentHover = Color3.fromRGB(165, 152, 241),
    AccentDark = Color3.fromRGB(49, 41, 80),
    AccentMuted = Color3.fromRGB(34, 30, 51),
    AccentText = Color3.fromRGB(182, 169, 246),
    ButtonText = Color3.fromRGB(17, 15, 25),
    Success = Color3.fromRGB(98, 177, 106),
    Warning = Color3.fromRGB(183, 153, 92),
    Danger = Color3.fromRGB(203, 96, 105),
    ToggleTrackOff = Color3.fromRGB(22, 20, 28),
    ToggleTrackOn = Color3.fromRGB(47, 43, 68),
    ToggleKnobOff = Color3.fromRGB(48, 44, 58),
    ToggleKnobOn = Color3.fromRGB(119, 113, 180),
    ToggleKnobDisabled = Color3.fromRGB(36, 35, 43),
    Radius = 5,
    InputRadius = 6,
    PanelRadius = 8,
    WindowRadius = 10,
    Font = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Bold = Enum.Font.GothamBold,
    Display = Enum.Font.GothamBold,
    BadgeSize = 11,
}
local Motion = {
    Hover = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Press = TweenInfo.new(0.075, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Toggle = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Enter = TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Exit = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    Page = TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    PageExit = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Indicator = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Panel = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Progress = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Drag = TweenInfo.new(0.055, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    DecodeDuration = 0.32,
    PageDistance = 6,
    PanelDistance = 6,
    RevealDistance = 6,
    StageDistance = 4,
    StageDelay = 0.035,
    SheetDistance = 8,
    AccessGate = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
}
local Settings = {
    Title = "PLAK",
    Version = "",
    KeyLink = KEY_REWARD_URL,
    Expiry = 0,
    Language = "en",
    User = "Hi!",
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
    RememberMe = true, -- Preserve prior autosave behavior until the user explicitly opts out.
}
local State = {
    Name = "Initializing",
    Alive = true,
    Visible = true,
    Presented = false,
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
local Accessibility
local Diagnostics
local ExternalAuth
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
    if Settings.ReducedMotion or State.Presented == false then
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
-- Material details are native, static and deliberately low contrast. No texture
-- requests, animation loops or extra CanvasGroups are needed for this depth.
local Material = {}
function Material:Tone(root)
    if root:FindFirstChildOfClass("UIGradient") then
        return
    end
    return create("UIGradient", {
        Name = "SurfaceFalloff",
        Color = ColorSequence.new(Color3.new(1, 1, 1), Theme.MaterialLow),
        Rotation = 90,
    }, root)
end
function Material:Rim(root, color, transparency)
    local rim = frame(root, "SurfaceRim", color or Theme.Rim)
    rim.BackgroundTransparency = transparency or 0.94
    rim.Position, rim.Size = UDim2.fromOffset(6, 0), UDim2.new(1, -12, 0, 1)
    rim.Active, rim.Selectable = false, false
    return rim
end
function Material:Panel(root)
    self:Tone(root)
    self:Rim(root)
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
    elseif State.Activity == "SavingPreferences" then
        State.Name = "SavingPreferences"
    elseif State.Activity == "Launching" then
        State.Name = "ProductLaunching"
    elseif State.Modal == "progress" then
        State.Name = "ProductProgress"
    elseif State.Modal then
        State.Name = "ModalOpen"
    elseif State.Page == "Licenses" then
        State.Name = "LicenseBrowser"
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
    -- Blocking overlays own the foreground; keep queued toast lifecycle intact.
    if UI.ToastLayer then
        UI.ToastLayer.Visible = State.Alive and State.Visible and not State.Modal
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
    elseif name == "collapse-window" then
        path({ { 4, 3 }, { 16, 3 }, { 16, 9 }, { 4, 9 }, { 4, 3 } }, false)
        path({ { 7, 12 }, { 10, 15 }, { 13, 12 } }, false)
        line(5, 18, 15, 18)
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
    elseif name == "copy" then
        path({ { 7, 3 }, { 16, 3 }, { 16, 13 } }, false)
        path({ { 4, 7 }, { 12, 7 }, { 12, 17 }, { 4, 17 }, { 4, 7 } }, false)
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
    elseif name == "chevron-right" then
        path({ { 7, 5 }, { 12, 10 }, { 7, 15 } })
    elseif name == "globe" then
        circle(10, 10, 8)
        line(2, 10, 18, 10)
        path({ { 10, 2 }, { 6, 6 }, { 6, 14 }, { 10, 18 } })
        path({ { 10, 2 }, { 14, 6 }, { 14, 14 }, { 10, 18 } })
    elseif name == "plak" then
        path({ { 3, 18 }, { 3, 2 }, { 18, 10 }, { 9, 15 }, { 6, 13 } })
        path({ { 7, 7 }, { 12, 10 }, { 7, 13 } })
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
    elseif name == "sliders" then
        line(3, 5, 17, 5)
        line(3, 10, 17, 10)
        line(3, 15, 17, 15)
        circle(7, 5, 2, true)
        circle(13, 10, 2, true)
        circle(8, 15, 2, true)
    elseif name == "settings" then
        circle(10, 10, 5.8)
        circle(10, 10, 2.2)
        for index = 0, 7 do
            local angle = index * math.pi / 4
            line(
                10 + math.cos(angle) * 6.3,
                10 + math.sin(angle) * 6.3,
                10 + math.cos(angle) * 8.2,
                10 + math.sin(angle) * 8.2
            )
        end
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
        SetColor = function(_, value, preset)
            for _, part in ipairs(parts) do
                if part:IsA("UIStroke") then
                    if preset then
                        Animation:To(part, { Color = value }, preset)
                    else
                        Animation:CancelProperty(part, "Color")
                        part.Color = value
                    end
                else
                    if preset then
                        Animation:To(part, { BackgroundColor3 = value }, preset)
                    else
                        Animation:CancelProperty(part, "BackgroundColor3")
                        part.BackgroundColor3 = value
                    end
                end
            end
        end,
    }
end
local Button = {}
function Button:Release(input, force)
    local capture = self.Capture
    if not capture then
        return
    end
    local same = input == capture.Input
        or (
            input
            and input.UserInputType == Enum.UserInputType.MouseButton1
            and capture.Input.UserInputType == Enum.UserInputType.MouseButton1
        )
    if not force and not same then
        return
    end
    self.Capture = nil
    local control = capture.Control
    control.Pressed = false
    if control.Scope.Alive and control.Root.Parent then
        control:Apply()
    end
end
function Button.new(parent, name, text, accent, iconName, onActivated, scope, allowed)
    scope = scope or Runtime
    local self = { Disabled = false, Hovered = false, Pressed = false, Scope = scope }
    scope.Finalizers[#scope.Finalizers + 1] = function()
        if Button.Capture and Button.Capture.Control == self then
            Button.Capture = nil
        end
    end
    self.Root = create("TextButton", {
        Name = name,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        BackgroundColor3 = accent and Theme.AccentHover or Theme.Input,
        Active = true,
        Selectable = true,
    }, parent)
    corner(self.Root, Theme.Radius)
    self.HoverStroke = stroke(self.Root, Theme.Accent, 1, 1)
    self.Scale = create("UIScale", { Scale = 1 }, self.Root)
    if accent then
        Material:Tone(self.Root)
        self.SurfaceRim = Material:Rim(self.Root, Theme.Text, 0.84)
    end
    self.Label = label(self.Root, "Label", text, 13, accent and Theme.ButtonText or Theme.Text, Theme.Medium)
    self.Label.TextXAlignment = Enum.TextXAlignment.Center
    self.Label.TextTruncate = Enum.TextTruncate.AtEnd
    self.Label.Size = UDim2.fromScale(1, 1)
    if iconName then
        self.Icon = Icon.new(self.Root, iconName, accent and Theme.ButtonText or Theme.Text, 18)
        self.Icon.Root.AnchorPoint = Vector2.new(0, 0.5)
        self.Icon.Root.Position = UDim2.new(0, 14, 0.5, 0)
        self.Label.Position = UDim2.fromOffset(36, 0)
        self.Label.Size = UDim2.new(1, -44, 1, 0)
    end
    function self:Apply()
        local preset = self.Pressed and Motion.Press or Motion.Hover
        local base = accent and Theme.AccentHover
            or self.ContextHovered and Theme.AccentDark
            or self.BaseColor
            or Theme.Input
        local color = self.Disabled and base:Lerp(Theme.Surface, 0.48)
            or self.Pressed and base:Lerp(Theme.Surface, 0.16)
            or self.Hovered and base:Lerp(Theme.Text, accent and 0.045 or 0.035)
            or base
        Animation:To(self.Root, { BackgroundColor3 = color }, preset)
        if self.Gradient then
            Animation:To(
                self.Gradient,
                { Offset = Vector2.new(self.Hovered and not self.Disabled and 0.045 or 0, 0) },
                Motion.Hover
            )
        end
        Animation:To(self.HoverStroke, {
            Color = accent and Theme.AccentText or Theme.Line,
            Transparency = self.Disabled and 1
                or (self.Ghost or self.Navigation) and 1
                or self.Hovered and 0.35
                or accent and 0.65
                or 1,
        }, preset)
        local textColor = self.Disabled and Theme.Muted or self.TextColor or (accent and Theme.ButtonText or Theme.Text)
        if self.Navigation then
            Animation:To(self.Root, {
                BackgroundTransparency = self.Hovered and not self.Selected and 0.55 or 1,
            }, preset)
            textColor = self.Disabled and Theme.Muted
                or (self.Selected or self.Hovered) and Theme.Text
                or Theme.Secondary
        elseif self.Ghost then
            Animation:To(self.Root, {
                BackgroundTransparency = self.Disabled and 1 or self.Pressed and 0.25 or self.Hovered and 0.5 or 1,
            }, preset)
        end
        Animation:To(self.Label, { TextColor3 = textColor }, preset)
        if self.NavHint then
            self.NavHint.TextColor3 = self.Disabled and Theme.Muted or self.Selected and Theme.Secondary or Theme.Muted
        end
        if self.Icon then
            self.Icon:SetColor(
                self.Navigation and (self.Selected and Theme.AccentText or textColor) or textColor,
                preset
            )
        end
        if self.SurfaceRim then
            Animation:To(self.SurfaceRim, {
                BackgroundTransparency = self.Disabled and 1 or self.Pressed and 0.96 or self.Hovered and 0.76 or 0.84,
            }, preset)
        end
        self.Root.Selectable = not self.Disabled
        -- Surface/ink feedback, never a small layout jump on every press.
        Animation:To(self.Scale, { Scale = 1 }, Motion.Press)
    end
    function self:SetDisabled(value)
        if Button.Capture and Button.Capture.Control == self then
            Button:Release(nil, true)
        end
        self.Disabled = value == true
        self.Pressed = false
        if self.Disabled then
            self.Hovered = false
        end
        self:Apply()
    end
    local function enabled()
        return not self.Disabled and (allowed or canInteract)()
    end
    scope:Connect(self.Root.MouseEnter, function()
        if enabled() then
            self.Hovered = true
            self:Apply()
            if Accessibility then
                Accessibility:Tooltip(self.Root)
            end
        end
    end)
    scope:Connect(self.Root.MouseLeave, function()
        if Accessibility and Accessibility.TooltipRoot == self.Root then
            Accessibility:HideTooltip()
        end
        self.Hovered = false
        self.Pressed = false
        self:Apply()
    end)
    scope:Connect(self.Root.SelectionGained, function()
        if Accessibility then
            Accessibility:Selection(self.Root, true)
        end
        if enabled() then
            self.Hovered = true
            self:Apply()
        end
    end)
    scope:Connect(self.Root.SelectionLost, function()
        if Accessibility then
            Accessibility:Selection(self.Root, false)
        end
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
            Button:Release(nil, true)
            Button.Capture = { Control = self, Input = input }
            self.Pressed = true
            self:Apply()
        end
    end)
    scope:Connect(self.Root.InputEnded, function(input)
        if Button.Capture and Button.Capture.Control == self then
            Button:Release(input)
        end
    end)
    function self:Activate()
        if not enabled() then
            return false
        end
        if Button.Capture and Button.Capture.Control == self then
            Button:Release(nil, true)
        end
        self.Pressed = false
        self:Apply()
        onActivated()
        return true
    end
    scope:Connect(self.Root.Activated, function()
        if
            Accessibility
            and Accessibility.KeyboardRoot == self.Root
            and os.clock() - (Accessibility.KeyboardAt or -1) < 0.12
        then
            return
        end
        self:Activate()
    end)
    if Accessibility then
        Accessibility:Register(self.Root, self, enabled)
    end
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
        gameCopy = "A supported Roblox experience. Inspect details, then launch.",
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
        gameCopy = "Поддерживаемая игра Roblox. Посмотрите описание, затем запускайте.",
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
        gameCopy = "Una experiencia de Roblox compatible. Consulta los detalles y luego inicia.",
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
        gameCopy = "Uma experiência Roblox compatível. Veja os detalhes e depois inicie.",
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
            authChecking = "Checking your key…",
            authSlow = "Still waiting for verification…",
            authGranted = "Access verified",
            authFailed = "Could not verify access",
            pasteKey = "Paste",
            forgetKey = "Forget",
            rememberMe = "Remember Me",
            keyRememberUnavailable = "Saved-key management is unavailable",
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
            authChecking = "Validando tu key…",
            authSlow = "Seguimos esperando la validación…",
            authGranted = "Acceso verificado",
            authFailed = "No se pudo verificar el acceso",
            pasteKey = "Pegar",
            forgetKey = "Olvidar",
            rememberMe = "Recordarme",
            keyRememberUnavailable = "No se puede gestionar la key guardada",
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
            authChecking = "Validando sua key…",
            authSlow = "Ainda aguardando a validação…",
            authGranted = "Acesso verificado",
            authFailed = "Não foi possível verificar o acesso",
            pasteKey = "Colar",
            forgetKey = "Esquecer",
            rememberMe = "Lembrar de mim",
            keyRememberUnavailable = "Gerenciamento da key salva indisponível",
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
            authChecking = "Проверяем ключ…",
            authSlow = "Ждём подтверждения…",
            authGranted = "Доступ подтверждён",
            authFailed = "Не удалось подтвердить доступ",
            pasteKey = "Вставить",
            forgetKey = "Забыть",
            rememberMe = "Запомнить меня",
            keyRememberUnavailable = "Управление сохранённым ключом недоступно",
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

do
    local qualityCopy = {
        en = {
            homeHeroA = "Your key.",
            homeHeroB = "Your access.",
            homeCopy = "Verify once. Get straight to your game.",
            fieldLabel = "License key",
            keyGuidance = "Paste your license key to continue.",
            homeNav = "Home",
            gamesNav = "Supported Games",
            licensesNav = "License Keys",
            refreshNav = "Refresh",
            journeyKey = "Check key",
            journeyVerified = "Verified",
            journeyReady = "Ready",
            handoffReady = "The script starts after this window closes.",
            journeyHint = "Acceptance is confirmed by your validator.",
            gameInspect = "View game details",
            gameLaunch = "Launch",
            gameAbout = "About this script",
            currentBadge = "Current game",
            currentBadgeShort = "Current",
            moreDetails = "Details",
        },
        es = {
            homeHeroA = "Tu key.",
            homeHeroB = "Tu acceso.",
            homeCopy = "Valida una vez. Entra directo a tu juego.",
            fieldLabel = "Clave de licencia",
            keyGuidance = "Pega tu clave de licencia para continuar.",
            homeNav = "Inicio",
            gamesNav = "Juegos compatibles",
            licensesNav = "Claves de licencia",
            refreshNav = "Actualizar",
            journeyKey = "Validar key",
            journeyVerified = "Verificada",
            journeyReady = "Listo",
            handoffReady = "El script inicia al cerrar esta ventana.",
            journeyHint = "La aceptación la confirma tu validador.",
            gameInspect = "Ver detalles del juego",
            gameLaunch = "Iniciar",
            gameAbout = "Acerca del script",
            currentBadge = "Juego actual",
            currentBadgeShort = "Actual",
            moreDetails = "Detalles",
        },
        pt = {
            homeHeroA = "Sua key.",
            homeHeroB = "Seu acesso.",
            homeCopy = "Valide uma vez. Vá direto para o jogo.",
            fieldLabel = "Chave de licença",
            keyGuidance = "Cole sua chave de licença para continuar.",
            homeNav = "Início",
            gamesNav = "Jogos compatíveis",
            licensesNav = "Chaves de licença",
            refreshNav = "Atualizar",
            journeyKey = "Validar key",
            journeyVerified = "Verificada",
            journeyReady = "Pronto",
            handoffReady = "O script inicia após fechar esta janela.",
            journeyHint = "A aceitação é confirmada pelo validador.",
            gameInspect = "Ver detalhes do jogo",
            gameLaunch = "Iniciar",
            gameAbout = "Sobre este script",
            currentBadge = "Jogo atual",
            currentBadgeShort = "Atual",
            moreDetails = "Detalhes",
        },
        ru = {
            homeHeroA = "Ваш ключ.",
            homeHeroB = "Ваш доступ.",
            homeCopy = "Подтвердите ключ и переходите к игре.",
            fieldLabel = "Ключ лицензии",
            keyGuidance = "Вставьте ключ лицензии для продолжения.",
            homeNav = "Главная",
            gamesNav = "Поддерживаемые игры",
            licensesNav = "Ключи лицензии",
            refreshNav = "Обновить",
            journeyKey = "Проверка",
            journeyVerified = "Подтверждён",
            journeyReady = "Готово",
            handoffReady = "Скрипт запустится после закрытия окна.",
            journeyHint = "Доступ подтверждает ваш валидатор.",
            gameInspect = "Подробнее об игре",
            gameLaunch = "Запуск",
            gameAbout = "Об этом скрипте",
            currentBadge = "Текущая игра",
            currentBadgeShort = "Здесь",
            moreDetails = "Подробнее",
        },
    }
    for id, values in pairs(qualityCopy) do
        for key, value in pairs(values) do
            Translations[id][key] = value
        end
    end
end

do
    local copy = {
        en = {
            accessSceneTitle = "You're in.",
            accessSceneVerified = "Access verified",
            accessSceneHandoff = "Your script starts after this window closes.",
            accessSceneClosing = "Closing this window",
            accessSceneMessage = "Your key has been accepted.",
        },
        es = {
            accessSceneTitle = "Ya estás dentro.",
            accessSceneVerified = "Acceso verificado",
            accessSceneHandoff = "Tu script empieza después de cerrar esta ventana.",
            accessSceneClosing = "Cerrando esta ventana",
            accessSceneMessage = "Tu key ha sido aceptada.",
        },
        pt = {
            accessSceneTitle = "Você entrou.",
            accessSceneVerified = "Acesso verificado",
            accessSceneHandoff = "Seu script começa depois que esta janela fechar.",
            accessSceneClosing = "Fechando esta janela",
            accessSceneMessage = "Sua chave foi aceita.",
        },
        ru = {
            accessSceneTitle = "Доступ открыт.",
            accessSceneVerified = "Доступ подтверждён",
            accessSceneHandoff = "Скрипт запустится после закрытия этого окна.",
            accessSceneClosing = "Закрываем это окно",
            accessSceneMessage = "Ваш ключ принят.",
        },
    }
    for id, values in pairs(copy) do
        for key, value in pairs(values) do
            Translations[id][key] = value
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
            offerTab = "License Keys",
            offerMonthlyBadge = "MONTHLY ACCESS",
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
            offerTab = "Claves de licencia",
            offerMonthlyBadge = "ACCESO MENSUAL",
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
            offerTab = "Chaves de licença",
            offerMonthlyBadge = "ACESSO MENSAL",
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
            offerTab = "Ключи лицензии",
            offerMonthlyBadge = "МЕСЯЧНЫЙ ДОСТУП",
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
do
    local polish = {
        en = {
            offerHaveKey = "Already have a key?",
            diagShow = "Show diagnostics",
            diagHide = "Hide diagnostics",
            diagTitle = "UI diagnostics",
            diagBuild = "UI build",
            diagReady = "UI ready",
            diagValidation = "Last validation",
            diagHandoff = "UI handoff",
            diagNote = "Measured UI timings only. No key or personal data. Excludes download and Script().",
            diagNotMeasured = "Not measured",
            diagPending = "In progress",
            diagCopied = "Diagnostics copied. No key included.",
            secondaryCommunity = "Community",
            tipAuth = "Authorization",
            tipProducts = "Supported games",
            tipRefresh = "Refresh loader",
            tipLanguage = "Change language",
        },
        es = {
            offerHaveKey = "¿Ya tienes una key?",
            diagShow = "Ver diagnóstico",
            diagHide = "Ocultar diagnóstico",
            diagTitle = "Diagnóstico de UI",
            diagBuild = "Construcción UI",
            diagReady = "UI lista",
            diagValidation = "Última validación",
            diagHandoff = "Entrega UI",
            diagNote = "Solo tiempos medidos de UI. Sin key ni datos personales. Excluye descarga y Script().",
            diagNotMeasured = "Sin medición",
            diagPending = "En curso",
            diagCopied = "Diagnóstico copiado. Sin key.",
            secondaryCommunity = "Comunidad",
            tipAuth = "Autorización",
            tipProducts = "Juegos compatibles",
            tipRefresh = "Actualizar loader",
            tipLanguage = "Cambiar idioma",
        },
        pt = {
            offerHaveKey = "Já tem uma key?",
            diagShow = "Ver diagnóstico",
            diagHide = "Ocultar diagnóstico",
            diagTitle = "Diagnóstico da UI",
            diagBuild = "Construção UI",
            diagReady = "UI pronta",
            diagValidation = "Última validação",
            diagHandoff = "Entrega UI",
            diagNote = "Apenas tempos medidos da UI. Sem key ou dados pessoais. Exclui download e Script().",
            diagNotMeasured = "Não medido",
            diagPending = "Em andamento",
            diagCopied = "Diagnóstico copiado. Sem key.",
            secondaryCommunity = "Comunidade",
            tipAuth = "Autorização",
            tipProducts = "Jogos compatíveis",
            tipRefresh = "Atualizar loader",
            tipLanguage = "Mudar idioma",
        },
        ru = {
            offerHaveKey = "Уже есть ключ?",
            diagShow = "Показать диагностику",
            diagHide = "Скрыть диагностику",
            diagTitle = "Диагностика UI",
            diagBuild = "Создание UI",
            diagReady = "UI готов",
            diagValidation = "Последняя проверка",
            diagHandoff = "Передача UI",
            diagNote = "Только измерения UI. Без ключа и личных данных. Не включает загрузку и Script().",
            diagNotMeasured = "Не измерено",
            diagPending = "В процессе",
            diagCopied = "Диагностика скопирована. Без ключа.",
            secondaryCommunity = "Сообщество",
            tipAuth = "Авторизация",
            tipProducts = "Поддерживаемые игры",
            tipRefresh = "Обновить загрузчик",
            tipLanguage = "Изменить язык",
        },
    }
    for language, values in pairs(polish) do
        for key, value in pairs(values) do
            Translations[language][key] = value
        end
    end
end
do
    Translations.en.keyLinkLoading = "Getting your key link…"
    Translations.es.keyLinkLoading = "Obteniendo el enlace de tu key…"
    Translations.pt.keyLinkLoading = "Obtendo o link da sua key…"
    Translations.ru.keyLinkLoading = "Получение ссылки на ключ…"
end
do
    local external = {
        en = {
            externalUnconfirmed = "FlowAuth did not confirm this run.",
            externalRestart = "Close this prompt and rerun the FlowAuth loader. If a run is still pending, restart the executor.",
            externalKeyLong = "Keys must contain at most 512 bytes.",
            accessLifetime = "Lifetime",
        },
        es = {
            externalUnconfirmed = "FlowAuth no confirmó esta ejecución.",
            externalRestart = "Cierra esta ventana y ejecuta de nuevo el loader de FlowAuth. Si sigue pendiente, reinicia el executor.",
            externalKeyLong = "Las keys deben tener como máximo 512 bytes.",
            accessLifetime = "Lifetime",
        },
        pt = {
            externalUnconfirmed = "O FlowAuth não confirmou esta execução.",
            externalRestart = "Feche esta janela e execute o loader FlowAuth novamente. Se continuar pendente, reinicie o executor.",
            externalKeyLong = "As keys devem ter no máximo 512 bytes.",
            accessLifetime = "Vitalício",
        },
        ru = {
            externalUnconfirmed = "FlowAuth не подтвердил этот запуск.",
            externalRestart = "Закройте окно и снова запустите загрузчик FlowAuth. Если запрос ещё ожидается, перезапустите исполнитель.",
            externalKeyLong = "Ключ не должен превышать 512 байт.",
            accessLifetime = "Бессрочно",
        },
    }
    for language, values in pairs(external) do
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
-- Neron-family copy, shared by headings, controls and accessible labels.
do
    local copy = {
        en = {
            homeNav = "Access",
            pageAccess = "Verify your key to continue.",
            pageGames = "Browse supported experiences.",
            pageLicenses = "Choose the access that fits you.",
            signIn = "Verify key",
            getKey = "Get a free key",
            fieldLabel = "License key",
            keyHint = "Paste your key",
            closeLoader = "Close loader",
            preferencesTitle = "Preferences",
            motionOption = "Motion",
            asideTitle = "One key. Your access.",
            asideCopy = "Enter your key, or get a free key to continue. Verification stays in your hands.",
            offerChooseLifetime = "Open store",
            offerChooseMonthly = "Open store",
            offerSubhead = "Monthly or lifetime. Your choice.",
            communityDockTitle = "Join Discord",
            communityDockSubtitle = "Support and the Plak community",
        },
        es = {
            homeNav = "Acceso",
            pageAccess = "Verifica tu key para continuar.",
            pageGames = "Explora las experiencias compatibles.",
            pageLicenses = "Elige el acceso que va contigo.",
            signIn = "Verificar key",
            getKey = "Obtener key gratis",
            fieldLabel = "Key de licencia",
            keyHint = "Pega tu key",
            closeLoader = "Cerrar loader",
            preferencesTitle = "Preferencias",
            motionOption = "Animación",
            asideTitle = "Una key. Tu acceso.",
            asideCopy = "Introduce tu key u obtén una gratis para continuar. Tú decides cuándo verificar.",
            offerChooseLifetime = "Abrir tienda",
            offerChooseMonthly = "Abrir tienda",
            offerSubhead = "Mensual o de por vida. Tú eliges.",
            communityDockTitle = "Únete a Discord",
            communityDockSubtitle = "Soporte y la comunidad de Plak",
        },
        pt = {
            homeNav = "Acesso",
            pageAccess = "Verifique sua key para continuar.",
            pageGames = "Explore as experiências compatíveis.",
            pageLicenses = "Escolha o acesso ideal para você.",
            signIn = "Verificar key",
            getKey = "Obter key grátis",
            fieldLabel = "Key de licença",
            keyHint = "Cole sua key",
            closeLoader = "Fechar loader",
            preferencesTitle = "Preferências",
            motionOption = "Animação",
            asideTitle = "Uma key. Seu acesso.",
            asideCopy = "Insira sua key ou obtenha uma grátis para continuar. Você decide quando verificar.",
            offerChooseLifetime = "Abrir loja",
            offerChooseMonthly = "Abrir loja",
            offerSubhead = "Mensal ou vitalício. Você escolhe.",
            communityDockTitle = "Entre no Discord",
            communityDockSubtitle = "Suporte e a comunidade Plak",
        },
        ru = {
            homeNav = "Доступ",
            pageAccess = "Проверьте ключ, чтобы продолжить.",
            pageGames = "Посмотрите поддерживаемые игры.",
            pageLicenses = "Выберите подходящий вариант доступа.",
            signIn = "Проверить ключ",
            getKey = "Получить бесплатный ключ",
            fieldLabel = "Лицензионный ключ",
            keyHint = "Вставьте ключ",
            closeLoader = "Закрыть загрузчик",
            preferencesTitle = "Настройки",
            motionOption = "Анимация",
            asideTitle = "Один ключ. Ваш доступ.",
            asideCopy = "Введите ключ или получите бесплатный, чтобы продолжить. Вы сами запускаете проверку.",
            offerChooseLifetime = "Открыть магазин",
            offerChooseMonthly = "Открыть магазин",
            offerSubhead = "На месяц или навсегда. Выбирайте.",
            communityDockTitle = "Наш Discord",
            communityDockSubtitle = "Поддержка и сообщество Plak",
        },
    }
    for language, values in pairs(copy) do
        values.journeyKey = values.signIn
        for key, value in pairs(values) do
            Translations[language][key] = value
        end
    end
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
    corner(self.Root, Theme.PanelRadius)
    self.Root.ClipsDescendants = true
    self.Fallback = frame(self.Root, "Fallback", Theme.Surface)
    self.Fallback.Size = UDim2.fromScale(1, 1)
    gradient(self.Fallback, Theme.AccentMuted, Theme.Surface, 75)
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
    corner(self.Image, Theme.PanelRadius)
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
    self.Root = frame(parent, name or "PlakWordmark", Theme.Elevated)
    self.Root.ClipsDescendants = true
    corner(self.Root, Theme.PanelRadius)
    gradient(self.Root, Theme.AccentMuted, Theme.Surface, 74)
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
    local inset = frame(self.Stage, "InkField", Theme.Content)
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
            local cut = frame(parentObject, "CornerCounter", Theme.Content)
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
        local face = index <= 2 and Theme.Text or Theme.Accent
        for _, spec in ipairs(BrandArt.Glyphs[data[1]]) do
            segment(letter, spec, Theme.AccentDark, 7, 9, false)
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
    corner(self.OverrideImage, Theme.PanelRadius)
    local function settle()
        if self.Alive and self.OverrideImage then
            self.Stage.Visible = not self.OverrideImage.IsLoaded
        end
    end
    settle()
    self.OverrideConnection = Runtime:Connect(self.OverrideImage:GetPropertyChangedSignal("IsLoaded"), settle)
end
local AccessScene = { View = nil, Mode = nil }
local Modal = { Config = nil, ProgressHandle = nil, SurfaceGeometry = {} }
local Navigation = {}
local Stagecraft = { Token = 0, Tasks = {}, Rests = {}, Groups = {}, HeaderPage = "Auth" }
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
local SUPPORTED_GAMES_URL = "https://raw.githubusercontent.com/Nanana291/Plak/main/Games.json"
local SupportedGamesFallback = {
    { Id = "roll-a-fisherman", GameId = 90920025162454, FallbackName = "Roll a Fisherman", Status = "Available" },
}
local function loadSupportedGames()
    local fetched, response = pcall(function()
        return game:HttpGet(SUPPORTED_GAMES_URL)
    end)
    if fetched and type(response) == "string" and response ~= "" then
        local decodedOk, decoded = pcall(Services.Http.JSONDecode, Services.Http, response)
        if decodedOk and type(decoded) == "table" then
            local catalog = {}
            for _, config in ipairs(decoded) do
                if type(config) == "table" then
                    catalog[#catalog + 1] = config
                end
            end
            if #catalog > 0 or next(decoded) == nil then
                return catalog
            end
        end
    end
    warn("[PlakUi] Failed to load supported games from Games.json; using fallback catalog")
    return SupportedGamesFallback
end
local function productName(product)
    product = product or {}
    return localizedValue(
        product.Name or product.ResolvedName or product.FallbackName,
        Localization:Get(product.GameId and "game" or "umbrella")
    )
end
local GameMedia = { Ready = false, Cache = {}, Pending = {}, Queue = {}, Bindings = {}, Active = nil, Serial = 0 }
function GameMedia:PlaceId(value)
    local id = finite(value, 0)
    return id > 0 and id < 9007199254740992 and id == math.floor(id) and id or nil
end
function GameMedia:Thumbnail(id)
    -- GameThumbnail uses a placeId; GameIcon uses a universeId. Native content works without file APIs.
    return "rbxthumb://type=GameThumbnail&id=" .. string.format("%.0f", id) .. "&w=768&h=432"
end
function GameMedia:GameIcon(universeId)
    local id = self:PlaceId(universeId)
    return id and ("rbxthumb://type=GameIcon&id=" .. string.format("%.0f", id) .. "&w=150&h=150") or ""
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
function GameMedia:Materialize(url, id, kind, valid)
    local host = type(url) == "string" and url:match("^https://([^/]+)/")
    local write, custom = capability("writefile"), capability("getcustomasset") or capability("getsynasset")
    if
        not host
        or not (host == "rbxcdn.com" or host:match("^[%w%-%.]+%.rbxcdn%.com$"))
        or not write
        or not custom
        or not valid()
    then
        return nil
    end
    local bytes = self:Get(url, false, valid)
    if not bytes or bytes:sub(1, 8) ~= "\137PNG\13\10\26\10" or not valid() then
        return nil
    end
    local ok, image = pcall(function()
        local path = "PlakUi_" .. kind .. "_" .. string.format("%.0f", id) .. "_" .. self.Serial .. ".png"
        if not valid() or write(path, bytes) == false or not valid() then
            return nil
        end
        return custom(path)
    end)
    return ok and valid() and assetId(image) or nil
end
function GameMedia:Resolve(placeId, valid, partial)
    local info = partial or { Image = self:Thumbnail(placeId) }
    local current = placeId == self:PlaceId(game.PlaceId)
    local universeId = current and self:PlaceId(game.GameId) or nil
    if not universeId then
        local universe = self:Get(
            "https://apis.roblox.com/universes/v1/places/" .. string.format("%.0f", placeId) .. "/universe",
            true,
            valid
        )
        universeId = universe and self:PlaceId(universe.universeId)
    end
    if universeId then
        info.UniverseId = universeId
        local suffix = string.format("%.0f", universeId)
        if current then
            -- The Home identity is a universe GameIcon, NEVER a place's rectangular thumbnail.
            info.Icon = self:GameIcon(universeId)
            local icons = self:Get(
                "https://thumbnails.roblox.com/v1/games/icons?universeIds="
                    .. suffix
                    .. "&size=150x150&format=Png&isCircular=false",
                true,
                valid
            )
            local icon = icons and type(icons.data) == "table" and icons.data[1]
            if type(icon) == "table" and tonumber(icon.targetId) == universeId and icon.state == "Completed" then
                info.Icon = self:Materialize(icon.imageUrl, universeId, "icon", valid) or info.Icon
            end
            if valid() and Experience then
                Experience:RefreshGame()
            end
        end
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
        info.Image = self:Materialize(url, placeId, "game", valid) or info.Image
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
        Animation:To(item.Root, {
            GroupTransparency = 1,
            Position = item.Root.Position + UDim2.fromOffset(Settings.ReducedMotion and 0 or 8, 0),
        }, Motion.Exit, remove)
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
    item.Root.BackgroundColor3 = Theme.Elevated
    item.Root.BackgroundTransparency = 0
    item.Root.GroupTransparency = 1
    item.Root.Position = UDim2.fromOffset(UI.Stage.AbsoluteSize.X, 12)
    corner(item.Root, Theme.PanelRadius)
    stroke(item.Root, Theme.Line, 1, 0.25)
    Material:Panel(item.Root)
    local accent = config.Type == "warning" and Theme.Warning
        or config.Type == "error" and Theme.Danger
        or config.Type == "success" and Theme.Success
        or Theme.AccentText
    local rail = frame(item.Root, "Accent", accent)
    place(rail, 0, 14, 2, 48)
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
-- A presentation of acceptance, never a validator, progress simulator or host runner.
function AccessScene:Build(parent)
    if self.View then
        return
    end
    local v = {}
    self.View = v
    v.Root = frame(parent, "AccessGrantedScene")
    v.Root.BackgroundTransparency, v.Root.Size = 1, UDim2.fromScale(1, 1)
    v.Graphic = frame(v.Root, "GraphicPlane", Theme.AccentMuted)
    v.Brand = label(v.Graphic, "Brand", Settings.Title, 14, Theme.Text, Theme.Bold)
    v.Art = frame(v.Graphic, "AccessGate")
    v.Art.BackgroundTransparency, v.Art.ClipsDescendants = 1, true
    v.Mark = group(v.Art, "RevealedIdentity")
    v.MarkIcon = Icon.new(v.Mark, "plak", Theme.AccentText, 128)
    for _, segment in ipairs(v.MarkIcon.Root:GetChildren()) do
        if segment:IsA("Frame") then
            segment.Size = UDim2.new(segment.Size.X.Scale, segment.Size.X.Offset, 0, 4)
        end
    end
    v.LeftShutter = frame(v.Art, "LeftGate", Theme.AccentMuted)
    v.RightShutter = frame(v.Art, "RightGate", Theme.AccentMuted)
    v.GateEdge = frame(v.LeftShutter, "Seam", Theme.Line)
    v.GateEdge.Size, v.GateEdge.Position = UDim2.new(0, 1, 1, 0), UDim2.new(1, -1, 0, 0)
    v.Verified = localized(v.Graphic, "Verified", "accessSceneVerified", 12, Theme.AccentText, Theme.Medium)
    v.Verified.TextWrapped, v.Verified.TextTruncate = true, Enum.TextTruncate.AtEnd
    v.MiniMark = Icon.new(v.Root, "plak", Theme.AccentText, 26)
    v.MiniBrand = label(v.Root, "CompactBrand", Settings.Title, 14, Theme.Text, Theme.Bold)
    v.Scroll = create("ScrollingFrame", {
        Name = "AcceptedContext",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        VerticalScrollBarInset = Enum.ScrollBarInset.None,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
        ClipsDescendants = true,
    }, v.Root)
    v.Body = frame(v.Scroll, "Body")
    v.Body.BackgroundTransparency = 1
    v.Title = localized(v.Body, "Title", "accessSceneTitle", 34, Theme.Text, Theme.Bold)
    v.Message = label(v.Body, "AcceptedMessage", "", 13, Theme.Secondary)
    v.ContextDivider = frame(v.Body, "ContextDivider", Theme.Edge)
    v.ContextDivider.BackgroundTransparency = 0.45
    v.Game = label(v.Body, "CurrentExperience", "", 22, Theme.Text, Theme.Bold)
    v.License = label(v.Body, "ActualAccess", "", 12, Theme.AccentText, Theme.Medium)
    for _, text in ipairs({ v.Title, v.Message, v.Game, v.License }) do
        text.TextWrapped, text.TextYAlignment, text.TextTruncate =
            true, Enum.TextYAlignment.Top, Enum.TextTruncate.AtEnd
    end
    v.Divider = frame(v.Root, "FooterDivider", Theme.Edge)
    v.Divider.BackgroundTransparency = 0.45
    v.Note = label(v.Root, "HandoffNote", "", 11, Theme.Secondary)
    v.Note.TextWrapped, v.Note.TextTruncate = true, Enum.TextTruncate.AtEnd
    v.Brand.TextTruncate, v.MiniBrand.TextTruncate = Enum.TextTruncate.AtEnd, Enum.TextTruncate.AtEnd
    Runtime.Finalizers[#Runtime.Finalizers + 1] = function()
        self:Cancel(true)
        v.Root:Destroy()
        self.View, self.Mode, self.MessageValue = nil, nil, nil
        self.LastGame, self.LastLicense, self.LayoutMode = nil, nil, nil
        self.HasHandoff = nil
    end
end
function AccessScene:GameTitle()
    local id = GameMedia:PlaceId(game.PlaceId)
    for _, product in ipairs(State.Products) do
        if id and product.GameId == id then
            return productName(product)
        end
    end
    return Experience.CurrentGameCard and Experience.CurrentGameCard.Product.ResolvedName
        or Localization:Get("currentGame")
end
function AccessScene:Refresh()
    local v = self.View
    if not v or not self.Mode then
        return
    end
    v.Brand.Text, v.MiniBrand.Text = Settings.Title, Settings.Title
    Localization:Bind(v.Message, "accessSceneMessage", "Text", function()
        return self.MessageValue and localizedValue(self.MessageValue) or Localization:Get("accessSceneMessage")
    end)
    Localization:Bind(v.Game, "currentGame", "Text", function()
        return self:GameTitle()
    end)
    local currentGame, license = self:GameTitle(), Experience:LicenseText()
    local changed = self.LastGame ~= currentGame or self.LastLicense ~= license
    self.LastGame, self.LastLicense = currentGame, license
    v.License.Text = license
    Localization:Bind(v.Note, "accessSceneClosing", "Text", function()
        return Localization:Get(self.HasHandoff and "accessSceneHandoff" or "accessSceneClosing")
    end)
    if changed and self.LayoutMode == self.Mode then
        Responsive:Request()
    end
end
function AccessScene:Mount(parent, mode, message)
    self:Build(parent)
    self:Cancel(true)
    self.Mode, self.MessageValue = mode, message
    self.HasHandoff = mode == "exit" and type(State.Callbacks.Authorized) == "function"
    local v = self.View
    v.Root.Parent, v.Root.Visible = parent, true
    v.Scroll.CanvasPosition = Vector2.new(0, 0)
    self:Refresh()
end
function AccessScene:Cancel(settle)
    local v = self.View
    if not v then
        return
    end
    Animation:CancelTree(v.Root)
    if settle then
        v.LeftShutter.Position = self.LeftRest or UDim2.fromOffset(-65, 0)
        v.RightShutter.Position = self.RightRest or UDim2.fromOffset(129, 0)
        v.Mark.GroupTransparency = 0
    end
end
function AccessScene:Hide()
    self:Cancel(true)
    if self.View then
        self.View.Root.Visible = false
    end
    self.Mode, self.MessageValue = nil, nil
    self.HasHandoff = nil
end
function AccessScene:Layout(width, height, settle)
    local v = self.View
    if not v or not self.Mode then
        return
    end
    local wide = width >= 560 and height >= 300
    local short = height < 280
    local pad = width < 280 and 16 or 24
    local x, top = wide and 220 or pad, wide and 28 or short and 18 or 64
    local controlInner = math.max(44, width - x - pad)
    local inner = controlInner
    local titleWidth = math.max(44, inner - (self.Mode == "confirm" and (wide or short) and 44 or 0))
    local titleSize = wide and 34 or short and 24 or 28
    local title = Localization:Get("accessSceneTitle")
    local titleHeight = math.max(titleSize + 6, measure(title, titleSize, Theme.Bold, titleWidth) + 6)
    local footer = self.Mode == "confirm" and 64 or 58
    local bodyTop = math.max(top + titleHeight + 12, self.Mode == "confirm" and 64 or 0)
    -- Fit actual translated lines, not just a fixed viewport breakpoint.
    local ultra = height < 200 or bodyTop + 26 + footer + 12 > height
    if ultra then
        top, bodyTop, titleSize = 18, 18, 18
        inner = math.max(44, controlInner - (self.Mode == "confirm" and 44 or 0))
        titleWidth = inner
        titleHeight = math.max(24, measure(title, titleSize, Theme.Bold, titleWidth) + 6)
    end
    v.Graphic.Visible = wide
    place(v.Graphic, 0, 0, 192, height)
    place(v.Brand, 24, 20, 144, 24)
    place(v.Art, 32, (height - 128) / 2, 128, 128)
    place(v.Mark, 0, 0, 128, 128)
    place(v.MarkIcon.Root, 0, 0, 128, 128)
    v.LeftShutter.Size, v.RightShutter.Size = UDim2.fromOffset(65, 128), UDim2.fromOffset(65, 128)
    self.LeftRest, self.RightRest = UDim2.fromOffset(-65, 0), UDim2.fromOffset(129, 0)
    place(v.Verified, 24, height - 58, 144, 38)
    v.MiniMark.Root.Visible, v.MiniBrand.Visible =
        not wide and not short and not ultra, not wide and not short and not ultra
    place(v.MiniMark.Root, pad, 18, 26, 26)
    place(v.MiniBrand, pad + 38, 17, width - pad * 2 - 82, 28)
    v.Title.TextSize = titleSize
    -- At the minimum supported height, the entire heading/context scrolls in a lane beside Close.
    v.Title.Parent = ultra and v.Body or v.Root
    local message = self.MessageValue and localizedValue(self.MessageValue) or Localization:Get("accessSceneMessage")
    local messageHeight = math.clamp(measure(message, 13, Theme.Font, inner - 8) + 4, 24, 100)
    local gameSize = ultra and 16 or 22
    v.Game.TextSize = gameSize
    local gameHeight = math.clamp(measure(self:GameTitle(), gameSize, Theme.Bold, inner - 8) + 4, 28, 72)
    local licenseHeight = math.clamp(measure(Experience:LicenseText(), 12, Theme.Medium, inner - 8) + 4, 20, 48)
    place(v.Title, ultra and 0 or x, ultra and 0 or top, titleWidth, titleHeight)
    local viewportHeight = math.max(20, height - footer - bodyTop - 12)
    local messageY = ultra and titleHeight + 8 or 0
    place(v.Message, 0, messageY, inner - 8, messageHeight)
    local contextY = math.max(messageY + messageHeight + 20, viewportHeight - gameHeight - 6 - licenseHeight - 16)
    place(v.ContextDivider, 0, contextY - 10, inner - 8, 1)
    place(v.Game, 0, contextY, inner - 8, gameHeight)
    place(v.License, 0, contextY + gameHeight + 6, inner - 8, licenseHeight)
    local bodyHeight = math.max(viewportHeight, contextY + gameHeight + 6 + licenseHeight + 8)
    place(v.Scroll, x, bodyTop, inner, viewportHeight)
    v.Body.Size, v.Scroll.CanvasSize = UDim2.fromOffset(inner, bodyHeight), UDim2.fromOffset(0, bodyHeight)
    v.Scroll.ScrollingEnabled = bodyHeight > viewportHeight
    v.Scroll.CanvasPosition =
        Vector2.new(0, math.clamp(v.Scroll.CanvasPosition.Y, 0, math.max(0, bodyHeight - viewportHeight)))
    place(v.Divider, x, height - footer - 2, controlInner, 1)
    v.Note.Visible = self.Mode ~= "confirm"
    place(v.Note, x + 24, height - 46, controlInner - 24, 34)
    if self.Mode == "confirm" then
        place(UI.ResultAction.Root, x, height - 56, controlInner, 44)
        place(UI.ResultClose.Root, width - 52, 12, 44, 44)
    else
        place(UI.ProgressCheck.Root, x, height - 37, 14, 14)
        UI.ProgressCheck:SetColor(Theme.AccentText)
    end
    local changed = self.LayoutWidth ~= width or self.LayoutHeight ~= height or self.LayoutMode ~= self.Mode
    self.LayoutWidth, self.LayoutHeight, self.LayoutMode = width, height, self.Mode
    if changed or (settle and Settings.ReducedMotion) then
        self:Cancel(true)
    end
end
function AccessScene:Reveal()
    local v = self.View
    if not v then
        return
    end
    self:Cancel(true)
    if not Settings.ReducedMotion and v.Graphic.Visible then
        v.LeftShutter.Position, v.RightShutter.Position = UDim2.fromOffset(0, 0), UDim2.fromOffset(64, 0)
        v.Mark.GroupTransparency = 0.45
        Animation:To(v.LeftShutter, { Position = self.LeftRest }, Motion.AccessGate)
        Animation:To(v.RightShutter, { Position = self.RightRest }, Motion.AccessGate)
        Animation:To(v.Mark, { GroupTransparency = 0 }, Motion.AccessGate)
    end
end
function AccessScene:ScrollKey(key)
    local v = self.View
    if
        not State.Alive
        or not State.Visible
        or State.Activity ~= "Idle"
        or State.Modal ~= "result"
        or self.Mode ~= "confirm"
        or not v
        or not v.Root.Visible
        or not v.Scroll.ScrollingEnabled
    then
        return false
    end
    local direction = key == Enum.KeyCode.PageDown and 1 or key == Enum.KeyCode.PageUp and -1 or 0
    if direction == 0 then
        return false
    end
    local height = v.Scroll.Size.Y.Offset
    local bottom = math.max(0, v.Scroll.CanvasSize.Y.Offset - height)
    v.Scroll.CanvasPosition =
        Vector2.new(0, math.clamp(v.Scroll.CanvasPosition.Y + direction * math.max(20, height - 16), 0, bottom))
    return true
end
-- A queued layout must compare canonical bounds, not animated positions.
function Modal:PlaceSurface(root, width, height, position, settleMotion)
    local size = UDim2.fromOffset(width, height)
    local previous = self.SurfaceGeometry[root]
    local changed = not previous or previous.Size ~= size or previous.Position ~= position
    self.SurfaceGeometry[root] = { Size = size, Position = position }
    root.Size = size
    if changed then
        Animation:CancelProperty(root, "Position")
        root.Position = position
        if settleMotion and root.Visible then
            Animation:CancelProperty(root, "GroupTransparency")
            root.GroupTransparency = 0
            if root == UI.Result then
                Animation:CancelProperty(UI.ResultScale, "Scale")
                UI.ResultScale.Scale = 1
            end
        end
    end
end
function Modal:Layout(settleMotion)
    local size = UI.Stage.AbsoluteSize
    if settleMotion then
        if not State.Modal and UI.Overlay.Visible then
            self:Close(true)
        end
    end
    local verified = State.Authorized and self.Config and self.Config.VerifiedAccess == true
    local width = verified and math.min(620, math.max(128, size.X - 24)) or math.min(420, math.max(200, size.X - 24))
    local height = verified and math.min(width >= 560 and 360 or 400, math.max(128, size.Y - 24))
        or math.min(320, math.max(180, size.Y - 24))
    local center = State.WindowCenter or size / 2
    center = Vector2.new(
        math.clamp(center.X, width / 2 + 8, math.max(width / 2 + 8, size.X - width / 2 - 8)),
        math.clamp(center.Y, height / 2 + 8, math.max(height / 2 + 8, size.Y - height / 2 - 8))
    )
    self:PlaceSurface(UI.Result, width, height, UDim2.fromOffset(center.X, center.Y), settleMotion)
    local inner = width - 40
    local hasLink = self.Config
        and type(self.Config.Link) == "string"
        and self.Config.Link ~= ""
        and not self.Config.CopyText
        and height >= 300
    place(UI.ResultSymbol, 20, 20, 32, 32)
    place(UI.ResultIcon.Root, 7, 7, 18, 18)
    place(UI.ResultTitle, 64, 17, width - 120, 42)
    local support = height >= 280
    local bottom = height - (support and 110 or 76) - (hasLink and 52 or 0)
    place(UI.ResultDescription, 20, 74, inner, math.max(28, bottom - 80))
    place(UI.ResultCopy, 20, 74, inner, math.max(28, bottom - 80))
    place(UI.ResultLink.Root, 20, bottom + 2, inner, 44)
    UI.ResultLink.Root.Visible = hasLink == true
    UI.ResultDivider.Visible, UI.ResultSupport.Visible = support, support
    place(UI.ResultDivider, 20, height - 110, inner, 1)
    place(UI.ResultSupport, 20, height - 100, inner, 28)
    place(UI.ResultAction.Root, 20, height - 64, inner, 44)
    place(UI.ResultClose.Root, width - 48, 12, 44, 44)
    UI.ResultSymbol.Visible, UI.ResultTitle.Visible = not verified, not verified
    if verified then
        UI.ResultDescription.Visible, UI.ResultSupport.Visible, UI.ResultDivider.Visible = false, false, false
        UI.ResultCopy.Visible, UI.ResultLink.Root.Visible = false, false
    end
    local completion = self.AuthCompletion == true and State.Authorized and State.Modal == "progress"
    local progressWidth = completion and math.min(620, math.max(128, size.X - 24))
        or math.min(440, math.max(200, size.X - 24))
    local progressHeight = completion and math.min(progressWidth >= 560 and 340 or 384, math.max(128, size.Y - 24))
        or 76
    local progressCenter = Vector2.new(
        math.clamp(center.X, progressWidth / 2 + 8, math.max(progressWidth / 2 + 8, size.X - progressWidth / 2 - 8)),
        completion
                and math.clamp(
                    center.Y,
                    progressHeight / 2 + 8,
                    math.max(progressHeight / 2 + 8, size.Y - progressHeight / 2 - 8)
                )
            or center.Y
    )
    self:PlaceSurface(
        UI.ProgressPanel,
        progressWidth,
        progressHeight,
        UDim2.fromOffset(progressCenter.X, progressCenter.Y),
        settleMotion
    )
    place(UI.ProgressText, completion and 52 or 20, 12, progressWidth - (completion and 72 or 100), 26)
    if UI.ProgressCheck then
        place(UI.ProgressCheck.Root, 20, 16, 20, 20)
        place(UI.ProgressLicense, 20, 42, progressWidth - 40, 22)
        UI.ProgressLicense.Visible, UI.ProgressPercent.Visible = false, not completion
    end
    UI.ProgressText.Visible, UI.ProgressTrack.Visible = not completion, not completion
    place(UI.ProgressPercent, progressWidth - 80, 12, 60, 26)
    place(UI.ProgressTrack, 20, completion and 76 or 48, progressWidth - 40, 4)
    if AccessScene.Mode == "confirm" and verified then
        AccessScene:Layout(width, height, settleMotion)
    elseif AccessScene.Mode == "exit" and completion then
        AccessScene:Layout(progressWidth, progressHeight, settleMotion)
    end
end

function Modal:Refresh()
    local config = self.Config
    if not config then
        return
    end
    UI.ResultClose.Root:SetAttribute("ActionLabel", Localization:Get("close"))
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
    local verified = State.Authorized and config.VerifiedAccess == true
    UI.ResultAction.BaseColor = verified and Theme.AccentHover or Theme.Input
    UI.ResultAction.TextColor = verified and Theme.ButtonText or nil
    UI.ResultAction:Apply()
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
    local semantic = kind == "success" and Theme.Success
        or kind == "error" and Theme.Danger
        or (kind == "warning" or kind == "disabled") and Theme.Warning
        or Theme.AccentText
    UI.ResultSymbol.BackgroundColor3 = semantic
    UI.ResultSymbol.BackgroundTransparency = 0.90
    UI.ResultIcon:SetColor(semantic)
    UI.ResultCopy.Visible = config.CopyText ~= nil
    UI.ResultCopy.Text = config.CopyText or ""
    self:Layout()
    UI.ResultDescription.Visible = config.CopyText == nil and not verified
end
function Modal:Open(config)
    if not State.Alive then
        return
    end
    Stagecraft:Cancel(true)
    Experience.OptionsOpen = false
    Experience:RefreshOptions()
    Accessibility:CaptureModal()
    State.ModalToken = State.ModalToken + 1
    if LicenseOffer then
        LicenseOffer:CancelReveal()
    end
    self.Config = config or {}
    self.AuthCompletion = false
    if State.Authorized and self.Config.VerifiedAccess == true then
        AccessScene:Mount(UI.Result, "confirm", self.Config.Description)
    else
        AccessScene:Hide()
    end
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
    UI.ResultScale.Scale = Settings.ReducedMotion and 1 or 0.992
    local destination = self.SurfaceGeometry[UI.Result].Position
    UI.Result.Position = destination + UDim2.fromOffset(0, Settings.ReducedMotion and 0 or Motion.PanelDistance)
    Animation:To(UI.Backdrop, { BackgroundTransparency = 0.48 }, Motion.Enter)
    Animation:To(UI.Result, { GroupTransparency = 0, Position = destination }, Motion.Enter)
    Animation:To(UI.ResultScale, { Scale = 1 }, Motion.Enter)
    if AccessScene.Mode == "confirm" then
        AccessScene:Reveal()
    end
end
function Modal:Close(immediate)
    if not State.Alive then
        return
    end
    State.ModalToken = State.ModalToken + 1
    AccessScene:Cancel(true)
    local token = State.ModalToken
    if LicenseOffer then
        LicenseOffer:CancelReveal()
    end
    self.Config = nil
    State.Modal = nil
    reconcile()
    Accessibility:HideTooltip()
    Accessibility:Layout()
    local function finish()
        if token == State.ModalToken then
            UI.Overlay.Visible = false
            UI.Result.Visible = false
            UI.ProgressPanel.Visible = false
            AccessScene:Hide()
            Localization.Bindings[UI.ResultTitle] = nil
            Localization.Bindings[UI.ResultDescription] = nil
            Accessibility:RestoreModal()
        end
    end
    if immediate or not State.Visible then
        Animation:CancelTree(UI.Overlay)
        finish()
    else
        UI.ResultAction:SetDisabled(true)
        Animation:To(UI.Backdrop, { BackgroundTransparency = 1 }, Motion.Exit)
        local panel = UI.Result.Visible and UI.Result or UI.ProgressPanel
        Animation:To(panel, {
            GroupTransparency = 1,
            Position = panel.Position + UDim2.fromOffset(0, Settings.ReducedMotion and 0 or Motion.PanelDistance),
        }, Motion.Exit, finish)
    end
end
function Modal:Loading(config)
    if not State.Alive then
        return
    end
    Stagecraft:Cancel(true)
    Experience.OptionsOpen = false
    Experience:RefreshOptions()
    if type(config) == "string" then
        config = { Text = config }
    end
    config = config or {}
    if LicenseOffer then
        LicenseOffer:CancelReveal()
    end
    Accessibility:CaptureModal()
    self.AuthCompletion = config.AuthCompletion == true and State.Authorized
    if self.AuthCompletion then
        AccessScene:Mount(UI.ProgressPanel, "exit", config.Text)
    else
        AccessScene:Hide()
    end
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
    local destination = self.SurfaceGeometry[UI.ProgressPanel].Position
    UI.ProgressPanel.Position = destination + UDim2.fromOffset(0, Motion.PanelDistance)
    Animation:To(UI.ProgressPanel, { GroupTransparency = 0, Position = destination }, Motion.Enter)
    Animation:To(UI.Backdrop, { BackgroundTransparency = 0.48 }, Motion.Enter)
    self:SetText(config.Text)
    self:SetProgress(finite(config.Progress, 0), true)
    if self.AuthCompletion then
        AccessScene:Reveal()
    end
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
    if self.AuthCompletion and AccessScene.Mode == "exit" then
        AccessScene.MessageValue = value
        AccessScene:Refresh()
        self:Layout()
    end
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
    return Diagnostics:Text()
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
            local copied, result = false, nil
            if copy then
                copied, result = pcall(copy, details)
            end
            if copied and result ~= false then
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
        if State.Modal == "result" and State.Activity == "Idle" then
            Modal:Close()
        end
    end)
    UI.Result = group(UI.Overlay, "ResultModal")
    UI.Result.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.Result.BackgroundTransparency = 0
    UI.Result.Active = true
    UI.Result.BackgroundColor3 = Theme.Elevated
    UI.Result.ZIndex = 2
    UI.Result.Visible = false
    corner(UI.Result, Theme.PanelRadius)
    stroke(UI.Result, Theme.WindowEdge, 1, 0.28)
    Material:Panel(UI.Result)
    UI.ResultScale = create("UIScale", { Scale = 1 }, UI.Result)
    UI.ResultSymbol = frame(UI.Result, "Symbol", Theme.Accent)
    corner(UI.ResultSymbol, Theme.Radius)
    UI.ResultIcon = Icon.new(UI.ResultSymbol, "check", Theme.Surface, 24)
    UI.ResultTitle = label(UI.Result, "Title", "", 17, Theme.Text, Theme.Medium)
    UI.ResultTitle.TextXAlignment = Enum.TextXAlignment.Left
    UI.ResultTitle.TextWrapped = true
    UI.ResultTitle.TextTruncate = Enum.TextTruncate.AtEnd
    UI.ResultDescription = label(UI.Result, "Description", "", 13, Theme.Secondary)
    UI.ResultDescription.TextWrapped = true
    UI.ResultDescription.TextYAlignment = Enum.TextYAlignment.Top
    UI.ResultDescription.TextXAlignment = Enum.TextXAlignment.Left
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
    UI.ResultSupport.TextXAlignment = Enum.TextXAlignment.Left
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
    UI.ResultLink.Label.TextColor3 = Theme.AccentText
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
    corner(UI.ProgressPanel, Theme.PanelRadius)
    Material:Panel(UI.ProgressPanel)
    stroke(UI.ProgressPanel, Theme.Line, 1)
    UI.ProgressText = localized(UI.ProgressPanel, "Status", "loading", 14, Theme.Text, Theme.Medium)
    UI.ProgressText.TextTruncate = Enum.TextTruncate.AtEnd
    UI.ProgressPercent = label(UI.ProgressPanel, "Percentage", "0%", 14, Theme.Text, Theme.Medium)
    UI.ProgressCheck = Icon.new(UI.ProgressPanel, "check", Theme.Success, 24)
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
    if UI.LanguageName then
        for _, descriptor in ipairs(Languages) do
            if descriptor.Id == Settings.Language then
                UI.LanguageName.Text = descriptor.Name
                break
            end
        end
    end
    local color = self.Open and Theme.AccentText or self.Hovered and Theme.Text or Theme.Secondary
    UI.LanguageToggle:SetAttribute("Expanded", self.Open)
    Animation:To(UI.LanguageChevron.Root, { Rotation = self.Open and 180 or 0 }, Motion.Hover)
    Animation:To(UI.LanguageChevronScale, { Scale = self.Pressed and 0.94 or self.Hovered and 1.03 or 1 }, Motion.Hover)
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
    local hit = math.max(44, math.ceil(44 / math.max(0.1, State.Layout.Scale or 1)))
    local step = hit + 4
    local menuWidth = math.min(188, math.max(108, width - 16))
    local menuHeight = math.min(200, math.max(56, height - 16))
    local x = math.min(rail + 8, math.max(8, width - menuWidth - 8))
    local y = math.max(8, height - menuHeight - 12)
    self.Position = UDim2.fromOffset(x, y)
    Animation:CancelProperty(UI.LanguageMenu, "Position")
    UI.LanguageMenu.Position = self.Position
    UI.LanguageMenu.Size = UDim2.fromOffset(menuWidth, menuHeight)
    UI.LanguageList.Size = UDim2.fromScale(1, 1)
    UI.LanguageList.CanvasSize = UDim2.fromOffset(0, #Languages * step + 8)
    self.Scrollable = menuHeight < #Languages * step + 8
    UI.LanguageList.ScrollingEnabled = self.Open and self.Scrollable
    if not self.Scrollable then
        UI.LanguageList.CanvasPosition = Vector2.new(0, 0)
    end
    for index, language in ipairs(Languages) do
        local button = UI.LanguageOptions[language.Id]
        place(button.Root, 4, (index - 1) * step + 4, menuWidth - 8, hit)
        place(button.Check.Root, menuWidth - 32, (hit - 12) / 2, 12, 12)
    end
end
function LanguageController:SetOpen(value)
    if Accessibility then
        Accessibility:HideTooltip()
    end
    value = value == true and canInteract()
    if self.Open == value then
        return
    end
    self.Open = value
    self.Pressed = false
    if Accessibility then
        if value then
            self.ReturnFocus = Accessibility.Focused
        else
            local root = self.ReturnFocus
            self.ReturnFocus = nil
            if root and Accessibility.Keyboard then
                Accessibility:Focus(root)
            end
        end
    end
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
            UI.LanguageMenuScale.Scale = Settings.ReducedMotion and 1 or 0.992
        end
        UI.LanguageMenu.Visible = true
        UI.LanguageMenu.Active = true
        Animation:To(UI.LanguageMenuScale, { Scale = 1 }, Motion.Enter)
        Animation:To(UI.LanguageMenu, { Position = self.Position or UI.LanguageMenu.Position }, Motion.Enter)
        Animation:To(UI.LanguageMenu, { GroupTransparency = 0 }, Motion.Enter)
    else
        UI.LanguageMenu.Active = false
        Animation:To(UI.LanguageMenuScale, { Scale = Settings.ReducedMotion and 1 or 0.992 }, Motion.Exit)
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
    corner(UI.Window, Theme.WindowRadius)
    UI.WindowEdge = stroke(UI.Window, Theme.WindowEdge, 1, 0.42)
    UI.WindowRim = Material:Rim(UI.Window, Theme.Rim, 0.91)
    UI.WindowRim.ZIndex = 6
    UI.Scale = create("UIScale", { Scale = 1 }, UI.Window)
    UI.ContentSurface = frame(UI.Window, "ContentSurface", Theme.Content)
    Material:Tone(UI.ContentSurface)
    UI.Header = frame(UI.Window, "Header")
    UI.Header.BackgroundColor3 = Theme.Header
    UI.Header.BackgroundTransparency = 0
    UI.Header.Active = true
    UI.BrandLogo = Icon.new(UI.Header, "plak", Theme.AccentText, 28)
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
        "collapse-window",
        function()
            Loader:Hide()
        end,
        Runtime,
        function()
            return State.Alive and State.Visible
        end
    )
    UI.Minimize.BaseColor = Theme.Header
    UI.Minimize.Ghost = true
    UI.Minimize:Apply()
    UI.Minimize.Root:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, Theme.Radius)
    UI.Minimize.Icon.Root.Position = UDim2.new(0.5, -10, 0.5, 0)
    UI.Minimize.Icon:SetColor(Theme.Secondary)
    UI.CloseWindow = Button.new(
        UI.Header,
        "CloseLoader",
        "",
        false,
        "x",
        function()
            Loader:Destroy()
        end,
        Runtime,
        function()
            return State.Alive and State.Visible
        end
    )
    UI.CloseWindow.Root.BackgroundTransparency = 1
    UI.CloseWindow.Ghost = true
    UI.CloseWindow.Label.Visible = false
    UI.CloseWindow.Icon.Root.Position = UDim2.new(0.5, -9, 0.5, 0)
    UI.CloseWindow.Root:SetAttribute("ActionLabel", Localization:Get("closeLoader"))
    UI.MinimizeGlyphScale = create("UIScale", { Scale = 1 }, UI.Minimize.Icon.Root)
    local function paintHide(hovered)
        UI.Minimize.Icon:SetColor(hovered and Theme.Accent or Theme.Secondary)
        Animation:To(UI.MinimizeGlyphScale, { Scale = hovered and 1.035 or 1 }, Motion.Hover)
    end
    Runtime:Connect(UI.Minimize.Root.MouseEnter, function()
        paintHide(true)
    end)
    Runtime:Connect(UI.Minimize.Root.MouseLeave, function()
        paintHide(false)
    end)
    Runtime:Connect(UI.Minimize.Root.SelectionGained, function()
        paintHide(true)
    end)
    Runtime:Connect(UI.Minimize.Root.SelectionLost, function()
        paintHide(false)
    end)
    Localization:Bind(UI.Minimize.Label, "minimize")
    UI.Minimize.Label.Visible = false
    -- A sibling of Window remains reachable when the full window (including its modal) is hidden.
    UI.RestoreDock = group(UI.Stage, "RestoreDock")
    UI.RestoreDock.Visible = false
    UI.RestoreDock.ZIndex = 25
    UI.RestoreDock.GroupTransparency = 1
    UI.RestoreDockScale = create("UIScale", { Scale = 1 }, UI.RestoreDock)
    UI.Restore = Button.new(
        UI.RestoreDock,
        "RestoreLoader",
        "",
        false,
        "plak",
        function()
            Loader:Show()
        end,
        Runtime,
        function()
            return State.Alive and not State.Visible
        end
    )
    UI.Restore.Root.Size = UDim2.fromScale(1, 1)
    corner(UI.Restore.Root, Theme.PanelRadius)
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
    UI.Sidebar.BackgroundColor3 = Theme.Sidebar
    UI.Sidebar.BackgroundTransparency = 0
    Material:Tone(UI.Sidebar)
    UI.BrandLogo.Root.Parent, UI.Brand.Parent = UI.Sidebar, UI.Sidebar
    UI.SidebarDivider = frame(UI.Sidebar, "SidebarDivider", Theme.Edge)
    UI.HeaderDivider = frame(UI.Header, "HeaderDivider", Theme.Edge)
    UI.PageHeading = group(UI.Header, "RouteHeading")
    UI.PageDescription = localized(UI.PageHeading, "PageDescription", "pageAccess", 12, Theme.Secondary)
    UI.PageDescription.TextTruncate = Enum.TextTruncate.AtEnd
    UI.RailSurface = frame(UI.Sidebar, "NavigationSurface", Theme.Sidebar)
    corner(UI.RailSurface, Theme.PanelRadius)
    UI.NavigationCaption = localized(UI.Sidebar, "NavigationCaption", "main", 10, Theme.Muted, Theme.Medium)
    UI.NavigationCaption.TextTransparency = 0.25
    UI.NavigationCaption.TextTruncate = Enum.TextTruncate.AtEnd
    UI.NavigationPlate = frame(UI.Sidebar, "NavigationSelection", Theme.Inactive)
    corner(UI.NavigationPlate, 4)
    stroke(UI.NavigationPlate, Theme.Line, 1, 0.72)
    Material:Rim(UI.NavigationPlate, Theme.Rim, 0.96)
    UI.UtilityDivider = frame(UI.Sidebar, "UtilityDivider", Theme.Edge)
    UI.ContextIcon = Icon.new(UI.Sidebar, "home", Theme.Muted, 18)
    UI.ActiveNav = frame(UI.Sidebar, "Active", Theme.AccentDark)
    UI.ActiveNav.BackgroundTransparency = 0.7
    corner(UI.ActiveNav, 1)
    UI.ActiveNav.BackgroundColor3 = Theme.AccentText
    UI.ActiveNav.BackgroundTransparency = 1
    UI.NavigationCaret = Icon.new(UI.ActiveNav, "chevron-right", Theme.AccentText, 10)
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
            Loader:SetProducts(loadSupportedGames())
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
    UI.Breadcrumb = label(UI.PageHeading, "PageTitle", "", 17, Theme.Text, Theme.Bold)
    UI.Social = {}
    for _, name in ipairs({ "discord", "send", "youtube" }) do
        local id = name == "send" and "telegram" or name
        local button = Button.new(UI.Sidebar, "Social_" .. id, "", false, name, function()
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
        button.Root:SetAttribute(
            "ActionLabel",
            id == "discord" and "Discord" or id == "telegram" and "Telegram" or "YouTube"
        )
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
    UI.LanguageName = label(UI.LanguageToggle, "CurrentLanguage", "", 12, Theme.Secondary, Theme.Medium)
    UI.LanguageName.TextTruncate = Enum.TextTruncate.AtEnd
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
    corner(UI.LanguageMenu, Theme.PanelRadius)
    stroke(UI.LanguageMenu, Theme.Line, 1, 0.2)
    Material:Panel(UI.LanguageMenu)
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
            Animation:To(self.Label, { TextColor3 = self.Selected and Theme.AccentText or Theme.Text }, Motion.Hover)
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
-- Event-only navigation and one reusable tooltip/focus surface. No frame polling.
Accessibility = { Entries = {}, ByRoot = {}, Keyboard = false }
function Accessibility:Available(root)
    if not State.Alive or not State.Visible or not root or not root.Parent then
        return false
    end
    if
        Experience
        and Experience.OptionsOpen
        and not State.Modal
        and UI.Preferences
        and not root:IsDescendantOf(UI.Preferences)
    then
        return false
    end
    local entry = self.ByRoot[root]
    if not entry or (entry.Allowed and not entry.Allowed()) then
        return false
    end
    if root ~= UI.Key and root.Selectable == false then
        return false
    end
    local object = root
    while object and object ~= UI.Gui do
        if object:IsA("GuiObject") and object.Visible == false then
            return false
        end
        object = object.Parent
    end
    return object == UI.Gui
end
function Accessibility:TooltipText(root)
    local value = root:GetAttribute("ActionLabel")
    local entry = self.ByRoot[root]
    if entry and entry.Button then
        if entry.Button.Label.Visible and entry.Button.Label.Text ~= "" then
            value = entry.Button.Label.Text
        else
            value = value or entry.Button.Label.Text
        end
    end
    return type(value) == "string" and value or ""
end
function Accessibility:HideTooltip()
    Runtime:Cancel(self.TooltipTask)
    self.TooltipTask = nil
    self.TooltipRoot = nil
    if UI.Tooltip then
        UI.Tooltip.Visible = false
    end
end
function Accessibility:Tooltip(root, immediate)
    self:HideTooltip()
    local entry = self.ByRoot[root]
    if
        not entry
        or (entry.Button and entry.Button.Label.Visible and entry.Button.Label.Text ~= "")
        or not self:Available(root)
    then
        return
    end
    self.TooltipRoot = root
    self.TooltipTask = Runtime:Later(immediate and 0 or 0.35, function()
        self.TooltipTask = nil
        if self.TooltipRoot ~= root or not self:Available(root) then
            return
        end
        local text = self:TooltipText(root)
        if text == "" then
            return
        end
        if not UI.Tooltip then
            UI.Tooltip = group(UI.Stage, "ActionTooltip")
            UI.Tooltip.BackgroundColor3 = Theme.Elevated
            UI.Tooltip.BackgroundTransparency = 0
            UI.Tooltip.ZIndex = 55
            corner(UI.Tooltip, Theme.PanelRadius)
            stroke(UI.Tooltip, Theme.Line, 1, 0.15)
            UI.TooltipLabel = label(UI.Tooltip, "Hint", "", 12, Theme.Text, Theme.Medium)
            UI.TooltipLabel.TextWrapped = true
        end
        UI.TooltipLabel.Text = text
        UI.Tooltip.Visible = true
        UI.Tooltip.GroupTransparency = Settings.ReducedMotion and 0 or 1
        self:Layout()
        Animation:To(UI.Tooltip, { GroupTransparency = 0 }, Motion.Hover)
    end)
end
function Accessibility:Register(root, button, allowed)
    if self.ByRoot[root] then
        return
    end
    local entry = { Root = root, Button = button, Allowed = allowed }
    self.Entries[#self.Entries + 1] = entry
    self.ByRoot[root] = entry
    -- Factory-owned signals already have a scope; extra hints share that scope.
    local scope = button and button.Scope or Runtime
    if not button then
        scope:Connect(root.MouseEnter, function()
            self:Tooltip(root)
        end)
        scope:Connect(root.MouseLeave, function()
            if self.TooltipRoot == root then
                self:HideTooltip()
            end
        end)
        scope:Connect(root.SelectionGained, function()
            if self.Keyboard and self:Available(root) then
                self.Focused = root
                self:Layout()
                self:Tooltip(root, true)
            end
        end)
        scope:Connect(root.SelectionLost, function()
            if self.Focused == root then
                self.Focused = nil
                self:Layout()
                self:HideTooltip()
            end
        end)
    end
    scope.Finalizers[#scope.Finalizers + 1] = function()
        self.ByRoot[root] = nil
        for index, item in ipairs(self.Entries) do
            if item == entry then
                table.remove(self.Entries, index)
                break
            end
        end
        if self.Focused == root then
            self:Clear()
        end
        if self.TooltipRoot == root then
            self:HideTooltip()
        end
    end
end
function Accessibility:Selection(root, gained)
    if gained and self.Keyboard and self:Available(root) then
        self.Focused = root
        self:Layout()
        self:Tooltip(root, true)
    elseif not gained and self.Focused == root then
        self.Focused = nil
        self:Layout()
        self:HideTooltip()
    end
end
function Accessibility:Clear()
    self.Focused = nil
    self.Keyboard = false
    self:HideTooltip()
    if UI.FocusRing then
        UI.FocusRing.Visible = false
    end
    if self.GuiService then
        pcall(function()
            local selected = self.GuiService.SelectedObject
            if selected and self.ByRoot[selected] then
                self.GuiService.SelectedObject = self.ExternalSelection
            end
        end)
    end
    self.ExternalSelection = nil
end
function Accessibility:EnsureVisible(root)
    local scroll = root.Parent
    while scroll and scroll ~= UI.Stage do
        if scroll:IsA("ScrollingFrame") then
            local scale = root:IsDescendantOf(UI.Window) and (State.Layout.Scale or 1) or 1
            local top = (root.AbsolutePosition.Y - scroll.AbsolutePosition.Y) / scale
            local viewport = scroll.AbsoluteSize.Y / scale
            local bottom = top + root.AbsoluteSize.Y / scale
            local y = scroll.CanvasPosition.Y
            if top < 8 then
                y = y + top - 8
            elseif bottom > viewport - 8 then
                y = y + bottom - viewport + 8
            end
            scroll.CanvasPosition = Vector2.new(
                scroll.CanvasPosition.X,
                math.clamp(y, 0, math.max(0, scroll.CanvasSize.Y.Offset - viewport))
            )
        end
        scroll = scroll.Parent
    end
end
function Accessibility:Focus(root)
    if not self:Available(root) then
        return false
    end
    local native = Services.Input:GetFocusedTextBox()
    if native == UI.Key or native == UI.ResultCopy then
        native:ReleaseFocus(false)
    end
    self.Focused = root
    self.Keyboard = true
    self:EnsureVisible(root)
    if root == UI.Key or root == UI.ResultCopy then
        root:CaptureFocus()
    elseif self.GuiService then
        pcall(function()
            local selected = self.GuiService.SelectedObject
            if selected and not self.ByRoot[selected] then
                self.ExternalSelection = selected
            end
            self.GuiService.SelectedObject = root
        end)
    end
    self.Focused = root
    self:Layout()
    self:Tooltip(root, true)
    return true
end
function Accessibility:Order()
    local list, seen = {}, {}
    local function add(value)
        local root = value and (typeof(value) == "Instance" and value or value.Root)
        if root and not seen[root] and self:Available(root) then
            list[#list + 1] = root
            seen[root] = true
        end
    end
    if LanguageController.Open then
        add(UI.LanguageToggle)
        for _, language in ipairs(Languages) do
            add(UI.LanguageOptions[language.Id])
        end
    elseif State.Modal == "result" then
        add(UI.ResultClose)
        add(UI.ResultCopy)
        add(UI.ResultLink)
        add(UI.ResultAction)
    elseif State.Modal then
        return list
    elseif Experience.OptionsOpen then
        add(UI.PreferenceClose)
        add(UI.PreferenceLanguage)
        add(UI.PreferenceScale)
        add(UI.PreferenceMotion)
        add(UI.PreferenceReset)
        add(UI.CommunityRestore)
        add(UI.DiagnosticsToggle)
        add(UI.DiagnosticsCopy)
    else
        add(UI.Options)
        if State.Page == "Auth" then
            add(UI.Key)
            add(UI.RevealKey)
            add(UI.Validate)
            add(UI.GetKey)
            add(UI.PasteKey)
            add(UI.KeyFeedbackMore)
            add(UI.RememberMe)
            add(UI.Options)
            add(UI.CommunityDetails)
            add(UI.PreferenceLanguage)
            add(UI.PreferenceScale)
            add(UI.PreferenceMotion)
            add(UI.PreferenceReset)
            add(UI.CommunityRestore)
            add(UI.DiagnosticsToggle)
            add(UI.DiagnosticsCopy)
            add(UI.CommunityClose)
            add(UI.CommunityJoin)
            add(UI.CommunitySupport)
            add(UI.CommunitySuggest)
            add(UI.CommunityDockJoin)
            add(UI.CommunityOpen)
            add(UI.CommunityDockClose)
        elseif State.Page == "Licenses" then
            add(UI.LicenseJumpLife)
            add(UI.LicenseJumpMonth)
            for _, card in ipairs(UI.LicenseCards or {}) do
                add(card.Buy)
            end
            add(UI.LicenseStore)
            add(UI.LicenseHaveKey)
        else
            for _, card in ipairs(Cards) do
                add(card.Select)
                add(card.Open)
            end
        end
        for _, id in ipairs({ "discord", "telegram", "youtube" }) do
            add(UI.Social[id])
        end
        add(UI.AuthNav)
        add(UI.ProductsNav)
        add(UI.RefreshNav)
        add(UI.LicenseNav)
        add(UI.LanguageToggle)
        add(UI.Minimize)
        add(UI.CloseWindow)
    end
    return list
end
function Accessibility:Tab(reverse)
    if not State.Alive or not State.Visible or State.Activity ~= "Idle" then
        return false
    end
    local list = self:Order()
    if #list == 0 then
        return false
    end
    local current = Services.Input:GetFocusedTextBox() or self.Focused
    local index = reverse and 1 or 0
    for i, root in ipairs(list) do
        if root == current then
            index = i
            break
        end
    end
    index = ((index - 1 + (reverse and -1 or 1)) % #list) + 1
    return self:Focus(list[index])
end
function Accessibility:Activate()
    local root = self.Focused
    if not self.Keyboard or not self:Available(root) then
        return false
    end
    if root == UI.Key or root == UI.ResultCopy then
        return false
    end -- Native TextBox owns Enter/IME.
    local entry = self.ByRoot[root]
    if entry.Button then
        entry.Button:Activate()
        self.KeyboardRoot, self.KeyboardAt = root, os.clock()
    elseif root == UI.LanguageToggle then
        LanguageController:SetOpen(not LanguageController.Open)
    end
    return true
end
function Accessibility:CaptureModal()
    if not State.Modal then
        self.ReturnFocus = Services.Input:GetFocusedTextBox() or self.Focused
    end
    self:HideTooltip()
    if UI.FocusRing then
        UI.FocusRing.Visible = false
    end
end
function Accessibility:RestoreModal()
    local root = self.ReturnFocus
    self.ReturnFocus = nil
    if root and self.Keyboard and State.Activity == "Idle" then
        self:Focus(root)
    else
        self:Layout()
    end
end
function Accessibility:Layout()
    local root = self.Focused
    local show = self.Keyboard and self:Available(root)
    if show and root == UI.ResultCopy then
        self:EnsureVisible(root)
    end
    if show then
        if not UI.FocusRing then
            UI.FocusRing = frame(UI.Stage, "KeyboardFocus")
            UI.FocusRing.BackgroundTransparency = 1
            UI.FocusRing.ZIndex = 45
            corner(UI.FocusRing, Theme.Radius)
            stroke(UI.FocusRing, Theme.Accent, 2, 0.08)
        end
        local origin, size = root.AbsolutePosition - UI.Stage.AbsolutePosition, root.AbsoluteSize
        place(UI.FocusRing, origin.X - 2, origin.Y - 2, size.X + 4, size.Y + 4)
    end
    if UI.FocusRing then
        UI.FocusRing.Visible = show == true
    end
    if UI.Tooltip and UI.Tooltip.Visible and self.TooltipRoot and self:Available(self.TooltipRoot) then
        local target = self.TooltipRoot
        local size = UI.Stage.AbsoluteSize
        local width = math.min(236, math.max(100, size.X - 16))
        local height = math.clamp(measure(UI.TooltipLabel.Text, 12, Theme.Medium, width - 24) + 20, 38, 84)
        local origin = target.AbsolutePosition - UI.Stage.AbsolutePosition
        local x = math.clamp(origin.X + target.AbsoluteSize.X + 8, 8, math.max(8, size.X - width - 8))
        local y = math.clamp(origin.Y + (target.AbsoluteSize.Y - height) / 2, 8, math.max(8, size.Y - height - 8))
        place(UI.Tooltip, x, y, width, height)
        place(UI.TooltipLabel, 12, 8, width - 24, height - 16)
    elseif UI.Tooltip then
        UI.Tooltip.Visible = false
    end
end
function Accessibility:Build()
    pcall(function()
        self.GuiService = game:GetService("GuiService")
        Runtime:Connect(self.GuiService:GetPropertyChangedSignal("SelectedObject"), function()
            local selected = self.GuiService.SelectedObject
            if selected and not self.ByRoot[selected] and self.Keyboard then
                self:Clear()
            end
        end)
    end)
    self:Register(UI.Key, nil, AuthField.Interactive)
    UI.ResultCopy.Selectable = true
    self:Register(UI.ResultCopy, nil, function()
        return State.Modal == "result" and State.Activity == "Idle"
    end)
    self:Register(UI.LanguageToggle, nil, function()
        return State.Activity == "Idle" and not State.Modal
    end)
    Runtime:Connect(UI.Key.Focused, function()
        if self.Keyboard then
            self.Focused = UI.Key
            self:Layout()
        end
        self:HideTooltip()
    end)
    Runtime:Connect(UI.AuthScroll:GetPropertyChangedSignal("CanvasPosition"), function()
        self:Layout()
    end)
    Runtime:Connect(Services.Input.InputBegan, function(input)
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
            self:Clear()
        end
    end)
end

-- Measured frontend spans only. No host exceptions, key material, user identity or entitlement.
Diagnostics = { StartedAt = ModuleStartedAt, Open = false }
function Diagnostics:Milliseconds(value)
    return type(value) == "number"
            and value == value
            and value < math.huge
            and math.max(0, math.floor(value * 1000 + 0.5))
        or nil
end
function Diagnostics:Snapshot()
    return {
        schemaVersion = 1,
        uiBuildMs = self:Milliseconds(self.BuiltAt and self.BuiltAt - self.StartedAt),
        uiReadyMs = self:Milliseconds(self.ReadyAt and self.ReadyAt - self.StartedAt),
        validationMs = self:Milliseconds(self.ValidationSeconds),
        handoffMs = self:Milliseconds(self.HandoffSeconds),
        validationPending = self.ValidationStarted ~= nil,
        uiVisible = State.Visible == true,
        language = Settings.Language,
        reducedMotion = Settings.ReducedMotion,
        viewportWidth = math.floor(State.Layout.Width or 0),
        viewportHeight = math.floor(State.Layout.Height or 0),
    }
end
function Diagnostics:Text()
    local data = self:Snapshot()
    local function timing(value)
        return value ~= nil and tostring(value) .. " ms" or "not measured"
    end
    return string.format(
        "PLAK UI diagnostics v1\nUI build: %s\nUI ready: %s\nLast validation: %s\nUI handoff: %s\nValidation pending: %s\nLanguage: %s\nReduced motion: %s\nUI visible: %s\nWindow: %dx%d\nTimings exclude download, checkout and Script() execution.",
        timing(data.uiBuildMs),
        timing(data.uiReadyMs),
        timing(data.validationMs),
        timing(data.handoffMs),
        tostring(data.validationPending),
        data.language,
        tostring(data.reducedMotion),
        tostring(data.uiVisible),
        data.viewportWidth,
        data.viewportHeight
    )
end
function Diagnostics:Refresh()
    if not UI.DiagnosticsPanel then
        return
    end
    local data = self:Snapshot()
    local values = { data.uiBuildMs, data.uiReadyMs, data.validationMs, data.handoffMs }
    for index, row in ipairs(UI.DiagnosticRows) do
        row.Value.Text = index == 3 and data.validationPending and Localization:Get("diagPending")
            or values[index] ~= nil and tostring(values[index]) .. " ms"
            or Localization:Get("diagNotMeasured")
    end
    UI.DiagnosticsPanel.Visible = self.Open and Experience.OptionsOpen
    Localization:Bind(UI.DiagnosticsToggle.Label, self.Open and "diagHide" or "diagShow")
    UI.DiagnosticsToggle:SetDisabled(State.Activity ~= "Idle")
end
function Diagnostics:Build()
    if UI.DiagnosticsPanel then
        return
    end
    UI.DiagnosticsPanel = frame(UI.PreferencesContent, "Diagnostics", Theme.Input)
    corner(UI.DiagnosticsPanel, Theme.PanelRadius)
    stroke(UI.DiagnosticsPanel, Theme.Line, 1, 0.4)
    UI.DiagnosticRows = {}
    for index, key in ipairs({ "diagBuild", "diagReady", "diagValidation", "diagHandoff" }) do
        UI.DiagnosticRows[index] = {
            Title = localized(UI.DiagnosticsPanel, "Metric" .. index, key, 12, Theme.Secondary),
            Value = label(UI.DiagnosticsPanel, "Value" .. index, "", 14, Theme.Text, Theme.Medium),
        }
    end
    UI.DiagnosticsNote = localized(UI.DiagnosticsPanel, "Privacy", "diagNote", 11, Theme.Secondary)
    UI.DiagnosticsNote.TextWrapped = true
    UI.DiagnosticsCopy = Button.new(UI.DiagnosticsPanel, "CopyDiagnostics", "", false, "copy", function()
        self:Copy()
    end, Runtime, canInteract)
    Localization:Bind(UI.DiagnosticsCopy.Label, "copyDetails")
    self:Refresh()
end
function Diagnostics:Toggle(open)
    if not State.Alive or not State.Visible or State.Activity ~= "Idle" then
        return false
    end
    self.Open = open == nil and not self.Open or open == true
    if self.Open then
        self:Build()
    end
    if UI.DiagnosticsToggle then
        Localization:Bind(UI.DiagnosticsToggle.Label, self.Open and "diagHide" or "diagShow")
    end
    self:Refresh()
    Responsive:Update()
    return true
end
function Diagnostics:Measure(width)
    if
        self.MeasuredWidth == width
        and self.MeasuredLanguage == Settings.Language
        and self.MeasuredScale == State.Layout.Scale
    then
        return
    end
    self.MeasuredWidth, self.MeasuredLanguage, self.MeasuredScale = width, Settings.Language, State.Layout.Scale
    self.NoteHeight = math.clamp(measure(Localization:Get("diagNote"), 11, Theme.Font, math.max(1, width - 24)), 38, 96)
    self.MetricsHeight = width < 270 and 232 or 124
    self.PanelHeight = self.MetricsHeight
        + self.NoteHeight
        + 18
        + math.max(44, math.ceil(44 / math.max(0.1, State.Layout.Scale or 1)))
end
function Diagnostics:Height()
    return self.Open and ((self.PanelHeight or 232) + 12) or 0
end
function Diagnostics:Layout(width)
    if not UI.DiagnosticsPanel or not self.Open then
        return
    end
    self:Measure(width)
    place(UI.DiagnosticsPanel, 0, self.Top or 242, width, self.PanelHeight)
    local half = (width - 32) / 2
    for index, row in ipairs(UI.DiagnosticRows) do
        local stacked = width < 270
        local x = stacked and 12 or index % 2 == 1 and 12 or 20 + half
        local y = stacked and 12 + (index - 1) * 54 or index <= 2 and 12 or 66
        local rowWidth = stacked and width - 24 or half
        row.Title.TextWrapped = true
        row.Title.TextTruncate = Enum.TextTruncate.AtEnd
        place(row.Title, x, y, rowWidth, 28)
        place(row.Value, x, y + 28, rowWidth, 22)
    end
    place(UI.DiagnosticsNote, 12, self.MetricsHeight, width - 24, self.NoteHeight)
    place(
        UI.DiagnosticsCopy.Root,
        12,
        self.MetricsHeight + 8 + self.NoteHeight,
        width - 24,
        math.max(44, math.ceil(44 / math.max(0.1, State.Layout.Scale or 1)))
    )
end
function Diagnostics:Copy()
    if not canInteract() then
        return false, "busy"
    end
    local text = self:Text()
    local copy = capability("setclipboard") or capability("toclipboard")
    local ok, result = false, nil
    if copy then
        ok, result = pcall(copy, text)
    end
    if ok and result ~= false then
        Loader:Toast({ Type = "success", Title = Localization:Get("copied"), Subtitle = Localization:Get("diagCopied") })
        return true
    end
    Modal:Open({
        Type = "info",
        Title = Localization:Get("diagTitle"),
        CopyText = text,
        ActionKey = "close",
        OnAction = function()
            Modal:Close()
        end,
    })
    return false, "clipboard_unavailable"
end

-- Dedicated lazy storefront page. Checkout and entitlement remain with the store/host.
LicenseOffer = { RevealTasks = {}, Generation = 0 }
function LicenseOffer:Enabled()
    return Settings.LicenseOfferEnabled and Settings.LicenseStoreLink ~= ""
end
function LicenseOffer:Interactive()
    return canInteract() and State.Page == "Licenses" and self:Enabled()
end
function LicenseOffer:CancelReveal()
    self.Generation = self.Generation + 1
    for _, thread in ipairs(self.RevealTasks) do
        Runtime:Cancel(thread)
    end
    table.clear(self.RevealTasks)
    for _, card in ipairs(UI.LicenseCards or {}) do
        Animation:CancelProperty(card.Root, "Position")
        Animation:CancelProperty(card.Root, "GroupTransparency")
        Animation:CancelProperty(card.Scale, "Scale")
        Animation:CancelProperty(card.Sweep, "Position")
        Animation:CancelProperty(card.Seal.Root, "Rotation")
        Animation:CancelProperty(card.SealScale, "Scale")
        card.Root.GroupTransparency, card.Scale.Scale = 0, 1
        if card.Rest then
            card.Root.Position = card.Rest
        end
        card.Hovered = false
        card.Sweep.Visible = false
        card.Seal.Root.Rotation, card.SealScale.Scale = -35, 1
    end
end
function LicenseOffer:Refresh()
    if UI.LicenseNav then
        UI.LicenseNav:SetDisabled(not self:Enabled() or State.Activity ~= "Idle")
        UI.LicenseNav.Root:SetAttribute("ActionLabel", Localization:Get("offerTab"))
        -- Navigation owns icon ink. A second immediate painter here used to
        -- cancel its hover/selection tween on every responsive refresh.
    end
    if not UI.LicensePanel then
        return
    end
    Localization:Bind(UI.LicenseStore.Label, "offerStore", "Text", function()
        return Settings.LicenseStoreLink:gsub("^https://", ""):gsub("/$", "")
    end)
    UI.LicenseStore.Root:SetAttribute(
        "ActionLabel",
        Localization:Get("offerStore") .. " · " .. Settings.LicenseStoreLink
    )
    local copied = self.CopyTask ~= nil and self.CopiedLink == Settings.LicenseStoreLink
    for _, card in ipairs(UI.LicenseCards) do
        Localization:Bind(
            card.Buy.Label,
            copied and "offerCopied" or card.Primary and "offerChooseLifetime" or "offerChooseMonthly"
        )
        card.Buy:SetDisabled(copied or not self:Enabled())
    end
    UI.LicenseStore:SetDisabled(copied or not self:Enabled())
    self:FitLabels()
end
function LicenseOffer:Copy(plan)
    if not self:Interactive() then
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
        self.CopyTask, self.CopiedLink = nil, nil
        self:Refresh()
    end)
    self:Refresh()
    return true
end
function LicenseOffer:Paint(card, hovered)
    card.Hovered = hovered == true
    local surface = card.Primary and Theme.AccentMuted or Theme.Input
    Animation:To(
        card.Root,
        { BackgroundColor3 = card.Hovered and surface:Lerp(Theme.Text, 0.018) or surface },
        Motion.Hover
    )
    local color = card.Primary and Theme.AccentHover or Theme.Edge
    Animation:To(card.Border, {
        Color = color,
        Transparency = card.Hovered and 0.18 or card.Primary and 0.45 or 0.12,
    }, Motion.Hover)
    -- Keep compatibility fields for existing reveal/cleanup owners, but no sweep,
    -- key rotation, scaling or permanent promotional motion in this language.
    Animation:CancelProperty(card.Sweep, "Position")
    Animation:CancelProperty(card.Seal.Root, "Rotation")
    Animation:CancelProperty(card.SealScale, "Scale")
    card.Sweep.Visible = false
    card.Seal.Root.Rotation, card.SealScale.Scale = -35, 1
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
function LicenseOffer:BuildKey(parent, primary)
    local root = frame(parent, "FacetedLicenseKey")
    root.BackgroundTransparency = 1
    root.Rotation = -35
    local bright = primary and Theme.AccentHover or Theme.Secondary
    local dark = primary and Theme.AccentMuted or Theme.Input
    -- Small open bow with depth faces and a beveled shaft; no asset or idle effect.
    for index = 0, 5 do
        local a, b = math.rad(index * 60 - 30), math.rad((index + 1) * 60 - 30)
        local x1, y1 = 26 + math.cos(a) * 18, 20 + math.sin(a) * 18
        local x2, y2 = 26 + math.cos(b) * 18, 20 + math.sin(b) * 18
        local angle = math.deg(math.atan2(y2 - y1, x2 - x1))
        for layer = 1, 2 do
            local face = frame(root, "BowFace" .. index .. "Depth" .. layer)
            face.AnchorPoint = Vector2.new(0.5, 0.5)
            face.Position =
                UDim2.fromOffset((x1 + x2) / 2 + (layer == 1 and 2 or 0), (y1 + y2) / 2 + (layer == 1 and 3 or 0))
            face.Size = UDim2.fromOffset(20, layer == 1 and 8 or 6)
            face.Rotation = angle
            gradient(face, layer == 1 and dark or bright, dark, index < 3 and 90 or 270)
        end
    end
    local shaft = frame(root, "BeveledShaft")
    place(shaft, 22, 34, 9, 43)
    gradient(shaft, bright, dark, 0)
    local edge = frame(root, "ShaftDepth", dark)
    place(edge, 31, 36, 2, 41)
    for index = 1, 2 do
        local tooth = frame(root, "KeyTooth" .. index)
        place(tooth, 29, 55 + index * 10, index == 1 and 10 or 14, 7)
        gradient(tooth, bright, dark, 90)
    end
    return { Root = root }
end

function LicenseOffer:BuildCard(primary)
    local card = { Primary = primary }
    card.Root = group(UI.LicenseBody, primary and "Lifetime" or "Monthly")
    card.Root.BackgroundTransparency, card.Root.ClipsDescendants = 0, true
    card.Root.BackgroundColor3 = primary and Theme.AccentMuted or Theme.Input
    corner(card.Root, Theme.PanelRadius)
    card.Border = stroke(card.Root, primary and Theme.AccentHover or Theme.Edge, 1, primary and 0.45 or 0.12)
    Material:Panel(card.Root)
    card.Scale = create("UIScale", { Scale = 1 }, card.Root)
    card.Facet = frame(card.Root, "DiagonalFacet", Theme.Text)
    card.Facet.Visible, card.Facet.BackgroundTransparency = false, 1
    card.Sweep = frame(card.Root, "FiniteLightSweep", Theme.Text)
    card.Sweep.Visible, card.Sweep.BackgroundTransparency = false, 1
    card.Badge = frame(card.Root, "PaymentBadge", primary and Theme.Surface or Theme.Surface)
    corner(card.Badge, 2)
    card.BadgeLabel = localized(
        card.Badge,
        "Payment",
        primary and "offerOneTime" or "offerMonthlyBadge",
        11,
        Theme.Secondary,
        Theme.Medium
    )
    card.BadgeLabel.TextXAlignment = Enum.TextXAlignment.Left
    card.BadgeLabel.TextWrapped = true
    card.BadgeLabel.TextTruncate = Enum.TextTruncate.None
    card.Title = label(card.Root, "Plan", primary and "Lifetime" or "Monthly", 16, Theme.Text, Theme.Bold)
    card.Price = label(card.Root, "Price", primary and "$12" or "$5", 44, Theme.Text, Theme.Bold)
    card.Currency =
        localized(card.Root, "Currency", primary and "offerUSD" or "offerPerMonth", 12, Theme.Secondary, Theme.Medium)
    card.Currency.TextWrapped = true
    card.Currency.TextTruncate = Enum.TextTruncate.None
    card.Term =
        localized(card.Root, "LicenseTerm", primary and "offerLifetimeTerm" or "offerMonthlyTerm", 12, Theme.Secondary)
    card.Term.TextWrapped, card.Term.TextYAlignment = true, Enum.TextYAlignment.Top
    card.Term.TextTruncate = Enum.TextTruncate.None
    card.Seal = self:BuildKey(card.Root, primary)
    card.SealScale = create("UIScale", { Scale = 1 }, card.Seal.Root)
    card.Buy = Button.new(
        card.Root,
        "Choose",
        "",
        primary,
        nil,
        function()
            return self:Copy(primary and "lifetime" or "monthly")
        end,
        Runtime,
        function()
            return self:Interactive()
        end
    )
    card.Buy.Label.TextColor3 = primary and Theme.ButtonText or Theme.Text
    card.Buy.Label.TextWrapped, card.Buy.Label.TextTruncate = true, Enum.TextTruncate.None
    card.Buy.Label.Position, card.Buy.Label.Size = UDim2.fromOffset(8, 0), UDim2.new(1, -40, 1, 0)
    card.Arrow = Icon.new(card.Buy.Root, "chevron", primary and Theme.ButtonText or Theme.Text, 14)
    card.Arrow.Root.Rotation = -90
    if not primary then
        card.Buy.BaseColor = Theme.Surface
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
    Runtime:Connect(card.Buy.Root.SelectionGained, function()
        if self:Interactive() then
            self:Paint(card, true)
        end
    end)
    Runtime:Connect(card.Buy.Root.SelectionLost, function()
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
    UI.LicensePanel = group(UI.Pages, "Licenses")
    UI.LicensePanel.Visible, UI.LicensePanel.ClipsDescendants = false, true
    UI.LicensePanel.Size = UDim2.fromScale(1, 1)
    UI.LicenseScale = create("UIScale", { Scale = 1 }, UI.LicensePanel)
    -- Keep existing owner/field contracts, without a repeated promotional banner.
    UI.LicenseMark = self:BuildMark(UI.LicensePanel)
    UI.LicenseMark.Visible = false
    UI.LicenseTag = localized(UI.LicensePanel, "Category", "offerLicenses", 14, Theme.Text, Theme.Medium)
    UI.LicenseTag.Visible = false
    UI.LicenseDivider = frame(UI.LicensePanel, "HeaderDivider", Theme.Edge)
    UI.LicenseDivider.Visible = false
    UI.LicenseScroll = create("ScrollingFrame", {
        Name = "LicenseContent",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.AccentHover,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        VerticalScrollBarInset = Enum.ScrollBarInset.None,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
        ClipsDescendants = true,
    }, UI.LicensePanel)
    UI.LicenseBody = frame(UI.LicenseScroll, "Body")
    UI.LicenseBody.BackgroundTransparency = 1
    UI.LicenseHeroA = localized(UI.LicenseBody, "HeroA", "offerHeroA", 16, Theme.Text, Theme.Bold)
    UI.LicenseHeroB = localized(UI.LicenseBody, "HeroB", "offerHeroB", 16, Theme.Text, Theme.Bold)
    UI.LicenseHeroA.Visible, UI.LicenseHeroB.Visible = false, false
    UI.LicenseSubhead = localized(UI.LicenseBody, "Subhead", "offerSubhead", 12, Theme.Secondary)
    UI.LicenseSubhead.TextWrapped, UI.LicenseSubhead.TextYAlignment = true, Enum.TextYAlignment.Top
    UI.LicenseSubhead.TextTruncate = Enum.TextTruncate.None
    UI.LicenseJumpLife = Button.new(UI.LicenseBody, "LifetimeShortcut", "", false, nil, function()
        UI.LicenseScroll.CanvasPosition = Vector2.new(0, math.max(0, UI.LicenseCards[1].Rest.Y.Offset - 8))
    end, Runtime, allowed)
    UI.LicenseJumpMonth = Button.new(UI.LicenseBody, "MonthlyShortcut", "", false, nil, function()
        UI.LicenseScroll.CanvasPosition = Vector2.new(0, math.max(0, UI.LicenseCards[2].Rest.Y.Offset - 8))
    end, Runtime, allowed)
    Localization:Bind(UI.LicenseJumpLife.Label, "offerJumpLifetime")
    Localization:Bind(UI.LicenseJumpMonth.Label, "offerJumpMonthly")
    UI.LicenseCards = { self:BuildCard(true), self:BuildCard(false) }
    UI.LicenseTerms = localized(UI.LicenseBody, "Terms", "offerTerms", 12, Theme.Secondary)
    UI.LicenseTerms.TextWrapped, UI.LicenseTerms.TextYAlignment = true, Enum.TextYAlignment.Top
    UI.LicenseTerms.TextTruncate = Enum.TextTruncate.None
    UI.LicenseStore = Button.new(UI.LicensePanel, "Storefront", "", false, "link", function()
        return self:Copy()
    end, Runtime, allowed)
    UI.LicenseStore.BaseColor = Theme.Input
    UI.LicenseStore.Label.TextWrapped, UI.LicenseStore.Label.TextTruncate = true, Enum.TextTruncate.None
    UI.LicenseStore:Apply()
    UI.LicenseHaveKey = Button.new(UI.LicensePanel, "HaveKey", "", false, nil, function()
        return self:BackToKey()
    end, Runtime, allowed)
    UI.LicenseHaveKey.Root.BackgroundTransparency = 1
    Localization:Bind(UI.LicenseHaveKey.Label, "offerHaveKey")
    UI.LicenseHaveKey.Label.TextWrapped, UI.LicenseHaveKey.Label.TextTruncate = true, Enum.TextTruncate.None
    self:Refresh()
end

function LicenseOffer:Layout(settle)
    if not UI.LicensePanel then
        return
    end
    if settle then
        self:CancelReveal()
    end
    local size = UI.Pages.AbsoluteSize
    local scale = math.max(0.1, UI.Scale.Scale)
    local hit = math.max(44, math.ceil(44 / scale))
    local width, height = math.max(100, size.X / scale), math.max(100, size.Y / scale)
    local stacked, compact, inFlowFooter = width < 560, width < 360, height < 200
    local footer = inFlowFooter and 0 or compact and (hit * 2 + 16) or hit + 12
    local viewportHeight = math.max(20, height - footer)
    UI.LicensePanel.Size = UDim2.fromOffset(width, height)
    UI.LicenseMark.Visible, UI.LicenseTag.Visible, UI.LicenseDivider.Visible = false, false, false
    local showHeading = height >= 260
    UI.LicenseHeroA.Visible, UI.LicenseHeroB.Visible = showHeading, showHeading
    place(UI.LicenseScroll, 0, 0, width, viewportHeight)
    local headingA = TextMetrics:Get(Localization:Get("offerHeroA"), 26, Theme.Display, 10000)
    local headingB = TextMetrics:Get(Localization:Get("offerHeroB"), 26, Theme.Display, 10000)
    local headingWidth = math.ceil(headingA and headingA.X or width)
    local inlineHeading = headingWidth + (headingB and headingB.X or width) + 10 <= width
    local headingHeight = showHeading and (inlineHeading and 34 or 66) or 0
    UI.LicenseHeroA.TextSize, UI.LicenseHeroB.TextSize = 26, 26
    UI.LicenseHeroB.TextColor3 = Theme.AccentText
    place(UI.LicenseHeroA, 0, 0, inlineHeading and headingWidth + 2 or width, 32)
    place(
        UI.LicenseHeroB,
        inlineHeading and headingWidth + 10 or 0,
        inlineHeading and 0 or 32,
        inlineHeading and width - headingWidth - 10 or width,
        32
    )
    local subheadHeight = math.max(18, measure(Localization:Get("offerSubhead"), 12, Theme.Font, width))
    local subheadY = showHeading and headingHeight + 6 or 0
    place(UI.LicenseSubhead, 0, subheadY, width, subheadHeight)
    local cardsY = subheadY + subheadHeight + 14
    UI.LicenseJumpLife.Root.Visible, UI.LicenseJumpMonth.Root.Visible = stacked, stacked
    if stacked then
        local half = (width - 8) / 2
        place(UI.LicenseJumpLife.Root, 0, cardsY, half, hit)
        place(UI.LicenseJumpMonth.Root, half + 8, cardsY, half, hit)
        cardsY = cardsY + hit + 12
    end
    local gap = 16
    local firstWidth = stacked and width or math.floor((width - gap) * 0.56)
    local widths = { firstWidth, stacked and width or width - gap - firstWidth }
    -- Measure both before placing either so translated terms retain equal-height comparison.
    local cardHeight, badgeExtra = 248, 0
    for index, card in ipairs(UI.LicenseCards) do
        local cardWidth = widths[index]
        -- Language decoding is presentation only: never size from its transient
        -- scrambled label text, otherwise a later resize changes the final layout.
        card.BadgeCopy = Localization:Get(card.Primary and "offerOneTime" or "offerMonthlyBadge")
        local term = Localization:Get(card.Primary and "offerLifetimeTerm" or "offerMonthlyTerm")
        card.TermHeight = math.max(20, measure(term, 12, Theme.Font, math.max(1, cardWidth - 32)))
        card.BadgeHeight =
            math.max(22, measure(card.BadgeCopy, Theme.BadgeSize, Theme.Medium, math.max(1, cardWidth - 48)) + 8)
        badgeExtra = math.max(badgeExtra, card.BadgeHeight - 24)
        cardHeight = math.max(cardHeight, 156 + card.TermHeight + 12 + hit + 16)
    end
    cardHeight = cardHeight + badgeExtra
    for index, card in ipairs(UI.LicenseCards) do
        local cardWidth = widths[index]
        local x = stacked and 0 or (index == 1 and 0 or firstWidth + gap)
        local y = cardsY + (stacked and (index - 1) * (cardHeight + gap) or 0)
        card.Rest = UDim2.fromOffset(x, y)
        card.Root.Position, card.Root.Size = card.Rest, UDim2.fromOffset(cardWidth, cardHeight)
        card.Facet.Visible, card.Sweep.Visible = false, false
        place(card.Title, 16, 16, cardWidth - 32, 24)
        card.Title.TextSize = 18
        local termBounds = TextMetrics:Get(card.BadgeCopy, Theme.BadgeSize, Theme.Medium, 10000)
        local badgeWidth = math.min(cardWidth - 32, math.ceil(termBounds and termBounds.X or cardWidth - 48) + 24)
        place(card.Badge, 16, 48, badgeWidth, card.BadgeHeight)
        place(card.BadgeLabel, 8, 0, badgeWidth - 16, card.BadgeHeight)
        card.BadgeLabel.TextSize = Theme.BadgeSize
        local keyVisible = cardWidth >= 250
        card.Seal.Root.Visible = keyVisible
        place(card.Seal.Root, cardWidth - 76, 72 + badgeExtra, 56, 84)
        card.Price.TextSize = cardWidth < 220 and 36 or cardWidth < 300 and 44 or 48
        place(card.Price, 16, 78 + badgeExtra, math.max(1, cardWidth - 32 - (keyVisible and 70 or 0)), 52)
        place(card.Currency, 16, 130 + badgeExtra, cardWidth - 32, 20)
        place(card.Term, 16, 156 + badgeExtra, cardWidth - 32, card.TermHeight)
        place(card.Buy.Root, 16, cardHeight - hit - 16, cardWidth - 32, hit)
        place(card.Arrow.Root, cardWidth - 60, 15, 14, 14)
        self:Paint(card, card.Hovered)
    end
    local termsY = cardsY + (stacked and cardHeight * 2 + gap or cardHeight) + 16
    local termsHeight = math.max(18, measure(Localization:Get("offerTerms"), 12, Theme.Font, width))
    place(UI.LicenseTerms, 0, termsY, width, termsHeight)
    local canvas = termsY + termsHeight + 8
    local footerParent = inFlowFooter and UI.LicenseBody or UI.LicensePanel
    UI.LicenseStore.Root.Parent, UI.LicenseHaveKey.Root.Parent = footerParent, footerParent
    UI.LicenseStore.Root.Visible, UI.LicenseHaveKey.Root.Visible = true, true
    local footerY = inFlowFooter and canvas + 8 or height - footer + 8
    if compact then
        place(UI.LicenseStore.Root, 0, footerY, width, hit)
        place(UI.LicenseHaveKey.Root, 0, footerY + hit + 4, width, hit)
    else
        local haveWidth = math.min(180, math.floor(width * 0.38))
        place(UI.LicenseStore.Root, 0, footerY, width - haveWidth - 8, hit)
        place(UI.LicenseHaveKey.Root, width - haveWidth, footerY, haveWidth, hit)
    end
    if inFlowFooter then
        canvas = footerY + (compact and (hit * 2 + 4) or hit) + 8
    end
    UI.LicenseBody.Size, UI.LicenseScroll.CanvasSize = UDim2.fromOffset(width, canvas), UDim2.fromOffset(0, canvas)
    UI.LicenseScroll.ScrollingEnabled = canvas > viewportHeight
    local old = UI.LicenseScroll.CanvasPosition
    UI.LicenseScroll.CanvasPosition = Vector2.new(0, math.clamp(old.Y, 0, math.max(0, canvas - viewportHeight)))
    self:FitLabels()
end

function LicenseOffer:FitLabels()
    local copied = self.CopyTask ~= nil and self.CopiedLink == Settings.LicenseStoreLink
    for _, card in ipairs(UI.LicenseCards or {}) do
        local width = math.max(1, card.Buy.Root.Size.X.Offset - 40)
        local caption =
            Localization:Get(copied and "offerCopied" or card.Primary and "offerChooseLifetime" or "offerChooseMonthly")
        local bounds = TextMetrics:Get(caption, 14, Theme.Medium, 10000)
        card.Buy.Label.TextSize = bounds and bounds.X > width and 12 or 14
        card.Buy.Label.TextWrapped = true
        card.Buy.Label.TextTruncate = Enum.TextTruncate.None
        card.BadgeLabel.TextSize = Theme.BadgeSize
        card.Currency.TextSize, card.Term.TextSize = 12, 12
    end
    for _, button in ipairs({ UI.LicenseStore, UI.LicenseHaveKey, UI.LicenseJumpLife, UI.LicenseJumpMonth }) do
        if button then
            button.Label.TextSize, button.Label.TextWrapped = 12, true
            button.Label.TextTruncate = Enum.TextTruncate.None
        end
    end
end

function LicenseOffer:BackToKey()
    if not self:Interactive() then
        return false
    end
    local keyboard = Accessibility.Keyboard
    Navigation:Go("Auth", true)
    Accessibility.Keyboard = keyboard
    UI.AuthScroll.CanvasPosition = Vector2.new(0, 0)
    if keyboard then
        Accessibility:Focus(UI.Key)
    else
        UI.Key:CaptureFocus()
    end
    return true
end
function LicenseOffer:Reveal()
    self:CancelReveal()
    if not self:Interactive() or not UI.LicensePanel then
        return
    end
    local generation, token = self.Generation, State.PageToken
    for index, card in ipairs(UI.LicenseCards) do
        card.Root.GroupTransparency = Settings.ReducedMotion and 0 or 1
        card.Root.Position = card.Rest + UDim2.fromOffset(0, Settings.ReducedMotion and 0 or 8)
        card.Scale.Scale = Settings.ReducedMotion and 1 or 0.985
        self.RevealTasks[#self.RevealTasks + 1] = Runtime:Later(
            Settings.ReducedMotion and 0 or 0.055 * (index - 1),
            function()
                if self.Generation == generation and State.PageToken == token and self:Interactive() then
                    Animation:To(card.Root, { GroupTransparency = 0, Position = card.Rest }, Motion.Enter)
                    Animation:To(card.Scale, { Scale = 1 }, Motion.Enter)
                end
            end
        )
    end
end
function LicenseOffer:Open()
    if not State.Alive or not State.Visible or State.Activity ~= "Idle" or not self:Enabled() then
        return false, "unavailable"
    end
    Modal:Close(true)
    return Navigation:Go("Licenses")
end
function LicenseOffer:BuildTriggers()
    UI.LicenseNav = Button.new(UI.Sidebar, "Licenses", "", false, "key", function()
        self:Open()
    end)
    UI.LicenseNav.Root.BackgroundTransparency = 1
    UI.LicenseNav.Label.Visible = false
    UI.LicenseNav.Icon.Root.Position = UDim2.new(0.5, -10, 0.5, 0)
    for index, button in ipairs({ UI.AuthNav, UI.ProductsNav, UI.LicenseNav, UI.RefreshNav }) do
        button.NavHint = label(button.Root, "RouteGuidance", "", 11, Theme.Muted)
        button.NavHint.TextWrapped, button.NavHint.TextTruncate = true, Enum.TextTruncate.AtEnd
        button.NavHint.TextYAlignment = Enum.TextYAlignment.Top
        Localization:Bind(button.NavHint, ({ "pageAccess", "pageGames", "pageLicenses", "tipRefresh" })[index])
    end
    self:Refresh()
end

Community = { DetailsOpen = false, Generation = 0, CardHeight = 300, CardRevealed = false, DockRevealed = false }
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
        and (State.Page == "Auth" or Experience.OptionsOpen)
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
    if UI.CommunityDetails then
        -- The dock's Details target replaced this old form action; refresh must not resurrect it.
        UI.CommunityDetails.Root.Visible = false
        UI.CommunityDetails:SetDisabled(State.Activity ~= "Idle")
    end
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
    if
        not self.DetailsOpen
        or not self:Enabled()
        or not self:Interactive()
        or self.CardRevealed
        or not State.Layout.Height
    then
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
    self.DetailsOpen = true
    Responsive:Update()
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
    return (self:Enabled() or self.Hiding)
            and State.Page == "Auth"
            and width >= 180
            and height >= 350
            and (math.max(44, math.ceil(44 / math.max(0.1, State.Layout.Scale or 1))) + 24)
        or 0
end
function Community:Height()
    return self.DetailsOpen and (self:Enabled() or self.Hiding) and (self.CardHeight + 12) or 0
end
function Community:Measure(width)
    if
        self.MeasuredWidth == width
        and self.MeasuredLanguage == Settings.Language
        and self.MeasuredScale == State.Layout.Scale
    then
        return
    end
    self.MeasuredWidth, self.MeasuredLanguage, self.MeasuredScale = width, Settings.Language, State.Layout.Scale
    local inner = math.max(1, width - 32)
    self.IntroHeight = math.clamp(measure(Localization:Get("communityIntro"), 12, Theme.Font, inner), 30, 62)
    self.NewsHeights = self.NewsHeights or {}
    local joinY = 63 + self.IntroHeight + 16 + 27
    for index, key in ipairs({ "communityNewsAuth", "communityNewsPrefs", "communityNewsGame" }) do
        local rowHeight = math.clamp(measure(Localization:Get(key), 12, Theme.Font, inner - 14), 20, 48)
        self.NewsHeights[index] = rowHeight
        joinY = joinY + rowHeight + 5
    end
    self.CardHeight = joinY + 57 + math.max(44, math.ceil(44 / math.max(0.1, State.Layout.Scale or 1))) * 2
end
function Community:Layout(width, y)
    local enabled = self.DetailsOpen and (self:Enabled() or self.Hiding)
    UI.CommunityCard.Visible = enabled
    if not enabled then
        return
    end
    self:Measure(width)
    local compact = width < 260
    local hit = math.max(44, math.ceil(44 / math.max(0.1, State.Layout.Scale or 1)))
    Localization:Bind(UI.CommunityTitle, compact and "communityDockTitle" or "communityTitle")
    UI.CommunityAvatar.Visible = not compact
    place(UI.CommunityAvatar, 16, 16, 36, 36)
    place(UI.CommunityDiscord.Root, 6, 6, 24, 24)
    place(UI.CommunityClose.Root, width - hit - 8, 8, hit, hit)
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
    place(UI.CommunityJoin.Root, 16, joinY, inner, hit)
    local half = (inner - 8) / 2
    place(UI.CommunitySupport.Root, 16, joinY + hit + 8, half, hit)
    place(UI.CommunitySuggest.Root, 24 + half, joinY + hit + 8, half, hit)
    place(UI.CommunityOptional, 16, joinY + hit * 2 + 15, inner, 22)
    self.CardHeight = joinY + hit * 2 + 49
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
    local hit = math.max(44, math.ceil(44 / math.max(0.1, State.Layout.Scale or 1)))
    local dockHeight = hit + 12
    place(UI.CommunityDock, x, y, width, dockHeight)
    local compact = width < 360
    UI.CommunityDockIcon.Root.Visible, UI.CommunityDockSubtitle.Visible = not compact, not compact
    place(UI.CommunityDockIcon.Root, 14, (dockHeight - 20) / 2, 20, 20)
    local start = compact and 16 or 48
    local joinWidth = compact and hit or math.max(hit, 76)
    local actionWidth = joinWidth + hit + 16
    place(
        UI.CommunityDockTitle,
        start,
        compact and (dockHeight - 24) / 2 or 8,
        math.max(1, width - start - actionWidth - 8),
        24
    )
    place(UI.CommunityDockSubtitle, start, 32, math.max(1, width - start - actionWidth - 8), 18)
    place(UI.CommunityOpen.Root, 0, 0, math.max(hit, width - actionWidth), dockHeight)
    place(UI.CommunityDockJoin.Root, width - actionWidth + 2, 6, joinWidth, hit)
    place(UI.CommunityDockClose.Root, width - hit - 6, 6, hit, hit)
    if not self.DockRevealed then
        self.DockRevealed = true
        UI.CommunityDockScale.Scale = Settings.ReducedMotion and 1 or 0.99
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
    corner(UI.CommunityCard, Theme.PanelRadius)
    UI.CommunityBorder = stroke(UI.CommunityCard, Theme.AccentDark, 1, 0.58)
    UI.CommunityScale = create("UIScale", { Scale = 1 }, UI.CommunityCard)
    UI.CommunityAvatar = frame(UI.CommunityCard, "DiscordMark", Theme.AccentDark)
    corner(UI.CommunityAvatar, Theme.PanelRadius)
    gradient(UI.CommunityAvatar, Theme.AccentDark, Theme.AccentMuted, 65)
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
    corner(UI.CommunityDock, Theme.PanelRadius)
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
    UI.CommunityRestore = secondary(UI.PreferencesContent, "CommunityVisibility", "communityHide", function()
        if Settings.CommunityDismissed then
            self:Restore()
        else
            self:Dismiss()
        end
    end)
    UI.CommunityRestore.Ghost = true
    UI.CommunityRestore.Icon = Icon.new(UI.CommunityRestore.Root, "discord", Theme.Secondary, 18)
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
    local changed = self.Stage ~= stage
    self.Stage = stage
    self:RefreshJourney()
    if UI.AuthStatus then
        Localization:Bind(UI.AuthStatus, stage)
        UI.AuthStatus.TextColor3 = stage == "authFailed" and Theme.Danger
            or stage == "authGranted" and Theme.Text
            or Theme.Secondary
        if changed and State.Layout.Height then
            Responsive:Request()
        end
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
    if info.lifetime then
        return text .. "  •  " .. Localization:Get("accessLifetime")
    end
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
        local changed = UI.AuthLicense.Visible ~= State.Authorized
        UI.AuthLicense.Visible = State.Authorized
        if changed and State.Layout.Height then
            Responsive:Request()
        end
        Localization:Bind(UI.AuthLicense, "empty", "Text", function()
            return self:LicenseText()
        end)
    end
    if UI.ProgressLicense and Modal.AuthCompletion then
        UI.ProgressLicense.Text = self:LicenseText()
    end
    self:RefreshJourney()
    AuthField:Paint()
    self:RefreshGame()
    self:RefreshOptions()
    Community:Refresh()
    LicenseOffer:Refresh()
    Diagnostics:Refresh()
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
    UI.GameSupport.TextColor3 = matched and Theme.AccentText or Theme.Secondary
    local active = GameMedia.Active
    local info = active and active.Id == id and active.Partial or id and GameMedia.Cache[id]
    local image = info and info.Icon or GameMedia:GameIcon(game.GameId)
    if UI.GameImage.Image ~= image then
        UI.GameImage.Image = image
    end
    UI.GameImage.Visible = image ~= "" and UI.GameImage.IsLoaded
    if AccessScene.Mode then
        AccessScene:Refresh()
    end
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
    local ok, result = pcall(function()
        local make = capability("makefolder")
        local exists = capability("isfolder")
        if make and (not exists or not exists("PLAK")) then
            pcall(make, "PLAK")
        end
        local http = game:GetService("HttpService")
        -- Whitelist only UI preferences. Never persist tier, authorization or key.
        return write(
            "PLAK/ui_preferences.json",
            http:JSONEncode({
                Version = 1,
                Language = Settings.Language,
                UIScale = Settings.UIScale,
                ReducedMotion = Settings.ReducedMotion,
                CommunityDismissed = Settings.CommunityDismissed,
                RememberMe = Settings.RememberMe,
            })
        )
    end)
    ok = ok and result ~= false
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
        if type(data.RememberMe) == "boolean" then
            Settings.RememberMe = data.RememberMe
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
function Experience:CanRememberKey()
    return type(State.Callbacks.ForgetKey) == "function"
        and capability("readfile") ~= nil
        and capability("writefile") ~= nil
        and capability("isfile") ~= nil
end
function Experience:SetRememberMe(value)
    if not AuthField.Interactive() then
        return false, "busy"
    end
    if not self:CanRememberKey() then
        return false, "storage_unavailable"
    end
    value = value == true
    if Settings.RememberMe == value then
        return true
    end
    -- Block reentry if executor file operations or the host deletion callback yield.
    State.Activity = value and "SavingPreferences" or "ForgettingKey"
    reconcile()
    Settings.RememberMe = value
    self:PreferenceChanged()
    Runtime:Cancel(self.PrefTimer)
    self.PrefTimer = nil
    local saved = self:SavePrefs() -- Commit opt-out before a quick restart can hydrate an old value.
    local ok, removed = true, true
    if not value and State.Alive then
        ok, removed = pcall(State.Callbacks.ForgetKey, Loader)
    end
    if not State.Alive then
        return false, "destroyed"
    end
    State.Activity = "Idle"
    reconcile()
    self:RefreshOptions()
    if not ok or removed ~= true then
        -- Keep OFF even if deletion fails: the host must still skip saving and loading.
        Loader:Toast({ Type = "warning", Subtitle = Localization:Get("keyForgetFailed") })
        return false, "delete_failed"
    end
    if not saved then
        Loader:Toast({ Type = "warning", Subtitle = Localization:Get(self.PrefSaveState) })
    end
    -- Do not erase the field, change premium state or revoke the current session.
    return true
end
function Experience:PresentOptions()
    local blocked = not State.Visible or State.Modal or State.Activity ~= "Idle"
    local open = self.OptionsOpen == true and not blocked
    if self.OptionsPresented == open and not (blocked and UI.Preferences.Visible) then
        return
    end
    self.OptionsPresented = open
    self.OptionsToken = (self.OptionsToken or 0) + 1
    local token = self.OptionsToken
    local rest = self.PreferencesRest or UI.Preferences.Position
    if blocked or (not open and not UI.Preferences.Visible) then
        Animation:CancelTree(UI.Preferences)
        Animation:CancelTree(UI.PreferencesBackdrop)
        UI.Preferences.Visible, UI.PreferencesBackdrop.Visible = false, false
        UI.Preferences.GroupTransparency, UI.PreferencesBackdrop.BackgroundTransparency = 1, 1
        UI.Preferences.Position = rest
        return
    end
    if open then
        if not UI.Preferences.Visible then
            UI.Preferences.GroupTransparency = Settings.ReducedMotion and 0 or 1
            UI.Preferences.Position = rest + UDim2.fromOffset(Settings.ReducedMotion and 0 or Motion.SheetDistance, 0)
        end
        UI.Preferences.Visible, UI.PreferencesBackdrop.Visible = true, true
        Animation:To(UI.Preferences, { Position = rest }, Motion.Panel)
        Animation:To(UI.Preferences, { GroupTransparency = 0 }, Motion.Panel)
        Animation:To(UI.PreferencesBackdrop, { BackgroundTransparency = 0.48 }, Motion.Panel)
    else
        Animation:To(UI.PreferencesBackdrop, { BackgroundTransparency = 1 }, Motion.Exit)
        Animation:To(UI.Preferences, {
            Position = rest + UDim2.fromOffset(Settings.ReducedMotion and 0 or Motion.SheetDistance, 0),
        }, Motion.Exit)
        Animation:To(UI.Preferences, { GroupTransparency = 1 }, Motion.Exit, function()
            if token == self.OptionsToken and not self.OptionsOpen then
                UI.Preferences.Visible, UI.PreferencesBackdrop.Visible = false, false
                UI.Preferences.Position = self.PreferencesRest or rest
            end
        end)
    end
end
function Experience:RefreshOptions()
    if UI.DiagnosticsToggle then
        UI.DiagnosticsToggle:SetDisabled(State.Activity ~= "Idle")
    end
    if UI.DiagnosticsPanel then
        UI.DiagnosticsPanel.Visible = Diagnostics.Open and self.OptionsOpen
    end
    if not UI.Preferences then
        return
    end
    self:PresentOptions()
    UI.Options.ContextHovered = self.OptionsOpen
    UI.Options:Apply()
    Localization:Bind(UI.PreferenceLanguage.Label, "languageOption")
    UI.PreferenceLanguage.ValueLabel.Text = Settings.Language:upper()
    Localization:Bind(UI.PreferenceScale.Label, "scaleOption")
    UI.PreferenceScale.ValueLabel.Text = math.floor(Settings.UIScale * 100 + 0.5) .. "%"
    Localization:Bind(UI.PreferenceMotion.Label, "motionOption")
    Localization:Bind(UI.PreferenceMotion.ValueLabel, Settings.ReducedMotion and "motionReduced" or "motionFull")
    for _, button in ipairs({ UI.PreferenceLanguage, UI.PreferenceScale, UI.PreferenceMotion }) do
        button.Root:SetAttribute("ActionLabel", button.Label.Text .. ": " .. button.ValueLabel.Text)
    end
    Localization:Bind(UI.PreferenceNote, self.PrefSaveState or "prefSession")
    local busy = State.Activity ~= "Idle"
    local rememberAvailable = self:CanRememberKey()
    UI.PasteKey:SetDisabled(busy or not capability("getclipboard"))
    UI.RememberMe:SetDisabled(busy or not rememberAvailable)
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
    UI.RememberMe.Root:SetAttribute("ActionLabel", Localization:Get("rememberMe"))
    UI.RememberMe.Root:SetAttribute(
        "DisabledReason",
        not rememberAvailable and Localization:Get("keyRememberUnavailable") or ""
    )
    Localization:Bind(UI.KeyActionsNote, "empty", "Text", function()
        if not capability("getclipboard") then
            return Localization:Get("clipboardUnavailable")
        elseif not rememberAvailable then
            return Localization:Get("keyRememberUnavailable")
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
    UI.ProgressCheckScale.Scale = 1
    AccessScene:Refresh()
    UI.ProgressLicense.Text = self:LicenseText()
end
-- Frontend milestones only: key request, actual acceptance, pending host handoff.
function Experience:RefreshJourney()
    if not UI.AuthJourneyNodes then
        return
    end
    local accepted = State.Authorized and (self.Stage == "authGranted" or State.Activity == "Completing")
    local linkLoading = self.Stage == "keyLinkLoading"
    local checking = State.Activity == "Validating" and not linkLoading
    UI.AuthJourney.Visible = checking or accepted or linkLoading
    local handoff = accepted and State.Activity == "Completing" and type(State.Callbacks.Authorized) == "function"
    for index, node in ipairs(UI.AuthJourneyNodes) do
        node.Root.Visible = not linkLoading
        local done = accepted and index <= 2
        local active = index == 1 and not accepted or index == 3 and handoff
        node.Dot.BackgroundColor3 = done and Theme.Accent
            or active and (State.AuthError and Theme.Danger or Theme.Accent)
            or Theme.Muted
        node.Dot.BackgroundTransparency = done and 0 or active and 0.1 or 0.7
        node.Check.Root.Visible = done
        if done and not self.WasAccepted then
            node.CheckScale.Scale = Settings.ReducedMotion and 1 or 0.88
            Animation:To(node.CheckScale, { Scale = 1 }, Motion.Page)
        end
        node.Label.TextColor3 = (done or active) and Theme.Text or Theme.Secondary
        if index == 1 and checking and not self.WasChecking then
            Animation:To(node.Scale, { Scale = 1.06 }, Motion.Press, function()
                Animation:To(node.Scale, { Scale = 1 }, Motion.Page)
            end)
        end
    end
    for index, rail in ipairs(UI.AuthJourneyRails or {}) do
        rail.Root.Visible = not linkLoading
        local filled = accepted and (index == 1 or handoff)
        Animation:To(rail.Fill, { Size = UDim2.fromScale(filled and 1 or 0, 1) }, Motion.Toggle)
    end
    self.WasChecking, self.WasAccepted = checking, accepted
    if UI.AuthJourneyNote then
        Localization:Bind(UI.AuthJourneyNote, handoff and "handoffReady" or "journeyHint")
    end
end
function Experience:BuildJourney()
    UI.AuthJourney = frame(UI.AuthBody, "VerificationJourney", Theme.Input)
    UI.AuthJourney.BackgroundTransparency = 1
    corner(UI.AuthJourney, Theme.PanelRadius)
    UI.AuthJourneyNodes = {}
    UI.AuthJourneyRails = {}
    for index = 1, 2 do
        local rail = frame(UI.AuthJourney, "MilestoneConnector" .. index, Theme.Line)
        local fill = frame(rail, "Accepted", Theme.Accent)
        fill.Size = UDim2.fromScale(0, 1)
        UI.AuthJourneyRails[index] = { Root = rail, Fill = fill }
    end
    for index, key in ipairs({ "journeyKey", "journeyVerified", "journeyReady" }) do
        local node = { Root = frame(UI.AuthJourney, "Milestone" .. index) }
        node.Root.BackgroundTransparency = 1
        node.Dot = frame(node.Root, "StateDot", Theme.Muted)
        corner(node.Dot, 100)
        node.Scale = create("UIScale", { Scale = 1 }, node.Dot)
        node.Check = Icon.new(node.Root, "check", Theme.Text, 12)
        node.CheckScale = create("UIScale", { Scale = 1 }, node.Check.Root)
        node.Check.Root.Visible = false
        node.Label = localized(node.Root, "Caption", key, 11, Theme.Secondary, Theme.Medium)
        node.Label.TextWrapped = true
        node.Label.TextXAlignment = Enum.TextXAlignment.Center
        UI.AuthJourneyNodes[index] = node
    end
    UI.AuthStatus.Parent = UI.AuthJourney
    UI.AuthJourneyNote = localized(UI.AuthJourney, "HandoffCaption", "journeyHint", 11, Theme.Secondary)
    UI.AuthJourneyNote.TextWrapped = true
    UI.AuthJourneyNote.TextTruncate = Enum.TextTruncate.AtEnd
    self:RefreshJourney()
end
function Experience:Measure(width)
    self.StatusHeight = math.clamp(measure(Localization:Get(self.Stage), 12, Theme.Font, math.max(1, width)), 24, 54)
end
function Experience:Height()
    return math.max(44, math.ceil(44 / math.max(0.1, State.Layout.Scale or 1)))
        + 12
        + (State.Authorized and 28 or 0)
        + Community:Height()
end

function Experience:FitButton(button)
    if not button then
        return
    end
    local inset = button.Track and 52 or button.Icon and button.Icon.Root.Visible and 44 or 16
    local width = math.max(1, button.Root.Size.X.Offset - inset)
    button.Label.TextSize = width < 120 and 12 or 13
    button.Label.TextWrapped = true
end
function Experience:Layout(width, y)
    local hit = math.max(44, math.ceil(44 / math.max(0.1, State.Layout.Scale or 1)))
    place(UI.RememberMe.Root, 0, y, width, hit)
    UI.KeyActionsNote.Visible = false -- Feedback uses the reserved guidance slot.
    y = y + hit + 8
    UI.AuthLicense.Visible = State.Authorized
    if State.Authorized then
        place(UI.AuthLicense, 0, y, width, 24)
        y = y + 28
    end
    UI.CommunityDetails.Root.Visible = false -- The persistent invitation has its own Details target.
    Community:Layout(width, y)
    local panelWidth = math.min(420, State.Layout.Width - 24)
    local inner = panelWidth - 32
    local step = math.max(hit, 52)
    place(UI.PreferenceWell, 0, 0, inner, step * 3)
    for index, button in ipairs({ UI.PreferenceLanguage, UI.PreferenceScale, UI.PreferenceMotion }) do
        place(button.Root, 0, (index - 1) * step, inner, step)
        place(button.RowIcon.Root, 12, (step - 18) / 2, 18, 18)
        local valueWidth = button == UI.PreferenceMotion and math.min(162, inner * 0.45) or 60
        if inner < 260 then
            button.Label.Position, button.Label.Size = UDim2.fromOffset(42, 5), UDim2.new(1, -76, 0, 18)
            button.ValueLabel.Position, button.ValueLabel.Size =
                UDim2.fromOffset(42, step - 21), UDim2.new(1, -76, 0, 17)
            button.ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
        else
            place(button.ValueLabel, inner - valueWidth - 30, 0, valueWidth, step)
            button.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            button.Label.Position, button.Label.Size = UDim2.fromOffset(42, 0), UDim2.new(1, -valueWidth - 82, 1, 0)
        end
        place(button.ValueChevron.Root, inner - 24, (step - 12) / 2, 12, 12)
    end
    for index, divider in ipairs(UI.PreferenceDividers) do
        place(divider, 42, index * step, inner - 54, 1)
    end
    local actionsY, splitActions = step * 3 + 12, inner >= 320
    local actionWidth = splitActions and (inner - 12) / 2 or inner
    for index, button in ipairs({ UI.PreferenceReset, UI.CommunityRestore }) do
        place(
            button.Root,
            splitActions and (index - 1) * (actionWidth + 12) or 0,
            actionsY + (splitActions and 0 or (index - 1) * (hit + 4)),
            actionWidth,
            hit
        )
        button.Icon.Root.AnchorPoint = Vector2.new(0, 0.5)
        place(button.Icon.Root, 8, hit / 2, 18, 18)
        button.Label.Position, button.Label.Size = UDim2.fromOffset(36, 0), UDim2.new(1, -44, 1, 0)
        button.Label.TextXAlignment = Enum.TextXAlignment.Left
    end
    local noteY = actionsY + (splitActions and hit or hit * 2 + 4) + 16
    local noteHeight =
        math.max(36, measure(Localization:Get(self.PrefSaveState or "prefSession"), 12, Theme.Font, inner))
    place(UI.PreferenceNote, 0, noteY, inner, noteHeight)
    local diagY = noteY + noteHeight + 12
    place(UI.DiagnosticsToggle.Root, 0, diagY, inner, hit)
    UI.DiagnosticsToggle.Icon.Root.AnchorPoint = Vector2.new(0, 0.5)
    place(UI.DiagnosticsToggle.Icon.Root, 8, hit / 2, 18, 18)
    Diagnostics.Top = diagY + hit + 12
    Diagnostics:Layout(inner)
    local bodyHeight = Diagnostics.Top + Diagnostics:Height() + 8
    local header = math.max(78, hit + 24)
    place(UI.PreferencesHeaderDivider, 16, header - 2, inner, 1)
    local panelHeight = math.min(State.Layout.Height - 24, header + bodyHeight + 24)
    local rest = UDim2.fromOffset(State.Layout.Width - panelWidth - 12, 12)
    if self.PreferencesRest ~= rest then
        Animation:CancelProperty(UI.Preferences, "Position")
        UI.Preferences.Position = rest
        self.PreferencesRest = rest
    end
    UI.Preferences.Size = UDim2.fromOffset(panelWidth, math.max(hit + 48, panelHeight))
    local headerIcon = panelWidth >= 260
    local titleX = headerIcon and 56 or 16
    UI.PreferencesTitle.TextSize = headerIcon and 20 or 18
    UI.PreferencesIcon.Root.Visible = headerIcon
    place(UI.PreferencesIcon.Root, 16, 20, 24, 24)
    place(UI.PreferencesTitle, titleX, 12, panelWidth - hit - titleX - 24, 28)
    place(UI.PreferenceSectionLabel, titleX, 43, panelWidth - titleX - 20, 20)
    place(UI.PreferenceClose.Root, panelWidth - hit - 8, 8, hit, hit)
    place(UI.PreferencesScroll, 16, header + 8, inner, math.max(20, panelHeight - header - 24))
    UI.PreferencesContent.Size = UDim2.fromOffset(inner, bodyHeight)
    UI.PreferencesScroll.CanvasSize = UDim2.fromOffset(0, bodyHeight)
    UI.PreferencesScroll.ScrollingEnabled = bodyHeight > UI.PreferencesScroll.Size.Y.Offset
    UI.PreferencesScroll.CanvasPosition = Vector2.new(
        0,
        math.clamp(
            UI.PreferencesScroll.CanvasPosition.Y,
            0,
            math.max(0, bodyHeight - UI.PreferencesScroll.Size.Y.Offset)
        )
    )
    self:PresentOptions()
    for _, button in ipairs({
        UI.GetKey,
        UI.RememberMe,
        UI.Options,
        UI.PreferenceLanguage,
        UI.PreferenceScale,
        UI.PreferenceMotion,
        UI.PreferenceReset,
        UI.CommunityRestore,
        UI.DiagnosticsToggle,
    }) do
        self:FitButton(button)
    end
end

function Experience:Build()
    local function secondary(name, key, callback, parent)
        local button = Button.new(parent or UI.AuthBody, name, "", false, nil, callback, Runtime, function()
            return parent == UI.PreferencesContent and canInteract() or AuthField.Interactive()
        end)
        button.BaseColor = Theme.Surface
        button:Apply()
        Localization:Bind(button.Label, key)
        return button
    end
    UI.PasteKey = secondary("PasteKey", "pasteKey", function()
        self:Paste()
    end, UI.KeyContainer)
    UI.PasteKey.Root.BackgroundTransparency = 1
    UI.PasteKey.Ghost = true
    UI.PasteKey.Label.Visible = false
    UI.PasteKey.Root:SetAttribute("ActionLabel", Localization:Get("pasteKey"))
    UI.PasteGlyph = Icon.new(UI.PasteKey.Root, "copy", Theme.Secondary, 18)
    place(UI.PasteGlyph.Root, 13, 13, 18, 18)
    UI.RememberMe = secondary("RememberMe", "rememberMe", function()
        self:SetRememberMe(not Settings.RememberMe)
    end)
    do
        local toggle = UI.RememberMe
        toggle.Root.BackgroundTransparency = 1
        toggle.Root:SetAttribute("ControlType", "Toggle")
        toggle.Label.TextXAlignment = Enum.TextXAlignment.Left
        toggle.Label.Size = UDim2.new(1, -52, 1, 0)
        toggle.Track = frame(toggle.Root, "SwitchTrack", Theme.ToggleTrackOff)
        toggle.Track.AnchorPoint = Vector2.new(1, 0.5)
        toggle.Track.Position = UDim2.new(1, -4, 0.5, 0)
        toggle.Track.Size = UDim2.fromOffset(36, 14)
        corner(toggle.Track, 7)
        toggle.TrackEdge = stroke(toggle.Track, Theme.Line, 1, 0.62)
        toggle.Knob = frame(toggle.Track, "SwitchKnob", Theme.ToggleKnobOff)
        toggle.Knob.AnchorPoint = Vector2.new(0.5, 0.5)
        toggle.Knob.Size = UDim2.fromOffset(10, 10)
        toggle.Knob.Position = UDim2.new(0, Settings.RememberMe and 29 or 7, 0.5, 0)
        corner(toggle.Knob, 5)
        function toggle:Apply()
            local on = Settings.RememberMe
            local track = self.Disabled and Theme.Input or on and Theme.ToggleTrackOn or Theme.ToggleTrackOff
            local knob = self.Disabled and Theme.ToggleKnobDisabled or on and Theme.ToggleKnobOn or Theme.ToggleKnobOff
            if not self.Disabled and self.Hovered then
                track = track:Lerp(Theme.Text, 0.035)
            end
            if not self.Disabled and self.Pressed then
                knob = knob:Lerp(track, 0.12)
            end
            self.Root.Selectable = not self.Disabled
            self.Root:SetAttribute("Value", on)
            self.Label.TextColor3 = self.Disabled and Theme.Muted or Theme.Text
            Animation:To(self.Track, { BackgroundColor3 = track }, Motion.Toggle)
            Animation:To(self.TrackEdge, { Transparency = self.Disabled and 0.85 or on and 0.7 or 0.48 }, Motion.Toggle)
            Animation:To(self.Knob, {
                BackgroundColor3 = knob,
                Position = UDim2.new(0, on and 29 or 7, 0.5, 0),
            }, Motion.Toggle)
        end
        toggle:Apply()
    end
    UI.Options = Button.new(UI.Sidebar, "PreferencesToggle", "", false, "settings", function()
        Loader:ShowPreferences(not self.OptionsOpen)
    end, Runtime, canInteract)
    Localization:Bind(UI.Options.Label, "preferencesTitle")
    UI.Options.Root.BackgroundTransparency = 1
    UI.Options.Ghost = true
    UI.KeyGuidance = localized(UI.AuthBody, "KeyGuidance", "keyGuidance", 12, Theme.Secondary)
    UI.KeyGuidance.TextWrapped = true
    UI.KeyGuidance.TextYAlignment = Enum.TextYAlignment.Top
    UI.KeyFeedbackMore = Button.new(UI.AuthBody, "ErrorDetails", "…", false, nil, function()
        local feedback = State.AuthFeedback
        if feedback then
            Modal:Open({
                Type = "warning",
                TitleKey = "authFailed",
                Description = feedback.Message or Localization:Get(feedback.Key),
            })
        end
    end, Runtime, AuthField.Interactive)
    UI.KeyFeedbackMore.Root.Visible = false
    UI.KeyFeedbackMore.Root:SetAttribute("ActionLabel", Localization:Get("moreDetails"))
    UI.KeyActionsNote = label(UI.AuthBody, "KeyActionsNote", "", 12, Theme.Secondary)
    UI.KeyActionsNote.TextTruncate = Enum.TextTruncate.AtEnd
    UI.KeyActionsNote.TextWrapped = true
    UI.AuthStatus = label(UI.AuthBody, "AuthStatus", "", 12, Theme.Secondary)
    UI.AuthStatus.TextWrapped = true
    UI.AuthStatus.TextTruncate = Enum.TextTruncate.AtEnd
    self:BuildJourney()
    UI.AuthLicense = label(UI.AuthBody, "AuthLicense", "", 12, Theme.Text)
    UI.AuthLicense.TextTruncate = Enum.TextTruncate.AtEnd
    UI.CurrentGame = frame(UI.AuthBody, "CurrentGame", Theme.Input)
    corner(UI.CurrentGame, Theme.PanelRadius)
    UI.GamePlaceholder = frame(UI.CurrentGame, "GameIcon", Theme.Elevated)
    UI.GamePlaceholder.ClipsDescendants = true
    corner(UI.GamePlaceholder, Theme.PanelRadius)
    UI.GameFallback = Icon.new(UI.GamePlaceholder, "grid", Theme.Secondary, 20)
    UI.GameImage = create(
        "ImageLabel",
        { Name = "GameImage", BackgroundTransparency = 1, Image = "", Visible = false, ScaleType = Enum.ScaleType.Crop },
        UI.GamePlaceholder
    )
    corner(UI.GameImage, Theme.PanelRadius)
    stroke(UI.GamePlaceholder, Theme.Line, 1, 0.55)
    UI.GameContextTag = localized(UI.CurrentGame, "ContextType", "game", 10, Theme.Muted, Theme.Medium)
    UI.GameContextTag.TextXAlignment = Enum.TextXAlignment.Right
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
            Artwork = { Set = function() end }, -- The Home GameIcon owns the square identity image.
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
    UI.PreferencesBackdrop = create("TextButton", {
        Name = "PreferencesBackdrop",
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 11,
        Visible = false,
        Active = true,
        Selectable = false,
    }, UI.Window)
    Runtime:Connect(UI.PreferencesBackdrop.Activated, function()
        Loader:ShowPreferences(false)
    end)
    UI.Preferences = group(UI.Window, "Preferences")
    UI.Preferences.BackgroundColor3, UI.Preferences.BackgroundTransparency = Theme.Elevated, 0
    UI.Preferences.ZIndex, UI.Preferences.Visible, UI.Preferences.Active = 12, false, true
    corner(UI.Preferences, Theme.PanelRadius)
    stroke(UI.Preferences, Theme.WindowEdge, 1, 0.35)
    Material:Panel(UI.Preferences)
    UI.PreferencesHeaderDivider = frame(UI.Preferences, "HeaderDivider", Theme.Edge)
    UI.PreferencesIcon = Icon.new(UI.Preferences, "sliders", Theme.AccentText, 24)
    UI.PreferencesTitle = localized(UI.Preferences, "Title", "preferencesTitle", 20, Theme.Text, Theme.Bold)
    UI.PreferenceClose = Button.new(UI.Preferences, "ClosePreferences", "", false, "x", function()
        Loader:ShowPreferences(false)
    end, Runtime, canInteract)
    UI.PreferenceClose.Root.BackgroundTransparency = 1
    UI.PreferenceClose.Ghost = true
    UI.PreferenceClose.Label.Visible = false
    UI.PreferenceClose.Icon.Root.Position = UDim2.new(0.5, -9, 0.5, 0)
    UI.PreferenceClose.Root:SetAttribute("ActionLabel", Localization:Get("close"))
    UI.PreferencesScroll = create("ScrollingFrame", {
        Name = "PreferenceScroll",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        VerticalScrollBarInset = Enum.ScrollBarInset.None,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
        ClipsDescendants = true,
    }, UI.Preferences)
    UI.PreferencesContent = frame(UI.PreferencesScroll, "PreferenceContent")
    UI.PreferencesContent.BackgroundTransparency = 1
    UI.PreferenceSectionLabel = localized(UI.Preferences, "Section", "session", 11, Theme.Muted, Theme.Medium)
    UI.PreferenceWell = frame(UI.PreferencesContent, "SettingWell", Theme.Input)
    corner(UI.PreferenceWell, Theme.InputRadius)
    UI.PreferenceDividers = {}
    for index = 1, 2 do
        UI.PreferenceDividers[index] = frame(UI.PreferenceWell, "Divider", Theme.Edge)
        UI.PreferenceDividers[index].BackgroundTransparency = 0.5
    end
    UI.PreferenceLanguage = secondary("Language", "languageOption", function()
        local order = { en = "es", es = "pt", pt = "ru", ru = "en" }
        Loader:SetLanguage(order[Settings.Language] or "en")
    end, UI.PreferencesContent)
    UI.PreferenceScale = secondary("Scale", "scaleOption", function()
        local nextScale = Settings.UIScale < 0.95 and 1 or Settings.UIScale < 1.05 and 1.1 or 0.9
        Loader:SetUIScale(nextScale)
    end, UI.PreferencesContent)
    UI.PreferenceMotion = secondary("Motion", "motionFull", function()
        Loader:SetReducedMotion(not Settings.ReducedMotion)
    end, UI.PreferencesContent)
    UI.PreferenceReset = secondary("Reset", "resetOptions", function()
        Loader:SetLanguage("en")
        Loader:SetUIScale(1)
        Loader:SetReducedMotion(false)
        Community:Restore()
        self:PreferenceChanged()
    end, UI.PreferencesContent)
    UI.PreferenceReset.Ghost = true
    UI.PreferenceReset.Icon = Icon.new(UI.PreferenceReset.Root, "refresh", Theme.Secondary, 18)
    for index, button in ipairs({ UI.PreferenceLanguage, UI.PreferenceScale, UI.PreferenceMotion }) do
        button.BaseColor, button.Ghost = Theme.Hover, true
        button:Apply()
        button.Label.TextXAlignment = Enum.TextXAlignment.Left
        button.RowIcon =
            Icon.new(button.Root, index == 1 and "globe" or index == 2 and "sliders" or "clock", Theme.Secondary, 18)
        button.ValueLabel = label(button.Root, "Value", "", 12, Theme.Secondary, Theme.Medium)
        button.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
        button.ValueLabel.TextTruncate = Enum.TextTruncate.AtEnd
        button.ValueChevron = Icon.new(button.Root, "chevron", Theme.Muted, 12)
        button.ValueChevron.Root.Rotation = -90
        button:Apply()
    end
    UI.PreferenceNote = label(UI.PreferencesContent, "SaveState", "", 12, Theme.Secondary)
    UI.PreferenceNote.TextWrapped = true
    Community:Build()
    LicenseOffer:BuildTriggers()
    UI.CommunityDetails = secondary("CommunityDetails", "secondaryCommunity", function()
        Community:Open()
    end)
    UI.DiagnosticsToggle = secondary("DiagnosticsToggle", "diagShow", function()
        Diagnostics:Toggle()
    end, UI.PreferencesContent)
    UI.DiagnosticsToggle.Ghost = true
    UI.DiagnosticsToggle.Icon = Icon.new(UI.DiagnosticsToggle.Root, "info", Theme.Secondary, 18)
    UI.DiagnosticsToggle.Label.Position, UI.DiagnosticsToggle.Label.Size =
        UDim2.fromOffset(36, 0), UDim2.new(1, -44, 1, 0)
    UI.DiagnosticsToggle.Label.TextXAlignment = Enum.TextXAlignment.Left
    self:Refresh()
end

function AuthField:Paint()
    if not UI.KeyStroke then
        return
    end
    local active = State.Focused or State.AuthError
    local ink = State.AuthError and Theme.Danger or State.Focused and Theme.AccentText or Theme.Line
    Animation:To(
        UI.KeyStroke,
        { Color = ink, Transparency = active and 0.12 or self.Hovered and 0.32 or 0.48 },
        Motion.Hover
    )
    Animation:To(UI.KeyContainer, {
        BackgroundColor3 = State.AuthError and Theme.Input:Lerp(Theme.Danger, 0.025)
            or State.Focused and Theme.Input:Lerp(Theme.Accent, 0.045)
            or self.Hovered and Theme.Elevated
            or Theme.Input,
    }, Motion.Hover)
    UI.KeyIcon:SetColor(
        State.AuthError and Theme.Danger or State.Focused and Theme.AccentText or Theme.Muted,
        Motion.Hover
    )
    Animation:To(UI.KeyRim, { BackgroundTransparency = active and 0.93 or 0.97 }, Motion.Hover)
    if UI.KeyFocusLine then
        UI.KeyFocusLine.BackgroundColor3 = State.AuthError and Theme.Danger or Theme.Accent
        Animation:To(UI.KeyFocusLine, {
            Size = active and UDim2.new(1, -24, 0, 1) or UDim2.fromOffset(0, 1),
            BackgroundTransparency = active and 0.12 or 1,
        }, Motion.Toggle)
    end
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
    AuthField:Paint()
    reconcile()
    Responsive:Update()
end
function AuthField:SetVisible(value)
    Settings.KeyVisible = value == true
    self:SyncMask()
end
local function authBusy(value)
    if value then
        Experience.OptionsOpen = false
    end
    UI.Validate:SetDisabled(value)
    UI.GetKey:SetDisabled(value)
    UI.RevealKey:SetDisabled(value)
    UI.Key.TextEditable = State.Visible and not value and State.Page == "Auth"
    UI.CommunityDetails:SetDisabled(value)
    UI.Key.Active = UI.Key.TextEditable
    UI.AuthNav:SetDisabled(value)
    UI.ProductsNav:SetDisabled(value)
    UI.RefreshNav:SetDisabled(value)
    LicenseOffer:Refresh()
    Accessibility:HideTooltip()
    Accessibility:Layout()
    UI.DiagnosticsToggle:SetDisabled(value)
    UI.AuthBusyTrack.Visible = value
    Experience:SetStage(value and "authChecking" or "authReady")
    Experience:RefreshOptions()
    if value then
        -- Waiting feedback stays inside the control; its outer geometry never pulses.
        Animation:To(UI.Validate.Scale, { Scale = 1 }, Motion.Press)
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
        if State.Page == "Auth" then
            Animation:To(UI.Auth, { GroupTransparency = 0.12 }, Motion.Page)
        end
    else
        Animation:Cancel(State.AuthSpinner)
        State.AuthSpinner = nil
        Localization:Bind(UI.Validate.Label, "journeyKey")
        if State.Page == "Auth" then
            Animation:To(UI.Auth, { GroupTransparency = 0 }, Motion.Page)
        end
    end
end
-- Frontend bridge only. The host confirms AFTER its provider accepts the key.
-- These methods are not a permission boundary and never check a key themselves.
ExternalAuth = { Mode = false, Consumed = false }
function ExternalAuth:Settle(success, message, info)
    local request = self.Pending
    if not request or request.Done then
        return false, "no_pending_submission"
    end
    if success and (not State.Alive or request.Token ~= State.ValidationToken) then
        return false, "stale_submission"
    end
    if success then
        if type(info) ~= "table" or (info.tier ~= "premium" and info.tier ~= "free") then
            return false, "missing_auth_metadata"
        end
        Loader:SetAuthInfo(info)
        Loader:SetExpiry(info.secondsLeft)
    end
    request.Done = true
    request.Success = success == true
    request.MessageKey = message == nil and (success and "authGranted" or "externalUnconfirmed") or nil
    request.Message = message
    Runtime:Cancel(request.Timer)
    request.Timer = nil
    request.Signal:Fire()
    return true
end
function ExternalAuth:Wait(key)
    if self.Consumed then
        return false, Localization:Get("externalRestart")
    end
    if #key > 512 then
        return false, Localization:Get("externalKeyLong")
    end
    local callback = State.Callbacks.KeySubmit
    if type(callback) ~= "function" then
        return false, Localization:Get("noValidator")
    end
    self.Consumed = true
    local request = { Token = State.ValidationToken, Signal = create("BindableEvent", { Name = "ExternalAuthResult" }) }
    self.Pending = request
    request.Timer = Runtime:Later(30, function()
        if self.Pending == request then
            self:Settle(false)
        end
    end)
    local ok, submitted = pcall(callback, key, Loader)
    if not ok or submitted == false then
        self:Settle(false)
    end
    -- Done is checked before Wait: a synchronous host confirmation cannot be lost.
    if not request.Done then
        request.Signal.Event:Wait()
    end
    Runtime:Cancel(request.Timer)
    request.Signal:Destroy()
    if self.Pending == request then
        self.Pending = nil
    end
    return request.Success == true, request.Message or Localization:Get(request.MessageKey or "externalUnconfirmed")
end
function ExternalAuth:Cancel(message)
    return self:Settle(false, message)
end

-- Shared verified frontend completion; never performs provider authentication.
local function completeAuthorized(token, key, message)
    State.Authorized = true
    local acceptedAt = os.clock()
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
        Experience:RefreshJourney()
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
                Diagnostics.HandoffSeconds = os.clock() - acceptedAt
                Diagnostics:Refresh()
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
        return true
    else
        Modal:Open({
            Type = "success",
            TitleKey = "granted",
            VerifiedAccess = true,
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
    Diagnostics.HandoffSeconds = os.clock() - acceptedAt
    Diagnostics:Refresh()
    if State.Alive and State.Callbacks.Authorized then
        invokeHost(State.Callbacks.Authorized, key, resultMessage, Loader)
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
    Diagnostics.ValidationStarted = os.clock()
    Diagnostics.ValidationSeconds = nil
    Diagnostics.HandoffSeconds = nil
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
        local callbackStarted = os.clock()
        local ok, success, message = pcall(callback, key)
        if not State.Alive or token ~= State.ValidationToken then
            return
        end
        Diagnostics.ValidationSeconds = os.clock() - callbackStarted
        Diagnostics.ValidationStarted = nil
        Diagnostics:Refresh()
        Runtime:Cancel(State.SlowAuthTimer)
        State.SlowAuthTimer = nil
        State.Activity = "Idle"
        authBusy(false)
        if ok and success == true then
            if completeAuthorized(token, key, message) then
                return
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
            local adviceKey = ExternalAuth.Mode and ExternalAuth.Consumed and "externalRestart"
                or kind == "network" and "networkHint"
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
local function requestKeyLink()
    if not AuthField.Interactive() then
        return false, "busy"
    end
    -- No helper call, network wait or extra authentication just to acquire a key.
    return openLink(KEY_REWARD_URL)
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
    UI.AuthHeading = group(UI.AuthBody, "AccessHeading")
    UI.AuthForm = group(UI.AuthBody, "AccessForm")
    UI.HeroA = localized(UI.AuthHeading, "HeroAccent", "homeHeroA", 30, Theme.Text, Theme.Display)
    UI.HeroB = localized(UI.AuthHeading, "HeroWhite", "homeHeroB", 30, Theme.AccentText, Theme.Display)
    UI.HeroA.TextYAlignment = Enum.TextYAlignment.Top
    UI.HeroB.TextYAlignment = Enum.TextYAlignment.Top
    UI.AuthCopy = localized(UI.AuthHeading, "Copy", "homeCopy", 13, Theme.Secondary)
    UI.AuthCopy.TextWrapped = true
    UI.AuthCopy.TextYAlignment = Enum.TextYAlignment.Bottom
    UI.KeyFieldLabel = localized(UI.AuthBody, "KeyFieldLabel", "fieldLabel", 12, Theme.Text, Theme.Medium)
    UI.KeyContainer = frame(UI.AuthBody, "KeyField", Theme.Input)
    corner(UI.KeyContainer, Theme.InputRadius)
    UI.KeyStroke = stroke(UI.KeyContainer, Theme.Line, 1, 0.1)
    Material:Tone(UI.KeyContainer)
    UI.KeyRim = Material:Rim(UI.KeyContainer, Theme.Rim, 0.96)
    UI.KeyFocusLine = frame(UI.KeyContainer, "FocusUnderline", Theme.Accent)
    UI.KeyFocusLine.AnchorPoint = Vector2.new(0.5, 0)
    UI.KeyFocusLine.Position = UDim2.new(0.5, 0, 1, -3)
    UI.KeyFocusLine.Size = UDim2.fromOffset(0, 1)
    corner(UI.KeyFocusLine, 2)
    UI.KeyIcon = Icon.new(UI.KeyContainer, "key", Theme.Muted, 19)
    place(UI.KeyIcon.Root, 15, 15, 19, 19)
    UI.Key = create("TextBox", {
        Name = "Key",
        Text = "",
        PlaceholderText = "",
        PlaceholderColor3 = Theme.Secondary,
        TextColor3 = Theme.Text,
        TextSize = 14,
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
    UI.KeyMask = label(UI.KeyContainer, "KeyMask", "", 14, Theme.Text, Theme.Medium)
    UI.KeyMask.Active = false
    UI.KeyMask.Selectable = false
    UI.KeyMask.TextTruncate = Enum.TextTruncate.AtEnd
    UI.KeyMask.ZIndex = 2
    UI.KeyMask.Visible = false
    UI.RevealKey = Button.new(UI.KeyContainer, "RevealKey", "", false, nil, function()
        AuthField:SetVisible(not Settings.KeyVisible)
    end, Runtime, AuthField.Interactive)
    UI.RevealKey.Root.BackgroundTransparency = 1
    UI.RevealKey.Ghost = true
    UI.RevealKey.Root.ZIndex = 3
    UI.RevealKey.Label.Visible = false
    UI.RevealEye = Icon.new(UI.RevealKey.Root, "eye", Theme.Secondary, 19)
    UI.ConcealEye = Icon.new(UI.RevealKey.Root, "eye-off", Theme.Accent, 19)
    place(UI.RevealEye.Root, 12, 12, 19, 19)
    place(UI.ConcealEye.Root, 12, 12, 19, 19)
    UI.KeyFeedback = label(UI.AuthBody, "KeyFeedback", "", 12, Theme.Danger, Theme.Medium)
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
            -- Editing a new candidate must not look already verified. The
            -- previously accepted session/host entitlement is not revoked here.
            Experience:SetStage("authReady")
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
        AuthField:Paint()
        UI.KeyIcon:SetColor(Theme.Accent)
        Responsive:Update()
    end)
    Runtime:Connect(UI.Key.FocusLost, function(enter)
        State.Focused = false
        reconcile()
        UI.KeyIcon:SetColor(State.AuthError and Theme.Accent or Theme.Muted)
        AuthField:Paint()
        if enter and AuthField.Interactive() then
            validate(UI.Key.Text)
        end
        Responsive:Update()
    end)
    Runtime:Connect(UI.KeyContainer.MouseEnter, function()
        AuthField.Hovered = canInteract()
        AuthField:Paint()
    end)
    Runtime:Connect(UI.KeyContainer.MouseLeave, function()
        AuthField.Hovered = false
        AuthField:Paint()
    end)
    UI.Validate = Button.new(UI.AuthBody, "Validate", "", true, nil, function()
        validate(UI.Key.Text)
    end, Runtime, AuthField.Interactive)
    UI.Validate.Icon = Icon.new(UI.Validate.Root, "chevron-right", Theme.ButtonText, 18)
    Localization:Bind(UI.Validate.Label, "journeyKey")
    UI.GetKey = Button.new(UI.AuthBody, "GetKey", "", false, "support", function()
        requestKeyLink()
    end, Runtime, AuthField.Interactive)
    UI.GetKey.Ghost = true
    Localization:Bind(UI.GetKey.Label, "getKey")
    UI.AuthBusyTrack = frame(UI.Validate.Root, "WaitingTrack", Theme.AccentDark)
    UI.AuthBusyTrack.Position = UDim2.new(0, 14, 1, -8)
    UI.AuthBusyTrack.Size = UDim2.new(1, -28, 0, 2)
    UI.AuthBusyTrack.ClipsDescendants = true
    UI.AuthBusyTrack.Visible = false
    corner(UI.AuthBusyTrack, 2)
    UI.AuthBusyFill = frame(UI.AuthBusyTrack, "IndeterminateFill", Theme.Text)
    corner(UI.AuthBusyFill, 2)
    UI.AccessAside = group(UI.AuthBody, "AccessIdentity")
    UI.AsideDivider = frame(UI.AccessAside, "ContextDivider", Theme.Line)
    UI.AsideDivider.BackgroundTransparency = 0.5
    UI.AuthArtwork = BrandArt.new(UI.AccessAside, "HeroArtwork")
    UI.AuthArtwork:Set(Settings.Artwork)
    Experience:Build()
    for _, root in ipairs({
        UI.KeyFieldLabel,
        UI.KeyContainer,
        UI.KeyFeedback,
        UI.KeyGuidance,
        UI.AuthJourney,
        UI.KeyFeedbackMore.Root,
        UI.Validate.Root,
        UI.GetKey.Root,
    }) do
        root.Parent = UI.AuthForm
    end
    Stagecraft.Groups = { UI.AuthHeading, UI.AuthForm, UI.AccessAside }
    Runtime.Finalizers[#Runtime.Finalizers + 1] = function()
        Stagecraft:Cancel(false)
        table.clear(Stagecraft.Groups)
        table.clear(Stagecraft.Rests)
    end
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
    self.Hovered, self.Selected = nil, nil
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
function Cards:ResetHover()
    local card = self.Hovered
    self.Hovered = nil
    if not card or not card.Root.Parent then
        return
    end
    Animation:To(card.Artwork.Image, { ImageColor3 = Color3.fromRGB(240, 240, 244) }, Motion.Hover)
    if not card.Article and not card.DetailsOpen then
        Animation:To(card.Border, { Color = Theme.Line, Transparency = 0.35 }, Motion.Hover)
    end
    if card.Divider then
        Animation:To(card.Divider, { BackgroundColor3 = Theme.Edge }, Motion.Hover)
    end
end
function Cards:Select(card)
    if not canInteract() or State.Page ~= "Products" then
        return false
    end
    local opening = self.Selected ~= card or not card.DetailsOpen
    self.Selected = opening and card or nil
    for _, other in ipairs(self) do
        other.DetailsOpen = opening and other == card
    end
    self:Layout()
    if opening then
        card.Details.GroupTransparency = Settings.ReducedMotion and 0 or 1
        card.Details.Position = card.DetailsRest + UDim2.fromOffset(0, Settings.ReducedMotion and 0 or 8)
        Animation:To(card.Details, { GroupTransparency = 0, Position = card.DetailsRest }, Motion.Page)
    end
    return true
end

function Cards:Create(product, index)
    local card = { Scope = Scope.new(), Product = product, Index = index, DetailsOpen = false }
    card.Root = group(UI.Catalog, "Product_" .. product.Id)
    card.Root.BackgroundTransparency, card.Root.BackgroundColor3, card.Root.ClipsDescendants = 0, Theme.Elevated, true
    corner(card.Root, Theme.PanelRadius)
    card.Border = stroke(card.Root, Theme.Line, 1, 0.45)
    Material:Tone(card.Root)
    card.Artwork = Artwork.new(
        card.Root,
        "ProductArtwork",
        nil,
        product.Artwork or (product.GameId and GameMedia:Thumbnail(product.GameId))
    )
    card.Artwork.Root.Size = UDim2.new(1, 0, 1, -76)
    card.Artwork.Root.ClipsDescendants = true
    corner(card.Artwork.Root, Theme.InputRadius)
    card.Artwork.Image.ImageColor3 = Color3.fromRGB(240, 240, 244)
    card.Shade = frame(card.Root, "ImageLegibility", Color3.new(0, 0, 0))
    card.Shade.Size, card.Shade.BackgroundTransparency = UDim2.new(1, 0, 1, -76), 0.65
    create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.10),
            NumberSequenceKeypoint.new(0.4, 0.92),
            NumberSequenceKeypoint.new(1, 0.05),
        }),
    }, card.Shade)
    card.Select = Button.new(
        card.Root,
        "InspectGame",
        "",
        false,
        nil,
        function()
            self:Select(card)
        end,
        card.Scope,
        function()
            return canInteract() and State.Page == "Products"
        end
    )
    card.Select.Root.BackgroundTransparency, card.Select.Label.Visible = 1, false
    card.Select.Root:SetAttribute("ActionLabel", Localization:Get("gameInspect") .. " · " .. productName(product))
    card.InspectBadge = frame(card.Select.Root, "InspectAffordance", Theme.Surface)
    card.InspectBadge.BackgroundTransparency = 0.18
    corner(card.InspectBadge, Theme.Radius)
    stroke(card.InspectBadge, Theme.Line, 1, 0.4)
    card.InspectGlyph = Icon.new(card.InspectBadge, "info", Theme.Secondary, 16)
    card.InspectGlyph.Root.AnchorPoint = Vector2.new(0, 0)
    card.Current = frame(card.Root, "CurrentGameBadge", Theme.AccentDark)
    corner(card.Current, 6)
    card.CurrentLabel = localized(card.Current, "CurrentGame", "currentBadge", 11, Theme.Text, Theme.Medium)
    card.CurrentLabel.TextXAlignment = Enum.TextXAlignment.Center
    card.CurrentLabel.TextTruncate = Enum.TextTruncate.AtEnd
    card.Footer = frame(card.Root, "CardFooter", Theme.Input)
    card.FooterRim = Material:Rim(card.Footer, Theme.Rim, 0.96)
    card.Logo = Icon.new(card.Footer, "plak", Theme.AccentText, 22)
    card.Name = label(card.Footer, "ProductName", "", 17, Theme.Text, Theme.Bold)
    card.Name.TextWrapped, card.Name.TextTruncate = true, Enum.TextTruncate.AtEnd
    Localization:Bind(card.Name, "umbrella", "Text", function()
        return productName(product)
    end)
    card.Synopsis = label(card.Footer, "Synopsis", "", 12, Theme.Secondary)
    card.Synopsis.TextWrapped, card.Synopsis.TextTruncate, card.Synopsis.TextYAlignment =
        true, Enum.TextTruncate.AtEnd, Enum.TextYAlignment.Top
    Localization:Bind(card.Synopsis, "productCopy", "Text", function()
        return localizedValue(product.Description, Localization:Get(product.GameId and "gameCopy" or "productCopy"))
    end)
    card.Divider = frame(card.Root, "ArticleDivider", Theme.Edge)
    card.Divider.BackgroundTransparency = 0.35
    card.Details = group(card.Root, "InspectionDetails")
    card.Details.BackgroundColor3, card.Details.BackgroundTransparency, card.Details.Visible =
        Theme.Surface, 0.03, false
    corner(card.Details, Theme.PanelRadius)
    card.DetailsBorder = stroke(card.Details, Theme.Edge, 1, 0.2)
    Material:Panel(card.Details)
    card.DetailsRim = card.Details:FindFirstChild("SurfaceRim")
    card.DetailsTitle = localized(card.Details, "About", "gameAbout", 12, Theme.Secondary, Theme.Medium)
    card.DetailsName = label(card.Details, "GameIdentity", "", 17, Theme.Text, Theme.Bold)
    card.DetailsName.TextWrapped, card.DetailsName.TextTruncate = true, Enum.TextTruncate.AtEnd
    Localization:Bind(card.DetailsName, "umbrella", "Text", function()
        return productName(product)
    end)
    card.Description = label(card.Details, "Description", "", 12, Theme.Text)
    card.Description.TextWrapped, card.Description.TextYAlignment, card.Description.TextTruncate =
        true, Enum.TextYAlignment.Top, Enum.TextTruncate.AtEnd
    Localization:Bind(card.Description, "productCopy", "Text", function()
        return localizedValue(product.Description, Localization:Get(product.GameId and "gameCopy" or "productCopy"))
    end)
    local status = Statuses[product.Status] or Statuses.Disabled
    card.Status = frame(card.Root, "Status", Theme.Surface)
    corner(card.Status, 6)
    card.StatusLabel = localized(card.Status, "StatusText", status.Key, 11, Theme.Text, Theme.Medium)
    card.StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    card.StatusIconBox = frame(card.Root, "StatusIcon", Theme.Surface)
    corner(card.StatusIconBox, 6)
    card.StatusIcon = Icon.new(card.StatusIconBox, status.Icon, Theme.Secondary, 16)
    card.StatusIconBox:SetAttribute("ActionLabel", Localization:Get(status.Key))
    card.Open = Button.new(
        card.Footer,
        "Launch",
        "",
        true,
        "play",
        function()
            launchProduct(product)
        end,
        card.Scope,
        function()
            return canInteract() and State.Page == "Products"
        end
    )
    card.Open.BaseColor = Theme.Inactive
    card.Open:Apply()
    Localization:Bind(card.Open.Label, "gameLaunch")
    card.Dim = frame(card.Root, "InactiveShade", Theme.Surface)
    card.Dim.BackgroundTransparency, card.Dim.Size, card.Dim.Active = 1, UDim2.fromScale(1, 1), false
    local function paint(other, hovered)
        if not other or not other.Root.Parent then
            return
        end
        Animation:To(
            other.Artwork.Image,
            { ImageColor3 = hovered and Color3.new(1, 1, 1) or Color3.fromRGB(240, 240, 244) },
            Motion.Hover
        )
        if other.Article then
            Animation:To(other.Divider, {
                BackgroundColor3 = hovered and Theme.Line or Theme.Edge,
            }, Motion.Hover)
        elseif not other.DetailsOpen then
            Animation:To(other.Border, {
                Color = hovered and Theme.Line:Lerp(Theme.AccentText, 0.22) or Theme.Line,
                Transparency = hovered and 0.15 or 0.45,
            }, Motion.Hover)
        end
    end
    local function hover(value)
        if value and (not canInteract() or State.Page ~= "Products") then
            return
        end
        -- Only old/new hovered cards are painted. No all-catalog hover tween fanout.
        local previous = self.Hovered
        if value then
            if previous ~= card then
                paint(previous, false)
            end
            self.Hovered = card
            paint(card, true)
        elseif previous == card then
            self.Hovered = nil
            paint(card, false)
        end
    end
    card.Scope:Connect(card.Root.MouseEnter, function()
        hover(true)
    end)
    card.Scope:Connect(card.Root.MouseLeave, function()
        hover(false)
    end)
    card.Scope:Connect(card.Select.Root.SelectionGained, function()
        hover(true)
    end)
    card.Scope:Connect(card.Select.Root.SelectionLost, function()
        hover(false)
    end)
    card.Scope:Connect(card.Open.Root.SelectionGained, function()
        hover(true)
    end)
    card.Scope:Connect(card.Open.Root.SelectionLost, function()
        hover(false)
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
            card.Root.Position = card.RestPosition + UDim2.fromOffset(0, Motion.RevealDistance)
            card.RevealThread = card.Scope:Later(math.min(index - 1, 5) * 0.025, function()
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
    local scale = math.max(0.1, UI.Scale.Scale)
    local hit = math.max(44, math.ceil(44 / scale))
    local width = UI.Catalog.AbsoluteSize.X / scale
    local article, gap = width >= 600, 20
    local cardWidth = article and math.floor((width - gap) * 0.52) or width
    local copyWidth = article and width - cardWidth - gap or width
    local artHeight = math.clamp(math.floor(cardWidth * 9 / 16), article and 196 or 156, 252)
    local footerHeight, rowY = hit + 32, 0
    for index, card in ipairs(self) do
        self:SettleReveal(card)
        local titleHeight = article
                and math.clamp(measure(productName(card.Product), 24, Theme.Bold, copyWidth) + 4, 32, 60)
            or footerHeight - 24
        local statusY = titleHeight + 8
        local copyY = statusY + 36
        local inspectionHeight = article
                and 24 + math.clamp(
                    measure(
                        localizedValue(
                            card.Product.Description,
                            Localization:Get(card.Product.GameId and "gameCopy" or "productCopy")
                        ),
                        12,
                        Theme.Font,
                        copyWidth
                    ),
                    48,
                    240
                )
            or 126
        local baseHeight = article
                and math.max(artHeight, copyY + (card.DetailsOpen and inspectionHeight or 60) + 16 + hit)
            or artHeight + footerHeight
        local disclosure = not article and card.DetailsOpen and 138 or 0
        local cardHeight = baseHeight + disclosure + (article and 20 or 0)
        card.Article = article
        place(card.Root, 0, rowY, width, cardHeight)
        card.RestPosition = card.Root.Position
        card.Root.BackgroundTransparency = article and 1 or 0
        Animation:To(card.Border, {
            Color = card.DetailsOpen and Theme.Accent or Theme.Line,
            Transparency = article and 1 or card.DetailsOpen and 0.1 or 0.35,
        }, Motion.Hover)
        place(card.Artwork.Root, 0, 0, cardWidth, artHeight)
        place(card.Shade, 0, 0, cardWidth, artHeight)
        place(card.Select.Root, 0, 0, cardWidth, artHeight)
        place(card.InspectBadge, 12, artHeight - 40, 28, 28)
        place(card.InspectGlyph.Root, 6, 6, 16, 16)
        place(
            card.Footer,
            article and cardWidth + gap or 0,
            article and 0 or artHeight,
            copyWidth,
            article and baseHeight or footerHeight
        )
        card.Footer.BackgroundTransparency = article and 1 or 0
        card.FooterRim.Visible = not article
        card.Divider.Visible = article
        place(card.Divider, 0, cardHeight - 1, width, 1)
        card.Logo.Root.Visible = false
        local actionWidth = article and math.min(180, copyWidth) or cardWidth >= 340 and 116 or hit
        card.Name.TextSize = article and 24 or 14
        place(
            card.Name,
            article and 0 or 16,
            article and 0 or 12,
            article and copyWidth or math.max(1, cardWidth - actionWidth - 44),
            titleHeight
        )
        card.Name.TextYAlignment = article and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
        card.Synopsis.Visible = article and not card.DetailsOpen
        place(card.Synopsis, 0, copyY, copyWidth, 60)
        place(
            card.Open.Root,
            article and 0 or cardWidth - actionWidth - 12,
            article and baseHeight - hit or 16,
            actionWidth,
            hit
        )
        card.Open.Label.Visible = actionWidth > hit
        card.Open.Icon.Root.Position = actionWidth > hit and UDim2.new(0, 14, 0.5, 0) or UDim2.new(0.5, -9, 0.5, 0)
        local dw, dh = article and copyWidth or cardWidth, inspectionHeight
        card.DetailsRest = article and UDim2.fromOffset(cardWidth + gap, copyY) or UDim2.fromOffset(0, baseHeight + 12)
        Animation:CancelTree(card.Details)
        card.DetailsToken = (card.DetailsToken or 0) + 1
        card.Details.Position, card.Details.Size = card.DetailsRest, UDim2.fromOffset(dw, dh)
        card.Details.Visible, card.Details.GroupTransparency = card.DetailsOpen, card.DetailsOpen and 0 or 1
        card.Details.BackgroundColor3 = Theme.Elevated
        card.Details.BackgroundTransparency = article and 1 or 0.03
        card.DetailsBorder.Transparency = article and 1 or 0.2
        card.DetailsRim.Visible, card.DetailsName.Visible = not article, not article
        place(card.DetailsTitle, article and 0 or 16, article and 0 or 12, dw - (article and 0 or 32), 22)
        place(card.DetailsName, 16, article and 0 or 36, dw - 32, 24)
        place(
            card.Description,
            article and 0 or 16,
            article and 24 or 72,
            dw - (article and 0 or 32),
            math.max(32, dh - (article and 24 or 88))
        )
        local currentId = GameMedia:PlaceId(game.PlaceId)
        local current = currentId ~= nil and card.Product.GameId == currentId
        card.Current.Visible = current
        local badgeKey = cardWidth < 220 and "currentBadgeShort" or "currentBadge"
        Localization:Bind(card.CurrentLabel, badgeKey)
        local badgeWidth = math.min(cardWidth - 76, math.max(80, #characters(Localization:Get(badgeKey)) * 5.8 + 20))
        place(card.Current, 12, 12, badgeWidth, 26)
        place(card.CurrentLabel, 6, 0, badgeWidth - 12, 26)
        card.Status.Visible = article or not current or cardWidth >= 340
        local statusText = Localization:Get((Statuses[card.Product.Status] or Statuses.Disabled).Key)
        local maximum = math.max(40, cardWidth - (current and badgeWidth + 86 or 72))
        local statusWidth = math.clamp(#characters(statusText) * 5.8 + 20, math.min(88, maximum), maximum)
        card.Status.BackgroundTransparency = article and 1 or 0
        card.StatusIconBox.BackgroundTransparency = article and 1 or 0
        card.StatusLabel.TextXAlignment = article and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
        place(
            card.Status,
            article and cardWidth + gap + 26 or cardWidth - statusWidth - 50,
            article and statusY or 12,
            article and copyWidth - 26 or statusWidth,
            26
        )
        place(card.StatusLabel, article and 0 or 6, 0, article and copyWidth - 26 or statusWidth - 12, 26)
        place(card.StatusIconBox, article and cardWidth + gap - 4 or cardWidth - 38, article and statusY or 12, 26, 26)
        place(card.StatusIcon.Root, 5, 5, 16, 16)
        card.Select.Root:SetAttribute(
            "ActionLabel",
            Localization:Get("gameInspect") .. " · " .. productName(card.Product)
        )
        card.StatusIconBox:SetAttribute("ActionLabel", statusText)
        rowY = rowY + cardHeight + gap
    end
    UI.Catalog.CanvasSize = UDim2.fromOffset(0, #self > 0 and rowY - gap + 2 or 0)
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
function Navigation:PageRoot(page)
    return page == "Auth" and UI.Auth or page == "Products" and UI.Products or UI.LicensePanel
end
function Navigation:Refresh(instant)
    UI.AuthNav.Root:SetAttribute("ActionLabel", Localization:Get("homeNav"))
    UI.ProductsNav.Root:SetAttribute("ActionLabel", Localization:Get("tipProducts"))
    UI.RefreshNav.Root:SetAttribute("ActionLabel", Localization:Get("tipRefresh"))
    UI.LanguageToggle:SetAttribute("ActionLabel", Localization:Get("tipLanguage"))
    Localization:Bind(UI.Breadcrumb, "homeNav", "Text", function()
        return Localization:Get(
            State.Page == "Auth" and "homeNav" or State.Page == "Products" and "gamesNav" or "licensesNav"
        )
    end)
    Localization:Bind(UI.PageDescription, "pageAccess", "Text", function()
        return Localization:Get(
            State.Page == "Auth" and "pageAccess" or State.Page == "Products" and "pageGames" or "pageLicenses"
        )
    end)
    for index, button in ipairs({ UI.AuthNav, UI.ProductsNav, UI.LicenseNav, UI.RefreshNav }) do
        button.Navigation = true
        button.Selected = index == (State.Page == "Auth" and 1 or State.Page == "Products" and 2 or 3)
        button.BaseColor = Theme.Hover
        button:Apply()
    end
    Localization:Bind(UI.AuthNav.Label, "homeNav")
    Localization:Bind(UI.ProductsNav.Label, "gamesNav")
    Localization:Bind(UI.LicenseNav.Label, "licensesNav")
    Localization:Bind(UI.RefreshNav.Label, "refreshNav")
    LicenseOffer:Refresh()
    UI.ProductMark.Visible, UI.ContextIcon.Root.Visible, UI.Copyright.Visible = false, false, false
    local selected = State.Page == "Auth" and UI.AuthNav.Root
        or State.Page == "Products" and UI.ProductsNav.Root
        or UI.LicenseNav.Root
    UI.ActiveNav.Visible, UI.NavigationPlate.Visible = selected.Visible, selected.Visible
    local marker = UDim2.fromOffset(
        selected.Position.X.Offset + selected.Size.X.Offset - 14,
        selected.Position.Y.Offset + (selected.Size.Y.Offset - 10) / 2
    )
    local markerSize = UDim2.fromOffset(10, 10)
    if instant or not self.PlateReady or Settings.ReducedMotion then
        Animation:CancelProperty(UI.NavigationPlate, "Position")
        Animation:CancelProperty(UI.NavigationPlate, "Size")
        Animation:CancelProperty(UI.ActiveNav, "Position")
        UI.NavigationPlate.Position, UI.NavigationPlate.Size = selected.Position, selected.Size
        UI.ActiveNav.Position, UI.ActiveNav.Size = marker, markerSize
    else
        Animation:To(UI.NavigationPlate, { Position = selected.Position, Size = selected.Size }, Motion.Indicator)
        UI.ActiveNav.Size = markerSize
        Animation:To(UI.ActiveNav, { Position = marker }, Motion.Indicator)
    end
    self.PlateReady = true
end

function Navigation:Go(page, force)
    if not State.Alive or (not force and not canInteract()) then
        return false
    end
    if page ~= "Auth" and page ~= "Products" and page ~= "Licenses" then
        return false
    end
    if page == "Licenses" then
        if not LicenseOffer:Enabled() then
            return false
        end
        LicenseOffer:Build()
    end
    Button:Release(nil, true)
    Stagecraft:Cancel(true)
    closeLanguage()
    Accessibility:Clear()
    UI.AuthArtwork:CancelReveal()
    LicenseOffer:CancelReveal()
    State.PageToken = State.PageToken + 1
    local token = State.PageToken
    local previous, destination = self:PageRoot(State.Page), self:PageRoot(page)
    local oldIndex = State.Page == "Auth" and 1 or State.Page == "Products" and 2 or 3
    local newIndex = page == "Auth" and 1 or page == "Products" and 2 or 3
    local direction = newIndex >= oldIndex and 1 or -1
    local continuing = destination.Visible
    State.Page, State.Focused = page, false
    UI.Key.TextEditable = State.Visible and page == "Auth" and State.Activity == "Idle"
    UI.Key.Active = UI.Key.TextEditable
    UI.Key:ReleaseFocus(false)
    reconcile()
    -- Every root is reconciled on every switch. Old completion closures cannot
    -- resurrect a third page after A -> B -> C -> A in the same animation window.
    for _, root in ipairs({ UI.Auth, UI.Products, UI.LicensePanel }) do
        Animation:CancelProperty(root, "Position")
        Animation:CancelProperty(root, "GroupTransparency")
        if root ~= previous and root ~= destination then
            root.Visible, root.GroupTransparency = false, 1
            root.Position = UDim2.fromOffset(0, 0)
        end
    end
    if previous ~= destination then
        Animation:CancelTree(previous)
        if Settings.ReducedMotion then
            previous.Visible = false
        else
            Animation:To(previous, {
                Position = UDim2.fromOffset(-direction * Motion.PageDistance / 2, 0),
            }, Motion.PageExit)
            Animation:To(previous, { GroupTransparency = 1 }, Motion.PageExit, function()
                if token == State.PageToken and State.Page == page then
                    previous.Visible = false
                    previous.Position = UDim2.fromOffset(0, 0)
                end
            end)
        end
    end
    if not continuing and not Settings.ReducedMotion then
        destination.GroupTransparency = 1
        destination.Position = UDim2.fromOffset(direction * Motion.PageDistance, 0)
    end
    destination.Visible = true
    Animation:To(destination, { Position = UDim2.fromOffset(0, 0) }, Motion.Page)
    Animation:To(destination, { GroupTransparency = 0 }, Motion.Page)
    Cards:ResetHover()
    Responsive:Update()
    if page == "Auth" then
        UI.AuthArtwork:Reveal()
        Stagecraft:Reveal()
    elseif page == "Products" then
        Cards:Reveal()
    else
        LicenseOffer:Reveal()
    end
    Stagecraft:Header(page)
    return true
end
-- Two bounded visual stages, never an auth/progress owner. Each new route wins.
function Stagecraft:Cancel(settle)
    self.Token = self.Token + 1
    for thread in pairs(self.Tasks) do
        Runtime:Cancel(thread)
        self.Tasks[thread] = nil
    end
    for _, root in ipairs(self.Groups) do
        Animation:CancelProperty(root, "Position")
        Animation:CancelProperty(root, "GroupTransparency")
        if settle and root.Parent then
            root.GroupTransparency = 0
            root.Position = self.Rests[root] or root.Position
        end
    end
    if UI.PageHeading then
        Animation:CancelProperty(UI.PageHeading, "Position")
        Animation:CancelProperty(UI.PageHeading, "GroupTransparency")
        if settle and UI.PageHeading.Parent then
            UI.PageHeading.GroupTransparency = 0
            UI.PageHeading.Position = self.Rests[UI.PageHeading] or UDim2.fromOffset(0, 0)
        end
    end
end
function Stagecraft:Place(root, x, y, width, height)
    local rest, size = UDim2.fromOffset(x, y), UDim2.fromOffset(width, height)
    if self.Rests[root] ~= rest or root.Size ~= size then
        for thread, owner in pairs(self.Tasks) do
            if owner == root then
                Runtime:Cancel(thread)
                self.Tasks[thread] = nil
            end
        end
        Animation:CancelProperty(root, "Position")
        Animation:CancelProperty(root, "GroupTransparency")
        root.Position, root.GroupTransparency = rest, 0
        root.Size = size
    end
    self.Rests[root] = rest
end
function Stagecraft:Reveal()
    self:Cancel(true)
    if not State.Alive or Settings.ReducedMotion or not State.Visible or State.Page ~= "Auth" or State.Modal then
        return
    end
    local token = self.Token
    for index, root in ipairs(self.Groups) do
        if root.Visible then
            local target = self.Rests[root] or root.Position
            root.GroupTransparency = 1
            root.Position = target + UDim2.fromOffset(0, Motion.StageDistance)
            local thread
            thread = Runtime:Later((index - 1) * Motion.StageDelay, function()
                self.Tasks[thread] = nil
                if
                    token == self.Token
                    and State.Visible
                    and State.Page == "Auth"
                    and not State.Modal
                    and root.Parent
                then
                    Animation:To(root, { Position = target, GroupTransparency = 0 }, Motion.Page)
                end
            end)
            if thread then
                self.Tasks[thread] = root
            end
        end
    end
end
function Stagecraft:Header(page)
    local changed = self.HeaderPage ~= page
    self.HeaderPage = page
    local root = UI.PageHeading
    if not root or not root.Visible or not changed or Settings.ReducedMotion or not State.Visible then
        return
    end
    local target = self.Rests[root] or UDim2.fromOffset(0, 0)
    root.Position, root.GroupTransparency = target + UDim2.fromOffset(Motion.StageDistance, 0), 1
    Animation:To(root, { Position = target, GroupTransparency = 0 }, Motion.Page)
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
    local hit = math.max(44, math.ceil(44 / math.max(0.1, State.Layout.Scale or 1)))
    local aside = not narrow and width >= 640 and height >= 300
    local asideWidth = aside and 224 or 0
    local left = aside and width - asideWidth - 28 or width
    local tiny = height < 180
    local hero = not State.Layout.KeyboardCompact and height >= 260
    local fontSize = aside and (left >= 400 and 40 or 36) or left >= 400 and 30 or 26
    -- Always measure canonical copy, never the intermediate language-decode glyphs.
    local a = TextMetrics:Get(Localization:Get("homeHeroA"), fontSize, Theme.Display, 10000)
    local b = TextMetrics:Get(Localization:Get("homeHeroB"), fontSize, Theme.Display, 10000)
    local aWidth, bWidth = math.ceil(a and a.X or left), math.ceil(b and b.X or left)
    local inline = not aside and aWidth + bWidth + 12 <= left
    local lineHeight = fontSize + 6
    local secondY = fontSize + 4
    local headingHeight = hero and (inline and lineHeight + 8 or secondY + lineHeight + 4) or 0
    UI.AuthHeading.Visible = hero
    UI.HeroA.Visible, UI.HeroB.Visible, UI.AuthCopy.Visible = hero, hero, false
    UI.HeroA.TextSize, UI.HeroB.TextSize = fontSize, fontSize
    place(UI.HeroA, 0, 0, inline and aWidth + 2 or left, lineHeight)
    place(
        UI.HeroB,
        inline and aWidth + 12 or 0,
        inline and 0 or secondY,
        inline and left - aWidth - 12 or left,
        lineHeight
    )
    Stagecraft:Place(UI.AuthHeading, 0, 0, left, headingHeight)
    local gameY = hero and headingHeight + 12 or 0
    local gameHeight = tiny and 0 or 52
    UI.CurrentGame.Parent = aside and UI.AccessAside or UI.AuthBody
    UI.CurrentGame.Visible = not tiny
    local contextWidth = aside and asideWidth or left
    local iconSize = aside and 40 or 48
    local textX = iconSize + 16
    place(UI.CurrentGame, 0, aside and 260 or gameY, contextWidth, aside and 68 or gameHeight)
    place(UI.GamePlaceholder, 0, 2, iconSize, iconSize)
    place(UI.GameFallback.Root, (iconSize - 20) / 2, (iconSize - 20) / 2, 20, 20)
    place(UI.GameImage, 0, 0, iconSize, iconSize)
    UI.GameContextTag.Visible = not aside and left >= 400
    place(UI.GameContextTag, math.max(0, left - 56), 3, 56, 26)
    UI.GameName.TextWrapped = aside
    place(
        UI.GameName,
        textX,
        1,
        math.max(1, contextWidth - textX - (not aside and left >= 400 and 64 or 0)),
        aside and 36 or 26
    )
    place(UI.GameSupport, textX, aside and 39 or 30, math.max(1, contextWidth - textX), 20)
    UI.CurrentGame.BackgroundTransparency = 1
    UI.GameName.TextSize = 14
    UI.GameSupport.TextSize = 12
    local formY = State.Layout.KeyboardCompact and 0 or aside and headingHeight + 20 or gameY + gameHeight + 14
    local labelY = 0
    UI.KeyFieldLabel.Visible = not State.Layout.KeyboardCompact
    place(UI.KeyFieldLabel, 0, labelY, left, 20)
    local inputY, controlHeight = State.Layout.KeyboardCompact and 0 or labelY + 22, math.max(hit, aside and 60 or 52)
    place(UI.KeyContainer, 0, inputY, left, controlHeight)
    local hasIcon = left >= 244
    UI.KeyIcon.Root.Visible = hasIcon
    local inset = hasIcon and 40 or 12
    place(UI.KeyIcon.Root, 12, (controlHeight - 18) / 2, 18, 18)
    local actionsWidth = hit * 2 + 8
    UI.Key.Position, UI.Key.Size = UDim2.fromOffset(inset, 0), UDim2.new(1, -inset - actionsWidth - 8, 1, 0)
    State.Layout.KeyWidth = math.max(1, left - inset - actionsWidth - 8)
    UI.Key.PlaceholderText = AuthField:Hint()
    UI.KeyMask.Position, UI.KeyMask.Size = UI.Key.Position, UI.Key.Size
    place(UI.PasteKey.Root, left - actionsWidth, (controlHeight - hit) / 2, hit, hit)
    place(UI.RevealKey.Root, left - hit - 4, (controlHeight - hit) / 2, hit, hit)
    place(UI.PasteGlyph.Root, (hit - 18) / 2, (hit - 18) / 2, 18, 18)
    place(UI.RevealEye.Root, (hit - 19) / 2, (hit - 19) / 2, 19, 19)
    place(UI.ConcealEye.Root, (hit - 19) / 2, (hit - 19) / 2, 19, 19)
    local guidanceY = inputY + controlHeight + 10
    local guidanceHeight = math.max(58, measure(Localization:Get("keyGuidance"), 12, Theme.Font, left))
    local feedback = State.AuthFeedback
    local text = feedback and (feedback.Message or Localization:Get(feedback.Key)) or ""
    local needDetails = feedback and measure(text, 12, Theme.Medium, math.max(1, left - hit - 8)) > guidanceHeight
    place(UI.KeyFeedback, 0, guidanceY, left - (needDetails and hit + 8 or 0), guidanceHeight)
    place(UI.KeyGuidance, 0, guidanceY, left, guidanceHeight)
    UI.KeyGuidance.Visible = not State.AuthError and not UI.AuthJourney.Visible
    Localization:Bind(UI.KeyGuidance, "keyGuidance", "Text", function()
        return Localization:Get("keyGuidance")
    end)
    place(UI.AuthJourney, 0, guidanceY, left, guidanceHeight)
    local nodeWidth = (left - 16) / 3
    for index, node in ipairs(UI.AuthJourneyNodes) do
        place(node.Root, 8 + (index - 1) * nodeWidth, 2, nodeWidth, 28)
        place(node.Dot, nodeWidth / 2 - 5, 0, 10, 10)
        place(node.Check.Root, nodeWidth / 2 - 5, 0, 10, 10)
        node.Label.TextSize = 11
        place(node.Label, 0, 12, nodeWidth, 16)
    end
    for index, rail in ipairs(UI.AuthJourneyRails) do
        place(rail.Root, 8 + (index - 0.5) * nodeWidth + 10, 7, math.max(1, nodeWidth - 20), 1)
    end
    place(UI.AuthStatus, 8, 33, left - 16, 22)
    UI.AuthStatus.TextSize, UI.AuthStatus.TextXAlignment = 12, Enum.TextXAlignment.Left
    UI.AuthJourneyNote.Visible = false
    UI.KeyFeedbackMore.Root.Visible = needDetails == true
    place(UI.KeyFeedbackMore.Root, left - hit, guidanceY, hit, hit)
    local buttonY = guidanceY + guidanceHeight + 8
    local primaryBounds = TextMetrics:Get(Localization:Get("journeyKey"), 14, Theme.Medium, 10000)
    local busyBounds = TextMetrics:Get(Localization:Get("validating"), 14, Theme.Medium, 10000)
    local primaryText = math.max(primaryBounds and primaryBounds.X or left, busyBounds and busyBounds.X or left)
    local secondaryBounds = TextMetrics:Get(Localization:Get("getKey"), 13, Theme.Medium, 10000)
    local secondaryWidth = math.max(hit * 2, math.ceil(secondaryBounds and secondaryBounds.X or left) + 28)
    local paired = left >= 360 and primaryText + 52 + secondaryWidth + 12 <= left
    local verifyWidth = paired and left - secondaryWidth - 12 or left
    place(UI.Validate.Root, 0, buttonY, verifyWidth, hit)
    UI.Validate.Label.TextSize = 14
    UI.Validate.Label.TextXAlignment = Enum.TextXAlignment.Left
    UI.Validate.Label.Position, UI.Validate.Label.Size = UDim2.fromOffset(16, 0), UDim2.new(1, -52, 1, 0)
    UI.Validate.Icon.Root.AnchorPoint = Vector2.new(0, 0.5)
    place(UI.Validate.Icon.Root, verifyWidth - 32, hit / 2, 18, 18)
    local getKeyY = paired and buttonY or buttonY + hit + 2
    place(UI.GetKey.Root, paired and verifyWidth + 12 or 0, getKeyY, paired and secondaryWidth or left, hit)
    UI.GetKey.TextColor = Theme.AccentText
    UI.GetKey:Apply()
    UI.GetKey.Label.TextSize, UI.GetKey.Label.TextWrapped = 13, true
    UI.GetKey.Icon.Root.Visible = false
    UI.GetKey.Label.Position, UI.GetKey.Label.Size = UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1)
    Community:Measure(left)
    Diagnostics:Measure(left)
    Experience:Measure(left)
    local formHeight = getKeyY + hit
    Stagecraft:Place(UI.AuthForm, 0, formY, left, formHeight)
    local extrasY = formY + formHeight + 4
    Experience:Layout(left, extrasY)
    local bodyHeight = math.max(height, extrasY + Experience:Height() + 8, aside and 336 or 0)
    UI.AuthBody.Size, UI.AuthScroll.CanvasSize = UDim2.fromOffset(width, bodyHeight), UDim2.fromOffset(0, bodyHeight)
    UI.AccessAside.Visible = aside
    UI.AuthArtwork.Root.Visible = aside
    Stagecraft:Place(UI.AccessAside, left + 28, 0, asideWidth, aside and 328 or 0)
    if aside then
        place(UI.AsideDivider, 0, 248, asideWidth, 1)
        place(UI.AuthArtwork.Root, 0, 0, asideWidth, 232)
        UI.AuthArtwork:Layout(asideWidth, 232)
        -- The miniature mark is art, not unreadable microcopy at a fractional scale.
        UI.AuthArtwork.Caption.Visible, UI.AuthArtwork.Serial.Visible, UI.AuthArtwork.Signature.Visible =
            false, false, false
    end
    AuthField:SyncMask()
    UI.AuthScroll.ScrollingEnabled = bodyHeight > height + 1
    if State.Focused and height < 250 then
        local lead = math.min(24, math.max(0, height - controlHeight - 8))
        UI.AuthScroll.CanvasPosition = Vector2.new(0, math.max(0, inputY - lead))
    elseif not UI.AuthScroll.ScrollingEnabled then
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
    local floor = height < size.Y and State.Focused and 80 or 160
    return Vector2.new(math.max(160, size.X), math.max(floor, height))
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
    local oldLayout = State.Layout
    local safe = safeSize()
    local narrow = (safe.X < 620 and safe.X / safe.Y < 1.35) or (safe.X < 850 and safe.X / safe.Y < 1.22)
    local width = narrow and math.min(560, safe.X - 20) or math.min(912, safe.X - 20)
    local height = narrow and math.min(720, safe.Y - 20) or math.min(543, safe.Y - 20)
    local scale = math.min(Settings.UIScale, (safe.X - 20) / width, (safe.Y - 20) / height)
    local hit = math.max(44, math.ceil(44 / math.max(0.1, scale)))
    local keyboardCompact = State.Focused and safe.Y < 220
    local expanded = width >= 820 and not narrow and not keyboardCompact
    local rail = keyboardCompact and 0 or expanded and 196 or math.max(56, hit + 8)
    local header = math.max(height < 400 and 54 or 64, hit + 8)
    if keyboardCompact then
        header = height >= math.max(hit, 48) * 2 + 12 and hit or 0
    end
    local pad = keyboardCompact and 4 or width < 480 and 12 or 24
    local footer = keyboardCompact and 4 or 12
    local pageTop = header + pad
    local contentWidth = math.max(100, width - rail - pad * 2)
    local contentHeight = math.max(52, height - pageTop - footer)
    State.Layout = {
        Width = width,
        Height = height,
        Scale = scale,
        Rail = rail,
        Narrow = narrow,
        Safe = safe,
        Hit = hit,
        Header = header,
        ContentX = rail + pad,
        KeyboardCompact = keyboardCompact,
    }
    UI.Window.Size = UDim2.fromOffset(width, height)
    State.VisibilityRestScale = scale
    Animation:CancelProperty(UI.Scale, "Scale")
    UI.Scale.Scale = scale * (State.Visible and 1 or 0.965)
    local center = self:Clamp(State.WindowCenter or safe / 2, safe, Vector2.new(width * scale, height * scale))
    State.WindowCenter, State.Drag = center, nil
    Animation:CancelProperty(UI.Window, "Position")
    UI.Window.Position = UDim2.fromOffset(center.X, center.Y)
    UI.Sidebar.Visible, UI.Header.Visible = not keyboardCompact, header > 0
    place(UI.ContentSurface, rail, 0, width - rail, height)
    place(UI.Sidebar, 0, 0, rail, height)
    place(UI.SidebarDivider, rail - 1, 0, 1, height)
    UI.RailSurface.Visible = false
    place(UI.Header, rail, 0, width - rail, header)
    place(UI.HeaderDivider, 0, header - 1, width - rail, 1)
    place(UI.BrandLogo.Root, expanded and 20 or (rail - 24) / 2, 20, 24, 24)
    UI.Brand.Visible = expanded
    UI.Brand.TextSize, UI.Brand.Font = 18, Theme.Bold
    place(UI.Brand, 54, 12, rail - 66, 40)
    local navY = header + (height < 400 and 4 or 32)
    local optionY = height - hit * 2 - 16
    local socialWanted = height >= 450
        and (
            State.Callbacks.Social ~= nil
            or Settings.SocialLinks.discord ~= nil
            or Settings.SocialLinks.telegram ~= nil
            or Settings.SocialLinks.youtube ~= nil
        )
    local utilityTop = socialWanted and optionY - hit - 8 or optionY - 10
    local detailedHeight = math.max(hit, 64)
    local detailedNavigation = expanded
        and height >= 500
        and navY + (detailedHeight + 4) * 3 + detailedHeight + 12 <= utilityTop
    local navHeight = detailedNavigation and detailedHeight or hit
    local navStep = navHeight + 4
    UI.NavigationCaption.Visible = expanded and height >= 420
    place(UI.NavigationCaption, 22, header + 8, rail - 40, 16)
    local labelInset = 44
    for index, button in ipairs({ UI.AuthNav, UI.ProductsNav, UI.LicenseNav, UI.RefreshNav }) do
        place(
            button.Root,
            expanded and 8 or (rail - hit) / 2,
            navY + (index - 1) * navStep,
            expanded and rail - 16 or hit,
            navHeight
        )
        button.Icon.Root.Position = UDim2.new(expanded and 0 or 0.5, expanded and 14 or -9, 0.5, 0)
        button.Icon.Root.Size = UDim2.fromOffset(18, 18)
        button.Label.Visible = expanded
        button.Label.Position, button.Label.Size =
            UDim2.fromOffset(labelInset, detailedNavigation and 5 or 0),
            UDim2.new(1, -labelInset - 18, detailedNavigation and 0 or 1, detailedNavigation and 26 or 0)
        button.Label.TextXAlignment, button.Label.TextWrapped = Enum.TextXAlignment.Left, true
        button.NavHint.Visible = detailedNavigation
        place(button.NavHint, labelInset, 34, rail - labelInset - 34, 28)
    end
    UI.RefreshNav.Root.Visible = height >= 420 and optionY >= UI.RefreshNav.Root.Position.Y.Offset + navHeight + 14
    UI.ProductsNav.Root.Visible = height >= navY + navStep + hit
    UI.LicenseNav.Root.Visible = LicenseOffer:Enabled() and height >= navY + navStep * 2 + hit + 8
    local navigationBottom = 0
    for _, button in ipairs({ UI.AuthNav, UI.ProductsNav, UI.LicenseNav, UI.RefreshNav }) do
        if button.Root.Visible then
            navigationBottom = math.max(navigationBottom, button.Root.Position.Y.Offset + navHeight)
        end
    end
    local headerWidth = width - rail
    local controls = hit * 2 + 12
    local avatarVisible = headerWidth >= 460
    local avatarSpace = avatarVisible and 128 or 0
    local titleWidth = math.max(40, headerWidth - controls - avatarSpace - pad * 2)
    Stagecraft:Place(UI.PageHeading, 0, 0, headerWidth, header)
    UI.PageDescription.Visible = headerWidth >= 280 and height >= 250
    place(UI.Breadcrumb, pad, UI.PageDescription.Visible and 10 or (header - 24) / 2, titleWidth, 24)
    place(UI.PageDescription, pad, 35, titleWidth, 20)
    UI.Breadcrumb.TextTruncate = Enum.TextTruncate.AtEnd
    place(UI.Minimize.Root, headerWidth - controls, (header - hit) / 2, hit, hit)
    place(UI.CloseWindow.Root, headerWidth - hit - 6, (header - hit) / 2, hit, hit)
    UI.CloseWindow.Root:SetAttribute("ActionLabel", Localization:Get("closeLoader"))
    UI.User.Visible, UI.Avatar.Root.Visible = avatarVisible, avatarVisible
    UI.UserAction.Visible = avatarVisible and type(State.Callbacks.User) == "function"
    place(UI.User, headerWidth - controls - 128, 0, 82, header)
    place(UI.Avatar.Root, headerWidth - controls - 38, (header - 28) / 2, 28, 28)
    place(UI.UserAction, headerWidth - controls - 128, 0, 122, header)
    if UI.CustomAvatar then
        UI.CustomAvatar.Visible = avatarVisible
        UI.CustomAvatar.Position, UI.CustomAvatar.Size = UI.Avatar.Root.Position, UI.Avatar.Root.Size
    end
    local restoreSize = math.max(48, hit)
    local restoreY = math.clamp(center.Y - restoreSize / 2, 8, math.max(8, safe.Y - restoreSize - 8))
    place(UI.RestoreDock, math.max(8, safe.X - restoreSize - 12), restoreY, restoreSize, restoreSize)
    UI.Minimize.Root:SetAttribute("ActionLabel", Localization:Get("minimize"))
    UI.Restore.Root:SetAttribute("ActionLabel", Localization:Get("restore"))
    local footerFits = optionY >= navigationBottom + 14
    UI.Options.Root.Visible = footerFits
    UI.UtilityDivider.Visible = expanded and footerFits
    place(UI.UtilityDivider, 20, optionY - 10, math.max(1, rail - 40), 1)
    UI.Options.Label.Visible = expanded
    place(UI.Options.Root, expanded and 8 or (rail - hit) / 2, optionY, expanded and rail - 16 or hit, hit)
    UI.Options.Icon.Root.Position = UDim2.new(expanded and 0 or 0.5, expanded and 14 or -9, 0.5, 0)
    UI.Options.Label.Position, UI.Options.Label.Size = UDim2.fromOffset(44, 0), UDim2.new(1, -52, 1, 0)
    UI.Options.Label.TextXAlignment = Enum.TextXAlignment.Left
    place(UI.LanguageToggle, expanded and 8 or (rail - hit) / 2, height - hit - 8, expanded and rail - 16 or hit, hit)
    UI.LanguageToggle.Visible = height >= header + hit + 16
    UI.LanguageChevron.Root.Visible = expanded
    UI.LanguageName.Visible = expanded
    place(UI.LanguageName, 48, 0, math.max(1, rail - 96), hit)
    place(UI.LanguageFlag, expanded and 12 or (hit - 26) / 2, (hit - 26) / 2, 26, 26)
    place(UI.LanguageChevron.Root, expanded and rail - 48 or 16, (hit - 12) / 2, 12, 12)
    for index, id in ipairs({ "discord", "telegram", "youtube" }) do
        local button = UI.Social[id]
        local show = (State.Callbacks.Social ~= nil or Settings.SocialLinks[id] ~= nil)
            and height >= 450
            and optionY - hit - 8 >= navigationBottom + 8
        button.Root.Visible = show
        local x = expanded and 8 + (index - 1) * (hit + 4) or (rail - hit) / 2
        place(button.Root, x, optionY - hit - 8, hit, hit)
        if not expanded and index > 1 then
            button.Root.Visible = false
        end
    end
    UI.Version.Visible = expanded and Settings.Version ~= "" and height >= 500
    place(UI.Version, 54, header - 20, rail - 66, 16)
    UI.Version.TextXAlignment = Enum.TextXAlignment.Left
    LanguageController:Layout(width, height, rail)
    place(UI.Pages, rail + pad, pageTop, contentWidth, contentHeight)
    UI.Key.TextEditable = State.Visible
        and State.Page == "Auth"
        and State.Activity == "Idle"
        and not Experience.OptionsOpen
        and not State.Modal
    UI.Key.Active = UI.Key.TextEditable
    local dockHeight = Community:DockHeight(contentWidth, height)
    local authHeight = math.max(52, contentHeight - dockHeight)
    UI.AuthScroll.Size = UDim2.new(1, 0, 1, -dockHeight)
    self:Auth(contentWidth, authHeight, narrow)
    Community:LayoutDock(rail + pad, pageTop + contentHeight - dockHeight, contentWidth, height)
    Navigation:Refresh(oldLayout.Rail ~= rail or oldLayout.Hit ~= hit or oldLayout.Header ~= header)
    Cards:Layout()
    LicenseOffer:Layout(true)
    Modal:Layout(true)
    Toasts:Layout()
    Accessibility:Layout()
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
        for _, button in ipairs({ UI.UserAction, UI.Minimize.Root, UI.CloseWindow.Root, UI.LanguageToggle }) do
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
        Button:Release(input)
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
        Button:Release(nil, true)
        LanguageController.Pressed, LanguageController.Hovered = false, false
        LanguageController:Paint()
        Cards:ResetHover()
        State.Drag = nil
    end)
    Runtime:Connect(Services.Input.InputBegan, function(input, processed)
        local focused = Services.Input:GetFocusedTextBox()
        local ownedTextbox = focused == UI.Key or focused == UI.ResultCopy
        local ownedSelection = Accessibility.Keyboard and Accessibility:Available(Accessibility.Focused)
        if input.KeyCode == Enum.KeyCode.Tab and (not processed or ownedTextbox or ownedSelection) then
            if focused and not ownedTextbox then
                return
            end
            local reverse = false
            pcall(function()
                reverse = Services.Input:IsKeyDown(Enum.KeyCode.LeftShift)
                    or Services.Input:IsKeyDown(Enum.KeyCode.RightShift)
            end)
            Accessibility:Tab(reverse)
            return
        end
        if processed or (focused and not ownedTextbox) then
            return
        end
        if not focused and AccessScene:ScrollKey(input.KeyCode) then
            return
        end
        if (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter) and not focused then
            if Accessibility:Activate() then
                return
            end
        end
        if input.KeyCode == Enum.KeyCode.Escape then
            if LanguageController.Open then
                closeLanguage()
            elseif Experience.OptionsOpen and State.Activity == "Idle" then
                Loader:ShowPreferences(false)
            elseif State.Modal == "result" and State.Activity == "Idle" then
                Modal:Close()
            elseif State.Page == "Licenses" and State.Activity == "Idle" then
                Navigation:Go("Auth")
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
        UI.RestoreDockScale.Scale = Settings.ReducedMotion and 1 or 0.84
        Animation:To(UI.RestoreDockScale, { Scale = 1 }, Motion.Enter)
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
    if AccessScene.Mode then
        AccessScene:Refresh()
    end
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
    -- Keep the public setter callable for older hosts; its URL is deliberately ignored.
    if State.Alive then
        Settings.KeyLink = KEY_REWARD_URL
    end
    return self
end
function Loader:SetExpiry(seconds)
    if State.Alive then
        Settings.Expiry = seconds == math.huge and math.huge or math.max(0, finite(seconds, 0))
    end
    return self
end
function Loader:GetExpiry()
    return Settings.Expiry
end
-- Validation only: return true/false and a message; do not run long-lived Script() here.
-- This optional host hook resolves a link only on an explicit Get Key action.
function Loader:SetOnGetKey(callback)
    assert(callback == nil or type(callback) == "function", "SetOnGetKey expects a function or nil")
    if State.Alive then
        State.Callbacks.GetKey = callback
    end
    return self
end
-- Native PUBLIC prompt lifecycle for the documented first-statement flow_init.
-- Returns only user input; the protected host confirms real signed auth later.
-- Never contains gameplay or grants an entitlement from an input string.
function Loader:AwaitFlowKey(currentKey, options)
    if not State.Alive then
        error("[PLAK] Key prompt is already closed", 0)
    end
    options = type(options) == "table" and options or {}
    local GET_KEY_URL = KEY_REWARD_URL
    local SAVE_FOLDER = "PLAK"
    local SAVE_FILE = SAVE_FOLDER .. "/saved_key.txt"
    local SLOT = "__PlakFlowInitBridgeV1"
    local OWNER = "PLAK/flow_init/v1"

    local function environment()
        if type(getgenv) == "function" then
            local ok, value = pcall(getgenv)
            if ok and type(value) == "table" then
                return value
            end
        end
        return type(_G) == "table" and _G or nil
    end
    local env = environment()
    if not env then
        self:Destroy()
        error("[PLAK] Shared executor environment is unavailable", 0)
    end
    local function primitive(name, direct)
        local value = env[name]
        if type(value) == "function" then
            return value
        end
        if type(direct) == "function" then
            return direct
        end
        value = type(_G) == "table" and _G[name] or nil
        return type(value) == "function" and value or nil
    end
    local function trim(value)
        return type(value) == "string" and value:gsub("^%s+", ""):gsub("%s+$", "") or ""
    end
    local function getFlow()
        local value = env.FlowAuth
        if type(value) ~= "table" and type(_G) == "table" then
            value = _G.FlowAuth
        end
        return type(value) == "table" and value or nil
    end
    local old = env[SLOT]
    if type(old) == "table" and old.Owner == OWNER then
        if old.ScriptStarted then
            if old.Loader ~= self then
                self:Destroy()
            end
            error("[PLAK] Script() already started in this session; restart the executor to run it again", 0)
        end
        if not old.Finished then
            if old.Loader ~= self then
                self:Destroy()
            end
            error(
                "[PLAK] A FlowAuth run is still unconfirmed. Close its UI and restart the executor before retrying",
                0
            )
        end
        if old.Loader then
            pcall(old.Loader.Destroy, old.Loader)
        end
    end
    -- A single-flight UI transport, NOT authentication proof or a cached license.
    local bridge = { Owner = OWNER, Stage = "initializing", Finished = false, Flow = getFlow() }
    env[SLOT] = bridge
    env.premuser = false
    local submit = Instance.new("BindableEvent")
    submit.Name = "PlakFlowInitSubmission"
    local chosenKey
    local files = {
        Read = primitive("readfile", readfile),
        Exists = primitive("isfile", isfile),
        Write = primitive("writefile", writefile),
        Delete = primitive("delfile", delfile),
        MakeFolder = primitive("makefolder", makefolder),
        IsFolder = primitive("isfolder", isfolder),
    }
    local function clearCredential()
        chosenKey = nil
    end
    local function stopOriginalRun()
        local flow = bridge.Flow
        if flow and type(flow.Stop) == "function" then
            local ok = pcall(flow.Stop, flow)
            if ok then
                bridge.Finished = true
            end
            return ok
        end
        return false
    end
    local function abort(message)
        bridge.Cancelled = true
        bridge.Finished = not bridge.Submitted
        bridge.Stage = "cancelled"
        clearCredential()
        if not bridge.Submitted then
            if submit then
                submit:Fire()
            end
        else
            stopOriginalRun()
        end
        if bridge.Loader then
            pcall(bridge.Loader.Destroy, bridge.Loader)
        end
        if submit then
            submit:Destroy()
            submit = nil
        end
        error(message, 0) -- flow_init errors CANCEL the run; never return nil as a fallback key.
    end
    local function readSavedKey()
        if not Settings.RememberMe or not files.Read or not files.Exists then
            return nil
        end
        local ok, exists = pcall(files.Exists, SAVE_FILE)
        if not ok or not exists then
            return nil
        end
        local readOk, value = pcall(files.Read, SAVE_FILE)
        local key = readOk and trim(value) or ""
        return #key > 0 and #key <= 512 and key or nil
    end
    local function deleteSavedKey()
        if files.Exists then
            local ok, exists = pcall(files.Exists, SAVE_FILE)
            if ok and not exists then
                return true
            end
        end
        if files.Delete then
            local ok, result = pcall(files.Delete, SAVE_FILE)
            if ok and result ~= false then
                return true
            end
        end
        -- Some executors can read/write files but cannot delete them.
        if files.Write then
            local ok, result = pcall(files.Write, SAVE_FILE, "")
            return ok and result ~= false
        end
        return false
    end
    -- Called ONLY by the protected, post-auth body. Do not cache merely submitted keys.
    bridge.SaveAcceptedKey = function()
        local key = chosenKey
        clearCredential()
        if not Settings.RememberMe or not files.Write or type(key) ~= "string" or key == "" then
            return false
        end
        if files.MakeFolder then
            local existsOk, exists = false, false
            if files.IsFolder then
                existsOk, exists = pcall(files.IsFolder, SAVE_FOLDER)
            end
            if not existsOk or not exists then
                pcall(files.MakeFolder, SAVE_FOLDER)
            end
        end
        local ok, result = pcall(files.Write, SAVE_FILE, key)
        return ok and result ~= false
    end
    bridge.ClearCredential = clearCredential
    local cachedLink = ""
    local function getKeyLink()
        cachedLink = GET_KEY_URL
        return cachedLink
    end
    local loader = self
    bridge.Loader = loader
    for _, name in ipairs({
        "SetTitle",
        "SetVersion",
        "SetSuccessBehavior",
        "SetOnKeySubmit",
        "ConfirmExternalAuth",
        "CancelExternalAuth",
        "SetOnAuthorized",
        "SetOnDestroyed",
        "SetOnForgetKey",
        "SetOnGetKey",
        "SetKeyLink",
        "AutoValidate",
        "GetState",
        "Destroy",
    }) do
        if type(loader[name]) ~= "function" then
            abort("[PLAK] Remote UI is outdated: missing " .. name .. "; publish updated UIs/PlakUi.lua")
        end
    end
    if loader.FlowInitVersion ~= 1 then
        abort("[PLAK] Publish the flow_init-compatible PlakUi.lua at SOURCE_URL")
    end
    loader:SetTitle("Plak")
    loader:SetVersion("1.1.0")
    loader:SetSuccessBehavior("destroy")
    loader:SetOnGetKey(getKeyLink)
    if cachedLink ~= "" then
        loader:SetKeyLink(cachedLink)
    end
    loader:SetOnForgetKey((files.Delete or files.Write) and deleteSavedKey or nil)
    if not Settings.RememberMe then
        deleteSavedKey()
    end
    loader:SetOnDestroyed(function()
        if bridge.Accepted then
            return
        end -- Successful UI teardown must NOT stop the protected game.
        bridge.Cancelled = true
        bridge.Stage = "cancelled"
        clearCredential()
        if bridge.Submitted then
            stopOriginalRun()
        else
            bridge.Finished = true
            if submit then
                submit:Fire()
            end
        end
    end)
    loader:SetOnKeySubmit(function(key)
        if bridge.Submitted or bridge.Cancelled then
            return false
        end
        key = trim(key)
        if key == "" or #key > 512 then
            return false
        end
        chosenKey = key
        bridge.Flow = bridge.Flow or getFlow()
        bridge.Submitted = true
        bridge.Stage = "awaiting-flowauth"
        submit:Fire() -- Submission ONLY: no success message, premium flag or gameplay.
        return true
    end)
    bridge.Stage = "prompt"
    print("[PLAK] Key UI ready v1.5; waiting for FlowAuth confirmation.")
    local initialKey = trim(currentKey)
    if #initialKey > 512 then
        abort("[PLAK] script_key exceeds FlowAuth's 512-byte limit")
    end
    if initialKey == "" then
        initialKey = readSavedKey() or ""
    end
    if initialKey ~= "" then
        loader:AutoValidate(initialKey)
    end
    -- Check the latch before waiting: already-set script_key / fast submission cannot be lost.
    if not bridge.Submitted and not bridge.Cancelled then
        submit.Event:Wait()
    end
    submit:Destroy()
    submit = nil
    if bridge.Cancelled or type(chosenKey) ~= "string" or chosenKey == "" then
        abort("[PLAK] Key prompt cancelled")
    end
    return chosenKey -- FlowAuth checks it NEXT. An input string is never authentication proof.
end

-- One-shot pre-auth submission. The protected host must call ConfirmExternalAuth later.
function Loader:SetOnKeySubmit(callback)
    assert(callback == nil or type(callback) == "function", "SetOnKeySubmit expects a function or nil")
    if State.Alive then
        if ExternalAuth.Pending or ExternalAuth.Consumed then
            return self, false
        end
        ExternalAuth.Mode = callback ~= nil
        State.Callbacks.KeySubmit = callback
        State.Callbacks.Validate = callback and function(key)
            return ExternalAuth:Wait(key)
        end or nil
    end
    return self, true
end
function Loader:ConfirmExternalAuth(info, message)
    if not ExternalAuth.Mode then
        return false, "not_external_auth"
    end
    return ExternalAuth:Settle(true, message, info)
end
-- Presentation-only entry for a protected body that already passed its signed tier
-- check but has no pre-auth UI transport. No synthetic key or validator is involved.
function Loader:CompleteVerifiedAuth(info, message)
    if not State.Alive then
        return false, "destroyed"
    end
    if State.Authorized or State.Activity ~= "Idle" or ExternalAuth.Pending or ExternalAuth.Consumed then
        return false, "busy_or_completed"
    end
    if type(info) ~= "table" or (info.tier ~= "free" and info.tier ~= "premium") then
        return false, "missing_auth_metadata"
    end
    self:SetAuthInfo(info)
    self:SetExpiry(info.secondsLeft)
    State.ValidationToken = State.ValidationToken + 1
    State.AuthError = false
    if State.Modal then
        Modal:Close(true)
    end
    self:Show()
    completeAuthorized(State.ValidationToken, nil, message)
    return true
end
function Loader:CancelExternalAuth(message)
    return ExternalAuth:Cancel(type(message) == "string" and safeText(message, 240) or nil)
end
function Loader:SetOnDestroyed(callback)
    assert(callback == nil or type(callback) == "function", "SetOnDestroyed expects a function or nil")
    if State.Alive then
        State.Callbacks.Destroyed = callback
    end
    return self
end
function Loader:SetOnValidate(callback)
    assert(callback == nil or type(callback) == "function", "SetOnValidate expects a function or nil")
    if State.Alive then
        if ExternalAuth.Pending then
            return self, false
        end
        ExternalAuth.Mode = false
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
        if not LicenseOffer:Enabled() and State.Page == "Licenses" then
            Navigation:Go("Auth", true)
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
    if not LicenseOffer:Enabled() and State.Page == "Licenses" then
        Navigation:Go("Auth", true)
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
    if State.Page == "Licenses" then
        LicenseOffer:Layout(true)
    end
    Accessibility:HideTooltip()
    Accessibility:Layout()
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
    Settings.User = safeText(user or "Hi!", 96)
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
            Stagecraft:Cancel(true)
            AccessScene:Cancel(true)
            Accessibility:HideTooltip()
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
            if State.Page == "Licenses" then
                LicenseOffer:Layout(true)
            end
        end
        if State.Activity == "Validating" then
            authBusy(true)
        end
        Accessibility:Layout()
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
            and UI.User.Visible
            and (UI.Avatar.Root.Visible or UI.CustomAvatar ~= nil)
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
            secondsLeft = info.secondsLeft == math.huge and math.huge or seconds and seconds >= 0 and seconds or nil,
            lifetime = info.secondsLeft == math.huge,
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
    if not canInteract() then
        return self, false
    end
    local wasOpen = Experience.OptionsOpen
    Experience.OptionsOpen = visible ~= false
    if Experience.OptionsOpen then
        Stagecraft:Cancel(true)
    end
    closeLanguage()
    UI.Key:ReleaseFocus(false)
    UI.Key.TextEditable = not Experience.OptionsOpen and State.Page == "Auth"
    UI.Key.Active = UI.Key.TextEditable
    Experience:RefreshOptions()
    Responsive:Update()
    if Experience.OptionsOpen and not wasOpen then
        if Accessibility.Keyboard then
            Accessibility:Focus(UI.PreferenceClose.Root)
        end
    elseif not Experience.OptionsOpen and Accessibility.Keyboard then
        Accessibility:Focus(UI.Options.Root)
    end
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

-- Whitelisted scalars only: no key, host result, account identity or callback error.
function Loader:GetDiagnostics()
    return Diagnostics:Snapshot()
end
function Loader:CopyDiagnostics()
    return Diagnostics:Copy()
end
function Loader:ShowDiagnostics(visible)
    if State.Alive and State.Visible and State.Activity == "Idle" then
        if visible ~= false then
            Experience.OptionsOpen = true
        end
        Experience:RefreshOptions()
        return Diagnostics:Toggle(visible ~= false)
    end
    return false, "unavailable"
end
function Loader:GetState()
    return {
        Name = State.Name,
        Page = State.Page,
        Activity = State.Activity,
        Visible = State.Visible,
        KeyVisible = Settings.KeyVisible,
        RememberMe = Settings.RememberMe,
        AuthError = State.AuthError == true,
        Authorized = State.Authorized,
        Language = Settings.Language,
        UIScale = Settings.UIScale,
        ReducedMotion = Settings.ReducedMotion,
        CommunityEnabled = Community:Enabled(),
        CommunityDockVisible = UI.CommunityDock and UI.CommunityDock.Visible or false,
        CommunityDismissed = Settings.CommunityDismissed,
        ExternalAuthPending = ExternalAuth.Pending ~= nil and not ExternalAuth.Pending.Done,
        ExternalAuthSubmitted = ExternalAuth.Mode and ExternalAuth.Consumed,
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
    local wasVisible = State.Visible
    State.VisibilityToken = State.VisibilityToken + 1
    State.Visible = true
    reconcile()
    restoreAffordance(false)
    UI.Window.Visible = true
    UI.Key.TextEditable = State.Activity ~= "Validating" and State.Page == "Auth"
    UI.Key.Active = UI.Key.TextEditable
    Responsive:Update()
    UI.Overlay.Visible = State.Modal ~= nil
    local destination = UI.Window.Position
    if not wasVisible and not Settings.ReducedMotion then
        UI.Window.Position = destination + UDim2.fromOffset(0, 8)
        UI.Scale.Scale = (State.VisibilityRestScale or 1) * 0.98
    end
    Animation:To(UI.Scale, { Scale = State.VisibilityRestScale or 1 }, Motion.Enter)
    Animation:To(UI.Window, { Position = destination }, Motion.Enter)
    Animation:To(UI.Window, { GroupTransparency = 0 }, Motion.Enter)
    if State.Page == "Auth" then
        UI.AuthArtwork:Reveal()
        Stagecraft:Reveal()
    elseif State.Page == "Products" then
        Cards:Reveal()
    else
        LicenseOffer:Reveal()
    end
    return self
end
function Loader:Hide()
    if not State.Alive then
        return self
    end
    Button:Release(nil, true)
    Stagecraft:Cancel(true)
    AccessScene:Cancel(true)
    State.VisibilityToken = State.VisibilityToken + 1
    local token = State.VisibilityToken
    State.Visible = false
    Accessibility:Clear()
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
    -- Authentication exits never expose an interactive restore chip.
    restoreAffordance(State.Activity ~= "Completing")
    UI.Overlay.Visible = false
    local rest = UI.Window.Position
    local offset = State.Activity == "Completing" and Vector2.new(0, -6) or Vector2.new(12, 18)
    if State.Activity ~= "Completing" then
        local dock = UI.RestoreDock.Position
        offset = Vector2.new((dock.X.Offset - rest.X.Offset) * 0.045, (dock.Y.Offset - rest.Y.Offset) * 0.045)
    end
    Animation:To(
        UI.Scale,
        { Scale = (State.VisibilityRestScale or 1) * (State.Activity == "Completing" and 0.985 or 0.965) },
        Motion.Exit
    )
    -- Keep fade/finalizer separate: resize owns Position and may cancel its tween.
    Animation:To(UI.Window, { Position = rest + UDim2.fromOffset(offset.X, offset.Y) }, Motion.Exit)
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
    local destroyed = State.Callbacks.Destroyed
    -- Wake an unscoped external waiter before disposing its signal/lifecycle.
    if ExternalAuth.Pending then
        ExternalAuth:Cancel()
    end
    Accessibility:Clear()
    Diagnostics.ValidationStarted = nil
    Runtime:Cancel(Experience.PrefTimer)
    Experience.PrefTimer = nil
    Experience:SavePrefs()
    State.AuthInfo = nil
    State.SlowAuthTimer = nil
    Button.Capture = nil
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
    table.clear(Modal.SurfaceGeometry)
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
    if type(destroyed) == "function" then
        local ok = pcall(destroyed, self)
        if not ok then
            warn("[PLAK] Destroy callback failed")
        end
    end
    Settings.Artwork = nil
    Settings.KeyLink = KEY_REWARD_URL
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
    Diagnostics.BuiltAt = os.clock()
    UI.Gui.Parent = parent
    Accessibility:Build()
    bindInput()
    local dispose = create("BindableEvent", { Name = "PlakDispose" }, UI.Gui)
    Runtime:Connect(dispose.Event, function()
        Loader:Destroy()
    end)
    Runtime:Connect(UI.Gui.Destroying, function()
        Loader:Destroy()
    end)
    Responsive:Update()
    Loader:SetProducts(loadSupportedGames())
    Diagnostics.ReadyAt = os.clock()
    reconcile()
    State.Presented = true
    if State.Visible then
        Animation:To(UI.Window, { GroupTransparency = 0 }, Motion.Enter)
        UI.AuthArtwork:Reveal()
        Stagecraft:Reveal()
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
