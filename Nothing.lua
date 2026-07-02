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
local Config = function(data,default)
	data = data or {};

	for i,v in next,default do
		data[i] = data[i] or v;
	end;

	return data;
end;

local Library = {};

Library['.'] = '1';
Library['FetchIcon'] = "https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json";
Library._ConfigDefaults = {
	Folder = "NothingUI",
	SubFolder = tostring(game.PlaceId),
}
Library._LastWindow = nil

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

local function SerializeConfigValue(value, seen)
	local valueType = typeof(value)
	if value == nil or valueType == "string" or valueType == "number" or valueType == "boolean" then
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
	config = Config(config,{
		Title = "UI Library",
		Description = "discord.gg/BH6pE7jesa",
		Keybind = Enum.KeyCode.LeftControl,
		Size = UDim2.new(0.100000001, 445, 0.100000001, 315)
	});

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
	WindowTable.ToggleButton = nil
	
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
		LogoText.TextWrapped = true
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

	Twen:Create(ImageButton,TweenInfo1,{
		ImageTransparency = 0.5
	}):Play()

	ImageButton.MouseButton1Click:Connect(function()
		WindowTable.WindowToggle = not WindowTable.WindowToggle
		Update()
	end)

	Input.InputBegan:Connect(function(io)
		if io.KeyCode == WindowTable.Keybind then
			WindowTable.WindowToggle = not WindowTable.WindowToggle
			Update()
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
		SelectedConfig = "",
		AutoloadEnabled = false,
		Folder = Library._ConfigDefaults.Folder,
		SubFolder = Library._ConfigDefaults.SubFolder,
		SettingsUI = nil,
	}

	local function NormalizeConfigName(name, allowEmpty)
		name = tostring(name or "")
		name = name:gsub("[\\/:*?\"<>|]", "_")
		name = name:gsub("^%s+", ""):gsub("%s+$", "")
		name = name:gsub("^%.+", "")
		if name == "" then
			return allowEmpty and "" or "Default"
		end
		return name
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
			return decoded
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
		for _, file in ipairs(SafeListFiles(self:GetConfigFolder())) do
			local name = DecodeFileName(file)
			if name and name ~= "autoload" then
				configs[#configs + 1] = name
			end
		end

		table.sort(configs)
		return configs
	end

	function ConfigManager:SerializeValues()
		for flag, object in pairs(self.Registered) do
			if object and object.GetValue then
				local ok, current = pcall(function()
					return object:GetValue()
				end)
				if ok then
					self.Values[flag] = current
				end
			end
		end

		local result = {}
		for flag, value in pairs(self.Values) do
			result[flag] = SerializeConfigValue(value)
		end
		return result
	end

	function ConfigManager:SyncSettingsUI()
		if not self.SettingsUI then
			return
		end

		local configs = self:RefreshList()
		local ui = self.SettingsUI

		if ui.ConfigDropdown and ui.ConfigDropdown.Set then
			ui.ConfigDropdown:Set(configs)
			if self.SelectedConfig ~= "" then
				ui.ConfigDropdown:SetValue(self.SelectedConfig, true)
			else
				ui.ConfigDropdown:SetValue(nil, true)
			end
		end

		if ui.ConfigTextbox and ui.ConfigTextbox.SetValue then
			ui.ConfigTextbox:SetValue(self.SelectedConfig ~= "" and self.SelectedConfig or "", true)
		end

		if ui.AutoloadToggle and ui.AutoloadToggle.SetValue then
			ui.AutoloadToggle:SetValue(self.AutoloadEnabled, true)
		end
	end

	function ConfigManager:PersistAutoload()
		self:EnsureFolders()
		self:WriteJson(self:GetAutoloadPath(), {
			Enabled = self.AutoloadEnabled and true or false,
			Config = self.SelectedConfig ~= "" and self.SelectedConfig or nil,
		})
	end

	function ConfigManager:SetSelectedConfig(name, silent)
		name = name and NormalizeConfigName(name, true) or ""
		self.SelectedConfig = name

		if not silent then
			self:PersistAutoload()
		end

		self:SyncSettingsUI()
	end

	function ConfigManager:SetAutoloadEnabled(enabled, silent)
		self.AutoloadEnabled = enabled and true or false

		if not silent then
			self:PersistAutoload()
		end

		self:SyncSettingsUI()
	end

	function ConfigManager:Register(flag, object)
		flag = tostring(flag or "")
		if flag == "" or type(object) ~= "table" then
			return false
		end

		if self.Registered[flag] and self.Registered[flag] ~= object then
			warn(("[Nothing UI] Duplicate Flag ignored: %s"):format(flag))
			object.Flag = nil
			return false
		end

		self.Registered[flag] = object
		if object.GetValue then
			local ok, current = pcall(function()
				return object:GetValue()
			end)
			if ok and current ~= nil then
				self.Values[flag] = current
			end
		end
		object.Flag = flag
		object.ConfigManager = self

		if self.LoadedData and self.LoadedData[flag] ~= nil and object.SetValue then
			local loadedValue = self.LoadedData[flag]
			self.Values[flag] = loadedValue
			task.defer(function()
				if object and object.SetValue then
					pcall(function()
						object:SetValue(loadedValue, false)
					end)
				end
			end)
		end

		return true
	end

	function ConfigManager:Update(flag, value)
		if flag == nil then
			return
		end

		self.Values[tostring(flag)] = value
	end

	function ConfigManager:ApplyLoadedData()
		if type(self.LoadedData) ~= "table" then
			return
		end

		for flag, value in pairs(self.LoadedData) do
			local object = self.Registered[flag]
			if object and object.SetValue then
				pcall(function()
					object:SetValue(value, false)
				end)
			end
		end
	end

	function ConfigManager:LoadConfig(name)
		name = name and NormalizeConfigName(name, true) or ""
		if name == "" then
			return false
		end

		self:EnsureFolders()
		local data = self:ReadJson(self:GetConfigPath(name))
		if type(data) ~= "table" then
			self.LoadedData = nil
			return false
		end

		self.LoadedData = data
		self:SetSelectedConfig(name, false)
		self:ApplyLoadedData()
		return true
	end

	function ConfigManager:SaveConfig(name)
		name = name and NormalizeConfigName(name, false) or ""
		if name == "" then
			return false
		end

		self:EnsureFolders()
		local ok = self:WriteJson(self:GetConfigPath(name), self:SerializeValues())
		if not ok then
			return false
		end

		self:SetSelectedConfig(name, false)
		self:SyncSettingsUI()
		return true
	end

	function ConfigManager:LoadAutoload()
		self:EnsureFolders()
		self.LoadedData = nil
		self.AutoloadEnabled = false
		self.SelectedConfig = ""

		local data = self:ReadJson(self:GetAutoloadPath())
		if type(data) == "table" then
			self.AutoloadEnabled = data.Enabled == true
			self.SelectedConfig = data.Config and NormalizeConfigName(data.Config, true) or self.SelectedConfig
		end

		self:SyncSettingsUI()

		if self.AutoloadEnabled and self.SelectedConfig ~= "" then
			self:LoadConfig(self.SelectedConfig)
		end
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

		local ConfigDropdown = nil
		local ConfigTextbox = nil
		local AutoloadToggle = nil

		ConfigDropdown = ConfigSection:NewDropdown({
			Title = "Select Config",
			Data = self:RefreshList(),
			Default = self.SelectedConfig ~= "" and self.SelectedConfig or nil,
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
					ConfigDropdown:Set(list)
				end
				ConfigManager:SyncSettingsUI()
			end,
		})

		ConfigTextbox = ConfigSection:NewTextbox({
			Title = "Config Name",
			Default = self.SelectedConfig,
			FileType = "",
			Flag = nil,
			Callback = function(value)
				if type(value) == "string" and value ~= "" then
					ConfigManager:SetSelectedConfig(value)
				end
			end,
		})

		ConfigSection:Divider()

		ConfigSection:NewButton({
			Title = "Save Config",
			Callback = function()
				local name = ConfigTextbox and ConfigTextbox.GetValue and ConfigTextbox:GetValue() or ConfigManager.SelectedConfig
				if name == nil or tostring(name) == "" then
					name = ConfigManager.SelectedConfig
				end
				if name == nil or tostring(name) == "" then
					name = "Default"
				end
				ConfigManager:SaveConfig(name)
				ConfigManager:SyncSettingsUI()
			end,
		})

		ConfigSection:NewButton({
			Title = "Load Config",
			Callback = function()
				local name = ConfigDropdown and ConfigDropdown.GetValue and ConfigDropdown:GetValue() or ConfigManager.SelectedConfig
				if type(name) == "table" then
					name = next(name)
				end
				if name ~= nil and tostring(name) ~= "" then
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

		ConfigManager.SettingsUI = {
			ConfigDropdown = ConfigDropdown,
			ConfigTextbox = ConfigTextbox,
			AutoloadToggle = AutoloadToggle,
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
			Icon.Image = ResolveIconSource(c_o_n_f_i_g.Icon); 
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
				FunctionParagraph.Size = UDim2.new(0.949999988, 0, 0, 54)
				FunctionParagraph.ZIndex = 17
				Twen:Create(FunctionParagraph, TweenInfo1, { BackgroundTransparency = 0.8 }):Play()

				UICorner.CornerRadius = UDim.new(0, 2)
				UICorner.Parent = FunctionParagraph

				UIStroke.Transparency = 0.950
				UIStroke.Color = Color3.fromRGB(255, 255, 255)
				UIStroke.Parent = FunctionParagraph

				TitleText.Name = "TitleText"
				TitleText.Parent = FunctionParagraph
				TitleText.AnchorPoint = Vector2.new(0.5, 0)
				TitleText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TitleText.BackgroundTransparency = 1.000
				TitleText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TitleText.BorderSizePixel = 0
				TitleText.Position = UDim2.new(0.5, 0, 0.12, 0)
				TitleText.Size = UDim2.new(0.949999988, 0, 0, 18)
				TitleText.ZIndex = 18
				TitleText.Font = Enum.Font.GothamBold
				TitleText.Text = ParagraphState.Title
				TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
				TitleText.TextScaled = true
				TitleText.TextSize = 14.000
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
				DescriptionText.Position = UDim2.new(0.5, 0, 0, 26)
				DescriptionText.Size = UDim2.new(0.949999988, 0, 0, 18)
				DescriptionText.ZIndex = 18
				DescriptionText.Font = Enum.Font.GothamBold
				DescriptionText.Text = ParagraphState.Description
				DescriptionText.TextColor3 = Color3.fromRGB(255, 255, 255)
				DescriptionText.TextScaled = true
				DescriptionText.TextSize = 14.000
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

					local titleHeight = math.max(16, titleBounds.Y)
					local descHeight = ParagraphState.Description ~= "" and math.max(16, descBounds.Y) or 0
					local totalHeight = 14 + titleHeight + (descHeight > 0 and (8 + descHeight) or 8)

					FunctionParagraph.Size = UDim2.new(0.949999988, 0, 0, math.max(46, totalHeight))
					TitleText.Size = UDim2.new(0.949999988, 0, 0, titleHeight)
					DescriptionText.Visible = ParagraphState.Description ~= ""
					if descHeight > 0 then
						DescriptionText.Position = UDim2.new(0.5, 0, 0, titleHeight + 8)
						DescriptionText.Size = UDim2.new(0.949999988, 0, 0, descHeight)
					end
				end

				FunctionParagraph:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateLayout)
				task.defer(UpdateLayout)

				local Paragraph = {}

				function Paragraph:SetTitle(value)
					ParagraphState.Title = tostring(value or "")
					TitleText.Text = ParagraphState.Title
					UpdateLayout()
				end

				function Paragraph:SetDescription(value)
					ParagraphState.Description = tostring(value or "")
					DescriptionText.Text = ParagraphState.Description
					UpdateLayout()
				end

				function Paragraph:Set(title, desc)
					ParagraphState.Title = tostring(title or "")
					ParagraphState.Description = tostring(desc or "")
					TitleText.Text = ParagraphState.Title
					DescriptionText.Text = ParagraphState.Description
					UpdateLayout()
				end

				function Paragraph:Visible(newindx)
					FunctionParagraph.Visible = newindx
				end

				function Paragraph:Destroy()
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

						CurrentBind = ResolveKeybindValue(new, CurrentBind)
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
						UpdateBindDisplay(Bind)
						if BindActiveFlag then
							ConfigManager:Update(BindActiveFlag, CurrentBind)
						end
						Twen:Create(KeybindText, TweenInfo.new(0.1), {
							TextTransparency = 0.500,
						}):Play()

						Capturing = false
						if type(bindCfg.Callback) == "function" then
							task.spawn(bindCfg.Callback, CurrentBind)
						end
					end)

					AttachedKeybind = {
						Flag = bindCfg.Flag,
						GetValue = function()
							return CurrentBind
						end,
						SetValue = function(newindex, silent)
							UpdateBindDisplay(newindex)
							if BindActiveFlag then
								ConfigManager:Update(BindActiveFlag, CurrentBind)
							end
							if not silent and type(bindCfg.Callback) == "function" then
								task.spawn(bindCfg.Callback, CurrentBind)
							end
						end,
						Value = function(newindex, silent)
							AttachedKeybind:SetValue(newindex, silent)
						end,
						Visible = function(newindx)
							KeybindFrame.Visible = newindx
						end,
						Destroy = function()
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

				local function OnChange(value)
					value = value == true
					toggle.Default = value
					if Registered and ActiveFlag then
						ConfigManager:Update(ActiveFlag, value)
					end
					if value then

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
				end;

				OnChange(toggle.Default);

				Button.MouseButton1Click:Connect(function()
					OnChange(not toggle.Default);
					task.spawn(toggle.Callback,toggle.Default)
				end)

				local ToggleObject = {
					Flag = toggle.Flag,
					GetValue = function()
						return toggle.Default == true
					end,
					SetValue = function(newindex, silent)
						OnChange(newindex == true);
						if not silent then
							task.spawn(toggle.Callback,toggle.Default)
						end
					end,
					Value = function(newindex, silent)
						OnChange(newindex == true);
						if not silent then
							task.spawn(toggle.Callback,toggle.Default)
						end
					end,
					Visible = function(newindx)
						FunctionToggle.Visible = newindx
					end,
					NewKeybind = function(bindCfg)
						local handle = CreateAttachedKeybind(bindCfg)
						return handle
					end,
				}

				if toggle.Flag then
					ConfigManager:Register(toggle.Flag, ToggleObject)
					ActiveFlag = ToggleObject.Flag
				end
				Registered = true

				return ToggleObject
			end;

			function SectionTable:NewTitle(lrm)
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

				return {
					Visible = function(newindx)
						FunctionTitle.Visible = newindx
					end,
					Set = function(a)
						TextInt.Text = a
					end,
				};
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

				return {
					Visible = function(newindx)
						FunctionButton.Visible = newindx
					end,
					Fire = cfg.Callback
				};
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

				local IsWIP = false;
				local function UpdateUI(new)
					if new == "..." then
						Bindkey.Text = "..."
						local size = TextServ:GetTextSize(Bindkey.Text,Bindkey.TextSize,Bindkey.Font,Vector2.new(math.huge,math.huge));
						Twen:Create(System,TweenInfo.new(0.2),{
							Size = UDim2.new(0, size.X + 2, 0.600000024, 0)
						}):Play()
						return
					end

					ctfx.Default = ResolveKeybindValue(new, ctfx.Default)
					Bindkey.Text = FormatKeybindValue(ctfx.Default)
					if Registered and ActiveFlag then
						ConfigManager:Update(ActiveFlag, ctfx.Default)
					end

					local size = TextServ:GetTextSize(Bindkey.Text,Bindkey.TextSize,Bindkey.Font,Vector2.new(math.huge,math.huge));

					Twen:Create(System,TweenInfo.new(0.2),{
						Size = UDim2.new(0, size.X + 2, 0.600000024, 0)
					}):Play()
				end;

				UpdateUI(ctfx.Default)

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
					UpdateUI(Bind)

					IsWIP = false;
					if type(ctfx.Callback) == "function" then
						ctfx.Callback(ctfx.Default);
					end;


				end)

				local KeybindObject = {
						Flag = ctfx.Flag,
						GetValue = function()
							return ctfx.Default
						end,
						SetValue = function(value, silent)
							UpdateUI(value)
							if ActiveFlag then
								ConfigManager:Update(ActiveFlag, ctfx.Default)
							end
							if not silent and type(ctfx.Callback) == "function" then
								ctfx.Callback(ctfx.Default);
							end
						end,
					Visible = function(newindx)
						FunctionKeybind.Visible = newindx
					end,
					Value = function(lrm, silent)
						UpdateUI(lrm)
						if not silent and type(ctfx.Callback) == "function" then
							ctfx.Callback(ctfx.Default);
						end
					end,
				}

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

				UICorner_3.CornerRadius = UDim.new(0, 2)
				UICorner_3.Parent = TFrame

				UIStroke_2.Transparency = 0.975
				UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
				UIStroke_2.Parent = MFrame

				local Holding = false

				local function ApplyValue(value, silent)
					local Value = math.clamp(math.round(tonumber(value) or slider.Default), slider.Min, slider.Max)
					slider.Default = Value
					local SizeScale = (slider.Max == slider.Min) and 1 or ((Value - slider.Min) / (slider.Max - slider.Min))
					ValueText.Text = tostring(Value)..'/'..tostring(slider.Max)
					Twen:Create(TFrame,TweenInfo.new(0.1),{Size = UDim2.fromScale(SizeScale, 1)}):Play()
					if ActiveFlag then
						ConfigManager:Update(ActiveFlag, Value)
					end
					if not silent then
						slider.Callback(Value)
					end
				end

				local function update(Input)
					local SizeScale = math.clamp((((Input.Position.X) - MFrame.AbsolutePosition.X) / MFrame.AbsoluteSize.X), 0, 1)
					local Main = ((slider.Max - slider.Min) * SizeScale) + slider.Min;
					local Value = math.round(Main)
					ApplyValue(Value)
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

				local SliderObject = {
					Flag = slider.Flag,
					GetValue = function()
						return slider.Default
					end,
					SetValue = function(value, silent)
						ApplyValue(value, silent)
					end,
					Visible = function(newindx)
						FunctionSlider.Visible = newindx
					end,
					Value = function(lrm, silent)
						ApplyValue(lrm, silent)
					end,
				}

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

				local function ApplyValue(value, silent)
					drop.Default = NormalizeDropdownValue(drop.Data, value, drop.Multi)
					ValueText.Text = FormatDropdownValue(drop.Data, drop.Default, drop.Multi)
					if ActiveFlag then
						ConfigManager:Update(ActiveFlag, drop.Default)
					end
					if not silent then
						drop.Callback(drop.Default)
					end
				end

				local Updater = function(value)
					ApplyValue(value)
				end

				Button.MouseButton1Click:Connect(function()
					WindowTable.Dropdown:Setup(MFrame)

					WindowTable.Dropdown:Open(drop.Data,drop.Default,Updater,drop.Multi)
				end)

				local DropdownObject = {
					Flag = drop.Flag,
					GetValue = function()
						return drop.Default
					end,
					SetValue = function(value, silent)
						ApplyValue(value, silent)
					end,
					Visible = function(newindx)
						FunctionDropdown.Visible = newindx
					end,
					Value = function(value, silent)
						ApplyValue(value, silent)
					end,
					Open = function(value)
						WindowTable.Dropdown:Setup(MFrame)

						WindowTable.Dropdown:Open(drop.Data,drop.Default,Updater,drop.Multi)
					end,

					Close = function(value)
						WindowTable.Dropdown:Close();
					end,
					Clear = function()
						drop.Data = {}
						ApplyValue(drop.Multi and {} or nil, true)
					end,
					Set = function(table)
						drop.Data = table
						drop.Default = NormalizeDropdownValue(drop.Data, drop.Default, drop.Multi)
						ValueText.Text = FormatDropdownValue(drop.Data, drop.Default, drop.Multi)
						if drop.Flag then
							ConfigManager:Update(drop.Flag, drop.Default)
						end
					end
				}

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
				local CurrentValue = nil

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

					if type(value) == "number" then
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

					local text = tostring(value or "")
					return text, text
				end

				local function ApplyValue(value, silent)
					local resolvedValue, resolvedText = ResolveTextboxValue(value)
					CurrentValue = resolvedValue
					conf.Default = resolvedValue
					SetText(resolvedText)
					if ActiveFlag then
						ConfigManager:Update(ActiveFlag, resolvedValue)
					end
					if not silent and type(conf.Callback) == "function" then
						conf.Callback(resolvedValue)
					end
				end

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

				TextBox.FocusLost:Connect(function()
					ApplyValue(TextBox.Text, false)
				end)

				ApplyValue(conf.Default, true)

				local TextboxObject = {
					Flag = conf.Flag,
					GetValue = function()
						return CurrentValue
					end,
					SetValue = function(value, silent)
						ApplyValue(value, silent)
					end,
					Value = function(value, silent)
						ApplyValue(value, silent)
					end,
					Visible = function(newindx)
						FunctionTextbox.Visible = newindx
					end,
					Destroy = function()
						FunctionTextbox:Destroy()
					end,
				}

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
		ConfigManager.Folder = NormalizePath(folder) ~= "" and NormalizePath(folder) or Library._ConfigDefaults.Folder
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

	Library._LastWindow = WindowTable

	return WindowTable;
end;

function Library:SetFolder(folder)
	local window = self and self.ConfigManager and self or Library._LastWindow
	if window and window.ConfigManager then
		return window:SetFolder(folder)
	end

	Library._ConfigDefaults.Folder = NormalizePath(folder) ~= "" and NormalizePath(folder) or Library._ConfigDefaults.Folder
end

function Library:SetSubFolder(subfolder)
	local window = self and self.ConfigManager and self or Library._LastWindow
	if window and window.ConfigManager then
		return window:SetSubFolder(subfolder)
	end

	Library._ConfigDefaults.SubFolder = NormalizeSubFolderPath(Library._ConfigDefaults.Folder, subfolder)
end

function Library:AddSettingsTab()
	local window = self and self.ConfigManager and self or Library._LastWindow
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
