--!nonstrict
-- UiLib: standalone client-side UI. Requiring this module mounts nothing.
-- Dynamic Instance factories intentionally use nonstrict mode; public value contracts are typed.
-- Usage: local w = Library:CreateWindow({Id='menu'}); w:AddTab({Name='Main'}):AddSection({Name='General'}):AddToggle({Name='Enabled'})
-- Config is JSON, never executor filesystem code. CreateReferenceDemo() and RunSelfTest() are opt-in.
export type WindowConfig = {
    Id: string?,
    Title: string?,
    Size: UDim2?,
    Accent: Color3?,
    Parent: Instance?,
    Draggable: boolean?,
    Resizable: boolean?,
    Scale: number?,
    HideKey: EnumItem?,
}
export type ControlConfig = {
    Name: string?,
    Description: string?,
    Tooltip: string?,
    Flag: string?,
    Default: unknown,
    Callback: ((...unknown) -> ())?,
    Disabled: boolean?,
    Visible: boolean?,
}
export type SliderConfig = {
    Name: string?,
    Min: number,
    Max: number,
    Default: number?,
    Increment: number?,
    Prefix: string?,
    Suffix: string?,
    Flag: string?,
    Callback: ((number) -> ())?,
}
export type ColorValue = { Color: Color3, Alpha: number }
local Library = {
    Windows = {},
    Themes = {},
    Locales = {},
    Icons = {},
    Scale = 1,
    AnimationSpeed = 1,
    CornerStyle = 1,
    Language = "en",
    Version = "1.0.0",
}
local UI = {}
UI.S = {
    Input = game:GetService("UserInputService"),
    Tween = game:GetService("TweenService"),
    Http = game:GetService("HttpService"),
    Players = game:GetService("Players"),
    Run = game:GetService("RunService"),
}
UI.Palette = {
    Base = Color3.fromRGB(20, 23, 28),
    Panel = Color3.fromRGB(24, 27, 33),
    Row = Color3.fromRGB(27, 30, 37),
    Hover = Color3.fromRGB(33, 37, 45),
    Border = Color3.fromRGB(45, 49, 59),
    Text = Color3.fromRGB(190, 192, 200),
    Muted = Color3.fromRGB(111, 115, 127),
    Faint = Color3.fromRGB(69, 74, 87),
    Thumb = Color3.fromRGB(223, 225, 232),
    Accent = Color3.fromRGB(191, 61, 222),
    Danger = Color3.fromRGB(220, 91, 108),
    Success = Color3.fromRGB(109, 190, 141),
    Warning = Color3.fromRGB(219, 172, 101),
}
UI.Radii = { Window = 18, Panel = 10, Control = 6, Popup = 10, Small = 4 }
UI.Font = Font.fromEnum(Enum.Font.BuilderSans)
UI.Duration =
    { Hover = 0.1, Press = 0.08, Toggle = 0.14, Slider = 0.09, Popup = 0.16, Color = 0.12, Nav = 0.18, Window = 0.22 }
UI.Window, UI.Tab, UI.Section, UI.Control, UI.Companion = {}, {}, {}, {}, {}
for _, class in { UI.Window, UI.Tab, UI.Section, UI.Control, UI.Companion } do
    class.__index = class
end
function UI.warn(name, message)
    warn("[UiLib/" .. tostring(name) .. "] " .. tostring(message))
end
function UI.call(name, callback, ...)
    if callback == nil then
        return
    end
    if type(callback) ~= "function" then
        UI.warn(name, "Callback must be a function")
        return
    end
    local ok, err = pcall(callback, ...)
    if not ok then
        UI.warn(name, err)
    end
end
function UI.finite(n)
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end
function UI.copy(v)
    if type(v) ~= "table" then
        return v
    end
    local result = {}
    for k, item in v do
        result[k] = UI.copy(item)
    end
    return result
end
function UI.equal(a, b)
    if type(a) ~= type(b) then
        return false
    end
    if type(a) ~= "table" then
        return a == b
    end
    for k, v in a do
        if not UI.equal(v, b[k]) then
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
function UI.bag()
    return { Items = {}, Dead = false }
end
function UI.keep(bag, item)
    if bag.Dead then
        UI.dispose(item)
    else
        bag.Items[item] = true
    end
    return item
end
function UI.dispose(item)
    local kind = typeof(item)
    if kind == "RBXScriptConnection" then
        item:Disconnect()
    elseif kind == "Instance" then
        item:Destroy()
    elseif kind == "thread" then
        if coroutine.status(item) ~= "dead" and item ~= coroutine.running() then
            pcall(task.cancel, item)
        end
    elseif kind == "function" then
        UI.call("Cleanup", item)
    elseif type(item) == "table" and item.Destroy then
        item:Destroy()
    end
end
function UI.clean(bag)
    if bag.Dead then
        return
    end
    bag.Dead = true
    for item in bag.Items do
        UI.dispose(item)
    end
    table.clear(bag.Items)
end
function UI.connect(owner, signal, fn)
    return UI.keep(owner.Bag, signal:Connect(fn))
end
-- Multiplex service events once per module; last subscriber releases the connection.
UI.InputRoutes = {}
function UI.route(owner, name, callback, sourceSignal)
    local route = UI.InputRoutes[name]
    if not route then
        route = { Listeners = {} }
        UI.InputRoutes[name] = route
        route.Connection = (sourceSignal or UI.S.Input[name]):Connect(function(...)
            for target, handler in route.Listeners do
                if not target.Dead then
                    handler(...)
                end
            end
        end)
    end
    route.Listeners[owner] = callback
    UI.keep(owner.Bag, function()
        route.Listeners[owner] = nil
        if next(route.Listeners) == nil then
            route.Connection:Disconnect()
            UI.InputRoutes[name] = nil
        end
    end)
end
function UI.later(owner, seconds, fn)
    local thread
    thread = task.delay(seconds, function()
        owner.Bag.Items[thread] = nil
        if not owner.Bag.Dead then
            fn()
        end
    end)
    UI.keep(owner.Bag, thread)
    return thread
end
function UI.new(class, parent, props)
    local obj = Instance.new(class)
    if obj:IsA("GuiObject") then
        obj.BorderSizePixel = 0
        obj.BackgroundTransparency = 1
    end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        obj.FontFace = UI.Font
        obj.TextSize = 12
        obj.TextColor3 = UI.Palette.Text
        obj.TextXAlignment = Enum.TextXAlignment.Left
        obj.Text = ""
    end
    if obj:IsA("GuiButton") then
        obj.AutoButtonColor = false
    end
    for k, v in props or {} do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end
function UI.bind(w, obj, property, token)
    local map = w.Bindings[obj]
    if not map then
        map = {}
        w.Bindings[obj] = map
    end
    map[property] = token
    obj[property] = w.Theme[token]
    return obj
end
function UI.round(w, obj, kind)
    local corner = UI.new("UICorner", obj, { CornerRadius = UDim.new(0, UI.Radii[kind] * w.CornerStyle) })
    w.Corners[corner] = kind
    return corner
end
function UI.stroke(w, obj, token, transparency)
    local s = UI.new(
        "UIStroke",
        obj,
        { Thickness = 1, Transparency = transparency or 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
    )
    UI.bind(w, s, "Color", token or "Border")
    return s
end
function UI.frame(w, parent, props, token, radius)
    local f = UI.new("Frame", parent, props)
    if token then
        f.BackgroundTransparency = 0
        UI.bind(w, f, "BackgroundColor3", token)
    end
    if radius then
        UI.round(w, f, radius)
    end
    return f
end
function UI.text(w, parent, text, props, token)
    local p = { Text = text, Size = UDim2.new(1, 0, 0, 20) }
    for k, v in props or {} do
        p[k] = v
    end
    return UI.bind(w, UI.new("TextLabel", parent, p), "TextColor3", token or "Text")
end
function UI.tween(w, obj, props, category)
    if not obj.Parent or w.Dead then
        return
    end
    local previous = w.Tweens[obj]
    if previous then
        previous:Cancel()
        w.Tweens[obj] = nil
    end
    local speed = w.AnimationSpeed
    if speed <= 0 then
        for k, v in props do
            obj[k] = v
        end
        return
    end
    local t = UI.S.Tween:Create(
        obj,
        TweenInfo.new((UI.Duration[category] or 0.14) / speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        props
    )
    w.Tweens[obj] = t
    local connection
    connection = t.Completed:Connect(function()
        connection:Disconnect()
        if w.Tweens[obj] == t then
            w.Tweens[obj] = nil
        end
    end)
    t:Play()
end
function UI.list(parent, gap, horizontal)
    return UI.new("UIListLayout", parent, {
        Padding = UDim.new(0, gap or 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
    })
end
function UI.pad(parent, n)
    UI.new("UIPadding", parent, {
        PaddingTop = UDim.new(0, n),
        PaddingBottom = UDim.new(0, n),
        PaddingLeft = UDim.new(0, n),
        PaddingRight = UDim.new(0, n),
    })
end
function UI.button(owner, parent, text, props, fn)
    local w = owner.Window or owner
    local b = UI.new("TextButton", parent, props or {})
    local restTransparency = b.BackgroundTransparency
    b.Text = text
    UI.bind(w, b, "TextColor3", "Text")
    UI.connect(owner, b.Activated, function()
        if not owner.Dead and not owner.Disabled and (b == w.Restore or w:CanInteract(b)) then
            UI.call(text, fn)
        end
    end)
    UI.connect(owner, b.MouseEnter, function()
        if not owner.Disabled then
            restTransparency = b.BackgroundTransparency
            UI.tween(w, b, { BackgroundTransparency = math.min(restTransparency, 0.35) }, "Hover")
        end
    end)
    UI.connect(owner, b.MouseLeave, function()
        UI.tween(w, b, { BackgroundTransparency = restTransparency }, "Hover")
    end)
    UI.connect(owner, b.InputBegan, function(input)
        if
            not owner.Disabled
            and (
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            )
        then
            restTransparency = b.BackgroundTransparency
            UI.tween(w, b, { BackgroundTransparency = math.min(restTransparency, 0.15) }, "Press")
        end
    end)
    UI.connect(owner, b.InputEnded, function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            UI.tween(w, b, { BackgroundTransparency = restTransparency }, "Press")
        end
    end)
    UI.bind(w, b, "BackgroundColor3", "Hover")
    UI.round(w, b, "Control")
    return b
end
-- Asset-free, coherent 16-unit line icons. Custom images retain their vector fallback.
UI.Paths = {
    search = {
        { { 3, 3 }, { 10, 3 }, { 12, 5 }, { 12, 9 }, { 10, 11 }, { 5, 11 }, { 3, 9 }, { 3, 3 } },
        {
            { 11, 11 },
            { 15, 15 },
        },
    },
    close = { { { 4, 4 }, { 12, 12 } }, { { 12, 4 }, { 4, 12 } } },
    chevron = { { { 5, 6 }, { 8, 9 }, { 11, 6 } } },
    grid = {
        { { 2, 2 }, { 6, 2 }, { 6, 6 }, { 2, 6 }, { 2, 2 } },
        { { 10, 2 }, { 14, 2 }, { 14, 6 }, { 10, 6 }, { 10, 2 } },
        { { 2, 10 }, { 6, 10 }, { 6, 14 }, { 2, 14 }, { 2, 10 } },
        { { 10, 10 }, { 14, 10 }, { 14, 14 }, { 10, 14 }, { 10, 10 } },
    },
    target = {
        { { 2, 6 }, { 2, 2 }, { 6, 2 } },
        { { 10, 2 }, { 14, 2 }, { 14, 6 } },
        { { 14, 10 }, { 14, 14 }, { 10, 14 } },
        { { 6, 14 }, { 2, 14 }, { 2, 10 } },
        { { 5, 8 }, { 11, 8 } },
        { { 8, 5 }, { 8, 11 } },
    },
    logo = { { { 8, 1 }, { 14, 4 }, { 14, 12 }, { 8, 15 }, { 2, 12 }, { 2, 4 }, { 8, 1 } }, { { 7, 8 }, { 9, 8 } } },
    profile = {
        { { 5, 3 }, { 8, 1 }, { 11, 3 }, { 11, 6 }, { 8, 8 }, { 5, 6 }, { 5, 3 } },
        {
            { 2, 15 },
            { 2, 12 },
            { 5, 10 },
            { 11, 10 },
            { 14, 12 },
            { 14, 15 },
        },
    },
    settings = {
        { { 8, 2 }, { 12, 4 }, { 14, 8 }, { 12, 12 }, { 8, 14 }, { 4, 12 }, { 2, 8 }, { 4, 4 }, { 8, 2 } },
        {
            { 6, 6 },
            { 10, 6 },
            { 10, 10 },
            { 6, 10 },
            { 6, 6 },
        },
    },
    check = { { { 3, 8 }, { 6, 11 }, { 13, 4 } } },
    play = { { { 5, 3 }, { 12, 8 }, { 5, 13 }, { 5, 3 } } },
    previous = { { { 3, 3 }, { 3, 13 } }, { { 12, 3 }, { 5, 8 }, { 12, 13 }, { 12, 3 } } },
    next = { { { 13, 3 }, { 13, 13 } }, { { 4, 3 }, { 11, 8 }, { 4, 13 }, { 4, 3 } } },
    copy = { { { 6, 2 }, { 14, 2 }, { 14, 10 } }, { { 2, 6 }, { 10, 6 }, { 10, 14 }, { 2, 14 }, { 2, 6 } } },
    ellipsis = { { { 3, 8 }, { 3.5, 8 } }, { { 8, 8 }, { 8.5, 8 } }, { { 13, 8 }, { 13.5, 8 } } },
    resize = { { { 7, 14 }, { 14, 7 } }, { { 11, 14 }, { 14, 11 } } },
}
function UI.line(w, parent, a, b, token, width)
    local d = b - a
    return UI.frame(w, parent, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
        Size = UDim2.fromOffset(math.max(d.Magnitude, 0.5), width or 1),
        Rotation = math.deg(math.atan2(d.Y, d.X)),
    }, token)
end
function UI.icon(w, parent, name, props, token)
    local f = UI.frame(w, parent, props or { Size = UDim2.fromOffset(16, 16) })
    local resolved = Library.Icons[name] or name or "grid"
    local paths = UI.Paths[resolved] or UI.Paths.grid
    for _, path in paths do
        for i = 2, #path do
            UI.line(w, f, Vector2.new(unpack(path[i - 1])), Vector2.new(unpack(path[i])), token or "Muted", 1)
        end
    end
    if type(resolved) == "number" or (type(resolved) == "string" and string.find(resolved, "rbxasset", 1, true)) then
        UI.new("ImageLabel", f, {
            Size = UDim2.fromScale(1, 1),
            Image = type(resolved) == "number" and ("rbxassetid://" .. resolved) or resolved,
        })
    elseif not UI.Paths[resolved] then
        UI.warn("Icon", "Unknown icon " .. tostring(resolved) .. "; using grid")
    end
    return f
end
function UI.inside(obj, p)
    local a, s = obj.AbsolutePosition, obj.AbsoluteSize
    return obj.Visible and p.X >= a.X and p.Y >= a.Y and p.X <= a.X + s.X and p.Y <= a.Y + s.Y
end
function UI.point(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end
function UI.releaseDrag(w)
    local drag = w.Router.Drag
    if drag and drag.Scroll and drag.Scroll.Parent then
        drag.Scroll.ScrollingEnabled = drag.WasScrolling
    end
    if UI.ActiveDrag == w then
        UI.ActiveDrag = nil
    end
    w.Router.Drag = nil
end
function UI.drag(owner, hit, onStart, onMove, onEnd)
    local w = owner.Window or owner
    UI.connect(owner, hit.InputBegan, function(input)
        if owner.Dead or owner.Disabled or UI.S.Input:GetFocusedTextBox() or w.Router.Drag or UI.ActiveDrag then
            return
        end
        if
            input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end
        if not w:CanInteract(hit) then
            return
        end
        local p = UI.point(input)
        local state = onStart(p, input)
        if state == false then
            return
        end
        local scroll = hit.Parent
        while scroll and not scroll:IsA("ScrollingFrame") do
            scroll = scroll.Parent
        end
        local wasScrolling = scroll and scroll.ScrollingEnabled
        if scroll then
            scroll.ScrollingEnabled = false
        end
        w.Router.Drag = {
            Owner = owner,
            Input = input,
            Move = onMove,
            End = onEnd,
            State = state,
            Scroll = scroll,
            WasScrolling = wasScrolling,
        }
        UI.ActiveDrag = w
        onMove(p, state)
    end)
end
function UI.locale(w, key)
    return (Library.Locales[w.Language] or {})[key] or Library.Locales.en[key] or key
end
Library.Locales.en = {
    Search = "Search functions",
    NoResults = "No results",
    Copy = "Copy",
    Close = "Close",
    Clear = "Clear",
    SelectAll = "Select all",
    Reset = "Reset",
    Cancel = "Cancel",
    Confirm = "Confirm",
}
Library.Locales.es = {
    Search = "Buscar funciones",
    NoResults = "Sin resultados",
    Copy = "Copiar",
    Close = "Cerrar",
    Clear = "Limpiar",
    SelectAll = "Seleccionar todo",
    Reset = "Restablecer",
    Cancel = "Cancelar",
    Confirm = "Confirmar",
}
-- One popup stack per window; nested popovers never live under a clipped settings row.
function UI.Window:CanInteract(obj)
    if self.Dead or not self.Visible then
        return false
    end
    if self.Modal and not obj:IsDescendantOf(self.Modal.Frame) then
        return false
    end
    return true
end
function UI.Window:ClosePopups(from)
    for i = #self.Popups, from or 1, -1 do
        local p = table.remove(self.Popups, i)
        if self.Router.Drag and self.Router.Drag.Owner.Popup == p then
            UI.releaseDrag(self)
        end
        p.Dead = true
        UI.clean(p.Bag)
        p.Frame:Destroy()
        if p.OnClose then
            p.OnClose()
        end
    end
end
function UI.Window:OpenPopover(anchor, size, parentPopup)
    local depth = 1
    if parentPopup then
        for i, p in self.Popups do
            if p == parentPopup then
                depth = i + 1
                break
            end
        end
    end
    self:ClosePopups(depth)
    local p = { Window = self, Bag = UI.bag(), Anchor = anchor, Depth = depth, Size = size }
    p.Frame = UI.frame(
        self,
        self.Overlay,
        { Size = UDim2.fromOffset(size.X, size.Y), ZIndex = 30 + depth * 10, Active = true },
        "Panel",
        "Popup"
    )
    UI.stroke(self, p.Frame, "Border", 0.4)
    p.Content = UI.frame(self, p.Frame, { Size = UDim2.fromScale(1, 1), ClipsDescendants = true })
    table.insert(self.Popups, p)
    function p:Place()
        if self.Dead or not self.Anchor.Parent then
            return
        end
        local root = self.Window.Root
        local bounds = root.AbsoluteSize
        local origin = root.AbsolutePosition
        local a = self.Anchor.AbsolutePosition - origin
        local s = self.Anchor.AbsoluteSize
        local width = math.min(self.Size.X, bounds.X - 16)
        local height = math.min(self.Size.Y, bounds.Y - 16)
        local x, y = a.X, a.Y + s.Y + 6
        if self.Depth > 1 then
            x = a.X + s.X + 8
            y = a.Y
        end
        if x + width > bounds.X - 8 then
            x = if self.Depth > 1 then a.X - width - 8 else bounds.X - width - 8
        end
        if y + height > bounds.Y - 8 then
            y = if self.Depth > 1 then bounds.Y - height - 8 else a.Y - height - 6
        end
        self.Frame.Size = UDim2.fromOffset(width, height)
        self.Frame.Position = UDim2.fromOffset(
            math.clamp(x, 8, math.max(8, bounds.X - width - 8)),
            math.clamp(y, 8, math.max(8, bounds.Y - height - 8))
        )
    end
    function p:Destroy()
        if not self.Dead then
            self.Window:ClosePopups(self.Depth)
        end
    end
    p:Place()
    UI.connect(p, anchor:GetPropertyChangedSignal("AbsolutePosition"), function()
        p:Place()
    end)
    UI.connect(p, anchor.AncestryChanged, function()
        if not anchor:IsDescendantOf(self.Root) then
            p:Destroy()
        end
    end)
    p.Frame.BackgroundTransparency = 1
    UI.tween(self, p.Frame, { BackgroundTransparency = 0 }, "Popup")
    return p
end
function UI.Window:Tooltip(anchor, text)
    if self.TooltipFrame then
        self.TooltipFrame:Destroy()
        self.TooltipFrame = nil
    end
    if not text or text == "" then
        return
    end
    local f = UI.frame(
        self,
        self.Overlay,
        { Size = UDim2.fromOffset(math.min(280, self.Root.AbsoluteSize.X - 20), 52), ZIndex = 150 },
        "Panel",
        "Small"
    )
    UI.stroke(self, f)
    UI.text(self, f, text, { Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 1, -12), TextWrapped = true })
    local a = anchor.AbsolutePosition - self.Root.AbsolutePosition
    f.Position = UDim2.fromOffset(
        math.clamp(a.X, 8, math.max(8, self.Root.AbsoluteSize.X - f.AbsoluteSize.X - 8)),
        math.clamp(a.Y + anchor.AbsoluteSize.Y + 7, 8, math.max(8, self.Root.AbsoluteSize.Y - 60))
    )
    self.TooltipFrame = f
    self.TooltipAnchor = anchor
end
function UI.tooltip(owner, anchor, getText)
    local w = owner.Window or owner
    local pending
    local function cancel()
        if pending then
            UI.dispose(pending)
            owner.Bag.Items[pending] = nil
            pending = nil
        end
        if w.TooltipFrame and w.TooltipAnchor == anchor then
            w.TooltipFrame:Destroy()
            w.TooltipFrame = nil
        end
    end
    UI.connect(owner, anchor.MouseEnter, function()
        cancel()
        pending = UI.later(owner, 0.55, function()
            w:Tooltip(anchor, getText())
        end)
    end)
    UI.connect(owner, anchor.MouseLeave, cancel)
    UI.connect(owner, anchor.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            cancel()
            pending = UI.later(owner, 0.65, function()
                if not w.Router.Drag then
                    w:Tooltip(anchor, getText())
                end
            end)
        end
    end)
    UI.connect(owner, anchor.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            cancel()
        end
    end)
    UI.keep(owner.Bag, cancel)
end
function Library:CreateWindow(config)
    config = config or {}
    assert(UI.S.Run:IsClient(), "[UiLib] CreateWindow requires a client")
    local player = UI.S.Players.LocalPlayer
    local parent = config.Parent or (player and player:FindFirstChildOfClass("PlayerGui"))
    assert(
        parent and typeof(parent) == "Instance",
        "[UiLib] Supply a valid Parent, or wait for PlayerGui before CreateWindow"
    )
    assert(config.Size == nil or typeof(config.Size) == "UDim2", "[UiLib] Size must be UDim2")
    assert(config.Position == nil or typeof(config.Position) == "UDim2", "[UiLib] Position must be UDim2")
    assert(config.MinSize == nil or typeof(config.MinSize) == "Vector2", "[UiLib] MinSize must be Vector2")
    assert(config.MaxSize == nil or typeof(config.MaxSize) == "Vector2", "[UiLib] MaxSize must be Vector2")
    assert(config.Accent == nil or typeof(config.Accent) == "Color3", "[UiLib] Accent must be Color3")
    local id = tostring(config.Id or "default")
    -- Synchronous disposal completes before replacement; safe with deferred engine signals.
    for _, old in parent:GetChildren() do
        if old:IsA("ScreenGui") and old:GetAttribute("UiLibId") == id then
            local stop = old:FindFirstChild("UiLibDispose")
            if stop and stop:IsA("BindableFunction") then
                local ok, err = pcall(function()
                    stop:Invoke()
                end)
                if not ok then
                    UI.warn("Reexecution", err)
                end
            end
            old:Destroy()
        end
    end
    local w = setmetatable({
        Window = nil,
        Id = id,
        Title = config.Title or "Interface",
        Bag = UI.bag(),
        Theme = UI.copy(self.Theme or UI.Palette),
        Bindings = setmetatable({}, { __mode = "k" }),
        Corners = setmetatable({}, { __mode = "k" }),
        Tweens = {},
        Popups = {},
        Tabs = {},
        Controls = {},
        Flags = {},
        Companions = {},
        Router = {},
        Visible = true,
        Touch = UI.S.Input.TouchEnabled,
        Scale = UI.finite(config.Scale) and math.clamp(config.Scale, 0.75, 1.5) or self.Scale,
        AnimationSpeed = self.AnimationSpeed,
        CornerStyle = self.CornerStyle,
        Language = self.Language,
        Draggable = config.Draggable ~= false,
        Resizable = config.Resizable == true,
        DesiredSize = config.Size or UDim2.fromOffset(800, 540),
        HideKey = config.HideKey or Enum.KeyCode.RightShift,
        MinSize = config.MinSize or Vector2.new(340, 300),
        MaxSize = config.MaxSize or Vector2.new(1600, 1100),
    }, UI.Window)
    w.Window = w
    if config.Accent then
        assert(typeof(config.Accent) == "Color3", "[UiLib] Accent must be Color3")
        w.Theme.Accent = config.Accent
    end
    w.Gui = UI.new("ScreenGui", parent, {
        Name = "UiLib_" .. id,
        ResetOnSpawn = false,
        ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = config.DisplayOrder or 70,
    })
    w.Gui:SetAttribute("UiLibId", id)
    local dispose = UI.new("BindableFunction", w.Gui, { Name = "UiLibDispose" })
    dispose.OnInvoke = function()
        w:Destroy()
    end
    UI.connect(w, w.Gui.Destroying, function()
        w:Destroy()
    end)
    w.Root = UI.frame(w, w.Gui, { Size = UDim2.fromScale(1, 1) })
    w.Frame = UI.frame(
        w,
        w.Root,
        { Size = w.DesiredSize, Position = UDim2.fromOffset(100, 60), Active = true },
        "Base",
        "Window"
    )
    UI.stroke(w, w.Frame, "Border", 0.65)
    w.Shadow = UI.frame(
        w,
        w.Root,
        { ZIndex = 0, BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.86 },
        nil,
        "Window"
    )
    w.UIScale = UI.new("UIScale", w.Frame, { Scale = w.Scale })
    w.Header = UI.frame(w, w.Frame, { Size = UDim2.new(1, -20, 0, 48), Position = UDim2.fromOffset(10, 0) })
    UI.icon(w, w.Header, "logo", { Position = UDim2.fromOffset(9, 15), Size = UDim2.fromOffset(16, 16) }, "Accent")
    local searchSurface = UI.frame(
        w,
        w.Header,
        { Position = UDim2.fromOffset(52, 11), Size = UDim2.new(0.56, 0, 0, 28) },
        "Panel",
        "Control"
    )
    UI.icon(w, searchSurface, "search", { Position = UDim2.fromOffset(9, 6), Size = UDim2.fromOffset(16, 16) })
    w.Search = UI.new("TextBox", searchSurface, {
        Position = UDim2.fromOffset(32, 0),
        Size = UDim2.new(1, -40, 1, 0),
        PlaceholderText = UI.locale(w, "Search"),
        PlaceholderColor3 = w.Theme.Muted,
        ClearTextOnFocus = false,
    })
    UI.bind(w, w.Search, "TextColor3", "Text")
    UI.connect(w, w.Search:GetPropertyChangedSignal("Text"), function()
        w:SearchControls(w.Search.Text)
    end)
    local utility = UI.button(
        w,
        w.Header,
        "",
        { Position = UDim2.new(1, -30, 0, 8), Size = UDim2.fromOffset(30, 32) },
        function()
            w:OpenProfile()
        end
    )
    UI.icon(w, utility, "grid", { Position = UDim2.fromOffset(7, 8), Size = UDim2.fromOffset(16, 16) })
    w.Nav = UI.new("ScrollingFrame", w.Frame, {
        Position = UDim2.fromOffset(4, 54),
        Size = UDim2.new(0, 44, 1, -108),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    })
    UI.bind(w, w.Nav, "BackgroundColor3", "Panel")
    w.Nav.BackgroundTransparency = 0
    UI.round(w, w.Nav, "Panel")
    UI.list(w.Nav, 6)
    UI.pad(w.Nav, 3)
    w.ProfileButton = UI.button(
        w,
        w.Frame,
        "",
        { Position = UDim2.new(0, 7, 1, -47), Size = UDim2.fromOffset(36, 36) },
        function()
            w:OpenProfile()
        end
    )
    UI.icon(
        w,
        w.ProfileButton,
        "profile",
        { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(16, 16) },
        "Text"
    )
    w.Body = UI.frame(
        w,
        w.Frame,
        { Position = UDim2.fromOffset(60, 49), Size = UDim2.new(1, -76, 1, -61), ClipsDescendants = true }
    )
    w.Empty = UI.text(
        w,
        w.Body,
        UI.locale(w, "NoResults"),
        { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Visible = false },
        "Muted"
    )
    w.Overlay = UI.frame(w, w.Root, { Size = UDim2.fromScale(1, 1), ZIndex = 20 })
    w.ToastHolder = UI.frame(w, w.Root, {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -12, 1, -12),
        Size = UDim2.fromOffset(300, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 180,
    })
    local toastLayout = UI.list(w.ToastHolder, 6)
    toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    w.Restore = UI.button(
        w,
        w.Root,
        "",
        { Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(44, 44), Visible = false, ZIndex = 200 },
        function()
            w:Show()
        end
    )
    w.Restore.BackgroundTransparency = 0
    UI.icon(w, w.Restore, "logo", { Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(16, 16) }, "Accent")
    UI.drag(w, w.Header, function(p)
        if not w.Draggable or UI.inside(searchSurface, p) or UI.inside(utility, p) then
            return false
        end
        return { Start = p, Position = w.Frame.Position }
    end, function(p, s)
        w:SetPosition(UDim2.fromOffset(s.Position.X.Offset + p.X - s.Start.X, s.Position.Y.Offset + p.Y - s.Start.Y))
    end)
    w.Resize = UI.button(w, w.Frame, "", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1, 1),
        Size = UDim2.fromOffset(28, 28),
        Visible = w.Resizable,
    }, nil)
    UI.icon(w, w.Resize, "resize", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(16, 16) }, "Faint")
    UI.drag(w, w.Resize, function(p)
        if not w.Resizable then
            return false
        end
        return { Start = p, Size = w.Frame.AbsoluteSize / w.Scale }
    end, function(p, s)
        local size = s.Size + (p - s.Start) / w.Scale
        w:SetSize(UDim2.fromOffset(size.X, size.Y))
    end)
    UI.route(w, "InputChanged", function(i)
        local drag = w.Router.Drag
        if
            drag
            and (
                i == drag.Input
                or (
                    drag.Input.UserInputType == Enum.UserInputType.MouseButton1
                    and i.UserInputType == Enum.UserInputType.MouseMovement
                )
            )
        then
            if drag.Owner.Dead then
                UI.releaseDrag(w)
            else
                drag.Move(UI.point(i), drag.State)
            end
        end
    end)
    UI.route(w, "InputEnded", function(i)
        local d = w.Router.Drag
        if d and i == d.Input then
            UI.releaseDrag(w)
            if d.End then
                d.End(d.State)
            end
        end
        for control in w.Controls do
            if
                control.Kind == "Keybind"
                and control.Holding
                and (i.KeyCode == control.Value or i.UserInputType == control.Value)
            then
                control.Holding = false
                UI.call(control.Name, control.Callback, false)
            end
        end
    end)
    UI.route(w, "WindowFocusReleased", function()
        UI.releaseDrag(w)
        w:ReleaseKeys()
    end)
    UI.route(w, "InputBegan", function(i, processed)
        if w.Dead then
            return
        end
        local capture = w.Router.Capture
        if capture and not UI.S.Input:GetFocusedTextBox() then
            if i.KeyCode == Enum.KeyCode.Escape then
                capture.Render()
                w.Router.Capture = nil
                return
            end
            local key = if i.KeyCode ~= Enum.KeyCode.Unknown then i.KeyCode else i.UserInputType
            if key ~= Enum.UserInputType.MouseMovement and key ~= Enum.UserInputType.Touch then
                capture:Set(key)
                w.Router.Capture = nil
            end
            return
        end
        if not UI.S.Input:GetFocusedTextBox() and not processed then
            if i.KeyCode == w.HideKey or i.UserInputType == w.HideKey then
                w:Toggle()
                return
            end
            if i.KeyCode == Enum.KeyCode.Escape then
                if w.Modal then
                    w.Modal:Destroy()
                else
                    w:ClosePopups(math.max(1, #w.Popups))
                end
                return
            end
            if w.Visible and not w.Modal then
                for c in w.Controls do
                    if
                        c.Kind == "Keybind"
                        and not c.Disabled
                        and c.Visible
                        and (i.KeyCode == c.Value or i.UserInputType == c.Value)
                    then
                        if c.Mode == "Toggle" then
                            c.Active = not c.Active
                            UI.call(c.Name, c.Callback, c.Active)
                        elseif c.Mode == "Hold" then
                            if not c.Holding then
                                c.Holding = true
                                UI.call(c.Name, c.Callback, true)
                            end
                        else
                            UI.call(c.Name, c.Callback, true)
                        end
                    end
                end
            end
        end
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            local p = UI.point(i)
            local insideDepth = 0
            for depth, pop in w.Popups do
                if UI.inside(pop.Frame, p) or UI.inside(pop.Anchor, p) then
                    insideDepth = depth
                end
            end
            if insideDepth < #w.Popups then
                w:ClosePopups(insideDepth + 1)
            end
        end
    end)
    UI.connect(w, w.Root:GetPropertyChangedSignal("AbsoluteSize"), function()
        w:Reflow()
    end)
    UI.connect(w, w.Frame:GetPropertyChangedSignal("AbsoluteSize"), function()
        for _, tab in w.Tabs do
            tab:Layout()
        end
    end)
    for _, property in { "OnScreenKeyboardVisible", "OnScreenKeyboardPosition", "OnScreenKeyboardSize" } do
        UI.route(w, "Keyboard/" .. property, function()
            w:AdaptKeyboard()
        end, UI.S.Input:GetPropertyChangedSignal(property))
    end
    UI.connect(w, w.Gui:GetPropertyChangedSignal("AbsoluteSize"), function()
        w:AdaptKeyboard()
    end)
    self.Windows[id] = w
    w:Reflow()
    local bounds = w.Root.AbsoluteSize
    w:SetPosition(
        config.Position
            or UDim2.fromOffset(
                math.max(8, (bounds.X - w.Frame.AbsoluteSize.X) / 2),
                math.max(8, (bounds.Y - w.Frame.AbsoluteSize.Y) / 2)
            )
    )
    return w
end
function UI.Window:AdaptKeyboard()
    if self.Dead then
        return
    end
    if self.Touch and UI.S.Input.OnScreenKeyboardVisible then
        local top = UI.S.Input.OnScreenKeyboardPosition.Y - self.Root.AbsolutePosition.Y
        self.Root.Size = UDim2.new(1, 0, 0, math.max(100, math.min(self.Gui.AbsoluteSize.Y, top - 8)))
    else
        self.Root.Size = UDim2.fromScale(1, 1)
    end
    self:Reflow()
    UI.later(self, 0, function()
        local box = UI.S.Input:GetFocusedTextBox()
        if not box or not box:IsDescendantOf(self.Root) then
            return
        end
        local scroll = box.Parent
        while scroll and not scroll:IsA("ScrollingFrame") do
            scroll = scroll.Parent
        end
        if not scroll then
            return
        end
        local top = scroll.AbsolutePosition.Y
        local bottom = top + scroll.AbsoluteSize.Y - 8
        local delta = math.max(0, box.AbsolutePosition.Y + box.AbsoluteSize.Y - bottom)
        if box.AbsolutePosition.Y < top then
            delta = box.AbsolutePosition.Y - top
        end
        scroll.CanvasPosition = Vector2.new(scroll.CanvasPosition.X, math.max(0, scroll.CanvasPosition.Y + delta))
    end)
end
function UI.Window:ReleaseKeys()
    for c in self.Controls do
        if c.Holding then
            c.Holding = false
            UI.call(c.Name, c.Callback, false)
        end
    end
end
function UI.Window:Reflow()
    if self.Dead then
        return
    end
    local b = self.Root.AbsoluteSize
    if b.X < 1 or b.Y < 1 then
        return
    end
    if self.ScaleMode == "Fit" then
        local desired = self.DesiredSize
        self.Scale = math.clamp(
            math.min(
                1,
                (b.X - 40) / math.max(1, desired.X.Offset + b.X * desired.X.Scale),
                (b.Y - 16) / math.max(1, desired.Y.Offset + b.Y * desired.Y.Scale)
            ),
            0.75,
            1.5
        )
    end
    self.Compact = b.X < 650
    self.Nav.Position = UDim2.fromOffset(self.Compact and 4 or -20, 82)
    self.Nav.Size = UDim2.new(0, 44, 1, -130)
    self.ProfileButton.Position = UDim2.new(0, self.Compact and 7 or -16, 1, -47)
    self.Touch = UI.S.Input.TouchEnabled
    local size = self.DesiredSize
    local width = math.clamp(size.X.Offset + b.X * size.X.Scale, self.MinSize.X, self.MaxSize.X)
    local height = math.clamp(size.Y.Offset + b.Y * size.Y.Scale, self.MinSize.Y, self.MaxSize.Y)
    width = math.min(width, (b.X - (self.Compact and 16 or 40)) / self.Scale)
    height = math.min(height, (b.Y - 16) / self.Scale)
    if self.Compact then
        width = (b.X - 16) / self.Scale
        height = (b.Y - 16) / self.Scale
    end
    self.Frame.Size = UDim2.fromOffset(math.max(100, width), math.max(100, height))
    self.UIScale.Scale = self.Scale
    self:SetPosition(self.Frame.Position)
    for _, t in self.Tabs do
        t:Layout()
    end
    for _, p in self.Popups do
        p:Place()
    end
    self.ToastHolder.Size = UDim2.fromOffset(math.min(300, b.X - 24), 0)
    for _, c in self.Companions do
        c:Reflow()
    end
end
function UI.Window:SetPosition(p)
    if self.Dead then
        return
    end
    assert(typeof(p) == "UDim2", "[UiLib] Position must be UDim2")
    local b = self.Root.AbsoluteSize
    local size = self.Frame.AbsoluteSize
    local x = p.X.Offset + p.X.Scale * b.X
    local y = p.Y.Offset + p.Y.Scale * b.Y
    self.Frame.Position = UDim2.fromOffset(
        math.clamp(x, self.Compact and 8 or 28, math.max(self.Compact and 8 or 28, b.X - size.X - 8)),
        math.clamp(y, 8, math.max(8, b.Y - size.Y - 8))
    )
    if self.Shadow then
        self.Shadow.Position = UDim2.fromOffset(self.Frame.Position.X.Offset - 4, self.Frame.Position.Y.Offset + 3)
        self.Shadow.Size = UDim2.fromOffset(size.X + 8, size.Y + 5)
    end
    for _, c in self.Companions do
        if c.Linked then
            c:Reflow()
        end
    end
end
function UI.Window:SetSize(size)
    assert(typeof(size) == "UDim2", "[UiLib] Size must be UDim2")
    self.DesiredSize = size
    self:Reflow()
end
function UI.Window:SetScale(scale)
    if not UI.finite(scale) then
        UI.warn("Window", "Scale must be finite")
        return
    end
    self.ScaleMode = "Manual"
    self.Scale = math.clamp(scale, 0.75, 1.5)
    self:Reflow()
end
function UI.Window:GetScale()
    return self.Scale
end
function UI.Window:SetTitle(title)
    self.Title = tostring(title)
    self.Gui.Name = "UiLib_" .. self.Id .. "_" .. self.Title
end
function UI.Window:SetDraggable(v)
    self.Draggable = v == true
end
function UI.Window:SetResizable(v)
    self.Resizable = v == true
    self.Resize.Visible = self.Resizable
end
function UI.Window:SetVisible(v)
    if self.Dead then
        return
    end
    self.Visible = v == true
    self.Frame.Visible = self.Visible
    self.Shadow.Visible = self.Visible
    self.Restore.Visible = not self.Visible
    if not self.Visible then
        self:ClosePopups()
        UI.releaseDrag(self)
        self.Router.Capture = nil
        self:ReleaseKeys()
        if self.Modal then
            self.Modal:Destroy()
        end
        self:Tooltip(self.Frame, nil)
    end
    for _, c in self.Companions do
        c:Reflow()
    end
end
function UI.Window:Hide()
    self:SetVisible(false)
end
function UI.Window:Show()
    self:SetVisible(true)
end
function UI.Window:Toggle()
    self:SetVisible(not self.Visible)
end
function UI.Window:SetAccent(color, instant)
    if typeof(color) ~= "Color3" then
        UI.warn("Theme", "Accent must be Color3")
        return
    end
    self.Theme.Accent = color
    self:RefreshTheme(instant)
end
function UI.Window:GetAccent()
    return self.Theme.Accent
end
function UI.Window:RefreshTheme(instant)
    for obj, props in self.Bindings do
        if obj.Parent then
            local values = {}
            for property, token in props do
                values[property] = self.Theme[token]
            end
            if instant then
                for k, v in values do
                    obj[k] = v
                end
            else
                UI.tween(self, obj, values, "Color")
            end
        end
    end
    for c in self.Controls do
        if c.Render and not c.Dead then
            c.Render(true)
        end
    end
    for _, t in self.Tabs do
        t:Render()
    end
end
function UI.Window:SetTheme(theme)
    local data = type(theme) == "string" and Library.Themes[theme] or theme
    if type(data) ~= "table" then
        UI.warn("Theme", "Unknown theme")
        return
    end
    for k, v in data do
        if not UI.Palette[k] or typeof(v) ~= "Color3" then
            UI.warn("Theme", "Invalid token " .. tostring(k))
            return
        end
    end
    for k, v in data do
        self.Theme[k] = v
    end
    self:RefreshTheme()
end
function UI.Window:SetCornerStyle(n)
    if not UI.finite(n) then
        UI.warn("Corners", "Expected number")
        return
    end
    self.CornerStyle = math.clamp(n, 0, 2)
    for corner, kind in self.Corners do
        if corner.Parent then
            corner.CornerRadius = UDim.new(0, UI.Radii[kind] * self.CornerStyle)
        end
    end
end
function UI.Window:SetAnimationSpeed(n)
    if UI.finite(n) then
        self.AnimationSpeed = math.clamp(n, 0, 4)
    else
        UI.warn("Animation", "Expected finite speed")
    end
end
function UI.Window:GetAnimationSpeed()
    return self.AnimationSpeed
end
function UI.Window:SetLocale(locale)
    if not Library.Locales[locale] then
        UI.warn("Locale", "Unregistered " .. tostring(locale))
        return
    end
    self.Language = locale
    self.Search.PlaceholderText = UI.locale(self, "Search")
    self.Empty.Text = UI.locale(self, "NoResults")
    self:ClosePopups()
end
UI.Window.SetLanguage = UI.Window.SetLocale
function UI.Window:Destroy()
    if self.Dead then
        return
    end
    self.Dead = true
    self:ReleaseKeys()
    self:ClosePopups()
    UI.releaseDrag(self)
    self.Router = {}
    if self.Modal then
        self.Modal:Destroy()
    end
    for _, tab in table.clone(self.Tabs) do
        tab:Destroy()
    end
    for _, c in table.clone(self.Companions) do
        c:Destroy()
    end
    for _, t in self.Tweens do
        t:Cancel()
    end
    table.clear(self.Tweens)
    UI.clean(self.Bag)
    self.Gui:Destroy()
    table.clear(self.Bindings)
    table.clear(self.Corners)
    if Library.Windows[self.Id] == self then
        Library.Windows[self.Id] = nil
    end
end
function UI.Window:AddTab(options)
    options = options or {}
    local tab = setmetatable({
        Window = self,
        Bag = UI.bag(),
        Name = options.Name or "Page",
        Sections = {},
        Visible = true,
        Order = #self.Tabs + 1,
    }, UI.Tab)
    tab.Button = UI.button(tab, self.Nav, "", { Size = UDim2.fromOffset(36, 36), LayoutOrder = tab.Order }, function()
        tab:Select()
    end)
    tab.Icon = UI.icon(
        self,
        tab.Button,
        options.Icon or "grid",
        { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(16, 16) }
    )
    tab.Stroke = UI.stroke(self, tab.Button, "Accent", 1)
    UI.tooltip(tab, tab.Button, function()
        return tab.Name
    end)
    tab.Page = UI.new("ScrollingFrame", self.Body, {
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = self.Theme.Faint,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    })
    UI.bind(self, tab.Page, "ScrollBarImageColor3", "Faint")
    tab.Full = UI.frame(self, tab.Page, { Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
    tab.Left = UI.frame(self, tab.Page, { Size = UDim2.new(0.5, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
    tab.Right = UI.frame(self, tab.Page, { Size = UDim2.new(0.5, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
    UI.list(tab.Full, 14)
    UI.list(tab.Left, 14)
    UI.list(tab.Right, 14)
    UI.connect(tab, tab.Full:GetPropertyChangedSignal("AbsoluteSize"), function()
        tab:Layout()
    end)
    UI.connect(tab, tab.Left:GetPropertyChangedSignal("AbsoluteSize"), function()
        tab:Layout()
    end)
    table.insert(self.Tabs, tab)
    if not self.Selected then
        tab:Select()
    end
    return tab
end
UI.Window.AddPage = UI.Window.AddTab
function UI.Tab:Render()
    local selected = self.Window.Selected == self
    self.Button.BackgroundTransparency = selected and 0.8 or 1
    self.Button.BackgroundColor3 = selected and self.Window.Theme.Accent or self.Window.Theme.Hover
    self.Stroke.Transparency = selected and 0.65 or 1
    for _, obj in self.Icon:GetDescendants() do
        if obj:IsA("Frame") then
            obj.BackgroundColor3 = selected and self.Window.Theme.Accent or self.Window.Theme.Faint
        end
    end
end
function UI.Tab:Select()
    if self.Dead or not self.Visible then
        return
    end
    local w = self.Window
    w:ClosePopups()
    UI.releaseDrag(w)
    w.Selected = self
    for _, t in w.Tabs do
        t.Page.Visible = t == self
        t:Render()
    end
    self:Layout()
    self.Page.Position = UDim2.fromOffset(5, 0)
    UI.tween(w, self.Page, { Position = UDim2.fromOffset(0, 0) }, "Nav")
    w:SearchControls(w.Search.Text)
end
function UI.Tab:Layout()
    if self.Dead then
        return
    end
    local scale = self.Window.Scale
    local y = self.Full.AbsoluteSize.Y / scale
    if y > 0 then
        y += 12
    end
    local narrow = self.Window.Frame.AbsoluteSize.X / scale < 610
    self.Left.Position = UDim2.fromOffset(0, y)
    self.Left.Size = UDim2.new(narrow and 1 or 0.5, narrow and -6 or -10, 0, 0)
    self.Right.Size = self.Left.Size
    self.Right.Position = narrow and UDim2.fromOffset(0, y + self.Left.AbsoluteSize.Y / scale + 14)
        or UDim2.new(0.5, 4, 0, y)
end
function UI.Tab:SetVisible(v)
    self.Visible = v == true
    self.Button.Visible = self.Visible
    if not self.Visible and self.Window.Selected == self then
        self.Page.Visible = false
        self.Window.Selected = nil
        for _, t in self.Window.Tabs do
            if t.Visible and t ~= self then
                t:Select()
                break
            end
        end
    end
end
function UI.Tab:Destroy()
    if self.Dead then
        return
    end
    self.Dead = true
    for _, s in table.clone(self.Sections) do
        s:Destroy()
    end
    UI.clean(self.Bag)
    self.Button:Destroy()
    self.Page:Destroy()
    local index = table.find(self.Window.Tabs, self)
    if index then
        table.remove(self.Window.Tabs, index)
    end
    if self.Window.Selected == self then
        self.Window.Selected = nil
        for _, t in self.Window.Tabs do
            if t.Visible then
                t:Select()
                break
            end
        end
    end
end
function UI.Tab:AddSection(options)
    options = options or {}
    local side = options.Span == "Full" and "Full" or options.Side
    if side == nil or side == "Auto" then
        side = (#self.Sections % 2 == 0) and "Left" or "Right"
    end
    if side ~= "Full" and side ~= "Left" and side ~= "Right" then
        UI.warn("Section", "Invalid Side")
        side = "Left"
    end
    local s = setmetatable({
        Window = self.Window,
        Tab = self,
        Bag = UI.bag(),
        Name = options.Name or "",
        Controls = {},
        Visible = true,
        Side = side,
    }, UI.Section)
    s.Frame = UI.frame(
        self.Window,
        self[side],
        { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = #self.Sections + 1 }
    )
    UI.list(s.Frame, 3)
    s.Title =
        UI.text(self.Window, s.Frame, s.Name, { Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 0, TextSize = 12 }, "Text")
    table.insert(self.Sections, s)
    return s
end
function UI.Tab:AddLeftSection(o)
    o = table.clone(o or {})
    o.Side = "Left"
    return self:AddSection(o)
end
function UI.Tab:AddRightSection(o)
    o = table.clone(o or {})
    o.Side = "Right"
    return self:AddSection(o)
end
function UI.Section:SetVisible(v)
    self.Visible = v == true
    self.Window:SearchControls(self.Window.Search.Text)
end
function UI.Section:Destroy()
    if self.Dead then
        return
    end
    self.Dead = true
    for _, c in table.clone(self.Controls) do
        c:Destroy()
    end
    UI.clean(self.Bag)
    self.Frame:Destroy()
    if self.Tab then
        local i = table.find(self.Tab.Sections, self)
        if i then
            table.remove(self.Tab.Sections, i)
        end
    end
end
function UI.Window:SearchControls(query)
    query = string.lower(query or "")
    if query ~= "" and not self.Searching then
        self.BeforeSearch = self.Selected
    end
    if
        query == ""
        and self.Searching
        and self.BeforeSearch
        and not self.BeforeSearch.Dead
        and self.BeforeSearch.Visible
    then
        self.Selected = self.BeforeSearch
    end
    self.Searching = query ~= ""
    local total = 0
    for _, tab in self.Tabs do
        local tabCount = 0
        for _, s in tab.Sections do
            local count = 0
            for _, c in s.Controls do
                local hay = string.lower(
                    tab.Name .. " " .. s.Name .. " " .. c.Name .. " " .. c.Description .. " " .. (c.Aliases or "")
                )
                c.Frame.Visible = c.Visible and s.Visible and (query == "" or string.find(hay, query, 1, true) ~= nil)
                if c.Frame.Visible then
                    count += 1
                end
            end
            s.Frame.Visible = s.Visible and (query == "" or count > 0)
            tabCount += count
        end
        tab.Button.Visible = tab.Visible and (query == "" or tabCount > 0)
        if tab == self.Selected then
            total = tabCount
        end
    end
    if total == 0 and query ~= "" then
        for _, tab in self.Tabs do
            if tab.Button.Visible and tab ~= self.Selected then
                self.Selected = tab
                total = 1
                break
            end
        end
    end
    for _, tab in self.Tabs do
        tab.Page.Visible = tab == self.Selected and tab.Visible
        tab:Render()
    end
    self.Empty.Visible = query ~= "" and total == 0
end
-- Component ownership: one Set path validates, copies, updates flags, renders, then calls listeners.
UI.ValueKinds = {
    Toggle = true,
    Checkbox = true,
    Slider = true,
    RangeSlider = true,
    Dropdown = true,
    MultiDropdown = true,
    Input = true,
    Keybind = true,
    ColorPicker = true,
    SegmentedControl = true,
    RadioGroup = true,
    ProgressBar = true,
    Status = true,
    CurveEditor = true,
}

function UI.control(section, options, kind, height)
    assert(not section.Dead, "[UiLib] Cannot add controls to a destroyed section")
    options = options or {}
    local w = section.Window
    local c = setmetatable({
        Window = w,
        Section = section,
        Popup = section.Popup,
        Bag = UI.bag(),
        Kind = kind,
        Name = options.Name or kind,
        Description = options.Description or "",
        Tooltip = options.Tooltip or "",
        Aliases = type(options.Aliases) == "table" and table.concat(options.Aliases, " ") or options.Aliases,
        Visible = options.Visible ~= false,
        Disabled = options.Disabled == true,
        Callback = options.Callback,
        Listeners = {},
        Default = UI.copy(options.Default),
        Value = UI.copy(options.Default),
    }, UI.Control)
    if options.Flag and not UI.ValueKinds[kind] then
        UI.warn(c.Name, "Flags are supported only on value controls")
    elseif options.Flag and (type(options.Flag) ~= "string" or options.Flag == "__ui") then
        UI.warn(c.Name, "Flag must be a string other than reserved __ui")
    elseif options.Flag then
        if w.Flags[options.Flag] then
            UI.warn(c.Name, "Duplicate flag " .. options.Flag .. "; control not registered")
        else
            c.Flag = options.Flag
            w.Flags[c.Flag] = c
        end
    end
    c.Frame = UI.frame(w, section.Frame, {
        Size = UDim2.new(1, 0, 0, height or section.RowHeight or (w.Touch and 44 or 36)),
        LayoutOrder = #section.Controls + 1,
        Visible = c.Visible,
    }, "Panel", "Control")
    c.Label = UI.text(w, c.Frame, c.Name, {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(0.57, -10, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, "Muted")
    c.Field = UI.frame(w, c.Frame, { Position = UDim2.new(0.57, 0, 0, 0), Size = UDim2.new(0.43, -10, 1, 0) })
    table.insert(section.Controls, c)
    w.Controls[c] = true
    UI.tooltip(c, c.Frame, function()
        return c.Tooltip ~= "" and c.Tooltip or c.Description
    end)
    if options.Callback and type(options.Callback) ~= "function" then
        UI.warn(c.Name, "Invalid callback")
        c.Callback = nil
    end
    return c
end
function UI.Control:Get()
    return UI.copy(self.Value)
end
function UI.Control:Set(value, silent)
    if self.Dead then
        UI.warn(self.Name, "Set on destroyed control")
        return false
    end
    if self.Validate then
        local ok, result, message = self.Validate(value)
        if not ok then
            UI.warn(self.Name, message or "Invalid value")
            return false
        end
        value = result
    end
    if UI.equal(self.Value, value) then
        return true
    end
    self.Value = UI.copy(value)
    if self.Render then
        self.Render()
    end
    if not silent then
        local args = if self.Kind == "ColorPicker"
            then { self.Value.Color, self.Value.Alpha }
            else { UI.copy(self.Value) }
        UI.call(self.Name, self.Kind == "Keybind" and self.ChangedCallback or self.Callback, unpack(args))
        for callback in self.Listeners do
            UI.call(self.Name, callback, unpack(args))
        end
    end
    return true
end
function UI.Control:Reset(silent)
    return self:Set(UI.copy(self.Default), silent)
end
function UI.Control:CancelInteraction()
    self:Close()
    if self.Window.Router.Capture == self then
        self.Window.Router.Capture = nil
        if self.Render then
            self.Render()
        end
    end
    if self.Holding then
        self.Holding = false
        UI.call(self.Name, self.Callback, false)
    end
    if self.Window.Router.Drag and self.Window.Router.Drag.Owner == self then
        UI.releaseDrag(self.Window)
    end
end
function UI.Control:SetVisible(v)
    if self.Dead then
        return
    end
    self.Visible = v == true
    self.Frame.Visible = self.Visible
    if self.Section.Tab then
        self.Window:SearchControls(self.Window.Search.Text)
    end
    if not self.Visible then
        self:CancelInteraction()
        if self.Window.Router.Drag and self.Window.Router.Drag.Owner == self then
            UI.releaseDrag(self.Window)
        end
    end
end
function UI.Control:SetDisabled(v)
    if self.Dead then
        return
    end
    self.Disabled = v == true
    self.Label.TextTransparency = self.Disabled and 0.55 or 0
    if self.Render then
        self.Render(true)
    end
    if self.Disabled then
        self:CancelInteraction()
        if self.Window.Router.Drag and self.Window.Router.Drag.Owner == self then
            UI.releaseDrag(self.Window)
        end
    end
end
function UI.Control:SetName(s)
    self.Name = tostring(s)
    self.Label.Text = self.Name
end
function UI.Control:SetDescription(s)
    self.Description = tostring(s)
end
function UI.Control:SetTooltip(s)
    self.TooltipFrame = tostring(s)
end
function UI.Control:OnChanged(callback)
    assert(type(callback) == "function", "[UiLib] OnChanged expects function")
    self.Listeners[callback] = true
    local c = self
    return {
        Disconnect = function()
            c.Listeners[callback] = nil
        end,
    }
end
UI.Control.OnClicked = UI.Control.OnChanged
function UI.Control:Close()
    if self.OpenPopup and not self.OpenPopup.Dead then
        self.OpenPopup:Destroy()
    end
    self.OpenPopup = nil
end
function UI.Control:Destroy()
    if self.Dead then
        return
    end
    self:Close()
    self.Dead = true
    if self.Window.Router.Drag and self.Window.Router.Drag.Owner == self then
        UI.releaseDrag(self.Window)
    end
    if self.Window.Router.Capture == self then
        self.Window.Router.Capture = nil
    end
    if self.Holding then
        UI.call(self.Name, self.Callback, false)
    end
    if self.Flag and self.Window.Flags[self.Flag] == self then
        self.Window.Flags[self.Flag] = nil
    end
    self.Window.Controls[self] = nil
    UI.clean(self.Bag)
    table.clear(self.Listeners)
    self.Frame:Destroy()
    local i = table.find(self.Section.Controls, self)
    if i then
        table.remove(self.Section.Controls, i)
    end
end
function UI.finish(c, default)
    c.Value = nil
    if not c:Set(default, true) then
        local name = c.Name
        c:Destroy()
        error("[UiLib/" .. name .. "] Invalid default", 2)
    end
    c.Default = UI.copy(c.Value)
    c:SetDisabled(c.Disabled)
    return c
end
function UI.Section:AddToggle(options)
    options = options or {}
    local c = UI.control(self, options, "Toggle")
    local w = c.Window
    local hit = UI.button(c, c.Field, "", { Size = UDim2.fromScale(1, 1) }, function()
        c:Set(not c.Value)
    end)
    local track = UI.frame(
        w,
        hit,
        { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(25, 14) },
        "Row",
        "Small"
    )
    local thumb = UI.frame(w, track, { Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(8, 8) }, "Faint")
    UI.new("UICorner", thumb, { CornerRadius = UDim.new(1, 0) })
    c.Validate = function(v)
        return type(v) == "boolean", v, "Expected boolean"
    end
    c.Render = function(instant)
        local color = c.Value and w.Theme.Accent or w.Theme.Faint
        local props = { Position = UDim2.fromOffset(c.Value and 14 or 3, 3), BackgroundColor3 = color }
        if instant then
            for k, v in props do
                thumb[k] = v
            end
        else
            UI.tween(w, thumb, props, "Toggle")
        end
        track.BackgroundColor3 = c.Value and w.Theme.Panel:Lerp(w.Theme.Accent, 0.13) or w.Theme.Row
        thumb.BackgroundTransparency = c.Disabled and 0.6 or 0
    end
    return UI.finish(c, options.Default == true)
end
function UI.Section:AddCheckbox(options)
    local c = self:AddToggle(options)
    c.Kind = "Checkbox"
    c.Field:ClearAllChildren()
    local b = UI.button(c, c.Field, "", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(36, c.Frame.Size.Y.Offset),
    }, function()
        c:Set(not c.Value)
    end)
    local box = UI.frame(
        c.Window,
        b,
        { Position = UDim2.new(0.5, -7, 0.5, -7), Size = UDim2.fromOffset(14, 14) },
        "Row",
        "Small"
    )
    UI.stroke(c.Window, box)
    local check = UI.icon(
        c.Window,
        box,
        "check",
        { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(-1, -1) },
        "Accent"
    )
    c.Render = function()
        check.Visible = c.Value
        box.BackgroundTransparency = c.Disabled and 0.7 or 0
    end
    c.Render()
    return c
end
function UI.slider(section, options, range)
    options = options or {}
    local min, max, step = options.Min or 0, options.Max or 100, options.Increment or 1
    assert(
        UI.finite(min) and UI.finite(max) and max > min and UI.finite(step) and step > 0,
        "[UiLib] Slider requires finite Min < Max and positive Increment"
    )
    local c = UI.control(section, options, range and "RangeSlider" or "Slider")
    local w = c.Window
    c.Min, c.Max, c.Increment = min, max, step
    local number = UI.text(w, c.Field, "", {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0.3, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextSize = 11,
    }, "Text")
    local hit = UI.button(c, c.Field, "", { Position = UDim2.new(0.36, 0, 0, 0), Size = UDim2.new(0.64, 0, 1, 0) }, nil)
    local track =
        UI.frame(w, hit, { Position = UDim2.new(0, 4, 0.5, -2), Size = UDim2.new(1, -8, 0, 4) }, "Row", "Small")
    local fill = UI.frame(w, track, { Size = UDim2.fromScale(0.5, 1) }, "Accent", "Small")
    local thumbs = {}
    for i = 1, range and 2 or 1 do
        local t = UI.frame(
            w,
            track,
            { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(7, 7), Position = UDim2.fromScale(0.5, 0.5) },
            "Thumb"
        )
        UI.new("UICorner", t, { CornerRadius = UDim.new(1, 0) })
        thumbs[i] = t
    end
    local function snap(v)
        return math.clamp(min + math.floor((math.clamp(v, min, max) - min) / step + 0.5) * step, min, max)
    end
    c.Validate = function(v)
        if range then
            if type(v) ~= "table" or #v ~= 2 or not UI.finite(v[1]) or not UI.finite(v[2]) then
                return false, nil, "Expected {lower, upper}"
            end
            local low, high = snap(v[1]), snap(v[2])
            if low > high then
                return false, nil, "Range thumbs may not cross"
            end
            return true, { low, high }
        end
        if not UI.finite(v) then
            return false, nil, "Expected finite number"
        end
        return true, snap(v)
    end
    local function format(v)
        return (options.Prefix or "") .. string.format("%.4g", v) .. (options.Suffix or "")
    end
    c.Render = function()
        if c.Value == nil then
            return
        end
        local a = range and (c.Value[1] - min) / (max - min) or 0
        local b = ((range and c.Value[2] or c.Value) - min) / (max - min)
        fill.Position = UDim2.fromScale(a, 0)
        fill.Size = UDim2.fromScale(b - a, 1)
        thumbs[1].Position = UDim2.fromScale(range and a or b, 0.5)
        if range then
            thumbs[2].Position = UDim2.fromScale(b, 0.5)
        end
        number.Text = range and (format(c.Value[1]) .. "–" .. format(c.Value[2])) or format(c.Value)
        fill.BackgroundTransparency = c.Disabled and 0.65 or 0
    end
    UI.drag(c, hit, function(p)
        local ratio = math.clamp((p.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        if range then
            local value = min + ratio * (max - min)
            return math.abs(value - c.Value[1]) < math.abs(value - c.Value[2]) and 1 or 2
        end
        return 1
    end, function(p, index)
        local v = snap(
            min + math.clamp((p.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1) * (max - min)
        )
        if range then
            local pair = c:Get()
            pair[index] = index == 1 and math.min(v, pair[2]) or math.max(v, pair[1])
            c:Set(pair)
        else
            c:Set(v)
        end
    end)
    UI.connect(c, hit.InputBegan, function(i)
        local delta = (i.KeyCode == Enum.KeyCode.Right or i.KeyCode == Enum.KeyCode.DPadRight) and step
            or ((i.KeyCode == Enum.KeyCode.Left or i.KeyCode == Enum.KeyCode.DPadLeft) and -step or 0)
        if delta ~= 0 and not c.Disabled and not range then
            c:Set(c.Value + delta)
        end
    end)
    return UI.finish(c, options.Default or (range and { min, max } or min))
end
function UI.Section:AddSlider(o)
    return UI.slider(self, o, false)
end
function UI.Section:AddRangeSlider(o)
    return UI.slider(self, o, true)
end
function UI.Section:AddButton(options)
    options = options or {}
    local c = UI.control(self, options, "Button")
    local w = c.Window
    c.Label.Visible = false
    c.Field.Visible = false
    c.Button = UI.button(
        c,
        c.Frame,
        c.Name,
        { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center },
        function()
            UI.call(c.Name, c.Callback)
            for callback in c.Listeners do
                UI.call(c.Name, callback)
            end
        end
    )
    local style = options.Style or "Secondary"
    if style == "Icon" then
        c.Button.Text = ""
        UI.icon(
            w,
            c.Button,
            options.Icon or "grid",
            { Position = UDim2.new(0.5, -8, 0.5, -8), Size = UDim2.fromOffset(16, 16) }
        )
    end
    c.Render = function()
        c.Frame.BackgroundColor3 = style == "Primary" and w.Theme.Panel:Lerp(w.Theme.Accent, 0.2) or w.Theme.Row
        c.Button.TextColor3 = style == "Destructive" and w.Theme.Danger or w.Theme.Text
        c.Frame.BackgroundTransparency = style == "Ghost" and 1 or 0
        c.Button.TextTransparency = c.Disabled and 0.6 or 0
    end
    function c:SetName(n)
        self.Name = tostring(n)
        self.Button.Text = self.Name
    end
    c.Render()
    return c
end
function UI.Section:AddIconButton(o)
    o = table.clone(o or {})
    o.Style = "Icon"
    return self:AddButton(o)
end
function UI.Section:AddInput(options)
    options = options or {}
    local c = UI.control(self, options, "Input")
    local w = c.Window
    local surface =
        UI.frame(w, c.Field, { Position = UDim2.new(0, 0, 0.5, -12), Size = UDim2.new(1, 0, 0, 24) }, "Row", "Small")
    local stroke = UI.stroke(w, surface, "Border", 0.7)
    c.TextBox = UI.new("TextBox", surface, {
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -28, 1, 0),
        PlaceholderText = options.Placeholder or "",
        PlaceholderColor3 = w.Theme.Muted,
        ClearTextOnFocus = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    UI.bind(w, c.TextBox, "TextColor3", "Text")
    UI.button(c, surface, "×", {
        Position = UDim2.new(1, -22, 0, 0),
        Size = UDim2.fromOffset(22, 24),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, function()
        c.TextBox.Text = ""
        c.TextBox:CaptureFocus()
    end)
    c.Validate = function(v)
        if options.Type == "Number" then
            if not UI.finite(v) then
                return false, nil, "Expected number"
            end
            v = math.clamp(v, options.Min or -math.huge, options.Max or math.huge)
        elseif type(v) ~= "string" then
            return false, nil, "Expected text"
        end
        if type(v) == "string" and #v > (options.MaxLength or 4096) then
            return false, nil, "Text exceeds MaxLength"
        end
        if options.Validate then
            local ok, valid, message = pcall(options.Validate, v)
            if not ok or valid == false then
                return false, nil, message or "Validation failed"
            end
        end
        return true, v
    end
    c.Render = function()
        c.TextBox.Text = tostring(c.Value or "")
        c.TextBox.TextEditable = not c.Disabled
    end
    UI.connect(c, c.TextBox.Focused, function()
        if c.Disabled then
            c.TextBox:ReleaseFocus()
            return
        end
        stroke.Color = w.Theme.Accent
        stroke.Transparency = 0.3
    end)
    UI.connect(c, c.TextBox.FocusLost, function()
        local value = options.Type == "Number" and tonumber(c.TextBox.Text) or c.TextBox.Text
        if c:Set(value) then
            stroke.Color = w.Theme.Border
            stroke.Transparency = 0.7
        else
            stroke.Color = w.Theme.Danger
            stroke.Transparency = 0.2
            c.TextBox.Text = tostring(c.Value or "")
        end
    end)
    return UI.finish(c, options.Default or (options.Type == "Number" and 0 or ""))
end
function UI.Section:AddNumberInput(o)
    o = table.clone(o or {})
    o.Type = "Number"
    return self:AddInput(o)
end
function UI.Section:AddKeybind(options)
    options = options or {}
    local c = UI.control(self, options, "Keybind")
    local w = c.Window
    c.Mode = options.Mode or "Toggle"
    c.ChangedCallback = options.Changed
    assert(
        c.Mode == "Toggle" or c.Mode == "Hold" or c.Mode == "Press",
        "[UiLib] Keybind mode must be Toggle, Hold, or Press"
    )
    local b = UI.button(
        c,
        c.Field,
        "",
        { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Right },
        function()
            UI.later(c, 0, function()
                if w.Router.Capture then
                    w.Router.Capture.Render()
                end
                w.Router.Capture = c
                b.Text = "[ ... ]"
            end)
        end
    )
    c.Validate = function(v)
        return typeof(v) == "EnumItem"
            and (
                v.EnumType == Enum.KeyCode
                or (
                    v.EnumType == Enum.UserInputType
                    and (
                        v == Enum.UserInputType.MouseButton1
                        or v == Enum.UserInputType.MouseButton2
                        or v == Enum.UserInputType.MouseButton3
                    )
                )
            ),
            v,
            "Expected keyboard, controller, or mouse-button EnumItem"
    end
    c.Render = function()
        b.Text = c.Value and ("[ " .. c.Value.Name .. " ]") or "[ None ]"
    end
    return UI.finish(c, options.Default or Enum.KeyCode.RightShift)
end
function UI.dropdown(section, options, multi)
    options = options or {}
    local c = UI.control(section, options, multi and "MultiDropdown" or "Dropdown")
    local w = c.Window
    c.Options = {}
    c.MaxSelections = options.MaxSelections or math.huge
    local b = UI.button(c, c.Field, "", {
        Position = UDim2.new(0, 0, 0.5, -12),
        Size = UDim2.new(1, 0, 0, 24),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, function()
        c:Open()
    end)
    b.BackgroundTransparency = 0
    UI.bind(w, b, "BackgroundColor3", "Row")
    local title = UI.text(w, b, "", {
        Position = UDim2.fromOffset(7, 0),
        Size = UDim2.new(1, -28, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = 11,
    })
    UI.icon(w, b, "chevron", { Position = UDim2.new(1, -20, 0.5, -8), Size = UDim2.fromOffset(16, 16) })
    c.Validate = function(v)
        if multi then
            if type(v) ~= "table" then
                return false, nil, "Expected selection array"
            end
            local output, seen = {}, {}
            for _, item in v do
                if not table.find(c.Options, item) then
                    return false, nil, "Invalid selection " .. tostring(item)
                end
                if not seen[item] then
                    seen[item] = true
                    table.insert(output, item)
                end
            end
            if #output > c.MaxSelections then
                return false, nil, "MaxSelections exceeded"
            end
            return true, output
        end
        if v == nil or table.find(c.Options, v) then
            return true, v
        end
        return false, nil, "Invalid selection " .. tostring(v)
    end
    c.Render = function()
        title.Text = multi and (c.Value and #c.Value > 0 and tostring(#c.Value) .. " selected" or "—")
            or tostring(c.Value or "—")
        if c.RefreshOptions then
            c.RefreshOptions()
        end
    end
    function c:SetOptions(values)
        if type(values) ~= "table" then
            UI.warn(self.Name, "Options must be an array")
            return
        end
        local output = {}
        for _, v in values do
            if (type(v) == "string" or UI.finite(v)) and not table.find(output, v) then
                table.insert(output, v)
            else
                UI.warn(self.Name, "Invalid or duplicate option")
            end
        end
        self.Options = output
        if multi then
            local selected = {}
            for _, v in self.Value or {} do
                if table.find(output, v) then
                    table.insert(selected, v)
                end
            end
            self:Set(selected)
        elseif self.Value ~= nil and not table.find(output, self.Value) then
            self:Set(nil)
        end
        self:Close()
    end
    function c:Open()
        if self.Dead or self.Disabled then
            return
        end
        if self.OpenPopup and not self.OpenPopup.Dead then
            self:Close()
            return
        end
        local searchable = options.Searchable ~= false
        local header = searchable and 36 or 4
        local footer = multi and 32 or 0
        local p = w:OpenPopover(
            b,
            Vector2.new(
                math.max(210, b.AbsoluteSize.X),
                math.min(292, #self.Options * (w.Touch and 40 or 28) + header + footer + 10)
            ),
            self.Popup
        )
        self.OpenPopup = p
        local rows = {}
        local search
        if searchable then
            search = UI.new("TextBox", p.Content, {
                Position = UDim2.fromOffset(10, 4),
                Size = UDim2.new(1, -20, 0, 28),
                PlaceholderText = UI.locale(w, "Search"),
                PlaceholderColor3 = w.Theme.Muted,
                ClearTextOnFocus = false,
            })
            UI.bind(w, search, "TextColor3", "Text")
        end
        local list = UI.new("ScrollingFrame", p.Content, {
            Position = UDim2.fromOffset(5, header),
            Size = UDim2.new(1, -10, 1, -header - footer - 4),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
        })
        UI.list(list, 2)
        for index, v in self.Options do
            local row = UI.button(
                p,
                list,
                "  " .. tostring(v),
                { Size = UDim2.new(1, -3, 0, w.Touch and 40 or 28), LayoutOrder = index },
                function()
                    if multi then
                        local selected = c:Get()
                        local i = table.find(selected, v)
                        if i then
                            table.remove(selected, i)
                        elseif #selected < c.MaxSelections then
                            table.insert(selected, v)
                        end
                        c:Set(selected)
                    else
                        c:Set(v)
                        c:Close()
                    end
                end
            )
            rows[v] = row
        end
        self.RefreshOptions = function()
            for v, row in rows do
                local selected = multi and c.Value and table.find(c.Value, v) ~= nil or (not multi and c.Value == v)
                row.TextColor3 = selected and w.Theme.Accent or w.Theme.Text
                row.Text = (selected and "  ✓  " or "      ") .. tostring(v)
                row.Visible = not search
                    or string.find(string.lower(tostring(v)), string.lower(search.Text), 1, true) ~= nil
            end
        end
        if search then
            UI.connect(p, search:GetPropertyChangedSignal("Text"), self.RefreshOptions)
        end
        if multi then
            UI.button(
                p,
                p.Content,
                UI.locale(w, "Clear"),
                { Position = UDim2.new(0, 10, 1, -30), Size = UDim2.new(0.5, -10, 0, 26) },
                function()
                    c:Set({})
                end
            )
            if options.SelectAll ~= false then
                UI.button(p, p.Content, UI.locale(w, "SelectAll"), {
                    Position = UDim2.new(0.5, 0, 1, -30),
                    Size = UDim2.new(0.5, -10, 0, 26),
                    TextXAlignment = Enum.TextXAlignment.Right,
                }, function()
                    local all = {}
                    for i = 1, math.min(#c.Options, c.MaxSelections) do
                        all[i] = c.Options[i]
                    end
                    c:Set(all)
                end)
            end
        end
        p.OnClose = function()
            c.RefreshOptions = nil
            c.OpenPopup = nil
        end
        self.RefreshOptions()
    end
    c:SetOptions(options.Options or {})
    return UI.finish(c, options.Default or (multi and {} or c.Options[1]))
end
function UI.Section:AddDropdown(o)
    return UI.dropdown(self, o, false)
end
function UI.Section:AddMultiDropdown(o)
    return UI.dropdown(self, o, true)
end
function UI.Section:AddSegmentedControl(options)
    options = options or {}
    local c = UI.control(self, options, "SegmentedControl", 64)
    local w = c.Window
    c.Label.Size = UDim2.new(1, -20, 0, 24)
    c.Field.Position = UDim2.fromOffset(8, 27)
    c.Field.Size = UDim2.new(1, -16, 0, 29)
    local values = options.Options or {}
    assert(#values > 0, "[UiLib] SegmentedControl requires options")
    local buttons = {}
    for i, v in values do
        buttons[i] = UI.button(c, c.Field, tostring(v), {
            Position = UDim2.new((i - 1) / #values, 2, 0, 0),
            Size = UDim2.new(1 / #values, -4, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
        }, function()
            c:Set(v)
        end)
    end
    c.Validate = function(v)
        return table.find(values, v) ~= nil, v, "Invalid option"
    end
    c.Render = function()
        for i, b in buttons do
            b.BackgroundTransparency = c.Value == values[i] and 0.82 or 1
            b.BackgroundColor3 = w.Theme.Accent
            b.TextColor3 = c.Value == values[i] and w.Theme.Text or w.Theme.Muted
        end
    end
    return UI.finish(c, options.Default or values[1])
end
function UI.Section:AddRadioGroup(options)
    options = options or {}
    local values = options.Options or {}
    assert(#values > 0, "[UiLib] RadioGroup requires options")
    local rowHeight = self.Window.Touch and 44 or 28
    local c = UI.control(self, options, "RadioGroup", 28 + #values * rowHeight)
    local w = c.Window
    c.Label.Size = UDim2.new(1, -20, 0, 24)
    c.Field.Visible = false
    local dots = {}
    for i, value in values do
        local button = UI.button(
            c,
            c.Frame,
            "      " .. tostring(value),
            { Position = UDim2.fromOffset(10, 24 + (i - 1) * rowHeight), Size = UDim2.new(1, -20, 0, rowHeight) },
            function()
                c:Set(value)
            end
        )
        local ring = UI.frame(w, button, { Position = UDim2.new(0, 2, 0.5, -6), Size = UDim2.fromOffset(12, 12) })
        UI.new("UICorner", ring, { CornerRadius = UDim.new(1, 0) })
        UI.stroke(w, ring, "Border", 0.2)
        local dot = UI.frame(w, ring, { Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(6, 6) }, "Accent")
        UI.new("UICorner", dot, { CornerRadius = UDim.new(1, 0) })
        dots[i] = dot
    end
    c.Validate = function(v)
        return table.find(values, v) ~= nil, v, "Invalid radio selection"
    end
    c.Render = function()
        for i, dot in dots do
            dot.Visible = c.Value == values[i]
            dot.BackgroundTransparency = c.Disabled and 0.6 or 0
        end
    end
    return UI.finish(c, options.Default or values[1])
end
function UI.Section:AddLabel(options)
    if type(options) == "string" then
        options = { Name = options }
    end
    local c = UI.control(self, options or {}, "Label", 24)
    c.Field.Visible = false
    c.Label.Size = UDim2.new(1, -20, 1, 0)
    c.Frame.BackgroundTransparency = 1
    return c
end
function UI.Section:AddParagraph(options)
    options = options or {}
    local c = UI.control(self, options, "Paragraph", 72)
    c.Field.Visible = false
    c.Label.Size = UDim2.new(1, -20, 0, 24)
    local body = UI.text(c.Window, c.Frame, options.Content or options.Description or "", {
        Position = UDim2.fromOffset(10, 26),
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, "Muted")
    UI.connect(c, body:GetPropertyChangedSignal("TextBounds"), function()
        c.Frame.Size = UDim2.new(1, 0, 0, math.max(52, body.TextBounds.Y + 36))
    end)
    function c:SetDescription(v)
        self.Description = tostring(v)
        body.Text = self.Description
    end
    return c
end
function UI.Section:AddDivider()
    local c = UI.control(self, { Name = "" }, "Divider", 10)
    c.Label.Visible = false
    c.Field.Visible = false
    c.Frame.BackgroundTransparency = 1
    UI.frame(c.Window, c.Frame, { Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 1) }, "Border")
    return c
end
function UI.Section:AddProgressBar(options)
    options = options or {}
    local c = UI.control(self, options, "ProgressBar", options.Compact and 12 or 38)
    local w = c.Window
    c.Label.Visible = not options.Compact
    c.Label.Size = UDim2.new(1, -20, 0, 22)
    c.Field.Visible = false
    local track =
        UI.frame(w, c.Frame, { Position = UDim2.new(0, 8, 1, -10), Size = UDim2.new(1, -16, 0, 5) }, "Row", "Small")
    local fill = UI.frame(w, track, { Size = UDim2.fromScale(0, 1) }, "Accent", "Small")
    c.Validate = function(v)
        return UI.finite(v), UI.finite(v) and math.clamp(v, 0, 1) or 0, "Expected progress 0..1"
    end
    c.Render = function(instant)
        if instant then
            fill.Size = UDim2.fromScale(c.Value or 0, 1)
        else
            UI.tween(w, fill, { Size = UDim2.fromScale(c.Value or 0, 1) }, "Slider")
        end
    end
    return UI.finish(c, options.Default or 0)
end
function UI.Section:AddStatus(options)
    options = options or {}
    local c = UI.control(self, options, "Status", 24)
    c.Field.Visible = false
    c.Frame.BackgroundTransparency = 1
    c.Label.Position = UDim2.fromOffset(24, 0)
    c.Label.Size = UDim2.new(1, -34, 1, 0)
    local dot =
        UI.frame(c.Window, c.Frame, { Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(5, 5) }, "Accent")
    UI.new("UICorner", dot, { CornerRadius = UDim.new(1, 0) })
    c.Validate = function(v)
        return type(v) == "string", v, "Expected status text"
    end
    c.Render = function()
        c.Label.Text = c.Value or ""
    end
    return UI.finish(c, options.Default or options.Name or "Ready")
end
function UI.Section:AddCustomControl(options)
    options = options or {}
    local c = UI.control(self, options, "Custom", options.Height or 60)
    c.Label.Visible = false
    c.Field.Visible = false
    UI.call(c.Name, options.Build, c.Frame, c)
    return c
end
function UI.Section:AddColorPicker(options)
    options = options or {}
    local c = UI.control(self, options, "ColorPicker")
    local w = c.Window
    local b = UI.button(c, c.Field, "", { Size = UDim2.fromScale(1, 1) }, function()
        c:Open()
    end)
    local swatch = UI.frame(
        w,
        b,
        { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(24, 12) },
        nil,
        "Small"
    )
    swatch.BackgroundTransparency = 0
    c.Validate = function(v)
        if typeof(v) == "Color3" then
            v = { Color = v, Alpha = c.Value and c.Value.Alpha or options.Alpha or 1 }
        end
        if type(v) ~= "table" or typeof(v.Color) ~= "Color3" or not UI.finite(v.Alpha) then
            return false, nil, "Expected Color3 or {Color=Color3, Alpha=number}"
        end
        return true, { Color = v.Color, Alpha = math.clamp(v.Alpha, 0, 1) }
    end
    c.Render = function()
        if not c.Value then
            return
        end
        swatch.BackgroundColor3 = c.Value.Color
        swatch.BackgroundTransparency = 1 - c.Value.Alpha
        if c.UpdatePicker then
            c.UpdatePicker()
        end
    end
    function c:GetColor()
        return self.Value.Color, self.Value.Alpha
    end
    function c:Open()
        if self.Dead or self.Disabled then
            return
        end
        if self.OpenPopup and not self.OpenPopup.Dead then
            self:Close()
            return
        end
        local p = w:OpenPopover(b, Vector2.new(232, 354), self.Popup)
        self.OpenPopup = p
        p.Content:Destroy()
        p.Content = UI.new("ScrollingFrame", p.Frame, {
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.fromOffset(0, 354),
            ScrollBarThickness = 2,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        })
        local owner = { Window = w, Popup = p, Bag = p.Bag, Disabled = false }
        UI.text(
            w,
            p.Content,
            self.Name,
            { Position = UDim2.fromOffset(10, 7), Size = UDim2.new(1, -40, 0, 18), TextSize = 11 }
        )
        UI.button(p, p.Content, "×", {
            Position = UDim2.new(1, -28, 0, 4),
            Size = UDim2.fromOffset(24, 24),
            TextXAlignment = Enum.TextXAlignment.Center,
        }, function()
            c:Close()
        end)
        local sv = UI.frame(
            w,
            p.Content,
            { Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, -20, 0, 212) },
            nil,
            "Small"
        )
        sv.BackgroundTransparency = 0
        sv.Active = true
        local white = UI.new(
            "Frame",
            sv,
            { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0 }
        )
        UI.round(w, white, "Small")
        UI.new("UIGradient", white, {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
        })
        local black = UI.new(
            "Frame",
            sv,
            { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 0 }
        )
        UI.round(w, black, "Small")
        UI.new("UIGradient", black, {
            Rotation = 90,
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
        })
        local function marker(parent)
            local f =
                UI.frame(w, parent, { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(9, 9), ZIndex = 3 })
            UI.new("UICorner", f, { CornerRadius = UDim.new(1, 0) })
            UI.stroke(w, f, "Thumb", 0)
            return f
        end
        local cursor = marker(sv)
        local hueHit = UI.frame(
            w,
            p.Content,
            { Position = UDim2.fromOffset(10, 245), Size = UDim2.new(1, -20, 0, 28), Active = true }
        )
        local hue = UI.new("Frame", hueHit, {
            Position = UDim2.fromOffset(0, 10),
            Size = UDim2.new(1, 0, 0, 8),
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.new(1, 1, 1),
        })
        UI.round(w, hue, "Small")
        local keys = {}
        for i = 0, 6 do
            keys[i + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1))
        end
        UI.new("UIGradient", hue, { Color = ColorSequence.new(keys) })
        local hueCursor = marker(hue)
        local alphaHit = UI.frame(
            w,
            p.Content,
            { Position = UDim2.fromOffset(10, 273), Size = UDim2.new(1, -20, 0, 24), Active = true }
        )
        local alpha = UI.frame(
            w,
            alphaHit,
            { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 8), ClipsDescendants = true },
            "Row",
            "Small"
        )
        for i = 0, 26 do
            UI.new("Frame", alpha, {
                Position = UDim2.fromOffset(i * 8, 0),
                Size = UDim2.fromOffset(4, 4),
                BackgroundColor3 = Color3.fromRGB(100, 103, 110),
                BackgroundTransparency = 0,
            })
            UI.new("Frame", alpha, {
                Position = UDim2.fromOffset(i * 8 + 4, 4),
                Size = UDim2.fromOffset(4, 4),
                BackgroundColor3 = Color3.fromRGB(100, 103, 110),
                BackgroundTransparency = 0,
            })
        end
        local alphaFill = UI.new("Frame", alpha, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0 })
        UI.new("UIGradient", alphaFill, {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
        })
        local alphaCursor = marker(alpha)
        local hex = UI.new("TextBox", p.Content, {
            Position = UDim2.fromOffset(10, 306),
            Size = UDim2.new(1, -82, 0, 28),
            ClearTextOnFocus = false,
            TextSize = 12,
        })
        UI.bind(w, hex, "TextColor3", "Text")
        local copy = UI.button(p, p.Content, UI.locale(w, "Copy"), {
            Position = UDim2.new(1, -64, 0, 306),
            Size = UDim2.fromOffset(54, 28),
            TextXAlignment = Enum.TextXAlignment.Center,
        }, function()
            -- Clipboard injection is optional and explicit; standard Roblox has no clipboard API.
            if Library.Clipboard then
                UI.call("Clipboard", Library.Clipboard, "#" .. c.Value.Color:ToHex())
            else
                hex:CaptureFocus()
                hex.SelectionStart = 1
                hex.CursorPosition = #hex.Text + 1
            end
        end)
        local h, s, v = c.Value.Color:ToHSV()
        local updating = false
        self.UpdatePicker = function()
            if updating then
                return
            end
            local nh, ns, nv = c.Value.Color:ToHSV()
            if ns > 0 then
                h = nh
            end
            s = ns
            v = nv
            sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            cursor.Position = UDim2.fromScale(s, 1 - v)
            hueCursor.Position = UDim2.fromScale(h, 0.5)
            alphaCursor.Position = UDim2.fromScale(c.Value.Alpha, 0.5)
            alphaFill.BackgroundColor3 = c.Value.Color
            hex.Text = "#" .. c.Value.Color:ToHex():upper()
        end
        local function commit()
            updating = true
            c:Set({ Color = Color3.fromHSV(h, s, v), Alpha = c.Value.Alpha })
            updating = false
            if c.UpdatePicker and not c.Dead then
                c.UpdatePicker()
            end
        end
        UI.drag(owner, sv, function()
            return true
        end, function(pos)
            s = math.clamp((pos.X - sv.AbsolutePosition.X) / math.max(1, sv.AbsoluteSize.X), 0, 1)
            v = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / math.max(1, sv.AbsoluteSize.Y), 0, 1)
            commit()
        end)
        UI.drag(owner, hueHit, function()
            return true
        end, function(pos)
            h = math.clamp((pos.X - hue.AbsolutePosition.X) / math.max(1, hue.AbsoluteSize.X), 0, 1)
            commit()
        end)
        UI.drag(owner, alphaHit, function()
            return true
        end, function(pos)
            c:Set({
                Color = c.Value.Color,
                Alpha = math.clamp((pos.X - alpha.AbsolutePosition.X) / math.max(1, alpha.AbsoluteSize.X), 0, 1),
            })
        end)
        UI.connect(p, hex.FocusLost, function()
            local value = hex.Text:gsub("#", "")
            if #value == 6 and value:match("^%x+$") then
                c:Set({ Color = Color3.fromHex(value), Alpha = c.Value.Alpha })
            else
                UI.warn(c.Name, "HEX must contain six hexadecimal digits")
                c.UpdatePicker()
            end
        end)
        p.OnClose = function()
            self.UpdatePicker = nil
            self.OpenPopup = nil
        end
        self.UpdatePicker()
    end
    return UI.finish(c, { Color = options.Default or w.Theme.Accent, Alpha = options.Alpha or 1 })
end
-- Cubic Bezier uses true control points and 80 segments, not a coarse polyline.
function UI.bezier(points, t)
    local work = table.clone(points)
    for level = #work - 1, 1, -1 do
        for i = 1, level do
            work[i] = work[i]:Lerp(work[i + 1], t)
        end
    end
    return work[1]
end
function UI.Section:AddCurveEditor(options)
    options = options or {}
    local c = UI.control(self, options, "CurveEditor", options.Height or 170)
    local w = c.Window
    c.Label.Size = UDim2.new(1, -20, 0, 24)
    c.Field.Visible = false
    local graph = UI.frame(
        w,
        c.Frame,
        { Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 1, -46), ClipsDescendants = true },
        "Panel",
        "Small"
    )
    local plot = UI.frame(w, graph, { Position = UDim2.fromOffset(10, 12), Size = UDim2.new(1, -20, 1, -28) })
    for i = 0, 10 do
        local x = UI.frame(w, plot, { Position = UDim2.fromScale(i / 10, 0), Size = UDim2.new(0, 1, 1, 0) }, "Border")
        x.BackgroundTransparency = 0.82
        local y = UI.frame(w, plot, { Position = UDim2.fromScale(0, i / 10), Size = UDim2.new(1, 0, 0, 1) }, "Border")
        y.BackgroundTransparency = 0.82
    end
    local segments = {}
    for i = 1, 80 do
        segments[i] =
            UI.frame(w, plot, { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(1, 1.3) }, "Accent")
    end
    local handles = {}
    local labels = {}
    c.Validate = function(points)
        if type(points) ~= "table" or #points < 2 or #points > 8 then
            return false, nil, "Expected 2–8 Vector2 control points"
        end
        local result = {}
        for i, p in points do
            if typeof(p) ~= "Vector2" or not UI.finite(p.X) or not UI.finite(p.Y) then
                return false, nil, "Invalid point"
            end
            result[i] = Vector2.new(math.clamp(p.X, 0, 1), math.clamp(p.Y, 0, 1))
        end
        return true, result
    end
    c.Render = function()
        if not c.Value then
            return
        end
        local size = plot.AbsoluteSize / (c.Popup and 1 or w.Scale)
        local function project(p)
            return Vector2.new(p.X * size.X, p.Y * size.Y)
        end
        local last = project(UI.bezier(c.Value, 0))
        for i, line in segments do
            local nextPoint = project(UI.bezier(c.Value, i / #segments))
            local delta = nextPoint - last
            line.Position = UDim2.fromOffset((last.X + nextPoint.X) / 2, (last.Y + nextPoint.Y) / 2)
            line.Size = UDim2.fromOffset(math.max(0.1, delta.Magnitude + 0.4), 1.3)
            line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
            last = nextPoint
        end
        for i = 1, 8 do
            if not handles[i] then
                local hit = UI.button(c, plot, "", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Size = UDim2.fromOffset(w.Touch and 36 or 20, w.Touch and 36 or 20),
                    ZIndex = 3,
                }, nil)
                local dot = UI.frame(w, hit, {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(5, 5),
                }, "Thumb")
                UI.new("UICorner", dot, { CornerRadius = UDim.new(1, 0) })
                handles[i] = hit
                UI.drag(c, hit, function()
                    return options.Editable ~= false and i <= #c.Value
                end, function(pos)
                    local points = c:Get()
                    points[i] = Vector2.new(
                        math.clamp((pos.X - plot.AbsolutePosition.X) / math.max(1, plot.AbsoluteSize.X), 0, 1),
                        math.clamp((pos.Y - plot.AbsolutePosition.Y) / math.max(1, plot.AbsoluteSize.Y), 0, 1)
                    )
                    c:Set(points)
                end)
            end
            local point = c.Value[i]
            handles[i].Visible = point ~= nil
            if point then
                handles[i].Position = UDim2.fromScale(point.X, point.Y)
            end
        end
        if labels[1] then
            labels[1].Text = string.format("%.2f, %.2f", c.Value[1].X, c.Value[1].Y)
            local lastPoint = c.Value[#c.Value]
            labels[2].Text = string.format("%.2f, %.2f", lastPoint.X, lastPoint.Y)
        end
    end
    labels[1] = UI.text(
        w,
        graph,
        "",
        { Position = UDim2.new(0, 4, 1, -15), Size = UDim2.fromOffset(80, 15), TextSize = 10 },
        "Muted"
    )
    labels[2] = UI.text(w, graph, "", {
        Position = UDim2.new(1, -85, 0, -1),
        Size = UDim2.fromOffset(80, 15),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, "Muted")
    UI.connect(c, plot:GetPropertyChangedSignal("AbsoluteSize"), function()
        c.Render()
    end)
    return UI.finish(
        c,
        options.Points or { Vector2.new(0, 1), Vector2.new(0, 0), Vector2.new(1, 1), Vector2.new(1, 0) }
    )
end
function UI.Section:AddGraph(options)
    options = table.clone(options or {})
    options.Editable = false
    return self:AddCurveEditor(options)
end
-- Companion layout and isolated preview scene.
function UI.Window:AddCompanionWindow(options)
    options = options or {}
    local p = setmetatable({
        Window = self,
        Bag = UI.bag(),
        Controls = {},
        Linked = options.Linked ~= false,
        Side = options.Side or "Left",
        Visible = true,
        Size = options.Size or Vector2.new(280, 410),
    }, UI.Companion)
    p.Frame = UI.frame(
        self,
        self.Root,
        { Size = UDim2.fromOffset(p.Size.X, p.Size.Y), Position = UDim2.fromOffset(12, 12), ZIndex = 3, Active = true },
        "Base",
        "Panel"
    )
    UI.stroke(self, p.Frame, "Border", 0.65)
    p.Header = UI.frame(self, p.Frame, { Size = UDim2.new(1, 0, 0, 34) })
    UI.text(
        self,
        p.Header,
        options.Title or "Animation preview",
        { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -44, 1, 0), TextSize = 11 }
    )
    local closeButton = UI.button(p, p.Header, "×", {
        Position = UDim2.new(1, -32, 0, 4),
        Size = UDim2.fromOffset(28, 28),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, function()
        p:Hide()
    end)
    p.Content = UI.new("ScrollingFrame", p.Frame, {
        Position = UDim2.fromOffset(8, 36),
        Size = UDim2.new(1, -16, 1, -44),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
    })
    UI.list(p.Content, 4)
    p.Section = setmetatable(
        { Window = self, Bag = p.Bag, Frame = p.Content, Controls = p.Controls, Name = "Preview", Visible = true },
        UI.Section
    )
    UI.drag(p, p.Header, function(pos)
        if UI.inside(closeButton, pos) then
            return false
        end
        return { Start = pos, Position = p.Frame.Position }
    end, function(pos, s)
        p.Linked = false
        p.Frame.Position =
            UDim2.fromOffset(s.Position.X.Offset + pos.X - s.Start.X, s.Position.Y.Offset + pos.Y - s.Start.Y)
        p:Reflow()
    end)
    table.insert(self.Companions, p)
    p:Reflow()
    return p
end
UI.Window.AddSecondaryWindow = UI.Window.AddCompanionWindow
function UI.Companion:Reflow()
    if self.Dead then
        return
    end
    local w = self.Window
    local b = w.Root.AbsoluteSize
    self.Frame.Visible = self.Visible and w.Visible and (not w.Compact or self.MobileOpen == true)
    local width = math.min(self.Size.X, b.X - 16)
    local height = math.min(self.Size.Y, b.Y - 16)
    self.Frame.Size = UDim2.fromOffset(width, height)
    local x, y = self.Frame.Position.X.Offset, self.Frame.Position.Y.Offset
    if self.Linked then
        local pos = w.Frame.AbsolutePosition - w.Root.AbsolutePosition
        x = self.Side == "Right" and pos.X + w.Frame.AbsoluteSize.X + 18 or pos.X - width - 18
        y = pos.Y - 24
        if (x < 8 or x + width > b.X - 8) and not self.MobileOpen then
            local alternative = self.Side == "Right" and pos.X - width - 18 or pos.X + w.Frame.AbsoluteSize.X + 18
            if alternative >= 8 and alternative + width <= b.X - 8 then
                x = alternative
            else
                self.Frame.Visible = false
            end
        end
    end
    self.Frame.Position = UDim2.fromOffset(
        math.clamp(x, 8, math.max(8, b.X - width - 8)),
        math.clamp(y, 8, math.max(8, b.Y - height - 8))
    )
end
function UI.Companion:SetVisible(v)
    self.Visible = v == true
    self.MobileOpen = self.Visible
    self:Reflow()
end
function UI.Companion:Show()
    self:SetVisible(true)
end
function UI.Companion:Hide()
    self:SetVisible(false)
end
function UI.Companion:SetLinked(v)
    self.Linked = v == true
    self:Reflow()
end
function UI.Companion:Destroy()
    if self.Dead then
        return
    end
    self.Dead = true
    for _, c in table.clone(self.Controls) do
        c:Destroy()
    end
    UI.clean(self.Bag)
    self.Frame:Destroy()
    local i = table.find(self.Window.Companions, self)
    if i then
        table.remove(self.Window.Companions, i)
    end
end
function UI.Companion:AddViewport(o)
    return self.Section:AddViewport(o)
end
function UI.Companion:AddLabel(o)
    return self.Section:AddLabel(o)
end
function UI.Companion:AddProgressBar(o)
    return self.Section:AddProgressBar(o)
end
function UI.Companion:AddButton(o)
    return self.Section:AddButton(o)
end
function UI.Companion:AddMetadata(values)
    local labels = {}
    local c = self.Section:AddCustomControl({
        Name = "Metadata",
        Height = math.ceil(#values / 2) * 18,
        Build = function(frame, control)
            for i, entry in values do
                local right = i % 2 == 0
                labels[i] = UI.text(control.Window, frame, tostring(entry.Name) .. ": " .. tostring(entry.Value), {
                    Position = UDim2.new(right and 0.5 or 0, 4, 0, math.floor((i - 1) / 2) * 18),
                    Size = UDim2.new(0.5, -8, 0, 18),
                    TextSize = 10,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = right and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
                }, i > 2 and "Muted" or "Text")
            end
        end,
    })
    function c:SetEntry(index, value)
        assert(labels[index], "[UiLib] Unknown metadata entry")
        labels[index].Text = tostring(values[index].Name) .. ": " .. tostring(value)
    end
    return c
end
function UI.Companion:AddActions(actions)
    return self.Section:AddCustomControl({
        Name = "Actions",
        Height = 28,
        Build = function(frame, c)
            for i, a in actions do
                local b = UI.button(
                    c,
                    frame,
                    "",
                    { Position = UDim2.new((i - 1) / #actions, 2, 0, 0), Size = UDim2.new(1 / #actions, -4, 1, 0) },
                    a.Callback
                )
                b.BackgroundTransparency = 0
                UI.icon(
                    c.Window,
                    b,
                    a.Icon or "play",
                    { Position = UDim2.new(0.5, -8, 0.5, -8), Size = UDim2.fromOffset(16, 16) }
                )
            end
        end,
    })
end
function UI.Section:AddViewport(options)
    options = options or {}
    local c = UI.control(self, options, "Viewport", options.Height or 260)
    local w = c.Window
    c.Label.Visible = false
    c.Field.Visible = false
    c.Frame.BackgroundTransparency = 1
    c.Viewport = UI.new("ViewportFrame", c.Frame, {
        Size = UDim2.fromScale(1, 1),
        Ambient = Color3.fromRGB(180, 180, 185),
        LightColor = Color3.new(1, 1, 1),
        LightDirection = Vector3.new(-1, -1, -2),
    })
    c.World = UI.new("WorldModel", c.Viewport, { Name = "PreviewWorld" })
    c.Camera = UI.new("Camera", c.Viewport, { FieldOfView = 32 })
    c.Viewport.CurrentCamera = c.Camera
    c.Scene = UI.new("Model", c.World, { Name = "PreviewScene" })
    c.Yaw = options.Rotation or -0.25
    c.Pitch = 0
    local lines = {}
    c.Cage = UI.new("Model", c.World, { Name = "AccentWireframe" })
    function c:FrameCamera()
        if not self.Model then
            return
        end
        local cf, size = self.Bounds, self.BoundsSize
        if not cf then
            cf, size = self.Model:GetBoundingBox()
            self.Bounds = cf
            self.BoundsSize = size
        end
        local aspect = self.Viewport.AbsoluteSize.X / math.max(1, self.Viewport.AbsoluteSize.Y)
        local fov = math.rad(self.Camera.FieldOfView / 2)
        local distance = (math.max(size.Y, size.X / math.max(0.25, aspect)) * 0.65) / math.tan(fov) + size.Z * 0.7
        local center = cf.Position
        local rotation = CFrame.Angles(self.Pitch, self.Yaw, 0)
        self.Camera.CFrame =
            CFrame.lookAt(center + rotation:VectorToWorldSpace(Vector3.new(0, size.Y * 0.05, distance)), center)
    end
    function c:SetModel(model)
        if typeof(model) ~= "Instance" or not model:IsA("Model") then
            UI.warn(self.Name, "Model must be a Model")
            return false
        end
        local ok, clone = pcall(function()
            return model:Clone()
        end)
        if not ok or not clone then
            UI.warn(self.Name, "Model is not cloneable; enable Archivable")
            return false
        end
        for _, obj in clone:GetDescendants() do
            if obj:IsA("LuaSourceContainer") then
                obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.Anchored = true
                obj.CanCollide = false
                obj.CanTouch = false
                obj.CanQuery = false
            end
        end
        if not clone:FindFirstChildWhichIsA("BasePart", true) then
            clone:Destroy()
            UI.warn(self.Name, "Model contains no parts")
            return false
        end
        if self.Model then
            self.Model:Destroy()
        end
        self.Model = clone
        self.Bounds = nil
        clone.Parent = self.Scene
        local cf, size = clone:GetBoundingBox()
        clone:PivotTo(CFrame.new(-cf.Position) * clone:GetPivot())
        self.Cage:ClearAllChildren()
        table.clear(lines)
        local boxCf, boxSize = clone:GetBoundingBox()
        boxSize += Vector3.new(0.8, 0.65, 0.65)
        if options.Wireframe ~= false then
            local vertices = {}
            for x = -1, 1, 2 do
                for y = -1, 1, 2 do
                    for z = -1, 1, 2 do
                        table.insert(
                            vertices,
                            boxCf:PointToWorldSpace(
                                Vector3.new(x * boxSize.X / 2, y * boxSize.Y / 2, z * boxSize.Z / 2)
                            )
                        )
                    end
                end
            end
            for i = 1, 8 do
                for j = i + 1, 8 do
                    local a, b = vertices[i], vertices[j]
                    local changed = 0
                    local localA, localB = boxCf:PointToObjectSpace(a), boxCf:PointToObjectSpace(b)
                    if math.abs(localA.X - localB.X) > 0.01 then
                        changed += 1
                    end
                    if math.abs(localA.Y - localB.Y) > 0.01 then
                        changed += 1
                    end
                    if math.abs(localA.Z - localB.Z) > 0.01 then
                        changed += 1
                    end
                    if changed == 1 then
                        local part = UI.new("Part", self.Cage, {
                            Anchored = true,
                            CanCollide = false,
                            CanTouch = false,
                            CanQuery = false,
                            CastShadow = false,
                            Size = Vector3.new(0.012, 0.012, (b - a).Magnitude),
                            CFrame = CFrame.lookAt((a + b) / 2, b),
                            Material = Enum.Material.SmoothPlastic,
                            Transparency = 0.15,
                        })
                        UI.bind(w, part, "Color", "Accent")
                        table.insert(lines, part)
                    end
                end
            end
        end
        self:FrameCamera()
        return true
    end
    function c:SetRotation(yaw, pitch)
        self.Yaw = yaw
        self.Pitch = math.clamp(pitch or self.Pitch, -1.2, 1.2)
        self:FrameCamera()
    end
    function c:SyncRotation()
        local visible = self.AutoRotate and not self.Dead and self.Window.Visible
        local ancestor = self.Frame
        while ancestor and ancestor ~= self.Window.Gui do
            if ancestor:IsA("GuiObject") and not ancestor.Visible then
                visible = false
                break
            end
            ancestor = ancestor.Parent
        end
        if visible and not self.RotateConnection then
            self.RotateConnection = UI.connect(self, UI.S.Run.RenderStepped, function(dt)
                self:SetRotation(self.Yaw + dt * 0.35)
            end)
        elseif not visible and self.RotateConnection then
            self.RotateConnection:Disconnect()
            self.Bag.Items[self.RotateConnection] = nil
            self.RotateConnection = nil
        end
    end
    function c:SetAutoRotate(enabled)
        self.AutoRotate = enabled == true
        self:SyncRotation()
    end
    local visibilityAncestor = c.Frame
    while visibilityAncestor and visibilityAncestor ~= w.Gui do
        if visibilityAncestor:IsA("GuiObject") then
            UI.connect(c, visibilityAncestor:GetPropertyChangedSignal("Visible"), function()
                c:SyncRotation()
            end)
        end
        visibilityAncestor = visibilityAncestor.Parent
    end
    UI.drag(c, c.Viewport, function(pos)
        return options.Interactive ~= false and { Start = pos, Yaw = c.Yaw, Pitch = c.Pitch }
    end, function(pos, s)
        c:SetRotation(s.Yaw + (pos.X - s.Start.X) * 0.012, s.Pitch + (pos.Y - s.Start.Y) * 0.01)
    end)
    UI.connect(c, c.Viewport:GetPropertyChangedSignal("AbsoluteSize"), function()
        c:FrameCamera()
    end)
    if options.Model then
        c:SetModel(options.Model)
    end
    if typeof(options.Camera) == "Instance" and options.Camera:IsA("Camera") then
        c.Camera.CFrame = options.Camera.CFrame
        c.Camera.FieldOfView = options.Camera.FieldOfView
    end
    c:SetAutoRotate(options.AutoRotate == true)
    return c
end
function UI.popupSection(w, p, name)
    local frame = UI.new("ScrollingFrame", p.Content, {
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 1, -16),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
    })
    UI.list(frame, 3)
    local section = setmetatable(
        { Window = w, Popup = p, Bag = UI.bag(), Frame = frame, Controls = {}, Name = name or "", Visible = true },
        UI.Section
    )
    UI.keep(p.Bag, function()
        section:Destroy()
    end)
    return section
end
function UI.Window:OpenProfile()
    if self.Dead or not self.Visible then
        return
    end
    if self.ProfilePopup and not self.ProfilePopup.Dead then
        self:ClosePopups()
        return
    end
    local p = self:OpenPopover(self.ProfileButton, Vector2.new(224, self.Touch and 430 or 268))
    self.ProfilePopup = p
    local s = UI.popupSection(self, p, "Profile")
    s.RowHeight = self.Touch and 44 or 24
    local w = self
    s:AddCustomControl({
        Name = "Profile",
        Height = 52,
        Build = function(frame)
            UI.icon(
                w,
                frame,
                "profile",
                { Position = UDim2.fromOffset(10, 15), Size = UDim2.fromOffset(16, 16) },
                "Text"
            )
            UI.text(w, frame, w.Title, { Position = UDim2.fromOffset(38, 8), Size = UDim2.new(1, -44, 0, 20) })
            UI.text(
                w,
                frame,
                "Interface preferences",
                { Position = UDim2.fromOffset(38, 27), Size = UDim2.new(1, -44, 0, 16), TextSize = 10 },
                "Muted"
            )
        end,
    })
    s:AddColorPicker({
        Name = "Color scheme",
        Default = self.Theme.Accent,
        Callback = function(color)
            w:SetAccent(color, true)
        end,
    })
    local function nested(name, build)
        local c = s:AddButton({ Name = name .. "    ...", Style = "Row" })
        c.Callback = function()
            local child = w:OpenPopover(c.Frame, Vector2.new(252, self.Touch and 116 or 92), p)
            build(UI.popupSection(w, child, name))
        end
    end
    nested("Scale", function(section)
        section:AddSlider({
            Name = "Scale",
            Min = 0.75,
            Max = 1.5,
            Increment = 0.05,
            Default = w.Scale,
            Callback = function(v)
                w:SetScale(v)
            end,
        })
        section:AddDropdown({
            Name = "Scale mode",
            Options = { "Manual", "Fit" },
            Default = w.ScaleMode or "Manual",
            Callback = function(v)
                w.ScaleMode = v
                w:Reflow()
            end,
        })
    end)
    nested("Corner smoothness", function(section)
        section:AddSlider({
            Name = "Corner radius",
            Min = 0,
            Max = 2,
            Increment = 0.05,
            Default = w.CornerStyle,
            Callback = function(v)
                w:SetCornerStyle(v)
            end,
        })
    end)
    nested("Animation speed", function(section)
        local speedControl
        local enabled = section:AddToggle({
            Name = "Enabled",
            Default = w.AnimationSpeed > 0,
            Callback = function(v)
                w:SetAnimationSpeed(v and (speedControl and speedControl:Get() or 1) or 0)
            end,
        })
        speedControl = section:AddSlider({
            Name = "Animation speed",
            Min = 0.1,
            Max = 4,
            Increment = 0.1,
            Default = math.max(0.1, w.AnimationSpeed),
            Callback = function(v)
                if enabled:Get() then
                    w:SetAnimationSpeed(v)
                end
            end,
        })
    end)
    local locales = {}
    for key in Library.Locales do
        table.insert(locales, key)
    end
    table.sort(locales)
    s:AddDropdown({
        Name = "Interface language",
        Options = locales,
        Default = w.Language,
        Callback = function(v)
            w:SetLocale(v)
        end,
    })
    s:AddKeybind({
        Name = "Hide / show key",
        Default = w.HideKey,
        Changed = function(v)
            w.HideKey = v
        end,
    })
    if #self.Companions > 0 then
        s:AddButton({
            Name = "Show preview",
            Callback = function()
                w.Companions[1]:Show()
                w:ClosePopups()
            end,
        })
    end
    p.OnClose = function()
        w.ProfilePopup = nil
    end
    return p
end
function UI.Window:CreateContextMenu(anchor, items, parentPopup)
    local p =
        self:OpenPopover(anchor, Vector2.new(190, math.min(360, #items * (self.Touch and 44 or 32) + 16)), parentPopup)
    local s = UI.popupSection(self, p, "Context")
    for _, item in items do
        s:AddButton({
            Name = item.Name,
            Style = item.Destructive and "Destructive" or "Row",
            Disabled = item.Disabled,
            Callback = function()
                p:Destroy()
                UI.call("Context/" .. tostring(item.Name), item.Callback)
            end,
        })
    end
    return p
end
function UI.Control:SetContextMenu(items)
    if self.ContextButton then
        self.ContextButton:Destroy()
    end
    local b = UI.button(
        self,
        self.Frame,
        "",
        { Position = UDim2.new(0.55, -26, 0, 0), Size = UDim2.fromOffset(24, self.Frame.Size.Y.Offset) },
        function()
            self.Window:CreateContextMenu(self.ContextButton, items, self.Popup)
        end
    )
    UI.icon(self.Window, b, "ellipsis", { Position = UDim2.new(0.5, -8, 0.5, -8), Size = UDim2.fromOffset(16, 16) })
    self.ContextButton = b
    self.Label.Size = UDim2.new(0.55, -30, 1, 0)
    return self
end
function UI.Window:Notify(options)
    if self.Dead then
        return
    end
    if type(options) == "string" then
        options = { Title = options }
    end
    options = options or {}
    local n = { Window = self, Bag = UI.bag() }
    local w = self
    n.Frame = UI.frame(
        self,
        self.ToastHolder,
        { Size = UDim2.new(1, 0, 0, options.Description and 66 or 40), ZIndex = 180 },
        "Panel",
        "Control"
    )
    UI.stroke(self, n.Frame, "Border", 0.5)
    local kind = ({ Error = "Danger", Warning = "Warning", Success = "Success", Info = "Accent" })[options.Type]
        or "Accent"
    UI.frame(self, n.Frame, { Position = UDim2.fromOffset(0, 9), Size = UDim2.new(0, 2, 1, -18) }, kind, "Small")
    UI.text(
        self,
        n.Frame,
        options.Title or "Notification",
        { Position = UDim2.fromOffset(12, 7), Size = UDim2.new(1, -45, 0, 24), TextTruncate = Enum.TextTruncate.AtEnd }
    )
    if options.Description then
        UI.text(
            self,
            n.Frame,
            options.Description,
            { Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 0, 30), TextWrapped = true, TextSize = 11 },
            "Muted"
        )
    end
    function n:Destroy()
        if self.Dead then
            return
        end
        self.Dead = true
        UI.clean(self.Bag)
        self.Frame:Destroy()
        w.Bag.Items[self] = nil
    end
    UI.button(n, n.Frame, "×", {
        Position = UDim2.new(1, -30, 0, 6),
        Size = UDim2.fromOffset(24, 26),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, function()
        n:Destroy()
    end)
    UI.keep(self.Bag, n)
    if options.Duration ~= 0 then
        UI.later(n, options.Duration or 4, function()
            n:Destroy()
        end)
    end
    return n
end
function UI.Window:CreateDialog(options)
    options = options or {}
    if self.Modal then
        self.Modal:Destroy()
    end
    self:ClosePopups()
    UI.releaseDrag(self)
    self:ReleaseKeys()
    local w = self
    local d = { Window = self, Bag = UI.bag() }
    d.Backdrop = UI.new("TextButton", self.Overlay, {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(),
        BackgroundTransparency = 0.45,
        ZIndex = 160,
        Text = "",
        Modal = true,
    })
    d.Frame = UI.frame(self, d.Backdrop, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, math.min(400, self.Root.AbsoluteSize.X - 24), 0, 210),
        ZIndex = 161,
        Active = true,
    }, "Panel", "Popup")
    UI.stroke(self, d.Frame, "Border", 0.4)
    UI.text(
        self,
        d.Frame,
        options.Title or "Confirm",
        { Position = UDim2.fromOffset(18, 15), Size = UDim2.new(1, -36, 0, 26), TextSize = 15 }
    )
    UI.text(self, d.Frame, options.Description or "", {
        Position = UDim2.fromOffset(18, 51),
        Size = UDim2.new(1, -36, 1, -113),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, "Muted")
    local confirmation
    if options.Confirmation then
        confirmation = UI.new("TextBox", d.Frame, {
            Position = UDim2.fromOffset(18, 118),
            Size = UDim2.new(1, -36, 0, 28),
            ClearTextOnFocus = false,
            PlaceholderText = "Type " .. tostring(options.Confirmation),
        })
        UI.bind(self, confirmation, "TextColor3", "Text")
    end
    local previous = game:GetService("GuiService").SelectedObject
    function d:Destroy()
        if self.Dead then
            return
        end
        self.Dead = true
        UI.clean(self.Bag)
        self.Backdrop:Destroy()
        if w.Modal == self then
            w.Modal = nil
        end
        if previous and previous.Parent then
            game:GetService("GuiService").SelectedObject = previous
        end
    end
    local actions = options.Actions
        or { { Name = UI.locale(self, "Cancel") }, { Name = UI.locale(self, "Confirm"), Callback = options.Callback } }
    for i, action in actions do
        local b = UI.button(d, d.Frame, action.Name, {
            Position = UDim2.new((i - 1) / #actions, 12, 1, -48),
            Size = UDim2.new(1 / #actions, -24, 0, 32),
            TextXAlignment = Enum.TextXAlignment.Center,
        }, function()
            if
                confirmation
                and action.Name ~= UI.locale(w, "Cancel")
                and confirmation.Text ~= tostring(options.Confirmation)
            then
                confirmation:CaptureFocus()
                return
            end
            d:Destroy()
            UI.call("Dialog", action.Callback)
        end)
        b.BackgroundTransparency = 0
        if i == 1 then
            game:GetService("GuiService").SelectedObject = b
        end
    end
    UI.connect(d, d.Backdrop.Activated, function()
        if options.Dismissible ~= false then
            d:Destroy()
        end
    end)
    UI.connect(d, self.Root:GetPropertyChangedSignal("AbsoluteSize"), function()
        d.Frame.Size =
            UDim2.fromOffset(math.min(400, w.Root.AbsoluteSize.X - 24), math.min(210, w.Root.AbsoluteSize.Y - 24))
    end)
    self.Modal = d
    return d
end
-- Bounded, tagged serializer. No functions, Instances, cycles, or arbitrary Enum lookups.
function UI.encode(value, depth, seen)
    depth = depth or 0
    seen = seen or {}
    assert(depth < 24, "Config nesting too deep")
    local kind = typeof(value)
    if kind == "Color3" then
        return { __ui = "color", r = value.R, g = value.G, b = value.B }
    end
    if kind == "Vector2" then
        return { __ui = "vector2", x = value.X, y = value.Y }
    end
    if kind == "EnumItem" then
        return { __ui = "enum", enum = tostring(value.EnumType), name = value.Name }
    end
    if kind == "number" then
        assert(UI.finite(value), "Nonfinite config number")
        return value
    end
    if kind == "boolean" or kind == "string" or kind == "nil" then
        return value
    end
    assert(kind == "table", "Unsupported config value " .. kind)
    assert(not seen[value], "Cyclic config")
    seen[value] = true
    local output = {}
    for k, v in value do
        assert(type(k) == "string" or type(k) == "number", "Unsupported key")
        output[k] = UI.encode(v, depth + 1, seen)
    end
    seen[value] = nil
    return output
end
function UI.decode(value, depth)
    depth = depth or 0
    assert(depth < 24, "Config nesting too deep")
    if type(value) ~= "table" then
        assert(
            type(value) == "string" or type(value) == "boolean" or value == nil or UI.finite(value),
            "Invalid config scalar"
        )
        return value
    end
    if value.__ui == "color" then
        assert(UI.finite(value.r) and UI.finite(value.g) and UI.finite(value.b), "Malformed Color3")
        assert(
            value.r >= 0 and value.r <= 1 and value.g >= 0 and value.g <= 1 and value.b >= 0 and value.b <= 1,
            "Color channels outside 0..1"
        )
        return Color3.new(value.r, value.g, value.b)
    elseif value.__ui == "vector2" then
        assert(UI.finite(value.x) and UI.finite(value.y), "Malformed Vector2")
        return Vector2.new(value.x, value.y)
    elseif value.__ui == "enum" then
        assert(
            value.enum == "KeyCode"
                or value.enum == "UserInputType"
                or value.enum == "Enum.KeyCode"
                or value.enum == "Enum.UserInputType",
            "Unsupported Enum"
        )
        local enum = (value.enum == "KeyCode" or value.enum == "Enum.KeyCode") and Enum.KeyCode or Enum.UserInputType
        local found
        for _, item in enum:GetEnumItems() do
            if item.Name == value.name then
                found = item
                break
            end
        end
        assert(found, "Unknown Enum item")
        return found
    elseif value.__ui ~= nil then
        error("Unknown serialized tag")
    end
    local result = {}
    for k, v in value do
        result[k] = UI.decode(v, depth + 1)
    end
    return result
end
function UI.Window:GetFlag(flag)
    local c = self.Flags[flag]
    return c and c:Get()
end
function UI.Window:SetFlag(flag, value, silent)
    local c = self.Flags[flag]
    if not c then
        UI.warn("Flags", "Unknown flag " .. tostring(flag))
        return false
    end
    return c:Set(value, silent)
end
function UI.Window:GetFlags()
    local result = {}
    for flag, c in self.Flags do
        result[flag] = c:Get()
    end
    return result
end
function UI.Window:ExportConfig()
    local ok, result = pcall(function()
        return UI.S.Http:JSONEncode({ Version = 1, Flags = UI.encode(self:GetFlags()) })
    end)
    if not ok then
        UI.warn("Config", result)
        return nil, result
    end
    return result
end
function UI.Window:ImportConfig(data, silent)
    if self.Dead then
        return false, "Window destroyed"
    end
    local ok, result = pcall(function()
        if type(data) == "string" then
            assert(#data <= 1048576, "Config exceeds 1MB")
            data = UI.S.Http:JSONDecode(data)
        end
        assert(
            type(data) == "table" and data.Version == 1 and type(data.Flags) == "table",
            "Malformed or unsupported config"
        )
        local decoded = UI.decode(data.Flags)
        local pending = {}
        for flag, value in decoded do
            local control = self.Flags[flag]
            if control then
                local valid, normalized, message = control.Validate(value)
                assert(valid, flag .. ": " .. tostring(message or "invalid value"))
                table.insert(
                    pending,
                    { Control = control, Value = normalized, Changed = not UI.equal(control.Value, normalized) }
                )
            else
                UI.warn("Config", "Ignoring unknown flag " .. tostring(flag))
            end
        end
        return pending
    end)
    if not ok then
        UI.warn("Config", result)
        return false, result
    end
    -- Validate everything before mutating anything; callbacks see the complete imported state.
    for _, item in result do
        item.Control:Set(item.Value, true)
    end
    if not silent then
        for _, item in result do
            if item.Changed and not item.Control.Dead then
                local c = item.Control
                local args = c.Kind == "ColorPicker" and { c.Value.Color, c.Value.Alpha } or { c:Get() }
                UI.call(c.Name, c.Kind == "Keybind" and c.ChangedCallback or c.Callback, unpack(args))
                for callback in c.Listeners do
                    UI.call(c.Name, callback, unpack(args))
                end
            end
        end
    end
    return true
end
function Library:GetWindow(id)
    return self.Windows[id or "default"]
end
function Library:GetWindows()
    local result = {}
    for _, w in self.Windows do
        table.insert(result, w)
    end
    return result
end
function Library:RegisterTheme(name, theme)
    assert(type(name) == "string" and type(theme) == "table", "[UiLib] RegisterTheme expects name and token table")
    for k, v in theme do
        assert(UI.Palette[k] and typeof(v) == "Color3", "[UiLib] Invalid theme token " .. tostring(k))
    end
    self.Themes[name] = UI.copy(theme)
end
function Library:SetTheme(theme)
    local data = type(theme) == "string" and self.Themes[theme] or theme
    if type(data) ~= "table" then
        UI.warn("Theme", "Unknown theme")
        return
    end
    for k, v in data do
        if not UI.Palette[k] or typeof(v) ~= "Color3" then
            UI.warn("Theme", "Malformed theme")
            return
        end
    end
    self.Theme = UI.copy(UI.Palette)
    for k, v in data do
        self.Theme[k] = v
    end
    for _, w in self.Windows do
        w:SetTheme(data)
    end
end
function Library:GetTheme()
    return UI.copy(self.Theme or UI.Palette)
end
function Library:SetAccent(color)
    if typeof(color) ~= "Color3" then
        UI.warn("Theme", "Expected Color3")
        return
    end
    self.Theme = self.Theme or UI.copy(UI.Palette)
    self.Theme.Accent = color
    for _, w in self.Windows do
        w:SetAccent(color)
    end
end
function Library:GetAccent()
    return (self.Theme or UI.Palette).Accent
end
function Library:SetScale(n)
    if not UI.finite(n) then
        return
    end
    self.Scale = math.clamp(n, 0.75, 1.5)
    for _, w in self.Windows do
        w:SetScale(self.Scale)
    end
end
function Library:GetScale()
    return self.Scale
end
function Library:SetAnimationSpeed(n)
    if not UI.finite(n) then
        return
    end
    self.AnimationSpeed = math.clamp(n, 0, 4)
    for _, w in self.Windows do
        w:SetAnimationSpeed(self.AnimationSpeed)
    end
end
function Library:GetAnimationSpeed()
    return self.AnimationSpeed
end
function Library:SetCornerStyle(n)
    if not UI.finite(n) then
        return
    end
    self.CornerStyle = math.clamp(n, 0, 2)
    for _, w in self.Windows do
        w:SetCornerStyle(n)
    end
end
function Library:RegisterLocale(name, dictionary)
    assert(type(name) == "string" and type(dictionary) == "table", "[UiLib] Invalid locale")
    for k, v in dictionary do
        assert(type(k) == "string" and type(v) == "string", "[UiLib] Locale entries must be strings")
    end
    self.Locales[name] = table.clone(dictionary)
end
function Library:SetLanguage(name)
    if not self.Locales[name] then
        UI.warn("Locale", "Unknown locale")
        return
    end
    self.Language = name
    for _, w in self.Windows do
        w:SetLocale(name)
    end
end
function Library:RegisterIcon(name, asset)
    assert(type(name) == "string" and (type(asset) == "number" or type(asset) == "string"), "[UiLib] Invalid icon")
    self.Icons[name] = asset
end
function Library:SetClipboardHandler(callback)
    assert(callback == nil or type(callback) == "function", "[UiLib] Invalid clipboard handler")
    self.Clipboard = callback
end
function Library:Notify(options)
    local w = self:GetWindow() or self:GetWindows()[1]
    if w then
        return w:Notify(options)
    end
    UI.warn("Notify", "Create a window first")
end
function Library:CreateDialog(options)
    local w = self:GetWindow() or self:GetWindows()[1]
    if w then
        return w:CreateDialog(options)
    end
    UI.warn("Dialog", "Create a window first")
end
function Library:Unload()
    for _, w in self:GetWindows() do
        w:Destroy()
    end
end
Library.Destroy = Library.Unload
Library:RegisterTheme("Reference", UI.Palette)
-- Opt-in visual fixture, built exclusively through the public component API.
function Library:CreateReferenceDemo(options)
    options = options or {}
    local w = self:CreateWindow({
        Id = options.Id or "reference",
        Title = options.Title or "Interface",
        Size = UDim2.fromOffset(800, 540),
        Accent = Color3.fromRGB(197, 54, 225),
        Resizable = true,
        Parent = options.Parent,
    })
    local main = w:AddTab({ Name = "Main", Icon = "target" })
    local general = main:AddLeftSection({ Name = "General" })
    general
        :AddToggle({
            Name = "Enable targeting",
            Default = false,
            Flag = "Demo.Enabled",
            Tooltip = "Example interface control; no gameplay automation.",
        })
        :SetContextMenu({
            {
                Name = "Reset",
                Callback = function()
                    w:SetFlag("Demo.Enabled", false)
                end,
            },
        })
    general:AddToggle({ Name = "Silent mode", Default = false, Flag = "Demo.Silent" })
    general:AddSlider({ Name = "Field of view", Min = 0, Max = 100, Default = 50, Flag = "Demo.FOV" })
    general:AddToggle({ Name = "Automatic action", Default = false, Flag = "Demo.Automatic" }):SetContextMenu({
        {
            Name = "Configure",
            Callback = function()
                w:OpenProfile()
            end,
        },
    })
    general:AddButton({
        Name = "Notification",
        Callback = function()
            w:Notify({
                Title = "Interface updated",
                Description = "Every accent element shares one theme.",
                Type = "Info",
            })
        end,
    })
    local targets = main:AddLeftSection({ Name = "Target selection" })
    targets:AddDropdown({
        Name = "Target area",
        Options = { "None", "Head", "Torso", "Nearest" },
        Default = "None",
        Flag = "Demo.Area",
    })
    targets:AddDropdown({
        Name = "Priority",
        Options = { "Nearest", "Distance", "Health" },
        Default = "Nearest",
        Flag = "Demo.Priority",
    })
    targets:AddToggle({ Name = "Multiple targets", Default = false, Flag = "Demo.Multi" })
    targets:AddRangeSlider({ Name = "Distance range", Min = 0, Max = 100, Default = { 15, 80 }, Flag = "Demo.Range" })
    local motion = main:AddRightSection({ Name = "Smoothness and speed" })
    motion:AddCurveEditor({
        Name = "Smoothness type",
        Points = { Vector2.new(0, 1), Vector2.new(0, 0), Vector2.new(1, 1), Vector2.new(1, 0) },
        Height = 166,
        Flag = "Demo.Curve",
    })
    motion:AddSlider({ Name = "Horizontal speed", Min = 0, Max = 100, Default = 50, Flag = "Demo.Horizontal" })
    motion:AddSlider({ Name = "Vertical speed", Min = 0, Max = 100, Default = 50, Flag = "Demo.Vertical" })
    motion:AddToggle({ Name = "Camera compensation", Default = false, Flag = "Demo.Compensation" }):SetContextMenu({
        {
            Name = "Animation settings",
            Callback = function()
                w:OpenProfile()
            end,
        },
    })
    local filters = main:AddRightSection({ Name = "Filters and checks" })
    filters:AddToggle({ Name = "Ignore teammates", Default = false, Flag = "Demo.Teammates" })
    filters:AddToggle({ Name = "Ignore obstacles", Default = false, Flag = "Demo.Obstacles" })
    local controls = w:AddTab({ Name = "Controls", Icon = "grid" })
    local values = controls:AddLeftSection({ Name = "Value controls" })
    values:AddCheckbox({ Name = "Checkbox", Default = true, Flag = "Demo.Check" })
    values:AddMultiDropdown({
        Name = "Selections",
        Options = { "One", "Two", "Three", "Four" },
        Default = { "One" },
        Flag = "Demo.Selections",
        MaxSelections = 3,
    })
    values:AddInput({ Name = "Text", Default = "Example", Flag = "Demo.Text" })
    values:AddNumberInput({ Name = "Number", Default = 12, Min = 0, Max = 100, Flag = "Demo.Number" })
    values:AddKeybind({ Name = "Action key", Default = Enum.KeyCode.F, Mode = "Press" })
    local appearance = controls:AddRightSection({ Name = "Appearance" })
    appearance:AddColorPicker({
        Name = "Color scheme",
        Default = w:GetAccent(),
        Flag = "Demo.Color",
        Callback = function(color)
            w:SetAccent(color, true)
        end,
    })
    appearance:AddSegmentedControl({ Name = "Mode", Options = { "One", "Two", "Three" }, Default = "Two" })
    appearance:AddStatus({ Name = "Status", Default = "Ready" })
    appearance:AddParagraph({
        Name = "Reusable library",
        Content = "All controls on this page use the same public API as the reference composition.",
    })
    appearance:AddButton({
        Name = "Open dialog",
        Callback = function()
            w:CreateDialog({
                Title = "Confirm change",
                Description = "Callbacks are isolated; cancel leaves state unchanged.",
            })
        end,
    })
    w:AddTab({ Name = "Preview", Icon = "play" }):AddSection({ Name = "Companion" }):AddButton({
        Name = "Show preview",
        Callback = function()
            if w.Companions[1] then
                w.Companions[1]:Show()
            end
        end,
    })
    local settings = w:AddTab({ Name = "Settings", Icon = "settings" })
    settings:AddSection({ Name = "Interface", Side = "Left" }):AddButton({
        Name = "Open preferences",
        Callback = function()
            w:OpenProfile()
        end,
    })
    local configSection = settings:AddRightSection({ Name = "Configuration" })
    local json = configSection:AddInput({ Name = "JSON", Default = "", MaxLength = 1048576 })
    configSection:AddButton({
        Name = "Export",
        Callback = function()
            json:Set(w:ExportConfig() or "", true)
        end,
    })
    configSection:AddButton({
        Name = "Import",
        Callback = function()
            local ok = w:ImportConfig(json:Get())
            w:Notify({
                Title = ok and "Configuration imported" or "Invalid configuration",
                Type = ok and "Success" or "Error",
            })
        end,
    })
    local preview = w:AddCompanionWindow({
        Title = "Animation visualizer",
        Size = Vector2.new(280, 410),
        Side = "Left",
        Linked = true,
    })
    local mannequin = Instance.new("Model")
    mannequin.Name = "Mannequin"
    for _, part in
        {
            { "Head", Vector3.new(1, 1, 1), Vector3.new(0, 2.5, 0) },
            { "Torso", Vector3.new(2, 2, 1), Vector3.new(0, 1, 0) },
            { "Left arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 1, 0) },
            { "Right arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 1, 0) },
            { "Left leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -1, 0) },
            { "Right leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -1, 0) },
        }
    do
        UI.new("Part", mannequin, {
            Name = part[1],
            Size = part[2],
            Position = part[3],
            Anchored = true,
            Color = Color3.fromRGB(208, 209, 212),
            Material = Enum.Material.SmoothPlastic,
        })
    end
    local viewport =
        preview:AddViewport({ Model = options.Model or mannequin, Height = 270, Wireframe = true, Interactive = true })
    mannequin:Destroy()
    preview:AddMetadata({
        { Name = "Name", Value = options.Name or "Preview" },
        { Name = "Speed", Value = "0.00" },
        { Name = "ID", Value = "000000" },
        { Name = "Position", Value = "0.00 / 0.00" },
    })
    preview:AddActions({
        {
            Icon = "previous",
            Callback = function()
                viewport:SetRotation(viewport.Yaw - 0.25)
            end,
        },
        {
            Icon = "play",
            Callback = function()
                viewport:SetAutoRotate(not viewport.AutoRotate)
            end,
        },
        {
            Icon = "next",
            Callback = function()
                viewport:SetRotation(viewport.Yaw + 0.25)
            end,
        },
    })
    preview:AddProgressBar({ Name = "Progress", Default = 0.5, Compact = true })
    main:Select()
    local bounds = w.Root.AbsoluteSize
    local totalWidth = w.Frame.AbsoluteSize.X + preview.Size.X + 18
    if bounds.X >= totalWidth + 16 then
        w:SetPosition(
            UDim2.fromOffset(
                (bounds.X - totalWidth) / 2 + preview.Size.X + 18,
                math.max(32, (bounds.Y - w.Frame.AbsoluteSize.Y) / 2)
            )
        )
    end
    return w
end
-- Runnable pure-contract checks; no window or global input connections are created.
function Library:RunSelfTest()
    assert(UI.equal(UI.copy({ true, { 2, "x" } }), { true, { 2, "x" } }), "Copy/equality")
    assert(not UI.equal({ 1 }, { 1, 2 }), "Equality length")
    local values = {
        Enabled = true,
        Range = { 2, 8 },
        Color = Color3.fromRGB(21, 89, 176),
        Key = Enum.KeyCode.RightShift,
        Points = { Vector2.new(0, 1), Vector2.new(1, 0) },
    }
    local decoded = UI.decode(UI.S.Http:JSONDecode(UI.S.Http:JSONEncode(UI.encode(values))))
    assert(decoded.Enabled and decoded.Range[2] == 8 and decoded.Key == values.Key, "Config round trip")
    assert((decoded.Points[1] - values.Points[1]).Magnitude < 1e-6, "Vector2 round trip")
    assert(math.abs(decoded.Color.R - values.Color.R) < 1e-6, "Color round trip")
    local points = { Vector2.new(0, 1), Vector2.new(0, 0), Vector2.new(1, 1), Vector2.new(1, 0) }
    assert(UI.bezier(points, 0) == points[1] and UI.bezier(points, 1) == points[4], "Bezier endpoints")
    assert((UI.bezier(points, 0.5) - Vector2.new(0.5, 0.5)).Magnitude < 1e-6, "Bezier midpoint")
    local cycle = {}
    cycle.self = cycle
    assert(not pcall(UI.encode, cycle), "Cycle rejected")
    assert(not pcall(UI.decode, { __ui = "enum", enum = "Invalid", name = "Bad" }), "Enum rejected")
    assert(not pcall(UI.encode, 0 / 0), "NaN rejected")
    return true
end
-- Opt-in Roblox client integration check. This is not a screenshot/device-input test.
function Library:RunLifecycleTest(options)
    options = options or {}
    self:RunSelfTest()
    local id = "__UiLib_contract_test"
    local w = self:CreateWindow({ Id = id, Parent = options.Parent })
    local ok, reason = pcall(function()
        local tab = w:AddTab({ Name = "Contracts" })
        local s = tab:AddSection({ Name = "Values" })
        local calls = 0
        local toggle = s:AddToggle({
            Name = "Toggle",
            Flag = "Toggle",
            Default = false,
            Callback = function()
                calls += 1
            end,
        })
        toggle:Set(true)
        toggle:Set(true)
        assert(calls == 1, "Duplicate callback")
        toggle:Set(false, true)
        assert(calls == 1, "Silent Set fired callback")
        local slider =
            s:AddSlider({ Name = "Slider", Flag = "Slider", Min = 0, Max = 10, Increment = 0.5, Default = 1 })
        slider:Set(2.26)
        assert(slider:Get() == 2.5, "Slider snapping")
        local range = s:AddRangeSlider({ Name = "Range", Flag = "Range", Min = 0, Max = 10, Default = { 2, 8 } })
        assert(not range:Set({ 9, 1 }), "Crossed range accepted")
        local drop = s:AddDropdown({ Name = "Dropdown", Options = { "A", "B" }, Default = "A" })
        local picker = s:AddColorPicker({ Name = "Picker", Default = Color3.fromRGB(30, 90, 180), Flag = "Color" })
        s:AddCurveEditor({ Name = "Curve", Flag = "Curve" })
        for _ = 1, 10 do
            drop:Open()
            drop:Close()
            picker:Open()
            picker:Close()
        end
        local function count(t)
            local n = 0
            for _ in t do
                n += 1
            end
            return n
        end
        local controlCount = count(w.Controls)
        for _ = 1, 10 do
            w:OpenProfile()
            w:ClosePopups()
        end
        assert(count(w.Controls) == controlCount, "Popup control leak")
        assert(#w.Popups == 0, "Popup stack leak")
        local json = w:ExportConfig()
        assert(type(json) == "string", "Export is not JSON")
        assert(w:ImportConfig(json, true), "Config round trip failed")
        assert(
            not w:ImportConfig({ Version = 1, Flags = { Toggle = true, Slider = "invalid" } }),
            "Malformed config accepted"
        )
        assert(toggle:Get() == false, "Partial config mutation")
        w:SearchControls("Slider")
        assert(slider.Frame.Visible and not toggle.Frame.Visible, "Search filtering")
        w:SearchControls("")
        assert(toggle.Frame.Visible, "Search restoration")
        w:SetAccent(Color3.fromRGB(0, 210, 190), true)
        w:SetScale(1.25)
        w:SetCornerStyle(0.8)
        w:Hide()
        w:Show()
        local dialog = w:CreateDialog({ Title = "Test" })
        dialog:Destroy()
        w:Notify({ Title = "Test", Duration = 0 }):Destroy()
    end)
    w:Destroy()
    assert(self:GetWindow(id) == nil, "Window registry leak")
    if not ok then
        error(reason, 2)
    end
    return true
end
return Library
