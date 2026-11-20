-- JetZKey • Plak's native license frontend. The host owns validation, verified
-- entitlements and protected application startup. This file never checks a key on
-- its own and never writes premuser.
local Services = {
    Players = game:GetService("Players"),
    Input = game:GetService("UserInputService"),
    Tween = game:GetService("TweenService"),
    Http = game:GetService("HttpService"),
    Media = game:GetService("ContentProvider"),
}
local U, View, Auth, Prefs, Catalog, FX = {}, {}, {}, {}, {}, {}
local Loader = {
    AuthHandoffVersion = 2,
    FlowInitVersion = 1,
    FlowInitPromptVersion = 1,
    VerifiedPresentationVersion = 1,
    __PlakOwned = true,
}
local State = {
    alive = true,
    visible = true,
    route = "Key",
    sub = "Key",
    activity = "Idle",
    stage = "authReady",
    authorized = false,
    token = 0,
    provider = "Not checked",
    callbacks = {},
    expiry = 0,
    progress = 0,
}
local UI = { routes = {}, sides = {}, subs = {}, busy = {}, checks = {} }
local Settings = {
    version = "1.0",
    remember = true,
    reduced = false,
    scale = 1,
    language = "en",
    behavior = "destroy",
    toggle = Enum.KeyCode.RightShift,
    keyVisible = false,
    community = true,
    communityDismissed = false,
    offer = true,
}
local TITLE = "Plak"
local REWARD = "https://flowauth.net/v1/projects/3405/rewards/public/complete/407?reward=reward-mv4jrbf3"
local DISCORD = "https://dsc.gg/plak"
local REGISTRY = "https://raw.githubusercontent.com/Nanana291/Plak/refs/heads/main/Games.json"
local PREFS_FILE = "PLAK/ui_preferences.json"
local OWNER = "__PlakUiLoader"

local V, O, S, C = Vector2.new, UDim2.fromOffset, UDim2.fromScale, Color3.fromRGB
local Theme = {
    bg = C(13, 13, 15),
    sidebar = C(14, 13, 18),
    selected = C(19, 18, 24),
    surface = C(17, 16, 21),
    field = C(21, 20, 25),
    raised = C(24, 22, 29),
    hover = C(29, 26, 33),
    pressed = C(36, 29, 37),
    border = C(42, 38, 47),
    divider = C(24, 23, 27),
    ink = C(248, 247, 246),
    secondary = C(175, 170, 181),
    muted = C(133, 130, 143),
    nav = C(133, 128, 145),
    disabled = C(107, 101, 116),
    coral = C(240, 110, 117),
    accent = C(202, 112, 113),
    darkCoral = C(42, 26, 28),
    green = C(120, 226, 162),
    deepGreen = C(20, 36, 29),
    error = C(248, 122, 132),
    amber = C(222, 178, 108),
    black = C(11, 10, 13),
}
local Regular = Font.fromEnum(Enum.Font.RobotoMono)
local FontFace = {
    normal = Regular,
    medium = Font.new(Regular.Family, Enum.FontWeight.Medium),
    bold = Font.new(Regular.Family, Enum.FontWeight.Bold),
}
-- JetZ metrics: default desktop width, sidebar, drawer, safe margins and touch
-- hit target. Height and per-page insets use the measured Plak compositions.
local D = { width = 838, height = 486, sidebar = 198, landscapeSide = 140, drawer = 198, touchHit = 44 }

function U.trim(value)
    return type(value) == "string" and value:gsub("^%s+", ""):gsub("%s+$", "") or ""
end

function U.number(value, default)
    local n = tonumber(value)
    return n and n == n and math.abs(n) < math.huge and n or default
end

function U.text(value, limit, default)
    if type(value) ~= "string" and type(value) ~= "number" then
        return default or ""
    end
    local str = tostring(value):gsub("[%z\1-\8\11\12\14-\31]", "")
    if not utf8.len(str) then
        str = str:gsub("[\128-\255]", "?")
    end
    if #str > limit then
        str = str:sub(1, (utf8.offset(str, 0, limit + 1) or limit + 1) - 1)
    end
    return str
end

function U.redact(message, key, default)
    if type(message) ~= "string" or U.trim(message) == "" then
        return default
    end
    if type(key) == "string" and key ~= "" and message:find(key, 1, true) then
        return default
    end
    return U.text(message, 240, default)
end

function U.environment()
    if type(getgenv) == "function" then
        local ok, result = pcall(getgenv)
        if ok and type(result) == "table" then
            return result
        end
    end
    return _G
end

local Env = U.environment()
local RunEnv = type(getfenv) == "function" and getfenv(0) or {}
function U.cap(...)
    for i = 1, select("#", ...) do
        local name = select(i, ...)
        local fn = Env[name]
        if type(fn) ~= "function" then
            fn = RunEnv[name]
        end
        if type(fn) ~= "function" then
            fn = _G[name]
        end
        if type(fn) == "function" then
            return fn
        end
    end
    return nil
end

function U.url(value)
    local url = U.trim(value)
    return #url <= 2048 and not url:find("[%s%z]") and url:match("^https://[^/?#]+") and url or nil
end

function U.call(callback, ...)
    if callback then
        local ok, first, second = pcall(callback, ...)
        return ok, first, second
    end
    return false
end

function U.now()
    local ok, result = pcall(function()
        return workspace:GetServerTimeNow()
    end)
    return ok and U.number(result, nil) or os.time()
end

local Scope = {}
Scope.__index = Scope
function Scope.new()
    return setmetatable({ items = {}, dead = false }, Scope)
end
function Scope:remove(key)
    local dispose = self.items[key]
    self.items[key] = nil
    if dispose then
        pcall(dispose)
    end
end
function Scope:give(key, dispose)
    self:remove(key)
    if self.dead then
        pcall(dispose)
    else
        self.items[key] = dispose
    end
end
function Scope:connect(signal, fn)
    local conn = signal:Connect(function(...)
        if not self.dead then
            fn(...)
        end
    end)
    self:give(conn, function()
        conn:Disconnect()
    end)
    return conn
end
function Scope:later(key, seconds, fn)
    self:remove(key)
    if self.dead then
        return
    end
    local function run()
        self.items[key] = nil
        if not self.dead then
            fn()
        end
    end
    local thread = seconds > 0 and task.delay(seconds, run) or task.defer(run)
    self:give(key, function()
        if coroutine.running() ~= thread and coroutine.status(thread) ~= "dead" then
            task.cancel(thread)
        end
    end)
end
-- Unlike a scheduled timer, a started job remains owned while Roblox yields.
function Scope:job(key, fn)
    self:remove(key)
    if self.dead then
        return
    end
    local thread
    local function cancel()
        if coroutine.running() ~= thread and coroutine.status(thread) ~= "dead" then
            task.cancel(thread)
        end
    end
    thread = task.defer(function()
        if not self.dead then
            fn()
        end
        if self.items[key] == cancel then
            self.items[key] = nil
        end
    end)
    self:give(key, cancel)
end
function Scope:destroy()
    if self.dead then
        return
    end
    self.dead = true
    local snapshot = self.items
    self.items = {}
    for _, dispose in pairs(snapshot) do
        pcall(dispose)
    end
end

local Life = Scope.new()
function U.make(class, parent, name, props)
    local obj = Instance.new(class)
    obj.Name = name
    if obj:IsA("GuiObject") then
        obj.BackgroundTransparency = 1
        obj.BorderSizePixel = 0
        obj.Selectable = false
    end
    if props then
        for k, value in pairs(props) do
            obj[k] = value
        end
    end
    obj.Parent = parent
    return obj
end
function U.place(obj, x, y, width, height)
    obj.Position, obj.Size = O(x, y), O(math.max(0, width), math.max(0, height))
end
function U.fill(parent, name, color, props)
    local obj = U.make("Frame", parent, name, props)
    obj.BackgroundColor3, obj.BackgroundTransparency = color, 0
    return obj
end
function U.corner(obj, radius)
    return U.make("UICorner", obj, "Radius", { CornerRadius = UDim.new(0, radius) })
end
function U.border(obj, color, transparency, thickness)
    return U.make("UIStroke", obj, "Edge", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end
function U.gradient(obj, from, to, rotation)
    return U.make("UIGradient", obj, "Tone", { Color = ColorSequence.new(from, to), Rotation = rotation or 0 })
end
function U.label(parent, name, text, size, color, weight, align)
    return U.make("TextLabel", parent, name, {
        Text = text,
        TextSize = size,
        TextColor3 = color or Theme.ink,
        FontFace = FontFace[weight or "normal"],
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end
function U.middle(parent, name, text, size, color, weight)
    return U.label(parent, name, text, size, color, weight, Enum.TextXAlignment.Center)
end
function U.tween(scope, slot, obj, seconds, goals, style, direction, repeats)
    scope:remove(slot)
    if scope.dead then
        return
    end
    if Settings.reduced or seconds <= 0 then
        for k, value in pairs(goals) do
            obj[k] = value
        end
        return
    end
    local animation = Services.Tween:Create(
        obj,
        TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out, repeats or 0),
        goals
    )
    local conn
    local function dispose()
        conn:Disconnect()
        animation:Cancel()
        animation:Destroy()
    end
    conn = animation.Completed:Connect(function()
        conn:Disconnect()
        if scope.items[slot] == dispose then
            scope.items[slot] = nil
        end
        animation:Destroy()
    end)
    scope:give(slot, dispose)
    animation:Play()
end
function U.scroll(parent, name)
    return U.make("ScrollingFrame", parent, name, {
        CanvasSize = O(0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.coral,
        ScrollBarImageTransparency = 0.12,
        TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        ClipsDescendants = true,
    })
end

-- Paths follow JetZ's native-stroke convention. A geometry fallback is always
-- available; the UI does not require uploaded decorations or a second UI loader.
local Paths = {
    brand = {
        { 0.50, 0.07, 0.20, 0.50, 3.7 },
        { 0.20, 0.50, 0.50, 0.93, 3.7 },
        { 0.59, 0.28, 0.77, 0.50, 4.4 },
        {
            0.77,
            0.50,
            0.59,
            0.72,
            4.4,
        },
    },
    brandPair = {
        { 0.41, 0.13, 0.14, 0.50, 3 },
        { 0.14, 0.50, 0.41, 0.87, 3 },
        { 0.59, 0.13, 0.32, 0.50, 3 },
        { 0.32, 0.50, 0.59, 0.87, 3 },
        { 0.60, 0.27, 0.80, 0.50, 3 },
        { 0.80, 0.50, 0.60, 0.73, 3 },
    },
    check = { { 0.17, 0.52, 0.40, 0.76 }, { 0.40, 0.76, 0.86, 0.28 } },
    x = { { 0.22, 0.22, 0.78, 0.78 }, { 0.78, 0.22, 0.22, 0.78 } },
    menu = { { 0.17, 0.26, 0.83, 0.26 }, { 0.17, 0.50, 0.83, 0.50 }, { 0.17, 0.74, 0.83, 0.74 } },
    key = {
        { 0.49, 0.52, 0.10, 0.90 },
        { 0.28, 0.73, 0.40, 0.83 },
        { 0.17, 0.83, 0.27, 0.93 },
        { "o", 0.65, 0.35, 0.49 },
    },
    search = { { 0.43, 0.62, 0.12, 0.92 }, { "o", 0.59, 0.43, 0.56 } },
    account = {
        { "o", 0.50, 0.29, 0.36 },
        { 0.16, 0.85, 0.84, 0.85 },
        { 0.16, 0.85, 0.16, 0.73 },
        { 0.16, 0.73, 0.29, 0.59 },
        { 0.29, 0.59, 0.72, 0.59 },
        { 0.72, 0.59, 0.84, 0.73 },
        { 0.84, 0.73, 0.84, 0.85 },
    },
    info = { { "o", 0.50, 0.50, 0.85 }, { ".", 0.50, 0.34, 0.09 }, { 0.50, 0.48, 0.50, 0.68 } },
    clock = { { "o", 0.50, 0.50, 0.84 }, { 0.50, 0.25, 0.50, 0.50 }, { 0.50, 0.50, 0.68, 0.62 } },
    games = {
        { 0.11, 0.44, 0.06, 0.73 },
        { 0.06, 0.73, 0.17, 0.82 },
        { 0.17, 0.82, 0.34, 0.66 },
        { 0.34, 0.66, 0.66, 0.66 },
        { 0.66, 0.66, 0.83, 0.82 },
        { 0.83, 0.82, 0.94, 0.73 },
        { 0.94, 0.73, 0.88, 0.44 },
        { 0.88, 0.44, 0.77, 0.29 },
        { 0.77, 0.29, 0.23, 0.29 },
        { 0.23, 0.29, 0.11, 0.44 },
        { 0.20, 0.48, 0.39, 0.48 },
        { 0.30, 0.39, 0.30, 0.58 },
        { ".", 0.68, 0.48, 0.08 },
        { ".", 0.80, 0.53, 0.08 },
    },
    settings = {
        { "o", 0.50, 0.50, 0.30 },
        { 0.39, 0.09, 0.61, 0.09 },
        { 0.61, 0.09, 0.66, 0.22 },
        { 0.66, 0.22, 0.80, 0.20 },
        { 0.80, 0.20, 0.91, 0.39 },
        { 0.91, 0.39, 0.81, 0.50 },
        { 0.81, 0.50, 0.91, 0.61 },
        { 0.91, 0.61, 0.80, 0.80 },
        { 0.80, 0.80, 0.66, 0.78 },
        { 0.66, 0.78, 0.61, 0.91 },
        { 0.61, 0.91, 0.39, 0.91 },
        { 0.39, 0.91, 0.34, 0.78 },
        { 0.34, 0.78, 0.20, 0.80 },
        { 0.20, 0.80, 0.09, 0.61 },
        { 0.09, 0.61, 0.19, 0.50 },
        { 0.19, 0.50, 0.09, 0.39 },
        { 0.09, 0.39, 0.20, 0.20 },
        { 0.20, 0.20, 0.34, 0.22 },
        { 0.34, 0.22, 0.39, 0.09 },
    },
    crown = {
        { 0.10, 0.30, 0.24, 0.77 },
        { 0.24, 0.77, 0.76, 0.77 },
        { 0.76, 0.77, 0.90, 0.30 },
        { 0.90, 0.30, 0.68, 0.49 },
        { 0.68, 0.49, 0.50, 0.20 },
        { 0.50, 0.20, 0.32, 0.49 },
        { 0.32, 0.49, 0.10, 0.30 },
    },
    calendar = {
        { 0.15, 0.24, 0.85, 0.24 },
        { 0.85, 0.24, 0.85, 0.87 },
        { 0.85, 0.87, 0.15, 0.87 },
        { 0.15, 0.87, 0.15, 0.24 },
        { 0.15, 0.44, 0.85, 0.44 },
        { 0.34, 0.13, 0.34, 0.32 },
        { 0.66, 0.13, 0.66, 0.32 },
        { ".", 0.34, 0.61, 0.075 },
        { ".", 0.50, 0.61, 0.075 },
        { ".", 0.66, 0.61, 0.075 },
        { ".", 0.34, 0.73, 0.075 },
        { ".", 0.50, 0.73, 0.075 },
    },
    external = {
        { 0.67, 0.49, 0.67, 0.86 },
        { 0.67, 0.86, 0.14, 0.86 },
        { 0.14, 0.86, 0.14, 0.34 },
        { 0.14, 0.34, 0.48, 0.34 },
        { 0.44, 0.58, 0.85, 0.16 },
        { 0.85, 0.16, 0.85, 0.43 },
        { 0.85, 0.16, 0.57, 0.16 },
    },
    copy = {
        { 0.34, 0.36, 0.89, 0.36 },
        { 0.89, 0.36, 0.89, 0.90 },
        { 0.89, 0.90, 0.34, 0.90 },
        { 0.34, 0.90, 0.34, 0.36 },
        { 0.65, 0.22, 0.65, 0.10 },
        { 0.65, 0.10, 0.11, 0.10 },
        { 0.11, 0.10, 0.11, 0.65 },
        { 0.11, 0.65, 0.20, 0.65 },
    },
    erase = {
        { 0.09, 0.51, 0.29, 0.51 },
        { 0.09, 0.51, 0.31, 0.29 },
        { 0.09, 0.51, 0.31, 0.73 },
        { 0.34, 0.51, 0.88, 0.51 },
        { 0.61, 0.23, 0.88, 0.23 },
        { 0.88, 0.23, 0.88, 0.80 },
        { 0.88, 0.80, 0.61, 0.80 },
    },
    refresh = {
        { 0.82, 0.36, 0.68, 0.16 },
        { 0.68, 0.16, 0.35, 0.14 },
        { 0.35, 0.14, 0.14, 0.35 },
        { 0.14, 0.35, 0.13, 0.45 },
        { 0.82, 0.15, 0.82, 0.36 },
        { 0.61, 0.36, 0.82, 0.36 },
        { 0.18, 0.64, 0.32, 0.84 },
        { 0.32, 0.84, 0.65, 0.86 },
        { 0.65, 0.86, 0.86, 0.65 },
        { 0.86, 0.65, 0.87, 0.55 },
        { 0.18, 0.85, 0.18, 0.64 },
        { 0.18, 0.64, 0.39, 0.64 },
    },
    eye = {
        { "o", 0.50, 0.50, 0.23 },
        { 0.08, 0.50, 0.28, 0.25 },
        { 0.28, 0.25, 0.72, 0.25 },
        { 0.72, 0.25, 0.92, 0.50 },
        { 0.92, 0.50, 0.72, 0.75 },
        { 0.72, 0.75, 0.28, 0.75 },
        { 0.28, 0.75, 0.08, 0.50 },
    },
    infinity = { { "o", 0.28, 0.50, 0.35 }, { "o", 0.72, 0.50, 0.35 }, { 0.45, 0.50, 0.55, 0.50 } },
    discord = {
        { "d", 0.22, 0.57, 0.36, 0.53 },
        { "d", 0.78, 0.57, 0.36, 0.53 },
        { "d", 0.50, 0.49, 0.59, 0.46 },
        { "d", 0.35, 0.53, 0.16, 0.19, 1 },
        { "d", 0.65, 0.53, 0.16, 0.19, 1 },
    },
}
function U.icon(parent, name, size, ink)
    local host = U.make("Frame", parent, name .. "Icon", { Size = O(size, size) })
    local recolor = {}
    for _, p in ipairs(Paths[name] or Paths.info) do
        if type(p[1]) == "string" then
            local width, height = size * p[4], size * (p[5] or p[4])
            local dot = U.fill(host, "Disc", p[6] and Theme.black or ink, { AnchorPoint = V(0.5, 0.5) })
            U.place(dot, p[2] * size, p[3] * size, width, height)
            U.corner(dot, size)
            if p[1] == "o" then
                dot.BackgroundTransparency = 1
                recolor[#recolor + 1] = { U.border(dot, ink, 0, math.max(1, size * 0.086)), "Color" }
            elseif not p[6] then
                recolor[#recolor + 1] = { dot, "BackgroundColor3" }
            end
        else
            local x, y = (p[3] - p[1]) * size, (p[4] - p[2]) * size
            local thick = p[5] and size * p[5] / 24 or math.max(1, size * 0.087)
            local line = U.fill(host, "Stroke", ink, {
                AnchorPoint = V(0.5, 0.5),
                Rotation = math.deg(math.atan2(y, x)),
            })
            U.place(
                line,
                (p[1] + p[3]) * size / 2,
                (p[2] + p[4]) * size / 2,
                math.sqrt(x * x + y * y) + thick * 0.65,
                thick
            )
            U.corner(line, thick / 2)
            recolor[#recolor + 1] = { line, "BackgroundColor3" }
        end
    end
    return host,
        function(color)
            for _, part in ipairs(recolor) do
                part[1][part[2]] = color
            end
        end
end
function U.centerIcon(parent, name, size, color)
    local icon, paint = U.icon(parent, name, size, color)
    icon.AnchorPoint, icon.Position = V(0.5, 0.5), S(0.5, 0.5)
    return icon, paint
end
function U.button(parent, name, action, scope)
    scope = scope or Life
    local root = U.make("TextButton", parent, name, {
        Text = "",
        AutoButtonColor = false,
        Active = true,
        Selectable = true,
        SelectionImageObject = UI.focus,
    })
    root:SetAttribute("ActionLabel", name)
    local btn = { root = root, enabled = true, hover = false, down = false, scope = scope }
    local function paint()
        if btn.paint then
            btn.paint(btn)
        end
    end
    scope:connect(root.MouseEnter, function()
        if not Services.Input.TouchEnabled then
            btn.hover = true
            paint()
        end
    end)
    scope:connect(root.MouseLeave, function()
        btn.hover, btn.down = false, false
        paint()
    end)
    scope:connect(root.InputBegan, function(input)
        local kind = input.UserInputType
        if btn.enabled and (kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch) then
            btn.down = true
            paint()
        end
    end)
    scope:connect(root.InputEnded, function()
        if btn.down then
            btn.down = false
            paint()
        end
    end)
    scope:connect(root.Activated, function()
        if btn.enabled and State.alive then
            btn.down = false
            paint()
            action()
        end
    end)
    function btn:enable(enabled)
        if enabled == self.enabled then
            return
        end
        self.enabled, self.down, self.hover = enabled, false, false
        root.Active, root.Selectable, root.Interactable = enabled, enabled, enabled
        paint()
    end
    return btn
end
function U.action(parent, text, name, primary, callback, scope)
    local btn = U.button(parent, text, callback, scope)
    local root = btn.root
    root.BackgroundTransparency = 0
    U.corner(root, 6)
    btn.edge = U.border(root, Theme.border)
    btn.content = U.make("Frame", root, "Caption", { AnchorPoint = V(0.5, 0.5), Position = S(0.5, 0.5) })
    btn.icon, btn.inkIcon = U.icon(btn.content, name, 15, Theme.ink)
    btn.label = U.label(btn.content, "Text", text, 14, Theme.ink, "bold")
    function btn:setText(value)
        self.label.Text = value
        root:SetAttribute("ActionLabel", value)
        local width = math.ceil((utf8.len(value) or #value) * self.label.TextSize * 0.61) + 26
        self.content.Size = O(width, 22)
        U.place(self.icon, 0, 3, 15, 15)
        U.place(self.label, 25, 0, width - 24, 22)
    end
    btn:setText(text)
    function btn:paint()
        local enabled = self.enabled
        local ink = not enabled and Theme.disabled or primary and Theme.black or Theme.ink
        local fill = not enabled and (primary and C(65, 37, 42) or Theme.surface)
            or primary and (self.down and C(215, 91, 102) or self.hover and C(250, 126, 132) or Theme.coral)
            or self.down and Theme.pressed
            or self.hover and Theme.hover
            or Theme.field
        self.label.TextColor3 = ink
        self.inkIcon(ink)
        self.edge.Color = primary and fill or enabled and C(79, 75, 87) or Theme.border
        U.tween(self.scope, self, root, 0.10, { BackgroundColor3 = fill })
    end
    root.BackgroundColor3 = primary and Theme.coral or Theme.field
    btn:paint()
    return btn
end

-- Window, navigation and shared view primitives --------------------------------
local SideOrder = { "Key System", "Games", "About", "Settings" }
local SideRoutes = { ["Key System"] = "Key", Games = "Games", About = "About", Settings = "Settings" }
local SideIcons = { ["Key System"] = "key", Games = "games", About = "info", Settings = "settings" }
local Strips = {
    Key = { "Key", "Account", "Status" },
    Account = { "Key", "Account", "Status" },
    Status = { "Key", "Account", "Status" },
    Games = { "Key", "Account", "About", "Games" },
    About = { "Key", "Account", "About" },
    Settings = { "Settings" },
}
function View.sideFor(route)
    return SideRoutes[route] and route or "Key System"
end
function View.requireIdle()
    return State.alive and State.activity == "Idle" and not State.modal
end
function View.bindBusy(button, condition)
    UI.busy[button] = condition or true
    return button
end
function View.releaseFocus()
    local focused = Services.Input:GetFocusedTextBox()
    if focused and focused:IsDescendantOf(UI.gui) then
        focused:ReleaseFocus(false)
    end
end

function View.shell(parent)
    UI.gui = U.make("ScreenGui", nil, "JetZKey", {
        Enabled = false,
        ResetOnSpawn = false,
        DisplayOrder = 82,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
        ClipToDeviceSafeArea = true,
        SafeAreaCompatibility = Enum.SafeAreaCompatibility.None,
    })
    UI.gui:SetAttribute("PlakUiOwned", true)
    UI.gui:SetAttribute("JetZKeyOwned", true)
    UI.viewport = U.make("Frame", UI.gui, "SafeViewport", { Size = S(1, 1) })
    local shell = U.fill(UI.viewport, "Plak", Theme.bg, { Active = true, ClipsDescendants = true })
    UI.shell = shell
    U.corner(shell, 10)
    U.border(shell, Theme.border, 0.56)
    UI.scale = U.make("UIScale", shell, "WindowScale", { Scale = 1 })
    local focus = U.make("Frame", nil, "KeyboardFocus", { Size = S(1, 1) })
    UI.focus = focus
    Life:give("keyboard-focus", function()
        focus:Destroy()
    end)
    U.corner(UI.focus, 5)
    U.border(UI.focus, Theme.accent, 0.14, 1.5)

    UI.body = U.make("Frame", shell, "Workspace", { ZIndex = 2, ClipsDescendants = true })
    UI.header = U.make("Frame", UI.body, "Header", { ZIndex = 3 })
    UI.dragBar = U.make("Frame", UI.header, "DragRegion", { Active = true, Size = S(1, 1) })
    UI.strip = U.make("Frame", UI.header, "SubTabs", { Size = S(1, 1), ZIndex = 2 })
    UI.stripLine = U.fill(UI.strip, "ActiveIndicator", Theme.coral, { ZIndex = 3, Size = O(0, 2) })
    for _, route in ipairs({ "Key", "Account", "Status", "Games", "About", "Settings" }) do
        local tab = U.button(UI.strip, route, function()
            View.go(route)
        end)
        tab.root.BackgroundColor3 = Theme.surface
        U.corner(tab.root, 3)
        tab.label = U.middle(tab.root, "Caption", route, 13, Theme.nav, "bold")
        tab.label.Size = S(1, 1)
        function tab:paint()
            local active = State.route == route
            self.root.BackgroundTransparency = active and 0.22 or (self.enabled and self.hover and 0.53 or 1)
            self.label.TextColor3 = active and Theme.ink
                or (self.enabled and self.hover and Theme.secondary or Theme.nav)
        end
        UI.subs[route] = View.bindBusy(tab)
    end
    UI.islandTitle = U.label(UI.header, "CompactTitle", TITLE, 15, Theme.ink, "bold")
    UI.islandTitle.ZIndex = 3
    UI.menu = U.button(UI.header, "Open navigation", function()
        View.setDrawer(not State.drawerOpen)
    end)
    UI.menu.root.ZIndex = 4
    U.centerIcon(UI.menu.root, "menu", 17, Theme.ink)
    UI.close = U.button(shell, "Close key system", function()
        Loader:Destroy()
    end)
    UI.close.root.ZIndex = 40
    local _, closePaint = U.centerIcon(UI.close.root, "x", 13, Theme.muted)
    function UI.close:paint()
        closePaint(self.hover and Theme.ink or Theme.muted)
    end

    UI.drawerShade = U.button(shell, "Close navigation", function()
        View.setDrawer(false)
    end)
    UI.drawerShade.root.ZIndex = 10
    UI.drawerShade.root.BackgroundColor3 = Theme.black
    UI.drawerShade.root.BackgroundTransparency = 0.43
    UI.drawerShade.root.Size = S(1, 1)
    UI.drawerShade.root.Visible = false
    UI.sidebar = U.fill(shell, "Sidebar", Theme.sidebar, { ZIndex = 11, ClipsDescendants = true })
    U.corner(UI.sidebar, 10)
    UI.sideFill = U.fill(UI.sidebar, "InsideEdge", Theme.sidebar)
    UI.brand = U.make("Frame", UI.sidebar, "Brand", { Active = true, ZIndex = 2 })
    UI.logo = U.icon(UI.brand, "brand", 30, Theme.coral)
    UI.title = U.label(UI.brand, "Title", TITLE, 17, Theme.ink, "bold")
    UI.brandLine = U.fill(UI.brand, "Seam", Theme.divider)
    UI.navScroll = U.scroll(UI.sidebar, "Navigation")
    UI.navScroll.ZIndex = 2
    UI.navScroll.ScrollBarThickness = 0
    for _, side in ipairs(SideOrder) do
        local tab = U.button(UI.navScroll, side, function()
            View.go(side == "Key System" and State.sub or SideRoutes[side])
        end)
        tab.root.BackgroundColor3 = Theme.selected
        U.corner(tab.root, 3)
        tab.mark = U.fill(tab.root, "ActiveIndicator", Theme.coral)
        U.corner(tab.mark, 2)
        tab.icon, tab.inkIcon = U.icon(tab.root, SideIcons[side], 18, Theme.nav)
        tab.label = U.label(tab.root, "Caption", side, 14, Theme.nav, "bold")
        function tab:paint()
            local active = View.sideFor(State.route) == side
            self.mark.Visible = active
            self.root.BackgroundTransparency = active and 0 or (self.enabled and self.hover and 0.35 or 1)
            self.label.TextColor3 = active and Theme.ink
                or (self.enabled and self.hover and Theme.secondary or Theme.nav)
            self.inkIcon(active and Theme.coral or self.label.TextColor3)
        end
        UI.sides[side] = View.bindBusy(tab)
    end
    UI.footer = U.label(UI.sidebar, "Release", "Release " .. Settings.version, 12, Theme.ink, "medium")
    UI.footer.ZIndex = 2
    UI.pages = U.make("Frame", UI.body, "Pages", { ClipsDescendants = true })
    for route in pairs(Strips) do
        UI.routes[route] = route == "Games" and U.make("Frame", UI.pages, route) or U.scroll(UI.pages, route)
        UI.routes[route].Visible = route == State.route
    end
    UI.restore = U.action(UI.viewport, "Plak", "brand", false, function()
        Loader:Show()
    end)
    UI.restore.root.AnchorPoint, UI.restore.root.Position = V(0, 0.5), UDim2.new(0, 10, 0.5, 0)
    UI.restore.root.Size, UI.restore.root.Visible = O(91, 44), false
    UI.gui.Parent = parent
end

function View.setDrawer(enabled)
    local g = State.geometry
    State.drawerOpen = enabled and g and g.drawer and State.activity == "Idle" or false
    if not g then
        return
    end
    UI.drawerShade.root.Visible = State.drawerOpen
    UI.sidebar.Visible = not g.drawer or State.drawerOpen
end

function View.strip(animate)
    local g = State.geometry
    if not g then
        return
    end
    UI.strip.Visible = g.header > 0
    if g.header <= 0 then
        return
    end
    local route = State.route
    local strip = Strips[route]
    for _, tab in pairs(UI.subs) do
        tab.root.Visible = false
    end
    local compact = g.compact
    local x, gap, row = compact and 10 or 64, compact and 5 or 18, g.header
    local desired = { Key = 88, Account = 100, Status = 88, Games = 93, About = 92, Settings = 108 }
    local available = math.max(1, g.viewW - x - (g.drawer and 10 or g.hit + 12))
    local widthSum = 0
    for _, name in ipairs(strip) do
        widthSum += desired[name]
    end
    local factor = math.min(1, math.max(1, available - (#strip - 1) * gap) / widthSum)
    for _, name in ipairs(strip) do
        local tab = UI.subs[name]
        local w = math.floor(desired[name] * factor)
        tab.root.Visible = true
        U.place(tab.root, x, 0, w, row)
        tab.label.TextSize = compact and 12 or 13
        tab:paint()
        if name == route then
            local pos = O(x, route == "About" and row - 2 or 0)
            U.tween(Life, "selected-sub", UI.stripLine, animate and 0.17 or 0, { Position = pos, Size = O(w, 2.5) })
        end
        x += w + gap
    end
end

function View.go(route, force)
    if not State.alive or not Strips[route] then
        return false
    end
    if not force and not View.requireIdle() then
        return false
    end
    View.setDrawer(false)
    if State.route == route then
        return true
    end
    View.releaseFocus()
    local old = State.route
    if old == "About" then
        FX.stopAbout()
    end
    UI.routes[old].Visible = false
    State.route = route
    if View.sideFor(route) == "Key System" then
        State.sub = route
    end
    UI.routes[route].Visible = true
    for _, tab in pairs(UI.sides) do
        tab:paint()
    end
    View.layout(false, true)
    View.paint()
    if route == "About" then
        FX.enterAbout()
    end
    if route == "Games" then
        Catalog.render()
    end
    return true
end

function View.heading(parent, icon, title, detail)
    local h = { root = U.make("Frame", parent, title .. "Heading") }
    h.tile = U.fill(h.root, "IconTile", Theme.darkCoral)
    U.corner(h.tile, 7)
    U.border(h.tile, Theme.accent, 0.61, 1.25)
    U.centerIcon(h.tile, icon, 25, Theme.accent)
    h.title = U.middle(h.root, "Title", title, 22, Theme.ink, "bold")
    h.detail = U.middle(h.root, "Description", detail, 12, Theme.muted)
    return h
end
function View.placeHeading(h, x, y, w, compact, tight)
    local tile = tight and 31 or compact and 37 or 47
    local titleH = tight and 22 or 28
    local below = tight and 3 or 7
    h.title.TextSize = tight and 17 or compact and 19 or 22
    h.detail.TextSize = tight and 11 or 12
    U.place(h.root, x, y, w, tile + titleH + below + 20)
    U.place(h.tile, math.floor((w - tile) / 2), 0, tile, tile)
    U.place(h.title, 0, tile + below, w, titleH)
    U.place(h.detail, 0, tile + below + titleH, w, 18)
end

function View.check(parent, text, detail, handler, name)
    local btn = U.button(parent, name or text, handler)
    btn.square = U.fill(btn.root, "Checkbox", Theme.coral)
    U.corner(btn.square, 4)
    btn.edge = U.border(btn.square, Theme.accent, 0.14)
    btn.mark = U.centerIcon(btn.square, "check", 14, Theme.black)
    btn.label = U.label(btn.root, "Caption", text, 13, Theme.ink, "medium")
    btn.detail = U.label(btn.root, "Description", detail, 11, Theme.muted)
    btn.detail.TextXAlignment = Enum.TextXAlignment.Right
    function btn:paint()
        local on = self.checked == true
        self.mark.Visible = on
        self.square.BackgroundColor3 = not self.enabled and Theme.raised
            or on and (self.down and Theme.accent or self.hover and C(250, 126, 132) or Theme.coral)
            or self.hover and Theme.hover
            or Theme.field
        self.edge.Transparency = self.enabled and 0.17 or 0.55
        self.label.TextColor3 = self.enabled and Theme.ink or Theme.muted
        self.root:SetAttribute("Checked", on)
    end
    function btn:layout(w, h, stack)
        local square = stack and 20 or 23
        U.place(self.square, 0, math.floor((h - square) / 2), square, square)
        U.place(self.label, square + 15, stack and 3 or 0, stack and w - square - 15 or 146, stack and 21 or h)
        self.detail.TextXAlignment = stack and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
        U.place(
            self.detail,
            stack and square + 15 or 162,
            stack and 21 or 0,
            w - (stack and square + 15 or 162) - 4,
            stack and 19 or h
        )
    end
    return btn
end
function View.input(parent, name, hint, image, isKey)
    local field = { root = U.fill(parent, name .. "Field", Theme.field) }
    U.corner(field.root, 6)
    field.edge = U.border(field.root, Theme.accent, 0.12, 1.1)
    field.icon, field.paintIcon = U.icon(field.root, image, 16, Theme.muted)
    field.icon.AnchorPoint, field.icon.Position = V(0, 0.5), UDim2.new(0, 13, 0.5, 0)
    field.box = U.make("TextBox", field.root, name, {
        Text = "",
        PlaceholderText = hint,
        PlaceholderColor3 = Theme.muted,
        TextColor3 = Theme.ink,
        TextSize = 13,
        FontFace = Regular,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        MultiLine = false,
        TextWrapped = false,
        SelectionImageObject = UI.focus,
        Active = true,
        Selectable = true,
        Position = O(46, 0),
        Size = UDim2.new(1, isKey and -88 or -54, 1, 0),
    })
    function field:paint()
        local focused = self.box:IsFocused()
        local color = isKey and State.authError and Theme.error or Theme.coral
        self.paintIcon(focused and Theme.accent or Theme.muted)
        U.tween(Life, self.edge, self.edge, 0.10, { Color = color, Transparency = focused and 0 or 0.24 })
    end
    Life:connect(field.box.Focused, function()
        field:paint()
    end)
    Life:connect(field.box.FocusLost, function()
        field:paint()
    end)
    return field
end
function View.lines(page, name)
    return U.fill(page, name, Theme.divider)
end
function View.fitScroll(page, height)
    local position = page.CanvasPosition
    page.CanvasSize = O(0, math.max(0, height))
    local g = State.geometry
    local maxScroll = math.max(0, height * g.scale - page.AbsoluteWindowSize.Y)
    if position.Y > maxScroll then
        page.CanvasPosition = V(0, maxScroll)
    end
end

function View.buildKey()
    local page = UI.routes.Key
    local k = { page = page }
    UI.key = k
    k.heading = View.heading(page, "key", "Key System", "Enter your key to unlock Plak.")
    k.topRule, k.midRule, k.bottomRule =
        View.lines(page, "HeaderDivider"), View.lines(page, "FieldDivider"), View.lines(page, "ActionDivider")
    k.caption = U.label(page, "InsertKey", "Insert Key", 13, Theme.ink, "bold")
    k.captionIcon = U.icon(page, "settings", 10, Theme.disabled)
    k.field = View.input(page, "KeyInput", "Enter your key...", "key", true)
    k.mask = U.label(k.field.root, "KeyMask", "", 13, Theme.ink)
    k.mask.Position, k.mask.Size = k.field.box.Position, k.field.box.Size
    k.mask.ZIndex = 2
    k.mask.Visible = false
    k.reveal = View.bindBusy(U.button(k.field.root, "Show or hide key", function()
        Loader:SetKeyVisible(not Settings.keyVisible)
    end))
    k.reveal.root.AnchorPoint = V(1, 0.5)
    k.reveal.root.Position = UDim2.new(1, -2, 0.5, 0)
    k.reveal.root.Size = UDim2.new(0, 40, 1, 0)
    k.reveal.root.ZIndex = 3
    local _, ink = U.centerIcon(k.reveal.root, "eye", 15, Theme.muted)
    function k.reveal:paint()
        ink((self.hover or Settings.keyVisible) and Theme.accent or Theme.muted)
    end
    k.remember = View.check(page, "Remember Me", "Save your key for next time.", function()
        Prefs.remember(not Settings.remember)
    end, "Remember Me")
    UI.checks[1] = k.remember
    k.rememberIcon = U.icon(k.remember.root, "settings", 10, Theme.disabled)
    k.validate = View.bindBusy(
        U.action(page, "Validate Key", "check", true, function()
            Loader:Validate()
        end),
        function()
            return not State.authorized and not State.closedAttempt
        end
    )
    k.get = View.bindBusy(U.action(page, "Get Key", "external", false, function()
        View.link(REWARD, "Key Link Copied")
    end))
    k.feedback = U.label(page, "ValidationFeedback", "", 11, Theme.error, "medium")
    k.feedback.TextWrapped = true
    k.feedback.TextYAlignment = Enum.TextYAlignment.Top
    Life:connect(k.field.box:GetPropertyChangedSignal("Text"), function()
        View.mask()
        if State.authError and not State.settingKey and State.activity == "Idle" then
            State.authError, State.message = false, nil
            View.paint()
        end
    end)
    Life:connect(k.field.box.Focused, View.mask)
    Life:connect(k.field.box.FocusLost, function(submit)
        View.mask()
        if submit then
            Loader:Validate()
        end
    end)
    Life:connect(k.field.box.ReturnPressedFromOnScreenKeyboard, function()
        if State.route == "Key" and State.visible and View.requireIdle() then
            Loader:Validate()
        end
    end)
end
function View.mask()
    local k = UI.key
    if not State.alive or not k then
        return
    end
    local box = k.field.box
    local hidden = box.Text ~= "" and not Settings.keyVisible and not box:IsFocused()
    box.TextTransparency = hidden and 1 or 0
    k.mask.Visible = hidden
    k.mask.Text = hidden and string.rep("•", math.min(54, utf8.len(box.Text) or #box.Text)) or ""
    k.reveal:paint()
end
function View.actionPair(left, right, x, y, w, h, gap, fraction, threshold)
    if w < (threshold or 362) then
        U.place(left.root, x, y, w, h)
        U.place(right.root, x, y + h + 8, w, h)
        return y + 2 * h + 8
    end
    local first = math.floor((w - gap) * (fraction or 0.5))
    U.place(left.root, x, y, first, h)
    U.place(right.root, x + first + gap, y, w - first - gap, h)
    return y + h
end
function View.layoutKey(g)
    local k = UI.key
    local x, right = g.compact and 16 or 67, g.compact and 16 or 47
    local w = math.max(1, g.viewW - x - right)
    local compact = g.compact or g.viewH < 355
    local top = compact and 13 or 33
    View.placeHeading(k.heading, x, top, w, compact, false)
    local rule = top + (compact and 103 or 128)
    U.place(k.topRule, x, rule, w, 1)
    U.place(k.caption, x, rule + 13, w, 22)
    U.place(k.captionIcon, x + 90, rule + 19, 10, 10)
    local fieldY = rule + 41
    local fieldH = math.max(36, g.touch and g.hit or 0)
    U.place(k.field.root, x, fieldY, w, fieldH)
    local rememberY = fieldY + fieldH + (compact and 10 or 18)
    local rememberH = math.max(g.touch and g.hit or 0, compact and 43 or 50)
    U.place(k.midRule, x, rememberY, w, 1)
    U.place(k.remember.root, x, rememberY + 1, w, rememberH - 1)
    k.remember:layout(w, rememberH - 1, w < 466)
    k.rememberIcon.Visible = w >= 466
    U.place(k.rememberIcon, 134, (rememberH - 10) / 2, 10, 10)
    local bottom = rememberY + rememberH
    U.place(k.bottomRule, x, bottom, w, 1)
    local actionHeight = math.max(41, g.touch and g.hit or 0)
    local last = View.actionPair(k.validate, k.get, x, bottom + (compact and 12 or 19), w, actionHeight, 16, 0.527)
    U.place(k.feedback, x, last + 8, w, 34)
    View.fitScroll(k.page, last + (State.authError and 45 or 17))
end

-- License and truthful operational status ------------------------------------
local AccountRows = {
    { "key", "License Key" },
    { "calendar", "Key Expiration" },
    { "clock", "Time Remaining" },
}
local StatusRows = {
    { "key", "Authentication" },
    { "refresh", "FlowAuth" },
    { "calendar", "License validity" },
    { "games", "Current game" },
    { "info", "Game catalog" },
}
function View.fact(parent, glyph, title)
    local row = { root = U.make("Frame", parent, title) }
    row.icon = U.icon(row.root, glyph, 17, Theme.muted)
    row.label = U.label(row.root, "Label", title, 13, Theme.ink, "medium")
    row.value = U.label(row.root, "Value", "", 12, Theme.secondary, "medium", Enum.TextXAlignment.Right)
    row.rule = View.lines(row.root, "Divider")
    return row
end
function View.placeFact(row, x, y, w, h, stack, tail)
    tail = tail or 0
    U.place(row.root, x, y, w, h)
    U.place(row.icon, 8, stack and 8 or (h - 17) / 2, 17, 17)
    U.place(row.label, 41, stack and 2 or 0, stack and w - 49 - tail or w * 0.46 - 34, stack and 27 or h)
    row.value.TextXAlignment = stack and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
    U.place(
        row.value,
        stack and 41 or w * 0.46,
        stack and 24 or 0,
        stack and w - 49 - tail or w * 0.54 - 7 - tail,
        stack and h - 25 or h
    )
    U.place(row.rule, 0, h - 1, w, 1)
end
function View.buildAccount()
    local a = { page = UI.routes.Account, rows = {} }
    UI.account = a
    a.heading = View.heading(a.page, "account", "Account", "Your license and account details.")
    a.plan = U.fill(a.page, "Plan", Theme.field)
    U.corner(a.plan, 8)
    a.edge = U.border(a.plan, Theme.border, 0, 1.1)
    a.tone = U.gradient(a.plan, Color3.new(1, 1, 1), C(155, 150, 165), 14)
    a.tile = U.fill(a.plan, "PlanIcon", Theme.raised)
    U.corner(a.tile, 7)
    a.crown = U.centerIcon(a.tile, "crown", 31, Theme.coral)
    a.person = U.centerIcon(a.tile, "account", 25, Theme.secondary)
    a.planLabel = U.label(a.plan, "Label", "Plan", 12, Theme.secondary)
    a.planText = U.label(a.plan, "Value", "Not authenticated", 22, Theme.ink, "bold")
    a.badge = U.fill(a.plan, "LicenseState", Theme.raised)
    U.corner(a.badge, 6)
    a.badgeStroke = U.border(a.badge, Theme.border, 0.20)
    a.badgeIcon, a.badgeInk = U.icon(a.badge, "check", 14, Theme.green)
    a.badgeText = U.middle(a.badge, "State", "", 12, Theme.secondary, "medium")
    for _, spec in ipairs(AccountRows) do
        a.rows[#a.rows + 1] = View.fact(a.page, spec[1], spec[2])
    end
    a.copy = View.bindBusy(
        U.button(a.rows[1].root, "Copy verified license key", function()
            if not State.authorized or not State.key then
                return
            end
            local ok, result = U.call(U.cap("setclipboard", "toclipboard", "writeclipboard"), State.key)
            if not State.alive then
                return
            end
            if ok and result ~= false then
                Loader:Toast({ Type = "success", Title = "License Key Copied", Subtitle = "Copied to your clipboard." })
            else
                Loader:Toast({
                    Type = "warning",
                    Title = "Could Not Copy",
                    Subtitle = "Clipboard access is unavailable.",
                })
            end
        end),
        function()
            return State.authorized
                and State.key ~= nil
                and Auth.remaining() ~= 0
                and U.cap("setclipboard", "toclipboard", "writeclipboard") ~= nil
        end
    )
    U.centerIcon(a.copy.root, "copy", 16, Theme.ink)
    a.refresh = View.bindBusy(U.action(a.page, "Refresh", "refresh", false, Auth.refreshNow), function()
        return State.authorized and State.callbacks.Refresh ~= nil
    end)
    a.clear = View.bindBusy(
        U.action(a.page, "Clear Saved Key", "erase", true, function()
            Loader:ForgetSavedKey()
        end),
        function()
            return State.callbacks.ForgetKey ~= nil
        end
    )
    a.note = U.label(a.page, "AccountActions", "", 11, Theme.muted)
    a.note.TextWrapped = true
    a.note.TextYAlignment = Enum.TextYAlignment.Top
end
function View.layoutAccount(g)
    local a = UI.account
    local x, right = g.compact and 16 or 50, g.compact and 16 or 36
    local w = math.max(1, g.viewW - x - right)
    local compact = g.compact or g.viewH < 355
    local stack = w < 485
    local short = compact and g.viewH < 355
    local top = compact and 8 or 20
    View.placeHeading(a.heading, x, top, w, compact, short)
    local planY = top + (short and 80 or compact and 93 or 117)
    local planH = compact and 61 or 73
    U.place(a.plan, x, planY, w, planH)
    local tile = compact and 40 or 50
    local left = compact and 10 or 16
    U.place(a.tile, left, (planH - tile) / 2, tile, tile)
    local contentX = left + tile + 14
    local badgeW = compact and 68 or 84
    local infoW = w - contentX - badgeW - left - 6
    a.planText.TextSize = compact and 16 or 22
    U.place(a.planLabel, contentX, 10, infoW, 20)
    U.place(a.planText, contentX, 27, infoW, 30)
    U.place(a.badge, w - left - badgeW, (planH - 28) / 2, badgeW, 28)
    U.place(a.badgeIcon, 8, 7, 14, 14)
    U.place(a.badgeText, 0, 0, badgeW, 28)
    local y = planY + planH + 10
    local h = stack and 47 or short and 35 or 40
    for i, row in ipairs(a.rows) do
        View.placeFact(row, x, y, w, h, stack, i == 1 and 40 or 0)
        y += h
    end
    U.place(a.copy.root, w - 40, 0, 40, h)
    local last = View.actionPair(
        a.refresh,
        a.clear,
        x,
        y + (compact and 12 or 16),
        w,
        math.max(41, g.touch and g.hit or 0),
        compact and 10 or 15,
        0.494,
        330
    )
    U.place(a.note, x, last + 8, w, 29)
    View.fitScroll(a.page, last + 42)
end

function View.buildStatus()
    local page = UI.routes.Status
    local t = { page = page, rows = {} }
    UI.status = t
    t.heading = View.heading(page, "info", "Status", "Authentication and game support.")
    for _, spec in ipairs(StatusRows) do
        t.rows[#t.rows + 1] = View.fact(page, spec[1], spec[2])
    end
    t.note = U.label(page, "StatusDetail", "", 11, Theme.muted)
    t.note.TextWrapped = true
    t.note.TextYAlignment = Enum.TextYAlignment.Top
end
function View.layoutStatus(g)
    local t = UI.status
    local x, right = g.compact and 16 or 50, g.compact and 16 or 36
    local w = math.max(1, g.viewW - x - right)
    local top = g.compact and 8 or 21
    local short = g.compact and g.viewH < 355
    View.placeHeading(t.heading, x, top, w, g.compact, short)
    local y = top + (short and 80 or g.compact and 94 or 120)
    local stack = w < 420
    local h = stack and 47 or short and 39 or 42
    for _, row in ipairs(t.rows) do
        View.placeFact(row, x, y, w, h, stack)
        y += h
    end
    U.place(t.note, x, y + 12, w, 45)
    View.fitScroll(t.page, y + 63)
end

function Auth.remaining(info)
    info = info or State.info
    if not info or info.tier == "keyless" then
        return nil
    end
    if info.seconds == math.huge then
        return math.huge
    end
    return info.deadline and math.max(0, info.deadline - os.clock()) or nil
end
function Auth.duration(seconds)
    if seconds == math.huge then
        return "No time limit"
    end
    if seconds == nil then
        return "Unavailable"
    end
    if seconds <= 0 then
        return "0m"
    end
    local minutes = math.floor(seconds / 60)
    if minutes == 0 then
        return "<1m"
    end
    return string.format("%dd %02dh %02dm", math.floor(minutes / 1440), math.floor(minutes / 60) % 24, minutes % 60)
end
function Auth.mask(key)
    if not key then
        return "Unavailable"
    end
    local len = utf8.len(key)
    if not len or len < 9 then
        return "****"
    end
    local suffix = key:sub(utf8.offset(key, -4))
    local prefix, middle, last = key:match("^([%w]+)%-(.+)%-([%w]+)$")
    if prefix and #prefix <= 6 and #last == 4 then
        local masked = middle:gsub("[^%-]+", "****")
        return prefix .. "-" .. masked:sub(1, 18) .. "-" .. suffix
    end
    return "••••-" .. suffix
end

function View.account()
    Life:remove("countdown")
    local a, t = UI.account, UI.status
    local confirmed = State.authorized
    local tier = confirmed and State.info and State.info.tier or nil
    local remaining = confirmed and Auth.remaining() or nil
    local expired = confirmed and remaining == 0
    local premium = tier == "premium"
    local hasTier = tier ~= nil
    local keyless = tier == "keyless"
    local label = not confirmed and "Not authenticated"
        or keyless and "Keyless"
        or premium and "Premium"
        or tier == "free" and "Free"
        or "Unavailable"
    if not confirmed and State.geometry.compact then
        label = "Not signed in"
    end
    local tone = premium and not expired and Theme.coral or Theme.ink
    a.planText.Text, a.planText.TextColor3 = label, tone
    a.plan.BackgroundColor3 = premium and not expired and C(48, 29, 33) or Theme.field
    a.tile.BackgroundColor3 = premium and not expired and C(76, 38, 44) or Theme.raised
    a.edge.Color = premium and not expired and Theme.coral or Theme.border
    a.crown.Visible, a.person.Visible = premium, not premium
    a.badgeText.Text = expired and "Expired" or confirmed and (hasTier and "Active" or "Verified") or "Inactive"
    local badgeInk = expired and Theme.error or confirmed and Theme.green or Theme.muted
    a.badgeText.TextColor3, a.badgeStroke.Color = badgeInk, badgeInk
    a.badge.BackgroundColor3 = confirmed and not expired and Theme.deepGreen or Theme.raised
    a.badgeIcon.Visible = confirmed and not expired and not State.geometry.compact
    a.badgeInk(badgeInk)
    a.badgeText.Position = O(a.badgeIcon.Visible and 11 or 0, 0)
    a.rows[1].value.Text = not confirmed and "Not authenticated"
        or keyless and "No key required"
        or Auth.mask(State.key)
    local date = "Unavailable"
    if expired then
        date = "Expired"
    elseif remaining == math.huge then
        date = "Never expires"
    elseif remaining and State.info.untilUnix then
        local ok, result = pcall(os.date, "!%b %d, %Y %I:%M %p", math.floor(State.info.untilUnix))
        if ok and type(result) == "string" then
            date = result .. " UTC"
        end
    end
    a.rows[2].value.Text = not confirmed and "Not authenticated" or keyless and "Not applicable" or date
    a.rows[3].value.Text = not confirmed and "Not authenticated"
        or keyless and "Not applicable"
        or Auth.duration(remaining)
    a.rows[3].value.TextColor3 = confirmed and remaining ~= nil and Theme.coral or Theme.secondary
    a.copy.root.Visible = State.key ~= nil and not keyless
    a.note.Text = State.callbacks.Refresh and "Clearing a saved key does not sign you out."
        or "License refresh isn't available. Clearing a saved key does not sign you out."
    t.rows[1].value.Text = expired and "Expired"
        or confirmed and "Authenticated"
        or State.activity == "Validating" and (State.restoring and "Restoring saved key" or "Validating")
        or State.authError and "Not authenticated"
        or "Awaiting key"
    t.rows[2].value.Text = State.provider
    t.rows[3].value.Text = not confirmed and "Not authenticated"
        or expired and "Expired"
        or keyless and "Keyless"
        or remaining == nil and "Expiry unavailable"
        or "Valid"
    t.note.Text = State.authError and (State.message or "")
        or "Service status reflects the last verification, not live uptime."
    if
        State.visible
        and (State.route == "Account" or State.route == "Status")
        and remaining
        and remaining > 0
        and remaining < math.huge
    then
        local untilChange = math.max(0.12, remaining % 60 + 0.03)
        Life:later("countdown", math.min(remaining + 0.03, untilChange), function()
            View.account()
            a.copy:enable(
                View.requireIdle()
                    and State.key ~= nil
                    and Auth.remaining() ~= 0
                    and U.cap("setclipboard", "toclipboard", "writeclipboard") ~= nil
            )
        end)
    end
end

-- Settings and the same preference format read by Plak. Only the host reads or
-- writes the saved key in RequireKey mode; JetZKey stores no credential itself.
function Prefs.load()
    local read, exists = U.cap("readfile", "read_file"), U.cap("isfile", "is_file")
    if not read or not exists then
        return
    end
    pcall(function()
        if not exists(PREFS_FILE) then
            return
        end
        local raw = read(PREFS_FILE)
        if type(raw) ~= "string" or #raw > 4096 then
            return
        end
        local data = Services.Http:JSONDecode(raw)
        if type(data) ~= "table" or data.Version ~= 1 then
            return
        end
        Settings.scale = math.clamp(U.number(data.UIScale, 1), 0.85, 1.15)
        if type(data.RememberMe) == "boolean" then
            Settings.remember = data.RememberMe
        end
        if type(data.ReducedMotion) == "boolean" then
            Settings.reduced = data.ReducedMotion
        end
        if type(data.CommunityDismissed) == "boolean" then
            Settings.communityDismissed = data.CommunityDismissed
        end
        if type(data.Language) == "string" then
            Settings.language = U.text(data.Language, 12, "en")
        end
        Prefs.note = "Preferences restored from this device."
    end)
end
function Prefs.save()
    if not Prefs.dirty then
        return true
    end
    if Prefs.saving then
        return false
    end
    local write = U.cap("writefile", "write_file")
    if not write then
        Prefs.note = "Preferences are session-only on this client."
        return false
    end
    Prefs.saving = true
    local saved
    repeat
        local version = Prefs.version
        local ok, result = pcall(function()
            local make, exists = U.cap("makefolder", "make_folder"), U.cap("isfolder", "is_folder")
            if make and (not exists or not exists("PLAK")) then
                pcall(make, "PLAK")
            end
            return write(
                PREFS_FILE,
                Services.Http:JSONEncode({
                    Version = 1,
                    Language = Settings.language,
                    UIScale = Settings.scale,
                    RememberMe = Settings.remember,
                    ReducedMotion = Settings.reduced,
                    CommunityDismissed = Settings.communityDismissed,
                })
            )
        end)
        saved = ok and result ~= false
        Prefs.dirty = not saved or Prefs.version ~= version
        if version == Prefs.version then
            break
        end
    until false
    Prefs.saving = false
    Prefs.note = saved and "Preferences saved on this device." or "Could not save preferences on this device."
    return saved
end
function Prefs.changed(sync)
    Prefs.version = (Prefs.version or 0) + 1
    Prefs.dirty = true
    if sync then
        Life:remove("preferences")
        return Prefs.save()
    end
    Life:later("preferences", 0.20, function()
        Prefs.save()
        if State.alive then
            View.paint()
        end
    end)
    return true
end
function Prefs.available()
    -- These are the exact names read by PlakScript, as distinct from optional
    -- UI preference aliases. Don't promise saving if only the aliases exist.
    return State.callbacks.ForgetKey ~= nil
        and U.cap("readfile") ~= nil
        and U.cap("isfile") ~= nil
        and U.cap("writefile") ~= nil
end
function Prefs.remember(value)
    if not View.requireIdle() then
        return false, "busy"
    end
    if not Prefs.available() then
        return false, "storage_unavailable"
    end
    if Settings.remember == value then
        return true
    end
    -- Serialize opt-out with validation. Persist OFF before calling the host's
    -- removal callback so a prompt restart cannot normally hydrate an old opt-in.
    State.activity = value and "SavingPreferences" or "ForgettingKey"
    Settings.remember = value
    View.paint()
    local saved = Prefs.changed(true)
    local removed = true
    if not value and State.alive then
        local ok, result = U.call(State.callbacks.ForgetKey, Loader)
        removed = ok and result == true
    end
    if not State.alive then
        return false, "destroyed"
    end
    State.activity = "Idle"
    View.paint()
    if not removed then
        Loader:Toast({
            Type = "warning",
            Title = "Saved Key Not Removed",
            Subtitle = "Remember Me is off for this session. Try clearing the saved key again.",
        })
        return false, "delete_failed"
    end
    if not saved then
        Loader:Toast({ Type = "warning", Title = "Preferences Not Saved", Subtitle = Prefs.note })
    end
    return true
end
function View.buildSettings()
    local t = { page = UI.routes.Settings }
    UI.settings = t
    t.heading = View.heading(t.page, "settings", "Settings", "Manage saved keys and interface motion.")
    t.remember = View.check(t.page, "Remember Me", "Use an authenticated key on the next launch.", function()
        Prefs.remember(not Settings.remember)
    end, "Settings Remember Me")
    t.motion = View.check(t.page, "Reduce Motion", "Limit decorative transitions.", function()
        Loader:SetReducedMotion(not Settings.reduced)
    end)
    View.bindBusy(t.motion)
    UI.checks[2] = t.remember
    t.clear = View.bindBusy(
        U.action(t.page, "Clear Saved Key", "erase", false, function()
            Loader:ForgetSavedKey()
        end),
        function()
            return State.callbacks.ForgetKey ~= nil
        end
    )
    t.topRule, t.midRule, t.bottomRule =
        View.lines(t.page, "HeaderDivider"),
        View.lines(t.page, "PreferenceDivider"),
        View.lines(t.page, "ActionDivider")
    t.note = U.label(t.page, "Persistence", "", 11, Theme.muted)
    t.note.TextWrapped = true
    t.note.TextYAlignment = Enum.TextYAlignment.Top
end
function View.layoutSettings(g)
    local t = UI.settings
    local x, right = g.compact and 16 or 67, g.compact and 16 or 47
    local w = math.max(1, g.viewW - x - right)
    local y = g.compact and 10 or 23
    View.placeHeading(t.heading, x, y, w, g.compact, false)
    y += g.compact and 106 or 122
    local h = math.max(50, g.touch and g.hit or 0)
    U.place(t.topRule, x, y, w, 1)
    U.place(t.remember.root, x, y + 1, w, h)
    t.remember:layout(w, h, w < 530)
    y += h + 1
    U.place(t.midRule, x, y, w, 1)
    U.place(t.motion.root, x, y + 1, w, h)
    t.motion:layout(w, h, w < 530)
    y += h + 1
    U.place(t.bottomRule, x, y, w, 1)
    U.place(t.clear.root, x, y + 16, math.min(w, 236), math.max(41, g.touch and g.hit or 0))
    U.place(t.note, x, y + 74, w, 55)
    View.fitScroll(t.page, y + 137)
end

-- Informational catalog. GameId in Games.json is the *place* identifier.
-- GameThumbnail is Roblox's landscape place media; GameIcon takes a universe ID
-- and is deliberately not used here. Only displayed rows enter the preload queue.
Catalog.rows, Catalog.media, Catalog.entries, Catalog.results, Catalog.byPlace = {}, {}, {}, {}, {}
Catalog.status, Catalog.workers, Catalog.revision = "idle", 0, 0
function Catalog.placeId(value)
    local n = U.number(value, 0)
    return n > 0 and n < 9007199254740992 and n == math.floor(n) and n or nil
end
function Catalog.artwork(value, place)
    if type(value) == "number" and Catalog.placeId(value) then
        return "rbxassetid://" .. string.format("%.0f", value)
    end
    if type(value) == "string" and value:match("^rbxassetid://%d+$") then
        return value
    end
    if not place then
        return nil
    end
    return "rbxthumb://type=GameThumbnail&id=" .. string.format("%.0f", place) .. "&w=768&h=432"
end
function Catalog.normalize(array, strict)
    local rows, ids, lookup = {}, {}, {}
    local hadEntries = next(array) ~= nil
    for index, entry in ipairs(array) do
        if type(entry) == "table" then
            local place = Catalog.placeId(entry.GameId or entry.PlaceId)
            local id = U.text(entry.Id or index, 96)
            local name = U.trim(U.text(entry.Name or entry.FallbackName, 180))
            if id ~= "" and name ~= "" and (place or not strict) and not ids[id] and not (place and lookup[place]) then
                local row = {
                    id = id,
                    place = place,
                    name = name,
                    fold = name:lower(),
                    status = U.text(entry.Status, 32),
                    artwork = Catalog.artwork(entry.Artwork, place),
                }
                ids[id] = true
                if place then
                    lookup[place] = row
                end
                rows[#rows + 1] = row
            end
        end
    end
    if strict and hadEntries and #rows == 0 then
        return nil
    end
    return rows, lookup
end
function Catalog.install(rows, lookup)
    local artwork = {}
    for _, row in ipairs(rows) do
        if row.artwork then
            artwork[row.artwork] = true
        end
    end
    Catalog.artworkIds = artwork
    for uri, entry in pairs(Catalog.media) do
        if not artwork[uri] and entry.status ~= "loading" then
            Catalog.media[uri] = nil
        end
    end
    Catalog.entries, Catalog.byPlace, Catalog.status = rows, lookup, "ready"
    Catalog.filter(false)
    Catalog.paintStatus()
end
function Catalog.fetch()
    if not State.alive or Catalog.status == "loading" then
        return
    end
    Catalog.status = "loading"
    Catalog.revision += 1
    local revision = Catalog.revision
    Catalog.paintStatus()
    Life:later("registry-timeout", 14, function()
        if Catalog.revision ~= revision then
            return
        end
        Catalog.revision += 1
        Life:remove("registry")
        Catalog.status, Catalog.reason = "failed", "The game registry request timed out."
        Catalog.paintStatus()
    end)
    -- Do not start catalog HTTP while initializing or block input/validation.
    Life:job("registry", function()
        local ok, raw = pcall(function()
            return game:HttpGet(REGISTRY)
        end)
        if not State.alive or revision ~= Catalog.revision then
            return
        end
        if not ok then
            local adapter = U.cap("request", "http_request", "httpRequest", "httprequest")
            if adapter then
                local requested, response = pcall(adapter, {
                    Url = REGISTRY,
                    Method = "GET",
                    Headers = { Accept = "application/json" },
                    Timeout = 8,
                })
                local code = requested
                        and type(response) == "table"
                        and U.number(response.StatusCode or response.Status or response.status_code, 0)
                    or 0
                ok = code >= 200 and code < 300
                raw = ok and (response.Body or response.body) or nil
            end
        end
        if not State.alive or revision ~= Catalog.revision then
            return
        end
        Life:remove("registry-timeout")
        if ok and type(raw) == "string" and #raw <= 1048576 and raw:match("^%s*%[") then
            local parsed, array = pcall(Services.Http.JSONDecode, Services.Http, raw)
            if parsed and type(array) == "table" then
                local rows, lookup = Catalog.normalize(array, true)
                if rows and (#rows > 0 or raw:match("^%s*%[%s*%]%s*$")) then
                    Catalog.install(rows, lookup)
                    return
                end
            end
        end
        if ok then
            Catalog.reason = "The game registry returned invalid data."
        else
            Catalog.reason = "The game registry could not be reached."
        end
        Catalog.status = "failed"
        Catalog.paintStatus()
    end)
end
function Catalog.rowState(row)
    local item = row.item
    local media = item and item.artwork and Catalog.media[item.artwork]
    local decoded = media and media.status == "ready"
    local uri = decoded and item.artwork or ""
    if row.image.Image ~= uri then
        row.image.Image = uri
    end
    row.image.Visible = decoded == true
    local ready = decoded and row.image.IsLoaded
    row.placeholder.Visible = not ready
    local missing = not item
        or not item.artwork
        or (media and (media.status == "failed" or media.timedOut))
        or row.displayTimedOut
    row.placeholder.Text = missing and "Thumbnail unavailable" or "Loading thumbnail…"
    if ready or missing or not decoded then
        Life:remove(row)
    elseif not Life.items[row] then
        Life:later(row, 7, function()
            row.displayTimedOut = true
            Catalog.rowState(row)
        end)
    end
end
function Catalog.mediaDone(uri, entry, ready)
    if not State.alive or Catalog.media[uri] ~= entry or entry.status ~= "loading" then
        return
    end
    Life:remove(entry)
    Life:remove(entry.timeout)
    Catalog.workers -= 1
    entry.status, entry.retryAt, entry.timedOut = ready and "ready" or "failed", os.clock() + 30, nil
    if not Catalog.artworkIds[uri] then
        Catalog.media[uri] = nil
    end
    for _, card in ipairs(Catalog.rows) do
        if card.item and card.item.artwork == uri then
            Catalog.rowState(card)
        end
    end
    Catalog.pump()
end
function Catalog.pump()
    if not State.alive or not State.visible or State.route ~= "Games" then
        return
    end
    for _, row in ipairs(Catalog.rows) do
        if Catalog.workers >= 3 then
            break
        end
        local uri = row.item and row.item.artwork
        local prev = uri and Catalog.media[uri]
        if uri and (not prev or (prev.status == "failed" and os.clock() >= prev.retryAt)) then
            local entry = { status = "loading", timeout = {} }
            Catalog.media[uri] = entry
            Catalog.workers += 1
            Life:later(entry.timeout, 12, function()
                -- Let the UI settle while retaining the native request's slot.
                -- PreloadAsync may still finish; never refill a slot early.
                entry.timedOut = true
                for _, card in ipairs(Catalog.rows) do
                    if card.item and card.item.artwork == uri then
                        Catalog.rowState(card)
                    end
                end
            end)
            Life:job(entry, function()
                local outcome
                local ok = pcall(Services.Media.PreloadAsync, Services.Media, { uri }, function(_, result)
                    outcome = result
                end)
                if not State.alive or entry.status ~= "loading" then
                    return
                end
                if not outcome and ok then
                    local checked, result = pcall(Services.Media.GetAssetFetchStatus, Services.Media, uri)
                    if checked then
                        outcome = result
                    end
                end
                Catalog.mediaDone(uri, entry, ok and outcome == Enum.AssetFetchStatus.Success)
            end)
        end
    end
end
function Catalog.newRow()
    local card = { root = U.fill(UI.games.list, "GameCard", Theme.field) }
    U.corner(card.root, 9)
    U.border(card.root, C(53, 49, 58), 0.16)
    card.art = U.fill(card.root, "Thumbnail", Theme.surface)
    U.corner(card.art, 7)
    card.art.ClipsDescendants = true
    card.image = U.make("ImageLabel", card.art, "Landscape", {
        ScaleType = Enum.ScaleType.Crop,
        Size = S(1, 1),
        Image = "",
        Visible = false,
    })
    U.corner(card.image, 7)
    card.placeholder = U.middle(card.art, "ThumbnailState", "", 10, Theme.muted, "medium")
    card.placeholder.Size = UDim2.new(1, -10, 1, 0)
    card.placeholder.Position = O(5, 0)
    card.placeholder.TextWrapped = true
    card.div = U.fill(card.root, "MediaDivider", C(73, 70, 80))
    card.label = U.label(card.root, "Supported Game", "Supported Game", 10, Theme.secondary, "medium")
    card.title = U.label(card.root, "GameName", "", 17, Theme.ink, "bold")
    card.title.TextWrapped = true
    Life:connect(card.image:GetPropertyChangedSignal("IsLoaded"), function()
        if card.item then
            Catalog.rowState(card)
        end
    end)
    return card
end
function Catalog.placeRow(row, index)
    local g = UI.games
    local w, h = g.width - 9, g.rowHeight
    local art = math.floor(w * (State.geometry.compact and 0.42 or 0.477))
    local labelX = art + (State.geometry.compact and 25 or 33)
    U.place(row.root, 2, 3 + (index - 1) * (h + g.gap), w - 2, h)
    U.place(row.art, 2, 2, art, h - 4)
    U.place(row.div, art + 16, 11, 1, h - 22)
    U.place(row.label, labelX, 9, w - labelX - 10, 17)
    row.title.TextSize = State.geometry.compact and 13 or 17
    U.place(row.title, labelX, 24, w - labelX - 10, h - 28)
end
function Catalog.render()
    if not State.alive or not State.visible or State.route ~= "Games" or not UI.games.height then
        return
    end
    local g, all = UI.games, Catalog.results
    local unit, scale = g.rowHeight + g.gap, State.geometry.scale
    local height = #all == 0 and (g.empty.Parent == g.list and 113 or 0) or #all * unit - g.gap + 7
    View.fitScroll(g.list, height)
    local first = math.max(1, math.floor(g.list.CanvasPosition.Y / (unit * scale)))
    local bound = math.min(#all, first + math.ceil(g.height / unit) + 3)
    local slots = math.max(0, bound - first + 1)
    for i = 1, slots do
        local index = first + i - 1
        local row = Catalog.rows[i]
        if not row then
            row = Catalog.newRow()
            Catalog.rows[i] = row
        end
        local item = all[index]
        if row.item ~= item then
            Life:remove(row)
            row.item, row.displayTimedOut = item, false
            row.title.Text = item.name
            row.root:SetAttribute("GameId", item.place)
            row.root:SetAttribute("GameName", item.name)
            Catalog.rowState(row)
        end
        row.root.Visible = true
        Catalog.placeRow(row, index)
    end
    for i = slots + 1, #Catalog.rows do
        local row = Catalog.rows[i]
        Life:remove(row)
        row.item, row.root.Visible = nil, false
        row.image.Image = ""
    end
    g.track.Visible = height > g.height
    local range = math.max(1, height - g.height)
    local length = math.min(g.height, math.max(24, g.height * g.height / math.max(1, height)))
    local distance = math.max(0, g.height - length)
    U.place(g.handle, 0, math.clamp(g.list.CanvasPosition.Y / (scale * range), 0, 1) * distance, 4, length)
    Catalog.pump()
end
function Catalog.filter(reset)
    local query = U.trim(UI.games.search.box.Text):lower()
    local results = {}
    for _, item in ipairs(Catalog.entries) do
        if query == "" or item.fold:find(query, 1, true) then
            results[#results + 1] = item
        end
    end
    Catalog.results = results
    if reset then
        UI.games.list.CanvasPosition = V(0, 0)
    end
    Catalog.paintStatus()
    Catalog.render()
end
function Catalog.paintStatus()
    local status = Catalog.status
    local ui = UI.games
    if not ui then
        return
    end
    local message = status == "idle" or status == "loading"
    ui.empty.Visible = status ~= "ready" or #Catalog.results == 0
    ui.retry.root.Visible = status == "failed"
    ui.emptyTitle.Text = message and "Loading games…"
        or status == "failed" and "Catalog unavailable"
        or #Catalog.entries == 0 and "No supported games listed"
        or "No matching games"
    ui.emptyText.Text = message and "Reading the Plak game registry."
        or status == "failed" and (Catalog.reason or "Couldn't load the game registry.")
        or #Catalog.entries == 0 and "The registry is currently empty."
        or "Try a different search."
    if UI.status then
        local entry = Catalog.byPlace[game.PlaceId]
        UI.status.rows[4].value.Text = status ~= "ready" and "Not confirmed"
            or entry and (entry.status == "Available" and "Supported" or (entry.status ~= "" and entry.status or "Listed"))
            or "Not listed"
        UI.status.rows[5].value.Text = message and "Loading"
            or status == "failed" and "Unavailable"
            or #Catalog.entries == 0 and "Empty"
            or tostring(#Catalog.entries) .. " games loaded"
    end
end
function View.buildGames()
    local g = { page = UI.routes.Games }
    UI.games = g
    g.heading = View.heading(g.page, "games", "Supported Games", "Games currently supported by Plak.")
    g.search = View.input(g.page, "Search", "Search game...", "search", false)
    g.list = U.scroll(g.page, "GamesList")
    g.list.ScrollBarImageTransparency = 1
    g.track = U.fill(g.page, "ScrollTrack", Theme.surface)
    U.corner(g.track, 4)
    g.handle = U.fill(g.track, "ScrollThumb", Theme.coral)
    U.corner(g.handle, 4)
    g.empty = U.fill(g.page, "CatalogState", Theme.surface)
    U.corner(g.empty, 8)
    U.border(g.empty, Theme.border, 0.32)
    g.emptyTitle = U.middle(g.empty, "Title", "", 14, Theme.ink, "bold")
    g.emptyText = U.middle(g.empty, "Detail", "", 11, Theme.muted)
    g.emptyText.TextWrapped = true
    g.retry = View.bindBusy(U.action(g.empty, "Retry Catalog", "refresh", false, Catalog.fetch))
    Life:connect(g.list:GetPropertyChangedSignal("CanvasPosition"), function()
        Life:later("game-rows", 0, Catalog.render)
    end)
    Life:connect(g.search.box:GetPropertyChangedSignal("Text"), function()
        Catalog.filter(true)
    end)
end
function View.layoutGames(geometry)
    local g = UI.games
    local pad = geometry.compact and 12 or 21
    local width = math.max(1, geometry.viewW - 2 * pad)
    local tight = geometry.viewH < 305
    local tiny = geometry.viewH < 177
    g.heading.root.Visible = not tiny
    View.placeHeading(g.heading, pad, tight and 0 or 1, width, geometry.compact, tight)
    local searchY = tiny and 4 or tight and 81 or 103
    local h = math.max(33, geometry.touch and geometry.hit or 0)
    U.place(g.search.root, pad + 3, searchY, width - 9, h)
    local listY = searchY + h + (geometry.compact and 11 or 14)
    local listH = math.max(10, geometry.viewH - listY - 11)
    g.width, g.height, g.rowHeight, g.gap = width, listH, geometry.compact and 66 or 64, 9
    U.place(g.list, pad, listY, width, listH)
    U.place(g.track, geometry.viewW - pad + 4, listY, 4, listH)
    U.place(g.empty, pad + 2, listY + 2, width - 9, math.min(140, math.max(listH - 4, 96)))
    -- Use the same scroller for compact empty/error states so Retry stays reachable.
    local showCompact = listH < 94
    if showCompact then
        local wasParent = g.empty.Parent == g.list
        if not wasParent then
            g.empty.Parent = g.list
        end
        U.place(g.empty, 2, 2, width - 12, 108)
    elseif g.empty.Parent ~= g.page then
        g.empty.Parent = g.page
    end
    U.place(g.emptyTitle, 6, 8, width - 22, 24)
    U.place(g.emptyText, 9, 32, width - 28, 28)
    U.place(g.retry.root, ((width - 9) - 147) / 2, 64, 147, 35)
    Catalog.render()
end

-- Community and license offerings -------------------------------------------
function View.link(url, copiedTitle)
    local write = U.cap("setclipboard", "toclipboard", "writeclipboard")
    local ok, result = U.call(write, url)
    if not State.alive then
        return false
    end
    if ok and result ~= false then
        Loader:Toast({ Type = "success", Title = copiedTitle, Subtitle = "Copied to your clipboard." })
        return true
    end
    FX.modal({
        Type = "info",
        Title = "Copy this link",
        Description = "Clipboard access is unavailable.",
        CopyText = url,
    })
    return false
end
function View.aboutCard(parent, name, glyph, callback)
    local c = { group = U.make("CanvasGroup", parent, name, { GroupTransparency = 0 }) }
    c.button = View.bindBusy(U.button(c.group, name, callback))
    c.button.root.Size = S(1, 1)
    c.panel = c.button.root
    c.panel.BackgroundColor3, c.panel.BackgroundTransparency = Theme.field, 0
    U.corner(c.panel, 8)
    c.edge = U.border(c.panel, Theme.accent, 0.72)
    c.tint = U.gradient(c.panel, Color3.new(1, 1, 1), C(154, 136, 154), 10)
    local iconSize = glyph == "discord" and 37 or 32
    c.icon, c.ink = U.icon(c.panel, glyph, iconSize, Theme.coral)
    c.iconSize = iconSize
    c.title = U.label(c.panel, "Title", name, 17, Theme.ink, "bold")
    c.detail = U.label(c.panel, "Description", "", 12, Theme.secondary)
    c.flash = U.make("Frame", c.group, "Highlight", { Size = UDim2.new(1, -2, 1, -2), Position = O(1, 1), ZIndex = 2 })
    U.corner(c.flash, 8)
    c.glow = U.border(c.flash, Theme.coral, 1, 2)
    c.halo = U.border(c.flash, Theme.coral, 1, 6)
    c.sweep = U.fill(c.panel, "AccentSweep", Theme.coral, {
        Position = O(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 1,
    })
    c.sweep.BackgroundTransparency = 1
    U.corner(c.sweep, 7)
    c.sweepTone = U.gradient(c.sweep, Color3.new(1, 1, 1), Color3.new(1, 1, 1), glyph == "discord" and 0 or 22)
    c.sweepTone.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.36, 0.98),
        NumberSequenceKeypoint.new(0.50, 0.26),
        NumberSequenceKeypoint.new(0.76, 1),
        NumberSequenceKeypoint.new(1, 1),
    })
    -- Move the tint under the content, not over the text or hit target.
    for _, obj in ipairs({ c.icon, c.title, c.detail }) do
        obj.ZIndex = 3
    end
    function c.button:paint()
        local color = self.down and Theme.pressed or self.hover and C(46, 29, 36) or c.base
        c.panel.BackgroundColor3 = color or Theme.field
        c.edge.Transparency = self.hover and 0.12 or c.restEdge or 0.56
    end
    return c
end
function View.purchase()
    View.link(Settings.store or DISCORD, Settings.store and "Store Link Copied" or "Discord Link Copied")
end
function View.buildAbout()
    local a = { page = UI.routes.About, cards = {} }
    UI.about = a
    a.heading = View.heading(a.page, "brandPair", "About Plak", "Script hub for Roblox games.")
    a.discord = View.aboutCard(a.page, "Join our Discord", "discord", function()
        if State.callbacks.Social then
            U.call(State.callbacks.Social, "discord", Loader)
        else
            View.link(Settings.communityLink or DISCORD, "Discord Link Copied")
        end
    end)
    a.discord.base, a.discord.restEdge = C(34, 23, 28), 0.30
    a.discord.detail.Text = "Get updates, scripts and support."
    a.discord.url = U.label(a.discord.panel, "Invite", DISCORD, 11, C(243, 158, 169), "medium")
    a.discord.external = U.icon(a.discord.panel, "external", 25, C(254, 195, 204))
    a.discord.external.ZIndex = 3
    a.discord.url.ZIndex = 3
    a.lifetime = View.aboutCard(a.page, "Lifetime Key", "crown", View.purchase)
    a.lifetime.base, a.lifetime.restEdge = C(39, 24, 32), 0.38
    a.lifetime.detail.Text = "One-time purchase"
    a.lifetime.foot = U.label(a.lifetime.panel, "Term", "Lifetime access", 11, Theme.secondary)
    a.lifetime.footIcon = U.icon(a.lifetime.panel, "infinity", 14, Theme.coral)
    a.monthly = View.aboutCard(a.page, "Monthly Key", "calendar", View.purchase)
    a.monthly.base, a.monthly.restEdge = C(37, 26, 33), 0.43
    a.monthly.detail.Text = "Monthly license"
    a.monthly.foot = U.label(a.monthly.panel, "Term", "Monthly access", 11, Theme.secondary)
    a.monthly.footIcon = U.icon(a.monthly.panel, "calendar", 14, Theme.coral)
    a.cards = { a.discord, a.lifetime, a.monthly }
    for _, c in ipairs(a.cards) do
        c.button:paint()
        if c.foot then
            c.foot.ZIndex, c.footIcon.ZIndex = 3, 3
        end
    end
    a.discord.ink(C(249, 181, 194))
end
function View.layoutAbout(g)
    local a = UI.about
    local x, right = g.compact and 16 or 43, g.compact and 16 or 43
    local width = math.max(1, g.viewW - x - right)
    local compact = g.compact or g.viewH < 350
    local tallTop = compact and 14 or 36
    View.placeHeading(a.heading, x, tallTop, width, compact, false)
    if not compact then
        U.place(a.heading.tile, (width - 60) / 2, 0, 60, 60)
        a.heading.title.TextSize, a.heading.detail.TextSize = 26, 14
        U.place(a.heading.title, 0, 63, width, 34)
        U.place(a.heading.detail, 0, 98, width, 20)
    end
    local y = compact and 122 or 194
    local discordH = compact and 85 or 96
    local left = compact and 14 or 22
    local discord = a.discord
    discord.group.Visible = Settings.community and not Settings.communityDismissed
    if discord.group.Visible then
        U.place(discord.group, x, y, width, discordH)
        discord.rest = O(x, y)
        U.place(discord.icon, left, (discordH - discord.iconSize) / 2, discord.iconSize, discord.iconSize)
        local textX = left + 48
        discord.title.TextSize, discord.detail.TextSize = compact and 15 or 17, compact and 11 or 12
        U.place(discord.title, textX, compact and 9 or 16, width - textX - 44, 25)
        U.place(discord.detail, textX, compact and 33 or 43, width - textX - 44, 18)
        U.place(discord.url, textX, compact and 55 or 64, width - textX - 42, 17)
        U.place(discord.external, width - 41, (discordH - 25) / 2, 25, 25)
        discord.url.Text = Settings.communityLink or DISCORD
        y += discordH + 15
    end
    a.lifetime.group.Visible, a.monthly.group.Visible = Settings.offer, Settings.offer
    local columns = width >= 458
    local cardH = compact and 87 or 112
    local cardW = columns and math.floor((width - 17) / 2) or width
    if Settings.offer then
        for i, c in ipairs({ a.lifetime, a.monthly }) do
            local cx = x + (columns and (i - 1) * (cardW + 17) or 0)
            local cy = y + (columns and 0 or (i - 1) * (cardH + 12))
            c.rest = O(cx, cy)
            U.place(c.group, cx, cy, cardW, cardH)
            U.place(c.icon, left, compact and 15 or 23, c.iconSize, c.iconSize)
            c.title.TextSize, c.detail.TextSize = compact and 15 or 17, compact and 11 or 12
            local textX = left + 48
            U.place(c.title, textX, compact and 10 or 15, cardW - textX - 7, 24)
            U.place(c.detail, textX, compact and 35 or 41, cardW - textX - 7, 19)
            U.place(c.footIcon, left + 18, cardH - 29, 14, 14)
            U.place(c.foot, textX, cardH - 35, cardW - textX - 7, 26)
        end
        y += columns and cardH or 2 * cardH + 12
    end
    View.fitScroll(a.page, y + 19)
end

function FX.stopAbout()
    if FX.about then
        FX.about:destroy()
        FX.about = nil
    end
    if not UI.about or not UI.about.cards then
        return
    end
    for _, c in ipairs(UI.about.cards) do
        c.group.GroupTransparency = 0
        if c.rest then
            c.group.Position = c.rest
        end
        c.glow.Transparency, c.halo.Transparency, c.sweep.BackgroundTransparency = 1, 1, 1
    end
end
function FX.enterAbout()
    FX.stopAbout()
    if Settings.reduced or not State.visible then
        return
    end
    local scope = Scope.new()
    FX.about = scope
    for index, c in ipairs(UI.about.cards) do
        if c.group.Visible and c.rest then
            c.group.GroupTransparency = 0.50
            c.group.Position = c.rest + O(0, 7)
            local entrance = ({ 0, 0.22, 0.40 })[index]
            local emphasis = ({ 0.22, 0.64, 1.07 })[index]
            scope:later("enter" .. index, entrance, function()
                U.tween(
                    scope,
                    c.group,
                    c.group,
                    0.23,
                    { GroupTransparency = 0, Position = c.rest },
                    Enum.EasingStyle.Quart
                )
            end)
            scope:later("flash" .. index, emphasis, function()
                c.sweepTone.Offset = V(-0.44, 0)
                U.tween(scope, c.glow, c.glow, 0.15, { Transparency = 0.28 })
                U.tween(scope, c.halo, c.halo, 0.20, { Transparency = 0.82 })
                U.tween(scope, c.sweep, c.sweep, 0.17, { BackgroundTransparency = 0.78 })
                U.tween(scope, c.sweepTone, c.sweepTone, 0.61, { Offset = V(0.47, 0) }, Enum.EasingStyle.Sine)
                scope:later("settle" .. index, 0.25, function()
                    U.tween(scope, c.glow, c.glow, 0.39, { Transparency = 1 })
                    U.tween(scope, c.halo, c.halo, 0.39, { Transparency = 1 })
                    U.tween(scope, c.sweep, c.sweep, 0.36, { BackgroundTransparency = 1 })
                end)
            end)
        end
    end
end

-- Scoped native validation scene, host dialogs and filtered notification stack
FX.toasts = {}
function FX.build()
    UI.toastLayer = U.make("Frame", UI.shell, "Notifications", { Size = S(1, 1), ZIndex = 33 })
    UI.shade = U.make("TextButton", UI.shell, "ValidationOverlay", {
        Size = S(1, 1),
        Text = "",
        AutoButtonColor = false,
        Active = true,
        Modal = true,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 28,
    })
    local f = {}
    UI.validation = f
    f.panel = U.make("CanvasGroup", UI.shade, "ValidationPanel", {
        AnchorPoint = V(0.5, 0.5),
        Position = S(0.5, 0.5),
        GroupTransparency = 1,
        BackgroundColor3 = C(19, 18, 23),
        BackgroundTransparency = 0,
    })
    U.corner(f.panel, 11)
    U.border(f.panel, Theme.border, 0.32)
    f.art = U.make(
        "Frame",
        f.panel,
        "FeedbackGlyph",
        { AnchorPoint = V(0.5, 0), Position = UDim2.new(0.5, 0, 0, 20), Size = O(64, 64) }
    )
    local circle = U.make("Frame", f.art, "Ring", { Position = O(5, 5), Size = O(54, 54) })
    U.corner(circle, 50)
    f.ring = U.border(circle, C(52, 45, 55), 0, 2.15)
    f.glow = U.border(circle, Theme.coral, 1, 8)
    local halo = U.make("Frame", f.art, "SoftHalo", { Position = O(3, 3), Size = O(58, 58) })
    U.corner(halo, 50)
    f.halo = U.border(halo, Theme.coral, 1, 11)
    f.arc = U.make("Frame", f.art, "Spinner", { Size = S(1, 1) })
    for i = 0, 23 do
        local a = (i / 36) * math.pi * 2 - math.pi / 2
        local segment = U.fill(f.arc, "ArcSegment", Theme.coral, {
            AnchorPoint = V(0.5, 0.5),
            Rotation = math.deg(a) + 90,
        })
        U.place(segment, 32 + math.cos(a) * 27, 32 + math.sin(a) * 27, 5.5, 2.15)
        segment.BackgroundTransparency = 0.72 * (1 - i / 23) ^ 2
        U.corner(segment, 3)
    end
    f.check = U.centerIcon(f.art, "check", 32, Theme.coral)
    f.cross = U.centerIcon(f.art, "x", 28, Theme.error)
    f.checkScale = U.make("UIScale", f.check, "CheckScale", { Scale = 0.62 })
    f.title = U.middle(f.panel, "Title", "Validating...", 15, Theme.ink, "bold")
    f.title.Position, f.title.Size = UDim2.new(0, 5, 1, -40), UDim2.new(1, -10, 0, 27)
end
function FX.layout()
    local g = State.geometry
    local width = math.min(222, g.width - 24)
    local height = math.min(143, g.height - 18)
    UI.validation.panel.Size = O(width, height)
    UI.validation.art.Position = UDim2.new(0.5, 0, 0, height < 130 and 9 or 21)
    if FX.dialog then
        FX.layoutDialog()
    end
    FX.stack(false)
end
function FX.overlayPresent()
    local f = UI.validation
    local scope = FX.validation
    if not scope or scope.dead then
        return
    end
    if not UI.shade.Visible then
        UI.shade.Visible = true
        U.tween(scope, "dim", UI.shade, 0.15, { BackgroundTransparency = 0.47 })
        U.tween(
            scope,
            "panel",
            f.panel,
            0.19,
            { GroupTransparency = 0, Position = S(0.5, 0.5) },
            Enum.EasingStyle.Quart
        )
    end
end
function FX.begin()
    if FX.validation then
        FX.validation:destroy()
    end
    local scope = Scope.new()
    FX.validation = scope
    local f = UI.validation
    f.title.Text = "Validating..."
    f.panel.GroupTransparency, f.panel.Position = 1, S(0.5, 0.53)
    f.arc.Rotation = 0
    f.arc.Visible, f.check.Visible, f.cross.Visible = true, false, false
    f.ring.Color, f.glow.Transparency, f.halo.Transparency = C(52, 45, 55), 1, 1
    UI.shade.BackgroundTransparency = 1
    scope:later("introduce", Settings.reduced and 0 or 0.12, function()
        FX.overlayPresent()
        FX.spin()
    end)
end
function FX.spin()
    local scope = FX.validation
    if not scope or State.activity ~= "Validating" then
        return
    end
    local arc = UI.validation.arc
    arc.Rotation = 0
    U.tween(scope, "spinner", arc, 1.02, { Rotation = 360 }, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
end
function FX.settle(success, title)
    local scope, f = FX.validation, UI.validation
    if not scope then
        FX.begin()
        scope = FX.validation
    end
    scope:remove("introduce")
    scope:remove("spinner")
    FX.overlayPresent()
    f.arc.Visible = false
    f.title.Text = success and "Validated!" or title
    f.check.Visible, f.cross.Visible = success, not success
    local color = success and Theme.coral or Theme.error
    local easing = Enum.EasingStyle.Quad
    U.tween(scope, "finish-ring", f.ring, 0.16, { Color = color }, easing)
    f.glow.Color, f.halo.Color = color, color
    U.tween(scope, "finish-glow", f.glow, 0.20, { Transparency = success and 0.76 or 0.9 })
    U.tween(scope, "finish-halo", f.halo, 0.24, { Transparency = success and 0.91 or 0.97 })
    if success then
        f.checkScale.Scale = 0.66
        U.tween(scope, "check", f.checkScale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
    end
end
function FX.fade()
    local scope = FX.validation
    if not scope then
        return
    end
    U.tween(scope, "dim", UI.shade, 0.15, { BackgroundTransparency = 1 })
    U.tween(scope, "panel", UI.validation.panel, 0.15, { GroupTransparency = 1, Position = S(0.5, 0.51) })
end
function FX.closeValidation()
    if FX.validation then
        FX.validation:destroy()
        FX.validation = nil
    end
    if UI.shade then
        UI.shade.Visible = false
    end
end

function FX.stack(animate)
    if not State.geometry then
        return
    end
    local g = State.geometry
    local width = math.max(1, math.min(g.width - g.hit - 15, 244))
    for i, item in ipairs(FX.toasts) do
        local panel = item.root
        local edge = math.max(8, math.floor(g.hit / 2))
        panel.Size = O(width, 55)
        local pos = UDim2.new(1, -g.hit - 3, 0, edge + (i - 1) * 61)
        if not item.closing then
            U.tween(item.scope, "stack", panel, animate and 0.16 or 0, { Position = pos })
        end
    end
end
function FX.removeToast(item, instant)
    if item.closing and not instant then
        return
    end
    local function dispose()
        local i = table.find(FX.toasts, item)
        if i then
            table.remove(FX.toasts, i)
        end
        item.scope:destroy()
        item.root:Destroy()
        FX.stack(not instant)
    end
    if Settings.reduced or instant then
        dispose()
        return
    end
    item.closing = true
    item.scope:remove("stack")
    U.tween(
        item.scope,
        "fade",
        item.root,
        0.14,
        { GroupTransparency = 1, Position = item.root.Position + O(12, 0) },
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.In
    )
    item.scope:later("remove", 0.15, dispose)
end
function FX.toast(config)
    local style = config.Type
    local title = U.text(config.Title, 60, style == "error" and "Error" or style == "success" and "Success" or "Plak")
    local detail = U.text(config.Subtitle or config.Description, 180)
    for _, item in ipairs(FX.toasts) do
        if item.title == title and item.detail == detail and not item.closing then
            return
        end
    end
    if #FX.toasts >= 3 then
        FX.removeToast(FX.toasts[#FX.toasts], true)
    end
    local foreground = style == "success" and Theme.green
        or style == "error" and Theme.error
        or style == "warning" and Theme.amber
        or Theme.coral
    local group = U.make("CanvasGroup", UI.toastLayer, "Notification", {
        AnchorPoint = V(1, 0),
        BackgroundColor3 = style == "success" and C(17, 30, 24) or C(20, 18, 23),
        BackgroundTransparency = 0,
        GroupTransparency = 1,
        Position = UDim2.new(1, 12, 0, 10),
    })
    U.corner(group, 7)
    U.border(group, foreground, 0.24)
    local glyph = Paths[config.Icon] and config.Icon
        or style == "success" and "check"
        or style == "error" and "x"
        or "info"
    local size = 17
    U.place(U.icon(group, glyph, size, foreground), 14, 17, size, size)
    local heading = U.label(group, "Title", title, 12, foreground, "bold")
    heading.Position, heading.Size = O(40, 5), UDim2.new(1, -49, 0, 20)
    local text = U.label(group, "Detail", detail, 10, Theme.secondary)
    text.Position, text.Size = O(40, 25), UDim2.new(1, -49, 0, 26)
    text.TextYAlignment, text.TextWrapped = Enum.TextYAlignment.Top, true
    local item = { root = group, scope = Scope.new(), title = title, detail = detail }
    table.insert(FX.toasts, 1, item)
    FX.stack(true)
    U.tween(item.scope, "fade", group, 0.18, { GroupTransparency = 0 }, Enum.EasingStyle.Quart)
    item.scope:later("duration", math.clamp(U.number(config.Duration, 3), 0.25, 30), function()
        FX.removeToast(item, false)
    end)
end
function FX.clearToasts()
    for i = #FX.toasts, 1, -1 do
        FX.removeToast(FX.toasts[i], true)
    end
end

function FX.layoutDialog()
    local d, g = FX.dialog, State.geometry
    local w = math.min(g.width - 20, 388)
    local h = math.min(g.height - 20, d.copy and 178 or d.progress and 113 or 144)
    d.panel.Size = O(w, h)
    d.title.Position, d.title.Size = O(12, 7), O(w - 24, 25)
    d.message.Position, d.message.Size = O(12, 32), O(w - 24, d.copy and math.max(18, h - 117) or math.max(22, h - 78))
    if d.copy then
        U.place(d.copy, 11, h - 84, w - 22, 32)
    end
    if d.action then
        U.place(d.action.root, 12, h - 43, w - 24, 35)
    end
    if d.track then
        U.place(d.track, 15, h - 35, w - 30, 5)
    end
end
function FX.closeDialog()
    local d = FX.dialog
    if not d then
        return
    end
    FX.dialog = nil
    State.modal = nil
    d.scope:destroy()
    d.shade:Destroy()
    if State.alive then
        View.paint()
    end
end
function FX.modal(config, progress)
    if not State.alive or State.activity ~= "Idle" then
        return nil
    end
    FX.closeDialog()
    View.releaseFocus()
    View.setDrawer(false)
    local d = { scope = Scope.new(), progress = progress == true }
    FX.dialog = d
    State.modal = progress and "progress" or "result"
    d.shade = U.make("TextButton", UI.shell, "DialogOverlay", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.46,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        Modal = true,
        Size = S(1, 1),
        ZIndex = 25,
    })
    d.panel = U.make("CanvasGroup", d.shade, "Dialog", {
        Position = S(0.5, 0.5),
        AnchorPoint = V(0.5, 0.5),
        BackgroundColor3 = Theme.raised,
        BackgroundTransparency = 0,
        GroupTransparency = 1,
    })
    U.corner(d.panel, 8)
    U.border(d.panel, Theme.border, 0.24)
    d.title =
        U.middle(d.panel, "Title", U.text(config.Title, 70, progress and "Working…" or "Plak"), 15, Theme.ink, "bold")
    d.message = U.middle(d.panel, "Detail", U.text(config.Description or config.Text, 360), 12, Theme.secondary)
    d.message.TextWrapped = true
    if type(config.CopyText) == "string" then
        d.copy = U.make("TextBox", d.panel, "Link", {
            BackgroundColor3 = Theme.field,
            BackgroundTransparency = 0,
            Text = U.text(config.CopyText, 2048),
            FontFace = Regular,
            TextSize = 11,
            TextColor3 = Theme.ink,
            TextEditable = false,
            ClearTextOnFocus = false,
            Selectable = true,
            Active = true,
        })
        U.corner(d.copy, 5)
        U.border(d.copy, Theme.border)
    end
    if progress then
        d.track = U.fill(d.panel, "Track", Theme.field)
        U.corner(d.track, 3)
        d.fill = U.fill(d.track, "Progress", Theme.coral)
        U.corner(d.fill, 3)
    else
        d.action = U.action(d.panel, U.text(config.ActionText or config.Action, 40, "Close"), "check", false, function()
            FX.closeDialog()
            U.call(type(config.OnAction) == "function" and config.OnAction or nil, Loader)
        end, d.scope)
    end
    local handle = {}
    function handle:SetText(text)
        if FX.dialog == d then
            d.message.Text = U.text(text, 360)
        end
        return self
    end
    function handle:SetProgress(value)
        if FX.dialog == d and d.fill then
            State.progress = math.clamp(U.number(value, State.progress), 0, 1)
            U.tween(d.scope, "progress", d.fill, 0.18, { Size = S(State.progress, 1) })
        end
        return self
    end
    function handle:Complete(result)
        if FX.dialog == d then
            result = type(result) == "table" and result or { Type = "success", Title = "Complete" }
            if result.Type == "error" or result.Type == "disabled" then
                FX.modal(result)
            else
                self:SetProgress(1)
                d.scope:later("complete", Settings.reduced and 0 or 0.20, function()
                    FX.modal(result)
                end)
            end
        end
        return self
    end
    function handle:Close()
        if FX.dialog == d then
            FX.closeDialog()
        end
    end
    d.handle = handle
    if progress then
        handle:SetProgress(config.Progress or 0)
    end
    FX.layoutDialog()
    View.paint()
    U.tween(d.scope, "entrance", d.panel, 0.16, { GroupTransparency = 0 })
    return handle
end

-- One owner for validation. Metadata is only a display snapshot. Host approval
-- is separate from SetAuthInfo, SetExpiry, and every visual state change.
local Tier = { free = true, premium = true, keyless = true }
local function importSeconds(info, seconds)
    local n = seconds == math.huge and math.huge or U.number(seconds, nil)
    if not n or n < 0 then
        info.seconds, info.deadline, info.untilUnix = nil, nil, nil
    elseif n == math.huge then
        info.seconds, info.deadline, info.untilUnix = n, nil, nil
    else
        info.seconds, info.deadline, info.untilUnix = n, os.clock() + n, U.now() + n
    end
end
function Auth.setInfo(info)
    local target = State.refresh or State
    local imported
    if type(info) == "table" then
        local tier = info.tier or info.keyTier
        imported = { tier = Tier[tier] and tier or nil }
        importSeconds(imported, info.secondsLeft)
    end
    target.info = imported
    if State.refresh then
        target.changed = imported ~= nil
    end
    if UI.account and not State.refresh then
        View.paint()
    end
end
function Auth.setExpiry(seconds)
    local target = State.refresh or State
    target.expiry = seconds == math.huge and math.huge or math.max(0, U.number(seconds, 0))
    if seconds == math.huge or U.number(seconds, nil) ~= nil then
        target.info = target.info or {}
        importSeconds(target.info, seconds)
        if State.refresh then
            target.changed = true
        end
    end
    if UI.account and not State.refresh then
        View.paint()
    end
end
function Auth.refreshNow()
    if not View.requireIdle() or not State.authorized or not State.callbacks.Refresh then
        return
    end
    local transaction = {
        info = State.info and table.clone(State.info),
        expiry = State.expiry,
        changed = false,
    }
    State.refresh, State.activity = transaction, "Refreshing"
    local callback = State.callbacks.Refresh
    View.paint()
    task.defer(function()
        if not State.alive or State.refresh ~= transaction then
            return
        end
        local ok, result = pcall(callback, Loader)
        if not State.alive or State.refresh ~= transaction then
            return
        end
        State.refresh, State.activity = nil, "Idle"
        if ok and result ~= false and transaction.changed then
            State.info, State.expiry = transaction.info, transaction.expiry
            Loader:Toast({
                Type = "success",
                Title = "Account Refreshed",
                Subtitle = "Latest license information received.",
            })
        else
            Loader:Toast({
                Type = "warning",
                Title = "Refresh Unavailable",
                Subtitle = "No updated license information was received.",
            })
        end
        View.paint()
    end)
end

local Failure = {
    { "expired", "Key Expired", "Your key has expired.", "Last request rejected" },
    { "rate limit", "Rate Limited", "Too many requests. Wait before trying again.", "Rate limited" },
    { "rate_limit", "Rate Limited", "Too many requests. Wait before trying again.", "Rate limited" },
    { "too many requests", "Rate Limited", "Too many requests. Wait before trying again.", "Rate limited" },
    { "request failed", "Connection Error", "The verification request failed. Try again.", "Request failed" },
    { "network", "Connection Error", "Couldn't reach the verification service. Try again.", "Request failed" },
    { "connection", "Connection Error", "Couldn't reach the verification service. Try again.", "Request failed" },
    { "timeout", "Connection Error", "The verification request timed out. Try again.", "Not confirmed" },
    {
        "protected gameplay module",
        "Module Unavailable",
        "The loader did not return a compatible module.",
        "Unconfirmed response",
    },
    { "unavailable", "Service Unavailable", "The verification service is unavailable.", "Unavailable" },
    { "invalid", "Invalid Key", "Invalid key or wrong project.", "Last request rejected" },
    { "revoked", "Key Revoked", "This key has been revoked.", "Last request rejected" },
    { "paused", "Key Paused", "This key is paused.", "Last request rejected" },
    { "hwid_mismatch", "Device Mismatch", "This key is linked to another device.", "Last request rejected" },
    { "another device", "Device Mismatch", "This key is linked to another device.", "Last request rejected" },
    { "session limit", "Session Limit", "This key has reached its active session limit.", "Last request rejected" },
    {
        "instance_limit_reached",
        "Session Limit",
        "This key has reached its active session limit.",
        "Last request rejected",
    },
}
function Auth.failure(message, key, raised, malformed)
    if raised then
        return "Validation Failed", "The validation handler did not finish successfully.", "Not confirmed"
    end
    if malformed then
        return "Validation Failed", "The loader did not confirm the key.", "Not confirmed"
    end
    local lower = type(message) == "string" and message:lower() or ""
    for _, row in ipairs(Failure) do
        if lower:find(row[1], 1, true) then
            return row[2], U.redact(message, key, row[3]), row[4]
        end
    end
    return "Access Not Granted", U.redact(message, key, "Key verification failed. Try again."), "Not confirmed"
end
function Auth.reject(token, title, message, provider)
    State.authorized, State.info, State.key, State.expiry = false, nil, nil, 0
    State.authError, State.message, State.provider = true, message, provider
    State.stage, State.activity = "authFailed", "Settling"
    FX.settle(false, title)
    View.paint()
    local scope = FX.validation
    scope:later("failure", Settings.reduced and 0 or 0.34, function()
        if token ~= State.token or not State.alive then
            return
        end
        FX.closeValidation()
        State.activity = "Idle"
        View.paint()
        Loader:Toast({ Type = "error", Title = title, Subtitle = message })
    end)
end

function Auth.finish(token, key, message, viaCallback)
    local fromHost = State.info and State.info.tier or nil
    if Auth.remaining() == 0 then
        -- Contradictory signed metadata must not turn into a successful handoff.
        -- The stock host retains the verified payload, so require a fresh host run.
        State.closedAttempt = true
        Auth.reject(
            token,
            "Key Expired",
            "The loader reported an expired license. Close and reload before trying again.",
            "Expired metadata returned"
        )
        return
    end
    State.authorized, State.key = true, key
    State.activity, State.stage, State.provider =
        "Completing", "authGranted", viaCallback and "Last request confirmed" or "Confirmed by host"
    State.authError, State.message = false, nil
    View.paint()
    FX.settle(true)
    local scope = FX.validation
    local behavior, callback = Settings.behavior, State.callbacks.Authorized
    local info = fromHost == "premium" and "Premium access enabled."
        or fromHost == "keyless" and "Keyless access enabled."
        or key and "Your key has been validated."
        or "Your access has been verified."
    local hostMessage = U.redact(message, key, "Access granted")
    local function expiredDuringExit()
        if Auth.remaining() ~= 0 then
            return false
        end
        State.closedAttempt = true
        for i = #FX.toasts, 1, -1 do
            if FX.toasts[i].title == "Access Granted" then
                FX.removeToast(FX.toasts[i], true)
            end
        end
        FX.closeValidation()
        Auth.reject(
            token,
            "Key Expired",
            "The verified license expired before handoff. Close and reload to try again.",
            "Last request confirmed"
        )
        return true
    end
    local short = Settings.reduced or not State.visible
    scope:later("granted", short and 0 or 0.28, function()
        if not expiredDuringExit() then
            Loader:Toast({ Type = "success", Title = "Access Granted", Subtitle = info })
        end
    end)
    scope:later("fade-verified", short and 0 or 0.53, FX.fade)
    scope:later("handoff", short and 0 or 0.83, function()
        if not State.alive or State.token ~= token or State.handoff or expiredDuringExit() then
            return
        end
        State.handoff = true
        FX.closeValidation()
        State.activity = "Idle"
        if behavior == "destroy" then
            Loader:Destroy() -- The caller checks GetState().Name before invoking Start().
        elseif behavior == "hide" then
            Loader:Hide()
        else
            FX.modal({
                Title = "Access Granted",
                Description = hostMessage,
                ActionText = "Continue",
                OnAction = function()
                    if behavior == "products" then
                        View.go("Games", true)
                    end
                end,
            })
        end
        if callback then
            -- Host work must survive the UI scope it just left, and is never retried.
            task.defer(function()
                local ok = pcall(callback, key, hostMessage, Loader)
                if not ok then
                    warn("[JetZKey] Authorized callback failed.")
                end
            end)
        end
    end)
end

function Auth.validate(value, restore)
    if not State.alive then
        return false, "destroyed"
    end
    if State.activity ~= "Idle" then
        return false, "busy"
    end
    if State.authorized or State.closedAttempt then
        return false, "already_completed"
    end
    FX.closeDialog()
    local key = U.trim(value)
    if key == "" or #key > 512 or not utf8.len(key) or key:find("%z") then
        State.authError, State.stage = true, "authFailed"
        State.message = key == "" and "Enter your key to continue."
            or #key > 512 and "The key exceeds the loader's input limit."
            or "The key has invalid text."
        View.go("Key", true)
        View.paint()
        if State.visible and key == "" then
            UI.key.field.box:CaptureFocus()
        end
        return false, key == "" and "empty_key" or "invalid_key"
    end
    local callback = State.callbacks.Validate
    if not callback then
        State.authError, State.message, State.provider = true, "The host has not installed a validator.", "Unavailable"
        View.go("Key", true)
        View.paint()
        return false, "callback_unavailable"
    end
    State.token += 1
    local token = State.token
    State.activity, State.stage, State.restoring = "Validating", restore and "authRestoring" or "authChecking", restore
    State.info, State.expiry, State.authError, State.message = nil, 0, false, nil
    State.provider = "Checking through host"
    Settings.keyVisible = false
    View.go("Key", true)
    View.releaseFocus()
    State.settingKey = true
    UI.key.field.box.Text = key
    State.settingKey = false
    FX.begin()
    View.paint()
    Life:later("slow-validation", 8, function()
        if token == State.token and State.activity == "Validating" then
            State.stage = "authSlow"
            View.paint()
        end
    end)
    task.defer(function()
        if not State.alive or State.token ~= token then
            return
        end
        local ok, result, message = pcall(callback, key)
        if not State.alive or State.token ~= token then
            return
        end
        Life:remove("slow-validation")
        State.restoring = false
        if ok and result == true then
            Auth.finish(token, key, message, not Auth.external)
        else
            Auth.reject(token, Auth.failure(message, key, not ok, ok and type(result) ~= "boolean"))
        end
    end)
    return true
end

-- Responsive layout and input: the same safe viewport/keyboard/drawer model
-- used by JetZ, but no off-screen drag range and no mobile window enlargement.
function View.clamp(x, y)
    local g = State.geometry
    return math.round(math.clamp(x, 0, math.max(0, g.area.X - g.width * g.scale))),
        math.round(math.clamp(y, 0, math.max(0, g.area.Y - g.height * g.scale)))
end
function View.layout(reveal, animateNav)
    local size = UI.viewport.AbsoluteSize
    if size.X <= 2 or size.Y <= 2 then
        local cam = workspace.CurrentCamera
        size = cam and cam.ViewportSize or V(866, 514)
        if size.X <= 2 or size.Y <= 2 then
            size = V(866, 514)
        end
    end
    local touch = Services.Input.TouchEnabled
    local keyboard = touch and Services.Input.OnScreenKeyboardVisible
    if keyboard then
        local y = Services.Input.OnScreenKeyboardPosition.Y - UI.viewport.AbsolutePosition.Y
        if y >= 90 and y < size.Y then
            size = V(size.X, y)
        end
    end
    local scale = Settings.scale
    local margin = touch and 7 or 14
    local hit = touch and math.ceil(D.touchHit / scale) or 30
    local width = math.max(1, math.floor(math.min(D.width, (size.X - 2 * margin) / scale)))
    local height = math.max(1, math.floor(math.min(D.height, (size.Y - 2 * margin) / scale)))
    local drawer = width < 660 and (not touch or size.X < size.Y * 1.18 or width < 515)
    local compact = drawer or width < 830 or touch and size.Y < 550
    local sidebar = drawer and 0 or (compact and D.landscapeSide or D.sidebar)
    local navHeader = State.route == "Games" and 42 or 54
    local header = compact and math.max(38, touch and hit or 0) or navHeader
    local toolbar = drawer and math.max(40, hit) or 0
    if keyboard and height < 204 then
        header = 0
    end
    local viewportW, viewportH = width - sidebar, math.max(1, height - header - toolbar)
    local g = {
        width = width,
        height = height,
        scale = scale,
        touch = touch,
        compact = compact,
        drawer = drawer,
        header = header,
        toolbar = toolbar,
        hit = hit,
        sidebar = sidebar,
        area = size,
        viewW = viewportW,
        viewH = viewportH,
    }
    local old = State.geometry
    State.geometry = g
    if FX.about and old and (old.viewW ~= viewportW or old.viewH ~= viewportH) then
        FX.stopAbout()
    end
    U.place(UI.shell, 0, 0, width, height)
    UI.scale.Scale = scale
    local centerX, centerY = (size.X - width * scale) / 2, (size.Y - height * scale) / 2
    local x, y = centerX, centerY
    if State.position then
        x, y = State.position.X, State.position.Y
    end
    x, y = View.clamp(x, y)
    UI.shell.Position = O(x, y)
    UI.close.root.Size = O(hit, hit)
    UI.close.root.Position = O(width - hit, 0)
    U.place(UI.body, sidebar, 0, viewportW, height)
    U.place(UI.header, 0, 0, viewportW, header + toolbar)
    U.place(UI.strip, 0, toolbar, viewportW, header)
    U.place(UI.menu.root, 0, 0, toolbar, toolbar)
    U.place(UI.islandTitle, toolbar + 5, 0, viewportW - toolbar - hit - 10, toolbar)
    UI.islandTitle.Visible, UI.menu.root.Visible = drawer, drawer
    U.place(UI.pages, 0, header + toolbar, viewportW, viewportH)
    for _, page in pairs(UI.routes) do
        page.Size = S(1, 1)
    end
    local sideWidth = drawer and math.min(width - hit, D.drawer) or sidebar
    local brandHeight = compact and 62 or 84
    local navY, navRow, navGap =
        brandHeight + (compact and 8 or 13), math.max(compact and 37 or 42, touch and hit or 0), compact and 4 or 9
    U.place(UI.sidebar, 0, 0, sideWidth, height)
    U.place(UI.sideFill, math.max(0, sideWidth - 11), 0, 11, height)
    U.place(UI.brand, 0, 0, sideWidth, brandHeight)
    U.place(UI.brandLine, 0, brandHeight - 1, sideWidth, 1)
    U.place(UI.logo, compact and 16 or 27, (brandHeight - 30) / 2, 30, 30)
    U.place(UI.title, compact and 56 or 76, 0, sideWidth - (compact and 62 or 82), brandHeight)
    local showFooter = height >= 172
    local footerY = height - (compact and 34 or 51)
    U.place(UI.footer, compact and 16 or 21, footerY, sideWidth - 26, 31)
    UI.footer.Visible = showFooter
    U.place(UI.navScroll, 0, navY, sideWidth, math.max(16, (showFooter and footerY - 3 or height - 2) - navY))
    UI.navScroll.CanvasSize = O(0, navRow * 4 + navGap * 3)
    for i, side in ipairs(SideOrder) do
        local tab = UI.sides[side]
        U.place(tab.root, 0, (i - 1) * (navRow + navGap), sideWidth, navRow)
        U.place(tab.mark, 0, 0, 3.5, navRow)
        U.place(tab.icon, compact and 17 or 25, (navRow - 18) / 2, 18, 18)
        local textX = compact and 46 or 68
        U.place(tab.label, textX, 0, sideWidth - textX - 6, navRow)
        tab:paint()
    end
    View.setDrawer(State.drawerOpen)
    View.strip(animateNav)
    View.layoutKey(g)
    View.layoutAccount(g)
    View.layoutStatus(g)
    View.layoutAbout(g)
    View.layoutSettings(g)
    View.layoutGames(g)
    FX.layout()
    if reveal and touch and Services.Input.OnScreenKeyboardVisible then
        Life:later("reveal-field", 0, function()
            if State.route ~= "Key" then
                return
            end
            local box, page = UI.key.field.box, UI.routes.Key
            if not box:IsFocused() then
                return
            end
            local delta = box.AbsolutePosition.Y
                + box.AbsoluteSize.Y
                + 7
                - (page.AbsolutePosition.Y + page.AbsoluteWindowSize.Y)
            if delta > 0 then
                page.CanvasPosition += V(0, delta)
            end
        end)
    end
end

function View.paint()
    if not State.alive or not State.geometry then
        return
    end
    local idle = View.requireIdle()
    for btn, condition in pairs(UI.busy) do
        btn:enable(idle and (condition == true or condition()))
    end
    local key = UI.key
    local editable = idle
        and State.route == "Key"
        and State.visible
        and not State.authorized
        and not State.closedAttempt
    key.field.box.TextEditable, key.field.box.Active, key.field.box.Selectable = editable, editable, editable
    local pending = State.activity == "Validating"
    key.validate:setText(pending and "Validating..." or "Validate Key")
    if pending and State.stage == "authSlow" then
        UI.validation.title.Text = "Still validating..."
    end
    key.feedback.Text = State.message or ""
    key.feedback.Visible = State.authError == true
    key.field:paint()
    View.mask()
    local canRemember = Prefs.available()
    for _, check in ipairs(UI.checks) do
        check.checked = Settings.remember
        check:enable(idle and canRemember)
        check:paint()
    end
    UI.settings.motion.checked = Settings.reduced
    UI.settings.motion:paint()
    UI.settings.note.Text = Prefs.note
        or (
            canRemember and "Keys are saved only by the Plak loader after verification."
            or "Saved-key storage isn't available on this client."
        )
    View.layoutKey(State.geometry)
    View.account()
    Catalog.paintStatus()
end

function View.bindInput()
    local input = Services.Input
    local function queueLayout()
        State.drag = nil
        Life:later("layout", 0, function()
            View.layout(true)
            View.paint()
        end)
    end
    Life:connect(UI.viewport:GetPropertyChangedSignal("AbsoluteSize"), queueLayout)
    for _, prop in ipairs({ "OnScreenKeyboardVisible", "OnScreenKeyboardPosition", "TouchEnabled" }) do
        Life:connect(input:GetPropertyChangedSignal(prop), queueLayout)
    end
    for _, handle in ipairs({ UI.brand, UI.dragBar, UI.islandTitle }) do
        Life:connect(handle.InputBegan, function(io)
            local kind = io.UserInputType
            if
                not State.visible
                or not View.requireIdle()
                or State.drag
                or (kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch)
            then
                return
            end
            State.drag = {
                input = io,
                touch = kind == Enum.UserInputType.Touch,
                point = V(io.Position.X, io.Position.Y),
                start = V(UI.shell.Position.X.Offset, UI.shell.Position.Y.Offset),
            }
        end)
    end
    Life:connect(input.InputChanged, function(io)
        local d = State.drag
        if
            not d
            or (d.touch and io ~= d.input)
            or (not d.touch and io.UserInputType ~= Enum.UserInputType.MouseMovement)
        then
            return
        end
        local position = d.start + V(io.Position.X, io.Position.Y) - d.point
        local x, y = View.clamp(position.X, position.Y)
        State.position = V(x, y)
        UI.shell.Position = O(x, y)
    end)
    Life:connect(input.InputEnded, function(io)
        if State.drag and State.drag.input == io then
            State.drag = nil
        end
    end)
    Life:connect(input.WindowFocusReleased, function()
        State.drag = nil
    end)
    Life:connect(input.InputBegan, function(io, processed)
        if processed or input:GetFocusedTextBox() then
            return
        end
        if io.KeyCode == Settings.toggle then
            if State.visible then
                Loader:Hide()
            else
                Loader:Show()
            end
        elseif io.KeyCode == Enum.KeyCode.Escape then
            if FX.dialog then
                FX.closeDialog()
            elseif State.drawerOpen then
                View.setDrawer(false)
            end
        end
    end)
end

-- PlakUi compatibility surface ------------------------------------------------
local function hook(name, callback)
    assert(callback == nil or type(callback) == "function", name .. " callback must be a function or nil")
    if State.alive then
        State.callbacks[name] = callback
    end
    return Loader
end
function Loader:SetTitle(_title)
    -- The renderer always presents the official Plak title.
    return self
end
function Loader:SetVersion(version)
    if State.alive then
        Settings.version = U.text(version, 48)
        UI.footer.Text = Settings.version == "" and "Release" or "Release " .. Settings.version
    end
    return self
end
function Loader:SetKeyLink(_url)
    -- PlakUi's public reward gateway is fixed and takes precedence over host URLs.
    return self
end
function Loader:SetOnGetKey(callback)
    return hook("GetKey", callback)
end
function Loader:SetOnValidate(callback)
    assert(callback == nil or type(callback) == "function", "SetOnValidate expects a function or nil")
    if State.alive and Auth.pending then
        return self, false
    end
    if State.alive then
        Auth.external = false
    end
    return hook("Validate", callback)
end
function Loader:SetOnAuthorized(callback)
    return hook("Authorized", callback)
end
function Loader:SetOnDestroyed(callback)
    return hook("Destroyed", callback)
end
function Loader:SetOnForgetKey(callback)
    hook("ForgetKey", callback)
    if State.alive then
        View.paint()
    end
    return self
end
function Loader:SetOnRefresh(callback)
    hook("Refresh", callback)
    if State.alive then
        View.paint()
    end
    return self
end
function Loader:SetAuthInfo(info)
    if State.alive then
        Auth.setInfo(info)
    end
    return self
end
function Loader:SetExpiry(seconds)
    if State.alive then
        Auth.setExpiry(seconds)
    end
    return self
end
function Loader:GetExpiry()
    return State.expiry
end
function Loader:SetSuccessBehavior(behavior)
    assert(
        behavior == "products" or behavior == "stay" or behavior == "hide" or behavior == "destroy",
        "Unknown success behavior"
    )
    if State.alive then
        Settings.behavior = behavior
    end
    return self
end
function Loader:Validate(key)
    if not State.alive then
        return false, "destroyed"
    end
    return Auth.validate(key ~= nil and key or UI.key.field.box.Text, false)
end
function Loader:AutoValidate(key)
    return Auth.validate(key, true)
end
function Loader:SetKeyVisible(value)
    if not State.alive or (value == true and (not View.requireIdle() or State.route ~= "Key")) then
        return self, false
    end
    Settings.keyVisible = value == true
    View.mask()
    return self, true
end
function Loader:IsKeyVisible()
    return Settings.keyVisible
end
function Loader:PasteKey()
    if not View.requireIdle() or State.route ~= "Key" or State.authorized then
        return false, "busy"
    end
    local read = U.cap("getclipboard", "readclipboard")
    if not read then
        return false, "clipboard_unavailable"
    end
    local ok, val = pcall(read)
    if not State.alive then
        return false, "destroyed"
    end
    if not View.requireIdle() or State.route ~= "Key" or State.authorized then
        return false, "busy"
    end
    val = ok and U.trim(val) or ""
    if val == "" or #val > 4096 or val:find("[%z\r\n]") or not utf8.len(val) then
        return false, "invalid_clipboard"
    end
    Settings.keyVisible = false
    UI.key.field.box.Text = val
    UI.key.field.box:CaptureFocus()
    return true
end
function Loader:ForgetSavedKey()
    if not View.requireIdle() then
        return false, "busy"
    end
    local callback = State.callbacks.ForgetKey
    if not callback then
        return false, "callback_unavailable"
    end
    State.activity = "ForgettingKey"
    View.paint()
    local ok, result = pcall(callback, self)
    if not State.alive then
        return false, "destroyed"
    end
    State.activity = "Idle"
    local removed = ok and result == true
    if removed then
        Settings.keyVisible = false
        UI.key.field.box.Text = ""
        State.authError, State.message = false, nil
        self:Toast({ Type = "success", Title = "Saved Key Removed", Subtitle = "The current session was not revoked." })
    else
        self:Toast({
            Type = "warning",
            Title = "Saved Key Not Removed",
            Subtitle = "Couldn't clear the saved key on this device.",
        })
    end
    View.paint()
    return removed, not removed and "delete_failed" or nil
end
function Loader:SetReducedMotion(value)
    if State.alive and Settings.reduced ~= (value == true) then
        Settings.reduced = value == true
        if Settings.reduced then
            FX.stopAbout()
            if FX.validation then
                FX.validation:remove("spinner")
            end
        elseif FX.validation and UI.shade.Visible then
            FX.spin()
        end
        Prefs.changed(false)
        View.paint()
    end
    return self
end
function Loader:SetUIScale(value)
    if State.alive then
        Settings.scale = math.clamp(U.number(value, 1), 0.85, 1.15)
        View.layout(true)
        Prefs.changed(false)
    end
    return self
end
function Loader:SetToggleKey(key)
    if State.alive and typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
        Settings.toggle = key
    end
    return self
end
function Loader:Show()
    if State.alive then
        State.visible = true
        UI.shell.Visible, UI.restore.root.Visible = true, false
        View.layout(false)
        View.paint()
    end
    return self
end
function Loader:Hide()
    if State.alive then
        View.releaseFocus()
        View.setDrawer(false)
        FX.stopAbout()
        State.visible, State.drag, Settings.keyVisible = false, nil, false
        UI.shell.Visible = false
        UI.restore.root.Visible = State.activity ~= "Completing"
        View.paint()
    end
    return self
end
function Loader:ShowPreferences(visible)
    if not View.requireIdle() then
        return self, false
    end
    if visible == false and State.route == "Settings" then
        View.go(State.beforeSettings or State.sub)
    elseif visible ~= false and State.route ~= "Settings" then
        State.beforeSettings = State.route
        View.go("Settings")
    end
    return self, true
end
function Loader:ShowAuth()
    View.go("Key")
    return self
end
function Loader:ShowProducts()
    View.go("Games")
    return self
end
function Loader:ShowLicenses()
    return Settings.offer and View.go("About") or false
end
function Loader:SetProducts(products)
    if State.alive then
        assert(type(products) == "table", "SetProducts expects an array of product configurations")
        Catalog.revision += 1
        Life:remove("registry")
        Life:remove("registry-timeout")
        local rows, lookup = Catalog.normalize(products, false)
        Catalog.install(rows, lookup)
    end
    return self
end
function Loader:Toast(config)
    if not State.alive then
        return nil
    end
    FX.toast(type(config) == "table" and config or { Subtitle = U.text(config, 180) })
    return self
end
function Loader:ClearToasts()
    if State.alive then
        FX.clearToasts()
    end
    return self
end
function Loader:ShowLoading(config)
    return FX.modal(type(config) == "table" and config or { Text = config }, true)
end
function Loader:SetProgress(value)
    if FX.dialog then
        FX.dialog.handle:SetProgress(value)
    end
    return self
end
function Loader:HideLoading()
    if State.modal == "progress" then
        FX.closeDialog()
    end
    return self
end
function Loader:ShowResult(config)
    FX.modal(type(config) == "table" and config or { Description = config })
    return self
end
function Loader:CloseModal()
    FX.closeDialog()
    return self
end
function Loader:SetStatus(value, product)
    if not State.alive then
        return self
    end
    if product ~= nil then
        for _, item in ipairs(Catalog.entries) do
            if item.id == tostring(product) then
                item.status = U.text(value, 32)
                break
            end
        end
        Catalog.paintStatus()
    elseif FX.dialog then
        FX.dialog.handle:SetText(value)
    end
    return self
end
function Loader:SetCommunityEnabled(enabled)
    if State.alive then
        Settings.community = enabled == true
        View.layoutAbout(State.geometry)
    end
    return self
end
function Loader:SetCommunityLink(link)
    if not State.alive then
        return self, false
    end
    local url = U.url(link)
    if not url and U.trim(link) ~= "" then
        return self, false
    end
    Settings.communityLink = url
    View.layoutAbout(State.geometry)
    return self, true
end
function Loader:GetCommunityLink()
    return Settings.communityLink or DISCORD
end
function Loader:SetOnSocial(callback)
    return hook("Social", callback)
end
function Loader:SetLicenseOfferEnabled(enabled)
    if State.alive then
        Settings.offer = enabled == true
        View.layoutAbout(State.geometry)
    end
    return self
end
function Loader:SetLicenseStoreLink(link)
    if not State.alive or type(link) ~= "string" then
        return self, false
    end
    local url = U.url(link)
    if not url and U.trim(link) ~= "" then
        return self, false
    end
    Settings.store = url
    return self, true
end

function Loader:GetState()
    local page = State.route == "Games" and "Products" or State.route == "About" and "Licenses" or "Auth"
    local name = not State.alive and "Destroyed"
        or not State.visible and "Hidden"
        or State.activity == "Completing" and "AuthCompleting"
        or State.activity == "Validating" and "Validating"
        or State.activity == "Settling" and "Validating"
        or State.activity ~= "Idle" and State.activity
        or State.modal == "progress" and "ProductProgress"
        or State.modal and "ModalOpen"
        or page == "Products" and "ProductBrowser"
        or page == "Licenses" and "LicenseBrowser"
        or UI.key and UI.key.field.box:IsFocused() and "AuthFocused"
        or State.authorized and "Authorized"
        or "AuthIdle"
    return {
        Name = name,
        Page = page,
        Activity = State.activity,
        Visible = State.visible,
        KeyVisible = Settings.keyVisible,
        RememberMe = Settings.remember,
        AuthError = State.authError == true,
        Authorized = State.authorized,
        Language = Settings.language,
        UIScale = Settings.scale,
        ReducedMotion = Settings.reduced,
        CommunityEnabled = Settings.community,
        CommunityDockVisible = false,
        CommunityDismissed = Settings.communityDismissed,
        ExternalAuthPending = Auth.pending ~= nil and not Auth.pending.done,
        ExternalAuthSubmitted = Auth.external and Auth.consumed or false,
        AuthStage = State.stage,
        AccessTier = State.authorized and State.info and State.info.tier or nil,
        ExpirySeconds = State.expiry,
        Progress = State.progress,
        Modal = State.modal,
        Route = State.route,
        LicenseRemaining = State.authorized and Auth.remaining() or nil,
    }
end

-- Legacy pre-auth transport. Submitting input never grants access. A protected
-- host must explicitly provide its already-verified metadata on confirmation.
function Auth.settleExternal(accepted, message, info)
    local req = Auth.pending
    if not req or req.done then
        return false, "no_pending_submission"
    end
    if accepted then
        if not State.alive or req.token ~= State.token then
            return false, "stale_submission"
        end
        if type(info) ~= "table" or (info.tier ~= "free" and info.tier ~= "premium") then
            return false, "missing_auth_metadata"
        end
        Auth.setInfo(info)
        Auth.setExpiry(info.secondsLeft)
    end
    req.done, req.accepted, req.message = true, accepted == true, message
    Life:remove(req)
    req.signal:Fire()
    return true
end
function Auth.externalWait(key)
    if Auth.consumed then
        return false, "This prompt has already submitted a key. Reload to try again."
    end
    local callback = State.callbacks.KeySubmit
    if not callback then
        return false, "The host has not installed a validator."
    end
    local req = { token = State.token, signal = U.make("BindableEvent", nil, "ProtectedAuthResult") }
    Auth.pending, Auth.consumed = req, true
    Life:later(req, 30, function()
        Auth.settleExternal(false, "The FlowAuth confirmation timed out.")
    end)
    local ok, submitted = pcall(callback, key, Loader)
    if not ok or submitted == false then
        Auth.settleExternal(false)
    end
    if not req.done then
        req.signal.Event:Wait()
    end
    Life:remove(req)
    req.signal:Destroy()
    if Auth.pending == req then
        Auth.pending = nil
    end
    return req.accepted == true,
        req.message or (req.accepted and "Access granted" or "FlowAuth did not confirm this run.")
end
function Loader:SetOnKeySubmit(callback)
    assert(callback == nil or type(callback) == "function", "SetOnKeySubmit expects a function or nil")
    if State.alive then
        if Auth.pending or Auth.consumed then
            return self, false
        end
        Auth.external = callback ~= nil
        State.callbacks.KeySubmit = callback
        State.callbacks.Validate = callback and Auth.externalWait or nil
    end
    return self, true
end
function Loader:ConfirmExternalAuth(info, message)
    if not Auth.external then
        return false, "not_external_auth"
    end
    return Auth.settleExternal(true, message, info)
end
function Loader:CancelExternalAuth(message)
    return Auth.settleExternal(false, type(message) == "string" and U.text(message, 240) or nil)
end
function Loader:CompleteVerifiedAuth(info, message)
    if not State.alive then
        return false, "destroyed"
    end
    if State.authorized or State.activity ~= "Idle" or Auth.pending or Auth.consumed or State.closedAttempt then
        return false, "busy_or_completed"
    end
    if type(info) ~= "table" or (info.tier ~= "free" and info.tier ~= "premium") then
        return false, "missing_auth_metadata"
    end
    FX.closeDialog()
    Auth.setInfo(info)
    Auth.setExpiry(info.secondsLeft)
    State.token += 1
    self:Show()
    Auth.finish(State.token, nil, message, false)
    return not State.closedAttempt, State.closedAttempt and "expired" or nil
end
function Loader:AwaitFlowKey(currentKey, _options)
    if not State.alive then
        error("[PLAK] Key prompt is already closed", 0)
    end
    local slot, owner = "__PlakFlowInitBridgeV1", "PLAK/flow_init/v1"
    local old = Env[slot]
    if type(old) == "table" and old.Owner == owner then
        if old.ScriptStarted or not old.Finished then
            if old.Loader ~= self then
                self:Destroy()
            end
            error("[PLAK] A FlowAuth run is already active; restart before retrying", 0)
        end
        if old.Loader and old.Loader ~= self then
            U.call(old.Loader.Destroy, old.Loader)
        end
    end
    local bridge = {
        Owner = owner,
        Stage = "prompt",
        Finished = false,
        Loader = self,
        Flow = type(Env.FlowAuth) == "table" and Env.FlowAuth or nil,
    }
    Env[slot] = bridge
    local submit = U.make("BindableEvent", nil, "PlakFlowInitSubmission")
    local selected
    local file = "PLAK/saved_key.txt"
    local read, exists, write, delete = U.cap("readfile"), U.cap("isfile"), U.cap("writefile"), U.cap("delfile")
    local function remove()
        if exists then
            local ok, had = pcall(exists, file)
            if ok and not had then
                return true
            end
        end
        local ok, result = U.call(delete, file)
        if ok and result ~= false then
            return true
        end
        ok, result = U.call(write, file, "")
        return ok and result ~= false
    end
    bridge.ClearCredential = function()
        selected = nil
    end
    bridge.SaveAcceptedKey = function()
        if bridge.Accepted ~= true then
            return false
        end
        local key = selected
        selected = nil
        if not Settings.remember or not write or type(key) ~= "string" or key == "" then
            return false
        end
        local ok, result = pcall(function()
            local make, folder = U.cap("makefolder"), U.cap("isfolder")
            if make and (not folder or not folder("PLAK")) then
                pcall(make, "PLAK")
            end
            return write(file, key)
        end)
        return ok and result ~= false
    end
    self:SetTitle(TITLE):SetVersion("1.1.0"):SetSuccessBehavior("destroy")
    self:SetOnForgetKey((delete or write) and remove or nil)
    if not Settings.remember then
        remove()
    end
    self:SetOnDestroyed(function()
        if bridge.Accepted then
            return
        end
        bridge.Cancelled, bridge.Stage, selected = true, "cancelled", nil
        if bridge.Submitted then
            local flow = bridge.Flow
            if flow and type(flow.Stop) == "function" then
                bridge.Finished = pcall(flow.Stop, flow)
            end
        else
            bridge.Finished = true
            if submit then
                submit:Fire()
            end
        end
    end)
    self:SetOnKeySubmit(function(key)
        if bridge.Submitted or bridge.Cancelled or not submit then
            return false
        end
        selected = key
        bridge.Flow = bridge.Flow or (type(Env.FlowAuth) == "table" and Env.FlowAuth or nil)
        bridge.Submitted, bridge.Stage = true, "awaiting-flowauth"
        submit:Fire()
        return true
    end)
    local initial = U.trim(currentKey)
    if #initial > 512 then
        self:Destroy()
        submit:Destroy()
        submit = nil
        error("[PLAK] script_key exceeds the input limit", 0)
    end
    if initial == "" and Settings.remember and read and exists then
        local ok, val = pcall(function()
            return exists(file) and read(file) or nil
        end)
        local saved = ok and U.trim(val) or ""
        if #saved <= 512 and utf8.len(saved) then
            initial = saved
        end
    end
    if initial ~= "" then
        self:AutoValidate(initial)
    end
    if not bridge.Submitted and not bridge.Cancelled then
        submit.Event:Wait()
    end
    submit:Destroy()
    submit = nil
    if bridge.Cancelled or not selected then
        error("[PLAK] Key prompt cancelled", 0)
    end
    return selected
end

function Loader:Destroy()
    if not State.alive then
        return
    end
    local destructor = State.callbacks.Destroyed
    State.alive, State.visible = false, false
    State.token += 1
    Auth.settleExternal(false)
    State.drag, State.refresh, State.activity = nil, nil, "Idle"
    State.modal, State.info, State.key, State.message = nil, nil, nil, nil
    State.authError, Settings.keyVisible = false, false
    if Env[OWNER] == self then
        Env[OWNER] = nil
    end
    table.clear(State.callbacks)
    if UI.key then
        pcall(function()
            UI.key.field.box:ReleaseFocus(false)
            UI.key.field.box.Text = ""
        end)
    end
    Life:destroy()
    FX.closeValidation()
    FX.closeDialog()
    FX.stopAbout()
    FX.clearToasts()
    table.clear(Catalog.rows)
    table.clear(Catalog.media)
    table.clear(Catalog.results)
    table.clear(Catalog.entries)
    table.clear(Catalog.byPlace)
    Catalog.artworkIds = nil
    if UI.gui and not State.guiDestroying then
        UI.gui:Destroy()
    end
    table.clear(UI)
    if Prefs.dirty then
        Prefs.save()
    end
    if destructor then
        local ok = pcall(destructor, self)
        if not ok then
            warn("[JetZKey] Destroy callback failed.")
        end
    end
end

local function initialize()
    local player = Services.Players.LocalPlayer
    local parent = player and (player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5))
    assert(parent, "JetZKey requires a client PlayerGui")
    local previous = Env[OWNER]
    if type(previous) == "table" and previous.__PlakOwned and type(previous.Destroy) == "function" then
        pcall(previous.Destroy, previous)
    end
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("ScreenGui") and child:GetAttribute("PlakUiOwned") == true then
            local signal = child:FindFirstChild("PlakDispose")
            if signal and signal:IsA("BindableEvent") then
                signal:Fire()
            end
            child:Destroy()
        end
    end
    Prefs.load()
    Env[OWNER] = Loader
    View.shell(parent)
    View.buildKey()
    View.buildAccount()
    View.buildStatus()
    View.buildGames()
    View.buildAbout()
    View.buildSettings()
    FX.build()
    View.bindInput()
    local dispose = U.make("BindableEvent", UI.gui, "PlakDispose")
    Life:connect(dispose.Event, function()
        Loader:Destroy()
    end)
    Life:connect(UI.gui.Destroying, function()
        State.guiDestroying = true
        Loader:Destroy()
    end)
    Life:connect(UI.gui.AncestryChanged, function()
        if not UI.gui.Parent then
            Loader:Destroy()
        end
    end)
    View.layout(false)
    View.paint()
    UI.gui.Enabled = true
    Catalog.fetch()
end
local ok = pcall(initialize)
if not ok then
    Loader:Destroy()
    -- Initialization diagnostics must never include raw host/parser exceptions.
    error("[JetZKey] Could not initialize the native key window.", 0)
end
return Loader
