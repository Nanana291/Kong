local Loader = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

local Theme = {
    Ink = Color3.fromRGB(6, 8, 13),
    InkSoft = Color3.fromRGB(11, 13, 20),
    Panel = Color3.fromRGB(12, 14, 21),
    PanelDeep = Color3.fromRGB(7, 9, 14),
    PanelBlue = Color3.fromRGB(22, 28, 44),
    Text = Color3.fromRGB(238, 240, 250),
    TextDim = Color3.fromRGB(135, 141, 160),
    TextMuted = Color3.fromRGB(78, 84, 104),
    Line = Color3.fromRGB(57, 62, 83),
    LineSoft = Color3.fromRGB(35, 39, 55),
    Accent = Color3.fromRGB(149, 159, 255),
    AccentHot = Color3.fromRGB(180, 188, 255),
    AccentDeep = Color3.fromRGB(95, 107, 188),
    Success = Color3.fromRGB(112, 229, 170),
    Error = Color3.fromRGB(255, 103, 123),
    Warning = Color3.fromRGB(255, 207, 120),
}

local TweenInfoSet = {
    Open = TweenInfo.new(0.52, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Close = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
    Soft = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Toast = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    ToastOut = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
}

local State = {
    Destroyed = false,
    Open = true,
    Validating = false,
    Title = "KRONOS",
    Version = "",
    KeyLink = "https://imphub.vercel.app/GetKeyAccess",
    ValidateCallback = nil,
    ExpiryToken = 0,
    Connections = {},
    Tweens = {},
    Toasts = {},
    ToastQueue = {},
    ScaleTarget = 1,
    Center = nil,
    WasDragged = false,
    LoadingTick = 0,
    Drag = {
        Active = false,
        Input = nil,
        StartPointer = Vector2.zero,
        StartCenter = Vector2.zero,
        TargetCenter = Vector2.zero,
        CurrentCenter = Vector2.zero,
        Velocity = Vector2.zero,
        LastPointer = Vector2.zero,
        LastTime = 0,
    },
}

local UI = {}
local BASE_SIZE = Vector2.new(980, 582)
local SAFE_PAD = 18

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    State.Connections[#State.Connections + 1] = connection
    return connection
end

local function disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function new(className, props)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        if key ~= "Parent" then
            object[key] = value
        end
    end
    if props and props.Parent then
        object.Parent = props.Parent
    end
    return object
end

local function corner(parent, radius)
    return new("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent,
    })
end

local function stroke(parent, color, thickness, transparency)
    return new("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        Parent = parent,
    })
end

local function gradient(parent, colorSequence, rotation, transparency)
    return new("UIGradient", {
        Color = colorSequence,
        Rotation = rotation or 0,
        Transparency = transparency or NumberSequence.new(0),
        Parent = parent,
    })
end

local function tween(object, info, properties)
    if State.Destroyed or not object or not object.Parent then
        return nil
    end
    local ok, created = pcall(TweenService.Create, TweenService, object, info, properties)
    if ok and created then
        State.Tweens[#State.Tweens + 1] = created
        created.Completed:Once(function()
            local index = table.find(State.Tweens, created)
            if index then
                table.remove(State.Tweens, index)
            end
        end)
        created:Play()
        return created
    end
    for key, value in pairs(properties) do
        pcall(function()
            object[key] = value
        end)
    end
    return nil
end

local function cancelTween(tweenObject)
    if tweenObject then
        pcall(function()
            tweenObject:Cancel()
        end)
    end
end

local function getViewport()
    local camera = workspace.CurrentCamera
    if camera and camera.ViewportSize.X > 0 and camera.ViewportSize.Y > 0 then
        return camera.ViewportSize
    end
    if UI.Root and UI.Root.AbsoluteSize.X > 0 and UI.Root.AbsoluteSize.Y > 0 then
        return UI.Root.AbsoluteSize
    end
    return Vector2.new(1920, 1080)
end

local function clampCenter(center)
    local viewport = getViewport()
    local scale = State.ScaleTarget
    local visual = BASE_SIZE * scale
    local minX = visual.X * 0.5 + SAFE_PAD
    local maxX = viewport.X - visual.X * 0.5 - SAFE_PAD
    local minY = visual.Y * 0.5 + SAFE_PAD
    local maxY = viewport.Y - visual.Y * 0.5 - SAFE_PAD

    local x = viewport.X * 0.5
    local y = viewport.Y * 0.5

    if maxX > minX then
        x = math.clamp(center.X, minX, maxX)
    end
    if maxY > minY then
        y = math.clamp(center.Y, minY, maxY)
    end

    return Vector2.new(x, y)
end

local function applyWindowPosition(center)
    State.Center = clampCenter(center)
    State.Drag.CurrentCenter = State.Center
    State.Drag.TargetCenter = State.Center
    if UI.WindowHost then
        UI.WindowHost.Position = UDim2.fromOffset(State.Center.X, State.Center.Y)
    end
end

local function updateScale()
    if not UI.WindowScale then
        return
    end

    local viewport = getViewport()
    local pad = UserInputService.TouchEnabled and 12 or 32
    local usableX = math.max(viewport.X - pad * 2, 240)
    local usableY = math.max(viewport.Y - pad * 2, 180)
    local maxScale = UserInputService.TouchEnabled and not UserInputService.MouseEnabled and 0.94 or 1
    local scale = math.min(usableX / BASE_SIZE.X, usableY / BASE_SIZE.Y, maxScale)
    State.ScaleTarget = math.clamp(scale, 0.285, maxScale)
    UI.WindowScale.Scale = State.ScaleTarget

    if not State.Center or not State.WasDragged then
        applyWindowPosition(Vector2.new(viewport.X * 0.5, viewport.Y * 0.5))
    else
        applyWindowPosition(State.Center)
    end
end

local function setParent(screenGui)
    local parented = pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)
    if parented then
        return
    end

    local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui and LocalPlayer then
        playerGui = LocalPlayer:WaitForChild("PlayerGui", 8)
    end
    if playerGui then
        parented = pcall(function()
            screenGui.Parent = playerGui
        end)
    end
    if not parented then
        pcall(function()
            screenGui.Parent = game:GetService("CoreGui")
        end)
    end
end

local function buildNoise(parent, zIndex, dotCount)
    local layer = new("Frame", {
        Name = "Noise Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = zIndex,
        Parent = parent,
    })
    corner(layer, 12)

    for index = 1, dotCount do
        local x = ((index * 47) % 997) / 997
        local y = ((index * 83) % 991) / 991
        local alpha = 0.9 + (((index * 19) % 7) * 0.01)
        new("Frame", {
            Name = "NoiseDot",
            Size = UDim2.fromOffset(1, 1),
            Position = UDim2.fromScale(x, y),
            BackgroundColor3 = index % 3 == 0 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1),
            BackgroundTransparency = alpha,
            BorderSizePixel = 0,
            ZIndex = zIndex,
            Parent = layer,
        })
    end

    return layer
end

local function createAcrylic(parent, zIndex, radius, tint, tintTransparency)
    local background = new("Frame", {
        Name = "Background Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Ink,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = zIndex,
        Parent = parent,
    })
    corner(background, radius)

    local blur = new("Frame", {
        Name = "Blur Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.PanelBlue,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        ZIndex = zIndex + 1,
        Parent = parent,
    })
    corner(blur, radius)
    gradient(
        blur,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 38, 58)),
            ColorSequenceKeypoint.new(0.52, Color3.fromRGB(12, 14, 22)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 4, 8)),
        }),
        22,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.12),
            NumberSequenceKeypoint.new(1, 0.45),
        })
    )

    local tintLayer = new("Frame", {
        Name = "Tint Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = tint or Theme.Panel,
        BackgroundTransparency = tintTransparency or 0.58,
        BorderSizePixel = 0,
        ZIndex = zIndex + 2,
        Parent = parent,
    })
    corner(tintLayer, radius)

    local noise = buildNoise(parent, zIndex + 3, 130)

    local highlight = new("Frame", {
        Name = "Highlight Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        ZIndex = zIndex + 4,
        Parent = parent,
    })
    corner(highlight, radius)
    gradient(
        highlight,
        ColorSequence.new(Color3.new(1, 1, 1), Theme.Accent),
        -34,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.83),
            NumberSequenceKeypoint.new(0.44, 0.98),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local glow = new("Frame", {
        Name = "Glow Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = zIndex + 5,
        Parent = parent,
    })
    corner(glow, radius)
    gradient(
        glow,
        ColorSequence.new(Theme.AccentHot, Theme.Ink),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.72),
            NumberSequenceKeypoint.new(0.58, 1),
            NumberSequenceKeypoint.new(1, 0.9),
        })
    )

    local border = stroke(parent, Color3.fromRGB(57, 64, 92), 1, 0.36)
    border.Name = "Border Layer"

    return {
        Background = background,
        Blur = blur,
        Tint = tintLayer,
        Noise = noise,
        Highlight = highlight,
        Glow = glow,
        Border = border,
    }
end

local function clearChildren(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

local function buildWordmark(parent, text, options)
    local holder = new("Frame", {
        Name = options.Name or "Wordmark",
        Size = options.Size,
        Position = options.Position,
        AnchorPoint = options.AnchorPoint or Vector2.zero,
        BackgroundTransparency = 1,
        ZIndex = options.ZIndex,
        Parent = parent,
    })

    local layout = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = options.HorizontalAlignment or Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, options.Padding or 10),
        Parent = holder,
    })

    local function render(newText)
        clearChildren(holder)
        layout.Parent = holder
        local order = 0
        for index = 1, #newText do
            local char = string.sub(newText, index, index)
            order += 1
            if char == " " then
                new("Frame", {
                    Name = "Gap",
                    Size = UDim2.fromOffset(options.SpaceWidth or 10, 1),
                    BackgroundTransparency = 1,
                    LayoutOrder = order,
                    ZIndex = options.ZIndex,
                    Parent = holder,
                })
            else
                local accentStart = math.max(2, math.floor(#newText * 0.42))
                local accentEnd = math.min(#newText, accentStart + 2)
                new("TextLabel", {
                    Name = "Letter_" .. char,
                    Size = UDim2.fromOffset(options.LetterWidth or 24, options.TextSize + 8),
                    BackgroundTransparency = 1,
                    Text = string.upper(char),
                    TextColor3 = index >= accentStart and index <= accentEnd and Theme.AccentHot or Theme.Text,
                    TextTransparency = options.TextTransparency or 0,
                    TextSize = options.TextSize,
                    Font = options.Font or Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    LayoutOrder = order,
                    ZIndex = options.ZIndex,
                    Parent = holder,
                })
            end
        end
    end

    render(text)
    return holder, render
end

local function letterSpaced(text)
    local parts = {}
    for index = 1, #text do
        parts[#parts + 1] = string.sub(text, index, index)
    end
    return table.concat(parts, "  ")
end

local function createTinyUserIcon(parent, zIndex)
    local holder = new("Frame", {
        Name = "UserIcon",
        Size = UDim2.fromOffset(24, 24),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -15, 0.5, 0),
        BackgroundTransparency = 1,
        ZIndex = zIndex,
        Parent = parent,
    })
    local head = new("Frame", {
        Size = UDim2.fromOffset(8, 8),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromOffset(12, 5),
        BackgroundColor3 = Theme.TextMuted,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = zIndex,
        Parent = holder,
    })
    corner(head, 8)
    local body = new("Frame", {
        Size = UDim2.fromOffset(15, 7),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromOffset(12, 20),
        BackgroundColor3 = Theme.TextMuted,
        BackgroundTransparency = 0.48,
        BorderSizePixel = 0,
        ZIndex = zIndex,
        Parent = holder,
    })
    corner(body, 7)
    return holder
end

local function createTinyKeyIcon(parent, zIndex)
    local holder = new("Frame", {
        Name = "KeyIcon",
        Size = UDim2.fromOffset(24, 24),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -15, 0.5, 0),
        BackgroundTransparency = 1,
        ZIndex = zIndex,
        Rotation = -25,
        Parent = parent,
    })
    local ring = new("Frame", {
        Size = UDim2.fromOffset(9, 9),
        Position = UDim2.fromOffset(4, 7),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = zIndex,
        Parent = holder,
    })
    corner(ring, 9)
    stroke(ring, Theme.TextMuted, 2, 0.35)
    local stem = new("Frame", {
        Size = UDim2.fromOffset(11, 2),
        Position = UDim2.fromOffset(12, 11),
        BackgroundColor3 = Theme.TextMuted,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = zIndex,
        Parent = holder,
    })
    corner(stem, 2)
    new("Frame", {
        Size = UDim2.fromOffset(2, 5),
        Position = UDim2.fromOffset(19, 12),
        BackgroundColor3 = Theme.TextMuted,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = zIndex,
        Parent = holder,
    })
    return holder
end

local function setStatus(kind, message)
    if not UI.StatusText then
        return
    end
    local color = Theme.TextDim
    if kind == "success" then
        color = Theme.Success
    elseif kind == "error" then
        color = Theme.Error
    elseif kind == "loading" then
        color = Theme.AccentHot
    elseif kind == "warning" then
        color = Theme.Warning
    end
    UI.StatusText.Text = message or "Status"
    UI.StatusText.TextColor3 = color
    if UI.StatusLine then
        tween(
            UI.StatusLine,
            TweenInfoSet.Soft,
            { BackgroundColor3 = color, BackgroundTransparency = kind == "idle" and 0.74 or 0.34 }
        )
    end
end

local function setInputLocked(locked)
    if UI.KeyBox then
        pcall(function()
            UI.KeyBox.TextEditable = not locked
        end)
        UI.KeyBox.Active = not locked
    end
    if UI.ValidateButton then
        UI.ValidateButton.Active = not locked
    end
    if UI.GetKeyButton then
        UI.GetKeyButton.Active = not locked
    end
end

local function startLoadingVisual()
    if UI.LoadingDot then
        UI.LoadingDot.Visible = true
    end
    if UI.ValidateLabel then
        UI.ValidateLabel.Text = "Validating"
    end
    disconnect(State.LoadingConnection)
    State.LoadingConnection = connect(RunService.RenderStepped, function(dt)
        State.LoadingTick += dt
        if UI.LoadingDot then
            UI.LoadingDot.Rotation = (State.LoadingTick * 220) % 360
            UI.LoadingDot.BackgroundTransparency = 0.18 + math.sin(State.LoadingTick * 6) * 0.08
        end
    end)
end

local function stopLoadingVisual()
    disconnect(State.LoadingConnection)
    State.LoadingConnection = nil
    if UI.LoadingDot then
        UI.LoadingDot.Visible = false
    end
    if UI.ValidateLabel then
        UI.ValidateLabel.Text = "Validate"
    end
end

local function shake(object)
    if not object then
        return
    end
    local original = object.Position
    task.spawn(function()
        for _, offset in ipairs({ -8, 8, -5, 5, 0 }) do
            if State.Destroyed or not object.Parent then
                return
            end
            tween(object, TweenInfo.new(0.045, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = original + UDim2.fromOffset(offset, 0),
            })
            task.wait(0.045)
        end
        if object.Parent then
            object.Position = original
        end
    end)
end

local function reflowToasts()
    for index, toast in ipairs(State.Toasts) do
        if toast.Gui and toast.Gui.Parent then
            tween(toast.Gui, TweenInfoSet.Toast, {
                Position = UDim2.new(1, -24, 0, 22 + (index - 1) * 92),
            })
        end
    end
end

local function removeToast(toast)
    local foundIndex = table.find(State.Toasts, toast)
    if foundIndex then
        table.remove(State.Toasts, foundIndex)
    end
    if toast.Gui and toast.Gui.Parent then
        local outTween = tween(toast.Gui, TweenInfoSet.ToastOut, {
            Position = toast.Gui.Position + UDim2.fromOffset(32, 0),
            GroupTransparency = 1,
        })
        if outTween then
            outTween.Completed:Once(function()
                if toast.Gui then
                    toast.Gui:Destroy()
                end
            end)
        else
            toast.Gui:Destroy()
        end
    end
    reflowToasts()

    local nextConfig = table.remove(State.ToastQueue, 1)
    if nextConfig then
        task.defer(function()
            Loader:Toast(nextConfig)
        end)
    end
end

local function toastColor(toastType)
    if toastType == "success" then
        return Theme.Success, "✓"
    elseif toastType == "error" then
        return Theme.Error, "!"
    elseif toastType == "warning" then
        return Theme.Warning, "!"
    elseif toastType == "loading" then
        return Theme.AccentHot, "…"
    end
    return Theme.AccentHot, "i"
end

local function createButton(parent, name, text, position, size, primary, callback)
    local button = new("TextButton", {
        Name = name,
        Position = position,
        Size = size,
        AutoButtonColor = false,
        BackgroundColor3 = primary and Theme.AccentDeep or Theme.PanelDeep,
        BackgroundTransparency = primary and 0 or 0.42,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 48,
        Parent = parent,
    })
    corner(button, primary and 24 or 18)
    local buttonStroke = stroke(button, primary and Theme.AccentHot or Theme.LineSoft, 1, primary and 0.58 or 0.48)
    local scale = new("UIScale", { Scale = 1, Parent = button })
    if primary then
        gradient(
            button,
            ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(121, 139, 220)),
                ColorSequenceKeypoint.new(0.46, Color3.fromRGB(151, 162, 245)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(118, 128, 214)),
            }),
            0,
            NumberSequence.new(0)
        )
    end

    local label = new("TextLabel", {
        Name = "Label",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = primary and Color3.fromRGB(249, 250, 255) or Theme.AccentHot,
        TextTransparency = primary and 0.03 or 0.14,
        Font = Enum.Font.GothamMedium,
        TextSize = primary and 15 or 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 49,
        Parent = button,
    })

    local arrow = new("TextLabel", {
        Name = "Arrow",
        Size = UDim2.fromOffset(28, 20),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -88, 0.5, 0),
        BackgroundTransparency = 1,
        Text = "→",
        TextColor3 = primary and Color3.fromRGB(246, 247, 255) or Theme.AccentHot,
        TextTransparency = primary and 0.12 or 0.25,
        Font = Enum.Font.GothamMedium,
        TextSize = primary and 22 or 16,
        ZIndex = 49,
        Parent = button,
    })
    if not primary then
        arrow.Visible = false
    end

    connect(button.MouseEnter, function()
        if not button.Active then
            return
        end
        tween(scale, TweenInfoSet.Fast, { Scale = 1.018 })
        tween(buttonStroke, TweenInfoSet.Fast, { Transparency = primary and 0.26 or 0.18 })
        tween(button, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0 or 0.24 })
    end)
    connect(button.MouseLeave, function()
        tween(scale, TweenInfoSet.Fast, { Scale = 1 })
        tween(buttonStroke, TweenInfoSet.Fast, { Transparency = primary and 0.58 or 0.48 })
        tween(button, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0 or 0.42 })
    end)
    connect(button.MouseButton1Down, function()
        if button.Active then
            tween(scale, TweenInfoSet.Fast, { Scale = 0.975 })
        end
    end)
    connect(button.MouseButton1Up, function()
        if button.Active then
            tween(scale, TweenInfoSet.Fast, { Scale = 1.012 })
        end
    end)
    connect(button.MouseButton1Click, callback)

    return button, label
end

local function openKeyLink()
    local url = State.KeyLink
    if type(url) ~= "string" or url == "" then
        setStatus("error", "Key link unavailable")
        Loader:Toast({
            Type = "error",
            Title = "No Key Link",
            Subtitle = "A key link has not been configured",
            Duration = 3,
        })
        return
    end

    local opened = false
    pcall(function()
        GuiService:OpenBrowserWindow(url)
        opened = true
    end)
    if not opened then
        pcall(function()
            if typeof(setclipboard) == "function" then
                setclipboard(url)
                opened = true
            elseif typeof(toclipboard) == "function" then
                toclipboard(url)
                opened = true
            end
        end)
    end

    if opened then
        setStatus("success", "Key link opened")
        Loader:Toast({
            Type = "success",
            Title = "Key Link Ready",
            Subtitle = "Browser opened or link copied",
            Duration = 2.5,
        })
    else
        setStatus("warning", url)
        Loader:Toast({ Type = "warning", Title = "Copy Key Link", Subtitle = url, Duration = 5 })
    end
end

local function finishValidation(success, message)
    State.Validating = false
    setInputLocked(false)
    stopLoadingVisual()
    if success then
        setStatus("success", message or "Welcome back!")
        Loader:Toast({
            Type = "success",
            Icon = "shield-check",
            Title = "Key Accepted",
            Subtitle = message or "Welcome back",
            Duration = 3,
        })
        if UI.WindowAcrylic and UI.WindowAcrylic.Border then
            tween(UI.WindowAcrylic.Border, TweenInfoSet.Soft, { Color = Theme.Success, Transparency = 0.32 })
        end
    else
        setStatus("error", message or "Validation failed")
        Loader:Toast({
            Type = "error",
            Title = "Key Rejected",
            Subtitle = message or "Validation failed",
            Duration = 3.5,
        })
        shake(UI.FormGroup)
        if UI.WindowAcrylic and UI.WindowAcrylic.Border then
            tween(UI.WindowAcrylic.Border, TweenInfoSet.Soft, { Color = Theme.Error, Transparency = 0.28 })
            task.delay(0.7, function()
                if not State.Destroyed and UI.WindowAcrylic and UI.WindowAcrylic.Border then
                    tween(
                        UI.WindowAcrylic.Border,
                        TweenInfoSet.Soft,
                        { Color = Color3.fromRGB(57, 64, 92), Transparency = 0.36 }
                    )
                end
            end)
        end
    end
end

local function validateKey()
    if State.Validating or State.Destroyed then
        return
    end
    local key = UI.KeyBox and UI.KeyBox.Text or ""
    key = tostring(key):gsub("^%s+", ""):gsub("%s+$", "")
    if key == "" then
        setStatus("error", "Enter your key first")
        shake(UI.FormGroup)
        Loader:Toast({
            Type = "error",
            Title = "Missing Key",
            Subtitle = "Enter a key before validating",
            Duration = 2.5,
        })
        return
    end
    if type(State.ValidateCallback) ~= "function" then
        setStatus("error", "Validator unavailable")
        Loader:Toast({
            Type = "error",
            Title = "Validator Missing",
            Subtitle = "SetOnValidate has not been configured",
            Duration = 3,
        })
        return
    end

    State.Validating = true
    setInputLocked(true)
    setStatus("loading", "Validating key...")
    startLoadingVisual()

    task.spawn(function()
        local ok, accepted, resultMessage = pcall(State.ValidateCallback, key)
        if State.Destroyed then
            return
        end
        if not ok then
            finishValidation(false, tostring(accepted or "Validation error"))
        else
            finishValidation(
                accepted == true,
                tostring(resultMessage or (accepted and "Welcome back!" or "Validation failed"))
            )
        end
    end)
end

local function setWordmark(text)
    State.Title = tostring(text or "KRONOS")
    if UI.RenderLeftWordmark then
        UI.RenderLeftWordmark(State.Title)
    end
    if UI.RenderRightWordmark then
        UI.RenderRightWordmark(State.Title)
    end
end

local function pointInObject(guiObject, point)
    if not guiObject or not guiObject.Parent then
        return false
    end
    local pos = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function beginDrag(input)
    if State.Destroyed or State.Validating then
        return
    end
    local inputType = input.UserInputType
    if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
        return
    end
    local point = Vector2.new(input.Position.X, input.Position.Y)
    if
        pointInObject(UI.KeyField, point)
        or pointInObject(UI.StatusField, point)
        or pointInObject(UI.ValidateButton, point)
        or pointInObject(UI.GetKeyButton, point)
    then
        return
    end

    State.WasDragged = true
    State.Drag.Active = true
    State.Drag.Input = input
    State.Drag.StartPointer = Vector2.new(input.Position.X, input.Position.Y)
    State.Drag.StartCenter = State.Center or Vector2.new(getViewport().X * 0.5, getViewport().Y * 0.5)
    State.Drag.TargetCenter = State.Drag.StartCenter
    State.Drag.CurrentCenter = State.Drag.StartCenter
    State.Drag.LastPointer = State.Drag.StartPointer
    State.Drag.LastTime = os.clock()
    State.Drag.Velocity = Vector2.zero

    local releaseConnection
    releaseConnection = input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            State.Drag.Active = false
            disconnect(releaseConnection)
        end
    end)
end

local function updateDragInput(input)
    if not State.Drag.Active then
        return
    end
    local inputType = input.UserInputType
    if inputType ~= Enum.UserInputType.MouseMovement and inputType ~= Enum.UserInputType.Touch then
        return
    end
    local pointer = Vector2.new(input.Position.X, input.Position.Y)
    local delta = pointer - State.Drag.StartPointer
    local now = os.clock()
    local dt = math.max(now - State.Drag.LastTime, 1 / 240)
    State.Drag.Velocity = (pointer - State.Drag.LastPointer) / dt
    State.Drag.LastPointer = pointer
    State.Drag.LastTime = now
    State.Drag.TargetCenter = clampCenter(State.Drag.StartCenter + delta)
end

local function updateDrag(dt)
    if State.Destroyed or not UI.Window then
        return
    end
    local drag = State.Drag
    local alpha = 1 - math.exp(-dt * (drag.Active and 34 or 22))

    if not drag.Active and drag.Velocity.Magnitude > 8 then
        drag.TargetCenter = clampCenter(drag.TargetCenter + drag.Velocity * dt * 0.42)
        drag.Velocity *= math.exp(-dt * 8.5)
    end

    drag.CurrentCenter = drag.CurrentCenter:Lerp(drag.TargetCenter, alpha)
    State.Center = clampCenter(drag.CurrentCenter)
    UI.WindowHost.Position = UDim2.fromOffset(State.Center.X, State.Center.Y)
end

local function createField(parent, name, y, isInput)
    local field = new("Frame", {
        Name = name,
        Size = UDim2.fromOffset(270, 54),
        Position = UDim2.fromOffset(122, y),
        BackgroundColor3 = Color3.fromRGB(4, 6, 10),
        BackgroundTransparency = 0.76,
        BorderSizePixel = 0,
        ZIndex = 42,
        Parent = parent,
    })
    corner(field, 6)

    local line = new("Frame", {
        Name = "BottomLine",
        Size = UDim2.new(1, -20, 0, 1),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -6),
        BackgroundColor3 = Theme.LineSoft,
        BackgroundTransparency = 0.42,
        BorderSizePixel = 0,
        ZIndex = 43,
        Parent = field,
    })

    local caption = new("TextLabel", {
        Name = "Caption",
        Size = UDim2.new(1, -58, 0, 18),
        Position = UDim2.fromOffset(18, 7),
        BackgroundTransparency = 1,
        Text = isInput and "Enter Key" or "Status",
        TextColor3 = Theme.TextMuted,
        TextTransparency = 0.18,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 44,
        Parent = field,
    })

    if isInput then
        local box = new("TextBox", {
            Name = "Input",
            Size = UDim2.new(1, -68, 0, 24),
            Position = UDim2.fromOffset(18, 25),
            BackgroundTransparency = 1,
            ClearTextOnFocus = false,
            Text = "",
            PlaceholderText = "Enter your key...",
            PlaceholderColor3 = Color3.fromRGB(75, 81, 102),
            TextColor3 = Theme.Text,
            TextTransparency = 0.08,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 45,
            Parent = field,
        })
        createTinyUserIcon(field, 45)
        connect(box.Focused, function()
            tween(line, TweenInfoSet.Soft, { BackgroundColor3 = Theme.AccentHot, BackgroundTransparency = 0.16 })
            tween(field, TweenInfoSet.Soft, { BackgroundTransparency = 0.62 })
        end)
        connect(box.FocusLost, function(enterPressed)
            tween(line, TweenInfoSet.Soft, { BackgroundColor3 = Theme.LineSoft, BackgroundTransparency = 0.42 })
            tween(field, TweenInfoSet.Soft, { BackgroundTransparency = 0.76 })
            if enterPressed then
                validateKey()
            end
        end)
        return field, box, line, caption
    end

    local value = new("TextLabel", {
        Name = "Value",
        Size = UDim2.new(1, -68, 0, 24),
        Position = UDim2.fromOffset(18, 25),
        BackgroundTransparency = 1,
        Text = "Status",
        TextColor3 = Theme.TextDim,
        TextTransparency = 0.12,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 45,
        Parent = field,
    })
    createTinyKeyIcon(field, 45)
    return field, value, line, caption
end

local function createShadow(parent)
    for index = 1, 5 do
        local spread = 8 + index * 9
        local shadow = new("Frame", {
            Name = "SoftShadow",
            Size = UDim2.new(1, spread, 1, spread),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 4 + index * 2),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.86 + index * 0.018,
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = parent,
        })
        corner(shadow, 16 + index * 4)
    end
end

local function buildInterface()
    UI.ScreenGui = new("ScreenGui", {
        Name = "KRONOS_KeySystem",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    setParent(UI.ScreenGui)

    UI.Blur = new("BlurEffect", {
        Name = "KRONOS_AcrylicBlur",
        Size = 0,
        Parent = Lighting,
    })
    tween(UI.Blur, TweenInfoSet.Open, { Size = 10 })

    UI.Root = new("Frame", {
        Name = "Root",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.44,
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = UI.ScreenGui,
    })
    gradient(
        UI.Root,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 8, 14)),
            ColorSequenceKeypoint.new(0.45, Color3.fromRGB(8, 10, 16)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(1, 2, 5)),
        }),
        18,
        NumberSequence.new(0)
    )

    UI.AmbientLeft = new("Frame", {
        Name = "AmbientLightingLeft",
        Size = UDim2.fromOffset(560, 560),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.28, 0.44),
        BackgroundColor3 = Theme.AccentDeep,
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = UI.Root,
    })
    corner(UI.AmbientLeft, 560)
    UI.AmbientRight = new("Frame", {
        Name = "AmbientLightingRight",
        Size = UDim2.fromOffset(440, 440),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.74, 0.42),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = UI.Root,
    })
    corner(UI.AmbientRight, 440)

    UI.WindowHost = new("Frame", {
        Name = "WindowHost",
        Size = UDim2.fromOffset(BASE_SIZE.X, BASE_SIZE.Y),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = UI.Root,
    })
    createShadow(UI.WindowHost)

    UI.Window = new("CanvasGroup", {
        Name = "Window",
        Size = UDim2.fromOffset(BASE_SIZE.X, BASE_SIZE.Y),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Theme.Ink,
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 8,
        Parent = UI.WindowHost,
    })
    corner(UI.Window, 12)
    UI.WindowScale = new("UIScale", { Scale = 1, Parent = UI.WindowHost })
    UI.WindowAcrylic = createAcrylic(UI.Window, 8, 12, Theme.Panel, 0.52)

    UI.LeftPanel = new("Frame", {
        Name = "LeftPanel",
        Size = UDim2.new(0, 490, 1, 0),
        BackgroundColor3 = Theme.InkSoft,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 20,
        Parent = UI.Window,
    })
    createAcrylic(UI.LeftPanel, 20, 12, Color3.fromRGB(7, 10, 18), 0.48)

    UI.SplitLine = new("Frame", {
        Name = "PanelSplit",
        Size = UDim2.new(0, 1, 1, -34),
        Position = UDim2.fromOffset(490, 17),
        BackgroundColor3 = Color3.fromRGB(18, 23, 36),
        BackgroundTransparency = 0.36,
        BorderSizePixel = 0,
        ZIndex = 38,
        Parent = UI.Window,
    })

    UI.RightPanel = new("Frame", {
        Name = "RightPanel",
        Size = UDim2.new(1, -490, 1, 0),
        Position = UDim2.fromOffset(490, 0),
        BackgroundColor3 = Color3.fromRGB(5, 7, 12),
        BackgroundTransparency = 0.26,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 30,
        Parent = UI.Window,
    })
    createAcrylic(UI.RightPanel, 30, 12, Color3.fromRGB(5, 7, 12), 0.34)

    for index, spec in ipairs({
        { 90, 125, 160, 0.9 },
        { 320, 155, 74, 0.92 },
        { 360, 386, 118, 0.93 },
    }) do
        local orb = new("Frame", {
            Name = "AcrylicOrb",
            Size = UDim2.fromOffset(spec[3], spec[3]),
            Position = UDim2.fromOffset(spec[1], spec[2]),
            BackgroundColor3 = Color3.fromRGB(82, 101, 150),
            BackgroundTransparency = spec[4],
            BorderSizePixel = 0,
            ZIndex = 35 + index,
            Parent = UI.LeftPanel,
        })
        corner(orb, spec[3])
    end

    local leftWordmark, leftRender = buildWordmark(UI.LeftPanel, State.Title, {
        Name = "LeftWordmark",
        Size = UDim2.fromOffset(340, 58),
        Position = UDim2.fromOffset(245, 300),
        AnchorPoint = Vector2.new(0.5, 0.5),
        TextSize = 35,
        LetterWidth = 26,
        Padding = 15,
        SpaceWidth = 18,
        ZIndex = 62,
    })
    UI.LeftWordmark = leftWordmark
    UI.RenderLeftWordmark = leftRender

    UI.Powered = new("TextLabel", {
        Name = "Powered",
        Size = UDim2.fromOffset(350, 30),
        Position = UDim2.fromOffset(42, 538),
        BackgroundTransparency = 1,
        Text = letterSpaced("Powered by Delta"),
        TextColor3 = Theme.TextDim,
        TextTransparency = 0.48,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 62,
        Parent = UI.LeftPanel,
    })

    UI.VersionLabel = new("TextLabel", {
        Name = "Version",
        Size = UDim2.fromOffset(140, 24),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -34, 1, -20),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Theme.TextMuted,
        TextTransparency = 0.35,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Visible = false,
        ZIndex = 62,
        Parent = UI.LeftPanel,
    })

    local rightWordmark, rightRender = buildWordmark(UI.RightPanel, State.Title, {
        Name = "RightWordmark",
        Size = UDim2.fromOffset(330, 48),
        Position = UDim2.fromOffset(255, 90),
        AnchorPoint = Vector2.new(0.5, 0.5),
        TextSize = 30,
        LetterWidth = 23,
        Padding = 12,
        SpaceWidth = 16,
        ZIndex = 64,
    })
    UI.RightWordmark = rightWordmark
    UI.RenderRightWordmark = rightRender

    UI.Subtitle = new("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.fromOffset(370, 28),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromOffset(255, 128),
        BackgroundTransparency = 1,
        Text = letterSpaced("Secure Access Validation"),
        TextColor3 = Theme.TextDim,
        TextTransparency = 0.48,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 64,
        Parent = UI.RightPanel,
    })

    UI.FormGroup = new("Frame", {
        Name = "FormGroup",
        Size = UDim2.fromOffset(490, 330),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        ZIndex = 40,
        Parent = UI.RightPanel,
    })

    UI.KeyField, UI.KeyBox = createField(UI.FormGroup, "EnterKeyField", 206, true)
    UI.StatusField, UI.StatusText, UI.StatusLine = createField(UI.FormGroup, "StatusField", 274, false)

    UI.ValidateButton, UI.ValidateLabel = createButton(
        UI.FormGroup,
        "ValidateButton",
        "Validate",
        UDim2.fromOffset(105, 350),
        UDim2.fromOffset(286, 48),
        true,
        validateKey
    )
    UI.LoadingDot = new("Frame", {
        Name = "LoadingDot",
        Size = UDim2.fromOffset(14, 14),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromOffset(80, 24),
        BackgroundColor3 = Color3.fromRGB(248, 250, 255),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 50,
        Parent = UI.ValidateButton,
    })
    corner(UI.LoadingDot, 14)
    stroke(UI.LoadingDot, Color3.fromRGB(255, 255, 255), 2, 0.55)

    UI.GetKeyButton = nil
    UI.GetKeyLabel = nil
    UI.GetKeyButton, UI.GetKeyLabel = createButton(
        UI.FormGroup,
        "GetKeyButton",
        "Get Key",
        UDim2.fromOffset(105, 414),
        UDim2.fromOffset(286, 38),
        false,
        openKeyLink
    )

    UI.ToastLayer = new("Frame", {
        Name = "ToastLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 300,
        Parent = UI.Root,
    })

    connect(UI.LeftPanel.InputBegan, beginDrag)
    connect(UI.RightPanel.InputBegan, beginDrag)
    connect(UI.Window.InputBegan, beginDrag)
    connect(UserInputService.InputChanged, updateDragInput)
    connect(RunService.RenderStepped, updateDrag)
    connect(UI.Root:GetPropertyChangedSignal("AbsoluteSize"), updateScale)
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
        disconnect(State.CameraViewportConnection)
        State.CameraViewportConnection = nil
        if workspace.CurrentCamera then
            State.CameraViewportConnection =
                connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateScale)
        end
        task.defer(updateScale)
    end)
    if workspace.CurrentCamera then
        State.CameraViewportConnection =
            connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateScale)
    end

    setStatus("idle", "Status")
    updateScale()
    UI.Window.GroupTransparency = 1
    tween(UI.Window, TweenInfoSet.Open, { GroupTransparency = 0 })
    tween(UI.Root, TweenInfoSet.Open, { BackgroundTransparency = 0.34 })
end

function Loader:SetTitle(title)
    setWordmark(title or "KRONOS")
    return self
end

function Loader:SetVersion(version)
    State.Version = tostring(version or "")
    if UI.VersionLabel then
        if State.Version == "" then
            UI.VersionLabel.Visible = false
        else
            UI.VersionLabel.Visible = true
            UI.VersionLabel.Text = "v" .. State.Version
        end
    end
    return self
end

function Loader:SetKeyLink(url)
    State.KeyLink = tostring(url or "")
    return self
end

function Loader:SetExpiry(seconds)
    State.ExpiryToken += 1
    local token = State.ExpiryToken
    local expiry = tonumber(seconds)
    if expiry and expiry > 0 then
        task.delay(expiry, function()
            if State.Destroyed or token ~= State.ExpiryToken then
                return
            end
            State.Validating = false
            setInputLocked(false)
            stopLoadingVisual()
            setStatus("warning", "Session expired")
            Loader:Toast({
                Type = "warning",
                Title = "Session Expired",
                Subtitle = "Generate or enter a fresh key",
                Duration = 4,
            })
        end)
    end
    return self
end

function Loader:SetOnValidate(callback)
    if type(callback) == "function" then
        State.ValidateCallback = callback
    else
        State.ValidateCallback = nil
    end
    return self
end

function Loader:Toast(config)
    if State.Destroyed then
        return nil
    end
    if type(config) == "string" then
        config = { Title = config }
    elseif type(config) ~= "table" then
        config = { Title = "Notification" }
    end

    if #State.Toasts >= 4 then
        State.ToastQueue[#State.ToastQueue + 1] = config
        return nil
    end

    local accent, icon = toastColor(string.lower(tostring(config.Type or "info")))
    if config.Icon == "shield-check" then
        icon = "✓"
    end

    local card = new("CanvasGroup", {
        Name = "Toast",
        Size = UDim2.fromOffset(312, 82),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 36, 0, 22 + #State.Toasts * 92),
        BackgroundColor3 = Theme.PanelDeep,
        BackgroundTransparency = 0.1,
        GroupTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 310,
        Parent = UI.ToastLayer,
    })
    corner(card, 16)
    createAcrylic(card, 310, 16, Color3.fromRGB(8, 10, 16), 0.42)
    stroke(card, accent, 1, 0.62)

    local iconFrame = new("Frame", {
        Name = "IconFrame",
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.fromOffset(16, 21),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        ZIndex = 325,
        Parent = card,
    })
    corner(iconFrame, 14)
    stroke(iconFrame, accent, 1, 0.58)
    new("TextLabel", {
        Name = "Icon",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = icon,
        TextColor3 = accent,
        TextTransparency = 0.04,
        TextSize = 19,
        Font = Enum.Font.GothamBold,
        ZIndex = 326,
        Parent = iconFrame,
    })

    new("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -84, 0, 24),
        Position = UDim2.fromOffset(68, 18),
        BackgroundTransparency = 1,
        Text = tostring(config.Title or "Notification"),
        TextColor3 = Theme.Text,
        TextTransparency = 0.02,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 326,
        Parent = card,
    })

    new("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(1, -84, 0, 28),
        Position = UDim2.fromOffset(68, 42),
        BackgroundTransparency = 1,
        Text = tostring(config.Subtitle or ""),
        TextColor3 = Theme.TextDim,
        TextTransparency = 0.18,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 326,
        Parent = card,
    })

    local toast = { Gui = card, Token = os.clock() }
    State.Toasts[#State.Toasts + 1] = toast
    reflowToasts()
    tween(card, TweenInfoSet.Toast, {
        Position = UDim2.new(1, -24, 0, 22 + (#State.Toasts - 1) * 92),
        GroupTransparency = 0,
    })

    local duration = tonumber(config.Duration) or 3
    task.delay(math.max(duration, 0.5), function()
        if not State.Destroyed then
            removeToast(toast)
        end
    end)

    return card
end

function Loader:Close(callback)
    if State.Destroyed or not State.Open then
        if type(callback) == "function" then
            task.defer(callback)
        end
        return self
    end
    State.Open = false
    State.Validating = false
    setInputLocked(true)
    stopLoadingVisual()
    if UI.Blur then
        tween(UI.Blur, TweenInfoSet.Close, { Size = 0 })
    end
    if UI.Root then
        tween(UI.Root, TweenInfoSet.Close, { BackgroundTransparency = 1 })
    end
    if UI.Window then
        local closeTween = tween(UI.Window, TweenInfoSet.Close, { GroupTransparency = 1 })
        if closeTween then
            closeTween.Completed:Once(function()
                if UI.Window then
                    UI.Window.Visible = false
                end
                if type(callback) == "function" then
                    callback()
                end
            end)
        elseif type(callback) == "function" then
            callback()
        end
    end
    return self
end

function Loader:Destroy()
    if State.Destroyed then
        return self
    end
    State.Destroyed = true
    for _, connection in ipairs(State.Connections) do
        disconnect(connection)
    end
    table.clear(State.Connections)
    for _, tweenObject in ipairs(State.Tweens) do
        cancelTween(tweenObject)
    end
    table.clear(State.Tweens)
    if UI.Blur then
        UI.Blur:Destroy()
    end
    if UI.ScreenGui then
        UI.ScreenGui:Destroy()
    end
    table.clear(State.Toasts)
    table.clear(State.ToastQueue)
    return self
end

buildInterface()

return Loader
