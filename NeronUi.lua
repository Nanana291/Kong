-- NeronUi 2.0 — reference-measured, client-only, dependency-free.
-- require(ModuleScript) or loadstring(readfile(...))() returns the library; nothing auto-opens.
-- Set(value [, silent]) fires Callback only on change. Defaults are silent.
-- Range:Set(low, high [, silent]); Color:Set(color [, silent]); callbacks receive snapshots.
-- Numeric controls: Step/Increment, Prefix, Suffix, Rounding. Values are finite and clamped.
-- Parent may be supplied for Studio. Otherwise protected UI -> CoreGui -> PlayerGui.
-- Same Id replaces the previous window, including listeners, across library re-execution.
-- Window > Tab > SubTab > controls remains the public hierarchy; Settings is a separate overlay.
-- CreateWindow also accepts Theme, Language, Settings=false, Autoload=false, GameName, Filesystem.
-- ManualSize accepts Vector2.new(w,h), offset UDim2 or {w,h}; nil/false keeps Size/default.
-- Legacy ManualSize=true still selects500x480. Resizable defaults true; MinSize/MaxSize bound it.
-- RememberSize/RememberPosition default false, including when older preferences enabled them; startup is centered.
-- Desktop automatic Size is912x543; mobile defaults unchanged.
-- Tooltips/Tooltip/ToolTip provide hover/hold hints. Explicit sizing takes precedence over saved dimensions.
-- Premium={Active=boolean,ExpiresAt=UnixSeconds,Plan=string}; SetPremiumStatus updates Settings > General.
-- Premium is external display state, never a saved entitlement or automatic unlock.
-- Toggle Locked=true stays OFF and opens a Premium callout; SetLocked(false) restores interaction.
-- OnBuyPremium(toggle, window), on Window or Toggle, connects your purchase flow; it never auto-unlocks.
-- Themes: Neron Dark / Graphite / OLED / Light; locales: English / Spanish / Russian / Portuguese.
-- Stateful controls with string Flag are saved unless Persistent=false. No flag is generated implicitly.
-- Window:CreateProfile/SaveProfile/LoadProfile(name [, silent]) return success, error or load counts.
-- LoadProfile(name,true) and startup autoload update state/UI without callbacks; false/nil is normal load.
-- ImportProfile(name,json [, overwrite]); ExportProfile([name]); Rename/Duplicate/Delete/RefreshProfiles.
-- SetAutoload(name), DisableAutoload(), GetAutoload(), ApplyAutoload(); OpenSettings([category]).
-- SetTheme/GetTheme/GetThemeTokens; ImportTheme/ExportTheme; SetLanguage/GetLanguage/Translate.
-- Preferences: Neron/End/{Theme,Autoload}.json; profiles: Neron/<sanitized game>/Settings/<name>.json.
-- Without filesystem APIs the entire UI still works; persistence returns a descriptive failure.
-- Readback/rollback protects saves where possible; executor APIs cannot guarantee crash-atomic writes.
local S = {
    Tween = game:GetService("TweenService"),
    Input = game:GetService("UserInputService"),
    Players = game:GetService("Players"),
    Core = game:GetService("CoreGui"),
    Text = game:GetService("TextService"),
    Http = game:GetService("HttpService"),
    Marketplace = game:GetService("MarketplaceService"),
}
local Theme = {
    AppBackground = Color3.fromRGB(24, 23, 28),
    WindowBackground = Color3.fromRGB(14, 13, 18),
    SidebarBackground = Color3.fromRGB(16, 15, 20),
    ContentBackground = Color3.fromRGB(15, 14, 19),
    RowBackground = Color3.fromRGB(16, 15, 20),
    RowHover = Color3.fromRGB(18, 17, 23),
    PopoverBackground = Color3.fromRGB(12, 11, 17),
    InputBackground = Color3.fromRGB(18, 17, 23),
    Separator = Color3.fromRGB(24, 23, 29),
    BorderWeak = Color3.fromRGB(26, 25, 33),
    BorderStrong = Color3.fromRGB(58, 55, 78),
    TextPrimary = Color3.fromRGB(220, 219, 225),
    TextSecondary = Color3.fromRGB(67, 65, 75),
    TextMuted = Color3.fromRGB(53, 51, 60),
    TextDisabled = Color3.fromRGB(36, 35, 43),
    Accent = Color3.fromRGB(116, 111, 177),
    AccentHover = Color3.fromRGB(130, 124, 192),
    AccentPressed = Color3.fromRGB(90, 86, 143),
    AccentMuted = Color3.fromRGB(36, 33, 52),
    Success = Color3.fromRGB(98, 177, 106),
    Warning = Color3.fromRGB(183, 153, 92),
    Danger = Color3.fromRGB(203, 96, 105),
}
Theme.HeaderBackground = Color3.fromRGB(16, 15, 20)
Theme.RowPressed = Color3.fromRGB(21, 20, 27)
Theme.SurfaceSecondary = Color3.fromRGB(20, 19, 26)
Theme.SurfaceSelected = Color3.fromRGB(23, 22, 30)
Theme.SurfaceEdge = Color3.fromRGB(28, 27, 35)
Theme.ToggleTrackOff = Color3.fromRGB(22, 20, 28)
Theme.ToggleTrackOn = Color3.fromRGB(47, 43, 68)
Theme.ToggleKnobOff = Color3.fromRGB(48, 44, 58)
Theme.ToggleKnobOn = Color3.fromRGB(119, 113, 180)
Theme.SliderTrack = Color3.fromRGB(20, 19, 26)
Theme.SliderFill = Theme.Accent
Theme.SliderKnob = Theme.Accent
Theme.SliderCore = Color3.fromRGB(31, 28, 46)
Theme.DropdownBackground = Color3.fromRGB(19, 18, 25)
Theme.DropdownHover = Color3.fromRGB(23, 22, 31)
Theme.Overlay = Color3.new(0, 0, 0)
Theme.Shadow = Color3.new(0, 0, 0)
Theme.ButtonText = Color3.fromRGB(17, 15, 25)
Theme.SystemText = Color3.fromRGB(153, 150, 164)
local T = {
    Geometry = {
        Width = 872,
        Height = 548,
        DesktopWidth = 912,
        DesktopHeight = 543,
        ManualWidth = 500, -- UIs/FluentModded.lua CreateWindow Size
        ManualHeight = 480,
        Sidebar = 234,
        Header = 64,
        Strip = 40,
        ContentTop = 110,
        ContentLeft = 12,
        ContentRight = 42,
        LabelInset = 16,
        Row = 64,
        DescriptionRow = 76,
        RowGap = 10,
        Control = 142,
        ValueGap = 16,
        ControlLane = 228,
        Track = 10,
        Thumb = 10,
        ThumbCore = 4,
        Toggle = 36,
        AttachedSwatchInset = 64,
        ToggleHeight = 14,
        ToggleKnob = 10,
        ToggleInset = 2,
        PremiumBadge = 56,
        PremiumWidth = 290,
        PremiumHeight = 164,
        Swatch = 17,
        Scrollbar = 9,
        ScrollInset = 10,
        Option = 28,
        PopoverWidth = 160,
        PickerWidth = 180,
        PickerSV = 100,
        PickerRail = 8,
        SearchInset = 126,
        Button = 44,
        SidebarTab = 44,
        Category = 28,
    },
    Radius = { Window = 6, Row = 2, Popover = 3, Input = 2, Button = 3 },
    Spacing = { Tiny = 4, Small = 8, Normal = 12, Medium = 16, Large = 24, Wide = 32 },
    Type = {
        Brand = 18,
        Suffix = 9,
        PageTitle = 16,
        PageSubtitle = 11,
        Category = 10,
        Tab = 13,
        SubTab = 12,
        ElementTitle = 13,
        Description = 12,
        Value = 12,
        PopoverOption = 12,
    },
    Motion = { Micro = 0.10, Fast = 0.16, Normal = 0.18, Structural = 0.24 },
    Z = {
        Shell = 1,
        Content = 3,
        Dim = 20,
        Popover = 60,
        Search = 40,
        Settings = 50,
        Confirmation = 70,
        Toast = 80,
        Tooltip = 90,
    },
}
local U, Maid, Motion, Icons, Input, Overlay, Scroll = {}, {}, {}, {}, {}, {}, {}
local Window, Tab, SubTab, Control, Components = {}, {}, {}, {}, {}
local Presentation, Locale, Storage, Profiles, SettingsUI = {}, {}, {}, {}, {}
local Tooltip, Geometry, Premium = {}, {}, {}
local Library = { Version = "2.0.0", Tokens = T, Theme = Theme, Icons = {} }
Window.__index = Window
Tab.__index = Tab
SubTab.__index = SubTab
Control.__index = Control

function Maid.new(motion)
    return setmetatable({ items = {}, dead = false, motion = motion }, { __index = Maid })
end
function Maid:Add(item)
    if self.dead then
        Maid.Clean(item)
    else
        self.items[item] = true
    end
    return item
end
function Maid.Clean(item)
    if typeof(item) == "RBXScriptConnection" then
        item:Disconnect()
    elseif typeof(item) == "Instance" then
        item:Destroy()
    elseif type(item) == "function" then
        item()
    elseif type(item) == "table" and item.Destroy then
        item:Destroy()
    end
end
function Maid:Remove(item, clean)
    self.items[item] = nil
    if clean then
        Maid.Clean(item)
    end
end
function Maid:After(seconds, fn, deferred)
    if self.dead then
        return
    end
    local thread, cancel
    cancel = function()
        if thread and coroutine.status(thread) == "suspended" then
            task.cancel(thread)
        end
    end
    local function run()
        self:Remove(cancel)
        if not self.dead then
            fn()
        end
    end
    thread = deferred and task.defer(run) or task.delay(seconds, run)
    self:Add(cancel)
    return cancel
end
function Maid:Destroy()
    if self.dead then
        return
    end
    self.dead = true
    for item in pairs(self.items) do
        self.items[item] = nil
        if typeof(item) == "Instance" and self.motion then
            self.motion:Tree(item)
        end
        local ok, err = pcall(Maid.Clean, item)
        if not ok then
            warn("[Neron cleanup] " .. tostring(err))
        end
    end
end

function Motion.new()
    return setmetatable({ leases = setmetatable({}, { __mode = "k" }) }, { __index = Motion })
end
function Motion:Cancel(obj, property)
    local slots = self.leases[obj]
    if not slots then
        return
    end
    local function stop(key, lease)
        slots[key] = nil
        lease.connection:Disconnect()
        lease.tween:Cancel()
    end
    if property then
        if slots[property] then
            stop(property, slots[property])
        end
    else
        for key, lease in pairs(slots) do
            stop(key, lease)
        end
        self.leases[obj] = nil
    end
end
function Motion:To(obj, duration, goals)
    if not obj.Parent then
        return
    end
    local slots = self.leases[obj]
    if not slots then
        slots = {}
        self.leases[obj] = slots
    end
    for property, value in pairs(goals) do
        local active = slots[property]
        if duration ~= 0 and active and active.goal == value then
            continue
        end
        self:Cancel(obj, property)
        if obj[property] == value then
            continue
        end
        if duration == 0 then
            obj[property] = value
        else
            local tween = S.Tween:Create(
                obj,
                TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { [property] = value }
            )
            local lease = { tween = tween, goal = value }
            slots[property] = lease
            lease.connection = tween.Completed:Connect(function()
                if slots[property] == lease then
                    slots[property] = nil
                end
                lease.connection:Disconnect()
            end)
            tween:Play()
        end
    end
end
function Motion:Tree(root)
    self:Cancel(root)
    for _, obj in ipairs(root:GetDescendants()) do
        self:Cancel(obj)
    end
end
function Motion:Destroy()
    for obj in pairs(self.leases) do
        self:Cancel(obj)
    end
end
U.owners = setmetatable({}, { __mode = "kv" })
function U.new(class, props, parent)
    local obj = Instance.new(class)
    if obj:IsA("GuiObject") then
        obj.BorderSizePixel = 0
        obj.BackgroundTransparency = 1
    end
    if obj:IsA("GuiButton") then
        obj.AutoButtonColor = false
        if obj:IsA("TextButton") then
            obj.Text = ""
        end
    end
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    obj.Parent = parent
    local owner = parent and U.owners[parent]
    if owner then
        U.owners[obj] = owner
        for _, property in ipairs({ "BackgroundColor3", "TextColor3", "PlaceholderColor3", "ImageColor3", "Color" }) do
            local color = props and props[property]
            if typeof(color) == "Color3" then
                for token, value in pairs(owner.theme) do
                    if color == value then
                        U.bind(owner, obj, property, token)
                        break
                    end
                end
            end
        end
    end
    return obj
end
function U.corner(obj, radius)
    return U.new("UICorner", { CornerRadius = UDim.new(0, radius) }, obj)
end
function U.stroke(obj, color, thickness)
    return U.new(
        "UIStroke",
        { Color = color, Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
        obj
    )
end
function U.label(parent, text, size, color, props)
    local p = {
        Text = tostring(text or ""),
        Font = Enum.Font.Gotham,
        TextSize = size,
        TextColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.fromScale(1, 1),
        ZIndex = parent.ZIndex + 1,
    }
    for key, value in pairs(props or {}) do
        p[key] = value
    end
    return U.new("TextLabel", p, parent)
end
function U.connect(bag, signal, fn)
    return bag:Add(signal:Connect(fn))
end
function U.finite(value, fallback)
    local n = tonumber(value)
    if not n or n ~= n or n == math.huge or n == -math.huge then
        return fallback
    end
    return n
end
function U.copy(v)
    return type(v) == "table" and table.clone(v) or v
end
function U.equal(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        return a == b
    end
    if #a ~= #b then
        return false
    end
    for i, value in ipairs(a) do
        if value ~= b[i] then
            return false
        end
    end
    return true
end
function U.remove(list, item)
    local i = table.find(list, item)
    if i then
        table.remove(list, i)
    end
end
function U.point(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end
function U.inside(obj, p)
    if not obj or not obj.Parent or not obj.Visible then
        return false
    end
    local a, b = obj.AbsolutePosition, obj.AbsoluteSize
    return p.X >= a.X and p.Y >= a.Y and p.X <= a.X + b.X and p.Y <= a.Y + b.Y
end
function U.primary(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end
function U.width(text, size, font)
    return S.Text:GetTextSize(tostring(text), size, font or Enum.Font.Gotham, Vector2.new(2000, 100)).X
end
function U.bind(w, obj, property, token)
    local bindings = w.bindings[obj]
    if not bindings then
        bindings = {}
        w.bindings[obj] = bindings
    end
    bindings[property] = token
    obj[property] = w.theme[token]
end
function U.frame(parent, props, w, token)
    local f = U.new("Frame", props, parent)
    if token then
        f.BackgroundTransparency = 0
        U.bind(w, f, "BackgroundColor3", token)
    end
    return f
end
function U.button(parent, props)
    return U.new("TextButton", props, parent)
end
function U.focusRelease(w)
    local box = S.Input:GetFocusedTextBox()
    if box and box:IsDescendantOf(w.gui) then
        box:ReleaseFocus()
    end
end
function U.warn(name, err)
    warn("[Neron " .. tostring(name) .. "] " .. tostring(err))
end

-- Native vector icons are the deterministic fallback. Asset ids/registry entries override them.
-- Geometry is normalized to a 24x24/Lucide-like visual grid and rendered through Neron's existing Frame/UIStroke pipeline.
function Icons.line(parent, x1, y1, x2, y2, color, width)
    local dx, dy = x2 - x1, y2 - y1
    return U.new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale((x1 + x2) / 2, (y1 + y2) / 2),
        Size = UDim2.new(math.sqrt(dx * dx + dy * dy), 0, 0, width or 1.4),
        Rotation = math.deg(math.atan2(dy, dx)),
        BackgroundTransparency = 0,
        BackgroundColor3 = color,
        ZIndex = parent.ZIndex,
    }, parent)
end
function Icons.ring(parent, x, y, r, color, width)
    local f = U.new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(x, y),
        Size = UDim2.fromScale(r * 2, r * 2),
        ZIndex = parent.ZIndex,
    }, parent)
    U.corner(f, 100)
    U.stroke(f, color, width or 1.4)
    return f
end
function Icons.poly(parent, points, color, width, closed)
    for i = 1, #points - 1 do
        local a, b = points[i], points[i + 1]
        Icons.line(parent, a[1], a[2], b[1], b[2], color, width)
    end
    if closed and #points > 2 then
        local a, b = points[#points], points[1]
        Icons.line(parent, a[1], a[2], b[1], b[2], color, width)
    end
end
function Icons.arc(parent, cx, cy, r, a1, a2, color, width, steps)
    steps = steps or 6
    local px, py
    for i = 0, steps do
        local t = a1 + (a2 - a1) * (i / steps)
        local x, y = cx + math.cos(t) * r, cy + math.sin(t) * r
        if px then Icons.line(parent, px, py, x, y, color, width) end
        px, py = x, y
    end
end

local function iconLine(x1,y1,x2,y2) return {"line",x1,y1,x2,y2} end
local function iconRing(x,y,r) return {"ring",x,y,r} end
local function iconPoly(points, closed) return {"poly",points,closed == true} end
local function iconArc(cx,cy,r,a1,a2,steps) return {"arc",cx,cy,r,a1,a2,steps or 6} end
local function iconBar(x,y,w,h,rotation) return {"bar",x,y,w,h,rotation or 0} end
local function rect(x1,y1,x2,y2)
    return {iconLine(x1,y1,x2,y1), iconLine(x2,y1,x2,y2), iconLine(x2,y2,x1,y2), iconLine(x1,y2,x1,y1)}
end
local function append(dst, src)
    for _, v in ipairs(src) do dst[#dst+1] = v end
    return dst
end
local function copy(src)
    local out = {}
    for _, v in ipairs(src) do out[#out+1] = v end
    return out
end
local NativeIcons = {}
local function define(name, commands) NativeIcons[name] = commands end
local pi = math.pi

local function gear(teeth)
    local c = {iconRing(.5,.5,.16), iconRing(.5,.5,.31)}
    for i=0,(teeth or 8)-1 do
        local a=i*2*pi/(teeth or 8)
        c[#c+1]=iconLine(.5+math.cos(a)*.33,.5+math.sin(a)*.33,.5+math.cos(a)*.43,.5+math.sin(a)*.43)
    end
    return c
end
local function shieldBase()
    return {iconPoly({{.5,.12},{.8,.23},{.76,.58},{.66,.76},{.5,.88},{.34,.76},{.24,.58},{.2,.23}},true)}
end
local function chartAxes()
    return {iconLine(.18,.16,.18,.82),iconLine(.18,.82,.84,.82)}
end
local function mapBase()
    return {iconPoly({{.16,.24},{.38,.16},{.62,.25},{.84,.17},{.84,.76},{.62,.84},{.38,.75},{.16,.83}},true),iconLine(.38,.16,.38,.75),iconLine(.62,.25,.62,.84)}
end
local function pinBase()
    return {iconRing(.5,.37,.13),iconPoly({{.37,.37},{.4,.56},{.5,.82},{.6,.56},{.63,.37}},false)}
end
local function packageBase(opened)
    local c={iconPoly({{.2,.32},{.5,.16},{.8,.32},{.8,.72},{.5,.86},{.2,.72}},true),iconLine(.2,.32,.5,.48),iconLine(.8,.32,.5,.48),iconLine(.5,.48,.5,.86)}
    if opened then c[#c+1]=iconLine(.2,.32,.12,.22); c[#c+1]=iconLine(.8,.32,.88,.22) end
    return c
end
local function swordBase(flip)
    if not flip then
        return {iconLine(.28,.76,.72,.24),iconLine(.65,.2,.8,.16),iconLine(.8,.16,.76,.31),iconLine(.23,.67,.37,.81),iconLine(.2,.84,.3,.74)}
    end
    return {iconLine(.72,.76,.28,.24),iconLine(.35,.2,.2,.16),iconLine(.2,.16,.24,.31),iconLine(.77,.67,.63,.81),iconLine(.8,.84,.7,.74)}
end
local function eyeBase()
    return {iconArc(.5,.5,.38,pi,2*pi,8),iconArc(.5,.5,.38,0,pi,8),iconRing(.5,.5,.11)}
end
local function gamepadBase()
    return {iconArc(.5,.56,.36,pi,2*pi,8),iconPoly({{.14,.56},{.18,.76},{.3,.82},{.4,.7},{.6,.7},{.7,.82},{.82,.76},{.86,.56}},false),iconLine(.28,.5,.28,.66),iconLine(.2,.58,.36,.58),iconRing(.68,.54,.035),iconRing(.77,.62,.035)}
end
local function coinStack()
    return {iconRing(.4,.62,.18),iconRing(.62,.38,.18),iconLine(.22,.62,.22,.73),iconLine(.58,.38,.58,.49),iconLine(.76,.38,.76,.49)}
end

-- Core / automation
define("settings", gear(8))
define("cog", append(gear(6), {iconRing(.5,.5,.07)}))
define("wrench", {iconArc(.35,.3,.16,-.5,2.2,6),iconLine(.43,.42,.76,.75),iconRing(.78,.78,.07)})
define("hammer", {iconPoly({{.22,.25},{.45,.12},{.58,.26},{.35,.39}},true),iconLine(.4,.36,.76,.78),iconLine(.7,.84,.82,.72)})
define("toolbox", append(rect(.18,.35,.82,.78),{iconPoly({{.36,.35},{.39,.24},{.61,.24},{.64,.35}},false),iconLine(.18,.5,.82,.5),iconLine(.46,.5,.46,.6),iconLine(.54,.5,.54,.6)}))
define("command", {iconArc(.35,.35,.14,pi/2,2*pi,6),iconArc(.65,.35,.14,pi,2.5*pi,6),iconArc(.35,.65,.14,-pi/2,pi,6),iconArc(.65,.65,.14,0,1.5*pi,6),iconLine(.35,.21,.65,.79),iconLine(.21,.35,.79,.65)})
define("terminal", append(rect(.15,.2,.85,.8),{iconLine(.28,.38,.4,.5),iconLine(.4,.5,.28,.62),iconLine(.5,.63,.7,.63)}))
define("code", {iconLine(.38,.28,.2,.5),iconLine(.2,.5,.38,.72),iconLine(.62,.28,.8,.5),iconLine(.8,.5,.62,.72),iconLine(.56,.2,.44,.8)})
define("square-code", append(rect(.14,.14,.86,.86),{iconLine(.42,.34,.3,.5),iconLine(.3,.5,.42,.66),iconLine(.58,.34,.7,.5),iconLine(.7,.5,.58,.66)}))
define("blocks", {iconPoly({{.2,.26},{.36,.18},{.52,.26},{.36,.34}},true),iconPoly({{.48,.48},{.64,.4},{.8,.48},{.64,.56}},true),iconPoly({{.2,.7},{.36,.62},{.52,.7},{.36,.78}},true),iconLine(.36,.34,.36,.62),iconLine(.52,.26,.64,.4)})
define("bot", append(rect(.2,.3,.8,.76),{iconLine(.5,.3,.5,.18),iconRing(.5,.14,.04),iconRing(.36,.5,.045),iconRing(.64,.5,.045),iconLine(.36,.64,.64,.64),iconLine(.12,.44,.2,.44),iconLine(.8,.44,.88,.44)}))
define("brain-circuit", {iconArc(.43,.5,.25,pi/2,3*pi/2,7),iconArc(.57,.5,.25,-pi/2,pi/2,7),iconLine(.5,.25,.5,.75),iconLine(.3,.42,.42,.42),iconLine(.58,.58,.72,.58),iconRing(.27,.42,.03),iconRing(.75,.58,.03),iconLine(.38,.7,.38,.82),iconRing(.38,.85,.03)})
define("sparkles", {iconPoly({{.5,.14},{.56,.39},{.8,.45},{.56,.51},{.5,.76},{.44,.51},{.2,.45},{.44,.39}},true),iconPoly({{.77,.16},{.8,.25},{.89,.28},{.8,.31},{.77,.4},{.74,.31},{.65,.28},{.74,.25}},true)})
define("zap", {iconPoly({{.56,.12},{.24,.55},{.47,.55},{.41,.88},{.76,.43},{.53,.43}},true)})
define("flame", {iconPoly({{.5,.12},{.62,.34},{.58,.47},{.72,.42},{.78,.58},{.72,.76},{.58,.86},{.4,.84},{.25,.72},{.22,.55},{.34,.39},{.38,.58},{.5,.48}},true)})
define("rocket", {iconPoly({{.5,.13},{.65,.27},{.7,.52},{.5,.7},{.3,.52},{.35,.27}},true),iconRing(.5,.38,.08),iconLine(.35,.57,.23,.72),iconLine(.65,.57,.77,.72),iconLine(.45,.73,.4,.87),iconLine(.55,.73,.6,.87)})
define("wand-sparkles", {iconLine(.26,.78,.68,.36),iconLine(.2,.72,.32,.84),iconLine(.62,.3,.74,.42),iconPoly({{.76,.12},{.79,.21},{.88,.24},{.79,.27},{.76,.36},{.73,.27},{.64,.24},{.73,.21}},true)})

-- Security / visual
define("shield", shieldBase())
define("shield-check", append(shieldBase(),{iconLine(.36,.5,.46,.6),iconLine(.46,.6,.66,.38)}))
define("shield-alert", append(shieldBase(),{iconLine(.5,.35,.5,.57),iconRing(.5,.68,.025)}))
define("shield-off", append(shieldBase(),{iconLine(.18,.18,.82,.82)}))
define("lock", append({iconArc(.5,.37,.2,pi,2*pi,7),iconLine(.3,.37,.3,.47),iconLine(.7,.37,.7,.47)}, append(rect(.22,.46,.78,.84), {iconLine(.5,.58,.5,.7)})))
define("lock-keyhole", append({iconArc(.5,.37,.2,pi,2*pi,7),iconLine(.3,.37,.3,.47),iconLine(.7,.37,.7,.47)}, append(rect(.22,.46,.78,.84), {iconRing(.5,.62,.04),iconLine(.5,.66,.5,.73)})))
define("eye", eyeBase())
define("eye-off", append(eyeBase(),{iconLine(.18,.18,.82,.82)}))
define("scan-eye", append(eyeBase(),{iconLine(.15,.3,.15,.15),iconLine(.15,.15,.3,.15),iconLine(.85,.3,.85,.15),iconLine(.85,.15,.7,.15),iconLine(.15,.7,.15,.85),iconLine(.15,.85,.3,.85),iconLine(.85,.7,.85,.85),iconLine(.85,.85,.7,.85)}))
define("fingerprint-pattern", {iconArc(.5,.55,.28,pi,2*pi,8),iconArc(.5,.55,.2,pi,2*pi,7),iconArc(.5,.55,.12,pi,2*pi,6),iconLine(.22,.55,.22,.68),iconLine(.78,.55,.78,.68),iconArc(.5,.68,.28,0,pi,8)})
define("target", {iconRing(.5,.5,.35),iconRing(.5,.5,.18),iconRing(.5,.5,.04)})
define("crosshair", {iconRing(.5,.5,.25),iconLine(.5,.12,.5,.34),iconLine(.5,.66,.5,.88),iconLine(.12,.5,.34,.5),iconLine(.66,.5,.88,.5)})
define("focus", {iconLine(.18,.36,.18,.18),iconLine(.18,.18,.36,.18),iconLine(.82,.36,.82,.18),iconLine(.82,.18,.64,.18),iconLine(.18,.64,.18,.82),iconLine(.18,.82,.36,.82),iconLine(.82,.64,.82,.82),iconLine(.82,.82,.64,.82),iconRing(.5,.5,.1)})
define("radar", {iconRing(.5,.5,.34),iconRing(.5,.5,.2),iconLine(.5,.5,.76,.27),iconRing(.62,.43,.035)})

-- Combat / rewards
define("sword", swordBase(false))
define("swords", append(swordBase(false),swordBase(true)))
define("skull", {iconArc(.5,.43,.3,pi,2*pi,8),iconLine(.2,.43,.24,.7),iconLine(.76,.7,.8,.43),iconLine(.24,.7,.38,.78),iconLine(.62,.78,.76,.7),iconRing(.38,.5,.055),iconRing(.62,.5,.055),iconLine(.45,.68,.45,.8),iconLine(.55,.68,.55,.8)})
define("crown", {iconPoly({{.18,.3},{.34,.56},{.5,.28},{.66,.56},{.82,.3},{.76,.76},{.24,.76}},true),iconLine(.24,.66,.76,.66)})
define("trophy", {iconPoly({{.3,.2},{.7,.2},{.66,.53},{.57,.63},{.43,.63},{.34,.53}},true),iconArc(.28,.35,.16,pi/2,3*pi/2,6),iconArc(.72,.35,.16,-pi/2,pi/2,6),iconLine(.5,.63,.5,.78),iconLine(.36,.82,.64,.82)})
define("medal", {iconRing(.5,.62,.18),iconLine(.38,.46,.28,.18),iconLine(.48,.45,.4,.18),iconLine(.52,.45,.6,.18),iconLine(.62,.46,.72,.18),iconPoly({{.5,.52},{.54,.59},{.62,.6},{.56,.66},{.58,.74},{.5,.7},{.42,.74},{.44,.66},{.38,.6},{.46,.59}},true)})
define("award", {iconRing(.5,.42,.2),iconPoly({{.38,.58},{.32,.86},{.5,.75},{.68,.86},{.62,.58}},false),iconPoly({{.5,.28},{.54,.38},{.65,.38},{.56,.45},{.59,.56},{.5,.5},{.41,.56},{.44,.45},{.35,.38},{.46,.38}},true)})
define("gem", {iconPoly({{.3,.18},{.7,.18},{.84,.38},{.5,.84},{.16,.38}},true),iconLine(.16,.38,.84,.38),iconLine(.3,.18,.4,.38),iconLine(.7,.18,.6,.38),iconLine(.4,.38,.5,.84),iconLine(.6,.38,.5,.84)})
define("coins", coinStack())
define("hand-coins", append(coinStack(),{iconPoly({{.15,.72},{.34,.72},{.48,.82},{.72,.72},{.86,.64}},false),iconLine(.15,.72,.15,.84)}))
define("wallet", append(rect(.16,.28,.84,.76),{iconLine(.16,.38,.72,.38),iconPoly({{.62,.46},{.86,.46},{.86,.66},{.62,.66}},true),iconRing(.69,.56,.025)}))
define("banknote", append(rect(.14,.26,.86,.74),{iconRing(.5,.5,.13),iconLine(.2,.34,.3,.34),iconLine(.7,.66,.8,.66)}))
define("dollar-sign", {iconLine(.5,.16,.5,.84),iconArc(.5,.38,.2,.55*pi,1.5*pi,7),iconArc(.5,.62,.2,-.45*pi,.5*pi,7)})

-- Charts / progression
define("chart-line", append(chartAxes(),{iconPoly({{.26,.68},{.4,.5},{.52,.59},{.72,.31}},false)}))
define("chart-pie", {iconArc(.48,.52,.3,.08*pi,1.5*pi,10),iconLine(.48,.22,.48,.52),iconLine(.48,.52,.77,.52),iconArc(.55,.45,.3,-.5*pi,0,5)})
define("chart-bar", append(chartAxes(),{iconLine(.3,.7,.3,.56),iconLine(.48,.7,.48,.4),iconLine(.66,.7,.66,.28)}))
define("chart-area", append(chartAxes(),{iconPoly({{.22,.68},{.39,.48},{.52,.58},{.74,.3},{.74,.76},{.22,.76}},true)}))
define("chart-column", append(chartAxes(),{iconPoly({{.27,.72},{.27,.57},{.37,.57},{.37,.72}},true),iconPoly({{.45,.72},{.45,.42},{.55,.42},{.55,.72}},true),iconPoly({{.63,.72},{.63,.3},{.73,.3},{.73,.72}},true)}))
define("chart-column-increasing", append(chartAxes(),{iconPoly({{.25,.72},{.25,.62},{.35,.62},{.35,.72}},true),iconPoly({{.43,.72},{.43,.5},{.53,.5},{.53,.72}},true),iconPoly({{.61,.72},{.61,.35},{.71,.35},{.71,.72}},true),iconLine(.28,.46,.7,.22),iconLine(.7,.22,.62,.22),iconLine(.7,.22,.7,.3)}))
define("chart-no-axes-combined", {iconPoly({{.2,.72},{.36,.55},{.5,.62},{.72,.34},{.82,.42}},false),iconLine(.25,.72,.25,.58),iconLine(.45,.72,.45,.48),iconLine(.65,.72,.65,.38)})
define("activity", {iconPoly({{.14,.52},{.3,.52},{.39,.28},{.52,.74},{.62,.44},{.72,.52},{.86,.52}},false)})
define("gauge", {iconArc(.5,.64,.32,pi,2*pi,9),iconLine(.5,.64,.68,.39),iconRing(.5,.64,.04),iconLine(.25,.66,.18,.66),iconLine(.75,.66,.82,.66)})
define("circle-gauge", append({iconRing(.5,.5,.36)}, {iconArc(.5,.57,.24,pi,2*pi,8),iconLine(.5,.57,.66,.39),iconRing(.5,.57,.035)}))
define("trending-up-down", {iconPoly({{.17,.63},{.35,.45},{.49,.57},{.7,.31},{.84,.31}},false),iconLine(.84,.31,.76,.23),iconLine(.84,.31,.76,.39),iconPoly({{.17,.76},{.32,.64},{.48,.73},{.65,.58},{.84,.74}},false)})

-- World / teleport
define("map", mapBase())
define("map-pin", append(mapBase(),pinBase()))
define("map-pinned", append(pinBase(),{iconLine(.18,.74,.38,.66),iconLine(.62,.66,.82,.74),iconLine(.38,.66,.5,.72),iconLine(.5,.72,.62,.66)}))
define("map-pin-search", append(pinBase(),{iconRing(.72,.7,.1),iconLine(.79,.77,.87,.85)}))
define("navigation", {iconPoly({{.5,.12},{.78,.82},{.5,.67},{.22,.82}},true),iconLine(.5,.67,.5,.36)})
define("compass", {iconRing(.5,.5,.36),iconPoly({{.6,.3},{.54,.54},{.3,.6},{.46,.46}},true)})
define("locate", {iconRing(.5,.5,.2),iconLine(.5,.1,.5,.25),iconLine(.5,.75,.5,.9),iconLine(.1,.5,.25,.5),iconLine(.75,.5,.9,.5)})
define("locate-fixed", append({iconRing(.5,.5,.2),iconRing(.5,.5,.04)}, {iconLine(.5,.1,.5,.25),iconLine(.5,.75,.5,.9),iconLine(.1,.5,.25,.5),iconLine(.75,.5,.9,.5)}))
define("signpost", {iconLine(.5,.15,.5,.86),iconPoly({{.24,.26},{.72,.26},{.82,.38},{.72,.5},{.24,.5}},true),iconLine(.38,.86,.62,.86)})
define("signpost-big", {iconLine(.5,.12,.5,.88),iconPoly({{.16,.22},{.7,.22},{.84,.38},{.7,.54},{.16,.54}},true),iconLine(.34,.88,.66,.88)})
define("milestone", {iconLine(.22,.18,.22,.84),iconPoly({{.22,.25},{.7,.25},{.82,.4},{.7,.55},{.22,.55}},true),iconRing(.22,.18,.035),iconRing(.22,.84,.035)})
define("road", {iconLine(.37,.12,.28,.88),iconLine(.63,.12,.72,.88),iconLine(.5,.16,.5,.31),iconLine(.5,.42,.5,.58),iconLine(.5,.69,.5,.84)})
define("waypoints", {iconRing(.25,.28,.09),iconRing(.75,.72,.09),iconLine(.25,.37,.25,.48),iconArc(.5,.5,.25,pi,0,7),iconLine(.75,.52,.75,.63)})
define("house", {iconPoly({{.16,.45},{.5,.18},{.84,.45},{.84,.82},{.62,.82},{.62,.58},{.38,.58},{.38,.82},{.16,.82}},true)})
define("castle", {iconPoly({{.18,.84},{.18,.36},{.28,.36},{.28,.24},{.38,.24},{.38,.36},{.62,.36},{.62,.24},{.72,.24},{.72,.36},{.82,.36},{.82,.84}},false),iconLine(.18,.84,.82,.84),iconArc(.5,.84,.12,pi,2*pi,6),iconLine(.5,.72,.5,.84)})
define("mountain", {iconPoly({{.12,.8},{.39,.3},{.5,.47},{.6,.34},{.88,.8}},false),iconLine(.39,.3,.47,.45),iconLine(.47,.45,.52,.39)})
define("mountain-snow", {iconPoly({{.1,.82},{.36,.28},{.5,.52},{.62,.34},{.9,.82}},false),iconPoly({{.29,.43},{.36,.28},{.44,.42},{.5,.52}},false),iconPoly({{.55,.45},{.62,.34},{.7,.47}},false)})

-- Farming / resources
define("tractor", {iconRing(.3,.72,.15),iconRing(.72,.7,.11),iconPoly({{.25,.57},{.25,.4},{.48,.4},{.58,.6},{.78,.6}},false),iconLine(.48,.4,.48,.24),iconLine(.48,.24,.65,.24),iconLine(.65,.24,.7,.6),iconLine(.2,.57,.12,.57),iconLine(.58,.6,.58,.72)})
define("sprout", {iconLine(.5,.82,.5,.42),iconArc(.38,.42,.18,0,pi,6),iconArc(.62,.52,.18,pi,2*pi,6),iconLine(.5,.42,.32,.27),iconLine(.5,.52,.7,.37)})
define("pickaxe", {iconArc(.48,.31,.28,pi,2*pi,8),iconLine(.48,.31,.72,.78),iconLine(.66,.82,.78,.74)})
define("shovel", {iconLine(.5,.18,.5,.62),iconRing(.5,.18,.07),iconPoly({{.34,.62},{.66,.62},{.6,.82},{.5,.88},{.4,.82}},true)})
define("axe", {iconLine(.56,.25,.38,.82),iconPoly({{.5,.28},{.62,.17},{.82,.27},{.68,.48}},true),iconLine(.32,.84,.45,.78)})
define("leaf", {iconPoly({{.2,.72},{.28,.35},{.58,.18},{.82,.2},{.8,.48},{.58,.75},{.2,.72}},true),iconLine(.22,.72,.7,.3),iconLine(.45,.5,.45,.67),iconLine(.55,.43,.7,.43)})
define("tree-palm", {iconLine(.5,.38,.42,.86),iconLine(.5,.38,.26,.24),iconLine(.5,.38,.72,.2),iconLine(.5,.38,.78,.43),iconLine(.5,.38,.29,.51),iconArc(.28,.26,.14,pi,2*pi,5),iconArc(.72,.22,.14,pi,2*pi,5)})
define("plant-pot", {iconPoly({{.26,.58},{.74,.58},{.68,.84},{.32,.84}},true),iconLine(.5,.58,.5,.32),iconArc(.38,.32,.14,0,pi,5),iconArc(.62,.38,.14,pi,2*pi,5)})
define("fishing-rod", {iconArc(.42,.42,.33,-pi/2,0,8),iconLine(.42,.09,.42,.72),iconLine(.75,.42,.75,.72),iconArc(.75,.78,.06,-pi/2,pi,5)})
define("fishing-hook", {iconLine(.5,.16,.5,.64),iconArc(.5,.65,.2,0,pi,7),iconLine(.3,.65,.3,.56),iconLine(.3,.56,.39,.62)})

-- Inventory / system
define("package", packageBase(false))
define("package-open", packageBase(true))
define("package-search", append(packageBase(false),{iconRing(.72,.7,.1),iconLine(.79,.77,.88,.86)}))
define("boxes", {iconPoly({{.14,.3},{.32,.2},{.5,.3},{.32,.4}},true),iconPoly({{.5,.3},{.68,.2},{.86,.3},{.68,.4}},true),iconPoly({{.32,.58},{.5,.48},{.68,.58},{.5,.68}},true),iconLine(.32,.4,.32,.58),iconLine(.68,.4,.68,.58),iconLine(.5,.3,.5,.48)})
define("backpack", append({iconArc(.5,.34,.2,pi,2*pi,7)}, append(rect(.23,.34,.77,.84), {iconLine(.23,.5,.77,.5),iconPoly({{.36,.34},{.38,.2},{.62,.2},{.64,.34}},false),iconLine(.38,.66,.62,.66)})))
define("shopping-bag", {iconPoly({{.22,.34},{.78,.34},{.74,.84},{.26,.84}},true),iconArc(.5,.36,.18,pi,2*pi,6)})
define("shopping-cart", {iconLine(.14,.22,.24,.22),iconPoly({{.24,.22},{.32,.62},{.72,.62},{.82,.34},{.28,.34}},false),iconLine(.32,.62,.28,.72),iconLine(.28,.72,.72,.72),iconRing(.34,.82,.045),iconRing(.68,.82,.045)})
define("archive", append(rect(.18,.28,.82,.8),{iconPoly({{.14,.18},{.86,.18},{.82,.3},{.18,.3}},true),iconLine(.4,.48,.6,.48)}))
define("database", {iconArc(.5,.28,.3,0,2*pi,10),iconLine(.2,.28,.2,.72),iconLine(.8,.28,.8,.72),iconArc(.5,.5,.3,0,pi,8),iconArc(.5,.72,.3,0,pi,8)})
define("hard-drive", append(rect(.16,.24,.84,.76),{iconLine(.2,.6,.8,.6),iconRing(.72,.68,.035),iconRing(.6,.68,.035)}))
define("cpu", append(rect(.26,.26,.74,.74),{iconPoly({{.36,.36},{.64,.36},{.64,.64},{.36,.64}},true),iconLine(.34,.16,.34,.26),iconLine(.5,.16,.5,.26),iconLine(.66,.16,.66,.26),iconLine(.34,.74,.34,.84),iconLine(.5,.74,.5,.84),iconLine(.66,.74,.66,.84),iconLine(.16,.34,.26,.34),iconLine(.16,.5,.26,.5),iconLine(.16,.66,.26,.66),iconLine(.74,.34,.84,.34),iconLine(.74,.5,.84,.5),iconLine(.74,.66,.84,.66)}))
define("memory-stick", append(rect(.2,.3,.8,.7),{iconLine(.28,.2,.28,.3),iconLine(.42,.2,.42,.3),iconLine(.58,.2,.58,.3),iconLine(.72,.2,.72,.3),iconLine(.28,.7,.28,.8),iconLine(.42,.7,.42,.8),iconLine(.58,.7,.58,.8),iconLine(.72,.7,.72,.8),iconPoly({{.36,.4},{.64,.4},{.64,.6},{.36,.6}},true)}))

-- Player / game / utility
define("gamepad", gamepadBase())
define("gamepad-2", append(gamepadBase(),{iconLine(.43,.22,.57,.22),iconLine(.5,.15,.5,.29)}))
define("joystick", {iconRing(.5,.78,.08),iconLine(.5,.7,.5,.36),iconRing(.5,.26,.12),iconPoly({{.25,.84},{.75,.84},{.7,.7},{.58,.66},{.42,.66},{.3,.7}},false)})
define("dumbbell", {iconLine(.24,.5,.76,.5),iconLine(.22,.34,.22,.66),iconLine(.3,.38,.3,.62),iconLine(.78,.34,.78,.66),iconLine(.7,.38,.7,.62),iconLine(.12,.42,.12,.58),iconLine(.88,.42,.88,.58)})
define("biceps-flexed", {iconArc(.42,.58,.26,.1*pi,1.15*pi,8),iconLine(.18,.64,.32,.78),iconLine(.32,.78,.58,.8),iconArc(.62,.54,.2,pi,2*pi,7),iconLine(.58,.34,.68,.2),iconLine(.68,.2,.8,.27),iconLine(.8,.27,.76,.43)})
define("timer", {iconRing(.5,.55,.3),iconLine(.5,.55,.5,.34),iconLine(.5,.55,.66,.64),iconLine(.42,.16,.58,.16),iconLine(.5,.16,.5,.25),iconLine(.72,.25,.8,.33)})

-- Existing internal icons retained in the same namespace.
define("search", {iconRing(.42,.42,.25),iconLine(.60,.60,.85,.85)})
define("chevron", {iconLine(.22,.38,.50,.65),iconLine(.50,.65,.78,.38)})
define("pencil", {iconLine(.25,.75,.73,.27),iconLine(.32,.80,.80,.32),iconLine(.25,.75,.20,.85)})
define("folder", {iconPoly({{.15,.27},{.4,.27},{.5,.38},{.87,.38},{.87,.8},{.15,.8}},true)})
define("chart", {iconLine(.18,.2,.18,.8),iconLine(.18,.8,.85,.8),iconLine(.36,.66,.36,.5),iconLine(.55,.66,.55,.3),iconLine(.75,.66,.75,.4)})
define("profile", {iconLine(.25,.18,.25,.88),iconPoly({{.25,.2},{.8,.2},{.63,.48},{.25,.48}},true)})
define("flag", copy(NativeIcons.profile))
define("misc", {iconRing(.5,.28,.12),iconLine(.5,.42,.5,.76),iconLine(.5,.76,.23,.76),iconLine(.5,.76,.77,.76)})
define("empty", {iconRing(.5,.5,.40),iconRing(.36,.43,.025),iconRing(.64,.43,.025),iconPoly({{.35,.67},{.43,.61},{.57,.61},{.65,.67}},false)})
define("menu", {iconLine(.18,.28,.82,.28),iconLine(.18,.5,.82,.5),iconLine(.18,.72,.82,.72)})
define("discord", {iconRing(.5,.5,.32),iconRing(.37,.48,.025),iconRing(.63,.48,.025),iconLine(.33,.65,.67,.65)})
define("brand", {iconBar(.24,.22,.58,.14,-28),iconBar(.18,.45,.58,.14,-28),iconBar(.12,.68,.58,.14,-28)})

local function normalizeIconName(name)
    if type(name) ~= "string" then return name end
    local n = string.lower(name)
    n = n:gsub("^%s+", ""):gsub("%s+$", "")
    n = n:gsub("_", "-"):gsub("%s+", "-")
    return n
end
Icons.normalizeName = normalizeIconName
Icons.Native = NativeIcons

function Icons.make(parent, name, size, color, w)
    local root = U.frame(parent, { Size = UDim2.fromOffset(size, size), ZIndex = parent.ZIndex + 1 }, w)
    local normalized = normalizeIconName(name or "settings")
    local asset = Library.Icons[normalized] or Library.Icons[name] or normalized
    if type(asset) == "number" or (type(asset) == "string" and (asset:match("^rbx") or asset:match("^%d+$"))) then
        U.new("ImageLabel", {
            BackgroundTransparency = 1,
            Image = type(asset) == "number" and "rbxassetid://" .. asset
                or (asset:match("^%d+$") and "rbxassetid://" .. asset or asset),
            ImageColor3 = color,
            Size = UDim2.fromScale(1, 1),
            ZIndex = root.ZIndex,
        }, root)
    else
        local commands = NativeIcons[normalized] or NativeIcons.settings
        for _, cmd in ipairs(commands) do
            if cmd[1] == "line" then
                Icons.line(root, cmd[2], cmd[3], cmd[4], cmd[5], color)
            elseif cmd[1] == "ring" then
                Icons.ring(root, cmd[2], cmd[3], cmd[4], color)
            elseif cmd[1] == "poly" then
                Icons.poly(root, cmd[2], color, nil, cmd[3])
            elseif cmd[1] == "arc" then
                Icons.arc(root, cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], color, nil, cmd[7])
            elseif cmd[1] == "bar" then
                U.new("Frame", {
                    Position = UDim2.fromScale(cmd[2], cmd[3]),
                    Size = UDim2.fromScale(cmd[4], cmd[5]),
                    Rotation = cmd[6],
                    BackgroundTransparency = 0,
                    BackgroundColor3 = color,
                    ZIndex = root.ZIndex,
                }, root)
            end
        end
    end
    return root
end
function Icons.color(root, color)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("ImageLabel") then
            obj.ImageColor3 = color
        elseif obj:IsA("Frame") and obj.BackgroundTransparency == 0 then
            obj.BackgroundColor3 = color
        elseif obj:IsA("UIStroke") then
            obj.Color = color
        end
    end
end

-- Exactly one drag capture and three global input connections per window. Touch identity is retained.
function Input.new(w)
    local self = setmetatable({ w = w }, { __index = Input })
    U.connect(w.bag, S.Input.InputChanged, function(event)
        if w.tooltip then
            w.tooltip:Changed(event)
        end
        local cap = self.capture
        if not cap then
            return
        end
        if
            (cap.touch and event == cap.input)
            or (not cap.touch and event.UserInputType == Enum.UserInputType.MouseMovement)
        then
            cap.move(U.point(event))
        end
    end)
    U.connect(w.bag, S.Input.InputEnded, function(event)
        if w.tooltip then
            w.tooltip:Ended(event)
        end
        for control, input in pairs(w.pressed) do
            if
                input == event
                or (
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    and event.UserInputType == Enum.UserInputType.MouseButton1
                )
            then
                w.pressed[control] = nil
                control.state.Pressed = false
                control:_render()
            end
        end
        local cap = self.capture
        if
            cap
            and (
                (cap.touch and event == cap.input)
                or (not cap.touch and event.UserInputType == Enum.UserInputType.MouseButton1)
            )
        then
            self:Cancel()
        end
    end)
    U.connect(w.bag, S.Input.WindowFocusReleased, function()
        if w.tooltip then
            w.tooltip:Cancel()
        end
        self:Cancel()
        for control in pairs(w.pressed) do
            control.state.Pressed = false
            control:_render()
            w.pressed[control] = nil
        end
    end)
    return self
end
function Input:CanStart(event)
    local cap = self.capture
    return U.primary(event)
        and not self.w.destroyed
        and self.w.visible
        and not (cap and cap.touch and event ~= cap.input)
end
function Input:Start(owner, event, move, finish)
    if not self:CanStart(event) then
        return false
    end
    self:Cancel()
    if self.w.tooltip then
        self.w.tooltip:Cancel()
    end
    self.capture = {
        owner = owner,
        input = event,
        touch = event.UserInputType == Enum.UserInputType.Touch,
        move = move,
        finish = finish,
    }
    move(U.point(event))
    return true
end
function Input:Cancel(owner)
    local cap = self.capture
    if cap and (not owner or cap.owner == owner) then
        self.capture = nil
        if cap.finish then
            cap.finish()
        end
    end
end

function Overlay.new(w)
    return setmetatable({ w = w }, { __index = Overlay })
end
function Overlay:Place()
    local a = self.active
    if not a then
        return
    end
    local w = self.w
    local p = a.anchor.AbsolutePosition - w.stage.AbsolutePosition
    local sz = a.anchor.AbsoluteSize
    local view = w.stage.AbsoluteSize
    local scale = w.scale
    local width, height = a.width * scale, a.height * scale
    local x = math.clamp(p.X + sz.X - width, 8, math.max(8, view.X - width - 8))
    local y = p.Y + sz.Y + 4 * scale
    if y + height > view.Y - 8 then
        y = p.Y - height - 4 * scale
    end
    y = math.clamp(y, 8, math.max(8, view.Y - height - 8))
    a.holder.Position = UDim2.fromOffset(x, y)
end
function Overlay:Open(owner, anchor, width, height, build, allowLocked)
    self:Close(true)
    if self.w.tooltip then
        self.w.tooltip:Cancel()
    end
    local w = self.w
    local usable = owner:_usable() or (allowLocked and owner.state.Locked and owner._available and owner:_available())
    if w.destroyed or not w.visible or w.searchOpen or not usable then
        return
    end
    local bag = Maid.new(w.motion)
    local holder = U.frame(
        w.popoverLayer,
        { Name = "FloatingAnchor", Size = UDim2.fromOffset(width * w.scale, height * w.scale), ZIndex = T.Z.Popover },
        w
    )
    bag:Add(holder)
    local group = U.new("CanvasGroup", {
        Name = "Popover",
        Size = UDim2.fromOffset(width, height),
        GroupTransparency = 1,
        Position = UDim2.fromOffset(0, 4),
        BackgroundTransparency = 0,
        BackgroundColor3 = w.theme.PopoverBackground,
        ZIndex = T.Z.Popover,
    }, holder)
    U.new("UIScale", { Scale = w.scale }, group)
    U.corner(group, T.Radius.Popover)
    local edge = U.stroke(group, w.theme.SurfaceEdge, 1)
    edge.Transparency = 0.55
    U.bind(w, edge, "Color", "SurfaceEdge")
    U.bind(w, group, "BackgroundColor3", "PopoverBackground")
    self.active =
        { owner = owner, anchor = anchor, width = width, height = height, holder = holder, group = group, bag = bag }
    owner.state.Open = true
    owner:_render()
    build(group, bag)
    self:Place()
    w:_dimState(true, 0.46)
    w.motion:To(group, T.Motion.Normal, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
    U.connect(bag, anchor:GetPropertyChangedSignal("AbsolutePosition"), function()
        self:Place()
    end)
end
function Overlay:Close(immediate)
    if immediate and self.closing then
        self.closing.bag:Destroy()
        self.closing = nil
    end
    local a = self.active
    if not a then
        return
    end
    self.active = nil
    local w = self.w
    w.input:Cancel(a.owner)
    a.owner.state.Open = false
    if not a.owner.destroyed then
        a.owner:_render()
    end
    w.motion:Cancel(a.group)
    if immediate or w.destroyed then
        a.bag:Destroy()
    else
        local closing = a
        self.closing = closing
        w.motion:To(a.group, T.Motion.Fast, { GroupTransparency = 1, Position = UDim2.fromOffset(0, 4) })
        a.bag:After(T.Motion.Fast, function()
            a.bag:Destroy()
            if self.closing == closing then
                self.closing = nil
            end
        end)
    end
    if self.closing and immediate then
        self.closing.bag:Destroy()
        self.closing = nil
    end
    if not w.searchOpen then
        w:_dimState(false, 1, immediate)
    end
end
function Overlay:Destroy()
    self:Close(true)
    if self.closing then
        self.closing.bag:Destroy()
        self.closing = nil
    end
end

function Scroll.make(w, parent, bag, inset, thin)
    local sf = U.new("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 0,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        CanvasPosition = Vector2.new(),
        ZIndex = parent.ZIndex + 1,
    }, parent)
    local layout = U.new(
        "UIListLayout",
        { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, inset or T.Geometry.RowGap) },
        sf
    )
    local rail = U.button(parent, {
        Name = "CustomScrollbar",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -(thin and 2 or T.Geometry.ScrollInset), 0, 0),
        Size = UDim2.new(0, thin and 12 or 18, 1, 0),
        ZIndex = parent.ZIndex + 3,
    })
    local thumb = U.frame(rail, {
        Name = "Thumb",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(thin and 3 or T.Geometry.Scrollbar, 32),
        ZIndex = rail.ZIndex,
    }, w, "Accent")
    U.corner(thumb, 2)
    local scroll = { frame = sf, layout = layout, rail = rail, thumb = thumb }
    function scroll:Update()
        if not sf.Parent then
            return
        end
        local scale = w.scale
        local padding = sf:FindFirstChildOfClass("UIPadding")
        local inset = padding and (padding.PaddingTop.Offset + padding.PaddingBottom.Offset) or 0
        local content = layout.AbsoluteContentSize.Y / scale + inset + 4
        sf.CanvasSize = UDim2.fromOffset(0, content)
        local view = sf.AbsoluteSize.Y / scale
        local maximum = math.max(0, content - view)
        if sf.CanvasPosition.Y < 0 or sf.CanvasPosition.Y > maximum then
            sf.CanvasPosition = Vector2.new(0, math.clamp(sf.CanvasPosition.Y, 0, maximum))
        end
        rail.Visible = maximum > 1
        local h = math.min(view, math.max(thin and 18 or 28, view * view / math.max(content, 1)))
        thumb.Size = UDim2.fromOffset(thin and 3 or T.Geometry.Scrollbar, h)
        thumb.Position =
            UDim2.new(1, 0, 0, maximum > 0 and math.clamp(sf.CanvasPosition.Y, 0, maximum) / maximum * (view - h) or 0)
        self.maximum = maximum
        self.travel = view - h
    end
    U.connect(bag, layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        scroll:Update()
    end)
    U.connect(bag, sf:GetPropertyChangedSignal("AbsoluteSize"), function()
        scroll:Update()
    end)
    U.connect(bag, sf:GetPropertyChangedSignal("CanvasPosition"), function()
        if w.tooltip then
            w.tooltip:Cancel()
        end
        scroll:Update()
        local a = w.overlay.active
        if a and a.owner.page and a.owner.page.scroll.frame == sf then
            w.overlay:Close(true)
        end
    end)
    U.connect(bag, rail.InputBegan, function(event)
        if not U.primary(event) then
            return
        end
        scroll:Update()
        local start = U.point(event)
        local canvas = sf.CanvasPosition.Y
        local onThumb = U.inside(thumb, start)
        w.input:Start(scroll, event, function(p)
            local ratio
            if onThumb then
                ratio = (p.Y - start.Y) / (math.max(1, scroll.travel) * w.scale)
                sf.CanvasPosition = Vector2.new(0, math.clamp(canvas + ratio * scroll.maximum, 0, scroll.maximum))
            else
                ratio = (p.Y - rail.AbsolutePosition.Y) / (math.max(1, rail.AbsoluteSize.Y))
                sf.CanvasPosition = Vector2.new(0, math.clamp(ratio * scroll.maximum, 0, scroll.maximum))
            end
        end)
    end)
    bag:Add(function()
        w.input:Cancel(scroll)
    end)
    scroll:Update()
    return scroll
end

function Window:_dimState(visible, transparency, immediate)
    if visible and self.tooltip then
        self.tooltip:Cancel()
    end
    Geometry.layout(self)
    if self.settingsOpen and not visible then
        visible = true
        transparency = 0.38
    end
    self.dimGeneration = (self.dimGeneration or 0) + 1
    local generation = self.dimGeneration
    if self.dimCancel then
        self.bag:Remove(self.dimCancel, true)
        self.dimCancel = nil
    end
    if visible then
        self.dim.Visible = true
    end
    self.motion:To(self.dim, immediate and 0 or T.Motion.Normal, { BackgroundTransparency = transparency })
    if not visible then
        if immediate then
            self.dim.Visible = false
        else
            self.dimCancel = self.bag:After(T.Motion.Normal, function()
                if generation == self.dimGeneration and not self.searchOpen and not self.overlay.active then
                    self.dim.Visible = false
                end
                self.dimCancel = nil
            end)
        end
    end
end
function Window:_canNavigate()
    return not self.destroyed and self.visible
end
function Window:_selectTab(tab)
    if self.tooltip then
        self.tooltip:Cancel()
    end
    if not self:_canNavigate() or tab.destroyed or tab.disabled or not tab.visible then
        return
    end
    if self.settingsOpen then
        self:CloseSettings(true)
    end
    self.overlay:Close(true)
    self.input:Cancel()
    self:CloseSearch(true)
    U.focusRelease(self)
    local previous = self.activeTab
    if previous and previous ~= tab then
        previous.header.Visible = false
        previous.strip.Visible = false
        if previous.activeSub then
            previous.activeSub.host.Visible = false
            self.motion:Cancel(previous.activeSub.host)
        end
    end
    self.activeTab = tab
    tab.header.Visible = true
    tab.strip.Visible = true
    for _, other in ipairs(self.tabs) do
        other:_render()
    end
    local sub = tab.activeSub
    if not sub or sub.destroyed or not sub.visible or sub.disabled then
        sub = nil
        for _, candidate in ipairs(tab.subtabs) do
            if candidate.visible and not candidate.disabled then
                sub = candidate
                break
            end
        end
    end
    if sub then
        tab:_selectSub(sub)
    end
    if self.compact then
        self:SetSidebarVisible(false)
    end
end
function Window:SetTitle(name)
    if self.destroyed then
        return self
    end
    self.name = tostring(name or "")
    self.brand.Text = self.name
    self:_brandLayout()
    return self
end
function Window:SetSuffix(text)
    if self.destroyed then
        return self
    end
    self.suffixLabel.Text = tostring(text or "")
    self:_brandLayout()
    return self
end
function Window:_brandLayout()
    local width = math.min(110, math.ceil(U.width(self.name, T.Type.Brand, Enum.Font.GothamBold)) + 2)
    self.brand.Size = UDim2.fromOffset(width, 28)
    self.suffixLabel.Position = UDim2.fromOffset(82 + width, 23)
end
function Window:SetAccent(color)
    assert(typeof(color) == "Color3", "Neron SetAccent expects Color3")
    if not self.destroyed then
        self.customAccent = color
        Presentation.remember(self)
        Presentation.apply(self)
        if self.persistence then
            self.persistence:QueuePresentation()
        end
    end
    return self
end
function Window:SetVisible(value)
    if self.destroyed then
        return self
    end
    self.visible = value == true
    if not self.visible then
        if self.tooltip then
            self.tooltip:Cancel()
        end
        self.overlay:Close(true)
        self:CloseSearch(true)
        self.input:Cancel()
        U.focusRelease(self)
    end
    if not self.visible and self.CloseSettings then
        self:CloseSettings(true)
    end
    self.gui.Enabled = self.visible
    Geometry.layout(self)
    if self.visible and not self.activeTab then
        for _, tab in ipairs(self.tabs) do
            if tab.visible and not tab.disabled then
                tab:Select()
                break
            end
        end
    end
    return self
end
function Window:SetSidebarVisible(value)
    if self.destroyed then
        return self
    end
    self.sidebarOpen = value == true
    self.sidebar.Visible = not self.compact or self.sidebarOpen
    self.drawerShade.Visible = self.compact and self.sidebarOpen
    self.sidebar.ZIndex = self.compact and 12 or T.Z.Shell
    return self
end
function Window:_responsive(preserveCapture)
    if self.destroyed then
        return
    end
    self.overlay:Close(true)
    if self.tooltip then
        self.tooltip:Cancel()
    end
    if not preserveCapture then
        self.input:Cancel()
    end
    local view = self.stage.AbsoluteSize
    if view.X <= 0 or view.Y <= 0 then
        return
    end
    if self.defaultDesktopSize then
        self.baseWidth = math.clamp(T.Geometry.DesktopWidth, self.minimumSize.X, self.maximumSize.X)
        self.baseHeight = math.clamp(T.Geometry.DesktopHeight, self.minimumSize.Y, self.maximumSize.Y)
    end
    local portrait = view.X < 600 or (view.Y > view.X and view.X < 900)
    local width = portrait and math.max(320, self.manualSize and math.min(self.baseWidth, view.X - 16) or view.X - 16)
        or self.baseWidth
    local floorHeight = self.manualSize and math.min(400, self.baseHeight) or 400
    local height = portrait and math.max(floorHeight, math.min(self.baseHeight, view.Y - 24)) or self.baseHeight
    local drawer = portrait or width < 480
    self.scale = math.min(1, (view.X - 16) / width, (view.Y - 24) / height)
    self.scale = math.max(0.30, self.scale)
    self.compact = drawer
    self.root.Size = UDim2.fromOffset(width, height)
    self.uiScale.Scale = self.scale
    local side = drawer and 0 or T.Geometry.Sidebar
    self.content.Position = UDim2.fromOffset(side, 0)
    self.content.Size = UDim2.new(1, -side, 1, 0)
    self.menu.Visible = drawer
    self.sidebar.Size = UDim2.new(0, T.Geometry.Sidebar, 1, 0)
    self:SetSidebarVisible(self.sidebarOpen and drawer)
    self.searchPanel.Position = UDim2.new(0, drawer and 12 or T.Geometry.SearchInset, 0, T.Geometry.Header)
    self.searchPanel.Size = UDim2.new(1, -(drawer and 24 or T.Geometry.SearchInset * 2), 1, -T.Geometry.Header - 18)
    for _, tab in ipairs(self.tabs) do
        tab.title.Position = UDim2.fromOffset(drawer and 48 or 16, 10)
        tab.description.Position = UDim2.fromOffset(drawer and 48 or 16, 32)
        for _, sub in ipairs(tab.subtabs) do
            local reserve = self.resizeEnabled and not self.compact and 44 or 0
            sub.scroll.frame.Size = UDim2.new(1, -T.Geometry.ContentRight, 1, -reserve)
            sub.scroll.rail.Size = UDim2.new(0, 18, 1, -reserve)
            for _, control in ipairs(sub.controls) do
                control:_layout()
            end
            sub.scroll:Update()
        end
    end
    if self.settingsButton then
        SettingsUI.footerLayout(self)
    end
    if self.settingsPanel then
        SettingsUI.layout(self)
    end
    SettingsUI.transientLayout(self)
    local size = Vector2.new(width * self.scale, height * self.scale)
    local center = self.root.Position
    local x = center.X.Scale * view.X + center.X.Offset
    local y = center.Y.Scale * view.Y + center.Y.Offset
    x = math.clamp(x, size.X * 0.5, math.max(size.X * 0.5, view.X - size.X * 0.5))
    y = math.clamp(y, size.Y * 0.5, math.max(size.Y * 0.5, view.Y - size.Y * 0.5))
    self.root.Position = UDim2.fromOffset(x, y)
    Geometry.layout(self)
end
function Window:Destroy()
    if self.destroyed then
        return
    end
    if self.tooltip then
        self.tooltip:Cancel()
    end
    if self.geometryCancel then
        self.bag:Remove(self.geometryCancel, true)
        self.geometryCancel = nil
        Geometry.flush(self)
    end
    if self.persistence and self.persistence.presentationCancel then
        self.bag:Remove(self.persistence.presentationCancel, true)
        self.persistence.presentationCancel = nil
        self.persistence:SavePresentation()
    end
    self:CloseSettings(true)
    self.destroyed = true
    self.overlay:Destroy()
    self.input:Cancel()
    U.focusRelease(self)
    for i = #self.tabs, 1, -1 do
        self.tabs[i]:Destroy()
    end
    if self.searchResultsBag then
        self.searchResultsBag:Destroy()
    end
    if self.settingsPages then
        for _, page in pairs(self.settingsPages) do
            for i = #page.controls, 1, -1 do
                page.controls[i]:Destroy()
            end
            page.bag:Destroy()
        end
    end
    if self.profileListBag then
        self.profileListBag:Destroy()
    end
    if self.toastBag then
        self.toastBag:Destroy()
    end
    self.toastBag, self.toastGroup = nil, nil
    self.motion:Destroy()
    self.bag:Destroy()
    if Library.windows then
        Library.windows[self] = nil
    end
    if self.registry[self.id] == self then
        self.registry[self.id] = nil
    end
    table.clear(self.index)
    table.clear(self.Flags)
    table.clear(self.bindings)
    if self.localeBindings then
        table.clear(self.localeBindings)
    end
end
function Window:AddTab(config)
    assert(not self.destroyed, "Neron window is destroyed")
    config = config or {}
    local categoryName = tostring(config.Category or "GENERAL"):upper()
    local category = self.categories[categoryName]
    if not category then
        self.categorySerial = (self.categorySerial or 0) + 1
        local box = U.frame(self.sidebarScroll.frame, {
            Name = categoryName,
            Size = UDim2.new(1, -10, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = self.categorySerial,
            ZIndex = self.sidebar.ZIndex + 1,
        }, self)
        local layout = U.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, box)
        local heading = U.label(box, categoryName, T.Type.Category, self.theme.TextSecondary, {
            Size = UDim2.new(1, -16, 0, T.Geometry.Category),
            Position = UDim2.fromOffset(10, 0),
            Font = Enum.Font.GothamBold,
            LayoutOrder = 0,
        })
        U.new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, box)
        U.bind(self, heading, "TextColor3", "TextSecondary")
        category = { box = box, layout = layout, tabs = {} }
        self.categories[categoryName] = category
        table.insert(self.categoryOrder, category)
    end
    local tab = setmetatable({
        window = self,
        bag = Maid.new(self.motion),
        name = tostring(config.Name or "Tab"),
        descriptionText = tostring(config.Description or ""),
        tooltipText = config.Tooltip or config.ToolTip,
        visible = config.Visible ~= false,
        disabled = config.Disabled == true,
        subtabs = {},
        category = category,
    }, Tab)
    table.insert(self.tabs, tab)
    table.insert(category.tabs, tab)
    category.tabSerial = (category.tabSerial or 0) + 1
    tab.row = U.button(category.box, {
        Name = tab.name,
        Size = UDim2.new(1, -4, 0, T.Geometry.SidebarTab),
        LayoutOrder = category.tabSerial,
        ZIndex = self.sidebar.ZIndex + 2,
        Visible = tab.visible,
    })
    tab.bag:Add(tab.row)
    U.corner(tab.row, T.Radius.Row)
    tab.icon = Icons.make(tab.row, config.Icon or "settings", 14, self.theme.TextSecondary, self)
    tab.icon.Position = UDim2.new(0, 16, 0, 0.5 * T.Geometry.SidebarTab - 7)
    tab.label = U.label(
        tab.row,
        tab.name,
        T.Type.Tab,
        self.theme.TextSecondary,
        { Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -48, 1, 0), Font = Enum.Font.GothamMedium }
    )
    tab.header = U.frame(
        self.content,
        { Name = "Header", Size = UDim2.new(1, 0, 0, T.Geometry.Header), Visible = false, ZIndex = T.Z.Content },
        self,
        "HeaderBackground"
    )
    tab.bag:Add(tab.header)
    tab.title = U.label(tab.header, tab.name, T.Type.PageTitle, self.theme.TextPrimary, {
        Position = UDim2.fromOffset(self.compact and 48 or 16, 10),
        Size = UDim2.new(1, -72, 0, 22),
        Font = Enum.Font.GothamBold,
    })
    tab.description = U.label(
        tab.header,
        tab.descriptionText,
        T.Type.PageSubtitle,
        self.theme.TextMuted,
        { Position = UDim2.fromOffset(self.compact and 48 or 16, 32), Size = UDim2.new(1, -72, 0, 18) }
    )
    U.bind(self, tab.title, "TextColor3", "TextPrimary")
    U.bind(self, tab.description, "TextColor3", "TextMuted")
    tab.strip = U.frame(self.content, {
        Name = "SubTabs",
        Position = UDim2.fromOffset(0, T.Geometry.Header),
        Size = UDim2.new(1, -26, 0, T.Geometry.Strip),
        Visible = false,
        ZIndex = T.Z.Content,
    }, self)
    tab.bag:Add(tab.strip)
    tab.stripScroll = U.new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -1),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ScrollBarThickness = 0,
        ZIndex = tab.strip.ZIndex,
    }, tab.strip)
    tab.stripLayout = U.new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    }, tab.stripScroll)
    U.new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, tab.stripScroll)
    U.frame(
        tab.strip,
        { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), ZIndex = tab.strip.ZIndex },
        self,
        "Separator"
    )
    tab.indicator = U.frame(tab.stripScroll, {
        Name = "ActiveIndicator",
        Size = UDim2.fromOffset(0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        ZIndex = tab.strip.ZIndex + 3,
    }, self, "Accent")
    -- The shared indicator is outside the layout's sibling set.
    tab.indicator.Parent = tab.strip
    Tooltip.bind(self, tab, tab.row, tab.bag, function()
        return tab.tooltipText or tab.descriptionText
    end, function()
        return tab.visible and not tab.disabled and not self.settingsOpen
    end)
    U.connect(tab.bag, tab.row.Activated, function()
        if Tooltip.blocked(self, tab) then
            return
        end
        self:_selectTab(tab)
    end)
    U.connect(tab.bag, tab.row.MouseEnter, function()
        tab.hover = true
        tab:_render()
    end)
    U.connect(tab.bag, tab.row.MouseLeave, function()
        tab.hover = false
        tab:_render()
    end)
    tab:_render()
    if not self.activeTab and tab.visible and not tab.disabled then
        self:_selectTab(tab)
    end
    return tab
end
function Tab:_render()
    if self.destroyed then
        return
    end
    local w = self.window
    local selected = w.activeTab == self
    local color = self.disabled and w.theme.TextDisabled
        or ((selected or self.hover) and w.theme.TextPrimary or w.theme.TextSecondary)
    w.motion:To(self.label, T.Motion.Micro, { TextColor3 = color })
    Icons.color(self.icon, selected and w.theme.Accent or color)
    w.motion:To(
        self.row,
        T.Motion.Micro,
        { BackgroundColor3 = w.theme.RowHover, BackgroundTransparency = (selected or self.hover) and 0.12 or 1 }
    )
end
function Tab:_selectSub(sub)
    if self.window.tooltip then
        self.window.tooltip:Cancel()
    end
    local w = self.window
    if
        not w:_canNavigate()
        or self.destroyed
        or self.disabled
        or not self.visible
        or sub.destroyed
        or sub.disabled
        or not sub.visible
    then
        return
    end
    if w.activeTab ~= self then
        w:_selectTab(self)
    end
    if w.settingsOpen then
        w:CloseSettings(true)
    end
    w.overlay:Close(true)
    w.input:Cancel()
    w:CloseSearch(true)
    U.focusRelease(w)
    for _, other in ipairs(self.subtabs) do
        if other ~= sub then
            other.host.Visible = false
            w.motion:Cancel(other.host)
        end
    end
    self.activeSub = sub
    sub.host.Visible = true
    w.motion:Cancel(sub.host)
    sub.host.GroupTransparency = 0.65
    sub.host.Position = UDim2.fromOffset(-12, T.Geometry.ContentTop)
    w.motion:To(
        sub.host,
        T.Motion.Structural,
        { GroupTransparency = 0, Position = UDim2.fromOffset(0, T.Geometry.ContentTop) }
    )
    for _, other in ipairs(self.subtabs) do
        other:_render()
    end
    self:_indicator()
end
function Tab:_indicator()
    local sub = self.activeSub
    if not sub or sub.destroyed then
        self.indicator.Visible = false
        return
    end
    self.indicator.Visible = self.window.activeTab == self
    local x = (sub.button.AbsolutePosition.X - self.strip.AbsolutePosition.X) / self.window.scale
    self.window.motion:To(
        self.indicator,
        T.Motion.Fast,
        { Position = UDim2.new(0, x - 8, 1, -1), Size = UDim2.fromOffset(sub.button.Size.X.Offset + 8, 1) }
    )
end
function Tab:AddSubTab(config)
    assert(not self.destroyed, "Neron tab is destroyed")
    config = config or {}
    local w = self.window
    local sub = setmetatable({
        window = w,
        tab = self,
        bag = Maid.new(w.motion),
        name = tostring(config.Name or "General"),
        visible = config.Visible ~= false,
        disabled = config.Disabled == true,
        controls = {},
        tooltipText = config.Tooltip or config.ToolTip,
    }, SubTab)
    table.insert(self.subtabs, sub)
    self.subSerial = (self.subSerial or 0) + 1
    local width = math.ceil(U.width(sub.name, T.Type.SubTab, Enum.Font.GothamMedium)) + 20 + (config.Icon and 20 or 0)
    sub.button = U.button(self.stripScroll, {
        Name = sub.name,
        Size = UDim2.fromOffset(width, T.Geometry.Strip - 1),
        LayoutOrder = self.subSerial,
        Visible = sub.visible,
        ZIndex = self.strip.ZIndex + 1,
    })
    sub.bag:Add(sub.button)
    sub.label = U.label(sub.button, sub.name, T.Type.SubTab, w.theme.TextMuted, {
        Position = UDim2.fromOffset(config.Icon and 28 or 8, 0),
        Size = UDim2.new(1, -(config.Icon and 28 or 8), 1, 0),
        Font = Enum.Font.GothamMedium,
    })
    if config.Icon then
        sub.icon = Icons.make(sub.button, config.Icon, 12, w.theme.TextMuted, w)
        sub.icon.Position = UDim2.new(0, 8, 0.5, -6)
    end
    sub.host = U.new("CanvasGroup", {
        Name = "Page",
        Position = UDim2.fromOffset(0, T.Geometry.ContentTop),
        Size = UDim2.new(1, 0, 1, -T.Geometry.ContentTop),
        GroupTransparency = 0,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = T.Z.Content,
    }, w.content)
    sub.bag:Add(sub.host)
    sub.scroll = Scroll.make(w, sub.host, sub.bag)
    local reserve = w.resizeEnabled and not w.compact and 44 or 0
    sub.scroll.frame.Size = UDim2.new(1, -T.Geometry.ContentRight, 1, -reserve)
    sub.scroll.rail.Size = UDim2.new(0, 18, 1, -reserve)
    sub.scroll.frame.Position = UDim2.fromOffset(T.Geometry.ContentLeft, 0)
    Tooltip.bind(w, sub, sub.button, sub.bag, function()
        return sub.tooltipText or ""
    end, function()
        return sub.visible
            and not sub.disabled
            and self.visible
            and not self.disabled
            and w.activeTab == self
            and not w.settingsOpen
    end)
    U.connect(sub.bag, sub.button.Activated, function()
        if not sub.disabled and not Tooltip.blocked(w, sub) then
            self:_selectSub(sub)
        end
    end)
    U.connect(sub.bag, sub.button.MouseEnter, function()
        sub.hover = true
        sub:_render()
    end)
    U.connect(sub.bag, sub.button.MouseLeave, function()
        sub.hover = false
        sub:_render()
    end)
    U.connect(sub.bag, sub.button:GetPropertyChangedSignal("AbsolutePosition"), function()
        if self.activeSub == sub then
            self:_indicator()
        end
    end)
    sub:_render()
    if not self.activeSub and sub.visible and not sub.disabled then
        self.activeSub = sub
        if w.activeTab == self then
            self:_selectSub(sub)
        end
    end
    return sub
end
function Tab:Select()
    self.window:_selectTab(self)
    return self
end
function Tab:SetName(name)
    if self.destroyed then
        return self
    end
    self.name = tostring(name)
    self.label.Text = self.name
    self.window:_indexChanged()
    self.title.Text = self.name
    return self
end
function Tab:SetDescription(text)
    if self.destroyed then
        return self
    end
    self.descriptionText = tostring(text or "")
    self.description.Text = self.descriptionText
    self.window:_indexChanged()
    return self
end
function Tab:_fallback()
    if self.window.activeTab == self then
        self.window.overlay:Close(true)
        self.window.input:Cancel()
        self.window:CloseSearch(true)
        U.focusRelease(self.window)
        self.header.Visible = false
        self.strip.Visible = false
        if self.activeSub then
            self.activeSub.host.Visible = false
        end
        self.window.activeTab = nil
        for _, other in ipairs(self.window.tabs) do
            if other ~= self and not other.destroyed and other.visible and not other.disabled then
                other:Select()
                break
            end
        end
    end
end
function Tab:SetVisible(value)
    if self.destroyed then
        return self
    end
    if self.window.tooltip then
        self.window.tooltip:Cancel()
    end
    self.visible = value == true
    self.row.Visible = self.visible
    if not self.visible then
        self:_fallback()
    elseif not self.disabled and not self.window.activeTab then
        self:Select()
    end
    self.window:_indexChanged()
    return self
end
function Tab:SetDisabled(value)
    if self.destroyed then
        return self
    end
    if self.window.tooltip then
        self.window.tooltip:Cancel()
    end
    self.disabled = value == true
    if self.disabled then
        self:_fallback()
    elseif self.visible then
        self:SetVisible(true)
    end
    self:_render()
    self.window:_indexChanged()
    return self
end
function Tab:Destroy()
    if self.destroyed then
        return
    end
    self:_fallback()
    self.destroyed = true
    for i = #self.subtabs, 1, -1 do
        self.subtabs[i]:Destroy()
    end
    U.remove(self.window.tabs, self)
    U.remove(self.category.tabs, self)
    self.bag:Destroy()
    if #self.category.tabs == 0 then
        self.category.box:Destroy()
        U.remove(self.window.categoryOrder, self.category)
        for name, category in pairs(self.window.categories) do
            if category == self.category then
                self.window.categories[name] = nil
            end
        end
    end
end
function SubTab:_render()
    if self.destroyed then
        return
    end
    local w = self.window
    local active = self.tab.activeSub == self
    local c = self.disabled and w.theme.TextDisabled
        or ((active or self.hover) and w.theme.TextPrimary or w.theme.TextMuted)
    w.motion:To(self.label, T.Motion.Micro, { TextColor3 = c })
    local withIcon = self.icon and active
    self.label.Position = UDim2.fromOffset(withIcon and 25 or 8, 0)
    self.label.Size = UDim2.new(1, -(withIcon and 25 or 8), 1, 0)
    self.button.Size = UDim2.fromOffset(
        math.ceil(U.width(self.name, T.Type.SubTab, Enum.Font.GothamMedium)) + 20 + (withIcon and 20 or 0),
        T.Geometry.Strip - 1
    )
    if self.icon then
        self.icon.Visible = active
        Icons.color(self.icon, active and w.theme.Accent or c)
    end
end
function SubTab:Select()
    self.tab:_selectSub(self)
    return self
end
function SubTab:SetName(name)
    if self.destroyed then
        return self
    end
    self.name = tostring(name)
    self.label.Text = self.name
    self.window:_indexChanged()
    self:_render()
    self.tab:_indicator()
    return self
end
function SubTab:_fallback()
    if self.tab.activeSub == self then
        self.window.overlay:Close(true)
        self.window.input:Cancel()
        U.focusRelease(self.window)
        self.host.Visible = false
        self.tab.activeSub = nil
        for _, other in ipairs(self.tab.subtabs) do
            if other ~= self and other.visible and not other.disabled and not other.destroyed then
                self.tab.activeSub = other
                if self.window.activeTab == self.tab then
                    other:Select()
                end
                break
            end
        end
        self.tab:_indicator()
    end
end
function SubTab:SetVisible(value)
    if self.destroyed then
        return self
    end
    if self.window.tooltip then
        self.window.tooltip:Cancel()
    end
    self.visible = value == true
    self.button.Visible = self.visible
    if not self.visible then
        self:_fallback()
    elseif not self.disabled and not self.tab.activeSub then
        self.tab.activeSub = self
        if self.window.activeTab == self.tab then
            self:Select()
        end
    end
    self.window:_indexChanged()
    return self
end
function SubTab:SetDisabled(value)
    if self.destroyed then
        return self
    end
    if self.window.tooltip then
        self.window.tooltip:Cancel()
    end
    self.disabled = value == true
    if self.disabled then
        self:_fallback()
    elseif self.visible then
        self:SetVisible(true)
    end
    self:_render()
    self.window:_indexChanged()
    return self
end
function SubTab:Destroy()
    if self.destroyed then
        return
    end
    self:_fallback()
    self.destroyed = true
    for i = #self.controls, 1, -1 do
        self.controls[i]:Destroy()
    end
    U.remove(self.tab.subtabs, self)
    self.bag:Destroy()
end

-- One continuous row system. No component cards; separators and typography carry hierarchy.
function Components.row(page, config, kind)
    assert(not page.destroyed, "Neron subtab is destroyed")
    config = config or {}
    local w = page.window
    if config.Flag then
        assert(not w.flagOwners[config.Flag], "Neron duplicate Flag: " .. config.Flag)
    end
    local self = setmetatable({
        page = page,
        window = w,
        bag = Maid.new(w.motion),
        kind = kind,
        config = config,
        state = {
            Disabled = config.Disabled == true,
            Locked = kind == "Toggle" and config.Locked == true,
            Visible = config.Visible ~= false,
            Hovered = false,
            Pressed = false,
            Open = false,
        },
        inlineOwner = config.InlineWith,
        attachments = {},
        name = tostring(config.Name or kind),
        description = tostring(config.Description or ""),
        tooltipText = config.Tooltip or config.ToolTip,
        value = nil,
        flag = config.Flag,
    }, Control)
    table.insert(page.controls, self)
    if not page.system then
        table.insert(w.index, self)
    end
    page.controlSerial = (page.controlSerial or 0) + 1
    if self.flag then
        w.flagOwners[self.flag] = self
    end
    self.row = U.new(self.inlineOwner and "Frame" or "TextButton", {
        Name = self.name,
        Size = UDim2.new(1, 0, 0, T.Geometry.Row),
        Visible = self.state.Visible,
        LayoutOrder = page.controlSerial,
        ZIndex = page.scroll.frame.ZIndex + 1,
    }, page.scroll.frame)
    self.row.BackgroundTransparency = 0
    self.row.BackgroundColor3 = w.theme.RowBackground
    U.corner(self.row, T.Radius.Row)
    self.bag:Add(self.row)
    self.label =
        U.label(self.row, self.name, T.Type.ElementTitle, w.theme.TextSecondary, { Font = Enum.Font.GothamBold })
    self.desc = U.label(
        self.row,
        self.description,
        T.Type.Description,
        w.theme.TextMuted,
        { TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top }
    )
    self.separator = U.frame(self.row, {
        Position = UDim2.new(0, T.Geometry.LabelInset, 1, -1),
        Size = UDim2.new(1, -T.Geometry.LabelInset * 2, 0, 1),
        ZIndex = self.row.ZIndex + 1,
    }, w, "Separator")
    self.lane = U.frame(self.row, {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 0),
        Size = UDim2.fromOffset(T.Geometry.ControlLane, T.Geometry.Row),
        ZIndex = self.row.ZIndex + 2,
    }, w)
    U.connect(self.bag, self.row.MouseEnter, function()
        self.state.Hovered = true
        self:_render()
    end)
    U.connect(self.bag, self.row.MouseLeave, function()
        self.state.Hovered = false
        self:_render()
    end)
    U.connect(self.bag, self.row.InputBegan, function(input)
        if U.primary(input) and self:_usable() then
            self.state.Pressed = true
            self.window.pressed[self] = input
            self:_render()
        end
    end)
    U.connect(self.bag, self.row.InputEnded, function(input)
        if U.primary(input) then
            self.state.Pressed = false
            self:_render()
        end
    end)
    U.connect(self.bag, self.row:GetPropertyChangedSignal("AbsoluteSize"), function()
        self:_layout()
    end)
    if self.inlineOwner then
        assert(
            self.inlineOwner.page == page and not self.inlineOwner.destroyed,
            "Neron inline controls must share a subtab"
        )
        self.row.Parent = self.inlineOwner.row
        self.row.BackgroundTransparency = 1
        self.label.Visible = false
        self.desc.Visible = false
        self.separator.Visible = false
        table.insert(self.inlineOwner.attachments, self)
    end
    self:_layout()
    Tooltip.bind(w, self, self.row, self.bag, function()
        return self.tooltipText or self.description
    end, function()
        return self:_available()
    end)
    w:_indexChanged()
    return self
end
function Control:_available()
    return not self.destroyed
        and not Tooltip.blocked(self.window, self)
        and (not self.inlineOwner or self.inlineOwner:_usable())
        and not self.state.Disabled
        and self.state.Visible
        and self.window.visible
        and not self.window.destroyed
        and not self.window.searchOpen
        and not self.window.confirmation
        and not self.window.transfer
        and (self.page.system and self.window.settingsOpen and self.window.settingsCategory == self.page.name or not self.page.system and not self.window.settingsOpen)
        and self.page.visible
        and not self.page.disabled
        and self.page.tab.visible
        and not self.page.tab.disabled
        and (self.page.system or self.window.activeTab == self.page.tab)
        and (self.page.system or self.page.tab.activeSub == self.page)
end
function Control:_usable()
    return not self.state.Locked and self:_available()
end
function Control:_layout()
    if self.destroyed then
        return
    end
    if self.inlineOwner then
        self.row.Size = UDim2.fromScale(1, 1)
        self.lane.Size = UDim2.fromOffset(32, self.inlineOwner.lane.Size.Y.Offset)
        self.lane.Position = UDim2.new(
            1,
            -T.Geometry.AttachedSwatchInset,
            self.inlineOwner.lane.Position.Y.Scale,
            self.inlineOwner.lane.Position.Y.Offset
        )
        return
    end
    local width = self.row.AbsoluteSize.X / self.window.scale
    local narrow = self.window.compact or ((self.window.manualSize or self.window.defaultDesktopSize) and width < 400)
    local hasDesc = self.description ~= ""
    local h = T.Geometry.Row
    local descriptionHeight = 0
    if hasDesc then
        local width = math.max(80, self.row.AbsoluteSize.X / self.window.scale - 32)
        local lines =
            S.Text:GetTextSize(self.description, T.Type.Description, Enum.Font.Gotham, Vector2.new(width, 1000)).Y
        descriptionHeight = math.ceil(lines)
        h = math.max(h, descriptionHeight + 44)
    end
    local laneWidth = math.min(T.Geometry.ControlLane, math.max(130, width * 0.38))
    if narrow then
        h = hasDesc and math.max(106, descriptionHeight + 82) or 90
        laneWidth = math.min(T.Geometry.ControlLane, width - 32)
    end
    self.row.Size = UDim2.new(1, 0, 0, h)
    self.lane.Size = UDim2.fromOffset(laneWidth, narrow and 34 or (hasDesc and 44 or h))
    self.lane.Position = narrow and UDim2.new(1, -16, 1, -40) or UDim2.new(1, -16, 0, 0)
    local titleWidth = narrow and width - 32 or math.max(40, width - laneWidth - 40)
    self.label.Position = UDim2.fromOffset(T.Geometry.LabelInset, hasDesc and 12 or (narrow and 12 or h / 2 - 10))
    self.label.Size = UDim2.fromOffset(titleWidth, 20)
    self.desc.Visible = hasDesc
    self.desc.Position = UDim2.fromOffset(T.Geometry.LabelInset, 34)
    self.desc.Size = UDim2.new(1, -32, 0, narrow and descriptionHeight or h - 40)
    if self.layoutVisual then
        self:layoutVisual(laneWidth)
    end
    for _, attached in ipairs(self.attachments) do
        attached:_layout()
    end
end
function Control:_render()
    if self.destroyed then
        return
    end
    local w = self.window
    local s = self.state
    local on = s.Hovered
        or s.Highlight
        or s.Open
        or s.Pressed
        or s.Focused
        or (self.kind == "Toggle" and self.value == true)
    local color = s.Disabled and w.theme.TextDisabled
        or (
            (on or self.systemHeading) and w.theme.TextPrimary
            or (self.page.system and w.theme.SystemText or w.theme.TextSecondary)
        )
    w.motion:To(self.label, T.Motion.Micro, { TextColor3 = color })
    w.motion:To(self.desc, T.Motion.Micro, {
        TextColor3 = s.Disabled and w.theme.TextDisabled
            or (self.page.system and w.theme.TextSecondary or w.theme.TextMuted),
    })
    w.motion:To(
        self.row,
        T.Motion.Micro,
        { BackgroundColor3 = s.Pressed and w.theme.RowPressed or (on and w.theme.RowHover or w.theme.RowBackground) }
    )
    if self.renderVisual then
        self:renderVisual()
    end
end
function Control:_emit()
    if type(self.config.Callback) ~= "function" or self.destroyed then
        return
    end
    if self.emitting then
        self.pending = true
        return
    end
    self.emitting = true
    local count = 0
    repeat
        self.pending = false
        count += 1
        local value = U.copy(self.value)
        local ok, err = xpcall(function()
            if self.kind == "RangeSlider" then
                self.config.Callback(value[1], value[2])
            elseif self.kind == "Button" then
                self.config.Callback()
            elseif self.kind == "ColorPicker" then
                self.config.Callback(value, self.alpha)
            else
                self.config.Callback(value)
            end
        end, debug.traceback)
        if not ok then
            U.warn(self.name, err)
        end
    until self.destroyed or not self.pending or count >= 8
    if self.pending and not self.destroyed then
        U.warn(self.name, "callback reentry limit reached")
    end
    self.emitting = false
    self.pending = false
end
function Control:_commit(value, silent)
    if self.destroyed then
        return self
    end
    local changed = not U.equal(self.value, value)
    self.value = U.copy(value)
    if self.flag then
        self.window.Flags[self.flag] = U.copy(value)
    end
    self:_render()
    if self.flag and self.window.persistence then
        self.window.persistence:QueueAutoload()
    end
    if changed and not silent then
        self:_emit()
    end
    return self
end
function Control:Get()
    return U.copy(self.value)
end
function Control:SetVisible(value)
    if self.destroyed then
        return self
    end
    if self.window.tooltip then
        self.window.tooltip:Cancel()
    end
    self.state.Visible = value == true
    self.row.Visible = self.state.Visible
    if not self.state.Visible then
        self:Close()
        self.window.input:Cancel(self)
        for _, attached in ipairs(self.attachments) do
            attached:Close()
        end
        if self.box and self.box:IsFocused() then
            self.box:ReleaseFocus()
        end
        self.state.Pressed = false
        self.window.pressed[self] = nil
    end
    self.page.scroll:Update()
    self.window:_indexChanged()
    return self
end
function Control:SetDisabled(value)
    if self.destroyed then
        return self
    end
    if self.window.tooltip then
        self.window.tooltip:Cancel()
    end
    self.state.Disabled = value == true
    self.state.Pressed = false
    self.window.pressed[self] = nil
    if self.state.Disabled then
        self:Close()
        self.window.input:Cancel(self)
        if self.box and self.box:IsFocused() then
            self.box:ReleaseFocus()
        end
    end
    self:_render()
    for _, attached in ipairs(self.attachments) do
        if self.state.Disabled then
            attached:Close()
        end
        attached:_render()
    end
    return self
end
function Control:SetName(name)
    if self.destroyed then
        return self
    end
    self.name = tostring(name)
    self.label.Text = self.name
    self.window:_indexChanged()
    self.row.Name = self.name
    if self.kind == "Label" or self.kind == "Section" then
        self:_commit(self.name, true)
    end
    if self.actionLabel and not self.config.Text then
        self.actionLabel.Text = self.name
    end
    if self.premiumBadge then
        self:_layout()
    end
    return self
end
function Control:SetDescription(text)
    if self.destroyed then
        return self
    end
    self.description = tostring(text or "")
    self.desc.Text = self.description
    if self.kind == "Paragraph" or self.kind == "Notice" then
        self:_commit(self.description, true)
    end
    self.window:_indexChanged()
    self:_layout()
    return self
end
function Control:Close()
    local a = self.window.overlay.active
    if a and a.owner == self then
        self.window.overlay:Close()
    end
    return self
end
function Control:Destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true
    for i = #self.attachments, 1, -1 do
        self.attachments[i]:Destroy()
    end
    if self.inlineOwner then
        U.remove(self.inlineOwner.attachments, self)
    end
    local overlay = self.window.overlay
    if (overlay.active and overlay.active.owner == self) or (overlay.closing and overlay.closing.owner == self) then
        overlay:Close(true)
    end
    self.window.input:Cancel(self)
    self.window.pressed[self] = nil
    if self.box and self.box:IsFocused() then
        self.box:ReleaseFocus()
    end
    self.window.motion:Cancel(self.row)
    self.window.motion:Cancel(self.label)
    self.window.motion:Cancel(self.desc)
    U.remove(self.page.controls, self)
    U.remove(self.window.index, self)
    if self.flag then
        self.window.flagOwners[self.flag] = nil
        self.window.Flags[self.flag] = nil
    end
    self.bag:Destroy()
    self.window:_indexChanged()
end

function Components.circle(parent, diameter, color)
    local f = U.new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(diameter, diameter),
        BackgroundTransparency = 0,
        BackgroundColor3 = color,
        ZIndex = parent.ZIndex + 1,
    }, parent)
    U.corner(f, 100)
    return f
end
function SubTab:AddToggle(config)
    config = config or {}
    assert(
        config.OnBuyPremium == nil or type(config.OnBuyPremium) == "function",
        "Neron OnBuyPremium expects a function"
    )
    local self = Components.row(self, config, "Toggle")
    self.track = U.frame(self.lane, {
        Name = "SwitchTrack",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(T.Geometry.Toggle, T.Geometry.ToggleHeight),
        ZIndex = self.lane.ZIndex + 1,
    }, self.window, "ToggleTrackOff")
    U.corner(self.track, T.Geometry.ToggleHeight / 2)
    self.knob = Components.circle(self.track, T.Geometry.ToggleKnob, self.window.theme.ToggleKnobOff)
    self.knob.Name = "SwitchKnob"
    self.knob.Position = UDim2.new(0, T.Geometry.ToggleInset + T.Geometry.ToggleKnob / 2, 0.5, 0)
    self.hitbox = U.button(self.lane, {
        Name = "SwitchHitbox",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 8, 0.5, 0),
        Size = UDim2.fromOffset(44, 40),
        ZIndex = self.lane.ZIndex + 3,
    })
    function self:_premiumChrome()
        if self.premiumBadge then
            return
        end
        self.lockIcon = Icons.make(self.lane, "lock", 12, self.window.theme.TextMuted, self.window)
        self.lockIcon.AnchorPoint = Vector2.new(1, 0.5)
        self.lockIcon.Position = UDim2.new(1, -T.Geometry.Toggle - 10, 0.5, 0)
        self.premiumBadge = U.label(self.row, "PREMIUM", 9, self.window.theme.Accent, {
            Name = "PremiumBadge",
            Size = UDim2.fromOffset(T.Geometry.PremiumBadge, 18),
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.GothamMedium,
            ZIndex = self.lane.ZIndex,
        })
        U.corner(self.premiumBadge, T.Radius.Input)
        self.premiumEdge = U.stroke(self.premiumBadge, self.window.theme.Accent, 1)
        self.premiumEdge.Transparency = 0.45
    end
    function self:layoutVisual()
        if not self.premiumBadge then
            return
        end
        local available = self.label.Size.X.Offset
        local badge = T.Geometry.PremiumBadge
        local text = S.Text:GetTextSize(self.name, T.Type.ElementTitle, Enum.Font.GothamBold, Vector2.new(10000, 20)).X
        local x = math.min(text + 10, math.max(0, available - badge))
        self.premiumBadge.Position = UDim2.fromOffset(T.Geometry.LabelInset + x, self.label.Position.Y.Offset + 1)
        if self.state.Locked then
            self.label.Size = UDim2.fromOffset(math.max(1, x - 10), 20)
        end
    end
    function self:renderVisual()
        local w, state = self.window, self.state
        local on = self.value == true
        local inactive = state.Disabled or state.Locked
        local track = state.Disabled and w.theme.InputBackground
            or (state.Locked and w.theme.DropdownBackground or (on and w.theme.ToggleTrackOn or w.theme.ToggleTrackOff))
        local knob = state.Disabled and w.theme.TextDisabled
            or (state.Locked and w.theme.TextSecondary or (on and w.theme.ToggleKnobOn or w.theme.ToggleKnobOff))
        if state.Locked then
            self:_premiumChrome()
        end
        if self.premiumBadge then
            self.premiumBadge.Visible = state.Locked
            self.lockIcon.Visible = state.Locked
            self.premiumBadge.TextColor3 = state.Disabled and w.theme.TextDisabled or w.theme.Accent
            self.premiumEdge.Color = w.theme.Accent
            Icons.color(
                self.lockIcon,
                state.Disabled and w.theme.TextDisabled or w.theme.Accent:Lerp(w.theme.TextSecondary, 0.4)
            )
        end
        if not inactive and state.Hovered then
            track = track:Lerp(w.theme.TextPrimary, 0.035)
        end
        if not inactive and state.Pressed then
            knob = knob:Lerp(track, 0.12)
        end
        local inset = T.Geometry.ToggleInset + T.Geometry.ToggleKnob / 2
        w.motion:To(self.track, T.Motion.Fast, { BackgroundColor3 = track })
        w.motion:To(self.knob, T.Motion.Fast, {
            BackgroundColor3 = knob,
            Position = UDim2.new(0, on and T.Geometry.Toggle - inset or inset, 0.5, 0),
        })
    end
    function self:Set(value, silent)
        return self:_commit(not self.state.Locked and value == true, silent)
    end
    function self:GetLocked()
        return self.state.Locked
    end
    function self:SetLocked(value, silent)
        if self.destroyed or self.state.Locked == (value == true) then
            return self
        end
        self.state.Locked = value == true
        self.config.Locked = self.state.Locked
        self:Close()
        self.window.input:Cancel(self)
        self.state.Pressed = false
        self.window.pressed[self] = nil
        if self.state.Locked then
            self:Set(false, silent)
        end
        for _, attached in ipairs(self.attachments) do
            attached:Close()
            attached:_render()
        end
        self:_layout()
        self:_render()
        return self
    end
    function self:OpenPremium()
        if self.state.Locked and self:_available() then
            local width = math.min(
                T.Geometry.PremiumWidth,
                math.max(180, self.window.stage.AbsoluteSize.X / self.window.scale - 16)
            )
            self.window.overlay:Open(self, self.row, width, T.Geometry.PremiumHeight, function(group, bag)
                Components.premium(self, group, bag)
            end, true)
        end
        return self
    end
    local function activate()
        if self:_available() then
            self.state.Pressed = false
            self.window.pressed[self] = nil
            if self.state.Locked then
                self:OpenPremium()
            else
                self:Set(not self.value)
            end
        end
    end
    U.connect(self.bag, self.row.Activated, activate)
    U.connect(self.bag, self.hitbox.Activated, activate)
    U.connect(self.bag, self.hitbox.InputBegan, function(event)
        if U.primary(event) and self:_available() then
            self.state.Pressed = true
            self.window.pressed[self] = event
            self:_render()
        end
    end)
    function self:AddColorPicker(pickerConfig)
        assert(
            not self.destroyed and (not self.ColorPicker or self.ColorPicker.destroyed),
            "Neron toggle has one owned color swatch"
        )
        local options = table.clone(pickerConfig or {})
        options.InlineWith = self
        local picker = self.page:AddColorPicker(options)
        self.ColorPicker = picker
        return picker
    end
    self:Set(config.Default == true, true)
    self:_layout()
    return self
end
function Components.premium(control, group, bag)
    local w = control.window
    local function available()
        local active = w.overlay.active
        return not bag.dead
            and control.state.Locked
            and control.state.Open
            and control:_available()
            and active
            and active.owner == control
            and active.group == group
    end
    local icon = Icons.make(group, "lock", 18, w.theme.Accent, w)
    icon.Position = UDim2.fromOffset(14, 15)
    SettingsUI.text(w, group, "PremiumRequired", {
        Name = "PremiumHeading",
        Position = UDim2.fromOffset(42, 12),
        Size = UDim2.new(1, -56, 0, 24),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
    }, "TextPrimary")
    local copy = U.label(
        group,
        string.format(w:Translate("UnlockPremiumFeature"), control.name),
        T.Type.Value,
        w.theme.SystemText,
        {
            Position = UDim2.fromOffset(14, 46),
            Size = UDim2.new(1, -28, 0, 54),
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
        }
    )
    U.bind(w, copy, "TextColor3", "SystemText")
    local buy = U.button(group, {
        Name = "BuyPremium",
        Position = UDim2.new(0, 14, 1, -54),
        Size = UDim2.new(1, -28, 0, 40),
        BackgroundTransparency = 0,
        BackgroundColor3 = w.theme.Accent,
        ZIndex = group.ZIndex + 2,
    })
    U.corner(buy, T.Radius.Button)
    SettingsUI.text(w, buy, "BuyPremium", {
        TextXAlignment = Enum.TextXAlignment.Center,
        Font = Enum.Font.GothamMedium,
    }, "ButtonText")
    local owner = { state = { Hovered = false, Pressed = false } }
    function owner:_render()
        if bag.dead then
            return
        end
        Icons.color(icon, w.theme.Accent)
        w.motion:To(buy, T.Motion.Micro, {
            BackgroundColor3 = self.state.Pressed and w.theme.AccentPressed
                or (self.state.Hovered and w.theme.AccentHover or w.theme.Accent),
        })
    end
    w.systemRenders = w.systemRenders or {}
    w.systemRenders[buy] = owner
    bag:Add(function()
        w.systemRenders[buy] = nil
        w.pressed[owner] = nil
    end)
    U.connect(bag, buy.MouseEnter, function()
        owner.state.Hovered = true
        owner:_render()
    end)
    U.connect(bag, buy.MouseLeave, function()
        owner.state.Hovered, owner.state.Pressed = false, false
        owner:_render()
    end)
    U.connect(bag, buy.InputBegan, function(event)
        if U.primary(event) and available() then
            owner.state.Pressed = true
            w.pressed[owner] = event
            owner:_render()
        end
    end)
    U.connect(bag, buy.InputEnded, function(event)
        if U.primary(event) then
            owner.state.Pressed = false
            owner:_render()
        end
    end)
    U.connect(bag, buy.Activated, function()
        if not available() then
            return
        end
        owner.state.Pressed = false
        w.pressed[owner] = nil
        w.overlay:Close()
        local callback = control.config.OnBuyPremium or w.onBuyPremium
        if type(callback) ~= "function" then
            w:Notify("PremiumRequired", w:Translate("PurchaseNotConfigured"), "Warning")
            return
        end
        local ok, err = xpcall(function()
            callback(control, w)
        end, debug.traceback)
        if not ok then
            U.warn("Buy Premium", err)
            if not w.destroyed then
                w:Notify("Failed", nil, "Danger")
            end
        end
    end)
    owner:_render()
end
function Components.numeric(config)
    local min = U.finite(config.Min, 0)
    local max = U.finite(config.Max, 100)
    assert(max > min, "Neron numeric Max must be greater than Min")
    local step = U.finite(config.Step or config.Increment, 1)
    assert(step > 0, "Neron numeric Step must be positive")
    local rounding = U.finite(config.Rounding, nil)
    if rounding then
        rounding = math.clamp(math.floor(rounding), 0, 8)
    else
        rounding = 0
        while rounding < 8 and math.abs(step * 10 ^ rounding - math.round(step * 10 ^ rounding)) > 1e-7 do
            rounding += 1
        end
    end
    return {
        min = min,
        max = max,
        step = step,
        rounding = rounding,
        prefix = tostring(config.Prefix or ""),
        suffix = tostring(config.Suffix or ""),
    }
end
function Components.quantize(n, value)
    value = math.clamp(U.finite(value, n.min), n.min, n.max)
    if value == n.max then
        return n.max
    end
    return math.clamp(n.min + math.round((value - n.min) / n.step) * n.step, n.min, n.max)
end
function Components.format(n, value)
    return n.prefix .. string.format("%." .. n.rounding .. "f", value) .. n.suffix
end
function Components.slider(page, config, range)
    config = config or {}
    local number = Components.numeric(config)
    local self = Components.row(page, config, range and "RangeSlider" or "Slider")
    self.number = number
    self.track = U.button(self.lane, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(T.Geometry.Control, 32),
        ZIndex = self.lane.ZIndex + 1,
    })
    self.rail = U.frame(self.track, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, T.Geometry.Track),
        ZIndex = self.track.ZIndex,
    }, self.window, "SliderTrack")
    U.corner(self.rail, 5)
    self.fill =
        U.frame(self.rail, { Size = UDim2.fromScale(0, 1), ZIndex = self.rail.ZIndex + 1 }, self.window, "SliderFill")
    U.corner(self.fill, 5)
    self.thumbs = {}
    for _ = 1, range and 2 or 1 do
        local thumb = Components.circle(self.rail, T.Geometry.Thumb, self.window.theme.Accent)
        local center = Components.circle(thumb, T.Geometry.ThumbCore, self.window.theme.SliderCore)
        U.bind(self.window, center, "BackgroundColor3", "SliderCore")
        thumb.Position = UDim2.fromScale(0, 0.5)
        center.Position = UDim2.fromScale(0.5, 0.5)
        table.insert(self.thumbs, thumb)
    end
    self.valueLabel = U.label(self.lane, "", T.Type.Value, self.window.theme.TextPrimary, {
        TextXAlignment = Enum.TextXAlignment.Right,
        Size = UDim2.new(1, -T.Geometry.Control - T.Geometry.ValueGap, 1, 0),
    })
    function self:layoutVisual(laneWidth)
        local width = math.min(T.Geometry.Control, laneWidth - 72)
        self.track.Size = UDim2.fromOffset(width, 32)
        self.valueLabel.Size = UDim2.new(1, -width - T.Geometry.ValueGap, 1, 0)
    end
    function self:renderVisual()
        local n = self.number
        local v = self.value
        if v == nil then
            return
        end
        local low = range and v[1] or n.min
        local high = range and v[2] or v
        local a, b = (low - n.min) / (n.max - n.min), (high - n.min) / (n.max - n.min)
        local width = self.track.Size.X.Offset
        local travel = width - T.Geometry.Thumb
        self.fill.Position = UDim2.fromOffset(range and a * travel or 0, 0)
        self.fill.Size = UDim2.fromOffset((range and (b - a) or b) * travel + T.Geometry.Thumb, T.Geometry.Track)
        self.thumbs[1].Position = UDim2.new(0, T.Geometry.Thumb / 2 + (range and a or b) * travel, 0.5, 0)
        if range then
            self.thumbs[2].Position = UDim2.new(0, T.Geometry.Thumb / 2 + b * travel, 0.5, 0)
        end
        local color = self.state.Disabled and self.window.theme.TextDisabled or self.window.theme.SliderFill
        self.rail.BackgroundColor3 = self.window.theme.SliderTrack
        self.fill.BackgroundColor3 = color
        for _, thumb in ipairs(self.thumbs) do
            thumb.BackgroundColor3 = self.state.Disabled and color or self.window.theme.SliderKnob
        end
        self.valueLabel.Text = range and (Components.format(n, low) .. ", " .. Components.format(n, high))
            or Components.format(n, high)
        self.valueLabel.TextColor3 = self.state.Disabled and self.window.theme.TextDisabled
            or self.window.theme.TextPrimary
    end
    if range then
        function self:Set(low, high, silent)
            if type(low) == "table" then
                silent = high
                high = low[2]
                low = low[1]
            end
            low = Components.quantize(self.number, low)
            high = Components.quantize(self.number, high)
            return self:_commit({ math.min(low, high), math.max(low, high) }, silent)
        end
    else
        function self:Set(value, silent)
            return self:_commit(Components.quantize(self.number, value), silent)
        end
    end
    U.connect(self.bag, self.track.InputBegan, function(event)
        if not self:_usable() or not self.window.input:CanStart(event) then
            return
        end
        local n = self.number
        local which = 1
        if range then
            local x = U.point(event).X
            local d1 = math.abs(x - self.thumbs[1].AbsolutePosition.X - self.thumbs[1].AbsoluteSize.X / 2)
            local d2 = math.abs(x - self.thumbs[2].AbsolutePosition.X - self.thumbs[2].AbsoluteSize.X / 2)
            which = d1 == d2 and (self.lastThumb == 1 and 2 or 1) or (d1 < d2 and 1 or 2)
            self.lastThumb = which
        end
        self.state.Pressed = true
        self:_render()
        local scrolling = self.page.scroll.frame.ScrollingEnabled
        self.page.scroll.frame.ScrollingEnabled = false
        self.window.input:Start(self, event, function(p)
            local ratio = math.clamp(
                (p.X - self.rail.AbsolutePosition.X - T.Geometry.Thumb * self.window.scale / 2)
                    / math.max(1, self.rail.AbsoluteSize.X - T.Geometry.Thumb * self.window.scale),
                0,
                1
            )
            local v = Components.quantize(n, n.min + ratio * (n.max - n.min))
            if range then
                if which == 1 then
                    self:Set(math.min(v, self.value[2]), self.value[2])
                else
                    self:Set(self.value[1], math.max(v, self.value[1]))
                end
            else
                self:Set(v)
            end
        end, function()
            self.state.Pressed = false
            if not self.page.destroyed then
                self.page.scroll.frame.ScrollingEnabled = scrolling
            end
            self:_render()
        end)
    end)
    if range then
        local d = config.Default or { self.number.min, self.number.max }
        self:Set(d[1], d[2], true)
    else
        self:Set(config.Default or self.number.min, true)
    end
    self:_layout()
    return self
end
function SubTab:AddSlider(config)
    return Components.slider(self, config, false)
end
function SubTab:AddRangeSlider(config)
    return Components.slider(self, config, true)
end

function Components.values(values)
    local out, seen = {}, {}
    for _, v in ipairs(values or {}) do
        v = tostring(v)
        if not seen[v] then
            seen[v] = true
            table.insert(out, v)
        end
    end
    return out
end
function Components.dropdown(page, config, multi)
    config = config or {}
    local self = Components.row(page, config, multi and "MultiDropdown" or "Dropdown")
    self.values = Components.values(config.Values)
    self.maxSelections = multi and math.max(0, math.floor(U.finite(config.MaxSelections, #self.values))) or nil
    self.unlimited = config.MaxSelections == nil
    self.trigger = U.button(self.lane, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(142, 30),
        ZIndex = self.lane.ZIndex + 1,
    })
    self.valueLabel = U.label(
        self.trigger,
        "",
        T.Type.Value,
        self.window.theme.TextPrimary,
        { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -30, 1, 0), Font = Enum.Font.GothamMedium }
    )
    self.chevron = Icons.make(self.trigger, "chevron", 8, self.window.theme.TextPrimary, self.window)
    self.chevron.Position = UDim2.new(1, -18, 0.5, -4)
    function self:renderVisual()
        local w = self.window
        self.valueLabel.Text = multi
                and ((self.value and #self.value > 0) and table.concat(self.value, ", ") or tostring(
                    config.Placeholder or Locale.text(w, "None")
                ))
            or tostring(self.value or config.Placeholder or Locale.text(w, "Select"))
        self.valueLabel.TextColor3 = self.state.Disabled and w.theme.TextDisabled or w.theme.TextPrimary
        Icons.color(self.chevron, self.valueLabel.TextColor3)
        w.motion:To(self.chevron, T.Motion.Fast, { Rotation = self.state.Open and 180 or 0 })
        self.trigger.BackgroundColor3 = self.state.Open and w.theme.DropdownHover or w.theme.DropdownBackground
        w.motion:To(
            self.trigger,
            T.Motion.Micro,
            { BackgroundTransparency = (self.state.Open or self.state.Hovered) and 0.15 or 0.55 }
        )
        if self.optionRows then
            for _, option in ipairs(self.optionRows) do
                local selected = multi and self.value and table.find(self.value, option.value) ~= nil
                    or (not multi and option.value == self.value)
                option.dot.Visible = selected
                option.label.TextColor3 = (selected or option.hover) and w.theme.TextPrimary or w.theme.TextMuted
                option.dot.BackgroundColor3 = w.theme.Accent
            end
        end
    end
    function self:Set(value, silent)
        if multi then
            local requested = {}
            for _, v in ipairs(type(value) == "table" and value or {}) do
                requested[tostring(v)] = true
            end
            local selected = {}
            local maximum = self.unlimited and #self.values or self.maxSelections
            for _, v in ipairs(self.values) do
                if requested[v] and #selected < maximum then
                    table.insert(selected, v)
                end
            end
            return self:_commit(selected, silent)
        end
        if value ~= nil then
            value = tostring(value)
        end
        if value ~= nil and not table.find(self.values, value) then
            return self
        end
        return self:_commit(value, silent)
    end
    function self:SetValues(values, silent)
        local open = self.state.Open
        self:Close()
        self.values = Components.values(values)
        if multi then
            self:Set(self.value, silent)
        else
            local current = self.value
            if not table.find(self.values, current) then
                current = nil
            end
            self:Set(current, silent)
        end
        if open then
            self:Open()
        end
        return self
    end
    function self:Open()
        if not self:_usable() then
            return self
        end
        local height = math.min(6, #self.values) * T.Geometry.Option + 8
        self.window.overlay:Open(self, self.trigger, T.Geometry.PopoverWidth, math.max(36, height), function(group, bag)
            local holder = U.frame(
                group,
                { Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8), ZIndex = group.ZIndex + 1 },
                self.window
            )
            local scroll = Scroll.make(self.window, holder, bag, 0, true)
            scroll.frame.Size = UDim2.new(1, -8, 1, 0)
            local options = {}
            self.optionRows = options
            bag:Add(function()
                if self.optionRows == options then
                    self.optionRows = nil
                end
            end)
            for i, value in ipairs(self.values) do
                local button = U.button(
                    scroll.frame,
                    { Size = UDim2.new(1, 0, 0, T.Geometry.Option), LayoutOrder = i, ZIndex = scroll.frame.ZIndex + 1 }
                )
                local label = U.label(
                    button,
                    value,
                    T.Type.PopoverOption,
                    self.window.theme.TextMuted,
                    { Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -22, 1, 0) }
                )
                local dot = Components.circle(button, 4, self.window.theme.Accent)
                dot.Position = UDim2.new(1, -8, 0.5, 0)
                local option = { value = value, label = label, dot = dot }
                table.insert(options, option)
                U.connect(bag, button.MouseEnter, function()
                    option.hover = true
                    self:_render()
                end)
                U.connect(bag, button.MouseLeave, function()
                    option.hover = false
                    self:_render()
                end)
                U.connect(bag, button.Activated, function()
                    if self.destroyed or not self:_usable() or not self.state.Open then
                        return
                    end
                    if multi then
                        local selected = self:Get()
                        local idx = table.find(selected, value)
                        if idx then
                            table.remove(selected, idx)
                        else
                            table.insert(selected, value)
                        end
                        self:Set(selected)
                    else
                        self:Set(value)
                        self:Close()
                    end
                end)
            end
            if #self.values == 0 then
                local empty = U.label(
                    holder,
                    Locale.text(self.window, "NoOptions"),
                    T.Type.Description,
                    self.window.theme.TextMuted
                )
                Locale.bind(self.window, empty, "Text", "NoOptions")
            end
            self:_render()
            scroll:Update()
        end)
        return self
    end
    U.connect(self.bag, self.trigger.Activated, function()
        if self.state.Open then
            self:Close()
        else
            self:Open()
        end
    end)
    self:Set(config.Default or (multi and {} or self.values[1]), true)
    return self
end
function SubTab:AddDropdown(config)
    return Components.dropdown(self, config, false)
end
function SubTab:AddMultiDropdown(config)
    return Components.dropdown(self, config, true)
end

function SubTab:AddColorPicker(config)
    config = config or {}
    assert(config.Default == nil or typeof(config.Default) == "Color3", "Neron ColorPicker Default expects Color3")
    local self = Components.row(self, config, "ColorPicker")
    self.alpha = math.clamp(U.finite(config.Alpha, 1), 0, 1)
    self.hasAlpha = config.Alpha ~= nil
    self.swatch = Components.circle(self.lane, T.Geometry.Swatch, Color3.new(1, 1, 1))
    self.window.bindings[self.swatch] = nil
    self.swatch.Position = UDim2.new(1, -T.Geometry.Swatch / 2, 0.5, 0)
    self.trigger = U.button(self.lane, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 8, 0.5, 0),
        Size = UDim2.fromOffset(34, 34),
        ZIndex = self.lane.ZIndex + 3,
    })
    function self:renderVisual()
        if not self.value then
            return
        end
        self.swatch.BackgroundColor3 = self.value
        self.swatch.BackgroundTransparency = (
            self.state.Disabled or (self.inlineOwner and self.inlineOwner.state.Disabled)
        )
                and 0.65
            or 1 - self.alpha
        if self.picker then
            local p = self.picker
            p.sv.BackgroundColor3 = Color3.fromHSV(self.hue, 1, 1)
            p.svHandle.Position = UDim2.fromScale(self.saturation, 1 - self.brightness)
            p.hueHandle.Position = UDim2.fromScale(self.hue, 0.5)
            if p.alpha then
                p.alpha.BackgroundColor3 = self.value
                p.alphaHandle.Position = UDim2.fromScale(self.alpha, 0.5)
            end
        end
    end
    function self:Set(color, silent)
        assert(typeof(color) == "Color3", "Neron ColorPicker:Set expects Color3")
        local hue, sat, val = color:ToHSV()
        self.hue = hue
        self.saturation = sat
        self.brightness = val
        return self:_commit(color, silent)
    end
    function self:SetAlpha(alpha, silent)
        if self.destroyed then
            return self
        end
        alpha = math.clamp(U.finite(alpha, 1), 0, 1)
        local changed = self.alpha ~= alpha
        self.alpha = alpha
        self:_render()
        if changed and not silent then
            self:_emit()
        end
        return self
    end
    function self:GetAlpha()
        return self.alpha
    end
    function self:Open()
        if not self:_usable() then
            return self
        end
        local width = T.Geometry.PickerWidth
        local height = 8 + T.Geometry.PickerSV + 16 + T.Geometry.PickerRail + (self.hasAlpha and 24 or 0) + 8
        self.window.overlay:Open(self, self.trigger, width, height, function(group, bag)
            local w = self.window
            local function canStart(event)
                local active = w.overlay.active
                return self:_usable()
                    and self.state.Open
                    and active
                    and active.owner == self
                    and active.group == group
                    and w.input:CanStart(event)
            end
            local railWidth = width - 16
            local sv = U.button(group, {
                Position = UDim2.fromOffset(8, 8),
                Size = UDim2.fromOffset(railWidth, T.Geometry.PickerSV),
                BackgroundTransparency = 0,
                ZIndex = group.ZIndex + 1,
            })
            U.corner(sv, 2)
            local white = U.frame(sv, {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0,
                ZIndex = sv.ZIndex + 1,
            }, w)
            U.new("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            }, white)
            local black = U.frame(sv, {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = 0,
                ZIndex = sv.ZIndex + 2,
            }, w)
            w.bindings[white] = nil
            w.bindings[black] = nil
            U.new("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
            }, black)
            local marker = U.frame(
                sv,
                { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 6), ZIndex = sv.ZIndex + 3 },
                w
            )
            U.corner(marker, 100)
            U.stroke(marker, Color3.new(1, 1, 1), 1)
            local hue = U.button(group, {
                Position = UDim2.fromOffset(8, 8 + T.Geometry.PickerSV + 16),
                Size = UDim2.fromOffset(railWidth, T.Geometry.PickerRail),
                BackgroundTransparency = 0,
                BackgroundColor3 = Color3.new(1, 1, 1),
                ZIndex = group.ZIndex + 1,
            })
            U.corner(hue, 2)
            w.bindings[hue] = nil
            local spectrum = {}
            for i = 0, 6 do
                table.insert(spectrum, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
            end
            U.new("UIGradient", { Color = ColorSequence.new(spectrum) }, hue)
            local hueHandle = U.frame(hue, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(4, 12),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0,
                ZIndex = hue.ZIndex + 3,
            }, w)
            U.corner(hueHandle, 1)
            local p = { sv = sv, svHandle = marker, hueHandle = hueHandle }
            self.picker = p
            if self.hasAlpha then
                local alpha = U.button(group, {
                    Position = UDim2.fromOffset(8, 8 + T.Geometry.PickerSV + 40),
                    Size = UDim2.fromOffset(railWidth, T.Geometry.PickerRail),
                    BackgroundTransparency = 0,
                    ZIndex = group.ZIndex + 1,
                })
                U.corner(alpha, 2)
                U.new("UIGradient", {
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    }),
                }, alpha)
                local backing = U.frame(group, {
                    Position = alpha.Position,
                    Size = alpha.Size,
                    BackgroundTransparency = 0,
                    BackgroundColor3 = Color3.fromRGB(90, 90, 90),
                    ZIndex = group.ZIndex,
                }, w)
                for i = 0, 19 do
                    U.frame(backing, {
                        Position = UDim2.new(i / 20, 0, 0, i % 2 * 4),
                        Size = UDim2.new(1 / 20, 0, 0, 4),
                        BackgroundTransparency = 0,
                        BackgroundColor3 = Color3.fromRGB(135, 135, 135),
                        ZIndex = backing.ZIndex,
                    }, w)
                end
                p.alpha = alpha
                p.alphaHandle = U.frame(alpha, {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Size = UDim2.fromOffset(4, 12),
                    BackgroundTransparency = 0,
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex = alpha.ZIndex + 3,
                }, w)
                U.corner(p.alphaHandle, 1)
                U.connect(bag, alpha.InputBegan, function(event)
                    if not canStart(event) then
                        return
                    end
                    w.input:Start(self, event, function(point)
                        self:SetAlpha((point.X - alpha.AbsolutePosition.X) / math.max(1, alpha.AbsoluteSize.X))
                    end)
                end)
            end
            local function applyHSV(h, s, v)
                self.hue = h
                self.saturation = s
                self.brightness = v
                -- Preserve hue at gray/black: ToHSV() would discard the user's selected hue.
                self:_commit(Color3.fromHSV(h, s, v), false)
            end
            U.connect(bag, sv.InputBegan, function(event)
                if not canStart(event) then
                    return
                end
                w.input:Start(self, event, function(point)
                    local x = math.clamp((point.X - sv.AbsolutePosition.X) / math.max(1, sv.AbsoluteSize.X), 0, 1)
                    local y = math.clamp((point.Y - sv.AbsolutePosition.Y) / math.max(1, sv.AbsoluteSize.Y), 0, 1)
                    applyHSV(self.hue, x, 1 - y)
                end)
            end)
            U.connect(bag, hue.InputBegan, function(event)
                if not canStart(event) then
                    return
                end
                w.input:Start(self, event, function(point)
                    applyHSV(
                        math.clamp((point.X - hue.AbsolutePosition.X) / math.max(1, hue.AbsoluteSize.X), 0, 1),
                        self.saturation,
                        self.brightness
                    )
                end)
            end)
            bag:Add(function()
                if self.picker == p then
                    self.picker = nil
                end
            end)
            self:_render()
        end)
        return self
    end
    U.connect(self.bag, self.trigger.Activated, function()
        if self.state.Open then
            self:Close()
        else
            self:Open()
        end
    end)
    self:Set(config.Default or Color3.fromRGB(70, 177, 245), true)
    return self
end

function SubTab:AddTextbox(config)
    config = config or {}
    local self = Components.row(self, config, "Textbox")
    self.box = U.new("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(152, 30),
        Text = "",
        PlaceholderText = tostring(config.Placeholder or ""),
        PlaceholderColor3 = self.window.theme.TextMuted,
        TextSize = T.Type.Value,
        TextColor3 = self.window.theme.TextPrimary,
        Font = Enum.Font.GothamMedium,
        ClearTextOnFocus = config.ClearOnFocus == true,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 0.60,
        BackgroundColor3 = self.window.theme.InputBackground,
        ZIndex = self.lane.ZIndex + 1,
    }, self.lane)
    U.corner(self.box, T.Radius.Input)
    U.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 26) }, self.box)
    self.edit = Icons.make(self.box, "pencil", 10, self.window.theme.TextPrimary, self.window)
    self.edit.Position = UDim2.new(1, -20, 0.5, -5)
    U.bind(self.window, self.box, "BackgroundColor3", "InputBackground")
    U.bind(self.window, self.box, "PlaceholderColor3", "TextMuted")
    self.focusStroke = U.stroke(self.box, self.window.theme.BorderStrong, 1)
    self.focusStroke.Transparency = 1
    function self:normalize(value)
        local text = tostring(value or "")
        local max = math.max(0, math.floor(U.finite(config.MaxLength, 4096)))
        local ok, offset = pcall(utf8.offset, text, max + 1)
        if ok and offset then
            text = text:sub(1, offset - 1)
        elseif not ok then
            text = text:sub(1, max)
        end
        if config.Numeric then
            if text == "" then
                return ""
            end
            local number = U.finite(text, nil)
            if not number then
                return tostring(self.value or "")
            end
            return tostring(number)
        end
        return text
    end
    function self:renderVisual()
        self.box.TextEditable = not self.state.Disabled
        self.box.TextColor3 = self.state.Disabled and self.window.theme.TextDisabled or self.window.theme.TextPrimary
        Icons.color(self.edit, self.box.TextColor3)
        self.window.motion:To(self.focusStroke, T.Motion.Micro, { Transparency = self.state.Focused and 0.15 or 1 })
        self.window.motion:To(
            self.box,
            T.Motion.Micro,
            { BackgroundTransparency = self.state.Focused and 0.05 or 0.60 }
        )
    end
    function self:Set(value, silent)
        if self.destroyed then
            return self
        end
        value = self:normalize(value)
        if self.box.Text ~= value then
            self.writing = true
            self.box.Text = value
            self.writing = false
        end
        return self:_commit(value, silent)
    end
    function self:Focus()
        if self:_usable() then
            self.box:CaptureFocus()
        end
        return self
    end
    U.connect(self.bag, self.box.Focused, function()
        if not self:_usable() then
            self.box:ReleaseFocus()
            return
        end
        self.state.Focused = true
        self:_render()
    end)
    U.connect(self.bag, self.box.FocusLost, function()
        self.state.Focused = false
        self:Set(self.box.Text)
        self:_render()
    end)
    U.connect(self.bag, self.box:GetPropertyChangedSignal("Text"), function()
        if self.writing or self.destroyed then
            return
        end
        local text = self:normalize(self.box.Text)
        if not config.Numeric then
            if text ~= self.box.Text then
                self.writing = true
                self.box.Text = text
                self.writing = false
            end
        end
        if config.Live then
            self:Set(text)
        end
    end)
    self:Set(config.Default or "", true)
    return self
end
function SubTab:AddButton(config)
    config = config or {}
    local self = Components.row(self, config, "Button")
    local full = config.Inline ~= true
    self.action = U.button(full and self.row or self.lane, {
        Name = "Action",
        AnchorPoint = full and Vector2.new(0, 0.5) or Vector2.new(1, 0.5),
        Position = full and UDim2.new(0, 0, 0.5, 0) or UDim2.fromScale(1, 0.5),
        Size = full and UDim2.new(1, 0, 0, T.Geometry.Button) or UDim2.fromOffset(142, 30),
        ZIndex = self.lane.ZIndex + 3,
    })
    U.corner(self.action, T.Radius.Button)
    self.actionLabel = U.label(
        self.action,
        config.Text or self.name,
        T.Type.Value,
        self.window.theme.TextMuted,
        { TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium }
    )
    function self:layoutVisual()
        if full then
            self.row.Size = UDim2.new(1, 0, 0, T.Geometry.Row)
            self.label.Visible = false
            self.desc.Visible = false
            self.separator.Visible = false
        end
    end
    self:_layout()
    function self:renderVisual()
        local s = self.state
        local w = self.window
        local active = (config.Primary == true or s.Hovered or s.Focused) and not s.Disabled
        local color = s.Disabled and w.theme.InputBackground
            or (s.Pressed and w.theme.AccentPressed or (active and w.theme.Accent or w.theme.RowBackground))
        w.motion:To(self.action, T.Motion.Micro, { BackgroundColor3 = color, BackgroundTransparency = 0 })
        self.actionLabel.TextColor3 = s.Disabled and w.theme.TextDisabled
            or (active and w.theme.ButtonText or (self.page.system and w.theme.SystemText or w.theme.TextMuted))
    end
    function self:Press()
        if self:_usable() then
            self:_emit()
        end
        return self
    end
    function self:SetText(text)
        if not self.destroyed then
            self.config.Text = tostring(text)
            self.actionLabel.Text = self.config.Text
        end
        return self
    end
    U.connect(self.bag, self.action.MouseEnter, function()
        self.state.Hovered = true
        self:_render()
    end)
    U.connect(self.bag, self.action.MouseLeave, function()
        self.state.Hovered = false
        self.state.Pressed = false
        self:_render()
    end)
    U.connect(self.bag, self.action.InputBegan, function(event)
        if U.primary(event) and self:_usable() then
            self.state.Pressed = true
            self.window.pressed[self] = event
            self:_render()
        end
    end)
    U.connect(self.bag, self.action.InputEnded, function(event)
        if U.primary(event) then
            self.state.Pressed = false
            self:_render()
        end
    end)
    U.connect(self.bag, self.action.Activated, function()
        self.state.Pressed = false
        self:Press()
        self:_render()
    end)
    self:_render()
    return self
end
function Components.info(page, config, kind)
    if type(config) == "string" then
        config = { Name = config }
    end
    config = config or {}
    local self = Components.row(page, config, kind)
    self.lane.Visible = false
    function self:layoutVisual()
        self.label.Size = UDim2.new(1, -32, 0, 20)
        if self.window.compact and self.description ~= "" then
            self.row.Size = UDim2.new(1, 0, 0, math.max(T.Geometry.Row, 46 + self.desc.Size.Y.Offset))
        end
        if kind == "Section" then
            self.row.Size = UDim2.new(1, 0, 0, 32)
            self.label.Position = UDim2.fromOffset(16, 6)
            self.label.TextSize = T.Type.Category
            self.label.Font = Enum.Font.GothamBold
            self.separator.Visible = false
        elseif kind == "Separator" then
            self.row.Size = UDim2.new(1, 0, 0, 12)
            self.label.Visible = false
            self.desc.Visible = false
        end
    end
    function self:Set(text, silent)
        if self.destroyed then
            return self
        end
        if kind == "Paragraph" or kind == "Notice" then
            self.description = tostring(text or "")
            self.desc.Text = self.description
            self.window:_indexChanged()
        else
            self.name = tostring(text or "")
            self.label.Text = self.name
        end
        self.window:_indexChanged()
        self:_layout()
        return self:_commit(tostring(text or ""), silent)
    end
    if kind == "Notice" then
        self.notice = U.frame(
            self.row,
            { Position = UDim2.fromOffset(0, 12), Size = UDim2.new(0, 2, 1, -24), ZIndex = self.row.ZIndex + 2 },
            self.window,
            config.Status or "Accent"
        )
    end
    self:_commit((kind == "Paragraph" or kind == "Notice") and self.description or self.name, true)
    self:_layout()
    return self
end
function SubTab:AddLabel(config)
    return Components.info(self, config, "Label")
end
function SubTab:AddParagraph(config)
    return Components.info(self, config, "Paragraph")
end
function SubTab:AddSeparator()
    return Components.info(self, {}, "Separator")
end
function SubTab:AddSection(config)
    return Components.info(self, config, "Section")
end
function SubTab:AddNotice(config)
    return Components.info(self, config, "Notice")
end

function Window:_indexChanged()
    if self.destroyed or not self.searchOpen or self.indexRefresh then
        return
    end
    self.indexRefresh = self.bag:After(0, function()
        self.indexRefresh = nil
        if self.searchOpen then
            self:_searchResults(self.searchBox.Text)
        end
    end, true)
end
function Window:_searchResults(query)
    if self.destroyed then
        return
    end
    if self.searchResultsBag then
        self.searchResultsBag:Destroy()
    end
    local bag = Maid.new(self.motion)
    self.searchResultsBag = bag
    query = tostring(query or ""):lower():match("^%s*(.-)%s*$")
    local hits = 0
    if query ~= "" then
        for _, control in ipairs(self.index) do
            local page, tab = control.page, control.page.tab
            local keywords = control.config.Keywords
            if type(keywords) == "table" then
                keywords = table.concat(keywords, " ")
            end
            local haystack = (
                tab.name
                .. " "
                .. page.name
                .. " "
                .. control.name
                .. " "
                .. control.description
                .. " "
                .. tostring(keywords or "")
            ):lower()
            local match = true
            for word in query:gmatch("%S+") do
                if not haystack:find(word, 1, true) then
                    match = false
                    break
                end
            end
            if
                match
                and control.state.Visible
                and not control.destroyed
                and page.visible
                and not page.disabled
                and tab.visible
                and not tab.disabled
                and control.kind ~= "Separator"
            then
                hits += 1
                local row = U.button(self.searchScroll.frame, {
                    Name = "Result",
                    Size = UDim2.new(1, -8, 0, control.description ~= "" and 76 or 64),
                    LayoutOrder = hits,
                    BackgroundTransparency = 0,
                    BackgroundColor3 = self.theme.RowBackground,
                    ZIndex = T.Z.Search + 3,
                })
                bag:Add(row)
                U.label(row, control.name, T.Type.ElementTitle, self.theme.TextPrimary, {
                    Position = UDim2.fromOffset(16, 12),
                    Size = UDim2.new(1, -32, 0, 20),
                    Font = Enum.Font.GothamMedium,
                })
                U.label(
                    row,
                    tab.name .. " / " .. page.name,
                    T.Type.Description,
                    self.theme.TextMuted,
                    { Position = UDim2.fromOffset(16, 38), Size = UDim2.new(1, -32, 0, 18) }
                )
                U.frame(
                    row,
                    { Position = UDim2.new(0, 16, 1, -1), Size = UDim2.new(1, -32, 0, 1), ZIndex = row.ZIndex },
                    self,
                    "Separator"
                )
                U.connect(bag, row.MouseEnter, function()
                    self.motion:To(row, T.Motion.Micro, { BackgroundColor3 = self.theme.RowHover })
                end)
                U.connect(bag, row.MouseLeave, function()
                    self.motion:To(row, T.Motion.Micro, { BackgroundColor3 = self.theme.RowBackground })
                end)
                U.connect(bag, row.Activated, function()
                    if
                        control.destroyed
                        or not self.searchOpen
                        or not control.state.Visible
                        or not page.visible
                        or page.disabled
                        or not tab.visible
                        or tab.disabled
                    then
                        return
                    end
                    self:CloseSearch(true)
                    tab:Select()
                    page:Select()
                    control.bag:After(0, function()
                        if
                            control.destroyed
                            or page.destroyed
                            or self.destroyed
                            or not control.state.Visible
                            or self.activeTab ~= tab
                            or tab.activeSub ~= page
                        then
                            return
                        end
                        local sf = page.scroll.frame
                        page.scroll:Update()
                        local y = (control.row.AbsolutePosition.Y - sf.AbsolutePosition.Y) / self.scale
                            + sf.CanvasPosition.Y
                        sf.CanvasPosition = Vector2.new(0, math.clamp(y - 8, 0, page.scroll.maximum))
                        if control.highlightCancel then
                            control.bag:Remove(control.highlightCancel, true)
                        end
                        control.state.Highlight = true
                        control:_render()
                        control.highlightCancel = control.bag:After(0.6, function()
                            control.highlightCancel = nil
                            control.state.Highlight = false
                            control:_render()
                        end)
                    end, true)
                end)
            end
        end
    end
    self.searchEmpty.Visible = hits == 0
    self.searchScroll:Update()
end
function Window:OpenSearch()
    if self.settingsOpen then
        self:CloseSettings(true)
    end
    if not self.searchEnabled or not self:_canNavigate() then
        return self
    end
    self.overlay:Close(true)
    self.input:Cancel()
    U.focusRelease(self)
    self.searchGeneration = (self.searchGeneration or 0) + 1
    if self.searchCancel then
        self.bag:Remove(self.searchCancel, true)
        self.searchCancel = nil
    end
    self.searchOpen = true
    self.searchPanel.Visible = true
    self:_dimState(true, 0.32)
    self.motion:To(self.searchPanel, T.Motion.Structural, { GroupTransparency = 0 })
    self.searchBox.Text = ""
    self:_searchResults("")
    self.searchBox:CaptureFocus()
    return self
end
function Window:CloseSearch(immediate)
    if not self.searchOpen then
        if immediate then
            if self.searchCancel then
                self.bag:Remove(self.searchCancel, true)
                self.searchCancel = nil
            end
            self.motion:To(self.searchPanel, 0, { GroupTransparency = 1 })
            self.searchPanel.Visible = false
            if not self.overlay.active then
                self:_dimState(false, 1, true)
            end
        end
        return self
    end
    self.searchOpen = false
    self.searchGeneration = (self.searchGeneration or 0) + 1
    local generation = self.searchGeneration
    self.searchBox:ReleaseFocus()
    self.motion:To(self.searchPanel, immediate and 0 or T.Motion.Fast, { GroupTransparency = 1 })
    if immediate then
        self.searchPanel.Visible = false
    else
        self.searchCancel = self.bag:After(T.Motion.Fast, function()
            if self.searchGeneration == generation and not self.searchOpen then
                self.searchPanel.Visible = false
            end
            self.searchCancel = nil
        end)
    end
    self:_dimState(false, 1, immediate)
    return self
end
function Window:SetSearchEnabled(value)
    self.searchEnabled = value == true
    if self.searchPreference and not self.searchPreference.destroyed then
        self.searchPreference:Set(self.searchEnabled, true)
    end
    self.searchButton.Visible = self.searchEnabled
    if not self.searchEnabled then
        self:CloseSearch()
    end
    return self
end
function Window:GetFlag(flag)
    return U.copy(self.Flags[flag])
end
function Window:SetFlag(flag, value, silent)
    local control = self.flagOwners[flag]
    if control and control.Set then
        control:Set(value, silent)
    end
    return self
end
function Library:RegisterIcon(name, asset)
    assert(
        type(name) == "string" and (type(asset) == "number" or type(asset) == "string"),
        "Neron icon expects name and asset id"
    )
    self.Icons[name] = asset
    return self
end
-- Hover/hold hints are non-modal. One pending timer and one tooltip per window.
function Tooltip.blocked(w, owner)
    return w.tooltip and w.tooltip.suppressed[owner] == true
end
function Tooltip.init(w, config)
    local self = setmetatable({ w = w, suppressed = setmetatable({}, { __mode = "k" }) }, { __index = Tooltip })
    w.tooltip, w.tooltipsEnabled = self, config.Tooltips ~= false
    w.bag:Add(function()
        self:Cancel()
    end)
end
function Tooltip:Hide()
    if self.pending then
        self.pending.bag:Destroy()
        self.pending = nil
    end
    if self.active then
        self.active.bag:Destroy()
        self.active = nil
    end
end
function Tooltip:Cancel()
    self:Hide()
    if self.touch then
        self.suppressed[self.touch.entry.owner] = nil
        self.touch = nil
    end
end
function Tooltip:valid(entry)
    local w = self.w
    return w.tooltipsEnabled
        and not w.destroyed
        and w.visible
        and entry.object.Parent
        and not entry.bag.dead
        and not w.searchOpen
        and not w.overlay.active
        and not w.confirmation
        and not w.transfer
        and not w.input.capture
        and not S.Input:GetFocusedTextBox()
        and entry.usable()
end
function Tooltip:Place()
    local a = self.active
    if not a then
        return
    end
    local w = self.w
    local view = w.stage.AbsoluteSize
    local p = a.entry.object.AbsolutePosition - w.stage.AbsolutePosition
    local sz = a.entry.object.AbsoluteSize
    local width, height = a.width * w.scale, a.height * w.scale
    local x = math.clamp(p.X, 8, math.max(8, view.X - width - 8))
    local y = p.Y + sz.Y + 6 * w.scale
    if y + height > view.Y - 8 then
        y = p.Y - height - 6 * w.scale
    end
    a.holder.Position = UDim2.fromOffset(x, math.clamp(y, 8, math.max(8, view.Y - height - 8)))
end
function Tooltip:Show(entry)
    if not self:valid(entry) then
        return
    end
    local ok, text = pcall(entry.text)
    if not ok or type(text) ~= "string" or text == "" then
        return
    end
    self:Hide()
    local w, bag = self.w, Maid.new(self.w.motion)
    local width = math.min(280, math.max(100, w.stage.AbsoluteSize.X / w.scale - 16))
    local bounds = S.Text:GetTextSize(text, T.Type.Value, Enum.Font.Gotham, Vector2.new(width - 24, 1000))
    width = math.max(80, math.min(width, bounds.X + 24))
    local height = math.min(164, math.max(32, bounds.Y + 20))
    local holder = U.frame(
        w.stage,
        { Name = "TooltipLayer", Size = UDim2.fromOffset(width * w.scale, height * w.scale), ZIndex = T.Z.Tooltip },
        w
    )
    bag:Add(holder)
    local panel = U.new("CanvasGroup", {
        Size = UDim2.fromOffset(width, height),
        BackgroundTransparency = 0,
        BackgroundColor3 = w.theme.PopoverBackground,
        GroupTransparency = 1,
        ZIndex = T.Z.Tooltip,
    }, holder)
    U.new("UIScale", { Scale = w.scale }, panel)
    U.corner(panel, T.Radius.Popover)
    local edge = U.stroke(panel, w.theme.SurfaceEdge, 1)
    edge.Transparency = 0.55
    U.bind(w, edge, "Color", "SurfaceEdge")
    U.bind(w, panel, "BackgroundColor3", "PopoverBackground")
    local label = U.label(panel, text, T.Type.Value, w.theme.SystemText, {
        Position = UDim2.fromOffset(12, 10),
        Size = UDim2.new(1, -24, 1, -20),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
    })
    U.bind(w, label, "TextColor3", "SystemText")
    self.active =
        { entry = entry, bag = bag, holder = holder, panel = panel, label = label, width = width, height = height }
    self:Place()
    w.motion:To(panel, T.Motion.Micro, { GroupTransparency = 0 })
    U.connect(bag, entry.object:GetPropertyChangedSignal("AbsolutePosition"), function()
        self:Place()
    end)
end
function Tooltip:Pend(entry, touch)
    if not self:valid(entry) then
        return
    end
    self:Cancel()
    if touch then
        self.touch = { entry = entry, input = touch, start = U.point(touch) }
    end
    local bag = Maid.new(self.w.motion)
    self.pending = { entry = entry, bag = bag }
    bag:After(touch and 0.55 or 0.35, function()
        if self.pending and self.pending.entry == entry then
            self:Show(entry)
            if touch and self.active and self.touch then
                self.suppressed[entry.owner] = true
            end
        end
    end)
end
function Tooltip:Changed(event)
    if self.touch and event == self.touch.input and (U.point(event) - self.touch.start).Magnitude > 10 then
        self:Hide()
    end
end
function Tooltip:Ended(event)
    local touch = self.touch
    if touch and event == touch.input then
        self:Hide()
        self.touch = nil
        touch.entry.bag:After(0.20, function()
            self.suppressed[touch.entry.owner] = nil
        end)
    end
end
function Tooltip.bind(w, owner, object, bag, text, usable)
    local entry = { owner = owner, object = object, bag = bag, text = text, usable = usable }
    U.connect(bag, object.MouseEnter, function()
        w.tooltip:Pend(entry)
    end)
    U.connect(bag, object.MouseLeave, function()
        if
            (w.tooltip.pending and w.tooltip.pending.entry == entry)
            or (w.tooltip.active and w.tooltip.active.entry == entry)
        then
            w.tooltip:Hide()
        end
    end)
    U.connect(bag, object.InputBegan, function(event)
        if event.UserInputType == Enum.UserInputType.Touch then
            w.tooltip:Pend(entry, event)
        end
    end)
    bag:Add(function()
        if
            (w.tooltip.pending and w.tooltip.pending.entry == entry)
            or (w.tooltip.active and w.tooltip.active.entry == entry)
            or (w.tooltip.touch and w.tooltip.touch.entry == entry)
        then
            w.tooltip:Cancel()
        end
        w.tooltip.suppressed[owner] = nil
    end)
end
function Window:SetTooltipsEnabled(value)
    if self.destroyed then
        return self
    end
    self.tooltipsEnabled = value == true
    if not self.tooltipsEnabled then
        self.tooltip:Cancel()
    end
    if self.tooltipPreference then
        self.tooltipPreference:Set(self.tooltipsEnabled, true)
    end
    return self
end
function Control:SetTooltip(text)
    self.tooltipText = tostring(text or "")
    if not self.destroyed then
        self.window.tooltip:Cancel()
    end
    return self
end
function Tab:SetTooltip(text)
    self.tooltipText = tostring(text or "")
    if not self.destroyed then
        self.window.tooltip:Cancel()
    end
    return self
end
function SubTab:SetTooltip(text)
    self.tooltipText = tostring(text or "")
    if not self.destroyed then
        self.window.tooltip:Cancel()
    end
    return self
end

-- Window geometry is presentation, never a game profile or entitlement.
function Geometry.dimensions(value)
    local x, y
    if typeof(value) == "Vector2" then
        x, y = value.X, value.Y
    elseif typeof(value) == "UDim2" and value.X.Scale == 0 and value.Y.Scale == 0 then
        x, y = value.X.Offset, value.Y.Offset
    elseif type(value) == "table" then
        x, y = value[1] or value.Width, value[2] or value.Height
    end
    if type(x) ~= "number" or type(y) ~= "number" or not U.finite(x) or not U.finite(y) or x <= 0 or y <= 0 then
        return nil
    end
    return Vector2.new(math.floor(x + 0.5), math.floor(y + 0.5))
end
function Geometry.layout(w)
    if not w.resizeGrip then
        return
    end
    w.resizeGrip.Visible = w.resizeEnabled
        and w.visible
        and not w.settingsOpen
        and not w.searchOpen
        and not w.confirmation
        and not w.transfer
        and not w.overlay.active
end
function Geometry.record(w, force)
    if w.destroyed or not w.persistence or (not force and not w.rememberSize and not w.rememberPosition) then
        return
    end
    Library.geometryPrefs = Library.geometryPrefs or {}
    local view = w.stage.AbsoluteSize
    Library.geometryPrefs[w.id] = {
        rememberSize = w.rememberSize,
        rememberPosition = w.rememberPosition,
        size = w.rememberSize and { w.baseWidth, w.baseHeight } or nil,
        position = w.rememberPosition and {
            math.clamp(w.root.Position.X.Offset / math.max(1, view.X), 0, 1),
            math.clamp(w.root.Position.Y.Offset / math.max(1, view.Y), 0, 1),
        } or nil,
    }
    local ids = {}
    for id in pairs(Library.geometryPrefs) do
        table.insert(ids, id)
    end
    table.sort(ids)
    while #ids > 64 do
        local id = table.remove(ids, 1)
        if id ~= w.id then
            Library.geometryPrefs[id] = nil
        else
            table.insert(ids, id)
        end
    end
    if w.geometryCancel then
        w.bag:Remove(w.geometryCancel, true)
    end
    w.geometryCancel = w.bag:After(0.30, function()
        w.geometryCancel = nil
        Geometry.flush(w)
    end)
end
function Geometry.flush(w)
    local contents, failure = w.persistence.store:Read("Neron/End/Theme.json")
    if not contents and failure == "InvalidJSON" then
        return false, failure
    end
    local data = contents and Storage.decode(contents) or nil
    if data and data.schemaVersion ~= 0 and data.schemaVersion ~= 1 then
        return false, "InvalidJSON"
    end
    local overrides = {}
    for token, color in pairs(w.themeOverrides) do
        overrides[token] = Presentation.colorData(color)
    end
    data = data
        or {
            theme = w.themeName,
            language = w.language,
            overrides = overrides,
            accent = w.customAccent and Presentation.colorData(w.customAccent),
        }
    data.schemaVersion, data.windows = 1, Library.geometryPrefs or {}
    return w.persistence.store:Write("Neron/End/Theme.json", data)
end
function Geometry.restore(w, prefs, config)
    Library.geometryPrefs = Library.geometryPrefs or {}
    local count = 0
    for id, record in pairs(type(prefs.windows) == "table" and prefs.windows or {}) do
        count += 1
        if count > 64 then
            break
        end
        if type(id) == "string" and #id <= 128 and type(record) == "table" and not Library.geometryPrefs[id] then
            local size = Geometry.dimensions(record.size)
            local pos = record.position
            local valid = type(pos) == "table"
                and type(pos[1]) == "number"
                and type(pos[2]) == "number"
                and U.finite(pos[1])
                and U.finite(pos[2])
            Library.geometryPrefs[id] = {
                rememberSize = record.rememberSize == true,
                rememberPosition = record.rememberPosition == true,
                size = size and { size.X, size.Y } or nil,
                position = valid and { math.clamp(pos[1], 0, 1), math.clamp(pos[2], 0, 1) } or nil,
            }
        end
    end
    local record = Library.geometryPrefs[w.id]
    if not record then
        return
    end
    -- Explicit constructor sizing wins over remembered geometry, including false (automatic).
    local size = config.ManualSize == nil and config.Size == nil and w.rememberSize and Geometry.dimensions(record.size)
    if size then
        w.baseWidth = math.clamp(size.X, w.minimumSize.X, w.maximumSize.X)
        w.baseHeight = math.clamp(size.Y, w.minimumSize.Y, w.maximumSize.Y)
        w.manualSize = true
        w.defaultDesktopSize = false
    end
    if w.rememberPosition and record.position then
        local view = w.stage.AbsoluteSize
        w.root.Position = UDim2.fromOffset(record.position[1] * view.X, record.position[2] * view.Y)
    end
    w:_responsive()
end
function Geometry.apply(w, size, capture)
    if w.destroyed then
        return false, "WindowDestroyed"
    end
    size = Geometry.dimensions(size)
    if not size then
        return false, "Invalid window dimensions"
    end
    w.baseWidth, w.baseHeight =
        math.clamp(size.X, w.minimumSize.X, w.maximumSize.X), math.clamp(size.Y, w.minimumSize.Y, w.maximumSize.Y)
    w.manualSize = true
    w.defaultDesktopSize = false
    w:_responsive(capture)
    if not capture then
        Geometry.record(w)
    end
    return true
end
function Window:SetSize(size)
    return Geometry.apply(self, size)
end
function Window:GetSize()
    return Vector2.new(self.baseWidth, self.baseHeight)
end
function Window:SetPosition(position)
    if self.destroyed or typeof(position) ~= "Vector2" or not U.finite(position.X) or not U.finite(position.Y) then
        return false, "Invalid window position"
    end
    self.root.Position = UDim2.fromOffset(position.X, position.Y)
    self:_responsive()
    Geometry.record(self)
    return true
end
function Window:GetPosition()
    return Vector2.new(self.root.Position.X.Offset, self.root.Position.Y.Offset)
end
function Window:SetResizable(value)
    if self.destroyed then
        return self
    end
    self.resizeEnabled = value == true
    if not self.resizeEnabled then
        self.input:Cancel(self.resizeOwner)
    end
    if self.resizePreference then
        self.resizePreference:Set(self.resizeEnabled, true)
    end
    self:_responsive()
    return self
end
function Window:SetRememberSize(value)
    if self.destroyed then
        return self
    end
    self.rememberSize = value == true
    if self.rememberSizePreference then
        self.rememberSizePreference:Set(self.rememberSize, true)
    end
    Geometry.record(self, true)
    return self
end
function Window:SetRememberPosition(value)
    if self.destroyed then
        return self
    end
    self.rememberPosition = value == true
    if self.rememberPositionPreference then
        self.rememberPositionPreference:Set(self.rememberPosition, true)
    end
    Geometry.record(self, true)
    return self
end
function Geometry.init(w, config)
    w.minimumSize = Geometry.dimensions(config.MinSize) or Vector2.new(320, 320)
    w.maximumSize = Geometry.dimensions(config.MaxSize)
        or Vector2.new(math.max(2048, w.baseWidth, w.minimumSize.X), math.max(1440, w.baseHeight, w.minimumSize.Y))
    w.baseWidth = math.clamp(w.baseWidth, w.minimumSize.X, w.maximumSize.X)
    w.baseHeight = math.clamp(w.baseHeight, w.minimumSize.Y, w.maximumSize.Y)
    w.resizeEnabled, w.rememberSize, w.rememberPosition =
        config.Resizable ~= false, config.RememberSize == true, config.RememberPosition == true
    w.resizeGrip = U.button(w.root, {
        Name = "ResizeGrip",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1, 1),
        Size = UDim2.fromOffset(44, 44),
        ZIndex = 15,
    })
    local glyph =
        U.frame(w.resizeGrip, { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -19, 1, -19), ZIndex = 16 }, w)
    Icons.line(glyph, 0.22, 0.82, 0.82, 0.22, w.theme.TextMuted)
    Icons.line(glyph, 0.51, 0.82, 0.82, 0.51, w.theme.TextMuted)
    local owner = { state = { Hovered = false, Pressed = false } }
    w.resizeOwner = owner
    function owner:_render()
        Icons.color(
            glyph,
            self.state.Pressed and w.theme.Accent or (self.state.Hovered and w.theme.TextSecondary or w.theme.TextMuted)
        )
    end
    w.systemRenders = w.systemRenders or {}
    w.systemRenders[w.resizeGrip] = owner
    w.bag:Add(function()
        w.systemRenders[w.resizeGrip] = nil
        w.input:Cancel(owner)
    end)
    U.connect(w.bag, w.resizeGrip.MouseEnter, function()
        owner.state.Hovered = true
        owner:_render()
    end)
    U.connect(w.bag, w.resizeGrip.MouseLeave, function()
        owner.state.Hovered = false
        owner:_render()
    end)
    U.connect(w.bag, w.resizeGrip.InputBegan, function(event)
        if not U.primary(event) or not w.resizeGrip.Visible or not w.input:CanStart(event) then
            return
        end
        local start, size, scale = U.point(event), w.root.Size, w.scale
        local view = w.stage.AbsoluteSize
        local p = w.root.AbsolutePosition - w.stage.AbsolutePosition
        local left, top = math.max(8, p.X), math.max(12, p.Y)
        local maxX =
            math.max(w.minimumSize.X, math.min(w.maximumSize.X, (view.X - left - 8) / scale, (view.X - 16) / scale))
        local maxY =
            math.max(w.minimumSize.Y, math.min(w.maximumSize.Y, (view.Y - top - 12) / scale, (view.Y - 24) / scale))
        owner.state.Pressed = true
        owner:_render()
        w.input:Start(owner, event, function(point)
            local x = math.clamp(size.X.Offset + (point.X - start.X) / scale, w.minimumSize.X, maxX)
            local y = math.clamp(size.Y.Offset + (point.Y - start.Y) / scale, w.minimumSize.Y, maxY)
            Geometry.apply(w, Vector2.new(x, y), true)
            w.root.Position =
                UDim2.fromOffset(left + w.root.Size.X.Offset * w.scale / 2, top + w.root.Size.Y.Offset * w.scale / 2)
        end, function()
            owner.state.Pressed = false
            owner:_render()
            Geometry.record(w)
        end)
    end)
    Tooltip.bind(w, owner, w.resizeGrip, w.bag, function()
        return w:Translate("DragToResize")
    end, function()
        return w.resizeGrip.Visible
    end)
    owner:_render()
    Geometry.layout(w)
end

-- Premium is supplied by the consumer's validation service; never inferred or saved as entitlement.
function Premium.normalize(data)
    if data == nil then
        return {}
    end
    if type(data) ~= "table" or (data.Active ~= nil and type(data.Active) ~= "boolean") then
        return nil
    end
    local expiry = data.ExpiresAt
    if expiry ~= nil and (type(expiry) ~= "number" or not U.finite(expiry) or expiry <= 0 or expiry > 253402300799) then
        return nil
    end
    if data.Plan ~= nil and (type(data.Plan) ~= "string" or #data.Plan > 80) then
        return nil
    end
    return { Active = data.Active, ExpiresAt = expiry and math.floor(expiry), Plan = data.Plan }
end
function Window:GetPremiumStatus()
    local data = self.premiumData or {}
    local known = data.Active ~= nil
    local expired = data.Active == true and data.ExpiresAt ~= nil and data.ExpiresAt <= os.time()
    return {
        Status = not known and "NotVerified" or (expired and "Expired" or (data.Active and "Active" or "Inactive")),
        Active = data.Active == true and not expired,
        Known = known,
        ExpiresAt = data.ExpiresAt,
        Plan = data.Plan,
    }
end
function Premium.refresh(w)
    if w.destroyed or not w.premiumStatusRow then
        return
    end
    local data = w:GetPremiumStatus()
    local theme = w.theme
    w.premiumStatusRow:_commit(w:Translate(data.Status), true)
    w.premiumStatusRow.valueLabel.Text = w:Translate(data.Status)
    w.premiumStatusRow.valueLabel.TextColor3 = data.Active and theme.Success
        or (data.Status == "Expired" and theme.Warning or theme.TextSecondary)
    local expiry = w:Translate("NotProvided")
    if data.ExpiresAt then
        local ok, value = pcall(os.date, "!%Y-%m-%d %H:%M UTC", data.ExpiresAt)
        if ok then
            expiry = value
        end
    end
    w.premiumExpiryRow.valueLabel.Text = expiry
    w.premiumPlanRow.valueLabel.Text = data.Plan or w:Translate("NotProvided")
    w.premiumPlanRow:SetVisible(data.Plan ~= nil)
    w.premiumBuy:SetVisible(not data.Active)
end
function Premium.schedule(w)
    if w.premiumCancel then
        w.bag:Remove(w.premiumCancel, true)
        w.premiumCancel = nil
    end
    local data = w:GetPremiumStatus()
    if data.Active and data.ExpiresAt then
        w.premiumCancel = w.bag:After(math.min(86400, data.ExpiresAt - os.time()), function()
            w.premiumCancel = nil
            Premium.refresh(w)
            Premium.schedule(w)
        end)
    end
end
function Window:SetPremiumStatus(data)
    if self.destroyed then
        return false, "WindowDestroyed"
    end
    local parsed = Premium.normalize(data)
    if not parsed then
        return false, "Invalid Premium status"
    end
    self.premiumData = parsed
    Premium.refresh(self)
    Premium.schedule(self)
    return true
end
function Premium.row(w, page, key)
    local control = Components.row(page, { Name = w:Translate(key), Persistent = false }, "PremiumInfo")
    w.systemControls[control] = { name = key }
    control.valueLabel = U.label(
        control.lane,
        "",
        11,
        w.theme.SystemText,
        { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Right }
    )
    U.bind(w, control.valueLabel, "TextColor3", "SystemText")
    function control:layoutVisual()
        local width = self.row.AbsoluteSize.X / w.scale
        local lane = math.max(72, (width - 32) * 0.58)
        self.row.Size = UDim2.new(1, 0, 0, 40)
        self.label.Position = UDim2.fromOffset(16, 10)
        self.label.Size = UDim2.fromOffset(math.max(30, width - lane - 44), 20)
        self.lane.Size = UDim2.fromOffset(lane, 40)
        self.lane.Position = UDim2.new(1, -16, 0, 0)
    end
    control:_layout()
    control:_render()
    return control
end
function Premium.build(w, page)
    SettingsUI.heading(w, page, "Premium", "PremiumBody")
    w.premiumStatusRow = Premium.row(w, page, "PremiumStatus")
    w.premiumExpiryRow = Premium.row(w, page, "PremiumExpiry")
    w.premiumPlanRow = Premium.row(w, page, "PremiumPlan")
    w.premiumBuy = SettingsUI.control(w, page, "AddButton", "BuyPremium", {
        Primary = true,
        Callback = function()
            if w.premiumPurchaseBusy or w:GetPremiumStatus().Active then
                return
            end
            if type(w.onBuyPremium) ~= "function" then
                w:Notify("PremiumRequired", w:Translate("PurchaseNotConfigured"), "Warning")
                return
            end
            w.premiumPurchaseBusy = true
            local ok, err = xpcall(function()
                w.onBuyPremium(nil, w)
            end, debug.traceback)
            w.premiumPurchaseBusy = false
            if not ok then
                U.warn("Buy Premium", err)
                if not w.destroyed then
                    w:Notify("Failed", nil, "Danger")
                end
            end
        end,
    })
    local press = w.premiumBuy.Press
    function w.premiumBuy:Press()
        if self.emitting or w.premiumPurchaseBusy then
            return self
        end
        return press(self)
    end
    Premium.refresh(w)
end

function Library:CreateWindow(config)
    config = config or {}
    assert(
        config.Filesystem == nil or type(config.Filesystem) == "table",
        "Neron Filesystem expects an API adapter table"
    )
    assert(
        config.OnBuyPremium == nil or type(config.OnBuyPremium) == "function",
        "Neron OnBuyPremium expects a function"
    )
    local manual = config.ManualSize
    local size
    if manual == true then
        size = Vector2.new(T.Geometry.ManualWidth, T.Geometry.ManualHeight)
    elseif manual == nil or manual == false then
        size = config.Size or Vector2.new(T.Geometry.Width, T.Geometry.Height)
    else
        size = manual
    end
    size = Geometry.dimensions(size)
    assert(size, "Neron ManualSize/Size expects Vector2, offset UDim2 or {width,height}")
    local minimum = config.MinSize and Geometry.dimensions(config.MinSize)
    local maximum = config.MaxSize and Geometry.dimensions(config.MaxSize)
    assert(
        config.MinSize == nil or (minimum and minimum.X >= 320 and minimum.Y >= 320),
        "Neron MinSize must be at least320x320"
    )
    assert(
        config.MaxSize == nil
            or (maximum and maximum.X >= (minimum and minimum.X or 320) and maximum.Y >= (minimum and minimum.Y or 320)),
        "Neron MaxSize must contain MinSize"
    )
    local baseWidth, baseHeight = size.X, size.Y
    assert(baseWidth >= 320 and baseHeight >= 320, "Neron window Size must be at least 320x320")
    assert(config.Accent == nil or typeof(config.Accent) == "Color3", "Neron window Accent expects Color3")
    local env = _G
    if type(getgenv) == "function" then
        local ok, value = pcall(getgenv)
        if ok and type(value) == "table" then
            env = value
        end
    end
    local registry = env.__NeronUiWindows
    if type(registry) ~= "table" then
        registry = {}
        pcall(function()
            env.__NeronUiWindows = registry
        end)
    end
    local id = tostring(config.Id or "Main"):gsub("[^%w_%-]", "_")
    local parent = config.Parent
    if not parent then
        local hui = env.gethui or gethui
        if type(hui) == "function" then
            local ok, value = pcall(hui)
            if ok then
                parent = value
            end
        end
        if not parent then
            local probe = Instance.new("Folder")
            local ok = pcall(function()
                probe.Parent = S.Core
            end)
            probe:Destroy()
            if ok then
                parent = S.Core
            else
                local player = S.Players.LocalPlayer
                assert(player, "NeronUi requires a client LocalPlayer")
                parent = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
            end
        end
    end
    assert(typeof(parent) == "Instance", "NeronUi needs an accessible GUI parent")
    if registry[id] and registry[id].Destroy then
        registry[id]:Destroy()
    end
    local name = "NeronUi_" .. id
    local old = parent:FindFirstChild(name)
    if old then
        local unload = old:FindFirstChild("NeronUnload")
        if unload and unload:IsA("BindableEvent") then
            unload:Fire()
        end
        old:Destroy()
    end
    local w = setmetatable({
        id = id,
        registry = registry,
        bag = Maid.new(),
        motion = Motion.new(),
        theme = table.clone(Theme),
        bindings = setmetatable({}, { __mode = "k" }),
        tabs = {},
        categories = {},
        categoryOrder = {},
        index = {},
        Flags = {},
        flagOwners = {},
        visible = config.Visible ~= false,
        scale = 1,
        pressed = setmetatable({}, { __mode = "k" }),
        name = tostring(config.Name or "NERON"),
        searchEnabled = config.Search ~= false,
        manualSize = config.ManualSize ~= nil and config.ManualSize ~= false,
        defaultDesktopSize = (config.ManualSize == nil or config.ManualSize == false)
            and config.Size == nil
            and (not S.Input.TouchEnabled or (S.Input.KeyboardEnabled == true and S.Input.MouseEnabled == true)),
        onBuyPremium = config.OnBuyPremium,
    }, Window)
    w.bag.motion = w.motion
    registry[id] = w
    w.baseWidth = baseWidth
    w.baseHeight = baseHeight
    w.gui = U.new("ScreenGui", {
        Name = name,
        Enabled = w.visible,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = config.DisplayOrder or 50,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, parent)
    U.owners[w.gui] = w
    w.bag:Add(w.gui)
    local unload = U.new("BindableEvent", { Name = "NeronUnload" }, w.gui)
    U.connect(w.bag, unload.Event, function()
        w:Destroy()
    end)
    U.connect(w.bag, w.gui.Destroying, function()
        if not w.destroyed then
            w:Destroy()
        end
    end)
    w.stage = U.frame(w.gui, { Name = "Viewport", Size = UDim2.fromScale(1, 1), ZIndex = 1 }, w)
    w.root = U.new("CanvasGroup", {
        GroupTransparency = 0,
        BackgroundTransparency = 0,
        BackgroundColor3 = w.theme.WindowBackground,
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(w.baseWidth, w.baseHeight),
        ClipsDescendants = true,
        ZIndex = T.Z.Shell,
    }, w.stage)
    U.bind(w, w.root, "BackgroundColor3", "WindowBackground")
    U.corner(w.root, T.Radius.Window)
    local edge = U.stroke(w.root, w.theme.SurfaceEdge, 1)
    edge.Transparency = 0.45
    U.bind(w, edge, "Color", "SurfaceEdge")
    w.uiScale = U.new("UIScale", { Scale = 1 }, w.root)
    w.content = U.frame(w.root, {
        Name = "Content",
        Position = UDim2.fromOffset(T.Geometry.Sidebar, 0),
        Size = UDim2.new(1, -T.Geometry.Sidebar, 1, 0),
        ClipsDescendants = true,
        ZIndex = T.Z.Content,
    }, w, "ContentBackground")
    w.sidebar = U.frame(
        w.root,
        { Name = "Sidebar", Size = UDim2.new(0, T.Geometry.Sidebar, 1, 0), ZIndex = T.Z.Shell + 1 },
        w,
        "SidebarBackground"
    )
    U.frame(
        w.sidebar,
        { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), ZIndex = w.sidebar.ZIndex + 1 },
        w,
        "Separator"
    )
    w.brandIcon = Icons.make(w.sidebar, "brand", 24, w.theme.Accent, w)
    w.brandIcon.Position = UDim2.fromOffset(48, 20)
    w.brand = U.label(
        w.sidebar,
        w.name,
        T.Type.Brand,
        w.theme.TextPrimary,
        { Position = UDim2.fromOffset(82, 18), Size = UDim2.fromOffset(100, 28), Font = Enum.Font.GothamBold }
    )
    w.suffixLabel = U.label(
        w.sidebar,
        config.Suffix or "CORP.",
        T.Type.Suffix,
        w.theme.TextSecondary,
        { Size = UDim2.fromOffset(45, 20), Font = Enum.Font.GothamBold }
    )
    U.bind(w, w.brand, "TextColor3", "TextPrimary")
    U.bind(w, w.suffixLabel, "TextColor3", "TextSecondary")
    w:_brandLayout()
    local sideHost = U.frame(
        w.sidebar,
        { Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 1, -112), ZIndex = w.sidebar.ZIndex + 1 },
        w
    )
    w.input = Input.new(w)
    w.overlay = Overlay.new(w)
    Tooltip.init(w, config)
    w.sidebarScroll = Scroll.make(w, sideHost, w.bag, 0, true)
    w.dragZone = U.button(w.content, { Name = "DragZone", Size = UDim2.new(1, -58, 0, 58), ZIndex = T.Z.Content + 5 })
    w.searchButton = U.button(w.content, {
        Name = "Search",
        Position = UDim2.new(1, -48, 0, 14),
        Size = UDim2.fromOffset(32, 32),
        ZIndex = T.Z.Content + 6,
        Visible = w.searchEnabled,
    })
    local searchIcon = Icons.make(w.searchButton, "search", 14, w.theme.TextSecondary, w)
    searchIcon.Position = UDim2.fromOffset(9, 9)
    w.menu = U.button(w.content, {
        Name = "Navigation",
        Position = UDim2.fromOffset(8, 12),
        Size = UDim2.fromOffset(32, 32),
        Visible = false,
        ZIndex = T.Z.Content + 6,
    })
    local menuIcon = Icons.make(w.menu, "menu", 16, w.theme.TextSecondary, w)
    menuIcon.Position = UDim2.fromOffset(8, 8)
    w.drawerShade = U.button(w.root, {
        Name = "DrawerShade",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.4,
        BackgroundColor3 = Color3.new(0, 0, 0),
        Visible = false,
        ZIndex = 11,
    })
    w.dim = U.button(w.root, {
        Name = "Deemphasis",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BackgroundColor3 = Color3.new(0, 0, 0),
        Visible = false,
        ZIndex = T.Z.Dim,
    })
    w.popoverLayer = U.frame(w.stage, { Name = "PopoverLayer", Size = UDim2.fromScale(1, 1), ZIndex = T.Z.Popover }, w)
    w.searchPanel = U.new("CanvasGroup", {
        Name = "SearchLayer",
        Position = UDim2.new(0, T.Geometry.SearchInset, 0, T.Geometry.Header),
        Size = UDim2.new(1, -T.Geometry.SearchInset * 2, 1, -T.Geometry.Header - 18),
        Visible = false,
        GroupTransparency = 1,
        BackgroundTransparency = 0,
        BackgroundColor3 = w.theme.PopoverBackground,
        ZIndex = T.Z.Search,
        ClipsDescendants = true,
    }, w.root)
    U.corner(w.searchPanel, 3)
    w.searchBox = U.new("TextBox", {
        Name = "Query",
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -48, 0, 44),
        Text = "",
        PlaceholderText = "Search for your function",
        ClearTextOnFocus = false,
        TextSize = T.Type.Value,
        Font = Enum.Font.Gotham,
        TextColor3 = w.theme.TextPrimary,
        PlaceholderColor3 = w.theme.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = T.Z.Search + 1,
    }, w.searchPanel)
    local searchGlyph = Icons.make(w.searchPanel, "search", 12, w.theme.TextMuted, w)
    searchGlyph.Position = UDim2.new(1, -26, 0, 16)
    U.frame(
        w.searchPanel,
        { Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 1), ZIndex = T.Z.Search + 1 },
        w,
        "Separator"
    )
    local resultsHost = U.frame(
        w.searchPanel,
        { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -56), ZIndex = T.Z.Search + 1 },
        w
    )
    w.searchScroll = Scroll.make(w, resultsHost, w.bag, 6, true)
    w.searchEmpty = U.frame(resultsHost, { Size = UDim2.fromScale(1, 1), ZIndex = T.Z.Search + 3 }, w)
    local emptyIcon = Icons.make(w.searchEmpty, "empty", 50, w.theme.TextDisabled, w)
    emptyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    emptyIcon.Position = UDim2.fromScale(0.5, 0.4)
    U.label(w.searchEmpty, "No matching settings", T.Type.Description, w.theme.TextMuted, {
        Position = UDim2.new(0, 0, 0.4, 32),
        Size = UDim2.new(1, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    U.connect(w.bag, w.searchButton.Activated, function()
        w:OpenSearch()
    end)
    U.connect(w.bag, w.searchBox:GetPropertyChangedSignal("Text"), function()
        if w.searchOpen then
            w:_searchResults(w.searchBox.Text)
        end
    end)
    U.connect(w.bag, w.menu.Activated, function()
        w:SetSidebarVisible(not w.sidebarOpen)
    end)
    U.connect(w.bag, w.drawerShade.Activated, function()
        w:SetSidebarVisible(false)
    end)
    U.connect(w.bag, w.dim.Activated, function()
        if w.settingsOpen then
            w:CloseSettings()
        elseif w.searchOpen then
            w:CloseSearch()
        else
            w.overlay:Close()
        end
    end)
    U.connect(w.bag, S.Input.InputBegan, function(event, processed)
        if w.destroyed or not w.visible then
            return
        end
        if event.KeyCode == Enum.KeyCode.Escape then
            if w.transfer then
                SettingsUI.dismissTransfer(w)
            elseif w.confirmation then
                SettingsUI.dismissConfirmation(w)
            elseif w.overlay.active then
                w.overlay:Close()
            elseif w.settingsOpen then
                w:CloseSettings()
            elseif w.searchOpen then
                w:CloseSearch()
            else
                w.overlay:Close()
            end
        elseif
            not processed
            and event.KeyCode == Enum.KeyCode.F
            and (S.Input:IsKeyDown(Enum.KeyCode.LeftControl) or S.Input:IsKeyDown(Enum.KeyCode.RightControl))
        then
            w:OpenSearch()
        elseif U.primary(event) then
            local a = w.overlay.active
            if a and not U.inside(a.holder, U.point(event)) and not U.inside(a.anchor, U.point(event)) then
                w.overlay:Close()
            end
        end
    end)
    if config.Draggable ~= false then
        local function drag(event)
            if not U.primary(event) or w.searchOpen or w.settingsOpen or w.overlay.active then
                return
            end
            local start = U.point(event)
            local center = w.root.Position
            w.input:Start(w, event, function(p)
                local view = w.stage.AbsoluteSize
                local size = w.root.AbsoluteSize
                local x = center.X.Offset + (p.X - start.X)
                local y = center.Y.Offset + (p.Y - start.Y)
                x = math.clamp(x, 48 - size.X * 0.5, view.X - 48 + size.X * 0.5)
                y = math.clamp(y, 16 + size.Y * 0.5, view.Y - 32 + size.Y * 0.5)
                w.root.Position = UDim2.fromOffset(x, y)
            end, function()
                Geometry.record(w)
            end)
        end
        U.connect(w.bag, w.dragZone.InputBegan, drag)
        local brandDrag =
            U.button(w.sidebar, { Name = "BrandDrag", Size = UDim2.new(1, 0, 0, 56), ZIndex = w.sidebar.ZIndex + 5 })
        U.connect(w.bag, brandDrag.InputBegan, drag)
    end
    U.connect(w.bag, w.stage:GetPropertyChangedSignal("AbsoluteSize"), function()
        w:_responsive()
    end)
    Geometry.init(w, config)
    w:_responsive()
    Presentation.init(w, config)
    Profiles.init(w, config)
    w.premiumData = Premium.normalize(config.Premium) or {}
    Premium.schedule(w)
    SettingsUI.init(w, config)
    if config.Accent then
        w:SetAccent(config.Accent)
    end
    return w
end

-- Semantic presentation: bindings are weak, updates event-driven, state remains authoritative.
Presentation.themes = {
    ["Neron Dark"] = table.clone(Theme),
    Graphite = {
        WindowBackground = Color3.fromRGB(24, 25, 28),
        SidebarBackground = Color3.fromRGB(28, 29, 33),
        HeaderBackground = Color3.fromRGB(26, 27, 30),
        ContentBackground = Color3.fromRGB(23, 24, 27),
        RowBackground = Color3.fromRGB(28, 29, 33),
        RowHover = Color3.fromRGB(33, 35, 40),
        RowPressed = Color3.fromRGB(38, 40, 46),
        SurfaceSecondary = Color3.fromRGB(34, 36, 41),
        SurfaceSelected = Color3.fromRGB(40, 43, 49),
        PopoverBackground = Color3.fromRGB(29, 31, 36),
        InputBackground = Color3.fromRGB(34, 36, 42),
        Separator = Color3.fromRGB(43, 45, 51),
        BorderWeak = Color3.fromRGB(48, 51, 58),
        SurfaceEdge = Color3.fromRGB(55, 58, 66),
        BorderStrong = Color3.fromRGB(85, 92, 107),
        TextPrimary = Color3.fromRGB(226, 229, 235),
        TextSecondary = Color3.fromRGB(102, 106, 118),
        TextMuted = Color3.fromRGB(77, 82, 93),
        TextDisabled = Color3.fromRGB(54, 58, 67),
        SystemText = Color3.fromRGB(159, 166, 179),
        Accent = Color3.fromRGB(125, 149, 187),
        ToggleTrackOff = Color3.fromRGB(44, 48, 56),
        ToggleTrackOn = Color3.fromRGB(73, 96, 131),
        ToggleKnobOff = Color3.fromRGB(110, 120, 137),
        ToggleKnobOn = Color3.fromRGB(182, 207, 238),
        SliderTrack = Color3.fromRGB(39, 42, 48),
        SliderCore = Color3.fromRGB(37, 43, 53),
        DropdownBackground = Color3.fromRGB(32, 34, 39),
        DropdownHover = Color3.fromRGB(42, 45, 52),
        ButtonText = Color3.fromRGB(20, 26, 36),
    },
    OLED = {
        WindowBackground = Color3.fromRGB(0, 0, 0),
        SidebarBackground = Color3.fromRGB(5, 5, 7),
        ContentBackground = Color3.fromRGB(2, 2, 4),
        HeaderBackground = Color3.fromRGB(3, 3, 5),
        RowBackground = Color3.fromRGB(7, 7, 10),
        RowHover = Color3.fromRGB(13, 12, 18),
        RowPressed = Color3.fromRGB(18, 16, 24),
        SurfaceSecondary = Color3.fromRGB(12, 11, 17),
        SurfaceSelected = Color3.fromRGB(19, 16, 28),
        PopoverBackground = Color3.fromRGB(9, 8, 14),
        InputBackground = Color3.fromRGB(14, 12, 20),
        Separator = Color3.fromRGB(23, 21, 29),
        BorderWeak = Color3.fromRGB(28, 25, 35),
        SurfaceEdge = Color3.fromRGB(31, 28, 39),
        TextPrimary = Color3.fromRGB(231, 227, 240),
        TextSecondary = Color3.fromRGB(84, 79, 97),
        TextMuted = Color3.fromRGB(61, 56, 74),
        TextDisabled = Color3.fromRGB(39, 36, 47),
        SystemText = Color3.fromRGB(154, 145, 173),
        Accent = Color3.fromRGB(148, 125, 200),
        ToggleTrackOff = Color3.fromRGB(24, 20, 32),
        ToggleTrackOn = Color3.fromRGB(83, 64, 123),
        ToggleKnobOff = Color3.fromRGB(95, 83, 115),
        ToggleKnobOn = Color3.fromRGB(190, 166, 232),
        SliderTrack = Color3.fromRGB(16, 13, 22),
        SliderCore = Color3.fromRGB(24, 18, 36),
        DropdownBackground = Color3.fromRGB(12, 10, 17),
        DropdownHover = Color3.fromRGB(21, 17, 30),
    },
    Light = {
        AppBackground = Color3.fromRGB(223, 226, 232),
        WindowBackground = Color3.fromRGB(247, 248, 250),
        SidebarBackground = Color3.fromRGB(237, 239, 244),
        HeaderBackground = Color3.fromRGB(245, 246, 249),
        ContentBackground = Color3.fromRGB(244, 245, 248),
        RowBackground = Color3.fromRGB(249, 250, 252),
        RowHover = Color3.fromRGB(237, 235, 245),
        RowPressed = Color3.fromRGB(227, 224, 240),
        SurfaceSecondary = Color3.fromRGB(235, 237, 243),
        SurfaceSelected = Color3.fromRGB(226, 223, 239),
        PopoverBackground = Color3.fromRGB(251, 252, 254),
        InputBackground = Color3.fromRGB(230, 232, 239),
        Separator = Color3.fromRGB(218, 220, 228),
        BorderWeak = Color3.fromRGB(207, 210, 220),
        BorderStrong = Color3.fromRGB(139, 130, 175),
        SurfaceEdge = Color3.fromRGB(196, 200, 212),
        TextPrimary = Color3.fromRGB(30, 31, 41),
        TextSecondary = Color3.fromRGB(103, 106, 122),
        TextMuted = Color3.fromRGB(135, 138, 151),
        TextDisabled = Color3.fromRGB(177, 179, 190),
        SystemText = Color3.fromRGB(78, 82, 99),
        Accent = Color3.fromRGB(108, 94, 163),
        ToggleTrackOff = Color3.fromRGB(198, 200, 211),
        ToggleTrackOn = Color3.fromRGB(130, 114, 180),
        ToggleKnobOff = Color3.fromRGB(250, 251, 253),
        ToggleKnobOn = Color3.fromRGB(252, 250, 255),
        SliderTrack = Color3.fromRGB(216, 218, 230),
        SliderCore = Color3.fromRGB(226, 222, 239),
        DropdownBackground = Color3.fromRGB(234, 236, 242),
        DropdownHover = Color3.fromRGB(223, 224, 235),
        ButtonText = Color3.fromRGB(252, 250, 255),
        Success = Color3.fromRGB(39, 134, 80),
        Warning = Color3.fromRGB(155, 111, 30),
        Danger = Color3.fromRGB(179, 55, 65),
    },
}
Presentation.order = { "Neron Dark", "Graphite", "OLED", "Light" }
function Presentation.colors(name, overrides, accent)
    local theme = table.clone(Theme)
    for token, value in pairs(Presentation.themes[name] or {}) do
        theme[token] = value
    end
    for token, value in pairs(overrides or {}) do
        if Theme[token] and typeof(value) == "Color3" then
            theme[token] = value
        end
    end
    local color = accent or theme.Accent
    theme.Accent = color
    theme.AccentHover = (not accent and overrides and overrides.AccentHover) or color:Lerp(Color3.new(1, 1, 1), 0.10)
    theme.AccentPressed = (not accent and overrides and overrides.AccentPressed)
        or color:Lerp(Color3.new(0, 0, 0), 0.22)
    theme.AccentMuted = (not accent and overrides and overrides.AccentMuted) or color:Lerp(theme.WindowBackground, 0.76)
    theme.SliderFill = accent or (overrides and overrides.SliderFill) or color
    theme.SliderKnob = accent or (overrides and overrides.SliderKnob) or color
    if accent then
        theme.ToggleTrackOn = color:Lerp(theme.WindowBackground, 0.68)
        theme.ToggleKnobOn = color:Lerp(Color3.new(1, 1, 1), 0.04)
    end
    return theme
end
function Presentation.apply(w)
    if w.destroyed then
        return
    end
    w.theme = Presentation.colors(w.themeName, w.themeOverrides, w.customAccent)
    for obj, bindings in pairs(w.bindings) do
        if obj.Parent then
            for property, token in pairs(bindings) do
                if obj[property] ~= w.theme[token] then
                    w.motion:Cancel(obj, property)
                    obj[property] = w.theme[token]
                end
            end
        else
            w.bindings[obj] = nil
        end
    end
    Icons.color(w.brandIcon, w.theme.Accent)
    for _, tab in ipairs(w.tabs) do
        tab:_render()
        for _, sub in ipairs(tab.subtabs) do
            sub:_render()
            for _, control in ipairs(sub.controls) do
                control:_render()
            end
        end
    end
    for _, page in pairs(w.settingsPages or {}) do
        for _, control in ipairs(page.controls) do
            control:_render()
        end
    end
    if w.searchOpen then
        w:_searchResults(w.searchBox.Text)
    end
    for button, owner in pairs(w.systemRenders or {}) do
        if button.Parent then
            owner:_render()
        else
            w.systemRenders[button] = nil
        end
    end
    if
        w.accentPreference
        and not w.accentPreference.destroyed
        and not U.equal(w.accentPreference.value, w.theme.Accent)
    then
        w.accentPreference:Set(w.theme.Accent, true)
    end
    if SettingsUI.refreshStyle then
        SettingsUI.refreshStyle(w)
    end
    if w.premiumData then
        Premium.refresh(w)
    end
end
function Presentation.remember(w)
    Library.themeName, Library.themeOverrides, Library.customAccent =
        w.themeName, table.clone(w.themeOverrides), w.customAccent
end
function Presentation.init(w, config)
    Library.windows = Library.windows or setmetatable({}, { __mode = "k" })
    Library.windows[w] = true
    w.themeName = Presentation.themes[config.Theme] and config.Theme or Library.themeName or "Neron Dark"
    w.themeOverrides = config.Theme == nil and table.clone(Library.themeOverrides or {}) or {}
    w.customAccent = config.Accent or (config.Theme == nil and Library.customAccent or nil)
    w.localeBindings = setmetatable({}, { __mode = "k" })
    w.language = Locale.dictionaries[config.Language] and config.Language or Library.language or "English"
    Presentation.apply(w)
    Locale.bind(w, w.searchBox, "PlaceholderText", "Search")
    for _, obj in ipairs(w.searchEmpty:GetDescendants()) do
        if obj:IsA("TextLabel") then
            Locale.bind(w, obj, "Text", "NoMatches")
        end
    end
end
function Window:SetTheme(name, silent)
    if self.destroyed or not Presentation.themes[name] then
        return false, "Unknown theme"
    end
    self.themeName, self.themeOverrides, self.customAccent = name, {}, nil
    Presentation.remember(self)
    Presentation.apply(self)
    if not silent and self.persistence then
        self.persistence:QueuePresentation()
    end
    return true
end
function Window:GetTheme()
    return self.themeName
end
function Window:GetThemeTokens()
    return table.clone(self.theme)
end
function Library:SetTheme(name)
    if not Presentation.themes[name] then
        return false, "Unknown theme"
    end
    self.themeName, self.themeOverrides, self.customAccent = name, {}, nil
    for w in pairs(self.windows or {}) do
        w:SetTheme(name)
    end
    return true
end
function Library:GetTheme()
    return self.themeName or "Neron Dark"
end
function Library:GetThemes()
    return table.clone(Presentation.order)
end
function Presentation.colorData(color)
    return { color.R, color.G, color.B }
end
function Presentation.decodeColor(value)
    if typeof(value) == "Color3" then
        return value
    end
    if type(value) ~= "table" or #value ~= 3 then
        return nil
    end
    for i = 1, 3 do
        if type(value[i]) ~= "number" or U.finite(value[i], nil) == nil then
            return nil
        end
    end
    return Color3.new(math.clamp(value[1], 0, 1), math.clamp(value[2], 0, 1), math.clamp(value[3], 0, 1))
end
function Window:ExportTheme()
    local values = {}
    for token, color in pairs(self.theme) do
        values[token] = Presentation.colorData(color)
    end
    return Storage.encode({ schemaVersion = 1, name = self.themeName, base = self.themeName, colors = values })
end
function Window:ImportTheme(json, silent)
    if self.destroyed then
        return false, "WindowDestroyed"
    end
    local data, err = Storage.decode(json)
    if not data then
        return false, err
    end
    if data.schemaVersion ~= 1 or type(data.colors) ~= "table" then
        return false, "Invalid theme schema"
    end
    local overrides, count = {}, 0
    for token, value in pairs(data.colors) do
        if Theme[token] then
            local color = Presentation.decodeColor(value)
            if not color then
                return false, "Invalid theme color: " .. token
            end
            overrides[token], count = color, count + 1
        end
    end
    if count == 0 then
        return false, "Theme contains no known colors"
    end
    self.themeName = Presentation.themes[data.base] and data.base or "Neron Dark"
    self.themeOverrides, self.customAccent = overrides, nil
    Presentation.remember(self)
    Presentation.apply(self)
    if not silent and self.persistence then
        self.persistence:QueuePresentation()
    end
    return true
end

-- System labels only. Consumer labels remain untouched unless explicitly bound by the consumer.
Locale.order = { "English", "Spanish", "Russian", "Portuguese" }
Locale.rows = {
    Settings = { "Settings", "Configuración", "Настройки", "Configurações" },
    Profiles = { "Profiles", "Perfiles", "Профили", "Perfis" },
    Themes = { "Themes", "Temas", "Темы", "Temas" },
    Language = { "Language", "Idioma", "Язык", "Idioma" },
    General = { "General", "General", "Общие", "Geral" },
    PremiumRequired = { "Premium Required", "Se requiere Premium", "Требуется Premium", "Premium necessário" },
    BuyPremium = { "Buy Premium", "Comprar Premium", "Купить Premium", "Comprar Premium" },
    UnlockPremiumFeature = {
        "Unlock %s with Premium.",
        "Desbloquea %s con Premium.",
        "Разблокируйте %s с Premium.",
        "Desbloqueie %s com Premium.",
    },
    PurchaseNotConfigured = {
        "Premium purchase is not configured.",
        "La compra de Premium no está configurada.",
        "Покупка Premium не настроена.",
        "A compra do Premium não está configurada.",
    },
    Premium = { "Premium", "Premium", "Premium", "Premium" },
    PremiumBody = {
        "Status provided by your validation service.",
        "Estado proporcionado por tu servicio de validación.",
        "Статус предоставлен службой проверки.",
        "Status fornecido pelo seu serviço de validação.",
    },
    PremiumStatus = { "Status", "Estado", "Статус", "Status" },
    PremiumExpiry = { "Expires (UTC)", "Vence (UTC)", "Истекает (UTC)", "Expira (UTC)" },
    PremiumPlan = { "Plan", "Plan", "План", "Plano" },
    NotVerified = { "Not verified", "Sin verificar", "Не проверен", "Não verificado" },
    Inactive = { "Inactive", "Inactivo", "Неактивен", "Inativo" },
    Expired = { "Expired", "Vencido", "Истёк", "Expirado" },
    NotProvided = { "Not provided", "No proporcionado", "Не указан", "Não informado" },
    Tooltips = { "Tooltips", "Ayudas emergentes", "Подсказки", "Dicas" },
    Resizable = {
        "Allow window resizing",
        "Permitir cambiar tamaño",
        "Изменять размер окна",
        "Permitir redimensionamento",
    },
    RememberSize = {
        "Remember window size",
        "Recordar tamaño",
        "Запоминать размер",
        "Lembrar tamanho",
    },
    RememberPosition = {
        "Remember window position",
        "Recordar posición",
        "Запоминать положение",
        "Lembrar posição",
    },
    DragToResize = {
        "Drag to resize the window.",
        "Arrastra para cambiar el tamaño.",
        "Потяните, чтобы изменить размер.",
        "Arraste para redimensionar a janela.",
    },
    Close = { "Close", "Cerrar", "Закрыть", "Fechar" },
    Create = { "Create", "Crear", "Создать", "Criar" },
    Save = { "Save", "Guardar", "Сохранить", "Salvar" },
    Load = { "Load", "Cargar", "Загрузить", "Carregar" },
    Rename = { "Rename", "Renombrar", "Переименовать", "Renomear" },
    Duplicate = { "Duplicate", "Duplicar", "Дублировать", "Duplicar" },
    Delete = { "Delete", "Eliminar", "Удалить", "Excluir" },
    Refresh = { "Refresh", "Actualizar", "Обновить", "Atualizar" },
    Import = { "Import", "Importar", "Импорт", "Importar" },
    Export = { "Export", "Exportar", "Экспорт", "Exportar" },
    Confirm = { "Confirm", "Confirmar", "Подтвердить", "Confirmar" },
    Cancel = { "Cancel", "Cancelar", "Отмена", "Cancelar" },
    Autoload = { "Autoload", "Carga automática", "Автозагрузка", "Carregamento automático" },
    Enable = { "Enable", "Activar", "Включить", "Ativar" },
    Disable = { "Disable", "Desactivar", "Отключить", "Desativar" },
    Search = {
        "Search for a setting",
        "Buscar una configuración",
        "Поиск настройки",
        "Buscar configuração",
    },
    NoMatches = {
        "No matching settings",
        "Sin coincidencias",
        "Совпадений нет",
        "Nenhuma configuração encontrada",
    },
    NoOptions = { "No options", "Sin opciones", "Нет вариантов", "Sem opções" },
    None = { "None", "Ninguno", "Нет", "Nenhum" },
    Select = { "Select", "Seleccionar", "Выбрать", "Selecionar" },
    NoProfiles = {
        "No profiles yet",
        "Aún no hay perfiles",
        "Профилей пока нет",
        "Nenhum perfil ainda",
    },
    ProfileName = { "Profile name", "Nombre del perfil", "Имя профиля", "Nome do perfil" },
    Saved = { "Profile saved", "Perfil guardado", "Профиль сохранён", "Perfil salvo" },
    Loaded = { "Profile loaded", "Perfil cargado", "Профиль загружен", "Perfil carregado" },
    Deleted = { "Profile deleted", "Perfil eliminado", "Профиль удалён", "Perfil excluído" },
    Renamed = { "Profile renamed", "Perfil renombrado", "Профиль переименован", "Perfil renomeado" },
    Duplicated = { "Profile duplicated", "Perfil duplicado", "Профиль скопирован", "Perfil duplicado" },
    Imported = { "Profile imported", "Perfil importado", "Профиль импортирован", "Perfil importado" },
    AutoloadEnabled = {
        "Autoload enabled",
        "Carga automática activada",
        "Автозагрузка включена",
        "Carregamento automático ativado",
    },
    AutoloadDisabled = {
        "Autoload disabled",
        "Carga automática desactivada",
        "Автозагрузка отключена",
        "Carregamento automático desativado",
    },
    ThemeChanged = { "Theme changed", "Tema cambiado", "Тема изменена", "Tema alterado" },
    ThemeImported = { "Theme imported", "Tema importado", "Тема импортирована", "Tema importado" },
    InvalidJSON = { "Invalid JSON", "JSON no válido", "Неверный JSON", "JSON inválido" },
    InvalidProfile = { "Invalid profile", "Perfil no válido", "Неверный профиль", "Perfil inválido" },
    FilesystemUnavailable = {
        "Filesystem unavailable",
        "Sistema de archivos no disponible",
        "Файловая система недоступна",
        "Sistema de arquivos indisponível",
    },
    SaveFailure = {
        "Could not save",
        "No se pudo guardar",
        "Не удалось сохранить",
        "Não foi possível salvar",
    },
    Failed = { "Operation failed", "Operación fallida", "Ошибка операции", "Falha na operação" },
    DeleteQuestion = {
        "Delete this profile? This cannot be undone.",
        "¿Eliminar este perfil? No se puede deshacer.",
        "Удалить профиль? Это действие необратимо.",
        "Excluir este perfil? Esta ação é irreversível.",
    },
    ProfileBody = {
        "Save named configurations for this game. Only flagged controls are included.",
        "Guarda configuraciones para este juego. Solo se incluyen controles con Flag.",
        "Сохраняйте настройки игры. Включены только элементы с Flag.",
        "Salve configurações deste jogo. Apenas controles com Flag são incluídos.",
    },
    ThemeBody = {
        "Presentation changes live; your controls and values remain in place.",
        "La apariencia cambia en vivo; los controles y valores permanecen.",
        "Оформление меняется сразу; элементы и значения сохраняются.",
        "A aparência muda ao vivo; controles e valores são preservados.",
    },
    LanguageBody = {
        "System text changes immediately. Developer labels are preserved.",
        "El texto del sistema cambia al instante. Tus etiquetas se conservan.",
        "Текст системы меняется сразу. Названия разработчика сохраняются.",
        "O texto do sistema muda imediatamente. Seus rótulos são preservados.",
    },
    GeneralBody = {
        "Window preferences and persistence capabilities.",
        "Preferencias de ventana y capacidades de guardado.",
        "Настройки окна и возможности сохранения.",
        "Preferências da janela e recursos de armazenamento.",
    },
    Accent = { "Custom accent", "Acento personalizado", "Свой акцент", "Cor de destaque" },
    ResetAccent = { "Reset accent", "Restablecer acento", "Сбросить акцент", "Restaurar destaque" },
    ThemeJSON = { "Theme JSON", "JSON del tema", "JSON темы", "JSON do tema" },
    ProfileJSON = { "Profile JSON", "JSON del perfil", "JSON профиля", "JSON do perfil" },
    Copy = { "Copy", "Copiar", "Копировать", "Copiar" },
    ClipboardUnavailable = {
        "Clipboard unavailable; select and copy the text.",
        "Portapapeles no disponible; selecciona y copia el texto.",
        "Буфер недоступен; выделите и скопируйте текст.",
        "Área de transferência indisponível; selecione e copie o texto.",
    },
    Copied = { "Copied", "Copiado", "Скопировано", "Copiado" },
    SilentLoad = {
        "Silent profile load",
        "Carga de perfil silenciosa",
        "Тихая загрузка профиля",
        "Carregar perfil silenciosamente",
    },
    SilentBody = {
        "Update controls without triggering developer callbacks.",
        "Actualiza controles sin ejecutar callbacks del desarrollador.",
        "Обновлять элементы без вызова функций разработчика.",
        "Atualize controles sem acionar callbacks do desenvolvedor.",
    },
    SearchEnabled = { "Enable search", "Activar búsqueda", "Включить поиск", "Ativar busca" },
    Notifications = {
        "Show system feedback",
        "Mostrar avisos del sistema",
        "Показывать уведомления",
        "Mostrar avisos do sistema",
    },
    PersistenceReady = {
        "Persistence ready",
        "Guardado disponible",
        "Сохранение доступно",
        "Armazenamento disponível",
    },
    ProfileExists = {
        "A profile with this name already exists",
        "Ya existe un perfil con ese nombre",
        "Профиль с таким именем уже существует",
        "Já existe um perfil com esse nome",
    },
    MissingProfile = {
        "Profile not found",
        "Perfil no encontrado",
        "Профиль не найден",
        "Perfil não encontrado",
    },
    InvalidName = {
        "Enter a valid profile name",
        "Escribe un nombre de perfil válido",
        "Введите допустимое имя профиля",
        "Digite um nome de perfil válido",
    },
    SetAutoload = {
        "Use selected profile",
        "Usar perfil seleccionado",
        "Использовать выбранный профиль",
        "Usar perfil selecionado",
    },
    Active = { "Active", "Activo", "Активный", "Ativo" },
    ResolvingGame = {
        "Resolving game name…",
        "Obteniendo nombre del juego…",
        "Определение названия игры…",
        "Obtendo nome do jogo…",
    },
    WindowDestroyed = {
        "Window is destroyed",
        "La ventana está destruida",
        "Окно уничтожено",
        "A janela foi destruída",
    },
    Ready = { "Ready", "Listo", "Готово", "Pronto" },
}
Locale.dictionaries = {}
for i, language in ipairs(Locale.order) do
    local dictionary = {}
    for key, translations in pairs(Locale.rows) do
        dictionary[key] = translations[i]
    end
    Locale.dictionaries[language] = dictionary
end
function Locale.text(w, key)
    return (Locale.dictionaries[w.language or "English"] or {})[key] or Locale.dictionaries.English[key] or key
end
function Locale.bind(w, object, property, key)
    local bindings = w.localeBindings[object] or {}
    w.localeBindings[object] = bindings
    bindings[property] = key
    object[property] = Locale.text(w, key)
end
function Window:Translate(key)
    return Locale.text(self, tostring(key))
end
function Window:BindLocalization(object, property, key)
    assert(
        typeof(object) == "Instance" and object:IsDescendantOf(self.gui),
        "Neron localization target must belong to this window"
    )
    Locale.bind(self, object, property or "Text", key)
    return self
end
function Window:SetLanguage(language, silent)
    if self.tooltip then
        self.tooltip:Cancel()
    end
    if self.destroyed or not Locale.dictionaries[language] then
        return false, "Unknown language"
    end
    self.overlay:Close(true)
    self.language = language
    Library.language = language
    for object, properties in pairs(self.localeBindings) do
        if object.Parent then
            for property, key in pairs(properties) do
                object[property] = Locale.text(self, key)
            end
        else
            self.localeBindings[object] = nil
        end
    end
    if SettingsUI.refreshLanguage then
        SettingsUI.refreshLanguage(self)
    end
    if not silent and self.persistence then
        self.persistence:QueuePresentation()
    end
    return true
end
function Window:GetLanguage()
    return self.language
end
function Library:SetLanguage(language)
    if not Locale.dictionaries[language] then
        return false, "Unknown language"
    end
    self.language = language
    for w in pairs(self.windows or {}) do
        w:SetLanguage(language)
    end
    return true
end
function Library:GetLanguage()
    return self.language or "English"
end
function Library:GetLanguages()
    return table.clone(Locale.order)
end

-- Executor filesystem adapter. No capability probe writes files; Studio remains fully usable.
function Storage.resolve(name)
    local environments = { _G }
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            table.insert(environments, env)
        end
    end
    if type(getfenv) == "function" then
        local ok, env = pcall(getfenv, 0)
        if ok and type(env) == "table" then
            table.insert(environments, env)
        end
    end
    for _, env in ipairs(environments) do
        local ok, fn = pcall(function()
            return env[name]
        end)
        if ok and type(fn) == "function" then
            return fn
        end
    end
    return nil
end
function Storage.new(adapter)
    local self = setmetatable({ api = {}, known = {} }, { __index = Storage })
    for _, key in ipairs({ "isfolder", "makefolder", "isfile", "readfile", "writefile", "delfile", "listfiles" }) do
        if adapter ~= nil then
            self.api[key] = adapter[key]
        else
            self.api[key] = Storage.resolve(key)
        end
    end
    self.available = true
    for _, key in ipairs({ "isfolder", "makefolder", "isfile", "readfile", "writefile" }) do
        if type(self.api[key]) ~= "function" then
            self.available = false
        end
    end
    return self
end
function Storage.sanitize(value, fallback)
    local text = tostring(value or ""):gsub('[%z\1-\31<>:"/\\|?*]', "_"):match("^%s*(.-)%s*$")
    text = text:gsub("%.+$", ""):gsub("^%.+", ""):gsub("%s+$", "")
    if #text > 80 then
        local ok, offset = pcall(utf8.offset, text, 0, 81)
        text = ok and offset and text:sub(1, offset - 1) or text:sub(1, 80)
    end
    if text == "" or text == "." or text == ".." then
        return fallback
    end
    local upper = text:upper()
    if
        upper == "CON"
        or upper == "PRN"
        or upper == "AUX"
        or upper == "NUL"
        or upper:match("^COM%d$")
        or upper:match("^LPT%d$")
    then
        text = "_" .. text
    end
    return text
end
function Storage.gameName(value, fallback)
    local name = Storage.sanitize(value, fallback)
    return name:lower() == "end" and "_" .. name or name
end
function Storage.decode(json)
    if type(json) ~= "string" or #json == 0 or #json > 1024 * 1024 then
        return nil, "InvalidJSON"
    end
    local ok, value = pcall(S.Http.JSONDecode, S.Http, json)
    if not ok or type(value) ~= "table" then
        return nil, "InvalidJSON"
    end
    return value
end
function Storage.encode(value)
    local ok, json = pcall(S.Http.JSONEncode, S.Http, value)
    if not ok or type(json) ~= "string" or #json > 1024 * 1024 then
        return nil, "InvalidJSON"
    end
    local decoded = Storage.decode(json)
    if not decoded then
        return nil, "InvalidJSON"
    end
    return json
end
function Storage:Call(key, ...)
    local fn = self.api[key]
    if type(fn) ~= "function" then
        return false, "FilesystemUnavailable"
    end
    local ok, result = pcall(fn, ...)
    if not ok then
        return false, tostring(result)
    end
    return true, result
end
function Storage:EnsureFolder(path)
    if not self.available then
        return false, "FilesystemUnavailable"
    end
    local prefix = ""
    for part in path:gmatch("[^/]+") do
        prefix = prefix == "" and part or prefix .. "/" .. part
        local ok, exists = self:Call("isfolder", prefix)
        if not ok then
            return false, exists
        end
        if not exists then
            local made, err = self:Call("makefolder", prefix)
            if not made then
                return false, err
            end
            local checked, present = self:Call("isfolder", prefix)
            if not checked or not present then
                return false, "SaveFailure"
            end
        end
    end
    return true
end
function Storage:Exists(path)
    local ok, value = self:Call("isfile", path)
    return ok and value == true
end
function Storage:Read(path)
    if not self:Exists(path) then
        return nil, "MissingProfile"
    end
    local ok, contents = self:Call("readfile", path)
    if not ok or type(contents) ~= "string" then
        return nil, "InvalidJSON"
    end
    return contents
end
function Storage:Write(path, value)
    if not self.available then
        return false, "FilesystemUnavailable"
    end
    local json, err = Storage.encode(value)
    if not json then
        return false, err
    end
    local folder = path:match("^(.*)/[^/]+$")
    local ready, failure = self:EnsureFolder(folder)
    if not ready then
        return false, failure
    end
    local checked, exists = self:Call("isfile", path)
    if not checked then
        return false, exists
    end
    local backup
    if exists then
        local previous, failure = self:Read(path)
        if not previous then
            return false, failure or "SaveFailure"
        end
        backup = previous
    end
    local wrote, reason = self:Call("writefile", path, json)
    local verify = wrote and self:Read(path) or nil
    if not wrote or verify ~= json or not Storage.decode(verify) then
        if backup then
            self:Call("writefile", path, backup)
        end
        return false, reason or "SaveFailure"
    end
    self.known[path] = true
    return true
end
function Storage:Delete(path)
    local ok, err = self:Call("delfile", path)
    if not ok then
        return false, err
    end
    local checked, exists = self:Call("isfile", path)
    if not checked or exists then
        return false, checked and "SaveFailure" or exists
    end
    self.known[path] = nil
    return true
end
function Storage:List(folder)
    if not self.available then
        return nil, "FilesystemUnavailable"
    end
    local out, seen = {}, {}
    local ok, files = self:Call("listfiles", folder)
    if ok and type(files) == "table" then
        for _, path in ipairs(files) do
            if type(path) == "string" then
                local name = path:gsub("\\", "/"):match("([^/]+)%.json$")
                if
                    name
                    and Storage.sanitize(name) == name
                    and not seen[name]
                    and self:Exists(folder .. "/" .. name .. ".json")
                then
                    out[#out + 1], seen[name] = name, true
                end
            end
        end
    end
    -- Executors lacking listfiles can still use and refresh known profiles and Default.
    for path in pairs(self.known) do
        if path:sub(1, #folder + 1) == folder .. "/" and self:Exists(path) then
            local name = path:match("([^/]+)%.json$")
            if name and not seen[name] then
                out[#out + 1], seen[name] = name, true
            end
        end
    end
    if self:Exists(folder .. "/Default.json") and not seen.Default then
        table.insert(out, "Default")
    end
    table.sort(out, function(a, b)
        return a:lower() == b:lower() and a < b or a:lower() < b:lower()
    end)
    return out
end
function Maid:Spawn(fn)
    if self.dead then
        return
    end
    local thread, cancel
    cancel = function()
        if thread and coroutine.running() ~= thread and coroutine.status(thread) == "suspended" then
            task.cancel(thread)
        end
    end
    thread = task.defer(function()
        if not self.dead then
            fn()
        end
        self:Remove(cancel)
    end)
    self:Add(cancel)
    return cancel
end

Profiles.stateful = {
    Toggle = true,
    Slider = true,
    RangeSlider = true,
    Dropdown = true,
    MultiDropdown = true,
    ColorPicker = true,
    Textbox = true,
}
function Profiles.init(w, config)
    local self = setmetatable({
        window = w,
        store = Storage.new(config.Filesystem),
        placeId = game.PlaceId,
        gameName = Storage.gameName(config.GameName, tostring(game.PlaceId)),
        applied = setmetatable({}, { __mode = "k" }),
        silentLoad = true,
        autoloadAllowed = config.Autoload ~= false,
        ready = config.GameName ~= nil,
    }, { __index = Profiles })
    w.persistence = self
    self:Paths()
    local ready, err = self.store:EnsureFolder("Neron/End")
    self.status = ready and "PersistenceReady" or "FilesystemUnavailable"
    self.error = err
    local contents = self.store:Read("Neron/End/Theme.json")
    local prefs = contents and Storage.decode(contents)
    if prefs and (prefs.schemaVersion == 1 or prefs.schemaVersion == 0) then
        Geometry.restore(w, prefs, config)
        if config.Theme == nil and Library.themeName == nil and Presentation.themes[prefs.theme] then
            w.themeName = prefs.theme
        end
        if config.Language == nil and Library.language == nil and Locale.dictionaries[prefs.language] then
            w.language = prefs.language
        end
        local useStoredTheme = config.Theme == nil and Library.themeName == nil
        if useStoredTheme then
            w.customAccent = config.Accent or Presentation.decodeColor(prefs.accent)
            w.themeOverrides = {}
        end
        if useStoredTheme and type(prefs.overrides) == "table" then
            for token, color in pairs(prefs.overrides) do
                local parsed = Theme[token] and Presentation.decodeColor(color)
                if parsed then
                    w.themeOverrides[token] = parsed
                end
            end
        end
        Presentation.apply(w)
        w:SetLanguage(w.language, true)
    end
    if self.ready then
        local folderReady, failure = self.store:EnsureFolder(self.folder)
        self.status, self.error = folderReady and "PersistenceReady" or "SaveFailure", failure
        self:QueueAutoload()
    else
        self.metadataCancel = w.bag:Spawn(function()
            local ok, info = pcall(S.Marketplace.GetProductInfo, S.Marketplace, game.PlaceId)
            if w.destroyed or self.ready then
                return
            end
            if ok and type(info) == "table" and type(info.Name) == "string" then
                self.gameName = Storage.gameName(info.Name, tostring(game.PlaceId))
            end
            self.ready = true
            self:Paths()
            local folderReady, failure = self.store:EnsureFolder(self.folder)
            self.status, self.error = folderReady and "PersistenceReady" or "SaveFailure", failure
            self:QueueAutoload()
            if w.settingsOpen then
                SettingsUI.refreshProfiles(w)
            end
        end)
        w.bag:After(5, function()
            if self.ready or w.destroyed then
                return
            end
            self.ready = true
            if self.metadataCancel then
                w.bag:Remove(self.metadataCancel, true)
                self.metadataCancel = nil
            end
            local folderReady, failure = self.store:EnsureFolder(self.folder)
            self.status, self.error = folderReady and "PersistenceReady" or "SaveFailure", failure
            self:QueueAutoload()
            if w.settingsOpen then
                SettingsUI.refreshProfiles(w)
            end
        end)
    end
end
function Profiles:Paths()
    self.folder = "Neron/" .. self.gameName .. "/Settings"
end
function Profiles:Writable()
    if self.window.destroyed then
        return false, "WindowDestroyed"
    end
    if not self.store.available then
        return false, "FilesystemUnavailable"
    end
    if not self.ready then
        return false, "ResolvingGame"
    end
    if self.busy then
        return false, "Failed"
    end
    return true
end
function Profiles:Status()
    if not self.store.available then
        return "FilesystemUnavailable"
    end
    if not self.ready then
        return "ResolvingGame"
    end
    return self.status
end
function Profiles:Name(name)
    if type(name) ~= "string" then
        return nil, "InvalidName"
    end
    local clean = Storage.sanitize(name)
    if not clean then
        return nil, "InvalidName"
    end
    return clean
end
function Profiles:Path(name)
    return self.folder .. "/" .. name .. ".json"
end
function Profiles:Snapshot()
    local entries = {}
    for flag, control in pairs(self.window.flagOwners) do
        if
            type(flag) == "string"
            and not control.destroyed
            and Profiles.stateful[control.kind]
            and control.config.Persistent ~= false
        then
            local value = control:Get()
            local entry = { kind = control.kind, value = value }
            if control.kind == "ColorPicker" then
                entry.value = Presentation.colorData(value)
                if control.hasAlpha then
                    entry.alpha = control.alpha
                end
            end
            entries[flag] = entry
        end
    end
    local now = os.time()
    return {
        schemaVersion = 1,
        libraryVersion = Library.Version,
        game = self.gameName,
        placeId = self.placeId,
        createdAt = now,
        updatedAt = now,
        values = entries,
    }
end
function Profiles:Migrate(data)
    if type(data) ~= "table" or type(data.values) ~= "table" then
        return nil, "InvalidProfile"
    end
    local version = data.schemaVersion
    if version == nil or version == 0 then
        local values = {}
        for flag, value in pairs(data.values) do
            local control = self.window.flagOwners[flag]
            if control and Profiles.stateful[control.kind] then
                values[flag] = { kind = control.kind, value = value }
            end
        end
        data.values, data.schemaVersion = values, 1
    elseif version ~= 1 then
        return nil, "InvalidProfile"
    end
    local count = 0
    for flag, entry in pairs(data.values) do
        count += 1
        if count > 2048 or type(flag) ~= "string" or type(entry) ~= "table" then
            return nil, "InvalidProfile"
        end
    end
    return data
end
function Profiles:Read(name)
    local clean, err = self:Name(name)
    if not clean then
        return nil, err
    end
    local json, reason = self.store:Read(self:Path(clean))
    if not json then
        return nil, reason
    end
    local data, failure = Storage.decode(json)
    if not data then
        return nil, failure
    end
    return self:Migrate(data)
end
function Profiles:ValidValue(control, entry)
    if entry.kind ~= control.kind then
        return nil
    end
    local value, kind = entry.value, control.kind
    if kind == "Toggle" then
        if type(value) ~= "boolean" then
            return nil
        end
    elseif kind == "Slider" then
        if type(value) ~= "number" or not U.finite(value, nil) then
            return nil
        end
        value = Components.quantize(control.number, value)
    elseif kind == "RangeSlider" then
        if type(value) ~= "table" or #value ~= 2 then
            return nil
        end
        for i = 1, 2 do
            if type(value[i]) ~= "number" or not U.finite(value[i], nil) then
                return nil
            end
        end
        local a, b = Components.quantize(control.number, value[1]), Components.quantize(control.number, value[2])
        value = { math.min(a, b), math.max(a, b) }
    elseif kind == "Dropdown" then
        if type(value) ~= "string" or not table.find(control.values, value) then
            return nil
        end
    elseif kind == "MultiDropdown" then
        if type(value) ~= "table" then
            return nil
        end
        local filtered = {}
        for _, v in ipairs(value) do
            if type(v) == "string" and table.find(control.values, v) then
                table.insert(filtered, v)
            end
        end
        value = filtered
    elseif kind == "ColorPicker" then
        value = Presentation.decodeColor(value)
        if not value then
            return nil
        end
        if entry.alpha ~= nil and (type(entry.alpha) ~= "number" or not U.finite(entry.alpha, nil)) then
            return nil
        end
    elseif kind == "Textbox" then
        if type(value) ~= "string" then
            return nil
        end
        value = control:normalize(value)
    else
        return nil
    end
    return value, true
end
function Profiles:Apply(data, silent, pendingOnly)
    local applied, ignored = 0, 0
    local owners = table.clone(self.window.flagOwners)
    for flag, entry in pairs(data.values) do
        local control = owners[flag]
        if
            control
            and not control.destroyed
            and Profiles.stateful[control.kind]
            and control.config.Persistent ~= false
            and (not pendingOnly or not self.applied[control])
        then
            local value, valid = self:ValidValue(control, entry)
            if valid then
                self.applied[control] = true
                if control.kind == "ColorPicker" then
                    local alpha = entry.alpha ~= nil and math.clamp(entry.alpha, 0, 1) or control.alpha
                    local changed = control.alpha ~= alpha or not U.equal(control.value, value)
                    control.alpha = alpha
                    control:Set(value, true)
                    if changed and not silent then
                        control:_emit()
                    end
                else
                    control:Set(value, silent == true)
                end
                applied += 1
            else
                ignored += 1
            end
        else
            ignored += 1
        end
    end
    return applied, ignored
end
function Profiles:Changed()
    local w = self.window
    if self.refreshCancel or w.destroyed or not w.settingsOpen or w.settingsCategory ~= "Profiles" then
        return
    end
    self.refreshCancel = w.bag:After(0, function()
        self.refreshCancel = nil
        if w.settingsOpen and w.settingsCategory == "Profiles" then
            SettingsUI.refreshProfiles(w)
        end
    end, true)
end
function Profiles:Save(name, create)
    local ready, reason = self:Writable()
    if not ready then
        return false, reason
    end
    local clean, err = self:Name(name)
    if not clean then
        return false, err
    end
    local checked, exists = self.store:Call("isfile", self:Path(clean))
    if not checked then
        return false, exists
    end
    if create and exists then
        return false, "ProfileExists"
    end
    local snapshot = self:Snapshot()
    local previous = self:Read(clean)
    if previous and U.finite(previous.createdAt, nil) then
        snapshot.createdAt = previous.createdAt
    end
    local ok, reason = self.store:Write(self:Path(clean), snapshot)
    if ok then
        self.status, self.error = "PersistenceReady", nil
        self.activeProfile = clean
        self:Changed()
    end
    return ok, reason
end
function Profiles:Load(name, silent)
    local ready, reason = self:Writable()
    if not ready then
        return false, reason
    end
    local clean, err = self:Name(name)
    if not clean then
        return false, err
    end
    local data, reason = self:Read(clean)
    if not data then
        return false, reason
    end
    self.busy = true
    -- Loading replaces pending startup values, so subsequent late controls never resurrect an older profile.
    self.autoloadValues = nil
    local applied, ignored = self:Apply(data, silent == true)
    self.activeProfile, self.busy = clean, false
    self:Changed()
    return true, { applied = applied, ignored = ignored }
end
function Profiles:AutoloadData()
    local json = self.store:Read("Neron/End/Autoload.json")
    local data = json and Storage.decode(json)
    if data and data.schemaVersion == 0 and data.placeId ~= nil then
        data = {
            schemaVersion = 1,
            games = {
                [tostring(data.placeId)] = {
                    game = data.game,
                    placeId = data.placeId,
                    profile = data.profile,
                    enabled = data.enabled == true,
                },
            },
        }
    end
    if not data or data.schemaVersion ~= 1 or type(data.games) ~= "table" then
        data = { schemaVersion = 1, games = {} }
    end
    return data
end
function Profiles:SetAutoload(name, enabled)
    local ready, err = self:Writable()
    if not ready then
        return false, err
    end
    local data = self:AutoloadData()
    local clean
    if enabled ~= false then
        clean = self:Name(name)
        if not clean then
            return false, "InvalidName"
        end
        local valid, err = self:Read(clean)
        if not valid then
            return false, err
        end
    end
    local record = { game = self.gameName, placeId = self.placeId, profile = clean, enabled = enabled ~= false }
    data.games[tostring(self.placeId)] = record
    local ok, err = self.store:Write("Neron/End/Autoload.json", data)
    if ok then
        self.autoload = record
        self:Changed()
    end
    return ok, err
end
function Profiles:QueueAutoload()
    if self.queued or self.busy or self.window.destroyed or not self.ready or not self.autoloadAllowed then
        return
    end
    self.queued = self.window.bag:After(0, function()
        self.queued = nil
        if not self.autoloadChecked then
            self.autoloadChecked = true
            local record = self:AutoloadData().games[tostring(self.placeId)]
            if
                type(record) == "table"
                and record.enabled == true
                and record.game == self.gameName
                and record.placeId == self.placeId
            then
                self.autoload = record
                local data = self:Read(record.profile)
                if data then
                    self.autoloadValues, self.activeProfile = data, record.profile
                else
                    self.autoloadError = "MissingProfile"
                end
            end
        end
        if self.autoloadValues then
            self.busy = true
            self:Apply(self.autoloadValues, true, true)
            self.busy = false
        end
    end, true)
end
function Profiles:QueuePresentation()
    if self.window.destroyed then
        return
    end
    Library.preferenceRevision = (Library.preferenceRevision or 0) + 1
    self.preferenceRevision = Library.preferenceRevision
    if self.presentationCancel then
        self.window.bag:Remove(self.presentationCancel, true)
    end
    self.presentationCancel = self.window.bag:After(0.30, function()
        self.presentationCancel = nil
        local ok, err = self:SavePresentation()
        if not ok and self.window.settingsOpen then
            self.window:Notify("SaveFailure", Locale.text(self.window, err or "Failed"), "Warning")
        end
    end)
end
function Profiles:SavePresentation()
    if self.preferenceRevision and self.preferenceRevision ~= Library.preferenceRevision then
        return true
    end
    local w, overrides = self.window, {}
    for token, color in pairs(w.themeOverrides) do
        overrides[token] = Presentation.colorData(color)
    end
    local ok, err = self.store:Write("Neron/End/Theme.json", {
        schemaVersion = 1,
        theme = w.themeName,
        language = w.language,
        accent = w.customAccent and Presentation.colorData(w.customAccent),
        overrides = overrides,
        windows = Library.geometryPrefs or {},
    })
    self.presentationError = ok and nil or err
    return ok, err
end
function Window:SaveProfile(name)
    return self.persistence:Save(name, false)
end
function Window:CreateProfile(name)
    return self.persistence:Save(name, true)
end
function Window:LoadProfile(name, silent)
    return self.persistence:Load(name, silent)
end
function Window:RefreshProfiles()
    return self.persistence.store:List(self.persistence.folder)
end
function Window:GetActiveProfile()
    return self.persistence.activeProfile
end
function Window:GetPersistenceStatus()
    return {
        available = self.persistence.store.available,
        ready = self.persistence.ready,
        game = self.persistence.gameName,
        folder = self.persistence.folder,
        canDelete = type(self.persistence.store.api.delfile) == "function",
        canList = type(self.persistence.store.api.listfiles) == "function",
    }
end
function Window:ExportProfile(name)
    local data, err
    if name then
        data, err = self.persistence:Read(name)
    else
        data = self.persistence:Snapshot()
    end
    if not data then
        return nil, err
    end
    return Storage.encode(data)
end
function Window:ImportProfile(name, json, overwrite)
    local ready, reason = self.persistence:Writable()
    if not ready then
        return false, reason
    end
    local clean, err = self.persistence:Name(name)
    if not clean then
        return false, err
    end
    local data, failure = Storage.decode(json)
    if not data then
        return false, failure
    end
    data, failure = self.persistence:Migrate(data)
    if not data then
        return false, failure
    end
    local path = self.persistence:Path(clean)
    local checked, exists = self.persistence.store:Call("isfile", path)
    if not checked then
        return false, exists
    end
    if not overwrite and exists then
        return false, "ProfileExists"
    end
    data.game, data.placeId, data.updatedAt = self.persistence.gameName, self.persistence.placeId, os.time()
    local ok, reason = self.persistence.store:Write(path, data)
    if ok then
        self.persistence.status, self.persistence.error = "PersistenceReady", nil
        self.persistence:Changed()
    end
    return ok, reason
end
function Window:DuplicateProfile(name, newName)
    local json, err = self:ExportProfile(name)
    if not json then
        return false, err
    end
    return self:ImportProfile(newName, json, false)
end
function Window:RenameProfile(name, newName)
    local manager = self.persistence
    local ready, reason = manager:Writable()
    if not ready then
        return false, reason
    end
    if type(manager.store.api.delfile) ~= "function" then
        return false, "FilesystemUnavailable"
    end
    local old, err = manager:Name(name)
    local new = manager:Name(newName)
    if not old or not new then
        return false, err or "InvalidName"
    end
    if old == new then
        return true
    end
    local ok, reason = self:DuplicateProfile(old, new)
    if not ok then
        return false, reason
    end
    local record = manager:AutoloadData().games[tostring(manager.placeId)]
    local wasAutoload = type(record) == "table"
        and record.enabled
        and record.game == manager.gameName
        and record.profile == old
    if wasAutoload then
        local moved, failure = self:SetAutoload(new)
        if not moved then
            manager.store:Delete(manager:Path(new))
            return false, failure
        end
    end
    local deleted, failure = manager.store:Delete(manager:Path(old))
    if not deleted then
        -- Only discard the destination after positively reading the source. A failed
        -- post-delete verification must never remove the last recoverable copy.
        if manager:Read(old) then
            if wasAutoload then
                self:SetAutoload(old)
            end
            manager.store:Delete(manager:Path(new))
        else
            if manager.activeProfile == old then
                manager.activeProfile = new
            end
            manager:Changed()
        end
        return false, failure
    end
    if manager.activeProfile == old then
        manager.activeProfile = new
    end
    manager:Changed()
    return true
end
function Window:DeleteProfile(name)
    local manager = self.persistence
    local ready, reason = manager:Writable()
    if not ready then
        return false, reason
    end
    if type(manager.store.api.delfile) ~= "function" then
        return false, "FilesystemUnavailable"
    end
    local clean, err = manager:Name(name)
    if not clean then
        return false, err
    end
    if not manager.store:Exists(manager:Path(clean)) then
        return false, "MissingProfile"
    end
    local record = manager:AutoloadData().games[tostring(manager.placeId)]
    local targeted = type(record) == "table"
        and record.enabled
        and record.game == manager.gameName
        and record.profile == clean
    if targeted then
        local ok, reason = self:DisableAutoload()
        if not ok then
            return false, reason
        end
    end
    local ok, reason = manager.store:Delete(manager:Path(clean))
    if not ok and targeted then
        self:SetAutoload(clean)
    end
    if ok and manager.activeProfile == clean then
        manager.activeProfile = nil
    end
    if ok then
        manager.autoloadValues = nil
        manager:Changed()
    end
    return ok, reason
end
function Window:SetAutoload(name)
    return self.persistence:SetAutoload(name, true)
end
function Window:DisableAutoload()
    return self.persistence:SetAutoload(nil, false)
end
function Window:GetAutoload()
    local record = self.persistence:AutoloadData().games[tostring(self.persistence.placeId)]
    return type(record) == "table"
            and record.game == self.persistence.gameName
            and record.placeId == self.persistence.placeId
            and table.clone(record)
        or { enabled = false }
end
function Window:ApplyAutoload()
    local manager = self.persistence
    manager.autoloadChecked, manager.autoloadValues = false, nil
    table.clear(manager.applied)
    manager:QueueAutoload()
    return self
end

-- Dedicated system interface: never inserted in Window.tabs, search index or consumer flags.
function SettingsUI.text(w, parent, key, props, role)
    local label = U.label(parent, Locale.text(w, key), T.Type.Value, w.theme[role or "SystemText"], props)
    U.bind(w, label, "TextColor3", role or "SystemText")
    Locale.bind(w, label, "Text", key)
    return label
end
function SettingsUI.interactive(w, object)
    if w.destroyed or not w.visible or not w.settingsOpen then
        return false
    end
    if w.confirmation then
        return object:IsDescendantOf(w.confirmation.panel)
    end
    if w.transfer then
        return object:IsDescendantOf(w.transfer.panel)
    end
    if not w.settingsPanel or not object:IsDescendantOf(w.settingsPanel) then
        return false
    end
    for key, page in pairs(w.settingsPages) do
        if object:IsDescendantOf(page.host) then
            return w.settingsCategory == key
        end
    end
    return true
end
function SettingsUI.button(w, parent, key, props, bag, callback, primary)
    local button = U.button(parent, props)
    U.corner(button, T.Radius.Button)
    local label = SettingsUI.text(
        w,
        button,
        key,
        { TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium },
        primary and "ButtonText" or "SystemText"
    )
    local owner = { state = { Hovered = false, Pressed = false } }
    function owner:_render()
        local state = self.state
        w.motion:To(button, T.Motion.Micro, {
            BackgroundTransparency = 0,
            BackgroundColor3 = state.Pressed and (primary and w.theme.AccentPressed or w.theme.RowPressed)
                or (
                    primary and w.theme.Accent
                    or (state.Hovered and w.theme.SurfaceSelected or w.theme.SurfaceSecondary)
                ),
        })
        label.TextColor3 = primary and w.theme.ButtonText or w.theme.SystemText
    end
    w.systemRenders = w.systemRenders or {}
    w.systemRenders[button] = owner
    bag:Add(function()
        w.systemRenders[button] = nil
        w.pressed[owner] = nil
    end)
    U.connect(bag, button.MouseEnter, function()
        owner.state.Hovered = true
        owner:_render()
    end)
    U.connect(bag, button.MouseLeave, function()
        owner.state.Hovered, owner.state.Pressed = false, false
        owner:_render()
    end)
    U.connect(bag, button.InputBegan, function(event)
        if U.primary(event) and SettingsUI.interactive(w, button) then
            owner.state.Pressed = true
            w.pressed[owner] = event
            owner:_render()
        end
    end)
    U.connect(bag, button.InputEnded, function(event)
        if U.primary(event) then
            owner.state.Pressed = false
            owner:_render()
        end
    end)
    U.connect(bag, button.Activated, function()
        if not SettingsUI.interactive(w, button) then
            return
        end
        owner.state.Pressed = false
        w.pressed[owner] = nil
        owner:_render()
        local ok, err = xpcall(callback, debug.traceback)
        if not ok then
            U.warn(key, err)
            w:Notify("Failed", nil, "Danger")
        end
    end)
    U.bind(w, button, "BackgroundColor3", primary and "Accent" or "SurfaceSecondary")
    owner:_render()
    return button
end
function Window:Notify(key, detail, status)
    if self.destroyed or self.systemNotifications == false then
        return self
    end
    if self.toastBag then
        self.toastBag:Destroy()
    end
    key = tostring(key or "")
    status = self.theme[status or "Accent"] and (status or "Accent") or "Accent"
    local bag = Maid.new(self.motion)
    self.toastBag = bag
    local group = U.new("CanvasGroup", {
        Name = "Feedback",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -16),
        Size = UDim2.new(0, math.min(320, self.root.Size.X.Offset - 36), 0, 54),
        BackgroundTransparency = 0,
        BackgroundColor3 = self.theme.PopoverBackground,
        GroupTransparency = 1,
        ZIndex = T.Z.Toast,
    }, self.root)
    bag:Add(group)
    self.toastGroup = group
    U.corner(group, T.Radius.Popover)
    U.bind(self, group, "BackgroundColor3", "PopoverBackground")
    local line = U.frame(
        group,
        { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(0, 2, 1, -16), ZIndex = group.ZIndex + 1 },
        self,
        status or "Accent"
    )
    U.corner(line, 1)
    local label = SettingsUI.text(
        self,
        group,
        key,
        { Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 19) },
        "TextPrimary"
    )
    if detail then
        U.label(
            group,
            tostring(detail),
            T.Type.PageSubtitle,
            self.theme.SystemText,
            { Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -28, 0, 16) }
        )
    else
        label.Size = UDim2.new(1, -28, 1, -16)
    end
    self.motion:To(group, T.Motion.Normal, { GroupTransparency = 0 })
    bag:After(2.6, function()
        self.motion:To(group, T.Motion.Fast, { GroupTransparency = 1 })
        bag:After(T.Motion.Fast, function()
            bag:Destroy()
            if self.toastBag == bag then
                self.toastBag, self.toastGroup = nil, nil
            end
        end)
    end)
    return self
end
function SettingsUI.result(w, ok, err, success)
    if ok then
        w:Notify(success, nil, "Success")
    else
        local key = Locale.dictionaries.English[err] and err or "Failed"
        w:Notify(key, key == "Failed" and tostring(err or "") or nil, "Danger")
    end
    return ok
end
function SettingsUI.dismissConfirmation(w)
    if w.confirmation then
        w.confirmation.bag:Destroy()
        w.confirmation = nil
    end
end
function SettingsUI.confirm(w, title, message, detail, callback)
    SettingsUI.dismissConfirmation(w)
    w.overlay:Close(true)
    w.input:Cancel()
    U.focusRelease(w)
    local bag = Maid.new(w.motion)
    local shade = U.button(w.root, {
        Name = "ConfirmationShade",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.38,
        BackgroundColor3 = w.theme.Overlay,
        ZIndex = T.Z.Confirmation,
    })
    bag:Add(shade)
    local panel = U.new("CanvasGroup", {
        Name = "Confirmation",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(math.min(360, w.root.Size.X.Offset - 32), 178),
        BackgroundTransparency = 0,
        BackgroundColor3 = w.theme.PopoverBackground,
        GroupTransparency = 1,
        ZIndex = shade.ZIndex + 1,
    }, shade)
    U.corner(panel, T.Radius.Popover)
    U.bind(w, panel, "BackgroundColor3", "PopoverBackground")
    local stroke = U.stroke(panel, w.theme.SurfaceEdge)
    stroke.Transparency = 0.3
    SettingsUI.text(
        w,
        panel,
        title,
        { Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 24), Font = Enum.Font.GothamBold },
        "TextPrimary"
    )
    SettingsUI.text(w, panel, message, {
        Position = UDim2.fromOffset(16, 44),
        Size = UDim2.new(1, -32, 0, 44),
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
    })
    U.label(
        panel,
        detail or "",
        T.Type.Description,
        w.theme.TextSecondary,
        { Position = UDim2.fromOffset(16, 91), Size = UDim2.new(1, -32, 0, 18) }
    )
    SettingsUI.button(
        w,
        panel,
        "Cancel",
        { Position = UDim2.new(0, 16, 1, -48), Size = UDim2.new(0.5, -24, 0, 32), ZIndex = panel.ZIndex + 2 },
        bag,
        function()
            SettingsUI.dismissConfirmation(w)
        end
    )
    SettingsUI.button(
        w,
        panel,
        "Confirm",
        { Position = UDim2.new(0.5, 8, 1, -48), Size = UDim2.new(0.5, -24, 0, 32), ZIndex = panel.ZIndex + 2 },
        bag,
        function()
            SettingsUI.dismissConfirmation(w)
            callback()
        end,
        true
    )
    U.connect(bag, shade.Activated, function()
        SettingsUI.dismissConfirmation(w)
    end)
    w.confirmation = { bag = bag, panel = panel }
    w.motion:To(panel, T.Motion.Normal, { GroupTransparency = 0 })
end
function SettingsUI.dismissTransfer(w)
    if w.transfer then
        if w.transfer.box:IsFocused() then
            w.transfer.box:ReleaseFocus()
        end
        w.transfer.bag:Destroy()
        w.transfer = nil
    end
end
function SettingsUI.transfer(w, kind, json, import)
    SettingsUI.dismissTransfer(w)
    w.overlay:Close(true)
    w.input:Cancel()
    U.focusRelease(w)
    local bag = Maid.new(w.motion)
    local shade = U.button(w.root, {
        Name = "TransferShade",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.35,
        BackgroundColor3 = w.theme.Overlay,
        ZIndex = T.Z.Confirmation,
    })
    bag:Add(shade)
    local panel = U.new("CanvasGroup", {
        Name = "JSONTransfer",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -48, 1, -80),
        BackgroundTransparency = 0,
        BackgroundColor3 = w.theme.PopoverBackground,
        GroupTransparency = 1,
        ZIndex = shade.ZIndex + 1,
    }, shade)
    U.corner(panel, T.Radius.Popover)
    U.bind(w, panel, "BackgroundColor3", "PopoverBackground")
    SettingsUI.text(
        w,
        panel,
        kind == "theme" and "ThemeJSON" or "ProfileJSON",
        { Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -64, 0, 24), Font = Enum.Font.GothamBold },
        "TextPrimary"
    )
    local host = U.frame(
        panel,
        { Position = UDim2.fromOffset(16, 48), Size = UDim2.new(1, -32, 1, -112), ZIndex = panel.ZIndex + 1 },
        w,
        "InputBackground"
    )
    U.corner(host, T.Radius.Input)
    local scroll = Scroll.make(w, host, bag, 0, true)
    scroll.frame.Size = UDim2.new(1, -12, 1, 0)
    U.new("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
    }, scroll.frame)
    local box = U.new("TextBox", {
        Size = UDim2.new(1, -16, 0, 200),
        Text = json or "",
        ClearTextOnFocus = false,
        MultiLine = true,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Font = Enum.Font.Code,
        TextSize = T.Type.Description,
        TextColor3 = w.theme.SystemText,
        ZIndex = scroll.frame.ZIndex + 1,
    }, scroll.frame)
    local function resize()
        if #box.Text > 1024 * 1024 then
            box.Text = box.Text:sub(1, 1024 * 1024)
        end
        local width = math.max(80, box.AbsoluteSize.X / w.scale)
        local size = S.Text:GetTextSize(box.Text, T.Type.Description, Enum.Font.Code, Vector2.new(width, 200000))
        local height = math.max(200, size.Y + 20)
        if box.Size.Y.Offset ~= height then
            box.Size = UDim2.new(1, -16, 0, height)
        end
        scroll:Update()
    end
    U.connect(bag, box:GetPropertyChangedSignal("Text"), resize)
    U.connect(bag, box:GetPropertyChangedSignal("AbsoluteSize"), resize)
    SettingsUI.button(
        w,
        panel,
        "Close",
        { Position = UDim2.new(0, 16, 1, -48), Size = UDim2.new(0.5, -24, 0, 32), ZIndex = panel.ZIndex + 2 },
        bag,
        function()
            SettingsUI.dismissTransfer(w)
        end
    )
    SettingsUI.button(
        w,
        panel,
        import and "Import" or "Copy",
        { Position = UDim2.new(0.5, 8, 1, -48), Size = UDim2.new(0.5, -24, 0, 32), ZIndex = panel.ZIndex + 2 },
        bag,
        function()
            if import then
                local ok, err
                if kind == "theme" then
                    ok, err = w:ImportTheme(box.Text)
                else
                    ok, err = w:ImportProfile(w.profileName:Get(), box.Text)
                end
                if SettingsUI.result(w, ok, err, kind == "theme" and "ThemeImported" or "Imported") then
                    SettingsUI.dismissTransfer(w)
                    SettingsUI.refreshProfiles(w)
                end
            else
                local copy = Storage.resolve("setclipboard") or Storage.resolve("toclipboard")
                local ok = copy and pcall(copy, box.Text)
                w:Notify(ok and "Copied" or "ClipboardUnavailable")
                if not ok then
                    box:CaptureFocus()
                    box.SelectionStart = 1
                    box.CursorPosition = #box.Text + 1
                end
            end
        end,
        true
    )
    U.connect(bag, shade.Activated, function()
        SettingsUI.dismissTransfer(w)
    end)
    w.transfer = { bag = bag, panel = panel, box = box }
    resize()
    w.motion:To(panel, T.Motion.Normal, { GroupTransparency = 0 })
end
function SettingsUI.page(w, key)
    local bag = Maid.new(w.motion)
    local host = U.new("CanvasGroup", {
        Name = key,
        Size = UDim2.fromScale(1, 1),
        GroupTransparency = 0,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = w.settingsBody.ZIndex + 1,
    }, w.settingsBody)
    bag:Add(host)
    local page = setmetatable({
        name = key,
        window = w,
        controls = {},
        system = true,
        visible = true,
        disabled = false,
        tab = { visible = true, disabled = false },
        bag = bag,
        host = host,
    }, SubTab)
    page.tab.activeSub = page
    page.scroll = Scroll.make(w, host, bag, 8, true)
    page.scroll.frame.Size = UDim2.new(1, -16, 1, 0)
    w.settingsPages[key] = page
    return page
end
function SettingsUI.control(w, page, method, key, config, description)
    config = table.clone(config or {})
    config.Name = Locale.text(w, key)
    if description then
        config.Description = Locale.text(w, description)
    end
    local control = page[method](page, config)
    w.systemControls[control] = { name = key, description = description }
    return control
end
function SettingsUI.heading(w, page, key, body)
    local control = SettingsUI.control(w, page, "AddParagraph", key, {}, body)
    U.bind(w, control.label, "TextColor3", "TextPrimary")
    control.systemHeading = true
    control:_render()
    control.label.Font = Enum.Font.GothamBold
    control.label.TextSize = T.Type.PageTitle
    return control
end
function SettingsUI.context(w, row, name)
    local owner = { state = {}, page = w.settingsPages.Profiles, profileContext = true }
    function owner:_usable()
        return not w.destroyed
            and w.settingsOpen
            and w.settingsCategory == "Profiles"
            and not w.confirmation
            and not w.transfer
    end
    function owner:_render()
        local icon = row:FindFirstChildOfClass("Frame")
        if row.Parent and icon then
            w.motion:To(icon, T.Motion.Fast, { Rotation = self.state.Open and 180 or 0 })
        end
    end
    local keys = { "Load", "Save", "Rename", "Duplicate", "Delete", "Autoload" }
    local actions = {
        Load = function()
            local ok, err = w:LoadProfile(name, w.persistence.silentLoad)
            SettingsUI.result(w, ok, err, "Loaded")
        end,
        Save = function()
            local ok, err = w:SaveProfile(name)
            SettingsUI.result(w, ok, err, "Saved")
        end,
        Rename = function()
            local ok, err = w:RenameProfile(name, w.profileName:Get())
            SettingsUI.result(w, ok, err, "Renamed")
        end,
        Duplicate = function()
            local ok, err = w:DuplicateProfile(name, w.profileName:Get())
            SettingsUI.result(w, ok, err, "Duplicated")
        end,
        Delete = function()
            SettingsUI.confirm(w, "Delete", "DeleteQuestion", name, function()
                local ok, err = w:DeleteProfile(name)
                SettingsUI.result(w, ok, err, "Deleted")
                SettingsUI.refreshProfiles(w)
            end)
        end,
        Autoload = function()
            local ok, err = w:SetAutoload(name)
            SettingsUI.result(w, ok, err, "AutoloadEnabled")
        end,
    }
    w.overlay:Open(owner, row, 176, #keys * T.Geometry.Option + 8, function(group, bag)
        for i, key in ipairs(keys) do
            local button = U.button(group, {
                Position = UDim2.fromOffset(4, 4 + (i - 1) * T.Geometry.Option),
                Size = UDim2.new(1, -8, 0, T.Geometry.Option),
                ZIndex = group.ZIndex + 1,
            })
            U.corner(button, T.Radius.Row)
            SettingsUI.text(
                w,
                button,
                key,
                { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0) },
                key == "Delete" and "Danger" or "SystemText"
            )
            U.connect(bag, button.MouseEnter, function()
                button.BackgroundTransparency = 0
                button.BackgroundColor3 = w.theme.SurfaceSelected
            end)
            U.connect(bag, button.MouseLeave, function()
                button.BackgroundTransparency = 1
            end)
            U.connect(bag, button.Activated, function()
                local active = w.overlay.active
                if not owner:_usable() or not owner.state.Open or not active or active.owner ~= owner then
                    return
                end
                w.overlay:Close(true)
                actions[key]()
                SettingsUI.refreshProfiles(w)
            end)
        end
    end)
end
function SettingsUI.refreshProfiles(w)
    if w.overlay.active and w.overlay.active.owner.profileContext then
        w.overlay:Close(true)
    end
    if not w.settingsPages or not w.settingsPages.Profiles or w.destroyed then
        return
    end
    if w.persistence.refreshCancel then
        w.bag:Remove(w.persistence.refreshCancel, true)
        w.persistence.refreshCancel = nil
    end
    if w.profileListBag then
        w.profileListBag:Destroy()
    end
    local bag = Maid.new(w.motion)
    w.profileListBag = bag
    local page = w.settingsPages.Profiles
    local profiles, err = w:RefreshProfiles()
    w.persistenceLabel:Set(Locale.text(w, w.persistence:Status()), true)
    if w.pathLabel then
        w.pathLabel:Set(w.persistence.folder, true)
    end
    if not profiles or #profiles == 0 then
        local empty = U.frame(page.scroll.frame, {
            Name = "ProfileEmpty",
            Size = UDim2.new(1, 0, 0, 64),
            LayoutOrder = 5,
            ZIndex = page.scroll.frame.ZIndex + 1,
        }, w, "RowBackground")
        bag:Add(empty)
        U.corner(empty, T.Radius.Row)
        SettingsUI.text(
            w,
            empty,
            err and w.persistence:Status() or "NoProfiles",
            { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 1, 0) }
        )
    else
        local autoload = w:GetAutoload()
        for i, name in ipairs(profiles) do
            local row = U.button(page.scroll.frame, {
                Name = "Profile",
                Size = UDim2.new(1, 0, 0, 48),
                LayoutOrder = 5 + i,
                BackgroundTransparency = 0,
                ZIndex = page.scroll.frame.ZIndex + 1,
            })
            bag:Add(row)
            U.corner(row, T.Radius.Row)
            U.bind(
                w,
                row,
                "BackgroundColor3",
                w.persistence.activeProfile == name and "SurfaceSelected" or "RowBackground"
            )
            local glyph = Icons.make(row, "folder", 14, w.theme.TextSecondary, w)
            glyph.Position = UDim2.fromOffset(14, 17)
            U.label(row, name, T.Type.Value, w.theme.TextPrimary, {
                Position = UDim2.fromOffset(38, 0),
                Size = UDim2.new(1, w.persistence.activeProfile == name and -190 or -120, 1, 0),
            })
            if autoload.enabled and autoload.profile == name then
                local dot = Components.circle(row, 4, w.theme.Accent)
                dot.Position = UDim2.new(1, -70, 0.5, 0)
            end
            if w.persistence.activeProfile == name then
                SettingsUI.text(w, row, "Active", {
                    Position = UDim2.new(1, -128, 0, 0),
                    Size = UDim2.fromOffset(80, 48),
                    TextXAlignment = Enum.TextXAlignment.Right,
                }, "TextSecondary")
            end
            local menu = U.button(row, {
                Name = "ProfileActions",
                Position = UDim2.new(1, -44, 0, 2),
                Size = UDim2.fromOffset(40, 44),
                ZIndex = row.ZIndex + 2,
            })
            local icon = Icons.make(menu, "chevron", 8, w.theme.SystemText, w)
            icon.Position = UDim2.fromOffset(16, 18)
            U.connect(bag, row.Activated, function()
                w.selectedProfile = name
                w.profileName:Set(name, true)
            end)
            U.connect(bag, menu.Activated, function()
                w.selectedProfile = name
                SettingsUI.context(w, menu, name)
            end)
            U.connect(bag, row.MouseEnter, function()
                w.motion:To(row, T.Motion.Micro, { BackgroundColor3 = w.theme.RowHover })
            end)
            U.connect(bag, row.MouseLeave, function()
                w.motion:To(row, T.Motion.Micro, {
                    BackgroundColor3 = w.persistence.activeProfile == name and w.theme.SurfaceSelected
                        or w.theme.RowBackground,
                })
            end)
        end
    end
    page.scroll:Update()
end
function SettingsUI.profiles(w, page)
    SettingsUI.heading(w, page, "Profiles", "ProfileBody")
    w.persistenceLabel = SettingsUI.control(w, page, "AddLabel", w.persistence:Status())
    w.pathLabel = page:AddLabel(w.persistence.folder)
    w.profileName = SettingsUI.control(w, page, "AddTextbox", "ProfileName", { Default = "Default", MaxLength = 80 })
    SettingsUI.control(w, page, "AddButton", "Create", {
        Primary = true,
        Callback = function()
            local ok, err = w:CreateProfile(w.profileName:Get())
            SettingsUI.result(w, ok, err, "Saved")
            SettingsUI.refreshProfiles(w)
        end,
    })
    local toolbar = U.frame(page.scroll.frame, {
        Name = "ProfileToolbar",
        Size = UDim2.new(1, 0, 0, 176),
        LayoutOrder = 10000,
        ZIndex = page.scroll.frame.ZIndex + 1,
    }, w)
    page.bag:Add(toolbar)
    local actions = {
        {
            key = "Save",
            run = function()
                local ok, err = w:SaveProfile(w.profileName:Get())
                SettingsUI.result(w, ok, err, "Saved")
                SettingsUI.refreshProfiles(w)
            end,
        },
        {
            key = "Load",
            run = function()
                local ok, err = w:LoadProfile(w.profileName:Get(), w.persistence.silentLoad)
                SettingsUI.result(w, ok, err, "Loaded")
                SettingsUI.refreshProfiles(w)
            end,
        },
        {
            key = "Refresh",
            run = function()
                SettingsUI.refreshProfiles(w)
            end,
        },
        {
            key = "Autoload",
            run = function()
                local ok, err = w:SetAutoload(w.profileName:Get())
                SettingsUI.result(w, ok, err, "AutoloadEnabled")
                SettingsUI.refreshProfiles(w)
            end,
        },
        {
            key = "Import",
            run = function()
                SettingsUI.transfer(w, "profile", "", true)
            end,
        },
        {
            key = "Export",
            run = function()
                local json, err = w:ExportProfile(w.profileName:Get())
                if json then
                    SettingsUI.transfer(w, "profile", json, false)
                else
                    SettingsUI.result(w, false, err, "Ready")
                end
            end,
        },
        {
            key = "Disable",
            run = function()
                local ok, err = w:DisableAutoload()
                SettingsUI.result(w, ok, err, "AutoloadDisabled")
                SettingsUI.refreshProfiles(w)
            end,
        },
        {
            key = "Themes",
            run = function()
                w:SetSettingsCategory("Themes")
            end,
        },
    }
    local buttons = {}
    for i, action in ipairs(actions) do
        buttons[i] = SettingsUI.button(
            w,
            toolbar,
            action.key,
            { Name = action.key, ZIndex = toolbar.ZIndex + 1 },
            page.bag,
            action.run
        )
    end
    w.profileToolbarLayout = function()
        local width = toolbar.AbsoluteSize.X / w.scale
        local columns = width >= 540 and 4 or 2
        local rows = math.ceil(#buttons / columns)
        local height = rows * 36 + (rows - 1) * 8
        if toolbar.Size.Y.Offset ~= height then
            toolbar.Size = UDim2.new(1, 0, 0, height)
        end
        for i, button in ipairs(buttons) do
            local col, row = (i - 1) % columns, math.floor((i - 1) / columns)
            button.Size = UDim2.new(1 / columns, -6, 0, 36)
            button.Position = UDim2.new(col / columns, col > 0 and 2 or 0, 0, row * 44)
        end
        page.scroll:Update()
    end
    U.connect(page.bag, toolbar:GetPropertyChangedSignal("AbsoluteSize"), w.profileToolbarLayout)
    local function compactInfo(control)
        function control:layoutVisual()
            self.row.Size = UDim2.new(1, 0, 0, 28)
            self.label.Position = UDim2.fromOffset(16, 4)
            self.label.Size = UDim2.new(1, -32, 0, 20)
            self.separator.Visible = false
        end
        control:_layout()
    end
    compactInfo(w.persistenceLabel)
    compactInfo(w.pathLabel)
    w.profileToolbarLayout()
    SettingsUI.refreshProfiles(w)
end
function SettingsUI.preview(w, page, name, order)
    local card = U.button(page.scroll.frame, {
        Name = name,
        Size = UDim2.new(1, 0, 0, 92),
        LayoutOrder = order,
        BackgroundTransparency = 0,
        ZIndex = page.scroll.frame.ZIndex + 1,
    })
    page.bag:Add(card)
    U.corner(card, T.Radius.Row)
    local colors = Presentation.colors(name)
    local preview = U.new("CanvasGroup", {
        Name = "ThemePreview",
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.fromOffset(110, 64),
        BackgroundTransparency = 0,
        BackgroundColor3 = colors.ContentBackground,
        GroupTransparency = 0,
        ZIndex = card.ZIndex + 1,
    }, card)
    U.corner(preview, T.Radius.Popover)
    U.frame(preview, {
        Size = UDim2.new(0, 28, 1, 0),
        BackgroundTransparency = 0,
        BackgroundColor3 = colors.SidebarBackground,
        ZIndex = preview.ZIndex,
    }, w)
    for i = 1, 3 do
        U.frame(preview, {
            Position = UDim2.fromOffset(34, 10 + (i - 1) * 16),
            Size = UDim2.fromOffset(68, 12),
            BackgroundTransparency = 0,
            BackgroundColor3 = colors.RowBackground,
            ZIndex = preview.ZIndex + 1,
        }, w)
    end
    U.frame(preview, {
        Position = UDim2.fromOffset(39, 14),
        Size = UDim2.fromOffset(22, 2),
        BackgroundTransparency = 0,
        BackgroundColor3 = colors.TextPrimary,
        ZIndex = preview.ZIndex + 2,
    }, w)
    local control = U.frame(preview, {
        Position = UDim2.fromOffset(87, 13),
        Size = UDim2.fromOffset(10, 4),
        BackgroundTransparency = 0,
        BackgroundColor3 = colors.Accent,
        ZIndex = preview.ZIndex + 2,
    }, w)
    U.corner(control, 2)
    local rail = U.frame(preview, {
        Position = UDim2.fromOffset(76, 30),
        Size = UDim2.fromOffset(20, 3),
        BackgroundTransparency = 0,
        BackgroundColor3 = colors.Accent,
        ZIndex = preview.ZIndex + 2,
    }, w)
    U.corner(rail, 1)
    -- Preview palettes belong to their represented theme, not the currently selected one.
    w.bindings[preview] = nil
    for _, obj in ipairs(preview:GetDescendants()) do
        w.bindings[obj] = nil
    end
    U.label(
        card,
        name,
        T.Type.Tab,
        w.theme.TextPrimary,
        { Position = UDim2.fromOffset(140, 22), Size = UDim2.new(1, -180, 0, 22), Font = Enum.Font.GothamMedium }
    )
    local selected = Components.circle(card, 5, w.theme.Accent)
    selected.Position = UDim2.new(1, -18, 0.5, 0)
    w.themeCards[name] = { row = card, dot = selected }
    U.connect(page.bag, card.Activated, function()
        if not SettingsUI.interactive(w, card) then
            return
        end
        w:SetTheme(name)
        w:Notify("ThemeChanged")
    end)
    U.connect(page.bag, card.MouseEnter, function()
        w.motion:To(card, T.Motion.Micro, { BackgroundColor3 = w.theme.RowHover })
    end)
    U.connect(page.bag, card.MouseLeave, function()
        SettingsUI.refreshStyle(w)
    end)
end
function SettingsUI.themes(w, page)
    SettingsUI.heading(w, page, "Themes", "ThemeBody")
    for i, name in ipairs(Presentation.order) do
        SettingsUI.preview(w, page, name, i + 1)
    end
    page.controlSerial = 10
    w.accentPreference = SettingsUI.control(w, page, "AddColorPicker", "Accent", {
        Default = w.theme.Accent,
        Callback = function(color)
            w:SetAccent(color)
        end,
    })
    SettingsUI.control(w, page, "AddButton", "ResetAccent", {
        Inline = true,
        Callback = function()
            w:SetTheme(w.themeName)
        end,
    })
    SettingsUI.control(w, page, "AddButton", "Import", {
        Inline = true,
        Callback = function()
            SettingsUI.transfer(w, "theme", "", true)
        end,
    })
    SettingsUI.control(w, page, "AddButton", "Export", {
        Inline = true,
        Callback = function()
            local json, err = w:ExportTheme()
            if json then
                SettingsUI.transfer(w, "theme", json, false)
            else
                SettingsUI.result(w, false, err, "Ready")
            end
        end,
    })
end
function SettingsUI.flag(w, parent, language)
    local flag = U.new("CanvasGroup", {
        Name = "Flag",
        Position = UDim2.fromOffset(16, 20),
        Size = UDim2.fromOffset(28, 28),
        BackgroundTransparency = 0,
        GroupTransparency = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = parent.ZIndex + 1,
    }, parent)
    U.corner(flag, 100)
    local function stripe(y, height, color)
        return U.frame(flag, {
            Position = UDim2.fromScale(0, y),
            Size = UDim2.fromScale(1, height),
            BackgroundTransparency = 0,
            BackgroundColor3 = color,
            ZIndex = flag.ZIndex + 1,
        }, w)
    end
    if language == "Russian" then
        stripe(0, 1 / 3, Color3.fromRGB(243, 244, 246))
        stripe(1 / 3, 1 / 3, Color3.fromRGB(48, 83, 174))
        stripe(2 / 3, 1 / 3, Color3.fromRGB(194, 54, 61))
    elseif language == "Spanish" then
        stripe(0, 1 / 4, Color3.fromRGB(175, 42, 52))
        stripe(1 / 4, 1 / 2, Color3.fromRGB(231, 181, 64))
        stripe(3 / 4, 1 / 4, Color3.fromRGB(175, 42, 52))
    elseif language == "Portuguese" then
        stripe(0, 1, Color3.fromRGB(45, 133, 80))
        U.frame(flag, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(17, 17),
            Rotation = 45,
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(229, 194, 58),
            ZIndex = flag.ZIndex + 2,
        }, w)
        local globe = Components.circle(flag, 11, Color3.fromRGB(51, 71, 132))
        globe.Position = UDim2.fromScale(0.5, 0.5)
        globe.ZIndex = flag.ZIndex + 3
        Icons.line(globe, 0.13, 0.42, 0.87, 0.60, Color3.fromRGB(226, 229, 221), 1)
    else
        for i = 0, 12 do
            stripe(i / 13, 1 / 13, i % 2 == 0 and Color3.fromRGB(177, 63, 74) or Color3.fromRGB(241, 235, 231))
        end
        U.frame(flag, {
            Size = UDim2.fromScale(0.48, 0.54),
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(54, 71, 127),
            ZIndex = flag.ZIndex + 2,
        }, w)
        for x = 1, 3 do
            for y = 1, 3 do
                local dot = Components.circle(flag, 1, Color3.fromRGB(242, 241, 238))
                dot.Position = UDim2.fromOffset(x * 3, y * 3 + 2)
                dot.ZIndex = flag.ZIndex + 3
            end
        end
    end
    w.bindings[flag] = nil
    for _, object in ipairs(flag:GetDescendants()) do
        w.bindings[object] = nil
    end
end
function SettingsUI.languages(w, page)
    SettingsUI.heading(w, page, "Language", "LanguageBody")
    local names = { English = "English", Spanish = "Español", Russian = "Русский", Portuguese = "Português" }
    local regions = { English = "US", Spanish = "ES", Russian = "RU", Portuguese = "BR" }
    for i, language in ipairs(Locale.order) do
        local card = U.button(page.scroll.frame, {
            Name = language,
            Size = UDim2.new(1, 0, 0, 68),
            LayoutOrder = i + 1,
            BackgroundTransparency = 0,
            ZIndex = page.scroll.frame.ZIndex + 1,
        })
        page.bag:Add(card)
        U.corner(card, T.Radius.Row)
        SettingsUI.flag(w, card, language)
        U.label(
            card,
            names[language],
            T.Type.Tab,
            w.theme.TextPrimary,
            { Position = UDim2.fromOffset(58, 12), Size = UDim2.new(1, -90, 0, 24), Font = Enum.Font.GothamMedium }
        )
        U.label(
            card,
            regions[language],
            T.Type.PageSubtitle,
            w.theme.TextSecondary,
            { Position = UDim2.fromOffset(58, 36), Size = UDim2.new(1, -90, 0, 18) }
        )
        local dot = Components.circle(card, 5, w.theme.Accent)
        dot.Position = UDim2.new(1, -18, 0.5, 0)
        w.languageCards[language] = { row = card, dot = dot }
        U.connect(page.bag, card.Activated, function()
            if SettingsUI.interactive(w, card) then
                w:SetLanguage(language)
            end
        end)
        U.connect(page.bag, card.MouseEnter, function()
            w.motion:To(card, T.Motion.Micro, { BackgroundColor3 = w.theme.RowHover })
        end)
        U.connect(page.bag, card.MouseLeave, function()
            SettingsUI.refreshStyle(w)
        end)
    end
end
function SettingsUI.general(w, page)
    SettingsUI.heading(w, page, "General", "GeneralBody")
    w.tooltipPreference = SettingsUI.control(w, page, "AddToggle", "Tooltips", {
        Default = w.tooltipsEnabled,
        Callback = function(value)
            w:SetTooltipsEnabled(value)
        end,
    })
    w.resizePreference = SettingsUI.control(w, page, "AddToggle", "Resizable", {
        Default = w.resizeEnabled,
        Callback = function(value)
            w:SetResizable(value)
        end,
    })
    w.rememberSizePreference = SettingsUI.control(w, page, "AddToggle", "RememberSize", {
        Default = w.rememberSize,
        Callback = function(value)
            w:SetRememberSize(value)
        end,
    })
    w.rememberPositionPreference = SettingsUI.control(w, page, "AddToggle", "RememberPosition", {
        Default = w.rememberPosition,
        Callback = function(value)
            w:SetRememberPosition(value)
        end,
    })
    SettingsUI.control(w, page, "AddToggle", "SilentLoad", {
        Default = w.persistence.silentLoad,
        Callback = function(value)
            w.persistence.silentLoad = value
        end,
    }, "SilentBody")
    w.searchPreference = SettingsUI.control(w, page, "AddToggle", "SearchEnabled", {
        Default = w.searchEnabled,
        Callback = function(value)
            w:SetSearchEnabled(value)
        end,
    })
    SettingsUI.control(w, page, "AddToggle", "Notifications", {
        Default = w.systemNotifications ~= false,
        Callback = function(value)
            w.systemNotifications = value
        end,
    })
    Premium.build(w, page)
end
function SettingsUI.refreshStyle(w)
    for key, entry in pairs(w.settingsNav or {}) do
        local selected = w.settingsCategory == key
        entry.row.BackgroundColor3 = selected and w.theme.SurfaceSelected or w.theme.SidebarBackground
        entry.label.TextColor3 = selected and w.theme.TextPrimary or w.theme.SystemText
        entry.indicator.Visible = selected
        entry.indicator.BackgroundColor3 = w.theme.Accent
    end
    for name, card in pairs(w.themeCards or {}) do
        card.row.BackgroundColor3 = name == w.themeName and w.theme.SurfaceSelected or w.theme.RowBackground
        card.dot.Visible = name == w.themeName
        card.dot.BackgroundColor3 = w.theme.Accent
    end
    for language, card in pairs(w.languageCards or {}) do
        card.row.BackgroundColor3 = language == w.language and w.theme.SurfaceSelected or w.theme.RowBackground
        card.dot.Visible = language == w.language
        card.dot.BackgroundColor3 = w.theme.Accent
    end
    if w.settingsIcon then
        Icons.color(w.settingsIcon, w.settingsOpen and w.theme.Accent or w.theme.TextSecondary)
    end
end
function SettingsUI.refreshLanguage(w)
    Premium.refresh(w)
    for control, keys in pairs(w.systemControls or {}) do
        if not control.destroyed then
            control:SetName(Locale.text(w, keys.name))
            if keys.description then
                control:SetDescription(Locale.text(w, keys.description))
            end
        else
            w.systemControls[control] = nil
        end
    end
    SettingsUI.layout(w)
    if w.settingsPages then
        SettingsUI.refreshProfiles(w)
    end
end
function SettingsUI.transientLayout(w)
    if w.confirmation then
        w.confirmation.panel.Size = UDim2.fromOffset(math.min(360, w.root.Size.X.Offset - 32), 178)
    end
    if w.toastGroup then
        w.toastGroup.Size = UDim2.fromOffset(math.min(320, w.root.Size.X.Offset - 36), 54)
    end
end
function SettingsUI.layout(w)
    if not w.settingsPanel then
        return
    end
    local compact = w.compact or w.root.Size.X.Offset < 640
    w.settingsPanel.Position = UDim2.fromOffset(compact and 8 or 18, compact and 12 or 28)
    w.settingsPanel.Size = UDim2.new(1, -(compact and 16 or 36), 1, -(compact and 24 or 56))
    w.settingsNavHost.Position = UDim2.fromOffset(8, 56)
    w.settingsNavHost.Size = compact and UDim2.new(1, -16, 0, 40) or UDim2.new(0, 140, 1, -64)
    w.settingsNavLayout.FillDirection = compact and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
    w.settingsNavHost.ScrollingDirection = compact and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y
    w.settingsNavHost.AutomaticCanvasSize = compact and Enum.AutomaticSize.X or Enum.AutomaticSize.Y
    for key, entry in pairs(w.settingsNav) do
        entry.row.Size =
            UDim2.fromOffset(compact and math.max(80, U.width(Locale.text(w, key), T.Type.Value) + 32) or 140, 36)
        entry.indicator.Size = compact and UDim2.new(1, -16, 0, 1) or UDim2.new(0, 2, 1, -16)
        entry.indicator.Position = compact and UDim2.new(0, 8, 1, -1) or UDim2.fromOffset(0, 8)
    end
    w.settingsBody.Position = UDim2.fromOffset(compact and 12 or 164, compact and 106 or 60)
    w.settingsBody.Size = UDim2.new(1, -(compact and 24 or 180), 1, -(compact and 120 or 74))
    if w.profileToolbarLayout then
        w.profileToolbarLayout()
    end
    for _, page in pairs(w.settingsPages) do
        for _, control in ipairs(page.controls) do
            control:_layout()
        end
        page.scroll:Update()
    end
end
function Window:SetSettingsCategory(key)
    if not self.settingsPages or not self.settingsPages[key] then
        return false
    end
    self.overlay:Close(true)
    self.input:Cancel()
    U.focusRelease(self)
    SettingsUI.dismissConfirmation(self)
    SettingsUI.dismissTransfer(self)
    self.settingsCategory = key
    for name, page in pairs(self.settingsPages) do
        self.motion:Cancel(page.host)
        page.host.Visible = name == key
        if name == key then
            page.host.GroupTransparency = 0.35
            self.motion:To(page.host, T.Motion.Normal, { GroupTransparency = 0 })
        end
    end
    if key == "Profiles" then
        SettingsUI.refreshProfiles(self)
    end
    SettingsUI.refreshStyle(self)
    return true
end
function SettingsUI.build(w)
    w.settingsPages, w.settingsNav, w.themeCards, w.languageCards = {}, {}, {}, {}
    w.systemControls = setmetatable({}, { __mode = "k" })
    local panel = U.new("CanvasGroup", {
        Name = "SettingsOverlay",
        Visible = false,
        GroupTransparency = 1,
        BackgroundTransparency = 0,
        BackgroundColor3 = w.theme.WindowBackground,
        ClipsDescendants = true,
        ZIndex = T.Z.Settings,
    }, w.root)
    w.settingsPanel = panel
    U.corner(panel, T.Radius.Window)
    U.bind(w, panel, "BackgroundColor3", "WindowBackground")
    local stroke = U.stroke(panel, w.theme.SurfaceEdge, 1)
    stroke.Transparency = 0.4
    SettingsUI.text(w, panel, "Settings", {
        Position = UDim2.fromOffset(16, 10),
        Size = UDim2.new(1, -160, 0, 30),
        Font = Enum.Font.GothamBold,
        TextSize = T.Type.PageTitle,
    }, "TextPrimary")
    SettingsUI.button(
        w,
        panel,
        "Close",
        { Position = UDim2.new(1, -100, 0, 8), Size = UDim2.fromOffset(88, 36), ZIndex = panel.ZIndex + 3 },
        w.bag,
        function()
            w:CloseSettings()
        end
    )
    U.frame(
        panel,
        { Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 1), ZIndex = panel.ZIndex + 1 },
        w,
        "Separator"
    )
    w.settingsNavHost = U.new(
        "ScrollingFrame",
        { Name = "SettingsCategories", ScrollBarThickness = 0, CanvasSize = UDim2.new(), ZIndex = panel.ZIndex + 1 },
        panel
    )
    w.settingsNavLayout =
        U.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, w.settingsNavHost)
    for i, key in ipairs({ "Profiles", "Themes", "Language", "General" }) do
        local row = U.button(
            w.settingsNavHost,
            { Name = key, LayoutOrder = i, BackgroundTransparency = 0, ZIndex = panel.ZIndex + 2 }
        )
        U.corner(row, T.Radius.Row)
        local label =
            SettingsUI.text(w, row, key, { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -24, 1, 0) })
        local indicator = U.frame(row, { ZIndex = row.ZIndex + 2 }, w, "Accent")
        w.settingsNav[key] = { row = row, label = label, indicator = indicator }
        U.connect(w.bag, row.Activated, function()
            if SettingsUI.interactive(w, row) then
                w:SetSettingsCategory(key)
            end
        end)
        U.connect(w.bag, row.MouseEnter, function()
            w.motion:To(row, T.Motion.Micro, { BackgroundColor3 = w.theme.RowHover })
        end)
        U.connect(w.bag, row.MouseLeave, function()
            SettingsUI.refreshStyle(w)
        end)
    end
    w.settingsBody = U.frame(
        panel,
        { Name = "SettingsBody", ClipsDescendants = true, ZIndex = panel.ZIndex + 1 },
        w,
        "ContentBackground"
    )
    SettingsUI.profiles(w, SettingsUI.page(w, "Profiles"))
    SettingsUI.themes(w, SettingsUI.page(w, "Themes"))
    SettingsUI.languages(w, SettingsUI.page(w, "Language"))
    SettingsUI.general(w, SettingsUI.page(w, "General"))
    SettingsUI.layout(w)
end
function SettingsUI.footerLayout(w)
    w.content.Size =
        UDim2.new(1, -(w.compact and 0 or T.Geometry.Sidebar), 1, -(w.compact and w.settingsEnabled and 48 or 0))
end
function SettingsUI.init(w, config)
    w.settingsEnabled = config.Settings ~= false
    local button = U.button(w.root, {
        Name = "Settings",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 12, 1, -6),
        Size = UDim2.fromOffset(44, 40),
        Visible = w.settingsEnabled,
        ZIndex = 14,
    })
    U.corner(button, T.Radius.Row)
    w.settingsButton = button
    Tooltip.bind(w, w, button, w.bag, function()
        return w:Translate("Settings")
    end, function()
        return w.settingsEnabled
    end)
    w.settingsIcon = Icons.make(button, "settings", 16, w.theme.TextSecondary, w)
    w.settingsIcon.Position = UDim2.fromOffset(14, 12)
    U.connect(w.bag, button.Activated, function()
        if w.settingsOpen then
            w:CloseSettings()
        else
            w:OpenSettings()
        end
    end)
    U.connect(w.bag, button.MouseEnter, function()
        w.motion:To(button, T.Motion.Micro, { BackgroundColor3 = w.theme.RowHover, BackgroundTransparency = 0 })
    end)
    U.connect(w.bag, button.MouseLeave, function()
        w.motion:To(button, T.Motion.Micro, { BackgroundTransparency = 1 })
    end)
    U.connect(w.bag, button.InputBegan, function(event)
        if U.primary(event) then
            w.motion:To(button, T.Motion.Micro, { BackgroundColor3 = w.theme.RowPressed, BackgroundTransparency = 0 })
        end
    end)
    U.connect(w.bag, button.InputEnded, function(event)
        if U.primary(event) then
            w.motion:To(button, T.Motion.Micro, { BackgroundColor3 = w.theme.RowHover })
        end
    end)
    SettingsUI.footerLayout(w)
end
function Window:OpenSettings(category)
    if self.destroyed or not self.visible or not self.settingsEnabled then
        return self
    end
    self.overlay:Close(true)
    self.input:Cancel()
    self:CloseSearch(true)
    U.focusRelease(self)
    if self.settingsCancel then
        self.bag:Remove(self.settingsCancel, true)
        self.settingsCancel = nil
    end
    if not self.settingsPanel then
        SettingsUI.build(self)
    end
    self.settingsOpen = true
    self:SetSidebarVisible(false)
    self.settingsPanel.Visible = true
    self:_dimState(true, 0.38)
    self.motion:To(self.settingsPanel, T.Motion.Structural, { GroupTransparency = 0 })
    self:SetSettingsCategory(category or self.settingsCategory or "Profiles")
    SettingsUI.layout(self)
    return self
end
function Window:CloseSettings(immediate)
    if self.destroyed and not immediate then
        return self
    end
    self.settingsOpen = false
    self.overlay:Close(true)
    self.input:Cancel()
    U.focusRelease(self)
    SettingsUI.dismissConfirmation(self)
    SettingsUI.dismissTransfer(self)
    if self.settingsCancel then
        self.bag:Remove(self.settingsCancel, true)
        self.settingsCancel = nil
    end
    if self.settingsPanel then
        self.motion:To(self.settingsPanel, immediate and 0 or T.Motion.Fast, { GroupTransparency = 1 })
        if immediate then
            self.settingsPanel.Visible = false
        else
            self.settingsCancel = self.bag:After(T.Motion.Fast, function()
                self.settingsCancel = nil
                if not self.settingsOpen then
                    self.settingsPanel.Visible = false
                end
            end)
        end
    end
    self:_dimState(false, 1, immediate)
    SettingsUI.refreshStyle(self)
    return self
end
function Window:SetSettingsEnabled(enabled)
    self.settingsEnabled = enabled == true
    self.settingsButton.Visible = self.settingsEnabled
    SettingsUI.footerLayout(self)
    if not self.settingsEnabled then
        self:CloseSettings(true)
    end
    return self
end

-- Optional showcase: uses only the public API, never executes automatically.
function Library:Demo(config)
    config = config or {}
    if config.Name == nil then
        config.Name = "NERON"
    end
    local w = self:CreateWindow(config)
    local basic = w:AddTab({
        Name = "Basic Settings",
        Category = "GENERAL",
        Icon = "discord",
        Description = "Here are the main configuration parameters for the application or system.",
    })
    local general = basic:AddSubTab({ Name = "General", Icon = "discord" })
    local additional = basic:AddSubTab({ Name = "Additional", Icon = "settings" })
    local misc = basic:AddSubTab({ Name = "Misc", Icon = "misc" })
    general:AddToggle({ Name = "Enable autostart on system boot", Default = false, Flag = "Autostart" })
    general:AddToggle({ Name = "Show popup notifications", Default = true, Flag = "Notifications" })
    general:AddDropdown({
        Name = "Interface Language",
        Values = { "English", "Russian", "Deutsch" },
        Default = "English",
    })
    general:AddDropdown({ Name = "Theme", Values = { "Dark", "Light", "System" }, Default = "Dark" })
    general:AddTextbox({ Name = "Username", Default = "Admin", MaxLength = 64 })
    general:AddSlider({ Name = "Maximum concurrent downloads", Min = 1, Max = 20, Default = 5 })
    general:AddSlider({
        Name = "Log detail level",
        Description = "Controls how much information is written to the log file. Higher values mean more details.",
        Min = 0,
        Max = 1,
        Step = 0.1,
        Default = 0.7,
    })
    general:AddRangeSlider({ Name = "Allowed port range", Min = 0, Max = 65535, Default = { 1024, 65535 } })
    general:AddMultiDropdown({
        Name = "Preferred server regions",
        Description = "Select regions for potentially faster connection speeds.",
        Values = {
            "America (North)",
            "America (South)",
            "Europe (Frankfurt)",
            "Europe (London)",
            "Asia (Tokyo)",
            "Asia (Singapore)",
        },
        Default = { "Europe (Frankfurt)" },
    })
    general:AddColorPicker({ Name = "Active element color", Default = Color3.fromRGB(70, 177, 245), Alpha = 1 })
    local custom = general:AddToggle({
        Name = "Use custom background color",
        Description = "Overrides the theme's default background color when checked.",
    })
    custom:AddColorPicker({ Name = "Custom background color", Default = Color3.new(1, 1, 1) })
    general:AddButton({ Name = "Reset all settings to default" })
    general:AddRangeSlider({
        Name = "Response timeout range",
        Min = 0.1,
        Max = 5,
        Step = 0.1,
        Default = { 0.5, 2 },
        Suffix = "s",
    })
    additional:AddToggle({
        Name = "Enable update checks",
        Description = "Check for updates when the application starts.",
        Default = true,
    })
    additional:AddParagraph({
        Name = "Updates",
        Description = "Additional settings use their own page and scroll position.",
    })
    misc:AddSection({ Name = "INFORMATION" })
    misc:AddNotice({ Name = "Local UI only", Description = "The showcase does not alter gameplay." })
    misc:AddSeparator()
    misc:AddLabel("Neron UI " .. self.Version)
    local accessibility = w:AddTab({
        Name = "Accessibility",
        Category = "GENERAL",
        Icon = "flag",
        Description = "Input and presentation preferences.",
    })
    accessibility:AddSubTab({ Name = "General" }):AddToggle({ Name = "Enable keyboard navigation", Default = true })
    local display = w:AddTab({
        Name = "Display Settings",
        Category = "VISUALIZATION",
        Icon = "chart",
        Description = "Parameters affecting the visual representation of data and the interface.",
    })
    local view = display:AddSubTab({ Name = "General", Icon = "discord" })
    display
        :AddSubTab({ Name = "Additional", Icon = "settings" })
        :AddToggle({ Name = "Enable secondary display", Default = false })
    display:AddSubTab({ Name = "Misc", Icon = "misc" }):AddParagraph({
        Name = "Display information",
        Description = "Color and layout controls follow the same design tokens.",
    })
    view:AddToggle({
        Name = "Display grid on charts",
        Description = "Automatically starts the application when your computer boots up.",
        Default = true,
    })
    view:AddToggle({
        Name = "Use font anti-aliasing",
        Description = "Makes text appear smoother on screen; may slightly impact performance.",
    })
    view:AddDropdown({ Name = "Default chart type", Values = { "Line", "Bar", "Pie", "Scatter" } })
    view:AddSlider({ Name = "Chart line thickness", Min = 1, Max = 10, Default = 2, Suffix = "%" })
    view:AddSlider({
        Name = "Inactive element opacity",
        Description = "Adjusts transparency of UI elements that are not currently active or hovered over.",
        Min = 0,
        Max = 100,
        Default = 50,
        Suffix = "%",
    })
    view:AddDropdown({ Name = "Interface color scheme", Values = { "Contrast", "Soft", "System" } })
    view:AddDropdown({
        Name = "Controls the visual effects when switching between views",
        Values = { "Disable", "Fast", "Smooth" },
    })
    view:AddColorPicker({ Name = "Chart background color", Default = Color3.new(1, 1, 1) })
    view:AddColorPicker({ Name = "Data highlight color", Default = Color3.fromRGB(240, 65, 50) })
    view:AddRangeSlider({ Name = "Font size range", Min = 10, Max = 24, Default = { 10, 16 }, Suffix = "px" })
    view:AddMultiDropdown({
        Name = "Table columns to display",
        Values = { "ID", "Name", "Status", "Date", "Type" },
        Default = { "ID", "Name", "Status" },
    })
    view:AddTextbox({ Name = "Watermark text", Default = "Neron Corp." })
    view:AddButton({ Name = "Apply visual settings" })
    view:AddRangeSlider({
        Name = "Contrast range",
        Description = "Adjusts the difference between light and dark areas for better visibility.",
        Min = 0.1,
        Max = 2,
        Step = 0.1,
        Default = { 0.8, 1.2 },
    })
    local profile = w:AddTab({ Name = "Profile Management", Category = "VISUALIZATION", Icon = "profile" })
    profile:AddSubTab({ Name = "General" }):AddTextbox({ Name = "Profile name", Default = "Default" })
    local advanced = w:AddTab({
        Name = "Advanced Parameters",
        Category = "MISCELLANEOUS",
        Icon = "settings",
        Description = "Various settings not included in the main categories.",
    })
    local params = advanced:AddSubTab({ Name = "General", Icon = "discord" })
    params:AddDropdown({ Name = "Interface scale", Values = { "0.75x", "1x", "1.5x", "2x" }, Default = "1x" })
    params:AddToggle({
        Name = "Enable debug mode",
        Description = "Provides more detailed error messages and logging for troubleshooting.",
    })
    params:AddToggle({
        Name = "Send anonymous usage statistics",
        Description = "Help improve the application by sending non-personal data about how features are used.",
    })
    params:AddTextbox({ Name = "Temporary files path", Default = "/tmp/neron_cache" })
    params:AddSlider({ Name = "Autosave interval", Min = 1, Max = 60, Default = 15, Suffix = "min" })
    local backup = w:AddTab({ Name = "Data Sync & Backup", Category = "MISCELLANEOUS", Icon = "folder" })
    backup:AddSubTab({ Name = "General" }):AddButton({ Name = "Back up settings", Inline = true })
    basic:Select()
    general:Select()
    return w
end
return Library
