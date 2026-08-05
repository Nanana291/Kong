--!strict

--[[
    KronosV1.8.lua
    Cumulative native Roblox UI library refined against the supplied
    2340x1080 reference video. All controllers and the optional showcase live
    in this file; no remote modules or external UI libraries are required.
]]

type AnyTable = { [any]: any }
type ThemeMap = { [string]: Color3 }
type IconOptions = {
    Icon: string?,
    IconSize: number?,
    IconColor: Color3?,
    IconTransparency: number?,
}
type DragOptions = {
    DragBounds: string?,
    KeepFullyVisible: boolean?,
    DragMargin: number?,
    MinimumVisiblePixels: number?,
    DragThreshold: number?,
}
type ComponentOptions = IconOptions & { [string]: any }
type NavigationOptions = IconOptions & { [string]: any }
type NotificationOptions = IconOptions & { [string]: any }
type FloatingWidgetOptions = IconOptions & DragOptions & { [string]: any }
type WindowConfig = {
    Title: string?,
    Subtitle: string?,
    SubTitle: string?,
    SearchBar: boolean?,
    SearchBehavior: string?,
    CompactNavigation: boolean?,
    Accent: Color3?,
    ToggleKey: Enum.KeyCode?,
    MobileToggle: boolean?,
    FloatingWidgets: boolean?,
    StatusStrip: boolean?,
    StatusFields: { [string]: boolean }?,
    TargetList: boolean?,
    KeybindList: boolean?,
    KeybindListActiveOnly: boolean?,
    KeybindListEmptyMessage: boolean?,
    Size: UDim2?,
    Width: number?,
    Height: number?,
    Icon: string?,
    IconSize: number?,
    IconColor: Color3?,
    IconTransparency: number?,
    Draggable: boolean?,
    DragBounds: string?,
    KeepFullyVisible: boolean?,
    DragMargin: number?,
    MinimumVisiblePixels: number?,
    Transparency: number?,
    Acrylic: boolean?,
    AcrylicIntensity: number?,
    BorderIntensity: number?,
    SurfaceContrast: number?,
    ReducedMotion: boolean?,
    AnimationIntensity: number?,
    DimStrength: number?,
    HeaderContext: boolean?,
    ProfilePanel: boolean?,
    ProfileName: string?,
    ProfileSubtitle: string?,
    ShowSidebarProfile: boolean?,
    ShowCloseButton: boolean?,
    ShowMinimizeButton: boolean?,
    ShowPresetsButton: boolean?,
}

local Kronos: AnyTable = {}
Kronos.Version = "1.8.0"
Kronos.Options = {} :: AnyTable
Kronos.Windows = {} :: { AnyTable }
Kronos.Connections = {} :: { RBXScriptConnection }
Kronos.Notifications = {} :: { Instance }
Kronos.NotificationHandles = {} :: { AnyTable }
Kronos.Flags = {} :: AnyTable
Kronos.ThemeBindings = {} :: { AnyTable }
Kronos.ActiveTweens = setmetatable({}, { __mode = "k" }) :: AnyTable
Kronos.ActiveTweenTargets = setmetatable({}, { __mode = "k" }) :: AnyTable
Kronos.Destroyed = false
Kronos.Keybinds = {} :: { AnyTable }
Kronos.Widgets = {} :: { AnyTable }
Kronos.SurfaceBindings = setmetatable({}, { __mode = "k" }) :: AnyTable
Kronos.BorderBindings = setmetatable({}, { __mode = "k" }) :: AnyTable
Kronos.AcrylicBindings = setmetatable({}, { __mode = "k" }) :: AnyTable
Kronos.Scrollbars = setmetatable({}, { __mode = "k" }) :: AnyTable
Kronos.SurfaceTransparency = 0.16
Kronos.AcrylicEnabled = true
Kronos.AcrylicIntensity = 0.62
Kronos.BorderIntensity = 1
Kronos.SurfaceContrast = 0.98
Kronos.ReducedMotion = false
Kronos.AnimationIntensity = 1
Kronos.AnimationsEnabled = true
Kronos.NotificationMotion = true
Kronos.PageTransitions = true
Kronos.DimStrength = 0.36

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
    -- The objective uses a narrow dark ladder: layers are distinguishable,
    -- but no surface becomes a bright card against the shell.
    Background = Color3.fromRGB(10, 10, 13),
    BackgroundSoft = Color3.fromRGB(13, 13, 17),
    Surface = Color3.fromRGB(17, 16, 22),
    Surface2 = Color3.fromRGB(22, 21, 29),
    Surface3 = Color3.fromRGB(27, 25, 35),
    ElevatedSurface = Color3.fromRGB(21, 20, 28),
    SurfaceHover = Color3.fromRGB(31, 29, 40),
    HoverSurface = Color3.fromRGB(31, 29, 40),
    PressedSurface = Color3.fromRGB(33, 28, 45),
    Stroke = Color3.fromRGB(55, 53, 67),
    StrokeSoft = Color3.fromRGB(40, 38, 49),
    Border = Color3.fromRGB(55, 52, 68),
    Divider = Color3.fromRGB(39, 37, 48),
    Text = Color3.fromRGB(232, 229, 238),
    PrimaryText = Color3.fromRGB(232, 229, 238),
    SubText = Color3.fromRGB(143, 140, 156),
    SecondaryText = Color3.fromRGB(143, 140, 156),
    Muted = Color3.fromRGB(91, 88, 103),
    Disabled = Color3.fromRGB(64, 64, 74),
    DisabledText = Color3.fromRGB(104, 104, 117),
    Accent = Color3.fromRGB(164, 112, 255),
    AccentDark = Color3.fromRGB(107, 72, 190),
    AccentSoft = Color3.fromRGB(194, 158, 255),
    AccentHover = Color3.fromRGB(177, 126, 255),
    AccentPressed = Color3.fromRGB(139, 88, 229),
    White = Color3.fromRGB(255, 255, 255),
    Success = Color3.fromRGB(86, 191, 136),
    Warning = Color3.fromRGB(220, 169, 84),
    Error = Color3.fromRGB(218, 88, 105),
    Shadow = Color3.fromRGB(0, 0, 0),
    Overlay = Color3.fromRGB(4, 4, 7),
    InnerHighlight = Color3.fromRGB(103, 91, 130),
    ScrollTrack = Color3.fromRGB(43, 38, 57),
    AcrylicTint = Color3.fromRGB(26, 22, 34),
}

local Motion = {
    -- Semantic profiles measured to stay fast and restrained like the reference.
    HoverIn = 0.09,
    HoverOut = 0.11,
    PressIn = 0.045,
    PressOut = 0.07,
    FocusIn = 0.105,
    FocusOut = 0.095,
    ToggleOn = 0.13,
    ToggleOff = 0.11,
    SliderActive = 0.06,
    SliderIdle = 0.085,
    TabSelect = 0.12,
    SubtabSelect = 0.11,
    PageEnter = 0.105,
    PageExit = 0.07,
    PopupEnter = 0.105,
    PopupExit = 0.085,
    SettingsEnter = 0.135,
    SettingsExit = 0.105,
    NotificationEnter = 0.135,
    NotificationMove = 0.12,
    NotificationExit = 0.115,
    ScrollbarActivate = 0.075,
    ScrollbarIdle = 0.14,
    WidgetEnter = 0.135,
    WidgetExit = 0.105,
    RowInsert = 0.115,
    RowRemove = 0.1,
    Minimize = 0.145,
    Restore = 0.145,
    SearchFilter = 0.095,
    DependentReveal = 0.13,
    TooltipEnter = 0.095,
    TooltipExit = 0.08,
    DragClamp = 0.09,

    -- Backward-compatible internal aliases used by mature component code.
    Hover = 0.08,
    Press = 0.05,
    Slider = 0.065,
    Toggle = 0.14,
    Dropdown = 0.13,
    PopupClose = 0.09,
    Tab = 0.115,
    SubTab = 0.11,
    TabExit = 0.085,
    Search = 0.1,
    Settings = 0.145,
    Widget = 0.15,
    DragRelease = 0.085,
    Window = 0.18,
    Notification = 0.145,
    Tooltip = 0.1,
    Health = 0.14,
    KeybindRow = 0.115,
    Scrollbar = 0.085,
}

-- V1.8 target-derived design decisions. These tokens centralize measurements
-- that were previously scattered through individual components.
local TargetDesign = {
    Window = {
        -- The objective shell measures roughly 906x584 in the supplied
        -- 2340x1080 capture. Mobile landscape uses a logical viewport, so it
        -- needs a separate artboard scale instead of inflating the whole UI.
        LogicalSize = Vector2.new(906, 584),
        Aspect = 906 / 584,
        Center = Vector2.new(0.453, 0.548),
        Radius = 8,
        WideHeightRatio = 0.58,
        MediumHeightRatio = 0.56,
        CompactHeightRatio = 0.76,
        LandscapeHeightRatio = 0.84,
        MobileLandscapeScale = 0.476,
        PortraitWidthRatio = 0.94,
        PortraitHeightRatio = 0.84,
    },
    Header = {
        Height = 50,
        BrandSize = 18,
        ContextHeight = 26,
        ContextWidth = 190,
        UtilitySize = 22,
    },
    Navigation = {
        ExpandedRatio = 0.276,
        CompactRatio = 0.062,
        CompactWidth = 44,
        SearchHeight = 24,
        TabHeight = 25,
        CompactTabHeight = 28,
        FooterHeight = 24,
    },
    Content = {
        MaximumWidth = 620,
        SingleColumnMaximum = 418,
        MinimumSection = 232,
        ColumnGap = 10,
        SectionGap = 7,
        -- The objective uses the header selector as sub-navigation; content
        -- does not reserve a second horizontal subtab rail.
        SubtabInset = 0,
    },
    Control = {
        RowHeight = 27,
        Row = 27,
        DescriptionHeight = 36,
        Radius = 4,
        ToggleSize = 12,
        Toggle = 12,
        InputHeight = 22,
        SliderTrack = 3,
        SliderThumb = 8,
    },
    Scrollbar = {
        IdleThickness = 3,
        IdleWidth = 3,
        ActiveThickness = 5,
        ActiveWidth = 5,
        MinimumThumb = 18,
        HorizontalMinimumThumb = 24,
        TrackInset = 2,
        Margin = 3,
        HorizontalMargin = 4,
        IdleTransparency = 0.48,
        ActiveTransparency = 0.08,
        FadeDelay = 0.72,
        IdleDelay = 0.72,
        WheelStep = 34,
    },
    Popup = {
        Radius = 6,
        DropdownWidth = 190,
        ColorWidth = 210,
        SearchHeight = 24,
        OptionHeight = 24,
        Padding = 5,
        MaximumVisibleOptions = 6,
    },
    Widget = {
        -- The objective keeps both floating cards compact, with the target
        -- card only slightly wider than the keybind table.
        Target = Vector2.new(250, 72),
        TargetWidth = 250,
        TargetHeight = 72,
        Keybind = Vector2.new(236, 58),
        KeybindWidth = 236,
        KeybindHeight = 58,
        StatusWidth = 162,
        StatusHeight = 28,
        ReopenSize = 42,
    },
}

-- Metrics dereference these groups during module evaluation, so validate the
-- design token shape before constructing any dependent tables.
assert(
    type(TargetDesign.Window) == "table"
        and type(TargetDesign.Header) == "table"
        and type(TargetDesign.Navigation) == "table"
        and type(TargetDesign.Content) == "table"
        and type(TargetDesign.Control) == "table"
        and type(TargetDesign.Scrollbar) == "table"
        and type(TargetDesign.Popup) == "table"
        and type(TargetDesign.Widget) == "table",
    "[Kronos] TargetDesign is incomplete"
)

local Metrics = {
    -- Target-derived measurements from the 2340x1080 objective capture.
    ReferenceViewport = Vector2.new(2340, 1080),
    ReferenceWindow = Vector2.new(906, 584),
    ReferenceAspect = 906 / 584,
    Window = TargetDesign.Window.LogicalSize,
    MinimumWindow = Vector2.new(440, 284),
    MaximumWindow = Vector2.new(906, 584),
    Header = TargetDesign.Header.Height,
    Sidebar = 250,
    SidebarRatio = TargetDesign.Navigation.ExpandedRatio,
    CompactSidebar = TargetDesign.Navigation.CompactWidth,
    CompactSidebarRatio = TargetDesign.Navigation.CompactRatio,
    HeaderRatio = 0.092,
    HeaderContextWidth = TargetDesign.Header.ContextWidth,
    HeaderContextHeight = TargetDesign.Header.ContextHeight,
    PreferredContent = 600,
    MaximumContent = TargetDesign.Content.MaximumWidth,
    SingleColumnMaximum = TargetDesign.Content.SingleColumnMaximum,
    MinimumSection = TargetDesign.Content.MinimumSection,
    ColumnGap = TargetDesign.Content.ColumnGap,
    Row = TargetDesign.Control.RowHeight,
    DescriptionRow = TargetDesign.Control.DescriptionHeight,
    SectionGap = TargetDesign.Content.SectionGap,
    Radius = TargetDesign.Control.Radius,
    ShellRadius = TargetDesign.Window.Radius,
    PopupRadius = TargetDesign.Popup.Radius,
}

local LayerZ = {
    Main = 10,
    Floating = 500,
    Popup = 700,
    Notification = 1000,
    Modal = 1200,
    Mobile = 1400,
}


-- Generated Lucide name-to-asset table, embedded so icon resolution is offline and deterministic.
local LucideAssets: { [string]: string } = {
    ["a-arrow-down"] = "rbxassetid://92867583610071",
    ["a-arrow-up"] = "rbxassetid://132318504999733",
    ["a-large-small"] = "rbxassetid://111491496660216",
    ["accessibility"] = "rbxassetid://114029945302017",
    ["activity"] = "rbxassetid://94212016861936",
    ["air-vent"] = "rbxassetid://81517226012329",
    ["airplay"] = "rbxassetid://115020759309179",
    ["alarm-clock-check"] = "rbxassetid://76437352099157",
    ["alarm-clock-minus"] = "rbxassetid://77364179863205",
    ["alarm-clock-off"] = "rbxassetid://97904885874823",
    ["alarm-clock-plus"] = "rbxassetid://80468822979214",
    ["alarm-clock"] = "rbxassetid://126259032907535",
    ["alarm-smoke"] = "rbxassetid://96965448419685",
    ["album"] = "rbxassetid://127358331163602",
    ["align-center-horizontal"] = "rbxassetid://81570549209434",
    ["align-center-vertical"] = "rbxassetid://118470463752466",
    ["align-end-horizontal"] = "rbxassetid://139502909745427",
    ["align-end-vertical"] = "rbxassetid://96528869059554",
    ["align-horizontal-distribute-center"] = "rbxassetid://97220086126656",
    ["align-horizontal-distribute-end"] = "rbxassetid://106128590702022",
    ["align-horizontal-distribute-start"] = "rbxassetid://76074660002997",
    ["align-horizontal-justify-center"] = "rbxassetid://75732302772427",
    ["align-horizontal-justify-end"] = "rbxassetid://129167626402283",
    ["align-horizontal-justify-start"] = "rbxassetid://130161830325281",
    ["align-horizontal-space-around"] = "rbxassetid://91646106782950",
    ["align-horizontal-space-between"] = "rbxassetid://103886093046990",
    ["align-start-horizontal"] = "rbxassetid://125674804697729",
    ["align-start-vertical"] = "rbxassetid://105020230154823",
    ["align-vertical-distribute-center"] = "rbxassetid://93791183635525",
    ["align-vertical-distribute-end"] = "rbxassetid://139354223511433",
    ["align-vertical-distribute-start"] = "rbxassetid://74961997822126",
    ["align-vertical-justify-center"] = "rbxassetid://134754696166569",
    ["align-vertical-justify-end"] = "rbxassetid://92569381441969",
    ["align-vertical-justify-start"] = "rbxassetid://99692844572718",
    ["align-vertical-space-around"] = "rbxassetid://96206012459190",
    ["align-vertical-space-between"] = "rbxassetid://124998077349706",
    ["ambulance"] = "rbxassetid://78599995190651",
    ["ampersand"] = "rbxassetid://75272915739209",
    ["ampersands"] = "rbxassetid://126947193455996",
    ["amphora"] = "rbxassetid://137370389604364",
    ["anchor"] = "rbxassetid://92181172123618",
    ["angry"] = "rbxassetid://74237056000103",
    ["annoyed"] = "rbxassetid://80064369052011",
    ["antenna"] = "rbxassetid://99628923540956",
    ["anvil"] = "rbxassetid://100203029845919",
    ["aperture"] = "rbxassetid://83396154449972",
    ["app-window-mac"] = "rbxassetid://79587216113811",
    ["app-window"] = "rbxassetid://93142176757189",
    ["apple"] = "rbxassetid://104349242902442",
    ["archive-restore"] = "rbxassetid://78956681942188",
    ["archive-x"] = "rbxassetid://75830115088395",
    ["archive"] = "rbxassetid://122180020814574",
    ["armchair"] = "rbxassetid://105384358373973",
    ["arrow-big-down-dash"] = "rbxassetid://137987229582002",
    ["arrow-big-down"] = "rbxassetid://81081164158885",
    ["arrow-big-left-dash"] = "rbxassetid://97827621354677",
    ["arrow-big-left"] = "rbxassetid://85973092492641",
    ["arrow-big-right-dash"] = "rbxassetid://117825834972403",
    ["arrow-big-right"] = "rbxassetid://82960676755590",
    ["arrow-big-up-dash"] = "rbxassetid://99260194327483",
    ["arrow-big-up"] = "rbxassetid://93136954756149",
    ["arrow-down-0-1"] = "rbxassetid://120961896217875",
    ["arrow-down-1-0"] = "rbxassetid://93474255891850",
    ["arrow-down-a-z"] = "rbxassetid://99554596207900",
    ["arrow-down-from-line"] = "rbxassetid://132045845807798",
    ["arrow-down-left"] = "rbxassetid://102899325237364",
    ["arrow-down-narrow-wide"] = "rbxassetid://129105261655061",
    ["arrow-down-right"] = "rbxassetid://123109928624974",
    ["arrow-down-to-dot"] = "rbxassetid://101675355931221",
    ["arrow-down-to-line"] = "rbxassetid://87050478931254",
    ["arrow-down-up"] = "rbxassetid://85780258549577",
    ["arrow-down-wide-narrow"] = "rbxassetid://88461733425991",
    ["arrow-down-z-a"] = "rbxassetid://76115279362232",
    ["arrow-down"] = "rbxassetid://98764963621439",
    ["arrow-left-from-line"] = "rbxassetid://87857914437603",
    ["arrow-left-right"] = "rbxassetid://131324733048447",
    ["arrow-left-to-line"] = "rbxassetid://118645136026970",
    ["arrow-left"] = "rbxassetid://102531941843733",
    ["arrow-right-from-line"] = "rbxassetid://74073639809355",
    ["arrow-right-left"] = "rbxassetid://77015754304300",
    ["arrow-right-to-line"] = "rbxassetid://78632510329852",
    ["arrow-right"] = "rbxassetid://113692007244654",
    ["arrow-up-0-1"] = "rbxassetid://105257823943016",
    ["arrow-up-1-0"] = "rbxassetid://134175521693798",
    ["arrow-up-a-z"] = "rbxassetid://77763416595160",
    ["arrow-up-down"] = "rbxassetid://81019887641527",
    ["arrow-up-from-dot"] = "rbxassetid://124408496673275",
    ["arrow-up-from-line"] = "rbxassetid://95777664626453",
    ["arrow-up-left"] = "rbxassetid://123490598231261",
    ["arrow-up-narrow-wide"] = "rbxassetid://73006024672636",
    ["arrow-up-right"] = "rbxassetid://129280608535523",
    ["arrow-up-to-line"] = "rbxassetid://108818207813537",
    ["arrow-up-wide-narrow"] = "rbxassetid://87437426951568",
    ["arrow-up-z-a"] = "rbxassetid://107546173611884",
    ["arrow-up"] = "rbxassetid://89282378235317",
    ["arrows-up-from-line"] = "rbxassetid://133710016938621",
    ["asterisk"] = "rbxassetid://88552752106723",
    ["at-sign"] = "rbxassetid://79059152889146",
    ["atom"] = "rbxassetid://73167696981648",
    ["audio-lines"] = "rbxassetid://70930641819242",
    ["audio-waveform"] = "rbxassetid://86462036665209",
    ["award"] = "rbxassetid://132740088158419",
    ["axe"] = "rbxassetid://132405197863294",
    ["axis-3d"] = "rbxassetid://122438676546804",
    ["baby"] = "rbxassetid://93472926933440",
    ["backpack"] = "rbxassetid://140420225386018",
    ["badge-alert"] = "rbxassetid://101829200081951",
    ["badge-cent"] = "rbxassetid://133345018873154",
    ["badge-check"] = "rbxassetid://76078495178149",
    ["badge-dollar-sign"] = "rbxassetid://127139803581141",
    ["badge-euro"] = "rbxassetid://120016477674659",
    ["badge-indian-rupee"] = "rbxassetid://75659682309981",
    ["badge-info"] = "rbxassetid://131995373201472",
    ["badge-japanese-yen"] = "rbxassetid://99081574588615",
    ["badge-minus"] = "rbxassetid://140321561183881",
    ["badge-percent"] = "rbxassetid://121359224294885",
    ["badge-plus"] = "rbxassetid://100325578561866",
    ["badge-pound-sterling"] = "rbxassetid://119688217279444",
    ["badge-question-mark"] = "rbxassetid://121464963737502",
    ["badge-russian-ruble"] = "rbxassetid://108839463659864",
    ["badge-swiss-franc"] = "rbxassetid://91447608372740",
    ["badge-turkish-lira"] = "rbxassetid://137839965873529",
    ["badge-x"] = "rbxassetid://122931434733842",
    ["badge"] = "rbxassetid://116620312917084",
    ["baggage-claim"] = "rbxassetid://86922213051957",
    ["ban"] = "rbxassetid://90767043015246",
    ["banana"] = "rbxassetid://140713420056179",
    ["bandage"] = "rbxassetid://129660129590770",
    ["banknote-arrow-down"] = "rbxassetid://139366449345199",
    ["banknote-arrow-up"] = "rbxassetid://133758343082529",
    ["banknote-x"] = "rbxassetid://95348701438065",
    ["banknote"] = "rbxassetid://104840231536668",
    ["barcode"] = "rbxassetid://118473018143689",
    ["barrel"] = "rbxassetid://130647115622774",
    ["baseline"] = "rbxassetid://124677132511270",
    ["bath"] = "rbxassetid://76031400297942",
    ["battery-charging"] = "rbxassetid://80139357470047",
    ["battery-full"] = "rbxassetid://70906718268972",
    ["battery-low"] = "rbxassetid://139659256984314",
    ["battery-medium"] = "rbxassetid://105934079398915",
    ["battery-plus"] = "rbxassetid://91931341486966",
    ["battery-warning"] = "rbxassetid://115230083817257",
    ["battery"] = "rbxassetid://70765800346189",
    ["beaker"] = "rbxassetid://80902539995520",
    ["bean-off"] = "rbxassetid://98164436608714",
    ["bean"] = "rbxassetid://89491967076869",
    ["bed-double"] = "rbxassetid://73820193212911",
    ["bed-single"] = "rbxassetid://113423940880634",
    ["bed"] = "rbxassetid://97726529032925",
    ["beef"] = "rbxassetid://105850162318915",
    ["beer-off"] = "rbxassetid://120333134736361",
    ["beer"] = "rbxassetid://116404978807744",
    ["bell-dot"] = "rbxassetid://93161277118810",
    ["bell-electric"] = "rbxassetid://100277767266983",
    ["bell-minus"] = "rbxassetid://126334890449727",
    ["bell-off"] = "rbxassetid://78560046118930",
    ["bell-plus"] = "rbxassetid://77014333795836",
    ["bell-ring"] = "rbxassetid://94612128913941",
    ["bell"] = "rbxassetid://97392696311902",
    ["between-horizontal-end"] = "rbxassetid://81602774794322",
    ["between-horizontal-start"] = "rbxassetid://76112384929846",
    ["between-vertical-end"] = "rbxassetid://72817612571631",
    ["between-vertical-start"] = "rbxassetid://85278312190301",
    ["biceps-flexed"] = "rbxassetid://82004462003936",
    ["bike"] = "rbxassetid://102930322246035",
    ["binary"] = "rbxassetid://91751953950088",
    ["binoculars"] = "rbxassetid://101460003267896",
    ["biohazard"] = "rbxassetid://95956532900432",
    ["bird"] = "rbxassetid://132284145117371",
    ["birdhouse"] = "rbxassetid://83999157401433",
    ["bitcoin"] = "rbxassetid://95459240442938",
    ["blend"] = "rbxassetid://111679612185257",
    ["blinds"] = "rbxassetid://71164165283925",
    ["blocks"] = "rbxassetid://72212693357737",
    ["bluetooth-connected"] = "rbxassetid://96315134002985",
    ["bluetooth-off"] = "rbxassetid://80600044218117",
    ["bluetooth-searching"] = "rbxassetid://100673019606426",
    ["bluetooth"] = "rbxassetid://90506573139443",
    ["bold"] = "rbxassetid://116141470019166",
    ["bolt"] = "rbxassetid://102881251417484",
    ["bomb"] = "rbxassetid://139223800924636",
    ["bone"] = "rbxassetid://111242153474115",
    ["book-a"] = "rbxassetid://104067275658465",
    ["book-alert"] = "rbxassetid://124159928044853",
    ["book-audio"] = "rbxassetid://109208148317037",
    ["book-check"] = "rbxassetid://115999656081696",
    ["book-copy"] = "rbxassetid://108543407492005",
    ["book-dashed"] = "rbxassetid://127430784795958",
    ["book-down"] = "rbxassetid://101011730128222",
    ["book-headphones"] = "rbxassetid://108670200799574",
    ["book-heart"] = "rbxassetid://112788845135284",
    ["book-image"] = "rbxassetid://80808285757226",
    ["book-key"] = "rbxassetid://116024426170705",
    ["book-lock"] = "rbxassetid://118765061220571",
    ["book-marked"] = "rbxassetid://73211024251780",
    ["book-minus"] = "rbxassetid://112724962046282",
    ["book-open-check"] = "rbxassetid://130848362492667",
    ["book-open-text"] = "rbxassetid://100629528672195",
    ["book-open"] = "rbxassetid://129845326810392",
    ["book-plus"] = "rbxassetid://140267785051233",
    ["book-text"] = "rbxassetid://94011772484232",
    ["book-type"] = "rbxassetid://97817304725443",
    ["book-up-2"] = "rbxassetid://130161620853665",
    ["book-up"] = "rbxassetid://98640174079190",
    ["book-user"] = "rbxassetid://128489189240523",
    ["book-x"] = "rbxassetid://118754548186537",
    ["book"] = "rbxassetid://125383279695672",
    ["bookmark-check"] = "rbxassetid://93940443347986",
    ["bookmark-minus"] = "rbxassetid://96807096039910",
    ["bookmark-plus"] = "rbxassetid://121469724491615",
    ["bookmark-x"] = "rbxassetid://112272342584706",
    ["bookmark"] = "rbxassetid://121093149326239",
    ["boom-box"] = "rbxassetid://99901322535868",
    ["bot-message-square"] = "rbxassetid://96145330292478",
    ["bot-off"] = "rbxassetid://140417690560013",
    ["bot"] = "rbxassetid://80451686744860",
    ["bottle-wine"] = "rbxassetid://131675403196921",
    ["bow-arrow"] = "rbxassetid://124089655150375",
    ["box"] = "rbxassetid://101768155599700",
    ["boxes"] = "rbxassetid://136372617578355",
    ["braces"] = "rbxassetid://117761094704041",
    ["brackets"] = "rbxassetid://74368995728099",
    ["brain-circuit"] = "rbxassetid://70547962410202",
    ["brain-cog"] = "rbxassetid://132039205501538",
    ["brain"] = "rbxassetid://92424107303177",
    ["brick-wall-fire"] = "rbxassetid://92980588705520",
    ["brick-wall-shield"] = "rbxassetid://75954432775071",
    ["brick-wall"] = "rbxassetid://112878522258821",
    ["briefcase-business"] = "rbxassetid://129135125207283",
    ["briefcase-conveyor-belt"] = "rbxassetid://108665725653714",
    ["briefcase-medical"] = "rbxassetid://119917756334087",
    ["briefcase"] = "rbxassetid://96754188164225",
    ["bring-to-front"] = "rbxassetid://132975903553748",
    ["brush-cleaning"] = "rbxassetid://71728977448805",
    ["brush"] = "rbxassetid://127035535799640",
    ["bubbles"] = "rbxassetid://106183424168227",
    ["bug-off"] = "rbxassetid://88020025049245",
    ["bug-play"] = "rbxassetid://80107955888092",
    ["bug"] = "rbxassetid://83626408925438",
    ["building-2"] = "rbxassetid://77873775611951",
    ["building"] = "rbxassetid://110616258983082",
    ["bus-front"] = "rbxassetid://89863432456045",
    ["bus"] = "rbxassetid://133798469717463",
    ["cable-car"] = "rbxassetid://128643682205596",
    ["cable"] = "rbxassetid://128449944504901",
    ["cake-slice"] = "rbxassetid://136769828413242",
    ["cake"] = "rbxassetid://103131590503275",
    ["calculator"] = "rbxassetid://74915716529646",
    ["calendar-1"] = "rbxassetid://98458364171044",
    ["calendar-arrow-down"] = "rbxassetid://108415736543437",
    ["calendar-arrow-up"] = "rbxassetid://70574654109118",
    ["calendar-check-2"] = "rbxassetid://120231170248276",
    ["calendar-check"] = "rbxassetid://71551019465748",
    ["calendar-clock"] = "rbxassetid://119132152594595",
    ["calendar-cog"] = "rbxassetid://122402172360287",
    ["calendar-days"] = "rbxassetid://99072017568595",
    ["calendar-fold"] = "rbxassetid://117368871270394",
    ["calendar-heart"] = "rbxassetid://88839008103676",
    ["calendar-minus-2"] = "rbxassetid://98846170279891",
    ["calendar-minus"] = "rbxassetid://137354318924383",
    ["calendar-off"] = "rbxassetid://109726151749217",
    ["calendar-plus-2"] = "rbxassetid://112264562093883",
    ["calendar-plus"] = "rbxassetid://125266115249843",
    ["calendar-range"] = "rbxassetid://103641849247576",
    ["calendar-search"] = "rbxassetid://92010083223634",
    ["calendar-sync"] = "rbxassetid://78082218499697",
    ["calendar-x-2"] = "rbxassetid://107518051061147",
    ["calendar-x"] = "rbxassetid://106703374806500",
    ["calendar"] = "rbxassetid://114792700814035",
    ["camera-off"] = "rbxassetid://81057636835256",
    ["camera"] = "rbxassetid://79950339943067",
    ["candy-cane"] = "rbxassetid://71689468772492",
    ["candy-off"] = "rbxassetid://110232752314832",
    ["candy"] = "rbxassetid://107812129154678",
    ["cannabis"] = "rbxassetid://98792006538601",
    ["captions-off"] = "rbxassetid://105223545364193",
    ["captions"] = "rbxassetid://104960225031445",
    ["car-front"] = "rbxassetid://87380942739063",
    ["car-taxi-front"] = "rbxassetid://122455403384057",
    ["car"] = "rbxassetid://121065933462582",
    ["caravan"] = "rbxassetid://120070979471783",
    ["card-sim"] = "rbxassetid://134490550095771",
    ["carrot"] = "rbxassetid://119118221444304",
    ["case-lower"] = "rbxassetid://129303130603241",
    ["case-sensitive"] = "rbxassetid://125410273293056",
    ["case-upper"] = "rbxassetid://111633433531325",
    ["cassette-tape"] = "rbxassetid://137065788934157",
    ["cast"] = "rbxassetid://98202245922071",
    ["castle"] = "rbxassetid://119275077187784",
    ["cat"] = "rbxassetid://124252153404931",
    ["cctv"] = "rbxassetid://99979894766624",
    ["chart-area"] = "rbxassetid://123446436762366",
    ["chart-bar-big"] = "rbxassetid://72336824986044",
    ["chart-bar-decreasing"] = "rbxassetid://107217459044963",
    ["chart-bar-increasing"] = "rbxassetid://88268905998571",
    ["chart-bar-stacked"] = "rbxassetid://98478751113024",
    ["chart-bar"] = "rbxassetid://105389816384108",
    ["chart-candlestick"] = "rbxassetid://125676898615697",
    ["chart-column-big"] = "rbxassetid://98598733210787",
    ["chart-column-decreasing"] = "rbxassetid://73586137373563",
    ["chart-column-increasing"] = "rbxassetid://120421615068601",
    ["chart-column-stacked"] = "rbxassetid://86031449675105",
    ["chart-column"] = "rbxassetid://97915995538580",
    ["chart-gantt"] = "rbxassetid://88811660555940",
    ["chart-line"] = "rbxassetid://101833156055618",
    ["chart-network"] = "rbxassetid://104027882693561",
    ["chart-no-axes-column-decreasing"] = "rbxassetid://123371717192542",
    ["chart-no-axes-column-increasing"] = "rbxassetid://140383830943049",
    ["chart-no-axes-column"] = "rbxassetid://94078751170351",
    ["chart-no-axes-combined"] = "rbxassetid://121424233161912",
    ["chart-no-axes-gantt"] = "rbxassetid://131936541106368",
    ["chart-pie"] = "rbxassetid://113412261630136",
    ["chart-scatter"] = "rbxassetid://108217585014571",
    ["chart-spline"] = "rbxassetid://90307460742494",
    ["check-check"] = "rbxassetid://95183312173858",
    ["check-line"] = "rbxassetid://115122343485290",
    ["check"] = "rbxassetid://93898873302694",
    ["chef-hat"] = "rbxassetid://121744015002573",
    ["cherry"] = "rbxassetid://139519182403183",
    ["chess-bishop"] = "rbxassetid://121701705580238",
    ["chess-king"] = "rbxassetid://90885687223462",
    ["chess-knight"] = "rbxassetid://96467707042169",
    ["chess-pawn"] = "rbxassetid://111318574652751",
    ["chess-queen"] = "rbxassetid://98304702099749",
    ["chess-rook"] = "rbxassetid://76223925830262",
    ["chevron-down"] = "rbxassetid://134243273101015",
    ["chevron-first"] = "rbxassetid://105243363790238",
    ["chevron-last"] = "rbxassetid://89268452603731",
    ["chevron-left"] = "rbxassetid://73780377692148",
    ["chevron-right"] = "rbxassetid://92473583511724",
    ["chevron-up"] = "rbxassetid://122444883127455",
    ["chevrons-down-up"] = "rbxassetid://139404716013205",
    ["chevrons-down"] = "rbxassetid://100524612205956",
    ["chevrons-left-right-ellipsis"] = "rbxassetid://125035817741526",
    ["chevrons-left-right"] = "rbxassetid://87910685945204",
    ["chevrons-left"] = "rbxassetid://82617201744347",
    ["chevrons-right-left"] = "rbxassetid://87149546686569",
    ["chevrons-right"] = "rbxassetid://139121276490483",
    ["chevrons-up-down"] = "rbxassetid://131833120209646",
    ["chevrons-up"] = "rbxassetid://100467452364672",
    ["chromium"] = "rbxassetid://128165143739006",
    ["church"] = "rbxassetid://113714744350666",
    ["cigarette-off"] = "rbxassetid://77797883078452",
    ["circle-alert"] = "rbxassetid://83898160590116",
    ["circle-arrow-down"] = "rbxassetid://95901860261344",
    ["circle-arrow-left"] = "rbxassetid://102148876968988",
    ["circle-arrow-out-down-left"] = "rbxassetid://140598097856694",
    ["circle-arrow-out-down-right"] = "rbxassetid://119952801379305",
    ["circle-arrow-out-up-left"] = "rbxassetid://132858212688303",
    ["circle-arrow-out-up-right"] = "rbxassetid://81783743753173",
    ["circle-arrow-right"] = "rbxassetid://70786767999559",
    ["circle-arrow-up"] = "rbxassetid://84395128546494",
    ["circle-check-big"] = "rbxassetid://93202927221730",
    ["circle-check"] = "rbxassetid://85262178816537",
    ["circle-chevron-down"] = "rbxassetid://137069490345718",
    ["circle-chevron-left"] = "rbxassetid://130250009740827",
    ["circle-chevron-right"] = "rbxassetid://125943696958495",
    ["circle-chevron-up"] = "rbxassetid://111223574026321",
    ["circle-dashed"] = "rbxassetid://126799443883746",
    ["circle-divide"] = "rbxassetid://106398997754208",
    ["circle-dollar-sign"] = "rbxassetid://91106238890387",
    ["circle-dot-dashed"] = "rbxassetid://111451232827180",
    ["circle-dot"] = "rbxassetid://82947033619201",
    ["circle-ellipsis"] = "rbxassetid://91687150884779",
    ["circle-equal"] = "rbxassetid://95133963751438",
    ["circle-fading-arrow-up"] = "rbxassetid://104648212910336",
    ["circle-fading-plus"] = "rbxassetid://91847890443490",
    ["circle-gauge"] = "rbxassetid://108157549473765",
    ["circle-minus"] = "rbxassetid://133556159576809",
    ["circle-off"] = "rbxassetid://97923456918886",
    ["circle-parking-off"] = "rbxassetid://128369410981252",
    ["circle-parking"] = "rbxassetid://124034962915196",
    ["circle-pause"] = "rbxassetid://139337739700879",
    ["circle-percent"] = "rbxassetid://133311912860256",
    ["circle-play"] = "rbxassetid://120408917249739",
    ["circle-plus"] = "rbxassetid://113157136350384",
    ["circle-pound-sterling"] = "rbxassetid://105476153083828",
    ["circle-power"] = "rbxassetid://140676030155098",
    ["circle-question-mark"] = "rbxassetid://97516698664325",
    ["circle-slash-2"] = "rbxassetid://136766902186549",
    ["circle-slash"] = "rbxassetid://125206439913049",
    ["circle-small"] = "rbxassetid://73685402843600",
    ["circle-star"] = "rbxassetid://120318414957104",
    ["circle-stop"] = "rbxassetid://87400503942659",
    ["circle-user-round"] = "rbxassetid://95489465399880",
    ["circle-user"] = "rbxassetid://136220511671311",
    ["circle-x"] = "rbxassetid://76821953846248",
    ["circle"] = "rbxassetid://130359823580534",
    ["circuit-board"] = "rbxassetid://107695264369312",
    ["citrus"] = "rbxassetid://139018222976433",
    ["clapperboard"] = "rbxassetid://132660667070200",
    ["clipboard-check"] = "rbxassetid://92649798577170",
    ["clipboard-clock"] = "rbxassetid://123957515687745",
    ["clipboard-copy"] = "rbxassetid://125851897718493",
    ["clipboard-list"] = "rbxassetid://96460215958908",
    ["clipboard-minus"] = "rbxassetid://107968008485671",
    ["clipboard-paste"] = "rbxassetid://74382068849983",
    ["clipboard-pen-line"] = "rbxassetid://77711589791615",
    ["clipboard-pen"] = "rbxassetid://75290966822953",
    ["clipboard-plus"] = "rbxassetid://134285318675662",
    ["clipboard-type"] = "rbxassetid://89949374318028",
    ["clipboard-x"] = "rbxassetid://102222456890103",
    ["clipboard"] = "rbxassetid://89601995828423",
    ["clock-1"] = "rbxassetid://129363225422045",
    ["clock-10"] = "rbxassetid://104332695855541",
    ["clock-11"] = "rbxassetid://119023205186105",
    ["clock-12"] = "rbxassetid://117789618723068",
    ["clock-2"] = "rbxassetid://134710777209413",
    ["clock-3"] = "rbxassetid://136385631189327",
    ["clock-4"] = "rbxassetid://121808839832144",
    ["clock-5"] = "rbxassetid://85082019959457",
    ["clock-6"] = "rbxassetid://71009733505593",
    ["clock-7"] = "rbxassetid://103111188546225",
    ["clock-8"] = "rbxassetid://110059272125337",
    ["clock-9"] = "rbxassetid://77610027126437",
    ["clock-alert"] = "rbxassetid://97157344465162",
    ["clock-arrow-down"] = "rbxassetid://92349314416042",
    ["clock-arrow-up"] = "rbxassetid://111484286332629",
    ["clock-check"] = "rbxassetid://85231630218857",
    ["clock-fading"] = "rbxassetid://93205297285245",
    ["clock-plus"] = "rbxassetid://93367709263150",
    ["clock"] = "rbxassetid://121808839832144",
    ["closed-caption"] = "rbxassetid://99832644030788",
    ["cloud-alert"] = "rbxassetid://91967273658626",
    ["cloud-check"] = "rbxassetid://97318598202432",
    ["cloud-cog"] = "rbxassetid://96497764065749",
    ["cloud-download"] = "rbxassetid://121435581993566",
    ["cloud-drizzle"] = "rbxassetid://139525315752605",
    ["cloud-fog"] = "rbxassetid://76650233148776",
    ["cloud-hail"] = "rbxassetid://72320462748242",
    ["cloud-lightning"] = "rbxassetid://133517088924849",
    ["cloud-moon-rain"] = "rbxassetid://127667837827018",
    ["cloud-moon"] = "rbxassetid://71938114737914",
    ["cloud-off"] = "rbxassetid://131907154501444",
    ["cloud-rain-wind"] = "rbxassetid://107414583736721",
    ["cloud-rain"] = "rbxassetid://105547081967408",
    ["cloud-snow"] = "rbxassetid://72307126270226",
    ["cloud-sun-rain"] = "rbxassetid://99041604425705",
    ["cloud-sun"] = "rbxassetid://86114208148727",
    ["cloud-upload"] = "rbxassetid://93307473217005",
    ["cloud"] = "rbxassetid://121226497050352",
    ["cloudy"] = "rbxassetid://105360479023346",
    ["clover"] = "rbxassetid://74925550436750",
    ["club"] = "rbxassetid://108490365816628",
    ["code-xml"] = "rbxassetid://130150477351734",
    ["code"] = "rbxassetid://107380207681249",
    ["codepen"] = "rbxassetid://135643965971885",
    ["codesandbox"] = "rbxassetid://106911852964823",
    ["coffee"] = "rbxassetid://106864403231093",
    ["cog"] = "rbxassetid://116544501716299",
    ["coins"] = "rbxassetid://116510979641930",
    ["columns-2"] = "rbxassetid://113004100221850",
    ["columns-3-cog"] = "rbxassetid://121589691981064",
    ["columns-3"] = "rbxassetid://115223357399375",
    ["columns-4"] = "rbxassetid://130807991968419",
    ["combine"] = "rbxassetid://79908476334048",
    ["command"] = "rbxassetid://93648221906330",
    ["compass"] = "rbxassetid://115123411028382",
    ["component"] = "rbxassetid://110027788875080",
    ["computer"] = "rbxassetid://77480056459407",
    ["concierge-bell"] = "rbxassetid://140384259310436",
    ["cone"] = "rbxassetid://97759550688437",
    ["construction"] = "rbxassetid://106539489968173",
    ["contact-round"] = "rbxassetid://71907624112229",
    ["contact"] = "rbxassetid://75868297719012",
    ["container"] = "rbxassetid://91507237573499",
    ["contrast"] = "rbxassetid://112796643981497",
    ["cookie"] = "rbxassetid://73159504540002",
    ["cooking-pot"] = "rbxassetid://94959783129799",
    ["copy-check"] = "rbxassetid://91177247988892",
    ["copy-minus"] = "rbxassetid://109524509933035",
    ["copy-plus"] = "rbxassetid://113618379616952",
    ["copy-slash"] = "rbxassetid://93805787810390",
    ["copy-x"] = "rbxassetid://106557557978061",
    ["copy"] = "rbxassetid://78979572434545",
    ["copyleft"] = "rbxassetid://78559055698593",
    ["copyright"] = "rbxassetid://129433635747111",
    ["corner-down-left"] = "rbxassetid://90473561177832",
    ["corner-down-right"] = "rbxassetid://86512767702085",
    ["corner-left-down"] = "rbxassetid://139876989150630",
    ["corner-left-up"] = "rbxassetid://126228268096099",
    ["corner-right-down"] = "rbxassetid://89237035551302",
    ["corner-right-up"] = "rbxassetid://112851237026705",
    ["corner-up-left"] = "rbxassetid://84669279763024",
    ["corner-up-right"] = "rbxassetid://115099889693145",
    ["cpu"] = "rbxassetid://77549309870247",
    ["creative-commons"] = "rbxassetid://90408210735312",
    ["credit-card"] = "rbxassetid://99163352872346",
    ["croissant"] = "rbxassetid://130710485559420",
    ["crop"] = "rbxassetid://116344601101413",
    ["cross"] = "rbxassetid://101833377863588",
    ["crosshair"] = "rbxassetid://134242818164054",
    ["crown"] = "rbxassetid://127843403295538",
    ["cuboid"] = "rbxassetid://75618807946111",
    ["cup-soda"] = "rbxassetid://121098640829562",
    ["currency"] = "rbxassetid://90551250119972",
    ["cylinder"] = "rbxassetid://90569677179169",
    ["dam"] = "rbxassetid://76874486231393",
    ["database-backup"] = "rbxassetid://103403210984699",
    ["database-zap"] = "rbxassetid://131199921258418",
    ["database"] = "rbxassetid://126791525623846",
    ["decimals-arrow-left"] = "rbxassetid://120198500638749",
    ["decimals-arrow-right"] = "rbxassetid://118263047146797",
    ["delete"] = "rbxassetid://126279426372342",
    ["dessert"] = "rbxassetid://71508133278830",
    ["diameter"] = "rbxassetid://97429051503783",
    ["diamond-minus"] = "rbxassetid://128989071438290",
    ["diamond-percent"] = "rbxassetid://107717860105959",
    ["diamond-plus"] = "rbxassetid://134701163723675",
    ["diamond"] = "rbxassetid://105846996304890",
    ["dice-1"] = "rbxassetid://112650149591038",
    ["dice-2"] = "rbxassetid://112278274566793",
    ["dice-3"] = "rbxassetid://118526270626312",
    ["dice-4"] = "rbxassetid://113365650364004",
    ["dice-5"] = "rbxassetid://72768312430593",
    ["dice-6"] = "rbxassetid://85376239182543",
    ["dices"] = "rbxassetid://81268120302865",
    ["diff"] = "rbxassetid://135052708609715",
    ["disc-2"] = "rbxassetid://91419420404185",
    ["disc-3"] = "rbxassetid://135470554736048",
    ["disc-album"] = "rbxassetid://74693460404344",
    ["disc"] = "rbxassetid://101908120120777",
    ["divide"] = "rbxassetid://136678191878278",
    ["dna-off"] = "rbxassetid://89612426361540",
    ["dna"] = "rbxassetid://74007982981741",
    ["dock"] = "rbxassetid://121997427160252",
    ["dog"] = "rbxassetid://71920105558570",
    ["dollar-sign"] = "rbxassetid://127320961224019",
    ["donut"] = "rbxassetid://72204922742657",
    ["door-closed-locked"] = "rbxassetid://74027613267551",
    ["door-closed"] = "rbxassetid://136249099949073",
    ["door-open"] = "rbxassetid://91306356501736",
    ["dot"] = "rbxassetid://137321056643916",
    ["download"] = "rbxassetid://134814648082393",
    ["drafting-compass"] = "rbxassetid://99701976182841",
    ["drama"] = "rbxassetid://110297795801577",
    ["dribbble"] = "rbxassetid://80231809663849",
    ["drill"] = "rbxassetid://108644821412796",
    ["drone"] = "rbxassetid://117299095794783",
    ["droplet-off"] = "rbxassetid://119365002225172",
    ["droplet"] = "rbxassetid://100597455015098",
    ["droplets"] = "rbxassetid://140111846025180",
    ["drum"] = "rbxassetid://136979060344890",
    ["drumstick"] = "rbxassetid://104662462521709",
    ["dumbbell"] = "rbxassetid://80277236776212",
    ["ear-off"] = "rbxassetid://87421916192807",
    ["ear"] = "rbxassetid://121894949934209",
    ["earth-lock"] = "rbxassetid://88814147073745",
    ["earth"] = "rbxassetid://76231597751076",
    ["eclipse"] = "rbxassetid://114829622118222",
    ["egg-fried"] = "rbxassetid://90622538210545",
    ["egg-off"] = "rbxassetid://92288321309285",
    ["egg"] = "rbxassetid://117851493400222",
    ["ellipsis-vertical"] = "rbxassetid://117978708573781",
    ["ellipsis"] = "rbxassetid://140019550645825",
    ["equal-approximately"] = "rbxassetid://105382689698323",
    ["equal-not"] = "rbxassetid://76864449458032",
    ["equal"] = "rbxassetid://123467780715624",
    ["eraser"] = "rbxassetid://133957773112410",
    ["ethernet-port"] = "rbxassetid://75391715149314",
    ["euro"] = "rbxassetid://72229646524456",
    ["ev-charger"] = "rbxassetid://97906158859623",
    ["expand"] = "rbxassetid://137492887754537",
    ["external-link"] = "rbxassetid://129331830773832",
    ["eye-closed"] = "rbxassetid://111063268625789",
    ["eye-off"] = "rbxassetid://135928786788378",
    ["eye"] = "rbxassetid://100033680381365",
    ["facebook"] = "rbxassetid://72098528632192",
    ["factory"] = "rbxassetid://102170024318039",
    ["fan"] = "rbxassetid://78391400440696",
    ["fast-forward"] = "rbxassetid://121615540167909",
    ["feather"] = "rbxassetid://91872927606406",
    ["fence"] = "rbxassetid://123451565578029",
    ["ferris-wheel"] = "rbxassetid://79729205796176",
    ["figma"] = "rbxassetid://134182122852301",
    ["file-archive"] = "rbxassetid://77018106869967",
    ["file-axis-3d"] = "rbxassetid://133912328009885",
    ["file-badge"] = "rbxassetid://74564895394477",
    ["file-box"] = "rbxassetid://119264004071690",
    ["file-braces-corner"] = "rbxassetid://77253337986109",
    ["file-braces"] = "rbxassetid://95314128621234",
    ["file-chart-column-increasing"] = "rbxassetid://134449481172067",
    ["file-chart-column"] = "rbxassetid://82048481252560",
    ["file-chart-line"] = "rbxassetid://71954360551345",
    ["file-chart-pie"] = "rbxassetid://81072193564497",
    ["file-check-corner"] = "rbxassetid://76295552859171",
    ["file-check"] = "rbxassetid://82604001452455",
    ["file-clock"] = "rbxassetid://102325208830990",
    ["file-code-corner"] = "rbxassetid://78293841184371",
    ["file-code"] = "rbxassetid://130978036895504",
    ["file-cog"] = "rbxassetid://101385347151368",
    ["file-diff"] = "rbxassetid://96147216772241",
    ["file-digit"] = "rbxassetid://89220220354580",
    ["file-down"] = "rbxassetid://120650154178290",
    ["file-exclamation-point"] = "rbxassetid://102821865889635",
    ["file-headphone"] = "rbxassetid://100533735901986",
    ["file-heart"] = "rbxassetid://132214916401696",
    ["file-image"] = "rbxassetid://123334057511782",
    ["file-input"] = "rbxassetid://124728604166044",
    ["file-key"] = "rbxassetid://118790255921100",
    ["file-lock"] = "rbxassetid://72170228691242",
    ["file-minus-corner"] = "rbxassetid://119263271735124",
    ["file-minus"] = "rbxassetid://111014798459222",
    ["file-music"] = "rbxassetid://134948051536671",
    ["file-output"] = "rbxassetid://92146832572911",
    ["file-pen-line"] = "rbxassetid://104622936345006",
    ["file-pen"] = "rbxassetid://79556179730240",
    ["file-play"] = "rbxassetid://89006821567838",
    ["file-plus-corner"] = "rbxassetid://76544604043974",
    ["file-plus"] = "rbxassetid://78881710800060",
    ["file-question-mark"] = "rbxassetid://127617422859576",
    ["file-scan"] = "rbxassetid://129480105228213",
    ["file-search-corner"] = "rbxassetid://90974165234008",
    ["file-search"] = "rbxassetid://97780235974933",
    ["file-signal"] = "rbxassetid://122070252538165",
    ["file-sliders"] = "rbxassetid://85787771732439",
    ["file-spreadsheet"] = "rbxassetid://134501869359270",
    ["file-stack"] = "rbxassetid://138929929862605",
    ["file-symlink"] = "rbxassetid://91865722036510",
    ["file-terminal"] = "rbxassetid://116757454755476",
    ["file-text"] = "rbxassetid://90496405707281",
    ["file-type-corner"] = "rbxassetid://124902230275209",
    ["file-type"] = "rbxassetid://115272552799361",
    ["file-up"] = "rbxassetid://131173039312748",
    ["file-user"] = "rbxassetid://99552018455009",
    ["file-video-camera"] = "rbxassetid://81719056173960",
    ["file-volume"] = "rbxassetid://111264764438958",
    ["file-x-corner"] = "rbxassetid://87554136773609",
    ["file-x"] = "rbxassetid://107333775515154",
    ["file"] = "rbxassetid://74748492079329",
    ["files"] = "rbxassetid://102806336233202",
    ["film"] = "rbxassetid://120978945609706",
    ["fingerprint"] = "rbxassetid://112173305232811",
    ["fire-extinguisher"] = "rbxassetid://111643493006960",
    ["fish-off"] = "rbxassetid://89756724887508",
    ["fish-symbol"] = "rbxassetid://118475177681618",
    ["fish"] = "rbxassetid://124360663785796",
    ["flag-off"] = "rbxassetid://112944528856799",
    ["flag-triangle-left"] = "rbxassetid://88045221285272",
    ["flag-triangle-right"] = "rbxassetid://108292480304566",
    ["flag"] = "rbxassetid://78183383236196",
    ["flame-kindling"] = "rbxassetid://139728976917928",
    ["flame"] = "rbxassetid://98218034436456",
    ["flashlight-off"] = "rbxassetid://79780362871740",
    ["flashlight"] = "rbxassetid://100286985600444",
    ["flask-conical-off"] = "rbxassetid://112597970025298",
    ["flask-conical"] = "rbxassetid://128406680901165",
    ["flask-round"] = "rbxassetid://127508287324940",
    ["flip-horizontal-2"] = "rbxassetid://103726993598186",
    ["flip-horizontal"] = "rbxassetid://122937530107837",
    ["flip-vertical-2"] = "rbxassetid://103836358956328",
    ["flip-vertical"] = "rbxassetid://108003917346888",
    ["flower-2"] = "rbxassetid://72934574245145",
    ["flower"] = "rbxassetid://86129438272762",
    ["focus"] = "rbxassetid://87493973153317",
    ["fold-horizontal"] = "rbxassetid://92835712442240",
    ["fold-vertical"] = "rbxassetid://108873727253656",
    ["folder-archive"] = "rbxassetid://97312009460206",
    ["folder-check"] = "rbxassetid://128492920904557",
    ["folder-clock"] = "rbxassetid://111964836738545",
    ["folder-closed"] = "rbxassetid://118286209350843",
    ["folder-code"] = "rbxassetid://70624096349370",
    ["folder-cog"] = "rbxassetid://85299519462846",
    ["folder-dot"] = "rbxassetid://138687772725278",
    ["folder-down"] = "rbxassetid://118044108459225",
    ["folder-git-2"] = "rbxassetid://101394054141166",
    ["folder-git"] = "rbxassetid://121885778095158",
    ["folder-heart"] = "rbxassetid://79104747211105",
    ["folder-input"] = "rbxassetid://90699920697871",
    ["folder-kanban"] = "rbxassetid://78313285104072",
    ["folder-key"] = "rbxassetid://85270407596791",
    ["folder-lock"] = "rbxassetid://119201572260567",
    ["folder-minus"] = "rbxassetid://85648718999010",
    ["folder-open-dot"] = "rbxassetid://74741494767354",
    ["folder-open"] = "rbxassetid://76018996254888",
    ["folder-output"] = "rbxassetid://101532447937612",
    ["folder-pen"] = "rbxassetid://112770491173911",
    ["folder-plus"] = "rbxassetid://91865663406119",
    ["folder-root"] = "rbxassetid://103333751154693",
    ["folder-search-2"] = "rbxassetid://71276453442655",
    ["folder-search"] = "rbxassetid://110568075123861",
    ["folder-symlink"] = "rbxassetid://127485747227189",
    ["folder-sync"] = "rbxassetid://91544602659796",
    ["folder-tree"] = "rbxassetid://85577554337861",
    ["folder-up"] = "rbxassetid://72008269765857",
    ["folder-x"] = "rbxassetid://91699618247635",
    ["folder"] = "rbxassetid://80846616596607",
    ["folders"] = "rbxassetid://110351216219061",
    ["footprints"] = "rbxassetid://139192589041315",
    ["forklift"] = "rbxassetid://72030930983101",
    ["forward"] = "rbxassetid://97545944739523",
    ["frame"] = "rbxassetid://109080612832751",
    ["framer"] = "rbxassetid://108384807262391",
    ["frown"] = "rbxassetid://124407301067982",
    ["fuel"] = "rbxassetid://106447647274511",
    ["fullscreen"] = "rbxassetid://77793665526178",
    ["funnel-plus"] = "rbxassetid://100780233821928",
    ["funnel-x"] = "rbxassetid://70984385812555",
    ["funnel"] = "rbxassetid://108829540827529",
    ["gallery-horizontal-end"] = "rbxassetid://74672430161161",
    ["gallery-horizontal"] = "rbxassetid://80004001442122",
    ["gallery-thumbnails"] = "rbxassetid://136219289862706",
    ["gallery-vertical-end"] = "rbxassetid://106461402088317",
    ["gallery-vertical"] = "rbxassetid://119299431466725",
    ["gamepad-2"] = "rbxassetid://92483947987410",
    ["gamepad-directional"] = "rbxassetid://84342305212226",
    ["gamepad"] = "rbxassetid://121607283959010",
    ["gauge"] = "rbxassetid://110273524101447",
    ["gavel"] = "rbxassetid://78952298198456",
    ["gem"] = "rbxassetid://112904952151156",
    ["georgian-lari"] = "rbxassetid://98084432591687",
    ["ghost"] = "rbxassetid://113822048130017",
    ["gift"] = "rbxassetid://109855212076373",
    ["git-branch-minus"] = "rbxassetid://97385010649411",
    ["git-branch-plus"] = "rbxassetid://125944221134316",
    ["git-branch"] = "rbxassetid://90490195516649",
    ["git-commit-horizontal"] = "rbxassetid://133646041800147",
    ["git-commit-vertical"] = "rbxassetid://122098032990350",
    ["git-compare-arrows"] = "rbxassetid://84874426520216",
    ["git-compare"] = "rbxassetid://91945124438792",
    ["git-fork"] = "rbxassetid://89954992404765",
    ["git-graph"] = "rbxassetid://86166832019304",
    ["git-merge"] = "rbxassetid://131833355158059",
    ["git-pull-request-arrow"] = "rbxassetid://94507974577439",
    ["git-pull-request-closed"] = "rbxassetid://78070600389091",
    ["git-pull-request-create-arrow"] = "rbxassetid://127422677061091",
    ["git-pull-request-create"] = "rbxassetid://105929577383926",
    ["git-pull-request-draft"] = "rbxassetid://76173459869943",
    ["git-pull-request"] = "rbxassetid://138463010991471",
    ["github"] = "rbxassetid://120349554354380",
    ["gitlab"] = "rbxassetid://114054627192933",
    ["glass-water"] = "rbxassetid://115526102400988",
    ["glasses"] = "rbxassetid://87936407455373",
    ["globe-lock"] = "rbxassetid://134065526704402",
    ["globe"] = "rbxassetid://114238209622913",
    ["goal"] = "rbxassetid://120517954878160",
    ["gpu"] = "rbxassetid://95577823614219",
    ["graduation-cap"] = "rbxassetid://93771896340220",
    ["grape"] = "rbxassetid://134760640415561",
    ["grid-2x2-check"] = "rbxassetid://138468840220821",
    ["grid-2x2-plus"] = "rbxassetid://91811610580247",
    ["grid-2x2-x"] = "rbxassetid://72407303981388",
    ["grid-2x2"] = "rbxassetid://99050491897640",
    ["grid-3x2"] = "rbxassetid://95528684210010",
    ["grid-3x3"] = "rbxassetid://70419024781206",
    ["grip-horizontal"] = "rbxassetid://136255899715930",
    ["grip-vertical"] = "rbxassetid://137183678565296",
    ["grip"] = "rbxassetid://109058783556768",
    ["group"] = "rbxassetid://107643418926671",
    ["guitar"] = "rbxassetid://75915531867926",
    ["ham"] = "rbxassetid://74465607934635",
    ["hamburger"] = "rbxassetid://93086916815495",
    ["hammer"] = "rbxassetid://83545120140895",
    ["hand-coins"] = "rbxassetid://126990543175462",
    ["hand-fist"] = "rbxassetid://83341608917591",
    ["hand-grab"] = "rbxassetid://88867162163985",
    ["hand-heart"] = "rbxassetid://117507367668412",
    ["hand-helping"] = "rbxassetid://89897738419446",
    ["hand-metal"] = "rbxassetid://113619498548713",
    ["hand-platter"] = "rbxassetid://88594727743168",
    ["hand"] = "rbxassetid://130703864968637",
    ["handbag"] = "rbxassetid://135675846264061",
    ["handshake"] = "rbxassetid://78442115255814",
    ["hard-drive-download"] = "rbxassetid://73913801230614",
    ["hard-drive-upload"] = "rbxassetid://85762133615118",
    ["hard-drive"] = "rbxassetid://88183305858463",
    ["hard-hat"] = "rbxassetid://128050846767382",
    ["hash"] = "rbxassetid://82890331678520",
    ["hat-glasses"] = "rbxassetid://101165538224815",
    ["haze"] = "rbxassetid://108857561768901",
    ["hdmi-port"] = "rbxassetid://103693661037020",
    ["heading-1"] = "rbxassetid://118129315662110",
    ["heading-2"] = "rbxassetid://110209069670094",
    ["heading-3"] = "rbxassetid://90267885237062",
    ["heading-4"] = "rbxassetid://129625620307602",
    ["heading-5"] = "rbxassetid://120386663181267",
    ["heading-6"] = "rbxassetid://90959079775093",
    ["heading"] = "rbxassetid://129254312067735",
    ["headphone-off"] = "rbxassetid://85038251615641",
    ["headphones"] = "rbxassetid://118833729589183",
    ["headset"] = "rbxassetid://129269236787694",
    ["heart-crack"] = "rbxassetid://110987638564119",
    ["heart-handshake"] = "rbxassetid://111483078692002",
    ["heart-minus"] = "rbxassetid://96827380163326",
    ["heart-off"] = "rbxassetid://89748414415617",
    ["heart-plus"] = "rbxassetid://94877796283249",
    ["heart-pulse"] = "rbxassetid://129352925579546",
    ["heart"] = "rbxassetid://116559368303288",
    ["heater"] = "rbxassetid://140478466880916",
    ["helicopter"] = "rbxassetid://111557171735930",
    ["hexagon"] = "rbxassetid://127592089339199",
    ["highlighter"] = "rbxassetid://77411555641113",
    ["history"] = "rbxassetid://123980022019922",
    ["hop-off"] = "rbxassetid://103386036934034",
    ["hop"] = "rbxassetid://82778923997672",
    ["hospital"] = "rbxassetid://105868763850707",
    ["hotel"] = "rbxassetid://132283390859718",
    ["hourglass"] = "rbxassetid://86160434939203",
    ["house-heart"] = "rbxassetid://136054771868597",
    ["house-plug"] = "rbxassetid://71438263712075",
    ["house-plus"] = "rbxassetid://118495165208309",
    ["house-wifi"] = "rbxassetid://126495519725698",
    ["house"] = "rbxassetid://98755624629571",
    ["ice-cream-bowl"] = "rbxassetid://124867218454386",
    ["ice-cream-cone"] = "rbxassetid://90751397288639",
    ["id-card-lanyard"] = "rbxassetid://90761480469224",
    ["id-card"] = "rbxassetid://75354294622640",
    ["image-down"] = "rbxassetid://78972295741235",
    ["image-minus"] = "rbxassetid://101066016918565",
    ["image-off"] = "rbxassetid://81934811700938",
    ["image-play"] = "rbxassetid://129501806784210",
    ["image-plus"] = "rbxassetid://70391970623917",
    ["image-up"] = "rbxassetid://126610009605241",
    ["image-upscale"] = "rbxassetid://106963545024679",
    ["images"] = "rbxassetid://79350649395557",
    ["import"] = "rbxassetid://116545008906029",
    ["inbox"] = "rbxassetid://112591360302868",
    ["indian-rupee"] = "rbxassetid://113038778381805",
    ["infinity"] = "rbxassetid://98083086936965",
    ["info"] = "rbxassetid://124560466474914",
    ["inspection-panel"] = "rbxassetid://70905313146088",
    ["instagram"] = "rbxassetid://119864798614855",
    ["italic"] = "rbxassetid://96220378864282",
    ["iteration-ccw"] = "rbxassetid://140221832794083",
    ["iteration-cw"] = "rbxassetid://95534489554662",
    ["japanese-yen"] = "rbxassetid://106362863465813",
    ["joystick"] = "rbxassetid://99416790224739",
    ["kanban"] = "rbxassetid://125934100055431",
    ["kayak"] = "rbxassetid://136107544609389",
    ["key-round"] = "rbxassetid://83619031955390",
    ["key-square"] = "rbxassetid://94621420033649",
    ["key"] = "rbxassetid://96510194465420",
    ["keyboard-music"] = "rbxassetid://121058541758636",
    ["keyboard-off"] = "rbxassetid://92466375369772",
    ["keyboard"] = "rbxassetid://121474456068237",
    ["lamp-ceiling"] = "rbxassetid://80032758469141",
    ["lamp-desk"] = "rbxassetid://85290686983238",
    ["lamp-floor"] = "rbxassetid://104585881375892",
    ["lamp-wall-down"] = "rbxassetid://91271394132073",
    ["lamp-wall-up"] = "rbxassetid://132141464337445",
    ["lamp"] = "rbxassetid://110730830653382",
    ["land-plot"] = "rbxassetid://96449039620294",
    ["landmark"] = "rbxassetid://76885079756393",
    ["languages"] = "rbxassetid://90816903776498",
    ["laptop-minimal-check"] = "rbxassetid://114352019833865",
    ["laptop-minimal"] = "rbxassetid://136705765566068",
    ["laptop"] = "rbxassetid://111387063244975",
    ["lasso-select"] = "rbxassetid://105609719912753",
    ["lasso"] = "rbxassetid://121072936884007",
    ["laugh"] = "rbxassetid://104491311361166",
    ["layers-2"] = "rbxassetid://70536710516357",
    ["layers"] = "rbxassetid://81973586053257",
    ["layout-dashboard"] = "rbxassetid://139929981863901",
    ["layout-grid"] = "rbxassetid://81344910161871",
    ["layout-list"] = "rbxassetid://87462136296578",
    ["layout-panel-left"] = "rbxassetid://125092469751491",
    ["layout-panel-top"] = "rbxassetid://91943941515944",
    ["layout-template"] = "rbxassetid://115564446417985",
    ["leaf"] = "rbxassetid://119951075637174",
    ["leafy-green"] = "rbxassetid://105146290493154",
    ["lectern"] = "rbxassetid://106166425183862",
    ["library-big"] = "rbxassetid://106794530191412",
    ["library"] = "rbxassetid://114334671982047",
    ["life-buoy"] = "rbxassetid://81168450671956",
    ["ligature"] = "rbxassetid://111397873269411",
    ["lightbulb-off"] = "rbxassetid://83795722296178",
    ["lightbulb"] = "rbxassetid://103871245626488",
    ["line-squiggle"] = "rbxassetid://109555164424447",
    ["link-2-off"] = "rbxassetid://76885956296867",
    ["link-2"] = "rbxassetid://86072351557466",
    ["link"] = "rbxassetid://131607023382430",
    ["linkedin"] = "rbxassetid://132842789255788",
    ["list-check"] = "rbxassetid://72374358471156",
    ["list-checks"] = "rbxassetid://99809353635593",
    ["list-chevrons-down-up"] = "rbxassetid://137409641500711",
    ["list-chevrons-up-down"] = "rbxassetid://81825351389084",
    ["list-collapse"] = "rbxassetid://124505247702401",
    ["list-end"] = "rbxassetid://77650610048119",
    ["list-filter-plus"] = "rbxassetid://96385120752336",
    ["list-filter"] = "rbxassetid://103321376129527",
    ["list-indent-decrease"] = "rbxassetid://137879979228193",
    ["list-indent-increase"] = "rbxassetid://79051053161201",
    ["list-minus"] = "rbxassetid://138507965142671",
    ["list-music"] = "rbxassetid://126380635781840",
    ["list-ordered"] = "rbxassetid://83212528113913",
    ["list-plus"] = "rbxassetid://112384738137814",
    ["list-restart"] = "rbxassetid://91703153577421",
    ["list-start"] = "rbxassetid://84828348299727",
    ["list-todo"] = "rbxassetid://132980603752108",
    ["list-tree"] = "rbxassetid://97685396239010",
    ["list-video"] = "rbxassetid://93648525452489",
    ["list-x"] = "rbxassetid://113025303988861",
    ["list"] = "rbxassetid://113179976918783",
    ["loader-circle"] = "rbxassetid://116535712789945",
    ["loader-pinwheel"] = "rbxassetid://108513357940900",
    ["loader"] = "rbxassetid://78408734580845",
    ["locate-fixed"] = "rbxassetid://137367361548433",
    ["locate-off"] = "rbxassetid://73729216338137",
    ["locate"] = "rbxassetid://84467676590391",
    ["lock-keyhole-open"] = "rbxassetid://110863509313073",
    ["lock-keyhole"] = "rbxassetid://78672912777756",
    ["lock-open"] = "rbxassetid://93597915325122",
    ["lock"] = "rbxassetid://134724289526879",
    ["log-in"] = "rbxassetid://103768533135201",
    ["log-out"] = "rbxassetid://84895399304975",
    ["logs"] = "rbxassetid://89772091251787",
    ["lollipop"] = "rbxassetid://84681611583044",
    ["luggage"] = "rbxassetid://76619236486400",
    ["magnet"] = "rbxassetid://135162361226972",
    ["mail-check"] = "rbxassetid://86921536259917",
    ["mail-minus"] = "rbxassetid://81989813236553",
    ["mail-open"] = "rbxassetid://122785416858638",
    ["mail-plus"] = "rbxassetid://104886401588341",
    ["mail-question-mark"] = "rbxassetid://126540170949819",
    ["mail-search"] = "rbxassetid://135616173775287",
    ["mail-warning"] = "rbxassetid://81495303676089",
    ["mail-x"] = "rbxassetid://74607841705644",
    ["mail"] = "rbxassetid://103945161245599",
    ["mailbox"] = "rbxassetid://82765503320335",
    ["mails"] = "rbxassetid://90673453450080",
    ["map-minus"] = "rbxassetid://129525760577747",
    ["map-pin-check-inside"] = "rbxassetid://107130529843809",
    ["map-pin-check"] = "rbxassetid://118110914690154",
    ["map-pin-house"] = "rbxassetid://80546885029816",
    ["map-pin-minus-inside"] = "rbxassetid://79005529692964",
    ["map-pin-minus"] = "rbxassetid://74518762643623",
    ["map-pin-off"] = "rbxassetid://82474689391020",
    ["map-pin-pen"] = "rbxassetid://113515395277504",
    ["map-pin-plus-inside"] = "rbxassetid://134639656514430",
    ["map-pin-plus"] = "rbxassetid://91875228967029",
    ["map-pin-x-inside"] = "rbxassetid://126235934252379",
    ["map-pin-x"] = "rbxassetid://101085273547316",
    ["map-pin"] = "rbxassetid://84279202219901",
    ["map-pinned"] = "rbxassetid://103963788475034",
    ["map-plus"] = "rbxassetid://129388826743495",
    ["map"] = "rbxassetid://95107167260947",
    ["mars-stroke"] = "rbxassetid://131973193186828",
    ["mars"] = "rbxassetid://111287112372511",
    ["martini"] = "rbxassetid://82977695401058",
    ["maximize-2"] = "rbxassetid://73085922906397",
    ["maximize"] = "rbxassetid://76045941763188",
    ["medal"] = "rbxassetid://79016002264450",
    ["megaphone-off"] = "rbxassetid://124280774193935",
    ["megaphone"] = "rbxassetid://118759541854879",
    ["meh"] = "rbxassetid://132197867028557",
    ["memory-stick"] = "rbxassetid://93212591343119",
    ["menu"] = "rbxassetid://77021539815611",
    ["merge"] = "rbxassetid://126201866476775",
    ["message-circle-code"] = "rbxassetid://112865244991651",
    ["message-circle-dashed"] = "rbxassetid://81525157881897",
    ["message-circle-heart"] = "rbxassetid://101990756073677",
    ["message-circle-more"] = "rbxassetid://92856823884663",
    ["message-circle-off"] = "rbxassetid://134955643890328",
    ["message-circle-plus"] = "rbxassetid://106562979649273",
    ["message-circle-question-mark"] = "rbxassetid://107700302759934",
    ["message-circle-reply"] = "rbxassetid://137071749508334",
    ["message-circle-warning"] = "rbxassetid://119020096067894",
    ["message-circle-x"] = "rbxassetid://126843387725536",
    ["message-circle"] = "rbxassetid://127255077587058",
    ["message-square-code"] = "rbxassetid://110968863152123",
    ["message-square-dashed"] = "rbxassetid://107653455516238",
    ["message-square-diff"] = "rbxassetid://75472190472625",
    ["message-square-dot"] = "rbxassetid://127806382463916",
    ["message-square-heart"] = "rbxassetid://75612811742074",
    ["message-square-lock"] = "rbxassetid://81268215619563",
    ["message-square-more"] = "rbxassetid://120139782405970",
    ["message-square-off"] = "rbxassetid://99961019005789",
    ["message-square-plus"] = "rbxassetid://76934450256199",
    ["message-square-quote"] = "rbxassetid://116670768629340",
    ["message-square-reply"] = "rbxassetid://130985622754637",
    ["message-square-share"] = "rbxassetid://131017005324026",
    ["message-square-text"] = "rbxassetid://94899503194205",
    ["message-square-warning"] = "rbxassetid://138432903962261",
    ["message-square-x"] = "rbxassetid://137285463279462",
    ["message-square"] = "rbxassetid://83881670383280",
    ["messages-square"] = "rbxassetid://97532166733358",
    ["mic-off"] = "rbxassetid://82123034444822",
    ["mic-vocal"] = "rbxassetid://99082286164362",
    ["mic"] = "rbxassetid://89640799126523",
    ["microchip"] = "rbxassetid://73937907669903",
    ["microscope"] = "rbxassetid://116875530102782",
    ["microwave"] = "rbxassetid://108411735353008",
    ["milestone"] = "rbxassetid://101618292325920",
    ["milk-off"] = "rbxassetid://72388480962742",
    ["milk"] = "rbxassetid://96221903896918",
    ["minimize-2"] = "rbxassetid://116269596042539",
    ["minimize"] = "rbxassetid://121304296213645",
    ["minus"] = "rbxassetid://118026365011536",
    ["monitor-check"] = "rbxassetid://86651948439229",
    ["monitor-cloud"] = "rbxassetid://85931096038318",
    ["monitor-cog"] = "rbxassetid://94345128715799",
    ["monitor-dot"] = "rbxassetid://130394010063680",
    ["monitor-down"] = "rbxassetid://97466933743423",
    ["monitor-off"] = "rbxassetid://74395526657953",
    ["monitor-pause"] = "rbxassetid://76002184067562",
    ["monitor-play"] = "rbxassetid://133018824306217",
    ["monitor-smartphone"] = "rbxassetid://84335680433378",
    ["monitor-speaker"] = "rbxassetid://81744810060380",
    ["monitor-stop"] = "rbxassetid://98708958984757",
    ["monitor-up"] = "rbxassetid://96035360858377",
    ["monitor-x"] = "rbxassetid://126265210441423",
    ["monitor"] = "rbxassetid://72664649203050",
    ["moon-star"] = "rbxassetid://82782200506348",
    ["moon"] = "rbxassetid://83380517901735",
    ["motorbike"] = "rbxassetid://94580787368233",
    ["mountain-snow"] = "rbxassetid://105315495740588",
    ["mountain"] = "rbxassetid://73269957566415",
    ["mouse-off"] = "rbxassetid://75267871697595",
    ["mouse-pointer-2-off"] = "rbxassetid://104701076865632",
    ["mouse-pointer-2"] = "rbxassetid://117093892862228",
    ["mouse-pointer-ban"] = "rbxassetid://106849413057133",
    ["mouse-pointer-click"] = "rbxassetid://107150227368485",
    ["mouse-pointer"] = "rbxassetid://72322454962935",
    ["mouse"] = "rbxassetid://73096068864710",
    ["move-3d"] = "rbxassetid://103365982054003",
    ["move-diagonal-2"] = "rbxassetid://117298577948096",
    ["move-diagonal"] = "rbxassetid://101433481954184",
    ["move-down-left"] = "rbxassetid://102819433534567",
    ["move-down-right"] = "rbxassetid://101479760041877",
    ["move-down"] = "rbxassetid://70510115135583",
    ["move-horizontal"] = "rbxassetid://88513523439149",
    ["move-left"] = "rbxassetid://137614740247980",
    ["move-right"] = "rbxassetid://132455779472989",
    ["move-up-left"] = "rbxassetid://139079815540148",
    ["move-up-right"] = "rbxassetid://105885140592646",
    ["move-up"] = "rbxassetid://84505444262658",
    ["move-vertical"] = "rbxassetid://86234730730899",
    ["move"] = "rbxassetid://116138709011735",
    ["music-2"] = "rbxassetid://134397426600888",
    ["music-3"] = "rbxassetid://94466120066498",
    ["music-4"] = "rbxassetid://132459323665838",
    ["music"] = "rbxassetid://113343203848535",
    ["navigation-2-off"] = "rbxassetid://116569611780763",
    ["navigation-2"] = "rbxassetid://81889066747907",
    ["navigation-off"] = "rbxassetid://87003270290777",
    ["navigation"] = "rbxassetid://79308213542922",
    ["network"] = "rbxassetid://127410729922644",
    ["newspaper"] = "rbxassetid://123479530460544",
    ["nfc"] = "rbxassetid://76822396542242",
    ["non-binary"] = "rbxassetid://78442360386235",
    ["notebook-pen"] = "rbxassetid://140380614761023",
    ["notebook-tabs"] = "rbxassetid://127371085570083",
    ["notebook-text"] = "rbxassetid://93061585217270",
    ["notebook"] = "rbxassetid://136132108664987",
    ["notepad-text-dashed"] = "rbxassetid://135793446376219",
    ["notepad-text"] = "rbxassetid://93404682958966",
    ["nut-off"] = "rbxassetid://78795397311573",
    ["nut"] = "rbxassetid://127146410705656",
    ["octagon-alert"] = "rbxassetid://140438367956051",
    ["octagon-minus"] = "rbxassetid://74720436795421",
    ["octagon-pause"] = "rbxassetid://103161463909039",
    ["octagon-x"] = "rbxassetid://90498161006311",
    ["octagon"] = "rbxassetid://120803515514852",
    ["omega"] = "rbxassetid://70414080018786",
    ["option"] = "rbxassetid://100776883894054",
    ["orbit"] = "rbxassetid://108926136860562",
    ["origami"] = "rbxassetid://136020626667101",
    ["package-2"] = "rbxassetid://70394974762575",
    ["package-check"] = "rbxassetid://102374216055130",
    ["package-minus"] = "rbxassetid://114492858789692",
    ["package-open"] = "rbxassetid://132890233237818",
    ["package-plus"] = "rbxassetid://129261988138366",
    ["package-search"] = "rbxassetid://95465120894145",
    ["package-x"] = "rbxassetid://70818501607442",
    ["package"] = "rbxassetid://97261141732706",
    ["paint-bucket"] = "rbxassetid://124275586663284",
    ["paint-roller"] = "rbxassetid://115248074358348",
    ["paintbrush-vertical"] = "rbxassetid://105151296591292",
    ["paintbrush"] = "rbxassetid://125572663700289",
    ["palette"] = "rbxassetid://86350350950064",
    ["panda"] = "rbxassetid://132509022802512",
    ["panel-bottom-close"] = "rbxassetid://74287004071159",
    ["panel-bottom-dashed"] = "rbxassetid://131084651621603",
    ["panel-bottom-open"] = "rbxassetid://107768659586540",
    ["panel-bottom"] = "rbxassetid://132127145048511",
    ["panel-left-close"] = "rbxassetid://126579818823552",
    ["panel-left-dashed"] = "rbxassetid://75536606374585",
    ["panel-left-open"] = "rbxassetid://111075816195767",
    ["panel-left-right-dashed"] = "rbxassetid://110100707973959",
    ["panel-left"] = "rbxassetid://97419752870313",
    ["panel-right-close"] = "rbxassetid://139528655524132",
    ["panel-right-dashed"] = "rbxassetid://94959793877311",
    ["panel-right-open"] = "rbxassetid://118114419142794",
    ["panel-right"] = "rbxassetid://116365035443156",
    ["panel-top-bottom-dashed"] = "rbxassetid://134737235653344",
    ["panel-top-close"] = "rbxassetid://83578325777808",
    ["panel-top-dashed"] = "rbxassetid://70522913169237",
    ["panel-top-open"] = "rbxassetid://137959875507454",
    ["panel-top"] = "rbxassetid://75838479462875",
    ["panels-left-bottom"] = "rbxassetid://72996856149149",
    ["panels-right-bottom"] = "rbxassetid://90659068960726",
    ["panels-top-left"] = "rbxassetid://79858853850600",
    ["paperclip"] = "rbxassetid://92088291163453",
    ["parentheses"] = "rbxassetid://78950955173096",
    ["parking-meter"] = "rbxassetid://84652733960568",
    ["party-popper"] = "rbxassetid://111626795712193",
    ["pause"] = "rbxassetid://74873705394436",
    ["paw-print"] = "rbxassetid://112218825427601",
    ["pc-case"] = "rbxassetid://122978648019101",
    ["pen-line"] = "rbxassetid://109108135755303",
    ["pen-off"] = "rbxassetid://84807123119438",
    ["pen-tool"] = "rbxassetid://106145404953445",
    ["pen"] = "rbxassetid://72037878096321",
    ["pencil-line"] = "rbxassetid://88392917053533",
    ["pencil-off"] = "rbxassetid://103330927652832",
    ["pencil-ruler"] = "rbxassetid://110120288284597",
    ["pencil"] = "rbxassetid://137986121120732",
    ["pentagon"] = "rbxassetid://79184802179890",
    ["percent"] = "rbxassetid://130155041032013",
    ["person-standing"] = "rbxassetid://125020872044147",
    ["philippine-peso"] = "rbxassetid://91173798254675",
    ["phone-call"] = "rbxassetid://70555587592860",
    ["phone-forwarded"] = "rbxassetid://113269614319737",
    ["phone-incoming"] = "rbxassetid://82863576359288",
    ["phone-missed"] = "rbxassetid://130156165198376",
    ["phone-off"] = "rbxassetid://133318623553383",
    ["phone-outgoing"] = "rbxassetid://104576478735825",
    ["phone"] = "rbxassetid://128804946640049",
    ["pi"] = "rbxassetid://74936036243146",
    ["piano"] = "rbxassetid://85008880789520",
    ["pickaxe"] = "rbxassetid://105888023317688",
    ["picture-in-picture-2"] = "rbxassetid://112803319544468",
    ["picture-in-picture"] = "rbxassetid://80579597835123",
    ["piggy-bank"] = "rbxassetid://79498575790721",
    ["pilcrow-left"] = "rbxassetid://103803000849583",
    ["pilcrow-right"] = "rbxassetid://104881733911870",
    ["pilcrow"] = "rbxassetid://139512780392871",
    ["pill-bottle"] = "rbxassetid://118394692404597",
    ["pill"] = "rbxassetid://73280534813448",
    ["pin-off"] = "rbxassetid://127696372451750",
    ["pin"] = "rbxassetid://120978111007514",
    ["pipette"] = "rbxassetid://133167932934404",
    ["pizza"] = "rbxassetid://126964453193501",
    ["plane-landing"] = "rbxassetid://122555692211889",
    ["plane-takeoff"] = "rbxassetid://117179478829575",
    ["plane"] = "rbxassetid://126985561580989",
    ["play"] = "rbxassetid://135609604299893",
    ["plug-2"] = "rbxassetid://97912386476366",
    ["plug-zap"] = "rbxassetid://74506269884055",
    ["plug"] = "rbxassetid://99782373064495",
    ["plus"] = "rbxassetid://111774323017047",
    ["pocket-knife"] = "rbxassetid://134075428063965",
    ["pocket"] = "rbxassetid://136686762542964",
    ["podcast"] = "rbxassetid://109577075549215",
    ["pointer-off"] = "rbxassetid://95488389312794",
    ["pointer"] = "rbxassetid://92615117311099",
    ["popcorn"] = "rbxassetid://139446511232750",
    ["popsicle"] = "rbxassetid://112696318077073",
    ["pound-sterling"] = "rbxassetid://127482649469130",
    ["power-off"] = "rbxassetid://118768311012214",
    ["power"] = "rbxassetid://96479131758775",
    ["presentation"] = "rbxassetid://106134583757890",
    ["printer-check"] = "rbxassetid://130273549443689",
    ["printer"] = "rbxassetid://76080649734247",
    ["projector"] = "rbxassetid://103281856385283",
    ["proportions"] = "rbxassetid://130046855997237",
    ["puzzle"] = "rbxassetid://136837798892463",
    ["pyramid"] = "rbxassetid://107811442374127",
    ["qr-code"] = "rbxassetid://105329945723350",
    ["quote"] = "rbxassetid://103271711590001",
    ["rabbit"] = "rbxassetid://98580518804206",
    ["radar"] = "rbxassetid://138528222906635",
    ["radiation"] = "rbxassetid://104499586848433",
    ["radical"] = "rbxassetid://132758286926047",
    ["radio-receiver"] = "rbxassetid://129598303378835",
    ["radio-tower"] = "rbxassetid://93958663130054",
    ["radio"] = "rbxassetid://85611589536956",
    ["radius"] = "rbxassetid://89814505307129",
    ["rail-symbol"] = "rbxassetid://134295386306962",
    ["rainbow"] = "rbxassetid://132488862841895",
    ["rat"] = "rbxassetid://127400975953159",
    ["ratio"] = "rbxassetid://126369423897295",
    ["receipt-cent"] = "rbxassetid://91557573925201",
    ["receipt-euro"] = "rbxassetid://94015722210295",
    ["receipt-indian-rupee"] = "rbxassetid://89718170439990",
    ["receipt-japanese-yen"] = "rbxassetid://132472560758851",
    ["receipt-pound-sterling"] = "rbxassetid://73934967569625",
    ["receipt-russian-ruble"] = "rbxassetid://105164576936853",
    ["receipt-swiss-franc"] = "rbxassetid://72503668620116",
    ["receipt-text"] = "rbxassetid://138483536013737",
    ["receipt-turkish-lira"] = "rbxassetid://91950765836342",
    ["receipt"] = "rbxassetid://77877895901792",
    ["rectangle-circle"] = "rbxassetid://100642423153903",
    ["rectangle-ellipsis"] = "rbxassetid://112919953980965",
    ["rectangle-goggles"] = "rbxassetid://98605436666727",
    ["rectangle-horizontal"] = "rbxassetid://90224199814966",
    ["rectangle-vertical"] = "rbxassetid://117277050590967",
    ["recycle"] = "rbxassetid://140417023381961",
    ["redo-2"] = "rbxassetid://70451039017914",
    ["redo-dot"] = "rbxassetid://94252981719732",
    ["redo"] = "rbxassetid://116150342119054",
    ["refresh-ccw-dot"] = "rbxassetid://106702246753270",
    ["refresh-ccw"] = "rbxassetid://117913330389477",
    ["refresh-cw-off"] = "rbxassetid://140179498843054",
    ["refresh-cw"] = "rbxassetid://138133190015277",
    ["refrigerator"] = "rbxassetid://102614042652753",
    ["regex"] = "rbxassetid://100727200791841",
    ["remove-formatting"] = "rbxassetid://112833162022628",
    ["repeat-1"] = "rbxassetid://130144534857095",
    ["repeat-2"] = "rbxassetid://85927537182704",
    ["repeat"] = "rbxassetid://121886242955173",
    ["replace-all"] = "rbxassetid://127862728198635",
    ["replace"] = "rbxassetid://128404082279430",
    ["reply-all"] = "rbxassetid://71723137343562",
    ["reply"] = "rbxassetid://109788633497028",
    ["rewind"] = "rbxassetid://95205297521988",
    ["ribbon"] = "rbxassetid://94265331526851",
    ["rocket"] = "rbxassetid://87412317685854",
    ["rocking-chair"] = "rbxassetid://110420269495360",
    ["roller-coaster"] = "rbxassetid://112426178972099",
    ["rose"] = "rbxassetid://126336840238769",
    ["rotate-3d"] = "rbxassetid://76300551576392",
    ["rotate-ccw-key"] = "rbxassetid://74976035240976",
    ["rotate-ccw-square"] = "rbxassetid://90515853170424",
    ["rotate-ccw"] = "rbxassetid://110116685948665",
    ["rotate-cw-square"] = "rbxassetid://77095448159303",
    ["rotate-cw"] = "rbxassetid://84183336178654",
    ["route-off"] = "rbxassetid://106350402024079",
    ["route"] = "rbxassetid://89968303228953",
    ["router"] = "rbxassetid://102130331994471",
    ["rows-2"] = "rbxassetid://112556185960101",
    ["rows-3"] = "rbxassetid://117215586961375",
    ["rows-4"] = "rbxassetid://125646021959055",
    ["rss"] = "rbxassetid://131789058984793",
    ["ruler-dimension-line"] = "rbxassetid://70673861371412",
    ["ruler"] = "rbxassetid://81432445547423",
    ["russian-ruble"] = "rbxassetid://126357936542156",
    ["sailboat"] = "rbxassetid://87110567187540",
    ["salad"] = "rbxassetid://128864507821603",
    ["sandwich"] = "rbxassetid://104573187458917",
    ["satellite-dish"] = "rbxassetid://136742443888305",
    ["satellite"] = "rbxassetid://134967053164645",
    ["saudi-riyal"] = "rbxassetid://102282769104635",
    ["save-all"] = "rbxassetid://116946975799440",
    ["save-off"] = "rbxassetid://87085435778560",
    ["save"] = "rbxassetid://126116963775616",
    ["scale-3d"] = "rbxassetid://72414199620352",
    ["scale"] = "rbxassetid://108203682317477",
    ["scaling"] = "rbxassetid://122360365318466",
    ["scan-barcode"] = "rbxassetid://96889457154761",
    ["scan-eye"] = "rbxassetid://99244790601968",
    ["scan-face"] = "rbxassetid://109959345069668",
    ["scan-heart"] = "rbxassetid://106280819776142",
    ["scan-line"] = "rbxassetid://126544908146540",
    ["scan-qr-code"] = "rbxassetid://105409149549927",
    ["scan-search"] = "rbxassetid://80009010551347",
    ["scan-text"] = "rbxassetid://73702396787766",
    ["scan"] = "rbxassetid://123104789658180",
    ["school"] = "rbxassetid://76351530290068",
    ["scissors-line-dashed"] = "rbxassetid://122237447974173",
    ["scissors"] = "rbxassetid://118665510911274",
    ["screen-share-off"] = "rbxassetid://107677572669805",
    ["screen-share"] = "rbxassetid://85137895705653",
    ["scroll-text"] = "rbxassetid://97321022666868",
    ["scroll"] = "rbxassetid://74072101474951",
    ["search-check"] = "rbxassetid://75442076191356",
    ["search-code"] = "rbxassetid://117114794592802",
    ["search-slash"] = "rbxassetid://96483932261041",
    ["search-x"] = "rbxassetid://137319957522951",
    ["search"] = "rbxassetid://121018724060431",
    ["section"] = "rbxassetid://91732188298948",
    ["send-horizontal"] = "rbxassetid://111734392411664",
    ["send-to-back"] = "rbxassetid://75340312862253",
    ["send"] = "rbxassetid://127751956873796",
    ["separator-horizontal"] = "rbxassetid://84864453699927",
    ["separator-vertical"] = "rbxassetid://84031801478581",
    ["server-cog"] = "rbxassetid://138470287250966",
    ["server-crash"] = "rbxassetid://132810618000212",
    ["server-off"] = "rbxassetid://114048751507723",
    ["server"] = "rbxassetid://92188766517878",
    ["settings-2"] = "rbxassetid://135684703553372",
    ["settings"] = "rbxassetid://80758916183665",
    ["shapes"] = "rbxassetid://129989433311409",
    ["share-2"] = "rbxassetid://71210767962065",
    ["share"] = "rbxassetid://87340985053299",
    ["sheet"] = "rbxassetid://134902122480171",
    ["shell"] = "rbxassetid://140212943563599",
    ["shield-alert"] = "rbxassetid://114995877719925",
    ["shield-ban"] = "rbxassetid://108765041044649",
    ["shield-check"] = "rbxassetid://87354736164608",
    ["shield-ellipsis"] = "rbxassetid://114794739892123",
    ["shield-half"] = "rbxassetid://117842634172647",
    ["shield-minus"] = "rbxassetid://89965059528921",
    ["shield-off"] = "rbxassetid://133426959132690",
    ["shield-plus"] = "rbxassetid://100664857995498",
    ["shield-question-mark"] = "rbxassetid://135722075265150",
    ["shield-user"] = "rbxassetid://124832775645347",
    ["shield-x"] = "rbxassetid://73370117343811",
    ["shield"] = "rbxassetid://110987169760162",
    ["ship-wheel"] = "rbxassetid://130797795829448",
    ["ship"] = "rbxassetid://83995100553930",
    ["shirt"] = "rbxassetid://106579555405966",
    ["shopping-bag"] = "rbxassetid://71885477293226",
    ["shopping-basket"] = "rbxassetid://138646411956433",
    ["shopping-cart"] = "rbxassetid://128420521375441",
    ["shovel"] = "rbxassetid://102465000512056",
    ["shower-head"] = "rbxassetid://75884944024117",
    ["shredder"] = "rbxassetid://122125164414463",
    ["shrimp"] = "rbxassetid://102625900815307",
    ["shrink"] = "rbxassetid://90953687918880",
    ["shrub"] = "rbxassetid://127326280714343",
    ["shuffle"] = "rbxassetid://132382786975101",
    ["sigma"] = "rbxassetid://126884244870899",
    ["signal-high"] = "rbxassetid://130436670012270",
    ["signal-low"] = "rbxassetid://73674683500458",
    ["signal-medium"] = "rbxassetid://125003021367019",
    ["signal-zero"] = "rbxassetid://130045332414754",
    ["signal"] = "rbxassetid://78424889355261",
    ["signature"] = "rbxassetid://114402748013000",
    ["signpost-big"] = "rbxassetid://115780185675001",
    ["signpost"] = "rbxassetid://106584743791433",
    ["siren"] = "rbxassetid://134210267818039",
    ["skip-back"] = "rbxassetid://70466132711334",
    ["skip-forward"] = "rbxassetid://124844823753990",
    ["skull"] = "rbxassetid://137726256442333",
    ["slack"] = "rbxassetid://96089719516736",
    ["slash"] = "rbxassetid://117792185664263",
    ["slice"] = "rbxassetid://95810504278179",
    ["sliders-horizontal"] = "rbxassetid://85538382643347",
    ["sliders-vertical"] = "rbxassetid://101190569086853",
    ["smartphone-charging"] = "rbxassetid://102837532613995",
    ["smartphone-nfc"] = "rbxassetid://82326425754446",
    ["smartphone"] = "rbxassetid://96623008834511",
    ["smile-plus"] = "rbxassetid://131981881472144",
    ["smile"] = "rbxassetid://105880397565283",
    ["snail"] = "rbxassetid://70904536548363",
    ["snowflake"] = "rbxassetid://101235206534566",
    ["soap-dispenser-droplet"] = "rbxassetid://77258480479465",
    ["sofa"] = "rbxassetid://114427687218324",
    ["solar-panel"] = "rbxassetid://132448188047921",
    ["soup"] = "rbxassetid://115092551871618",
    ["space"] = "rbxassetid://87072088914178",
    ["spade"] = "rbxassetid://131444449466462",
    ["sparkle"] = "rbxassetid://111044800239623",
    ["sparkles"] = "rbxassetid://138635884129147",
    ["speaker"] = "rbxassetid://96227183003618",
    ["speech"] = "rbxassetid://87013139446349",
    ["spell-check-2"] = "rbxassetid://81556731785534",
    ["spell-check"] = "rbxassetid://91913483031334",
    ["spline-pointer"] = "rbxassetid://84842840956804",
    ["spline"] = "rbxassetid://129406685807412",
    ["split"] = "rbxassetid://105112438805988",
    ["spool"] = "rbxassetid://124541981347743",
    ["spotlight"] = "rbxassetid://77571742539344",
    ["spray-can"] = "rbxassetid://128372039366326",
    ["sprout"] = "rbxassetid://100091687832508",
    ["square-activity"] = "rbxassetid://89496630185293",
    ["square-arrow-down-left"] = "rbxassetid://108194680296901",
    ["square-arrow-down-right"] = "rbxassetid://99403846801050",
    ["square-arrow-down"] = "rbxassetid://135962519626588",
    ["square-arrow-left"] = "rbxassetid://111671474549238",
    ["square-arrow-out-down-left"] = "rbxassetid://125714881756353",
    ["square-arrow-out-down-right"] = "rbxassetid://89971003001390",
    ["square-arrow-out-up-left"] = "rbxassetid://103759986579087",
    ["square-arrow-out-up-right"] = "rbxassetid://91221896066807",
    ["square-arrow-right"] = "rbxassetid://113920471701361",
    ["square-arrow-up-left"] = "rbxassetid://112424670290693",
    ["square-arrow-up-right"] = "rbxassetid://76602291406940",
    ["square-arrow-up"] = "rbxassetid://106998604646718",
    ["square-asterisk"] = "rbxassetid://89186832353625",
    ["square-bottom-dashed-scissors"] = "rbxassetid://79076980104803",
    ["square-chart-gantt"] = "rbxassetid://104034017316411",
    ["square-check-big"] = "rbxassetid://115320390907184",
    ["square-check"] = "rbxassetid://134682053539509",
    ["square-chevron-down"] = "rbxassetid://91032307924592",
    ["square-chevron-left"] = "rbxassetid://73143404829510",
    ["square-chevron-right"] = "rbxassetid://90612077729930",
    ["square-chevron-up"] = "rbxassetid://85565910197337",
    ["square-code"] = "rbxassetid://81604576616881",
    ["square-dashed-bottom-code"] = "rbxassetid://100354801563230",
    ["square-dashed-bottom"] = "rbxassetid://101102319625624",
    ["square-dashed-kanban"] = "rbxassetid://90388067649847",
    ["square-dashed-mouse-pointer"] = "rbxassetid://121016142178467",
    ["square-dashed-top-solid"] = "rbxassetid://117157577548540",
    ["square-dashed"] = "rbxassetid://136905537847606",
    ["square-divide"] = "rbxassetid://99894657101970",
    ["square-dot"] = "rbxassetid://116613421354866",
    ["square-equal"] = "rbxassetid://110283363706707",
    ["square-function"] = "rbxassetid://86075219551088",
    ["square-kanban"] = "rbxassetid://114537101260131",
    ["square-library"] = "rbxassetid://73810931222081",
    ["square-m"] = "rbxassetid://117662700410577",
    ["square-menu"] = "rbxassetid://104067089444415",
    ["square-minus"] = "rbxassetid://116764432015770",
    ["square-mouse-pointer"] = "rbxassetid://76141850603920",
    ["square-parking-off"] = "rbxassetid://100857293535141",
    ["square-parking"] = "rbxassetid://133116656122387",
    ["square-pause"] = "rbxassetid://86608552787615",
    ["square-pen"] = "rbxassetid://120239476110475",
    ["square-percent"] = "rbxassetid://87111930314567",
    ["square-pi"] = "rbxassetid://75383328781618",
    ["square-pilcrow"] = "rbxassetid://131854284699367",
    ["square-play"] = "rbxassetid://108186325238481",
    ["square-plus"] = "rbxassetid://114713264461873",
    ["square-power"] = "rbxassetid://129240437805187",
    ["square-radical"] = "rbxassetid://132645931868292",
    ["square-round-corner"] = "rbxassetid://104592745113567",
    ["square-scissors"] = "rbxassetid://110601255612411",
    ["square-sigma"] = "rbxassetid://113231244246816",
    ["square-slash"] = "rbxassetid://105477013908757",
    ["square-split-horizontal"] = "rbxassetid://76095370148660",
    ["square-split-vertical"] = "rbxassetid://88589192032058",
    ["square-square"] = "rbxassetid://136555087357875",
    ["square-stack"] = "rbxassetid://100463396619394",
    ["square-star"] = "rbxassetid://94506958703720",
    ["square-stop"] = "rbxassetid://80018708472943",
    ["square-terminal"] = "rbxassetid://83969264476798",
    ["square-user-round"] = "rbxassetid://86484997229302",
    ["square-user"] = "rbxassetid://70771214183445",
    ["square-x"] = "rbxassetid://125136183850190",
    ["square"] = "rbxassetid://86304921356806",
    ["squares-exclude"] = "rbxassetid://102345385822324",
    ["squares-intersect"] = "rbxassetid://120869602570119",
    ["squares-subtract"] = "rbxassetid://131484650948795",
    ["squares-unite"] = "rbxassetid://96673080107843",
    ["squircle-dashed"] = "rbxassetid://129936702532522",
    ["squircle"] = "rbxassetid://82426632573807",
    ["squirrel"] = "rbxassetid://112864252085343",
    ["stamp"] = "rbxassetid://92370779813368",
    ["star-half"] = "rbxassetid://117449275562979",
    ["star-off"] = "rbxassetid://75742832732503",
    ["star"] = "rbxassetid://136141469398409",
    ["step-back"] = "rbxassetid://108672750005121",
    ["step-forward"] = "rbxassetid://126131872136145",
    ["stethoscope"] = "rbxassetid://122331031702148",
    ["sticker"] = "rbxassetid://79938203791608",
    ["sticky-note"] = "rbxassetid://111894074643919",
    ["store"] = "rbxassetid://90338129673705",
    ["stretch-horizontal"] = "rbxassetid://87665042192343",
    ["stretch-vertical"] = "rbxassetid://95265463417122",
    ["strikethrough"] = "rbxassetid://103417324549613",
    ["subscript"] = "rbxassetid://74553514785183",
    ["sun-dim"] = "rbxassetid://129141645592715",
    ["sun-medium"] = "rbxassetid://130278807964710",
    ["sun-moon"] = "rbxassetid://75752898854559",
    ["sun-snow"] = "rbxassetid://112791898014579",
    ["sun"] = "rbxassetid://110150589884127",
    ["sunrise"] = "rbxassetid://134705665494098",
    ["sunset"] = "rbxassetid://75904872203588",
    ["superscript"] = "rbxassetid://96887696590118",
    ["swatch-book"] = "rbxassetid://126786244872453",
    ["swiss-franc"] = "rbxassetid://113497920041625",
    ["switch-camera"] = "rbxassetid://76841154349737",
    ["sword"] = "rbxassetid://124448418211665",
    ["swords"] = "rbxassetid://81872698913435",
    ["syringe"] = "rbxassetid://123891270479254",
    ["table-2"] = "rbxassetid://95751552281545",
    ["table-cells-merge"] = "rbxassetid://95363715175258",
    ["table-cells-split"] = "rbxassetid://114799086088649",
    ["table-columns-split"] = "rbxassetid://111011625447949",
    ["table-of-contents"] = "rbxassetid://135044763275414",
    ["table-properties"] = "rbxassetid://125062886015372",
    ["table-rows-split"] = "rbxassetid://96443733673997",
    ["table"] = "rbxassetid://109109148250737",
    ["tablet-smartphone"] = "rbxassetid://133680859813404",
    ["tablet"] = "rbxassetid://128403991264386",
    ["tablets"] = "rbxassetid://80835787970735",
    ["tag"] = "rbxassetid://129104970103940",
    ["tags"] = "rbxassetid://107179263080798",
    ["tally-1"] = "rbxassetid://115301298241643",
    ["tally-2"] = "rbxassetid://110363186864027",
    ["tally-3"] = "rbxassetid://97655344572540",
    ["tally-4"] = "rbxassetid://102633494371890",
    ["tally-5"] = "rbxassetid://88031817475886",
    ["tangent"] = "rbxassetid://123263132981724",
    ["target"] = "rbxassetid://87563802520297",
    ["telescope"] = "rbxassetid://91755049143647",
    ["tent-tree"] = "rbxassetid://76698322463977",
    ["tent"] = "rbxassetid://109779587826330",
    ["terminal"] = "rbxassetid://106783148545356",
    ["test-tube-diagonal"] = "rbxassetid://75662704378840",
    ["test-tube"] = "rbxassetid://98801015650164",
    ["test-tubes"] = "rbxassetid://92555361447433",
    ["text-align-center"] = "rbxassetid://84051028246390",
    ["text-align-end"] = "rbxassetid://130041738343555",
    ["text-align-justify"] = "rbxassetid://80279880143030",
    ["text-align-start"] = "rbxassetid://134489585487649",
    ["text-cursor-input"] = "rbxassetid://107551944047171",
    ["text-cursor"] = "rbxassetid://115984654447300",
    ["text-initial"] = "rbxassetid://129458097472087",
    ["text-quote"] = "rbxassetid://139278366448736",
    ["text-search"] = "rbxassetid://92345384671606",
    ["text-select"] = "rbxassetid://117087320884956",
    ["text-wrap"] = "rbxassetid://114804318314018",
    ["theater"] = "rbxassetid://108558145549163",
    ["thermometer-snowflake"] = "rbxassetid://121876188028425",
    ["thermometer-sun"] = "rbxassetid://106693240074310",
    ["thermometer"] = "rbxassetid://106546011492311",
    ["thumbs-down"] = "rbxassetid://87794009914015",
    ["thumbs-up"] = "rbxassetid://111137070767020",
    ["ticket-check"] = "rbxassetid://105428777212507",
    ["ticket-minus"] = "rbxassetid://78966299769328",
    ["ticket-percent"] = "rbxassetid://80834774406405",
    ["ticket-plus"] = "rbxassetid://110086734392189",
    ["ticket-slash"] = "rbxassetid://89045681172265",
    ["ticket-x"] = "rbxassetid://88674114109926",
    ["ticket"] = "rbxassetid://126527071492145",
    ["tickets-plane"] = "rbxassetid://100367018248695",
    ["tickets"] = "rbxassetid://135268612687833",
    ["timer-off"] = "rbxassetid://110916370767271",
    ["timer-reset"] = "rbxassetid://110052125369932",
    ["timer"] = "rbxassetid://85473888890506",
    ["toggle-left"] = "rbxassetid://85887872573050",
    ["toggle-right"] = "rbxassetid://90411952142550",
    ["toilet"] = "rbxassetid://80930782432931",
    ["tool-case"] = "rbxassetid://87533537832522",
    ["tornado"] = "rbxassetid://88358291515768",
    ["torus"] = "rbxassetid://70855707283051",
    ["touchpad-off"] = "rbxassetid://78784008075456",
    ["touchpad"] = "rbxassetid://74882354908014",
    ["tower-control"] = "rbxassetid://95937619060532",
    ["toy-brick"] = "rbxassetid://86293483924633",
    ["tractor"] = "rbxassetid://103376704722051",
    ["traffic-cone"] = "rbxassetid://74110220470369",
    ["train-front-tunnel"] = "rbxassetid://105194827005114",
    ["train-front"] = "rbxassetid://125237934215370",
    ["train-track"] = "rbxassetid://77451032453723",
    ["tram-front"] = "rbxassetid://93315182364998",
    ["transgender"] = "rbxassetid://135530817673639",
    ["trash-2"] = "rbxassetid://109843431391323",
    ["trash"] = "rbxassetid://106723740584310",
    ["tree-deciduous"] = "rbxassetid://123124389219004",
    ["tree-palm"] = "rbxassetid://103846705893963",
    ["tree-pine"] = "rbxassetid://124662547202594",
    ["trees"] = "rbxassetid://121203841375919",
    ["trello"] = "rbxassetid://130987241149527",
    ["trending-down"] = "rbxassetid://139309232226438",
    ["trending-up-down"] = "rbxassetid://85083293981691",
    ["trending-up"] = "rbxassetid://81819858538839",
    ["triangle-alert"] = "rbxassetid://125920361880643",
    ["triangle-dashed"] = "rbxassetid://124324079103935",
    ["triangle-right"] = "rbxassetid://116930791412791",
    ["triangle"] = "rbxassetid://126330486745540",
    ["trophy"] = "rbxassetid://131545003268773",
    ["truck-electric"] = "rbxassetid://111873446387359",
    ["truck"] = "rbxassetid://86662707764771",
    ["turkish-lira"] = "rbxassetid://114589876174070",
    ["turntable"] = "rbxassetid://129870346487856",
    ["turtle"] = "rbxassetid://118295081560334",
    ["tv-minimal-play"] = "rbxassetid://99201833426972",
    ["tv-minimal"] = "rbxassetid://100382201729427",
    ["tv"] = "rbxassetid://135687724791776",
    ["twitch"] = "rbxassetid://71383308134888",
    ["twitter"] = "rbxassetid://88791703276842",
    ["type-outline"] = "rbxassetid://80108627791690",
    ["type"] = "rbxassetid://133543553793564",
    ["umbrella-off"] = "rbxassetid://72395143739955",
    ["umbrella"] = "rbxassetid://127502210274589",
    ["underline"] = "rbxassetid://123709229216544",
    ["undo-2"] = "rbxassetid://113885292059932",
    ["undo-dot"] = "rbxassetid://132055277744844",
    ["undo"] = "rbxassetid://111258459077271",
    ["unfold-horizontal"] = "rbxassetid://117128358526398",
    ["unfold-vertical"] = "rbxassetid://116593025265499",
    ["ungroup"] = "rbxassetid://106674800451003",
    ["university"] = "rbxassetid://84652528263642",
    ["unlink-2"] = "rbxassetid://128131898892572",
    ["unlink"] = "rbxassetid://139835795227752",
    ["unplug"] = "rbxassetid://90171381619874",
    ["upload"] = "rbxassetid://138212042425501",
    ["usb"] = "rbxassetid://117230058949613",
    ["user-check"] = "rbxassetid://81775205032725",
    ["user-cog"] = "rbxassetid://92795491530865",
    ["user-lock"] = "rbxassetid://78892639693821",
    ["user-minus"] = "rbxassetid://126976941957511",
    ["user-pen"] = "rbxassetid://87445472574836",
    ["user-plus"] = "rbxassetid://118514469915884",
    ["user-round-check"] = "rbxassetid://118794737621941",
    ["user-round-cog"] = "rbxassetid://78239503290053",
    ["user-round-minus"] = "rbxassetid://98944176636447",
    ["user-round-pen"] = "rbxassetid://108155244324878",
    ["user-round-plus"] = "rbxassetid://113301899567470",
    ["user-round-search"] = "rbxassetid://71565774381870",
    ["user-round-x"] = "rbxassetid://122367980560930",
    ["user-round"] = "rbxassetid://136485052187963",
    ["user-search"] = "rbxassetid://101335649828115",
    ["user-star"] = "rbxassetid://98777846316000",
    ["user-x"] = "rbxassetid://139748155894754",
    ["user"] = "rbxassetid://81589895647169",
    ["users-round"] = "rbxassetid://103005444008339",
    ["users"] = "rbxassetid://115398113982385",
    ["utensils-crossed"] = "rbxassetid://109520762270383",
    ["utensils"] = "rbxassetid://139952569804235",
    ["utility-pole"] = "rbxassetid://101965541238242",
    ["variable"] = "rbxassetid://104743088438151",
    ["vault"] = "rbxassetid://108049164599845",
    ["vector-square"] = "rbxassetid://86713728565344",
    ["vegan"] = "rbxassetid://119489190688082",
    ["venetian-mask"] = "rbxassetid://102636443033920",
    ["venus-and-mars"] = "rbxassetid://120227752103771",
    ["venus"] = "rbxassetid://82891342220859",
    ["vibrate-off"] = "rbxassetid://113446447326246",
    ["vibrate"] = "rbxassetid://108330910738733",
    ["video-off"] = "rbxassetid://132239189859305",
    ["video"] = "rbxassetid://107587444636945",
    ["videotape"] = "rbxassetid://114816894323398",
    ["view"] = "rbxassetid://118717253976805",
    ["voicemail"] = "rbxassetid://134313454010227",
    ["volleyball"] = "rbxassetid://83889351124153",
    ["volume-1"] = "rbxassetid://98514588731639",
    ["volume-2"] = "rbxassetid://89344380902620",
    ["volume-off"] = "rbxassetid://103047478058767",
    ["volume-x"] = "rbxassetid://139252359189540",
    ["volume"] = "rbxassetid://103236289817396",
    ["vote"] = "rbxassetid://89409762851246",
    ["wallet-cards"] = "rbxassetid://129728715308337",
    ["wallet-minimal"] = "rbxassetid://137800448816116",
    ["wallet"] = "rbxassetid://132331555762628",
    ["wallpaper"] = "rbxassetid://74682121235494",
    ["wand-sparkles"] = "rbxassetid://82546429942392",
    ["wand"] = "rbxassetid://114580617777835",
    ["warehouse"] = "rbxassetid://78388887451080",
    ["washing-machine"] = "rbxassetid://104194127573858",
    ["watch"] = "rbxassetid://130544621618405",
    ["waves-ladder"] = "rbxassetid://101808619355514",
    ["waves"] = "rbxassetid://96340135183647",
    ["waypoints"] = "rbxassetid://102450133666017",
    ["webcam"] = "rbxassetid://104148487911129",
    ["webhook-off"] = "rbxassetid://96370548093471",
    ["webhook"] = "rbxassetid://112812457747322",
    ["weight"] = "rbxassetid://103860559844854",
    ["wheat-off"] = "rbxassetid://133294844612307",
    ["wheat"] = "rbxassetid://85261952080359",
    ["whole-word"] = "rbxassetid://90111083954485",
    ["wifi-cog"] = "rbxassetid://110500263326209",
    ["wifi-high"] = "rbxassetid://81954601342139",
    ["wifi-low"] = "rbxassetid://138217335635913",
    ["wifi-off"] = "rbxassetid://74113634330106",
    ["wifi-pen"] = "rbxassetid://91290205064712",
    ["wifi-sync"] = "rbxassetid://84043971055177",
    ["wifi-zero"] = "rbxassetid://124286465246123",
    ["wifi"] = "rbxassetid://104669375183960",
    ["wind-arrow-down"] = "rbxassetid://127753987414870",
    ["wind"] = "rbxassetid://114551690399915",
    ["wine-off"] = "rbxassetid://108294164302317",
    ["wine"] = "rbxassetid://115743721332829",
    ["workflow"] = "rbxassetid://99186544029189",
    ["worm"] = "rbxassetid://115752311548091",
    ["wrench"] = "rbxassetid://112148279212860",
    ["x"] = "rbxassetid://110786993356448",
    ["youtube"] = "rbxassetid://123663668456341",
    ["zap-off"] = "rbxassetid://81385483183652",
    ["zap"] = "rbxassetid://130551565616516",
    ["zoom-in"] = "rbxassetid://127956924984803",
    ["zoom-out"] = "rbxassetid://108334162607319",
    ["balloon"] = "rbxassetid://97489111621526",
    ["beef-off"] = "rbxassetid://99869959725200",
    ["book-search"] = "rbxassetid://132585409504950",
    ["calendars"] = "rbxassetid://130944763042289",
    ["cannabis-off"] = "rbxassetid://101938500363812",
    ["cctv-off"] = "rbxassetid://75925370187295",
    ["cigarette"] = "rbxassetid://137149549886852",
    ["circle-pile"] = "rbxassetid://116353155251541",
    ["cloud-backup"] = "rbxassetid://111649579696132",
    ["cloud-sync"] = "rbxassetid://79393911188593",
    ["database-search"] = "rbxassetid://92017137080138",
    ["ellipse"] = "rbxassetid://71559658267482",
    ["fingerprint-pattern"] = "rbxassetid://80934710831288",
    ["fishing-hook"] = "rbxassetid://121038780855899",
    ["fishing-rod"] = "rbxassetid://71754848048049",
    ["form"] = "rbxassetid://72999643971000",
    ["git-merge-conflict"] = "rbxassetid://85677801675703",
    ["globe-off"] = "rbxassetid://77775243585824",
    ["globe-x"] = "rbxassetid://109268097029296",
    ["hd"] = "rbxassetid://71682790698278",
    ["image"] = "rbxassetid://112751259236831",
    ["layers-plus"] = "rbxassetid://77587765623057",
    ["lens-concave"] = "rbxassetid://94819631937027",
    ["lens-convex"] = "rbxassetid://74736504195474",
    ["line-dot-right-horizontal"] = "rbxassetid://104718593155221",
    ["line-style"] = "rbxassetid://90176717785772",
    ["map-pin-search"] = "rbxassetid://89065012915078",
    ["message-circle-check"] = "rbxassetid://132772297689418",
    ["message-square-check"] = "rbxassetid://125789987055668",
    ["metronome"] = "rbxassetid://101991829345965",
    ["mirror-rectangular"] = "rbxassetid://109046769760336",
    ["mirror-round"] = "rbxassetid://121534049429097",
    ["mouse-left"] = "rbxassetid://99144293708743",
    ["mouse-right"] = "rbxassetid://88331710212594",
    ["printer-x"] = "rbxassetid://103002721801548",
    ["radio-off"] = "rbxassetid://80359258046586",
    ["road"] = "rbxassetid://120251329173530",
    ["scooter"] = "rbxassetid://100035452787934",
    ["search-alert"] = "rbxassetid://127597984617505",
    ["shelving-unit"] = "rbxassetid://80116568514793",
    ["shield-cog-corner"] = "rbxassetid://111694066132698",
    ["shield-cog"] = "rbxassetid://129235695057857",
    ["sport-shoe"] = "rbxassetid://120495992692630",
    ["square-arrow-right-enter"] = "rbxassetid://138867831495334",
    ["square-arrow-right-exit"] = "rbxassetid://133688575845430",
    ["square-centerline-dashed-horizontal"] = "rbxassetid://77780104374341",
    ["square-centerline-dashed-vertical"] = "rbxassetid://107878435803525",
    ["stone"] = "rbxassetid://135161057497830",
    ["toolbox"] = "rbxassetid://85341033903792",
    ["towel-rack"] = "rbxassetid://125223915620991",
    ["user-key"] = "rbxassetid://105403041782190",
    ["user-round-key"] = "rbxassetid://124547549008939",
    ["van"] = "rbxassetid://122066377022942",
    ["waves-arrow-down"] = "rbxassetid://129215220911792",
    ["waves-arrow-up"] = "rbxassetid://102314705716217",
    ["weight-tilde"] = "rbxassetid://112081212176951",
    ["x-line-top"] = "rbxassetid://140592656289509",
    ["zodiac-aquarius"] = "rbxassetid://74560047770362",
    ["zodiac-aries"] = "rbxassetid://73255859670234",
    ["zodiac-cancer"] = "rbxassetid://131985162532947",
    ["zodiac-capricorn"] = "rbxassetid://97859568140652",
    ["zodiac-gemini"] = "rbxassetid://80997588122992",
    ["zodiac-leo"] = "rbxassetid://75509406718106",
    ["zodiac-libra"] = "rbxassetid://113222735060218",
    ["zodiac-ophiuchus"] = "rbxassetid://129180108892480",
    ["zodiac-pisces"] = "rbxassetid://95845819440327",
    ["zodiac-sagittarius"] = "rbxassetid://82651026742181",
    ["zodiac-scorpio"] = "rbxassetid://113640924054631",
    ["zodiac-taurus"] = "rbxassetid://123053219704400",
    ["zodiac-virgo"] = "rbxassetid://99462994613661",
}

local IconAliases: { [string]: string } = {
    home = "house",
    aimbot = "crosshair",
    aim = "crosshair",
    combat = "crosshair",
    trigger = "circle-dot",
    visual = "eye",
    visuals = "eye",
    options = "settings",
    config = "settings",
    gear = "settings",
    player = "user",
    kronos = "orbit",
    color = "palette",
    ["no-recoil"] = "shield-check",
    ["check-circle"] = "circle-check",
    ["x-circle"] = "circle-x",
    sliders = "sliders-horizontal",
    layoutdashboard = "layout-dashboard",
    paneldashboard = "panels-top-left",
}

-- Accept lower-case compact spellings such as `layoutdashboard` without
-- weakening canonical kebab-case resolution. Collisions retain the first
-- canonical asset deterministically.
local CompactIconNames: { [string]: string } = {}
for canonicalName in pairs(LucideAssets) do
    local compactName = string.gsub(canonicalName, "%-", "")
    if CompactIconNames[compactName] == nil then
        CompactIconNames[compactName] = canonicalName
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
local IconController: AnyTable = {
    Cache = {} :: { [string]: string },
    Canonical = {} :: { [string]: string },
    Valid = {} :: { [string]: boolean },
    InvalidWarned = {} :: { [string]: boolean },
}
local AnimationController = {}
local InputController: AnyTable = {
    KeyboardHandlers = setmetatable({}, { __mode = "k" }),
}
local DragController = {}
local AppearanceController: AnyTable = { Records = Kronos.SurfaceBindings }
local BorderController: AnyTable = { Records = Kronos.BorderBindings }

local SurfaceDepth = {
    Background = 0,
    BackgroundSoft = 0.32,
    Surface = 0.58,
    Surface2 = 0.74,
    Surface3 = 0.9,
    ElevatedSurface = 0.96,
    SurfaceHover = 1,
    HoverSurface = 1,
    PressedSurface = 1,
    AcrylicTint = 0.68,
}

local SurfaceTransparencyWeight = {
    Background = 0.5,
    BackgroundSoft = 0.64,
    Surface = 0.84,
    Surface2 = 0.79,
    Surface3 = 0.68,
    ElevatedSurface = 0.61,
    SurfaceHover = 0.76,
    HoverSurface = 0.76,
    PressedSurface = 0.7,
    AcrylicTint = 0.75,
}

local BorderRoleStrength = {
    Quiet = 0.46,
    Shell = 0.92,
    MainShellOuter = 1,
    InnerHighlight = 0.42,
    MainShellInner = 0.5,
    HeaderDivider = 0.72,
    SidebarDivider = 0.76,
    ContentDivider = 0.64,
    Section = 0.52,
    Control = 0.48,
    Hover = 0.8,
    ControlHover = 0.8,
    Focus = 1.06,
    ControlFocused = 1.06,
    Disabled = 0.36,
    ControlDisabled = 0.36,
    Dropdown = 0.88,
    Popup = 1,
    ColorPicker = 0.96,
    Settings = 0.94,
    Notification = 0.9,
    Floating = 0.92,
    FloatingWidget = 0.94,
    ScrollTrack = 0.46,
    Reopen = 0.92,
    ReopenButton = 0.92,
    AcrylicHighlight = 0.42,
    Error = 1.08,
    Accent = 1,
}

local BorderStyles = {
    Quiet = { Transparency = 0.9, Thickness = 1 },
    Shell = { Transparency = 0.62, Thickness = 1 },
    MainShellOuter = { Transparency = 0.56, Thickness = 1 },
    InnerHighlight = { Transparency = 0.91, Thickness = 1 },
    MainShellInner = { Transparency = 0.88, Thickness = 1 },
    HeaderDivider = { Transparency = 0.72, Thickness = 1 },
    SidebarDivider = { Transparency = 0.7, Thickness = 1 },
    ContentDivider = { Transparency = 0.78, Thickness = 1 },
    Section = { Transparency = 0.84, Thickness = 1 },
    Control = { Transparency = 0.88, Thickness = 1 },
    Hover = { Transparency = 0.68, Thickness = 1 },
    ControlHover = { Transparency = 0.68, Thickness = 1 },
    Focus = { Transparency = 0.4, Thickness = 1 },
    ControlFocused = { Transparency = 0.4, Thickness = 1 },
    Disabled = { Transparency = 0.92, Thickness = 1 },
    ControlDisabled = { Transparency = 0.92, Thickness = 1 },
    Dropdown = { Transparency = 0.66, Thickness = 1 },
    Popup = { Transparency = 0.56, Thickness = 1 },
    ColorPicker = { Transparency = 0.54, Thickness = 1 },
    Settings = { Transparency = 0.58, Thickness = 1 },
    Notification = { Transparency = 0.62, Thickness = 1 },
    Floating = { Transparency = 0.6, Thickness = 1 },
    FloatingWidget = { Transparency = 0.58, Thickness = 1 },
    ScrollTrack = { Transparency = 0.9, Thickness = 1 },
    Reopen = { Transparency = 0.58, Thickness = 1 },
    ReopenButton = { Transparency = 0.58, Thickness = 1 },
    AcrylicHighlight = { Transparency = 0.91, Thickness = 1 },
    Error = { Transparency = 0.44, Thickness = 1 },
    Accent = { Transparency = 0.48, Thickness = 1 },
}

local AcrylicRoleStrength = {
    MainWindow = 0.78,
    Surface = 0.88,
    Popup = 1.1,
    Dropdown = 1.06,
    ColorPicker = 1.1,
    Settings = 1.08,
    Notification = 1.08,
    TargetList = 1,
    KeybindList = 1,
    StatusStrip = 0.94,
    ReopenButton = 1.04,
    Floating = 1,
    FloatingWidget = 1,
    Tooltip = 1.04,
}

local AcrylicController: AnyTable = { Records = Kronos.AcrylicBindings }
local ScrollbarController: AnyTable = { Entries = Kronos.Scrollbars }
local SubtabController: AnyTable = {}
local PopupController = {}
local NotificationController = {}
local FloatingWidgetController = {}
local WindowController = {}
local NavigationController = {}
local ResponsiveController: AnyTable = {
    Records = setmetatable({}, { __mode = "k" }),
}
local Components = {}

function ThemeController:ResolveColor(token: string): Color3
    local color = Theme[token] or Theme.Text
    local depth = SurfaceDepth[token]
    if depth == nil or depth <= 0 then
        return color
    end

    local contrast = math.clamp(tonumber(Kronos.SurfaceContrast) or 1, 0.65, 1.4)
    if contrast < 1 then
        return color:Lerp(Theme.Background, (1 - contrast) * 0.72 * depth)
    end

    return color:Lerp(Theme.Text, (contrast - 1) * 0.11 * depth)
end

function ThemeController:Bind(instance: Instance, property: string, token: string)
    table.insert(Kronos.ThemeBindings, { Instance = instance, Property = property, Token = token })
    local appearanceRecord = AppearanceController.Records[instance]
    if property == "BackgroundColor3" and appearanceRecord then
        appearanceRecord.Token = token
        if instance:IsA("GuiObject") then
            (instance :: GuiObject).BackgroundTransparency =
                AppearanceController:Resolve(appearanceRecord.BaseTransparency, token)
        end
    end
    pcall(function()
        (instance :: any)[property] = self:ResolveColor(token)
    end)
end

function ThemeController:Refresh()
    for index = #Kronos.ThemeBindings, 1, -1 do
        local binding = Kronos.ThemeBindings[index]
        local instance = binding.Instance
        if not instance or instance.Parent == nil then
            table.remove(Kronos.ThemeBindings, index)
        else
            local active = Kronos.ActiveTweens[instance]
            if active and active[binding.Property] then
                AnimationController:Cancel(instance, true)
            end
            pcall(function()
                (instance :: any)[binding.Property] = self:ResolveColor(binding.Token)
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
    for instance in pairs(AppearanceController.Records) do
        if not instance.Parent or instance == root or instance:IsDescendantOf(root) then
            AppearanceController.Records[instance] = nil
        end
    end
    for instance in pairs(BorderController.Records) do
        if not instance.Parent or instance == root or instance:IsDescendantOf(root) then
            BorderController.Records[instance] = nil
        end
    end
    for instance in pairs(AcrylicController.Records) do
        if not instance.Parent or instance == root or instance:IsDescendantOf(root) then
            AcrylicController.Records[instance] = nil
        end
    end
end

function AppearanceController:IsSurfaceColor(color: any): boolean
    return color == Theme.Background
        or color == Theme.BackgroundSoft
        or color == Theme.Surface
        or color == Theme.Surface2
        or color == Theme.Surface3
        or color == Theme.ElevatedSurface
        or color == Theme.SurfaceHover
        or color == Theme.HoverSurface
        or color == Theme.PressedSurface
        or color == Theme.AcrylicTint
end

function AppearanceController:Resolve(baseTransparency: number, token: string?): number
    local base = math.clamp(tonumber(baseTransparency) or 0, 0, 1)
    local amount = math.clamp(tonumber(Kronos.SurfaceTransparency) or 0, 0, 1)
    local weight = SurfaceTransparencyWeight[token or ""] or 1
    return 1 - (1 - base) * (1 - math.clamp(amount * weight, 0, 0.94))
end

function AppearanceController:Register(instance: Instance, baseTransparency: number?): boolean
    if not instance:IsA("GuiObject") then
        return false
    end
    local guiObject = instance :: GuiObject
    if not self:IsSurfaceColor(guiObject.BackgroundColor3) then
        return false
    end
    local record = self.Records[instance]
    if not record then
        record = {}
        self.Records[instance] = record
    end
    record.BaseTransparency = math.clamp(
        tonumber(baseTransparency) or tonumber(record.BaseTransparency) or guiObject.BackgroundTransparency,
        0,
        1
    )
    guiObject.BackgroundTransparency = self:Resolve(record.BaseTransparency, record.Token)
    return true
end

function AppearanceController:SetBase(instance: Instance, baseTransparency: number): number
    local record = self.Records[instance]
    if not record then
        return baseTransparency
    end
    record.BaseTransparency = math.clamp(tonumber(baseTransparency) or 0, 0, 1)
    return self:Resolve(record.BaseTransparency, record.Token)
end

function AppearanceController:Refresh()
    for instance, record in pairs(self.Records) do
        if not instance.Parent then
            self.Records[instance] = nil
        elseif instance:IsA("GuiObject") then
            local guiObject = instance :: GuiObject
            local active = Kronos.ActiveTweens[guiObject]
            if active and active.BackgroundTransparency then
                AnimationController:Cancel(guiObject, true)
            end
            guiObject.BackgroundTransparency = self:Resolve(record.BaseTransparency, record.Token)
        end
    end
end

function BorderController:Resolve(baseTransparency: number, role: string?): number
    local base = math.clamp(tonumber(baseTransparency) or 0, 0, 1)
    local intensity = math.clamp(tonumber(Kronos.BorderIntensity) or 1, 0, 1.5)
    local roleStrength = BorderRoleStrength[role or ""] or 1
    return 1 - math.clamp((1 - base) * intensity * roleStrength, 0, 1)
end

function BorderController:Register(
    strokeObject: UIStroke,
    baseTransparency: number?,
    baseThickness: number?,
    role: string?
): UIStroke
    self.Records[strokeObject] = {
        BaseTransparency = math.clamp(tonumber(baseTransparency) or strokeObject.Transparency, 0, 1),
        BaseThickness = math.max(tonumber(baseThickness) or strokeObject.Thickness, 0.5),
        Role = role or "Control",
    }
    local record = self.Records[strokeObject]
    strokeObject:SetAttribute("KronosBorderRole", record.Role)
    strokeObject.Transparency = self:Resolve(record.BaseTransparency, record.Role)
    return strokeObject
end

function BorderController:SetBase(strokeObject: UIStroke, baseTransparency: number): number
    local record = self.Records[strokeObject]
    if not record then
        return baseTransparency
    end
    record.BaseTransparency = math.clamp(tonumber(baseTransparency) or 0, 0, 1)
    return self:Resolve(record.BaseTransparency, record.Role)
end

function BorderController:Refresh()
    local intensity = math.clamp(tonumber(Kronos.BorderIntensity) or 1, 0, 1.5)
    for strokeObject, record in pairs(self.Records) do
        if not strokeObject.Parent then
            self.Records[strokeObject] = nil
        else
            local active = Kronos.ActiveTweens[strokeObject]
            if active and active.Transparency then
                AnimationController:Cancel(strokeObject, true)
            end
            strokeObject.Transparency = self:Resolve(record.BaseTransparency, record.Role)
            strokeObject.Thickness = math.max(record.BaseThickness * (0.8 + 0.2 * math.min(intensity, 1)), 0.5)
        end
    end
end

function AnimationController:Duration(duration: number?): number
    if Kronos.ReducedMotion or Kronos.AnimationsEnabled == false then
        return 0
    end
    return math.max((duration or Motion.Hover) * math.clamp(Kronos.AnimationIntensity, 0, 2), 0)
end

function AnimationController:Cancel(instance: Instance, resolveTargets: boolean?)
    local activeByProperty = Kronos.ActiveTweens[instance]
    if not activeByProperty then
        return
    end
    local targetsByProperty = Kronos.ActiveTweenTargets[instance]
    local cancelled = {}
    for _, tweenObject in pairs(activeByProperty) do
        if not cancelled[tweenObject] then
            cancelled[tweenObject] = true
            pcall(tweenObject.Cancel, tweenObject)
        end
    end
    if resolveTargets and targetsByProperty then
        for property, value in pairs(targetsByProperty) do
            pcall(function()
                (instance :: any)[property] = value
            end)
        end
    end
    Kronos.ActiveTweens[instance] = nil
    Kronos.ActiveTweenTargets[instance] = nil
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
    if properties.BackgroundTransparency ~= nil then
        local resolved = AppearanceController:SetBase(instance, properties.BackgroundTransparency)
        if resolved ~= properties.BackgroundTransparency then
            local transformed = table.clone(properties)
            transformed.BackgroundTransparency = resolved
            properties = transformed
        end
    end
    if instance:IsA("UIStroke") and properties.Transparency ~= nil then
        local resolved = BorderController:SetBase(instance :: UIStroke, properties.Transparency)
        if resolved ~= properties.Transparency then
            local transformed = table.clone(properties)
            transformed.Transparency = resolved
            properties = transformed
        end
    end
    local resolvedDuration = self:Duration(duration)
    if resolvedDuration <= 0 then
        self:Cancel(instance)
        for property, value in pairs(properties) do
            pcall(function()
                (instance :: any)[property] = value
            end)
        end
        return nil
    end
    local activeByProperty = Kronos.ActiveTweens[instance]
    if not activeByProperty then
        activeByProperty = {}
        Kronos.ActiveTweens[instance] = activeByProperty
    end
    local targetsByProperty = Kronos.ActiveTweenTargets[instance]
    if not targetsByProperty then
        targetsByProperty = {}
        Kronos.ActiveTweenTargets[instance] = targetsByProperty
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
                targetsByProperty[property] = nil
            end
        end
    end
    local ok, result = pcall(function()
        return TweenService:Create(
            instance,
            TweenInfo.new(resolvedDuration, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
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
            Kronos.ActiveTweenTargets[instance] = nil
        end
        return nil
    end
    local tweenObject = result :: Tween
    for property in pairs(properties) do
        activeByProperty[property] = tweenObject
        targetsByProperty[property] = properties[property]
    end
    tweenObject.Completed:Once(function()
        local current = Kronos.ActiveTweens[instance]
        if not current then
            return
        end
        for property, active in pairs(current) do
            if active == tweenObject then
                current[property] = nil
                local currentTargets = Kronos.ActiveTweenTargets[instance]
                if currentTargets then
                    currentTargets[property] = nil
                end
            end
        end
        if next(current) == nil then
            Kronos.ActiveTweens[instance] = nil
            Kronos.ActiveTweenTargets[instance] = nil
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

local function pointInside(guiObject: GuiObject?, position: Vector3): boolean
    if not guiObject or not guiObject.Parent then
        return false
    end
    local absolutePosition = guiObject.AbsolutePosition
    local absoluteSize = guiObject.AbsoluteSize
    return position.X >= absolutePosition.X
        and position.X <= absolutePosition.X + absoluteSize.X
        and position.Y >= absolutePosition.Y
        and position.Y <= absolutePosition.Y + absoluteSize.Y
end

function InputController:_dispatch(stage: string, callback: any, ...: any): boolean
    if type(callback) ~= "function" then
        return true
    end
    local arguments = table.pack(...)
    local ok, err = xpcall(function()
        callback(table.unpack(arguments, 1, arguments.n))
    end, debug.traceback)
    if not ok then
        warn("[Kronos][InputController][" .. stage .. "] " .. tostring(err))
    end
    return ok
end

function InputController:Initialize()
    if self.Initialized then
        return
    end
    self.Initialized = true
    addConnection(
        Kronos,
        UserInputService.InputBegan:Connect(function(input, processed)
            if Kronos.Destroyed then
                return
            end
            for _, window in ipairs(table.clone(Kronos.Windows)) do
                if not window.Destroyed and type(window._handleInputBegan) == "function" then
                    self:_dispatch("InputBegan", window._handleInputBegan, window, input, processed)
                end
            end
            if not processed then
                local selected = GuiService.SelectedObject
                local handler = selected and self.KeyboardHandlers[selected]
                if handler then
                    self:_dispatch("Keyboard", handler, input)
                end
            end
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local popupWindow = Kronos.ActivePopupWindow
                local activePopup = popupWindow and popupWindow.ActivePopup
                if
                    activePopup
                    and not pointInside(activePopup.Frame, input.Position)
                    and not pointInside(activePopup.Anchor, input.Position)
                then
                    PopupController:Close(popupWindow)
                end
            end
        end)
    )
    addConnection(
        Kronos,
        UserInputService.InputChanged:Connect(function(input)
            local active = self.ActivePointer
            if not active then
                return
            end
            local touch = active.Input.UserInputType == Enum.UserInputType.Touch
            if
                (touch and input ~= active.Input)
                or (not touch and input.UserInputType ~= Enum.UserInputType.MouseMovement)
            then
                return
            end
            if not self:_dispatch("PointerChanged", active.Changed, input) and self.ActivePointer == active then
                self:CancelPointer(active.Owner)
            end
        end)
    )
    addConnection(
        Kronos,
        UserInputService.InputEnded:Connect(function(input)
            local active = self.ActivePointer
            if active then
                local finished = (active.Input.UserInputType == Enum.UserInputType.Touch and input == active.Input)
                    or (
                        active.Input.UserInputType ~= Enum.UserInputType.Touch
                        and input.UserInputType == Enum.UserInputType.MouseButton1
                    )
                if finished then
                    self.ActivePointer = nil
                    self:_dispatch("PointerEnded", active.Ended, input, false)
                end
            end
            for _, window in ipairs(table.clone(Kronos.Windows)) do
                if not window.Destroyed and type(window._handleInputEnded) == "function" then
                    self:_dispatch("InputEnded", window._handleInputEnded, window, input)
                end
            end
        end)
    )
end

function InputController:BeginPointer(
    owner: any,
    input: InputObject,
    changed: (InputObject) -> (),
    ended: ((InputObject?, boolean?) -> ())?
): boolean
    self:Initialize()
    if
        self.ActivePointer
        or (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch)
    then
        return false
    end
    self.ActivePointer = {
        Owner = owner,
        Input = input,
        Changed = changed,
        Ended = ended or function() end,
    }
    return true
end

function InputController:CancelPointer(owner: any?): boolean
    local active = self.ActivePointer
    if not active or (owner ~= nil and active.Owner ~= owner) then
        return false
    end
    self.ActivePointer = nil
    self:_dispatch("PointerCancelled", active.Ended, nil, true)
    return true
end

function InputController:BindKeyboard(target: GuiObject, callback: (InputObject) -> ())
    self.KeyboardHandlers[target] = callback
end

function InputController:UnbindKeyboard(target: GuiObject?)
    if target then
        self.KeyboardHandlers[target] = nil
    end
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
    if instance:IsA("GuiObject") and instance.BackgroundTransparency < 1 then
        AppearanceController:Register(instance, instance.BackgroundTransparency)
    end
    if instance:IsA("ScrollingFrame") then
        instance:SetAttribute("KronosCustomScrollbar", true)
        instance.ScrollBarThickness = 0
        task.defer(function()
            if instance.Parent and type(ScrollbarController.Attach) == "function" then
                ScrollbarController:Attach(instance)
            end
        end)
    end
    return instance
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = parent })
end

local function stroke(parent, color, transparency, thickness, role)
    local semanticRole = role or "Control"
    local style = BorderStyles[semanticRole] or BorderStyles.Control
    local resolvedTransparency = transparency
    if resolvedTransparency == nil then
        resolvedTransparency = style.Transparency
    end
    local resolvedThickness = thickness
    if resolvedThickness == nil then
        resolvedThickness = style.Thickness
    end
    local strokeObject = create("UIStroke", {
        Color = color or Theme.Stroke,
        Transparency = resolvedTransparency,
        Thickness = resolvedThickness,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
    return BorderController:Register(strokeObject, resolvedTransparency, resolvedThickness, semanticRole)
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

local function boundedClamp(value: number, minimum: number, maximum: number): number
    local low = minimum
    local high = maximum
    if high < low then
        low, high = high, low
    end
    if value < low then
        return low
    end
    if value > high then
        return high
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

function AcrylicController:Register(root: GuiObject, role: string?): AnyTable
    local existing = self.Records[root]
    if existing then
        return existing
    end
    local tint = create("Frame", {
        Name = "AcrylicTint",
        BackgroundColor3 = Theme.AcrylicTint,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = root.ZIndex,
        Parent = root,
    }) :: Frame
    tint:SetAttribute("KronosNoDensity", true)
    local rootCorner = root:FindFirstChildOfClass("UICorner")
    if rootCorner then
        create("UICorner", { CornerRadius = rootCorner.CornerRadius, Parent = tint })
    end
    local tintGradient = create("UIGradient", {
        Rotation = 24,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.AcrylicTint:Lerp(Theme.Accent, 0.08)),
            ColorSequenceKeypoint.new(0.55, Theme.AcrylicTint),
            ColorSequenceKeypoint.new(1, Theme.Background),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(0.55, 0.28),
            NumberSequenceKeypoint.new(1, 0.52),
        }),
        Parent = tint,
    }) :: UIGradient
    local depth = create("Frame", {
        Name = "AcrylicDepth",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = root.ZIndex,
        Parent = root,
    }) :: Frame
    depth:SetAttribute("KronosNoDensity", true)
    if rootCorner then
        create("UICorner", { CornerRadius = rootCorner.CornerRadius, Parent = depth })
    end
    local depthGradient = create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Surface2),
            ColorSequenceKeypoint.new(0.58, Theme.Background),
            ColorSequenceKeypoint.new(1, Theme.Shadow),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.84),
            NumberSequenceKeypoint.new(0.58, 0.9),
            NumberSequenceKeypoint.new(1, 0.66),
        }),
        Parent = depth,
    }) :: UIGradient
    local sheen = create("Frame", {
        Name = "AcrylicSheen",
        BackgroundColor3 = Theme.InnerHighlight,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 0, 1),
        ZIndex = root.ZIndex + 1,
        Parent = root,
    }) :: Frame
    sheen:SetAttribute("KronosNoDensity", true)
    ThemeController:Bind(tint, "BackgroundColor3", "AcrylicTint")
    ThemeController:Bind(depth, "BackgroundColor3", "Background")
    ThemeController:Bind(sheen, "BackgroundColor3", "InnerHighlight")
    local record = {
        Root = root,
        Tint = tint,
        Depth = depth,
        Sheen = sheen,
        Gradient = tintGradient,
        DepthGradient = depthGradient,
        Role = role or "Surface",
    }
    self.Records[root] = record
    self:RefreshRecord(record)
    return record
end

function AcrylicController:RefreshRecord(record: AnyTable)
    local root = record.Root
    if not root or not root.Parent then
        if root then
            self.Records[root] = nil
        end
        return
    end
    local enabled = Kronos.AcrylicEnabled == true
    local roleStrength = AcrylicRoleStrength[record.Role] or (
        string.find(record.Role or "", "Settings", 1, true) and 1.08
        or string.find(record.Role or "", "Preset", 1, true) and 1.04
        or 1
    )
    local intensity = math.clamp((tonumber(Kronos.AcrylicIntensity) or 0.55) * roleStrength, 0, 1)
    record.Tint.Visible = enabled
    record.Depth.Visible = enabled
    record.Sheen.Visible = enabled
    -- The objective uses a readable dark acrylic rather than nearly invisible
    -- tint layers. Root transparency still exposes the world, while these
    -- layers restore separation, depth, and a faint lavender cast.
    record.Tint.BackgroundTransparency = enabled and (0.94 - 0.22 * intensity) or 1
    record.Depth.BackgroundTransparency = enabled and (0.985 - 0.095 * intensity) or 1
    record.Sheen.BackgroundTransparency = enabled and (0.97 - 0.13 * intensity) or 1
    record.Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AcrylicTint:Lerp(Theme.Accent, 0.05 + 0.09 * intensity)),
        ColorSequenceKeypoint.new(0.55, Theme.AcrylicTint),
        ColorSequenceKeypoint.new(1, Theme.Background),
    })
    record.DepthGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ThemeController:ResolveColor("Surface2")),
        ColorSequenceKeypoint.new(0.58, ThemeController:ResolveColor("Background")),
        ColorSequenceKeypoint.new(1, Theme.Shadow),
    })
end

function AcrylicController:Refresh()
    for _, record in pairs(self.Records) do
        self:RefreshRecord(record)
    end
end

function IconController:Normalize(name: any): string?
    if type(name) ~= "string" then
        return nil
    end
    local normalized = name:match("^%s*(.-)%s*$") or ""
    if normalized == "" then
        return nil
    end
    normalized = normalized:gsub("(%u)(%u%l)", "%1-%2")
    normalized = normalized:gsub("(%l%d)(%u)", "%1-%2")
    normalized = normalized:gsub("[%s_]+", "-")
    normalized = normalized:lower():gsub("^lucide%-", ""):gsub("^icon%-", "")
    normalized = normalized:gsub("[^%w%-]", ""):gsub("%-+", "-")
    normalized = normalized:gsub("^%-", ""):gsub("%-$", "")
    return normalized ~= "" and normalized or nil
end

function IconController:Resolve(name: any): (string?, string?, boolean)
    local normalized = self:Normalize(name)
    if not normalized then
        return nil, nil, true
    end
    local cached = self.Cache[normalized]
    if cached then
        return cached, self.Canonical[normalized], self.Valid[normalized] == true
    end
    local canonical = IconAliases[normalized] or normalized
    local asset = LucideAssets[canonical]
    if not asset then
        local compactName = string.gsub(normalized, "%-", "")
        canonical = CompactIconNames[compactName] or canonical
        asset = LucideAssets[canonical]
    end
    local valid = asset ~= nil
    if not asset then
        canonical = "circle"
        asset = LucideAssets[canonical]
        if not self.InvalidWarned[normalized] then
            self.InvalidWarned[normalized] = true
            warn("[Kronos][LucideResolver] Unknown icon '" .. normalized .. "'; using circle")
        end
    end
    self.Cache[normalized] = asset
    self.Canonical[normalized] = canonical
    self.Valid[normalized] = valid
    return asset, canonical, valid
end

function IconController:Create(parent: Instance, options: any, token: string?): ImageLabel?
    local config: AnyTable = type(options) == "table" and options or { Icon = options }
    local asset, canonical = self:Resolve(config.Icon)
    if not asset then
        return nil
    end
    local size = math.clamp(math.floor(finiteNumber(config.IconSize, 14) + 0.5), 8, 32)
    local explicitColor = typeof(config.IconColor) == "Color3"
    local colorToken = token or "SubText"
    local icon = create("ImageLabel", {
        Name = "LucideIcon",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = asset,
        ImageColor3 = explicitColor and config.IconColor or Theme[colorToken] or Theme.SubText,
        ImageTransparency = math.clamp(finiteNumber(config.IconTransparency, 0), 0, 1),
        ScaleType = Enum.ScaleType.Fit,
        Size = UDim2.fromOffset(size, size),
        Parent = parent,
    }) :: ImageLabel
    icon:SetAttribute("KronosLucide", canonical)
    if not explicitColor and Theme[colorToken] then
        ThemeController:Bind(icon, "ImageColor3", colorToken)
    end
    return icon
end

local function makeIcon(parent: Instance, options: any, token: string?): ImageLabel?
    return IconController:Create(parent, options, token)
end

local function viewportSize()
    local cam = workspace.CurrentCamera
    if cam then
        return cam.ViewportSize
    end
    return Vector2.new(1920, 1080)
end

local function scaledUDim(value: UDim, density: number): UDim
    return UDim.new(value.Scale, math.floor(value.Offset * density + 0.5))
end

local function scaledUDim2(value: UDim2, density: number): UDim2
    return UDim2.new(
        value.X.Scale,
        math.floor(value.X.Offset * density + 0.5),
        value.Y.Scale,
        math.floor(value.Y.Offset * density + 0.5)
    )
end

function ResponsiveController:GetDensity(viewport: Vector2?): number
    local size = viewport or viewportSize()
    local portrait = size.X < size.Y

    -- Density follows usable visual height instead of physical capture pixels.
    -- This prevents high-DPI landscape recordings from inflating every row.
    if portrait then
        if size.X <= 390 then
            return 0.8
        elseif size.X <= 480 then
            return 0.84
        end
        return 0.88
    end
    if size.Y <= 430 then
        return 0.62
    elseif size.Y <= 560 then
        return 0.68
    elseif size.Y <= 760 then
        return 0.74
    elseif size.X < 1200 or size.Y < 820 then
        return 0.8
    elseif size.X < 1800 or size.Y < 980 then
        return 0.86
    end
    return 0.92
end

function ResponsiveController:GetFloatingDensity(viewport: Vector2?): number
    local size = viewport or viewportSize()
    if
        UserInputService.TouchEnabled
        and size.X > size.Y
        and size.Y <= 620
    then
        -- Floating widgets in the objective retain a larger independent scale
        -- than the dense mobile-landscape application shell.
        return 0.68
    end
    return self:GetDensity(size)
end

function ResponsiveController:GetMinimumTextSize(viewport: Vector2?): number
    local size = viewport or viewportSize()
    if UserInputService.TouchEnabled and size.X > size.Y and size.Y <= 620 then
        return 6
    end
    return 8
end

function ResponsiveController:GetLayoutMode(viewport: Vector2, safeWidth: number, safeHeight: number): string
    if viewport.X < viewport.Y or safeWidth < safeHeight * 0.82 or safeWidth <= 520 then
        return "Portrait"
    end
    if UserInputService.TouchEnabled and safeWidth > safeHeight and safeHeight <= 620 then
        return "MobileLandscape"
    end
    if safeWidth < 980 or safeHeight < 560 then
        return "Compact"
    end
    if safeWidth < 1580 or safeHeight < 820 then
        return "Medium"
    end
    return "Wide"
end

function ResponsiveController:CalculateWindowSize(
    window: AnyTable,
    viewport: Vector2,
    safeWidth: number,
    safeHeight: number
): (number, number, string)
    local mode = self:GetLayoutMode(viewport, safeWidth, safeHeight)
    local baseWidth = math.max(finiteNumber(window.BaseWidth, TargetDesign.Window.LogicalSize.X), 1)
    local baseHeight = math.max(finiteNumber(window.BaseHeight, TargetDesign.Window.LogicalSize.Y), 1)
    local explicitAspect = math.clamp(baseWidth / baseHeight, 1.15, 2.05)
    local aspect = (window.HasExplicitWidth or window.HasExplicitHeight) and explicitAspect
        or TargetDesign.Window.Aspect
    local width: number
    local height: number

    if mode == "Portrait" and not window.HasExplicitWidth and not window.HasExplicitHeight then
        width = math.min(baseWidth, safeWidth * TargetDesign.Window.PortraitWidthRatio)
        local portraitTarget = math.max(width * 1.34, math.min(430, safeHeight))
        height = math.min(safeHeight * TargetDesign.Window.PortraitHeightRatio, portraitTarget)
    else
        local heightRatio = TargetDesign.Window.WideHeightRatio
        local designScale = 1
        local widthRatio = 0.78
        if mode == "MobileLandscape" then
            heightRatio = TargetDesign.Window.LandscapeHeightRatio
            -- The supplied 2340x1080 mobile capture renders a 1170x540
            -- logical viewport. A 0.476 artboard scale reproduces the
            -- objective's measured compact shell without affecting desktop
            -- sizing or child-density rules.
            designScale = TargetDesign.Window.MobileLandscapeScale
            widthRatio = 0.9
        elseif mode == "Compact" then
            heightRatio = TargetDesign.Window.CompactHeightRatio
            designScale = 0.86
            widthRatio = 0.9
        elseif mode == "Medium" then
            heightRatio = TargetDesign.Window.MediumHeightRatio
            designScale = 0.96
            widthRatio = 0.74
        end

        height = math.min(baseHeight * designScale, safeHeight * heightRatio)
        width = height * aspect
        local maximumWidth = safeWidth * widthRatio
        if width > maximumWidth then
            width = maximumWidth
            height = width / aspect
        end

        if window.HasExplicitWidth then
            width = baseWidth
            if not window.HasExplicitHeight then
                height = width / aspect
            end
        end
        if window.HasExplicitHeight then
            height = baseHeight
            if not window.HasExplicitWidth then
                width = height * aspect
            end
        end
    end

    local minimumWidth = math.min(mode == "Portrait" and 280 or 320, safeWidth)
    local minimumHeight = math.min(mode == "Portrait" and 360 or 220, safeHeight)
    width = math.clamp(width, minimumWidth, safeWidth)
    height = math.clamp(height, minimumHeight, safeHeight)

    if mode ~= "Portrait" and not (window.HasExplicitWidth and window.HasExplicitHeight) then
        if width / math.max(height, 1) > aspect then
            width = height * aspect
        else
            height = width / aspect
        end
        width = math.min(width, safeWidth)
        height = math.min(height, safeHeight)
    end

    return math.floor(width + 0.5), math.floor(height + 0.5), mode
end

function ResponsiveController:Scale(window: AnyTable?, value: number): number
    return math.floor(value * ((window and window.Density) or self:GetDensity()) + 0.5)
end

function ResponsiveController:_capture(window: AnyTable, instance: Instance)
    if self.Records[instance] or instance:GetAttribute("KronosNoDensity") then
        return
    end
    local record: AnyTable = { Window = window }
    if instance:IsA("GuiObject") then
        record.Size = instance.Size
        record.Position = instance.Position
        if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
            record.TextSize = instance.TextSize
        end
        if instance:IsA("ScrollingFrame") then
            record.ScrollBarThickness = instance:GetAttribute("KronosCustomScrollbar") and 0
                or instance.ScrollBarThickness
        end
    elseif instance:IsA("UICorner") then
        record.CornerRadius = instance.CornerRadius
    elseif instance:IsA("UIPadding") then
        record.PaddingLeft = instance.PaddingLeft
        record.PaddingTop = instance.PaddingTop
        record.PaddingRight = instance.PaddingRight
        record.PaddingBottom = instance.PaddingBottom
    elseif instance:IsA("UIListLayout") then
        record.Padding = instance.Padding
    elseif instance:IsA("UIStroke") then
        record.Thickness = instance.Thickness
    else
        return
    end
    self.Records[instance] = record
end

function ResponsiveController:_applyRecord(instance: Instance, record: AnyTable, density: number)
    if not instance.Parent then
        self.Records[instance] = nil
        return
    end
    if record.Size then
        local guiObject = instance :: GuiObject
        local previousDensity = record.AppliedDensity
        local ratio = previousDensity and density / previousDensity or density
        local expectedSize = previousDensity and scaledUDim2(record.Size, previousDensity) or nil
        local expectedPosition = previousDensity and scaledUDim2(record.Position, previousDensity) or nil
        guiObject.Size = expectedSize and guiObject.Size ~= expectedSize and scaledUDim2(guiObject.Size, ratio)
            or scaledUDim2(record.Size, density)
        guiObject.Position = expectedPosition
                and guiObject.Position ~= expectedPosition
                and scaledUDim2(guiObject.Position, ratio)
            or scaledUDim2(record.Position, density)
        if record.TextSize then
            (instance :: any).TextSize = math.max(
                record.TextSize * density,
                self:GetMinimumTextSize()
            )
        end
        if record.ScrollBarThickness then
            local scrollingFrame = instance :: ScrollingFrame
            scrollingFrame.ScrollBarThickness = scrollingFrame:GetAttribute("KronosCustomScrollbar") and 0
                or math.max(
                    math.floor(record.ScrollBarThickness * density + 0.5),
                    record.ScrollBarThickness > 0 and 1 or 0
                )
        end
        record.AppliedDensity = density
    elseif record.CornerRadius then
        local cornerObject = instance :: UICorner
        cornerObject.CornerRadius = scaledUDim(record.CornerRadius, density)
    elseif record.PaddingLeft then
        local pad = instance :: UIPadding
        pad.PaddingLeft = scaledUDim(record.PaddingLeft, density)
        pad.PaddingTop = scaledUDim(record.PaddingTop, density)
        pad.PaddingRight = scaledUDim(record.PaddingRight, density)
        pad.PaddingBottom = scaledUDim(record.PaddingBottom, density)
    elseif record.Padding then
        local layout = instance :: UIListLayout
        layout.Padding = scaledUDim(record.Padding, density)
    elseif record.Thickness then
        local strokeObject = instance :: UIStroke
        strokeObject.Thickness = math.max(record.Thickness * density, 0.5)
    end
end

function ResponsiveController:RegisterTree(window: AnyTable, root: Instance, excludeRoot: boolean?)
    if not excludeRoot then
        self:_capture(window, root)
    end
    for _, descendant in ipairs(root:GetDescendants()) do
        self:_capture(window, descendant)
    end
    local density = window.Density or self:GetDensity()
    if not excludeRoot then
        local rootRecord = self.Records[root]
        if rootRecord then
            self:_applyRecord(root, rootRecord, density)
        end
    end
    for _, descendant in ipairs(root:GetDescendants()) do
        local record = self.Records[descendant]
        if record then
            self:_applyRecord(descendant, record, density)
        end
    end
end

function ResponsiveController:Apply(window: AnyTable)
    local density = window.Density or self:GetDensity()
    for instance, record in pairs(self.Records) do
        if record.Window == window then
            self:_applyRecord(instance, record, density)
        end
    end
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

local function guiInsets(): (Vector2, Vector2)
    local ok, topLeft, bottomRight = pcall(GuiService.GetGuiInset, GuiService)
    if ok and typeof(topLeft) == "Vector2" and typeof(bottomRight) == "Vector2" then
        return topLeft, bottomRight
    end
    return Vector2.zero, Vector2.zero
end

local function viewportBounds(target: GuiObject, options: AnyTable?): (Vector2, Vector2)
    options = options or {}
    local parent = target.Parent
    local origin = Vector2.zero
    local size = viewportSize()
    if parent and parent:IsA("GuiObject") then
        origin = parent.AbsolutePosition
        size = parent.AbsoluteSize
    end
    if Kronos.GUI and Kronos.GUI.IgnoreGuiInset then
        local topLeftInset, bottomRightInset = guiInsets()
        origin += topLeftInset
        size -= topLeftInset + bottomRightInset
    end
    local margin = math.clamp(finiteNumber(options.DragMargin, 4), 0, 32)
    return origin + Vector2.new(margin, margin), origin + size - Vector2.new(margin, margin)
end

local function clampTopLeftForSize(target: GuiObject, topLeft: Vector2, size: Vector2, options: AnyTable?): Vector2
    options = options or {}
    if options.DragBounds == "None" then
        return topLeft
    end
    local minimum, maximumEdge = viewportBounds(target, options)
    local keepFullyVisible = options.KeepFullyVisible ~= false
    local minimumVisible =
        math.clamp(finiteNumber(options.MinimumVisiblePixels, 24), 1, math.max(math.min(size.X, size.Y), 1))
    local maximum = keepFullyVisible and (maximumEdge - size)
        or (maximumEdge - Vector2.new(minimumVisible, minimumVisible))
    if not keepFullyVisible then
        minimum -= size - Vector2.new(minimumVisible, minimumVisible)
    end
    local function clamped(value: number, low: number, high: number): number
        if high < low then
            return (low + high) * 0.5
        end
        return math.clamp(value, low, high)
    end
    return Vector2.new(clamped(topLeft.X, minimum.X, maximum.X), clamped(topLeft.Y, minimum.Y, maximum.Y))
end

local function clampAbsoluteTopLeft(target: GuiObject, topLeft: Vector2, options: AnyTable?): Vector2
    return clampTopLeftForSize(target, topLeft, target.AbsoluteSize, options)
end

local function setAbsoluteTopLeft(target: GuiObject, topLeft: Vector2): Vector2
    local parent = target.Parent
    local parentPosition = Vector2.zero
    if parent and parent:IsA("GuiObject") then
        parentPosition = parent.AbsolutePosition
    end
    local anchorPosition = topLeft + target.AbsoluteSize * target.AnchorPoint - parentPosition
    anchorPosition = Vector2.new(math.floor(anchorPosition.X + 0.5), math.floor(anchorPosition.Y + 0.5))
    target.Position = UDim2.fromOffset(anchorPosition.X, anchorPosition.Y)
    return anchorPosition
end

local function nearestEdgeLayout(target: GuiObject, requestedSize: Vector2, options: AnyTable?): (UDim2, UDim2)
    local minimum, maximumEdge = viewportBounds(target, options)
    local available = maximumEdge - minimum
    local size = Vector2.new(
        math.min(math.max(requestedSize.X, 1), math.max(available.X, 1)),
        math.min(math.max(requestedSize.Y, 1), math.max(available.Y, 1))
    )
    local oldTopLeft = target.AbsolutePosition
    local oldSize = target.AbsoluteSize
    local left = oldTopLeft.X - minimum.X
    local right = maximumEdge.X - oldTopLeft.X - oldSize.X
    local top = oldTopLeft.Y - minimum.Y
    local bottom = maximumEdge.Y - oldTopLeft.Y - oldSize.Y
    local topLeft = Vector2.new(
        math.abs(right) < math.abs(left) and maximumEdge.X - size.X - right or minimum.X + left,
        math.abs(bottom) < math.abs(top) and maximumEdge.Y - size.Y - bottom or minimum.Y + top
    )
    topLeft = clampTopLeftForSize(target, topLeft, size, options)
    local parentPosition = Vector2.zero
    if target.Parent and target.Parent:IsA("GuiObject") then
        parentPosition = target.Parent.AbsolutePosition
    end
    local anchored = topLeft + size * target.AnchorPoint - parentPosition
    return UDim2.fromOffset(math.floor(size.X + 0.5), math.floor(size.Y + 0.5)),
        UDim2.fromOffset(math.floor(anchored.X + 0.5), math.floor(anchored.Y + 0.5))
end

function DragController:Initialize()
    if self.Initialized then
        return
    end
    self.Initialized = true
    self.Bindings = setmetatable({}, { __mode = "k" })
    InputController:Initialize()
end

function DragController:_update(input: InputObject)
    local active = self.Active
    if not active then
        return
    end
    if not active.Target.Parent then
        self:Cancel(active.Target)
        return
    end
    local pointer = Vector2.new(input.Position.X, input.Position.Y)
    active.LastPointer = pointer
    local delta = pointer - active.StartPointer
    if not active.Moved and delta.Magnitude < active.Threshold then
        return
    end
    active.Moved = true
    local topLeft = clampAbsoluteTopLeft(active.Target, active.StartTopLeft + delta, active.Options)
    local position = setAbsoluteTopLeft(active.Target, topLeft)
    if active.MovedCallback then
        active.MovedCallback(position)
    end
end

function DragController:_finish()
    local active = self.Active
    if not active then
        return
    end
    self.Active = nil
    if active.EndedCallback then
        active.EndedCallback(active.Moved == true)
    end
end

function DragController:Cancel(target: GuiObject?)
    if self.Active and (target == nil or self.Active.Target == target) then
        if not InputController:CancelPointer(self) then
            self:_finish()
        end
    end
end

function DragController:IsDragging(target: GuiObject): boolean
    return self.Active ~= nil and self.Active.Target == target
end

function DragController:Clamp(target: GuiObject, options: AnyTable?): Vector2
    if not target.Parent then
        return Vector2.zero
    end
    local binding = self.Bindings and self.Bindings[target]
    options = options or (binding and binding.Options) or {}
    local topLeft = clampAbsoluteTopLeft(target, target.AbsolutePosition, options)
    local position = setAbsoluteTopLeft(target, topLeft)
    if self.Active and self.Active.Target == target then
        self.Active.StartTopLeft = target.AbsolutePosition
        self.Active.StartPointer = self.Active.LastPointer or self.Active.StartPointer
    end
    return position
end

function DragController:Bind(
    owner: AnyTable,
    handle: GuiObject,
    target: GuiObject,
    movedCallback: ((Vector2) -> ())?,
    options: AnyTable?
): AnyTable
    self:Initialize()
    options = options or {}
    local binding = {
        Owner = owner,
        Handle = handle,
        Target = target,
        Options = options,
        MovedCallback = movedCallback,
    }
    self.Bindings[target] = binding
    handle.Active = true
    addConnection(
        owner,
        handle.InputBegan:Connect(function(input)
            if
                Kronos.Destroyed
                or self.Active
                or InputController.ActivePointer
                or not target.Parent
                or not target.Visible
            then
                return
            end
            if
                input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch
            then
                return
            end
            if type(options.CanStart) == "function" then
                local ok, allowed = pcall(options.CanStart)
                if not ok or allowed == false then
                    return
                end
            end
            for _, ignored in ipairs(options.Ignore or {}) do
                if pointInside(ignored, input.Position) then
                    return
                end
            end
            local window = owner.Window or (owner.Kronos and owner)
            if window and window.ActivePopup then
                PopupController:Close(window)
            end
            local activeTweens = Kronos.ActiveTweens[target]
            if activeTweens and (activeTweens.Position or activeTweens.Size) then
                AnimationController:Cancel(target)
                if type(owner.Clamp) == "function" then
                    owner:Clamp()
                elseif type(owner.ApplyResponsive) == "function" then
                    owner:ApplyResponsive()
                end
                if target:IsA("CanvasGroup") and owner.Visible ~= false then
                    target.GroupTransparency = 0
                end
            end
            local pointer = Vector2.new(input.Position.X, input.Position.Y)
            local baseThreshold = math.max(finiteNumber(options.DragThreshold, 6), 0)
            local pointerThreshold = input.UserInputType == Enum.UserInputType.Touch
                    and math.max(baseThreshold, 8)
                or baseThreshold
            local active = {
                Input = input,
                Target = target,
                StartPointer = pointer,
                LastPointer = pointer,
                StartTopLeft = target.AbsolutePosition,
                Threshold = pointerThreshold,
                Options = options,
                MovedCallback = movedCallback,
                EndedCallback = options.Ended,
                Moved = false,
            }
            self.Active = active
            if
                not InputController:BeginPointer(self, input, function(changedInput)
                    self:_update(changedInput)
                end, function()
                    self:_finish()
                end)
            then
                self.Active = nil
            end
        end)
    )
    addConnection(
        owner,
        target.AncestryChanged:Connect(function(_, parent)
            if parent == nil then
                self:Cancel(target)
                if self.Bindings then
                    self.Bindings[target] = nil
                end
            end
        end)
    )
    return binding
end

function ScrollbarController:Initialize()
    if self.Initialized then
        return
    end
    self.Initialized = true
    InputController:Initialize()
end

function ScrollbarController:_updatePointer(input: InputObject)
    local active = self.Active
    if not active then
        return
    end
    if not active.Scroller.Parent then
        self:Cancel()
        return
    end
    local pointer = active.Horizontal and input.Position.X or input.Position.Y
    active.LastPointer = pointer
    local travel = math.max(active.TrackLength - active.ThumbLength, 1)
    local canvas = active.StartCanvas + (pointer - active.StartPointer) / travel * active.MaximumCanvas
    self:SetCanvas(active, canvas)
    self:Wake(active, true)
end

function ScrollbarController:_finishPointer()
    local active = self.Active
    if not active then
        return
    end
    self.Active = nil
    active.Dragging = false
    if active.Scroller and active.Scroller.Parent then
        self:Update(active)
        self:Wake(active, false)
    end
end

function ScrollbarController:GetLengths(entry: AnyTable): (number, number, number, number)
    local scroller = entry.Scroller :: ScrollingFrame
    local view = entry.Horizontal and scroller.AbsoluteSize.X or scroller.AbsoluteSize.Y
    local content = entry.Horizontal and scroller.AbsoluteCanvasSize.X or scroller.AbsoluteCanvasSize.Y
    content = math.max(content, view)
    local trackLength = math.max(view - entry.Margin * 2, 1)
    local maximumCanvas = math.max(content - view, 0)
    local minimumThumb = math.min(math.max(finiteNumber(entry.MinimumThumb, 1), 1), trackLength)
    local thumbLength = maximumCanvas > 0
            and math.clamp(trackLength * view / math.max(content, 1), minimumThumb, trackLength)
        or trackLength
    return view, trackLength, maximumCanvas, thumbLength
end

function ScrollbarController:SetCanvas(entry: AnyTable, value: number)
    local scroller = entry.Scroller :: ScrollingFrame
    local _, _, maximumCanvas = self:GetLengths(entry)
    local nextValue = math.clamp(value, 0, maximumCanvas)
    if entry.Horizontal then
        scroller.CanvasPosition = Vector2.new(nextValue, scroller.CanvasPosition.Y)
    else
        scroller.CanvasPosition = Vector2.new(scroller.CanvasPosition.X, nextValue)
    end
end

function ScrollbarController:Update(entry: AnyTable)
    local scroller = entry.Scroller :: ScrollingFrame
    if not scroller.Parent or not entry.Track.Parent then
        self:Detach(scroller)
        return
    end
    scroller.ScrollBarThickness = 0
    entry.Track.ZIndex = scroller.ZIndex + 40
    entry.Thumb.ZIndex = entry.Track.ZIndex + 1
    local view, trackLength, maximumCanvas, thumbLength = self:GetLengths(entry)
    entry.TrackLength = trackLength
    entry.MaximumCanvas = maximumCanvas
    entry.ThumbLength = thumbLength
    local current = entry.Horizontal and scroller.CanvasPosition.X or scroller.CanvasPosition.Y
    if self.Active == entry and entry.Dragging and entry.LastPointer then
        entry.StartPointer = entry.LastPointer
        entry.StartCanvas = current
    end
    local ratio = maximumCanvas > 0 and math.clamp(current / maximumCanvas, 0, 1) or 0
    local thumbOffset = (trackLength - thumbLength) * ratio
    local active = entry.Hovered or entry.Dragging or self.Active == entry
    local width = active and entry.ActiveWidth or entry.IdleWidth
    local canvas = scroller.CanvasPosition
    local targetSize: UDim2
    if entry.Horizontal then
        entry.Track.AnchorPoint = Vector2.new(0, 1)
        entry.Track.Position = UDim2.fromOffset(canvas.X + entry.Margin, canvas.Y + view - entry.Margin - 1)
        targetSize = UDim2.fromOffset(trackLength, width)
        entry.Thumb.Position = UDim2.fromOffset(thumbOffset, 0)
        entry.Thumb.Size = UDim2.fromOffset(thumbLength, width)
    else
        entry.Track.AnchorPoint = Vector2.new(1, 0)
        entry.Track.Position =
            UDim2.fromOffset(canvas.X + scroller.AbsoluteSize.X - entry.Margin - 1, canvas.Y + entry.Margin)
        targetSize = UDim2.fromOffset(width, trackLength)
        entry.Thumb.Position = UDim2.fromOffset(0, thumbOffset)
        entry.Thumb.Size = UDim2.fromOffset(width, thumbLength)
    end
    if entry.LastWidth and entry.LastWidth ~= width then
        tween(entry.Track, { Size = targetSize }, Motion.Scrollbar)
    else
        entry.Track.Size = targetSize
    end
    entry.LastWidth = width
    entry.Track.Visible = maximumCanvas > 0.5 and scroller.Visible
end

function ScrollbarController:Wake(entry: AnyTable, hold: boolean?)
    if not entry.Track.Parent then
        return
    end
    entry.IdleGeneration = (entry.IdleGeneration or 0) + 1
    local generation = entry.IdleGeneration
    tween(entry.Track, { BackgroundTransparency = 0.91 }, Motion.ScrollbarActivate)
    tween(entry.Thumb, { BackgroundTransparency = 0.08 }, Motion.ScrollbarActivate)
    if hold then
        return
    end
    task.delay(TargetDesign.Scrollbar.IdleDelay, function()
        if entry.IdleGeneration == generation and not entry.Hovered and not entry.Dragging and entry.Track.Parent then
            tween(entry.Track, { BackgroundTransparency = 0.99 }, Motion.ScrollbarIdle)
            tween(entry.Thumb, { BackgroundTransparency = 0.48 }, Motion.ScrollbarIdle)
        end
    end)
end

function ScrollbarController:Detach(scroller: ScrollingFrame)
    local entry = self.Entries[scroller]
    if not entry then
        return
    end
    if self.Active == entry then
        self:Cancel()
    end
    self.Entries[scroller] = nil
    disconnectAll(entry)
    if entry.Track and entry.Track.Parent then
        ThemeController:UnbindTree(entry.Track)
        entry.Track:Destroy()
    end
end

function ScrollbarController:Cancel()
    local active = self.Active
    if not active then
        return
    end
    if not InputController:CancelPointer(self) then
        self:_finishPointer()
    end
end

function ScrollbarController:Attach(scroller: ScrollingFrame): AnyTable?
    if self.Entries[scroller] or not scroller.Parent then
        return self.Entries[scroller]
    end
    self:Initialize()
    scroller:SetAttribute("KronosCustomScrollbar", true)
    scroller.ScrollBarThickness = 0
    local horizontal = scroller.ScrollingDirection == Enum.ScrollingDirection.X
    local entry: AnyTable = {
        Scroller = scroller,
        Connections = {},
        Horizontal = horizontal,
        Margin = TargetDesign.Scrollbar.Margin,
        IdleWidth = TargetDesign.Scrollbar.IdleWidth,
        ActiveWidth = TargetDesign.Scrollbar.ActiveWidth,
        MinimumThumb = horizontal and TargetDesign.Scrollbar.HorizontalMinimumThumb or TargetDesign.Scrollbar.MinimumThumb,
        Hovered = false,
        Dragging = false,
    }
    local track = create("Frame", {
        Name = "KronosScrollTrack",
        BackgroundColor3 = Theme.ScrollTrack,
        BackgroundTransparency = 0.98,
        BorderSizePixel = 0,
        Active = true,
        ClipsDescendants = true,
        ZIndex = scroller.ZIndex + 40,
        Parent = scroller,
    }) :: Frame
    track:SetAttribute("KronosNoDensity", true)
    local thumb = create("Frame", {
        Name = "KronosScrollThumb",
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.48,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = track.ZIndex + 1,
        Parent = track,
    }) :: Frame
    thumb:SetAttribute("KronosNoDensity", true)
    corner(track, 2)
    corner(thumb, 2)
    local trackStroke = stroke(track, Theme.ScrollTrack, 0.9, 1, "ScrollTrack")
    local thumbStroke = stroke(thumb, Theme.InnerHighlight, 0.78, 1, "AcrylicHighlight")
    ThemeController:Bind(track, "BackgroundColor3", "ScrollTrack")
    ThemeController:Bind(trackStroke, "Color", "ScrollTrack")
    ThemeController:Bind(thumb, "BackgroundColor3", "Accent")
    ThemeController:Bind(thumbStroke, "Color", "InnerHighlight")
    entry.Track = track
    entry.Thumb = thumb
    self.Entries[scroller] = entry

    local function refresh()
        self:Update(entry)
    end
    for _, property in ipairs({
        "AbsoluteSize",
        "AbsoluteCanvasSize",
        "CanvasPosition",
        "Visible",
        "ZIndex",
        "ScrollingDirection",
    }) do
        local propertyName = property
        addConnection(
            entry,
            scroller:GetPropertyChangedSignal(propertyName):Connect(function()
                if propertyName == "ScrollingDirection" then
                    entry.Horizontal = scroller.ScrollingDirection == Enum.ScrollingDirection.X
                    entry.MinimumThumb = entry.Horizontal and TargetDesign.Scrollbar.HorizontalMinimumThumb or TargetDesign.Scrollbar.MinimumThumb
                    entry.Margin = entry.Horizontal and TargetDesign.Scrollbar.HorizontalMargin or TargetDesign.Scrollbar.Margin
                end
                refresh()
                if propertyName == "CanvasPosition" then
                    self:Wake(entry, false)
                end
            end)
        )
    end
    addConnection(
        entry,
        track.MouseEnter:Connect(function()
            entry.Hovered = true
            refresh()
            self:Wake(entry, true)
        end)
    )
    addConnection(
        entry,
        track.MouseLeave:Connect(function()
            entry.Hovered = false
            refresh()
            self:Wake(entry, false)
        end)
    )
    addConnection(
        entry,
        track.InputBegan:Connect(function(input)
            if
                input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch
            then
                return
            end
            if
                not InputController:BeginPointer(self, input, function(changedInput)
                    self:_updatePointer(changedInput)
                end, function()
                    self:_finishPointer()
                end)
            then
                return
            end
            self:Update(entry)
            local pointer = entry.Horizontal and input.Position.X or input.Position.Y
            if not pointInside(thumb, input.Position) then
                local trackStart = entry.Horizontal and track.AbsolutePosition.X or track.AbsolutePosition.Y
                local travel = math.max(entry.TrackLength - entry.ThumbLength, 1)
                local offset = math.clamp(pointer - trackStart - entry.ThumbLength * 0.5, 0, travel)
                self:SetCanvas(entry, offset / travel * entry.MaximumCanvas)
                self:Update(entry)
            end
            entry.Dragging = true
            entry.StartPointer = pointer
            entry.LastPointer = pointer
            entry.StartCanvas = entry.Horizontal and scroller.CanvasPosition.X or scroller.CanvasPosition.Y
            self.Active = entry
            self:Wake(entry, true)
            self:Update(entry)
        end)
    )
    addConnection(
        entry,
        scroller.InputChanged:Connect(function(input)
            if entry.Horizontal and input.UserInputType == Enum.UserInputType.MouseWheel then
                local _, _, maximumCanvas = self:GetLengths(entry)
                self:SetCanvas(entry, scroller.CanvasPosition.X - input.Position.Z * math.min(TargetDesign.Scrollbar.WheelStep, maximumCanvas))
                self:Wake(entry, false)
            end
        end)
    )
    addConnection(
        entry,
        scroller.AncestryChanged:Connect(function(_, parent)
            if parent == nil then
                self:Detach(scroller)
            end
        end)
    )
    self:Update(entry)
    return entry
end

function ScrollbarController:DestroyAll()
    self:Cancel()
    local scrollers = {}
    for scroller in pairs(self.Entries) do
        table.insert(scrollers, scroller)
    end
    for _, scroller in ipairs(scrollers) do
        self:Detach(scroller)
    end
end

function PopupController:Close(window: AnyTable)
    local active = window.ActivePopup
    if not active then
        if Kronos.ActivePopupWindow == window then
            Kronos.ActivePopupWindow = nil
        end
        return
    end
    ScrollbarController:Cancel()
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
            task.delay(AnimationController:Duration(Motion.PopupClose), function()
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
    local anchorPosition = anchor.AbsolutePosition - rootPosition
    local anchorSize = anchor.AbsoluteSize
    local popupSize = popup.AbsoluteSize
    local spacing = gap or 6
    local topLeftInset, bottomRightInset = guiInsets()
    local viewport = viewportSize()
    local minimumX = topLeftInset.X - rootPosition.X + 8
    local minimumY = topLeftInset.Y - rootPosition.Y + 8
    local maximumX = viewport.X - bottomRightInset.X - rootPosition.X - popupSize.X - 8
    local maximumY = viewport.Y - bottomRightInset.Y - rootPosition.Y - popupSize.Y - 8
    local x: number
    local y: number
    if placement == "Side" then
        x = anchorPosition.X + anchorSize.X + spacing
        y = anchorPosition.Y
        if x > maximumX then
            x = anchorPosition.X - popupSize.X - spacing
        end
    else
        x = anchorPosition.X
        y = anchorPosition.Y + anchorSize.Y + spacing
        if y > maximumY then
            y = anchorPosition.Y - popupSize.Y - spacing
        end
    end
    x = math.clamp(x, minimumX, math.max(maximumX, minimumX))
    y = math.clamp(y, minimumY, math.max(maximumY, minimumY))
    popup.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
end

function PopupController:Open(
    window: AnyTable,
    popup: GuiObject,
    anchor: GuiObject,
    gap: number?,
    placement: string?
): AnyTable
    InputController:CancelPointer()
    DragController:Cancel()
    ScrollbarController:Cancel()
    if Kronos.ActivePopupWindow and Kronos.ActivePopupWindow ~= window then
        self:Close(Kronos.ActivePopupWindow)
    end
    self:Close(window)
    local maid = Maid.new()
    window.ActivePopup = { Frame = popup, Maid = maid, Anchor = anchor, Gap = gap, Placement = placement }
    Kronos.ActivePopupWindow = window
    popup.Parent = window.PopupLayer or window.Overlay
    AcrylicController:Register(popup, "Popup")
    ResponsiveController:RegisterTree(window, popup)
    popup.Visible = true
    maid:Give(popup.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            if descendant.Parent and descendant:IsDescendantOf(popup) then
                ResponsiveController:RegisterTree(window, descendant)
            end
        end)
    end))
    local function reposition()
        if popup.Parent and anchor.Parent and window.ActivePopup and window.ActivePopup.Frame == popup then
            self:Position(window, popup, anchor, gap, placement)
        end
    end
    task.defer(reposition)
    maid:Give(popup:GetPropertyChangedSignal("AbsoluteSize"):Connect(reposition))
    maid:Give(anchor:GetPropertyChangedSignal("AbsolutePosition"):Connect(reposition))
    maid:Give(anchor:GetPropertyChangedSignal("AbsoluteSize"):Connect(reposition))
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

local function makeLayer(gui: ScreenGui, name: string, zIndex: number): Frame
    return create("Frame", {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = false,
        ZIndex = zIndex,
        Parent = gui,
    }) :: Frame
end

local function layoutToastHolder(holder: Frame)
    local density = ResponsiveController:GetDensity()
    local function d(value: number): number
        return math.floor(value * density + 0.5)
    end
    local topLeftInset, bottomRightInset = guiInsets()
    local top = topLeftInset.Y + d(44)
    holder.Position = UDim2.new(1, -(bottomRightInset.X + d(10)), 0, top)
    holder.Size = UDim2.fromOffset(d(204), math.max(viewportSize().Y - top - bottomRightInset.Y - d(8), d(80)))
    local layout = holder:FindFirstChildOfClass("UIListLayout")
    if layout then
        layout.Padding = UDim.new(0, d(4))
    end
end

local function makeToastHolder(parent: Instance): Frame
    local holder = create("Frame", {
        Name = "ToastHolder",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 50),
        Size = UDim2.fromOffset(204, 460),
        Parent = parent,
        ZIndex = LayerZ.Notification,
    }) :: Frame
    local layout = list(holder, Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Right)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layoutToastHolder(holder)
    return holder
end

function NotificationController:ApplyResponsive()
    if Kronos.ToastHolder and Kronos.ToastHolder.Parent then
        layoutToastHolder(Kronos.ToastHolder)
    end
end

Kronos.GUI = nil
Kronos.ToastHolder = nil
Kronos.Layers = nil

function Kronos:_ensureGui()
    if self.GUI and self.GUI.Parent then
        return self.GUI
    end
    self.GUI = createRootGui()
    self.Layers = {
        Main = makeLayer(self.GUI, "MainWindowLayer", LayerZ.Main),
        Floating = makeLayer(self.GUI, "FloatingWidgetLayer", LayerZ.Floating),
        Popup = makeLayer(self.GUI, "PopupLayer", LayerZ.Popup),
        Notification = makeLayer(self.GUI, "NotificationLayer", LayerZ.Notification),
        Modal = makeLayer(self.GUI, "ModalLayer", LayerZ.Modal),
        Mobile = makeLayer(self.GUI, "MobileLayer", LayerZ.Mobile),
    }
    self.GlobalPopupLayer = self.Layers.Popup
    self.ToastHolder = makeToastHolder(self.Layers.Notification)
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

function Kronos:GetIcon(name: any): (string?, string?, boolean)
    return IconController:Resolve(name)
end

function Kronos:IsIconValid(name: any): (boolean, string?)
    if not IconController:Normalize(name) then
        return false, nil
    end
    local _, canonical, valid = IconController:Resolve(name)
    return valid, canonical
end

Kronos.ResolveIcon = Kronos.GetIcon

function Kronos:Notify(config: NotificationOptions?): AnyTable
    if self.Destroyed then
        return { Destroy = function() end }
    end
    config = config or {}
    self:_ensureGui()
    if not self.ToastHolder or not self.ToastHolder.Parent then
        self.ToastHolder = makeToastHolder(self.Layers.Notification)
    end

    local requestedDuration = finiteNumber(config.Duration, 4)
    local persistent = requestedDuration <= 0
    local duration = persistent and 0 or math.max(requestedDuration, 0.5)
    local notificationMotion = self.NotificationMotion ~= false and Motion.Notification or 0
    local message = tostring(config.Content or config.Message or config.Subtitle or "")
    local height = message ~= "" and 48 or 34
    local width = 200
    local kind = string.lower(tostring(config.Type or "info"))
    local accent = Theme.Accent
    local accentToken = "Accent"
    local defaultIcon = "info"
    if kind == "success" then
        accent = Theme.Success
        accentToken = "Success"
        defaultIcon = "circle-check"
    elseif kind == "warning" then
        accent = Theme.Warning
        accentToken = "Warning"
        defaultIcon = "triangle-alert"
    elseif kind == "error" then
        accent = Theme.Error
        accentToken = "Error"
        defaultIcon = "circle-x"
    end

    local slot = create("Frame", {
        Name = "NotificationSlot",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(width, height),
        LayoutOrder = -math.floor(os.clock() * 1000),
        Parent = self.ToastHolder,
        ZIndex = 1000,
    }) :: Frame
    local toast = create("CanvasGroup", {
        Name = "Notification",
        BackgroundColor3 = Theme.ElevatedSurface,
        BackgroundTransparency = 0.14,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.fromOffset(width, height),
        Parent = slot,
        ZIndex = 1001,
    }) :: CanvasGroup
    ThemeController:Bind(toast, "BackgroundColor3", "ElevatedSurface")
    corner(toast, Metrics.PopupRadius)
    stroke(toast, Theme.Border, nil, 1, "Notification")
    AcrylicController:Register(toast, "Notification")

    local accentBar = create("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(2, height - 14),
        Position = UDim2.fromOffset(0, 7),
        Parent = toast,
        ZIndex = 1002,
    }) :: Frame
    corner(accentBar, 2)
    ThemeController:Bind(accentBar, "BackgroundColor3", accentToken)

    local icon = makeIcon(toast, {
        Icon = config.Icon or defaultIcon,
        IconSize = config.IconSize or 10,
        IconColor = config.IconColor,
        IconTransparency = config.IconTransparency,
    }, accentToken)
    if icon then
        icon.Position = UDim2.fromOffset(10, message ~= "" and 9 or 11)
        icon.ZIndex = 1002
    end

    local textOffset = icon and 27 or 10
    local title = makeText(toast, tostring(config.Title or "Kronos"), 9, Theme.Text, "medium")
    title.Position = UDim2.fromOffset(textOffset, 3)
    title.Size = UDim2.new(1, -textOffset - 9, 0, 19)
    title.ZIndex = 1002

    if message ~= "" then
        local content = makeText(toast, message, 8, Theme.SubText)
        content.Position = UDim2.fromOffset(textOffset, 19)
        content.Size = UDim2.new(1, -textOffset - 9, 0, 24)
        content.TextWrapped = true
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.ZIndex = 1002
    end

    local progress = create("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 6, 1, -3),
        Size = UDim2.new(1, -12, 0, 1),
        Parent = toast,
        ZIndex = 1002,
        Visible = not persistent,
    }) :: Frame
    corner(progress, 1)
    ThemeController:Bind(progress, "BackgroundColor3", accentToken)

    local responsiveOwner = self.Windows[1] or { Density = ResponsiveController:GetDensity() }
    ResponsiveController:RegisterTree(responsiveOwner, slot)
    local function d(value: number): number
        return ResponsiveController:Scale(responsiveOwner, value)
    end
    table.insert(self.Notifications, toast)
    local dismissed = false
    local handle: AnyTable = {}
    local timerThread: thread? = nil
    function handle:Destroy()
        if dismissed then
            return
        end
        dismissed = true
        if timerThread then
            pcall(task.cancel, timerThread)
            timerThread = nil
        end
        if toast.Parent then
            ThemeController:UnbindTree(slot)
            if Kronos.Destroyed then
                slot:Destroy()
            else
                tween(
                    toast,
                    { GroupTransparency = 1, Position = UDim2.fromOffset(d(9), 0) },
                    notificationMotion,
                    Enum.EasingStyle.Quart,
                    Enum.EasingDirection.In
                )
                task.delay(AnimationController:Duration(notificationMotion), function()
                    if slot.Parent then
                        slot:Destroy()
                    end
                end)
            end
        end
        local index = table.find(Kronos.Notifications, toast)
        if index then
            table.remove(Kronos.Notifications, index)
        end
        local handleIndex = table.find(Kronos.NotificationHandles, self)
        if handleIndex then
            table.remove(Kronos.NotificationHandles, handleIndex)
        end
    end

    handle.Close = handle.Destroy
    table.insert(self.NotificationHandles, handle)
    tween(toast, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, notificationMotion, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    if not persistent then
        tween(progress, { Size = UDim2.fromOffset(0, d(1)) }, duration, Enum.EasingStyle.Linear)
        timerThread = task.delay(duration, function()
            timerThread = nil
            handle:Destroy()
        end)
    end
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

local SubTab = {}
SubTab.__index = SubTab

local Section = {}
Section.__index = Section

local BaseControl = {}
BaseControl.__index = BaseControl

function BaseControl:_closeTransient()
    InputController:CancelPointer(self)
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
                descendant.TextTransparency = self.Disabled and 0.38 or 0
            end
        end
        if self.Instance:IsA("Frame") then
            self.Instance.BackgroundTransparency = self.Disabled and 0.86
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
    InputController:UnbindKeyboard(self.KeyboardTarget)
    self.KeyboardTarget = nil
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

local function makeControlRow(section, titleText, description, height, iconOptions: IconOptions?)
    local rowOwner: AnyTable = { Connections = {} }
    local rowHeight = height or (description and Metrics.DescriptionRow or Metrics.Row)
    local row = create("Frame", {
        Name = "ControlRow",
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, rowHeight),
        ClipsDescendants = true,
        Parent = section.Content,
    })
    row:SetAttribute("KronosSearch", string.lower(tostring(titleText or "") .. " " .. tostring(description or "")))
    corner(row, 2)
    local rowStroke = stroke(row, Theme.StrokeSoft, nil, 1, "Control")
    ThemeController:Bind(row, "BackgroundColor3", "Surface2")
    ThemeController:Bind(rowStroke, "Color", "StrokeSoft")
    local rowDivider = create("Frame", {
        Name = "RowDivider",
        BackgroundColor3 = Theme.Divider,
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 5, 1, 0),
        Size = UDim2.new(1, -10, 0, 1),
        ZIndex = 1,
        Parent = row,
    }) :: Frame
    ThemeController:Bind(rowDivider, "BackgroundColor3", "Divider")

    local titleOffset = 8
    local rowIcon: ImageLabel? = nil
    if iconOptions and iconOptions.Icon then
        rowIcon = makeIcon(row, iconOptions, "SubText")
        if rowIcon then
            rowIcon.AnchorPoint = Vector2.new(0, 0.5)
            rowIcon.Position = UDim2.new(0, 8, 0.5, 0)
            rowIcon.ZIndex = 2
            titleOffset = 26
        end
    end
    local title = makeText(row, titleText or "Control", 9, Theme.Text, "medium")
    title.Name = "ControlTitle"
    title.Position = UDim2.fromOffset(titleOffset, description and 4 or 0)
    title.Size = UDim2.new(0.6, -titleOffset - 3, 0, 16)
    if not description then
        title.AnchorPoint = Vector2.new(0, 0.5)
        title.Position = UDim2.new(0, titleOffset, 0.5, 0)
        title.Size = UDim2.new(0.6, -titleOffset - 3, 0, 16)
    end

    local descLabel
    if description then
        descLabel = makeText(row, description, 8, Theme.Muted)
        descLabel.Position = UDim2.fromOffset(titleOffset, 18)
        descLabel.Size = UDim2.new(0.64, -titleOffset - 5, 0, 13)
    end

    local holder = create("Frame", {
        Name = "ControlHolder",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.new(0.38, -4, 1, -8),
        Parent = row,
    })

    local hover = makeHitbox(row)
    hover.ZIndex = 0
    addConnection(
        rowOwner,
        hover.MouseEnter:Connect(function()
            if not row:GetAttribute("KronosDisabled") then
                tween(row, { BackgroundTransparency = 0.66 }, Motion.HoverIn)
                tween(rowStroke, { Transparency = BorderController:Resolve(0.52, "ControlHover") }, Motion.HoverIn)
            end
        end)
    )
    addConnection(
        rowOwner,
        hover.MouseLeave:Connect(function()
            tween(row, { BackgroundTransparency = 0.78 }, Motion.HoverOut)
            tween(rowStroke, { Transparency = BorderController:Resolve(0.72, "Control") }, Motion.HoverOut)
        end)
    )

    section.RowConnectionOwners = section.RowConnectionOwners or {}
    section.RowConnectionOwners[row] = rowOwner

    return row, holder, title, descLabel, hover, rowIcon
end

function Section:_control(id, object)
    object.Id = id
    object.Section = self
    object.Window = self.Window
    object.TitleLabel = object.TitleLabel or (object.Instance and object.Instance:FindFirstChild("ControlTitle", true))
    object.BaseTransparency = object.Instance and object.Instance.BackgroundTransparency or 0.78
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
    if object.Instance then
        ResponsiveController:RegisterTree(self.Window, object.Instance)
    end
    return object
end

function Section:CreateToggle(id: any, config: ComponentOptions?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Flag or config.Name or config.Title
    end
    config = config or {}
    local row, holder, titleLabel, _, hitbox =
        makeControlRow(self, config.Name or config.Title or id or "Toggle", config.Description, nil, config)
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
        Position = UDim2.new(1, -1, 0.5, 0),
        Size = UDim2.fromOffset(TargetDesign.Control.Toggle, TargetDesign.Control.Toggle),
        Parent = holder,
        ZIndex = 6,
    }) :: TextButton
    corner(box, 3)
    local boxStroke = stroke(box, toggle.Value and Theme.Accent or Theme.Stroke, toggle.Value and 0.12 or 0.44, 1)
    local check = makeIcon(box, { Icon = "check", IconSize = 9 }, "White")
    if check then
        check.AnchorPoint = Vector2.new(0.5, 0.5)
        check.Position = UDim2.fromScale(0.5, 0.5)
        check.ImageTransparency = toggle.Value and 0 or 1
        check.ZIndex = 7
    end

    local function render(value: boolean, instant: boolean?)
        local duration = instant and 0 or Motion.Toggle
        AnimationController:Tween(box, {
            BackgroundColor3 = value and Theme.Accent or Theme.Surface3,
            BackgroundTransparency = value and 0.04 or 0.24,
        }, duration)
        AnimationController:Tween(boxStroke, {
            Color = value and Theme.Accent or Theme.Stroke,
            Transparency = value and 0.12 or 0.44,
        }, duration)
        if check then
            AnimationController:Tween(check, { ImageTransparency = value and 0 or 1 }, duration)
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
                task.delay(AnimationController:Duration(Motion.Toggle), function()
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

function Section:CreateSlider(id: any, config: ComponentOptions?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Flag or config.Name or config.Title
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
    local row, holder, titleLabel = makeControlRow(
        self,
        config.Name or config.Title or id or "Slider",
        config.Description,
        config.Description and 39 or 31,
        config
    )
    holder.Size = UDim2.new(0.43, -5, 1, -8)

    local slider = setmetatable({
        Value = default,
        Callback = config.Callback,
        ChangedCallbacks = {},
        Instance = row,
        TitleLabel = titleLabel,
        Disabled = false,
    }, BaseControl)
    local valueLabel = makeText(holder, "", 9, Theme.SubText, "bold")
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, 0, 0, -1)
    valueLabel.Size = UDim2.fromOffset(70, 14)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local track = create("Frame", {
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, TargetDesign.Control.SliderTrack),
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
        Size = UDim2.fromOffset(TargetDesign.Control.SliderThumb, TargetDesign.Control.SliderThumb),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Parent = track,
        ZIndex = 3,
    }) :: Frame
    corner(knob, 5)

    local dragging = false
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
    local function finishDrag()
        if not dragging then
            return
        end
        dragging = false
        local size = ResponsiveController:Scale(self.Window, TargetDesign.Control.SliderThumb)
        tween(knob, { Size = UDim2.fromOffset(size, size) }, Motion.Press)
    end
    addConnection(
        slider,
        hit.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                if
                    not InputController:BeginPointer(slider, input, update, function()
                        finishDrag()
                    end)
                then
                    return
                end
                dragging = true
                update(input)
                local size = ResponsiveController:Scale(self.Window, 10)
                tween(knob, { Size = UDim2.fromOffset(size, size) }, Motion.Press)
            end
        end)
    )
    slider.KeyboardTarget = hit
    InputController:BindKeyboard(hit, function(input)
        if slider.Disabled or GuiService.SelectedObject ~= hit then
            return
        end
        if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Down then
            slider:SetValue(slider.Value - step)
        elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.Up then
            slider:SetValue(slider.Value + step)
        end
    end)

    slider.Value = quantize(default)
    render(slider.Value, true)
    local result = self:_control(id, slider)
    if config.Disabled then
        result:SetDisabled(true)
    end
    return result
end
function Section:CreateInput(id: any, config: ComponentOptions?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Flag or config.Name or config.Title
    end
    config = config or {}
    local row, holder, titleLabel =
        makeControlRow(self, config.Name or config.Title or id or "Input", config.Description, nil, config)
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
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        ClearTextOnFocus = config.ClearOnFocus == true,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextColor3 = Theme.Text,
        PlaceholderText = tostring(config.Placeholder or "Type..."),
        PlaceholderColor3 = Theme.Muted,
        Text = input.Value,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClipsDescendants = true,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, TargetDesign.Control.InputHeight),
        Parent = holder,
    }) :: TextBox
    corner(box, 4)
    local boxStroke = stroke(box, Theme.Stroke, nil, 1, "Control")
    padding(box, 7, 0, 7, 0)

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
            tween(box, { BackgroundTransparency = 0.08 }, Motion.Hover)
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
            task.delay(0.38, function()
                if current ~= generation or not target.Parent or not window.Visible then
                    return
                end
                dismissTooltip(window)
                local measured = TextService:GetTextSize(value, 9, Enum.Font.GothamMedium, Vector2.new(220, 100))
                local tip = create("TextLabel", {
                    Name = "Tooltip",
                    BackgroundColor3 = Theme.ElevatedSurface,
                    BackgroundTransparency = 0.08,
                    BorderSizePixel = 0,
                    Text = value,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 9,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Size = UDim2.fromOffset(math.min(measured.X + 14, 236), measured.Y + 10),
                    ZIndex = 930,
                    Parent = window.PopupLayer,
                }) :: TextLabel
                corner(tip, 4)
                stroke(tip, Theme.Border, 0.38, 1, "Floating")
                AcrylicController:Register(tip, "Tooltip")
                padding(tip, 7, 4, 7, 4)
                ResponsiveController:RegisterTree(window, tip)
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
                tween(tip, { TextTransparency = 0, BackgroundTransparency = 0.08 }, Motion.Tooltip)
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

function Section:CreateDropdown(id: any, config: ComponentOptions?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Flag or config.Name or config.Title
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

    local row, holder, titleLabel =
        makeControlRow(self, config.Name or config.Title or id or "Dropdown", config.Description, nil, config)
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
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, TargetDesign.Control.InputHeight),
        Parent = holder,
        ZIndex = 6,
    }) :: TextButton
    corner(button, 4)
    local buttonStroke = stroke(button, Theme.Border, nil, 1, "Control")
    local label = makeText(button, "", 9, Theme.SubText, "medium")
    label.Position = UDim2.fromOffset(8, 0)
    label.Size = UDim2.new(1, -29, 1, 0)
    label.ZIndex = 7
    local arrow = makeIcon(button, { Icon = "chevron-down", IconSize = 9 }, "Muted")
    if arrow then
        arrow.AnchorPoint = Vector2.new(1, 0.5)
        arrow.Position = UDim2.new(1, -6, 0.5, 0)
        arrow.ZIndex = 7
    end

    local function displayValue(): string
        if multi then
            local selected = dropdown.Value :: { any }
            if #selected == 0 then
                return tostring(config.Placeholder or "Select...")
            end
            if #selected > 2 then
                return string.format("%s, %s  +%d", tostring(selected[1]), tostring(selected[2]), #selected - 2)
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
        local visibleRows = math.clamp(#options, 1, 6)
        local popupHeight = visibleRows * 22 + math.max(visibleRows - 1, 0) + 10 + (searchable and 27 or 0)
        popupHeight = math.clamp(popupHeight, 46, searchable and 190 or 160)
        local popup = create("CanvasGroup", {
            Name = "DropdownPopup",
            BackgroundColor3 = Theme.ElevatedSurface,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            GroupTransparency = 1,
            Size = UDim2.fromOffset(math.max(button.AbsoluteSize.X, TargetDesign.Popup.DropdownWidth), popupHeight),
            Visible = false,
            ZIndex = 700,
        }) :: CanvasGroup
        corner(popup, Metrics.PopupRadius)
        stroke(popup, Theme.Border, nil, 1, "Dropdown")
        padding(popup, 5, 5, 5, 5)
        local popupMaid = PopupController:Open(self.Window, popup, button, 5)
        popupMaid:Give(function()
            if arrow and arrow.Parent then
                tween(arrow, { Rotation = 0, ImageColor3 = Theme.Muted }, Motion.PopupClose)
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
                PlaceholderText = "Search",
                PlaceholderColor3 = Theme.Muted,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamMedium,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, TargetDesign.Popup.SearchHeight),
                ZIndex = 702,
                Parent = popup,
            }) :: TextBox
            corner(searchBox, 3)
            stroke(searchBox, Theme.Border, 0.56, 1)
            padding(searchBox, 7, 0, 7, 0)
            topOffset = TargetDesign.Popup.SearchHeight + 4
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
        local optionLayout = list(listFrame, Enum.FillDirection.Vertical, 1)
        popupMaid:Give(optionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.fromOffset(0, optionLayout.AbsoluteContentSize.Y)
        end))
        local empty = makeText(scroll, "No options found", 9, Theme.Muted)
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
                        BackgroundTransparency = selected and 0.64 or 0.82,
                        BorderSizePixel = 0,
                        Text = "",
                        AutoButtonColor = false,
                        Size = UDim2.new(1, 0, 0, TargetDesign.Popup.OptionHeight),
                        ZIndex = 704,
                        Parent = listFrame,
                    }) :: TextButton
                    corner(item, 3)
                    local indicator = create("Frame", {
                        BackgroundColor3 = Theme.Accent,
                        BackgroundTransparency = selected and 0 or 1,
                        BorderSizePixel = 0,
                        Position = UDim2.fromOffset(0, 6),
                        Size = UDim2.fromOffset(2, 10),
                        ZIndex = 705,
                        Parent = item,
                    }) :: Frame
                    ThemeController:Bind(indicator, "BackgroundColor3", "Accent")
                    local optionIconName = type(config.OptionIcons) == "table"
                            and (config.OptionIcons[option] or config.OptionIcons[optionText])
                        or nil
                    local optionOffset = 9
                    local optionIcon =
                        makeIcon(item, { Icon = optionIconName, IconSize = 10 }, selected and "Accent" or "Muted")
                    if optionIcon then
                        optionIcon.AnchorPoint = Vector2.new(0, 0.5)
                        optionIcon.Position = UDim2.new(0, 9, 0.5, 0)
                        optionIcon.ZIndex = 705
                        optionOffset = 26
                    end
                    local optionLabel = makeText(
                        item,
                        optionText,
                        9,
                        selected and Theme.Text or Theme.SubText,
                        selected and "bold" or nil
                    )
                    optionLabel.Position = UDim2.fromOffset(optionOffset, 0)
                    optionLabel.Size = UDim2.new(1, dropdown.Multi and -optionOffset - 23 or -optionOffset - 7, 1, 0)
                    optionLabel.ZIndex = 705
                    if dropdown.Multi then
                        local checkBox = create("Frame", {
                            BackgroundColor3 = selected and Theme.Accent or Theme.Surface3,
                            BackgroundTransparency = selected and 0.04 or 0.24,
                            BorderSizePixel = 0,
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, -6, 0.5, 0),
                            Size = UDim2.fromOffset(11, 11),
                            ZIndex = 705,
                            Parent = item,
                        }) :: Frame
                        corner(checkBox, 3)
                        local checkStroke =
                            stroke(checkBox, selected and Theme.Accent or Theme.Border, selected and 0.12 or 0.44, 1)
                        if selected then
                            ThemeController:Bind(checkBox, "BackgroundColor3", "Accent")
                            ThemeController:Bind(checkStroke, "Color", "Accent")
                        end
                        if selected then
                            local check = makeIcon(checkBox, { Icon = "check", IconSize = 8 }, "White")
                            if check then
                                check.AnchorPoint = Vector2.new(0.5, 0.5)
                                check.Position = UDim2.fromScale(0.5, 0.5)
                                check.ZIndex = 706
                            end
                        end
                    end
                    table.insert(
                        optionConnections,
                        item.MouseEnter:Connect(function()
                            tween(item, { BackgroundTransparency = selected and 0.54 or 0.72 }, Motion.Hover)
                        end)
                    )
                    table.insert(
                        optionConnections,
                        item.MouseLeave:Connect(function()
                            tween(item, { BackgroundTransparency = selected and 0.64 or 0.82 }, Motion.Hover)
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
                if arrow then
                    tween(arrow, { Rotation = 180, ImageColor3 = Theme.Accent }, Motion.Dropdown)
                end
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

function Section:CreateButton(id: any, config: ComponentOptions?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Flag or config.Name or config.Title
    end
    config = config or {}
    local row, holder, titleLabel =
        makeControlRow(self, config.Name or config.Title or id or "Button", config.Description, nil, config)
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
        Size = UDim2.new(1, 0, 0, TargetDesign.Control.Row),
        ZIndex = 6,
        Parent = holder,
    }) :: TextButton
    corner(button, 4)
    local buttonStroke = stroke(
        button,
        config.Primary and Theme.Accent or Theme.Border,
        nil,
        1,
        config.Primary and "Accent" or "Control"
    )
    local label = makeText(button, actionText, 9, config.Primary and Theme.White or Theme.SubText, "bold")
    label.Size = UDim2.fromScale(1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.ZIndex = 7
    function control:SetBusy(busy: boolean): AnyTable
        self.Busy = busy == true
        label.Text = self.Busy and "···" or actionText
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
                tween(button, {
                    Size = UDim2.new(
                        1,
                        -ResponsiveController:Scale(self.Window, 3),
                        0,
                        ResponsiveController:Scale(self.Window, 23)
                    ),
                }, Motion.Press)
            end
        end)
    )
    addConnection(
        control,
        button.MouseButton1Up:Connect(function()
            tween(button, { Size = UDim2.new(1, 0, 0, ResponsiveController:Scale(self.Window, 26)) }, Motion.Press)
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

function Section:CreateLabel(id: any, config: (ComponentOptions | string)?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Flag or config.Name or config.Title or config.Text
    end
    if type(config) == "string" then
        config = { Text = config }
    end
    config = config or {}
    local textValue = tostring(config.Text or config.Name or config.Title or id or "Label")
    local frame = create("Frame", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 21),
        Parent = self.Content,
    }) :: Frame
    frame:SetAttribute("KronosSearch", string.lower(textValue))
    local iconOffset = 0
    local labelIcon = makeIcon(frame, config, config.Muted and "Muted" or "SubText")
    if labelIcon then
        labelIcon.AnchorPoint = Vector2.new(0, 0.5)
        labelIcon.Position = UDim2.new(0, 2, 0.5, 0)
        iconOffset = (labelIcon.Size.X.Offset or 14) + 8
    end
    local label = makeText(
        frame,
        textValue,
        tonumber(config.TextSize) or 9,
        config.Muted and Theme.SubText or Theme.Text,
        config.Bold and "bold" or nil
    )
    label.Position = UDim2.fromOffset(iconOffset, 0)
    label.Size = UDim2.new(1, -iconOffset, 1, 0)
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

function Section:CreateParagraph(id: any, config: ComponentOptions?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Flag or config.Name or config.Title
    end
    config = config or {}
    local textValue = tostring(config.Content or config.Text or "")
    local titleText = config.Name or config.Title
    local frame = create("Frame", {
        Name = "Paragraph",
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 50),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Content,
    }) :: Frame
    corner(frame, 4)
    stroke(frame, Theme.Border, 0.74, 1)
    padding(frame, 8, 6, 8, 6)
    frame:SetAttribute("KronosSearch", string.lower(tostring(titleText or "") .. " " .. textValue))
    local paragraphLayout = list(frame, Enum.FillDirection.Vertical, 3)
    local titleLabel: TextLabel? = nil
    if titleText then
        local heading = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            LayoutOrder = 1,
            Parent = frame,
        }) :: Frame
        local titleOffset = 0
        local paragraphIcon = makeIcon(heading, config, "SubText")
        if paragraphIcon then
            paragraphIcon.AnchorPoint = Vector2.new(0, 0.5)
            paragraphIcon.Position = UDim2.new(0, 0, 0.5, 0)
            titleOffset = paragraphIcon.Size.X.Offset + 6
        end
        titleLabel = makeText(heading, tostring(titleText), 10, Theme.Text, "bold")
        titleLabel.Position = UDim2.fromOffset(titleOffset, 0)
        titleLabel.Size = UDim2.new(1, -titleOffset, 1, 0)
    end
    local content = makeText(frame, textValue, 9, Theme.SubText)
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

function Section:CreateDivider(id: any, config: (ComponentOptions | string)?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Flag or config.Name or config.Title
    elseif type(config) == "string" then
        config = { Title = config }
    end
    config = config or {}
    local frame = create("Frame", {
        Name = "Divider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, (config.Name or config.Title) and 20 or 12),
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
    local dividerTitle = config.Name or config.Title
    if dividerTitle then
        local measured = TextService:GetTextSize(tostring(dividerTitle), 9, Enum.Font.GothamBold, Vector2.new(1000, 16))
        local iconWidth = IconController:Normalize(config.Icon)
                and math.clamp(finiteNumber(config.IconSize, 11), 8, 32) + 5
            or 0
        local titleHolder = create("Frame", {
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(8, 2),
            Size = UDim2.fromOffset(measured.X + iconWidth + 12, 16),
            Parent = frame,
        }) :: Frame
        ThemeController:Bind(titleHolder, "BackgroundColor3", "Surface")
        local dividerIcon = makeIcon(titleHolder, config, "Muted")
        if dividerIcon then
            dividerIcon.AnchorPoint = Vector2.new(0, 0.5)
            dividerIcon.Position = UDim2.new(0, 5, 0.5, 0)
        end
        titleLabel = makeText(titleHolder, tostring(dividerTitle), 9, Theme.Muted, "bold")
        titleLabel.Position = UDim2.fromOffset(iconWidth + 6, 0)
        titleLabel.Size = UDim2.new(1, -iconWidth - 9, 1, 0)
    end
    return self:_control(id, setmetatable({ Value = nil, Instance = frame, TitleLabel = titleLabel }, BaseControl))
end

function Section:CreateKeybind(id: any, config: ComponentOptions?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Flag or config.Name or config.Title
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
    local row, holder, titleLabel =
        makeControlRow(self, config.Name or config.Title or id or "Keybind", config.Description, nil, config)
    holder.Size = UDim2.fromOffset(108, 26)
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
        DisplayName = config.Name or config.Title or id or "Keybind",
        ShowInList = config.ShowInList ~= false,
    }, BaseControl)

    local modeButton = create("TextButton", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Text = string.upper(string.sub(keybind.Mode, 1, 1)),
        TextColor3 = Theme.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -66, 0.5, 0),
        Size = UDim2.fromOffset(22, 22),
        ZIndex = 6,
        Parent = holder,
    }) :: TextButton
    corner(modeButton, 4)
    stroke(modeButton, Theme.Border, nil, 1, "Control")
    local keyButton = create("TextButton", {
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(62, 22),
        ZIndex = 6,
        Parent = holder,
    }) :: TextButton
    corner(keyButton, 4)
    local keyStroke = stroke(keyButton, Theme.Border, nil, 1, "Control")
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
                Size = UDim2.fromOffset(188, 114),
                Visible = false,
                ZIndex = 720,
            }) :: CanvasGroup
            corner(popup, Metrics.PopupRadius)
            stroke(popup, Theme.Border, 0.28, 1, "Floating")
            padding(popup, 7, 7, 7, 7)
            local popupMaid = PopupController:Open(self.Window, popup, modeButton, 5)
            local bindingHeader = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 19),
                ZIndex = 722,
                Parent = popup,
            }) :: Frame
            local bindingIcon = makeIcon(bindingHeader, { Icon = "keyboard", IconSize = 12 }, "Muted")
            if bindingIcon then
                bindingIcon.Position = UDim2.fromOffset(4, 5)
                bindingIcon.ZIndex = 723
            end
            local bindingValue = makeText(bindingHeader, string.upper(tostring(keybind.Value)), 9, Theme.Text, "bold")
            bindingValue.Position = UDim2.fromOffset(25, 0)
            bindingValue.Size = UDim2.new(1, -25, 1, 0)
            bindingValue.ZIndex = 723

            local modeRow = create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 23),
                Size = UDim2.new(1, 0, 0, 25),
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
            valueTitle.Position = UDim2.fromOffset(0, 55)
            valueTitle.Size = UDim2.new(1, 0, 0, 14)
            valueTitle.ZIndex = 722
            local showChoice = create("TextButton", {
                BackgroundColor3 = Theme.Surface2,
                BackgroundTransparency = 0.4,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Position = UDim2.fromOffset(0, 80),
                Size = UDim2.new(1, 0, 0, 27),
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
                Size = UDim2.fromOffset(13, 13),
                ZIndex = 723,
                Parent = showChoice,
            }) :: Frame
            corner(showCheck, 3)
            local showMark = makeIcon(showCheck, { Icon = "check", IconSize = 9 }, "White")
            if showMark then
                showMark.AnchorPoint = Vector2.new(0.5, 0.5)
                showMark.Position = UDim2.fromScale(0.5, 0.5)
                showMark.Visible = keybind.ShowInList
                showMark.ZIndex = 724
            end
            popupMaid:Give(showChoice.Activated:Connect(function()
                keybind:SetShowInList(not keybind.ShowInList)
                showCheck.BackgroundColor3 = keybind.ShowInList and Theme.Accent or Theme.Surface3
                showCheck.BackgroundTransparency = keybind.ShowInList and 0 or 0.16
                if showMark then
                    showMark.Visible = keybind.ShowInList
                end
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

function Section:CreateColorpicker(id: any, config: ComponentOptions?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Flag or config.Name or config.Title
    end
    config = config or {}
    local initial = typeof(config.Default) == "Color3" and config.Default or Theme.Accent
    local initialAlpha = math.clamp(finiteNumber(config.Transparency or config.Alpha, 0), 0, 1)
    local row, holder, titleLabel =
        makeControlRow(self, config.Name or config.Title or id or "Color", config.Description, nil, config)
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
        Size = UDim2.new(1, 0, 0, TargetDesign.Control.InputHeight),
        ZIndex = 6,
        Parent = holder,
    }) :: TextButton
    corner(preview, 4)
    local previewStroke = stroke(preview, Theme.Border, nil, 1, "ColorPicker")
    local previewLabel = makeText(preview, rgbToHex(initial), 8, Theme.White, "bold")
    previewLabel.Size = UDim2.fromScale(1, 1)
    previewLabel.TextXAlignment = Enum.TextXAlignment.Center
    previewLabel.TextStrokeTransparency = 0.58
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
        local popupHeight = alphaEnabled and 214 or 188
        if not continuous then
            popupHeight += 24
        end
        local popup = create("CanvasGroup", {
            Name = "ColorPickerPopup",
            BackgroundColor3 = Theme.ElevatedSurface,
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            GroupTransparency = 1,
            Size = UDim2.fromOffset(TargetDesign.Popup.ColorWidth, popupHeight),
            Visible = false,
            ZIndex = 740,
        }) :: CanvasGroup
        corner(popup, Metrics.PopupRadius)
        stroke(popup, Theme.Border, nil, 1, "ColorPicker")
        padding(popup, 7, 7, 7, 7)
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
            Position = UDim2.fromOffset(0, 22),
            Size = UDim2.fromOffset(142, 86),
            ClipsDescendants = true,
            ZIndex = 742,
            Parent = popup,
        }) :: Frame
        corner(saturationFrame, 4)
        stroke(saturationFrame, Theme.Border, 0.38, 1, "ColorPicker")
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
            Size = UDim2.fromOffset(8, 8),
            ZIndex = 746,
            Parent = saturationFrame,
        }) :: Frame
        corner(saturationDot, 4)
        stroke(saturationDot, Color3.new(0, 0, 0), 0.22, 1)
        local saturationHit = makeHitbox(saturationFrame)
        saturationHit.ZIndex = 745

        local hueFrame = create("Frame", {
            BackgroundColor3 = Theme.White,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(148, 22),
            Size = UDim2.fromOffset(14, 86),
            ClipsDescendants = true,
            ZIndex = 742,
            Parent = popup,
        }) :: Frame
        corner(hueFrame, 4)
        stroke(hueFrame, Theme.Border, 0.4, 1, "ColorPicker")
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
            Size = UDim2.fromOffset(16, 2),
            ZIndex = 746,
            Parent = hueFrame,
        }) :: Frame
        corner(hueMarker, 2)
        local hueHit = makeHitbox(hueFrame)
        hueHit.ZIndex = 745

        local previewChip = create("Frame", {
            BackgroundColor3 = candidate,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 115),
            Size = UDim2.fromOffset(26, 24),
            ZIndex = 742,
            Parent = popup,
        }) :: Frame
        corner(previewChip, 4)
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
            Position = UDim2.fromOffset(30, 115),
            Size = UDim2.fromOffset(62, 24),
            ZIndex = 742,
            Parent = popup,
        }) :: TextBox
        corner(hexBox, 4)
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
            Position = UDim2.fromOffset(94, 115),
            Size = UDim2.fromOffset(72, 24),
            ZIndex = 742,
            Parent = popup,
        }) :: TextBox
        corner(rgbBox, 4)
        stroke(rgbBox, Theme.Border, 0.56, 1)

        local alphaTrack: Frame? = nil
        local alphaFill: Frame? = nil
        local alphaLabel: TextLabel? = nil
        local controlsY = 145
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
                Position = UDim2.fromOffset(0, controlsY + 18),
                Size = UDim2.new(1, 0, 0, 5),
                ZIndex = 742,
                Parent = popup,
            }) :: Frame
            corner(alphaTrack, 3)
            stroke(alphaTrack, Theme.Border, 0.52, 1, "ColorPicker")
            alphaFill = create("Frame", {
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1 - alphaValue, 1),
                ZIndex = 743,
                Parent = alphaTrack,
            }) :: Frame
            corner(alphaFill, 4)
            ThemeController:Bind(alphaFill, "BackgroundColor3", "Accent")
            controlsY += 27
        end

        local presetFrame = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, controlsY),
            Size = UDim2.new(1, 0, 0, 23),
            ZIndex = 742,
            Parent = popup,
        }) :: Frame
        local presetLayout = list(presetFrame, Enum.FillDirection.Horizontal, 4)
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
                Size = UDim2.fromOffset(21, 21),
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
        local function updateActive(input: InputObject)
            if activeDrag == "Saturation" then
                updateSaturation(input.Position)
            elseif activeDrag == "Hue" then
                updateHue(input.Position)
            elseif activeDrag == "Alpha" then
                updateAlpha(input.Position)
            end
        end
        local function beginDrag(kind: string, input: InputObject)
            if
                not InputController:BeginPointer(picker, input, updateActive, function()
                    activeDrag = nil
                end)
            then
                return
            end
            activeDrag = kind
            updateActive(input)
        end
        popupMaid:Give(function()
            InputController:CancelPointer(picker)
            activeDrag = nil
        end)
        popupMaid:Give(saturationHit.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                beginDrag("Saturation", input)
            end
        end))
        popupMaid:Give(hueHit.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                beginDrag("Hue", input)
            end
        end))
        if alphaTrack then
            popupMaid:Give(alphaTrack.InputBegan:Connect(function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    beginDrag("Alpha", input)
                end
            end))
        end
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
                Position = UDim2.fromOffset(0, controlsY + 26),
                Size = UDim2.new(1, 0, 0, 23),
                ZIndex = 742,
                Parent = popup,
            }) :: TextButton
            corner(applyButton, 4)
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

function Section:CreateMultiDropdown(id: any, config: ComponentOptions?): AnyTable
    if type(id) == "table" then
        config = id
        id = config.Id or config.Flag or config.Name or config.Title
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
            local wasVisible = instance.Visible
            instance.Visible = controlMatch and control.ManualVisible ~= false
            if instance.Visible and not wasVisible then
                local restingTransparency = control.BaseTransparency or instance.BackgroundTransparency
                instance.BackgroundTransparency = 1
                tween(instance, { BackgroundTransparency = restingTransparency }, Motion.Search)
            end
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

local function applySubTabInset(owner: AnyTable, _enabled: boolean)
    if not owner.Scroll then
        return
    end
    -- Video 2 keeps sub-navigation in the compact header selector. The page
    -- therefore always owns the complete content viewport instead of losing
    -- vertical space to a duplicate horizontal rail.
    owner.Scroll.Position = UDim2.fromOffset(0, 0)
    owner.Scroll.Size = UDim2.fromScale(1, 1)
end

function SubtabController:Refresh(tab: AnyTable)
    local bar = tab.SubTabBar
    local layout = tab.SubTabBarLayout
    local overflow = tab.SubTabOverflow
    if not bar or not bar.Parent or not layout or not overflow then
        return
    end
    local contentWidth = math.max(layout.AbsoluteContentSize.X + ResponsiveController:Scale(tab.Window, 2), 0)
    bar.CanvasSize = UDim2.fromOffset(contentWidth, 0)
    local maximum = math.max(contentWidth - bar.AbsoluteSize.X, 0)
    local current = math.clamp(bar.CanvasPosition.X, 0, maximum)
    if math.abs(current - bar.CanvasPosition.X) > 0.5 then
        bar.CanvasPosition = Vector2.new(current, 0)
    end
    tab.SubTabOverflowing = maximum > 1
    overflow.Left.Visible = tab.SubTabOverflowing and current > 1 and bar.Visible
    overflow.Right.Visible = tab.SubTabOverflowing and current < maximum - 1 and bar.Visible
end

function SubtabController:Reveal(tab: AnyTable, owner: AnyTable)
    local selector = tab.SubTabSelectors and tab.SubTabSelectors[owner]
    local bar = tab.SubTabBar
    if not selector or not selector.Button or not selector.Button.Parent or not bar or not bar.Parent then
        return
    end
    task.defer(function()
        if not selector.Button.Parent or not bar.Parent then
            return
        end
        self:Refresh(tab)
        local maximum = math.max(bar.AbsoluteCanvasSize.X - bar.AbsoluteSize.X, 0)
        if maximum <= 0 then
            return
        end
        local paddingSize = ResponsiveController:Scale(tab.Window, 7)
        local itemStart = selector.Button.AbsolutePosition.X - bar.AbsolutePosition.X + bar.CanvasPosition.X
        local itemEnd = itemStart + selector.Button.AbsoluteSize.X
        local current = bar.CanvasPosition.X
        local target = current
        if itemStart < current + paddingSize then
            target = itemStart - paddingSize
        elseif itemEnd > current + bar.AbsoluteSize.X - paddingSize then
            target = itemEnd - bar.AbsoluteSize.X + paddingSize
        end
        target = math.clamp(target, 0, maximum)
        if math.abs(target - current) > 0.5 then
            tween(bar, { CanvasPosition = Vector2.new(target, 0) }, Motion.SubTab)
        end
    end)
end

function SubtabController:GetVisibleOwners(tab: AnyTable): { AnyTable }
    local owners: { AnyTable } = {}
    if tab.SubTabSelectors and tab.SubTabSelectors[tab] and tab.SubTabSelectors[tab].Button.Visible then
        table.insert(owners, tab)
    end
    for _, subTab in ipairs(tab.SubTabs or {}) do
        local selector = tab.SubTabSelectors and tab.SubTabSelectors[subTab]
        if selector and selector.Button.Visible then
            table.insert(owners, subTab)
        end
    end
    return owners
end

function SubtabController:SelectAdjacent(tab: AnyTable, owner: AnyTable, direction: number)
    local owners = self:GetVisibleOwners(tab)
    local currentIndex = table.find(owners, owner)
    if not currentIndex or #owners <= 1 then
        return
    end
    local nextIndex = ((currentIndex - 1 + direction) % #owners) + 1
    local nextOwner = owners[nextIndex]
    tab:SelectSubTab(nextOwner)
    local selector = tab.SubTabSelectors and tab.SubTabSelectors[nextOwner]
    if selector and selector.Button then
        GuiService.SelectedObject = selector.Button
        self:Reveal(tab, nextOwner)
    end
end

function SubtabController:Attach(tab: AnyTable)
    if tab.SubTabOverflow or not tab.SubTabBar or not tab.Page then
        return
    end
    local page = tab.Page
    local bar = tab.SubTabBar
    local function makeFade(name: string, left: boolean): Frame
        local fade = create("Frame", {
            Name = name,
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            AnchorPoint = left and Vector2.zero or Vector2.new(1, 0),
            Position = left and UDim2.fromOffset(7, 5) or UDim2.new(1, -7, 0, 5),
            Size = UDim2.fromOffset(20, 28),
            Visible = false,
            ZIndex = page.ZIndex + 6,
            Parent = page,
        }) :: Frame
        create("UIGradient", {
            Rotation = 0,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, left and 0 or 1),
                NumberSequenceKeypoint.new(1, left and 1 or 0),
            }),
            Parent = fade,
        })
        ThemeController:Bind(fade, "BackgroundColor3", "Background")
        return fade
    end
    tab.SubTabOverflow = {
        Left = makeFade("SubTabFadeLeft", true),
        Right = makeFade("SubTabFadeRight", false),
    }
    for _, signal in ipairs({
        tab.SubTabBarLayout:GetPropertyChangedSignal("AbsoluteContentSize"),
        bar:GetPropertyChangedSignal("AbsoluteSize"),
        bar:GetPropertyChangedSignal("CanvasPosition"),
        bar:GetPropertyChangedSignal("Visible"),
    }) do
        addConnection(
            tab,
            signal:Connect(function()
                self:Refresh(tab)
            end)
        )
    end
    self:Refresh(tab)
end

function Tab:_setSubTabVisual(owner: AnyTable, active: boolean)
    local selector = self.SubTabSelectors and self.SubTabSelectors[owner]
    if not selector then
        return
    end
    tween(selector.Button, {
        BackgroundColor3 = active and Theme.PressedSurface or Theme.Surface2,
        BackgroundTransparency = active and 0.76 or 1,
    }, Motion.SubTab)
    tween(selector.Marker, {
        BackgroundTransparency = active and 0 or 1,
        Size = active
                and UDim2.fromOffset(
                    ResponsiveController:Scale(self.Window, 12),
                    ResponsiveController:Scale(self.Window, 2)
                )
            or UDim2.fromOffset(
                ResponsiveController:Scale(self.Window, 6),
                ResponsiveController:Scale(self.Window, 2)
            ),
    }, Motion.SubTab)
    tween(selector.Label, { TextColor3 = active and Theme.Text or Theme.SubText }, Motion.SubTab)
    if selector.Icon then
        tween(selector.Icon, { ImageColor3 = active and Theme.Accent or Theme.Muted }, Motion.SubTab)
    end
end

function Tab:_createSubTabSelector(owner: AnyTable, config: AnyTable): AnyTable
    self.SubTabSelectors = self.SubTabSelectors or {}
    local existing = self.SubTabSelectors[owner]
    if existing then
        return existing
    end
    local titleText = tostring(config.Name or config.Title or "General")
    local iconSize = IconController:Normalize(config.Icon) and math.clamp(finiteNumber(config.IconSize, 11), 8, 24) or 0
    local textSize = TextService:GetTextSize(titleText, 9, Enum.Font.GothamBold, Vector2.new(640, 24))
    local horizontalPadding = iconSize > 0 and iconSize + 15 or 16
    local width = math.clamp(textSize.X + horizontalPadding, 40, 220)
    local button = create("TextButton", {
        Name = "SubTabButton",
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Selectable = true,
        Size = UDim2.fromOffset(width, 23),
        Parent = self.SubTabBar,
    }) :: TextButton
    corner(button, 4)
    local selectorStroke = stroke(button, Theme.Border, nil, 1, "Quiet")
    ThemeController:Bind(selectorStroke, "Color", "Border")
    local offset = 9
    local icon = makeIcon(button, config, "Muted")
    if icon then
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Position = UDim2.new(0, 8, 0.5, 0)
        icon.ZIndex = 3
        offset = icon.Size.X.Offset + 13
    end
    local label = makeText(button, titleText, 9, Theme.SubText, "bold")
    label.Position = UDim2.fromOffset(offset, 0)
    label.Size = UDim2.new(1, -offset - 7, 1, 0)
    label.ZIndex = 3
    local marker = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.fromOffset(7, 2),
        ZIndex = 4,
        Parent = button,
    }) :: Frame
    corner(marker, 1)
    ThemeController:Bind(marker, "BackgroundColor3", "Accent")
    local selector = { Button = button, Label = label, Icon = icon, Marker = marker }
    self.SubTabSelectors[owner] = selector
    addConnection(
        owner,
        button.Activated:Connect(function()
            self:SelectSubTab(owner)
        end)
    )
    addConnection(
        owner,
        button.MouseEnter:Connect(function()
            if self.ActiveSubTab ~= owner then
                tween(button, { BackgroundTransparency = 0.84 }, Motion.HoverIn)
                tween(selectorStroke, { Transparency = BorderController:Resolve(0.52, "ControlHover") }, Motion.HoverIn)
            end
        end)
    )
    addConnection(
        owner,
        button.MouseLeave:Connect(function()
            if self.ActiveSubTab ~= owner then
                tween(button, { BackgroundTransparency = 1 }, Motion.HoverOut)
                tween(selectorStroke, { Transparency = BorderController:Resolve(0.74, "Quiet") }, Motion.HoverOut)
            end
        end)
    )
    addConnection(
        owner,
        button.SelectionGained:Connect(function()
            SubtabController:Reveal(self, owner)
        end)
    )
    addConnection(
        owner,
        button.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard and input.UserInputType ~= Enum.UserInputType.Gamepad1 then
                return
            end
            if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.DPadLeft then
                SubtabController:SelectAdjacent(self, owner, -1)
            elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.DPadRight then
                SubtabController:SelectAdjacent(self, owner, 1)
            end
        end)
    )
    ResponsiveController:RegisterTree(self.Window, button)
    task.defer(function()
        SubtabController:Refresh(self)
    end)
    return selector
end

function Tab:_ensureDefaultSubTabSelector()
    if self.SubTabSelectors and self.SubTabSelectors[self] then
        return
    end
    self:_createSubTabSelector(self, { Name = self.DefaultSubTabName or "General" })
    self.SearchVisible = true
end

function Tab:SelectSubTab(owner: AnyTable): AnyTable
    if owner ~= self and table.find(self.SubTabs, owner) == nil then
        return self
    end
    if owner.SearchVisible == false or self.ActiveSubTab == owner then
        return self
    end
    dismissTooltip(self.Window)
    PopupController:Close(self.Window)
    local owners = { self }
    for _, subTab in ipairs(self.SubTabs) do
        table.insert(owners, subTab)
    end
    for _, candidate in ipairs(owners) do
        local active = candidate == owner
        if candidate.Scroll then
            candidate.Scroll.Visible = active
        end
        self:_setSubTabVisual(candidate, active)
    end
    self.SubtabTransitionGeneration = (self.SubtabTransitionGeneration or 0) + 1
    self.ActiveSubTab = owner
    if self.Window and type(self.Window._refreshHeaderContext) == "function" then
        self.Window:_refreshHeaderContext()
    end
    owner.Scroll.Visible = true
    owner.Columns.AnchorPoint = Vector2.new(0.5, 0)
    owner.Columns.Position = UDim2.new(
        0.5,
        ResponsiveController:Scale(self.Window, 3),
        0,
        ResponsiveController:Scale(self.Window, 7)
    )
    tween(owner.Columns, {
        Position = UDim2.new(0.5, 0, 0, ResponsiveController:Scale(self.Window, 7)),
    }, Motion.SubtabSelect)
    SubtabController:Reveal(self, owner)
    owner:ApplyColumns(self.Window.TwoColumn)
    return self
end

function Tab:_updateCanvas()
    task.defer(function()
        if not self.Scroll or not self.Scroll.Parent then
            return
        end
        local leftHeight = self.LeftLayout.AbsoluteContentSize.Y
        local rightHeight = self.TwoColumn and self.RightLayout.AbsoluteContentSize.Y or 0
        local height = self.TwoColumn and math.max(leftHeight, rightHeight) or leftHeight
        self.Columns.Size = UDim2.new(self.Columns.Size.X.Scale, self.Columns.Size.X.Offset, 0, height)
        self.Scroll.CanvasSize = UDim2.fromOffset(0, height + ResponsiveController:Scale(self.Window, 18))
    end)
end

function Tab:_applyContentWidth()
    if not self.Scroll or not self.Columns then
        return
    end
    local function d(value: number): number
        return ResponsiveController:Scale(self.Window, value)
    end
    local available = math.max(self.Scroll.AbsoluteSize.X - d(12), 1)
    local preferredMinimum = math.min(d(Metrics.MinimumSection), available)
    local contentWidth = math.clamp(math.min(available, d(Metrics.MaximumContent)), preferredMinimum, available)
    self.Columns.AnchorPoint = Vector2.new(0.5, 0)
    self.Columns.Position = UDim2.new(0.5, 0, 0, d(5))
    self.Columns.Size = UDim2.fromOffset(contentWidth, self.Columns.Size.Y.Offset)

    if self.TwoColumn then
        local halfGap = d(Metrics.ColumnGap) * 0.5
        self.LeftColumn.AnchorPoint = Vector2.zero
        self.LeftColumn.Position = UDim2.fromOffset(0, 0)
        self.LeftColumn.Size = UDim2.new(0.5, -halfGap, 0, 0)
        self.RightColumn.AnchorPoint = Vector2.zero
        self.RightColumn.Position = UDim2.new(0.5, halfGap, 0, 0)
        self.RightColumn.Size = UDim2.new(0.5, -halfGap, 0, 0)
    else
        local singleWidth = math.min(contentWidth, d(Metrics.SingleColumnMaximum))
        self.LeftColumn.AnchorPoint = Vector2.new(0.5, 0)
        self.LeftColumn.Position = UDim2.new(0.5, 0, 0, 0)
        self.LeftColumn.Size = UDim2.fromOffset(singleWidth, 0)
        self.RightColumn.AnchorPoint = Vector2.zero
        self.RightColumn.Position = UDim2.fromOffset(0, 0)
    end
end

function Tab:ApplyColumns(twoColumn: boolean)
    if self.TwoColumn == twoColumn and self.ColumnsInitialized then
        self:_applyContentWidth()
        self:_updateCanvas()
        return
    end
    self.TwoColumn = twoColumn
    self.ColumnsInitialized = true
    self.RightColumn.Visible = twoColumn
    if twoColumn then
        for index, section in ipairs(self.Sections) do
            local side = section.PreferredSide
            if side == nil then
                side = index % 2 == 0 and "Right" or "Left"
            end
            section.Instance.Parent = side == "Right" and self.RightColumn or self.LeftColumn
        end
    else
        for _, section in ipairs(self.Sections) do
            section.Instance.Parent = self.LeftColumn
        end
    end
    self:_applyContentWidth()
    self:_updateCanvas()
    if not self.ParentTab then
        for _, subTab in ipairs(self.SubTabs or {}) do
            Tab.ApplyColumns(subTab, twoColumn)
        end
    end
end

function Tab:RefreshSearch(query: string): boolean
    local normalized = string.lower(query)
    local tabMatch = normalized == "" or string.find(string.lower(self.Title), normalized, 1, true) ~= nil
    local anySection = false
    for _, section in ipairs(self.Sections) do
        anySection = section:RefreshSearch(normalized, tabMatch) or anySection
    end
    local firstVisibleOwner: AnyTable? = nil
    if self.HasSubTabs then
        local defaultVisible = #self.Sections > 0 and (tabMatch or anySection)
        local defaultSelector = self.SubTabSelectors[self]
        if defaultSelector then
            defaultSelector.Button.Visible = defaultVisible
        end
        self.SearchVisible = defaultVisible
        if defaultVisible then
            firstVisibleOwner = self
        end
        for _, subTab in ipairs(self.SubTabs) do
            local subVisible = subTab:RefreshSearch(normalized, tabMatch)
            anySection = subVisible or anySection
            firstVisibleOwner = firstVisibleOwner or (subVisible and subTab or nil)
        end
        local activeOwner = self.ActiveSubTab
        if activeOwner and activeOwner.SearchVisible == false then
            self.ActiveSubTab = nil
        end
        if not self.ActiveSubTab and firstVisibleOwner then
            self:SelectSubTab(firstVisibleOwner)
        end
    end
    self.SearchVisible = tabMatch or anySection or firstVisibleOwner ~= nil
    self.Button.Visible = self.SearchVisible
    self:_updateCanvas()
    return self.SearchVisible
end

function Tab:CreateSection(config: (NavigationOptions | string)?): AnyTable
    if type(config) == "string" then
        config = { Title = config }
    end
    config = config or {}
    if self.HasSubTabs then
        self:_ensureDefaultSubTabSelector()
        if not self.ActiveSubTab then
            self:SelectSubTab(self)
        end
    end
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
        Title = tostring(config.Name or config.Title or "Section"),
    }, Section)
    section.SearchText = string.lower(section.Title .. " " .. tostring(config.Description or ""))

    local frame = create("Frame", {
        Name = "Section",
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.62,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = index,
        Parent = parent,
    }) :: Frame
    frame:SetAttribute("KronosSearch", section.SearchText)
    corner(frame, 4)
    local frameStroke = stroke(frame, Theme.Border, nil, 1, "Section")
    ThemeController:Bind(frameStroke, "Color", "Border")
    padding(frame, 6, 5, 6, 5)
    local frameLayout = list(frame, Enum.FillDirection.Vertical, 0)

    local heading = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, config.Description and 22 or 15),
        LayoutOrder = 1,
        Parent = frame,
    }) :: Frame
    local titleOffset = 0
    if config.Icon then
        local icon = makeIcon(heading, config, "Accent")
        if icon then
            icon.Position = UDim2.fromOffset(0, 1)
            titleOffset = icon.Size.X.Offset + 5
        end
    end
    local title = makeText(heading, section.Title, 8, Theme.SubText, "medium")
    title.Position = UDim2.fromOffset(titleOffset, 0)
    title.Size = UDim2.new(1, -titleOffset, 0, 14)
    if config.Description then
        local description = makeText(heading, tostring(config.Description), 8, Theme.Muted)
        description.Position = UDim2.fromOffset(titleOffset, 11)
        description.Size = UDim2.new(1, -titleOffset, 0, 11)
    end

    local content = create("Frame", {
        Name = "Controls",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Parent = frame,
    }) :: Frame
    local contentLayout = list(content, Enum.FillDirection.Vertical, 0)
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
    ResponsiveController:RegisterTree(self.Window, frame)
    self:ApplyColumns(self.TwoColumn)
    self:_updateCanvas()
    return section
end

Tab.AddSection = Tab.CreateSection

SubTab._updateCanvas = Tab._updateCanvas
SubTab._applyContentWidth = Tab._applyContentWidth
SubTab.ApplyColumns = Tab.ApplyColumns
SubTab.CreateSection = Tab.CreateSection
SubTab.AddSection = Tab.CreateSection

function SubTab:RefreshSearch(query: string, parentMatch: boolean?): boolean
    local normalized = string.lower(query)
    local subTabMatch = parentMatch == true
        or normalized == ""
        or string.find(string.lower(self.Title), normalized, 1, true) ~= nil
    local anySection = false
    for _, section in ipairs(self.Sections) do
        anySection = section:RefreshSearch(normalized, subTabMatch) or anySection
    end
    self.SearchVisible = subTabMatch or anySection
    local selector = self.ParentTab.SubTabSelectors[self]
    if selector then
        selector.Button.Visible = self.SearchVisible
    end
    if not self.SearchVisible then
        self.Scroll.Visible = false
    end
    self:_updateCanvas()
    return self.SearchVisible
end

function SubTab:Select(): AnyTable
    self.ParentTab:SelectSubTab(self)
    return self
end

function SubTab:Destroy()
    local parentTab = self.ParentTab
    local wasActive = parentTab.ActiveSubTab == self
    local sections = copyArray(self.Sections)
    for _, section in ipairs(sections) do
        section:Destroy()
    end
    disconnectAll(self)
    local selector = parentTab.SubTabSelectors[self]
    if selector and selector.Button then
        ThemeController:UnbindTree(selector.Button)
        selector.Button:Destroy()
    end
    parentTab.SubTabSelectors[self] = nil
    if self.Scroll then
        ThemeController:UnbindTree(self.Scroll)
        self.Scroll:Destroy()
    end
    removeArrayValue(parentTab.SubTabs, self)
    if #parentTab.SubTabs == 0 then
        parentTab.HasSubTabs = false
        parentTab.ActiveSubTab = nil
        parentTab.SubTabBar.Visible = false
        applySubTabInset(parentTab, false)
        parentTab.Scroll.Visible = true
        local defaultSelector = parentTab.SubTabSelectors[parentTab]
        if defaultSelector then
            ThemeController:UnbindTree(defaultSelector.Button)
            defaultSelector.Button:Destroy()
            parentTab.SubTabSelectors[parentTab] = nil
        end
    elseif wasActive then
        parentTab.ActiveSubTab = nil
        if #parentTab.Sections > 0 then
            parentTab:SelectSubTab(parentTab)
        else
            parentTab:SelectSubTab(parentTab.SubTabs[1])
        end
    end
    SubtabController:Refresh(parentTab)
end

function Tab:CreateSubTab(config: (NavigationOptions | string)?): AnyTable
    if type(config) == "string" then
        config = { Name = config }
    end
    config = config or {}
    if not self.HasSubTabs then
        self.HasSubTabs = true
        self.SubTabBar.Visible = false
        applySubTabInset(self, true)
        if #self.Sections > 0 then
            self:_ensureDefaultSubTabSelector()
            self.ActiveSubTab = self
            self:_setSubTabVisual(self, true)
        else
            self.Scroll.Visible = false
        end
    end
    local subTab = setmetatable({
        ParentTab = self,
        Window = self.Window,
        Title = tostring(config.Name or config.Title or "Subtab"),
        Sections = {},
        Connections = {},
        SearchVisible = true,
        TwoColumn = self.Window.TwoColumn,
    }, SubTab)
    local scroll = create("ScrollingFrame", {
        Name = "SubTabContent",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.08,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        Parent = self.Page,
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
    subTab.Scroll = scroll
    subTab.Columns = columns
    subTab.LeftColumn = leftColumn
    subTab.RightColumn = rightColumn
    subTab.LeftLayout = leftLayout
    subTab.RightLayout = rightLayout
    addConnection(
        subTab,
        leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            subTab:_updateCanvas()
        end)
    )
    addConnection(
        subTab,
        rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            subTab:_updateCanvas()
        end)
    )
    table.insert(self.SubTabs, subTab)
    self:_createSubTabSelector(subTab, config)
    SubtabController:Refresh(self)
    ResponsiveController:RegisterTree(self.Window, scroll)
    subTab:ApplyColumns(self.Window.TwoColumn)
    if not self.ActiveSubTab then
        self:SelectSubTab(subTab)
    end
    return subTab
end

Tab.AddSubTab = Tab.CreateSubTab
Tab.AddSubtab = Tab.CreateSubTab

function Tab:Destroy()
    local wasActive = self.Window.ActiveTab == self
    local subTabs = copyArray(self.SubTabs)
    for _, subTab in ipairs(subTabs) do
        subTab:Destroy()
    end
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
        BackgroundTransparency = active and 0.84 or 1,
    }, Motion.Tab)
    tween(tab.ActiveBar, {
        BackgroundTransparency = active and 0 or 1,
        Size = active and UDim2.fromOffset(ResponsiveController:Scale(self, 2), ResponsiveController:Scale(self, 12))
            or UDim2.fromOffset(ResponsiveController:Scale(self, 2), ResponsiveController:Scale(self, 5)),
    }, Motion.Tab)
    if tab.IconLabel then
        tween(tab.IconLabel, { ImageColor3 = active and Theme.Accent or Theme.Muted }, Motion.Tab)
    end
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
    if
        self.SearchBehavior == "ClearOnNavigation"
        and not self.ApplyingSearch
        and self.SearchBox
        and self.SearchBox.Text ~= ""
    then
        self.SearchBox.Text = ""
        self:ApplySearch("")
    end
    dismissTooltip(self)
    PopupController:Close(self)
    self.PageTransitionGeneration = (self.PageTransitionGeneration or 0) + 1
    local transitionGeneration = self.PageTransitionGeneration
    local pageEnterMotion = self.Kronos.PageTransitions ~= false and Motion.PageEnter or 0
    local pageExitMotion = self.Kronos.PageTransitions ~= false and Motion.PageExit or 0
    if self.ActiveTab then
        local previousTab = self.ActiveTab
        self:_setActiveTabVisual(previousTab, false)
        tween(previousTab.Page, { GroupTransparency = 1, Position = UDim2.fromOffset(-3, 0) }, pageExitMotion)
        task.delay(AnimationController:Duration(pageExitMotion), function()
            if
                self.PageTransitionGeneration == transitionGeneration
                and self.ActiveTab ~= previousTab
                and previousTab.Page.Parent
            then
                previousTab.Page.Visible = false
            end
        end)
    end
    self.ActiveTab = tab
    tab.Page.Visible = true
    tab.Page.Position = UDim2.fromOffset(3, 0)
    tab.Page.GroupTransparency = 1
    tween(tab.Page, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, pageEnterMotion)
    self:_setActiveTabVisual(tab, true)
    self:_refreshHeaderContext()
    tab:ApplyColumns(self.TwoColumn)
    if tab.HasSubTabs and not tab.ActiveSubTab then
        if #tab.Sections > 0 then
            tab:SelectSubTab(tab)
        elseif tab.SubTabs[1] then
            tab:SelectSubTab(tab.SubTabs[1])
        end
    end
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

function Window:CreateTab(config: (NavigationOptions | string)?): AnyTable
    if type(config) == "string" then
        config = { Title = config }
    end
    config = config or {}
    local tab = setmetatable({
        Window = self,
        Title = tostring(config.Name or config.Title or "Tab"),
        Sections = {},
        SubTabs = {},
        SubTabSelectors = {},
        Connections = {},
        SearchVisible = true,
        TwoColumn = self.TwoColumn,
        HasSubTabs = false,
        DefaultSubTabName = config.DefaultSubTabName,
    }, Tab)
    local button = create("TextButton", {
        Name = "TabButton",
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, TargetDesign.Navigation.TabHeight),
        Parent = self.SidebarList,
    }) :: TextButton
    button:SetAttribute("KronosSearch", string.lower(tab.Title))
    corner(button, 4)
    local activeBar = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(2, 7),
        Parent = button,
    }) :: Frame
    corner(activeBar, 1)
    ThemeController:Bind(activeBar, "BackgroundColor3", "Accent")
    local icon = makeIcon(button, config, "Muted")
    if icon then
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Position = UDim2.new(0, 12, 0.5, 0)
    end
    local title = makeText(button, tab.Title, 9, Theme.SubText)
    local titleOffset = icon and (icon.Size.X.Offset + 20) or 11
    title.Position = UDim2.fromOffset(titleOffset, 0)
    title.Size = UDim2.new(1, -titleOffset - 7, 1, 0)

    local page = create("CanvasGroup", {
        Name = "TabPage",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = self.PageHost,
    }) :: CanvasGroup
    local subTabBar = create("ScrollingFrame", {
        Name = "SubTabBar",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(7, 3),
        Size = UDim2.new(1, -14, 0, 25),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        Visible = false,
        Parent = page,
    }) :: ScrollingFrame
    local subTabBarLayout = list(subTabBar, Enum.FillDirection.Horizontal, 2)
    subTabBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
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
    tab.SubTabBar = subTabBar
    tab.SubTabBarLayout = subTabBarLayout
    tab.Scroll = scroll
    tab.Columns = columns
    tab.LeftColumn = leftColumn
    tab.RightColumn = rightColumn
    tab.LeftLayout = leftLayout
    tab.RightLayout = rightLayout
    SubtabController:Attach(tab)
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
                tween(button, { BackgroundTransparency = 0.78 }, Motion.Hover)
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
    ResponsiveController:RegisterTree(self, button)
    ResponsiveController:RegisterTree(self, page)
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
        tab = self:CreateTab({ Title = "General", Icon = "house" })
    end
    return tab:CreateSection(config)
end

function Window:Notify(config: NotificationOptions?): AnyTable
    return self.Kronos:Notify(config)
end

local function makeUtilityButton(parent: Instance, iconName: string, order: number): TextButton
    local button = create("TextButton", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.44,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(
            1,
            -(8 + (order - 1) * (TargetDesign.Header.UtilitySize + 5)),
            0.5,
            0
        ),
        Size = UDim2.fromOffset(TargetDesign.Header.UtilitySize, TargetDesign.Header.UtilitySize),
        ZIndex = 32,
        Parent = parent,
    }) :: TextButton
    corner(button, 5)
    stroke(button, Theme.Border, nil, 1, "Control")
    local icon = makeIcon(button, { Icon = iconName, IconSize = 11 }, "SubText")
    if icon then
        icon.Name = "UtilityIcon"
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.ZIndex = 33
    end
    return button
end

function Window:_refreshHeaderContext()
    local label = self.HeaderContextLabel
    if not label or not label.Parent then
        return
    end

    local activeTab = self.ActiveTab
    if not activeTab then
        label.Text = "Overview"
        return
    end

    local activeSubTab = activeTab.ActiveSubTab
    if activeSubTab and activeSubTab ~= activeTab then
        label.Text = tostring(activeSubTab.Title)
    else
        label.Text = tostring(activeTab.DefaultSubTabName or activeTab.Title)
    end

    local breadcrumb = self.BreadcrumbLabel
    if breadcrumb and breadcrumb.Parent then
        if activeSubTab and activeSubTab ~= activeTab then
            breadcrumb.Text = tostring(activeTab.Title) .. "   ›   " .. tostring(activeSubTab.Title)
        else
            breadcrumb.Text = tostring(activeTab.Title)
        end
    end
end

function Window:_openHeaderContext()
    local anchor = self.HeaderContext
    if not anchor or not anchor.Parent then
        return
    end
    if self.ActivePopup and self.ActivePopup.Anchor == anchor then
        PopupController:Close(self)
        return
    end

    local entries: { AnyTable } = {}
    local activeTab = self.ActiveTab
    if not activeTab or activeTab.SearchVisible == false then
        return
    end

    if activeTab.HasSubTabs then
        local defaultSelector = activeTab.SubTabSelectors and activeTab.SubTabSelectors[activeTab]
        if defaultSelector and activeTab.SearchVisible ~= false then
            table.insert(entries, {
                Label = tostring(activeTab.DefaultSubTabName or "General"),
                Tab = activeTab,
                Owner = activeTab,
                Indent = false,
            })
        end
        for _, subTab in ipairs(activeTab.SubTabs) do
            if subTab.SearchVisible ~= false then
                table.insert(entries, {
                    Label = tostring(subTab.Title),
                    Tab = activeTab,
                    Owner = subTab,
                    Indent = false,
                })
            end
        end
    else
        table.insert(entries, {
            Label = tostring(activeTab.Title),
            Tab = activeTab,
            Owner = nil,
            Indent = false,
        })
    end
    if #entries == 0 then
        return
    end

    local visibleRows = math.min(#entries, 8)
    local popup = create("CanvasGroup", {
        Name = "HeaderContextPopup",
        BackgroundColor3 = Theme.ElevatedSurface,
        BackgroundTransparency = 0.035,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Size = UDim2.fromOffset(228, visibleRows * 29 + 12),
        Visible = false,
        ZIndex = 780,
    }) :: CanvasGroup
    corner(popup, Metrics.PopupRadius)
    local popupStroke = stroke(popup, Theme.Border, nil, 1, "Popup")
    ThemeController:Bind(popupStroke, "Color", "Border")

    local scroll = create("ScrollingFrame", {
        Name = "ContextItems",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.new(1, -12, 1, -12),
        CanvasSize = UDim2.fromOffset(0, #entries * 29),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 781,
        Parent = popup,
    }) :: ScrollingFrame
    local rowLayout = list(scroll, Enum.FillDirection.Vertical, 1)
    rowLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local popupMaid = PopupController:Open(self, popup, anchor, 6)
    for index, entry in ipairs(entries) do
        local selected = entry.Tab == self.ActiveTab
            and ((entry.Owner == nil and not entry.Tab.HasSubTabs)
                or entry.Owner == entry.Tab.ActiveSubTab
                or (entry.Owner == entry.Tab and entry.Tab.ActiveSubTab == entry.Tab))
        local row = create("TextButton", {
            Name = "ContextRow",
            BackgroundColor3 = selected and Theme.PressedSurface or Theme.Surface2,
            BackgroundTransparency = selected and 0.28 or 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.new(1, -4, 0, 28),
            LayoutOrder = index,
            ZIndex = 782,
            Parent = scroll,
        }) :: TextButton
        corner(row, 4)
        local x = entry.Indent and 24 or 10
        if entry.Indent then
            local branch = makeIcon(row, { Icon = "corner-down-right", IconSize = 10 }, "Muted")
            if branch then
                branch.AnchorPoint = Vector2.new(0, 0.5)
                branch.Position = UDim2.new(0, 8, 0.5, 0)
                branch.ZIndex = 783
            end
        end
        local rowLabel = makeText(
            row,
            entry.Label,
            entry.Indent and 9 or 10,
            selected and Theme.Text or Theme.SubText,
            entry.Indent and nil or "bold"
        )
        rowLabel.Position = UDim2.fromOffset(x, 0)
        rowLabel.Size = UDim2.new(1, -x - 26, 1, 0)
        rowLabel.ZIndex = 783
        if selected then
            local selectedIcon = makeIcon(row, { Icon = "check", IconSize = 11 }, "Accent")
            if selectedIcon then
                selectedIcon.AnchorPoint = Vector2.new(1, 0.5)
                selectedIcon.Position = UDim2.new(1, -8, 0.5, 0)
                selectedIcon.ZIndex = 783
            end
        end
        popupMaid:Give(row.MouseEnter:Connect(function()
            tween(row, { BackgroundTransparency = selected and 0.2 or 0.48 }, Motion.HoverIn)
        end))
        popupMaid:Give(row.MouseLeave:Connect(function()
            tween(row, { BackgroundTransparency = selected and 0.28 or 1 }, Motion.HoverOut)
        end))
        popupMaid:Give(row.Activated:Connect(function()
            self:SelectTab(entry.Tab)
            if entry.Owner then
                entry.Tab:SelectSubTab(entry.Owner)
            end
            PopupController:Close(self)
        end))
    end
    tween(popup, { GroupTransparency = 0 }, Motion.PopupEnter)
end

function Window:_makeHeader(config: WindowConfig)
    local header = create("Frame", {
        Name = "Header",
        BackgroundColor3 = Theme.BackgroundSoft,
        BackgroundTransparency = 0.19,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Metrics.Header),
        ZIndex = 25,
        Parent = self.Main,
    }) :: Frame
    ThemeController:Bind(header, "BackgroundColor3", "BackgroundSoft")
    local divider = create("Frame", {
        Name = "HeaderDivider",
        BackgroundColor3 = Theme.Divider,
        BackgroundTransparency = 0.42,
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
        Size = UDim2.new(1, -42, 1, 0),
        ZIndex = 27,
        Parent = header,
    }) :: Frame

    local hasLogo = IconController:Normalize(config.Icon) ~= nil
    local logo = create("Frame", {
        Name = "BrandMark",
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, math.floor((Metrics.Header - TargetDesign.Header.BrandSize) * 0.5)),
        Size = UDim2.fromOffset(TargetDesign.Header.BrandSize, TargetDesign.Header.BrandSize),
        Visible = hasLogo,
        ZIndex = 29,
        Parent = header,
    }) :: Frame
    corner(logo, 5)
    local logoStroke = stroke(logo, Theme.AccentSoft, 0.96, 1)
    ThemeController:Bind(logo, "BackgroundColor3", "Accent")
    ThemeController:Bind(logoStroke, "Color", "AccentSoft")
    local logoIcon = hasLogo and makeIcon(logo, {
        Icon = config.Icon,
        IconSize = math.min(config.IconSize or 16, 17),
        IconColor = config.IconColor,
        IconTransparency = config.IconTransparency,
    }, "Accent") or nil
    if logoIcon then
        logoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        logoIcon.Position = UDim2.fromScale(0.5, 0.5)
        logoIcon.ZIndex = 30
    end

    local titleOffset = hasLogo and 36 or 12
    local title = makeText(header, tostring(config.Title or "Kronos"), 11, Theme.Text, "bold")
    title.Position = UDim2.fromOffset(titleOffset, 0)
    title.Size = UDim2.fromOffset(hasLogo and 156 or 180, Metrics.Header)
    title.ZIndex = 29

    -- The objective keeps branding on one line. Subtitle data remains in the
    -- public API and is represented by the status/context surfaces instead of
    -- creating a second line that makes the header feel oversized.
    local subtitleText = tostring(config.Subtitle or config.SubTitle or "")
    local subtitle = makeText(header, subtitleText, 8, Theme.Muted)
    subtitle.Visible = false
    subtitle.Position = UDim2.fromOffset(titleOffset, 0)
    subtitle.Size = UDim2.fromOffset(hasLogo and 156 or 180, Metrics.Header)
    subtitle.ZIndex = 29

    local contextButton = create("TextButton", {
        Name = "HeaderContext",
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.63, 0, 0.5, 0),
        Size = UDim2.fromOffset(Metrics.HeaderContextWidth, Metrics.HeaderContextHeight),
        Visible = config.HeaderContext ~= false,
        ZIndex = 31,
        Parent = header,
    }) :: TextButton
    corner(contextButton, 4)
    local contextStroke = stroke(contextButton, Theme.Border, 0.82, 1, "Control")
    ThemeController:Bind(contextButton, "BackgroundColor3", "Surface2")
    ThemeController:Bind(contextStroke, "Color", "Border")
    local contextLabel = makeText(contextButton, "Overview", 9, Theme.SubText)
    contextLabel.Position = UDim2.fromOffset(10, 0)
    contextLabel.Size = UDim2.new(1, -34, 1, 0)
    contextLabel.ZIndex = 32
    local contextChevron = makeIcon(contextButton, { Icon = "chevron-down", IconSize = 9 }, "Muted")
    if contextChevron then
        contextChevron.AnchorPoint = Vector2.new(1, 0.5)
        contextChevron.Position = UDim2.new(1, -8, 0.5, 0)
        contextChevron.ZIndex = 32
    end

    local profileButton = makeUtilityButton(header, "user-round", 1)
    profileButton.Name = "SettingsButton"
    profileButton.BackgroundColor3 = Theme.Surface2
    profileButton.BackgroundTransparency = 0.62
    ThemeController:Bind(profileButton, "BackgroundColor3", "Surface2")

    -- The objective separates a compact navigation utility from the page
    -- selector. It remains a compatibility-safe visual affordance.
    local navigationButton = create("TextButton", {
        Name = "NavigationUtility",
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.74,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromOffset(Metrics.Sidebar + 8, math.floor(Metrics.Header * 0.5)),
        Size = UDim2.fromOffset(21, 21),
        ZIndex = 32,
        Parent = header,
    }) :: TextButton
    corner(navigationButton, 4)
    stroke(navigationButton, Theme.Border, nil, 1, "Control")
    ThemeController:Bind(navigationButton, "BackgroundColor3", "Surface2")
    local navigationIcon = makeIcon(navigationButton, { Icon = "panel-left", IconSize = 10 }, "Muted")
    if navigationIcon then
        navigationIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        navigationIcon.Position = UDim2.fromScale(0.5, 0.5)
        navigationIcon.ZIndex = 33
    end

    local presetsButton = makeUtilityButton(header, "save", 2)
    presetsButton.Name = "PresetsButton"
    presetsButton.Visible = config.ShowPresetsButton == true
    local minimizeButton = makeUtilityButton(header, "minus", 3)
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Visible = config.ShowMinimizeButton == true
    local closeButton = makeUtilityButton(header, "x", 4)
    closeButton.Name = "CloseButton"
    closeButton.Visible = config.ShowCloseButton == true

    self.ProfileButton = profileButton
    self.SettingsButton = profileButton
    self.NavigationButton = navigationButton
    self.PresetsButton = presetsButton
    self.HeaderTitle = title
    self.HeaderSubtitle = subtitle
    self.HeaderContext = contextButton
    self.HeaderContextLabel = contextLabel
    self.HeaderContextEnabled = config.HeaderContext ~= false
    self.Header = header

    if config.Draggable ~= false then
        DragController:Bind(self, dragSurface, self.Root, function(position)
            self.LastPosition = position
        end, self.DragOptions)
    end

    for _, button in ipairs({ profileButton, presetsButton, minimizeButton, closeButton }) do
        addConnection(
            self,
            button.MouseEnter:Connect(function()
                local accentUtility = button:GetAttribute("KronosAccentUtility") == true
                tween(button, { BackgroundTransparency = accentUtility and 0.02 or 0.16 }, Motion.HoverIn)
                local icon = button:FindFirstChild("UtilityIcon")
                if icon then
                    tween(icon, { ImageColor3 = accentUtility and Theme.White or Theme.Text }, Motion.HoverIn)
                end
            end)
        )
        addConnection(
            self,
            button.MouseLeave:Connect(function()
                local accentUtility = button:GetAttribute("KronosAccentUtility") == true
                tween(button, { BackgroundTransparency = accentUtility and 0.08 or 0.62 }, Motion.HoverOut)
                local icon = button:FindFirstChild("UtilityIcon")
                if icon then
                    tween(icon, { ImageColor3 = accentUtility and Theme.White or Theme.SubText }, Motion.HoverOut)
                end
            end)
        )
    end

    addConnection(self, contextButton.MouseEnter:Connect(function()
        tween(contextButton, { BackgroundTransparency = 0.38 }, Motion.HoverIn)
        tween(contextStroke, { Transparency = BorderController:Resolve(0.42, "Hover") }, Motion.HoverIn)
    end))
    addConnection(self, contextButton.MouseLeave:Connect(function()
        tween(contextButton, { BackgroundTransparency = 0.72 }, Motion.HoverOut)
        tween(contextStroke, { Transparency = BorderController:Resolve(0.82, "Control") }, Motion.HoverOut)
    end))
    addConnection(self, contextButton.Activated:Connect(function()
        self:_openHeaderContext()
    end))
    addConnection(self, profileButton.Activated:Connect(function()
        self:OpenProfile()
    end))
    addConnection(self, navigationButton.Activated:Connect(function()
        self:SetCompactNavigation(self.ExpandedNavigation)
    end))
    addConnection(self, presetsButton.Activated:Connect(function()
        self:OpenPresets()
    end))
    addConnection(self, minimizeButton.Activated:Connect(function()
        self:Minimize()
    end))
    addConnection(self, closeButton.Activated:Connect(function()
        self:SetVisible(false)
    end))
    self:_refreshHeaderContext()
end

function Window:SetTitle(value: any): AnyTable
    self.Title = tostring(value or "Kronos")
    if self.HeaderTitle and self.HeaderTitle.Parent then
        self.HeaderTitle.Text = self.Title
    end
    if self.StatusStrip and type(self.StatusStrip.Refresh) == "function" then
        self.StatusStrip:Refresh()
    end
    return self
end

function Window:SetSubtitle(value: any): AnyTable
    self.Subtitle = tostring(value or "")
    local subtitle = self.HeaderSubtitle
    local title = self.HeaderTitle
    if subtitle and subtitle.Parent then
        subtitle.Text = self.Subtitle
        subtitle.Visible = self.Subtitle ~= ""
    end
    if title and title.Parent then
        local xScale = title.Position.X.Scale
        local xOffset = title.Position.X.Offset
        local widthScale = title.Size.X.Scale
        local widthOffset = title.Size.X.Offset
        if self.Subtitle ~= "" then
            title.Position = UDim2.new(xScale, xOffset, 0, 6)
            title.Size = UDim2.new(widthScale, widthOffset, 0, 18)
        else
            title.Position = UDim2.new(xScale, xOffset, 0, 0)
            title.Size = UDim2.new(widthScale, widthOffset, 1, 0)
        end
    end
    if self.StatusStrip and type(self.StatusStrip.Refresh) == "function" then
        self.StatusStrip:Refresh()
    end
    return self
end

function Window:QueueSearch(value: string)
    self.SearchGeneration = (self.SearchGeneration or 0) + 1
    local generation = self.SearchGeneration
    self.PendingSearch = tostring(value or "")
    task.defer(function()
        if self.Destroyed or self.SearchGeneration ~= generation then
            return
        end
        local pending = self.PendingSearch or ""
        self.PendingSearch = nil
        self:ApplySearch(pending)
    end)
end

function Window:ApplySearch(value: string)
    dismissTooltip(self)
    PopupController:Close(self)
    self.ApplyingSearch = true
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
    self.ApplyingSearch = false
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
    local density = ResponsiveController:GetDensity(viewport)
    local densityChanged = self.Density ~= density
    self.Density = density
    ResponsiveController:Apply(self)
    NotificationController:ApplyResponsive()
    local function d(value: number): number
        return ResponsiveController:Scale(self, value)
    end
    local topLeftInset, bottomRightInset = guiInsets()
    local dragMargin = math.clamp(finiteNumber(self.DragOptions and self.DragOptions.DragMargin, 4), 0, 32)
    local safeWidth = math.max(viewport.X - topLeftInset.X - bottomRightInset.X - dragMargin * 2, 1)
    local safeHeight = math.max(viewport.Y - topLeftInset.Y - bottomRightInset.Y - dragMargin * 2, 1)
    local width, height, layoutMode = ResponsiveController:CalculateWindowSize(self, viewport, safeWidth, safeHeight)
    self.LayoutMode = layoutMode
    self.Width = width
    self.Height = height
    if self.LastPosition then
        local size, position = nearestEdgeLayout(self.Root, Vector2.new(width, height), self.DragOptions)
        self.Root.Size = size
        self.Root.Position = position
    else
        self.Root.Size = UDim2.fromOffset(width, height)
        -- The objective positions the shell against the full captured
        -- viewport. Safe-area ownership belongs to DragController:Clamp;
        -- folding the top inset into the center calculation pushed the shell
        -- visibly too low on mobile.
        self.Root.Position = UDim2.fromOffset(
            math.floor(viewport.X * TargetDesign.Window.Center.X + 0.5),
            math.floor(viewport.Y * TargetDesign.Window.Center.Y + 0.5)
        )
    end
    DragController:Clamp(self.Root, self.DragOptions)

    -- High-DPI mobile recordings can expose a small logical ViewportSize even
    -- when the physical shell has the same usable width as the reference.
    -- Decide navigation from shell geometry, then size it as a stable ratio.
    local expandedThreshold = layoutMode == "MobileLandscape" and 400 or 500
    local expanded = layoutMode ~= "Portrait"
        and width >= d(expandedThreshold)
        and self.ForceCompactNavigation ~= true
    local sidebarWidth: number
    if expanded then
        local minimumSidebar = math.max(d(142), 72)
        local maximumSidebar = math.max(d(Metrics.Sidebar), minimumSidebar)
        sidebarWidth = boundedClamp(
            math.floor(width * Metrics.SidebarRatio + 0.5),
            minimumSidebar,
            maximumSidebar
        )
    else
        -- V1.6 could call math.clamp with a 44px minimum and a 42px maximum
        -- at compact densities, aborting ApplyResponsive. Keep the bounds
        -- ordered for every viewport and custom density.
        local minimumSidebar = math.max(d(34), 28)
        local maximumSidebar = math.max(d(Metrics.CompactSidebar), minimumSidebar)
        sidebarWidth = boundedClamp(
            math.floor(width * Metrics.CompactSidebarRatio + 0.5),
            minimumSidebar,
            maximumSidebar
        )
    end
    local minimumHeader = 18
    local maximumHeader = math.max(d(Metrics.Header), minimumHeader)
    local headerHeight = boundedClamp(
        math.floor(height * Metrics.HeaderRatio + 0.5),
        minimumHeader,
        maximumHeader
    )
    self.ExpandedNavigation = expanded
    self.Sidebar.Size = UDim2.new(0, sidebarWidth, 1, -headerHeight)
    self.Content.Position = UDim2.fromOffset(sidebarWidth, headerHeight)
    self.Content.Size = UDim2.new(1, -sidebarWidth, 1, -headerHeight)
    self.Header.Size = UDim2.new(1, 0, 0, headerHeight)
    if self.HeaderContext then
        local headerContentWidth = math.max(width - sidebarWidth - d(48), 1)
        local desiredContextWidth = math.min(d(Metrics.HeaderContextWidth), math.max(headerContentWidth - d(90), d(126)))
        self.HeaderContext.Size = UDim2.fromOffset(desiredContextWidth, d(Metrics.HeaderContextHeight))
        self.HeaderContext.Position = UDim2.fromOffset(
            math.floor(sidebarWidth + d(28) + desiredContextWidth * 0.5 + 0.5),
            math.floor(headerHeight * 0.5 + 0.5)
        )
        self.HeaderContext.Visible = self.HeaderContextEnabled ~= false
            and layoutMode ~= "Portrait"
            and headerContentWidth >= d(220)
        if self.NavigationButton then
            self.NavigationButton.Position = UDim2.fromOffset(sidebarWidth + d(4), math.floor(headerHeight * 0.5 + 0.5))
            self.NavigationButton.Visible = layoutMode ~= "Portrait"
        end
    end
    self.SearchBox.PlaceholderText = expanded and "Search" or ""
    self.SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    if not expanded and self.SearchExpanded then
        self.SearchBox.Size = UDim2.fromOffset(
            math.min(d(180), width - d(64)),
            d(TargetDesign.Navigation.SearchHeight)
        )
    else
        self.SearchBox.Size = UDim2.new(
            1,
            -d(16),
            0,
            d(TargetDesign.Navigation.SearchHeight)
        )
    end
    self.SearchBox.Position = UDim2.fromOffset(d(8), d(8))
    self.SearchIcon.Visible = true
    for _, tab in ipairs(self.Tabs) do
        tab.TitleLabel.Visible = expanded or tab.IconLabel == nil
        if tab.IconLabel then
            tab.IconLabel.AnchorPoint = Vector2.new(0, 0.5)
            tab.IconLabel.Position = expanded and UDim2.new(0, d(12), 0.5, 0) or UDim2.new(0.5, 0, 0.5, 0)
            if not expanded then
                tab.IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            end
        end
        tab.Button.Size = UDim2.new(
            1,
            0,
            0,
            expanded and d(TargetDesign.Navigation.TabHeight)
                or d(TargetDesign.Navigation.CompactTabHeight)
        )
    end
    if self.SidebarFooter then
        self.SidebarFooter.Visible = self.ShowSidebarProfile == true
    end
    if self.SidebarFooterLabel then
        self.SidebarFooterLabel.Visible = self.ShowSidebarProfile == true and expanded
    end
    if self.NavigationScroll then
        local navigationTop = self.SearchBox.Visible and d(36) or d(8)
        local reservedBottom = self.ShowSidebarProfile and d(32) or d(6)
        self.NavigationScroll.Position = UDim2.fromOffset(d(8), navigationTop)
        self.NavigationScroll.Size = UDim2.new(
            1,
            -d(16),
            1,
            -(navigationTop + reservedBottom)
        )
    end
    local contentWidth = width - sidebarWidth
    local twoColumnThreshold = layoutMode == "MobileLandscape" and 340 or 430
    local minimumContentHeight = layoutMode == "MobileLandscape" and 230 or 260
    self.TwoColumn = layoutMode ~= "Portrait"
        and contentWidth >= d(twoColumnThreshold)
        and height - headerHeight >= d(minimumContentHeight)
    for _, tab in ipairs(self.Tabs) do
        tab:ApplyColumns(self.TwoColumn)
        SubtabController:Refresh(tab)
        if tab.ActiveSubTab then
            SubtabController:Reveal(tab, tab.ActiveSubTab)
        end
    end
    if self.SidePanel and self.SidePanel.Parent then
        local isPresets = self.SidePanelKind == "Presets"
        local isProfile = self.SidePanelKind == "Profile"
        local designPanelWidth = isPresets and 198 or (isProfile and 206 or 218)
        local panelWidth = math.min(d(designPanelWidth), math.max(width - d(70), d(184)))
        local openPosition: UDim2
        local closedPosition: UDim2
        if isPresets then
            local x = math.min(sidebarWidth + d(9), math.max(width - panelWidth - d(9), d(9)))
            openPosition = UDim2.fromOffset(x, headerHeight + d(6))
            closedPosition = UDim2.fromOffset(x, headerHeight - d(3))
        else
            openPosition = UDim2.new(1, -panelWidth - d(7), 0, headerHeight + d(6))
            closedPosition = UDim2.new(1, d(5), 0, headerHeight + d(6))
        end
        local availablePanelHeight = math.max(height - headerHeight - d(12), d(150))
        if isProfile or isPresets then
            local desiredHeight = d(isProfile and 220 or 236)
            self.SidePanel.Size = UDim2.fromOffset(
                panelWidth,
                math.min(desiredHeight, availablePanelHeight)
            )
        else
            self.SidePanel.Size = UDim2.new(0, panelWidth, 1, -(headerHeight + d(12)))
        end
        self.SidePanel.Position = openPosition
        self.SidePanelOpenPosition = openPosition
        self.SidePanelClosedPosition = closedPosition
    end
    local floatingDensity = ResponsiveController:GetFloatingDensity(viewport)
    for _, widget in ipairs(self.Widgets) do
        local widgetDensityChanged = widget.Density ~= nil
            and math.abs(finiteNumber(widget.Density, floatingDensity) - floatingDensity) > 0.001
        if widget.Reflow and (densityChanged or widgetDensityChanged) then
            widget:Reflow()
        elseif widget.Clamp then
            widget:Clamp()
        end
    end
    local defaultWidgetBottom: number? = nil
    local function placeDefault(widget: AnyTable?, topLeft: Vector2?, reserveSpace: boolean?)
        if
            not widget
            or widget.UserMoved
            or widget.CustomPosition
            or not widget.Root
            or not widget.Root.Parent
            or not topLeft
        then
            return
        end
        local root = widget.Root :: GuiObject
        local clamped = clampTopLeftForSize(root, topLeft, root.AbsoluteSize, widget.DragOptions)
        setAbsoluteTopLeft(root, clamped)
        if reserveSpace ~= false and widget.Visible ~= false then
            defaultWidgetBottom = math.max(defaultWidgetBottom or clamped.Y, clamped.Y + root.AbsoluteSize.Y)
        end
    end
    local status = self.StatusStrip
    local target = self.TargetList
    local keybinds = self.KeybindWidget
    local reopen = self.ReopenButton
    local gap = d(8)
    if status and status.Root and status.Root.Parent then
        local minimum, maximumEdge = viewportBounds(status.Root, status.DragOptions)
        placeDefault(status, Vector2.new(maximumEdge.X - status.Root.AbsoluteSize.X, minimum.Y))
    end
    if target and target.Root and target.Root.Parent then
        local minimum, maximumEdge = viewportBounds(target.Root, target.DragOptions)
        local targetY = minimum.Y
        if viewport.X < viewport.Y and status and status.Root and status.Root.Parent then
            targetY += status.Root.AbsoluteSize.Y + gap
        end
        local targetTravel = math.max(maximumEdge.X - minimum.X - target.Root.AbsoluteSize.X, 0)
        placeDefault(target, Vector2.new(minimum.X + targetTravel * 0.1, targetY))
    end
    if keybinds and keybinds.Root and keybinds.Root.Parent then
        local minimum, maximumEdge = viewportBounds(keybinds.Root, keybinds.DragOptions)
        local topLeft =
            Vector2.new(minimum.X + (maximumEdge.X - minimum.X) * 0.5 - keybinds.Root.AbsoluteSize.X * 0.5, minimum.Y)
        if viewport.X < viewport.Y then
            local y = minimum.Y
            if status and status.Root and status.Root.Parent then
                y += status.Root.AbsoluteSize.Y + gap
            end
            if target and target.Root and target.Root.Parent then
                y += target.Root.AbsoluteSize.Y + gap
            end
            topLeft = Vector2.new(minimum.X, y)
        end
        placeDefault(keybinds, topLeft)
    end
    if reopen and reopen.Root and reopen.Root.Parent then
        local minimum, maximumEdge = viewportBounds(reopen.Root, reopen.DragOptions)
        placeDefault(
            reopen,
            Vector2.new(maximumEdge.X - reopen.Root.AbsoluteSize.X, maximumEdge.Y - reopen.Root.AbsoluteSize.Y),
            false
        )
    end
    -- Floating widgets occupy the viewport independently in the objective.
    -- Only portrait mode stacks the shell below top widgets; desktop and
    -- landscape keep the target-derived center instead of being forced down.
    if not self.LastPosition and defaultWidgetBottom and layoutMode == "Portrait" then
        local minimum, maximumEdge = viewportBounds(self.Root, self.DragOptions)
        local centeredTop = minimum.Y + math.max(maximumEdge.Y - minimum.Y - self.Root.AbsoluteSize.Y, 0) * 0.54
        local maximumTop = maximumEdge.Y - self.Root.AbsoluteSize.Y
        local top = boundedClamp(math.max(centeredTop, defaultWidgetBottom + d(8)), minimum.Y, maximumTop)
        local horizontalTravel = math.max(maximumEdge.X - minimum.X - self.Root.AbsoluteSize.X, 0)
        local left = minimum.X + horizontalTravel * 0.5
        setAbsoluteTopLeft(self.Root, Vector2.new(left, top))
    end
    self:_refreshHeaderContext()
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

    self.VisibilityGeneration = (self.VisibilityGeneration or 0) + 1
    local generation = self.VisibilityGeneration
    self.Visible = nextVisible
    dismissTooltip(self)
    PopupController:Close(self)
    self:_closeSidePanel(true)

    local scale = self.WindowScale
    local shadowHost = self.ShadowHost
    local outerShadow = self.OuterShadow
    local innerShadow = self.InnerShadow

    if nextVisible then
        self.Root.Visible = true
        if shadowHost and shadowHost.Parent then
            shadowHost.Visible = true
        end
        self.Root.GroupTransparency = 1
        if scale and scale.Parent then
            scale.Scale = 0.992
            tween(scale, { Scale = 1 }, Motion.Restore, Enum.EasingStyle.Quart)
        end
        if outerShadow and outerShadow.Parent then
            outerShadow.BackgroundTransparency = 1
            tween(outerShadow, { BackgroundTransparency = self.ShadowOuterTransparency or 0.9 }, Motion.Restore)
        end
        if innerShadow and innerShadow.Parent then
            innerShadow.BackgroundTransparency = 1
            tween(innerShadow, { BackgroundTransparency = self.ShadowInnerTransparency or 0.8 }, Motion.Restore)
        end
        tween(self.Root, {
            GroupTransparency = 0,
        }, Motion.Restore, Enum.EasingStyle.Quart)
    else
        InputController:CancelPointer()
        DragController:Cancel(self.Root)
        ScrollbarController:Cancel()
        if scale and scale.Parent then
            tween(scale, { Scale = 0.992 }, Motion.Minimize, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        end
        if outerShadow and outerShadow.Parent then
            tween(outerShadow, { BackgroundTransparency = 1 }, Motion.Minimize)
        end
        if innerShadow and innerShadow.Parent then
            tween(innerShadow, { BackgroundTransparency = 1 }, Motion.Minimize)
        end
        tween(self.Root, {
            GroupTransparency = 1,
        }, Motion.Minimize, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(AnimationController:Duration(Motion.Minimize), function()
            if
                self.VisibilityGeneration == generation
                and not self.Visible
                and self.Root
                and self.Root.Parent
            then
                self.Root.Visible = false
                if shadowHost and shadowHost.Parent then
                    shadowHost.Visible = false
                end
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

function Window:SetTransparency(value: number): AnyTable
    self.Kronos:SetTransparency(value)
    return self
end

function Window:GetTransparency(): number
    return self.Kronos:GetTransparency()
end

function Window:SetAcrylic(enabled: boolean): AnyTable
    self.Kronos:SetAcrylic(enabled)
    return self
end

function Window:GetAcrylic(): boolean
    return self.Kronos:GetAcrylic()
end

function Window:SetAcrylicIntensity(value: number): AnyTable
    self.Kronos:SetAcrylicIntensity(value)
    return self
end

function Window:GetAcrylicIntensity(): number
    return self.Kronos:GetAcrylicIntensity()
end

function Window:SetBorderIntensity(value: number): AnyTable
    self.Kronos:SetBorderIntensity(value)
    return self
end

function Window:GetBorderIntensity(): number
    return self.Kronos:GetBorderIntensity()
end

function Window:SetSurfaceContrast(value: number): AnyTable
    self.Kronos:SetSurfaceContrast(value)
    return self
end

function Window:GetSurfaceContrast(): number
    return self.Kronos:GetSurfaceContrast()
end

function Window:SetReducedMotion(enabled: boolean): AnyTable
    self.Kronos:SetReducedMotion(enabled)
    return self
end

function Window:GetReducedMotion(): boolean
    return self.Kronos:GetReducedMotion()
end

function Window:SetAnimationIntensity(value: number): AnyTable
    self.Kronos:SetAnimationIntensity(value)
    return self
end

function Window:GetAnimationIntensity(): number
    return self.Kronos:GetAnimationIntensity()
end

function Window:SetAnimationsEnabled(enabled: boolean): AnyTable
    self.Kronos:SetAnimationsEnabled(enabled)
    return self
end

function Window:GetAnimationsEnabled(): boolean
    return self.Kronos:GetAnimationsEnabled()
end

function Window:SetNotificationMotion(enabled: boolean): AnyTable
    self.Kronos:SetNotificationMotion(enabled)
    return self
end

function Window:GetNotificationMotion(): boolean
    return self.Kronos:GetNotificationMotion()
end

function Window:SetPageTransitions(enabled: boolean): AnyTable
    self.Kronos:SetPageTransitions(enabled)
    return self
end

function Window:GetPageTransitions(): boolean
    return self.Kronos:GetPageTransitions()
end

function Window:SetDimStrength(value: number): AnyTable
    self.Kronos:SetDimStrength(value)
    return self
end

function Window:GetDimStrength(): number
    return self.Kronos:GetDimStrength()
end

Window.SetBackgroundDim = Window.SetDimStrength
Window.GetBackgroundDim = Window.GetDimStrength

function Window:ResetAppearance(): AnyTable
    self.Kronos:ResetAppearance()
    return self
end

function Window:SetCompactNavigation(compact: boolean): AnyTable
    self.ForceCompactNavigation = compact == true
    self:ApplyResponsive()
    return self
end

function Window:SetSearchBehavior(behavior: any): AnyTable
    local normalized = string.gsub(string.lower(tostring(behavior or "Live")), "[%s_%-]", "")
    self.SearchBehavior = (normalized == "clearonnavigation" or normalized == "clear")
        and "ClearOnNavigation"
        or "Live"
    return self
end

function Window:GetSearchBehavior(): string
    return self.SearchBehavior or "Live"
end

function Window:ResetInterfaceLayout(): AnyTable
    DragController:Cancel(self.Root)
    self.LastPosition = nil
    self.ForceCompactNavigation = false
    local viewport = viewportSize()
    local topLeftInset, bottomRightInset = guiInsets()
    local usableWidth = viewport.X - topLeftInset.X - bottomRightInset.X
    local usableHeight = viewport.Y - topLeftInset.Y - bottomRightInset.Y
    self.Root.Position = UDim2.fromOffset(
        math.floor(topLeftInset.X + usableWidth * 0.56 + 0.5),
        math.floor(topLeftInset.Y + usableHeight * 0.54 + 0.5)
    )
    self:ApplyResponsive()
    return self
end

function Window:ResetWidgetPositions(): AnyTable
    for _, widget in ipairs(self.Widgets) do
        DragController:Cancel(widget.Root)
        widget.UserMoved = false
        widget.CustomPosition = false
    end
    self:ApplyResponsive()
    return self
end

function Window:ResetPositions(): AnyTable
    DragController:Cancel(self.Root)
    self.LastPosition = nil
    self.ForceCompactNavigation = false
    local viewport = viewportSize()
    local topLeftInset, bottomRightInset = guiInsets()
    local usableWidth = viewport.X - topLeftInset.X - bottomRightInset.X
    local usableHeight = viewport.Y - topLeftInset.Y - bottomRightInset.Y
    self.Root.Position = UDim2.fromOffset(
        math.floor(topLeftInset.X + usableWidth * 0.56 + 0.5),
        math.floor(topLeftInset.Y + usableHeight * 0.54 + 0.5)
    )
    for _, widget in ipairs(self.Widgets) do
        DragController:Cancel(widget.Root)
        widget.UserMoved = false
        widget.CustomPosition = false
    end
    self:ApplyResponsive()
    return self
end

function Window:_closeSidePanel(immediate: boolean?)
    local utility = self.SettingsButton
    if utility and utility.Parent then
        utility:SetAttribute("KronosAccentUtility", false)
        tween(utility, {
            BackgroundColor3 = Theme.Surface2,
            BackgroundTransparency = 0.62,
        }, immediate and 0 or Motion.HoverOut)
        local utilityIcon = utility:FindFirstChild("UtilityIcon")
        if utilityIcon and utilityIcon:IsA("ImageLabel") then
            tween(utilityIcon, { ImageColor3 = Theme.SubText }, immediate and 0 or Motion.HoverOut)
        end
    end
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
        Motion.SettingsExit,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.In
    )
    if dim then
        tween(dim, { BackgroundTransparency = 1 }, Motion.SettingsExit)
    end
    task.delay(AnimationController:Duration(Motion.SettingsExit), function()
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
        Appearance = {
            Transparency = Kronos:GetTransparency(),
            Acrylic = Kronos:GetAcrylic(),
            AcrylicIntensity = Kronos:GetAcrylicIntensity(),
            BorderIntensity = Kronos:GetBorderIntensity(),
            SurfaceContrast = Kronos:GetSurfaceContrast(),
            ReducedMotion = Kronos:GetReducedMotion(),
            AnimationIntensity = Kronos:GetAnimationIntensity(),
            DimStrength = Kronos:GetDimStrength(),
        },
        Flags = flags,
    }
end

function Window:ApplyPreset(preset: AnyTable)
    if typeof(preset.Accent) == "Color3" then
        self:SetAccent(preset.Accent)
    end
    if type(preset.Appearance) == "table" then
        local appearance = preset.Appearance
        if appearance.Transparency ~= nil then
            self:SetTransparency(appearance.Transparency)
        end
        if appearance.Acrylic ~= nil then
            self:SetAcrylic(appearance.Acrylic)
        end
        if appearance.AcrylicIntensity ~= nil then
            self:SetAcrylicIntensity(appearance.AcrylicIntensity)
        end
        if appearance.BorderIntensity ~= nil then
            self:SetBorderIntensity(appearance.BorderIntensity)
        end
        if appearance.SurfaceContrast ~= nil then
            self:SetSurfaceContrast(appearance.SurfaceContrast)
        end
        if appearance.ReducedMotion ~= nil then
            self:SetReducedMotion(appearance.ReducedMotion)
        end
        if appearance.AnimationIntensity ~= nil then
            self:SetAnimationIntensity(appearance.AnimationIntensity)
        end
        if appearance.DimStrength ~= nil then
            self:SetDimStrength(appearance.DimStrength)
        end
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

function Window:_openSidePanel(kind: string, initialPage: string?)
    InputController:CancelPointer()
    DragController:Cancel()
    ScrollbarController:Cancel()
    self:_closeSidePanel(true)
    PopupController:Close(self)
    local utility = self.SettingsButton
    if utility and utility.Parent then
        utility:SetAttribute("KronosAccentUtility", true)
        tween(utility, {
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.08,
        }, Motion.SettingsEnter)
        local utilityIcon = utility:FindFirstChild("UtilityIcon")
        if utilityIcon and utilityIcon:IsA("ImageLabel") then
            tween(utilityIcon, { ImageColor3 = Theme.White }, Motion.SettingsEnter)
        end
    end
    local sideMaid = Maid.new()
    self.SideMaid = sideMaid
    local function d(value: number): number
        return ResponsiveController:Scale(self, value)
    end
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
    local designPanelWidth = kind == "Presets" and 198 or (kind == "Profile" and 206 or 218)
    local panelWidth = math.min(d(designPanelWidth), math.max(self.Width - d(70), d(184)))
    local headerHeight = self.Header and math.max(self.Header.AbsoluteSize.Y, 1) or d(Metrics.Header)
    local openPosition: UDim2
    local closedPosition: UDim2
    if kind == "Presets" then
        local navigationWidth = self.Sidebar and math.max(self.Sidebar.AbsoluteSize.X, 1)
            or d(self.ExpandedNavigation and Metrics.Sidebar or Metrics.CompactSidebar)
        local x = math.min(navigationWidth + d(9), math.max(self.Width - panelWidth - d(9), d(9)))
        openPosition = UDim2.fromOffset(x, headerHeight + d(6))
        closedPosition = UDim2.fromOffset(x, headerHeight - d(3))
    else
        openPosition = UDim2.new(1, -panelWidth - d(7), 0, headerHeight + d(6))
        closedPosition = UDim2.new(1, -panelWidth + d(5), 0, headerHeight + d(6))
    end
    local availablePanelHeight = math.max(self.Height - headerHeight - d(12), d(150))
    local compactPanelHeight = kind == "Profile" and d(220)
        or (kind == "Presets" and d(236) or nil)
    local panelSize = compactPanelHeight
        and UDim2.fromOffset(panelWidth, math.min(compactPanelHeight, availablePanelHeight))
        or UDim2.new(0, panelWidth, 1, -(headerHeight + d(12)))

    local panel = create("CanvasGroup", {
        Name = kind .. "Panel",
        BackgroundColor3 = Theme.ElevatedSurface,
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Position = closedPosition,
        Size = panelSize,
        ZIndex = 175,
        Parent = self.Main,
    }) :: CanvasGroup
    ThemeController:Bind(panel, "BackgroundColor3", "ElevatedSurface")
    corner(panel, 5)
    local panelStroke = stroke(
        panel,
        Theme.Border,
        nil,
        1,
        (kind == "Settings" or kind == "Profile") and "Settings" or "Popup"
    )
    ThemeController:Bind(panelStroke, "Color", "Border")
    AcrylicController:Register(panel, kind .. "Panel")
    self.SidePanel = panel
    self.SideDim = dim
    self.SidePanelKind = kind
    self.SidePanelOpenPosition = openPosition
    self.SidePanelClosedPosition = closedPosition

    local header = create("Frame", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.24,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Visible = kind ~= "Profile",
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
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(7, 6),
        Size = UDim2.fromOffset(20, 20),
        Visible = false,
        ZIndex = 178,
        Parent = header,
    }) :: TextButton
    corner(back, 5)
    local backIcon = makeIcon(back, { Icon = "chevron-left", IconSize = 10 }, "SubText")
    if backIcon then
        backIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        backIcon.Position = UDim2.fromScale(0.5, 0.5)
        backIcon.ZIndex = 179
    end
    local panelRootTitle = kind == "Presets" and "Presets" or (kind == "Profile" and "Profile" or "Settings")
    local headerTitle = makeText(header, panelRootTitle, 9, Theme.Text, "bold")
    headerTitle.Position = UDim2.fromOffset(12, 0)
    headerTitle.Size = UDim2.new(1, -54, 1, 0)
    headerTitle.ZIndex = 177
    local close = create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(20, 20),
        ZIndex = 178,
        Parent = header,
    }) :: TextButton
    local closeIcon = makeIcon(close, { Icon = "x", IconSize = 11 }, "Muted")
    if closeIcon then
        closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        closeIcon.Position = UDim2.fromScale(0.5, 0.5)
        closeIcon.ZIndex = 179
    end

    local content = create("ScrollingFrame", {
        Name = "PanelContent",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = kind == "Profile" and UDim2.fromOffset(0, 0) or UDim2.fromOffset(0, 32),
        Size = kind == "Profile" and UDim2.fromScale(1, 1) or UDim2.new(1, 0, 1, -32),
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
        Position = UDim2.fromOffset(7, 7),
        Size = UDim2.new(1, -16, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 177,
        Parent = content,
    }) :: Frame
    local pageLayout = list(page, Enum.FillDirection.Vertical, 3)
    sideMaid:Give(pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.fromOffset(0, pageLayout.AbsoluteContentSize.Y + 18)
    end))
    local pageMaid = Maid.new()
    sideMaid:Give(function()
        pageMaid:Cleanup()
    end)
    local currentPage = "root"
    local activeSettingsSlider: AnyTable? = nil
    local settingsPointerOwner = {}
    sideMaid:Give(function()
        InputController:CancelPointer(settingsPointerOwner)
        activeSettingsSlider = nil
    end)

    local function clearPage()
        self.CapturingToggleKey = nil
        InputController:CancelPointer(settingsPointerOwner)
        activeSettingsSlider = nil
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
            Size = UDim2.new(1, 0, 0, subtitleText and 28 or 17),
            ZIndex = 178,
            Parent = page,
        }) :: Frame
        local titleLabel = makeText(heading, titleText, 10, Theme.Text, "bold")
        titleLabel.Size = UDim2.new(1, 0, 0, 17)
        titleLabel.ZIndex = 179
        if subtitleText then
            local subLabel = makeText(heading, subtitleText, 8, Theme.Muted)
            subLabel.Position = UDim2.fromOffset(0, 16)
            subLabel.Size = UDim2.new(1, 0, 0, 18)
            subLabel.ZIndex = 179
        end
    end

    local function addRow(
        titleText: string,
        subtitleText: string?,
        callback: (() -> ())?,
        iconName: string?
    ): TextButton
        local rowHeight = kind == "Profile" and 22 or (subtitleText and 32 or 26)
        local row = create("TextButton", {
            BackgroundColor3 = Theme.Surface2,
            BackgroundTransparency = 0.64,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, rowHeight),
            ZIndex = 178,
            Parent = page,
        }) :: TextButton
        corner(row, 3)
        stroke(row, Theme.Border, 0.76, 1, "Control")
        local textOffset = 10
        if iconName then
            local rowIcon = makeIcon(row, { Icon = iconName, IconSize = 11 }, "SubText")
            if rowIcon then
                rowIcon.AnchorPoint = Vector2.new(0, 0.5)
                rowIcon.Position = UDim2.new(0, 8, 0.5, 0)
                rowIcon.ZIndex = 179
                textOffset = 24
            end
        end
        local titleLabel = makeText(row, titleText, 9, Theme.Text, "medium")
        titleLabel.Position = UDim2.fromOffset(textOffset, subtitleText and 3 or 0)
        titleLabel.Size = UDim2.new(1, -textOffset - 26, 0, subtitleText and 20 or rowHeight)
        titleLabel.ZIndex = 179
        if subtitleText then
            local subtitleLabel = makeText(row, subtitleText, 8, Theme.Muted)
            subtitleLabel.Position = UDim2.fromOffset(textOffset, 18)
            subtitleLabel.Size = UDim2.new(1, -textOffset - 26, 0, 16)
            subtitleLabel.ZIndex = 179
        end
        if callback then
            local chevron = makeIcon(row, { Icon = "chevron-right", IconSize = 10 }, "Muted")
            if chevron then
                chevron.AnchorPoint = Vector2.new(1, 0.5)
                chevron.Position = UDim2.new(1, -10, 0.5, 0)
                chevron.ZIndex = 179
            end
            pageMaid:Give(row.Activated:Connect(callback))
        end
        pageMaid:Give(row.MouseEnter:Connect(function()
            tween(row, { BackgroundTransparency = 0.46 }, Motion.Hover)
        end))
        pageMaid:Give(row.MouseLeave:Connect(function()
            tween(row, { BackgroundTransparency = 0.64 }, Motion.Hover)
        end))
        return row
    end

    local function addToggleRow(
        titleText: string,
        subtitleText: string?,
        getter: () -> boolean,
        setter: (boolean) -> (),
        iconName: string?
    ): TextButton
        local row = addRow(titleText, subtitleText, nil, iconName)
        local toggleBox = create("Frame", {
            BackgroundColor3 = Theme.Surface3,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(13, 13),
            ZIndex = 180,
            Parent = row,
        }) :: Frame
        ThemeController:Bind(toggleBox, "BackgroundColor3", "Surface3")
        corner(toggleBox, 3)
        local boxStroke = stroke(toggleBox, Theme.Border, nil, 1, "Control")
        ThemeController:Bind(boxStroke, "Color", "Border")
        local selectedFill = create("Frame", {
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            ZIndex = 181,
            Parent = toggleBox,
        }) :: Frame
        ThemeController:Bind(selectedFill, "BackgroundColor3", "Accent")
        corner(selectedFill, 3)
        local check = makeIcon(toggleBox, { Icon = "check", IconSize = 7 }, "White")
        if check then
            check.AnchorPoint = Vector2.new(0.5, 0.5)
            check.Position = UDim2.fromScale(0.5, 0.5)
            check.ImageTransparency = 1
            check.ZIndex = 182
        end
        local function refresh(immediate: boolean?)
            local enabled = getter()
            local fillTransparency = enabled and 0 or 1
            local checkTransparency = enabled and 0 or 1
            local borderRecord = BorderController.Records[boxStroke]
            if borderRecord then
                borderRecord.BaseTransparency = enabled and 0.46 or 0.64
                borderRecord.Role = enabled and "Focus" or "Control"
                boxStroke:SetAttribute("KronosBorderRole", borderRecord.Role)
            end
            local borderTransparency = BorderController:Resolve(enabled and 0.46 or 0.64, enabled and "Focus" or "Control")
            if immediate then
                selectedFill.BackgroundTransparency = fillTransparency
                boxStroke.Transparency = borderTransparency
                if check then
                    check.ImageTransparency = checkTransparency
                end
            else
                tween(selectedFill, { BackgroundTransparency = fillTransparency }, enabled and Motion.ToggleOn or Motion.ToggleOff)
                tween(boxStroke, { Transparency = borderTransparency }, enabled and Motion.ToggleOn or Motion.ToggleOff)
                if check then
                    tween(check, { ImageTransparency = checkTransparency }, enabled and Motion.ToggleOn or Motion.ToggleOff)
                end
            end
        end
        pageMaid:Give(row.Activated:Connect(function()
            setter(not getter())
            refresh(false)
        end))
        refresh(true)
        return row
    end

    local function addSliderRow(
        titleText: string,
        minimum: number,
        maximum: number,
        getter: () -> number,
        setter: (number) -> (),
        formatter: ((number) -> string)?,
        iconName: string?
    ): TextButton
        local row = addRow(titleText, nil, nil, iconName)
        row.Size = UDim2.new(1, 0, 0, 36)
        local valueLabel = makeText(row, "", 8, Theme.SubText, "bold")
        valueLabel.AnchorPoint = Vector2.new(1, 0)
        valueLabel.Position = UDim2.new(1, -8, 0, 0)
        valueLabel.Size = UDim2.fromOffset(52, 25)
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.ZIndex = 180
        local track = create("Frame", {
            BackgroundColor3 = Theme.Surface3,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(8, 26),
            Size = UDim2.new(1, -16, 0, 3),
            ZIndex = 180,
            Parent = row,
        }) :: Frame
        corner(track, 2)
        local fill = create("Frame", {
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(0, 1),
            ZIndex = 181,
            Parent = track,
        }) :: Frame
        corner(fill, 2)
        ThemeController:Bind(fill, "BackgroundColor3", "Accent")
        local knob = create("Frame", {
            BackgroundColor3 = Theme.White,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(8, 8),
            ZIndex = 182,
            Parent = track,
        }) :: Frame
        corner(knob, 4)
        ThemeController:Bind(knob, "BackgroundColor3", "White")
        local hitbox = create("TextButton", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Position = UDim2.fromOffset(5, 18),
            Size = UDim2.new(1, -10, 0, 16),
            ZIndex = 183,
            Parent = row,
        }) :: TextButton
        local range = math.max(maximum - minimum, 0.0001)
        local function refresh()
            local value = math.clamp(finiteNumber(getter(), minimum), minimum, maximum)
            local ratio = (value - minimum) / range
            fill.Size = UDim2.fromScale(ratio, 1)
            knob.Position = UDim2.fromScale(ratio, 0.5)
            valueLabel.Text = formatter and formatter(value) or formatNumber(value, 2)
        end
        local function update(pointerX: number)
            local ratio = math.clamp((pointerX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            setter(minimum + range * ratio)
            refresh()
        end
        pageMaid:Give(hitbox.InputBegan:Connect(function(input)
            if
                input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch
            then
                return
            end
            local active = { Update = update }
            if
                not InputController:BeginPointer(settingsPointerOwner, input, function(changedInput)
                    if activeSettingsSlider == active then
                        active.Update(changedInput.Position.X)
                    end
                end, function()
                    if activeSettingsSlider == active then
                        activeSettingsSlider = nil
                    end
                end)
            then
                return
            end
            activeSettingsSlider = active
            update(input.Position.X)
        end))
        refresh()
        return row
    end

    local showPage: (string) -> ()
    showPage = function(pageName: string)
        clearPage()
        page.Position = UDim2.fromOffset(7, 10)
        currentPage = pageName
        back.Visible = pageName ~= "root"
        headerTitle.Position = pageName ~= "root" and UDim2.fromOffset(38, 0) or UDim2.fromOffset(12, 0)
        if kind == "Presets" then
            headerTitle.Text = pageName == "root" and "Presets" or pageName
        elseif kind == "Profile" then
            headerTitle.Text = pageName == "root" and "Profile" or pageName
        else
            headerTitle.Text = pageName == "root" and "Settings" or pageName
        end

        if kind == "Profile" and pageName == "root" then
            local profileCard = create("Frame", {
                Name = "ProfileCard",
                BackgroundColor3 = Theme.Surface2,
                BackgroundTransparency = 0.7,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 44),
                ZIndex = 178,
                Parent = page,
            }) :: Frame
            corner(profileCard, 4)
            local profileStroke = stroke(profileCard, Theme.Border, nil, 1, "Control")
            ThemeController:Bind(profileCard, "BackgroundColor3", "Surface2")
            ThemeController:Bind(profileStroke, "Color", "Border")

            local avatar = create("ImageLabel", {
                Name = "Avatar",
                BackgroundColor3 = Theme.Surface3,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Image = "",
                Position = UDim2.fromOffset(8, 7),
                Size = UDim2.fromOffset(30, 30),
                ZIndex = 179,
                Parent = profileCard,
            }) :: ImageLabel
            corner(avatar, 15)
            local avatarStroke = stroke(avatar, Theme.Border, nil, 1, "Control")
            ThemeController:Bind(avatar, "BackgroundColor3", "Surface3")
            ThemeController:Bind(avatarStroke, "Color", "Border")

            local displayName = tostring(
                self.ProfileName
                    or (LocalPlayer and LocalPlayer.DisplayName)
                    or "Local Player"
            )
            local profileSubtitle = tostring(
                self.ProfileSubtitle
                    or (LocalPlayer and ("@" .. LocalPlayer.Name))
                    or "Local profile"
            )
            local fallback = makeText(
                avatar,
                string.upper(string.sub(displayName, 1, 1)),
                13,
                Theme.Text,
                "bold"
            )
            fallback.Size = UDim2.fromScale(1, 1)
            fallback.TextXAlignment = Enum.TextXAlignment.Center
            fallback.ZIndex = 180

            local displayLabel = makeText(profileCard, displayName, 10, Theme.Text, "bold")
            displayLabel.Position = UDim2.fromOffset(44, 6)
            displayLabel.Size = UDim2.new(1, -56, 0, 16)
            displayLabel.ZIndex = 179
            local profileMeta = makeText(profileCard, profileSubtitle, 8, Theme.Muted)
            profileMeta.Position = UDim2.fromOffset(44, 21)
            profileMeta.Size = UDim2.new(1, -56, 0, 14)
            profileMeta.ZIndex = 179

            if LocalPlayer and not self.ProfileName then
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

            addRow("Installed hotkeys", nil, function()
                self:_openSidePanel("Settings", "Hotkeys")
            end, "keyboard")
            addRow("Menu language", nil, nil, "languages")
            addRow("Watermark", nil, function()
                if self.StatusStrip then
                    self.StatusStrip:SetVisible(not self.StatusStrip.Visible)
                    self:_openSidePanel("Profile")
                end
            end, "badge-info")
            addRow("DPI Menu", nil, function()
                self:_openSidePanel("Settings", "Interface")
            end, "monitor-cog")
            addRow("Styles", nil, function()
                self:OpenPresets()
            end, "palette")
            addRow("Settings", nil, function()
                self:OpenSettings()
            end, "settings")
        elseif kind == "Settings" and pageName == "root" then
            local profile = create("Frame", {
                BackgroundColor3 = Theme.Surface2,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 52),
                ZIndex = 178,
                Parent = page,
            }) :: Frame
            corner(profile, 4)
            stroke(profile, Theme.Border, 0.62, 1)
            local avatar = create("ImageLabel", {
                BackgroundColor3 = Theme.Surface3,
                BorderSizePixel = 0,
                Image = "",
                Position = UDim2.fromOffset(8, 9),
                Size = UDim2.fromOffset(34, 34),
                ZIndex = 179,
                Parent = profile,
            }) :: ImageLabel
            corner(avatar, 17)
            local fallback = makeText(
                avatar,
                string.upper(string.sub(LocalPlayer and LocalPlayer.Name or "K", 1, 1)),
                13,
                Theme.Text,
                "bold"
            )
            fallback.Size = UDim2.fromScale(1, 1)
            fallback.TextXAlignment = Enum.TextXAlignment.Center
            fallback.ZIndex = 180
            local userName =
                makeText(profile, LocalPlayer and LocalPlayer.DisplayName or "Local Player", 11, Theme.Text, "bold")
            userName.Position = UDim2.fromOffset(50, 8)
            userName.Size = UDim2.new(1, -65, 0, 18)
            userName.ZIndex = 179
            local metadata =
                makeText(profile, LocalPlayer and ("@" .. LocalPlayer.Name) or "Profile unavailable", 9, Theme.Muted)
            metadata.Position = UDim2.fromOffset(50, 25)
            metadata.Size = UDim2.new(1, -65, 0, 16)
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
            end, "palette")
            addRow("Installed hotkeys", "Window and control bindings", function()
                showPage("Hotkeys")
            end, "keyboard")
            addRow("Interface behavior", "Navigation and notifications", function()
                showPage("Interface")
            end, "settings-2")
            addRow("Animation", "Motion intensity and reduced-motion behavior", function()
                showPage("Animation")
            end, "waves")
            addRow("Floating widgets", "Status, target, and keybind lists", function()
                showPage("Widgets")
            end, "panels-top-left")
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
            end, "rotate-ccw")
            addHeading("Material", "Layered transparency, borders, and motion")
            addSliderRow("Transparency", 0, 0.45, function()
                return self.Kronos:GetTransparency()
            end, function(value)
                self:SetTransparency(value)
            end, function(value)
                return tostring(math.floor(value * 100 + 0.5)) .. "%"
            end, "blend")
            addToggleRow("Acrylic surfaces", "Subtle layered tint without executor blur", function()
                return self.Kronos:GetAcrylic()
            end, function(enabled)
                self:SetAcrylic(enabled)
            end, "panels-top-left")
            addSliderRow("Acrylic intensity", 0, 1, function()
                return self.Kronos:GetAcrylicIntensity()
            end, function(value)
                self:SetAcrylicIntensity(value)
            end, function(value)
                return tostring(math.floor(value * 100 + 0.5)) .. "%"
            end, "sparkles")
            addSliderRow("Border intensity", 0.35, 1.5, function()
                return self.Kronos:GetBorderIntensity()
            end, function(value)
                self:SetBorderIntensity(value)
            end, function(value)
                return formatNumber(value, 2) .. "x"
            end, "square-dashed")
            addSliderRow("Surface contrast", 0.65, 1.4, function()
                return self.Kronos:GetSurfaceContrast()
            end, function(value)
                self:SetSurfaceContrast(value)
            end, function(value)
                return formatNumber(value, 2) .. "x"
            end, "contrast")
            addSliderRow("Panel dimming", 0, 0.85, function()
                return self.Kronos:GetDimStrength()
            end, function(value)
                self:SetDimStrength(value)
            end, function(value)
                return tostring(math.floor(value * 100 + 0.5)) .. "%"
            end, "moon")
            addRow("Reset appearance", "Restore reference material defaults", function()
                self:ResetAppearance()
                showPage("Theme")
            end, "rotate-ccw")
        elseif kind == "Settings" and pageName == "Animation" then
            addHeading("Motion", "Fast, interruptible transitions with explicit reduced-motion support")
            addToggleRow("Animations enabled", "Master switch for owned interface motion", function()
                return self.Kronos:GetAnimationsEnabled()
            end, function(enabled)
                self:SetAnimationsEnabled(enabled)
            end, "play")
            addToggleRow("Reduced motion", "Resolve transitions immediately", function()
                return self.Kronos:GetReducedMotion()
            end, function(enabled)
                self:SetReducedMotion(enabled)
            end, "accessibility")
            addSliderRow("Animation intensity", 0.35, 1.5, function()
                return self.Kronos:GetAnimationIntensity()
            end, function(value)
                self:SetAnimationIntensity(value)
            end, function(value)
                return formatNumber(value, 2) .. "x"
            end, "gauge")
            addToggleRow("Notification motion", "Animate notification entrance, reflow, and exit", function()
                return self.Kronos:GetNotificationMotion()
            end, function(enabled)
                self:SetNotificationMotion(enabled)
            end, "bell")
            addToggleRow("Page transitions", "Short opacity and three-pixel page movement", function()
                return self.Kronos:GetPageTransitions()
            end, function(enabled)
                self:SetPageTransitions(enabled)
            end, "panel-top-open")
            addRow("Motion profile", "Restrained reference timing · no overshoot", nil, "activity")
        elseif kind == "Settings" and pageName == "Hotkeys" then
            addHeading("Window hotkey", "Click the row, then press a keyboard key")
            local row = addRow("Toggle interface", tostring(self.ToggleKey.Name), nil, "keyboard")
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
                end, "command")
            end
        elseif kind == "Settings" and pageName == "Interface" then
            addHeading("Layout", "Compact geometry is preserved at every breakpoint")
            local navRow = addRow(
                "Compact navigation",
                self.ForceCompactNavigation and "Enabled" or "Automatic",
                nil,
                "panel-left"
            )
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
            addToggleRow("Clear search on navigation", "Otherwise filtering remains live and persistent", function()
                return self:GetSearchBehavior() == "ClearOnNavigation"
            end, function(enabled)
                self:SetSearchBehavior(enabled and "ClearOnNavigation" or "Live")
            end, "search")
            addRow("Notification preview", "Show the compact stacked notification", function()
                self:Notify({ Title = "Kronos", Content = "Interface settings are active.", Type = "success" })
            end, "bell")
            addToggleRow("Show Target List", "Independent draggable target panel", function()
                return self.TargetList ~= nil and self.TargetList.Visible ~= false
            end, function(enabled)
                if not self.TargetList and enabled then
                    self:CreateTargetList({ Title = "Target List" })
                elseif self.TargetList then
                    self.TargetList:SetVisible(enabled)
                end
            end, "crosshair")
            addToggleRow("Show Keybind List", "Live function, key and status rows", function()
                return self.KeybindWidget ~= nil and self.KeybindWidget.Visible ~= false
            end, function(enabled)
                if not self.KeybindWidget and enabled then
                    self:CreateKeybindList({ Title = "Keybind List" })
                elseif self.KeybindWidget then
                    self.KeybindWidget:SetVisible(enabled)
                end
            end, "keyboard")
            addToggleRow("Show Status Strip", "Compact runtime metrics", function()
                return self.StatusStrip ~= nil and self.StatusStrip.Visible ~= false
            end, function(enabled)
                if not self.StatusStrip and enabled then
                    self:CreateStatusStrip({ Title = "Kronos" })
                elseif self.StatusStrip then
                    self.StatusStrip:SetVisible(enabled)
                end
            end, "activity")
            addToggleRow("Show Mobile Reopen Button", "Restore access after minimizing", function()
                return self.ReopenButton ~= nil and self.ReopenButton.Visible ~= false
            end, function(enabled)
                if not self.ReopenButton and enabled then
                    self:CreateReopenButton({ Title = "Kronos" })
                elseif self.ReopenButton then
                    self.ReopenButton:SetVisible(enabled and not self.Visible)
                end
            end, "panel-top-open")
            addRow("Reset widget positions", "Restore independent floating-widget anchors", function()
                self:ResetWidgetPositions()
            end, "locate-fixed")
            addRow("Reset interface layout", "Restore target-derived window geometry and navigation", function()
                self:ResetInterfaceLayout()
            end, "rotate-ccw")
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
            addRow("Reset widget positions", "Restore default viewport anchors", function()
                self:ResetWidgetPositions()
            end, "locate-fixed")
        elseif kind == "Presets" then
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
                Text = "",
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.fromOffset(31, 31),
                ZIndex = 179,
                Parent = toolbar,
            }) :: TextButton
            corner(addPreset, 5)
            ThemeController:Bind(addPreset, "BackgroundColor3", "Accent")
            local addPresetIcon = makeIcon(addPreset, { Icon = "plus", IconSize = 13 }, "White")
            if addPresetIcon then
                addPresetIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                addPresetIcon.Position = UDim2.fromScale(0.5, 0.5)
                addPresetIcon.ZIndex = 180
            end

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
                                Text = "",
                                AutoButtonColor = false,
                                AnchorPoint = Vector2.new(1, 0.5),
                                Position = UDim2.new(1, -6, 0.5, 0),
                                Size = UDim2.fromOffset(25, 25),
                                ZIndex = 180,
                                Parent = presetRow,
                            }) :: TextButton
                            local deleteIcon = makeIcon(delete, { Icon = "trash-2", IconSize = 12 }, "Error")
                            if deleteIcon then
                                deleteIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                                deleteIcon.Position = UDim2.fromScale(0.5, 0.5)
                                deleteIcon.ZIndex = 181
                            end
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
                stroke(createPopup, Theme.Border, 0.25, 1, "Floating")
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
        ResponsiveController:RegisterTree(self, page, true)
        tween(page, { Position = UDim2.fromOffset(7, 7) }, Motion.PageEnter)
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
    showPage(initialPage or "root")
    ResponsiveController:RegisterTree(self, panel, true)
    local dimAmount = kind == "Settings"
        and math.min(Kronos.DimStrength, 0.52)
        or math.min(Kronos.DimStrength * 0.24, 0.1)
    tween(dim, { BackgroundTransparency = 1 - dimAmount }, Motion.SettingsEnter)
    tween(panel, { Position = openPosition, GroupTransparency = 0 }, Motion.SettingsEnter)
end

function Window:OpenProfile(): AnyTable
    self:_openSidePanel("Profile")
    return self
end

function Window:OpenSettingsPage(pageName: string): AnyTable
    self:_openSidePanel("Settings", pageName)
    return self
end

function Window:OpenSettings(): AnyTable
    self:_openSidePanel("Settings")
    return self
end

function Window:OpenPresets(): AnyTable
    self:_openSidePanel("Presets")
    return self
end

function FloatingWidgetController:Create(window: AnyTable, config: FloatingWidgetOptions): AnyTable
    local density = ResponsiveController:GetFloatingDensity()
    local designWidth = math.max(finiteNumber(config.Width or (config.Size and config.Size.X.Offset), 246), 40)
    local designHeight = math.max(finiteNumber(config.Height or (config.Size and config.Size.Y.Offset), 120), 40)
    local widget: AnyTable = {
        Window = window,
        Connections = {},
        Visible = config.Visible ~= false,
        Title = tostring(config.Title or "Widget"),
        Alive = true,
        Pinned = config.Pinned == true,
        CustomPosition = if config.CustomPosition ~= nil then config.CustomPosition == true else config.Position ~= nil,
        DesignWidth = designWidth,
        DesignHeight = designHeight,
        Density = density,
        DesiredWidth = math.floor(designWidth * density + 0.5),
        DesiredHeight = math.floor(designHeight * density + 0.5),
        DragOptions = {
            DragBounds = config.DragBounds or "Viewport",
            KeepFullyVisible = config.KeepFullyVisible ~= false,
            DragMargin = finiteNumber(config.DragMargin, 4),
            MinimumVisiblePixels = finiteNumber(config.MinimumVisiblePixels, 24),
            DragThreshold = finiteNumber(config.DragThreshold, 5),
        },
    }
    local root = create("CanvasGroup", {
        Name = config.Name or "FloatingWidget",
        BackgroundColor3 = Theme.ElevatedSurface,
        BackgroundTransparency = 0.14,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Position = scaledUDim2(config.Position or UDim2.fromOffset(14, 80), density),
        Size = UDim2.fromOffset(math.floor(designWidth * density + 0.5), math.floor(designHeight * density + 0.5)),
        ClipsDescendants = true,
        Visible = widget.Visible,
        ZIndex = config.ZIndex or 500,
        Parent = Kronos.Layers.Floating,
    }) :: CanvasGroup
    root:SetAttribute("KronosNoDensity", true)
    ThemeController:Bind(root, "BackgroundColor3", "ElevatedSurface")
    corner(root, 5)
    local rootStroke = stroke(root, Theme.Border, nil, 1, "FloatingWidget")
    ThemeController:Bind(rootStroke, "Color", "Border")
    AcrylicController:Register(root, "FloatingWidget")
    local header = create("Frame", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Active = true,
        Size = UDim2.new(1, 0, 0, 18),
        ZIndex = root.ZIndex + 1,
        Parent = root,
    }) :: Frame
    local marker = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 4),
        Size = UDim2.fromOffset(2, 10),
        ZIndex = root.ZIndex + 2,
        Parent = header,
    }) :: Frame
    corner(marker, 1)
    ThemeController:Bind(marker, "BackgroundColor3", "Accent")
    local titleOffset = 10
    local widgetIcon = makeIcon(header, config, "Accent")
    if widgetIcon then
        widgetIcon.AnchorPoint = Vector2.new(0, 0.5)
        widgetIcon.Position = UDim2.new(0, 8, 0.5, 0)
        widgetIcon.ZIndex = root.ZIndex + 2
        titleOffset = widgetIcon.Size.X.Offset + 13
    end
    local title = makeText(header, widget.Title, 8, Theme.Text, "bold")
    title.Position = UDim2.fromOffset(titleOffset, 0)
    local utilityWidth = (config.Pinnable == true and 18 or 0) + (config.Hideable == true and 18 or 0)
    title.Size = UDim2.new(1, -titleOffset - utilityWidth - 8, 1, 0)
    title.ZIndex = root.ZIndex + 2
    local pin = create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -22, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        Visible = config.Pinnable == true,
        ZIndex = root.ZIndex + 3,
        Parent = header,
    }) :: TextButton
    local pinIcon = makeIcon(pin, { Icon = "pin", IconSize = 11 }, widget.Pinned and "Accent" or "Muted")
    if pinIcon then
        pinIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        pinIcon.Position = UDim2.fromScale(0.5, 0.5)
        pinIcon.ZIndex = root.ZIndex + 4
    end
    local hide = create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -4, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        Visible = config.Hideable == true,
        ZIndex = root.ZIndex + 3,
        Parent = header,
    }) :: TextButton
    local hideIcon = makeIcon(hide, { Icon = "eye-off", IconSize = 12 }, "Muted")
    if hideIcon then
        hideIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        hideIcon.Position = UDim2.fromScale(0.5, 0.5)
        hideIcon.ZIndex = root.ZIndex + 4
    end
    ThemeController:Bind(header, "BackgroundColor3", "Surface2")
    local body = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 18),
        Size = UDim2.new(1, 0, 1, -18),
        ZIndex = root.ZIndex + 1,
        Parent = root,
    }) :: Frame
    widget.Root = root
    widget.Header = header
    widget.Body = body
    function widget:SetPinned(pinned: boolean): AnyTable
        self.Pinned = pinned == true
        if self.Pinned then
            DragController:Cancel(root)
        end
        if pinIcon then
            pinIcon.ImageColor3 = self.Pinned and Theme.Accent or Theme.Muted
        end
        return self
    end
    function widget:SetVisible(visible: boolean): AnyTable
        self.VisibilityGeneration = (self.VisibilityGeneration or 0) + 1
        local generation = self.VisibilityGeneration
        self.Visible = visible ~= false
        if self.Visible then
            local wasVisible = root.Visible
            root.Visible = true
            if not wasVisible then
                root.GroupTransparency = 1
            end
            tween(root, { GroupTransparency = 0 }, Motion.WidgetEnter)
        else
            DragController:Cancel(root)
            ScrollbarController:Cancel()
            tween(root, { GroupTransparency = 1 }, Motion.WidgetExit)
            task.delay(AnimationController:Duration(Motion.WidgetExit), function()
                if
                    self.Alive
                    and self.VisibilityGeneration == generation
                    and not self.Visible
                    and root.Parent
                then
                    root.Visible = false
                end
            end)
        end
        return self
    end
    function widget:Clamp()
        if root.Parent then
            local size, position =
                nearestEdgeLayout(root, Vector2.new(self.DesiredWidth, self.DesiredHeight), self.DragOptions)
            root.Size = size
            root.Position = position
            DragController:Clamp(root, self.DragOptions)
        end
    end
    function widget:Resize(width: number, height: number)
        self.DesignWidth = math.max(finiteNumber(width, self.DesignWidth), 40)
        self.DesignHeight = math.max(finiteNumber(height, self.DesignHeight), 40)
        self.Density = ResponsiveController:GetFloatingDensity()
        self.DesiredWidth = math.floor(self.DesignWidth * self.Density + 0.5)
        self.DesiredHeight = math.floor(self.DesignHeight * self.Density + 0.5)
        self.ResizeGeneration = (self.ResizeGeneration or 0) + 1
        local generation = self.ResizeGeneration
        local size, position =
            nearestEdgeLayout(root, Vector2.new(self.DesiredWidth, self.DesiredHeight), self.DragOptions)
        if DragController:IsDragging(root) then
            root.Size = size
            root.Position = position
            DragController:Clamp(root, self.DragOptions)
        else
            tween(root, { Size = size, Position = position }, Motion.Widget)
        end
        task.delay(AnimationController:Duration(Motion.Widget), function()
            if self.Alive and self.ResizeGeneration == generation and root.Parent then
                self:Clamp()
            end
        end)
    end
    function widget:Reflow()
        self.Density = ResponsiveController:GetFloatingDensity()
        self.DesiredWidth = math.floor(self.DesignWidth * self.Density + 0.5)
        self.DesiredHeight = math.floor(self.DesignHeight * self.Density + 0.5)
        self:Clamp()
    end
    function widget:Destroy()
        self.Alive = false
        DragController:Cancel(root)
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
        pin.Activated:Connect(function()
            widget:SetPinned(not widget.Pinned)
        end)
    )
    addConnection(
        widget,
        hide.Activated:Connect(function()
            widget:SetVisible(false)
        end)
    )
    if config.Draggable ~= false then
        DragController:Bind(widget, header, root, function()
            widget.UserMoved = true
        end, {
            DragBounds = widget.DragOptions.DragBounds,
            KeepFullyVisible = widget.DragOptions.KeepFullyVisible,
            DragMargin = widget.DragOptions.DragMargin,
            MinimumVisiblePixels = widget.DragOptions.MinimumVisiblePixels,
            DragThreshold = widget.DragOptions.DragThreshold,
            Ignore = { pin, hide },
            CanStart = function()
                return not widget.Pinned
            end,
        })
    end
    ResponsiveController:RegisterTree(window, root, true)
    addConnection(
        widget,
        root.DescendantAdded:Connect(function(descendant)
            task.defer(function()
                if widget.Alive and descendant.Parent and descendant:IsDescendantOf(root) then
                    ResponsiveController:RegisterTree(window, descendant)
                end
            end)
        end)
    )
    table.insert(window.Widgets, widget)
    table.insert(Kronos.Widgets, widget)
    widget:Clamp()
    return widget
end

function Window:CreateFloatingWidget(config: FloatingWidgetOptions?): AnyTable
    return FloatingWidgetController:Create(self, config or {})
end

Window.AddFloatingWidget = Window.CreateFloatingWidget

function Window:CreateTargetList(config: FloatingWidgetOptions?): AnyTable
    config = config or {}
    local widget = FloatingWidgetController:Create(self, {
        Name = "TargetList",
        Title = config.Name or config.Title or "Target list",
        Icon = config.Icon or "target",
        IconSize = config.IconSize,
        IconColor = config.IconColor,
        IconTransparency = config.IconTransparency,
        Size = config.Size or UDim2.fromOffset(TargetDesign.Widget.TargetWidth, TargetDesign.Widget.TargetHeight),
        Position = config.Position or UDim2.fromOffset(12, 12),
        CustomPosition = config.Position ~= nil,
        Visible = config.Visible ~= false,
        Draggable = config.Draggable,
        DragBounds = config.DragBounds,
        KeepFullyVisible = config.KeepFullyVisible,
        DragMargin = config.DragMargin,
        MinimumVisiblePixels = config.MinimumVisiblePixels,
        Pinned = config.Pinned,
        Pinnable = config.Pinnable ~= false,
        Hideable = config.Hideable == true,
    })
    local avatar = create("ImageLabel", {
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Image = "",
        Position = UDim2.fromOffset(6, 5),
        Size = UDim2.fromOffset(26, 26),
        ZIndex = 503,
        Parent = widget.Body,
    }) :: ImageLabel
    corner(avatar, 13)
    local fallback = makeText(avatar, "—", 12, Theme.Muted, "bold")
    fallback.Size = UDim2.fromScale(1, 1)
    fallback.TextXAlignment = Enum.TextXAlignment.Center
    fallback.ZIndex = 504
    local fallbackIcon = makeIcon(avatar, { Icon = "venetian-mask", IconSize = 15 }, "Text")
    if fallbackIcon then
        fallbackIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        fallbackIcon.Position = UDim2.fromScale(0.5, 0.5)
        fallbackIcon.Visible = false
        fallbackIcon.ZIndex = 505
    end
    local nameLabel = makeText(widget.Body, "No target", 9, Theme.Text, "bold")
    nameLabel.Position = UDim2.fromOffset(38, 2)
    nameLabel.Size = UDim2.new(1, -44, 0, 15)
    nameLabel.ZIndex = 503
    local healthLabel = makeText(widget.Body, "Waiting", 8, Theme.Muted)
    healthLabel.Position = UDim2.fromOffset(38, 16)
    healthLabel.Size = UDim2.new(1, -44, 0, 12)
    healthLabel.TextXAlignment = Enum.TextXAlignment.Right
    healthLabel.ZIndex = 503
    local healthTrack = create("Frame", {
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(38, 31),
        Size = UDim2.new(1, -44, 0, 2),
        ZIndex = 503,
        Parent = widget.Body,
    }) :: Frame
    ThemeController:Bind(healthTrack, "BackgroundColor3", "Surface3")
    corner(healthTrack, 1)
    local healthFill = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        ZIndex = 504,
        Parent = healthTrack,
    }) :: Frame
    corner(healthFill, 1)
    ThemeController:Bind(healthFill, "BackgroundColor3", "Accent")
    function widget:SetTarget(name: any, health: number?, maximumHealth: number?, userId: number?)
        local avatarImage: any = nil
        if type(name) == "table" then
            local data = name
            name = data.Name or data.DisplayName
            health = data.Health
            maximumHealth = data.MaxHealth or data.MaximumHealth
            userId = data.UserId
            avatarImage = data.Avatar or data.Image
        end
        self.TargetGeneration = (self.TargetGeneration or 0) + 1
        local generation = self.TargetGeneration
        if name == nil or tostring(name) == "" then
            nameLabel.Text = "No target"
            healthLabel.Text = "Waiting"
            fallback.Text = "—"
            fallback.Visible = true
            if fallbackIcon then
                fallbackIcon.Visible = false
            end
            avatar.Image = ""
            tween(healthFill, { Size = UDim2.fromScale(0, 1) }, Motion.Toggle)
            return
        end
        local current = math.max(finiteNumber(health, 0), 0)
        local maximum = math.max(finiteNumber(maximumHealth, 100), 1)
        local numericUserId = math.max(math.floor(finiteNumber(userId, 0)), 0)
        local ratio = math.clamp(current / maximum, 0, 1)
        nameLabel.Text = tostring(name)
        healthLabel.Text = string.format("%d/%d HP", math.floor(current + 0.5), math.floor(maximum + 0.5))
        fallback.Text = ""
        fallback.Visible = fallbackIcon == nil
        if fallbackIcon then
            fallbackIcon.Visible = true
        end
        avatar.Image = ""
        tween(healthFill, { Size = UDim2.fromScale(ratio, 1) }, Motion.Health)
        if avatarImage ~= nil and tostring(avatarImage) ~= "" then
            avatar.Image = type(avatarImage) == "number" and "rbxassetid://" .. tostring(avatarImage)
                or tostring(avatarImage)
            fallback.Visible = false
            if fallbackIcon then
                fallbackIcon.Visible = false
            end
        elseif numericUserId > 0 then
            task.spawn(function()
                local ok, image = pcall(
                    Players.GetUserThumbnailAsync,
                    Players,
                    numericUserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size100x100
                )
                if ok and widget.Alive and widget.TargetGeneration == generation and avatar.Parent then
                    avatar.Image = image
                    fallback.Visible = false
                    if fallbackIcon then
                        fallbackIcon.Visible = false
                    end
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

function Window:CreateKeybindList(config: FloatingWidgetOptions?): AnyTable
    config = config or {}
    local widget = FloatingWidgetController:Create(self, {
        Name = "KeybindList",
        Title = config.Name or config.Title or "Keybind list",
        Icon = config.Icon or "list-filter",
        IconSize = config.IconSize,
        IconColor = config.IconColor,
        IconTransparency = config.IconTransparency,
        Size = config.Size or UDim2.fromOffset(TargetDesign.Widget.KeybindWidth, TargetDesign.Widget.KeybindHeight),
        Position = config.Position or UDim2.new(0.5, -104, 0, 12),
        CustomPosition = config.Position ~= nil,
        Visible = config.Visible ~= false,
        Draggable = config.Draggable,
        DragBounds = config.DragBounds,
        KeepFullyVisible = config.KeepFullyVisible,
        DragMargin = config.DragMargin,
        MinimumVisiblePixels = config.MinimumVisiblePixels,
        Pinned = config.Pinned,
        Pinnable = config.Pinnable ~= false,
        Hideable = config.Hideable == true,
    })
    widget.ActiveOnly = config.ActiveOnly == true
    widget.ShowEmptyMessage = config.ShowEmptyMessage ~= false
    local columnHeader = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(7, 3),
        Size = UDim2.new(1, -14, 0, 15),
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
    headerLabel("STATUS", UDim2.new(0.78, 0, 0, 0), UDim2.new(0.22, 0, 1, 0), Enum.TextXAlignment.Right)
    local rows = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(7, 18),
        Size = UDim2.new(1, -14, 1, -21),
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
                and (not widget.ActiveOnly or keybind.Active == true)
            then
                count += 1
                local row = create("Frame", {
                    BackgroundColor3 = Theme.Surface2,
                    BackgroundTransparency = 0.55,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 17),
                    LayoutOrder = count,
                    ZIndex = 504,
                    Parent = rowHolder,
                }) :: Frame
                corner(row, 3)
                local function valueLabel(
                    text: string,
                    position: UDim2,
                    size: UDim2,
                    alignment: Enum.TextXAlignment,
                    color: Color3
                )
                    local label = makeText(row, text, 8, color, "medium")
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
                    tostring(keybind.Mode or "Toggle"),
                    UDim2.new(0.78, 0, 0, 0),
                    UDim2.new(0.22, -6, 1, 0),
                    Enum.TextXAlignment.Right,
                    keybind.Active and Theme.Accent or Theme.Muted
                )
                row.BackgroundTransparency = 1
                tween(row, { BackgroundTransparency = 0.64 }, Motion.KeybindRow)
            end
        end
        local bodyHeight = 15 + count * 16
        local finalHeight = math.clamp(bodyHeight + 18, TargetDesign.Widget.KeybindHeight, 112)
        widget:Resize(widget.DesignWidth, finalHeight)
        rows.Visible = true
        columnHeader.Visible = true
        if count == 0 and widget.ShowEmptyMessage then
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

function Window:CreateStatusStrip(config: FloatingWidgetOptions?): AnyTable
    config = config or {}
    local configuredFields = type(config.Fields) == "table" and config.Fields or {}
    local density = ResponsiveController:GetFloatingDensity()
    local designWidth = math.max(finiteNumber(config.Width, TargetDesign.Widget.StatusWidth), 92)
    local designHeight = math.max(finiteNumber(config.Height, TargetDesign.Widget.StatusHeight), 22)
    local widget: AnyTable = {
        Window = self,
        Connections = {},
        Visible = config.Visible ~= false,
        Alive = true,
        Title = config.Name or config.Title or "Status Strip",
        CustomPosition = config.Position ~= nil,
        Fields = {
            Kronos = configuredFields.Kronos ~= false,
            Context = configuredFields.Context == true,
            FPS = configuredFields.FPS ~= false,
            Ping = configuredFields.Ping == true,
            Time = configuredFields.Time ~= false,
        },
        DesignWidth = designWidth,
        DesignHeight = designHeight,
        Density = density,
        DesiredWidth = math.floor(designWidth * density + 0.5),
        DesiredHeight = math.floor(designHeight * density + 0.5),
        DragOptions = {
            DragBounds = config.DragBounds or "Viewport",
            KeepFullyVisible = config.KeepFullyVisible ~= false,
            DragMargin = finiteNumber(config.DragMargin, 4),
            MinimumVisiblePixels = finiteNumber(config.MinimumVisiblePixels, 24),
            DragThreshold = finiteNumber(config.DragThreshold, 5),
        },
    }
    local root = create("CanvasGroup", {
        Name = "StatusStrip",
        BackgroundColor3 = Theme.ElevatedSurface,
        BackgroundTransparency = 0.14,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = scaledUDim2(config.Position or UDim2.new(1, -12, 0, 12), density),
        Size = UDim2.fromOffset(math.floor(designWidth * density + 0.5), math.floor(designHeight * density + 0.5)),
        ClipsDescendants = true,
        Visible = widget.Visible,
        ZIndex = 540,
        Parent = Kronos.Layers.Floating,
    }) :: CanvasGroup
    root:SetAttribute("KronosNoDensity", true)
    ThemeController:Bind(root, "BackgroundColor3", "ElevatedSurface")
    corner(root, 4)
    stroke(root, Theme.Border, nil, 1, "FloatingWidget")
    AcrylicController:Register(root, "StatusStrip")
    local marker = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 6),
        Size = UDim2.fromOffset(2, 12),
        ZIndex = 541,
        Parent = root,
    }) :: Frame
    ThemeController:Bind(marker, "BackgroundColor3", "Accent")
    local statusIcon = makeIcon(root, {
        Icon = config.Icon or "layers-2",
        IconSize = config.IconSize or 10,
        IconColor = config.IconColor,
        IconTransparency = config.IconTransparency,
    }, "Accent")
    if statusIcon then
        statusIcon.AnchorPoint = Vector2.new(0, 0.5)
        statusIcon.Position = UDim2.new(0, 7, 0.5, 0)
        statusIcon.ZIndex = 543
    end
    local dragHandle = create("Frame", {
        BackgroundTransparency = 1,
        Active = true,
        Size = UDim2.new(1, -27, 1, 0),
        ZIndex = 542,
        Parent = root,
    }) :: Frame
    local fieldHolder = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(statusIcon and 24 or 8, 0),
        Size = UDim2.new(1, statusIcon and -54 or -38, 1, 0),
        ZIndex = 542,
        Parent = root,
    }) :: Frame
    local fieldLayout = list(fieldHolder, Enum.FillDirection.Horizontal, 0)
    fieldLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    local labels: AnyTable = {}
    local fieldDividers: AnyTable = {}
    local fieldOrder = { "Kronos", "Context", "FPS", "Ping", "Time" }
    local function addField(name: string, width: number, color: Color3)
        local label = makeText(fieldHolder, "", 9, color, "bold")
        label.Name = name
        label.Size = UDim2.fromOffset(width, 30)
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.ZIndex = 543
        labels[name] = label
        if name ~= "Kronos" then
            local divider = create("Frame", {
                BackgroundColor3 = Theme.Divider,
                BackgroundTransparency = 0.48,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(1, 10),
                ZIndex = 544,
                Parent = label,
            }) :: Frame
            ThemeController:Bind(divider, "BackgroundColor3", "Divider")
            fieldDividers[name] = divider
        end
    end
    local fieldWidths = { Kronos = 34, Context = 42, FPS = 30, Ping = 30, Time = 30 }
    addField("Kronos", fieldWidths.Kronos, Theme.Text)
    addField("Context", fieldWidths.Context, Theme.SubText)
    addField("FPS", fieldWidths.FPS, Theme.SubText)
    addField("Ping", fieldWidths.Ping, Theme.SubText)
    addField("Time", fieldWidths.Time, Theme.SubText)
    local menu = create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -3, 0.5, 0),
        Size = UDim2.fromOffset(25, 26),
        ZIndex = 544,
        Parent = root,
    }) :: TextButton
    local menuIcon = makeIcon(menu, { Icon = "ellipsis-vertical", IconSize = 13 }, "Muted")
    if menuIcon then
        menuIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        menuIcon.Position = UDim2.fromScale(0.5, 0.5)
        menuIcon.ZIndex = 545
    end
    widget.Root = root
    function widget:SetVisible(visible: boolean): AnyTable
        self.VisibilityGeneration = (self.VisibilityGeneration or 0) + 1
        local generation = self.VisibilityGeneration
        self.Visible = visible ~= false
        if self.Visible then
            local wasVisible = root.Visible
            root.Visible = true
            if not wasVisible then
                root.GroupTransparency = 1
            end
            tween(root, { GroupTransparency = 0 }, Motion.WidgetEnter)
        else
            DragController:Cancel(root)
            tween(root, { GroupTransparency = 1 }, Motion.WidgetExit)
            task.delay(AnimationController:Duration(Motion.WidgetExit), function()
                if
                    self.Alive
                    and self.VisibilityGeneration == generation
                    and not self.Visible
                    and root.Parent
                then
                    root.Visible = false
                end
            end)
        end
        return self
    end
    function widget:Clamp()
        local size, position =
            nearestEdgeLayout(root, Vector2.new(self.DesiredWidth, self.DesiredHeight), self.DragOptions)
        root.Size = size
        root.Position = position
        DragController:Clamp(root, self.DragOptions)
    end
    function widget:Resize(width: number, height: number)
        self.DesignWidth = math.max(finiteNumber(width, self.DesignWidth), 80)
        self.DesignHeight = math.max(finiteNumber(height, self.DesignHeight), 24)
        self.Density = ResponsiveController:GetFloatingDensity()
        self.DesiredWidth = math.floor(self.DesignWidth * self.Density + 0.5)
        self.DesiredHeight = math.floor(self.DesignHeight * self.Density + 0.5)
        local size, position =
            nearestEdgeLayout(root, Vector2.new(self.DesiredWidth, self.DesiredHeight), self.DragOptions)
        if DragController:IsDragging(root) then
            root.Size = size
            root.Position = position
            DragController:Clamp(root, self.DragOptions)
        else
            tween(root, { Size = size, Position = position }, Motion.Widget)
        end
    end
    function widget:Reflow()
        self.Density = ResponsiveController:GetFloatingDensity()
        self.DesiredWidth = math.floor(self.DesignWidth * self.Density + 0.5)
        self.DesiredHeight = math.floor(self.DesignHeight * self.Density + 0.5)
        self:Clamp()
    end
    function widget:Refresh()
        marker.BackgroundColor3 = Theme.Accent
        local brand = tostring(self.Window.Title or "Kronos")
        labels.Kronos.Text = string.upper(string.sub(brand, 1, 10))
        local context = tostring(self.Window.Subtitle or self.Window.ProfileSubtitle or "Lobby [1]")
        labels.Context.Text = string.sub(context, 1, 16)
    end
    function widget:Destroy()
        self.Alive = false
        DragController:Cancel(root)
        disconnectAll(self)
        if root.Parent then
            ThemeController:UnbindTree(root)
            root:Destroy()
        end
        removeArrayValue(self.Window.Widgets, self)
        removeArrayValue(Kronos.Widgets, self)
    end
    local function layoutFields()
        local width = 30
        local hasVisibleField = false
        for _, name in ipairs(fieldOrder) do
            local label = labels[name]
            label.Visible = widget.Fields[name] == true
            if fieldDividers[name] then
                fieldDividers[name].Visible = label.Visible and hasVisibleField
            end
            if label.Visible then
                hasVisibleField = true
                width += fieldWidths[name]
            end
        end
        widget:Resize(width, widget.DesignHeight)
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
                Size = UDim2.fromOffset(142, 158),
                Visible = false,
                ZIndex = 760,
            }) :: CanvasGroup
            corner(popup, Metrics.PopupRadius)
            stroke(popup, Theme.Border, 0.26, 1, "Floating")
            padding(popup, 6, 6, 6, 6)
            local popupLayout = list(popup, Enum.FillDirection.Vertical, 3)
            local popupMaid = PopupController:Open(self, popup, menu, 5)
            for _, name in ipairs({ "Kronos", "Context", "FPS", "Ping", "Time" }) do
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
                local check = makeIcon(choice, { Icon = "check", IconSize = 10 }, "Accent")
                if check then
                    check.AnchorPoint = Vector2.new(1, 0.5)
                    check.Position = UDim2.new(1, -9, 0.5, 0)
                    check.Visible = widget.Fields[name]
                    check.ZIndex = 763
                end
                popupMaid:Give(choice.Activated:Connect(function()
                    widget.Fields[name] = not widget.Fields[name]
                    if check then
                        check.Visible = widget.Fields[name]
                    end
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
    if config.Draggable ~= false then
        DragController:Bind(widget, dragHandle, root, function()
            widget.UserMoved = true
        end, widget.DragOptions)
    end
    ResponsiveController:RegisterTree(self, root, true)
    table.insert(self.Widgets, widget)
    table.insert(Kronos.Widgets, widget)
    layoutFields()
    widget:Refresh()
    local sampledFrames = 0
    local sampleStartedAt = os.clock()
    addConnection(
        widget,
        RunService.Heartbeat:Connect(function()
            if
                widget.Alive
                and widget.Visible
                and root.Visible
                and widget.Fields.FPS
            then
                sampledFrames += 1
            end
        end)
    )
    task.spawn(function()
        while widget.Alive and root.Parent do
            task.wait(0.75)
            if not widget.Alive or not root.Parent then
                break
            end
            if not widget.Visible or not root.Visible then
                sampledFrames = 0
                sampleStartedAt = os.clock()
                continue
            end
            local now = os.clock()
            if widget.Fields.FPS then
                local elapsed = math.max(now - sampleStartedAt, 1 / 240)
                local fps = math.clamp(math.floor(sampledFrames / elapsed + 0.5), 0, 999)
                labels.FPS.Text = tostring(fps) .. "FPS"
            end
            sampledFrames = 0
            sampleStartedAt = now
            local brand = tostring(self.Title or "Kronos")
            labels.Kronos.Text = string.upper(string.sub(brand, 1, 10))
            if widget.Fields.Context then
                local context = tostring(self.Subtitle or self.ProfileSubtitle or "Lobby [1]")
                labels.Context.Text = string.sub(context, 1, 16)
            end
            if widget.Fields.Ping then
                local ping = "—"
                pcall(function()
                    local network = (Stats :: any).Network
                    local item = network and network.ServerStatsItem and network.ServerStatsItem["Data Ping"]
                    if item then
                        local numericPing = tonumber(item:GetValue())
                        if numericPing then
                            ping = tostring(math.clamp(math.floor(numericPing + 0.5), 0, 999)) .. "PING"
                        else
                            ping = tostring(item:GetValueString())
                        end
                    end
                end)
                labels.Ping.Text = ping
            end
            if widget.Fields.Time then
                labels.Time.Text = os.date("%H:%M")
            end
        end
    end)
    self.StatusStrip = widget
    return widget
end

function Window:CreateReopenButton(config: FloatingWidgetOptions?): AnyTable
    config = config or {}
    local density = self.Density or ResponsiveController:GetDensity()
    local configuredSize = typeof(config.Size) == "UDim2" and config.Size.X.Offset or config.Size
    local designSize = math.max(finiteNumber(configuredSize, TargetDesign.Widget.ReopenSize), 28)
    local widget: AnyTable = {
        Window = self,
        Connections = {},
        Visible = false,
        Alive = true,
        Title = "Reopen Button",
        DesignSize = designSize,
        CustomPosition = config.Position ~= nil,
        DragOptions = {
            DragBounds = config.DragBounds or "Viewport",
            KeepFullyVisible = config.KeepFullyVisible ~= false,
            DragMargin = finiteNumber(config.DragMargin, 4),
            MinimumVisiblePixels = finiteNumber(config.MinimumVisiblePixels, 24),
            DragThreshold = finiteNumber(config.DragThreshold, 5),
        },
    }
    local root = create("CanvasGroup", {
        Name = "KronosReopen",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = scaledUDim2(config.Position or UDim2.new(1, -44, 1, -44), density),
        Size = UDim2.fromOffset(math.floor(designSize * density + 0.5), math.floor(designSize * density + 0.5)),
        Visible = false,
        ZIndex = 900,
        Parent = Kronos.Layers.Mobile,
    }) :: CanvasGroup
    root:SetAttribute("KronosNoDensity", true)
    local button = create("TextButton", {
        BackgroundColor3 = Theme.ElevatedSurface,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(designSize, designSize),
        ZIndex = 901,
        Parent = root,
    }) :: TextButton
    ThemeController:Bind(button, "BackgroundColor3", "Text")
    corner(button, math.floor(designSize * 0.5 + 0.5))
    local buttonStroke = stroke(button, Theme.Border, 0.34, 1, "ReopenButton")
    ThemeController:Bind(buttonStroke, "Color", "Border")
    local reopenIcon = makeIcon(button, {
        Icon = config.Icon or "layers-2",
        IconSize = config.IconSize or 15,
        IconColor = config.IconColor,
        IconTransparency = config.IconTransparency,
    }, "Background")
    if reopenIcon then
        reopenIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        reopenIcon.Position = UDim2.fromScale(0.5, 0.5)
        reopenIcon.ZIndex = 902
    end
    widget.Root = root
    function widget:SetVisible(visible: boolean): AnyTable
        self.VisibilityGeneration = (self.VisibilityGeneration or 0) + 1
        local generation = self.VisibilityGeneration
        self.Visible = visible ~= false
        if self.Visible then
            local wasVisible = root.Visible
            root.Visible = true
            if not wasVisible then
                root.GroupTransparency = 1
            end
            tween(root, { GroupTransparency = 0 }, Motion.Restore)
        else
            DragController:Cancel(root)
            tween(root, { GroupTransparency = 1 }, Motion.Minimize)
            task.delay(AnimationController:Duration(Motion.Minimize), function()
                if
                    self.Alive
                    and self.VisibilityGeneration == generation
                    and not self.Visible
                    and root.Parent
                then
                    root.Visible = false
                end
            end)
        end
        return self
    end
    function widget:Clamp()
        local size = ResponsiveController:Scale(self.Window, self.DesignSize)
        local nextSize, nextPosition = nearestEdgeLayout(root, Vector2.new(size, size), self.DragOptions)
        root.Size = nextSize
        root.Position = nextPosition
        DragController:Clamp(root, self.DragOptions)
    end
    function widget:Reflow()
        self:Clamp()
    end
    function widget:Destroy()
        self.Alive = false
        DragController:Cancel(root)
        disconnectAll(self)
        if root.Parent then
            ThemeController:UnbindTree(root)
            root:Destroy()
        end
        removeArrayValue(self.Window.Widgets, self)
        removeArrayValue(Kronos.Widgets, self)
    end
    local moved = false
    local pressedAt = 0
    addConnection(
        widget,
        button.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                moved = false
                pressedAt = os.clock()
                local pressedSize = ResponsiveController:Scale(self, designSize - 4)
                tween(button, { Size = UDim2.fromOffset(pressedSize, pressedSize) }, Motion.Press)
            end
        end)
    )
    DragController:Bind(widget, button, root, function()
        moved = true
        widget.UserMoved = true
    end, {
        DragBounds = widget.DragOptions.DragBounds,
        KeepFullyVisible = widget.DragOptions.KeepFullyVisible,
        DragMargin = widget.DragOptions.DragMargin,
        MinimumVisiblePixels = widget.DragOptions.MinimumVisiblePixels,
        DragThreshold = widget.DragOptions.DragThreshold,
        Ended = function()
            local size = ResponsiveController:Scale(self, designSize)
            tween(button, { Size = UDim2.fromOffset(size, size) }, Motion.Press)
        end,
    })
    addConnection(
        widget,
        button.Activated:Connect(function()
            if moved then
                moved = false
                return
            end
            if os.clock() - pressedAt <= 0.65 then
                self:SetVisible(true)
            end
        end)
    )
    addConnection(
        widget,
        button.MouseEnter:Connect(function()
            tween(button, { BackgroundColor3 = Theme.White, BackgroundTransparency = 0 }, Motion.Hover)
        end)
    )
    addConnection(
        widget,
        button.MouseLeave:Connect(function()
            tween(button, { BackgroundColor3 = Theme.Text, BackgroundTransparency = 0.02 }, Motion.Hover)
        end)
    )
    ResponsiveController:RegisterTree(self, root, true)
    table.insert(self.Widgets, widget)
    table.insert(Kronos.Widgets, widget)
    self.ReopenButton = widget
    return widget
end

function Window:_handleInputBegan(input: InputObject, processed: boolean)
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
        if not keybind.Disabled and keybind.Value ~= "NONE" and InputController.Matches(input, keybind.Value) then
            if keybind.Mode == "Hold" then
                keybind:SetActive(true)
            elseif keybind.Mode == "Toggle" then
                keybind:SetActive(not keybind.Active)
            elseif keybind.Mode == "Always" then
                keybind:SetActive(true)
            end
        end
    end
end

function Window:_handleInputEnded(input: InputObject)
    for _, keybind in ipairs(self.Keybinds) do
        if keybind.Mode == "Hold" and keybind.Active and InputController.Matches(input, keybind.Value) then
            keybind:SetActive(false)
        end
    end
end

function Window:_bindInput()
    InputController:Initialize()
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
        local function refreshSections(owner: AnyTable)
            for _, section in ipairs(owner.Sections) do
                section.Instance.BackgroundColor3 = Theme.Surface
                for _, control in ipairs(section.Controls) do
                    if type(control.RefreshView) == "function" then
                        control:RefreshView()
                    end
                end
            end
        end
        refreshSections(tab)
        for _, subTab in ipairs(tab.SubTabs) do
            refreshSections(subTab)
            tab:_setSubTabVisual(subTab, tab.ActiveSubTab == subTab)
        end
        if tab.HasSubTabs and tab.SubTabSelectors[tab] then
            tab:_setSubTabVisual(tab, tab.ActiveSubTab == tab)
        end
    end
    for _, widget in ipairs(self.Widgets) do
        if type(widget.Refresh) == "function" then
            widget:Refresh()
        end
        if type(widget.SetPinned) == "function" then
            widget:SetPinned(widget.Pinned)
        end
    end
end

function Window:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    self.VisibilityGeneration = (self.VisibilityGeneration or 0) + 1
    self.SearchGeneration = (self.SearchGeneration or 0) + 1
    self.PendingSearch = nil
    self.CapturingToggleKey = nil
    if self.ListeningKeybind and type(self.ListeningKeybind.CancelListening) == "function" then
        self.ListeningKeybind:CancelListening()
    end
    self.ListeningKeybind = nil
    DragController:Cancel(self.Root)
    AnimationController:Cancel(self.Root)
    if self.WindowScale then
        AnimationController:Cancel(self.WindowScale)
    end
    if self.OuterShadow then
        AnimationController:Cancel(self.OuterShadow)
    end
    if self.InnerShadow then
        AnimationController:Cancel(self.InnerShadow)
    end
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
    if self.ShadowHost and self.ShadowHost.Parent then
        ThemeController:UnbindTree(self.ShadowHost)
        self.ShadowHost:Destroy()
    end
    removeArrayValue(Kronos.Windows, self)
end

local function buildWindow(library: AnyTable, config: WindowConfig): AnyTable
    library:_ensureGui()
    if typeof(config.Accent) == "Color3" then
        library:SetAccent(config.Accent)
    end
    if config.Transparency ~= nil then
        library:SetTransparency(config.Transparency)
    end
    if config.Acrylic ~= nil then
        library:SetAcrylic(config.Acrylic)
    end
    if config.AcrylicIntensity ~= nil then
        library:SetAcrylicIntensity(config.AcrylicIntensity)
    end
    if config.BorderIntensity ~= nil then
        library:SetBorderIntensity(config.BorderIntensity)
    end
    if config.SurfaceContrast ~= nil then
        library:SetSurfaceContrast(config.SurfaceContrast)
    end
    if config.ReducedMotion ~= nil then
        library:SetReducedMotion(config.ReducedMotion)
    end
    if config.AnimationIntensity ~= nil then
        library:SetAnimationIntensity(config.AnimationIntensity)
    end
    if config.DimStrength ~= nil then
        library:SetDimStrength(config.DimStrength)
    end
    local configuredWidth = tonumber(config.Width)
        or (config.Size and config.Size.X.Offset > 0 and config.Size.X.Offset)
    local configuredHeight = tonumber(config.Height)
        or (config.Size and config.Size.Y.Offset > 0 and config.Size.Y.Offset)
    local baseWidth = configuredWidth or Metrics.Window.X
    local baseHeight = configuredHeight or Metrics.Window.Y
    baseWidth = math.max(finiteNumber(baseWidth, Metrics.Window.X), 280)
    baseHeight = math.max(finiteNumber(baseHeight, Metrics.Window.Y), 300)
    local viewport = viewportSize()
    local density = ResponsiveController:GetDensity(viewport)
    local topLeftInset, bottomRightInset = guiInsets()
    local dragMargin = math.clamp(finiteNumber(config.DragMargin, 4), 0, 32)
    local initialSafeWidth = math.max(viewport.X - topLeftInset.X - bottomRightInset.X - dragMargin * 2, 1)
    local initialSafeHeight = math.max(viewport.Y - topLeftInset.Y - bottomRightInset.Y - dragMargin * 2, 1)
    local sizingState = {
        BaseWidth = baseWidth,
        BaseHeight = baseHeight,
        HasExplicitWidth = configuredWidth ~= nil,
        HasExplicitHeight = configuredHeight ~= nil,
    }
    local initialWidth, initialHeight, layoutMode =
        ResponsiveController:CalculateWindowSize(sizingState, viewport, initialSafeWidth, initialSafeHeight)
    local window = setmetatable({
        Kronos = library,
        BaseWidth = baseWidth,
        BaseHeight = baseHeight,
        HasExplicitWidth = configuredWidth ~= nil,
        HasExplicitHeight = configuredHeight ~= nil,
        Width = initialWidth,
        Height = initialHeight,
        Density = density,
        LayoutMode = layoutMode,
        Tabs = {},
        Keybinds = {},
        Widgets = {},
        Connections = {},
        Visible = true,
        Destroyed = false,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        ForceCompactNavigation = config.CompactNavigation == true,
        SearchBehavior = (
            string.gsub(string.lower(tostring(config.SearchBehavior or "")), "[%s_%-]", "")
                == "clearonnavigation"
        ) and "ClearOnNavigation" or "Live",
        TwoColumn = layoutMode ~= "Portrait" and initialWidth >= 730 * density and initialHeight >= 340 * density,
        Presets = {},
        Title = tostring(config.Title or "Kronos"),
        Subtitle = tostring(config.Subtitle or config.SubTitle or ""),
        ProfileName = config.ProfileName,
        ProfileSubtitle = config.ProfileSubtitle,
        ShowSidebarProfile = config.ShowSidebarProfile == true,
        DragOptions = {
            DragBounds = config.DragBounds or "Viewport",
            KeepFullyVisible = config.KeepFullyVisible ~= false,
            DragMargin = dragMargin,
            MinimumVisiblePixels = finiteNumber(config.MinimumVisiblePixels, 24),
            DragThreshold = 5,
        },
    }, Window)
    -- Match the objective's normalized full-viewport center. The subsequent
    -- drag clamp is still authoritative for device safe areas.
    local centerX = viewport.X * TargetDesign.Window.Center.X
    local centerY = viewport.Y * TargetDesign.Window.Center.Y
    local initialPosition = UDim2.fromOffset(math.floor(centerX + 0.5), math.floor(centerY + 0.5))
    local initialSize = UDim2.fromOffset(initialWidth, initialHeight)

    -- CanvasGroup always clips descendants in Roblox. V1.6 attempted to
    -- disable clipping on the root, which emitted a runtime warning and cut
    -- off the exterior shadow. A sibling host now owns all out-of-bounds depth
    -- while the CanvasGroup remains the animation and content owner.
    local shadowHost = create("Frame", {
        Name = "WindowShadowHost",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = initialPosition,
        Size = initialSize,
        ClipsDescendants = false,
        ZIndex = 8,
        Parent = library.Layers.Main,
    }) :: Frame
    shadowHost:SetAttribute("KronosNoDensity", true)

    local root = create("CanvasGroup", {
        Name = "Window",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = initialPosition,
        Size = initialSize,
        ClipsDescendants = true,
        ZIndex = 10,
        Parent = library.Layers.Main,
    }) :: CanvasGroup
    root:SetAttribute("KronosNoDensity", true)

    local outerShadow = create("Frame", {
        Name = "OuterShadow",
        BackgroundColor3 = Theme.Shadow,
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-7, -2),
        Size = UDim2.new(1, 14, 1, 16),
        ZIndex = 8,
        Parent = shadowHost,
    }) :: Frame
    corner(outerShadow, Metrics.ShellRadius + 5)
    local shadow = create("Frame", {
        Name = "InnerShadow",
        BackgroundColor3 = Theme.Shadow,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-2, 3),
        Size = UDim2.new(1, 4, 1, 7),
        ZIndex = 9,
        Parent = shadowHost,
    }) :: Frame
    corner(shadow, Metrics.ShellRadius + 2)
    local main = create("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 10,
        Parent = root,
    }) :: Frame
    ThemeController:Bind(main, "BackgroundColor3", "Background")
    corner(main, Metrics.ShellRadius)
    local mainStroke = stroke(main, Theme.Border, nil, 1, "MainShellOuter")
    ThemeController:Bind(mainStroke, "Color", "Border")
    local innerStroke = stroke(main, Theme.InnerHighlight, nil, 1, "MainShellInner")
    ThemeController:Bind(innerStroke, "Color", "InnerHighlight")
    AcrylicController:Register(main, "MainWindow")
    window.Root = root
    window.Main = main
    window.ShadowHost = shadowHost
    window.OuterShadow = outerShadow
    window.InnerShadow = shadow
    window.ShadowOuterTransparency = 0.9
    window.ShadowInnerTransparency = 0.8
    window.WindowScale = create("UIScale", {
        Name = "WindowMotionScale",
        Scale = 1,
        Parent = root,
    })
    window.PopupLayer = library.GlobalPopupLayer

    local function syncShadowHost()
        if not shadowHost.Parent or not root.Parent then
            return
        end
        shadowHost.AnchorPoint = root.AnchorPoint
        shadowHost.Position = root.Position
        shadowHost.Size = root.Size
        shadowHost.Visible = root.Visible
    end
    addConnection(window, root:GetPropertyChangedSignal("Position"):Connect(syncShadowHost))
    addConnection(window, root:GetPropertyChangedSignal("Size"):Connect(syncShadowHost))
    addConnection(window, root:GetPropertyChangedSignal("AnchorPoint"):Connect(syncShadowHost))
    syncShadowHost()
    window:_makeHeader(config)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.BackgroundSoft,
        BackgroundTransparency = 0.24,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, Metrics.Header),
        Size = UDim2.new(0, Metrics.Sidebar, 1, -Metrics.Header),
        ZIndex = 12,
        Parent = main,
    }) :: Frame
    ThemeController:Bind(sidebar, "BackgroundColor3", "BackgroundSoft")
    local sidebarDivider = create("Frame", {
        BackgroundColor3 = Theme.Divider,
        BackgroundTransparency = 0.36,
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
        BackgroundTransparency = 0.76,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Text = "",
        PlaceholderText = "Search",
        PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(8, 6),
        Size = UDim2.new(1, -16, 0, TargetDesign.Navigation.SearchHeight),
        ZIndex = 15,
        Parent = sidebar,
    }) :: TextBox
    ThemeController:Bind(searchBox, "BackgroundColor3", "Surface2")
    corner(searchBox, 4)
    local searchStroke = stroke(searchBox, Theme.Border, 0.86, 1, "Control")
    padding(searchBox, 24, 0, 7, 0)
    local searchIcon = makeIcon(searchBox, { Icon = "search", IconSize = 10 }, "Muted")
    assert(searchIcon, "Required Lucide search icon is unavailable")
    searchIcon.AnchorPoint = Vector2.new(0, 0.5)
    searchIcon.Position = UDim2.new(0, -17, 0.5, 0)
    searchIcon.ZIndex = 16
    local navScroll = create("ScrollingFrame", {
        Name = "Navigation",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 36),
        Size = UDim2.new(1, -16, 1, window.ShowSidebarProfile and -68 or -42),
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
    local sidebarLayout = list(sidebarList, Enum.FillDirection.Vertical, 2)
    addConnection(
        window,
        sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            navScroll.CanvasSize = UDim2.fromOffset(0, sidebarLayout.AbsoluteContentSize.Y + 4)
        end)
    )
    local footer = create("TextButton", {
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.new(0, 8, 1, -29),
        Size = UDim2.new(1, -16, 0, 21),
        Visible = window.ShowSidebarProfile,
        ZIndex = 15,
        Parent = sidebar,
    }) :: TextButton
    ThemeController:Bind(footer, "BackgroundColor3", "Surface2")
    corner(footer, 4)
    local footerIcon = makeIcon(footer, { Icon = "user", IconSize = 10 }, "Accent")
    assert(footerIcon, "Required Lucide profile icon is unavailable")
    footerIcon.AnchorPoint = Vector2.new(0, 0.5)
    footerIcon.Position = UDim2.new(0, 11, 0.5, 0)
    footerIcon.ZIndex = 16
    local footerLabel = makeText(footer, LocalPlayer and LocalPlayer.DisplayName or "Profile", 8, Theme.SubText, "medium")
    footerLabel.Position = UDim2.fromOffset(27, 0)
    footerLabel.Size = UDim2.new(1, -32, 1, 0)
    footerLabel.ZIndex = 16

    local content = create("Frame", {
        Name = "Content",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(Metrics.Sidebar, Metrics.Header),
        Size = UDim2.new(1, -Metrics.Sidebar, 1, -Metrics.Header),
        ZIndex = 12,
        Parent = main,
    }) :: Frame
    ThemeController:Bind(content, "BackgroundColor3", "Background")
    local breadcrumb = makeText(content, "Overview", 8, Theme.Muted, "bold")
    breadcrumb.Name = "Breadcrumb"
    breadcrumb.Position = UDim2.fromOffset(9, 1)
    breadcrumb.Size = UDim2.new(1, -18, 0, 17)
    breadcrumb.ZIndex = 15

    local pageHost = create("Frame", {
        Name = "PageHost",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 18),
        Size = UDim2.new(1, 0, 1, -18),
        ZIndex = 13,
        Parent = content,
    }) :: Frame
    local emptySearch = makeText(content, "No matching tabs or controls", 9, Theme.Muted, "medium")
    emptySearch.AnchorPoint = Vector2.new(0.5, 0.5)
    emptySearch.Position = UDim2.fromScale(0.5, 0.5)
    emptySearch.Size = UDim2.fromOffset(280, 32)
    emptySearch.TextXAlignment = Enum.TextXAlignment.Center
    emptySearch.TextYAlignment = Enum.TextYAlignment.Center
    emptySearch.Visible = false
    emptySearch.ZIndex = 14

    window.Sidebar = sidebar
    window.SearchBox = searchBox
    window.SearchStroke = searchStroke
    window.SearchIcon = searchIcon
    window.NavigationScroll = navScroll
    window.SidebarList = sidebarList
    window.SidebarFooter = footer
    window.SidebarFooterLabel = footerLabel
    window.Content = content
    window.BreadcrumbLabel = breadcrumb
    window.PageHost = pageHost
    window.EmptySearch = emptySearch
    if config.SearchBar == false then
        searchBox.Visible = false
        navScroll.Position = UDim2.fromOffset(8, 8)
        navScroll.Size = UDim2.new(1, -16, 1, window.ShowSidebarProfile and -54 or -16)
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
            tween(searchStroke, { Color = Theme.Border, Transparency = 0.86 }, Motion.Hover)
        end)
    )
    addConnection(
        window,
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            window:QueueSearch(searchBox.Text)
        end)
    )
    addConnection(
        window,
        footer.Activated:Connect(function()
            window:OpenProfile()
        end)
    )
    ResponsiveController:RegisterTree(window, main)
    window:_bindInput()
    local resizeQueued = false
    local function viewportChanged()
        if resizeQueued or window.Destroyed then
            return
        end
        resizeQueued = true
        task.defer(function()
            resizeQueued = false
            if not window.Destroyed and window.Root and window.Root.Parent then
                window:ApplyResponsive()
            end
        end)
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
        { Name = "Legit PvP", Accent = Color3.fromRGB(164, 112, 255), Flags = {} },
        { Name = "Rage HvH", Accent = Color3.fromRGB(151, 96, 255), Flags = {} },
        { Name = "Trolling Config", Accent = Color3.fromRGB(175, 120, 255), Flags = {} },
        { Name = "Stealth RP", Accent = Color3.fromRGB(128, 104, 224), Flags = {} },
        { Name = "Vehicle God", Accent = Color3.fromRGB(184, 126, 255), Flags = {} },
    }
    window:ApplyResponsive()
    if config.MobileToggle ~= false then
        window:CreateReopenButton({})
    end
    if config.FloatingWidgets ~= false then
        window:CreateStatusStrip({
            Visible = config.StatusStrip ~= false,
            Fields = config.StatusFields,
        })
        window:CreateTargetList({ Visible = config.TargetList ~= false })
        window:CreateKeybindList({
            Visible = config.KeybindList ~= false,
            ActiveOnly = config.KeybindListActiveOnly == true,
            ShowEmptyMessage = config.KeybindListEmptyMessage ~= false,
        })
    end
    window:ApplyResponsive()
    if window.WindowScale then
        window.WindowScale.Scale = 0.992
        tween(window.WindowScale, { Scale = 1 }, Motion.Window, Enum.EasingStyle.Quart)
    end
    if window.OuterShadow then
        window.OuterShadow.BackgroundTransparency = 1
        tween(window.OuterShadow, {
            BackgroundTransparency = window.ShadowOuterTransparency or 0.9,
        }, Motion.Window)
    end
    if window.InnerShadow then
        window.InnerShadow.BackgroundTransparency = 1
        tween(window.InnerShadow, {
            BackgroundTransparency = window.ShadowInnerTransparency or 0.8,
        }, Motion.Window)
    end
    tween(root, {
        GroupTransparency = 0,
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
    AppearanceController:Refresh()
    BorderController:Refresh()
    AcrylicController:Refresh()
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
    AcrylicController:Refresh()
    for _, window in ipairs(self.Windows) do
        window:RefreshTheme()
    end
    return self
end

function Kronos:SetTransparency(value: number): AnyTable
    self.SurfaceTransparency = math.clamp(finiteNumber(value, self.SurfaceTransparency), 0, 0.9)
    AppearanceController:Refresh()
    AcrylicController:Refresh()
    return self
end

function Kronos:GetTransparency(): number
    return self.SurfaceTransparency
end

function Kronos:SetAcrylic(enabled: boolean): AnyTable
    self.AcrylicEnabled = enabled == true
    AcrylicController:Refresh()
    return self
end

function Kronos:GetAcrylic(): boolean
    return self.AcrylicEnabled == true
end

function Kronos:SetAcrylicIntensity(value: number): AnyTable
    self.AcrylicIntensity = math.clamp(finiteNumber(value, self.AcrylicIntensity), 0, 1)
    AcrylicController:Refresh()
    return self
end

function Kronos:GetAcrylicIntensity(): number
    return self.AcrylicIntensity
end

function Kronos:SetBorderIntensity(value: number): AnyTable
    self.BorderIntensity = math.clamp(finiteNumber(value, self.BorderIntensity), 0, 1.5)
    BorderController:Refresh()
    return self
end

function Kronos:GetBorderIntensity(): number
    return self.BorderIntensity
end

function Kronos:SetSurfaceContrast(value: number): AnyTable
    self.SurfaceContrast = math.clamp(finiteNumber(value, self.SurfaceContrast), 0.65, 1.4)
    ThemeController:Refresh()
    AppearanceController:Refresh()
    AcrylicController:Refresh()
    return self
end

function Kronos:GetSurfaceContrast(): number
    return self.SurfaceContrast
end

function Kronos:SetReducedMotion(enabled: boolean): AnyTable
    self.ReducedMotion = enabled == true
    if self.ReducedMotion then
        local instances = {}
        for instance in pairs(self.ActiveTweens) do
            table.insert(instances, instance)
        end
        for _, instance in ipairs(instances) do
            AnimationController:Cancel(instance, true)
        end
        for _, window in ipairs(self.Windows) do
            if window.Root and window.Root.Parent then
                window.Root.Visible = window.Visible ~= false
                window.Root.GroupTransparency = window.Visible ~= false and 0 or 1
            end
            for _, widget in ipairs(window.Widgets or {}) do
                if widget.Root and widget.Root.Parent then
                    widget.Root.Visible = widget.Visible ~= false
                    widget.Root.GroupTransparency = widget.Visible ~= false and 0 or 1
                end
            end
        end
    end
    return self
end

function Kronos:GetReducedMotion(): boolean
    return self.ReducedMotion == true
end

function Kronos:SetAnimationIntensity(value: number): AnyTable
    self.AnimationIntensity = math.clamp(finiteNumber(value, self.AnimationIntensity), 0, 2)
    return self
end

function Kronos:GetAnimationIntensity(): number
    return self.AnimationIntensity
end

function Kronos:SetAnimationsEnabled(enabled: boolean): AnyTable
    self.AnimationsEnabled = enabled == true
    if not self.AnimationsEnabled then
        local instances = {}
        for instance in pairs(self.ActiveTweens) do
            table.insert(instances, instance)
        end
        for _, instance in ipairs(instances) do
            AnimationController:Cancel(instance, true)
        end
    end
    return self
end

function Kronos:GetAnimationsEnabled(): boolean
    return self.AnimationsEnabled ~= false
end

function Kronos:SetNotificationMotion(enabled: boolean): AnyTable
    self.NotificationMotion = enabled == true
    return self
end

function Kronos:GetNotificationMotion(): boolean
    return self.NotificationMotion ~= false
end

function Kronos:SetPageTransitions(enabled: boolean): AnyTable
    self.PageTransitions = enabled == true
    return self
end

function Kronos:GetPageTransitions(): boolean
    return self.PageTransitions ~= false
end

function Kronos:SetDimStrength(value: number): AnyTable
    self.DimStrength = math.clamp(finiteNumber(value, self.DimStrength), 0, 0.9)
    for _, window in ipairs(self.Windows) do
        if window.SideDim and window.SideDim.Parent then
            window.SideDim.BackgroundTransparency = 1 - self.DimStrength
        end
    end
    return self
end

function Kronos:GetDimStrength(): number
    return self.DimStrength
end

Kronos.SetBackgroundDim = Kronos.SetDimStrength
Kronos.GetBackgroundDim = Kronos.GetDimStrength

function Kronos:ResetAppearance(): AnyTable
    self.SurfaceTransparency = 0.1
    self.AcrylicEnabled = true
    self.AcrylicIntensity = 0.58
    self.BorderIntensity = 1
    self.SurfaceContrast = 1.02
    self.ReducedMotion = false
    self.AnimationIntensity = 1
    self.AnimationsEnabled = true
    self.NotificationMotion = true
    self.PageTransitions = true
    self.DimStrength = 0.5
    AppearanceController:Refresh()
    BorderController:Refresh()
    AcrylicController:Refresh()
    return self
end

function Kronos:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    InputController:CancelPointer()
    DragController:Cancel()
    local notificationHandles = copyArray(self.NotificationHandles)
    for _, handle in ipairs(notificationHandles) do
        handle:Destroy()
    end
    while #self.Windows > 0 do
        self.Windows[#self.Windows]:Destroy()
    end
    ScrollbarController:DestroyAll()
    PopupController.Active = nil
    NotificationController.Active = nil
    InputController.ActivePointer = nil
    DragController.Active = nil
    ScrollbarController.Active = nil
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
    self.Layers = nil
    self.ActivePopupWindow = nil
    if DragController.Bindings then
        table.clear(DragController.Bindings)
    end
    if ScrollbarController.Entries then
        table.clear(ScrollbarController.Entries)
    end
    table.clear(self.Options)
    table.clear(self.Flags)
    table.clear(self.Keybinds)
    table.clear(self.Widgets)
    table.clear(self.Notifications)
    table.clear(self.NotificationHandles)
    table.clear(self.ThemeBindings)
    table.clear(self.ActiveTweenTargets)
    table.clear(self.SurfaceBindings)
    table.clear(self.BorderBindings)
    table.clear(self.AcrylicBindings)
    table.clear(self.Scrollbars)
    table.clear(InputController.KeyboardHandlers)
    InputController.Initialized = false
    if Environment.__KRONOS_ACTIVE == self then
        Environment.__KRONOS_ACTIVE = nil
    end
end

local function buildShowcase(): AnyTable
    local window = Kronos:CreateWindow({
        Title = "Kronos",
        Subtitle = "Lobby [1]",
        Icon = "layers-2",
        ProfileName = "Past Owl",
        ProfileSubtitle = "Tue 15 Jan 2026",
        ShowSidebarProfile = false,
        SearchBar = true,
        Accent = Theme.Accent,
        ToggleKey = Enum.KeyCode.RightShift,
        MobileToggle = true,
        FloatingWidgets = true,
        StatusFields = {
            Kronos = true,
            Context = true,
            FPS = false,
            Ping = false,
            Time = false,
        },
        KeybindListActiveOnly = false,
        KeybindListEmptyMessage = false,
        Transparency = 0.18,
        Acrylic = true,
        AcrylicIntensity = 0.62,
        BorderIntensity = 1,
        SurfaceContrast = 0.98,
    })

    local overview = window:AddTab({ Name = "General", Icon = "house" })
    local mainSubTab = overview:AddSubTab({ Name = "Player", Icon = "user-round" })
    local statesSubTab = overview:AddSubTab({ Name = "Combat", Icon = "crosshair" })
    -- The default showcase mirrors the objective's initial General › Player
    -- composition instead of presenting an internal component playground.
    -- All component APIs remain exercised across the other showcase pages.
    local general = mainSubTab:AddSection({
        Title = "General",
        Side = "Left",
    })
    general:AddToggle({
        Id = "ObjectiveSuicide",
        Title = "Suicide",
        Default = true,
    })
    general:AddToggle({
        Id = "ObjectiveSelfRevive",
        Title = "Self revive",
        Default = true,
    })
    general:AddToggle({
        Id = "ObjectiveForceCrush",
        Title = "Force crush",
        Default = true,
    })

    local playerOptions = mainSubTab:AddSection({
        Title = "Player options",
        Side = "Left",
    })
    playerOptions:AddToggle({ Id = "ObjectiveGodMode", Title = "God mode", Default = true })
    playerOptions:AddToggle({ Id = "ObjectiveSoloSession", Title = "Solo session", Default = false })
    playerOptions:AddToggle({ Id = "ObjectiveAntiHeadshot", Title = "Anti headshot", Default = true })
    playerOptions:AddToggle({ Id = "ObjectiveHealCover", Title = "Heal behind cover", Default = true })
    playerOptions:AddToggle({ Id = "ObjectiveInvisibility", Title = "Invisibility", Default = true })
    playerOptions:AddToggle({ Id = "ObjectiveServerInvisible", Title = "Server invisible", Default = true })
    playerOptions:AddToggle({ Id = "ObjectiveInfiniteStamina", Title = "Infinite stamina", Default = true })

    local movement = mainSubTab:AddSection({
        Title = "Movement options",
        Side = "Right",
    })
    movement:AddToggle({
        Id = "ObjectiveFreecam",
        Title = "Enable freecam",
        Default = true,
    })
    movement:AddToggle({
        Id = "ObjectiveNoClip",
        Title = "Enable no-clip",
        Default = true,
    })

    local coordinates = mainSubTab:AddSection({
        Title = "Coordinates",
        Side = "Right",
    })
    coordinates:AddInput({
        Id = "ObjectiveCoordinateX",
        Title = "X coordinate",
        NumericOnly = true,
        Default = 22,
    })
    coordinates:AddInput({
        Id = "ObjectiveCoordinateY",
        Title = "Y coordinate",
        NumericOnly = true,
        Default = 6,
    })
    coordinates:AddInput({
        Id = "ObjectiveCoordinateZ",
        Title = "Z coordinate",
        NumericOnly = true,
        Default = 0,
    })
    coordinates:AddButton({
        Id = "ObjectiveTeleportCoordinates",
        Title = "Teleport to coordinates",
        ButtonText = "Teleport",
    })

    local waypoint = mainSubTab:AddSection({
        Title = "Waypoint",
        Side = "Right",
    })
    waypoint:AddToggle({
        Id = "ObjectiveTeleportWaypoint",
        Title = "TP to waypoint",
        Default = true,
    })
    waypoint:AddDropdown({
        Id = "ObjectiveWalkingStyle",
        Title = "Walking style",
        Values = { "Normal", "Relaxed", "Confident" },
        Default = "Normal",
    })
    waypoint:AddButton({
        Id = "ObjectiveNotify",
        Title = "Notify",
        ButtonText = "Notify",
        Callback = function()
            window:Notify({
                Title = "Waypoint updated",
                Content = "The compact notification stack is active.",
                Icon = "circle-check",
                Type = "success",
                Duration = 2.4,
            })
        end,
    })

    local states = statesSubTab:AddSection({
        Title = "States",
        Side = "Left",
        Icon = "circle-check",
    })
    local dependency =
        states:AddToggle({ Id = "ShowcaseDependency", Title = "Advanced controls", Icon = "eye", Default = true })
    states:AddToggle({
        Id = "ShowcaseToggle",
        Title = "Enabled toggle",
        Icon = "check",
        Default = true,
    })
    states:AddToggle({
        Id = "ShowcaseDisabledToggle",
        Title = "Disabled toggle",
        Icon = "circle-off",
        Default = false,
        Disabled = true,
    })
    local dependentDropdown = states:AddDropdown({
        Id = "ShowcaseDependentDropdown",
        Title = "Dependent mode",
        Icon = "list-filter",
        Values = { "Balanced", "Precise", "Responsive" },
        Default = "Balanced",
    })
    dependency:AddDependency(dependentDropdown)
    states:AddSlider({
        Id = "ShowcaseStrength",
        Title = "Strength",
        Icon = "gauge",
        Min = 0,
        Max = 100,
        Default = 64,
        Step = 1,
        Suffix = "%",
    })

    local components = window:AddTab({ Name = "Visuals", Icon = "eye" })
    local inputsSubTab = components:AddSubTab({ Name = "Player", Icon = "user-round" })
    local selectionSubTab = components:AddSubTab({ Name = "World", Icon = "globe-2" })
    local feedbackSubTab = components:AddSubTab({ Name = "Notifications", Icon = "bell-ring" })
    local typographySubTab = components:AddSubTab({ Name = "Appearance", Icon = "palette" })
    local inputs = inputsSubTab:AddSection({
        Title = "Inputs",
        Side = "Left",
        Icon = "keyboard",
    })
    inputs:AddInput({
        Id = "ShowcaseTextInput",
        Title = "Text input",
        Icon = "text-cursor-input",
        Placeholder = "Type a value",
        Default = "Kronos",
        MaxLength = 32,
        SubmitOnEnter = true,
        OnSubmit = function(value)
            window:Notify({ Title = "Input submitted", Content = value, Icon = "send", Duration = 2 })
        end,
    })
    inputs:AddInput({
        Id = "ShowcaseNumericInput",
        Title = "Numeric input",
        Icon = "binary",
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
        Icon = "sliders-horizontal",
        Min = 0,
        Max = 1,
        Default = 0.35,
        Step = 0.05,
        Precision = 2,
    })
    inputs:AddColorPicker({
        Id = "ShowcaseColor",
        Title = "Accent color",
        Icon = "palette",
        Default = Theme.Accent,
        EnableAlpha = true,
        Callback = function(color)
            window:SetAccent(color)
        end,
    })

    local selections = selectionSubTab:AddSection({
        Title = "Selections",
        Side = "Left",
        Icon = "list-checks",
    })
    selections:AddDropdown({
        Id = "ShowcaseDropdown",
        Title = "Single dropdown",
        Icon = "chevrons-up-down",
        Values = { "Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa" },
        Default = "Gamma",
        Search = true,
        OptionIcons = { Alpha = "a-large-small", Gamma = "circle-dot", Kappa = "key-round" },
    })
    selections:AddMultiDropdown({
        Id = "ShowcaseMultiDropdown",
        Title = "Multi-select",
        Icon = "list-plus",
        Values = { "Status", "Target", "Keybinds", "Metrics", "Clock" },
        Default = { "Status", "Keybinds" },
        MaxSelections = 3,
    })
    selections:AddKeybind({
        Id = "ShowcaseKeybind",
        Title = "Suicide",
        Icon = "command",
        Default = Enum.KeyCode.X.Name,
        Mode = "Toggle",
        Callback = function(active)
            window:Notify({
                Title = "Keybind state",
                Content = active and "Active" or "Inactive",
                Icon = "keyboard",
                Duration = 1.6,
            })
        end,
    })
    selections:AddKeybind({
        Id = "ShowcaseHoldKeybind",
        Title = "Enable no-clip",
        Icon = "mouse-pointer-click",
        Default = Enum.KeyCode.H.Name,
        Mode = "Hold",
    })

    local feedback = feedbackSubTab:AddSection({ Title = "Feedback", Icon = "message-square-more" })
    feedback:AddButton({
        Id = "ShowcaseSuccessFeedback",
        Title = "Success notification",
        Icon = "circle-check",
        ButtonText = "Show",
        Callback = function()
            window:Notify({
                Title = "Action completed",
                Content = "The requested action finished.",
                Icon = "circle-check",
                Type = "success",
            })
        end,
    })
    feedback:AddToggle({
        Id = "ShowcaseFeedbackToggle",
        Title = "Interaction feedback",
        Icon = "mouse-pointer-click",
        Default = true,
    })

    local typography = typographySubTab:AddSection({ Title = "Typography", Icon = "type" })
    typography:AddLabel({ Text = "Compact utility label", Icon = "text-cursor" })
    typography:AddParagraph({
        Title = "Reference hierarchy",
        Content = "Quiet copy, restrained weight, and dense spacing.",
        Icon = "text-align-start",
    })
    typography:AddDivider({ Title = "Secondary" })

    local weapon = window:AddTab({ Name = "Weapon", Icon = "crosshair" })
    local weaponGeneral = weapon:AddSubTab({ Name = "General", Icon = "sliders-horizontal" })
    local weaponHandling = weapon:AddSubTab({ Name = "Handling", Icon = "gauge" })
    local weaponOptions = weaponGeneral:AddSection({ Title = "Weapon options", Icon = "crosshair", Side = "Left" })
    weaponOptions:AddToggle({
        Id = "ShowcaseWeaponEnabled",
        Title = "Enable weapon profile",
        Icon = "circle-check",
        Default = true,
    })
    weaponOptions:AddToggle({
        Id = "ShowcaseAutoReload",
        Title = "Automatic reload",
        Icon = "refresh-cw",
        Default = false,
    })
    weaponOptions:AddDropdown({
        Id = "ShowcaseWeaponPreset",
        Title = "Selected weapon",
        Icon = "list-filter",
        Values = { "Primary", "Secondary", "Utility" },
        Default = "Primary",
    })
    local handling = weaponHandling:AddSection({ Title = "Handling", Icon = "gauge", Side = "Left" })
    handling:AddSlider({
        Id = "ShowcaseWeaponResponse",
        Title = "Response",
        Icon = "activity",
        Min = 0,
        Max = 100,
        Default = 72,
        Suffix = "%",
    })
    handling:AddSlider({
        Id = "ShowcaseWeaponOffset",
        Title = "Vertical offset",
        Icon = "move-vertical",
        Min = -1,
        Max = 1,
        Default = 0,
        Step = 0.05,
        Precision = 2,
    })

    local vehicle = window:AddTab({ Name = "Vehicle", Icon = "car-front" })
    local vehicleGeneral = vehicle:AddSubTab({ Name = "General", Icon = "car-front" })
    local vehicleOptions = vehicleGeneral:AddSection({ Title = "Vehicle options", Icon = "car-front", Side = "Left" })
    vehicleOptions:AddToggle({
        Id = "ShowcaseVehicleAssist",
        Title = "Driving assistance",
        Icon = "route",
        Default = true,
    })
    vehicleOptions:AddToggle({
        Id = "ShowcaseVehicleStability",
        Title = "Stability control",
        Icon = "shield-check",
        Default = true,
    })
    vehicleOptions:AddSlider({
        Id = "ShowcaseVehicleResponse",
        Title = "Steering response",
        Icon = "rotate-3d",
        Min = 0,
        Max = 100,
        Default = 55,
        Suffix = "%",
    })

    local advanced = window:AddTab({ Name = "Server", Icon = "server" })
    local panelsSubTab = advanced:AddSubTab({ Name = "Interface", Icon = "panels-top-left" })
    local widgetsSubTab = advanced:AddSubTab({ Name = "Widgets", Icon = "move" })
    local responsiveSubTab =
        advanced:AddSubTab({ Name = "Responsive & Accessibility", Icon = "smartphone" })
    local panels = panelsSubTab:AddSection({
        Title = "Panels",
        Side = "Left",
        Icon = "panel-top",
    })
    panels:AddButton({
        Id = "ShowcaseSettings",
        Title = "Profile settings",
        ButtonText = "Open",
        Icon = "user-cog",
        Callback = function()
            window:OpenSettings()
        end,
    })
    panels:AddButton({
        Id = "ShowcasePresets",
        Title = "Configuration presets",
        ButtonText = "Open",
        Icon = "save",
        Callback = function()
            window:OpenPresets()
        end,
    })
    panels:AddButton({
        Id = "ShowcaseMinimize",
        Title = "Minimize and restore",
        ButtonText = "Minimize",
        Icon = "minimize-2",
        Callback = function()
            window:Minimize()
        end,
    })
    panels:AddDivider({ Title = "Notifications", Icon = "bell" })
    panels:AddButton({
        Id = "ShowcaseWarning",
        Title = "Warning",
        ButtonText = "Show",
        Icon = "triangle-alert",
        Callback = function()
            window:Notify({
                Title = "Warning",
                Content = "This is a restrained warning state.",
                Icon = "triangle-alert",
                Type = "warning",
            })
        end,
    })
    panels:AddButton({
        Id = "ShowcaseError",
        Title = "Error",
        ButtonText = "Show",
        Icon = "circle-x",
        Callback = function()
            window:Notify({
                Title = "Error",
                Content = "Callbacks remain isolated from the interface.",
                Icon = "circle-x",
                Type = "error",
            })
        end,
    })

    local widgets = widgetsSubTab:AddSection({
        Title = "Floating widgets",
        Side = "Left",
        Icon = "move",
    })
    widgets:AddToggle({
        Id = "ShowcaseStatusVisible",
        Title = "Status strip",
        Icon = "activity",
        Default = true,
        Callback = function(value)
            window.StatusStrip:SetVisible(value)
        end,
    })
    widgets:AddToggle({
        Id = "ShowcaseTargetVisible",
        Title = "Target list",
        Icon = "target",
        Default = true,
        Callback = function(value)
            window.TargetList:SetVisible(value)
        end,
    })
    widgets:AddToggle({
        Id = "ShowcaseKeybindsVisible",
        Title = "Keybind list",
        Icon = "keyboard",
        Default = true,
        Callback = function(value)
            window.KeybindWidget:SetVisible(value)
        end,
    })
    widgets:AddLabel({ Text = "Drag each widget across the full viewport", Icon = "move", Muted = true })

    local responsive = responsiveSubTab:AddSection({
        Title = "Adaptive layout",
        Icon = "scan",
        Side = "Left",
    })
    responsive:AddParagraph({
        Title = "Structural breakpoints",
        Content = "The shell preserves its measured ratio in landscape and becomes a single-column surface in portrait.",
        Icon = "smartphone",
    })
    responsive:AddButton({
        Title = "Reset layout",
        ButtonText = "Reset",
        Icon = "locate-fixed",
        Callback = function()
            window:ResetPositions()
        end,
    })

    local playerTab = window:AddTab({ Name = "Player", Icon = "user-round" })
    local playerGeneral = playerTab:AddSubTab({ Name = "General", Icon = "user-round" })
    local playerOptions = playerGeneral:AddSection({ Title = "Player options", Icon = "user-cog", Side = "Left" })
    playerOptions:AddToggle({
        Id = "ShowcasePlayerStatus",
        Title = "Show player status",
        Icon = "badge-info",
        Default = true,
    })
    playerOptions:AddDropdown({
        Id = "ShowcasePlayerMode",
        Title = "Movement mode",
        Icon = "footprints",
        Values = { "Normal", "Assisted", "Free" },
        Default = "Normal",
    })
    playerOptions:AddButton({
        Id = "ShowcasePlayerReset",
        Title = "Reset local state",
        Icon = "rotate-ccw",
        ButtonText = "Reset",
        Callback = function()
            window:Notify({
                Title = "Local state reset",
                Content = "Showcase values were restored.",
                Icon = "rotate-ccw",
                Duration = 2,
            })
        end,
    })

    local miscTab = window:AddTab({ Name = "Misc", Icon = "wrench" })
    local miscGeneral = miscTab:AddSubTab({ Name = "Interface", Icon = "settings-2" })
    local miscOptions = miscGeneral:AddSection({ Title = "Interface utilities", Icon = "wrench", Side = "Left" })
    miscOptions:AddToggle({
        Id = "ShowcaseSearchEnabled",
        Title = "Live search",
        Icon = "search",
        Default = true,
        Callback = function(value)
            window:SetSearchBehavior(value and "Live" or "ClearOnNavigation")
        end,
    })
    miscOptions:AddButton({
        Id = "ShowcaseResetWidgets",
        Title = "Reset widget positions",
        Icon = "locate-fixed",
        ButtonText = "Reset",
        Callback = function()
            window:ResetWidgetPositions()
        end,
    })

    local luaTab = window:AddTab({ Name = "Lua system", Icon = "file-code-2" })
    local luaGeneral = luaTab:AddSubTab({ Name = "Runtime", Icon = "braces" })
    local luaOptions = luaGeneral:AddSection({ Title = "Runtime information", Icon = "file-code-2", Side = "Left" })
    luaOptions:AddLabel({ Text = "Kronos " .. tostring(Kronos.Version), Icon = "badge-check", Bold = true })
    luaOptions:AddParagraph({
        Title = "Lifecycle",
        Content = "Initialization, re-execution, and cleanup share one owned runtime.",
        Icon = "refresh-cw",
    })

    local executorTab = window:AddTab({ Name = "Executor", Icon = "terminal" })
    local executorGeneral = executorTab:AddSubTab({ Name = "Compatibility", Icon = "terminal" })
    local executorOptions =
        executorGeneral:AddSection({ Title = "Runtime compatibility", Icon = "shield-check", Side = "Left" })
    executorOptions:AddLabel({ Text = "Native Roblox UI path active", Icon = "circle-check" })
    executorOptions:AddParagraph({
        Title = "Fallback behavior",
        Content = "Optional capabilities degrade without disabling the main interface.",
        Icon = "info",
    })

    if window.TargetList then
        window.TargetList:SetTarget({
            Name = "Past Owl",
            Health = 10,
            MaxHealth = 20,
            UserId = nil,
        })
    end
    window:ApplySearch("")
    window:Notify({
        Title = "Kronos ready",
        Content = "Interface loaded.",
        Icon = "circle-check",
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

local startupOk = startupStage("ServiceResolution", function()
    assert(type(Environment) == "table", "Luau environment is unavailable")
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
if startupOk then
    startupOk = startupStage("PreviousInstanceCleanup", function()
        assert(previousCleanupOk, tostring(previousCleanupError))
    end)
end
if startupOk then
    startupOk = startupStage("TargetDesignValidation", function()
        assert(
            TargetDesign.Window.LogicalSize.X > 0
                and TargetDesign.Window.LogicalSize.Y > 0
                and TargetDesign.Window.MobileLandscapeScale > 0
                and TargetDesign.Window.MobileLandscapeScale <= 1,
            "Target window geometry is invalid"
        )
        assert(TargetDesign.Control.Row > 0 and TargetDesign.Control.InputHeight > 0, "Control geometry tokens are invalid")
        assert(TargetDesign.Popup.DropdownWidth > 0 and TargetDesign.Popup.ColorWidth > 0, "Popup geometry tokens are invalid")
        assert(TargetDesign.Scrollbar.MinimumThumb > 0 and TargetDesign.Scrollbar.ActiveWidth >= TargetDesign.Scrollbar.IdleWidth, "Scrollbar tokens are invalid")
        assert(TargetDesign.Widget.TargetWidth > 0 and TargetDesign.Widget.KeybindWidth > 0, "Widget geometry tokens are invalid")
        assert(
            TargetDesign.Navigation.CompactWidth >= 28
                and Metrics.Sidebar > TargetDesign.Navigation.CompactWidth,
            "Navigation geometry tokens are invalid"
        )
        assert(boundedClamp(1, 2, 0) == 1, "Ordered clamp helper is invalid")
        assert(type(Window.QueueSearch) == "function", "Search coalescing API is unavailable")
    end)
end
if startupOk then
    startupOk = startupStage("ThemeCreation", function()
        assert(
            Theme.Background and Theme.Surface and Theme.Accent and Theme.Text,
            "Semantic theme tokens are incomplete"
        )
        assert(Motion.Window and Metrics.Window, "Motion or sizing tokens are incomplete")
        assert(
            type(AppearanceController.Refresh) == "function"
                and type(BorderController.Refresh) == "function"
                and type(AcrylicController.Refresh) == "function",
            "Appearance controllers are incomplete"
        )
    end)
end
if startupOk then
    startupOk = startupStage("LucideResolverCreation", function()
        local apple, appleName, appleValid = IconController:Resolve("apple")
        local check, checkName, checkValid = IconController:Resolve("circle-check")
        assert(apple and appleName == "apple" and appleValid, "Lucide apple is unavailable")
        assert(check and checkName == "circle-check" and checkValid, "Lucide circle-check is unavailable")
    end)
end
if startupOk then
    startupOk = startupStage("RootGuiCreation", function()
        Kronos:_ensureGui()
    end)
end
if startupOk then
    startupOk = startupStage("InputControllerCreation", function()
        InputController:Initialize()
        assert(
            InputController.Initialized
                and type(InputController.Name) == "function"
                and type(InputController.Matches) == "function"
                and type(InputController.BeginPointer) == "function"
                and type(InputController.CancelPointer) == "function",
            "Input controller is incomplete"
        )
    end)
end
if startupOk then
    startupOk = startupStage("DragControllerCreation", function()
        DragController:Initialize()
        assert(DragController.Initialized and type(DragController.Bind) == "function")
    end)
end
if startupOk then
    startupOk = startupStage("PopupControllerCreation", function()
        assert(type(PopupController.Open) == "function" and type(PopupController.Position) == "function")
        assert(type(NotificationController.Push) == "function")
        assert(type(ScrollbarController.Attach) == "function" and type(ScrollbarController.DestroyAll) == "function")
    end)
end
if startupOk then
    startupOk = startupStage("WindowCreation", function()
        assert(type(WindowController.Create) == "function" and type(NavigationController.Select) == "function")
        assert(type(Tab.CreateSubTab) == "function" and type(SubTab.AddSection) == "function")
        assert(type(SubtabController.Refresh) == "function" and type(SubtabController.Reveal) == "function")
        assert(
            type(Components.Toggle) == "function"
                and type(Components.Dropdown) == "function"
                and type(Components.MultiDropdown) == "function"
                and type(Components.Keybind) == "function"
                and type(Components.ColorPicker) == "function",
            "A required component constructor is unavailable"
        )
    end)
end
if startupOk then
    startupOk = startupStage("PublicAPICompatibility", function()
        assert(Kronos.Version == "1.8.0", "Unexpected Kronos version")
        assert(
            type(Kronos.CreateWindow) == "function"
                and type(Kronos.Notify) == "function"
                and type(Kronos.Destroy) == "function",
            "Core public API is incomplete"
        )
        assert(
            type(Window.AddTab) == "function"
                and type(Window.SetTransparency) == "function"
                and type(Window.SetAcrylic) == "function"
                and type(Window.SetBorderIntensity) == "function"
                and type(Window.OpenSettings) == "function"
                and type(Window.SetTitle) == "function"
                and type(Window.SetSubtitle) == "function",
            "Window compatibility API is incomplete"
        )
        assert(
            type(Tab.AddSubTab) == "function"
                and type(Tab.AddSection) == "function"
                and type(SubTab.AddSection) == "function",
            "Navigation compatibility API is incomplete"
        )
        assert(
            type(Section.AddButton) == "function"
                and type(Section.AddToggle) == "function"
                and type(Section.AddSlider) == "function"
                and type(Section.AddInput) == "function"
                and type(Section.AddDropdown) == "function"
                and type(Section.AddKeybind) == "function"
                and type(Section.AddColorPicker) == "function",
            "Component compatibility API is incomplete"
        )
    end)
end
if startupOk then
    startupOk = startupStage("WidgetCreation", function()
        assert(type(FloatingWidgetController.Create) == "function")
        assert(
            type(Window.CreateFloatingWidget) == "function"
                and type(Window.CreateTargetList) == "function"
                and type(Window.CreateKeybindList) == "function"
                and type(Window.CreateStatusStrip) == "function"
                and type(Window.CreateReopenButton) == "function"
        )
    end)
end
if startupOk and RUN_SHOWCASE then
    local showcaseOk, showcaseError = startupStage("ShowcaseCreation", buildShowcase)
    if not showcaseOk then
        Kronos:Notify({
            Title = "Showcase failed",
            Content = tostring(showcaseError),
            Icon = "circle-x",
            Type = "error",
            Duration = 7,
        })
    end
end
if startupOk then
    startupStage("Activation", function()
        Environment.__KRONOS_ACTIVE = Kronos
    end)
end

return Kronos
