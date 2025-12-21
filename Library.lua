local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local getgenv = getgenv or function()
    return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}
local Paragraphs = {}
local Tooltips = {}

local NeonAccentColor = Color3.fromHex("#813dd4")

local BaseURL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local CustomImageManager = {}
local CustomImageManagerAssets = {
    TransparencyTexture = {
        RobloxId = 139785960036434,
        Path = "Obsidian/assets/TransparencyTexture.png",
        URL = BaseURL .. "assets/TransparencyTexture.png",

        Id = nil,
    },

    SaturationMap = {
        RobloxId = 4155801252,
        Path = "Obsidian/assets/SaturationMap.png",
        URL = BaseURL .. "assets/SaturationMap.png",

        Id = nil,
    }
}
do
    local function RecursiveCreatePath(Path: string, IsFile: boolean?)
        if not isfolder or not makefolder then
            return
        end

        local Segments = Path:split("/")
        local TraversedPath = ""

        if IsFile then
            table.remove(Segments, #Segments)
        end

        for _, Segment in ipairs(Segments) do
            if not isfolder(TraversedPath .. Segment) then
                makefolder(TraversedPath .. Segment)
            end

            TraversedPath = TraversedPath .. Segment .. "/"
        end

        return TraversedPath
    end

    function CustomImageManager.AddAsset(AssetName: string, RobloxAssetId: number, URL: string, ForceRedownload: boolean?)
        if CustomImageManagerAssets[AssetName] ~= nil then
            error(string.format("Asset %q already exists", AssetName))
        end

        assert(typeof(RobloxAssetId) == "number", "RobloxAssetId must be a number")

        CustomImageManagerAssets[AssetName] = {
            RobloxId = RobloxAssetId,
            Path = string.format("Obsidian/custom_assets/%s", AssetName),
            URL = URL,

            Id = nil,
        }

        CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
    end

    function CustomImageManager.GetAsset(AssetName: string)
        if not CustomImageManagerAssets[AssetName] then
            return nil
        end

        local AssetData = CustomImageManagerAssets[AssetName]
        if AssetData.Id then
            return AssetData.Id
        end

        local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)

        if getcustomasset then
            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID then
                AssetID = NewID
            end
        end

        AssetData.Id = AssetID
        return AssetID
    end

    function CustomImageManager.DownloadAsset(AssetName: string, ForceRedownload: boolean?)
        if not getcustomasset or not writefile or not isfile then
            return false, "missing functions"
        end

        local AssetData = CustomImageManagerAssets[AssetName]

        RecursiveCreatePath(AssetData.Path, true)

        if ForceRedownload ~= true and isfile(AssetData.Path) then
            return true, nil
        end

        local success, errorMessage = pcall(function()
            writefile(AssetData.Path, game:HttpGet(AssetData.URL))
        end)

        return success, errorMessage
    end

    for AssetName, _ in CustomImageManagerAssets do
        CustomImageManager.DownloadAsset(AssetName)
    end
end

local Library = {
    LocalPlayer = LocalPlayer,
    DevicePlatform = nil,
    IsMobile = false,
    IsRobloxFocused = true,

    ScreenGui = nil,

    SearchText = "",
    Searching = false,
    GlobalSearch = false,
    LastSearchTab = nil,

    ActiveTab = nil,
    Tabs = {},
    DependencyBoxes = {},

    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},

    Notifications = {},

    ToggleKeybind = Enum.KeyCode.RightControl,
    TweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    NotifyTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    HoverTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
    ToggleTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    FadeTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),

    Toggled = false,
    Unloaded = false,

    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,

    NotifySide = "Right",
    ShowCustomCursor = true,
    ForceCheckbox = false,
    ShowToggleFrameInKeybinds = true,
    NotifyOnError = false,

    CantDragForced = false,

    Signals = {},
    UnloadSignals = {},

    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 4,

    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(13, 13, 18),
        MainColor = Color3.fromRGB(22, 22, 32),
        AccentColor = Color3.fromHex("#813dd4"),
        OutlineColor = Color3.fromRGB(42, 42, 55),
        FontColor = Color3.new(1, 1, 1),
        Font = Font.fromEnum(Enum.Font.Code),

        Red = Color3.fromRGB(255, 50, 50),
        Dark = Color3.new(0, 0, 0),
        White = Color3.new(1, 1, 1),

        -- Secondary accent (darker purple)
        AccentDark = Color3.fromHex("#5a1fa3"),

        -- Highlight/Glow effect
        Highlight = true,
        HighlightColor = Color3.fromHex("#813dd4"),
    },

    Registry = {},
    DPIRegistry = {},
    
    ImageManager = CustomImageManager,
}

if RunService:IsStudio() then
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        Library.IsMobile = true
        Library.MinSize = Vector2.new(480, 240)
    else
        Library.IsMobile = false
        Library.MinSize = Vector2.new(480, 360)
    end
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
    Library.MinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

local Templates = {
    --// UI \\-
    Frame = {
        BorderSizePixel = 0,
    },
    ImageLabel = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    },
    ImageButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
    },
    ScrollingFrame = {
        BorderSizePixel = 0,
    },
    TextLabel = {
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextBox = {
        BorderSizePixel = 0,
        FontFace = "Font",
        PlaceholderColor3 = function()
            local H, S, V = Library.Scheme.FontColor:ToHSV()
            return Color3.fromHSV(H, S, V / 2)
        end,
        Text = "",
        TextColor3 = "FontColor",
    },
    UIListLayout = {
        SortOrder = Enum.SortOrder.LayoutOrder,
    },
    UIStroke = {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    },

    --// Library \\--
    Window = {
        Title = "No Title",
        Footer = "No Footer",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(720, 600),
        IconSize = UDim2.fromOffset(30, 30),
        AutoShow = true,
        Center = true,
        Resizable = true,
        SearchbarSize = UDim2.fromScale(1, 1),
        GlobalSearch = false,
        CornerRadius = 4,
        NotifySide = "Right",
        ShowCustomCursor = true,
        Font = Enum.Font.Code,
        ToggleKeybind = Enum.KeyCode.RightControl,
        MobileButtonsSide = "Left",
        UnlockMouseWhileOpen = true,
        Compact = false,
        EnableSidebarResize = false,
        SidebarMinWidth = 180,
        SidebarCompactWidth = 54,
        SidebarCollapseThreshold = 0.5,
        SidebarHighlightCallback = nil,
    },
    Toggle = {
        Text = "Toggle",
        Default = false,

        Callback = function() end,
        Changed = function() end,

        Risky = false,
        Disabled = false,
        Visible = true,
    },
    Input = {
        Text = "Input",
        Default = "",
        Finished = false,
        Numeric = false,
        ClearTextOnFocus = true,
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "---",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Dropdown = {
        Values = {},
        DisabledValues = {},
        Multi = false,
        MaxVisibleDropdownItems = 8,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Viewport = {
        Object = nil,
        Camera = nil,
        Clone = true,
        AutoFocus = true,
        Interactive = false,
        Height = 200,
        Visible = true,
    },
    Image = {
        Image = "",
        Transparency = 0,
        BackgroundTransparency = 0,
        Color = Color3.new(1, 1, 1),
        RectOffset = Vector2.zero,
        RectSize = Vector2.zero,
        ScaleType = Enum.ScaleType.Fit,
        Height = 200,
        Visible = true,
    },
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    },

    --// Addons \\-
    KeyPicker = {
        Text = "KeyPicker",
        Default = "None",
        DefaultModifiers = {},
        Mode = "Toggle",
        Modes = { "Always", "Toggle", "Hold" },
        SyncToggleState = false,

        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1, 1, 1),

        Callback = function() end,
        Changed = function() end,
    },
}

local Places = {
    Bottom = { 0, 1 },
    Right = { 1, 0 },
}
local Sizes = {
    Left = { 0.5, 1 },
    Right = { 0.5, 1 },
}

--// Basic Functions \\--
local function ApplyDPIScale(Dimension, ExtraOffset)
    if typeof(Dimension) == "UDim" then
        return UDim.new(Dimension.Scale, Dimension.Offset * Library.DPIScale)
    end

    if ExtraOffset then
        return UDim2.new(
            Dimension.X.Scale,
            (Dimension.X.Offset * Library.DPIScale) + (ExtraOffset[1] * Library.DPIScale),
            Dimension.Y.Scale,
            (Dimension.Y.Offset * Library.DPIScale) + (ExtraOffset[2] * Library.DPIScale)
        )
    end

    return UDim2.new(
        Dimension.X.Scale,
        Dimension.X.Offset * Library.DPIScale,
        Dimension.Y.Scale,
        Dimension.Y.Offset * Library.DPIScale
    )
end
local function ApplyTextScale(TextSize)
    return TextSize * Library.DPIScale
end

local function WaitForEvent(Event, Timeout, Condition)
    local Bindable = Instance.new("BindableEvent")
    local Connection = Event:Once(function(...)
        if not Condition or typeof(Condition) == "function" and Condition(...) then
            Bindable:Fire(true)
        else
            Bindable:Fire(false)
        end
    end)
    task.delay(Timeout, function()
        Connection:Disconnect()
        Bindable:Fire(false)
    end)

    local Result = Bindable.Event:Wait()
    Bindable:Destroy()

    return Result
end

local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end
local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and Input.UserInputState == Enum.UserInputState.Begin
        and Library.IsRobloxFocused
end
local function IsHoverInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Input.UserInputState == Enum.UserInputState.Change
end
local function IsDragInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
        and Library.IsRobloxFocused
end

local function GetTableSize(Table: { [any]: any })
    local Size = 0

    for _, _ in Table do
        Size += 1
    end

    return Size
end
local function StopTween(Tween: TweenBase)
    if not (Tween and Tween.PlaybackState == Enum.PlaybackState.Playing) then
        return
    end

    Tween:Cancel()
end
local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end
local function Round(Value, Rounding)
    -- Ensure Value is a number
    Value = tonumber(Value)
    if not Value then
        return 0
    end

    -- Ensure Rounding is a valid number and convert if necessary
    Rounding = tonumber(Rounding) or 0

    -- Ensure Rounding is non-negative and an integer
    if Rounding < 0 then
        Rounding = 0
    end
    Rounding = math.floor(Rounding)

    if Rounding == 0 then
        return math.floor(Value)
    end

    -- Safely format with validated inputs
    local formatted = string.format("%." .. Rounding .. "f", Value)
    return tonumber(formatted) or Value
end

local function GetPlayers(ExcludeLocalPlayer: boolean?)
    local PlayerList = Players:GetPlayers()

    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)
        if Idx then
            table.remove(PlayerList, Idx)
        end
    end

    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)

    return PlayerList
end
local function GetTeams()
    local TeamList = Teams:GetTeams()

    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)

    return TeamList
end
local function GetLighterColor(Color)
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:UpdateKeybindFrame()
    if not Library.KeybindFrame then
        return
    end

    local XSize = 0
    for _, KeybindToggle in pairs(Library.KeybindToggles) do
        if not KeybindToggle.Holder.Visible then
            continue
        end

        local FullSize = KeybindToggle.Label.Size.X.Offset + KeybindToggle.Label.Position.X.Offset
        if FullSize > XSize then
            XSize = FullSize
        end
    end

    Library.KeybindFrame.Size = UDim2.fromOffset(XSize + 18 * Library.DPIScale, 0)
end
function Library:UpdateDependencyBoxes()
    for _, Depbox in pairs(Library.DependencyBoxes) do
        Depbox:Update(true)
    end

    if Library.Searching then
        Library:UpdateSearch(Library.SearchText)
    end
end

local function CheckDepbox(Box, Search)
    local VisibleElements = 0

    for _, ElementInfo in pairs(Box.Elements) do
        if ElementInfo.Type == "Divider" then
            ElementInfo.Holder.Visible = false
            continue
        elseif ElementInfo.SubButton then
            --// Check if any of the Buttons Name matches with Search
            local Visible = false

            --// Check if Search matches Element's Name and if Element is Visible
            if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                Visible = true
            else
                ElementInfo.Base.Visible = false
            end
            if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                Visible = true
            else
                ElementInfo.SubButton.Base.Visible = false
            end
            ElementInfo.Holder.Visible = Visible
            if Visible then
                VisibleElements += 1
            end

            continue
        end

        --// Check if Search matches Element's Name and if Element is Visible
        if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
            ElementInfo.Holder.Visible = true
            VisibleElements += 1
        else
            ElementInfo.Holder.Visible = false
        end
    end

    for _, Depbox in pairs(Box.DependencyBoxes) do
        if not Depbox.Visible then
            continue
        end

        VisibleElements += CheckDepbox(Depbox, Search)
    end

    return VisibleElements
end
local function RestoreDepbox(Box)
    for _, ElementInfo in pairs(Box.Elements) do
        ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

        if ElementInfo.SubButton then
            ElementInfo.Base.Visible = ElementInfo.Visible
            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
        end
    end

    Box:Resize()
    Box.Holder.Visible = true

    for _, Depbox in pairs(Box.DependencyBoxes) do
        if not Depbox.Visible then
            continue
        end

        RestoreDepbox(Depbox)
    end
end

function Library:UpdateSearch(SearchText)
    Library.SearchText = SearchText

    local TabsToReset = {}

    if Library.GlobalSearch then
        for _, Tab in pairs(Library.Tabs) do
            if typeof(Tab) == "table" and not Tab.IsKeyTab then
                table.insert(TabsToReset, Tab)
            end
        end
    elseif Library.LastSearchTab and typeof(Library.LastSearchTab) == "table" then
        table.insert(TabsToReset, Library.LastSearchTab)
    end

    local function ResetTab(Tab)
        if not Tab then
            return
        end

        for _, Groupbox in pairs(Tab.Groupboxes) do
            for _, ElementInfo in pairs(Groupbox.Elements) do
                ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, Depbox in pairs(Groupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            Groupbox:Resize()
            Groupbox.Holder.Visible = true
        end

        for _, Tabbox in pairs(Tab.Tabboxes) do
            for _, SubTab in pairs(Tabbox.Tabs) do
                for _, ElementInfo in pairs(SubTab.Elements) do
                    ElementInfo.Holder.Visible =
                        typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                    if ElementInfo.SubButton then
                        ElementInfo.Base.Visible = ElementInfo.Visible
                        ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                    end
                end

                for _, Depbox in pairs(SubTab.DependencyBoxes) do
                    if not Depbox.Visible then
                        continue
                    end

                    RestoreDepbox(Depbox)
                end

                SubTab.ButtonHolder.Visible = true
            end

            if Tabbox.ActiveTab then
                Tabbox.ActiveTab:Resize()
            end
            Tabbox.Holder.Visible = true
        end

        for _, DepGroupbox in pairs(Tab.DependencyGroupboxes) do
            if not DepGroupbox.Visible then
                continue
            end

            for _, ElementInfo in pairs(DepGroupbox.Elements) do
                ElementInfo.Holder.Visible =
                    typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, Depbox in pairs(DepGroupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            DepGroupbox:Resize()
            DepGroupbox.Holder.Visible = true
        end
    end

    for _, Tab in ipairs(TabsToReset) do
        ResetTab(Tab)
    end

    local Search = SearchText:lower()
    if Trim(Search) == "" then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end
    if not Library.GlobalSearch and Library.ActiveTab and Library.ActiveTab.IsKeyTab then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end

    Library.Searching = true

    local TabsToSearch = {}

    if Library.GlobalSearch then
        TabsToSearch = TabsToReset
        if #TabsToSearch == 0 then
            for _, Tab in pairs(Library.Tabs) do
                if typeof(Tab) == "table" and not Tab.IsKeyTab then
                    table.insert(TabsToSearch, Tab)
                end
            end
        end
    elseif Library.ActiveTab then
        table.insert(TabsToSearch, Library.ActiveTab)
    end

    local function ApplySearchToTab(Tab)
        if not Tab then
            return
        end

        local HasVisible = false

        --// Loop through Groupboxes to get Elements Info
        for _, Groupbox in pairs(Tab.Groupboxes) do
            local VisibleElements = 0

            for _, ElementInfo in pairs(Groupbox.Elements) do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = false
                    continue
                elseif ElementInfo.SubButton then
                    --// Check if any of the Buttons Name matches with Search
                    local Visible = false

                    --// Check if Search matches Element's Name and if Element is Visible
                    if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        Visible = true
                    else
                        ElementInfo.Base.Visible = false
                    end
                    if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                        Visible = true
                    else
                        ElementInfo.SubButton.Base.Visible = false
                    end
                    ElementInfo.Holder.Visible = Visible
                    if Visible then
                        VisibleElements += 1
                    end

                    continue
                end

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, Depbox in pairs(Groupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements += CheckDepbox(Depbox, Search)
            end

            --// Update Groupbox Size and Visibility if found any element
            if VisibleElements > 0 then
                Groupbox:Resize()
                HasVisible = true
            end
            Groupbox.Holder.Visible = VisibleElements > 0
        end

        for _, Tabbox in pairs(Tab.Tabboxes) do
            local VisibleTabs = 0
            local VisibleElements = {}

            for _, SubTab in pairs(Tabbox.Tabs) do
                VisibleElements[SubTab] = 0

                for _, ElementInfo in pairs(SubTab.Elements) do
                    if ElementInfo.Type == "Divider" then
                        ElementInfo.Holder.Visible = false
                        continue
                    elseif ElementInfo.SubButton then
                        --// Check if any of the Buttons Name matches with Search
                        local Visible = false

                        --// Check if Search matches Element's Name and if Element is Visible
                        if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                            Visible = true
                        else
                            ElementInfo.Base.Visible = false
                        end
                        if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                            Visible = true
                        else
                            ElementInfo.SubButton.Base.Visible = false
                        end
                        ElementInfo.Holder.Visible = Visible
                        if Visible then
                            VisibleElements[SubTab] += 1
                        end

                        continue
                    end

                    --// Check if Search matches Element's Name and if Element is Visible
                    if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        ElementInfo.Holder.Visible = true
                        VisibleElements[SubTab] += 1
                    else
                        ElementInfo.Holder.Visible = false
                    end
                end

                for _, Depbox in pairs(SubTab.DependencyBoxes) do
                    if not Depbox.Visible then
                        continue
                    end

                    VisibleElements[SubTab] += CheckDepbox(Depbox, Search)
                end
            end

            for SubTab, Visible in pairs(VisibleElements) do
                SubTab.ButtonHolder.Visible = Visible > 0
                if Visible > 0 then
                    VisibleTabs += 1
                    HasVisible = true

                    if Tabbox.ActiveTab == SubTab then
                        SubTab:Resize()
                    elseif Tabbox.ActiveTab and VisibleElements[Tabbox.ActiveTab] == 0 then
                        SubTab:Show()
                    end
                end
            end

            --// Update Tabbox Visibility if any visible
            Tabbox.Holder.Visible = VisibleTabs > 0
        end

        for _, DepGroupbox in pairs(Tab.DependencyGroupboxes) do
            if not DepGroupbox.Visible then
                continue
            end

            local VisibleElements = 0

            for _, ElementInfo in pairs(DepGroupbox.Elements) do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = false
                    continue
                elseif ElementInfo.SubButton then
                    --// Check if any of the Buttons Name matches with Search
                    local Visible = false

                    --// Check if Search matches Element's Name and if Element is Visible
                    if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        Visible = true
                    else
                        ElementInfo.Base.Visible = false
                    end
                    if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                        Visible = true
                    else
                        ElementInfo.SubButton.Base.Visible = false
                    end
                    ElementInfo.Holder.Visible = Visible
                    if Visible then
                        VisibleElements += 1
                    end

                    continue
                end

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, Depbox in pairs(DepGroupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements += CheckDepbox(Depbox, Search)
            end

            --// Update Groupbox Size and Visibility if found any element
            if VisibleElements > 0 then
                DepGroupbox:Resize()
                HasVisible = true
            end
            DepGroupbox.Holder.Visible = VisibleElements > 0
        end

        return HasVisible
    end

    local FirstVisibleTab = nil
    local ActiveHasVisible = false

    for _, Tab in ipairs(TabsToSearch) do
        local HasVisible = ApplySearchToTab(Tab)
        if HasVisible then
            if not FirstVisibleTab then
                FirstVisibleTab = Tab
            end
            if Tab == Library.ActiveTab then
                ActiveHasVisible = true
            end
        end
    end

    if Library.GlobalSearch then
        if ActiveHasVisible and Library.ActiveTab then
            Library.ActiveTab:RefreshSides()
        elseif FirstVisibleTab then
            local SearchMarker = SearchText
            task.defer(function()
                if Library.SearchText ~= SearchMarker then
                    return
                end

                if Library.ActiveTab ~= FirstVisibleTab then
                    FirstVisibleTab:Show()
                end
            end)
        end
        Library.LastSearchTab = nil
    else
        Library.LastSearchTab = Library.ActiveTab
    end
end

function Library:AddToRegistry(Instance, Properties)
    Library.Registry[Instance] = Properties
end

function Library:RemoveFromRegistry(Instance)
    Library.Registry[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for Instance, Properties in pairs(Library.Registry) do
        for Property, ColorIdx in pairs(Properties) do
            if typeof(ColorIdx) == "string" then
                Instance[Property] = Library.Scheme[ColorIdx]
            elseif typeof(ColorIdx) == "function" then
                Instance[Property] = ColorIdx()
            end
        end
    end
end

function Library:UpdateDPI(Instance, Properties)
    if not Library.DPIRegistry[Instance] then
        return
    end

    for Property, Value in pairs(Properties) do
        Library.DPIRegistry[Instance][Property] = Value and Value or nil
    end
end

function Library:SetDPIScale(DPIScale: number)
    Library.DPIScale = DPIScale / 100
    Library.MinSize *= Library.DPIScale

    for Instance, Properties in pairs(Library.DPIRegistry) do
        for Property, Value in pairs(Properties) do
            if Property == "DPIExclude" or Property == "DPIOffset" then
                continue
            elseif Property == "TextSize" then
                Instance[Property] = ApplyTextScale(Value)
            else
                Instance[Property] = ApplyDPIScale(Value, Properties["DPIOffset"][Property])
            end
        end
    end

    for _, Tab in pairs(Library.Tabs) do
        if Tab.IsKeyTab then
            continue
        end

        Tab:Resize(true)
        for _, Groupbox in pairs(Tab.Groupboxes) do
            Groupbox:Resize()
        end
        for _, Tabbox in pairs(Tab.Tabboxes) do
            for _, SubTab in pairs(Tabbox.Tabs) do
                SubTab:Resize()
            end
        end
    end

    for _, Option in pairs(Options) do
        if Option.Type == "Dropdown" then
            Option:RecalculateListSize()
        elseif Option.Type == "KeyPicker" then
            Option:Update()
        end
    end

    Library:UpdateKeybindFrame()
    for _, Notification in pairs(Library.Notifications) do
        Notification:Resize()
    end
end

function Library:GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
    local ConnectionType = typeof(Connection)
    if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
        table.insert(Library.Signals, Connection)
    end

    return Connection
end

function IsValidCustomIcon(Icon: string)
    return typeof(Icon) == "string"
        and (Icon:match("rbxasset") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
end

type Icon = {
    Url: string,
    Id: number,
    IconName: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
}

type IconModule = {
    Icons: { string },
    GetAsset: (Name: string) -> Icon?,
}

local FetchIcons, Icons = pcall(function()
    return (loadstring(
        game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua")
    ) :: () -> IconModule)()
end)

function Library:GetIcon(IconName: string)
    if not FetchIcons then
        return
    end

    local Success, Icon = pcall(Icons.GetAsset, IconName)
    if not Success then
        return
    end
    return Icon
end

function Library:GetCustomIcon(IconName: string)
    if not IsValidCustomIcon(IconName) then
        return Library:GetIcon(IconName)
    else
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Custom = true,
        }
    end
end

function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in pairs(Template) do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end

--// Creator Functions \\--
local function FillInstance(Table: { [string]: any }, Instance: GuiObject)
    local ThemeProperties = Library.Registry[Instance] or {}
    local DPIProperties = Library.DPIRegistry[Instance] or {}

    local DPIExclude = DPIProperties["DPIExclude"] or Table["DPIExclude"] or {}
    local DPIOffset = DPIProperties["DPIOffset"] or Table["DPIOffset"] or {}

    for k, v in pairs(Table) do
        if k == "DPIExclude" or k == "DPIOffset" then
            continue
        elseif ThemeProperties[k] then
            ThemeProperties[k] = nil
        elseif k ~= "Text" and (Library.Scheme[v] or typeof(v) == "function") then
            -- me when Red in dropdowns break things (temp fix - or perm idk if deivid will do something about this)
            ThemeProperties[k] = v
            Instance[k] = Library.Scheme[v] or v()
            continue
        end

        if not DPIExclude[k] then
            if k == "Position" or k == "Size" or k:match("Padding") then
                DPIProperties[k] = v
                v = ApplyDPIScale(v, DPIOffset[k])
            elseif k == "TextSize" then
                DPIProperties[k] = v
                v = ApplyTextScale(v)
            end
        end

        Instance[k] = v
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Instance] = ThemeProperties
    end
    if GetTableSize(DPIProperties) > 0 then
        DPIProperties["DPIExclude"] = DPIExclude
        DPIProperties["DPIOffset"] = DPIOffset
        Library.DPIRegistry[Instance] = DPIProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local Instance = Instance.new(ClassName)

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], Instance)
    end
    FillInstance(Properties, Instance)

    if Properties["Parent"] and not Properties["ZIndex"] then
        pcall(function()
            Instance.ZIndex = Properties.Parent.ZIndex
        end)
    end

    return Instance
end

--// Main Instances \\-
local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
    local success, _error = pcall(function()
        if not Parent then
            Parent = CoreGui
        end

        local DestinationParent
        if typeof(Parent) == "function" then
            DestinationParent = Parent()
        else
            DestinationParent = Parent
        end

        Instance.Parent = DestinationParent
    end)

    if not (success and Instance.Parent) then
        Instance.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
    if SkipHiddenUI then
        SafeParentUI(UI, CoreGui)
        return
    end

    pcall(protectgui, UI)
    SafeParentUI(UI, gethui)
end

local ScreenGui = New("ScreenGui", {
    Name = "Obsidian",
    DisplayOrder = 999,
    ResetOnSpawn = false,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui
ScreenGui.DescendantRemoving:Connect(function(Instance)
    Library:RemoveFromRegistry(Instance)
    Library.DPIRegistry[Instance] = nil
end)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0, 0),
    AnchorPoint = Vector2.zero,
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})

--// Cursor
local Cursor
do
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "White",
        Size = UDim2.fromOffset(9, 1),
        Visible = false,
        ZIndex = 999,
        Parent = ScreenGui,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "Dark",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 998,
        Parent = Cursor,
    })

    local CursorV = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "White",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 9),
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "Dark",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 998,
        Parent = CursorV,
    })
end

--// Notification
local NotificationArea
local NotificationList
do
    NotificationArea = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -6, 0, 6),
        Size = UDim2.new(0, 300, 1, -6),
        Parent = ScreenGui,
    })
    NotificationList = New("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 6),
        Parent = NotificationArea,
    })
end

--// Lib Functions \\--
function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

function Library:GetDarkerColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 2)
end

function Library:GetLighterColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.15))
end

function Library:GetAccentGlow(Color: Color3, Intensity: number?): Color3
    Intensity = Intensity or 0.2
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - Intensity), math.min(1, V + Intensity))
end

-- Create a pulse animation effect on an element
function Library:CreatePulseEffect(Element: GuiObject, Property: string, StartValue: any, EndValue: any, Duration: number?)
    Duration = Duration or 1
    local PulseTweenInfo = TweenInfo.new(Duration / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local PulseTween = TweenService:Create(Element, PulseTweenInfo, {[Property] = EndValue})
    Element[Property] = StartValue
    PulseTween:Play()
    return PulseTween
end

-- Create a glow/shadow effect using UIStroke
function Library:CreateGlowEffect(Element: GuiObject, Color: Color3?, Thickness: number?)
    Color = Color or Library.Scheme.AccentColor
    Thickness = Thickness or 2

    local Glow = Instance.new("UIStroke")
    Glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Glow.Color = Color
    Glow.Thickness = Thickness
    Glow.Transparency = 0.5
    Glow.Parent = Element

    -- Animate the glow
    local GlowTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local GlowTween = TweenService:Create(Glow, GlowTweenInfo, {Transparency = 0.8})
    GlowTween:Play()

    return Glow, GlowTween
end

-- Ripple click effect
function Library:CreateRippleEffect(Element: GuiObject, ClickPosition: Vector2?)
    local Ripple = Instance.new("Frame")
    Ripple.Name = "Ripple"
    Ripple.BackgroundColor3 = Library.Scheme.AccentColor
    Ripple.BackgroundTransparency = 0.7
    Ripple.BorderSizePixel = 0
    Ripple.ZIndex = Element.ZIndex + 1

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(1, 0)
    Corner.Parent = Ripple

    -- Position at click or center
    local ElementPos = Element.AbsolutePosition
    local ElementSize = Element.AbsoluteSize
    local RipplePos = ClickPosition or Vector2.new(ElementPos.X + ElementSize.X/2, ElementPos.Y + ElementSize.Y/2)

    local RelativeX = (RipplePos.X - ElementPos.X) / ElementSize.X
    local RelativeY = (RipplePos.Y - ElementPos.Y) / ElementSize.Y

    Ripple.Position = UDim2.fromScale(RelativeX, RelativeY)
    Ripple.Size = UDim2.fromOffset(0, 0)
    Ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    Ripple.Parent = Element

    -- Expand and fade
    local MaxSize = math.max(ElementSize.X, ElementSize.Y) * 2.5
    local RippleTween = TweenService:Create(Ripple, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(MaxSize, MaxSize),
        BackgroundTransparency = 1,
    })
    RippleTween:Play()
    RippleTween.Completed:Connect(function()
        Ripple:Destroy()
    end)

    return Ripple
end

-- Shake effect for error feedback
function Library:CreateShakeEffect(Element: GuiObject, Intensity: number?, Duration: number?)
    Intensity = Intensity or 5
    Duration = Duration or 0.3

    local OriginalPosition = Element.Position
    local StartTime = tick()

    local ShakeConnection
    ShakeConnection = RunService.RenderStepped:Connect(function()
        local Elapsed = tick() - StartTime
        if Elapsed >= Duration then
            Element.Position = OriginalPosition
            ShakeConnection:Disconnect()
            return
        end

        local Progress = Elapsed / Duration
        local Decay = 1 - Progress
        local OffsetX = math.sin(Elapsed * 50) * Intensity * Decay
        Element.Position = OriginalPosition + UDim2.fromOffset(OffsetX, 0)
    end)

    return ShakeConnection
end

-- Scale bounce effect
function Library:CreateBounceEffect(Element: GuiObject, Scale: number?)
    Scale = Scale or 1.1
    local OriginalSize = Element.Size

    local BounceUp = TweenService:Create(Element, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(OriginalSize.X.Scale * Scale, OriginalSize.X.Offset, OriginalSize.Y.Scale * Scale, OriginalSize.Y.Offset),
    })
    local BounceDown = TweenService:Create(Element, TweenInfo.new(0.15, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
        Size = OriginalSize,
    })

    BounceUp:Play()
    BounceUp.Completed:Connect(function()
        BounceDown:Play()
    end)
end

function Library:GetKeyString(KeyCode: Enum.KeyCode)
    if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
        return string.char(KeyCode.Value)
    end

    return KeyCode.Name
end

function Library:GetTextBounds(Text: string, Font: Font, Size: number, Width: number?): (number, number)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = Text
    Params.RichText = true
    Params.Font = Font
    Params.Size = Size
    Params.Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

    local Bounds = TextService:GetTextBoundsAsync(Params)
    return Bounds.X, Bounds.Y
end

function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X
        and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y
        and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:SafeCallback(Func: (...any) -> ...any, ...: any)
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError then
            Library:Notify(Error)
        end

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

function Library:MakeDraggable(UI: GuiObject, DragFrame: GuiObject, IgnoreToggled: boolean?, IsMainWindow: boolean?)
    local StartPos
    local FramePos
    local Dragging = false
    local Changed
    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or IsMainWindow and Library.CantDragForced then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if
            (not IgnoreToggled and not Library.Toggled)
            or (IsMainWindow and Library.CantDragForced)
            or not (ScreenGui and ScreenGui.Parent)
        then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Position =
                UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
        end
    end))
end

function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: () -> ()?)
    local StartPos
    local FrameSize
    local Dragging = false
    local Changed

    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        StartPos = Input.Position
        FrameSize = UI.Size
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Size = UDim2.new(
                FrameSize.X.Scale,
                math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
                FrameSize.Y.Scale,
                math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
            )
            if Callback then
                Library:SafeCallback(Callback)
            end
        end
    end))
end

function Library:MakeCover(Holder: GuiObject, Place: string)
    local Pos = Places[Place] or { 0, 0 }
    local Size = Sizes[Place] or { 1, 0.5 }

    local Cover = New("Frame", {
        AnchorPoint = Vector2.new(Pos[1], Pos[2]),
        BackgroundColor3 = Holder.BackgroundColor3,
        Position = UDim2.fromScale(Pos[1], Pos[2]),
        Size = UDim2.fromScale(Size[1], Size[2]),
        Parent = Holder,
    })

    return Cover
end

function Library:MakeLine(Frame: GuiObject, Info)
    local Line = New("Frame", {
        AnchorPoint = Info.AnchorPoint or Vector2.zero,
        BackgroundColor3 = "OutlineColor",
        Position = Info.Position,
        Size = Info.Size,
        ZIndex = Info.ZIndex or 1,
        Parent = Frame,
    })

    return Line
end

function Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)
    local Holder = New("Frame", {
        BackgroundColor3 = "Dark",
        Position = UDim2.fromOffset(-2, -2),
        Size = UDim2.new(1, 4, 1, 4),
        ZIndex = ZIndex,
        Parent = Frame,
    })

    local Outline = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = ZIndex,
        Parent = Holder,
    })

    -- Purple shadow effect
    local Shadow = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = "AccentColor",
        ImageTransparency = 0.88,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 16, 1, 16),
        ZIndex = (ZIndex or 1) - 1,
        Parent = Holder,
    })

    if Corner and Corner > 0 then
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner + 1),
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner),
            Parent = Outline,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner + 4),
            Parent = Shadow,
        })
    end

    return Holder, Outline
end

function Library:AddDraggableButton(Text: string, Func)
    local Table = {}

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        TextSize = 16,
        ZIndex = 10,
        Parent = ScreenGui,

        DPIExclude = {
            Position = true,
        },
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Button,
    })
    Library:MakeOutline(Button, Library.CornerRadius, 9)

    Table.Button = Button
    Button.MouseButton1Click:Connect(function()
        Library:SafeCallback(Func, Table)
    end)
    Library:MakeDraggable(Button, Button, true)

    function Table:SetText(NewText: string)
        local X, Y = Library:GetTextBounds(NewText, Library.Scheme.Font, 16)

        Button.Text = NewText
        Button.Size = UDim2.fromOffset(X * Library.DPIScale * 2, Y * Library.DPIScale * 2)
        Library:UpdateDPI(Button, {
            Size = UDim2.fromOffset(X * 2, Y * 2),
        })
    end
    Table:SetText(Text)

    return Table
end

-- New icon button for mobile (square with Lucide icon)
function Library:AddIconButton(IconName: string, Func, Options)
    Options = Options or {}
    local Table = {
        Toggled = false,
        Locked = false,
    }

    local Size = Options.Size or 40
    local Icon = Library:GetCustomIcon(IconName)
    local ToggledIcon = Options.ToggledIcon and Library:GetCustomIcon(Options.ToggledIcon) or nil

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = Options.Position or UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(Size, Size),
        Text = "",
        ZIndex = 10,
        Parent = ScreenGui,

        DPIExclude = {
            Position = true,
        },
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Button,
    })

    local Outline = Library:MakeOutline(Button, Library.CornerRadius + 1, 9)

    local IconImage = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = Icon and Icon.Url or "",
        ImageColor3 = "FontColor",
        ImageRectOffset = Icon and Icon.ImageRectOffset or Vector2.zero,
        ImageRectSize = Icon and Icon.ImageRectSize or Vector2.zero,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(Size * 0.5, Size * 0.5),
        Parent = Button,
    })

    -- Hover animation
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, Library.HoverTweenInfo, {
            BackgroundColor3 = Library:GetLighterColor(Library.Scheme.BackgroundColor),
        }):Play()
        TweenService:Create(IconImage, Library.HoverTweenInfo, {
            ImageColor3 = Library.Scheme.AccentColor,
            Size = UDim2.fromOffset(Size * 0.55, Size * 0.55),
        }):Play()
    end)

    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, Library.HoverTweenInfo, {
            BackgroundColor3 = Library.Scheme.BackgroundColor,
        }):Play()
        TweenService:Create(IconImage, Library.HoverTweenInfo, {
            ImageColor3 = Table.Toggled and Library.Scheme.AccentColor or Library.Scheme.FontColor,
            Size = UDim2.fromOffset(Size * 0.5, Size * 0.5),
        }):Play()
    end)

    -- Click animation and callback
    Button.MouseButton1Click:Connect(function()
        if Table.Locked then return end

        -- Click bounce effect
        local BounceDown = TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(Size * 0.9, Size * 0.9),
        })
        local BounceUp = TweenService:Create(Button, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(Size, Size),
        })

        BounceDown:Play()
        BounceDown.Completed:Connect(function()
            BounceUp:Play()
        end)

        -- Rotate icon animation
        TweenService:Create(IconImage, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Rotation = IconImage.Rotation == 0 and 180 or 0,
        }):Play()

        Library:SafeCallback(Func, Table)
    end)

    Library:MakeDraggable(Button, Button, true)

    Table.Button = Button
    Table.Icon = IconImage
    Table.Outline = Outline

    function Table:SetIcon(NewIconName: string)
        local NewIcon = Library:GetCustomIcon(NewIconName)
        if NewIcon then
            IconImage.Image = NewIcon.Url
            IconImage.ImageRectOffset = NewIcon.ImageRectOffset
            IconImage.ImageRectSize = NewIcon.ImageRectSize
        end
    end

    function Table:SetToggled(Value: boolean)
        Table.Toggled = Value
        TweenService:Create(IconImage, Library.HoverTweenInfo, {
            ImageColor3 = Value and Library.Scheme.AccentColor or Library.Scheme.FontColor,
        }):Play()

        if ToggledIcon and Value then
            Table:SetIcon(Options.ToggledIcon)
        elseif Icon and not Value then
            Table:SetIcon(IconName)
        end
    end

    function Table:SetPosition(NewPos: UDim2)
        Button.Position = NewPos
    end

    function Table:SetAnchorPoint(Point: Vector2)
        Button.AnchorPoint = Point
    end

    return Table
end

function Library:AddDraggableMenu(Name: string)
    local Background = Library:MakeOutline(ScreenGui, Library.CornerRadius, 10)
    Background.AutomaticSize = Enum.AutomaticSize.Y
    Background.Position = UDim2.fromOffset(6, 6)
    Background.Size = UDim2.fromOffset(0, 0)
    Library:UpdateDPI(Background, {
        Position = false,
        Size = false,
    })

    local Holder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Parent = Background,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Holder,
    })
    Library:MakeLine(Holder, {
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Text = Name,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = Label,
    })

    local Container = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 35),
        Size = UDim2.new(1, 0, 1, -35),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        Parent = Container,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        PaddingTop = UDim.new(0, 7),
        Parent = Container,
    })

    Library:MakeDraggable(Background, Label, true)
    return Background, Container
end

--// Watermark \\--
do
    local WatermarkBackground = Library:MakeOutline(ScreenGui, Library.CornerRadius, 10)
    WatermarkBackground.AutomaticSize = Enum.AutomaticSize.Y
    WatermarkBackground.Position = UDim2.fromOffset(6, 6)
    WatermarkBackground.Size = UDim2.fromOffset(0, 0)
    WatermarkBackground.Visible = false

    Library:UpdateDPI(WatermarkBackground, {
        Position = false,
        Size = false,
    })

    local Holder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Parent = WatermarkBackground,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Holder,
    })

    local WatermarkLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.fromOffset(0, -8 * Library.DPIScale + 7),
        Text = "",
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = WatermarkLabel,
    })

    Library:MakeDraggable(WatermarkBackground, WatermarkLabel, true)

    local function ResizeWatermark()
        local X, Y = Library:GetTextBounds(WatermarkLabel.Text, Library.Scheme.Font, 15)
        WatermarkBackground.Size = UDim2.fromOffset((12 + X + 12 + 4) * Library.DPIScale, Y + 12 + 4)
        Library:UpdateDPI(WatermarkBackground, {
            Size = UDim2.fromOffset(12 + X + 12 + 4, Y + 12 + 4),
        })
        WatermarkLabel.Size = UDim2.new(1, 0, 0, WatermarkBackground.Size.Y.Offset)
    end

    function Library:SetWatermarkVisibility(Visible: boolean)
        WatermarkBackground.Visible = Visible
        if Visible then
            ResizeWatermark()
        end
    end

    function Library:SetWatermark(Text: string)
        WatermarkLabel.Text = Text
        ResizeWatermark()
    end
end

--// Context Menu \\--
local CurrentMenu
function Library:AddContextMenu(
    Holder: GuiObject,
    Size: UDim2 | () -> (),
    Offset: { [number]: number } | () -> {},
    List: number?,
    ActiveCallback: (Active: boolean) -> ()?
)
    local Menu
    if List then
        Menu = New("ScrollingFrame", {
            AutomaticCanvasSize = List == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3 = "BackgroundColor",
            BorderSizePixel = 0,
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = "AccentColor",
            ScrollBarThickness = List == 2 and 3 or 0,
            Size = typeof(Size) == "function" and Size() or Size,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = 10,
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
            },
        })
    else
        Menu = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            BorderSizePixel = 0,
            Size = typeof(Size) == "function" and Size() or Size,
            Visible = false,
            ZIndex = 10,
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
            },
        })
    end

    -- Modern rounded corners
    New("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Menu,
    })

    -- Stroke for clean border
    New("UIStroke", {
        Color = "OutlineColor",
        Thickness = 1,
        Parent = Menu,
    })

    local Table = {
        Active = false,
        Holder = Holder,
        Menu = Menu,
        List = nil,
        Signal = nil,

        Size = Size,
    }

    if List then
        Table.List = New("UIListLayout", {
            Parent = Menu,
        })
    end

    function Table:Open()
        if CurrentMenu == Table then
            return
        elseif CurrentMenu then
            CurrentMenu:Close()
        end

        CurrentMenu = Table
        Table.Active = true

        if typeof(Offset) == "function" then
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset()[2])
            )
        else
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset[2])
            )
        end
        if typeof(Table.Size) == "function" then
            Menu.Size = Table.Size()
        else
            Menu.Size = ApplyDPIScale(Table.Size)
        end
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, true)
        end

        Menu.Visible = true

        Table.Signal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if typeof(Offset) == "function" then
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset()[2])
                )
            else
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset[2])
                )
            end
        end)
    end

    function Table:Close()
        if CurrentMenu ~= Table then
            return
        end
        Menu.Visible = false

        if Table.Signal then
            Table.Signal:Disconnect()
            Table.Signal = nil
        end
        Table.Active = false
        CurrentMenu = nil
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, false)
        end
    end

    function Table:Toggle()
        if Table.Active then
            Table:Close()
        else
            Table:Open()
        end
    end

    function Table:SetSize(Size)
        Table.Size = Size
        Menu.Size = typeof(Size) == "function" and Size() or Size
    end

    return Table
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
    if Library.Unloaded then
        return
    end

    if IsClickInput(Input, true) then
        local Location = Input.Position

        if
            CurrentMenu
            and not (
                Library:MouseIsOverFrame(CurrentMenu.Menu, Location)
                or Library:MouseIsOverFrame(CurrentMenu.Holder, Location)
            )
        then
            CurrentMenu:Close()
        end
    end
end))

--// Tooltip \\--
local TooltipLabel = New("TextLabel", {
    BackgroundColor3 = "BackgroundColor",
    BorderSizePixel = 0,
    TextSize = 14,
    TextWrapped = true,
    Visible = false,
    ZIndex = 20,
    Parent = ScreenGui,
})

-- Rounded corners for tooltip
New("UICorner", {
    CornerRadius = UDim.new(0, 6),
    Parent = TooltipLabel,
})

-- Clean stroke border
New("UIStroke", {
    Color = "OutlineColor",
    Thickness = 1,
    Parent = TooltipLabel,
})

-- Tooltip padding
New("UIPadding", {
    PaddingBottom = UDim.new(0, 4),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    PaddingTop = UDim.new(0, 4),
    Parent = TooltipLabel,
})

-- Purple shadow for tooltip
local TooltipShadow = New("ImageLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Image = "rbxassetid://6015897843",
    ImageColor3 = "AccentColor",
    ImageTransparency = 0.88,
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, 12, 1, 12),
    ZIndex = -1,
    Parent = TooltipLabel,
})
New("UICorner", {
    CornerRadius = UDim.new(0, 8),
    Parent = TooltipShadow,
})
TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    if Library.Unloaded then
        return
    end

    local X, Y = Library:GetTextBounds(
        TooltipLabel.Text,
        TooltipLabel.FontFace,
        TooltipLabel.TextSize,
        workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 4
    )

    TooltipLabel.Size = UDim2.fromOffset(X + 8 * Library.DPIScale, Y + 4 * Library.DPIScale)
    Library:UpdateDPI(TooltipLabel, {
        Size = UDim2.fromOffset(X, Y),
        DPIOffset = {
            Size = { 8, 4 },
        },
    })
end)

local CurrentHoverInstance
function Library:AddTooltip(InfoStr: string, DisabledInfoStr: string, HoverInstance: GuiObject)
    local TooltipTable = {
        Disabled = false,
        Hovering = false,
        Signals = {},
    }

    local function DoHover()
        if
            CurrentHoverInstance == HoverInstance
            or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
            or (TooltipTable.Disabled and typeof(DisabledInfoStr) ~= "string")
            or (not TooltipTable.Disabled and typeof(InfoStr) ~= "string")
        then
            return
        end
        CurrentHoverInstance = HoverInstance

        TooltipLabel.Text = TooltipTable.Disabled and DisabledInfoStr or InfoStr
        TooltipLabel.Visible = true

        while
            Library.Toggled
            and Library:MouseIsOverFrame(HoverInstance, Mouse)
            and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
        do
            TooltipLabel.Position = UDim2.fromOffset(
                Mouse.X + (Library.ShowCustomCursor and 8 or 14),
                Mouse.Y + (Library.ShowCustomCursor and 8 or 12)
            )

            RunService.RenderStepped:Wait()
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end

    local function GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
        local ConnectionType = typeof(Connection)
        if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
            table.insert(TooltipTable.Signals, Connection)
        end

        return Connection
    end

    GiveSignal(HoverInstance.MouseEnter:Connect(DoHover))
    GiveSignal(HoverInstance.MouseMoved:Connect(DoHover))
    GiveSignal(HoverInstance.MouseLeave:Connect(function()
        if CurrentHoverInstance ~= HoverInstance then
            return
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end))

    function TooltipTable:Destroy()
        for Index = #TooltipTable.Signals, 1, -1 do
            local Connection = table.remove(TooltipTable.Signals, Index)
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end

        if CurrentHoverInstance == HoverInstance then
            if TooltipLabel then
                TooltipLabel.Visible = false
            end

            CurrentHoverInstance = nil
        end
    end

    table.insert(Tooltips, TooltipLabel)
    return TooltipTable
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

function Library:Unload()
    for Index = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Index)
        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
    end

    for _, Callback in Library.UnloadSignals do
        Library:SafeCallback(Callback)
    end

    for _, Tooltip in Tooltips do
        Library:SafeCallback(Tooltip.Destroy, Tooltip)
    end

    Library.Unloaded = true
    ScreenGui:Destroy()

    getgenv().Library = nil
end

local CheckIcon = Library:GetIcon("check")
local ArrowIcon = Library:GetIcon("chevron-up")
local ResizeIcon = Library:GetIcon("move-diagonal-2")
local KeyIcon = Library:GetIcon("key")
local MoveIcon = Library:GetIcon("move")

function Library:SetIconModule(module: IconModule)
    FetchIcons = true
    Icons = module

    -- Top ten fixes 🚀
    CheckIcon = Library:GetIcon("check")
    ArrowIcon = Library:GetIcon("chevron-up")
    ResizeIcon = Library:GetIcon("move-diagonal-2")
    KeyIcon = Library:GetIcon("key")
    MoveIcon = Library:GetIcon("move")
end

local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddKeyPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.KeyPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local KeyPicker = {
            Text = Info.Text,
            Value = Info.Default, -- Key
            Modifiers = Info.DefaultModifiers, -- Modifiers
            DisplayValue = Info.Default, -- Picker Text

            Toggled = false,
            Mode = Info.Mode,
            SyncToggleState = Info.SyncToggleState,

            Callback = Info.Callback,
            ChangedCallback = Info.ChangedCallback,
            Changed = Info.Changed,
            Clicked = Info.Clicked,

            Type = "KeyPicker",
        }

        if KeyPicker.Mode == "Press" then
            assert(ParentObj.Type == "Label", "KeyPicker with the mode 'Press' can be only applied on Labels.")

            KeyPicker.SyncToggleState = false
            Info.Modes = { "Press" }
            Info.Mode = "Press"
        end

        if KeyPicker.SyncToggleState then
            Info.Modes = { "Toggle" }
            Info.Mode = "Toggle"
        end

        local Picking = false

        -- Special Keys
        local SpecialKeys = {
            ["MB1"] = Enum.UserInputType.MouseButton1,
            ["MB2"] = Enum.UserInputType.MouseButton2,
            ["MB3"] = Enum.UserInputType.MouseButton3,
        }

        local SpecialKeysInput = {
            [Enum.UserInputType.MouseButton1] = "MB1",
            [Enum.UserInputType.MouseButton2] = "MB2",
            [Enum.UserInputType.MouseButton3] = "MB3",
        }

        -- Modifiers
        local Modifiers = {
            ["LAlt"] = Enum.KeyCode.LeftAlt,
            ["RAlt"] = Enum.KeyCode.RightAlt,

            ["LCtrl"] = Enum.KeyCode.LeftControl,
            ["RCtrl"] = Enum.KeyCode.RightControl,

            ["LShift"] = Enum.KeyCode.LeftShift,
            ["RShift"] = Enum.KeyCode.RightShift,

            ["Tab"] = Enum.KeyCode.Tab,
            ["CapsLock"] = Enum.KeyCode.CapsLock,
        }

        local ModifiersInput = {
            [Enum.KeyCode.LeftAlt] = "LAlt",
            [Enum.KeyCode.RightAlt] = "RAlt",

            [Enum.KeyCode.LeftControl] = "LCtrl",
            [Enum.KeyCode.RightControl] = "RCtrl",

            [Enum.KeyCode.LeftShift] = "LShift",
            [Enum.KeyCode.RightShift] = "RShift",

            [Enum.KeyCode.Tab] = "Tab",
            [Enum.KeyCode.CapsLock] = "CapsLock",
        }

        local IsModifierInput = function(Input)
            return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
        end

        local GetActiveModifiers = function()
            local ActiveModifiers = {}

            for Name, Input in Modifiers do
                if table.find(ActiveModifiers, Name) then
                    continue
                end
                if not UserInputService:IsKeyDown(Input) then
                    continue
                end

                table.insert(ActiveModifiers, Name)
            end

            return ActiveModifiers
        end

        local AreModifiersHeld = function(Required)
            if not (typeof(Required) == "table" and GetTableSize(Required) > 0) then
                return true
            end

            local ActiveModifiers = GetActiveModifiers()
            local Holding = true

            for _, Name in Required do
                if table.find(ActiveModifiers, Name) then
                    continue
                end

                Holding = false
                break
            end

            return Holding
        end

        local IsInputDown = function(Input)
            if not Input then
                return false
            end

            if SpecialKeysInput[Input.UserInputType] ~= nil then
                return UserInputService:IsMouseButtonPressed(Input.UserInputType)
                    and not UserInputService:GetFocusedTextBox()
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                return UserInputService:IsKeyDown(Input.KeyCode) and not UserInputService:GetFocusedTextBox()
            else
                return false
            end
        end

        local ConvertToInputModifiers = function(CurrentModifiers)
            local InputModifiers = {}

            for _, name in CurrentModifiers do
                table.insert(InputModifiers, Modifiers[name])
            end

            return InputModifiers
        end

        local VerifyModifiers = function(CurrentModifiers)
            if typeof(CurrentModifiers) ~= "table" then
                return {}
            end

            local ValidModifiers = {}

            for _, name in CurrentModifiers do
                if not Modifiers[name] then
                    continue
                end

                table.insert(ValidModifiers, name)
            end

            return ValidModifiers
        end

        KeyPicker.Modifiers = VerifyModifiers(KeyPicker.Modifiers) -- Verify default modifiers

        local Picker = New("TextButton", {
            BackgroundColor3 = "MainColor",
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(0, 20),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = KeyPicker.Value or "...",
            TextSize = 12,
            Parent = ToggleLabel,
        })

        New("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = Picker,
        })

        local PickerStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Picker,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = Picker,
        })

        -- Hover effects for KeyPicker button
        Picker.MouseEnter:Connect(function()
            TweenService:Create(Picker, Library.HoverTweenInfo, {
                BackgroundColor3 = Library:GetLighterColor(Library.Scheme.MainColor),
            }):Play()
            TweenService:Create(PickerStroke, Library.HoverTweenInfo, {
                Color = Library.Scheme.AccentColor,
            }):Play()
        end)
        Picker.MouseLeave:Connect(function()
            TweenService:Create(Picker, Library.HoverTweenInfo, {
                BackgroundColor3 = Library.Scheme.MainColor,
            }):Play()
            TweenService:Create(PickerStroke, Library.HoverTweenInfo, {
                Color = Library.Scheme.OutlineColor,
            }):Play()
        end)

        local KeybindsToggle = { Normal = KeyPicker.Mode ~= "Toggle" }
        do
            local Holder = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                Text = "",
                Visible = not Info.NoUI,
                Parent = Library.KeybindContainer,
            })

            local Label = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = Holder,

                DPIExclude = {
                    Size = true,
                },
            })

            local Checkbox = New("Frame", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.fromOffset(14, 14),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = Holder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Checkbox,
            })
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Checkbox,
            })

            local CheckImage = New("ImageLabel", {
                Image = CheckIcon and CheckIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 1,
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = Checkbox,
            })

            function KeybindsToggle:Display(State)
                TweenService:Create(Label, Library.HoverTweenInfo, {
                    TextTransparency = State and 0 or 0.5,
                    TextColor3 = State and Library.Scheme.AccentColor or Library.Scheme.FontColor,
                }):Play()
                TweenService:Create(CheckImage, Library.ToggleTweenInfo, {
                    ImageTransparency = State and 0 or 1,
                    ImageColor3 = State and Library.Scheme.AccentColor or Library.Scheme.FontColor,
                }):Play()
                TweenService:Create(Checkbox, Library.HoverTweenInfo, {
                    BackgroundColor3 = State and Library:GetLighterColor(Library.Scheme.MainColor) or Library.Scheme.MainColor,
                }):Play()
            end

            function KeybindsToggle:SetText(Text)
                local X = Library:GetTextBounds(Text, Label.FontFace, Label.TextSize)
                Label.Text = Text
                Label.Size = UDim2.new(0, X, 1, 0)
            end

            function KeybindsToggle:SetVisibility(Visibility)
                Holder.Visible = Visibility
            end

            function KeybindsToggle:SetNormal(Normal)
                KeybindsToggle.Normal = Normal

                Holder.Active = not Normal
                Label.Position = Normal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(22 * Library.DPIScale, 0)
                Checkbox.Visible = not Normal
            end

            KeyPicker.DoClick = function(...) end --// make luau lsp shut up
            Holder.MouseButton1Click:Connect(function()
                if KeybindsToggle.Normal then
                    return
                end

                KeyPicker.Toggled = not KeyPicker.Toggled
                KeyPicker:DoClick()
            end)

            KeybindsToggle.Holder = Holder
            KeybindsToggle.Label = Label
            KeybindsToggle.Checkbox = Checkbox
            KeybindsToggle.Loaded = true
            table.insert(Library.KeybindToggles, KeybindsToggle)
        end

        local MenuTable = Library:AddContextMenu(Picker, UDim2.fromOffset(62, 0), function()
            return { Picker.AbsoluteSize.X + 1.5, 0.5 }
        end, 1)
        KeyPicker.Menu = MenuTable

        local ModeButtons = {}
        for _, Mode in pairs(Info.Modes) do
            local ModeButton = {}

            local Button = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 21),
                Text = Mode,
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = MenuTable.Menu,
            })

            function ModeButton:Select()
                for _, Button in pairs(ModeButtons) do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                Button.BackgroundTransparency = 0
                Button.TextTransparency = 0

                MenuTable:Close()
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil

                Button.BackgroundTransparency = 1
                Button.TextTransparency = 0.5
            end

            Button.MouseButton1Click:Connect(function()
                ModeButton:Select()
            end)

            if KeyPicker.Mode == Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Display(PickerText)
            if Library.Unloaded then
                return
            end

            local X, Y = Library:GetTextBounds(
                PickerText or KeyPicker.DisplayValue,
                Picker.FontFace,
                Picker.TextSize,
                ToggleLabel.AbsoluteSize.X
            )
            Picker.Text = PickerText or KeyPicker.DisplayValue
            Picker.Size = UDim2.fromOffset(X + 9 * Library.DPIScale, Y + 4 * Library.DPIScale)
        end

        function KeyPicker:Update()
            KeyPicker:Display()

            if Info.NoUI then
                return
            end

            if KeyPicker.Mode == "Toggle" and ParentObj.Type == "Toggle" and ParentObj.Disabled then
                KeybindsToggle:SetVisibility(false)
                return
            end

            local State = KeyPicker:GetState()
            local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

            if KeybindsToggle.Loaded then
                if ShowToggle then
                    KeybindsToggle:SetNormal(false)
                else
                    KeybindsToggle:SetNormal(true)
                end

                KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.DisplayValue, KeyPicker.Text, KeyPicker.Mode))
                KeybindsToggle:SetVisibility(true)
                KeybindsToggle:Display(State)
            end

            Library:UpdateKeybindFrame()
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            elseif KeyPicker.Mode == "Hold" then
                local Key = KeyPicker.Value
                if Key == "None" then
                    return false
                end

                if not AreModifiersHeld(KeyPicker.Modifiers) then
                    return false
                end

                if SpecialKeys[Key] ~= nil then
                    return UserInputService:IsMouseButtonPressed(SpecialKeys[Key])
                        and not UserInputService:GetFocusedTextBox()
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[Key]) and not UserInputService:GetFocusedTextBox()
                end
            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:OnChanged(Func)
            KeyPicker.Changed = Func
        end

        function KeyPicker:OnClick(Func)
            KeyPicker.Clicked = Func
        end

        function KeyPicker:DoClick()
            if KeyPicker.Mode == "Press" then
                if KeyPicker.Toggled and Info.WaitForCallback == true then
                    return
                end

                KeyPicker.Toggled = true
            end

            if ParentObj.Type == "Toggle" and KeyPicker.SyncToggleState then
                ParentObj:SetValue(KeyPicker.Toggled)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        function KeyPicker:SetValue(Data)
            local Key, Mode, Modifiers = Data[1], Data[2], Data[3]

            local IsKeyValid, UserInputType = pcall(function()
                if Key == "None" then
                    Key = nil
                    return nil
                end

                if SpecialKeys[Key] == nil then
                    return Enum.KeyCode[Key]
                end

                return SpecialKeys[Key]
            end)

            if Key == nil then
                KeyPicker.Value = "None"
            elseif IsKeyValid then
                KeyPicker.Value = Key
            else
                KeyPicker.Value = "Unknown"
            end

            KeyPicker.Modifiers =
                VerifyModifiers(if typeof(Modifiers) == "table" then Modifiers else KeyPicker.Modifiers)
            KeyPicker.DisplayValue = if GetTableSize(KeyPicker.Modifiers) > 0
                then (table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value)
                else KeyPicker.Value

            if ModeButtons[Mode] then
                ModeButtons[Mode]:Select()
            end

            local NewModifiers = ConvertToInputModifiers(KeyPicker.Modifiers)
            Library:SafeCallback(KeyPicker.ChangedCallback, UserInputType, NewModifiers)
            Library:SafeCallback(KeyPicker.Changed, UserInputType, NewModifiers)

            KeyPicker:Update()
        end

        function KeyPicker:SetText(Text)
            KeybindsToggle:SetText(Text)
            KeyPicker:Update()
        end

        Picker.MouseButton1Click:Connect(function()
            if Picking then
                return
            end

            Picking = true

            Picker.Text = "..."
            Picker.Size = UDim2.fromOffset(29 * Library.DPIScale, 18 * Library.DPIScale)

            -- Wait for an non modifier key --
            local Input
            local ActiveModifiers = {}

            local GetInput = function()
                Input = UserInputService.InputBegan:Wait()
                if UserInputService:GetFocusedTextBox() then
                    return true
                end
            end

            repeat
                task.wait()

                -- Wait for any input --
                Picker.Text = "..."
                Picker.Size = UDim2.fromOffset(29 * Library.DPIScale, 18 * Library.DPIScale)

                if GetInput() then
                    Picking = false
                    KeyPicker:Update()
                    return
                end

                -- Escape --
                if Input.KeyCode == Enum.KeyCode.Escape then
                    break
                end

                -- Handle modifier keys --
                if IsModifierInput(Input) then
                    local StopLoop = false

                    repeat
                        task.wait()
                        if UserInputService:IsKeyDown(Input.KeyCode) then
                            task.wait(0.075)

                            if UserInputService:IsKeyDown(Input.KeyCode) then
                                -- Add modifier to the key list --
                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    ActiveModifiers[#ActiveModifiers + 1] = ModifiersInput[Input.KeyCode]
                                    KeyPicker:Display(table.concat(ActiveModifiers, " + ") .. " + ...")
                                end

                                -- Wait for another input --
                                if GetInput() then
                                    StopLoop = true
                                    break -- Invalid Input
                                end

                                -- Escape --
                                if Input.KeyCode == Enum.KeyCode.Escape then
                                    break
                                end

                                -- Stop loop if its a normal key --
                                if not IsModifierInput(Input) then
                                    break
                                end
                            else
                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    break -- Modifier is meant to be used as a normal key --
                                end
                            end
                        end
                    until false

                    if StopLoop then
                        Picking = false
                        KeyPicker:Update()
                        return
                    end
                end

                break -- Input found, end loop
            until false

            local Key = "Unknown"
            if SpecialKeysInput[Input.UserInputType] ~= nil then
                Key = SpecialKeysInput[Input.UserInputType];
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name;
            end

            ActiveModifiers = if Input.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then {} else ActiveModifiers;

            KeyPicker.Toggled = false
            KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

            -- RunService.RenderStepped:Wait()
            repeat
                task.wait()
            until not IsInputDown(Input) or UserInputService:GetFocusedTextBox()
            Picking = false
        end)
        Picker.MouseButton2Click:Connect(MenuTable.Toggle)

        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
            if Library.Unloaded then
                return
            end
            
            if
                KeyPicker.Mode == "Always"
                or KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            local Key = KeyPicker.Value
            local HoldingModifiers = AreModifiersHeld(KeyPicker.Modifiers)
            local HoldingKey = false

            if
                Key
                and HoldingModifiers == true
                and (
                    SpecialKeysInput[Input.UserInputType] == Key
                    or (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key)
                )
            then
                HoldingKey = true
            end

            if KeyPicker.Mode == "Toggle" then
                if HoldingKey then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                end
            elseif KeyPicker.Mode == "Press" then
                if HoldingKey then
                    KeyPicker:DoClick()
                end
            end

            KeyPicker:Update()
        end))

        Library:GiveSignal(UserInputService.InputEnded:Connect(function()
            if Library.Unloaded then
                return
            end

            if
                KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            KeyPicker:Update()
        end))

        KeyPicker:Update()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        KeyPicker.Default = KeyPicker.Value
        KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers or {})

        Options[Idx] = KeyPicker

        return self
    end

    local HueSequenceTable = {}
    for Hue = 0, 1, 0.1 do
        table.insert(HueSequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
    end
    function Funcs:AddColorPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.ColorPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local ColorPicker = {
            Value = Info.Default,

            Transparency = Info.Transparency or 0,
            Title = Info.Title,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Type = "ColorPicker",
        }
        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

        local Holder = New("TextButton", {
            BackgroundColor3 = ColorPicker.Value,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(20, 20),
            Text = "",
            Parent = ToggleLabel,
        })

        New("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = Holder,
        })

        local HolderStroke = New("UIStroke", {
            Color = Library:GetDarkerColor(ColorPicker.Value),
            Thickness = 1.5,
            Parent = Holder,
        })

        -- Glow effect on hover
        local HolderGlow = New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843",
            ImageColor3 = ColorPicker.Value,
            ImageTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(30, 30),
            ZIndex = 0,
            Parent = Holder,
        })

        local HolderTransparency = New("ImageLabel", {
            Image = CustomImageManager.GetAsset("TransparencyTexture"),
            ImageTransparency = (1 - ColorPicker.Transparency),
            ScaleType = Enum.ScaleType.Tile,
            Size = UDim2.fromScale(1, 1),
            TileSize = UDim2.fromOffset(9, 9),
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = HolderTransparency,
        })

        -- Hover effects
        Holder.MouseEnter:Connect(function()
            TweenService:Create(HolderGlow, Library.HoverTweenInfo, {
                ImageTransparency = 0.6,
            }):Play()
            TweenService:Create(Holder, Library.HoverTweenInfo, {
                Size = UDim2.fromOffset(22, 22),
            }):Play()
        end)

        Holder.MouseLeave:Connect(function()
            TweenService:Create(HolderGlow, Library.HoverTweenInfo, {
                ImageTransparency = 1,
            }):Play()
            TweenService:Create(Holder, Library.HoverTweenInfo, {
                Size = UDim2.fromOffset(20, 20),
            }):Play()
        end)

        --// Color Menu \\--
        local ColorMenu = Library:AddContextMenu(
            Holder,
            UDim2.fromOffset(Info.Transparency and 256 or 234, 0),
            function()
                return { 0.5, Holder.AbsoluteSize.Y + 1.5 }
            end,
            1
        )
        ColorMenu.List.Padding = UDim.new(0, 8)
        ColorPicker.ColorMenu = ColorMenu

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6),
            Parent = ColorMenu.Menu,
        })

        if typeof(ColorPicker.Title) == "string" then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 8),
                Text = ColorPicker.Title,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ColorMenu.Menu,
            })
        end

        local ColorHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 200),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            Parent = ColorHolder,
        })

        --// Sat Map
        local SatVipMap = New("ImageButton", {
            BackgroundColor3 = ColorPicker.Value,
            Image = CustomImageManager.GetAsset("SaturationMap"),
            Size = UDim2.fromOffset(200, 200),
            Parent = ColorHolder,
        })

        local SatVibCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "White",
            Size = UDim2.fromOffset(6, 6),
            Parent = SatVipMap,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = SatVibCursor,
        })
        New("UIStroke", {
            Color = "Dark",
            Parent = SatVibCursor,
        })

        --// Hue
        local HueSelector = New("TextButton", {
            Size = UDim2.fromOffset(16, 200),
            Text = "",
            Parent = ColorHolder,
        })
        New("UIGradient", {
            Color = ColorSequence.new(HueSequenceTable),
            Rotation = 90,
            Parent = HueSelector,
        })

        local HueCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "White",
            BorderColor3 = "Dark",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0.5, ColorPicker.Hue),
            Size = UDim2.new(1, 2, 0, 1),
            Parent = HueSelector,
        })

        --// Alpha
        local TransparencySelector, TransparencyColor, TransparencyCursor
        if Info.Transparency then
            TransparencySelector = New("ImageButton", {
                Image = CustomImageManager.GetAsset("TransparencyTexture"),
                ScaleType = Enum.ScaleType.Tile,
                Size = UDim2.fromOffset(16, 200),
                TileSize = UDim2.fromOffset(8, 8),
                Parent = ColorHolder,
            })

            TransparencyColor = New("Frame", {
                BackgroundColor3 = ColorPicker.Value,
                Size = UDim2.fromScale(1, 1),
                Parent = TransparencySelector,
            })
            New("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = TransparencyColor,
            })

            TransparencyCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "White",
                BorderColor3 = "Dark",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0.5, ColorPicker.Transparency),
                Size = UDim2.new(1, 2, 0, 1),
                Parent = TransparencySelector,
            })
        end

        local InfoHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 8),
            Parent = InfoHolder,
        })

        local HueBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "#??????",
            TextSize = 14,
            Parent = InfoHolder,
        })

        local RgbBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "?, ?, ?",
            TextSize = 14,
            Parent = InfoHolder,
        })

        --// Context Menu \\--
        local ContextMenu = Library:AddContextMenu(Holder, UDim2.fromOffset(93, 0), function()
            return { Holder.AbsoluteSize.X + 1.5, 0.5 }
        end, 1)
        ColorPicker.ContextMenu = ContextMenu
        do
            local function CreateButton(Text, Func)
                local Button = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = Text,
                    TextSize = 14,
                    Parent = ContextMenu.Menu,
                })

                Button.MouseButton1Click:Connect(function()
                    Library:SafeCallback(Func)
                    ContextMenu:Close()
                end)
            end

            CreateButton("Copy color", function()
                Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }
            end)

            ColorPicker.SetValueRGB = function(...) end --// make luau lsp shut up
            CreateButton("Paste color", function()
                ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
            end)

            if setclipboard then
                CreateButton("Copy Hex", function()
                    setclipboard(tostring(ColorPicker.Value:ToHex()))
                end)
                CreateButton("Copy RGB", function()
                    setclipboard(table.concat({
                        math.floor(ColorPicker.Value.R * 255),
                        math.floor(ColorPicker.Value.G * 255),
                        math.floor(ColorPicker.Value.B * 255),
                    }, ", "))
                end)
            end
        end

        --// End \\--

        function ColorPicker:SetHSVFromRGB(Color)
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
        end

        function ColorPicker:Display()
            if Library.Unloaded then
                return
            end

            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

            -- Animated color transitions
            TweenService:Create(Holder, Library.HoverTweenInfo, {
                BackgroundColor3 = ColorPicker.Value,
            }):Play()
            TweenService:Create(HolderStroke, Library.HoverTweenInfo, {
                Color = Library:GetDarkerColor(ColorPicker.Value),
            }):Play()
            TweenService:Create(HolderGlow, Library.HoverTweenInfo, {
                ImageColor3 = ColorPicker.Value,
            }):Play()
            TweenService:Create(HolderTransparency, Library.HoverTweenInfo, {
                ImageTransparency = (1 - ColorPicker.Transparency),
            }):Play()

            TweenService:Create(SatVipMap, Library.HoverTweenInfo, {
                BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1),
            }):Play()
            if TransparencyColor then
                TweenService:Create(TransparencyColor, Library.HoverTweenInfo, {
                    BackgroundColor3 = ColorPicker.Value,
                }):Play()
            end

            -- Animated cursor positions
            TweenService:Create(SatVibCursor, Library.ToggleTweenInfo, {
                Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib),
            }):Play()
            TweenService:Create(HueCursor, Library.ToggleTweenInfo, {
                Position = UDim2.fromScale(0.5, ColorPicker.Hue),
            }):Play()
            if TransparencyCursor then
                TweenService:Create(TransparencyCursor, Library.ToggleTweenInfo, {
                    Position = UDim2.fromScale(0.5, ColorPicker.Transparency),
                }):Play()
            end

            HueBox.Text = "#" .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255),
            }, ", ")
        end

        function ColorPicker:Update()
            ColorPicker:Display()

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
        end

        function ColorPicker:SetValue(HSV, Transparency)
            if typeof(HSV) == "Color3" then
                ColorPicker:SetValueRGB(HSV, Transparency)
                return
            end

            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        Holder.MouseButton1Click:Connect(ColorMenu.Toggle)
        Holder.MouseButton2Click:Connect(ContextMenu.Toggle)

        SatVipMap.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) do
                local MinX = SatVipMap.AbsolutePosition.X
                local MaxX = MinX + SatVipMap.AbsoluteSize.X
                local LocationX = math.clamp(Mouse.X, MinX, MaxX)

                local MinY = SatVipMap.AbsolutePosition.Y
                local MaxY = MinY + SatVipMap.AbsoluteSize.Y
                local LocationY = math.clamp(Mouse.Y, MinY, MaxY)

                local OldSat = ColorPicker.Sat
                local OldVib = ColorPicker.Vib
                ColorPicker.Sat = (LocationX - MinX) / (MaxX - MinX)
                ColorPicker.Vib = 1 - ((LocationY - MinY) / (MaxY - MinY))

                if ColorPicker.Sat ~= OldSat or ColorPicker.Vib ~= OldVib then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        HueSelector.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) do
                local Min = HueSelector.AbsolutePosition.Y
                local Max = Min + HueSelector.AbsoluteSize.Y
                local Location = math.clamp(Mouse.Y, Min, Max)

                local OldHue = ColorPicker.Hue
                ColorPicker.Hue = (Location - Min) / (Max - Min)

                if ColorPicker.Hue ~= OldHue then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        if TransparencySelector then
            TransparencySelector.InputBegan:Connect(function(Input: InputObject)
                while IsDragInput(Input) do
                    local Min = TransparencySelector.AbsolutePosition.Y
                    local Max = TransparencySelector.AbsolutePosition.Y + TransparencySelector.AbsoluteSize.Y
                    local Location = math.clamp(Mouse.Y, Min, Max)

                    local OldTransparency = ColorPicker.Transparency
                    ColorPicker.Transparency = (Location - Min) / (Max - Min)

                    if ColorPicker.Transparency ~= OldTransparency then
                        ColorPicker:Update()
                    end

                    RunService.RenderStepped:Wait()
                end
            end)
        end

        HueBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local Success, Color = pcall(Color3.fromHex, HueBox.Text)
            if Success and typeof(Color) == "Color3" then
                ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
            end

            ColorPicker:Update()
        end)
        RgbBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local R, G, B = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
            if R and G and B then
                ColorPicker:SetHSVFromRGB(Color3.fromRGB(R, G, B))
            end

            ColorPicker:Update()
        end)

        ColorPicker:Display()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, ColorPicker)
        end

        ColorPicker.Default = ColorPicker.Value

        Options[Idx] = ColorPicker

        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddDivider()
        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = New("Frame", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Size = UDim2.new(1, 0, 0, 2),
            Parent = Container,
        })

        Groupbox:Resize()

        table.insert(Groupbox.Elements, {
            Holder = Holder,
            Type = "Divider",
        })
    end

    function Funcs:AddLabel(...)
        local Data = {}
        local Addons = {}

        local First = select(1, ...)
        local Second = select(2, ...)

        if typeof(First) == "table" or typeof(Second) == "table" then
            local Params = typeof(First) == "table" and First or Second

            Data.Text = Params.Text or ""
            Data.DoesWrap = Params.DoesWrap or false
            Data.Size = Params.Size or 14
            Data.Visible = Params.Visible or true
            Data.Color = Params.Color
            Data.Idx = typeof(Second) == "table" and First or nil
            -- New options
            Data.Icon = Params.Icon -- Lucide icon name
            Data.Suffix = Params.Suffix -- Suffix text (right side)
            Data.Animated = Params.Animated -- Pulse animation
            Data.Badge = Params.Badge -- Badge text
            Data.BadgeColor = Params.BadgeColor -- Badge color
        else
            Data.Text = First or ""
            Data.DoesWrap = Second or false
            Data.Size = 14
            Data.Visible = true
            Data.Idx = select(3, ...) or nil
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Label = {
            Text = Data.Text,
            DoesWrap = Data.DoesWrap,

            Color = Data.Color,
            Icon = Data.Icon,
            Suffix = Data.Suffix,
            Animated = Data.Animated,
            Badge = Data.Badge,
            BadgeColor = Data.BadgeColor,

            Addons = Addons,

            Visible = Data.Visible,
            Type = "Label",
        }

        -- Create holder frame for complex labels
        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Parent = Container,
        })

        local TextLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = Data.Icon and UDim2.fromOffset(20, 0) or UDim2.fromOffset(0, 0),
            Size = Data.Icon and UDim2.new(1, -20, 1, 0) or UDim2.fromScale(1, 1),
            Text = Label.Text,
            TextSize = Data.Size,
            TextWrapped = Label.DoesWrap,
            TextXAlignment = Groupbox.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        -- Add icon if specified
        local IconImage
        if Data.Icon then
            local Icon = Library:GetCustomIcon(Data.Icon)
            if Icon then
                IconImage = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Image = Icon.Url,
                    ImageColor3 = "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    Position = UDim2.fromOffset(0, 1),
                    Size = UDim2.fromOffset(16, 16),
                    Parent = Holder,
                })
                Label.IconImage = IconImage
            end
        end

        -- Add suffix if specified
        local SuffixLabel
        if Data.Suffix then
            SuffixLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = Data.Suffix,
                TextSize = Data.Size,
                TextColor3 = Library.Scheme.AccentColor,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = Holder,
            })
            Library.Registry[SuffixLabel] = { TextColor3 = "AccentColor" }
            Label.SuffixLabel = SuffixLabel
        end

        -- Add badge if specified
        local BadgeFrame
        if Data.Badge then
            BadgeFrame = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Data.BadgeColor and Color3.fromHex(Data.BadgeColor) or Library.Scheme.AccentColor,
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(0, 16),
                AutomaticSize = Enum.AutomaticSize.X,
                Parent = Holder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = BadgeFrame,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                Parent = BadgeFrame,
            })
            local BadgeText = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = Data.Badge,
                TextSize = 11,
                TextColor3 = Library.Scheme.BackgroundColor,
                Parent = BadgeFrame,
            })
            Label.BadgeFrame = BadgeFrame
            Label.BadgeText = BadgeText
        end

        -- Add animated pulse effect if specified
        local AnimatedTween
        if Data.Animated then
            local function StartPulse()
                if AnimatedTween then AnimatedTween:Cancel() end
                AnimatedTween = TweenService:Create(TextLabel, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                    TextTransparency = 0.4,
                })
                AnimatedTween:Play()

                if IconImage then
                    TweenService:Create(IconImage, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                        ImageTransparency = 0.4,
                    }):Play()
                end
            end
            StartPulse()
            Label.AnimatedTween = AnimatedTween
        end

        local function ApplyLabelColor(ColorOption)
            if ColorOption == nil then
                return
            end

            local function ClearThemeBinding()
                local ThemeProps = Library.Registry[TextLabel]
                if ThemeProps and ThemeProps.TextColor3 ~= nil then
                    ThemeProps.TextColor3 = nil

                    if GetTableSize(ThemeProps) == 0 then
                        Library.Registry[TextLabel] = nil
                    end
                end
            end

            if typeof(ColorOption) == "Color3" then
                ClearThemeBinding()
                TextLabel.TextColor3 = ColorOption
                return
            end

            if typeof(ColorOption) ~= "string" then
                return
            end

            local Raw = Trim(ColorOption)
            if Raw == "" then
                return
            end

            local Key = Raw:lower()

            local SchemeKey
            if Library.Scheme[Raw] then
                SchemeKey = Raw
            else
                local AliasMap = {
                    accent = "AccentColor",
                    accentcolor = "AccentColor",
                    background = "BackgroundColor",
                    backgroundcolor = "BackgroundColor",
                    main = "MainColor",
                    maincolor = "MainColor",
                    outline = "OutlineColor",
                    outlinecolor = "OutlineColor",
                    font = "FontColor",
                    fontcolor = "FontColor",
                    red = "Red",
                    dark = "Dark",
                    white = "White",
                }

                SchemeKey = AliasMap[Key]
            end

            if SchemeKey and Library.Scheme[SchemeKey] then
                local ThemeProps = Library.Registry[TextLabel] or {}

                TextLabel.TextColor3 = Library.Scheme[SchemeKey]
                ThemeProps.TextColor3 = SchemeKey
                Library.Registry[TextLabel] = ThemeProps
                return
            end

            local NamedColors = {
                green = Color3.fromRGB(50, 205, 50),
                blue = Color3.fromRGB(65, 105, 225),
                yellow = Color3.fromRGB(255, 255, 0),
                orange = Color3.fromRGB(255, 165, 0),
                purple = Color3.fromRGB(180, 80, 255),
                pink = Color3.fromRGB(255, 105, 180),
                cyan = Color3.fromRGB(0, 255, 255),
                magenta = Color3.fromRGB(255, 0, 255),
                teal = Color3.fromRGB(0, 128, 128),
                lime = Color3.fromRGB(0, 255, 0),
                brown = Color3.fromRGB(165, 42, 42),
                grey = Color3.fromRGB(128, 128, 128),
                gray = Color3.fromRGB(128, 128, 128),
                black = Color3.new(0, 0, 0),
            }

            local NamedColor = NamedColors[Key]
            if NamedColor then
                ClearThemeBinding()
                TextLabel.TextColor3 = NamedColor
                return
            end

            local Success, HexColor = pcall(Color3.fromHex, Raw)
            if Success and typeof(HexColor) == "Color3" then
                ClearThemeBinding()
                TextLabel.TextColor3 = HexColor
            end
        end

        ApplyLabelColor(Label.Color)

        function Label:SetVisible(Visible: boolean)
            Label.Visible = Visible

            TextLabel.Visible = Label.Visible
            Groupbox:Resize()
        end

        function Label:SetText(Text: string)
            Label.Text = Text
            TextLabel.Text = Text

            if Label.DoesWrap then
                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4 * Library.DPIScale)
            end

            Groupbox:Resize()
        end

        if Label.DoesWrap then
            local _, Y =
                Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
            TextLabel.Size = UDim2.new(1, 0, 0, Y + 4 * Library.DPIScale)
        else
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 6),
                Parent = TextLabel,
            })
        end

        if Data.DoesWrap then
            local Last = TextLabel.AbsoluteSize

            TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if TextLabel.AbsoluteSize == Last then
                    return
                end

                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4 * Library.DPIScale)

                Last = TextLabel.AbsoluteSize
                Groupbox:Resize()
            end)
        end

        Groupbox:Resize()

        Label.TextLabel = TextLabel
        Label.Container = Container
        if not Data.DoesWrap then
            setmetatable(Label, BaseAddons)
        end

        -- Subtle hover effect for labels
        local OriginalTransparency = TextLabel.TextTransparency
        Holder.MouseEnter:Connect(function()
            if not Data.Animated then
                TweenService:Create(TextLabel, Library.HoverTweenInfo, {
                    TextTransparency = math.max(0, OriginalTransparency - 0.15),
                }):Play()
            end
            if IconImage then
                TweenService:Create(IconImage, Library.HoverTweenInfo, {
                    Size = UDim2.fromOffset(18, 18),
                    Position = UDim2.fromOffset(-1, 0),
                }):Play()
            end
        end)
        Holder.MouseLeave:Connect(function()
            if not Data.Animated then
                TweenService:Create(TextLabel, Library.HoverTweenInfo, {
                    TextTransparency = OriginalTransparency,
                }):Play()
            end
            if IconImage then
                TweenService:Create(IconImage, Library.HoverTweenInfo, {
                    Size = UDim2.fromOffset(16, 16),
                    Position = UDim2.fromOffset(0, 1),
                }):Play()
            end
        end)

        -- New functions for label management
        function Label:SetSuffix(NewSuffix: string)
            if SuffixLabel then
                SuffixLabel.Text = NewSuffix
            end
        end

        function Label:SetBadge(NewBadge: string, NewColor: string?)
            if BadgeFrame then
                Label.BadgeText.Text = NewBadge
                if NewColor then
                    BadgeFrame.BackgroundColor3 = Color3.fromHex(NewColor)
                end
            end
        end

        function Label:SetIcon(NewIcon: string)
            if IconImage then
                local Icon = Library:GetCustomIcon(NewIcon)
                if Icon then
                    IconImage.Image = Icon.Url
                    IconImage.ImageRectOffset = Icon.ImageRectOffset
                    IconImage.ImageRectSize = Icon.ImageRectSize
                end
            end
        end

        function Label:SetAnimated(Enabled: boolean)
            if Enabled then
                if not AnimatedTween then
                    AnimatedTween = TweenService:Create(TextLabel, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                        TextTransparency = 0.4,
                    })
                    AnimatedTween:Play()
                end
            else
                if AnimatedTween then
                    AnimatedTween:Cancel()
                    AnimatedTween = nil
                    TextLabel.TextTransparency = 0
                end
            end
        end

        Label.Holder = Holder
        table.insert(Groupbox.Elements, Label)

        if Data.Idx then
            Labels[Data.Idx] = Label
        else
            table.insert(Labels, Label)
        end

        return Label
    end

    function Funcs:AddParagraph(...)
        local Data = {}
        local First = select(1, ...)
        local Second = select(2, ...)

        if typeof(First) == "table" then
            Data.Text = First.Text or ""
            Data.Size = First.Size or 12
            Data.Color = First.Color
            Data.Icon = First.Icon
            Data.Visible = First.Visible ~= false
            Data.MaxWidth = First.MaxWidth
            Data.Padding = First.Padding or 10
            Data.LineHeight = First.LineHeight or 1.3
            Data.Idx = Second
        else
            Data.Text = First or ""
            Data.Size = Second or 12
            Data.Visible = true
            Data.Padding = 10
            Data.LineHeight = 1.3
            Data.Idx = select(3, ...)
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Paragraph = {
            Text = Data.Text,
            Size = Data.Size,
            Color = Data.Color,
            Icon = Data.Icon,
            Visible = Data.Visible,
            Type = "Paragraph",
        }

        -- Calculate height based on text
        local function CalculateHeight(Text, FontSize, MaxWidth)
            local _, Height = Library:GetTextBounds(Text or "", Font.new("rbxasset://fonts/families/GothamSSm.json"), FontSize, MaxWidth or 250)
            return math.max(Height + Data.Padding * 2, 40)
        end

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, CalculateHeight(Data.Text, Data.Size, Data.MaxWidth)),
            Visible = Paragraph.Visible,
            Parent = Container,
        })

        -- Background box
        local ParagraphBox = New("Frame", {
            BackgroundColor3 = Color3.fromRGB(25, 25, 30),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })
        New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ParagraphBox })
        New("UIStroke", { Color = Color3.fromRGB(40, 40, 50), Thickness = 1, Parent = ParagraphBox })

        -- Content frame with padding
        local ContentFrame = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = ParagraphBox,
        })
        New("UIPadding", {
            PaddingLeft = UDim.new(0, Data.Padding),
            PaddingRight = UDim.new(0, Data.Padding),
            PaddingTop = UDim.new(0, Data.Padding),
            PaddingBottom = UDim.new(0, Data.Padding),
            Parent = ContentFrame,
        })

        -- Icon (optional)
        local IconImage
        if Data.Icon then
            local Icon = Library:GetCustomIcon(Data.Icon)
            if Icon then
                IconImage = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Image = Icon.Url,
                    ImageColor3 = Library.Scheme.AccentColor,
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.fromOffset(20, 20),
                    Parent = ContentFrame,
                })
                Paragraph.IconImage = IconImage
            end
        end

        -- Text label with word wrapping
        local TextLabel = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = Data.Icon and UDim2.fromOffset(28, 0) or UDim2.fromOffset(0, 0),
            Size = Data.Icon and UDim2.new(1, -28, 0, 0) or UDim2.fromScale(1, 1),
            Text = Paragraph.Text,
            TextColor3 = Color3.fromRGB(180, 180, 190),
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
            TextSize = Data.Size,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = ContentFrame,
        })
        Paragraph.TextLabel = TextLabel

        -- Apply color if specified
        local function ApplyParagraphColor(ColorOption)
            if ColorOption == nil then
                return
            end

            if typeof(ColorOption) == "Color3" then
                TextLabel.TextColor3 = ColorOption
                return
            end

            if typeof(ColorOption) ~= "string" then
                return
            end

            local Key = Trim(ColorOption):lower()
            if Library.Scheme[ColorOption] then
                TextLabel.TextColor3 = Library.Scheme[ColorOption]
            else
                local SchemeMap = {
                    accent = "AccentColor", accentcolor = "AccentColor",
                    background = "BackgroundColor", backgroundcolor = "BackgroundColor",
                    main = "MainColor", maincolor = "MainColor",
                    outline = "OutlineColor", outlinecolor = "OutlineColor",
                    font = "FontColor", fontcolor = "FontColor",
                    red = "Red", dark = "Dark", white = "White",
                }
                if SchemeMap[Key] and Library.Scheme[SchemeMap[Key]] then
                    TextLabel.TextColor3 = Library.Scheme[SchemeMap[Key]]
                end
            end
        end

        ApplyParagraphColor(Data.Color)

        -- Methods
        function Paragraph:SetVisible(Visible: boolean)
            Paragraph.Visible = Visible
            Holder.Visible = Visible
            Groupbox:Resize()
        end

        function Paragraph:SetText(NewText: string)
            Paragraph.Text = NewText
            TextLabel.Text = NewText
            local _, Height = Library:GetTextBounds(NewText, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
            Holder.Size = UDim2.new(1, 0, 0, math.max(Height + Data.Padding * 2 + (Data.Icon and 20 or 0), 40))
            Groupbox:Resize()
        end

        function Paragraph:SetColor(NewColor)
            ApplyParagraphColor(NewColor)
        end

        function Paragraph:SetSize(NewSize: number)
            Data.Size = NewSize
            TextLabel.TextSize = NewSize
            local _, Height = Library:GetTextBounds(Paragraph.Text, TextLabel.FontFace, NewSize, TextLabel.AbsoluteSize.X)
            Holder.Size = UDim2.new(1, 0, 0, math.max(Height + Data.Padding * 2 + (Data.Icon and 20 or 0), 40))
            Groupbox:Resize()
        end

        function Paragraph:SetIcon(NewIcon: string)
            if NewIcon then
                local Icon = Library:GetCustomIcon(NewIcon)
                if Icon then
                    if not IconImage then
                        IconImage = New("ImageLabel", {
                            BackgroundTransparency = 1,
                            Image = Icon.Url,
                            ImageColor3 = Library.Scheme.AccentColor,
                            ImageRectOffset = Icon.ImageRectOffset,
                            ImageRectSize = Icon.ImageRectSize,
                            Size = UDim2.fromOffset(20, 20),
                            Parent = ContentFrame,
                        })
                        TextLabel.Position = UDim2.fromOffset(28, 0)
                        TextLabel.Size = UDim2.new(1, -28, 0, 0)
                    else
                        IconImage.Image = Icon.Url
                        IconImage.ImageRectOffset = Icon.ImageRectOffset
                        IconImage.ImageRectSize = Icon.ImageRectSize
                    end
                end
            end
        end

        -- Handle text wrapping and dynamic height
        local AbsoluteSize = TextLabel.AbsoluteSize
        TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if TextLabel.AbsoluteSize ~= AbsoluteSize then
                local _, Height = Library:GetTextBounds(Paragraph.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                Holder.Size = UDim2.new(1, 0, 0, math.max(Height + Data.Padding * 2 + (Data.Icon and 20 or 0), 40))
                AbsoluteSize = TextLabel.AbsoluteSize
                Groupbox:Resize()
            end
        end)

        Paragraph.Holder = Holder
        table.insert(Groupbox.Elements, Paragraph)

        if Data.Idx then
            Paragraphs[Data.Idx] = Paragraph
        else
            table.insert(Paragraphs, Paragraph)
        end

        Groupbox:Resize()
        return Paragraph
    end

    function Funcs:AddDivider(Info)
        Info = Info or {}

        local Groupbox = self
        local Container = Groupbox.Container

        local Divider = {
            Visible = Info.Visible ~= false,
            Text = Info.Text,
            Type = "Divider",
        }

        local height = Info.Text and 20 or 12

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, height),
            Visible = Divider.Visible,
            Parent = Container,
        })

        local Line = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "OutlineColor",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 0, 0, 1),
            Parent = Holder,
        })

        -- Add text in middle if specified
        if Info.Text then
            local TextLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(0, 14),
                Text = "  " .. Info.Text .. "  ",
                TextColor3 = Library.Scheme.OutlineColor,
                TextSize = 12,
                Parent = Holder,
            })
            Library.Registry[TextLabel] = { TextColor3 = "OutlineColor" }
            Divider.TextLabel = TextLabel
        end

        function Divider:SetVisible(Visible: boolean)
            Divider.Visible = Visible
            Holder.Visible = Divider.Visible
            Groupbox:Resize()
        end

        function Divider:SetText(Text: string)
            if Divider.TextLabel then
                Divider.Text = Text
                Divider.TextLabel.Text = "  " .. Text .. "  "
            end
        end

        Groupbox:Resize()

        Divider.Holder = Holder
        table.insert(Groupbox.Elements, Divider)

        return Divider
    end

    function Funcs:AddSpacer(Height)
        Height = Height or 8

        local Groupbox = self
        local Container = Groupbox.Container

        local Spacer = {
            Height = Height,
            Visible = true,
            Type = "Spacer",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Height),
            Visible = true,
            Parent = Container,
        })

        function Spacer:SetVisible(Visible: boolean)
            Spacer.Visible = Visible
            Holder.Visible = Spacer.Visible
            Groupbox:Resize()
        end

        function Spacer:SetHeight(NewHeight: number)
            Spacer.Height = NewHeight
            Holder.Size = UDim2.new(1, 0, 0, NewHeight)
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Spacer.Holder = Holder
        table.insert(Groupbox.Elements, Spacer)

        return Spacer
    end

    function Funcs:AddInfobox(Info)
        Info = Info or {}

        local Groupbox = self
        local Container = Groupbox.Container

        local Infobox = {
            Text = Info.Text or "Info",
            Value = Info.Default,
            DisplayText = Info.DisplayText or (Info.Default ~= nil and tostring(Info.Default) or "---"),
            Callback = Info.Callback,
            Visible = Info.Visible ~= false,
            Disabled = Info.Disabled or false,

            -- Button options
            Button = Info.Button,
            ButtonText = Info.ButtonText or "Action",
            ButtonFunc = Info.ButtonFunc or function() end,
            ButtonIcon = Info.ButtonIcon,

            Type = "Infobox",
        }

        local hasButton = Infobox.Button == true
        local holderHeight = Info.Text and 42 or 26

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, holderHeight),
            Visible = Infobox.Visible,
            Parent = Container,
        })

        -- Label (title)
        local Label
        if Info.Text then
            Label = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = Info.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
        end

        -- Content container (holds infobox and optional button)
        local ContentHolder = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 26),
            Parent = Holder,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = ContentHolder,
        })

        -- Infobox display
        local infoboxWidth = hasButton and 0.65 or 1
        local InfoDisplay = New("Frame", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.new(infoboxWidth, hasButton and -3 or 0, 1, 0),
            Parent = ContentHolder,
        })

        New("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = InfoDisplay,
        })

        local InfoStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = InfoDisplay,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = InfoDisplay,
        })

        local DisplayLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = Infobox.DisplayText,
            TextColor3 = Library.Scheme.FontColor,
            TextSize = 13,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = InfoDisplay,
        })
        Library.Registry[DisplayLabel] = { TextColor3 = "FontColor" }

        -- Copy icon (click to copy value)
        local CopyIcon = Library:GetCustomIcon("copy")
        local CopyButton
        if CopyIcon then
            CopyButton = New("ImageButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Image = CopyIcon.Url,
                ImageColor3 = Library.Scheme.FontColor,
                ImageRectOffset = CopyIcon.ImageRectOffset,
                ImageRectSize = CopyIcon.ImageRectSize,
                ImageTransparency = 0.5,
                Position = UDim2.new(1, 5, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                Parent = InfoDisplay,
            })
            Library.Registry[CopyButton] = { ImageColor3 = "FontColor" }

            CopyButton.MouseEnter:Connect(function()
                TweenService:Create(CopyButton, Library.HoverTweenInfo, {
                    ImageTransparency = 0,
                    ImageColor3 = Library.Scheme.AccentColor,
                }):Play()
            end)

            CopyButton.MouseLeave:Connect(function()
                TweenService:Create(CopyButton, Library.HoverTweenInfo, {
                    ImageTransparency = 0.5,
                    ImageColor3 = Library.Scheme.FontColor,
                }):Play()
            end)

            CopyButton.MouseButton1Click:Connect(function()
                if Infobox.Value ~= nil then
                    pcall(function()
                        setclipboard(tostring(Infobox.Value))
                    end)
                    -- Flash effect
                    TweenService:Create(CopyButton, Library.HoverTweenInfo, {
                        ImageColor3 = Color3.fromRGB(80, 200, 120),
                    }):Play()
                    task.delay(0.3, function()
                        TweenService:Create(CopyButton, Library.HoverTweenInfo, {
                            ImageColor3 = Library.Scheme.AccentColor,
                        }):Play()
                    end)
                end
            end)
        end

        -- Hover effects for infobox
        InfoDisplay.MouseEnter:Connect(function()
            if Infobox.Disabled then return end
            TweenService:Create(InfoStroke, Library.HoverTweenInfo, {
                Color = Library:GetLighterColor(Library.Scheme.OutlineColor),
            }):Play()
            TweenService:Create(InfoDisplay, Library.HoverTweenInfo, {
                BackgroundColor3 = Library:GetLighterColor(Library.Scheme.MainColor),
            }):Play()
        end)

        InfoDisplay.MouseLeave:Connect(function()
            if Infobox.Disabled then return end
            TweenService:Create(InfoStroke, Library.HoverTweenInfo, {
                Color = Library.Scheme.OutlineColor,
            }):Play()
            TweenService:Create(InfoDisplay, Library.HoverTweenInfo, {
                BackgroundColor3 = Library.Scheme.MainColor,
            }):Play()
        end)

        -- Optional button
        local ActionButton, ButtonLabel, ButtonIconImage
        if hasButton then
            ActionButton = New("TextButton", {
                BackgroundColor3 = "AccentColor",
                Size = UDim2.new(0.35, -3, 1, 0),
                Text = "",
                Parent = ContentHolder,
            })

            New("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = ActionButton,
            })

            local ButtonStroke = New("UIStroke", {
                Color = "AccentColor",
                Transparency = 0.5,
                Parent = ActionButton,
            })

            -- Button content layout
            local ButtonContent = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Parent = ActionButton,
            })

            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 4),
                Parent = ButtonContent,
            })

            -- Button icon
            if Infobox.ButtonIcon then
                local BtnIcon = Library:GetCustomIcon(Infobox.ButtonIcon)
                if BtnIcon then
                    ButtonIconImage = New("ImageLabel", {
                        BackgroundTransparency = 1,
                        Image = BtnIcon.Url,
                        ImageColor3 = Library.Scheme.BackgroundColor,
                        ImageRectOffset = BtnIcon.ImageRectOffset,
                        ImageRectSize = BtnIcon.ImageRectSize,
                        Size = UDim2.fromOffset(12, 12),
                        LayoutOrder = 1,
                        Parent = ButtonContent,
                    })
                    Library.Registry[ButtonIconImage] = { ImageColor3 = "BackgroundColor" }
                end
            end

            -- Button text
            ButtonLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 14),
                Text = Infobox.ButtonText,
                TextColor3 = Library.Scheme.BackgroundColor,
                TextSize = 13,
                LayoutOrder = 2,
                Parent = ButtonContent,
            })
            Library.Registry[ButtonLabel] = { TextColor3 = "BackgroundColor" }

            -- Button hover effects
            ActionButton.MouseEnter:Connect(function()
                if Infobox.Disabled then return end
                TweenService:Create(ActionButton, Library.HoverTweenInfo, {
                    BackgroundColor3 = Library:GetLighterColor(Library.Scheme.AccentColor),
                }):Play()
            end)

            ActionButton.MouseLeave:Connect(function()
                if Infobox.Disabled then return end
                TweenService:Create(ActionButton, Library.HoverTweenInfo, {
                    BackgroundColor3 = Library.Scheme.AccentColor,
                }):Play()
            end)

            -- Button click
            ActionButton.MouseButton1Click:Connect(function()
                if Infobox.Disabled then return end

                -- Click animation
                TweenService:Create(ActionButton, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {
                    Size = UDim2.new(0.35, -5, 1, -2),
                }):Play()
                task.delay(0.1, function()
                    TweenService:Create(ActionButton, Library.HoverTweenInfo, {
                        Size = UDim2.new(0.35, -3, 1, 0),
                    }):Play()
                end)

                Library:SafeCallback(Infobox.ButtonFunc, Infobox.Value)
            end)

            Infobox.ActionButton = ActionButton
            Infobox.ButtonLabel = ButtonLabel
        end

        -- Functions
        function Infobox:SetValue(NewValue, NewDisplayText)
            Infobox.Value = NewValue
            if NewDisplayText then
                Infobox.DisplayText = tostring(NewDisplayText)
            else
                Infobox.DisplayText = NewValue ~= nil and tostring(NewValue) or "---"
            end
            DisplayLabel.Text = Infobox.DisplayText

            if Infobox.Callback then
                Library:SafeCallback(Infobox.Callback, Infobox.Value)
            end
        end

        function Infobox:GetValue()
            return Infobox.Value
        end

        function Infobox:SetDisplayText(NewText)
            Infobox.DisplayText = tostring(NewText)
            DisplayLabel.Text = Infobox.DisplayText
        end

        function Infobox:SetButtonText(NewText)
            if ButtonLabel then
                Infobox.ButtonText = NewText
                ButtonLabel.Text = NewText
            end
        end

        function Infobox:SetDisabled(Disabled)
            Infobox.Disabled = Disabled
            DisplayLabel.TextTransparency = Disabled and 0.5 or 0
            if Label then
                Label.TextTransparency = Disabled and 0.5 or 0
            end
            if ActionButton then
                ActionButton.Active = not Disabled
                ActionButton.BackgroundTransparency = Disabled and 0.5 or 0
            end
        end

        function Infobox:SetVisible(Visible)
            Infobox.Visible = Visible
            Holder.Visible = Visible
            Groupbox:Resize()
        end

        function Infobox:OnChanged(Func)
            Infobox.Callback = Func
        end

        Groupbox:Resize()

        Infobox.Holder = Holder
        Infobox.DisplayLabel = DisplayLabel
        Infobox.InfoDisplay = InfoDisplay
        table.insert(Groupbox.Elements, Infobox)

        return Infobox
    end

    function Funcs:AddButton(...)
        local function GetInfo(...)
            local Info = {}

            local First = select(1, ...)
            local Second = select(2, ...)

            if typeof(First) == "table" or typeof(Second) == "table" then
                local Params = typeof(First) == "table" and First or Second

                Info.Text = Params.Text or ""
                Info.Func = Params.Func or function() end
                Info.DoubleClick = Params.DoubleClick

                Info.Tooltip = Params.Tooltip
                Info.DisabledTooltip = Params.DisabledTooltip

                Info.Risky = Params.Risky or false
                Info.Disabled = Params.Disabled or false
                Info.Visible = Params.Visible or true
                Info.Idx = typeof(Second) == "table" and First or nil

                -- New options
                Info.Icon = Params.Icon -- Lucide icon name
                Info.IconRight = Params.IconRight -- Place icon on right side
                Info.Variant = Params.Variant -- "Default", "Accent", "Success", "Warning", "Danger"
                Info.Loading = Params.Loading -- Loading state
                Info.Compact = Params.Compact -- Compact mode (icon only)
            else
                Info.Text = First or ""
                Info.Func = Second or function() end
                Info.DoubleClick = false

                Info.Tooltip = nil
                Info.DisabledTooltip = nil

                Info.Risky = false
                Info.Disabled = false
                Info.Visible = true
                Info.Idx = select(3, ...) or nil
            end

            return Info
        end
        local Info = GetInfo(...)

        local Groupbox = self
        local Container = Groupbox.Container

        local Button = {
            Text = Info.Text,
            Func = Info.Func,
            DoubleClick = Info.DoubleClick,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            -- New properties
            Icon = Info.Icon,
            IconRight = Info.IconRight,
            Variant = Info.Variant or "Default",
            Loading = Info.Loading or false,
            Compact = Info.Compact or false,

            Tween = nil,
            Type = "Button",
        }

        -- Variant colors
        local VariantColors = {
            Default = { bg = "MainColor", text = "FontColor", hover = nil },
            Accent = { bg = "AccentColor", text = "BackgroundColor", hover = nil },
            Success = { bg = Color3.fromRGB(40, 167, 69), text = Color3.new(1, 1, 1), hover = Color3.fromRGB(50, 190, 85) },
            Warning = { bg = Color3.fromRGB(255, 193, 7), text = Color3.fromRGB(20, 20, 20), hover = Color3.fromRGB(255, 210, 50) },
            Danger = { bg = Color3.fromRGB(220, 53, 69), text = Color3.new(1, 1, 1), hover = Color3.fromRGB(240, 70, 85) },
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 21),
            Parent = Container,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 9),
            Parent = Holder,
        })

        local function CreateButton(Button)
            local VariantStyle = VariantColors[Button.Variant] or VariantColors.Default
            local bgColor = VariantStyle.bg
            local textColor = VariantStyle.text

            -- Convert scheme key strings to actual Color3 values
            local function GetColor(colorValue)
                if typeof(colorValue) == "string" then
                    return Library.Scheme[colorValue] or Library.Scheme.FontColor
                end
                return colorValue
            end

            local actualBgColor = GetColor(bgColor)
            local actualTextColor = GetColor(textColor)

            local Base = New("TextButton", {
                Active = not Button.Disabled and not Button.Loading,
                BackgroundColor3 = Button.Disabled and Library.Scheme.BackgroundColor or actualBgColor,
                ClipsDescendants = true,
                Size = Button.Compact and UDim2.fromOffset(24, 21) or UDim2.fromScale(1, 1),
                Text = (Button.Icon and not Button.Compact) and "" or (Button.Compact and "" or Button.Text),
                TextSize = 14,
                TextTransparency = Button.Disabled and 0.8 or (Button.Variant == "Default" and 0.4 or 0),
                TextColor3 = actualTextColor,
                Visible = Button.Visible,
                Parent = Holder,
            })

            -- Register color for theme support
            if typeof(bgColor) == "string" then
                Library.Registry[Base] = Library.Registry[Base] or {}
                Library.Registry[Base].BackgroundColor3 = Button.Disabled and "BackgroundColor" or bgColor
            end
            if typeof(textColor) == "string" then
                Library.Registry[Base] = Library.Registry[Base] or {}
                Library.Registry[Base].TextColor3 = textColor
            end

            New("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = Base,
            })

            local strokeColor = Button.Variant == "Default" and Library.Scheme.OutlineColor or (typeof(bgColor) == "Color3" and bgColor or Library.Scheme.AccentColor)
            local Stroke = New("UIStroke", {
                Color = strokeColor,
                Transparency = Button.Disabled and 0.5 or (Button.Variant == "Default" and 0 or 0.5),
                Thickness = 1,
                Parent = Base,
            })
            if Button.Variant == "Default" then
                Library.Registry[Stroke] = Library.Registry[Stroke] or {}
                Library.Registry[Stroke].Color = "OutlineColor"
            end

            -- Subtle gradient overlay for depth
            local GradientOverlay = New("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.95,
                Size = UDim2.new(1, 0, 0.5, 0),
                ZIndex = 0,
                Parent = Base,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = GradientOverlay,
            })
            New("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Rotation = 90,
                Parent = GradientOverlay,
            })

            -- Glow effect on hover (initially invisible)
            local ButtonGlow = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://6015897843",
                ImageColor3 = Button.Variant == "Default" and Library.Scheme.AccentColor or actualBgColor,
                ImageTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(49, 49, 450, 450),
                Size = UDim2.new(1, 12, 1, 12),
                ZIndex = -1,
                Parent = Base,
            })
            Button.Glow = ButtonGlow

            -- Add icon if specified
            local IconImage, IconContainer
            if Button.Icon then
                local Icon = Library:GetCustomIcon(Button.Icon)
                if Icon then
                    local iconSize = 14

                    if not Button.Compact then
                        -- Container for icon + text layout
                        IconContainer = New("Frame", {
                            BackgroundTransparency = 1,
                            Size = UDim2.fromScale(1, 1),
                            Parent = Base,
                        })

                        New("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(0, 6),
                            Parent = IconContainer,
                        })

                        -- Create icon (left side)
                        if not Button.IconRight then
                            IconImage = New("ImageLabel", {
                                BackgroundTransparency = 1,
                                Image = Icon.Url,
                                ImageColor3 = actualTextColor,
                                ImageRectOffset = Icon.ImageRectOffset,
                                ImageRectSize = Icon.ImageRectSize,
                                Size = UDim2.fromOffset(iconSize, iconSize),
                                LayoutOrder = 1,
                                Parent = IconContainer,
                            })
                            if typeof(textColor) == "string" then
                                Library.Registry[IconImage] = { ImageColor3 = textColor }
                            end
                        end

                        -- Create text label
                        local TextLabel = New("TextLabel", {
                            BackgroundTransparency = 1,
                            AutomaticSize = Enum.AutomaticSize.X,
                            Size = UDim2.fromOffset(0, iconSize),
                            Text = Button.Text,
                            TextSize = 14,
                            TextColor3 = actualTextColor,
                            TextTransparency = Button.Disabled and 0.8 or (Button.Variant == "Default" and 0.4 or 0),
                            LayoutOrder = 2,
                            Parent = IconContainer,
                        })
                        if typeof(textColor) == "string" then
                            Library.Registry[TextLabel] = { TextColor3 = textColor }
                        end
                        Button.TextLabel = TextLabel

                        -- Create icon (right side)
                        if Button.IconRight then
                            IconImage = New("ImageLabel", {
                                BackgroundTransparency = 1,
                                Image = Icon.Url,
                                ImageColor3 = actualTextColor,
                                ImageRectOffset = Icon.ImageRectOffset,
                                ImageRectSize = Icon.ImageRectSize,
                                Size = UDim2.fromOffset(iconSize, iconSize),
                                LayoutOrder = 3,
                                Parent = IconContainer,
                            })
                            if typeof(textColor) == "string" then
                                Library.Registry[IconImage] = { ImageColor3 = textColor }
                            end
                        end
                    else
                        -- Compact mode - icon only, centered
                        IconImage = New("ImageLabel", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundTransparency = 1,
                            Image = Icon.Url,
                            ImageColor3 = actualTextColor,
                            ImageRectOffset = Icon.ImageRectOffset,
                            ImageRectSize = Icon.ImageRectSize,
                            Position = UDim2.fromScale(0.5, 0.5),
                            Size = UDim2.fromOffset(iconSize, iconSize),
                            Parent = Base,
                        })
                        if typeof(textColor) == "string" then
                            Library.Registry[IconImage] = { ImageColor3 = textColor }
                        end
                    end
                end
            end

            -- Loading spinner
            local LoadingSpinner
            if Button.Loading then
                LoadingSpinner = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://4965945816",
                    ImageColor3 = actualTextColor,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(14, 14),
                    Visible = true,
                    Parent = Base,
                })
                if typeof(textColor) == "string" then
                    Library.Registry[LoadingSpinner] = { ImageColor3 = textColor }
                end

                -- Animate spinner
                local spinTween = TweenService:Create(LoadingSpinner, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
                    Rotation = 360,
                })
                spinTween:Play()
                Button.SpinTween = spinTween

                -- Hide text/icon while loading
                if IconContainer then IconContainer.Visible = false end
                if IconImage and not IconContainer then IconImage.Visible = false end
                Base.Text = ""
            end

            Button.IconImage = IconImage
            Button.IconContainer = IconContainer
            Button.LoadingSpinner = LoadingSpinner
            Button.VariantStyle = VariantStyle
            Button.GetColor = GetColor

            local PressDepth = 0

            local function BeginPress()
                if Button.Disabled or Button.Locked then
                    return
                end

                PressDepth += 1
                if PressDepth == 1 then
                    -- Store old color using attribute instead of custom property
                    local oldColor = Base.TextColor3
                    Base:SetAttribute("_NeonOldTextColor_R", oldColor.R)
                    Base:SetAttribute("_NeonOldTextColor_G", oldColor.G)
                    Base:SetAttribute("_NeonOldTextColor_B", oldColor.B)
                    Base.TextColor3 = NeonAccentColor
                end
            end

            local function EndPress()
                if Button.Disabled or Button.Locked then
                    return
                end

                if PressDepth == 0 then
                    return
                end

                PressDepth -= 1
                if PressDepth == 0 then
                    local r = Base:GetAttribute("_NeonOldTextColor_R")
                    local g = Base:GetAttribute("_NeonOldTextColor_G")
                    local b = Base:GetAttribute("_NeonOldTextColor_B")
                    if r and g and b then
                        Base.TextColor3 = Color3.new(r, g, b)
                        Base:SetAttribute("_NeonOldTextColor_R", nil)
                        Base:SetAttribute("_NeonOldTextColor_G", nil)
                        Base:SetAttribute("_NeonOldTextColor_B", nil)
                    end
                end
            end

            Base.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) then
                    return
                end

                BeginPress()
            end)

            Base.InputEnded:Connect(function(Input)
                if not IsClickInput(Input) then
                    return
                end

                EndPress()
            end)

            return Base, Stroke
        end

        local function InitEvents(Button)
            Button.Base.MouseEnter:Connect(function()
                if Button.Disabled or Button.Loading then
                    return
                end

                local VariantStyle = Button.VariantStyle or VariantColors.Default
                local bgColor = VariantStyle.bg
                local hoverColor = VariantStyle.hover

                -- Calculate hover color
                local targetBgColor
                if hoverColor then
                    targetBgColor = hoverColor
                elseif typeof(bgColor) == "string" then
                    targetBgColor = Library:GetLighterColor(Library.Scheme[bgColor] or Library.Scheme.MainColor)
                else
                    targetBgColor = Library:GetLighterColor(bgColor)
                end

                local tweenProps = {
                    BackgroundColor3 = targetBgColor,
                }

                -- Only animate text transparency for default variant
                if Button.Variant == "Default" or not Button.Variant then
                    tweenProps.TextTransparency = 0
                    if Button.TextLabel then
                        TweenService:Create(Button.TextLabel, Library.HoverTweenInfo, { TextTransparency = 0 }):Play()
                    end
                end

                -- Scale up icon slightly on hover
                if Button.IconImage then
                    TweenService:Create(Button.IconImage, Library.HoverTweenInfo, {
                        Size = UDim2.fromOffset(16, 16),
                    }):Play()
                end

                -- Show glow effect
                if Button.Glow then
                    TweenService:Create(Button.Glow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                        ImageTransparency = 0.85,
                    }):Play()
                end

                -- Animate stroke
                if Button.Stroke then
                    TweenService:Create(Button.Stroke, Library.HoverTweenInfo, {
                        Transparency = 0,
                        Color = Library.Scheme.AccentColor,
                    }):Play()
                end

                Button.Tween = TweenService:Create(Button.Base, Library.HoverTweenInfo, tweenProps)
                Button.Tween:Play()
            end)
            Button.Base.MouseLeave:Connect(function()
                if Button.Disabled or Button.Loading then
                    return
                end

                local VariantStyle = Button.VariantStyle or VariantColors.Default
                local bgColor = VariantStyle.bg

                local targetBgColor
                if typeof(bgColor) == "string" then
                    targetBgColor = Library.Scheme[bgColor] or Library.Scheme.MainColor
                else
                    targetBgColor = bgColor
                end

                local tweenProps = {
                    BackgroundColor3 = targetBgColor,
                }

                -- Only animate text transparency for default variant
                if Button.Variant == "Default" or not Button.Variant then
                    tweenProps.TextTransparency = 0.4
                    if Button.TextLabel then
                        TweenService:Create(Button.TextLabel, Library.HoverTweenInfo, { TextTransparency = 0.4 }):Play()
                    end
                end

                -- Scale icon back down
                if Button.IconImage then
                    TweenService:Create(Button.IconImage, Library.HoverTweenInfo, {
                        Size = UDim2.fromOffset(14, 14),
                    }):Play()
                end

                -- Hide glow effect
                if Button.Glow then
                    TweenService:Create(Button.Glow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                        ImageTransparency = 1,
                    }):Play()
                end

                -- Reset stroke
                if Button.Stroke then
                    local strokeColor = Button.Variant == "Default" and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
                    TweenService:Create(Button.Stroke, Library.HoverTweenInfo, {
                        Transparency = Button.Variant == "Default" and 0 or 0.5,
                        Color = strokeColor,
                    }):Play()
                end

                Button.Tween = TweenService:Create(Button.Base, Library.HoverTweenInfo, tweenProps)
                Button.Tween:Play()
            end)

            Button.Base.MouseButton1Click:Connect(function()
                if Button.Disabled or Button.Locked then
                    return
                end

                -- Create ripple effect on click
                local ClickPos = Vector2.new(Mouse.X, Mouse.Y)
                Library:CreateRippleEffect(Button.Base, ClickPos)

                if Button.DoubleClick then
                    Button.Locked = true

                    Button.Base.Text = "Are you sure?"
                    Button.Base.TextColor3 = Library.Scheme.AccentColor
                    Library.Registry[Button.Base].TextColor3 = "AccentColor"

                    local Clicked = WaitForEvent(Button.Base.MouseButton1Click, 0.5)

                    Button.Base.Text = Button.Text
                    Button.Base.TextColor3 = Button.Risky and Library.Scheme.Red or Library.Scheme.FontColor
                    Library.Registry[Button.Base].TextColor3 = Button.Risky and "Red" or "FontColor"

                    if Clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    RunService.RenderStepped:Wait() --// Mouse Button fires without waiting (i hate roblox)
                    Button.Locked = false
                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Base, Button.Stroke = CreateButton(Button)
        InitEvents(Button)

        function Button:AddButton(...)
            local Info = GetInfo(...)

            local SubButton = {
                Text = Info.Text,
                Func = Info.Func,
                DoubleClick = Info.DoubleClick,

                Tooltip = Info.Tooltip,
                DisabledTooltip = Info.DisabledTooltip,
                TooltipTable = nil,

                Risky = Info.Risky,
                Disabled = Info.Disabled,
                Visible = Info.Visible,

                Tween = nil,
                Type = "SubButton",
            }

            Button.SubButton = SubButton
            SubButton.Base, SubButton.Stroke = CreateButton(SubButton)
            InitEvents(SubButton)

            function SubButton:UpdateColors()
                if Library.Unloaded then
                    return
                end

                StopTween(SubButton.Tween)

                SubButton.Base.BackgroundColor3 = SubButton.Disabled and Library.Scheme.BackgroundColor
                    or Library.Scheme.MainColor
                SubButton.Base.TextTransparency = SubButton.Disabled and 0.8 or 0.4
                SubButton.Stroke.Transparency = SubButton.Disabled and 0.5 or 0

                Library.Registry[SubButton.Base].BackgroundColor3 = SubButton.Disabled and "BackgroundColor"
                    or "MainColor"
            end

            function SubButton:SetDisabled(Disabled: boolean)
                SubButton.Disabled = Disabled

                if SubButton.TooltipTable then
                    SubButton.TooltipTable.Disabled = SubButton.Disabled
                end

                SubButton.Base.Active = not SubButton.Disabled
                SubButton:UpdateColors()
            end

            function SubButton:SetVisible(Visible: boolean)
                SubButton.Visible = Visible

                SubButton.Base.Visible = SubButton.Visible
                Groupbox:Resize()
            end

            function SubButton:SetText(Text: string)
                SubButton.Text = Text
                SubButton.Base.Text = Text
            end

            if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                SubButton.TooltipTable =
                    Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            if SubButton.Risky then
                SubButton.Base.TextColor3 = Library.Scheme.Red
                Library.Registry[SubButton.Base].TextColor3 = "Red"
            end

            SubButton:UpdateColors()

            if Info.Idx then
                Buttons[Info.Idx] = SubButton
            else
                table.insert(Buttons, SubButton)
            end

            return SubButton
        end

        function Button:UpdateColors()
            if Library.Unloaded then
                return
            end

            StopTween(Button.Tween)

            Button.Base.BackgroundColor3 = Button.Disabled and Library.Scheme.BackgroundColor
                or Library.Scheme.MainColor
            Button.Base.TextTransparency = Button.Disabled and 0.8 or 0.4
            Button.Stroke.Transparency = Button.Disabled and 0.5 or 0

            Library.Registry[Button.Base].BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor"
        end

        function Button:SetDisabled(Disabled: boolean)
            Button.Disabled = Disabled

            if Button.TooltipTable then
                Button.TooltipTable.Disabled = Button.Disabled
            end

            Button.Base.Active = not Button.Disabled
            Button:UpdateColors()
        end

        function Button:SetVisible(Visible: boolean)
            Button.Visible = Visible

            Holder.Visible = Button.Visible
            Groupbox:Resize()
        end

        function Button:SetText(Text: string)
            Button.Text = Text
            if Button.TextLabel then
                Button.TextLabel.Text = Text
            else
                Button.Base.Text = Text
            end
        end

        function Button:SetLoading(IsLoading: boolean)
            Button.Loading = IsLoading
            Button.Base.Active = not Button.Disabled and not Button.Loading

            if IsLoading then
                -- Create spinner if not exists
                if not Button.LoadingSpinner then
                    local textColor = Button.VariantStyle and Button.VariantStyle.text or "FontColor"
                    Button.LoadingSpinner = New("ImageLabel", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://4965945816",
                        ImageColor3 = typeof(textColor) == "string" and textColor or textColor,
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(14, 14),
                        Visible = true,
                        Parent = Button.Base,
                    })
                    if typeof(textColor) == "string" then
                        Library.Registry[Button.LoadingSpinner] = Library.Registry[Button.LoadingSpinner] or {}
                        Library.Registry[Button.LoadingSpinner].ImageColor3 = textColor
                    end

                    Button.SpinTween = TweenService:Create(Button.LoadingSpinner, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
                        Rotation = 360,
                    })
                    Button.SpinTween:Play()
                else
                    Button.LoadingSpinner.Visible = true
                    if Button.SpinTween then Button.SpinTween:Play() end
                end

                -- Hide content
                if Button.IconContainer then Button.IconContainer.Visible = false end
                if Button.IconImage and not Button.IconContainer then Button.IconImage.Visible = false end
                if Button.TextLabel then
                    Button.TextLabel.Visible = false
                else
                    Button.Base.Text = ""
                end
            else
                -- Hide spinner
                if Button.LoadingSpinner then
                    Button.LoadingSpinner.Visible = false
                    if Button.SpinTween then Button.SpinTween:Cancel() end
                end

                -- Show content
                if Button.IconContainer then Button.IconContainer.Visible = true end
                if Button.IconImage and not Button.IconContainer then Button.IconImage.Visible = true end
                if Button.TextLabel then
                    Button.TextLabel.Visible = true
                else
                    Button.Base.Text = Button.Text
                end
            end
        end

        function Button:SetIcon(IconName: string)
            local Icon = Library:GetCustomIcon(IconName)
            if Icon and Button.IconImage then
                Button.Icon = IconName
                Button.IconImage.Image = Icon.Url
                Button.IconImage.ImageRectOffset = Icon.ImageRectOffset
                Button.IconImage.ImageRectSize = Icon.ImageRectSize
            end
        end

        if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
            Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
            Button.TooltipTable.Disabled = Button.Disabled
        end

        if Button.Risky then
            Button.Base.TextColor3 = Library.Scheme.Red
            Library.Registry[Button.Base].TextColor3 = "Red"
        end

        Button:UpdateColors()
        Groupbox:Resize()

        Button.Holder = Holder
        table.insert(Groupbox.Elements, Button)

        if Info.Idx then
            Buttons[Info.Idx] = Button
        else
            table.insert(Buttons, Button)
        end

        return Button
    end

    function Funcs:AddCheckbox(Idx, Info)
        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},

            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(26, 0),
            Size = UDim2.new(1, -26, 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

        local Checkbox = New("Frame", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Button,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = Checkbox,
        })

        local CheckboxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Checkbox,
        })

        local CheckImage = New("ImageLabel", {
            Image = CheckIcon and CheckIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 1,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = Checkbox,
        })

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            CheckboxStroke.Transparency = Toggle.Disabled and 0.5 or 0

            if Toggle.Disabled then
                Label.TextTransparency = 0.8
                CheckImage.ImageTransparency = Toggle.Value and 0.8 or 1

                Checkbox.BackgroundColor3 = Library.Scheme.BackgroundColor
                Library.Registry[Checkbox].BackgroundColor3 = "BackgroundColor"

                return
            end

            TweenService:Create(Label, Library.HoverTweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(CheckImage, Library.ToggleTweenInfo, {
                ImageTransparency = Toggle.Value and 0 or 1,
                ImageColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.FontColor,
            }):Play()
            TweenService:Create(Checkbox, Library.HoverTweenInfo, {
                BackgroundColor3 = Toggle.Value and Library:GetLighterColor(Library.Scheme.MainColor) or Library.Scheme.MainColor,
            }):Play()

            Checkbox.BackgroundColor3 = Library.Scheme.MainColor
            Library.Registry[Checkbox].BackgroundColor3 = "MainColor"
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
            Library:UpdateDependencyBoxes()
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end)

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.Red
            Library.Registry[Label].TextColor3 = "Red"
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        return Toggle
    end

    function Funcs:AddToggle(Idx, Info)
        if Library.ForceCheckbox then
            return Funcs.AddCheckbox(self, Idx, Info)
        end

        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},

            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -40, 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

        local Switch = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = "MainColor",
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(36, 20),
            Parent = Button,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Switch,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3),
            PaddingTop = UDim.new(0, 3),
            Parent = Switch,
        })
        local SwitchStroke = New("UIStroke", {
            Color = "OutlineColor",
            Thickness = 1,
            Parent = Switch,
        })

        -- Glow effect for switch when enabled
        local SwitchGlow = New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843",
            ImageColor3 = "AccentColor",
            ImageTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 16, 1, 16),
            ZIndex = 0,
            Parent = Switch,
        })

        local Ball = New("Frame", {
            BackgroundColor3 = "FontColor",
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Switch,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Ball,
        })

        -- Ball shadow
        local BallShadow = New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843",
            ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 0.8,
            Position = UDim2.new(0.5, 0, 0.5, 2),
            Size = UDim2.new(1, 4, 1, 4),
            ZIndex = 0,
            Parent = Ball,
        })

        -- Hover effect variables
        local isHovering = false

        Button.MouseEnter:Connect(function()
            if Toggle.Disabled then return end
            isHovering = true
            TweenService:Create(Label, Library.HoverTweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.2,
            }):Play()
            TweenService:Create(Switch, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(38, 22),
            }):Play()
            TweenService:Create(SwitchStroke, Library.HoverTweenInfo, {
                Color = Library.Scheme.AccentColor,
                Transparency = 0,
            }):Play()
            TweenService:Create(SwitchGlow, Library.HoverTweenInfo, {
                ImageTransparency = Toggle.Value and 0.6 or 0.85,
            }):Play()
        end)

        Button.MouseLeave:Connect(function()
            if Toggle.Disabled then return end
            isHovering = false
            TweenService:Create(Label, Library.HoverTweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(Switch, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                Size = UDim2.fromOffset(36, 20),
            }):Play()
            TweenService:Create(SwitchStroke, Library.HoverTweenInfo, {
                Color = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor,
                Transparency = 0,
            }):Play()
            TweenService:Create(SwitchGlow, Library.HoverTweenInfo, {
                ImageTransparency = Toggle.Value and 0.7 or 1,
            }):Play()
        end)

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            local Offset = Toggle.Value and 1 or 0

            Switch.BackgroundTransparency = Toggle.Disabled and 0.75 or 0
            SwitchStroke.Transparency = Toggle.Disabled and 0.75 or 0

            Switch.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor
            SwitchStroke.Color = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor

            Library.Registry[Switch].BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
            Library.Registry[SwitchStroke].Color = Toggle.Value and "AccentColor" or "OutlineColor"

            -- Animate glow effect
            TweenService:Create(SwitchGlow, Library.ToggleTweenInfo, {
                ImageTransparency = Toggle.Value and 0.7 or 1,
            }):Play()

            if Toggle.Disabled then
                Label.TextTransparency = 0.8
                Ball.AnchorPoint = Vector2.new(Offset, 0)
                Ball.Position = UDim2.fromScale(Offset, 0)
                SwitchGlow.ImageTransparency = 1

                Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
                Library.Registry[Ball].BackgroundColor3 = function()
                    return Library:GetDarkerColor(Library.Scheme.FontColor)
                end

                return
            end

            TweenService:Create(Label, Library.HoverTweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(Ball, Library.ToggleTweenInfo, {
                AnchorPoint = Vector2.new(Offset, 0),
                Position = UDim2.fromScale(Offset, 0),
                Size = Toggle.Value and UDim2.new(1, -2, 1, -2) or UDim2.new(0.85, -2, 0.85, -2),
            }):Play()
            TweenService:Create(Switch, Library.HoverTweenInfo, {
                BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor,
            }):Play()

            Ball.BackgroundColor3 = Library.Scheme.FontColor
            Library.Registry[Ball].BackgroundColor3 = "FontColor"
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
            Library:UpdateDependencyBoxes()
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end)

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.Red
            Library.Registry[Label].TextColor3 = "Red"
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        return Toggle
    end

    function Funcs:AddInput(Idx, Info)
        Info = Library:Validate(Info, Templates.Input)

        local Groupbox = self
        local Container = Groupbox.Container

        local Input = {
            Text = Info.Text,
            Value = Info.Default,

            Finished = Info.Finished,
            Numeric = Info.Numeric,
            ClearTextOnFocus = Info.ClearTextOnFocus,
            Placeholder = Info.Placeholder,
            AllowEmpty = Info.AllowEmpty,
            EmptyReset = Info.EmptyReset,

            -- AutoComplete options
            AutoComplete = Info.AutoComplete or false,
            CompleteOptions = Info.CompleteOptions or {},
            MaxSuggestions = Info.MaxSuggestions or 5,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Input",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 42),
            Visible = Input.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = Input.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        local Box = New("TextBox", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 0,
            ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
            PlaceholderText = Input.Placeholder,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 24),
            Text = Input.Value,
            TextEditable = not Input.Disabled,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        New("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = Box,
        })

        local BoxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Box,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        -- Focus glow effect
        local FocusGlow = New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843",
            ImageColor3 = "AccentColor",
            ImageTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 20, 1, 20),
            ZIndex = 0,
            Parent = Box,
        })

        -- Hover effect
        Box.MouseEnter:Connect(function()
            if Input.Disabled then return end
            TweenService:Create(BoxStroke, Library.HoverTweenInfo, {
                Color = Library:GetLighterColor(Library.Scheme.OutlineColor),
            }):Play()
            TweenService:Create(Label, Library.HoverTweenInfo, {
                TextTransparency = 0,
            }):Play()
        end)

        Box.MouseLeave:Connect(function()
            if Input.Disabled then return end
            TweenService:Create(BoxStroke, Library.HoverTweenInfo, {
                Color = Library.Scheme.OutlineColor,
            }):Play()
            TweenService:Create(Label, Library.HoverTweenInfo, {
                TextTransparency = Input.Disabled and 0.8 or 0,
            }):Play()
        end)

        Input.BoxStroke = BoxStroke
        Input.FocusGlow = FocusGlow

        -- AutoComplete System (Enhanced Design)
        local ACMenu, ACList, ACButtons, ACSelectedIndex, ACStroke, ACGlow
        local ACVisible = false

        if Input.AutoComplete then
            ACButtons = {}
            ACSelectedIndex = 0

            -- Menu frame with enhanced design
            ACMenu = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(200, 0),
                Visible = false,
                ZIndex = 50,
                Parent = ScreenGui,
            })

            New("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = ACMenu,
            })

            ACStroke = New("UIStroke", {
                Color = "AccentColor",
                Transparency = 0.7,
                Thickness = 1.5,
                Parent = ACMenu,
            })

            -- Soft glow behind menu
            ACGlow = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://6015897843",
                ImageColor3 = "AccentColor",
                ImageTransparency = 0.85,
                Position = UDim2.fromScale(0.5, 0.5),
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(49, 49, 450, 450),
                Size = UDim2.new(1, 24, 1, 24),
                ZIndex = 49,
                Parent = ACMenu,
            })

            -- Gradient overlay for depth
            local ACGradient = New("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.97,
                Size = UDim2.new(1, 0, 0, 20),
                ZIndex = 51,
                Parent = ACMenu,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = ACGradient,
            })
            New("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Rotation = 90,
                Parent = ACGradient,
            })

            -- List container
            ACList = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.fromScale(1, 1),
                ClipsDescendants = true,
                ZIndex = 52,
                Parent = ACMenu,
            })

            New("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = ACList,
            })

            New("UIPadding", {
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 6),
                Parent = ACList,
            })

            Input.AutoCompleteMenu = ACMenu
        end

        -- Helper functions
        local function ACHide()
            if not ACMenu then return end
            ACVisible = false
            ACSelectedIndex = 0

            -- Animate out
            TweenService:Create(ACMenu, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
                Size = UDim2.fromOffset(ACMenu.Size.X.Offset, 0),
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(ACStroke, TweenInfo.new(0.15), {
                Transparency = 1,
            }):Play()
            TweenService:Create(ACGlow, TweenInfo.new(0.15), {
                ImageTransparency = 1,
            }):Play()

            task.delay(0.15, function()
                if not ACVisible and ACMenu then
                    ACMenu.Visible = false
                end
            end)
        end

        local function ACSelect(index)
            if not ACButtons or #ACButtons == 0 then return end
            index = ((index - 1) % #ACButtons) + 1

            -- Reset previous with animation
            if ACSelectedIndex > 0 and ACSelectedIndex <= #ACButtons then
                local prev = ACButtons[ACSelectedIndex]
                if prev then
                    TweenService:Create(prev.Button, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Library.Scheme.MainColor,
                        BackgroundTransparency = 0,
                    }):Play()
                    TweenService:Create(prev.Label, TweenInfo.new(0.15), {
                        TextColor3 = Library.Scheme.FontColor,
                    }):Play()
                    if prev.Icon then
                        TweenService:Create(prev.Icon, TweenInfo.new(0.15), {
                            ImageColor3 = Library.Scheme.FontColor,
                            ImageTransparency = 0.5,
                        }):Play()
                    end
                end
            end

            ACSelectedIndex = index
            local btn = ACButtons[index]
            if btn then
                TweenService:Create(btn.Button, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
                    BackgroundColor3 = Library.Scheme.AccentColor,
                    BackgroundTransparency = 0,
                }):Play()
                TweenService:Create(btn.Label, TweenInfo.new(0.15), {
                    TextColor3 = Library.Scheme.BackgroundColor,
                }):Play()
                if btn.Icon then
                    TweenService:Create(btn.Icon, TweenInfo.new(0.15), {
                        ImageColor3 = Library.Scheme.BackgroundColor,
                        ImageTransparency = 0,
                    }):Play()
                end
            end
        end

        local function ACConfirm()
            if ACSelectedIndex > 0 and ACSelectedIndex <= #ACButtons then
                local btn = ACButtons[ACSelectedIndex]
                if btn then
                    Box.Text = btn.Value
                    Input:SetValue(btn.Value)
                    ACHide()
                end
            end
        end

        local function ACShow(matches)
            if not ACMenu or not ACList or #matches == 0 then
                ACHide()
                return
            end

            -- Clear existing
            for _, btn in ipairs(ACButtons or {}) do
                if btn.Button then btn.Button:Destroy() end
            end
            ACButtons = {}
            ACSelectedIndex = 0

            -- Create buttons with enhanced design
            for i, match in ipairs(matches) do
                local btnData = { Value = match }

                local Btn = New("TextButton", {
                    BackgroundColor3 = Library.Scheme.MainColor,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 32),
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = i,
                    ZIndex = 53,
                    Parent = ACList,
                })
                Library.Registry[Btn] = { BackgroundColor3 = "MainColor" }
                btnData.Button = Btn

                New("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = Btn,
                })

                -- Search icon
                local Icon = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Image = Library:GetCustomIcon("search") or "rbxassetid://3926305904",
                    ImageColor3 = Library.Scheme.FontColor,
                    ImageTransparency = 0.5,
                    Position = UDim2.new(0, 10, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    ZIndex = 54,
                    Parent = Btn,
                })
                Library.Registry[Icon] = { ImageColor3 = "FontColor" }
                btnData.Icon = Icon

                local Lbl = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(32, 0),
                    Size = UDim2.new(1, -42, 1, 0),
                    Text = match,
                    TextColor3 = Library.Scheme.FontColor,
                    TextSize = 13,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 54,
                    Parent = Btn,
                })
                Library.Registry[Lbl] = { TextColor3 = "FontColor" }
                btnData.Label = Lbl

                -- Hover effects
                Btn.MouseEnter:Connect(function()
                    ACSelect(i)
                end)

                Btn.MouseLeave:Connect(function()
                    if ACSelectedIndex == i then
                        TweenService:Create(Btn, TweenInfo.new(0.1), {
                            BackgroundColor3 = Library.Scheme.MainColor,
                        }):Play()
                        TweenService:Create(Lbl, TweenInfo.new(0.1), {
                            TextColor3 = Library.Scheme.FontColor,
                        }):Play()
                        TweenService:Create(Icon, TweenInfo.new(0.1), {
                            ImageColor3 = Library.Scheme.FontColor,
                            ImageTransparency = 0.5,
                        }):Play()
                        ACSelectedIndex = 0
                    end
                end)

                Btn.MouseButton1Click:Connect(function()
                    Box.Text = match
                    Input:SetValue(match)
                    ACHide()
                end)

                table.insert(ACButtons, btnData)
            end

            -- Position and animate
            local absPos = Box.AbsolutePosition
            local absSize = Box.AbsoluteSize
            local itemH = 32
            local padding = 12
            local spacing = 4
            local maxItems = math.min(#matches, Input.MaxSuggestions)
            local menuH = (itemH * maxItems) + (spacing * (maxItems - 1)) + padding

            ACMenu.Position = UDim2.fromOffset(
                math.floor(absPos.X),
                math.floor(absPos.Y + absSize.Y + 4)
            )
            ACMenu.Size = UDim2.fromOffset(math.floor(absSize.X), 0)
            ACMenu.BackgroundTransparency = 1
            ACMenu.Visible = true
            ACVisible = true

            -- Animate in with bounce
            TweenService:Create(ACMenu, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(math.floor(absSize.X), menuH),
                BackgroundTransparency = 0,
            }):Play()
            TweenService:Create(ACStroke, TweenInfo.new(0.2), {
                Transparency = 0.7,
            }):Play()
            TweenService:Create(ACGlow, TweenInfo.new(0.3), {
                ImageTransparency = 0.85,
            }):Play()
        end

        local function ACUpdate(text)
            if not Input.AutoComplete or not ACMenu then return end

            if text == "" or #Input.CompleteOptions == 0 then
                ACHide()
                return
            end

            local matches = {}
            local lower = text:lower()
            for _, opt in ipairs(Input.CompleteOptions) do
                local s = tostring(opt)
                if s:lower():find(lower, 1, true) then
                    table.insert(matches, s)
                    if #matches >= Input.MaxSuggestions then break end
                end
            end

            ACShow(matches)
        end

        -- Events
        if Input.AutoComplete then
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                if Box:IsFocused() then ACUpdate(Box.Text) end
            end)

            Box.Focused:Connect(function()
                task.defer(function()
                    if #Box.Text > 0 then ACUpdate(Box.Text) end
                end)
            end)

            Box.FocusLost:Connect(function()
                task.delay(0.2, function()
                    if ACVisible then ACHide() end
                end)
            end)

            UserInputService.InputBegan:Connect(function(input)
                if not ACVisible or not Box:IsFocused() then return end
                if input.KeyCode == Enum.KeyCode.Down then
                    ACSelect(ACSelectedIndex + 1)
                elseif input.KeyCode == Enum.KeyCode.Up then
                    ACSelect(ACSelectedIndex - 1)
                elseif input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.Return then
                    if ACSelectedIndex > 0 then
                        ACConfirm()
                    elseif #ACButtons > 0 then
                        ACSelect(1)
                        ACConfirm()
                    end
                elseif input.KeyCode == Enum.KeyCode.Escape then
                    ACHide()
                end
            end)

            Box:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                if ACVisible and ACMenu then
                    local absPos = Box.AbsolutePosition
                    local absSize = Box.AbsoluteSize
                    ACMenu.Position = UDim2.fromOffset(
                        math.floor(absPos.X),
                        math.floor(absPos.Y + absSize.Y + 4)
                    )
                end
            end)
        end

        -- API
        function Input:SetCompleteOptions(opts)
            Input.CompleteOptions = opts or {}
            if Box:IsFocused() and #Box.Text > 0 then ACUpdate(Box.Text) end
        end

        function Input:AddCompleteOption(opt)
            table.insert(Input.CompleteOptions, opt)
        end

        function Input:RemoveCompleteOption(opt)
            for i, v in ipairs(Input.CompleteOptions) do
                if tostring(v) == tostring(opt) then
                    table.remove(Input.CompleteOptions, i)
                    break
                end
            end
        end

        function Input:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Input.Disabled and 0.8 or 0
            Box.TextTransparency = Input.Disabled and 0.8 or 0
        end

        function Input:OnChanged(Func)
            Input.Changed = Func
        end

        function Input:SetValue(Text)
            if not Input.AllowEmpty and Trim(Text) == "" then
                Text = Input.EmptyReset
            end

            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Input.Numeric then
                if #tostring(Text) > 0 and not tonumber(Text) then
                    Text = Input.Value
                end
            end

            Input.Value = Text
            Box.Text = Text

            if not Input.Disabled then
                Library:SafeCallback(Input.Callback, Input.Value)
                Library:SafeCallback(Input.Changed, Input.Value)
            end
        end

        function Input:SetDisabled(Disabled: boolean)
            Input.Disabled = Disabled

            if Input.TooltipTable then
                Input.TooltipTable.Disabled = Input.Disabled
            end

            Box.ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus
            Box.TextEditable = not Input.Disabled
            Input:UpdateColors()

            if Disabled then
                if FocusTween then
                    StopTween(FocusTween)
                    FocusTween = nil
                end

                if not Library.Unloaded and Box and Box.Parent then
                    Box.TextColor3 = Library.Scheme.FontColor
                    Box.BorderColor3 = Library.Scheme.OutlineColor
                end
            end
        end

        function Input:SetVisible(Visible: boolean)
            Input.Visible = Visible

            Holder.Visible = Input.Visible
            Groupbox:Resize()
        end

        function Input:SetText(Text: string)
            Input.Text = Text
            Label.Text = Text
        end

        local NeonInputTextColor = NeonAccentColor

        local FocusTween
        local BackgroundTween

        local function SetFocusVisual(IsFocused)
            if Library.Unloaded or not Box or not Box.Parent then
                return
            end

            local TargetTextColor = IsFocused and NeonInputTextColor or Library.Scheme.FontColor
            local TargetStrokeColor = IsFocused and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
            local TargetBackgroundColor = IsFocused and Library:GetLighterColor(Library.Scheme.MainColor) or Library.Scheme.MainColor
            local TargetGlowTransparency = IsFocused and 0.7 or 1

            if FocusTween then
                StopTween(FocusTween)
                FocusTween = nil
            end
            if BackgroundTween then
                StopTween(BackgroundTween)
                BackgroundTween = nil
            end

            FocusTween = TweenService:Create(Box, Library.HoverTweenInfo, {
                TextColor3 = TargetTextColor,
            })
            BackgroundTween = TweenService:Create(Box, Library.FadeTweenInfo, {
                BackgroundColor3 = TargetBackgroundColor,
            })

            -- Animate stroke color
            TweenService:Create(BoxStroke, Library.HoverTweenInfo, {
                Color = TargetStrokeColor,
            }):Play()

            -- Animate glow effect
            TweenService:Create(FocusGlow, Library.FadeTweenInfo, {
                ImageTransparency = TargetGlowTransparency,
            }):Play()

            FocusTween:Play()
            BackgroundTween:Play()
        end

        -- Desktop + mobile both fire Focused/FocusLost on TextBox, so
        -- this works for keyboard and touch inputs.
        Box.Focused:Connect(function()
            if Input.Disabled then
                return
            end

            SetFocusVisual(true)
        end)

        if Input.Finished then
            -- In "Finished" mode, commit the value whenever focus is lost so it
            -- behaves consistently on desktop and mobile (where users often tap
            -- outside instead of pressing Enter).
            Box.FocusLost:Connect(function()
                SetFocusVisual(false)
                Input:SetValue(Box.Text)
            end)
        else
            Box.FocusLost:Connect(function()
                SetFocusVisual(false)
            end)

            Box:GetPropertyChangedSignal("Text"):Connect(function()
                Input:SetValue(Box.Text)
            end)
        end

        if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
            Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
            Input.TooltipTable.Disabled = Input.Disabled
        end

        Groupbox:Resize()

        Input.Holder = Holder
        table.insert(Groupbox.Elements, Input)

        Input.Default = Input.Value

        Options[Idx] = Input

        return Input
    end

    function Funcs:AddSlider(Idx, Info)
        Info = Library:Validate(Info, Templates.Slider)

        local Groupbox = self
        local Container = Groupbox.Container

        local Slider = {
            Text = Info.Text,
            Value = Info.Default,

            Min = Info.Min,
            Max = Info.Max,

            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            Compact = Info.Compact,
            Rounding = Info.Rounding or 0,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Slider",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Compact and 13 or 31),
            Visible = Slider.Visible,
            Parent = Container,
        })

        local SliderLabel
        if not Info.Compact then
            SliderLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = Slider.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
        end

        local Bar = New("TextButton", {
            Active = not Slider.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 14),
            Text = "",
            ClipsDescendants = true,
            Parent = Holder,
        })

        New("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = Bar,
        })

        local BarStroke = New("UIStroke", {
            Color = "OutlineColor",
            Thickness = 1,
            Parent = Bar,
        })

        local DisplayLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = 14,
            ZIndex = 3,
            Parent = Bar,
        })
        New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            Color = "Dark",
            LineJoinMode = Enum.LineJoinMode.Miter,
            Parent = DisplayLabel,
        })

        local Fill = New("Frame", {
            BackgroundColor3 = "AccentColor",
            Size = UDim2.fromScale(0.5, 1),
            Parent = Bar,

            DPIExclude = {
                Size = true,
            },
        })

        New("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = Fill,
        })

        -- Fill glow effect
        local FillGlow = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = "AccentColor",
            BackgroundTransparency = 0.5,
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.new(0.5, 0, 1, 6),
            ZIndex = 0,
            Parent = Bar,

            DPIExclude = {
                Size = true,
            },
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = FillGlow,
        })

        -- Slider thumb/handle (circular design)
        local Thumb = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "FontColor",
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            ZIndex = 2,
            Parent = Bar,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Thumb,
        })
        local ThumbStroke = New("UIStroke", {
            Color = "AccentColor",
            Thickness = 2,
            Transparency = 0.5,
            Parent = Thumb,
        })

        -- Thumb inner dot
        local ThumbDot = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "AccentColor",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(6, 6),
            ZIndex = 3,
            Parent = Thumb,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = ThumbDot,
        })

        -- Thumb glow
        local ThumbGlow = New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843",
            ImageColor3 = "AccentColor",
            ImageTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.5),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            Size = UDim2.fromOffset(28, 28),
            ZIndex = 1,
            Parent = Thumb,
        })

        -- Thumb shadow
        local ThumbShadow = New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843",
            ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 0.8,
            Position = UDim2.new(0.5, 0, 0.5, 2),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            Size = UDim2.fromOffset(20, 20),
            ZIndex = 0,
            Parent = Thumb,
        })

        -- Hover effects
        local isDragging = false

        Bar.MouseEnter:Connect(function()
            if Slider.Disabled then return end
            TweenService:Create(Thumb, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(20, 20),
            }):Play()
            TweenService:Create(ThumbDot, Library.HoverTweenInfo, {
                Size = UDim2.fromOffset(8, 8),
            }):Play()
            TweenService:Create(ThumbGlow, Library.HoverTweenInfo, {
                ImageTransparency = 0.7,
            }):Play()
            TweenService:Create(ThumbStroke, Library.HoverTweenInfo, {
                Transparency = 0,
            }):Play()
            TweenService:Create(BarStroke, Library.HoverTweenInfo, {
                Color = Library.Scheme.AccentColor,
            }):Play()
            if SliderLabel then
                TweenService:Create(SliderLabel, Library.HoverTweenInfo, {
                    TextTransparency = 0,
                }):Play()
            end
        end)

        Bar.MouseLeave:Connect(function()
            if Slider.Disabled or isDragging then return end
            TweenService:Create(Thumb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                Size = UDim2.fromOffset(16, 16),
            }):Play()
            TweenService:Create(ThumbDot, Library.HoverTweenInfo, {
                Size = UDim2.fromOffset(6, 6),
            }):Play()
            TweenService:Create(ThumbGlow, Library.HoverTweenInfo, {
                ImageTransparency = 1,
            }):Play()
            TweenService:Create(ThumbStroke, Library.HoverTweenInfo, {
                Transparency = 0.5,
            }):Play()
            TweenService:Create(BarStroke, Library.HoverTweenInfo, {
                Color = Library.Scheme.OutlineColor,
            }):Play()
            if SliderLabel then
                TweenService:Create(SliderLabel, Library.HoverTweenInfo, {
                    TextTransparency = Slider.Disabled and 0.8 or 0,
                }):Play()
            end
        end)

        Slider.Thumb = Thumb
        Slider.ThumbGlow = ThumbGlow
        Slider.ThumbDot = ThumbDot
        Slider.FillGlow = FillGlow
        Slider.BarStroke = BarStroke

        function Slider:UpdateColors()
            if Library.Unloaded then
                return
            end

            if SliderLabel then
                SliderLabel.TextTransparency = Slider.Disabled and 0.8 or 0
            end
            DisplayLabel.TextTransparency = Slider.Disabled and 0.8 or 0

            Fill.BackgroundColor3 = Slider.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
            Library.Registry[Fill].BackgroundColor3 = Slider.Disabled and "OutlineColor" or "AccentColor"

            -- Update thumb visibility
            Thumb.BackgroundTransparency = Slider.Disabled and 0.5 or 0
            FillGlow.BackgroundTransparency = Slider.Disabled and 0.9 or 0.5
        end

        function Slider:Display()
            if Library.Unloaded then
                return
            end

            local CustomDisplayText = nil
            if Info.FormatDisplayValue then
                CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
            end

            if CustomDisplayText then
                DisplayLabel.Text = tostring(CustomDisplayText)
            else
                if Info.Compact then
                    DisplayLabel.Text = Slider.Text .. ": " .. Slider.Prefix .. tostring(Slider.Value) .. Slider.Suffix
                elseif Info.HideMax then
                    DisplayLabel.Text = Slider.Prefix .. tostring(Slider.Value) .. Slider.Suffix
                else
                    DisplayLabel.Text = Slider.Prefix .. tostring(Slider.Value) .. Slider.Suffix .. "/" .. Slider.Prefix .. tostring(Slider.Max) .. Slider.Suffix
                end
            end

            local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            TweenService:Create(Fill, Library.HoverTweenInfo, {
                Size = UDim2.fromScale(X, 1),
            }):Play()

            -- Animate thumb position
            TweenService:Create(Thumb, Library.HoverTweenInfo, {
                Position = UDim2.new(X, 0, 0.5, 0),
            }):Play()

            -- Animate fill glow
            TweenService:Create(FillGlow, Library.HoverTweenInfo, {
                Size = UDim2.new(X, 0, 1, 6),
            }):Play()
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
        end

        function Slider:SetMax(Value)
            assert(Value > Slider.Min, "Max value cannot be less than the current min value.")
    
            Slider:SetValue(math.clamp(Slider.Value, Slider.Min, Value)) --this will make  so it updates. and im calling this so i dont need to add an if :P
            Slider.Max = Value
            Slider:Display()
        end

        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")
    
            Slider:SetValue(math.clamp(Slider.Value, Value, Slider.Max)) --same here. adding these comments for the funny
            Slider.Min = Value
            Slider:Display()
        end

        function Slider:SetValue(Str)
            if Slider.Disabled then
                return
            end

            local Num = tonumber(Str)
            if not Num or Num == Slider.Value then
                return
            end

            Num = math.clamp(Num, Slider.Min, Slider.Max)

            Slider.Value = Num
            Slider:Display()

            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        function Slider:SetDisabled(Disabled: boolean)
            Slider.Disabled = Disabled

            if Slider.TooltipTable then
                Slider.TooltipTable.Disabled = Slider.Disabled
            end

            Bar.Active = not Slider.Disabled
            Slider:UpdateColors()
        end

        function Slider:SetVisible(Visible: boolean)
            Slider.Visible = Visible

            Holder.Visible = Slider.Visible
            Groupbox:Resize()
        end

        function Slider:SetText(Text: string)
            Slider.Text = Text
            if SliderLabel then
                SliderLabel.Text = Text
                return
            end
            Slider:Display()
        end

        function Slider:SetPrefix(Prefix: string)
            Slider.Prefix = Prefix
            Slider:Display()
        end

        function Slider:SetSuffix(Suffix: string)
            Slider.Suffix = Suffix
            Slider:Display()
        end

        local IsDraggingSlider = false

        Bar.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) or Slider.Disabled then
                return
            end

            IsDraggingSlider = true

            for _, Side in pairs(Library.ActiveTab.Sides) do
                Side.ScrollingEnabled = false
            end
        end)

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
            if not IsDraggingSlider or Slider.Disabled or not Bar.Visible then
                return
            end

            -- Allow mouse movement and touch input while dragging
            if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            local Location = Mouse.X
            local BarPos = Bar.AbsolutePosition.X
            local BarSize = Bar.AbsoluteSize.X

            if BarSize == 0 then
                return
            end

            local Scale = math.clamp((Location - BarPos) / BarSize, 0, 1)

            local OldValue = Slider.Value
            Slider.Value = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

            Slider:Display()
            if Slider.Value ~= OldValue then
                Library:SafeCallback(Slider.Callback, Slider.Value)
                Library:SafeCallback(Slider.Changed, Slider.Value)
            end
        end))

        Library:GiveSignal(UserInputService.InputEnded:Connect(function(Input: InputObject)
            if IsMouseInput(Input) then
                IsDraggingSlider = false

                for _, Side in pairs(Library.ActiveTab.Sides) do
                    Side.ScrollingEnabled = true
                end
            end
        end))

        if typeof(Slider.Tooltip) == "string" or typeof(Slider.DisabledTooltip) == "string" then
            Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, Slider.DisabledTooltip, Bar)
            Slider.TooltipTable.Disabled = Slider.Disabled
        end

        Slider:UpdateColors()
        Slider:Display()
        Groupbox:Resize()

        Slider.Holder = Holder
        table.insert(Groupbox.Elements, Slider)

        Slider.Default = Slider.Value

        Options[Idx] = Slider

        return Slider
    end

    function Funcs:AddDropdown(Idx, Info)
        Info = Library:Validate(Info, Templates.Dropdown)

        local Groupbox = self
        local Container = Groupbox.Container

        if Info.SpecialType == "Player" then
            Info.Values = GetPlayers(Info.ExcludeLocalPlayer)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams()
            Info.AllowNull = true
        end

        local Dropdown = {
            Text = typeof(Info.Text) == "string" and Info.Text or nil,
            Value = Info.Multi and {} or nil,
            Values = Info.Values,
            DisabledValues = Info.DisabledValues,
            Multi = Info.Multi,

            SpecialType = Info.SpecialType,
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Dropdown",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Dropdown.Text and 42 or 24),
            Visible = Dropdown.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = Dropdown.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not not Info.Text,
            Parent = Holder,
        })

        local Display = New("TextButton", {
            Active = not Dropdown.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 24),
            Text = "---",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        New("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = Display,
        })

        local DisplayStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Display,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 6),
            Parent = Display,
        })

        -- Arrow container with background
        local ArrowContainer = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = "OutlineColor",
            BackgroundTransparency = 0.8,
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(20, 16),
            Parent = Display,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, 3),
            Parent = ArrowContainer,
        })

        local ArrowImage = New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = ArrowIcon and ArrowIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(14, 14),
            Parent = ArrowContainer,
        })

        -- Hover effects
        Display.MouseEnter:Connect(function()
            if Dropdown.Disabled then return end
            TweenService:Create(DisplayStroke, Library.HoverTweenInfo, {
                Color = Library:GetLighterColor(Library.Scheme.OutlineColor),
            }):Play()
            TweenService:Create(ArrowContainer, Library.HoverTweenInfo, {
                BackgroundTransparency = 0.6,
            }):Play()
            TweenService:Create(Label, Library.HoverTweenInfo, {
                TextTransparency = 0,
            }):Play()
        end)

        Display.MouseLeave:Connect(function()
            if Dropdown.Disabled then return end
            TweenService:Create(DisplayStroke, Library.HoverTweenInfo, {
                Color = Library.Scheme.OutlineColor,
            }):Play()
            TweenService:Create(ArrowContainer, Library.HoverTweenInfo, {
                BackgroundTransparency = 0.8,
            }):Play()
            TweenService:Create(Label, Library.HoverTweenInfo, {
                TextTransparency = Dropdown.Disabled and 0.8 or 0,
            }):Play()
        end)

        local SearchBox
        if Info.Searchable then
            SearchBox = New("TextBox", {
                BackgroundTransparency = 1,
                PlaceholderText = "Search...",
                Position = UDim2.fromOffset(-8, 0),
                Size = UDim2.new(1, -12, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = false,
                Parent = Display,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                Parent = SearchBox,
            })
        end

        local MenuTable = Library:AddContextMenu(
            Display,
            function()
                return UDim2.fromOffset(Display.AbsoluteSize.X, 0)
            end,
            function()
                return { 0.5, Display.AbsoluteSize.Y + 2 }
            end,
            2,
            function(Active: boolean)
                Display.TextTransparency = (Active and SearchBox) and 1 or 0

                -- Animated arrow rotation and transparency
                TweenService:Create(ArrowImage, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    ImageTransparency = Active and 0 or 0.5,
                    Rotation = Active and 180 or 0,
                }):Play()

                -- Arrow container accent highlight
                TweenService:Create(ArrowContainer, Library.HoverTweenInfo, {
                    BackgroundColor3 = Active and Library.Scheme.AccentColor or Library.Scheme.OutlineColor,
                    BackgroundTransparency = Active and 0.3 or 0.8,
                }):Play()

                -- Arrow color change
                TweenService:Create(ArrowImage, Library.HoverTweenInfo, {
                    ImageColor3 = Active and Library.Scheme.AccentColor or Library.Scheme.FontColor,
                }):Play()

                -- Stroke highlight
                TweenService:Create(DisplayStroke, Library.HoverTweenInfo, {
                    Color = Active and Library.Scheme.AccentColor or Library.Scheme.OutlineColor,
                }):Play()

                -- Animated display background
                TweenService:Create(Display, Library.HoverTweenInfo, {
                    BackgroundColor3 = Active and Library:GetLighterColor(Library.Scheme.MainColor) or Library.Scheme.MainColor,
                }):Play()

                if SearchBox then
                    SearchBox.Text = ""
                    SearchBox.Visible = Active
                end
            end
        )
        Dropdown.Menu = MenuTable
        Library:UpdateDPI(MenuTable.Menu, {
            Position = false,
            Size = false,
        })

        function Dropdown:RecalculateListSize(Count)
            local Y = math.clamp(
                (Count or GetTableSize(Dropdown.Values)) * (21 * Library.DPIScale),
                0,
                Info.MaxVisibleDropdownItems * (21 * Library.DPIScale)
            )

            MenuTable:SetSize(function()
                return UDim2.fromOffset(Display.AbsoluteSize.X, Y)
            end)
        end

        function Dropdown:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Dropdown.Disabled and 0.8 or 0
            Display.TextTransparency = Dropdown.Disabled and 0.8 or 0
            ArrowImage.ImageTransparency = Dropdown.Disabled and 0.8 or MenuTable.Active and 0 or 0.5
        end

        function Dropdown:Display()
            if Library.Unloaded then
                return
            end

            local Str = ""

            if Info.Multi then
                for _, Value in pairs(Dropdown.Values) do
                    if Dropdown.Value[Value] then
                        Str = Str
                            .. (Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(Value)) or tostring(Value))
                            .. ", "
                    end
                end

                Str = Str:sub(1, #Str - 2)
            else
                Str = Dropdown.Value and tostring(Dropdown.Value) or ""
                if Str ~= "" and Info.FormatDisplayValue then
                    Str = tostring(Info.FormatDisplayValue(Str))
                end
            end

            if #Str > 25 then
                Str = Str:sub(1, 22) .. "..."
            end

            Display.Text = (Str == "" and "---" or Str)
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local Table = {}

                for Value, _ in pairs(Dropdown.Value) do
                    table.insert(Table, Value)
                end

                return Table
            end

            return Dropdown.Value and 1 or 0
        end

        local Buttons = {}
        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local DisabledValues = Dropdown.DisabledValues

            for Button, _ in pairs(Buttons) do
                Button:Destroy()
            end
            table.clear(Buttons)

            local Count = 0
            for _, Value in pairs(Values) do
                if SearchBox and not tostring(Value):lower():match(SearchBox.Text:lower()) then
                    continue
                end

                Count += 1
                local IsDisabled = table.find(DisabledValues, Value)
                local Table = {}

                local Button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 1,
                    LayoutOrder = IsDisabled and 1 or 0,
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = tostring(Value),
                    TextSize = 14,
                    TextTransparency = 0.5,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = MenuTable.Menu,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    Parent = Button,
                })

                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end

                    TweenService:Create(Button, Library.HoverTweenInfo, {
                        BackgroundTransparency = Selected and 0 or 1,
                        TextTransparency = IsDisabled and 0.8 or Selected and 0 or 0.5,
                        BackgroundColor3 = Selected and Library.Scheme.AccentColor or Library.Scheme.MainColor,
                        TextColor3 = Selected and Library.Scheme.BackgroundColor or Library.Scheme.FontColor,
                    }):Play()
                end

                -- Hover effects for dropdown items
                if not IsDisabled then
                    Button.MouseEnter:Connect(function()
                        if not Selected then
                            TweenService:Create(Button, Library.HoverTweenInfo, {
                                BackgroundTransparency = 0.7,
                                TextTransparency = 0.2,
                            }):Play()
                        end
                    end)
                    Button.MouseLeave:Connect(function()
                        if not Selected then
                            TweenService:Create(Button, Library.HoverTweenInfo, {
                                BackgroundTransparency = 1,
                                TextTransparency = 0.5,
                            }):Play()
                        end
                    end)
                    Button.MouseButton1Click:Connect(function()
                        local Try = not Selected

                        if not (Dropdown:GetActiveValues() == 1 and not Try and not Info.AllowNull) then
                            Selected = Try
                            if Info.Multi then
                                Dropdown.Value[Value] = Selected and true or nil
                            else
                                Dropdown.Value = Selected and Value or nil
                            end

                            for _, OtherButton in pairs(Buttons) do
                                OtherButton:UpdateButton()
                            end
                        end

                        Table:UpdateButton()
                        Dropdown:Display()

                        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                        Library:UpdateDependencyBoxes()
                    end)
                end

                Table:UpdateButton()
                Dropdown:Display()

                Buttons[Button] = Table
            end

            Dropdown:RecalculateListSize(Count)
        end

        function Dropdown:SetValue(Value)
            if Info.Multi then
                local Table = {}

                for Val, Active in pairs(Value or {}) do
                    if Active and table.find(Dropdown.Values, Val) then
                        Table[Val] = true
                    end
                end

                Dropdown.Value = Table
            else
                if table.find(Dropdown.Values, Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end

            Dropdown:Display()
            for _, Button in pairs(Buttons) do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                Library:UpdateDependencyBoxes()
            end
        end

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValues(Values)
            if typeof(Values) == "table" then
                for _, val in pairs(Values) do
                    table.insert(Dropdown.Values, val)
                end
            elseif typeof(Values) == "string" then
                table.insert(Dropdown.Values, Values)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabledValues(DisabledValues)
            Dropdown.DisabledValues = DisabledValues
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in pairs(DisabledValues) do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabled(Disabled: boolean)
            Dropdown.Disabled = Disabled

            if Dropdown.TooltipTable then
                Dropdown.TooltipTable.Disabled = Dropdown.Disabled
            end

            MenuTable:Close()
            Display.Active = not Dropdown.Disabled
            Dropdown:UpdateColors()
        end

        function Dropdown:SetVisible(Visible: boolean)
            Dropdown.Visible = Visible

            Holder.Visible = Dropdown.Visible
            Groupbox:Resize()
        end

        function Dropdown:SetText(Text: string)
            Dropdown.Text = Text
            Holder.Size = UDim2.new(1, 0, 0, (Text and 39 or 21) * Library.DPIScale)

            Label.Text = Text and Text or ""
            Label.Visible = not not Text
        end

        Display.MouseButton1Click:Connect(function()
            if Dropdown.Disabled then
                return
            end

            MenuTable:Toggle()
        end)

        if SearchBox then
            SearchBox:GetPropertyChangedSignal("Text"):Connect(Dropdown.BuildDropdownList)
        end

        local Defaults = {}
        if typeof(Info.Default) == "string" then
            local Index = table.find(Dropdown.Values, Info.Default)
            if Index then
                table.insert(Defaults, Index)
            end

        elseif typeof(Info.Default) == "table" then
            for _, Value in next, Info.Default do
                local Index = table.find(Dropdown.Values, Value)
                if Index then
                    table.insert(Defaults, Index)
                end
            end
            
        elseif Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end

                if not Info.Multi then
                    break
                end
            end
        end

        if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
            Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, Display)
            Dropdown.TooltipTable.Disabled = Dropdown.Disabled
        end

        Dropdown:UpdateColors()
        Dropdown:Display()
        Dropdown:BuildDropdownList()
        Groupbox:Resize()

        Dropdown.Holder = Holder
        table.insert(Groupbox.Elements, Dropdown)

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values

        Options[Idx] = Dropdown

        return Dropdown
    end

    function Funcs:AddViewport(Idx, Info)
        Info = Library:Validate(Info, Templates.Viewport)

        local Groupbox = self
        local Container = Groupbox.Container

        local Dragging, Pinching = false, false
        local LastMousePos, LastPinchDist = nil, 0

        local ViewportObject = Info.Object
        if Info.Clone and typeof(Info.Object) == "Instance" then
            if Info.Object.Archivable then
                ViewportObject = ViewportObject:Clone()
            else
                Info.Object.Archivable = true
                ViewportObject = ViewportObject:Clone()
                Info.Object.Archivable = false
            end
        end

        local Viewport = {
            Object = ViewportObject,
            Camera = if not Info.Camera then Instance.new("Camera") else Info.Camera,
            Interactive = Info.Interactive,
            AutoFocus = Info.AutoFocus,
            Visible = Info.Visible,
            Type = "Viewport",
        }

        assert(
            typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
            "Instance must be a BasePart or Model."
        )

        assert(
            typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
            "Camera must be a valid Camera instance."
        )

        local function GetModelSize(model)
            if model:IsA("BasePart") then
                return model.Size
            end

            return select(2, model:GetBoundingBox())
        end

        local function FocusCamera()
            local ModelSize = GetModelSize(Viewport.Object)
            local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
            local CameraDistance = MaxExtent * 2
            local ModelPosition = Viewport.Object:GetPivot().Position

            Viewport.Camera.CFrame =
                CFrame.new(ModelPosition + Vector3.new(0, MaxExtent / 2, CameraDistance), ModelPosition)
        end

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Viewport.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ViewportFrame = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
            CurrentCamera = Viewport.Camera,
            Active = Viewport.Interactive,
        })

        ViewportFrame.MouseEnter:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in pairs(Groupbox.Tab.Sides) do
                Side.ScrollingEnabled = false
            end
        end)

        ViewportFrame.MouseLeave:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in pairs(Groupbox.Tab.Sides) do
                Side.ScrollingEnabled = true
            end
        end)

        ViewportFrame.InputBegan:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = true
                LastMousePos = input.Position
            elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                Dragging = true
                LastMousePos = input.Position
            end
        end)

        Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end))

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Dragging or Pinching then
                return
            end

            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local MouseDelta = input.Position - LastMousePos
                LastMousePos = input.Position

                local Position = Viewport.Object:GetPivot().Position
                local Camera = Viewport.Camera

                local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.01)
                Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

                local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.01)
                local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

                if PitchedCFrame.UpVector.Y > 0.1 then
                    Camera.CFrame = PitchedCFrame
                end
            end
        end))

        ViewportFrame.InputChanged:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseWheel then
                local ZoomAmount = input.Position.Z * 2
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * ZoomAmount
            end
        end)

        Library:GiveSignal(UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                return
            end

            if state == Enum.UserInputState.Begin then
                Pinching = true
                Dragging = false
                LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude

            elseif state == Enum.UserInputState.Change then
                local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                local delta = (currentDist - LastPinchDist) * 0.1
                LastPinchDist = currentDist
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * delta

            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                Pinching = false
            end
        end))

        Viewport.Object.Parent = ViewportFrame
        if Viewport.AutoFocus then
            FocusCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            assert(Object, "Object cannot be nil.")

            if Clone then
                Object = Object:Clone()
            end

            if Viewport.Object then
                Viewport.Object:Destroy()
            end

            Viewport.Object = Object
            Viewport.Object.Parent = ViewportFrame

            Groupbox:Resize()
        end

        function Viewport:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Viewport:Focus()
            if not Viewport.Object then
                return
            end

            FocusCamera()
        end

        function Viewport:SetCamera(Camera: Instance)
            assert(
                Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                "Camera must be a valid Camera instance."
            )

            Viewport.Camera = Camera
            ViewportFrame.CurrentCamera = Camera
        end

        function Viewport:SetInteractive(Interactive: boolean)
            Viewport.Interactive = Interactive
            ViewportFrame.Active = Interactive
        end

        function Viewport:SetVisible(Visible: boolean)
            Viewport.Visible = Visible

            Holder.Visible = Viewport.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Viewport.Holder = Holder
        table.insert(Groupbox.Elements, Viewport)

        Options[Idx] = Viewport

        return Viewport
    end

    function Funcs:AddImage(Idx, Info)
        Info = Library:Validate(Info, Templates.Image)

        local Groupbox = self
        local Container = Groupbox.Container

        local Image = {
            Image = Info.Image,
            Color = Info.Color,
            RectOffset = Info.RectOffset,
            RectSize = Info.RectSize,
            Height = Info.Height,
            ScaleType = Info.ScaleType,
            Transparency = Info.Transparency,
            BackgroundTransparency = Info.BackgroundTransparency,

            Visible = Info.Visible,
            Type = "Image",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Image.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BackgroundTransparency = Image.BackgroundTransparency,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ImageProperties = {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Image.Image,
            ImageTransparency = Image.Transparency,
            ImageColor3 = Image.Color,
            ImageRectOffset = Image.RectOffset,
            ImageRectSize = Image.RectSize,
            ScaleType = Image.ScaleType,
            Parent = Box,
        }

        local Icon = Library:GetCustomIcon(ImageProperties.Image)
        assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        ImageProperties.Image = Icon.Url
        ImageProperties.ImageRectOffset = Icon.ImageRectOffset
        ImageProperties.ImageRectSize = Icon.ImageRectSize

        local ImageLabel = New("ImageLabel", ImageProperties)

        function Image:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Image.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Image:SetImage(NewImage: string)
            assert(typeof(NewImage) == "string", "Image must be a string.")

            local Icon = Library:GetCustomIcon(NewImage)
            assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            NewImage = Icon.Url
            Image.RectOffset = Icon.ImageRectOffset
            Image.RectSize = Icon.ImageRectSize

            ImageLabel.Image = NewImage
            Image.Image = NewImage
        end

        function Image:SetColor(Color: Color3)
            assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

            ImageLabel.ImageColor3 = Color
            Image.Color = Color
        end

        function Image:SetRectOffset(RectOffset: Vector2)
            assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

            ImageLabel.ImageRectOffset = RectOffset
            Image.RectOffset = RectOffset
        end

        function Image:SetRectSize(RectSize: Vector2)
            assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

            ImageLabel.ImageRectSize = RectSize
            Image.RectSize = RectSize
        end

        function Image:SetScaleType(ScaleType: Enum.ScaleType)
            assert(
                typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                "ScaleType must be a valid Enum.ScaleType."
            )

            ImageLabel.ScaleType = ScaleType
            Image.ScaleType = ScaleType
        end

        function Image:SetTransparency(Transparency: number)
            assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
            assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

            ImageLabel.ImageTransparency = Transparency
            Image.Transparency = Transparency
        end

        function Image:SetVisible(Visible: boolean)
            Image.Visible = Visible

            Holder.Visible = Image.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Image.Holder = Holder
        table.insert(Groupbox.Elements, Image)

        Options[Idx] = Image

        return Image
    end

    function Funcs:AddVideo(Idx, Info)
        Info = Library:Validate(Info, Templates.Video)

        local Groupbox = self
        local Container = Groupbox.Container

        local Video = {
            Video = Info.Video,
            Looped = Info.Looped,
            Playing = Info.Playing,
            Volume = Info.Volume,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "Video",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Video.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local VideoFrameInstance = New("VideoFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Video = Video.Video,
            Looped = Video.Looped,
            Volume = Video.Volume,
            Parent = Box,
        })

        VideoFrameInstance.Playing = Video.Playing

        function Video:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Video.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Video:SetVideo(NewVideo: string)
            assert(typeof(NewVideo) == "string", "Video must be a string.")

            VideoFrameInstance.Video = NewVideo
            Video.Video = NewVideo
        end

        function Video:SetLooped(Looped: boolean)
            assert(typeof(Looped) == "boolean", "Looped must be a boolean.")

            VideoFrameInstance.Looped = Looped
            Video.Looped = Looped
        end

        function Video:SetVolume(Volume: number)
            assert(typeof(Volume) == "number", "Volume must be a number between 0 and 10.")

            VideoFrameInstance.Volume = Volume
            Video.Volume = Volume
        end

        function Video:SetPlaying(Playing: boolean)
            assert(typeof(Playing) == "boolean", "Playing must be a boolean.")

            VideoFrameInstance.Playing = Playing
            Video.Playing = Playing
        end

        function Video:Play()
            VideoFrameInstance.Playing = true
            Video.Playing = true
        end

        function Video:Pause()
            VideoFrameInstance.Playing = false
            Video.Playing = false
        end

        function Video:SetVisible(Visible: boolean)
            Video.Visible = Visible

            Holder.Visible = Video.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Video.Holder = Holder
        Video.VideoFrame = VideoFrameInstance
        table.insert(Groupbox.Elements, Video)

        Options[Idx] = Video

        return Video
    end

    function Funcs:AddUIPassthrough(Idx, Info)
        Info = Library:Validate(Info, Templates.UIPassthrough)

        local Groupbox = self
        local Container = Groupbox.Container

        assert(Info.Instance, "Instance must be provided.")
        assert(
            typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"),
            "Instance must inherit from GuiBase2d."
        )
        assert(typeof(Info.Height) == "number" and Info.Height > 0, "Height must be a number greater than 0.")

        local Passthrough = {
            Instance = Info.Instance,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "UIPassthrough",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Passthrough.Visible,
            Parent = Container,
        })

        Passthrough.Instance.Parent = Holder

        Groupbox:Resize()

        function Passthrough:SetHeight(Height: number)
            assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

            Passthrough.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Passthrough:SetInstance(Instance: Instance)
            assert(Instance, "Instance must be provided.")
            assert(
                typeof(Instance) == "Instance" and Instance:IsA("GuiBase2d"),
                "Instance must inherit from GuiBase2d."
            )

            if Passthrough.Instance then
                Passthrough.Instance.Parent = nil
            end

            Passthrough.Instance = Instance
            Passthrough.Instance.Parent = Holder
        end

        function Passthrough:SetVisible(Visible: boolean)
            Passthrough.Visible = Visible

            Holder.Visible = Passthrough.Visible
            Groupbox:Resize()
        end

        Passthrough.Holder = Holder
        table.insert(Groupbox.Elements, Passthrough)

        Options[Idx] = Passthrough

        return Passthrough
    end

    function Funcs:AddDependencyBox()
        local Groupbox = self
        local Container = Groupbox.Container

        local DepboxContainer
        local DepboxList

        do
            DepboxContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            DepboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepboxContainer,
            })
        end

        local Depbox = {
            Visible = false,
            Dependencies = {},

            Holder = DepboxContainer,
            Container = DepboxContainer,

            Elements = {},
            DependencyBoxes = {},
        }

        function Depbox:Resize()
            DepboxContainer.Size = UDim2.new(1, 0, 0, DepboxList.AbsoluteContentSize.Y * Library.DPIScale)
            Groupbox:Resize()
        end

        function Depbox:Update(CancelSearch)
            for _, Dependency in pairs(Depbox.Dependencies) do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    DepboxContainer.Visible = false
                    Depbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    end
                end
            end

            Depbox.Visible = true
            DepboxContainer.Visible = true
            if not Library.Searching then
                task.defer(function()
                    Depbox:Resize()
                end)
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        DepboxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if not Depbox.Visible then
                return
            end

            Depbox:Resize()
        end)

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in pairs(Dependencies) do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end

        DepboxContainer:GetPropertyChangedSignal("Visible"):Connect(function()
            Depbox:Resize()
        end)

        setmetatable(Depbox, BaseGroupbox)

        table.insert(Groupbox.DependencyBoxes, Depbox)
        table.insert(Library.DependencyBoxes, Depbox)

        return Depbox
    end

    function Funcs:AddDependencyGroupbox()
        local Groupbox = self
        local Tab = Groupbox.Tab
        local BoxHolder = Groupbox.BoxHolder

        local Background = Library:MakeOutline(BoxHolder, Library.CornerRadius)
        Background.Size = UDim2.fromScale(1, 0)
        Background.Visible = false
        Library:UpdateDPI(Background, {
            Size = false,
        })

        local DepGroupboxContainer
        local DepGroupboxList

        do
            DepGroupboxContainer = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = Background,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                Parent = DepGroupboxContainer,
            })

            DepGroupboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepGroupboxContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7),
                Parent = DepGroupboxContainer,
            })
        end

        local DepGroupbox = {
            Visible = false,
            Dependencies = {},

            BoxHolder = BoxHolder,
            Holder = Background,
            Container = DepGroupboxContainer,

            Tab = Tab,
            Elements = {},
            DependencyBoxes = {},
        }

        function DepGroupbox:Resize()
            Background.Size = UDim2.new(1, 0, 0, DepGroupboxList.AbsoluteContentSize.Y + 18 * Library.DPIScale)
        end

        function DepGroupbox:Update(CancelSearch)
            for _, Dependency in pairs(DepGroupbox.Dependencies) do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    Background.Visible = false
                    DepGroupbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            Background.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            Background.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    end
                end
            end

            DepGroupbox.Visible = true
            if not Library.Searching then
                Background.Visible = true
                DepGroupbox:Resize()
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function DepGroupbox:SetupDependencies(Dependencies)
            for _, Dependency in pairs(Dependencies) do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            DepGroupbox.Dependencies = Dependencies
            DepGroupbox:Update()
        end

        setmetatable(DepGroupbox, BaseGroupbox)

        table.insert(Tab.DependencyGroupboxes, DepGroupbox)
        table.insert(Library.DependencyBoxes, DepGroupbox)

        return DepGroupbox
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

function Library:SetFont(FontFace)
    if typeof(FontFace) == "EnumItem" then
        FontFace = Font.fromEnum(FontFace)
    end

    Library.Scheme.Font = FontFace
    Library:UpdateColorsUsingRegistry()
end

function Library:SetNotifySide(Side: string)
    Library.NotifySide = Side

    if Side:lower() == "left" then
        NotificationArea.AnchorPoint = Vector2.new(0, 0)
        NotificationArea.Position = UDim2.fromOffset(6, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    else
        NotificationArea.AnchorPoint = Vector2.new(1, 0)
        NotificationArea.Position = UDim2.new(1, -6, 0, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    end
end

function Library:Notify(...)
    local Data = {}
    local Info = select(1, ...)

    -- Parse arguments
    if typeof(Info) == "table" then
        Data.Title = Info.Title and tostring(Info.Title) or nil
        Data.Description = Info.Description and tostring(Info.Description) or nil
        Data.SubText = Info.SubText and tostring(Info.SubText) or nil
        Data.Time = Info.Time or 5
        Data.SoundId = Info.SoundId
        Data.Steps = Info.Steps
        Data.Persist = Info.Persist

        -- Options
        Data.Type = Info.Type or "info"
        Data.Icon = Info.Icon
        Data.Closable = Info.Closable ~= false
        Data.Buttons = Info.Buttons or {}
        Data.OnClick = Info.OnClick
        Data.OnClose = Info.OnClose
        Data.Width = Info.Width
        Data.Image = Info.Image
        Data.Progress = Info.Progress
        Data.Animated = Info.Animated ~= false
        Data.Color = Info.Color
    else
        Data.Description = tostring(Info)
        Data.Time = select(2, ...) or 5
        Data.SoundId = select(3, ...)
        Data.Type = "info"
        Data.Closable = true
        Data.Buttons = {}
    end
    Data.Destroyed = false

    -- Type configuration
    local TypeConfig = {
        success = { Icon = "check", Color = Color3.fromRGB(45, 180, 90) },
        error = { Icon = "x", Color = Color3.fromRGB(220, 60, 60) },
        warning = { Icon = "alert-triangle", Color = Color3.fromRGB(220, 160, 40) },
        info = { Icon = "info", Color = Library.Scheme.AccentColor },
        loading = { Icon = "loader", Color = Library.Scheme.AccentColor, Spinning = true },
        custom = { Icon = Data.Icon, Color = Data.Color or Library.Scheme.AccentColor },
    }

    local Config = TypeConfig[Data.Type] or TypeConfig.info
    local NotifyIcon = Data.Icon or Config.Icon
    local NotifyColor = Data.Color or Config.Color
    local IsSpinning = Config.Spinning

    local DeletedInstance = false
    local DeleteConnection = nil
    if typeof(Data.Time) == "Instance" then
        DeleteConnection = Data.Time.Destroying:Connect(function()
            DeletedInstance = true
            if DeleteConnection then
                DeleteConnection:Disconnect()
                DeleteConnection = nil
            end
        end)
    end

    local NotifyWidth = Data.Width or 340

    -- Main container
    local FakeBackground = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(NotifyWidth, 0),
        Visible = false,
        Parent = NotificationArea,
        DPIExclude = { Size = true },
    })

    -- Shadow effect
    local NotifyShadow = New("ImageLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Image = "rbxasset://textures/ui/common/shadows/shadow_down_16.png",
        ImageTransparency = 0.4,
        Size = UDim2.new(1, 32, 0, 0),
        Position = UDim2.fromOffset(-16, -8),
        ScaleType = Enum.ScaleType.Slice,
        SliceScale = 0.08,
        Parent = FakeBackground,
    })

    -- Dark background with enhanced styling
    local Background = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(20, 20, 25),
        Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -10, 0, 0) or UDim2.new(1, 10, 0, 0),
        Size = UDim2.fromScale(1, 0),
        ClipsDescendants = true,
        Parent = FakeBackground,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = Background,
    })

    -- Gradient overlay for depth
    local GradientOverlay = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(25, 25, 32),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 0),
        Parent = Background,
    })
    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 23)),
        }),
        Rotation = 90,
        Parent = GradientOverlay,
    })
    GradientOverlay.ZIndex = 0

    -- Enhanced border
    New("UIStroke", {
        Color = Color3.fromRGB(50, 50, 65),
        Thickness = 1.5,
        Parent = Background,
    })

    -- Glow effect
    local NotifyGlow = New("ImageLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Image = "rbxasset://textures/ui/common/gradient_main.png",
        ImageColor3 = NotifyColor,
        ImageTransparency = 0.85,
        Size = UDim2.new(1, 20, 0, 0),
        Position = UDim2.fromOffset(-10, -10),
        ScaleType = Enum.ScaleType.Slice,
        SliceScale = 0.5,
        ZIndex = -1,
        Parent = Background,
    })

    -- Accent indicator line (enhanced)
    local AccentLine = New("Frame", {
        BackgroundColor3 = NotifyColor,
        Size = UDim2.new(1, 0, 0, 3),
        BorderSizePixel = 0,
        Parent = Background,
        ZIndex = 1,
    })
    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = AccentLine,
    })

    -- Content container
    local ContentHolder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 3),
        Size = UDim2.new(1, 0, 0, 0),
        Parent = Background,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 14),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        PaddingTop = UDim.new(0, 12),
        Parent = ContentHolder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 10),
        Parent = ContentHolder,
    })

    -- Header (icon + text + close)
    local HeaderRow = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = ContentHolder,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 10),
        Parent = HeaderRow,
    })

    -- Icon
    local IconData = Library:GetIcon(NotifyIcon or "info")
    local IconImage
    if IconData then
        IconImage = New("ImageLabel", {
            BackgroundTransparency = 1,
            Image = IconData.Url,
            ImageColor3 = NotifyColor,
            ImageRectOffset = IconData.ImageRectOffset,
            ImageRectSize = IconData.ImageRectSize,
            Size = UDim2.fromOffset(18, 18),
            Parent = HeaderRow,
        })

        if IsSpinning then
            task.spawn(function()
                while not Data.Destroyed and IconImage and IconImage.Parent do
                    IconImage.Rotation = IconImage.Rotation + 6
                    task.wait(0.016)
                end
            end)
        end
    end

    -- Text container
    local TextContainer = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, Data.Closable and -52 or -28, 0, 0),
        Parent = HeaderRow,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = TextContainer,
    })

    local Title, Desc, SubTextLabel

    if Data.Title then
        Title = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            Text = Data.Title,
            TextColor3 = Color3.fromRGB(250, 250, 252),
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = TextContainer,
        })
    end

    if Data.Description then
        Desc = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            Text = Data.Description,
            TextColor3 = Color3.fromRGB(180, 180, 195),
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = TextContainer,
        })
    end

    if Data.SubText then
        SubTextLabel = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            Text = Data.SubText,
            TextColor3 = NotifyColor,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = TextContainer,
        })
    end

    -- Close button
    local CloseButton
    if Data.Closable then
        CloseButton = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -10, 0, 10),
            Size = UDim2.fromOffset(16, 16),
            Text = "",
            Parent = Background,
        })

        local CloseIcon = Library:GetIcon("x")
        local CloseIconImage
        if CloseIcon then
            CloseIconImage = New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = CloseIcon.Url,
                ImageColor3 = Color3.fromRGB(100, 100, 110),
                ImageRectOffset = CloseIcon.ImageRectOffset,
                ImageRectSize = CloseIcon.ImageRectSize,
                Size = UDim2.fromScale(1, 1),
                Parent = CloseButton,
            })
        end

        CloseButton.MouseEnter:Connect(function()
            if CloseIconImage then
                TweenService:Create(CloseIconImage, TweenInfo.new(0.15), {
                    ImageColor3 = Color3.fromRGB(220, 220, 225),
                }):Play()
            end
        end)
        CloseButton.MouseLeave:Connect(function()
            if CloseIconImage then
                TweenService:Create(CloseIconImage, TweenInfo.new(0.15), {
                    ImageColor3 = Color3.fromRGB(100, 100, 110),
                }):Play()
            end
        end)
        CloseButton.MouseButton1Click:Connect(function()
            if Data.OnClose then pcall(Data.OnClose) end
            Data:Destroy()
        end)
    end

    -- Image
    if Data.Image then
        local ImageHolder = New("Frame", {
            BackgroundColor3 = Color3.fromRGB(25, 25, 30),
            Size = UDim2.new(1, 0, 0, 80),
            Parent = ContentHolder,
        })
        New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ImageHolder })
        New("ImageLabel", {
            BackgroundTransparency = 1,
            Image = typeof(Data.Image) == "number" and ("rbxassetid://" .. Data.Image) or Data.Image,
            ScaleType = Enum.ScaleType.Fit,
            Size = UDim2.fromScale(1, 1),
            Parent = ImageHolder,
        })
    end

    -- Progress bar
    local ProgressFill
    if Data.Progress or (Data.Time and not Data.Persist and typeof(Data.Time) ~= "Instance") then
        local ProgressHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 3),
            Parent = ContentHolder,
        })

        local ProgressBar = New("Frame", {
            BackgroundColor3 = Color3.fromRGB(28, 28, 35),
            Size = UDim2.fromScale(1, 1),
            Parent = ProgressHolder,
        })
        New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ProgressBar })

        -- Calculate initial progress
        local InitialProgress = 1
        if Data.Progress then
            InitialProgress = typeof(Data.Progress) == "table" and (Data.Progress.Current / Data.Progress.Max) or Data.Progress
        end

        ProgressFill = New("Frame", {
            BackgroundColor3 = NotifyColor,
            Size = UDim2.fromScale(InitialProgress, 1),
            Parent = ProgressBar,
        })
        New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ProgressFill })

        -- Add subtle glow to progress bar
        New("UIStroke", {
            Color = NotifyColor,
            Thickness = 0.5,
            Transparency = 0.5,
            Parent = ProgressFill,
        })
    end

    -- Action buttons (improved styling)
    if #Data.Buttons > 0 then
        local ButtonsRow = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            Parent = ContentHolder,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 8),
            Parent = ButtonsRow,
        })

        for _, ButtonInfo in ipairs(Data.Buttons) do
            local BtnText = ButtonInfo.Text or ButtonInfo[1] or "Button"
            local BtnCallback = ButtonInfo.Callback or ButtonInfo[2]
            local BtnVariant = ButtonInfo.Variant or ButtonInfo[3] or "default"

            local BtnColors = {
                default = { Bg = Color3.fromRGB(40, 40, 50), Hover = Color3.fromRGB(60, 60, 75), Border = Color3.fromRGB(60, 60, 75), Text = Color3.fromRGB(210, 210, 220) },
                primary = { Bg = NotifyColor, Hover = Library:GetLighterColor(NotifyColor), Border = Library:GetLighterColor(NotifyColor), Text = Color3.new(1, 1, 1) },
                danger = { Bg = Color3.fromRGB(200, 60, 60), Hover = Color3.fromRGB(220, 80, 80), Border = Color3.fromRGB(220, 80, 80), Text = Color3.new(1, 1, 1) },
            }
            local BtnColor = BtnColors[BtnVariant] or BtnColors.default

            local ActionBtn = New("TextButton", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = BtnColor.Bg,
                Size = UDim2.fromOffset(0, 28),
                Text = "",
                Parent = ButtonsRow,
            })
            New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ActionBtn })
            New("UIStroke", { Color = BtnColor.Border, Thickness = 1.5, Transparency = 0.3, Parent = ActionBtn })
            New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = ActionBtn })

            -- Button glow effect
            New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxasset://textures/ui/common/gradient_main.png",
                ImageColor3 = BtnColor.Bg,
                ImageTransparency = 0.95,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1.2, 1.3),
                ZIndex = 0,
                Parent = ActionBtn,
            })

            local BtnLabel = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(0, 1),
                Text = BtnText,
                TextColor3 = BtnColor.Text,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
                TextSize = 11,
                ZIndex = 1,
                Parent = ActionBtn,
            })

            ActionBtn.MouseEnter:Connect(function()
                TweenService:Create(ActionBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundColor3 = BtnColor.Hover }):Play()
                TweenService:Create(BtnLabel, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
            end)
            ActionBtn.MouseLeave:Connect(function()
                TweenService:Create(ActionBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundColor3 = BtnColor.Bg }):Play()
                TweenService:Create(BtnLabel, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
            end)
            ActionBtn.MouseButton1Click:Connect(function()
                if BtnCallback then pcall(BtnCallback, Data) end
            end)
        end
    end

    -- Click handler
    if Data.OnClick then
        local ClickDetector = New("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            ZIndex = 0,
            Parent = Background,
        })
        ClickDetector.MouseButton1Click:Connect(function()
            if Data.OnClick then pcall(Data.OnClick, Data) end
        end)
    end

    -- Methods
    function Data:Resize() end

    function Data:ChangeTitle(NewText)
        if Title then Data.Title = tostring(NewText); Title.Text = Data.Title end
    end

    function Data:ChangeDescription(NewText)
        if Desc then Data.Description = tostring(NewText); Desc.Text = Data.Description end
    end

    function Data:ChangeSubText(NewText)
        if SubTextLabel then Data.SubText = tostring(NewText); SubTextLabel.Text = Data.SubText end
    end

    function Data:SetProgress(Value, Max)
        if ProgressFill then
            local Progress = math.clamp(Max and (Value / Max) or Value, 0, 1)
            if Data.Animated then
                TweenService:Create(ProgressFill, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Size = UDim2.fromScale(Progress, 1) }):Play()
            else
                ProgressFill.Size = UDim2.fromScale(Progress, 1)
            end
        end
    end

    function Data:ChangeStep(NewStep)
        if ProgressFill and Data.Steps then
            Data:SetProgress(math.clamp(NewStep or 0, 0, Data.Steps), Data.Steps)
        end
    end

    function Data:SetType(NewType)
        local NewConfig = TypeConfig[NewType] or TypeConfig.info
        local NewColor = NewConfig.Color
        TweenService:Create(AccentLine, TweenInfo.new(0.2), { BackgroundColor3 = NewColor }):Play()
        if IconImage then TweenService:Create(IconImage, TweenInfo.new(0.2), { ImageColor3 = NewColor }):Play() end
        if ProgressFill then TweenService:Create(ProgressFill, TweenInfo.new(0.2), { BackgroundColor3 = NewColor }):Play() end

        local NewIconData = Library:GetIcon(NewConfig.Icon)
        if NewIconData and IconImage then
            IconImage.Image = NewIconData.Url
            IconImage.ImageRectOffset = NewIconData.ImageRectOffset
            IconImage.ImageRectSize = NewIconData.ImageRectSize
        end
    end

    function Data:SetIcon(NewIconName)
        local NewIconData = Library:GetIcon(NewIconName)
        if NewIconData and IconImage then
            IconImage.Image = NewIconData.Url
            IconImage.ImageRectOffset = NewIconData.ImageRectOffset
            IconImage.ImageRectSize = NewIconData.ImageRectSize
        end
    end

    function Data:Destroy()
        Data.Destroyed = true
        if typeof(Data.Time) == "Instance" then pcall(Data.Time.Destroy, Data.Time) end
        if DeleteConnection then DeleteConnection:Disconnect() end

        local ExitPos = Library.NotifySide:lower() == "left" and UDim2.new(-1, -10, 0, 0) or UDim2.new(1, 10, 0, 0)

        -- Smooth exit animation
        TweenService:Create(Background, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = ExitPos }):Play()
        TweenService:Create(Background, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 0.6 }):Play()

        -- Fade out shadow and glow
        TweenService:Create(NotifyShadow, TweenInfo.new(0.25), { ImageTransparency = 1 }):Play()
        TweenService:Create(NotifyGlow, TweenInfo.new(0.25), { ImageTransparency = 1 }):Play()

        task.delay(0.35, function()
            Library.Notifications[FakeBackground] = nil
            FakeBackground:Destroy()
        end)
    end

    -- Sound
    if Data.SoundId then
        local SoundId = typeof(Data.SoundId) == "number" and ("rbxassetid://" .. Data.SoundId) or Data.SoundId
        New("Sound", { SoundId = SoundId, Volume = 3, PlayOnRemove = true, Parent = SoundService }):Destroy()
    end

    Library.Notifications[FakeBackground] = Data
    FakeBackground.Visible = true

    -- Entry animation
    Background.Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -10, 0, 0) or UDim2.new(1, 10, 0, 0)
    Background.BackgroundTransparency = 0.4

    -- Smooth entry with bounce effect
    local EntryTween = TweenService:Create(Background, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) })
    EntryTween:Play()

    -- Fade in transparency
    TweenService:Create(Background, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()

    -- Fade in shadow
    TweenService:Create(NotifyShadow, TweenInfo.new(0.3), { ImageTransparency = 0.4 }):Play()

    -- Fade in glow
    TweenService:Create(NotifyGlow, TweenInfo.new(0.3), { ImageTransparency = 0.85 }):Play()

    -- Auto-destroy
    task.delay(0.4, function()
        if Data.Persist then return end
        if typeof(Data.Time) == "Instance" then
            repeat task.wait() until DeletedInstance or Data.Destroyed
        else
            if ProgressFill and not Data.Progress then
                TweenService:Create(ProgressFill, TweenInfo.new(Data.Time, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) }):Play()
            end
            task.wait(Data.Time)
        end
        if not Data.Destroyed then Data:Destroy() end
    end)

    return Data
end

function Library:CreateWindow(WindowInfo)
    WindowInfo = Library:Validate(WindowInfo, Templates.Window)
    local ViewportSize: Vector2 = workspace.CurrentCamera.ViewportSize
    if RunService:IsStudio() and ViewportSize.X <= 5 and ViewportSize.Y <= 5 then
        repeat
            ViewportSize = workspace.CurrentCamera.ViewportSize
            task.wait()
        until ViewportSize.X > 5 and ViewportSize.Y > 5
    end

    local MaxX = ViewportSize.X - 64
    local MaxY = ViewportSize.Y - 64

    Library.MinSize = Vector2.new(math.min(Library.MinSize.X, MaxX), math.min(Library.MinSize.Y, MaxY))
    WindowInfo.Size = UDim2.fromOffset(
        math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, MaxX),
        math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, MaxY)
    )
    if typeof(WindowInfo.Font) == "EnumItem" then
        WindowInfo.Font = Font.fromEnum(WindowInfo.Font)
    end

    Library.CornerRadius = WindowInfo.CornerRadius
    Library:SetNotifySide(WindowInfo.NotifySide)
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor
    Library.Scheme.Font = WindowInfo.Font
    Library.ToggleKeybind = WindowInfo.ToggleKeybind
    Library.GlobalSearch = WindowInfo.GlobalSearch

    local IsDefaultSearchbarSize = WindowInfo.SearchbarSize == UDim2.fromScale(1, 1)
    local MainFrame
    local SearchBox
    local CurrentTabInfo
    local CurrentTabLabel
    local CurrentTabDescription
    local ResizeButton
    local Tabs
    local Container
    local Window
    local WindowTitle

    local SidebarHighlightCallback = WindowInfo.SidebarHighlightCallback

    local LayoutState = {
        IsCompact = WindowInfo.Compact,
        MinWidth = WindowInfo.SidebarMinWidth,
        CompactWidth = WindowInfo.SidebarCompactWidth,
        MinContentWidth = WindowInfo.MinContentWidth or 260,
        CollapseThreshold = WindowInfo.SidebarCollapseThreshold,
        CurrentWidth = nil,
        LastExpandedWidth = nil,
        MaxWidth = nil,
        GrabberHighlighted = false,
    }

    if LayoutState.MinWidth <= LayoutState.CompactWidth then
        LayoutState.MinWidth = LayoutState.CompactWidth + 32
    end

    if LayoutState.CollapseThreshold <= 0 then
        LayoutState.CollapseThreshold = 0.5
    elseif LayoutState.CollapseThreshold >= 1 then
        LayoutState.CollapseThreshold = 0.9
    end

    local InitialFrameWidth = math.max(WindowInfo.Size.X.Offset, LayoutState.MinWidth + LayoutState.MinContentWidth)
    local InitialExpandedWidth = WindowInfo.InitialSidebarWidth
        or math.floor(InitialFrameWidth * (WindowInfo.InitialSidebarScale or 0.3))
    LayoutState.CurrentWidth = math.max(LayoutState.MinWidth, InitialExpandedWidth)
    LayoutState.LastExpandedWidth = LayoutState.CurrentWidth

    local LayoutRefs = {
        DividerLine = nil,
        TitleHolder = nil,
        WindowIcon = nil,
        WindowTitle = nil,
        RightWrapper = nil,
        TabsFrame = nil,
        ContainerFrame = nil,
        SidebarGrabber = nil,
        TabPadding = {},
        TabLabels = {},
    }

    local MoveReservedWidth = (MoveIcon and 28 + 10) or 0

    local SidebarDrag = {
        Active = false,
        StartWidth = 0,
        StartX = 0,
        TouchId = nil,
    }

    local function GetSidebarWidth()
        return LayoutState.IsCompact and LayoutState.CompactWidth or LayoutState.CurrentWidth
    end

    local function EnsureSidebarBounds()
        local Width = MainFrame and MainFrame.AbsoluteSize.X or WindowInfo.Size.X.Offset
        if Width <= 0 then
            return
        end

        local MaxSidebar = Width - LayoutState.MinContentWidth
        LayoutState.MaxWidth = math.max(LayoutState.MinWidth, MaxSidebar)

        LayoutState.CurrentWidth = math.clamp(LayoutState.CurrentWidth, LayoutState.MinWidth, LayoutState.MaxWidth)
        LayoutState.LastExpandedWidth = math.clamp(
            LayoutState.LastExpandedWidth or LayoutState.CurrentWidth,
            LayoutState.MinWidth,
            LayoutState.MaxWidth
        )
    end

    local function SetSidebarHighlight(IsActive)
        local DividerLine = LayoutRefs.DividerLine
        if not DividerLine then
            return
        end

        LayoutState.GrabberHighlighted = IsActive == true

        if typeof(SidebarHighlightCallback) == "function" then
            Library:SafeCallback(SidebarHighlightCallback, DividerLine, LayoutState.GrabberHighlighted)
        else
            local TargetColor = LayoutState.GrabberHighlighted and Library.Scheme.AccentColor
                or Library.Scheme.OutlineColor

            TweenService:Create(DividerLine, Library.HoverTweenInfo, {
                BackgroundColor3 = TargetColor,
                Size = LayoutState.GrabberHighlighted and UDim2.new(0, 4, 1, 0) or UDim2.new(0, 2, 1, 0),
            }):Play()
        end
    end

    local function ApplySidebarLayout()
        EnsureSidebarBounds()

        local SidebarWidth = GetSidebarWidth()
        local IsCompact = LayoutState.IsCompact

        if LayoutRefs.DividerLine then
            LayoutRefs.DividerLine.Position = UDim2.new(0, SidebarWidth, 0, 0)
        end

        if LayoutRefs.TabsFrame then
            LayoutRefs.TabsFrame.Size = UDim2.new(0, SidebarWidth, 1, -70)
        end

        if LayoutRefs.ContainerFrame then
            LayoutRefs.ContainerFrame.Position = UDim2.fromOffset(SidebarWidth, 49)
            LayoutRefs.ContainerFrame.Size = UDim2.new(1, -SidebarWidth, 1, -70)
        end

        if LayoutRefs.SidebarGrabber then
            LayoutRefs.SidebarGrabber.Position =
                UDim2.fromOffset(SidebarWidth - LayoutRefs.SidebarGrabber.Size.X.Offset / 2, 49)
        end

        if LayoutRefs.TitleHolder then
            LayoutRefs.TitleHolder.Size = UDim2.new(0, math.max(LayoutState.CompactWidth, SidebarWidth), 1, 0)
        end

        if LayoutRefs.WindowIcon then
            if WindowInfo.Icon then
                LayoutRefs.WindowIcon.Visible = true
            else
                LayoutRefs.WindowIcon.Visible = IsCompact or not LayoutRefs.WindowTitle
            end
        end

        if LayoutRefs.WindowTitle then
            LayoutRefs.WindowTitle.Visible = not IsCompact
            if not IsCompact then
                local MaxTextWidth =
                    math.max(0, SidebarWidth - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 12 or 12))
                local TextWidth =
                    Library:GetTextBounds(LayoutRefs.WindowTitle.Text, Library.Scheme.Font, 20, MaxTextWidth)
                LayoutRefs.WindowTitle.Size = UDim2.new(0, TextWidth, 1, 0)
            else
                LayoutRefs.WindowTitle.Size = UDim2.new(0, 0, 1, 0)
            end
        end

        if LayoutRefs.RightWrapper then
            local PositionX = SidebarWidth + 8
            LayoutRefs.RightWrapper.Position = UDim2.new(0, PositionX, 0.5, 0)
            LayoutRefs.RightWrapper.Size = UDim2.new(1, -PositionX - 8 - MoveReservedWidth, 1, -16)
        end

        for _, Padding in ipairs(LayoutRefs.TabPadding) do
            Padding.PaddingLeft = UDim.new(0, IsCompact and 14 or 12)
            Padding.PaddingRight = UDim.new(0, IsCompact and 14 or 12)
            Padding.PaddingTop = UDim.new(0, IsCompact and 7 or 11)
            Padding.PaddingBottom = UDim.new(0, IsCompact and 7 or 11)
        end

        for _, LabelObject in ipairs(LayoutRefs.TabLabels) do
            LabelObject.Visible = not IsCompact
        end

        SetSidebarHighlight(LayoutState.GrabberHighlighted)

        WindowInfo.Compact = LayoutState.IsCompact

        for _, TabObject in pairs(Library.Tabs) do
            if TabObject.RefreshSides then
                TabObject:RefreshSides()
            end
        end
    end

    local function SetSidebarWidth(Width)
        EnsureSidebarBounds()

        Width = Width or LayoutState.CurrentWidth

        local Threshold = LayoutState.MinWidth * LayoutState.CollapseThreshold
        local WasCompact = LayoutState.IsCompact

        if Width <= Threshold then
            if not WasCompact then
                LayoutState.LastExpandedWidth = LayoutState.CurrentWidth
            end
            LayoutState.IsCompact = true
        else
            local TargetWidth = Width
            if WasCompact then
                TargetWidth = math.max(Width, LayoutState.MinWidth)
            end

            LayoutState.CurrentWidth = math.clamp(TargetWidth, LayoutState.MinWidth, LayoutState.MaxWidth)
            LayoutState.LastExpandedWidth = LayoutState.CurrentWidth
            LayoutState.IsCompact = false
        end

        ApplySidebarLayout()
    end

    do
        Library.KeybindFrame, Library.KeybindContainer = Library:AddDraggableMenu("Keybinds")
        Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
        Library.KeybindFrame.Position = UDim2.new(0, 6, 0.5, 0)
        Library.KeybindFrame.Visible = false
        Library:UpdateDPI(Library.KeybindFrame, {
            Position = false,
            Size = false,
        })

        MainFrame = New("TextButton", {
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
            end,
            Name = "Main",
            Text = "",
            Position = WindowInfo.Position,
            Size = WindowInfo.Size,
            Visible = false,
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
            },
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
            Parent = MainFrame,
        })
        local InitialSidebarWidth = GetSidebarWidth()
        LayoutRefs.DividerLine = Library:MakeLine(MainFrame, {
            Position = UDim2.new(0, InitialSidebarWidth, 0, 0),
            Size = UDim2.new(0, 1, 1, -21),
            ZIndex = 2,
        })

        local Lines = {
            {
                Position = UDim2.fromOffset(0, 48),
                Size = UDim2.new(1, 0, 0, 1),
            },
            {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, -20),
                Size = UDim2.new(1, 0, 0, 1),
            },
        }
        for _, Info in pairs(Lines) do
            Library:MakeLine(MainFrame, Info)
        end
        Library:MakeOutline(MainFrame, WindowInfo.CornerRadius, 0)

        -- Highlight/Glow effect - Modern diffuse shadow system
        -- Creates a soft, spread shadow like professional design tools (Canva, Figma)
        local ShadowLayers = {}

        -- Create container for all shadow layers
        local ShadowContainer = New("Frame", {
            Name = "ShadowContainer",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),
            ZIndex = -10,
            Parent = MainFrame,
        })

        -- Shadow configuration for smooth gradient falloff
        local ShadowConfig = {
            { size = 12,  transparency = 0.6,  zIndex = -1 },  -- Core glow (brightest)
            { size = 24,  transparency = 0.72, zIndex = -2 },  -- Inner spread
            { size = 40,  transparency = 0.82, zIndex = -3 },  -- Mid spread
            { size = 60,  transparency = 0.88, zIndex = -4 },  -- Outer spread
            { size = 85,  transparency = 0.93, zIndex = -5 },  -- Far spread
            { size = 115, transparency = 0.96, zIndex = -6 },  -- Ambient (softest)
        }

        -- Create shadow layers dynamically
        for i, config in ipairs(ShadowConfig) do
            local ShadowLayer = New("ImageLabel", {
                Name = "ShadowLayer" .. i,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://6015897843",
                ImageColor3 = Library.Scheme.HighlightColor,
                ImageTransparency = config.transparency,
                Position = UDim2.fromScale(0.5, 0.5),
                ScaleType = Enum.ScaleType.Slice,
                Size = UDim2.new(1, config.size, 1, config.size),
                SliceCenter = Rect.new(49, 49, 450, 450),
                ZIndex = config.zIndex,
                Parent = ShadowContainer,
            })
            table.insert(ShadowLayers, {
                Layer = ShadowLayer,
                BaseSize = config.size,
                BaseTransparency = config.transparency,
            })
        end

        -- Animated glow pulse effect
        local HighlightPulseTweens = {}
        local function UpdateHighlightGlow()
            -- Cancel existing tweens
            for _, tween in ipairs(HighlightPulseTweens) do
                if tween then tween:Cancel() end
            end
            HighlightPulseTweens = {}

            if Library.Scheme.Highlight then
                ShadowContainer.Visible = true

                -- Update colors for all layers
                for _, layerData in ipairs(ShadowLayers) do
                    layerData.Layer.ImageColor3 = Library.Scheme.HighlightColor
                end

                -- Create smooth wave animation (layers pulse in sequence)
                for i, layerData in ipairs(ShadowLayers) do
                    local layer = layerData.Layer
                    local baseSize = layerData.BaseSize
                    local baseTransparency = layerData.BaseTransparency

                    -- Each layer pulses with offset timing for wave effect
                    local pulseSize = baseSize + 8
                    local pulseTransparency = math.max(0.5, baseTransparency - 0.08)

                    local PulseTween = TweenService:Create(layer,
                        TweenInfo.new(3 + (i * 0.3), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                        {
                            Size = UDim2.new(1, pulseSize, 1, pulseSize),
                            ImageTransparency = pulseTransparency,
                        }
                    )

                    task.delay(i * 0.15, function()
                        if not Library.Unloaded then
                            PulseTween:Play()
                        end
                    end)

                    table.insert(HighlightPulseTweens, PulseTween)
                end
            else
                ShadowContainer.Visible = false
            end
        end

        -- Function to set shadow intensity (0-1)
        local function SetShadowIntensity(intensity)
            for i, layerData in ipairs(ShadowLayers) do
                local baseTransparency = layerData.BaseTransparency
                local targetTransparency = 1 - ((1 - baseTransparency) * intensity)
                TweenService:Create(layerData.Layer, Library.FadeTweenInfo, {
                    ImageTransparency = targetTransparency,
                }):Play()
            end
        end

        Library.ShadowContainer = ShadowContainer
        Library.ShadowLayers = ShadowLayers
        Library.UpdateHighlightGlow = UpdateHighlightGlow
        Library.SetShadowIntensity = SetShadowIntensity

        UpdateHighlightGlow()

        if WindowInfo.BackgroundImage then
            New("ImageLabel", {
                Image = WindowInfo.BackgroundImage,
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                ScaleType = Enum.ScaleType.Stretch,
                ZIndex = 999,
                BackgroundTransparency = 1,
                ImageTransparency = 0.75,
                Parent = MainFrame,
            })
        end

        if WindowInfo.Center then
            MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset / 2, 0.5, -MainFrame.Size.Y.Offset / 2)
        end

        --// Top Bar \\-
        local TopBar = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 48),
            Parent = MainFrame,
        })
        Library:MakeDraggable(MainFrame, TopBar, false, true)

        --// Title
        local TitleHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, math.max(LayoutState.CompactWidth, InitialSidebarWidth), 1, 0),
            Parent = TopBar,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = TitleHolder,
        })
        LayoutRefs.TitleHolder = TitleHolder

        local WindowIcon
        if WindowInfo.Icon then
            WindowIcon = New("ImageButton", {
                Image = if tonumber(WindowInfo.Icon)
                    then string.format("rbxassetid://%d", WindowInfo.Icon)
                    else WindowInfo.Icon,
                Size = WindowInfo.IconSize,
                BackgroundTransparency = 1,
                Parent = TitleHolder,
            })
        else
            WindowIcon = New("TextButton", {
                Text = WindowInfo.Title:sub(1, 1),
                TextScaled = true,
                Size = WindowInfo.IconSize,
                BackgroundTransparency = 1,
                Parent = TitleHolder,
            })
        end
        WindowIcon.Visible = WindowInfo.Icon ~= nil or LayoutState.IsCompact
        LayoutRefs.WindowIcon = WindowIcon

        WindowTitle = New("TextButton", {
            BackgroundTransparency = 1,
            Text = WindowInfo.Title,
            TextSize = 20,
            Visible = not LayoutState.IsCompact,
            Parent = TitleHolder,
        })
        if not LayoutState.IsCompact then
            local MaxTextWidth =
                math.max(0, InitialSidebarWidth - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 12 or 12))
            local TextWidth = Library:GetTextBounds(WindowTitle.Text, Library.Scheme.Font, 20, MaxTextWidth)
            WindowTitle.Size = UDim2.new(0, TextWidth, 1, 0)
        else
            WindowTitle.Size = UDim2.new(0, 0, 1, 0)
        end

        LayoutRefs.WindowTitle = WindowTitle

        --// Top Right Bar
        local RightWrapper = New("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, InitialSidebarWidth + 8, 0.5, 0),
            Size = UDim2.new(1, -(InitialSidebarWidth + 16 + MoveReservedWidth), 1, -16),
            Parent = TopBar,
        })
        LayoutRefs.RightWrapper = RightWrapper

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = RightWrapper,
        })

        CurrentTabInfo = New("Frame", {
            Size = UDim2.fromScale(WindowInfo.DisableSearch and 1 or 0.5, 1),
            Visible = false,
            BackgroundTransparency = 1,
            Parent = RightWrapper,
        })

        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Grow,
            Parent = CurrentTabInfo,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = CurrentTabInfo,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            Parent = CurrentTabInfo,
        })

        CurrentTabLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = CurrentTabInfo,
        })

        CurrentTabDescription = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            TextWrapped = true,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.5,
            Parent = CurrentTabInfo,
        })

        SearchBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            PlaceholderText = "Search",
            Size = WindowInfo.SearchbarSize,
            TextScaled = true,
            Visible = not (WindowInfo.DisableSearch or false),
            Parent = RightWrapper,
        })
        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Shrink,
            Parent = SearchBox,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
            Parent = SearchBox,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            Parent = SearchBox,
        })
        New("UIStroke", {
            Color = "OutlineColor",
            Parent = SearchBox,
        })

        local SearchIcon = Library:GetIcon("search")
        if SearchIcon then
            New("ImageLabel", {
                Image = SearchIcon.Url,
                ImageColor3 = "FontColor",
                ImageRectOffset = SearchIcon.ImageRectOffset,
                ImageRectSize = SearchIcon.ImageRectSize,
                ImageTransparency = 0.5,
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = SearchBox,
            })
        end

        if MoveIcon then
            New("ImageLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Image = MoveIcon.Url,
                ImageColor3 = NeonAccentColor,
                ImageRectOffset = MoveIcon.ImageRectOffset,
                ImageRectSize = MoveIcon.ImageRectSize,
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(28, 28),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = TopBar,
            })
        end

        --// PC Control Buttons \\--
        if not Library.IsMobile then
            local ControlButtonsContainer = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, MoveIcon and -44 or -10, 0.5, 0),
                Size = UDim2.fromOffset(90, 28),
                Parent = TopBar,
            })

            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 4),
                Parent = ControlButtonsContainer,
            })

            -- Helper function to create control button
            local function CreateControlButton(iconName, callback, options)
                options = options or {}
                local icon = Library:GetIcon(iconName)
                if not icon then return nil end

                local ButtonFrame = New("TextButton", {
                    BackgroundColor3 = Library.Scheme.MainColor,
                    Size = UDim2.fromOffset(26, 26),
                    Text = "",
                    AutoButtonColor = false,
                    Parent = ControlButtonsContainer,
                })

                New("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = ButtonFrame,
                })

                local ButtonIcon = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = icon.Url,
                    ImageColor3 = Library.Scheme.FontColor,
                    ImageRectOffset = icon.ImageRectOffset,
                    ImageRectSize = icon.ImageRectSize,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(16, 16),
                    Parent = ButtonFrame,
                })

                Library:AddToRegistry(ButtonFrame, {
                    BackgroundColor3 = "MainColor",
                })
                Library:AddToRegistry(ButtonIcon, {
                    ImageColor3 = "FontColor",
                })

                local btn = {
                    Frame = ButtonFrame,
                    Icon = ButtonIcon,
                    Toggled = false,
                    ConfirmPending = false,
                }

                function btn:SetIcon(newIconName)
                    local newIcon = Library:GetIcon(newIconName)
                    if newIcon then
                        ButtonIcon.Image = newIcon.Url
                        ButtonIcon.ImageRectOffset = newIcon.ImageRectOffset
                        ButtonIcon.ImageRectSize = newIcon.ImageRectSize
                    end
                end

                function btn:SetToggled(toggled)
                    self.Toggled = toggled
                end

                -- Hover effects
                ButtonFrame.MouseEnter:Connect(function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Library.Scheme.AccentColor,
                    }):Play()
                    TweenService:Create(ButtonIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                        ImageColor3 = Library.Scheme.White,
                    }):Play()
                end)

                ButtonFrame.MouseLeave:Connect(function()
                    if not btn.ConfirmPending then
                        TweenService:Create(ButtonFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                            BackgroundColor3 = Library.Scheme.MainColor,
                        }):Play()
                        TweenService:Create(ButtonIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                            ImageColor3 = Library.Scheme.FontColor,
                        }):Play()
                    end
                end)

                ButtonFrame.MouseButton1Click:Connect(function()
                    callback(btn)
                end)

                return btn
            end

            -- Hide/Show button
            local PCToggleBtn = CreateControlButton("eye", function(self)
                Library:Toggle()
                self:SetToggled(Library.Toggled)
                if Library.Toggled then
                    self:SetIcon("eye")
                else
                    self:SetIcon("eye-off")
                end
            end)

            -- Lock/Unlock button
            local PCLockBtn = CreateControlButton("unlock", function(self)
                Library.CantDragForced = not Library.CantDragForced
                self:SetToggled(Library.CantDragForced)
                if Library.CantDragForced then
                    self:SetIcon("lock")
                else
                    self:SetIcon("unlock")
                end
            end)

            -- Unload button with confirmation
            local PCUnloadBtn = CreateControlButton("power", function(self)
                if not self.ConfirmPending then
                    self.ConfirmPending = true
                    self:SetIcon("alert-circle")
                    TweenService:Create(self.Icon, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                        ImageColor3 = Library.Scheme.Red or Color3.fromRGB(255, 80, 80),
                    }):Play()
                    TweenService:Create(self.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Library.Scheme.Red or Color3.fromRGB(255, 80, 80),
                    }):Play()

                    -- Reset after 2 seconds if not confirmed
                    task.delay(2, function()
                        if self.ConfirmPending then
                            self.ConfirmPending = false
                            self:SetIcon("power")
                            TweenService:Create(self.Icon, TweenInfo.new(0.3), {
                                ImageColor3 = Library.Scheme.FontColor,
                            }):Play()
                            TweenService:Create(self.Frame, TweenInfo.new(0.3), {
                                BackgroundColor3 = Library.Scheme.MainColor,
                            }):Play()
                        end
                    end)
                else
                    -- Confirmed - unload the library
                    self.ConfirmPending = false
                    Library:Unload()
                end
            end)
        end

        --// Bottom Bar \\--
        local BottomBar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4)
            end,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 20),
            Parent = MainFrame,
        })
        do
            local Cover = Library:MakeCover(BottomBar, "Top")
            Library:AddToRegistry(Cover, {
                BackgroundColor3 = function()
                    return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4)
                end,
            })
        end
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
            Parent = BottomBar,
        })

        --// Footer
        New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = WindowInfo.Footer,
            TextSize = 14,
            TextTransparency = 0.5,
            TextColor3 = NeonAccentColor,
            Parent = BottomBar,
        })

        --// Resize Button
        if WindowInfo.Resizable then
            ResizeButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Text = "",
                Parent = BottomBar,
            })

            Library:MakeResizable(MainFrame, ResizeButton, function()
                EnsureSidebarBounds()
                ApplySidebarLayout()
                for _, Tab in pairs(Library.Tabs) do
                    Tab:Resize(true)
                end
            end)
        end

        New("ImageLabel", {
            Image = ResizeIcon and ResizeIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = ResizeButton,
        })

        MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            EnsureSidebarBounds()
            ApplySidebarLayout()
        end)

        --// Tabs \\--
        Tabs = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "BackgroundColor",
            CanvasSize = UDim2.fromScale(0, 0),
            Position = UDim2.fromOffset(0, 49),
            ScrollBarThickness = 0,
            Size = UDim2.new(0, InitialSidebarWidth, 1, -70),
            Parent = MainFrame,
        })
        New("UIListLayout", {
            Parent = Tabs,
        })
        LayoutRefs.TabsFrame = Tabs

        --// Container \\--
        Container = New("Frame", {
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 1)
            end,
            Name = "Container",
            Position = UDim2.fromOffset(InitialSidebarWidth, 49),
            Size = UDim2.new(1, -InitialSidebarWidth, 1, -70),
            Parent = MainFrame,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 0),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 0),
            Parent = Container,
        })

        LayoutRefs.ContainerFrame = Container

        if WindowInfo.EnableSidebarResize then
            local SidebarGrabber = New("TextButton", {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Text = "",
                Size = UDim2.new(0, 12, 1, -70),
                Position = UDim2.fromOffset(InitialSidebarWidth - 6, 49),
                ZIndex = 5,
                Parent = MainFrame,
            })
            LayoutRefs.SidebarGrabber = SidebarGrabber

            SidebarGrabber.MouseEnter:Connect(function()
                if Library.Toggled then
                    SetSidebarHighlight(true)
                end
            end)
            SidebarGrabber.MouseLeave:Connect(function()
                if not SidebarDrag.Active then
                    SetSidebarHighlight(false)
                end
            end)

            Library:GiveSignal(SidebarGrabber.InputBegan:Connect(function(input)
                if not Library.Toggled then
                    return
                end

                if
                    input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch
                then
                    return
                end

                SidebarDrag.Active = true
                SidebarDrag.StartWidth = GetSidebarWidth()
                SidebarDrag.StartX = input.Position.X
                SidebarDrag.TouchId = input.UserInputType == Enum.UserInputType.Touch and input or nil

                SetSidebarHighlight(true)

                local Connection
                Connection = Library:GiveSignal(input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        SidebarDrag.Active = false
                        SidebarDrag.TouchId = nil

                        local IsOver = Library:MouseIsOverFrame(SidebarGrabber, Vector2.new(Mouse.X, Mouse.Y))
                        SetSidebarHighlight(IsOver and Library.Toggled)

                        if Connection then
                            Connection:Disconnect()
                        end
                    end
                end))
            end))

            Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
                if Library.Unloaded then
                    return
                end

                if not SidebarDrag.Active then
                    return
                end

                if not Library.Toggled then
                    SidebarDrag.Active = false
                    SidebarDrag.TouchId = nil
                    SetSidebarHighlight(false)
                    return
                end

                if input.UserInputType == Enum.UserInputType.MouseMovement or input == SidebarDrag.TouchId then
                    local Delta = input.Position.X - SidebarDrag.StartX
                    SetSidebarWidth(SidebarDrag.StartWidth + Delta)
                end
            end))

            Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
                if Library.Unloaded then
                    return
                end

                if not SidebarDrag.Active then
                    return
                end

                if
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                    or input == SidebarDrag.TouchId
                then
                    SidebarDrag.Active = false
                    SidebarDrag.TouchId = nil
                    local IsOver = Library:MouseIsOverFrame(SidebarGrabber, Vector2.new(Mouse.X, Mouse.Y))
                    SetSidebarHighlight(IsOver and Library.Toggled)
                end
            end))

            SetSidebarHighlight(false)
        end

        task.defer(function()
            EnsureSidebarBounds()
            ApplySidebarLayout()
        end)
    end

    --// Window Table \\--
    Window = {}

    function Window:GetSidebarWidth()
        return GetSidebarWidth()
    end

    function Window:IsSidebarCompacted()
        return LayoutState.IsCompact
    end

    function Window:SetSidebarWidth(Width)
        SetSidebarWidth(Width)
    end

    function Window:SetCompact(State)
        assert(typeof(State) == "boolean", "State must be a boolean")

        local Threshold = LayoutState.MinWidth * LayoutState.CollapseThreshold
        if State then
            SetSidebarWidth(Threshold * 0.5)
        else
            SetSidebarWidth(LayoutState.LastExpandedWidth or LayoutState.CurrentWidth or LayoutState.MinWidth)
        end
    end

    function Window:ApplyLayout()
        ApplySidebarLayout()
    end

    function Window:ChangeTitle(title)
        assert(typeof(title) == "string", "Expected string for title got: " .. typeof(title))
        
        WindowTitle.Text = title
        WindowInfo.Title = title
    end

    function Window:AddTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
        else
            Name = select(1, ...)
            Icon = select(2, ...)
            Description = select(3, ...)
        end

        local TabButton: TextButton
        local TabLabel
        local TabIcon
        local TabIndicatorRef
        local TabGlowRef

        local TabContainer
        local TabLeft
        local TabRight

        Icon = Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                Parent = Tabs,
            })

            local ButtonPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, LayoutState.IsCompact and 7 or 11),
                PaddingLeft = UDim.new(0, LayoutState.IsCompact and 14 or 12),
                PaddingRight = UDim.new(0, LayoutState.IsCompact and 14 or 12),
                PaddingTop = UDim.new(0, LayoutState.IsCompact and 7 or 11),
                Parent = TabButton,
            })
            table.insert(LayoutRefs.TabPadding, ButtonPadding)

            -- Active indicator bar (left side accent line)
            local TabIndicator = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "AccentColor",
                Position = UDim2.new(0, -8, 0.5, 0),
                Size = UDim2.fromOffset(4, 0),
                Parent = TabButton,
            })
            New("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = TabIndicator,
            })

            -- Purple glow effect for active tab indicator
            local TabGlow = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://6015897843",
                ImageColor3 = "AccentColor",
                ImageTransparency = 1,
                Position = UDim2.new(0, -6, 0.5, 0),
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(49, 49, 450, 450),
                Size = UDim2.fromOffset(20, 40),
                ZIndex = -1,
                Parent = TabButton,
            })

            -- Secondary outer glow for depth
            local TabGlowOuter = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://6015897843",
                ImageColor3 = "AccentColor",
                ImageTransparency = 1,
                Position = UDim2.new(0, -6, 0.5, 0),
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(49, 49, 450, 450),
                Size = UDim2.fromOffset(35, 55),
                ZIndex = -2,
                Parent = TabButton,
            })

            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -30, 1, 0),
                Text = Name,
                TextSize = 16,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not LayoutState.IsCompact,
                Parent = TabButton,
            })
            table.insert(LayoutRefs.TabLabels, TabLabel)

            if Icon then
                TabIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "White" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                    Parent = TabButton,
                })
            end

            -- Store indicator references for animation
            TabIndicatorRef = TabIndicator
            TabGlowRef = TabGlow
            local TabGlowOuterRef = TabGlowOuter

            --// Tab Container \\--
            TabContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            TabLeft = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarThickness = 0,
                Parent = TabContainer,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = TabLeft,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabLeft,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabLeft,
                })

                TabLeft.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, 0)
                Library:UpdateDPI(TabLeft, { Size = TabLeft.Size })
            end

            TabRight = New("ScrollingFrame", {
                AnchorPoint = Vector2.new(1, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                Position = UDim2.fromScale(1, 0),
                ScrollBarThickness = 0,
                Parent = TabContainer,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = TabRight,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabRight,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabRight,
                })

                TabRight.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, 0)
                Library:UpdateDPI(TabRight, { Size = TabRight.Size })
            end
		end

        --// Warning Box \\--
		local WarningBoxHolder = New("Frame", {
		    AutomaticSize = Enum.AutomaticSize.Y,
		    BackgroundTransparency = 1,
		    Position = UDim2.fromOffset(2, 6),
		    Size = UDim2.fromScale(1, 0),
		    Visible = false,
		    Parent = TabContainer
		})

		local WarningBoxBackground, WarningBoxOutline = Library:MakeOutline(WarningBoxHolder, WindowInfo.CornerRadius)
		WarningBoxBackground.Size = UDim2.fromScale(1, 0)
		Library:UpdateDPI(WarningBoxBackground, {
		    Size = false,
		})

		local WarningBox
		local WarningBoxScrollingFrame
		local WarningTitle
		local WarningStroke
		local WarningText
		do
		    WarningBox = New("Frame", {
		        BackgroundColor3 = "BackgroundColor",
		        Position = UDim2.fromOffset(2, 2),
		        Size = UDim2.new(1, -4, 0, 100),
		        Parent = WarningBoxBackground,
		    })
		    New("UICorner", {
		        CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
		        Parent = WarningBox,
		    })
		    
		    WarningBoxScrollingFrame = New("ScrollingFrame", {
		        BackgroundTransparency = 1,
		        BorderSizePixel = 0,
		        Size = UDim2.fromScale(1, 1),
		        CanvasSize = UDim2.new(0, 0, 0, 0),
		        ScrollBarThickness = 3,
		        ScrollingDirection = Enum.ScrollingDirection.Y,
		        Parent = WarningBox,
		    })
		    
		    New("UIPadding", {
		        PaddingBottom = UDim.new(0, 4),
		        PaddingLeft = UDim.new(0, 6),
		        PaddingRight = UDim.new(0, 6),
		        PaddingTop = UDim.new(0, 4),
		        Parent = WarningBoxScrollingFrame,
		    })
		    
		    WarningTitle = New("TextLabel", {
		        BackgroundTransparency = 1,
		        Size = UDim2.new(1, -4, 0, 14),
		        Text = "",
		        TextColor3 = Color3.fromRGB(255, 50, 50),
		        TextSize = 14,
		        TextXAlignment = Enum.TextXAlignment.Left,
		        Parent = WarningBoxScrollingFrame,
		    })
		    
		    WarningStroke = New("UIStroke", {
		        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		        Color = Color3.fromRGB(169, 0, 0),
		        LineJoinMode = Enum.LineJoinMode.Miter,
		        Parent = WarningTitle,
		    })
		    
		    WarningText = New("TextLabel", {
		        BackgroundTransparency = 1,
		        Position = UDim2.fromOffset(0, 16),
		        Size = UDim2.new(1, -4, 0, 0),
		        Text = "",
		        TextSize = 14,
		        TextWrapped = true,
		        Parent = WarningBoxScrollingFrame,
		        TextXAlignment = Enum.TextXAlignment.Left,
		        TextYAlignment = Enum.TextYAlignment.Top,
		    })
		    
		    New("UIStroke", {
		        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		        Color = "Dark",
		        LineJoinMode = Enum.LineJoinMode.Miter,
		        Parent = WarningText,
		    })
		end

        --// Tab Table \\--
        local Tab = {
            Groupboxes = {},
            Tabboxes = {},
            DependencyGroupboxes = {},
            Sides = {
                TabLeft,
                TabRight,
            },
            WarningBox = {
                IsNormal = false,
                LockSize = false,
                Visible = false,
                Title = "WARNING",
                Text = "",
            },
        }

        function Tab:UpdateWarningBox(Info)
		    if typeof(Info.IsNormal) == "boolean" then
		        Tab.WarningBox.IsNormal = Info.IsNormal
		    end
		    if typeof(Info.LockSize) == "boolean" then
		        Tab.WarningBox.LockSize = Info.LockSize
		    end
		    if typeof(Info.Visible) == "boolean" then
		        Tab.WarningBox.Visible = Info.Visible
		    end
		    if typeof(Info.Title) == "string" then
		        Tab.WarningBox.Title = Info.Title
		    end
		    if typeof(Info.Text) == "string" then
		        Tab.WarningBox.Text = Info.Text
		    end

		    WarningBoxHolder.Visible = Tab.WarningBox.Visible
		    WarningTitle.Text = Tab.WarningBox.Title
		    WarningText.Text = Tab.WarningBox.Text
		    Tab:Resize(true)

		    WarningBox.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor
		        or Color3.fromRGB(127, 0, 0)

		    WarningBoxBackground.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.Dark
		        or Color3.fromRGB(169, 0, 0)
	        WarningBoxOutline.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
	            or Color3.fromRGB(255, 50, 50)
		    
		    WarningTitle.TextColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor
		        or Color3.fromRGB(255, 50, 50)
		    WarningStroke.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
		        or Color3.fromRGB(169, 0, 0)

		    if not Library.Registry[WarningBox] then
		        Library:AddToRegistry(WarningBox, {})
		    end
		    if not Library.Registry[WarningBoxBackground] then
		        Library:AddToRegistry(WarningBoxBackground, {})
		    end
		    if not Library.Registry[WarningBoxOutline] then
		        Library:AddToRegistry(WarningBoxOutline, {})
		    end
		    if not Library.Registry[WarningTitle] then
		        Library:AddToRegistry(WarningTitle, {})
		    end
		    if not Library.Registry[WarningStroke] then
		        Library:AddToRegistry(WarningStroke, {})
		    end

		    Library.Registry[WarningBox].BackgroundColor3 = function()
		        return Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor or Color3.fromRGB(127, 0, 0)
		    end

		    Library.Registry[WarningBoxBackground].BackgroundColor3 = function()
		        return Tab.WarningBox.IsNormal == true and Library.Scheme.Dark or Color3.fromRGB(169, 0, 0)
		    end
		    
	        Library.Registry[WarningBoxOutline].BackgroundColor3 = function()
	            return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(255, 50, 50)
	        end

		    Library.Registry[WarningTitle].TextColor3 = function()
		        return Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor or Color3.fromRGB(255, 50, 50)
		    end

		    Library.Registry[WarningStroke].Color = function()
		        return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(169, 0, 0)
		    end
		end

        function Tab:RefreshSides()
		    local Offset = WarningBoxHolder.Visible and WarningBoxBackground.AbsoluteSize.Y + 6 or 0
		    for _, Side in pairs(Tab.Sides) do
		        Side.Position = UDim2.new(Side.Position.X.Scale, 0, 0, Offset)
		        Side.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, -Offset)
		        Library:UpdateDPI(Side, {
		            Position = Side.Position,
		            Size = Side.Size,
		        })
		    end
		end

        function Tab:Resize(ResizeWarningBox: boolean?)
		    if ResizeWarningBox then
		        local MaximumSize = math.floor(TabContainer.AbsoluteSize.Y / 3.25)
		        local _, YText = Library:GetTextBounds(
		            WarningText.Text,
		            Library.Scheme.Font,
		            WarningText.TextSize,
		            WarningText.AbsoluteSize.X
		        )

		        local YBox = 24 + YText
		        if Tab.WarningBox.LockSize == true and YBox >= MaximumSize then
		            WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, YBox)
		            YBox = MaximumSize
		        else
		            WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
		        end

		        WarningText.Size = UDim2.new(1, -4, 0, YText)
		        Library:UpdateDPI(WarningText, { Size = WarningText.Size })

		        WarningBox.Size = UDim2.new(1, -4, 0, YBox)
		        Library:UpdateDPI(WarningBox, { Size = WarningBox.Size })

		        WarningBoxBackground.Size = UDim2.new(1, 0, 0, YBox + 4 * Library.DPIScale)
		    end

		    Tab:RefreshSides()
		end

        function Tab:AddGroupbox(Info)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = Info.Side == 1 and TabLeft or TabRight,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })

            local Background = Library:MakeOutline(BoxHolder, WindowInfo.CornerRadius)
            Background.Size = UDim2.fromScale(1, 0)
            Library:UpdateDPI(Background, {
                Size = false,
            })

            -- Purple shadow effect for groupbox
            local GroupboxShadow = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://6015897843",
                ImageColor3 = Library.Scheme.AccentColor,
                ImageTransparency = 0.92,
                Position = UDim2.fromScale(0.5, 0.5),
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(49, 49, 450, 450),
                Size = UDim2.new(1, 20, 1, 20),
                ZIndex = -1,
                Parent = Background,
            })
            Library.Registry[GroupboxShadow] = { ImageColor3 = "AccentColor" }

            local GroupboxHolder
            local GroupboxLabel
            local GroupboxDescription
            local CollapseArrow

            local GroupboxContainer
            local GroupboxList

            local isCollapsed = false
            local headerHeight = Info.Description and 50 or 34

            do
                GroupboxHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(2, 2),
                    Size = UDim2.new(1, -4, 1, -4),
                    Parent = Background,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
                    Parent = GroupboxHolder,
                })
                Library:MakeLine(GroupboxHolder, {
                    Position = UDim2.fromOffset(0, headerHeight),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local BoxIcon = Library:GetCustomIcon(Info.IconName)
                local BoxIconImage
                if BoxIcon then
                    BoxIconImage = New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "White" or "AccentColor",
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        Position = UDim2.fromOffset(6, 6),
                        Size = UDim2.fromOffset(22, 22),
                        Parent = GroupboxHolder,
                    })
                end

                GroupboxLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(BoxIcon and 24 or 0, 0),
                    Size = UDim2.new(1, Info.Description and -30 or 0, 0, Info.Description and 18 or 34),
                    Text = Info.Name,
                    TextSize = 15,
                    TextTransparency = 0.1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = GroupboxHolder,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                    Parent = GroupboxLabel,
                })

                -- Description label (dark gray)
                if Info.Description then
                    GroupboxDescription = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(BoxIcon and 24 or 0, 18),
                        Size = UDim2.new(1, -30, 0, 16),
                        Text = Info.Description,
                        TextSize = 13,
                        TextTransparency = 0.5,
                        TextColor3 = Color3.fromRGB(150, 150, 150),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = GroupboxHolder,
                    })
                    New("UIPadding", {
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12),
                        Parent = GroupboxDescription,
                    })
                end

                -- Collapse/Expand arrow
                CollapseArrow = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -30, 0, 0),
                    Size = UDim2.new(0, 30, 0, headerHeight),
                    Text = "▼",
                    TextSize = 12,
                    TextTransparency = 0.3,
                    Parent = GroupboxHolder,
                })
                Library.Registry[CollapseArrow] = { TextColor3 = "FontColor" }

                -- Hover effect for groupbox header
                local HeaderHoverRegion = New("TextButton", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.new(1, 0, 0, headerHeight),
                    Text = "",
                    Parent = GroupboxHolder,
                })

                HeaderHoverRegion.MouseEnter:Connect(function()
                    TweenService:Create(GroupboxLabel, Library.HoverTweenInfo, {
                        TextTransparency = 0,
                        TextColor3 = Library.Scheme.AccentColor,
                    }):Play()
                    TweenService:Create(CollapseArrow, Library.HoverTweenInfo, {
                        TextTransparency = 0,
                        TextColor3 = Library.Scheme.AccentColor,
                    }):Play()
                    if BoxIconImage then
                        TweenService:Create(BoxIconImage, Library.HoverTweenInfo, {
                            ImageTransparency = 0,
                            Rotation = 5,
                        }):Play()
                    end
                end)

                HeaderHoverRegion.MouseLeave:Connect(function()
                    TweenService:Create(GroupboxLabel, Library.HoverTweenInfo, {
                        TextTransparency = 0.1,
                        TextColor3 = Library.Scheme.FontColor,
                    }):Play()
                    TweenService:Create(CollapseArrow, Library.HoverTweenInfo, {
                        TextTransparency = 0.3,
                        TextColor3 = Library.Scheme.FontColor,
                    }):Play()
                    if BoxIconImage then
                        TweenService:Create(BoxIconImage, Library.HoverTweenInfo, {
                            ImageTransparency = 0,
                            Rotation = 0,
                        }):Play()
                    end
                end)

                -- Click to collapse/expand
                HeaderHoverRegion.MouseButton1Click:Connect(function()
                    isCollapsed = not isCollapsed

                    -- Animate arrow rotation
                    TweenService:Create(CollapseArrow, Library.HoverTweenInfo, {
                        Rotation = isCollapsed and -90 or 0,
                    }):Play()

                    -- Animate container visibility
                    if isCollapsed then
                        GroupboxContainer.Visible = false
                        TweenService:Create(Background, Library.HoverTweenInfo, {
                            Size = UDim2.new(1, 0, 0, headerHeight + 4),
                        }):Play()
                    else
                        GroupboxContainer.Visible = true
                        local targetHeight = GroupboxList.AbsoluteContentSize.Y + headerHeight + 19
                        TweenService:Create(Background, Library.HoverTweenInfo, {
                            Size = UDim2.new(1, 0, 0, targetHeight * Library.DPIScale),
                        }):Play()
                    end
                end)

                GroupboxContainer = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, headerHeight + 1),
                    Size = UDim2.new(1, 0, 1, -(headerHeight + 1)),
                    Parent = GroupboxHolder,
                })

                GroupboxList = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = GroupboxContainer,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
                    Parent = GroupboxContainer,
                })
            end

            local Groupbox = {
                BoxHolder = BoxHolder,
                Holder = Background,
                Container = GroupboxContainer,
                HeaderHeight = headerHeight,
                IsCollapsed = isCollapsed,

                Tab = Tab,
                DependencyBoxes = {},
                Elements = {},
            }

            function Groupbox:Resize()
                if not isCollapsed then
                    local contentHeight = GroupboxList.AbsoluteContentSize.Y + headerHeight + 19
                    Background.Size = UDim2.new(1, 0, 0, contentHeight * Library.DPIScale)
                end
            end

            setmetatable(Groupbox, BaseGroupbox)

            Groupbox:Resize()
            Tab.Groupboxes[Info.Name] = Groupbox

            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name, IconName, Description)
            return Tab:AddGroupbox({ Side = 1, Name = Name, IconName = IconName, Description = Description })
        end

        function Tab:AddRightGroupbox(Name, IconName, Description)
            return Tab:AddGroupbox({ Side = 2, Name = Name, IconName = IconName, Description = Description })
        end

        function Tab:AddTabbox(Info)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = Info.Side == 1 and TabLeft or TabRight,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })

            local Background = Library:MakeOutline(BoxHolder, WindowInfo.CornerRadius)
            Background.Size = UDim2.fromScale(1, 0)
            Library:UpdateDPI(Background, {
                Size = false,
            })

            local TabboxHolder
            local TabboxButtons

            do
                TabboxHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(2, 2),
                    Size = UDim2.new(1, -4, 1, -4),
                    Parent = Background,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
                    Parent = TabboxHolder,
                })

                TabboxButtons = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 34),
                    Parent = TabboxHolder,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Parent = TabboxButtons,
                })
            end

            local Tabbox = {
                ActiveTab = nil,

                BoxHolder = BoxHolder,
                Holder = Background,
                Tabs = {},
            }

            function Tabbox:AddTab(Name)
                local Button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 0,
                    Size = UDim2.fromOffset(0, 34),
                    Text = Name,
                    TextSize = 15,
                    TextTransparency = 0.5,
                    Parent = TabboxButtons,
                })

                local Line = Library:MakeLine(Button, {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 0, 1, 1),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local Container = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 1, -35),
                    Visible = false,
                    Parent = TabboxHolder,
                })
                local List = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = Container,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
                    Parent = Container,
                })

                local Tab = {
                    ButtonHolder = Button,
                    Container = Container,

                    Tab = Tab,
                    Elements = {},
                    DependencyBoxes = {},
                }

                function Tab:Show()
                    if Tabbox.ActiveTab then
                        Tabbox.ActiveTab:Hide()
                    end

                    Button.BackgroundTransparency = 1
                    Button.TextTransparency = 0
                    Line.Visible = false

                    Container.Visible = true

                    Tabbox.ActiveTab = Tab
                    Tab:Resize()
                end

                function Tab:Hide()
                    Button.BackgroundTransparency = 0
                    Button.TextTransparency = 0.5
                    Line.Visible = true
                    Container.Visible = false

                    Tabbox.ActiveTab = nil
                end

                function Tab:Resize()
                    if Tabbox.ActiveTab ~= Tab then
                        return
                    end
                    Background.Size = UDim2.new(1, 0, 0, List.AbsoluteContentSize.Y + 53 * Library.DPIScale)
                end

                --// Execution \\--
                if not Tabbox.ActiveTab then
                    Tab:Show()
                end

                Button.MouseButton1Click:Connect(Tab.Show)

                setmetatable(Tab, BaseGroupbox)

                Tabbox.Tabs[Name] = Tab

                return Tab
            end

            if Info.Name then
                Tab.Tabboxes[Info.Name] = Tabbox
            else
                table.insert(Tab.Tabboxes, Tabbox)
            end

            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Side = 1, Name = Name })
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Side = 2, Name = Name })
        end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.HoverTweenInfo, {
                TextTransparency = Hovering and 0.15 or 0.5,
            }):Play()
            TweenService:Create(TabButton, Library.HoverTweenInfo, {
                BackgroundTransparency = Hovering and 0.85 or 1,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.HoverTweenInfo, {
                    ImageTransparency = Hovering and 0.15 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            -- Animate tab button background
            TweenService:Create(TabButton, Library.FadeTweenInfo, {
                BackgroundTransparency = 0,
            }):Play()

            -- Animate label with accent color tint
            TweenService:Create(TabLabel, Library.FadeTweenInfo, {
                TextTransparency = 0,
            }):Play()

            -- Animate icon
            if TabIcon then
                TweenService:Create(TabIcon, Library.FadeTweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end

            -- Animate indicator bar (expand from center)
            TweenService:Create(TabIndicatorRef, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(4, 28),
            }):Play()

            -- Animate glow effect (inner)
            TweenService:Create(TabGlowRef, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                ImageTransparency = 0.5,
                Size = UDim2.fromOffset(24, 45),
            }):Play()

            -- Animate outer glow
            if TabGlowOuterRef then
                TweenService:Create(TabGlowOuterRef, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
                    ImageTransparency = 0.75,
                    Size = UDim2.fromOffset(40, 60),
                }):Play()
            end

            if Description then
                CurrentTabInfo.Visible = true

                if IsDefaultSearchbarSize then
                    SearchBox.Size = UDim2.fromScale(0.5, 1)
                end

                CurrentTabLabel.Text = Name
                CurrentTabDescription.Text = Description
            end

            TabContainer.Visible = true
            Tab:RefreshSides()

            Library.ActiveTab = Tab

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            -- Animate tab button
            TweenService:Create(TabButton, Library.FadeTweenInfo, {
                BackgroundTransparency = 1,
            }):Play()

            -- Animate label
            TweenService:Create(TabLabel, Library.FadeTweenInfo, {
                TextTransparency = 0.5,
                TextColor3 = Library.Scheme.FontColor,
            }):Play()

            -- Animate icon
            if TabIcon then
                TweenService:Create(TabIcon, Library.FadeTweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end

            -- Animate indicator bar (collapse to center)
            TweenService:Create(TabIndicatorRef, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(4, 0),
            }):Play()

            -- Animate glow effect out (inner)
            TweenService:Create(TabGlowRef, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                ImageTransparency = 1,
                Size = UDim2.fromOffset(20, 40),
            }):Play()

            -- Animate outer glow out
            if TabGlowOuterRef then
                TweenService:Create(TabGlowOuterRef, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
                    ImageTransparency = 1,
                    Size = UDim2.fromOffset(35, 55),
                }):Play()
            end

            TabContainer.Visible = false

            if IsDefaultSearchbarSize then
                SearchBox.Size = UDim2.fromScale(1, 1)
            end

            CurrentTabInfo.Visible = false

            Library.ActiveTab = nil
        end

        --// Execution \\--
        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddKeyTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
        else
            Name = select(1, ...) or "Tab"
            Icon = select(2, ...)
            Description = select(3, ...)
        end

        Icon = Icon or "key"

        local TabButton: TextButton
        local TabLabel
        local TabIcon

        local TabContainer

        Icon = if Icon == "key" then KeyIcon else Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                Parent = Tabs,
            })
            local KeyTabPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, LayoutState.IsCompact and 7 or 11),
                PaddingLeft = UDim.new(0, LayoutState.IsCompact and 14 or 12),
                PaddingRight = UDim.new(0, LayoutState.IsCompact and 14 or 12),
                PaddingTop = UDim.new(0, LayoutState.IsCompact and 7 or 11),
                Parent = TabButton,
            })
            table.insert(LayoutRefs.TabPadding, KeyTabPadding)

            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -30, 1, 0),
                Text = Name,
                TextSize = 16,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not LayoutState.IsCompact,
                Parent = TabButton,
            })
            table.insert(LayoutRefs.TabLabels, TabLabel)

            if Icon then
                TabIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "White" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                    Parent = TabButton,
                })
            end

            --// Tab Container \\--
            TabContainer = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarThickness = 0,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })
            New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = TabContainer,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 1),
                PaddingRight = UDim.new(0, 1),
                Parent = TabContainer,
            })
        end

        --// Tab Table \\--
        local Tab = {
            Elements = {},
            IsKeyTab = true,
        }

        function Tab:AddKeyBox(...)
            local Data = {}

            local First = select(1, ...)

            if typeof(First) == "function" then
                Data.Callback = First
            else
                Data.ExpectedKey = First
                Data.Callback = select(2, ...)
            end

            local Holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.75, 0, 0, 21),
                Parent = TabContainer,
            })

            local Box = New("TextBox", {
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                PlaceholderText = "Key",
                Size = UDim2.new(1, -71, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Box,
            })

            local Button = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 63, 1, 0),
                Text = "Execute",
                TextSize = 14,
                Parent = Holder,
            })

            Button.MouseButton1Click:Connect(function()
                if Data.ExpectedKey and Box.Text ~= Data.ExpectedKey then
                    Data.Callback(false, Box.Text)
                    return
                end

                Data.Callback(true, Box.Text)
            end)
        end

        function Tab:RefreshSides() end
        function Tab:Resize() end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.HoverTweenInfo, {
                TextTransparency = Hovering and 0.15 or 0.5,
            }):Play()
            TweenService:Create(TabButton, Library.HoverTweenInfo, {
                BackgroundTransparency = Hovering and 0.85 or 1,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.HoverTweenInfo, {
                    ImageTransparency = Hovering and 0.15 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.FadeTweenInfo, {
                BackgroundTransparency = 0,
            }):Play()
            TweenService:Create(TabLabel, Library.FadeTweenInfo, {
                TextTransparency = 0,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.FadeTweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end
            TabContainer.Visible = true

            if Description then
                CurrentTabInfo.Visible = true

                if IsDefaultSearchbarSize then
                    SearchBox.Size = UDim2.fromScale(0.5, 1)
                end

                CurrentTabLabel.Text = Name
                CurrentTabDescription.Text = Description
            end

            Tab:RefreshSides()

            Library.ActiveTab = Tab

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.FadeTweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.FadeTweenInfo, {
                TextTransparency = 0.5,
                TextColor3 = Library.Scheme.FontColor,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.FadeTweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end
            TabContainer.Visible = false

            if IsDefaultSearchbarSize then
                SearchBox.Size = UDim2.fromScale(1, 1)
            end

            CurrentTabInfo.Visible = false

            Library.ActiveTab = nil
        end

        --// Execution \\--
        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Tab.Container = TabContainer
        setmetatable(Tab, BaseGroupbox)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Library:Toggle(Value: boolean?)
        if typeof(Value) == "boolean" then
            Library.Toggled = Value
        else
            Library.Toggled = not Library.Toggled
        end

        local OpenTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local CloseTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

        if Library.Toggled then
            -- Show animation with scale and fade
            MainFrame.Visible = true

            -- Store original position
            local OriginalPos = MainFrame.Position
            local OriginalSize = MainFrame.Size

            -- Start from scaled down and below
            MainFrame.Size = UDim2.new(OriginalSize.X.Scale * 0.95, OriginalSize.X.Offset * 0.95, OriginalSize.Y.Scale * 0.95, OriginalSize.Y.Offset * 0.95)
            MainFrame.Position = OriginalPos + UDim2.fromOffset(OriginalSize.X.Offset * 0.025, 30)
            MainFrame.BackgroundTransparency = 0.5

            -- Animate shadow layers in with staggered timing
            if Library.ShadowLayers then
                for i, layerData in ipairs(Library.ShadowLayers) do
                    local layer = layerData.Layer
                    local targetTransparency = layerData.BaseTransparency
                    layer.ImageTransparency = 1
                    task.delay((i - 1) * 0.04, function()
                        TweenService:Create(layer, OpenTweenInfo, {
                            ImageTransparency = targetTransparency,
                        }):Play()
                    end)
                end
            end

            -- Animate to final state
            local ShowTweenSize = TweenService:Create(MainFrame, OpenTweenInfo, {
                Size = OriginalSize,
                Position = OriginalPos,
                BackgroundTransparency = 0,
            })
            ShowTweenSize:Play()
        else
            -- Hide animation with scale and fade
            local OriginalPos = MainFrame.Position
            local OriginalSize = MainFrame.Size

            -- Animate shadow layers out with staggered timing
            if Library.ShadowLayers then
                for i, layerData in ipairs(Library.ShadowLayers) do
                    local layer = layerData.Layer
                    task.delay((#Library.ShadowLayers - i) * 0.03, function()
                        TweenService:Create(layer, CloseTweenInfo, {
                            ImageTransparency = 1,
                        }):Play()
                    end)
                end
            end

            local HideTween = TweenService:Create(MainFrame, CloseTweenInfo, {
                Size = UDim2.new(OriginalSize.X.Scale * 0.95, OriginalSize.X.Offset * 0.95, OriginalSize.Y.Scale * 0.95, OriginalSize.Y.Offset * 0.95),
                Position = OriginalPos + UDim2.fromOffset(OriginalSize.X.Offset * 0.025, 20),
                BackgroundTransparency = 0.5,
            })
            HideTween:Play()
            HideTween.Completed:Connect(function()
                if not Library.Toggled then
                    MainFrame.Visible = false
                    MainFrame.Size = OriginalSize
                    MainFrame.Position = OriginalPos
                    MainFrame.BackgroundTransparency = 0
                end
            end)
        end

        if WindowInfo.UnlockMouseWhileOpen then
            ModalElement.Modal = Library.Toggled
        end

        if Library.Toggled and not Library.IsMobile then
            local OldMouseIconEnabled = UserInputService.MouseIconEnabled
            pcall(function()
                RunService:UnbindFromRenderStep("ShowCursor")
            end)
            RunService:BindToRenderStep("ShowCursor", Enum.RenderPriority.Last.Value, function()
                UserInputService.MouseIconEnabled = not Library.ShowCustomCursor

                Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                Cursor.Visible = Library.ShowCustomCursor

                if not (Library.Toggled and ScreenGui and ScreenGui.Parent) then
                    UserInputService.MouseIconEnabled = OldMouseIconEnabled
                    Cursor.Visible = false
                    RunService:UnbindFromRenderStep("ShowCursor")
                end
            end)

        elseif not Library.Toggled then
            SetSidebarHighlight(false)
            TooltipLabel.Visible = false

            for _, Option in pairs(Library.Options) do
                if Option.Type == "ColorPicker" then
                    Option.ColorMenu:Close()
                    Option.ContextMenu:Close()

                elseif Option.Type == "Dropdown" or Option.Type == "KeyPicker" then
                    Option.Menu:Close()
                end
            end
        end
    end

    if WindowInfo.AutoShow then
        task.spawn(Library.Toggle)
    end

    if Library.IsMobile then
        -- Toggle button with eye icon (eye/eye-off)
        local ToggleButton = Library:AddIconButton("eye", function(self)
            Library:Toggle()
            self:SetToggled(Library.Toggled)

            -- Animate icon change
            if Library.Toggled then
                self:SetIcon("eye")
            else
                self:SetIcon("eye-off")
            end
        end, {
            Size = 44,
            ToggledIcon = "eye-off",
        })
        ToggleButton:SetToggled(Library.Toggled)

        -- Lock button with lock/unlock icon
        local LockButton = Library:AddIconButton("lock", function(self)
            Library.CantDragForced = not Library.CantDragForced
            self:SetToggled(Library.CantDragForced)

            -- Animate icon change
            if Library.CantDragForced then
                self:SetIcon("lock")
            else
                self:SetIcon("unlock")
            end
        end, {
            Size = 44,
            ToggledIcon = "unlock",
        })

        -- Unload button with power icon (closes the UI completely)
        local UnloadButton = Library:AddIconButton("power", function(self)
            -- Confirm unload with visual feedback
            if not self.ConfirmPending then
                self.ConfirmPending = true
                self:SetIcon("alert-circle")
                TweenService:Create(self.Icon, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                    ImageColor3 = Library.Scheme.Red or Color3.fromRGB(255, 80, 80),
                }):Play()

                -- Reset after 2 seconds if not confirmed
                task.delay(2, function()
                    if self.ConfirmPending then
                        self.ConfirmPending = false
                        self:SetIcon("power")
                        TweenService:Create(self.Icon, TweenInfo.new(0.3), {
                            ImageColor3 = Library.Scheme.FontColor,
                        }):Play()
                    end
                end)
            else
                -- Confirmed - unload the library
                self.ConfirmPending = false
                Library:Unload()
            end
        end, {
            Size = 44,
        })

        if WindowInfo.MobileButtonsSide == "Right" then
            ToggleButton:SetPosition(UDim2.new(1, -6, 0, 6))
            ToggleButton:SetAnchorPoint(Vector2.new(1, 0))

            LockButton:SetPosition(UDim2.new(1, -6, 0, 56))
            LockButton:SetAnchorPoint(Vector2.new(1, 0))

            UnloadButton:SetPosition(UDim2.new(1, -6, 0, 106))
            UnloadButton:SetAnchorPoint(Vector2.new(1, 0))
        else
            ToggleButton:SetPosition(UDim2.fromOffset(6, 6))
            LockButton:SetPosition(UDim2.fromOffset(6, 56))
            UnloadButton:SetPosition(UDim2.fromOffset(6, 106))
        end
    end

    --// Execution \\--
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Library:UpdateSearch(SearchBox.Text)
    end)

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
        if Library.Unloaded then
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if
            (
                typeof(Library.ToggleKeybind) == "table"
                and Library.ToggleKeybind.Type == "KeyPicker"
                and Input.KeyCode.Name == Library.ToggleKeybind.Value
            ) or Input.KeyCode == Library.ToggleKeybind
        then
            Library.Toggle()
        end
    end))

    Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    return Window
end

local function OnPlayerChange()
    if Library.Unloaded then
        return
    end

    local PlayerList, ExcludedPlayerList = GetPlayers(), GetPlayers(true)
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
            Dropdown:SetValues(Dropdown.ExcludeLocalPlayer and ExcludedPlayerList or PlayerList)
        end
    end
end

local function OnTeamChange()
    if Library.Unloaded then
        return
    end

    local TeamList = GetTeams()
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Team" then
            Dropdown:SetValues(TeamList)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

getgenv().Library = Library
return Library
