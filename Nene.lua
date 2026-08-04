--!strict

--[[
    Kronos.lua
    Self-contained native Roblox UI library reconstructed from the supplied
    2340x1080 reference video. All controllers and the optional showcase live
    in this file; no remote modules or external UI libraries are required.
]]

type AnyTable = { [any]: any }
type ThemeMap = { [string]: Color3 }
type WindowConfig = {
    Title: string?,
    Subtitle: string?,
    SubTitle: string?,
    SearchBar: boolean?,
    Accent: Color3?,
    ToggleKey: Enum.KeyCode?,
    MobileToggle: boolean?,
    FloatingWidgets: boolean?,
    StatusStrip: boolean?,
    TargetList: boolean?,
    KeybindList: boolean?,
    Size: UDim2?,
    Width: number?,
    Height: number?,
}

local Kronos: AnyTable = {}
Kronos.Version = "1.0.0"
Kronos.Options = {} :: AnyTable
Kronos.Windows = {} :: { AnyTable }
Kronos.Connections = {} :: { RBXScriptConnection }
Kronos.Notifications = {} :: { Instance }
Kronos.Flags = {} :: AnyTable
Kronos.ThemeBindings = {} :: { AnyTable }
Kronos.ActiveTweens = setmetatable({}, { __mode = "k" }) :: AnyTable
Kronos.Destroyed = false
Kronos.Keybinds = {} :: { AnyTable }
Kronos.Widgets = {} :: { AnyTable }

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

local RuntimeEnvironment: AnyTable = getfenv() :: AnyTable
local Environment: AnyTable = RuntimeEnvironment
local resolvedSharedEnvironment = false
if type(RuntimeEnvironment.getgenv) == "function" then
    local sharedOk, sharedEnvironment = pcall(RuntimeEnvironment.getgenv)
    if sharedOk and type(sharedEnvironment) == "table" then
        Environment = sharedEnvironment
        resolvedSharedEnvironment = true
    end
end
if not resolvedSharedEnvironment and type(RuntimeEnvironment.shared) == "table" then
    Environment = RuntimeEnvironment.shared
end
local previous = Environment.__KRONOS_ACTIVE
local previousCleanupOk = true
local previousCleanupError: any = nil
if type(previous) == "table" and type(previous.Destroy) == "function" then
    previousCleanupOk, previousCleanupError = pcall(previous.Destroy, previous)
end
Environment.__KRONOS_ACTIVE = nil

local Theme: ThemeMap = {
    Background = Color3.fromRGB(9, 9, 11),
    BackgroundSoft = Color3.fromRGB(12, 12, 15),
    Surface = Color3.fromRGB(15, 15, 18),
    Surface2 = Color3.fromRGB(19, 19, 23),
    Surface3 = Color3.fromRGB(24, 24, 29),
    ElevatedSurface = Color3.fromRGB(21, 21, 25),
    SurfaceHover = Color3.fromRGB(27, 27, 33),
    HoverSurface = Color3.fromRGB(27, 27, 33),
    PressedSurface = Color3.fromRGB(31, 29, 38),
    Stroke = Color3.fromRGB(45, 45, 53),
    StrokeSoft = Color3.fromRGB(33, 33, 40),
    Border = Color3.fromRGB(45, 45, 53),
    Divider = Color3.fromRGB(31, 31, 37),
    Text = Color3.fromRGB(239, 239, 244),
    PrimaryText = Color3.fromRGB(239, 239, 244),
    SubText = Color3.fromRGB(154, 154, 166),
    SecondaryText = Color3.fromRGB(154, 154, 166),
    Muted = Color3.fromRGB(91, 91, 103),
    Disabled = Color3.fromRGB(61, 61, 70),
    DisabledText = Color3.fromRGB(91, 91, 101),
    Accent = Color3.fromRGB(143, 104, 255),
    AccentDark = Color3.fromRGB(99, 65, 186),
    AccentSoft = Color3.fromRGB(174, 127, 255),
    AccentHover = Color3.fromRGB(164, 121, 255),
    AccentPressed = Color3.fromRGB(119, 81, 213),
    White = Color3.fromRGB(255, 255, 255),
    Success = Color3.fromRGB(91, 196, 139),
    Warning = Color3.fromRGB(222, 173, 88),
    Error = Color3.fromRGB(220, 91, 108),
    Shadow = Color3.fromRGB(0, 0, 0),
    Overlay = Color3.fromRGB(4, 4, 6),
}

local Motion = {
    Hover = 0.1,
    Press = 0.08,
    Slider = 0.08,
    Toggle = 0.16,
    Dropdown = 0.19,
    PopupClose = 0.12,
    Tab = 0.2,
    TabExit = 0.12,
    Window = 0.28,
    Notification = 0.28,
    Tooltip = 0.14,
    Health = 0.18,
    KeybindRow = 0.16,
}

local Metrics = {
    Window = Vector2.new(820, 480),
    Header = 58,
    Sidebar = 205,
    CompactSidebar = 58,
    Row = 38,
    SectionGap = 12,
    Radius = 7,
    PopupRadius = 7,
    TouchTarget = 42,
    SafePadding = 12,
}

local Icons = {
    Crosshair = "⊙",
    Target = "◎",
    Combat = "⊙",
    Trigger = "◌",
    Eye = "◉",
    Visuals = "◉",
    Settings = "⚙",
    Gear = "⚙",
    Search = "⌕",
    User = "•",
    Home = "⌂",
    Folder = "▱",
    Misc = "✦",
    Shield = "◆",
    Color = "◐",
    Bell = "◒",
    Code = "<>",
    Star = "✦",
    NoRecoil = "◈",
    Rocket = "▲",
    Play = "▶",
    ChevronDown = "⌄",
    ChevronRight = "›",
    PanelTop = "▤",
    Sliders = "≡",
    Palette = "◐",
    Keyboard = "⌨",
    MousePointer = "⌖",
    Zap = "ϟ",
    Sparkles = "✦",
    Info = "i",
    Circle = "○",
    Check = "✓",
    X = "×",
    Default = "•",
}

local IconAliases = {
    Aimbot = "Crosshair",
    Aim = "Crosshair",
    Visual = "Eye",
    Options = "Settings",
    Config = "Settings",
    Player = "User",
    Kronos = "Folder",
}

local LucideFallbacks = {
    Activity = "⌁",
    Airplay = "▭",
    AlarmClock = "◷",
    AlignJustify = "≡",
    Archive = "▣",
    ArrowDown = "↓",
    ArrowLeft = "←",
    ArrowRight = "→",
    ArrowUp = "↑",
    Badge = "◇",
    Ban = "⊘",
    BellRing = "◒",
    Book = "▤",
    Bookmark = "▮",
    Box = "□",
    Briefcase = "▣",
    Calendar = "□",
    Camera = "◉",
    ChartBar = "▥",
    ChartLine = "⌁",
    CheckCircle = "✓",
    ChevronLeft = "‹",
    ChevronsUpDown = "↕",
    CircleDot = "⊙",
    Clipboard = "▤",
    Clock = "◷",
    Cloud = "☁",
    Cog = "⚙",
    Command = "⌘",
    Compass = "◎",
    Copy = "▣",
    Cpu = "◈",
    Database = "▥",
    Download = "↓",
    Edit = "✎",
    ExternalLink = "↗",
    EyeOff = "◌",
    File = "▤",
    Filter = "⌯",
    Flag = "⚑",
    Flame = "♢",
    Gauge = "◔",
    Gift = "◇",
    Globe = "○",
    Heart = "♡",
    Image = "▧",
    Inbox = "▤",
    Layers = "▦",
    LayoutDashboard = "▦",
    Link = "⌁",
    List = "☰",
    Lock = "◆",
    LogOut = "↦",
    Mail = "✉",
    Map = "▱",
    Menu = "☰",
    Minus = "−",
    Monitor = "▭",
    Moon = "◐",
    MoreHorizontal = "…",
    MoreVertical = "⋮",
    Mouse = "⌖",
    Move = "✥",
    Music = "♪",
    Package = "▣",
    Pause = "Ⅱ",
    Pen = "✎",
    Plus = "+",
    Power = "⏻",
    RefreshCcw = "↺",
    Save = "▣",
    Scan = "⌗",
    Send = "↗",
    Server = "▥",
    Share = "↗",
    ShoppingCart = "▱",
    Signal = "⌁",
    Skull = "☠",
    Smartphone = "▯",
    Sun = "☼",
    Terminal = ">_",
    Trash = "⌫",
    Trophy = "♢",
    Unlock = "◇",
    Upload = "↑",
    Volume2 = ")))",
    Wand = "✦",
    Wifi = "⌁",
    Wrench = "⚒",
    XCircle = "×",
}

for iconName, iconGlyph in pairs(LucideFallbacks) do
    if Icons[iconName] == nil then
        Icons[iconName] = iconGlyph
    end
end

local Maid = {}
Maid.__index = Maid

function Maid.new(): AnyTable
    return setmetatable({ Tasks = {} }, Maid)
end

function Maid:Give(taskValue: any): any
    table.insert(self.Tasks, taskValue)
    return taskValue
end

function Maid:Cleanup()
    for index = #self.Tasks, 1, -1 do
        local taskValue = self.Tasks[index]
        self.Tasks[index] = nil
        if typeof(taskValue) == "RBXScriptConnection" then
            pcall(taskValue.Disconnect, taskValue)
        elseif typeof(taskValue) == "Instance" then
            pcall(taskValue.Destroy, taskValue)
        elseif type(taskValue) == "function" then
            pcall(taskValue)
        elseif type(taskValue) == "table" then
            local cleanup = taskValue.Destroy or taskValue.Cleanup
            if type(cleanup) == "function" then
                pcall(cleanup, taskValue)
            end
        end
    end
end

local ThemeController = {}
local AnimationController = {}
local InputController = {}
local DragController = {}
local PopupController = {}
local NotificationController = {}
local FloatingWidgetController = {}
local WindowController = {}
local NavigationController = {}
local Components = {}

function ThemeController:Bind(instance: Instance, property: string, token: string)
    table.insert(Kronos.ThemeBindings, { Instance = instance, Property = property, Token = token })
end

function ThemeController:Refresh()
    for index = #Kronos.ThemeBindings, 1, -1 do
        local binding = Kronos.ThemeBindings[index]
        local instance = binding.Instance
        if not instance or instance.Parent == nil then
            table.remove(Kronos.ThemeBindings, index)
        else
            pcall(function()
                (instance :: any)[binding.Property] = Theme[binding.Token]
            end)
        end
    end
end

function ThemeController:UnbindTree(root: Instance?)
    if not root then
        return
    end
    for index = #Kronos.ThemeBindings, 1, -1 do
        local instance = Kronos.ThemeBindings[index].Instance
        if not instance or instance == root or instance:IsDescendantOf(root) then
            table.remove(Kronos.ThemeBindings, index)
        end
    end
end

function AnimationController:Cancel(instance: Instance)
    local activeByProperty = Kronos.ActiveTweens[instance]
    if not activeByProperty then
        return
    end
    local cancelled = {}
    for _, tweenObject in pairs(activeByProperty) do
        if not cancelled[tweenObject] then
            cancelled[tweenObject] = true
            pcall(tweenObject.Cancel, tweenObject)
        end
    end
    Kronos.ActiveTweens[instance] = nil
end

function AnimationController:Tween(
    instance: Instance,
    properties: AnyTable,
    duration: number?,
    style: Enum.EasingStyle?,
    direction: Enum.EasingDirection?
): Tween?
    if Kronos.Destroyed or instance.Parent == nil then
        return nil
    end
    local activeByProperty = Kronos.ActiveTweens[instance]
    if not activeByProperty then
        activeByProperty = {}
        Kronos.ActiveTweens[instance] = activeByProperty
    end
    local conflicting = {}
    for property in pairs(properties) do
        local active = activeByProperty[property]
        if active then
            conflicting[active] = true
        end
    end
    for active in pairs(conflicting) do
        pcall(active.Cancel, active)
        for property, tweenObject in pairs(activeByProperty) do
            if tweenObject == active then
                activeByProperty[property] = nil
            end
        end
    end
    local ok, result = pcall(function()
        return TweenService:Create(
            instance,
            TweenInfo.new(
                duration or Motion.Hover,
                style or Enum.EasingStyle.Quint,
                direction or Enum.EasingDirection.Out
            ),
            properties
        )
    end)
    if not ok then
        for property, value in pairs(properties) do
            pcall(function()
                (instance :: any)[property] = value
            end)
        end
        if next(activeByProperty) == nil then
            Kronos.ActiveTweens[instance] = nil
        end
        return nil
    end
    local tweenObject = result :: Tween
    for property in pairs(properties) do
        activeByProperty[property] = tweenObject
    end
    tweenObject.Completed:Once(function()
        local current = Kronos.ActiveTweens[instance]
        if not current then
            return
        end
        for property, active in pairs(current) do
            if active == tweenObject then
                current[property] = nil
            end
        end
        if next(current) == nil then
            Kronos.ActiveTweens[instance] = nil
        end
    end)
    tweenObject:Play()
    return tweenObject
end

function InputController.Name(input: InputObject): string
    if input.KeyCode ~= Enum.KeyCode.Unknown then
        return input.KeyCode.Name
    end
    return input.UserInputType.Name
end

function InputController.Matches(input: InputObject, binding: any): boolean
    local name = typeof(binding) == "EnumItem" and binding.Name or tostring(binding)
    return InputController.Name(input) == name
end

local function resolveParent(): Instance
    local ok, result = pcall(function()
        local getProtectedGui = Environment.gethui
            or RuntimeEnvironment.gethui
            or Environment.get_hidden_ui
            or RuntimeEnvironment.get_hidden_ui
        if type(getProtectedGui) == "function" then
            return getProtectedGui()
        end
        return nil
    end)
    if ok and typeof(result) == "Instance" then
        return result
    end
    local coreOk = pcall(function()
        local probe = Instance.new("Folder")
        probe.Name = "KronosParentProbe"
        probe.Parent = CoreGui
        probe:Destroy()
    end)
    if coreOk then
        return CoreGui
    end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui and LocalPlayer then
        playerGui = LocalPlayer:WaitForChild("PlayerGui", 8) :: PlayerGui?
    end
    assert(playerGui, "No supported client GUI parent is available")
    return playerGui
end

local function safeCall(callback: any, ...: any): boolean
    if type(callback) ~= "function" then
        return true
    end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = xpcall(function()
            callback(table.unpack(args, 1, args.n))
        end, debug.traceback)
        if not ok then
            warn("[Kronos] Callback error:", err)
            if not Kronos.Destroyed and Kronos.Notify then
                Kronos:Notify({
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

local function addConnection(owner: AnyTable, connection: RBXScriptConnection?): RBXScriptConnection?
    if not connection then
        return connection
    end
    owner.Connections = owner.Connections or {}
    table.insert(owner.Connections, connection)
    return connection
end

local function disconnectAll(owner: AnyTable?)
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

local function create(className: string, props: AnyTable?, children: { Instance }?): any
    local instance = Instance.new(className)
    props = props or {}
    local requestedParent = props.Parent
    for key, value in pairs(props) do
        if key ~= "Parent" then
            (instance :: any)[key] = value
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    if requestedParent then
        instance.Parent = requestedParent
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

local function tween(
    instance: Instance?,
    properties: AnyTable,
    duration: number?,
    style: Enum.EasingStyle?,
    direction: Enum.EasingDirection?
): Tween?
    if not instance or instance.Parent == nil then
        return nil
    end
    return AnimationController:Tween(instance, properties, duration, style, direction)
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

local function finiteNumber(value: any, fallback: number): number
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return fallback
    end
    return numeric
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
    if type(name) ~= "string" then
        return Icons.Default
    end
    local resolved = IconAliases[name] or name
    if Icons[resolved] then
        return Icons[resolved]
    end
    local lowered = string.lower(resolved)
    for iconName, iconValue in pairs(Icons) do
        if string.lower(iconName) == lowered then
            return iconValue
        end
    end
    return Icons.Default
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

local function viewportSize()
    local cam = workspace.CurrentCamera
    if cam then
        return cam.ViewportSize
    end
    return Vector2.new(1920, 1080)
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

local function guiInsets(): (Vector2, Vector2)
    local ok, topLeft, bottomRight = pcall(GuiService.GetGuiInset, GuiService)
    if ok and typeof(topLeft) == "Vector2" and typeof(bottomRight) == "Vector2" then
        return topLeft, bottomRight
    end
    return Vector2.zero, Vector2.zero
end

local function clampGuiCenter(target: GuiObject, center: Vector2): Vector2
    local viewport = viewportSize()
    local topLeftInset, bottomRightInset = guiInsets()
    local size = target.AbsoluteSize
    local anchor = target.AnchorPoint
    local paddingValue = Metrics.SafePadding
    local minimum = Vector2.new(
        topLeftInset.X + paddingValue + size.X * anchor.X,
        topLeftInset.Y + paddingValue + size.Y * anchor.Y
    )
    local maximum = Vector2.new(
        viewport.X - bottomRightInset.X - paddingValue - size.X * (1 - anchor.X),
        viewport.Y - bottomRightInset.Y - paddingValue - size.Y * (1 - anchor.Y)
    )
    return Vector2.new(
        math.clamp(center.X, math.min(minimum.X, maximum.X), math.max(minimum.X, maximum.X)),
        math.clamp(center.Y, math.min(minimum.Y, maximum.Y), math.max(minimum.Y, maximum.Y))
    )
end

function DragController:Bind(owner: AnyTable, handle: GuiObject, target: GuiObject, movedCallback: ((Vector2) -> ())?)
    local active = false
    local dragTouch: InputObject? = nil
    local pointerStart = Vector2.zero
    local centerStart = Vector2.zero

    addConnection(
        owner,
        handle.InputBegan:Connect(function(input)
            if active then
                return
            end
            if
                input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch
            then
                return
            end
            active = true
            dragTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
            pointerStart = Vector2.new(input.Position.X, input.Position.Y)
            centerStart = target.AbsolutePosition + target.AbsoluteSize * target.AnchorPoint
        end)
    )
    addConnection(
        owner,
        UserInputService.InputChanged:Connect(function(input)
            if
                not active
                or not (
                    (dragTouch and input == dragTouch)
                    or (not dragTouch and input.UserInputType == Enum.UserInputType.MouseMovement)
                )
            then
                return
            end
            local pointer = Vector2.new(input.Position.X, input.Position.Y)
            local center = clampGuiCenter(target, centerStart + pointer - pointerStart)
            target.Position = UDim2.fromOffset(math.floor(center.X + 0.5), math.floor(center.Y + 0.5))
            if movedCallback then
                movedCallback(center)
            end
        end)
    )
    addConnection(
        owner,
        UserInputService.InputEnded:Connect(function(input)
            if
                active
                and (
                    (dragTouch and input == dragTouch)
                    or (not dragTouch and input.UserInputType == Enum.UserInputType.MouseButton1)
                )
            then
                active = false
                dragTouch = nil
            end
        end)
    )
end

function PopupController:Close(window: AnyTable)
    local active = window.ActivePopup
    if not active then
        if Kronos.ActivePopupWindow == window then
            Kronos.ActivePopupWindow = nil
        end
        return
    end
    window.ActivePopup = nil
    if Kronos.ActivePopupWindow == window then
        Kronos.ActivePopupWindow = nil
    end
    if active.Maid then
        active.Maid:Cleanup()
    end
    local frame = active.Frame
    if frame and frame.Parent then
        ThemeController:UnbindTree(frame)
        if frame:IsA("CanvasGroup") then
            frame.Interactable = false
            tween(frame, {
                GroupTransparency = 1,
                Position = frame.Position + UDim2.fromOffset(0, -3),
            }, Motion.PopupClose, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            task.delay(Motion.PopupClose, function()
                if frame.Parent then
                    frame:Destroy()
                end
            end)
        else
            frame:Destroy()
        end
    end
end

function PopupController:Position(
    window: AnyTable,
    popup: GuiObject,
    anchor: GuiObject,
    gap: number?,
    placement: string?
)
    local layer = window.PopupLayer or window.Overlay
    local rootPosition = layer.AbsolutePosition
    local rootSize = layer.AbsoluteSize
    local anchorPosition = anchor.AbsolutePosition - rootPosition
    local anchorSize = anchor.AbsoluteSize
    local popupSize = popup.AbsoluteSize
    local spacing = gap or 6
    local x: number
    local y: number
    if placement == "Side" then
        x = anchorPosition.X + anchorSize.X + spacing
        y = anchorPosition.Y
        if x + popupSize.X > rootSize.X - 8 then
            x = anchorPosition.X - popupSize.X - spacing
        end
    else
        x = anchorPosition.X
        y = anchorPosition.Y + anchorSize.Y + spacing
        if y + popupSize.Y > rootSize.Y - 8 then
            y = anchorPosition.Y - popupSize.Y - spacing
        end
    end
    x = math.clamp(x, 8, math.max(rootSize.X - popupSize.X - 8, 8))
    y = math.clamp(y, 8, math.max(rootSize.Y - popupSize.Y - 8, 8))
    popup.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
end

function PopupController:Open(
    window: AnyTable,
    popup: GuiObject,
    anchor: GuiObject,
    gap: number?,
    placement: string?
): AnyTable
    if Kronos.ActivePopupWindow and Kronos.ActivePopupWindow ~= window then
        self:Close(Kronos.ActivePopupWindow)
    end
    self:Close(window)
    local maid = Maid.new()
    window.ActivePopup = { Frame = popup, Maid = maid, Anchor = anchor, Gap = gap, Placement = placement }
    Kronos.ActivePopupWindow = window
    popup.Parent = window.PopupLayer or window.Overlay
    popup.Visible = true
    task.defer(function()
        if popup.Parent and window.ActivePopup and window.ActivePopup.Frame == popup then
            self:Position(window, popup, anchor, gap, placement)
        end
    end)
    maid:Give(UserInputService.InputBegan:Connect(function(input)
        if
            input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end
        if not pointInside(popup, input.Position) and not pointInside(anchor, input.Position) then
            self:Close(window)
        end
    end))
    maid:Give(popup.AncestryChanged:Connect(function(_, parent)
        if parent == nil and window.ActivePopup and window.ActivePopup.Frame == popup then
            window.ActivePopup = nil
            if Kronos.ActivePopupWindow == window then
                Kronos.ActivePopupWindow = nil
            end
            ThemeController:UnbindTree(popup)
            maid:Cleanup()
        end
    end))
    return maid
end

local function createRootGui()
    local parent = resolveParent()
    local stale = parent:FindFirstChild("KronosUI")
    if stale then
        stale:Destroy()
    end
    local gui = create("ScreenGui", {
        Name = "KronosUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999,
    })
    gui.Parent = parent
    return gui
end

local function makeToastHolder(gui)
    local holder = create("Frame", {
        Name = "ToastHolder",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 72),
        Size = UDim2.fromOffset(300, 560),
        Parent = gui,
        ZIndex = 1000,
    })
    local layout = list(holder, Enum.FillDirection.Vertical, 7, Enum.HorizontalAlignment.Right)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    return holder
end

Kronos.GUI = nil
Kronos.ToastHolder = nil

function Kronos:_ensureGui()
    if self.GUI and self.GUI.Parent then
        return self.GUI
    end
    self.GUI = createRootGui()
    self.ToastHolder = makeToastHolder(self.GUI)
    return self.GUI
end

function Kronos:_registerOption(id, option)
    if id then
        assert(self.Options[id] == nil or self.Options[id] == option, "Duplicate Kronos option id: " .. tostring(id))
        self.Options[id] = option
        self.Flags[id] = option.Value
    end
end

function Kronos:SafeCallback(callback, ...)
    return safeCall(callback, ...)
end

function Kronos:Notify(config: AnyTable?): AnyTable
    if self.Destroyed then
        return { Destroy = function() end }
    end
    config = config or {}
    local gui = self:_ensureGui()
    if not self.ToastHolder or not self.ToastHolder.Parent then
        self.ToastHolder = makeToastHolder(gui)
    end

    local duration = math.max(finiteNumber(config.Duration, 4), 0.5)
    local message = tostring(config.Content or config.Message or config.Subtitle or "")
    local height = message ~= "" and 76 or 58
    local accent = Theme.Accent
    local accentToken = "Accent"
    if config.Type == "success" then
        accent = Theme.Success
        accentToken = "Success"
    elseif config.Type == "warning" then
        accent = Theme.Warning
        accentToken = "Warning"
    elseif config.Type == "error" then
        accent = Theme.Error
        accentToken = "Error"
    end

    local slot = create("Frame", {
        Name = "NotificationSlot",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(292, height),
        LayoutOrder = -math.floor(os.clock() * 1000),
        Parent = self.ToastHolder,
        ZIndex = 1000,
    }) :: Frame
    local toast = create("CanvasGroup", {
        Name = "Notification",
        BackgroundColor3 = Theme.ElevatedSurface,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.fromOffset(292, height),
        Parent = slot,
        ZIndex = 1001,
    }) :: CanvasGroup
    ThemeController:Bind(toast, "BackgroundColor3", "ElevatedSurface")
    corner(toast, Metrics.PopupRadius)
    stroke(toast, Theme.Border, 0.42, 1)

    local accentBar = create("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(3, height - 16),
        Position = UDim2.fromOffset(0, 8),
        Parent = toast,
        ZIndex = 1002,
    }) :: Frame
    corner(accentBar, 2)
    ThemeController:Bind(accentBar, "BackgroundColor3", accentToken)

    local icon = makeText(
        toast,
        getIcon(config.Icon or (config.Type == "success" and "CheckCircle" or "Info")),
        14,
        accent,
        "bold"
    )
    icon.Position = UDim2.fromOffset(13, 11)
    icon.Size = UDim2.fromOffset(22, 22)
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.ZIndex = 1002
    ThemeController:Bind(icon, "TextColor3", accentToken)

    local title = makeText(toast, tostring(config.Title or "Kronos"), 12, Theme.Text, "bold")
    title.Position = UDim2.fromOffset(40, 8)
    title.Size = UDim2.new(1, -50, 0, 22)
    title.ZIndex = 1002

    if message ~= "" then
        local content = makeText(toast, message, 11, Theme.SubText)
        content.Position = UDim2.fromOffset(40, 29)
        content.Size = UDim2.new(1, -50, 0, 31)
        content.TextWrapped = true
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.ZIndex = 1002
    end

    local progress = create("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 9, 1, -5),
        Size = UDim2.new(1, -18, 0, 2),
        Parent = toast,
        ZIndex = 1002,
    }) :: Frame
    corner(progress, 1)
    ThemeController:Bind(progress, "BackgroundColor3", accentToken)

    table.insert(self.Notifications, toast)
    local dismissed = false
    local handle: AnyTable = {}
    function handle:Destroy()
        if dismissed then
            return
        end
        dismissed = true
        if toast.Parent then
            ThemeController:UnbindTree(slot)
            tween(
                toast,
                { GroupTransparency = 1, Position = UDim2.fromOffset(18, 0) },
                Motion.Notification,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.In
            )
            task.delay(Motion.Notification, function()
                if slot.Parent then
                    slot:Destroy()
                end
            end)
        end
        local index = table.find(Kronos.Notifications, toast)
        if index then
            table.remove(Kronos.Notifications, index)
        end
    end

    tween(toast, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, Motion.Notification)
    tween(progress, { Size = UDim2.fromOffset(0, 2) }, duration, Enum.EasingStyle.Linear)
    task.delay(duration, function()
        handle:Destroy()
    end)
    return handle
end

function NotificationController:Push(config: AnyTable?): AnyTable
    return Kronos:Notify(config)
end

local function dismissTooltip(window: AnyTable?, root: Instance?)
    if not window then
        return
    end
    local anchor = window.ActiveTooltipAnchor
    if root and anchor and anchor ~= root and not anchor:IsDescendantOf(root) then
        return
    end
    if root and not anchor then
        return
    end
    if window.ActiveTooltip and window.ActiveTooltip.Parent then
        window.ActiveTooltip:Destroy()
    end
    window.ActiveTooltip = nil
    window.ActiveTooltipAnchor = nil
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local BaseControl = {}
BaseControl.__index = BaseControl

function BaseControl:_closeTransient()
    if self.Instance then
        dismissTooltip(self.Window, self.Instance)
    end
    if self.Window and self.Window.ListeningKeybind == self then
        if type(self.CancelListening) == "function" then
            self:CancelListening()
        else
            self.Window.ListeningKeybind = nil
        end
    end
    if self.Window and self.Window.ActivePopup and self.Instance then
        local anchor = self.Window.ActivePopup.Anchor
        if anchor == self.Instance or (anchor and anchor:IsDescendantOf(self.Instance)) then
            PopupController:Close(self.Window)
        end
    end
end

function BaseControl:SetVisible(visible: boolean): AnyTable
    self.ManualVisible = visible ~= false
    if not self.ManualVisible then
        self:_closeTransient()
    end
    if self.Instance then
        self.Instance.Visible = self.ManualVisible and self.SearchVisible ~= false
    end
    return self
end

function BaseControl:SetDisabled(disabled: boolean): AnyTable
    self.Disabled = disabled == true
    if self.Disabled then
        self:_closeTransient()
    end
    if self.Instance then
        self.Instance:SetAttribute("KronosDisabled", self.Disabled)
        for _, descendant in ipairs(self.Instance:GetDescendants()) do
            if descendant:IsA("GuiButton") or descendant:IsA("TextBox") then
                descendant.Interactable = not self.Disabled
            end
            if descendant:IsA("TextLabel") then
                descendant.TextTransparency = self.Disabled and 0.46 or 0
            end
        end
        if self.Instance:IsA("Frame") then
            self.Instance.BackgroundTransparency = self.Disabled and 0.78
                or (self.BaseTransparency or self.Instance.BackgroundTransparency)
        end
    end
    if type(self.RefreshView) == "function" then
        self:RefreshView()
    end
    return self
end

function BaseControl:Destroy()
    self:_closeTransient()
    disconnectAll(self)
    if self.Window and self.Window.Keybinds then
        local windowIndex = table.find(self.Window.Keybinds, self)
        if windowIndex then
            table.remove(self.Window.Keybinds, windowIndex)
        end
    end
    local keybindIndex = table.find(Kronos.Keybinds, self)
    if keybindIndex then
        table.remove(Kronos.Keybinds, keybindIndex)
    end
    if self.Section and self.Section.Controls then
        local controlIndex = table.find(self.Section.Controls, self)
        if controlIndex then
            table.remove(self.Section.Controls, controlIndex)
        end
    end
    if self.Instance then
        ThemeController:UnbindTree(self.Instance)
        self.Instance:Destroy()
        self.Instance = nil
    end
    if self.Id and Kronos.Options[self.Id] == self then
        Kronos.Options[self.Id] = nil
        Kronos.Flags[self.Id] = nil
    end
    if self.Window and not self.Window.Destroyed and self.Window.KeybindWidget then
        self.Window.KeybindWidget:Refresh()
    end
end

function BaseControl:Get(): any
    return self.Value
end

function BaseControl:Set(value: any): AnyTable
    if type(self.SetValue) == "function" then
        self:SetValue(value)
    else
        self:_fire(value)
    end
    return self
end

function BaseControl:SetText(text: string): AnyTable
    self.Text = tostring(text)
    if self.Instance then
        self.Instance:SetAttribute("KronosSearch", string.lower(self.Text))
    end
    if self.TitleLabel then
        self.TitleLabel.Text = self.Text
    elseif self.Instance then
        local label = self.Instance:FindFirstChild("ControlTitle", true)
        if label and label:IsA("TextLabel") then
            label.Text = self.Text
        end
    end
    return self
end

function BaseControl:SetOptions(options: { any }): AnyTable
    if type(self.SetValues) == "function" then
        self:SetValues(options)
    end
    return self
end

function BaseControl:Refresh(options: { any }?): AnyTable
    if options then
        self:SetOptions(options)
    elseif type(self.RefreshView) == "function" then
        self:RefreshView()
    end
    return self
end

function BaseControl:OnChanged(callback)
    self.ChangedCallbacks = self.ChangedCallbacks or {}
    table.insert(self.ChangedCallbacks, callback)
    return self
end

function BaseControl:_fire(value)
    self.Value = value
    if self.Id then
        Kronos.Flags[self.Id] = value
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
    local rowOwner: AnyTable = { Connections = {} }
    local rowHeight = height or (description and 48 or Metrics.Row)
    local row = create("Frame", {
        Name = "ControlRow",
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.54,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, rowHeight),
        ClipsDescendants = true,
        Parent = section.Content,
    })
    row:SetAttribute("KronosSearch", string.lower(tostring(titleText or "") .. " " .. tostring(description or "")))
    corner(row, 5)
    local rowStroke = stroke(row, Theme.StrokeSoft, 0.78, 1)
    ThemeController:Bind(row, "BackgroundColor3", "Surface2")
    ThemeController:Bind(rowStroke, "Color", "StrokeSoft")

    local title = makeText(row, titleText or "Control", 11, Theme.Text, "bold")
    title.Name = "ControlTitle"
    title.Position = UDim2.fromOffset(11, description and 5 or 0)
    title.Size = UDim2.new(0.56, -14, 0, 18)
    if not description then
        title.AnchorPoint = Vector2.new(0, 0.5)
        title.Position = UDim2.new(0, 11, 0.5, 0)
        title.Size = UDim2.new(0.56, -14, 0, 18)
    end

    local descLabel
    if description then
        descLabel = makeText(row, description, 9, Theme.Muted)
        descLabel.Position = UDim2.fromOffset(11, 24)
        descLabel.Size = UDim2.new(0.61, -16, 0, 15)
    end

    local holder = create("Frame", {
        Name = "ControlHolder",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0.43, -6, 1, -8),
        Parent = row,
    })

    local hover = makeHitbox(row)
    hover.ZIndex = 0
    addConnection(
        rowOwner,
        hover.MouseEnter:Connect(function()
            if not row:GetAttribute("KronosDisabled") then
                tween(row, { BackgroundTransparency = 0.34 }, Motion.Hover)
            end
        end)
    )
    addConnection(
        rowOwner,
        hover.MouseLeave:Connect(function()
            tween(row, { BackgroundTransparency = 0.54 }, Motion.Hover)
        end)
    )

    section.RowConnectionOwners = section.RowConnectionOwners or {}
    section.RowConnectionOwners[row] = rowOwner

    return row, holder, title, descLabel, hover
end

function Section:_control(id, object)
    object.Id = id
    object.Section = self
    object.Window = self.Window
    object.TitleLabel = object.TitleLabel or (object.Instance and object.Instance:FindFirstChild("ControlTitle", true))
    object.BaseTransparency = object.Instance and object.Instance.BackgroundTransparency or 0.54
    object.ManualVisible = true
    object.SearchVisible = true
    if object.Instance and self.RowConnectionOwners then
        local rowOwner = self.RowConnectionOwners[object.Instance]
        if rowOwner then
            object.Connections = object.Connections or {}
            for _, connection in ipairs(rowOwner.Connections) do
                table.insert(object.Connections, connection)
            end
            self.RowConnectionOwners[object.Instance] = nil
        end
    end
    if id and Kronos.Options[id] and Kronos.Options[id] ~= object then
        object:Destroy()
        error("Duplicate Kronos option id: " .. tostring(id), 2)
    end
    table.insert(self.Controls, object)
    if id then
        Kronos:_registerOption(id, object)
    end
    return object
end

function Section:CreateToggle(id: any, config: AnyTable?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local row, holder, titleLabel, _, hitbox = makeControlRow(self, config.Title or id or "Toggle", config.Description)
    local toggle = setmetatable({
        Value = config.Default == true,
        Callback = config.Callback,
        ChangedCallbacks = {},
        Instance = row,
        TitleLabel = titleLabel,
        Disabled = false,
    }, BaseControl)

    local box = create("TextButton", {
        BackgroundColor3 = toggle.Value and Theme.Accent or Theme.Surface3,
        BackgroundTransparency = toggle.Value and 0 or 0.16,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -2, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        Parent = holder,
        ZIndex = 6,
    }) :: TextButton
    corner(box, 4)
    local boxStroke = stroke(box, toggle.Value and Theme.Accent or Theme.Stroke, toggle.Value and 0.08 or 0.5, 1)
    local check = makeText(box, toggle.Value and "✓" or "", 12, Theme.White, "bold")
    check.Size = UDim2.fromScale(1, 1)
    check.TextXAlignment = Enum.TextXAlignment.Center
    check.ZIndex = 7

    local function render(value: boolean, instant: boolean?)
        local duration = instant and 0 or Motion.Toggle
        AnimationController:Tween(box, {
            BackgroundColor3 = value and Theme.Accent or Theme.Surface3,
            BackgroundTransparency = value and 0 or 0.16,
        }, duration)
        AnimationController:Tween(boxStroke, {
            Color = value and Theme.Accent or Theme.Stroke,
            Transparency = value and 0.08 or 0.5,
        }, duration)
        check.Text = value and "✓" or ""
        check.TextTransparency = value and 1 or 0
        if value then
            AnimationController:Tween(check, { TextTransparency = 0 }, duration)
        end
        titleLabel.TextColor3 = value and Theme.Text or Theme.SubText
    end

    toggle.RefreshView = function()
        render(toggle.Value, true)
    end

    function toggle:AddDependency(control: AnyTable, inverted: boolean?): AnyTable
        self.Dependents = self.Dependents or {}
        table.insert(self.Dependents, { Control = control, Inverted = inverted == true, Generation = 0 })
        local dependency = self.Dependents[#self.Dependents]
        local function applyDependency(value: boolean, instant: boolean?)
            dependency.Generation += 1
            local generation = dependency.Generation
            local visible = dependency.Inverted and not value or value
            local instance = control.Instance
            if not instance then
                return
            end
            if visible then
                control:SetVisible(true)
                if not instant then
                    for _, descendant in ipairs(instance:GetDescendants()) do
                        if descendant:IsA("TextLabel") then
                            descendant.TextTransparency = 1
                            tween(descendant, { TextTransparency = control.Disabled and 0.46 or 0 }, Motion.Toggle)
                        end
                    end
                end
            elseif instant then
                control:SetVisible(false)
            else
                for _, descendant in ipairs(instance:GetDescendants()) do
                    if descendant:IsA("TextLabel") then
                        tween(descendant, { TextTransparency = 1 }, Motion.Toggle)
                    end
                end
                task.delay(Motion.Toggle, function()
                    if dependency.Generation == generation then
                        control:SetVisible(false)
                    end
                end)
            end
        end
        applyDependency(self.Value, true)
        self:OnChanged(function(value)
            applyDependency(value, false)
        end)
        return control
    end

    function toggle:SetValue(value: any)
        local nextValue = value == true
        if self.Value == nextValue then
            return self
        end
        self.Value = nextValue
        render(nextValue)
        self:_fire(nextValue)
        return self
    end

    local function clicked()
        if not toggle.Disabled then
            toggle:SetValue(not toggle.Value)
        end
    end
    hitbox.ZIndex = 5
    addConnection(toggle, hitbox.Activated:Connect(clicked))
    addConnection(toggle, box.Activated:Connect(clicked))
    render(toggle.Value, true)
    local result = self:_control(id, toggle)
    if config.Disabled then
        result:SetDisabled(true)
    end
    return result
end

function Section:CreateSlider(id: any, config: AnyTable?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local minimum = finiteNumber(config.Min, 0)
    local maximum = finiteNumber(config.Max, 100)
    if maximum < minimum then
        minimum, maximum = maximum, minimum
    end
    local precision = math.floor(math.clamp(finiteNumber(config.Precision, finiteNumber(config.Rounding, 0)), 0, 6))
    local step = math.max(finiteNumber(config.Step, 10 ^ -precision), 10 ^ -precision)
    local default = math.clamp(finiteNumber(config.Default, minimum), minimum, maximum)
    local suffix = tostring(config.Suffix or "")
    local row, holder, titleLabel =
        makeControlRow(self, config.Title or id or "Slider", config.Description, config.Description and 50 or 42)
    holder.Size = UDim2.new(0.45, -6, 1, -8)

    local slider = setmetatable({
        Value = default,
        Callback = config.Callback,
        ChangedCallbacks = {},
        Instance = row,
        TitleLabel = titleLabel,
        Disabled = false,
    }, BaseControl)
    local valueLabel = makeText(holder, "", 10, Theme.SubText, "bold")
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, 0, 0, -1)
    valueLabel.Size = UDim2.fromOffset(70, 14)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local track = create("Frame", {
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, -4),
        Size = UDim2.new(1, 0, 0, 3),
        Parent = holder,
    }) :: Frame
    corner(track, 2)
    local fill = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = track,
    }) :: Frame
    corner(fill, 2)
    ThemeController:Bind(fill, "BackgroundColor3", "Accent")
    local knob = create("Frame", {
        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(9, 9),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Parent = track,
        ZIndex = 3,
    }) :: Frame
    corner(knob, 5)

    local dragging = false
    local dragTouch: InputObject? = nil
    local function normalized(value: number): number
        if maximum == minimum then
            return 0
        end
        return (value - minimum) / (maximum - minimum)
    end
    local function quantize(value: number): number
        local snapped = minimum + math.floor(((value - minimum) / step) + 0.5) * step
        return math.clamp(snapped, minimum, maximum)
    end
    local function render(value: number, immediate: boolean?)
        local ratio = normalized(value)
        valueLabel.Text = formatNumber(value, precision) .. suffix
        if immediate then
            fill.Size = UDim2.fromScale(ratio, 1)
            knob.Position = UDim2.fromScale(ratio, 0.5)
        else
            tween(fill, { Size = UDim2.fromScale(ratio, 1) }, Motion.Slider)
            tween(knob, { Position = UDim2.fromScale(ratio, 0.5) }, Motion.Slider)
        end
    end
    slider.RefreshView = function()
        fill.BackgroundColor3 = Theme.Accent
        render(slider.Value, true)
    end
    function slider:SetValue(value: any)
        local nextValue = quantize(finiteNumber(value, minimum))
        if math.abs(nextValue - self.Value) < 1e-7 then
            return self
        end
        self.Value = nextValue
        render(nextValue, dragging)
        self:_fire(nextValue)
        return self
    end

    local hit = makeHitbox(holder)
    hit.Name = "SliderHitbox"
    hit.Selectable = true
    hit.ZIndex = 4
    local function update(input: InputObject)
        if slider.Disabled or track.AbsoluteSize.X <= 0 then
            return
        end
        local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        slider:SetValue(minimum + (maximum - minimum) * ratio)
    end
    addConnection(
        slider,
        hit.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                dragging = true
                dragTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
                update(input)
                tween(knob, { Size = UDim2.fromOffset(12, 12) }, Motion.Press)
            end
        end)
    )
    addConnection(
        slider,
        UserInputService.InputChanged:Connect(function(input)
            if
                dragging
                and (
                    (dragTouch and input == dragTouch)
                    or (not dragTouch and input.UserInputType == Enum.UserInputType.MouseMovement)
                )
            then
                update(input)
            end
        end)
    )
    addConnection(
        slider,
        UserInputService.InputEnded:Connect(function(input)
            if
                dragging
                and (
                    (dragTouch and input == dragTouch)
                    or (not dragTouch and input.UserInputType == Enum.UserInputType.MouseButton1)
                )
            then
                dragging = false
                dragTouch = nil
                tween(knob, { Size = UDim2.fromOffset(9, 9) }, Motion.Press)
            end
        end)
    )
    addConnection(
        slider,
        UserInputService.InputBegan:Connect(function(input, processed)
            if processed or slider.Disabled or GuiService.SelectedObject ~= hit then
                return
            end
            if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Down then
                slider:SetValue(slider.Value - step)
            elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.Up then
                slider:SetValue(slider.Value + step)
            end
        end)
    )

    slider.Value = quantize(default)
    render(slider.Value, true)
    local result = self:_control(id, slider)
    if config.Disabled then
        result:SetDisabled(true)
    end
    return result
end
function Section:CreateInput(id: any, config: AnyTable?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local row, holder, titleLabel = makeControlRow(self, config.Title or id or "Input", config.Description)
    local input = setmetatable({
        Value = tostring(config.Default or ""),
        Callback = config.Callback,
        ChangedCallbacks = {},
        Instance = row,
        TitleLabel = titleLabel,
        Disabled = false,
        Valid = true,
    }, BaseControl)
    local box = create("TextBox", {
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        ClearTextOnFocus = config.ClearOnFocus == true,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = Theme.Text,
        PlaceholderText = tostring(config.Placeholder or "Type..."),
        PlaceholderColor3 = Theme.Muted,
        Text = input.Value,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClipsDescendants = true,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 28),
        Parent = holder,
    }) :: TextBox
    corner(box, 5)
    local boxStroke = stroke(box, Theme.Stroke, 0.56, 1)
    padding(box, 9, 0, 9, 0)

    local changing = false
    local maximumLength = math.floor(math.clamp(finiteNumber(config.MaxLength, 1024), 0, 16384))
    local function validate(text: string): (boolean, string?)
        if config.NumericOnly and text ~= "" and tonumber(text) == nil then
            return false, "Enter a number"
        end
        if type(config.Validate) == "function" then
            local ok, valid, message = pcall(config.Validate, text)
            if not ok then
                return false, tostring(valid)
            end
            if valid == false then
                return false, tostring(message or "Invalid value")
            end
        end
        return true, nil
    end
    function input:SetError(message: string?): AnyTable
        self.Error = message
        self.Valid = message == nil
        tween(boxStroke, {
            Color = message and Theme.Error or Theme.Stroke,
            Transparency = message and 0.08 or 0.56,
        }, Motion.Hover)
        return self
    end
    input.RefreshView = function()
        box.BackgroundColor3 = Theme.Surface3
        box.TextColor3 = Theme.Text
        if input.Error then
            boxStroke.Color = Theme.Error
            boxStroke.Transparency = 0.08
        elseif box:IsFocused() then
            boxStroke.Color = Theme.Accent
            boxStroke.Transparency = 0.18
        else
            boxStroke.Color = Theme.Border
            boxStroke.Transparency = 0.56
        end
    end
    local function commit(text: string, fire: boolean)
        local valid, message = validate(text)
        input:SetError(valid and nil or message)
        if not valid then
            safeCall(config.OnInvalid, text, message)
            return false
        end
        input.Value = text
        if fire then
            input:_fire(text)
        end
        return true
    end
    function input:SetValue(value: any)
        local text = tostring(value or "")
        if #text > maximumLength then
            text = string.sub(text, 1, maximumLength)
        end
        if not commit(text, true) then
            return self
        end
        changing = true
        box.Text = text
        changing = false
        return self
    end

    addConnection(
        input,
        box.Focused:Connect(function()
            tween(boxStroke, { Color = Theme.Accent, Transparency = 0.18 }, Motion.Hover)
            tween(box, { BackgroundTransparency = 0.04 }, Motion.Hover)
            if type(self.Window.EnsureVisible) == "function" then
                self.Window:EnsureVisible(row)
            end
        end)
    )
    addConnection(
        input,
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if changing then
                return
            end
            local text = box.Text
            if #text > maximumLength then
                text = string.sub(text, 1, maximumLength)
                changing = true
                box.Text = text
                box.CursorPosition = #text + 1
                changing = false
            end
            if config.Live == true then
                commit(text, true)
            end
        end)
    )
    addConnection(
        input,
        box.FocusLost:Connect(function(enterPressed)
            tween(box, { BackgroundTransparency = 0.12 }, Motion.Hover)
            local accepted = commit(box.Text, config.Live ~= true)
            if accepted then
                tween(boxStroke, { Color = Theme.Stroke, Transparency = 0.56 }, Motion.Hover)
                safeCall(config.OnFocusLost, box.Text, enterPressed)
                if enterPressed and config.SubmitOnEnter ~= false then
                    safeCall(config.OnSubmit, box.Text)
                end
            end
        end)
    )

    local result = self:_control(id, input)
    if config.Disabled then
        result:SetDisabled(true)
    end
    return result
end
function Section:_closeDropdowns()
    PopupController:Close(self.Window)
end

local function arrayContains(values: { any }, target: any): boolean
    return table.find(values, target) ~= nil
end

local function copyArray(values: { any }?): { any }
    local result = {}
    if type(values) == "table" then
        for _, value in ipairs(values) do
            table.insert(result, value)
        end
    end
    return result
end

local function removeArrayValue(values: { any }, target: any)
    local index = table.find(values, target)
    if index then
        table.remove(values, index)
    end
end

local function attachTooltip(window: AnyTable, target: GuiObject, value: any, owner: AnyTable?)
    if
        type(value) ~= "string"
        or value == ""
        or UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    then
        return
    end
    local connectionOwner = owner or window
    local generation = 0
    addConnection(
        connectionOwner,
        target.MouseEnter:Connect(function()
            generation += 1
            local current = generation
            task.delay(0.45, function()
                if current ~= generation or not target.Parent or not window.Visible then
                    return
                end
                dismissTooltip(window)
                local measured = TextService:GetTextSize(value, 10, Enum.Font.GothamMedium, Vector2.new(260, 100))
                local tip = create("TextLabel", {
                    Name = "Tooltip",
                    BackgroundColor3 = Theme.ElevatedSurface,
                    BackgroundTransparency = 0.04,
                    BorderSizePixel = 0,
                    Text = value,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 10,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Size = UDim2.fromOffset(math.min(measured.X + 18, 278), measured.Y + 12),
                    ZIndex = 930,
                    Parent = window.PopupLayer,
                }) :: TextLabel
                corner(tip, Metrics.PopupRadius)
                stroke(tip, Theme.Border, 0.38, 1)
                padding(tip, 9, 5, 9, 5)
                local mouse = UserInputService:GetMouseLocation()
                local viewport = viewportSize()
                local width = tip.AbsoluteSize.X
                local height = tip.AbsoluteSize.Y
                tip.Position = UDim2.fromOffset(
                    math.clamp(mouse.X + 12, 8, viewport.X - width - 8),
                    math.clamp(mouse.Y + 14, 8, viewport.Y - height - 8)
                )
                tip.TextTransparency = 1
                tip.BackgroundTransparency = 1
                tween(tip, { TextTransparency = 0, BackgroundTransparency = 0.04 }, Motion.Tooltip)
                window.ActiveTooltip = tip
                window.ActiveTooltipAnchor = target
            end)
        end)
    )
    addConnection(
        connectionOwner,
        target.MouseLeave:Connect(function()
            generation += 1
            dismissTooltip(window, target)
        end)
    )
end

function Section:CreateDropdown(id: any, config: AnyTable?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local options = copyArray(config.Values or config.Options or {})
    local multi = config.Multi == true
    local configuredMaximum = config.MaxSelections or config.MaximumSelections
    local maximumSelections = configuredMaximum == nil and math.huge
        or math.max(math.floor(finiteNumber(configuredMaximum, #options)), 0)
    local initial = config.Default
    if multi then
        local selected = {}
        if type(initial) == "table" then
            for _, candidate in ipairs(initial) do
                if
                    arrayContains(options, candidate)
                    and not arrayContains(selected, candidate)
                    and #selected < maximumSelections
                then
                    table.insert(selected, candidate)
                end
            end
        end
        initial = selected
    elseif initial == nil then
        initial = options[1]
    elseif not arrayContains(options, initial) then
        initial = options[1]
    end

    local row, holder, titleLabel = makeControlRow(self, config.Title or id or "Dropdown", config.Description)
    local dropdown = setmetatable({
        Value = initial,
        Values = options,
        Multi = multi,
        Callback = config.Callback,
        ChangedCallbacks = {},
        Instance = row,
        TitleLabel = titleLabel,
        Disabled = false,
    }, BaseControl)

    local button = create("TextButton", {
        Name = "DropdownButton",
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 28),
        Parent = holder,
        ZIndex = 6,
    }) :: TextButton
    corner(button, 5)
    local buttonStroke = stroke(button, Theme.Border, 0.58, 1)
    local label = makeText(button, "", 10, Theme.SubText, "bold")
    label.Position = UDim2.fromOffset(9, 0)
    label.Size = UDim2.new(1, -29, 1, 0)
    label.ZIndex = 7
    local arrow = makeText(button, getIcon("ChevronDown"), 11, Theme.Muted, "bold")
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -7, 0.5, 0)
    arrow.Size = UDim2.fromOffset(14, 18)
    arrow.TextXAlignment = Enum.TextXAlignment.Center
    arrow.ZIndex = 7

    local function displayValue(): string
        if multi then
            local selected = dropdown.Value :: { any }
            if #selected == 0 then
                return tostring(config.Placeholder or "Select...")
            end
            if #selected > 2 then
                return tostring(selected[1]) .. ", " .. tostring(selected[2]) .. "  +" .. tostring(#selected - 2)
            end
            local result = {}
            for _, value in ipairs(selected) do
                table.insert(result, tostring(value))
            end
            return table.concat(result, ", ")
        end
        return dropdown.Value ~= nil and tostring(dropdown.Value) or tostring(config.Placeholder or "Select...")
    end

    local function render()
        label.Text = displayValue()
        button.BackgroundColor3 = dropdown.Disabled and Theme.Surface2 or Theme.Surface3
        label.TextColor3 = dropdown.Disabled and Theme.DisabledText or Theme.SubText
    end

    function dropdown:SetValue(value: any): AnyTable
        if self.Multi then
            local selected = {}
            if type(value) == "table" then
                for _, candidate in ipairs(value) do
                    if
                        arrayContains(self.Values, candidate)
                        and not arrayContains(selected, candidate)
                        and #selected < maximumSelections
                    then
                        table.insert(selected, candidate)
                    end
                end
            end
            self.Value = selected
        else
            self.Value = value
        end
        render()
        self:_fire(self.Value)
        return self
    end

    function dropdown:SetValues(newOptions: { any }?): AnyTable
        self.Values = copyArray(newOptions or {})
        options = self.Values
        if self.Multi then
            self:SetValue(self.Value)
        elseif self.Value ~= nil and not arrayContains(options, self.Value) then
            self:SetValue(options[1])
        else
            render()
        end
        return self
    end

    dropdown.RefreshView = render

    local function openMenu()
        if dropdown.Disabled then
            return
        end
        if self.Window.ActivePopup and self.Window.ActivePopup.Anchor == button then
            PopupController:Close(self.Window)
            return
        end

        local searchable = config.Search == true or #options > 8
        local visibleRows = math.clamp(#options, 1, 7)
        local popupHeight = visibleRows * 28 + math.max(visibleRows - 1, 0) * 3 + 14 + (searchable and 36 or 0)
        popupHeight = math.clamp(popupHeight, 52, searchable and 266 or 226)
        local popup = create("CanvasGroup", {
            Name = "DropdownPopup",
            BackgroundColor3 = Theme.ElevatedSurface,
            BackgroundTransparency = 0.03,
            BorderSizePixel = 0,
            GroupTransparency = 1,
            Size = UDim2.fromOffset(math.max(button.AbsoluteSize.X, 208), popupHeight),
            Visible = false,
            ZIndex = 700,
        }) :: CanvasGroup
        corner(popup, Metrics.PopupRadius)
        stroke(popup, Theme.Border, 0.28, 1)
        padding(popup, 7, 7, 7, 7)
        local popupMaid = PopupController:Open(self.Window, popup, button, 5)
        popupMaid:Give(function()
            if arrow.Parent then
                tween(arrow, { Rotation = 0, TextColor3 = Theme.Muted }, Motion.PopupClose)
            end
        end)
        local optionConnections = {} :: { RBXScriptConnection }
        popupMaid:Give(function()
            for _, connection in ipairs(optionConnections) do
                connection:Disconnect()
            end
            table.clear(optionConnections)
        end)

        local searchBox: TextBox? = nil
        local topOffset = 0
        if searchable then
            searchBox = create("TextBox", {
                Name = "Search",
                BackgroundColor3 = Theme.Surface3,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                Text = "",
                PlaceholderText = "Search options",
                PlaceholderColor3 = Theme.Muted,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamMedium,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 29),
                ZIndex = 702,
                Parent = popup,
            }) :: TextBox
            corner(searchBox, 5)
            stroke(searchBox, Theme.Border, 0.56, 1)
            padding(searchBox, 8, 0, 8, 0)
            topOffset = 35
        end

        local scroll = create("ScrollingFrame", {
            Name = "Options",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, topOffset),
            Size = UDim2.new(1, 0, 1, -topOffset),
            CanvasSize = UDim2.fromOffset(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Accent,
            ScrollBarImageTransparency = 0.12,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ZIndex = 702,
            Parent = popup,
        }) :: ScrollingFrame
        ThemeController:Bind(scroll, "ScrollBarImageColor3", "Accent")
        local listFrame = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 703,
            Parent = scroll,
        }) :: Frame
        local optionLayout = list(listFrame, Enum.FillDirection.Vertical, 3)
        popupMaid:Give(optionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.fromOffset(0, optionLayout.AbsoluteContentSize.Y)
        end))
        local empty = makeText(scroll, "No options found", 10, Theme.Muted)
        empty.Size = UDim2.new(1, -8, 0, 34)
        empty.TextXAlignment = Enum.TextXAlignment.Center
        empty.Visible = false
        empty.ZIndex = 704

        local function clearOptionConnections()
            for _, connection in ipairs(optionConnections) do
                connection:Disconnect()
            end
            table.clear(optionConnections)
        end

        local rebuild: (string?) -> ()
        rebuild = function(filter: string?)
            clearOptionConnections()
            for _, child in ipairs(listFrame:GetChildren()) do
                if child:IsA("GuiButton") then
                    ThemeController:UnbindTree(child)
                    child:Destroy()
                end
            end
            local query = string.lower(filter or "")
            local shown = 0
            for _, option in ipairs(options) do
                local optionText = tostring(option)
                if query == "" or string.find(string.lower(optionText), query, 1, true) then
                    shown += 1
                    local selected = dropdown.Multi and arrayContains(dropdown.Value, option)
                        or dropdown.Value == option
                    local item = create("TextButton", {
                        BackgroundColor3 = selected and Theme.PressedSurface or Theme.Surface2,
                        BackgroundTransparency = selected and 0.05 or 0.44,
                        BorderSizePixel = 0,
                        Text = "",
                        AutoButtonColor = false,
                        Size = UDim2.new(1, 0, 0, 28),
                        ZIndex = 704,
                        Parent = listFrame,
                    }) :: TextButton
                    corner(item, 5)
                    local indicator = create("Frame", {
                        BackgroundColor3 = Theme.Accent,
                        BackgroundTransparency = selected and 0 or 1,
                        BorderSizePixel = 0,
                        Position = UDim2.fromOffset(0, 6),
                        Size = UDim2.fromOffset(2, 16),
                        ZIndex = 705,
                        Parent = item,
                    }) :: Frame
                    ThemeController:Bind(indicator, "BackgroundColor3", "Accent")
                    local optionLabel = makeText(
                        item,
                        optionText,
                        10,
                        selected and Theme.Text or Theme.SubText,
                        selected and "bold" or nil
                    )
                    optionLabel.Position = UDim2.fromOffset(9, 0)
                    optionLabel.Size = UDim2.new(1, dropdown.Multi and -32 or -16, 1, 0)
                    optionLabel.ZIndex = 705
                    if dropdown.Multi then
                        local checkBox = create("Frame", {
                            BackgroundColor3 = selected and Theme.Accent or Theme.Surface3,
                            BackgroundTransparency = selected and 0 or 0.18,
                            BorderSizePixel = 0,
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, -7, 0.5, 0),
                            Size = UDim2.fromOffset(14, 14),
                            ZIndex = 705,
                            Parent = item,
                        }) :: Frame
                        corner(checkBox, 3)
                        local checkStroke =
                            stroke(checkBox, selected and Theme.Accent or Theme.Border, selected and 0.1 or 0.48, 1)
                        if selected then
                            ThemeController:Bind(checkBox, "BackgroundColor3", "Accent")
                            ThemeController:Bind(checkStroke, "Color", "Accent")
                        end
                        local check = makeText(checkBox, selected and "✓" or "", 9, Theme.White, "bold")
                        check.Size = UDim2.fromScale(1, 1)
                        check.TextXAlignment = Enum.TextXAlignment.Center
                        check.ZIndex = 706
                    end
                    table.insert(
                        optionConnections,
                        item.MouseEnter:Connect(function()
                            tween(item, { BackgroundTransparency = selected and 0.02 or 0.22 }, Motion.Hover)
                        end)
                    )
                    table.insert(
                        optionConnections,
                        item.MouseLeave:Connect(function()
                            tween(item, { BackgroundTransparency = selected and 0.05 or 0.44 }, Motion.Hover)
                        end)
                    )
                    table.insert(
                        optionConnections,
                        item.Activated:Connect(function()
                            if dropdown.Multi then
                                local selectedValues = copyArray(dropdown.Value)
                                if arrayContains(selectedValues, option) then
                                    removeArrayValue(selectedValues, option)
                                elseif #selectedValues >= maximumSelections then
                                    NotificationController:Push({
                                        Title = "Selection limit",
                                        Content = "Choose up to " .. tostring(maximumSelections) .. " options.",
                                        Type = "warning",
                                        Duration = 2.4,
                                    })
                                    return
                                else
                                    table.insert(selectedValues, option)
                                end
                                dropdown:SetValue(selectedValues)
                                rebuild(searchBox and searchBox.Text or "")
                            else
                                dropdown:SetValue(option)
                                PopupController:Close(self.Window)
                            end
                        end)
                    )
                end
            end
            empty.Visible = shown == 0
        end

        rebuild("")
        if searchBox then
            popupMaid:Give(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                rebuild(searchBox.Text)
            end))
            task.defer(function()
                if searchBox and searchBox.Parent and config.FocusSearch == true then
                    searchBox:CaptureFocus()
                end
            end)
        end
        task.defer(function()
            if popup.Parent and self.Window.ActivePopup and self.Window.ActivePopup.Frame == popup then
                local resting = popup.Position
                popup.Position = resting + UDim2.fromOffset(0, -4)
                tween(popup, { GroupTransparency = 0, Position = resting }, Motion.Dropdown)
                tween(arrow, { Rotation = 180, TextColor3 = Theme.Accent }, Motion.Dropdown)
            end
        end)
    end

    addConnection(
        dropdown,
        button.MouseEnter:Connect(function()
            if not dropdown.Disabled then
                tween(button, { BackgroundTransparency = 0.02 }, Motion.Hover)
                tween(buttonStroke, { Color = Theme.Accent, Transparency = 0.42 }, Motion.Hover)
            end
        end)
    )
    addConnection(
        dropdown,
        button.MouseLeave:Connect(function()
            tween(button, { BackgroundTransparency = 0.12 }, Motion.Hover)
            tween(buttonStroke, { Color = Theme.Border, Transparency = 0.58 }, Motion.Hover)
        end)
    )
    addConnection(dropdown, button.Activated:Connect(openMenu))
    attachTooltip(self.Window, button, config.Tooltip, dropdown)
    render()
    local result = self:_control(id, dropdown)
    if config.Disabled then
        result:SetDisabled(true)
    end
    return result
end

function Section:CreateButton(id: any, config: AnyTable?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local row, holder, titleLabel = makeControlRow(self, config.Title or id or "Button", config.Description)
    local control = setmetatable({
        Value = nil,
        Callback = config.Callback,
        ChangedCallbacks = {},
        Instance = row,
        TitleLabel = titleLabel,
        Disabled = false,
        Busy = false,
    }, BaseControl)
    local actionText = tostring(config.ButtonText or config.Text or "Run")
    local button = create("TextButton", {
        BackgroundColor3 = config.Primary and Theme.Accent or Theme.Surface3,
        BackgroundTransparency = config.Primary and 0 or 0.1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 28),
        ZIndex = 6,
        Parent = holder,
    }) :: TextButton
    corner(button, 5)
    local buttonStroke =
        stroke(button, config.Primary and Theme.Accent or Theme.Border, config.Primary and 0.18 or 0.55, 1)
    local label = makeText(button, actionText, 10, config.Primary and Theme.White or Theme.SubText, "bold")
    label.Size = UDim2.fromScale(1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.ZIndex = 7
    if config.Icon then
        label.Text = getIcon(config.Icon) .. "  " .. actionText
    end

    function control:SetBusy(busy: boolean): AnyTable
        self.Busy = busy == true
        label.Text = self.Busy and "···"
            or (config.Icon and getIcon(config.Icon) .. "  " .. actionText or actionText)
        button.Interactable = not self.Busy and not self.Disabled
        tween(button, { BackgroundTransparency = self.Busy and 0.42 or (config.Primary and 0 or 0.1) }, Motion.Hover)
        return self
    end

    control.RefreshView = function()
        button.BackgroundColor3 = config.Primary and Theme.Accent or Theme.Surface3
        buttonStroke.Color = config.Primary and Theme.Accent or Theme.Border
    end

    addConnection(
        control,
        button.MouseEnter:Connect(function()
            if not control.Disabled and not control.Busy then
                tween(button, {
                    BackgroundColor3 = config.Primary and Theme.AccentHover or Theme.HoverSurface,
                    BackgroundTransparency = config.Primary and 0 or 0.02,
                }, Motion.Hover)
            end
        end)
    )
    addConnection(
        control,
        button.MouseLeave:Connect(function()
            if not control.Busy then
                tween(button, {
                    BackgroundColor3 = config.Primary and Theme.Accent or Theme.Surface3,
                    BackgroundTransparency = config.Primary and 0 or 0.1,
                }, Motion.Hover)
            end
        end)
    )
    addConnection(
        control,
        button.MouseButton1Down:Connect(function()
            if not control.Disabled and not control.Busy then
                tween(button, { Size = UDim2.new(1, -3, 0, 25) }, Motion.Press)
            end
        end)
    )
    addConnection(
        control,
        button.MouseButton1Up:Connect(function()
            tween(button, { Size = UDim2.new(1, 0, 0, 28) }, Motion.Press)
        end)
    )
    addConnection(
        control,
        button.Activated:Connect(function()
            if control.Disabled or control.Busy then
                return
            end
            if config.AutoBusy then
                control:SetBusy(true)
                safeCall(config.Callback, control)
                task.delay(math.max(finiteNumber(config.BusyDuration, 0.45), 0), function()
                    if control.Instance and control.Instance.Parent then
                        control:SetBusy(false)
                    end
                end)
            else
                safeCall(config.Callback, control)
            end
            for _, callback in ipairs(control.ChangedCallbacks) do
                safeCall(callback, true)
            end
        end)
    )
    attachTooltip(self.Window, button, config.Tooltip, control)
    local result = self:_control(id, control)
    if config.Disabled then
        result:SetDisabled(true)
    end
    return result
end

function Section:CreateLabel(id: any, config: AnyTable?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title or config.Text
    end
    if type(config) == "string" then
        config = { Text = config }
    end
    config = config or {}
    local frame = create("Frame", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Parent = self.Content,
    }) :: Frame
    frame:SetAttribute("KronosSearch", string.lower(tostring(config.Text or config.Title or id or "Label")))
    local label = makeText(
        frame,
        tostring(config.Text or config.Title or id or "Label"),
        tonumber(config.TextSize) or 10,
        config.Muted and Theme.SubText or Theme.Text,
        config.Bold and "bold" or nil
    )
    label.Size = UDim2.fromScale(1, 1)
    label.TextWrapped = config.Wrap == true
    local control = setmetatable({ Value = label.Text, Instance = frame, TitleLabel = label }, BaseControl)
    function control:SetValue(value: any): AnyTable
        self.Value = tostring(value or "")
        label.Text = self.Value
        self:_fire(self.Value)
        return self
    end
    return self:_control(id, control)
end

function Section:CreateParagraph(id: any, config: AnyTable?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local textValue = tostring(config.Content or config.Text or "")
    local frame = create("Frame", {
        Name = "Paragraph",
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.58,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 58),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Content,
    }) :: Frame
    corner(frame, 5)
    stroke(frame, Theme.Border, 0.74, 1)
    padding(frame, 10, 8, 10, 8)
    frame:SetAttribute("KronosSearch", string.lower(tostring(config.Title or "") .. " " .. textValue))
    local paragraphLayout = list(frame, Enum.FillDirection.Vertical, 3)
    local titleLabel: TextLabel? = nil
    if config.Title then
        titleLabel = makeText(frame, tostring(config.Title), 10, Theme.Text, "bold")
        titleLabel.Size = UDim2.new(1, 0, 0, 16)
        titleLabel.LayoutOrder = 1
    end
    local content = makeText(frame, textValue, 10, Theme.SubText)
    content.Size = UDim2.new(1, 0, 0, 28)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.TextWrapped = true
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.LayoutOrder = 2
    local paragraph = setmetatable({ Value = textValue, Instance = frame, TitleLabel = titleLabel }, BaseControl)
    function paragraph:SetValue(value: any): AnyTable
        self.Value = tostring(value or "")
        content.Text = self.Value
        self:_fire(self.Value)
        return self
    end
    paragraph.RefreshView = function()
        frame.BackgroundColor3 = Theme.Surface2
        content.TextColor3 = Theme.SubText
        if titleLabel then
            titleLabel.TextColor3 = Theme.Text
        end
    end
    return self:_control(id, paragraph)
end

function Section:CreateDivider(id: any, config: AnyTable?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    elseif type(config) == "string" then
        config = { Title = config }
    end
    config = config or {}
    local frame = create("Frame", {
        Name = "Divider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, config.Title and 20 or 12),
        Parent = self.Content,
    }) :: Frame
    local line = create("Frame", {
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = frame,
    }) :: Frame
    ThemeController:Bind(line, "BackgroundColor3", "Divider")
    local titleLabel: TextLabel? = nil
    if config.Title then
        titleLabel = makeText(frame, " " .. tostring(config.Title) .. " ", 9, Theme.Muted, "bold")
        titleLabel.BackgroundColor3 = Theme.Surface
        titleLabel.BackgroundTransparency = 0
        titleLabel.AutomaticSize = Enum.AutomaticSize.X
        titleLabel.Size = UDim2.fromOffset(0, 16)
        titleLabel.Position = UDim2.fromOffset(8, 2)
    end
    return self:_control(id, setmetatable({ Value = nil, Instance = frame, TitleLabel = titleLabel }, BaseControl))
end

function Section:CreateKeybind(id: any, config: AnyTable?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local initialValue = config.Default
    if initialValue == nil then
        initialValue = "NONE"
    elseif typeof(initialValue) == "EnumItem" then
        initialValue = initialValue.Name
    else
        initialValue = tostring(initialValue)
    end
    local initialMode = tostring(config.Mode or "Toggle")
    if initialMode ~= "Hold" and initialMode ~= "Toggle" and initialMode ~= "Always" then
        initialMode = "Toggle"
    end
    local row, holder, titleLabel = makeControlRow(self, config.Title or id or "Keybind", config.Description)
    holder.Size = UDim2.fromOffset(132, 30)
    local keybind = setmetatable({
        Value = initialValue,
        Mode = initialMode,
        Callback = config.OnChanged or config.Changed,
        ActiveCallback = config.Callback,
        ChangedCallbacks = {},
        Instance = row,
        TitleLabel = titleLabel,
        Disabled = false,
        Listening = false,
        Active = initialMode == "Always",
        DisplayName = config.Title or id or "Keybind",
        ShowInList = config.ShowInList ~= false,
    }, BaseControl)

    local modeButton = create("TextButton", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.14,
        BorderSizePixel = 0,
        Text = string.upper(string.sub(keybind.Mode, 1, 1)),
        TextColor3 = Theme.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -80, 0.5, 0),
        Size = UDim2.fromOffset(25, 26),
        ZIndex = 6,
        Parent = holder,
    }) :: TextButton
    corner(modeButton, 4)
    stroke(modeButton, Theme.Border, 0.62, 1)
    local keyButton = create("TextButton", {
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(74, 26),
        ZIndex = 6,
        Parent = holder,
    }) :: TextButton
    corner(keyButton, 4)
    local keyStroke = stroke(keyButton, Theme.Border, 0.54, 1)
    local keyLabel = makeText(keyButton, "", 9, Theme.SubText, "bold")
    keyLabel.Size = UDim2.fromScale(1, 1)
    keyLabel.TextXAlignment = Enum.TextXAlignment.Center
    keyLabel.ZIndex = 7

    local function refresh()
        keyLabel.Text = keybind.Listening and "..." or string.upper(tostring(keybind.Value))
        keyLabel.TextColor3 = keybind.Listening and Theme.Accent or (keybind.Active and Theme.Text or Theme.SubText)
        modeButton.Text = string.upper(string.sub(keybind.Mode, 1, 1))
        modeButton.TextColor3 = keybind.Mode == "Always" and Theme.Accent or Theme.Muted
        if self.Window.KeybindWidget then
            self.Window.KeybindWidget:Refresh()
        end
    end

    function keybind:SetValue(value: any): AnyTable
        local nextValue = value == nil and "NONE" or (typeof(value) == "EnumItem" and value.Name or tostring(value))
        if nextValue ~= "NONE" and config.AllowConflict ~= true then
            for _, other in ipairs(self.Window.Keybinds) do
                if other ~= self and other.Value == nextValue then
                    other:SetValue("NONE")
                    NotificationController:Push({
                        Title = "Binding moved",
                        Content = nextValue .. " is now assigned to " .. self.DisplayName .. ".",
                        Duration = 2.3,
                    })
                end
            end
        end
        self.Value = nextValue
        self.Listening = false
        refresh()
        self:_fire(nextValue)
        return self
    end

    function keybind:SetMode(mode: any): AnyTable
        local normalized = tostring(mode or "Toggle")
        if normalized ~= "Hold" and normalized ~= "Toggle" and normalized ~= "Always" then
            normalized = "Toggle"
        end
        self.Mode = normalized
        self:SetActive(normalized == "Always")
        refresh()
        return self
    end

    function keybind:SetShowInList(visible: boolean): AnyTable
        self.ShowInList = visible ~= false
        refresh()
        return self
    end

    function keybind:SetActive(active: boolean): AnyTable
        local nextState = active == true
        if self.Active == nextState then
            return self
        end
        self.Active = nextState
        refresh()
        safeCall(self.ActiveCallback, nextState)
        return self
    end

    function keybind:BeginListening()
        if self.Disabled then
            return
        end
        if self.Window.ListeningKeybind and self.Window.ListeningKeybind ~= self then
            self.Window.ListeningKeybind:CancelListening()
        end
        self.Window.ListeningKeybind = self
        self.Listening = true
        refresh()
    end

    function keybind:CancelListening()
        self.Listening = false
        if self.Window.ListeningKeybind == self then
            self.Window.ListeningKeybind = nil
        end
        refresh()
    end

    function keybind:Capture(input: InputObject)
        if input.KeyCode == Enum.KeyCode.Escape then
            self:CancelListening()
            return
        end
        if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
            self:SetValue("NONE")
            self.Window.ListeningKeybind = nil
            return
        end
        local name = InputController.Name(input)
        if name ~= "MouseMovement" and name ~= "Touch" and name ~= "Unknown" then
            self:SetValue(name)
            self.Window.ListeningKeybind = nil
        end
    end

    keybind.RefreshView = refresh
    addConnection(
        keybind,
        keyButton.Activated:Connect(function()
            keybind:BeginListening()
        end)
    )
    addConnection(
        keybind,
        modeButton.Activated:Connect(function()
            if keybind.Disabled then
                return
            end
            local popup = create("CanvasGroup", {
                Name = "KeybindModePopup",
                BackgroundColor3 = Theme.ElevatedSurface,
                BackgroundTransparency = 0.03,
                BorderSizePixel = 0,
                GroupTransparency = 1,
                Size = UDim2.fromOffset(210, 126),
                Visible = false,
                ZIndex = 720,
            }) :: CanvasGroup
            corner(popup, Metrics.PopupRadius)
            stroke(popup, Theme.Border, 0.28, 1)
            padding(popup, 8, 8, 8, 8)
            local popupMaid = PopupController:Open(self.Window, popup, modeButton, 5)
            local bindingHeader = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
                ZIndex = 722,
                Parent = popup,
            }) :: Frame
            local bindingIcon = makeText(bindingHeader, getIcon("Keyboard"), 10, Theme.Muted, "bold")
            bindingIcon.Size = UDim2.fromOffset(20, 22)
            bindingIcon.TextXAlignment = Enum.TextXAlignment.Center
            bindingIcon.ZIndex = 723
            local bindingValue = makeText(bindingHeader, string.upper(tostring(keybind.Value)), 9, Theme.Text, "bold")
            bindingValue.Position = UDim2.fromOffset(25, 0)
            bindingValue.Size = UDim2.new(1, -25, 1, 0)
            bindingValue.ZIndex = 723

            local modeRow = create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 27),
                Size = UDim2.new(1, 0, 0, 29),
                ZIndex = 722,
                Parent = popup,
            }) :: Frame
            local modeLayout = list(modeRow, Enum.FillDirection.Horizontal, 4)
            modeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            local modeButtons: AnyTable = {}
            for _, mode in ipairs({ "Toggle", "Hold", "Always" }) do
                local choice = create("TextButton", {
                    BackgroundColor3 = keybind.Mode == mode and Theme.Accent or Theme.Surface2,
                    BackgroundTransparency = keybind.Mode == mode and 0 or 0.4,
                    BorderSizePixel = 0,
                    Text = mode,
                    TextColor3 = keybind.Mode == mode and Theme.White or Theme.SubText,
                    Font = Enum.Font.GothamBold,
                    TextSize = 9,
                    AutoButtonColor = false,
                    Size = UDim2.new(1 / 3, -3, 1, 0),
                    ZIndex = 722,
                    Parent = modeRow,
                }) :: TextButton
                corner(choice, 4)
                modeButtons[mode] = choice
            end
            local function refreshModeChoices()
                for mode, choice in pairs(modeButtons) do
                    local selected = keybind.Mode == mode
                    choice.BackgroundColor3 = selected and Theme.Accent or Theme.Surface2
                    choice.BackgroundTransparency = selected and 0 or 0.4
                    choice.TextColor3 = selected and Theme.White or Theme.SubText
                end
            end
            for mode, choice in pairs(modeButtons) do
                popupMaid:Give(choice.Activated:Connect(function()
                    keybind:SetMode(mode)
                    refreshModeChoices()
                end))
            end
            local valueTitle = makeText(popup, "VALUE", 8, Theme.Muted, "bold")
            valueTitle.Position = UDim2.fromOffset(0, 63)
            valueTitle.Size = UDim2.new(1, 0, 0, 14)
            valueTitle.ZIndex = 722
            local showChoice = create("TextButton", {
                BackgroundColor3 = Theme.Surface2,
                BackgroundTransparency = 0.4,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Position = UDim2.fromOffset(0, 80),
                Size = UDim2.new(1, 0, 0, 30),
                ZIndex = 722,
                Parent = popup,
            }) :: TextButton
            corner(showChoice, 4)
            local showLabel = makeText(showChoice, "Show in binds", 9, Theme.SubText, "bold")
            showLabel.Position = UDim2.fromOffset(8, 0)
            showLabel.Size = UDim2.new(1, -34, 1, 0)
            showLabel.ZIndex = 723
            local showCheck = create("Frame", {
                BackgroundColor3 = keybind.ShowInList and Theme.Accent or Theme.Surface3,
                BackgroundTransparency = keybind.ShowInList and 0 or 0.16,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -7, 0.5, 0),
                Size = UDim2.fromOffset(15, 15),
                ZIndex = 723,
                Parent = showChoice,
            }) :: Frame
            corner(showCheck, 3)
            local showMark = makeText(showCheck, keybind.ShowInList and "✓" or "", 9, Theme.White, "bold")
            showMark.Size = UDim2.fromScale(1, 1)
            showMark.TextXAlignment = Enum.TextXAlignment.Center
            showMark.ZIndex = 724
            popupMaid:Give(showChoice.Activated:Connect(function()
                keybind:SetShowInList(not keybind.ShowInList)
                showCheck.BackgroundColor3 = keybind.ShowInList and Theme.Accent or Theme.Surface3
                showCheck.BackgroundTransparency = keybind.ShowInList and 0 or 0.16
                showMark.Text = keybind.ShowInList and "✓" or ""
            end))
            task.defer(function()
                if popup.Parent and self.Window.ActivePopup and self.Window.ActivePopup.Frame == popup then
                    tween(popup, { GroupTransparency = 0 }, Motion.Dropdown)
                end
            end)
        end)
    )
    attachTooltip(
        self.Window,
        keyButton,
        config.Tooltip or "Click to listen. Escape cancels; Backspace clears.",
        keybind
    )

    table.insert(self.Window.Keybinds, keybind)
    table.insert(Kronos.Keybinds, keybind)
    local result = self:_control(id, keybind)
    if config.Disabled then
        result:SetDisabled(true)
    end
    refresh()
    return result
end

function Section:CreateColorpicker(id: any, config: AnyTable?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    local initial = typeof(config.Default) == "Color3" and config.Default or Theme.Accent
    local initialAlpha = math.clamp(finiteNumber(config.Transparency or config.Alpha, 0), 0, 1)
    local row, holder, titleLabel = makeControlRow(self, config.Title or id or "Color", config.Description)
    local picker = setmetatable({
        Value = initial,
        Transparency = initialAlpha,
        Callback = config.Callback,
        ChangedCallbacks = {},
        Instance = row,
        TitleLabel = titleLabel,
        Disabled = false,
    }, BaseControl)
    local preview = create("TextButton", {
        BackgroundColor3 = initial,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 28),
        ZIndex = 6,
        Parent = holder,
    }) :: TextButton
    corner(preview, 5)
    local previewStroke = stroke(preview, Theme.Border, 0.28, 1)
    local previewLabel = makeText(preview, rgbToHex(initial), 9, Theme.White, "bold")
    previewLabel.Size = UDim2.fromScale(1, 1)
    previewLabel.TextXAlignment = Enum.TextXAlignment.Center
    previewLabel.TextStrokeTransparency = 0.45
    previewLabel.ZIndex = 7

    local function render()
        preview.BackgroundColor3 = picker.Value
        previewLabel.Text = rgbToHex(picker.Value)
    end

    function picker:SetValue(color: any, transparency: number?): AnyTable
        if typeof(color) ~= "Color3" then
            return self
        end
        self.Value = color
        if transparency ~= nil then
            self.Transparency = math.clamp(finiteNumber(transparency, self.Transparency), 0, 1)
        end
        render()
        self:_fire(color)
        safeCall(config.OnTransparencyChanged, self.Transparency)
        return self
    end

    picker.RefreshView = render

    local function openPicker()
        if picker.Disabled then
            return
        end
        if self.Window.ActivePopup and self.Window.ActivePopup.Anchor == preview then
            PopupController:Close(self.Window)
            return
        end
        local alphaEnabled = config.EnableAlpha == true or config.Alpha ~= nil or config.Transparency ~= nil
        local continuous = config.Continuous ~= false
        local popupHeight = alphaEnabled and 242 or 214
        if not continuous then
            popupHeight += 29
        end
        local popup = create("CanvasGroup", {
            Name = "ColorPickerPopup",
            BackgroundColor3 = Theme.ElevatedSurface,
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            GroupTransparency = 1,
            Size = UDim2.fromOffset(200, popupHeight),
            Visible = false,
            ZIndex = 740,
        }) :: CanvasGroup
        corner(popup, Metrics.PopupRadius)
        stroke(popup, Theme.Border, 0.24, 1)
        padding(popup, 9, 9, 9, 9)
        local popupMaid = PopupController:Open(self.Window, popup, preview, 5)
        local hueValue, saturation, brightness = picker.Value:ToHSV()
        local alphaValue = picker.Transparency
        local candidate = picker.Value

        local pickerTitle =
            makeText(popup, tostring(config.PopupTitle or config.Title or "Color"), 9, Theme.Text, "bold")
        pickerTitle.Size = UDim2.new(1, 0, 0, 18)
        pickerTitle.ZIndex = 742

        local saturationFrame = create("Frame", {
            BackgroundColor3 = Color3.fromHSV(hueValue, 1, 1),
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 24),
            Size = UDim2.fromOffset(154, 100),
            ClipsDescendants = true,
            ZIndex = 742,
            Parent = popup,
        }) :: Frame
        corner(saturationFrame, 5)
        local whiteLayer = create("Frame", {
            BackgroundColor3 = Theme.White,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 743,
            Parent = saturationFrame,
        }) :: Frame
        local whiteGradient = create("UIGradient", {
            Rotation = 0,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = whiteLayer,
        }) :: UIGradient
        local blackLayer = create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 744,
            Parent = saturationFrame,
        }) :: Frame
        create("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
            Parent = blackLayer,
        })
        local saturationDot = create("Frame", {
            BackgroundColor3 = Theme.White,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(saturation, 1 - brightness),
            Size = UDim2.fromOffset(9, 9),
            ZIndex = 746,
            Parent = saturationFrame,
        }) :: Frame
        corner(saturationDot, 5)
        stroke(saturationDot, Color3.new(0, 0, 0), 0.22, 1)
        local saturationHit = makeHitbox(saturationFrame)
        saturationHit.ZIndex = 745

        local hueFrame = create("Frame", {
            BackgroundColor3 = Theme.White,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(160, 24),
            Size = UDim2.fromOffset(18, 100),
            ClipsDescendants = true,
            ZIndex = 742,
            Parent = popup,
        }) :: Frame
        corner(hueFrame, 5)
        create("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            }),
            Parent = hueFrame,
        })
        local hueMarker = create("Frame", {
            BackgroundColor3 = Theme.White,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, hueValue),
            Size = UDim2.fromOffset(20, 3),
            ZIndex = 746,
            Parent = hueFrame,
        }) :: Frame
        corner(hueMarker, 2)
        local hueHit = makeHitbox(hueFrame)
        hueHit.ZIndex = 745

        local previewChip = create("Frame", {
            BackgroundColor3 = candidate,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 132),
            Size = UDim2.fromOffset(28, 27),
            ZIndex = 742,
            Parent = popup,
        }) :: Frame
        corner(previewChip, 5)
        stroke(previewChip, Theme.Border, 0.25, 1)

        local hexBox = create("TextBox", {
            BackgroundColor3 = Theme.Surface3,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Text = rgbToHex(candidate),
            PlaceholderText = "#FFFFFF",
            TextColor3 = Theme.Text,
            PlaceholderColor3 = Theme.Muted,
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            Position = UDim2.fromOffset(34, 132),
            Size = UDim2.fromOffset(64, 27),
            ZIndex = 742,
            Parent = popup,
        }) :: TextBox
        corner(hexBox, 5)
        stroke(hexBox, Theme.Border, 0.56, 1)
        local rgbBox = create("TextBox", {
            BackgroundColor3 = Theme.Surface3,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Text = string.format(
                "%d, %d, %d",
                math.floor(candidate.R * 255 + 0.5),
                math.floor(candidate.G * 255 + 0.5),
                math.floor(candidate.B * 255 + 0.5)
            ),
            PlaceholderText = "R, G, B",
            TextColor3 = Theme.Text,
            PlaceholderColor3 = Theme.Muted,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            Position = UDim2.fromOffset(104, 132),
            Size = UDim2.fromOffset(74, 27),
            ZIndex = 742,
            Parent = popup,
        }) :: TextBox
        corner(rgbBox, 5)
        stroke(rgbBox, Theme.Border, 0.56, 1)

        local alphaTrack: Frame? = nil
        local alphaFill: Frame? = nil
        local alphaLabel: TextLabel? = nil
        local controlsY = 166
        if alphaEnabled then
            alphaLabel = makeText(
                popup,
                "Alpha  " .. tostring(math.floor((1 - alphaValue) * 100 + 0.5)) .. "%",
                9,
                Theme.SubText,
                "bold"
            )
            alphaLabel.Position = UDim2.fromOffset(0, controlsY)
            alphaLabel.Size = UDim2.new(1, 0, 0, 16)
            alphaLabel.ZIndex = 742
            alphaTrack = create("Frame", {
                BackgroundColor3 = Theme.Surface3,
                BorderSizePixel = 0,
                Active = true,
                Position = UDim2.fromOffset(0, controlsY + 19),
                Size = UDim2.new(1, 0, 0, 7),
                ZIndex = 742,
                Parent = popup,
            }) :: Frame
            corner(alphaTrack, 4)
            alphaFill = create("Frame", {
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1 - alphaValue, 1),
                ZIndex = 743,
                Parent = alphaTrack,
            }) :: Frame
            corner(alphaFill, 4)
            ThemeController:Bind(alphaFill, "BackgroundColor3", "Accent")
            controlsY += 30
        end

        local presetFrame = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, controlsY),
            Size = UDim2.new(1, 0, 0, 25),
            ZIndex = 742,
            Parent = popup,
        }) :: Frame
        local presetLayout = list(presetFrame, Enum.FillDirection.Horizontal, 5)
        presetLayout.VerticalAlignment = Enum.VerticalAlignment.Center

        local function updateFields(fire: boolean)
            candidate = Color3.fromHSV(hueValue, saturation, brightness)
            saturationFrame.BackgroundColor3 = Color3.fromHSV(hueValue, 1, 1)
            saturationDot.Position = UDim2.fromScale(saturation, 1 - brightness)
            hueMarker.Position = UDim2.fromScale(0.5, hueValue)
            previewChip.BackgroundColor3 = candidate
            hexBox.Text = rgbToHex(candidate)
            rgbBox.Text = string.format(
                "%d, %d, %d",
                math.floor(candidate.R * 255 + 0.5),
                math.floor(candidate.G * 255 + 0.5),
                math.floor(candidate.B * 255 + 0.5)
            )
            if alphaFill then
                alphaFill.Size = UDim2.fromScale(1 - alphaValue, 1)
            end
            if alphaLabel then
                alphaLabel.Text = "Alpha  " .. tostring(math.floor((1 - alphaValue) * 100 + 0.5)) .. "%"
            end
            if fire and continuous then
                picker:SetValue(candidate, alphaValue)
            end
        end

        local presetColors = config.Presets
            or {
                Theme.Accent,
                Color3.fromRGB(104, 139, 255),
                Color3.fromRGB(89, 199, 158),
                Color3.fromRGB(224, 109, 129),
                Color3.fromRGB(231, 179, 92),
                Color3.fromRGB(239, 239, 244),
            }
        for _, color in ipairs(presetColors) do
            local chip = create("TextButton", {
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Size = UDim2.fromOffset(24, 24),
                ZIndex = 743,
                Parent = presetFrame,
            }) :: TextButton
            corner(chip, 4)
            stroke(chip, Theme.White, 0.6, 1)
            popupMaid:Give(chip.Activated:Connect(function()
                hueValue, saturation, brightness = color:ToHSV()
                updateFields(true)
            end))
        end

        local activeDrag: string? = nil
        local dragTouch: InputObject? = nil
        local function updateSaturation(position: Vector3)
            saturation =
                math.clamp((position.X - saturationFrame.AbsolutePosition.X) / saturationFrame.AbsoluteSize.X, 0, 1)
            brightness = 1
                - math.clamp((position.Y - saturationFrame.AbsolutePosition.Y) / saturationFrame.AbsoluteSize.Y, 0, 1)
            updateFields(true)
        end
        local function updateHue(position: Vector3)
            hueValue = math.clamp((position.Y - hueFrame.AbsolutePosition.Y) / hueFrame.AbsoluteSize.Y, 0, 1)
            updateFields(true)
        end
        local function updateAlpha(position: Vector3)
            if alphaTrack then
                alphaValue = 1
                    - math.clamp((position.X - alphaTrack.AbsolutePosition.X) / alphaTrack.AbsoluteSize.X, 0, 1)
                updateFields(true)
            end
        end
        popupMaid:Give(saturationHit.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                activeDrag = "Saturation"
                dragTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
                updateSaturation(input.Position)
            end
        end))
        popupMaid:Give(hueHit.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                activeDrag = "Hue"
                dragTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
                updateHue(input.Position)
            end
        end))
        if alphaTrack then
            popupMaid:Give(alphaTrack.InputBegan:Connect(function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    activeDrag = "Alpha"
                    dragTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
                    updateAlpha(input.Position)
                end
            end))
        end
        popupMaid:Give(UserInputService.InputChanged:Connect(function(input)
            if
                activeDrag
                and (
                    (dragTouch and input == dragTouch)
                    or (not dragTouch and input.UserInputType == Enum.UserInputType.MouseMovement)
                )
            then
                if activeDrag == "Saturation" then
                    updateSaturation(input.Position)
                elseif activeDrag == "Hue" then
                    updateHue(input.Position)
                elseif activeDrag == "Alpha" then
                    updateAlpha(input.Position)
                end
            end
        end))
        popupMaid:Give(UserInputService.InputEnded:Connect(function(input)
            if
                activeDrag
                and (
                    (dragTouch and input == dragTouch)
                    or (not dragTouch and input.UserInputType == Enum.UserInputType.MouseButton1)
                )
            then
                activeDrag = nil
                dragTouch = nil
            end
        end))
        popupMaid:Give(hexBox.FocusLost:Connect(function()
            local parsed = hexToColor(hexBox.Text)
            if parsed then
                hueValue, saturation, brightness = parsed:ToHSV()
                updateFields(true)
            else
                hexBox.Text = rgbToHex(candidate)
            end
        end))
        popupMaid:Give(rgbBox.FocusLost:Connect(function()
            local red, green, blue = string.match(rgbBox.Text, "^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
            if red and green and blue then
                local parsed = Color3.fromRGB(
                    math.clamp(tonumber(red) or 0, 0, 255),
                    math.clamp(tonumber(green) or 0, 0, 255),
                    math.clamp(tonumber(blue) or 0, 0, 255)
                )
                hueValue, saturation, brightness = parsed:ToHSV()
                updateFields(true)
            else
                rgbBox.Text = string.format(
                    "%d, %d, %d",
                    math.floor(candidate.R * 255 + 0.5),
                    math.floor(candidate.G * 255 + 0.5),
                    math.floor(candidate.B * 255 + 0.5)
                )
            end
        end))

        if not continuous then
            local applyButton = create("TextButton", {
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Text = "Apply",
                TextColor3 = Theme.White,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                AutoButtonColor = false,
                Position = UDim2.fromOffset(0, controlsY + 29),
                Size = UDim2.new(1, 0, 0, 25),
                ZIndex = 742,
                Parent = popup,
            }) :: TextButton
            corner(applyButton, 5)
            popupMaid:Give(applyButton.Activated:Connect(function()
                picker:SetValue(candidate, alphaValue)
                PopupController:Close(self.Window)
            end))
        end

        updateFields(false)
        task.defer(function()
            if popup.Parent and self.Window.ActivePopup and self.Window.ActivePopup.Frame == popup then
                local resting = popup.Position
                popup.Position = resting + UDim2.fromOffset(0, -4)
                tween(popup, { GroupTransparency = 0, Position = resting }, Motion.Dropdown)
            end
        end)
    end

    addConnection(picker, preview.Activated:Connect(openPicker))
    attachTooltip(self.Window, preview, config.Tooltip, picker)
    render()
    local result = self:_control(id, picker)
    if config.Disabled then
        result:SetDisabled(true)
    end
    return result
end

function Section:CreateMultiDropdown(id: any, config: AnyTable?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Title
    end
    config = config or {}
    config.Multi = true
    return self:CreateDropdown(id, config)
end

Section.AddToggle = Section.CreateToggle
Section.AddSlider = Section.CreateSlider
Section.AddDropdown = Section.CreateDropdown
Section.AddMultiDropdown = Section.CreateMultiDropdown
Section.AddInput = Section.CreateInput
Section.AddKeybind = Section.CreateKeybind
Section.AddButton = Section.CreateButton
Section.AddLabel = Section.CreateLabel
Section.AddParagraph = Section.CreateParagraph
Section.AddDivider = Section.CreateDivider
Section.AddColorpicker = Section.CreateColorpicker
Section.AddColorPicker = Section.CreateColorpicker
Section.CreateColorPicker = Section.CreateColorpicker
function Section:RefreshSearch(query: string, parentMatch: boolean?): boolean
    local normalized = string.lower(query)
    local sectionMatch = parentMatch == true
        or normalized == ""
        or string.find(self.SearchText, normalized, 1, true) ~= nil
    local anyVisible = false
    for _, control in ipairs(self.Controls) do
        local instance = control.Instance
        if instance and instance.Parent then
            local searchText = instance:GetAttribute("KronosSearch")
            local controlMatch = sectionMatch
                or (type(searchText) == "string" and string.find(searchText, normalized, 1, true) ~= nil)
            control.SearchVisible = controlMatch
            instance.Visible = controlMatch and control.ManualVisible ~= false
            anyVisible = anyVisible or instance.Visible
        end
    end
    self.SearchVisible = sectionMatch or anyVisible
    self.Instance.Visible = self.ManualVisible ~= false and self.SearchVisible
    return self.Instance.Visible
end

function Section:SetVisible(visible: boolean): AnyTable
    self.ManualVisible = visible ~= false
    self.Instance.Visible = self.ManualVisible and self.SearchVisible ~= false
    self.Tab:_updateCanvas()
    return self
end

function Section:Destroy()
    local controls = copyArray(self.Controls)
    for _, control in ipairs(controls) do
        control:Destroy()
    end
    if self.RowConnectionOwners then
        for _, owner in pairs(self.RowConnectionOwners) do
            disconnectAll(owner)
        end
        table.clear(self.RowConnectionOwners)
    end
    disconnectAll(self)
    if self.Instance then
        ThemeController:UnbindTree(self.Instance)
        self.Instance:Destroy()
    end
    local index = table.find(self.Tab.Sections, self)
    if index then
        table.remove(self.Tab.Sections, index)
    end
    self.Tab:_updateCanvas()
end

function Tab:_updateCanvas()
    task.defer(function()
        if not self.Scroll or not self.Scroll.Parent then
            return
        end
        local leftHeight = self.LeftLayout.AbsoluteContentSize.Y
        local rightHeight = self.TwoColumn and self.RightLayout.AbsoluteContentSize.Y or 0
        local height = self.TwoColumn and math.max(leftHeight, rightHeight) or leftHeight
        self.Columns.Size = UDim2.new(1, -2, 0, height)
        self.Scroll.CanvasSize = UDim2.fromOffset(0, height + 18)
    end)
end

function Tab:ApplyColumns(twoColumn: boolean)
    if self.TwoColumn == twoColumn and self.ColumnsInitialized then
        self:_updateCanvas()
        return
    end
    self.TwoColumn = twoColumn
    self.ColumnsInitialized = true
    self.RightColumn.Visible = twoColumn
    if twoColumn then
        self.LeftColumn.Size = UDim2.new(0.5, -5, 0, 0)
        self.RightColumn.Size = UDim2.new(0.5, -5, 0, 0)
        self.RightColumn.Position = UDim2.new(0.5, 5, 0, 0)
        for index, section in ipairs(self.Sections) do
            local side = section.PreferredSide
            if side == nil then
                side = index % 2 == 0 and "Right" or "Left"
            end
            section.Instance.Parent = side == "Right" and self.RightColumn or self.LeftColumn
        end
    else
        self.LeftColumn.Size = UDim2.new(1, 0, 0, 0)
        self.RightColumn.Position = UDim2.fromOffset(0, 0)
        for _, section in ipairs(self.Sections) do
            section.Instance.Parent = self.LeftColumn
        end
    end
    self:_updateCanvas()
end

function Tab:RefreshSearch(query: string): boolean
    local normalized = string.lower(query)
    local tabMatch = normalized == "" or string.find(string.lower(self.Title), normalized, 1, true) ~= nil
    local anySection = false
    for _, section in ipairs(self.Sections) do
        anySection = section:RefreshSearch(normalized, tabMatch) or anySection
    end
    self.SearchVisible = tabMatch or anySection
    self.Button.Visible = self.SearchVisible
    self:_updateCanvas()
    return self.SearchVisible
end

function Tab:CreateSection(config: AnyTable?): AnyTable
    if type(config) == "string" then
        config = { Title = config }
    end
    config = config or {}
    local index = #self.Sections + 1
    local preferredSide: string? = nil
    if type(config.Side) == "string" then
        preferredSide = string.lower(config.Side) == "right" and "Right" or "Left"
    end
    local parent = self.LeftColumn
    if self.TwoColumn and (preferredSide == "Right" or (preferredSide == nil and index % 2 == 0)) then
        parent = self.RightColumn
    end
    local section = setmetatable({
        Window = self.Window,
        Tab = self,
        Controls = {},
        Connections = {},
        PreferredSide = preferredSide,
        ManualVisible = true,
        SearchVisible = true,
        Title = tostring(config.Title or "Section"),
    }, Section)
    section.SearchText = string.lower(section.Title .. " " .. tostring(config.Description or ""))

    local frame = create("Frame", {
        Name = "Section",
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.52,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = index,
        Parent = parent,
    }) :: Frame
    frame:SetAttribute("KronosSearch", section.SearchText)
    corner(frame, Metrics.Radius)
    local frameStroke = stroke(frame, Theme.Border, 0.78, 1)
    ThemeController:Bind(frameStroke, "Color", "Border")
    padding(frame, 10, 8, 10, 10)
    local frameLayout = list(frame, Enum.FillDirection.Vertical, 6)

    local heading = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, config.Description and 31 or 21),
        LayoutOrder = 1,
        Parent = frame,
    }) :: Frame
    local titleOffset = 0
    if config.Icon then
        local icon = makeText(heading, getIcon(config.Icon), 11, Theme.Accent, "bold")
        icon.Position = UDim2.fromOffset(0, 0)
        icon.Size = UDim2.fromOffset(16, 18)
        icon.TextXAlignment = Enum.TextXAlignment.Center
        titleOffset = 21
        ThemeController:Bind(icon, "TextColor3", "Accent")
    end
    local title = makeText(heading, section.Title, 11, Theme.Text, "bold")
    title.Position = UDim2.fromOffset(titleOffset, 0)
    title.Size = UDim2.new(1, -titleOffset, 0, 18)
    if config.Description then
        local description = makeText(heading, tostring(config.Description), 9, Theme.Muted)
        description.Position = UDim2.fromOffset(titleOffset, 16)
        description.Size = UDim2.new(1, -titleOffset, 0, 14)
    end

    local content = create("Frame", {
        Name = "Controls",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Parent = frame,
    }) :: Frame
    local contentLayout = list(content, Enum.FillDirection.Vertical, 5)
    section.Instance = frame
    section.Content = content
    section.ContentLayout = contentLayout
    section.TitleLabel = title
    addConnection(
        section,
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            self:_updateCanvas()
        end)
    )
    table.insert(self.Sections, section)
    self:ApplyColumns(self.TwoColumn)
    self:_updateCanvas()
    return section
end

Tab.AddSection = Tab.CreateSection

function Tab:Destroy()
    local wasActive = self.Window.ActiveTab == self
    local sections = copyArray(self.Sections)
    for _, section in ipairs(sections) do
        section:Destroy()
    end
    disconnectAll(self)
    if self.Button then
        ThemeController:UnbindTree(self.Button)
        self.Button:Destroy()
    end
    if self.Page then
        ThemeController:UnbindTree(self.Page)
        self.Page:Destroy()
    end
    local index = table.find(self.Window.Tabs, self)
    if index then
        table.remove(self.Window.Tabs, index)
    end
    if wasActive and not self.Window.Destroyed then
        self.Window.ActiveTab = nil
        for _, tab in ipairs(self.Window.Tabs) do
            if tab.SearchVisible ~= false then
                self.Window:SelectTab(tab)
                break
            end
        end
    end
end

function Window:_setActiveTabVisual(tab: AnyTable, active: boolean)
    if not tab then
        return
    end
    tween(tab.Button, {
        BackgroundColor3 = active and Theme.PressedSurface or Theme.Surface2,
        BackgroundTransparency = active and 0.18 or 1,
    }, Motion.Tab)
    tween(tab.ActiveBar, {
        BackgroundTransparency = active and 0 or 1,
        Size = active and UDim2.fromOffset(2, 20) or UDim2.fromOffset(2, 8),
    }, Motion.Tab)
    tween(tab.IconLabel, { TextColor3 = active and Theme.Accent or Theme.Muted }, Motion.Tab)
    tween(tab.TitleLabel, { TextColor3 = active and Theme.Text or Theme.SubText }, Motion.Tab)
end

function Window:SelectTab(tab: any)
    if type(tab) == "string" then
        for _, candidate in ipairs(self.Tabs) do
            if candidate.Title == tab then
                tab = candidate
                break
            end
        end
    end
    if type(tab) ~= "table" or tab == self.ActiveTab or tab.SearchVisible == false then
        return self
    end
    dismissTooltip(self)
    PopupController:Close(self)
    if self.ActiveTab then
        local previousTab = self.ActiveTab
        self:_setActiveTabVisual(previousTab, false)
        tween(previousTab.Page, { GroupTransparency = 1, Position = UDim2.fromOffset(-7, 0) }, Motion.TabExit)
        task.delay(Motion.TabExit, function()
            if self.ActiveTab ~= previousTab and previousTab.Page.Parent then
                previousTab.Page.Visible = false
            end
        end)
    end
    self.ActiveTab = tab
    tab.Page.Visible = true
    tab.Page.Position = UDim2.fromOffset(7, 0)
    tab.Page.GroupTransparency = 1
    tween(tab.Page, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, Motion.Tab)
    self:_setActiveTabVisual(tab, true)
    tab:ApplyColumns(self.TwoColumn)
    task.defer(function()
        if tab.Button.Parent and self.NavigationScroll.AbsoluteCanvasSize.Y > self.NavigationScroll.AbsoluteSize.Y then
            local buttonTop = tab.Button.AbsolutePosition.Y - self.NavigationScroll.AbsolutePosition.Y
            local buttonBottom = buttonTop + tab.Button.AbsoluteSize.Y
            local current = self.NavigationScroll.CanvasPosition.Y
            local viewHeight = self.NavigationScroll.AbsoluteSize.Y
            if buttonTop < current then
                self.NavigationScroll.CanvasPosition = Vector2.new(0, math.max(buttonTop - 4, 0))
            elseif buttonBottom > current + viewHeight then
                self.NavigationScroll.CanvasPosition = Vector2.new(0, buttonBottom - viewHeight + 4)
            end
        end
    end)
    return self
end

function Window:CreateTab(config: AnyTable?): AnyTable
    if type(config) == "string" then
        config = { Title = config }
    end
    config = config or {}
    local tab = setmetatable({
        Window = self,
        Title = tostring(config.Title or "Tab"),
        Sections = {},
        Connections = {},
        SearchVisible = true,
        TwoColumn = self.TwoColumn,
    }, Tab)
    local button = create("TextButton", {
        Name = "TabButton",
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = self.SidebarList,
    }) :: TextButton
    button:SetAttribute("KronosSearch", string.lower(tab.Title))
    corner(button, 5)
    local activeBar = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(2, 8),
        Parent = button,
    }) :: Frame
    corner(activeBar, 1)
    ThemeController:Bind(activeBar, "BackgroundColor3", "Accent")
    local icon = makeText(button, getIcon(config.Icon or tab.Title), 12, Theme.Muted, "bold")
    icon.Position = UDim2.fromOffset(9, 0)
    icon.Size = UDim2.fromOffset(22, 34)
    icon.TextXAlignment = Enum.TextXAlignment.Center
    local title = makeText(button, tab.Title, 10, Theme.SubText, "bold")
    title.Position = UDim2.fromOffset(36, 0)
    title.Size = UDim2.new(1, -43, 1, 0)

    local page = create("CanvasGroup", {
        Name = "TabPage",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = self.PageHost,
    }) :: CanvasGroup
    local scroll = create("ScrollingFrame", {
        Name = "ContentScroll",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.08,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = page,
    }) :: ScrollingFrame
    ThemeController:Bind(scroll, "ScrollBarImageColor3", "Accent")
    local columns = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(7, 7),
        Size = UDim2.new(1, -18, 0, 0),
        Parent = scroll,
    }) :: Frame
    local leftColumn = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = columns,
    }) :: Frame
    local rightColumn = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 5, 0, 0),
        Size = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = columns,
    }) :: Frame
    local leftLayout = list(leftColumn, Enum.FillDirection.Vertical, Metrics.SectionGap)
    local rightLayout = list(rightColumn, Enum.FillDirection.Vertical, Metrics.SectionGap)
    tab.Button = button
    tab.ActiveBar = activeBar
    tab.IconLabel = icon
    tab.TitleLabel = title
    tab.Page = page
    tab.Scroll = scroll
    tab.Columns = columns
    tab.LeftColumn = leftColumn
    tab.RightColumn = rightColumn
    tab.LeftLayout = leftLayout
    tab.RightLayout = rightLayout
    addConnection(
        tab,
        leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tab:_updateCanvas()
        end)
    )
    addConnection(
        tab,
        rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tab:_updateCanvas()
        end)
    )
    addConnection(
        tab,
        button.Activated:Connect(function()
            self:SelectTab(tab)
        end)
    )
    addConnection(
        tab,
        button.MouseEnter:Connect(function()
            if self.ActiveTab ~= tab then
                tween(button, { BackgroundTransparency = 0.45 }, Motion.Hover)
            end
        end)
    )
    addConnection(
        tab,
        button.MouseLeave:Connect(function()
            if self.ActiveTab ~= tab then
                tween(button, { BackgroundTransparency = 1 }, Motion.Hover)
            end
        end)
    )
    attachTooltip(self, button, config.Tooltip, tab)
    table.insert(self.Tabs, tab)
    tab:ApplyColumns(self.TwoColumn)
    if not self.ActiveTab then
        self:SelectTab(tab)
    end
    return tab
end

Window.AddTab = Window.CreateTab

function Window:AddSection(config: AnyTable?): AnyTable
    local tab = self.ActiveTab or self.Tabs[1]
    if not tab then
        tab = self:CreateTab({ Title = "General", Icon = "Home" })
    end
    return tab:CreateSection(config)
end

function Window:Notify(config: AnyTable?): AnyTable
    return self.Kronos:Notify(config)
end

local function makeUtilityButton(parent: Instance, glyph: string, order: number): TextButton
    local button = create("TextButton", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.38,
        BorderSizePixel = 0,
        Text = glyph,
        TextColor3 = Theme.SubText,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -(10 + (order - 1) * 31), 0.5, 0),
        Size = UDim2.fromOffset(25, 25),
        ZIndex = 32,
        Parent = parent,
    }) :: TextButton
    corner(button, 5)
    stroke(button, Theme.Border, 0.7, 1)
    return button
end

function Window:_makeHeader(config: WindowConfig)
    local header = create("Frame", {
        Name = "Header",
        BackgroundColor3 = Theme.BackgroundSoft,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Metrics.Header),
        ZIndex = 25,
        Parent = self.Main,
    }) :: Frame
    ThemeController:Bind(header, "BackgroundColor3", "BackgroundSoft")
    local divider = create("Frame", {
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 26,
        Parent = header,
    }) :: Frame
    ThemeController:Bind(divider, "BackgroundColor3", "Divider")
    local dragSurface = create("Frame", {
        Name = "DragSurface",
        BackgroundTransparency = 1,
        Active = true,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -155, 1, 0),
        ZIndex = 27,
        Parent = header,
    }) :: Frame

    local logo = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(13, 14),
        Size = UDim2.fromOffset(27, 27),
        ZIndex = 29,
        Parent = header,
    }) :: Frame
    corner(logo, 5)
    ThemeController:Bind(logo, "BackgroundColor3", "Accent")
    local logoText = makeText(logo, "K", 13, Theme.White, "bold")
    logoText.Size = UDim2.fromScale(1, 1)
    logoText.TextXAlignment = Enum.TextXAlignment.Center
    logoText.ZIndex = 30
    local title = makeText(header, tostring(config.Title or "Kronos"), 13, Theme.Text, "bold")
    title.Position = UDim2.fromOffset(49, 10)
    title.Size = UDim2.fromOffset(180, 20)
    title.ZIndex = 29
    local subtitle =
        makeText(header, tostring(config.Subtitle or config.SubTitle or "Interface Library"), 9, Theme.Muted)
    subtitle.Position = UDim2.fromOffset(49, 28)
    subtitle.Size = UDim2.fromOffset(260, 17)
    subtitle.ZIndex = 29

    local closeButton = makeUtilityButton(header, "×", 1)
    local minimizeButton = makeUtilityButton(header, "−", 2)
    local settingsButton = makeUtilityButton(header, getIcon("Settings"), 3)
    local presetsButton = makeUtilityButton(header, getIcon("Save"), 4)
    self.SettingsButton = settingsButton
    self.PresetsButton = presetsButton
    self.HeaderTitle = title
    self.HeaderSubtitle = subtitle
    self.Header = header
    DragController:Bind(self, dragSurface, self.Root, function(position)
        self.LastPosition = position
    end)
    for _, button in ipairs({ closeButton, minimizeButton, settingsButton, presetsButton }) do
        addConnection(
            self,
            button.MouseEnter:Connect(function()
                tween(button, { BackgroundTransparency = 0.12, TextColor3 = Theme.Text }, Motion.Hover)
            end)
        )
        addConnection(
            self,
            button.MouseLeave:Connect(function()
                tween(button, { BackgroundTransparency = 0.38, TextColor3 = Theme.SubText }, Motion.Hover)
            end)
        )
    end
    addConnection(
        self,
        closeButton.Activated:Connect(function()
            self:SetVisible(false)
        end)
    )
    addConnection(
        self,
        minimizeButton.Activated:Connect(function()
            self:Minimize()
        end)
    )
    addConnection(
        self,
        settingsButton.Activated:Connect(function()
            self:OpenSettings()
        end)
    )
    addConnection(
        self,
        presetsButton.Activated:Connect(function()
            self:OpenPresets()
        end)
    )
end

function Window:ApplySearch(value: string)
    dismissTooltip(self)
    PopupController:Close(self)
    local query = string.lower(value or "")
    local visibleTabs = 0
    local firstVisible: AnyTable? = nil
    for _, tab in ipairs(self.Tabs) do
        if tab:RefreshSearch(query) then
            visibleTabs += 1
            firstVisible = firstVisible or tab
        end
    end
    self.EmptySearch.Visible = visibleTabs == 0
    if self.ActiveTab and self.ActiveTab.SearchVisible == false then
        self.ActiveTab.Page.Visible = false
        self.ActiveTab = nil
        if firstVisible then
            self:SelectTab(firstVisible)
        end
    elseif not self.ActiveTab and firstVisible then
        self:SelectTab(firstVisible)
    end
end

function Window:EnsureVisible(instance: GuiObject)
    local ancestor: Instance? = instance.Parent
    while ancestor and not ancestor:IsA("ScrollingFrame") do
        ancestor = ancestor.Parent
    end
    if not ancestor or not ancestor:IsA("ScrollingFrame") then
        return
    end
    local scroller = ancestor :: ScrollingFrame
    task.defer(function()
        if not instance.Parent then
            return
        end
        local top = instance.AbsolutePosition.Y - scroller.AbsolutePosition.Y + scroller.CanvasPosition.Y
        local bottom = top + instance.AbsoluteSize.Y
        local viewTop = scroller.CanvasPosition.Y
        local viewBottom = viewTop + scroller.AbsoluteSize.Y
        if top < viewTop then
            scroller.CanvasPosition = Vector2.new(0, math.max(top - 8, 0))
        elseif bottom > viewBottom then
            scroller.CanvasPosition = Vector2.new(0, bottom - scroller.AbsoluteSize.Y + 8)
        end
    end)
end

function Window:ApplyResponsive()
    if not self.Root or not self.Root.Parent then
        return
    end
    local viewport = viewportSize()
    local topLeftInset, bottomRightInset = guiInsets()
    local safeWidth = math.max(viewport.X - topLeftInset.X - bottomRightInset.X - Metrics.SafePadding * 2, 280)
    local safeHeight = math.max(viewport.Y - topLeftInset.Y - bottomRightInset.Y - Metrics.SafePadding * 2, 300)
    local width = math.min(self.BaseWidth, safeWidth)
    local height = math.min(self.BaseHeight, safeHeight)
    width = math.floor(width + 0.5)
    height = math.floor(height + 0.5)
    self.Width = width
    self.Height = height
    self.Root.Size = UDim2.fromOffset(width, height)
    local anchorPoint = self.Root.AbsolutePosition + self.Root.AbsoluteSize * self.Root.AnchorPoint
    local clamped = clampGuiCenter(self.Root, anchorPoint)
    self.Root.Position = UDim2.fromOffset(clamped.X, clamped.Y)

    local expanded = width >= 690 and self.ForceCompactNavigation ~= true
    local sidebarWidth = expanded and Metrics.Sidebar or Metrics.CompactSidebar
    self.ExpandedNavigation = expanded
    self.Sidebar.Size = UDim2.new(0, sidebarWidth, 1, -Metrics.Header)
    self.Content.Position = UDim2.fromOffset(sidebarWidth, Metrics.Header)
    self.Content.Size = UDim2.new(1, -sidebarWidth, 1, -Metrics.Header)
    self.SearchBox.PlaceholderText = expanded and "Search" or ""
    self.SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    if not expanded and self.SearchExpanded then
        self.SearchBox.Size = UDim2.fromOffset(math.min(190, width - 74), 30)
    else
        self.SearchBox.Size = UDim2.new(1, -16, 0, 30)
    end
    self.SearchBox.Position = UDim2.fromOffset(8, 8)
    self.SearchIcon.Visible = true
    for _, tab in ipairs(self.Tabs) do
        tab.TitleLabel.Visible = expanded
        tab.IconLabel.Position = expanded and UDim2.fromOffset(9, 0) or UDim2.fromOffset(16, 0)
        tab.IconLabel.Size = expanded and UDim2.fromOffset(22, 34) or UDim2.fromOffset(22, 34)
        tab.Button.Size = UDim2.new(1, 0, 0, expanded and 34 or 38)
    end
    if self.SidebarFooterLabel then
        self.SidebarFooterLabel.Visible = expanded
    end
    self.TwoColumn = width >= 730 and height >= 340
    for _, tab in ipairs(self.Tabs) do
        tab:ApplyColumns(self.TwoColumn)
    end
    if self.SidePanel and self.SidePanel.Parent then
        local isPresets = self.SidePanelKind == "Presets"
        local panelWidth = math.min(isPresets and 250 or 292, math.max(width - 76, 226))
        local openPosition: UDim2
        local closedPosition: UDim2
        if isPresets then
            local x = math.min(sidebarWidth + 9, math.max(width - panelWidth - 9, 9))
            openPosition = UDim2.fromOffset(x, Metrics.Header + 6)
            closedPosition = UDim2.fromOffset(x, Metrics.Header - 3)
        else
            openPosition = UDim2.new(1, -panelWidth - 7, 0, Metrics.Header + 6)
            closedPosition = UDim2.new(1, 5, 0, Metrics.Header + 6)
        end
        self.SidePanel.Size = UDim2.new(0, panelWidth, 1, -(Metrics.Header + 12))
        self.SidePanel.Position = openPosition
        self.SidePanelOpenPosition = openPosition
        self.SidePanelClosedPosition = closedPosition
    end
    for _, widget in ipairs(self.Widgets) do
        if widget.Clamp then
            widget:Clamp()
        end
    end
    local activePopup = self.ActivePopup
    if activePopup and activePopup.Frame.Parent and activePopup.Anchor.Parent then
        PopupController:Position(self, activePopup.Frame, activePopup.Anchor, activePopup.Gap, activePopup.Placement)
    end
end

function Window:SetVisible(visible: boolean): AnyTable
    local nextVisible = visible ~= false
    if self.Visible == nextVisible or self.Destroyed then
        return self
    end
    self.Visible = nextVisible
    dismissTooltip(self)
    PopupController:Close(self)
    self:_closeSidePanel(true)
    if nextVisible then
        self.Root.Visible = true
        self.Root.GroupTransparency = 1
        self.Root.Size = UDim2.fromOffset(self.Width * 0.97, self.Height * 0.97)
        tween(self.Root, {
            GroupTransparency = 0,
            Size = UDim2.fromOffset(self.Width, self.Height),
        }, Motion.Window, Enum.EasingStyle.Quart)
    else
        tween(self.Root, {
            GroupTransparency = 1,
            Size = UDim2.fromOffset(self.Width * 0.97, self.Height * 0.97),
        }, Motion.Window, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(Motion.Window, function()
            if not self.Visible and self.Root and self.Root.Parent then
                self.Root.Visible = false
            end
        end)
    end
    if self.ReopenButton then
        self.ReopenButton:SetVisible(not nextVisible)
    end
    return self
end

function Window:Toggle(): AnyTable
    return self:SetVisible(not self.Visible)
end

function Window:Minimize(): AnyTable
    return self:SetVisible(false)
end

function Window:Close(): AnyTable
    return self:SetVisible(false)
end

function Window:SetTheme(overrides: AnyTable): AnyTable
    self.Kronos:SetTheme(overrides)
    return self
end

function Window:SetAccent(color: Color3): AnyTable
    self.Kronos:SetAccent(color)
    return self
end

function Window:SetCompactNavigation(compact: boolean): AnyTable
    self.ForceCompactNavigation = compact == true
    self:ApplyResponsive()
    return self
end
function Window:_closeSidePanel(immediate: boolean?)
    if not self.SidePanel then
        return
    end
    PopupController:Close(self)
    self.CapturingToggleKey = nil
    local panel = self.SidePanel
    local dim = self.SideDim
    local closedPosition = self.SidePanelClosedPosition or UDim2.new(1, 12, 0, Metrics.Header)
    self.SidePanel = nil
    self.SideDim = nil
    self.SidePanelKind = nil
    self.SidePanelOpenPosition = nil
    self.SidePanelClosedPosition = nil
    ThemeController:UnbindTree(panel)
    if self.SideMaid then
        self.SideMaid:Cleanup()
        self.SideMaid = nil
    end
    if immediate then
        if dim and dim.Parent then
            dim:Destroy()
        end
        if panel.Parent then
            panel:Destroy()
        end
        return
    end
    tween(
        panel,
        { Position = closedPosition, GroupTransparency = 1 },
        Motion.Tab,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.In
    )
    if dim then
        tween(dim, { BackgroundTransparency = 1 }, Motion.Tab)
    end
    task.delay(Motion.Tab, function()
        if dim and dim.Parent then
            dim:Destroy()
        end
        if panel.Parent then
            panel:Destroy()
        end
    end)
end

function Window:_capturePreset(name: string): AnyTable
    local flags = {}
    for key, value in pairs(Kronos.Flags) do
        flags[key] = type(value) == "table" and copyArray(value) or value
    end
    return {
        Name = name,
        Accent = Theme.Accent,
        Flags = flags,
    }
end

function Window:ApplyPreset(preset: AnyTable)
    if typeof(preset.Accent) == "Color3" then
        self:SetAccent(preset.Accent)
    end
    if type(preset.Flags) == "table" then
        for key, value in pairs(preset.Flags) do
            local option = Kronos.Options[key]
            if option and type(option.Set) == "function" then
                option:Set(type(value) == "table" and copyArray(value) or value)
            end
        end
    end
    self:Notify({
        Title = "Preset applied",
        Content = tostring(preset.Name or "Preset"),
        Type = "success",
        Duration = 2.2,
    })
end

function Window:_openSidePanel(kind: string)
    self:_closeSidePanel(true)
    PopupController:Close(self)
    local sideMaid = Maid.new()
    self.SideMaid = sideMaid
    local dim = create("TextButton", {
        Name = "PanelDim",
        BackgroundColor3 = Theme.Overlay,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 170,
        Parent = self.Main,
    }) :: TextButton
    local panelWidth = math.min(kind == "Presets" and 250 or 292, math.max(self.Width - 76, 226))
    local openPosition: UDim2
    local closedPosition: UDim2
    if kind == "Presets" then
        local navigationWidth = self.ExpandedNavigation and Metrics.Sidebar or Metrics.CompactSidebar
        local x = math.min(navigationWidth + 9, math.max(self.Width - panelWidth - 9, 9))
        openPosition = UDim2.fromOffset(x, Metrics.Header + 6)
        closedPosition = UDim2.fromOffset(x, Metrics.Header - 3)
    else
        openPosition = UDim2.new(1, -panelWidth - 7, 0, Metrics.Header + 6)
        closedPosition = UDim2.new(1, 5, 0, Metrics.Header + 6)
    end
    local panel = create("CanvasGroup", {
        Name = kind .. "Panel",
        BackgroundColor3 = Theme.ElevatedSurface,
        BackgroundTransparency = 0.015,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Position = closedPosition,
        Size = UDim2.new(0, panelWidth, 1, -(Metrics.Header + 12)),
        ZIndex = 175,
        Parent = self.Main,
    }) :: CanvasGroup
    ThemeController:Bind(panel, "BackgroundColor3", "ElevatedSurface")
    local panelStroke = stroke(panel, Theme.Border, 0.25, 1)
    ThemeController:Bind(panelStroke, "Color", "Border")
    self.SidePanel = panel
    self.SideDim = dim
    self.SidePanelKind = kind
    self.SidePanelOpenPosition = openPosition
    self.SidePanelClosedPosition = closedPosition

    local header = create("Frame", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 52),
        ZIndex = 176,
        Parent = panel,
    }) :: Frame
    ThemeController:Bind(header, "BackgroundColor3", "Surface2")
    local panelDivider = create("Frame", {
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 177,
        Parent = header,
    }) :: Frame
    ThemeController:Bind(panelDivider, "BackgroundColor3", "Divider")
    local back = create("TextButton", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Text = "‹",
        TextColor3 = Theme.SubText,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        AutoButtonColor = false,
        Position = UDim2.fromOffset(10, 13),
        Size = UDim2.fromOffset(26, 26),
        Visible = false,
        ZIndex = 178,
        Parent = header,
    }) :: TextButton
    corner(back, 5)
    local headerTitle = makeText(header, kind == "Presets" and "Presets" or "Settings", 12, Theme.Text, "bold")
    headerTitle.Position = UDim2.fromOffset(14, 0)
    headerTitle.Size = UDim2.new(1, -54, 1, 0)
    headerTitle.ZIndex = 177
    local close = create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Theme.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        ZIndex = 178,
        Parent = header,
    }) :: TextButton

    local content = create("ScrollingFrame", {
        Name = "PanelContent",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 52),
        Size = UDim2.new(1, 0, 1, -52),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.1,
        ZIndex = 176,
        Parent = panel,
    }) :: ScrollingFrame
    ThemeController:Bind(content, "ScrollBarImageColor3", "Accent")
    local page = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -26, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 177,
        Parent = content,
    }) :: Frame
    local pageLayout = list(page, Enum.FillDirection.Vertical, 6)
    sideMaid:Give(pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.fromOffset(0, pageLayout.AbsoluteContentSize.Y + 25)
    end))
    local pageMaid = Maid.new()
    sideMaid:Give(function()
        pageMaid:Cleanup()
    end)
    local currentPage = "root"

    local function clearPage()
        self.CapturingToggleKey = nil
        pageMaid:Cleanup()
        pageMaid = Maid.new()
        for _, child in ipairs(page:GetChildren()) do
            if not child:IsA("UIListLayout") then
                ThemeController:UnbindTree(child)
                child:Destroy()
            end
        end
        content.CanvasPosition = Vector2.zero
    end

    local function addHeading(titleText: string, subtitleText: string?)
        local heading = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, subtitleText and 42 or 25),
            ZIndex = 178,
            Parent = page,
        }) :: Frame
        local titleLabel = makeText(heading, titleText, 11, Theme.Text, "bold")
        titleLabel.Size = UDim2.new(1, 0, 0, 20)
        titleLabel.ZIndex = 179
        if subtitleText then
            local subLabel = makeText(heading, subtitleText, 9, Theme.Muted)
            subLabel.Position = UDim2.fromOffset(0, 19)
            subLabel.Size = UDim2.new(1, 0, 0, 18)
            subLabel.ZIndex = 179
        end
    end

    local function addRow(titleText: string, subtitleText: string?, callback: (() -> ())?): TextButton
        local rowHeight = subtitleText and 46 or 36
        local row = create("TextButton", {
            BackgroundColor3 = Theme.Surface2,
            BackgroundTransparency = 0.38,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, rowHeight),
            ZIndex = 178,
            Parent = page,
        }) :: TextButton
        corner(row, 5)
        stroke(row, Theme.Border, 0.72, 1)
        local titleLabel = makeText(row, titleText, 10, Theme.Text, "bold")
        titleLabel.Position = UDim2.fromOffset(10, subtitleText and 4 or 0)
        titleLabel.Size = UDim2.new(1, -36, 0, subtitleText and 20 or rowHeight)
        titleLabel.ZIndex = 179
        if subtitleText then
            local subtitleLabel = makeText(row, subtitleText, 9, Theme.Muted)
            subtitleLabel.Position = UDim2.fromOffset(10, 22)
            subtitleLabel.Size = UDim2.new(1, -36, 0, 16)
            subtitleLabel.ZIndex = 179
        end
        if callback then
            local chevron = makeText(row, "›", 14, Theme.Muted, "bold")
            chevron.AnchorPoint = Vector2.new(1, 0.5)
            chevron.Position = UDim2.new(1, -9, 0.5, 0)
            chevron.Size = UDim2.fromOffset(18, 22)
            chevron.TextXAlignment = Enum.TextXAlignment.Center
            chevron.ZIndex = 179
            pageMaid:Give(row.Activated:Connect(callback))
        end
        pageMaid:Give(row.MouseEnter:Connect(function()
            tween(row, { BackgroundTransparency = 0.22 }, Motion.Hover)
        end))
        pageMaid:Give(row.MouseLeave:Connect(function()
            tween(row, { BackgroundTransparency = 0.38 }, Motion.Hover)
        end))
        return row
    end

    local showPage: (string) -> ()
    showPage = function(pageName: string)
        clearPage()
        currentPage = pageName
        back.Visible = pageName ~= "root"
        headerTitle.Position = pageName ~= "root" and UDim2.fromOffset(45, 0) or UDim2.fromOffset(14, 0)
        if kind == "Presets" then
            headerTitle.Text = pageName == "root" and "Presets" or pageName
        else
            headerTitle.Text = pageName == "root" and "Settings" or pageName
        end

        if kind == "Settings" and pageName == "root" then
            local profile = create("Frame", {
                BackgroundColor3 = Theme.Surface2,
                BackgroundTransparency = 0.28,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 67),
                ZIndex = 178,
                Parent = page,
            }) :: Frame
            corner(profile, 6)
            stroke(profile, Theme.Border, 0.62, 1)
            local avatar = create("ImageLabel", {
                BackgroundColor3 = Theme.Surface3,
                BorderSizePixel = 0,
                Image = "",
                Position = UDim2.fromOffset(10, 11),
                Size = UDim2.fromOffset(44, 44),
                ZIndex = 179,
                Parent = profile,
            }) :: ImageLabel
            corner(avatar, 22)
            local fallback = makeText(
                avatar,
                string.upper(string.sub(LocalPlayer and LocalPlayer.Name or "K", 1, 1)),
                15,
                Theme.Text,
                "bold"
            )
            fallback.Size = UDim2.fromScale(1, 1)
            fallback.TextXAlignment = Enum.TextXAlignment.Center
            fallback.ZIndex = 180
            local userName =
                makeText(profile, LocalPlayer and LocalPlayer.DisplayName or "Local Player", 11, Theme.Text, "bold")
            userName.Position = UDim2.fromOffset(64, 13)
            userName.Size = UDim2.new(1, -74, 0, 19)
            userName.ZIndex = 179
            local metadata =
                makeText(profile, LocalPlayer and ("@" .. LocalPlayer.Name) or "Profile unavailable", 9, Theme.Muted)
            metadata.Position = UDim2.fromOffset(64, 31)
            metadata.Size = UDim2.new(1, -74, 0, 17)
            metadata.ZIndex = 179
            if LocalPlayer then
                task.spawn(function()
                    local ok, image = pcall(
                        Players.GetUserThumbnailAsync,
                        Players,
                        LocalPlayer.UserId,
                        Enum.ThumbnailType.HeadShot,
                        Enum.ThumbnailSize.Size100x100
                    )
                    if ok and avatar.Parent then
                        avatar.Image = image
                        fallback.Visible = false
                    end
                end)
            end
            addHeading("Interface", "Appearance, input, and floating panels")
            addRow("Theme & accent", "Reference violet and semantic colors", function()
                showPage("Theme")
            end)
            addRow("Installed hotkeys", "Window and control bindings", function()
                showPage("Hotkeys")
            end)
            addRow("Interface behavior", "Navigation and notifications", function()
                showPage("Interface")
            end)
            addRow("Floating widgets", "Status, target, and keybind lists", function()
                showPage("Widgets")
            end)
        elseif kind == "Settings" and pageName == "Theme" then
            addHeading("Accent color", "Changes propagate without rebuilding controls")
            local palette = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 38),
                ZIndex = 178,
                Parent = page,
            }) :: Frame
            local paletteLayout = list(palette, Enum.FillDirection.Horizontal, 7)
            paletteLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            local colors = {
                Color3.fromRGB(143, 104, 255),
                Color3.fromRGB(105, 135, 255),
                Color3.fromRGB(89, 194, 145),
                Color3.fromRGB(218, 98, 126),
                Color3.fromRGB(224, 172, 88),
                Color3.fromRGB(204, 118, 255),
            }
            for _, color in ipairs(colors) do
                local chip = create("TextButton", {
                    BackgroundColor3 = color,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    Size = UDim2.fromOffset(31, 31),
                    ZIndex = 179,
                    Parent = palette,
                }) :: TextButton
                corner(chip, 5)
                stroke(chip, Theme.White, 0.68, 1)
                pageMaid:Give(chip.Activated:Connect(function()
                    self:SetAccent(color)
                end))
            end
            addRow("Restore reference violet", rgbToHex(Color3.fromRGB(143, 104, 255)), function()
                self:SetAccent(Color3.fromRGB(143, 104, 255))
            end)
        elseif kind == "Settings" and pageName == "Hotkeys" then
            addHeading("Window hotkey", "Click the row, then press a keyboard key")
            local row = addRow("Toggle interface", tostring(self.ToggleKey.Name), nil)
            local keyLabel = makeText(row, self.ToggleKey.Name, 9, Theme.Accent, "bold")
            keyLabel.AnchorPoint = Vector2.new(1, 0.5)
            keyLabel.Position = UDim2.new(1, -9, 0.5, 0)
            keyLabel.Size = UDim2.fromOffset(80, 20)
            keyLabel.TextXAlignment = Enum.TextXAlignment.Right
            keyLabel.ZIndex = 180
            pageMaid:Give(row.Activated:Connect(function()
                keyLabel.Text = "..."
                self.CapturingToggleKey = { Label = keyLabel }
            end))
            addHeading("Control bindings", "Keybind rows update the floating list live")
            for _, keybind in ipairs(self.Keybinds) do
                addRow(keybind.DisplayName, tostring(keybind.Value) .. "  ·  " .. keybind.Mode, function()
                    self:_closeSidePanel(false)
                    keybind:BeginListening()
                end)
            end
        elseif kind == "Settings" and pageName == "Interface" then
            addHeading("Layout", "Compact geometry is preserved at every breakpoint")
            local navRow = addRow("Compact navigation", self.ForceCompactNavigation and "Enabled" or "Automatic", nil)
            local navState = makeText(navRow, self.ForceCompactNavigation and "ON" or "AUTO", 9, Theme.Accent, "bold")
            navState.AnchorPoint = Vector2.new(1, 0.5)
            navState.Position = UDim2.new(1, -9, 0.5, 0)
            navState.Size = UDim2.fromOffset(50, 20)
            navState.TextXAlignment = Enum.TextXAlignment.Right
            navState.ZIndex = 180
            pageMaid:Give(navRow.Activated:Connect(function()
                self:SetCompactNavigation(not self.ForceCompactNavigation)
                navState.Text = self.ForceCompactNavigation and "ON" or "AUTO"
            end))
            addRow("Notification preview", "Show the compact stacked notification", function()
                self:Notify({ Title = "Kronos", Content = "Interface settings are active.", Type = "success" })
            end)
        elseif kind == "Settings" and pageName == "Widgets" then
            addHeading("Floating widgets", "Each panel is draggable and independently hideable")
            for _, widget in ipairs(self.Widgets) do
                if widget ~= self.ReopenButton then
                    local row = addRow(widget.Title or widget.Root.Name, widget.Visible and "Visible" or "Hidden", nil)
                    local state = makeText(
                        row,
                        widget.Visible and "ON" or "OFF",
                        9,
                        widget.Visible and Theme.Accent or Theme.Muted,
                        "bold"
                    )
                    state.AnchorPoint = Vector2.new(1, 0.5)
                    state.Position = UDim2.new(1, -9, 0.5, 0)
                    state.Size = UDim2.fromOffset(36, 20)
                    state.TextXAlignment = Enum.TextXAlignment.Right
                    state.ZIndex = 180
                    pageMaid:Give(row.Activated:Connect(function()
                        widget:SetVisible(not widget.Visible)
                        state.Text = widget.Visible and "ON" or "OFF"
                        state.TextColor3 = widget.Visible and Theme.Accent or Theme.Muted
                    end))
                end
            end
        elseif kind == "Presets" then
            addHeading("Configuration presets", "Stored for the current execution")
            local toolbar = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 31),
                ZIndex = 178,
                Parent = page,
            }) :: Frame
            local presetSearch = create("TextBox", {
                BackgroundColor3 = Theme.Surface3,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                Text = "",
                PlaceholderText = "Search presets",
                PlaceholderColor3 = Theme.Muted,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamMedium,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -37, 1, 0),
                ZIndex = 179,
                Parent = toolbar,
            }) :: TextBox
            corner(presetSearch, 5)
            padding(presetSearch, 8, 0, 8, 0)
            stroke(presetSearch, Theme.Border, 0.58, 1)
            local addPreset = create("TextButton", {
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Text = "+",
                TextColor3 = Theme.White,
                Font = Enum.Font.GothamBold,
                TextSize = 15,
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.fromOffset(31, 31),
                ZIndex = 179,
                Parent = toolbar,
            }) :: TextButton
            corner(addPreset, 5)
            ThemeController:Bind(addPreset, "BackgroundColor3", "Accent")

            local presetList = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 178,
                Parent = page,
            }) :: Frame
            list(presetList, Enum.FillDirection.Vertical, 5)
            local presetMaid = Maid.new()
            pageMaid:Give(function()
                presetMaid:Cleanup()
            end)

            local function renderPresets(query: string?)
                presetMaid:Cleanup()
                presetMaid = Maid.new()
                for _, child in ipairs(presetList:GetChildren()) do
                    if not child:IsA("UIListLayout") then
                        child:Destroy()
                    end
                end
                local normalized = string.lower(query or "")
                local shown = 0
                for index, preset in ipairs(self.Presets) do
                    local presetName = tostring(preset.Name)
                    if normalized == "" or string.find(string.lower(presetName), normalized, 1, true) then
                        shown += 1
                        local presetRow = create("TextButton", {
                            BackgroundColor3 = Theme.Surface2,
                            BackgroundTransparency = 0.38,
                            BorderSizePixel = 0,
                            Text = "",
                            AutoButtonColor = false,
                            Size = UDim2.new(1, 0, 0, 36),
                            LayoutOrder = index,
                            ZIndex = 178,
                            Parent = presetList,
                        }) :: TextButton
                        corner(presetRow, 5)
                        stroke(presetRow, Theme.Border, 0.72, 1)
                        local swatch = create("Frame", {
                            BackgroundColor3 = preset.Accent or Theme.Accent,
                            BorderSizePixel = 0,
                            Position = UDim2.fromOffset(9, 11),
                            Size = UDim2.fromOffset(14, 14),
                            ZIndex = 179,
                            Parent = presetRow,
                        }) :: Frame
                        corner(swatch, 4)
                        local presetLabel = makeText(presetRow, presetName, 10, Theme.Text, "bold")
                        presetLabel.Position = UDim2.fromOffset(30, 0)
                        presetLabel.Size = UDim2.new(1, -88, 1, 0)
                        presetLabel.ZIndex = 179
                        local applyLabel = makeText(presetRow, "Apply", 8, Theme.Muted, "bold")
                        applyLabel.AnchorPoint = Vector2.new(1, 0.5)
                        applyLabel.Position = UDim2.new(1, -8, 0.5, 0)
                        applyLabel.Size = UDim2.fromOffset(42, 20)
                        applyLabel.TextXAlignment = Enum.TextXAlignment.Right
                        applyLabel.ZIndex = 179
                        presetMaid:Give(presetRow.Activated:Connect(function()
                            self:ApplyPreset(preset)
                        end))
                        presetMaid:Give(presetRow.MouseEnter:Connect(function()
                            tween(presetRow, { BackgroundTransparency = 0.22 }, Motion.Hover)
                        end))
                        presetMaid:Give(presetRow.MouseLeave:Connect(function()
                            tween(presetRow, { BackgroundTransparency = 0.38 }, Motion.Hover)
                        end))
                        if index > 2 then
                            applyLabel.Visible = false
                            local delete = create("TextButton", {
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Text = "×",
                                TextColor3 = Theme.Error,
                                Font = Enum.Font.GothamBold,
                                TextSize = 13,
                                AutoButtonColor = false,
                                AnchorPoint = Vector2.new(1, 0.5),
                                Position = UDim2.new(1, -6, 0.5, 0),
                                Size = UDim2.fromOffset(25, 25),
                                ZIndex = 180,
                                Parent = presetRow,
                            }) :: TextButton
                            presetMaid:Give(delete.Activated:Connect(function()
                                table.remove(self.Presets, index)
                                renderPresets(presetSearch.Text)
                            end))
                        end
                    end
                end
                if shown == 0 then
                    local empty = makeText(presetList, "No matching presets", 9, Theme.Muted, "bold")
                    empty.Size = UDim2.new(1, 0, 0, 30)
                    empty.TextXAlignment = Enum.TextXAlignment.Center
                end
            end

            pageMaid:Give(presetSearch:GetPropertyChangedSignal("Text"):Connect(function()
                renderPresets(presetSearch.Text)
            end))
            pageMaid:Give(addPreset.Activated:Connect(function()
                if self.ActivePopup and self.ActivePopup.Anchor == addPreset then
                    PopupController:Close(self)
                    return
                end
                local createPopup = create("CanvasGroup", {
                    Name = "PresetCreatePopup",
                    BackgroundColor3 = Theme.ElevatedSurface,
                    BackgroundTransparency = 0.02,
                    BorderSizePixel = 0,
                    GroupTransparency = 1,
                    Size = UDim2.fromOffset(220, 84),
                    Visible = false,
                    ZIndex = 780,
                }) :: CanvasGroup
                corner(createPopup, Metrics.PopupRadius)
                stroke(createPopup, Theme.Border, 0.25, 1)
                padding(createPopup, 8, 8, 8, 8)
                local popupMaid = PopupController:Open(self, createPopup, addPreset, 6, "Side")
                local nameBox = create("TextBox", {
                    BackgroundColor3 = Theme.Surface3,
                    BackgroundTransparency = 0.08,
                    BorderSizePixel = 0,
                    ClearTextOnFocus = false,
                    Text = "",
                    PlaceholderText = "Preset name",
                    PlaceholderColor3 = Theme.Muted,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 0, 29),
                    ZIndex = 782,
                    Parent = createPopup,
                }) :: TextBox
                corner(nameBox, 5)
                padding(nameBox, 8, 0, 8, 0)
                stroke(nameBox, Theme.Border, 0.58, 1)
                local save = create("TextButton", {
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Text = "Create",
                    TextColor3 = Theme.White,
                    Font = Enum.Font.GothamBold,
                    TextSize = 9,
                    AutoButtonColor = false,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 0, 29),
                    ZIndex = 782,
                    Parent = createPopup,
                }) :: TextButton
                corner(save, 5)
                ThemeController:Bind(save, "BackgroundColor3", "Accent")
                local function savePreset()
                    local presetName = string.match(nameBox.Text, "^%s*(.-)%s*$") or ""
                    presetName = string.sub(presetName, 1, 32)
                    if presetName == "" then
                        self:Notify({ Title = "Preset name required", Type = "warning", Duration = 2 })
                        return
                    end
                    for _, preset in ipairs(self.Presets) do
                        if string.lower(tostring(preset.Name)) == string.lower(presetName) then
                            self:Notify({ Title = "Preset already exists", Type = "warning", Duration = 2 })
                            return
                        end
                    end
                    table.insert(self.Presets, self:_capturePreset(presetName))
                    PopupController:Close(self)
                    renderPresets(presetSearch.Text)
                end
                popupMaid:Give(save.Activated:Connect(savePreset))
                popupMaid:Give(nameBox.FocusLost:Connect(function(enterPressed)
                    if enterPressed then
                        savePreset()
                    end
                end))
                task.defer(function()
                    if createPopup.Parent and self.ActivePopup and self.ActivePopup.Frame == createPopup then
                        tween(createPopup, { GroupTransparency = 0 }, Motion.Dropdown)
                        nameBox:CaptureFocus()
                    end
                end)
            end))
            renderPresets("")
        end
    end

    sideMaid:Give(dim.Activated:Connect(function()
        self:_closeSidePanel(false)
    end))
    sideMaid:Give(close.Activated:Connect(function()
        self:_closeSidePanel(false)
    end))
    sideMaid:Give(back.Activated:Connect(function()
        if currentPage == "root" then
            self:_closeSidePanel(false)
        else
            showPage("root")
        end
    end))
    showPage("root")
    tween(dim, { BackgroundTransparency = 0.36 }, Motion.Tab)
    tween(panel, { Position = openPosition, GroupTransparency = 0 }, Motion.Tab)
end

function Window:OpenSettings(): AnyTable
    self:_openSidePanel("Settings")
    return self
end

function Window:OpenPresets(): AnyTable
    self:_openSidePanel("Presets")
    return self
end

function FloatingWidgetController:Create(window: AnyTable, config: AnyTable): AnyTable
    local widget: AnyTable = {
        Window = window,
        Connections = {},
        Visible = config.Visible ~= false,
        Title = tostring(config.Title or "Widget"),
        Alive = true,
        DesiredWidth = (config.Size and config.Size.X.Offset) or 246,
        DesiredHeight = (config.Size and config.Size.Y.Offset) or 120,
    }
    local root = create("CanvasGroup", {
        Name = config.Name or "FloatingWidget",
        BackgroundColor3 = Theme.ElevatedSurface,
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Position = config.Position or UDim2.fromOffset(14, 80),
        Size = config.Size or UDim2.fromOffset(246, 120),
        ClipsDescendants = true,
        Visible = widget.Visible,
        ZIndex = config.ZIndex or 500,
        Parent = Kronos.GUI,
    }) :: CanvasGroup
    ThemeController:Bind(root, "BackgroundColor3", "ElevatedSurface")
    corner(root, Metrics.Radius)
    local rootStroke = stroke(root, Theme.Border, 0.36, 1)
    ThemeController:Bind(rootStroke, "Color", "Border")
    local header = create("Frame", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Active = true,
        Size = UDim2.new(1, 0, 0, 31),
        ZIndex = root.ZIndex + 1,
        Parent = root,
    }) :: Frame
    local marker = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.fromOffset(2, 15),
        ZIndex = root.ZIndex + 2,
        Parent = header,
    }) :: Frame
    corner(marker, 1)
    ThemeController:Bind(marker, "BackgroundColor3", "Accent")
    local title = makeText(header, widget.Title, 10, Theme.Text, "bold")
    title.Position = UDim2.fromOffset(10, 0)
    title.Size = UDim2.new(1, -34, 1, 0)
    title.ZIndex = root.ZIndex + 2
    local hide = create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "⌖",
        TextColor3 = Theme.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -5, 0.5, 0),
        Size = UDim2.fromOffset(24, 24),
        ZIndex = root.ZIndex + 3,
        Parent = header,
    }) :: TextButton
    ThemeController:Bind(header, "BackgroundColor3", "Surface2")
    local body = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 31),
        Size = UDim2.new(1, 0, 1, -31),
        ZIndex = root.ZIndex + 1,
        Parent = root,
    }) :: Frame
    widget.Root = root
    widget.Header = header
    widget.Body = body
    function widget:SetVisible(visible: boolean): AnyTable
        self.Visible = visible ~= false
        if self.Visible then
            root.Visible = true
            root.GroupTransparency = 1
            tween(root, { GroupTransparency = 0 }, Motion.Window)
        else
            tween(root, { GroupTransparency = 1 }, Motion.Tab)
            task.delay(Motion.Tab, function()
                if not self.Visible and root.Parent then
                    root.Visible = false
                end
            end)
        end
        return self
    end
    function widget:Clamp()
        if root.Parent then
            local viewport = viewportSize()
            root.Size = UDim2.fromOffset(
                math.min(self.DesiredWidth, math.max(viewport.X - Metrics.SafePadding * 2, 220)),
                math.min(self.DesiredHeight, math.max(viewport.Y - Metrics.SafePadding * 2, 72))
            )
            local anchorPoint = root.AbsolutePosition + root.AbsoluteSize * root.AnchorPoint
            local clamped = clampGuiCenter(root, anchorPoint)
            root.Position = UDim2.fromOffset(clamped.X, clamped.Y)
        end
    end
    function widget:Resize(width: number, height: number)
        width = math.max(finiteNumber(width, self.DesiredWidth), 40)
        height = math.max(finiteNumber(height, self.DesiredHeight), 40)
        self.DesiredWidth = width
        self.DesiredHeight = height
        self.ResizeGeneration = (self.ResizeGeneration or 0) + 1
        local generation = self.ResizeGeneration
        local viewport = viewportSize()
        tween(root, {
            Size = UDim2.fromOffset(
                math.min(width, math.max(viewport.X - Metrics.SafePadding * 2, 220)),
                math.min(height, math.max(viewport.Y - Metrics.SafePadding * 2, 72))
            ),
        }, Motion.Tab)
        task.delay(Motion.Tab, function()
            if self.Alive and self.ResizeGeneration == generation and root.Parent then
                self:Clamp()
            end
        end)
    end
    function widget:Destroy()
        self.Alive = false
        disconnectAll(self)
        if root.Parent then
            ThemeController:UnbindTree(root)
            root:Destroy()
        end
        local index = table.find(window.Widgets, self)
        if index then
            table.remove(window.Widgets, index)
        end
        local globalIndex = table.find(Kronos.Widgets, self)
        if globalIndex then
            table.remove(Kronos.Widgets, globalIndex)
        end
    end
    addConnection(
        widget,
        hide.Activated:Connect(function()
            widget:SetVisible(false)
        end)
    )
    DragController:Bind(widget, header, root)
    table.insert(window.Widgets, widget)
    table.insert(Kronos.Widgets, widget)
    widget:Clamp()
    return widget
end

function Window:CreateTargetList(config: AnyTable?): AnyTable
    config = config or {}
    local widget = FloatingWidgetController:Create(self, {
        Name = "TargetList",
        Title = config.Title or "Target List",
        Size = UDim2.fromOffset(410, 130),
        Position = config.Position or UDim2.fromOffset(14, 86),
        Visible = config.Visible ~= false,
    })
    local avatar = create("ImageLabel", {
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Image = "",
        Position = UDim2.fromOffset(10, 12),
        Size = UDim2.fromOffset(43, 43),
        ZIndex = 503,
        Parent = widget.Body,
    }) :: ImageLabel
    corner(avatar, 5)
    local fallback = makeText(avatar, "—", 14, Theme.Muted, "bold")
    fallback.Size = UDim2.fromScale(1, 1)
    fallback.TextXAlignment = Enum.TextXAlignment.Center
    fallback.ZIndex = 504
    local nameLabel = makeText(widget.Body, "No target", 10, Theme.Text, "bold")
    nameLabel.Position = UDim2.fromOffset(62, 10)
    nameLabel.Size = UDim2.new(1, -72, 0, 18)
    nameLabel.ZIndex = 503
    local healthLabel = makeText(widget.Body, "Waiting", 9, Theme.Muted)
    healthLabel.Position = UDim2.fromOffset(62, 28)
    healthLabel.Size = UDim2.new(1, -72, 0, 17)
    healthLabel.ZIndex = 503
    local healthTrack = create("Frame", {
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(62, 50),
        Size = UDim2.new(1, -72, 0, 5),
        ZIndex = 503,
        Parent = widget.Body,
    }) :: Frame
    ThemeController:Bind(healthTrack, "BackgroundColor3", "Surface3")
    corner(healthTrack, 3)
    local healthFill = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        ZIndex = 504,
        Parent = healthTrack,
    }) :: Frame
    corner(healthFill, 3)
    ThemeController:Bind(healthFill, "BackgroundColor3", "Accent")
    function widget:SetTarget(name: string?, health: number?, maximumHealth: number?, userId: number?)
        self.TargetGeneration = (self.TargetGeneration or 0) + 1
        local generation = self.TargetGeneration
        if not name then
            nameLabel.Text = "No target"
            healthLabel.Text = "Waiting"
            fallback.Text = "—"
            fallback.Visible = true
            avatar.Image = ""
            tween(healthFill, { Size = UDim2.fromScale(0, 1) }, Motion.Toggle)
            return
        end
        local current = math.max(finiteNumber(health, 0), 0)
        local maximum = math.max(finiteNumber(maximumHealth, 100), 1)
        local ratio = math.clamp(current / maximum, 0, 1)
        nameLabel.Text = tostring(name)
        healthLabel.Text = string.format("%d / %d HP", math.floor(current + 0.5), math.floor(maximum + 0.5))
        fallback.Text = string.upper(string.sub(tostring(name), 1, 1))
        fallback.Visible = true
        tween(healthFill, { Size = UDim2.fromScale(ratio, 1) }, Motion.Health)
        if userId and userId > 0 then
            task.spawn(function()
                local ok, image = pcall(
                    Players.GetUserThumbnailAsync,
                    Players,
                    userId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size100x100
                )
                if ok and widget.Alive and widget.TargetGeneration == generation and avatar.Parent then
                    avatar.Image = image
                    fallback.Visible = false
                end
            end)
        end
    end
    function widget:Refresh()
        healthFill.BackgroundColor3 = Theme.Accent
    end
    self.TargetList = widget
    return widget
end

function Window:CreateKeybindList(config: AnyTable?): AnyTable
    config = config or {}
    local widget = FloatingWidgetController:Create(self, {
        Name = "KeybindList",
        Title = config.Title or "Keybind List",
        Size = UDim2.fromOffset(410, 87),
        Position = config.Position or UDim2.new(0.5, -205, 0, 76),
        Visible = config.Visible ~= false,
    })
    local columnHeader = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 4),
        Size = UDim2.new(1, -16, 0, 19),
        ZIndex = 503,
        Parent = widget.Body,
    }) :: Frame
    local function headerLabel(text: string, position: UDim2, size: UDim2, alignment: Enum.TextXAlignment)
        local label = makeText(columnHeader, text, 8, Theme.Muted, "bold")
        label.Position = position
        label.Size = size
        label.TextXAlignment = alignment
        label.ZIndex = 504
    end
    headerLabel("FUNCTION", UDim2.fromOffset(0, 0), UDim2.new(0.5, 0, 1, 0), Enum.TextXAlignment.Left)
    headerLabel("HOTKEY", UDim2.new(0.5, 0, 0, 0), UDim2.new(0.28, 0, 1, 0), Enum.TextXAlignment.Center)
    headerLabel("STATE", UDim2.new(0.78, 0, 0, 0), UDim2.new(0.22, 0, 1, 0), Enum.TextXAlignment.Right)
    local rows = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 24),
        Size = UDim2.new(1, -16, 1, -28),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 1,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.2,
        ZIndex = 503,
        Parent = widget.Body,
    }) :: ScrollingFrame
    ThemeController:Bind(rows, "ScrollBarImageColor3", "Accent")
    local rowHolder = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -3, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 503,
        Parent = rows,
    }) :: Frame
    local rowsLayout = list(rowHolder, Enum.FillDirection.Vertical, 2)
    addConnection(
        widget,
        rowsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            rows.CanvasSize = UDim2.fromOffset(0, rowsLayout.AbsoluteContentSize.Y)
        end)
    )
    function widget:Refresh()
        for _, child in ipairs(rowHolder:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        local count = 0
        for _, keybind in ipairs(self.Window.Keybinds) do
            if
                keybind.Instance
                and keybind.Instance.Parent
                and keybind.Value ~= "NONE"
                and keybind.ShowInList ~= false
            then
                count += 1
                local row = create("Frame", {
                    BackgroundColor3 = Theme.Surface2,
                    BackgroundTransparency = 0.55,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 22),
                    LayoutOrder = count,
                    ZIndex = 504,
                    Parent = rowHolder,
                }) :: Frame
                corner(row, 4)
                local function valueLabel(
                    text: string,
                    position: UDim2,
                    size: UDim2,
                    alignment: Enum.TextXAlignment,
                    color: Color3
                )
                    local label = makeText(row, text, 9, color, "bold")
                    label.Position = position
                    label.Size = size
                    label.TextXAlignment = alignment
                    label.ZIndex = 505
                end
                valueLabel(
                    keybind.DisplayName,
                    UDim2.fromOffset(7, 0),
                    UDim2.new(0.5, -7, 1, 0),
                    Enum.TextXAlignment.Left,
                    Theme.SubText
                )
                valueLabel(
                    tostring(keybind.Value),
                    UDim2.new(0.5, 0, 0, 0),
                    UDim2.new(0.28, 0, 1, 0),
                    Enum.TextXAlignment.Center,
                    Theme.Text
                )
                valueLabel(
                    keybind.Active and "ON" or "OFF",
                    UDim2.new(0.78, 0, 0, 0),
                    UDim2.new(0.22, -6, 1, 0),
                    Enum.TextXAlignment.Right,
                    keybind.Active and Theme.Accent or Theme.Muted
                )
                row.BackgroundTransparency = 1
                tween(row, { BackgroundTransparency = 0.55 }, Motion.KeybindRow)
            end
        end
        local bodyHeight = 31 + math.max(count, 1) * 24
        local finalHeight = math.clamp(bodyHeight + 31, 80, 202)
        widget:Resize(410, finalHeight)
        rows.Visible = true
        columnHeader.Visible = count > 0
        if count == 0 then
            local empty = makeText(rowHolder, "No active bindings", 9, Theme.Muted)
            empty.Name = "Empty"
            empty.Size = UDim2.new(1, 0, 0, 24)
            empty.TextXAlignment = Enum.TextXAlignment.Center
        end
    end
    self.KeybindWidget = widget
    widget:Refresh()
    return widget
end

function Window:CreateStatusStrip(config: AnyTable?): AnyTable
    config = config or {}
    local widget: AnyTable = {
        Window = self,
        Connections = {},
        Visible = config.Visible ~= false,
        Alive = true,
        Title = "Status Strip",
        Fields = { Kronos = true, FPS = true, Ping = true, Time = true },
        DesiredWidth = 318,
    }
    local root = create("CanvasGroup", {
        Name = "StatusStrip",
        BackgroundColor3 = Theme.ElevatedSurface,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = config.Position or UDim2.new(1, -14, 0, 14),
        Size = UDim2.fromOffset(318, 30),
        ClipsDescendants = true,
        Visible = widget.Visible,
        ZIndex = 540,
        Parent = Kronos.GUI,
    }) :: CanvasGroup
    ThemeController:Bind(root, "BackgroundColor3", "ElevatedSurface")
    corner(root, 5)
    stroke(root, Theme.Border, 0.36, 1)
    local marker = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 7),
        Size = UDim2.fromOffset(2, 16),
        ZIndex = 541,
        Parent = root,
    }) :: Frame
    ThemeController:Bind(marker, "BackgroundColor3", "Accent")
    local dragHandle = create("Frame", {
        BackgroundTransparency = 1,
        Active = true,
        Size = UDim2.new(1, -27, 1, 0),
        ZIndex = 542,
        Parent = root,
    }) :: Frame
    local fieldHolder = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -38, 1, 0),
        ZIndex = 542,
        Parent = root,
    }) :: Frame
    local fieldLayout = list(fieldHolder, Enum.FillDirection.Horizontal, 0)
    fieldLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    local labels: AnyTable = {}
    local function addField(name: string, width: number, color: Color3)
        local label = makeText(fieldHolder, "", 9, color, "bold")
        label.Name = name
        label.Size = UDim2.fromOffset(width, 30)
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.ZIndex = 543
        labels[name] = label
    end
    addField("Kronos", 84, Theme.Text)
    addField("FPS", 58, Theme.SubText)
    addField("Ping", 72, Theme.SubText)
    addField("Time", 66, Theme.SubText)
    local menu = create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "⋮",
        TextColor3 = Theme.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -3, 0.5, 0),
        Size = UDim2.fromOffset(25, 26),
        ZIndex = 544,
        Parent = root,
    }) :: TextButton
    widget.Root = root
    function widget:SetVisible(visible: boolean): AnyTable
        self.Visible = visible ~= false
        root.Visible = self.Visible
        return self
    end
    function widget:Clamp()
        root.Size =
            UDim2.fromOffset(math.min(self.DesiredWidth, math.max(viewportSize().X - Metrics.SafePadding * 2, 150)), 30)
        local anchorPoint = root.AbsolutePosition + root.AbsoluteSize * root.AnchorPoint
        local clamped = clampGuiCenter(root, anchorPoint)
        root.Position = UDim2.fromOffset(clamped.X, clamped.Y)
    end
    function widget:Refresh()
        marker.BackgroundColor3 = Theme.Accent
    end
    function widget:Destroy()
        self.Alive = false
        disconnectAll(self)
        if root.Parent then
            ThemeController:UnbindTree(root)
            root:Destroy()
        end
        removeArrayValue(self.Window.Widgets, self)
        removeArrayValue(Kronos.Widgets, self)
    end
    local function layoutFields()
        local width = 10
        for name, label in pairs(labels) do
            label.Visible = widget.Fields[name] == true
            if label.Visible then
                width += label.Size.X.Offset
            end
        end
        widget.DesiredWidth = width + 30
        widget:Clamp()
    end
    addConnection(
        widget,
        menu.Activated:Connect(function()
            local popup = create("CanvasGroup", {
                Name = "StatusFieldsPopup",
                BackgroundColor3 = Theme.ElevatedSurface,
                BackgroundTransparency = 0.02,
                BorderSizePixel = 0,
                GroupTransparency = 1,
                Size = UDim2.fromOffset(142, 128),
                Visible = false,
                ZIndex = 760,
            }) :: CanvasGroup
            corner(popup, Metrics.PopupRadius)
            stroke(popup, Theme.Border, 0.26, 1)
            padding(popup, 6, 6, 6, 6)
            local popupLayout = list(popup, Enum.FillDirection.Vertical, 3)
            local popupMaid = PopupController:Open(self, popup, menu, 5)
            for _, name in ipairs({ "Kronos", "FPS", "Ping", "Time" }) do
                local choice = create("TextButton", {
                    BackgroundColor3 = Theme.Surface2,
                    BackgroundTransparency = 0.42,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    Size = UDim2.new(1, 0, 0, 26),
                    ZIndex = 762,
                    Parent = popup,
                }) :: TextButton
                corner(choice, 4)
                local choiceLabel = makeText(choice, name, 9, Theme.SubText, "bold")
                choiceLabel.Position = UDim2.fromOffset(8, 0)
                choiceLabel.Size = UDim2.new(1, -34, 1, 0)
                choiceLabel.ZIndex = 763
                local check = makeText(choice, widget.Fields[name] and "✓" or "", 10, Theme.Accent, "bold")
                check.AnchorPoint = Vector2.new(1, 0.5)
                check.Position = UDim2.new(1, -7, 0.5, 0)
                check.Size = UDim2.fromOffset(18, 18)
                check.TextXAlignment = Enum.TextXAlignment.Center
                check.ZIndex = 763
                popupMaid:Give(choice.Activated:Connect(function()
                    widget.Fields[name] = not widget.Fields[name]
                    check.Text = widget.Fields[name] and "✓" or ""
                    layoutFields()
                    PopupController:Position(self, popup, menu, 5)
                end))
            end
            task.defer(function()
                if popup.Parent and self.ActivePopup and self.ActivePopup.Frame == popup then
                    tween(popup, { GroupTransparency = 0 }, Motion.Dropdown)
                end
            end)
        end)
    )
    DragController:Bind(widget, dragHandle, root)
    table.insert(self.Widgets, widget)
    table.insert(Kronos.Widgets, widget)
    layoutFields()
    task.spawn(function()
        while widget.Alive and root.Parent do
            local started = os.clock()
            RunService.Heartbeat:Wait()
            if not widget.Alive or not root.Parent then
                break
            end
            local elapsed = math.max(os.clock() - started, 1 / 240)
            local fps = math.clamp(math.floor(1 / elapsed + 0.5), 0, 999)
            local ping = "—"
            pcall(function()
                local network = (Stats :: any).Network
                local item = network and network.ServerStatsItem and network.ServerStatsItem["Data Ping"]
                if item then
                    ping = item:GetValueString()
                end
            end)
            labels.Kronos.Text = "KRONOS  " .. tostring(game.PlaceId)
            labels.FPS.Text = tostring(fps) .. " FPS"
            labels.Ping.Text = ping
            labels.Time.Text = os.date("%H:%M")
            task.wait(0.75)
        end
    end)
    self.StatusStrip = widget
    return widget
end

function Window:CreateReopenButton(config: AnyTable?): AnyTable
    config = config or {}
    local widget: AnyTable = {
        Window = self,
        Connections = {},
        Visible = false,
        Alive = true,
        Title = "Reopen Button",
    }
    local root = create("CanvasGroup", {
        Name = "KronosReopen",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = config.Position or UDim2.new(1, -55, 1, -70),
        Size = UDim2.fromOffset(40, 40),
        Visible = false,
        ZIndex = 900,
        Parent = Kronos.GUI,
    }) :: CanvasGroup
    local button = create("TextButton", {
        BackgroundColor3 = Theme.ElevatedSurface,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Text = "K",
        TextColor3 = Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 901,
        Parent = root,
    }) :: TextButton
    ThemeController:Bind(button, "BackgroundColor3", "ElevatedSurface")
    corner(button, 10)
    local buttonStroke = stroke(button, Theme.Accent, 0.18, 1)
    ThemeController:Bind(button, "TextColor3", "Accent")
    ThemeController:Bind(buttonStroke, "Color", "Accent")
    widget.Root = root
    function widget:SetVisible(visible: boolean): AnyTable
        self.Visible = visible ~= false
        root.Visible = self.Visible
        if self.Visible then
            root.GroupTransparency = 1
            tween(root, { GroupTransparency = 0 }, Motion.Window)
        end
        return self
    end
    function widget:Clamp()
        local anchorPoint = root.AbsolutePosition + root.AbsoluteSize * root.AnchorPoint
        local clamped = clampGuiCenter(root, anchorPoint)
        root.Position = UDim2.fromOffset(clamped.X, clamped.Y)
    end
    function widget:Destroy()
        self.Alive = false
        disconnectAll(self)
        if root.Parent then
            ThemeController:UnbindTree(root)
            root:Destroy()
        end
        removeArrayValue(self.Window.Widgets, self)
        removeArrayValue(Kronos.Widgets, self)
    end
    local moved = false
    local pressInput: InputObject? = nil
    addConnection(
        widget,
        button.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                moved = false
                pressInput = input
                tween(root, { Size = UDim2.fromOffset(36, 36) }, Motion.Press)
            end
        end)
    )
    DragController:Bind(widget, button, root, function()
        moved = true
    end)
    addConnection(
        widget,
        button.Activated:Connect(function()
            if moved then
                moved = false
                return
            end
            self:SetVisible(true)
        end)
    )
    addConnection(
        widget,
        UserInputService.InputEnded:Connect(function(input)
            if input == pressInput then
                pressInput = nil
                tween(root, { Size = UDim2.fromOffset(40, 40) }, Motion.Press)
            end
        end)
    )
    addConnection(
        widget,
        button.MouseEnter:Connect(function()
            tween(button, { BackgroundColor3 = Theme.HoverSurface, BackgroundTransparency = 0 }, Motion.Hover)
        end)
    )
    addConnection(
        widget,
        button.MouseLeave:Connect(function()
            tween(button, { BackgroundColor3 = Theme.ElevatedSurface, BackgroundTransparency = 0.02 }, Motion.Hover)
        end)
    )
    table.insert(self.Widgets, widget)
    table.insert(Kronos.Widgets, widget)
    self.ReopenButton = widget
    return widget
end

function Window:_bindInput()
    addConnection(
        self,
        UserInputService.InputBegan:Connect(function(input, processed)
            if self.CapturingToggleKey then
                local capture = self.CapturingToggleKey
                if input.KeyCode == Enum.KeyCode.Escape then
                    if capture.Label and capture.Label.Parent then
                        capture.Label.Text = self.ToggleKey.Name
                    end
                    self.CapturingToggleKey = nil
                elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                    self.ToggleKey = input.KeyCode
                    if capture.Label and capture.Label.Parent then
                        capture.Label.Text = input.KeyCode.Name
                    end
                    self.CapturingToggleKey = nil
                end
                return
            end
            if self.ListeningKeybind then
                self.ListeningKeybind:Capture(input)
                return
            end
            if input.KeyCode == Enum.KeyCode.Escape then
                if self.ActivePopup then
                    PopupController:Close(self)
                elseif self.SidePanel then
                    self:_closeSidePanel(false)
                end
                return
            end
            if not processed and not UserInputService:GetFocusedTextBox() and input.KeyCode == self.ToggleKey then
                self:Toggle()
                return
            end
            if processed then
                return
            end
            for _, keybind in ipairs(self.Keybinds) do
                if
                    not keybind.Disabled
                    and keybind.Value ~= "NONE"
                    and InputController.Matches(input, keybind.Value)
                then
                    if keybind.Mode == "Hold" then
                        keybind:SetActive(true)
                    elseif keybind.Mode == "Toggle" then
                        keybind:SetActive(not keybind.Active)
                    elseif keybind.Mode == "Always" then
                        keybind:SetActive(true)
                    end
                end
            end
        end)
    )
    addConnection(
        self,
        UserInputService.InputEnded:Connect(function(input)
            for _, keybind in ipairs(self.Keybinds) do
                if keybind.Mode == "Hold" and keybind.Active and InputController.Matches(input, keybind.Value) then
                    keybind:SetActive(false)
                end
            end
        end)
    )
end

function Window:RefreshTheme()
    if self.Main then
        self.Main.BackgroundColor3 = Theme.Background
        self.Sidebar.BackgroundColor3 = Theme.BackgroundSoft
        if self.SearchStroke then
            self.SearchStroke.Color = self.SearchBox:IsFocused() and Theme.Accent or Theme.Border
        end
    end
    for _, tab in ipairs(self.Tabs) do
        self:_setActiveTabVisual(tab, self.ActiveTab == tab)
        for _, section in ipairs(tab.Sections) do
            section.Instance.BackgroundColor3 = Theme.Surface
            for _, control in ipairs(section.Controls) do
                if type(control.RefreshView) == "function" then
                    control:RefreshView()
                end
            end
        end
    end
    for _, widget in ipairs(self.Widgets) do
        if type(widget.Refresh) == "function" then
            widget:Refresh()
        end
    end
end

function Window:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    dismissTooltip(self)
    PopupController:Close(self)
    self:_closeSidePanel(true)
    local tabs = copyArray(self.Tabs)
    for _, tab in ipairs(tabs) do
        tab:Destroy()
    end
    local widgets = copyArray(self.Widgets)
    for _, widget in ipairs(widgets) do
        widget:Destroy()
    end
    if self.CameraMaid then
        self.CameraMaid:Cleanup()
        self.CameraMaid = nil
    end
    disconnectAll(self)
    if self.Root and self.Root.Parent then
        ThemeController:UnbindTree(self.Root)
        self.Root:Destroy()
    end
    removeArrayValue(Kronos.Windows, self)
end

local function buildWindow(library: AnyTable, config: WindowConfig): AnyTable
    local gui = library:_ensureGui()
    if typeof(config.Accent) == "Color3" then
        library:SetAccent(config.Accent)
    end
    if not library.GlobalPopupLayer or not library.GlobalPopupLayer.Parent then
        library.GlobalPopupLayer = create("Frame", {
            Name = "GlobalPopupLayer",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 650,
            Parent = gui,
        }) :: Frame
    end
    local baseWidth = tonumber(config.Width)
        or (config.Size and config.Size.X.Offset > 0 and config.Size.X.Offset)
        or Metrics.Window.X
    local baseHeight = tonumber(config.Height)
        or (config.Size and config.Size.Y.Offset > 0 and config.Size.Y.Offset)
        or Metrics.Window.Y
    baseWidth = math.max(finiteNumber(baseWidth, Metrics.Window.X), 280)
    baseHeight = math.max(finiteNumber(baseHeight, Metrics.Window.Y), 300)
    local viewport = viewportSize()
    local topLeftInset, bottomRightInset = guiInsets()
    local initialWidth =
        math.min(baseWidth, math.max(viewport.X - topLeftInset.X - bottomRightInset.X - Metrics.SafePadding * 2, 280))
    local initialHeight =
        math.min(baseHeight, math.max(viewport.Y - topLeftInset.Y - bottomRightInset.Y - Metrics.SafePadding * 2, 300))
    local window = setmetatable({
        Kronos = library,
        BaseWidth = baseWidth,
        BaseHeight = baseHeight,
        Width = initialWidth,
        Height = initialHeight,
        Tabs = {},
        Keybinds = {},
        Widgets = {},
        Connections = {},
        Visible = true,
        Destroyed = false,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        TwoColumn = initialWidth >= 730 and initialHeight >= 340,
        Presets = {},
    }, Window)
    local root = create("CanvasGroup", {
        Name = "Window",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(
            math.floor((topLeftInset.X + viewport.X - bottomRightInset.X) / 2),
            math.floor((topLeftInset.Y + viewport.Y - bottomRightInset.Y) / 2)
        ),
        Size = UDim2.fromOffset(initialWidth * 0.97, initialHeight * 0.97),
        ClipsDescendants = false,
        ZIndex = 10,
        Parent = gui,
    }) :: CanvasGroup
    local shadow = create("Frame", {
        BackgroundColor3 = Theme.Shadow,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 6),
        Size = UDim2.fromScale(1, 1),
        ZIndex = 8,
        Parent = root,
    }) :: Frame
    corner(shadow, Metrics.Radius + 1)
    local main = create("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.025,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 10,
        Parent = root,
    }) :: Frame
    ThemeController:Bind(main, "BackgroundColor3", "Background")
    corner(main, Metrics.Radius)
    local mainStroke = stroke(main, Theme.Border, 0.22, 1)
    ThemeController:Bind(mainStroke, "Color", "Border")
    window.Root = root
    window.Main = main
    window.PopupLayer = library.GlobalPopupLayer
    window:_makeHeader(config)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.BackgroundSoft,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, Metrics.Header),
        Size = UDim2.new(0, Metrics.Sidebar, 1, -Metrics.Header),
        ZIndex = 12,
        Parent = main,
    }) :: Frame
    ThemeController:Bind(sidebar, "BackgroundColor3", "BackgroundSoft")
    local sidebarDivider = create("Frame", {
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        ZIndex = 13,
        Parent = sidebar,
    }) :: Frame
    ThemeController:Bind(sidebarDivider, "BackgroundColor3", "Divider")
    local searchBox = create("TextBox", {
        Name = "Search",
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.26,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Text = "",
        PlaceholderText = "Search",
        PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 0, 30),
        ZIndex = 15,
        Parent = sidebar,
    }) :: TextBox
    ThemeController:Bind(searchBox, "BackgroundColor3", "Surface2")
    corner(searchBox, 5)
    local searchStroke = stroke(searchBox, Theme.Border, 0.66, 1)
    padding(searchBox, 27, 0, 8, 0)
    local searchIcon = makeText(searchBox, getIcon("Search"), 11, Theme.Muted, "bold")
    searchIcon.Position = UDim2.fromOffset(-19, 0)
    searchIcon.Size = UDim2.fromOffset(17, 30)
    searchIcon.TextXAlignment = Enum.TextXAlignment.Center
    searchIcon.ZIndex = 16
    local navScroll = create("ScrollingFrame", {
        Name = "Navigation",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 45),
        Size = UDim2.new(1, -16, 1, -91),
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        ScrollBarThickness = 1,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.2,
        ZIndex = 14,
        Parent = sidebar,
    }) :: ScrollingFrame
    ThemeController:Bind(navScroll, "ScrollBarImageColor3", "Accent")
    local sidebarList = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -3, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = navScroll,
    }) :: Frame
    local sidebarLayout = list(sidebarList, Enum.FillDirection.Vertical, 4)
    addConnection(
        window,
        sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            navScroll.CanvasSize = UDim2.fromOffset(0, sidebarLayout.AbsoluteContentSize.Y + 4)
        end)
    )
    local footer = create("TextButton", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.48,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.new(0, 8, 1, -39),
        Size = UDim2.new(1, -16, 0, 31),
        ZIndex = 15,
        Parent = sidebar,
    }) :: TextButton
    ThemeController:Bind(footer, "BackgroundColor3", "Surface2")
    corner(footer, 5)
    local footerIcon = makeText(footer, getIcon("User"), 11, Theme.Accent, "bold")
    footerIcon.Position = UDim2.fromOffset(8, 0)
    footerIcon.Size = UDim2.fromOffset(22, 31)
    footerIcon.TextXAlignment = Enum.TextXAlignment.Center
    footerIcon.ZIndex = 16
    ThemeController:Bind(footerIcon, "TextColor3", "Accent")
    local footerLabel = makeText(footer, LocalPlayer and LocalPlayer.DisplayName or "Profile", 9, Theme.SubText, "bold")
    footerLabel.Position = UDim2.fromOffset(34, 0)
    footerLabel.Size = UDim2.new(1, -39, 1, 0)
    footerLabel.ZIndex = 16

    local content = create("Frame", {
        Name = "Content",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(Metrics.Sidebar, Metrics.Header),
        Size = UDim2.new(1, -Metrics.Sidebar, 1, -Metrics.Header),
        ZIndex = 12,
        Parent = main,
    }) :: Frame
    ThemeController:Bind(content, "BackgroundColor3", "Background")
    local pageHost = create("Frame", {
        Name = "PageHost",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 13,
        Parent = content,
    }) :: Frame
    local emptySearch = makeText(content, "No matching tabs or controls", 10, Theme.Muted, "bold")
    emptySearch.Size = UDim2.fromScale(1, 1)
    emptySearch.TextXAlignment = Enum.TextXAlignment.Center
    emptySearch.Visible = false
    emptySearch.ZIndex = 14

    window.Sidebar = sidebar
    window.SearchBox = searchBox
    window.SearchStroke = searchStroke
    window.SearchIcon = searchIcon
    window.NavigationScroll = navScroll
    window.SidebarList = sidebarList
    window.SidebarFooterLabel = footerLabel
    window.Content = content
    window.PageHost = pageHost
    window.EmptySearch = emptySearch
    if config.SearchBar == false then
        searchBox.Visible = false
        navScroll.Position = UDim2.fromOffset(8, 8)
        navScroll.Size = UDim2.new(1, -16, 1, -54)
    end
    table.insert(library.Windows, window)
    addConnection(
        window,
        searchBox.Focused:Connect(function()
            window.SearchExpanded = true
            window:ApplyResponsive()
            tween(searchStroke, { Color = Theme.Accent, Transparency = 0.28 }, Motion.Hover)
        end)
    )
    addConnection(
        window,
        searchBox.FocusLost:Connect(function()
            window.SearchExpanded = false
            window:ApplyResponsive()
            tween(searchStroke, { Color = Theme.Border, Transparency = 0.66 }, Motion.Hover)
        end)
    )
    addConnection(
        window,
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            window:ApplySearch(searchBox.Text)
        end)
    )
    addConnection(
        window,
        footer.Activated:Connect(function()
            window:OpenSettings()
        end)
    )
    window:_bindInput()
    local function viewportChanged()
        window:ApplyResponsive()
    end
    local cameraMaid = Maid.new()
    window.CameraMaid = cameraMaid
    local function bindCurrentCamera()
        cameraMaid:Cleanup()
        if workspace.CurrentCamera then
            cameraMaid:Give(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(viewportChanged))
        end
        viewportChanged()
    end
    bindCurrentCamera()
    addConnection(
        window,
        workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            bindCurrentCamera()
        end)
    )
    window.Presets = {
        { Name = "Reference", Accent = Color3.fromRGB(143, 104, 255), Flags = {} },
        { Name = "Cool Violet", Accent = Color3.fromRGB(119, 93, 226), Flags = {} },
    }
    window:ApplyResponsive()
    if config.MobileToggle ~= false then
        window:CreateReopenButton({})
    end
    if config.FloatingWidgets ~= false then
        window:CreateStatusStrip({ Visible = config.StatusStrip ~= false })
        window:CreateTargetList({ Visible = config.TargetList ~= false })
        window:CreateKeybindList({ Visible = config.KeybindList ~= false })
    end
    root.Size = UDim2.fromOffset(window.Width * 0.97, window.Height * 0.97)
    tween(root, {
        GroupTransparency = 0,
        Size = UDim2.fromOffset(window.Width, window.Height),
    }, Motion.Window, Enum.EasingStyle.Quart)
    return window
end

function WindowController:Create(library: AnyTable, config: WindowConfig): AnyTable
    return buildWindow(library, config)
end

function WindowController:SetVisible(window: AnyTable, visible: boolean): AnyTable
    return window:SetVisible(visible)
end

function NavigationController:Select(window: AnyTable, tab: any): AnyTable
    return window:SelectTab(tab)
end

function NavigationController:Search(window: AnyTable, query: string)
    window:ApplySearch(query)
end

Components.Toggle = Section.CreateToggle
Components.Slider = Section.CreateSlider
Components.Input = Section.CreateInput
Components.Dropdown = Section.CreateDropdown
Components.MultiDropdown = Section.CreateMultiDropdown
Components.Keybind = Section.CreateKeybind
Components.ColorPicker = Section.CreateColorpicker
Components.Button = Section.CreateButton
Components.Label = Section.CreateLabel
Components.Paragraph = Section.CreateParagraph
Components.Divider = Section.CreateDivider

function Kronos:CreateWindow(config: WindowConfig?): AnyTable
    if self.Destroyed then
        error("[Kronos][RootGuiCreation] Cannot create a window after Kronos was destroyed", 0)
    end
    config = config or {}
    local ok, result = xpcall(function()
        return WindowController:Create(self, config)
    end, debug.traceback)
    if not ok then
        local diagnostic = "[Kronos][RootGuiCreation] " .. tostring(result)
        warn(diagnostic)
        error(diagnostic, 0)
    end
    return result
end

function Kronos:SetTheme(overrides: AnyTable?): AnyTable
    local accentChanged = false
    if type(overrides) == "table" then
        for key, value in pairs(overrides) do
            if Theme[key] ~= nil and typeof(value) == "Color3" then
                Theme[key] = value
                accentChanged = accentChanged or key == "Accent"
            end
        end
    end
    if accentChanged and type(overrides) == "table" then
        if typeof(overrides.AccentHover) ~= "Color3" then
            Theme.AccentHover = Theme.Accent:Lerp(Theme.White, 0.13)
        end
        if typeof(overrides.AccentPressed) ~= "Color3" then
            Theme.AccentPressed = Theme.Accent:Lerp(Color3.new(0, 0, 0), 0.18)
        end
        if typeof(overrides.AccentDark) ~= "Color3" then
            Theme.AccentDark = Theme.Accent:Lerp(Color3.new(0, 0, 0), 0.28)
        end
        if typeof(overrides.AccentSoft) ~= "Color3" then
            Theme.AccentSoft = Theme.Accent:Lerp(Theme.White, 0.2)
        end
    end
    ThemeController:Refresh()
    for _, window in ipairs(self.Windows) do
        window:RefreshTheme()
    end
    return self
end

function Kronos:SetAccent(color: Color3): AnyTable
    if typeof(color) ~= "Color3" then
        return self
    end
    Theme.Accent = color
    Theme.AccentHover = color:Lerp(Theme.White, 0.13)
    Theme.AccentPressed = color:Lerp(Color3.new(0, 0, 0), 0.18)
    Theme.AccentDark = color:Lerp(Color3.new(0, 0, 0), 0.28)
    Theme.AccentSoft = color:Lerp(Theme.White, 0.2)
    ThemeController:Refresh()
    for _, window in ipairs(self.Windows) do
        window:RefreshTheme()
    end
    return self
end

function Kronos:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    while #self.Windows > 0 do
        self.Windows[#self.Windows]:Destroy()
    end
    disconnectAll(self)
    local tweenInstances = {}
    for instance in pairs(self.ActiveTweens) do
        table.insert(tweenInstances, instance)
    end
    for _, instance in ipairs(tweenInstances) do
        AnimationController:Cancel(instance)
    end
    if self.GUI and self.GUI.Parent then
        self.GUI:Destroy()
    end
    self.GUI = nil
    self.ToastHolder = nil
    self.GlobalPopupLayer = nil
    table.clear(self.Options)
    table.clear(self.Flags)
    table.clear(self.Keybinds)
    table.clear(self.Widgets)
    table.clear(self.ThemeBindings)
    if Environment.__KRONOS_ACTIVE == self then
        Environment.__KRONOS_ACTIVE = nil
    end
end

local function buildShowcase(): AnyTable
    local window = Kronos:CreateWindow({
        Title = "Kronos",
        Subtitle = "Interface Library  ·  Showcase",
        SearchBar = true,
        Accent = Theme.Accent,
        ToggleKey = Enum.KeyCode.RightShift,
        MobileToggle = true,
        Width = 820,
        Height = 480,
        FloatingWidgets = true,
    })

    local overview = window:AddTab({ Title = "Overview", Icon = "Home" })
    local general = overview:AddSection({
        Title = "General",
        Description = "Compact component states",
        Side = "Left",
        Icon = "Sliders",
    })
    general:AddLabel({ Id = "ShowcaseLabel", Text = "Native Roblox controls with persistent state", Bold = true })
    general:AddParagraph({
        Id = "ShowcaseParagraph",
        Title = "Reference composition",
        Content = "Near-black surfaces, restrained violet emphasis, slim separators, and short interruptible motion.",
    })
    general:AddDivider({ Title = "Actions" })
    general:AddButton({
        Id = "ShowcaseNotification",
        Title = "Notification",
        ButtonText = "Preview",
        Icon = "Bell",
        Callback = function()
            window:Notify({
                Title = "Kronos notification",
                Content = "The compact notification stack is working.",
                Type = "success",
                Duration = 3,
            })
        end,
    })
    general:AddButton({
        Id = "ShowcaseBusy",
        Title = "Busy state",
        ButtonText = "Run",
        AutoBusy = true,
        BusyDuration = 0.8,
    })
    general:AddButton({
        Id = "ShowcaseDisabledButton",
        Title = "Disabled action",
        ButtonText = "Unavailable",
        Disabled = true,
    })

    local states = overview:AddSection({
        Title = "States",
        Description = "Selection and dependency behavior",
        Side = "Right",
        Icon = "CheckCircle",
    })
    local dependency =
        states:AddToggle({ Id = "ShowcaseDependency", Title = "Reveal advanced control", Default = true })
    states:AddToggle({
        Id = "ShowcaseToggle",
        Title = "Enabled toggle",
        Description = "Square reference treatment",
        Default = true,
    })
    states:AddToggle({ Id = "ShowcaseDisabledToggle", Title = "Disabled toggle", Default = false, Disabled = true })
    local dependentDropdown = states:AddDropdown({
        Id = "ShowcaseDependentDropdown",
        Title = "Dependent mode",
        Values = { "Balanced", "Precise", "Responsive" },
        Default = "Balanced",
    })
    dependency:AddDependency(dependentDropdown)
    states:AddSlider({
        Id = "ShowcaseStrength",
        Title = "Strength",
        Min = 0,
        Max = 100,
        Default = 64,
        Step = 1,
        Suffix = "%",
    })

    local components = window:AddTab({ Title = "Components", Icon = "LayoutDashboard" })
    local inputs = components:AddSection({
        Title = "Inputs",
        Description = "Text, number, and continuous values",
        Side = "Left",
        Icon = "Keyboard",
    })
    inputs:AddInput({
        Id = "ShowcaseTextInput",
        Title = "Text input",
        Placeholder = "Type a value",
        Default = "Kronos",
        MaxLength = 32,
        SubmitOnEnter = true,
        OnSubmit = function(value)
            window:Notify({ Title = "Input submitted", Content = value, Duration = 2 })
        end,
    })
    inputs:AddInput({
        Id = "ShowcaseNumericInput",
        Title = "Numeric input",
        Placeholder = "0 - 100",
        Default = "24",
        NumericOnly = true,
        Validate = function(value)
            local numeric = tonumber(value)
            return numeric ~= nil and numeric >= 0 and numeric <= 100, "Use a value from 0 to 100"
        end,
    })
    inputs:AddSlider({
        Id = "ShowcasePrecision",
        Title = "Precision",
        Min = 0,
        Max = 1,
        Default = 0.35,
        Step = 0.05,
        Precision = 2,
    })
    inputs:AddColorPicker({
        Id = "ShowcaseColor",
        Title = "Accent color",
        Default = Theme.Accent,
        EnableAlpha = true,
        Callback = function(color)
            window:SetAccent(color)
        end,
    })

    local selections = components:AddSection({
        Title = "Selections",
        Description = "Overlay popups stay outside clipping",
        Side = "Right",
        Icon = "List",
    })
    selections:AddDropdown({
        Id = "ShowcaseDropdown",
        Title = "Single dropdown",
        Values = { "Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa" },
        Default = "Gamma",
        Search = true,
    })
    selections:AddMultiDropdown({
        Id = "ShowcaseMultiDropdown",
        Title = "Multi-select",
        Values = { "Status", "Target", "Keybinds", "Metrics", "Clock" },
        Default = { "Status", "Keybinds" },
        MaxSelections = 3,
    })
    selections:AddKeybind({
        Id = "ShowcaseKeybind",
        Title = "Interface action",
        Default = Enum.KeyCode.F.Name,
        Mode = "Toggle",
        Callback = function(active)
            window:Notify({ Title = "Keybind state", Content = active and "Active" or "Inactive", Duration = 1.6 })
        end,
    })
    selections:AddKeybind({
        Id = "ShowcaseHoldKeybind",
        Title = "Hold action",
        Default = Enum.KeyCode.LeftAlt.Name,
        Mode = "Hold",
    })

    local advanced = window:AddTab({ Title = "Advanced", Icon = "Settings" })
    local panels = advanced:AddSection({
        Title = "Panels",
        Description = "Reference auxiliary surfaces",
        Side = "Left",
        Icon = "PanelTop",
    })
    panels:AddButton({
        Id = "ShowcaseSettings",
        Title = "Profile settings",
        ButtonText = "Open",
        Callback = function()
            window:OpenSettings()
        end,
    })
    panels:AddButton({
        Id = "ShowcasePresets",
        Title = "Configuration presets",
        ButtonText = "Open",
        Callback = function()
            window:OpenPresets()
        end,
    })
    panels:AddButton({
        Id = "ShowcaseMinimize",
        Title = "Minimize and restore",
        ButtonText = "Minimize",
        Callback = function()
            window:Minimize()
        end,
    })
    panels:AddDivider({ Title = "Notification variants" })
    panels:AddButton({
        Id = "ShowcaseWarning",
        Title = "Warning",
        ButtonText = "Show",
        Callback = function()
            window:Notify({ Title = "Warning", Content = "This is a restrained warning state.", Type = "warning" })
        end,
    })
    panels:AddButton({
        Id = "ShowcaseError",
        Title = "Error",
        ButtonText = "Show",
        Callback = function()
            window:Notify({ Title = "Error", Content = "Callbacks remain isolated from the interface.", Type = "error" })
        end,
    })

    local widgets = advanced:AddSection({
        Title = "Floating widgets",
        Description = "Independent drag and visibility",
        Side = "Right",
        Icon = "Move",
    })
    widgets:AddToggle({
        Id = "ShowcaseStatusVisible",
        Title = "Status strip",
        Default = true,
        Callback = function(value)
            window.StatusStrip:SetVisible(value)
        end,
    })
    widgets:AddToggle({
        Id = "ShowcaseTargetVisible",
        Title = "Target list",
        Default = true,
        Callback = function(value)
            window.TargetList:SetVisible(value)
        end,
    })
    widgets:AddToggle({
        Id = "ShowcaseKeybindsVisible",
        Title = "Keybind list",
        Default = true,
        Callback = function(value)
            window.KeybindWidget:SetVisible(value)
        end,
    })
    widgets:AddParagraph({
        Title = "Responsive behavior",
        Content = "Resize or rotate the viewport to switch navigation density and content columns without rebuilding state.",
    })

    if window.TargetList then
        window.TargetList:SetTarget(
            LocalPlayer and LocalPlayer.DisplayName or "Local Player",
            76,
            100,
            LocalPlayer and LocalPlayer.UserId or nil
        )
    end
    window:ApplySearch("")
    window:Notify({
        Title = "Kronos ready",
        Content = "Use the sidebar, search, overlays, or RightShift to explore.",
        Type = "success",
        Duration = 4,
    })
    return window
end

local RUN_SHOWCASE = true

Kronos.StartupDiagnostics = {} :: { AnyTable }
local function startupStage(name: string, callback: () -> any): (boolean, any)
    local ok, result = xpcall(callback, debug.traceback)
    table.insert(Kronos.StartupDiagnostics, {
        Stage = name,
        Success = ok,
        Error = ok and nil or tostring(result),
    })
    if not ok then
        warn("[Kronos][" .. name .. "] " .. tostring(result))
    end
    return ok, result
end

local startupOk = startupStage("EnvironmentValidation", function()
    assert(type(Environment) == "table", "Luau environment is unavailable")
end)
if startupOk then
    startupOk = startupStage("PreviousInstanceCleanup", function()
        assert(previousCleanupOk, tostring(previousCleanupError))
    end)
end
if startupOk then
    startupOk = startupStage("ServiceAcquisition", function()
        assert(
            Players
                and TweenService
                and UserInputService
                and RunService
                and TextService
                and CoreGui
                and GuiService
                and Stats,
            "One or more required Roblox services are unavailable"
        )
    end)
end
if startupOk then
    startupOk = startupStage("ThemeInitialization", function()
        assert(
            Theme.Background and Theme.Surface and Theme.Accent and Theme.Text,
            "Semantic theme tokens are incomplete"
        )
        assert(Motion.Window and Metrics.Window, "Motion or sizing tokens are incomplete")
    end)
end
if startupOk then
    startupOk = startupStage("ControllerInitialization", function()
        assert(
            type(AnimationController.Tween) == "function"
                and type(DragController.Bind) == "function"
                and type(PopupController.Open) == "function"
                and type(NotificationController.Push) == "function"
                and type(WindowController.Create) == "function"
                and type(NavigationController.Select) == "function",
            "A required controller was not initialized"
        )
    end)
end
if startupOk then
    startupOk = startupStage("ComponentInitialization", function()
        assert(
            type(Components.Toggle) == "function"
                and type(Components.Dropdown) == "function"
                and type(Components.Keybind) == "function"
                and type(Components.ColorPicker) == "function",
            "A required component constructor was not initialized"
        )
    end)
end
if startupOk then
    startupOk = startupStage("RootGuiCreation", function()
        Kronos:_ensureGui()
    end)
end
if startupOk and RUN_SHOWCASE then
    local showcaseOk, showcaseError = startupStage("ShowcaseCreation", buildShowcase)
    if not showcaseOk then
        Kronos:Notify({
            Title = "Showcase failed",
            Content = tostring(showcaseError),
            Type = "error",
            Duration = 7,
        })
    end
end
if startupOk then
    startupStage("FinalActivation", function()
        Environment.__KRONOS_ACTIVE = Kronos
    end)
end

return Kronos
