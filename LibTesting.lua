--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]

local Library do 
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local TextService = game:GetService("TextService")
    local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")

    -- 1. We detect the 'request' function (works in Synapse, KRNL, Fluxus, Solara, etc.)
    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

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
        local function RecursiveCreatePath(Path, IsFile)
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

        function CustomImageManager.AddAsset(AssetName, RobloxAssetId, URL, ForceRedownload)
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

        function CustomImageManager.GetAsset(AssetName)
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

        function CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
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

    function IsValidCustomIcon(Icon)
        return type(Icon) == "string"
            and (Icon:match("rbxasset") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
    end

    local FetchIcons, Icons = pcall(function()
        return loadstring(
            game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua")
        )()
    end)

    gethui = gethui or function()
        return CoreGui
    end

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    local Mouse = LocalPlayer:GetMouse()

    local FromRGB = Color3.fromRGB
    local FromHSV = Color3.fromHSV
    local FromHex = Color3.fromHex

    local RGBSequence = ColorSequence.new
    local RGBSequenceKeypoint = ColorSequenceKeypoint.new
    local NumSequence = NumberSequence.new
    local NumSequenceKeypoint = NumberSequenceKeypoint.new

    local UDim2New = UDim2.new
    local UDimNew = UDim.new
    local UDim2FromOffset = UDim2.fromOffset
    local Vector2New = Vector2.new
    local Vector3New = Vector3.new

    local MathClamp = math.clamp
    local MathFloor = math.floor
    local MathAbs = math.abs
    local MathSin = math.sin

    local TableInsert = table.insert
    local TableFind = table.find
    local TableRemove = table.remove
    local TableConcat = table.concat
    local TableClone = table.clone
    local TableUnpack = table.unpack

    local StringFormat = string.format
    local StringFind = string.find
    local StringGSub = string.gsub
    local StringLower = string.lower
    local StringLen = string.len

    local InstanceNew = Instance.new

    local RectNew = Rect.new

    local IsMobile = UserInputService.TouchEnabled or false

    Library = {
        Theme =  { },

        MenuKeybind = tostring(Enum.KeyCode.RightControl), 

        Flags = { },

        Tween = {
            Time = 0.3,
            Style = Enum.EasingStyle.Quad,
            Direction = Enum.EasingDirection.Out
        },

        FadeSpeed = 0.2,

        Folders = {
            Directory = "lyapossss",
            Configs = "lyapossss/Configs",
            Assets = "lyapossss/Assets",
        },

        -- Ignore below
        Pages = { },
        Sections = { },

        Connections = { },
        Threads = { },

        ThemeMap = { },
        ThemeItems = { },
        ThemeCallbacks = { },

        OpenFrames = { },

        SetFlags = { },

        UnnamedConnections = 0,
        UnnamedFlags = 0,

        Holder = nil,
        NotifHolder = nil,
        UnusedHolder = nil,

        Font = nil,

        MinSize = Vector2New(480, 360)
    }

    local Tween, Instances

    Library.GetIcon = function(self, IconName)
        if not FetchIcons then
            return
        end

        local Success, Icon = pcall(Icons.GetAsset, IconName)
        if not Success then
            return
        end
        return Icon
    end

    Library.GetCustomIcon = function(self, IconName)
        if IsValidCustomIcon(IconName) then
            return {
                Url = IconName,
                ImageRectOffset = Vector2New(0, 0),
                ImageRectSize = Vector2New(0, 0),
                Custom = true,
            }
        end

        local Icon = self:GetIcon(IconName)
        if Icon then
            if type(Icon) == "string" then
                return {
                    Url = Icon,
                    ImageRectOffset = Vector2New(0, 0),
                    ImageRectSize = Vector2New(0, 0),
                    Custom = true,
                }
            end
            return Icon
        end

        if tonumber(IconName) then
            return {
                Url = "rbxassetid://" .. IconName,
                ImageRectOffset = Vector2New(0, 0),
                ImageRectSize = Vector2New(0, 0),
                Custom = true,
            }
        end

        return nil
    end

    Library.__index = Library
    Library.Sections.__index = Library.Sections
    Library.Pages.__index = Library.Pages

    local Keys = {
        ["Unknown"]           = "Unknown",
        ["Backspace"]         = "Back",
        ["Tab"]               = "Tab",
        ["Clear"]             = "Clear",
        ["Return"]            = "Return",
        ["Pause"]             = "Pause",
        ["Escape"]            = "Escape",
        ["Space"]             = "Space",
        ["QuotedDouble"]      = '"',
        ["Hash"]              = "#",
        ["Dollar"]            = "$",
        ["Percent"]           = "%",
        ["Ampersand"]         = "&",
        ["Quote"]             = "'",
        ["LeftParenthesis"]   = "(",
        ["RightParenthesis"]  = " )",
        ["Asterisk"]          = "*",
        ["Plus"]              = "+",
        ["Comma"]             = ",",
        ["Minus"]             = "-",
        ["Period"]            = ".",
        ["Slash"]             = "`",
        ["Three"]             = "3",
        ["Seven"]             = "7",
        ["Eight"]             = "8",
        ["Colon"]             = ":",
        ["Semicolon"]         = ";",
        ["LessThan"]          = "<",
        ["GreaterThan"]       = ">",
        ["Question"]          = "?",
        ["Equals"]            = "=",
        ["At"]                = "@",
        ["LeftBracket"]       = "LeftBracket",
        ["RightBracket"]      = "RightBracked",
        ["BackSlash"]         = "BackSlash",
        ["Caret"]             = "^",
        ["Underscore"]        = "_",
        ["Backquote"]         = "`",
        ["LeftCurly"]         = "{",
        ["Pipe"]              = "|",
        ["RightCurly"]        = "}",
        ["Tilde"]             = "~",
        ["Delete"]            = "Delete",
        ["End"]               = "End",
        ["KeypadZero"]        = "Keypad0",
        ["KeypadOne"]         = "Keypad1",
        ["KeypadTwo"]         = "Keypad2",
        ["KeypadThree"]       = "Keypad3",
        ["KeypadFour"]        = "Keypad4",
        ["KeypadFive"]        = "Keypad5",
        ["KeypadSix"]         = "Keypad6",
        ["KeypadSeven"]       = "Keypad7",
        ["KeypadEight"]       = "Keypad8",
        ["KeypadNine"]        = "Keypad9",
        ["KeypadPeriod"]      = "KeypadP",
        ["KeypadDivide"]      = "KeypadD",
        ["KeypadMultiply"]    = "KeypadM",
        ["KeypadMinus"]       = "KeypadM",
        ["KeypadPlus"]        = "KeypadP",
        ["KeypadEnter"]       = "KeypadE",
        ["KeypadEquals"]      = "KeypadE",
        ["Insert"]            = "Insert",
        ["Home"]              = "Home",
        ["PageUp"]            = "PageUp",
        ["PageDown"]          = "PageDown",
        ["RightShift"]        = "RightShift",
        ["LeftShift"]         = "LeftShift",
        ["RightControl"]      = "RightControl",
        ["LeftControl"]       = "LeftControl",
        ["LeftAlt"]           = "LeftAlt",
        ["RightAlt"]          = "RightAlt"
    }

    local Themes = {
        ["Preset"] = {
            ["AccentGradient"] = FromRGB(109, 43, 139),
            ["Background 2"] = FromRGB(10, 10, 12),
            ["Background"] = FromRGB(12, 12, 14),
            ["Text"] = FromRGB(235, 235, 235),
            ["Outline"] = FromRGB(25, 25, 28),
            ["Section Top"] = FromRGB(28, 27, 31),
            ["Section Background"] = FromRGB(10, 10, 12),
            ["Section Background 2"] = FromRGB(14, 14, 16),
            ["Accent"] = FromRGB(151, 69, 186),
            ["Element"] = FromRGB(16, 16, 18)
        },
        ["Dark"] = {
            ["AccentGradient"] = FromRGB(50, 50, 55),
            ["Background 2"] = FromRGB(6, 6, 8),
            ["Background"] = FromRGB(9, 9, 11),
            ["Text"] = FromRGB(220, 220, 220),
            ["Outline"] = FromRGB(22, 22, 24),
            ["Section Top"] = FromRGB(22, 22, 25),
            ["Section Background"] = FromRGB(8, 8, 10),
            ["Section Background 2"] = FromRGB(12, 12, 14),
            ["Accent"] = FromRGB(90, 90, 100),
            ["Element"] = FromRGB(14, 14, 16)
        },
        ["Flame"] = {
            ["AccentGradient"] = FromRGB(160, 50, 10),
            ["Background 2"] = FromRGB(8, 6, 6),
            ["Background"] = FromRGB(10, 8, 8),
            ["Text"] = FromRGB(235, 225, 215),
            ["Outline"] = FromRGB(30, 18, 14),
            ["Section Top"] = FromRGB(28, 18, 14),
            ["Section Background"] = FromRGB(8, 6, 6),
            ["Section Background 2"] = FromRGB(14, 10, 9),
            ["Accent"] = FromRGB(220, 75, 20),
            ["Element"] = FromRGB(18, 12, 10)
        },
        ["Plasma"] = {
            ["AccentGradient"] = FromRGB(130, 10, 130),
            ["Background 2"] = FromRGB(8, 6, 10),
            ["Background"] = FromRGB(10, 8, 13),
            ["Text"] = FromRGB(235, 220, 240),
            ["Outline"] = FromRGB(28, 18, 34),
            ["Section Top"] = FromRGB(26, 18, 32),
            ["Section Background"] = FromRGB(8, 6, 10),
            ["Section Background 2"] = FromRGB(14, 10, 17),
            ["Accent"] = FromRGB(190, 50, 210),
            ["Element"] = FromRGB(16, 12, 20)
        },
        ["Forest"] = {
            ["AccentGradient"] = FromRGB(18, 100, 30),
            ["Background 2"] = FromRGB(6, 9, 6),
            ["Background"] = FromRGB(8, 11, 8),
            ["Text"] = FromRGB(215, 235, 215),
            ["Outline"] = FromRGB(16, 26, 16),
            ["Section Top"] = FromRGB(18, 28, 18),
            ["Section Background"] = FromRGB(6, 9, 6),
            ["Section Background 2"] = FromRGB(10, 14, 10),
            ["Accent"] = FromRGB(45, 175, 65),
            ["Element"] = FromRGB(12, 17, 12)
        },
        ["Aqua"] = {
            ["AccentGradient"] = FromRGB(10, 110, 140),
            ["Background 2"] = FromRGB(6, 8, 10),
            ["Background"] = FromRGB(8, 10, 13),
            ["Text"] = FromRGB(215, 235, 240),
            ["Outline"] = FromRGB(14, 24, 30),
            ["Section Top"] = FromRGB(16, 26, 32),
            ["Section Background"] = FromRGB(6, 8, 10),
            ["Section Background 2"] = FromRGB(10, 13, 17),
            ["Accent"] = FromRGB(30, 190, 220),
            ["Element"] = FromRGB(11, 15, 19)
        },
    }

    Library.Theme = TableClone(Themes["Preset"])
    Library.Themes = Themes
    Library.ActiveThemePreset = "Default"

    -- Folders
    Library.SetFolder = function(self, Folder)
        self.Folders.Directory = Folder
        self.Folders.Configs = Folder .. "/Configs"
        self.Folders.Assets = Folder .. "/Assets"

        local function RecursiveMakeFolder(Path)
            local Segments = Path:split("/")
            local TraversedPath = ""

            for _, Segment in ipairs(Segments) do
                TraversedPath = TraversedPath .. Segment
                if not isfolder(TraversedPath) then
                    makefolder(TraversedPath)
                end
                TraversedPath = TraversedPath .. "/"
            end
        end

        RecursiveMakeFolder(self.Folders.Directory)
        RecursiveMakeFolder(self.Folders.Configs)
        RecursiveMakeFolder(self.Folders.Assets)
    end

    Library:SetFolder("lyapossss")

    Library.Unload = function(self)
        for Index, Value in self.Connections do 
            Value.Connection:Disconnect()
        end

        for Index, Value in self.Threads do 
            coroutine.close(Value)
        end

        if self.Holder then 
            self.Holder:Clean()
        end

        Library = nil 
        getgenv().Library = nil
    end

    Library.GetImage = function(self, Image)
        local ImageData = self.Images[Image]

        if not ImageData then 
            return
        end

        return getcustomasset(self.Folders.Assets .. "/" .. ImageData[1])
    end

    Library.Round = function(self, Number, Float)
        if not Float or Float == 0 then
            return MathFloor(Number + 0.5)
        end
        local Multiplier = 1 / Float
        return MathFloor(Number * Multiplier + 0.5) / Multiplier
    end

    Library.Thread = function(self, Function)
        local NewThread = coroutine.create(Function)
        
        coroutine.wrap(function()
            coroutine.resume(NewThread)
        end)()

        TableInsert(self.Threads, NewThread)
        return NewThread
    end
    
    Library.SafeCall = function(self, Function, ...)
        local Arguements = { ... }
        local Success, Result = pcall(Function, TableUnpack(Arguements))

        if not Success then
            warn(Result)
            return false
        end

        return Success
    end

    Library.Connect = function(self, Event, Callback, Name)
        Name = Name or StringFormat("connection_number_%s_%s", self.UnnamedConnections + 1, HttpService:GenerateGUID(false))

        local NewConnection = {
            Event = Event,
            Callback = Callback,
            Name = Name,
            Connection = nil
        }

        Library:Thread(function()
            NewConnection.Connection = Event:Connect(Callback)
        end)

        TableInsert(self.Connections, NewConnection)
        return NewConnection
    end

    Library.Disconnect = function(self, Name)
        for _, Connection in self.Connections do 
            if Connection.Name == Name then
                Connection.Connection:Disconnect()
                break
            end
        end
    end

    Library.NextFlag = function(self)
        self.UnnamedFlags = self.UnnamedFlags + 1
        return StringFormat("flag_number_%s", self.UnnamedFlags)
    end

    Library.AddToTheme = function(self, Item, Properties)
        local ok, inst = pcall(function() return Item.Instance end)
        Item = (ok and inst) or Item

        local ThemeData = {
            Item = Item,
            Properties = Properties,
        }

        for Property, Value in ThemeData.Properties do
            if type(Value) == "string" then
                pcall(function()
                    Item[Property] = self.Theme[Value]
                end)
            else
                pcall(function()
                    Item[Property] = Value()
                end)
            end
        end

        TableInsert(self.ThemeItems, ThemeData)
        self.ThemeMap[Item] = ThemeData
    end

	Library.ToRich = function(self, Text, Color)
		return `<font color="rgb({MathFloor(Color.R * 255)}, {MathFloor(Color.G * 255)}, {MathFloor(Color.B * 255)})">{Text}</font>`
	end

    Library.ConfigManager = {
        Elements = {},
        List = {},
        Files = {},
        Autoload = nil
    }

    Library.NormalizeConfigName = function(self, Name, KeepExtension)
        if not Name or Name == "" then
            return nil
        end

        local Cleaned = tostring(Name):match("^%s*(.-)%s*$")
        Cleaned = Cleaned:gsub("\\", "/"):match("[^/]+$") or Cleaned
        if Cleaned == "" or Cleaned == "autoload.txt" then
            return nil
        end

        local HasJson = Cleaned:sub(-5):lower() == ".json"
        if HasJson then
            return KeepExtension and Cleaned or Cleaned:sub(1, -6)
        end

        return KeepExtension and (Cleaned .. ".json") or Cleaned
    end

    Library.ResolveConfigPath = function(self, Name)
        local DisplayName = Library:NormalizeConfigName(Name, false)
        if not DisplayName then
            return nil, nil, nil
        end

        local StoredPath = self.ConfigManager.Files[DisplayName]
        if type(StoredPath) == "string" and StoredPath ~= "" then
            local StoredFileName = StoredPath:match("[^/\\]+$")
            if StoredFileName then
                return DisplayName, StoredFileName, StoredPath
            end
        end

        local FileName = Library:NormalizeConfigName(Name, true)
        return DisplayName, FileName, self.Folders.Configs .. "/" .. FileName
    end

    Library.GetAutoloadConfigName = function(self)
        local Path = self.Folders.Configs .. "/autoload.txt"
        if not isfile(Path) then
            return nil
        end

        return Library:NormalizeConfigName(readfile(Path), false)
    end

    Library.SetAutoloadConfigName = function(self, Name)
        local Path = self.Folders.Configs .. "/autoload.txt"
        local DisplayName, FileName = Library:ResolveConfigPath(Name)

        if FileName then
            writefile(Path, FileName)
        elseif isfile(Path) then
            delfile(Path)
        end

        self.ConfigManager.Autoload = DisplayName
        return DisplayName
    end

    Library.ListConfigs = function(self)
        local DisplayList = {}
        local Files = {}

        if isfolder(self.Folders.Configs) then
            for _, Path in ipairs(listfiles(self.Folders.Configs)) do
                local FileName = Path:match("[^/\\]+$")
                if FileName and FileName:sub(-5):lower() == ".json" then
                    local DisplayName = Library:NormalizeConfigName(FileName, false)
                    if DisplayName then
                        Files[DisplayName] = Path
                        TableInsert(DisplayList, DisplayName)
                    end
                end
            end
        end

        table.sort(DisplayList, function(a, b)
            return tostring(a):lower() < tostring(b):lower()
        end)

        self.ConfigManager.List = DisplayList
        self.ConfigManager.Files = Files
        self.ConfigManager.Autoload = self:GetAutoloadConfigName()

        return DisplayList, Files
    end

    Library.ReadConfigFile = function(self, Name)
        local DisplayName, _, Path = Library:ResolveConfigPath(Name)
        if not DisplayName or not Path or not isfile(Path) then
            return false, "Config file not found"
        end

        local Success, Result = pcall(readfile, Path)
        if not Success then
            warn(Result)
            return false, Result
        end

        return true, Result
    end

    Library.CreateConfigFile = function(self, Name)
        local DisplayName, _, Path = Library:ResolveConfigPath(Name)
        if not DisplayName or not Path then
            return false, "Invalid config name"
        end

        if isfile(Path) then
            return false, "Config already exists"
        end

        local Success, Result = pcall(writefile, Path, Library:GetConfig())
        if not Success then
            warn(Result)
            return false, Result
        end

        Library:RefreshConfigsList(nil, DisplayName)
        return true, DisplayName
    end

    Library.SaveConfigFile = function(self, Name)
        local DisplayName, _, Path = Library:ResolveConfigPath(Name)
        if not DisplayName or not Path then
            return false, "Invalid config name"
        end

        local Success, Result = pcall(writefile, Path, Library:GetConfig())
        if not Success then
            warn(Result)
            return false, Result
        end

        Library:RefreshConfigsList(nil, DisplayName)
        return true, DisplayName
    end

    Library.GetConfig = function(self)
        local Config = { } 
        local IgnoredFlags = {
            ConfigsList = true,
            ConfigsName = true,
            UI_AutoloadConfig = true
        }

        local Success, Result = Library:SafeCall(function()
            for Index, Value in Library.Flags do 
                if IgnoredFlags[Index] then
                    continue
                end

                if type(Value) == "table" and Value.Key then
                    Config[Index] = {Key = tostring(Value.Key), Mode = Value.Mode}
                elseif type(Value) == "table" and Value.Color then
                    Config[Index] = {Color = "#" .. Value.HexValue, Alpha = Value.Alpha}
                else
                    Config[Index] = Value
                end
            end
            Config["__ThemePreset"] = Library.ActiveThemePreset or "Default"
        end)

        return HttpService:JSONEncode(Config)
    end

    Library.LoadConfig = function(self, Config)
        if type(Config) ~= "string" or Config == "" then
            return false, "Invalid config payload"
        end

        local IgnoredFlags = {
            ConfigsList = true,
            ConfigsName = true,
            UI_AutoloadConfig = true
        }

        local RawConfig = Config
        local Trimmed = RawConfig:match("^%s*(.-)%s*$")

        if Trimmed ~= "" and Trimmed:sub(1, 1) ~= "{" and Trimmed:sub(1, 1) ~= "[" then
            local ReadSuccess, ReadResult = Library:ReadConfigFile(Trimmed)
            if not ReadSuccess then
                return false, ReadResult
            end

            RawConfig = ReadResult
        end

        local DecodeSuccess, Decoded = pcall(function()
            return HttpService:JSONDecode(RawConfig)
        end)

        if not DecodeSuccess then
            warn(Decoded)
            return false, Decoded
        end

        local Success, Result = pcall(function()
            for Index, Value in Decoded do
                if Index == "__ThemePreset" then
                    if type(Value) == "string" then
                        Library:ApplyThemePreset(Value)
                    end
                    continue
                end

                if IgnoredFlags[Index] then
                    continue
                end

                local SetFunction = Library.SetFlags[Index]

                if not SetFunction then
                    continue
                end

                if type(Value) == "table" and Value.Key then 
                    SetFunction(Value)
                elseif type(Value) == "table" and Value.Color then
                    local Color = Value.Color
                    if type(Color) == "string" and Color:sub(1, 1) == "#" then
                        Color = FromHex(Color)
                    end
                    SetFunction(Color, Value.Alpha)
                else
                    SetFunction(Value)
                end
            end
        end)

        if not Success then
            warn(Result)
            return false, Result
        end

        return true
    end

    Library.LoadAutoloadConfig = function(self)
        local ConfigName = Library:GetAutoloadConfigName()
        if not ConfigName then
            return
        end

        local Success, Err = Library:LoadConfig(ConfigName)
        if not Success then
            warn("Failed to load autoload config: " .. tostring(Err))
        end
    end

    Library.DeleteConfig = function(self, Config)
        local DisplayName, _, Path = Library:ResolveConfigPath(Config)
        if not DisplayName or not Path or not isfile(Path) then
            return false, "Config file not found"
        end

        local Success, Result = pcall(delfile, Path)
        if not Success then
            warn(Result)
            return false, Result
        end

        if self:GetAutoloadConfigName() == DisplayName then
            self:SetAutoloadConfigName(nil)
        end

        Library:RefreshConfigsList(nil)
        return true
    end

    Library.RefreshConfigsList = function(self, Element, SelectedValue)
        if Element then
            self.ConfigManager.Elements[Element] = true
        end

        local List = self:ListConfigs()

        for BoundElement in self.ConfigManager.Elements do
            if type(BoundElement) ~= "table" or type(BoundElement.Refresh) ~= "function" then
                self.ConfigManager.Elements[BoundElement] = nil
                continue
            end

            local CurrentSelection = SelectedValue
            if CurrentSelection == nil and type(BoundElement.Get) == "function" then
                CurrentSelection = BoundElement:Get()
            end
            CurrentSelection = Library:NormalizeConfigName(CurrentSelection, false)

            local RefreshSuccess = pcall(function()
                BoundElement:Refresh(List)
            end)

            if not RefreshSuccess then
                self.ConfigManager.Elements[BoundElement] = nil
                continue
            end

            if CurrentSelection and self.ConfigManager.Files[CurrentSelection] then
                pcall(function()
                    BoundElement:Set(CurrentSelection)
                end)
            else
                BoundElement.Value = BoundElement.Multi and {} or nil
                if BoundElement.Flag then
                    Library.Flags[BoundElement.Flag] = BoundElement.Value
                end
            end
        end

        return List
    end

    Library.ChangeItemTheme = function(self, Item, Properties)
        Item = Item.Instance or Item

        if not self.ThemeMap[Item] then 
            return
        end

        self.ThemeMap[Item].Properties = Properties
        self.ThemeMap[Item] = self.ThemeMap[Item]
    end

    Library.ChangeTheme = function(self, Theme, Color)
        self.Theme[Theme] = Color

        for _, Item in self.ThemeItems do
            for Property, Value in Item.Properties do
                if type(Value) == "string" and Value == Theme then
                    pcall(function()
                        Item.Item[Property] = Color
                    end)
                elseif type(Value) == "function" then
                    pcall(function()
                        Item.Item[Property] = Value()
                    end)
                end
            end
        end
    end

    Library.ApplyThemePreset = function(self, PresetName)
        local Key = PresetName == "Default" and "Preset" or PresetName
        local ThemeData = self.Themes[Key]
        if not ThemeData then return end
        self.ActiveThemePreset = PresetName
        local TInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        for ThemeKey, Color in ThemeData do
            self.Theme[ThemeKey] = Color
            for _, Item in self.ThemeItems do
                for Property, Value in Item.Properties do
                    if type(Value) == "string" and Value == ThemeKey then
                        pcall(function()
                            if Item.Item:IsA("Frame") or Item.Item:IsA("ScrollingFrame") or Item.Item:IsA("TextButton") or Item.Item:IsA("TextLabel") or Item.Item:IsA("ImageLabel") then
                                TweenService:Create(Item.Item, TInfo, { [Property] = Color }):Play()
                            else
                                Item.Item[Property] = Color
                            end
                        end)
                    elseif type(Value) == "function" then
                        pcall(function()
                            Item.Item[Property] = Value()
                        end)
                    end
                end
            end
        end
        for _, cb in ipairs(self.ThemeCallbacks) do
            pcall(cb, self.Theme, TInfo)
        end
    end

    Library.IsMouseOverFrame = function(self, Frame)
        Frame = Frame.Instance

        local MousePosition = Vector2New(Mouse.X, Mouse.Y)

        return MousePosition.X >= Frame.AbsolutePosition.X and MousePosition.X <= Frame.AbsolutePosition.X + Frame.AbsoluteSize.X 
        and MousePosition.Y >= Frame.AbsolutePosition.Y and MousePosition.Y <= Frame.AbsolutePosition.Y + Frame.AbsoluteSize.Y
    end

    Library.MakeResizable = function(self, UI, DragFrame)
        local StartPos
        local FrameSize
        local Dragging = false
        local Changed

        local function IsClickInput(Input)
            return (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch)
                and Input.UserInputState == Enum.UserInputState.Begin
        end

        local function IsHoverInput(Input)
            return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
                and Input.UserInputState == Enum.UserInputState.Change
        end

        Library:Connect(DragFrame.InputBegan, function(Input)
            if not IsClickInput(Input) then return end

            StartPos = Input.Position
            FrameSize = UI.Size
            Dragging = true

            Changed = Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                    if Changed then
                        Changed:Disconnect()
                        Changed = nil
                    end
                end
            end)
        end)

        Library:Connect(UserInputService.InputChanged, function(Input)
            if not UI.Visible then
                Dragging = false
                if Changed then
                    Changed:Disconnect()
                    Changed = nil
                end
                return
            end

            if Dragging and IsHoverInput(Input) then
                local Delta = Input.Position - StartPos
                local NewX = FrameSize.X.Offset + Delta.X
                local NewY = FrameSize.Y.Offset + Delta.Y
                
                -- Enforce MinSize
                NewX = math.max(NewX, Library.MinSize.X)
                NewY = math.max(NewY, Library.MinSize.Y)

                UI.Size = UDim2New(
                    FrameSize.X.Scale,
                    NewX,
                    FrameSize.Y.Scale,
                    NewY
                )
            end
        end)
    end

    Library.Lerp = function(self, Start, Finish, Time)
        return Start + (Finish - Start) * Time
    end

    Library.CompareVectors = function(self, PointA, PointB)
        return (PointA.X < PointB.X) or (PointA.Y < PointB.Y)
    end

    Library.IsClipped = function(self, Object, Column)
        local Parent = Column
        
        local BoundryTop = Parent.AbsolutePosition
        local BoundryBottom = BoundryTop + Parent.AbsoluteSize

        local Top = Object.AbsolutePosition
        local Bottom = Top + Object.AbsoluteSize 

        return Library:CompareVectors(Top, BoundryTop) or Library:CompareVectors(BoundryBottom, Bottom)
    end

    Library.GetCalculatedRayPosition = function(self, Position, Normal, Origin, Direction)
        local N = Normal
        local D = Direction
        local V = Origin - Position

        local Number = (N.x * V.x) + (N.y * V.y) + (N.z * V.z)
        local Den = (N.x * D.x) + (N.y * D.y) + (N.z * D.z)
        local A = -Number / Den

        return Origin + (A * Direction)
    end

    Library.UpdateText = function(self)
        for Index, Value in self.UnusedHolder.Instance:GetDescendants() do 
            if Value:IsA("TextLabel") or Value:IsA("TextButton") or Value:IsA("TextBox") then
                Value.FontFace = Library.Font
            end
        end

        for Index, Value in self.Holder.Instance:GetDescendants() do 
            if Value:IsA("TextLabel") or Value:IsA("TextButton") or Value:IsA("TextBox") then
                Value.FontFace = Library.Font
            end
        end
    end

    Library.MakeBlurred = function(self, Item, Window)
        Item = Item.Instance
        local BlurItem = Item

        local Part = Instances:Create("Part", {
            Material = Enum.Material.Glass,
            Transparency = 1,
            Reflectance = 1,
            CastShadow = false,
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            CollisionGroup = " ",
            Size = Vector3New(1, 1, 1) * 0.01,
            Color = FromRGB(0,0,0),
            Parent = Camera
        })
            
        local BlockMesh = Instances:Create("BlockMesh", {Parent = Part.Instance})

        local DepthOfField = Instances:Create("DepthOfFieldEffect", {
            Parent = Lighting,
            Enabled = true,
            FarIntensity = 0,
            FocusDistance = 0,
            InFocusRadius = 1000,
            NearIntensity = 1,
            Name = ""
        })

        Library:Connect(RunService.RenderStepped, function()
            if Window.IsOpen then
                if Item.Visible then
                    DepthOfField:Tween(nil, {NearIntensity = 1})

                    Part:Tween(nil, {Transparency = 0.97})
                    Part:Tween(nil, {Size = Vector3New(1, 1, 1) * 0.01})

                    local Corner0 = BlurItem.AbsolutePosition;
                    local Corner1 = Corner0 + BlurItem.AbsoluteSize;
                        
                    local Ray0 = Camera.ScreenPointToRay(Camera, Corner0.X, Corner0.Y, 1);
                    local Ray1 = Camera.ScreenPointToRay(Camera, Corner1.X, Corner1.Y, 1);

                    local Origin = Camera.CFrame.Position + Camera.CFrame.LookVector * (0.05 - Camera.NearPlaneZ);

                    local Normal = Camera.CFrame.LookVector;

                    local Position0 = Library:GetCalculatedRayPosition(Origin, Normal, Ray0.Origin, Ray0.Direction)
                    local Position1 = Library:GetCalculatedRayPosition(Origin, Normal, Ray1.Origin, Ray1.Direction)

                    Position0 = Camera.CFrame:PointToObjectSpace(Position0)
                    Position1 = Camera.CFrame:PointToObjectSpace(Position1)

                    local Size = Position1 - Position0
                    local Center = (Position0 + Position1) / 2

                    BlockMesh.Instance.Offset = Center
                    BlockMesh.Instance.Scale  = Size / 0.0101

                    Part.Instance.CFrame = Camera.CFrame
                else
                    DepthOfField:Tween(nil, {NearIntensity = 0})

                    --Part:Tween(nil, {Transparency = 1})
                    BlockMesh.Instance.Offset = Vector3New(0, 0, 0)
                    BlockMesh.Instance.Scale  = Vector3New(0, 0, 0)
                end
            else
                DepthOfField:Tween(nil, {NearIntensity = 0})

                --Part:Tween(nil, {Transparency = 1})
                BlockMesh.Instance.Offset = Vector3New(0, 0, 0)
                BlockMesh.Instance.Scale  = Vector3New(0, 0, 0)
            end
        end)
    end

    Library.EscapePattern = function(self, String)
        local ShouldEscape = false 

        if string.match(String, "[%(%)%.%%%+%-%*%?%[%]%^%$]") then
            ShouldEscape = true
        end

        if ShouldEscape then
            return StringGSub(String, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
        end

        return String
    end

    -- Tweening
    Tween = { } do
        Tween.__index = Tween

        Tween.Create = function(self, Item, Info, Goal, IsRawItem)
            if not Item then return end
            if not Library then return end  -- Library was unloaded; discard stale callbacks
            Item = IsRawItem and Item or Item.Instance
            Info = Info or TweenInfo.new(Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction)

            local NewTween = {
                Tween = TweenService:Create(Item, Info, Goal),
                Info = Info,
                Goal = Goal,
                Item = Item
            }

            NewTween.Tween:Play()

            setmetatable(NewTween, Tween)

            return NewTween
        end

        Tween.GetProperty = function(self, Item)
            Item = Item or self.Item 

            if Item:IsA("Frame") then
                return { "BackgroundTransparency" }
            elseif Item:IsA("TextLabel") or Item:IsA("TextButton") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("ImageLabel") or Item:IsA("ImageButton") then
                return { "BackgroundTransparency", "ImageTransparency" }
            elseif Item:IsA("ScrollingFrame") then
                return { "BackgroundTransparency", "ScrollBarImageTransparency" }
            elseif Item:IsA("TextBox") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("UIStroke") then 
                return { "Transparency" }
            end
        end

        Tween.FadeItem = function(self, Item, Property, Visibility, Speed)
            local Item = Item or self.Item 

            local Success, OldTransparency = pcall(function()
                return Item[Property]
            end)

            if not Success then
                return
            end

            pcall(function()
                Item[Property] = Visibility and 1 or OldTransparency
            end)

            local NewTween = Tween:Create(Item, TweenInfo.new(Speed or Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction), {
                [Property] = Visibility and OldTransparency or 1
            }, true)

            Library:Connect(NewTween.Tween.Completed, function()
                if not Visibility then 
                    task.wait()
                    pcall(function()
                        Item[Property] = OldTransparency
                    end)
                end
            end)

            return NewTween
        end

        Tween.Get = function(self)
            if not self.Tween then 
                return
            end

            return self.Tween, self.Info, self.Goal
        end

        Tween.Pause = function(self)
            if not self.Tween then 
                return
            end

            self.Tween:Pause()
        end

        Tween.Play = function(self)
            if not self.Tween then 
                return
            end

            self.Tween:Play()
        end

        Tween.Clean = function(self)
            if not self.Tween then 
                return
            end

            Tween:Pause()
            self = nil
        end
    end

    -- Instances
    Instances = { } do
        Instances.__index = Instances

        Instances.Create = function(self, Class, Properties)
            local NewItem = {
                Instance = InstanceNew(Class),
                Properties = Properties,
                Class = Class
            }

            setmetatable(NewItem, Instances)

            for Property, Value in NewItem.Properties do
                NewItem.Instance[Property] = Value
            end

            return NewItem
        end

        Instances.FadeItem = function(self, Visibility, Speed)
            local Item = self.Instance

            if Visibility == true then 
                Item.Visible = true
            end

            local Descendants = Item:GetDescendants()
            TableInsert(Descendants, Item)

            local NewTween

            for Index, Value in Descendants do 
                local TransparencyProperty = Tween:GetProperty(Value)

                if not TransparencyProperty then 
                    continue
                end

                if type(TransparencyProperty) == "table" then 
                    for _, Property in TransparencyProperty do 
                        NewTween = Tween:FadeItem(Value, Property, not Visibility, Speed)
                    end
                else
                    NewTween = Tween:FadeItem(Value, TransparencyProperty, not Visibility, Speed)
                end
            end
        end

        Instances.AddToTheme = function(self, Properties)
            if not self.Instance then 
                return
            end

            Library:AddToTheme(self, Properties)
        end

        Instances.ChangeItemTheme = function(self, Properties)
            if not self.Instance then 
                return
            end

            Library:ChangeItemTheme(self, Properties)
        end

        Instances.Connect = function(self, Event, Callback, Name)
            if not self.Instance then 
                return
            end

            if not self.Instance[Event] then 
                return
            end

            if IsMobile then
                if Event == "MouseButton1Down" then
                    Event = "TouchTap"
                elseif Event == "MouseButton2Down" or Event == "MouseButton2Click" then 
                    Event = "TouchLongPress"
                end
            end

            return Library:Connect(self.Instance[Event], Callback, Name)
        end

        Instances.Tween = function(self, Info, Goal)
            if not self.Instance then 
                return
            end

            return Tween:Create(self, Info, Goal)
        end

        Instances.Disconnect = function(self, Name)
            if not self.Instance then 
                return
            end

            return Library:Disconnect(Name)
        end

        Instances.Clean = function(self)
            if not self.Instance then 
                return
            end

            self.Instance:Destroy()
            self = nil
        end

        Instances.MakeDraggable = function(self)
            if not self.Instance then 
                return
            end
        
            local Gui = self.Instance
            local Dragging = false 
            local DragStart
            local StartPosition 
        
            local Set = function(Input)
                local DragDelta = Input.Position - DragStart
                local NewX = StartPosition.X.Offset + DragDelta.X
                local NewY = StartPosition.Y.Offset + DragDelta.Y

                local ScreenSize = Gui.Parent.AbsoluteSize
                local GuiSize = Gui.AbsoluteSize
        
                NewX = MathClamp(NewX, 0, ScreenSize.X - GuiSize.X)
                NewY = MathClamp(NewY, 0, ScreenSize.Y - GuiSize.Y)
        
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0, NewX, 0, NewY)})
            end
        
            local InputChanged
        
            self:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    DragStart = Input.Position
                    StartPosition = Gui.Position
        
                    if InputChanged then 
                        return
                    end
        
                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Dragging = false
                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end)
        
            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dragging then
                        Set(Input)
                    end
                end
            end)
        
            return Dragging
        end

        Instances.MakeResizeable = function(self, Minimum, Maximum, Window)
            if not self.Instance then 
                return
            end

            local Gui = self.Instance

            local Resizing = false 
            local CurrentSide = nil

            local StartMouse = nil 
            local StartPosition = nil 
            local StartSize = nil
            
            local EdgeThickness = 2

            local MakeEdge = function(Name, Position, Size)
                local Button = Instances:Create("TextButton", {
                    Name = "\0",
                    Size = Size,
                    Position = Position,
                    BackgroundColor3 = FromRGB(166, 147, 243),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Parent = Gui,
                    ZIndex = 99999,
                })  Button:AddToTheme({BackgroundColor3 = "Accent"})

                return Button
            end

            local Edges = {
                {Button = MakeEdge(
                    "Left", 
                    UDim2New(0, 0, 0, 0), 
                    UDim2New(0, EdgeThickness, 1, 0)), 
                    Side = "L"
                },

                {Button = MakeEdge(
                    "Right", 
                    UDim2New(1, -EdgeThickness, 0, 0), 
                    UDim2New(0, EdgeThickness, 1, 0)), 
                    Side = "R"
                },

                {Button = MakeEdge(
                    "Top", UDim2New(0, 0, 0, 0), 
                    UDim2New(1, 0, 0, EdgeThickness)), 
                    Side = "T"
                },

                {Button = MakeEdge(
                    "Bottom", 
                    UDim2New(0, 0, 1, -EdgeThickness), 
                    UDim2New(1, 0, 0, EdgeThickness)), 
                    Side = "B"
                },
            }

            local BeginResizing = function(Side)
                Resizing = true 
                CurrentSide = Side 

                StartMouse = UserInputService:GetMouseLocation()

                -- store offsets, not absolute screen pos
                StartPosition = Vector2New(Gui.Position.X.Offset, Gui.Position.Y.Offset)
                StartSize = Vector2New(Gui.Size.X.Offset, Gui.Size.Y.Offset)
                
                for Index, Value in Edges do 
                    Value.Button:Tween(nil, {BackgroundTransparency = (Value.Side == Side) and 0 or 1})
                end
            end

            local EndResizing = function()
                Resizing = false 
                CurrentSide = nil

                for Index, Value in Edges do 
                    Value.Button.Instance.BackgroundTransparency = 1
                end
            end

            for Index, Value in Edges do 
                Value.Button:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        BeginResizing(Value.Side)
                    end
                end)
            end

            Library:Connect(UserInputService.InputEnded, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if Resizing then
                        EndResizing()
                    end
                end
            end)

            Library:Connect(RunService.RenderStepped, function()
                if not Resizing or not CurrentSide then 
                    return 
                end

                local MouseLocation = UserInputService:GetMouseLocation()
                local dx = MouseLocation.X - StartMouse.X
                local dy = MouseLocation.Y - StartMouse.Y
            
                local x, y = StartPosition.X, StartPosition.Y
                local w, h = StartSize.X, StartSize.Y

                if CurrentSide == "L" then
                    x = StartPosition.X + dx
                    w = StartSize.X - dx

                    if Window then
                        Window.Left.Y = h
                    end
                elseif CurrentSide == "R" then
                    w = StartSize.X + dx

                    if Window then
                        Window.Right.Y = h
                    end
                elseif CurrentSide == "T" then
                    y = StartPosition.Y + dy
                    h = StartSize.Y - dy

                    if Window then
                        Window.Top.X = w
                    end
                elseif CurrentSide == "B" then
                    h = StartSize.Y + dy

                    if Window then
                        Window.Bottom.X = w
                    end
                end
            
                if w < Minimum.X then
                    if CurrentSide == "L" then
                        x = x - (Minimum.X - w)
                    end
                    w = Minimum.X
                end
                if h < Minimum.Y then
                    if CurrentSide == "T" then
                        y = y - (Minimum.Y - h)
                    end
                    h = Minimum.Y
                end
            
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2FromOffset(x, y)})
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2FromOffset(w, h)})
            end)
        end

        Instances.OnHover = function(self, Function)
            if not self.Instance then 
                return
            end
            
            return Library:Connect(self.Instance.MouseEnter, Function)
        end

        Instances.OnHoverLeave = function(self, Function)
            if not self.Instance then 
                return
            end
            
            return Library:Connect(self.Instance.MouseLeave, Function)
        end
    end

    -- Custom font
    local CustomFont = { } do
        function CustomFont:New(Name, Weight, Style, Data)
            if not isfile(Data.Id) then 
                writefile(Data.Id, game:HttpGet(Data.Url))
            end

            local Data = {
                name = Name,
                faces = {
                    {
                        name = Name,
                        weight = Weight,
                        style = Style,
                        assetId = getcustomasset(Data.Id)
                    }
                }
            }

            writefile(`{Library.Folders.Assets}/{Name}.font`, HttpService:JSONEncode(Data))
            return getcustomasset(`{Library.Folders.Assets}/{Name}.font`)
        end

        local SemiBold = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)

        local Regular = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

        local Light = Font.new("rbxassetid://12187365364", Enum.FontWeight.Light, Enum.FontStyle.Normal)

        Library.Fonts = {
            ["SemiBold"] = SemiBold,
            ["Regular"] = Regular,
            ["Light"] = Light
        }

        Library.Font = SemiBold
    end

    Library.Holder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 2,
        ResetOnSpawn = false
    })

    Library.UnusedHolder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Enabled = false,
        ResetOnSpawn = false
    })

    Library.NotifHolder  = Instances:Create("Frame", {
        Parent = Library.Holder.Instance,
        Name = "\0",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2New(1, 1),
        Position = UDim2New(1, -16, 1, -16),
        Size = UDim2New(0, 480, 1, -32),
        BorderSizePixel = 0,
        BackgroundColor3 = FromRGB(255, 255, 255),
        ClipsDescendants = false,
    })

    Instances:Create("UIListLayout", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        Padding = UDimNew(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        FillDirection = Enum.FillDirection.Vertical,
    })

    -- Tooltip UI
    local TooltipLabel = Instances:Create("TextLabel", {
        BackgroundColor3 = FromRGB(12, 12, 14),
        BorderSizePixel = 0,
        TextSize = 14,
        TextWrapped = true,
        Visible = false,
        ZIndex = 200,
        Parent = Library.Holder.Instance,
        FontFace = Library.Font,
        TextColor3 = FromRGB(235, 235, 235),
        AutomaticSize = Enum.AutomaticSize.XY
    })
    TooltipLabel:AddToTheme({BackgroundColor3 = "Background", TextColor3 = "Text"})

    Instances:Create("UICorner", {
        CornerRadius = UDimNew(0, 6),
        Parent = TooltipLabel.Instance,
    })

    Instances:Create("UIStroke", {
        Color = FromRGB(25, 25, 28),
        Thickness = 1,
        Parent = TooltipLabel.Instance,
    }):AddToTheme({Color = "Outline"})

    Instances:Create("UIPadding", {
        PaddingBottom = UDimNew(0, 4),
        PaddingLeft = UDimNew(0, 8),
        PaddingRight = UDimNew(0, 8),
        PaddingTop = UDimNew(0, 4),
        Parent = TooltipLabel.Instance,
    })

    local CurrentHoverInstance
    function Library:AddTooltip(InfoStr, HoverInstance)
        if typeof(InfoStr) ~= "string" or InfoStr == "" then return end

        local function DoHover()
            if CurrentHoverInstance == HoverInstance then
                return
            end

            CurrentHoverInstance = HoverInstance
            TooltipLabel.Instance.Text = InfoStr
            TooltipLabel.Instance.Visible = true

            Library:Thread(function()
                while CurrentHoverInstance == HoverInstance and TooltipLabel.Instance.Visible do
                    local MousePos = UserInputService:GetMouseLocation()
                    local ScreenSize = Camera.ViewportSize
                    local TooltipSize = TooltipLabel.Instance.AbsoluteSize

                    local PosX = MousePos.X + 15
                    local PosY = MousePos.Y + 15

                    if PosX + TooltipSize.X > ScreenSize.X - 10 then
                        PosX = MousePos.X - TooltipSize.X - 15
                    end

                    if PosY + TooltipSize.Y > ScreenSize.Y - 10 then
                        PosY = MousePos.Y - TooltipSize.Y - 15
                    end

                    TooltipLabel.Instance.Position = UDim2FromOffset(PosX, PosY)
                    RunService.RenderStepped:Wait()
                end
            end)
        end

        Library:Connect(HoverInstance.MouseEnter, DoHover)
        Library:Connect(HoverInstance.MouseLeave, function()
            if CurrentHoverInstance == HoverInstance then
                TooltipLabel.Instance.Visible = false
                CurrentHoverInstance = nil
            end
        end)
    end

    do 
        Library.CreateColorpicker = function(self, Data)
            local Colorpicker = {
                Flag = Data.Flag,

                Hue = 0,
                Saturation = 0,
                Value = 0,

                Alpha = 0,

                Color = FromRGB(0, 0, 0),
                HexValue = "#000000",

                SavedColors = { },

                IsOpen = false 
            }

            local Items = { } do
                Items["ColorpickerButton"] = Instances:Create("TextButton", {
                    Parent = Data.Parent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(0, 100, 0, 20),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                if not Data.Parent2.Instance:FindFirstChild("nig") then
                    Items["PaletteIcon"] = Instances:Create("ImageLabel", {
                        Parent = Data.Parent2.Instance,
                        ImageColor3 = FromRGB(141, 141, 150),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 16, 0, 16),
                        AnchorPoint = Vector2New(0.5, 1),
                        Image = "rbxassetid://92464809279921",
                        Name = "nig",
                        BackgroundTransparency = 1,
                        Position = UDim2New(1, -16, 1, -6),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })                

                    Items["PaletteIcon"]:OnHover(function()
                        Items["PaletteIcon"]:Tween(nil, {ImageColor3 = Library.Theme.Accent})
                    end)
                    
                    Items["PaletteIcon"]:OnHoverLeave(function()
                        Items["PaletteIcon"]:Tween(nil, {ImageColor3 = FromRGB(141, 141, 150)})
                    end)
                end
                
                Items["Color"] = Instances:Create("Frame", {
                    Parent = Items["ColorpickerButton"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 15, 0, 15),
                    Position = UDim2New(0, 0, 0, 2),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Color"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["ColorpickerButton"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "#7842ff",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 25, 0, 2),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["ColorpickerWindow"] = Instances:Create("TextButton", {
                    Parent = Library.UnusedHolder.Instance,
                    AutoButtonColor = false,
                    Text = "",
                    Name = "\0",
                    Visible = false,
                    Position = UDim2New(0.01075268816202879, 0, 0.0336427167057991, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 235, 0, 270),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 25)
                })  Items["ColorpickerWindow"]:AddToTheme({BackgroundColor3 = "Background"})
                
                Instances:Create("UICorner", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })
                
                Items["Palette"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    Position = UDim2New(0, 15, 0, 10),
                    Size = UDim2New(1, -31, 1, -159),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })
                
                Items["Saturation"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 1, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Saturation"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(1, 0)}
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Saturation"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Value"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 1, 1, 1),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(0, 0, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Value"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(1, 0)}
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Value"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["PaletteDragger"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 15, 0, 15),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 10, 0, 10),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["PaletteDragger"].Instance,
                    Name = "\0",
                    Color = FromRGB(255, 255, 255),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["PaletteDragger"].Instance,
                    Name = "\0"
                })
                
                Items["Hue"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 15, 1, -131),
                    Size = UDim2New(1, -31, 0, 6),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Items["HueInline"] = Instances:Create("TextButton", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["HueInline"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["HueInline"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 0, 0)), RGBSequenceKeypoint(0.17, FromRGB(255, 255, 0)), RGBSequenceKeypoint(0.33, FromRGB(0, 255, 0)), RGBSequenceKeypoint(0.5, FromRGB(0, 255, 255)), RGBSequenceKeypoint(0.67, FromRGB(0, 0, 255)), RGBSequenceKeypoint(0.83, FromRGB(255, 0, 255)), RGBSequenceKeypoint(1, FromRGB(255, 0, 0))}
                })
                
                Items["HueDragger"] = Instances:Create("Frame", {
                    Parent = Items["HueInline"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 15, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 12, 0, 12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["HueDragger"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Items["Alpha"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 15, 1, -107),
                    Size = UDim2New(1, -31, 0, 6),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(0, 0, 0)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                })
                
                Items["AlphaDragger"] = Instances:Create("Frame", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 15, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 12, 0, 12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["AlphaDragger"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Items["SavedColors"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2New(0, 1),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0),
                    ScrollBarImageColor3 = FromRGB(124, 163, 255),
                    MidImage = "rbxassetid://86870199131153",
                    BorderColor3 = FromRGB(0, 0, 0),
                    ScrollBarThickness = 0,
                    Size = UDim2New(1, -20, 0, 69),
                    Selectable = false,
                    TopImage = "rbxassetid://86870199131153",
                    Position = UDim2New(0, 10, 1, -30),
                    BottomImage = "rbxassetid://86870199131153",
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                }) 
                
                Instances:Create("UIGridLayout", {
                    Parent = Items["SavedColors"].Instance,
                    Name = "\0",
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    CellPadding = UDim2New(0, 10, 0, 10),
                    CellSize = UDim2New(0, 25, 0, 25)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["SavedColors"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 5),
                    PaddingTop = UDimNew(0, 5),
                    PaddingRight = UDimNew(0, -125),
                    PaddingBottom = UDimNew(0, 5)
                })

                Items["HEXInput"] = Instances:Create("TextBox", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ClearTextOnFocus = false,
                    Text = "#7ca3ff",
                    AnchorPoint = Vector2New(1, 1),
                    Size = UDim2New(0, 140, 0, 20),
                    TextTransparency = 0.5,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    Position = UDim2New(1, -8, 1, -8),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(30, 29, 31)
                })  Items["HEXInput"]:AddToTheme({BackgroundColor3 = "Outline"})

                Instances:Create("UIPadding", {
                    Parent = Items["HEXInput"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 5),
                })
                
                Items["HexLabel"] = Instances:Create("TextLabel", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "Custom:",
                    TextTransparency = 0.5,
                    AnchorPoint = Vector2New(0, 1),
                    Size = UDim2New(0, 40, 0, 20),
                    Position = UDim2New(0, 10, 1, -8),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(30, 29, 31)
                })  Items["HexLabel"]:AddToTheme({TextColor3 = "Text"})
                
                Instances:Create("UICorner", {
                    Parent = Items["HEXInput"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })                
            end

            function Colorpicker:Get()
                return Colorpicker.Color, Colorpicker.Alpha
            end

            function Colorpicker:Update(IsFromAlpha)
                local Hue, Saturation, Value = Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value
                Colorpicker.Color = FromHSV(Hue, Saturation, Value)
                Colorpicker.HexValue = Colorpicker.Color:ToHex()

                Library.Flags[Colorpicker.Flag] = {
                    Alpha = Colorpicker.Alpha,
                    Color = Colorpicker.Color,
                    HexValue = Colorpicker.HexValue,
                    Transparency = 1 - Colorpicker.Alpha
                }

                Items["Color"]:Tween(nil, {BackgroundColor3 = Colorpicker.Color})
                Items["Palette"]:Tween(nil, {BackgroundColor3 = FromHSV(Hue, 1, 1)})
                Items["Text"].Instance.Text = ("#"..Colorpicker.HexValue):upper()
                Items["HEXInput"].Instance.Text = "#"..Colorpicker.HexValue

                if not IsFromAlpha then 
                    Items["Alpha"]:Tween(nil, {BackgroundColor3 = Colorpicker.Color})
                end

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Colorpicker.Color, Colorpicker.Alpha)
                end
            end

            local SlidingPalette = false
            local PaletteChanged
            
            function Colorpicker:SlidePalette(Input)
                if not Input or not SlidingPalette then
                    return
                end

                local ValueX = MathClamp(1 - (Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 1)
                local ValueY = MathClamp(1 - (Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 1)

                Colorpicker.Saturation = ValueX
                Colorpicker.Value = ValueY

                local SlideX = MathClamp((Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 0.955)
                local SlideY = MathClamp((Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 0.955)

                Items["PaletteDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, SlideY, 0)})
                Colorpicker:Update()
            end
            
            local SlidingHue = false
            local HueChanged

            function Colorpicker:SlideHue(Input)
                if not Input or not SlidingHue then
                    return
                end
                
                local ValueX = MathClamp((Input.Position.X - Items["Hue"].Instance.AbsolutePosition.X) / Items["Hue"].Instance.AbsoluteSize.X, 0, 1)

                Colorpicker.Hue = ValueX

                local SlideX = MathClamp((Input.Position.X - Items["Hue"].Instance.AbsolutePosition.X) / Items["Hue"].Instance.AbsoluteSize.X, 0, 0.955)

                Items["HueDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, 0.5, 0)})
                Colorpicker:Update()
            end

            local SlidingAlpha = false 
            local AlphaChanged

            function Colorpicker:SlideAlpha(Input)
                if not Input or not SlidingAlpha then
                    return
                end

                local ValueX = MathClamp((Input.Position.X - Items["Alpha"].Instance.AbsolutePosition.X) / Items["Alpha"].Instance.AbsoluteSize.X, 0, 1)

                Colorpicker.Alpha = ValueX

                local SlideX = MathClamp((Input.Position.X - Items["Alpha"].Instance.AbsolutePosition.X) / Items["Alpha"].Instance.AbsoluteSize.X, 0, 0.955)

                Items["AlphaDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, 0.5, 0)})
                Colorpicker:Update(true)
            end

            local Debounce = false
            local RenderStepped  

            function Colorpicker:SetOpen(Bool)
                if Debounce then 
                    return
                end

                Colorpicker.IsOpen = Bool

                Debounce = true 

                if Colorpicker.IsOpen then 
                    Items["ColorpickerWindow"].Instance.Visible = true
                    Items["ColorpickerWindow"].Instance.Parent = Library.Holder.Instance
                    
                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["ColorpickerWindow"].Instance.Position = UDim2New(
                            0, 
                            Items["ColorpickerButton"].Instance.AbsolutePosition.X, 
                            0, 
                            Items["ColorpickerButton"].Instance.AbsolutePosition.Y + Items["ColorpickerButton"].Instance.AbsoluteSize.Y + 5
                        )
                    end)

                    if Data.Section.IsSettings ~= true then
                        --print("sus")
                            for Index, Value in Library.OpenFrames do 
                                if Value ~= Colorpicker and type(Value) == "table" and Value.SetOpen then 
                                    Value:SetOpen(false)
                                end
                            end
                    end

                    Library.OpenFrames[Colorpicker] = Colorpicker 
                else
                    if not Data.Section.IsSettings then
                        --print("sus2")
                        if Library.OpenFrames[Colorpicker] then 
                            Library.OpenFrames[Colorpicker] = nil
                        end
                    end

                    if RenderStepped then 
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end
                end

                local Descendants = Items["ColorpickerWindow"].Instance:GetDescendants()
                TableInsert(Descendants, Items["ColorpickerWindow"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue 
                    end

                    if not Value.ClassName:find("UI") then 
                        Value.ZIndex = (Colorpicker.IsOpen and Data.Section.IsSettings and 9) or (Colorpicker.IsOpen and not Data.Section.IsSettings and 3) or 1
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end
                
                NewTween.Tween.Completed:Connect(function()
                    if not Library then return end
                    Debounce = false 
                    Items["ColorpickerWindow"].Instance.Visible = Colorpicker.IsOpen
                    task.wait(0.2)
                    if not Library then return end
                    Items["ColorpickerWindow"].Instance.Parent = not Colorpicker.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Colorpicker:Set(Color, Alpha)
                if type(Color) == "table" then
                    Color = FromRGB(Color[1], Color[2], Color[3])
                    Alpha = Color[4]
                elseif type(Color) == "string" then
                    Color = FromHex(Color)
                end 

                Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value = Color:ToHSV()
                Colorpicker.Alpha = Alpha or 0  

                local PaletteValueX = MathClamp(1 - Colorpicker.Saturation, 0, 0.955)
                local PaletteValueY = MathClamp(1 - Colorpicker.Value, 0, 0.955)

                local AlphaPositionX = MathClamp(Colorpicker.Alpha, 0, 0.955)
                    
                local HuePositionX = MathClamp(Colorpicker.Hue, 0, 0.955)

                Items["PaletteDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(PaletteValueX, 0, PaletteValueY, 0)})
                Items["HueDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(HuePositionX, 0, 0.5, 0)})
                Items["AlphaDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(AlphaPositionX, 0, 0.5, 0)})
                Colorpicker:Update()
            end

            Items["ColorpickerButton"]:Connect("MouseButton1Click", function()
                Colorpicker:SetOpen(not Colorpicker.IsOpen)
            end)

            Items["Palette"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    SlidingPalette = true 

                    Colorpicker:SlidePalette(Input)

                    if PaletteChanged then
                        return
                    end

                    PaletteChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingPalette = false

                            PaletteChanged:Disconnect()
                            PaletteChanged = nil
                        end
                    end)
                end
            end)

            Items["HueInline"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    SlidingHue = true 

                    Colorpicker:SlideHue(Input)

                    if HueChanged then
                        return
                    end

                    HueChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingHue = false

                            HueChanged:Disconnect()
                            HueChanged = nil
                        end
                    end)
                end
            end)

            Items["Alpha"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    SlidingAlpha = true 

                    Colorpicker:SlideAlpha(Input)

                    if AlphaChanged then
                        return
                    end

                    AlphaChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingAlpha = false

                            AlphaChanged:Disconnect()
                            AlphaChanged = nil
                        end
                    end)
                end
            end)

            function AddColor(Color)
                --if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    local SaveIndex = #Colorpicker.SavedColors + 1

                    local SavedColor = Instances:Create("TextButton", {
                        Parent = Items["SavedColors"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        Size = UDim2New(0, 200, 0, 50),
                        BorderSizePixel = 0,
                        TextSize = 14,
                        BackgroundTransparency = 1,
                        ZIndex = 4,
                        BackgroundColor3 = Color
                    })
                    
                    Instances:Create("UICorner", {
                        Parent = SavedColor.Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 6),
                    })                

                    local UIStroke = Instances:Create("UIStroke", {
                        Parent = SavedColor.Instance,
                        Name = "\0",
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Color = FromRGB(255, 255, 255),
                        Thickness = 1.5,
                        Transparency = 1
                    })

                    SavedColor:OnHover(function()
                        UIStroke:Tween(nil, {Transparency = 0})
                    end)

                    SavedColor:OnHoverLeave(function()
                        UIStroke:Tween(nil, {Transparency = 1})
                    end)
    
                    Colorpicker.SavedColors[SaveIndex] = {
                        Color = Color,
                        Alpha = Colorpicker.Alpha,
                    }
    
                    SavedColor:Connect("MouseButton1Click", function()
                        local NewColorData = Colorpicker.SavedColors[SaveIndex]
                        Colorpicker:Set(NewColorData.Color, NewColorData.Alpha)
                    end)

                    SavedColor:Tween(nil, {BackgroundTransparency = 0})
                --end
            end

            local Colors = {
                ["Orange"] = FromRGB(245, 114, 66),
                ["Pink"] = FromRGB(245, 66, 191),
                ["Purple"] = FromRGB(124, 54, 245),
                ["Pink 2"] = FromRGB(202, 110, 255),
                ["Pink 3"] = FromRGB(250, 142, 239),
                ["Yellow"] = FromRGB(214, 206, 92),
                ["Orange 2"] = FromRGB(255, 93, 48),
                ["Orange 3"] = FromRGB(255, 169, 56),   
                ["Green"] = FromRGB(0, 171, 0),
                ["Blue"] = FromRGB(0, 116, 224),
                ["Maroon"] = FromRGB(120, 0, 76),
                ["Whiteish Pink"] = FromRGB(255, 194, 245),         
                ["White"] = FromRGB(255, 255, 255),
                ["Red"] = FromRGB(255, 0, 0),
                ["Sky Blue"] = FromRGB(171, 209, 255),
            }

            AddColor(Colors["Orange"])
            AddColor(Colors["Pink"])
            AddColor(Colors["Purple"])
            AddColor(Colors["Pink 2"])
            AddColor(Colors["Pink 3"])
            AddColor(Colors["Yellow"])
            AddColor(Colors["Orange 2"])
            AddColor(Colors["Orange 3"])
            AddColor(Colors["Green"])
            AddColor(Colors["Blue"])
            AddColor(Colors["Maroon"])
            AddColor(Colors["Whiteish Pink"]) -- had to do it in order
            AddColor(Colors["White"])
            AddColor(Colors["Red"])
            AddColor(Colors["Sky Blue"])

            Items["HEXInput"]:Connect("FocusLost", function()
                Colorpicker:Set(tostring(Items["HEXInput"].Instance.Text), Colorpicker.Alpha)
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if SlidingPalette then 
                        Colorpicker:SlidePalette(Input)
                    end

                    if SlidingHue then
                        Colorpicker:SlideHue(Input)
                    end

                    if SlidingAlpha then
                        Colorpicker:SlideAlpha(Input)
                    end
                end
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if not Colorpicker.IsOpen then
                        return
                    end

                    if Library:IsMouseOverFrame(Items["ColorpickerWindow"]) or Library:IsMouseOverFrame(Items["PaletteIcon"]) and not Data.Section.IsSettings then
                        return
                    end

                    Colorpicker:SetOpen(false)
                end
            end)

            if Data.Default then
                Colorpicker:Set(Data.Default, Data.Alpha)
            end

            Library.SetFlags[Colorpicker.Flag] = function(Value, Alpha)
                Colorpicker:Set(Value, Alpha)
            end

            return Colorpicker, Items 
        end

        Library.KeybindList = function(self, Title)
            local KeybindList = { }
            Library.KeyList = KeybindList

            local Items = { } do 
                Items["KeybindsList"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 0.30000001192092896,
                    Position = UDim2New(0, 20, 0.5, 20),
                    Size = UDim2New(0, 100, 0, 30),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["KeybindsList"]:AddToTheme({BackgroundColor3 = "Section Background"})

                Items["KeybindsList"]:MakeDraggable()
                
                Instances:Create("UICorner", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0"
                })
                
                Items["Top"] = Instances:Create("Frame", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 12, 0, 40),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(31, 31, 36)
                })  Items["Top"]:AddToTheme({BackgroundColor3 = "Section Background 2"})
                
                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 21, 0, 20),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://81598136527047",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 15, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Icon"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(131, 131, 131)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(248, 248, 248),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Title,
                    AutomaticSize = Enum.AutomaticSize.X,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 45, 0.5, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Top"].Instance,
                    Name = "\0"
                })
                
                Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 10, 0, 5),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(31, 31, 36)
                }):AddToTheme({BackgroundColor3 = "Section Background 2"})
                
                Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(1, 1),
                    Position = UDim2New(1, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 10, 0, 5),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(31, 31, 36)
                }):AddToTheme({BackgroundColor3 = "Section Background 2"})
                
                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 40),
                    Size = UDim2New(1, 12, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 12)
                })                
            end

            function KeybindList:SetVisibility(Bool)
                Items["KeybindsList"].Instance.Visible = false
            end

            function KeybindList:Add(Name, Key)
                local NewKey = Instances:Create("TextButton", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                local NewKeyAccent = Instances:Create("Frame", {
                    Parent = NewKey.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient",{
                    Parent = NewKeyAccent.Instance,
                    Name = "\0",
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Instances:Create("UICorner", {
                    Parent = NewKeyAccent.Instance,
                    Name = "\0"
                })
                
                local NewKeyText = Instances:Create("TextLabel", {
                    Parent = NewKey.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.30000001192092896,
                    Text = Name .. " ["..Key.."]",
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  NewKeyText:AddToTheme({TextColor3 = "Text"})

                function NewKey:Set(Name, Key)
                    NewKeyText.Instance.Text = Name .. " ["..Key.."]"
                end

                function NewKey:SetStatus(Bool)
                    if Bool then 
                        NewKeyText:Tween(nil, {Position = UDim2New(0, 15, 0.5, 0), TextTransparency = 0})
                        NewKeyAccent:Tween(nil, {BackgroundTransparency = 0})
                    else
                        NewKeyText:Tween(nil, {Position = UDim2New(0, 0, 0.5, 0), TextTransparency = 0.3})
                        NewKeyAccent:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                return NewKey
            end

            return KeybindList
        end

        Library.Notification = function(self, Data)
            Data = Data or {}

            if not (Library.NotifHolder and Library.NotifHolder.Instance and Library.NotifHolder.Instance.Parent) then
                return
            end

            local Title       = tostring(Data.Title or "Notification")
            local Description = tostring(Data.Description or "")
            local SubText     = tostring(Data.SubText or "")
            local Icon        = Data.Icon
            local Duration    = tonumber(Data.Duration) or 5
            local AccentColor = Library.Theme["Accent"] or FromRGB(151, 69, 186)
            local Outline     = Library.Theme["Outline"] or FromRGB(58, 55, 72)
            local BgColor     = FromRGB(36, 34, 44)

            local CurrentCamera = Workspace.CurrentCamera
            local ViewportX = (CurrentCamera and CurrentCamera.ViewportSize.X) or 420
            local Width = math.min(360, math.max(300, ViewportX - 32))

            local PAD_H  = 18
            local PAD_V  = 16
            local CORNER = 18
            local PROG_H = 2

            local TitleFont = (Library.Fonts and Library.Fonts["SemiBold"]) or Library.Font
            local BodyFont  = (Library.Fonts and Library.Fonts["Regular"]) or Library.Font

            local TI_In  = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            local TI_Out = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

            local Wrapper = Instances:Create("Frame", {
                Parent = Library.NotifHolder.Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2New(0, Width, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = true,
                ZIndex = 10,
            })

            local Root = Instances:Create("Frame", {
                Parent = Wrapper.Instance,
                Name = "\0",
                BackgroundColor3 = BgColor,
                BorderSizePixel = 0,
                Position = UDim2New(0, Width + 24, 0, 0),
                Size = UDim2New(0, Width, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 0,
                ZIndex = 10,
            })

            Instances:Create("UICorner", {
                Parent = Root.Instance,
                CornerRadius = UDimNew(0, CORNER),
            })

            Instances:Create("UIStroke", {
                Parent = Root.Instance,
                Color = Outline,
                Thickness = 1,
                Transparency = 0,
            })

            local ContentRow = Instances:Create("Frame", {
                Parent = Root.Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2New(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 11,
            })

            Instances:Create("UIPadding", {
                Parent = ContentRow.Instance,
                Name = "\0",
                PaddingTop = UDimNew(0, PAD_V),
                PaddingBottom = UDimNew(0, PAD_V + PROG_H),
                PaddingLeft = UDimNew(0, PAD_H),
                PaddingRight = UDimNew(0, PAD_H),
            })

            Instances:Create("UIListLayout", {
                Parent = ContentRow.Instance,
                Padding = UDimNew(0, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            })

            local hasIcon = Icon ~= nil and Icon ~= ""
            if hasIcon then
                local iconData = self:GetCustomIcon(Icon)
                local IconWrap = Instances:Create("Frame", {
                    Parent = ContentRow.Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(0, 42, 0, 42),
                    LayoutOrder = 1,
                    ZIndex = 12,
                })

                local IconBg = Instances:Create("Frame", {
                    Parent = IconWrap.Instance,
                    Name = "\0",
                    BackgroundColor3 = AccentColor,
                    BackgroundTransparency = 0.82,
                    BorderSizePixel = 0,
                    Size = UDim2New(0, 38, 0, 38),
                    Position = UDim2New(0, 0, 0, 0),
                    ZIndex = 12,
                })

                Instances:Create("UICorner", {
                    Parent = IconBg.Instance,
                    CornerRadius = UDimNew(0, 12),
                })

                if iconData and iconData.Url then
                    Instances:Create("ImageLabel", {
                        Parent = IconBg.Instance,
                        Name = "\0",
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        Size = UDim2New(0, 18, 0, 18),
                        Image = iconData.Url,
                        ImageColor3 = AccentColor,
                        ImageRectOffset = iconData.ImageRectOffset or Vector2New(0, 0),
                        ImageRectSize = iconData.ImageRectSize or Vector2New(0, 0),
                        ZIndex = 13,
                    })
                end
            end

            local TextBlock = Instances:Create("Frame", {
                Parent = ContentRow.Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2New(1, hasIcon and -52 or -26, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = hasIcon and 2 or 1,
                ZIndex = 11,
            })

            Instances:Create("UIListLayout", {
                Parent = TextBlock.Instance,
                Padding = UDimNew(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            })

            Instances:Create("TextLabel", {
                Parent = TextBlock.Instance,
                Name = "\0",
                FontFace = TitleFont,
                Text = Title,
                TextColor3 = FromRGB(248, 246, 255),
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                RichText = false,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2New(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = 1,
                ZIndex = 12,
            })

            if Description ~= "" then
                Instances:Create("TextLabel", {
                    Parent = TextBlock.Instance,
                    Name = "\0",
                    FontFace = BodyFont,
                    Text = Description,
                    TextColor3 = FromRGB(195, 192, 212),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    LineHeight = 1.2,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = 2,
                    ZIndex = 12,
                })
            end

            if SubText ~= "" then
                Instances:Create("TextLabel", {
                    Parent = TextBlock.Instance,
                    Name = "\0",
                    FontFace = BodyFont,
                    Text = SubText,
                    TextColor3 = FromRGB(114, 110, 136),
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = 3,
                    ZIndex = 12,
                })
            end

            local CloseBtn = Instances:Create("TextButton", {
                Parent = Root.Instance,
                Name = "\0",
                Text = "×",
                FontFace = TitleFont,
                TextSize = 18,
                TextColor3 = FromRGB(110, 105, 132),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AnchorPoint = Vector2New(1, 0),
                Position = UDim2New(1, -12, 0, 12),
                Size = UDim2New(0, 20, 0, 20),
                AutoButtonColor = false,
                ZIndex = 14,
            })

            local ProgTrack = Instances:Create("Frame", {
                Parent = Root.Instance,
                Name = "\0",
                BackgroundColor3 = FromRGB(48, 45, 60),
                BorderSizePixel = 0,
                AnchorPoint = Vector2New(0, 1),
                Position = UDim2New(0, 0, 1, 0),
                Size = UDim2New(1, 0, 0, PROG_H),
                ClipsDescendants = true,
                ZIndex = 11,
            })

            Instances:Create("UICorner", {
                Parent = ProgTrack.Instance,
                CornerRadius = UDimNew(0, PROG_H),
            })

            local ProgFill = Instances:Create("Frame", {
                Parent = ProgTrack.Instance,
                Name = "\0",
                BackgroundColor3 = AccentColor,
                BorderSizePixel = 0,
                Size = UDim2New(1, 0, 1, 0),
                ZIndex = 12,
            })

            local dismissed = false
            local function Dismiss()
                if dismissed then
                    return
                end
                dismissed = true

                TweenService:Create(Root.Instance, TI_Out, {
                    Position = UDim2New(0, Width + 24, 0, 0),
                    BackgroundTransparency = 1,
                }):Play()

                for _, obj in ipairs(Root.Instance:GetDescendants()) do
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                        TweenService:Create(obj, TI_Out, {TextTransparency = 1}):Play()
                    elseif obj:IsA("ImageLabel") then
                        TweenService:Create(obj, TI_Out, {ImageTransparency = 1}):Play()
                    elseif obj:IsA("Frame") then
                        TweenService:Create(obj, TI_Out, {BackgroundTransparency = 1}):Play()
                    elseif obj:IsA("UIStroke") then
                        TweenService:Create(obj, TI_Out, {Transparency = 1}):Play()
                    end
                end

                task.delay(TI_Out.Time + 0.05, function()
                    if Wrapper and Wrapper.Instance and Wrapper.Instance.Parent then
                        Wrapper:Clean()
                    end
                end)
            end

            CloseBtn:Connect("MouseEnter", function()
                TweenService:Create(CloseBtn.Instance, TweenInfo.new(0.15), {TextColor3 = FromRGB(225, 222, 240)}):Play()
            end)
            CloseBtn:Connect("MouseLeave", function()
                TweenService:Create(CloseBtn.Instance, TweenInfo.new(0.15), {TextColor3 = FromRGB(110, 105, 132)}):Play()
            end)
            CloseBtn:Connect("MouseButton1Click", Dismiss)

            TweenService:Create(Root.Instance, TI_In, {Position = UDim2New(0, 0, 0, 0)}):Play()
            TweenService:Create(ProgFill.Instance,
                TweenInfo.new(Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                {Size = UDim2New(0, 0, 1, 0)}
            ):Play()

            task.delay(Duration, Dismiss)
        end

        Library.Window = function(self, Data)
            Data = Data or { }

            local Window = {
                Name = Data.Name or Data.name or "Window",
                SubName = Data.SubName or Data.subname or "Fine-tuning for sure wins",
                Logo = Data.Logo or Data.logo or "1l20959262762131",
                Compact = Data.Compact or false,
                SelectedTab = Data.SelectedTab or 1,
                
                Pages = { },
                Items = { },
                IsOpen = false,
                CurrentAlignment = "LeftTabs"
            }

            Window.ActivePage    = nil
            Window._tabLocked   = false

            function Window:SelectTab(Tab)
                local Target
                if type(Tab) == "number" then
                    Target = Window.Pages[Tab]
                elseif type(Tab) == "table" and Tab.Turn then
                    Target = Tab
                end
                if not Target then return end
                if Window.ActivePage == Target then return end
                if Window._tabLocked then return end

                Window._tabLocked = true

                local prev = Window.ActivePage
                Window.ActivePage = Target

                for _, P in ipairs(Window.Pages) do
                    if P ~= Target and P.Active then
                        P:_ForceOff()
                    end
                end
                Target:Turn(true)

                task.delay(0.55, function()
                    Window._tabLocked = false
                end)
            end

            local Items = { } do
                Items["MainFrame"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BackgroundTransparency = 0.12,
                    Position = UDim2New(0.5519999861717224, 0, 0.5, 0),
                    Size = UDim2New(0, 677, 0, 644),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["MainFrame"]:AddToTheme({BackgroundColor3 = "Background"})

                do
                    Instances:Create("UIScale", {
                        Parent = Items["MainFrame"].Instance,
                        Name = "\0",
                        Scale = IsMobile and 0.55 or 1.125
                    })
                end

                Items["MainFrame"]:MakeResizeable(Vector2New(Items["MainFrame"].Instance.AbsoluteSize.X, Items["MainFrame"].Instance.AbsoluteSize.Y), Vector2New(9999, 9999), OriginalSizes)
                Library:MakeBlurred(Items["MainFrame"], Window)
                
                Items["LeftTabs"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    Visible = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.15,
                    Size = UDim2New(0, 225, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29),
                    CanvasSize = UDim2New(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = FromRGB(0, 0, 0)
                })  Items["LeftTabs"]:AddToTheme({BackgroundColor3 = "Background", ScrollBarImageColor3 = "Accent"})

                Library:MakeBlurred(Items["LeftTabs"], Window)

                local Gui = Items["MainFrame"].Instance

                local Dragging = false 
                local DragStart
                local StartPosition 
    
                local Set = function(Input)
                    local DragDelta = Input.Position - DragStart
                    Items["MainFrame"]:Tween(TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(StartPosition.X.Scale, StartPosition.X.Offset + DragDelta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + DragDelta.Y)})
                end
    
                Items["MainFrame"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
    
                        DragStart = Input.Position
                        StartPosition = Gui.Position
    
                        Input.Changed:Connect(function()
                            if Input.UserInputState == Enum.UserInputState.End then
                                Dragging = false
                            end
                        end)
                    end
                end)

                Items["LeftTabs"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
    
                        DragStart = Input.Position
                        StartPosition = Gui.Position
    
                        Input.Changed:Connect(function()
                            if Input.UserInputState == Enum.UserInputState.End then
                                Dragging = false
                            end
                        end)
                    end
                end)
    
                Library:Connect(UserInputService.InputChanged, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                        if Dragging then
                            Set(Input)
                        end
                    end
                end)

                Items["FloatingButton"] = Instances:Create("TextButton", {
                    Parent = Library.Holder.Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    Position = UDim2New(0.5, 0, 0, 20),
                    AnchorPoint = Vector2New(0.5, 0),
                    Visible = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 50, 0, 50),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0.5,
                    ZIndex = 127,
                    BackgroundColor3 = Library.Theme.Background
                })  Items["FloatingButton"]:AddToTheme({BackgroundColor3 = "Background"})

                local Gui = Items["FloatingButton"].Instance

                local Dragging = false
                local DragStart
                local StartPosition

                local Set = function(Input)
                    local DragDelta = Input.Position - DragStart
                    Items["FloatingButton"]:Tween(TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(StartPosition.X.Scale, StartPosition.X.Offset + DragDelta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + DragDelta.Y)})
                end

                Items["FloatingButton"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true

                        DragStart = Input.Position
                        StartPosition = Gui.Position

                        Input.Changed:Connect(function()
                            if Input.UserInputState == Enum.UserInputState.End then
                                Dragging = false
                            end
                        end)
                    end
                end)

                Library:Connect(UserInputService.InputChanged, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                        if Dragging then
                            Set(Input)
                        end
                    end
                end)

                local FloatingLogoIcon = Library:GetCustomIcon(Window.Logo)
                Items["FloatingLogo"] = Instances:Create("ImageLabel", {
                    Parent = Items["FloatingButton"].Instance,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Name = "\0",
                    Image = FloatingLogoIcon and FloatingLogoIcon.Url or "",
                    ImageRectOffset = FloatingLogoIcon and FloatingLogoIcon.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = FloatingLogoIcon and FloatingLogoIcon.ImageRectSize or Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 127,
                    Size = UDim2New(1, -25, 1, -25),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["FloatingButton"].Instance,
                    CornerRadius = UDimNew(1, 0)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["FloatingLogo"].Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["PagePlaceholder"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    Visible = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["LeftTabs"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 12),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["LeftTabs"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 15),
                    PaddingBottom = UDimNew(0, 15),
                    PaddingRight = UDimNew(0, 12),
                    PaddingLeft = UDimNew(0, 12)
                })

                local LogoIcon = Library:GetCustomIcon(Window.Logo)
                Items["Logo"] = Instances:Create("ImageLabel", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 35, 0, 35),
                    Image = LogoIcon and LogoIcon.Url or "",
                    ImageRectOffset = LogoIcon and LogoIcon.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = LogoIcon and LogoIcon.ImageRectSize or Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 12),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                }) 

                Instances:Create("UIGradient", {
                    Parent = Items["Logo"].Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Window.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 52, 0, 13),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 16,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
                
                Items["SubTitle"] = Instances:Create("TextLabel", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.4000000059604645,
                    Text = Window.SubName,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 52, 0, 30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["SubTitle"]:AddToTheme({TextColor3 = "Text"})

                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.75,
                    Position = UDim2New(0, 0, 0, 55),
                    Size = UDim2New(1, 0, 1, -55),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["Content"]:AddToTheme({BackgroundColor3 = "Background"})

                Items["CloseButton"] = Instances:Create("TextButton", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0.20000000298023224,
                    Position = UDim2New(1, -14, 0, 11),
                    Size = UDim2New(0, 32, 0, 32),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["CloseButton"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["CloseButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })
                
                Items["CloseIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["CloseButton"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(240, 240, 240),
                    ImageTransparency = 0.30000001192092896,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 11, 0, 11),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://130510492706892",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["CloseIcon"]:AddToTheme({ImageColor3 = "Text"})        
                
                Items["CloseButton"]:Connect("MouseButton1Click", function()
                    Library:Unload()
                end)

                Items["CloseIconAccent"] = Instances:Create("Frame", {
                    Parent = Items["CloseButton"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BorderSizePixel = 0,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 0, 0, 0),
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["CloseIconAccent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                --// Resize Button
                Items["ResizeButton"] = Instances:Create("TextButton", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "ResizeButton",
                    Text = "",
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 20, 0, 20),
                    Position = UDim2New(1, 0, 1, 0),
                    AnchorPoint = Vector2New(1, 1),
                    ZIndex = 10,
                    AutoButtonColor = false
                })

                local ResizeIcon = Library:GetCustomIcon("move-diagonal-2")
                Items["ResizeImage"] = Instances:Create("ImageLabel", {
                    Parent = Items["ResizeButton"].Instance,
                    Image = ResizeIcon and ResizeIcon.Url or "",
                    ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    ImageTransparency = 0.5,
                    ZIndex = 10,
                    ImageColor3 = FromRGB(255, 255, 255)
                })
                Items["ResizeImage"]:AddToTheme({ImageColor3 = "Text"})

                Library:MakeResizable(Items["MainFrame"].Instance, Items["ResizeButton"].Instance)

                Instances:Create("UICorner", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })      

                Instances:Create("UICorner", {
                    Parent = Items["LeftTabs"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })      
                
                do
                    Items["LeftBottomPixels"] = Instances:Create("Frame", {
                        Parent = Items["MainFrame"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(1, 1),
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 1, 1, 0),
                        Size = UDim2New(0, 5, 0, 5),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                    
                    Items["___1"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 2, 1, 0),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___1"]:AddToTheme({BackgroundColor3 = "Background"})
                    
                    Items["___2"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 4, 1, 0),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___2"]:AddToTheme({BackgroundColor3 = "Background"})
                    
                    Items["___3"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 3, 1, 0),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___3"]:AddToTheme({BackgroundColor3 = "Background"})
                    
                    Items["___4"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 3, 1, -1),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___4"]:AddToTheme({BackgroundColor3 = "Background"})
                    
                    Items["___5"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 4, 1, -1),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___5"]:AddToTheme({BackgroundColor3 = "Background"})
                    
                    Items["___6"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 5, 1, 0),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___6"]:AddToTheme({BackgroundColor3 = "Background"})
                    
                    
                    
                    Items["LeftTopPixels"] = Instances:Create("Frame", {
                        Parent = Items["MainFrame"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(1, 0),
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 1, 0, 0),
                        Size = UDim2New(0, 5, 0, 5),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                    
                    Items["___7"] = Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 2, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BackgroundTransparency = 0.12,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___7"]:AddToTheme({BackgroundColor3 = "Background"})   
                    
                    Items["___8"]= Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        BackgroundTransparency = 0.12,
                        Position = UDim2New(0, 3, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___8"]:AddToTheme({BackgroundColor3 = "Background"})   
                    
                    Items["___9"]= Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 4, 0, 0),
                        BackgroundTransparency = 0.12,
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___9"]:AddToTheme({BackgroundColor3 = "Background"})   
                    
                    Items["___10"] = Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 5, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        BackgroundTransparency = 0.12,
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___10"]:AddToTheme({BackgroundColor3 = "Background"})   
                    
                    Items["___11"]=Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 3, 0, 1),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BackgroundTransparency = 0.12,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___11"]:AddToTheme({BackgroundColor3 = "Background"})   
                    
                    Items["___12"] = Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 4, 0, 1),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BackgroundTransparency = 0.12,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___12"]:AddToTheme({BackgroundColor3 = "Background"})                                      
                end

                function Window:SetTransparency()
                    Items["MainFrame"].Instance.BackgroundTransparency = Library.Flags["BackgroundTransparency"] 
                    Items["LeftTabs"].Instance.BackgroundTransparency = Library.Flags["BackgroundTransparency"]  
                    Items["FloatingButton"].Instance.BackgroundTransparency = Library.Flags["BackgroundTransparency"]

                    for _, Value in Items do 
                        if _:find("___") then
                            Value.Instance.BackgroundTransparency = tonumber(Library.Flags["BackgroundTransparency"])
                        end
                    end
                end

                Instances:Create("UIGradient", {
                    Parent = Items["CloseIconAccent"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))},
                    Rotation = -115
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["SettingsButton"] = Instances:Create("TextButton", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0.20000000298023224,
                    Position = UDim2New(1, -56, 0, 11),
                    Size = UDim2New(0, 32, 0, 32),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["SettingsButton"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["SettingsButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })
                
                Items["SettingsIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["SettingsButton"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(240, 240, 240),
                    ImageTransparency = 0.30000001192092896,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 15, 0, 14),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://122669828593160",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["SettingsIcon"]:AddToTheme({ImageColor3 = "Text"})

                Items["SettingsIconAccent"] = Instances:Create("Frame", {
                    Parent = Items["SettingsButton"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BorderSizePixel = 0,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 0, 0, 0),
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["SettingsIconAccent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["SettingsIconAccent"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))},
                    Rotation = -115
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["SettingsButton"]:OnHover(function()
                    Items["SettingsIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(1, 0, 1, 0),
                        BackgroundTransparency = 0
                    })
                end)

                Items["SettingsButton"]:OnHoverLeave(function()
                    Items["SettingsIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(0, 0, 0, 0),
                        BackgroundTransparency = 1
                    })
                end)

                Items["CloseButton"]:OnHover(function()
                    Items["CloseIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(1, 0, 1, 0),
                        BackgroundTransparency = 0
                    })
                end)

                Items["CloseButton"]:OnHoverLeave(function()
                    Items["CloseIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(0, 0, 0, 0),
                        BackgroundTransparency = 1
                    })
                end)
                
                local Settings = {
                    IsOpen = false,
                    Name = ""..#Library.Sections,
                    Items = { },
                    IsSettings = true,
                    Elements = { }
                }

                local SettingsItems = { }
                do
                    SettingsItems["Settings"] = Instances:Create("Frame", {
                        Parent = Library.UnusedHolder.Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        Position = UDim2New(0.8949604630470276, 0, 0.2945185601711273, 0),
                        Size = UDim2New(0, 245, 0, 159),
                        ZIndex = 2,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = FromRGB(21, 21, 24)
                    }) SettingsItems["Settings"]:AddToTheme({BackgroundColor3 = "Section Background 2"})
                    
                    Instances:Create("UICorner", {
                        Parent = SettingsItems["Settings"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 6)
                    })
                    
                    SettingsItems["CloseButton"] = Instances:Create("TextButton", {
                        Parent = SettingsItems["Settings"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        AnchorPoint = Vector2New(0, 1),
                        BorderSizePixel = 0,
                        Position = UDim2New(0, 8, 1, -8),
                        Size = UDim2New(1, -16, 0, 32),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(27, 26, 29)
                    }) SettingsItems["CloseButton"]:AddToTheme({BackgroundColor3 = "Element"})
                    
                    Instances:Create("UICorner", {
                        Parent = SettingsItems["CloseButton"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })
                    
                    SettingsItems["Text"] = Instances:Create("TextLabel", {
                        Parent = SettingsItems["CloseButton"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(240, 240, 240),
                        TextTransparency = 0.30000001192092896,
                        Text = "Close",
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2New(0, 0, 0, 15),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                    
                    SettingsItems["Content"] = Instances:Create("ScrollingFrame", {
                        Parent = SettingsItems["Settings"].Instance,
                        Name = "\0",
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        Selectable = false,
                        Size = UDim2New(1, -8, 1, -46),
                        Position = UDim2New(0, 4, 0, 4),
                        ScrollBarThickness = 2,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        BackgroundTransparency = 1,
                        BorderColor3 = FromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        CanvasSize = UDim2New(0, 0, 0, 0)
                    })  SettingsItems["Content"]:AddToTheme({ScrollBarImageColor3 = "Accent"})
                    
                    Instances:Create("UIListLayout", {
                        Parent = SettingsItems["Content"].Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 4),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })                    
                    
                    Instances:Create("UIPadding", {
                        Parent = SettingsItems["Content"].Instance,
                        Name = "\0",
                        PaddingTop = UDimNew(0, 4),
                        PaddingBottom = UDimNew(0, 4),
                        PaddingRight = UDimNew(0, 4),
                        PaddingLeft = UDimNew(0, 4)
                    })

                    SettingsItems["Accent"] = Instances:Create("Frame", {
                        Parent = SettingsItems["CloseButton"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0)
                    })  --SettingsItems["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})
    
                    SettingsItems["Gradient"] = Instances:Create("UIGradient", {
                        Parent = SettingsItems["Accent"].Instance,
                        Name = "\0",
                        Enabled = true,
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                    })  SettingsItems["Gradient"]:AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                    end})

                    Instances:Create("UICorner", {
                        Parent = SettingsItems["Accent"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })
    
                    Instances:Create("UICorner", {
                        Parent = SettingsItems["CloseButton"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })

                    SettingsItems["CloseButton"]:OnHover(function()
                        SettingsItems["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 0})
                    end)
    
                    SettingsItems["CloseButton"]:OnHoverLeave(function()
                        SettingsItems["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1})
                    end)

                    local RenderStepped 
                    local Debounce = false
    
                    function Settings:SetOpen(Bool)
                        if Debounce then 
                            return
                        end
        
                        Settings.IsOpen = Bool
        
                        Debounce = true 
        
                        if Settings.IsOpen then 
                            for Index, Value in Settings.Elements do
                                Value:RefreshPosition(true)
                                task.wait(0.03)
                            end
    
                            SettingsItems["Settings"].Instance.Visible = true
                            SettingsItems["Settings"].Instance.Parent = Library.Holder.Instance
                            
                            RenderStepped = RunService.RenderStepped:Connect(function()
                                SettingsItems["Settings"].Instance.Position = UDim2New(0, Items["SettingsIcon"].Instance.AbsolutePosition.X, 0, Items["SettingsIcon"].Instance.AbsolutePosition.Y + Items["SettingsButton"].Instance.AbsoluteSize.Y + 108)
                                SettingsItems["Settings"].Instance.Size = UDim2New(0, 325, 0, 300)
                            end)
        
                            for Index, Value in Library.OpenFrames do 
                                if Value ~= Settings and type(Value) == "table" and Value.SetOpen then 
                                    Value:SetOpen(false)
                                end
                            end
        
                            Library.OpenFrames[Settings] = Settings 
                        else
                            for Index, Value in Settings.Elements do
                                Value:RefreshPosition(false)
                            end
    
                            if Library.OpenFrames[Settings] then 
                                Library.OpenFrames[Settings] = nil
                            end
        
                            if RenderStepped then 
                                RenderStepped:Disconnect()
                                RenderStepped = nil
                            end
                        end
        
                        local Descendants = SettingsItems["Settings"].Instance:GetDescendants()
                        TableInsert(Descendants, SettingsItems["Settings"].Instance)
        
                        local NewTween
        
                        for Index, Value in Descendants do 
                            local TransparencyProperty = Tween:GetProperty(Value)
        
                            if not TransparencyProperty then
                                continue 
                            end
        
                            if not Value.ClassName:find("UI") then 
                                Value.ZIndex = Settings.IsOpen and 7 or 1
                                SettingsItems["Text"].Instance.ZIndex = 8
                            end
        
                            if type(TransparencyProperty) == "table" then 
                                for _, Property in TransparencyProperty do 
                                    NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                                end
                            else
                                NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                            end
                        end
                        
                        NewTween.Tween.Completed:Connect(function()
                        if not Library then return end
                            Debounce = false 
                            SettingsItems["Settings"].Instance.Visible = Settings.IsOpen
                            task.wait(0.2)
                        if not Library then return end
                            SettingsItems["Settings"].Instance.Parent = not Settings.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                        end)
                    end
    
                    SettingsItems["CloseButton"]:Connect("MouseButton1Click", function()
                        Settings:SetOpen(false)
                    end)
    
                    Items["SettingsButton"]:Connect("InputBegan", function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
                            Settings:SetOpen(not Settings.IsOpen)
                        end
                    end)
    
                    Settings.Items = SettingsItems
                    setmetatable(Settings, Library.Sections)
                end

                Settings:Label("First gradient color"):Colorpicker({
                    Flag = "AccentColor",
                    Default = Library.Theme.Accent,
                    Callback = function(Color)
                        Library.Theme.Accent = Color
                        Library:ChangeTheme("Accent", Color)
                    end
                })

                Settings:Label("Second gradient color"):Colorpicker({
                    Flag = "AccentGradientColor",
                    Default = Library.Theme.AccentGradient,
                    Callback = function(Color)
                        Library.Theme.AccentGradient = Color
                        Library:ChangeTheme("AccentGradient", Color)
                    end
                })

                Settings:Dropdown({
                    Name = "Font weight",
                    Flag = "FontStyle",
                    Default = "SemiBold",
                    Items = {"Light", "Regular", "SemiBold"},
                    Callback = function(Value)
                        local FontData = Library.Fonts[Value]

                        if FontData then
                            Library.Font = FontData
                            Library:UpdateText()
                        end
                    end
                })

                Settings:Slider({
                    Name = "Background Transparency",
                    Default = 0.12,
                    Decimals = 0.01,
                    Max = 1,
                    Min = 0,
                    Suffix = "%",
                    Flag = "BackgroundTransparency",
                    Callback = function(Value)
                        Window:SetTransparency(Value)
                    end
                })

                Settings:Keybind({
                    Name = "Menu Keybind",
                    Flag = "MenuBind",
                    Default = Enum.KeyCode.Z,
                    Callback = function(Value)
                        Window:SetOpen(Value)
                    end
                })

                print("[LibEleven] Theme Dropdown Loaded")
                Settings:Dropdown({
                    Name = "UI Theme",
                    Flag = "UIThemePreset",
                    Icon = "palette",
                    Default = "Default",
                    Items = {"Default", "Dark", "Flame", "Plasma", "Forest", "Aqua"},
                    Callback = function(Value)
                        print("[LibEleven] Theme changed to:", Value)
                        Library:ApplyThemePreset(Value)
                    end
                })

                Window.Items = Items
            end
            
            local Debounce = false

            function Window:SetCompact(Bool)
                Window.Compact = Bool
                local TargetWidth = Bool and 50 or 225

                Items["LeftTabs"]:Tween(TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New(0, TargetWidth, 1, 0)})

                for _, Page in pairs(Window.Pages) do
                    local Button = Page.Items["Inactive"]
                    local Text = Page.Items["Text"]
                    local Icon = Page.Items["Icon"]

                    if Bool then
                        Text:Tween(nil, {TextTransparency = 1})
                        Icon:Tween(nil, {Position = UDim2New(0.5, 0, 0.5, 0)})
                        Button:Tween(nil, {Size = UDim2New(1, 0, 0, 40)})
                    else
                        Text:Tween(nil, {TextTransparency = Page.Active and 0 or 0.3})
                        Icon:Tween(nil, {Position = UDim2New(0, 16, 0.5, 0)})
                        Button:Tween(nil, {Size = UDim2New(0, 200, 0, 40)})
                    end
                end
            end

            function Window:SetCenter()
                local CenterPosition = Items["MainFrame"].Instance.AbsolutePosition
                task.wait()
                Items["MainFrame"].Instance.AnchorPoint = Vector2New(0, 0)

                Items["MainFrame"].Instance.Position = UDim2New(0, CenterPosition.X, 0, CenterPosition.Y)
            end

            function Window:SetOpen(Bool)
                if Debounce then 
                    return
                end

                Window.IsOpen = Bool

                Debounce = true 

                if Window.IsOpen then 
                    Items["MainFrame"].Instance.Visible = true 
                end

                local Descendants = Items["MainFrame"].Instance:GetDescendants()
                TableInsert(Descendants, Items["MainFrame"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue 
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end
                
                NewTween.Tween.Completed:Connect(function()
                    Debounce = false 
                    Items["MainFrame"].Instance.Visible = Window.IsOpen
                end)
            end

            Items["FloatingButton"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Window:SetOpen(not Window.IsOpen)
                end
            end)

            --[[
            function Window:GetClosestFrame(Position, Instances)
                local ClosestRadius = math.huge
                local ClosestFrame

                local String = {"Items.LeftTabs", "Items.RightTabs", "Items.BottomTabs", "Items.TopTabs"}

                for Index, Value in (Instances or {Items.LeftTabs.Instance, Items.RightTabs.Instance, Items.BottomTabs.Instance, Items.TopTabs.Instance}) do
                    local Magnitude = (Vector2New(Value.AbsolutePosition.X, Value.AbsolutePosition.Y) - Position).Magnitude
                    if Magnitude < ClosestRadius then
                        ClosestFrame = String[Index]:gsub("Items.", "")
                        ClosestRadius = Magnitude
                    end
                end 

                return ClosestFrame
            end 

            function Window:UpdateTabs(CurrentAlignment)
                if CurrentAlignment == "TopTabs" or CurrentAlignment == "BottomTabs" then
                    for Index, Value in Window.Pages do 
                        Value.Items.Inactive.Instance.Parent = Items[CurrentAlignment].Instance
                        Value.Items.Inactive.Instance.Size = UDim2New(0, 70, 0, 60)
                        Value.Items.Text.Instance.Position = UDim2New(0.5, 0, 1, -2)
                        Value.Items.Text.Instance.AnchorPoint = Vector2New(0.5, 1)
                        Value.Items.Icon.Instance.AnchorPoint = Vector2New(0.5, 0.5)
                        Value.Items.Gradient.Instance.Rotation = -90
                        
                        if Value.Active then 
                            Value.Items.Icon.Instance.Size = UDim2New(0, 32, 0, 32)
                            Value.Items.Icon.Instance.Position = UDim2New(0.5, 0, 0.5, 0)
                            Value.Items.Text.Instance.TextTransparency = 1
                        else
                            Value.Items.Icon.Instance.Size = UDim2New(0, 24, 0, 24)
                            Value.Items.Icon.Instance.Position = UDim2New(0.5, 0, 0.5, -8)
                            Value.Items.Text.Instance.TextTransparency = 0
                        end
                    end
                elseif CurrentAlignment == "LeftTabs" or CurrentAlignment == "RightTabs" then
                    for Index, Value in Window.Pages do
                        Value.Items.Inactive.Instance.Parent = Items[CurrentAlignment].Instance
                        Value.Items.Inactive.Instance.Size = UDim2New(0, 200, 0, 40)

                        Value.Items.Text.Instance.Position = UDim2New(45, 0, 0.5, 0)
                        Value.Items.Text.Instance.AnchorPoint = Vector2New(0, 0.5)

                        Value.Items.Icon.Instance.AnchorPoint = Vector2New(0, 0.5)
                        Value.Items.Icon.Instance.Position = UDim2New(16, 0, 0.5, 0)
                        Value.Items.Icon.Instance.Size = UDim2New(0, 18, 0, 18)

                        Value.Items.Gradient.Instance.Rotation = 0
                    end
                        
                end
            end

            function Window:UpdateFrameSide(OldFrame, NewFrame)
                OldFrame.Instance.Visible = false 
                NewFrame.Instance.Visible = true
                Window:UpdateTabs(Window.CurrentAlignment)
            end

            function Window:UpdateHighlight(CurrentFrame, Bool)
                if Bool then
                    CurrentFrame.Instance.Visible = false 
                    Items["PagePlaceholder"].Instance.Visible = true
                else
                    CurrentFrame.Instance.Visible = true 
                    Items["PagePlaceholder"].Instance.Visible = false
                end
            end

            for Index, Value in {"Left", "Top", "Bottom", "Right"} do 
                local TabDragging = false
                local TabItem = Items[Value.."Tabs"]
                local SelectedParent

                TabItem:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
                        TabItem.Instance.Parent = Library.Holder.Instance
                        Window:UpdateHighlight(TabItem, true)
                        Items["PagePlaceholder"]:Tween(nil, {BackgroundTransparency = 0.3})
                        TabDragging = true 
                    end
                end)

                TabItem:Connect("InputEnded", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        TabDragging = false

                        if SelectedParent then
                            Items["PagePlaceholder"]:Tween(nil, {BackgroundTransparency = 1})
                            Window:UpdateHighlight(TabItem, false)
                            Window:UpdateFrameSide(TabItem, Items[SelectedParent])
                            Window.CurrentAlignment = SelectedParent
                        end
                    end                    
                end)

                Library:Connect(UserInputService.InputChanged, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement and TabDragging then 
                        SelectedParent = Window:GetClosestFrame(Vector2New(Input.Position.X, Input.Position.Y - 36))
                        local TargetSize
                        local TargetPosition
                        local TargetAnchorPoint

                        if SelectedParent == "LeftTabs" then
                            TargetSize = UDim2New(0, 225, 1, 0)
                            TargetPosition = UDim2New(0, 0, 0, 0)
                            TargetAnchorPoint = Vector2New(1, 0)
                        elseif SelectedParent == "RightTabs" then
                            TargetSize = UDim2New(0, 225, 1, 0)
                            TargetPosition = UDim2New(1, 0, 0, 0)
                            TargetAnchorPoint = Vector2New(0, 0)
                        elseif SelectedParent == "TopTabs" then
                            TargetSize = UDim2New(1, 0, 0, 80)
                            TargetPosition = UDim2New(0, 0, 0, 0)
                            TargetAnchorPoint = Vector2New(0, 1)
                        elseif SelectedParent == "BottomTabs" then
                            TargetSize = UDim2New(1, 0, 0, 90)
                            TargetPosition = UDim2New(0, 0, 1, 0)
                            TargetAnchorPoint = Vector2New(0, 0)
                        end
                        
                        Items["PagePlaceholder"].Instance.AnchorPoint = TargetAnchorPoint
                        Items["PagePlaceholder"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = TargetSize})
                        Items["PagePlaceholder"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = TargetPosition})
                    end
                end)
            end
            --]]

            function Window:Init()
                local OriginalTweenCreate = Tween.Create

                Tween.Create = function(self, Item, Info, Goal, IsRawItem)
                    local Item = IsRawItem and Item or Item.Instance
                    if not Item then return end

                    for Property, Value in pairs(Goal) do
                        Item[Property] = Value
                    end

                    return {
                        Tween = {
                            Play = function() end,
                            Completed = { Connect = function() return { Disconnect = function() end } end }
                        }
                    }
                end

                pcall(function()
                    for __, Value in Window.Pages do
                        if Value.Active then
                            for _, Value2 in Value.Sections do
                                Value2:TweenElements(true, true)
                            end
                        end
                    end
                end)

                Tween.Create = OriginalTweenCreate
            end

            --[[Library:Connect(UserInputService.InputBegan, function(Input)
                if tostring(Input.KeyCode) == Library.MenuKeybind or tostring(Input.UserInputType) == Library.MenuKeybind then
                    Window:SetOpen(not Window.IsOpen)
                end
            end)]]

            Window:SetCenter()
            if Window.Compact then
                Window:SetCompact(true)
            end
            task.wait()
            Window:SetOpen(true)
            return setmetatable(Window, Library)
        end

        Library.Category = function(self, Name, Collapsible)
            if type(Name) == "table" then
                Collapsible = Name.Collapsible or Name.collapsible or Collapsible
                Name = Name.Name or Name.name or "Category"
            end
            Name = tostring(Name or "Category")
            if not Collapsible then
                local Items = { } do
                    Items["Category"] = Instances:Create("TextLabel", {
                        Parent = self.Items["LeftTabs"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(240, 240, 240),
                        TextTransparency = 0.4000000059604645,
                        Text = Name,
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2New(1, 0, 0, 15),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["Category"]:AddToTheme({TextColor3 = "Text"})
                end
            else
                local Category = {
                    Window = self,
                    Items = { },
                    IsOpen = true
                }

                local Items = { } do
                    Items["Container"] = Instances:Create("Frame", {
                        Parent = self.Items["LeftTabs"].Instance,
                        Name = "\0",
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BorderColor3 = FromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    Instances:Create("UIListLayout", {
                        Parent = Items["Container"].Instance,
                        Name = "\0",
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDimNew(0, 5)
                    })

                    Items["Header"] = Instances:Create("TextButton", {
                        Parent = Items["Container"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(240, 240, 240),
                        TextTransparency = 0.4000000059604645,
                        Text = Name,
                        Size = UDim2New(1, 0, 0, 15),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        AutoButtonColor = false
                    }) Items["Header"]:AddToTheme({TextColor3 = "Text"})

                    Items["Arrow"] = Instances:Create("ImageLabel", {
                        Parent = Items["Header"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(141, 141, 150),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 12, 0, 12),
                        AnchorPoint = Vector2New(1, 0.5),
                        Image = "rbxassetid://123317177279443",
                        BackgroundTransparency = 1,
                        Position = UDim2New(1, 0, 0.5, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        Rotation = 180,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    Items["Content"] = Instances:Create("Frame", {
                        Parent = Items["Container"].Instance,
                        Name = "\0",
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BorderColor3 = FromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    Instances:Create("UIListLayout", {
                        Parent = Items["Content"].Instance,
                        Name = "\0",
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDimNew(0, 12)
                    })

                    Instances:Create("UIPadding", {
                        Parent = Items["Content"].Instance,
                        Name = "\0",
                        PaddingLeft = UDimNew(0, 10),
                        PaddingTop = UDimNew(0, 5)
                    })
                end

                function Category:SetOpen(Bool)
                    Category.IsOpen = Bool
                    if Category.IsOpen then
                         Items["Content"].Instance.Visible = true
                         Items["Arrow"]:Tween(nil, {Rotation = 180})
                    else
                         Items["Content"].Instance.Visible = false
                         Items["Arrow"]:Tween(nil, {Rotation = 0})
                    end
                end

                Items["Header"]:Connect("MouseButton1Click", function()
                    Category:SetOpen(not Category.IsOpen)
                end)

                function Category:Page(Data)
                    local Page = self.Window:Page(Data)
                    Page.Items["Inactive"].Instance.Parent = Items["Content"].Instance
                    Page.Items["Inactive"].Instance.Size = UDim2New(1, 0, 0, 40)
                    return Page
                end

                return Category
            end
        end

        Library.Page = function(self, Data)
            Data = Data or { }

            local Page = {
                Window = self,

                Name = Data.Name or Data.name or "Page",
                Icon = Data.Icon or Data.icon or "100050851789190",
                Columns = Data.Columns or Data.columns or 2,

                Items = { },
                ColumnsData = { },
                Sections = { },
                Active = false
            }

            local Items = { } do
                local IsCompact = Page.Window.Compact
                Items["Inactive"] = Instances:Create("TextButton", {
                    Parent = Page.Window.Items["LeftTabs"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = IsCompact and UDim2New(1, 0, 0, 40) or UDim2New(0, 200, 0, 40),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })  Items["Inactive"]:AddToTheme({BackgroundColor3 = "Accent"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })
                
                Items.Gradient = Instances:Create("UIGradient", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 0.41874998807907104), NumSequenceKeypoint(0.445, 0.78125), NumSequenceKeypoint(0.751, 0.9375), NumSequenceKeypoint(1, 1)}
                })

                Items["SelectedIndicator"] = Instances:Create("Frame", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 4, 0, 18),
                    Position = UDim2New(0, 0, 0.5, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 3
                })  Items["SelectedIndicator"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["SelectedIndicator"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 2)
                })
                
                local PageIcon = Library:GetCustomIcon(Page.Icon)
                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 18, 0, 18),
                    AnchorPoint = IsCompact and Vector2New(0.5, 0.5) or Vector2New(0, 0.5),
                    Image = PageIcon and PageIcon.Url or "",
                    ImageRectOffset = PageIcon and PageIcon.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = PageIcon and PageIcon.ImageRectSize or Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    Position = IsCompact and UDim2New(0.5, 0, 0.5, 0) or UDim2New(0, 16, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --Items["Icon"]:AddToTheme({ImageColor3 = "Accent"})

                Instances:Create("UIGradient", {
                    Parent = Items["Icon"].Instance,
                    Name = "\0",
                    Rotation = -115
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Page.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 45, 0.5, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    TextTransparency = IsCompact and 1 or 0.3,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})      
                
                Items["Page"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Visible = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    Position = UDim2New(0, 0, 0, 60),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Padding = UDimNew(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalFlex = Enum.UIFlexAlignment.Fill
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 10),
                    PaddingBottom = UDimNew(0, 10),
                    PaddingRight = UDimNew(0, 10),
                    PaddingLeft = UDimNew(0, 10)
                })                

                for Index = 1, Page.Columns do 
                    local NewColumn = Instances:Create("ScrollingFrame", {
                        Parent = Items["Page"].Instance,
                        Name = "\0",
                        ScrollBarImageColor3 = FromRGB(0, 0, 0),
                        Active = true,
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        ScrollBarThickness = 0,
                        BorderColor3 = FromRGB(0, 0, 0),
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 100, 0, 100),
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        CanvasSize = UDim2New(0, 0, 0, 0)
                    })
                    
                    Instances:Create("UIListLayout", {
                        Parent = NewColumn.Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })

                    Page.ColumnsData[Index] = NewColumn
                end

                Page.Items = Items
            end

            local Debounce = false

            function Page:_ForceOff()
                if not Page.Active then return end
                Page.Active = false
                Items["Page"].Instance.Visible = false
                Items["Page"].Instance.Parent = Library.UnusedHolder.Instance

                Items["Inactive"]:Tween(nil, {BackgroundTransparency = 1})
                Items["SelectedIndicator"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1, Size = UDim2New(0, 4, 0, 0)})
                Items["Text"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Library.Theme.Text, Position = UDim2New(0, 45, 0.5, 0)})
                Items["Icon"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageColor3 = FromRGB(255, 255, 255), Position = UDim2New(0, 16, 0.5, 0)})

                task.spawn(function()
                    for _, Value in Page.Sections do
                        Value:TweenElements(false, true)
                    end
                end)
            end

            function Page:Turn(Bool)
                if Debounce and Bool == Page.Active then return end

                Page.Active = Bool

                Debounce = true
                Items["Page"].Instance.Visible = Bool
                Items["Page"].Instance.Parent = Bool and Page.Window.Items["Content"].Instance or Library.UnusedHolder.Instance

                if Page.Active and Page.Name ~= "Dashboard" then
                    pcall(function()
                        if writefile and Library.Folders then
                            writefile(Library.Folders.Directory .. "/lastpage.txt", tostring(Page.Name))
                        end
                    end)
                end

                if Page.Active then
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 0.25})
                    Items["SelectedIndicator"]:Tween(TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Size = UDim2New(0, 4, 0, 18)})
                    Items["Text"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Library.Theme.Accent, Position = UDim2New(0, 49, 0.5, 0)})
                    Items["Icon"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageColor3 = Library.Theme.Accent, Position = UDim2New(0, 20, 0.5, 0)})
                    Items["Page"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                    for Index, Value in Page.Sections do
                        task.spawn(function() Value:TweenElements(true) end)
                    end
                else
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 1})
                    Items["SelectedIndicator"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1, Size = UDim2New(0, 4, 0, 0)})
                    Items["Text"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Library.Theme.Text, Position = UDim2New(0, 45, 0.5, 0)})
                    Items["Icon"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageColor3 = FromRGB(255, 255, 255), Position = UDim2New(0, 16, 0.5, 0)})
                    Items["Page"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 60)})
                end

                local AllInstances = Items["Page"].Instance:GetDescendants()
                TableInsert(AllInstances, Items["Page"].Instance)

                local NewTween

                for Index, Value in AllInstances do
                    local TransparencyProperty = Tween:GetProperty(Value)
                    if not TransparencyProperty then continue end
                    if type(TransparencyProperty) == "table" then
                        for _, Property in TransparencyProperty do
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                Library:Connect(NewTween.Tween.Completed, function()
                    Debounce = false
                    if not Page.Active then
                        for Index, Value in Page.Sections do
                            task.spawn(function() Value:TweenElements(false, true) end)
                        end
                    end
                end)
            end

            Items["Inactive"]:Connect("MouseButton1Click", function()
                if Page.Window.ActivePage == Page then return end
                Page.Window:SelectTab(Page)
            end)

            if #Page.Window.Pages == 0 then
                Page.Window.ActivePage = Page
                Page:Turn(true)
            end

            TableInsert(Page.Window.Pages, Page)

            if Page.Window.SelectedTab and Page.Window.SelectedTab == #Page.Window.Pages then
                Page.Window:SelectTab(Page)
            end

            return setmetatable(Page, Library.Pages)
        end

        Library.Pages.GlobalChat = function(self, Side)
            local GlobalChat = { }
            Library.GlobalChatt = GlobalChat

            local Items = { } do 
                Items["GlobalChat"] = Instances:Create("Frame", {
                    Parent = self.ColumnsData[Side].Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.30000001192092896,
                    Position = UDim2New(0,0,0,0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["GlobalChat"]:AddToTheme({BackgroundColor3 = "Section Background 2"})

                Items["GlobalChat"]:MakeDraggable()
                
                Instances:Create("UICorner", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })
                
                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "GLOBAL CHAT",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 13),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 16,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
                
                Items["SubTitle"] = Instances:Create("TextLabel", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.4000000059604645,
                    Text = "Chat with other users here.",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 14, 0, 30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["SubTitle"]:AddToTheme({TextColor3 = "Text"})
                
                Items["Message"] = Instances:Create("Frame", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    Selectable = true,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 1, -12),
                    Size = UDim2New(1, -66, 0, 32),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Message"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Message"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Message"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    Selectable = true,
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Size = UDim2New(1, -20, 0, 15),
                    Position = UDim2New(0, 10, 0, 8),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = "Message...",
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Input"]:AddToTheme({TextColor3 = "Text"})
                
                Items["SendButton"] = Instances:Create("TextButton", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 1),
                    Position = UDim2New(1, -12, 1, -12),
                    Size = UDim2New(0, 32, 0, 32),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["SendButton"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["SendButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["SendIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["SendButton"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ImageTransparency = 0.2,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://101636617799068",
                    BackgroundTransparency = 1,
                    ZIndex = 3,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 22, 0, 22),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["SendButton"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0)
                })  --Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["SendButton"]:OnHover(function()
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time+0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 0})
                end)

                Items["SendButton"]:OnHoverLeave(function()
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time+0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1})
                end)
                
                Items["Messages"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    ScrollBarImageColor3 = FromRGB(124, 163, 255),
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, -24, 1, -115),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 60),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })  Items["Messages"]:AddToTheme({ScrollBarImageColor3 = "Accent"})
                
                Instances:Create("UIListLayout", {
                    Parent = Items["Messages"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Messages"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 0),
                    PaddingBottom = UDimNew(0, 0),
                    PaddingRight = UDimNew(0, 10),
                    PaddingLeft = UDimNew(0, 0)
                })

                Items["Status"] = Instances:Create("Frame", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -12, 0, 10),
                    Size = UDim2New(0, 100, 0, 20),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["StatusCircle"] = Instances:Create("Frame", {
                    Parent = Items["Status"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 12, 0, 12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 210, 62)
                })

                Items["Glow"] = Instances:Create("ImageLabel", {
                    Parent = Items["StatusCircle"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 210, 62),
                    ScaleType = Enum.ScaleType.Slice,
                    ImageTransparency = 0.30000001192092896,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    Size = UDim2New(1, 8, 1, 8),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "http://www.roblox.com/asset/?id=18245826428",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    SliceCenter = RectNew(Vector2New(21, 21), Vector2New(79, 79))
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["StatusCircle"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Items["StatusText"] = Instances:Create("TextLabel", {
                    Parent = Items["Status"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 210, 62),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "67 Active | Connected",
                    AnchorPoint = Vector2New(1, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -20, 0.5, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })                
            end

            function GlobalChat:SetVisibility(Bool)
                Items["GlobalChat"].Instance.Visible = Bool
                Items["GlobalChat"].Instance.Parent = Bool and Data.MainFrame.Instance or Library.UnusedHolder
            end

            function GlobalChat:SetStatus(Text, Color)
                Items["StatusText"].Instance.Text = Text
                Items["StatusText"].Instance.TextColor3 = Color
                Items["StatusCircle"].Instance.BackgroundColor3 = Color
            end

            function GlobalChat:SetStatusText(Text)
                if not Done then
                    Items["StatusText"].Instance.TextColor3 = FromRGB(62, 255, 91)
                    Items["Glow"].Instance.ImageColor3 = FromRGB(62, 255, 91)
                    Items["StatusCircle"].Instance.BackgroundColor3 = FromRGB(62, 255, 91)
                    Done = true
                end
                Items["StatusText"].Instance.Text = Text
            end

            local OnMessagePressed            

            function GlobalChat:OnMessageSendPressed(Func)
                OnMessagePressed = Func
            end

            function GlobalChat:GetTypedMessage()
                return Items["Input"].Instance.Text
            end

            function GlobalChat:ClearText()
                Items["Input"].Instance.Text = ""
            end

            function GlobalChat:SendMessage(Avatar, Username, Message, IsLocalPlayer)
                local SubItems = { } do
                    if not IsLocalPlayer then
                        SubItems["Message1"] = Instances:Create("Frame", {
                            Parent = Items["Messages"].Instance,
                            Name = "\0",
                            BackgroundTransparency = 1,
                            Size = UDim2New(1, 0, 0, 45),
                            ZIndex = 2,
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        SubItems["PlayerName"] = Instances:Create("TextLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Username,
                            Size = UDim2New(0, 0, 0, 15),
                            BackgroundTransparency = 1,
                            RichText = true,
                            Position = UDim2New(0, 38, 0, 0),
                            TextTransparency = 0.3,
                            BorderSizePixel = 0,
                            ZIndex = 2,
                            AutomaticSize = Enum.AutomaticSize.X,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["PlayerName"]:AddToTheme({TextColor3 = "Text"})

                        SubItems["RealMessage"] = Instances:Create("Frame", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            Position = UDim2New(0, 38, 0, 20),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            ZIndex = 2,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            BackgroundColor3 = FromRGB(27, 25, 29)
                        })  SubItems["RealMessage"]:AddToTheme({BackgroundColor3 = "Background"})

                        Instances:Create("UISizeConstraint", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            MaxSize = Vector2New(370, 70)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })

                        SubItems["MessageText"] = Instances:Create("TextLabel", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Message,
                            BackgroundTransparency = 1,
                            TextWrapped = true,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            TextSize = 14,
                            ZIndex = 2,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["MessageText"]:AddToTheme({TextColor3 = "Text"})

                        Instances:Create("UIPadding", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            PaddingTop = UDimNew(0, 10),
                            PaddingBottom = UDimNew(0, 10),
                            PaddingRight = UDimNew(0, 10),
                            PaddingLeft = UDimNew(0, 10)
                        })

                        SubItems["Avatar"] = Instances:Create("ImageLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            BorderColor3 = FromRGB(0, 0, 0),
                            AnchorPoint = Vector2New(0, 0.5),
                            Image = Avatar,
                            BackgroundTransparency = 1,
                            Position = UDim2New(0, 0, 0.5, 0),
                            Size = UDim2New(0, 30, 0, 30),
                            ZIndex = 2,
                            BorderSizePixel = 0,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["Avatar"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })
                    else
                        SubItems["Message1"] = Instances:Create("Frame", {
                            Parent = Items["Messages"].Instance,
                            Name = "\0",
                            BackgroundTransparency = 1,
                            Size = UDim2New(1, 0, 0, 45),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            ZIndex = 2,
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        SubItems["PlayerName"] = Instances:Create("TextLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Username,
                            RichText = true,
                            AnchorPoint = Vector2New(1, 0),
                            Size = UDim2New(0, 0, 0, 15),
                            ZIndex = 2,
                            TextTransparency = 0.3,
                            BackgroundTransparency = 1,
                            Position = UDim2New(1, -38, 0, 0),
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.X,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["PlayerName"]:AddToTheme({TextColor3 = "Text"})

                        SubItems["RealMessage"] = Instances:Create("Frame", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            AnchorPoint = Vector2New(1, 0),
                            Position = UDim2New(1, -38, 0, 20),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            ZIndex = 2,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            BackgroundColor3 = FromRGB(27, 25, 29)
                        })  SubItems["RealMessage"]:AddToTheme({BackgroundColor3 = "Background"})

                        Instances:Create("UISizeConstraint", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            MaxSize = Vector2New(370, 75)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })

                        SubItems["MessageText"] = Instances:Create("TextLabel", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Message,
                            BackgroundTransparency = 1,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            ZIndex = 2,
                            TextWrapped = true,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["MessageText"]:AddToTheme({TextColor3 = "Text"})

                        Instances:Create("UIPadding", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            PaddingTop = UDimNew(0, 10),
                            PaddingBottom = UDimNew(0, 10),
                            PaddingRight = UDimNew(0, 10),
                            PaddingLeft = UDimNew(0, 10)
                        })

                        SubItems["Avatar"] = Instances:Create("ImageLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            BorderColor3 = FromRGB(0, 0, 0),
                            AnchorPoint = Vector2New(1, 0.5),
                            Image = Avatar,
                            ZIndex = 2,
                            BackgroundTransparency = 1,
                            Position = UDim2New(1, 0, 0.5, 0),
                            Size = UDim2New(0, 30, 0, 30),
                            BorderSizePixel = 0,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["Avatar"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })
                    end
                end
            end

            Items["SendButton"]:Connect("MouseButton1Click", function()
                if GlobalChat:GetTypedMessage() == "" then
                    return
                end
                
                OnMessagePressed()
            end)

            Items["Messages"]:Connect("ChildAdded", function()
                task.wait()
                Items["Messages"]:Tween(nil, {CanvasPosition = Vector2New(0, Items["Messages"].Instance.AbsoluteCanvasSize.Y - Items["Messages"].Instance.AbsoluteSize.Y)})
            end)

            for Index, Value in Items["GlobalChat"].Instance:GetDescendants() do 
                if Value.ClassName:find("UI") then 
                    continue 
                end

                Value.ZIndex = 2
            end

            Items["GlobalChat"].Instance.ZIndex = 2
            Items["SendIcon"].Instance.ZIndex = 3

            return GlobalChat 
        end

        Library.Pages.Section = function(self, Data)
            Data = Data or { }

            local Section = {
                Window = self.Window,
                Page = self,

                Name = Data.Name or Data.name or "Section",
                Description = Data.Description or Data.description or Data.desc or "",
                Icon = Data.Icon or Data.icon or "123944728972740",
                Side = Data.Side or Data.side or 1,

                Items = { },
                IsActive = true,
                Elements = { }
            }

            local Items = { } do
                Items["Section"] = Instances:Create("Frame", {
                    Parent = Section.Page.ColumnsData[Section.Side].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    ClipsDescendants = true,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 0),
                    ZIndex = 2,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(29, 28, 32)
                })  Items["Section"]:AddToTheme({BackgroundColor3 = "Section Background 2"})

                Instances:Create("UIListLayout", {
                    Parent = Items["Section"].Instance,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 0),
                    HorizontalAlignment = Enum.HorizontalAlignment.Center
                })
                
                Items["Top"] = Instances:Create("Frame", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.6499999761581421,
                    Size = UDim2New(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(31, 31, 36),
                    LayoutOrder = 1
                })  Items["Top"]:AddToTheme({BackgroundColor3 = "Outline"})

                Instances:Create("UIPadding", {
                    Parent = Items["Top"].Instance,
                    PaddingBottom = UDimNew(0, 1)
                })
                
                -- Main Horizontal Container
                Items["TopBackground"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 1, 0, 1),
                    Size = UDim2New(1, -2, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["TopBackground"]:AddToTheme({BackgroundColor3 = "Section Top"})

                Instances:Create("UIListLayout", {
                    Parent = Items["TopBackground"].Instance,
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 0)
                })

                -- 1. Icon Container
                Items["IconContainer"] = Instances:Create("Frame", {
                    Parent = Items["TopBackground"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 50, 0, 30),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = 1,
                    ZIndex = 2
                })
                
                local SectionIcon = Library:GetCustomIcon(Section.Icon)
                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["IconContainer"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 21, 0, 20),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Image = SectionIcon and SectionIcon.Url or "",
                    ImageRectOffset = SectionIcon and SectionIcon.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = SectionIcon and SectionIcon.ImageRectSize or Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --Items["Icon"]:AddToTheme({ImageColor3 = "Accent"})
                
                Instances:Create("UIGradient", {
                    Parent = Items["Icon"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(131, 131, 131)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                -- 2. Left Container (Title + Description)
                Items["TextContainer"] = Instances:Create("Frame", {
                    Parent = Items["TopBackground"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, -95, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = 2,
                    ZIndex = 2
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["TextContainer"].Instance,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 3)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["TextContainer"].Instance,
                    PaddingBottom = UDimNew(0, 10),
                    PaddingTop = UDimNew(0, 10)
                })

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["TextContainer"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(248, 248, 248),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Section.Name,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Size = UDim2New(1, 0, 0, 15),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    LayoutOrder = 1
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                if Section.Description and Section.Description ~= "" then
                    Items["Description"] = Instances:Create("TextLabel", {
                        Parent = Items["TextContainer"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(183, 183, 183),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = Section.Description,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Size = UDim2New(1, 0, 0, 0),
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextWrapped = true,
                        BorderSizePixel = 0,
                        TextTransparency = 0.4,
                        ZIndex = 2,
                        TextSize = 13,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        LayoutOrder = 2
                    })  Items["Description"]:AddToTheme({TextColor3 = "Text"})
                end

                Instances:Create("UICorner", {
                    Parent = Items["TopBackground"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                -- 3. Toggle Container
                Items["ToggleContainer"] = Instances:Create("Frame", {
                    Parent = Items["TopBackground"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 45, 0, 30),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = 3,
                    ZIndex = 2
                })

                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = Items["ToggleContainer"].Instance,
                    Name = "\0",
                    Active = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Selectable = false,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 26, 0, 16),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --Items["Toggle"]:AddToTheme({BackgroundColor3 = "Accent"})
                
                Items["Circle"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, -4, 0.5, 0),
                    Size = UDim2New(0, 8, 0, 8),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Circle"]:AddToTheme({BackgroundColor3 = "Text"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Circle"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 99999)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 9)
                })
                
                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Instances:Create("UICorner", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Fill"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 1, 1, -4),
                    Size = UDim2New(1, -2, 0, 4),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Fill"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Fill"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["TopFills"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 3),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  
                
                Items["Right1"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(1, -1, 0, 0),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Right1"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Items["Right2"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(1, -1, 0, 1),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Right2"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Items["Right3"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(1, -2, 0, 1),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Right3"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Items["Left1"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 2, 0, 0),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Left1"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Items["Left2"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 2, 0, 1),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Left2"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Items["Left3"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 3, 0, 1),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Left3"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Size = UDim2New(1, -2, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = 2,
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(24, 22, 25)
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 15),
                    Size = UDim2New(1, -24, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })                

                Items["Fade"] = Instances:Create("TextButton", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 10, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    Visible = false,
                    Text = "",
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(24, 22, 25)
                })  Items["Fade"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Fade"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })                

                Instances:Create("UIPadding", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    PaddingBottom = UDimNew(0, 10)
                })

                Section.Items = Items
            end

            function Section:ToggleBackground()
                Section.IsActive = not Section.IsActive

                if not Section.IsActive then 
                    Items["Fade"].Instance.Visible = true
                    Items["Fade"]:Tween(nil, {BackgroundTransparency = 0.3})
    
                    Items["Gradient"].Instance.Enabled = false
                    Items["Toggle"]:ChangeItemTheme({BackgroundColor3 = "Element"})
                    Items["Toggle"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                    Items["Circle"]:Tween(nil, {AnchorPoint = Vector2New(0, 0.5), Position = UDim2New(0, 4, 0.5, 0), BackgroundColor3 = Library.Theme.Text, BackgroundTransparency = 0.6})
                else
                    Items["Fade"]:Tween(nil, {BackgroundTransparency = 1})
                    task.spawn(function() 
                        task.wait(Library.Tween.Time)
                        Items["Fade"].Instance.Visible = false
                    end)

                    Items["Gradient"].Instance.Enabled = true
                    Items["Toggle"]:ChangeItemTheme({BackgroundColor3 = "Text"})
                    Items["Toggle"]:Tween(nil, {BackgroundColor3 = Library.Theme.Text})
                    Items["Circle"]:Tween(nil, {AnchorPoint = Vector2New(1, 0.5), Position = UDim2New(1, -4, 0.5, 0), BackgroundColor3 = Library.Theme.Text, BackgroundTransparency = 0})
                end
            end

            Library:Connect(Items["Content"].Instance.Changed, function(Property)
                if Property == "AbsoluteSize" then
                    Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Items["Content"].Instance.AbsoluteSize.Y + 10)
                end
            end)

            function Section:TweenElements(Bool, Debounce)
                for Index, Value in Section.Elements do
                    Value:RefreshPosition(Bool)
                    if not Debounce then 
                        task.wait(0.03)
                    end
                end
            end

            Items["Toggle"]:Connect("MouseButton1Click", function()
                Section:ToggleBackground()
            end)

            Section.Page.Sections[Section.Name] = Section

            return setmetatable(Section, Library.Sections)
        end

        Library.Pages.Tabbox = function(self, Data)
            Data = Data or {}

            local Tabbox = {
                Window = self.Window,
                Page = self,
                Side = Data.Side or 1,
                Tabs = {},
                ActiveTab = nil,
                Items = {}
            }

            local Items = {} do
                Items["Section"] = Instances:Create("Frame", {
                    Parent = Tabbox.Page.ColumnsData[Tabbox.Side].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 0),
                    ZIndex = 2,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(29, 28, 32)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Section"].Instance,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 0)
                })

                Items["Top"] = Instances:Create("Frame", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    LayoutOrder = 1
                })

                Items["TabButtons"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["TabButtons"].Instance,
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 0)
                })

                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.65,
                    Size = UDim2New(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    BackgroundColor3 = FromRGB(26, 26, 30),
                    LayoutOrder = 2
                })
                Instances:Create("UICorner", {Parent = Items["Content"].Instance, CornerRadius = UDimNew(0, 4)})
            end

            function Tabbox:RefreshPosition(Bool)
                if Bool then
                    Items["Header"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                    Items["Content"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 30)})
                else
                    Items["Header"].Instance.Position = UDim2New(0, 30, 0, 0)
                    Items["Content"].Instance.Position = UDim2New(0, 30, 0, 30)
                end
            end

            function Tabbox:AddTab(Name)
                if not Library then return end
                local Icon = Library:GetCustomIcon(Name)
                local IsIcon = Icon ~= nil

                local Tab = {
                    Window = Tabbox.Window,
                    Page = Tabbox.Page,
                    Section = Tabbox,
                    Items = {},
                    Elements = {}
                }

                TableInsert(Tabbox.Tabs, Tab)

                -- Recalculate width
                local Width = 1 / #Tabbox.Tabs
                for _, T in pairs(Tabbox.Tabs) do
                    if T.Items["Button"] then
                        T.Items["Button"].Instance.Size = UDim2New(Width, 0, 1, 0)
                    end
                end

                Tab.Items["Button"] = Instances:Create("TextButton", {
                    Parent = Items["TabButtons"].Instance,
                    Name = "\0",
                    Text = "",
                    Size = UDim2New(Width, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(35, 35, 38), -- Lighter than container (29, 28, 32)
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextSize = 14,
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    AutoButtonColor = false
                })

                if IsIcon then
                    Tab.Items["Icon"] = Instances:Create("ImageLabel", {
                        Parent = Tab.Items["Button"].Instance,
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 20, 0, 20),
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Image = Icon.Url,
                        ImageRectOffset = Icon.ImageRectOffset,
                        ImageRectSize = Icon.ImageRectSize,
                        ImageColor3 = FromRGB(150, 150, 150),
                        BorderSizePixel = 0,
                        ZIndex = 4
                    })
                end

                Tab.Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Visible = false,
                    BorderSizePixel = 0
                })

                Instances:Create("UIListLayout", {
                    Parent = Tab.Items["Content"].Instance,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 5)
                })

                Instances:Create("UIPadding", {
                    Parent = Tab.Items["Content"].Instance,
                    PaddingTop = UDimNew(0, 10),
                    PaddingBottom = UDimNew(0, 10),
                    PaddingLeft = UDimNew(0, 10),
                    PaddingRight = UDimNew(0, 10)
                })

                function Tab:Show()
                    if Tabbox.ActiveTab == Tab then return end

                    if Tabbox.ActiveTab then
                        Tabbox.ActiveTab:Hide()
                    end
                    Tabbox.ActiveTab = Tab

                    Tab.Items["Content"].Instance.Visible = true

                    -- Active Style
                    Tab.Items["Button"]:Tween(nil, {BackgroundTransparency = 0})

                    if Tab.Items["Icon"] then
                        Tab.Items["Icon"]:Tween(nil, {ImageColor3 = Library.Theme.Accent})
                    end
                end

                function Tab:Hide()
                    Tab.Items["Content"].Instance.Visible = false

                    -- Inactive Style
                    Tab.Items["Button"]:Tween(nil, {BackgroundTransparency = 1})

                    if Tab.Items["Icon"] then
                        Tab.Items["Icon"]:Tween(nil, {ImageColor3 = FromRGB(150, 150, 150)})
                    end
                end

                function Tab:RefreshPosition(Bool)
                end

                function Tab:TweenElements(Bool, Debounce)
                    for Index, Value in Tab.Elements do
                        if Value.RefreshPosition then
                            Value:RefreshPosition(Bool)
                        end
                        if not Debounce then
                            task.wait(0.03)
                        end
                    end
                end

                Tab.Items["Button"]:Connect("MouseButton1Click", function()
                    Tab:Show()
                end)

                if not Tabbox.ActiveTab then
                    Tab:Show()
                end

                Tab.Page.Sections[Name] = Tab
                return setmetatable(Tab, Library.Sections)
            end

            Tabbox.Items = Items
            return Tabbox
        end

        Library.Pages.AddLeftTabbox = function(self, Name)
            return self:Tabbox({ Side = 1, Name = Name })
        end

        Library.Pages.AddRightTabbox = function(self, Name)
            return self:Tabbox({ Side = 2, Name = Name })
        end

        Library.Sections.Toggle = function(self, Data)
            Data = Data or { }
            
            local Toggle = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Toggle",
                Description = Data.Description or Data.description or Data.desc or "",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or false,
                Callback = Data.Callback or Data.callback or function() end,

                Value = false,
                HasSettings = Data.HasSettings or Data.hasSettings or false,
                ParentToggle = Data.ParentToggle,
                IsSubToggle = Data.IsSubToggle == true,
                SubToggleLevel = Data.SubToggleLevel or 0,
                _subToggles = { },
                _subToggleSection = nil,
                _settingsExpanded = false,
                _settingsHeight = 0,
            }

            local BaseToggleHeight = Toggle.Description ~= "" and 34 or 18
            local CurrentToggleHeight = BaseToggleHeight

            local Items = { } do 
                Items["Wrapper"] = Instances:Create("Frame", {
                    Parent = Toggle.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, CurrentToggleHeight),
                    ZIndex = 2,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                local _ToggleParent = Items["Wrapper"].Instance

                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = _ToggleParent,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, CurrentToggleHeight),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                -- PC users get a ~15% larger indicator (21px vs 18px) for easier clicking
                local _IndicatorSize = IsMobile and 18 or 24
                local IndicatorAnchorY = Toggle.Description ~= "" and 0 or 0.5
                local IndicatorPositionY = Toggle.Description ~= "" and 1 or -math.floor(_IndicatorSize / 2)

                Items["Indicator"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, _IndicatorSize, 0, _IndicatorSize),
                    Position = UDim2New(0, 0, IndicatorAnchorY, IndicatorPositionY),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })  Items["Indicator"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 3)
                })

                Items["IndicatorStroke"] = Instances:Create("UIStroke", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Color = FromRGB(0, 0, 0),
                    Thickness = 1,
                    Transparency = 0.5
                }) Items["IndicatorStroke"]:AddToTheme({Color = "Outline"})

                Items["CheckImage"] = Instances:Create("ImageLabel", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://121760666525660",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    ImageTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["TextRow"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, -60, 0, 15),
                    Position = UDim2New(0, 24, 0, 0),
                    ZIndex = 2,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["TextRow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Toggle.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    Position = UDim2New(0, 0, 0, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                if Toggle.Description ~= "" then
                    Items["Description"] = Instances:Create("TextLabel", {
                        Parent = Items["Toggle"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(183, 183, 183),
                        TextTransparency = 0.4,
                        Text = Toggle.Description,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Size = UDim2New(1, -60, 0, 0),
                        Position = UDim2New(0, 24, 0, 16),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        TextWrapped = true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Top,
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        TextSize = 12,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["Description"]:AddToTheme({TextColor3 = "Text"})
                end

                if Toggle.IsSubToggle then
                    Items["Text"].Instance.TextSize = 13
                    Items["Text"].Instance.TextTransparency = 0.36

                    if Items["Description"] then
                        Items["Description"].Instance.TextSize = 11
                        Items["Description"].Instance.TextTransparency = 0.5
                    end
                end

                Items["IndicatorGradient"] = Instances:Create("UIGradient", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    Enabled = false,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.Accent)}
                })  Items["IndicatorGradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.Accent)}
                end})

                Items["Toggle"]:OnHover(function()
                    --Items["Indicator"]:Tween(TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 21, 0, 21), Position = UDim2New(0, -3, 0, -3)})
                end)

                Items["Toggle"]:OnHoverLeave(function()
                    --Items["Indicator"]:Tween(TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 18, 0, 18), Position = UDim2New(0, 0, 0, 0)})
                end)
            end

            local _IndicatorSize = IsMobile and 18 or 24
            local _TextXOffset   = _IndicatorSize + 4
            local IndicatorAnchorY = Toggle.Description ~= "" and 0 or 0.5
            local IndicatorPositionY = Toggle.Description ~= "" and 1 or -math.floor(_IndicatorSize / 2)

            Items["Indicator"].Instance.Position = UDim2New(0, 30, IndicatorAnchorY, IndicatorPositionY)
            Items["TextRow"].Instance.Position = UDim2New(0, 30 + _TextXOffset, 0, 0)
            if Items["Description"] then
                Items["Description"].Instance.Position = UDim2New(0, 30 + _TextXOffset, 0, 16)
            end

            local UpdateWrapperSize

            local function UpdateDescriptionLayout()
                if not Items["Description"] then
                    CurrentToggleHeight = BaseToggleHeight
                    Items["Toggle"].Instance.Size = UDim2New(1, 0, 0, CurrentToggleHeight)
                    UpdateWrapperSize()
                    return
                end

                local availableWidth = math.max(80, Items["Toggle"].Instance.AbsoluteSize.X - (30 + _TextXOffset) - 8)
                local textSize = TextService:GetTextSize(
                    Toggle.Description,
                    Items["Description"].Instance.TextSize,
                    Items["Description"].Instance.Font,
                    Vector2New(availableWidth, 1000)
                )

                local descriptionHeight = math.max(14, textSize.Y)
                Items["Description"].Instance.Size = UDim2New(0, availableWidth, 0, descriptionHeight)

                CurrentToggleHeight = math.max(BaseToggleHeight, 18 + descriptionHeight)
                Items["Toggle"].Instance.Size = UDim2New(1, 0, 0, CurrentToggleHeight)
                UpdateWrapperSize()
            end

            local function GetSubToggleHeight()
                if not Items["SubToggleHost"] or not Items["SubToggleLayout"] then
                    return 0
                end

                local height = Items["SubToggleLayout"].Instance.AbsoluteContentSize.Y
                return height > 0 and (height + 7) or 0
            end

            UpdateWrapperSize = function()
                local subToggleHeight = GetSubToggleHeight()
                local baseHeight = CurrentToggleHeight + subToggleHeight

                if Items["SubToggleHost"] then
                    Items["SubToggleHost"].Instance.Position = UDim2New(0, 16, 0, CurrentToggleHeight + 5)
                    Items["SubToggleHost"].Instance.Visible = subToggleHeight > 0
                end

                if Items["SettingsSeparator"] then
                    Items["SettingsSeparator"].Instance.Position = UDim2New(0, 0, 0, baseHeight + 4)
                end

                if Items["SettingsClipper"] then
                    Items["SettingsClipper"].Instance.Position = UDim2New(0, 0, 0, baseHeight + 5)
                end

                local targetHeight = baseHeight
                if Toggle.HasSettings and Toggle._settingsExpanded then
                    targetHeight = baseHeight + 5 + (Toggle._settingsHeight or 0)
                end

                Items["Wrapper"].Instance.Size = UDim2New(1, 0, 0, targetHeight)
            end

            local function ApplyParentToggleState()
                if not Toggle.ParentToggle then
                    return
                end

                local parentEnabled = Toggle.ParentToggle.Value == true

                Items["Text"].Instance.TextTransparency = parentEnabled and (Toggle.IsSubToggle and 0.36 or 0.3) or 0.62
                if Items["Description"] then
                    Items["Description"].Instance.TextTransparency = parentEnabled and (Toggle.IsSubToggle and 0.5 or 0.4) or 0.74
                end

                Items["Indicator"].Instance.BackgroundTransparency = parentEnabled and 0 or 0.25
                Items["IndicatorStroke"].Instance.Transparency = parentEnabled and (Toggle.Value and 1 or 0.5) or 0.72
                if Toggle.Value then
                    Items["CheckImage"].Instance.ImageTransparency = parentEnabled and 0 or 0.45
                else
                    Items["CheckImage"].Instance.ImageTransparency = 1
                end
            end

            function Toggle:RefreshPosition(Bool)
                local _IndicatorSize = IsMobile and 18 or 24
                local _TextXOffset   = _IndicatorSize + 4
                local IndicatorAnchorY = Toggle.Description ~= "" and 0 or 0.5
                local IndicatorPositionY = Toggle.Description ~= "" and 1 or -math.floor(_IndicatorSize / 2)
                if Bool then
                    Items["Indicator"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, IndicatorAnchorY, IndicatorPositionY)})
                    Items["TextRow"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, _TextXOffset, 0, 0)})
                    if Items["Description"] then
                        Items["Description"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, _TextXOffset, 0, 16)})
                    end
                else
                    Items["Indicator"].Instance.Position = UDim2New(0, 30, IndicatorAnchorY, IndicatorPositionY)
                    Items["TextRow"].Instance.Position = UDim2New(0, 30 + _TextXOffset, 0, 0)
                    if Items["Description"] then
                        Items["Description"].Instance.Position = UDim2New(0, 30 + _TextXOffset, 0, 16)
                    end
                end
            end

            function Toggle:Get()
                return Toggle.Value 
            end

            function Toggle:Set(Value, Instant)
                if Toggle.ParentToggle and not Toggle.ParentToggle.Value and Value == true then
                    return
                end

                Toggle.Value = Value 
                Library.Flags[Toggle.Flag] = Value 

                local _CheckSize = IsMobile and 12 or 16
                if Toggle.Value then
                    Items["IndicatorGradient"].Instance.Enabled = true
                    Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = function()
                        return Library.Theme.Accent
                    end})
                    if Instant then
                        Items["Indicator"].Instance.BackgroundColor3 = Library.Theme.Accent
                        Items["CheckImage"].Instance.ImageTransparency = 0
                        Items["CheckImage"].Instance.Size = UDim2New(0, _CheckSize, 0, _CheckSize)
                        Items["IndicatorStroke"].Instance.Transparency = 1
                    else
                        Items["Indicator"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Library.Theme.Accent})
                        Items["CheckImage"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ImageTransparency = 0, Size = UDim2New(0, _CheckSize, 0, _CheckSize)})
                        Items["IndicatorStroke"]:Tween(nil, {Transparency = 1})
                    end
                else
                    Items["IndicatorGradient"].Instance.Enabled = false
                    Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Element"})
                    if Instant then
                        Items["Indicator"].Instance.BackgroundColor3 = Library.Theme.Element
                        Items["CheckImage"].Instance.ImageTransparency = 1
                        Items["CheckImage"].Instance.Size = UDim2New(0, 0, 0, 0)
                        Items["IndicatorStroke"].Instance.Transparency = 0.5
                    else
                        Items["Indicator"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Library.Theme.Element})
                        Items["CheckImage"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ImageTransparency = 1, Size = UDim2New(0, 0, 0, 0)})
                        Items["IndicatorStroke"]:Tween(nil, {Transparency = 0.5})
                    end
                end

                if Toggle.Callback then 
                    Library:SafeCall(Toggle.Callback, Toggle.Value)
                end

                ApplyParentToggleState()

                for _, subToggle in ipairs(Toggle._subToggles) do
                    if subToggle.ApplyParentToggleState then
                        subToggle:ApplyParentToggleState()
                    end
                end

                -- HasSettings: sync settings panel visibility with toggle state
                if Toggle.HasSettings and Toggle.SetSettingsExpanded then
                    Toggle:SetSettingsExpanded(Toggle.Value)
                end
            end

            local GetAddonsHolder = function()
                if Items["AddonsHolder"] then
                    return Items["AddonsHolder"]
                end

                Items["AddonsHolder"] = Instances:Create("Frame", {
                    Parent = Items["Text"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 1, 0),
                    Position = UDim2New(1, 6, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    ZIndex = 2
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["AddonsHolder"].Instance,
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 5),
                    VerticalAlignment = Enum.VerticalAlignment.Center
                })

                return Items["AddonsHolder"]
            end

            function Toggle:ApplyParentToggleState()
                ApplyParentToggleState()
            end

            if Items["Description"] then
                Items["Toggle"].Instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    if not Library then
                        return
                    end
                    UpdateDescriptionLayout()
                end)
                UpdateDescriptionLayout()
            else
                UpdateWrapperSize()
            end

            local function EnsureSubToggleSection()
                if Toggle._subToggleSection then
                    return Toggle._subToggleSection
                end

                Items["SubToggleHost"] = Instances:Create("Frame", {
                    Parent = Items["Wrapper"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2New(0, 16, 0, CurrentToggleHeight + 5),
                    Size = UDim2New(1, -16, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Visible = false,
                    ZIndex = 2,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["SubToggleLayout"] = Instances:Create("UIListLayout", {
                    Parent = Items["SubToggleHost"].Instance,
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 4)
                })

                Toggle._subToggleSection = setmetatable({
                    Window = Toggle.Window,
                    Page = Toggle.Page,
                    Section = Toggle.Section,
                    Items = { Content = Items["SubToggleHost"] },
                    Elements = { },
                    IsSubToggleSection = true,
                    Name = Toggle.Name .. "_SubToggleSection",
                }, Library.Sections)

                Items["SubToggleLayout"].Instance:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if not Library then
                        return
                    end
                    UpdateWrapperSize()
                end)

                UpdateWrapperSize()
                return Toggle._subToggleSection
            end

            function Toggle:SubToggle(Data)
                Data = Data or {}
                assert(Data.Flag or Data.flag, "SubToggle requires Flag")

                local SubSection = EnsureSubToggleSection()
                local SubToggleData = TableClone(Data)
                SubToggleData.IsSubToggle = true
                SubToggleData.ParentToggle = Toggle
                SubToggleData.SubToggleLevel = (Toggle.SubToggleLevel or 0) + 1

                local SubToggle = Library.Sections.Toggle(SubSection, SubToggleData)
                TableInsert(Toggle._subToggles, SubToggle)
                UpdateWrapperSize()
                if SubToggle.ApplyParentToggleState then
                    SubToggle:ApplyParentToggleState()
                end
                return SubToggle
            end

            -- ─────────────────────────────────────────────────────────────
            -- HasSettings: inline expandable settings panel
            -- ─────────────────────────────────────────────────────────────
            if Toggle.HasSettings then
                -- Chevron arrow added to the addons holder (rotates on expand/collapse)
                local AddonsHolder = GetAddonsHolder()
                local ChevronIcon = Library:GetCustomIcon("chevron-down")
                Items["SettingsChevron"] = Instances:Create("ImageLabel", {
                    Parent = AddonsHolder.Instance,
                    Name = "\0",
                    Image = ChevronIcon and ChevronIcon.Url or "rbxassetid://6034818375",
                    ImageRectOffset = ChevronIcon and ChevronIcon.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = ChevronIcon and ChevronIcon.ImageRectSize or Vector2New(0, 0),
                    ImageColor3 = FromRGB(141, 141, 150),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(0, 12, 0, 12),
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 0, 0.5, 0),
                    ZIndex = 3,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    LayoutOrder = 99,
                })  Items["SettingsChevron"]:AddToTheme({ImageColor3 = "Text"})

                -- Separator line between toggle row and settings panel
                Items["SettingsSeparator"] = Instances:Create("Frame", {
                    Parent = Items["Wrapper"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.75,
                    BorderSizePixel = 0,
                    Position = UDim2New(0, 0, 0, CurrentToggleHeight + 4),
                    Size = UDim2New(1, 0, 0, 1),
                    ZIndex = 2,
                    Visible = false,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                })  Items["SettingsSeparator"]:AddToTheme({BackgroundColor3 = "Outline"})

                -- Clip frame: ClipsDescendants + manually tweened height
                Items["SettingsClipper"] = Instances:Create("Frame", {
                    Parent = Items["Wrapper"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2New(0, 0, 0, CurrentToggleHeight + 5),
                    Size = UDim2New(1, 0, 0, 0),
                    ClipsDescendants = true,
                    ZIndex = 2,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                })

                -- Accent bar on the left edge of the settings panel
                Items["SettingsAccentBar"] = Instances:Create("Frame", {
                    Parent = Items["SettingsClipper"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.55,
                    BorderSizePixel = 0,
                    Position = UDim2New(0, 0, 0, 3),
                    Size = UDim2New(0, 2, 1, -6),
                    ZIndex = 3,
                    BackgroundColor3 = FromRGB(124, 163, 255),
                })  Items["SettingsAccentBar"]:AddToTheme({BackgroundColor3 = "Accent"})

                -- Content frame: holds all child elements, auto-sizes vertically
                Items["SettingsContent"] = Instances:Create("Frame", {
                    Parent = Items["SettingsClipper"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2New(0, 10, 0, 0),
                    Size = UDim2New(1, -10, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 2,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                })

                local SettingsLayout = Instances:Create("UIListLayout", {
                    Parent = Items["SettingsContent"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                })

                Instances:Create("UIPadding", {
                    Parent = Items["SettingsContent"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 5),
                    PaddingBottom = UDimNew(0, 5),
                })

                -- Proxy section so Library.Sections.X() treats this as a normal section
                local SettingsSection = setmetatable({
                    Window = Toggle.Window,
                    Page   = Toggle.Page,
                    Section = Toggle.Section,
                    Items   = { Content = Items["SettingsContent"] },
                    Elements = { },
                    IsSettings = true,
                    Name = Toggle.Name .. "_InlineSettings",
                }, Library.Sections)

                Toggle.SettingsSection = SettingsSection

                -- Track expand state separately (Toggle.Value drives this)
                Toggle._settingsExpanded = false

                local function _MeasureSettingsHeight()
                    local Content = Items["SettingsContent"].Instance
                    local totalH = 10
                    local count = 0
                    for _, child in ipairs(Content:GetChildren()) do
                        if child:IsA("GuiObject") and child.Visible then
                            local h = child.Size.Y.Offset
                            if h <= 0 then h = 18 end
                            totalH = totalH + h
                            count = count + 1
                        end
                    end
                    if count > 1 then
                        totalH = totalH + (count - 1) * 5
                    end
                    return totalH
                end

                local function _GetSettingsHeight()
                    local h = SettingsLayout.Instance.AbsoluteContentSize.Y
                    return (h > 0 and h or 0) + 10
                end

                -- Core expand/collapse animation
                function Toggle:SetSettingsExpanded(Expanded)
                    Toggle._settingsExpanded = Expanded

                    local Clipper  = Items["SettingsClipper"].Instance
                    local Sep      = Items["SettingsSeparator"].Instance
                    local Chevron  = Items["SettingsChevron"].Instance
                    local TInfo    = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

                    if Expanded then
                        Sep.Visible = true
                        TweenService:Create(Chevron, TInfo, { Rotation = 180 }):Play()
                        local targetH = _MeasureSettingsHeight()
                        Toggle._settingsHeight = targetH
                        TweenService:Create(Clipper, TInfo, {
                            Size = UDim2New(1, 0, 0, targetH)
                        }):Play()
                        UpdateWrapperSize()
                    else
                        -- Rotate chevron back down
                        TweenService:Create(Chevron, TInfo, { Rotation = 0 }):Play()
                        Toggle._settingsHeight = 0
                        local collapseClipper = TweenService:Create(Clipper, TInfo, {
                            Size = UDim2New(1, 0, 0, 0)
                        })
                        collapseClipper:Play()
                        UpdateWrapperSize()
                        collapseClipper.Completed:Connect(function()
                            if not Library then return end
                            Sep.Visible = false
                        end)
                    end
                end

                -- Auto-resize when child elements are added/removed while panel is open
                SettingsLayout.Instance:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if not Toggle._settingsExpanded or not Library then return end
                    local targetH = _MeasureSettingsHeight()
                    if targetH <= 10 then return end
                    Toggle._settingsHeight = targetH
                    local ResizeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                    TweenService:Create(Items["SettingsClipper"].Instance, ResizeInfo, {
                        Size = UDim2New(1, 0, 0, targetH)
                    }):Play()
                    UpdateWrapperSize()
                end)

                -- ── Child element factories ──────────────────────────────
                -- Each method proxies through the SettingsSection so child
                -- elements inherit the same style and theme as normal elements.

                function Toggle:Toggle(Data)
                    return Library.Sections.Toggle(SettingsSection, Data)
                end

                function Toggle:Slider(Data)
                    return Library.Sections.Slider(SettingsSection, Data)
                end

                function Toggle:Dropdown(Data)
                    return Library.Sections.Dropdown(SettingsSection, Data)
                end

                function Toggle:Input(Data)
                    return Library.Sections.Textbox(SettingsSection, Data)
                end

                function Toggle:Textbox(Data)
                    return Library.Sections.Textbox(SettingsSection, Data)
                end

                function Toggle:Button(Data)
                    return Library.Sections.Button(SettingsSection, Data)
                end

                function Toggle:ColorPicker(Data)
                    return Library.Sections.Colorpicker(SettingsSection, Data)
                end

                function Toggle:Colorpicker(Data)
                    return Library.Sections.Colorpicker(SettingsSection, Data)
                end

                function Toggle:Label(Data)
                    return Library.Sections.Label(SettingsSection, Data)
                end

                function Toggle:Paragraph(Data)
                    return Library.Sections.Paragraph(SettingsSection, Data)
                end

                function Toggle:Keybind(Data)
                    return Library.Sections.Keybind(SettingsSection, Data)
                end

                function Toggle:Listbox(Data)
                    return Library.Sections.Listbox(SettingsSection, Data)
                end

                function Toggle:Divider()
                    return Library.Sections.Divider(SettingsSection, {})
                end

                function Toggle:QuickPresets(Data)
                    return Library.Sections.QuickPresets(SettingsSection, Data)
                end
            end
            -- ─────────────────────────────────────────────────────────────

            function Toggle:Keybind(Data)
                Data = Data or {}

                local Keybind = {
                    Key = Data.Key or Data.key or Enum.KeyCode.RightControl,
                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Mode = "Toggle",
                    Value = "None",
                    Picking = false
                }

                local Holder = GetAddonsHolder()

                local KeyButton = Instances:Create("TextButton", {
                    Parent = Holder.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(141, 141, 150),
                    Text = "[None]",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 1, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 12,
                    LayoutOrder = 1
                })

                function Keybind:Set(Key)
                    if StringFind(tostring(Key), "Enum") then
                        Keybind.Key = tostring(Key)
                        local KeyString = Keys[Keybind.Key] or StringGSub(tostring(Key), "Enum.KeyCode.", "")
                        Keybind.Value = KeyString
                        KeyButton.Instance.Text = "[" .. KeyString .. "]"
                        Library.Flags[Keybind.Flag] = Keybind.Key
                    elseif type(Key) == "string" then
                         -- Handle loading from config (string representation)
                         Keybind.Key = Key
                         local KeyString = Keys[Keybind.Key] or StringGSub(Key, "Enum.KeyCode.", "")
                         Keybind.Value = KeyString
                         KeyButton.Instance.Text = "[" .. KeyString .. "]"
                         Library.Flags[Keybind.Flag] = Keybind.Key
                    end
                    Keybind.Picking = false
                end

                KeyButton:Connect("MouseButton1Click", function()
                    Keybind.Picking = true
                    KeyButton.Instance.Text = "[...]"
                    
                    local InputBegan
                    InputBegan = UserInputService.InputBegan:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.Keyboard then
                            Keybind:Set(Input.KeyCode)
                            InputBegan:Disconnect()
                        elseif Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.MouseButton2 then
                             -- Optionally support mouse buttons
                             Keybind:Set(Input.UserInputType)
                             InputBegan:Disconnect()
                        end
                    end)
                end)

                Library:Connect(UserInputService.InputBegan, function(Input)
                    if not Keybind.Picking and Keybind.Value ~= "None" then
                        if tostring(Input.KeyCode) == Keybind.Key or tostring(Input.UserInputType) == Keybind.Key then
                            Toggle:Set(not Toggle.Value)
                        end
                    end
                end)

                if Data.Key then
                    Keybind:Set(Data.Key)
                end
                
                Library.SetFlags[Keybind.Flag] = function(Value)
                    Keybind:Set(Value)
                end

                return Toggle
            end

            local SettingsItem = { }

            function Toggle:Settings(Size)
                local Settings = {
                    IsOpen = false,
                    Name = "",
                    Items = { },
                    IsSettings = true,
                    Elements = { } 
                }
                Toggle.Settings = Settings

                SettingsItem = { } do 
                    SettingsItem["Settings"] = Instances:Create("Frame", {
                        Parent = Library.UnusedHolder.Instance,
                        Name = "\0",
                        Visible = false,
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        Position = UDim2New(0.8949604630470276, 0, 0.2945185601711273, 0),
                        Size = UDim2New(0, 245, 0, 159),
                        ZIndex = 2,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = FromRGB(21, 21, 24)
                    })  SettingsItem["Settings"]:AddToTheme({BackgroundColor3 = "Background"})

                    Instances:Create("UICorner", {
                        Parent = SettingsItem["Settings"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 6)
                    })                    

                    local Holder = GetAddonsHolder()
                    SettingsItem["SettingsIcon"] = Instances:Create("ImageLabel", {
                        Parent = Holder.Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(141, 141, 150),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 14, 0, 14),
                        AnchorPoint = Vector2New(0, 0.5),
                        Image = "rbxassetid://101500482366184",
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 0, 0.5, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        LayoutOrder = 2
                    })  Items["SettingsIcon"] = SettingsItem["SettingsIcon"]

                    SettingsItem["Content"] = Instances:Create("ScrollingFrame", {
                        Parent = SettingsItem["Settings"].Instance,
                        Name = "\0",
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        Selectable = false,
                        Size = UDim2New(1, -8, 1, -46),
                        Position = UDim2New(0, 4, 0, 4),
                        ScrollBarThickness = 2,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        CanvasSize = UDim2New(0, 0, 0, 0)
                    })  SettingsItem["Content"]:AddToTheme({ScrollBarImageColor3 = "Accent"})
                    
                    Instances:Create("UIListLayout", {
                        Parent = SettingsItem["Content"].Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 4),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                    
                    Instances:Create("UIPadding", {
                        Parent = SettingsItem["Content"].Instance,
                        Name = "\0",
                        PaddingTop = UDimNew(0, 4),
                        PaddingBottom = UDimNew(0, 4),
                        PaddingRight = UDimNew(0, 4),
                        PaddingLeft = UDimNew(0, 4)
                    })

                    SettingsItem["Button"] = Instances:Create("TextButton", {
                        Parent = SettingsItem["Settings"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, -16, 0, 32),
                        ZIndex = 2,
                        AnchorPoint = Vector2New(0, 1),
                        Position = UDim2New(0, 8, 1, -8),
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(27, 26, 29)
                    })  SettingsItem["Button"]:AddToTheme({BackgroundColor3 = "Element"})
    
                    SettingsItem["Accent"] = Instances:Create("Frame", {
                        Parent = SettingsItem["Button"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0)
                    })  --SettingsItem["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})
    
                    SettingsItem["Gradient"] = Instances:Create("UIGradient", {
                        Parent = SettingsItem["Accent"].Instance,
                        Name = "\0",
                        Enabled = true,
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                    })  SettingsItem["Gradient"]:AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                    end})
    
                    Instances:Create("UICorner", {
                        Parent = SettingsItem["Accent"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })
                    
                    Instances:Create("UICorner", {
                        Parent = SettingsItem["Button"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })
                    
                    SettingsItem["Text"] = Instances:Create("TextLabel", {
                        Parent = SettingsItem["Button"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(240, 240, 240),
                        TextTransparency = 0.30000001192092896,
                        Text = "Close",
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2New(0, 0, 0, 15),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  SettingsItem["Text"]:AddToTheme({TextColor3 = "Text"})   

                    SettingsItem["Button"]:OnHover(function()
                        SettingsItem["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 0})
                    end)
    
                    SettingsItem["Button"]:OnHoverLeave(function()
                        SettingsItem["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1})
                    end)
                end

                local RenderStepped 
                local Debounce = false

                function Settings:SetOpen(Bool)
                    if Debounce then 
                        return
                    end
    
                    Settings.IsOpen = Bool
    
                    Debounce = true 
    
                    if Settings.IsOpen then 
                        task.spawn(function()
                            for Index, Value in Settings.Elements do
                                Value:RefreshPosition(true)
                                task.wait(0.03)
                            end
                        end)

                        SettingsItem["Settings"].Instance.Visible = true
                        SettingsItem["Settings"].Instance.Parent = Library.Holder.Instance
                        
                        RenderStepped = RunService.RenderStepped:Connect(function()
                            SettingsItem["Settings"].Instance.Position = UDim2New(
                                0, Items["Toggle"].Instance.AbsolutePosition.X + Items["Toggle"].Instance.AbsoluteSize.X / 1.9 + 15, 
                                0, Items["Toggle"].Instance.AbsolutePosition.Y + Items["Toggle"].Instance.AbsoluteSize.Y + Size / 1.9)
                            SettingsItem["Settings"].Instance.Size = UDim2New(0, 245, 0, Size)
                        end)
    
                        for Index, Value in Library.OpenFrames do 
                            if Value ~= Settings and type(Value) == "table" and Value.SetOpen then 
                                Value:SetOpen(false)
                            end
                        end
    
                        Library.OpenFrames[Settings] = Settings 
                    else
                        for Index, Value in Settings.Elements do
                            Value:RefreshPosition(false)
                        end

                        if Library.OpenFrames[Settings] then 
                            Library.OpenFrames[Settings] = nil
                        end
    
                        if RenderStepped then 
                            RenderStepped:Disconnect()
                            RenderStepped = nil
                        end
                    end
    
                    local Descendants = SettingsItem["Settings"].Instance:GetDescendants()
                    TableInsert(Descendants, SettingsItem["Settings"].Instance)
    
                    local NewTween
    
                    for Index, Value in Descendants do 
                        local TransparencyProperty = Tween:GetProperty(Value)
    
                        if not TransparencyProperty then
                            continue 
                        end
    
                        if not Value.ClassName:find("UI") then 
                            Value.ZIndex = Settings.IsOpen and 7 or 1
                        end
    
                        if type(TransparencyProperty) == "table" then 
                            for _, Property in TransparencyProperty do 
                                NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                            end
                        else
                            NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                        end
                    end
                    
                    NewTween.Tween.Completed:Connect(function()
                        if not Library then return end
                        Debounce = false 
                        SettingsItem["Settings"].Instance.Visible = Settings.IsOpen
                        task.wait(0.2)
                        if not Library then return end
                        SettingsItem["Settings"].Instance.Parent = not Settings.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                    end)
                end

                SettingsItem["Button"]:Connect("MouseButton1Click", function()
                    Settings:SetOpen(false)
                end)

                SettingsItem["SettingsIcon"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
                        Settings:SetOpen(not Settings.IsOpen)
                    end
                end)

                Library:Connect(UserInputService.InputBegan, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
                        if Library:IsMouseOverFrame(SettingsItem["Settings"]) then
                            return 
                        end

                        Settings:SetOpen(false)
                    end
                end)

                Settings.Items = SettingsItem

                setmetatable(Settings, Library.Sections)
                return Settings
            end

            function Toggle:SetVisibility(Bool)
                Items["Wrapper"].Instance.Visible = Bool 
            end

            function Toggle:Colorpicker(Data)
                Data = Data or {}

                local CP = {
                    Window   = Toggle.Window,
                    Page     = Toggle.Page,
                    Section  = Toggle.Section,
                    Flag     = Data.Flag     or Data.flag     or Library:NextFlag(),
                    Default  = Data.Default  or Data.default  or Color3.fromRGB(255, 255, 255),
                    Callback = Data.Callback or Data.callback or function() end,
                    Alpha    = Data.Alpha    or Data.alpha    or false,
                }

                if not Items["InlineCP"] then
                    Items["InlineCP"] = Instances:Create("Frame", {
                        Parent              = Items["Toggle"].Instance,
                        Name                = "\0",
                        Size                = UDim2New(0, 20, 0, 20),
                        AnchorPoint         = Vector2New(1, 0.5),
                        Position            = UDim2New(1, -2, 0.5, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel     = 0,
                        ClipsDescendants    = true,
                        ZIndex              = 2,
                        BackgroundColor3    = FromRGB(0, 0, 0),
                    })
                end

                local DummyParent2 = Instances:Create("Frame", {
                    Parent              = Library.UnusedHolder.Instance,
                    Name                = "\0",
                    Size                = UDim2New(0, 1, 0, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel     = 0,
                    Visible             = false,
                    BackgroundColor3    = FromRGB(0, 0, 0),
                })

                local NewColorpicker = Library:CreateColorpicker({
                    Parent   = Items["InlineCP"],
                    Parent2  = DummyParent2,
                    Page     = CP.Page,
                    Section  = CP.Section,
                    Flag     = CP.Flag,
                    Default  = CP.Default,
                    Callback = CP.Callback,
                    Alpha    = CP.Alpha,
                })

                local cpBtn = Items["InlineCP"].Instance:FindFirstChildWhichIsA("TextButton")
                if cpBtn then
                    cpBtn.Position = UDim2New(0, 0, 0.5, 0)
                end

                Items["Text"].Instance.AutomaticSize = Enum.AutomaticSize.None
                Items["Text"].Instance.Size = UDim2New(1, -58, 0, 15)

                return NewColorpicker
            end


            function Toggle:RefreshPosition(Bool)
                local _IndicatorSize = IsMobile and 18 or 24
                local _TextXOffset   = _IndicatorSize + 4
                local IndicatorAnchorY = Toggle.Description ~= "" and 0 or 0.5
                local IndicatorPositionY = Toggle.Description ~= "" and 1 or -math.floor(_IndicatorSize / 2)
                if Bool then 
                    Items["Indicator"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, IndicatorAnchorY, IndicatorPositionY)})
                    Items["TextRow"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, _TextXOffset, 0, 0)})
                    if Items["Description"] then
                        Items["Description"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, _TextXOffset, 0, 16)})
                    end
                else
                    Items["Indicator"].Instance.Position = UDim2New(0, 30, IndicatorAnchorY, IndicatorPositionY)
                    Items["TextRow"].Instance.Position = UDim2New(0, 30 + _TextXOffset, 0, 0)
                    if Items["Description"] then
                        Items["Description"].Instance.Position = UDim2New(0, 30 + _TextXOffset, 0, 16)
                    end
                end 
            end

            Items["Toggle"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
                    if Items["SettingsIcon"] and Library:IsMouseOverFrame(Items["SettingsIcon"]) then
                        return 
                    end

                    if Toggle.ParentToggle and not Toggle.ParentToggle.Value then
                        return
                    end
                    
                    Toggle:Set(not Toggle.Value)
                end
            end)

            -- ── Timer feature ──────────────────────────────────────────────
            local timerEnabled   = Data.Timer       or Data.timer       or false
            local timerTime      = Data.Time        or Data.time        or 60
            local timerSuffix    = Data.TimerSuffix or Data.timerSuffix or " s"
            local timerThread    = nil
            local timerRemaining = timerTime

            if timerEnabled then
                -- Single text label that sits right-aligned on its own row below the toggle
                local TimerRow = Instances:Create("Frame", {
                    Parent           = Toggle.HasSettings
                        and Items["Wrapper"].Instance
                        or  Toggle.Section.Items["Content"].Instance,
                    Name             = "\0",
                    BackgroundTransparency = 1,
                    BorderSizePixel  = 0,
                    Size             = UDim2New(1, 0, 0, 14),
                    ZIndex           = 2,
                    Visible          = true,
                })

                local TimerLabel = Instances:Create("TextLabel", {
                    Parent              = TimerRow.Instance,
                    Name                = "\0",
                    FontFace            = Library.Font,
                    Text                = "[ Waiting for enable... ]",
                    TextColor3          = FromRGB(100, 97, 120),
                    TextTransparency    = 0,
                    TextSize            = 11,
                    TextXAlignment      = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    BorderSizePixel     = 0,
                    AnchorPoint         = Vector2New(0, 0),
                    Position            = UDim2New(0, 33, 0, 0),
                    Size                = UDim2New(1, -33, 0, 13),
                    ZIndex              = 3,
                })

                local function startTimer()
                    if timerThread then task.cancel(timerThread) end
                    timerRemaining = timerTime
                    timerThread = task.spawn(function()
                        local step = 0.05
                        while Library and Toggle.Value do
                            timerRemaining = timerRemaining - step
                            if timerRemaining <= 0 then
                                timerRemaining = timerTime
                                if Toggle.TimerCallback then
                                    Library:SafeCall(Toggle.TimerCallback)
                                end
                            end
                            TimerLabel.Instance.Text       = "[ " .. string.format("%.2f", timerRemaining) .. timerSuffix .. " ]"
                            TimerLabel.Instance.TextColor3 = Library.Theme.Accent
                            task.wait(step)
                        end
                    end)
                end

                local function stopTimer()
                    if timerThread then task.cancel(timerThread) timerThread = nil end
                    timerRemaining = timerTime
                    TimerLabel.Instance.Text       = "[ Waiting for enable... ]"
                    TimerLabel.Instance.TextColor3 = FromRGB(100, 97, 120)
                end

                local _origSet = Toggle.Set
                function Toggle:Set(Value, Instant)
                    _origSet(self, Value, Instant)
                    if Value then
                        startTimer()
                    else
                        stopTimer()
                    end
                end

                function Toggle:ResetTimer()
                    timerRemaining = timerTime
                end

                function Toggle:SetTime(newTime)
                    timerTime = newTime
                    timerRemaining = newTime
                end

                function Toggle:OnTimer(callback)
                    Toggle.TimerCallback = callback
                end

                function Toggle:GetRemaining()
                    return timerRemaining
                end
            end
            -- ── End Timer feature ──────────────────────────────────────────

            Toggle:Set(Toggle.Default, true)

            Library.SetFlags[Toggle.Flag] = function(Value)
                Toggle:Set(Value)
            end

            if Toggle.Section.Page and Toggle.Section.Page.Active then
                Toggle:RefreshPosition(true)
            end

            Toggle.Section.Elements[#Toggle.Section.Elements+1] = Toggle

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Toggle"].Instance)
            end

            return Toggle 
        end

        Library.Sections.Button = function(self, Data)
            Data = Data or { }

            local Button = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Button",
                Icon = Data.Icon or Data.icon or nil,
                Callback = Data.Callback or Data.callback or function() end
            }

            local Items = { } do 
                Items["Button"] = Instances:Create("TextButton", {
                    Parent = Button.Section.Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 32),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Button"]:AddToTheme({BackgroundColor3 = "Element"})

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0)
                })  --Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Button.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})          
                
                if Button.Icon then 
                    local ButtonIcon = Library:GetCustomIcon(Button.Icon)
                    Items["Icon"] = Instances:Create("ImageLabel", {
                        Parent = Items["Text"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(240, 240, 240),
                        ImageTransparency = 0.30000001192092896,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 18, 0, 18),
                        AnchorPoint = Vector2New(1, 0.5),
                        Image = ButtonIcon and ButtonIcon.Url or "",
                        ImageRectOffset = ButtonIcon and ButtonIcon.ImageRectOffset or Vector2New(0, 0),
                        ImageRectSize = ButtonIcon and ButtonIcon.ImageRectSize or Vector2New(0, 0),
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, -8, 0.5, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["Icon"]:AddToTheme({ImageColor3 = "Text"})
                end                    

                Items["Button"]:OnHover(function()
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 0})
                end)

                Items["Button"]:OnHoverLeave(function()
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1})
                end)
            end 

            --Button.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Button.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            function Button:SetVisibility(Bool)
                Items["Button"].Instance.Visible = Bool
            end

            function Button:Press()
                Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Accent"})
                Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})

                Items["Text"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0), TextTransparency = 0})

                if Button.Icon then 
                    Items["Icon"]:Tween(nil, {ImageColor3 = FromRGB(0, 0, 0), ImageTransparency = 0})
                end

                task.wait(0.2)

                Library:SafeCall(Button.Callback)
                Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Element"})
                Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})

                Items["Text"]:Tween(nil, {TextColor3 = Library.Theme.Text, TextTransparency = 0.3})

                if Button.Icon then 
                    Items["Icon"]:Tween(nil, {ImageColor3 = Library.Theme.Text, ImageTransparency = 0.3})
                end
            end

            Items["Button"]:Connect("MouseButton1Click", function()
                Button:Press()
            end)

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Button"].Instance)
            end

            return Button
        end

        Library.Sections.Slider = function(self, Data)
            Data = Data or { }

            local Slider = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Slider",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Min = Data.Min or Data.min or 0,
                Default = Data.Default or Data.default or 0,
                Max = Data.Max or Data.max or 100,
                Suffix = Data.Suffix or Data.suffix or "",
                Decimals = Data.Decimals or Data.decimals or 1,
                Callback = Data.Callback or Data.callback or function() end,

                Value = 0,
                Sliding = false
            }

            local Items = { } do 
                Items["Slider"] = Instances:Create("Frame", {
                    Parent = Slider.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 35),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
 
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Slider.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["RealSlider"] = Instances:Create("TextButton", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 1),
                    BorderSizePixel = 0,
                    Position = UDim2New(0, 20, 1, -3),
                    Size = UDim2New(1, -40, 0, 7),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["RealSlider"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0"
                })

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    Size = UDim2New(0.5, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0"
                })

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 16, 0, 12),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://117786983271442",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 5, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Rotation = -102,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(166, 166, 166))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["Plus"] = Instances:Create("TextButton", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "+",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 20, 0, 20),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0.5, -3),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Plus"]:AddToTheme({TextColor3 = "Text"})

                Items["Minus"] = Instances:Create("TextButton", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "-",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    Size = UDim2New(0, 20, 0, 20),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, -2, 0.5, -2),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Minus"]:AddToTheme({TextColor3 = "Text"})

                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "50%",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Value"]:AddToTheme({TextColor3 = "Text"})

                Items["RealSlider"]:OnHover(function()
                    Items["Icon"]:Tween(TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 18, 0, 14)})
                end)

                Items["RealSlider"]:OnHoverLeave(function()
                    Items["Icon"]:Tween(TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 16, 0, 12)})
                end)
            end

            --Slider.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Slider.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            --Items["Value"].Instance.TextTransparency = 1
            Items["RealSlider"].Instance.Position = UDim2New(0, 30, 1, -3)
            Items["Text"].Instance.Position = UDim2New(0, 30, 0, 0)

            -- ── Click-to-edit on value label ─────────────────────────────────
            local editBox = Instances:Create("TextBox", {
                Parent              = Items["Slider"].Instance,
                Name                = "\0",
                FontFace            = Library.Font,
                Text                = "",
                PlaceholderText     = "",
                PlaceholderColor3   = FromRGB(100, 97, 120),
                TextColor3          = Library.Theme.Accent,
                TextSize            = 14,
                TextXAlignment      = Enum.TextXAlignment.Right,
                BackgroundColor3    = Library.Theme.Element,
                BackgroundTransparency = 0,
                BorderSizePixel     = 0,
                AnchorPoint         = Vector2New(1, 0),
                Position            = UDim2New(1, 0, 0, 0),
                Size                = UDim2New(0, 52, 0, 15),
                ZIndex              = 5,
                Visible             = false,
                ClearTextOnFocus    = true,
            })
            editBox:AddToTheme({TextColor3 = "Accent", BackgroundColor3 = "Element"})
            Instances:Create("UICorner", { Parent = editBox.Instance, CornerRadius = UDimNew(0, 3) })

            local editActive = false

            local function openEdit()
                if editActive then return end
                editActive = true
                local places = math.max(0, math.floor(Slider.Decimals + 0.5))
                local displayStr = places == 0 and tostring(math.floor(Slider.Value + 0.5))
                               or StringFormat("%." .. places .. "f", Slider.Value)
                editBox.Instance.Text = displayStr
                Items["Value"].Instance.Visible = false
                editBox.Instance.Visible = true
                editBox.Instance:CaptureFocus()
            end

            local function closeEdit(commit)
                if not editActive then return end
                editActive = false
                editBox.Instance.Visible = false
                Items["Value"].Instance.Visible = true
                if commit then
                    local num = tonumber(editBox.Instance.Text)
                    if num then
                        Slider:Set(num)
                    end
                end
            end

            -- Click on the value label to open edit (handled by ValClickBtn overlay)
            local ValClickBtn = Instances:Create("TextButton", {
                Parent              = Items["Slider"].Instance,
                Name                = "\0",
                Text                = "",
                BackgroundTransparency = 1,
                BorderSizePixel     = 0,
                AnchorPoint         = Vector2New(1, 0),
                Position            = UDim2New(1, 0, 0, 0),
                Size                = UDim2New(0, 52, 0, 15),
                ZIndex              = 4,
                AutoButtonColor     = false,
            })
            ValClickBtn:Connect("MouseButton1Click", openEdit)

            editBox.Instance.FocusLost:Connect(function(enterPressed)
                closeEdit(true)
            end)

            UserInputService.InputBegan:Connect(function(input)
                if editActive and input.KeyCode == Enum.KeyCode.Escape then
                    closeEdit(false)
                end
            end)

            function Slider:Get()
                return Slider.Value 
            end

            function Slider:SetVisibility(Bool)
                Items["Slider"].Instance.Visible = Bool
            end

            function Slider:RefreshPosition(Bool)
                if Bool then 
                    Items["RealSlider"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 1, -3)})
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                   -- Items["Value"].Instance.TextTransparency = 0.3
                else
                    Items["RealSlider"].Instance.Position = UDim2New(0, 30, 1, -3)
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0, 0)
                   -- Items["Value"].Instance.TextTransparency = 1
                end
            end

            function Slider:Set(Value)
                local places = math.max(0, math.floor(Slider.Decimals + 0.5))
                local step    = places == 0 and 1 or (10 ^ -places)
                Slider.Value  = Library:Round(MathClamp(Value, Slider.Min, Slider.Max), step)
                Library.Flags[Slider.Flag] = Slider.Value

                local displayValue
                if places == 0 then
                    displayValue = tostring(math.floor(Slider.Value + 0.5))
                else
                    displayValue = StringFormat("%." .. places .. "f", Slider.Value)
                end

                local fillPct = math.clamp((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
                Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New(fillPct, 0, 1, 0)})
                Items["Value"].Instance.Text = displayValue .. Slider.Suffix

                if fillPct >= 1 then
                    Items["Icon"].Instance.Position = UDim2New(1, -12, 0.5, 0)
                elseif fillPct <= 0 then
                    Items["Icon"].Instance.Position = UDim2New(0, 5, 0.5, 0)
                else
                    Items["Icon"].Instance.Position = UDim2New(1, 5, 0.5, 0)
                end

                if Slider.Callback then
                    Library:SafeCall(Slider.Callback, Slider.Value)
                end
            end

            local function _getStep()
                local places = math.max(0, math.floor(Slider.Decimals + 0.5))
                return places == 0 and 1 or (10 ^ -places)
            end

            Items["Plus"]:Connect("MouseButton1Click", function()
                Slider:Set(Slider.Value + _getStep())
            end)

            Items["Minus"]:Connect("MouseButton1Click", function()
                Slider:Set(Slider.Value - _getStep())
            end)

            local InputChanged 
            
            Items["RealSlider"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Slider.Sliding = true

                    local SizeX = (Input.Position.X - Items["RealSlider"].Instance.AbsolutePosition.X) / Items["RealSlider"].Instance.AbsoluteSize.X
                    local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                    Slider:Set(Value)

                    if InputChanged then
                        return
                    end

                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Slider.Sliding = false

                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Slider.Sliding then
                        local SizeX = (Input.Position.X - Items["RealSlider"].Instance.AbsolutePosition.X) / Items["RealSlider"].Instance.AbsoluteSize.X
                        local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                        Slider:Set(Value)
                    end
                end
            end)

            if Slider.Default then
                Slider:Set(Slider.Default)
            end

            Library.SetFlags[Slider.Flag] = function(Value)
                Slider:Set(Value)
            end

            if Slider.Section.Page and Slider.Section.Page.Active then
                Slider:RefreshPosition(true)
            end

            Slider.Section.Elements[#Slider.Section.Elements+1] = Slider

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Slider"].Instance)
            end

            return Slider 
        end

        Library.Sections.Dropdown = function(self, Data)
            Data = Data or { }

            local Dropdown = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Dropdown",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Items = Data.Items or Data.items or { "One", "Two", "Three" },
                Default = Data.Default or Data.default or nil,
                Callback = Data.Callback or Data.callback or function() end,
                Size = Data.Size or Data.size or 125,
                OptionHolderSize = Data.OptionHolderSize or Data.optionholder or 125,
                Multi = Data.Multi or Data.multi or false,
                Priority = Data.Priority or Data.priority or false,
                PriorityMap = Data.PriorityMap or Data.priorityMap or {},
                MaxOptionWidth = 0,

                Value = { },
                Options = { },
                OptionsWithIndexes = { },
                IsOpen = false
            }

            local Items = { } do 
                Items["Dropdown"] = Instances:Create("Frame", {
                    Parent = Dropdown.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 25),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Dropdown.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
                
                Items["RealDropdown"] = Instances:Create("TextButton", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    Size = UDim2New(0, Dropdown.Size or 125, 0, 25),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, 0, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["RealDropdown"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })
                
                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "-",
                    Size = UDim2New(1, -40, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 10, 0.5, -1),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Value"]:AddToTheme({TextColor3 = "Text"})
                
                Items["Liner"] = Instances:Create("Frame", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, -25, 0, 0),
                    Size = UDim2New(0, 2, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(34, 32, 36)
                })  Items["Liner"]:AddToTheme({BackgroundColor3 = "Outline"})
                
                Items["ArrowIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(141, 141, 150),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 16, 0, 8),
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://123317177279443",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -5, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["ArrowIcon"].Instance,
                    Name = "\0",
                    Enabled = false,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(131, 131, 131)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["OptionHolder"] = Instances:Create("TextButton", {
                    Parent = Library.UnusedHolder.Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    Visible = false,
                    Position = UDim2New(0, 897, 0, 101),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 159, 0, 87),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["OptionHolder"]:AddToTheme({BackgroundColor3 = "Background"})
                 
                Instances:Create("UIStroke", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 33, 38),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Outline"})
                
                Instances:Create("UICorner", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })
                
                Items["Search"] = Instances:Create("TextBox", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    CursorPosition = -1,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Size = UDim2New(1, -16, 0, 30),
                    Position = UDim2New(0, 8, 0, 8),
                    BorderSizePixel = 0,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = "Search..",
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Search"]:AddToTheme({TextColor3 = "Text", BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 4),
                    PaddingLeft = UDimNew(0, 8)
                })

                Items["Holder"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, -16, 1, -50),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 0, 42),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })  Items["Holder"]:AddToTheme({ScrollBarImageColor3 = "Accent"})
                
                Instances:Create("UIListLayout", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })                
            end

            --ropdown.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Dropdown.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            Items["Text"].Instance.Position = UDim2New(0, 30, 0.5, 0)
            Items["RealDropdown"].Instance.Position = UDim2New(1, 30, 0, 0)

            function Dropdown:Get()
                return Dropdown.Value
            end

            function Dropdown:SetVisibility(Bool)
                Items["Dropdown"].Instance.Visible = Bool
            end

            function Dropdown:RefreshPosition(Bool)
                if Bool then
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                    Items["RealDropdown"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0, 0)})
                else
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0.5, 0)
                    Items["RealDropdown"].Instance.Position = UDim2New(1, 30, 0, 0)
                end
            end

            Items["RealDropdown"]:OnHover(function()
                if Dropdown.IsOpen then
                    return 
                end

                Items["ArrowIcon"]:Tween(nil, {ImageColor3 = FromRGB(255, 255, 255)})
                Items["Gradient"].Instance.Enabled = true
            end)

            Items["RealDropdown"]:OnHoverLeave(function()
                if Dropdown.IsOpen then
                    return 
                end

                Items["ArrowIcon"]:Tween(nil, {ImageColor3 = FromRGB(141, 141, 150)})
                Items["Gradient"].Instance.Enabled = false
            end)

            local RenderStepped 

            function Dropdown:SetOpen(Bool)
                if Debounce then 
                    return
                end

                Dropdown.IsOpen = Bool

                Debounce = true 

                if Dropdown.IsOpen then 
                    Items["OptionHolder"].Instance.Visible = true
                    Items["OptionHolder"].Instance.Parent = Library.Holder.Instance

                    Items["ArrowIcon"]:Tween(nil, {Rotation = 180, ImageColor3 = FromRGB(255, 255, 255)})
                    Items["Gradient"].Instance.Enabled = true
                    
                    Library:Thread(function()
                        for Index, Value in Dropdown.OptionsWithIndexes do 
                            task.spawn(function()
                                Value:RefreshPosition(true)
                            end)
                            task.wait(0.05)
                        end
                    end)
                    
                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["OptionHolder"].Instance.Position = UDim2New(0, Items["RealDropdown"].Instance.AbsolutePosition.X, 0, Items["RealDropdown"].Instance.AbsolutePosition.Y + Items["RealDropdown"].Instance.AbsoluteSize.Y + 5)

                        local VisibleOptions = 0
                        for _, Option in ipairs(Dropdown.OptionsWithIndexes) do
                            if Option.Button.Instance.Visible then
                                VisibleOptions = VisibleOptions + 1
                            end
                        end

                        local ContentHeight = (VisibleOptions * 24) + 12 + 35
                        local MaxHeight = Dropdown.OptionHolderSize
                        local Height = math.min(ContentHeight, MaxHeight)

                        local BaseWidth = Items["RealDropdown"].Instance.AbsoluteSize.X
                        local ContentWidth = Dropdown.MaxOptionWidth + 50
                        local Width = math.max(BaseWidth, ContentWidth)

                        Items["OptionHolder"].Instance.Size = UDim2New(0, Width, 0, Height)
                    end)

                    for Index, Value in Library.OpenFrames do 
                        if Value ~= Dropdown and not Dropdown.Section.IsSettings and type(Value) == "table" and Value.SetOpen then 
                            Value:SetOpen(false)
                        end
                    end

                    Library.OpenFrames[Dropdown] = Dropdown 
                else
                    if not Dropdown.IsOpen then
                        for Index, Value in Dropdown.OptionsWithIndexes do 
                            task.spawn(function()
                                Value:RefreshPosition(false)
                            end)
                        end
                    end

                    if Library.OpenFrames[Dropdown] then 
                        Library.OpenFrames[Dropdown] = nil
                    end

                    if RenderStepped then 
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end

                    Items["ArrowIcon"]:Tween(nil, {Rotation = 0, ImageColor3 = FromRGB(141, 141, 150)})
                    Items["Gradient"].Instance.Enabled = false
                end

                local Descendants = Items["OptionHolder"].Instance:GetDescendants()
                TableInsert(Descendants, Items["OptionHolder"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue 
                    end

                    if not Value.ClassName:find("UI") then 
                        Value.ZIndex = (Dropdown.IsOpen and Dropdown.Section.IsSettings and 8) or (Dropdown.IsOpen and 3) or 1
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end
                
                NewTween.Tween.Completed:Connect(function()
                    if not Library then return end
                    Debounce = false 
                    Items["OptionHolder"].Instance.Visible = Dropdown.IsOpen
                    task.wait(0.2)
                    if not Library then return end
                    Items["OptionHolder"].Instance.Parent = not Dropdown.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Dropdown:Set(Option)
                if Dropdown.Multi then 
                    if type(Option) ~= "table" then 
                        return
                    end
 
                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Option do
                        local OptionData = Dropdown.Options[Value]
                         
                        if not OptionData then
                            continue
                        end

                        OptionData.Selected = true 
                        OptionData:Toggle("Active")
                    end

                    Items["Value"].Instance.Text = TableConcat(Option, ", ")
                else
                    if not Dropdown.Options[Option] then
                        return
                    end

                    local OptionData = Dropdown.Options[Option]

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Dropdown.Options do
                        if Value ~= OptionData then
                            Value.Selected = false 
                            Value:Toggle("Inactive")
                        else
                            Value.Selected = true 
                            Value:Toggle("Active")
                        end
                    end

                    Items["Value"].Instance.Text = Option
                end

                if Dropdown.Callback then   
                    Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                end
            end

            function Dropdown:Add(Option)
                if not Library then return end
                local OptionButton = Instances:Create("TextButton", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                local OptionAccent = Instances:Create("Frame", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --OptionAccent:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UIGradient", {
                    Parent = OptionAccent.Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Instances:Create("UICorner", {
                    Parent = OptionAccent.Instance,
                    Name = "\0"
                })
                
                local OptionText = Instances:Create("TextLabel", {
                    Parent = OptionAccent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.30000001192092896,
                    Text = Option,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 30, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  OptionText:AddToTheme({TextColor3 = "Text"})

                -- Priority badge (shown when Dropdown.Priority = true)
                if Dropdown.Priority then
                    local priorityNum = Dropdown.PriorityMap[Option]
                    if priorityNum then
                        local badgeColors = {
                            [1] = FromRGB(239, 68, 68),    -- red   #1
                            [2] = FromRGB(249, 115, 22),   -- orange #2
                            [3] = FromRGB(234, 179, 8),    -- yellow #3
                            [4] = FromRGB(34, 197, 94),    -- green  #4
                            [5] = FromRGB(59, 130, 246),   -- blue   #5
                        }
                        local badgeColor = badgeColors[priorityNum] or FromRGB(100, 97, 120)
                        local Badge = Instances:Create("Frame", {
                            Parent = OptionButton.Instance,
                            Name = "\0",
                            AnchorPoint = Vector2New(1, 0.5),
                            Position = UDim2New(1, -4, 0.5, 0),
                            Size = UDim2New(0, 16, 0, 14),
                            BackgroundColor3 = badgeColor,
                            BackgroundTransparency = 0.35,
                            BorderSizePixel = 0,
                            ZIndex = 3,
                        })
                        Instances:Create("UICorner", { Parent = Badge.Instance, CornerRadius = UDimNew(0, 3) })
                        Instances:Create("TextLabel", {
                            Parent = Badge.Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            Text = tostring(priorityNum),
                            TextColor3 = badgeColor,
                            TextSize = 9,
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            Size = UDim2New(1, 0, 1, 0),
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 4,
                        })
                    end
                end
                
                local TextSize = OptionText.Instance.TextBounds
                if TextSize.X > Dropdown.MaxOptionWidth then
                    Dropdown.MaxOptionWidth = TextSize.X
                end

                local OptionData = {
                    Button = OptionButton,
                    Name = Option,
                    OptionText = OptionText,
                    OptionAccent = OptionAccent,
                    Selected = false
                }
                
                function OptionData:Toggle(Value)
                    if Value == "Active" then
                        OptionText:Tween(nil, {TextTransparency = 0, Position = UDim2New(0, 15, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 0})
                    else
                        OptionText:Tween(nil, {TextTransparency = 0.3, Position = UDim2New(0, 0, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                function OptionData:RefreshPosition(Bool)
                    if Bool then 
                        if OptionData.Selected then
                            OptionAccent:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 15, 0.5, 0)})
                        else
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                        end
                    else
                        if OptionData.Selected then
                            OptionAccent.Instance.Position = UDim2New(0, 30, 0.5, 0)
                            OptionText.Instance.Position = UDim2New(0, 45, 0.5, 0)
                        else
                            OptionText.Instance.Position = UDim2New(0, 30, 0.5, 0)
                        end
                    end

                    --if Bool then
                        --OptionAccent:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                    --else
                        --OptionAccent.Instance.Position = UDim2New(0, 30, 0.5, 0)
                    --end
                    
                    --[[
                    if Bool then 
                        if OptionData.Selected then 
                            OptionAccent:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 15, 0.5, 0)})
                        else
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                        end
                    else
                        if OptionData.Selected then
                            OptionAccent.Instance.Position = UDim2New(0, 30, 0.5, 0)
                            OptionText.Instance.Position = UDim2New(0, 45, 0.5, 0)
                        else
                            OptionText.Instance.Position = UDim2New(0, 30, 0.5, 0)
                        end
                    end
                    --]]
                end

                function OptionData:Set()
                    OptionData.Selected = not OptionData.Selected

                    if Dropdown.Multi then 
                        local Index = TableFind(Dropdown.Value, OptionData.Name)

                        if Index then 
                            TableRemove(Dropdown.Value, Index)
                        else
                            TableInsert(Dropdown.Value, OptionData.Name)
                        end

                        OptionData:Toggle(Index and "Inactive" or "Active")

                        Library.Flags[Dropdown.Flag] = Dropdown.Value

                        local TextFormat = #Dropdown.Value > 0 and TableConcat(Dropdown.Value, ", ") or "..."
                        Items["Value"].Instance.Text = TextFormat
                    else
                        if OptionData.Selected then 
                            Dropdown.Value = OptionData.Name
                            Library.Flags[Dropdown.Flag] = OptionData.Name

                            OptionData.Selected = true
                            OptionData:Toggle("Active")

                            for Index, Value in Dropdown.Options do 
                                if Value ~= OptionData then
                                    Value.Selected = false 
                                    Value:Toggle("Inactive")
                                end
                            end

                            Items["Value"].Instance.Text = OptionData.Name
                        else
                            Dropdown.Value = nil
                            Library.Flags[Dropdown.Flag] = nil

                            OptionData.Selected = false
                            OptionData:Toggle("Inactive")

                            Items["Value"].Instance.Text = "..."
                        end
                    end

                    if Dropdown.Callback then
                        Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                    end
                end

                OptionData.Button:Connect("MouseButton1Click", function()
                    OptionData:Set()
                end)

                Dropdown.Options[OptionData.Name] = OptionData
                Dropdown.OptionsWithIndexes[#Dropdown.OptionsWithIndexes+1] = OptionData
                OptionData:RefreshPosition(false)

                if Items["Search"].Instance.Text ~= "" then
                    if not StringFind(StringLower(Option), Library:EscapePattern(StringLower(Items["Search"].Instance.Text))) then
                        OptionButton.Instance.Visible = false
                    end
                end

                return OptionData
            end

            function Dropdown:Remove(Option)
                if Dropdown.Options[Option] then
                    Dropdown.Options[Option].Button:Clean()
                    Dropdown.Options[Option] = nil
                end
            end

            function Dropdown:Refresh(List)
                for Index, Value in Dropdown.Options do 
                    Dropdown:Remove(Value.Name)
                end

                for Index, Value in List do 
                    Dropdown:Add(Value)
                end
            end

            Items["RealDropdown"]:Connect("MouseButton1Click", function()
                Dropdown:SetOpen(not Dropdown.IsOpen)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dropdown.IsOpen then
                        if Library:IsMouseOverFrame(Items["OptionHolder"]) then
                            return
                        end

                        Dropdown:SetOpen(false)
                    end
                end
            end)

            Items["RealDropdown"]:Connect("Changed", function(Property)
                if Property == "AbsolutePosition" and Dropdown.IsOpen then
                    Dropdown.IsOpen = not Library:IsClipped(Items["OptionHolder"].Instance, Dropdown.Section.Items["Section"].Instance.Parent)
                    Items["OptionHolder"].Instance.Visible = Dropdown.IsOpen
                end
            end)

            Library:Connect(Items["Search"].Instance:GetPropertyChangedSignal("Text"), function()
                local InputText = Items["Search"].Instance.Text
                for _, Option in ipairs(Dropdown.OptionsWithIndexes) do
                    if InputText ~= "" then
                        if StringFind(StringLower(Option.Name), Library:EscapePattern(StringLower(InputText))) then
                            Option.Button.Instance.Visible = true
                        else
                            Option.Button.Instance.Visible = false
                        end
                    else
                        Option.Button.Instance.Visible = true
                    end
                end
            end)

            for Index, Value in Dropdown.Items do 
                Dropdown:Add(Value)
            end

            if Dropdown.Default then 
                Dropdown:Set(Dropdown.Default)
            end

            Library.SetFlags[Dropdown.Flag] = function(Value)
                Dropdown:Set(Value)
            end

            if Dropdown.Section.Page and Dropdown.Section.Page.Active then
                Dropdown:RefreshPosition(true)
            end

            Dropdown.Section.Elements[#Dropdown.Section.Elements+1] = Dropdown

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Dropdown"].Instance)
            end

            return Dropdown
        end

        Library.Sections.DropdownAmount = function(self, Data)
            Data = Data or { }

            local Dropdown = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Dropdown Amount",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Items = Data.Items or Data.items or { "One", "Two", "Three" },
                Default = Data.Default or Data.default or nil,
                Callback = Data.Callback or Data.callback or function() end,
                Size = Data.Size or Data.size or 125,
                OptionHolderSize = Data.OptionHolderSize or Data.optionholder or 125,
                MaxOptionWidth = 0,
                IsMulti = Data.IsMulti or Data.ismulti or false,
                DefaultAmount = Data.DefaultAmount or Data.defaultamount or 1,

                Value = { },
                Options = { },
                OptionsWithIndexes = { },
                IsOpen = false
            }

            local Items = { } do
                Items["Dropdown"] = Instances:Create("Frame", {
                    Parent = Dropdown.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 25),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.3,
                    Text = Dropdown.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["RealDropdown"] = Instances:Create("TextButton", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    Size = UDim2New(0, Dropdown.Size or 125, 0, 25),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, 0, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["RealDropdown"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })

                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.3,
                    Text = "-",
                    Size = UDim2New(1, -40, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 10, 0.5, -1),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Value"]:AddToTheme({TextColor3 = "Text"})

                Items["Liner"] = Instances:Create("Frame", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, -25, 0, 0),
                    Size = UDim2New(0, 2, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(34, 32, 36)
                })  Items["Liner"]:AddToTheme({BackgroundColor3 = "Outline"})

                Items["ArrowIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(141, 141, 150),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 16, 0, 8),
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://123317177279443",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -5, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["ArrowIcon"].Instance,
                    Name = "\0",
                    Enabled = false,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(131, 131, 131)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["OptionHolder"] = Instances:Create("TextButton", {
                    Parent = Library.UnusedHolder.Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    Visible = false,
                    Position = UDim2New(0, 897, 0, 101),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 159, 0, 87),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["OptionHolder"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UIStroke", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 33, 38),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Outline"})

                Instances:Create("UICorner", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["Holder"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, -16, 1, -16),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 0, 8),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })  Items["Holder"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

                Instances:Create("UIListLayout", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            Items["Text"].Instance.Position = UDim2New(0, 30, 0.5, 0)
            Items["RealDropdown"].Instance.Position = UDim2New(1, 30, 0, 0)

            function Dropdown:Get()
                return Dropdown.Value
            end

            function Dropdown:SetVisibility(Bool)
                Items["Dropdown"].Instance.Visible = Bool
            end

            function Dropdown:RefreshPosition(Bool)
                if Bool then
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                    Items["RealDropdown"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0, 0)})
                else
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0.5, 0)
                    Items["RealDropdown"].Instance.Position = UDim2New(1, 30, 0, 0)
                end
            end

            Items["RealDropdown"]:OnHover(function()
                if Dropdown.IsOpen then return end
                Items["ArrowIcon"]:Tween(nil, {ImageColor3 = FromRGB(255, 255, 255)})
                Items["Gradient"].Instance.Enabled = true
            end)

            Items["RealDropdown"]:OnHoverLeave(function()
                if Dropdown.IsOpen then return end
                Items["ArrowIcon"]:Tween(nil, {ImageColor3 = FromRGB(141, 141, 150)})
                Items["Gradient"].Instance.Enabled = false
            end)

            local RenderStepped

            function Dropdown:SetOpen(Bool)
                if Debounce then
                    return
                end

                Dropdown.IsOpen = Bool

                Debounce = true

                if Dropdown.IsOpen then
                    Items["OptionHolder"].Instance.Visible = true
                    Items["OptionHolder"].Instance.Parent = Library.Holder.Instance

                    Items["ArrowIcon"]:Tween(nil, {Rotation = 180, ImageColor3 = FromRGB(255, 255, 255)})
                    Items["Gradient"].Instance.Enabled = true

                    Library:Thread(function()
                        for Index, Value in Dropdown.OptionsWithIndexes do
                            task.spawn(function()
                                Value:RefreshPosition(true)
                            end)
                            task.wait(0.05)
                        end
                    end)

                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["OptionHolder"].Instance.Position = UDim2New(0, Items["RealDropdown"].Instance.AbsolutePosition.X, 0, Items["RealDropdown"].Instance.AbsolutePosition.Y + Items["RealDropdown"].Instance.AbsoluteSize.Y + 5)

                        local ContentHeight = (#Dropdown.OptionsWithIndexes * 24) + 12
                        local MaxHeight = Dropdown.OptionHolderSize
                        local Height = math.min(ContentHeight, MaxHeight)

                        local BaseWidth = Items["RealDropdown"].Instance.AbsoluteSize.X * 2
                        local ContentWidth = Dropdown.MaxOptionWidth + 80
                        local Width = math.max(BaseWidth, ContentWidth)

                        Items["OptionHolder"].Instance.Size = UDim2New(0, Width, 0, Height)
                    end)

                    for Index, Value in Library.OpenFrames do
                        if Value ~= Dropdown and not Dropdown.Section.IsSettings and type(Value) == "table" and Value.SetOpen then
                            Value:SetOpen(false)
                        end
                    end
                    Library.OpenFrames[Dropdown] = Dropdown
                else
                    if not Dropdown.IsOpen then
                        for Index, Value in Dropdown.OptionsWithIndexes do
                            task.spawn(function()
                                Value:RefreshPosition(false)
                            end)
                        end
                    end
                    if Library.OpenFrames[Dropdown] then
                        Library.OpenFrames[Dropdown] = nil
                    end
                    if RenderStepped then
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end
                    Items["ArrowIcon"]:Tween(nil, {Rotation = 0, ImageColor3 = FromRGB(141, 141, 150)})
                    Items["Gradient"].Instance.Enabled = false
                end

                local Descendants = Items["OptionHolder"].Instance:GetDescendants()
                TableInsert(Descendants, Items["OptionHolder"].Instance)

                local NewTween
                for Index, Value in Descendants do
                    local TransparencyProperty = Tween:GetProperty(Value)
                    if not TransparencyProperty then continue end
                    if not Value.ClassName:find("UI") then
                        Value.ZIndex = (Dropdown.IsOpen and Dropdown.Section.IsSettings and 8) or (Dropdown.IsOpen and 3) or 1
                    end
                    if type(TransparencyProperty) == "table" then
                        for _, Property in TransparencyProperty do
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                NewTween.Tween.Completed:Connect(function()
                    if not Library then return end
                    Debounce = false
                    Items["OptionHolder"].Instance.Visible = Dropdown.IsOpen
                    task.wait(0.2)
                    if not Library then return end
                    Items["OptionHolder"].Instance.Parent = not Dropdown.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Dropdown:UpdateText()
                local SelectedOptions = {}
                for _, Option in ipairs(Dropdown.OptionsWithIndexes) do
                    if Option.Selected then
                        table.insert(SelectedOptions, Option.Name .. " [" .. Option.Amount .. "]")
                    end
                end
                
                -- Update Value Table
                Dropdown.Value = {}
                for _, Option in ipairs(Dropdown.OptionsWithIndexes) do
                    if Option.Selected then
                        Dropdown.Value[Option.Name] = Option.Amount
                    end
                end
                
                local Text = #SelectedOptions > 0 and table.concat(SelectedOptions, ", ") or "..."
                Items["Value"].Instance.Text = Text
                
                Library.Flags[Dropdown.Flag] = Dropdown.Value
            end

            function Dropdown:Set(Option)
                if type(Option) == "table" then
                     if not Dropdown.IsMulti then
                        for _, Opt in pairs(Dropdown.Options) do
                            Opt.Selected = false
                            Opt:Toggle("Inactive")
                        end
                     end

                     local IsArray = #Option > 0
                     if IsArray then
                         for _, Name in ipairs(Option) do
                             local Opt = Dropdown.Options[Name]
                             if Opt then
                                 Opt.Selected = true
                                 Opt:Toggle("Active")
                                 if not Dropdown.IsMulti then break end
                             end
                         end
                     else
                         for Name, Amount in pairs(Option) do
                             local Opt = Dropdown.Options[Name]
                             if Opt then
                                 Opt.Selected = true
                                 Opt.Amount = Amount
                                 Opt.AmountBox.Instance.Text = tostring(Amount)
                                 Opt:Toggle("Active")
                                 if not Dropdown.IsMulti then break end
                             end
                         end
                     end
                elseif type(Option) == "string" then
                    local Opt = Dropdown.Options[Option]
                    if Opt then
                        if not Dropdown.IsMulti then
                            for _, O in pairs(Dropdown.Options) do
                                if O ~= Opt then
                                    O.Selected = false
                                    O:Toggle("Inactive")
                                end
                            end
                        end
                        Opt.Selected = true
                        Opt:Toggle("Active")
                    end
                end
                Dropdown:UpdateText()

                if Dropdown.Callback then
                     if Dropdown.IsMulti then
                         Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                     else
                         local SelName, SelAmount
                         for N, A in pairs(Dropdown.Value) do
                             SelName = N
                             SelAmount = A
                             break
                         end
                         if SelName then
                             Library:SafeCall(Dropdown.Callback, SelName, SelAmount)
                         end
                     end
                end
            end

            function Dropdown:SetOptions(Option)
                Dropdown:Set(Option)
            end

            function Dropdown:Add(Option)
                local OptionButton = Instances:Create("TextButton", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                local OptionAccent = Instances:Create("Frame", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient", {
                    Parent = OptionAccent.Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Instances:Create("UICorner", {
                    Parent = OptionAccent.Instance,
                    Name = "\0"
                })

                local OptionText = Instances:Create("TextLabel", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.3,
                    Text = Option,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 30, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  OptionText:AddToTheme({TextColor3 = "Text"})

                local TextSize = OptionText.Instance.TextBounds
                if TextSize.X > Dropdown.MaxOptionWidth then
                    Dropdown.MaxOptionWidth = TextSize.X
                end

                local AmountBox = Instances:Create("TextBox", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    Text = tostring(Dropdown.DefaultAmount),
                    PlaceholderText = "#",
                    TextColor3 = FromRGB(255, 255, 255),
                    PlaceholderColor3 = FromRGB(180, 180, 180),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Size = UDim2New(0, 40, 0, 16),
                    Position = UDim2New(1, -10, 0.5, 0),
                    AnchorPoint = Vector2New(1, 0.5),
                    ZIndex = 4,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    BackgroundColor3 = FromRGB(52, 116, 235),
                    ClipsDescendants = true
                })
                
                Instances:Create("UICorner", {
                    Parent = AmountBox.Instance,
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIStroke", {
                    Parent = AmountBox.Instance,
                    Name = "\0",
                    Color = FromRGB(255, 255, 255),
                    Transparency = 0.6,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Thickness = 1
                })

                local OptionData = {
                    Button = OptionButton,
                    Name = Option,
                    OptionText = OptionText,
                    OptionAccent = OptionAccent,
                    AmountBox = AmountBox,
                    Selected = false,
                    Amount = Dropdown.DefaultAmount
                }

                function OptionData:Toggle(Value)
                    if Value == "Active" then
                        OptionText:Tween(nil, {TextTransparency = 0, Position = UDim2New(0, 15, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 0})
                    else
                        OptionText:Tween(nil, {TextTransparency = 0.3, Position = UDim2New(0, 0, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                function OptionData:RefreshPosition(Bool)
                    if Bool then
                        if OptionData.Selected then
                            OptionAccent:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 15, 0.5, 0)})
                        else
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                        end
                    else
                        if OptionData.Selected then
                            OptionAccent.Instance.Position = UDim2New(0, 30, 0.5, 0)
                            OptionText.Instance.Position = UDim2New(0, 45, 0.5, 0)
                        else
                            OptionText.Instance.Position = UDim2New(0, 30, 0.5, 0)
                        end
                    end
                end

                function OptionData:Set()
                    if Dropdown.IsMulti then
                        OptionData.Selected = not OptionData.Selected
                        OptionData:Toggle(OptionData.Selected and "Active" or "Inactive")
                    else
                        if OptionData.Selected then return end
                        for _, Opt in pairs(Dropdown.Options) do
                            if Opt ~= OptionData and Opt.Selected then
                                Opt.Selected = false
                                Opt:Toggle("Inactive")
                            end
                        end
                        OptionData.Selected = true
                        OptionData:Toggle("Active")
                    end
                    
                    Dropdown:UpdateText()

                    if Dropdown.Callback then
                        if Dropdown.IsMulti then
                             Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                        else
                             Library:SafeCall(Dropdown.Callback, OptionData.Name, OptionData.Amount)
                        end
                    end
                end

                OptionData.Button:Connect("MouseButton1Click", function()
                    OptionData:Set()
                end)

                OptionData.AmountBox:Connect("FocusLost", function(Enter)
                    local Num = tonumber(OptionData.AmountBox.Instance.Text)
                    if Num then
                        OptionData.Amount = Num
                    else
                        OptionData.AmountBox.Instance.Text = tostring(OptionData.Amount)
                    end
                    Dropdown:UpdateText()

                    if Dropdown.Callback then
                        if Dropdown.IsMulti then
                             Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                        else
                             if OptionData.Selected then
                                 Library:SafeCall(Dropdown.Callback, OptionData.Name, OptionData.Amount)
                             end
                        end
                    end
                end)

                Dropdown.Options[OptionData.Name] = OptionData
                Dropdown.OptionsWithIndexes[#Dropdown.OptionsWithIndexes+1] = OptionData
                OptionData:RefreshPosition(false)

                return OptionData
            end

            function Dropdown:Remove(Option)
                if Dropdown.Options[Option] then
                    Dropdown.Options[Option].Button:Clean()
                    Dropdown.Options[Option] = nil
                end
            end

            function Dropdown:Refresh(List)
                for Index, Value in Dropdown.Options do
                    Dropdown:Remove(Value.Name)
                end
                Dropdown.OptionsWithIndexes = {}

                for Index, Value in List do
                    Dropdown:Add(Value)
                end
            end

            Items["RealDropdown"]:Connect("MouseButton1Click", function()
                Dropdown:SetOpen(not Dropdown.IsOpen)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dropdown.IsOpen then
                        if Library:IsMouseOverFrame(Items["OptionHolder"]) then return end
                        Dropdown:SetOpen(false)
                    end
                end
            end)

            Items["RealDropdown"]:Connect("Changed", function(Property)
                if Property == "AbsolutePosition" and Dropdown.IsOpen then
                    Dropdown.IsOpen = not Library:IsClipped(Items["OptionHolder"].Instance, Dropdown.Section.Items["Section"].Instance.Parent)
                    Items["OptionHolder"].Instance.Visible = Dropdown.IsOpen
                end
            end)

            for Index, Value in Dropdown.Items do
                Dropdown:Add(Value)
            end

            if Dropdown.Default then
                Dropdown:Set(Dropdown.Default)
            end

            Library.SetFlags[Dropdown.Flag] = function(Value)
                Dropdown:Set(Value)
            end

            if Dropdown.Section.Page and Dropdown.Section.Page.Active then
                Dropdown:RefreshPosition(true)
            end

            Dropdown.Section.Elements[#Dropdown.Section.Elements+1] = Dropdown

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Dropdown"].Instance)
            end

            return Dropdown
        end

        Library.Sections.PriorityDropdown = function(self, Data)
            Data = Data or { }

            local Dropdown = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Priority Dropdown",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Items = Data.Items or Data.items or { "One", "Two", "Three" },
                Default = Data.Default or Data.default or nil,
                Callback = Data.Callback or Data.callback or function() end,
                Size = Data.Size or Data.size or 125,
                OptionHolderSize = Data.OptionHolderSize or Data.optionholder or 125,
                MaxOptionWidth = 0,

                Value = { },
                Options = { },
                OptionsWithIndexes = { },
                IsOpen = false
            }

            local Items = { } do
                Items["Dropdown"] = Instances:Create("Frame", {
                    Parent = Dropdown.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 25),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.3,
                    Text = Dropdown.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["RealDropdown"] = Instances:Create("TextButton", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    Size = UDim2New(0, Dropdown.Size or 125, 0, 25),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, 0, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["RealDropdown"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })

                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.3,
                    Text = "-",
                    Size = UDim2New(1, -40, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 10, 0.5, -1),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Value"]:AddToTheme({TextColor3 = "Text"})

                Items["Liner"] = Instances:Create("Frame", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, -25, 0, 0),
                    Size = UDim2New(0, 2, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(34, 32, 36)
                })  Items["Liner"]:AddToTheme({BackgroundColor3 = "Outline"})

                Items["ArrowIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(141, 141, 150),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 16, 0, 8),
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://123317177279443",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -5, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["ArrowIcon"].Instance,
                    Name = "\0",
                    Enabled = false,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(131, 131, 131)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["OptionHolder"] = Instances:Create("TextButton", {
                    Parent = Library.UnusedHolder.Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    Visible = false,
                    Position = UDim2New(0, 897, 0, 101),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 159, 0, 87),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["OptionHolder"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UIStroke", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 33, 38),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Outline"})

                Instances:Create("UICorner", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["Holder"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, -16, 1, -16),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 0, 8),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })  Items["Holder"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

                Instances:Create("UIListLayout", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            Items["Text"].Instance.Position = UDim2New(0, 30, 0.5, 0)
            Items["RealDropdown"].Instance.Position = UDim2New(1, 30, 0, 0)

            function Dropdown:Get()
                return Dropdown.Value
            end

            function Dropdown:SetVisibility(Bool)
                Items["Dropdown"].Instance.Visible = Bool
            end

            function Dropdown:RefreshPosition(Bool)
                if Bool then
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                    Items["RealDropdown"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0, 0)})
                else
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0.5, 0)
                    Items["RealDropdown"].Instance.Position = UDim2New(1, 30, 0, 0)
                end
            end

            Items["RealDropdown"]:OnHover(function()
                if Dropdown.IsOpen then return end
                Items["ArrowIcon"]:Tween(nil, {ImageColor3 = FromRGB(255, 255, 255)})
                Items["Gradient"].Instance.Enabled = true
            end)

            Items["RealDropdown"]:OnHoverLeave(function()
                if Dropdown.IsOpen then return end
                Items["ArrowIcon"]:Tween(nil, {ImageColor3 = FromRGB(141, 141, 150)})
                Items["Gradient"].Instance.Enabled = false
            end)

            local RenderStepped

            function Dropdown:SetOpen(Bool)
                if Debounce then
                    return
                end

                Dropdown.IsOpen = Bool

                Debounce = true

                if Dropdown.IsOpen then
                    Items["OptionHolder"].Instance.Visible = true
                    Items["OptionHolder"].Instance.Parent = Library.Holder.Instance

                    Items["ArrowIcon"]:Tween(nil, {Rotation = 180, ImageColor3 = FromRGB(255, 255, 255)})
                    Items["Gradient"].Instance.Enabled = true

                    Library:Thread(function()
                        for Index, Value in Dropdown.OptionsWithIndexes do
                            task.spawn(function()
                                Value:RefreshPosition(true)
                            end)
                            task.wait(0.05)
                        end
                    end)

                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["OptionHolder"].Instance.Position = UDim2New(0, Items["RealDropdown"].Instance.AbsolutePosition.X, 0, Items["RealDropdown"].Instance.AbsolutePosition.Y + Items["RealDropdown"].Instance.AbsoluteSize.Y + 5)

                        local ContentHeight = (#Dropdown.OptionsWithIndexes * 24) + 12
                        local MaxHeight = Dropdown.OptionHolderSize
                        local Height = math.min(ContentHeight, MaxHeight)

                        local BaseWidth = Items["RealDropdown"].Instance.AbsoluteSize.X * 2
                        local ContentWidth = Dropdown.MaxOptionWidth + 80
                        local Width = math.max(BaseWidth, ContentWidth)

                        Items["OptionHolder"].Instance.Size = UDim2New(0, Width, 0, Height)
                    end)

                    for Index, Value in Library.OpenFrames do
                        if Value ~= Dropdown and not Dropdown.Section.IsSettings and type(Value) == "table" and Value.SetOpen then
                            Value:SetOpen(false)
                        end
                    end
                    Library.OpenFrames[Dropdown] = Dropdown
                else
                    if not Dropdown.IsOpen then
                        for Index, Value in Dropdown.OptionsWithIndexes do
                            task.spawn(function()
                                Value:RefreshPosition(false)
                            end)
                        end
                    end
                    if Library.OpenFrames[Dropdown] then
                        Library.OpenFrames[Dropdown] = nil
                    end
                    if RenderStepped then
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end
                    Items["ArrowIcon"]:Tween(nil, {Rotation = 0, ImageColor3 = FromRGB(141, 141, 150)})
                    Items["Gradient"].Instance.Enabled = false
                end

                local Descendants = Items["OptionHolder"].Instance:GetDescendants()
                TableInsert(Descendants, Items["OptionHolder"].Instance)

                local NewTween
                for Index, Value in Descendants do
                    local TransparencyProperty = Tween:GetProperty(Value)
                    if not TransparencyProperty then continue end
                    if not Value.ClassName:find("UI") then
                        Value.ZIndex = (Dropdown.IsOpen and Dropdown.Section.IsSettings and 8) or (Dropdown.IsOpen and 3) or 1
                    end
                    if type(TransparencyProperty) == "table" then
                        for _, Property in TransparencyProperty do
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                NewTween.Tween.Completed:Connect(function()
                    if not Library then return end
                    Debounce = false
                    Items["OptionHolder"].Instance.Visible = Dropdown.IsOpen
                    task.wait(0.2)
                    if not Library then return end
                    Items["OptionHolder"].Instance.Parent = not Dropdown.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Dropdown:UpdateText()
                local SelectedOptions = {}
                for _, Option in ipairs(Dropdown.OptionsWithIndexes) do
                    if Option.Selected then
                        table.insert(SelectedOptions, Option.Name .. " [" .. Option.Priority .. "]")
                    end
                end
                local Text = #SelectedOptions > 0 and table.concat(SelectedOptions, ", ") or "..."
                Items["Value"].Instance.Text = Text

                -- Update Value Table
                Dropdown.Value = {}
                for _, Option in ipairs(Dropdown.OptionsWithIndexes) do
                     Dropdown.Value[Option.Name] = { Selected = Option.Selected, Priority = Option.Priority }
                end
                Library.Flags[Dropdown.Flag] = Dropdown.Value
            end

            function Dropdown:Set(Option)
                if type(Option) == "table" then
                     -- Check if it's a list of names (array) or a state table (dictionary)
                     local IsArray = Option[1] ~= nil or next(Option) == nil

                     if IsArray then
                        -- Compat with list of names
                         for _, Opt in ipairs(Dropdown.OptionsWithIndexes) do
                             local Found = false
                             for _, Val in ipairs(Option) do
                                 if Val == Opt.Name then
                                     Found = true
                                     break
                                 end
                             end
                             Opt.Selected = Found
                             Opt:Toggle(Opt.Selected and "Active" or "Inactive")
                         end
                     else
                         -- State table
                         for Name, Data in pairs(Option) do
                             local Opt = Dropdown.Options[Name]
                             if Opt then
                                 if Data.Selected ~= nil then
                                     Opt.Selected = Data.Selected
                                     Opt:Toggle(Opt.Selected and "Active" or "Inactive")
                                 end
                                 if Data.Priority ~= nil then
                                     Opt.Priority = Data.Priority
                                     Opt.PriorityBox.Instance.Text = tostring(Data.Priority)
                                     -- Update badge color to match loaded priority
                                     local PCOLORS = {
                                         [1]=FromRGB(239,68,68),[2]=FromRGB(249,115,22),
                                         [3]=FromRGB(234,179,8),[4]=FromRGB(34,197,94),
                                         [5]=FromRGB(59,130,246),[6]=FromRGB(168,85,247),
                                         [7]=FromRGB(236,72,153),
                                     }
                                     local c = PCOLORS[Data.Priority] or FromRGB(100,97,120)
                                     if Opt.PriorityBox.Instance.Parent then
                                         local badge = Opt.PriorityBox.Instance.Parent
                                         if badge and badge:IsA("Frame") then
                                             badge.BackgroundColor3 = c
                                         end
                                     end
                                     Opt.PriorityBox.Instance.TextColor3 = c
                                 end
                             end
                         end
                     end
                end
                Dropdown:UpdateText()
            end

            function Dropdown:Add(Option)
                local OptionButton = Instances:Create("TextButton", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                local OptionAccent = Instances:Create("Frame", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient", {
                    Parent = OptionAccent.Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Instances:Create("UICorner", {
                    Parent = OptionAccent.Instance,
                    Name = "\0"
                })

                local OptionText = Instances:Create("TextLabel", {
                    Parent = OptionAccent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.3,
                    Text = Option,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 30, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  OptionText:AddToTheme({TextColor3 = "Text"})

                local TextSize = OptionText.Instance.TextBounds
                if TextSize.X > Dropdown.MaxOptionWidth then
                    Dropdown.MaxOptionWidth = TextSize.X
                end

                -- Priority badge wrapper
                local PRIORITY_COLORS = {
                    [1] = FromRGB(239, 68,  68),   -- red
                    [2] = FromRGB(249, 115, 22),   -- orange
                    [3] = FromRGB(234, 179, 8),    -- yellow
                    [4] = FromRGB(34,  197, 94),   -- green
                    [5] = FromRGB(59,  130, 246),  -- blue
                    [6] = FromRGB(168, 85,  247),  -- purple
                    [7] = FromRGB(236, 72,  153),  -- pink
                }
                local function GetPriorityColor(n)
                    return PRIORITY_COLORS[n] or FromRGB(100, 97, 120)
                end

                local PrioBadge = Instances:Create("Frame", {
                    Parent           = OptionButton.Instance,
                    Name             = "\0",
                    AnchorPoint      = Vector2New(1, 0.5),
                    Position         = UDim2New(1, -4, 0.5, 0),
                    Size             = UDim2New(0, 30, 0, 16),
                    BackgroundColor3 = GetPriorityColor(1),
                    BackgroundTransparency = 0.55,
                    BorderSizePixel  = 0,
                    ZIndex           = 4,
                })
                Instances:Create("UICorner", { Parent = PrioBadge.Instance, CornerRadius = UDimNew(0, 4) })

                local PriorityBox = Instances:Create("TextBox", {
                    Parent              = PrioBadge.Instance,
                    Name                = "\0",
                    FontFace            = Library.Font,
                    Text                = "1",
                    PlaceholderText     = "#",
                    TextColor3          = GetPriorityColor(1),
                    PlaceholderColor3   = FromRGB(180, 180, 180),
                    BackgroundTransparency = 1,
                    BorderSizePixel     = 0,
                    Size                = UDim2New(1, 0, 1, 0),
                    Position            = UDim2New(0, 0, 0, 0),
                    ZIndex              = 5,
                    TextSize            = 11,
                    TextXAlignment      = Enum.TextXAlignment.Center,
                    BackgroundColor3    = FromRGB(255, 255, 255),
                    ClipsDescendants    = false,
                })

                local function UpdateBadgeColor(num)
                    local c = GetPriorityColor(num)
                    TweenService:Create(PrioBadge.Instance,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = c }
                    ):Play()
                    PriorityBox.Instance.TextColor3 = c
                end

                local OptionData = {
                    Button = OptionButton,
                    Name = Option,
                    OptionText = OptionText,
                    OptionAccent = OptionAccent,
                    PriorityBox = PriorityBox,
                    Selected = false,
                    Priority = 1
                }

                function OptionData:Toggle(Value)
                    if Value == "Active" then
                        OptionText:Tween(nil, {TextTransparency = 0, Position = UDim2New(0, 15, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 0})
                    else
                        OptionText:Tween(nil, {TextTransparency = 0.3, Position = UDim2New(0, 0, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                function OptionData:RefreshPosition(Bool)
                    if Bool then
                        if OptionData.Selected then
                            OptionAccent:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 15, 0.5, 0)})
                        else
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                        end
                    else
                        if OptionData.Selected then
                            OptionAccent.Instance.Position = UDim2New(0, 30, 0.5, 0)
                            OptionText.Instance.Position = UDim2New(0, 45, 0.5, 0)
                        else
                            OptionText.Instance.Position = UDim2New(0, 30, 0.5, 0)
                        end
                    end
                end

                function OptionData:Set()
                    OptionData.Selected = not OptionData.Selected
                    OptionData:Toggle(OptionData.Selected and "Active" or "Inactive")
                    Dropdown:UpdateText()

                    if Dropdown.Callback then
                        Library:SafeCall(Dropdown.Callback, OptionData.Name, OptionData.Selected, OptionData.Priority)
                    end
                end

                OptionData.Button:Connect("MouseButton1Click", function()
                    OptionData:Set()
                end)

                OptionData.PriorityBox:Connect("FocusLost", function(Enter)
                    local Num = tonumber(OptionData.PriorityBox.Instance.Text)
                    if Num then
                        OptionData.Priority = math.max(1, math.floor(Num + 0.5))
                        OptionData.PriorityBox.Instance.Text = tostring(OptionData.Priority)
                        UpdateBadgeColor(OptionData.Priority)
                    else
                        OptionData.PriorityBox.Instance.Text = tostring(OptionData.Priority)
                    end
                    Dropdown:UpdateText()

                    if Dropdown.Callback then
                         Library:SafeCall(Dropdown.Callback, OptionData.Name, OptionData.Selected, OptionData.Priority)
                    end
                end)

                Dropdown.Options[OptionData.Name] = OptionData
                Dropdown.OptionsWithIndexes[#Dropdown.OptionsWithIndexes+1] = OptionData
                OptionData:RefreshPosition(false)

                return OptionData
            end

            function Dropdown:Remove(Option)
                if Dropdown.Options[Option] then
                    Dropdown.Options[Option].Button:Clean()
                    Dropdown.Options[Option] = nil
                end
            end

            function Dropdown:Refresh(List)
                for Index, Value in Dropdown.Options do
                    Dropdown:Remove(Value.Name)
                end
                Dropdown.OptionsWithIndexes = {}

                for Index, Value in List do
                    Dropdown:Add(Value)
                end
            end

            Items["RealDropdown"]:Connect("MouseButton1Click", function()
                Dropdown:SetOpen(not Dropdown.IsOpen)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dropdown.IsOpen then
                        if Library:IsMouseOverFrame(Items["OptionHolder"]) then return end
                        Dropdown:SetOpen(false)
                    end
                end
            end)

            Items["RealDropdown"]:Connect("Changed", function(Property)
                if Property == "AbsolutePosition" and Dropdown.IsOpen then
                    Dropdown.IsOpen = not Library:IsClipped(Items["OptionHolder"].Instance, Dropdown.Section.Items["Section"].Instance.Parent)
                    Items["OptionHolder"].Instance.Visible = Dropdown.IsOpen
                end
            end)

            for Index, Value in Dropdown.Items do
                Dropdown:Add(Value)
            end

            if Dropdown.Default then
                Dropdown:Set(Dropdown.Default)
            end

            Library.SetFlags[Dropdown.Flag] = function(Value)
                Dropdown:Set(Value)
            end

            if Dropdown.Section.Page and Dropdown.Section.Page.Active then
                Dropdown:RefreshPosition(true)
            end

            Dropdown.Section.Elements[#Dropdown.Section.Elements+1] = Dropdown

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Dropdown"].Instance)
            end

            return Dropdown
        end

        Library.Sections.Tabbox = function(self, Data)
            Data = Data or {}

            local Tabbox = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Tabs = {},
                ActiveTab = nil
            }

            local Items = {} do
                Items["Tabbox"] = Instances:Create("Frame", {
                    Parent = Tabbox.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                -- Container for Tab Buttons (Header)
                Items["Header"] = Instances:Create("Frame", {
                    Parent = Items["Tabbox"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 25),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    ZIndex = 2
                })

                Items["ButtonContainer"] = Instances:Create("Frame", {
                    Parent = Items["Header"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 2
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["ButtonContainer"].Instance,
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 4) -- Small gap between tabs
                })

                -- Content Frame (where elements go)
                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["Tabbox"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 0),
                    Position = UDim2New(0, 0, 0, 30), -- Offset by header height + padding
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    ZIndex = 2
                })

                 Instances:Create("UIListLayout", {
                    Parent = Items["Content"].Instance,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 0) -- Overlap is handled by visibility
                })
            end

            function Tabbox:RefreshPosition(Bool)
                if Bool then
                    Items["Header"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                    Items["Content"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 30)})
                else
                    Items["Header"].Instance.Position = UDim2New(0, 30, 0, 0)
                    Items["Content"].Instance.Position = UDim2New(0, 30, 0, 30)
                end
            end

            function Tabbox:AddTab(Name)
                local Icon = Library:GetCustomIcon(Name)
                local IsIcon = Icon ~= nil

                local Tab = {
                    Tabbox = Tabbox,
                    Name = Name,
                    Items = {},
                    Elements = {},
                    IsOpen = false
                }

                -- Create Tab Button
                local Button = Instances:Create("TextButton", {
                    Parent = Items["ButtonContainer"].Instance,
                    Name = Name,
                    Text = IsIcon and "" or Name,
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextSize = 13,
                    Size = UDim2New(0, 0, 1, 0), -- Width set dynamically
                    BackgroundColor3 = FromRGB(35, 35, 40),
                    BackgroundTransparency = 0, -- Inactive state
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    ZIndex = 2
                })
                Instances:Create("UICorner", {
                    Parent = Button.Instance,
                    CornerRadius = UDimNew(0, 4)
                })

                if IsIcon then
                    Tab.Items["Icon"] = Instances:Create("ImageLabel", {
                        Parent = Button.Instance,
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 18, 0, 18),
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Image = Icon.Url,
                        ImageRectOffset = Icon.ImageRectOffset,
                        ImageRectSize = Icon.ImageRectSize,
                        ImageColor3 = FromRGB(180, 180, 180),
                        BorderSizePixel = 0,
                        ZIndex = 3
                    })
                end

                Tab.Items["Button"] = Button

                -- Create Tab Content Container
                local Content = Instances:Create("Frame", {
                    Parent = Items["Content"].Instance,
                    Name = Name,
                    Size = UDim2New(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Visible = false,
                    ZIndex = 2
                })

                Instances:Create("UIListLayout", {
                    Parent = Content.Instance,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 6)
                })

                Instances:Create("UIPadding", {
                    Parent = Content.Instance,
                    PaddingTop = UDimNew(0, 6),
                    PaddingBottom = UDimNew(0, 6)
                })

                Tab.Items["Content"] = Content

                -- Button Click Logic
                Button:Connect("MouseButton1Click", function()
                    Tabbox:SetTab(Tab)
                end)

                -- Resize Logic (Equal Widths)
                local function UpdateWidths()
                    local Count = #Tabbox.Tabs
                    if Count > 0 then
                        local Width = 1 / Count
                        for _, T in ipairs(Tabbox.Tabs) do
                            if T.Items["Button"] and T.Items["Button"].Instance then
                                T.Items["Button"].Instance.Size = UDim2New(Width, -((4 * (Count - 1)) / Count), 1, 0)
                            end
                        end
                    end
                end

                table.insert(Tabbox.Tabs, Tab)
                UpdateWidths()

                -- Set Metatable for Element Creation inside Tab
                setmetatable(Tab, Library.Sections) -- Reuse Section metatable for element creation functions

                return Tab
            end

            function Tabbox:SetTab(Tab)
                if Tabbox.ActiveTab then
                    Tabbox.ActiveTab.IsOpen = false
                    Tabbox.ActiveTab.Items["Content"].Instance.Visible = false
                    -- Reset Style (Inactive)
                    Tabbox.ActiveTab.Items["Button"]:Tween(TweenInfo.new(0.2), {
                        BackgroundColor3 = FromRGB(35, 35, 40),
                        TextColor3 = FromRGB(180, 180, 180)
                    })
                    if Tabbox.ActiveTab.Items["Icon"] then
                        Tabbox.ActiveTab.Items["Icon"]:Tween(TweenInfo.new(0.2), {
                            ImageColor3 = FromRGB(180, 180, 180)
                        })
                    end
                end

                Tabbox.ActiveTab = Tab
                Tab.IsOpen = true
                Tab.Items["Content"].Instance.Visible = true
                -- Set Style (Active)
                Tab.Items["Button"]:Tween(TweenInfo.new(0.2), {
                    BackgroundColor3 = Library.Theme.Accent,
                    TextColor3 = FromRGB(255, 255, 255)
                })
                if Tab.Items["Icon"] then
                    Tab.Items["Icon"]:Tween(TweenInfo.new(0.2), {
                        ImageColor3 = FromRGB(255, 255, 255)
                    })
                end
            end

            -- Hook AddTab to auto-select first
            local OriginalAddTab = Tabbox.AddTab
            Tabbox.AddTab = function(self, Name)
                local Tab = OriginalAddTab(self, Name)
                if #Tabbox.Tabs == 1 then
                    Tabbox:SetTab(Tab)
                end
                return Tab
            end

            if Tabbox.Section.Page and Tabbox.Section.Page.Active then
                Tabbox:RefreshPosition(true)
            end

            Tabbox.Section.Elements[#Tabbox.Section.Elements+1] = Tabbox
            return Tabbox
        end

        -- Aliases for Sections
        Library.Sections.AddLeftTabbox = Library.Sections.Tabbox
        Library.Sections.AddRightTabbox = Library.Sections.Tabbox

        Library.Sections.Label = function(self, Data)
            Data = type(Data) == "table" and Data or {Name = Data}
            local Label = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Label"
            }

            local Items = { } do 
                Items["Label"] = Instances:Create("Frame", {
                    Parent = Label.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Label.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 30, 0, 5),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})          
            end

            --Label.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Label.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            function Label:SetText(Text)
                Text = tostring(Text)
                Items["Text"].Instance.Text = Text
            end

            function Label:SetVisibility(Bool)
                Items["Label"].Instance.Visible = Bool
            end

            function Label:RefreshPosition(Bool)
                if Bool then 
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 5)})

                    if Items["SubElements"] then
                        Items["SubElements"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 30)})
                        Tween:Create(Items["Label"].Instance:FindFirstChild("nig"), TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, -16, 1, -6)}, true)
                    end
                else 
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0, 5)

                    if Items["SubElements"] then
                        Items["SubElements"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 30, 0, 30)})
                        Tween:Create(Items["Label"].Instance:FindFirstChild("nig"), TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 30, 1, -6)}, true)
                    end
                end
            end

            function Label:Colorpicker(Data)
                Data = Data or { }

                local Colorpicker = {
                    Window = Label.Window,
                    Page = Label.Page,
                    Section = Label.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                    Callback = Data.Callback or Data.callback or function() end,
                    Alpha = Data.Alpha or Data.alpha or false
                }

                if not Items["SubElements"] then
                    Items["SubElements"] = Instances:Create("Frame", {
                        Parent = Items["Label"].Instance,
                        Name = "\0",
                        Size = UDim2New(1, 0, 0, 30),
                        Position = UDim2New(0, 0, 0, 30),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(27, 26, 29)
                    })  Items["SubElements"]:AddToTheme({BackgroundColor3 = "Element"})
                    
                    Instances:Create("UICorner", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 5)
                    })
                    
                    Instances:Create("UIListLayout", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDimNew(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })

                    Instances:Create("UIPadding", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        PaddingLeft = UDimNew(0, 6)
                    })                
                end

                --Label.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Label.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

                local NewColorpicker, ColorpickerItems = Library:CreateColorpicker({
                    Parent = Items["SubElements"],
                    Page = Colorpicker.Page,
                    Section = Colorpicker.Section,
                    Flag = Colorpicker.Flag,
                    Default = Colorpicker.Default,
                    Callback = Colorpicker.Callback,
                    Parent2 = Items["Label"],
                    Alpha = Colorpicker.Alpha
                })

                return NewColorpicker
            end

            if Label.Section.Page and Label.Section.Page.Active then
                Label:RefreshPosition(true)
            end

            Label.Section.Elements[#Label.Section.Elements+1] = Label

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Label"].Instance)
            end

            return Label
        end

        Library.Sections.Paragraph = function(self, Data)
            Data = Data or {}

            local Paragraph = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or Data.Title or Data.title or "Paragraph",
                Text = Data.Text or Data.text or "",
                Icon = Data.Icon or Data.icon or nil,
            }

            local Items = {} do
                Items["Paragraph"] = Instances:Create("Frame", {
                    Parent = Paragraph.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 0), -- AutomaticSize handles height
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                -- Layout container for Icon + Content
                Items["Container"] = Instances:Create("Frame", {
                    Parent = Items["Paragraph"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BorderSizePixel = 0
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Container"].Instance,
                    Name = "\0",
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDimNew(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Container"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 5),
                    PaddingRight = UDimNew(0, 5),
                    PaddingTop = UDimNew(0, 5),
                    PaddingBottom = UDimNew(0, 5)
                })

                if Paragraph.Icon then
                    local ParagraphIcon = Library:GetCustomIcon(Paragraph.Icon)
                    Items["Icon"] = Instances:Create("ImageLabel", {
                        Parent = Items["Container"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 18, 0, 18),
                        BackgroundTransparency = 1,
                        Image = ParagraphIcon and ParagraphIcon.Url or "",
                        ImageRectOffset = ParagraphIcon and ParagraphIcon.ImageRectOffset or Vector2New(0, 0),
                        ImageRectSize = ParagraphIcon and ParagraphIcon.ImageRectSize or Vector2New(0, 0),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        LayoutOrder = 1
                    })

                    Instances:Create("UIGradient", {
                        Parent = Items["Icon"].Instance,
                        Name = "\0",
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                    end})
                end

                -- Text container (Title + Text)
                Items["TextContent"] = Instances:Create("Frame", {
                    Parent = Items["Container"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, Paragraph.Icon and -30 or 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BorderSizePixel = 0,
                    LayoutOrder = 2
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["TextContent"].Instance,
                    Name = "\0",
                    FillDirection = Enum.FillDirection.Vertical,
                    Padding = UDimNew(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["TextContent"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    Text = Paragraph.Name,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Size = UDim2New(1, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    LayoutOrder = 1
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["TextContent"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(160, 160, 160),
                    Text = Paragraph.Text,
                    RichText = true,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Size = UDim2New(1, 0, 0, 14),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 13,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    LayoutOrder = 2
                })
            end

            function Paragraph:SetTitle(NewTitle)
                Items["Title"].Instance.Text = tostring(NewTitle)
            end

            function Paragraph:SetText(NewText)
                Items["Text"].Instance.Text = tostring(NewText)
            end

            function Paragraph:SetVisibility(Bool)
                Items["Paragraph"].Instance.Visible = Bool
            end

            function Paragraph:RefreshPosition(Bool)
                -- Paragraph likely doesn't need indentation animation like Label/Toggle, but consistent API helps
                if Bool then
                    Items["Container"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 5)})
                else
                    Items["Container"].Instance.Position = UDim2New(0, 0, 0, 5) -- Default offset
                end
            end

            if Paragraph.Section.Page and Paragraph.Section.Page.Active then
                Paragraph:RefreshPosition(true)
            end

            Paragraph.Section.Elements[#Paragraph.Section.Elements+1] = Paragraph

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Paragraph"].Instance)
            end

            return Paragraph
        end

        Library.Sections.Keybind = function(self, Data)
            Data = Data or { }

            local Keybind = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Keybind",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or Enum.KeyCode.RightShift,
                Callback = Data.Callback or Data.callback or function() end,
                Mode = Data.Mode or Data.mode or Enum.KeyCode.RightShift,

                Value = "",
                ModeSelected = "",
                Toggled = false,
                Picking = false
            }

            local Items = { } do
                Items["Label"] = Instances:Create("Frame", {
                    Parent = Keybind.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["SubElements"] = Instances:Create("Frame", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 30),
                    Position = UDim2New(0, 0, 0, 30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["SubElements"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 6)
                })
                
                Items["KeyButton"] = Instances:Create("TextButton", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "MouseButton2",
                    AutoButtonColor = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    SelectionOrder = 2,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["KeyButton"]:AddToTheme({TextColor3 = "Text"})
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Keybind.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 5),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
                
                Items["Modes"] = Instances:Create("Frame", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, 0, 0, 0),
                    Size = UDim2New(0, 200, 0, 25),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Modes"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })
                
                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    Size = UDim2New(0.35, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --Items["Background"]:AddToTheme({BackgroundColor3 = "Accent"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(166, 166, 166))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    TextTransparency = 0.30000001192092896,
                    Text = "Toggle",
                    AutoButtonColor = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0.35, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Toggle"]:AddToTheme({TextColor3 = function()
                    return Library.Theme.Text
                end})
                
                Items["Hold"] = Instances:Create("TextButton", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.20000000298023224,
                    Text = "Hold",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 0),
                    Size = UDim2New(0.35, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.35, 0, 0, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Hold"]:AddToTheme({TextColor3 = function()
                    return Library.Theme.Text
                end})        
                
                Items["Always"] = Instances:Create("TextButton", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.20000000298023224,
                    Text = "Always",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 0),
                    Size = UDim2New(0.4, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.7, -12, 0, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Always"]:AddToTheme({TextColor3 = function()
                    return Library.Theme.Text
                end})              
            end

            --Keybind.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Keybind.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            local KeyListItem 

            if Library.KeyList then 
                KeyListItem = Library.KeyList:Add("", "")
            end

            local Update = function()
                if KeyListItem then 
                    KeyListItem:Set(Data.Name, Keybind.Value)
                    KeyListItem:SetStatus(Keybind.Toggled)
                end
            end

            function Keybind:RefreshPosition(Bool)
                if Bool then 
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 5)})
                    Items["SubElements"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 30)})
                    Items["Modes"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0, 0)})
                else
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0, 5)
                    Items["SubElements"].Instance.Position = UDim2New(0, 30, 0, 30)
                    Items["Modes"].Instance.Position = UDim2New(1, 30, 0, 0)
                end
            end

            function Keybind:SetMode(Mode) -- hard coded
                if Mode == "Toggle" then
                    Items["Background"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0), Size = UDim2New(0.35, 0, 1, 0)})
                    Items["Toggle"]:ChangeItemTheme({TextColor3 = function()
                        return FromRGB(0, 0, 0)
                    end})
                    Items["Toggle"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0)})

                    Items["Hold"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Hold"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                    Items["Always"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Always"]:Tween(nil, {TextColor3 = Library.Theme.Text})
                elseif Mode == "Hold" then
                    Items["Background"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0.35, 0, 0, 0), Size = UDim2New(0.35, 0, 1, 0)})
                
                    Items["Toggle"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Toggle"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                    Items["Hold"]:ChangeItemTheme({TextColor3 = function()
                        return FromRGB(0, 0, 0)
                    end})
                    Items["Hold"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0)})

                    Items["Always"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Always"]:Tween(nil, {TextColor3 = Library.Theme.Text})
                elseif Mode == "Always" then
                    Items["Background"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0.7, 0, 0, 0), Size = UDim2New(0.3, 0, 1, 0)})
                
                    Items["Toggle"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Toggle"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                    Items["Hold"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Hold"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                    Items["Always"]:ChangeItemTheme({TextColor3 = function()
                        return FromRGB(0, 0, 0)
                    end})
                    Items["Always"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0)})
                end

                Library.Flags[Keybind.Flag] = {
                    Mode = Keybind.ModeSelected,
                    Key = Keybind.Key,
                    Toggled = Keybind.Toggled
                }

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end
            end

            function Keybind:Press(Bool)
                if Keybind.ModeSelected == "Toggle" then 
                    Keybind.Toggled = not Keybind.Toggled
                elseif Keybind.ModeSelected == "Hold" then 
                    Keybind.Toggled = Bool
                elseif Keybind.ModeSelected == "Always" then 
                    Keybind.Toggled = true
                end

                Library.Flags[Keybind.Flag] = {
                    Mode = Keybind.ModeSelected,
                    Key = Keybind.Key,
                    Toggled = Keybind.Toggled
                }

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end

                Update()
            end

            function Keybind:Get()
                return Keybind.Key, Keybind.ModeSelected, Keybind.Toggled
            end

            function Keybind:Set(Key)
                if StringFind(tostring(Key), "Enum") then 
                    Keybind.Key = tostring(Key)

                    Key = Key.Name == "Backspace" and "None" or Key.Name

                    local KeyString = Keys[Keybind.Key] or StringGSub(Key, "Enum.", "") or "None"
                    local TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"

                    Keybind.Value = TextToDisplay
                    Items["KeyButton"].Instance.Text = TextToDisplay

                    Library.Flags[Keybind.Flag] = {
                        Mode = Keybind.ModeSelected,
                        Key = Keybind.Key,
                        Toggled = Keybind.Toggled
                    }

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                elseif type(Key) == "table" then
                    local RealKey = Key.Key == "Backspace" and "None" or Key.Key
                    Keybind.Key = tostring(Key.Key)

                    if Key.ModeSelected then
                        Keybind.ModeSelected = Key.Mode
                        Keybind:SetMode(Key.Mode)
                    else
                        Keybind.ModeSelected = "Toggle"
                        Keybind:SetMode("Toggle")
                    end

                    local KeyString = Keys[Keybind.Key] or StringGSub(tostring(RealKey), "Enum.", "") or RealKey
                    local TextToDisplay = KeyString and StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"

                    TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "")

                    Keybind.Value = TextToDisplay
                    Items["KeyButton"].Instance.Text = TextToDisplay

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                elseif TableFind({"Toggle", "Hold", "Always"}, Key) then
                    Keybind.ModeSelected = Key
                    Keybind:SetMode(Key)

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                end

                --Items["KeyButton"].Instance.Position = UDim2New(0, Data.Text.Instance.TextBounds.X + 12, 0, 0)
                Keybind.Picking = false
            end

            Items["KeyButton"]:Connect("MouseButton1Click", function()
                Keybind.Picking = true 

                Items["KeyButton"].Instance.Text = "."
                Library:Thread(function()
                    local Count = 1

                    while true do 
                        if not Keybind.Picking then 
                            break
                        end

                        if Count == 4 then
                            Count = 1
                        end

                        Items["KeyButton"].Instance.Text = Count == 1 and "." or Count == 2 and ".." or Count == 3 and "..."
                        Count += 1
                        task.wait(0.35)
                    end
                end)

                local InputBegan
                InputBegan = UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.Keyboard then 
                        Keybind:Set(Input.KeyCode)
                    else
                        Keybind:Set(Input.UserInputType)
                    end

                    InputBegan:Disconnect()
                    InputBegan = nil
                end)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Keybind.Value == "None" then
                    return
                end

                if tostring(Input.KeyCode) == Keybind.Key then
                    if Keybind.ModeSelected == "Toggle" then 
                        Keybind:Press()
                    elseif Keybind.ModeSelected == "Hold" then 
                        Keybind:Press(true)
                    elseif Keybind.ModeSelected == "Always" then 
                        Keybind:Press(true)
                    end
                elseif tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.ModeSelected == "Toggle" then 
                        Keybind:Press()
                    elseif Keybind.ModeSelected == "Hold" then 
                        Keybind:Press(true)
                    elseif Keybind.ModeSelected == "Always" then 
                        Keybind:Press(true)
                    end
                end

                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not Keybind.IsOpen then
                        return
                    end

                    if Library:IsMouseOverFrame(Items["KeybindWindow"]) or Library:IsMouseOverFrame(Items["OptionHolder"]) then
                        return
                    end

                    Keybind:SetOpen(false)
                end
            end)

            Library:Connect(UserInputService.InputEnded, function(Input)
                if Keybind.Value == "None" then
                    return
                end

                if tostring(Input.KeyCode) == Keybind.Key then
                    if Keybind.ModeSelected == "Hold" then 
                        Keybind:Press(false)
                    elseif Keybind.ModeSelected == "Always" then 
                        Keybind:Press(true)
                    end
                elseif tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.ModeSelected == "Hold" then 
                        Keybind:Press(false)
                    elseif Keybind.ModeSelected == "Always" then 
                        Keybind:Press(true)
                    end
                end
            end)

            Items["Toggle"]:Connect("MouseButton1Click", function()
                Keybind.ModeSelected = "Toggle"
                Keybind:SetMode("Toggle")
            end)

            Items["Hold"]:Connect("MouseButton1Click", function()
                Keybind.ModeSelected = "Hold"
                Keybind:SetMode("Hold")
            end)

            Items["Always"]:Connect("MouseButton1Click", function()
                Keybind.ModeSelected = "Always"
                Keybind:SetMode("Always")
            end)

            if Keybind.Default then 
                Keybind:Set({
                    Mode = Keybind.Mode or "Toggle",
                    Key = Keybind.Default,
                })
            end

            Library.SetFlags[Keybind.Flag] = function(Value)
                Keybind:Set(Value)
            end

            if Keybind.Section.Page and Keybind.Section.Page.Active then
                Keybind:RefreshPosition(true)
            end

            Keybind.Section.Elements[#Keybind.Section.Elements+1] = Keybind

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Label"].Instance)
            end

            return Keybind 
        end

        Library.Sections.Textbox = function(self, Data)
            Data = Data or {}

            local Textbox = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Textbox",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default,
                Callback = Data.Callback or Data.callback or function() end,
                Placeholder = Data.Placeholder or Data.placeholder or "Placeholder",
                Numeric = Data.Numeric or Data.numeric or false,
                Finished = Data.Finished or Data.finished or false,

                AutoComplete = Data.AutoComplete or false,
                CompleteOptions = Data.CompleteOptions or {},
                ResultsIsOpen = false,

                Value = ""
            }

            local Items = {} do
                Items["Textbox"] = Instances:Create("Frame", {
                    Parent = Textbox.Section.Items["Content"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Selectable = true,
                    Size = UDim2New(1, 0, 0, 32),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                }) 

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Textbox"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.3,
                    Text = Textbox.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 30, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
                
                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Textbox"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, 30, 0.5, 0),
                    Size = UDim2New(0, 160, 0, 22),
                    Selectable = true,
                    ZIndex = 2,
                    ClipsDescendants = true,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UIStroke", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 33, 38),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Outline"})

                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Size = UDim2New(1, -20, 1, 0),
                    Position = UDim2New(0, 10, 0, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = Textbox.Placeholder,
                    TextSize = 13,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Input"]:AddToTheme({TextColor3 = "Text"})

                if Textbox.AutoComplete then
                    Items["ResultsHolder"] = Instances:Create("Frame", {
                        Parent = Library.UnusedHolder.Instance,
                        Name = "\0",
                        Visible = false,
                        Position = UDim2New(0, 0, 0, 0),
                        Size = UDim2New(0, 0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        ZIndex = 3,
                        BackgroundColor3 = FromRGB(27, 25, 29)
                    })  Items["ResultsHolder"]:AddToTheme({BackgroundColor3 = "Background"})

                    Instances:Create("UIStroke", {
                        Parent = Items["ResultsHolder"].Instance,
                        Name = "\0",
                        Color = FromRGB(35, 33, 38),
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    }):AddToTheme({Color = "Outline"})

                    Instances:Create("UICorner", {
                        Parent = Items["ResultsHolder"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 5)
                    })
                    
                    Items["ResultsList"] = Instances:Create("ScrollingFrame", {
                        Parent = Items["ResultsHolder"].Instance,
                        Name = "\0",
                        Active = true,
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        ScrollBarThickness = 2,
                        Size = UDim2New(1, -16, 1, -16),
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 8, 0, 8),
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        CanvasSize = UDim2New(0, 0, 0, 0)
                    }) Items["ResultsList"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

                    Instances:Create("UIListLayout", {
                        Parent = Items["ResultsList"].Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 4),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                end
            end
            
            function Textbox:Get()
                return Textbox.Value
            end

            function Textbox:SetVisibility(Bool)
                Items["Textbox"].Instance.Visible = Bool
            end

            function Textbox:RefreshPosition(Bool)
                if Bool then
                    Items["Title"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                    Items["Background"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0.5, 0)})
                else
                    Items["Title"].Instance.Position = UDim2New(0, 30, 0.5, 0)
                    Items["Background"].Instance.Position = UDim2New(1, 30, 0.5, 0)
                end
            end

            function Textbox:Set(Value)
                if Textbox.Numeric then
                    if (not tonumber(Value)) and StringLen(tostring(Value)) > 0 then
                        Value = Textbox.Value
                    end
                end

                Textbox.Value = Value
                Items["Input"].Instance.Text = tostring(Value)
                Library.Flags[Textbox.Flag] = Value

                if Textbox.Callback then
                    Library:SafeCall(Textbox.Callback, Value)
                end
            end

            local ResultsRenderStepped

            function Textbox:SetOpen(Bool)
                if not Textbox.AutoComplete then return end
                if Textbox.ResultsIsOpen == Bool then return end
                
                Textbox.ResultsIsOpen = Bool
                
                if Bool then
                    Items["ResultsHolder"].Instance.Visible = true
                    Items["ResultsHolder"].Instance.Parent = Library.Holder.Instance
                    
                    ResultsRenderStepped = RunService.RenderStepped:Connect(function()
                        local Count = 0
                        for _, child in ipairs(Items["ResultsList"].Instance:GetChildren()) do
                            if child:IsA("TextButton") then Count = Count + 1 end
                        end
                        
                        local ContentHeight = (Count * 24) + 16 -- Add some padding
                        local Height = math.min(ContentHeight, 200)
                        Items["ResultsHolder"].Instance.Size = UDim2New(0, Items["Background"].Instance.AbsoluteSize.X, 0, Height)
                        
                        -- Position above
                        Items["ResultsHolder"].Instance.Position = UDim2New(
                            0, 
                            Items["Background"].Instance.AbsolutePosition.X, 
                            0, 
                            Items["Background"].Instance.AbsolutePosition.Y - Height - 5
                        )
                    end)
                    
                     for Index, Value in Library.OpenFrames do 
                        if Value ~= Textbox and type(Value) == "table" and Value.SetOpen then
                            Value:SetOpen(false)
                        end
                    end
                    Library.OpenFrames[Textbox] = Textbox 
                else
                     Items["ResultsHolder"].Instance.Visible = false
                     Items["ResultsHolder"].Instance.Parent = Library.UnusedHolder.Instance
                     
                     if ResultsRenderStepped then
                        ResultsRenderStepped:Disconnect()
                        ResultsRenderStepped = nil
                     end

                     if Library.OpenFrames[Textbox] then 
                        Library.OpenFrames[Textbox] = nil
                    end
                end
            end

            function Textbox:UpdateResults()
                if not Textbox.AutoComplete then return end
                
                local InputText = Items["Input"].Instance.Text
                
                -- Clear old
                for _, child in ipairs(Items["ResultsList"].Instance:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                
                if InputText == "" then
                    Textbox:SetOpen(false)
                    return
                end
                
                local function EscapePattern(s)
                    return s:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
                end
                
                local Pattern = ""
                for i = 1, #InputText do
                     local c = InputText:sub(i,i)
                     if c:match("%a") then
                         Pattern = Pattern .. "[" .. string.upper(c) .. string.lower(c) .. "]"
                     else
                         Pattern = Pattern .. EscapePattern(c)
                     end
                end
                
                local Count = 0
                for _, Option in ipairs(Textbox.CompleteOptions) do
                    if string.find(Option, Pattern) then
                        Count = Count + 1
                        local Button = Instances:Create("TextButton", {
                            Parent = Items["ResultsList"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = "",
                            AutoButtonColor = false,
                            BackgroundTransparency = 1,
                            Size = UDim2New(1, 0, 0, 20),
                            BorderSizePixel = 0,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255),
                            RichText = true
                        })  Button:AddToTheme({TextColor3 = "Text"})
                        
                        -- Highlighting
                        local HighlightedText = string.gsub(Option, "("..Pattern..")", function(s)
                            return Library:ToRich(s, Library.Theme.Accent)
                        end)
                        Button.Instance.Text = HighlightedText
                        
                        -- Alignment
                        Button.Instance.TextXAlignment = Enum.TextXAlignment.Left
                        
                         local Accent = Instances:Create("Frame", {
                            Parent = Button.Instance,
                            Name = "\0",
                            BorderColor3 = FromRGB(0, 0, 0),
                            AnchorPoint = Vector2New(0, 0.5),
                            BackgroundTransparency = 1,
                            Position = UDim2New(0, 0, 0.5, 0),
                            Size = UDim2New(0, 3, 0, 14), 
                            BorderSizePixel = 0,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })
                         Instances:Create("UIGradient", {
                            Parent = Accent.Instance,
                             Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                         }):AddToTheme({Color = function()
                            return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                        end})
                        
                         Instances:Create("UIPadding", {
                            Parent = Button.Instance,
                            PaddingLeft = UDimNew(0, 8)
                        })

                        Button:Connect("MouseButton1Click", function()
                            Textbox:Set(Option)
                            Textbox:SetOpen(false)
                        end)
                        
                        Button:OnHover(function()
                             Accent:Tween(nil, {BackgroundTransparency = 0})
                        end)
                        Button:OnHoverLeave(function()
                             Accent:Tween(nil, {BackgroundTransparency = 1})
                        end)
                    end
                end
                
                if Count > 0 then
                    Textbox:SetOpen(true)
                else
                    Textbox:SetOpen(false)
                end
            end

            if Textbox.Finished then 
                Items["Input"]:Connect("FocusLost", function(PressedEnterQuestionMark)
                    if PressedEnterQuestionMark then
                        Textbox:Set(Items["Input"].Instance.Text)
                    end
                end)
            else
                Library:Connect(Items["Input"].Instance:GetPropertyChangedSignal("Text"), function()
                    Textbox:Set(Items["Input"].Instance.Text)
                end)
            end

            if Textbox.AutoComplete then
                 Library:Connect(Items["Input"].Instance:GetPropertyChangedSignal("Text"), function()
                    if Items["Input"].Instance.Text ~= Textbox.Value then
                         if Items["Input"].Instance:IsFocused() then
                             Textbox:UpdateResults()
                         end
                    end
                 end)
                 
                 Items["Input"]:Connect("Focused", function()
                     if Items["Input"].Instance.Text ~= "" then
                         Textbox:UpdateResults()
                     end
                 end)
                 
                 Library:Connect(UserInputService.InputBegan, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        if Textbox.ResultsIsOpen then
                             if Library:IsMouseOverFrame(Items["ResultsHolder"]) then return end
                             if Library:IsMouseOverFrame(Items["Background"]) then return end
                             
                             Textbox:SetOpen(false)
                        end
                    end
                end)
            end

            if Textbox.Default ~= nil then
                Textbox:Set(Textbox.Default)
            end

            Library.SetFlags[Textbox.Flag] = function(Value)
                Textbox:Set(Value)
            end

            if Textbox.Section.Page and Textbox.Section.Page.Active then
                Textbox:RefreshPosition(true)
            end

            Textbox.Section.Elements[#Textbox.Section.Elements+1] = Textbox

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Textbox"].Instance)
            end

            return Textbox
        end

        Library.Sections.Listbox = function(self, Data)
            Data = Data or {}

            local Listbox = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or Data.Title or Data.title or "Listbox",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Items = Data.Items or Data.items or {},
                Default = Data.Default or Data.default or nil,
                Callback = Data.Callback or Data.callback or function() end,
                Size = Data.Size or Data.size or 200, -- Height of the scroll area
                Multi = Data.Multi or Data.multi or false,

                Value = {},
                Options = {},
                IsOpen = false
            }

            local Items = {} do
                Items["Listbox"] = Instances:Create("Frame", {
                    Parent = Listbox.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y, -- Auto height based on content
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                -- Header
                Items["Header"] = Instances:Create("TextButton", {
                    Parent = Items["Listbox"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 25),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Header"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.3,
                    Text = Listbox.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 30, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Items["ArrowIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Header"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(141, 141, 150),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 16, 0, 8),
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://123317177279443", -- Same arrow as dropdown
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -5, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                -- Content Frame (Collapsible)
                Items["ContentFrame"] = Instances:Create("Frame", {
                    Parent = Items["Listbox"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 0), -- Start height 0
                    Position = UDim2New(0, 0, 0, 25),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ClipsDescendants = true,
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                -- Search Bar
                Items["Search"] = Instances:Create("TextBox", {
                    Parent = Items["ContentFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    CursorPosition = -1,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Size = UDim2New(1, 0, 0, 30),
                    BorderSizePixel = 0,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = "Search..",
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Search"]:AddToTheme({TextColor3 = "Text", BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 4),
                    PaddingLeft = UDimNew(0, 8)
                })

                -- Scroll Holder
                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["ContentFrame"].Instance,
                    Name = "\0",
                    Active = true,
                    Size = UDim2New(1, 0, 1, -35), -- Minus search height + margin
                    BorderColor3 = FromRGB(0, 0, 0),
                    Position = UDim2New(0, 0, 0, 35),
                    BackgroundColor3 = FromRGB(27, 26, 29),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })

                Items["Holder"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    ScrollBarImageColor3 = FromRGB(0, 0, 0),
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, -4, 1, -8),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Position = UDim2New(0, 0, 0, 4),
                    BackgroundColor3 = FromRGB(27, 26, 29),
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                }) Items["Holder"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

                Instances:Create("UIListLayout", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 12),
                    PaddingLeft = UDimNew(0, 8)
                })
            end

            function Listbox:SetOpen(Bool)
                Listbox.IsOpen = Bool

                if Listbox.IsOpen then
                    Items["ContentFrame"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 0, Listbox.Size + 35)})
                    Items["ArrowIcon"]:Tween(nil, {Rotation = 180, ImageColor3 = FromRGB(255, 255, 255)})
                else
                    Items["ContentFrame"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 0, 0)})
                    Items["ArrowIcon"]:Tween(nil, {Rotation = 0, ImageColor3 = FromRGB(141, 141, 150)})
                end
            end

            Items["Header"]:Connect("MouseButton1Click", function()
                Listbox:SetOpen(not Listbox.IsOpen)
            end)

            function Listbox:Get()
                return Listbox.Value
            end

            function Listbox:SetVisibility(Bool)
                Items["Listbox"].Instance.Visible = Bool
            end

            -- Header animation like Dropdown? Maybe just text color/position
            function Listbox:RefreshPosition(Bool)
                if Bool then
                    Items["Title"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                else
                    Items["Title"].Instance.Position = UDim2New(0, 30, 0.5, 0)
                end
            end

            function Listbox:Set(Option)
                if Listbox.Multi then
                    if type(Option) ~= "table" then 
                        return
                    end

                    Listbox.Value = Option
                    Library.Flags[Listbox.Flag] = Option

                    for Index, Value in Option do
                        local OptionData = Listbox.Options[Value]
                         
                        if not OptionData then
                            continue
                        end

                        OptionData.Selected = true 
                        OptionData:Toggle("Active")
                    end
                else
                    if not Listbox.Options[Option] then
                        return
                    end

                    local OptionData = Listbox.Options[Option]

                    Listbox.Value = Option
                    Library.Flags[Listbox.Flag] = Option

                    for Index, Value in Listbox.Options do
                        if Value ~= OptionData then
                            Value.Selected = false 
                            Value:Toggle("Inactive")
                        else
                            Value.Selected = true 
                            Value:Toggle("Active")
                        end
                    end
                end

                if Listbox.Callback then
                    Library:SafeCall(Listbox.Callback, Listbox.Value)
                end
            end

            function Listbox:Add(Option)
                if not Library then return end
                local OptionButton = Instances:Create("TextButton", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                local OptionAccent = Instances:Create("Frame", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    ZIndex = 2,
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = OptionAccent.Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Instances:Create("UICorner", {
                    Parent = OptionAccent.Instance,
                    Name = "\0"
                })
                
                local OptionText = Instances:Create("TextLabel", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.30000001192092896,
                    Text = Option,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  OptionText:AddToTheme({TextColor3 = "Text"})
                
                local OptionData = {
                    Button = OptionButton,
                    Name = Option,
                    OptionText = OptionText,
                    IsSearching = false,
                    OptionAccent = OptionAccent,
                    Selected = false
                }
                
                function OptionData:Toggle(Value)
                    if Value == "Active" then
                        OptionText:Tween(nil, {TextTransparency = 0, Position = UDim2New(0, 15, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 0})
                    else
                        OptionText:Tween(nil, {TextTransparency = 0.3, Position = UDim2New(0, 0, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                function OptionData:Search(Bool)
                    Library:Thread(function()
                        if Bool then 
                            OptionData.IsSearching = true
                            OptionText:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 1})
                            task.wait(0.08)
                            OptionButton:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 0, 0)})
                            
                            if OptionData.Selected then 
                                OptionAccent:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                            end
                        else
                            OptionData.IsSearching = false
                            OptionText:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = OptionData.Selected and 0 or 0.3})
                            task.wait(0.08)
                            OptionButton:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 0, 20)})
                            
                            if OptionData.Selected then 
                                OptionAccent:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
                            end
                        end
                    end)
                end

                function OptionData:Set()
                    OptionData.Selected = not OptionData.Selected

                    if Listbox.Multi then
                        local Index = TableFind(Listbox.Value, OptionData.Name)

                        if Index then 
                            TableRemove(Listbox.Value, Index)
                        else
                            TableInsert(Listbox.Value, OptionData.Name)
                        end

                        OptionData:Toggle(Index and "Inactive" or "Active")

                        Library.Flags[Listbox.Flag] = Listbox.Value
                    else
                        if OptionData.Selected then 
                            Listbox.Value = OptionData.Name
                            Library.Flags[Listbox.Flag] = OptionData.Name

                            OptionData.Selected = true
                            OptionData:Toggle("Active")

                            for Index, Value in Listbox.Options do
                                if Value ~= OptionData and not Value.IsSearching then
                                    Value.Selected = false 
                                    Value:Toggle("Inactive")
                                end
                            end
                        else
                            Listbox.Value = nil
                            Library.Flags[Listbox.Flag] = nil

                            OptionData.Selected = false
                            OptionData:Toggle("Inactive")
                        end
                    end

                    if Listbox.Callback then
                        Library:SafeCall(Listbox.Callback, Listbox.Value)
                    end
                end

                OptionData.Button:Connect("MouseButton1Click", function()
                    OptionData:Set()
                end)

                Listbox.Options[OptionData.Name] = OptionData
                return OptionData
            end

            function Listbox:Remove(Option)
                if Listbox.Options[Option] then
                    Listbox.Options[Option].Button:Clean()
                    Listbox.Options[Option] = nil
                end
            end

            function Listbox:Refresh(List)
                for Index, Value in Listbox.Options do
                    Listbox:Remove(Value.Name)
                end

                for Index, Value in List do 
                    Listbox:Add(Value)
                end
            end

            Library:Connect(Items["Search"].Instance:GetPropertyChangedSignal("Text"), function()
                Library:Thread(function()
                    for Index, Value in Listbox.Options do
                        local InputText = Items["Search"].Instance.Text
                        if InputText ~= "" then
                            if StringFind(StringLower(Value.Name), Library:EscapePattern(StringLower(InputText))) then
                                Value.Button.Instance.Visible = true
                                Value:Search(false)
                            else
                                Value:Search(true)
                                Value.Button.Instance.Visible = false
                            end
                        else
                            Value:Search(false)
                            Value.Button.Instance.Visible = true
                        end
                    end
                end)
            end)


            for Index, Value in Listbox.Items do
                Listbox:Add(Value)
            end

            if Listbox.Default then
                Listbox:Set(Listbox.Default)
            end

            Library.SetFlags[Listbox.Flag] = function(Value)
                Listbox:Set(Value)
            end

            if Listbox.Section.Page and Listbox.Section.Page.Active then
                Listbox:RefreshPosition(true)
            end

            Listbox.Section.Elements[#Listbox.Section.Elements+1] = Listbox

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Header"].Instance)
            end

            return Listbox
        end

        Library.Sections.InputList = function(self, Data)
            Data = Data or {}

            local InputList = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "InputList",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Callback = Data.Callback or Data.callback or function() end,
                Placeholder = Data.Placeholder or Data.placeholder or "Enter text...",

                Value = {},
            }

            local Items = {} do
                Items["InputList"] = Instances:Create("Frame", {
                    Parent = InputList.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                -- Title
                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["InputList"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.3,
                    Text = InputList.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 30, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                -- Input Area
                Items["InputArea"] = Instances:Create("Frame", {
                    Parent = Items["InputList"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, -60, 0, 32),
                    Position = UDim2New(0, 30, 0, 20),
                    ZIndex = 2
                })

                -- Input Box Background
                Items["InputBackground"] = Instances:Create("Frame", {
                    Parent = Items["InputArea"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -35, 1, 0),
                    ZIndex = 2,
                    ClipsDescendants = true,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["InputBackground"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UIStroke", {
                    Parent = Items["InputBackground"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 33, 38),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Outline"})

                Instances:Create("UICorner", {
                    Parent = Items["InputBackground"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                local InputIconData = Library:GetCustomIcon("pencil")
                Items["InputIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["InputBackground"].Instance,
                    Name = "\0",
                    Image = InputIconData and InputIconData.Url or "",
                    ImageRectOffset = InputIconData and InputIconData.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = InputIconData and InputIconData.ImageRectSize or Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 16, 0, 16),
                    Position = UDim2New(0, 8, 0.5, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    ZIndex = 2,
                    ImageColor3 = FromRGB(180, 180, 180)
                })

                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["InputBackground"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Size = UDim2New(1, -34, 1, 0),
                    Position = UDim2New(0, 30, 0, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = InputList.Placeholder,
                    TextSize = 13,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Input"]:AddToTheme({TextColor3 = "Text"})

                Items["Input"]:Connect("Focused", function()
                    local Stroke = Items["InputBackground"].Instance:FindFirstChildOfClass("UIStroke")
                    if Stroke then
                        TweenService:Create(Stroke, TweenInfo.new(0.3), {Color = Library.Theme.Accent}):Play()
                    end
                end)

                Items["Input"]:Connect("FocusLost", function()
                     local Stroke = Items["InputBackground"].Instance:FindFirstChildOfClass("UIStroke")
                    if Stroke then
                        TweenService:Create(Stroke, TweenInfo.new(0.3), {Color = Library.Theme.Outline}):Play()
                    end
                end)

                -- Add Button (Square, Black background)
                Items["AddButton"] = Instances:Create("TextButton", {
                    Parent = Items["InputArea"].Instance,
                    Name = "\0",
                    Text = "",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    Size = UDim2New(0, 32, 0, 32),
                    Position = UDim2New(1, -32, 0, 0),
                    BackgroundColor3 = FromRGB(0, 0, 0), -- Black
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    TextSize = 18,
                    ZIndex = 2
                })

                local AddIconData = Library:GetCustomIcon("plus")
                Items["AddIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["AddButton"].Instance,
                    Name = "\0",
                    Image = AddIconData and AddIconData.Url or "",
                    ImageRectOffset = AddIconData and AddIconData.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = AddIconData and AddIconData.ImageRectSize or Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 18, 0, 18),
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    ZIndex = 3,
                    ImageColor3 = FromRGB(255, 255, 255)
                })

                local AddButtonStroke = Instances:Create("UIStroke", {
                    Parent = Items["AddButton"].Instance,
                    Name = "\0",
                    Color = FromRGB(60, 60, 60),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Transparency = 0
                })

                -- Pink animation for Add Button
                Items["AddButton"]:OnHover(function()
                    Items["AddIcon"]:Tween(nil, {ImageColor3 = Library.Theme.Accent})
                    AddButtonStroke:Tween(nil, {Color = Library.Theme.Accent})
                end)

                Items["AddButton"]:OnHoverLeave(function()
                    Items["AddIcon"]:Tween(nil, {ImageColor3 = FromRGB(255, 255, 255)})
                    AddButtonStroke:Tween(nil, {Color = FromRGB(60, 60, 60)})
                end)

                -- List Area
                Items["ListArea"] = Instances:Create("Frame", {
                    Parent = Items["InputList"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, -60, 0, 0),
                    Position = UDim2New(0, 30, 0, 60),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 2
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["ListArea"].Instance,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 5)
                })
            end

            function InputList:GetTable()
                return InputList.Value
            end

            function InputList:SetVisibility(Bool)
                Items["InputList"].Instance.Visible = Bool
            end

            function InputList:RefreshPosition(Bool)
                if Bool then
                    Items["Title"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                    Items["InputArea"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 20)})
                    Items["ListArea"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 60)})
                else
                    Items["Title"].Instance.Position = UDim2New(0, 30, 0, 0)
                    Items["InputArea"].Instance.Position = UDim2New(0, 30, 0, 20)
                    Items["ListArea"].Instance.Position = UDim2New(0, 30, 0, 60)
                end
            end

            function InputList:Remove(Text)
                if not Library then return end
                local Index = TableFind(InputList.Value, Text)
                if Index then
                    TableRemove(InputList.Value, Index)

                    for _, child in ipairs(Items["ListArea"].Instance:GetChildren()) do
                        if child:IsA("Frame") and child.Name == Text then
                            local Info = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                            TweenService:Create(child, Info, {Size = UDim2New(1, 0, 0, 0), BackgroundTransparency = 1}):Play()

                             for _, desc in ipairs(child:GetDescendants()) do
                                if desc:IsA("UIStroke") then
                                    TweenService:Create(desc, Info, {Transparency = 1}):Play()
                                elseif desc:IsA("TextLabel") or desc:IsA("TextButton") then
                                     TweenService:Create(desc, Info, {TextTransparency = 1, BackgroundTransparency = 1}):Play()
                                elseif desc:IsA("ImageLabel") then
                                     TweenService:Create(desc, Info, {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
                                end
                            end

                            task.delay(0.35, function()
                                child:Destroy()
                            end)
                            break
                        end
                    end

                    if InputList.Callback then
                        Library:SafeCall(InputList.Callback, InputList.Value)
                    end
                end
            end

            function InputList:Add(Text)
                if not Library then return end
                if Text == "" or TableFind(InputList.Value, Text) then return end

                TableInsert(InputList.Value, Text)

                local ItemFrame = Instances:Create("Frame", {
                    Parent = Items["ListArea"].Instance,
                    Name = Text,
                    Size = UDim2New(1, 0, 0, 0),
                    BackgroundColor3 = FromRGB(27, 26, 29),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 2
                }) ItemFrame:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = ItemFrame.Instance,
                    CornerRadius = UDimNew(0, 4)
                })

                local ItemStroke = Instances:Create("UIStroke", {
                    Parent = ItemFrame.Instance,
                    Name = "\0",
                    Color = FromRGB(35, 33, 38),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Transparency = 1
                }) ItemStroke:AddToTheme({Color = "Outline"})

                local ItemText = Instances:Create("TextLabel", {
                    Parent = ItemFrame.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    Text = Text,
                    Size = UDim2New(1, -40, 1, 0),
                    Position = UDim2New(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    TextTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextSize = 13,
                    ZIndex = 2
                }) ItemText:AddToTheme({TextColor3 = "Text"})

                -- Remove Button (Square, Black background)
                local RemoveButton = Instances:Create("TextButton", {
                    Parent = ItemFrame.Instance,
                    Name = "\0",
                    Text = "",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    Size = UDim2New(0, 20, 0, 20),
                    Position = UDim2New(1, -25, 0.5, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundColor3 = FromRGB(0, 0, 0), -- Black
                    BackgroundTransparency = 1, -- Start transparent to match frame
                    TextTransparency = 1,
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    TextSize = 14,
                    ZIndex = 2
                })

                local RemoveIconData = Library:GetCustomIcon("trash-2")
                local RemoveIcon = Instances:Create("ImageLabel", {
                    Parent = RemoveButton.Instance,
                    Name = "\0",
                    Image = RemoveIconData and RemoveIconData.Url or "",
                    ImageRectOffset = RemoveIconData and RemoveIconData.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = RemoveIconData and RemoveIconData.ImageRectSize or Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 12, 0, 12),
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    ZIndex = 3,
                    ImageColor3 = FromRGB(255, 255, 255),
                    ImageTransparency = 1
                })

                local RemoveButtonStroke = Instances:Create("UIStroke", {
                    Parent = RemoveButton.Instance,
                    Name = "\0",
                    Color = FromRGB(60, 60, 60),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Transparency = 1
                })

                -- Red animation for Remove Button
                RemoveButton:OnHover(function()
                     RemoveButtonStroke:Tween(nil, {Color = FromRGB(255, 60, 60)})
                     RemoveIcon:Tween(nil, {ImageColor3 = FromRGB(255, 60, 60)})
                end)

                RemoveButton:OnHoverLeave(function()
                     RemoveButtonStroke:Tween(nil, {Color = FromRGB(60, 60, 60)})
                     RemoveIcon:Tween(nil, {ImageColor3 = FromRGB(255, 255, 255)})
                end)

                ItemFrame:OnHover(function()
                    RemoveButton:Tween(nil, {BackgroundTransparency = 0})
                    RemoveIcon:Tween(nil, {ImageTransparency = 0})
                    RemoveButtonStroke:Tween(nil, {Transparency = 0})
                end)

                ItemFrame:OnHoverLeave(function()
                    RemoveButton:Tween(nil, {BackgroundTransparency = 1})
                    RemoveIcon:Tween(nil, {ImageTransparency = 1})
                    RemoveButtonStroke:Tween(nil, {Transparency = 1})
                end)

                RemoveButton:Connect("MouseButton1Click", function()
                    InputList:Remove(Text)
                end)

                if InputList.Callback then
                    Library:SafeCall(InputList.Callback, InputList.Value)
                end

                Library:Thread(function()
                    ItemFrame:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 0, 30), BackgroundTransparency = 0})
                    ItemStroke:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Transparency = 0})
                    ItemText:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0})
                end)
            end

            Items["AddButton"]:Connect("MouseButton1Click", function()
                local Text = Items["Input"].Instance.Text
                if Text ~= "" then
                    InputList:Add(Text)
                    Items["Input"].Instance.Text = ""
                end
            end)

            Items["Input"]:Connect("FocusLost", function(Enter)
                if Enter then
                    local Text = Items["Input"].Instance.Text
                    if Text ~= "" then
                        InputList:Add(Text)
                        Items["Input"].Instance.Text = ""
                    end
                end
            end)

            if InputList.Section.Page and InputList.Section.Page.Active then
                InputList:RefreshPosition(true)
            end

            InputList.Section.Elements[#InputList.Section.Elements+1] = InputList

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["InputList"].Instance)
            end

            return InputList
        end
    end

        Library.Sections.Discord = function(self, Data)
            Data = Data or {}

            local Discord = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or Data.ServerName or "Discord Server",
                InviteLink = Data.InviteLink or Data.invite or "",
                TargetServerID = Data.TargetServerID or Data.id or nil,
            }

            -- Chat preview messages: user-supplied or built-in defaults
            local Messages = Data.Messages or Data.messages or {
                {User = "Member",  Text = "Welcome to the server!"},
                {User = "Support", Text = "Ask us anything, anytime."},
                {User = "Dev",     Text = "New update just dropped! 🎉"},
            }
            local MSG_COUNT = math.min(#Messages, 3)

            -- Layout constants (absolute heights, no UIListLayout on outer frame)
            local BADGE_H  = 18   -- "JOIN OUR COMMUNITY" pill row
            local GAP_H    = 6    -- gap between badge and card
            local CARD_H   = 90   -- main server info card
            local SEP_H    = 10   -- thin separator before chat
            local MSG_H    = 28   -- height per message row
            local CHAT_H   = SEP_H + (MSG_COUNT * MSG_H)

            -- Absolute Y origins for each child (used in RefreshPosition)
            local Y_BADGE  = 0
            local Y_CARD   = BADGE_H + GAP_H               -- 24
            local Y_CHAT   = Y_CARD  + CARD_H + GAP_H      -- 120

            local TOTAL_H  = Y_CHAT + CHAT_H               -- 208 with 3 msgs

            local InviteCode = Discord.InviteLink:gsub("https://discord.gg/", ""):gsub("https://discord.com/invite/", ""):gsub("discord.gg/", "")

            local Items = {} do

                -- ── Outer container ──────────────────────────────────────────
                Items["Discord"] = Instances:Create("Frame", {
                    Parent = Discord.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, TOTAL_H),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                })

                -- ── "JOIN OUR COMMUNITY" badge ────────────────────────────────
                Items["BadgeRow"] = Instances:Create("Frame", {
                    Parent = Items["Discord"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, Y_BADGE),
                    Size = UDim2New(1, 0, 0, BADGE_H),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                })

                Items["BadgePill"] = Instances:Create("Frame", {
                    Parent = Items["BadgeRow"].Instance,
                    Name = "\0",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, BADGE_H),
                    BackgroundTransparency = 0.72,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    BackgroundColor3 = FromRGB(151, 69, 186),
                })  Items["BadgePill"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["BadgePill"].Instance,
                    CornerRadius = UDimNew(1, 0),
                })
                Instances:Create("UIPadding", {
                    Parent = Items["BadgePill"].Instance,
                    PaddingLeft  = UDimNew(0, 7),
                    PaddingRight = UDimNew(0, 7),
                })

                Instances:Create("TextLabel", {
                    Parent = Items["BadgePill"].Instance,
                    Name = "\0",
                    FontFace = Font.fromEnum(Enum.Font.GothamBold),
                    TextColor3 = FromRGB(255, 255, 255),
                    Text = "JOIN OUR COMMUNITY",
                    TextSize = 9,
                    Size = UDim2New(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 3,
                })

                -- ── Main info card ────────────────────────────────────────────
                Items["Card"] = Instances:Create("Frame", {
                    Parent = Items["Discord"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 0, 0, Y_CARD),
                    Size = UDim2New(1, 0, 0, CARD_H),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    BackgroundColor3 = FromRGB(22, 21, 25),
                })  Items["Card"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Card"].Instance,
                    CornerRadius = UDimNew(0, 6),
                })
                Instances:Create("UIStroke", {
                    Parent = Items["Card"].Instance,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Thickness = 1,
                    Transparency = 0.35,
                    Color = FromRGB(60, 58, 65),
                }):AddToTheme({Color = "Outline"})

                -- Purple accent strip across the top of the card
                Items["AccentBar"] = Instances:Create("Frame", {
                    Parent = Items["Card"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 2),
                    Position = UDim2New(0, 0, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 3,
                    BackgroundColor3 = FromRGB(151, 69, 186),
                })  Items["AccentBar"]:AddToTheme({BackgroundColor3 = "Accent"})
                -- Soft gradient so the bar fades toward the edges
                Instances:Create("UIGradient", {
                    Parent = Items["AccentBar"].Instance,
                    Transparency = NumSequence{
                        NumSequenceKeypoint(0, 0.6),
                        NumSequenceKeypoint(0.5, 0),
                        NumSequenceKeypoint(1, 0.6),
                    },
                })

                -- ── Server icon ───────────────────────────────────────────────
                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Card"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 46, 0, 46),
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 14, 0.5, 1),
                    BackgroundColor3 = FromRGB(28, 26, 32),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    Image = "",
                })  Items["Icon"]:AddToTheme({BackgroundColor3 = "Background"})
                Instances:Create("UICorner", {
                    Parent = Items["Icon"].Instance,
                    CornerRadius = UDimNew(0, 10),
                })
                -- Accent ring around icon
                Instances:Create("UIStroke", {
                    Parent = Items["Icon"].Instance,
                    Color = FromRGB(151, 69, 186),
                    Thickness = 2,
                    Transparency = 0.35,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }):AddToTheme({Color = "Accent"})
                -- Gradient overlay on icon background
                Instances:Create("UIGradient", {
                    Parent = Items["Icon"].Instance,
                    Rotation = -115,
                    Enabled = true,
                    Color = RGBSequence{
                        RGBSequenceKeypoint(0, FromRGB(255, 255, 255)),
                        RGBSequenceKeypoint(1, FromRGB(143, 143, 143)),
                    },
                }):AddToTheme({Color = function()
                    return RGBSequence{
                        RGBSequenceKeypoint(0, Library.Theme.Accent),
                        RGBSequenceKeypoint(1, Library.Theme.AccentGradient),
                    }
                end})

                Items["IconText"] = Instances:Create("TextLabel", {
                    Parent = Items["Icon"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = string.sub(Discord.Name, 1, 1):upper(),
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.05,
                    TextSize = 20,
                    FontFace = Font.fromEnum(Enum.Font.GothamBold),
                    ZIndex = 4,
                })

                -- ── Server name ───────────────────────────────────────────────
                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Card"].Instance,
                    Name = "\0",
                    FontFace = Font.fromEnum(Enum.Font.GothamBold),
                    TextColor3 = FromRGB(235, 235, 235),
                    Text = Discord.Name,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2New(1, -158, 0, 16),
                    Position = UDim2New(0, 70, 0, 18),
                    BackgroundTransparency = 1,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 3,
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                -- Thin divider under server name
                Instances:Create("Frame", {
                    Parent = Items["Card"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 70, 0, 37),
                    Size = UDim2New(1, -160, 0, 1),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0.7,
                    ZIndex = 3,
                    BackgroundColor3 = FromRGB(60, 58, 65),
                }):AddToTheme({BackgroundColor3 = "Outline"})

                -- ── Online stat ───────────────────────────────────────────────
                local OnlineRow = Instances:Create("Frame", {
                    Parent = Items["Card"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 70, 0, 44),
                    Size = UDim2New(1, -158, 0, 14),
                    BorderSizePixel = 0,
                    ZIndex = 3,
                })
                Instances:Create("UIListLayout", {
                    Parent = OnlineRow.Instance,
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDimNew(0, 5),
                })

                Items["OnlineDot"] = Instances:Create("Frame", {
                    Parent = OnlineRow.Instance,
                    Name = "\0",
                    Size = UDim2New(0, 7, 0, 7),
                    BackgroundColor3 = FromRGB(35, 165, 89),
                    BorderSizePixel = 0,
                    ZIndex = 4,
                })
                Instances:Create("UICorner", {Parent = Items["OnlineDot"].Instance, CornerRadius = UDimNew(1, 0)})

                local Pulse = Instances:Create("Frame", {
                    Parent = Items["OnlineDot"].Instance,
                    Name = "Pulse",
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundColor3 = FromRGB(35, 165, 89),
                    BackgroundTransparency = 0.55,
                    ZIndex = 3,
                })
                Instances:Create("UICorner", {Parent = Pulse.Instance, CornerRadius = UDimNew(1, 0)})

                Library:Thread(function()
                    TweenService:Create(Pulse.Instance,
                        TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1),
                        {Size = UDim2New(2.2, 0, 2.2, 0), BackgroundTransparency = 1}
                    ):Play()
                end)

                Items["OnlineText"] = Instances:Create("TextLabel", {
                    Parent = OnlineRow.Instance,
                    Name = "\0",
                    FontFace = Font.fromEnum(Enum.Font.GothamMedium),
                    TextColor3 = FromRGB(35, 165, 89),
                    Text = "Loading...",
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 4,
                })

                -- ── Total stat ────────────────────────────────────────────────
                local TotalRow = Instances:Create("Frame", {
                    Parent = Items["Card"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 70, 0, 62),
                    Size = UDim2New(1, -158, 0, 14),
                    BorderSizePixel = 0,
                    ZIndex = 3,
                })
                Instances:Create("UIListLayout", {
                    Parent = TotalRow.Instance,
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDimNew(0, 5),
                })

                Items["TotalDot"] = Instances:Create("Frame", {
                    Parent = TotalRow.Instance,
                    Name = "\0",
                    Size = UDim2New(0, 7, 0, 7),
                    BackgroundColor3 = FromRGB(110, 110, 120),
                    BorderSizePixel = 0,
                    ZIndex = 4,
                })
                Instances:Create("UICorner", {Parent = Items["TotalDot"].Instance, CornerRadius = UDimNew(1, 0)})

                Items["TotalText"] = Instances:Create("TextLabel", {
                    Parent = TotalRow.Instance,
                    Name = "\0",
                    FontFace = Font.fromEnum(Enum.Font.GothamMedium),
                    TextColor3 = FromRGB(110, 110, 120),
                    Text = "Loading...",
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 4,
                })

                -- ── Join button ───────────────────────────────────────────────
                Items["JoinButton"] = Instances:Create("TextButton", {
                    Parent = Items["Card"].Instance,
                    Name = "\0",
                    Text = "Join",
                    FontFace = Font.fromEnum(Enum.Font.GothamBold),
                    TextColor3 = FromRGB(255, 255, 255),
                    BackgroundColor3 = FromRGB(151, 69, 186),
                    Size = UDim2New(0, 60, 0, 28),
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, -13, 0.5, 1),
                    AutoButtonColor = false,
                    TextSize = 12,
                    ZIndex = 3,
                    BorderSizePixel = 0,
                })  Items["JoinButton"]:AddToTheme({BackgroundColor3 = "Accent"})
                Instances:Create("UICorner", {
                    Parent = Items["JoinButton"].Instance,
                    CornerRadius = UDimNew(0, 5),
                })
                -- Subtle shine overlay on button
                Instances:Create("UIGradient", {
                    Parent = Items["JoinButton"].Instance,
                    Rotation = -90,
                    Color = RGBSequence{
                        RGBSequenceKeypoint(0, FromRGB(255, 255, 255)),
                        RGBSequenceKeypoint(1, FromRGB(200, 200, 200)),
                    },
                    Transparency = NumSequence{
                        NumSequenceKeypoint(0, 0.5),
                        NumSequenceKeypoint(1, 0.82),
                    },
                })

                Items["JoinButton"]:OnHover(function()
                    Items["JoinButton"]:Tween(TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Library.Theme.AccentGradient or FromRGB(109, 43, 139)
                    })
                end)
                Items["JoinButton"]:OnHoverLeave(function()
                    Items["JoinButton"]:Tween(TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Library.Theme.Accent or FromRGB(151, 69, 186)
                    })
                end)

                -- ── Chat preview ──────────────────────────────────────────────
                if MSG_COUNT > 0 then
                    Items["ChatCard"] = Instances:Create("Frame", {
                        Parent = Items["Discord"].Instance,
                        Name = "\0",
                        Position = UDim2New(0, 0, 0, Y_CHAT),
                        Size = UDim2New(1, 0, 0, CHAT_H),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                    })

                    -- Separator
                    Instances:Create("Frame", {
                        Parent = Items["ChatCard"].Instance,
                        Name = "\0",
                        AnchorPoint = Vector2New(0, 0),
                        Position = UDim2New(0, 0, 0, 4),
                        Size = UDim2New(1, 0, 0, 1),
                        BackgroundTransparency = 0.65,
                        BorderSizePixel = 0,
                        ZIndex = 3,
                        BackgroundColor3 = FromRGB(55, 53, 60),
                    }):AddToTheme({BackgroundColor3 = "Outline"})

                    for i = 1, MSG_COUNT do
                        local msg = Messages[i]
                        local yOff = SEP_H + (i - 1) * MSG_H

                        local MsgRow = Instances:Create("Frame", {
                            Parent = Items["ChatCard"].Instance,
                            Name = "\0",
                            BackgroundTransparency = 1,
                            Position = UDim2New(0, 0, 0, yOff),
                            Size = UDim2New(1, 0, 0, MSG_H),
                            BorderSizePixel = 0,
                            ZIndex = 2,
                        })

                        -- Avatar circle with accent gradient
                        local Avatar = Instances:Create("Frame", {
                            Parent = MsgRow.Instance,
                            Name = "\0",
                            AnchorPoint = Vector2New(0, 0.5),
                            Position = UDim2New(0, 2, 0.5, 0),
                            Size = UDim2New(0, 17, 0, 17),
                            BorderSizePixel = 0,
                            ZIndex = 3,
                            BackgroundColor3 = FromRGB(151, 69, 186),
                        })  Avatar:AddToTheme({BackgroundColor3 = "Accent"})
                        Instances:Create("UICorner", {Parent = Avatar.Instance, CornerRadius = UDimNew(1, 0)})
                        Instances:Create("UIGradient", {
                            Parent = Avatar.Instance,
                            Rotation = -115,
                            Color = RGBSequence{
                                RGBSequenceKeypoint(0, FromRGB(255, 255, 255)),
                                RGBSequenceKeypoint(1, FromRGB(143, 143, 143)),
                            },
                        }):AddToTheme({Color = function()
                            return RGBSequence{
                                RGBSequenceKeypoint(0, Library.Theme.Accent),
                                RGBSequenceKeypoint(1, Library.Theme.AccentGradient),
                            }
                        end})
                        Instances:Create("TextLabel", {
                            Parent = Avatar.Instance,
                            Name = "\0",
                            Size = UDim2New(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Text = string.sub(msg.User or "?", 1, 1):upper(),
                            TextColor3 = FromRGB(255, 255, 255),
                            TextSize = 9,
                            FontFace = Font.fromEnum(Enum.Font.GothamBold),
                            ZIndex = 4,
                        })

                        -- Username (accent color, small + bold)
                        Instances:Create("TextLabel", {
                            Parent = MsgRow.Instance,
                            Name = "\0",
                            AnchorPoint = Vector2New(0, 0.5),
                            Position = UDim2New(0, 25, 0.5, -6),
                            Size = UDim2New(0, 80, 0, 11),
                            BackgroundTransparency = 1,
                            Text = msg.User or "User",
                            TextColor3 = FromRGB(151, 69, 186),
                            TextSize = 10,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            FontFace = Font.fromEnum(Enum.Font.GothamBold),
                            ZIndex = 3,
                        }):AddToTheme({TextColor3 = "Accent"})

                        -- Message text
                        Instances:Create("TextLabel", {
                            Parent = MsgRow.Instance,
                            Name = "\0",
                            AnchorPoint = Vector2New(0, 0.5),
                            Position = UDim2New(0, 25, 0.5, 6),
                            Size = UDim2New(1, -30, 0, 11),
                            BackgroundTransparency = 1,
                            Text = msg.Text or "",
                            TextColor3 = FromRGB(160, 158, 168),
                            TextSize = 10,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            FontFace = Library.Font,
                            ZIndex = 3,
                        })
                    end
                end

            end  -- end Items do

            -- ── Slide-in animation ────────────────────────────────────────────
            function Discord:RefreshPosition(Bool)
                local TInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                if Bool then
                    Items["BadgeRow"]:Tween(TInfo, {Position = UDim2New(0, 0, 0, Y_BADGE)})
                    Items["Card"]:Tween(TInfo, {Position = UDim2New(0, 0, 0, Y_CARD)})
                    if Items["ChatCard"] then
                        Items["ChatCard"]:Tween(TInfo, {Position = UDim2New(0, 0, 0, Y_CHAT)})
                    end
                else
                    Items["BadgeRow"].Instance.Position  = UDim2New(0, 32, 0, Y_BADGE)
                    Items["Card"].Instance.Position      = UDim2New(0, 30, 0, Y_CARD)
                    if Items["ChatCard"] then
                        Items["ChatCard"].Instance.Position = UDim2New(0, 30, 0, Y_CHAT)
                    end
                end
            end

            -- ── Icon resolution (window logo > fallback letter) ───────────────
            local WindowIcon = Discord.Window and Discord.Window.Logo and Library:GetCustomIcon(Discord.Window.Logo) or nil
            local function ApplyWidgetIcon(fallbackName)
                if WindowIcon and WindowIcon.Url and WindowIcon.Url ~= "" then
                    Items["Icon"].Instance.Image = WindowIcon.Url
                    Items["Icon"].Instance.ImageRectOffset = WindowIcon.ImageRectOffset or Vector2New(0, 0)
                    Items["Icon"].Instance.ImageRectSize   = WindowIcon.ImageRectSize   or Vector2New(0, 0)
                    -- Disable the gradient when showing a real image
                    for _, child in Items["Icon"].Instance:GetChildren() do
                        if child:IsA("UIGradient") then child.Enabled = false end
                    end
                    Items["IconText"].Instance.Visible = false
                else
                    Items["IconText"].Instance.Text    = string.sub(fallbackName or Discord.Name, 1, 1):upper()
                    Items["IconText"].Instance.Visible = true
                end
            end

            ApplyWidgetIcon(Discord.Name)

            -- ── HTTP fetch (member counts + server name) ──────────────────────
            Library:Thread(function()
                if httpRequest and InviteCode ~= "" then
                    local Url = "https://discord.com/api/v9/invites/" .. InviteCode .. "?with_counts=true"
                    local response = httpRequest({ Url = Url, Method = "GET" })

                    if response.StatusCode == 200 then
                        local Success, data = pcall(function()
                            return HttpService:JSONDecode(response.Body)
                        end)

                        if Success and data then
                            if Discord.TargetServerID and data.guild and data.guild.id ~= Discord.TargetServerID then
                                warn("⚠️ WARNING: The invitation works, but the server ID does not match the one you entered.")
                                warn("Invitation ID: " .. (data.guild and data.guild.id or "N/A"))
                            else
                                local online = data.approximate_presence_count
                                local total  = data.approximate_member_count
                                local name   = data.guild.name

                                Items["Title"].Instance.Text = name or Discord.Name
                                ApplyWidgetIcon(name)
                                Items["OnlineText"].Instance.Text = online .. " Online"
                                Items["TotalText"].Instance.Text  = total  .. " Members"

                                print("--------------------------------")
                                print("✅ Server Verified: " .. (name or "Unknown"))
                                print("🆔 Correct ID: " .. (data.guild.id or "N/A"))
                                print("🟢 Online: " .. online)
                                print("👥 Totals: " .. total)
                                print("--------------------------------")
                            end
                        end
                    else
                        Items["OnlineText"].Instance.Text = "Error"
                        Items["TotalText"].Instance.Text  = "Error"
                    end
                else
                    Items["OnlineText"].Instance.Text = "N/A"
                    Items["TotalText"].Instance.Text  = "N/A"
                end
            end)

            -- ── Join button click ─────────────────────────────────────────────
            Items["JoinButton"]:Connect("MouseButton1Click", function()
                if setclipboard then
                    setclipboard(Discord.InviteLink)
                    Items["JoinButton"].Instance.Text = "Copied!"
                    task.delay(2, function()
                        Items["JoinButton"].Instance.Text = "Join"
                    end)
                end
            end)

            if Discord.Section.Page and Discord.Section.Page.Active then
                Discord:RefreshPosition(true)
            end

            Discord.Section.Elements[#Discord.Section.Elements+1] = Discord

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Discord"].Instance)
            end

            return Discord
        end

        Library.Sections.Webhook = function(self, Data)
            Data = Data or {}

            local Webhook = {
                Window   = self.Window,
                Page     = self.Page,
                Section  = self,
                Name     = Data.Name     or Data.name     or "Webhook",
                URL      = Data.URL      or Data.url      or "",
                Events   = Data.Events   or Data.events   or {},
                Callback = Data.Callback or Data.callback or function() end,
                OnSend   = Data.OnSend   or Data.onSend   or nil,
            }

            local currentURL  = Webhook.URL
            local savedEvents = {}
            local isSending   = false
            local pingSelected = "No ping"

            for _, ev in ipairs(Webhook.Events) do
                savedEvents[ev.Flag] = ev.Default ~= nil and ev.Default or false
            end

            local TI     = TweenInfo.new(0.2,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            local TI_back = TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            local PING_OPTIONS = { "No ping", "@everyone", "@here" }
            local pingIndex    = 1

            local Items = {} do
                -- ── Root container ───────────────────────────────────────────
                Items["Webhook"] = Instances:Create("Frame", {
                    Parent              = Webhook.Section.Items["Content"].Instance,
                    Name                = "\0",
                    BackgroundTransparency = 1,
                    Size                = UDim2New(1, 0, 0, 0),
                    AutomaticSize       = Enum.AutomaticSize.Y,
                    BorderSizePixel     = 0,
                    ZIndex              = 2,
                    BackgroundColor3    = FromRGB(255, 255, 255),
                })
                Instances:Create("UIListLayout", {
                    Parent    = Items["Webhook"].Instance,
                    Name      = "\0",
                    Padding   = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                })

                -- ── Header row (same height & style as Toggle) ───────────────
                local HeaderRow = Instances:Create("TextButton", {
                    Parent           = Items["Webhook"].Instance,
                    Name             = "\0",
                    Text             = "",
                    AutoButtonColor  = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel  = 0,
                    Size             = UDim2New(1, 0, 0, 32),
                    ZIndex           = 2,
                    LayoutOrder      = 1,
                })

                -- Bell icon
                local BellData = Library:GetCustomIcon("bell-ring") or Library:GetCustomIcon("bell")
                local HeaderIcon = Instances:Create("ImageLabel", {
                    Parent              = HeaderRow.Instance,
                    Name                = "\0",
                    Image               = BellData and BellData.Url or "",
                    ImageRectOffset     = BellData and BellData.ImageRectOffset or Vector2New(0,0),
                    ImageRectSize       = BellData and BellData.ImageRectSize   or Vector2New(0,0),
                    ImageColor3         = Library.Theme.Accent,
                    BackgroundTransparency = 1,
                    AnchorPoint         = Vector2New(0, 0.5),
                    Position            = UDim2New(0, 0, 0.5, 0),
                    Size                = UDim2New(0, 14, 0, 14),
                    ZIndex              = 3,
                })
                HeaderIcon:AddToTheme({ImageColor3 = "Accent"})

                -- Name label
                Instances:Create("TextLabel", {
                    Parent              = HeaderRow.Instance,
                    Name                = "\0",
                    FontFace            = Library.Font,
                    Text                = Webhook.Name,
                    TextColor3          = FromRGB(235, 235, 235),
                    TextTransparency    = 0.15,
                    TextSize            = 14,
                    TextXAlignment      = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    BorderSizePixel     = 0,
                    AnchorPoint         = Vector2New(0, 0.5),
                    Position            = UDim2New(0, 20, 0.5, 0),
                    Size                = UDim2New(1, -60, 0, 16),
                    ZIndex              = 3,
                }):AddToTheme({TextColor3 = "Text"})

                -- Status dot (right side)
                Items["StatusDot"] = Instances:Create("Frame", {
                    Parent           = HeaderRow.Instance,
                    Name             = "\0",
                    Size             = UDim2New(0, 7, 0, 7),
                    AnchorPoint      = Vector2New(1, 0.5),
                    Position         = UDim2New(1, 0, 0.5, 0),
                    BackgroundColor3 = FromRGB(80, 78, 98),
                    BorderSizePixel  = 0,
                    ZIndex           = 3,
                })
                Instances:Create("UICorner", { Parent = Items["StatusDot"].Instance, CornerRadius = UDimNew(1, 0) })

                -- ── URL row (same style as Textbox element) ──────────────────
                local URLRow = Instances:Create("Frame", {
                    Parent           = Items["Webhook"].Instance,
                    Name             = "\0",
                    Size             = UDim2New(1, 0, 0, 26),
                    BackgroundColor3 = Library.Theme.Element,
                    BorderSizePixel  = 0,
                    ZIndex           = 2,
                    LayoutOrder      = 2,
                })
                URLRow:AddToTheme({BackgroundColor3 = "Element"})
                Instances:Create("UICorner", { Parent = URLRow.Instance, CornerRadius = UDimNew(0, 5) })
                Instances:Create("UIStroke", {
                    Parent       = URLRow.Instance,
                    Color        = Library.Theme.Outline,
                    Thickness    = 1,
                    Transparency = 0.5,
                }):AddToTheme({Color = "Outline"})

                local LockData = Library:GetCustomIcon("link")
                Instances:Create("ImageLabel", {
                    Parent              = URLRow.Instance,
                    Name                = "\0",
                    Image               = LockData and LockData.Url or "",
                    ImageRectOffset     = LockData and LockData.ImageRectOffset or Vector2New(0,0),
                    ImageRectSize       = LockData and LockData.ImageRectSize   or Vector2New(0,0),
                    ImageColor3         = FromRGB(100, 97, 120),
                    BackgroundTransparency = 1,
                    AnchorPoint         = Vector2New(0, 0.5),
                    Position            = UDim2New(0, 6, 0.5, 0),
                    Size                = UDim2New(0, 11, 0, 11),
                    ZIndex              = 3,
                })

                Items["URLBox"] = Instances:Create("TextBox", {
                    Parent              = URLRow.Instance,
                    Name                = "\0",
                    FontFace            = Library.Font,
                    Text                = currentURL,
                    PlaceholderText     = "https://discord.com/api/webhooks/...",
                    PlaceholderColor3   = FromRGB(70, 67, 90),
                    TextColor3          = FromRGB(200, 198, 218),
                    TextSize            = 11,
                    TextXAlignment      = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    BorderSizePixel     = 0,
                    ClearTextOnFocus    = false,
                    ClipsDescendants    = true,
                    TextTruncate        = Enum.TextTruncate.AtEnd,
                    AnchorPoint         = Vector2New(0, 0.5),
                    Position            = UDim2New(0, 22, 0.5, 0),
                    Size                = UDim2New(1, -28, 0, 18),
                    ZIndex              = 3,
                })

                Items["URLBox"].Instance.FocusLost:Connect(function()
                    currentURL = Items["URLBox"].Instance.Text
                    Library.Flags[Webhook.Name .. "_URL"] = currentURL
                    local hasURL = currentURL ~= "" and currentURL:find("discord") ~= nil
                    Items["StatusDot"].Instance.BackgroundColor3 = hasURL and FromRGB(34, 197, 94) or FromRGB(80, 78, 98)
                    Webhook.Callback("url_changed", currentURL)
                end)

                -- ── NOTIFY ON label (same style as category labels) ───────────
                if #Webhook.Events > 0 then
                    local NotifyLabel = Instances:Create("Frame", {
                        Parent           = Items["Webhook"].Instance,
                        Name             = "\0",
                        Size             = UDim2New(1, 0, 0, 18),
                        BackgroundTransparency = 1,
                        BorderSizePixel  = 0,
                        ZIndex           = 2,
                        LayoutOrder      = 3,
                    })
                    local bellSmall = Library:GetCustomIcon("bell")
                    Instances:Create("ImageLabel", {
                        Parent              = NotifyLabel.Instance,
                        Image               = bellSmall and bellSmall.Url or "",
                        ImageRectOffset     = bellSmall and bellSmall.ImageRectOffset or Vector2New(0,0),
                        ImageRectSize       = bellSmall and bellSmall.ImageRectSize   or Vector2New(0,0),
                        ImageColor3         = FromRGB(100, 97, 120),
                        BackgroundTransparency = 1,
                        AnchorPoint         = Vector2New(0, 0.5),
                        Position            = UDim2New(0, 0, 0.5, 0),
                        Size                = UDim2New(0, 10, 0, 10),
                        ZIndex              = 3,
                    })
                    Instances:Create("TextLabel", {
                        Parent              = NotifyLabel.Instance,
                        FontFace            = Library.Font,
                        Text                = "NOTIFY ON",
                        TextColor3          = FromRGB(100, 97, 120),
                        TextSize            = 11,
                        TextXAlignment      = Enum.TextXAlignment.Left,
                        BackgroundTransparency = 1,
                        BorderSizePixel     = 0,
                        AnchorPoint         = Vector2New(0, 0.5),
                        Position            = UDim2New(0, 14, 0.5, 0),
                        Size                = UDim2New(1, -14, 0, 12),
                        ZIndex              = 3,
                    })

                    -- ── Event rows (identical to Toggle rows) ─────────────────
                    for idx, evData in ipairs(Webhook.Events) do
                        local evEnabled = savedEvents[evData.Flag] == true

                        local EvRow = Instances:Create("Frame", {
                            Parent           = Items["Webhook"].Instance,
                            Name             = "\0",
                            BackgroundTransparency = 1,
                            BorderSizePixel  = 0,
                            Size             = UDim2New(1, 0, 0, 22),
                            ZIndex           = 2,
                            LayoutOrder      = 10 + idx,
                        })

                        -- Indicator (exact Toggle indicator)
                        local indSize = IsMobile and 18 or 24
                        local Indicator = Instances:Create("Frame", {
                            Parent           = EvRow.Instance,
                            Name             = "evInd" .. idx,
                            Size             = UDim2New(0, indSize, 0, indSize),
                            Position         = UDim2New(0, 0, 0.5, -math.floor(indSize/2)),
                            BorderSizePixel  = 0,
                            ZIndex           = 2,
                            BackgroundColor3 = evEnabled and FromRGB(255, 255, 255) or Library.Theme.Element,
                        })
                        if evEnabled then
                            Indicator:ChangeItemTheme({BackgroundColor3 = function() return FromRGB(255,255,255) end})
                        else
                            Indicator:AddToTheme({BackgroundColor3 = "Element"})
                        end
                        Instances:Create("UICorner", { Parent = Indicator.Instance, CornerRadius = UDimNew(0, 3) })

                        local IndStroke = Instances:Create("UIStroke", {
                            Parent          = Indicator.Instance,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                            Color           = Library.Theme.Outline,
                            Thickness       = 1,
                            Transparency    = evEnabled and 1 or 0.5,
                        })
                        IndStroke:AddToTheme({Color = "Outline"})

                        local IndGradient = Instances:Create("UIGradient", {
                            Parent   = Indicator.Instance,
                            Enabled  = evEnabled,
                            Rotation = -115,
                            Color    = RGBSequence{
                                RGBSequenceKeypoint(0, Library.Theme.Accent),
                                RGBSequenceKeypoint(1, Library.Theme.AccentGradient),
                            },
                        })
                        IndGradient:AddToTheme({Color = function()
                            return RGBSequence{
                                RGBSequenceKeypoint(0, Library.Theme.Accent),
                                RGBSequenceKeypoint(1, Library.Theme.AccentGradient),
                            }
                        end})

                        local _chkSz = indSize - 7
                        local CheckImg = Instances:Create("ImageLabel", {
                            Parent              = Indicator.Instance,
                            Image               = "rbxassetid://121760666525660",
                            BackgroundTransparency = 1,
                            AnchorPoint         = Vector2New(0.5, 0.5),
                            Position            = UDim2New(0.5, 0, 0.5, 0),
                            Size                = evEnabled and UDim2New(0, _chkSz, 0, _chkSz) or UDim2New(0, 0, 0, 0),
                            ImageTransparency   = evEnabled and 0 or 1,
                            ZIndex              = 3,
                            BorderSizePixel     = 0,
                        })

                        -- Icon (optional)
                        local textXOffset = indSize + 6
                        if evData.Icon then
                            local evIconD = Library:GetCustomIcon(evData.Icon)
                            local evIconInst = Instances:Create("ImageLabel", {
                                Parent              = EvRow.Instance,
                                Image               = evIconD and evIconD.Url or "",
                                ImageRectOffset     = evIconD and evIconD.ImageRectOffset or Vector2New(0,0),
                                ImageRectSize       = evIconD and evIconD.ImageRectSize   or Vector2New(0,0),
                                ImageColor3         = evEnabled and Library.Theme.Accent or FromRGB(75, 72, 95),
                                BackgroundTransparency = 1,
                                AnchorPoint         = Vector2New(0, 0.5),
                                Position            = UDim2New(0, textXOffset, 0.5, 0),
                                Size                = UDim2New(0, 13, 0, 13),
                                ZIndex              = 3,
                                Name                = "evIcon" .. idx,
                            })
                            if evEnabled then
                                evIconInst:AddToTheme({ImageColor3 = "Accent"})
                            end
                            textXOffset = textXOffset + 18
                        end

                        -- Label (same as Toggle Text)
                        Instances:Create("TextLabel", {
                            Parent              = EvRow.Instance,
                            Name                = "evLabel" .. idx,
                            FontFace            = Library.Font,
                            Text                = evData.Name or "Event",
                            TextColor3          = evEnabled and FromRGB(235, 235, 235) or FromRGB(160, 158, 178),
                            TextTransparency    = evEnabled and 0.15 or 0.45,
                            TextSize            = 14,
                            TextXAlignment      = Enum.TextXAlignment.Left,
                            BackgroundTransparency = 1,
                            BorderSizePixel     = 0,
                            AnchorPoint         = Vector2New(0, 0.5),
                            Position            = UDim2New(0, textXOffset, 0.5, 0),
                            Size                = UDim2New(1, -textXOffset, 0, 15),
                            ZIndex              = 3,
                        }):AddToTheme({TextColor3 = "Text"})

                        -- Click button
                        local evBtn = Instances:Create("TextButton", {
                            Parent              = EvRow.Instance,
                            Text                = "",
                            BackgroundTransparency = 1,
                            BorderSizePixel     = 0,
                            Size                = UDim2New(1, 0, 1, 0),
                            ZIndex              = 5,
                            AutoButtonColor     = false,
                        })

                        evBtn:Connect("MouseButton1Click", function()
                            evEnabled = not evEnabled
                            savedEvents[evData.Flag] = evEnabled
                            Library.Flags[evData.Flag] = evEnabled

                            local label = EvRow.Instance:FindFirstChild("evLabel" .. idx)
                            local icon  = EvRow.Instance:FindFirstChild("evIcon"  .. idx)

                            if evEnabled then
                                IndGradient.Instance.Enabled = true
                                Indicator:ChangeItemTheme({BackgroundColor3 = function() return FromRGB(255,255,255) end})
                                TweenService:Create(Indicator.Instance, TI, {BackgroundColor3 = FromRGB(255,255,255)}):Play()
                                TweenService:Create(IndStroke.Instance,  TI, {Transparency = 1}):Play()
                                TweenService:Create(CheckImg.Instance,   TI_back, {ImageTransparency = 0, Size = UDim2New(0,_chkSz,0,_chkSz)}):Play()
                                if label then TweenService:Create(label, TI, {TextColor3 = FromRGB(235,235,235), TextTransparency = 0.15}):Play() end
                                if icon  then
                                    TweenService:Create(icon, TI, {ImageColor3 = Library.Theme.Accent}):Play()
                                    local w = Library.ThemeMap and Library.ThemeMap[icon]
                                    if w then w.Properties = {ImageColor3 = "Accent"} end
                                end
                            else
                                IndGradient.Instance.Enabled = false
                                Indicator:ChangeItemTheme({BackgroundColor3 = "Element"})
                                TweenService:Create(Indicator.Instance, TI, {BackgroundColor3 = Library.Theme.Element}):Play()
                                TweenService:Create(IndStroke.Instance,  TI, {Transparency = 0.5}):Play()
                                TweenService:Create(CheckImg.Instance,   TI_back, {ImageTransparency = 1, Size = UDim2New(0,0,0,0)}):Play()
                                if label then TweenService:Create(label, TI, {TextColor3 = FromRGB(160,158,178), TextTransparency = 0.45}):Play() end
                                if icon  then
                                    TweenService:Create(icon, TI, {ImageColor3 = FromRGB(75,72,95)}):Play()
                                    local w = Library.ThemeMap and Library.ThemeMap[icon]
                                    if w then w.Properties = {ImageColor3 = function() return FromRGB(75,72,95) end} end
                                end
                            end

                            Webhook.Callback("event_toggled", evData.Flag, evEnabled)
                        end)
                    end
                end

                -- ── Ping row (same style as a Label row with right value) ─────
                -- Spacer before ping
                Instances:Create("Frame", {
                    Parent           = Items["Webhook"].Instance,
                    Name             = "\0",
                    Size             = UDim2New(1, 0, 0, 4),
                    BackgroundTransparency = 1,
                    BorderSizePixel  = 0,
                    ZIndex           = 1,
                    LayoutOrder      = 49,
                })
                local PingRow = Instances:Create("Frame", {
                    Parent           = Items["Webhook"].Instance,
                    Name             = "\0",
                    Size             = UDim2New(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    BorderSizePixel  = 0,
                    ZIndex           = 2,
                    LayoutOrder      = 50,
                })

                local AtData = Library:GetCustomIcon("at-sign")
                Instances:Create("ImageLabel", {
                    Parent              = PingRow.Instance,
                    Image               = AtData and AtData.Url or "",
                    ImageRectOffset     = AtData and AtData.ImageRectOffset or Vector2New(0,0),
                    ImageRectSize       = AtData and AtData.ImageRectSize   or Vector2New(0,0),
                    ImageColor3         = FromRGB(100, 97, 120),
                    BackgroundTransparency = 1,
                    AnchorPoint         = Vector2New(0, 0.5),
                    Position            = UDim2New(0, 0, 0.5, 0),
                    Size                = UDim2New(0, 13, 0, 13),
                    ZIndex              = 3,
                })
                Instances:Create("TextLabel", {
                    Parent              = PingRow.Instance,
                    FontFace            = Library.Font,
                    Text                = "Ping",
                    TextColor3          = FromRGB(160, 158, 178),
                    TextTransparency    = 0.3,
                    TextSize            = 14,
                    TextXAlignment      = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    BorderSizePixel     = 0,
                    AnchorPoint         = Vector2New(0, 0.5),
                    Position            = UDim2New(0, 18, 0.5, 0),
                    Size                = UDim2New(0.5, -18, 0, 15),
                    ZIndex              = 3,
                }):AddToTheme({TextColor3 = "Text"})

                local PingChevData = Library:GetCustomIcon("chevron-right")
                local PingChev = Instances:Create("ImageLabel", {
                    Parent              = PingRow.Instance,
                    Image               = PingChevData and PingChevData.Url or "",
                    ImageRectOffset     = PingChevData and PingChevData.ImageRectOffset or Vector2New(0,0),
                    ImageRectSize       = PingChevData and PingChevData.ImageRectSize   or Vector2New(0,0),
                    ImageColor3         = FromRGB(100, 97, 120),
                    BackgroundTransparency = 1,
                    AnchorPoint         = Vector2New(1, 0.5),
                    Position            = UDim2New(1, 0, 0.5, 0),
                    Size                = UDim2New(0, 10, 0, 10),
                    ZIndex              = 3,
                })

                Items["PingValue"] = Instances:Create("TextLabel", {
                    Parent              = PingRow.Instance,
                    FontFace            = Library.Font,
                    Text                = "No ping",
                    TextColor3          = Library.Theme.Accent,
                    TextTransparency    = 0,
                    TextSize            = 14,
                    TextXAlignment      = Enum.TextXAlignment.Right,
                    BackgroundTransparency = 1,
                    BorderSizePixel     = 0,
                    AnchorPoint         = Vector2New(1, 0.5),
                    Position            = UDim2New(1, -14, 0.5, 0),
                    Size                = UDim2New(0.5, -14, 0, 15),
                    ZIndex              = 3,
                })
                Items["PingValue"]:AddToTheme({TextColor3 = "Accent"})

                local PingBtn = Instances:Create("TextButton", {
                    Parent              = PingRow.Instance,
                    Text                = "",
                    BackgroundTransparency = 1,
                    BorderSizePixel     = 0,
                    Size                = UDim2New(1, 0, 1, 0),
                    ZIndex              = 5,
                    AutoButtonColor     = false,
                })
                PingBtn:Connect("MouseButton1Click", function()
                    pingIndex    = (pingIndex % #PING_OPTIONS) + 1
                    pingSelected = PING_OPTIONS[pingIndex]
                    Items["PingValue"].Instance.Text = pingSelected
                    TweenService:Create(PingChev.Instance, TI, {Rotation = 90}):Play()
                    task.delay(0.18, function() PingChev.Instance.Rotation = 0 end)
                    Webhook.Callback("ping_changed", pingSelected)
                end)

                -- ── Send Test button (same style as Button element) ───────────
                -- Spacer before Send button
                Instances:Create("Frame", {
                    Parent           = Items["Webhook"].Instance,
                    Name             = "\0",
                    Size             = UDim2New(1, 0, 0, 4),
                    BackgroundTransparency = 1,
                    BorderSizePixel  = 0,
                    ZIndex           = 1,
                    LayoutOrder      = 98,
                })
                Items["TestBtn"] = Instances:Create("TextButton", {
                    Parent           = Items["Webhook"].Instance,
                    Name             = "\0",
                    Text             = "",
                    AutoButtonColor  = false,
                    Size             = UDim2New(1, 0, 0, 32),
                    BackgroundColor3 = Library.Theme.Element,
                    BorderSizePixel  = 0,
                    ZIndex           = 2,
                    LayoutOrder      = 99,
                })
                Items["TestBtn"]:AddToTheme({BackgroundColor3 = "Element"})
                Instances:Create("UICorner", { Parent = Items["TestBtn"].Instance, CornerRadius = UDimNew(0, 5) })
                Instances:Create("UIStroke", {
                    Parent       = Items["TestBtn"].Instance,
                    Color        = Library.Theme.Outline,
                    Thickness    = 1,
                    Transparency = 0.5,
                }):AddToTheme({Color = "Outline"})

                -- Accent fill on hover (same as Button element)
                local TestAccent = Instances:Create("Frame", {
                    Parent           = Items["TestBtn"].Instance,
                    Name             = "\0",
                    Size             = UDim2New(0, 0, 1, 0),
                    AnchorPoint      = Vector2New(0.5, 0.5),
                    Position         = UDim2New(0.5, 0, 0.5, 0),
                    BackgroundColor3 = Library.Theme.Accent,
                    BackgroundTransparency = 1,
                    BorderSizePixel  = 0,
                    ZIndex           = 2,
                })
                TestAccent:AddToTheme({BackgroundColor3 = "Accent"})
                Instances:Create("UICorner", { Parent = TestAccent.Instance, CornerRadius = UDimNew(0, 5) })

                local SendIconData = Library:GetCustomIcon("send")
                Instances:Create("ImageLabel", {
                    Parent              = Items["TestBtn"].Instance,
                    Image               = SendIconData and SendIconData.Url or "",
                    ImageRectOffset     = SendIconData and SendIconData.ImageRectOffset or Vector2New(0,0),
                    ImageRectSize       = SendIconData and SendIconData.ImageRectSize   or Vector2New(0,0),
                    ImageColor3         = FromRGB(235, 235, 235),
                    BackgroundTransparency = 1,
                    AnchorPoint         = Vector2New(0.5, 0.5),
                    Position            = UDim2New(0.5, -32, 0.5, 0),
                    Size                = UDim2New(0, 13, 0, 13),
                    ZIndex              = 3,
                }):AddToTheme({ImageColor3 = "Text"})

                local _testLabel = Instances:Create("TextLabel", {
                    Parent              = Items["TestBtn"].Instance,
                    FontFace            = Library.Font,
                    Text                = "Send Test",
                    TextColor3          = FromRGB(235, 235, 235),
                    TextTransparency    = 0.15,
                    TextSize            = 13,
                    BackgroundTransparency = 1,
                    BorderSizePixel     = 0,
                    AnchorPoint         = Vector2New(0.5, 0.5),
                    Position            = UDim2New(0.5, 2, 0.5, 0),
                    Size                = UDim2New(0, 90, 0, 14),
                    ZIndex              = 3,
                })
                _testLabel:AddToTheme({TextColor3 = "Text"})
                Items["TestLabel"] = _testLabel

                local TI_btn = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

                Items["TestBtn"]:OnHover(function()
                    TweenService:Create(TestAccent.Instance, TI_btn, {Size = UDim2New(1,0,1,0), BackgroundTransparency = 0.88}):Play()
                end)
                Items["TestBtn"]:OnHoverLeave(function()
                    TweenService:Create(TestAccent.Instance, TI_btn, {Size = UDim2New(0,0,1,0), BackgroundTransparency = 1}):Play()
                end)

                Items["TestBtn"]:Connect("MouseButton1Click", function()
                    if isSending then return end

                    if Webhook.OnSend then
                        Webhook.OnSend(currentURL, pingSelected, savedEvents)
                        Items["TestLabel"].Instance.Text = "✓ Sent"
                        task.delay(2, function() Items["TestLabel"].Instance.Text = "Send Test" end)
                        return
                    end

                    if currentURL == "" or not currentURL:find("discord") then
                        Items["TestLabel"].Instance.Text = "⚠ Invalid URL"
                        task.delay(2, function() Items["TestLabel"].Instance.Text = "Send Test" end)
                        return
                    end

                    isSending = true
                    Items["TestLabel"].Instance.Text = "Sending..."
                    Items["StatusDot"].Instance.BackgroundColor3 = FromRGB(234, 179, 8)

                    local httpRequest = (syn and syn.request)
                        or (http and http.request) or http_request or request or nil

                    if httpRequest then
                        local ok, res = pcall(httpRequest, {
                            Url     = currentURL,
                            Method  = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body    = game:GetService("HttpService"):JSONEncode({
                                username   = "Imp Hub X",
                                avatar_url = "https://i.imgur.com/JnkWLXc.png",
                                embeds = {{
                                    title       = "✅ Webhook Test",
                                    description = "Connection successful!",
                                    color       = 9699539,
                                    footer      = { text = "Imp Hub X • " .. os.date("%H:%M:%S") },
                                }}
                            })
                        })

                        if ok and res and (res.StatusCode == 204 or res.StatusCode == 200) then
                            Items["StatusDot"].Instance.BackgroundColor3 = FromRGB(34, 197, 94)
                            Items["TestLabel"].Instance.Text = "✓ Sent"
                        else
                            local code = (ok and res and res.StatusCode) or "err"
                            Items["StatusDot"].Instance.BackgroundColor3 = FromRGB(239, 68, 68)
                            Items["TestLabel"].Instance.Text = "✗ Failed (" .. tostring(code) .. ")"
                        end
                    else
                        Items["TestLabel"].Instance.Text = "✗ No HTTP"
                        Items["StatusDot"].Instance.BackgroundColor3 = FromRGB(239, 68, 68)
                    end

                    task.delay(3, function()
                        isSending = false
                        Items["TestLabel"].Instance.Text = "Send Test"
                        local hasURL = currentURL ~= "" and currentURL:find("discord") ~= nil
                        Items["StatusDot"].Instance.BackgroundColor3 = hasURL and FromRGB(34, 197, 94) or FromRGB(80, 78, 98)
                    end)
                end)
            end

            -- init URL state
            if currentURL ~= "" and currentURL:find("discord") then
                Items["StatusDot"].Instance.BackgroundColor3 = FromRGB(34, 197, 94)
            end

            function Webhook:SetURL(url)
                currentURL = url
                Items["URLBox"].Instance.Text = url
                Library.Flags[Webhook.Name .. "_URL"] = url
                local hasURL = url ~= "" and url:find("discord") ~= nil
                Items["StatusDot"].Instance.BackgroundColor3 = hasURL and FromRGB(34, 197, 94) or FromRGB(80, 78, 98)
            end

            function Webhook:Send(content, embeds)
                if currentURL == "" then return false end
                local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or nil
                if not httpRequest then return false end
                local pingStr = pingSelected == "@everyone" and "@everyone " or pingSelected == "@here" and "@here " or ""
                local ok = pcall(httpRequest, {
                    Url     = currentURL,
                    Method  = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body    = game:GetService("HttpService"):JSONEncode({
                        username   = "Imp Hub X",
                        avatar_url = "https://i.imgur.com/JnkWLXc.png",
                        content    = content and (pingStr .. content) or (pingStr ~= "" and pingStr or nil),
                        embeds     = embeds or nil,
                    })
                })
                return ok
            end

            function Webhook:GetEveryone() return pingSelected == "@everyone" end
            function Webhook:GetHere()     return pingSelected == "@here"     end
            function Webhook:GetPing()     return pingSelected                end
            function Webhook:IsEventEnabled(flag) return savedEvents[flag] == true end
            function Webhook:SetOnSend(fn) Webhook.OnSend = fn end
            function Webhook:RefreshPosition(Bool) end

            if Webhook.Section.Page and Webhook.Section.Page.Active then
                Webhook:RefreshPosition(true)
            end

            Webhook.Section.Elements[#Webhook.Section.Elements + 1] = Webhook

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Webhook"].Instance)
            end

            return Webhook
        end

        Library.Sections.QuickPresets = function(self, Data)
            Data = Data or {}

            local QP = {
                Window   = self.Window,
                Page     = self.Page,
                Section  = self,
                Name     = Data.Name     or Data.name     or "Quick Presets",
                Presets  = Data.Presets  or Data.presets  or {},
                ToolTip  = Data.ToolTip  or Data.tooltip  or nil,
            }

            local Items = {} do
                Items["QP"] = Instances:Create("Frame", {
                    Parent              = QP.Section.Items["Content"].Instance,
                    Name                = "\0",
                    BackgroundTransparency = 1,
                    Size                = UDim2New(1, 0, 0, 0),
                    AutomaticSize       = Enum.AutomaticSize.Y,
                    BorderSizePixel     = 0,
                    ZIndex              = 2,
                })

                Instances:Create("UIListLayout", {
                    Parent    = Items["QP"].Instance,
                    Name      = "\0",
                    Padding   = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                })

                -- Label row
                if QP.Name ~= "" then
                    local LabelRow = Instances:Create("Frame", {
                        Parent           = Items["QP"].Instance,
                        Name             = "\0",
                        BackgroundTransparency = 1,
                        BorderSizePixel  = 0,
                        Size             = UDim2New(1, 0, 0, 15),
                        ZIndex           = 2,
                        LayoutOrder      = 1,
                    })
                    Instances:Create("TextLabel", {
                        Parent              = LabelRow.Instance,
                        Name                = "\0",
                        FontFace            = Library.Font,
                        Text                = QP.Name,
                        TextColor3          = FromRGB(235, 235, 235),
                        TextTransparency    = 0.3,
                        TextSize            = 14,
                        TextXAlignment      = Enum.TextXAlignment.Left,
                        BackgroundTransparency = 1,
                        BorderSizePixel     = 0,
                        AnchorPoint         = Vector2New(0, 0.5),
                        Position            = UDim2New(0, 0, 0.5, 0),
                        Size                = UDim2New(1, 0, 0, 15),
                        ZIndex              = 3,
                    }):AddToTheme({TextColor3 = "Text"})
                end

                -- Buttons row
                local BtnRow = Instances:Create("Frame", {
                    Parent           = Items["QP"].Instance,
                    Name             = "\0",
                    BackgroundTransparency = 1,
                    BorderSizePixel  = 0,
                    Size             = UDim2New(1, 0, 0, 26),
                    ZIndex           = 2,
                    LayoutOrder      = 2,
                })

                Instances:Create("UIListLayout", {
                    Parent              = BtnRow.Instance,
                    Name                = "\0",
                    FillDirection       = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment   = Enum.VerticalAlignment.Center,
                    Padding             = UDimNew(0, 6),
                    SortOrder           = Enum.SortOrder.LayoutOrder,
                })

                local count   = #QP.Presets
                local TI_btn  = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

                for idx, preset in ipairs(QP.Presets) do
                    local Btn = Instances:Create("TextButton", {
                        Parent           = BtnRow.Instance,
                        Name             = "\0",
                        Text             = "",
                        AutoButtonColor  = false,
                        Size             = UDim2New(1/count, -(6*(count-1)/count), 1, 0),
                        BackgroundColor3 = Library.Theme.Element,
                        BorderSizePixel  = 0,
                        ZIndex           = 3,
                        LayoutOrder      = idx,
                    })
                    Btn:AddToTheme({BackgroundColor3 = "Element"})
                    Instances:Create("UICorner", { Parent = Btn.Instance, CornerRadius = UDimNew(0, 5) })
                    Instances:Create("UIStroke", {
                        Parent       = Btn.Instance,
                        Color        = Library.Theme.Outline,
                        Thickness    = 1,
                        Transparency = 0.5,
                    }):AddToTheme({Color = "Outline"})

                    -- Accent fill on hover
                    local BtnAccent = Instances:Create("Frame", {
                        Parent           = Btn.Instance,
                        Name             = "\0",
                        Size             = UDim2New(0, 0, 1, 0),
                        AnchorPoint      = Vector2New(0.5, 0.5),
                        Position         = UDim2New(0.5, 0, 0.5, 0),
                        BackgroundColor3 = Library.Theme.Accent,
                        BackgroundTransparency = 1,
                        BorderSizePixel  = 0,
                        ZIndex           = 2,
                    })
                    BtnAccent:AddToTheme({BackgroundColor3 = "Accent"})
                    Instances:Create("UICorner", { Parent = BtnAccent.Instance, CornerRadius = UDimNew(0, 5) })

                    local BtnLabel = Instances:Create("TextLabel", {
                        Parent              = Btn.Instance,
                        Name                = "\0",
                        FontFace            = Library.Font,
                        Text                = preset.Name or ("Preset " .. idx),
                        TextColor3          = FromRGB(235, 235, 235),
                        TextTransparency    = 0.2,
                        TextSize            = 12,
                        BackgroundTransparency = 1,
                        BorderSizePixel     = 0,
                        AnchorPoint         = Vector2New(0.5, 0.5),
                        Position            = UDim2New(0.5, 0, 0.5, 0),
                        Size                = UDim2New(1, -4, 0, 14),
                        TextTruncate        = Enum.TextTruncate.AtEnd,
                        TextXAlignment      = Enum.TextXAlignment.Center,
                        ZIndex              = 4,
                    })
                    BtnLabel:AddToTheme({TextColor3 = "Text"})

                    Btn:OnHover(function()
                        TweenService:Create(BtnAccent.Instance, TI_btn, {Size = UDim2New(1,0,1,0), BackgroundTransparency = 0.85}):Play()
                        TweenService:Create(BtnLabel.Instance,  TI_btn, {TextTransparency = 0}):Play()
                    end)
                    Btn:OnHoverLeave(function()
                        TweenService:Create(BtnAccent.Instance, TI_btn, {Size = UDim2New(0,0,1,0), BackgroundTransparency = 1}):Play()
                        TweenService:Create(BtnLabel.Instance,  TI_btn, {TextTransparency = 0.2}):Play()
                    end)

                    Btn:Connect("MouseButton1Click", function()
                        -- flash accent
                        TweenService:Create(BtnAccent.Instance, TI_btn, {Size = UDim2New(1,0,1,0), BackgroundTransparency = 0.7}):Play()
                        task.delay(0.18, function()
                            TweenService:Create(BtnAccent.Instance, TI_btn, {BackgroundTransparency = 1, Size = UDim2New(0,0,1,0)}):Play()
                        end)

                        if preset.Values then
                            for flag, value in pairs(preset.Values) do
                                local setter = Library.SetFlags[flag]
                                if setter then
                                    Library:SafeCall(setter, value)
                                end
                            end
                        end

                        if preset.Callback then
                            Library:SafeCall(preset.Callback)
                        end
                    end)

                    if Data.ToolTip and preset.ToolTip then
                        Library:AddTooltip(preset.ToolTip, Btn.Instance)
                    end
                end
            end

            function QP:SetVisibility(Bool)
                Items["QP"].Instance.Visible = Bool
            end

            function QP:RefreshPosition(Bool) end

            if QP.Section.Page and QP.Section.Page.Active then
                QP:RefreshPosition(true)
            end

            QP.Section.Elements[#QP.Section.Elements + 1] = QP

            if QP.ToolTip then
                Library:AddTooltip(QP.ToolTip, Items["QP"].Instance)
            end

            return QP
        end

        Library.Sections.Divider = function(self, Data)
            Data = Data or {}

            local Divider = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Title = Data.Title or Data.title or nil
            }

            local Items = {} do
                local dividerHeight = Divider.Title and 12 or 8

                Items["Divider"] = Instances:Create("Frame", {
                    Parent = Divider.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, dividerHeight),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                if Divider.Title then
                    Items["Title"] = Instances:Create("TextLabel", {
                        Parent = Items["Divider"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(240, 240, 240),
                        Text = Divider.Title,
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2New(0, 0, 0, 10),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        TextSize = 10,
                        TextTransparency = 0.34,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                    Items["LeftLine"] = Instances:Create("Frame", {
                        Parent = Items["Divider"].Instance,
                        Name = "\0",
                        AnchorPoint = Vector2New(1, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        Size = UDim2New(0.5, 0, 0, 1),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(45, 45, 48),
                        BackgroundTransparency = 0.58
                    })  Items["LeftLine"]:AddToTheme({BackgroundColor3 = "Outline"})

                    Instances:Create("UIGradient", {
                        Parent = Items["LeftLine"].Instance,
                        Transparency = NumSequence{
                            NumSequenceKeypoint(0, 1),
                            NumSequenceKeypoint(0.8, 0.72),
                            NumSequenceKeypoint(1, 0.48)
                        }
                    })

                    Items["RightLine"] = Instances:Create("Frame", {
                        Parent = Items["Divider"].Instance,
                        Name = "\0",
                        AnchorPoint = Vector2New(0, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        Size = UDim2New(0.5, 0, 0, 1),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(45, 45, 48),
                        BackgroundTransparency = 0.58
                    })  Items["RightLine"]:AddToTheme({BackgroundColor3 = "Outline"})

                    Instances:Create("UIGradient", {
                        Parent = Items["RightLine"].Instance,
                        Transparency = NumSequence{
                            NumSequenceKeypoint(0, 0.48),
                            NumSequenceKeypoint(0.2, 0.72),
                            NumSequenceKeypoint(1, 1)
                        }
                    })

                    local function UpdateLines()
                        local HalfText = Items["Title"].Instance.TextBounds.X / 2
                        local Padding = 6
                        local EdgeMargin = 10

                        Items["LeftLine"].Instance.Position = UDim2New(0.5, -HalfText - Padding, 0.5, 0)
                        Items["RightLine"].Instance.Position = UDim2New(0.5, HalfText + Padding, 0.5, 0)

                        Items["LeftLine"].Instance.Size = UDim2New(0.5, -HalfText - Padding - EdgeMargin, 0, 1)
                        Items["RightLine"].Instance.Size = UDim2New(0.5, -HalfText - Padding - EdgeMargin, 0, 1)
                    end

                    Library:Connect(Items["Title"].Instance:GetPropertyChangedSignal("TextBounds"), UpdateLines)
                    UpdateLines()
                else
                    Items["Line"] = Instances:Create("Frame", {
                        Parent = Items["Divider"].Instance,
                        Name = "\0",
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        Size = UDim2New(1, -28, 0, 1),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(45, 45, 48),
                        BackgroundTransparency = 0.62
                    })  Items["Line"]:AddToTheme({BackgroundColor3 = "Outline"})

                    Instances:Create("UIGradient", {
                        Parent = Items["Line"].Instance,
                        Transparency = NumSequence{
                            NumSequenceKeypoint(0, 1),
                            NumSequenceKeypoint(0.3, 0.82),
                            NumSequenceKeypoint(0.5, 0.66),
                            NumSequenceKeypoint(0.7, 0.82),
                            NumSequenceKeypoint(1, 1)
                        }
                    })
                end
            end

            function Divider:RefreshPosition(Bool)
            end

            if Divider.Section.Page and Divider.Section.Page.Active then
                Divider:RefreshPosition(true)
            end

            Divider.Section.Elements[#Divider.Section.Elements+1] = Divider

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Divider"].Instance)
            end

            return Divider
        end

        Library.Sections.Log = function(self, Data)
            Data = Data or {}

            local Log = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Log",
                Title = Data.Title or Data.title or "CONTAINER",
                Description = Data.Description or Data.desc or "Click to view logs",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                
                IsOpen = false,
                Items = {}
            }

            local Items = {} do
                -- Button in the Section
                Items["Button"] = Instances:Create("TextButton", {
                    Parent = Log.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 45),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    AutoButtonColor = false,
                    Text = ""
                })

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    Text = Log.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 30, 0, 6),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Items["Description"] = Instances:Create("TextLabel", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(160, 160, 160),
                    Text = Log.Description,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 12),
                    AnchorPoint = Vector2New(0, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 30, 0, 24),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 12,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                -- Log Icon (Small List Icon)
                local ListIcon = Library:GetCustomIcon("list")
                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    Image = ListIcon and ListIcon.Url or "rbxassetid://10723415903",
                    ImageRectOffset = ListIcon and ListIcon.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = ListIcon and ListIcon.ImageRectSize or Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 20, 0, 20),
                    Position = UDim2New(1, -30, 0.5, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    ZIndex = 2,
                    ImageColor3 = FromRGB(180, 180, 180)
                })

                -- Modal Overlay (Full Screen Blocker)
                Items["ModalOverlay"] = Instances:Create("Frame", {
                    Parent = Log.Window.Items["MainFrame"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.5,
                    Visible = false,
                    ZIndex = 100
                })

                -- Modal Frame (Centered)
                Items["ModalFrame"] = Instances:Create("Frame", {
                    Parent = Items["ModalOverlay"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 380, 0, 250),
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BackgroundColor3 = FromRGB(20, 20, 23),
                    BorderSizePixel = 0,
                    ZIndex = 101
                })
                Instances:Create("UICorner", {
                    Parent = Items["ModalFrame"].Instance,
                    CornerRadius = UDimNew(0, 8)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["ModalFrame"].Instance,
                    Color = FromRGB(45, 45, 48),
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Thickness = 1
                })

                Items["ModalScale"] = Instances:Create("UIScale", {
                    Parent = Items["ModalFrame"].Instance,
                    Scale = 0
                })

                -- Modal Header
                Items["ModalHeader"] = Instances:Create("Frame", {
                    Parent = Items["ModalFrame"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 50),
                    BackgroundTransparency = 1,
                    ZIndex = 102
                })

                Items["ModalTitle"] = Instances:Create("TextLabel", {
                    Parent = Items["ModalHeader"].Instance,
                    Name = "\0",
                    Text = string.upper(Log.Title),
                    FontFace = Library.Font, -- Assuming default font is bold enough
                    TextColor3 = FromRGB(255, 255, 255),
                    TextSize = 14,
                    Size = UDim2New(1, -50, 1, 0),
                    Position = UDim2New(0, 20, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    ZIndex = 102
                })

                Items["CloseButton"] = Instances:Create("TextButton", {
                    Parent = Items["ModalHeader"].Instance,
                    Name = "\0",
                    Text = "",
                    Size = UDim2New(0, 50, 1, 0),
                    Position = UDim2New(1, -50, 0, 0),
                    BackgroundTransparency = 1,
                    AutoButtonColor = false,
                    ZIndex = 102
                })
                
                local CloseIcon = Library:GetCustomIcon("x")
                Items["CloseIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["CloseButton"].Instance,
                    Image = CloseIcon and CloseIcon.Url or "rbxassetid://130510492706892", -- Using library close icon if not found
                    ImageRectOffset = CloseIcon and CloseIcon.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = CloseIcon and CloseIcon.ImageRectSize or Vector2New(0, 0),
                    Size = UDim2New(0, 14, 0, 14),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    ImageColor3 = FromRGB(150, 150, 150),
                    ZIndex = 103
                })

                -- Divider Line below Header
                Instances:Create("Frame", {
                    Parent = Items["ModalHeader"].Instance,
                    Size = UDim2New(1, 0, 0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    BackgroundColor3 = FromRGB(40, 40, 43),
                    BorderSizePixel = 0,
                    ZIndex = 102
                })

                -- Scrolling Content
                Items["ModalContent"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["ModalFrame"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 1, -51),
                    Position = UDim2New(0, 0, 0, 51),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 4,
                    ScrollBarImageColor3 = FromRGB(60, 60, 63),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    CanvasSize = UDim2New(0, 0, 0, 0),
                    ZIndex = 102
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["ModalContent"].Instance,
                    Padding = UDimNew(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["ModalContent"].Instance,
                    PaddingTop = UDimNew(0, 15),
                    PaddingBottom = UDimNew(0, 15)
                })
            end

            function Log:SetOpen(Bool)
                Log.IsOpen = Bool
                
                if Bool then
                    Items["ModalOverlay"].Instance.Visible = true
                    Items["ModalOverlay"]:Tween(TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5})
                    
                    Items["ModalScale"]:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
                    Items["ModalFrame"]:Tween(TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
                else
                    Items["ModalOverlay"]:Tween(TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                    
                    Items["ModalScale"]:Tween(TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
                    Items["ModalFrame"]:Tween(TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                    
                    task.delay(0.25, function()
                        if not Log.IsOpen then
                            Items["ModalOverlay"].Instance.Visible = false
                        end
                    end)
                end
            end

            Items["Button"]:Connect("MouseButton1Click", function()
                Log:SetOpen(true)
            end)

            Items["CloseButton"]:Connect("MouseButton1Click", function()
                Log:SetOpen(false)
            end)

            function Log:AddInfo(Info)
                Info = Info or {}
                local Icon = Info.Icon or "file-text"
                local Title = Info.Title or "Information"
                local Content = Info.Content or ""

                local Card = Instances:Create("Frame", {
                    Parent = Items["ModalContent"].Instance,
                    Name = Title,
                    Size = UDim2New(0.92, 0, 0, 0),
                    BackgroundColor3 = FromRGB(27, 27, 30), -- Slightly lighter than bg
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BorderSizePixel = 0,
                    ZIndex = 103
                })
                Instances:Create("UICorner", {
                    Parent = Card.Instance,
                    CornerRadius = UDimNew(0, 6)
                })
                Instances:Create("UIStroke", {
                    Parent = Card.Instance,
                    Color = FromRGB(45, 45, 48),
                    Transparency = 0,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Thickness = 1
                })
                
                local HLayout = Instances:Create("UIListLayout", {
                    Parent = Card.Instance,
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDimNew(0, 15),
                    VerticalAlignment = Enum.VerticalAlignment.Top
                })
                
                Instances:Create("UIPadding", {
                    Parent = Card.Instance,
                    PaddingTop = UDimNew(0, 15),
                    PaddingBottom = UDimNew(0, 15),
                    PaddingLeft = UDimNew(0, 15),
                    PaddingRight = UDimNew(0, 15)
                })

                -- Icon Area
                local IconContainer = Instances:Create("Frame", {
                    Parent = Card.Instance,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 20, 1, 0), -- Placeholder width
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = 1,
                    ZIndex = 104
                })
                
                local IconInst = Instances:Create("ImageLabel", {
                    Parent = IconContainer.Instance,
                    Size = UDim2New(0, 20, 0, 20),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 2), -- Adjust vertical align slightly
                    ImageColor3 = FromRGB(180, 180, 180),
                    ZIndex = 104
                })
                
                local IconData = Library:GetCustomIcon(Icon)
                if IconData then
                    IconInst.Instance.Image = IconData.Url
                    IconInst.Instance.ImageRectOffset = IconData.ImageRectOffset
                    IconInst.Instance.ImageRectSize = IconData.ImageRectSize
                end
                
                -- Text Area
                local TextContainer = Instances:Create("Frame", {
                    Parent = Card.Instance,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, -35, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = 2,
                    ZIndex = 104
                })
                
                Instances:Create("UIListLayout", {
                    Parent = TextContainer.Instance,
                    FillDirection = Enum.FillDirection.Vertical,
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                -- Card Title
                Instances:Create("TextLabel", {
                    Parent = TextContainer.Instance,
                    Text = string.upper(Title),
                    FontFace = Font.fromEnum(Enum.Font.GothamBold),
                    TextColor3 = FromRGB(255, 255, 255),
                    TextSize = 13,
                    Size = UDim2New(1, 0, 0, 15),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = 1,
                    ZIndex = 104
                })
                
                -- Card Content
                Instances:Create("TextLabel", {
                    Parent = TextContainer.Instance,
                    Text = Content,
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(150, 150, 150),
                    TextSize = 13,
                    Size = UDim2New(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    LayoutOrder = 2,
                    ZIndex = 104
                })
                
                return Card
            end

            function Log:RemoveInfo(Title)
                for _, Child in pairs(Items["ModalContent"].Instance:GetChildren()) do
                    if Child:IsA("Frame") and Child.Name == Title then
                        Child:Destroy()
                    end
                end
            end
            
            function Log:Clear()
                for _, Child in pairs(Items["ModalContent"].Instance:GetChildren()) do
                    if Child:IsA("Frame") then
                        Child:Destroy()
                    end
                end
            end

            function Log:SetVisibility(Bool)
                Items["Button"].Instance.Visible = Bool
            end
            
            function Log:RefreshPosition(Bool)
                if Bool then
                    Items["Title"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 6)})
                    Items["Description"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 24)})
                    Items["Icon"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0})
                else
                    Items["Title"].Instance.Position = UDim2New(0, 30, 0, 6)
                    Items["Description"].Instance.Position = UDim2New(0, 30, 0, 24)
                    Items["Icon"].Instance.ImageTransparency = 1 
                end
            end

            if Log.Section.Page and Log.Section.Page.Active then
                Log:RefreshPosition(true)
            end

            Log.Section.Elements[#Log.Section.Elements+1] = Log

            if Data.ToolTip or Data.tooltip then
                Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Button"].Instance)
            end

            return Log
        end

    -- ─────────────────────────────────────────────────────────────────────────
    -- ProgressDropdown: visual priority chain editor
    -- ─────────────────────────────────────────────────────────────────────────
    Library.Sections.ProgressDropdown = function(self, Data)
        Data = Data or {}

        local PD = {
            Window  = self.Window,
            Page    = self.Page,
            Section = self,

            Title       = Data.Title or Data.title or Data.Name or Data.name or "Priority",
            Flag        = Data.Flag or Data.flag or Library:NextFlag(),
            Description = Data.Description or Data.description or "",
            Callback    = Data.Callback or Data.callback or function() end,

            Options  = {},
            IsOpen   = false,
        }

        -- Deep-copy options from Data
        for _, opt in ipairs(Data.Options or Data.options or {}) do
            TableInsert(PD.Options, {Name = opt.Name or opt.name, Order = opt.Order or opt.order or 1})
        end
        table.sort(PD.Options, function(a, b) return a.Order < b.Order end)

        -- Seed Flags so SaveConfig captures the initial order immediately
        do
            local seed = {}
            for _, opt in ipairs(PD.Options) do seed[#seed + 1] = {Name = opt.Name, Order = opt.Order} end
            Library.Flags[PD.Flag] = seed
        end

        -- ── UI Items ──────────────────────────────────────────────────────────
        local Items = {} do
            -- Container row (sits in section content list)
            Items["Row"] = Instances:Create("Frame", {
                Parent = PD.Section.Items["Content"].Instance,
                Name   = "\0",
                BackgroundTransparency = 1,
                Size   = UDim2New(1, 0, 0, 25),
                BorderSizePixel = 0,
                ZIndex = 2,
                BackgroundColor3 = FromRGB(255, 255, 255),
            })

            -- Title label (left side)
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Row"].Instance,
                Name   = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(240, 240, 240),
                TextTransparency = 0.30000001192092896,
                Text = PD.Title,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2New(0, 0, 0, 15),
                AnchorPoint = Vector2New(0, 0.5),
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0.5, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 2,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 255, 255),
            })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

            -- Trigger button (right side, mirrors Dropdown's RealDropdown)
            Items["TriggerButton"] = Instances:Create("TextButton", {
                Parent = Items["Row"].Instance,
                Name   = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(0, 0, 0),
                Text = "",
                AutoButtonColor = false,
                AnchorPoint = Vector2New(1, 0),
                Position = UDim2New(1, 0, 0, 0),
                Size = UDim2New(0, 125, 0, 25),
                BorderSizePixel = 0,
                ZIndex = 2,
                TextSize = 14,
                BackgroundColor3 = FromRGB(27, 26, 29),
            })  Items["TriggerButton"]:AddToTheme({BackgroundColor3 = "Element"})

            Instances:Create("UICorner", {
                Parent = Items["TriggerButton"].Instance,
                Name   = "\0",
                CornerRadius = UDimNew(0, 6),
            })

            -- Button label
            Items["ButtonLabel"] = Instances:Create("TextLabel", {
                Parent = Items["TriggerButton"].Instance,
                Name   = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(240, 240, 240),
                TextTransparency = 0.30000001192092896,
                Text   = "Priority",
                Size   = UDim2New(1, -40, 0, 15),
                AnchorPoint = Vector2New(0, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2New(0, 10, 0.5, -1),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 2,
                TextSize = 13,
                BackgroundColor3 = FromRGB(255, 255, 255),
            })  Items["ButtonLabel"]:AddToTheme({TextColor3 = "Text"})

            -- Divider line before arrow
            Items["Liner"] = Instances:Create("Frame", {
                Parent = Items["TriggerButton"].Instance,
                Name   = "\0",
                AnchorPoint = Vector2New(1, 0),
                Position = UDim2New(1, -25, 0, 0),
                Size = UDim2New(0, 2, 1, 0),
                ZIndex = 2,
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(34, 32, 36),
            })  Items["Liner"]:AddToTheme({BackgroundColor3 = "Outline"})

            -- Arrow icon (chevron-down from lucide)
            local ArrowIconData = Library:GetCustomIcon("chevron-down")
            Items["ArrowIcon"] = Instances:Create("ImageLabel", {
                Parent = Items["TriggerButton"].Instance,
                Name   = "\0",
                ImageColor3 = FromRGB(141, 141, 150),
                Size = UDim2New(0, 16, 0, 8),
                AnchorPoint = Vector2New(1, 0.5),
                Image = ArrowIconData and ArrowIconData.Url or "rbxassetid://123317177279443",
                ImageRectOffset = ArrowIconData and ArrowIconData.ImageRectOffset or Vector2New(0, 0),
                ImageRectSize  = ArrowIconData and ArrowIconData.ImageRectSize  or Vector2New(0, 0),
                BackgroundTransparency = 1,
                Position = UDim2New(1, -5, 0.5, 0),
                ZIndex = 2,
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255),
            })

            Items["ArrowGradient"] = Instances:Create("UIGradient", {
                Parent = Items["ArrowIcon"].Instance,
                Name   = "\0",
                Enabled = false,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(131, 131, 131)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))},
            })  Items["ArrowGradient"]:AddToTheme({Color = function()
                return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
            end})

            -- Floating option panel (starts in UnusedHolder, moved to Holder when open)
            Items["OptionHolder"] = Instances:Create("TextButton", {
                Parent = Library.UnusedHolder.Instance,
                Text   = "",
                AutoButtonColor = false,
                Name   = "\0",
                Visible = false,
                Position = UDim2New(0, 0, 0, 0),
                Size = UDim2New(0, 160, 0, 100),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(27, 25, 29),
            })  Items["OptionHolder"]:AddToTheme({BackgroundColor3 = "Background"})

            Instances:Create("UIStroke", {
                Parent = Items["OptionHolder"].Instance,
                Name   = "\0",
                Color  = FromRGB(35, 33, 38),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }):AddToTheme({Color = "Outline"})

            Instances:Create("UICorner", {
                Parent = Items["OptionHolder"].Instance,
                Name   = "\0",
                CornerRadius = UDimNew(0, 5),
            })

            -- Scrollable content inside panel
            Items["Holder"] = Instances:Create("ScrollingFrame", {
                Parent = Items["OptionHolder"].Instance,
                Name   = "\0",
                Active = true,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 2,
                Size = UDim2New(1, -8, 1, -8),
                Position = UDim2New(0, 4, 0, 4),
                BackgroundTransparency = 1,
                BackgroundColor3 = FromRGB(255, 255, 255),
                BorderSizePixel = 0,
                CanvasSize = UDim2New(0, 0, 0, 0),
            })  Items["Holder"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

            Instances:Create("UIListLayout", {
                Parent = Items["Holder"].Instance,
                Name   = "\0",
                Padding = UDimNew(0, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            Instances:Create("UIPadding", {
                Parent = Items["Holder"].Instance,
                Name   = "\0",
                PaddingTop = UDimNew(0, 3),
                PaddingBottom = UDimNew(0, 3),
                PaddingLeft = UDimNew(0, 2),
                PaddingRight = UDimNew(0, 2),
            })
        end

        -- Slide-in offsets (like Dropdown)
        Items["Text"].Instance.Position = UDim2New(0, 30, 0.5, 0)
        Items["TriggerButton"].Instance.Position = UDim2New(1, 30, 0, 0)

        -- ── Mini-picker state ────────────────────────────────────────────────
        local MiniPicker = {Frame = nil, RS = nil, OwnerOpt = nil}

        local function CloseMiniPicker()
            if MiniPicker.RS    then MiniPicker.RS:Disconnect(); MiniPicker.RS = nil end
            if MiniPicker.Frame then MiniPicker.Frame:Destroy(); MiniPicker.Frame = nil end
            MiniPicker.OwnerOpt = nil
        end

        -- ── Callback helper ──────────────────────────────────────────────────
        local function FireCallback()
            local sorted = {}
            for _, opt in ipairs(PD.Options) do
                sorted[#sorted + 1] = {Name = opt.Name, Order = opt.Order}
            end
            table.sort(sorted, function(a, b) return a.Order < b.Order end)
            Library.Flags[PD.Flag] = sorted
            Library:SafeCall(PD.Callback, sorted)
        end

        -- ── Row rendering ────────────────────────────────────────────────────
        local ROW_H  = 28
        local CONN_H = 14

        local function RenderRows()
            -- Destroy previous rows
            CloseMiniPicker()
            for _, child in ipairs(Items["Holder"].Instance:GetChildren()) do
                if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                    child:Destroy()
                end
            end

            -- Re-sort
            table.sort(PD.Options, function(a, b) return a.Order < b.Order end)

            local n = #PD.Options
            for i, opt in ipairs(PD.Options) do

                -- ── Option row ───────────────────────────────────────────────
                local rowFrame = Instances:Create("Frame", {
                    Parent = Items["Holder"].Instance,
                    Name   = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, ROW_H),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    LayoutOrder = (i * 2) - 1,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                })

                -- Hover background fill
                local hoverBg = Instances:Create("Frame", {
                    Parent = rowFrame.Instance,
                    Name   = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                })  hoverBg:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = hoverBg.Instance,
                    Name   = "\0",
                    CornerRadius = UDimNew(0, 4),
                })

                -- Order badge (rounded square, left side)
                local badge = Instances:Create("Frame", {
                    Parent = rowFrame.Instance,
                    Name   = "\0",
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 6, 0.5, 0),
                    Size = UDim2New(0, 20, 0, 20),
                    BorderSizePixel = 0,
                    ZIndex = 3,
                    BackgroundColor3 = FromRGB(34, 32, 38),
                })  badge:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = badge.Instance,
                    Name   = "\0",
                    CornerRadius = UDimNew(0, 4),
                })

                Instances:Create("UIStroke", {
                    Parent = badge.Instance,
                    Name   = "\0",
                    Thickness = 1,
                    Transparency = 0.55,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Color = FromRGB(60, 58, 65),
                }):AddToTheme({Color = "Outline"})

                -- Badge number
                Instances:Create("TextLabel", {
                    Parent = badge.Instance,
                    Name   = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.1,
                    Text = tostring(opt.Order),
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 4,
                    TextSize = 11,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                }):AddToTheme({TextColor3 = "Text"})

                -- Option name
                Instances:Create("TextLabel", {
                    Parent = rowFrame.Instance,
                    Name   = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = opt.Name,
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 34, 0.5, 0),
                    Size = UDim2New(1, -58, 0, 15),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 3,
                    TextSize = 13,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                }):AddToTheme({TextColor3 = "Text"})

                -- Edit hint (small chevron on right edge)
                local editChevron = Library:GetCustomIcon("chevron-right")
                Instances:Create("ImageLabel", {
                    Parent = rowFrame.Instance,
                    Name   = "\0",
                    Image  = editChevron and editChevron.Url or "rbxassetid://123317177279443",
                    ImageRectOffset = editChevron and editChevron.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize   = editChevron and editChevron.ImageRectSize   or Vector2New(0, 0),
                    ImageColor3 = FromRGB(141, 141, 150),
                    ImageTransparency = 0.5,
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, -6, 0.5, 0),
                    Size = UDim2New(0, 8, 0, 12),
                    BackgroundTransparency = 1,
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                }):AddToTheme({ImageColor3 = "Text"})

                -- Invisible click button over whole row
                local clickBtn = Instances:Create("TextButton", {
                    Parent = rowFrame.Instance,
                    Name   = "\0",
                    Text   = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    ZIndex = 5,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                })

                -- Hover feedback
                rowFrame:OnHover(function()
                    hoverBg:Tween(nil, {BackgroundTransparency = 0.85})
                end)
                rowFrame:OnHoverLeave(function()
                    hoverBg:Tween(nil, {BackgroundTransparency = 1})
                end)

                -- ── Mini-picker open/close ───────────────────────────────────
                local capturedOpt = opt
                local capturedRowInst = rowFrame.Instance

                clickBtn:Connect("MouseButton1Click", function()
                    -- Toggle: clicking the same row again closes
                    if MiniPicker.OwnerOpt == capturedOpt then
                        CloseMiniPicker()
                        return
                    end
                    CloseMiniPicker()

                    local numOpts = #PD.Options
                    local itemH   = 22
                    local padV    = 4
                    local pickerH = numOpts * itemH + padV * 2
                    local pickerW = 38

                    -- Build the mini-picker frame (raw InstanceNew — transient)
                    local pickerFrame = InstanceNew("Frame")
                    pickerFrame.Name = "\0"
                    pickerFrame.Size = UDim2New(0, pickerW, 0, pickerH)
                    pickerFrame.BackgroundColor3 = Library.Theme["Background"] or FromRGB(27, 25, 29)
                    pickerFrame.BorderSizePixel  = 0
                    pickerFrame.ZIndex = 20
                    pickerFrame.Parent = Library.Holder.Instance

                    local pStroke = InstanceNew("UIStroke")
                    pStroke.Color = Library.Theme["Outline"] or FromRGB(35, 33, 38)
                    pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    pStroke.Parent = pickerFrame

                    local pCorner = InstanceNew("UICorner")
                    pCorner.CornerRadius = UDimNew(0, 5)
                    pCorner.Parent = pickerFrame

                    local pLayout = InstanceNew("UIListLayout")
                    pLayout.Padding = UDimNew(0, 0)
                    pLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    pLayout.Parent = pickerFrame

                    local pPad = InstanceNew("UIPadding")
                    pPad.PaddingTop    = UDimNew(0, padV)
                    pPad.PaddingBottom = UDimNew(0, padV)
                    pPad.Parent = pickerFrame

                    -- One button per order number
                    for orderNum = 1, numOpts do
                        local isActive = (orderNum == capturedOpt.Order)

                        local pBtn = InstanceNew("TextButton")
                        pBtn.Name    = "\0"
                        pBtn.Size    = UDim2New(1, 0, 0, itemH)
                        pBtn.BackgroundTransparency = isActive and 0.7 or 1
                        pBtn.BackgroundColor3 = Library.Theme["Accent"] or FromRGB(124, 163, 255)
                        pBtn.Text    = tostring(orderNum)
                        pBtn.FontFace = Library.Font
                        pBtn.TextColor3 = FromRGB(240, 240, 240)
                        pBtn.TextTransparency = isActive and 0 or 0.3
                        pBtn.AutoButtonColor = false
                        pBtn.BorderSizePixel = 0
                        pBtn.TextSize = 12
                        pBtn.ZIndex   = 21
                        pBtn.LayoutOrder = orderNum
                        pBtn.Parent   = pickerFrame

                        if isActive then
                            local pBtnCorner = InstanceNew("UICorner")
                            pBtnCorner.CornerRadius = UDimNew(0, 3)
                            pBtnCorner.Parent = pBtn
                        end

                        -- Hover highlight
                        pBtn.MouseEnter:Connect(function()
                            if not isActive then
                                TweenService:Create(pBtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.88}):Play()
                                TweenService:Create(pBtn, TweenInfo.new(0.1), {BackgroundColor3 = Library.Theme["Element"] or FromRGB(34, 32, 38)}):Play()
                            end
                        end)
                        pBtn.MouseLeave:Connect(function()
                            if not isActive then
                                TweenService:Create(pBtn, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                            end
                        end)

                        local capturedOrder = orderNum
                        pBtn.MouseButton1Click:Connect(function()
                            -- Swap order with whoever currently holds capturedOrder
                            for _, o in ipairs(PD.Options) do
                                if o ~= capturedOpt and o.Order == capturedOrder then
                                    o.Order = capturedOpt.Order
                                    break
                                end
                            end
                            capturedOpt.Order = capturedOrder

                            -- Re-normalise to 1..N
                            table.sort(PD.Options, function(a, b) return a.Order < b.Order end)
                            for idx, o in ipairs(PD.Options) do o.Order = idx end

                            CloseMiniPicker()
                            RenderRows()
                            FireCallback()
                        end)
                    end

                    -- Track position every frame beside the row
                    MiniPicker.RS = RunService.RenderStepped:Connect(function()
                        if not pickerFrame.Parent then
                            MiniPicker.RS:Disconnect()
                            MiniPicker.RS = nil
                            return
                        end
                        pickerFrame.Position = UDim2New(
                            0, capturedRowInst.AbsolutePosition.X + capturedRowInst.AbsoluteSize.X + 4,
                            0, capturedRowInst.AbsolutePosition.Y
                        )
                    end)

                    MiniPicker.Frame    = pickerFrame
                    MiniPicker.OwnerOpt = capturedOpt
                end)

                -- ── Connector line between rows ──────────────────────────────
                if i < n then
                    local connFrame = Instances:Create("Frame", {
                        Parent = Items["Holder"].Instance,
                        Name   = "\0",
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, 0, 0, CONN_H),
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        LayoutOrder = i * 2,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                    })

                    -- Vertical pipe line (aligns with centre of badge)
                    Instances:Create("Frame", {
                        Parent = connFrame.Instance,
                        Name   = "\0",
                        AnchorPoint = Vector2New(0.5, 0),
                        Position = UDim2New(0, 16, 0, 0),
                        Size = UDim2New(0, 1, 1, 0),
                        BorderSizePixel = 0,
                        ZIndex = 3,
                        BackgroundTransparency = 0.5,
                        BackgroundColor3 = FromRGB(80, 80, 95),
                    }):AddToTheme({BackgroundColor3 = "Outline"})
                end
            end
        end

        -- ── Public API ───────────────────────────────────────────────────────

        function PD:Get()
            local sorted = {}
            for _, opt in ipairs(PD.Options) do
                sorted[#sorted + 1] = {Name = opt.Name, Order = opt.Order}
            end
            table.sort(sorted, function(a, b) return a.Order < b.Order end)
            return sorted
        end

        function PD:SetVisibility(Bool)
            Items["Row"].Instance.Visible = Bool
        end

        function PD:RefreshPosition(Bool)
            if Bool then
                Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                Items["TriggerButton"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0, 0)})
            else
                Items["Text"].Instance.Position = UDim2New(0, 30, 0.5, 0)
                Items["TriggerButton"].Instance.Position = UDim2New(1, 30, 0, 0)
            end
        end

        local Debounce    = false
        local RenderStepped

        function PD:SetOpen(Bool)
            if Debounce then return end
            PD.IsOpen = Bool
            Debounce  = true

            if PD.IsOpen then
                RenderRows()
                Items["OptionHolder"].Instance.Visible = true
                Items["OptionHolder"].Instance.Parent  = Library.Holder.Instance
                Items["ArrowIcon"]:Tween(nil, {Rotation = 180, ImageColor3 = FromRGB(255, 255, 255)})
                Items["ArrowGradient"].Instance.Enabled = true

                RenderStepped = RunService.RenderStepped:Connect(function()
                    local btn    = Items["TriggerButton"].Instance
                    local n      = #PD.Options
                    local contentH = n * ROW_H + math.max(0, n - 1) * CONN_H + 6
                    local h      = math.min(contentH, 220)
                    local w      = math.max(btn.AbsoluteSize.X, 160)
                    Items["OptionHolder"].Instance.Position = UDim2New(0, btn.AbsolutePosition.X, 0, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 5)
                    Items["OptionHolder"].Instance.Size     = UDim2New(0, w, 0, h)
                end)

                for _, v in Library.OpenFrames do
                    if v ~= PD and not PD.Section.IsSettings and type(v) == "table" and v.SetOpen then
                        v:SetOpen(false)
                    end
                end
                Library.OpenFrames[PD] = PD
            else
                CloseMiniPicker()
                if Library.OpenFrames[PD] then Library.OpenFrames[PD] = nil end
                if RenderStepped then RenderStepped:Disconnect(); RenderStepped = nil end
                Items["ArrowIcon"]:Tween(nil, {Rotation = 0, ImageColor3 = FromRGB(141, 141, 150)})
                Items["ArrowGradient"].Instance.Enabled = false
            end

            -- Fade descendants in / out (same pattern as Dropdown)
            local Descendants = Items["OptionHolder"].Instance:GetDescendants()
            TableInsert(Descendants, Items["OptionHolder"].Instance)

            local NewTween
            for _, Value in Descendants do
                local TransparencyProperty = Tween:GetProperty(Value)
                if not TransparencyProperty then continue end
                if not Value.ClassName:find("UI") then
                    Value.ZIndex = (PD.IsOpen and PD.Section.IsSettings and 8) or (PD.IsOpen and 3) or 1
                end
                if type(TransparencyProperty) == "table" then
                    for _, Property in TransparencyProperty do
                        NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                    end
                else
                    NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                end
            end

            NewTween.Tween.Completed:Connect(function()
                if not Library then return end
                Debounce = false
                Items["OptionHolder"].Instance.Visible = PD.IsOpen
                task.wait(0.2)
                if not Library then return end
                Items["OptionHolder"].Instance.Parent = not PD.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
            end)
        end

        -- Trigger button click
        Items["TriggerButton"]:Connect("MouseButton1Click", function()
            PD:SetOpen(not PD.IsOpen)
        end)

        -- Close on outside click
        local function IsMouseOverRawFrame(Frame)
            if not Frame then return false end
            local mp = Vector2New(Mouse.X, Mouse.Y)
            local ap = Frame.AbsolutePosition
            local as = Frame.AbsoluteSize
            return mp.X >= ap.X and mp.X <= ap.X + as.X
               and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y
        end

        Library:Connect(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local overMain = Library:IsMouseOverFrame(Items["OptionHolder"])
                local overMini = IsMouseOverRawFrame(MiniPicker.Frame)

                -- Click inside mini-picker: let the button handler run, touch nothing
                if overMini then return end

                -- Click outside both panels: close mini then main
                if not overMain then
                    CloseMiniPicker()
                    if PD.IsOpen then
                        PD:SetOpen(false)
                    end
                else
                    -- Click inside main panel but outside mini: only close mini
                    CloseMiniPicker()
                end
            end
        end)
        -- Hover effects
        Items["TriggerButton"]:OnHover(function()
            if PD.IsOpen then return end
            Items["ArrowIcon"]:Tween(nil, {ImageColor3 = FromRGB(255, 255, 255)})
            Items["ArrowGradient"].Instance.Enabled = true
        end)
        Items["TriggerButton"]:OnHoverLeave(function()
            if PD.IsOpen then return end
            Items["ArrowIcon"]:Tween(nil, {ImageColor3 = FromRGB(141, 141, 150)})
            Items["ArrowGradient"].Instance.Enabled = false
        end)

        if PD.Section.Page and PD.Section.Page.Active then
            PD:RefreshPosition(true)
        end

        PD.Section.Elements[#PD.Section.Elements + 1] = PD

        Library.SetFlags[PD.Flag] = function(Value)
            if type(Value) ~= "table" then return end
            for _, v in ipairs(Value) do
                for _, opt in ipairs(PD.Options) do
                    if opt.Name == (v.Name or v.name) then
                        opt.Order = v.Order or v.order or opt.Order
                    end
                end
            end
            table.sort(PD.Options, function(a, b) return a.Order < b.Order end)
            for idx, o in ipairs(PD.Options) do o.Order = idx end
            if PD.IsOpen then RenderRows() end
        end

        if Data.ToolTip or Data.tooltip then
            Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Row"].Instance)
        end

        return PD
    end
    -- ─────────────────────────────────────────────────────────────────────────

    -- TaskQueue: visual automation pipeline with animated active-task indicator
    -- ─────────────────────────────────────────────────────────────────────────
    Library.Sections.TaskQueue = function(self, Data)
        Data = Data or {}

        local TQ = {
            Window  = self.Window,
            Page    = self.Page,
            Section = self,

            Title       = Data.Title or Data.title or Data.Name or Data.name or "Task Queue",
            Flag        = Data.Flag  or Data.flag  or Library:NextFlag(),
            Callback    = Data.Callback or Data.callback or function() end,

            Tasks       = {},
            CurrentTask = 1,   -- 1-based index into sorted Tasks
        }

        -- Deep-copy and sort tasks
        for _, t in ipairs(Data.Tasks or Data.tasks or {}) do
            TableInsert(TQ.Tasks, {Name = t.Name or t.name, Order = t.Order or t.order or 1})
        end
        table.sort(TQ.Tasks, function(a, b) return a.Order < b.Order end)

        -- Seed Library.Flags so SaveConfig works immediately
        do
            local seed = {}
            for _, t in ipairs(TQ.Tasks) do seed[#seed + 1] = {Name = t.Name, Order = t.Order} end
            Library.Flags[TQ.Flag] = seed
        end

        local ROW_H    = 30    -- px per task row
        local HEADER_H = 25    -- px for title row

        -- ── Static UI (header + task list shell) ──────────────────────────────
        local Items = {} do

            -- Outer container sits in section content
            Items["Container"] = Instances:Create("Frame", {
                Parent = TQ.Section.Items["Content"].Instance,
                Name   = "\0",
                BackgroundTransparency = 1,
                Size   = UDim2New(1, 0, 0, HEADER_H + #TQ.Tasks * ROW_H),
                BorderSizePixel = 0,
                ZIndex = 2,
                BackgroundColor3 = FromRGB(255, 255, 255),
            })

            -- Header row
            Items["HeaderRow"] = Instances:Create("Frame", {
                Parent = Items["Container"].Instance,
                Name   = "\0",
                BackgroundTransparency = 1,
                Size   = UDim2New(1, 0, 0, HEADER_H),
                Position = UDim2New(0, 0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 2,
                BackgroundColor3 = FromRGB(255, 255, 255),
            })

            -- Title label (left)
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["HeaderRow"].Instance,
                Name   = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(240, 240, 240),
                TextTransparency = 0.30000001192092896,
                Text = TQ.Title,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2New(0, 0, 0, 15),
                AnchorPoint = Vector2New(0, 0.5),
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0.5, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 2,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 255, 255),
            })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

            -- Task count pill (right)
            Items["CountBadge"] = Instances:Create("Frame", {
                Parent = Items["HeaderRow"].Instance,
                Name   = "\0",
                AnchorPoint = Vector2New(1, 0.5),
                Position = UDim2New(1, 0, 0.5, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2New(0, 0, 0, 16),
                BorderSizePixel = 0,
                ZIndex = 2,
                BackgroundColor3 = FromRGB(34, 32, 38),
            })  Items["CountBadge"]:AddToTheme({BackgroundColor3 = "Element"})
            Instances:Create("UICorner", {Parent = Items["CountBadge"].Instance, CornerRadius = UDimNew(0, 4)})
            Instances:Create("UIPadding", {
                Parent = Items["CountBadge"].Instance,
                PaddingLeft = UDimNew(0, 6), PaddingRight = UDimNew(0, 6),
            })
            Items["CountLabel"] = Instances:Create("TextLabel", {
                Parent = Items["CountBadge"].Instance,
                Name   = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(240, 240, 240),
                TextTransparency = 0.3,
                Text = tostring(#TQ.Tasks) .. " tasks",
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2New(0, 0, 1, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 3,
                TextSize = 10,
                BackgroundColor3 = FromRGB(255, 255, 255),
            })  Items["CountLabel"]:AddToTheme({TextColor3 = "Text"})

            -- Task list shell (rows rendered here dynamically)
            Items["TaskList"] = Instances:Create("Frame", {
                Parent = Items["Container"].Instance,
                Name   = "\0",
                BackgroundTransparency = 1,
                Size   = UDim2New(1, 0, 0, #TQ.Tasks * ROW_H),
                Position = UDim2New(0, 0, 0, HEADER_H),
                BorderSizePixel = 0,
                ClipsDescendants = false,
                ZIndex = 2,
                BackgroundColor3 = FromRGB(255, 255, 255),
            })

            -- Active task highlight (tweens vertically when active task changes)
            Items["ActiveHighlight"] = Instances:Create("Frame", {
                Parent = Items["TaskList"].Instance,
                Name   = "\0",
                BackgroundTransparency = 0.88,
                Size   = UDim2New(1, 0, 0, ROW_H),
                Position = UDim2New(0, 0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 2,
                BackgroundColor3 = FromRGB(151, 69, 186),
            })  Items["ActiveHighlight"]:AddToTheme({BackgroundColor3 = "Accent"})
            Instances:Create("UICorner", {Parent = Items["ActiveHighlight"].Instance, CornerRadius = UDimNew(0, 4)})

            -- Accent left-bar inside highlight
            Items["ActiveBar"] = Instances:Create("Frame", {
                Parent = Items["ActiveHighlight"].Instance,
                Name   = "\0",
                BackgroundTransparency = 0.2,
                Size   = UDim2New(0, 2, 1, -8),
                AnchorPoint = Vector2New(0, 0.5),
                Position = UDim2New(0, 3, 0.5, 0),
                BorderSizePixel = 0,
                ZIndex = 3,
                BackgroundColor3 = FromRGB(151, 69, 186),
            })  Items["ActiveBar"]:AddToTheme({BackgroundColor3 = "Accent"})
            Instances:Create("UICorner", {Parent = Items["ActiveBar"].Instance, CornerRadius = UDimNew(1, 0)})

        end  -- end Items do

        -- Pre-fetch icons once (shared by all rows)
        local ConnIconData    = Library:GetCustomIcon("corner-down-right")
        local ChevronIconData = Library:GetCustomIcon("chevron-right")

        -- ── Mini-picker state ─────────────────────────────────────────────────
        local MiniPicker = {Frame = nil, RS = nil, OwnerTask = nil}

        local function CloseMiniPicker()
            if MiniPicker.RS    then MiniPicker.RS:Disconnect(); MiniPicker.RS = nil end
            if MiniPicker.Frame then MiniPicker.Frame:Destroy(); MiniPicker.Frame = nil end
            MiniPicker.OwnerTask = nil
        end

        -- ── Callback helper ───────────────────────────────────────────────────
        local function FireCallback()
            local sorted = {}
            for _, t in ipairs(TQ.Tasks) do sorted[#sorted + 1] = {Name = t.Name, Order = t.Order} end
            table.sort(sorted, function(a, b) return a.Order < b.Order end)
            Library.Flags[TQ.Flag] = sorted
            Library:SafeCall(TQ.Callback, sorted)
        end

        -- ── Active indicator animation ─────────────────────────────────────────
        local function AnimateHighlight(idx)
            TQ.CurrentTask = math.clamp(idx, 1, math.max(1, #TQ.Tasks))
            Items["ActiveHighlight"]:Tween(
                TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {Position = UDim2New(0, 0, 0, (TQ.CurrentTask - 1) * ROW_H)}
            )
        end

        -- ── Row rendering ──────────────────────────────────────────────────────
        local RowInstances = {}  -- raw Instance refs for cleanup

        local function RenderRows()
            CloseMiniPicker()

            -- Destroy old row instances
            for _, inst in ipairs(RowInstances) do
                if inst and inst.Parent then inst:Destroy() end
            end
            RowInstances = {}

            table.sort(TQ.Tasks, function(a, b) return a.Order < b.Order end)
            local count = #TQ.Tasks

            -- Resize containers to match new count
            Items["TaskList"].Instance.Size    = UDim2New(1, 0, 0, count * ROW_H)
            Items["Container"].Instance.Size   = UDim2New(1, 0, 0, HEADER_H + count * ROW_H)
            Items["CountLabel"].Instance.Text  = tostring(count) .. " tasks"

            -- Clamp current task index (never touches ActiveHighlight position;
            -- AnimateHighlight owns all position changes after initial placement)
            TQ.CurrentTask = math.clamp(TQ.CurrentTask, 1, math.max(1, count))

            for i, task in ipairs(TQ.Tasks) do
                local rowY      = (i - 1) * ROW_H
                local isActive  = (i == TQ.CurrentTask)

                -- ── Row frame ─────────────────────────────────────────────────
                local rowFrame = InstanceNew("Frame")
                rowFrame.Name = "\0"
                rowFrame.BackgroundTransparency = 1
                rowFrame.BackgroundColor3 = Library.Theme["Accent"] or FromRGB(151, 69, 186)
                rowFrame.Size = UDim2New(1, 0, 0, ROW_H)
                rowFrame.Position = UDim2New(0, 0, 0, rowY)
                rowFrame.BorderSizePixel = 0
                rowFrame.ZIndex = 3
                rowFrame.Parent = Items["TaskList"].Instance
                RowInstances[#RowInstances + 1] = rowFrame

                -- ── └─ connector icon ──────────────────────────────────────────
                local connIcon = InstanceNew("ImageLabel")
                connIcon.Name = "\0"
                connIcon.BackgroundTransparency = 1
                connIcon.AnchorPoint = Vector2New(0, 0.5)
                connIcon.Position = UDim2New(0, 6, 0.5, 0)
                connIcon.Size = UDim2New(0, 14, 0, 14)
                connIcon.ZIndex = 4
                connIcon.BorderSizePixel = 0
                connIcon.BackgroundColor3 = FromRGB(255, 255, 255)
                connIcon.ImageColor3 = isActive
                    and (Library.Theme["Accent"] or FromRGB(151, 69, 186))
                    or  FromRGB(85, 83, 95)
                connIcon.ImageTransparency = isActive and 0.1 or 0.35
                if ConnIconData then
                    connIcon.Image           = ConnIconData.Url
                    connIcon.ImageRectOffset = ConnIconData.ImageRectOffset
                    connIcon.ImageRectSize   = ConnIconData.ImageRectSize
                else
                    -- Frame-based └─ fallback
                    connIcon.Image = ""
                    local vSeg = InstanceNew("Frame")
                    vSeg.BackgroundColor3 = FromRGB(85, 83, 95)
                    vSeg.BackgroundTransparency = 0.45
                    vSeg.BorderSizePixel = 0
                    vSeg.Size = UDim2New(0, 1, 0.5, 0)
                    vSeg.Position = UDim2New(0, 4, 0, 0)
                    vSeg.ZIndex = 5
                    vSeg.Parent = connIcon
                    local hSeg = InstanceNew("Frame")
                    hSeg.BackgroundColor3 = FromRGB(85, 83, 95)
                    hSeg.BackgroundTransparency = 0.45
                    hSeg.BorderSizePixel = 0
                    hSeg.Size = UDim2New(0.55, 0, 0, 1)
                    hSeg.Position = UDim2New(0, 4, 0.5, 0)
                    hSeg.ZIndex = 5
                    hSeg.Parent = connIcon
                end
                connIcon.Parent = rowFrame

                -- ── Order badge ────────────────────────────────────────────────
                local badge = InstanceNew("Frame")
                badge.Name = "\0"
                badge.AnchorPoint = Vector2New(0, 0.5)
                badge.Position = UDim2New(0, 24, 0.5, 0)
                badge.Size = UDim2New(0, 18, 0, 18)
                badge.BorderSizePixel = 0
                badge.ZIndex = 4
                badge.BackgroundColor3 = isActive
                    and (Library.Theme["Accent"] or FromRGB(151, 69, 186))
                    or  (Library.Theme["Element"] or FromRGB(34, 32, 38))
                badge.Parent = rowFrame

                local badgeCorner = InstanceNew("UICorner")
                badgeCorner.CornerRadius = UDimNew(0, 4)
                badgeCorner.Parent = badge

                local badgeStroke = InstanceNew("UIStroke")
                badgeStroke.Thickness = 1
                badgeStroke.Transparency = isActive and 0.8 or 0.55
                badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                badgeStroke.Color = isActive
                    and (Library.Theme["Accent"] or FromRGB(151, 69, 186))
                    or  (Library.Theme["Outline"] or FromRGB(60, 58, 65))
                badgeStroke.Parent = badge

                local badgeNum = InstanceNew("TextLabel")
                badgeNum.Name = "\0"
                badgeNum.FontFace = Library.Font
                badgeNum.TextColor3 = FromRGB(235, 235, 235)
                badgeNum.TextTransparency = isActive and 0 or 0.1
                badgeNum.Text = tostring(task.Order)
                badgeNum.Size = UDim2New(1, 0, 1, 0)
                badgeNum.BackgroundTransparency = 1
                badgeNum.TextXAlignment = Enum.TextXAlignment.Center
                badgeNum.ZIndex = 5
                badgeNum.TextSize = 10
                badgeNum.BackgroundColor3 = FromRGB(255, 255, 255)
                badgeNum.Parent = badge

                -- ── Task name ──────────────────────────────────────────────────
                local nameLabel = InstanceNew("TextLabel")
                nameLabel.Name = "\0"
                nameLabel.FontFace = Library.Font
                nameLabel.TextColor3 = isActive
                    and (Library.Theme["Accent"] or FromRGB(151, 69, 186))
                    or  (Library.Theme["Text"]   or FromRGB(240, 240, 240))
                nameLabel.TextTransparency = isActive and 0 or 0.25
                nameLabel.Text = task.Name
                nameLabel.AnchorPoint = Vector2New(0, 0.5)
                nameLabel.Position = UDim2New(0, 48, 0.5, 0)
                nameLabel.Size = UDim2New(1, -68, 0, 15)
                nameLabel.BackgroundTransparency = 1
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel.ZIndex = 4
                nameLabel.TextSize = 13
                nameLabel.BackgroundColor3 = FromRGB(255, 255, 255)
                nameLabel.Parent = rowFrame

                -- ── Edit hint (chevron right) ──────────────────────────────────
                local editIcon = InstanceNew("ImageLabel")
                editIcon.Name = "\0"
                editIcon.BackgroundTransparency = 1
                editIcon.AnchorPoint = Vector2New(1, 0.5)
                editIcon.Position = UDim2New(1, -4, 0.5, 0)
                editIcon.Size = UDim2New(0, 8, 0, 12)
                editIcon.ZIndex = 4
                editIcon.BorderSizePixel = 0
                editIcon.BackgroundColor3 = FromRGB(255, 255, 255)
                editIcon.ImageColor3 = Library.Theme["Text"] or FromRGB(141, 141, 150)
                editIcon.ImageTransparency = 0.55
                editIcon.Image = ChevronIconData and ChevronIconData.Url or ""
                editIcon.ImageRectOffset = ChevronIconData and ChevronIconData.ImageRectOffset or Vector2New(0, 0)
                editIcon.ImageRectSize   = ChevronIconData and ChevronIconData.ImageRectSize   or Vector2New(0, 0)
                editIcon.Parent = rowFrame

                -- ── Invisible click overlay ────────────────────────────────────
                local clickBtn = InstanceNew("TextButton")
                clickBtn.Name = "\0"
                clickBtn.Text = ""
                clickBtn.AutoButtonColor = false
                clickBtn.BackgroundTransparency = 1
                clickBtn.Size = UDim2New(1, 0, 1, 0)
                clickBtn.ZIndex = 6
                clickBtn.BorderSizePixel = 0
                clickBtn.BackgroundColor3 = FromRGB(255, 255, 255)
                clickBtn.Parent = rowFrame

                -- ── Hover feedback ─────────────────────────────────────────────
                local capturedTask     = task
                local capturedRowFrame = rowFrame
                local capturedIdx      = i

                rowFrame.MouseEnter:Connect(function()
                    if not isActive then
                        TweenService:Create(rowFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.93}):Play()
                    end
                    TweenService:Create(editIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {ImageTransparency = 0.1}):Play()
                end)
                rowFrame.MouseLeave:Connect(function()
                    TweenService:Create(rowFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
                    TweenService:Create(editIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {ImageTransparency = 0.55}):Play()
                end)

                -- ── Mini-picker (order change popup) ───────────────────────────
                clickBtn.MouseButton1Click:Connect(function()
                    if MiniPicker.OwnerTask == capturedTask then
                        CloseMiniPicker()
                        return
                    end
                    CloseMiniPicker()

                    local numTasks = #TQ.Tasks
                    local itemH    = 22
                    local padV     = 4
                    local pickerH  = numTasks * itemH + padV * 2
                    local pickerW  = 38

                    local pickerFrame = InstanceNew("Frame")
                    pickerFrame.Name = "\0"
                    pickerFrame.BackgroundColor3 = Library.Theme["Background"] or FromRGB(27, 25, 29)
                    pickerFrame.BorderSizePixel = 0
                    pickerFrame.Size = UDim2New(0, pickerW, 0, pickerH)
                    pickerFrame.ZIndex = 20
                    pickerFrame.Parent = Library.Holder.Instance

                    local pCornerOuter = InstanceNew("UICorner")
                    pCornerOuter.CornerRadius = UDimNew(0, 5)
                    pCornerOuter.Parent = pickerFrame

                    local pStroke = InstanceNew("UIStroke")
                    pStroke.Color = Library.Theme["Outline"] or FromRGB(35, 33, 38)
                    pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    pStroke.Thickness = 1
                    pStroke.Parent = pickerFrame

                    local pList = InstanceNew("UIListLayout")
                    pList.SortOrder = Enum.SortOrder.LayoutOrder
                    pList.Padding = UDimNew(0, 0)
                    pList.Parent = pickerFrame

                    local pPad = InstanceNew("UIPadding")
                    pPad.PaddingTop    = UDimNew(0, padV)
                    pPad.PaddingBottom = UDimNew(0, padV)
                    pPad.PaddingLeft   = UDimNew(0, 2)
                    pPad.PaddingRight  = UDimNew(0, 2)
                    pPad.Parent = pickerFrame

                    for orderNum = 1, numTasks do
                        local isCurrentOrder = (capturedTask.Order == orderNum)

                        local pBtn = InstanceNew("TextButton")
                        pBtn.Name = "\0"
                        pBtn.Text = tostring(orderNum)
                        pBtn.FontFace = Library.Font
                        pBtn.TextSize = 11
                        pBtn.TextColor3 = FromRGB(235, 235, 235)
                        pBtn.AutoButtonColor = false
                        pBtn.BackgroundColor3 = isCurrentOrder
                            and (Library.Theme["Accent"]  or FromRGB(151, 69, 186))
                            or  (Library.Theme["Element"] or FromRGB(34, 32, 38))
                        pBtn.BorderSizePixel = 0
                        pBtn.Size = UDim2New(1, 0, 0, itemH)
                        pBtn.ZIndex = 21
                        pBtn.LayoutOrder = orderNum
                        pBtn.Parent = pickerFrame

                        local pBtnCorner = InstanceNew("UICorner")
                        pBtnCorner.CornerRadius = UDimNew(0, 3)
                        pBtnCorner.Parent = pBtn

                        local capturedOrder = orderNum
                        pBtn.MouseButton1Click:Connect(function()
                            if capturedTask.Order == capturedOrder then
                                CloseMiniPicker(); return
                            end
                            -- Swap orders
                            for _, t in ipairs(TQ.Tasks) do
                                if t ~= capturedTask and t.Order == capturedOrder then
                                    t.Order = capturedTask.Order
                                    break
                                end
                            end
                            capturedTask.Order = capturedOrder
                            -- Re-normalise to 1..N
                            table.sort(TQ.Tasks, function(a, b) return a.Order < b.Order end)
                            for idx2, t in ipairs(TQ.Tasks) do t.Order = idx2 end
                            CloseMiniPicker()
                            RenderRows()
                            FireCallback()
                        end)

                        if not isCurrentOrder then
                            pBtn.MouseEnter:Connect(function()
                                TweenService:Create(pBtn, TweenInfo.new(0.1), {BackgroundColor3 = Library.Theme["Accent"] or FromRGB(151, 69, 186)}):Play()
                            end)
                            pBtn.MouseLeave:Connect(function()
                                TweenService:Create(pBtn, TweenInfo.new(0.1), {BackgroundColor3 = Library.Theme["Element"] or FromRGB(34, 32, 38)}):Play()
                            end)
                        end
                    end

                    -- Track position beside the row every frame
                    MiniPicker.RS = RunService.RenderStepped:Connect(function()
                        if not pickerFrame.Parent then
                            MiniPicker.RS:Disconnect(); MiniPicker.RS = nil; return
                        end
                        local rp = capturedRowFrame.AbsolutePosition
                        local rs = capturedRowFrame.AbsoluteSize
                        pickerFrame.Position = UDim2New(0, rp.X + rs.X + 4, 0, rp.Y)
                    end)

                    MiniPicker.Frame     = pickerFrame
                    MiniPicker.OwnerTask = capturedTask
                end)
            end
        end  -- end RenderRows

        -- Initial render + place highlight without animation
        RenderRows()
        Items["ActiveHighlight"].Instance.Position = UDim2New(0, 0, 0, 0)

        -- ── Public API ────────────────────────────────────────────────────────

        function TQ:SetTask(idx)
            if #TQ.Tasks == 0 then return end
            -- Rebuild rows first (rows reflect new active state), THEN tween the
            -- highlight so the animation plays over the already-updated row visuals
            local target = math.clamp(idx, 1, #TQ.Tasks)
            TQ.CurrentTask = target
            RenderRows()
            AnimateHighlight(target)
        end

        function TQ:GetCurrentTask()
            if #TQ.Tasks == 0 then return nil end
            local t = TQ.Tasks[TQ.CurrentTask]
            return t and {Name = t.Name, Order = t.Order} or nil
        end

        function TQ:NextTask()
            if #TQ.Tasks == 0 then return end
            local next = TQ.CurrentTask + 1
            if next > #TQ.Tasks then next = 1 end
            TQ.CurrentTask = next
            RenderRows()
            AnimateHighlight(next)
        end

        function TQ:ResetTasks()
            TQ.CurrentTask = 1
            RenderRows()
            AnimateHighlight(1)
        end

        -- ── Slide-in offsets ──────────────────────────────────────────────────
        Items["Text"].Instance.Position       = UDim2New(0, 30, 0.5, 0)
        Items["CountBadge"].Instance.Position = UDim2New(1, 30, 0.5, 0)

        function TQ:RefreshPosition(Bool)
            if Bool then
                Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                Items["CountBadge"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0.5, 0)})
            else
                Items["Text"].Instance.Position       = UDim2New(0, 30, 0.5, 0)
                Items["CountBadge"].Instance.Position = UDim2New(1, 30, 0.5, 0)
            end
        end

        -- ── Outside-click closes mini-picker ──────────────────────────────────
        local function IsMouseOverRawFrame(Frame)
            if not Frame then return false end
            local mp = Vector2New(Mouse.X, Mouse.Y)
            local ap = Frame.AbsolutePosition
            local as = Frame.AbsoluteSize
            return mp.X >= ap.X and mp.X <= ap.X + as.X
               and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y
        end

        Library:Connect(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                if not IsMouseOverRawFrame(MiniPicker.Frame) then
                    CloseMiniPicker()
                end
            end
        end)

        if TQ.Section.Page and TQ.Section.Page.Active then
            TQ:RefreshPosition(true)
        end

        TQ.Section.Elements[#TQ.Section.Elements + 1] = TQ

        -- ── Config: save / load ───────────────────────────────────────────────
        Library.SetFlags[TQ.Flag] = function(Value)
            if type(Value) ~= "table" then return end
            for _, v in ipairs(Value) do
                for _, t in ipairs(TQ.Tasks) do
                    if t.Name == (v.Name or v.name) then
                        t.Order = v.Order or v.order or t.Order
                    end
                end
            end
            table.sort(TQ.Tasks, function(a, b) return a.Order < b.Order end)
            for idx, t in ipairs(TQ.Tasks) do t.Order = idx end
            RenderRows()
        end

        if Data.ToolTip or Data.tooltip then
            Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Container"].Instance)
        end

        return TQ
    end
    -- ─────────────────────────────────────────────────────────────────────────

    -- ConditionBuilder: visual condition assistant panel
    -- ─────────────────────────────────────────────────────────────────────────
    Library.Sections.ConditionBuilder = function(self, Data)
        Data = Data or {}

        local CB = {
            Window  = self.Window,
            Page    = self.Page,
            Section = self,

            Title    = Data.Title    or Data.title    or "Conditions",
            Flag     = Data.Flag     or Data.flag     or Library:NextFlag(),
            Callback = Data.Callback or Data.callback or function() end,

            Conditions = {},
        }

        -- ── Variable / operator options ───────────────────────────────────────
        local VARIABLES = {
            "Mob Health", "Player Health", "Distance",
            "Enemy Count", "Player Level", "Energy", "Boss Spawned",
        }
        local OPERATORS = { "<", ">", "<=", ">=", "==", "!=" }

        -- ── Layout constants ──────────────────────────────────────────────────
        local HEADER_H = 26
        local COND_H   = 32   -- height of each condition row
        local ANIM_T   = TweenInfo.new(0.25, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
        local COLL_T   = TweenInfo.new(0.20, Enum.EasingStyle.Sine,  Enum.EasingDirection.In)
        local SLIDE_T  = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        -- Row layout: connector@4 | var-btn@22 w70 | op-btn@96 w36 | val-bg@136 w50 | remove@right-4
        local VAR_X, VAR_W = 22, 70
        local OP_X,  OP_W  = 96, 36
        local VAL_X, VAL_W = 136, 50

        -- ── Deep-copy DefaultConditions ───────────────────────────────────────
        for _, c in ipairs(Data.DefaultConditions or Data.defaultConditions or {}) do
            TableInsert(CB.Conditions, {
                Variable = c.Variable or c.variable or VARIABLES[1],
                Operator = c.Operator or c.operator or "<",
                Value    = tostring(tonumber(c.Value  or c.value) or 0),
            })
        end

        -- Seed Flags
        do
            local seed = {}
            for _, c in ipairs(CB.Conditions) do
                seed[#seed + 1] = {Variable = c.Variable, Operator = c.Operator, Value = tonumber(c.Value) or 0}
            end
            Library.Flags[CB.Flag] = seed
        end

        -- ── Callback helper ───────────────────────────────────────────────────
        local function FireCallback()
            local out = {}
            for _, c in ipairs(CB.Conditions) do
                out[#out + 1] = {Variable = c.Variable, Operator = c.Operator, Value = tonumber(c.Value) or 0}
            end
            Library.Flags[CB.Flag] = out
            Library:SafeCall(CB.Callback, out)
        end

        -- ── Shared mini-dropdown state ────────────────────────────────────────
        local MiniDrop = {Frame = nil, RS = nil, OwnerBtn = nil}

        local function CloseMiniDrop()
            if MiniDrop.RS    then MiniDrop.RS:Disconnect(); MiniDrop.RS = nil end
            if MiniDrop.Frame then MiniDrop.Frame:Destroy(); MiniDrop.Frame = nil end
            MiniDrop.OwnerBtn = nil
        end

        -- ── Static container (header + row layer) ─────────────────────────────
        local Items = {}

        Items["Container"] = Instances:Create("Frame", {
            Parent = CB.Section.Items["Content"].Instance,
            Name   = "\0",
            BackgroundTransparency = 1,
            Size   = UDim2New(1, 0, 0, HEADER_H + #CB.Conditions * COND_H),
            BorderSizePixel = 0,
            ZIndex = 2,
            BackgroundColor3 = FromRGB(255, 255, 255),
        })

        -- Header row
        local headerRow = Instances:Create("Frame", {
            Parent = Items["Container"].Instance,
            Name   = "\0",
            BackgroundTransparency = 1,
            Size   = UDim2New(1, 0, 0, HEADER_H),
            Position = UDim2New(0, 0, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 2,
            BackgroundColor3 = FromRGB(255, 255, 255),
        })

        -- Title label
        Items["Text"] = Instances:Create("TextLabel", {
            Parent = headerRow.Instance,
            Name   = "\0",
            FontFace = Library.Font,
            TextColor3 = FromRGB(240, 240, 240),
            TextTransparency = 0.30000001192092896,
            Text = CB.Title,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2New(0, 0, 0, 15),
            AnchorPoint = Vector2New(0, 0.5),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            Position = UDim2New(0, 0, 0.5, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
            TextSize = 14,
            BackgroundColor3 = FromRGB(255, 255, 255),
        })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

        -- "＋ Add" button (right of header)
        Items["AddButton"] = Instances:Create("TextButton", {
            Parent = headerRow.Instance,
            Name   = "\0",
            Text   = "",
            AutoButtonColor = false,
            AnchorPoint = Vector2New(1, 0.5),
            Position = UDim2New(1, 0, 0.5, 0),
            Size = UDim2New(0, 58, 0, 20),
            BorderSizePixel = 0,
            ZIndex = 2,
            BackgroundColor3 = FromRGB(22, 21, 25),
        })  Items["AddButton"]:AddToTheme({BackgroundColor3 = "Element"})
        Instances:Create("UICorner", {Parent = Items["AddButton"].Instance, CornerRadius = UDimNew(0, 5)})
        Instances:Create("UIStroke", {
            Parent = Items["AddButton"].Instance,
            Color  = FromRGB(60, 58, 65),
            Thickness = 1,
            Transparency = 0.45,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }):AddToTheme({Color = "Outline"})
        Items["AddLabel"] = Instances:Create("TextLabel", {
            Parent = Items["AddButton"].Instance,
            Name   = "\0",
            Text   = "+ Add",
            FontFace = Library.Font,
            TextColor3 = Library.Theme["Accent"] or FromRGB(151, 69, 186),
            TextSize = 11,
            Size = UDim2New(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 3,
        })  Items["AddLabel"]:AddToTheme({TextColor3 = "Accent"})

        Items["AddButton"]:OnHover(function()
            Items["AddButton"]:Tween(ANIM_T, {BackgroundColor3 = Library.Theme["Accent"] or FromRGB(151, 69, 186)})
            Items["AddLabel"]:Tween(ANIM_T, {TextColor3 = FromRGB(255, 255, 255)})
        end)
        Items["AddButton"]:OnHoverLeave(function()
            Items["AddButton"]:Tween(ANIM_T, {BackgroundColor3 = Library.Theme["Element"] or FromRGB(22, 21, 25)})
            Items["AddLabel"]:Tween(ANIM_T, {TextColor3 = Library.Theme["Accent"] or FromRGB(151, 69, 186)})
        end)

        -- Row layer (conditions live here)
        Items["RowLayer"] = Instances:Create("Frame", {
            Parent = Items["Container"].Instance,
            Name   = "\0",
            BackgroundTransparency = 1,
            Size   = UDim2New(1, 0, 0, #CB.Conditions * COND_H),
            Position = UDim2New(0, 0, 0, HEADER_H),
            BorderSizePixel = 0,
            ClipsDescendants = false,
            ZIndex = 2,
            BackgroundColor3 = FromRGB(255, 255, 255),
        })

        -- Subtle left-edge track line (shows the condition chain)
        Items["TrackLine"] = Instances:Create("Frame", {
            Parent = Items["RowLayer"].Instance,
            Name   = "\0",
            BackgroundTransparency = 0.72,
            Size   = UDim2New(0, 1, 1, -4),
            AnchorPoint = Vector2New(0, 0),
            Position = UDim2New(0, 10, 0, 2),
            BorderSizePixel = 0,
            ZIndex = 2,
            BackgroundColor3 = FromRGB(80, 78, 90),
        })  Items["TrackLine"]:AddToTheme({BackgroundColor3 = "Outline"})
        -- Gradient: solid top → fade bottom
        Instances:Create("UIGradient", {
            Parent = Items["TrackLine"].Instance,
            Rotation = 90,
            Transparency = NumSequence{
                NumSequenceKeypoint(0, 0),
                NumSequenceKeypoint(0.85, 0),
                NumSequenceKeypoint(1, 1),
            },
        })

        -- ── Row management ────────────────────────────────────────────────────
        local ConditionRows = {}  -- {cond=table, frame=Instance, remove=fn}

        -- Resize container to current row count (animated)
        local function ResizeContainer(animate)
            local newH = #CB.Conditions * COND_H
            if animate then
                TweenService:Create(Items["RowLayer"].Instance, ANIM_T, {Size = UDim2New(1, 0, 0, newH)}):Play()
                TweenService:Create(Items["TrackLine"].Instance, ANIM_T, {Size = UDim2New(0, 1, 1, -4)}):Play()
                TweenService:Create(Items["Container"].Instance, ANIM_T, {Size = UDim2New(1, 0, 0, HEADER_H + newH)}):Play()
            else
                Items["RowLayer"].Instance.Size    = UDim2New(1, 0, 0, newH)
                Items["Container"].Instance.Size   = UDim2New(1, 0, 0, HEADER_H + newH)
            end
        end

        -- Reposition all existing row frames to their correct Y (no tween, used after removal)
        local function RepositionRows(startIdx, animate)
            for i = startIdx, #ConditionRows do
                local entry = ConditionRows[i]
                local targetY = (i - 1) * COND_H
                if animate then
                    TweenService:Create(entry.frame, SLIDE_T, {Position = UDim2New(0, 0, 0, targetY)}):Play()
                else
                    entry.frame.Position = UDim2New(0, 0, 0, targetY)
                end
            end
        end

        -- Build a small floating picker (variable or operator selector)
        local function OpenMiniDrop(anchorBtn, options, currentValue, onSelect)
            if MiniDrop.OwnerBtn == anchorBtn then
                CloseMiniDrop(); return
            end
            CloseMiniDrop()

            local itemH  = 22
            local padV   = 4
            local pickerW = 90
            local pickerH = #options * itemH + padV * 2

            local pickerFrame = InstanceNew("Frame")
            pickerFrame.Name = "\0"
            pickerFrame.BackgroundColor3 = Library.Theme["Background"] or FromRGB(27, 25, 29)
            pickerFrame.BorderSizePixel = 0
            pickerFrame.Size = UDim2New(0, pickerW, 0, pickerH)
            pickerFrame.ZIndex = 20
            pickerFrame.Parent = Library.Holder.Instance

            local pCorner = InstanceNew("UICorner")
            pCorner.CornerRadius = UDimNew(0, 5)
            pCorner.Parent = pickerFrame

            local pStroke = InstanceNew("UIStroke")
            pStroke.Color = Library.Theme["Outline"] or FromRGB(35, 33, 38)
            pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            pStroke.Thickness = 1
            pStroke.Parent = pickerFrame

            local pList = InstanceNew("UIListLayout")
            pList.SortOrder = Enum.SortOrder.LayoutOrder
            pList.Padding = UDimNew(0, 0)
            pList.Parent = pickerFrame

            local pPad = InstanceNew("UIPadding")
            pPad.PaddingTop    = UDimNew(0, padV)
            pPad.PaddingBottom = UDimNew(0, padV)
            pPad.PaddingLeft   = UDimNew(0, 3)
            pPad.PaddingRight  = UDimNew(0, 3)
            pPad.Parent = pickerFrame

            for order, opt in ipairs(options) do
                local isCurrent = (opt == currentValue)

                local pBtn = InstanceNew("TextButton")
                pBtn.Name = "\0"
                pBtn.Text = opt
                pBtn.FontFace = Library.Font
                pBtn.TextSize = 11
                pBtn.TextXAlignment = Enum.TextXAlignment.Left
                pBtn.TextColor3 = isCurrent
                    and (Library.Theme["Accent"]  or FromRGB(151, 69, 186))
                    or  (Library.Theme["Text"]    or FromRGB(220, 220, 220))
                pBtn.TextTransparency = isCurrent and 0 or 0.1
                pBtn.AutoButtonColor = false
                pBtn.BackgroundColor3 = isCurrent
                    and (Library.Theme["Element"] or FromRGB(34, 32, 38))
                    or  FromRGB(0, 0, 0)
                pBtn.BackgroundTransparency = isCurrent and 0.55 or 1
                pBtn.BorderSizePixel = 0
                pBtn.Size = UDim2New(1, 0, 0, itemH)
                pBtn.ZIndex = 21
                pBtn.LayoutOrder = order
                pBtn.Parent = pickerFrame

                local pBtnCorner = InstanceNew("UICorner")
                pBtnCorner.CornerRadius = UDimNew(0, 3)
                pBtnCorner.Parent = pBtn

                local pBtnPad = InstanceNew("UIPadding")
                pBtnPad.PaddingLeft = UDimNew(0, 6)
                pBtnPad.Parent = pBtn

                local capturedOpt = opt
                pBtn.MouseButton1Click:Connect(function()
                    onSelect(capturedOpt)
                    CloseMiniDrop()
                end)

                if not isCurrent then
                    pBtn.MouseEnter:Connect(function()
                        TweenService:Create(pBtn, TweenInfo.new(0.12), {
                            BackgroundTransparency = 0.7,
                            BackgroundColor3 = Library.Theme["Element"] or FromRGB(34, 32, 38)
                        }):Play()
                    end)
                    pBtn.MouseLeave:Connect(function()
                        TweenService:Create(pBtn, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
                    end)
                end
            end

            -- Position picker below anchor button via RenderStepped
            MiniDrop.RS = RunService.RenderStepped:Connect(function()
                if not pickerFrame.Parent then
                    MiniDrop.RS:Disconnect(); MiniDrop.RS = nil; return
                end
                local ap = anchorBtn.AbsolutePosition
                local as = anchorBtn.AbsoluteSize
                -- Clamp so picker doesn't go off-screen vertically
                local screenH = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize.Y or 600
                local yBelow  = ap.Y + as.Y + 3
                local yAbove  = ap.Y - pickerH - 3
                local yFinal  = (yBelow + pickerH < screenH) and yBelow or yAbove
                pickerFrame.Position = UDim2New(0, ap.X, 0, yFinal)
                pickerFrame.Size     = UDim2New(0, math.max(pickerW, as.X), 0, pickerH)
            end)

            MiniDrop.Frame    = pickerFrame
            MiniDrop.OwnerBtn = anchorBtn
        end

        -- Build one condition row frame (raw Instances, not tracked by theme)
        local ConnIconData = Library:GetCustomIcon("corner-down-right")

        local function BuildConditionRow(condData, rowIndex)
            local rowFrame = InstanceNew("Frame")
            rowFrame.Name = "\0"
            rowFrame.BackgroundTransparency = 1
            rowFrame.Size = UDim2New(1, 0, 0, COND_H)
            rowFrame.Position = UDim2New(0, 0, 0, (rowIndex - 1) * COND_H)
            rowFrame.BorderSizePixel = 0
            rowFrame.ZIndex = 3
            rowFrame.BackgroundColor3 = FromRGB(255, 255, 255)
            rowFrame.Parent = Items["RowLayer"].Instance

            -- ── └─ connector icon ──────────────────────────────────────────────
            local connIcon = InstanceNew("ImageLabel")
            connIcon.Name = "\0"
            connIcon.BackgroundTransparency = 1
            connIcon.AnchorPoint = Vector2New(0, 0.5)
            connIcon.Position = UDim2New(0, 4, 0.5, 0)
            connIcon.Size = UDim2New(0, 13, 0, 13)
            connIcon.ZIndex = 4
            connIcon.BorderSizePixel = 0
            connIcon.BackgroundColor3 = FromRGB(255, 255, 255)
            connIcon.ImageColor3 = Library.Theme["Accent"] or FromRGB(151, 69, 186)
            connIcon.ImageTransparency = 0.45
            if ConnIconData then
                connIcon.Image           = ConnIconData.Url
                connIcon.ImageRectOffset = ConnIconData.ImageRectOffset
                connIcon.ImageRectSize   = ConnIconData.ImageRectSize
            else
                -- Frame-based └─ fallback
                connIcon.Image = ""
                local vSeg = InstanceNew("Frame")
                vSeg.BackgroundColor3 = Library.Theme["Outline"] or FromRGB(85, 83, 95)
                vSeg.BackgroundTransparency = 0.4
                vSeg.BorderSizePixel = 0
                vSeg.Size = UDim2New(0, 1, 0.5, 0)
                vSeg.Position = UDim2New(0, 4, 0, 0)
                vSeg.ZIndex = 5
                vSeg.Parent = connIcon
                local hSeg = InstanceNew("Frame")
                hSeg.BackgroundColor3 = Library.Theme["Outline"] or FromRGB(85, 83, 95)
                hSeg.BackgroundTransparency = 0.4
                hSeg.BorderSizePixel = 0
                hSeg.Size = UDim2New(0.6, 0, 0, 1)
                hSeg.Position = UDim2New(0, 4, 0.5, 0)
                hSeg.ZIndex = 5
                hSeg.Parent = connIcon
            end
            connIcon.Parent = rowFrame

            -- ── Shared button builder helper ───────────────────────────────────
            local function MakeFieldBtn(x, w, labelText)
                local bg = InstanceNew("TextButton")
                bg.Name = "\0"
                bg.Text = ""
                bg.AutoButtonColor = false
                bg.AnchorPoint = Vector2New(0, 0.5)
                bg.Position = UDim2New(0, x, 0.5, 0)
                bg.Size = UDim2New(0, w, 0, 22)
                bg.BackgroundColor3 = Library.Theme["Element"] or FromRGB(22, 21, 25)
                bg.BorderSizePixel = 0
                bg.ZIndex = 4
                bg.Parent = rowFrame

                local bgCorner = InstanceNew("UICorner")
                bgCorner.CornerRadius = UDimNew(0, 4)
                bgCorner.Parent = bg

                local bgStroke = InstanceNew("UIStroke")
                bgStroke.Color = Library.Theme["Outline"] or FromRGB(60, 58, 65)
                bgStroke.Thickness = 1
                bgStroke.Transparency = 0.55
                bgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                bgStroke.Parent = bg

                local label = InstanceNew("TextLabel")
                label.Name = "\0"
                label.FontFace = Library.Font
                label.Text = labelText
                label.TextColor3 = Library.Theme["Text"] or FromRGB(220, 220, 220)
                label.TextTransparency = 0.15
                label.TextSize = 11
                label.Size = UDim2New(1, -8, 1, 0)
                label.Position = UDim2New(0, 4, 0, 0)
                label.BackgroundTransparency = 1
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextTruncate = Enum.TextTruncate.AtEnd
                label.ZIndex = 5
                label.Parent = bg

                -- Chevron hint
                local ChevronData = Library:GetCustomIcon("chevron-down")
                local chevron = InstanceNew("ImageLabel")
                chevron.BackgroundTransparency = 1
                chevron.AnchorPoint = Vector2New(1, 0.5)
                chevron.Position = UDim2New(1, -2, 0.5, 0)
                chevron.Size = UDim2New(0, 8, 0, 5)
                chevron.ZIndex = 5
                chevron.BorderSizePixel = 0
                chevron.BackgroundColor3 = FromRGB(255, 255, 255)
                chevron.ImageColor3 = Library.Theme["Text"] or FromRGB(160, 158, 168)
                chevron.ImageTransparency = 0.5
                chevron.Image = ChevronData and ChevronData.Url or ""
                chevron.ImageRectOffset = ChevronData and ChevronData.ImageRectOffset or Vector2New(0,0)
                chevron.ImageRectSize   = ChevronData and ChevronData.ImageRectSize   or Vector2New(0,0)
                chevron.Parent = bg

                -- Hover feedback
                bg.MouseEnter:Connect(function()
                    TweenService:Create(bgStroke, TweenInfo.new(0.15), {Transparency = 0.15, Color = Library.Theme["Accent"] or FromRGB(151,69,186)}):Play()
                end)
                bg.MouseLeave:Connect(function()
                    TweenService:Create(bgStroke, TweenInfo.new(0.15), {Transparency = 0.55, Color = Library.Theme["Outline"] or FromRGB(60,58,65)}):Play()
                end)

                return bg, label
            end

            -- ── Variable selector button ───────────────────────────────────────
            local varBtn, varLabel = MakeFieldBtn(VAR_X, VAR_W, condData.Variable)
            varBtn.MouseButton1Click:Connect(function()
                OpenMiniDrop(varBtn, VARIABLES, condData.Variable, function(selected)
                    condData.Variable = selected
                    varLabel.Text = selected
                    FireCallback()
                end)
            end)

            -- ── Operator selector button ───────────────────────────────────────
            local opBtn, opLabel = MakeFieldBtn(OP_X, OP_W, condData.Operator)
            opBtn.MouseButton1Click:Connect(function()
                OpenMiniDrop(opBtn, OPERATORS, condData.Operator, function(selected)
                    condData.Operator = selected
                    opLabel.Text = selected
                    FireCallback()
                end)
            end)

            -- ── Value textbox ──────────────────────────────────────────────────
            local valBg = InstanceNew("Frame")
            valBg.Name = "\0"
            valBg.AnchorPoint = Vector2New(0, 0.5)
            valBg.Position = UDim2New(0, VAL_X, 0.5, 0)
            valBg.Size = UDim2New(0, VAL_W, 0, 22)
            valBg.BackgroundColor3 = Library.Theme["Element"] or FromRGB(22, 21, 25)
            valBg.BorderSizePixel = 0
            valBg.ZIndex = 4
            valBg.ClipsDescendants = true
            valBg.Parent = rowFrame

            local valCorner = InstanceNew("UICorner")
            valCorner.CornerRadius = UDimNew(0, 4)
            valCorner.Parent = valBg

            local valStroke = InstanceNew("UIStroke")
            valStroke.Color = Library.Theme["Outline"] or FromRGB(60, 58, 65)
            valStroke.Thickness = 1
            valStroke.Transparency = 0.55
            valStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            valStroke.Parent = valBg

            local valInput = InstanceNew("TextBox")
            valInput.Name = "\0"
            valInput.FontFace = Library.Font
            valInput.Text = condData.Value
            valInput.PlaceholderText = "0"
            valInput.PlaceholderColor3 = FromRGB(120, 118, 130)
            valInput.TextColor3 = Library.Theme["Text"] or FromRGB(220, 220, 220)
            valInput.TextTransparency = 0.1
            valInput.TextSize = 11
            valInput.Size = UDim2New(1, -8, 1, 0)
            valInput.Position = UDim2New(0, 4, 0, 0)
            valInput.BackgroundTransparency = 1
            valInput.BorderSizePixel = 0
            valInput.ZIndex = 5
            valInput.ClearTextOnFocus = false
            valInput.Parent = valBg

            -- Focus glow
            valInput.Focused:Connect(function()
                TweenService:Create(valStroke, TweenInfo.new(0.15), {
                    Transparency = 0,
                    Color = Library.Theme["Accent"] or FromRGB(151, 69, 186)
                }):Play()
            end)
            valInput.FocusLost:Connect(function(enterPressed)
                TweenService:Create(valStroke, TweenInfo.new(0.15), {
                    Transparency = 0.55,
                    Color = Library.Theme["Outline"] or FromRGB(60, 58, 65)
                }):Play()
                -- Enforce numeric, keep last valid
                local cleaned = valInput.Text:gsub("[^%d%.%-]", "")
                if cleaned == "" then cleaned = "0" end
                valInput.Text = cleaned
                condData.Value = cleaned
                FireCallback()
            end)
            valInput:GetPropertyChangedSignal("Text"):Connect(function()
                -- Live strip non-numerics
                local t = valInput.Text:gsub("[^%d%.%-]", "")
                if t ~= valInput.Text then valInput.Text = t end
                condData.Value = t
            end)

            -- ── Remove button (×) ──────────────────────────────────────────────
            local removeBtn = InstanceNew("TextButton")
            removeBtn.Name = "\0"
            removeBtn.Text = "×"
            removeBtn.FontFace = Library.Font
            removeBtn.TextSize = 14
            removeBtn.TextColor3 = FromRGB(160, 158, 168)
            removeBtn.TextTransparency = 0.3
            removeBtn.AutoButtonColor = false
            removeBtn.AnchorPoint = Vector2New(1, 0.5)
            removeBtn.Position = UDim2New(1, -2, 0.5, 0)
            removeBtn.Size = UDim2New(0, 18, 0, 18)
            removeBtn.BackgroundTransparency = 1
            removeBtn.BorderSizePixel = 0
            removeBtn.ZIndex = 4
            removeBtn.Parent = rowFrame

            removeBtn.MouseEnter:Connect(function()
                TweenService:Create(removeBtn, TweenInfo.new(0.12), {
                    TextColor3 = Library.Theme["Accent"] or FromRGB(151, 69, 186),
                    TextTransparency = 0,
                }):Play()
            end)
            removeBtn.MouseLeave:Connect(function()
                TweenService:Create(removeBtn, TweenInfo.new(0.12), {
                    TextColor3 = FromRGB(160, 158, 168),
                    TextTransparency = 0.3,
                }):Play()
            end)

            -- Removal logic: animate out, shift rows, resize
            removeBtn.MouseButton1Click:Connect(function()
                -- Find the index of this condition in CB.Conditions
                local removeIdx = nil
                for i2, entry in ipairs(ConditionRows) do
                    if entry.frame == rowFrame then
                        removeIdx = i2
                        break
                    end
                end
                if not removeIdx then return end
                if MiniDrop.OwnerBtn == varBtn or MiniDrop.OwnerBtn == opBtn then
                    CloseMiniDrop()
                end

                -- Fade out + slide slightly down
                TweenService:Create(rowFrame, COLL_T, {
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, rowFrame.Position.Y.Offset + 6),
                }):Play()
                -- Fade all children
                for _, child in ipairs(rowFrame:GetDescendants()) do
                    if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("ImageLabel") then
                        local tt = child:IsA("TextLabel") or child:IsA("TextButton")
                        local it = child:IsA("ImageLabel")
                        if tt then TweenService:Create(child, COLL_T, {TextTransparency=1, BackgroundTransparency=1}):Play()
                        elseif it then TweenService:Create(child, COLL_T, {ImageTransparency=1, BackgroundTransparency=1}):Play()
                        else TweenService:Create(child, COLL_T, {BackgroundTransparency=1}):Play()
                        end
                    elseif child:IsA("TextBox") then
                        TweenService:Create(child, COLL_T, {TextTransparency=1}):Play()
                    elseif child:IsA("UIStroke") then
                        TweenService:Create(child, COLL_T, {Transparency=1}):Play()
                    end
                end

                task.delay(COLL_T.Time + 0.02, function()
                    if not Library then return end
                    rowFrame:Destroy()
                    TableRemove(CB.Conditions, removeIdx)
                    TableRemove(ConditionRows, removeIdx)
                    -- Slide remaining rows upward
                    RepositionRows(removeIdx, true)
                    ResizeContainer(true)
                    FireCallback()
                end)
            end)

            return rowFrame
        end

        -- ── Add a new condition (with fade-in slide-up animation) ─────────────
        local function AddCondition(condData, animate)
            local idx = #CB.Conditions
            local newFrame = BuildConditionRow(condData, idx)

            if animate then
                -- Start offset down + transparent, tween to target
                local targetY = (idx - 1) * COND_H
                newFrame.Position = UDim2New(0, 0, 0, targetY + 10)
                -- Fade in all children
                for _, child in ipairs(newFrame:GetDescendants()) do
                    if child:IsA("Frame") then child.BackgroundTransparency = 1
                    elseif child:IsA("TextLabel") or child:IsA("TextButton") then
                        child.TextTransparency = 1; child.BackgroundTransparency = 1
                    elseif child:IsA("ImageLabel") then
                        child.ImageTransparency = 1; child.BackgroundTransparency = 1
                    elseif child:IsA("TextBox") then
                        child.TextTransparency = 1
                    elseif child:IsA("UIStroke") then
                        child.Transparency = 1
                    end
                end

                -- Slide into position
                TweenService:Create(newFrame, ANIM_T, {Position = UDim2New(0, 0, 0, targetY)}):Play()

                -- Fade in children with slight delay per type
                Library:Thread(function()
                    task.wait(0.04)
                    for _, child in ipairs(newFrame:GetDescendants()) do
                        if child:IsA("Frame") then
                            TweenService:Create(child, ANIM_T, {BackgroundTransparency = child.BackgroundTransparency == 1 and 0 or child.BackgroundTransparency}):Play()
                        end
                    end
                    for _, child in ipairs(newFrame:GetDescendants()) do
                        if child:IsA("TextLabel") or child:IsA("TextButton") then
                            -- only restore labels that should be visible
                            TweenService:Create(child, ANIM_T, {TextTransparency = 0.1, BackgroundTransparency = child:IsA("TextButton") and 0 or 1}):Play()
                        elseif child:IsA("ImageLabel") then
                            TweenService:Create(child, ANIM_T, {ImageTransparency = 0.45}):Play()
                        elseif child:IsA("TextBox") then
                            TweenService:Create(child, ANIM_T, {TextTransparency = 0.1}):Play()
                        elseif child:IsA("UIStroke") then
                            TweenService:Create(child, ANIM_T, {Transparency = 0.55}):Play()
                        end
                    end
                end)
            end

            ConditionRows[#ConditionRows + 1] = {cond = condData, frame = newFrame}
        end

        -- ── Spawn default conditions (no animation, instant) ─────────────────
        for _, c in ipairs(CB.Conditions) do
            AddCondition(c, false)
        end
        ResizeContainer(false)

        -- ── Add button handler ────────────────────────────────────────────────
        Items["AddButton"]:Connect("MouseButton1Click", function()
            local newCond = {Variable = VARIABLES[1], Operator = "<", Value = "0"}
            TableInsert(CB.Conditions, newCond)
            ResizeContainer(true)
            AddCondition(newCond, true)
            FireCallback()
        end)

        -- ── Close mini-drop on outside click ─────────────────────────────────
        local function IsMouseOverRawFrame(Frame)
            if not Frame then return false end
            local mp = Vector2New(Mouse.X, Mouse.Y)
            local ap = Frame.AbsolutePosition
            local as = Frame.AbsoluteSize
            return mp.X >= ap.X and mp.X <= ap.X + as.X
               and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y
        end

        Library:Connect(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or
               Input.UserInputType == Enum.UserInputType.Touch then
                if not IsMouseOverRawFrame(MiniDrop.Frame) then
                    CloseMiniDrop()
                end
            end
        end)

        -- ── Slide-in offsets for page transitions ─────────────────────────────
        Items["Text"].Instance.Position      = UDim2New(0, 30, 0.5, 0)
        Items["AddButton"].Instance.Position = UDim2New(1, 30, 0.5, 0)

        function CB:RefreshPosition(Bool)
            if Bool then
                Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                Items["AddButton"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0.5, 0)})
            else
                Items["Text"].Instance.Position      = UDim2New(0, 30, 0.5, 0)
                Items["AddButton"].Instance.Position = UDim2New(1, 30, 0.5, 0)
            end
        end

        -- ── Public API ────────────────────────────────────────────────────────
        function CB:Get()
            local out = {}
            for _, c in ipairs(CB.Conditions) do
                out[#out + 1] = {Variable = c.Variable, Operator = c.Operator, Value = tonumber(c.Value) or 0}
            end
            return out
        end

        function CB:Clear()
            for _, entry in ipairs(ConditionRows) do
                if entry.frame and entry.frame.Parent then entry.frame:Destroy() end
            end
            ConditionRows = {}
            CB.Conditions = {}
            ResizeContainer(true)
            FireCallback()
        end

        -- ── Config: save / load ───────────────────────────────────────────────
        if CB.Section.Page and CB.Section.Page.Active then
            CB:RefreshPosition(true)
        end

        CB.Section.Elements[#CB.Section.Elements + 1] = CB

        Library.SetFlags[CB.Flag] = function(Value)
            if type(Value) ~= "table" then return end
            -- Clear current rows
            for _, entry in ipairs(ConditionRows) do
                if entry.frame and entry.frame.Parent then entry.frame:Destroy() end
            end
            ConditionRows = {}
            CB.Conditions = {}
            -- Restore from saved value
            for _, c in ipairs(Value) do
                local newCond = {
                    Variable = c.Variable or c.variable or VARIABLES[1],
                    Operator = c.Operator or c.operator or "<",
                    Value    = tostring(tonumber(c.Value  or c.value) or 0),
                }
                TableInsert(CB.Conditions, newCond)
                AddCondition(newCond, false)
            end
            ResizeContainer(false)
        end

        if Data.ToolTip or Data.tooltip then
            Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Container"].Instance)
        end

        return CB
    end
    -- ─────────────────────────────────────────────────────────────────────────

    -- ─────────────────────────────────────────────────────────────────────────
    -- TagInput: text input that builds a removable-tag list
    -- API: :Add(tag), :Remove(tag), :Clear(), :Get() → {string,...}
    -- Callback(tags) fires on every Add/Remove/Clear
    -- ─────────────────────────────────────────────────────────────────────────
    Library.Sections.TagInput = function(self, Data)
        Data = Data or {}

        local TagInput = {
            Window      = self.Window,
            Page        = self.Page,
            Section     = self,

            Name        = Data.Name        or Data.name        or "TagInput",
            Flag        = Data.Flag        or Data.flag        or Library:NextFlag(),
            Callback    = Data.Callback    or Data.callback    or function() end,
            Placeholder = Data.Placeholder or Data.placeholder or "Add tag...",
            MaxTags     = Data.MaxTags     or Data.maxTags     or 30,

            Value       = {},    -- list of tag strings
            TagFrames   = {},    -- tag string → frame reference
        }

        -- ── height constants ───────────────────────────────────────────────
        local INPUT_H   = 32
        local TAGS_PADV = 6   -- vertical padding inside tags area
        local TAG_H     = 22  -- height of each pill row
        local WRAP_PAD  = 6   -- horizontal gap between pills
        local MAX_VISIBLE_ROWS = 3  -- rows before scroll kicks in

        local Items = {} do
            -- root frame
            Items["TagInput"] = Instances:Create("Frame", {
                Parent              = TagInput.Section.Items["Content"].Instance,
                Name                = "\0",
                BackgroundTransparency = 1,
                Size                = UDim2New(1, 0, 0, INPUT_H),
                AutomaticSize       = Enum.AutomaticSize.Y,
                BorderColor3        = FromRGB(0, 0, 0),
                ZIndex              = 2,
                BorderSizePixel     = 0,
                BackgroundColor3    = FromRGB(255, 255, 255),
            })

            -- title label
            Items["Title"] = Instances:Create("TextLabel", {
                Parent              = Items["TagInput"].Instance,
                Name                = "\0",
                FontFace            = Library.Font,
                TextColor3          = FromRGB(240, 240, 240),
                TextTransparency    = 0.3,
                Text                = TagInput.Name,
                AutomaticSize       = Enum.AutomaticSize.X,
                Size                = UDim2New(0, 0, 0, 15),
                AnchorPoint         = Vector2New(0, 0.5),
                BorderSizePixel     = 0,
                BackgroundTransparency = 1,
                Position            = UDim2New(0, 30, 0, INPUT_H / 2),
                BorderColor3        = FromRGB(0, 0, 0),
                ZIndex              = 2,
                TextSize            = 14,
                BackgroundColor3    = FromRGB(255, 255, 255),
            }) Items["Title"]:AddToTheme({TextColor3 = "Text"})

            -- input background (right side)
            Items["InputBg"] = Instances:Create("Frame", {
                Parent              = Items["TagInput"].Instance,
                Name                = "\0",
                Active              = true,
                BorderColor3        = FromRGB(0, 0, 0),
                AnchorPoint         = Vector2New(1, 0),
                Position            = UDim2New(1, -4, 0, 5),
                Size                = UDim2New(0, 160, 0, 22),
                ZIndex              = 2,
                ClipsDescendants    = true,
                BorderSizePixel     = 0,
                BackgroundColor3    = FromRGB(27, 26, 29),
            }) Items["InputBg"]:AddToTheme({BackgroundColor3 = "Element"})

            Instances:Create("UIStroke", {
                Parent              = Items["InputBg"].Instance,
                Name                = "\0",
                Color               = FromRGB(35, 33, 38),
                ApplyStrokeMode     = Enum.ApplyStrokeMode.Border,
            }):AddToTheme({Color = "Outline"})

            Instances:Create("UICorner", {
                Parent              = Items["InputBg"].Instance,
                Name                = "\0",
                CornerRadius        = UDimNew(0, 4),
            })

            -- text input inside InputBg
            Items["Input"] = Instances:Create("TextBox", {
                Parent              = Items["InputBg"].Instance,
                Name                = "\0",
                FontFace            = Library.Font,
                TextColor3          = FromRGB(240, 240, 240),
                BorderColor3        = FromRGB(0, 0, 0),
                Text                = "",
                ZIndex              = 3,
                Size                = UDim2New(1, -10, 1, 0),
                Position            = UDim2New(0, 8, 0, 0),
                BorderSizePixel     = 0,
                BackgroundTransparency = 1,
                PlaceholderColor3   = FromRGB(185, 185, 185),
                TextXAlignment      = Enum.TextXAlignment.Left,
                PlaceholderText     = TagInput.Placeholder,
                TextSize            = 13,
                BackgroundColor3    = FromRGB(255, 255, 255),
                ClearTextOnFocus    = false,
            }) Items["Input"]:AddToTheme({TextColor3 = "Text"})

            -- "+ Add" button (sits just to the right of InputBg's right edge)
            Items["AddBtn"] = Instances:Create("TextButton", {
                Parent              = Items["TagInput"].Instance,
                Name                = "\0",
                FontFace            = Library.Font,
                TextColor3          = FromRGB(255, 255, 255),
                Text                = "+",
                AutoButtonColor     = false,
                AnchorPoint         = Vector2New(1, 0),
                Position            = UDim2New(1, -170, 0, 5),
                Size                = UDim2New(0, 22, 0, 22),
                ZIndex              = 3,
                BorderSizePixel     = 0,
                BackgroundColor3    = FromRGB(80, 50, 110),
                TextSize            = 17,
            })

            Instances:Create("UIGradient", {
                Parent   = Items["AddBtn"].Instance,
                Name     = "\0",
                Rotation = -115,
                Color    = RGBSequence{
                    RGBSequenceKeypoint(0, FromRGB(255, 255, 255)),
                    RGBSequenceKeypoint(1, FromRGB(143, 143, 143)),
                },
            }):AddToTheme({Color = function()
                return RGBSequence{
                    RGBSequenceKeypoint(0, Library.Theme.Accent),
                    RGBSequenceKeypoint(1, Library.Theme.AccentGradient),
                }
            end})

            Instances:Create("UICorner", {
                Parent       = Items["AddBtn"].Instance,
                Name         = "\0",
                CornerRadius = UDimNew(0, 4),
            })

            -- tags scroll area (appears below input row)
            Items["TagsArea"] = Instances:Create("ScrollingFrame", {
                Parent                  = Items["TagInput"].Instance,
                Name                    = "\0",
                Position                = UDim2New(0, 0, 0, INPUT_H),
                Size                    = UDim2New(1, 0, 0, 0),
                AutomaticCanvasSize     = Enum.AutomaticSize.Y,
                CanvasSize              = UDim2New(0, 0, 0, 0),
                ScrollBarThickness      = 2,
                ScrollingDirection      = Enum.ScrollingDirection.Y,
                BackgroundTransparency  = 1,
                BorderSizePixel         = 0,
                ZIndex                  = 2,
                Visible                 = false,
                BackgroundColor3        = FromRGB(255, 255, 255),
            }) Items["TagsArea"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

            -- vertical list layout for the pills
            Items["TagsLayout"] = Instances:Create("UIListLayout", {
                Parent          = Items["TagsArea"].Instance,
                Name            = "\0",
                FillDirection   = Enum.FillDirection.Vertical,
                Padding         = UDimNew(0, WRAP_PAD),
                SortOrder       = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
            })

            Instances:Create("UIPadding", {
                Parent        = Items["TagsArea"].Instance,
                Name          = "\0",
                PaddingTop    = UDimNew(0, TAGS_PADV),
                PaddingBottom = UDimNew(0, TAGS_PADV),
                PaddingLeft   = UDimNew(0, 4),
                PaddingRight  = UDimNew(0, 4),
            })
        end

        -- ── internal helpers ───────────────────────────────────────────────
        local function FireCallback()
            Library:SafeCall(TagInput.Callback, TagInput.Value)
            Library.Flags[TagInput.Flag] = TagInput.Value
        end

        local function RecalcTagsHeight()
            local count = #TagInput.Value
            if count == 0 then
                Items["TagsArea"].Instance.Size    = UDim2New(1, 0, 0, 0)
                Items["TagsArea"].Instance.Visible = false
                return
            end
            local visibleRows = math.min(count, MAX_VISIBLE_ROWS)
            local h = visibleRows * (TAG_H + WRAP_PAD) + TAGS_PADV * 2
            Items["TagsArea"]:Tween(
                TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = UDim2New(1, 0, 0, h)}
            )
            Items["TagsArea"].Instance.Visible = true
        end

        local function MakePill(tag)
            local pill = Instances:Create("Frame", {
                Parent              = Items["TagsArea"].Instance,
                Name                = "\0",
                Size                = UDim2New(1, 0, 0, TAG_H),
                BackgroundColor3    = FromRGB(35, 30, 45),
                BorderSizePixel     = 0,
                ZIndex              = 3,
                ClipsDescendants    = true,
            }) pill:AddToTheme({BackgroundColor3 = "Element"})

            Instances:Create("UIStroke", {
                Parent          = pill.Instance,
                Name            = "\0",
                Color           = FromRGB(80, 50, 110),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }):AddToTheme({Color = "Accent"})

            Instances:Create("UICorner", {
                Parent       = pill.Instance,
                Name         = "\0",
                CornerRadius = UDimNew(0, 11),
            })

            local nameLabel = Instances:Create("TextLabel", {
                Parent              = pill.Instance,
                Name                = "\0",
                FontFace            = Library.Font,
                TextColor3          = FromRGB(220, 220, 220),
                Text                = tag,
                Size                = UDim2New(1, -18, 1, 0),
                Position            = UDim2New(0, 7, 0, 0),
                BackgroundTransparency = 1,
                TextXAlignment      = Enum.TextXAlignment.Left,
                TextSize            = 12,
                ZIndex              = 3,
                BorderSizePixel     = 0,
                BackgroundColor3    = FromRGB(255, 255, 255),
                ClipsDescendants    = true,
            }) nameLabel:AddToTheme({TextColor3 = "Text"})

            local removeBtn = Instances:Create("TextButton", {
                Parent              = pill.Instance,
                Name                = "\0",
                FontFace            = Library.Font,
                TextColor3          = FromRGB(180, 140, 200),
                Text                = "×",
                AutoButtonColor     = false,
                AnchorPoint         = Vector2New(1, 0.5),
                Position            = UDim2New(1, -2, 0.5, 0),
                Size                = UDim2New(0, 16, 0, 16),
                BackgroundTransparency = 1,
                TextSize            = 14,
                ZIndex              = 4,
                BorderSizePixel     = 0,
                BackgroundColor3    = FromRGB(255, 255, 255),
            })

            removeBtn:Connect("MouseButton1Click", function()
                TagInput:Remove(tag)
            end)

            TagInput.TagFrames[tag] = pill
        end

        -- ── Public API ─────────────────────────────────────────────────────
        function TagInput:Add(tag)
            tag = tostring(tag):match("^%s*(.-)%s*$")  -- trim whitespace
            if tag == "" then return end
            if #TagInput.Value >= TagInput.MaxTags then return end
            for _, existing in ipairs(TagInput.Value) do
                if existing == tag then return end  -- no duplicates
            end

            TagInput.Value[#TagInput.Value + 1] = tag
            MakePill(tag)
            RecalcTagsHeight()
            FireCallback()
        end

        function TagInput:Remove(tag)
            for i, existing in ipairs(TagInput.Value) do
                if existing == tag then
                    table.remove(TagInput.Value, i)
                    break
                end
            end
            local pill = TagInput.TagFrames[tag]
            if pill then
                pill.Instance:Destroy()
                TagInput.TagFrames[tag] = nil
            end
            RecalcTagsHeight()
            FireCallback()
        end

        function TagInput:Clear()
            for _, pill in pairs(TagInput.TagFrames) do
                if pill and pill.Instance and pill.Instance.Parent then
                    pill.Instance:Destroy()
                end
            end
            TagInput.Value     = {}
            TagInput.TagFrames = {}
            RecalcTagsHeight()
            FireCallback()
        end

        function TagInput:Get()
            local copy = {}
            for i, v in ipairs(TagInput.Value) do copy[i] = v end
            return copy
        end

        function TagInput:Set(tagsTable)
            TagInput:Clear()
            if type(tagsTable) ~= "table" then return end
            for _, tag in ipairs(tagsTable) do
                TagInput:Add(tag)
            end
        end

        function TagInput:SetVisibility(Bool)
            Items["TagInput"].Instance.Visible = Bool
        end

        function TagInput:RefreshPosition(Bool)
            if Bool then
                Items["Title"]:Tween(
                    TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                    {Position = UDim2New(0, 0, 0, INPUT_H / 2)}
                )
            else
                Items["Title"].Instance.Position = UDim2New(0, 30, 0, INPUT_H / 2)
            end
        end

        -- ── Input events ───────────────────────────────────────────────────
        Items["Input"]:Connect("FocusLost", function(enterPressed)
            if enterPressed then
                TagInput:Add(Items["Input"].Instance.Text)
                Items["Input"].Instance.Text = ""
            end
        end)

        Items["AddBtn"]:Connect("MouseButton1Click", function()
            TagInput:Add(Items["Input"].Instance.Text)
            Items["Input"].Instance.Text = ""
        end)

        -- ── Defaults & registration ────────────────────────────────────────
        if Data.Default or Data.default then
            TagInput:Set(Data.Default or Data.default)
        end

        Library.SetFlags[TagInput.Flag] = function(Value)
            TagInput:Set(Value)
        end

        if TagInput.Section.Page and TagInput.Section.Page.Active then
            TagInput:RefreshPosition(true)
        end

        TagInput.Section.Elements[#TagInput.Section.Elements + 1] = TagInput

        if Data.ToolTip or Data.tooltip then
            Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["TagInput"].Instance)
        end

        return TagInput
    end
    -- ─────────────────────────────────────────────────────────────────────────

    -- ─────────────────────────────────────────────────────────────────────────
    -- StatBar: multi-segment live stat bars with labels and optional value text
    -- API: :SetSegment(label, current, max), :Get() → {label→{Current,Max,...}}
    -- Callback(label, current, max) fires on every :SetSegment()
    -- ─────────────────────────────────────────────────────────────────────────
    Library.Sections.StatBar = function(self, Data)
        Data = Data or {}

        local StatBar = {
            Window      = self.Window,
            Page        = self.Page,
            Section     = self,

            Name        = Data.Name        or Data.name        or "StatBar",
            Flag        = Data.Flag        or Data.flag        or Library:NextFlag(),
            Callback    = Data.Callback    or Data.callback    or function() end,

            Segments    = {},  -- array of segment data from Data.Segments
            SegmentUI   = {},  -- label → {Fill, ValueLabel, BarBg}
        }

        local SEG_H     = 28   -- height per segment row
        local BAR_H     = 6    -- fill bar height
        local LABEL_W   = 68   -- fixed width for the label column
        local VAL_W     = 48   -- fixed width for the value text column

        local totalH = 32  -- header row

        -- copy segment definitions
        local segmentDefs = Data.Segments or Data.segments or {}
        for _, def in ipairs(segmentDefs) do
            local seg = {
                Label   = def.Label   or def.label   or "Stat",
                Color   = def.Color   or def.color   or FromRGB(130, 80, 220),
                Flag    = def.Flag    or def.flag     or nil,
                Current = 0,
                Max     = 100,
            }
            StatBar.Segments[#StatBar.Segments + 1] = seg
            totalH = totalH + SEG_H
        end

        local Items = {} do
            -- root frame
            Items["StatBar"] = Instances:Create("Frame", {
                Parent              = StatBar.Section.Items["Content"].Instance,
                Name                = "\0",
                BackgroundTransparency = 1,
                Size                = UDim2New(1, 0, 0, totalH),
                BorderColor3        = FromRGB(0, 0, 0),
                ZIndex              = 2,
                BorderSizePixel     = 0,
                BackgroundColor3    = FromRGB(255, 255, 255),
            })

            -- section title
            Items["Title"] = Instances:Create("TextLabel", {
                Parent              = Items["StatBar"].Instance,
                Name                = "\0",
                FontFace            = Library.Font,
                TextColor3          = FromRGB(240, 240, 240),
                TextTransparency    = 0.3,
                Text                = StatBar.Name,
                AutomaticSize       = Enum.AutomaticSize.X,
                Size                = UDim2New(0, 0, 0, 15),
                AnchorPoint         = Vector2New(0, 0.5),
                BorderSizePixel     = 0,
                BackgroundTransparency = 1,
                Position            = UDim2New(0, 30, 0, 16),
                BorderColor3        = FromRGB(0, 0, 0),
                ZIndex              = 2,
                TextSize            = 14,
                BackgroundColor3    = FromRGB(255, 255, 255),
            }) Items["Title"]:AddToTheme({TextColor3 = "Text"})

            -- build one row per segment
            for i, seg in ipairs(StatBar.Segments) do
                local yOff = 32 + (i - 1) * SEG_H

                -- label
                local segLabel = Instances:Create("TextLabel", {
                    Parent              = Items["StatBar"].Instance,
                    Name                = "\0",
                    FontFace            = Library.Font,
                    TextColor3          = FromRGB(180, 180, 190),
                    Text                = seg.Label,
                    Size                = UDim2New(0, LABEL_W, 0, SEG_H),
                    Position            = UDim2New(0, 8, 0, yOff),
                    BackgroundTransparency = 1,
                    TextXAlignment      = Enum.TextXAlignment.Left,
                    TextSize            = 12,
                    ZIndex              = 2,
                    BorderSizePixel     = 0,
                    BackgroundColor3    = FromRGB(255, 255, 255),
                }) segLabel:AddToTheme({TextColor3 = "SubText"})

                -- bar background
                local barBg = Instances:Create("Frame", {
                    Parent              = Items["StatBar"].Instance,
                    Name                = "\0",
                    Position            = UDim2New(0, LABEL_W + 12, 0, yOff + (SEG_H - BAR_H) / 2),
                    Size                = UDim2New(1, -(LABEL_W + 12 + VAL_W + 10), 0, BAR_H),
                    BackgroundColor3    = FromRGB(35, 33, 42),
                    BorderSizePixel     = 0,
                    ZIndex              = 2,
                    ClipsDescendants    = true,
                }) barBg:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent       = barBg.Instance,
                    Name         = "\0",
                    CornerRadius = UDimNew(1, 0),
                })

                Instances:Create("UIStroke", {
                    Parent          = barBg.Instance,
                    Name            = "\0",
                    Color           = FromRGB(50, 45, 60),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }):AddToTheme({Color = "Outline"})

                -- fill bar (starts at 0 width)
                local fill = Instances:Create("Frame", {
                    Parent           = barBg.Instance,
                    Name             = "\0",
                    Size             = UDim2New(0, 0, 1, 0),
                    BackgroundColor3 = seg.Color,
                    BorderSizePixel  = 0,
                    ZIndex           = 3,
                })

                Instances:Create("UIGradient", {
                    Parent   = fill.Instance,
                    Name     = "\0",
                    Rotation = 0,
                    Transparency = NumSequence{
                        NumSequenceKeypoint(0, 0),
                        NumSequenceKeypoint(0.85, 0),
                        NumSequenceKeypoint(1, 0.35),
                    },
                })

                Instances:Create("UICorner", {
                    Parent       = fill.Instance,
                    Name         = "\0",
                    CornerRadius = UDimNew(1, 0),
                })

                -- value text (right side)
                local valLabel = Instances:Create("TextLabel", {
                    Parent              = Items["StatBar"].Instance,
                    Name                = "\0",
                    FontFace            = Library.Font,
                    TextColor3          = FromRGB(160, 160, 170),
                    Text                = "0 / 100",
                    AnchorPoint         = Vector2New(1, 0),
                    Size                = UDim2New(0, VAL_W, 0, SEG_H),
                    Position            = UDim2New(1, -4, 0, yOff),
                    BackgroundTransparency = 1,
                    TextXAlignment      = Enum.TextXAlignment.Right,
                    TextSize            = 11,
                    ZIndex              = 2,
                    BorderSizePixel     = 0,
                    BackgroundColor3    = FromRGB(255, 255, 255),
                }) valLabel:AddToTheme({TextColor3 = "SubText"})

                StatBar.SegmentUI[seg.Label] = {
                    Fill       = fill,
                    ValueLabel = valLabel,
                    BarBg      = barBg,
                    SegData    = seg,
                }
            end
        end

        -- ── Public API ─────────────────────────────────────────────────────
        function StatBar:SetSegment(label, current, max)
            local ui = StatBar.SegmentUI[label]
            if not ui then return end

            current = math.max(0, current or 0)
            max     = math.max(1, max     or 100)

            ui.SegData.Current = current
            ui.SegData.Max     = max

            local ratio = math.clamp(current / max, 0, 1)

            -- animate fill width
            ui.Fill:Tween(
                TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = UDim2New(ratio, 0, 1, 0)}
            )

            -- update value text
            ui.ValueLabel.Instance.Text = string.format("%d / %d", current, max)

            -- update Flags
            if not Library.Flags[StatBar.Flag] then
                Library.Flags[StatBar.Flag] = {}
            end
            Library.Flags[StatBar.Flag][label] = {Current = current, Max = max}

            Library:SafeCall(StatBar.Callback, label, current, max)
        end

        function StatBar:Get()
            local out = {}
            for label, ui in pairs(StatBar.SegmentUI) do
                out[label] = {Current = ui.SegData.Current, Max = ui.SegData.Max}
            end
            return out
        end

        function StatBar:SetVisibility(Bool)
            Items["StatBar"].Instance.Visible = Bool
        end

        function StatBar:RefreshPosition(Bool)
            if Bool then
                Items["Title"]:Tween(
                    TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                    {Position = UDim2New(0, 0, 0, 16)}
                )
            else
                Items["Title"].Instance.Position = UDim2New(0, 30, 0, 16)
            end
        end

        -- ── Registration ───────────────────────────────────────────────────
        Library.Flags[StatBar.Flag] = {}

        if StatBar.Section.Page and StatBar.Section.Page.Active then
            StatBar:RefreshPosition(true)
        end

        StatBar.Section.Elements[#StatBar.Section.Elements + 1] = StatBar

        if Data.ToolTip or Data.tooltip then
            Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["StatBar"].Instance)
        end

        return StatBar
    end
    -- ─────────────────────────────────────────────────────────────────────────

    -- ─────────────────────────────────────────────────────────────────────────
    -- MultiToggle: compact grid of named checkboxes sharing one flag + callback
    -- API: :SetItem(key,bool), :Set({key=bool}), :Get()→{key=bool}
    -- Callback({key=bool}) fires on every change
    -- ─────────────────────────────────────────────────────────────────────────
    Library.Sections.MultiToggle = function(self, Data)
        Data = Data or {}

        local MultiToggle = {
            Window   = self.Window,
            Page     = self.Page,
            Section  = self,

            Name     = Data.Name    or Data.name    or "MultiToggle",
            Flag     = Data.Flag    or Data.flag    or Library:NextFlag(),
            Callback = Data.Callback or Data.callback or function() end,
            Columns  = Data.Columns or Data.columns or 3,

            Value    = {},
            ItemMeta = {},
        }

        local itemList = Data.Items   or Data.items   or {}
        local defaults = Data.Default or Data.default or {}

        for _, k in ipairs(itemList) do
            MultiToggle.Value[k] = defaults[k] == true
        end

        local CELL_H  = 22
        local TITLE_H = 32
        local ROW_GAP = 3
        local cols    = MultiToggle.Columns
        local rows    = math.ceil(#itemList / cols)
        local totalH  = TITLE_H + rows * (CELL_H + ROW_GAP)

        local Items = {} do
            Items["Root"] = Instances:Create("Frame", {
                Parent               = MultiToggle.Section.Items["Content"].Instance,
                Name                 = "\0",
                BackgroundTransparency = 1,
                Size                 = UDim2New(1, 0, 0, totalH),
                BorderSizePixel      = 0,
                ZIndex               = 2,
                BackgroundColor3     = FromRGB(255, 255, 255),
            })

            Items["Title"] = Instances:Create("TextLabel", {
                Parent               = Items["Root"].Instance,
                Name                 = "\0",
                FontFace             = Library.Font,
                TextColor3           = FromRGB(240, 240, 240),
                TextTransparency     = 0.3,
                Text                 = MultiToggle.Name,
                AutomaticSize        = Enum.AutomaticSize.X,
                Size                 = UDim2New(0, 0, 0, 15),
                AnchorPoint          = Vector2New(0, 0.5),
                Position             = UDim2New(0, 30, 0, TITLE_H / 2),
                BorderSizePixel      = 0,
                BackgroundTransparency = 1,
                ZIndex               = 2,
                TextSize             = 14,
                BackgroundColor3     = FromRGB(255, 255, 255),
            }) Items["Title"]:AddToTheme({TextColor3 = "Text"})

            local rowContainer = Instances:Create("Frame", {
                Parent               = Items["Root"].Instance,
                Name                 = "\0",
                BackgroundTransparency = 1,
                Position             = UDim2New(0, 0, 0, TITLE_H),
                Size                 = UDim2New(1, 0, 0, rows * (CELL_H + ROW_GAP)),
                BorderSizePixel      = 0,
                ZIndex               = 2,
                BackgroundColor3     = FromRGB(255, 255, 255),
            })

            Instances:Create("UIListLayout", {
                Parent        = rowContainer.Instance,
                Name          = "\0",
                FillDirection = Enum.FillDirection.Vertical,
                Padding       = UDimNew(0, ROW_GAP),
                SortOrder     = Enum.SortOrder.LayoutOrder,
            })

            for i, itemName in ipairs(itemList) do
                local rowIdx = math.ceil(i / cols)
                local rowKey = "Row_" .. rowIdx

                if not Items[rowKey] then
                    Items[rowKey] = Instances:Create("Frame", {
                        Parent               = rowContainer.Instance,
                        Name                 = "\0",
                        BackgroundTransparency = 1,
                        Size                 = UDim2New(1, 0, 0, CELL_H),
                        BorderSizePixel      = 0,
                        ZIndex               = 2,
                        BackgroundColor3     = FromRGB(255, 255, 255),
                    })

                    Instances:Create("UIListLayout", {
                        Parent        = Items[rowKey].Instance,
                        Name          = "\0",
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder     = Enum.SortOrder.LayoutOrder,
                    })
                end

                local cell = Instances:Create("TextButton", {
                    Parent               = Items[rowKey].Instance,
                    Name                 = "\0",
                    Text                 = "",
                    AutoButtonColor      = false,
                    BackgroundTransparency = 1,
                    Size                 = UDim2New(1 / cols, 0, 1, 0),
                    BorderSizePixel      = 0,
                    ZIndex               = 2,
                    BackgroundColor3     = FromRGB(255, 255, 255),
                })

                local INDIC = 14
                local indic = Instances:Create("Frame", {
                    Parent           = cell.Instance,
                    Name             = "\0",
                    Size             = UDim2New(0, INDIC, 0, INDIC),
                    AnchorPoint      = Vector2New(0, 0.5),
                    Position         = UDim2New(0, 4, 0.5, 0),
                    BorderSizePixel  = 0,
                    ZIndex           = 3,
                    BackgroundColor3 = FromRGB(35, 33, 42),
                }) indic:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent       = indic.Instance,
                    Name         = "\0",
                    CornerRadius = UDimNew(0, 3),
                })

                Instances:Create("UIStroke", {
                    Parent          = indic.Instance,
                    Name            = "\0",
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Color           = FromRGB(50, 45, 60),
                    Transparency    = 0.5,
                }):AddToTheme({Color = "Outline"})

                local indicGrad = Instances:Create("UIGradient", {
                    Parent   = indic.Instance,
                    Name     = "\0",
                    Enabled  = false,
                    Rotation = -115,
                    Color    = RGBSequence{
                        RGBSequenceKeypoint(0, Library.Theme.Accent),
                        RGBSequenceKeypoint(1, Library.Theme.Accent),
                    },
                }) indicGrad:AddToTheme({Color = function()
                    return RGBSequence{
                        RGBSequenceKeypoint(0, Library.Theme.Accent),
                        RGBSequenceKeypoint(1, Library.Theme.Accent),
                    }
                end})

                local checkImg = Instances:Create("ImageLabel", {
                    Parent               = indic.Instance,
                    Name                 = "\0",
                    Size                 = UDim2New(0, 0, 0, 0),
                    AnchorPoint          = Vector2New(0.5, 0.5),
                    Position             = UDim2New(0.5, 0, 0.5, 0),
                    Image                = "rbxassetid://121760666525660",
                    BackgroundTransparency = 1,
                    ZIndex               = 4,
                    BorderSizePixel      = 0,
                    ImageTransparency    = 1,
                    BackgroundColor3     = FromRGB(255, 255, 255),
                })

                local itemLbl = Instances:Create("TextLabel", {
                    Parent               = cell.Instance,
                    Name                 = "\0",
                    FontFace             = Library.Font,
                    TextColor3           = FromRGB(200, 200, 210),
                    TextTransparency     = 0.3,
                    Text                 = itemName,
                    AutomaticSize        = Enum.AutomaticSize.X,
                    Size                 = UDim2New(0, 0, 1, 0),
                    Position             = UDim2New(0, INDIC + 8, 0, 0),
                    BackgroundTransparency = 1,
                    TextSize             = 13,
                    ZIndex               = 3,
                    BorderSizePixel      = 0,
                    BackgroundColor3     = FromRGB(255, 255, 255),
                    TextXAlignment       = Enum.TextXAlignment.Left,
                }) itemLbl:AddToTheme({TextColor3 = "Text"})

                MultiToggle.ItemMeta[itemName] = {
                    Indic     = indic,
                    IndicGrad = indicGrad,
                    CheckImg  = checkImg,
                    Lbl       = itemLbl,
                }

                do
                    local _k = itemName
                    cell:Connect("MouseButton1Click", function()
                        MultiToggle:SetItem(_k, not MultiToggle.Value[_k])
                    end)
                end
            end
        end

        local function ApplyItemVisual(key, value)
            local m = MultiToggle.ItemMeta[key]
            if not m then return end
            local CS = 10
            if value then
                m.IndicGrad.Instance.Enabled = true
                m.Indic:ChangeItemTheme({BackgroundColor3 = function() return Library.Theme.Accent end})
                m.Indic:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Library.Theme.Accent})
                m.CheckImg:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ImageTransparency = 0, Size = UDim2New(0, CS, 0, CS)})
                m.Lbl:Tween(nil, {TextTransparency = 0})
            else
                m.IndicGrad.Instance.Enabled = false
                m.Indic:ChangeItemTheme({BackgroundColor3 = "Element"})
                m.Indic:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Library.Theme.Element})
                m.CheckImg:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ImageTransparency = 1, Size = UDim2New(0, 0, 0, 0)})
                m.Lbl:Tween(nil, {TextTransparency = 0.3})
            end
        end

        function MultiToggle:SetItem(key, value)
            if MultiToggle.Value[key] == nil then return end
            MultiToggle.Value[key] = value
            ApplyItemVisual(key, value)
            Library.Flags[MultiToggle.Flag] = MultiToggle.Value
            Library:SafeCall(MultiToggle.Callback, MultiToggle.Value)
        end

        function MultiToggle:Set(values)
            for k in pairs(MultiToggle.Value) do
                local nv = values[k] == true
                MultiToggle.Value[k] = nv
                ApplyItemVisual(k, nv)
            end
            Library.Flags[MultiToggle.Flag] = MultiToggle.Value
            Library:SafeCall(MultiToggle.Callback, MultiToggle.Value)
        end

        function MultiToggle:Get()
            local copy = {}
            for k, v in pairs(MultiToggle.Value) do copy[k] = v end
            return copy
        end

        function MultiToggle:SetVisibility(Bool)
            Items["Root"].Instance.Visible = Bool
        end

        function MultiToggle:RefreshPosition(Bool)
            if Bool then
                Items["Title"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, TITLE_H / 2)})
            else
                Items["Title"].Instance.Position = UDim2New(0, 30, 0, TITLE_H / 2)
            end
        end

        for _, k in ipairs(itemList) do
            ApplyItemVisual(k, MultiToggle.Value[k])
        end

        Library.Flags[MultiToggle.Flag] = MultiToggle.Value

        Library.SetFlags[MultiToggle.Flag] = function(Value)
            MultiToggle:Set(Value)
        end

        if MultiToggle.Section.Page and MultiToggle.Section.Page.Active then
            MultiToggle:RefreshPosition(true)
        end

        MultiToggle.Section.Elements[#MultiToggle.Section.Elements + 1] = MultiToggle

        if Data.ToolTip or Data.tooltip then
            Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Root"].Instance)
        end

        return MultiToggle
    end
    -- ─────────────────────────────────────────────────────────────────────────

    -- ─────────────────────────────────────────────────────────────────────────
    -- ButtonGroup: always-visible exclusive-select button row (radio pill style)
    -- API: :Set(value), :Get()→string
    -- Callback(value) fires on selection change
    -- ─────────────────────────────────────────────────────────────────────────
    Library.Sections.ButtonGroup = function(self, Data)
        Data = Data or {}

        local ButtonGroup = {
            Window   = self.Window,
            Page     = self.Page,
            Section  = self,

            Name     = Data.Name     or Data.name     or "ButtonGroup",
            Flag     = Data.Flag     or Data.flag     or Library:NextFlag(),
            Callback = Data.Callback or Data.callback or function() end,

            Value    = nil,
            BtnMeta  = {},
        }

        local itemList = Data.Items   or Data.items   or {}
        local default  = Data.Default or Data.default or itemList[1]

        local Items = {} do
            Items["Root"] = Instances:Create("Frame", {
                Parent               = ButtonGroup.Section.Items["Content"].Instance,
                Name                 = "\0",
                BackgroundTransparency = 1,
                Size                 = UDim2New(1, 0, 0, 32),
                BorderSizePixel      = 0,
                ZIndex               = 2,
                BackgroundColor3     = FromRGB(255, 255, 255),
            })

            Items["Title"] = Instances:Create("TextLabel", {
                Parent               = Items["Root"].Instance,
                Name                 = "\0",
                FontFace             = Library.Font,
                TextColor3           = FromRGB(240, 240, 240),
                TextTransparency     = 0.3,
                Text                 = ButtonGroup.Name,
                AutomaticSize        = Enum.AutomaticSize.X,
                Size                 = UDim2New(0, 0, 0, 15),
                AnchorPoint          = Vector2New(0, 0.5),
                Position             = UDim2New(0, 30, 0.5, 0),
                BorderSizePixel      = 0,
                BackgroundTransparency = 1,
                ZIndex               = 2,
                TextSize             = 14,
                BackgroundColor3     = FromRGB(255, 255, 255),
            }) Items["Title"]:AddToTheme({TextColor3 = "Text"})

            Items["BtnRowBg"] = Instances:Create("Frame", {
                Parent           = Items["Root"].Instance,
                Name             = "\0",
                AnchorPoint      = Vector2New(1, 0.5),
                Position         = UDim2New(1, -4, 0.5, 0),
                Size             = UDim2New(0.56, 0, 0, 22),
                BackgroundColor3 = FromRGB(27, 26, 29),
                BorderSizePixel  = 0,
                ZIndex           = 2,
                ClipsDescendants = true,
            }) Items["BtnRowBg"]:AddToTheme({BackgroundColor3 = "Element"})

            Instances:Create("UIStroke", {
                Parent          = Items["BtnRowBg"].Instance,
                Name            = "\0",
                Color           = FromRGB(50, 45, 60),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }):AddToTheme({Color = "Outline"})

            Instances:Create("UICorner", {
                Parent       = Items["BtnRowBg"].Instance,
                Name         = "\0",
                CornerRadius = UDimNew(0, 5),
            })

            Instances:Create("UIListLayout", {
                Parent        = Items["BtnRowBg"].Instance,
                Name          = "\0",
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder     = Enum.SortOrder.LayoutOrder,
            })

            local n = #itemList
            for i, optName in ipairs(itemList) do
                local btn = Instances:Create("TextButton", {
                    Parent               = Items["BtnRowBg"].Instance,
                    Name                 = "\0",
                    Text                 = "",
                    AutoButtonColor      = false,
                    Size                 = UDim2New(1 / n, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel      = 0,
                    ZIndex               = 3,
                    BackgroundColor3     = FromRGB(255, 255, 255),
                })

                local btnFill = Instances:Create("Frame", {
                    Parent               = btn.Instance,
                    Name                 = "\0",
                    Size                 = UDim2New(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel      = 0,
                    ZIndex               = 3,
                    BackgroundColor3     = FromRGB(80, 50, 120),
                })

                Instances:Create("UIGradient", {
                    Parent   = btnFill.Instance,
                    Name     = "\0",
                    Rotation = -115,
                    Color    = RGBSequence{
                        RGBSequenceKeypoint(0, Library.Theme.Accent),
                        RGBSequenceKeypoint(1, Library.Theme.AccentGradient),
                    },
                }):AddToTheme({Color = function()
                    return RGBSequence{
                        RGBSequenceKeypoint(0, Library.Theme.Accent),
                        RGBSequenceKeypoint(1, Library.Theme.AccentGradient),
                    }
                end})

                local btnText = Instances:Create("TextLabel", {
                    Parent               = btn.Instance,
                    Name                 = "\0",
                    FontFace             = Library.Font,
                    TextColor3           = FromRGB(200, 200, 210),
                    TextTransparency     = 0.4,
                    Text                 = optName,
                    AutomaticSize        = Enum.AutomaticSize.X,
                    AnchorPoint          = Vector2New(0.5, 0.5),
                    Size                 = UDim2New(0, 0, 0, 14),
                    Position             = UDim2New(0.5, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    TextSize             = 12,
                    ZIndex               = 4,
                    BorderSizePixel      = 0,
                    BackgroundColor3     = FromRGB(255, 255, 255),
                }) btnText:AddToTheme({TextColor3 = "Text"})

                if i < n then
                    Instances:Create("Frame", {
                        Parent               = btn.Instance,
                        Name                 = "\0",
                        AnchorPoint          = Vector2New(1, 0.5),
                        Position             = UDim2New(1, 0, 0.5, 0),
                        Size                 = UDim2New(0, 1, 0.55, 0),
                        BackgroundColor3     = FromRGB(50, 45, 60),
                        BackgroundTransparency = 0.4,
                        BorderSizePixel      = 0,
                        ZIndex               = 4,
                        BackgroundColor3     = FromRGB(255, 255, 255),
                    }):AddToTheme({BackgroundColor3 = "Outline"})
                end

                ButtonGroup.BtnMeta[optName] = { Btn = btn, BtnText = btnText, BtnFill = btnFill }

                do
                    local _opt = optName
                    btn:Connect("MouseButton1Click", function()
                        ButtonGroup:Set(_opt)
                    end)
                end
            end
        end

        local function ApplySelection(selected)
            for optName, meta in pairs(ButtonGroup.BtnMeta) do
                if optName == selected then
                    meta.BtnFill:Tween(nil, {BackgroundTransparency = 0.15})
                    meta.BtnText:Tween(nil, {TextTransparency = 0})
                else
                    meta.BtnFill:Tween(nil, {BackgroundTransparency = 1})
                    meta.BtnText:Tween(nil, {TextTransparency = 0.4})
                    meta.BtnText:ChangeItemTheme({TextColor3 = "Text"})
                end
            end
        end

        function ButtonGroup:Set(value)
            if not ButtonGroup.BtnMeta[value] then return end
            ButtonGroup.Value = value
            Library.Flags[ButtonGroup.Flag] = value
            ApplySelection(value)
            Library:SafeCall(ButtonGroup.Callback, value)
        end

        function ButtonGroup:Get()
            return ButtonGroup.Value
        end

        function ButtonGroup:SetVisibility(Bool)
            Items["Root"].Instance.Visible = Bool
        end

        function ButtonGroup:RefreshPosition(Bool)
            if Bool then
                Items["Title"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
            else
                Items["Title"].Instance.Position = UDim2New(0, 30, 0.5, 0)
            end
        end

        if default then
            ButtonGroup:Set(default)
        end

        Library.SetFlags[ButtonGroup.Flag] = function(Value)
            ButtonGroup:Set(Value)
        end

        if ButtonGroup.Section.Page and ButtonGroup.Section.Page.Active then
            ButtonGroup:RefreshPosition(true)
        end

        ButtonGroup.Section.Elements[#ButtonGroup.Section.Elements + 1] = ButtonGroup

        if Data.ToolTip or Data.tooltip then
            Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Root"].Instance)
        end

        return ButtonGroup
    end
    -- ─────────────────────────────────────────────────────────────────────────

    -- ─────────────────────────────────────────────────────────────────────────
    -- ComboInput: Toggle + inline secondary control (Slider or Dropdown) in one row
    -- Control.Type = "Slider"   → drag slider on the right, locked when toggle is OFF
    -- Control.Type = "Dropdown" → cycle-on-click selector, locked when toggle is OFF
    -- API: :SetToggle(bool), :SetControl(value), :Get()→{Toggle,Control}
    -- Callback(toggleEnabled, controlValue) fires on any change
    -- ─────────────────────────────────────────────────────────────────────────
    Library.Sections.ComboInput = function(self, Data)
        Data = Data or {}

        local ctrl = Data.Control or Data.control or {}

        local ComboInput = {
            Window      = self.Window,
            Page        = self.Page,
            Section     = self,

            Name        = Data.Name     or Data.name     or "ComboInput",
            Flag        = Data.Flag     or Data.flag     or Library:NextFlag(),
            Default     = Data.Default  ~= nil and Data.Default  or (Data.default ~= nil and Data.default or false),
            Callback    = Data.Callback or Data.callback or function() end,

            CtrlType    = ctrl.Type    or ctrl.type    or "Slider",
            CtrlFlag    = ctrl.Flag    or ctrl.flag    or Library:NextFlag(),
            CtrlMin     = ctrl.Min     or ctrl.min     or 0,
            CtrlMax     = ctrl.Max     or ctrl.max     or 100,
            CtrlStep    = ctrl.Step    or ctrl.step    or 1,
            CtrlSuffix  = ctrl.Suffix  or ctrl.suffix  or "",
            CtrlItems   = ctrl.Items   or ctrl.items   or {},

            ToggleValue = false,
            CtrlValue   = nil,
        }

        do
            local cd = ctrl.Default or ctrl.default
            if cd ~= nil then
                ComboInput.CtrlValue = cd
            elseif ComboInput.CtrlType == "Slider" then
                ComboInput.CtrlValue = ComboInput.CtrlMin
            elseif #ComboInput.CtrlItems > 0 then
                ComboInput.CtrlValue = ComboInput.CtrlItems[1]
            end
        end

        local INDIC_S = IsMobile and 18 or 24
        local CTRL_W  = 160

        local Items = {} do
            Items["Root"] = Instances:Create("Frame", {
                Parent               = ComboInput.Section.Items["Content"].Instance,
                Name                 = "\0",
                BackgroundTransparency = 1,
                Size                 = UDim2New(1, 0, 0, 32),
                BorderSizePixel      = 0,
                ZIndex               = 2,
                BackgroundColor3     = FromRGB(255, 255, 255),
            })

            -- toggle hit area (left side only, doesn't steal clicks from control)
            Items["ToggleHit"] = Instances:Create("TextButton", {
                Parent               = Items["Root"].Instance,
                Name                 = "\0",
                Text                 = "",
                AutoButtonColor      = false,
                BackgroundTransparency = 1,
                Size                 = UDim2New(1, -(CTRL_W + 10), 1, 0),
                BorderSizePixel      = 0,
                ZIndex               = 3,
                BackgroundColor3     = FromRGB(255, 255, 255),
            })

            -- indicator
            Items["Indicator"] = Instances:Create("Frame", {
                Parent           = Items["Root"].Instance,
                Name             = "\0",
                Size             = UDim2New(0, INDIC_S, 0, INDIC_S),
                Position         = UDim2New(0, 0, 0.5, -math.floor(INDIC_S / 2)),
                BorderSizePixel  = 0,
                ZIndex           = 4,
                BackgroundColor3 = FromRGB(35, 33, 42),
            }) Items["Indicator"]:AddToTheme({BackgroundColor3 = "Element"})

            Instances:Create("UICorner", {
                Parent       = Items["Indicator"].Instance,
                Name         = "\0",
                CornerRadius = UDimNew(0, 3),
            })

            Items["IndicStroke"] = Instances:Create("UIStroke", {
                Parent          = Items["Indicator"].Instance,
                Name            = "\0",
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Color           = FromRGB(0, 0, 0),
                Thickness       = 1,
                Transparency    = 0.5,
            }) Items["IndicStroke"]:AddToTheme({Color = "Outline"})

            Items["CheckImage"] = Instances:Create("ImageLabel", {
                Parent               = Items["Indicator"].Instance,
                Name                 = "\0",
                Size                 = UDim2New(0, 0, 0, 0),
                AnchorPoint          = Vector2New(0.5, 0.5),
                Position             = UDim2New(0.5, 0, 0.5, 0),
                Image                = "rbxassetid://121760666525660",
                BackgroundTransparency = 1,
                ZIndex               = 5,
                BorderSizePixel      = 0,
                ImageTransparency    = 1,
                BackgroundColor3     = FromRGB(255, 255, 255),
            })

            Items["IndicGrad"] = Instances:Create("UIGradient", {
                Parent   = Items["Indicator"].Instance,
                Name     = "\0",
                Enabled  = false,
                Rotation = -115,
                Color    = RGBSequence{
                    RGBSequenceKeypoint(0, Library.Theme.Accent),
                    RGBSequenceKeypoint(1, Library.Theme.Accent),
                },
            }) Items["IndicGrad"]:AddToTheme({Color = function()
                return RGBSequence{
                    RGBSequenceKeypoint(0, Library.Theme.Accent),
                    RGBSequenceKeypoint(1, Library.Theme.Accent),
                }
            end})

            Items["Title"] = Instances:Create("TextLabel", {
                Parent               = Items["Root"].Instance,
                Name                 = "\0",
                FontFace             = Library.Font,
                TextColor3           = FromRGB(240, 240, 240),
                TextTransparency     = 0.3,
                Text                 = ComboInput.Name,
                AutomaticSize        = Enum.AutomaticSize.X,
                Size                 = UDim2New(0, 0, 0, 15),
                AnchorPoint          = Vector2New(0, 0.5),
                Position             = UDim2New(0, INDIC_S + 6, 0.5, 0),
                BorderSizePixel      = 0,
                BackgroundTransparency = 1,
                ZIndex               = 2,
                TextSize             = 14,
                BackgroundColor3     = FromRGB(255, 255, 255),
            }) Items["Title"]:AddToTheme({TextColor3 = "Text"})

            -- control area (right side)
            Items["CtrlArea"] = Instances:Create("Frame", {
                Parent               = Items["Root"].Instance,
                Name                 = "\0",
                AnchorPoint          = Vector2New(1, 0.5),
                Position             = UDim2New(1, -4, 0.5, 0),
                Size                 = UDim2New(0, CTRL_W, 0, 22),
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                ZIndex               = 2,
                BackgroundColor3     = FromRGB(255, 255, 255),
            })

            -- dim overlay (covers control when toggle is OFF)
            Items["CtrlLock"] = Instances:Create("Frame", {
                Parent               = Items["CtrlArea"].Instance,
                Name                 = "\0",
                Size                 = UDim2New(1, 0, 1, 0),
                BackgroundColor3     = FromRGB(20, 18, 25),
                BackgroundTransparency = 0.45,
                BorderSizePixel      = 0,
                ZIndex               = 10,
                BackgroundColor3     = FromRGB(255, 255, 255),
            })
            Instances:Create("UICorner", {
                Parent       = Items["CtrlLock"].Instance,
                Name         = "\0",
                CornerRadius = UDimNew(0, 4),
            })

            -- ── Slider control ─────────────────────────────────────────────
            if ComboInput.CtrlType == "Slider" then
                local initRatio = (ComboInput.CtrlValue - ComboInput.CtrlMin) / math.max(1, ComboInput.CtrlMax - ComboInput.CtrlMin)

                Items["CtrlValueLbl"] = Instances:Create("TextLabel", {
                    Parent               = Items["CtrlArea"].Instance,
                    Name                 = "\0",
                    FontFace             = Library.Font,
                    TextColor3           = FromRGB(190, 190, 200),
                    Text                 = tostring(ComboInput.CtrlValue) .. (ComboInput.CtrlSuffix ~= "" and (" " .. ComboInput.CtrlSuffix) or ""),
                    AnchorPoint          = Vector2New(1, 0.5),
                    Size                 = UDim2New(0, 40, 0, 14),
                    Position             = UDim2New(1, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment       = Enum.TextXAlignment.Right,
                    TextSize             = 12,
                    ZIndex               = 3,
                    BorderSizePixel      = 0,
                    BackgroundColor3     = FromRGB(255, 255, 255),
                })

                Items["TrackBg"] = Instances:Create("Frame", {
                    Parent           = Items["CtrlArea"].Instance,
                    Name             = "\0",
                    AnchorPoint      = Vector2New(0, 0.5),
                    Position         = UDim2New(0, 0, 0.5, 0),
                    Size             = UDim2New(1, -46, 0, 4),
                    BackgroundColor3 = FromRGB(35, 33, 42),
                    BorderSizePixel  = 0,
                    ZIndex           = 3,
                    ClipsDescendants = true,
                }) Items["TrackBg"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UIStroke", {
                    Parent          = Items["TrackBg"].Instance,
                    Name            = "\0",
                    Color           = FromRGB(50, 45, 60),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }):AddToTheme({Color = "Outline"})

                Instances:Create("UICorner", {
                    Parent       = Items["TrackBg"].Instance,
                    Name         = "\0",
                    CornerRadius = UDimNew(1, 0),
                })

                Items["TrackFill"] = Instances:Create("Frame", {
                    Parent           = Items["TrackBg"].Instance,
                    Name             = "\0",
                    Size             = UDim2New(math.clamp(initRatio, 0, 1), 0, 1, 0),
                    BackgroundColor3 = FromRGB(130, 80, 220),
                    BorderSizePixel  = 0,
                    ZIndex           = 4,
                })

                Instances:Create("UIGradient", {
                    Parent   = Items["TrackFill"].Instance,
                    Name     = "\0",
                    Rotation = -115,
                    Color    = RGBSequence{
                        RGBSequenceKeypoint(0, Library.Theme.Accent),
                        RGBSequenceKeypoint(1, Library.Theme.AccentGradient),
                    },
                }):AddToTheme({Color = function()
                    return RGBSequence{
                        RGBSequenceKeypoint(0, Library.Theme.Accent),
                        RGBSequenceKeypoint(1, Library.Theme.AccentGradient),
                    }
                end})

                Instances:Create("UICorner", {
                    Parent       = Items["TrackFill"].Instance,
                    Name         = "\0",
                    CornerRadius = UDimNew(1, 0),
                })

                Items["TrackHit"] = Instances:Create("TextButton", {
                    Parent               = Items["TrackBg"].Instance,
                    Name                 = "\0",
                    Text                 = "",
                    AutoButtonColor      = false,
                    BackgroundTransparency = 1,
                    Size                 = UDim2New(1, 0, 0, 20),
                    AnchorPoint          = Vector2New(0, 0.5),
                    Position             = UDim2New(0, 0, 0.5, 0),
                    BorderSizePixel      = 0,
                    ZIndex               = 5,
                    BackgroundColor3     = FromRGB(255, 255, 255),
                })

                do
                    local dragging = false

                    local function CalcVal(pos)
                        local ab = Items["TrackBg"].Instance.AbsolutePosition
                        local sz = Items["TrackBg"].Instance.AbsoluteSize
                        local r  = math.clamp((pos.X - ab.X) / math.max(1, sz.X), 0, 1)
                        local raw = ComboInput.CtrlMin + r * (ComboInput.CtrlMax - ComboInput.CtrlMin)
                        return math.clamp(math.round(raw / ComboInput.CtrlStep) * ComboInput.CtrlStep, ComboInput.CtrlMin, ComboInput.CtrlMax)
                    end

                    local function ApplySlider(val)
                        ComboInput.CtrlValue = val
                        Library.Flags[ComboInput.CtrlFlag] = val
                        local r = (val - ComboInput.CtrlMin) / math.max(1, ComboInput.CtrlMax - ComboInput.CtrlMin)
                        Items["TrackFill"]:Tween(TweenInfo.new(0.06, Enum.EasingStyle.Linear), {Size = UDim2New(r, 0, 1, 0)})
                        local sfx = ComboInput.CtrlSuffix ~= "" and (" " .. ComboInput.CtrlSuffix) or ""
                        Items["CtrlValueLbl"].Instance.Text = tostring(val) .. sfx
                        Library:SafeCall(ComboInput.Callback, ComboInput.ToggleValue, val)
                    end

                    Items["TrackHit"]:Connect("InputBegan", function(inp)
                        if not ComboInput.ToggleValue then return end
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            ApplySlider(CalcVal(inp.Position))
                        end
                    end)

                    Library:Connect(UserInputService.InputChanged, function(inp)
                        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                            ApplySlider(CalcVal(inp.Position))
                        end
                    end)

                    Library:Connect(UserInputService.InputEnded, function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                        end
                    end)
                end

            -- ── Dropdown control ───────────────────────────────────────────
            elseif ComboInput.CtrlType == "Dropdown" then
                Items["CtrlBtn"] = Instances:Create("TextButton", {
                    Parent               = Items["CtrlArea"].Instance,
                    Name                 = "\0",
                    Text                 = "",
                    AutoButtonColor      = false,
                    Size                 = UDim2New(1, 0, 1, 0),
                    BackgroundColor3     = FromRGB(27, 26, 29),
                    BorderSizePixel      = 0,
                    ZIndex               = 3,
                    BackgroundColor3     = FromRGB(255, 255, 255),
                }) Items["CtrlBtn"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UIStroke", {
                    Parent          = Items["CtrlBtn"].Instance,
                    Name            = "\0",
                    Color           = FromRGB(50, 45, 60),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }):AddToTheme({Color = "Outline"})

                Instances:Create("UICorner", {
                    Parent       = Items["CtrlBtn"].Instance,
                    Name         = "\0",
                    CornerRadius = UDimNew(0, 4),
                })

                Items["CtrlValueLbl"] = Instances:Create("TextLabel", {
                    Parent               = Items["CtrlBtn"].Instance,
                    Name                 = "\0",
                    FontFace             = Library.Font,
                    TextColor3           = FromRGB(200, 200, 210),
                    Text                 = tostring(ComboInput.CtrlValue or ""),
                    AnchorPoint          = Vector2New(0, 0.5),
                    Size                 = UDim2New(1, -22, 0, 14),
                    Position             = UDim2New(0, 8, 0.5, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    TextSize             = 12,
                    ZIndex               = 4,
                    BorderSizePixel      = 0,
                    BackgroundColor3     = FromRGB(255, 255, 255),
                    ClipsDescendants     = true,
                }) Items["CtrlValueLbl"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("ImageLabel", {
                    Parent               = Items["CtrlBtn"].Instance,
                    Name                 = "\0",
                    ImageColor3          = FromRGB(141, 141, 150),
                    AnchorPoint          = Vector2New(1, 0.5),
                    Size                 = UDim2New(0, 12, 0, 6),
                    Position             = UDim2New(1, -5, 0.5, 0),
                    Image                = "rbxassetid://123317177279443",
                    BackgroundTransparency = 1,
                    ZIndex               = 4,
                    BorderSizePixel      = 0,
                    BackgroundColor3     = FromRGB(255, 255, 255),
                })

                do
                    local function ApplyDrop(val)
                        ComboInput.CtrlValue = val
                        Library.Flags[ComboInput.CtrlFlag] = val
                        Items["CtrlValueLbl"].Instance.Text = tostring(val)
                        Library:SafeCall(ComboInput.Callback, ComboInput.ToggleValue, val)
                    end

                    Items["CtrlBtn"]:Connect("MouseButton1Click", function()
                        if not ComboInput.ToggleValue then return end
                        local its = ComboInput.CtrlItems
                        if #its == 0 then return end
                        local cur = 1
                        for i, v in ipairs(its) do
                            if v == ComboInput.CtrlValue then cur = i break end
                        end
                        ApplyDrop(its[(cur % #its) + 1])
                    end)
                end
            end
        end

        -- ── toggle visual ──────────────────────────────────────────────────
        local function ApplyToggle(value, instant)
            local CS = IsMobile and 12 or 16
            if value then
                Items["IndicGrad"].Instance.Enabled = true
                Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = function() return Library.Theme.Accent end})
                if instant then
                    Items["Indicator"].Instance.BackgroundColor3 = Library.Theme.Accent
                    Items["CheckImage"].Instance.ImageTransparency = 0
                    Items["CheckImage"].Instance.Size = UDim2New(0, CS, 0, CS)
                    Items["IndicStroke"].Instance.Transparency = 1
                else
                    Items["Indicator"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Library.Theme.Accent})
                    Items["CheckImage"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ImageTransparency = 0, Size = UDim2New(0, CS, 0, CS)})
                    Items["IndicStroke"]:Tween(nil, {Transparency = 1})
                end
                Items["CtrlLock"]:Tween(nil, {BackgroundTransparency = 1})
            else
                Items["IndicGrad"].Instance.Enabled = false
                Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Element"})
                if instant then
                    Items["Indicator"].Instance.BackgroundColor3 = Library.Theme.Element
                    Items["CheckImage"].Instance.ImageTransparency = 1
                    Items["CheckImage"].Instance.Size = UDim2New(0, 0, 0, 0)
                    Items["IndicStroke"].Instance.Transparency = 0.5
                else
                    Items["Indicator"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Library.Theme.Element})
                    Items["CheckImage"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ImageTransparency = 1, Size = UDim2New(0, 0, 0, 0)})
                    Items["IndicStroke"]:Tween(nil, {Transparency = 0.5})
                end
                Items["CtrlLock"]:Tween(nil, {BackgroundTransparency = 0.45})
            end
        end

        -- ── Public API ─────────────────────────────────────────────────────
        function ComboInput:SetToggle(value, instant)
            ComboInput.ToggleValue = value
            Library.Flags[ComboInput.Flag] = value
            ApplyToggle(value, instant)
            Library:SafeCall(ComboInput.Callback, value, ComboInput.CtrlValue)
        end

        function ComboInput:SetControl(value)
            if ComboInput.CtrlType == "Slider" then
                value = math.clamp(tonumber(value) or ComboInput.CtrlMin, ComboInput.CtrlMin, ComboInput.CtrlMax)
                ComboInput.CtrlValue = value
                Library.Flags[ComboInput.CtrlFlag] = value
                local r = (value - ComboInput.CtrlMin) / math.max(1, ComboInput.CtrlMax - ComboInput.CtrlMin)
                if Items["TrackFill"] then
                    Items["TrackFill"]:Tween(TweenInfo.new(0.06, Enum.EasingStyle.Linear), {Size = UDim2New(r, 0, 1, 0)})
                end
                if Items["CtrlValueLbl"] then
                    local sfx = ComboInput.CtrlSuffix ~= "" and (" " .. ComboInput.CtrlSuffix) or ""
                    Items["CtrlValueLbl"].Instance.Text = tostring(value) .. sfx
                end
            elseif ComboInput.CtrlType == "Dropdown" then
                ComboInput.CtrlValue = value
                Library.Flags[ComboInput.CtrlFlag] = value
                if Items["CtrlValueLbl"] then
                    Items["CtrlValueLbl"].Instance.Text = tostring(value)
                end
            end
            Library:SafeCall(ComboInput.Callback, ComboInput.ToggleValue, value)
        end

        function ComboInput:Get()
            return { Toggle = ComboInput.ToggleValue, Control = ComboInput.CtrlValue }
        end

        function ComboInput:SetVisibility(Bool)
            Items["Root"].Instance.Visible = Bool
        end

        function ComboInput:RefreshPosition(Bool)
            if Bool then
                Items["Title"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, INDIC_S + 6, 0.5, 0)})
            else
                Items["Title"].Instance.Position = UDim2New(0, INDIC_S + 6, 0.5, 0)
            end
        end

        -- ── Toggle click ───────────────────────────────────────────────────
        Items["ToggleHit"]:Connect("MouseButton1Click", function()
            ComboInput:SetToggle(not ComboInput.ToggleValue)
        end)

        -- ── Init ───────────────────────────────────────────────────────────
        ComboInput:SetToggle(ComboInput.Default, true)

        Library.SetFlags[ComboInput.Flag] = function(Value)
            ComboInput:SetToggle(Value, true)
        end

        Library.SetFlags[ComboInput.CtrlFlag] = function(Value)
            ComboInput:SetControl(Value)
        end

        if ComboInput.Section.Page and ComboInput.Section.Page.Active then
            ComboInput:RefreshPosition(true)
        end

        ComboInput.Section.Elements[#ComboInput.Section.Elements + 1] = ComboInput

        if Data.ToolTip or Data.tooltip then
            Library:AddTooltip(Data.ToolTip or Data.tooltip, Items["Root"].Instance)
        end

        return ComboInput
    end
    -- ─────────────────────────────────────────────────────────────────────────

    -- ─────────────────────────────────────────────────────────────────────────
    -- Dashboard: built-in first tab, auto-generated, undeletable
    -- ─────────────────────────────────────────────────────────────────────────
    Library.CreateDashboard = function(self, Window)

        -- ── Bold font variant (headings) ──────────────────────────────────────
        local BoldFont = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

        -- ── Convenience colour aliases ────────────────────────────────────────
        local function Accent()   return Library.Theme["Accent"]         or FromRGB(151, 69, 186) end
        local function AccGrad()  return Library.Theme["AccentGradient"] or FromRGB(109, 43, 139) end
        local function Bg()       return Library.Theme["Background"]      or FromRGB(12, 12, 14)  end
        local function Elem()     return Library.Theme["Element"]         or FromRGB(18, 17, 22)  end
        local function Outline()  return Library.Theme["Outline"]         or FromRGB(40, 38, 46)  end
        local function Txt()      return Library.Theme["Text"]            or FromRGB(235,235,235) end

        -- ── Create page (Columns=0 → no auto columns, no sections) ───────────
        local DashPage = Window:Page({Name = "Dashboard", Icon = "house", Columns = 0})

        -- Pin dashboard tab button to LayoutOrder 1 so it is always first
        local DashBtn = DashPage.Items["Inactive"].Instance
        DashBtn.LayoutOrder = 1

        -- ── Separator spacer between Dashboard tab and dev tabs ───────────────
        local SepFr = InstanceNew("Frame")
        SepFr.Name       = "\0"
        SepFr.Size       = UDim2New(0.85, 0, 0, 1)
        SepFr.AnchorPoint = Vector2New(0.5, 0)
        SepFr.Position   = UDim2New(0.5, 0, 0, 0)
        SepFr.BackgroundColor3  = Outline()
        SepFr.BackgroundTransparency = 0.55
        SepFr.BorderSizePixel = 0
        SepFr.ZIndex       = 2
        SepFr.LayoutOrder  = 5
        SepFr.Parent = Window.Items["LeftTabs"].Instance
        -- Gradient: bright centre → fade sides
        local sepGrad = InstanceNew("UIGradient")
        sepGrad.Transparency = NumSequence{NumSequenceKeypoint(0,1), NumSequenceKeypoint(0.3,0), NumSequenceKeypoint(0.7,0), NumSequenceKeypoint(1,1)}
        sepGrad.Parent = SepFr

        -- ── Forward-declare RefreshCards (used by ChildAdded below) ───────────
        local RefreshCards
        local cardSlots  = {}   -- [{btn,icon,title,stroke,glow}×3]
        local cardPages  = {nil, nil, nil}

        -- ── Auto-assign LayoutOrder to dev tabs as they are created ───────────
        -- Every child that isn't the Dashboard button or the separator must land
        -- at LayoutOrder >= 100 so it sorts AFTER Dashboard (1) and separator (5).
        -- This covers: TextButton page-tab buttons, TextLabel category labels,
        -- and Frame collapsible-category containers.
        local devTabSeq = 0
        Window.Items["LeftTabs"].Instance.ChildAdded:Connect(function(child)
            if child == DashBtn or child == SepFr then return end
            -- Skip pure layout helpers (UIListLayout, UIPadding, etc.)
            if child:IsA("UIListLayout") or child:IsA("UIPadding") or
               child:IsA("UICorner")     or child:IsA("UIStroke")  or
               child:IsA("UIGradient")   or child:IsA("UIScale") then return end

            devTabSeq = devTabSeq + 1
            child.LayoutOrder = 100 + devTabSeq

            -- Only trigger card refresh for actual page tab buttons
            if child:IsA("TextButton") then
                task.wait()     -- let Library.Page finish TableInsert to Window.Pages
                if Library and RefreshCards then RefreshCards() end
            end
        end)

        -- ── Strip default column layout from the page frame ───────────────────
        local PageFr = DashPage.Items["Page"].Instance
        for _, ch in ipairs(PageFr:GetChildren()) do
            if ch:IsA("UIListLayout") or ch:IsA("UIPadding") then ch:Destroy() end
        end

        -- ═══════════════════════════════════════════════════════════════════════
        --  DASHBOARD CONTENT
        -- ═══════════════════════════════════════════════════════════════════════
        -- PageFr fills the Content area (window minus 55px header).
        -- Approximate real size: ~452 × 589 px.
        -- Layout:
        --   Top section  0 → 62%   (header + right panel)
        --   Divider line ~62%
        --   Cards row    64% → 100% (~225px)

        local TOP_FRAC  = 0.60   -- top section height fraction
        local CARD_FRAC = 0.36   -- cards row height fraction
        local PAD       = 14     -- standard padding px

        -- ── Main wrapper ──────────────────────────────────────────────────────
        local Main = InstanceNew("Frame")
        Main.Size = UDim2New(1,0,1,0)
        Main.BackgroundTransparency = 1
        Main.BorderSizePixel = 0
        Main.ZIndex = 2
        Main.Name = "\0"
        Main.Parent = PageFr

        -- Soft purple ambient glow at the top of the page
        local TopGlow = InstanceNew("Frame")
        TopGlow.Size = UDim2New(1,0, 0, 260)
        TopGlow.BackgroundColor3 = Accent()
        TopGlow.BackgroundTransparency = 0.93
        TopGlow.BorderSizePixel = 0
        TopGlow.ZIndex = 2
        TopGlow.Name = "\0"
        TopGlow.Parent = Main
        local tgGrad = InstanceNew("UIGradient")
        tgGrad.Rotation = 90
        tgGrad.Transparency = NumSequence{NumSequenceKeypoint(0,0), NumSequenceKeypoint(0.65,0.4), NumSequenceKeypoint(1,1)}
        tgGrad.Parent = TopGlow

        -- ── LEFT CONTENT (headings + sub-text + social) ───────────────────────
        local Left = InstanceNew("Frame")
        Left.Size     = UDim2New(0.58, 0, TOP_FRAC, 0)
        Left.Position = UDim2New(0, 0, 0, 0)
        Left.BackgroundTransparency = 1
        Left.BorderSizePixel = 0
        Left.ZIndex = 3
        Left.Name = "\0"
        Left.Parent = Main

        local function LeftLabel(y, txt, tsz, col, transp, fnt)
            local l = InstanceNew("TextLabel")
            l.FontFace    = fnt or Library.Font
            l.Text        = txt
            l.TextColor3  = col
            l.TextTransparency = transp or 0
            l.TextSize    = tsz
            l.Size        = UDim2New(1, -(PAD*2), 0, tsz + 6)
            l.Position    = UDim2New(0, PAD, 0, y)
            l.BackgroundTransparency = 1
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.ZIndex      = 4
            l.Name        = "\0"
            l.Parent      = Left
            return l
        end

        -- "WELCOME TO"
        LeftLabel(PAD,       "WELCOME TO",    15, Txt(),          0.25, BoldFont)

        -- "FREE VERSION" – accent gradient text
        local lbl2 = LeftLabel(PAD + 20,  "FREE VERSION",  24, Accent(),        0,    BoldFont)
        local g2 = InstanceNew("UIGradient")
        g2.Color = RGBSequence{RGBSequenceKeypoint(0, Accent()), RGBSequenceKeypoint(1, FromRGB(210, 130, 255))}
        g2.Rotation = 25
        g2.Parent = lbl2

        -- "OF IMP HUB"
        LeftLabel(PAD + 49,  "OF IMP HUB",   18, Txt(),          0.1,  BoldFont)

        -- Accent divider stripe
        local divFr = InstanceNew("Frame")
        divFr.Size = UDim2New(0, 55, 0, 2)
        divFr.Position = UDim2New(0, PAD, 0, PAD + 78)
        divFr.BackgroundColor3 = Accent()
        divFr.BackgroundTransparency = 0.25
        divFr.BorderSizePixel = 0
        divFr.ZIndex = 4
        divFr.Name = "\0"
        divFr.Parent = Left
        do
            local dc = InstanceNew("UICorner"); dc.CornerRadius = UDimNew(1,0); dc.Parent = divFr
            local dg = InstanceNew("UIGradient")
            dg.Color = RGBSequence{RGBSequenceKeypoint(0, Accent()), RGBSequenceKeypoint(1, AccGrad())}
            dg.Parent = divFr
        end

        -- Sub-text
        local subTxt = InstanceNew("TextLabel")
        subTxt.FontFace = Library.Font
        subTxt.Text = "Thanks for using our services.\nWe aim to provide the best experience possible."
        subTxt.TextColor3 = FromRGB(155, 152, 170)
        subTxt.TextTransparency = 0.05
        subTxt.TextSize = 12
        subTxt.Size = UDim2New(1, -(PAD*2), 0, 38)
        subTxt.Position = UDim2New(0, PAD, 0, PAD + 88)
        subTxt.BackgroundTransparency = 1
        subTxt.TextXAlignment = Enum.TextXAlignment.Left
        subTxt.TextYAlignment = Enum.TextYAlignment.Top
        subTxt.TextWrapped = true
        subTxt.ZIndex = 4
        subTxt.Name = "\0"
        subTxt.Parent = Left

        -- ── Social buttons ────────────────────────────────────────────────────
        local socialIcons = {}   -- populated inside MakeSocialBtn for theme updates
        local SocialRow = InstanceNew("Frame")
        SocialRow.Size = UDim2New(0, 80, 0, 30)
        SocialRow.Position = UDim2New(0, PAD, 0, PAD + 138)
        SocialRow.BackgroundTransparency = 1
        SocialRow.BorderSizePixel = 0
        SocialRow.ZIndex = 4
        SocialRow.Name = "\0"
        SocialRow.Parent = Left

        local function MakeSocialBtn(xOff, label, url, iconName)
            local btn = InstanceNew("TextButton")
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.Size = UDim2New(0, 30, 0, 30)
            btn.Position = UDim2New(0, xOff, 0, 0)
            btn.BackgroundColor3 = Elem()
            btn.BackgroundTransparency = 0.2
            btn.BorderSizePixel = 0
            btn.ZIndex = 5
            btn.Name = "\0"
            btn.Parent = SocialRow

            local bc = InstanceNew("UICorner"); bc.CornerRadius = UDimNew(1,0); bc.Parent = btn
            local bs = InstanceNew("UIStroke")
            bs.Color = Outline(); bs.Thickness = 1; bs.Transparency = 0.45
            bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; bs.Parent = btn

            -- Icon (try library icon; fall back to text initial)
            local iconData = Library:GetCustomIcon(iconName)
            if iconData and iconData.Url ~= "" then
                local img = InstanceNew("ImageLabel")
                img.Size = UDim2New(0, 16, 0, 16)
                img.AnchorPoint = Vector2New(0.5, 0.5)
                img.Position = UDim2New(0.5, 0, 0.5, 0)
                img.BackgroundTransparency = 1
                img.BorderSizePixel = 0
                img.ZIndex = 6
                img.Image = iconData.Url
                img.ImageRectOffset = iconData.ImageRectOffset
                img.ImageRectSize   = iconData.ImageRectSize
                img.ImageColor3     = Library.Theme.Accent
                img.Name = "\0"
                img.Parent = btn
                Library:AddToTheme(img, {ImageColor3 = "Accent"})
                socialIcons[#socialIcons+1] = img
                -- Deferred re-apply catches LoadAutoloadConfig theme override
                task.defer(function()
                    if img and img.Parent then
                        img.ImageColor3 = Library.Theme.Accent
                    end
                end)
            else
                local lbl = InstanceNew("TextLabel")
                lbl.Text = label
                lbl.FontFace = BoldFont
                lbl.TextColor3 = Accent()
                lbl.TextSize = 13
                lbl.Size = UDim2New(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.ZIndex = 6
                lbl.Name = "\0"
                lbl.Parent = btn
            end

            -- Hover
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
                TweenService:Create(bs,  TweenInfo.new(0.18), {Transparency = 0, Color = Accent()}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.2}):Play()
                TweenService:Create(bs,  TweenInfo.new(0.18), {Transparency = 0.45, Color = Outline()}):Play()
            end)

            -- Click → copy to clipboard + notify
            btn.MouseButton1Click:Connect(function()
                pcall(function() setclipboard(url) end)
                Library:Notification({
                    Title       = label .. " Link Copied",
                    Description = "Link copied to clipboard!",
                    Duration    = 3,
                })
            end)

            return btn
        end

        MakeSocialBtn(0,  "D", "https://discord.gg/vRXFYAtH5z",                           "message-circle")
        MakeSocialBtn(36, "▶", "https://youtube.com/@imphubscripts?si=nvhL4z5EuuBjCtWK",  "play-circle")

        local gameRaw   = tostring(Window.SubName or "")
        local gameUpper = string.upper(gameRaw)

        local gameTitleY = PAD + 182

        local gameTitleGlow = InstanceNew("Frame")
        gameTitleGlow.Size             = UDim2New(1, -(PAD*2), 0, 48)
        gameTitleGlow.Position         = UDim2New(0, PAD, 0, gameTitleY - 6)
        gameTitleGlow.BackgroundColor3 = Accent()
        gameTitleGlow.BackgroundTransparency = 0.82
        gameTitleGlow.BorderSizePixel  = 0
        gameTitleGlow.ZIndex           = 3
        gameTitleGlow.Name             = "\0"
        gameTitleGlow.Parent           = Left
        do
            local gg = InstanceNew("UIGradient")
            gg.Transparency = NumSequence{
                NumSequenceKeypoint(0, 1),
                NumSequenceKeypoint(0.25, 0.4),
                NumSequenceKeypoint(0.5, 0),
                NumSequenceKeypoint(0.75, 0.4),
                NumSequenceKeypoint(1, 1)
            }
            gg.Parent = gameTitleGlow
        end

        local gameTitle = InstanceNew("TextLabel")
        gameTitle.FontFace         = BoldFont
        gameTitle.Text             = gameUpper
        gameTitle.TextColor3       = FromRGB(255, 255, 255)
        gameTitle.TextTransparency = 0
        gameTitle.TextSize         = 26
        gameTitle.Size             = UDim2New(1, -(PAD*2), 0, 34)
        gameTitle.Position         = UDim2New(0, PAD, 0, gameTitleY)
        gameTitle.BackgroundTransparency = 1
        gameTitle.TextXAlignment   = Enum.TextXAlignment.Left
        gameTitle.TextTruncate     = Enum.TextTruncate.AtEnd
        gameTitle.ZIndex           = 4
        gameTitle.Name             = "\0"
        gameTitle.Parent           = Left
        local tg = InstanceNew("UIGradient")
        tg.Color = RGBSequence{
            RGBSequenceKeypoint(0, FromRGB(255, 255, 255)),
            RGBSequenceKeypoint(0.55, FromRGB(235, 228, 255)),
            RGBSequenceKeypoint(1, FromRGB(185, 155, 225))
        }
        tg.Rotation = 12
        tg.Parent = gameTitle

        local gameDesc = InstanceNew("TextLabel")
        gameDesc.FontFace         = Library.Font
        gameDesc.Text             = string.format(
            "Welcome to one of the best %s scripts you can find out!\nEnjoy this script with tons of features that are waiting for you.",
            gameRaw
        )
        gameDesc.TextColor3       = FromRGB(140, 138, 158)
        gameDesc.TextTransparency = 0
        gameDesc.TextSize         = 11
        gameDesc.Size             = UDim2New(1, -(PAD*2), 0, 42)
        gameDesc.Position         = UDim2New(0, PAD, 0, gameTitleY + 37)
        gameDesc.BackgroundTransparency = 1
        gameDesc.TextXAlignment   = Enum.TextXAlignment.Left
        gameDesc.TextYAlignment   = Enum.TextYAlignment.Top
        gameDesc.TextWrapped      = true
        gameDesc.ZIndex           = 4
        gameDesc.Name             = "\0"
        gameDesc.Parent           = Left

        -- ── RIGHT BRANDING PANEL ───────────────────────────────────────────────
        local RPanel = InstanceNew("Frame")
        RPanel.Size = UDim2New(0.40, -10, TOP_FRAC + 0.02, 0)
        RPanel.Position = UDim2New(0.59, 5, 0.025, 0)
        RPanel.BackgroundColor3 = Elem()
        RPanel.BackgroundTransparency = 0.1
        RPanel.BorderSizePixel = 0
        RPanel.ZIndex = 3
        RPanel.Name = "\0"
        RPanel.Parent = Main
        do
            local rpc = InstanceNew("UICorner"); rpc.CornerRadius = UDimNew(0, 10); rpc.Parent = RPanel
            local rps = InstanceNew("UIStroke")
            rps.Color = Outline(); rps.Thickness = 1; rps.Transparency = 0.55
            rps.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; rps.Parent = RPanel
        end

        -- Accent bar across top of right panel
        local rpTop = InstanceNew("Frame")
        rpTop.Size = UDim2New(1,0,0,2)
        rpTop.BackgroundColor3 = Accent()
        rpTop.BackgroundTransparency = 0.1
        rpTop.BorderSizePixel = 0
        rpTop.ZIndex = 4
        rpTop.Name = "\0"
        rpTop.Parent = RPanel
        do
            local rpTg = InstanceNew("UIGradient")
            rpTg.Color = RGBSequence{RGBSequenceKeypoint(0, Accent()), RGBSequenceKeypoint(1, AccGrad())}
            rpTg.Parent = rpTop
        end

        local LocalPlayer  = Players.LocalPlayer
        local Stats        = game:GetService("Stats")

        local rPad = 12

        local avatarGlow = InstanceNew("Frame")
        avatarGlow.Size             = UDim2New(0, 72, 0, 72)
        avatarGlow.AnchorPoint      = Vector2New(0.5, 0)
        avatarGlow.Position         = UDim2New(0.5, 0, 0, rPad + 8)
        avatarGlow.BackgroundColor3 = Accent()
        avatarGlow.BackgroundTransparency = 0.72
        avatarGlow.BorderSizePixel  = 0
        avatarGlow.ZIndex           = 3
        avatarGlow.Name             = "\0"
        avatarGlow.Parent           = RPanel
        do local agc = InstanceNew("UICorner"); agc.CornerRadius = UDimNew(1,0); agc.Parent = avatarGlow end

        local avatarRing = InstanceNew("Frame")
        avatarRing.Size             = UDim2New(0, 64, 0, 64)
        avatarRing.AnchorPoint      = Vector2New(0.5, 0)
        avatarRing.Position         = UDim2New(0.5, 0, 0, rPad + 12)
        avatarRing.BackgroundColor3 = Accent()
        avatarRing.BackgroundTransparency = 0.45
        avatarRing.BorderSizePixel  = 0
        avatarRing.ZIndex           = 4
        avatarRing.Name             = "\0"
        avatarRing.Parent           = RPanel
        do
            local arc = InstanceNew("UICorner"); arc.CornerRadius = UDimNew(1,0); arc.Parent = avatarRing
            local ars = InstanceNew("UIStroke")
            ars.Color = Accent(); ars.Thickness = 1.5; ars.Transparency = 0.3
            ars.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ars.Parent = avatarRing
        end

        local avatarImg = InstanceNew("ImageLabel")
        avatarImg.Size             = UDim2New(0, 56, 0, 56)
        avatarImg.AnchorPoint      = Vector2New(0.5, 0)
        avatarImg.Position         = UDim2New(0.5, 0, 0, rPad + 16)
        avatarImg.BackgroundColor3 = Bg()
        avatarImg.BackgroundTransparency = 0
        avatarImg.BorderSizePixel  = 0
        avatarImg.ZIndex           = 5
        avatarImg.Image            = ""
        avatarImg.Name             = "\0"
        avatarImg.Parent           = RPanel
        do local aic = InstanceNew("UICorner"); aic.CornerRadius = UDimNew(1,0); aic.Parent = avatarImg end

        Library:Thread(function()
            local ok, thumb = pcall(function()
                return Players:GetUserThumbnailAsync(
                    LocalPlayer.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size60x60
                )
            end)
            if ok and thumb then avatarImg.Image = thumb end
        end)

        local nameLabel = InstanceNew("TextLabel")
        nameLabel.FontFace         = BoldFont
        nameLabel.Text             = LocalPlayer.Name
        nameLabel.TextColor3       = Txt()
        nameLabel.TextTransparency = 0
        nameLabel.TextSize         = 14
        nameLabel.Size             = UDim2New(1, -(rPad*2), 0, 18)
        nameLabel.AnchorPoint      = Vector2New(0.5, 0)
        nameLabel.Position         = UDim2New(0.5, 0, 0, rPad + 78)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextXAlignment   = Enum.TextXAlignment.Center
        nameLabel.TextTruncate     = Enum.TextTruncate.AtEnd
        nameLabel.ZIndex           = 5
        nameLabel.Name             = "\0"
        nameLabel.Parent           = RPanel

        local displayName = LocalPlayer.DisplayName
        local hasDisplay  = displayName ~= LocalPlayer.Name and displayName ~= ""
        if hasDisplay then
            nameLabel.TextSize    = 12
            nameLabel.TextColor3  = FromRGB(165, 163, 185)
            local dispLabel = InstanceNew("TextLabel")
            dispLabel.FontFace    = BoldFont
            dispLabel.Text        = displayName
            dispLabel.TextColor3  = Txt()
            dispLabel.TextSize    = 15
            dispLabel.Size        = UDim2New(1, -(rPad*2), 0, 19)
            dispLabel.AnchorPoint = Vector2New(0.5, 0)
            dispLabel.Position    = UDim2New(0.5, 0, 0, rPad + 76)
            dispLabel.BackgroundTransparency = 1
            dispLabel.TextXAlignment = Enum.TextXAlignment.Center
            dispLabel.TextTruncate   = Enum.TextTruncate.AtEnd
            dispLabel.ZIndex      = 5
            dispLabel.Name        = "\0"
            dispLabel.Parent      = RPanel
            nameLabel.Position    = UDim2New(0.5, 0, 0, rPad + 95)
        end

        local freeBadge = InstanceNew("Frame")
        freeBadge.Size             = UDim2New(0, 46, 0, 16)
        freeBadge.AnchorPoint      = Vector2New(0.5, 0)
        freeBadge.Position         = UDim2New(0.5, 0, 0, hasDisplay and (rPad + 116) or (rPad + 99))
        freeBadge.BackgroundColor3 = Accent()
        freeBadge.BackgroundTransparency = 0.15
        freeBadge.BorderSizePixel  = 0
        freeBadge.ZIndex           = 5
        freeBadge.Name             = "\0"
        freeBadge.Parent           = RPanel
        do
            local fbc = InstanceNew("UICorner"); fbc.CornerRadius = UDimNew(0, 4); fbc.Parent = freeBadge
            local fbg = InstanceNew("UIGradient")
            fbg.Color = RGBSequence{RGBSequenceKeypoint(0, Accent()), RGBSequenceKeypoint(1, AccGrad())}
            fbg.Parent = freeBadge
            local fbl = InstanceNew("TextLabel")
            fbl.FontFace = BoldFont; fbl.Text = "FREE"
            fbl.TextColor3 = FromRGB(255,255,255); fbl.TextSize = 9
            fbl.Size = UDim2New(1,0,1,0); fbl.BackgroundTransparency = 1
            fbl.TextXAlignment = Enum.TextXAlignment.Center
            fbl.ZIndex = 6; fbl.Name = "\0"; fbl.Parent = freeBadge
        end

        local infoDivY = hasDisplay and (rPad + 140) or (rPad + 122)

        local infoDiv = InstanceNew("Frame")
        infoDiv.Size             = UDim2New(1, -(rPad*2), 0, 1)
        infoDiv.AnchorPoint      = Vector2New(0.5, 0)
        infoDiv.Position         = UDim2New(0.5, 0, 0, infoDivY)
        infoDiv.BackgroundColor3 = Outline()
        infoDiv.BackgroundTransparency = 0.5
        infoDiv.BorderSizePixel  = 0
        infoDiv.ZIndex           = 4
        infoDiv.Name             = "\0"
        infoDiv.Parent           = RPanel
        do
            local idg = InstanceNew("UIGradient")
            idg.Transparency = NumSequence{
                NumSequenceKeypoint(0, 1),
                NumSequenceKeypoint(0.2, 0),
                NumSequenceKeypoint(0.8, 0),
                NumSequenceKeypoint(1, 1)
            }
            idg.Parent = infoDiv
        end

        local function MakeInfoRow(yOff, iconName, valueText, labelText)
            local row = InstanceNew("Frame")
            row.Size             = UDim2New(1, -(rPad*2), 0, 28)
            row.AnchorPoint      = Vector2New(0.5, 0)
            row.Position         = UDim2New(0.5, 0, 0, yOff)
            row.BackgroundColor3 = Elem()
            row.BackgroundTransparency = 0.35
            row.BorderSizePixel  = 0
            row.ZIndex           = 4
            row.Name             = "\0"
            row.Parent           = RPanel
            do
                local rc = InstanceNew("UICorner"); rc.CornerRadius = UDimNew(0, 6); rc.Parent = row
                local rs = InstanceNew("UIStroke")
                rs.Color = Outline(); rs.Thickness = 1; rs.Transparency = 0.6
                rs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; rs.Parent = row
            end

            local iconData = Library:GetCustomIcon(iconName)
            local iconEl = InstanceNew("ImageLabel")
            iconEl.Size             = UDim2New(0, 13, 0, 13)
            iconEl.AnchorPoint      = Vector2New(0, 0.5)
            iconEl.Position         = UDim2New(0, 8, 0.5, 0)
            iconEl.BackgroundTransparency = 1
            iconEl.BorderSizePixel  = 0
            iconEl.ZIndex           = 5
            iconEl.ImageColor3      = Accent()
            iconEl.ImageTransparency = 0
            iconEl.Name             = "\0"
            if iconData then
                iconEl.Image           = iconData.Url
                iconEl.ImageRectOffset = iconData.ImageRectOffset
                iconEl.ImageRectSize   = iconData.ImageRectSize
            end
            iconEl.Parent = row

            local capLbl = InstanceNew("TextLabel")
            capLbl.FontFace = Library.Font
            capLbl.Text     = labelText
            capLbl.TextColor3 = FromRGB(130, 128, 150)
            capLbl.TextTransparency = 0
            capLbl.TextSize = 9
            capLbl.Size     = UDim2New(0, 50, 1, 0)
            capLbl.AnchorPoint = Vector2New(0, 0)
            capLbl.Position = UDim2New(0, 25, 0, 0)
            capLbl.BackgroundTransparency = 1
            capLbl.TextXAlignment = Enum.TextXAlignment.Left
            capLbl.TextYAlignment = Enum.TextYAlignment.Center
            capLbl.ZIndex = 5
            capLbl.Name   = "\0"
            capLbl.Parent = row

            local valLbl = InstanceNew("TextLabel")
            valLbl.FontFace = BoldFont
            valLbl.Text     = valueText
            valLbl.TextColor3 = Txt()
            valLbl.TextTransparency = 0
            valLbl.TextSize = 11
            valLbl.Size     = UDim2New(1, -80, 1, 0)
            valLbl.AnchorPoint = Vector2New(1, 0)
            valLbl.Position = UDim2New(1, -8, 0, 0)
            valLbl.BackgroundTransparency = 1
            valLbl.TextXAlignment = Enum.TextXAlignment.Right
            valLbl.TextYAlignment = Enum.TextYAlignment.Center
            valLbl.TextTruncate   = Enum.TextTruncate.AtEnd
            valLbl.ZIndex = 5
            valLbl.Name   = "\0"
            valLbl.Parent = row

            return valLbl
        end

        local rowBaseY = infoDivY + 10

        -- ── Total Executions tracking (per game) ──────────────────────────────
        local totalExecs = 1
        pcall(function()
            if writefile and readfile and isfile and makefolder then
                local execDir  = Library.Folders.Directory .. "/executions"
                local gameKey  = gameRaw:lower():gsub("[^%w]", "_")
                if gameKey == "" then gameKey = "unknown" end
                local execFile = execDir .. "/" .. gameKey .. ".txt"

                pcall(function() makefolder(execDir) end)

                if isfile(execFile) then
                    local stored = tonumber(readfile(execFile)) or 0
                    totalExecs = stored + 1
                end
                pcall(function() writefile(execFile, tostring(totalExecs)) end)
            end
        end)

        local timeVal  = MakeInfoRow(rowBaseY,      "clock",   "--:--:--",             "SERVER")
        local pingVal  = MakeInfoRow(rowBaseY + 34, "wifi",    "-- ms",                "PING")
        local execVal  = MakeInfoRow(rowBaseY + 68, "play",    tostring(totalExecs),   "EXECS")

        Library:Thread(function()
            while Library do
                local h, m, s = math.floor(tick() / 3600) % 24, math.floor(tick() / 60) % 60, math.floor(tick()) % 60
                pcall(function()
                    local st = workspace:GetServerTimeNow()
                    h = math.floor(st / 3600) % 24
                    m = math.floor(st / 60) % 60
                    s = math.floor(st) % 60
                end)
                timeVal.Text = string.format("%02d:%02d:%02d", h, m, s)

                local ping = 0
                pcall(function()
                    ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                end)
                local pingColor = ping < 80 and FromRGB(100, 220, 140) or ping < 160 and FromRGB(220, 190, 80) or FromRGB(220, 90, 90)
                pingVal.Text       = ping .. " ms"
                pingVal.TextColor3 = pingColor

                task.wait(1)
            end
        end)

        -- ── Horizontal divider between top section and cards ──────────────────
        local HDiv = InstanceNew("Frame")
        HDiv.Size = UDim2New(1, -(PAD*2), 0, 1)
        HDiv.AnchorPoint = Vector2New(0.5, 0)
        HDiv.Position = UDim2New(0.5, 0, TOP_FRAC, 6)
        HDiv.BackgroundColor3 = Outline()
        HDiv.BackgroundTransparency = 0.6
        HDiv.BorderSizePixel = 0
        HDiv.ZIndex = 3
        HDiv.Name = "\0"
        HDiv.Parent = Main
        do
            local hdg = InstanceNew("UIGradient")
            hdg.Transparency = NumSequence{NumSequenceKeypoint(0,1), NumSequenceKeypoint(0.15,0), NumSequenceKeypoint(0.85,0), NumSequenceKeypoint(1,1)}
            hdg.Parent = HDiv
        end

        -- "Quick Access" label above cards
        local qaLabel = InstanceNew("TextLabel")
        qaLabel.FontFace = Library.Font
        qaLabel.Text = "QUICK ACCESS"
        qaLabel.TextColor3 = Txt()
        qaLabel.TextTransparency = 0.55
        qaLabel.TextSize = 10
        qaLabel.Size = UDim2New(1, -(PAD*2), 0, 14)
        qaLabel.AnchorPoint = Vector2New(0.5, 0)
        qaLabel.Position = UDim2New(0.5, 0, TOP_FRAC, 16)
        qaLabel.BackgroundTransparency = 1
        qaLabel.TextXAlignment = Enum.TextXAlignment.Left
        qaLabel.ZIndex = 3
        qaLabel.Name = "\0"
        qaLabel.Parent = Main

        -- ── CARDS ROW ─────────────────────────────────────────────────────────
        local CardsRow = InstanceNew("Frame")
        CardsRow.Size     = UDim2New(1, -(PAD*2), CARD_FRAC, -32)
        CardsRow.AnchorPoint = Vector2New(0.5, 1)
        CardsRow.Position = UDim2New(0.5, 0, 1, -8)
        CardsRow.BackgroundTransparency = 1
        CardsRow.BorderSizePixel = 0
        CardsRow.ZIndex = 3
        CardsRow.Name = "\0"
        CardsRow.Parent = Main

        local cardsLayout = InstanceNew("UIListLayout")
        cardsLayout.FillDirection        = Enum.FillDirection.Horizontal
        cardsLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
        cardsLayout.VerticalAlignment    = Enum.VerticalAlignment.Center
        cardsLayout.Padding              = UDimNew(0, 8)
        cardsLayout.SortOrder            = Enum.SortOrder.LayoutOrder
        cardsLayout.Parent = CardsRow

        -- ── Build one card slot ────────────────────────────────────────────────
        local function MakeCard(idx)
            local cardBtn = InstanceNew("TextButton")
            cardBtn.Text = ""
            cardBtn.AutoButtonColor = false
            cardBtn.Size = UDim2New(0.315, 0, 1, 0)
            cardBtn.BackgroundColor3 = Elem()
            cardBtn.BackgroundTransparency = 0.12
            cardBtn.BorderSizePixel = 0
            cardBtn.ZIndex = 4
            cardBtn.LayoutOrder = idx
            cardBtn.Name = "\0"
            cardBtn.Parent = CardsRow

            local cbc = InstanceNew("UICorner"); cbc.CornerRadius = UDimNew(0, 8); cbc.Parent = cardBtn

            local cbs = InstanceNew("UIStroke")
            cbs.Color = Outline(); cbs.Thickness = 1; cbs.Transparency = 0.5
            cbs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; cbs.Parent = cardBtn

            -- Accent top border on each card
            local cbTop = InstanceNew("Frame")
            cbTop.Size = UDim2New(1,0,0,2)
            cbTop.BackgroundColor3 = Accent()
            cbTop.BackgroundTransparency = 0.55
            cbTop.BorderSizePixel = 0
            cbTop.ZIndex = 5
            cbTop.Name = "\0"
            cbTop.Parent = cardBtn
            do
                local ctg = InstanceNew("UIGradient")
                ctg.Color = RGBSequence{RGBSequenceKeypoint(0, Accent()), RGBSequenceKeypoint(1, AccGrad())}
                ctg.Parent = cbTop
            end

            -- Icon image (populated by RefreshCards)
            local cardIcon = InstanceNew("ImageLabel")
            cardIcon.Size = UDim2New(0, 33, 0, 33)
            cardIcon.AnchorPoint = Vector2New(0.5, 0)
            cardIcon.Position = UDim2New(0.5, 0, 0, 15)
            cardIcon.BackgroundTransparency = 1
            cardIcon.BorderSizePixel = 0
            cardIcon.ZIndex = 5
            cardIcon.Image = ""
            cardIcon.ImageTransparency = 1   -- hidden until populated
            cardIcon.ImageColor3 = Accent()
            cardIcon.Name = "CardIcon"
            cardIcon.Parent = cardBtn
            do
                local cig = InstanceNew("UIGradient")
                cig.Color = RGBSequence{RGBSequenceKeypoint(0, Accent()), RGBSequenceKeypoint(1, AccGrad())}
                cig.Rotation = -115
                cig.Parent = cardIcon
            end

            -- Title label
            local cardTitle = InstanceNew("TextLabel")
            cardTitle.FontFace = BoldFont
            cardTitle.Text = "—"
            cardTitle.TextColor3 = Txt()
            cardTitle.TextTransparency = 0.55   -- muted until populated
            cardTitle.TextSize = 12
            cardTitle.Size = UDim2New(1, -8, 0, 16)
            cardTitle.AnchorPoint = Vector2New(0.5, 0)
            cardTitle.Position = UDim2New(0.5, 0, 0, 56)
            cardTitle.BackgroundTransparency = 1
            cardTitle.TextXAlignment = Enum.TextXAlignment.Center
            cardTitle.TextTruncate = Enum.TextTruncate.AtEnd
            cardTitle.ZIndex = 5
            cardTitle.Name = "CardTitle"
            cardTitle.Parent = cardBtn

            local cardSubtitle = InstanceNew("TextLabel")
            cardSubtitle.FontFace = Library.Font
            cardSubtitle.Text = ""
            cardSubtitle.TextColor3 = FromRGB(110, 108, 130)
            cardSubtitle.TextTransparency = 1
            cardSubtitle.TextSize = 9
            cardSubtitle.Size = UDim2New(1, -10, 0, 22)
            cardSubtitle.AnchorPoint = Vector2New(0.5, 0)
            cardSubtitle.Position = UDim2New(0.5, 0, 0, 74)
            cardSubtitle.BackgroundTransparency = 1
            cardSubtitle.TextXAlignment = Enum.TextXAlignment.Center
            cardSubtitle.TextWrapped = true
            cardSubtitle.RichText = true
            cardSubtitle.ZIndex = 5
            cardSubtitle.Name = "CardSubtitle"
            cardSubtitle.Parent = cardBtn

            -- UIScale for click bounce
            local cardScale = InstanceNew("UIScale")
            cardScale.Scale = 1
            cardScale.Parent = cardBtn

            -- Hover
            cardBtn.MouseEnter:Connect(function()
                TweenService:Create(cardBtn,   TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
                TweenService:Create(cbs,       TweenInfo.new(0.2), {Transparency = 0, Color = Accent()}):Play()
                TweenService:Create(cbTop,     TweenInfo.new(0.2), {BackgroundTransparency = 0.15}):Play()
                TweenService:Create(cardScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.03}):Play()
            end)
            cardBtn.MouseLeave:Connect(function()
                TweenService:Create(cardBtn,   TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.12}):Play()
                TweenService:Create(cbs,       TweenInfo.new(0.2), {Transparency = 0.5, Color = Outline()}):Play()
                TweenService:Create(cbTop,     TweenInfo.new(0.2), {BackgroundTransparency = 0.55}):Play()
                TweenService:Create(cardScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
            end)

            -- Click: scale down then bounce back, then navigate
            cardBtn.MouseButton1Down:Connect(function()
                TweenService:Create(cardScale, TweenInfo.new(0.08), {Scale = 0.93}):Play()
            end)
            cardBtn.MouseButton1Up:Connect(function()
                TweenService:Create(cardScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
            end)
            cardBtn.MouseButton1Click:Connect(function()
                if not cardPages[idx] then return end
                task.delay(0.12, function()
                    if not Library then return end
                    for _, p in ipairs(Window.Pages) do
                        if p.Active then p:Turn(false) end
                    end
                    task.wait(0.05)
                    if Library then cardPages[idx]:Turn(true) end
                end)
            end)

            cardSlots[idx] = {btn=cardBtn, icon=cardIcon, title=cardTitle, subtitle=cardSubtitle, stroke=cbs, top=cbTop}
        end

        for i = 1, 3 do MakeCard(i) end

        -- ── RefreshCards: populate slots from first 3 non-dashboard pages ─────
        RefreshCards = function()
            local devPages = {}
            for _, p in ipairs(Window.Pages) do
                if p ~= DashPage and #devPages < 3 then
                    devPages[#devPages + 1] = p
                end
            end

            for i = 1, 3 do
                cardPages[i] = devPages[i]
                local slot = cardSlots[i]
                if not slot then continue end

                if devPages[i] then
                    -- Populate icon
                    local iconData = Library:GetCustomIcon(devPages[i].Icon)
                    if iconData then
                        slot.icon.Image           = iconData.Url
                        slot.icon.ImageRectOffset = iconData.ImageRectOffset
                        slot.icon.ImageRectSize   = iconData.ImageRectSize
                    else
                        slot.icon.Image = ""
                    end
                    -- Populate title
                    slot.title.Text = string.upper(devPages[i].Name)

                    local pageName = devPages[i].Name
                    local titleCased = pageName:sub(1,1):upper() .. pageName:sub(2):lower()
                    slot.subtitle.Text = string.format(
                        'This will redirect you to the <font color="#FFFFFF">%s</font> tab.',
                        titleCased
                    )

                    -- Animated reveal: icon slides up, title fades in
                    slot.icon.ImageTransparency = 1
                    slot.icon.Position = UDim2New(0.5, 0, 0, 28)
                    slot.title.TextTransparency = 1
                    slot.subtitle.TextTransparency = 1

                    local revT = TweenInfo.new(0.35 + (i-1)*0.08, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                    TweenService:Create(slot.icon,     revT, {ImageTransparency = 0, Position = UDim2New(0.5, 0, 0, 15)}):Play()
                    TweenService:Create(slot.title,    TweenInfo.new(0.3  + (i-1)*0.08, Enum.EasingStyle.Quad), {TextTransparency = 0.1}):Play()
                    TweenService:Create(slot.subtitle, TweenInfo.new(0.38 + (i-1)*0.08, Enum.EasingStyle.Quad), {TextTransparency = 0.1}):Play()
                else
                    slot.icon.Image = ""
                    slot.icon.ImageTransparency = 1
                    slot.title.Text = "—"
                    slot.title.TextTransparency = 0.55
                    slot.subtitle.Text = ""
                    slot.subtitle.TextTransparency = 1
                end
            end
        end

        -- ── Re-run cards on dashboard re-open (parent change = Turn fired) ────
        DashPage.Items["Page"].Instance:GetPropertyChangedSignal("Parent"):Connect(function()
            if not Library then return end
            local parent = DashPage.Items["Page"].Instance.Parent
            if parent == Window.Items["Content"].Instance then
                Library:Thread(function()
                    task.wait(0.08)
                    if Library then RefreshCards() end
                end)
            end
        end)

        -- ── Initial card pass (for any pages already in Window.Pages) ─────────
        task.wait()
        if Library then RefreshCards() end

        -- ── Tab memory: restore last active page ─────────────────────────────
        -- Use task.delay to run after LoadAutoloadConfig and all page Turn() calls settle
        task.delay(0.1, function()
            if not Library then return end
            local ok, savedName = pcall(function()
                if isfile and isfile(Library.Folders.Directory .. "/lastpage.txt") then
                    return readfile(Library.Folders.Directory .. "/lastpage.txt")
                end
            end)
            if ok and savedName and savedName ~= "" and savedName ~= "Dashboard" then
                for _, page in ipairs(Window.Pages) do
                    if page.Name == savedName then
                        Window._tabLocked = false
                        Window:SelectTab(page)
                        return
                    end
                end
            end
        end)

        -- ── Theme callback: update every accent element in the Dashboard ────────
        -- Collect references to everything accent/outline-reactive at build time.
        -- social button icon images + gradients populated above during MakeSocialBtn
        local infoRowIcons = {}  -- ImageLabel instances from MakeInfoRow

        -- patch MakeSocialBtn and MakeInfoRow to expose their inner elements
        -- (done via upvalue tables populated during construction above)
        -- We iterate RPanel & Left descendants once and tag by name/type
        local function gatherDashRefs(root)
            for _, d in ipairs(root:GetDescendants()) do
                -- info row icons: ImageLabels with ZIndex=5 inside Frames that are direct children of RPanel
                if d:IsA("ImageLabel") and d.ZIndex == 5
                   and d.Parent and d.Parent:IsA("Frame")
                   and d.Parent.Parent == RPanel
                   and d.Size == UDim2New(0,13,0,13) then
                    infoRowIcons[#infoRowIcons+1] = d
                end
            end
        end
        pcall(gatherDashRefs, RPanel)
        pcall(gatherDashRefs, Left)

        -- Build explicit lists for all reactive instances
        local accentFrames   = { TopGlow, divFr, gameTitleGlow, rpTop, avatarGlow, avatarRing, freeBadge }
        local accentStrokes  = {}   -- UIStroke instances with Color = Accent
        -- collect avatarRing stroke
        for _, ch in ipairs(avatarRing:GetChildren()) do
            if ch:IsA("UIStroke") then accentStrokes[#accentStrokes+1] = ch end
        end
        local accentGrads = {}  -- UIGradient instances: full Accent→AccGrad
        for _, fr in ipairs(accentFrames) do
            for _, ch in ipairs(fr:GetChildren()) do
                if ch:IsA("UIGradient") then accentGrads[#accentGrads+1] = ch end
            end
        end

        -- Register the theme callback
        Library.ThemeCallbacks[#Library.ThemeCallbacks + 1] = function(theme, TInfo)
            local accent  = theme.Accent         or FromRGB(151, 69, 186)
            local accGrad = theme.AccentGradient  or FromRGB(109, 43, 139)
            local outline = theme.Outline         or FromRGB(25, 25, 28)

            local seq = RGBSequence{RGBSequenceKeypoint(0, accent), RGBSequenceKeypoint(1, accGrad)}

            -- Tween accent frames
            for _, fr in ipairs(accentFrames) do
                pcall(function() TweenService:Create(fr, TInfo, {BackgroundColor3 = accent}):Play() end)
            end

            -- Update all accent gradients
            for _, gr in ipairs(accentGrads) do
                pcall(function() gr.Color = seq end)
            end

            -- Update avatarRing UIStroke
            for _, st in ipairs(accentStrokes) do
                pcall(function() TweenService:Create(st, TInfo, {Color = accent}):Play() end)
            end

            -- divFr gradient (Accent → AccGrad)
            pcall(function()
                local dg2 = divFr:FindFirstChildOfClass("UIGradient")
                if dg2 then dg2.Color = seq end
            end)

            -- freeBadge gradient
            pcall(function()
                local fbg = freeBadge:FindFirstChildOfClass("UIGradient")
                if fbg then fbg.Color = seq end
            end)

            -- rpTop gradient
            pcall(function()
                local rtg = rpTop:FindFirstChildOfClass("UIGradient")
                if rtg then rtg.Color = seq end
            end)

            -- "FREE VERSION" text gradient (first = accent, second = lighter tint of accent)
            pcall(function()
                local lighter = FromRGB(
                    math.min(255, accent.R * 255 + 60),
                    math.min(255, accent.G * 255 + 40),
                    math.min(255, accent.B * 255 + 60)
                )
                if g2 then g2.Color = RGBSequence{RGBSequenceKeypoint(0, accent), RGBSequenceKeypoint(1, lighter)} end
            end)

            -- gameTitle text gradient (white → tinted by accent)
            pcall(function()
                if tg then
                    local mid = FromRGB(
                        math.min(255, math.floor(255 * 0.92 + accent.R * 255 * 0.08)),
                        math.min(255, math.floor(255 * 0.92 + accent.G * 255 * 0.08)),
                        math.min(255, math.floor(255 * 0.92 + accent.B * 255 * 0.08))
                    )
                    local end_ = FromRGB(
                        math.min(255, math.floor(255 * 0.72 + accent.R * 255 * 0.28)),
                        math.min(255, math.floor(255 * 0.72 + accent.G * 255 * 0.28)),
                        math.min(255, math.floor(255 * 0.72 + accent.B * 255 * 0.28))
                    )
                    tg.Color = RGBSequence{
                        RGBSequenceKeypoint(0,    FromRGB(255,255,255)),
                        RGBSequenceKeypoint(0.55, mid),
                        RGBSequenceKeypoint(1,    end_),
                    }
                end
            end)

            -- Social button icons — direct assignment (no tween, guaranteed to work)
            for _, img in ipairs(socialIcons) do
                pcall(function()
                    img.ImageColor3 = accent
                    TweenService:Create(img, TInfo, {ImageColor3 = accent}):Play()
                end)
            end

            -- Info row icons (SERVER, PING)
            for _, ic in ipairs(infoRowIcons) do
                pcall(function()
                    TweenService:Create(ic, TInfo, {ImageColor3 = accent}):Play()
                end)
            end

            -- Card slots: top-bar, icon, icon gradient, stroke
            for _, slot in ipairs(cardSlots) do
                pcall(function()
                    if slot.top then
                        TweenService:Create(slot.top, TInfo, {BackgroundColor3 = accent}):Play()
                        local cig = slot.top:FindFirstChildOfClass("UIGradient")
                        if cig then cig.Color = seq end
                    end
                    if slot.icon then
                        TweenService:Create(slot.icon, TInfo, {ImageColor3 = accent}):Play()
                        local cig = slot.icon:FindFirstChildOfClass("UIGradient")
                        if cig then cig.Color = seq end
                    end
                    if slot.stroke then
                        TweenService:Create(slot.stroke, TInfo, {Color = outline}):Play()
                    end
                end)
            end
        end

        local footer = InstanceNew("TextLabel")
        footer.FontFace         = Library.Font
        footer.Text             = "Imp Hub © 2026"
        footer.TextColor3       = FromRGB(255, 255, 255)
        footer.TextTransparency = 0
        footer.TextSize         = 9
        footer.Size             = UDim2New(1, 0, 0, 14)
        footer.AnchorPoint      = Vector2New(0.5, 1)
        footer.Position         = UDim2New(0.5, 0, 1, -4)
        footer.BackgroundTransparency = 1
        footer.TextXAlignment   = Enum.TextXAlignment.Center
        footer.ZIndex           = 3
        footer.Name             = "\0"
        footer.Parent           = Main

        return DashPage
    end
    -- ─────────────────────────────────────────────────────────────────────────

    Library.CreateSettingsPage = function(self, Window, KeybindList)
        local Page = Window:Page({Name = "Settings", Icon = "122669828593160", Columns = 3})

        local function Accent()
            return Library.Theme["Accent"] or FromRGB(151, 69, 186)
        end

        local function AccGrad()
            return Library.Theme["AccentGradient"] or FromRGB(109, 43, 139)
        end

        local function Bg()
            return Library.Theme["Background"] or FromRGB(12, 12, 14)
        end

        local function Elem()
            return Library.Theme["Element"] or FromRGB(18, 17, 22)
        end

        local function Outline()
            return Library.Theme["Outline"] or FromRGB(40, 38, 46)
        end

        local function Txt()
            return Library.Theme["Text"] or FromRGB(235, 235, 235)
        end

        local BoldFont = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        local strFormat = string.format
        local StringUpper = string.upper
        local configFolder = Library.Folders.Configs

        local function NormalizeConfigName(name)
            return Library:NormalizeConfigName(name, false)
        end

        local function GetAutoloadConfig()
            return Library:GetAutoloadConfigName()
        end

        local function SetAutoloadConfig(configName)
            return Library:SetAutoloadConfigName(configName)
        end

        local PageFr = Page.Items["Page"].Instance
        for _, child in ipairs(PageFr:GetChildren()) do
            if child:IsA("UIListLayout") or child:IsA("UIPadding") then
                child:Destroy()
            end
        end

        local Main = InstanceNew("Frame")
        Main.Name = "\0"
        Main.Size = UDim2New(1, 0, 1, 0)
        Main.BackgroundTransparency = 1
        Main.BorderSizePixel = 0
        Main.ZIndex = 1
        Main.Parent = PageFr

        local TopGlow = InstanceNew("Frame")
        TopGlow.Name = "\0"
        TopGlow.Size = UDim2New(1, 0, 0, 170)
        TopGlow.BackgroundColor3 = Accent()
        TopGlow.BackgroundTransparency = 0.955
        TopGlow.BorderSizePixel = 0
        TopGlow.ZIndex = 1
        TopGlow.Parent = Main
        do
            local glowGrad = InstanceNew("UIGradient")
            glowGrad.Rotation = 90
            glowGrad.Transparency = NumSequence{
                NumSequenceKeypoint(0, 0),
                NumSequenceKeypoint(0.65, 0.45),
                NumSequenceKeypoint(1, 1)
            }
            glowGrad.Parent = TopGlow
        end

        local SideGlow = InstanceNew("Frame")
        SideGlow.Name = "\0"
        SideGlow.AnchorPoint = Vector2New(1, 1)
        SideGlow.Position = UDim2New(1, 26, 1, 18)
        SideGlow.Size = UDim2New(0, 190, 0, 150)
        SideGlow.BackgroundColor3 = Accent()
        SideGlow.BackgroundTransparency = 0.978
        SideGlow.BorderSizePixel = 0
        SideGlow.ZIndex = 1
        SideGlow.Parent = Main
        do
            local glowGrad = InstanceNew("UIGradient")
            glowGrad.Transparency = NumSequence{
                NumSequenceKeypoint(0, 0.2),
                NumSequenceKeypoint(1, 1)
            }
            glowGrad.Parent = SideGlow
        end

        local Header = Instances:Create("Frame", {
            Parent = Main,
            Name = "\0",
            Size = UDim2New(1, 0, 0, 58),
            BackgroundColor3 = Elem(),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2
        })
        Header:AddToTheme({BackgroundColor3 = "Element"})

        Instances:Create("UICorner", {
            Parent = Header.Instance,
            CornerRadius = UDimNew(0, 18)
        })

        local HeaderStroke = Instances:Create("UIStroke", {
            Parent = Header.Instance,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Outline(),
            Thickness = 1,
            Transparency = 1
        })
        HeaderStroke:AddToTheme({Color = "Outline"})

        local HeaderAccent = Instances:Create("Frame", {
            Parent = Header.Instance,
            Name = "\0",
            AnchorPoint = Vector2New(0.5, 1),
            Position = UDim2New(0.5, 0, 1, 0),
            Size = UDim2New(1, -4, 0, 1),
            BackgroundColor3 = Accent(),
            BackgroundTransparency = 0.72,
            BorderSizePixel = 0,
            ZIndex = 3
        })
        HeaderAccent:AddToTheme({BackgroundColor3 = "Accent"})

        local HeaderAccentGrad = Instances:Create("UIGradient", {
            Parent = HeaderAccent.Instance,
            Color = RGBSequence{
                RGBSequenceKeypoint(0, Accent()),
                RGBSequenceKeypoint(1, AccGrad())
            }
        })
        HeaderAccentGrad:AddToTheme({Color = function()
            return RGBSequence{
                RGBSequenceKeypoint(0, Library.Theme.Accent),
                RGBSequenceKeypoint(1, Library.Theme.AccentGradient)
            }
        end})

        local HeaderGlow = Instances:Create("Frame", {
            Parent = Header.Instance,
            Name = "\0",
            AnchorPoint = Vector2New(0, 0),
            Position = UDim2New(0, 12, 0, 0),
            Size = UDim2New(0.36, 0, 0, 40),
            BackgroundColor3 = Accent(),
            BackgroundTransparency = 0.96,
            BorderSizePixel = 0,
            ZIndex = 2
        })
        HeaderGlow:AddToTheme({BackgroundColor3 = "Accent"})
        Instances:Create("UICorner", {
            Parent = HeaderGlow.Instance,
            CornerRadius = UDimNew(0, 18)
        })

        local HeaderLeft = InstanceNew("Frame")
        HeaderLeft.Name = "\0"
        HeaderLeft.BackgroundTransparency = 1
        HeaderLeft.BorderSizePixel = 0
        HeaderLeft.Position = UDim2New(0, 0, 0, 3)
        HeaderLeft.Size = UDim2New(1, -176, 1, -6)
        HeaderLeft.ZIndex = 3
        HeaderLeft.Parent = Header.Instance

        local HeaderKicker = Instances:Create("TextLabel", {
            Parent = HeaderLeft,
            Name = "\0",
            FontFace = Library.Font,
            Text = "SETTINGS HUB",
            TextColor3 = FromRGB(164, 160, 186),
            TextSize = 9,
            BackgroundTransparency = 1,
            Size = UDim2New(1, 0, 0, 12),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 4
        })

        local HeaderTitle = Instances:Create("TextLabel", {
            Parent = HeaderLeft,
            Name = "\0",
            FontFace = BoldFont,
            Text = "Settings",
            TextColor3 = Txt(),
            TextSize = 18,
            BackgroundTransparency = 1,
            Position = UDim2New(0, 0, 0, 10),
            Size = UDim2New(1, 0, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 4
        })
        HeaderTitle:AddToTheme({TextColor3 = "Text"})

        local HeaderTitleGrad = Instances:Create("UIGradient", {
            Parent = HeaderTitle.Instance,
            Rotation = 12,
            Color = RGBSequence{
                RGBSequenceKeypoint(0, FromRGB(255, 255, 255)),
                RGBSequenceKeypoint(0.55, FromRGB(232, 226, 247)),
                RGBSequenceKeypoint(1, FromRGB(187, 161, 220))
            }
        })

        local HeaderSubtitle = Instances:Create("TextLabel", {
            Parent = HeaderLeft,
            Name = "\0",
            FontFace = Library.Font,
            Text = "Cleaner control over interface, motion, and config routing.",
            TextColor3 = FromRGB(145, 142, 160),
            TextSize = 11,
            BackgroundTransparency = 1,
            Position = UDim2New(0, 0, 0, 30),
            Size = UDim2New(1, -10, 0, 16),
            TextWrapped = false,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 4
        })

        local HeaderStats = InstanceNew("Frame")
        HeaderStats.Name = "\0"
        HeaderStats.BackgroundTransparency = 1
        HeaderStats.BorderSizePixel = 0
        HeaderStats.AnchorPoint = Vector2New(1, 0.5)
        HeaderStats.Position = UDim2New(1, -2, 0.5, 0)
        HeaderStats.Size = UDim2New(0, 164, 0, 34)
        HeaderStats.ZIndex = 4
        HeaderStats.Parent = Header.Instance

        local headerStatsLayout = InstanceNew("UIListLayout")
        headerStatsLayout.FillDirection = Enum.FillDirection.Vertical
        headerStatsLayout.Padding = UDimNew(0, 3)
        headerStatsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        headerStatsLayout.Parent = HeaderStats

        local function CreateHeaderStat(labelText, valueText)
            local stat = Instances:Create("Frame", {
                Parent = HeaderStats,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 14),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 4
            })

            Instances:Create("TextLabel", {
                Parent = stat.Instance,
                Name = "\0",
                FontFace = Library.Font,
                Text = labelText,
                TextColor3 = FromRGB(135, 132, 150),
                TextSize = 9,
                BackgroundTransparency = 1,
                Size = UDim2New(0.5, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 4
            })

            local value = Instances:Create("TextLabel", {
                Parent = stat.Instance,
                Name = "\0",
                FontFace = BoldFont,
                Text = valueText,
                TextColor3 = Txt(),
                TextSize = 9,
                BackgroundTransparency = 1,
                Position = UDim2New(0.5, 0, 0, 0),
                Size = UDim2New(0.5, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 4
            })
            value:AddToTheme({TextColor3 = "Text"})
            return value
        end

        local HeaderThemeValue = CreateHeaderStat("Theme", "Default")
        local HeaderAutoloadValue = CreateHeaderStat("Autoload", "Disabled")
        local HeaderKeybindValue = CreateHeaderStat("Keybind Overlay", KeybindList and "Attached" or "Detached")

        local columns = {
            Sidebar = Page.ColumnsData[1].Instance,
            Main = Page.ColumnsData[2].Instance,
            Right = Page.ColumnsData[3].Instance,
        }

        local columnDecor = {}

        local function CreateColumnPill(parent, text, width)
            local pill = Instances:Create("Frame", {
                Parent = parent,
                Name = "\0",
                Size = UDim2New(0, width or 74, 0, 20),
                BackgroundColor3 = Accent(),
                BackgroundTransparency = 0.12,
                BorderSizePixel = 0,
                ZIndex = 5
            })
            pill:AddToTheme({BackgroundColor3 = "Accent"})

            Instances:Create("UICorner", {
                Parent = pill.Instance,
                CornerRadius = UDimNew(0, 999)
            })

            local pillGrad = Instances:Create("UIGradient", {
                Parent = pill.Instance,
                Color = RGBSequence{
                    RGBSequenceKeypoint(0, Accent()),
                    RGBSequenceKeypoint(1, AccGrad())
                }
            })
            pillGrad:AddToTheme({Color = function()
                return RGBSequence{
                    RGBSequenceKeypoint(0, Library.Theme.Accent),
                    RGBSequenceKeypoint(1, Library.Theme.AccentGradient)
                }
            end})

            local label = Instances:Create("TextLabel", {
                Parent = pill.Instance,
                Name = "\0",
                FontFace = BoldFont,
                Text = text,
                TextColor3 = FromRGB(255, 255, 255),
                TextSize = 8,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 1, 0),
                ZIndex = 6
            })

            return {
                Frame = pill.Instance,
                Gradient = pillGrad.Instance,
                Label = label.Instance
            }
        end

        local function SetupColumn(column, position, size, backgroundTransparency, title, subtitle, tagText)
            local shell = Instances:Create("Frame", {
                Parent = Main,
                Name = "\0",
                Position = position,
                Size = size,
                BackgroundColor3 = Elem(),
                BackgroundTransparency = backgroundTransparency,
                BorderSizePixel = 0,
                ZIndex = 2
            })
            shell:AddToTheme({BackgroundColor3 = "Element"})

            Instances:Create("UICorner", {
                Parent = shell.Instance,
                CornerRadius = UDimNew(0, 18)
            })

            local shellStroke = Instances:Create("UIStroke", {
                Parent = shell.Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Color = Outline(),
                Thickness = 1,
                Transparency = 0.35
            })
            shellStroke:AddToTheme({Color = "Outline"})

            local shellTop = Instances:Create("Frame", {
                Parent = shell.Instance,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 2),
                BackgroundColor3 = Accent(),
                BackgroundTransparency = 0.16,
                BorderSizePixel = 0,
                ZIndex = 3
            })
            shellTop:AddToTheme({BackgroundColor3 = "Accent"})

            local shellTopGrad = Instances:Create("UIGradient", {
                Parent = shellTop.Instance,
                Color = RGBSequence{
                    RGBSequenceKeypoint(0, Accent()),
                    RGBSequenceKeypoint(1, AccGrad())
                }
            })
            shellTopGrad:AddToTheme({Color = function()
                return RGBSequence{
                    RGBSequenceKeypoint(0, Library.Theme.Accent),
                    RGBSequenceKeypoint(1, Library.Theme.AccentGradient)
                }
            end})

            local shellGlow = Instances:Create("Frame", {
                Parent = shell.Instance,
                Name = "\0",
                AnchorPoint = Vector2New(0.5, 0),
                Position = UDim2New(0.5, 0, 0, 2),
                Size = UDim2New(1, -32, 0, 34),
                BackgroundColor3 = Accent(),
                BackgroundTransparency = 0.955,
                BorderSizePixel = 0,
                ZIndex = 2
            })
            shellGlow:AddToTheme({BackgroundColor3 = "Accent"})
            Instances:Create("UICorner", {
                Parent = shellGlow.Instance,
                CornerRadius = UDimNew(0, 18)
            })

            local shellHeader = InstanceNew("Frame")
            shellHeader.Name = "\0"
            shellHeader.BackgroundTransparency = 1
            shellHeader.BorderSizePixel = 0
            shellHeader.Position = UDim2New(0, 14, 0, 10)
            shellHeader.Size = UDim2New(1, -28, 0, 46)
            shellHeader.ZIndex = 4
            shellHeader.Parent = shell.Instance

            local shellKicker = Instances:Create("TextLabel", {
                Parent = shellHeader,
                Name = "\0",
                FontFace = Library.Font,
                Text = StringUpper(title),
                TextColor3 = FromRGB(152, 148, 172),
                TextSize = 8,
                BackgroundTransparency = 1,
                Size = UDim2New(1, -88, 0, 10),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5
            })

            local shellTitle = Instances:Create("TextLabel", {
                Parent = shellHeader,
                Name = "\0",
                FontFace = BoldFont,
                Text = title,
                TextColor3 = Txt(),
                TextSize = 14,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0, 10),
                Size = UDim2New(1, -88, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 5
            })
            shellTitle:AddToTheme({TextColor3 = "Text"})

            local shellSubtitle = Instances:Create("TextLabel", {
                Parent = shellHeader,
                Name = "\0",
                FontFace = Library.Font,
                Text = subtitle,
                TextColor3 = FromRGB(140, 137, 156),
                TextSize = 9,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0, 26),
                Size = UDim2New(1, -4, 0, 14),
                TextWrapped = false,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5
            })

            local shellPill = CreateColumnPill(shellHeader, tagText, 74)
            shellPill.Frame.AnchorPoint = Vector2New(1, 0)
            shellPill.Frame.Position = UDim2New(1, 0, 0, 0)

            local shellDivider = Instances:Create("Frame", {
                Parent = shell.Instance,
                Name = "\0",
                AnchorPoint = Vector2New(0.5, 0),
                Position = UDim2New(0.5, 0, 0, 60),
                Size = UDim2New(1, -28, 0, 1),
                BackgroundColor3 = Outline(),
                BackgroundTransparency = 0.72,
                BorderSizePixel = 0,
                ZIndex = 3
            })
            shellDivider:AddToTheme({BackgroundColor3 = "Outline"})
            do
                local dividerGrad = InstanceNew("UIGradient")
                dividerGrad.Transparency = NumSequence{
                    NumSequenceKeypoint(0, 1),
                    NumSequenceKeypoint(0.18, 0.35),
                    NumSequenceKeypoint(0.82, 0.35),
                    NumSequenceKeypoint(1, 1)
                }
                dividerGrad.Parent = shellDivider.Instance
            end

            column.Parent = shell.Instance
            column.Position = UDim2New(0, 12, 0, 68)
            column.Size = UDim2New(1, -24, 1, -80)
            column.BackgroundTransparency = 1
            column.BorderSizePixel = 0
            column.ScrollBarThickness = 2
            column.ScrollBarImageColor3 = Accent()
            column.CanvasPosition = Vector2New(0, 0)
            column.ClipsDescendants = true
            column.ZIndex = 2

            local layout = column:FindFirstChildOfClass("UIListLayout")
            if layout then
                layout.Padding = UDimNew(0, 10)
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                layout.SortOrder = Enum.SortOrder.LayoutOrder
            end

            columnDecor[column] = {
                Shell = shell.Instance,
                Stroke = shellStroke.Instance,
                Top = shellTop.Instance,
                Glow = shellGlow.Instance,
                Divider = shellDivider.Instance,
                Pill = shellPill.Frame,
                PillGradient = shellPill.Gradient,
            }
        end

        SetupColumn(columns.Sidebar, UDim2New(0, 0, 0, 68), UDim2New(0.19, -2, 1, -68), 0.12, "Navigation", "Route the page and watch the live state.", "LIVE")
        SetupColumn(columns.Main, UDim2New(0.205, 2, 0, 68), UDim2New(0.525, -6, 1, -68), 0.08, "UI & Motion", "Keybind, theme, transparency, fade, and tween tuning.", "ACTIVE")
        SetupColumn(columns.Right, UDim2New(0.745, 4, 0, 68), UDim2New(0.255, -4, 1, -68), 0.12, "Config Control", "Saved setups, autoload, and workspace context.", "MANAGE")

        local function CreateSidebarCard(title, subtitle, height)
            local card = Instances:Create("Frame", {
                Parent = columns.Sidebar,
                Name = "\0",
                Size = UDim2New(1, 0, 0, height),
                BackgroundColor3 = Bg(),
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                ZIndex = 3
            })
            card:AddToTheme({BackgroundColor3 = "Background"})

            Instances:Create("UICorner", {
                Parent = card.Instance,
                CornerRadius = UDimNew(0, 14)
            })

            local stroke = Instances:Create("UIStroke", {
                Parent = card.Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Color = Outline(),
                Thickness = 1,
                Transparency = 0.48
            })
            stroke:AddToTheme({Color = "Outline"})

            local accent = Instances:Create("Frame", {
                Parent = card.Instance,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 2),
                BackgroundColor3 = Accent(),
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                ZIndex = 4
            })
            accent:AddToTheme({BackgroundColor3 = "Accent"})

            local accentGrad = Instances:Create("UIGradient", {
                Parent = accent.Instance,
                Color = RGBSequence{
                    RGBSequenceKeypoint(0, Accent()),
                    RGBSequenceKeypoint(1, AccGrad())
                }
            })
            accentGrad:AddToTheme({Color = function()
                return RGBSequence{
                    RGBSequenceKeypoint(0, Library.Theme.Accent),
                    RGBSequenceKeypoint(1, Library.Theme.AccentGradient)
                }
            end})

            local titleLabel = Instances:Create("TextLabel", {
                Parent = card.Instance,
                Name = "\0",
                FontFace = BoldFont,
                Text = title,
                TextColor3 = Txt(),
                TextSize = 13,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 14, 0, 12),
                Size = UDim2New(1, -28, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 4
            })
            titleLabel:AddToTheme({TextColor3 = "Text"})

            local subtitleLabel = Instances:Create("TextLabel", {
                Parent = card.Instance,
                Name = "\0",
                FontFace = Library.Font,
                Text = subtitle,
                TextColor3 = FromRGB(142, 139, 158),
                TextSize = 10,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 14, 0, 30),
                Size = UDim2New(1, -28, 0, 22),
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 4
            })

            local body = Instances:Create("Frame", {
                Parent = card.Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                Position = UDim2New(0, 14, 0, 58),
                Size = UDim2New(1, -28, 1, -70),
                BorderSizePixel = 0,
                ZIndex = 4
            })

            local bodyLayout = InstanceNew("UIListLayout")
            bodyLayout.Padding = UDimNew(0, 8)
            bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
            bodyLayout.Parent = body.Instance

            return card, body
        end

        local NavigationCard, NavBody = CreateSidebarCard(
            "Navigation",
            "Jump between the four settings groups without relying on the old stacked flow.",
            254
        )

        local SnapshotCard, SnapshotBody = CreateSidebarCard(
            "Snapshot",
            "Theme, autoload, and keybind status at a glance.",
            134
        )

        local NotesCard, NotesBody = CreateSidebarCard(
            "Workflow",
            "Use UI first, tune motion second, then finish by saving or autoloading a config.",
            136
        )

        local function CreateWorkflowRow(index, title, hint)
            local row = Instances:Create("Frame", {
                Parent = NotesBody.Instance,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 16),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 4
            })

            local dot = Instances:Create("Frame", {
                Parent = row.Instance,
                Name = "\0",
                Size = UDim2New(0, 16, 0, 16),
                BackgroundColor3 = Accent(),
                BackgroundTransparency = 0.12,
                BorderSizePixel = 0,
                ZIndex = 4
            })
            dot:AddToTheme({BackgroundColor3 = "Accent"})

            Instances:Create("UICorner", {
                Parent = dot.Instance,
                CornerRadius = UDimNew(0, 999)
            })

            Instances:Create("TextLabel", {
                Parent = dot.Instance,
                Name = "\0",
                FontFace = BoldFont,
                Text = tostring(index),
                TextColor3 = FromRGB(255, 255, 255),
                TextSize = 8,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 1, 0),
                ZIndex = 5
            })

            local titleLabel = Instances:Create("TextLabel", {
                Parent = row.Instance,
                Name = "\0",
                FontFace = BoldFont,
                Text = title,
                TextColor3 = Txt(),
                TextSize = 9,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 24, 0, 0),
                Size = UDim2New(0.5, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 4
            })
            titleLabel:AddToTheme({TextColor3 = "Text"})

            Instances:Create("TextLabel", {
                Parent = row.Instance,
                Name = "\0",
                FontFace = Library.Font,
                Text = hint,
                TextColor3 = FromRGB(140, 137, 156),
                TextSize = 8,
                BackgroundTransparency = 1,
                Position = UDim2New(0.5, 0, 0, 0),
                Size = UDim2New(0.5, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 4
            })
        end

        CreateWorkflowRow(1, "UI", "Keybind + theme")
        CreateWorkflowRow(2, "Motion", "Fade + tween")
        CreateWorkflowRow(3, "Config", "Save + autoload")

        local function CreateSnapshotRow(parent, labelText, valueText)
            local row = Instances:Create("Frame", {
                Parent = parent,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 15),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 4
            })

            Instances:Create("TextLabel", {
                Parent = row.Instance,
                Name = "\0",
                FontFace = Library.Font,
                Text = labelText,
                TextColor3 = FromRGB(132, 129, 148),
                TextSize = 10,
                BackgroundTransparency = 1,
                Size = UDim2New(0.48, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 4
            })

            local value = Instances:Create("TextLabel", {
                Parent = row.Instance,
                Name = "\0",
                FontFace = BoldFont,
                Text = valueText,
                TextColor3 = Txt(),
                TextSize = 10,
                BackgroundTransparency = 1,
                Position = UDim2New(0.48, 0, 0, 0),
                Size = UDim2New(0.52, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 4
            })
            value:AddToTheme({TextColor3 = "Text"})
            return value
        end

        local ThemeValue = CreateSnapshotRow(SnapshotBody.Instance, "Theme", "Default")
        local AutoloadValue = CreateSnapshotRow(SnapshotBody.Instance, "Autoload", "Disabled")
        local KeybindValue = CreateSnapshotRow(SnapshotBody.Instance, "Keybind Overlay", KeybindList and "Attached" or "Detached")

        local UISection = Page:Section({
            Name = "UI Settings",
            Description = "Menu access, keybind mode, theme behavior, and the emergency unload action.",
            Icon = "monitor",
            Side = 2
        }) do
            UISection:Keybind({
                Name = "Menu Keybind",
                Flag = "UI_MenuBind",
                Default = Enum.KeyCode.RightControl,
                ToolTip = "Choose the key used to open or close the interface.",
                Callback = function(Value)
                    Window:SetOpen(Value)
                end
            })

            UISection:Dropdown({
                Name = "Library Theme",
                Flag = "UI_ThemePreset",
                Icon = "palette",
                Default = "Default",
                Items = {"Default", "Dark", "Flame", "Plasma", "Forest", "Aqua"},
                ToolTip = "Switch the global theme preset used across the library.",
                Callback = function(Value)
                    ThemeValue.Instance.Text = tostring(Value)
                    HeaderThemeValue.Instance.Text = tostring(Value)
                    Library:ApplyThemePreset(Value)
                end
            })

            UISection:Button({
                Name = "Unload UI",
                Icon = "power",
                ToolTip = "Close and unload the full library immediately.",
                Callback = function()
                    Library:Unload()
                end
            })
        end

        local AnimationSection = Page:Section({
            Name = "Animation Settings",
            Description = "Background blend, fade timing, and tween speed with tighter vertical rhythm.",
            Icon = "sparkles",
            Side = 2
        }) do
            AnimationSection:Slider({
                Name = "Background Transparency",
                Flag = "UI_BackgroundTransparency",
                Default = 0.12,
                Min = 0,
                Max = 1,
                Decimals = 0.01,
                ToolTip = "Control the overall panel transparency level.",
                Callback = function(Value)
                    Window:SetTransparency(Value)
                end
            })

            AnimationSection:Slider({
                Name = "Fade Speed",
                Flag = "UI_FadeSpeed",
                Default = Library.FadeSpeed,
                Min = 0,
                Max = 1,
                Decimals = 0.01,
                ToolTip = "Adjust how quickly interface elements fade in and out.",
                Callback = function(Value)
                    Library.FadeSpeed = Value
                end
            })

            AnimationSection:Slider({
                Name = "Tween Speed",
                Flag = "UI_TweenSpeed",
                Default = Library.Tween.Time,
                Min = 0,
                Max = 1,
                Decimals = 0.01,
                ToolTip = "Adjust the default tween duration used by the library.",
                Callback = function(Value)
                    Library.Tween.Time = Value
                end
            })
        end

        local ConfigName
        local ConfigSelected
        local ConfigsDropdown
        local AutoloadToggle
        local AutoloadInfoParagraph
        local suppressAutoloadCallback = false

        local function UpdateAutoloadSnapshot(configName)
            local current = NormalizeConfigName(configName or GetAutoloadConfig())
            local visible = current and current:gsub("%.json$", "") or "Disabled"
            AutoloadValue.Instance.Text = visible
            HeaderAutoloadValue.Instance.Text = visible
            if AutoloadInfoParagraph then
                AutoloadInfoParagraph:SetText(current or "No autoload config is set right now.")
            end
        end

        local function SetAutoloadToggle(value)
            if not AutoloadToggle then
                return
            end

            suppressAutoloadCallback = true
            AutoloadToggle:Set(value, true)
            suppressAutoloadCallback = false
        end

        local function RefreshConfigPanel(selectedValue)
            local desiredSelection = NormalizeConfigName(selectedValue or ConfigSelected)
            Library:RefreshConfigsList(ConfigsDropdown, desiredSelection)

            if desiredSelection and Library.ConfigManager.Files[desiredSelection] then
                ConfigSelected = desiredSelection
            else
                ConfigSelected = nil
                if ConfigsDropdown then
                    ConfigsDropdown.Value = nil
                    if ConfigsDropdown.Flag then
                        Library.Flags[ConfigsDropdown.Flag] = nil
                    end
                end
            end

            local currentAutoload = NormalizeConfigName(GetAutoloadConfig())
            if currentAutoload and not Library.ConfigManager.Files[currentAutoload] then
                SetAutoloadConfig(nil)
                currentAutoload = nil
            end

            UpdateAutoloadSnapshot(currentAutoload)
            SetAutoloadToggle(currentAutoload ~= nil)

            return ConfigSelected, currentAutoload
        end

        local ConfigsSection = Page:Section({
            Name = "Config Panel",
            Description = "Saved setups, autoload routing, and direct file actions in one cleaner stack.",
            Icon = "folder",
            Side = 3
        }) do
            ConfigsDropdown = ConfigsSection:Listbox({
                Name = "Saved Configs",
                Flag = "ConfigsList",
                Items = {},
                Multi = false,
                ToolTip = "Browse every saved config found in the configs folder.",
                Callback = function(Value)
                    ConfigSelected = NormalizeConfigName(Value)

                    if AutoloadToggle and AutoloadToggle:Get() and ConfigSelected then
                        SetAutoloadConfig(ConfigSelected)
                        UpdateAutoloadSnapshot(ConfigSelected)
                    end
                end
            })

            ConfigsSection:Textbox({
                Name = "Config Name",
                Flag = "ConfigsName",
                Placeholder = "Enter a name...",
                Numeric = false,
                Finished = false,
                ToolTip = "Type the name that should be used when creating a new config.",
                Callback = function(Value)
                    ConfigName = Value
                end
            })

            ConfigsSection:Button({
                Name = "Create",
                Icon = "plus",
                ToolTip = "Create a new config file from the current flags.",
                Callback = function()
                    local desiredName = NormalizeConfigName(ConfigName)
                    if not desiredName then
                        Library:Notification({
                            Title = "Config Error",
                            Description = "Please enter a config name",
                            Duration = 5
                        })
                        return
                    end

                    local Success, Result = Library:CreateConfigFile(desiredName)
                    if not Success then
                        Library:Notification({
                            Title = "Config Error",
                            Description = tostring(Result or "Failed to create config"),
                            Duration = 5
                        })
                        return
                    end

                    RefreshConfigPanel(Result)
                    Library:Notification({
                        Title = "Config Created",
                        Description = strFormat("Created config %q", Result),
                        Duration = 5
                    })
                end
            })

            ConfigsSection:Button({
                Name = "Delete",
                Icon = "trash",
                ToolTip = "Delete the currently selected config file.",
                Callback = function()
                    if not ConfigSelected then
                        Library:Notification({
                            Title = "Config Error",
                            Description = "Select a config before deleting it",
                            Duration = 5
                        })
                        return
                    end

                    local deletedName = ConfigSelected
                    local Success, Result = Library:DeleteConfig(deletedName)
                    if not Success then
                        Library:Notification({
                            Title = "Config Error",
                            Description = tostring(Result or "Failed to delete config"),
                            Duration = 5
                        })
                        return
                    end

                    RefreshConfigPanel(nil)
                    Library:Notification({
                        Title = "Config Deleted",
                        Description = strFormat("Deleted config %q", deletedName),
                        Duration = 5
                    })
                end
            })

            ConfigsSection:Button({
                Name = "Load",
                Icon = "download",
                ToolTip = "Load the selected config into the active interface.",
                Callback = function()
                    if not ConfigSelected then
                        Library:Notification({
                            Title = "Config Error",
                            Description = "Select a config before loading it",
                            Duration = 5
                        })
                        return
                    end

                    local Success, Result = Library:LoadConfig(ConfigSelected)
                    if not Success then
                        Library:Notification({
                            Title = "Config Error",
                            Description = tostring(Result or "Failed to load config"),
                            Duration = 5
                        })
                        return
                    end

                    RefreshConfigPanel(ConfigSelected)
                    Library:Notification({
                        Title = "Config Loaded",
                        Description = strFormat("Loaded config %q", ConfigSelected),
                        Duration = 5
                    })
                end
            })

            ConfigsSection:Button({
                Name = "Save",
                Icon = "save",
                ToolTip = "Overwrite the selected config with the current flag state.",
                Callback = function()
                    if not ConfigSelected then
                        Library:Notification({
                            Title = "Config Error",
                            Description = "Select a config before saving it",
                            Duration = 5
                        })
                        return
                    end

                    local Success, Result = Library:SaveConfigFile(ConfigSelected)
                    if not Success then
                        Library:Notification({
                            Title = "Config Error",
                            Description = tostring(Result or "Failed to save config"),
                            Duration = 5
                        })
                        return
                    end

                    RefreshConfigPanel(Result)
                    Library:Notification({
                        Title = "Config Saved",
                        Description = strFormat("Saved config %q", Result),
                        Duration = 5
                    })
                end
            })

            ConfigsSection:Button({
                Name = "Refresh",
                Icon = "refresh-cw",
                ToolTip = "Refresh the config list from disk.",
                Callback = function()
                    RefreshConfigPanel(ConfigSelected)
                    Library:Notification({
                        Title = "Configs Refreshed",
                        Description = "Refreshed the config list",
                        Duration = 5
                    })
                end
            })

            AutoloadToggle = ConfigsSection:Toggle({
                Name = "Autoload Selected Config",
                Flag = "UI_AutoloadConfig",
                Default = false,
                ToolTip = "When enabled, the selected config becomes the autoload target.",
                Callback = function(Value)
                    if suppressAutoloadCallback then
                        return
                    end

                    if Value then
                        if not ConfigSelected then
                            Library:Notification({
                                Title = "Autoload Error",
                                Description = "Select a config before enabling autoload",
                                Duration = 5
                            })
                            SetAutoloadToggle(false)
                            UpdateAutoloadSnapshot(GetAutoloadConfig())
                            return
                        end

                        SetAutoloadConfig(ConfigSelected)
                        RefreshConfigPanel(ConfigSelected)
                        Library:Notification({
                            Title = "Autoload Set",
                            Description = strFormat("Set %q as autoload config", ConfigSelected),
                            Duration = 5
                        })
                    else
                        SetAutoloadConfig(nil)
                        RefreshConfigPanel(ConfigSelected)
                        Library:Notification({
                            Title = "Autoload Disabled",
                            Description = "Cleared the autoload config",
                            Duration = 5
                        })
                    end
                end
            })
        end

        local InfoSection = Page:Section({
            Name = "Session Info",
            Description = "Storage paths and runtime context for the current settings workspace.",
            Icon = "info",
            Side = 3
        }) do
            local autoloadInitial = NormalizeConfigName(GetAutoloadConfig())

            InfoSection:Paragraph({
                Name = "Config Storage",
                Icon = "hard-drive",
                Text = configFolder
            })

            AutoloadInfoParagraph = InfoSection:Paragraph({
                Name = "Autoload Target",
                Icon = "clock-3",
                Text = autoloadInitial or "No autoload config is set right now."
            })

            InfoSection:Paragraph({
                Name = "Keybind Overlay",
                Icon = "keyboard",
                Text = KeybindList and "A keybind list object is attached to this session." or "No keybind list object was passed into this page."
            })
        end

        local function StyleSectionCard(section)
            local items = section.Items
            if not items then
                return
            end

            items["Section"].Instance.BackgroundTransparency = 0.08
            items["Section"].Instance.BackgroundColor3 = Bg()

            local sectionPadding = items["Section"].Instance:FindFirstChildOfClass("UIPadding")
            if not sectionPadding then
                sectionPadding = InstanceNew("UIPadding")
                sectionPadding.Parent = items["Section"].Instance
            end
            sectionPadding.PaddingTop = UDimNew(0, 8)
            sectionPadding.PaddingBottom = UDimNew(0, 8)
            sectionPadding.PaddingLeft = UDimNew(0, 8)
            sectionPadding.PaddingRight = UDimNew(0, 8)

            local outerStroke = items["Section"].Instance:FindFirstChild("SettingsOuterStroke")
            if not outerStroke then
                outerStroke = InstanceNew("UIStroke")
                outerStroke.Name = "SettingsOuterStroke"
                outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                outerStroke.Thickness = 1
                outerStroke.Parent = items["Section"].Instance
            end
            outerStroke.Color = Outline()
            outerStroke.Transparency = 0.24
            Library:AddToTheme(outerStroke, {Color = "Outline"})

            items["Top"].Instance.BackgroundTransparency = 1
            items["TopBackground"].Instance.BackgroundTransparency = 0.06
            items["Background"].Instance.BackgroundTransparency = 0.02
            items["Fill"].Instance.Visible = false
            items["TopFills"].Instance.Visible = false

            local topLayout = items["TopBackground"].Instance:FindFirstChildOfClass("UIListLayout")
            if topLayout then
                topLayout.Padding = UDimNew(0, 4)
            end

            local topPadding = items["TopBackground"].Instance:FindFirstChildOfClass("UIPadding")
            if not topPadding then
                topPadding = InstanceNew("UIPadding")
                topPadding.Parent = items["TopBackground"].Instance
            end
            topPadding.PaddingTop = UDimNew(0, 8)
            topPadding.PaddingBottom = UDimNew(0, 8)
            topPadding.PaddingLeft = UDimNew(0, 8)
            topPadding.PaddingRight = UDimNew(0, 8)

            items["IconContainer"].Instance.Size = UDim2New(0, 32, 0, 0)
            items["TextContainer"].Instance.Size = UDim2New(1, -74, 0, 0)
            items["ToggleContainer"].Instance.Size = UDim2New(0, 28, 0, 0)
            items["Content"].Instance.Position = UDim2New(0, 12, 0, 10)
            items["Content"].Instance.Size = UDim2New(1, -24, 0, 0)

            local contentLayout = items["Content"].Instance:FindFirstChildOfClass("UIListLayout")
            if contentLayout then
                contentLayout.Padding = UDimNew(0, 8)
            end

            local contentPadding = items["Content"].Instance:FindFirstChildOfClass("UIPadding")
            if contentPadding then
                contentPadding.PaddingBottom = UDimNew(0, 10)
            end

            local textLayout = items["TextContainer"].Instance:FindFirstChildOfClass("UIListLayout")
            if textLayout then
                textLayout.Padding = UDimNew(0, 0)
            end

            local textPadding = items["TextContainer"].Instance:FindFirstChildOfClass("UIPadding")
            if textPadding then
                textPadding.PaddingTop = UDimNew(0, 0)
                textPadding.PaddingBottom = UDimNew(0, 0)
            end

            items["Title"].Instance.TextSize = 13
            if items["Description"] then
                items["Description"].Instance.TextSize = 10
                items["Description"].Instance.TextTransparency = 0.22
            end

            local sectionCorner = items["Section"].Instance:FindFirstChildOfClass("UICorner")
            if sectionCorner then
                sectionCorner.CornerRadius = UDimNew(0, 18)
            end

            local topCorner = items["Top"].Instance:FindFirstChildOfClass("UICorner")
            if topCorner then
                topCorner.CornerRadius = UDimNew(0, 14)
            end

            local topBackgroundCorner = items["TopBackground"].Instance:FindFirstChildOfClass("UICorner")
            if topBackgroundCorner then
                topBackgroundCorner.CornerRadius = UDimNew(0, 14)
            end

            local backgroundCorner = items["Background"].Instance:FindFirstChildOfClass("UICorner")
            if backgroundCorner then
                backgroundCorner.CornerRadius = UDimNew(0, 14)
            end

            local accentBar = items["TopBackground"].Instance:FindFirstChild("SettingsAccentBar")
            if not accentBar then
                accentBar = InstanceNew("Frame")
                accentBar.Name = "SettingsAccentBar"
                accentBar.Size = UDim2New(1, 0, 0, 1)
                accentBar.BackgroundTransparency = 0.45
                accentBar.BorderSizePixel = 0
                accentBar.ZIndex = 3
                accentBar.Parent = items["TopBackground"].Instance

                local accentBarGrad = InstanceNew("UIGradient")
                accentBarGrad.Name = "SettingsAccentGradient"
                accentBarGrad.Parent = accentBar
                Library:AddToTheme(accentBarGrad, {Color = function()
                    return RGBSequence{
                        RGBSequenceKeypoint(0, Library.Theme.Accent),
                        RGBSequenceKeypoint(1, Library.Theme.AccentGradient)
                    }
                end})
            end
            accentBar.BackgroundColor3 = Accent()
            Library:AddToTheme(accentBar, {BackgroundColor3 = "Accent"})

            local accentBarGrad = accentBar:FindFirstChild("SettingsAccentGradient")
            if accentBarGrad then
                accentBarGrad.Color = RGBSequence{
                    RGBSequenceKeypoint(0, Accent()),
                    RGBSequenceKeypoint(1, AccGrad())
                }
            end

            local glow = items["TopBackground"].Instance:FindFirstChild("SettingsHeaderGlow")
            if not glow then
                glow = InstanceNew("Frame")
                glow.Name = "SettingsHeaderGlow"
                glow.AnchorPoint = Vector2New(0.5, 0)
                glow.Position = UDim2New(0.5, 0, 0, 2)
                glow.Size = UDim2New(1, -20, 0, 22)
                glow.BackgroundTransparency = 0.965
                glow.BorderSizePixel = 0
                glow.ZIndex = 1
                glow.Parent = items["TopBackground"].Instance

                local glowCorner = InstanceNew("UICorner")
                glowCorner.CornerRadius = UDimNew(0, 14)
                glowCorner.Parent = glow
            end
            glow.BackgroundColor3 = Accent()
            Library:AddToTheme(glow, {BackgroundColor3 = "Accent"})

            if items["Toggle"] then
                local toggleCorner = items["Toggle"].Instance:FindFirstChildOfClass("UICorner")
                if toggleCorner then
                    toggleCorner.CornerRadius = UDimNew(0, 999)
                end
                items["Toggle"].Instance.Size = UDim2New(0, 24, 0, 14)
            end

            if items["Circle"] then
                items["Circle"].Instance.Size = UDim2New(0, 8, 0, 8)
            end

            local titleKicker = items["TextContainer"].Instance:FindFirstChild("SettingsCardKicker")
            if not titleKicker then
                titleKicker = Instances:Create("TextLabel", {
                    Parent = items["TextContainer"].Instance,
                    Name = "SettingsCardKicker",
                    FontFace = Library.Font,
                    Text = string.upper(items["Title"].Instance.Text),
                    TextColor3 = FromRGB(154, 150, 172),
                    TextSize = 8,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 10),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = 0,
                    ZIndex = 3
                })
            end
        end

        StyleSectionCard(UISection)
        StyleSectionCard(AnimationSection)
        StyleSectionCard(ConfigsSection)
        StyleSectionCard(InfoSection)

        local function ScrollToSection(column, section)
            local target = section and section.Items and section.Items["Section"] and section.Items["Section"].Instance
            if not target or not column then
                return
            end

            local targetY = math.max(0, column.CanvasPosition.Y + target.AbsolutePosition.Y - column.AbsolutePosition.Y - 8)
            TweenService:Create(column, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                CanvasPosition = Vector2New(0, targetY)
            }):Play()
        end

        local navEntries = {}
        local currentNav

        local function SetNavActive(targetEntry)
            currentNav = targetEntry

            for _, entry in ipairs(navEntries) do
                local isActive = entry == targetEntry
                TweenService:Create(entry.Button.Instance, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                    BackgroundTransparency = isActive and 0 or 0.12
                }):Play()
                TweenService:Create(entry.Stroke.Instance, TweenInfo.new(0.18), {
                    Transparency = isActive and 0.04 or 0.45,
                    Color = isActive and Accent() or Outline()
                }):Play()
                TweenService:Create(entry.Highlight.Instance, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                    BackgroundTransparency = isActive and 0.84 or 1
                }):Play()
            end
        end

        local function CreateNavButton(iconName, title, description, column, section)
            local button = Instances:Create("TextButton", {
                Parent = NavBody.Instance,
                Name = "\0",
                Text = "",
                AutoButtonColor = false,
                Size = UDim2New(1, 0, 0, 40),
                BackgroundColor3 = Elem(),
                BackgroundTransparency = 0.12,
                BorderSizePixel = 0,
                ZIndex = 4
            })
            button:AddToTheme({BackgroundColor3 = "Element"})

            Instances:Create("UICorner", {
                Parent = button.Instance,
                CornerRadius = UDimNew(0, 12)
            })

            local stroke = Instances:Create("UIStroke", {
                Parent = button.Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Color = Outline(),
                Thickness = 1,
                Transparency = 0.45
            })
            stroke:AddToTheme({Color = "Outline"})

            local highlight = Instances:Create("Frame", {
                Parent = button.Instance,
                Name = "\0",
                AnchorPoint = Vector2New(0.5, 0.5),
                Position = UDim2New(0.5, 0, 0.5, 0),
                Size = UDim2New(1, 0, 1, 0),
                BackgroundColor3 = Accent(),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 4
            })
            highlight:AddToTheme({BackgroundColor3 = "Accent"})

            Instances:Create("UICorner", {
                Parent = highlight.Instance,
                CornerRadius = UDimNew(0, 12)
            })

            local iconData = Library:GetCustomIcon(iconName)
            local icon = Instances:Create("ImageLabel", {
                Parent = button.Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                Position = UDim2New(0, 12, 0.5, 0),
                AnchorPoint = Vector2New(0, 0.5),
                Size = UDim2New(0, 15, 0, 15),
                Image = iconData and iconData.Url or "",
                ImageRectOffset = iconData and iconData.ImageRectOffset or Vector2New(0, 0),
                ImageRectSize = iconData and iconData.ImageRectSize or Vector2New(0, 0),
                ImageColor3 = Accent(),
                BorderSizePixel = 0,
                ZIndex = 5
            })
            icon:AddToTheme({ImageColor3 = "Accent"})

            local titleLabel = Instances:Create("TextLabel", {
                Parent = button.Instance,
                Name = "\0",
                FontFace = BoldFont,
                Text = title,
                TextColor3 = Txt(),
                TextSize = 10,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 34, 0, 6),
                Size = UDim2New(1, -42, 0, 12),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5
            })
            titleLabel:AddToTheme({TextColor3 = "Text"})

            Instances:Create("TextLabel", {
                Parent = button.Instance,
                Name = "\0",
                FontFace = Library.Font,
                Text = description,
                TextColor3 = FromRGB(142, 139, 158),
                TextSize = 8,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 34, 0, 18),
                Size = UDim2New(1, -42, 0, 11),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 5
            })

            local entry = {
                Button = button,
                Stroke = stroke,
                Highlight = highlight,
                Column = column,
                Section = section
            }
            navEntries[#navEntries + 1] = entry

            button:OnHover(function()
                if currentNav ~= entry then
                    TweenService:Create(button.Instance, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                        BackgroundTransparency = 0.02
                    }):Play()
                    TweenService:Create(stroke.Instance, TweenInfo.new(0.18), {
                        Transparency = 0.12,
                        Color = Accent()
                    }):Play()
                end
            end)

            button:OnHoverLeave(function()
                if currentNav ~= entry then
                    TweenService:Create(button.Instance, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                        BackgroundTransparency = 0.12
                    }):Play()
                    TweenService:Create(stroke.Instance, TweenInfo.new(0.18), {
                        Transparency = 0.45,
                        Color = Outline()
                    }):Play()
                end
            end)

            button:Connect("MouseButton1Click", function()
                SetNavActive(entry)
                ScrollToSection(column, section)
            end)
        end

        CreateNavButton("monitor", "UI Settings", "Keybind, theme, unload", columns.Main, UISection)
        CreateNavButton("sparkles", "Animations", "Transparency, fade, tween", columns.Main, AnimationSection)
        CreateNavButton("folder", "Config Panel", "Saved setups and autoload", columns.Right, ConfigsSection)
        CreateNavButton("info", "Workspace Info", "Storage and context", columns.Right, InfoSection)
        SetNavActive(navEntries[1])

        local initialTheme = Library.Flags["UI_ThemePreset"] or "Default"
        ThemeValue.Instance.Text = tostring(initialTheme)
        HeaderThemeValue.Instance.Text = tostring(initialTheme)
        RefreshConfigPanel(GetAutoloadConfig())

        HeaderKeybindValue.Instance.Text = KeybindList and "Attached" or "Detached"
        KeybindValue.Instance.Text = KeybindList and "Attached" or "Detached"

        Library.ThemeCallbacks[#Library.ThemeCallbacks + 1] = function(theme, tweenInfo)
            local accent = theme.Accent or FromRGB(151, 69, 186)
            local outline = theme.Outline or FromRGB(40, 38, 46)
            local seq = RGBSequence{
                RGBSequenceKeypoint(0, accent),
                RGBSequenceKeypoint(1, theme.AccentGradient or FromRGB(109, 43, 139))
            }

            pcall(function()
                TweenService:Create(TopGlow, tweenInfo, {BackgroundColor3 = accent}):Play()
                TweenService:Create(SideGlow, tweenInfo, {BackgroundColor3 = accent}):Play()
            end)

            pcall(function()
                HeaderTitleGrad.Instance.Color = RGBSequence{
                    RGBSequenceKeypoint(0, FromRGB(255, 255, 255)),
                    RGBSequenceKeypoint(0.55, FromRGB(
                        math.min(255, math.floor(255 * 0.9 + accent.R * 255 * 0.1)),
                        math.min(255, math.floor(255 * 0.9 + accent.G * 255 * 0.1)),
                        math.min(255, math.floor(255 * 0.9 + accent.B * 255 * 0.1))
                    )),
                    RGBSequenceKeypoint(1, FromRGB(
                        math.min(255, math.floor(255 * 0.7 + accent.R * 255 * 0.3)),
                        math.min(255, math.floor(255 * 0.7 + accent.G * 255 * 0.3)),
                        math.min(255, math.floor(255 * 0.7 + accent.B * 255 * 0.3))
                    ))
                }
            end)

            for _, column in pairs(columns) do
                pcall(function()
                    TweenService:Create(column, tweenInfo, {ScrollBarImageColor3 = accent}):Play()
                    local decor = columnDecor[column]
                    if decor and decor.Shell then
                        TweenService:Create(decor.Shell, tweenInfo, {BackgroundColor3 = theme.Element or FromRGB(18, 17, 22)}):Play()
                    end
                    if decor and decor.Stroke then
                        TweenService:Create(decor.Stroke, tweenInfo, {Color = outline}):Play()
                    end
                    if decor and decor.Glow then
                        TweenService:Create(decor.Glow, tweenInfo, {BackgroundColor3 = accent}):Play()
                    end
                    if decor and decor.Divider then
                        TweenService:Create(decor.Divider, tweenInfo, {BackgroundColor3 = outline}):Play()
                    end
                    if decor and decor.Top then
                        TweenService:Create(decor.Top, tweenInfo, {BackgroundColor3 = accent}):Play()
                        local borderGrad = decor.Top:FindFirstChildOfClass("UIGradient")
                        if borderGrad then
                            borderGrad.Color = seq
                        end
                    end
                    if decor and decor.Pill then
                        TweenService:Create(decor.Pill, tweenInfo, {BackgroundColor3 = accent}):Play()
                    end
                    if decor and decor.PillGradient then
                        decor.PillGradient.Color = seq
                    end
                end)
            end

            if currentNav then
                task.defer(function()
                    if Library then
                        SetNavActive(currentNav)
                    end
                end)
            end
        end

        return Page
    end
end
return Library
