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
    DiscordModalOpen = false,
    DiscordModalClosing = false,
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
local DISCORD_CONTACT_URL = "dsc.gg/kronoshub"

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
    return Vector2.new(center.X, center.Y)
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
    local depth = new("Frame", {
        Name = "Depth Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 1, 4),
        BackgroundTransparency = 0.36,
        BorderSizePixel = 0,
        ZIndex = zIndex,
        Parent = parent,
    })
    corner(depth, radius)
    gradient(
        depth,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 18, 28)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(6, 8, 13)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(1, 2, 5)),
        }),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.55, 0.03),
            NumberSequenceKeypoint.new(1, 0.16),
        })
    )

    local glassTint = new("Frame", {
        Name = "Glass Tint Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = tint or Theme.Panel,
        BackgroundTransparency = tintTransparency or 0.72,
        BorderSizePixel = 0,
        ZIndex = zIndex + 1,
        Parent = parent,
    })
    corner(glassTint, radius)

    local diffusion = new("Frame", {
        Name = "Light Diffusion Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.PanelBlue,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = zIndex + 2,
        Parent = parent,
    })
    corner(diffusion, radius)
    gradient(
        diffusion,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(62, 72, 100)),
            ColorSequenceKeypoint.new(0.42, Color3.fromRGB(18, 22, 34)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 7, 13)),
        }),
        26,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.62),
            NumberSequenceKeypoint.new(0.45, 0.91),
            NumberSequenceKeypoint.new(1, 0.78),
        })
    )

    local ambient = new("Frame", {
        Name = "Ambient Lighting Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.AccentDeep,
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        ZIndex = zIndex + 3,
        Parent = parent,
    })
    corner(ambient, radius)
    gradient(
        ambient,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(117, 126, 190)),
            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(20, 24, 38)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 8, 14)),
        }),
        -38,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.72),
            NumberSequenceKeypoint.new(0.5, 0.97),
            NumberSequenceKeypoint.new(1, 0.88),
        })
    )

    local materialGradient = new("Frame", {
        Name = "Gradient Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(19, 23, 34),
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        ZIndex = zIndex + 4,
        Parent = parent,
    })
    corner(materialGradient, radius)
    gradient(
        materialGradient,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(43, 51, 76)),
            ColorSequenceKeypoint.new(0.34, Color3.fromRGB(10, 13, 22)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(4, 6, 11)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 25, 39)),
        }),
        118,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.66),
            NumberSequenceKeypoint.new(0.4, 0.92),
            NumberSequenceKeypoint.new(1, 0.72),
        })
    )

    local noise = buildNoise(parent, zIndex + 5, 168)

    local reflection = new("Frame", {
        Name = "Reflection Layer",
        Size = UDim2.new(1, 0, 0.42, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.93,
        BorderSizePixel = 0,
        ZIndex = zIndex + 6,
        Parent = parent,
    })
    corner(reflection, radius)
    gradient(
        reflection,
        ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(148, 160, 220)),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.74),
            NumberSequenceKeypoint.new(0.42, 0.96),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local edgeHighlight = new("Frame", {
        Name = "Edge Highlight Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = zIndex + 7,
        Parent = parent,
    })
    corner(edgeHighlight, radius)
    local edgeStroke = stroke(edgeHighlight, Color3.fromRGB(185, 195, 230), 1, 0.78)
    edgeStroke.Name = "EdgeHighlightStroke"

    local border = stroke(parent, Color3.fromRGB(82, 90, 120), 1, 0.56)
    border.Name = "Border Layer"

    return {
        Background = depth,
        Depth = depth,
        Tint = glassTint,
        GlassTint = glassTint,
        Blur = diffusion,
        LightDiffusion = diffusion,
        AmbientLighting = ambient,
        Gradient = materialGradient,
        Noise = noise,
        Reflection = reflection,
        Highlight = edgeHighlight,
        EdgeHighlight = edgeHighlight,
        Glow = ambient,
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
    local lineTransparency = kind == "idle" and 0.74 or 0.5
    if kind == "success" then
        color = Color3.fromRGB(202, 208, 236)
        lineTransparency = 0.54
    elseif kind == "error" then
        color = Color3.fromRGB(205, 198, 224)
        lineTransparency = 0.48
    elseif kind == "loading" then
        color = Color3.fromRGB(204, 211, 250)
        lineTransparency = 0.44
    elseif kind == "warning" then
        color = Color3.fromRGB(205, 198, 224)
        lineTransparency = 0.48
    end
    UI.StatusText.Text = message or "Status"
    UI.StatusText.TextColor3 = color
    if UI.StatusLine then
        tween(UI.StatusLine, TweenInfoSet.Soft, { BackgroundColor3 = color, BackgroundTransparency = lineTransparency })
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
    State.LoadingTick = 0
    if UI.StatusText then
        tween(UI.StatusText, TweenInfoSet.Fast, { TextTransparency = 1 })
    end
    if UI.StatusLine then
        tween(UI.StatusLine, TweenInfoSet.Fast, { BackgroundTransparency = 1 })
    end
    if UI.ValidationOverlay then
        UI.ValidationOverlay.Visible = true
        UI.ValidationOverlay.GroupTransparency = 1
        tween(UI.ValidationOverlay, TweenInfoSet.Soft, { GroupTransparency = 0 })
    end
    if UI.ValidationOverlayScale then
        UI.ValidationOverlayScale.Scale = 0.94
        tween(UI.ValidationOverlayScale, TweenInfoSet.Soft, { Scale = 1 })
    end
    if UI.ValidateLabel then
        UI.ValidateLabel.Text = "Validating"
    end
    disconnect(State.LoadingConnection)
    State.LoadingConnection = connect(RunService.RenderStepped, function(dt)
        State.LoadingTick += dt
        if UI.ValidationSpinner then
            UI.ValidationSpinner.Rotation = (State.LoadingTick * 178) % 360
        end
        if UI.SpinnerSegments then
            for index, segment in ipairs(UI.SpinnerSegments) do
                local wave = (math.sin(State.LoadingTick * 7.2 + index * 0.7) + 1) * 0.5
                segment.BackgroundTransparency = 0.38 + wave * 0.42
            end
        end
    end)
end
local function stopLoadingVisual()
    disconnect(State.LoadingConnection)
    State.LoadingConnection = nil
    if UI.ValidationOverlay then
        local overlay = UI.ValidationOverlay
        local outTween = tween(overlay, TweenInfoSet.Fast, { GroupTransparency = 1 })
        if outTween then
            outTween.Completed:Once(function()
                if not State.Validating and overlay.Parent then
                    overlay.Visible = false
                end
            end)
        else
            overlay.Visible = false
        end
    end
    if UI.ValidationOverlayScale then
        tween(UI.ValidationOverlayScale, TweenInfoSet.Fast, { Scale = 0.96 })
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

local function getToastMetrics()
    local viewport = getViewport()
    local safeInset = GuiService:GetGuiInset()
    local width = math.clamp(viewport.X - 28, 280, 348)
    local height = 92
    local top = math.max(18, safeInset.Y + 14)
    local right = math.max(14, UserInputService.TouchEnabled and 16 or 24)
    return width, height, top, right
end

local function getToastPosition(index, offscreen)
    local width, height, top, right = getToastMetrics()
    local xOffset = offscreen and (width + 44) or -right
    return UDim2.new(1, xOffset, 0, top + (index - 1) * (height + 12))
end

local function reflowToasts()
    for index, toast in ipairs(State.Toasts) do
        if toast.Gui and toast.Gui.Parent then
            local width, height = getToastMetrics()
            toast.Gui.Size = UDim2.fromOffset(width, height)
            tween(toast.Gui, TweenInfoSet.Toast, {
                Position = getToastPosition(index, false),
            })
        end
    end
end

local function removeToast(toast)
    if toast.Removing then
        return
    end
    toast.Removing = true
    local foundIndex = table.find(State.Toasts, toast)
    if foundIndex then
        table.remove(State.Toasts, foundIndex)
    end
    if toast.ProgressTween then
        cancelTween(toast.ProgressTween)
        toast.ProgressTween = nil
    end
    if toast.Gui and toast.Gui.Parent then
        local outTween = tween(toast.Gui, TweenInfoSet.ToastOut, {
            Position = toast.Gui.Position + UDim2.fromOffset(34, -4),
            GroupTransparency = 1,
        })
        if toast.Scale then
            tween(toast.Scale, TweenInfoSet.ToastOut, { Scale = 0.975 })
        end
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
        return Color3.fromRGB(176, 235, 205), "✓"
    elseif toastType == "error" then
        return Color3.fromRGB(238, 176, 192), "!"
    elseif toastType == "warning" then
        return Color3.fromRGB(238, 210, 158), "!"
    elseif toastType == "loading" then
        return Color3.fromRGB(196, 205, 255), "…"
    end
    return Color3.fromRGB(196, 205, 255), "i"
end

local function createToastMaterial(parent, accent)
    local shadowLayer = new("Frame", {
        Name = "Shadow Layer",
        Size = UDim2.new(1, 18, 1, 20),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.55),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.76,
        BorderSizePixel = 0,
        ZIndex = 308,
        Parent = parent,
    })
    corner(shadowLayer, 24)
    gradient(
        shadowLayer,
        ColorSequence.new(Color3.fromRGB(0, 0, 0), accent),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.42),
            NumberSequenceKeypoint.new(0.58, 0.78),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local card = new("CanvasGroup", {
        Name = "ToastCard",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(7, 9, 15),
        BackgroundTransparency = 0.34,
        GroupTransparency = 0,
        ClipsDescendants = true,
        BorderSizePixel = 0,
        ZIndex = 310,
        Parent = parent,
    })
    corner(card, 18)

    local backgroundLayer = new("Frame", {
        Name = "Background Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(4, 6, 11),
        BackgroundTransparency = 0.34,
        BorderSizePixel = 0,
        ZIndex = 311,
        Parent = card,
    })
    corner(backgroundLayer, 18)

    local tintLayer = new("Frame", {
        Name = "Tint Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(13, 16, 26),
        BackgroundTransparency = 0.42,
        BorderSizePixel = 0,
        ZIndex = 312,
        Parent = card,
    })
    corner(tintLayer, 18)
    gradient(
        tintLayer,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(31, 36, 54)),
            ColorSequenceKeypoint.new(0.46, Color3.fromRGB(11, 14, 24)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 6, 12)),
        }),
        18,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.62),
            NumberSequenceKeypoint.new(0.55, 0.76),
            NumberSequenceKeypoint.new(1, 0.68),
        })
    )

    local noiseLayer = buildNoise(card, 313, 76)
    noiseLayer.Name = "Noise Layer"

    local reflectionLayer = new("Frame", {
        Name = "Reflection Layer",
        Size = UDim2.new(1, -18, 0.42, 0),
        Position = UDim2.fromOffset(9, 5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        ZIndex = 314,
        Parent = card,
    })
    corner(reflectionLayer, 16)
    gradient(
        reflectionLayer,
        ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(160, 170, 220)),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.76),
            NumberSequenceKeypoint.new(0.48, 0.96),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local highlightLayer = new("Frame", {
        Name = "Highlight Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 315,
        Parent = card,
    })
    corner(highlightLayer, 18)
    local edge = stroke(highlightLayer, Color3.fromRGB(202, 210, 246), 1, 0.72)
    edge.Name = "Edge Highlight"

    local accentGlow = new("Frame", {
        Name = "Accent Glow",
        Size = UDim2.new(0, 70, 1, 18),
        Position = UDim2.fromOffset(-26, -9),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
        ZIndex = 316,
        Parent = card,
    })
    corner(accentGlow, 36)
    gradient(
        accentGlow,
        ColorSequence.new(accent, Color3.fromRGB(8, 10, 16)),
        0,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.48),
            NumberSequenceKeypoint.new(0.66, 0.96),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local borderLayer = stroke(card, Color3.fromRGB(95, 104, 136), 1, 0.52)
    borderLayer.Name = "Border Layer"

    return card
end
local function createButton(parent, name, text, position, size, primary, callback)
    local button = new("TextButton", {
        Name = name,
        Position = position,
        Size = size,
        AutoButtonColor = false,
        BackgroundColor3 = primary and Color3.fromRGB(183, 192, 255) or Color3.fromRGB(10, 13, 21),
        BackgroundTransparency = primary and 0.2 or 0.76,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Text = "",
        ZIndex = 48,
        Parent = parent,
    })
    corner(button, primary and 24 or 18)

    local glow = new("Frame", {
        Name = "Glow Layer",
        Size = primary and UDim2.new(1, 30, 1, 24) or UDim2.new(1, 12, 1, 10),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.56),
        BackgroundColor3 = primary and Color3.fromRGB(176, 190, 255) or Theme.AccentDeep,
        BackgroundTransparency = primary and 0.78 or 0.95,
        BorderSizePixel = 0,
        ZIndex = 45,
        Parent = button,
    })
    corner(glow, primary and 34 or 24)
    gradient(
        glow,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(247, 247, 255)),
            ColorSequenceKeypoint.new(0.46, Color3.fromRGB(182, 190, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(126, 145, 230)),
        }),
        0,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, primary and 0.7 or 0.92),
            NumberSequenceKeypoint.new(0.48, primary and 0.34 or 0.82),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local base = new("Frame", {
        Name = "Base Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = primary and Color3.fromRGB(150, 163, 237) or Color3.fromRGB(8, 11, 18),
        BackgroundTransparency = primary and 0.1 or 0.78,
        BorderSizePixel = 0,
        ZIndex = 48,
        Parent = button,
    })
    corner(base, primary and 24 or 18)

    local gradientLayer = new("Frame", {
        Name = "Gradient Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = primary and Color3.fromRGB(206, 211, 255) or Color3.fromRGB(12, 15, 24),
        BackgroundTransparency = primary and 0.02 or 0.74,
        BorderSizePixel = 0,
        ZIndex = 49,
        Parent = button,
    })
    corner(gradientLayer, primary and 24 or 18)
    gradient(
        gradientLayer,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, primary and Color3.fromRGB(244, 244, 255) or Color3.fromRGB(20, 24, 36)),
            ColorSequenceKeypoint.new(0.18, primary and Color3.fromRGB(218, 222, 255) or Color3.fromRGB(16, 19, 30)),
            ColorSequenceKeypoint.new(0.58, primary and Color3.fromRGB(178, 187, 255) or Color3.fromRGB(11, 14, 23)),
            ColorSequenceKeypoint.new(1, primary and Color3.fromRGB(137, 157, 239) or Color3.fromRGB(6, 8, 14)),
        }),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, primary and 0.06 or 0.42),
            NumberSequenceKeypoint.new(0.44, primary and 0.01 or 0.24),
            NumberSequenceKeypoint.new(1, primary and 0.08 or 0.48),
        })
    )

    local highlight = new("Frame", {
        Name = "Highlight Layer",
        Size = UDim2.new(1, -18, 0, primary and 16 or 10),
        Position = UDim2.fromOffset(9, primary and 4 or 3),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = primary and 0.6 or 0.92,
        BorderSizePixel = 0,
        ZIndex = 50,
        Parent = button,
    })
    corner(highlight, primary and 16 or 12)
    gradient(
        highlight,
        ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(218, 224, 255)),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, primary and 0.34 or 0.86),
            NumberSequenceKeypoint.new(0.62, primary and 0.86 or 0.98),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local reflection = new("Frame", {
        Name = "Reflection Layer",
        Size = UDim2.new(0.54, 0, 0.72, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0.08, 0.44),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = primary and 0.84 or 0.96,
        BorderSizePixel = 0,
        Rotation = -10,
        ZIndex = 51,
        Parent = button,
    })
    corner(reflection, primary and 24 or 18)
    gradient(
        reflection,
        ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(185, 196, 255)),
        0,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, primary and 0.7 or 0.96),
            NumberSequenceKeypoint.new(0.38, primary and 0.88 or 1),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local edgeLight = new("Frame", {
        Name = "Edge Light Layer",
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.fromOffset(2, 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 52,
        Parent = button,
    })
    corner(edgeLight, primary and 22 or 16)
    local edgeStroke = stroke(edgeLight, Color3.fromRGB(252, 253, 255), 1, primary and 0.54 or 0.88)
    edgeStroke.Name = "EdgeLightStroke"

    local borderStroke =
        stroke(button, primary and Color3.fromRGB(224, 229, 255) or Theme.Line, 1, primary and 0.28 or 0.72)
    borderStroke.Name = "Border Layer"
    local scale = new("UIScale", { Scale = 1, Parent = button })

    local label = new("TextLabel", {
        Name = "Label",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = primary and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 193, 240),
        TextTransparency = primary and 0.04 or 0.2,
        Font = Enum.Font.GothamMedium,
        TextSize = primary and 15 or 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 55,
        Parent = button,
    })

    local arrow = new("TextLabel", {
        Name = "Arrow",
        Size = UDim2.fromOffset(28, 20),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -88, 0.5, 0),
        BackgroundTransparency = 1,
        Text = "→",
        TextColor3 = primary and Color3.fromRGB(255, 255, 255) or Theme.AccentHot,
        TextTransparency = primary and 0.16 or 0.38,
        Font = Enum.Font.GothamMedium,
        TextSize = primary and 22 or 16,
        ZIndex = 55,
        Parent = button,
    })
    if not primary then
        arrow.Visible = false
    end

    connect(button.MouseEnter, function()
        if not button.Active then
            return
        end
        tween(scale, TweenInfoSet.Fast, { Scale = 1.015 })
        tween(glow, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.68 or 0.9 })
        tween(highlight, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.52 or 0.9 })
        tween(reflection, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.78 or 0.94 })
        tween(edgeStroke, TweenInfoSet.Fast, { Transparency = primary and 0.38 or 0.78 })
        tween(borderStroke, TweenInfoSet.Fast, { Transparency = primary and 0.16 or 0.54 })
    end)
    connect(button.MouseLeave, function()
        tween(scale, TweenInfoSet.Fast, { Scale = 1 })
        tween(glow, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.78 or 0.95 })
        tween(highlight, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.6 or 0.92 })
        tween(reflection, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.84 or 0.96 })
        tween(edgeStroke, TweenInfoSet.Fast, { Transparency = primary and 0.54 or 0.88 })
        tween(borderStroke, TweenInfoSet.Fast, { Transparency = primary and 0.28 or 0.72 })
    end)
    connect(button.MouseButton1Down, function()
        if button.Active then
            tween(scale, TweenInfoSet.Fast, { Scale = 0.978 })
            tween(glow, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.74 or 0.94 })
            tween(gradientLayer, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.07 or 0.78 })
        end
    end)
    connect(button.MouseButton1Up, function()
        if button.Active then
            tween(scale, TweenInfoSet.Fast, { Scale = 1.008 })
            tween(glow, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.7 or 0.9 })
            tween(gradientLayer, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.02 or 0.74 })
        end
    end)
    connect(button.MouseButton1Click, callback)

    return button, label
end

local function copyDiscordLink()
    local copied = false
    pcall(function()
        if typeof(setclipboard) == "function" then
            setclipboard(DISCORD_CONTACT_URL)
            copied = true
        elseif typeof(toclipboard) == "function" then
            toclipboard(DISCORD_CONTACT_URL)
            copied = true
        end
    end)

    if copied then
        Loader:Toast({
            Type = "success",
            Icon = "shield-check",
            Title = "Discord Link Copied",
            Subtitle = DISCORD_CONTACT_URL,
            Duration = 3,
        })
    else
        Loader:Toast({
            Type = "warning",
            Icon = "info",
            Title = "Discord Link",
            Subtitle = DISCORD_CONTACT_URL,
            Duration = 5,
        })
    end
end

local function createModalCopyGlyph(parent, zIndex)
    local glyph = new("Frame", {
        Name = "CopyGlyph",
        Size = UDim2.fromOffset(22, 22),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = zIndex,
        Parent = parent,
    })

    local backSheet = new("Frame", {
        Name = "BackSheet",
        Size = UDim2.fromOffset(10, 12),
        Position = UDim2.fromOffset(4, 3),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = zIndex,
        Parent = glyph,
    })
    corner(backSheet, 4)
    local backStroke = stroke(backSheet, Color3.fromRGB(214, 224, 255), 1, 0.74)

    local frontSheet = new("Frame", {
        Name = "FrontSheet",
        Size = UDim2.fromOffset(11, 13),
        Position = UDim2.fromOffset(8, 7),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = zIndex + 1,
        Parent = glyph,
    })
    corner(frontSheet, 4)
    local frontStroke = stroke(frontSheet, Color3.fromRGB(230, 237, 255), 1, 0.68)

    local check = new("Frame", {
        Name = "CheckGlyph",
        Size = UDim2.fromOffset(22, 22),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = zIndex + 2,
        Parent = glyph,
    })

    local checkA = new("Frame", {
        Name = "CheckA",
        Size = UDim2.fromOffset(7, 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(8, 13),
        BackgroundColor3 = Color3.fromRGB(226, 240, 255),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Rotation = 42,
        ZIndex = zIndex + 2,
        Parent = check,
    })
    corner(checkA, 2)

    local checkB = new("Frame", {
        Name = "CheckB",
        Size = UDim2.fromOffset(12, 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(14, 10),
        BackgroundColor3 = Color3.fromRGB(226, 240, 255),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Rotation = -42,
        ZIndex = zIndex + 2,
        Parent = check,
    })
    corner(checkB, 2)

    return {
        Root = glyph,
        Strokes = { backStroke, frontStroke },
        Check = { checkA, checkB },
    }
end

local function setModalCopyGlyphHover(hovered)
    if not UI.DiscordModalCopyIcon then
        return
    end
    local icon = UI.DiscordModalCopyIcon
    tween(icon.Button, TweenInfoSet.Fast, {
        Position = hovered and UDim2.new(1, -35, 0.5, 0) or UDim2.new(1, -30, 0.5, 0),
    })
    tween(icon.Scale, TweenInfoSet.Fast, { Scale = hovered and 1 or 0.95 })
    tween(icon.Glow, TweenInfoSet.Fast, { BackgroundTransparency = hovered and 0.84 or 0.98 })
    for _, line in ipairs(icon.Glyph.Strokes) do
        tween(line, TweenInfoSet.Fast, {
            Color = hovered and Color3.fromRGB(244, 248, 255) or Color3.fromRGB(214, 224, 255),
            Transparency = hovered and 0.08 or 0.72,
        })
    end
end

local function playDiscordCopyFeedback()
    if not UI.DiscordModalFieldStroke then
        return
    end

    tween(UI.DiscordModalFieldStroke, TweenInfoSet.Fast, {
        Color = Color3.fromRGB(135, 165, 255),
        Transparency = 0.12,
    })
    if UI.DiscordModalFieldGlow then
        tween(UI.DiscordModalFieldGlow, TweenInfoSet.Fast, { BackgroundTransparency = 0.72 })
    end
    if UI.DiscordModalCopyIcon then
        local glyph = UI.DiscordModalCopyIcon.Glyph
        for _, line in ipairs(glyph.Strokes) do
            tween(line, TweenInfoSet.Fast, { Transparency = 1 })
        end
        for _, line in ipairs(glyph.Check) do
            tween(line, TweenInfoSet.Fast, { BackgroundTransparency = 0 })
        end
    end

    task.delay(0.72, function()
        if State.Destroyed or not UI.DiscordModalFieldStroke or not UI.DiscordModalFieldStroke.Parent then
            return
        end
        tween(UI.DiscordModalFieldStroke, TweenInfoSet.Soft, {
            Color = Color3.fromRGB(86, 96, 132),
            Transparency = 0.58,
        })
        if UI.DiscordModalFieldGlow then
            tween(UI.DiscordModalFieldGlow, TweenInfoSet.Soft, { BackgroundTransparency = 0.92 })
        end
        if UI.DiscordModalCopyIcon then
            local glyph = UI.DiscordModalCopyIcon.Glyph
            for _, line in ipairs(glyph.Strokes) do
                tween(line, TweenInfoSet.Soft, { Transparency = 0.72 })
            end
            for _, line in ipairs(glyph.Check) do
                tween(line, TweenInfoSet.Soft, { BackgroundTransparency = 1 })
            end
        end
    end)
end

local function copyDiscordFromModal()
    copyDiscordLink()
    playDiscordCopyFeedback()
end

local function createModalButton(parent, name, text, position, primary, callback)
    local button = new("TextButton", {
        Name = name,
        Size = UDim2.fromOffset(166, 44),
        Position = position,
        AutoButtonColor = false,
        BackgroundColor3 = primary and Color3.fromRGB(206, 214, 255) or Color3.fromRGB(13, 16, 25),
        BackgroundTransparency = primary and 0.08 or 0.4,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 244,
        Parent = parent,
    })
    corner(button, 15)

    local scale = new("UIScale", { Scale = 1, Parent = button })
    local glow = new("Frame", {
        Name = "ButtonGlow",
        Size = UDim2.new(1, 20, 1, 18),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.55),
        BackgroundColor3 = primary and Color3.fromRGB(143, 161, 255) or Color3.fromRGB(78, 93, 155),
        BackgroundTransparency = primary and 0.78 or 0.96,
        BorderSizePixel = 0,
        ZIndex = 242,
        Parent = button,
    })
    corner(glow, 21)
    gradient(
        glow,
        ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(88, 112, 220)),
        16,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.52),
            NumberSequenceKeypoint.new(0.46, 0.78),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local body = new("Frame", {
        Name = "MaterialBody",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = primary and Color3.fromRGB(219, 224, 255) or Color3.fromRGB(13, 16, 25),
        BackgroundTransparency = primary and 0.05 or 0.36,
        BorderSizePixel = 0,
        ZIndex = 245,
        Parent = button,
    })
    corner(body, 15)
    gradient(
        body,
        primary
                and ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(250, 249, 255)),
                    ColorSequenceKeypoint.new(0.46, Color3.fromRGB(205, 212, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(169, 191, 255)),
                })
            or ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 35, 52)),
                ColorSequenceKeypoint.new(0.52, Color3.fromRGB(12, 15, 24)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 9, 15)),
            }),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, primary and 0.02 or 0.2),
            NumberSequenceKeypoint.new(0.55, primary and 0.05 or 0.02),
            NumberSequenceKeypoint.new(1, primary and 0.12 or 0.22),
        })
    )

    local highlight = new("Frame", {
        Name = "GlassHighlight",
        Size = UDim2.new(1, -18, 0, 15),
        Position = UDim2.fromOffset(9, 5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = primary and 0.52 or 0.9,
        BorderSizePixel = 0,
        ZIndex = 246,
        Parent = button,
    })
    corner(highlight, 13)
    gradient(
        highlight,
        ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 193, 255)),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.35),
            NumberSequenceKeypoint.new(0.55, 0.92),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local border = stroke(
        button,
        primary and Color3.fromRGB(245, 247, 255) or Color3.fromRGB(85, 93, 126),
        1,
        primary and 0.32 or 0.6
    )
    local label = new("TextLabel", {
        Name = "Label",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = primary and Color3.fromRGB(17, 22, 40) or Theme.Text,
        TextTransparency = primary and 0.03 or 0.08,
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 248,
        Parent = button,
    })

    connect(button.MouseEnter, function()
        tween(scale, TweenInfoSet.Fast, { Scale = 1.012 })
        tween(glow, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.62 or 0.86 })
        tween(body, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.02 or 0.28 })
        tween(highlight, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.42 or 0.82 })
        tween(border, TweenInfoSet.Fast, { Transparency = primary and 0.18 or 0.42 })
    end)
    connect(button.MouseLeave, function()
        tween(scale, TweenInfoSet.Fast, { Scale = 1 })
        tween(glow, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.78 or 0.96 })
        tween(body, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.05 or 0.36 })
        tween(highlight, TweenInfoSet.Fast, { BackgroundTransparency = primary and 0.52 or 0.9 })
        tween(border, TweenInfoSet.Fast, { Transparency = primary and 0.32 or 0.6 })
    end)
    connect(button.MouseButton1Down, function()
        tween(scale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.97 })
    end)
    connect(button.MouseButton1Up, function()
        tween(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.012 })
    end)
    connect(button.MouseButton1Click, callback)

    return button, label
end

local function closeDiscordModal()
    if not State.DiscordModalOpen or State.DiscordModalClosing then
        return
    end
    State.DiscordModalClosing = true

    if UI.DiscordModalBackdrop then
        tween(UI.DiscordModalBackdrop, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        })
    end
    if UI.DiscordModalCard then
        tween(UI.DiscordModalCard, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            GroupTransparency = 1,
        })
    end
    if UI.DiscordModalScale then
        tween(
            UI.DiscordModalScale,
            TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            { Scale = 0.92 }
        )
    end

    task.delay(0.24, function()
        if State.Destroyed then
            return
        end
        if UI.DiscordModalBackdrop then
            UI.DiscordModalBackdrop.Visible = false
        end
        State.DiscordModalOpen = false
        State.DiscordModalClosing = false
    end)
end

local function createDiscordModal(parent)
    local backdrop = new("Frame", {
        Name = "DiscordModalBackdrop",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(1, 2, 6),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 210,
        Parent = parent,
    })

    local outside = new("TextButton", {
        Name = "OutsideDismissLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 211,
        Parent = backdrop,
    })

    local shadow = new("Frame", {
        Name = "ModalShadow",
        Size = UDim2.fromOffset(452, 274),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.515),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.46,
        BorderSizePixel = 0,
        ZIndex = 214,
        Parent = backdrop,
    })
    corner(shadow, 28)
    gradient(
        shadow,
        ColorSequence.new(Color3.fromRGB(75, 85, 145), Color3.fromRGB(0, 0, 0)),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.9),
            NumberSequenceKeypoint.new(0.48, 0.36),
            NumberSequenceKeypoint.new(1, 0.78),
        })
    )

    local card = new("CanvasGroup", {
        Name = "DiscordModalCard",
        Size = UDim2.fromOffset(420, 246),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.49),
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 220,
        Parent = backdrop,
    })
    corner(card, 18)
    createAcrylic(card, 220, 18, Color3.fromRGB(13, 17, 27), 0.48)
    local cardBorder = stroke(card, Color3.fromRGB(95, 105, 145), 1, 0.48)
    UI.DiscordModalScale = new("UIScale", { Scale = 0.92, Parent = card })

    local title = new("TextLabel", {
        Name = "DiscordTitle",
        Size = UDim2.fromOffset(352, 34),
        Position = UDim2.fromOffset(34, 28),
        BackgroundTransparency = 1,
        Text = "Discord",
        TextColor3 = Theme.Text,
        TextTransparency = 0.02,
        Font = Enum.Font.GothamSemibold,
        TextSize = 25,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 236,
        Parent = card,
    })

    local field = new("Frame", {
        Name = "DiscordLinkField",
        Size = UDim2.fromOffset(352, 58),
        Position = UDim2.fromOffset(34, 86),
        BackgroundColor3 = Color3.fromRGB(8, 11, 18),
        BackgroundTransparency = 0.34,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 235,
        Parent = card,
    })
    corner(field, 16)
    gradient(
        field,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(31, 36, 55)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(9, 12, 20)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 7, 12)),
        }),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(0.55, 0.04),
            NumberSequenceKeypoint.new(1, 0.2),
        })
    )

    local fieldGlow = new("Frame", {
        Name = "FieldBlueGlow",
        Size = UDim2.fromOffset(376, 76),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(210, 115),
        BackgroundColor3 = Color3.fromRGB(100, 130, 255),
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        ZIndex = 233,
        Parent = card,
    })
    corner(fieldGlow, 22)
    gradient(
        fieldGlow,
        ColorSequence.new(Color3.fromRGB(180, 196, 255), Color3.fromRGB(58, 78, 170)),
        0,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.42),
            NumberSequenceKeypoint.new(0.5, 0.76),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local innerLight = new("Frame", {
        Name = "FieldInnerLight",
        Size = UDim2.new(1, -12, 0, 14),
        Position = UDim2.fromOffset(6, 5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        ZIndex = 237,
        Parent = field,
    })
    corner(innerLight, 12)
    gradient(
        innerLight,
        ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(167, 184, 255)),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.64),
            NumberSequenceKeypoint.new(0.58, 0.96),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local linkText = new("TextLabel", {
        Name = "LinkText",
        Size = UDim2.new(1, -82, 1, 0),
        Position = UDim2.fromOffset(20, 0),
        BackgroundTransparency = 1,
        Text = DISCORD_CONTACT_URL,
        TextColor3 = Color3.fromRGB(217, 224, 250),
        TextTransparency = 0.08,
        Font = Enum.Font.GothamMedium,
        TextSize = 16,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 240,
        Parent = field,
    })

    local copyButton = new("TextButton", {
        Name = "CopyIconButton",
        Size = UDim2.fromOffset(34, 34),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -30, 0.5, 0),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 242,
        Parent = field,
    })
    local copyScale = new("UIScale", { Scale = 0.95, Parent = copyButton })
    local copyGlow = new("Frame", {
        Name = "CopyIconGlow",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(116, 143, 255),
        BackgroundTransparency = 0.98,
        BorderSizePixel = 0,
        ZIndex = 241,
        Parent = copyButton,
    })
    corner(copyGlow, 12)
    local copyGlyph = createModalCopyGlyph(copyButton, 244)

    local fieldStroke = stroke(field, Color3.fromRGB(86, 96, 132), 1, 0.58)
    fieldStroke.Name = "InputFieldStroke"

    connect(field.MouseEnter, function()
        setModalCopyGlyphHover(true)
        tween(fieldStroke, TweenInfoSet.Fast, { Transparency = 0.38, Color = Color3.fromRGB(105, 116, 157) })
        tween(field, TweenInfoSet.Fast, { BackgroundTransparency = 0.28 })
    end)
    connect(field.MouseLeave, function()
        setModalCopyGlyphHover(false)
        tween(fieldStroke, TweenInfoSet.Fast, { Transparency = 0.58, Color = Color3.fromRGB(86, 96, 132) })
        tween(field, TweenInfoSet.Fast, { BackgroundTransparency = 0.34 })
    end)
    connect(copyButton.MouseButton1Click, copyDiscordFromModal)

    createModalButton(card, "CopyButton", "Copy", UDim2.fromOffset(34, 172), true, copyDiscordFromModal)
    createModalButton(card, "CloseButton", "Close", UDim2.fromOffset(220, 172), false, closeDiscordModal)

    connect(outside.MouseButton1Click, closeDiscordModal)

    UI.DiscordModalBackdrop = backdrop
    UI.DiscordModalCard = card
    UI.DiscordModalFieldStroke = fieldStroke
    UI.DiscordModalFieldGlow = fieldGlow
    UI.DiscordModalCopyIcon = {
        Button = copyButton,
        Scale = copyScale,
        Glow = copyGlow,
        Glyph = copyGlyph,
    }

    return backdrop, card, cardBorder, title, linkText
end

local function openDiscordModal()
    if State.Destroyed or State.DiscordModalClosing then
        return
    end
    if not UI.DiscordModalBackdrop or not UI.DiscordModalBackdrop.Parent then
        if not UI.Window then
            return
        end
        createDiscordModal(UI.Window)
    end
    if State.DiscordModalOpen then
        return
    end

    State.DiscordModalOpen = true
    UI.DiscordModalBackdrop.Visible = true
    UI.DiscordModalBackdrop.BackgroundTransparency = 1
    UI.DiscordModalCard.GroupTransparency = 1
    UI.DiscordModalScale.Scale = 0.92
    if UI.DiscordModalFieldStroke then
        UI.DiscordModalFieldStroke.Color = Color3.fromRGB(86, 96, 132)
        UI.DiscordModalFieldStroke.Transparency = 0.58
    end
    setModalCopyGlyphHover(false)

    tween(UI.DiscordModalBackdrop, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.42,
    })
    tween(UI.DiscordModalCard, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        GroupTransparency = 0,
    })
    tween(UI.DiscordModalScale, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = 1,
    })
end

local function createContactSection(parent)
    local title = new("TextLabel", {
        Name = "ContactTitle",
        Size = UDim2.fromOffset(286, 18),
        Position = UDim2.fromOffset(105, 475),
        BackgroundTransparency = 1,
        Text = letterSpaced("OUR CONTACTS"),
        TextColor3 = Theme.TextDim,
        TextTransparency = 0.47,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 64,
        Parent = parent,
    })

    local row = new("Frame", {
        Name = "ContactRow",
        Size = UDim2.fromOffset(286, 44),
        Position = UDim2.fromOffset(105, 507),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 64,
        Parent = parent,
    })

    local restPosition = UDim2.fromOffset(0, 0)
    local hoverPosition = UDim2.fromOffset(0, -2)
    local pressPosition = UDim2.fromOffset(0, -1)
    local iconBase = Color3.fromRGB(210, 218, 255)
    local iconHover = Color3.fromRGB(239, 244, 255)
    local iconCut = Color3.fromRGB(9, 12, 20)

    local button = new("TextButton", {
        Name = "DiscordContactButton",
        Size = UDim2.fromOffset(44, 40),
        Position = restPosition,
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(7, 10, 17),
        BackgroundTransparency = 0.48,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Text = "",
        ZIndex = 66,
        Parent = row,
    })
    corner(button, 16)

    local scale = new("UIScale", {
        Scale = 1,
        Parent = button,
    })

    local shadow = new("Frame", {
        Name = "Shadow Base",
        Size = UDim2.new(1, 20, 1, 18),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.62),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.48,
        BorderSizePixel = 0,
        ZIndex = 62,
        Parent = button,
    })
    corner(shadow, 24)
    gradient(
        shadow,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(74, 86, 158)),
            ColorSequenceKeypoint.new(0.42, Color3.fromRGB(9, 12, 24)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
        }),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.96),
            NumberSequenceKeypoint.new(0.54, 0.36),
            NumberSequenceKeypoint.new(1, 0.82),
        })
    )

    local hoverGlow = new("Frame", {
        Name = "Animated Hover Glow",
        Size = UDim2.new(1, 18, 1, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.44, 0.46),
        BackgroundColor3 = Color3.fromRGB(118, 142, 255),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 64,
        Parent = button,
    })
    corner(hoverGlow, 25)
    gradient(
        hoverGlow,
        ColorSequence.new(Color3.fromRGB(202, 214, 255), Color3.fromRGB(65, 88, 180)),
        18,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.54),
            NumberSequenceKeypoint.new(0.45, 0.78),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local body = new("Frame", {
        Name = "Dark Acrylic Body",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(8, 11, 18),
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        ZIndex = 67,
        Parent = button,
    })
    corner(body, 16)
    gradient(
        body,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 31, 48)),
            ColorSequenceKeypoint.new(0.34, Color3.fromRGB(12, 15, 26)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 6, 12)),
        }),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(0.5, 0.04),
            NumberSequenceKeypoint.new(1, 0.18),
        })
    )

    local directionLight = new("Frame", {
        Name = "Directional Light",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(150, 168, 255),
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        ZIndex = 68,
        Parent = button,
    })
    corner(directionLight, 16)
    gradient(
        directionLight,
        ColorSequence.new(Color3.fromRGB(210, 222, 255), Color3.fromRGB(20, 24, 42)),
        0,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.7),
            NumberSequenceKeypoint.new(0.42, 0.94),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local innerShadow = new("Frame", {
        Name = "Inner Shadow",
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
        ZIndex = 69,
        Parent = button,
    })
    corner(innerShadow, 14)
    gradient(
        innerShadow,
        ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0)),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.58, 0.98),
            NumberSequenceKeypoint.new(1, 0.64),
        })
    )

    local topHighlight = new("Frame", {
        Name = "Top Glass Highlight",
        Size = UDim2.new(1, -12, 0, 12),
        Position = UDim2.fromOffset(6, 4),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        ZIndex = 70,
        Parent = button,
    })
    corner(topHighlight, 12)
    gradient(
        topHighlight,
        ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(167, 184, 255)),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.66),
            NumberSequenceKeypoint.new(0.52, 0.96),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local bottomShade = new("Frame", {
        Name = "Bottom Bevel Shadow",
        Size = UDim2.new(1, -8, 0, 9),
        Position = UDim2.new(0, 4, 1, -12),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
        ZIndex = 70,
        Parent = button,
    })
    corner(bottomShade, 10)
    gradient(
        bottomShade,
        ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(42, 53, 100)),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.48, 0.84),
            NumberSequenceKeypoint.new(1, 0.52),
        })
    )

    local edgeArcGlow = new("Frame", {
        Name = "Neptune Edge Glow",
        Size = UDim2.fromOffset(32, 6),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.62, 0, 1, -5),
        BackgroundColor3 = Color3.fromRGB(118, 148, 255),
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        Rotation = -8,
        ZIndex = 72,
        Parent = button,
    })
    corner(edgeArcGlow, 8)
    gradient(
        edgeArcGlow,
        ColorSequence.new(Color3.fromRGB(220, 232, 255), Color3.fromRGB(91, 121, 236)),
        0,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.34, 0.52),
            NumberSequenceKeypoint.new(0.72, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local edgeArc = new("Frame", {
        Name = "Neptune Edge Arc",
        Size = UDim2.fromOffset(29, 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.6, 0, 1, -5),
        BackgroundColor3 = Color3.fromRGB(211, 224, 255),
        BackgroundTransparency = 0.74,
        BorderSizePixel = 0,
        Rotation = -8,
        ZIndex = 73,
        Parent = button,
    })
    corner(edgeArc, 4)
    local arcGradient = gradient(
        edgeArc,
        ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(118, 148, 255)),
        0,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.18, 0.42),
            NumberSequenceKeypoint.new(0.7, 0.08),
            NumberSequenceKeypoint.new(1, 1),
        })
    )
    arcGradient.Offset = Vector2.new(-0.22, 0)

    local iconBloom = new("Frame", {
        Name = "Icon Bloom",
        Size = UDim2.fromOffset(32, 28),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(160, 182, 255),
        BackgroundTransparency = 0.96,
        BorderSizePixel = 0,
        ZIndex = 74,
        Parent = button,
    })
    corner(iconBloom, 999)
    gradient(
        iconBloom,
        ColorSequence.new(Color3.fromRGB(225, 232, 255), Color3.fromRGB(86, 111, 215)),
        0,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.36),
            NumberSequenceKeypoint.new(0.58, 0.72),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local glyph = new("Frame", {
        Name = "DiscordGlyph",
        Size = UDim2.fromOffset(24, 20),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 78,
        Parent = button,
    })

    local glyphTop = new("Frame", {
        Name = "GlyphTopContour",
        Size = UDim2.fromOffset(18, 7),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromOffset(12, 1),
        BackgroundColor3 = iconBase,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 78,
        Parent = glyph,
    })
    corner(glyphTop, 6)

    local glyphBody = new("Frame", {
        Name = "GlyphBody",
        Size = UDim2.fromOffset(24, 16),
        Position = UDim2.fromOffset(0, 4),
        BackgroundColor3 = iconBase,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 79,
        Parent = glyph,
    })
    corner(glyphBody, 7)

    local leftCheek = new("Frame", {
        Name = "GlyphLeftCheek",
        Size = UDim2.fromOffset(6, 9),
        Position = UDim2.fromOffset(-2, 7),
        BackgroundColor3 = iconBase,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 79,
        Parent = glyph,
    })
    corner(leftCheek, 999)

    local rightCheek = new("Frame", {
        Name = "GlyphRightCheek",
        Size = UDim2.fromOffset(6, 9),
        Position = UDim2.fromOffset(20, 7),
        BackgroundColor3 = iconBase,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 79,
        Parent = glyph,
    })
    corner(rightCheek, 999)

    local bottomCut = new("Frame", {
        Name = "GlyphBottomCut",
        Size = UDim2.fromOffset(10, 4),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromOffset(12, 17),
        BackgroundColor3 = iconCut,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 80,
        Parent = glyph,
    })
    corner(bottomCut, 999)

    local leftEye = new("Frame", {
        Name = "GlyphLeftEye",
        Size = UDim2.fromOffset(3, 4),
        Position = UDim2.fromOffset(7, 10),
        BackgroundColor3 = iconCut,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 81,
        Parent = glyph,
    })
    corner(leftEye, 999)

    local rightEye = new("Frame", {
        Name = "GlyphRightEye",
        Size = UDim2.fromOffset(3, 4),
        Position = UDim2.fromOffset(14, 10),
        BackgroundColor3 = iconCut,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 81,
        Parent = glyph,
    })
    corner(rightEye, 999)

    local glyphSheen = new("Frame", {
        Name = "GlyphSheen",
        Size = UDim2.new(1, -7, 0, 5),
        Position = UDim2.fromOffset(4, 5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = 82,
        Parent = glyph,
    })
    corner(glyphSheen, 5)
    gradient(
        glyphSheen,
        ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 205, 255)),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.64),
            NumberSequenceKeypoint.new(0.58, 0.96),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local border = stroke(button, Color3.fromRGB(78, 86, 120), 1, 0.54)
    border.Name = "Border Layer"
    local innerEdge = stroke(body, Color3.fromRGB(226, 234, 255), 1, 0.86)
    innerEdge.Name = "Inner Edge Light"

    local function tweenGlyph(color, transparency)
        tween(glyphTop, TweenInfoSet.Fast, { BackgroundColor3 = color, BackgroundTransparency = transparency })
        tween(glyphBody, TweenInfoSet.Fast, { BackgroundColor3 = color, BackgroundTransparency = transparency })
        tween(leftCheek, TweenInfoSet.Fast, { BackgroundColor3 = color, BackgroundTransparency = transparency })
        tween(rightCheek, TweenInfoSet.Fast, { BackgroundColor3 = color, BackgroundTransparency = transparency })
    end

    connect(button.MouseEnter, function()
        tween(button, TweenInfoSet.Fast, { Position = hoverPosition })
        tween(scale, TweenInfoSet.Fast, { Scale = 1.025 })
        tween(shadow, TweenInfoSet.Fast, { BackgroundTransparency = 0.36 })
        tween(hoverGlow, TweenInfoSet.Fast, { BackgroundTransparency = 0.82, Position = UDim2.fromScale(0.4, 0.44) })
        tween(body, TweenInfoSet.Fast, { BackgroundTransparency = 0.16 })
        tween(directionLight, TweenInfoSet.Fast, { BackgroundTransparency = 0.84 })
        tween(topHighlight, TweenInfoSet.Fast, { BackgroundTransparency = 0.82 })
        tween(bottomShade, TweenInfoSet.Fast, { BackgroundTransparency = 0.68 })
        tween(edgeArcGlow, TweenInfoSet.Fast, { BackgroundTransparency = 0.76 })
        tween(edgeArc, TweenInfoSet.Fast, {
            BackgroundTransparency = 0.18,
            Position = UDim2.new(0.68, 0, 1, -5),
            Rotation = -4,
        })
        tween(arcGradient, TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Offset = Vector2.new(0.24, 0),
        })
        tween(iconBloom, TweenInfoSet.Fast, { BackgroundTransparency = 0.82 })
        tween(glyphSheen, TweenInfoSet.Fast, { BackgroundTransparency = 0.8 })
        tweenGlyph(iconHover, 0.02)
        tween(border, TweenInfoSet.Fast, {
            Color = Color3.fromRGB(128, 145, 218),
            Transparency = 0.34,
        })
        tween(innerEdge, TweenInfoSet.Fast, { Transparency = 0.68 })
    end)
    connect(button.MouseLeave, function()
        tween(button, TweenInfoSet.Fast, { Position = restPosition })
        tween(scale, TweenInfoSet.Fast, { Scale = 1 })
        tween(shadow, TweenInfoSet.Fast, { BackgroundTransparency = 0.48 })
        tween(hoverGlow, TweenInfoSet.Fast, { BackgroundTransparency = 1, Position = UDim2.fromScale(0.44, 0.46) })
        tween(body, TweenInfoSet.Fast, { BackgroundTransparency = 0.22 })
        tween(directionLight, TweenInfoSet.Fast, { BackgroundTransparency = 0.94 })
        tween(topHighlight, TweenInfoSet.Fast, { BackgroundTransparency = 0.9 })
        tween(bottomShade, TweenInfoSet.Fast, { BackgroundTransparency = 0.78 })
        tween(edgeArcGlow, TweenInfoSet.Fast, { BackgroundTransparency = 0.94 })
        tween(edgeArc, TweenInfoSet.Fast, {
            BackgroundTransparency = 0.74,
            Position = UDim2.new(0.6, 0, 1, -5),
            Rotation = -8,
        })
        tween(arcGradient, TweenInfoSet.Fast, { Offset = Vector2.new(-0.22, 0) })
        tween(iconBloom, TweenInfoSet.Fast, { BackgroundTransparency = 0.96 })
        tween(glyphSheen, TweenInfoSet.Fast, { BackgroundTransparency = 0.88 })
        tweenGlyph(iconBase, 0.08)
        tween(border, TweenInfoSet.Fast, {
            Color = Color3.fromRGB(78, 86, 120),
            Transparency = 0.54,
        })
        tween(innerEdge, TweenInfoSet.Fast, { Transparency = 0.86 })
    end)
    connect(button.MouseButton1Down, function()
        tween(button, TweenInfoSet.Fast, { Position = pressPosition })
        tween(scale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.96 })
        tween(hoverGlow, TweenInfoSet.Fast, { BackgroundTransparency = 0.72 })
        tween(edgeArc, TweenInfoSet.Fast, { BackgroundTransparency = 0.08 })
        tween(iconBloom, TweenInfoSet.Fast, { BackgroundTransparency = 0.74 })
    end)
    connect(button.MouseButton1Up, function()
        tween(button, TweenInfoSet.Fast, { Position = hoverPosition })
        tween(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.025 })
        tween(hoverGlow, TweenInfoSet.Fast, { BackgroundTransparency = 0.82 })
        tween(edgeArc, TweenInfoSet.Fast, { BackgroundTransparency = 0.18 })
        tween(iconBloom, TweenInfoSet.Fast, { BackgroundTransparency = 0.82 })
    end)
    connect(button.MouseButton1Click, openDiscordModal)

    return title, row, button
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
    if success then
        State.Validating = false
        stopLoadingVisual()
        if UI.ValidateButton then
            tween(UI.ValidateButton, TweenInfoSet.Soft, { BackgroundTransparency = 0.12 })
        end
        if UI.WindowAcrylic and UI.WindowAcrylic.Border then
            tween(UI.WindowAcrylic.Border, TweenInfoSet.Soft, {
                Color = Color3.fromRGB(210, 218, 255),
                Transparency = 0.34,
            })
        end
        if UI.WindowScale then
            tween(
                UI.WindowScale,
                TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                { Scale = State.ScaleTarget * 0.985 }
            )
        end
        task.delay(0.18, function()
            if not State.Destroyed then
                Loader:Close()
            end
        end)
        return
    end

    State.Validating = false
    stopLoadingVisual()
    setInputLocked(false)
    if UI.StatusText then
        UI.StatusText.TextTransparency = 1
    end
    if UI.StatusLine then
        UI.StatusLine.BackgroundTransparency = 1
    end
    setStatus("error", message or "Validation failed")
    if UI.StatusText then
        tween(UI.StatusText, TweenInfoSet.Soft, { TextTransparency = 0.14 })
    end
    if UI.StatusLine then
        tween(UI.StatusLine, TweenInfoSet.Soft, { BackgroundTransparency = 0.46 })
    end
    if UI.FormGroup then
        local original = UI.FormGroup.Position
        tween(UI.FormGroup, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = original + UDim2.fromOffset(0, 2),
        })
        task.delay(0.08, function()
            if UI.FormGroup and UI.FormGroup.Parent then
                tween(
                    UI.FormGroup,
                    TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                    { Position = original }
                )
            end
        end)
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
        if UI.StatusText then
            tween(UI.StatusText, TweenInfoSet.Soft, { TextTransparency = 0.14 })
        end
        if UI.StatusLine then
            tween(UI.StatusLine, TweenInfoSet.Soft, { BackgroundTransparency = 0.46 })
        end
        return
    end
    if type(State.ValidateCallback) ~= "function" then
        setStatus("error", "Validator unavailable")
        if UI.StatusText then
            tween(UI.StatusText, TweenInfoSet.Soft, { TextTransparency = 0.14 })
        end
        if UI.StatusLine then
            tween(UI.StatusLine, TweenInfoSet.Soft, { BackgroundTransparency = 0.46 })
        end
        return
    end

    State.Validating = true
    setInputLocked(true)
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
    if State.Destroyed or State.Validating or State.DiscordModalOpen then
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
        or pointInObject(UI.ContactDiscordButton, point)
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
    local velocity = (pointer - State.Drag.LastPointer) / dt
    if velocity.Magnitude > 4200 then
        velocity = velocity.Unit * 4200
    end
    local nextCenter = State.Drag.StartCenter + delta
    State.Drag.Velocity = velocity
    State.Drag.LastPointer = pointer
    State.Drag.LastTime = now
    State.Drag.TargetCenter = nextCenter
    State.Drag.CurrentCenter = nextCenter
    State.Center = nextCenter
    if UI.WindowHost then
        UI.WindowHost.Position = UDim2.fromOffset(nextCenter.X, nextCenter.Y)
    end
end

local function updateDrag(dt)
    if State.Destroyed or not UI.WindowHost then
        return
    end
    local drag = State.Drag
    if drag.Active then
        return
    end

    if drag.Velocity.Magnitude > 8 then
        local nextCenter = drag.CurrentCenter + drag.Velocity * dt * 0.34
        drag.CurrentCenter = nextCenter
        drag.TargetCenter = nextCenter
        State.Center = nextCenter
        UI.WindowHost.Position = UDim2.fromOffset(nextCenter.X, nextCenter.Y)
        drag.Velocity *= math.exp(-dt * 9.8)
    end
end

local function createField(parent, name, y, isInput)
    local field = new("Frame", {
        Name = name,
        Size = UDim2.fromOffset(270, 54),
        Position = UDim2.fromOffset(122, y),
        BackgroundColor3 = Color3.fromRGB(4, 6, 10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 42,
        Parent = parent,
    })

    local aura = new("Frame", {
        Name = "FocusAura",
        Size = UDim2.new(1, -10, 0, 22),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -3),
        BackgroundColor3 = Theme.AccentHot,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 42,
        Parent = field,
    })
    corner(aura, 18)
    gradient(
        aura,
        ColorSequence.new(Theme.AccentHot, Theme.AccentDeep),
        0,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.78),
            NumberSequenceKeypoint.new(0.52, 0.52),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    local line = new("Frame", {
        Name = "BottomLine",
        Size = UDim2.new(1, -18, 0, 1),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -6),
        BackgroundColor3 = Theme.LineSoft,
        BackgroundTransparency = 0.68,
        BorderSizePixel = 0,
        ZIndex = 44,
        Parent = field,
    })

    local caption = new("TextLabel", {
        Name = "Caption",
        Size = UDim2.new(1, -58, 0, 18),
        Position = UDim2.fromOffset(18, 6),
        BackgroundTransparency = 1,
        Text = isInput and "Enter Key" or "Status",
        TextColor3 = Theme.TextMuted,
        TextTransparency = 0.34,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 45,
        Parent = field,
    })

    if isInput then
        local box = new("TextBox", {
            Name = "Input",
            Size = UDim2.new(1, -68, 0, 25),
            Position = UDim2.fromOffset(18, 24),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            ClearTextOnFocus = false,
            Text = "",
            PlaceholderText = "Enter your key...",
            PlaceholderColor3 = Color3.fromRGB(88, 94, 116),
            TextColor3 = Theme.Text,
            TextTransparency = 0.07,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextWrapped = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 46,
            Parent = field,
        })
        createTinyUserIcon(field, 46)
        connect(box.Focused, function()
            tween(line, TweenInfoSet.Soft, {
                BackgroundColor3 = Color3.fromRGB(225, 230, 255),
                BackgroundTransparency = 0.1,
                Size = UDim2.new(1, -10, 0, 1),
            })
            tween(aura, TweenInfoSet.Soft, { BackgroundTransparency = 0.88 })
            tween(caption, TweenInfoSet.Soft, { TextTransparency = 0.18 })
        end)
        connect(box.FocusLost, function(enterPressed)
            tween(line, TweenInfoSet.Soft, {
                BackgroundColor3 = Theme.LineSoft,
                BackgroundTransparency = 0.68,
                Size = UDim2.new(1, -18, 0, 1),
            })
            tween(aura, TweenInfoSet.Soft, { BackgroundTransparency = 1 })
            tween(caption, TweenInfoSet.Soft, { TextTransparency = 0.34 })
            if enterPressed then
                validateKey()
            end
        end)
        return field, box, line, caption
    end

    local value = new("TextLabel", {
        Name = "Value",
        Size = UDim2.new(1, -68, 0, 25),
        Position = UDim2.fromOffset(18, 24),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Text = "Status",
        TextColor3 = Theme.TextDim,
        TextTransparency = 0.14,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 46,
        Parent = field,
    })
    createTinyKeyIcon(field, 46)
    return field, value, line, caption
end

local function createShadow(parent)
    for index = 1, 7 do
        local spread = 16 + index * 12
        local shadow = new("Frame", {
            Name = "SoftShadow",
            Size = UDim2.new(1, spread, 1, spread),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 7 + index * 2),
            BackgroundColor3 = index <= 2 and Color3.fromRGB(6, 8, 14) or Color3.new(0, 0, 0),
            BackgroundTransparency = 0.82 + index * 0.018,
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = parent,
        })
        corner(shadow, 18 + index * 5)
    end
end

local function createValidationOverlay(parent)
    local overlay = new("CanvasGroup", {
        Name = "ValidationOverlay",
        Size = UDim2.fromScale(1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(2, 3, 6),
        BackgroundTransparency = 0.72,
        GroupTransparency = 1,
        Visible = false,
        BorderSizePixel = 0,
        ZIndex = 250,
        Parent = parent,
    })
    corner(overlay, 12)
    UI.ValidationOverlayScale = new("UIScale", { Scale = 0.94, Parent = overlay })

    local diffusion = new("Frame", {
        Name = "OverlayDiffusion",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(16, 20, 32),
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
        ZIndex = 251,
        Parent = overlay,
    })
    corner(diffusion, 12)
    gradient(
        diffusion,
        ColorSequence.new(Color3.fromRGB(44, 50, 72), Color3.fromRGB(3, 4, 8)),
        90,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.7),
            NumberSequenceKeypoint.new(0.56, 0.92),
            NumberSequenceKeypoint.new(1, 0.82),
        })
    )

    local spinner = new("Frame", {
        Name = "RouletteSpinner",
        Size = UDim2.fromOffset(76, 76),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 260,
        Parent = overlay,
    })
    UI.ValidationSpinner = spinner
    UI.SpinnerSegments = {}

    local bloom = new("Frame", {
        Name = "SpinnerGlow",
        Size = UDim2.fromOffset(82, 82),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(178, 190, 255),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        ZIndex = 258,
        Parent = spinner,
    })
    corner(bloom, 82)
    gradient(
        bloom,
        ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(130, 150, 235)),
        0,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.72),
            NumberSequenceKeypoint.new(0.48, 0.42),
            NumberSequenceKeypoint.new(1, 1),
        })
    )

    for index = 1, 14 do
        local angle = (index - 1) * (360 / 14)
        local segment = new("Frame", {
            Name = "Segment" .. index,
            Size = UDim2.fromOffset(3, 15),
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(230, 234, 255),
            BackgroundTransparency = 0.42 + index * 0.026,
            BorderSizePixel = 0,
            Rotation = angle,
            ZIndex = 261,
            Parent = spinner,
        })
        segment.Position = UDim2.new(0.5, math.sin(math.rad(angle)) * 28, 0.5, -math.cos(math.rad(angle)) * 28)
        corner(segment, 3)
        UI.SpinnerSegments[index] = segment
    end

    local label = new("TextLabel", {
        Name = "LoadingText",
        Size = UDim2.fromOffset(240, 24),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.5, 52),
        BackgroundTransparency = 1,
        Text = letterSpaced("Validating Access"),
        TextColor3 = Color3.fromRGB(198, 204, 232),
        TextTransparency = 0.42,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 261,
        Parent = overlay,
    })

    UI.ValidationOverlay = overlay
    return overlay
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
    tween(UI.Blur, TweenInfoSet.Open, { Size = 8 })

    UI.Root = new("Frame", {
        Name = "Root",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
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
    UI.WindowAcrylic = createAcrylic(UI.Window, 8, 12, Theme.Panel, 0.74)

    UI.LeftPanel = new("Frame", {
        Name = "LeftPanel",
        Size = UDim2.new(0, 490, 1, 0),
        BackgroundColor3 = Theme.InkSoft,
        BackgroundTransparency = 0.74,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 20,
        Parent = UI.Window,
    })
    createAcrylic(UI.LeftPanel, 20, 12, Color3.fromRGB(7, 10, 18), 0.78)

    UI.SplitLine = new("Frame", {
        Name = "PanelSplit",
        Size = UDim2.new(0, 1, 1, -34),
        Position = UDim2.fromOffset(490, 17),
        BackgroundColor3 = Color3.fromRGB(18, 23, 36),
        BackgroundTransparency = 0.68,
        BorderSizePixel = 0,
        ZIndex = 38,
        Parent = UI.Window,
    })

    UI.RightPanel = new("Frame", {
        Name = "RightPanel",
        Size = UDim2.new(1, -490, 1, 0),
        Position = UDim2.fromOffset(490, 0),
        BackgroundColor3 = Color3.fromRGB(5, 7, 12),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 30,
        Parent = UI.Window,
    })
    createAcrylic(UI.RightPanel, 30, 12, Color3.fromRGB(5, 7, 12), 0.74)

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
    UI.ContactTitle, UI.ContactRow, UI.ContactDiscordButton = createContactSection(UI.FormGroup)

    createValidationOverlay(UI.Window)

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
    connect(UI.Root:GetPropertyChangedSignal("AbsoluteSize"), reflowToasts)
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
    tween(UI.Root, TweenInfoSet.Open, { BackgroundTransparency = 0.48 })
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
    if not UI.ToastLayer then
        return nil
    end

    if #State.Toasts >= 4 then
        State.ToastQueue[#State.ToastQueue + 1] = config
        return nil
    end

    local accent, icon = toastColor(string.lower(tostring(config.Type or "info")))
    if type(config.Icon) == "string" then
        local iconName = string.lower(config.Icon)
        if iconName == "shield-check" or iconName == "check" or iconName == "check-circle" then
            icon = "✓"
        elseif iconName == "x" or iconName == "x-circle" or iconName == "alert" then
            icon = "!"
        elseif iconName == "info" then
            icon = "i"
        elseif iconName == "loader" or iconName == "loading" then
            icon = "…"
        end
    end

    local width, height = getToastMetrics()
    local wrapper = new("CanvasGroup", {
        Name = "Toast",
        Size = UDim2.fromOffset(width, height),
        AnchorPoint = Vector2.new(1, 0),
        Position = getToastPosition(1, true),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        ClipsDescendants = false,
        ZIndex = 306,
        Parent = UI.ToastLayer,
    })
    local wrapperScale = new("UIScale", { Scale = 0.965, Parent = wrapper })
    local card = createToastMaterial(wrapper, accent)

    local iconFrame = new("Frame", {
        Name = "IconFrame",
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.fromOffset(17, 18),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = 322,
        Parent = card,
    })
    corner(iconFrame, 13)
    stroke(iconFrame, accent, 1, 0.66)
    local iconGlow = new("Frame", {
        Name = "IconGlow",
        Size = UDim2.new(1, 10, 1, 10),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        ZIndex = 321,
        Parent = iconFrame,
    })
    corner(iconGlow, 18)

    new("TextLabel", {
        Name = "Icon",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = icon,
        TextColor3 = accent,
        TextTransparency = 0.03,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 323,
        Parent = iconFrame,
    })

    local titleText = tostring(config.Title or "Notification")
    local subtitleText = tostring(config.Subtitle or "")
    local title = new("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -82, 0, subtitleText == "" and 32 or 22),
        Position = UDim2.fromOffset(68, subtitleText == "" and 25 or 18),
        BackgroundTransparency = 1,
        Text = titleText,
        TextColor3 = Color3.fromRGB(240, 243, 255),
        TextTransparency = 0.02,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 323,
        Parent = card,
    })

    if subtitleText ~= "" then
        new("TextLabel", {
            Name = "Subtitle",
            Size = UDim2.new(1, -82, 0, 32),
            Position = UDim2.fromOffset(68, 42),
            BackgroundTransparency = 1,
            Text = subtitleText,
            TextColor3 = Color3.fromRGB(154, 162, 190),
            TextTransparency = 0.12,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 323,
            Parent = card,
        })
    else
        title.TextSize = 14
    end

    local progressTrack = new("Frame", {
        Name = "LifetimeTrack",
        Size = UDim2.new(1, -28, 0, 1),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -8),
        BackgroundColor3 = Color3.fromRGB(80, 88, 118),
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        ZIndex = 324,
        Parent = card,
    })
    corner(progressTrack, 1)

    local progressFill = new("Frame", {
        Name = "LifetimeIndicator",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        ZIndex = 325,
        Parent = progressTrack,
    })
    corner(progressFill, 1)
    gradient(
        progressFill,
        ColorSequence.new(Color3.fromRGB(245, 247, 255), accent),
        0,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.12),
            NumberSequenceKeypoint.new(1, 0.36),
        })
    )

    local toast = { Gui = wrapper, Card = card, Scale = wrapperScale, Token = os.clock(), Removing = false }
    table.insert(State.Toasts, 1, toast)
    reflowToasts()
    tween(wrapper, TweenInfoSet.Toast, {
        Position = getToastPosition(1, false),
        GroupTransparency = 0,
    })
    tween(wrapperScale, TweenInfoSet.Toast, { Scale = 1 })

    local duration = math.max(tonumber(config.Duration) or 3, 0.5)
    toast.ProgressTween = tween(
        progressFill,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, 0, 1, 0) }
    )
    if toast.ProgressTween then
        toast.ProgressTween.Completed:Once(function()
            if not State.Destroyed then
                removeToast(toast)
            end
        end)
    else
        task.delay(duration, function()
            if not State.Destroyed then
                removeToast(toast)
            end
        end)
    end

    return wrapper
end
local function cleanupVisuals()
    disconnect(State.LoadingConnection)
    State.LoadingConnection = nil
    disconnect(State.CameraViewportConnection)
    State.CameraViewportConnection = nil

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
        UI.Blur = nil
    end
    if UI.ScreenGui then
        UI.ScreenGui:Destroy()
        UI.ScreenGui = nil
    end
    table.clear(State.Toasts)
    table.clear(State.ToastQueue)
    table.clear(UI)
    State.Destroyed = true
end

function Loader:Close(callback)
    if State.Destroyed then
        if type(callback) == "function" then
            task.defer(callback)
        end
        return self
    end
    if not State.Open then
        if type(callback) == "function" then
            task.defer(callback)
        end
        return self
    end

    State.Open = false
    State.Validating = false
    setInputLocked(true)
    disconnect(State.LoadingConnection)
    State.LoadingConnection = nil

    if UI.ValidationOverlay then
        UI.ValidationOverlay.Visible = false
    end
    if UI.Blur then
        tween(UI.Blur, TweenInfoSet.Close, { Size = 0 })
    end
    if UI.Root then
        tween(UI.Root, TweenInfoSet.Close, { BackgroundTransparency = 1 })
    end
    if UI.WindowScale then
        tween(UI.WindowScale, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Scale = math.max((State.ScaleTarget or 1) * 0.982, 0.01),
        })
    end

    local function finalizeClose()
        cleanupVisuals()
        if type(callback) == "function" then
            callback()
        end
    end

    if UI.Window then
        local closeTween = tween(UI.Window, TweenInfoSet.Close, { GroupTransparency = 1 })
        if closeTween then
            closeTween.Completed:Once(finalizeClose)
        else
            finalizeClose()
        end
    else
        finalizeClose()
    end
    return self
end

function Loader:Destroy()
    if State.Destroyed then
        return self
    end
    State.Open = false
    State.Validating = false
    cleanupVisuals()
    return self
end

buildInterface()

return Loader
