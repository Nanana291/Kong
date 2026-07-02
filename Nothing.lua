-- ICON: https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json -
-- EDITED BY FEAR_GOD

local Twen = game:GetService('TweenService');
local Input = game:GetService('UserInputService');
local TextServ = game:GetService('TextService');
local LocalPlayer = game:GetService('Players').LocalPlayer;
local CoreGui = (gethui and gethui()) or game:FindFirstChild('CoreGui') or LocalPlayer.PlayerGui;
local Icons = (function()
	local p,c = pcall(function()
		local Http = game:HttpGetAsync('https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json');

		local Decode = game:GetService('HttpService'):JSONDecode(Http);

		return Decode['icon'];
	end);

	if p then return c end;

	return nil;
end)() or {};

local LucideIconCache = nil

local function LoadLucideIcons()
	if LucideIconCache ~= nil then
		return LucideIconCache
	end

	local ok, result = pcall(function()
		return loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/StyearX/Icons/refs/heads/main/lucide/dist/Icons.lua"))()
	end)

	if ok and type(result) == "table" then
		LucideIconCache = result
		return LucideIconCache
	end

	LucideIconCache = {}
	return LucideIconCache
end

local function ResolveIconSource(icon)
	if type(icon) ~= "string" then
		return icon
	end

	local lower = string.lower(icon)

	if Icons[icon] then
		return Icons[icon]
	end

	if Icons[lower] then
		return Icons[lower]
	end

	if icon:sub(1, 11) == "rbxassetid:" or icon:sub(1, 4) == "http" or icon:sub(1, 11) == "rbxthumb://" then
		return icon
	end

	local lucide = LoadLucideIcons()
	local normalized = lower:gsub("_", "-")
	local resolved = lucide[icon] or lucide[lower] or lucide[normalized] or lucide["lucide-" .. normalized]
	if resolved then
		return resolved
	end

	if Icons[lower] then
		return Icons[lower]
	end

	return icon
end

local ElBlurSource = function()
	local GuiSystem = {}
	local RunService = game:GetService('RunService');
	local CurrentCamera = workspace.CurrentCamera;

	function GuiSystem:Hash()
		return string.reverse(string.gsub(game:GetService('HttpService'):GenerateGUID(false),'..',function(aa)
			return string.reverse(aa)
		end))
	end

	local function Hiter(planePos, planeNormal, rayOrigin, rayDirection)
		local n = planeNormal
		local d = rayDirection
		local v = rayOrigin - planePos

		local num = (n.x*v.x) + (n.y*v.y) + (n.z*v.z)
		local den = (n.x*d.x) + (n.y*d.y) + (n.z*d.z)
		local a = -num / den

		return rayOrigin + (a * rayDirection), a;
	end;

	function GuiSystem.new(frame,NoAutoBackground)
		local Part = Instance.new('Part',workspace);
		local DepthOfField = Instance.new('DepthOfFieldEffect',game:GetService('Lighting'));
		local SurfaceGui = Instance.new('SurfaceGui',Part);
		local BlockMesh = Instance.new("BlockMesh");

		BlockMesh.Parent = Part;

		Part.Material = Enum.Material.Glass;
		Part.Transparency = 1;
		Part.Reflectance = 1;
		Part.CastShadow = false;
		Part.Anchored = true;
		Part.CanCollide = false;
		Part.CanQuery = false;
		Part.CollisionGroup = GuiSystem:Hash();
		Part.Size = Vector3.new(1, 1, 1) * 0.01;
		Part.Color = Color3.fromRGB(0,0,0);

		Twen:Create(Part,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{
			Transparency = 0.8;
		}):Play()

		DepthOfField.Enabled = true;
		DepthOfField.FarIntensity = 1;
		DepthOfField.FocusDistance = 0;
		DepthOfField.InFocusRadius = 500;
		DepthOfField.NearIntensity = 1;

		SurfaceGui.AlwaysOnTop = true;
		SurfaceGui.Adornee = Part;
		SurfaceGui.Active = true;
		SurfaceGui.Face = Enum.NormalId.Front;
		SurfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;

		DepthOfField.Name = GuiSystem:Hash();
		Part.Name = GuiSystem:Hash();
		SurfaceGui.Name = GuiSystem:Hash();

		local C4 = {
			Update = nil,
			Collection = SurfaceGui,
			Enabled = true,
			Instances = {
				BlockMesh = BlockMesh,
				Part = Part,
				DepthOfField = DepthOfField,
				SurfaceGui = SurfaceGui,
			},
			Signal = nil
		};

		local Update = function()
			if not C4.Enabled then
				Twen:Create(Part,TweenInfo.new(1,Enum.EasingStyle.Quint),{
					Transparency = 1;
				}):Play()

			end;

			Twen:Create(Part,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{
				Transparency = 0.8;
			}):Play()

			local corner0 = frame.AbsolutePosition;
			local corner1 = corner0 + frame.AbsoluteSize;

			local ray0 = CurrentCamera.ScreenPointToRay(CurrentCamera,corner0.X, corner0.Y, 1);
			local ray1 = CurrentCamera.ScreenPointToRay(CurrentCamera,corner1.X, corner1.Y, 1);

			local planeOrigin = CurrentCamera.CFrame.Position + CurrentCamera.CFrame.LookVector * (0.05 - CurrentCamera.NearPlaneZ);

			local planeNormal = CurrentCamera.CFrame.LookVector;

			local pos0 = Hiter(planeOrigin, planeNormal, ray0.Origin, ray0.Direction);
			local pos1 = Hiter(planeOrigin, planeNormal, ray1.Origin, ray1.Direction);

			pos0 = CurrentCamera.CFrame:PointToObjectSpace(pos0);
			pos1 = CurrentCamera.CFrame:PointToObjectSpace(pos1);

			local size   = pos1 - pos0;
			local center = (pos0 + pos1) / 2;

			BlockMesh.Offset = center
			BlockMesh.Scale  = size / 0.0101;
			Part.CFrame = CurrentCamera.CFrame;

			if not NoAutoBackground then

				local _,updatec = pcall(function()
					local userSettings = UserSettings():GetService("UserGameSettings")
					local qualityLevel = userSettings.SavedQualityLevel.Value

					if qualityLevel < 8 then
						Twen:Create(frame,TweenInfo.new(1),{
							BackgroundTransparency = 0
						}):Play()
					else
						Twen:Create(frame,TweenInfo.new(1),{
							BackgroundTransparency = 0.4
						}):Play()
					end;
				end)

			end
		end

		C4.Update = Update;
		C4.Signal = RunService.RenderStepped:Connect(Update);

		pcall(function()
			C4.Signal2 = CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
				Part.CFrame = CurrentCamera.CFrame;
			end);
		end)

		C4.Destroy = function()
			C4.Signal:Disconnect();
			C4.Signal2:Disconnect();
			C4.Update = function()

			end;

			Twen:Create(Part,TweenInfo.new(1),{
				Transparency = 1
			}):Play();

			DepthOfField:Destroy();
			Part:Destroy()
		end;

		return C4;
	end;

	return GuiSystem
end;

local ElBlurSource = ElBlurSource();
local Config = function(data, default)
	local source = type(data) == "table" and data or {}
	local result = {}

	for i, v in next, default do
		local value = source[i]
		if value == nil then
			result[i] = v
		else
			result[i] = value
		end
	end

	for i, v in next, source do
		if result[i] == nil then
			result[i] = v
		end
	end

	return result
end;

local Library = {};
local LibraryState = {
	Defaults = {
		Folder = "NothingUI",
		SubFolder = tostring(game.PlaceId),
	},
	LastWindow = nil,
}

local ThemeManager = {
	ActiveTheme = "Default",
	ConfigManager = nil,
	Themes = {
		Default = {
			Accent = Color3.fromRGB(255, 255, 255),
			AccentSoft = Color3.fromRGB(255, 255, 255),
			AccentStroke = Color3.fromRGB(255, 255, 255),
		},
		Kronos = {
			Accent = Color3.fromRGB(82, 128, 214),
			AccentSoft = Color3.fromRGB(82, 128, 214),
			AccentStroke = Color3.fromRGB(82, 128, 214),
		},
	},
	Bindings = setmetatable({}, { __mode = "k" }),
}

function ThemeManager:NormalizeTheme(name)
	name = tostring(name or "Default")
	if self.Themes[name] then
		return name
	end
	return "Default"
end

function ThemeManager:GetThemeName(name)
	return self:NormalizeTheme(name or self.ActiveTheme)
end

function ThemeManager:GetTheme(name)
	return self.Themes[self:NormalizeTheme(name or self.ActiveTheme)] or self.Themes.Default
end

function ThemeManager:GetColor(token, themeName)
	local theme = self:GetTheme(themeName)
	local color = theme[token] or theme.Accent or Color3.fromRGB(255, 255, 255)
	return color
end

function ThemeManager:_ApplyBinding(instance, binding)
	if not instance or not binding then
		return false
	end

	return pcall(function()
		instance[binding.Property] = self:GetColor(binding.Token)
	end)
end

function ThemeManager:Bind(instance, property, token)
	if not instance or property == nil then
		return false
	end

	local bucket = self.Bindings[instance]
	if not bucket then
		bucket = {}
		self.Bindings[instance] = bucket
	end

	bucket[#bucket + 1] = {
		Property = property,
		Token = token or "Accent",
	}

	self:_ApplyBinding(instance, bucket[#bucket])
	return true
end

function ThemeManager:BindAccent(instance, property)
	return self:Bind(instance, property, "Accent")
end

function ThemeManager:BindAccentStroke(instance)
	return self:Bind(instance, "Color", "AccentStroke")
end

function ThemeManager:ApplyTheme(themeName)
	themeName = self:NormalizeTheme(themeName)
	self.ActiveTheme = themeName

	for instance, bucket in pairs(self.Bindings) do
		if bucket and instance then
			for i = 1, #bucket do
				self:_ApplyBinding(instance, bucket[i])
			end
		end
	end
end

function ThemeManager:Persist()
	if self.ConfigManager and self.ConfigManager.PersistAutoload then
		self.ConfigManager:PersistAutoload()
	end
end

function ThemeManager:SetTheme(themeName, silent)
	local normalized = self:NormalizeTheme(themeName)
	if self.ActiveTheme == normalized then
		if not silent then
			self:Persist()
			if self.ConfigManager and self.ConfigManager.SyncSettingsUI then
				self.ConfigManager:SyncSettingsUI()
			end
		end
		return false
	end

	self.ActiveTheme = normalized
	if self.ConfigManager then
		self.ConfigManager.Theme = normalized
	end
	self:ApplyTheme(normalized)

	if not silent then
		self:Persist()
	end

	if self.ConfigManager and self.ConfigManager.SyncSettingsUI then
		self.ConfigManager:SyncSettingsUI()
	end

	return true
end

Library.Theme = ThemeManager

Library['.'] = '1';
Library['FetchIcon'] = "https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json";

pcall(function()
	Library['Icons'] = game:GetService('HttpService'):JSONDecode(game:HttpGetAsync(Library.FetchIcon))['icons'];
end)

local function NormalizePath(path)
	path = tostring(path or "")
	path = path:gsub("\\", "/"):gsub("/+", "/")
	path = path:gsub("^%s+", ""):gsub("%s+$", "")
	path = path:gsub("^/+", ""):gsub("/+$", "")
	return path
end

local function PathJoin(...)
	local parts = {}

	for i = 1, select("#", ...) do
		local part = NormalizePath(select(i, ...))
		if part ~= "" then
			parts[#parts + 1] = part
		end
	end

	return table.concat(parts, "/")
end

local function EnsureFolderTree(path)
	path = NormalizePath(path)
	if path == "" then
		return true
	end

	if typeof(isfolder) ~= "function" or typeof(makefolder) ~= "function" then
		return false
	end

	local current = ""
	for segment in path:gmatch("[^/]+") do
		current = current == "" and segment or (current .. "/" .. segment)
		if not isfolder(current) then
			pcall(makefolder, current)
		end
	end

	return true
end

local function SafeReadFile(path)
	if typeof(readfile) ~= "function" then
		return nil
	end

	local ok, data = pcall(readfile, path)
	if ok then
		return data
	end

	return nil
end

local function SafeWriteFile(path, data)
	if typeof(writefile) ~= "function" then
		return false
	end

	local ok = pcall(writefile, path, data)
	return ok
end

local function SafeIsFile(path)
	if typeof(isfile) ~= "function" then
		return nil
	end

	local ok, exists = pcall(isfile, path)
	if ok then
		return exists == true
	end

	return false
end

local function SafeListFiles(path)
	if typeof(listfiles) ~= "function" then
		return {}
	end

	local ok, files = pcall(listfiles, path)
	if ok and type(files) == "table" then
		return files
	end

	return {}
end

local ConfigNilValue = setmetatable({}, {
	__tostring = function()
		return "__NothingUIConfigNil__"
	end,
})

local ConfigNilKey = "__nothingui_internal_nil__"
local ConfigMetaKey = "__nothingui"

local function SerializeConfigValue(value, seen)
	local valueType = typeof(value)
	if value == nil or value == ConfigNilValue then
		return {
			[ConfigNilKey] = true,
		}
	end

	if valueType == "string" or valueType == "number" or valueType == "boolean" then
		return value
	end

	if valueType == "EnumItem" then
		return value.Name
	end

	if valueType == "table" then
		seen = seen or {}
		if seen[value] then
			return nil
		end

		seen[value] = true
		local result = {}

		for key, entry in pairs(value) do
			local serializedKey = SerializeConfigValue(key, seen)
			local serializedValue = SerializeConfigValue(entry, seen)
			if serializedKey ~= nil then
				result[serializedKey] = serializedValue
			end
		end

		seen[value] = nil
		return result
	end

	return tostring(value)
end

local function DecodeConfigValue(value, seen)
	if value == nil then
		return nil
	end

	if type(value) ~= "table" then
		return value
	end

	if value[ConfigNilKey] == true and next(value, ConfigNilKey) == nil then
		return ConfigNilValue
	end

	seen = seen or {}
	if seen[value] then
		return nil
	end

	seen[value] = true
	local result = {}

	for key, entry in pairs(value) do
		if key ~= ConfigNilKey then
			local decodedKey = DecodeConfigValue(key, seen)
			if decodedKey ~= nil then
				result[decodedKey] = DecodeConfigValue(entry, seen)
			end
		end
	end

	seen[value] = nil
	return result
end

local function CloneConfigValues(data)
	local result = {}
	if type(data) ~= "table" then
		return result
	end

	for key, value in pairs(data) do
		if key ~= ConfigMetaKey then
			result[key] = value
		end
	end

	return result
end

local function ResolveLoadedConfigValue(value, seen)
	if value == ConfigNilValue then
		return nil
	end

	if type(value) ~= "table" then
		return value
	end

	seen = seen or {}
	if seen[value] then
		return nil
	end

	seen[value] = true
	local result = {}

	for key, entry in pairs(value) do
		local resolvedKey = ResolveLoadedConfigValue(key, seen)
		if resolvedKey ~= nil then
			result[resolvedKey] = ResolveLoadedConfigValue(entry, seen)
		end
	end

	seen[value] = nil
	return result
end

local function DecodeFileName(path)
	path = NormalizePath(path)
	local name = path:match("([^/]+)%.json$")
	if name then
		return name
	end

	return nil
end

local function NormalizeSubFolderPath(folder, subfolder)
	local root = NormalizePath(folder)
	local sub = NormalizePath(subfolder)

	if sub ~= "" and root ~= "" then
		if sub == root then
			sub = ""
		elseif sub:sub(1, #root + 1) == (root .. "/") then
			sub = sub:sub(#root + 2)
		end
	end

	if sub == "" then
		sub = tostring(game.PlaceId)
	end

	return sub
end

local function ResolveKeybindValue(value, fallback)
	if typeof(value) == "EnumItem" then
		return value
	end

	if type(value) == "string" and value ~= "" then
		local stripped = value:gsub("^Enum%.KeyCode%.", "")
		return Enum.KeyCode[stripped] or fallback or Enum.KeyCode.Unknown
	end

	return fallback or Enum.KeyCode.Unknown
end

local function FormatKeybindValue(value)
	if typeof(value) == "EnumItem" then
		return Input:GetStringForKeyCode(value) or value.Name
	end

	if type(value) == "string" then
		return value
	end

	return "NONE"
end

local function NormalizeMethodArgs(owner, first, second, third)
	if first == owner then
		return second, third
	end

	return first, second
end

function Library.GradientImage(E : Frame , Color)
	local GLImage = Instance.new("ImageLabel")
	local upd = tick();
	local nextU , Speed , speedy , SIZ = 4 , 5 , -5 , 0.8;
	local nextmain = UDim2.new();
	local rng = Random.new(math.random(10,100000) + math.random(100, 1000) + math.sqrt(tick()));
	local int = 1;
	local TPL = 0.55;

	GLImage.Name = "GLImage"
	GLImage.Parent = E
	GLImage.AnchorPoint = Vector2.new(0.5, 0.5)
	GLImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	GLImage.BackgroundTransparency = 1.000
	GLImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	GLImage.BorderSizePixel = 0
	GLImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	GLImage.Size = UDim2.new(0.800000012, 0, 0.800000012, 0)
	GLImage.SizeConstraint = Enum.SizeConstraint.RelativeYY
	GLImage.ZIndex = E.ZIndex - 1;
	GLImage.Image = "rbxassetid://867619398"
	GLImage.ImageColor3 = Color or Color3.fromRGB(0, 195, 255)
	GLImage.ImageTransparency = 1;

	local str = 'GL_EFFECT_'..tostring(tick());
	game:GetService('RunService'):BindToRenderStep(str,45,function()
		if (tick() - upd) > nextU then
			nextU = rng:NextNumber(1.1,2.5)
			Speed = rng:NextNumber(-6,6)
			speedy = rng:NextNumber(-6,6)
			TPL = rng:NextNumber(0.2,0.8)
			SIZ = rng:NextNumber(0.6,0.9);
			upd = tick();
			int = 1
		else
			speedy = speedy + rng:NextNumber(-0.1,0.1);
			Speed = Speed + rng:NextNumber(-0.1,0.1);

		end;

		nextmain = nextmain:Lerp(UDim2.new(0.5 + (Speed / 24),0,0.5 + (speedy / 24),0) , .025)
		int = int + 0.1

		Twen:Create(GLImage,TweenInfo.new(1),{
			Rotation = GLImage.Rotation + Speed,
			Position = nextmain,
			Size = UDim2.fromScale(SIZ,SIZ),
			ImageTransparency = TPL
		}):Play()
	end)

	return str
end;

function Library.new(config)
	local UserSearchBar = config and config.SearchBar
	local UserTheme = config and config.Theme
	config = Config(config,{
		Title = "UI Library",
		Description = "discord.gg/BH6pE7jesa",
		Keybind = Enum.KeyCode.LeftControl,
		Size = UDim2.new(0.100000001, 445, 0.100000001, 315),
		SearchBar = true,
		Theme = "Default",
	});

	if UserSearchBar == false then
		config.SearchBar = false
	end
	if UserTheme ~= nil then
		config.Theme = UserTheme
	end

	config.SearchBar = config.SearchBar ~= false
	config.Theme = ThemeManager:NormalizeTheme(config.Theme or "Default")
	ThemeManager.ActiveTheme = config.Theme

	local TweenInfo1 = TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut);
	local TweenInfo2 = TweenInfo.new(0.7,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut);

	local WindowTable = {};
	local ConfigManager = nil
	local ScreenGui = Instance.new("ScreenGui")
	local MainFrame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local MainDropShadow = Instance.new("ImageLabel")
	local Headers = Instance.new("Frame")
	local Logo = Instance.new("Frame")
	local UICorner_2 = Instance.new("UICorner")
	local Title = Instance.new("TextLabel")
	local UIGradient = Instance.new("UIGradient")
	local Description = Instance.new("TextLabel")
	local UIGradient_2 = Instance.new("UIGradient")
	local BlockFrame1 = Instance.new("Frame")
	local UICorner_3 = Instance.new("UICorner")
	local UIGradient_3 = Instance.new("UIGradient")
	local BlockFrame3 = Instance.new("Frame")
	local UICorner_4 = Instance.new("UICorner")
	local UIGradient_4 = Instance.new("UIGradient")
	local BlockFrame2 = Instance.new("Frame")
	local UICorner_5 = Instance.new("UICorner")
	local UIGradient_5 = Instance.new("UIGradient")
	local TabButtonFrame = Instance.new("Frame")
	local UICorner_6 = Instance.new("UICorner")
	local TabButtons = Instance.new("ScrollingFrame")
	local UIListLayout = Instance.new("UIListLayout")
	local MainTabFrame = Instance.new("Frame")
	local UICorner_7 = Instance.new("UICorner")
	local InputFrame = Instance.new("Frame")
	local BuiltInLogo = nil
	local CustomLogo = nil
	local LogoVisibleTransparency = 0

	local function TweenLogoVisible(visible)
		local target = visible and LogoVisibleTransparency or 1
		if CustomLogo then
			Twen:Create(CustomLogo, TweenInfo1, {
				ImageTransparency = target,
			}):Play()
		elseif BuiltInLogo then
			Twen:Create(BuiltInLogo, TweenInfo1, {
				TextTransparency = target,
			}):Play()
		end
	end

	WindowTable.Tabs = {};
	WindowTable.Dropdown = {};
	WindowTable.WindowToggle = true;
	WindowTable.Keybind = config.Keybind;
	WindowTable.SearchBar = config.SearchBar
	WindowTable.ToggleButton = nil
	WindowTable.Theme = ThemeManager

	local ImageButton = Instance.new("ImageButton")

	ImageButton.Parent = MainFrame
	ImageButton.AnchorPoint = Vector2.new(1, 0)
	ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ImageButton.BackgroundTransparency = 1.000
	ImageButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ImageButton.BorderSizePixel = 0
	ImageButton.Position = UDim2.new(0.992500007, 0, 0.00999999978, 0)
	ImageButton.Size = UDim2.new(0.0850000009, 0, 0.0850000009, 0)
	ImageButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ImageButton.ZIndex = 50
	ImageButton.Image = "rbxassetid://10002398990"
	ImageButton.ImageTransparency = 1

	local HomeIcon = Instance.new("ImageLabel")
	HomeIcon.Parent = ImageButton
	HomeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	HomeIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	HomeIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
	HomeIcon.BorderSizePixel = 0
	HomeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	HomeIcon.Size = UDim2.new(0.7,0,0.7,0)
	HomeIcon.ZIndex = 49
	HomeIcon.Image = "rbxassetid://7733993211"
	HomeIcon.ScaleType = Enum.ScaleType.Fit
	HomeIcon.ImageTransparency = 1;
	HomeIcon.BackgroundTransparency = 1;

	local HasCustomLogo = type(config.Logo) == "string" and config.Logo ~= ""
	Logo.Name = "Logo"
	Logo.Parent = Headers
	Logo.Active = true
	Logo.AnchorPoint = Vector2.new(0.5, 0.5)
	Logo.BackgroundColor3 = Color3.fromRGB(255, 0, 4)
	Logo.BackgroundTransparency = 1.000
	Logo.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Logo.BorderSizePixel = 0
	Logo.ClipsDescendants = true
	Logo.Position = UDim2.new(0.5, 0, 0.5, 0)
	Logo.Size = UDim2.new(0.949999988, 0, 0.949999988, 0)
	Logo.ZIndex = 4

	if HasCustomLogo then
		CustomLogo = Instance.new("ImageLabel")
		CustomLogo.Name = "CustomLogo"
		CustomLogo.Parent = Logo
		CustomLogo.AnchorPoint = Vector2.new(0.5, 0.5)
		CustomLogo.BackgroundTransparency = 1
		CustomLogo.BorderSizePixel = 0
		CustomLogo.Position = UDim2.new(0.5, 0, 0.5, 0)
		CustomLogo.Size = UDim2.new(1, 0, 1, 0)
		CustomLogo.ZIndex = 4
		CustomLogo.Image = ResolveIconSource(config.Logo)
		CustomLogo.ScaleType = Enum.ScaleType.Crop
		CustomLogo.ImageTransparency = 1
	else
		local LogoText = Instance.new("TextLabel")
		LogoText.Name = "BuiltInLogo"
		LogoText.Parent = Logo
		LogoText.AnchorPoint = Vector2.new(0.5, 0.5)
		LogoText.BackgroundTransparency = 1
		LogoText.BorderSizePixel = 0
		LogoText.Position = UDim2.new(0.5, 0, 0.5, 0)
		LogoText.Size = UDim2.new(1, 0, 1, 0)
		LogoText.ZIndex = 4
		LogoText.Font = Enum.Font.Arcade
		LogoText.RichText = true
		LogoText.Text = '<font color="rgb(235,235,235)">K</font>  <font color="rgb(82,128,214)">R</font>  <font color="rgb(82,128,214)">O</font>  <font color="rgb(82,128,214)">N</font>  <font color="rgb(235,235,235)">O</font>  <font color="rgb(235,235,235)">S</font>'
		LogoText.TextColor3 = Color3.fromRGB(235, 235, 235)
		LogoText.TextScaled = true
		LogoText.TextSize = 14
		LogoText.TextTransparency = 1
		LogoText.TextWrapped = false
		LogoText.TextXAlignment = Enum.TextXAlignment.Center
		LogoText.TextYAlignment = Enum.TextYAlignment.Center
		BuiltInLogo = LogoText
		LogoVisibleTransparency = 0.1
	end

	TweenLogoVisible(true)

	local function Update()
		if WindowTable.WindowToggle then
			Twen:Create(MainFrame,TweenInfo.new(1.5,Enum.EasingStyle.Quint),{BackgroundTransparency = 0.4,Size = config.Size}):Play();
			Twen:Create(MainDropShadow,TweenInfo1,{ImageTransparency = 0.6}):Play();
			Twen:Create(Headers,TweenInfo1,{BackgroundTransparency = 0.5}):Play();
			TweenLogoVisible(true)
			Twen:Create(MainFrame,TweenInfo.new(0.5,Enum.EasingStyle.Quint),{Position = UDim2.fromScale(0.5,0.5)}):Play();
			WindowTable.ElBlurUI.Enabled = true;

			Twen:Create(BlockFrame1,TweenInfo1,{BackgroundTransparency = 0.8}):Play();
			Twen:Create(BlockFrame2,TweenInfo1,{BackgroundTransparency = 0.8}):Play();
			Twen:Create(BlockFrame3,TweenInfo1,{BackgroundTransparency = 0.8}):Play();

			Twen:Create(TabButtonFrame,TweenInfo1,{Position = UDim2.fromScale(0.16,0.215)}):Play();
			Twen:Create(MainTabFrame,TweenInfo1,{Position = UDim2.fromScale(0.658,0.131)}):Play();
			Twen:Create(Description,TweenInfo1,{Position = UDim2.fromScale(0.328,0.071)}):Play();

			Twen:Create(Title,TweenInfo1,{Position = UDim2.fromScale(0.328,0.013)}):Play();
			Twen:Create(Headers,TweenInfo1,{Position = UDim2.fromScale(0.01,0.015)}):Play();

			Twen:Create(ImageButton,TweenInfo.new(0.85,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
				Position = UDim2.new(0.992500007, 0, 0.00999999978, 0),
				Size = UDim2.new(0.0850000009, 0, 0.0850000009, 0),
				ImageTransparency = 0.5,
				AnchorPoint = Vector2.new(1, 0)
			}):Play();

			Twen:Create(HomeIcon,TweenInfo.new(0.5),{
				ImageTransparency = 1,
			}):Play()

			ImageButton.Image = "rbxassetid://10002398990"

			Twen:Create(UICorner,TweenInfo.new(1),{
				CornerRadius = UDim.new(0, 7)
			}):Play()

		else
			Twen:Create(MainFrame,TweenInfo.new(1,Enum.EasingStyle.Quint),{BackgroundTransparency = 1,Size = UDim2.new(0.085, 10,0.05, 0)}):Play();
			Twen:Create(MainFrame,TweenInfo.new(0.5,Enum.EasingStyle.Quint),{Position = UDim2.new(0.5, 0,0.05, 0)}):Play();
			Twen:Create(MainDropShadow,TweenInfo1,{ImageTransparency = 1}):Play();
			Twen:Create(Headers,TweenInfo1,{BackgroundTransparency = 1}):Play();
			TweenLogoVisible(false)
			Twen:Create(TabButtonFrame,TweenInfo1,{Position = UDim2.fromScale(0.16,1.1)}):Play();
			Twen:Create(MainTabFrame,TweenInfo1,{Position = UDim2.fromScale(1.5,0.131)}):Play();
			Twen:Create(Description,TweenInfo1,{Position = UDim2.fromScale(1.5,0.071)}):Play();
			Twen:Create(Headers,TweenInfo1,{Position = UDim2.fromScale(0.01,-0.2)}):Play();

			Twen:Create(UICorner,TweenInfo.new(1),{
				CornerRadius = UDim.new(0.1,0)
			}):Play()

			Twen:Create(ImageButton,TweenInfo1,{
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1,0,1,0),
				ImageTransparency = 1,
				AnchorPoint = Vector2.new(0.5,0.5)
			}):Play();

			Twen:Create(HomeIcon,TweenInfo.new(1),{
				ImageTransparency = 0.5,
			}):Play()


			Twen:Create(Title,TweenInfo1,{Position = UDim2.fromScale(1,0.071)}):Play();


			Twen:Create(BlockFrame1,TweenInfo1,{BackgroundTransparency = 1}):Play();
			Twen:Create(BlockFrame2,TweenInfo1,{BackgroundTransparency = 1}):Play();
			Twen:Create(BlockFrame3,TweenInfo1,{BackgroundTransparency = 1}):Play();

			WindowTable.ElBlurUI.Enabled = false;
		end;

		WindowTable.Dropdown:Close()
		if WindowTable.ToggleButton then
			WindowTable.ToggleButton();
		end;

		task.delay(1,WindowTable.ElBlurUI.Update)
	end;

	local function ToggleWindow()
		WindowTable.WindowToggle = not WindowTable.WindowToggle
		Update()
	end

	Twen:Create(ImageButton,TweenInfo1,{
		ImageTransparency = 0.5
	}):Play()

	ImageButton.MouseButton1Click:Connect(function()
		ToggleWindow()
	end)

	Input.InputBegan:Connect(function(io)
		if io.KeyCode == WindowTable.Keybind then
			ToggleWindow()
		end
	end)

	ScreenGui.Parent = CoreGui;
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
	ScreenGui.ResetOnSpawn = false;
	ScreenGui.IgnoreGuiInset = true;
	ScreenGui.Name = "RobloxGameGui";

	MainFrame.Name = "MainFrame"
	MainFrame.Parent = ScreenGui
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
	MainFrame.BackgroundTransparency = 1
	MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MainFrame.BorderSizePixel = 0
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.Size = UDim2.fromOffset(config.Size.X.Offset,config.Size.Y.Offset)
	MainFrame.Active = true;
	MainFrame.ClipsDescendants = true;

	WindowTable.AddEffect = function(color)
		Library.GradientImage(MainFrame,color)
	end

	Twen:Create(MainFrame,TweenInfo1,{BackgroundTransparency = 0.4,Size = config.Size}):Play();

	WindowTable.ElBlurUI = ElBlurSource.new(MainFrame);

	local FloatingShadow = Instance.new("ImageLabel")
	local FloatingButton = Instance.new("Frame")
	local FloatingCorner = Instance.new("UICorner")
	local FloatingStroke = Instance.new("UIStroke")
	local FloatingHitbox = Instance.new("TextButton")
	local FloatingIcon = Instance.new("Frame")
	local FloatingCamera = workspace.CurrentCamera
	local FloatingViewport = FloatingCamera and FloatingCamera.ViewportSize or Vector2.new(1920, 1080)
	local FloatingEdge = 18
	local FloatingBaseX = FloatingEdge
	local FloatingBaseY = math.max(18, math.floor(FloatingViewport.Y - 82))
	local FloatingSize = 46
	local FloatingShadowOffset = 2
	local FloatingStartPos = nil
	local FloatingStartInput = nil
	local FloatingDragging = false
	local FloatingMoved = false
	local FloatingThreshold = 6
	local FloatingHovering = false

	local function SetFloatingPosition(x, y)
		FloatingButton.Position = UDim2.fromOffset(x, y)
		FloatingShadow.Position = UDim2.fromOffset(x + FloatingShadowOffset, y + FloatingShadowOffset)
	end

	local function SetFloatingVisual(hovered, pressed)
		local target = pressed and 0.25 or (hovered and 0.32 or 0.42)
		Twen:Create(FloatingButton, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundTransparency = target,
		}):Play()
		Twen:Create(FloatingShadow, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			ImageTransparency = pressed and 0.85 or (hovered and 0.78 or 0.82),
		}):Play()
	end

	FloatingShadow.Name = "FloatingShadow"
	FloatingShadow.Parent = ScreenGui
	FloatingShadow.AnchorPoint = Vector2.new(0, 0)
	FloatingShadow.BackgroundTransparency = 1
	FloatingShadow.BorderSizePixel = 0
	FloatingShadow.Position = UDim2.fromOffset(FloatingBaseX + FloatingShadowOffset, FloatingBaseY + FloatingShadowOffset)
	FloatingShadow.Size = UDim2.fromOffset(FloatingSize + 8, FloatingSize + 8)
	FloatingShadow.ZIndex = 50
	FloatingShadow.Image = "rbxassetid://6015897843"
	FloatingShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	FloatingShadow.ImageTransparency = 0.82
	FloatingShadow.ScaleType = Enum.ScaleType.Slice
	FloatingShadow.SliceCenter = Rect.new(49, 49, 450, 450)
	FloatingShadow.Rotation = 0.0001

	FloatingButton.Name = "FloatingButton"
	FloatingButton.Parent = ScreenGui
	FloatingButton.AnchorPoint = Vector2.new(0, 0)
	FloatingButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	FloatingButton.BackgroundTransparency = 0.42
	FloatingButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	FloatingButton.BorderSizePixel = 0
	FloatingButton.ClipsDescendants = false
	FloatingButton.Position = UDim2.fromOffset(FloatingBaseX, FloatingBaseY)
	FloatingButton.Size = UDim2.fromOffset(FloatingSize, FloatingSize)
	FloatingButton.ZIndex = 51

	FloatingCorner.CornerRadius = UDim.new(0, 8)
	FloatingCorner.Parent = FloatingButton

	FloatingStroke.Transparency = 0.88
	FloatingStroke.Color = Color3.fromRGB(255, 255, 255)
	FloatingStroke.Parent = FloatingButton
	ThemeManager:BindAccentStroke(FloatingStroke)

	FloatingHitbox.Name = "Hitbox"
	FloatingHitbox.Parent = FloatingButton
	FloatingHitbox.BackgroundTransparency = 1
	FloatingHitbox.BorderSizePixel = 0
	FloatingHitbox.Size = UDim2.fromScale(1, 1)
	FloatingHitbox.ZIndex = 53
	FloatingHitbox.AutoButtonColor = false
	FloatingHitbox.Text = ""
	FloatingHitbox.Modal = false

	FloatingIcon.Name = "Icon"
	FloatingIcon.Parent = FloatingButton
	FloatingIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	FloatingIcon.BackgroundTransparency = 1
	FloatingIcon.BorderSizePixel = 0
	FloatingIcon.Position = UDim2.fromScale(0.5, 0.5)
	FloatingIcon.Size = UDim2.fromOffset(28, 28)
	FloatingIcon.ZIndex = 52

	local KPattern = {
		"10000",
		"10010",
		"10100",
		"11000",
		"10100",
		"10010",
		"10001",
	}

	local PixelSize = 3
	local PixelGap = 1
	local GridWidth = 5 * PixelSize + 4 * PixelGap
	local GridHeight = 7 * PixelSize + 6 * PixelGap
	local GridX = math.floor((28 - GridWidth) / 2)
	local GridY = math.floor((28 - GridHeight) / 2)

	for rowIndex, row in ipairs(KPattern) do
		for colIndex = 1, #row do
			if row:sub(colIndex, colIndex) == "1" then
				local Pixel = Instance.new("Frame")
				Pixel.Name = "Pixel"
				Pixel.Parent = FloatingIcon
				Pixel.BackgroundColor3 = Color3.fromRGB(242, 242, 242)
				Pixel.BorderSizePixel = 0
				Pixel.Position = UDim2.fromOffset(GridX + (colIndex - 1) * (PixelSize + PixelGap), GridY + (rowIndex - 1) * (PixelSize + PixelGap))
				Pixel.Size = UDim2.fromOffset(PixelSize, PixelSize)
				Pixel.ZIndex = 52
			end
		end
	end

	SetFloatingVisual(false, false)
	SetFloatingPosition(FloatingBaseX, FloatingBaseY)

	FloatingHitbox.MouseEnter:Connect(function()
		FloatingHovering = true
		if not FloatingDragging then
			SetFloatingVisual(true, false)
		end
	end)

	FloatingHitbox.MouseLeave:Connect(function()
		FloatingHovering = false
		if not FloatingDragging then
			SetFloatingVisual(false, false)
		end
	end)

	FloatingHitbox.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		FloatingStartInput = input
		FloatingStartPos = input.Position
		FloatingDragging = false
		FloatingMoved = false
		SetFloatingVisual(true, true)
	end)

	Input.InputChanged:Connect(function(input)
		if not FloatingStartInput or not FloatingStartPos then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - FloatingStartPos
		if not FloatingDragging and delta.Magnitude >= FloatingThreshold then
			FloatingDragging = true
		end

		if FloatingDragging then
			FloatingMoved = true
			local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or FloatingViewport
			local maxX = math.max(FloatingEdge, viewport.X - FloatingSize - FloatingEdge)
			local maxY = math.max(FloatingEdge, viewport.Y - FloatingSize - FloatingEdge)
			local nextX = math.clamp(FloatingButton.Position.X.Offset + delta.X, FloatingEdge, maxX)
			local nextY = math.clamp(FloatingButton.Position.Y.Offset + delta.Y, FloatingEdge, maxY)
			FloatingStartPos = input.Position
			SetFloatingPosition(nextX, nextY)
		end
	end)

	Input.InputEnded:Connect(function(input)
		if not FloatingStartInput then
			return
		end

		if input.UserInputType ~= FloatingStartInput.UserInputType then
			return
		end

		local shouldToggle = not FloatingMoved
		FloatingStartInput = nil
		FloatingStartPos = nil
		FloatingDragging = false
		FloatingMoved = false

		if FloatingHovering then
			SetFloatingVisual(true, false)
		else
			SetFloatingVisual(false, false)
		end

		if shouldToggle then
			ToggleWindow()
		end
	end)

	UICorner.CornerRadius = UDim.new(0, 7)
	UICorner.Parent = MainFrame

	MainDropShadow.Name = "MainDropShadow"
	MainDropShadow.Parent = MainFrame
	MainDropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	MainDropShadow.BackgroundTransparency = 1.000
	MainDropShadow.BorderSizePixel = 0
	MainDropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainDropShadow.Size = UDim2.new(1, 47, 1, 47)
	MainDropShadow.ZIndex = 0
	MainDropShadow.Image = "rbxassetid://6015897843"
	MainDropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	MainDropShadow.ImageTransparency = 1
	MainDropShadow.ScaleType = Enum.ScaleType.Slice
	MainDropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
	MainDropShadow.Rotation = 0.0001;

	Twen:Create(MainDropShadow,TweenInfo2,{ImageTransparency = 0.6}):Play();

	Headers.Name = "Headers"
	Headers.Parent = MainFrame
	Headers.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	Headers.BackgroundTransparency = 1
	Headers.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Headers.BorderSizePixel = 0
	Headers.ClipsDescendants = true
	Headers.Position = UDim2.new(0.0100000743, 0, 0.015, 0)
	Headers.Size = UDim2.new(0.300000012, 0, 0.178419471, 0)
	Headers.ZIndex = 3
	Twen:Create(Headers,TweenInfo2,{BackgroundTransparency = 0.5}):Play();

	UICorner_2.CornerRadius = UDim.new(0, 15)
	UICorner_2.Parent = Headers
	Twen:Create(UICorner_2,TweenInfo2,{CornerRadius = UDim.new(0, 4)}):Play();

	Title.Name = "Title"
	Title.Parent = MainFrame
	Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Title.BackgroundTransparency = 1.000
	Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Title.BorderSizePixel = 0
	Title.Position = UDim2.new(0.327570528, 0, 0.0126646794, 0)
	Title.Size = UDim2.new(0.671064615, 0, 0.0518743545, 0)
	Title.Font = Enum.Font.GothamBold
	Title.Text = config.Title
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextScaled = true
	Title.TextSize = 14.000
	Title.TextWrapped = true
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextTransparency = 1;

	Twen:Create(Title,TweenInfo2,{TextTransparency = 0}):Play();

	UIGradient.Rotation = 90
	UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.75, 0.27), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient.Parent = Title

	Description.Name = "Description"
	Description.Parent = MainFrame
	Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Description.BackgroundTransparency = 1.000
	Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Description.BorderSizePixel = 0
	Description.Position = UDim2.new(0.327570528, 0, 0.0709220618, 0)
	Description.Size = UDim2.new(0.671064615, 0, 0.0290780049, 0)
	Description.Font = Enum.Font.GothamBold
	Description.Text = config.Description
	Description.TextColor3 = Color3.fromRGB(255, 255, 255)
	Description.TextScaled = true
	Description.TextSize = 14.000
	Description.TextTransparency = 1
	Description.TextWrapped = true
	Description.TextXAlignment = Enum.TextXAlignment.Left
	Twen:Create(Description,TweenInfo2,{TextTransparency = 0.5}):Play();

	UIGradient_2.Rotation = 90
	UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.75, 0.27), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient_2.Parent = Description

	BlockFrame1.Name = "BlockFrame1"
	BlockFrame1.Parent = MainFrame
	BlockFrame1.AnchorPoint = Vector2.new(0, 0.5)
	BlockFrame1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BlockFrame1.BackgroundTransparency = 1
	BlockFrame1.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BlockFrame1.BorderSizePixel = 0
	BlockFrame1.Position = UDim2.new(0.317000002, 0, 0.5, 0)
	BlockFrame1.Size = UDim2.new(0, 1, 1, 0)
	BlockFrame1.ZIndex = 3
	Twen:Create(BlockFrame1,TweenInfo2,{BackgroundTransparency = 0.8}):Play();
	ThemeManager:BindAccent(BlockFrame1, "BackgroundColor3")

	UICorner_3.CornerRadius = UDim.new(0.5, 0)
	UICorner_3.Parent = BlockFrame1

	UIGradient_3.Rotation = 90
	UIGradient_3.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.05, 0.00), NumberSequenceKeypoint.new(0.96, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient_3.Parent = BlockFrame1

	BlockFrame3.Name = "BlockFrame3"
	BlockFrame3.Parent = MainFrame
	BlockFrame3.AnchorPoint = Vector2.new(0, 0.5)
	BlockFrame3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BlockFrame3.BackgroundTransparency = 1
	BlockFrame3.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BlockFrame3.BorderSizePixel = 0
	BlockFrame3.Position = UDim2.new(0.317000061, 0, 0.120060779, 0)
	BlockFrame3.Size = UDim2.new(0.682999969, 0, 0, 1)
	BlockFrame3.ZIndex = 3
	Twen:Create(BlockFrame3,TweenInfo2,{BackgroundTransparency = 0.8}):Play();
	ThemeManager:BindAccent(BlockFrame3, "BackgroundColor3")

	UICorner_4.CornerRadius = UDim.new(0.5, 0)
	UICorner_4.Parent = BlockFrame3

	UIGradient_4.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.98, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient_4.Parent = BlockFrame3

	BlockFrame2.Name = "BlockFrame2"
	BlockFrame2.Parent = MainFrame
	BlockFrame2.AnchorPoint = Vector2.new(0, 0.5)
	BlockFrame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BlockFrame2.BackgroundTransparency = 1
	BlockFrame2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BlockFrame2.BorderSizePixel = 0
	BlockFrame2.Position = UDim2.new(-0.00100000005, 0, 0.204999998, 0)
	BlockFrame2.Size = UDim2.new(0.318471342, 0, 0, 1)
	BlockFrame2.ZIndex = 3
	Twen:Create(BlockFrame2,TweenInfo2,{BackgroundTransparency = 0.8}):Play();
	ThemeManager:BindAccent(BlockFrame2, "BackgroundColor3")

	UICorner_5.CornerRadius = UDim.new(0.5, 0)
	UICorner_5.Parent = BlockFrame2

	UIGradient_5.Rotation = -180
	UIGradient_5.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.98, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient_5.Parent = BlockFrame2

	TabButtonFrame.Name = "TabButtonFrame"
	TabButtonFrame.Parent = MainFrame
	TabButtonFrame.AnchorPoint = Vector2.new(0.5, 0)
	TabButtonFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	TabButtonFrame.BackgroundTransparency = 1
	TabButtonFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabButtonFrame.BorderSizePixel = 0
	TabButtonFrame.ClipsDescendants = true
	TabButtonFrame.Position = UDim2.new(0.159999996, 0, 0.215000004, 0)
	TabButtonFrame.Size = UDim2.new(0.300000012, 0, 0.774999976, 0)
	Twen:Create(TabButtonFrame,TweenInfo2,{BackgroundTransparency = 0.5}):Play();

	UICorner_6.CornerRadius = UDim.new(0, 3)
	UICorner_6.Parent = TabButtonFrame

	TabButtons.Name = "TabButtons"
	TabButtons.Parent = TabButtonFrame
	TabButtons.Active = true
	TabButtons.AnchorPoint = Vector2.new(0.5, 0.5)
	TabButtons.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabButtons.BackgroundTransparency = 1.000
	TabButtons.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabButtons.BorderSizePixel = 0
	TabButtons.ClipsDescendants = false
	TabButtons.Position = UDim2.new(0.5, 0, 0.5, 0)
	TabButtons.Size = UDim2.new(0.970000029, 0, 0.970000029, 0)
	TabButtons.ScrollBarThickness = 0
	UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		TabButtons.CanvasSize = UDim2.fromOffset(0,UIListLayout.AbsoluteContentSize.Y)
	end)
	UIListLayout.Parent = TabButtons
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0, 3)

	MainTabFrame.Name = "MainTabFrame"
	MainTabFrame.Parent = MainFrame
	MainTabFrame.AnchorPoint = Vector2.new(0.5, 0)
	MainTabFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	MainTabFrame.BackgroundTransparency = 1
	MainTabFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MainTabFrame.BorderSizePixel = 0
	MainTabFrame.ClipsDescendants = true
	MainTabFrame.Position = UDim2.new(0.657999992, 0, 0.130999997, 0)
	MainTabFrame.Size = UDim2.new(0.670000017, 0, 0.860000014, 0)
	Twen:Create(MainTabFrame,TweenInfo2,{BackgroundTransparency = 0.5}):Play();

	UICorner_7.CornerRadius = UDim.new(0, 3)
	UICorner_7.Parent = MainTabFrame

	InputFrame.Name = "InputFrame"
	InputFrame.Parent = MainFrame
	InputFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	InputFrame.BackgroundTransparency = 1.000
	InputFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	InputFrame.BorderSizePixel = 0
	InputFrame.Position = UDim2.new(0, 0, 3.86494179e-08, 0)
	InputFrame.Size = UDim2.new(1, 0, 0.121327251, 0)
	InputFrame.ZIndex = 15;

	ConfigManager = {
		Registered = {},
		Values = {},
		LoadedData = nil,
		LoadingConfig = false,
		SelectedConfig = "",
		AutoloadEnabled = false,
		Theme = "Default",
		ConstructorTheme = config.Theme,
		Folder = LibraryState.Defaults.Folder,
		SubFolder = LibraryState.Defaults.SubFolder,
		SettingsUI = nil,
	}

	ThemeManager.ConfigManager = ConfigManager

	local function NormalizeConfigName(name, allowEmpty)
		if type(name) == "table" then
			name = ""
		end
		name = tostring(name or "")
		name = name:gsub("[\\/:*?\"<>|]", "_")
		name = name:gsub("^%s+", ""):gsub("%s+$", "")
		name = name:gsub("^%.+", "")
		if name == "" then
			return allowEmpty and "" or "Default"
		end
		return name
	end

	local function IsValidConfigName(name)
		if type(name) ~= "string" then
			return false
		end

		name = name:gsub("^%s+", ""):gsub("%s+$", "")
		if name == "" then
			return false
		end

		if name:find('[\\/:*?"<>|]') then
			return false
		end

		if name:sub(1, 1) == "." then
			return false
		end

		return true
	end

	local function DeepEqual(left, right, visited)
		if left == right then
			return true
		end

		local leftType = type(left)
		local rightType = type(right)
		if leftType ~= rightType then
			return false
		end

		if leftType ~= "table" then
			return left == right
		end

		visited = visited or {}
		local leftVisited = visited[left]
		if leftVisited and leftVisited[right] then
			return true
		end

		if not leftVisited then
			leftVisited = {}
			visited[left] = leftVisited
		end
		leftVisited[right] = true

		for key, value in pairs(left) do
			if not DeepEqual(value, right[key], visited) then
				return false
			end
		end

		for key in pairs(right) do
			if left[key] == nil then
				return false
			end
		end

		return true
	end

	local function NormalizeSubFolder(folder, subfolder)
		return NormalizeSubFolderPath(folder, subfolder)
	end

	function ConfigManager:GetRootPath()
		return PathJoin(self.Folder, self.SubFolder)
	end

	function ConfigManager:GetConfigFolder()
		return PathJoin(self:GetRootPath(), "Configs")
	end

	function ConfigManager:GetConfigPath(name)
		return PathJoin(self:GetConfigFolder(), NormalizeConfigName(name) .. ".json")
	end

	function ConfigManager:GetAutoloadPath()
		return PathJoin(self:GetRootPath(), "autoload.json")
	end

	function ConfigManager:EnsureFolders()
		EnsureFolderTree(self:GetConfigFolder())
	end

	function ConfigManager:ReadJson(path)
		local data = SafeReadFile(path)
		if not data or data == "" then
			return nil
		end

		local ok, decoded = pcall(function()
			return game:GetService("HttpService"):JSONDecode(data)
		end)

		if ok and type(decoded) == "table" then
			return DecodeConfigValue(decoded)
		end

		return nil
	end

	function ConfigManager:WriteJson(path, data)
		local ok, encoded = pcall(function()
			return game:GetService("HttpService"):JSONEncode(data)
		end)

		if not ok then
			return false
		end

		return SafeWriteFile(path, encoded)
	end

	function ConfigManager:RefreshList()
		self:EnsureFolders()

		local configs = {}
		local seen = {}
		for _, file in ipairs(SafeListFiles(self:GetConfigFolder())) do
			local name = DecodeFileName(file)
			name = name and NormalizeConfigName(name, true) or nil
			if name and IsValidConfigName(name) and name ~= "autoload" and not seen[name] then
				seen[name] = true
				configs[#configs + 1] = name
			end
		end

		table.sort(configs)
		return configs
	end

	function ConfigManager:IsConfigAvailable(name)
		name = name and tostring(name) or ""
		name = name:gsub("^%s+", ""):gsub("%s+$", "")
		if not IsValidConfigName(name) then
			return false
		end

		for _, entry in ipairs(self:RefreshList()) do
			if entry == name then
				return true
			end
		end

		return false
	end

	function ConfigManager:SerializeValues()
		local result = {
			[ConfigMetaKey] = {
				Theme = ThemeManager:GetThemeName(ThemeManager.ActiveTheme),
			},
		}
		local nextValues = {}

		for flag, object in pairs(self.Registered) do
			if object and object.GetValue and object.Destroyed ~= true then
				local ok, current = pcall(function()
					return object:GetValue()
				end)
				if ok then
					nextValues[flag] = current ~= nil and current or ConfigNilValue
					result[flag] = SerializeConfigValue(current)
				end
			end
		end

		self.Values = nextValues

		return result
	end

	function ConfigManager:SyncSettingsUI(selectedOverride)
		if not self.SettingsUI then
			return
		end
		if self._SyncingSettingsUI then
			return
		end

		self._SyncingSettingsUI = true

		local function SyncBody()
			local configs = self:RefreshList()
			local ui = self.SettingsUI
			local selected = selectedOverride ~= nil and selectedOverride or (self.SelectedConfig ~= "" and self.SelectedConfig or nil)
			local needsPersist = false
			local available = {}

			for _, name in ipairs(configs) do
				available[name] = true
			end

			if selected ~= nil and not available[selected] then
				selected = nil
				if self.SelectedConfig ~= "" then
					self.SelectedConfig = ""
					needsPersist = true
					if self.AutoloadEnabled then
						self.AutoloadEnabled = false
						needsPersist = true
					end
				end
			end

			if ui.ConfigDropdown and ui.ConfigDropdown.Set then
				ui.ConfigDropdown.Set(configs)
				local current = ui.ConfigDropdown.GetValue and ui.ConfigDropdown:GetValue() or nil
				if not DeepEqual(current, selected) then
					ui.ConfigDropdown.SetValue(selected, true)
				end
			end

			if ui.ConfigTextbox and ui.ConfigTextbox.SetValue then
				local selectedText = type(self.SelectedConfig) == "string" and self.SelectedConfig or ""
				local focused = ui.ConfigTextbox.IsFocused and ui.ConfigTextbox:IsFocused()
				local current = ui.ConfigTextbox.GetValue and ui.ConfigTextbox:GetValue() or ""
				if not focused and current ~= selectedText then
					ui.ConfigTextbox.SetValue(selectedText, true)
				end
			end

			if ui.AutoloadToggle and ui.AutoloadToggle.SetValue then
				local current = ui.AutoloadToggle.GetValue and ui.AutoloadToggle:GetValue() or nil
				if current ~= self.AutoloadEnabled then
					ui.AutoloadToggle.SetValue(self.AutoloadEnabled, true)
				end
			end

			if ui.ThemeDropdown and ui.ThemeDropdown.SetValue then
				local current = ui.ThemeDropdown.GetValue and ui.ThemeDropdown:GetValue() or nil
				local selectedTheme = ThemeManager:GetThemeName(ThemeManager.ActiveTheme)
				if current ~= selectedTheme then
					ui.ThemeDropdown.SetValue(selectedTheme, true)
				end
			end

			if needsPersist then
				self:PersistAutoload()
			end
		end

		local ok, err = xpcall(SyncBody, debug.traceback)
		self._SyncingSettingsUI = false
		if not ok then
			error(err, 0)
		end
	end

	function ConfigManager:PersistAutoload()
		self:EnsureFolders()
		self:WriteJson(self:GetAutoloadPath(), {
			Enabled = self.AutoloadEnabled and true or false,
			Config = self.SelectedConfig ~= "" and self.SelectedConfig or nil,
			Theme = ThemeManager:GetThemeName(ThemeManager.ActiveTheme),
		})
	end

	function ConfigManager:Notify(title, description, icon)
		if type(Library.Notification) ~= "function" then
			return
		end

		pcall(function()
			local manager = Library.Notification()
			if manager and manager.new then
				manager.new({
					Title = title or "Nothing UI",
					Description = description or "",
					Duration = 2.5,
					Icon = icon or "check",
				})
			end
		end)
	end

	function ConfigManager:SetSelectedConfig(name, silent)
		name = name and tostring(name) or ""
		name = name:gsub("^%s+", ""):gsub("%s+$", "")
		if name ~= "" and not IsValidConfigName(name) then
			return false
		end
		if name ~= "" and not self:IsConfigAvailable(name) then
			if not silent then
				self:Notify("Config Missing", ("Config '%s' does not exist."):format(name), "x")
			end
			return false
		end

		if self.SelectedConfig == name then
			if not silent then
				self:PersistAutoload()
			end
			return false
		end

		self.SelectedConfig = name
		self.Theme = ThemeManager:GetThemeName(ThemeManager.ActiveTheme)

		if not silent then
			self:PersistAutoload()
		end

		self:SyncSettingsUI(name ~= "" and name or nil)
		return true
	end

	function ConfigManager:SetAutoloadEnabled(enabled, silent)
		enabled = enabled and true or false
		if enabled then
			if self.SelectedConfig == "" or not self:IsConfigAvailable(self.SelectedConfig) then
				self.AutoloadEnabled = false
				if not silent then
					self:Notify("Autoload Disabled", "Select a valid config before enabling autoload.", "x")
					self:PersistAutoload()
				end
				self:SyncSettingsUI()
				return false
			end
		end

		if self.AutoloadEnabled == enabled then
			if not silent then
				self:PersistAutoload()
			end
			return false
		end

		self.AutoloadEnabled = enabled
		self.Theme = ThemeManager:GetThemeName(ThemeManager.ActiveTheme)

		if not silent then
			self:PersistAutoload()
		end

		self:SyncSettingsUI()
		return true
	end

	function ConfigManager:GetSetter(object)
		if type(object) ~= "table" then
			return nil
		end

		return object.SetValue or object.SetState or object.SetSelected or object.Value or object.Set
	end

	function ConfigManager:Register(flag, object)
		flag = tostring(flag or "")
		if flag == "" or flag == ConfigMetaKey or flag == ConfigNilKey or type(object) ~= "table" then
			return false
		end

		local existing = self.Registered[flag]
		if existing and existing ~= object then
			local existingRoot = existing.Root
			local stale = existing.Destroyed == true
				or existingRoot == nil
				or existingRoot.Parent == nil
			if stale then
				self.Registered[flag] = nil
			else
				warn(("[Nothing UI] Duplicate Flag ignored: %s"):format(flag))
				object.Flag = nil
				return false
			end
		end

		self.Registered[flag] = object
		if object.GetValue then
			local ok, current = pcall(function()
				return object:GetValue()
			end)
			if ok and current ~= nil then
				self.Values[flag] = current
			elseif ok and current == nil then
				self.Values[flag] = ConfigNilValue
			end
		end
		object.Flag = flag
		object.ConfigManager = self

		if object.Root and object.Root.AncestryChanged and not object._RegistryCleanupBound then
			object._RegistryCleanupBound = true
			object.Root.AncestryChanged:Connect(function(_, parent)
				if parent == nil and self.Registered[flag] == object then
					self:Unregister(flag, object)
				end
			end)
		end

		if self.LoadedData and self.LoadedData[flag] ~= nil and self:GetSetter(object) then
			self:ApplyValueToObject(flag, object, self.LoadedData[flag], false)
		end

		return true
	end

	function ConfigManager:Unregister(flag, object)
		flag = tostring(flag or "")
		if flag == "" then
			return false
		end

		local current = self.Registered[flag]
		if not current then
			return false
		end

		if object and current ~= object then
			return false
		end

		self.Registered[flag] = nil
		self.Values[flag] = nil
		if current and current.Destroyed ~= true then
			current.Destroyed = true
		end
		if current then
			current.Flag = nil
			current.ConfigManager = nil
		end

		return true
	end

	function ConfigManager:Update(flag, value)
		if flag == nil then
			return
		end

		self.Values[tostring(flag)] = value ~= nil and value or ConfigNilValue
	end

	function ConfigManager:ApplyValueToObject(flag, object, rawValue, silent)
		flag = tostring(flag or "")
		if flag == "" or not object or object.Destroyed == true or not self:GetSetter(object) then
			return false
		end

		local value = ResolveLoadedConfigValue(rawValue)
		local setter = self:GetSetter(object)
		local ok, err = xpcall(function()
			setter(object, value, silent == true)
		end, debug.traceback)

		if not ok then
			ok, err = xpcall(function()
				setter(value, silent == true)
			end, debug.traceback)
		end

		if not ok then
			warn(("[Nothing UI] Failed to restore Flag '%s': %s"):format(flag, tostring(err)))
			return false
		end

		if object.GetValue then
			local got, current = pcall(function()
				return object:GetValue()
			end)
			if got then
				self.Values[flag] = current ~= nil and current or ConfigNilValue
			else
				self.Values[flag] = value ~= nil and value or ConfigNilValue
			end
		else
			self.Values[flag] = value ~= nil and value or ConfigNilValue
		end

		return true
	end

	function ConfigManager:ApplyLoadedData(silent)
		if type(self.LoadedData) ~= "table" then
			return 0
		end

		local applied = 0
		self.LoadingConfig = true
		for flag, value in pairs(self.LoadedData) do
			if flag ~= ConfigMetaKey then
				local object = self.Registered[flag]
				if object and self:GetSetter(object) and object.Destroyed ~= true then
					if self:ApplyValueToObject(flag, object, value, silent == true) then
						applied = applied + 1
					end
				end
			end
		end
		self.LoadingConfig = false

		return applied
	end

	function ConfigManager:LoadConfig(name, silent)
		name = name and tostring(name) or ""
		name = name:gsub("^%s+", ""):gsub("%s+$", "")
		if not IsValidConfigName(name) then
			if not silent then
				self:Notify("Invalid Config", "The config name is empty or contains invalid characters.", "x")
			end
			return false
		end

		self:EnsureFolders()
		local data = self:ReadJson(self:GetConfigPath(name))
		if type(data) ~= "table" then
			self.LoadedData = nil
			if not silent then
				self:Notify("Load Failed", ("Could not read config '%s'."):format(name), "x")
			end
			return false
		end

		local meta = type(data[ConfigMetaKey]) == "table" and data[ConfigMetaKey] or nil
		if meta and meta.Theme ~= nil then
			self.Theme = ThemeManager:GetThemeName(meta.Theme)
			ThemeManager:SetTheme(self.Theme, true)
		end

		self.LoadedData = CloneConfigValues(data)
		self:ApplyLoadedData(false)
		self.SelectedConfig = name
		self.Theme = ThemeManager:GetThemeName(ThemeManager.ActiveTheme)
		self:PersistAutoload()
		self:SyncSettingsUI(name)
		if not silent then
			self:Notify("Loaded Config", name, "check")
		end
		return true
	end

	function ConfigManager:SaveConfig(name, silent)
		name = name and tostring(name) or ""
		name = name:gsub("^%s+", ""):gsub("%s+$", "")
		if not IsValidConfigName(name) then
			if not silent then
				self:Notify("Invalid Config", "The config name is empty or contains invalid characters.", "x")
			end
			return false
		end

		self:EnsureFolders()
		local payload = self:SerializeValues()
		local configPath = self:GetConfigPath(name)
		local ok = self:WriteJson(configPath, payload)
		local exists = SafeIsFile(configPath)
		if not ok or exists == false then
			if not silent then
				self:Notify("Save Failed", ("Could not write config '%s'."):format(name), "x")
			end
			return false
		end

		self.LoadedData = CloneConfigValues(payload)
		self.SelectedConfig = name
		self.Theme = ThemeManager:GetThemeName(ThemeManager.ActiveTheme)
		self:PersistAutoload()
		self:SyncSettingsUI(name)
		if not silent then
			self:Notify("Saved Config", name, "check")
		end
		return true
	end

	function ConfigManager:LoadAutoload()
		self:EnsureFolders()
		self.LoadedData = nil
		self.AutoloadEnabled = false
		self.SelectedConfig = ""
		self.Theme = ThemeManager:GetThemeName(self.ConstructorTheme or ThemeManager.ActiveTheme or "Default")

		local data = self:ReadJson(self:GetAutoloadPath())
		if type(data) ~= "table" then
			ThemeManager:SetTheme(self.Theme, true)
			self:SyncSettingsUI()
			return false
		end

		self.AutoloadEnabled = data.Enabled == true
		self.Theme = ThemeManager:GetThemeName(data.Theme or self.Theme)
		ThemeManager:SetTheme(self.Theme, true)

		if IsValidConfigName(data.Config) then
			self.SelectedConfig = NormalizeConfigName(data.Config, true)
		end

		if not self.AutoloadEnabled then
			self:SyncSettingsUI(self.SelectedConfig ~= "" and self.SelectedConfig or nil)
			return false
		end

		if self.SelectedConfig == "" or not self:IsConfigAvailable(self.SelectedConfig) then
			local missing = self.SelectedConfig
			self.SelectedConfig = ""
			self.AutoloadEnabled = false
			self:PersistAutoload()
			self:SyncSettingsUI()
			if missing ~= "" then
				self:Notify("Autoload Disabled", ("Config '%s' no longer exists."):format(missing), "x")
			end
			return false
		end

		local selected = self.SelectedConfig
		if self:LoadConfig(selected, true) then
			self.AutoloadEnabled = true
			self.SelectedConfig = selected
			self:PersistAutoload()
			self:SyncSettingsUI(selected)
			self:Notify("Autoload", ("Automatically loaded configuration '%s'."):format(selected), "check")
			return true
		end

		self.AutoloadEnabled = false
		self.SelectedConfig = ""
		self:PersistAutoload()
		self:SyncSettingsUI()
		self:Notify("Autoload Disabled", ("Could not load config '%s'."):format(selected), "x")
		return false
	end

	function ConfigManager:BuildSettingsTab()
		if self.SettingsTab then
			return self.SettingsTab
		end

		local SettingsTab = WindowTable:NewTab({
			Title = "Settings",
			Description = "Configurations",
			Icon = "settings",
		})

		local ConfigSection = SettingsTab:NewSection({
			Position = "Left",
			Title = "Configurations",
			Icon = "settings",
		})

		local CustomizeSection = SettingsTab:NewSection({
			Position = "Right",
			Title = "Customize",
			Icon = "palette",
		})

		local ConfigDropdown = nil
		local ConfigTextbox = nil
		local AutoloadToggle = nil
		local ThemeDropdown = nil

		ConfigDropdown = ConfigSection:NewDropdown({
			Title = "Select Config",
			Data = self:RefreshList(),
			Default = self.SelectedConfig ~= "" and self.SelectedConfig or nil,
			BeforeOpen = function()
				ConfigManager:SyncSettingsUI()
				return ConfigManager:RefreshList()
			end,
			Callback = function(value)
				if type(value) == "string" then
					ConfigManager:SetSelectedConfig(value)
				end
			end,
		})

		ConfigSection:NewButton({
			Title = "Refresh Configs",
			Callback = function()
				local list = ConfigManager:RefreshList()
				if ConfigDropdown and ConfigDropdown.Set then
					ConfigDropdown.Set(list)
				end
				ConfigManager:SyncSettingsUI()
			end,
		})

		ConfigTextbox = ConfigSection:NewTextbox({
			Title = "Config Name",
			Default = type(self.SelectedConfig) == "string" and self.SelectedConfig or "",
			FileType = "",
			Flag = nil,
			Callback = function() end,
		})

		ConfigSection:Divider()

		ConfigSection:NewButton({
			Title = "Save Config",
			Callback = function()
				local name = ""
				if ConfigTextbox and ConfigTextbox.GetValue then
					name = ConfigTextbox:GetValue()
				end
				if type(name) ~= "string" then
					name = tostring(name or "")
				end
				ConfigManager:SaveConfig(name)
			end,
		})

		ConfigSection:NewButton({
			Title = "Load Config",
			Callback = function()
				local name = ConfigDropdown and ConfigDropdown.GetValue and ConfigDropdown:GetValue() or ConfigManager.SelectedConfig
				if type(name) ~= "string" then
					name = ""
				end
				if name ~= "" then
					ConfigManager:LoadConfig(name)
				end
			end,
		})

		ConfigSection:Divider()

		AutoloadToggle = ConfigSection:NewToggle({
			Title = "Set Autoload Config",
			Default = self.AutoloadEnabled,
			Callback = function(value)
				ConfigManager:SetAutoloadEnabled(value)
			end,
		})

		ThemeDropdown = CustomizeSection:NewDropdown({
			Title = "Select Theme",
			Data = {"Default", "Kronos"},
			Default = ThemeManager:GetThemeName(ThemeManager.ActiveTheme),
			Callback = function(value)
				ThemeManager:SetTheme(value)
			end,
		})

		ConfigManager.SettingsUI = {
			ConfigDropdown = ConfigDropdown,
			ConfigTextbox = ConfigTextbox,
			AutoloadToggle = AutoloadToggle,
			ThemeDropdown = ThemeDropdown,
		}
		ConfigManager:SyncSettingsUI()

		self.SettingsTab = SettingsTab
		return SettingsTab
	end

	ConfigManager:LoadAutoload()

	local function NormalizeDropdownValue(values, value, multi)
		if multi then
			local state = {}

			for _, option in ipairs(values) do
				state[option] = false
			end

			if type(value) == "table" then
				for key, enabled in pairs(value) do
					if type(key) == "number" then
						if table.find(values, enabled) then
							state[enabled] = true
						elseif values[enabled] ~= nil then
							state[values[enabled]] = true
						end
					elseif state[key] ~= nil then
						state[key] = enabled and true or false
					end
				end
			elseif type(value) == "number" then
				local option = values[value]
				if option ~= nil then
					state[option] = true
				end
			elseif value ~= nil and table.find(values, value) then
				state[value] = true
			end

			return state
		end

		if type(value) == "table" then
			for key, enabled in pairs(value) do
				if type(key) == "number" then
					if table.find(values, enabled) then
						return enabled
					elseif values[enabled] ~= nil then
						return values[enabled]
					end
				elseif enabled and table.find(values, key) then
					return key
				end
			end

			return nil
		end

		if type(value) == "number" then
			return values[value]
		end

		if value ~= nil and table.find(values, value) then
			return value
		end

		return nil
	end

	local function FormatDropdownValue(values, value, multi)
		if multi then
			local picked = {}

			for _, option in ipairs(values) do
				if value and value[option] then
					picked[#picked + 1] = tostring(option)
				end
			end

			if #picked == 0 then
				return "NONE"
			end

			return table.concat(picked, ", ")
		end

		if value == nil or value == "" then
			return "NONE"
		end

		return tostring(value)
	end

	local function CountDropdownValue(value, multi)
		if not multi then
			return value and 1 or 0
		end

		local count = 0
		for _, enabled in pairs(value or {}) do
			if enabled then
				count += 1
			end
		end

		return count
	end

	task.spawn(function()
		local Locked = nil;
		local Looped = false;

		local DropdownFrame = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local MiniDropShadow = Instance.new("ImageLabel")
		local UIStroke = Instance.new("UIStroke")
		local ValueId = Instance.new("TextLabel")
		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		local ScrollingFrame = Instance.new("ScrollingFrame")
		local UIListLayout = Instance.new("UIListLayout")
		local Block = Instance.new("Frame")
		local BlockFrame3 = Instance.new("Frame")
		local UICorner_2 = Instance.new("UICorner")
		local UIGradient = Instance.new("UIGradient")

		DropdownFrame.Name = "DropdownFrame"
		DropdownFrame.Parent = ScreenGui
		DropdownFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
		DropdownFrame.BackgroundTransparency = 0.500
		DropdownFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		DropdownFrame.BorderSizePixel = 0
		DropdownFrame.Position = UDim2.new(0, 289, 0, 213)
		DropdownFrame.Size = UDim2.new(0, 150, 0, 145)
		DropdownFrame.ZIndex = 100
		DropdownFrame.Visible = false;

		UICorner.CornerRadius = UDim.new(0, 4)
		UICorner.Parent = DropdownFrame

		MiniDropShadow.Name = "MiniDropShadow"
		MiniDropShadow.Parent = DropdownFrame
		MiniDropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
		MiniDropShadow.BackgroundTransparency = 1.000
		MiniDropShadow.BorderSizePixel = 0
		MiniDropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
		MiniDropShadow.Size = UDim2.new(1, 47, 1, 47)
		MiniDropShadow.ZIndex = 99
		MiniDropShadow.Image = "rbxassetid://6015897843"
		MiniDropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		MiniDropShadow.ImageTransparency = 0.600
		MiniDropShadow.ScaleType = Enum.ScaleType.Slice
		MiniDropShadow.SliceCenter = Rect.new(49, 49, 450, 450)

		UIStroke.Transparency = 0.900
		UIStroke.Color = Color3.fromRGB(255, 255, 255)
		UIStroke.Parent = DropdownFrame
		ThemeManager:BindAccentStroke(UIStroke)

		ValueId.Name = "ValueId"
		ValueId.Parent = DropdownFrame
		ValueId.AnchorPoint = Vector2.new(0.5, 0)
		ValueId.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ValueId.BackgroundTransparency = 1.000
		ValueId.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ValueId.BorderSizePixel = 0
		ValueId.Position = UDim2.new(0.5, 0, 0, 0)
		ValueId.Size = UDim2.new(0.970000029, 0, 0.5, 0)
		ValueId.ZIndex = 101
		ValueId.Font = Enum.Font.GothamBold
		ValueId.Text = "NONE"
		ValueId.TextColor3 = Color3.fromRGB(255, 255, 255)
		ValueId.TextScaled = true
		ValueId.TextSize = 14.000
		ValueId.TextTransparency = 0.800
		ValueId.TextWrapped = true
		ValueId.TextXAlignment = Enum.TextXAlignment.Right

		UIAspectRatioConstraint.Parent = ValueId
		UIAspectRatioConstraint.AspectRatio = 15.000
		UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

		ScrollingFrame.Parent = DropdownFrame
		ScrollingFrame.Active = true
		ScrollingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		ScrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ScrollingFrame.BackgroundTransparency = 1.000
		ScrollingFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ScrollingFrame.BorderSizePixel = 0
		ScrollingFrame.Position = UDim2.new(0.5, 0, 0.555985212, 0)
		ScrollingFrame.Size = UDim2.new(0.949999988, 0, 0.888029099, 0)
		ScrollingFrame.ZIndex = 102
		ScrollingFrame.BottomImage = ""
		ScrollingFrame.ScrollBarThickness = 1
		ScrollingFrame.TopImage = ""

		UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			ScrollingFrame.CanvasSize = UDim2.fromOffset(0,UIListLayout.AbsoluteContentSize.Y)
		end)

		UIListLayout.Parent = ScrollingFrame
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Padding = UDim.new(0, 4)

		Block.Name = "Block"
		Block.Parent = ScrollingFrame
		Block.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Block.BackgroundTransparency = 1.000
		Block.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Block.BorderSizePixel = 0

		BlockFrame3.Name = "BlockFrame3"
		BlockFrame3.Parent = DropdownFrame
		BlockFrame3.AnchorPoint = Vector2.new(0, 0.5)
		BlockFrame3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		BlockFrame3.BackgroundTransparency = 0.800
		BlockFrame3.BorderColor3 = Color3.fromRGB(0, 0, 0)
		BlockFrame3.BorderSizePixel = 0
		BlockFrame3.Position = UDim2.new(0, 0, 0.0799999982, 0)
		BlockFrame3.Size = UDim2.new(1, 0, 0, 1)
		BlockFrame3.ZIndex = 102
		ThemeManager:BindAccent(BlockFrame3, "BackgroundColor3")

		UICorner_2.CornerRadius = UDim.new(0.5, 0)
		UICorner_2.Parent = BlockFrame3

		UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.03, 0.00), NumberSequenceKeypoint.new(0.98, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
		UIGradient.Parent = BlockFrame3

		local GetSelector = function(title,value)
			local Selector = Instance.new("Frame")
			local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
			local UICorner = Instance.new("UICorner")
			local Title = Instance.new("TextLabel")
			local UIGradient = Instance.new("UIGradient")
			local Frame = Instance.new("Frame")
			local UICorner_2 = Instance.new("UICorner")
			local UIGradient_2 = Instance.new("UIGradient")
			local Button = Instance.new("TextButton")
			local UIStroke = Instance.new("UIStroke")

			Selector.Name = "Selector"
			Selector.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Selector.BackgroundTransparency = 0.750
			Selector.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Selector.BorderSizePixel = 0
			Selector.ClipsDescendants = true
			Selector.Size = UDim2.new(0.970000029, 0, 0.5, 0)
			Selector.ZIndex = 103
			Selector.Parent = ScrollingFrame
			UIAspectRatioConstraint.Parent = Selector
			UIAspectRatioConstraint.AspectRatio = 6.250
			UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

			UICorner.CornerRadius = UDim.new(0, 3)
			UICorner.Parent = Selector

			Title.Name = "Title"
			Title.Parent = Selector
			Title.AnchorPoint = Vector2.new(0, 0.5)
			Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Title.BackgroundTransparency = 1.000
			Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Title.BorderSizePixel = 0
			Title.Position = UDim2.new(0.0250000004, 0, 0.5, 0)
			Title.Size = UDim2.new(1, 0, 0.5, 0)
			Title.ZIndex = 104
			Title.Font = Enum.Font.GothamBold
			Title.Text = title
			Title.TextColor3 = Color3.fromRGB(255, 255, 255)
			Title.TextScaled = true
			Title.TextSize = 14.000
			Title.TextWrapped = true
			Title.TextXAlignment = Enum.TextXAlignment.Left

			UIGradient.Rotation = 90
			UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
			UIGradient.Parent = Title

			Frame.Parent = Selector
			Frame.AnchorPoint = Vector2.new(1, 0.5)
			Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Frame.BackgroundTransparency = 0.600
			Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Frame.BorderSizePixel = 0
			Frame.Position = UDim2.new(1.02499998, 0, 0.5, 0)
			Frame.Size = UDim2.new(0.0549999997, 0, 0.699999988, 0)
			Frame.ZIndex = 104
			ThemeManager:BindAccent(Frame, "BackgroundColor3")

			UICorner_2.CornerRadius = UDim.new(0, 3)
			UICorner_2.Parent = Frame

			UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
			UIGradient_2.Parent = Frame

			Button.Name = "Button"
			Button.Parent = Selector
			Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Button.BackgroundTransparency = 1.000
			Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Button.BorderSizePixel = 0
			Button.Size = UDim2.new(1, 0, 1, 0)
			Button.ZIndex = 105
			Button.Font = Enum.Font.SourceSans
			Button.Text = ""
			Button.TextColor3 = Color3.fromRGB(0, 0, 0)
			Button.TextSize = 14.000
			Button.TextTransparency = 1.000

			UIStroke.Transparency = 0.900
			UIStroke.Color = Color3.fromRGB(255, 255, 255)
			UIStroke.Parent = Selector;
			ThemeManager:BindAccentStroke(UIStroke)

			local caller = function(a)
				if a then
					Twen:Create(Frame,TweenInfo.new(0.1),{
						Position = UDim2.new(1.02499998, 0, 0.5, 0)
					}):Play()
					Twen:Create(Title,TweenInfo.new(0.1),{
						TextTransparency = 0
					}):Play()

				else
					Twen:Create(Frame,TweenInfo.new(0.1),{
						Position = UDim2.new(1.12499998, 0, 0.5, 0)
					}):Play()
					Twen:Create(Title,TweenInfo.new(0.1),{
						TextTransparency = 0.25
					}):Play()
				end
			end;

			caller(value)

			return {
				effect = caller,
				button = Button,
				delete = function()
					Selector:Destroy()
				end,
			}
		end;

		local MouseInFrame = false;
		local MouseInMyFrame = false;

		function WindowTable.Dropdown:Setup(target_frame:Frame)
			Locked = target_frame
		end;

		function WindowTable.Dropdown:IsOpenFor(target_frame: Frame)
			return Looped and Locked == target_frame
		end;

		function WindowTable.Dropdown:Open(args,defauklt,callback,multi)
			Looped = true;

			local Values = args or {}
			local CurrentValue = NormalizeDropdownValue(Values, defauklt, multi)
			ValueId.Text = FormatDropdownValue(Values, CurrentValue, multi)

			Twen:Create(DropdownFrame,TweenInfo.new(0.3),{
				BackgroundTransparency = 0.1;
			}):Play()

			Twen:Create(MiniDropShadow,TweenInfo.new(0.3),{
				ImageTransparency = 0.6;
			}):Play()

			Twen:Create(ValueId,TweenInfo.new(0.3),{
				TextTransparency = 0.8;
			}):Play()

			Twen:Create(ScrollingFrame,TweenInfo.new(0.3),{
				ScrollBarImageTransparency = 0.5;
			}):Play()

			Twen:Create(BlockFrame3,TweenInfo.new(0.3),{
				BackgroundTransparency = 0.8;
			}):Play()

			Twen:Create(UIStroke,TweenInfo.new(0.3),{
				Transparency = 0.9;
			}):Play()

			for i,v in pairs(ScrollingFrame:GetChildren()) do
				if v ~= Block then
					if v:IsA('Frame') then
						v:Destroy();
					end;
				end;
			end

			local Buttons = {}

			for _, v in ipairs(Values) do
				local Selected = multi and CurrentValue[v] or CurrentValue == v
				local Butt = GetSelector(tostring(v), Selected)

				Butt.button.MouseButton1Click:Connect(function()
					if multi then
						CurrentValue[v] = not CurrentValue[v]
						Butt.effect(CurrentValue[v])
					else
						local Try = not (CurrentValue == v)

						if CountDropdownValue(CurrentValue, false) == 1 and not Try and not Config.AllowNull then
							return
						end

						CurrentValue = Try and v or nil

						for _, OtherButton in ipairs(Buttons) do
							OtherButton.effect(OtherButton.Value == CurrentValue)
						end
					end

					ValueId.Text = FormatDropdownValue(Values, CurrentValue, multi)

					if typeof(callback) == "function" then
						callback(CurrentValue)
					end
				end)

				Buttons[#Buttons + 1] = {
					Value = v,
					effect = Butt.effect,
				}
			end
		end

		function WindowTable.Dropdown:Close(args)
			Looped = false;
			Twen:Create(UIStroke,TweenInfo.new(0.3),{
				Transparency = 1;
			}):Play()
			Twen:Create(DropdownFrame,TweenInfo.new(0.3),{
				BackgroundTransparency = 1;
			}):Play()

			Twen:Create(MiniDropShadow,TweenInfo.new(0.3),{
				ImageTransparency = 1;
			}):Play()

			Twen:Create(ValueId,TweenInfo.new(0.3),{
				TextTransparency = 1;
			}):Play()

			Twen:Create(ScrollingFrame,TweenInfo.new(0.3),{
				ScrollBarImageTransparency = 1;
			}):Play()

			Twen:Create(BlockFrame3,TweenInfo.new(0.3),{
				BackgroundTransparency = 1;
			}):Play()

			for i,v in pairs(ScrollingFrame:GetChildren()) do
				if v ~= Block then
					if v:IsA('Frame') then
						v:Destroy();
					end;
				end;
			end;
		end;

		DropdownFrame.MouseEnter:Connect(function()
			MouseInMyFrame = true
		end)
		DropdownFrame.MouseLeave:Connect(function()
			MouseInMyFrame = false
		end)

		Input.InputBegan:Connect(function(keycode)
			if keycode.UserInputType == Enum.UserInputType.MouseButton1 or keycode.UserInputType == Enum.UserInputType.Touch then
				if not MouseInFrame and not MouseInMyFrame then
					WindowTable.Dropdown:Close();
				end;
			end;
		end)

		game:GetService('RunService'):BindToRenderStep('__LIBRARY__',20,function()
			WindowTable.Dropdown.Value = Looped
			if Looped then
				DropdownFrame.Visible = true;

				Twen:Create(DropdownFrame,TweenInfo.new(0.15),{
					Position = UDim2.fromOffset(Locked.AbsolutePosition.X + 5,Locked.AbsolutePosition.Y + (DropdownFrame.AbsoluteSize.Y / 1.5)),
					Size = UDim2.fromOffset(Locked.AbsoluteSize.X,150)
				}):Play()

			else
				if Locked then
					DropdownFrame.Size = DropdownFrame.Size:Lerp(UDim2.fromOffset(Locked.AbsoluteSize.X,0),.2);
					DropdownFrame.Position = DropdownFrame.Position:Lerp(UDim2.fromOffset(Locked.AbsolutePosition.X,Locked.AbsolutePosition.Y+DropdownFrame.AbsoluteSize.Y),.1);
				else
					DropdownFrame.Size = DropdownFrame.Size:Lerp(UDim2.fromOffset(0,0),.1);
					DropdownFrame.Position = DropdownFrame.Position:Lerp(UDim2.fromOffset(0,0),.1);
				end;

				if DropdownFrame.Size.Y.Offset == 0 then
					DropdownFrame.Visible = false;
				end;
			end;
		end);
	end)

	function WindowTable:NewTab(cfg)
		cfg = Config(cfg,{
			Title = "Example",
			Description = "Tab: "..tostring(#WindowTable.Tabs + 1),
			Icon = "rbxassetid://7733964640"
		});

		local TabTable = {};
		local TabButton = Instance.new("Frame")
		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		local UICorner = Instance.new("UICorner")
		local Icon = Instance.new("ImageLabel")
		local UICorner_2 = Instance.new("UICorner")
		local UIGradient = Instance.new("UIGradient")
		local Title = Instance.new("TextLabel")
		local UIGradient_2 = Instance.new("UIGradient")
		local Description = Instance.new("TextLabel")
		local UIGradient_3 = Instance.new("UIGradient")
		local Frame = Instance.new("Frame")
		local UICorner_3 = Instance.new("UICorner")
		local UIGradient_4 = Instance.new("UIGradient")
		local Button = Instance.new("TextButton")

		TabButton.Name = "TabButton"
		TabButton.Parent = TabButtons
		TabButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TabButton.BackgroundTransparency = 1
		TabButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TabButton.BorderSizePixel = 0
		TabButton.ClipsDescendants = true
		TabButton.Size = UDim2.new(0.970000029, 0, 0.5, 0)
		TabButton.ZIndex = 5
		Twen:Create(TabButton,TweenInfo2,{BackgroundTransparency = 0.750}):Play();

		UIAspectRatioConstraint.Parent = TabButton
		UIAspectRatioConstraint.AspectRatio = 4.250
		UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

		UICorner.CornerRadius = UDim.new(0, 3)
		UICorner.Parent = TabButton

		Icon.Name = "Icon"
		Icon.Parent = TabButton
		Icon.AnchorPoint = Vector2.new(0.5, 0.5)
		Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Icon.BackgroundTransparency = 1.000
		Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Icon.BorderSizePixel = 0
		Icon.Position = UDim2.new(0.100000001, 0, 0.5, 0)
		Icon.Size = UDim2.new(0.600000024, 0, 0.600000024, 0)
		Icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
		Icon.ZIndex = 6
		Icon.Image = ResolveIconSource(cfg.Icon)
		Icon.ImageTransparency = 1
		Twen:Create(Icon,TweenInfo2,{ImageTransparency = 0.1}):Play();

		UICorner_2.CornerRadius = UDim.new(0, 3)
		UICorner_2.Parent = Icon

		UIGradient.Rotation = 90
		UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.75, 0.27), NumberSequenceKeypoint.new(1.00, 1.00)}
		UIGradient.Parent = Icon

		Title.Name = "Title"
		Title.Parent = TabButton
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Title.BackgroundTransparency = 1.000
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BorderSizePixel = 0
		Title.Position = UDim2.new(0.200000003, 0, 0.375, 0)
		Title.Size = UDim2.new(1, 0, 0.400000006, 0)
		Title.Font = Enum.Font.GothamBold
		Title.Text = cfg.Title
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.TextScaled = true
		Title.TextSize = 14.000
		Title.TextWrapped = true
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.TextTransparency = 1;

		UIGradient_2.Rotation = 90
		UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
		UIGradient_2.Parent = Title

		Description.Name = "Description"
		Description.Parent = TabButton
		Description.AnchorPoint = Vector2.new(0, 0.5)
		Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Description.BackgroundTransparency = 1.000
		Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Description.BorderSizePixel = 0
		Description.Position = UDim2.new(0.200000003, 0, 0.699999988, 0)
		Description.Size = UDim2.new(1, 0, 0.300000012, 0)
		Description.Font = Enum.Font.GothamBold
		Description.Text = cfg.Description
		Description.TextColor3 = Color3.fromRGB(255, 255, 255)
		Description.TextScaled = true
		Description.TextSize = 14.000
		Description.TextTransparency = 1
		Description.TextWrapped = true
		Description.TextXAlignment = Enum.TextXAlignment.Left

		UIGradient_3.Rotation = 90
		UIGradient_3.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
		UIGradient_3.Parent = Description

		Frame.Parent = TabButton
		Frame.AnchorPoint = Vector2.new(1, 0.5)
		Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Frame.BackgroundTransparency = 1
		Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Frame.BorderSizePixel = 0
		Frame.Position = UDim2.new(1.02499998, 0, 0.5, 0)
		Frame.Size = UDim2.new(0.0549999997, 0, 0.699999988, 0)
		Frame.ZIndex = 6
		Twen:Create(Frame,TweenInfo2,{BackgroundTransparency = 0.1}):Play();
		ThemeManager:BindAccent(Frame, "BackgroundColor3")

		UICorner_3.CornerRadius = UDim.new(0, 3)
		UICorner_3.Parent = Frame

		UIGradient_4.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
		UIGradient_4.Parent = Frame

		Button.Name = "Button"
		Button.Parent = TabButton
		Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Button.BackgroundTransparency = 1.000
		Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Button.BorderSizePixel = 0
		Button.Size = UDim2.new(1, 0, 1, 0)
		Button.ZIndex = 15
		Button.Font = Enum.Font.SourceSans
		Button.Text = ""
		Button.TextColor3 = Color3.fromRGB(0, 0, 0)
		Button.TextSize = 14.000
		Button.TextTransparency = 1.000

		local Init = Instance.new("Frame")
		local LeftFrame = Instance.new("ScrollingFrame")
		local UIListLayout = Instance.new("UIListLayout")
		local RightFrame = Instance.new("ScrollingFrame")
		local UIListLayout_2 = Instance.new("UIListLayout")

		Init.Name = "Init"
		Init.Parent = MainTabFrame
		Init.AnchorPoint = Vector2.new(0.5, 0.5)
		Init.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Init.BackgroundTransparency = 1.000
		Init.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Init.BorderSizePixel = 0
		Init.Position = UDim2.new(0.5, 0, 0.5, 0)
		Init.Size = UDim2.new(0.980000019, 0, 0.980000019, 0)
		Init.ZIndex = 4

		LeftFrame.Name = "LeftFrame"
		LeftFrame.Parent = Init
		LeftFrame.Active = true
		LeftFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		LeftFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		LeftFrame.BackgroundTransparency = 1.000
		LeftFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		LeftFrame.BorderSizePixel = 0
		LeftFrame.ClipsDescendants = false
		LeftFrame.Position = UDim2.new(0.25, 0, 0.5, 0)
		LeftFrame.Size = UDim2.new(0.5, 0, 1, 0)
		LeftFrame.ScrollBarThickness = 0
		UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			LeftFrame.CanvasSize = UDim2.fromOffset(0,UIListLayout.AbsoluteContentSize.Y)
		end)
		UIListLayout.Parent = LeftFrame
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Padding = UDim.new(0, 3)

		RightFrame.Name = "RightFrame"
		RightFrame.Parent = Init
		RightFrame.Active = true
		RightFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		RightFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		RightFrame.BackgroundTransparency = 1.000
		RightFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RightFrame.BorderSizePixel = 0
		RightFrame.ClipsDescendants = false
		RightFrame.Position = UDim2.new(0.75, 0, 0.5, 0)
		RightFrame.Size = UDim2.new(0.5, 0, 1, 0)
		RightFrame.ScrollBarThickness = 0
		UIListLayout_2:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			RightFrame.CanvasSize = UDim2.fromOffset(0,UIListLayout_2.AbsoluteContentSize.Y)
		end)
		UIListLayout_2.Parent = RightFrame
		UIListLayout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout_2.Padding = UDim.new(0, 3)

		local onFunction = function(value)
			if value then
				Init.Visible = true;

				Twen:Create(Icon,TweenInfo.new(0.55,Enum.EasingStyle.Quint),{
					ImageTransparency = 0.1
				}):Play();

				Twen:Create(Title,TweenInfo.new(0.5,Enum.EasingStyle.Quint),{
					TextTransparency = 0
				}):Play();

				Twen:Create(Description,TweenInfo.new(0.4,Enum.EasingStyle.Quint),{
					TextTransparency = 0.500
				}):Play();

				Twen:Create(Frame,TweenInfo.new(0.55,Enum.EasingStyle.Quint),{
					Position = UDim2.new(1.02499998, 0, 0.5, 0)
				}):Play();
			else
				Init.Visible = false;

				Twen:Create(Icon,TweenInfo.new(0.55,Enum.EasingStyle.Quint),{
					ImageTransparency = 0.25
				}):Play();

				Twen:Create(Title,TweenInfo.new(0.4,Enum.EasingStyle.Quint),{
					TextTransparency = 0.25
				}):Play();

				Twen:Create(Description,TweenInfo.new(0.5,Enum.EasingStyle.Quint),{
					TextTransparency = 0.65
				}):Play();

				Twen:Create(Frame,TweenInfo.new(0.55,Enum.EasingStyle.Quint),{
					Position = UDim2.new(1.1, 0, 0.4, 0)
				}):Play();
			end;
		end;

		if WindowTable.Tabs[1] then
			onFunction(false);
		else
			onFunction(true);
		end;

		table.insert(WindowTable.Tabs,{
			Id = Init,
			onFunction = onFunction,
		})

		Button.MouseButton1Click:Connect(function()
			for i,v in ipairs(WindowTable.Tabs) do
				if v.Id == Init then
					v.onFunction(true);
				else
					v.onFunction(false);
				end;
			end;
		end)

		local SearchManager = {
			Query = "",
			Sections = setmetatable({}, { __mode = "k" }),
			Controls = setmetatable({}, { __mode = "k" }),
		}
		local SearchBarEnabled = config.SearchBar ~= false

		local function NormalizeSearchText(...)
			local parts = {}
			local count = 0

			for i = 1, select("#", ...) do
				local value = select(i, ...)
				if value ~= nil then
					local text = tostring(value)
					if text ~= "" then
						count = count + 1
						parts[count] = text
					end
				end
			end

			return string.lower(table.concat(parts, " ")):gsub("^%s+", ""):gsub("%s+$", "")
		end

		local function SearchContains(text, query)
			if query == "" then
				return true
			end

			return string.find(text, query, 1, true) ~= nil
		end

		local function SetInstanceVisible(object, visible)
			if object and object.Root and object.Root.Visible ~= visible then
				object.Root.Visible = visible
			end
		end

		function SearchManager:Apply()
			local query = self.Query

			for sectionObject, sectionEntry in pairs(self.Sections) do
				if sectionObject and sectionObject.Destroyed ~= true then
					local sectionMatch = query ~= "" and SearchContains(sectionEntry.Text, query)
					local anyChildVisible = false

					for i = 1, #sectionEntry.Children do
						local child = sectionEntry.Children[i]
						if child and child.Object and child.Object.Destroyed ~= true then
							local childMatch = query == "" or SearchContains(child.Text, query)
							local visible = child.BaseVisible and (query == "" or childMatch or sectionMatch)
							SetInstanceVisible(child.Object, visible)
							if visible then
								anyChildVisible = true
							end
						end
					end

					local sectionVisible = sectionEntry.BaseVisible and (query == "" or sectionMatch or anyChildVisible)
					SetInstanceVisible(sectionObject, sectionVisible)
				end
			end

			for controlObject, controlEntry in pairs(self.Controls) do
				if controlObject and controlObject.Destroyed ~= true and controlEntry.Section == nil then
					local visible = controlEntry.BaseVisible and (query == "" or SearchContains(controlEntry.Text, query))
					SetInstanceVisible(controlObject, visible)
				end
			end
		end

		function SearchManager:SetQuery(value)
			value = NormalizeSearchText(value)
			if self.Query == value then
				return false
			end

			self.Query = value
			self:Apply()
			return true
		end

		function SearchManager:RegisterSection(object, root, title)
			local entry = {
				Object = object,
				Root = root,
				Text = NormalizeSearchText(title),
				BaseVisible = true,
				Children = {},
			}

			self.Sections[object] = entry
			if self.Query ~= "" then
				self:Apply()
			end
			return entry
		end

		function SearchManager:RegisterControl(object, root, title, description, sectionObject)
			local sectionEntry = sectionObject and self.Sections[sectionObject] or nil
			local entry = {
				Object = object,
				Root = root,
				Text = NormalizeSearchText(title, description),
				BaseVisible = true,
				Section = sectionEntry,
			}

			self.Controls[object] = entry
			if sectionEntry then
				sectionEntry.Children[#sectionEntry.Children + 1] = entry
			end

			if self.Query ~= "" then
				self:Apply()
			end
			return entry
		end

		function SearchManager:UpdateControlText(object, title, description)
			local entry = self.Controls[object]
			if not entry then
				return
			end

			entry.Text = NormalizeSearchText(title, description)
			if self.Query ~= "" then
				self:Apply()
			end
		end

		function SearchManager:SetObjectVisible(object, visible)
			local entry = self.Controls[object] or self.Sections[object]
			if not entry then
				SetInstanceVisible(object, visible and true or false)
				return
			end

			entry.BaseVisible = visible and true or false
			self:Apply()
		end

		local TooltipManager = {
			ActiveObject = nil,
			Token = 0,
		}

		local TooltipFrame = Instance.new("Frame")
		local TooltipCorner = Instance.new("UICorner")
		local TooltipStroke = Instance.new("UIStroke")
		local TooltipShadow = Instance.new("ImageLabel")
		local TooltipText = Instance.new("TextLabel")

		TooltipFrame.Name = "TooltipFrame"
		TooltipFrame.Parent = ScreenGui
		TooltipFrame.AnchorPoint = Vector2.new(0, 0)
		TooltipFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
		TooltipFrame.BackgroundTransparency = 1
		TooltipFrame.BorderSizePixel = 0
		TooltipFrame.ClipsDescendants = false
		TooltipFrame.Position = UDim2.fromOffset(0, 0)
		TooltipFrame.Size = UDim2.fromOffset(10, 10)
		TooltipFrame.Visible = false
		TooltipFrame.ZIndex = 250

		TooltipShadow.Name = "Shadow"
		TooltipShadow.Parent = TooltipFrame
		TooltipShadow.AnchorPoint = Vector2.new(0.5, 0.5)
		TooltipShadow.BackgroundTransparency = 1
		TooltipShadow.BorderSizePixel = 0
		TooltipShadow.Position = UDim2.fromScale(0.5, 0.5)
		TooltipShadow.Size = UDim2.new(1, 18, 1, 18)
		TooltipShadow.ZIndex = 249
		TooltipShadow.Image = "rbxassetid://6015897843"
		TooltipShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		TooltipShadow.ImageTransparency = 1
		TooltipShadow.ScaleType = Enum.ScaleType.Slice
		TooltipShadow.SliceCenter = Rect.new(49, 49, 450, 450)

		TooltipCorner.CornerRadius = UDim.new(0, 4)
		TooltipCorner.Parent = TooltipFrame

		TooltipStroke.Transparency = 0.85
		TooltipStroke.Color = Color3.fromRGB(255, 255, 255)
		TooltipStroke.Parent = TooltipFrame
		ThemeManager:BindAccentStroke(TooltipStroke)

		TooltipText.Name = "Text"
		TooltipText.Parent = TooltipFrame
		TooltipText.BackgroundTransparency = 1
		TooltipText.BorderSizePixel = 0
		TooltipText.Position = UDim2.fromOffset(8, 6)
		TooltipText.Size = UDim2.fromOffset(10, 10)
		TooltipText.AutomaticSize = Enum.AutomaticSize.XY
		TooltipText.Font = Enum.Font.Gotham
		TooltipText.Text = ""
		TooltipText.TextColor3 = Color3.fromRGB(235, 235, 235)
		TooltipText.TextSize = 12
		TooltipText.TextTransparency = 1
		TooltipText.TextWrapped = true
		TooltipText.TextXAlignment = Enum.TextXAlignment.Left
		TooltipText.TextYAlignment = Enum.TextYAlignment.Top
		TooltipText.ZIndex = 250

		local TooltipPaddingX = 12
		local TooltipPaddingY = 8
		local TooltipMaxWidth = 260
		local TooltipGap = 10
		local TooltipFadeIn = TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local TooltipFadeOut = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		local function TooltipBounds(text)
			local bounds = TextServ:GetTextSize(text, TooltipText.TextSize, TooltipText.Font, Vector2.new(TooltipMaxWidth, math.huge))
			return Vector2.new(bounds.X + (TooltipPaddingX * 2), bounds.Y + (TooltipPaddingY * 2))
		end

		local function TooltipPosition(target, size)
			local camera = workspace.CurrentCamera
			local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
			local anchor = target and target.AbsolutePosition or Vector2.zero
			local targetSize = target and target.AbsoluteSize or Vector2.zero
			local x = anchor.X + math.floor(targetSize.X * 0.5)
			local y = anchor.Y + targetSize.Y + TooltipGap

			if y + size.Y > viewport.Y - 6 then
				y = anchor.Y - size.Y - TooltipGap
			end

			if y < 6 or y + size.Y > viewport.Y - 6 then
				local rightX = anchor.X + targetSize.X + TooltipGap
				local leftX = anchor.X - size.X - TooltipGap

				if rightX + size.X <= viewport.X - 6 then
					x = rightX
					y = math.clamp(anchor.Y + math.floor((targetSize.Y - size.Y) * 0.5), 6, math.max(6, viewport.Y - size.Y - 6))
				elseif leftX >= 6 then
					x = leftX
					y = math.clamp(anchor.Y + math.floor((targetSize.Y - size.Y) * 0.5), 6, math.max(6, viewport.Y - size.Y - 6))
				else
					y = math.clamp(y, 6, math.max(6, viewport.Y - size.Y - 6))
				end
			end

			if x + size.X > viewport.X - 6 then
				x = viewport.X - size.X - 6
			end

			if x < 6 then
				x = 6
			end

			return UDim2.fromOffset(x, y)
		end

		function TooltipManager:Show(target, text)
			text = tostring(text or "")
			if text == "" or not target or target.Parent == nil or not target.Visible then
				return
			end

			self.Token = self.Token + 1
			local token = self.Token
			self.ActiveObject = target

			local size = TooltipBounds(text)
			TooltipText.Text = text
			TooltipText.Size = UDim2.fromOffset(math.max(1, size.X - (TooltipPaddingX * 2)), math.max(1, size.Y - (TooltipPaddingY * 2)))
			TooltipFrame.Size = UDim2.fromOffset(size.X, size.Y)
			TooltipFrame.Position = TooltipPosition(target, size)
			TooltipFrame.Visible = true
			TooltipShadow.ImageTransparency = 1
			TooltipFrame.BackgroundTransparency = 1
			TooltipText.TextTransparency = 1

			Twen:Create(TooltipFrame, TooltipFadeIn, { BackgroundTransparency = 0.2 }):Play()
			Twen:Create(TooltipText, TooltipFadeIn, { TextTransparency = 0.05 }):Play()
			Twen:Create(TooltipShadow, TooltipFadeIn, { ImageTransparency = 0.8 }):Play()

			if token ~= self.Token then
				return
			end
		end

		function TooltipManager:Hide(target)
			if target and self.ActiveObject and target ~= self.ActiveObject then
				return
			end

			self.Token = self.Token + 1
			self.ActiveObject = nil

			local tweenA = Twen:Create(TooltipFrame, TooltipFadeOut, { BackgroundTransparency = 1 })
			local tweenB = Twen:Create(TooltipText, TooltipFadeOut, { TextTransparency = 1 })
			local tweenC = Twen:Create(TooltipShadow, TooltipFadeOut, { ImageTransparency = 1 })
			tweenA:Play()
			tweenB:Play()
			tweenC:Play()

			task.delay(0.12, function()
				if self.ActiveObject == nil then
					TooltipFrame.Visible = false
				end
			end)
		end

		function TooltipManager:Attach(target, tooltipText)
			tooltipText = type(tooltipText) == "string" and tooltipText or ""
			if tooltipText == "" or not target then
				return
			end

			local hoverShown = false
			local touchToken = 0
			local touchStart = nil
			local touchActive = false
			local touchLongShown = false
			local touchThreshold = 8
			local longPressDelay = 0.45

			target.MouseEnter:Connect(function()
				hoverShown = true
				self:Show(target, tooltipText)
			end)

			target.MouseLeave:Connect(function()
				hoverShown = false
				if not touchActive then
					self:Hide(target)
				end
			end)

			target.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				touchActive = true
				touchLongShown = false
				touchToken = touchToken + 1
				local token = touchToken
				touchStart = input.Position

				task.delay(longPressDelay, function()
					if token ~= touchToken or not touchActive or touchStart == nil then
						return
					end

					touchLongShown = true
					self:Show(target, tooltipText)
				end)
			end)

			target.InputChanged:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.Touch or not touchActive or not touchStart then
					return
				end

				if (input.Position - touchStart).Magnitude > touchThreshold then
					touchToken = touchToken + 1
					touchStart = nil
					touchActive = false
					touchLongShown = false
					self:Hide(target)
				end
			end)

			target.InputEnded:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				touchActive = false
				touchToken = touchToken + 1
				touchStart = nil
				if not hoverShown or not touchLongShown then
					self:Hide(target)
				end
				touchLongShown = false
			end)

			target.AncestryChanged:Connect(function(_, parent)
				if parent == nil then
					self:Hide(target)
				end
			end)
		end

		local function RegisterSearchableControl(object, root, title, description, tooltipText, tooltipTarget, sectionObject)
			SearchManager:RegisterControl(object, root, title, description, sectionObject)
			if tooltipText ~= nil and tooltipText ~= "" then
				TooltipManager:Attach(tooltipTarget or root, tooltipText)
			end
		end

		local function RegisterSearchableSection(object, root, title)
			SearchManager:RegisterSection(object, root, title)
		end

		local SearchFrame = nil
		local SearchCorner = nil
		local SearchStroke = nil
		local SearchBox = nil

		if SearchBarEnabled then
			SearchFrame = Instance.new("Frame")
			SearchCorner = Instance.new("UICorner")
			SearchStroke = Instance.new("UIStroke")
			SearchBox = Instance.new("TextBox")

			SearchFrame.Name = "SearchFrame"
			SearchFrame.Parent = Init
			SearchFrame.AnchorPoint = Vector2.new(0.5, 0)
			SearchFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
			SearchFrame.BackgroundTransparency = 0.8
			SearchFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
			SearchFrame.BorderSizePixel = 0
			SearchFrame.Position = UDim2.new(0.5, 0, 0.02, 0)
			SearchFrame.Size = UDim2.new(0.96, 0, 0, 28)
			SearchFrame.ZIndex = 20

			SearchCorner.CornerRadius = UDim.new(0, 3)
			SearchCorner.Parent = SearchFrame

			SearchStroke.Transparency = 0.95
			SearchStroke.Color = Color3.fromRGB(255, 255, 255)
			SearchStroke.Parent = SearchFrame
			ThemeManager:BindAccentStroke(SearchStroke)

			SearchBox.Name = "SearchBox"
			SearchBox.Parent = SearchFrame
			SearchBox.BackgroundTransparency = 1
			SearchBox.BorderSizePixel = 0
			SearchBox.ClearTextOnFocus = false
			SearchBox.Font = Enum.Font.GothamBold
			SearchBox.PlaceholderText = "Search..."
			SearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
			SearchBox.Position = UDim2.fromOffset(10, 0)
			SearchBox.Size = UDim2.new(1, -20, 1, 0)
			SearchBox.Text = ""
			SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			SearchBox.TextScaled = true
			SearchBox.TextSize = 14
			SearchBox.TextTransparency = 0.1
			SearchBox.TextWrapped = false
			SearchBox.TextXAlignment = Enum.TextXAlignment.Left
			SearchBox.ZIndex = 21

			SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
				SearchManager:SetQuery(SearchBox.Text)
			end)
		else
			SearchManager:SetQuery("")
		end

		local contentTop = SearchBarEnabled and 0.57 or 0.505
		local contentHeight = SearchBarEnabled and 0.83 or 0.92
		LeftFrame.Position = UDim2.new(0.25, 0, contentTop, 0)
		LeftFrame.Size = UDim2.new(0.5, 0, contentHeight, 0)
		RightFrame.Position = UDim2.new(0.75, 0, contentTop, 0)
		RightFrame.Size = UDim2.new(0.5, 0, contentHeight, 0)

		function TabTable:NewSection(c_o_n_f_i_g)
			c_o_n_f_i_g = Config(c_o_n_f_i_g,{
				Position = "Left",
				Title = "Section",
				Icon = 'rbxassetid://7733964640'
			});

			local SectionTable = {};
			local Section = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local Header = Instance.new("Frame")
			local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
			local UICorner_2 = Instance.new("UICorner")
			local Icon = Instance.new("ImageLabel")
			local UICorner_3 = Instance.new("UICorner")
			local UIGradient = Instance.new("UIGradient")
			local BlockFrame = Instance.new("Frame")
			local UICorner_4 = Instance.new("UICorner")
			local UIGradient_2 = Instance.new("UIGradient")
			local Title = Instance.new("TextLabel")
			local UIGradient_3 = Instance.new("UIGradient")
			local SectionAutoUI = Instance.new("UIListLayout")
			local UIStroke = Instance.new("UIStroke")
			local UIGradient_4 = Instance.new("UIGradient")

			Section.Name = "Section"
			Section.Parent = (c_o_n_f_i_g.Position == "Left" and LeftFrame) or RightFrame;
			Section.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Section.BackgroundTransparency = 1
			Section.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Section.BorderSizePixel = 0
			Section.Size = UDim2.new(0.980000019, 0, 0, 200)
			Section.ClipsDescendants = true;
			Twen:Create(Section,TweenInfo1,{BackgroundTransparency = 0.75}):Play();

			UICorner.CornerRadius = UDim.new(0, 3)
			UICorner.Parent = Section

			Header.Name = "Header"
			Header.Parent = Section
			Header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Header.BackgroundTransparency = 0.900
			Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Header.BorderSizePixel = 0
			Header.Size = UDim2.new(1, 0, 0.5, 0)
			Twen:Create(Header,TweenInfo2,{BackgroundTransparency = 0.9}):Play();

			UIAspectRatioConstraint.Parent = Header
			UIAspectRatioConstraint.AspectRatio = 8.000
			UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

			UICorner_2.CornerRadius = UDim.new(0, 3)
			UICorner_2.Parent = Header

			Icon.Name = "Icon"
			Icon.Parent = Header
			Icon.AnchorPoint = Vector2.new(0.5, 0.5)
			Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Icon.BackgroundTransparency = 1.000
			Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Icon.BorderSizePixel = 0
			Icon.Position = UDim2.new(0.0649999976, 0, 0.5, 0)
			Icon.Size = UDim2.new(0.600000024, 0, 0.600000024, 0)
			Icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
			Icon.ZIndex = 6
				Icon.Image = ResolveIconSource(c_o_n_f_i_g.Icon)
			Icon.ImageTransparency = 1
			Twen:Create(Icon,TweenInfo2,{ImageTransparency = 0.1}):Play();

			UICorner_3.CornerRadius = UDim.new(0, 3)
			UICorner_3.Parent = Icon

			UIGradient.Rotation = 90
			UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.75, 0.27), NumberSequenceKeypoint.new(1.00, 1.00)}
			UIGradient.Parent = Icon

		BlockFrame.Name = "BlockFrame"
		BlockFrame.Parent = Header
			BlockFrame.AnchorPoint = Vector2.new(0.5, 1)
			BlockFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			BlockFrame.BackgroundTransparency = 1
			BlockFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
			BlockFrame.BorderSizePixel = 0
			BlockFrame.Position = UDim2.new(0.5, 0, 1, 0)
		BlockFrame.Size = UDim2.new(1, 0, 0, 1)
		BlockFrame.ZIndex = 3
		Twen:Create(BlockFrame,TweenInfo2,{BackgroundTransparency = 0.8}):Play();
		ThemeManager:BindAccent(BlockFrame, "BackgroundColor3")

			UICorner_4.CornerRadius = UDim.new(0.5, 0)
			UICorner_4.Parent = BlockFrame

			UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.10, 0.00), NumberSequenceKeypoint.new(0.90, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
			UIGradient_2.Parent = BlockFrame

			Title.Name = "Title"
			Title.Parent = Header
			Title.AnchorPoint = Vector2.new(0, 0.5)
			Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Title.BackgroundTransparency = 1.000
			Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Title.BorderSizePixel = 0
			Title.Position = UDim2.new(0.125, 0, 0.449999988, 0)
			Title.Size = UDim2.new(1, 0, 0.5, 0)
			Title.Font = Enum.Font.GothamBold
			Title.Text = c_o_n_f_i_g.Title
			Title.TextColor3 = Color3.fromRGB(255, 255, 255)
			Title.TextScaled = true
			Title.TextSize = 14.000
			Title.TextWrapped = true
			Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.TextTransparency = 1
			Twen:Create(Title,TweenInfo2,{TextTransparency = 0}):Play();
			SectionTable.Root = Section
			SectionTable.Visible = function(newindx)
				SearchManager:SetObjectVisible(SectionTable, newindx)
			end
			SectionTable.SearchTitle = c_o_n_f_i_g.Title
			RegisterSearchableSection(SectionTable, Section, c_o_n_f_i_g.Title)

			UIGradient_3.Rotation = 90
			UIGradient_3.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
			UIGradient_3.Parent = Title

			SectionAutoUI.Name = "SectionAutoUI"
			SectionAutoUI.Parent = Section
			SectionAutoUI.HorizontalAlignment = Enum.HorizontalAlignment.Center
			SectionAutoUI.SortOrder = Enum.SortOrder.LayoutOrder
			SectionAutoUI.Padding = UDim.new(0, 3)

			SectionAutoUI:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
				Twen:Create(Section,TweenInfo.new(0.1),{
					Size = UDim2.new(0.98,0,0,math.max(SectionAutoUI.AbsoluteContentSize.Y,50) + (SectionAutoUI.Padding.Offset * 1.12));
				}):Play()
			end)

			UIStroke.Transparency = 1
			UIStroke.Color = Color3.fromRGB(255, 255, 255)
			UIStroke.Parent = Section
			ThemeManager:BindAccentStroke(UIStroke)
			Twen:Create(UIStroke,TweenInfo1,{Transparency = 0.9}):Play();

			UIGradient_4.Rotation = 90
			UIGradient_4.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.17, 1.00), NumberSequenceKeypoint.new(0.82, 1.00), NumberSequenceKeypoint.new(1.00, 0.00)}
			UIGradient_4.Parent = UIStroke

			function SectionTable:Paragraph(cfg, description)
				if type(cfg) ~= "table" then
					cfg = {
						Title = cfg,
						Description = description,
					}
				end

				cfg = Config(cfg, {
					Title = "Paragraph",
					Description = "",
				})

				local ParagraphState = {
					Title = tostring(cfg.Title or ""),
					Description = tostring(cfg.Description or ""),
				}

				local FunctionParagraph = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				local UIStroke = Instance.new("UIStroke")
				local TitleText = Instance.new("TextLabel")
				local TitleGradient = Instance.new("UIGradient")
				local DescriptionText = Instance.new("TextLabel")
				local DescriptionGradient = Instance.new("UIGradient")

				FunctionParagraph.Name = "FunctionParagraph"
				FunctionParagraph.Parent = Section
				FunctionParagraph.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionParagraph.BackgroundTransparency = 1
				FunctionParagraph.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionParagraph.BorderSizePixel = 0
				FunctionParagraph.ClipsDescendants = true
				FunctionParagraph.Active = true
				FunctionParagraph.Size = UDim2.new(0.949999988, 0, 0, 34)
				FunctionParagraph.ZIndex = 17
				Twen:Create(FunctionParagraph, TweenInfo1, { BackgroundTransparency = 0.8 }):Play()

				UICorner.CornerRadius = UDim.new(0, 2)
				UICorner.Parent = FunctionParagraph

			UIStroke.Transparency = 0.950
			UIStroke.Color = Color3.fromRGB(255, 255, 255)
			UIStroke.Parent = FunctionParagraph
			ThemeManager:BindAccentStroke(UIStroke)

				TitleText.Name = "TitleText"
				TitleText.Parent = FunctionParagraph
				TitleText.AnchorPoint = Vector2.new(0.5, 0)
				TitleText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TitleText.BackgroundTransparency = 1.000
				TitleText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TitleText.BorderSizePixel = 0
				TitleText.Position = UDim2.new(0.5, 0, 0.05, 0)
				TitleText.Size = UDim2.new(0.949999988, 0, 0, 16)
				TitleText.ZIndex = 18
				TitleText.Font = Enum.Font.GothamBold
				TitleText.Text = ParagraphState.Title
				TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
				TitleText.TextScaled = true
				TitleText.TextSize = 13.000
				TitleText.TextTransparency = 1
				TitleText.TextWrapped = true
				TitleText.TextXAlignment = Enum.TextXAlignment.Left
				TitleText.TextYAlignment = Enum.TextYAlignment.Top
				Twen:Create(TitleText, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					TextTransparency = 0.25,
				}):Play()

				TitleGradient.Rotation = 90
				TitleGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				TitleGradient.Parent = TitleText

				DescriptionText.Name = "DescriptionText"
				DescriptionText.Parent = FunctionParagraph
				DescriptionText.AnchorPoint = Vector2.new(0.5, 0)
				DescriptionText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				DescriptionText.BackgroundTransparency = 1.000
				DescriptionText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				DescriptionText.BorderSizePixel = 0
				DescriptionText.Position = UDim2.new(0.5, 0, 0, 20)
				DescriptionText.Size = UDim2.new(0.949999988, 0, 0, 13)
				DescriptionText.ZIndex = 18
				DescriptionText.Font = Enum.Font.GothamBold
				DescriptionText.Text = ParagraphState.Description
				DescriptionText.TextColor3 = Color3.fromRGB(255, 255, 255)
				DescriptionText.TextScaled = true
				DescriptionText.TextSize = 12.000
				DescriptionText.TextTransparency = 1
				DescriptionText.TextWrapped = true
				DescriptionText.TextXAlignment = Enum.TextXAlignment.Left
				DescriptionText.TextYAlignment = Enum.TextYAlignment.Top
				Twen:Create(DescriptionText, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					TextTransparency = 0.5,
				}):Play()

				DescriptionGradient.Rotation = 90
				DescriptionGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				DescriptionGradient.Parent = DescriptionText

				local function UpdateLayout()
					local rawWidth = FunctionParagraph.AbsoluteSize.X
					if rawWidth <= 0 then
						rawWidth = Section.AbsoluteSize.X
					end

					local measureWidth = math.max(120, math.floor(rawWidth * 0.92))
					local titleBounds = TextServ:GetTextSize(
						ParagraphState.Title ~= "" and ParagraphState.Title or " ",
						14,
						Enum.Font.GothamBold,
						Vector2.new(measureWidth, math.huge)
					)
					local descBounds = TextServ:GetTextSize(
						ParagraphState.Description ~= "" and ParagraphState.Description or " ",
						14,
						Enum.Font.GothamBold,
						Vector2.new(measureWidth, math.huge)
					)

					local titleHeight = math.max(13, titleBounds.Y)
					local descHeight = ParagraphState.Description ~= "" and math.max(12, descBounds.Y) or 0
					local totalHeight = 5 + titleHeight + (descHeight > 0 and (2 + descHeight) or 4)

					FunctionParagraph.Size = UDim2.new(0.949999988, 0, 0, math.max(28, totalHeight))
					TitleText.Size = UDim2.new(0.949999988, 0, 0, titleHeight)
					DescriptionText.Visible = ParagraphState.Description ~= ""
					if descHeight > 0 then
						DescriptionText.Position = UDim2.new(0.5, 0, 0, titleHeight + 2)
						DescriptionText.Size = UDim2.new(0.949999988, 0, 0, descHeight)
					end
				end

				FunctionParagraph:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateLayout)
				task.defer(UpdateLayout)

				local Paragraph = {}
				RegisterSearchableControl(Paragraph, FunctionParagraph, ParagraphState.Title, ParagraphState.Description, cfg.Tooltip, FunctionParagraph, SectionTable)

				function Paragraph:SetTitle(value)
					ParagraphState.Title = tostring(value or "")
					TitleText.Text = ParagraphState.Title
					SearchManager:UpdateControlText(Paragraph, ParagraphState.Title, ParagraphState.Description)
					UpdateLayout()
				end

				function Paragraph:SetDescription(value)
					ParagraphState.Description = tostring(value or "")
					DescriptionText.Text = ParagraphState.Description
					SearchManager:UpdateControlText(Paragraph, ParagraphState.Title, ParagraphState.Description)
					UpdateLayout()
				end

				function Paragraph:Set(title, desc)
					ParagraphState.Title = tostring(title or "")
					ParagraphState.Description = tostring(desc or "")
					TitleText.Text = ParagraphState.Title
					DescriptionText.Text = ParagraphState.Description
					SearchManager:UpdateControlText(Paragraph, ParagraphState.Title, ParagraphState.Description)
					UpdateLayout()
				end

				function Paragraph:Visible(newindx)
					SearchManager:SetObjectVisible(Paragraph, newindx)
				end

				function Paragraph:Destroy()
					SearchManager.Controls[Paragraph] = nil
					FunctionParagraph:Destroy()
				end

				return Paragraph
			end

			SectionTable.AddParagraph = SectionTable.Paragraph

			function SectionTable:NewToggle(toggle)
				toggle = Config(toggle,{
					Title = "Toggle",
					Default = false,
					Callback = function() end;
				});
				toggle.Default = toggle.Default == true
				toggle.Flag = toggle.Flag and tostring(toggle.Flag) or nil
				local ActiveFlag = toggle.Flag
				local Registered = false

				local FunctionToggle = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local Button = Instance.new("TextButton")
				local UIStroke = Instance.new("UIStroke")
				local System = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")
				local Icon = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local UICorner_3 = Instance.new("UICorner")

				FunctionToggle.Name = "FunctionToggle"
				FunctionToggle.Parent = Section
				FunctionToggle.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionToggle.BackgroundTransparency = 1
				FunctionToggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionToggle.BorderSizePixel = 0
				FunctionToggle.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionToggle.ZIndex = 17
				Twen:Create(FunctionToggle,TweenInfo1,{BackgroundTransparency = 0.8}):Play();

				UIAspectRatioConstraint.Parent = FunctionToggle
				UIAspectRatioConstraint.AspectRatio = 8.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionToggle
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.5, 0)
				TextInt.Size = UDim2.new(0.949999988, 0, 0.479999989, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = toggle.Title
				TextInt.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.TextScaled = true
				TextInt.TextSize = 14.000
				TextInt.TextTransparency = 0.250
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left

				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				Button.Name = "Button"
				Button.Parent = FunctionToggle
				Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Button.BackgroundTransparency = 1.000
				Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Button.BorderSizePixel = 0
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.ZIndex = 15
				Button.Font = Enum.Font.SourceSans
				Button.Text = ""
				Button.TextColor3 = Color3.fromRGB(0, 0, 0)
				Button.TextSize = 14.000
				Button.TextTransparency = 1.000

			UIStroke.Transparency = 0.950
			UIStroke.Color = Color3.fromRGB(255, 255, 255)
			UIStroke.Parent = FunctionToggle
			ThemeManager:BindAccentStroke(UIStroke)

				System.Name = "System"
				System.Parent = FunctionToggle
				System.AnchorPoint = Vector2.new(1, 0.5)
				System.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				System.BackgroundTransparency = 1.000
				System.BorderColor3 = Color3.fromRGB(0, 0, 0)
				System.BorderSizePixel = 0
				System.Position = UDim2.new(0.975000024, 0, 0.5, 0)
				System.Size = UDim2.new(0.155000001, 0, 0.600000024, 0)
				System.ZIndex = 18

				UICorner.CornerRadius = UDim.new(0.5, 0)
				UICorner.Parent = System

			UIStroke_2.Transparency = 0.850
			UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
			UIStroke_2.Parent = System
			ThemeManager:BindAccentStroke(UIStroke_2)

				Icon.Name = "Icon"
				Icon.Parent = System
				Icon.AnchorPoint = Vector2.new(0.5, 0.5)
			Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Icon.BackgroundTransparency = 0.500
				Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Icon.BorderSizePixel = 0
				Icon.Position = UDim2.new(0.25, 0, 0.5, 0)
			Icon.Size = UDim2.new(1, 0, 1, 0)
			Icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
			Icon.ZIndex = 17
			ThemeManager:BindAccent(Icon, "BackgroundColor3")

				UICorner_2.CornerRadius = UDim.new(1, 0)
				UICorner_2.Parent = Icon

				UICorner_3.CornerRadius = UDim.new(0, 2)
				UICorner_3.Parent = FunctionToggle

				local AttachedKeybind = nil
				local function UpdateToggleTitleWidth(hasKeybind)
					TextInt.Size = hasKeybind and UDim2.new(0.699999988, 0, 0.479999989, 0)
						or UDim2.new(0.949999988, 0, 0.479999989, 0)
				end

				UpdateToggleTitleWidth(false)

				local function CreateAttachedKeybind(bindCfg)
					if AttachedKeybind then
						return AttachedKeybind
					end

					bindCfg = Config(bindCfg, {
						Default = Enum.KeyCode.E,
						Callback = function() end,
					})
					bindCfg.Flag = bindCfg.Flag and tostring(bindCfg.Flag) or nil
					local BindActiveFlag = bindCfg.Flag

					local BindEvent = Instance.new("BindableEvent", FunctionToggle)
					local KeybindFrame = Instance.new("Frame")
					local KeybindCorner = Instance.new("UICorner")
					local KeybindStroke = Instance.new("UIStroke")
					local KeybindText = Instance.new("TextLabel")
					local KeybindButton = Instance.new("TextButton")
					local Capturing = false
					local Dispatching = false
					local CurrentBind = ResolveKeybindValue(bindCfg.Default, Enum.KeyCode.E)

					KeybindFrame.Name = "Keybind"
					KeybindFrame.Parent = FunctionToggle
					KeybindFrame.AnchorPoint = Vector2.new(1, 0.5)
					KeybindFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
					KeybindFrame.BackgroundTransparency = 1.000
					KeybindFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
					KeybindFrame.BorderSizePixel = 0
					KeybindFrame.Position = UDim2.new(0.885, 0, 0.5, 0)
					KeybindFrame.Size = UDim2.new(0, 50, 0.600000024, 0)
					KeybindFrame.ZIndex = 19

					KeybindCorner.CornerRadius = UDim.new(0.349999994, 0)
					KeybindCorner.Parent = KeybindFrame

					KeybindStroke.Transparency = 0.950
					KeybindStroke.Color = Color3.fromRGB(255, 255, 255)
					KeybindStroke.Parent = KeybindFrame

					KeybindText.Name = "Bindkey"
					KeybindText.Parent = KeybindFrame
					KeybindText.AnchorPoint = Vector2.new(0.5, 0.5)
					KeybindText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					KeybindText.BackgroundTransparency = 1.000
					KeybindText.BorderColor3 = Color3.fromRGB(0, 0, 0)
					KeybindText.BorderSizePixel = 0
					KeybindText.Position = UDim2.new(0.5, 0, 0.5, 0)
					KeybindText.Size = UDim2.new(1, 0, 0.649999976, 0)
					KeybindText.ZIndex = 20
					KeybindText.Font = Enum.Font.GothamBold
					KeybindText.Text = FormatKeybindValue(CurrentBind)
					KeybindText.TextColor3 = Color3.fromRGB(255, 255, 255)
					KeybindText.TextScaled = true
					KeybindText.TextSize = 14.000
					KeybindText.TextTransparency = 0.500
					KeybindText.TextWrapped = true

					KeybindButton.Name = "Button"
					KeybindButton.Parent = KeybindFrame
					KeybindButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					KeybindButton.BackgroundTransparency = 1.000
					KeybindButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
					KeybindButton.BorderSizePixel = 0
					KeybindButton.Size = UDim2.new(1, 0, 1, 0)
					KeybindButton.ZIndex = 21
					KeybindButton.Font = Enum.Font.SourceSans
					KeybindButton.Text = ""
					KeybindButton.TextColor3 = Color3.fromRGB(0, 0, 0)
					KeybindButton.TextSize = 14.000
					KeybindButton.TextTransparency = 1.000

					if bindCfg.Tooltip ~= nil and bindCfg.Tooltip ~= "" then
						TooltipManager:Attach(KeybindButton, bindCfg.Tooltip)
					end

					local ApplyBind
					local function UpdateBindDisplay(new)
						if new == "..." then
							KeybindText.Text = "..."
							local size = TextServ:GetTextSize(
								KeybindText.Text,
								KeybindText.TextSize,
								KeybindText.Font,
								Vector2.new(math.huge, math.huge)
							)

							Twen:Create(KeybindFrame, TweenInfo.new(0.2), {
								Size = UDim2.new(0, math.clamp(size.X + 12, 48, 92), 0.600000024, 0),
							}):Play()
							return
						end

						local nextBind = ResolveKeybindValue(new, CurrentBind)
						if nextBind == CurrentBind and KeybindText.Text == FormatKeybindValue(CurrentBind) then
							return false
						end

						CurrentBind = nextBind
						KeybindText.Text = FormatKeybindValue(CurrentBind)

						local size = TextServ:GetTextSize(
							KeybindText.Text,
							KeybindText.TextSize,
							KeybindText.Font,
							Vector2.new(math.huge, math.huge)
						)

						Twen:Create(KeybindFrame, TweenInfo.new(0.2), {
							Size = UDim2.new(0, math.clamp(size.X + 12, 48, 92), 0.600000024, 0),
						}):Play()
						return true
					end

					ApplyBind = function(newValue, silent, force)
						local resolved = ResolveKeybindValue(newValue, CurrentBind)
						if not force and resolved == CurrentBind then
							return false
						end

						local changed = UpdateBindDisplay(resolved)
						if not changed then
							if BindActiveFlag then
								ConfigManager:Update(BindActiveFlag, CurrentBind)
							end
							return false
						end

						if BindActiveFlag then
							ConfigManager:Update(BindActiveFlag, CurrentBind)
						end

						if not silent and type(bindCfg.Callback) == "function" and not Dispatching then
							Dispatching = true
							bindCfg.Callback(CurrentBind)
							Dispatching = false
						end

						return true
					end

					UpdateToggleTitleWidth(true)
					UpdateBindDisplay(CurrentBind)

					KeybindFrame.MouseEnter:Connect(function()
						Twen:Create(KeybindText, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
							TextTransparency = 0.1,
						}):Play()
					end)

					KeybindFrame.MouseLeave:Connect(function()
						if not Capturing then
							Twen:Create(KeybindText, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
								TextTransparency = 0.500,
							}):Play()
						end
					end)

					KeybindButton.MouseButton1Click:Connect(function()
						if Capturing then
							return
						end

						Capturing = true
						Twen:Create(KeybindText, TweenInfo.new(0.1), {
							TextTransparency = 0,
						}):Play()

						local Signal = Input.InputBegan:Connect(function(key)
							if key.KeyCode and key.KeyCode ~= Enum.KeyCode.Unknown then
								BindEvent:Fire(key.KeyCode)
							end
						end)

						UpdateBindDisplay("...")

						local Bind = BindEvent.Event:Wait()
						Signal:Disconnect()
						ApplyBind(Bind, false, true)
						Twen:Create(KeybindText, TweenInfo.new(0.1), {
							TextTransparency = 0.500,
						}):Play()

						Capturing = false
					end)

					AttachedKeybind = {
						Flag = bindCfg.Flag,
						Root = KeybindFrame,
						GetValue = function()
							return CurrentBind
						end,
						SetValue = function(first, second, third)
							local value, silent = NormalizeMethodArgs(AttachedKeybind, first, second, third)
							ApplyBind(value, silent)
						end,
						Value = function(first, second, third)
							local value, silent = NormalizeMethodArgs(AttachedKeybind, first, second, third)
							ApplyBind(value, silent)
						end,
						Visible = function(newindx)
							KeybindFrame.Visible = newindx
						end,
						Destroy = function()
							if BindActiveFlag then
								ConfigManager:Unregister(BindActiveFlag, AttachedKeybind)
							end
							AttachedKeybind.Destroyed = true
							KeybindFrame:Destroy()
							AttachedKeybind = nil
							UpdateToggleTitleWidth(false)
						end,
					}

					if bindCfg.Flag then
						ConfigManager:Register(bindCfg.Flag, AttachedKeybind)
						BindActiveFlag = AttachedKeybind.Flag
					end

					return AttachedKeybind
				end

				local Dispatching = false
				local CurrentValue = toggle.Default == true

				local function ApplyValue(value, silent, force)
					local nextValue = value == true
					if not force and nextValue == CurrentValue then
						return false
					end

					CurrentValue = nextValue
					toggle.Default = nextValue
					if Registered and ActiveFlag then
						ConfigManager:Update(ActiveFlag, nextValue)
					end
					if nextValue then

						Twen:Create(TextInt,TweenInfo.new(0.15,Enum.EasingStyle.Quint),{
							TextTransparency = 0.02
						}):Play()

						Twen:Create(Icon,TweenInfo.new(0.15,Enum.EasingStyle.Quint),{
							Position = UDim2.new(0.75, 0, 0.5, 0),
							BackgroundTransparency = 0.4
						}):Play()
					else
						Twen:Create(Icon,TweenInfo.new(0.15,Enum.EasingStyle.Quint),{
							Position = UDim2.new(0.25, 0, 0.5, 0),
							BackgroundTransparency = 0.500
						}):Play()

						Twen:Create(TextInt,TweenInfo.new(0.15,Enum.EasingStyle.Quint),{
							TextTransparency = 0.25
						}):Play()
					end;

					if not silent and type(toggle.Callback) == "function" and not Dispatching then
						Dispatching = true
						toggle.Callback(nextValue)
						Dispatching = false
					end

					return true
				end;

				ApplyValue(toggle.Default, true, true);

				Button.MouseButton1Click:Connect(function()
					ApplyValue(not CurrentValue, false)
				end)

				local ToggleObject = {
					Flag = toggle.Flag,
					Root = FunctionToggle,
					GetValue = function()
						return CurrentValue == true
					end,
					SetValue = function(first, second, third)
						local value, silent = NormalizeMethodArgs(ToggleObject, first, second, third)
						ApplyValue(value == true, silent)
					end,
					Value = function(first, second, third)
						local value, silent = NormalizeMethodArgs(ToggleObject, first, second, third)
						ApplyValue(value == true, silent)
					end,
					Visible = function(newindx)
						SearchManager:SetObjectVisible(ToggleObject, newindx)
					end,
					NewKeybind = function(first, second)
						local bindCfg = first == ToggleObject and second or first
						local handle = CreateAttachedKeybind(bindCfg)
						return handle
					end,
					Destroy = function()
						if ActiveFlag then
							ConfigManager:Unregister(ActiveFlag, ToggleObject)
						end
						ToggleObject.Destroyed = true
						FunctionToggle:Destroy()
					end,
				}

				RegisterSearchableControl(ToggleObject, FunctionToggle, toggle.Title, nil, toggle.Tooltip, Button, SectionTable)

				if toggle.Flag then
					ConfigManager:Register(toggle.Flag, ToggleObject)
					ActiveFlag = ToggleObject.Flag
				end
				Registered = true

				return ToggleObject
			end;

			function SectionTable:NewTitle(lrm)
				local TitleTooltip = nil
				if type(lrm) == "table" then
					TitleTooltip = lrm.Tooltip
					lrm = lrm.Title or lrm.Text or ""
				end
				local FunctionTitle = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local UICorner = Instance.new("UICorner")


				FunctionTitle.Name = "FunctionTitle"
				FunctionTitle.Parent = Section
				FunctionTitle.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionTitle.BackgroundTransparency = 0.800
				FunctionTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionTitle.BorderSizePixel = 0
				FunctionTitle.Active = true
				FunctionTitle.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionTitle.ZIndex = 17

				UIAspectRatioConstraint.Parent = FunctionTitle
				UIAspectRatioConstraint.AspectRatio = 8.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionTitle
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.5, 0)
				TextInt.Size = UDim2.new(0.949999988, 0, 0.600000024, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = lrm
				TextInt.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.TextScaled = true
				TextInt.TextSize = 14.000
				TextInt.TextTransparency = 1
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left
				Twen:Create(TextInt,TweenInfo1,{TextTransparency = 0.25}):Play();

				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				UICorner.CornerRadius = UDim.new(0, 2)
				UICorner.Parent = FunctionTitle
				local TitleObject = {
					Root = FunctionTitle,
					Visible = function(newindx)
						SearchManager:SetObjectVisible(TitleObject, newindx)
					end,
					Set = function(a)
						TextInt.Text = a
						SearchManager:UpdateControlText(TitleObject, a, nil)
					end,
				}

				RegisterSearchableControl(TitleObject, FunctionTitle, lrm, nil, TitleTooltip, FunctionTitle, SectionTable)

				return TitleObject;
			end;

			function SectionTable:NewButton(cfg)
				cfg = Config(cfg,{
					Title = "Button",
					Callback = function() end;
				});

				local FunctionButton = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local UICorner = Instance.new("UICorner")
				local DropShadow = Instance.new("ImageLabel")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local Button = Instance.new("TextButton")
				local UIStroke = Instance.new("UIStroke")

				FunctionButton.Name = "FunctionButton"
				FunctionButton.Parent = Section
				FunctionButton.BackgroundColor3 = Color3.fromRGB(71, 71, 71)
				FunctionButton.BackgroundTransparency = 1
				FunctionButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionButton.BorderSizePixel = 0
				FunctionButton.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionButton.ZIndex = 17
				Twen:Create(FunctionButton,TweenInfo1,{
					BackgroundTransparency = 0.750,
					Size = UDim2.new(0.949999988, 0, 0.5, 0)
				}):Play();

				UIAspectRatioConstraint.Parent = FunctionButton
				UIAspectRatioConstraint.AspectRatio = 7.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				Twen:Create(UIAspectRatioConstraint,TweenInfo1,{
					AspectRatio = 7.65
				}):Play();

				UICorner.CornerRadius = UDim.new(0, 2)
				UICorner.Parent = FunctionButton

				DropShadow.Name = "DropShadow"
				DropShadow.Parent = FunctionButton
				DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
				DropShadow.BackgroundTransparency = 1.000
				DropShadow.BorderSizePixel = 0
				DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
				DropShadow.Size = UDim2.new(1, 20, 1, 20)
				DropShadow.ZIndex = 16
				DropShadow.Image = "rbxassetid://6015897843"
				DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
				DropShadow.ImageTransparency = 0.600
				DropShadow.ScaleType = Enum.ScaleType.Slice
				DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionButton
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.5, 0)
				TextInt.Size = UDim2.new(1, 0, 0.479999989, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = cfg.Title
				TextInt.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.TextScaled = true
				TextInt.TextSize = 14.000
				TextInt.TextWrapped = true
				TextInt.TextTransparency = 0.25;

				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				Button.Name = "Button"
				Button.Parent = FunctionButton
				Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Button.BackgroundTransparency = 1.000
				Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Button.BorderSizePixel = 0
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.ZIndex = 15
				Button.Font = Enum.Font.SourceSans
				Button.Text = ""
				Button.TextColor3 = Color3.fromRGB(0, 0, 0)
				Button.TextSize = 14.000
				Button.TextTransparency = 1.000

			UIStroke.Transparency = 0.920
			UIStroke.Color = Color3.fromRGB(255, 255, 255)
			UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			UIStroke.Parent = FunctionButton
			ThemeManager:BindAccentStroke(UIStroke)

				Button.MouseEnter:Connect(function()
					Twen:Create(DropShadow,TweenInfo.new(0.2),{
						ImageTransparency = 0.35
					}):Play()

					Twen:Create(TextInt,TweenInfo.new(0.2),{
						TextTransparency = 0
					}):Play()
				end)

				Button.MouseLeave:Connect(function()
					Twen:Create(DropShadow,TweenInfo.new(0.2),{
						ImageTransparency = 0.600
					}):Play()

					Twen:Create(TextInt,TweenInfo.new(0.2),{
						TextTransparency = 0.25
					}):Play()
				end)

				Button.MouseButton1Click:Connect(function()
					task.spawn(cfg.Callback);
				end)

				local ButtonObject = {
					Root = FunctionButton,
					Visible = function(newindx)
						SearchManager:SetObjectVisible(ButtonObject, newindx)
					end,
					Fire = cfg.Callback,
				}

				RegisterSearchableControl(ButtonObject, FunctionButton, cfg.Title, nil, cfg.Tooltip, Button, SectionTable)

				return ButtonObject;
			end;

			function SectionTable:NewKeybind(ctfx)
				ctfx = Config(ctfx,{
					Title = "Keybind",
					Callback = function() end,
					Default = Enum.KeyCode.E,

				});
				ctfx.Flag = ctfx.Flag and tostring(ctfx.Flag) or nil
				ctfx.Default = ResolveKeybindValue(ctfx.Default, Enum.KeyCode.E)
				local ActiveFlag = ctfx.Flag
				local Registered = false

					local BindEvent = Instance.new('BindableEvent',Section);
					local FunctionKeybind = Instance.new("Frame")
					local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
					local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local Button = Instance.new("TextButton")
				local UIStroke = Instance.new("UIStroke")
				local System = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")
					local Bindkey = Instance.new("TextLabel")
					local UICorner_2 = Instance.new("UICorner")
					local Dispatching = false
					local CurrentBind = ctfx.Default
					local KeybindObject
					local ApplyBind
					BindEvent.Name = tostring(ctfx.Title)
				FunctionKeybind.Name = "FunctionKeybind"
				FunctionKeybind.Parent = Section
				FunctionKeybind.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionKeybind.BackgroundTransparency = 0.800
				FunctionKeybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionKeybind.BorderSizePixel = 0
				FunctionKeybind.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionKeybind.ZIndex = 17

				UIAspectRatioConstraint.Parent = FunctionKeybind
				UIAspectRatioConstraint.AspectRatio = 8.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionKeybind
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.5, 0)
				TextInt.Size = UDim2.new(0.949999988, 0, 0.479999989, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = ctfx.Title
				TextInt.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.TextScaled = true
				TextInt.TextSize = 14.000
				TextInt.TextTransparency = 0.250
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left

				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				Button.Name = "Button"
				Button.Parent = FunctionKeybind
				Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Button.BackgroundTransparency = 1.000
				Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Button.BorderSizePixel = 0
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.ZIndex = 15
				Button.Font = Enum.Font.SourceSans
				Button.Text = ""
				Button.TextColor3 = Color3.fromRGB(0, 0, 0)
				Button.TextSize = 14.000
				Button.TextTransparency = 1.000

			UIStroke.Transparency = 0.950
			UIStroke.Color = Color3.fromRGB(255, 255, 255)
			UIStroke.Parent = FunctionKeybind
			ThemeManager:BindAccentStroke(UIStroke)

				System.Name = "System"
				System.Parent = FunctionKeybind
				System.AnchorPoint = Vector2.new(1, 0.5)
				System.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				System.BackgroundTransparency = 1.000
				System.BorderColor3 = Color3.fromRGB(0, 0, 0)
				System.BorderSizePixel = 0
				System.Position = UDim2.new(0.975000024, 0, 0.5, 0)
				System.Size = UDim2.new(0, 50, 0.600000024, 0)
				System.ZIndex = 18

				UICorner.CornerRadius = UDim.new(0.349999994, 0)
				UICorner.Parent = System

			UIStroke_2.Transparency = 0.950
			UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
			UIStroke_2.Parent = System
			ThemeManager:BindAccentStroke(UIStroke_2)

				Bindkey.Name = "Bindkey"
				Bindkey.Parent = System
				Bindkey.AnchorPoint = Vector2.new(0.5, 0.5)
				Bindkey.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Bindkey.BackgroundTransparency = 1.000
				Bindkey.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Bindkey.BorderSizePixel = 0
				Bindkey.Position = UDim2.new(0.5, 0, 0.5, 0)
				Bindkey.Size = UDim2.new(1, 0, 0.649999976, 0)
				Bindkey.Font = Enum.Font.GothamBold
				Bindkey.Text = FormatKeybindValue(ctfx.Default)
				Bindkey.TextColor3 = Color3.fromRGB(255, 255, 255)
				Bindkey.TextScaled = true
				Bindkey.TextSize = 14.000
				Bindkey.TextTransparency = 0.500
				Bindkey.TextWrapped = true

				UICorner_2.CornerRadius = UDim.new(0, 2)
				UICorner_2.Parent = FunctionKeybind

					local IsWIP = false
					local function UpdateUI(new)
						if new == "..." then
							Bindkey.Text = "..."
							local size = TextServ:GetTextSize(Bindkey.Text, Bindkey.TextSize, Bindkey.Font, Vector2.new(math.huge, math.huge))
							Twen:Create(System, TweenInfo.new(0.2), {
								Size = UDim2.new(0, size.X + 2, 0.600000024, 0),
							}):Play()
							return true
						end

						local nextBind = ResolveKeybindValue(new, CurrentBind)
						if nextBind == CurrentBind and Bindkey.Text == FormatKeybindValue(CurrentBind) then
							return false
						end

						CurrentBind = nextBind
						ctfx.Default = CurrentBind
						Bindkey.Text = FormatKeybindValue(CurrentBind)
						if Registered and ActiveFlag then
							ConfigManager:Update(ActiveFlag, CurrentBind)
						end

						local size = TextServ:GetTextSize(Bindkey.Text, Bindkey.TextSize, Bindkey.Font, Vector2.new(math.huge, math.huge))
						Twen:Create(System, TweenInfo.new(0.2), {
							Size = UDim2.new(0, size.X + 2, 0.600000024, 0),
						}):Play()
						return true
					end

					ApplyBind = function(newValue, silent, force)
						local resolved = ResolveKeybindValue(newValue, CurrentBind)
						local valueChanged = resolved ~= CurrentBind
						if not force and not valueChanged then
							return false
						end

						local changed = UpdateUI(resolved)
						if not changed then
							if Registered and ActiveFlag then
								ConfigManager:Update(ActiveFlag, CurrentBind)
							end
							return false
						end

						if not silent and valueChanged and type(ctfx.Callback) == "function" and not Dispatching then
							Dispatching = true
							ctfx.Callback(CurrentBind)
							Dispatching = false
						end

						return true
					end

					UpdateUI(CurrentBind)

					Button.MouseButton1Click:Connect(function()
						if IsWIP then return end;

						IsWIP = true;


					Twen:Create(TextInt,TweenInfo.new(0.1),{
						TextTransparency = 0
					}):Play();

					local Signal = Input.InputBegan:Connect(function(key)
						if key.KeyCode then
							if key.KeyCode ~= Enum.KeyCode.Unknown then
								BindEvent:Fire(key.KeyCode);
							end;
						end;
					end)

						UpdateUI('...')
						local Bind = BindEvent.Event:Wait();
						Twen:Create(TextInt,TweenInfo.new(0.1),{
							TextTransparency = 0.250
						}):Play();
						Signal:Disconnect()
						ApplyBind(Bind, false, true)

						IsWIP = false;
					end)

					KeybindObject = {
						Flag = ctfx.Flag,
						Root = FunctionKeybind,
						GetValue = function()
							return CurrentBind
						end,
						SetValue = function(first, second, third)
							local value, silent = NormalizeMethodArgs(KeybindObject, first, second, third)
							ApplyBind(value, silent)
						end,
						Visible = function(newindx)
							SearchManager:SetObjectVisible(KeybindObject, newindx)
						end,
						Value = function(first, second, third)
							local value, silent = NormalizeMethodArgs(KeybindObject, first, second, third)
							ApplyBind(value, silent)
						end,
						Destroy = function()
							if ActiveFlag then
								ConfigManager:Unregister(ActiveFlag, KeybindObject)
							end
							KeybindObject.Destroyed = true
							FunctionKeybind:Destroy()
						end,
					}

					RegisterSearchableControl(KeybindObject, FunctionKeybind, ctfx.Title, nil, ctfx.Tooltip, KeybindButton, SectionTable)

				if ctfx.Flag then
					ConfigManager:Register(ctfx.Flag, KeybindObject)
					ActiveFlag = KeybindObject.Flag
				end
				Registered = true

				return KeybindObject
			end;

			function SectionTable:NewSlider(slider)
				slider = Config(slider,{
					Title = "Slider",
					Min = 0,
					Max = 100,
					Default = 50,
					Callback = function()

					end,
				});
				slider.Flag = slider.Flag and tostring(slider.Flag) or nil
				slider.Default = math.clamp(tonumber(slider.Default) or slider.Min, slider.Min, slider.Max)
				local ActiveFlag = slider.Flag

				local FunctionSlider = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local UIStroke = Instance.new("UIStroke")
				local UICorner = Instance.new("UICorner")
				local ValueText = Instance.new("TextLabel")
				local UIGradient_2 = Instance.new("UIGradient")
				local MFrame = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local TFrame = Instance.new("Frame")
				local UICorner_3 = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")

				FunctionSlider.Name = "FunctionSlider"
				FunctionSlider.Parent = Section
				FunctionSlider.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionSlider.BackgroundTransparency = 0.800
				FunctionSlider.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionSlider.BorderSizePixel = 0
				FunctionSlider.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionSlider.ZIndex = 17

				UIAspectRatioConstraint.Parent = FunctionSlider
				UIAspectRatioConstraint.AspectRatio = 6.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionSlider
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.25999999, 0)
				TextInt.Size = UDim2.new(0.949999988, 0, 0.379999995, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = slider.Title
				TextInt.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.TextScaled = true
				TextInt.TextSize = 14.000
				TextInt.TextTransparency = 0.250
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left

				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				UIStroke.Transparency = 0.950
				UIStroke.Color = Color3.fromRGB(255, 255, 255)
				UIStroke.Parent = FunctionSlider

				UICorner.CornerRadius = UDim.new(0, 2)
				UICorner.Parent = FunctionSlider

				ValueText.Name = "ValueText"
				ValueText.Parent = FunctionSlider
				ValueText.AnchorPoint = Vector2.new(0.5, 0.5)
				ValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ValueText.BackgroundTransparency = 1.000
				ValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				ValueText.BorderSizePixel = 0
				ValueText.Position = UDim2.new(0.5, 0, 0.25999999, 0)
				ValueText.Size = UDim2.new(0.949999988, 0, 0.349999994, 0)
				ValueText.ZIndex = 18
				ValueText.Font = Enum.Font.GothamBold
				ValueText.Text = tostring(slider.Default)..'/'..tostring(slider.Max)
				ValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
				ValueText.TextScaled = true
				ValueText.TextSize = 14.000
				ValueText.TextTransparency = 0.500
				ValueText.TextWrapped = true
				ValueText.TextXAlignment = Enum.TextXAlignment.Right

				UIGradient_2.Rotation = 90
				UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient_2.Parent = ValueText

				MFrame.Name = "MFrame"
				MFrame.Parent = FunctionSlider
				MFrame.AnchorPoint = Vector2.new(0.5, 0.5)
				MFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				MFrame.BackgroundTransparency = 0.800
				MFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				MFrame.BorderSizePixel = 0
				MFrame.ClipsDescendants = true
				MFrame.Position = UDim2.new(0.5, 0, 0.75, 0)
				MFrame.Size = UDim2.new(0.949999988, 0, 0.289999992, 0)
				MFrame.ZIndex = 18

				UICorner_2.CornerRadius = UDim.new(0, 2)
				UICorner_2.Parent = MFrame

				TFrame.Name = "TFrame"
				TFrame.Parent = MFrame
				TFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TFrame.BackgroundTransparency = 0.500
				TFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TFrame.BorderSizePixel = 0
			TFrame.Size = UDim2.new((slider.Default / slider.Max), 0, 1, 0)
			TFrame.ZIndex = 17
			ThemeManager:BindAccent(TFrame, "BackgroundColor3")

				UICorner_3.CornerRadius = UDim.new(0, 2)
				UICorner_3.Parent = TFrame

				UIStroke_2.Transparency = 0.975
				UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
				UIStroke_2.Parent = MFrame
				ThemeManager:BindAccentStroke(UIStroke_2)

				local Holding = false
				local Dispatching = false
				local CurrentValue = slider.Default
				local SliderObject

				local function ApplyValue(value, silent, force)
					local Value = math.clamp(math.round(tonumber(value) or CurrentValue), slider.Min, slider.Max)
					if not force and Value == CurrentValue then
						return false
					end

					CurrentValue = Value
					slider.Default = Value
					local SizeScale = (slider.Max == slider.Min) and 1 or ((Value - slider.Min) / (slider.Max - slider.Min))
					ValueText.Text = tostring(Value)..'/'..tostring(slider.Max)
					Twen:Create(TFrame,TweenInfo.new(0.1),{Size = UDim2.fromScale(SizeScale, 1)}):Play()
					if ActiveFlag then
						ConfigManager:Update(ActiveFlag, Value)
					end
					if not silent and type(slider.Callback) == "function" and not Dispatching then
						Dispatching = true
						slider.Callback(Value)
						Dispatching = false
					end
					return true
				end

				local function update(Input)
					local SizeScale = math.clamp((((Input.Position.X) - MFrame.AbsolutePosition.X) / MFrame.AbsoluteSize.X), 0, 1)
					local Main = ((slider.Max - slider.Min) * SizeScale) + slider.Min;
					local Value = math.round(Main)
					ApplyValue(Value, false)
				end

				MFrame.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						Holding = true
						update(Input)
						Twen:Create(TextInt,TweenInfo.new(0.1),{
							TextTransparency = 0
						}):Play()
					end
				end)

				MFrame.InputEnded:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						Holding = false
						Twen:Create(TextInt,TweenInfo.new(0.1),{
							TextTransparency = 0.3
						}):Play()
					end
				end)

				Input.InputChanged:Connect(function(Input)
					if Holding then
						if (Input.UserInputType==Enum.UserInputType.MouseMovement or Input.UserInputType==Enum.UserInputType.Touch)  then
							update(Input)
						end
					end
				end)

				SliderObject = {
					Flag = slider.Flag,
					Root = FunctionSlider,
					GetValue = function()
						return CurrentValue
					end,
					SetValue = function(first, second, third)
						local value, silent = NormalizeMethodArgs(SliderObject, first, second, third)
						ApplyValue(value, silent)
					end,
					Visible = function(newindx)
						SearchManager:SetObjectVisible(SliderObject, newindx)
					end,
					Value = function(first, second, third)
						local value, silent = NormalizeMethodArgs(SliderObject, first, second, third)
						ApplyValue(value, silent)
					end,
					Destroy = function()
						if ActiveFlag then
							ConfigManager:Unregister(ActiveFlag, SliderObject)
						end
						SliderObject.Destroyed = true
						FunctionSlider:Destroy()
					end,
				}

				RegisterSearchableControl(SliderObject, FunctionSlider, slider.Title, nil, slider.Tooltip, MFrame, SectionTable)

				if slider.Flag then
					ConfigManager:Register(slider.Flag, SliderObject)
					ActiveFlag = SliderObject.Flag
				end

				return SliderObject
			end;

			function SectionTable:NewDropdown(drop)
				drop = Config(drop,{
					Title = "Dropdown",
					Data = {'One','Two','Three','Four'},
					Default = 'Two',
					Multi = false,
					Callback = function(a)

					end,
				});

				drop.Multi = drop.Multi == true
				drop.Flag = drop.Flag and tostring(drop.Flag) or nil
				drop.Default = NormalizeDropdownValue(drop.Data, drop.Default, drop.Multi)
				local ActiveFlag = drop.Flag

				local FunctionDropdown = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local UIStroke = Instance.new("UIStroke")
				local UICorner = Instance.new("UICorner")
				local MFrame = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")
				local ValueText = Instance.new("TextLabel")
				local UIGradient_2 = Instance.new("UIGradient")
				local Button = Instance.new("TextButton")

				FunctionDropdown.Name = "FunctionDropdown"
				FunctionDropdown.Parent = Section
				FunctionDropdown.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionDropdown.BackgroundTransparency = 0.800
				FunctionDropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionDropdown.BorderSizePixel = 0
				FunctionDropdown.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionDropdown.ZIndex = 17

				UIAspectRatioConstraint.Parent = FunctionDropdown
				UIAspectRatioConstraint.AspectRatio = 5.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionDropdown
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.200000003, 0)
				TextInt.Size = UDim2.new(0.949999988, 0, 0.319999993, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = drop.Title
				TextInt.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.TextScaled = true
				TextInt.TextSize = 14.000
				TextInt.TextTransparency = 0.250
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left

				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				UIStroke.Transparency = 0.950
				UIStroke.Color = Color3.fromRGB(255, 255, 255)
				UIStroke.Parent = FunctionDropdown

				UICorner.CornerRadius = UDim.new(0, 2)
				UICorner.Parent = FunctionDropdown

				MFrame.Name = "MFrame"
				MFrame.Parent = FunctionDropdown
				MFrame.AnchorPoint = Vector2.new(0.5, 0.5)
				MFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				MFrame.BackgroundTransparency = 0.800
				MFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				MFrame.BorderSizePixel = 0
				MFrame.ClipsDescendants = true
				MFrame.Position = UDim2.new(0.5, 0, 0.699999988, 0)
				MFrame.Size = UDim2.new(0.949999988, 0, 0.375, 0)
				MFrame.ZIndex = 18

				UICorner_2.CornerRadius = UDim.new(0, 2)
				UICorner_2.Parent = MFrame

				UIStroke_2.Transparency = 0.975
				UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
				UIStroke_2.Parent = MFrame

				ValueText.Name = "ValueText"
				ValueText.Parent = MFrame
				ValueText.AnchorPoint = Vector2.new(0.5, 0.5)
				ValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ValueText.BackgroundTransparency = 1.000
				ValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				ValueText.BorderSizePixel = 0
				ValueText.Position = UDim2.new(0.5, 0, 0.5, 0)
				ValueText.Size = UDim2.new(1, 0, 0.800000012, 0)
				ValueText.ZIndex = 18
				ValueText.Font = Enum.Font.GothamBold
				ValueText.Text = FormatDropdownValue(drop.Data, drop.Default, drop.Multi)
				ValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
				ValueText.TextScaled = true
				ValueText.TextSize = 14.000
				ValueText.TextTransparency = 0.500
				ValueText.TextWrapped = true
				ValueText.TextXAlignment = Enum.TextXAlignment.Left

				MFrame.MouseEnter:Connect(function()
					Twen:Create(ValueText,TweenInfo.new(0.3),{
						TextTransparency = 0.1
					}):Play()
				end)

				MFrame.MouseLeave:Connect(function()
					Twen:Create(ValueText,TweenInfo.new(0.3),{
						TextTransparency = 0.500
					}):Play()
				end)

				UIGradient_2.Rotation = 90
				UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient_2.Parent = ValueText

				Button.Name = "Button"
				Button.Parent = FunctionDropdown
				Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Button.BackgroundTransparency = 1.000
				Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Button.BorderSizePixel = 0
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.ZIndex = 25
				Button.Font = Enum.Font.SourceSans
				Button.Text = ""
				Button.TextColor3 = Color3.fromRGB(0, 0, 0)
				Button.TextSize = 14.000
				Button.TextTransparency = 1.000

				local Dispatching = false
				local CurrentValue = drop.Default
				local DropdownObject
				local Updater

				local function ApplyValue(value, silent, force)
					local nextValue = NormalizeDropdownValue(drop.Data, value, drop.Multi)
					if not force and DeepEqual(nextValue, CurrentValue) then
						return false
					end

					CurrentValue = nextValue
					drop.Default = nextValue
					ValueText.Text = FormatDropdownValue(drop.Data, nextValue, drop.Multi)
					if ConfigManager.LoadingConfig and WindowTable.Dropdown.IsOpenFor and WindowTable.Dropdown:IsOpenFor(MFrame) then
						WindowTable.Dropdown:Open(drop.Data, nextValue, Updater, drop.Multi)
					end
					if ActiveFlag then
						ConfigManager:Update(ActiveFlag, nextValue)
					end
					if not silent and type(drop.Callback) == "function" and not Dispatching then
						Dispatching = true
						drop.Callback(nextValue)
						Dispatching = false
					end
					return true
				end

				Updater = function(value)
					ApplyValue(value)
				end

				Button.MouseButton1Click:Connect(function()
					if type(drop.BeforeOpen) == "function" then
						local ok, refreshed = pcall(drop.BeforeOpen)
						if ok and type(refreshed) == "table" then
							drop.Data = refreshed
							ApplyValue(CurrentValue, true, true)
						end
					end

					WindowTable.Dropdown:Setup(MFrame)

					WindowTable.Dropdown:Open(drop.Data,CurrentValue,Updater,drop.Multi)
				end)

				DropdownObject = {
					Flag = drop.Flag,
					Root = FunctionDropdown,
					GetValue = function()
						return CurrentValue
					end,
					SetValue = function(first, second, third)
						local value, silent = NormalizeMethodArgs(DropdownObject, first, second, third)
						ApplyValue(value, silent)
					end,
					Visible = function(newindx)
						SearchManager:SetObjectVisible(DropdownObject, newindx)
					end,
					Value = function(first, second, third)
						local value, silent = NormalizeMethodArgs(DropdownObject, first, second, third)
						ApplyValue(value, silent)
					end,
					Open = function(value)
						if type(drop.BeforeOpen) == "function" then
							local ok, refreshed = pcall(drop.BeforeOpen)
							if ok and type(refreshed) == "table" then
								drop.Data = refreshed
								ApplyValue(CurrentValue, true, true)
							end
						end

						WindowTable.Dropdown:Setup(MFrame)

						WindowTable.Dropdown:Open(drop.Data,CurrentValue,Updater,drop.Multi)
					end,

					Close = function(value)
						WindowTable.Dropdown:Close();
					end,
					Clear = function()
						drop.Data = {}
						ApplyValue(drop.Multi and {} or nil, true, true)
					end,
					Set = function(first, second)
						local data = first == DropdownObject and second or first
						drop.Data = type(data) == "table" and data or {}
						ApplyValue(CurrentValue, true, true)
					end,
					Destroy = function()
						if drop.Flag then
							ConfigManager:Unregister(drop.Flag, DropdownObject)
						end
						DropdownObject.Destroyed = true
						FunctionDropdown:Destroy()
					end
				}

				RegisterSearchableControl(DropdownObject, FunctionDropdown, drop.Title, nil, drop.Tooltip, MFrame, SectionTable)

				if drop.Flag then
					ConfigManager:Register(drop.Flag, DropdownObject)
					ActiveFlag = DropdownObject.Flag
				end

				return DropdownObject
			end;

			function SectionTable:Divider(text)
				local DividerText = ""
				if type(text) == "table" then
					DividerText = text.Text or text.Title or ""
				elseif text ~= nil then
					DividerText = tostring(text)
				end

				local FunctionDivider = Instance.new("Frame")
				local DividerStroke = Instance.new("UIStroke")
				local DividerCorner = Instance.new("UICorner")

				FunctionDivider.Name = "FunctionDivider"
				FunctionDivider.Parent = Section
				FunctionDivider.BackgroundTransparency = 1
				FunctionDivider.BorderSizePixel = 0
				FunctionDivider.Size = UDim2.new(0.949999988, 0, 0, DividerText ~= "" and 22 or 12)
				FunctionDivider.ZIndex = 17

				DividerStroke.Transparency = 1
				DividerStroke.Color = Color3.fromRGB(255, 255, 255)
				DividerStroke.Parent = FunctionDivider

				DividerCorner.CornerRadius = UDim.new(0, 2)
				DividerCorner.Parent = FunctionDivider

				if DividerText ~= "" then
					local DividerLeft = Instance.new("Frame")
					local DividerRight = Instance.new("Frame")
					local DividerTextLabel = Instance.new("TextLabel")
					local LeftCorner = Instance.new("UICorner")
					local RightCorner = Instance.new("UICorner")
					local TextGradient = Instance.new("UIGradient")

					DividerLeft.Name = "DividerLeft"
					DividerLeft.Parent = FunctionDivider
					DividerLeft.AnchorPoint = Vector2.new(0, 0.5)
					DividerLeft.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					DividerLeft.BackgroundTransparency = 0.800
					DividerLeft.BorderSizePixel = 0
					DividerLeft.Position = UDim2.new(0, 0, 0.5, 0)
					DividerLeft.Size = UDim2.new(0.36, 0, 0, 1)
					DividerLeft.ZIndex = 17

					LeftCorner.CornerRadius = UDim.new(0.5, 0)
					LeftCorner.Parent = DividerLeft

					DividerRight.Name = "DividerRight"
					DividerRight.Parent = FunctionDivider
					DividerRight.AnchorPoint = Vector2.new(1, 0.5)
					DividerRight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					DividerRight.BackgroundTransparency = 0.800
					DividerRight.BorderSizePixel = 0
					DividerRight.Position = UDim2.new(1, 0, 0.5, 0)
					DividerRight.Size = UDim2.new(0.36, 0, 0, 1)
					DividerRight.ZIndex = 17

					RightCorner.CornerRadius = UDim.new(0.5, 0)
					RightCorner.Parent = DividerRight

					DividerTextLabel.Name = "DividerText"
					DividerTextLabel.Parent = FunctionDivider
					DividerTextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
					DividerTextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					DividerTextLabel.BackgroundTransparency = 1
					DividerTextLabel.BorderSizePixel = 0
					DividerTextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
					DividerTextLabel.Size = UDim2.new(0.22, 0, 1, 0)
					DividerTextLabel.ZIndex = 18
					DividerTextLabel.Font = Enum.Font.GothamBold
					DividerTextLabel.Text = DividerText
					DividerTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
					DividerTextLabel.TextScaled = true
					DividerTextLabel.TextSize = 14
					DividerTextLabel.TextTransparency = 0.450
					DividerTextLabel.TextWrapped = true
					DividerTextLabel.TextXAlignment = Enum.TextXAlignment.Center
					DividerTextLabel.TextYAlignment = Enum.TextYAlignment.Center

					TextGradient.Rotation = 90
					TextGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
					TextGradient.Parent = DividerTextLabel
				else
					local DividerLine = Instance.new("Frame")
					local LineCorner = Instance.new("UICorner")

					DividerLine.Name = "DividerLine"
					DividerLine.Parent = FunctionDivider
					DividerLine.AnchorPoint = Vector2.new(0.5, 0.5)
					DividerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					DividerLine.BackgroundTransparency = 0.800
					DividerLine.BorderSizePixel = 0
					DividerLine.Position = UDim2.new(0.5, 0, 0.5, 0)
					DividerLine.Size = UDim2.new(1, 0, 0, 1)
					DividerLine.ZIndex = 17

					LineCorner.CornerRadius = UDim.new(0.5, 0)
					LineCorner.Parent = DividerLine
				end

				return {
					Visible = function(newindx)
						FunctionDivider.Visible = newindx
					end,
					Destroy = function()
						FunctionDivider:Destroy()
					end,
				}
			end

			SectionTable.AddDivider = SectionTable.Divider

			function SectionTable:NewColorpicker(conf)
				conf = Config(conf, {
					Title = "Colorpicker",
					Description = "",
					Icon = "palette",
					Default = Color3.new(1, 1, 1),
					Transparency = 0,
					AllowTransparency = false,
					Callback = function() end,
				})
				conf.Flag = conf.Flag and tostring(conf.Flag) or nil
				conf.AllowTransparency = conf.AllowTransparency == true
				conf.Transparency = math.clamp(tonumber(conf.Transparency) or 0, 0, 1)
				local ActiveFlag = conf.Flag

				local FunctionColorpicker = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				local UIStroke = Instance.new("UIStroke")
				local HeaderButton = Instance.new("TextButton")
				local Icon = Instance.new("ImageLabel")
				local TitleText = Instance.new("TextLabel")
				local DescriptionText = Instance.new("TextLabel")
				local PreviewShell = Instance.new("Frame")
				local PreviewCorner = Instance.new("UICorner")
				local PreviewStroke = Instance.new("UIStroke")
				local PreviewColor = Instance.new("Frame")
				local PreviewColorCorner = Instance.new("UICorner")
				local Arrow = Instance.new("TextLabel")
				local Body = Instance.new("Frame")
				local ColorArea = Instance.new("Frame")
				local ColorCorner = Instance.new("UICorner")
				local ColorStroke = Instance.new("UIStroke")
				local SaturationOverlay = Instance.new("Frame")
				local SaturationGradient = Instance.new("UIGradient")
				local ValueOverlay = Instance.new("Frame")
				local ValueGradient = Instance.new("UIGradient")
				local ColorCursor = Instance.new("Frame")
				local CursorCorner = Instance.new("UICorner")
				local CursorStroke = Instance.new("UIStroke")
				local HueTrack = Instance.new("Frame")
				local HueCorner = Instance.new("UICorner")
				local HueGradient = Instance.new("UIGradient")
				local HueThumb = Instance.new("Frame")
				local HueThumbCorner = Instance.new("UICorner")
				local HueThumbStroke = Instance.new("UIStroke")
				local AlphaTrack = Instance.new("Frame")
				local AlphaCorner = Instance.new("UICorner")
				local AlphaColor = Instance.new("Frame")
				local AlphaGradient = Instance.new("UIGradient")
				local AlphaThumb = Instance.new("Frame")
				local AlphaThumbCorner = Instance.new("UICorner")
				local AlphaThumbStroke = Instance.new("UIStroke")
				local LargePreview = Instance.new("Frame")
				local LargePreviewCorner = Instance.new("UICorner")
				local LargePreviewStroke = Instance.new("UIStroke")
				local HexBox = Instance.new("TextBox")
				local RBox = Instance.new("TextBox")
				local GBox = Instance.new("TextBox")
				local BBox = Instance.new("TextBox")
				local ABox = Instance.new("TextBox")
				local ColorpickerObject

				local CollapsedHeight = 42
				local ExpandedHeight = conf.AllowTransparency and 300 or 274
				local TextUpdating = false
				local Dispatching = false
				local Expanded = false
				local DraggingColor = false
				local DraggingHue = false
				local DraggingAlpha = false
				local Current = {
					H = 0,
					S = 0,
					V = 1,
					Transparency = conf.Transparency,
				}

				local function RGBToHex(r, g, b)
					return ("#%02X%02X%02X"):format(math.clamp(math.floor(r + 0.5), 0, 255), math.clamp(math.floor(g + 0.5), 0, 255), math.clamp(math.floor(b + 0.5), 0, 255))
				end

				local function ColorToRGB(color)
					return math.clamp(math.floor(color.R * 255 + 0.5), 0, 255), math.clamp(math.floor(color.G * 255 + 0.5), 0, 255), math.clamp(math.floor(color.B * 255 + 0.5), 0, 255)
				end

				local function FromRGBSafe(r, g, b)
					return Color3.fromRGB(math.clamp(tonumber(r) or 0, 0, 255), math.clamp(tonumber(g) or 0, 0, 255), math.clamp(tonumber(b) or 0, 0, 255))
				end

				local function NormalizeHex(text)
					text = tostring(text or ""):gsub("%s+", ""):gsub("#", "")
					if #text == 3 then
						text = text:sub(1, 1):rep(2) .. text:sub(2, 2):rep(2) .. text:sub(3, 3):rep(2)
					end
					if #text ~= 6 or text:find("[^%x]") then
						return nil
					end
					return "#" .. text:upper()
				end

				local function HexToColor3(text)
					local hex = NormalizeHex(text)
					if not hex then
						return nil
					end
					local raw = hex:sub(2)
					return Color3.fromRGB(tonumber(raw:sub(1, 2), 16), tonumber(raw:sub(3, 4), 16), tonumber(raw:sub(5, 6), 16))
				end

				local function ReadColorPayload()
					local color = Color3.fromHSV(Current.H, Current.S, Current.V)
					local r, g, b = ColorToRGB(color)
					return {
						Color3 = color,
						Format = conf.AllowTransparency and "RGBA" or "RGB",
						AllowTransparency = conf.AllowTransparency,
						RGB = {
							R = r,
							G = g,
							B = b,
						},
						HSV = {
							H = Current.H,
							S = Current.S,
							V = Current.V,
						},
						Hex = RGBToHex(r, g, b),
						Transparency = Current.Transparency,
						Alpha = 1 - Current.Transparency,
					}
				end

				local function ResolveColorInput(value, transparency)
					local color = nil
					local nextTransparency = transparency

					if typeof(value) == "Color3" then
						color = value
					elseif type(value) == "string" then
						color = HexToColor3(value)
					elseif type(value) == "table" then
						if typeof(value.Color3) == "Color3" then
							color = value.Color3
						elseif type(value.Hex) == "string" then
							color = HexToColor3(value.Hex)
						end

						if not color and type(value.RGB) == "table" then
							color = FromRGBSafe(tonumber(value.RGB.R) or tonumber(value.RGB[1]) or 255, tonumber(value.RGB.G) or tonumber(value.RGB[2]) or 255, tonumber(value.RGB.B) or tonumber(value.RGB[3]) or 255)
						elseif not color and (value.R or value.G or value.B) then
							color = FromRGBSafe(tonumber(value.R) or 255, tonumber(value.G) or 255, tonumber(value.B) or 255)
						elseif not color and type(value.HSV) == "table" then
							color = Color3.fromHSV(math.clamp(tonumber(value.HSV.H) or 0, 0, 1), math.clamp(tonumber(value.HSV.S) or 0, 0, 1), math.clamp(tonumber(value.HSV.V) or 1, 0, 1))
						end

						if value.Transparency ~= nil then
							nextTransparency = value.Transparency
						elseif value.Alpha ~= nil then
							nextTransparency = 1 - (tonumber(value.Alpha) or 1)
						end
					end

					color = color or Color3.new(1, 1, 1)
					nextTransparency = math.clamp(tonumber(nextTransparency) or Current.Transparency or 0, 0, 1)
					local h, s, v = color:ToHSV()
					return h, s, v, nextTransparency
				end

				local function SetInputText(box, text)
					TextUpdating = true
					box.Text = text
					TextUpdating = false
				end

				local function ApplyVisuals()
					local payload = ReadColorPayload()
					local color = payload.Color3
					ColorArea.BackgroundColor3 = Color3.fromHSV(Current.H, 1, 1)
					PreviewColor.BackgroundColor3 = color
					PreviewColor.BackgroundTransparency = conf.AllowTransparency and Current.Transparency or 0
					LargePreview.BackgroundColor3 = color
					LargePreview.BackgroundTransparency = conf.AllowTransparency and Current.Transparency or 0
					AlphaColor.BackgroundColor3 = color
					ColorCursor.Position = UDim2.fromScale(Current.S, 1 - Current.V)
					HueThumb.Position = UDim2.fromScale(Current.H, 0.5)
					AlphaThumb.Position = UDim2.fromScale(1 - Current.Transparency, 0.5)
					SetInputText(HexBox, payload.Hex)
					SetInputText(RBox, tostring(payload.RGB.R))
					SetInputText(GBox, tostring(payload.RGB.G))
					SetInputText(BBox, tostring(payload.RGB.B))
					SetInputText(ABox, tostring(math.floor(Current.Transparency * 100 + 0.5)))
				end

				local function Changed(h, s, v, transparency)
					return math.abs(Current.H - h) > 0.0005
						or math.abs(Current.S - s) > 0.0005
						or math.abs(Current.V - v) > 0.0005
						or math.abs(Current.Transparency - transparency) > 0.0005
				end

				local function ApplyHSV(h, s, v, transparency, silent, force)
					h = math.clamp(tonumber(h) or Current.H, 0, 1)
					s = math.clamp(tonumber(s) or Current.S, 0, 1)
					v = math.clamp(tonumber(v) or Current.V, 0, 1)
					transparency = conf.AllowTransparency and math.clamp(tonumber(transparency) or Current.Transparency, 0, 1) or 0
					if not force and not Changed(h, s, v, transparency) then
						return false
					end

					Current.H = h
					Current.S = s
					Current.V = v
					Current.Transparency = transparency
					ApplyVisuals()
					local payload = ReadColorPayload()
					if ActiveFlag then
						ConfigManager:Update(ActiveFlag, payload)
					end
					if not silent and type(conf.Callback) == "function" and not Dispatching then
						Dispatching = true
						conf.Callback(payload)
						Dispatching = false
					end
					return true
				end

				local function ApplyValue(value, silent, force)
					local h, s, v, transparency = ResolveColorInput(value, conf.AllowTransparency and Current.Transparency or 0)
					ApplyHSV(h, s, v, transparency, silent, force)
				end

				local function ApplyColor(color, silent)
					local h, s, v = color:ToHSV()
					ApplyHSV(h, s, v, Current.Transparency, silent)
				end

				local function ParseRGBBox()
					local r = math.clamp(tonumber(RBox.Text) or 0, 0, 255)
					local g = math.clamp(tonumber(GBox.Text) or 0, 0, 255)
					local b = math.clamp(tonumber(BBox.Text) or 0, 0, 255)
					ApplyColor(FromRGBSafe(r, g, b), false)
				end

				local function ParseAlphaBox()
					if not conf.AllowTransparency then
						return
					end
					local text = tostring(ABox.Text or ""):gsub("%%", "")
					local value = tonumber(text)
					if not value then
						ApplyVisuals()
						return
					end
					local transparency = value > 1 and (value / 100) or value
					ApplyHSV(Current.H, Current.S, Current.V, transparency, false)
				end

				local function ToggleExpanded(value)
					Expanded = value == nil and not Expanded or value == true
					Arrow.Text = Expanded and "⌃" or "⌄"
					Twen:Create(FunctionColorpicker, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						Size = UDim2.new(0.949999988, 0, 0, Expanded and ExpandedHeight or CollapsedHeight),
					}):Play()
					Twen:Create(Body, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundTransparency = Expanded and 1 or 1,
					}):Play()
				end

				local function UpdateFromColorArea(input)
					local pos = input.Position
					local x = math.clamp((pos.X - ColorArea.AbsolutePosition.X) / math.max(1, ColorArea.AbsoluteSize.X), 0, 1)
					local y = math.clamp((pos.Y - ColorArea.AbsolutePosition.Y) / math.max(1, ColorArea.AbsoluteSize.Y), 0, 1)
					ApplyHSV(Current.H, x, 1 - y, Current.Transparency, false)
				end

				local function UpdateFromHue(input)
					local x = math.clamp((input.Position.X - HueTrack.AbsolutePosition.X) / math.max(1, HueTrack.AbsoluteSize.X), 0, 1)
					ApplyHSV(x, Current.S, Current.V, Current.Transparency, false)
				end

				local function UpdateFromAlpha(input)
					if not conf.AllowTransparency then
						return
					end
					local x = math.clamp((input.Position.X - AlphaTrack.AbsolutePosition.X) / math.max(1, AlphaTrack.AbsoluteSize.X), 0, 1)
					ApplyHSV(Current.H, Current.S, Current.V, 1 - x, false)
				end

				local function MakeInputBox(box, label, position, size)
					box.Name = label .. "Input"
					box.Parent = Body
					box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
					box.BackgroundTransparency = 0.76
					box.BorderSizePixel = 0
					box.Position = position
					box.Size = size
					box.ZIndex = 22
					box.ClearTextOnFocus = false
					box.Font = Enum.Font.GothamBold
					box.TextColor3 = Color3.fromRGB(255, 255, 255)
					box.TextSize = 12
					box.TextTransparency = 0.15
					box.TextWrapped = false
					box.TextXAlignment = Enum.TextXAlignment.Center
					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(0, 3)
					corner.Parent = box
					local stroke = Instance.new("UIStroke")
					stroke.Transparency = 0.92
					stroke.Color = Color3.fromRGB(255, 255, 255)
					stroke.Parent = box
					ThemeManager:BindAccentStroke(stroke)
				end

				FunctionColorpicker.Name = "FunctionColorpicker"
				FunctionColorpicker.Parent = Section
				FunctionColorpicker.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionColorpicker.BackgroundTransparency = 0.8
				FunctionColorpicker.BorderSizePixel = 0
				FunctionColorpicker.ClipsDescendants = true
				FunctionColorpicker.Size = UDim2.new(0.949999988, 0, 0, CollapsedHeight)
				FunctionColorpicker.ZIndex = 17

				UICorner.CornerRadius = UDim.new(0, 3)
				UICorner.Parent = FunctionColorpicker

				UIStroke.Transparency = 0.95
				UIStroke.Color = Color3.fromRGB(255, 255, 255)
				UIStroke.Parent = FunctionColorpicker
				ThemeManager:BindAccentStroke(UIStroke)

				HeaderButton.Name = "HeaderButton"
				HeaderButton.Parent = FunctionColorpicker
				HeaderButton.BackgroundTransparency = 1
				HeaderButton.BorderSizePixel = 0
				HeaderButton.Size = UDim2.new(1, 0, 0, CollapsedHeight)
				HeaderButton.ZIndex = 25
				HeaderButton.Text = ""

				Icon.Name = "Icon"
				Icon.Parent = FunctionColorpicker
				Icon.AnchorPoint = Vector2.new(0, 0.5)
				Icon.BackgroundTransparency = 1
				Icon.Position = UDim2.new(0.035, 0, 0, 21)
				Icon.Size = UDim2.fromOffset(18, 18)
				Icon.ZIndex = 19
				Icon.Image = ResolveIconSource(conf.Icon or "palette")
				Icon.ImageTransparency = 0.25

				TitleText.Name = "TitleText"
				TitleText.Parent = FunctionColorpicker
				TitleText.BackgroundTransparency = 1
				TitleText.Position = UDim2.new(0.12, 0, 0, conf.Description ~= "" and 7 or 11)
				TitleText.Size = UDim2.new(0.58, 0, 0, 14)
				TitleText.ZIndex = 19
				TitleText.Font = Enum.Font.GothamBold
				TitleText.Text = tostring(conf.Title or "Colorpicker")
				TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
				TitleText.TextSize = 13
				TitleText.TextTransparency = 0.2
				TitleText.TextXAlignment = Enum.TextXAlignment.Left

				DescriptionText.Name = "DescriptionText"
				DescriptionText.Parent = FunctionColorpicker
				DescriptionText.BackgroundTransparency = 1
				DescriptionText.Position = UDim2.new(0.12, 0, 0, 23)
				DescriptionText.Size = UDim2.new(0.58, 0, 0, 12)
				DescriptionText.ZIndex = 19
				DescriptionText.Font = Enum.Font.GothamBold
				DescriptionText.Text = tostring(conf.Description or "")
				DescriptionText.TextColor3 = Color3.fromRGB(255, 255, 255)
				DescriptionText.TextSize = 11
				DescriptionText.TextTransparency = 0.55
				DescriptionText.TextXAlignment = Enum.TextXAlignment.Left
				DescriptionText.Visible = conf.Description ~= ""

				PreviewShell.Name = "PreviewShell"
				PreviewShell.Parent = FunctionColorpicker
				PreviewShell.AnchorPoint = Vector2.new(1, 0.5)
				PreviewShell.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				PreviewShell.BackgroundTransparency = 0.45
				PreviewShell.BorderSizePixel = 0
				PreviewShell.Position = UDim2.new(0.86, 0, 0, 21)
				PreviewShell.Size = UDim2.fromOffset(38, 20)
				PreviewShell.ZIndex = 19
				PreviewShell.ClipsDescendants = true
				PreviewCorner.CornerRadius = UDim.new(0, 4)
				PreviewCorner.Parent = PreviewShell
				PreviewStroke.Transparency = 0.82
				PreviewStroke.Parent = PreviewShell
				ThemeManager:BindAccentStroke(PreviewStroke)

				PreviewColor.Name = "PreviewColor"
				PreviewColor.Parent = PreviewShell
				PreviewColor.BorderSizePixel = 0
				PreviewColor.Size = UDim2.fromScale(1, 1)
				PreviewColor.ZIndex = 20
				PreviewColorCorner.CornerRadius = UDim.new(0, 4)
				PreviewColorCorner.Parent = PreviewColor

				Arrow.Name = "Arrow"
				Arrow.Parent = FunctionColorpicker
				Arrow.AnchorPoint = Vector2.new(1, 0.5)
				Arrow.BackgroundTransparency = 1
				Arrow.Position = UDim2.new(0.965, 0, 0, 21)
				Arrow.Size = UDim2.fromOffset(20, 20)
				Arrow.ZIndex = 19
				Arrow.Font = Enum.Font.GothamBold
				Arrow.Text = "⌄"
				Arrow.TextColor3 = Color3.fromRGB(255, 255, 255)
				Arrow.TextSize = 16
				Arrow.TextTransparency = 0.35

				Body.Name = "Body"
				Body.Parent = FunctionColorpicker
				Body.BackgroundTransparency = 1
				Body.BorderSizePixel = 0
				Body.Position = UDim2.new(0.035, 0, 0, 48)
				Body.Size = UDim2.new(0.93, 0, 0, ExpandedHeight - 54)
				Body.ZIndex = 18

				ColorArea.Name = "ColorArea"
				ColorArea.Parent = Body
				ColorArea.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
				ColorArea.BorderSizePixel = 0
				ColorArea.Position = UDim2.new(0, 0, 0, 0)
				ColorArea.Size = UDim2.new(0.58, 0, 0, 118)
				ColorArea.ZIndex = 19
				ColorArea.ClipsDescendants = true
				ColorCorner.CornerRadius = UDim.new(0, 5)
				ColorCorner.Parent = ColorArea
				ColorStroke.Transparency = 0.84
				ColorStroke.Parent = ColorArea
				ThemeManager:BindAccentStroke(ColorStroke)

				SaturationOverlay.Parent = ColorArea
				SaturationOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				SaturationOverlay.BorderSizePixel = 0
				SaturationOverlay.Size = UDim2.fromScale(1, 1)
				SaturationOverlay.ZIndex = 20
				SaturationGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
				SaturationGradient.Parent = SaturationOverlay

				ValueOverlay.Parent = ColorArea
				ValueOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				ValueOverlay.BorderSizePixel = 0
				ValueOverlay.Size = UDim2.fromScale(1, 1)
				ValueOverlay.ZIndex = 21
				ValueGradient.Rotation = 90
				ValueGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
				ValueGradient.Parent = ValueOverlay

				ColorCursor.Parent = ColorArea
				ColorCursor.AnchorPoint = Vector2.new(0.5, 0.5)
				ColorCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ColorCursor.BackgroundTransparency = 0.45
				ColorCursor.BorderSizePixel = 0
				ColorCursor.Size = UDim2.fromOffset(12, 12)
				ColorCursor.ZIndex = 24
				CursorCorner.CornerRadius = UDim.new(1, 0)
				CursorCorner.Parent = ColorCursor
				CursorStroke.Thickness = 1.4
				CursorStroke.Transparency = 0.1
				CursorStroke.Parent = ColorCursor

				LargePreview.Parent = Body
				LargePreview.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				LargePreview.BorderSizePixel = 0
				LargePreview.Position = UDim2.new(0.62, 0, 0, 0)
				LargePreview.Size = UDim2.new(0.38, 0, 0, 38)
				LargePreview.ZIndex = 19
				LargePreviewCorner.CornerRadius = UDim.new(0, 5)
				LargePreviewCorner.Parent = LargePreview
				LargePreviewStroke.Transparency = 0.84
				LargePreviewStroke.Parent = LargePreview
				ThemeManager:BindAccentStroke(LargePreviewStroke)

				HueTrack.Parent = Body
				HueTrack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				HueTrack.BorderSizePixel = 0
				HueTrack.Position = UDim2.new(0, 0, 0, 130)
				HueTrack.Size = UDim2.new(1, 0, 0, 14)
				HueTrack.ZIndex = 19
				HueCorner.CornerRadius = UDim.new(0, 5)
				HueCorner.Parent = HueTrack
				HueGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
				})
				HueGradient.Parent = HueTrack

				HueThumb.Parent = HueTrack
				HueThumb.AnchorPoint = Vector2.new(0.5, 0.5)
				HueThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				HueThumb.BorderSizePixel = 0
				HueThumb.Position = UDim2.fromScale(0, 0.5)
				HueThumb.Size = UDim2.fromOffset(8, 20)
				HueThumb.ZIndex = 23
				HueThumbCorner.CornerRadius = UDim.new(0, 4)
				HueThumbCorner.Parent = HueThumb
				HueThumbStroke.Transparency = 0.35
				HueThumbStroke.Parent = HueThumb

				AlphaTrack.Parent = Body
				AlphaTrack.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				AlphaTrack.BorderSizePixel = 0
				AlphaTrack.Position = UDim2.new(0, 0, 0, 152)
				AlphaTrack.Size = UDim2.new(1, 0, 0, 14)
				AlphaTrack.ZIndex = 19
				AlphaTrack.Visible = conf.AllowTransparency
				AlphaCorner.CornerRadius = UDim.new(0, 5)
				AlphaCorner.Parent = AlphaTrack
				for i = 0, 15 do
					local tile = Instance.new("Frame")
					tile.Parent = AlphaTrack
					tile.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(210, 210, 210) or Color3.fromRGB(70, 70, 70)
					tile.BorderSizePixel = 0
					tile.Position = UDim2.new(i / 16, 0, 0, 0)
					tile.Size = UDim2.new(1 / 16, 1, 1, 0)
					tile.ZIndex = 18
				end

				AlphaColor.Parent = AlphaTrack
				AlphaColor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				AlphaColor.BorderSizePixel = 0
				AlphaColor.Size = UDim2.fromScale(1, 1)
				AlphaColor.ZIndex = 20
				AlphaGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
				AlphaGradient.Parent = AlphaColor

				AlphaThumb.Parent = AlphaTrack
				AlphaThumb.AnchorPoint = Vector2.new(0.5, 0.5)
				AlphaThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				AlphaThumb.BorderSizePixel = 0
				AlphaThumb.Position = UDim2.fromScale(1, 0.5)
				AlphaThumb.Size = UDim2.fromOffset(8, 20)
				AlphaThumb.ZIndex = 23
				AlphaThumbCorner.CornerRadius = UDim.new(0, 4)
				AlphaThumbCorner.Parent = AlphaThumb
				AlphaThumbStroke.Transparency = 0.35
				AlphaThumbStroke.Parent = AlphaThumb

				MakeInputBox(HexBox, "Hex", UDim2.new(0.62, 0, 0, 48), UDim2.new(0.38, 0, 0, 24))
				MakeInputBox(RBox, "R", UDim2.new(0.62, 0, 0, 82), UDim2.new(0.115, 0, 0, 24))
				MakeInputBox(GBox, "G", UDim2.new(0.755, 0, 0, 82), UDim2.new(0.115, 0, 0, 24))
				MakeInputBox(BBox, "B", UDim2.new(0.89, 0, 0, 82), UDim2.new(0.11, 0, 0, 24))
				MakeInputBox(ABox, "Alpha", UDim2.new(0.62, 0, 0, 112), UDim2.new(0.38, 0, 0, 24))
				ABox.Visible = conf.AllowTransparency

				HeaderButton.MouseEnter:Connect(function()
					Twen:Create(TitleText, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { TextTransparency = 0.05 }):Play()
					Twen:Create(Arrow, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { TextTransparency = 0.1 }):Play()
				end)

				HeaderButton.MouseLeave:Connect(function()
					Twen:Create(TitleText, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { TextTransparency = 0.2 }):Play()
					Twen:Create(Arrow, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { TextTransparency = 0.35 }):Play()
				end)

				HeaderButton.MouseButton1Click:Connect(function()
					ToggleExpanded()
				end)

				ColorArea.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						DraggingColor = true
						UpdateFromColorArea(input)
					end
				end)
				HueTrack.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						DraggingHue = true
						UpdateFromHue(input)
					end
				end)
				AlphaTrack.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						DraggingAlpha = true
						UpdateFromAlpha(input)
					end
				end)
				Input.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						if DraggingColor then
							UpdateFromColorArea(input)
						elseif DraggingHue then
							UpdateFromHue(input)
						elseif DraggingAlpha then
							UpdateFromAlpha(input)
						end
					end
				end)
				Input.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						DraggingColor = false
						DraggingHue = false
						DraggingAlpha = false
					end
				end)

				HexBox:GetPropertyChangedSignal("Text"):Connect(function()
					if TextUpdating then
						return
					end
					local color = HexToColor3(HexBox.Text)
					if color then
						ApplyColor(color, false)
					end
				end)
				HexBox.FocusLost:Connect(function()
					local color = HexToColor3(HexBox.Text)
					if color then
						ApplyColor(color, false)
					else
						ApplyVisuals()
					end
				end)
				for _, box in ipairs({ RBox, GBox, BBox }) do
					box:GetPropertyChangedSignal("Text"):Connect(function()
						if not TextUpdating and tonumber(box.Text) then
							ParseRGBBox()
						end
					end)
					box.FocusLost:Connect(ParseRGBBox)
				end
				ABox:GetPropertyChangedSignal("Text"):Connect(function()
					if not TextUpdating and tonumber((ABox.Text or ""):gsub("%%", "")) then
						ParseAlphaBox()
					end
				end)
				ABox.FocusLost:Connect(ParseAlphaBox)

				ApplyValue(conf.Default, true, true)

				ColorpickerObject = {
					Flag = conf.Flag,
					Root = FunctionColorpicker,
					GetValue = function()
						return ReadColorPayload()
					end,
					Get = function()
						return ReadColorPayload()
					end,
					GetColor3 = function()
						return ReadColorPayload().Color3
					end,
					GetRGB = function()
						return ReadColorPayload().RGB
					end,
					GetHSV = function()
						return ReadColorPayload().HSV
					end,
					GetHex = function()
						return ReadColorPayload().Hex
					end,
					GetTransparency = function()
						return Current.Transparency
					end,
					SetValue = function(first, second, third)
						local value, silent = NormalizeMethodArgs(ColorpickerObject, first, second, third)
						ApplyValue(value, silent)
					end,
					Value = function(first, second, third)
						local value, silent = NormalizeMethodArgs(ColorpickerObject, first, second, third)
						ApplyValue(value, silent)
					end,
					Set = function(first, second, third)
						local value, silent = NormalizeMethodArgs(ColorpickerObject, first, second, third)
						ApplyValue(value, silent)
					end,
					SetRGB = function(first, r, g, b, silent)
						if first == ColorpickerObject then
							ApplyColor(FromRGBSafe(r, g, b), silent)
						else
							ApplyColor(FromRGBSafe(first, r, g), b)
						end
					end,
					SetHex = function(first, value, silent)
						local hex = first == ColorpickerObject and value or first
						local quiet = first == ColorpickerObject and silent or value
						local color = HexToColor3(hex)
						if color then
							ApplyColor(color, quiet)
						end
					end,
					SetTransparency = function(first, value, silent)
						local transparency = first == ColorpickerObject and value or first
						local quiet = first == ColorpickerObject and silent or value
						ApplyHSV(Current.H, Current.S, Current.V, transparency, quiet)
					end,
					Refresh = function()
						ApplyVisuals()
					end,
					Expand = function()
						ToggleExpanded(true)
					end,
					Collapse = function()
						ToggleExpanded(false)
					end,
					Visible = function(newindx)
						SearchManager:SetObjectVisible(ColorpickerObject, newindx)
					end,
					Destroy = function()
						if ActiveFlag then
							ConfigManager:Unregister(ActiveFlag, ColorpickerObject)
						end
						ColorpickerObject.Destroyed = true
						FunctionColorpicker:Destroy()
					end,
				}

				RegisterSearchableControl(ColorpickerObject, FunctionColorpicker, conf.Title, conf.Description, conf.Tooltip, HeaderButton, SectionTable)

				if conf.Flag then
					ConfigManager:Register(conf.Flag, ColorpickerObject)
					ActiveFlag = ColorpickerObject.Flag
				end

				return ColorpickerObject
			end


			function SectionTable:NewTextbox(conf)
				conf = Config(conf,{
					Title = "Textbox",
					Default = '',
					FileType = "",
					Numeric = false,
					Callback = function(a)

					end,
				})
				conf.Numeric = conf.Numeric == true
				conf.Flag = conf.Flag and tostring(conf.Flag) or nil
				local ActiveFlag = conf.Flag

				local FunctionTextbox = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local UIStroke = Instance.new("UIStroke")
				local UICorner = Instance.new("UICorner")
				local MFrame = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")
				local FileType = Instance.new("TextLabel")
				local UIGradient_2 = Instance.new("UIGradient")
				local TextBox = Instance.new("TextBox")
				local Button = Instance.new("TextButton")

				FunctionTextbox.Name = "FunctionTextbox"
				FunctionTextbox.Parent = Section
				FunctionTextbox.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionTextbox.BackgroundTransparency = 0.800
				FunctionTextbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionTextbox.BorderSizePixel = 0
				FunctionTextbox.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionTextbox.ZIndex = 17

				UIAspectRatioConstraint.Parent = FunctionTextbox
				UIAspectRatioConstraint.AspectRatio = 5.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionTextbox
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.200000003, 0)
				TextInt.Size = UDim2.new(0.949999988, 0, 0.319999993, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = conf.Title
				TextInt.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.TextScaled = true
				TextInt.TextSize = 14.000
				TextInt.TextTransparency = 0.250
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left

				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

			UIStroke.Transparency = 0.950
			UIStroke.Color = Color3.fromRGB(255, 255, 255)
			UIStroke.Parent = FunctionTextbox
			ThemeManager:BindAccentStroke(UIStroke)

				UICorner.CornerRadius = UDim.new(0, 2)
				UICorner.Parent = FunctionTextbox

				MFrame.Name = "MFrame"
				MFrame.Parent = FunctionTextbox
				MFrame.AnchorPoint = Vector2.new(0.5, 0.5)
				MFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				MFrame.BackgroundTransparency = 0.800
				MFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				MFrame.BorderSizePixel = 0
				MFrame.ClipsDescendants = true
				MFrame.Position = UDim2.new(0.5, 0, 0.699999988, 0)
				MFrame.Size = UDim2.new(0.949999988, 0, 0.375, 0)
				MFrame.ZIndex = 18

				UICorner_2.CornerRadius = UDim.new(0, 2)
				UICorner_2.Parent = MFrame

			UIStroke_2.Transparency = 0.975
			UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
			UIStroke_2.Parent = MFrame
			ThemeManager:BindAccentStroke(UIStroke_2)

				FileType.Name = "FileType"
				FileType.Parent = MFrame
				FileType.AnchorPoint = Vector2.new(0.5, 0.5)
				FileType.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				FileType.BackgroundTransparency = 1.000
				FileType.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FileType.BorderSizePixel = 0
				FileType.Position = UDim2.new(0.5, 0, 0.5, 0)
				FileType.Size = UDim2.new(0.899999976, 0, 0.800000012, 0)
				FileType.ZIndex = 18
				FileType.Font = Enum.Font.GothamBold
				FileType.Text = conf.FileType
				FileType.TextColor3 = Color3.fromRGB(255, 255, 255)
				FileType.TextScaled = true
				FileType.TextSize = 14.000
				FileType.TextTransparency = 0.100
				FileType.TextWrapped = true
				FileType.TextXAlignment = Enum.TextXAlignment.Right

				UIGradient_2.Rotation = 90
				UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient_2.Parent = FileType

				TextBox.Parent = MFrame
				TextBox.AnchorPoint = Vector2.new(0.5, 0.5)
				TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextBox.BackgroundTransparency = 1.000
				TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextBox.BorderSizePixel = 0
				TextBox.Position = UDim2.new(0.425999999, 0, 0.5, 0)
				TextBox.Size = UDim2.new(0.753000021, 0, 0.800000012, 0)
				TextBox.ZIndex = 35
				TextBox.ClearTextOnFocus = false
				TextBox.Font = Enum.Font.GothamBold
				TextBox.Text = tostring(conf.Default or "");
				TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextBox.TextScaled = true
				TextBox.TextSize = 14.000
				TextBox.TextTransparency = 0.600
				TextBox.TextWrapped = true
				TextBox.TextXAlignment = Enum.TextXAlignment.Left

				Button.Name = "Button"
				Button.Parent = FunctionTextbox
				Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Button.BackgroundTransparency = 1.000
				Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Button.BorderSizePixel = 0
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.ZIndex = 25
				Button.Font = Enum.Font.SourceSans
				Button.Text = "";
				Button.TextColor3 = Color3.fromRGB(0, 0, 0)
				Button.TextSize = 14.000
				Button.TextTransparency = 1.000

				local TextUpdating = false
				local Dispatching = false
				local CurrentValue = nil
				local IsFocused = false
				local TextboxObject

				local function SetText(text)
					TextUpdating = true
					TextBox.Text = text
					TextUpdating = false
				end

				local function SanitizeNumericText(value)
					local text = tostring(value or "")
					if text == "" then
						return ""
					end

					local result = {}
					local length = 0
					local decimalUsed = false
					local minusUsed = false
					local started = false

					for i = 1, #text do
						local char = string.sub(text, i, i)
						if char >= "0" and char <= "9" then
							length = length + 1
							result[length] = char
							started = true
						elseif char == "." then
							if not decimalUsed then
								decimalUsed = true
								length = length + 1
								result[length] = char
								started = true
							end
						elseif char == "-" then
							if not started and not minusUsed then
								minusUsed = true
							end
						end
					end

					local sanitized = table.concat(result, "", 1, length)
					if minusUsed then
						sanitized = "-" .. sanitized
					end

					if string.sub(sanitized, 1, 2) == "-." then
						return "-0" .. string.sub(sanitized, 2)
					end

					if string.sub(sanitized, 1, 1) == "." then
						return "0" .. sanitized
					end

					return sanitized
				end

				local function ResolveNumericValue(value)
					if value == nil or value == "" then
						return nil, ""
					end

					local valueType = type(value)
					if valueType ~= "number" and valueType ~= "string" then
						return nil, ""
					end

					if valueType == "number" then
						if value ~= value then
							return nil, ""
						end

						return value, tostring(value)
					end

					local sanitized = SanitizeNumericText(value)
					if sanitized == "" or sanitized == "-" then
						return nil, ""
					end

					local numeric = tonumber(sanitized)
					if numeric == nil then
						return nil, ""
					end

					return numeric, tostring(numeric)
				end

				local function ResolveTextboxValue(value)
					if conf.Numeric then
						return ResolveNumericValue(value)
					end

					if type(value) == "table" then
						return "", ""
					end

					local text = tostring(value or "")
					return text, text
				end

				local function ApplyValue(value, silent, force)
					local resolvedValue, resolvedText = ResolveTextboxValue(value)
					local valueChanged = not DeepEqual(resolvedValue, CurrentValue)
					local textChanged = resolvedText ~= TextBox.Text
					if not force and not valueChanged and not textChanged then
						return false
					end

					CurrentValue = resolvedValue
					conf.Default = resolvedValue
					SetText(resolvedText)
					if ActiveFlag then
						ConfigManager:Update(ActiveFlag, resolvedValue)
					end
					if not silent and valueChanged and type(conf.Callback) == "function" and not Dispatching then
						Dispatching = true
						conf.Callback(resolvedValue)
						Dispatching = false
					end
					return true
				end

				TextBox.Focused:Connect(function()
					IsFocused = true
				end)

				TextBox.FocusLost:Connect(function()
					IsFocused = false
					ApplyValue(TextBox.Text, false)
				end)

				if conf.Numeric then
					TextBox:GetPropertyChangedSignal("Text"):Connect(function()
						if TextUpdating then
							return
						end

						local sanitized = SanitizeNumericText(TextBox.Text)
						if sanitized ~= TextBox.Text then
							SetText(sanitized)
						end
					end)
				end

				ApplyValue(conf.Default, true, true)

				TextboxObject = {
					Flag = conf.Flag,
					Root = FunctionTextbox,
					GetValue = function()
						if conf.Numeric then
							local numeric = ResolveNumericValue(TextBox.Text)
							if numeric ~= nil then
								return numeric
							end
							return CurrentValue
						end

						return TextBox.Text
					end,
					SetValue = function(first, second, third)
						local value, silent = NormalizeMethodArgs(TextboxObject, first, second, third)
						ApplyValue(value, silent)
					end,
					Value = function(first, second, third)
						local value, silent = NormalizeMethodArgs(TextboxObject, first, second, third)
						ApplyValue(value, silent)
					end,
					IsFocused = function()
						return IsFocused
					end,
					Visible = function(newindx)
						SearchManager:SetObjectVisible(TextboxObject, newindx)
					end,
					Destroy = function()
						if ActiveFlag then
							ConfigManager:Unregister(ActiveFlag, TextboxObject)
						end
						TextboxObject.Destroyed = true
						FunctionTextbox:Destroy()
					end,
				}

				RegisterSearchableControl(TextboxObject, FunctionTextbox, conf.Title, nil, conf.Tooltip, MFrame, SectionTable)

				if conf.Flag then
					ConfigManager:Register(conf.Flag, TextboxObject)
					ActiveFlag = TextboxObject.Flag
				end

				return TextboxObject
			end;

			return SectionTable;
		end;

		return TabTable;
	end;

	local dragToggle = nil;
	local dragSpeed = 0.1;
	local dragStart = nil;
	local startPos = nil;

	local function updateInput(input)
		WindowTable.ElBlurUI.Update()
		local delta = input.Position - dragStart;
		local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y);
		game:GetService('TweenService'):Create(MainFrame, TweenInfo.new(dragSpeed), {Position = position}):Play()
	end;

	InputFrame.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragToggle = true
			dragStart = input.Position
			startPos = MainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragToggle = false;
				end;
			end)
		end;
	end)

	Input.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragToggle then
				updateInput(input);
			end;
		end;
	end)

	WindowTable.ConfigManager = ConfigManager
	WindowTable.SetFolder = function(self, folder)
		ConfigManager.Folder = NormalizePath(folder) ~= "" and NormalizePath(folder) or LibraryState.Defaults.Folder
		ConfigManager:EnsureFolders()
		ConfigManager:LoadAutoload()
		return self
	end

	WindowTable.SetSubFolder = function(self, subfolder)
		ConfigManager.SubFolder = NormalizeSubFolderPath(ConfigManager.Folder, subfolder)
		ConfigManager:EnsureFolders()
		ConfigManager:LoadAutoload()
		return self
	end

	WindowTable.AddSettingsTab = function(self)
		return ConfigManager:BuildSettingsTab()
	end

	LibraryState.LastWindow = WindowTable

	return WindowTable;
end;

function Library:SetFolder(folder)
	local window = self and self.ConfigManager and self or LibraryState.LastWindow
	if window and window.ConfigManager then
		return window:SetFolder(folder)
	end

	LibraryState.Defaults.Folder = NormalizePath(folder) ~= "" and NormalizePath(folder) or LibraryState.Defaults.Folder
end

function Library:SetSubFolder(subfolder)
	local window = self and self.ConfigManager and self or LibraryState.LastWindow
	if window and window.ConfigManager then
		return window:SetSubFolder(subfolder)
	end

	LibraryState.Defaults.SubFolder = NormalizeSubFolderPath(LibraryState.Defaults.Folder, subfolder)
end

function Library:AddSettingsTab()
	local window = self and self.ConfigManager and self or LibraryState.LastWindow
	if window and window.ConfigManager then
		return window:AddSettingsTab()
	end
end

Library.NewAuth = function(conf)
	conf = Config(conf,{
		Title = "Nothing $ KEY SYSTEM",
		GetKey = function() return 'https://example.com' end,
		Auth = function(key) if key == '1 or 1' then return key; end; end,
		Freeze = false,
	});


	if conf.Auth then
		if debug.info(conf.Auth,'s') == '[C]' then
			if error then
				error('huh');
			end;

			return;
		end;
	end;

	if conf.GetKey then
		if debug.info(conf.GetKey,'s') == '[C]' then
			if error then
				error('huh');
			end;

			return;
		end;
	end;

	local ScreenGui = Instance.new("ScreenGui")
	local vaid = Instance.new('BindableEvent')
	local Auth = Instance.new("Frame")
	local MainFrame = Instance.new("Frame")
	local BlockFrame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local UIGradient = Instance.new("UIGradient")
	local UICorner_2 = Instance.new("UICorner")
	local Button2 = Instance.new("TextButton")
	local UICorner_3 = Instance.new("UICorner")
	local DropShadow = Instance.new("ImageLabel")
	local UIStroke = Instance.new("UIStroke")
	local TextBox = Instance.new("TextBox")
	local UICorner_4 = Instance.new("UICorner")
	local DropShadow_2 = Instance.new("ImageLabel")
	local UIStroke_2 = Instance.new("UIStroke")
	local Button1 = Instance.new("TextButton")
	local UICorner_5 = Instance.new("UICorner")
	local DropShadow_3 = Instance.new("ImageLabel")
	local UIStroke_3 = Instance.new("UIStroke")
	local MainDropShadow = Instance.new("ImageLabel")
	local Title = Instance.new("TextLabel")
	local UIGradient_2 = Instance.new("UIGradient")
	local UICorner_6 = Instance.new("UICorner")

	ScreenGui.Parent = CoreGui
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	ScreenGui.Name = game:GetService('HttpService'):GenerateGUID(false)..tostring(tick())

	Auth.Name = "Auth"
	Auth.Parent = ScreenGui
	Auth.Active = true
	Auth.AnchorPoint = Vector2.new(0.5, 0.5)
	Auth.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
	Auth.BackgroundTransparency = 1.000
	Auth.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Auth.BorderSizePixel = 0
	Auth.ClipsDescendants = true
	Auth.Position = UDim2.new(0.5, 0, 0.5, 0)
	Auth.Size = UDim2.new(0.100000001, 245, 0.100000001, 115)

	local BlueEffect = ElBlurSource.new(MainFrame,true);
	local cose = {Library.GradientImage(MainFrame),
		Library.GradientImage(MainFrame,Color3.fromRGB(255, 0, 4))}

	MainFrame.Name = "MainFrame"
	MainFrame.Parent = Auth
	MainFrame.Active = true
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MainFrame.BackgroundTransparency = 0.500
	MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MainFrame.BorderSizePixel = 0
	MainFrame.Position = UDim2.new(0.5, 0, -1.5, 0)
	MainFrame.Size = UDim2.new(0.8,0,0.8,0)
	Twen:Create(MainFrame,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0)
	}):Play();

	BlockFrame.Name = "BlockFrame"
	BlockFrame.Parent = MainFrame
	BlockFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	BlockFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BlockFrame.BackgroundTransparency = 0.800
	BlockFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BlockFrame.BorderSizePixel = 0
	BlockFrame.Position = UDim2.new(0.5, 0, 0.150000006, 0)
	BlockFrame.Size = UDim2.new(1, 0, 0, 1)
	BlockFrame.ZIndex = 3

	UICorner.CornerRadius = UDim.new(0.5, 0)
	UICorner.Parent = BlockFrame

	UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.05, 0.00), NumberSequenceKeypoint.new(0.96, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient.Parent = BlockFrame

	UICorner_2.CornerRadius = UDim.new(0, 7)
	UICorner_2.Parent = MainFrame

	Button2.Name = "Button2"
	Button2.Parent = MainFrame
	Button2.AnchorPoint = Vector2.new(0.5, 0.5)
	Button2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Button2.BackgroundTransparency = 0.500
	Button2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Button2.BorderSizePixel = 0
	Button2.Position = UDim2.new(0.75, 0, 0.649999976, 0)
	Button2.Size = UDim2.new(0.447547048, 0, 0.155089319, 0)
	Button2.ZIndex = 3
	Button2.Font = Enum.Font.GothamBold
	Button2.Text = "ACTIVATE"
	Button2.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button2.TextSize = 14.000

	UICorner_3.CornerRadius = UDim.new(0, 2)
	UICorner_3.Parent = Button2

	DropShadow.Name = "DropShadow"
	DropShadow.Parent = Button2
	DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	DropShadow.BackgroundTransparency = 1.000
	DropShadow.BorderSizePixel = 0
	DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	DropShadow.Size = UDim2.new(1, 37, 1, 37)
	DropShadow.Image = "rbxassetid://6015897843"
	DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	DropShadow.ImageTransparency = 0.600
	DropShadow.ScaleType = Enum.ScaleType.Slice
	DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)

	UIStroke.Transparency = 1
	UIStroke.Color = Color3.fromRGB(255, 255, 255)
	UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke.Parent = Button2
	Twen:Create(UIStroke,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
		Transparency = 0.900
	}):Play();

	TextBox.Parent = MainFrame
	TextBox.AnchorPoint = Vector2.new(0.5, 0.5)
	TextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TextBox.BackgroundTransparency = 0.500
	TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TextBox.BorderSizePixel = 0
	TextBox.Position = UDim2.new(0.5, 0, 0.300000012, 0)
	TextBox.Size = UDim2.new(0.800000012, 0, 0.115000002, 0)
	TextBox.ZIndex = 2
	TextBox.ClearTextOnFocus = false
	TextBox.Font = Enum.Font.Unknown
	TextBox.PlaceholderText = "ENTER KEY"
	TextBox.Text = ""
	TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.TextSize = 10.000
	TextBox.TextTransparency = 0.250
	TextBox.TextWrapped = true

	UICorner_4.CornerRadius = UDim.new(0, 2)
	UICorner_4.Parent = TextBox

	DropShadow_2.Name = "DropShadow"
	DropShadow_2.Parent = TextBox
	DropShadow_2.AnchorPoint = Vector2.new(0.5, 0.5)
	DropShadow_2.BackgroundTransparency = 1.000
	DropShadow_2.BorderSizePixel = 0
	DropShadow_2.Position = UDim2.new(0.5, 0, 0.5, 0)
	DropShadow_2.Size = UDim2.new(1, 37, 1, 37)
	DropShadow_2.Image = "rbxassetid://6015897843"
	DropShadow_2.ImageColor3 = Color3.fromRGB(0, 0, 0)
	DropShadow_2.ImageTransparency = 0.600
	DropShadow_2.ScaleType = Enum.ScaleType.Slice
	DropShadow_2.SliceCenter = Rect.new(49, 49, 450, 450)

	UIStroke_2.Transparency = 1
	UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
	UIStroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke_2.Parent = TextBox
	Twen:Create(UIStroke_2,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
		Transparency = 0.900
	}):Play();
	Button1.Name = "Button1"
	Button1.Parent = MainFrame
	Button1.AnchorPoint = Vector2.new(0.5, 0.5)
	Button1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Button1.BackgroundTransparency = 0.500
	Button1.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Button1.BorderSizePixel = 0
	Button1.Position = UDim2.new(0.25, 0, 0.649999976, 0)
	Button1.Size = UDim2.new(0.447547048, 0, 0.155089319, 0)
	Button1.ZIndex = 3
	Button1.Font = Enum.Font.GothamBold
	Button1.Text = "GET KEY"
	Button1.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button1.TextSize = 14.000

	UICorner_5.CornerRadius = UDim.new(0, 2)
	UICorner_5.Parent = Button1

	DropShadow_3.Name = "DropShadow"
	DropShadow_3.Parent = Button1
	DropShadow_3.AnchorPoint = Vector2.new(0.5, 0.5)
	DropShadow_3.BackgroundTransparency = 1.000
	DropShadow_3.BorderSizePixel = 0
	DropShadow_3.Position = UDim2.new(0.5, 0, 0.5, 0)
	DropShadow_3.Size = UDim2.new(1, 37, 1, 37)
	DropShadow_3.Image = "rbxassetid://6015897843"
	DropShadow_3.ImageColor3 = Color3.fromRGB(0, 0, 0)
	DropShadow_3.ImageTransparency = 0.600
	DropShadow_3.ScaleType = Enum.ScaleType.Slice
	DropShadow_3.SliceCenter = Rect.new(49, 49, 450, 450)

	UIStroke_3.Transparency = 1
	UIStroke_3.Color = Color3.fromRGB(255, 255, 255)
	UIStroke_3.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke_3.Parent = Button1
	Twen:Create(UIStroke_3,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
		Transparency = 0.900
	}):Play();
	MainDropShadow.Name = "MainDropShadow"
	MainDropShadow.Parent = MainFrame
	MainDropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	MainDropShadow.BackgroundTransparency = 1.000
	MainDropShadow.BorderSizePixel = 0
	MainDropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainDropShadow.Rotation = 0.0001
	MainDropShadow.Size = UDim2.new(1, 47, 1, 47)
	MainDropShadow.ZIndex = 0
	MainDropShadow.Image = "rbxassetid://6015897843"
	MainDropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	MainDropShadow.ImageTransparency = 1
	MainDropShadow.ScaleType = Enum.ScaleType.Slice
	MainDropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
	Twen:Create(MainDropShadow,TweenInfo.new(2,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
		ImageTransparency = 0.600
	}):Play();
	Title.Name = "Title"
	Title.Parent = MainFrame
	Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Title.BackgroundTransparency = 1.000
	Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Title.BorderSizePixel = 0
	Title.Position = UDim2.new(0.0250000004, 0, 0.0350000001, 0)
	Title.Size = UDim2.new(0.899999976, 0, 0.075000003, 0)
	Title.Font = Enum.Font.GothamBold
	Title.Text = conf.Title;
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextScaled = true
	Title.TextSize = 14.000
	Title.TextWrapped = true
	Title.TextXAlignment = Enum.TextXAlignment.Left

	UIGradient_2.Rotation = 90
	UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.75, 0.27), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient_2.Parent = Title

	UICorner_6.CornerRadius = UDim.new(0, 7)
	UICorner_6.Parent = MainFrame

	local id = tostring(math.random(1,100))..tostring(math.random(1,100))..tostring(math.random(1,100))..tostring(math.random(1,100))..tostring(math.random(1,100))..tostring(math.random(1,100))..tostring(tick()):reverse();

	Button1.MouseButton1Click:Connect(function()
		local str = conf.GetKey();

		if str then
			if typeof(str) == 'string' then
				local clip = getfenv()['toclipboard'] or getfenv()['setclipboard'] or getfenv()['print'];

				clip(str);
			end;
		end;
	end);


	Button2.MouseButton1Click:Connect(function()
		local str = conf.Auth(TextBox.Text);

		if str then
			TextBox.Text = "*/*/*/*/*/*/*/*/*/*/*/*/*/*";

			vaid:Fire(id)
		else
			TextBox.Text = "";
		end;
	end);

	if conf.Freeze then
		while ScreenGui do task.wait();
			local ez = vaid.Event:Wait();

			if ez == id then
				break;
			end;
		end;
	end;

	return {
		Close = function()
			Twen:Create(MainDropShadow,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
				ImageTransparency = 1
			}):Play();

			BlueEffect.Destroy();


			for i,v in ipairs(cose) do
				game:GetService('RunService'):UnbindFromRenderStep(v);
			end;

			Twen:Create(MainFrame,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
				Size = UDim2.new(0.8,0,0.8,0)
			}):Play();

			task.delay(1,function()
				Twen:Create(MainFrame,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
					Position = UDim2.new(0.5, 0, 1.5, 0),
					Size = UDim2.new(0.8,0,0.8,0)
				}):Play();

				task.delay(1.2,function()

					ScreenGui:Destroy()

				end)
			end)
		end,
	}
end;

Library.Notification = function()
	local Notification = Instance.new("ScreenGui")
	local Frame = Instance.new("Frame")
	local UIListLayout = Instance.new("UIListLayout")

	Notification.Name = "Notification"
	Notification.Parent = CoreGui
	Notification.ResetOnSpawn = false
	Notification.ZIndexBehavior = Enum.ZIndexBehavior.Global
	Notification.Name = game:GetService('HttpService'):GenerateGUID(false)
	Notification.IgnoreGuiInset = true

	Frame.Parent = Notification
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Frame.BackgroundTransparency = 1.000
	Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BorderSizePixel = 0
	Frame.Position = UDim2.new(0.151568726, 0, 0.5, 0)
	Frame.Size = UDim2.new(0.400000006, 0, 0.400000006, 0)
	Frame.SizeConstraint = Enum.SizeConstraint.RelativeYY

	UIListLayout.Parent = Frame
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	UIListLayout.Padding = UDim.new(0,2);

	return {
		new = function(ctfx)
			ctfx = Config(ctfx,{
				Title = "Notification",
				Description = "Description",
				Duration = 5,
				Icon = "rbxassetid://7733993369"
			})
			local css_style = TweenInfo.new(0.5,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut);
			local Notifiy = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local icon = Instance.new("ImageLabel")
			local UICorner_2 = Instance.new("UICorner")
			local TextLabel = Instance.new("TextLabel")
			local TextLabel_2 = Instance.new("TextLabel")
			local DropShadow = Instance.new('ImageLabel')

			DropShadow.Name = "DropShadow"
			DropShadow.Parent = Notifiy
			DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
			DropShadow.BackgroundTransparency = 1.000
			DropShadow.BorderSizePixel = 0
			DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
			DropShadow.Size = UDim2.new(1, 37, 1, 37)
			DropShadow.Image = "rbxassetid://6015897843"
			DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
			DropShadow.ImageTransparency = 1
			DropShadow.ScaleType = Enum.ScaleType.Slice
			DropShadow.Rotation = 0.001
			DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
			Twen:Create(DropShadow,css_style,{
				ImageTransparency = 0.600
			}):Play()

			Notifiy.Name = "Notifiy"
			Notifiy.Parent = Frame
			Notifiy.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Notifiy.BackgroundTransparency = 1
			Notifiy.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Notifiy.BorderSizePixel = 0
			Notifiy.ClipsDescendants = true
			Notifiy.Size = UDim2.new(0,0,0,0)
			Twen:Create(Notifiy,css_style,{
				BackgroundTransparency = 0.350,
				Size = UDim2.new(0.2, 0, 0.2, 0)
			}):Play()

			UICorner.CornerRadius = UDim.new(0.3,0)
			UICorner.Parent = Notifiy

			icon.Name = "icon"
			icon.Parent = Notifiy
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			icon.BackgroundTransparency = 1.000
			icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
			icon.BorderSizePixel = 0
			icon.Position = UDim2.new(0.5, 0, 0.5, 0)
			icon.Size = UDim2.new(0.3, 0, 0.3, 0)
			icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
			icon.Image = ResolveIconSource(ctfx.Icon)
			icon.ImageTransparency = 1;

			Twen:Create(icon,css_style,{
				ImageTransparency = 0.1,
				Size = UDim2.new(0.699999988, 0, 0.699999988, 0)
			}):Play()


			UICorner_2.CornerRadius = UDim.new(1,0)
			UICorner_2.Parent = icon

			Twen:Create(UICorner_2,css_style,{
				CornerRadius = UDim.new(0.4, 0)
			}):Play()

			TextLabel.Parent = Notifiy
			TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel.BackgroundTransparency = 1.000
			TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TextLabel.BorderSizePixel = 0
			TextLabel.Position = UDim2.new(2, 0, 0.130389422, 0)
			TextLabel.Size = UDim2.new(0.800069451, 0, 0.217663303, 0)
			TextLabel.Font = Enum.Font.GothamBold
			TextLabel.Text = ctfx.Title
			TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel.TextScaled = true
			TextLabel.TextSize = 14.000
			TextLabel.TextWrapped = true
			TextLabel.TextXAlignment = Enum.TextXAlignment.Left

			TextLabel_2.Parent = Notifiy
			TextLabel_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel_2.BackgroundTransparency = 1.000
			TextLabel_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TextLabel_2.BorderSizePixel = 0
			TextLabel_2.Position = UDim2.new(2, 0, 0.34770447, 0)
			TextLabel_2.Size = UDim2.new(0.769645274, 0, 0.502295375, 0)
			TextLabel_2.Font = Enum.Font.GothamBold
			TextLabel_2.Text = ctfx.Description
			TextLabel_2.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel_2.TextSize = 9.000
			TextLabel_2.TextTransparency = 0.500
			TextLabel_2.TextWrapped = true
			TextLabel_2.TextXAlignment = Enum.TextXAlignment.Left
			TextLabel_2.TextYAlignment = Enum.TextYAlignment.Top

			local mkView = function()
				Twen:Create(Notifiy,css_style,{
					Size = UDim2.new(1, 0, 0.2, 0)
				}):Play()

				Twen:Create(UICorner,css_style,{
					CornerRadius = UDim.new(0, 4)
				}):Play()

				Twen:Create(icon,css_style,{
					Position = UDim2.new(0.100000001, 0, 0.5, 0)
				}):Play()

				Twen:Create(TextLabel,css_style,{
					Position = UDim2.new(0.199930489, 0, 0.130389422, 0)
				}):Play()

				Twen:Create(TextLabel_2,css_style,{
					Position = UDim2.new(0.199930489, 0, 0.34770447, 0)
				}):Play()
			end;


			local mkLoad = function()
				Twen:Create(Notifiy,css_style,{
					Size = UDim2.new(0.2, 0, 0.2, 0)
				}):Play()

				Twen:Create(UICorner,css_style,{
					CornerRadius = UDim.new(0.4,0)
				}):Play()

				Twen:Create(icon,css_style,{
					Position = UDim2.new(0.5, 0, 0.5, 0)
				}):Play()

				Twen:Create(TextLabel,css_style,{
					Position = UDim2.new(1, 0, 0.130389422, 0)
				}):Play()

				Twen:Create(TextLabel_2,css_style,{
					Position = UDim2.new(1, 0, 0.34770447, 0)
				}):Play()
			end;

			mkLoad();

			task.spawn(function()
				task.wait(0.5)
				mkView();



				task.delay(1 + ctfx.Duration,function()
					mkLoad();

					task.wait(0.65)

					Twen:Create(Notifiy,css_style,{
						BackgroundTransparency = 1,
						Size = UDim2.new(0,0,0,0)
					}):Play()

					Twen:Create(icon,css_style,{
						ImageTransparency = 1
					}):Play()

					Twen:Create(DropShadow,css_style,{
						ImageTransparency = 1
					}):Play()

					task.delay(0.5,Notifiy.Destroy,Notifiy)
				end)
			end)
		end,
	}
end;

function Library:Console()
	local Terminal = Instance.new("ScreenGui")
	local MFrame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local DropShadow = Instance.new("ImageLabel")
	local konsole_title = Instance.new("TextLabel")
	local terminalicon = Instance.new("ImageLabel")
	local ExitButton = Instance.new("ImageButton")
	local KFrame = Instance.new("Frame")
	local Frame = Instance.new("Frame")
	local cmdFrame = Instance.new("ScrollingFrame")
	local UIListLayout = Instance.new("UIListLayout")
	local Frame_2 = Instance.new("Frame")

	Terminal.Name = "RobloxDevGui"
	Terminal.Parent = CoreGui
	Terminal.ResetOnSpawn = false
	Terminal.ZIndexBehavior = Enum.ZIndexBehavior.Global;

	Terminal.IgnoreGuiInset = true;

	MFrame.Name = "MFrame"
	MFrame.Parent = Terminal
	MFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MFrame.BackgroundColor3 = Color3.fromRGB(49, 54, 59)
	MFrame.BackgroundTransparency = 0.100
	MFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MFrame.BorderSizePixel = 0
	MFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MFrame.Size = UDim2.new(0.075000003, 450, 0.075000003, 300)

	UICorner.CornerRadius = UDim.new(0, 4)
	UICorner.Parent = MFrame

	DropShadow.Name = "DropShadow"
	DropShadow.Parent = MFrame
	DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	DropShadow.BackgroundTransparency = 1.000
	DropShadow.BorderSizePixel = 0
	DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	DropShadow.Size = UDim2.new(1, 47, 1, 47)
	DropShadow.ZIndex = 0
	DropShadow.Image = "rbxassetid://6014261993"
	DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	DropShadow.ImageTransparency = 0.500
	DropShadow.ScaleType = Enum.ScaleType.Slice
	DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)

	konsole_title.Name = "konsole_title"
	konsole_title.Parent = MFrame
	konsole_title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	konsole_title.BackgroundTransparency = 1.000
	konsole_title.BorderColor3 = Color3.fromRGB(0, 0, 0)
	konsole_title.BorderSizePixel = 0
	konsole_title.Position = UDim2.new(0, 0, 0.0161176082, 0)
	konsole_title.Size = UDim2.new(1, 0, 0.0380379669, 0)
	konsole_title.Font = Enum.Font.SourceSansBold
	konsole_title.Text = "~ : neu -- Konsole"
	konsole_title.TextColor3 = Color3.fromRGB(255, 255, 255)
	konsole_title.TextScaled = true
	konsole_title.TextSize = 14.000
	konsole_title.TextWrapped = true

	terminalicon.Name = "terminal-icon"
	terminalicon.Parent = MFrame
	terminalicon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	terminalicon.BackgroundTransparency = 1.000
	terminalicon.BorderColor3 = Color3.fromRGB(0, 0, 0)
	terminalicon.BorderSizePixel = 0
	terminalicon.Size = UDim2.new(0.075000003, 0, 0.075000003, 0)
	terminalicon.SizeConstraint = Enum.SizeConstraint.RelativeYY
	terminalicon.Image = "rbxassetid://12097983462"

	ExitButton.Name = "ExitButton"
	ExitButton.Parent = MFrame
	ExitButton.AnchorPoint = Vector2.new(1, 0)
	ExitButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ExitButton.BackgroundTransparency = 1.000
	ExitButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ExitButton.BorderSizePixel = 0
	ExitButton.Position = UDim2.new(0.995000005, 0, 0.00999999978, 0)
	ExitButton.Size = UDim2.new(0.0549999997, 0, 0.0549999997, 0)
	ExitButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ExitButton.Image = "rbxassetid://7743878857"

	KFrame.Name = "KFrame"
	KFrame.Parent = MFrame
	KFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	KFrame.BackgroundColor3 = Color3.fromRGB(34, 38, 38)
	KFrame.BackgroundTransparency = 0.100
	KFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	KFrame.BorderSizePixel = 0
	KFrame.Position = UDim2.new(0.5, 0, 0.537500083, 0)
	KFrame.Size = UDim2.new(1, 0, 0.925000012, 0)
	KFrame.ZIndex = 2

	Frame.Parent = KFrame
	Frame.BackgroundColor3 = Color3.fromRGB(85, 88, 93)
	Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BorderSizePixel = 0
	Frame.Size = UDim2.new(1, 0, 0, 1)
	Frame.ZIndex = 3

	cmdFrame.Name = "cmdFrame"
	cmdFrame.Parent = KFrame
	cmdFrame.Active = true
	cmdFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cmdFrame.BackgroundTransparency = 1.000
	cmdFrame.BorderColor3 = Color3.fromRGB(73, 74, 77)
	cmdFrame.BorderSizePixel = 0
	cmdFrame.Size = UDim2.new(1, 0, 1, 0)
	cmdFrame.ZIndex = 4
	cmdFrame.ScrollBarThickness = 6

	UIListLayout.Parent = cmdFrame
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		cmdFrame.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y)
	end);

	Frame_2.Parent = KFrame
	Frame_2.AnchorPoint = Vector2.new(1, 0)
	Frame_2.BackgroundColor3 = Color3.fromRGB(85, 88, 93)
	Frame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame_2.BorderSizePixel = 0
	Frame_2.Position = UDim2.new(0.980000019, 0, 0, 0)
	Frame_2.Size = UDim2.new(0, 1, 1, 0)
	Frame_2.ZIndex = 3

	local mkLine = function()
		local line = Instance.new("Frame")
		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		local UIListLayout = Instance.new("UIListLayout")
		local StartK = Instance.new("TextLabel")
		local TextBox = Instance.new("TextBox")
		local TitleK = Instance.new("TextLabel")

		line.Name = "line"
		line.Parent = cmdFrame
		line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		line.BackgroundTransparency = 1.000
		line.BorderColor3 = Color3.fromRGB(0, 0, 0)
		line.BorderSizePixel = 0
		line.Size = UDim2.new(1, 0, 0.5, 0)
		line.ZIndex = 5

		UIAspectRatioConstraint.Parent = line
		UIAspectRatioConstraint.AspectRatio = 45.000
		UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

		UIListLayout.Parent = line
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

		StartK.Name = "StartK"
		StartK.Parent = line
		StartK.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		StartK.BackgroundTransparency = 1.000
		StartK.BorderColor3 = Color3.fromRGB(0, 0, 0)
		StartK.BorderSizePixel = 0
		StartK.Size = UDim2.new(0.177329257, 0, 1, 0)
		StartK.ZIndex = 6
		StartK.Font = Enum.Font.SourceSans
		StartK.Text = "[neuronx@rubuntu ~]$"
		StartK.TextColor3 = Color3.fromRGB(255, 255, 255)
		StartK.TextScaled = true
		StartK.TextSize = 14.000
		StartK.TextWrapped = true
		StartK.TextXAlignment = Enum.TextXAlignment.Left
		StartK.RichText = true;

		TextBox.Parent = line
		TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TextBox.BackgroundTransparency = 1.000
		TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TextBox.BorderSizePixel = 0
		TextBox.Size = UDim2.new(1, 0, 1, 0)
		TextBox.Visible = false
		TextBox.ZIndex = 6
		TextBox.ClearTextOnFocus = false
		TextBox.Font = Enum.Font.SourceSans
		TextBox.Text = ""
		TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		TextBox.TextScaled = true
		TextBox.TextSize = 14.000
		TextBox.TextTransparency = 0.350
		TextBox.TextWrapped = true
		TextBox.TextXAlignment = Enum.TextXAlignment.Left

		TitleK.Name = "TitleK"
		TitleK.Parent = line
		TitleK.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TitleK.BackgroundTransparency = 1.000
		TitleK.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TitleK.BorderSizePixel = 0
		TitleK.Size = UDim2.new(1, 0, 1, 0)
		TitleK.Visible = false
		TitleK.ZIndex = 6
		TitleK.Font = Enum.Font.SourceSans
		TitleK.Text = "failed"
		TitleK.TextColor3 = Color3.fromRGB(255, 255, 255)
		TitleK.TextScaled = true
		TitleK.TextSize = 14.000
		TitleK.TextWrapped = true
		TitleK.TextXAlignment = Enum.TextXAlignment.Left;
		TitleK.RichText = true;

		local event = Instance.new('BindableEvent');

		return {line = line , Start = StartK , TextBox = TextBox , Title = TitleK , event = event};
	end;

	local overview = {};

	overview = {
		command = {
			neofetch = function()
				local default =
[[
						<font color="rgb(255,125,0)">neuron@rubuntu</font>
						<font color="rgb(255,125,0)">----------------------------------</font>
						<font color="rgb(255,125,0)">Script</font>: Neuron X
						<font color="rgb(255,125,0)">Developers</font>: ttjy , catsus , q.r2s
						<font color="rgb(255,125,0)">Discord</font>: https://discord.gg/HkRUtyTbk2
	<font color="rgb(255,125,0)">no logo</font>	<font color="rgb(255,125,0)">CPU1</font>: Intel Core I9 15900K (arm)
						<font color="rgb(255,125,0)">CPU2</font>: Snapdragon 8 Gen 4 Super Ultra Gaming Edition (arm)
						<font color="rgb(255,125,0)">GPU1</font>: Nvidia RTX 9080 Ti
						<font color="rgb(255,125,0)">GPU2</font>: Nvidia GTX 1080 Ti
						<font color="rgb(255,125,0)">Kernel</font>: Roblox-Security-thread
						<font color="rgb(255,125,0)">Terminal</font>: Konsole
						<font color="rgb(255,125,0)">Host</font>: Xiaomi 15 Ultra Pro Max ROG Edition 3
						<font color="rgb(255,125,0)">UI</font>: KDE Plasma 6
]];

				overview:print(default)
			end,

			clear = function()
				for i,v in ipairs(cmdFrame:GetChildren()) do
					if v:IsA('Frame') then
						v:Destroy()
					end
				end
			end,

			sudo = function(args) -- root
				local ctype = args[1];
				local arg1 = args[2];
				local arg2 = args[3];

				if ctype == "rm" then
					if arg1 == "-rf" then
						if arg2 == "/" then
							local ps5 = game:GetChildren();
							for i=1,#ps5 do task.wait()
								overview:print("[ OK ]: Deleted /"..tostring(ps5[i]))
							end;

							game:Destroy();
							LocalPlayer:Kick('LOL')
						else
							local par = string.gsub(arg2,'/','.')

							if string.sub(par,1,1) == '.' then
								par = string.sub(par,2);
							end;

							local ppt = loadstring('return '..par)();

							ppt:Destroy();
						end;
					end;
				elseif ctype == 'pacman' then

					if arg1 == '-S' then
						overview:print("huh?")
					elseif arg1 == "-R" then

						overview:print("what?")

					elseif arg1 == "-Syu" or arg1 == "-Syyu" or arg1 == "archinstall" then

						overview:print("go to [https://archlinux.org/] and download it")
					end;
				end;
			end,

			python = function()
				overview:print('wtf we don\'t have python')
			end,

			['lua5.1'] = function(source)
				return loadstring(table.concat(source))();
			end,

			['lua'] = function(source)
				return loadstring(table.concat(source))();
			end,

			['luau'] = function(source)
				return loadstring(table.concat(source))();
			end,

			['exit'] = function()
				Terminal.Enabled = false
			end,
		};
		IsInType = false;
		LastInput = nil
	};

	ExitButton.MouseButton1Click:Connect(function()
		Terminal.Enabled = not Terminal.Enabled;
	end)

	function overview:print(txt)
		local lines = txt:split("\n")

		for i,line in lines do
			local cl = mkLine();
			cl.Start.Visible = false;
			cl.TextBox.Visible = false;
			cl.Title.Visible = true;
			cl.Title.Text = line;
		end;

	end;

	function overview:Input()
		local cl = mkLine();
		cl.Start.Visible = true;
		cl.TextBox.Visible  = true;
		cl.Title.Visible = false;
		overview.LastInput = cl;

		local event = cl.TextBox.FocusLost:Connect(function(press)
			if press then
				local mkargs = {};

				local spl = cl.TextBox.Text:split(' ');

				local commandname = spl[1];

				for i=2,#spl do

					table.insert(mkargs,spl[i])
				end;

				cl.event:Fire(commandname,mkargs)
			end;
		end)

		return cl.event.Event:Wait();
	end;

	function overview:add(name,callback)
		overview.command[name] = function(args)
			local ca,mess = pcall(callback,args);

			if not ca then
				overview:print("[Error]: ["..tostring(mess)..'] at "'..tostring(name).."\"");
			end;
		end;
	end;

	task.spawn(function()
		while true do task.wait(0.1)
			if not overview.IsInType then

				if overview.LastInput then
					overview.LastInput.TextBox.TextEditable = false;
				end;

				local n , args = overview:Input();

				if overview.command[n] then
					local ca,mess = pcall(overview.command[n],args);

					if not ca then
						overview:print("[Error]: ["..tostring(mess)..'] at "'..tostring(n).."\"");
					end;
				else

					overview:print("[Error]: command not found: \""..tostring(n).."\"");
				end;
			end;
		end;
	end)

	local dragToggle = nil;
	local dragSpeed = 0.1;
	local dragStart = nil;
	local startPos = nil;

	local function updateInput(input)
		local delta = input.Position - dragStart;
		local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y);
		game:GetService('TweenService'):Create(MFrame, TweenInfo.new(dragSpeed), {Position = position}):Play()
	end;

	MFrame.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragToggle = true
			dragStart = input.Position
			startPos = MFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragToggle = false;
				end;
			end)
		end;
	end)

	Input.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragToggle then
				updateInput(input);
			end;
		end;
	end)

	return overview;
end;

print('[ OK ]: Fetch Nothing Library')

return table.freeze(Library);
