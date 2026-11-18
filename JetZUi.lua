--!strict
-- JetZUi · client-side, dependency-free ModuleScript.
-- require(module):CreateWindow({ Title = "Tool" }); then AddTab / AddSubTab / AddSection.
-- Ranges are { Min = number, Max = number }; multi-values are ordered, dense arrays.
-- Value setters return (accepted, changedOrReason). Silent updates still render and update flags.
-- OnChanged receives (value, previous, controller); ColorPicker additionally supplies alpha.
-- Menus accept scalar/EnumItem/Instance values. Only JSON-safe scalars, enums, Color3, ranges,
-- and arrays are persisted. ImportConfig defaults to silent, validated, atomic application.
-- Destroyed handles ignore further calls (IsDestroyed remains safe). Destroy is idempotent.
-- ScreenGui defaults to PlayerGui with ResetOnSpawn=false; supply Parent for another owned host.
-- Size is logical Vector2; position is in safe-area pixels. GetLayout reports effective layout.
-- CreateReferenceDemo is optional and contains presentation/state only.
-- Controls support live dependencies: DependsOn/SetDependency and Toggle:AddSettings with Reveal/Disable/Dim modes.
-- Any row supports Locked=true / SetLocked(), with JetZ-native PREMIUM chrome and anchored purchase callout.
-- Settings > Configs owns persistent profiles, clipboard transfer, dirty state and per-game autoload.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Tweens = game:GetService("TweenService")
local Gui = game:GetService("GuiService")
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")

export type Range = { Min: number, Max: number }
export type Key = Enum.KeyCode | Enum.UserInputType
export type Option = string | number | boolean | EnumItem | Instance
export type Connection = { Connected: boolean, Disconnect: (Connection) -> () }
export type ComponentOptions = {
    Name: string?,
    Description: string?,
    Tooltip: string?,
    Flag: string?,
    Id: string?,
    Order: number?,
    Visible: boolean?,
    Disabled: boolean?,
    Context: { any }?,
    ContextBuild: ((any) -> ())?,
}
export type ValueOptions<T> = ComponentOptions & { Default: T?, Callback: ((T, T?, any) -> ())? }
export type SliderOptions = ValueOptions<number> & {
    Min: number?,
    Max: number?,
    Increment: number?,
    Prefix: string?,
    Suffix: string?,
    Format: ((number) -> string)?,
}
export type DropdownOptions<T> = ValueOptions<T> & {
    Values: { Option }?,
    Searchable: boolean?,
    MaxVisibleItems: number?,
    Placeholder: string?,
}
export type WindowOptions = {
    Id: string?,
    Title: string?,
    Version: string?,
    Logo: any?,
    Parent: Instance?,
    DisplayOrder: number?,
    Accent: Color3?,
    Theme: { [string]: any }?,
    Size: (Vector2 | UDim2)?,
    Position: (Vector2 | UDim2)?,
    Scale: number?,
    Contrast: number?,
    AnimationSpeed: number?,
    Draggable: boolean?,
    Resizable: boolean?,
    Visible: boolean?,
    HideKey: Key?,
    Development: boolean?,
    Touch: boolean?,
    Particles: boolean?,
    ParticleCount: number?,
}
export type ConfigOptions = { Silent: boolean?, Atomic: boolean?, IgnoreUnknown: boolean? }
export type CustomContext = {
    Container: Frame,
    Theme: (string) -> Color3?,
    Bind: (Instance, string, string) -> (),
    Cleanup: (any) -> any,
    Animate: (Instance, string, { [string]: any }) -> (),
    GetFlag: (string) -> any,
    SetFlag: (string, any, boolean?) -> (boolean, any),
    CanInteract: () -> boolean,
}

export type Controller = {
    SetVisible: (self: any, value: boolean) -> boolean,
    IsVisible: (self: any) -> boolean,
    SetDisabled: (self: any, value: boolean) -> boolean,
    IsDisabled: (self: any) -> boolean,
    SetName: (self: any, name: string) -> boolean,
    GetName: (self: any) -> string,
    SetDescription: (self: any, description: string?) -> boolean,
    GetDescription: (self: any) -> string?,
    SetTooltip: (self: any, tooltip: string?) -> boolean,
    GetTooltip: (self: any) -> string?,
    SetOrder: (self: any, order: number) -> boolean,
    GetOrder: (self: any) -> number,
    GetInstance: (self: any) -> GuiObject?,
    Destroy: (self: any) -> (),
    IsDestroyed: (self: any) -> boolean,
}
export type ValueHandle<T> = Controller & {
    GetValue: (self: any) -> T,
    SetValue: (self: any, value: T, silent: boolean?) -> (boolean, any),
    SetDefault: (self: any, value: T) -> boolean,
    GetDefault: (self: any) -> T,
    Reset: (self: any, silent: boolean?) -> (boolean, any),
    OnChanged: (self: any, listener: (T, T, any, ...any) -> ()) -> Connection,
}
export type NumericHandle<T> = ValueHandle<T> & {
    GetMin: (self: any) -> number,
    GetMax: (self: any) -> number,
    GetRange: (self: any) -> (number, number),
    SetMin: (self: any, min: number) -> boolean,
    SetMax: (self: any, max: number) -> boolean,
    SetRange: (self: any, min: number, max: number) -> boolean,
    GetIncrement: (self: any) -> number,
    SetIncrement: (self: any, step: number) -> boolean,
    SetPrefix: (self: any, prefix: string?) -> boolean,
    SetSuffix: (self: any, suffix: string?) -> boolean,
    SetFormat: (self: any, format: ((number) -> string)?) -> boolean,
}
export type SliderHandle = NumericHandle<number> & {
    OnDragStarted: (self: any, f: (number, any) -> ()) -> Connection,
    OnDragEnded: (self: any, f: (number, any, boolean) -> ()) -> Connection,
    IsDragging: (self: any) -> boolean,
}
export type RangeHandle = NumericHandle<Range> & {
    GetMinimumValue: (self: any) -> number,
    GetMaximumValue: (self: any) -> number,
    SetMinimumValue: (self: any, min: number, silent: boolean?) -> (boolean, any),
    SetMaximumValue: (self: any, max: number, silent: boolean?) -> (boolean, any),
}
export type CheckboxHandle = ValueHandle<boolean> & {
    Toggle: (self: any, silent: boolean?) -> (boolean, any),
    SetKeybind: (self: any, key: (Key | string)?) -> boolean,
    GetKeybind: (self: any) -> Key?,
    SetKeybindMode: (self: any, mode: "Toggle" | "Hold") -> boolean,
}
export type ChoiceHandle<T> = ValueHandle<T> & {
    GetValues: (self: any) -> { Option },
    SetValues: (self: any, values: { Option }, preserveSelection: boolean?) -> boolean,
    AddValue: (self: any, value: Option) -> boolean,
    RemoveValue: (self: any, value: Option) -> boolean,
    HasValue: (self: any, value: Option) -> boolean,
    ClearValues: (self: any) -> boolean,
}
export type DropdownHandle<T> = ChoiceHandle<T> & {
    Open: (self: any) -> boolean,
    Close: (self: any) -> boolean,
    Toggle: (self: any) -> boolean,
    IsOpen: (self: any) -> boolean,
    SetSearchable: (self: any, searchable: boolean) -> boolean,
    IsSearchable: (self: any) -> boolean,
    SetPlaceholder: (self: any, placeholder: string?) -> boolean,
    SetMaxVisibleItems: (self: any, max: number) -> boolean,
    OnOpened: (self: any, f: (any) -> ()) -> Connection,
    OnClosed: (self: any, f: (any) -> ()) -> Connection,
}
export type MultiDropdownHandle = DropdownHandle<{ Option }> & {
    Select: (self: any, choice: Option, silent: boolean?) -> (boolean, any),
    Deselect: (self: any, choice: Option, silent: boolean?) -> (boolean, any),
    ToggleValue: (self: any, choice: Option, silent: boolean?) -> (boolean, any),
    IsSelected: (self: any, choice: Option) -> boolean,
    SetMaximum: (self: any, max: number?) -> (boolean, any),
    SetMinimum: (self: any, min: number?) -> (boolean, any),
    SelectAll: (self: any, silent: boolean?) -> (boolean, any),
    ClearSelection: (self: any, silent: boolean?) -> (boolean, any),
}
export type ColorHandle = ValueHandle<Color3> & {
    GetColor: (self: any) -> Color3,
    SetColor: (self: any, color: Color3, silent: boolean?) -> (boolean, any),
    GetAlpha: (self: any) -> number,
    SetAlpha: (self: any, alpha: number, silent: boolean?) -> (boolean, any),
    GetHSV: (self: any) -> (number, number, number),
    SetHSV: (self: any, h: number, s: number, v: number, silent: boolean?) -> (boolean, any),
    GetHex: (self: any) -> string,
    SetHex: (self: any, hex: string, silent: boolean?) -> (boolean, any),
    Open: (self: any) -> boolean,
    Close: (self: any) -> boolean,
    Toggle: (self: any) -> boolean,
    IsOpen: (self: any) -> boolean,
}
export type ConfigReport = {
    Applied: number,
    Changed: number,
    Ignored: { string },
    Errors: { [string]: string },
}
export type Layout = {
    Width: number,
    Height: number,
    Sidebar: number,
    Touch: boolean,
    Drawer: boolean,
    Compact: boolean,
    Scale: number,
    Hit: number,
    Margin: number,
}
export type PageHandle = Controller & {
    Select: (self: any) -> boolean,
    IsSelected: (self: any) -> boolean,
    AddSection: (self: any, options: any?) -> any,
    GetSections: (self: any) -> { any },
    Clear: (self: any) -> (),
}
export type WindowHandle = Controller & {
    SetTitle: (self: any, title: string) -> boolean,
    GetTitle: (self: any) -> string,
    SetLogo: (self: any, logo: any) -> boolean,
    SetVersion: (self: any, version: string) -> boolean,
    Show: (self: any) -> boolean,
    Hide: (self: any) -> boolean,
    Toggle: (self: any) -> boolean,
    SetAccent: (self: any, accent: Color3) -> boolean,
    GetAccent: (self: any) -> Color3,
    SetScale: (self: any, scale: number) -> boolean,
    GetScale: (self: any) -> number,
    SetContrast: (self: any, contrast: number) -> boolean,
    GetContrast: (self: any) -> number,
    SetAnimationSpeed: (self: any, speed: number) -> boolean,
    GetAnimationSpeed: (self: any) -> number,
    SetDraggable: (self: any, draggable: boolean) -> boolean,
    SetResizable: (self: any, resizable: boolean) -> boolean,
    SetSize: (self: any, size: Vector2 | UDim2) -> boolean,
    GetSize: (self: any) -> Vector2,
    SetPosition: (self: any, position: Vector2 | UDim2) -> boolean,
    GetPosition: (self: any) -> Vector2,
    GetLayout: (self: any) -> Layout,
    AddTab: (self: any, options: any?) -> any,
    GetTab: (self: any, id: any) -> any,
    GetTabs: (self: any) -> { any },
    SelectTab: (self: any, id: any) -> boolean,
    GetFlag: (self: any, flag: string) -> any,
    SetFlag: (self: any, flag: string, value: any, silent: boolean?) -> (boolean, any),
    GetFlags: (self: any) -> { [string]: any },
    ExportConfig: (self: any, json: boolean?) -> (any, { string }),
    ImportConfig: (self: any, config: any, options: ConfigOptions?) -> (boolean, ConfigReport | string),
    Notify: (self: any, options: any) -> any,
    CreateDialog: (self: any, options: any) -> any,
}

-- Dynamic dispatch is confined to the private controller prototypes, cleanup, and the
-- declarative instance factory. The exported configs describe the stable consumer boundary.
type Payload = { [any]: any }
local U = {}
local P: Payload = {}
local Build: Payload = {}
local Library: any = { Version = "1.5.0" }

local V = Vector2.new
local O = UDim2.fromOffset
local S = UDim2.fromScale
local C = Color3.fromRGB
local White = C(255, 255, 255)
local Black = C(0, 0, 0)
local D = {
    Width = 838,
    Height = 536,
    Sidebar = 198,
    LandscapeSidebar = 140,
    Drawer = 238,
    Header = 60,
    TouchHeader = 48,
    BrandHeight = 88,
    NavStart = 103,
    NavRow = 45,
    NavGap = 10,
    Left = 71,
    Right = 76,
    ScrollRight = 36,
    ScrollTop = 5,
    ScrollBottom = 65,
    TouchGutter = 16,
    DesktopSafe = 14,
    MobileSafe = 7,
    DrawerBreakpoint = 660,
    LandscapeBreakpoint = 830,
    InlineMin = 194,
    InlineGap = 23,
    TouchHit = 44,
    Resize = {
        DesktopHit = 28,
        Plate = 22,
        Icon = 15,
        Inset = 5,
        ReadoutWidth = 105,
        ReadoutHeight = 23,
        Step = 16,
        MinWidth = 320,
        MinHeight = 225,
        MaxWidth = 2400,
        MaxHeight = 1600,
    },
    Row = 60,
    CheckRow = 67,
    NumericRow = 80,
    Radius = 11,
    FieldRadius = 3,
    PopupRadius = 5,
    ScrollWidth = 4,
    ScrollMin = 25,
    Check = 22,
    Track = 6,
    ThumbWidth = 29,
    ThumbHeight = 11,
    Gear = 14,
    PopupMargin = 8,
    PopupGap = 5,
    Option = 33,
    Search = 34,
    PressSlop = 8,
    TouchIntent = 7,
    HoverDelay = 0.38,
    HoldDelay = 0.48,
    MinScale = 0.75,
    MaxScale = 1.25,
    ParticleMax = 48,
    ParticleTouchMax = 20,
    Typography = {
        Brand = 16,
        Sidebar = 15,
        TopTab = 13,
        Control = 13,
        Numeric = 13,
        Muted = 12,
        Footer = 12,
        Tooltip = 12,
        Popup = 13,
        Section = 12,
    },
    Animation = {
        hover = 0.10,
        state = 0.13,
        nav = 0.17,
        page = 0.14,
        popup = 0.13,
        drawer = 0.18,
        toast = 0.18,
        modal = 0.15,
        progress = 1.18,
    },
    Colors = {
        Background = C(13, 13, 15),
        Sidebar = C(14, 13, 18),
        SidebarSelected = C(19, 18, 24),
        Surface = C(17, 16, 21),
        SurfaceRaised = C(24, 22, 29),
        Row = C(17, 16, 21),
        Hover = C(24, 22, 28),
        Pressed = C(32, 27, 34),
        Stroke = C(42, 38, 47),
        Divider = C(20, 20, 23),
        Track = C(25, 23, 29),
        Text = C(232, 229, 233),
        TextSecondary = C(175, 170, 181),
        TextMuted = C(98, 92, 107),
        NavMuted = C(84, 78, 93),
        Subdued = C(64, 59, 73),
        TextDisabled = C(69, 64, 77),
        Accent = C(202, 112, 113),
        Thumb = C(248, 247, 246),
        Danger = C(229, 113, 122),
        Warning = C(222, 178, 108),
        Success = C(128, 194, 155),
        Info = C(140, 163, 224),
    },
}
local ThemePresets: Payload = {
    ["JetZ Dark"] = {
        Background = C(13, 13, 15),
        Sidebar = C(14, 13, 18),
        SidebarSelected = C(19, 18, 24),
        Surface = C(17, 16, 21),
        SurfaceRaised = C(24, 22, 29),
        Row = C(17, 16, 21),
        Hover = C(24, 22, 28),
        Pressed = C(32, 27, 34),
        Stroke = C(42, 38, 47),
        Divider = C(20, 20, 23),
        Track = C(25, 23, 29),
        Text = C(232, 229, 233),
        TextSecondary = C(175, 170, 181),
        TextMuted = C(98, 92, 107),
        NavMuted = C(84, 78, 93),
        Subdued = C(64, 59, 73),
        TextDisabled = C(69, 64, 77),
        Accent = C(202, 112, 113),
        Thumb = C(248, 247, 246),
        Danger = C(229, 113, 122),
        Warning = C(222, 178, 108),
        Success = C(128, 194, 155),
        Info = C(140, 163, 224),
    },
    ["Graphite"] = {
        Background = C(14, 14, 17), Sidebar = C(16, 16, 20), SidebarSelected = C(24, 24, 30),
        Surface = C(20, 20, 25), SurfaceRaised = C(29, 29, 36), Row = C(20, 20, 25),
        Hover = C(31, 31, 39), Pressed = C(38, 38, 47), Stroke = C(56, 55, 67),
        Divider = C(28, 28, 34), Track = C(35, 34, 42), Text = C(237, 236, 240),
        TextSecondary = C(181, 179, 188), TextMuted = C(105, 102, 116), NavMuted = C(91, 88, 102),
        Subdued = C(70, 67, 80), TextDisabled = C(77, 74, 87), Accent = C(153, 146, 184),
        Thumb = C(248, 247, 246), Danger = C(221, 111, 123), Warning = C(221, 181, 111),
        Success = C(128, 190, 151), Info = C(142, 165, 221),
    },
    ["Crimson"] = {
        Background = C(14, 10, 13), Sidebar = C(17, 11, 15), SidebarSelected = C(29, 15, 20),
        Surface = C(22, 13, 18), SurfaceRaised = C(34, 18, 25), Row = C(22, 13, 18),
        Hover = C(37, 20, 27), Pressed = C(48, 23, 31), Stroke = C(69, 35, 43),
        Divider = C(31, 18, 22), Track = C(38, 22, 28), Text = C(242, 232, 235),
        TextSecondary = C(190, 167, 174), TextMuted = C(119, 86, 96), NavMuted = C(101, 72, 82),
        Subdued = C(78, 52, 61), TextDisabled = C(88, 60, 69), Accent = C(225, 84, 96),
        Thumb = C(251, 246, 247), Danger = C(236, 84, 98), Warning = C(227, 174, 94),
        Success = C(123, 194, 148), Info = C(142, 161, 224),
    },
    ["OLED"] = {
        Background = C(4, 4, 5), Sidebar = C(6, 6, 8), SidebarSelected = C(13, 12, 16),
        Surface = C(8, 8, 10), SurfaceRaised = C(15, 14, 18), Row = C(8, 8, 10),
        Hover = C(17, 16, 21), Pressed = C(24, 21, 28), Stroke = C(37, 34, 42),
        Divider = C(14, 14, 17), Track = C(19, 18, 22), Text = C(238, 236, 240),
        TextSecondary = C(171, 167, 178), TextMuted = C(88, 84, 97), NavMuted = C(75, 71, 84),
        Subdued = C(52, 49, 60), TextDisabled = C(60, 56, 67), Accent = C(202, 112, 113),
        Thumb = C(250, 249, 248), Danger = C(229, 113, 122), Warning = C(222, 178, 108),
        Success = C(128, 194, 155), Info = C(140, 163, 224),
    },
}
local ThemePresetOrder = { "JetZ Dark", "Graphite", "Crimson", "OLED" }

local SystemLocales: Payload = {
    English = {},
    ["Español"] = {
        ["Configs"] = "Configuraciones",
        ["Appearance"] = "Apariencia",
        ["Community"] = "Comunidad",
        ["About"] = "Acerca de",
        ["Interface"] = "Interfaz",
        ["Window behavior and everyday controls."] = "Comportamiento de la ventana y controles de uso diario.",
        ["Show sidebar"] = "Mostrar barra lateral",
        ["UI scale"] = "Escala de interfaz",
        ["Animation speed"] = "Velocidad de animación",
        ["Behavior"] = "Comportamiento",
        ["Shortcuts, visibility and optional visual effects."] = "Atajos, visibilidad y efectos visuales opcionales.",
        ["Window shortcut"] = "Atajo de ventana",
        ["Shortcut key"] = "Tecla de atajo",
        ["Watermark"] = "Marca de agua",
        ["Ambient particles"] = "Partículas ambientales",
        ["Particle style"] = "Estilo de partículas",
        ["Particle count"] = "Cantidad de partículas",
        ["Profiles"] = "Perfiles",
        ["Save, load and organize complete JetZ configurations."] = "Guarda, carga y organiza configuraciones completas de JetZ.",
        ["Profile status"] = "Estado del perfil",
        ["Startup"] = "Inicio",
        ["Saved config"] = "Configuración guardada",
        ["Config name"] = "Nombre de configuración",
        ["Create config"] = "Crear configuración",
        ["Save config"] = "Guardar configuración",
        ["Load config"] = "Cargar configuración",
        ["Manage"] = "Administrar",
        ["Rename, duplicate, delete or rescan configs."] = "Renombra, duplica, elimina o vuelve a escanear configuraciones.",
        ["Rename config"] = "Renombrar configuración",
        ["Duplicate config"] = "Duplicar configuración",
        ["Delete config"] = "Eliminar configuración",
        ["Refresh configs"] = "Actualizar configuraciones",
        ["Autoload"] = "Carga automática",
        ["Restore one saved config automatically for this game."] = "Restaura automáticamente una configuración guardada para este juego.",
        ["Set autoload"] = "Activar carga automática",
        ["Disable autoload"] = "Desactivar carga automática",
        ["Import & Export"] = "Importar y exportar",
        ["Transfer configs using the clipboard or the public profile API."] = "Transfiere configuraciones mediante el portapapeles o la API pública de perfiles.",
        ["Export config"] = "Exportar configuración",
        ["Import config"] = "Importar configuración",
        ["Theme"] = "Tema",
        ["Choose a preset, then fine-tune accent and contrast."] = "Elige un preset y después ajusta el acento y el contraste.",
        ["Theme presets"] = "Presets de tema",
        ["Accent color"] = "Color de acento",
        ["Contrast"] = "Contraste",
        ["Language"] = "Idioma",
        ["Language preference for JetZ system surfaces."] = "Idioma de las superficies del sistema JetZ.",
        ["Interface language"] = "Idioma de la interfaz",
        ["Localization"] = "Localización",
        ["This selector is reserved for JetZ system surfaces; labels supplied by scripts remain exactly as authored."] = "Este selector cambia los textos del sistema JetZ; los textos definidos por scripts permanecen sin cambios.",
        ["JetZ Premium"] = "JetZ Premium",
        ["Premium access and the JetZ community."] = "Acceso premium y comunidad de JetZ.",
        ["Plans"] = "Planes",
        ["Community"] = "Comunidad",
        ["Updates, support and feedback."] = "Actualizaciones, soporte y comentarios.",
        ["Discord"] = "Discord",
        ["About JetZ"] = "Acerca de JetZ",
        ["Library information and safe recovery actions."] = "Información de la librería y acciones seguras de recuperación.",
        ["Version"] = "Versión",
        ["Center window"] = "Centrar ventana",
        ["Reset appearance"] = "Restablecer apariencia",
        ["Active:"] = "Activo:",
        ["Unsaved changes"] = "Cambios sin guardar",
        ["Autoload:"] = "Carga automática:",
        ["Off"] = "Desactivada",
        ["Join the JetZ Community"] = "Únete a la comunidad JetZ",
        ["Share feedback, get support, see updates, and connect with other JetZ users."] = "Comparte comentarios, recibe soporte, mira novedades y conecta con otros usuarios de JetZ.",
        ["Join Community"] = "Unirse a la comunidad",
        ["Get Lifetime"] = "Obtener Lifetime",
        ["Get Monthly"] = "Obtener mensual",
        ["Lifetime"] = "De por vida",
        ["Monthly"] = "Mensual",
        ["All premium features"] = "Todas las funciones premium",
        ["Lifetime updates"] = "Actualizaciones de por vida",
        ["Continuous updates"] = "Actualizaciones continuas",
        ["Priority support"] = "Soporte prioritario",
        ["Support future development"] = "Apoya el desarrollo futuro",
    },
    ["Português"] = {
        ["Configs"] = "Configurações",
        ["Appearance"] = "Aparência",
        ["Community"] = "Comunidade",
        ["About"] = "Sobre",
        ["Interface"] = "Interface",
        ["Window behavior and everyday controls."] = "Comportamento da janela e controles do dia a dia.",
        ["Show sidebar"] = "Mostrar barra lateral",
        ["UI scale"] = "Escala da interface",
        ["Animation speed"] = "Velocidade da animação",
        ["Behavior"] = "Comportamento",
        ["Shortcuts, visibility and optional visual effects."] = "Atalhos, visibilidade e efeitos visuais opcionais.",
        ["Window shortcut"] = "Atalho da janela",
        ["Shortcut key"] = "Tecla de atalho",
        ["Watermark"] = "Marca d'água",
        ["Ambient particles"] = "Partículas ambientes",
        ["Particle style"] = "Estilo das partículas",
        ["Particle count"] = "Quantidade de partículas",
        ["Profiles"] = "Perfis",
        ["Save, load and organize complete JetZ configurations."] = "Salve, carregue e organize configurações completas do JetZ.",
        ["Profile status"] = "Status do perfil",
        ["Startup"] = "Inicialização",
        ["Saved config"] = "Configuração salva",
        ["Config name"] = "Nome da configuração",
        ["Create config"] = "Criar configuração",
        ["Save config"] = "Salvar configuração",
        ["Load config"] = "Carregar configuração",
        ["Manage"] = "Gerenciar",
        ["Rename, duplicate, delete or rescan configs."] = "Renomeie, duplique, exclua ou reescaneie configurações.",
        ["Rename config"] = "Renomear configuração",
        ["Duplicate config"] = "Duplicar configuração",
        ["Delete config"] = "Excluir configuração",
        ["Refresh configs"] = "Atualizar configurações",
        ["Autoload"] = "Carregamento automático",
        ["Restore one saved config automatically for this game."] = "Restaure automaticamente uma configuração salva para este jogo.",
        ["Set autoload"] = "Ativar carregamento automático",
        ["Disable autoload"] = "Desativar carregamento automático",
        ["Import & Export"] = "Importar e exportar",
        ["Transfer configs using the clipboard or the public profile API."] = "Transfira configurações usando a área de transferência ou a API pública de perfis.",
        ["Export config"] = "Exportar configuração",
        ["Import config"] = "Importar configuração",
        ["Theme"] = "Tema",
        ["Choose a preset, then fine-tune accent and contrast."] = "Escolha um preset e ajuste o destaque e o contraste.",
        ["Theme presets"] = "Presets de tema",
        ["Accent color"] = "Cor de destaque",
        ["Contrast"] = "Contraste",
        ["Language"] = "Idioma",
        ["Language preference for JetZ system surfaces."] = "Idioma das superfícies do sistema JetZ.",
        ["Interface language"] = "Idioma da interface",
        ["Localization"] = "Localização",
        ["This selector is reserved for JetZ system surfaces; labels supplied by scripts remain exactly as authored."] = "Este seletor altera os textos do sistema JetZ; textos definidos por scripts permanecem inalterados.",
        ["JetZ Premium"] = "JetZ Premium",
        ["Premium access and the JetZ community."] = "Acesso premium e comunidade JetZ.",
        ["Plans"] = "Planos",
        ["Community"] = "Comunidade",
        ["Updates, support and feedback."] = "Atualizações, suporte e feedback.",
        ["Discord"] = "Discord",
        ["About JetZ"] = "Sobre o JetZ",
        ["Library information and safe recovery actions."] = "Informações da biblioteca e ações seguras de recuperação.",
        ["Version"] = "Versão",
        ["Center window"] = "Centralizar janela",
        ["Reset appearance"] = "Redefinir aparência",
        ["Active:"] = "Ativo:",
        ["Unsaved changes"] = "Alterações não salvas",
        ["Autoload:"] = "Carregamento automático:",
        ["Off"] = "Desativado",
        ["Join the JetZ Community"] = "Entre na comunidade JetZ",
        ["Share feedback, get support, see updates, and connect with other JetZ users."] = "Compartilhe feedback, receba suporte, veja novidades e conecte-se com outros usuários do JetZ.",
        ["Join Community"] = "Entrar na comunidade",
        ["Get Lifetime"] = "Obter Lifetime",
        ["Get Monthly"] = "Obter mensal",
        ["Lifetime"] = "Vitalício",
        ["Monthly"] = "Mensal",
        ["All premium features"] = "Todos os recursos premium",
        ["Lifetime updates"] = "Atualizações vitalícias",
        ["Continuous updates"] = "Atualizações contínuas",
        ["Priority support"] = "Suporte prioritário",
        ["Support future development"] = "Apoie o desenvolvimento futuro",
    },
}
local SystemLocaleOrder = { "English", "Español", "Português" }

local FACE = Font.fromEnum(Enum.Font.RobotoMono)
local MEDIUM = Font.new(FACE.Family, Enum.FontWeight.Medium)
local BOLD = Font.new(FACE.Family, Enum.FontWeight.Bold)
local Pointer: any = nil
local Capturing: any = nil
local roots: Payload = setmetatable({}, { __mode = "k" })

function U.finite(x: any): boolean
    return type(x) == "number" and x == x and x > -math.huge and x < math.huge
end

function U.number(x: any, default: number): number
    return if U.finite(x) then x else default
end

function U.str(x: any, default: string?): string
    if type(x) ~= "string" then
        return default or ""
    end
    if utf8.len(x) == nil then
        return default or ""
    end
    return x
end

function U.cut(s: string, n: number): string
    local i = utf8.offset(s, n + 1)
    return if i then string.sub(s, 1, i - 1) else s
end

function U.measure(s: string, size: number): number
    return math.ceil((utf8.len(s) or #s) * size * 0.607)
end

function U.cfg(c: any): Payload
    if type(c) == "table" then
        return c
    end
    if type(c) == "string" then
        return { Name = c }
    end
    return {}
end

local ExecutorAliases: Payload = {
    setclipboard = { "setclipboard", "toclipboard", "writeclipboard" },
    getclipboard = { "getclipboard", "readclipboard" },
    isfolder = { "isfolder", "is_folder" },
    makefolder = { "makefolder", "make_folder" },
    isfile = { "isfile", "is_file" },
    readfile = { "readfile", "read_file" },
    writefile = { "writefile", "write_file" },
    delfile = { "delfile", "deletefile", "delete_file" },
    listfiles = { "listfiles", "list_files" },
}
local ExecutorNamespaces = { "syn", "filesystem", "fs", "clipboard" }

function U.executorEnvironments(): { any }
    local out, seen = {}, {}
    local function add(env: any)
        if type(env) == "table" and not seen[env] then
            seen[env] = true
            table.insert(out, env)
        end
    end

    add(_G)

    local base = nil
    local okBase, baseEnv = pcall(getfenv, 0)
    if okBase then
        base = baseEnv
        add(baseEnv)
    end

    local getGlobal = (type(base) == "table" and rawget(base, "getgenv")) or nil
    if type(getGlobal) ~= "function" then
        local ok, candidate = pcall(function()
            return getgenv
        end)
        if ok and type(candidate) == "function" then
            getGlobal = candidate
        end
    end
    if type(getGlobal) == "function" then
        local ok, env = pcall(getGlobal)
        if ok then add(env) end
    end

    local getRuntime = (type(base) == "table" and rawget(base, "getrenv")) or nil
    if type(getRuntime) ~= "function" then
        local ok, candidate = pcall(function()
            return getrenv
        end)
        if ok and type(candidate) == "function" then
            getRuntime = candidate
        end
    end
    if type(getRuntime) == "function" then
        local ok, env = pcall(getRuntime)
        if ok then add(env) end
    end

    local okLocal, localEnv = pcall(getfenv)
    if okLocal then add(localEnv) end
    return out
end

function U.resolveExecutor(name: string): (any, string?)
    local aliases = ExecutorAliases[name] or { name }
    local environments = U.executorEnvironments()

    for _, env in environments do
        for _, alias in aliases do
            local ok, value = pcall(function()
                return env[alias]
            end)
            if ok and type(value) == "function" then
                return value, "global:" .. alias
            end
        end
        for _, namespaceName in ExecutorNamespaces do
            local okNamespace, namespace = pcall(function()
                return env[namespaceName]
            end)
            if okNamespace and type(namespace) == "table" then
                for _, alias in aliases do
                    local ok, value = pcall(function()
                        return namespace[alias]
                    end)
                    if ok and type(value) == "function" then
                        return value, namespaceName .. "." .. alias
                    end
                end
            end
        end
    end

    -- Some executors expose injected globals to normal global lookup but not through
    -- _G/getgenv/getfenv tables. Resolve those names through the executor compiler.
    local loader = nil
    for _, env in environments do
        local ok, candidate = pcall(function()
            return env.loadstring
        end)
        if ok and type(candidate) == "function" then
            loader = candidate
            break
        end
    end
    if not loader then
        local ok, candidate = pcall(function()
            return loadstring
        end)
        if ok and type(candidate) == "function" then
            loader = candidate
        end
    end
    if type(loader) == "function" then
        for _, alias in aliases do
            if alias:match("^[%a_][%w_]*$") then
                local compiledOK, chunk = pcall(loader, "return " .. alias)
                if compiledOK and type(chunk) == "function" then
                    local runOK, value = pcall(chunk)
                    if runOK and type(value) == "function" then
                        return value, "loadstring:" .. alias
                    end
                end
            end
        end
    end

    return nil, nil
end

function U.global(name: string): any
    local value = U.resolveExecutor(name)
    return value
end

function U.copyText(value: string): boolean
    local fn = U.resolveExecutor("setclipboard")
    if type(fn) ~= "function" then
        return false
    end
    local ok = pcall(fn, value)
    return ok
end

function U.readClipboard(): string?
    local fn = U.resolveExecutor("getclipboard")
    if type(fn) ~= "function" then
        return nil
    end
    local ok, value = pcall(fn)
    return if ok and type(value) == "string" then value else nil
end

function U.copy(v: any): any
    if type(v) == "table" then
        return table.clone(v)
    end
    return v
end

function U.same(a: any, b: any): boolean
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    for k, v in a do
        if b[k] ~= v then
            return false
        end
    end
    for k in b do
        if a[k] == nil then
            return false
        end
    end
    return true
end

function U.point(i: InputObject): Vector2
    return V(i.Position.X, i.Position.Y)
end

function U.inside(obj: any, point: Vector2): boolean
    if not obj or not obj.Parent then
        return false
    end
    local p, s = obj.AbsolutePosition, obj.AbsoluteSize
    return point.X >= p.X and point.Y >= p.Y and point.X < p.X + s.X and point.Y < p.Y + s.Y
end

function U.hitType(i: InputObject): boolean
    return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1
end

function U.guiVisible(obj: any): boolean
    while obj do
        if obj:IsA("GuiObject") and not obj.Visible then
            return false
        end
        if obj:IsA("ScreenGui") then
            return obj.Enabled and obj.Parent ~= nil
        end
        obj = obj.Parent
    end
    return false
end

function U.anchorVisible(obj: any, safe: any): boolean
    if not U.guiVisible(obj) then
        return false
    end
    local a, b = obj.AbsolutePosition, obj.AbsolutePosition + obj.AbsoluteSize
    local ancestor = obj.Parent
    while ancestor do
        if ancestor == safe or (ancestor:IsA("GuiObject") and ancestor.ClipsDescendants) then
            local p, q = ancestor.AbsolutePosition, ancestor.AbsolutePosition + ancestor.AbsoluteSize
            a, b = V(math.max(a.X, p.X), math.max(a.Y, p.Y)), V(math.min(b.X, q.X), math.min(b.Y, q.Y))
            if b.X <= a.X or b.Y <= a.Y then
                return false
            end
        end
        if ancestor == safe then
            break
        end
        ancestor = ancestor.Parent
    end
    return true
end

function U.key(x: any): (boolean, any)
    if x == nil or x == Enum.KeyCode.Unknown then
        return true, nil
    end
    if type(x) == "string" then
        local ok, item = pcall(function()
            return (Enum.KeyCode :: any)[x]
        end)
        if ok and item then
            return item ~= Enum.KeyCode.Unknown, item
        end
    end
    if
        typeof(x) == "EnumItem"
        and (
            x.EnumType == Enum.KeyCode
            or x == Enum.UserInputType.MouseButton1
            or x == Enum.UserInputType.MouseButton2
            or x == Enum.UserInputType.MouseButton3
        )
    then
        return true, x
    end
    return false, nil
end

function U.inputKey(i: InputObject): any
    if i.KeyCode ~= Enum.KeyCode.Unknown then
        return i.KeyCode
    end
    local ok, key = U.key(i.UserInputType)
    return if ok then key else nil
end

function U.keyText(key: any): string
    if not key then
        return "[NONE]"
    end
    local name = key.Name
    if name == "RightShift" then
        name = "RShift"
    elseif name == "LeftShift" then
        name = "LShift"
    end
    return "[" .. string.upper((string.gsub(name, "^MouseButton", "M"))) .. "]"
end

function U.issue(owner: any, stage: string, problem: any): (false, string)
    local why = tostring(problem)
    local w = owner and (owner._w or owner)
    if not w or w._development ~= false then
        warn(
            ("[JetZUi/%s:%s] %s: %s"):format(
                owner and owner._kind or "Library",
                owner and owner._name or "",
                stage,
                why
            )
        )
    end
    return false, why
end

function U.call(owner: any, stage: string, callback: any, ...: any): (boolean, any)
    if type(callback) ~= "function" then
        return true, nil
    end
    local ok, value = pcall(callback, ...)
    if not ok then
        U.issue(owner, stage, value)
    end
    return ok, value
end

function U.sort(list: { any }): { any }
    local sorted = table.clone(list)
    table.sort(sorted, function(a, b)
        return if a._order == b._order then a._sequence < b._sequence else a._order < b._order
    end)
    return sorted
end

function U.remove(list: { any }, item: any)
    local i = table.find(list, item)
    if i then
        table.remove(list, i)
    end
end

-- Cleanup scopes use keyed slots so cancelled timers/tweens/option lists do not accumulate.
P.Scope = {}
P.Scope.__index = P.Scope

function U.scope(): any
    return setmetatable({ _items = {}, _dead = false }, P.Scope)
end

function U.dispose(x: any)
    local kind = typeof(x)
    if kind == "RBXScriptConnection" then
        x:Disconnect()
    elseif kind == "Instance" then
        x:Destroy()
    elseif kind == "function" then
        x()
    elseif kind == "thread" then
        if x ~= coroutine.running() and coroutine.status(x) ~= "dead" then
            task.cancel(x)
        end
    elseif type(x) == "table" and type(x.Destroy) == "function" then
        x:Destroy()
    elseif type(x) == "table" and type(x.Disconnect) == "function" then
        x:Disconnect()
    end
end

function P.Scope:Give(item: any, key: any?): any
    if item == nil then
        return nil
    end
    if self._dead then
        pcall(U.dispose, item)
        return item
    end
    key = key or item
    if self._items[key] ~= item then
        self:Remove(key)
        self._items[key] = item
    end
    return item
end

function P.Scope:Forget(key: any)
    self._items[key] = nil
end

function P.Scope:Remove(key: any)
    local item = self._items[key]
    self._items[key] = nil
    if item ~= nil then
        local ok, err = pcall(U.dispose, item)
        if not ok then
            U.issue(nil, "cleanup", err)
        end
    end
end

function P.Scope:Destroy()
    if self._dead then
        return
    end
    self._dead = true
    for key in self._items do
        self:Remove(key)
    end
end

function U.later(owner: any, scope: any, key: any, seconds: number?, fn: () -> ())
    scope:Remove(key)
    local function fire()
        scope:Forget(key)
        if not scope._dead and not owner._dead then
            U.call(owner, "deferred task", fn)
        end
    end
    scope:Give(if seconds then task.delay(seconds, fire) else task.defer(fire), key)
end

P.Signal = {}
P.Signal.__index = P.Signal

function U.signal(owner: any, label: string): any
    return setmetatable({ _list = {}, _owner = owner, _label = label, _dead = false }, P.Signal)
end

function P.Signal:Connect(fn: any): Connection
    local signal = self
    local connection: any = { Connected = not self._dead and type(fn) == "function" }
    function connection:Disconnect()
        if not self.Connected then
            return
        end
        self.Connected = false
        U.remove(signal._list, self)
        self._fn = nil
    end
    if connection.Connected then
        connection._fn = fn
        table.insert(self._list, connection)
    elseif type(fn) ~= "function" then
        U.issue(self._owner, self._label, "expected a listener function")
    end
    return connection
end

function P.Signal:Once(fn: any): Connection
    if type(fn) ~= "function" then
        return self:Connect(fn)
    end
    local connection: Connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        return fn(...)
    end)
    return connection
end

function P.Signal:_fire(...: any)
    if self._dead or #self._list == 0 then
        return
    end
    for _, connection in table.clone(self._list) do
        if connection.Connected then
            U.call(self._owner, self._label, connection._fn, ...)
        end
    end
end

function P.Signal:Fire(...: any)
    self:_fire(...)
end

function P.Signal:Destroy()
    if self._dead then
        return
    end
    self._dead = true
    for _, connection in self._list do
        connection.Connected = false
        connection._fn = nil
    end
    table.clear(self._list)
end

function U.event(owner: any, name: string): any
    local event = owner._events[name]
    if not event then
        event = U.signal(owner, name)
        owner._events[name] = event
        owner._life:Give(event)
    end
    return event
end

function U.emit(owner: any, name: string, ...: any)
    local signal = owner._events[name]
    if signal then
        signal:_fire(...)
    end
end

P.Theme = {}
P.Theme.__index = P.Theme

function U.color(x: any): boolean
    return typeof(x) == "Color3"
        and U.finite(x.R)
        and U.finite(x.G)
        and U.finite(x.B)
        and x.R >= 0
        and x.R <= 1
        and x.G >= 0
        and x.G <= 1
        and x.B >= 0
        and x.B <= 1
end

function U.luma(c: Color3): number
    local function channel(n: number): number
        return if n <= 0.04045 then n / 12.92 else ((n + 0.055) / 1.055) ^ 2.4
    end
    return 0.2126 * channel(c.R) + 0.7152 * channel(c.G) + 0.0722 * channel(c.B)
end

function P.Theme:_apply()
    local b, contrast = self._base, self._contrast
    local c = table.clone(b)
    local k = contrast - 1
    for _, role in
        { "SidebarSelected", "Surface", "SurfaceRaised", "Row", "Hover", "Pressed", "Stroke", "Divider", "Track" }
    do
        local v = b[role]
        if k < 0 then
            c[role] = v:Lerp(b.Background, -k * 0.69)
        else
            c[role] = v:Lerp(White, k * (if role == "Stroke" then 0.115 else 0.054))
        end
    end
    if k > 0 then
        c.TextMuted = c.TextMuted:Lerp(c.Text, k * 0.47)
        c.TextDisabled = c.TextDisabled:Lerp(c.TextSecondary, k * 0.32)
        c.NavMuted = c.NavMuted:Lerp(c.TextSecondary, k * 0.56)
        c.Subdued = c.Subdued:Lerp(c.TextSecondary, k * 0.47)
    end
    c.AccentMuted = c.SurfaceRaised:Lerp(c.Accent, 0.23)
    c.AccentInk = if U.luma(c.Accent) > 0.179 then C(14, 12, 17) else White
    self._colors = c
    for binding in self._bindings do
        binding()
    end
end

function U.theme(colors: any, accent: any): any
    local b: Payload = table.clone(D.Colors)
    if type(colors) == "table" then
        for k, v in colors do
            if b[k] and U.color(v) then
                b[k] = v
            end
        end
    end
    if U.color(accent) then
        b.Accent = accent
    end
    local t = setmetatable({ _base = b, _bindings = {}, _contrast = 1, _colors = {} }, P.Theme)
    t:_apply()
    return t
end

function U.paint(w: any, scope: any, obj: any, prop: string, token: any): () -> ()
    local t = w._theme
    local update = function()
        local colors = t._colors
        local v = if type(token) == "function" then token(colors) else colors[token]
        if v and obj[prop] ~= v then
            obj[prop] = v
        end
    end
    t._bindings[update] = true
    scope:Give(function()
        t._bindings[update] = nil
    end)
    update()
    return update
end

function U.make(class: string, parent: Instance?, props: Payload?): any
    local obj: any = Instance.new(class)
    if obj:IsA("GuiObject") then
        obj.BackgroundTransparency = 1
        obj.BorderSizePixel = 0
        obj.AutoLocalize = false
    end
    if props then
        for k, v in props do
            obj[k] = v
        end
    end
    obj.Parent = parent
    return obj
end

function U.frame(parent: Instance?, props: Payload?): Frame
    return U.make("Frame", parent, props)
end

function U.corner(obj: GuiObject, radius: number)
    U.make("UICorner", obj, { CornerRadius = UDim.new(0, radius) })
end

function U.text(w: any, scope: any, parent: Instance, role: string, text: string, color: any, props: Payload?): any
    local obj = U.make("TextLabel", parent, {
        Text = text,
        FontFace = if role == "Brand" then BOLD elseif role == "Tooltip" or role == "Muted" then FACE else MEDIUM,
        TextSize = D.Typography[role] or D.Typography.Control,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = S(1, 1),
        Name = role,
    })
    if props then
        for k, v in props do
            obj[k] = v
        end
    end
    local refresh = U.paint(w, scope, obj, "TextColor3", color)
    return obj, refresh
end

function U.fill(w: any, scope: any, obj: GuiObject, token: any): () -> ()
    obj.BackgroundTransparency = 0
    return U.paint(w, scope, obj, "BackgroundColor3", token)
end

function U.line(w: any, scope: any, parent: Instance, token: any, props: Payload): Frame
    local f = U.frame(parent, props)
    U.fill(w, scope, f, token)
    return f
end

function U.layout(parent: Instance, gap: number?): UIListLayout
    return U.make("UIListLayout", parent, { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, gap or 0) })
end

function U.padding(parent: Instance, x: number, y: number)
    U.make("UIPadding", parent, {
        PaddingLeft = UDim.new(0, x),
        PaddingRight = UDim.new(0, x),
        PaddingTop = UDim.new(0, y),
        PaddingBottom = UDim.new(0, y),
    })
end

function U.tween(w: any, life: any, object: Instance, slot: string, token: string, goals: Payload, instant: boolean?)
    life:Remove(slot)
    local time = D.Animation[token]
    if not time or instant or w._speed <= 0 then
        for k, v in goals do
            (object :: any)[k] = v
        end
        return
    end
    local t =
        Tweens:Create(object, TweenInfo.new(time / w._speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goals)
    local done: RBXScriptConnection?
    local function release()
        if done then
            done:Disconnect()
            done = nil
        end
        t:Cancel()
        t:Destroy()
    end
    done = t.Completed:Connect(function()
        life:Forget(slot)
        if done then
            done:Disconnect()
            done = nil
        end
        t:Destroy()
    end)
    life:Give(release, slot)
    t:Play()
end

-- Small path icons use frames rather than web fonts or opaque third-party asset bundles.
local Icons: Payload = {
    brand = {
        { 0.50, 0.07, 0.20, 0.50, 4.1 },
        { 0.20, 0.50, 0.50, 0.93, 4.1 },
        { 0.59, 0.28, 0.77, 0.50, 4.8 },
        {
            0.77,
            0.50,
            0.59,
            0.72,
            4.8,
        },
    },
    cross = {
        { 0.49, 0.10, 0.49, 0.36 },
        { 0.49, 0.64, 0.49, 0.90 },
        { 0.10, 0.49, 0.36, 0.49 },
        {
            0.64,
            0.49,
            0.90,
            0.49,
        },
    },
    lens = {
        { 0.14, 0.34, 0.14, 0.16 },
        { 0.14, 0.16, 0.33, 0.16 },
        { 0.67, 0.16, 0.86, 0.16 },
        { 0.86, 0.16, 0.86, 0.34 },
        { 0.86, 0.66, 0.86, 0.84 },
        { 0.86, 0.84, 0.67, 0.84 },
        { 0.33, 0.84, 0.14, 0.84 },
        { 0.14, 0.84, 0.14, 0.66 },
        { 0.42, 0.50, 0.58, 0.50, 2.5 },
    },
    edit = { { 0.22, 0.73, 0.68, 0.27, 2.2 }, { 0.66, 0.28, 0.77, 0.39, 1.5 }, { 0.21, 0.73, 0.37, 0.70 } },
    trash = {
        { 0.20, 0.29, 0.80, 0.29 },
        { 0.39, 0.18, 0.61, 0.18 },
        { 0.28, 0.36, 0.32, 0.79 },
        { 0.32, 0.79, 0.68, 0.79 },
        { 0.68, 0.79, 0.72, 0.36 },
        { 0.43, 0.41, 0.43, 0.68 },
        { 0.57, 0.41, 0.57, 0.68 },
    },
    eye = {
        { 0.10, 0.50, 0.33, 0.27 },
        { 0.33, 0.27, 0.67, 0.27 },
        { 0.67, 0.27, 0.90, 0.50 },
        { 0.90, 0.50, 0.67, 0.73 },
        { 0.67, 0.73, 0.33, 0.73 },
        { 0.33, 0.73, 0.10, 0.50 },
        { 0.42, 0.50, 0.58, 0.50, 2 },
    },
    box = {
        { 0.18, 0.18, 0.82, 0.18 },
        { 0.82, 0.18, 0.82, 0.82 },
        { 0.82, 0.82, 0.18, 0.82 },
        { 0.18, 0.82, 0.18, 0.18 },
    },
    layers = {
        { 0.12, 0.35, 0.50, 0.16 },
        { 0.50, 0.16, 0.88, 0.35 },
        { 0.88, 0.35, 0.50, 0.54 },
        { 0.50, 0.54, 0.12, 0.35 },
        { 0.12, 0.59, 0.50, 0.80 },
        { 0.50, 0.80, 0.88, 0.59 },
    },
    gear = {
        { 0.33, 0.24, 0.67, 0.24 },
        { 0.67, 0.24, 0.82, 0.50 },
        { 0.82, 0.50, 0.67, 0.76 },
        { 0.67, 0.76, 0.33, 0.76 },
        { 0.33, 0.76, 0.18, 0.50 },
        { 0.18, 0.50, 0.33, 0.24 },
        { 0.43, 0.50, 0.57, 0.50, 1.2 },
    },
    menu = { { 0.14, 0.27, 0.86, 0.27 }, { 0.14, 0.50, 0.86, 0.50 }, { 0.14, 0.73, 0.86, 0.73 } },
    close = { { 0.22, 0.22, 0.78, 0.78 }, { 0.78, 0.22, 0.22, 0.78 } },
    down = { { 0.20, 0.36, 0.50, 0.65 }, { 0.50, 0.65, 0.80, 0.36 } },
    right = { { 0.35, 0.22, 0.65, 0.50 }, { 0.65, 0.50, 0.35, 0.78 } },
    left = { { 0.65, 0.22, 0.35, 0.50 }, { 0.35, 0.50, 0.65, 0.78 } },
    check = { { 0.18, 0.51, 0.41, 0.73, 1.5 }, { 0.41, 0.73, 0.81, 0.28, 1.5 } },
    more = { { 0.18, 0.50, 0.25, 0.50, 2 }, { 0.47, 0.50, 0.54, 0.50, 2 }, { 0.75, 0.50, 0.82, 0.50, 2 } },
    plus = { { 0.50, 0.18, 0.50, 0.82 }, { 0.18, 0.50, 0.82, 0.50 } },
    minus = { { 0.18, 0.50, 0.82, 0.50 } },
    resize = { { 0.22, 0.80, 0.80, 0.22 }, { 0.50, 0.80, 0.80, 0.50 } },
    resizeGrip = {
        { 0.15, 0.77, 0.77, 0.15, 1.45 },
        { 0.42, 0.85, 0.85, 0.42, 1.45 },
        { 0.69, 0.89, 0.89, 0.69, 1.45 },
    },
    info = { { 0.50, 0.20, 0.50, 0.26, 1.5 }, { 0.50, 0.40, 0.50, 0.80, 1.5 } },
}
-- Canonical Lucide icons for Tabs/SubTabs and any component that uses U.icon.
-- Asset mappings come from LucideBlox; existing hand-drawn JetZ icons remain untouched.
local imageIcons: Payload = {
    ["settings"] = { Image = "rbxassetid://7734053495" },
    ["crown"] = { Image = "rbxassetid://7733765398" },
    ["coins"] = { Image = "rbxassetid://7743866529" },
    ["gamepad"] = { Image = "rbxassetid://7733799901" },
    ["gift"] = { Image = "rbxassetid://7733946818" },
    ["globe"] = { Image = "rbxassetid://7733954760" },
    ["home"] = { Image = "rbxassetid://7733960981" },
    ["image"] = { Image = "rbxassetid://7733964126" },
    ["alert-triangle"] = { Image = "rbxassetid://7733658504" },
    ["package-search"] = { Image = "rbxassetid://8997386448" },
    ["pencil"] = { Image = "rbxassetid://7734022107" },
    ["bluetooth"] = { Image = "rbxassetid://7733687147" },
    ["person-standing"] = { Image = "rbxassetid://7743871002" },
    ["tornado"] = { Image = "rbxassetid://7743873633" },
    ["headphones"] = { Image = "rbxassetid://7733956063" },
    ["qr-code"] = { Image = "rbxassetid://7743871575" },
    ["rewind"] = { Image = "rbxassetid://7734051670" },
    ["save"] = { Image = "rbxassetid://7734052335" },
    ["help-circle"] = { Image = "rbxassetid://7733956210" },
    ["phone"] = { Image = "rbxassetid://7734032056" },
    ["star"] = { Image = "rbxassetid://7734068321" },
    ["sun"] = { Image = "rbxassetid://7734068495" },
    ["gem"] = { Image = "rbxassetid://7733942651" },
    ["terminal"] = { Image = "rbxassetid://7743872929" },
    ["megaphone"] = { Image = "rbxassetid://7733993049" },
    ["unlock"] = { Image = "rbxassetid://7743875263" },
    ["camera"] = { Image = "rbxassetid://7733708692" },
    ["truck"] = { Image = "rbxassetid://7743874482" },
    ["gamepad-2"] = { Image = "rbxassetid://7733799795" },
    ["network"] = { Image = "rbxassetid://7734021047" },
    ["users"] = { Image = "rbxassetid://7743876054" },
    ["book"] = { Image = "rbxassetid://7733914390" },
    ["locate-fixed"] = { Image = "rbxassetid://7733992424" },
    ["bar-chart"] = { Image = "rbxassetid://7733674319" },
    ["shield-check"] = { Image = "rbxassetid://7734056411" },
    ["zoom-in"] = { Image = "rbxassetid://7743878977" },
    ["database"] = { Image = "rbxassetid://7743866778" },
    ["target"] = { Image = "rbxassetid://7743872758" },
    ["skip-back"] = { Image = "rbxassetid://7734058404" },
    ["inbox"] = { Image = "rbxassetid://7733964370" },
    ["shovel"] = { Image = "rbxassetid://7734056878" },
    ["file-text"] = { Image = "rbxassetid://7733789088" },
    ["timer"] = { Image = "rbxassetid://7743873443" },
    ["clipboard-check"] = { Image = "rbxassetid://7733919947" },
    ["user-check"] = { Image = "rbxassetid://7743875503" },
    ["copy"] = { Image = "rbxassetid://7733764083" },
    ["bot"] = { Image = "rbxassetid://7733916988" },
    ["upload"] = { Image = "rbxassetid://7743875428" },
    ["graduation-cap"] = { Image = "rbxassetid://7733955058" },
    ["plane"] = { Image = "rbxassetid://7734037723" },
    ["scissors"] = { Image = "rbxassetid://7734052570" },
    ["search"] = { Image = "rbxassetid://7734052925" },
    ["file"] = { Image = "rbxassetid://7733793319" },
    ["gauge"] = { Image = "rbxassetid://7733799969" },
    ["shield-alert"] = { Image = "rbxassetid://7734056326" },
    ["axe"] = { Image = "rbxassetid://7733674079" },
    ["radio"] = { Image = "rbxassetid://7743871662" },
    ["trending-down"] = { Image = "rbxassetid://7743874143" },
    ["eye-off"] = { Image = "rbxassetid://7733774495" },
    ["folder-plus"] = { Image = "rbxassetid://7733799092" },
    ["user-plus"] = { Image = "rbxassetid://7743875759" },
    ["command"] = { Image = "rbxassetid://7733924046" },
    ["map"] = { Image = "rbxassetid://7733992829" },
    ["shuffle"] = { Image = "rbxassetid://7734057059" },
    ["tablet"] = { Image = "rbxassetid://7743872620" },
    ["locate"] = { Image = "rbxassetid://7733992469" },
    ["share"] = { Image = "rbxassetid://7734053697" },
    ["coffee"] = { Image = "rbxassetid://7733752630" },
    ["dollar-sign"] = { Image = "rbxassetid://7733770599" },
    ["code"] = { Image = "rbxassetid://7733749837" },
    ["trending-up"] = { Image = "rbxassetid://7743874262" },
    ["cpu"] = { Image = "rbxassetid://7733765045" },
    ["palette"] = { Image = "rbxassetid://7734021595" },
    ["archive"] = { Image = "rbxassetid://7733911621" },
    ["shopping-bag"] = { Image = "rbxassetid://7734056747" },
    ["navigation"] = { Image = "rbxassetid://7734020989" },
    ["moon"] = { Image = "rbxassetid://7743870134" },
    ["compass"] = { Image = "rbxassetid://7733924216" },
    ["shield"] = { Image = "rbxassetid://7734056608" },
    ["printer"] = { Image = "rbxassetid://7734042580" },
    ["heart"] = { Image = "rbxassetid://7733956134" },
    ["lock"] = { Image = "rbxassetid://7733992528" },
    ["flag"] = { Image = "rbxassetid://7733798691" },
    ["star-half"] = { Image = "rbxassetid://7734068258" },
    ["mountain"] = { Image = "rbxassetid://7734008868" },
    ["volume"] = { Image = "rbxassetid://7743877487" },
    ["speaker"] = { Image = "rbxassetid://7734063416" },
    ["flame"] = { Image = "rbxassetid://7733798747" },
    ["lightbulb"] = { Image = "rbxassetid://7733975185" },
    ["mail"] = { Image = "rbxassetid://7733992732" },
    ["pause"] = { Image = "rbxassetid://7734021897" },
    ["calendar"] = { Image = "rbxassetid://7733919198" },
    ["file-code"] = { Image = "rbxassetid://7733779730" },
    ["video"] = { Image = "rbxassetid://7743876610" },
    ["bell"] = { Image = "rbxassetid://7733911828" },
    ["message-circle"] = { Image = "rbxassetid://7733993311" },
    ["skull"] = { Image = "rbxassetid://7734058599" },
    ["filter"] = { Image = "rbxassetid://7733798407" },
    ["play"] = { Image = "rbxassetid://7743871480" },
    ["bell-ring"] = { Image = "rbxassetid://7733675275" },
    ["crosshair"] = { Image = "rbxassetid://7733765307" },
    ["map-pin"] = { Image = "rbxassetid://7733992789" },
    ["activity"] = { Image = "rbxassetid://7733655755" },
    ["pie-chart"] = { Image = "rbxassetid://7734034378" },
    ["bar-chart-2"] = { Image = "rbxassetid://7733674239" },
    ["wrench"] = { Image = "rbxassetid://7743878358" },
    ["hammer"] = { Image = "rbxassetid://7733955511" },
    ["sprout"] = { Image = "rbxassetid://7743872071" },
    ["carrot"] = { Image = "rbxassetid://8997382987" },
    ["wallet"] = { Image = "rbxassetid://7743877573" },
    ["shopping-cart"] = { Image = "rbxassetid://7734056813" },
    ["car"] = { Image = "rbxassetid://7733708835" },
    ["navigation-2"] = { Image = "rbxassetid://7734020942" },
    ["key"] = { Image = "rbxassetid://7733965118" },
    ["shield-off"] = { Image = "rbxassetid://7734056540" },
    ["user"] = { Image = "rbxassetid://7743875962" },
    ["user-x"] = { Image = "rbxassetid://7743875879" },
    ["user-minus"] = { Image = "rbxassetid://7743875629" },
    ["package-check"] = { Image = "rbxassetid://8997386143" },
    ["package-minus"] = { Image = "rbxassetid://8997386266" },
    ["package-x"] = { Image = "rbxassetid://8997386545" },
    ["piggy-bank"] = { Image = "rbxassetid://7734034513" },
    ["move"] = { Image = "rbxassetid://7743870731" },
    ["move-horizontal"] = { Image = "rbxassetid://7734016210" },
    ["move-vertical"] = { Image = "rbxassetid://7743870608" },
    ["move-diagonal"] = { Image = "rbxassetid://7743870505" },
    ["move-diagonal-2"] = { Image = "rbxassetid://7734013178" },
    ["box-select"] = { Image = "rbxassetid://7733696665" },
    ["clock"] = { Image = "rbxassetid://7733734848" },
    ["aperture"] = { Image = "rbxassetid://7733666258" },
    ["bug"] = { Image = "rbxassetid://7733701545" },
    ["external-link"] = { Image = "rbxassetid://7743866903" },
    ["lightbulb-off"] = { Image = "rbxassetid://7733975123" },
    ["file-check-2"] = { Image = "rbxassetid://7733779610" },
    ["battery"] = { Image = "rbxassetid://7733674820" },
    ["flashlight-off"] = { Image = "rbxassetid://7733798799" },
    ["camera-off"] = { Image = "rbxassetid://7733919260" },
    ["function-square"] = { Image = "rbxassetid://7733799682" },
    ["mountain-snow"] = { Image = "rbxassetid://7743870286" },
    ["hand"] = { Image = "rbxassetid://7733955740" },
    ["hard-hat"] = { Image = "rbxassetid://7733955850" },
    ["hash"] = { Image = "rbxassetid://7733955906" },
    ["server"] = { Image = "rbxassetid://7734053426" },
    ["highlighter"] = { Image = "rbxassetid://7743868648" },
    ["bike"] = { Image = "rbxassetid://7733678330" },
    ["infinity"] = { Image = "rbxassetid://7733964640" },
    ["inspect"] = { Image = "rbxassetid://7733964808" },
    ["pin"] = { Image = "rbxassetid://8997386648" },
    ["monitor-off"] = { Image = "rbxassetid://7734000184" },
    ["more-vertical"] = { Image = "rbxassetid://7734006187" },
    ["package-plus"] = { Image = "rbxassetid://8997386355" },
    ["pen-tool"] = { Image = "rbxassetid://7734022041" },
    ["phone-incoming"] = { Image = "rbxassetid://7743871120" },
    ["phone-off"] = { Image = "rbxassetid://7734029534" },
    ["at-sign"] = { Image = "rbxassetid://7733673907" },
    ["sheet"] = { Image = "rbxassetid://7743871876" },
    ["tv"] = { Image = "rbxassetid://7743874674" },
    ["reply"] = { Image = "rbxassetid://7734051594" },
    ["bell-off"] = { Image = "rbxassetid://7733675107" },
    ["file-check"] = { Image = "rbxassetid://7733779668" },
    ["quote"] = { Image = "rbxassetid://7734045100" },
    ["rotate-ccw"] = { Image = "rbxassetid://7734051861" },
    ["library"] = { Image = "rbxassetid://7743869054" },
    ["on-charge"] = { Image = "rbxassetid://7734021231" },
    ["video-off"] = { Image = "rbxassetid://7743876466" },
    ["screen-share"] = { Image = "rbxassetid://7734052814" },
    ["server-crash"] = { Image = "rbxassetid://7734053281" },
    ["bluetooth-searching"] = { Image = "rbxassetid://7733914320" },
    ["shield-close"] = { Image = "rbxassetid://7734056470" },
    ["type"] = { Image = "rbxassetid://7743874740" },
    ["file-x-2"] = { Image = "rbxassetid://7743867554" },
    ["sidebar"] = { Image = "rbxassetid://7734058260" },
    ["sigma"] = { Image = "rbxassetid://7734058345" },
    ["smartphone-charging"] = { Image = "rbxassetid://7734058894" },
    ["arrow-left"] = { Image = "rbxassetid://7733673136" },
    ["currency"] = { Image = "rbxassetid://7733765592" },
    ["smile"] = { Image = "rbxassetid://7734059095" },
    ["switch-camera"] = { Image = "rbxassetid://7743872492" },
    ["table"] = { Image = "rbxassetid://7734073253" },
    ["tag"] = { Image = "rbxassetid://7734075797" },
    ["link"] = { Image = "rbxassetid://7733978098" },
    ["thermometer-sun"] = { Image = "rbxassetid://7734084018" },
    ["share-2"] = { Image = "rbxassetid://7734053595" },
    ["timer-off"] = { Image = "rbxassetid://8997388325" },
    ["timer-reset"] = { Image = "rbxassetid://7743873336" },
    ["phone-forwarded"] = { Image = "rbxassetid://7734027345" },
    ["triangle"] = { Image = "rbxassetid://7743874367" },
    ["file-output"] = { Image = "rbxassetid://7733788742" },
    ["electricity-off"] = { Image = "rbxassetid://7733771563" },
    ["signal-low"] = { Image = "rbxassetid://8997387189" },
    ["reply-all"] = { Image = "rbxassetid://7734051524" },
    ["ticket"] = { Image = "rbxassetid://7734086558" },
    ["smartphone"] = { Image = "rbxassetid://7734058979" },
    ["arrow-big-right"] = { Image = "rbxassetid://7733671493" },
    ["tv-2"] = { Image = "rbxassetid://7743874599" },
    ["flashlight"] = { Image = "rbxassetid://7733798851" },
    ["plus-square"] = { Image = "rbxassetid://7734040369" },
    ["clipboard-list"] = { Image = "rbxassetid://7733920117" },
    ["github"] = { Image = "rbxassetid://7733954058" },
    ["columns"] = { Image = "rbxassetid://7733757178" },
    ["arrow-big-down"] = { Image = "rbxassetid://7733668653" },
    ["cloud-off"] = { Image = "rbxassetid://7733745572" },
    ["x-circle"] = { Image = "rbxassetid://7743878496" },
    ["bell-plus"] = { Image = "rbxassetid://7733675181" },
    ["battery-medium"] = { Image = "rbxassetid://7733674731" },
    ["arrow-down"] = { Image = "rbxassetid://7733672933" },
    ["cast"] = { Image = "rbxassetid://7733919326" },
    ["gift-card"] = { Image = "rbxassetid://7733945018" },
    ["webcam"] = { Image = "rbxassetid://7743877896" },
    ["folder-minus"] = { Image = "rbxassetid://7733799022" },
    ["scan-line"] = { Image = "rbxassetid://8997386772" },
    ["download-cloud"] = { Image = "rbxassetid://7733770689" },
    ["list-checks"] = { Image = "rbxassetid://7743869317" },
    ["laptop-2"] = { Image = "rbxassetid://7733965313" },
    ["podcast"] = { Image = "rbxassetid://7734042234" },
    ["log-out"] = { Image = "rbxassetid://7733992677" },
    ["thumbs-up"] = { Image = "rbxassetid://7743873212" },
    ["file-search"] = { Image = "rbxassetid://7733788966" },
    ["thermometer"] = { Image = "rbxassetid://7734084149" },
    ["bluetooth-off"] = { Image = "rbxassetid://7733914252" },
    ["refresh-cw"] = { Image = "rbxassetid://7734051052" },
    ["languages"] = { Image = "rbxassetid://7733965249" },
    ["alarm-minus"] = { Image = "rbxassetid://7733656164" },
    ["log-in"] = { Image = "rbxassetid://7733992604" },
    ["maximize"] = { Image = "rbxassetid://7733992982" },
    ["brush"] = { Image = "rbxassetid://7733701455" },
    ["minus-circle"] = { Image = "rbxassetid://7733998053" },
    ["edit-3"] = { Image = "rbxassetid://7733771361" },
    ["book-open"] = { Image = "rbxassetid://7733687281" },
    ["divide-circle"] = { Image = "rbxassetid://7733769152" },
    ["clover"] = { Image = "rbxassetid://7733747233" },
    ["expand"] = { Image = "rbxassetid://7733771982" },
    ["phone-outgoing"] = { Image = "rbxassetid://7743871253" },
    ["paperclip"] = { Image = "rbxassetid://7734021680" },
    ["arrow-big-left"] = { Image = "rbxassetid://7733911731" },
    ["album"] = { Image = "rbxassetid://7733658133" },
    ["bookmark"] = { Image = "rbxassetid://7733692043" },
    ["check-circle-2"] = { Image = "rbxassetid://7733710700" },
    ["list-ordered"] = { Image = "rbxassetid://7743869411" },
    ["delete"] = { Image = "rbxassetid://7733768142" },
    ["octagon"] = { Image = "rbxassetid://7734021165" },
    ["git-commit"] = { Image = "rbxassetid://7743868360" },
    ["shirt"] = { Image = "rbxassetid://7734056672" },
    ["airplay"] = { Image = "rbxassetid://7733655834" },
    ["repeat"] = { Image = "rbxassetid://7734051454" },
    ["chevron-right"] = { Image = "rbxassetid://7733717755" },
    ["chevrons-right"] = { Image = "rbxassetid://7733919682" },
    ["alarm-check"] = { Image = "rbxassetid://7733655912" },
    ["arrow-up-right"] = { Image = "rbxassetid://7733673646" },
    ["file-minus"] = { Image = "rbxassetid://7733936115" },
}

function U.iconSpec(value: any): any
    if type(value) == "number" and U.finite(value) and value > 0 then
        return { Image = "rbxassetid://" .. tostring(math.floor(value)) }
    end
    if type(value) == "string" then
        if imageIcons[value] then
            return imageIcons[value]
        end
        if Icons[value] then
            return Icons[value]
        end
        if string.match(value, "^%d+$") then
            return { Image = "rbxassetid://" .. value }
        end
        if string.match(value, "^rbxassetid://%d+$") or string.match(value, "^rbxasset://") then
            return { Image = value }
        end
        return Icons.more
    end
    if type(value) == "table" and type(value.Image) == "string" then
        local resolved = U.iconSpec(value.Image)
        if not resolved or not resolved.Image then
            return Icons.more
        end
        local spec = table.clone(resolved)
        if typeof(value.RectOffset) == "Vector2" then
            spec.RectOffset = value.RectOffset
        end
        if typeof(value.RectSize) == "Vector2" then
            spec.RectSize = value.RectSize
        end
        return spec
    end
    return Icons.more
end

function U.icon(w: any, life: any, parent: Instance, spec: any, size: number, color: any, props: Payload?): any
    local host = U.frame(parent, props or { Size = O(size, size) })
    local localLife = U.scope()
    life:Give(localLife)
    local function set(nextSpec: any)
        localLife:Remove("draw")
        local drawing = U.scope()
        localLife:Give(drawing, "draw")
        if nextSpec == nil or nextSpec == false then
            return
        end
        local resolved = U.iconSpec(nextSpec)
        local canvas = U.frame(host, { Size = O(size, size), AnchorPoint = V(0.5, 0.5), Position = S(0.5, 0.5) })
        drawing:Give(canvas)
        if resolved.Image then
            local image = U.make("ImageLabel", canvas, {
                Size = S(1, 1),
                Image = resolved.Image,
                ImageRectOffset = resolved.RectOffset or Vector2.zero,
                ImageRectSize = resolved.RectSize or Vector2.zero,
            })
            U.paint(w, drawing, image, "ImageColor3", color)
        else
            for _, p in resolved do
                local x1, y1, x2, y2 = p[1], p[2], p[3], p[4]
                local a, b = (x2 - x1) * size, (y2 - y1) * size
                local stroke = U.line(w, drawing, canvas, color, {
                    Size = O(math.max(1, math.sqrt(a * a + b * b)), p[5] or 1.15),
                    AnchorPoint = V(0.5, 0.5),
                    Position = S((x1 + x2) / 2, (y1 + y2) / 2),
                    Rotation = math.deg(math.atan2(b, a)),
                })
                if (p[5] or 1) > 1.8 then
                    U.corner(stroke, 1)
                end
            end
        end
    end
    set(spec)
    return host, set
end

function U.scroll(parent: Instance, xAxis: boolean?, props: Payload?): any
    local obj = U.make("ScrollingFrame", parent, {
        Size = S(1, 1),
        CanvasSize = O(0, 0),
        AutomaticCanvasSize = if xAxis then Enum.AutomaticSize.None else Enum.AutomaticSize.Y,
        ScrollingDirection = if xAxis then Enum.ScrollingDirection.X else Enum.ScrollingDirection.Y,
        ScrollBarThickness = 0,
        Active = true,
        ClipsDescendants = true,
        Selectable = false,
    })
    if props then
        for k, v in props do
            obj[k] = v
        end
    end
    return obj
end

function U.class(parent: any?): any
    local proto = {}
    (proto :: any).__index = proto
    return setmetatable(proto, { __index = parent })
end

P.Base = U.class(nil)
P.Value = U.class(P.Base)
P.Row = U.class(P.Base)
P.Window = U.class(P.Base)
P.Tab = U.class(P.Base)
P.SubTab = U.class(P.Base)
P.Collection = U.class(P.Base)
P.Dependency = U.class(P.Collection)
P.Section = U.class(P.Collection)
P.Group = U.class(P.Collection)
P.Watermark = U.class(P.Base)
P.Toast = U.class(P.Base)
P.Dialog = U.class(P.Base)
P.Tooltip = U.class(P.Base)
P.Sidebar = U.class(P.Base)

function U.node(w: any, proto: any, kind: string, c: Payload, owner: any, root: GuiObject?): any
    local nextSequence = if w then w._seq + 1 else 0
    if w then
        w._seq = nextSequence
    end
    local name = U.str(c.Name, kind)
    local order = math.clamp(math.round(U.number(c.Order, nextSequence)), -2147483648, 2147483647)
    local n: any = setmetatable({
        _w = w,
        _kind = kind,
        _name = name,
        _id = U.str(c.Id, name),
        _order = order,
        _sequence = nextSequence,
        _owner = owner,
        _root = root,
        _life = U.scope(),
        _visible = c.Visible ~= false,
        _disabled = c.Disabled == true,
        _description = U.str(c.Description),
        _tooltip = U.str(c.Tooltip),
        _children = {},
        _events = {},
        _dead = false,
    }, proto)
    if root then
        root.Name = name
        root.Visible = n._visible
        root.LayoutOrder = n._order
    end
    return n
end

function U.owns(ancestor: any, node: any): boolean
    while node do
        if node == ancestor then
            return true
        end
        node = node._owner
    end
    return false
end

function U.parentChanged(n: any, reason: string)
    local owner = n._owner
    if owner and not owner._dead and owner._childChanged then
        owner:_childChanged(n, reason)
    end
end

function U.adopt(owner: any, n: any)
    table.insert(owner._children, n)
    U.parentChanged(n, "added")
    return n
end

function U.clear(owner: any)
    for _, child in table.clone(owner._children) do
        child:Destroy()
    end
end

function U.find(list: { any }, key: any): any
    if key == nil then
        return nil
    end
    for _, item in list do
        if item._id == key or item._name == key or item._flag == key or item == key then
            return item
        end
    end
    return nil
end

function P.Base:_isDisabled(): boolean
    local n = self
    while n do
        if n._disabled or n._dependencyDisabled or n._locked or n._dead then
            return true
        end
        n = n._owner
    end
    return false
end

function P.Base:_canLockedAction(): boolean
    local n = self
    while n do
        if n._disabled or n._dependencyDisabled or n._dependencyBlocked or n._dead then
            return false
        end
        n = n._owner
    end
    local w = self._w
    return self._visible
        and (not self._root or U.guiVisible(self._root))
        and (not w._dialog or U.owns(w._dialog, self))
        and (not w._drawerOpen or self._kind == "Tab" or self._kind == "Window")
end

function P.Base:_isDependencyBlocked(): boolean
    local n = self
    while n do
        if n._dependencyBlocked then
            return true
        end
        n = n._owner
    end
    return false
end

function P.Base:_canInteract(): boolean
    local w = self._w
    return self._visible
        and not self:_isDisabled()
        and not self:_isDependencyBlocked()
        and (not self._root or U.guiVisible(self._root))
        and (not w._dialog or U.owns(w._dialog, self))
        and (not w._drawerOpen or self._kind == "Tab" or self._kind == "Window")
end

function P.Base:_refreshState()
    if self._stateRender then
        self:_stateRender()
    end
    for _, child in self._children do
        child:_refreshState()
    end
end

function P.Base:SetVisible(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetVisible", "expected boolean")
    end
    if self._visible == v then
        return true
    end
    self._visible = v
    if self._root then
        self._root.Visible = v and not self._dependencyHidden
    end
    if not v then
        self._w:_quiet(self)
    end
    if self._visibilityRender then
        self:_visibilityRender()
    end
    if self._children[1] then
        self._w:_syncAnimations()
    end
    U.parentChanged(self, "visible")
    if self._w and self._w._syncDependencies then
        self._w:_syncDependencies(self)
    end
    return true
end
function P.Base:IsVisible(): boolean
    return self._visible
end

function P.Base:SetDisabled(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetDisabled", "expected boolean")
    end
    if self._disabled ~= v then
        self._disabled = v
        if v then
            self._w:_quiet(self)
        end
        self:_refreshState()
        U.parentChanged(self, "disabled")
        if self._w and self._w._syncDependencies then
            self._w:_syncDependencies(self)
        end
    end
    return true
end
function P.Base:IsDisabled(): boolean
    return self:_isDisabled()
end

function P.Base:SetName(v: string)
    if type(v) ~= "string" or utf8.len(v) == nil then
        return U.issue(self, "SetName", "expected UTF-8 text")
    end
    self._name = v
    if self._root then
        self._root.Name = v
    end
    if self._metaRender then
        self:_metaRender()
    end
    U.parentChanged(self, "name")
    return true
end
function P.Base:GetName(): string
    return self._name
end

function P.Base:SetDescription(v: string?)
    if v ~= nil and (type(v) ~= "string" or utf8.len(v) == nil) then
        return U.issue(self, "SetDescription", "expected text or nil")
    end
    self._description = v or ""
    if self._metaRender then
        self:_metaRender()
    end
    return true
end
function P.Base:GetDescription(): string?
    return if self._description ~= "" then self._description else nil
end

function P.Base:SetTooltip(v: string?)
    if v ~= nil and (type(v) ~= "string" or utf8.len(v) == nil) then
        return U.issue(self, "SetTooltip", "expected text or nil")
    end
    self._tooltip = v or ""
    if self._tooltipHook then
        self:_tooltipHook()
    end
    if self._w._tip and self._w._tip.owner == self then
        self._w:_hideTip()
    end
    return true
end
function P.Base:GetTooltip(): string?
    return if self._tooltip ~= "" then self._tooltip else nil
end

function P.Base:SetOrder(v: number)
    if not U.finite(v) then
        return U.issue(self, "SetOrder", "expected finite number")
    end
    self._order = math.clamp(math.round(v), -2147483648, 2147483647)
    if self._root then
        self._root.LayoutOrder = self._order
    end
    U.parentChanged(self, "order")
    return true
end
function P.Base:GetOrder(): number
    return self._order
end
function P.Base:GetInstance(): GuiObject
    return self._root
end
function P.Base:IsDestroyed(): boolean
    return self._dead
end

function P.Base:Destroy()
    if self._dead then
        return
    end
    self._dead = true
    local w = self._w
    w:_quiet(self)
    if self._flag and w._flags[self._flag] == self then
        w._flags[self._flag] = nil
    end
    if self._beforeDestroy then
        self:_beforeDestroy()
    end
    U.clear(self)
    self._life:Destroy()
    if self._root then
        self._root:Destroy()
    end
    self._root = nil
    if self._owner then
        U.remove(self._owner._children, self)
        U.parentChanged(self, "removed")
    end
    self._owner = nil
    table.clear(self._events)
    if w and w._syncDependencies and not w._dead then
        w:_syncDependencies(self)
    end
end

function P.Value:GetValue(): any
    return U.copy(self._value)
end
function P.Value:GetDefault(): any
    return U.copy(self._default)
end
function P.Value:SetDefault(v: any)
    local ok, normalized, why = self:_normalize(v)
    if not ok then
        return U.issue(self, "SetDefault", why or "invalid default")
    end
    self._default = U.copy(normalized)
    return true
end
function P.Value:Reset(silent: boolean?)
    return self:SetValue(self:GetDefault(), silent)
end
function P.Value:OnChanged(fn: any): Connection
    return U.event(self, "Changed"):Connect(fn)
end
function P.Value:_emitChange(v: any, old: any, previousAlpha: number?)
    local item = { value = U.copy(v), before = U.copy(old), alpha = self._alpha, previousAlpha = previousAlpha }
    local queue = self._emitQueue
    if queue then
        if #queue < 32 then
            table.insert(queue, item)
        end
        return
    end
    queue = { item }
    self._emitQueue = queue
    for i = 1, 32 do
        local nextItem = queue[i]
        if not nextItem or self._dead then
            break
        end
        if self._notify then
            self:_notify(nextItem.value, nextItem.before, nextItem.previousAlpha, nextItem.alpha)
        else
            U.call(self, "Callback", self._callback, U.copy(nextItem.value), U.copy(nextItem.before), self)
            U.emit(self, "Changed", U.copy(nextItem.value), U.copy(nextItem.before), self)
        end
    end
    if #queue >= 32 then
        U.issue(self, "Callback", "aborted a repeating reentrant change cycle")
    end
    self._emitQueue = nil
end

function P.Value:_commit(v: any, silent: boolean?, instant: boolean?): (boolean, boolean)
    local old = self._value
    if U.same(old, v) then
        return true, false
    end
    local equivalent = self._sameValue and self:_sameValue(old, v)
    self._value = U.copy(v)
    if self._valueRender then
        self:_valueRender(instant == true)
    end
    if self._w and self._w._syncDependencies then
        self._w:_syncDependencies(self)
    end
    if self._w and self._w._profileManager and self._flag then
        self._w._profileManager:ControlChanged(self)
    end
    if equivalent then
        return true, false
    end
    if self._effect then
        U.call(self, "internal state effect", self._effect, self._value, self)
    end
    if not silent then
        self:_emitChange(self._value, old)
    end
    return true, true
end

function P.Value:SetValue(v: any, silent: boolean?)
    if silent ~= nil and type(silent) ~= "boolean" then
        return U.issue(self, "SetValue", "silent must be boolean")
    end
    local ok, normalized, why = self:_normalize(v)
    if self._dead then
        return false, "destroyed during validation"
    end
    if not ok then
        return U.issue(self, "SetValue", why or "invalid value")
    end
    return self:_commit(normalized, silent)
end

function U.value(n: any, c: Payload, fallback: any)
    n._callback = if type(c.Callback) == "function" then c.Callback else nil
    local def = c.Default
    if def == nil then
        def = fallback
    end
    local ok, initial, why = n:_normalize(def)
    if not ok then
        U.issue(n, "Default", why or "invalid default")
        local _, safe = n:_normalize(fallback)
        initial = safe
    end
    n._default, n._value = U.copy(initial), U.copy(initial)
    if type(c.Flag) == "string" and c.Flag ~= "" then
        if n._w._flags[c.Flag] then
            U.issue(n, "Flag", "duplicate flag " .. c.Flag)
        else
            n._flag = c.Flag
            n._w._flags[c.Flag] = n
        end
    end
    if n._valueRender then
        n:_valueRender(true)
    end
    if n._w and n._w._syncDependencies then
        n._w:_syncDependencies(n)
    end
end

-- A pointer session is acquired once and has a single release path. Touch sliders
-- reserve horizontal intent only; a predominantly vertical move is left to native scroll.
function P.Window:_take(owner: any, input: InputObject, spec: Payload): boolean
    if Pointer or Capturing or not U.hitType(input) or not owner:_canInteract() then
        return false
    end
    local pt = U.point(input)
    local touch = input.UserInputType == Enum.UserInputType.Touch
    local g: Payload = {
        window = self,
        owner = owner,
        input = input,
        from = pt,
        touch = touch,
        started = not touch or not spec.Axis,
        life = U.scope(),
        spec = spec,
    }
    Pointer = g
    function g:Begin(p: Vector2)
        if self.spec.Scroll then
            local scroll = self.spec.Scroll
            local prev = scroll.ScrollingEnabled
            scroll.ScrollingEnabled = false
            self.life:Give(function()
                if scroll.Parent then
                    scroll.ScrollingEnabled = prev
                end
            end)
        end
        U.call(owner, "pointer start", spec.Start, p, self.from)
    end
    g.life:Give(input:GetPropertyChangedSignal("UserInputState"):Connect(function()
        if input.UserInputState == Enum.UserInputState.Cancel then
            self:_release(true)
        end
    end))
    if g.started then
        g:Begin(pt)
    end
    return true
end

function P.Window:_release(cancel: boolean, p: Vector2?)
    local g = Pointer
    if not g or g.window ~= self then
        return
    end
    Pointer = nil
    g.life:Destroy()
    if g.started then
        U.call(g.owner, "pointer end", g.spec.End, cancel, p or g.from)
    elseif not cancel and p and (p - g.from).Magnitude <= D.PressSlop and g.owner:_canInteract() then
        U.call(g.owner, "pointer tap", g.spec.Tap, p)
    end
end

function P.Window:_movePointer(input: InputObject)
    local g = Pointer
    if not g or g.window ~= self then
        return
    end
    if (g.touch and input ~= g.input) or (not g.touch and input.UserInputType ~= Enum.UserInputType.MouseMovement) then
        return
    end
    if not g.owner:_canInteract() then
        self:_release(true)
        return
    end
    local p = U.point(input)
    if not g.started then
        local delta = p - g.from
        local x, y = math.abs(delta.X), math.abs(delta.Y)
        if g.spec.Axis == "x" and y > D.TouchIntent and y > x then
            self:_release(true)
            return
        end
        if
            (g.spec.Axis == "x" and x >= D.TouchIntent and x >= y)
            or (g.spec.Axis == "any" and delta.Magnitude >= D.TouchIntent)
        then
            g.started = true
            g:Begin(p)
        end
    end
    if Pointer == g and g.started then
        U.call(g.owner, "pointer move", g.spec.Move, p, g.from)
    end
end

function P.Window:_placePopup(p: any)
    if p.dead then
        return
    end
    if not U.anchorVisible(p.anchor, self._safe) then
        self:_closeFrom(p, true)
        return
    end
    local vp, origin = self:_area(), self._safe.AbsolutePosition
    if vp.X <= 0 or vp.Y <= 0 then
        return
    end
    local scale, m = self._scale, D.PopupMargin
    local a, b = p.anchor.AbsolutePosition - origin, p.anchor.AbsoluteSize
    local w = math.min(p.width * scale, math.max(1, vp.X - 2 * m))
    local height = math.min(p.height * scale, math.max(1, vp.Y - 2 * m))
    local below, above = vp.Y - (a.Y + b.Y) - m - D.PopupGap, a.Y - m - D.PopupGap
    local up = below < height and above > below
    local space = if up then above else below
    -- Preserve usable minimum space for an oversized popup by allowing it to overlap
    -- its anchor; the body can scroll but never gets positioned beyond the safe rect.
    if space > 90 * scale then
        height = math.min(height, space)
    end
    local x = if p.left then a.X else a.X + b.X - w
    local y = if up then a.Y - D.PopupGap - height else a.Y + b.Y + D.PopupGap
    p.panel.Position = O(
        math.round(math.clamp(x, m, math.max(m, vp.X - m - w))),
        math.round(math.clamp(y, m, math.max(m, vp.Y - m - height)))
    )
    p.scale.Scale = scale
    p.panel.Size = O(math.floor(w / scale), math.floor(height / scale))
    p.body.ScrollingEnabled = not p.adaptive and height + 1 < p.height * scale
    p.body.CanvasSize = O(0, if p.adaptive then 0 else p.height)
    p.content.Size = if p.adaptive then S(1, 1) else UDim2.new(1, 0, 0, p.height)
    if p.layout then
        p.layout(w / scale, height / scale)
    end
end

function P.Window:_closeFrom(p: any?, instant: boolean?)
    local index = if p then table.find(self._popups, p) else 1
    if not index then
        return
    end
    local retired = {}
    for i = #self._popups, index, -1 do
        local item = table.remove(self._popups, i)
        item.dead = true
        item.owner._popup = nil
        item.input:Destroy()
        item.panel.Interactable = false
        table.insert(retired, item)
    end
    self._life:Remove("popupExitTimer")
    self._life:Remove("popupExit")
    self._exitingPopup = nil
    for _, item in retired do
        local owner = item.owner
        if
            Pointer
            and Pointer.window == self
            and (Pointer.owner == owner or (Pointer.owner._root and Pointer.owner._root:IsDescendantOf(item.panel)))
        then
            self:_release(true)
        end
        local box = Input:GetFocusedTextBox()
        if box and box:IsDescendantOf(item.panel) then
            box:ReleaseFocus(false)
        end
        if
            not instant
            and not self._dead
            and not owner._dead
            and self._speed > 0
            and #retired == 1
            and not item.hasSection
        then
            self._life:Give(item.life, "popupExit")
            self._exitingPopup = item
            U.tween(self, item.life, item.panel, "exitAnim", "popup", { GroupTransparency = 1 })
            U.later(self, self._life, "popupExitTimer", D.Animation.popup / self._speed, function()
                self._exitingPopup = nil
                self._life:Remove("popupExit")
            end)
        else
            item.life:Destroy()
        end
        if owner._popupRender then
            owner:_popupRender(false)
        end
        if item.kind == "capture" and Capturing == owner then
            owner._capturePopup = nil
            U.endCapture(owner)
        end
        if not owner._dead and not self._dead then
            if item.kind == "context" then
                U.emit(owner, "ContextClosed", owner)
            end
            if item.kind ~= "capture" and (item.kind ~= "context" or owner._kind == "ContextMenu") then
                U.emit(owner, "Closed", owner)
            end
        end
    end
end

function U.popup(owner: any, anchor: GuiObject, size: Vector2, settings: Payload?): any
    local w = owner._w
    if not owner:_canInteract() or not U.anchorVisible(anchor, w._safe) then
        return nil
    end
    if owner._popup then
        return owner._popup
    end
    local cfg = settings or {}
    w:_hideTip()
    w._life:Remove("popupExitTimer")
    w._life:Remove("popupExit")
    w._exitingPopup = nil
    local top = w._popups[#w._popups]
    local attempts = 0
    while top and not anchor:IsDescendantOf(top.panel) do
        attempts += 1
        if attempts > 12 then
            return nil
        end
        w:_closeFrom(top, true)
        if owner._dead or w._dead then
            return nil
        end
        top = w._popups[#w._popups]
    end
    if owner._popup then
        return owner._popup
    end
    local life, inputLife = U.scope(), U.scope()
    local panel = U.make("CanvasGroup", w._popupLayer, {
        Name = "JetZPopup",
        Active = true,
        GroupTransparency = 1,
        ZIndex = #w._popups + 1,
    })
    life:Give(panel)
    life:Give(inputLife)
    U.corner(panel, D.PopupRadius)
    U.fill(w, life, panel, "Surface")
    local scale = U.make("UIScale", panel, { Scale = w._scale })
    local body = U.scroll(panel, false, { AutomaticCanvasSize = Enum.AutomaticSize.None, ScrollingEnabled = false })
    local content = U.frame(body, { Size = S(1, 1) })
    local p = {
        life = life,
        input = inputLife,
        owner = owner,
        anchor = anchor,
        panel = panel,
        body = body,
        content = content,
        scale = scale,
        width = size.X,
        height = size.Y,
        left = cfg.Left == true,
        adaptive = cfg.Adaptive == true,
        hasSection = cfg.HasSection == true,
        dead = false,
    }
    owner._popup = p
    table.insert(w._popups, p)
    local function dirty()
        U.later(w, inputLife, "placement", nil, function()
            w:_placePopup(p)
        end)
    end
    inputLife:Give(anchor:GetPropertyChangedSignal("AbsolutePosition"):Connect(dirty))
    inputLife:Give(anchor:GetPropertyChangedSignal("AbsoluteSize"):Connect(dirty))
    inputLife:Give(anchor.AncestryChanged:Connect(dirty))
    local a = anchor.Parent
    while a and a ~= w._safe do
        if a:IsA("ScrollingFrame") then
            inputLife:Give(a:GetPropertyChangedSignal("CanvasPosition"):Connect(dirty))
        end
        a = a.Parent
    end
    w:_placePopup(p)
    if p.dead then
        return nil
    end
    U.tween(w, life, panel, "entry", "popup", { GroupTransparency = 0 })
    if owner._popupRender then
        owner:_popupRender(true)
    end
    return p
end

function P.Window:_hideTip()
    self._tip = nil
    self._life:Remove("tip")
end

function P.Window:_showTip(owner: any, anchor: GuiObject)
    if
        not owner:_canInteract()
        or #self._popups > 0
        or not U.anchorVisible(anchor, self._safe)
        or owner._tooltip == ""
    then
        return
    end
    self:_hideTip()
    local scope = U.scope()
    self._life:Give(scope, "tip")
    self._tip = { owner = owner, anchor = anchor }
    local pop = U.frame(self._tipLayer, { Name = "JetZTooltip" })
    scope:Give(pop)
    U.fill(self, scope, pop, "SurfaceRaised")
    U.corner(pop, D.PopupRadius)
    local text = U.text(self, scope, pop, "Tooltip", owner._tooltip, "TextSecondary", {
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTruncate = Enum.TextTruncate.None,
        Position = O(9, 7),
        Size = UDim2.new(1, -18, 1, -14),
    })
    local function place()
        if not U.anchorVisible(anchor, self._safe) then
            self:_hideTip()
            return
        end
        local view = self._safe.AbsoluteSize
        if view.X < 30 or view.Y < 30 then
            self:_hideTip()
            return
        end
        local origin = self._safe.AbsolutePosition
        local width = math.clamp(U.measure(owner._tooltip, text.TextSize) + 20, 70, 272)
        width = math.min(width, view.X - 16)
        local lines = 0
        for line in string.gmatch(owner._tooltip .. "\n", "(.-)\n") do
            lines += math.max(1, math.ceil(U.measure(line, text.TextSize) / math.max(1, width - 18)))
        end
        local height = math.min(14 + math.max(1, lines) * 16, 125, view.Y - 16)
        local ap = anchor.AbsolutePosition - origin
        local x = math.clamp(ap.X + 8, 8, math.max(8, view.X - width - 8))
        local y = ap.Y + anchor.AbsoluteSize.Y + 5
        if y + height > view.Y - 8 then
            y = ap.Y - height - 5
        end
        pop.Position = O(x, math.clamp(y, 8, math.max(8, view.Y - height - 8)))
        pop.Size = O(width, height)
    end
    place()
    if not scope._dead then
        scope:Give(anchor:GetPropertyChangedSignal("AbsolutePosition"):Connect(place))
        U.later(self, scope, "expiry", 4.5, function()
            self:_hideTip()
        end)
    end
end

function P.Window:_watchHold(owner: any, anchor: GuiObject, input: InputObject, fn: () -> ())
    if self._hold or Pointer or Capturing or input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    self._hold = { input = input, point = U.point(input), owner = owner }
    U.later(self, self._life, "hold", D.HoldDelay, function()
        local hold = self._hold
        self._hold = nil
        if not hold or Pointer or not owner:_canInteract() or not U.anchorVisible(anchor, self._safe) then
            return
        end
        self._suppressed[input] = true
        owner._longPressAt = os.clock()
        fn()
    end)
end

function P.Window:_stopHold()
    self._hold = nil
    self._life:Remove("hold")
end

function U.hints(n: any, anchor: any)
    n._life:Remove("hints")
    if n._tooltip == "" and not n._context then
        return
    end
    local scope, w = U.scope(), n._w
    n._life:Give(scope, "hints")
    scope:Give(anchor.MouseEnter:Connect(function()
        if n._tooltip ~= "" and n:_canInteract() and not Pointer then
            U.later(n, scope, "hover", D.HoverDelay, function()
                w:_showTip(n, anchor)
            end)
        end
    end))
    scope:Give(anchor.MouseLeave:Connect(function()
        scope:Remove("hover")
        if w._tip and w._tip.owner == n then
            w:_hideTip()
        end
    end))
    scope:Give(anchor.InputBegan:Connect(function(input: InputObject)
        if not n:_canInteract() then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton2 and n._context then
            n:OpenContext()
        elseif input.UserInputType == Enum.UserInputType.Touch then
            w:_watchHold(n, anchor, input, function()
                if n._context then
                    n:OpenContext()
                else
                    w:_showTip(n, anchor)
                end
            end)
        end
    end))
end

function U.button(owner: any, scope: any, parent: Instance, props: Payload, fire: any, visual: any?): any
    local object =
        U.make("TextButton", parent, { Text = "", AutoButtonColor = false, Active = true, Selectable = true })
    for k, v in props do
        object[k] = v
    end
    scope:Give(object.Activated:Connect(function(input: InputObject?)
        local w = owner._w
        local recovery = object == w._reopen and not w._visible and not w._disabled
        if
            (owner:_canInteract() or recovery)
            and object.Interactable
            and U.guiVisible(object)
            and not Pointer
            and (not Capturing or Capturing == owner)
            and (not input or not w._suppressed[input])
            and not (
                input
                and input.UserInputType == Enum.UserInputType.Touch
                and owner._longPressAt
                and os.clock() - owner._longPressAt < 0.24
            )
        then
            U.call(owner, "Activated", fire, input)
        end
    end))
    if visual then
        local hover, selected = false, false
        local function state(nextState: string?)
            if not owner:_canInteract() then
                visual("idle")
                return
            end
            visual(nextState or (if selected then "focus" elseif hover then "hover" else "idle"))
        end
        scope:Give(object.MouseEnter:Connect(function()
            hover = true
            state()
        end))
        scope:Give(object.MouseLeave:Connect(function()
            hover = false
            state()
        end))
        scope:Give(object.SelectionGained:Connect(function()
            selected = true
            state()
        end))
        scope:Give(object.SelectionLost:Connect(function()
            selected = false
            state()
        end))
        scope:Give(object.MouseButton1Down:Connect(function()
            state("press")
        end))
        scope:Give(object.MouseButton1Up:Connect(function()
            state()
        end))
    end
    return object
end

function U.nearestScroll(obj: Instance?): any
    while obj do
        if obj:IsA("ScrollingFrame") then
            return obj
        end
        obj = obj.Parent
    end
    return nil
end

function U.scrollbar(w: any, owner: any, scope: any, view: any, parent: Instance, props: Payload): any
    local rail = U.frame(parent, props)
    local channel = U.line(w, scope, rail, "Track", {
        AnchorPoint = V(0.5, 0),
        Position = S(0.5, 0),
        Size = UDim2.new(0, D.ScrollWidth, 1, 0),
    })
    local thumb = U.line(w, scope, channel, "Accent", { Size = O(D.ScrollWidth, D.ScrollMin) })
    U.corner(channel, 3)
    U.corner(thumb, 3)
    local function bounds(): (number, number, number)
        local visible, total = view.AbsoluteWindowSize.Y, view.AbsoluteCanvasSize.Y
        local h = rail.AbsoluteSize.Y
        return math.max(total - visible, 0),
            h,
            math.min(h, math.max(D.ScrollMin * w._scale, h * visible / math.max(1, total)))
    end
    local function update()
        local range, h, len = bounds()
        rail.Visible = range > 1 and h > 1
        if rail.Visible then
            thumb.Size = UDim2.new(1, 0, math.clamp(len / h, 0, 1), 0)
            thumb.Position = S(0, math.clamp(view.CanvasPosition.Y / range, 0, 1) * (h - len) / h)
        end
    end
    for _, prop in { "AbsoluteCanvasSize", "AbsoluteWindowSize", "CanvasPosition" } do
        scope:Give(view:GetPropertyChangedSignal(prop):Connect(update))
    end
    scope:Give(rail:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
    rail.Active = true
    scope:Give(rail.InputBegan:Connect(function(input: InputObject)
        if not rail.Visible then
            return
        end
        local grab = 0
        local function move(p: Vector2)
            local range, h, len = bounds()
            view.CanvasPosition =
                V(0, math.clamp((p.Y - rail.AbsolutePosition.Y - grab) / math.max(1, h - len), 0, 1) * range)
        end
        w:_take(owner, input, {
            Start = function(p: Vector2)
                local _, _, len = bounds()
                grab = if U.inside(thumb, p) then p.Y - thumb.AbsolutePosition.Y else len / 2
                move(p)
            end,
            Move = move,
        })
    end))
    update()
    return rail
end

function U.focusable(owner: any, life: any, object: GuiObject, fn: any, allowLocked: boolean?)
    local w = owner._w
    object.SelectionImageObject = w._selectionVisual
    w._focusables[object] = { owner = owner, activate = fn, order = owner._sequence, allowLocked = allowLocked == true }
    life:Give(function()
        w._focusables[object] = nil
        if Gui.SelectedObject == object then
            Gui.SelectedObject = nil
        end
    end)
end

function P.Window:_focusCycle(reverse: boolean): boolean
    local eligible = {}
    local top = self._popups[#self._popups]
    for object, entry in self._focusables do
        if
            (not top or object:IsDescendantOf(top.panel))
            and object.Selectable
            and object.Interactable
            and (if entry.allowLocked then entry.owner:_canLockedAction() else entry.owner:_canInteract())
            and U.anchorVisible(object, self._safe)
        then
            table.insert(eligible, object)
        end
    end
    if #eligible == 0 then
        return false
    end
    table.sort(eligible, function(a, b)
        local p, q = a.AbsolutePosition, b.AbsolutePosition
        if math.abs(p.Y - q.Y) < 1 then
            if math.abs(p.X - q.X) < 1 then
                return self._focusables[a].order < self._focusables[b].order
            end
            return p.X < q.X
        end
        return p.Y < q.Y
    end)
    local k = table.find(eligible, Gui.SelectedObject) or (if reverse then 1 else 0)
    Gui.SelectedObject = eligible[(k - 1 + (if reverse then -1 else 1)) % #eligible + 1]
    return true
end

function P.Window:_quiet(owner: any)
    if Pointer and Pointer.window == self and U.owns(owner, Pointer.owner) then
        self:_release(true)
    end
    if Capturing and Capturing._w == self and U.owns(owner, Capturing) then
        U.endCapture(Capturing)
    end
    if self._hold and U.owns(owner, self._hold.owner) then
        self:_stopHold()
    end
    if self._tip and U.owns(owner, self._tip.owner) then
        self:_hideTip()
    end
    for _, p in self._popups do
        if U.owns(owner, p.owner) then
            self:_closeFrom(p, true)
            break
        end
    end
    if owner == self or (self._exitingPopup and U.owns(owner, self._exitingPopup.owner)) then
        self._exitingPopup = nil
        self._life:Remove("popupExitTimer")
        self._life:Remove("popupExit")
    end
    local box, focus = Input:GetFocusedTextBox(), Gui.SelectedObject
    if box and owner._root and box:IsDescendantOf(owner._root) then
        box:ReleaseFocus(false)
    end
    if focus and owner._root and focus:IsDescendantOf(owner._root) then
        Gui.SelectedObject = nil
    end
end

function P.Window:_globalInput()
    local life = self._life
    life:Give(Input.InputBegan:Connect(function(i: InputObject, processed: boolean)
        local key = U.inputKey(i)
        local focused = Input:GetFocusedTextBox()
        if Capturing then
            if Capturing._w == self then
                local p = Capturing._capturePopup
                if p and U.hitType(i) and not U.inside(p.panel, U.point(i)) and not U.inside(p.anchor, U.point(i)) then
                    U.endCapture(Capturing)
                elseif
                    key
                    and i.UserInputType ~= Enum.UserInputType.MouseButton1
                    and (not focused or key == Enum.KeyCode.Escape)
                then
                    Capturing:_captureInput(key)
                end
            end
            return
        end
        if self._visible then
            if key == Enum.KeyCode.Escape then
                local top = self._popups[#self._popups]
                if top then
                    self:_closeFrom(top)
                    return
                end
                if self._dialog then
                    if self._dialog._escape then
                        self._dialog:Close()
                    end
                    return
                end
                if self._drawerOpen then
                    self:SetDrawerOpen(false)
                    return
                end
            end
            if U.hitType(i) or i.UserInputType == Enum.UserInputType.MouseButton2 then
                local point = U.point(i)
                self:_hideTip()
                local firstClose
                for j = #self._popups, 1, -1 do
                    local p = self._popups[j]
                    if U.inside(p.panel, point) or U.inside(p.anchor, point) then
                        break
                    end
                    firstClose = p
                end
                if firstClose then
                    self:_closeFrom(firstClose, true)
                end
            end
            if not focused then
                if
                    key == Enum.KeyCode.Tab
                    and not processed
                    and self:_focusCycle(
                        Input:IsKeyDown(Enum.KeyCode.LeftShift) or Input:IsKeyDown(Enum.KeyCode.RightShift)
                    )
                then
                    return
                end
                local selected = Gui.SelectedObject
                local entry = selected and self._focusables[selected]
                local top = self._popups[#self._popups]
                if
                    entry
                    and entry.owner:_canInteract()
                    and selected.Interactable
                    and U.anchorVisible(selected, self._safe)
                    and (not top or selected:IsDescendantOf(top.panel))
                then
                    if entry.owner._keyboard and entry.owner:_keyboard(key, selected) then
                        return
                    end
                    if
                        not processed
                        and (key == Enum.KeyCode.Return or key == Enum.KeyCode.Space)
                        and entry.activate
                    then
                        U.call(entry.owner, "keyboard", entry.activate, i)
                        return
                    end
                end
            end
        end
        if not key or processed or focused or self._disabled or self._dialog or Pointer then
            return
        end
        if self._down[key] then
            return
        end
        self._down[key] = true
        if key == self._hideKey and self._hideKeyEnabled then
            self:Toggle()
            return
        end
        for binding in self._keys do
            if binding._keyInput then
                binding:_keyInput(key, true)
            end
        end
    end))
    life:Give(Input.InputChanged:Connect(function(i)
        local h = self._hold
        if h and h.input == i and (U.point(i) - h.point).Magnitude > D.PressSlop then
            self:_stopHold()
        end
        self:_movePointer(i)
    end))
    life:Give(Input.InputEnded:Connect(function(i)
        if self._hold and self._hold.input == i then
            self:_stopHold()
        end
        local g = Pointer
        if
            g
            and g.window == self
            and (g.input == i or (not g.touch and i.UserInputType == Enum.UserInputType.MouseButton1))
        then
            self:_release(i.UserInputState == Enum.UserInputState.Cancel, U.point(i))
        end
        local key = U.inputKey(i)
        if not key then
            return
        end
        self._down[key] = nil
        for binding in self._keys do
            if binding._keyInput then
                binding:_keyInput(key, false)
            end
        end
    end))
    life:Give(Input.WindowFocusReleased:Connect(function()
        self:_release(true)
        self:_stopHold()
        if Capturing and Capturing._w == self then
            Capturing:CancelCapture()
        end
        for key in self._down do
            for binding in self._keys do
                if binding._keyInput then
                    binding:_keyInput(key, false)
                end
            end
        end
        table.clear(self._down)
    end))
end

function U.view(w: any, owner: any): any
    local view = U.scroll(w._pages, false, { Name = "Page", Visible = false })
    owner._life:Give(view)
    local rail = U.scrollbar(w, owner, owner._life, view, w._pages, { Name = "Scrollbar" })
    owner._life:Give(rail)
    local contents = U.frame(view, {
        Name = "Sections",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    U.layout(contents, 0)
    local tail = U.frame(contents, { Name = "BottomInset", Size = UDim2.new(1, 0, 0, 25), LayoutOrder = 2147483647 })
    return { scroll = view, contents = contents, rail = rail, tail = tail }
end

function U.eligible(n: any): boolean
    return n ~= nil and n._visible and not n._disabled and not n._dead
end

function P.Window:_geometry(view: any)
    local g = self._layout
    -- Keep the enlarged touch target out of the page and native scroll rail.
    local clearance = if g.Touch and self._resizable then g.Hit else 0
    view.scroll.Position = O(g.Left, 0)
    view.scroll.Size = UDim2.new(1, -(g.Left + g.Right), 1, -clearance)
    view.rail.AnchorPoint = V(0.5, 0)
    view.rail.Position = UDim2.new(1, -g.ScrollRight, 0, 0)
    local railInset = math.max(if g.Compact then 17 else D.ScrollBottom, clearance)
    view.rail.Size = UDim2.new(0, if g.Touch then 18 else 13, 1, -railInset)
    view.tail.Size = UDim2.new(1, 0, 0, if g.Compact then 16 else 56)
end

function P.Window:_syncView(item: any, active: boolean)
    local view = item._view
    view.scroll.Visible = active
    view.rail.Parent = if active then self._pages else nil
    if active then
        self:_geometry(view)
    end
end

function P.Window:_refreshNav(animate: boolean?)
    if not self._layout or self._dead then
        return
    end
    local oldTab, oldSub = self._activeTab, self._activeSub
    local tabs = U.sort(self._tabs)
    if self._settingsTab and not self._settingsTab._dead then
        U.remove(tabs, self._settingsTab)
        table.insert(tabs, self._settingsTab)
    end
    local tab = self._wantedTab
    if not U.eligible(tab) then
        tab = nil
        for _, t in tabs do
            if U.eligible(t) then
                tab = t
                break
            end
        end
        self._wantedTab = tab
    end
    local sub = tab and tab._wantedSub
    if tab and not U.eligible(sub) then
        sub = nil
        for _, s in U.sort(tab._subs) do
            if U.eligible(s) then
                sub = s
                break
            end
        end
        tab._wantedSub = sub
    end
    self._activeTab, self._activeSub = tab, sub
    if oldTab ~= tab or oldSub ~= sub then
        local previous = oldSub or oldTab
        if previous then
            self:_quiet(previous)
            local focus = Input:GetFocusedTextBox()
            if focus and focus:IsDescendantOf(previous._view.scroll) then
                focus:ReleaseFocus(false)
            end
            local selected = Gui.SelectedObject
            if selected and selected:IsDescendantOf(previous._view.scroll) then
                Gui.SelectedObject = nil
            end
        end
    end
    if self._dead then
        return
    end
    local g = self._layout
    local visible = 0
    for _, t in tabs do
        t._root.Visible = t._visible
        t._root.LayoutOrder = t._order
        t._navRender(animate == true)
        self:_syncView(t, t == tab and not sub)
        for _, s in t._subs do
            s._root.Visible = t == tab and s._visible
            self:_syncView(s, t == tab and s == sub)
            if s._root.Visible then
                visible += 1
            end
        end
    end
    local stripHeight = if g.Drawer and visible == 0 then 0 else g.Header
    local totalHeader = (if g.Drawer then g.Header else 0) + stripHeight
    self._header.Size = UDim2.new(1, 0, 0, totalHeader)
    self._strip.Position = O(g.Left, if g.Drawer then g.Header else 0)
    self._strip.Size = UDim2.new(1, -(g.Left + g.Right), 0, stripHeight)
    self._strip.Visible = visible > 0
    self._blank.Position = O(0, 0)
    self._blank.Size = UDim2.new(1, 0, 0, totalHeader)
    self._pages.Position = O(0, totalHeader + D.ScrollTop)
    self._pages.Size = UDim2.new(1, 0, 1, -(totalHeader + D.ScrollTop))
    self._mobileTitle.Text = if tab then tab._name else self._name
    local cursor, subX, subW = 0, 0, 0
    if tab then
        for _, s in U.sort(tab._subs) do
            if s._visible then
                local width =
                    math.clamp(U.measure(s._name, D.Typography.TopTab) + (if s._icon then 61 else 46), 66, 195)
                s._root.Position = O(cursor, 0)
                s._root.Size = UDim2.new(0, width, 1, 0)
                s._navRender()
                if s == sub then
                    subX, subW = cursor, width
                end
                cursor += width + (if g.Compact then 7 else 21)
            end
        end
    end
    self._strip.CanvasSize = O(cursor, 0)
    self._underline.Visible = sub ~= nil
    if sub then
        U.tween(
            self,
            self._life,
            self._underline,
            "underline",
            "nav",
            { Position = O(subX, 0), Size = O(subW, 2) },
            not animate or oldTab ~= tab or not oldSub
        )
        local length = math.max(1, g.Width - g.Sidebar - g.Left - g.Right)
        local offset = self._strip.CanvasPosition.X / self._scale
        if subX < offset then
            self._strip.CanvasPosition = V(subX * self._scale, 0)
        elseif subX + subW > offset + length then
            self._strip.CanvasPosition = V(math.max(0, subX + subW - length) * self._scale, 0)
        end
    end
    if oldTab ~= tab or oldSub ~= sub then
        self:_syncAnimations()
    end
    if animate and (oldTab or oldSub) and (oldTab ~= tab or oldSub ~= sub) then
        self._veil.BackgroundTransparency = 0.22
        U.tween(self, self._life, self._veil, "page", "page", { BackgroundTransparency = 1 })
    end
end

function P.Window:_childChanged(child: any)
    if child._kind == "Tab" then
        self:_refreshNav(true)
    end
end

function P.Tab:_childChanged(child: any)
    if child._kind == "SubTab" then
        self._w:_refreshNav(true)
    end
end

function U.navIcon(n: any, parent: Instance, size: number, color: any)
    local host, set = U.icon(
        n._w,
        n._life,
        parent,
        n._icon,
        size,
        color,
        { AnchorPoint = V(0, 0.5), Position = UDim2.new(0, 18, 0.5, 0), Size = O(size, size) }
    )
    n._iconHost, n._setIcon = host, set
end

function P.Tab:SetIcon(icon: any)
    self._icon = U.copy(icon)
    self._setIcon(icon)
    self._navRender(false)
    return true
end
function P.Tab:GetIcon(): any
    return U.copy(self._icon)
end
function P.SubTab:SetIcon(icon: any)
    self._icon = U.copy(icon)
    self._setIcon(icon)
    self._w:_refreshNav(false)
    return true
end
function P.SubTab:GetIcon(): any
    return U.copy(self._icon)
end
function P.Tab:SetBadge(badge: any)
    if badge ~= nil and type(badge) ~= "string" and not U.finite(badge) then
        return U.issue(self, "SetBadge", "expected text, number or nil")
    end
    self._badgeText = if badge == nil then "" else tostring(badge)
    self._navRender(false)
    return true
end
function P.Tab:GetBadge(): string?
    return if self._badgeText ~= "" then self._badgeText else nil
end
function P.Tab:Select(): boolean
    return self._w:SelectTab(self)
end
function P.Tab:IsSelected(): boolean
    return self._w._activeTab == self
end
function P.Tab:GetSubTabs(): { any }
    return U.sort(self._subs)
end
function P.Tab:GetSubTab(k: any): any
    return U.find(self._subs, k)
end
function P.Tab:Clear()
    U.clear(self)
end
function P.SubTab:Clear()
    U.clear(self)
end
function P.SubTab:IsSelected(): boolean
    return self._w._activeSub == self
end
function P.SubTab:Select(): boolean
    if not U.eligible(self) or not U.eligible(self._owner) then
        return false
    end
    self._owner._wantedSub = self
    return self._w:SelectTab(self._owner)
end

function P.Window:AddTab(options: any)
    local c = U.cfg(options)
    local systemSettings = c._SystemSettings == true
    if systemSettings then
        c = table.clone(c)
        c.Order = 2147483647
    end
    local hadUserTab = false
    for _, existing in self._tabs do
        if not existing._systemSettings and not existing._dead then
            hadUserTab = true
            break
        end
    end
    local t = U.node(self, P.Tab, "Tab", c, self, nil)
    t._systemSettings = systemSettings
    t._view = U.view(self, t)
    t._subs, t._icon = {}, U.copy(c.Icon)
    t._badgeText = if type(c.Badge) == "string" or U.finite(c.Badge) then tostring(c.Badge) else ""
    local state = "idle"
    local btn = U.button(
        t,
        t._life,
        self._navList,
        { Name = t._name, LayoutOrder = t._order, Size = UDim2.new(1, 0, 0, D.NavRow) },
        function()
            t:Select()
        end,
        function(nextState: string)
            state = nextState
            if t._navRender then
                t._navRender(false)
            end
        end
    )
    t._root = btn
    local rail = U.line(self, t._life, btn, "Accent", { Size = UDim2.new(0, 3, 1, 0), BackgroundTransparency = 0 })
    U.navIcon(t, btn, 18, "Accent")
    local label, textColor = U.text(self, t._life, btn, "Sidebar", t._name, function(colors: Payload)
        return if t:_isDisabled()
            then colors.TextDisabled
            elseif t == self._activeTab or state ~= "idle" then colors.Text
            else colors.NavMuted
    end)
    local badge = U.text(self, t._life, btn, "Muted", "", "TextSecondary", {
        AnchorPoint = V(1, 0),
        Position = UDim2.new(1, -11, 0, 0),
        Size = UDim2.new(0, 44, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    local shade = U.paint(self, t._life, btn, "BackgroundColor3", function(colors: Payload)
        if t:_isDisabled() then
            return colors.Sidebar
        end
        if state == "press" then
            return colors.Pressed
        end
        if t == self._activeTab then
            return colors.SidebarSelected
        end
        return colors.Hover
    end)
    t._navRender = function(animated: boolean)
        local selected, g = self._activeTab == t, self._layout
        local enabled = not t:_isDisabled()
        btn.Interactable = enabled
        btn.Selectable = enabled
        local height = if g.Touch then math.max(D.NavRow, g.Hit) else D.NavRow
        btn.Size = UDim2.new(1, 0, 0, height)
        t._iconHost.Visible = selected and t._icon ~= nil
        t._iconHost.Position = UDim2.new(0, if g.Compact then 12 else 19, 0.5, 0)
        local inset = if t._iconHost.Visible then (if g.Compact then 37 else 64) else 25
        label.Position = O(inset, 0)
        label.Size = UDim2.new(1, -(inset + (if t._badgeText ~= "" then 54 else 9)), 1, 0)
        label.Text = t._name
        badge.Text = t._badgeText
        textColor()
        shade()
        U.tween(
            self,
            t._life,
            btn,
            "navShade",
            "hover",
            { BackgroundTransparency = if selected or (enabled and state ~= "idle") then 0 else 1 },
            not animated
        )
        U.tween(
            self,
            t._life,
            rail,
            "navLine",
            "nav",
            { BackgroundTransparency = if selected then 0 else 1 },
            not animated
        )
    end
    t._metaRender = function()
        label.Text = t._name
    end
    t._stateRender = function()
        t._navRender(false)
    end
    t._beforeDestroy = function()
        U.remove(self._tabs, t)
    end
    t._tooltipHook = function()
        U.hints(t, btn)
    end
    t:_tooltipHook()
    U.focusable(t, t._life, btn, function()
        t:Select()
    end)
    table.insert(self._tabs, t)
    U.adopt(self, t)
    if not systemSettings and not hadUserTab and self._settingsTab and self._wantedTab == self._settingsTab then
        self._wantedTab = t
        self:_refreshNav(false)
    end
    return t
end

function P.Tab:AddSubTab(options: any)
    local c = U.cfg(options)
    local w = self._w
    local s = U.node(w, P.SubTab, "SubTab", c, self, nil)
    s._icon = U.copy(c.Icon)
    s._view = U.view(w, s)
    local state = "idle"
    local btn = U.button(s, s._life, w._strip, { Name = s._name, Visible = false }, function()
        s:Select()
    end, function(nextState: string)
        state = nextState
        if s._navRender then
            s._navRender()
        end
    end)
    s._root = btn
    U.navIcon(s, btn, 13, "Accent")
    local label, refresh = U.text(w, s._life, btn, "TopTab", s._name, function(colors: Payload)
        if s:_isDisabled() then
            return colors.TextDisabled
        end
        return if w._activeSub == s or state ~= "idle" then colors.Text else colors.NavMuted
    end, { TextXAlignment = Enum.TextXAlignment.Center })
    U.paint(w, s._life, btn, "BackgroundColor3", "Surface")
    s._navRender = function()
        btn.Interactable = not s:_isDisabled()
        btn.Selectable = btn.Interactable
        s._iconHost.Visible = s._icon ~= nil
        label.Position = O(if s._icon then 22 else 0, 0)
        label.Size = UDim2.new(1, if s._icon then -22 else 0, 1, 0)
        label.Text = s._name
        btn.BackgroundTransparency = if w._activeSub == s then 0.62 elseif state ~= "idle" then 0.34 else 1
        refresh()
    end
    s._stateRender = s._navRender
    s._tooltipHook = function()
        U.hints(s, btn)
    end
    s:_tooltipHook()
    s._beforeDestroy = function()
        U.remove(self._subs, s)
    end
    U.focusable(s, s._life, btn, function()
        s:Select()
    end)
    if #self._subs == 0 then
        for _, child in table.clone(self._children) do
            if child._kind == "Section" then
                U.remove(self._children, child)
                child._owner = s
                table.insert(s._children, child)
                child._root.Parent = s._view.contents
            end
        end
    end
    table.insert(self._subs, s)
    return U.adopt(self, s)
end

function P.Window:GetTabs(): { any }
    local sorted = U.sort(self._tabs)
    if self._settingsTab and not self._settingsTab._dead then
        U.remove(sorted, self._settingsTab)
        table.insert(sorted, self._settingsTab)
    end
    return sorted
end
function P.Window:GetTab(key: any): any
    return U.find(self._tabs, key)
end
function P.Window:GetSelectedTab(): any
    return self._activeTab
end
function P.Window:SelectTab(key: any): boolean
    local t = self:GetTab(key)
    if not U.eligible(t) then
        return false
    end
    self._wantedTab = t
    self:SetDrawerOpen(false)
    self:_refreshNav(true)
    return true
end

function P.Window:_syncDependencies(source: any?)
    if self._dead or self._syncingDependencies or not self._dependencies then
        return
    end
    self._syncingDependencies = true
    for item in self._dependencies do
        if item._dead then
            self._dependencies[item] = nil
        elseif item._dependencySync then
            local ok, why = pcall(item._dependencySync, item, source)
            if not ok then
                U.issue(item, "dependency sync", why)
            end
        end
    end
    self._syncingDependencies = false
end

function P.Window:_area(): Vector2
    local area = self._safe.AbsoluteSize
    if area.X <= 2 or area.Y <= 2 then
        area = V(D.Width + 2 * D.DesktopSafe, D.Height + 2 * D.DesktopSafe)
    end
    if self._useTouch and Input.OnScreenKeyboardVisible then
        local y = Input.OnScreenKeyboardPosition.Y - self._safe.AbsolutePosition.Y
        if y > 140 and y < area.Y then
            area = V(area.X, y)
        end
    end
    return area
end

function P.Window:_placeWindow(p: Vector2?)
    local g = self._layout
    local area = self:_area()
    local avail = V(g.Width * self._scale, g.Height * self._scale)
    local target = p or (area - avail) / 2
    local minimum = V(
        math.min(g.Margin, math.max(0, (area.X - avail.X) / 2)),
        math.min(g.Margin, math.max(0, (area.Y - avail.Y) / 2))
    )
    self._position = V(
        math.round(math.clamp(target.X, minimum.X, math.max(minimum.X, area.X - avail.X - minimum.X))),
        math.round(math.clamp(target.Y, minimum.Y, math.max(minimum.Y, area.Y - avail.Y - minimum.Y)))
    )
    self._shell.Position = O(self._position.X, self._position.Y)
end

function P.Window:_reflow()
    if self._dead then
        return
    end
    local area, s = self:_area(), self._scale
    local touch = self._useTouch
    local m = if touch then D.MobileSafe else D.DesktopSafe
    local available = V(math.max(1, (area.X - 2 * m) / s), math.max(1, (area.Y - 2 * m) / s))
    local width = math.floor(math.min(self._size.X, available.X))
    local height = math.floor(math.min(self._size.Y, available.Y))
    local drawer = self._sidebarVisible
        and width < D.DrawerBreakpoint
        and (not touch or area.X < area.Y * 1.18 or width < 515)
    if drawer and touch and area.X < area.Y * 1.18 and not self._userSize then
        width = math.floor(math.min(available.X, 600))
        height = math.floor(math.min(available.Y, 730))
    end
    local compact = drawer or width < D.LandscapeBreakpoint or (touch and area.Y < 550)
    local sidebar = if drawer or not self._sidebarVisible then 0 elseif compact then D.LandscapeSidebar else D.Sidebar
    local gutter = if compact then D.TouchGutter else D.Left
    local hit = if touch then math.ceil(D.TouchHit / s) else 0
    local old = self._layout
    self._layout = {
        Width = width,
        Height = height,
        Touch = touch,
        Drawer = drawer,
        Compact = compact,
        Sidebar = sidebar,
        Left = gutter,
        Right = if compact then 26 else D.Right,
        ScrollRight = if compact then 11 else D.ScrollRight,
        Header = if compact then math.max(D.TouchHeader, hit) else D.Header,
        Hit = hit,
        Margin = m,
        Scale = s,
    }
    self._uiScale.Scale = s
    self._shell.Size = O(width, height)
    self._body.Position = O(sidebar, 0)
    self._body.Size = UDim2.new(1, -sidebar, 1, 0)
    self._brand.Size = UDim2.new(1, 0, 0, if compact then 65 else D.BrandHeight)
    local logoInset, titleInset = if compact then 20 else 30, if compact then 56 else 78
    self._brandLogo.Position = UDim2.new(0, logoInset, 0.5, 0)
    self._brandText.Position = O(titleInset, 0)
    self._brandText.Size = UDim2.new(1, -(titleInset + 7), 1, 0)
    self._navList.Position = O(0, if compact then 71 else D.NavStart)
    self._navList.Size = UDim2.new(1, 0, 1, -(if compact then 111 else 146))
    self._mobile.Visible = drawer
    self._mobile.Size = UDim2.new(1, 0, 0, self._layout.Header)
    self._drawerButton.Size = O(self._layout.Header, self._layout.Header)
    self._reopen.Visible = not self._visible and touch
    if old and old.Drawer and not drawer then
        self:SetDrawerOpen(false)
    end
    self:_drawerLayout(true)
    self:_placeWindow(if self._manual then self._position else nil)
    self:_refreshNav(false)
    if not old or old.Hit ~= hit or old.Compact ~= compact or old.Drawer ~= drawer then
        for n in self._responsive do
            if not n._dead then
                n:_measure()
            end
        end
    end
    for _, popup in table.clone(self._popups) do
        if not popup.dead and popup.kind == "dropdown" and popup.hit ~= hit then
            popup.owner:_buildOptions(popup)
        else
            self:_placePopup(popup)
        end
    end
    if self._dialog then
        self._dialog:_layout()
    end
    if self._useTouch and Input.OnScreenKeyboardVisible then
        local box = Input:GetFocusedTextBox()
        if box and box:IsDescendantOf(self._gui) then
            U.later(self, self._life, "revealEditor", nil, function()
                if not box.Parent or not box:IsFocused() then
                    return
                end
                local scroll = U.nearestScroll(box)
                if not scroll or not scroll.ScrollingEnabled then
                    return
                end
                local delta = box.AbsolutePosition.Y
                    + box.AbsoluteSize.Y
                    + 6
                    - (scroll.AbsolutePosition.Y + scroll.AbsoluteWindowSize.Y)
                if delta > 0 then
                    scroll.CanvasPosition += V(0, delta)
                end
            end)
        end
    end
    if self._renderDock then
        self:_renderDock()
    end
    if self._particlesRefresh then
        self:_particlesRefresh()
    end
end

function P.Window:_drawerLayout(instant: boolean?)
    local g = self._layout
    local open = g.Drawer and self._drawerOpen
    local width = if g.Drawer then math.max(1, math.min(D.Drawer, g.Width - 34)) else g.Sidebar
    self._life:Remove("drawerExit")
    self._sidebar.Visible = self._sidebarVisible and (not g.Drawer or open or (not instant and self._sidebar.Visible))
    self._sidebar.Interactable = self._sidebarVisible and (not g.Drawer or open)
    self._sidebar.Size = UDim2.new(0, width, 1, 0)
    self._sidebar.ZIndex = if g.Drawer then 12 else 2
    self._drawerScrim.Visible = open
    self._body.Interactable = not open and not self._dialog and not self._disabled
    self:_layoutResizeGrip()
    if open then
        U.tween(self, self._life, self._sidebar, "drawer", "drawer", { Position = O(0, 0) }, instant)
    else
        if g.Drawer and not instant and self._sidebar.Visible and self._speed > 0 then
            U.tween(self, self._life, self._sidebar, "drawer", "drawer", { Position = O(-width, 0) })
            U.later(self, self._life, "drawerExit", D.Animation.drawer / self._speed, function()
                if not self._drawerOpen then
                    self._sidebar.Visible = false
                end
            end)
        else
            self._life:Remove("drawer")
            self._sidebar.Position = O(if g.Drawer then -width else 0, 0)
            if g.Drawer then
                self._sidebar.Visible = false
            end
        end
    end
end

function P.Window:SetDrawerOpen(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetDrawerOpen", "expected boolean")
    end
    if v and not self._layout.Drawer then
        return false, "drawer is only available in compact layout"
    end
    if v == self._drawerOpen then
        return true
    end
    if v then
        self:_quiet(self)
    end
    self._drawerOpen = v
    self:_drawerLayout(false)
    return true
end
function P.Window:IsDrawerOpen(): boolean
    return self._drawerOpen
end
function P.Window:SetSidebarVisible(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetSidebarVisible", "expected boolean")
    end
    if self._sidebarVisible ~= v then
        self._sidebarVisible = v
        self._drawerOpen = false
        self:_reflow()
    end
    return true
end
function P.Window:GetSidebar(): any
    if not self._sidebarControl then
        self._sidebarControl = U.node(self, P.Sidebar, "Sidebar", { Name = "Navigation" }, self, nil)
        U.adopt(self, self._sidebarControl)
    end
    return self._sidebarControl
end
function P.Sidebar:GetInstance(): GuiObject
    return self._w._sidebar
end
function P.Sidebar:GetTabs(): { any }
    return self._w:GetTabs()
end
function P.Sidebar:Select(key: any)
    return self._w:SelectTab(key)
end
function P.Sidebar:SetDrawerOpen(v: boolean)
    return self._w:SetDrawerOpen(v)
end
function P.Sidebar:IsDrawerOpen(): boolean
    return self._w:IsDrawerOpen()
end
function P.Sidebar:SetVisible(v: boolean)
    return self._w:SetSidebarVisible(v)
end
function P.Sidebar:IsVisible(): boolean
    return self._w._sidebarVisible
end
function P.Sidebar:SetDisabled(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetDisabled", "expected boolean")
    end
    self._disabled = v
    self._w._navList.Interactable = not v
    return true
end
function P.Sidebar:Destroy()
    if self._dead then
        return
    end
    local w = self._w
    w._sidebarControl = nil
    if not w._dead then
        w:SetSidebarVisible(false)
        w._navList.Interactable = true
    end
    P.Base.Destroy(self)
end
function P.Window:GetLayout(): any
    return table.clone(self._layout)
end
function P.Window:GetTitle(): string
    return self._name
end
function P.Window:SetTitle(v: string)
    return self:SetName(v)
end
function P.Window:SetLogo(v: any)
    self._logo = U.copy(v)
    self._setLogo(v)
    return true
end
function P.Window:GetLogo(): any
    return U.copy(self._logo)
end
function P.Window:SetVersion(v: string)
    if type(v) ~= "string" or utf8.len(v) == nil then
        return U.issue(self, "SetVersion", "expected text")
    end
    self._footer.Text = v
    return true
end
function P.Window:GetVersion(): string
    return self._footer.Text
end

function P.Window:SetVisible(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetVisible", "expected boolean")
    end
    if v == self._visible then
        return true
    end
    self._visible, self._shell.Visible = v, v
    if not v then
        self:_quiet(self)
        self._resetResizeFeedback()
        self:SetDrawerOpen(false)
        if self._dialog then
            self._dialog:Close()
        end
        if self._dead then
            return true
        end
    end
    self:_syncAnimations()
    self._reopen.Visible = self._useTouch and not v
    if self._particlesRefresh then
        self:_particlesRefresh()
    end
    return true
end
function P.Window:Show()
    return self:SetVisible(true)
end
function P.Window:Hide()
    return self:SetVisible(false)
end
function P.Window:Toggle()
    return self:SetVisible(not self._visible)
end
function P.Window:Translate(text: string): string
    local locale = SystemLocales[self._settingsLanguage] or SystemLocales.English
    return locale[text] or text
end

function P.Window:GetLanguages(): { string }
    return table.clone(SystemLocaleOrder)
end

function P.Window:GetLanguage(): string
    return self._settingsLanguage or "English"
end

function P.Window:_refreshSystemLanguage()
    local root = self._settingsTab
    if root and not root._dead then
        local function visit(node: any)
            if node ~= root and not node._dead then
                if node.GetName and node.SetName then
                    node._localeSourceName = node._localeSourceName or node:GetName()
                    node:SetName(self:Translate(node._localeSourceName))
                end
                if node.GetDescription and node.SetDescription then
                    local current = node:GetDescription()
                    if node._localeSourceDescription == nil then
                        node._localeSourceDescription = current or false
                    end
                    if node._localeSourceDescription ~= false then
                        node:SetDescription(self:Translate(node._localeSourceDescription))
                    end
                end
                if node._box and node._box:IsA("TextBox") then
                    node._localeSourcePlaceholder = node._localeSourcePlaceholder or node._box.PlaceholderText
                    if node._localeSourcePlaceholder ~= "" then
                        node._box.PlaceholderText = self:Translate(node._localeSourcePlaceholder)
                    end
                end
            end
            for _, child in node._children or {} do visit(child) end
            if node._settings and not node._settings._dead then visit(node._settings) end
        end
        visit(root)
    end
    for _, callback in self._localeBindings or {} do
        local ok, why = pcall(callback)
        if not ok then U.issue(self, "localization", why) end
    end
    if self._profileManager then self._profileManager:RefreshUI() end
end

function P.Window:SetLanguage(language: string)
    if type(language) ~= "string" or not SystemLocales[language] then
        return U.issue(self, "SetLanguage", "unsupported language " .. tostring(language))
    end
    self._settingsLanguage = language
    self:_refreshSystemLanguage()
    return true
end

function P.Window:SetPremiumURL(url: string)
    if type(url) ~= "string" or utf8.len(url) == nil then
        return U.issue(self, "SetPremiumURL", "expected UTF-8 URL text")
    end
    self._premiumURL = url
    return true
end

function P.Window:GetPremiumURL(): string
    return self._premiumURL
end

function P.Window:SetThemePreset(name: string)
    local preset = ThemePresets[name]
    if not preset then
        return U.issue(self, "SetThemePreset", "unknown theme preset " .. tostring(name))
    end
    self._themePreset = name
    return self:SetTheme(preset)
end
function P.Window:GetThemePreset(): string
    return self._themePreset or "Custom"
end
function P.Window:GetThemePresets(): { string }
    return table.clone(ThemePresetOrder)
end
function P.Window:SetAccent(v: Color3)
    if not U.color(v) then
        return U.issue(self, "SetAccent", "expected Color3 with channels in [0,1]")
    end
    if self._theme._base.Accent ~= v then
        self._themePreset = "Custom"
        self._theme._base.Accent = v
        self._theme:_apply()
        self:_reflect("accent", v)
    end
    return true
end
function P.Window:GetAccent(): Color3
    return self._theme._base.Accent
end
function P.Window:GetTheme(): any
    return table.clone(self._theme._colors)
end
function P.Window:SetTheme(v: any)
    if type(v) ~= "table" then
        return U.issue(self, "SetTheme", "expected a token table")
    end
    local updated = table.clone(self._theme._base)
    for key, color in v do
        if D.Colors[key] == nil or not U.color(color) then
            return U.issue(self, "SetTheme", "invalid token " .. tostring(key))
        end
        updated[key] = color
    end
    self._theme._base = updated
    self._theme:_apply()
    self:_reflect("accent", updated.Accent)
    return true
end
function P.Window:SetContrast(v: number)
    if not U.finite(v) then
        return U.issue(self, "SetContrast", "expected finite number")
    end
    local nextValue = math.clamp(v, 0.45, 2)
    if self._theme._contrast ~= nextValue then
        self._theme._contrast = nextValue
        self._theme:_apply()
        self:_reflect("contrast", nextValue)
    end
    return true
end
function P.Window:GetContrast(): number
    return self._theme._contrast
end
function P.Window:SetScale(v: number)
    if not U.finite(v) then
        return U.issue(self, "SetScale", "expected finite number")
    end
    local n = math.clamp(v, D.MinScale, D.MaxScale)
    if n ~= self._scale then
        self._scale = n
        self:_reflow()
        self:_reflect("scale", n)
    end
    return true
end
function P.Window:GetScale(): number
    return self._scale
end
function P.Window:_syncAnimations()
    for n in self._animated do
        if not n._dead then
            n:_updateAnimation()
        end
    end
end
function P.Window:SetAnimationSpeed(v: number)
    if not U.finite(v) or v < 0 then
        return U.issue(self, "SetAnimationSpeed", "expected a nonnegative finite speed")
    end
    local speed = if v == 0 then 0 else math.clamp(v, 0.2, 4)
    if self._speed == speed then
        return true
    end
    self._speed = speed
    self:_syncAnimations()
    self:_reflect("speed", speed)
    return true
end
function P.Window:GetAnimationSpeed(): number
    return self._speed
end
function P.Window:SetDraggable(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetDraggable", "expected boolean")
    end
    self._draggable = v
    if not v and Pointer and Pointer.window == self and Pointer.spec.WindowAction == "move" then
        self:_release(true)
    end
    return true
end
function P.Window:IsDraggable(): boolean
    return self._draggable
end
function P.Window:SetResizable(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetResizable", "expected boolean")
    end
    if self._resizable == v then
        return true
    end
    self._resizable = v
    if not v and Pointer and Pointer.window == self and Pointer.spec.WindowAction == "resize" then
        self:_release(true)
    end
    self:_layoutResizeGrip()
    local visiblePage = self._activeSub or self._activeTab
    if visiblePage then
        self:_geometry(visiblePage._view)
    end
    return true
end
function P.Window:IsResizable(): boolean
    return self._resizable
end
function P.Window:SetSize(v: any)
    if typeof(v) == "UDim2" then
        local a = self:_area() / self._scale
        v = V(a.X * v.X.Scale + v.X.Offset, a.Y * v.Y.Scale + v.Y.Offset)
    end
    if typeof(v) ~= "Vector2" or not U.finite(v.X) or not U.finite(v.Y) or v.X <= 0 or v.Y <= 0 then
        return U.issue(self, "SetSize", "expected a positive Vector2 or UDim2")
    end
    self._userSize = true
    local limits = D.Resize
    self._size =
        V(math.clamp(v.X, limits.MinWidth, limits.MaxWidth), math.clamp(v.Y, limits.MinHeight, limits.MaxHeight))
    self:_reflow()
    return true
end
function P.Window:GetSize(): Vector2
    return self._size
end
function P.Window:SetPosition(v: any)
    if typeof(v) == "UDim2" then
        local a = self:_area()
        v = V(a.X * v.X.Scale + v.X.Offset, a.Y * v.Y.Scale + v.Y.Offset)
    end
    if typeof(v) ~= "Vector2" or not U.finite(v.X) or not U.finite(v.Y) then
        return U.issue(self, "SetPosition", "expected finite Vector2 or UDim2")
    end
    self._manual = true
    self:_placeWindow(v)
    return true
end
function P.Window:GetPosition(): Vector2
    return self._position
end
function P.Window:Center()
    self._manual = false
    self:_placeWindow()
end
function P.Window:SetHideKey(v: any)
    local ok, key = U.key(v)
    if not ok then
        return U.issue(self, "SetHideKey", "expected key or nil")
    end
    self._hideKey = key
    self:_reflect("hideKey", key)
    return true
end
function P.Window:GetHideKey(): any
    return self._hideKey
end
function P.Window:SetHideKeyEnabled(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetHideKeyEnabled", "expected boolean")
    end
    self._hideKeyEnabled = v
    self:_reflect("hideEnabled", v)
    return true
end

function P.Window:_reflect(k: string, value: any)
    local controller = self._settings[k]
    if controller and not controller._dead then
        local previous = self._reflecting
        self._reflecting = k
        controller:SetValue(value, true)
        self._reflecting = previous
    end
end

function P.Window:_layoutResizeGrip()
    local g, limits = self._layout, D.Resize
    local hit = if g.Touch then g.Hit else limits.DesktopHit
    local handle = self._resizeHandle
    handle.Size = O(hit, hit)
    handle.Visible = self._resizable and not self._drawerOpen
    local enabled = handle.Visible and not self._disabled and not self._dialog
    handle.Interactable = enabled
    handle.Selectable = enabled
    self._resizeReadout.Position = UDim2.new(1, -limits.Inset, 1, -hit - limits.Inset)
    if not enabled then
        if Gui.SelectedObject == handle then
            Gui.SelectedObject = nil
        end
        self._resetResizeFeedback()
    elseif self._resizeReadout.Visible then
        self._resizeReadoutText.Text = ("%d × %d"):format(g.Width, g.Height)
    end
end

function P.Window:_canResize(): boolean
    return self._resizeHandle.Visible
        and self._resizeHandle.Interactable
        and self:_canInteract()
        and #self._popups == 0
        and not Input:GetFocusedTextBox()
end

function P.Window:_resizeTo(target: Vector2): boolean
    local g, limits = self._layout, D.Resize
    -- Clamp growth at the current top-left so pulling against an edge never moves the window.
    local available = (self:_area() - self._position - V(g.Margin, g.Margin)) / self._scale
    local maxWidth = math.max(g.Width, math.min(limits.MaxWidth, math.floor(available.X)))
    local maxHeight = math.max(g.Height, math.min(limits.MaxHeight, math.floor(available.Y)))
    local width = math.clamp(math.round(target.X), math.min(g.Width, limits.MinWidth), maxWidth)
    local height = math.clamp(math.round(target.Y), math.min(g.Height, limits.MinHeight), maxHeight)
    if width == g.Width and height == g.Height then
        return false
    end
    self._manual = true
    return self:SetSize(V(width, height))
end

function P.Window:_keyboard(key: any, selected: GuiObject): boolean
    if selected ~= self._resizeHandle or Pointer or not self:_canResize() then
        return false
    end
    local x = if key == Enum.KeyCode.Left or key == Enum.KeyCode.DPadLeft
        then -1
        elseif key == Enum.KeyCode.Right or key == Enum.KeyCode.DPadRight then 1
        else 0
    local y = if key == Enum.KeyCode.Up or key == Enum.KeyCode.DPadUp
        then -1
        elseif key == Enum.KeyCode.Down or key == Enum.KeyCode.DPadDown then 1
        else 0
    if x == 0 and y == 0 then
        return false
    end
    local g = self._layout
    self:_resizeTo(V(g.Width + x * D.Resize.Step, g.Height + y * D.Resize.Step))
    return true
end

function P.Window:_mountResizeGrip()
    local life, limits = self._life, D.Resize
    local handle = U.make("TextButton", self._shell, {
        Name = "Resize",
        Text = "",
        AnchorPoint = V(1, 1),
        Position = S(1, 1),
        Active = true,
        AutoButtonColor = false,
        ZIndex = 14,
    })
    self._resizeHandle = handle
    U.focusable(self, life, handle, nil)
    local plate = U.frame(handle, {
        Name = "ResizePlate",
        AnchorPoint = V(1, 1),
        Position = UDim2.new(1, -limits.Inset, 1, -limits.Inset),
        Size = O(limits.Plate, limits.Plate),
        BackgroundTransparency = 0.42,
    })
    U.corner(plate, 5)
    local stroke = U.make("UIStroke", plate, { Thickness = 1, Transparency = 0.42 })
    local idle = U.icon(self, life, plate, "resizeGrip", limits.Icon, "TextSecondary", { Size = S(1, 1) })
    local active = U.icon(self, life, plate, "resizeGrip", limits.Icon, "Accent", { Size = S(1, 1), Visible = false })
    local readout = U.frame(self._shell, {
        Name = "ResizeReadout",
        AnchorPoint = V(1, 1),
        Size = O(limits.ReadoutWidth, limits.ReadoutHeight),
        Visible = false,
        ZIndex = 14,
    })
    U.corner(readout, D.PopupRadius)
    U.fill(self, life, readout, "SurfaceRaised")
    U.line(self, life, readout, "Accent", { Position = O(5, 6), Size = O(2, 11) })
    local readoutText = U.text(self, life, readout, "Numeric", "", "Text", {
        Position = O(8, 0),
        Size = UDim2.new(1, -12, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    self._resizeReadout, self._resizeReadoutText = readout, readoutText

    local hover, focus, resizing = false, false, false
    local plateColor = U.paint(self, life, plate, "BackgroundColor3", function(t: Payload)
        return if resizing then t.AccentMuted elseif hover or focus then t.Hover else t.Surface
    end)
    local edgeColor = U.paint(self, life, stroke, "Color", function(t: Payload)
        return if resizing or focus then t.Accent elseif hover then t.AccentMuted else t.Stroke
    end)
    local function paint(instant: boolean?)
        local engaged = hover or focus or resizing
        idle.Visible, active.Visible = not engaged, engaged
        plateColor()
        edgeColor()
        U.tween(self, life, plate, "resizePlate", "hover", {
            BackgroundTransparency = if resizing then 0.06 elseif engaged then 0.17 else 0.42,
        }, instant)
        readout.Visible = resizing
        if resizing then
            local g = self._layout
            readoutText.Text = ("%d × %d"):format(g.Width, g.Height)
        end
    end
    self._resetResizeFeedback = function()
        if hover or focus or resizing then
            hover, focus, resizing = false, false, false
            paint(true)
        end
    end
    life:Give(handle.MouseEnter:Connect(function()
        if handle.Interactable then
            hover = true
            paint()
        end
    end))
    life:Give(handle.MouseLeave:Connect(function()
        if hover then
            hover = false
            paint()
        end
    end))
    life:Give(handle.SelectionGained:Connect(function()
        if handle.Interactable then
            focus = true
            paint()
        end
    end))
    life:Give(handle.SelectionLost:Connect(function()
        if focus then
            focus = false
            paint()
        end
    end))
    life:Give(handle.InputBegan:Connect(function(input: InputObject)
        if not self:_canResize() then
            return
        end
        local g, scale = self._layout, self._scale
        local initial = V(g.Width, g.Height)
        local mouse = input.UserInputType == Enum.UserInputType.MouseButton1
        self:_take(self, input, {
            Axis = "any",
            WindowAction = "resize",
            Start = function()
                resizing = true
                paint()
            end,
            Move = function(point: Vector2, from: Vector2)
                if self._scale ~= scale then
                    self:_release(true)
                    return
                end
                self:_resizeTo(initial + (point - from) / scale)
            end,
            End = function(cancelled: boolean, point: Vector2)
                resizing = false
                hover = mouse and not cancelled and U.inside(handle, point)
                paint()
            end,
        })
    end))
end

function P.Window:_chrome()
    local w, life = self, self._life
    local safe = self._safe
    local shell = self._shell
    local focusVisual = U.frame(nil, { Size = S(1, 1), Name = "JetZFocus" })
    life:Give(focusVisual)
    local stroke = U.make("UIStroke", focusVisual, { Thickness = 1, Transparency = 0.17 })
    U.paint(w, life, stroke, "Color", "Accent")
    U.corner(focusVisual, D.FieldRadius)
    self._selectionVisual = focusVisual
    U.fill(self, life, shell, "Background")
    U.corner(shell, D.Radius)
    self._uiScale = U.make("UIScale", shell, { Scale = self._scale })
    self._particlesPane = U.frame(shell, { Size = S(1, 1), ClipsDescendants = true, Name = "Atmosphere" })
    local body = U.frame(shell, { Name = "Workspace", ZIndex = 2 })
    self._body = body
    self._pages = U.frame(body, { Name = "Pages", ClipsDescendants = true })
    self._veil = U.line(w, life, self._pages, "Background", { Size = S(1, 1), ZIndex = 9, Name = "Transition" })
    self._veil.BackgroundTransparency = 1
    self._header = U.frame(body, { Name = "Header", ZIndex = 10 })
    self._blank = U.frame(self._header, { Active = true, Name = "DragRegion" })
    self._strip = U.scroll(self._header, true, { Name = "SubTabs", ZIndex = 2 })
    self._underline = U.line(w, life, self._strip, "Accent", { Size = O(0, 2), ZIndex = 4, Name = "Active" })
    self._mobile = U.frame(self._header, { Name = "CompactHeader", ZIndex = 3 })
    self._mobileTitle = U.text(w, life, self._mobile, "Sidebar", self._name, "Text", {
        Position = O(62, 0),
        Size = UDim2.new(1, -78, 1, 0),
    })
    self._drawerButton = U.button(self, life, self._mobile, { Name = "Navigation" }, function()
        w:SetDrawerOpen(not w._drawerOpen)
    end)
    U.icon(w, life, self._drawerButton, "menu", 17, "TextSecondary", { Size = S(1, 1) })
    U.focusable(w, life, self._drawerButton, function()
        w:SetDrawerOpen(not w._drawerOpen)
    end)
    self._drawerScrim = U.button(self, life, shell, {
        Name = "DrawerScrim",
        Size = S(1, 1),
        ZIndex = 11,
        Selectable = false,
        BackgroundTransparency = 0.41,
        BackgroundColor3 = Black,
        Visible = false,
    }, function()
        w:SetDrawerOpen(false)
    end)
    self._sidebar = U.frame(shell, { Name = "Sidebar", ClipsDescendants = true, Position = O(0, 0) })
    U.fill(w, life, self._sidebar, "Sidebar")
    U.corner(self._sidebar, D.Radius)
    self._brand = U.frame(self._sidebar, { Active = true, Name = "Brand" })
    U.line(w, life, self._brand, "Surface", {
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
    })
    local logoHost, setLogo = U.icon(w, life, self._brand, self._logo, 29, "Accent", {
        AnchorPoint = V(0, 0.5),
        Position = UDim2.new(0, 30, 0.5, 0),
        Size = O(32, 32),
    })
    self._setLogo, self._brandLogo = setLogo, logoHost
    self._brandText = U.text(w, life, self._brand, "Brand", self._name, "Text", {
        Position = O(78, 0),
        Size = UDim2.new(1, -84, 1, 0),
    })
    self._navList = U.scroll(self._sidebar, false, { Name = "Navigation" })
    U.layout(self._navList, D.NavGap)
    self._footer = U.text(w, life, self._sidebar, "Footer", "", "TextSecondary", {
        Position = UDim2.new(0, 22, 1, -45),
        Size = UDim2.new(1, -36, 0, 33),
    })
    self:_mountResizeGrip()
    self._reopen = U.button(
        self,
        life,
        safe,
        { Name = "Show window", Visible = false, Position = O(8, 8), Size = O(46, 46), ZIndex = 60 },
        function()
            w:Show()
        end
    )
    U.corner(self._reopen, D.PopupRadius)
    U.fill(w, life, self._reopen, "SurfaceRaised")
    U.icon(w, life, self._reopen, "brand", 20, "Accent", { Size = S(1, 1) })
    self._popupLayer = U.frame(safe, { Name = "PopupLayer", Size = S(1, 1), ZIndex = 20 })
    self._tipLayer = U.frame(safe, { Name = "TooltipLayer", Size = S(1, 1), ZIndex = 24 })
    self._modalLayer = U.frame(safe, { Name = "ModalLayer", Size = S(1, 1), ZIndex = 35 })
    self._toastLayer = U.frame(safe, {
        Name = "NotificationLayer",
        ZIndex = 30,
        AnchorPoint = V(1, 0),
        Position = UDim2.new(1, -11, 0, 11),
        Size = O(295, 1),
    })
    U.layout(self._toastLayer, 7)
    local function moving(input: InputObject)
        if not self._draggable or self._drawerOpen or #self._popups > 0 or Input:GetFocusedTextBox() then
            return
        end
        local start = self._position
        self:_take(self, input, {
            Axis = "any",
            WindowAction = "move",
            Move = function(p: Vector2, from: Vector2)
                if (p - from).Magnitude < 3 then
                    return
                end

                -- Match NeronUi's permissive drag bounds: the window may travel mostly
                -- off-screen while a small recovery strip remains reachable.
                local area = self._safe.AbsoluteSize
                if area.X <= 2 or area.Y <= 2 then
                    area = self:_area()
                end
                local layout = self._layout
                local scaled = V(layout.Width * self._scale, layout.Height * self._scale)
                local target = start + p - from
                local minX = 48 - scaled.X
                local maxX = math.max(minX, area.X - 48)
                local minY = 16
                local maxY = math.max(minY, area.Y - 32)

                self._manual = true
                self._position = V(
                    math.round(math.clamp(target.X, minX, maxX)),
                    math.round(math.clamp(target.Y, minY, maxY))
                )
                self._shell.Position = O(self._position.X, self._position.Y)
            end,
        })
    end
    life:Give(self._blank.InputBegan:Connect(moving))
    life:Give(self._brand.InputBegan:Connect(moving))
    life:Give(self._mobileTitle.InputBegan:Connect(moving))
    self._stateRender = function()
        self._shell.Interactable = not self._disabled and not self._dialog
        self:_drawerLayout(true)
    end
    self._metaRender = function()
        self._brandText.Text = self._name
        if not self._activeTab then
            self._mobileTitle.Text = self._name
        end
    end
end

function Library:CreateWindow(options: WindowOptions?): (WindowHandle | false, string?)
    local c = U.cfg(options)
    local parent = c.Parent
    if parent == nil then
        local player = Players.LocalPlayer
        if not player then
            return U.issue(nil, "CreateWindow", "call from a Roblox client")
        end
        parent = player:FindFirstChildOfClass("PlayerGui")
        if not parent then
            return U.issue(nil, "CreateWindow", "PlayerGui is not available yet")
        end
    end
    if typeof(parent) ~= "Instance" then
        return U.issue(nil, "CreateWindow", "Parent must be a client UI host")
    end
    local id = "JetZUi_" .. string.sub(U.str(c.Id, "Main"), 1, 80)
    local prior = parent:FindFirstChild(id)
    if prior then
        if prior:IsA("ScreenGui") and prior:GetAttribute("JetZUiOwner") == true then
            local owner = roots[prior]
            if owner then
                owner:Destroy()
            else
                local stop = prior:FindFirstChild("Shutdown")
                if stop and stop:IsA("BindableFunction") then
                    pcall(function()
                        stop:Invoke()
                    end)
                elseif stop and stop:IsA("BindableEvent") then
                    stop:Fire()
                end
                prior:Destroy()
            end
        else
            return U.issue(nil, "CreateWindow", "a non-JetZ object already uses " .. id)
        end
    end
    local gui = U.make("ScreenGui", nil, {
        Name = id,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = math.clamp(math.round(U.number(c.DisplayOrder, 70)), -100000, 100000),
        ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
        ClipToDeviceSafeArea = true,
        SafeAreaCompatibility = Enum.SafeAreaCompatibility.None,
    })
    gui:SetAttribute("JetZUiOwner", true)
    local safe = U.frame(gui, { Size = S(1, 1), Name = "SafeViewport" })
    local shell = U.frame(safe, { Name = "Window", Active = true, ZIndex = 1 })
    local w = U.node(nil, P.Window, "Window", { Name = U.str(c.Title, "JetZ"), Visible = c.Visible }, nil, shell)
    w._w, w._seq, w._gui, w._safe, w._shell, w._development = w, 0, gui, safe, shell, c.Development ~= false
    w._theme = U.theme(c.Theme, c.Accent)
    w._flags, w._keys, w._down, w._tabs, w._popups, w._settings, w._toasts = {}, {}, {}, {}, {}, {}, {}
    w._dependencies = {}
    w._profileManager = P.ProfileManager.new(w, c.Persistence or c.Settings)
    w._themePreset = "JetZ Dark"
    w._settingsLanguage = if type(c.Language) == "string" and SystemLocales[c.Language] then c.Language else "English"
    w._localeBindings = {}
    w._premiumURL = U.str(c.PremiumURL or c.StoreURL, "https://plak-hub.mysellauth.com/")
    w._responsive, w._animated, w._focusables, w._particles = {}, {}, {}, {}
    w._suppressed = setmetatable({}, { __mode = "k" })
    w._size, w._position = V(D.Width, D.Height), Vector2.zero
    w._scale, w._speed =
        math.clamp(U.number(c.Scale, 1), D.MinScale, D.MaxScale), math.clamp(U.number(c.AnimationSpeed, 1), 0, 4)
    if w._speed > 0 then
        w._speed = math.max(0.2, w._speed)
    end
    w._theme._contrast = math.clamp(U.number(c.Contrast, 1), 0.45, 2)
    w._theme:_apply()
    w._useTouch = if type(c.Touch) == "boolean" then c.Touch else Input.TouchEnabled
    w._draggable, w._resizable, w._drawerOpen, w._sidebarVisible =
        c.Draggable ~= false, c.Resizable ~= false, false, true
    w._hideKeyEnabled = true
    local _, key = U.key(c.HideKey)
    w._hideKey = key or Enum.KeyCode.RightShift
    w._logo = if c.Logo == nil then "brand" else U.copy(c.Logo)
    w._particleEnabled, w._particleCount, w._particleMode =
        c.Particles == true, math.clamp(math.round(U.number(c.ParticleCount, 16)), 0, D.ParticleMax), "Float"
    w:_chrome()
    w:SetVersion(U.str(c.Version))
    local ok, why = pcall(function()
        gui.Parent = parent
    end)
    if not ok then
        w:Destroy()
        return U.issue(nil, "CreateWindow", why)
    end
    roots[gui] = w
    local stop = U.make("BindableFunction", gui, { Name = "Shutdown" })
    stop.OnInvoke = function()
        w:Destroy()
        return true
    end
    w._life:Give(gui.Destroying:Connect(function()
        w:Destroy()
    end))
    w._life:Give(gui.AncestryChanged:Connect(function()
        if not gui.Parent then
            w:Destroy()
        end
    end))
    local function viewportChanged()
        w:_release(true)
        U.later(w, w._life, "layout", nil, function()
            w:_reflow()
        end)
    end
    w._life:Give(safe:GetPropertyChangedSignal("AbsoluteSize"):Connect(viewportChanged))
    if w._useTouch then
        for _, prop in { "OnScreenKeyboardVisible", "OnScreenKeyboardPosition" } do
            w._life:Give(Input:GetPropertyChangedSignal(prop):Connect(viewportChanged))
        end
    end
    w:_globalInput()
    w:_reflow()
    if c.Size ~= nil then
        w:SetSize(c.Size)
    end
    if c.Position ~= nil then
        w:SetPosition(c.Position)
    end
    w:AddSettings(type(c.Settings) == "table" and c.Settings or {})
    return w, nil
end

function P.Window:Destroy()
    if self._dead then
        return
    end
    local gui = self._gui
    roots[gui] = nil
    P.Base.Destroy(self)
    gui:Destroy()
    self._gui, self._shell, self._safe = nil, nil, nil
end

function P.Collection:GetControls(): { any }
    return U.sort(self._children)
end
function P.Collection:GetControl(name: string): any
    local direct = U.find(self._children, name)
    if direct then
        return direct
    end
    for _, c in self._children do
        if c._kind == "InlineGroup" then
            local found = c:GetControl(name)
            if found then
                return found
            end
        end
        if c._settings and not c._settings._dead then
            local found = c._settings:GetControl(name)
            if found then
                return found
            end
        end
    end
    return nil
end
function P.Collection:Clear()
    U.clear(self)
end

-- Dependency engine -----------------------------------------------------------
-- Examples:
--   local advanced = master:AddSettings({ Mode = "Reveal" })
--   advanced:AddSlider({ Name = "Speed", Min = 1, Max = 100 })
--   row:SetDependency({ Flag = "farm.enabled", Equals = true }, "Disable")
--   row:SetDependency({ All = { "farm.enabled", { Flag = "zone", In = { 3, 4, 5 } } } }, "Reveal")
-- Conditions are evaluated only on state changes; there is no polling/render-step work.
-- Supported condition shapes:
--   controller | "flag.name" | function(window, dependent) -> boolean
--   { Control=controller, Equals=value }
--   { Flag="flag.name", NotEquals=value }
--   { Truthy=true, Flag="flag.name" }
--   { In={...}, Flag="flag.name" }
--   { Predicate=function(value, source, window, dependent) return boolean end, ... }
--   { All={...} } | { Any={...} } | { Not=condition }
local dependencyModes: Payload = { Reveal = true, Disable = true, Dim = true }

function U.dependencyValue(w: any, source: any): (any, any)
    if type(source) == "string" then
        source = w._flags[source]
    end
    if type(source) == "table" and source._w == w and not source._dead then
        if source.GetValue then
            local ok, value = pcall(source.GetValue, source)
            if ok then
                return value, source
            end
        end
        return source._value, source
    end
    return nil, nil
end

function U.dependencyEval(w: any, dependent: any, spec: any): boolean
    local kind = type(spec)
    if spec == nil then
        return true
    elseif kind == "boolean" then
        return spec
    elseif kind == "string" then
        local value = U.dependencyValue(w, spec)
        return value ~= nil and value ~= false
    elseif kind == "function" then
        local ok, result = U.call(dependent, "dependency predicate", spec, w, dependent)
        return ok and result == true
    elseif kind ~= "table" then
        return false
    end

    if spec._w == w and spec.GetValue then
        local value = U.dependencyValue(w, spec)
        return value ~= nil and value ~= false
    end
    if spec.Not ~= nil then
        return not U.dependencyEval(w, dependent, spec.Not)
    end
    if type(spec.All) == "table" then
        for _, condition in spec.All do
            if not U.dependencyEval(w, dependent, condition) then
                return false
            end
        end
        return true
    end
    if type(spec.Any) == "table" then
        for _, condition in spec.Any do
            if U.dependencyEval(w, dependent, condition) then
                return true
            end
        end
        return false
    end
    if spec[1] ~= nil and spec.Control == nil and spec.Flag == nil then
        for _, condition in spec do
            if not U.dependencyEval(w, dependent, condition) then
                return false
            end
        end
        return true
    end

    local source = spec.Control
    if source == nil then
        source = spec.Flag
    end
    local value, controller = U.dependencyValue(w, source)
    if spec.Exists ~= nil then
        return (controller ~= nil) == (spec.Exists == true)
    end
    if controller == nil then
        return false
    end
    if spec.Predicate ~= nil then
        if type(spec.Predicate) ~= "function" then
            U.issue(dependent, "dependency", "Predicate must be a function")
            return false
        end
        local ok, result = U.call(dependent, "dependency predicate", spec.Predicate, U.copy(value), controller, w, dependent)
        if not ok or result ~= true then
            return false
        end
    end
    if spec.Equals ~= nil and not U.same(value, spec.Equals) then
        return false
    end
    if spec.NotEquals ~= nil and U.same(value, spec.NotEquals) then
        return false
    end
    if spec.Truthy ~= nil and ((value ~= nil and value ~= false) ~= (spec.Truthy == true)) then
        return false
    end
    if type(spec.In) == "table" then
        local found = false
        for _, candidate in spec.In do
            if U.same(value, candidate) then
                found = true
                break
            end
        end
        if not found then
            return false
        end
    end
    if spec.Equals == nil and spec.NotEquals == nil and spec.Truthy == nil and spec.In == nil and spec.Predicate == nil then
        return value ~= nil and value ~= false
    end
    return true
end

function P.Row:_dependencySync()
    local state = self._dependency
    if not state then
        return
    end
    local active = U.dependencyEval(self._w, self, state.Spec)
    local changed = state.Active ~= active
    state.Active = active
    self._dependencyHidden = not active and state.Mode == "Reveal"
    self._dependencyDisabled = not active and state.Mode == "Disable"
    self._dependencyBlocked = not active and state.Mode == "Dim"
    self._dependencyDim = not active and state.Mode == "Dim"
    if self._root then
        self._root.Visible = self._visible and not self._dependencyHidden
    end
    if not active then
        self._w:_quiet(self)
    end
    self:_refreshState()
    U.parentChanged(self, "dependency")
    if changed then
        U.emit(self, "DependencyChanged", active, self)
    end
end

function P.Row:SetDependency(spec: any, mode: string?)
    if self._dead then
        return false, "destroyed controller"
    end
    local resolvedMode = mode or (type(spec) == "table" and spec.Mode) or "Reveal"
    if type(resolvedMode) ~= "string" or not dependencyModes[resolvedMode] then
        return U.issue(self, "SetDependency", "mode must be Reveal, Disable or Dim")
    end
    if spec == nil then
        return self:ClearDependency()
    end
    self._dependency = { Spec = spec, Mode = resolvedMode, Active = nil }
    self._w._dependencies[self] = true
    self._life:Give(function()
        if self._w and self._w._dependencies then
            self._w._dependencies[self] = nil
        end
    end, "dependencyRegistration")
    self:_dependencySync()
    return true
end

function P.Row:GetDependency(): any
    if not self._dependency then
        return nil
    end
    return {
        Spec = self._dependency.Spec,
        Mode = self._dependency.Mode,
        Active = self._dependency.Active == true,
    }
end

function P.Row:IsDependencyActive(): boolean
    return not self._dependency or self._dependency.Active == true
end

function P.Row:OnDependencyChanged(fn: any): Connection
    return U.event(self, "DependencyChanged"):Connect(fn)
end

function P.Row:ClearDependency()
    self._life:Remove("dependencyRegistration")
    self._dependency = nil
    self._dependencyHidden = false
    self._dependencyDisabled = false
    self._dependencyBlocked = false
    self._dependencyDim = false
    if self._root then
        self._root.Visible = self._visible
    end
    self:_refreshState()
    U.parentChanged(self, "dependency")
    return true
end

function P.Row:GetSettings(): any
    return self._settings
end

function P.Row:AddSettings(options: any)
    if self._dead then
        return U.issue(self, "AddSettings", "destroyed controller")
    end
    if self._settings and not self._settings._dead then
        return self._settings
    end
    if type(self._value) ~= "boolean" then
        return U.issue(self, "AddSettings", "requires a boolean Toggle or Checkbox")
    end
    if self._owner and self._owner._kind == "InlineGroup" then
        return U.issue(self, "AddSettings", "nested settings are not supported inside InlineGroup; place the master control directly in a Section")
    end
    local c = U.cfg(options)
    local mode = U.str(c.Mode, "Disable")
    if not dependencyModes[mode] then
        return U.issue(self, "AddSettings", "Mode must be Reveal, Disable or Dim")
    end

    local parent = self._root and self._root.Parent
    if not parent then
        return U.issue(self, "AddSettings", "master control is not mounted")
    end
    local root = U.make("CanvasGroup", parent, {
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        GroupTransparency = 1,
        Visible = false,
        BackgroundTransparency = 1,
        Name = "DependentSettings",
    })
    local group = U.node(self._w, P.Dependency, "Dependency", {
        Name = U.str(c.Name, self._name .. " Settings"),
        Visible = c.Visible,
    }, self, root)
    group._small = self._small
    group._mode = mode
    group._expanded = c.Expanded ~= false
    group._groupVisible = c.Visible ~= false
    group._condition = c.When
    group._lastActive = nil
    group._host = U.frame(root, {
        Position = O(28, 0),
        Size = UDim2.new(1, -28, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Name = "DependentContent",
    })
    group._list = U.layout(group._host, 0)
    group._rail = U.line(self._w, group._life, root, function(t: Payload)
        return if group:IsActive() then t.Accent else t.Divider
    end, {
        Position = O(12, 2),
        Size = UDim2.new(0, 2, 1, -8),
        Name = "DependencyRail",
    })
    U.corner(group._rail, 2)
    group._refreshRail = U.paint(self._w, group._life, group._rail, "BackgroundColor3", function(t: Payload)
        return if group:IsActive() then t.Accent else t.Divider
    end)

    group._chevronButton = U.button(self, group._life, self._heading, {
        Name = "SettingsChevron",
        ZIndex = 8,
        Size = O(20, 20),
    }, function()
        if group:IsActive() or group._mode ~= "Reveal" then
            group:SetExpanded(not group._expanded)
        end
    end)
    group._chevron = U.icon(self._w, group._life, group._chevronButton, "right", 9, function(t: Payload)
        return if group:IsActive() then t.Accent else t.TextMuted
    end, {
        Size = S(1, 1),
    })
    group._statusDot = U.line(self._w, group._life, group._chevronButton, function(t: Payload)
        return if group:IsActive() then t.Accent else t.TextMuted
    end, {
        AnchorPoint = V(0.5, 0.5),
        Position = UDim2.new(1, -2, 0.5, 0),
        Size = O(4, 4),
        ZIndex = 10,
        Name = "DependencyStatus",
    })
    U.corner(group._statusDot, 4)
    group._refreshStatus = U.paint(self._w, group._life, group._statusDot, "BackgroundColor3", function(t: Payload)
        return if group:IsActive() then t.Accent else t.TextMuted
    end)
    self._interactive[group._chevronButton] = function()
        return group:IsActive() or group._mode ~= "Reveal"
    end
    group._life:Give(function()
        if self._interactive then
            self._interactive[group._chevronButton] = nil
        end
    end, "dependencyChevronRegistration")
    U.focusable(self, group._life, group._chevronButton, function()
        if group:IsActive() or group._mode ~= "Reveal" then
            group:SetExpanded(not group._expanded)
        end
    end)

    self._settings = group
    self._w._dependencies[group] = true
    group._life:Give(function()
        if group._w and group._w._dependencies then
            group._w._dependencies[group] = nil
        end
    end, "dependencyRegistration")
    group._life:Give(group._list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        group:_dependencySync()
    end))
    U.adopt(self, group)
    self:_measure()
    group:_dependencySync(true)
    return group
end

function P.Dependency:_layoutChevron()
    if self._dead or not self._chevronButton or not self._owner then
        return
    end
    local h = math.max(20, self._owner._heading.AbsoluteSize.Y / self._w._scale)
    self._chevronButton.Position = O(self._owner._titleLeft, math.max(0, (h - 20) / 2))
end

function P.Dependency:IsActive(): boolean
    if self._dead or not self._owner or self._owner._dead then
        return false
    end
    if self._condition ~= nil then
        return U.dependencyEval(self._w, self, self._condition)
    end
    return self._owner._value == true
        and self._owner._visible
        and not self._owner:_isDisabled()
        and not self._owner:_isDependencyBlocked()
        and (not self._owner._root or U.guiVisible(self._owner._root))
end

function P.Dependency:_dependencySync(source: any?, immediate: boolean?)
    if type(source) == "boolean" and immediate == nil then
        immediate = source
    end
    if self._dead or not self._root then
        return
    end
    local active = self:IsActive()
    if active and self._lastActive == false and self._mode == "Reveal" then
        self._expanded = true
    end
    local shown = self._groupVisible
        and self._owner._visible
        and self._expanded
        and (self._mode ~= "Reveal" or active)
    local target = if shown then self._list.AbsoluteContentSize.Y else 0
    self._dependencyDisabled = not active and self._mode == "Disable"
    self._dependencyBlocked = not active and self._mode == "Dim"

    if shown then
        self._root.Visible = true
    end
    local transparency = if not shown then 1 elseif active then 0 elseif self._mode == "Dim" then 0.46 else 0.62
    U.tween(self._w, self._life, self._root, "dependencyFrame", "nav", {
        Size = UDim2.new(1, 0, 0, target),
        GroupTransparency = transparency,
    }, immediate == true)
    if not shown then
        local delay = if immediate or self._w._speed <= 0 then nil else D.Animation.nav / self._w._speed
        if delay then
            U.later(self, self._life, "dependencyHide", delay, function()
                if not self._dead and (not self._groupVisible or not self._expanded or (self._mode == "Reveal" and not self:IsActive())) then
                    self._root.Visible = false
                end
            end)
        else
            self._root.Visible = false
        end
    else
        self._life:Remove("dependencyHide")
    end

    if self._chevron then
        U.tween(self._w, self._life, self._chevron, "dependencyChevron", "state", {
            Rotation = if self._expanded and shown then 90 else 0,
        }, immediate == true)
    end
    if self._refreshRail then
        self._refreshRail()
    end
    if self._refreshStatus then
        self._refreshStatus()
    end
    self:_refreshState()
    local changed = self._lastActive ~= active
    self._lastActive = active
    if changed then
        U.emit(self, "DependencyChanged", active, self)
    end
    U.parentChanged(self, "height")
end

function P.Dependency:_childChanged()
    U.later(self, self._life, "dependencyLayout", nil, function()
        self:_dependencySync()
    end)
end

function P.Dependency:SetMode(mode: string)
    if not dependencyModes[mode] then
        return U.issue(self, "SetMode", "expected Reveal, Disable or Dim")
    end
    self._mode = mode
    self:_dependencySync()
    return true
end

function P.Dependency:GetMode(): string
    return self._mode
end

function P.Dependency:SetCondition(spec: any)
    self._condition = spec
    self:_dependencySync()
    return true
end

function P.Dependency:GetCondition(): any
    return self._condition
end

function P.Dependency:AddSection(options: any)
    if self._dead then
        return U.issue(self, "AddSection", "destroyed dependency group")
    end
    local section = U.section(self, self._host, options, self._small)
    U.adopt(self, section)
    self:_dependencySync(true)
    return section
end

function P.Dependency:SetExpanded(value: boolean)
    if type(value) ~= "boolean" then
        return U.issue(self, "SetExpanded", "expected boolean")
    end
    self._expanded = value
    self:_dependencySync()
    return true
end

function P.Dependency:IsExpanded(): boolean
    return self._expanded
end

function P.Dependency:SetVisible(value: boolean)
    if type(value) ~= "boolean" then
        return U.issue(self, "SetVisible", "expected boolean")
    end
    self._groupVisible = value
    self:_dependencySync()
    return true
end

function P.Dependency:IsVisible(): boolean
    return self._groupVisible
end

function P.Dependency:OnDependencyChanged(fn: any): Connection
    return U.event(self, "DependencyChanged"):Connect(fn)
end

function P.Dependency:Destroy()
    if self._dead then
        return
    end
    local owner = self._owner
    if owner and owner._settings == self then
        owner._settings = nil
    end
    P.Base.Destroy(self)
    if owner and not owner._dead then
        owner:_measure()
        owner:_stateRender()
    end
end


function U.section(owner: any, host: Instance, options: any, compact: boolean?): any
    local c = U.cfg(options)
    local w = owner._w
    local root = U.frame(host, { AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) })
    local sec = U.node(w, P.Section, "Section", c, owner, root)
    sec._small, sec._collapsed = compact == true, c.Collapsed == true
    sec._showHeading = c.ShowHeading ~= false and c.Name ~= nil and c.Name ~= ""
    sec._collapsible = c.Collapsible ~= false
    U.layout(root, 0)
    local accent, symbol
    local heading = U.button(sec, sec._life, root, {
        Size = UDim2.new(1, 0, 0, 34),
        LayoutOrder = -1,
        Name = "SectionHeading",
    }, function()
        if sec._collapsible then
            sec:ToggleCollapsed()
        end
    end)
    local caption, headerColor = U.text(w, sec._life, heading, "Section", "", function(colors: Payload)
        return if sec:_isDisabled() then colors.TextDisabled else colors.TextSecondary
    end, { Size = UDim2.new(1, -26, 1, 0) })
    accent =
        U.line(w, sec._life, heading, "Divider", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1) })
    symbol = U.icon(w, sec._life, heading, "down", 11, "TextMuted", {
        AnchorPoint = V(1, 0.5),
        Position = UDim2.new(1, -1, 0.5, 0),
        Size = O(14, 14),
    })
    sec._host = U.frame(root, { LayoutOrder = 0, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) })
    U.layout(sec._host, 0)
    function sec:_stateRender()
        heading.Selectable = self._collapsible and not self:_isDisabled()
        heading.Interactable = heading.Selectable
        self._host.Interactable = not self:_isDisabled() and not self._collapsed
        headerColor()
    end
    function sec:_metaRender()
        local description = if self._description ~= "" then "  ·  " .. self._description else ""
        caption.Text = self._name .. description
        heading.Visible = self._showHeading
        symbol.Visible = self._collapsible
        symbol.Rotation = if self._collapsed then -90 else 0
        self._host.Visible = not self._collapsed
        accent.Visible = self._showHeading
    end
    function sec:_measure()
        heading.Size = UDim2.new(1, 0, 0, math.max(34, w._layout.Hit))
    end
    sec._tooltipHook = function()
        U.hints(sec, heading)
    end
    sec:_tooltipHook()
    U.focusable(sec, sec._life, heading, function()
        if sec._collapsible then
            sec:ToggleCollapsed()
        end
    end)
    w._responsive[sec] = true
    sec._life:Give(function()
        w._responsive[sec] = nil
    end)
    sec:_metaRender()
    sec:_stateRender()
    sec:_measure()
    return sec
end

function P.Section:SetCollapsed(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetCollapsed", "expected boolean")
    end
    if v == self._collapsed then
        return true
    end
    self._collapsed = v
    if v then
        for _, child in self._children do
            self._w:_quiet(child)
        end
    end
    self:_metaRender()
    self:_stateRender()
    self._w:_syncAnimations()
    return true
end
function P.Section:IsCollapsed(): boolean
    return self._collapsed
end
function P.Section:ToggleCollapsed()
    return self:SetCollapsed(not self._collapsed)
end
function P.Section:SetShowHeading(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetShowHeading", "expected boolean")
    end
    self._showHeading = v
    self:_metaRender()
    return true
end

function P.Tab:AddSection(options: any)
    local sub = self._wantedSub or self._subs[1]
    if sub then
        return sub:AddSection(options)
    end
    return U.adopt(self, U.section(self, self._view.contents, options))
end
function P.SubTab:AddSection(options: any)
    return U.adopt(self, U.section(self, self._view.contents, options))
end
function P.SubTab:GetSections(): { any }
    return U.sort(self._children)
end
function P.Tab:GetSections(): { any }
    local sub = self._wantedSub or self._subs[1]
    return if sub then sub:GetSections() else U.sort(self._children)
end

function P.Group:_measure()
    local root = self._root
    local w = self._w
    local width = root.AbsoluteSize.X / w._scale
    if width < 1 then
        width = math.max(1, w._layout.Width - w._layout.Sidebar - w._layout.Left - w._layout.Right)
    end
    local cols = math.clamp(math.floor((width + self._gap) / (self._min + self._gap)), 1, self._columns)
    local children = U.sort(self._children)
    local heights, active = {}, {}
    for _, n in children do
        if n._visible and not n._dependencyHidden then
            table.insert(active, n)
            local group = math.ceil(#active / cols)
            heights[group] = math.max(heights[group] or 0, n._height or n._root.Size.Y.Offset)
        end
    end
    local y, line = 0, 1
    for i, n in active do
        local column = (i - 1) % cols
        if column == 0 and i > 1 then
            y += heights[line]
            line += 1
        end
        n._root.Position = UDim2.new(column / cols, column * self._gap / cols, 0, y)
        n._root.Size = UDim2.new(1 / cols, -self._gap * (cols - 1) / cols, 0, n._height or n._root.Size.Y.Offset)
    end
    self._height = y + (heights[line] or 0)
    local x = root.Size.X
    if root.Size.Y.Offset ~= self._height then
        root.Size = UDim2.new(x.Scale, x.Offset, 0, self._height)
        U.parentChanged(self, "height")
    end
end
function P.Group:_childChanged()
    U.later(self, self._life, "flow", nil, function()
        self:_measure()
    end)
end
function P.Group:SetColumns(v: number)
    if not U.finite(v) or v < 1 or v > 8 then
        return U.issue(self, "SetColumns", "expected 1–8 columns")
    end
    self._columns = math.floor(v)
    self:_childChanged()
    return true
end
function P.Group:GetColumns(): number
    return self._columns
end

function P.Collection:AddInlineGroup(options: any)
    local c = U.cfg(options)
    local root = U.frame(self._host, { Size = UDim2.new(1, 0, 0, 0) })
    local n = U.node(self._w, P.Group, "InlineGroup", c, self, root)
    n._host, n._small = root, self._small
    n._columns = math.clamp(math.floor(U.number(c.Columns, 2)), 1, 8)
    n._min = math.clamp(U.number(c.MinimumWidth, D.InlineMin), 108, 420)
    n._gap = math.clamp(U.number(c.Gap, D.InlineGap), 0, 42)
    n._life:Give(root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        n:_childChanged()
    end))
    return U.adopt(self, n)
end

function U.row(owner: any, kind: string, c: Payload, variant: string): any
    local w = owner._w
    local root = U.frame(owner._host, { Size = UDim2.new(1, 0, 0, 0), Name = kind })
    local n = U.node(w, P.Row, kind, c, owner, root)
    n._variant, n._interactive, n._small = variant, {}, owner._small == true
    n._locked = c.Locked == true
    n._lockOptions = if type(c.LockOptions) == "table" then table.clone(c.LockOptions)
        elseif type(c.Premium) == "table" then table.clone(c.Premium)
        else {}
    n._pendingDependency, n._pendingDependencyMode = c.DependsOn, c.DependencyMode
    n._heightBase = if owner._small
        then (if variant == "numeric" then 52 else 33)
        elseif variant == "numeric" then D.NumericRow
        elseif variant == "check" then D.CheckRow
        else D.Row
    if U.finite(c.Height) then
        n._heightBase = math.clamp(c.Height, 1, 2000)
    end
    n._titleLeft, n._reserve = 0, 0
    n._heading = U.frame(root, { Name = "Heading", Size = UDim2.new(1, 0, 0, 0) })
    n._title, n._refreshTitle = U.text(w, n._life, n._heading, "Control", n._name, function(t: Payload)
        return if n._locked then t.TextSecondary
            elseif n:_isDisabled() then t.TextDisabled
            elseif n._dim or n._dependencyDim then t.Subdued
            else t.Text
    end, { Size = S(1, 1) })
    function n:_descriptionWidget()
        if self._desc then
            return self._desc
        end
        self._desc, self._refreshDescription = U.text(
            w,
            self._life,
            root,
            "Muted",
            self._description,
            function(t: Payload)
                return if self:_isDisabled() then t.TextDisabled elseif self._dependencyDim then t.Subdued else t.TextSecondary
            end,
            { Visible = false }
        )
        return self._desc
    end
    n._divider = U.line(w, n._life, root, "Divider", {
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        Name = "Divider",
    })
    n._divider.Visible = c.Separator ~= false
    if type(c.Context) == "table" or type(c.ContextBuild) == "function" then
        n._context = { Items = c.Context, Build = c.ContextBuild, Width = c.ContextWidth, Left = true }
    end

    function n:_ensureLockChrome()
        if self._lockChip then
            return
        end
        local chip = U.make("TextButton", self._heading, {
            Name = "PremiumLock",
            Size = O(78, 22),
            BackgroundTransparency = 0,
            Text = "",
            AutoButtonColor = false,
            Active = true,
            Selectable = true,
            ZIndex = 12,
            Visible = false,
        })
        self._life:Give(chip)
        U.corner(chip, 6)
        self._lockFill = U.fill(w, self._life, chip, "AccentMuted")
        local stroke = U.make("UIStroke", chip, { Thickness = 1, Transparency = 0.42 })
        self._life:Give(stroke)
        self._lockStroke = U.paint(w, self._life, stroke, "Color", "Accent")
        local icon = U.icon(w, self._life, chip, "lock", 11, "Accent", {
            Position = O(7, 3),
            Size = O(16, 16),
            ZIndex = chip.ZIndex + 1,
        })
        local label = U.text(w, self._life, chip, "Footer", "PREMIUM", "Accent", {
            Position = O(24, 0),
            Size = UDim2.new(1, -28, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = chip.ZIndex + 1,
        })
        label.FontFace = MEDIUM
        self._lockChip, self._lockIcon, self._lockLabel = chip, icon, label
        local function open()
            if self._locked and self:_canLockedAction() then
                self:OpenLocked()
            end
        end
        self._life:Give(chip.Activated:Connect(open))
        U.focusable(self, self._life, chip, open, true)
    end

    function n:_lockRender()
        if not self._locked and not self._lockChip then
            return
        end
        self:_ensureLockChrome()
        self._lockChip.Visible = self._locked
        self._lockChip.Interactable = self._locked and self:_canLockedAction()
        self._lockChip.Selectable = self._lockChip.Interactable
        local options = self._lockOptions or {}
        self._lockLabel.Text = U.str(options.Badge, "PREMIUM")
        if self._lockFill then self._lockFill() end
        if self._lockStroke then self._lockStroke() end
    end

    function n:_headingLayout()
        local g = w._layout
        local dependencyInset = if self._settings then 24 else 0
        local x, reserve = self._titleLeft + dependencyInset, self._reserve
        local width = root.AbsoluteSize.X / w._scale
        if self._settings and self._settings._layoutChevron then
            self._settings:_layoutChevron()
        end
        if self._reserveWidth then
            reserve = self:_reserveWidth(width)
        end
        if self._reserveRatio then
            reserve = math.floor(math.max(reserve, (root.AbsoluteSize.X / w._scale) * self._reserveRatio))
        end
        local gear = self._gear and self._gear.Visible
        local gearWidth = if gear then (if g.Touch then g.Hit else 25) else 0
        if gear then
            local maxPosition = math.max(x, width - (reserve + gearWidth))
            self._gear.Position = O(math.min(maxPosition, x + U.measure(self._name, D.Typography.Control) + 7), 0)
            self._gear.Size = UDim2.new(0, gearWidth, 1, 0)
        end
        local right = if gear then math.max(reserve, width - self._gear.Position.X.Offset) else reserve
        self._title.Position = O(x, 0)
        local lockRight = right
        if self._locked then
            self:_ensureLockChrome()
            local chipWidth = 78
            local textWidth = U.measure(self._name, D.Typography.Control)
            local chipX = math.min(x + textWidth + 9, math.max(x, width - right - chipWidth - 5))
            self._lockChip.Position = O(chipX, math.max(0, (self._heading.AbsoluteSize.Y / w._scale - 22) / 2))
            self._lockChip.Size = O(chipWidth, 22)
            lockRight = math.max(right, width - chipX)
        elseif self._lockChip then
            self._lockChip.Visible = false
        end
        self._title.Size = UDim2.new(1, -(x + lockRight), 1, 0)
        local wrap = g.Touch
            and variant == "numeric"
            and width > x + right + 60
            and U.measure(self._name, D.Typography.Control) > width - x - right
        self._title.TextWrapped = wrap
        self._title.TextTruncate = if wrap then Enum.TextTruncate.None else Enum.TextTruncate.AtEnd
    end
    function n:_measure()
        local g = w._layout
        local base = self._heightBase
        local extra = (if self._description ~= "" and not self._hideDescription then 19 else 0)
        local h = if variant == "numeric"
            then math.max(base, (if g.Touch then 2 * g.Hit + 4 else 0))
            elseif variant == "divider" or variant == "custom" then base
            else math.max(base, g.Hit)
        self._baseHeight, self._height = h, h + extra
        local oldX = root.Size.X
        root.Size = UDim2.new(oldX.Scale, oldX.Offset, 0, self._height)
        local headingH = if variant == "numeric"
            then (if self._small then math.max(25, g.Hit) else math.max(36, g.Hit))
            else h
        self._heading.Position = O(
            0,
            if variant == "numeric" and not self._small
                then (if g.Touch then 2 else 12)
                else U.number(c.ContentOffset, 0)
        )
        self._heading.Size = UDim2.new(1, 0, 0, headingH)
        if extra > 0 then
            local desc = self:_descriptionWidget()
            desc.Text = self._description
            local descriptionLeft = self._titleLeft + (if self._settings then 24 else 0)
            desc.Position = O(descriptionLeft, h - 2)
            desc.Size = UDim2.new(1, -(descriptionLeft + 8), 0, 18)
            desc.Visible = true
        elseif self._desc then
            self._desc.Visible = false
        end
        self:_headingLayout()
        if self._layoutRender then
            self:_layoutRender()
        end
        U.parentChanged(self, "height")
    end
    function n:_metaRender()
        self._title.Text = self._name
        self:_measure()
    end
    function n:_stateRender()
        local enabled = not self:_isDisabled()
        for object, available in self._interactive do
            local live = enabled and (available == true or available())
            object.Interactable = live
            object.Selectable = live
        end
        self:_refreshTitle()
        if self._refreshDescription then
            self:_refreshDescription()
        end
        if self._valueRender then
            self:_valueRender(true)
        end
        if self._stateEffect then
            self:_stateEffect()
        end
        if self._lockRender then
            self:_lockRender()
        end
    end
    function n:_makeOptionsGear()
        if self._gear or c.HideOptions then
            return
        end
        n._gear = U.button(n, n._life, n._heading, { ZIndex = 5, Name = "Options" }, function()
            n:ToggleContext()
        end)
        U.icon(w, n._life, n._gear, "gear", D.Gear, "TextMuted", { Size = S(1, 1) })
        n._interactive[n._gear] = true
        U.focusable(n, n._life, n._gear, function()
            n:ToggleContext()
        end)
        self:_watchSize()
    end
    function n:_watchSize()
        if self._watchingSize then
            return
        end
        self._watchingSize = true
        n._life:Give(root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if n._dead then
                return
            end
            n:_headingLayout()
            if n._resizeContent then
                n:_resizeContent()
            end
        end))
    end
    if n._context then
        n:_makeOptionsGear()
    end
    if variant == "numeric" or variant == "check" then
        n:_watchSize()
    end
    n._tooltipHook = function()
        U.hints(n, root)
    end
    n:_tooltipHook()
    w._responsive[n] = true
    n._life:Give(function()
        w._responsive[n] = nil
    end)
    return n
end

function U.ready(owner: any, n: any): any
    if n._reserveRatio or n._reserveWidth then
        n:_watchSize()
    end
    n:_measure()
    n:_stateRender()
    U.adopt(owner, n)
    if n._pendingDependency ~= nil then
        n:SetDependency(n._pendingDependency, n._pendingDependencyMode)
        n._pendingDependency, n._pendingDependencyMode = nil, nil
    end
    if n._w and n._w._profileManager and n._flag then
        n._w._profileManager:Hydrate(n)
    end
    if n._locked and (n._kind == "Toggle" or n._kind == "Checkbox") and n._value == true and n.SetValue then
        n:SetValue(false, true)
    end
    if n._lockRender then
        n:_lockRender()
        n:_measure()
    end
    return n
end

function U.rowButton(n: any, parent: any, props: Payload, fire: any, visual: any?): any
    local b = U.button(n, n._life, parent, props, fire, visual)
    n._interactive[b] = true
    U.focusable(n, n._life, b, fire)
    return b
end

function U.context(owner: any, target: GuiObject, cfg: Payload): any
    local w = owner._w
    if owner._popup then
        w:_closeFrom(owner._popup, true)
    end
    local width = math.clamp(U.number(cfg.Width, 192), 130, 415)
    local p = U.popup(owner, target, V(width, 165), { Left = cfg.Left, HasSection = type(cfg.Build) == "function" })
    if not p then
        return nil
    end
    p.kind = "context"
    if type(cfg.Build) == "function" then
        local section = U.section(owner, p.content, { ShowHeading = false, Name = "Options" }, true)
        p.life:Give(section)
        local ok = U.call(owner, "ContextBuild", cfg.Build, section, owner)
        if not ok or p.dead then
            if not p.dead then
                w:_closeFrom(p, true)
            end
            return nil
        end
        local function size()
            local h = section._root and section._root.AbsoluteSize.Y / w._scale or 0
            p.height = math.max(41, h + 8)
            if not p.dead then
                w:_placePopup(p)
            end
        end
        section._root.Position = O(7, 4)
        section._root.Size = UDim2.new(1, -14, 0, 0)
        p.input:Give(section._root:GetPropertyChangedSignal("AbsoluteSize"):Connect(size))
        size()
    else
        local panel = p.content
        local path = { { items = if type(cfg.Items) == "table" then cfg.Items else {}, name = "" } }
        local function draw()
            p.life:Remove("actions")
            local life = U.scope()
            p.life:Give(life, "actions")
            local itemHost = U.frame(panel, { Position = O(5, 4), Size = UDim2.new(1, -10, 1, -8) })
            life:Give(itemHost)
            U.layout(itemHost, 1)
            local depth = #path
            local h = math.max(D.Option, w._layout.Hit)
            local function action(title: string, icon: string?, order: number, disabled: boolean, fn: any)
                local b = U.button(owner, life, itemHost, {
                    Size = UDim2.new(1, 0, 0, h),
                    LayoutOrder = order,
                    Interactable = not disabled,
                    Selectable = not disabled,
                }, fn)
                local label = U.text(
                    w,
                    life,
                    b,
                    "Popup",
                    title,
                    if disabled then "TextDisabled" else "Text",
                    { Position = O(8, 0), Size = UDim2.new(1, -30, 1, 0) }
                )
                if icon then
                    U.icon(w, life, b, icon, 11, "TextSecondary", {
                        AnchorPoint = V(1, 0.5),
                        Position = UDim2.new(1, -7, 0.5, 0),
                        Size = O(16, 16),
                    })
                end
                if not disabled then
                    life:Give(b.MouseEnter:Connect(function()
                        label.TextColor3 = w._theme._colors.TextSecondary
                    end))
                    life:Give(b.MouseLeave:Connect(function()
                        label.TextColor3 = w._theme._colors.Text
                    end))
                    U.focusable(owner, life, b, fn)
                end
            end
            local shown = 0
            if depth > 1 then
                action(path[depth].name, "left", 0, false, function()
                    table.remove(path)
                    draw()
                end)
                shown += 1
            end
            for _, it in path[depth].items do
                if type(it) == "table" then
                    shown += 1
                    local title = U.str(it.Name or it.Text, "Action")
                    action(
                        title,
                        if type(it.Items) == "table" then "right" else nil,
                        shown,
                        it.Disabled == true,
                        function()
                            if type(it.Items) == "table" and #path < 12 then
                                table.insert(path, { items = it.Items, name = title })
                                draw()
                            else
                                w:_closeFrom(p)
                                U.call(owner, "Context action", it.Callback, owner, it)
                            end
                        end
                    )
                end
            end
            if shown == 0 then
                action("No actions", nil, 0, true, nil)
                shown = 1
            end
            p.height = shown * (h + 1) + 8
            w:_placePopup(p)
        end
        draw()
    end
    U.emit(owner, "ContextOpened", owner)
    if owner._kind == "ContextMenu" then
        U.emit(owner, "Opened", owner)
    end
    return p
end

function P.Row:SetContext(items: any, builder: any?)
    if items ~= nil and type(items) ~= "table" then
        return U.issue(self, "SetContext", "expected action array or nil")
    end
    if builder ~= nil and type(builder) ~= "function" then
        return U.issue(self, "SetContext", "expected builder function or nil")
    end
    if self._popup and self._popup.kind == "context" then
        self._w:_closeFrom(self._popup, true)
    end
    self._context = if items or builder then { Items = items, Build = builder, Left = true } else nil
    if self._context then
        self:_makeOptionsGear()
    end
    if self._gear then
        self._gear.Visible = self._context ~= nil
    end
    self:_measure()
    self:_tooltipHook()
    return true
end
function P.Row:OpenContext(): boolean
    if not self._context then
        return false
    end
    if self._popup and self._popup.kind == "context" then
        return true
    end
    return U.context(self, if self._gear and self._gear.Visible then self._gear else self._root, self._context) ~= nil
end
function P.Row:OnContextOpened(fn: any): Connection
    return U.event(self, "ContextOpened"):Connect(fn)
end
function P.Row:OnContextClosed(fn: any): Connection
    return U.event(self, "ContextClosed"):Connect(fn)
end
function P.Row:CloseContext()
    if self._popup and self._popup.kind == "context" then
        self._w:_closeFrom(self._popup)
    end
end
function P.Row:ToggleContext()
    if self._popup and self._popup.kind == "context" then
        self:CloseContext()
    else
        self:OpenContext()
    end
end


function P.Row:SetLockOptions(options: any)
    if options ~= nil and type(options) ~= "table" then
        return U.issue(self, "SetLockOptions", "expected options table or nil")
    end
    self._lockOptions = if type(options) == "table" then table.clone(options) else {}
    if self._lockRender then
        self:_lockRender()
        self:_measure()
    end
    return true
end

function P.Row:GetLockOptions(): any
    return table.clone(self._lockOptions or {})
end

function P.Row:SetLocked(value: boolean, silentOrOptions: any?, options: any?)
    if type(value) ~= "boolean" then
        return U.issue(self, "SetLocked", "expected boolean")
    end
    local silent = false
    local lockOptions = options
    if type(silentOrOptions) == "boolean" then
        silent = silentOrOptions
    elseif type(silentOrOptions) == "table" then
        lockOptions = silentOrOptions
    elseif silentOrOptions ~= nil then
        return U.issue(self, "SetLocked", "second argument must be boolean or options table")
    end
    if lockOptions ~= nil then
        local ok = self:SetLockOptions(lockOptions)
        if ok ~= true then return ok end
    end
    if self._locked == value then
        if self._lockRender then self:_lockRender() end
        return true
    end
    self._locked = value
    self._w:_quiet(self)
    if self._popup and self._popup.kind == "premium" then
        self._w:_closeFrom(self._popup, true)
    end
    if value and (self._kind == "Toggle" or self._kind == "Checkbox") and self._value == true and self.SetValue then
        self:SetValue(false, silent)
    end
    self:_refreshState()
    self:_measure()
    U.parentChanged(self, "locked")
    if self._w and self._w._syncDependencies then
        self._w:_syncDependencies(self)
    end
    U.emit(self, "LockedChanged", value, self)
    return true
end

function P.Row:IsLocked(): boolean
    return self._locked == true
end

function P.Row:GetLocked(): boolean
    return self:IsLocked()
end

function P.Row:OnLockedChanged(fn: any): Connection
    return U.event(self, "LockedChanged"):Connect(fn)
end

function P.Row:OnLockedOpened(fn: any): Connection
    return U.event(self, "LockedOpened"):Connect(fn)
end

function P.Row:OpenLocked(): boolean
    if not self._locked or not self:_canLockedAction() then
        return false
    end
    if self._popup and self._popup.kind == "premium" then
        return true
    end
    local w = self._w
    local options = self._lockOptions or {}
    local width = math.clamp(U.number(options.Width, 304), 230, 390)
    local height = math.clamp(U.number(options.Height, 174), 150, 240)
    local anchor = self._lockChip or self._root
    local p = U.popup(self, anchor, V(width, height), { Left = true })
    if not p then return false end
    p.kind = "premium"
    local life, host = p.life, p.content
    local accentRail = U.line(w, life, host, "Accent", {
        Position = O(0, 0),
        Size = UDim2.new(0, 2, 1, 0),
        Name = "PremiumRail",
    })
    U.corner(accentRail, 2)
    local iconHost = U.frame(host, {
        Position = O(13, 13),
        Size = O(30, 30),
        BackgroundTransparency = 0,
        Name = "PremiumIcon",
    })
    life:Give(iconHost)
    U.corner(iconHost, 7)
    U.fill(w, life, iconHost, "AccentMuted")
    U.icon(w, life, iconHost, U.str(options.Icon, "lock"), 15, "Accent", { Size = S(1, 1) })
    local title = U.text(w, life, host, "Popup", U.str(options.Title, "Premium Required"), "Text", {
        Position = O(52, 10),
        Size = UDim2.new(1, -66, 0, 24),
    })
    title.FontFace = BOLD
    local feature = U.str(options.Feature, self._name)
    local reason = U.str(options.Reason, "Unlock " .. feature .. " with Premium.")
    U.text(w, life, host, "Muted", reason, "TextSecondary", {
        Position = O(13, 48),
        Size = UDim2.new(1, -26, 0, 54),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
    })
    local action = U.button(w, life, host, {
        AnchorPoint = V(0, 1),
        Position = UDim2.new(0, 13, 1, -13),
        Size = UDim2.new(1, -26, 0, math.max(36, w._layout.Hit)),
        BackgroundTransparency = 0,
        Name = "PremiumAction",
    }, function()
        if not self._locked then return end
        local callback = options.Callback
        local ok = true
        if type(callback) == "function" then
            ok = select(1, U.call(self, "LockedAction", callback, self))
        else
            local url = U.str(options.URL, w._premiumURL)
            ok = url ~= "" and U.copyText(url)
            w:Notify({
                Title = if ok then "Purchase link copied" else "Clipboard unavailable",
                Description = if ok then url else "Unable to copy the premium purchase link.",
                Severity = if ok then "Success" else "Warning",
                Duration = 3,
            })
        end
        if ok and not p.dead then w:_closeFrom(p) end
    end)
    U.corner(action, 6)
    U.fill(w, life, action, "Accent")
    local actionText = U.text(w, life, action, "Control", U.str(options.ActionText, "Buy Premium"), "AccentInk", {
        Position = O(12, 0),
        Size = UDim2.new(1, -42, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    actionText.FontFace = MEDIUM
    U.icon(w, life, action, "crown", 13, "AccentInk", {
        AnchorPoint = V(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = O(17, 17),
    })
    U.emit(self, "LockedOpened", self)
    return true
end

P.ValueRow = U.class(P.Row)
for name, method in P.Value do
    if name ~= "__index" then
        P.ValueRow[name] = method
    end
end
P.Check = U.class(P.ValueRow)
P.Keybind = U.class(P.ValueRow)
P.Numeric = U.class(P.ValueRow)
P.Slider = U.class(P.Numeric)
P.Range = U.class(P.Slider)

function U.bool(_: any, v: any)
    if type(v) ~= "boolean" then
        return false, nil, "expected boolean"
    end
    return true, v
end

function U.endCapture(n: any)
    if Capturing ~= n then
        return
    end
    Capturing = nil
    local popup = n._capturePopup
    n._capturePopup = nil
    if popup and not popup.dead then
        n._w:_closeFrom(popup, true)
    end
    if n._bindRender and not n._dead then
        n:_bindRender()
    end
end

function U.touchCapture(n: any)
    local w = n._w
    if not w._layout.Touch or not n._captureAnchor then
        return
    end
    local h = math.max(D.TouchHit, w._layout.Hit)
    local p = U.popup(n, n._captureAnchor, V(218, 2 * h + 48))
    if not p then
        return
    end
    p.kind = "capture"
    n._capturePopup = p
    local life = p.life
    local help = U.text(w, life, p.content, "Popup", "Key name or hardware key", "TextSecondary", {
        Position = O(8, 4),
        Size = UDim2.new(1, -16, 0, 23),
    })
    local box = U.field(w, life, p.content, "Popup", {
        PlaceholderText = "Example: G",
        Name = "KeyName",
        Position = O(8, 30),
        Size = UDim2.new(1, -16, 0, h),
    })
    U.fill(w, life, box, "SurfaceRaised")
    U.corner(box, D.FieldRadius)
    U.padding(box, 7, 0)
    local function action(text: string, col: number, fire: any)
        local b = U.button(n, life, p.content, {
            Position = UDim2.new(col / 3, 8 - col * 3, 0, 36 + h),
            Size = UDim2.new(1 / 3, -7, 0, h),
        }, fire)
        U.fill(w, life, b, "SurfaceRaised")
        U.corner(b, D.FieldRadius)
        U.text(w, life, b, "Popup", text, "Text", { TextXAlignment = Enum.TextXAlignment.Center })
    end
    local function apply()
        local text = box.Text:match("^%s*(.-)%s*$") or ""
        if #text == 1 then
            text = text:upper()
        end
        local ok, key = U.key(text)
        if not ok then
            help.Text = "Unknown key name"
            return
        end
        U.endCapture(n)
        if n._kind == "Keybind" then
            n:SetValue(key)
        else
            n:SetKeybind(key)
        end
    end
    action("Set", 0, apply)
    action("Clear", 1, function()
        U.endCapture(n)
        if n._kind == "Keybind" then
            n:SetValue(nil)
        else
            n:SetKeybind(nil)
        end
    end)
    action("Cancel", 2, function()
        U.endCapture(n)
    end)
    life:Give(box.FocusLost:Connect(function(enter: boolean)
        if enter and not p.dead then
            apply()
        end
    end))
end

function U.beginCapture(n: any): boolean
    if n._capturable == false or not n:_canInteract() or Pointer then
        return false
    end
    if Capturing == n then
        U.endCapture(n)
        return true
    end
    if Capturing then
        U.endCapture(Capturing)
    end
    n._w:_hideTip()
    Capturing = n
    if n._bindRender then
        n:_bindRender()
    end
    U.touchCapture(n)
    return true
end

function U.captureInput(n: any, key: Key)
    U.endCapture(n)
    if key == Enum.KeyCode.Escape then
        return
    end
    if key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Delete then
        key = nil :: any
    end
    if n._kind == "Keybind" then
        n:SetValue(key)
    else
        n:SetKeybind(key)
    end
end

function P.Check:Toggle(silent: boolean?)
    return self:SetValue(not self._value, silent)
end
function P.Check:SetKeybind(key: any)
    local ok, k = U.key(key)
    if not ok then
        return U.issue(self, "SetKeybind", "expected a key or nil")
    end
    if k ~= self._key and self._keyRestore ~= nil then
        local held = self._keyRestore
        self._keyRestore = nil
        self:SetValue(held, true)
    end
    local changedKey = self._key ~= k
    self._key = k
    self._bindSlot = self._bindSlot or k ~= nil
    self._w._keys[self] = if k then true else nil
    self:_bindRender()
    if changedKey and self._w and self._w._profileManager and self._flag then
        self._w._profileManager:ControlChanged(self)
    end
    self:_measure()
    self:_stateRender()
    return true
end
function P.Check:GetKeybind(): any
    return self._key
end
function P.Check:GetKeybindMode(): string
    return self._keyMode
end
function P.Check:SetKeybindMode(mode: string)
    if mode ~= "Toggle" and mode ~= "Hold" then
        return U.issue(self, "SetKeybindMode", "expected Toggle or Hold")
    end
    if self._keyMode ~= mode and self._keyRestore ~= nil then
        local before = self._keyRestore
        self._keyRestore = nil
        self:SetValue(before, true)
    end
    local changedMode = self._keyMode ~= mode
    self._keyMode = mode
    if changedMode and self._w and self._w._profileManager and self._flag then
        self._w._profileManager:ControlChanged(self)
    end
    return true
end
function P.Check:BeginCapture()
    return U.beginCapture(self)
end
function P.Check:CancelCapture()
    U.endCapture(self)
end
function P.Check:IsCapturing(): boolean
    return Capturing == self
end
function P.Check:_captureInput(key: Key)
    U.captureInput(self, key)
end
function P.Check:_keyInput(key: Key, down: boolean)
    if key ~= self._key or self:_isDisabled() then
        return
    end
    if self._keyMode ~= "Hold" then
        if down then
            self:Toggle()
        end
    elseif down and self._keyRestore == nil then
        self._keyRestore = self._value
        self:SetValue(true)
    elseif not down and self._keyRestore ~= nil then
        local restore = self._keyRestore
        self._keyRestore = nil
        self:SetValue(restore)
    end
end
P.Check._normalize = U.bool

function Build.Check(owner: any, c: Payload, kind: string)
    local n = U.row(owner, kind, c, "check")
    setmetatable(n, P.Check)
    local w, life = n._w, n._life
    local switch = c.Style == "Switch"
    n._titleLeft = if switch then 56 else 44
    n._bindSlot = c.ShowKeybind == true or c.Keybind ~= nil
    local _, key = U.key(c.Keybind)
    n._key, n._keyMode = key, if c.KeybindMode == "Hold" then "Hold" else "Toggle"
    local state, redraw: (() -> ())? = "idle", nil
    local hit = U.rowButton(n, n._heading, { Name = "CheckTarget", Size = S(1, 1) }, function()
        n:Toggle()
    end, function(nextState: string)
        state = nextState
        if redraw then
            redraw()
        end
    end)
    local size = if switch then 34 else D.Check
    local box = U.frame(hit, { Name = "Check", AnchorPoint = V(0, 0.5), Position = S(0, 0.5), Size = O(size, D.Check) })
    U.corner(box, if switch then 11 else 3)
    local glyph, dot
    if switch then
        dot = U.line(w, life, box, "Thumb", { AnchorPoint = V(0.5, 0.5), Size = O(12, 12), Position = S(0.28, 0.5) })
        U.corner(dot, 9)
    else
        glyph = U.icon(w, life, box, "check", 15, "AccentInk", { Size = S(1, 1), Visible = false })
    end
    local glyphScale = if glyph then U.make("UIScale", glyph, { Scale = 1 }) else nil
    local boxColor = U.paint(w, life, box, "BackgroundColor3", function(t: Payload)
        if n:_isDisabled() then
            return if n._value then t.AccentMuted else t.Row
        end
        return if n._value
            then (if state == "press" then t.Accent:Lerp(t.Background, 0.12) else t.Accent)
            elseif state ~= "idle" then t.Hover
            else t.Surface
    end)
    redraw = boxColor
    box.BackgroundTransparency = 0
    local keyHit = U.rowButton(n, n._heading, {
        AnchorPoint = V(1, 0),
        Position = S(1, 0),
        Size = UDim2.new(0, 86, 1, 0),
        ZIndex = 3,
        Name = "Binding",
    }, function()
        n:BeginCapture()
    end)
    local keyLabel, keyPaint = U.text(w, life, keyHit, "Numeric", "", function(t: Payload)
        return if Capturing == n then t.Accent elseif n:_isDisabled() then t.TextDisabled else t.Subdued
    end, { TextXAlignment = Enum.TextXAlignment.Right })
    n._captureAnchor = keyHit
    n._interactive[keyHit] = function()
        return n._bindSlot
    end
    function n:_bindRender()
        keyLabel.Text = if Capturing == self then "[PRESS KEY]" else U.keyText(self._key)
        keyPaint()
        keyHit.Visible = self._bindSlot
        self._reserve = if self._bindSlot
            then math.max(w._layout.Hit, U.measure(keyLabel.Text, D.Typography.Numeric) + 8)
            else 0
        keyHit.Size = UDim2.new(0, self._reserve, 1, 0)
        self:_headingLayout()
    end
    function n:_layoutRender()
        self._titleLeft = if w._layout.Touch then (if switch then 46 else 33) else (if switch then 56 else 44)
        self:_bindRender()
        hit.Size = UDim2.new(1, -self._reserve, 1, 0)
    end
    function n:_valueRender(instant: boolean)
        self._dim = not self._value and c.DimUnchecked ~= false
        self:_refreshTitle()
        boxColor()
        if glyph and glyphScale then
            local before = glyph.Visible
            glyph.Visible = self._value == true
            if glyph.Visible and not before and not instant then
                glyphScale.Scale = 0.78
            end
            U.tween(w, life, glyphScale, "glyph", "state", { Scale = 1 }, instant or not glyph.Visible)
        end
        if dot then
            U.tween(w, life, dot, "switch", "state", { Position = S(if self._value then 0.72 else 0.28, 0.5) }, instant)
        end
        self:_bindRender()
    end
    function n:_stateEffect()
        if self:_isDisabled() and self._keyRestore ~= nil then
            local original = self._keyRestore
            self._keyRestore = nil
            self:SetValue(original, true)
        end
    end
    if key then
        w._keys[n] = true
    end
    life:Give(function()
        w._keys[n] = nil
        U.endCapture(n)
    end)
    U.value(n, c, false)
    return U.ready(owner, n)
end

local modes = { Toggle = true, Hold = true, Press = true, Always = true }

P.Keybind._normalize = function(_: any, v: any)
    local ok, k = U.key(v)
    return ok, k, "expected Enum.KeyCode, mouse button or nil"
end

function P.Keybind:_activeSet(v: boolean, silent: boolean?)
    if v == self._active then
        return
    end
    self._active = v
    self:_bindRender()
    if not silent then
        local stage = if v then "Activated" else "Deactivated"
        U.call(self, stage, if v then self._onActivate else self._onDeactivate, self._value, self)
        U.emit(self, stage, self._value, self)
    end
end

function P.Keybind:GetMode(): string
    return self._mode
end
function P.Keybind:SetMode(v: string)
    if type(v) ~= "string" or not modes[v] then
        return U.issue(self, "SetMode", "expected Toggle, Hold, Press or Always")
    end
    if v ~= self._mode then
        self._mode = v
        self:_activeSet(v == "Always" and self._enabled and not self:_isDisabled())
        self:_bindRender()
        if self._w and self._w._profileManager and self._flag then
            self._w._profileManager:ControlChanged(self)
        end
    end
    return true
end
function P.Keybind:GetKey(): any
    return self:GetValue()
end
function P.Keybind:SetKey(v: any, silent: boolean?)
    return self:SetValue(v, silent)
end
function P.Keybind:SetEnabled(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetEnabled", "expected boolean")
    end
    if self._enabled == v then
        return true
    end
    self._enabled = v
    if not v then
        U.endCapture(self)
    end
    self:_activeSet(v and self._mode == "Always" and not self:_isDisabled())
    self:_stateRender()
    return true
end
function P.Keybind:IsEnabled(): boolean
    return self._enabled
end
function P.Keybind:BeginCapture()
    return self._enabled and U.beginCapture(self)
end
function P.Keybind:CancelCapture()
    U.endCapture(self)
end
function P.Keybind:IsCapturing(): boolean
    return Capturing == self
end
function P.Keybind:IsActive(): boolean
    return self._active
end
function P.Keybind:OnActivated(fn: any): Connection
    return U.event(self, "Activated"):Connect(fn)
end
function P.Keybind:OnDeactivated(fn: any): Connection
    return U.event(self, "Deactivated"):Connect(fn)
end
function P.Keybind:_captureInput(key: Key)
    U.captureInput(self, key)
end
function P.Keybind:_keyInput(key: Key, down: boolean)
    if key ~= self._value or not self._enabled or self:_isDisabled() or self._mode == "Always" then
        return
    end
    if self._mode == "Hold" then
        self:_activeSet(down)
    elseif down then
        if self._mode == "Toggle" then
            self:_activeSet(not self._active)
        else
            self:_activeSet(true)
            if not self._dead then
                self:_activeSet(false)
            end
        end
    end
end

function Build.Keybind(owner: any, c: Payload)
    local n = U.row(owner, "Keybind", c, "normal")
    setmetatable(n, P.Keybind)
    local w, life = n._w, n._life
    n._mode = if type(c.Mode) == "string" and modes[c.Mode] then c.Mode else "Toggle"
    n._enabled, n._active, n._capturable = c.Enabled ~= false, false, c.Capturable ~= false
    n._reserve = 100
    n._title.Visible = c.HideLabel ~= true
    n._onActivate, n._onDeactivate = c.Activated, c.Deactivated
    local btn = U.rowButton(n, n._heading, {
        AnchorPoint = V(1, 0),
        Position = S(1, 0),
        Size = UDim2.new(0, 116, 1, 0),
        Name = "Capture",
    }, function()
        n:BeginCapture()
    end)
    n._captureAnchor = btn
    n._interactive[btn] = function()
        return n._enabled and n._capturable
    end
    local display, refresh = U.text(w, life, btn, "Numeric", "", function(t: Payload)
        return if n:_isDisabled() or not n._enabled
            then t.TextDisabled
            elseif n._active or Capturing == n then t.Accent
            else t.TextSecondary
    end, { TextXAlignment = Enum.TextXAlignment.Right })
    function n:_reserveWidth(width: number): number
        if c.HideLabel then
            btn.Size = S(1, 1)
            return width
        end
        local want = math.max(w._layout.Hit, U.measure(display.Text, D.Typography.Numeric) + 13, 53)
        local actual = math.min(math.max(44, width * 0.62), want)
        btn.Size = UDim2.new(0, actual, 1, 0)
        return actual + 5
    end
    function n:_bindRender()
        display.Text = if Capturing == self
            then "[PRESS KEY]"
            elseif self._mode == "Always" then "[ALWAYS]"
            else U.keyText(self._value)
        self:_headingLayout()
        refresh()
    end
    n._valueRender = n._bindRender
    n._effect = function()
        n:_activeSet(n._mode == "Always" and n._enabled and not n:_isDisabled(), true)
    end
    n._stateEffect = function()
        if n._mode == "Always" or n:_isDisabled() then
            n:_activeSet(n._mode == "Always" and n._enabled and not n:_isDisabled())
        end
    end
    w._keys[n] = true
    life:Give(function()
        w._keys[n] = nil
        U.endCapture(n)
    end)
    U.value(n, c, c.Key)
    n:_activeSet(n._mode == "Always" and n._enabled and not n:_isDisabled(), true)
    return U.ready(owner, n)
end

function U.quantize(n: any, v: number): number
    local lo, hi, step = n._min, n._max, n._step
    v = math.clamp(v, lo, hi)
    if v == lo or v == hi or not step then
        return v
    end
    local k = (v - lo) / step
    if k > 9e14 then
        return v
    end
    return math.clamp(lo + math.round(k) * step, lo, hi)
end

function U.numeric(n: any, c: Payload, lo: number, hi: number, inc: number)
    n._min, n._max = U.number(c.Min, lo), U.number(c.Max, hi)
    if n._min > n._max or not U.finite(n._max - n._min) then
        U.issue(n, "Range", "invalid constructor range")
        n._min, n._max = lo, hi
    end
    n._step = if U.finite(c.Increment) and c.Increment > 0 then c.Increment else inc
    n._prefix, n._suffix = U.str(c.Prefix), U.str(c.Suffix)
    n._format = if type(c.Format) == "function" then c.Format else nil
end

function U.numText(n: any, v: number): string
    local f = n._format
    if f then
        local ok, text = U.call(n, "Format", f, v)
        if ok and type(text) == "string" and utf8.len(text) then
            return text
        end
    end
    local step = n._step or 1
    local d = 0
    while d < 7 and math.abs(step) < 1e8 and math.abs(step - math.round(step)) > 1e-7 do
        d += 1
        step *= 10
    end
    if math.abs(v) > 1e13 or (v ~= 0 and math.abs(v) < 1e-7) then
        return string.format("%.6g", v)
    end
    return string.format("%." .. d .. "f", v)
end

function P.Numeric:_normalize(v: any)
    if not U.finite(v) then
        return false, nil, "expected finite number"
    end
    return true, U.quantize(self, v)
end
function P.Numeric:_domainChanged()
    local _, def = self:_normalize(self._default)
    local _, now = self:_normalize(self._value)
    self._default = def
    local _, change = self:_commit(now, false)
    if not change and self._valueRender then
        self:_valueRender(true)
    end
    return true
end
function P.Numeric:SetRange(lo: number, hi: number)
    if not U.finite(lo) or not U.finite(hi) or lo > hi or not U.finite(hi - lo) then
        return U.issue(self, "SetRange", "expected finite min <= max and a finite span")
    end
    self._min, self._max = lo, hi
    return self:_domainChanged()
end
function P.Numeric:SetMin(n: number)
    return self:SetRange(n, self._max)
end
function P.Numeric:SetMax(n: number)
    return self:SetRange(self._min, n)
end
function P.Numeric:GetMin(): number
    return self._min
end
function P.Numeric:GetMax(): number
    return self._max
end
function P.Numeric:GetRange(): (number, number)
    return self._min, self._max
end
function P.Numeric:GetIncrement(): number
    return self._step
end
function P.Numeric:SetIncrement(v: number)
    if not U.finite(v) or v <= 0 then
        return U.issue(self, "SetIncrement", "expected positive finite increment")
    end
    self._step = v
    return self:_domainChanged()
end
function P.Numeric:SetPrefix(v: string?)
    if v ~= nil and (type(v) ~= "string" or utf8.len(v) == nil) then
        return U.issue(self, "SetPrefix", "expected text or nil")
    end
    self._prefix = v or ""
    self:_valueRender(true)
    return true
end
function P.Numeric:SetSuffix(v: string?)
    if v ~= nil and (type(v) ~= "string" or utf8.len(v) == nil) then
        return U.issue(self, "SetSuffix", "expected text or nil")
    end
    self._suffix = v or ""
    self:_valueRender(true)
    return true
end
function P.Numeric:GetPrefix(): string
    return self._prefix
end
function P.Numeric:GetSuffix(): string
    return self._suffix
end
function P.Numeric:SetFormat(v: any)
    if v ~= nil and type(v) ~= "function" then
        return U.issue(self, "SetFormat", "expected function or nil")
    end
    self._format = v
    self:_valueRender(true)
    return true
end

function P.Range:_normalize(v: any)
    if type(v) ~= "table" or not U.finite(v.Min) or not U.finite(v.Max) or v.Min > v.Max then
        return false, nil, "expected { Min = number, Max = number } with Min <= Max"
    end
    return true, { Min = U.quantize(self, v.Min), Max = U.quantize(self, v.Max) }
end
function P.Range:GetMinimumValue(): number
    return self._value.Min
end
function P.Range:GetMaximumValue(): number
    return self._value.Max
end
function P.Range:SetMinimumValue(v: number, silent: boolean?)
    if not U.finite(v) then
        return U.issue(self, "SetMinimumValue", "expected finite number")
    end
    return self:SetValue({ Min = math.min(v, self._value.Max), Max = self._value.Max }, silent)
end
function P.Range:SetMaximumValue(v: number, silent: boolean?)
    if not U.finite(v) then
        return U.issue(self, "SetMaximumValue", "expected finite number")
    end
    return self:SetValue({ Min = self._value.Min, Max = math.max(v, self._value.Min) }, silent)
end
function P.Slider:OnDragStarted(fn: any): Connection
    return U.event(self, "DragStarted"):Connect(fn)
end
function P.Slider:OnDragEnded(fn: any): Connection
    return U.event(self, "DragEnded"):Connect(fn)
end
function P.Slider:IsDragging(): boolean
    return self._dragging == true
end

function Build.Slider(owner: any, c: Payload, range: boolean)
    local n = U.row(owner, if range then "RangeSlider" else "Slider", c, "numeric")
    setmetatable(n, if range then P.Range else P.Slider)
    U.numeric(n, c, 0, 100, 1)
    local w, life = n._w, n._life
    n._reserve = if range then 118 else 55
    local readout, readColor = U.text(w, life, n._heading, "Numeric", "", function(t: Payload)
        return if n:_isDisabled() then t.TextDisabled else t.Text
    end, {
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = V(1, 0),
        Position = S(1, 0),
        Size = UDim2.new(0, n._reserve, 1, 0),
    })
    local hit = U.rowButton(n, n._root, { Name = "SliderTarget", Size = UDim2.new(1, 0, 0, 35) }, nil)
    local track = U.line(w, life, hit, "Track", {
        Name = "Track",
        AnchorPoint = V(0, 0.5),
        Position = S(0, 0.5),
        Size = UDim2.new(1, 0, 0, D.Track),
    })
    U.corner(track, 3)
    local region = U.frame(track, {
        Name = "Positions",
        Position = O(D.ThumbWidth / 2, 0),
        Size = UDim2.new(1, -D.ThumbWidth, 1, 0),
    })
    local active = U.line(w, life, region, function(t: Payload)
        return if n:_isDisabled() then t.AccentMuted else t.Accent
    end, {
        Name = "Fill",
        Size = S(0, 1),
    })
    U.corner(active, 3)
    local function thumb(name: string)
        local t = U.line(w, life, region, function(colors: Payload)
            return if n:_isDisabled()
                then colors.TextDisabled
                elseif n._focusThumb == name then colors.TextSecondary
                else colors.Thumb
        end, {
            AnchorPoint = V(0.5, 0.5),
            Position = S(0, 0.5),
            Size = O(D.ThumbWidth, D.ThumbHeight),
            Name = name,
        })
        U.corner(t, 8)
        return t
    end
    local high = thumb(if range then "Maximum" else "Thumb")
    local low = if range then thumb("Minimum") else nil
    local function fraction(v: number): number
        return if n._max == n._min then 0 else math.clamp((v - n._min) / (n._max - n._min), 0, 1)
    end
    function n:_layoutRender()
        local height = if self._small then math.max(24, w._layout.Hit) else math.max(39, w._layout.Hit)
        local centre = if w._layout.Touch
            then self._baseHeight - height / 2 - 3
            elseif self._small then self._baseHeight - 15
            else self._baseHeight - 25
        hit.Position = O(0, centre - height / 2)
        hit.Size = UDim2.new(1, 0, 0, height)
    end
    function n:_valueRender(instant: boolean)
        if self._value == nil then
            return
        end
        local a = if range then fraction(self._value.Min) else 0
        local b = fraction(if range then self._value.Max else self._value)
        if range then
            readout.Text = self._prefix
                .. U.numText(self, self._value.Min)
                .. self._suffix
                .. ", "
                .. self._prefix
                .. U.numText(self, self._value.Max)
                .. self._suffix
        else
            readout.Text = self._prefix .. U.numText(self, self._value) .. self._suffix
        end
        self._reserve = math.clamp(U.measure(readout.Text, D.Typography.Numeric) + 8, 40, 180)
        readout.Size = UDim2.new(0, self._reserve, 1, 0)
        self:_headingLayout()
        readColor()
        local snap = instant or self._dragging
        local pad = if range then 0 else -D.ThumbWidth / 2
        U.tween(
            w,
            life,
            active,
            "fill",
            "state",
            { Position = UDim2.new(a, pad, 0, 0), Size = UDim2.new(b - a, -pad, 1, 0) },
            snap
        )
        U.tween(w, life, high, "hi", "state", { Position = S(b, 0.5) }, snap)
        if low then
            U.tween(w, life, low, "lo", "state", { Position = S(a, 0.5) }, snap)
        end
    end
    local function step(which: number, amount: number)
        if range then
            if which == 1 then
                n:SetMinimumValue(n._value.Min + amount)
            else
                n:SetMaximumValue(n._value.Max + amount)
            end
        else
            n:SetValue(n._value + amount)
        end
    end
    function n:_keyboard(key: any, selected: any): boolean
        if selected ~= hit then
            return false
        end
        if range and (key == Enum.KeyCode.Up or key == Enum.KeyCode.Down) then
            self._keyboardThumb = if self._keyboardThumb == 1 then 2 else 1
            return true
        end
        local sign = if key == Enum.KeyCode.Left or key == Enum.KeyCode.DPadLeft
            then -1
            elseif key == Enum.KeyCode.Right or key == Enum.KeyCode.DPadRight then 1
            else 0
        if sign == 0 then
            return false
        end
        step(self._keyboardThumb or 1, sign * self._step)
        return true
    end
    life:Give(hit.InputBegan:Connect(function(i: InputObject)
        local which, x, width = 0, 0, 1
        local function ratio(point: Vector2): number
            return math.clamp((point.X - x) / width, 0, 1)
        end
        local function set(p: Vector2)
            local k = ratio(p)
            if range and which == 0 then
                local a, b = fraction(n._value.Min), fraction(n._value.Max)
                which = if a == b then (if k < a then 1 else 2) elseif math.abs(k - a) <= math.abs(k - b) then 1 else 2
            end
            local v = n._min + k * (n._max - n._min)
            if not range then
                n:SetValue(v)
            elseif which == 1 then
                n:SetMinimumValue(v)
            else
                n:SetMaximumValue(v)
            end
        end
        local function start(p: Vector2, from: Vector2?)
            x, width = region.AbsolutePosition.X, math.max(1, region.AbsoluteSize.X)
            n._dragging = true
            if range and from then
                local a, b, k = fraction(n._value.Min), fraction(n._value.Max), ratio(from)
                which = if a == b
                    then (if ratio(p) < a then 1 else 2)
                    elseif math.abs(k - a) <= math.abs(k - b) then 1
                    else 2
            end
            U.emit(n, "DragStarted", n:GetValue(), n)
            if not n._dead and n:_canInteract() then
                set(p)
            end
        end
        local function finish(cancel: boolean)
            n._dragging = false
            if not n._dead then
                U.emit(n, "DragEnded", n:GetValue(), n, cancel)
            end
        end
        w:_take(n, i, {
            Axis = "x",
            Scroll = U.nearestScroll(hit),
            Start = start,
            Move = set,
            End = finish,
            Tap = function(p: Vector2)
                start(p)
                finish(false)
            end,
        })
    end))
    U.value(n, c, if range then { Min = n._min, Max = n._max } else n._min)
    return U.ready(owner, n)
end

P.Choice = U.class(P.ValueRow)
P.Dropdown = U.class(P.Choice)
P.Multi = U.class(P.Dropdown)
P.InlineChoice = U.class(P.Choice)

function U.dense(v: any): boolean
    if type(v) ~= "table" then
        return false
    end
    local n = #v
    for k in v do
        if not U.finite(k) or k < 1 or k > n or k % 1 ~= 0 then
            return false
        end
    end
    for i = 1, n do
        if v[i] == nil then
            return false
        end
    end
    return true
end

function U.option(x: any): boolean
    return (type(x) == "string" and utf8.len(x) ~= nil)
        or type(x) == "boolean"
        or U.finite(x)
        or typeof(x) == "EnumItem"
        or typeof(x) == "Instance"
end
function U.choiceList(v: any): (boolean, any, any)
    if not U.dense(v) then
        return false, nil, "expected a dense array of options"
    end
    local values, set = {}, {}
    for _, x in v do
        if not U.option(x) then
            return false, nil, "unsupported option type " .. typeof(x)
        end
        if not set[x] then
            set[x] = true
            table.insert(values, x)
        end
    end
    return true, values, set
end
function U.optionText(owner: any, x: any): string
    if owner._labeler then
        local ok, s = U.call(owner, "Labeler", owner._labeler, x)
        if ok and type(s) == "string" and utf8.len(s) then
            return s
        end
    end
    if typeof(x) == "EnumItem" or typeof(x) == "Instance" then
        return x.Name
    end
    return tostring(x)
end

function P.Choice:_counts(): (number, number)
    local max = math.min(self._maximum or #self._choices, #self._choices)
    return math.min(self._minimum or 0, max), max
end

function P.Choice:_reconcile(v: any)
    if not self._multi then
        if v ~= nil and self._options[v] then
            return v
        end
        return if self._requireSelection then self._choices[1] else nil
    end
    local lo, hi = self:_counts()
    local selected = {}
    local count = 0
    for _, x in v or {} do
        if self._options[x] and count < hi and not selected[x] then
            selected[x] = true
            count += 1
        end
    end
    if count < lo then
        for _, x in self._choices do
            if not selected[x] then
                selected[x] = true
                count += 1
            end
            if count >= lo then
                break
            end
        end
    end
    local result = table.create(count)
    for _, x in self._choices do
        if selected[x] then
            table.insert(result, x)
        end
    end
    return result
end

function P.Choice:_normalize(v: any)
    if not self._multi then
        if v == nil and (not self._requireSelection or #self._choices == 0) then
            return true, nil
        end
        if not U.option(v) or not self._options[v] then
            return false, nil, "value must be in GetValues()"
        end
        return true, v
    end
    if not U.dense(v) then
        return false, nil, "expected an array of selected options"
    end
    local count, set = 0, {}
    for _, x in v do
        if not U.option(x) or not self._options[x] then
            return false, nil, "unknown selected option"
        end
        if not set[x] then
            set[x] = true
            count += 1
        end
    end
    local lo, hi = self:_counts()
    if count < lo or count > hi then
        return false, nil, ("selection count must be %d–%d"):format(lo, hi)
    end
    local result = table.create(count)
    for _, x in self._choices do
        if set[x] then
            table.insert(result, x)
        end
    end
    return true, result
end

function P.Choice:GetValues(): { Option }
    return table.clone(self._choices)
end
function P.Choice:SetValues(v: { Option }, preserve: boolean?)
    if preserve ~= nil and type(preserve) ~= "boolean" then
        return U.issue(self, "SetValues", "preserveSelection must be boolean")
    end
    local ok, values, set = U.choiceList(v)
    if not ok then
        return U.issue(self, "SetValues", set)
    end
    self._choices, self._options = values, set
    self._default = self:_reconcile(self._default)
    local nextValue
    if preserve == false then
        nextValue = self:_reconcile(nil)
    else
        nextValue = self:_reconcile(self._value)
    end
    local _, changed = self:_commit(nextValue, false, true)
    if self._dead then
        return true
    end
    if self._optionsRender then
        self:_optionsRender()
    end
    if not changed then
        self:_valueRender(true)
    end
    return true
end
function P.Choice:HasValue(v: any): boolean
    return U.option(v) and self._options[v] == true
end
function P.Choice:AddValue(v: Option)
    if not U.option(v) then
        return U.issue(self, "AddValue", "unsupported option")
    end
    if self._options[v] then
        return true
    end
    local list = self:GetValues()
    table.insert(list, v)
    return self:SetValues(list, true)
end
function P.Choice:RemoveValue(v: Option)
    if not self:HasValue(v) then
        return false, "unknown option"
    end
    local list = self:GetValues()
    U.remove(list, v)
    return self:SetValues(list, true)
end
function P.Choice:ClearValues()
    return self:SetValues({}, false)
end

function P.Multi:_sameValue(a: { Option }, b: { Option }): boolean
    if #a ~= #b then
        return false
    end
    local all = {}
    for _, value in a do
        all[value] = true
    end
    for _, value in b do
        if not all[value] then
            return false
        end
    end
    return true
end

function P.Multi:_setLimit(k: string, v: number?)
    if v ~= nil and (not U.finite(v) or v < 0 or v % 1 ~= 0) then
        return U.issue(self, "Selection limit", "expected a nonnegative integer or nil")
    end
    local lo = if k == "_minimum" then v else self._minimum
    local hi = if k == "_maximum" then v else self._maximum
    if lo and hi and lo > hi then
        return U.issue(self, "Selection limit", "minimum exceeds maximum")
    end
    self[k] = v
    self._default = self:_reconcile(self._default)
    return self:_commit(self:_reconcile(self._value), false, true)
end
function P.Multi:SetMaximum(v: number?)
    return self:_setLimit("_maximum", v)
end
function P.Multi:GetMaximum(): number?
    return self._maximum
end
function P.Multi:SetMinimum(v: number?)
    return self:_setLimit("_minimum", v)
end
function P.Multi:GetMinimum(): number
    return self._minimum or 0
end
function P.Multi:IsSelected(v: Option): boolean
    return table.find(self._value, v) ~= nil
end
function P.Multi:Select(v: Option, silent: boolean?)
    if not self:HasValue(v) then
        return U.issue(self, "Select", "unknown option")
    end
    if self:IsSelected(v) then
        return true, false
    end
    local list = self:GetValue()
    table.insert(list, v)
    return self:SetValue(list, silent)
end
function P.Multi:Deselect(v: Option, silent: boolean?)
    if not self:IsSelected(v) then
        return true, false
    end
    local list = self:GetValue()
    U.remove(list, v)
    return self:SetValue(list, silent)
end
function P.Multi:ToggleValue(v: Option, silent: boolean?)
    if self:IsSelected(v) then
        return self:Deselect(v, silent)
    end
    return self:Select(v, silent)
end
function P.Multi:SelectAll(silent: boolean?)
    local _, hi = self:_counts()
    local set, list = {}, self:GetValue()
    for _, v in list do
        set[v] = true
    end
    for _, v in self._choices do
        if #list >= hi then
            break
        end
        if not set[v] then
            table.insert(list, v)
        end
    end
    return self:SetValue(list, silent)
end
function P.Multi:ClearSelection(silent: boolean?)
    return self:SetValue(self:_reconcile({}), silent)
end

function U.choices(n: any, c: Payload, multi: boolean)
    local ok, list, set = U.choiceList(c.Values or {})
    if not ok then
        U.issue(n, "Values", set)
        list, set = {}, {}
    end
    n._multi, n._choices, n._options = multi, list, set
    n._requireSelection = c.RequireSelection == true
    n._minimum = if U.finite(c.Minimum) then math.max(0, math.floor(c.Minimum)) else 0
    n._maximum = if U.finite(c.Maximum) then math.max(n._minimum, math.floor(c.Maximum)) else nil
    n._labeler = if type(c.Labeler) == "function" then c.Labeler else nil
end

function U.field(w: any, life: any, parent: Instance, role: string, props: Payload): any
    local box = U.make("TextBox", parent, {
        Text = "",
        ClearTextOnFocus = false,
        FontFace = FACE,
        TextSize = D.Typography[role] or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Selectable = true,
    })
    for k, v in props do
        box[k] = v
    end
    U.paint(w, life, box, "TextColor3", "Text")
    U.paint(w, life, box, "PlaceholderColor3", "TextMuted")
    return box
end

function P.Dropdown:SetSearchable(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetSearchable", "expected boolean")
    end
    if self._searchable == v then
        return true
    end
    self._searchable = v
    if self:IsOpen() then
        self:_buildOptions(self._popup)
    end
    return true
end
function P.Dropdown:IsSearchable(): boolean
    return self._searchable
end
function P.Dropdown:SetPlaceholder(v: string?)
    if v ~= nil and (type(v) ~= "string" or utf8.len(v) == nil) then
        return U.issue(self, "SetPlaceholder", "expected text or nil")
    end
    self._placeholder = v or ""
    self:_valueRender(true)
    return true
end
function P.Dropdown:GetPlaceholder(): string
    return self._placeholder
end
function P.Dropdown:SetMaxVisibleItems(v: number)
    if not U.finite(v) or v < 1 or v > 25 then
        return U.issue(self, "SetMaxVisibleItems", "expected 1–25")
    end
    self._maxVisible = math.floor(v)
    if self:IsOpen() then
        self:_buildOptions(self._popup)
    end
    return true
end
function P.Dropdown:GetMaxVisibleItems(): number
    return self._maxVisible
end
function P.Dropdown:OnOpened(fn: any): Connection
    return U.event(self, "Opened"):Connect(fn)
end
function P.Dropdown:OnClosed(fn: any): Connection
    return U.event(self, "Closed"):Connect(fn)
end
function P.Dropdown:IsOpen(): boolean
    return self._popup ~= nil and self._popup.kind == "dropdown"
end
function P.Dropdown:Close()
    if self:IsOpen() then
        self._w:_closeFrom(self._popup)
    end
    return true
end
function P.Dropdown:Toggle(): boolean
    if self:IsOpen() then
        self:Close()
        return false
    end
    return self:Open()
end
function P.Dropdown:Open(): boolean
    if self:IsOpen() then
        return true
    end
    if self._popup then
        self._w:_closeFrom(self._popup, true)
    end
    local width = math.max(self._dropdownWidth, self._select.AbsoluteSize.X / self._w._scale)
    local p = U.popup(self, self._select, V(math.min(width, 329), 150), { Adaptive = true })
    if not p then
        return false
    end
    p.kind = "dropdown"
    self:_popupRender(true)
    self:_buildOptions(p)
    U.emit(self, "Opened", self)
    return true
end

function P.Dropdown:_buildOptions(p: any)
    if not p or p.dead then
        return
    end
    p.life:Remove("list")
    local life, w = U.scope(), self._w
    p.life:Give(life, "list")
    local content = U.frame(p.content, { Size = S(1, 1), Name = "Options" })
    life:Give(content)
    p.hit = w._layout.Hit
    local rowH = math.max(D.Option, p.hit)
    local searchH = if self._searchable then math.max(D.Search, w._layout.Hit) + 7 else 0
    local q
    if self._searchable then
        q = U.field(w, life, content, "Popup", {
            Name = "Search",
            PlaceholderText = "Filter…",
            Text = p.query or "",
            Position = O(6, 4),
            Size = UDim2.new(1, -12, 0, searchH - 7),
        })
        U.fill(w, life, q, "SurfaceRaised")
        U.corner(q, D.FieldRadius)
        U.padding(q, 7, 0)
        U.focusable(self, life, q, function()
            q:CaptureFocus()
        end)
    end
    local scroll = U.scroll(content, false, {
        Position = O(5, searchH + 4),
        Size = UDim2.new(1, -10, 1, -(searchH + 8)),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        Name = "OptionList",
    })
    local no = U.text(w, life, scroll, "Popup", "No options", "TextMuted", {
        Position = O(7, 0),
        Size = UDim2.new(1, -14, 0, rowH),
        Visible = false,
    })
    local filtered, pool = {}, {}
    local function update()
        if p.dead or life._dead then
            return
        end
        local first = math.floor(scroll.CanvasPosition.Y / (rowH * w._scale)) + 1
        for j, slot in pool do
            local idx = first + j - 1
            local item = filtered[idx]
            slot.value = if item then item.value else nil
            slot.index = if item then idx else nil
            if item then
                slot.label.Text = item.text
                slot.button.Position = O(0, (idx - 1) * rowH)
                local selected = if self._multi then self:IsSelected(item.value) else self._value == item.value
                slot.line.Visible = selected
                slot.selected = selected
                slot.repaint()
            end
            slot.button.Visible = item ~= nil
        end
    end
    for _ = 1, self._maxVisible + 2 do
        local slot: Payload = { state = "idle", selected = false }
        local function choose()
            if p.dead or slot.value == nil then
                return
            end
            local item = slot.value
            if self._multi then
                self:ToggleValue(item)
            else
                self:SetValue(item)
                if self._popup == p then
                    self:Close()
                end
            end
        end
        local btn = U.button(
            self,
            life,
            scroll,
            {
                Size = UDim2.new(1, -4, 0, rowH),
                Name = "Option",
                Visible = false,
            },
            choose,
            function(state: string)
                slot.state = state
                if slot.repaint then
                    slot.repaint()
                end
            end
        )
        U.focusable(self, life, btn, choose)
        local bg = U.paint(w, life, btn, "BackgroundColor3", function(t: Payload)
            if slot.state == "press" then
                return t.Pressed
            end
            if slot.state ~= "idle" then
                return t.Hover
            end
            return if slot.selected then t.SidebarSelected else t.Surface
        end)
        local label = U.text(w, life, btn, "Popup", "", function(t: Payload)
            return if slot.selected then t.Text else t.TextSecondary
        end, { Position = O(8, 0), Size = UDim2.new(1, -25, 1, 0) })
        local fg = U.paint(w, life, label, "TextColor3", function(t: Payload)
            return if slot.selected or slot.state ~= "idle" then t.Text else t.TextSecondary
        end)
        slot.line = U.line(w, life, btn, "Accent", {
            AnchorPoint = V(1, 0.5),
            Position = UDim2.new(1, -4, 0.5, 0),
            Size = O(2, 12),
            Visible = false,
        })
        slot.button, slot.label = btn, label
        slot.repaint = function()
            bg()
            fg()
            btn.BackgroundTransparency = if slot.selected or slot.state ~= "idle" then 0 else 1
        end
        table.insert(pool, slot)
    end
    local function filter()
        if p.dead then
            return
        end
        table.clear(filtered)
        p.query = if q then q.Text else ""
        local pattern = string.lower(p.query)
        for _, val in self._choices do
            local text = U.optionText(self, val)
            if pattern == "" or string.find(string.lower(text), pattern, 1, true) then
                table.insert(filtered, { value = val, text = text })
            end
        end
        no.Text = if #self._choices == 0 then "No options" else "No matches"
        no.Visible = #filtered == 0
        scroll.CanvasPosition = Vector2.zero
        scroll.CanvasSize = O(0, math.max(1, #filtered) * rowH)
        p.height = math.max(1, math.min(#filtered, self._maxVisible)) * rowH + searchH + 8
        w:_placePopup(p)
        update()
    end
    p.update, p.filter = update, filter
    p.navigate = function(direction: number)
        if #filtered == 0 then
            return false
        end
        local selectedIndex, selected = nil, Gui.SelectedObject
        for _, record in pool do
            if record.button == selected then
                selectedIndex = record.index
                break
            end
        end
        local target = if selectedIndex
            then math.clamp(selectedIndex + direction, 1, #filtered)
            else (if direction < 0 then #filtered else 1)
        local py = (target - 1) * rowH * w._scale
        local size = scroll.AbsoluteWindowSize.Y
        if py < scroll.CanvasPosition.Y then
            scroll.CanvasPosition = V(0, py)
        elseif py + rowH * w._scale > scroll.CanvasPosition.Y + size and size > 0 then
            scroll.CanvasPosition = V(0, py + rowH * w._scale - size)
        end
        update()
        for _, record in pool do
            if record.index == target then
                Gui.SelectedObject = record.button
                break
            end
        end
        return true
    end
    local rail = U.scrollbar(w, self, life, scroll, content, {
        Position = UDim2.new(1, -7, 0, searchH + 4),
        Size = UDim2.new(0, 6, 1, -(searchH + 8)),
    })
    life:Give(rail)
    life:Give(scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(update))
    if q then
        life:Give(q:GetPropertyChangedSignal("Text"):Connect(function()
            U.later(self, life, "filter", nil, filter)
        end))
    end
    filter()
end

function Build.Dropdown(owner: any, c: Payload, multi: boolean)
    local n = U.row(owner, if multi then "MultiDropdown" else "Dropdown", c, "normal")
    setmetatable(n, if multi then P.Multi else P.Dropdown)
    local w, life = n._w, n._life
    U.choices(n, c, multi)
    n._maxVisible = math.clamp(math.floor(U.number(c.MaxVisibleItems, 6)), 1, 25)
    n._searchable, n._placeholder = c.Searchable == true, U.str(c.Placeholder, "Select")
    n._dropdownWidth = math.clamp(U.number(c.PopupWidth, 175), 115, 329)
    n._reserve = 120
    local btn = U.rowButton(n, n._heading, {
        AnchorPoint = V(1, 0),
        Position = S(1, 0),
        Size = S(if c.HideLabel then 1 else 0.55, 1),
        Name = "Selection",
    }, function()
        n:Toggle()
    end)
    n._select = btn
    n._title.Visible = c.HideLabel ~= true
    local fg, refresh = U.text(w, life, btn, "Numeric", "", function(t: Payload)
        if n:_isDisabled() then
            return t.TextDisabled
        end
        return if n._popup then t.Accent elseif n._empty then t.TextSecondary else t.Text
    end, { Size = UDim2.new(1, -30, 1, 0), TextXAlignment = Enum.TextXAlignment.Right })
    local arrow = U.icon(w, life, btn, "down", 10, function(t: Payload)
        if n:_isDisabled() then
            return t.TextDisabled
        end
        return if n._popup then t.Accent else t.Text
    end, {
        AnchorPoint = V(1, 0.5),
        Position = UDim2.new(1, 3, 0.5, 0),
        Size = O(16, 14),
    })
    function n:_keyboard(key: any, selected: GuiObject): boolean
        local up = key == Enum.KeyCode.Up or key == Enum.KeyCode.DPadUp
        local down = key == Enum.KeyCode.Down or key == Enum.KeyCode.DPadDown
        if not up and not down then
            return false
        end
        if selected == btn and not self:IsOpen() then
            self:Open()
        end
        local popup = self._popup
        return popup ~= nil and popup.kind == "dropdown" and popup.navigate and popup.navigate(if up then -1 else 1)
            or false
    end
    function n:_reserveWidth(width: number): number
        if c.HideLabel then
            return width
        end
        local limit = math.max(46, width * 0.51)
        local want = math.max(48, U.measure(fg.Text, D.Typography.Numeric) + 36)
        local actual = math.min(want, limit)
        btn.Size = UDim2.new(0, actual, 1, 0)
        return actual + 4
    end
    function n:_popupRender(show: boolean)
        if self._dead then
            return
        end
        U.tween(w, life, arrow, "caret", "state", { Rotation = if show then 180 else 0 })
        refresh()
    end
    function n:_valueRender()
        local v = self._value
        self._empty = if multi then #v == 0 else v == nil
        if self._empty then
            fg.Text = self._placeholder
        elseif multi then
            local labels = {}
            for i, x in v do
                if i > 8 then
                    table.insert(labels, "+" .. tostring(#v - 8))
                    break
                end
                table.insert(labels, U.optionText(self, x))
            end
            fg.Text = table.concat(labels, ", ")
        else
            fg.Text = U.optionText(self, v)
        end
        self:_headingLayout()
        refresh()
        local p = self._popup
        if p and p.kind == "dropdown" and p.update then
            p.update()
        end
    end
    function n:_optionsRender()
        local p = self._popup
        if p and p.kind == "dropdown" and p.filter then
            p.filter()
        end
    end
    U.value(n, c, n:_reconcile(nil))
    return U.ready(owner, n)
end

function Build.InlineChoice(owner: any, c: Payload, radio: boolean)
    local n = U.row(owner, if radio then "RadioGroup" else "SegmentedControl", c, "normal")
    setmetatable(n, P.InlineChoice)
    local w, life = n._w, n._life
    U.choices(n, c, false)
    local showLabel = c.HideLabel ~= true
    n._title.Visible = showLabel
    n._reserveRatio = if radio or not showLabel then nil else 0.62
    local host = U.scroll(n._root, not radio, {
        Name = "ChoiceOptions",
        Active = not radio,
        ScrollingEnabled = not radio,
        AutomaticCanvasSize = Enum.AutomaticSize.None,
    })
    local function geometry()
        local g = w._layout
        local h = math.max(if n._small then 31 else 35, g.Hit)
        n._heightBase = if radio
            then math.max(1, #n._choices) * h + (if showLabel then 29 else 0)
            else math.max(h + 7, if n._small then 37 else D.Row)
        if radio then
            host.Position = O(0, if showLabel then 29 else 0)
            host.Size = UDim2.new(1, 0, 0, n._heightBase - (if showLabel then 29 else 0))
            n._heading.Size = UDim2.new(1, 0, 0, 29)
        else
            host.AnchorPoint = V(1, 0)
            host.Position = UDim2.new(1, 0, 0, math.max(0, (n._baseHeight - h) / 2))
            host.Size = UDim2.new(if showLabel then 0.62 else 1, 0, 0, h)
        end
        return h
    end
    n._layoutRender = geometry
    n._valueRender = function()
        for _, entry in n._choiceUI or {} do
            entry.refresh()
        end
    end
    n._optionsRender = function()
        life:Remove("items")
        local localLife = U.scope()
        life:Give(localLife, "items")
        local listParent = U.frame(host, { Size = S(1, 1) })
        localLife:Give(listParent)
        local h = math.max(if n._small then 31 else 35, w._layout.Hit)
        local ui, x = {}, 0
        for i, value in n._choices do
            local label = U.optionText(n, value)
            local width = if radio
                then 0
                else math.clamp(U.measure(label, D.Typography.Popup) + 17, math.max(48, w._layout.Hit), 174)
            local hover = "idle"
            local function choose()
                n:SetValue(value)
            end
            local b = U.button(
                n,
                localLife,
                listParent,
                {
                    Position = if radio then O(0, (i - 1) * h) else O(x, 0),
                    Size = UDim2.new(if radio then 1 else 0, width, 0, h),
                    Name = "Choice",
                },
                choose,
                function(state: string)
                    hover = state
                    if ui[i] then
                        ui[i].refresh()
                    end
                end
            )
            U.focusable(n, localLife, b, choose)
            if not radio then
                U.corner(b, D.FieldRadius)
            end
            local text, fg = U.text(w, localLife, b, "Popup", label, function(t: Payload)
                if n:_isDisabled() then
                    return t.TextDisabled
                end
                if n._value == value and not radio then
                    return t.AccentInk
                end
                return if n._value == value or hover ~= "idle" then t.Text else t.TextSecondary
            end, {
                Position = O(if radio then 25 else 4, 0),
                Size = UDim2.new(1, if radio then -30 else -8, 1, 0),
                TextXAlignment = if radio then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center,
            })
            local icon
            if radio then
                icon = U.icon(w, localLife, b, "check", 12, "Accent", {
                    AnchorPoint = V(0, 0.5),
                    Position = UDim2.new(0, 1, 0.5, 0),
                    Size = O(16, 16),
                })
            end
            local bg = U.paint(w, localLife, b, "BackgroundColor3", function(t: Payload)
                if n._value == value and not radio then
                    return if n:_isDisabled() then t.AccentMuted else t.Accent
                end
                return if hover == "press" then t.Pressed elseif hover ~= "idle" then t.Hover else t.SurfaceRaised
            end)
            ui[i] = {
                refresh = function()
                    fg()
                    bg()
                    b.Interactable = not n:_isDisabled()
                    b.Selectable = b.Interactable
                    b.BackgroundTransparency = if radio and hover == "idle" then 1 else 0
                    if icon then
                        icon.Visible = n._value == value
                    end
                end,
            }
            x += width + 4
        end
        n._choiceUI = ui
        host.CanvasSize = O(x, 0)
        n._heightBase = if radio
            then math.max(1, #n._choices) * h + (if showLabel then 29 else 0)
            else math.max(h + 7, if n._small then 37 else D.Row)
        n:_measure()
        n:_valueRender()
    end
    local lastHit = w._layout.Hit
    n._resizeContent = function()
        if lastHit ~= w._layout.Hit then
            lastHit = w._layout.Hit
            n:_optionsRender()
        end
    end
    n._life:Give(n._root:GetPropertyChangedSignal("AbsoluteSize"):Connect(n._resizeContent))
    U.value(n, c, n:_reconcile(nil))
    n:_optionsRender()
    return U.ready(owner, n)
end

P.Action = U.class(P.Row)
P.Label = U.class(P.Row)
P.Paragraph = U.class(P.Label)
P.Status = U.class(P.Label)
P.TextInput = U.class(P.ValueRow)
P.NumberInput = U.class(P.Numeric)
P.Color = U.class(P.ValueRow)
P.Progress = U.class(P.Numeric)
P.Custom = U.class(P.Row)
P.Context = U.class(P.Row)

local styles = { Neutral = true, Accent = true, Ghost = true, Danger = true, Tint = true }

function P.Action:SetText(v: string)
    return self:SetName(v)
end
function P.Action:GetText(): string
    return self:GetName()
end
function P.Action:SetStyle(v: string)
    if type(v) ~= "string" or not styles[v] then
        return U.issue(self, "SetStyle", "expected Neutral, Accent, Ghost, Danger or Tint")
    end
    self._style = v
    self:_stateRender()
    return true
end
function P.Action:GetStyle(): string
    return self._style
end
function P.Action:SetIcon(v: any)
    self._icon = U.copy(v)
    self._drawIcon(v)
    self:_stateRender()
    return true
end
function P.Action:GetIcon(): any
    return U.copy(self._icon)
end
function P.Action:SetLoading(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetLoading", "expected boolean")
    end
    self._loading = v
    self:_measure()
    self:_stateRender()
    return true
end
function P.Action:IsLoading(): boolean
    return self._loading
end
function P.Action:SetCallback(fn: any)
    if fn ~= nil and type(fn) ~= "function" then
        return U.issue(self, "SetCallback", "expected callable or nil")
    end
    self._callback = fn
    return true
end
function P.Action:Fire(...: any)
    if self:_isDisabled() or self._loading then
        return false, "button unavailable"
    end
    local ok, out = U.call(self, "Callback", self._callback, self, ...)
    U.emit(self, "Clicked", self, ...)
    return ok, out
end
function P.Action:Click(...: any)
    if not self:_canInteract() then
        return false, "button is not interactive"
    end
    return self:Fire(...)
end
function P.Action:OnClicked(fn: any): Connection
    return U.event(self, "Clicked"):Connect(fn)
end

function Build.Button(owner: any, c: Payload, iconOnly: boolean)
    if c.Name == nil and type(c.Text) == "string" then
        c = table.clone(c)
        c.Name = c.Text
    end
    local n = U.row(owner, if iconOnly then "IconButton" else "Button", c, "normal")
    setmetatable(n, P.Action)
    local w, life = n._w, n._life
    n._style = if type(c.Style) == "string" and styles[c.Style] then c.Style else "Neutral"
    n._callback, n._loading, n._icon = c.Callback, c.Loading == true, U.copy(c.Icon)
    if iconOnly and n._icon == nil then
        n._icon = "more"
    end
    if iconOnly and n._tooltip == "" then
        n:SetTooltip(n._name)
    end
    n._title.Visible = false
    local state = "idle"
    local button = U.rowButton(
        n,
        n._heading,
        { AnchorPoint = V(0.5, 0.5), Position = S(0.5, 0.5), Name = "Action" },
        function(input: any)
            n:Click(input)
        end,
        function(nextState: string)
            state = nextState
            if n._paintAction then
                n:_paintAction()
            end
        end
    )
    U.corner(button, D.FieldRadius)
    n._interactive[button] = function()
        return not n._loading
    end
    local shade = U.paint(w, life, button, "BackgroundColor3", function(t: Payload)
        if n:_isDisabled() or n._loading then
            return t.Surface
        end
        if n._style == "Accent" then
            return if state == "press" then t.Accent:Lerp(t.Background, 0.14) else t.Accent
        end
        if n._style == "Danger" then
            return if state == "idle" then t.SurfaceRaised else t.Danger
        end
        if n._style == "Tint" then
            return if state == "idle"
                then t.Surface
                elseif state == "press" then t.Accent:Lerp(t.Background, 0.21)
                else t.Accent
        end
        return if state == "press" then t.AccentMuted elseif state ~= "idle" then t.Hover else t.Row
    end)
    local function ink(t: Payload)
        if n:_isDisabled() then
            return t.TextDisabled
        end
        if n._style == "Accent" and not n._loading then
            return t.AccentInk
        end
        if n._style == "Danger" then
            return if state == "idle" then t.Danger else t.Background
        end
        if n._style == "Tint" then
            return if state == "idle" then t.NavMuted else t.AccentInk
        end
        return if n._loading then t.TextSecondary else t.Text
    end
    local text, fore = U.text(w, life, button, "Control", "", ink, { TextXAlignment = Enum.TextXAlignment.Center })
    local host, change = U.icon(w, life, button, n._icon, 15, ink, {
        AnchorPoint = V(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = O(21, 21),
    })
    n._drawIcon = change
    function n:_paintAction()
        shade()
        fore()
        button.BackgroundTransparency = if self._style == "Ghost" and state == "idle" then 1 else 0
    end
    function n:_stateEffect()
        text.Text = if self._loading then "Working…" else self._name
        text.Visible = not iconOnly or self._loading
        host.Visible = self._icon ~= nil and not self._loading
        local inset = if host.Visible and not iconOnly then 29 else 5
        text.Position = O(inset, 0)
        text.Size = UDim2.new(1, -(inset + 5), 1, 0)
        if iconOnly then
            host.AnchorPoint = V(0.5, 0.5)
            host.Position = S(0.5, 0.5)
        end
        self:_paintAction()
    end
    function n:_layoutRender()
        local h = math.max(if self._small then 27 else 45, w._layout.Hit)
        button.Size = UDim2.new(
            if iconOnly and not self._loading then 0 else 1,
            if iconOnly and not self._loading then h else 0,
            0,
            math.min(self._baseHeight, h)
        )
    end
    local meta = n._metaRender
    n._metaRender = function(self: any)
        meta(self)
        self:_stateEffect()
    end
    return U.ready(owner, n)
end

function P.Label:SetText(s: string)
    if type(s) ~= "string" or utf8.len(s) == nil then
        return U.issue(self, "SetText", "expected UTF-8 text")
    end
    self._text = s
    self:_metaRender()
    return true
end
function P.Label:GetText(): string
    return self._text
end
function P.Label:SetColor(c: Color3?)
    if c ~= nil and not U.color(c) then
        return U.issue(self, "SetColor", "expected Color3 or nil")
    end
    self._textColor = c
    self:_stateRender()
    return true
end
function P.Label:GetColor(): Color3
    return self._textColor or self._w._theme._colors.Text
end
function P.Label:SetAlignment(v: any)
    if type(v) == "string" then
        local ok, x = pcall(function()
            return (Enum.TextXAlignment :: any)[v]
        end)
        if ok then
            v = x
        end
    end
    if typeof(v) ~= "EnumItem" or v.EnumType ~= Enum.TextXAlignment then
        return U.issue(self, "SetAlignment", "expected TextXAlignment")
    end
    self._textWidget.TextXAlignment = v
    return true
end
function P.Label:SetRichText(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetRichText", "expected boolean")
    end
    self._textWidget.RichText = v
    return true
end
function P.Paragraph:SetTitle(v: string)
    return self:SetName(v)
end
function P.Paragraph:GetTitle(): string
    return self:GetName()
end
function P.Status:SetSeverity(v: string)
    if
        type(v) ~= "string" or not ({ Default = true, Info = true, Success = true, Warning = true, Error = true })[v]
    then
        return U.issue(self, "SetSeverity", "expected Default, Info, Success, Warning or Error")
    end
    self._severity = v
    self:_stateRender()
    return true
end
function P.Status:GetSeverity(): string
    return self._severity
end

function U.severity(v: string): string
    if v == "Error" then
        return "Danger"
    end
    if v == "Info" or v == "Warning" or v == "Success" then
        return v
    end
    return "Accent"
end

function Build.Label(owner: any, c: Payload, kind: string)
    local n = U.row(owner, kind, c, "custom")
    setmetatable(n, if kind == "Paragraph" then P.Paragraph elseif kind == "Status" then P.Status else P.Label)
    local w, life = n._w, n._life
    n._text, n._textColor = U.str(c.Text, n._name), if U.color(c.Color) then c.Color else nil
    n._textToken = if type(c.ColorToken) == "string" then c.ColorToken else nil
    n._hideDescription = kind == "Paragraph"
    n._severity = U.str(c.Severity, "Default")
    n._heightBase = U.number(c.Height, if kind == "SectionLabel" then 33 else 35)
    n._divider.Visible = c.Separator == true or (c.Separator ~= false and kind == "SectionLabel")
    n._title.Visible = kind == "Paragraph"
    local label, refresh = U.text(
        w,
        life,
        n._root,
        if kind == "SectionLabel" then "Section" else "Control",
        n._text,
        function(t: Payload)
            return if n:_isDisabled()
                then t.TextDisabled
                elseif n._textColor then n._textColor
                elseif n._textToken and t[n._textToken] then t[n._textToken]
                elseif kind == "Paragraph" then t.TextSecondary
                elseif kind == "Status" then t[U.severity(n._severity)]
                elseif kind == "SectionLabel" then t.TextSecondary
                else t.Text
        end,
        {
            TextWrapped = kind == "Paragraph",
            TextTruncate = if kind == "Paragraph" then Enum.TextTruncate.None else Enum.TextTruncate.AtEnd,
            RichText = c.RichText == true,
            TextYAlignment = if kind == "Paragraph" then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center,
        }
    )
    n._textWidget = label
    if c.Alignment then
        n:SetAlignment(c.Alignment)
    end
    local meta = n._metaRender
    function n:_metaRender()
        label.Text = if n._text ~= "" then n._text elseif self._description ~= "" then self._description else ""
        meta(self)
    end
    n._stateEffect = refresh
    if kind == "Paragraph" then
        local captionH = 19
        function n:_layoutRender()
            self._heading.Size = UDim2.new(1, 0, 0, captionH)
            label.Position = O(0, captionH + 3)
            label.Size = UDim2.new(1, -3, 1, -(captionH + 10))
        end
        local oldMeasure = n._measure
        function n:_measure()
            local width = n._root.AbsoluteSize.X / w._scale
            if width < 12 then
                width = math.max(90, w._layout.Width - w._layout.Left - w._layout.Right - w._layout.Sidebar)
            end
            local count = 0
            for line in string.gmatch(label.Text .. "\n", "(.-)\n") do
                count += math.max(1, math.ceil(U.measure(line, D.Typography.Control) / math.max(1, width - 16)))
            end
            self._heightBase = math.max(42, captionH + 10 + math.min(count, 280) * 18)
            oldMeasure(self)
        end
        life:Give(n._root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if not n._dead then
                n:_measure()
            end
        end))
    else
        label.Size = UDim2.new(1, -2, 0, n._heightBase)
    end
    n:_metaRender()
    return U.ready(owner, n)
end

function P.TextInput:_normalize(v: any)
    if type(v) ~= "string" or utf8.len(v) == nil then
        return false, nil, "expected UTF-8 text"
    end
    local s = if self._maxLength then U.cut(v, self._maxLength) else v
    if self._validator then
        local ok, valid, reason = pcall(self._validator, s, self)
        if not ok then
            return false, nil, "validation error: " .. tostring(valid)
        end
        if valid ~= true then
            return false, nil, U.str(reason, "validation rejected the text")
        end
    end
    return true, s
end
function P.TextInput:SetPlaceholder(v: string?)
    if v ~= nil and (type(v) ~= "string" or utf8.len(v) == nil) then
        return U.issue(self, "SetPlaceholder", "expected text or nil")
    end
    self._box.PlaceholderText = v or ""
    return true
end
function P.TextInput:GetPlaceholder(): string
    return self._box.PlaceholderText
end
function P.TextInput:SetMaxLength(v: number?)
    if v ~= nil and (not U.finite(v) or v < 0 or v % 1 ~= 0) then
        return U.issue(self, "SetMaxLength", "expected nonnegative integer or nil")
    end
    local old = self._maxLength
    self._maxLength = v
    local ok, val, why = self:_normalize(self._value)
    local okDefault, def = self:_normalize(self._default)
    if not ok or not okDefault then
        self._maxLength = old
        return U.issue(self, "SetMaxLength", why or "truncated default is invalid")
    end
    self._default = def
    return self:_commit(val, false, true)
end
function P.TextInput:SetValidation(v: any)
    if v ~= nil and type(v) ~= "function" then
        return U.issue(self, "SetValidation", "expected a function or nil")
    end
    local previous = self._validator
    self._validator = v
    local ok, _, why = self:_normalize(self._value)
    local defaultOK = self:_normalize(self._default)
    if not ok or not defaultOK then
        self._validator = previous
        return U.issue(self, "SetValidation", why or "validator rejected the stored default")
    end
    return true
end
function P.TextInput:Focus(): boolean
    if not self:_canInteract() or self._readOnly then
        return false
    end
    self._box:CaptureFocus()
    return true
end
function P.TextInput:ReleaseFocus(enter: boolean?)
    self._box:ReleaseFocus(enter == true)
    return true
end
function P.TextInput:Clear(silent: boolean?)
    return self:SetValue("", silent)
end
function P.TextInput:SetReadOnly(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetReadOnly", "expected boolean")
    end
    if v and self._box:IsFocused() then
        self._box:ReleaseFocus(false)
    end
    self._readOnly = v
    self:_stateRender()
    return true
end
function P.TextInput:IsReadOnly(): boolean
    return self._readOnly
end
function P.TextInput:OnSubmitted(fn: any): Connection
    return U.event(self, "Submitted"):Connect(fn)
end
function P.TextInput:OnFocused(fn: any): Connection
    return U.event(self, "Focused"):Connect(fn)
end
function P.TextInput:OnFocusLost(fn: any): Connection
    return U.event(self, "FocusLost"):Connect(fn)
end

for _, name in
    {
        "SetPlaceholder",
        "GetPlaceholder",
        "Focus",
        "ReleaseFocus",
        "SetReadOnly",
        "IsReadOnly",
        "OnSubmitted",
        "OnFocused",
        "OnFocusLost",
    }
do
    P.NumberInput[name] = P.TextInput[name]
end
function P.NumberInput:Increment(silent: boolean?)
    return self:SetValue(self._value + self._step, silent)
end
function P.NumberInput:Decrement(silent: boolean?)
    return self:SetValue(self._value - self._step, silent)
end

function Build.Input(owner: any, c: Payload, numeric: boolean)
    local n = U.row(owner, if numeric then "NumberInput" else "TextInput", c, "normal")
    setmetatable(n, if numeric then P.NumberInput else P.TextInput)
    local w, life = n._w, n._life
    if numeric then
        U.numeric(n, c, -1e9, 1e9, 1)
    end
    n._readOnly, n._validator = c.ReadOnly == true, if type(c.Validation) == "function" then c.Validation else nil
    n._maxLength = if U.finite(c.MaxLength) then math.max(0, math.floor(c.MaxLength)) else nil
    n._reserveRatio, n._reserve = if numeric then 0.46 else 0.52, 115
    local box = U.field(w, life, n._heading, if numeric then "Numeric" else "Control", {
        Name = "ValueEditor",
        PlaceholderText = U.str(c.Placeholder),
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = V(1, 0.5),
        Position = S(1, 0.5),
        Size = UDim2.new(0.49, 0, 0, 29),
    })
    U.corner(box, D.FieldRadius)
    U.padding(box, 8, 0)
    n._box = box
    n._interactive[box] = function()
        return not n._readOnly
    end
    U.focusable(n, life, box, function()
        n:Focus()
    end)
    local focus, editing, invalid = false, false, false
    local heightBase = n._heightBase
    local tint = U.paint(w, life, box, "BackgroundColor3", function(t: Payload)
        if n:_isDisabled() or n._readOnly then
            return t.Row
        end
        return if invalid then t.Pressed elseif focus then t.SurfaceRaised else t.Surface
    end)
    local border = U.line(w, life, n._heading, function(t: Payload)
        return if invalid then t.Danger else t.Accent
    end, {
        Name = "Focus",
        AnchorPoint = V(1, 0),
        Position = S(1, 0.5),
        Size = UDim2.new(0.49, 0, 0, 1),
    })
    local stepWidth = if numeric then 52 else 0
    local down, up
    if numeric then
        down = U.rowButton(n, n._heading, { AnchorPoint = V(1, 0.5), Name = "Decrement" }, function()
            n:Decrement()
        end)
        up = U.rowButton(
            n,
            n._heading,
            { AnchorPoint = V(1, 0.5), Position = S(1, 0.5), Name = "Increment" },
            function()
                n:Increment()
            end
        )
        U.icon(w, life, down, "minus", 12, "TextSecondary", { Size = S(1, 1) })
        U.icon(w, life, up, "plus", 12, "TextSecondary", { Size = S(1, 1) })
        U.fill(w, life, down, "Surface")
        U.fill(w, life, up, "Surface")
        n._interactive[down], n._interactive[up] =
            function()
                return not n._readOnly
            end, function()
                return not n._readOnly
            end
    end
    function n:_layoutRender()
        local size = math.max(32, w._layout.Hit)
        local step = if numeric then math.max(26, w._layout.Hit) else 0
        stepWidth = step * 2
        local narrow = self._narrow == true
        local ratio = if narrow then 1 elseif numeric then 0.62 else 0.51
        local baseY, yOffset = if narrow then 0 else 0.5, if narrow then self._baseHeight - size / 2 - 4 else 0
        self._reserveRatio = if narrow then nil else ratio + 0.03
        self._reserve = if narrow then 0 else 115
        self:_headingLayout()
        if narrow then
            self._title.Size = UDim2.new(1, -10, 0, 29)
        end
        box.Position = UDim2.new(1, -stepWidth, baseY, yOffset)
        box.Size = UDim2.new(ratio, -stepWidth, 0, size)
        border.Position = UDim2.new(1, -stepWidth, baseY, yOffset + size / 2 - 1)
        border.Size = UDim2.new(ratio, -stepWidth, 0, 1)
        border.Visible = focus
        if up and down then
            up.Position = UDim2.new(1, 0, baseY, yOffset)
            up.Size = O(step, size)
            down.Position = UDim2.new(1, -step, baseY, yOffset)
            down.Size = O(step, size)
        end
    end
    local originalMeasure = n._measure
    function n:_measure()
        local width = self._root.AbsoluteSize.X / w._scale
        local minimum = if numeric then math.max(260, (2 * math.max(26, w._layout.Hit) + 65) / 0.62) else 258
        self._narrow = width > 0 and width < minimum
        self._heightBase = if self._narrow then math.max(heightBase, math.max(32, w._layout.Hit) + 37) else heightBase
        originalMeasure(self)
    end
    n._resizeContent = function()
        n:_measure()
    end
    n:_watchSize()
    function n:_stateEffect()
        box.TextEditable = not self:_isDisabled() and not self._readOnly
        tint()
    end
    function n:_valueRender()
        if editing then
            return
        end
        editing = true
        if numeric then
            box.Text = if focus
                then tostring(self._value)
                else self._prefix .. U.numText(self, self._value) .. self._suffix
        else
            box.Text = self._value or ""
        end
        editing = false
    end
    local function proposed(): (boolean, any)
        local val = if numeric then tonumber(box.Text) else box.Text
        return n:_normalize(val)
    end
    life:Give(box.Focused:Connect(function()
        if not n:_canInteract() or n._readOnly then
            box:ReleaseFocus(false)
            return
        end
        w:_release(true)
        w:_stopHold()
        focus, invalid = true, false
        n:_valueRender()
        n:_layoutRender()
        tint()
        U.emit(n, "Focused", n:GetValue(), n)
    end))
    life:Give(box:GetPropertyChangedSignal("Text"):Connect(function()
        if editing or not focus or n._dead then
            return
        end
        if not numeric and n._maxLength and utf8.len(box.Text) ~= nil then
            local short = U.cut(box.Text, n._maxLength)
            if short ~= box.Text then
                editing = true
                box.Text = short
                editing = false
            end
        end
        local ok, val = proposed()
        invalid = not ok
        if ok and not numeric and c.Live ~= false then
            editing = true
            n:_commit(val, false, true)
            editing = false
        end
        tint()
    end))
    life:Give(box.ReturnPressedFromOnScreenKeyboard:Connect(function()
        if box:IsFocused() then
            box:ReleaseFocus(true)
        end
    end))
    life:Give(box.FocusLost:Connect(function(enterPressed: boolean)
        if n._dead then
            return
        end
        local ok, val = proposed()
        focus, invalid = false, false
        if ok and not n:_isDisabled() and not n._readOnly then
            n:_commit(val, false, true)
        end
        if n._dead then
            return
        end
        n:_valueRender()
        n:_layoutRender()
        tint()
        if enterPressed and ok then
            U.emit(n, "Submitted", n:GetValue(), n)
        end
        U.emit(n, "FocusLost", n:GetValue(), enterPressed, ok, n)
    end))
    if not numeric and n._validator and not n:_normalize(c.Default or "") and not n:_normalize("") then
        U.issue(
            n,
            "Validation",
            "the default and empty fallback were rejected; install a compatible validator after initialization"
        )
        n._validator = nil
    end
    U.value(n, c, if numeric then U.quantize(n, 0) else "")
    return U.ready(owner, n)
end

function P.Color:_normalize(v: any)
    if not U.color(v) then
        return false, nil, "expected Color3 with channels in [0,1]"
    end
    return true, v
end
function P.Color:GetColor(): Color3
    return self:GetValue()
end
function P.Color:SetColor(v: Color3, silent: boolean?)
    return self:SetValue(v, silent)
end
function P.Color:GetAlpha(): number
    return self._alpha
end
function P.Color:SetAlpha(alpha: number, silent: boolean?)
    if not U.finite(alpha) or alpha < 0 or alpha > 1 then
        return U.issue(self, "SetAlpha", "expected opacity from 0 to 1")
    end
    if silent ~= nil and type(silent) ~= "boolean" then
        return U.issue(self, "SetAlpha", "silent must be boolean")
    end
    local previous = self._alpha
    if alpha == previous then
        return true, false
    end
    self._alpha = alpha
    self:_valueRender(true)
    if self._w and self._w._profileManager and self._flag then
        self._w._profileManager:ControlChanged(self)
    end
    if not silent then
        self:_emitChange(self._value, self._value, previous)
    end
    return true, true
end
function P.Color:SetDefaultAlpha(v: number)
    if not U.finite(v) or v < 0 or v > 1 then
        return U.issue(self, "SetDefaultAlpha", "expected opacity from 0 to 1")
    end
    self._defaultAlpha = v
    return true
end
function P.Color:GetDefaultAlpha(): number
    return self._defaultAlpha
end
function P.Color:Reset(silent: boolean?)
    if silent ~= nil and type(silent) ~= "boolean" then
        return U.issue(self, "Reset", "silent must be boolean")
    end
    local old, alpha = self._value, self._alpha
    self._alpha = self._defaultAlpha
    local _, changed = self:_commit(self._default, true, true)
    if not changed and alpha ~= self._alpha then
        self:_valueRender(true)
    end
    if not silent and (changed or alpha ~= self._alpha) then
        self:_emitChange(self._value, old, alpha)
    end
    return true, changed or alpha ~= self._alpha
end
function P.Color:GetHSV(): (number, number, number)
    local h, s, v = self._value:ToHSV()
    return if s <= 1e-7 or v <= 1e-7 or (h == 0 and self._lastHue == 1) then self._lastHue else h, s, v
end
function P.Color:SetHSV(h: number, s: number, v: number, silent: boolean?)
    if not U.finite(h) or not U.finite(s) or not U.finite(v) or h < 0 or h > 1 or s < 0 or s > 1 or v < 0 or v > 1 then
        return U.issue(self, "SetHSV", "each channel must be in [0,1]")
    end
    if silent ~= nil and type(silent) ~= "boolean" then
        return U.issue(self, "SetHSV", "silent must be boolean")
    end
    self._lastHue = h
    local ok, changed = self:SetValue(Color3.fromHSV(h, s, v), silent)
    if ok and not changed then
        self:_valueRender(true)
    end
    return ok, changed
end
function P.Color:SetHex(s: string, silent: boolean?)
    if type(s) ~= "string" then
        return U.issue(self, "SetHex", "expected #RRGGBB")
    end
    local clean = string.match(s, "^%s*#?(%x%x%x%x%x%x)%s*$")
    if not clean then
        return U.issue(self, "SetHex", "expected #RRGGBB")
    end
    return self:SetValue(Color3.fromHex(clean), silent)
end
function P.Color:GetHex(): string
    return "#" .. self._value:ToHex():upper()
end
function P.Color:IsOpen(): boolean
    return self._popup ~= nil and self._popup.kind == "color"
end
function P.Color:Close()
    if self:IsOpen() then
        self._w:_closeFrom(self._popup)
    end
    return true
end
function P.Color:Toggle(): boolean
    if self:IsOpen() then
        self:Close()
        return false
    end
    return self:Open()
end
function P.Color:OnOpened(fn: any): Connection
    return U.event(self, "Opened"):Connect(fn)
end
function P.Color:OnClosed(fn: any): Connection
    return U.event(self, "Closed"):Connect(fn)
end

function P.Color:Open(): boolean
    if self:IsOpen() then
        return true
    end
    if self._popup then
        self._w:_closeFrom(self._popup, true)
    end
    local w = self._w
    local touch = w._layout.Touch
    local bar = if touch then w._layout.Hit else 18
    local svH = if touch then 138 else 150
    local hexH = math.max(27, w._layout.Hit)
    local p = U.popup(
        self,
        self._swatchButton,
        V(if touch then 220 else 176, svH + (if self._alphaShown then 2 * bar else bar) + hexH + 23)
    )
    if not p then
        return false
    end
    p.kind = "color"
    local life, content = p.life, p.content
    local sv = U.frame(
        content,
        { Active = true, Name = "SaturationValue", Position = O(7, 7), Size = UDim2.new(1, -14, 0, svH) }
    )
    U.corner(sv, D.FieldRadius)
    sv.BackgroundTransparency = 0
    local tint = U.frame(sv, { BackgroundTransparency = 0, BackgroundColor3 = White, Size = S(1, 1) })
    local shade = U.frame(sv, { BackgroundTransparency = 0, BackgroundColor3 = Black, Size = S(1, 1) })
    U.corner(tint, D.FieldRadius)
    U.corner(shade, D.FieldRadius)
    U.make("UIGradient", tint, { Transparency = NumberSequence.new(0, 1) })
    U.make("UIGradient", shade, { Rotation = 90, Transparency = NumberSequence.new(1, 0) })
    local mark = U.frame(sv, { AnchorPoint = V(0.5, 0.5), Size = O(10, 10), Name = "Selector", ZIndex = 3 })
    U.corner(mark, 10)
    U.make("UIStroke", mark, { Color = White, Thickness = 1.35 })
    local function addStrip(name: string, y: number)
        local hit =
            U.frame(content, { Active = true, Name = name, Position = O(7, y), Size = UDim2.new(1, -14, 0, bar) })
        local track = U.frame(hit, {
            AnchorPoint = V(0, 0.5),
            Position = S(0, 0.5),
            Size = UDim2.new(1, 0, 0, if touch then 9 else 5),
            BackgroundTransparency = 0,
            BackgroundColor3 = White,
        })
        U.corner(track, 3)
        local selector = U.frame(track, {
            AnchorPoint = V(0.5, 0.5),
            Size = O(4, if touch then 13 else 9),
            BackgroundTransparency = 0,
            BackgroundColor3 = White,
            ZIndex = 3,
            Name = "Selector",
        })
        U.corner(selector, 2)
        return hit, track, selector
    end
    local y = svH + 10
    local hue, hueTrack, hueMarker = addStrip("Hue", y)
    local colors = {}
    for i = 0, 6 do
        table.insert(colors, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((6 - i) / 6, 1, 1)))
    end
    U.make("UIGradient", hueTrack, { Color = ColorSequence.new(colors) })
    local alphaHit, alphaTint, alphaMarker
    y += bar
    if self._alphaShown then
        local h, t, m = addStrip("Alpha", y)
        alphaHit, alphaMarker = h, m
        for i = 0, 13 do
            U.frame(t, {
                Position = S(i / 14, 0),
                Size = S(1 / 14, 1),
                BackgroundTransparency = 0,
                BackgroundColor3 = if i % 2 == 0 then C(84, 83, 90) else C(135, 132, 139),
            })
        end
        alphaTint = U.frame(t, { Size = S(1, 1), BackgroundTransparency = 0, ZIndex = 2 })
        U.make("UIGradient", alphaTint, { Transparency = NumberSequence.new(1, 0) })
        y += bar
    end
    local hex = U.field(w, life, content, "Numeric", {
        Name = "Hex",
        Position = O(7, y + 2),
        Size = UDim2.new(1, -14, 0, hexH),
        TextXAlignment = Enum.TextXAlignment.Center,
        PlaceholderText = "#RRGGBB",
    })
    U.fill(w, life, hex, "SurfaceRaised")
    U.corner(hex, D.FieldRadius)
    U.focusable(self, life, hex, function()
        hex:CaptureFocus()
    end)
    local function update()
        local h, s, v = self:GetHSV()
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        mark.Position = S(math.clamp(s, 0.014, 0.986), math.clamp(1 - v, 0.014, 0.986))
        hueMarker.Position = S(math.clamp(1 - h, 0.01, 0.99), 0.5)
        if alphaMarker and alphaTint then
            alphaTint.BackgroundColor3 = self._value
            alphaMarker.Position = S(math.clamp(self._alpha, 0.01, 0.99), 0.5)
        end
        if not hex:IsFocused() then
            hex.Text = self:GetHex()
        end
    end
    p.update = update
    local function drag(surface: any, apply: any)
        life:Give(surface.InputBegan:Connect(function(i: InputObject)
            local function move(point: Vector2)
                local pos, size = surface.AbsolutePosition, surface.AbsoluteSize
                local x = math.clamp((point.X - pos.X) / math.max(1, size.X), 0, 1)
                local yy = math.clamp((point.Y - pos.Y) / math.max(1, size.Y), 0, 1)
                apply(x, yy)
            end
            w:_take(self, i, { Start = move, Move = move, Scroll = p.body })
        end))
    end
    drag(sv, function(x: number, yy: number)
        local h = self:GetHSV()
        self:SetHSV(h, x, 1 - yy)
    end)
    drag(hue, function(x: number)
        local _, s, v = self:GetHSV()
        self:SetHSV(1 - x, s, v)
    end)
    if alphaHit then
        drag(alphaHit, function(x: number)
            self:SetAlpha(x)
        end)
    end
    life:Give(hex.FocusLost:Connect(function()
        if not p.dead then
            self:SetHex(hex.Text)
            if not p.dead then
                update()
            end
        end
    end))
    update()
    U.emit(self, "Opened", self)
    return true
end

function Build.Color(owner: any, c: Payload)
    local n = U.row(owner, "ColorPicker", c, "normal")
    setmetatable(n, P.Color)
    local w, life = n._w, n._life
    n._alpha = math.clamp(U.number(c.Alpha, 1), 0, 1)
    n._defaultAlpha, n._lastHue, n._alphaShown = n._alpha, 0, c.ShowAlpha ~= false
    n._title.Visible = c.HideLabel ~= true
    n._reserve = 62
    local btn = U.rowButton(n, n._heading, {
        AnchorPoint = V(1, 0),
        Position = S(1, 0),
        Size = UDim2.new(if c.HideLabel then 1 else 0, if c.HideLabel then 0 else 55, 1, 0),
        Name = "Color",
    }, function()
        n:Toggle()
    end)
    n._swatchButton = btn
    local swatch =
        U.frame(btn, { AnchorPoint = V(1, 0.5), Position = S(1, 0.5), Size = O(29, 15), BackgroundTransparency = 0 })
    U.corner(swatch, D.FieldRadius)
    U.fill(w, life, swatch, "SurfaceRaised")
    local display = U.frame(swatch, { Size = S(1, 1), Name = "Swatch" })
    U.corner(display, D.FieldRadius)
    function n:_valueRender()
        if not self._value then
            return
        end
        local h, s, v = self._value:ToHSV()
        if s > 1e-7 and v > 1e-7 and not (h == 0 and self._lastHue == 1) then
            self._lastHue = h
        end
        display.BackgroundColor3 = self._value
        display.BackgroundTransparency = 1 - self._alpha * (if self:_isDisabled() then 0.42 else 1)
        local p = self._popup
        if p and p.update then
            p.update()
        end
    end
    function n:_notify(value: Color3, old: Color3, previousAlpha: number?, alpha: number?)
        local a = alpha or self._alpha
        U.call(self, "Callback", self._callback, value, old, self, a, previousAlpha or a)
        U.emit(self, "Changed", value, old, self, a, previousAlpha or a)
    end
    U.value(n, c, w:GetAccent())
    return U.ready(owner, n)
end

function P.Progress:SetText(text: string?)
    if text ~= nil and (type(text) ~= "string" or utf8.len(text) == nil) then
        return U.issue(self, "SetText", "expected text or nil")
    end
    self._customText = text
    self:_valueRender(true)
    return true
end
function P.Progress:GetText(): string?
    return self._customText
end
function P.Progress:SetShowValue(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetShowValue", "expected boolean")
    end
    self._showValue = v
    self:_valueRender(true)
    return true
end
function P.Progress:IsShowingValue(): boolean
    return self._showValue
end
function P.Progress:SetIndeterminate(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetIndeterminate", "expected boolean")
    end
    if self._indeterminate == v then
        return true
    end
    self._indeterminate = v
    self._w._animated[self] = if v then true else nil
    self:_updateAnimation()
    return true
end
function P.Progress:IsIndeterminate(): boolean
    return self._indeterminate
end
function Build.Progress(owner: any, c: Payload)
    local n = U.row(owner, "ProgressBar", c, "numeric")
    setmetatable(n, P.Progress)
    local w, life = n._w, n._life
    U.numeric(n, c, 0, 100, 1)
    n._showValue, n._customText = c.ShowValue ~= false, if type(c.Text) == "string" then c.Text else nil
    n._reserve = 92
    local info = U.text(w, life, n._heading, "Numeric", "", "TextSecondary", {
        AnchorPoint = V(1, 0),
        Position = S(1, 0),
        Size = UDim2.new(0.43, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    n._reserveRatio = 0.44
    local track = U.line(
        w,
        life,
        n._root,
        "Track",
        { Size = UDim2.new(1, 0, 0, D.Track), ClipsDescendants = true, Name = "ProgressTrack" }
    )
    local fill = U.line(w, life, track, function(t: Payload)
        return if n:_isDisabled() then t.AccentMuted else t.Accent
    end, { Size = S(0, 1), Name = "ProgressFill" })
    U.corner(track, 3)
    U.corner(fill, 3)
    function n:_layoutRender()
        track.Position = O(0, self._baseHeight - 24)
    end
    function n:_valueRender(instant: boolean)
        if not self._indeterminate then
            local x = if self._max == self._min then 1 else (self._value - self._min) / (self._max - self._min)
            U.tween(w, life, fill, "fill", "state", { Position = O(0, 0), Size = S(x, 1) }, instant)
        end
        info.Text = if self._customText ~= nil
            then self._customText
            elseif self._indeterminate then "In progress"
            else self._prefix .. U.numText(self, self._value) .. self._suffix
        info.Visible = self._showValue or self._customText ~= nil
    end
    function n:_updateAnimation()
        life:Remove("indeterminate")
        if not self._indeterminate then
            self:_valueRender(false)
            return
        end
        life:Remove("fill")
        fill.Size, fill.Position = S(0.30, 1), S(0.35, 0)
        if w._speed > 0 and self:_canInteract() then
            fill.Position = S(-0.30, 0)
            local tween = Tweens:Create(
                fill,
                TweenInfo.new(
                    D.Animation.progress / w._speed,
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut,
                    -1,
                    false
                ),
                { Position = S(1, 0) }
            )
            life:Give(function()
                tween:Cancel()
                tween:Destroy()
            end, "indeterminate")
            tween:Play()
        end
        self:_valueRender(true)
    end
    life:Give(function()
        w._animated[n] = nil
    end)
    n._visibilityRender = n._updateAnimation
    n._stateEffect = function()
        if n._indeterminate then
            n:_updateAnimation()
        end
    end
    U.value(n, c, n._min)
    U.ready(owner, n)
    n:SetIndeterminate(c.Indeterminate == true)
    return n
end

function P.Custom:SetHeight(v: number)
    if not U.finite(v) or v < 1 or v > 2000 then
        return U.issue(self, "SetHeight", "expected height from 1 to 2000")
    end
    self._heightBase = v
    self:_measure()
    return true
end
function P.Custom:GetHeight(): number
    return self._heightBase
end
function P.Custom:SetBuild(builder: any)
    if type(builder) ~= "function" then
        return U.issue(self, "SetBuild", "expected builder function")
    end
    self._life:Remove("build")
    local w, life = self._w, U.scope()
    self._life:Give(life, "build")
    local container = U.frame(self._root, { Name = "CustomContent", Size = UDim2.new(1, 0, 0, self._heightBase) })
    life:Give(container)
    self._customContainer = container
    local ctx: CustomContext = {
        Container = container,
        Theme = function(role)
            return w._theme._colors[role]
        end,
        Bind = function(instance, property, role)
            if w._theme._colors[role] then
                U.paint(w, life, instance, property, role)
            end
        end,
        Cleanup = function(item)
            return life:Give(item)
        end,
        Animate = function(instance, token, props)
            U.tween(w, life, instance, tostring(instance) .. token, token, props)
        end,
        GetFlag = function(flag)
            return w:GetFlag(flag)
        end,
        SetFlag = function(flag, v, silent)
            return w:SetFlag(flag, v, silent)
        end,
        CanInteract = function()
            return not self._dead and self:_canInteract()
        end,
    }
    local ok, dispose = U.call(self, "Build", builder, ctx)
    if not ok then
        self._life:Remove("build")
        self._customContainer = nil
        return false, dispose
    end
    if dispose ~= nil then
        life:Give(dispose)
    end
    return true
end
function Build.Custom(owner: any, c: Payload)
    local n = U.row(owner, "Custom", c, "custom")
    setmetatable(n, P.Custom)
    n._title.Visible = false
    n._divider.Visible = c.Separator == true
    n._heightBase = math.clamp(U.number(c.Height, 40), 1, 2000)
    n._layoutRender = function()
        if n._customContainer and n._customContainer.Parent then
            n._customContainer.Size = UDim2.new(1, 0, 0, n._heightBase)
        end
    end
    U.ready(owner, n)
    if c.Build ~= nil then
        n:SetBuild(c.Build)
    end
    return n
end

function P.Context:Open(): boolean
    return self:OpenContext()
end
function P.Context:Close()
    self:CloseContext()
    return true
end
function P.Context:Toggle()
    self:ToggleContext()
    return self:IsOpen()
end
function P.Context:IsOpen(): boolean
    return self._popup ~= nil and self._popup.kind == "context"
end
function P.Context:OnOpened(fn: any): Connection
    return U.event(self, "Opened"):Connect(fn)
end
function P.Context:OnClosed(fn: any): Connection
    return U.event(self, "Closed"):Connect(fn)
end
function P.Context:GetItems(): { any }
    return table.clone(self._context.Items or {})
end
function P.Context:SetItems(items: { any })
    if not U.dense(items) then
        return U.issue(self, "SetItems", "expected an array of item descriptors")
    end
    for _, item in items do
        if type(item) ~= "table" then
            return U.issue(self, "SetItems", "expected item descriptors")
        end
    end
    local open = self:IsOpen()
    if open then
        self:Close()
    end
    if self._dead then
        return false
    end
    self._context.Items = table.clone(items)
    if open then
        self:Open()
    end
    return true
end
function P.Context:SetQuickAction(action: any)
    if action ~= nil and (type(action) ~= "table" or type(action.Callback) ~= "function") then
        return U.issue(self, "SetQuickAction", "expected { Icon, Callback } or nil")
    end
    self._quick = if action then table.clone(action) else nil
    if self._quickRender then
        self:_quickRender()
    end
    return true
end
function P.Context:OpenContext(): boolean
    if self:IsOpen() then
        return true
    end
    return U.context(self, self._contextAnchor, self._context) ~= nil
end
function Build.Context(owner: any, c: Payload)
    local n = U.row(owner, "ContextMenu", c, "normal")
    setmetatable(n, P.Context)
    local w, life = n._w, n._life
    n._context = { Items = c.Items, Build = c.Build, Width = c.Width }
    n._reserve = 57
    local btn = U.rowButton(n, n._heading, {
        AnchorPoint = V(1, 0),
        Position = S(1, 0),
        Size = UDim2.new(0, 53, 1, 0),
        Name = "ContextAction",
    }, function()
        n:Toggle()
    end)
    n._contextAnchor = btn
    U.icon(w, life, btn, c.Icon or "more", 16, "TextSecondary", { Size = S(1, 1) })
    local quick = U.rowButton(n, n._heading, {
        AnchorPoint = V(1, 0),
        Position = S(1, 0),
        Name = "QuickAction",
        Visible = false,
    }, function()
        if n._quick then
            U.call(n, "quick action", n._quick.Callback, n)
        end
    end)
    local _, draw = U.icon(w, life, quick, nil, 16, function(t: Payload)
        return if n:_isDisabled() then t.TextDisabled elseif n._quick and n._quick.Danger then t.Danger else t.TextMuted
    end, { Size = S(1, 1) })
    n._interactive[quick] = function()
        return n._quick ~= nil
    end
    function n:_layoutRender()
        local width = math.max(if self._quick then 35 else 46, w._layout.Hit)
        quick.Size = UDim2.new(0, width, 1, 0)
        quick.Visible = self._quick ~= nil
        btn.Size = UDim2.new(0, width, 1, 0)
        btn.Position = UDim2.new(1, if self._quick then -width else 0, 0, 0)
        self._reserve = (if self._quick then 2 else 1) * width + 7
        self:_headingLayout()
    end
    function n:_quickRender()
        draw(self._quick and (self._quick.Icon or "more"))
        self:_measure()
        self:_stateRender()
    end
    if c.QuickAction then
        n:SetQuickAction(c.QuickAction)
    end
    n:_tooltipHook()
    return U.ready(owner, n)
end

function P.Window:CreateContextMenu(anchor: any, options: any)
    local object = if typeof(anchor) == "Instance"
        then anchor
        elseif type(anchor) == "table" and anchor.GetInstance then anchor:GetInstance()
        else nil
    if not object or not object:IsA("GuiObject") or not object:IsDescendantOf(self._gui) then
        return U.issue(self, "CreateContextMenu", "expected a descendant GuiObject or live controller")
    end
    local c = U.cfg(options)
    local semantic = if type(anchor) == "table" and anchor._w == self then anchor else self
    local n = U.node(self, P.Context, "ContextMenu", c, semantic, nil)
    n._context, n._contextAnchor = { Items = c.Items, Build = c.Build, Width = c.Width }, object
    n._life:Give(object.Destroying:Connect(function()
        n:Destroy()
    end))
    n._tooltipHook = function()
        U.hints(n, object)
    end
    n:_tooltipHook()
    n.GetInstance = function()
        return if n._dead then nil else object
    end
    return U.adopt(semantic, n)
end

function P.Tooltip:Show()
    if not self._visible then
        self._visible = true
    end
    self._w:_showTip(self, self._anchor)
    return self:IsOpen()
end
function P.Tooltip:Close()
    if self._w._tip and self._w._tip.owner == self then
        self._w:_hideTip()
    end
end
function P.Tooltip:IsOpen(): boolean
    return self._w._tip ~= nil and self._w._tip.owner == self
end
function P.Tooltip:SetText(text: string?)
    return self:SetTooltip(text)
end
function P.Tooltip:GetText(): string?
    return self:GetTooltip()
end
function P.Tooltip:GetInstance(): GuiObject
    return self._anchor
end

function P.Window:CreateTooltip(anchor: any, text: string)
    local obj = if typeof(anchor) == "Instance"
        then anchor
        elseif type(anchor) == "table" and anchor.GetInstance then anchor:GetInstance()
        else nil
    if not obj or not obj:IsA("GuiObject") or not obj:IsDescendantOf(self._gui) then
        return U.issue(self, "CreateTooltip", "invalid anchor")
    end
    local semantic = if type(anchor) == "table" and anchor._w == self then anchor else self
    local n = U.node(self, P.Tooltip, "Tooltip", { Tooltip = text }, semantic, nil)
    n._anchor = obj
    n._tooltipHook = function()
        U.hints(n, obj)
    end
    n:_tooltipHook()
    n._life:Give(obj.Destroying:Connect(function()
        n:Destroy()
    end))
    return U.adopt(semantic, n)
end

function P.Collection:AddToggle(c: any)
    return Build.Check(self, U.cfg(c), "Toggle")
end
function P.Collection:AddCheckbox(c: any)
    return Build.Check(self, U.cfg(c), "Checkbox")
end
function P.Collection:AddSlider(c: any)
    return Build.Slider(self, U.cfg(c), false)
end
function P.Collection:AddRangeSlider(c: any)
    return Build.Slider(self, U.cfg(c), true)
end
function P.Collection:AddDropdown(c: any)
    return Build.Dropdown(self, U.cfg(c), false)
end
function P.Collection:AddMultiDropdown(c: any)
    return Build.Dropdown(self, U.cfg(c), true)
end
function P.Collection:AddRadioGroup(c: any)
    return Build.InlineChoice(self, U.cfg(c), true)
end
function P.Collection:AddSegmentedControl(c: any)
    return Build.InlineChoice(self, U.cfg(c), false)
end
function P.Collection:AddInput(c: any)
    return Build.Input(self, U.cfg(c), false)
end
P.Collection.AddTextInput = P.Collection.AddInput
function P.Collection:AddNumberInput(c: any)
    return Build.Input(self, U.cfg(c), true)
end
function P.Collection:AddKeybind(c: any)
    return Build.Keybind(self, U.cfg(c))
end
function P.Collection:AddColorPicker(c: any)
    return Build.Color(self, U.cfg(c))
end
function P.Collection:AddButton(c: any)
    return Build.Button(self, U.cfg(c), false)
end
function P.Collection:AddIconButton(c: any)
    return Build.Button(self, U.cfg(c), true)
end
function P.Collection:AddProgressBar(c: any)
    return Build.Progress(self, U.cfg(c))
end
function P.Collection:AddLabel(c: any)
    return Build.Label(self, U.cfg(c), "Label")
end
function P.Collection:AddSectionLabel(c: any)
    return Build.Label(self, U.cfg(c), "SectionLabel")
end
function P.Collection:AddParagraph(c: any)
    return Build.Label(self, U.cfg(c), "Paragraph")
end
function P.Collection:AddStatus(c: any)
    return Build.Label(self, U.cfg(c), "Status")
end
function P.Collection:AddCustom(c: any)
    return Build.Custom(self, U.cfg(c))
end
function P.Collection:AddContextMenu(c: any)
    return Build.Context(self, U.cfg(c))
end
function P.Collection:AddDivider(options: any)
    local c = U.cfg(options)
    local n = U.row(self, "Divider", c, "divider")
    n._heightBase = math.clamp(U.number(c.Height, 9), 1, 56)
    n._title.Visible = false
    n._divider.Visible = true
    n._divider.Position = UDim2.new(0, 0, 0.5, 0)
    return U.ready(self, n)
end

function P.Watermark:SetText(text: string)
    if type(text) ~= "string" or utf8.len(text) == nil then
        return U.issue(self, "SetText", "expected UTF-8 text")
    end
    self._text.Text = text
    self:_layout()
    return true
end
function P.Watermark:GetText(): string
    return self._text.Text
end
function P.Watermark:SetPosition(pos: Vector2?)
    if pos ~= nil and (typeof(pos) ~= "Vector2" or not U.finite(pos.X) or not U.finite(pos.Y)) then
        return U.issue(self, "SetPosition", "expected Vector2 or nil")
    end
    self._position = pos
    self:_layout()
    return true
end
function P.Watermark:GetPosition(): Vector2
    return self._resolved
end
function P.Watermark:_layout()
    local view = self._w:_area()
    local width = math.min(math.max(70, U.measure(self._text.Text, D.Typography.Footer) + 24), math.max(1, view.X - 18))
    local x, y = if self._position then self._position.X else 10, if self._position then self._position.Y else 10
    self._resolved = V(math.clamp(x, 8, math.max(8, view.X - width - 8)), math.clamp(y, 8, math.max(8, view.Y - 34)))
    self._root.Position = O(self._resolved.X, self._resolved.Y)
    self._root.Size = O(width, 25)
end

function P.Window:SetWatermark(v: any)
    if type(v) ~= "boolean" and type(v) ~= "table" then
        return U.issue(self, "SetWatermark", "expected boolean or options")
    end
    if not self._watermark or self._watermark._dead then
        local root = U.frame(self._safe, { Name = "Watermark", ZIndex = 16 })
        local wm = U.node(self, P.Watermark, "Watermark", { Name = "Watermark", Visible = false }, self, root)
        U.fill(self, wm._life, root, "SurfaceRaised")
        U.corner(root, D.FieldRadius)
        U.line(self, wm._life, root, "Accent", { Size = UDim2.new(0, 2, 1, 0) })
        wm._text = U.text(
            self,
            wm._life,
            root,
            "Footer",
            self._name,
            "TextSecondary",
            { Position = O(10, 0), Size = UDim2.new(1, -19, 1, 0) }
        )
        wm._metaRender = function()
            wm:SetText(wm._name)
        end
        wm._visibilityRender = function()
            if not self._dead then
                self:_reflect("watermark", wm._visible)
            end
        end
        wm._beforeDestroy = function()
            self._watermark = nil
        end
        self._watermark = U.adopt(self, wm)
    end
    local wm = self._watermark
    if type(v) == "table" then
        if v.Text ~= nil then
            wm:SetText(v.Text)
        end
        if v.Position ~= nil then
            wm:SetPosition(v.Position)
        end
        wm:SetVisible(v.Visible ~= false)
    else
        wm:SetVisible(v)
    end
    wm:_layout()
    self:_reflect("watermark", wm._visible)
    return wm
end
function P.Window:GetWatermark(): any
    return self._watermark
end
function P.Window:_particlesRefresh()
    self._life:Remove("particles")
    local available = if self._useTouch then D.ParticleTouchMax else D.ParticleMax
    local count = if self._particleEnabled and self._visible then math.min(self._particleCount, available) else 0
    local pool = self._particles
    local random = Random.new(5731)
    for i = #pool + 1, count do
        local size = random:NextNumber(1.4, 3.5)
        local dot = U.line(self, self._life, self._particlesPane, "Accent", { Size = O(size, size), Name = "Particle" })
        U.corner(dot, 3)
        pool[i] =
            { gui = dot, x = (i * 0.618) % 1, y = (i * 0.363) % 1, phase = i * 1.87, drift = 0.012 + (i % 7) * 0.002 }
    end
    for i, particle in pool do
        particle.gui.Visible = i <= count
    end
    if count == 0 then
        return
    end
    local step, elapsed = 0, 0
    local function render()
        for i = 1, count do
            local p = pool[i]
            local x = (p.x + math.sin(elapsed * 0.42 + p.phase) * 0.013) % 1
            local y = if self._particleMode == "Twinkle" then p.y else (p.y - elapsed * p.drift) % 1
            p.gui.Position = S(x, y)
            p.gui.BackgroundTransparency = 0.86 + math.sin(elapsed * 0.9 + p.phase) * 0.07
        end
    end
    render()
    self._life:Give(
        Run.Heartbeat:Connect(function(dt: number)
            step += dt
            if step < 1 / 24 then
                return
            end
            elapsed += math.min(step, 0.15)
            step = 0
            render()
        end),
        "particles"
    )
end
function P.Window:SetParticles(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetParticles", "expected boolean")
    end
    if self._particleEnabled ~= v then
        self._particleEnabled = v
        self:_particlesRefresh()
    end
    self:_reflect("particles", v)
    self:_reflect("particleMode", if v then self._particleMode else "Disabled")
    return true
end
function P.Window:GetParticles(): boolean
    return self._particleEnabled
end
function P.Window:SetParticleCount(n: number)
    if not U.finite(n) or n < 0 then
        return U.issue(self, "SetParticleCount", "expected nonnegative count")
    end
    local count = math.min(D.ParticleMax, math.round(n))
    if self._particleCount ~= count then
        self._particleCount = count
        self:_particlesRefresh()
    end
    self:_reflect("particleCount", count)
    return true
end
function P.Window:GetParticleCount(): number
    return self._particleCount
end
function P.Window:SetParticleMode(mode: string)
    if mode == "Disabled" then
        return self:SetParticles(false)
    end
    if mode ~= "Twinkle" and mode ~= "Float" then
        return U.issue(self, "SetParticleMode", "expected Disabled, Float or Twinkle")
    end
    if mode ~= self._particleMode then
        self._particleMode = mode
        self:_particlesRefresh()
    end
    return self:SetParticles(true)
end
function P.Window:GetParticleMode(): string
    return if self._particleEnabled then self._particleMode else "Disabled"
end

function P.Toast:SetText(text: string)
    return self:SetName(text)
end
function P.Toast:GetText(): string
    return self:GetName()
end
function P.Toast:SetSeverity(v: string)
    if
        type(v) ~= "string" or not ({ Default = true, Info = true, Success = true, Warning = true, Error = true })[v]
    then
        return U.issue(self, "SetSeverity", "expected Default, Info, Success, Warning or Error")
    end
    self._severity = v
    self._severityPaint()
    return true
end
function P.Toast:GetSeverity(): string
    return self._severity
end
function P.Toast:SetDuration(seconds: number)
    if not U.finite(seconds) or seconds < 0 or seconds > 600 then
        return U.issue(self, "SetDuration", "expected 0–600 seconds")
    end
    self._seconds = seconds
    local life = self._life
    life:Remove("duration")
    life:Remove("lifeFill")
    self._lifeFill.Visible = seconds > 0
    if seconds > 0 then
        self._lifeFill.Size = S(1, 1)
        local animation =
            Tweens:Create(self._lifeFill, TweenInfo.new(seconds, Enum.EasingStyle.Linear), { Size = S(0, 1) })
        life:Give(function()
            animation:Cancel()
            animation:Destroy()
        end, "lifeFill")
        animation:Play()
        U.later(self, life, "duration", seconds, function()
            self:Destroy()
        end)
    end
    return true
end
function P.Toast:GetDuration(): number
    return self._seconds
end
function P.Toast:Close()
    self:Destroy()
end

function P.Window:_renderDock()
    local area = self:_area()
    self._toastLayer.Size = O(math.max(1, math.min(302, area.X - 22)), 1)
    if self._watermark and not self._watermark._dead then
        self._watermark:_layout()
    end
end
function P.Window:Notify(options: any)
    local c = U.cfg(options)
    local root = U.make("CanvasGroup", self._toastLayer, {
        Size = UDim2.new(1, 0, 0, 64),
        GroupTransparency = 1,
        Name = "Notification",
    })
    local n = U.node(self, P.Toast, "Notification", {
        Name = U.str(c.Title or c.Name, "Notification"),
        Description = c.Description or c.Text,
    }, self, root)
    local w, life = self, n._life
    n._severity = U.str(c.Severity, "Default")
    root.LayoutOrder = -n._sequence
    U.fill(w, life, root, "SurfaceRaised")
    U.corner(root, D.PopupRadius)
    local rail = U.frame(root, { Size = UDim2.new(0, 2, 1, 0) })
    n._severityPaint = U.fill(w, life, rail, function(t: Payload)
        return t[U.severity(n._severity)]
    end)
    local label =
        U.text(w, life, root, "Popup", n._name, "Text", { Position = O(13, 7), Size = UDim2.new(1, -26, 0, 21) })
    local detail = U.text(w, life, root, "Muted", n._description, "TextSecondary", {
        Position = O(13, 29),
        Size = UDim2.new(1, -27, 0, 32),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
    })
    local fillWrap = U.frame(root, { Position = UDim2.new(0, 2, 1, -2), Size = UDim2.new(1, -2, 0, 2) })
    n._lifeFill = U.line(w, life, fillWrap, "Accent", { Size = S(1, 1) })
    local hasAction = type(c.Action) == "function"
        or (type(c.Action) == "table" and type(c.Action.Callback) == "function")
    local action
    if hasAction then
        local cfg = if type(c.Action) == "function" then { Callback = c.Action } else c.Action
        local h = math.max(30, self._layout.Hit)
        local function trigger()
            U.call(n, "Notification action", cfg.Callback, n)
            if not n._dead then
                n:Destroy()
            end
        end
        action = U.button(
            n,
            life,
            root,
            { Position = UDim2.new(0, 10, 1, -(h + 6)), Size = UDim2.new(1, -20, 0, h) },
            trigger
        )
        U.fill(w, life, action, "Surface")
        U.corner(action, D.FieldRadius)
        U.text(
            w,
            life,
            action,
            "Popup",
            U.str(cfg.Text or cfg.Name, "Open"),
            "Text",
            { TextXAlignment = Enum.TextXAlignment.Center }
        )
        U.focusable(n, life, action, trigger)
    end
    n._metaRender = function()
        label.Text, detail.Text = n._name, n._description
        root.Size = UDim2.new(
            1,
            0,
            0,
            (if n._description == "" then 36 else 67) + (if action then action.Size.Y.Offset + 5 else 0)
        )
    end
    n._stateRender = function()
        if action then
            action.Interactable = not n:_isDisabled()
            action.Selectable = action.Interactable
        end
    end
    n._beforeDestroy = function()
        U.remove(self._toasts, n)
    end
    n:_metaRender()
    table.insert(self._toasts, n)
    U.adopt(self, n)
    while #self._toasts > math.min(if self._useTouch then 3 else 5, math.max(1, math.floor(self:_area().Y / 117))) do
        self._toasts[1]:Destroy()
    end
    U.tween(w, life, root, "appear", "toast", { GroupTransparency = 0 })
    n:SetDuration(math.clamp(U.number(c.Duration, 4.5), 0, 600))
    return n
end

function P.Dialog:IsOpen(): boolean
    return self._w._dialog == self and self._visible
end
function P.Dialog:Close(result: any)
    if not self:IsOpen() then
        return false
    end
    self._result = result
    self:Destroy()
    return true
end
function P.Dialog:SetTitle(v: string)
    return self:SetName(v)
end
function P.Dialog:GetTitle(): string
    return self:GetName()
end
function P.Dialog:OnClosed(fn: any): Connection
    return U.event(self, "DialogClosed"):Connect(fn)
end
function P.Dialog:SetVisible(v: boolean)
    if type(v) ~= "boolean" then
        return U.issue(self, "SetVisible", "expected boolean")
    end
    return if v then self:IsOpen() else self:Close()
end
function P.Dialog:_layout()
    local area = self._w:_area()
    local w = math.max(1, math.min(self._preferredWidth, area.X - 28))
    local actionH = math.max(36, if self._w._useTouch then D.TouchHit else 0)
    local col = if w < 325 then 1 else math.min(#self._actions, 2)
    col = math.max(1, col)
    local buttonArea = math.ceil(#self._actions / col) * (actionH + 6)
    local height = math.max(1, math.min(self._preferredHeight + buttonArea, area.Y - 26))
    self._panel.Size = O(w, height)
    self._panel.Position = O(self._w._safe.AbsoluteSize.X / 2, area.Y / 2)
    local visibleActions = math.min(buttonArea, math.max(actionH + 3, height - 90))
    self._actionHost.Size = UDim2.new(1, -24, 0, visibleActions)
    self._body.Size = UDim2.new(1, -24, 1, -(visibleActions + 57))
    self._actionGrid.CellSize = UDim2.new(1 / col, -((col - 1) * 6 / col), 0, actionH)
end

function P.Dialog:SetButtons(buttons: any)
    if not U.dense(buttons) then
        return U.issue(self, "SetButtons", "expected an array of buttons")
    end
    if #buttons > 6 then
        return U.issue(self, "SetButtons", "up to six actions are supported")
    end
    for _, item in buttons do
        if type(item) ~= "table" then
            return U.issue(self, "SetButtons", "expected button descriptors")
        end
    end
    if #buttons == 0 then
        buttons = { { Text = "Close" } }
    end
    self._life:Remove("actions")
    local life, w = U.scope(), self._w
    self._life:Give(life, "actions")
    self._actions = table.clone(buttons)
    local preferred
    for i, item in buttons do
        local function trigger()
            if item.Disabled == true or not self:IsOpen() then
                return
            end
            local ok, result = U.call(self, "Dialog action", item.Callback, self, item.Value)
            if ok and result ~= false and item.Close ~= false and not self._dead then
                self:Close(item.Value)
            end
        end
        local active = item.Primary == true
        local b = U.button(self, life, self._actionHost, {
            LayoutOrder = i,
            Interactable = item.Disabled ~= true,
            Selectable = item.Disabled ~= true,
        }, trigger)
        life:Give(b)
        U.fill(
            w,
            life,
            b,
            if item.Disabled == true
                then "Surface"
                elseif item.Danger == true then "Danger"
                elseif active then "Accent"
                else "SurfaceRaised"
        )
        U.corner(b, D.FieldRadius)
        U.text(
            w,
            life,
            b,
            "Popup",
            U.str(item.Text or item.Name, "Close"),
            if item.Disabled == true
                then "TextDisabled"
                elseif item.Danger == true then "Background"
                elseif active then "AccentInk"
                else "Text",
            { Position = O(5, 0), Size = UDim2.new(1, -10, 1, 0), TextXAlignment = Enum.TextXAlignment.Center }
        )
        if item.Disabled ~= true then
            U.focusable(self, life, b, trigger)
            if not preferred then
                preferred = b
            end
        end
    end
    self:_layout()
    if preferred then
        Gui.SelectedObject = preferred
    end
    return true
end

function P.Window:CreateDialog(options: any)
    if not self._visible then
        return U.issue(self, "CreateDialog", "show the window first")
    end
    if self._dialog then
        self._dialog:Destroy()
    end
    if self._dead then
        return nil, "window destroyed"
    end
    local c = U.cfg(options)
    local previous = Gui.SelectedObject
    self:SetDrawerOpen(false)
    self:_quiet(self)
    local root = U.frame(self._modalLayer, { Size = S(1, 1), Name = "Dialog", Active = true })
    local n = U.node(self, P.Dialog, "Dialog", {
        Name = U.str(c.Title or c.Name, "Dialog"),
        Description = c.Description or c.Text,
    }, self, root)
    local w, life = self, n._life
    n._escape = c.Escape ~= false
    n._actions = {}
    n._preferredWidth = math.clamp(U.number(c.Width, 366), 260, 600)
    n._preferredHeight = math.clamp(U.number(c.Height, 132), 98, 420)
    local scrim = U.button(n, life, root, {
        Size = S(1, 1),
        Selectable = false,
        BackgroundColor3 = Black,
        BackgroundTransparency = 1,
        Name = "Backdrop",
    }, function()
        if c.DismissOnBackdrop then
            n:Close()
        end
    end)
    local panel = U.make("CanvasGroup", root, {
        AnchorPoint = V(0.5, 0.5),
        Active = true,
        ZIndex = 2,
        GroupTransparency = 1,
        Name = "Panel",
    })
    n._panel = panel
    U.fill(w, life, panel, "Surface")
    U.corner(panel, D.PopupRadius)
    U.line(w, life, panel, "Accent", { Position = O(12, 0), Size = O(37, 2) })
    local title =
        U.text(w, life, panel, "Brand", n._name, "Text", { Position = O(12, 5), Size = UDim2.new(1, -24, 0, 33) })
    n._body = U.scroll(panel, false, { Position = O(12, 43), Name = "Description" })
    local desc = U.text(w, life, n._body, "Control", n._description, "TextSecondary", {
        Size = UDim2.new(1, -3, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        TextYAlignment = Enum.TextYAlignment.Top,
    })
    n._actionHost =
        U.scroll(panel, false, { AnchorPoint = V(0, 1), Position = UDim2.new(0, 12, 1, -9), Name = "Actions" })
    n._actionGrid = U.make("UIGridLayout", n._actionHost, {
        CellPadding = O(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    n._metaRender = function()
        title.Text, desc.Text = n._name, n._description
    end
    n._beforeDestroy = function()
        if self._dialog == n then
            self._dialog = nil
            if not self._dead then
                self._shell.Interactable = not self._disabled
                self:_drawerLayout(true)
                if previous and U.guiVisible(previous) and previous.Interactable then
                    Gui.SelectedObject = previous
                end
            end
        end
        if not self._dead then
            U.emit(n, "DialogClosed", n._result, n)
        end
    end
    self._dialog = n
    self._shell.Interactable = false
    self:_drawerLayout(true)
    U.adopt(self, n)
    if not n:SetButtons(c.Buttons or {}) then
        n:SetButtons({})
    end
    U.tween(w, life, scrim, "scrim", "modal", { BackgroundTransparency = 0.43 })
    U.tween(w, life, panel, "panel", "modal", { GroupTransparency = 0 })
    return n
end

-- The flag registry indexes live value owners rather than storing a second state copy.
function P.Window:GetFlag(key: string): any
    local flag = if type(key) == "string" then self._flags[key] else nil
    if flag then
        return flag:GetValue()
    end
    return nil
end
function P.Window:SetFlag(key: string, value: any, silent: boolean?)
    local flag = if type(key) == "string" then self._flags[key] else nil
    if not flag then
        return U.issue(self, "SetFlag", "unknown flag " .. tostring(key))
    end
    return flag:SetValue(value, silent)
end
function P.Window:GetFlags(): Payload
    local flags = {}
    for key, owner in self._flags do
        flags[key] = owner:GetValue()
    end
    return flags
end

function U.encode(value: any, depth: number): (boolean, any)
    if depth > 8 then
        return false, nil
    end
    if value == nil then
        return true, { __jetz = "nil" }
    end
    if type(value) == "boolean" or (type(value) == "string" and utf8.len(value)) or U.finite(value) then
        return true, value
    end
    if U.color(value) then
        return true, { __jetz = "color", R = value.R, G = value.G, B = value.B }
    end
    if typeof(value) == "EnumItem" then
        return true, { __jetz = "enum", Type = tostring(value.EnumType):gsub("^Enum%.", ""), Name = value.Name }
    end
    if type(value) ~= "table" then
        return false, nil
    end
    if U.finite(value.Min) and U.finite(value.Max) and value.Min <= value.Max then
        return true, { __jetz = "range", Min = value.Min, Max = value.Max }
    end
    if not U.dense(value) then
        return false, nil
    end
    local items = {}
    for i, v in value do
        local ok, item = U.encode(v, depth + 1)
        if not ok then
            return false, nil
        end
        items[i] = item
    end
    return true, { __jetz = "array", Items = items }
end
function U.decode(value: any, depth: number): (boolean, any)
    if depth > 8 then
        return false, nil
    end
    if type(value) ~= "table" then
        return value == nil or U.color(value) or (U.option(value) and typeof(value) ~= "Instance"), value
    end
    local kind = value.__jetz
    if kind == "nil" then
        return true, nil
    end
    if kind == "color" then
        for _, c in { "R", "G", "B" } do
            if not U.finite(value[c]) or value[c] < 0 or value[c] > 1 then
                return false, nil
            end
        end
        return true, Color3.new(value.R, value.G, value.B)
    end
    if kind == "enum" then
        if type(value.Type) ~= "string" or type(value.Name) ~= "string" then
            return false, nil
        end
        local ok, item = pcall(function()
            return (Enum :: any)[value.Type][value.Name]
        end)
        return ok and typeof(item) == "EnumItem", item
    end
    if kind == "range" or (kind == nil and value.Min ~= nil) then
        if not U.finite(value.Min) or not U.finite(value.Max) or value.Min > value.Max then
            return false, nil
        end
        return true, { Min = value.Min, Max = value.Max }
    end
    local items = if kind == "array" then value.Items elseif kind == nil then value else nil
    if not U.dense(items) then
        return false, nil
    end
    local result = {}
    for i, item in items do
        local ok, v = U.decode(item, depth + 1)
        if not ok or v == nil then
            return false, nil
        end
        result[i] = v
    end
    return true, result
end


P.ProfileManager = {}
P.ProfileManager.__index = P.ProfileManager

function U.profileName(value: any): string?
    if type(value) ~= "string" then return nil end
    local name = value:gsub('[%z\1-\31<>:"/\\|?*]', "_"):match("^%s*(.-)%s*$") or ""
    name = name:gsub("%.+$", ""):gsub("^%.+", ""):gsub("%s+$", "")
    if #name > 64 then name = name:sub(1, 64) end
    if name == "" or name == "." or name == ".." then return nil end
    local upper = name:upper()
    if upper == "CON" or upper == "PRN" or upper == "AUX" or upper == "NUL"
        or upper:match("^COM%d$") or upper:match("^LPT%d$")
    then name = "_" .. name end
    return name
end

function P.ProfileManager.new(w: any, options: any): any
    local c = U.cfg(options)
    local self = setmetatable({}, P.ProfileManager)
    self.window, self.api, self.sources = w, {}, {}
    for _, key in { "isfolder", "makefolder", "isfile", "readfile", "writefile", "delfile", "listfiles" } do
        local fn, source = U.resolveExecutor(key)
        self.api[key], self.sources[key] = fn, source
    end
    self.required = { "isfolder", "makefolder", "isfile", "readfile", "writefile" }
    self.missing = {}
    for _, key in self.required do
        if type(self.api[key]) ~= "function" then
            table.insert(self.missing, key)
        end
    end
    self.available = #self.missing == 0
    self.gameName = U.profileName(c.GameName) or U.profileName(w._name) or ("Place_" .. tostring(game.PlaceId))
    self.placeId = game.PlaceId
    self.root = U.str(c.ConfigRoot, "JetZ/Configs")
    self.folder = self.root .. "/" .. self.gameName
    self.indexPath, self.autoloadPath = self.folder .. "/index.json", self.root .. "/autoload.json"
    self.activeProfile, self.dirty, self.pending, self.applying = nil, false, nil, false
    self.lastResult = nil
    self.autoloadState = self.available and "Idle" or "Filesystem unavailable"
    if self.available then
        self:EnsureFolder(self.folder)
        self:PrepareAutoload()
    end
    return self
end

function P.ProfileManager:Resolve(key: string): any
    local fn = self.api[key]
    if type(fn) == "function" then
        return fn
    end
    local resolved, source = U.resolveExecutor(key)
    if type(resolved) == "function" then
        self.api[key], self.sources[key] = resolved, source
        local at = table.find(self.missing, key)
        if at then table.remove(self.missing, at) end
        self.available = #self.missing == 0
        return resolved
    end
    return nil
end

function P.ProfileManager:Call(key: string, ...: any): (boolean, any)
    local fn = self:Resolve(key)
    if type(fn) ~= "function" then
        return false, "Executor function unavailable: " .. key
    end
    local ok, result = pcall(fn, ...)
    if ok then
        return true, result
    end
    return false, tostring(result)
end

function P.ProfileManager:EnsureFolder(path: string): (boolean, any)
    for _, key in self.required do
        self:Resolve(key)
    end
    if not self.available then
        return false, "Filesystem unavailable (missing: " .. table.concat(self.missing, ", ") .. ")"
    end
    local current = ""
    for part in path:gmatch("[^/]+") do
        current = if current == "" then part else current .. "/" .. part
        local ok, exists = self:Call("isfolder", current)
        if not ok then return false, exists end
        if not exists then
            local made, why = self:Call("makefolder", current)
            if not made then return false, why end
        end
    end
    return true
end

function P.ProfileManager:Read(path: string): (any, any)
    if not self:Resolve("isfile") or not self:Resolve("readfile") then
        return nil, "Filesystem read functions unavailable"
    end
    local ok, exists = self:Call("isfile", path)
    if not ok or not exists then return nil, ok and "File not found" or exists end
    local readOK, raw = self:Call("readfile", path)
    if not readOK or type(raw) ~= "string" then return nil, readOK and "Invalid JSON" or raw end
    local decodedOK, data = pcall(Http.JSONDecode, Http, raw)
    if not decodedOK or type(data) ~= "table" then return nil, "Invalid JSON" end
    return data, nil
end

function P.ProfileManager:Write(path: string, data: any): (boolean, any)
    local folder = path:match("^(.*)/[^/]+$")
    if folder then
        local ready, why = self:EnsureFolder(folder)
        if not ready then return false, why end
    end
    local encodedOK, raw = pcall(Http.JSONEncode, Http, data)
    if not encodedOK or type(raw) ~= "string" then return false, "Invalid JSON" end
    local wrote, why = self:Call("writefile", path, raw)
    if not wrote then return false, why end
    local verifyOK, verify = self:Call("readfile", path)
    if not verifyOK or type(verify) ~= "string" then return false, "Write verification failed" end
    local valid = pcall(Http.JSONDecode, Http, verify)
    if valid then
        return true, nil
    end
    return false, "Write verification failed"
end

function P.ProfileManager:Path(name: string): string
    return self.folder .. "/" .. name .. ".json"
end

function P.ProfileManager:Names(): { string }
    local names = {}
    local index = self:Read(self.indexPath)
    if type(index) == "table" and type(index.Profiles) == "table" then
        for _, value in index.Profiles do
            local clean = U.profileName(value)
            if clean and not table.find(names, clean) then table.insert(names, clean) end
        end
    elseif type(self.api.listfiles) == "function" then
        local ok, files = self:Call("listfiles", self.folder)
        if ok and type(files) == "table" then
            for _, path in files do
                if type(path) == "string" then
                    local name = path:match("([^/\\]+)%.json$")
                    if name and name ~= "index" and not table.find(names, name) then table.insert(names, name) end
                end
            end
        end
    end
    table.sort(names, function(a,b) return a:lower() < b:lower() end)
    return names
end

function P.ProfileManager:Index(name: string, present: boolean)
    local names = self:Names()
    local at = table.find(names, name)
    if present and not at then table.insert(names, name) elseif not present and at then table.remove(names, at) end
    table.sort(names, function(a,b) return a:lower() < b:lower() end)
    self:Write(self.indexPath, { Version = 1, Profiles = names, UpdatedAt = os.time() })
    self:RefreshUI()
end

function P.ProfileManager:Snapshot(): any
    local config, notSaved = self.window:ExportConfig(false)
    return { Version = 1, Game = self.gameName, PlaceId = self.placeId, UpdatedAt = os.time(), Config = config, NotSaved = notSaved }
end

function P.ProfileManager:ReadProfile(name: string): (any, any)
    local clean = U.profileName(name)
    if not clean then return nil, "Invalid profile name" end
    local data, why = self:Read(self:Path(clean))
    if not data then return nil, why end
    if data.Version ~= 1 or type(data.Config) ~= "table" then return nil, "Unsupported profile format" end
    return data, nil
end

function P.ProfileManager:Save(name: string, createOnly: boolean?): (boolean, any)
    local clean = U.profileName(name)
    if not clean then return false, "Invalid profile name" end
    local ok, exists = self:Call("isfile", self:Path(clean))
    if not ok then return false, exists end
    if createOnly and exists then return false, "Profile already exists" end
    local wrote, why = self:Write(self:Path(clean), self:Snapshot())
    if wrote then
        self.activeProfile, self.dirty = clean, false
        self:Index(clean, true)
        self:RefreshUI()
    end
    return wrote, why
end

function P.ProfileManager:SetPending(config: any, silent: boolean?)
    if type(config) ~= "table" then self.pending = nil return end
    self.pending = {
        Flags = table.clone(type(config.Flags) == "table" and config.Flags or config),
        Extras = table.clone(type(config.Extras) == "table" and config.Extras or {}),
        Silent = silent == true,
    }
end

function P.ProfileManager:Hydrate(control: any)
    local pending, flag = self.pending, control._flag
    if not pending or not flag or pending.Flags[flag] == nil then return end
    local ok, value = U.decode(pending.Flags[flag], 0)
    if ok then
        local valid, canonical = control:_normalize(value)
        if valid then
            self.applying = true
            control:_commit(canonical, pending.Silent, true)
            local meta = pending.Extras[flag]
            if type(meta) == "table" then
                if control._kind == "ColorPicker" and U.finite(meta.Alpha) and control.SetAlpha then
                    control:SetAlpha(meta.Alpha, true)
                elseif control._kind == "Keybind" and type(meta.Mode) == "string" and control.SetKeybindMode then
                    control:SetKeybindMode(meta.Mode)
                elseif control._kind == "Toggle" or control._kind == "Checkbox" then
                    if meta.Key ~= nil and control.SetKeybind then
                        local keyOK, key = U.decode(meta.Key, 0)
                        if keyOK then control:SetKeybind(key) end
                    end
                    if type(meta.Mode) == "string" and control.SetKeybindMode then control:SetKeybindMode(meta.Mode) end
                end
            end
            self.applying = false
        end
    end
    pending.Flags[flag], pending.Extras[flag] = nil, nil
    if next(pending.Flags) == nil then self.pending, self.autoloadState = nil, "Ready" end
end

function P.ProfileManager:Apply(data: any, silent: boolean?): (boolean, any)
    if type(data) ~= "table" or type(data.Config) ~= "table" then return false, "Unsupported profile format" end
    self.applying = true
    local ok, report = self.window:ImportConfig(data.Config, { Silent = silent == true, Atomic = true, IgnoreUnknown = true })
    self.applying = false
    if not ok then self.lastResult = report return false, report end
    self:SetPending(data.Config, silent)
    if self.pending then
        for flag in table.clone(self.pending.Flags) do
            local control = self.window._flags[flag]
            if control then self:Hydrate(control) end
        end
    end
    self.lastResult = report
    return true, report
end

function P.ProfileManager:Load(name: string, silent: boolean?): (boolean, any)
    local clean = U.profileName(name)
    if not clean then return false, "Invalid profile name" end
    local data, why = self:ReadProfile(clean)
    if not data then return false, why end
    local ok, report = self:Apply(data, silent)
    if ok then
        self.activeProfile, self.dirty, self.autoloadState = clean, false, "Ready"
        self:RefreshUI()
    end
    return ok, report
end

function P.ProfileManager:Delete(name: string): (boolean, any)
    local clean = U.profileName(name)
    if not clean then return false, "Invalid profile name" end
    if type(self:Resolve("delfile")) ~= "function" then return false, "Executor function unavailable: delfile" end
    local checked, exists = self:Call("isfile", self:Path(clean))
    if not checked then return false, exists end
    if not exists then return false, "Profile not found" end
    local auto = self:GetAutoload()
    if auto.enabled and auto.profile == clean then self:SetAutoload(nil, false) end
    local ok, why = self:Call("delfile", self:Path(clean))
    if ok then
        self:Index(clean, false)
        if self.activeProfile == clean then self.activeProfile, self.dirty = nil, false end
        self:RefreshUI()
    end
    return ok, why
end

function P.ProfileManager:Duplicate(name: string, newName: string): (boolean, any)
    local data, why = self:ReadProfile(name)
    local clean = U.profileName(newName)
    if not data then return false, why end
    if not clean then return false, "Invalid profile name" end
    local checked, exists = self:Call("isfile", self:Path(clean))
    if not checked then return false, exists end
    if exists then return false, "Profile already exists" end
    data.UpdatedAt = os.time()
    local ok, err = self:Write(self:Path(clean), data)
    if ok then self:Index(clean, true) end
    return ok, err
end

function P.ProfileManager:Rename(name: string, newName: string): (boolean, any)
    local old, new = U.profileName(name), U.profileName(newName)
    if not old or not new then return false, "Invalid profile name" end
    if old == new then return true end
    local auto = self:GetAutoload()
    local ok, why = self:Duplicate(old, new)
    if not ok then return false, why end
    local deleted, deleteWhy = self:Delete(old)
    if not deleted then
        if type(self.api.delfile) == "function" then
            self:Call("delfile", self:Path(new))
            self:Index(new, false)
        end
        return false, deleteWhy
    end
    if auto.enabled and auto.profile == old then self:SetAutoload(new, true) end
    if self.activeProfile == old then self.activeProfile = new end
    self:RefreshUI()
    return true
end

function P.ProfileManager:AutoloadData(): any
    local data = self:Read(self.autoloadPath)
    return if type(data) == "table" and data.Version == 1 and type(data.Games) == "table" then data else { Version = 1, Games = {} }
end

function P.ProfileManager:GetAutoload(): any
    local record = self:AutoloadData().Games[tostring(self.placeId)]
    return if type(record) == "table" and record.Game == self.gameName then table.clone(record) else { enabled = false }
end

function P.ProfileManager:SetAutoload(name: string?, enabled: boolean): (boolean, any)
    for _, key in self.required do self:Resolve(key) end
    if not self.available then
        return false, "Filesystem unavailable (missing: " .. table.concat(self.missing, ", ") .. ")"
    end
    local data, key = self:AutoloadData(), tostring(self.placeId)
    if enabled then
        local clean = U.profileName(name)
        if not clean then return false, "Invalid profile name" end
        local checked, exists = self:Call("isfile", self:Path(clean))
        if not checked or not exists then return false, checked and "Profile not found" or exists end
        data.Games[key] = { enabled = true, profile = clean, Game = self.gameName, PlaceId = self.placeId }
    else
        data.Games[key] = { enabled = false, Game = self.gameName, PlaceId = self.placeId }
    end
    local ok, why = self:Write(self.autoloadPath, data)
    if ok then self:RefreshUI() end
    return ok, why
end

function P.ProfileManager:PrepareAutoload()
    local auto = self:GetAutoload()
    if not auto.enabled or type(auto.profile) ~= "string" then self.autoloadState = "Disabled" return end
    local data, why = self:ReadProfile(auto.profile)
    if not data then self.autoloadState = "Failed: " .. tostring(why) return end
    self.activeProfile, self.dirty, self.autoloadState = auto.profile, false, "Hydrating"
    self:SetPending(data.Config, false)
end

function P.ProfileManager:ApplyAutoload(): (boolean, any)
    local auto = self:GetAutoload()
    if not auto.enabled or type(auto.profile) ~= "string" then return false, "Autoload is disabled" end
    return self:Load(auto.profile, false)
end

function P.ProfileManager:ControlChanged(_: any)
    if not self.applying and self.activeProfile then
        self.dirty = true
        self:RefreshUI()
    end
end

function P.ProfileManager:RefreshUI()
    local ui = self.ui
    if not ui then return end
    local names = self:Names()
    if ui.Profile then
        ui.Profile:SetValues(#names > 0 and names or { "No profiles" }, true)
        if self.activeProfile and table.find(names, self.activeProfile) then ui.Profile:SetValue(self.activeProfile, true) end
    end
    if ui.Status then
        local w = self.window
        ui.Status:SetText(w:Translate("Active:") .. " " .. (self.activeProfile or "None") .. (self.dirty and ("  •  " .. w:Translate("Unsaved changes")) or ""))
        if ui.Status.SetSeverity then
            ui.Status:SetSeverity(if not self.available then "Warning" elseif self.dirty then "Warning" else "Success")
        end
    end
    if ui.AutoloadStatus then
        local auto = self:GetAutoload()
        local w = self.window
        ui.AutoloadStatus:SetText(if auto.enabled
            then w:Translate("Autoload:") .. " " .. tostring(auto.profile)
            else w:Translate("Autoload:") .. " " .. w:Translate("Off"))
        if ui.AutoloadStatus.SetSeverity then
            ui.AutoloadStatus:SetSeverity(if auto.enabled then "Success" else "Info")
        end
    end
end

function P.Window:SaveProfile(name: string) return self._profileManager:Save(name, false) end
function P.Window:CreateProfile(name: string) return self._profileManager:Save(name, true) end
function P.Window:LoadProfile(name: string, silent: boolean?) return self._profileManager:Load(name, silent) end
function P.Window:RefreshProfiles(): { string } return self._profileManager:Names() end
function P.Window:GetActiveProfile(): string? return self._profileManager.activeProfile end
function P.Window:GetPersistenceStatus(): any
    local m = self._profileManager
    for _, key in m.required do m:Resolve(key) end
    return {
        available = m.available,
        game = m.gameName,
        placeId = m.placeId,
        folder = m.folder,
        canDelete = type(m:Resolve("delfile")) == "function",
        canList = type(m:Resolve("listfiles")) == "function",
        autoloadState = m.autoloadState,
        dirty = m.dirty,
        missing = table.clone(m.missing),
        sources = table.clone(m.sources),
    }
end
function P.Window:ExportProfile(name: string?): (string?, any)
    local data, why
    if name then
        data, why = self._profileManager:ReadProfile(name)
    else
        data = self._profileManager:Snapshot()
    end
    if not data then
        return nil, why
    end
    local ok, json = pcall(Http.JSONEncode, Http, data)
    if ok then
        return json, nil
    end
    return nil, tostring(json)
end
function P.Window:ImportProfile(name: string, json: string, overwrite: boolean?): (boolean, any)
    local clean = U.profileName(name)
    if not clean or type(json) ~= "string" or #json > 2097152 then return false, "Invalid profile" end
    local ok, data = pcall(Http.JSONDecode, Http, json)
    if not ok or type(data) ~= "table" or data.Version ~= 1 or type(data.Config) ~= "table" then return false, "Invalid profile" end
    local path = self._profileManager:Path(clean)
    local checked, exists = self._profileManager:Call("isfile", path)
    if not checked then return false, exists end
    if exists and overwrite ~= true then return false, "Profile already exists" end
    data.Game, data.PlaceId, data.UpdatedAt = self._profileManager.gameName, game.PlaceId, os.time()
    local wrote, err = self._profileManager:Write(path, data)
    if wrote then self._profileManager:Index(clean, true) end
    return wrote, err
end
function P.Window:DuplicateProfile(name: string, newName: string) return self._profileManager:Duplicate(name, newName) end
function P.Window:RenameProfile(name: string, newName: string) return self._profileManager:Rename(name, newName) end
function P.Window:DeleteProfile(name: string) return self._profileManager:Delete(name) end
function P.Window:SetAutoload(name: string) return self._profileManager:SetAutoload(name, true) end
function P.Window:DisableAutoload() return self._profileManager:SetAutoload(nil, false) end
function P.Window:GetAutoload() return self._profileManager:GetAutoload() end
function P.Window:ApplyAutoload() return self._profileManager:ApplyAutoload() end
function P.Window:GetConfigDiagnostics(): any
    local m = self._profileManager
    for _, key in m.required do m:Resolve(key) end
    return {
        available = m.available,
        activeProfile = m.activeProfile,
        dirty = m.dirty,
        autoloadState = m.autoloadState,
        pending = m.pending ~= nil,
        folder = m.folder,
        lastResult = m.lastResult,
        missing = table.clone(m.missing),
        sources = table.clone(m.sources),
        clipboard = select(2, U.resolveExecutor("setclipboard")),
    }
end

function P.Window:ExportConfig(json: boolean?)
    if json ~= nil and type(json) ~= "boolean" then
        return U.issue(self, "ExportConfig", "expected boolean or nil")
    end
    local flags, extras, notSaved = {}, {}, {}
    for flag, control in self._flags do
        local ok, val = U.encode(control:GetValue(), 0)
        if ok then
            flags[flag] = val
            if control._kind == "ColorPicker" then
                extras[flag] = { Alpha = control._alpha }
            elseif control._kind == "Keybind" then
                extras[flag] = { Mode = control._mode }
            elseif control._kind == "Checkbox" or control._kind == "Toggle" then
                if control._key then
                    local _, key = U.encode(control._key, 0)
                    extras[flag] = { Key = key, Mode = control._keyMode }
                elseif control._bindSlot then
                    extras[flag] = { Key = { __jetz = "nil" }, Mode = control._keyMode }
                end
            end
        else
            table.insert(notSaved, flag)
        end
    end
    table.sort(notSaved)
    local data = { Version = 1, Flags = flags, Extras = extras }
    if json then
        local ok, s = pcall(function()
            return Http:JSONEncode(data)
        end)
        if not ok then
            return U.issue(self, "ExportConfig", s)
        end
        return s, notSaved
    end
    return data, notSaved
end

function P.Window:ImportConfig(data: any, options: ConfigOptions?)
    if options ~= nil and type(options) ~= "table" then
        return U.issue(self, "ImportConfig", "expected options or nil")
    end
    local c = options or {}
    local source = data
    if type(data) == "string" then
        if #data > 2097152 then
            return U.issue(self, "ImportConfig", "JSON config exceeds 2 MiB")
        end
        local ok, decoded = pcall(function()
            return Http:JSONDecode(data)
        end)
        if not ok then
            return U.issue(self, "ImportConfig", "invalid JSON")
        end
        source = decoded
    end
    if type(source) ~= "table" then
        return U.issue(self, "ImportConfig", "expected config table or JSON")
    end
    local flags, extras = source, {}
    if source.Version ~= nil or type(source.Flags) == "table" then
        if source.Version ~= 1 or type(source.Flags) ~= "table" then
            return U.issue(self, "ImportConfig", "unsupported config format")
        end
        if source.Extras ~= nil and type(source.Extras) ~= "table" then
            return U.issue(self, "ImportConfig", "Extras must be a table")
        end
        flags, extras = source.Flags, source.Extras or {}
    end
    if
        (c.Silent ~= nil and type(c.Silent) ~= "boolean")
        or (c.Atomic ~= nil and type(c.Atomic) ~= "boolean")
        or (c.IgnoreUnknown ~= nil and type(c.IgnoreUnknown) ~= "boolean")
    then
        return U.issue(self, "ImportConfig", "options must be booleans")
    end
    local report = { Applied = 0, Changed = 0, Ignored = {}, Errors = {} }
    local staged, keys = {}, {}
    for name in flags do
        if type(name) == "string" then
            table.insert(keys, name)
        else
            report.Errors[tostring(name)] = "flag must be a string"
        end
    end
    table.sort(keys)
    for _, name in keys do
        local control = self._flags[name]
        if not control then
            if c.IgnoreUnknown ~= false then
                table.insert(report.Ignored, name)
            else
                report.Errors[name] = "unknown flag"
            end
        else
            local ok, value = U.decode(flags[name], 0)
            if ok then
                local valid, canonical, reason = control:_normalize(value)
                if not valid then
                    report.Errors[name] = reason or "invalid value"
                else
                    local entry: Payload = { owner = control, value = canonical, name = name }
                    local meta = extras[name]
                    if meta ~= nil then
                        if type(meta) ~= "table" then
                            report.Errors[name] = "invalid flag metadata"
                        elseif control._kind == "ColorPicker" and meta.Alpha ~= nil then
                            if not U.finite(meta.Alpha) or meta.Alpha < 0 or meta.Alpha > 1 then
                                report.Errors[name] = "invalid alpha"
                            else
                                entry.alpha = meta.Alpha
                            end
                        elseif control._kind == "Keybind" and meta.Mode ~= nil then
                            if type(meta.Mode) ~= "string" or not modes[meta.Mode] then
                                report.Errors[name] = "invalid keybind mode"
                            else
                                entry.mode = meta.Mode
                            end
                        elseif (control._kind == "Toggle" or control._kind == "Checkbox") and meta.Key ~= nil then
                            local validEncoding, key = U.decode(meta.Key, 0)
                            local keyOK, button = U.key(key)
                            if not validEncoding or not keyOK then
                                report.Errors[name] = "invalid toggle key"
                            elseif meta.Mode ~= nil and meta.Mode ~= "Toggle" and meta.Mode ~= "Hold" then
                                report.Errors[name] = "invalid toggle key mode"
                            else
                                entry.setKey, entry.key, entry.toggleMode = true, button, meta.Mode
                            end
                        end
                    end
                    if not report.Errors[name] then
                        table.insert(staged, entry)
                    end
                end
            else
                report.Errors[name] = "invalid encoded value"
            end
        end
    end
    if c.Atomic ~= false and next(report.Errors) then
        return false, report
    end
    local changes = {}
    for _, e in staged do
        local owner = e.owner
        if self._dead then
            break
        end
        if not owner._dead and self._flags[e.name] == owner then
            local previous, oldAlpha, oldMode, oldKey = owner._value, owner._alpha, owner._mode, owner._key
            local _, changed = owner:_commit(e.value, true, true)
            if e.alpha ~= nil then
                owner:SetAlpha(e.alpha, true)
            end
            if e.mode ~= nil and e.mode ~= owner._mode then
                owner._mode = e.mode
                owner:_activeSet(e.mode == "Always" and owner._enabled and not owner:_isDisabled(), true)
                owner:_bindRender()
            end
            if e.setKey then
                owner:SetKeybind(e.key)
            end
            if e.toggleMode then
                owner:SetKeybindMode(e.toggleMode)
            end
            report.Applied += 1
            if changed or oldAlpha ~= owner._alpha or oldMode ~= owner._mode or oldKey ~= owner._key then
                report.Changed += 1
                table.insert(changes, {
                    owner = owner,
                    old = previous,
                    alpha = oldAlpha,
                    valueChanged = changed or oldAlpha ~= owner._alpha,
                })
            end
        end
    end
    if c.Silent == false then
        for _, change in changes do
            local owner = change.owner
            if not owner._dead and change.valueChanged then
                owner:_emitChange(owner._value, change.old, change.alpha)
            end
        end
    end
    return next(report.Errors) == nil, report
end

-- Always-present JetZ system settings. It is intentionally a real final Tab so keyboard,
-- gamepad, responsive layout and navigation all use the same paths as consumer content.
function P.Window:AddSettings(options: any)
    local c = U.cfg(options)
    if self._settingsSurface and not self._settingsSurface._dead then
        return self._settingsSurface
    end

    local tab = self._settingsTab
    if not tab or tab._dead then
        tab = self:AddTab({
            Name = U.str(c.Name, "Settings"),
            Icon = c.Icon or "settings",
            Order = 2147483647,
            _SystemSettings = true,
        })
        self._settingsTab = tab
    end

    local general = tab:AddSubTab({ Name = "General", Icon = "filter", Order = 1 })
    local configs = tab:AddSubTab({ Name = "Configs", Icon = "save", Order = 2 })
    local appearance = tab:AddSubTab({ Name = "Appearance", Icon = "palette", Order = 3 })
    local community = tab:AddSubTab({ Name = "Community", Icon = "users", Order = 4 })
    local about = tab:AddSubTab({ Name = "About", Icon = "info", Order = 5 })

    local prefix = U.str(c.FlagPrefix, "ui.")
    local storeURL = U.str(c.StoreURL, self._premiumURL)
    self._premiumURL = storeURL
    local discordURL = U.str(c.DiscordURL, "https://dsc.gg/plak")
    local lifetimePrice = U.str(c.LifetimePrice, "$12")
    local monthlyPrice = U.str(c.MonthlyPrice, "$5")

    local function flag(k: string): string?
        return if prefix ~= "" then prefix .. k else nil
    end
    local function attach(key: string, n: any, apply: any)
        self._settings[key] = n
        n._effect = function(v: any)
            if self._reflecting ~= key then
                apply(v)
            end
        end
        n._life:Give(function()
            if self._settings[key] == n then
                self._settings[key] = nil
            end
        end)
        -- AddSettings is constructed before consumer tabs. If autoload hydrated this
        -- control during U.ready(), replay the internal effect once now that it exists.
        apply(n:GetValue())
        return n
    end
    local function bindLocale(callback: any)
        table.insert(self._localeBindings, callback)
        callback()
    end
    local function section(page: any, name: string, description: string?)
        return page:AddSection({
            Name = name,
            Description = description,
            Collapsible = false,
            ShowHeading = true,
        })
    end

    -- General -----------------------------------------------------------------
    local interface = section(general, "Interface", "Window behavior and everyday controls.")

    attach("sidebar", interface:AddToggle({
        Name = "Show sidebar",
        Flag = flag("sidebar"),
        Default = self._sidebarVisible,
        Tooltip = "Show or hide the persistent desktop navigation rail.",
    }), function(v: boolean)
        self:SetSidebarVisible(v)
    end)

    attach("scale", interface:AddSlider({
        Name = "UI scale",
        Flag = flag("scale"),
        Default = self._scale,
        Min = D.MinScale,
        Max = D.MaxScale,
        Increment = 0.01,
        Format = function(v: number)
            return tostring(math.round(v * 100)) .. "%"
        end,
    }), function(v: number)
        self:SetScale(v)
    end)

    attach("speed", interface:AddSlider({
        Name = "Animation speed",
        Flag = flag("speed"),
        Default = self._speed,
        Min = 0,
        Max = 4,
        Increment = 0.05,
        Tooltip = "0 disables transitions while preserving state changes.",
    }), function(v: number)
        self:SetAnimationSpeed(v)
    end)

    local behavior = section(general, "Behavior", "Shortcuts, visibility and optional visual effects.")
    attach("hideEnabled", behavior:AddToggle({
        Name = "Window shortcut",
        Flag = flag("hideEnabled"),
        Default = self._hideKeyEnabled,
        Tooltip = "Allow the hide/show key to toggle this window.",
    }), function(v: boolean)
        self:SetHideKeyEnabled(v)
    end)

    local hideSettings = self._settings.hideEnabled:AddSettings({ Mode = "Disable" })
    local keyControl = hideSettings:AddKeybind({
        Name = "Shortcut key",
        Flag = flag("hideKey"),
        Default = self._hideKey,
    })
    local internalKeyEffect = keyControl._effect
    attach("hideKey", keyControl, function(v: any)
        if internalKeyEffect then
            internalKeyEffect(v)
        end
        self:SetHideKey(v)
    end)

    attach("watermark", behavior:AddToggle({
        Name = "Watermark",
        Flag = flag("watermark"),
        Default = self._watermark ~= nil and self._watermark._visible,
    }), function(v: boolean)
        self:SetWatermark(v)
    end)

    local particles = attach("particles", behavior:AddToggle({
        Name = "Ambient particles",
        Flag = flag("particles"),
        Default = self._particleEnabled,
    }), function(v: boolean)
        self:SetParticles(v)
    end)
    local particleSettings = particles:AddSettings({ Mode = "Disable" })
    attach("particleMode", particleSettings:AddDropdown({
        Name = "Particle style",
        Flag = flag("particleMode"),
        Values = { "Disabled", "Float", "Twinkle" },
        Default = self:GetParticleMode(),
        RequireSelection = true,
    }), function(v: string)
        self:SetParticleMode(v)
    end)
    attach("particleCount", particleSettings:AddSlider({
        Name = "Particle count",
        Flag = flag("particleCount"),
        Default = self._particleCount,
        Min = 0,
        Max = D.ParticleMax,
        Tooltip = "Touch devices automatically use a lower safe cap.",
    }), function(v: number)
        self:SetParticleCount(v)
    end)


    -- Configs ------------------------------------------------------------------
    local manager = self._profileManager
    local profiles = section(configs, "Profiles", "Save, load and organize complete JetZ configurations.")

    local profileStatus = profiles:AddStatus({
        Name = "Profile status",
        Text = "Active: " .. (manager.activeProfile or "None"),
        Severity = manager.available and "Success" or "Warning",
        ColorToken = "Accent",
    })
    local autoloadStatus = profiles:AddStatus({
        Name = "Startup",
        Text = "Autoload: Off",
        Severity = manager.available and "Info" or "Warning",
        ColorToken = "Accent",
    })

    local names = manager:Names()
    local profileSelect = profiles:AddDropdown({
        Name = "Saved config",
        Values = #names > 0 and names or { "No profiles" },
        Default = manager.activeProfile or names[1] or "No profiles",
        RequireSelection = true,
    })
    local profileName = profiles:AddInput({
        Name = "Config name",
        Placeholder = "My Config",
        MaxLength = 64,
        Default = "",
    })

    local function selectedProfile(): string?
        local value = profileSelect:GetValue()
        return if type(value) == "string" and value ~= "No profiles" then value else nil
    end
    local function desiredName(): string?
        return U.profileName(profileName:GetValue()) or selectedProfile()
    end
    local function result(title: string, ok: boolean, reason: any?)
        self:Notify({
            Title = title,
            Description = if ok then nil else tostring(reason or "Operation failed"),
            Severity = if ok then "Success" else "Warning",
            Duration = 3,
        })
    end
    local function refresh(selectName: string?)
        local list = manager:Names()
        profileSelect:SetValues(#list > 0 and list or { "No profiles" }, true)
        local target = selectName or manager.activeProfile
        if target and table.find(list, target) then profileSelect:SetValue(target, true) end
        manager:RefreshUI()
    end

    local primary = profiles:AddInlineGroup({ Columns = 3, Gap = 8, MinimumWidth = 106 })
    primary:AddButton({
        Name = "Create config", Text = "Create", Icon = "folder-plus",
        Callback = function()
            local name = U.profileName(profileName:GetValue())
            if not name then result("Config not created", false, "Enter a valid config name") return end
            local ok, why = self:CreateProfile(name)
            result(ok and "Config created" or "Create failed", ok, why)
            if ok then profileName:SetValue("", true) refresh(name) end
        end,
    })
    primary:AddButton({
        Name = "Save config", Text = "Save", Icon = "save",
        Callback = function()
            local name = desiredName()
            if not name then result("Nothing to save", false, "Select a config or enter a name") return end
            local ok, why = self:SaveProfile(name)
            result(ok and "Config saved" or "Save failed", ok, why)
            if ok then refresh(name) end
        end,
    })
    primary:AddButton({
        Name = "Load config", Text = "Load", Icon = "download-cloud",
        Callback = function()
            local name = selectedProfile()
            if not name then result("Nothing to load", false, "Select a saved config") return end
            local ok, why = self:LoadProfile(name, false)
            result(ok and "Config loaded" or "Load failed", ok, why)
            if ok then refresh(name) end
        end,
    })

    local manage = section(configs, "Manage", "Rename, duplicate, delete or rescan configs.")
    local manageActions = manage:AddInlineGroup({ Columns = 4, Gap = 8, MinimumWidth = 92 })
    manageActions:AddButton({
        Name = "Rename config", Text = "Rename", Icon = "pencil",
        Callback = function()
            local old, new = selectedProfile(), U.profileName(profileName:GetValue())
            if not old or not new then result("Rename failed", false, "Select a config and enter the new name") return end
            local ok, why = self:RenameProfile(old, new)
            result(ok and "Config renamed" or "Rename failed", ok, why)
            if ok then profileName:SetValue("", true) refresh(new) end
        end,
    })
    manageActions:AddButton({
        Name = "Duplicate config", Text = "Duplicate", Icon = "copy",
        Callback = function()
            local old, new = selectedProfile(), U.profileName(profileName:GetValue())
            if not old or not new then result("Duplicate failed", false, "Select a config and enter the copy name") return end
            local ok, why = self:DuplicateProfile(old, new)
            result(ok and "Config duplicated" or "Duplicate failed", ok, why)
            if ok then profileName:SetValue("", true) refresh(new) end
        end,
    })
    manageActions:AddButton({
        Name = "Delete config", Text = "Delete", Icon = "trash",
        Callback = function()
            local name = selectedProfile()
            if not name then return end
            self:CreateDialog({
                Title = "Delete config?",
                Description = "This permanently deletes \"" .. name .. "\" from local storage.",
                Buttons = {
                    { Text = "Cancel" },
                    {
                        Text = "Delete", Danger = true,
                        Callback = function()
                            local ok, why = self:DeleteProfile(name)
                            result(ok and "Config deleted" or "Delete failed", ok, why)
                            refresh(nil)
                        end,
                    },
                },
            })
        end,
    })
    manageActions:AddButton({
        Name = "Refresh configs", Text = "Refresh", Icon = "refresh-cw",
        Callback = function()
            refresh(selectedProfile())
            self:Notify({ Title = "Configs refreshed", Severity = "Info", Duration = 2 })
        end,
    })

    local startup = section(configs, "Autoload", "Restore one saved config automatically for this game.")
    local autoActions = startup:AddInlineGroup({ Columns = 2, Gap = 8, MinimumWidth = 145 })
    autoActions:AddButton({
        Name = "Set autoload", Text = "Set Autoload", Icon = "play",
        Callback = function()
            local name = selectedProfile()
            if not name then result("Autoload unchanged", false, "Select a saved config") return end
            local ok, why = self:SetAutoload(name)
            result(ok and "Autoload enabled" or "Autoload failed", ok, why)
            manager:RefreshUI()
        end,
    })
    autoActions:AddButton({
        Name = "Disable autoload", Text = "Disable", Icon = "pause",
        Callback = function()
            local ok, why = self:DisableAutoload()
            result(ok and "Autoload disabled" or "Autoload failed", ok, why)
            manager:RefreshUI()
        end,
    })

    local transfer = section(configs, "Import & Export", "Transfer configs using the clipboard or the public profile API.")
    local transferActions = transfer:AddInlineGroup({ Columns = 2, Gap = 8, MinimumWidth = 145 })
    transferActions:AddButton({
        Name = "Export config", Text = "Copy Export", Icon = "upload",
        Callback = function()
            local json, why = self:ExportProfile(selectedProfile())
            if not json then result("Export failed", false, why) return end
            local copied = U.copyText(json)
            result(copied and "Config copied" or "Clipboard unavailable", copied,
                copied and nil or "Use Window:ExportProfile() to retrieve the JSON directly")
        end,
    })
    transferActions:AddButton({
        Name = "Import config", Text = "Import Clipboard", Icon = "download-cloud",
        Callback = function()
            local name, json = U.profileName(profileName:GetValue()), U.readClipboard()
            if not name then result("Import failed", false, "Enter the destination config name first") return end
            if not json then result("Import failed", false, "Clipboard read is unavailable") return end
            local ok, why = self:ImportProfile(name, json, false)
            result(ok and "Config imported" or "Import failed", ok, why)
            if ok then profileName:SetValue("", true) refresh(name) end
        end,
    })

    manager.ui = { Profile = profileSelect, Status = profileStatus, AutoloadStatus = autoloadStatus }
    manager:RefreshUI()

    -- Appearance ---------------------------------------------------------------
    local themes = section(appearance, "Theme", "Choose a preset, then fine-tune accent and contrast.")

    local themeCards: any = nil
    themeCards = themes:AddCustom({
        Name = "Theme presets",
        Height = 122,
        Build = function(ctx: any)
            local host = ctx.Container
            local life = U.scope()
            ctx.Cleanup(life)
            local buttons = {}
            local function makeCard(name: string, index: number)
                local palette = ThemePresets[name]
                local button = U.make("TextButton", host, {
                    Name = name,
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 0,
                    ZIndex = host.ZIndex + 1,
                })
                life:Give(button)
                U.corner(button, 7)
                local stroke = U.make("UIStroke", button, { Thickness = 1, Transparency = 0.08 })
                life:Give(stroke)
                local preview = U.make("Frame", button, {
                    Position = O(10, 10),
                    Size = UDim2.new(1, -20, 0, 55),
                    BackgroundTransparency = 0,
                    BackgroundColor3 = palette.Background,
                    ZIndex = button.ZIndex + 1,
                })
                life:Give(preview)
                U.corner(preview, 5)
                local side = U.make("Frame", preview, {
                    Size = UDim2.new(0, 22, 1, 0),
                    BackgroundTransparency = 0,
                    BackgroundColor3 = palette.Sidebar,
                    ZIndex = preview.ZIndex + 1,
                })
                life:Give(side)
                local row = U.make("Frame", preview, {
                    Position = O(30, 12),
                    Size = UDim2.new(1, -39, 0, 18),
                    BackgroundTransparency = 0,
                    BackgroundColor3 = palette.SurfaceRaised,
                    ZIndex = preview.ZIndex + 1,
                })
                life:Give(row)
                U.corner(row, 3)
                local accent = U.make("Frame", row, {
                    AnchorPoint = V(1, 0.5),
                    Position = UDim2.new(1, -7, 0.5, 0),
                    Size = O(27, 4),
                    BackgroundTransparency = 0,
                    BackgroundColor3 = palette.Accent,
                    ZIndex = row.ZIndex + 1,
                })
                life:Give(accent)
                U.corner(accent, 3)
                local title = U.make("TextLabel", button, {
                    Position = O(10, 72),
                    Size = UDim2.new(1, -34, 0, 22),
                    BackgroundTransparency = 1,
                    Text = name,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = ctx.Theme("Text"),
                    TextSize = 12,
                    FontFace = MEDIUM,
                    ZIndex = button.ZIndex + 2,
                })
                life:Give(title)
                local selected = U.make("TextLabel", button, {
                    AnchorPoint = V(1, 0),
                    Position = UDim2.new(1, -9, 0, 72),
                    Size = O(18, 20),
                    BackgroundTransparency = 1,
                    Text = "✓",
                    TextColor3 = ctx.Theme("Accent"),
                    TextSize = 13,
                    FontFace = BOLD,
                    ZIndex = button.ZIndex + 2,
                })
                life:Give(selected)
                local function render()
                    local active = self:GetThemePreset() == name
                    selected.Visible = active
                    stroke.Color = if active then self._theme._colors.Accent else self._theme._colors.Stroke
                    stroke.Thickness = if active then 2 else 1
                    button.BackgroundColor3 = if active then self._theme._colors.AccentMuted else self._theme._colors.Surface
                    title.TextColor3 = self._theme._colors.Text
                end
                buttons[name] = { Root = button, Render = render }
                life:Give(button.Activated:Connect(function()
                    if not ctx.CanInteract() then
                        return
                    end
                    self:SetThemePreset(name)
                    for _, entry in buttons do
                        entry.Render()
                    end
                end))
                render()
                return button
            end
            for i, name in ThemePresetOrder do
                makeCard(name, i)
            end
            local function layout()
                local width = host.AbsoluteSize.X
                local gap = 8
                local cols = if width >= 520 then 4 elseif width >= 270 then 2 else 1
                local rows = math.ceil(#ThemePresetOrder / cols)
                local cardWidth = math.max(96, (width - gap * (cols - 1)) / cols)
                local cardHeight = if cols == 1 then 100 else 102
                for i, name in ThemePresetOrder do
                    local entry = buttons[name]
                    local col, rowIndex = (i - 1) % cols, math.floor((i - 1) / cols)
                    entry.Root.Position = O(col * (cardWidth + gap), rowIndex * (cardHeight + gap))
                    entry.Root.Size = O(cardWidth, cardHeight)
                end
                local height = rows * cardHeight + math.max(0, rows - 1) * gap
                if themeCards and not themeCards._dead and math.abs(themeCards:GetHeight() - height) > 1 then
                    themeCards:SetHeight(height)
                end
            end
            life:Give(host:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
            layout()
            return function()
                life:Destroy()
            end
        end,
    })

    attach("accent", themes:AddColorPicker({
        Name = "Accent color",
        Flag = flag("accent"),
        Default = self:GetAccent(),
        ShowAlpha = false,
    }), function(v: Color3)
        self:SetAccent(v)
    end)

    attach("contrast", themes:AddSlider({
        Name = "Contrast",
        Flag = flag("contrast"),
        Default = self:GetContrast(),
        Min = 0.45,
        Max = 2,
        Increment = 0.05,
    }), function(v: number)
        self:SetContrast(v)
    end)

    local language = section(appearance, "Language", "Language preference for JetZ system surfaces.")
    language:AddSegmentedControl({
        Name = "Interface language",
        Values = self:GetLanguages(),
        Default = self:GetLanguage(),
        Callback = function(v: string)
            self:SetLanguage(v)
        end,
    })
    language:AddParagraph({
        Name = "Localization",
        Description = "This selector is reserved for JetZ system surfaces; labels supplied by scripts remain exactly as authored.",
    })

    -- Community ---------------------------------------------------------------
    local premium = section(community, "JetZ Premium", "Premium access and the JetZ community.")

    local function promotionCard(parent: Instance, life: any, x: number, width: number, height: number, titleText: string, price: string, caption: string, primary: boolean, callback: () -> ())
        local card = U.make("Frame", parent, {
            Position = O(x, 0),
            Size = O(width, height),
            BackgroundTransparency = 0,
            ZIndex = parent.ZIndex + 1,
        })
        life:Give(card)
        U.corner(card, 8)
        local fill = U.paint(self, life, card, "BackgroundColor3", if primary then "SurfaceRaised" else "Surface")
        local edge = U.make("UIStroke", card, { Thickness = if primary then 2 else 1, Transparency = 0.08 })
        life:Give(edge)
        U.paint(self, life, edge, "Color", if primary then "Accent" else "Stroke")
        local crown = U.icon(self, life, card, if primary then "crown" else "calendar", 18, "Accent", {
            Position = O(15, 14), Size = O(20, 20),
        })
        local title = U.text(self, life, card, "Control", self:Translate(titleText), "Text", {
            Position = O(43, 10), Size = UDim2.new(1, -55, 0, 25),
        })
        title.FontFace = BOLD
        local priceLabel = U.text(self, life, card, "Brand", price, "Text", {
            Position = O(15, 42), Size = UDim2.new(1, -30, 0, 28),
        })
        priceLabel.FontFace = BOLD
        local body = U.text(self, life, card, "Muted", caption, "TextSecondary", {
            Position = O(15, 76), Size = UDim2.new(1, -30, 0, height - 132),
            TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
        })
        local action = U.make("TextButton", card, {
            AnchorPoint = V(0, 1),
            Position = UDim2.new(0, 15, 1, -14),
            Size = UDim2.new(1, -30, 0, 38),
            Text = self:Translate(if primary then "Get Lifetime" else "Get Monthly"),
            TextSize = 12,
            FontFace = MEDIUM,
            AutoButtonColor = false,
            BackgroundTransparency = 0,
            ZIndex = card.ZIndex + 2,
        })
        life:Give(action)
        U.corner(action, 5)
        U.paint(self, life, action, "BackgroundColor3", if primary then "Accent" else "SurfaceRaised")
        U.paint(self, life, action, "TextColor3", if primary then "Background" else "Text")
        bindLocale(function()
            if not card.Parent then return end
            title.Text = self:Translate(titleText)
            action.Text = self:Translate(if primary then "Get Lifetime" else "Get Monthly")
            local translated = {}
            for line in caption:gmatch("[^\n]+") do
                table.insert(translated, self:Translate(line))
            end
            body.Text = table.concat(translated, "\n")
        end)
        life:Give(action.Activated:Connect(callback))
        return card
    end

    local premiumCards: any = nil
    premiumCards = premium:AddCustom({
        Name = "Plans",
        Height = 222,
        Build = function(ctx: any)
            local host = ctx.Container
            local life = U.scope()
            ctx.Cleanup(life)
            local lifetime, monthly
            local function copyStore()
                local clipboard = U.resolveExecutor("setclipboard")
                local ok = type(clipboard) == "function" and pcall(clipboard, storeURL)
                self:Notify({
                    Title = ok and "Purchase link copied" or "Clipboard unavailable",
                    Description = ok and storeURL or "Copy the store URL manually: " .. storeURL,
                    Severity = ok and "Success" or "Warning",
                    Duration = 3,
                })
            end
            lifetime = promotionCard(host, life, 0, 100, 210, "Lifetime", lifetimePrice .. "  one-time",
                "All premium features\nLifetime updates\nPriority support\nSupport future development", true, copyStore)
            monthly = promotionCard(host, life, 0, 100, 210, "Monthly", monthlyPrice .. "  / month",
                "All premium features\nContinuous updates\nPriority support", false, copyStore)
            local function layout()
                local width = host.AbsoluteSize.X
                local gap = 10
                local stacked = width < 430
                local cardWidth = if stacked then width else (width - gap) / 2
                lifetime.Position = O(0, 0)
                lifetime.Size = O(cardWidth, 210)
                monthly.Position = O(if stacked then 0 else cardWidth + gap, if stacked then 220 else 0)
                monthly.Size = O(cardWidth, 210)
                local height = if stacked then 430 else 210
                if premiumCards and not premiumCards._dead and math.abs(premiumCards:GetHeight() - height) > 1 then
                    premiumCards:SetHeight(height)
                end
            end
            life:Give(host:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
            layout()
            return function()
                life:Destroy()
            end
        end,
    })

    local discord = section(community, "Community", "Updates, support and feedback.")
    local discordCard: any = nil
    discordCard = discord:AddCustom({
        Name = "Discord",
        Height = 150,
        Build = function(ctx: any)
            local host = ctx.Container
            local life = U.scope()
            ctx.Cleanup(life)
            local card = U.make("Frame", host, {
                Size = S(1, 1),
                BackgroundTransparency = 0,
                ZIndex = host.ZIndex + 1,
            })
            life:Give(card)
            U.corner(card, 8)
            U.paint(self, life, card, "BackgroundColor3", "Surface")
            local stroke = U.make("UIStroke", card, { Thickness = 1, Transparency = 0.08 })
            life:Give(stroke)
            U.paint(self, life, stroke, "Color", "Stroke")
            U.icon(self, life, card, "users", 24, "Accent", { Position = O(16, 16), Size = O(28, 28) })
            local title = U.text(self, life, card, "Brand", self:Translate("Join the JetZ Community"), "Text", {
                Position = O(54, 10), Size = UDim2.new(1, -70, 0, 28),
            })
            title.FontFace = BOLD
            local discordBody = U.text(self, life, card, "Muted", self:Translate("Share feedback, get support, see updates, and connect with other JetZ users."), "TextSecondary", {
                Position = O(16, 50), Size = UDim2.new(1, -32, 0, 36),
                TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
            })
            local join = U.make("TextButton", card, {
                AnchorPoint = V(0, 1),
                Position = UDim2.new(0, 16, 1, -14),
                Size = UDim2.new(1, -32, 0, 38),
                BackgroundTransparency = 0,
                Text = self:Translate("Join Community"),
                TextSize = 12,
                FontFace = MEDIUM,
                AutoButtonColor = false,
                ZIndex = card.ZIndex + 2,
            })
            life:Give(join)
            U.corner(join, 5)
            U.paint(self, life, join, "BackgroundColor3", "AccentMuted")
            U.paint(self, life, join, "TextColor3", "Text")
            U.icon(self, life, join, "message-circle", 14, "Accent", {
                AnchorPoint = V(1, 0.5),
                Position = UDim2.new(1, -13, 0.5, 0),
                Size = O(18, 18),
                ZIndex = join.ZIndex + 1,
            })
            bindLocale(function()
                if not join.Parent then return end
                title.Text = self:Translate("Join the JetZ Community")
                discordBody.Text = self:Translate("Share feedback, get support, see updates, and connect with other JetZ users.")
                join.Text = self:Translate("Join Community")
            end)
            life:Give(join.Activated:Connect(function()
                local clipboard = U.resolveExecutor("setclipboard")
                local ok = type(clipboard) == "function" and pcall(clipboard, discordURL)
                self:Notify({
                    Title = ok and "Discord link copied" or "Clipboard unavailable",
                    Description = ok and discordURL or "Join manually at " .. discordURL,
                    Severity = ok and "Success" or "Warning",
                    Duration = 3,
                })
            end))
            return function()
                life:Destroy()
            end
        end,
    })

    -- About -------------------------------------------------------------------
    local info = section(about, "About JetZ", "Library information and safe recovery actions.")
    info:AddParagraph({
        Name = "JetZ UI",
        Description = "A responsive Roblox UI framework with keyboard, touch, gamepad, theming, dependencies, configs and custom surfaces.",
    })
    info:AddLabel({ Name = "Version", Text = U.str(Library.Version, "Current") })
    info:AddButton({
        Name = "Center window",
        Text = "Center",
        Icon = "locate-fixed",
        Callback = function()
            self:Center()
        end,
    })
    info:AddButton({
        Name = "Reset appearance",
        Text = "Reset",
        Icon = "rotate-ccw",
        Callback = function()
            self:SetThemePreset("JetZ Dark")
            self:SetContrast(1)
            self:SetScale(1)
            if self._settings.accent and not self._settings.accent._dead then
                self._settings.accent:SetValue(self:GetAccent(), true)
            end
            if self._settings.contrast and not self._settings.contrast._dead then
                self._settings.contrast:SetValue(1, true)
            end
            if self._settings.scale and not self._settings.scale._dead then
                self._settings.scale:SetValue(1, true)
            end
        end,
    })

    self._settingsSurface = interface
    interface._life:Give(function()
        if self._settingsSurface == interface then
            self._settingsSurface = nil
        end
    end)

    -- Settings is a system destination, never the initial destination when consumer tabs exist.
    if self._wantedTab == nil then
        self._wantedTab = tab
    end
    self:_refreshNav(false)
    self:_refreshSystemLanguage()
    return interface
end

function Library:CreateSignal(): any
    return U.signal(nil, "Custom")
end

function Library:RegisterIcon(name: string, spec: any)
    if type(name) ~= "string" or name == "" then
        return U.issue(nil, "RegisterIcon", "expected a nonempty name")
    end
    local resolved = U.iconSpec(spec)
    if not resolved.Image then
        return U.issue(nil, "RegisterIcon", "expected image ID or atlas descriptor")
    end
    imageIcons[name] = table.clone(resolved)
    return true
end
function Library:UnregisterIcon(name: string)
    if type(name) ~= "string" then
        return false
    end
    imageIcons[name] = nil
    return true
end

local function demoOverride(kind: string)
    local mode, saved: any = "Toggle", nil
    return function(menu: any, control: any)
        menu:AddLabel({ Name = "Select", Text = "Select", Height = 23 })
        menu:AddSegmentedControl({
            Name = "Mode",
            HideLabel = true,
            Values = { "Toggle", "Hold" },
            Default = mode,
            Callback = function(v: string)
                mode = v
                if kind == "boolean" then
                    control:SetKeybindMode(v)
                end
            end,
        })
        if kind == "range" then
            local min, max = control:GetRange()
            menu:AddRangeSlider({
                Name = "Value",
                Min = min,
                Max = max,
                Default = saved or control:GetValue(),
                Suffix = control:GetSuffix(),
                Callback = function(v: Range)
                    saved = v
                end,
            })
        elseif kind == "number" then
            local min, max = control:GetRange()
            menu:AddSlider({
                Name = "Value",
                Min = min,
                Max = max,
                Default = saved or control:GetValue(),
                Suffix = control:GetSuffix(),
                Callback = function(v: number)
                    saved = v
                end,
            })
        elseif kind == "dropdown" then
            menu:AddDropdown({
                Name = "Value",
                Values = control:GetValues(),
                Default = saved or control:GetValue(),
                Callback = function(v: Option)
                    saved = v
                end,
            })
        else
            menu:AddKeybind({
                Name = "Key",
                Default = control:GetKeybind(),
                Callback = function(v: Key)
                    control:SetKeybind(v)
                end,
            })
            menu:AddCheckbox({
                Name = "Value",
                Default = control:GetValue(),
                Callback = function(v: boolean)
                    control:SetValue(v)
                end,
            })
        end
    end
end

function Library:CreateReferenceDemo(options: WindowOptions?)
    if options ~= nil and type(options) ~= "table" then
        return U.issue(nil, "CreateReferenceDemo", "expected window options")
    end
    local config: any = table.clone(options or {})
    config.Title, config.Version = config.Title or "CHRONIC", config.Version or "Release 0.4"
    config.Id = config.Id or "Reference"
    if config.ParticleCount == nil then
        config.ParticleCount = 0
    end
    local w: any = self:CreateWindow(config)
    if type(w) ~= "table" then
        return w
    end
    local assistance = w:AddTab({ Name = "Assistance", Icon = "cross" })
    local aimbot = assistance:AddSubTab("Aimbot")
    assistance:AddSubTab("Assist")
    assistance:AddSubTab("Others")
    local a = aimbot:AddSection({ ShowHeading = false })
    a:AddCheckbox({
        Name = "Enabled aimbot",
        Height = 60,
        ContentOffset = -3,
        Default = false,
        Keybind = Enum.KeyCode.G,
        Flag = "a.enabled",
        ContextBuild = demoOverride("boolean"),
    })
    local pair = a:AddInlineGroup({ Columns = 2 })
    pair:AddSlider({
        Name = "Field of view",
        Max = 180,
        Default = 180,
        Suffix = "°",
        Flag = "a.field",
        ContextBuild = demoOverride("number"),
    })
    pair:AddSlider({
        Name = "Min. Damage",
        Default = 100,
        Suffix = "%",
        Flag = "a.damage",
        ContextBuild = demoOverride("number"),
    })
    a:AddDropdown({
        Name = "Accuracy boost",
        Values = { "Disabled", "Enabled", "Auto" },
        Default = "Disabled",
        Flag = "a.accuracy",
    })
    a:AddCheckbox({
        Name = "Automatic penetration",
        Default = true,
        ShowKeybind = true,
        Flag = "a.penetrate",
        ContextBuild = demoOverride("boolean"),
    })
    a:AddRangeSlider({
        Name = "Minimum hit chance",
        Default = { Min = 0, Max = 100 },
        Suffix = "%",
        Flag = "a.chance",
        ContextBuild = demoOverride("range"),
    })
    a:AddCheckbox({
        Name = "Reduce aim step",
        Default = false,
        ShowKeybind = true,
        Flag = "a.step",
        ContextBuild = demoOverride("boolean"),
    })
    a:AddDropdown({
        Name = "Automatic penetration",
        Values = { "Low", "Medium", "High" },
        Default = "Medium",
        Flag = "a.level",
    })
    a:AddButton({
        Name = "BUTTON",
        Style = "Tint",
        Callback = function()
            w:Notify({ Title = "Action preview", Description = "UI preview only", Duration = 2.5 })
        end,
    })
    a:AddInput({ Name = "TEXT", Flag = "a.text", MaxLength = 72 })

    local visuals = w:AddTab({ Name = "Visuals", Icon = "lens" })
    local players = visuals:AddSubTab("Players"):AddSection({ ShowHeading = false })
    visuals:AddSubTab("Weapons")
    visuals:AddSubTab("Effects")
    visuals:AddSubTab("Models")
    players:AddDropdown({
        Name = "Activation type",
        Values = { "Default", "Manual", "Auto" },
        Default = "Auto",
        Flag = "v.mode",
        ContextBuild = demoOverride("dropdown"),
    })
    local teammates = players:AddInlineGroup({ MinimumWidth = 115, Gap = 12 })
    teammates:AddCheckbox({ Name = "Teammates", Default = true, Flag = "v.team" })
    teammates:AddMultiDropdown({
        Name = "Teammate details",
        HideLabel = true,
        Values = { "Health bar", "Name", "Other" },
        Default = { "Health bar", "Name", "Other" },
        Flag = "v.details",
    })
    local box = players:AddInlineGroup({ MinimumWidth = 115, Gap = 12 })
    box:AddCheckbox({ Name = "Bounding box", Default = true, Flag = "v.box" })
    box:AddColorPicker({
        Name = "Box color",
        HideLabel = true,
        Default = Color3.fromRGB(219, 216, 131),
        Flag = "v.boxColor",
    })
    players:AddSlider({
        Name = "Transparent walls",
        Default = 100,
        Suffix = "%",
        Flag = "v.opacity",
        ContextBuild = demoOverride("number"),
    })
    players:AddCheckbox({
        Name = "Remove flashbang effect",
        ShowKeybind = true,
        Flag = "v.flash",
        ContextBuild = demoOverride("boolean"),
    })
    players:AddCheckbox({
        Name = "Disable post processing",
        Default = true,
        ShowKeybind = true,
        Flag = "v.post",
        ContextBuild = demoOverride("boolean"),
    })
    players:AddDropdown({
        Name = "Visual recoil adjustment",
        Values = { "Disabled", "Enabled", "Auto" },
        Default = "Auto",
        Flag = "v.recoil",
    })

    local misc = w:AddTab({ Name = "Misc", Icon = "layers" })
    local m = misc:AddSubTab("Miscellaneous"):AddSection({ ShowHeading = false })
    misc:AddSubTab("Settings")
    m:AddSlider({ Name = "Override FOV", Min = 20, Default = 100, Increment = 0.1, Flag = "m.fov" })
    m:AddCheckbox({
        Name = "Bunny hop",
        Default = true,
        ShowKeybind = true,
        Flag = "m.hop",
        ContextBuild = demoOverride("boolean"),
    })
    local pair2 = m:AddInlineGroup({ MinimumWidth = 120, Gap = 12 })
    pair2:AddCheckbox({ Name = "Air strafe", Default = true, Flag = "m.strafe" })
    pair2:AddDropdown({
        Name = "Air strafe mode",
        HideLabel = true,
        Values = { "Disabled", "Manual", "Auto" },
        Default = "Disabled",
        Flag = "m.strafeMode",
    })
    local pair3 = m:AddInlineGroup()
    pair3:AddSlider({
        Name = "Air strafe smoothing",
        Default = 100,
        Suffix = "%",
        Flag = "m.smooth",
        ContextBuild = demoOverride("number"),
    })
    pair3:AddSlider({
        Name = "Auto. Weapons",
        Default = 100,
        Suffix = " [MS]",
        Flag = "m.time",
        ContextBuild = demoOverride("number"),
    })
    m:AddCheckbox({
        Name = "Jump at edge",
        Default = true,
        ShowKeybind = true,
        Flag = "m.edge",
        ContextBuild = demoOverride("boolean"),
    })
    m:AddCheckbox({
        Name = "Reveal competitive ranks",
        Default = true,
        ShowKeybind = true,
        Flag = "m.rank",
        ContextBuild = demoOverride("boolean"),
    })
    m:AddSlider({ Name = "Reveal timeline size", Default = 100, Increment = 0.001, Flag = "m.timeline" })

    local cfg = w:AddTab({ Name = "Config", Icon = "box" }):AddSubTab("Config"):AddSection({ ShowHeading = false })
    local saved: any = nil
    local function removeSnapshot(row: any)
        w:CreateDialog({
            Title = "Remove snapshot?",
            Description = "Clears the demo's in-memory copy.",
            Buttons = {
                { Text = "Cancel" },
                {
                    Text = "Remove",
                    Danger = true,
                    Callback = function()
                        saved = nil
                        row:SetVisible(false)
                    end,
                },
            },
        })
    end
    cfg:AddContextMenu({
        Name = "New Config 4",
        Description = "A snapshot of this demo's preferences.",
        Icon = "edit",
        QuickAction = { Icon = "trash", Danger = true, Callback = removeSnapshot },
        Items = {
            {
                Name = "Save snapshot",
                Callback = function()
                    saved = w:ExportConfig()
                    w:Notify({
                        Title = "Snapshot saved",
                        Description = "Kept in memory for this demo.",
                        Severity = "Success",
                    })
                end,
            },
            {
                Name = "Load snapshot",
                Callback = function()
                    if saved then
                        local ok = w:ImportConfig(saved)
                        w:Notify({
                            Title = if ok then "Snapshot loaded" else "Snapshot not applied",
                            Severity = if ok then "Success" else "Warning",
                        })
                    else
                        w:Notify({
                            Title = "No snapshot yet",
                            Description = "Save a snapshot before loading.",
                            Severity = "Info",
                        })
                    end
                end,
            },
            { Name = "Remove snapshot", Callback = removeSnapshot },
        },
    })
    local settings = w:AddTab({ Name = "Settings", Icon = "gear" })
    w:AddSettings({ Tab = settings, SubTab = "GUI" })
    settings:AddSubTab("Other")
    aimbot:Select()
    return w
end

-- Guard all public prototype entries at a single boundary. Private teardown methods
-- intentionally remain callable while a controller is destroying its own scopes.
do
    for _, proto in P do
        if proto ~= P.Scope and proto ~= P.Signal and proto ~= P.Theme then
            for name, method in proto do
                if
                    type(name) == "string"
                    and not string.match(name, "^_")
                    and type(method) == "function"
                    and name ~= "Destroy"
                    and name ~= "IsDestroyed"
                then
                    proto[name] = function(self: any, ...: any)
                        if self._dead then
                            return nil, "destroyed controller"
                        end
                        return method(self, ...)
                    end
                end
            end
        end
    end
end

return Library
