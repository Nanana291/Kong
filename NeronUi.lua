-- NeronUi 1.0 — reference-measured, client-only, dependency-free.
-- require(ModuleScript) or loadstring(readfile(...))() returns the library; nothing auto-opens.
-- Set(value [, silent]) fires Callback only on change. Defaults are silent.
-- Range:Set(low, high [, silent]); Color:Set(color [, silent]); callbacks receive snapshots.
-- Numeric controls: Step/Increment, Prefix, Suffix, Rounding. Values are finite and clamped.
-- Parent may be supplied for Studio. Otherwise protected UI -> CoreGui -> PlayerGui.
-- Same Id replaces the previous window, including listeners, across library re-execution.
local S = {
    Tween = game:GetService("TweenService"),
    Input = game:GetService("UserInputService"),
    Players = game:GetService("Players"),
    Core = game:GetService("CoreGui"),
    Text = game:GetService("TextService"),
}
local Theme = {
    AppBackground = Color3.fromRGB(24, 23, 28),
    WindowBackground = Color3.fromRGB(14, 13, 18),
    SidebarBackground = Color3.fromRGB(16, 15, 20),
    ContentBackground = Color3.fromRGB(14, 13, 18),
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
local T = {
    Geometry = {
        Width = 872,
        Height = 548,
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
        Toggle = 10,
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
    Z = { Shell = 1, Content = 3, Dim = 20, Popover = 30, Search = 40 },
}
local U, Maid, Motion, Icons, Input, Overlay, Scroll = {}, {}, {}, {}, {}, {}, {}
local Window, Tab, SubTab, Control, Components = {}, {}, {}, {}, {}
local Library = { Version = "1.0.0", Tokens = T, Theme = Theme, Icons = {} }
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
function Icons.make(parent, name, size, color, w)
    local root = U.frame(parent, { Size = UDim2.fromOffset(size, size), ZIndex = parent.ZIndex + 1 }, w)
    local asset = Library.Icons[name] or name
    if type(asset) == "number" or (type(asset) == "string" and (asset:match("^rbx") or asset:match("^%d+$"))) then
        U.new("ImageLabel", {
            Image = type(asset) == "number" and "rbxassetid://" .. asset
                or (asset:match("^%d+$") and "rbxassetid://" .. asset or asset),
            ImageColor3 = color,
            Size = UDim2.fromScale(1, 1),
            ZIndex = root.ZIndex,
        }, root)
    else
        local function l(a, b, c, d)
            Icons.line(root, a, b, c, d, color)
        end
        local function r(x, y, z)
            Icons.ring(root, x, y, z, color)
        end
        if name == "search" then
            r(0.42, 0.42, 0.25)
            l(0.60, 0.60, 0.85, 0.85)
        elseif name == "chevron" then
            l(0.22, 0.38, 0.50, 0.65)
            l(0.5, 0.65, 0.78, 0.38)
        elseif name == "pencil" then
            l(0.25, 0.75, 0.73, 0.27)
            l(0.32, 0.80, 0.80, 0.32)
            l(0.25, 0.75, 0.20, 0.85)
        elseif name == "folder" then
            l(0.15, 0.27, 0.40, 0.27)
            l(0.4, 0.27, 0.50, 0.38)
            l(0.5, 0.38, 0.87, 0.38)
            l(0.87, 0.38, 0.87, 0.8)
            l(0.87, 0.8, 0.15, 0.8)
            l(0.15, 0.8, 0.15, 0.27)
        elseif name == "chart" then
            l(0.18, 0.2, 0.18, 0.8)
            l(0.18, 0.8, 0.85, 0.8)
            l(0.36, 0.66, 0.36, 0.50)
            l(0.55, 0.66, 0.55, 0.3)
            l(0.75, 0.66, 0.75, 0.4)
        elseif name == "profile" or name == "flag" then
            l(0.25, 0.18, 0.25, 0.88)
            l(0.25, 0.20, 0.8, 0.20)
            l(0.8, 0.20, 0.63, 0.48)
            l(0.63, 0.48, 0.25, 0.48)
        elseif name == "misc" then
            r(0.5, 0.28, 0.12)
            l(0.5, 0.42, 0.5, 0.76)
            l(0.5, 0.76, 0.23, 0.76)
            l(0.5, 0.76, 0.77, 0.76)
        elseif name == "empty" then
            r(0.5, 0.5, 0.40)
            r(0.36, 0.43, 0.025)
            r(0.64, 0.43, 0.025)
            l(0.35, 0.67, 0.43, 0.61)
            l(0.43, 0.61, 0.57, 0.61)
            l(0.57, 0.61, 0.65, 0.67)
        elseif name == "menu" then
            l(0.18, 0.28, 0.82, 0.28)
            l(0.18, 0.5, 0.82, 0.5)
            l(0.18, 0.72, 0.82, 0.72)
        elseif name == "brand" then
            for i = 0, 2 do
                U.new("Frame", {
                    Position = UDim2.fromScale(0.24 - i * 0.06, 0.22 + i * 0.23),
                    Size = UDim2.fromScale(0.58, 0.14),
                    Rotation = -28,
                    BackgroundTransparency = 0,
                    BackgroundColor3 = color,
                    ZIndex = root.ZIndex,
                }, root)
            end
        elseif name == "discord" then
            r(0.5, 0.5, 0.32)
            r(0.37, 0.48, 0.025)
            r(0.63, 0.48, 0.025)
            l(0.33, 0.65, 0.67, 0.65)
        else
            r(0.5, 0.5, 0.23)
            for i = 0, 7 do
                local a = i * math.pi / 4
                l(
                    0.5 + math.cos(a) * 0.27,
                    0.5 + math.sin(a) * 0.27,
                    0.5 + math.cos(a) * 0.39,
                    0.5 + math.sin(a) * 0.39
                )
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
function Overlay:Open(owner, anchor, width, height, build)
    self:Close(true)
    local w = self.w
    if w.destroyed or not w.visible or w.searchOpen or not owner:_usable() then
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
        local content = layout.AbsoluteContentSize.Y / scale + 4
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
    if not self:_canNavigate() or tab.destroyed or tab.disabled or not tab.visible then
        return
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
    if self.destroyed then
        return self
    end
    self.theme.Accent = color
    self.theme.AccentHover = color:Lerp(Color3.new(1, 1, 1), 0.10)
    self.theme.AccentPressed = color:Lerp(Color3.new(0, 0, 0), 0.22)
    self.theme.AccentMuted = color:Lerp(self.theme.WindowBackground, 0.76)
    for obj, bindings in pairs(self.bindings) do
        if obj.Parent then
            for property, token in pairs(bindings) do
                self.motion:Cancel(obj, property)
                obj[property] = self.theme[token]
            end
        end
    end
    Icons.color(self.brandIcon, color)
    for _, tab in ipairs(self.tabs) do
        tab:_render()
        for _, sub in ipairs(tab.subtabs) do
            sub:_render()
            for _, control in ipairs(sub.controls) do
                control:_render()
            end
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
        self.overlay:Close(true)
        self:CloseSearch(true)
        self.input:Cancel()
        U.focusRelease(self)
    end
    self.gui.Enabled = self.visible
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
function Window:_responsive()
    if self.destroyed then
        return
    end
    self.overlay:Close(true)
    self.input:Cancel()
    local view = self.stage.AbsoluteSize
    if view.X <= 0 or view.Y <= 0 then
        return
    end
    local portrait = view.X < 600 or (view.Y > view.X and view.X < 900)
    local width = portrait and math.max(320, view.X - 16) or self.baseWidth
    local height = portrait and math.max(400, math.min(self.baseHeight, view.Y - 24)) or self.baseHeight
    self.scale = math.min(1, (view.X - 16) / width, (view.Y - 24) / height)
    self.scale = math.max(0.30, self.scale)
    self.compact = portrait
    self.root.Size = UDim2.fromOffset(width, height)
    self.uiScale.Scale = self.scale
    local side = portrait and 0 or T.Geometry.Sidebar
    self.content.Position = UDim2.fromOffset(side, 0)
    self.content.Size = UDim2.new(1, -side, 1, 0)
    self.menu.Visible = portrait
    self.sidebar.Size = UDim2.new(0, T.Geometry.Sidebar, 1, 0)
    self:SetSidebarVisible(self.sidebarOpen and portrait)
    self.searchPanel.Position = UDim2.new(0, portrait and 12 or T.Geometry.SearchInset, 0, T.Geometry.Header)
    self.searchPanel.Size = UDim2.new(1, -(portrait and 24 or T.Geometry.SearchInset * 2), 1, -T.Geometry.Header - 18)
    for _, tab in ipairs(self.tabs) do
        tab.title.Position = UDim2.fromOffset(portrait and 48 or 16, 10)
        tab.description.Position = UDim2.fromOffset(portrait and 48 or 16, 32)
        for _, sub in ipairs(tab.subtabs) do
            for _, control in ipairs(sub.controls) do
                control:_layout()
            end
            sub.scroll:Update()
        end
    end
    local size = Vector2.new(width * self.scale, height * self.scale)
    local center = self.root.Position
    local x = center.X.Scale * view.X + center.X.Offset
    local y = center.Y.Scale * view.Y + center.Y.Offset
    x = math.clamp(x, size.X * 0.5, math.max(size.X * 0.5, view.X - size.X * 0.5))
    y = math.clamp(y, size.Y * 0.5, math.max(size.Y * 0.5, view.Y - size.Y * 0.5))
    self.root.Position = UDim2.fromOffset(x, y)
end
function Window:Destroy()
    if self.destroyed then
        return
    end
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
    self.motion:Destroy()
    self.bag:Destroy()
    if self.registry[self.id] == self then
        self.registry[self.id] = nil
    end
    table.clear(self.index)
    table.clear(self.Flags)
    table.clear(self.bindings)
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
        self
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
    U.connect(tab.bag, tab.row.Activated, function()
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
    sub.scroll.frame.Size = UDim2.new(1, -T.Geometry.ContentRight, 1, 0)
    sub.scroll.frame.Position = UDim2.fromOffset(T.Geometry.ContentLeft, 0)
    U.connect(sub.bag, sub.button.Activated, function()
        if not sub.disabled then
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
            Visible = config.Visible ~= false,
            Hovered = false,
            Pressed = false,
            Open = false,
        },
        inlineOwner = config.InlineWith,
        attachments = {},
        name = tostring(config.Name or kind),
        description = tostring(config.Description or ""),
        value = nil,
        flag = config.Flag,
    }, Control)
    table.insert(page.controls, self)
    table.insert(w.index, self)
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
    self.bag:Add(self.row)
    self.label =
        U.label(self.row, self.name, T.Type.ElementTitle, w.theme.TextSecondary, { Font = Enum.Font.GothamMedium })
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
    w:_indexChanged()
    return self
end
function Control:_usable()
    return not self.destroyed
        and (not self.inlineOwner or self.inlineOwner:_usable())
        and not self.state.Disabled
        and self.state.Visible
        and self.window.visible
        and not self.window.destroyed
        and not self.window.searchOpen
        and self.page.visible
        and not self.page.disabled
        and self.page.tab.visible
        and not self.page.tab.disabled
        and self.window.activeTab == self.page.tab
        and self.page.tab.activeSub == self.page
end
function Control:_layout()
    if self.destroyed then
        return
    end
    if self.inlineOwner then
        self.row.Size = UDim2.fromScale(1, 1)
        self.lane.Size = UDim2.fromOffset(32, self.inlineOwner.lane.Size.Y.Offset)
        self.lane.Position =
            UDim2.new(1, -48, self.inlineOwner.lane.Position.Y.Scale, self.inlineOwner.lane.Position.Y.Offset)
        return
    end
    local narrow = self.window.compact
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
    local width = self.row.AbsoluteSize.X / self.window.scale
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
    local color = s.Disabled and w.theme.TextDisabled or (on and w.theme.TextPrimary or w.theme.TextSecondary)
    w.motion:To(self.label, T.Motion.Micro, { TextColor3 = color })
    w.motion:To(self.desc, T.Motion.Micro, { TextColor3 = s.Disabled and w.theme.TextDisabled or w.theme.TextMuted })
    w.motion:To(self.row, T.Motion.Micro, { BackgroundColor3 = on and w.theme.RowHover or w.theme.RowBackground })
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
    local self = Components.row(self, config, "Toggle")
    self.dot = Components.circle(self.lane, T.Geometry.Toggle, self.window.theme.AccentMuted)
    self.dot.Position = UDim2.new(1, -T.Geometry.Toggle / 2, 0.5, 0)
    self.core = Components.circle(self.dot, 4, self.window.theme.RowBackground)
    self.core.Position = UDim2.fromScale(0.5, 0.5)
    function self:renderVisual()
        local w = self.window
        local color = self.state.Disabled and w.theme.TextDisabled
            or (self.value and w.theme.Accent or w.theme.AccentMuted)
        w.motion:To(self.dot, T.Motion.Fast, { BackgroundColor3 = color })
        w.motion:To(
            self.core,
            T.Motion.Fast,
            { Size = UDim2.fromOffset(self.state.Pressed and 3 or 4, self.state.Pressed and 3 or 4) }
        )
    end
    function self:Set(value, silent)
        return self:_commit(value == true, silent)
    end
    U.connect(self.bag, self.row.Activated, function()
        if self:_usable() then
            self.state.Pressed = false
            self:Set(not self.value)
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
    self:Set(config and config.Default == true, true)
    return self
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
    }, self.window, "InputBackground")
    U.corner(self.rail, 5)
    self.fill =
        U.frame(self.rail, { Size = UDim2.fromScale(0, 1), ZIndex = self.rail.ZIndex + 1 }, self.window, "Accent")
    U.corner(self.fill, 5)
    self.thumbs = {}
    for _ = 1, range and 2 or 1 do
        local thumb = Components.circle(self.rail, T.Geometry.Thumb, self.window.theme.Accent)
        local center = Components.circle(thumb, T.Geometry.ThumbCore, self.window.theme.RowBackground)
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
        local color = self.state.Disabled and self.window.theme.TextDisabled or self.window.theme.Accent
        self.fill.BackgroundColor3 = color
        for _, thumb in ipairs(self.thumbs) do
            thumb.BackgroundColor3 = color
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
                    config.Placeholder or "None"
                ))
            or tostring(self.value or config.Placeholder or "Select")
        self.valueLabel.TextColor3 = self.state.Disabled and w.theme.TextDisabled or w.theme.TextPrimary
        Icons.color(self.chevron, self.valueLabel.TextColor3)
        w.motion:To(self.chevron, T.Motion.Fast, { Rotation = self.state.Open and 180 or 0 })
        self.trigger.BackgroundColor3 = w.theme.InputBackground
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
                U.label(holder, "No options", T.Type.Description, self.window.theme.TextMuted)
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
                    if not U.primary(event) then
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
                if not U.primary(event) then
                    return
                end
                w.input:Start(self, event, function(point)
                    local x = math.clamp((point.X - sv.AbsolutePosition.X) / math.max(1, sv.AbsoluteSize.X), 0, 1)
                    local y = math.clamp((point.Y - sv.AbsolutePosition.Y) / math.max(1, sv.AbsoluteSize.Y), 0, 1)
                    applyHSV(self.hue, x, 1 - y)
                end)
            end)
            U.connect(bag, hue.InputBegan, function(event)
                if not U.primary(event) then
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
            or (active and w.theme.WindowBackground or w.theme.TextMuted)
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
function Library:CreateWindow(config)
    config = config or {}
    local size = config.Size
    local baseWidth = typeof(size) == "Vector2" and U.finite(size.X, 0) or T.Geometry.Width
    local baseHeight = typeof(size) == "Vector2" and U.finite(size.Y, 0) or T.Geometry.Height
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
    w.root = U.frame(w.stage, {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(w.baseWidth, w.baseHeight),
        ClipsDescendants = true,
        ZIndex = T.Z.Shell,
    }, w, "WindowBackground")
    U.corner(w.root, T.Radius.Window)
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
        { Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 1, -68), ZIndex = w.sidebar.ZIndex + 1 },
        w
    )
    w.input = Input.new(w)
    w.overlay = Overlay.new(w)
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
        if w.searchOpen then
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
            if w.searchOpen then
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
            if not U.primary(event) or w.searchOpen or w.overlay.active then
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
    w:_responsive()
    if config.Accent then
        w:SetAccent(config.Accent)
    end
    return w
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
    misc:AddLabel("Neron UI 1.0")
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
