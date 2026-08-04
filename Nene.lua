--!strict
--[[
    RosaUI.lua
    Production Roblox UI library inspired by the supplied dark coral desktop panel.

    Install as a ModuleScript and require it from a LocalScript.

    local RosaUI = require(path.To.RosaUI)
    local window = RosaUI.CreateWindow({
        Title = "Brand name",
        Subtitle = "The slogan, if there is one.",
        Accent = Color3.fromRGB(255, 87, 90),
        Keybind = Enum.KeyCode.RightShift,
    })

    RosaUI.CreateReferenceDemo() creates the complete screenshot-style demo.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")

type AnyObject = { [any]: any }

local Library = {}
Library.Version = "1.0.0"

local WindowMethods = {}
WindowMethods.__index = WindowMethods
local PageMethods = {}
PageMethods.__index = PageMethods
local TabMethods = {}
TabMethods.__index = TabMethods
local SectionMethods = {}
SectionMethods.__index = SectionMethods
local ComponentMethods = {}
ComponentMethods.__index = ComponentMethods

local Maid = {}
Maid.__index = Maid

function Maid.new(): AnyObject
    return setmetatable({ _tasks = {}, _destroyed = false }, Maid)
end

function Maid:Add(value: any): any
    if value == nil then
        return nil
    end
    if self._destroyed then
        local kind = typeof(value)
        if kind == "RBXScriptConnection" then
            (value :: RBXScriptConnection):Disconnect()
        elseif kind == "Instance" then
            (value :: Instance):Destroy()
        elseif kind == "function" then
            pcall(value)
        elseif kind == "thread" then
            pcall(task.cancel, value)
        elseif type(value) == "table" and type(value.Destroy) == "function" then
            pcall(function() value:Destroy() end)
        end
        return value
    end
    table.insert(self._tasks, value)
    return value
end

function Maid:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    for index = #self._tasks, 1, -1 do
        local value = self._tasks[index]
        self._tasks[index] = nil
        local kind = typeof(value)
        if kind == "RBXScriptConnection" then
            pcall(function() (value :: RBXScriptConnection):Disconnect() end)
        elseif kind == "Instance" then
            pcall(function() (value :: Instance):Destroy() end)
        elseif kind == "function" then
            pcall(value)
        elseif kind == "thread" then
            pcall(task.cancel, value)
        elseif type(value) == "table" and type(value.Destroy) == "function" then
            pcall(function() value:Destroy() end)
        end
    end
end

local THEME = table.freeze({
    Canvas = Color3.fromRGB(8, 8, 11),
    Shell = Color3.fromRGB(17, 16, 21),
    ShellRaised = Color3.fromRGB(21, 20, 26),
    Rail = Color3.fromRGB(15, 14, 19),
    Surface = Color3.fromRGB(23, 22, 29),
    SurfaceRaised = Color3.fromRGB(28, 27, 35),
    SurfaceHover = Color3.fromRGB(32, 31, 40),
    SurfacePressed = Color3.fromRGB(37, 35, 44),
    Control = Color3.fromRGB(35, 34, 44),
    ControlDark = Color3.fromRGB(27, 26, 34),
    Border = Color3.fromRGB(62, 59, 72),
    BorderStrong = Color3.fromRGB(82, 78, 92),
    Text = Color3.fromRGB(241, 239, 246),
    TextSecondary = Color3.fromRGB(177, 172, 190),
    TextMuted = Color3.fromRGB(111, 107, 122),
    TextDisabled = Color3.fromRGB(79, 76, 88),
    White = Color3.fromRGB(255, 255, 255),
    Shadow = Color3.fromRGB(0, 0, 0),
    Success = Color3.fromRGB(71, 201, 139),
    Warning = Color3.fromRGB(246, 184, 75),
    Error = Color3.fromRGB(242, 86, 99),
})

local BASE_WIDTH = 860
local BASE_HEIGHT = 520
local HEADER_HEIGHT = 70
local SIDEBAR_WIDTH = 64
local COLUMN_GAP = 14

local FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local NORMAL = TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local SLOW = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local activeTweens: { [Instance]: Tween } = setmetatable({}, { __mode = "k" }) :: any

local function tween(instance: Instance, info: TweenInfo, properties: AnyObject): Tween?
    if instance.Parent == nil then
        return nil
    end
    local old = activeTweens[instance]
    if old then
        pcall(function() old:Cancel() end)
    end
    local object = TweenService:Create(instance, info, properties)
    activeTweens[instance] = object
    local connection: RBXScriptConnection?
    connection = object.Completed:Connect(function()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        if activeTweens[instance] == object then
            activeTweens[instance] = nil
        end
        pcall(function() object:Destroy() end)
    end)
    object:Play()
    return object
end

local function new(className: string, properties: AnyObject?, children: { Instance }?): Instance
    local instance = Instance.new(className)
    local anyInstance = instance :: any
    local parent: Instance? = nil
    if properties then
        for key, value in pairs(properties) do
            if key == "Parent" then
                parent = value
            else
                anyInstance[key] = value
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

local function corner(parent: Instance, radius: number): UICorner
    return new("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent,
    }) :: UICorner
end

local function stroke(parent: Instance, color: Color3, transparency: number, thickness: number?): UIStroke
    return new("UIStroke", {
        Color = color,
        Transparency = transparency,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    }) :: UIStroke
end

local function padding(parent: Instance, left: number, right: number, top: number, bottom: number): UIPadding
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, left),
        PaddingRight = UDim.new(0, right),
        PaddingTop = UDim.new(0, top),
        PaddingBottom = UDim.new(0, bottom),
        Parent = parent,
    }) :: UIPadding
end

local function list(
    parent: Instance,
    direction: Enum.FillDirection,
    gap: number,
    horizontal: Enum.HorizontalAlignment?,
    vertical: Enum.VerticalAlignment?
): UIListLayout
    return new("UIListLayout", {
        FillDirection = direction,
        Padding = UDim.new(0, gap),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
        Parent = parent,
    }) :: UIListLayout
end

local function mix(a: Color3, b: Color3, amount: number): Color3
    local t = math.clamp(amount, 0, 1)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

local function contrastText(color: Color3): Color3
    local luminance = color.R * 0.2126 + color.G * 0.7152 + color.B * 0.0722
    return if luminance > 0.62 then Color3.fromRGB(24, 22, 28) else Color3.new(1, 1, 1)
end

local function invoke(callback: any, ...: any)
    if type(callback) ~= "function" then
        return
    end
    local arguments = table.pack(...)
    task.spawn(function()
        local ok, message = pcall(function()
            callback(table.unpack(arguments, 1, arguments.n))
        end)
        if not ok then
            warn("[RosaUI] callback error:", message)
        end
    end)
end

local function invokeLatest(owner: AnyObject, callback: any, ...: any)
    if type(callback) ~= "function" then
        return
    end

    owner._latestCallbackArguments = table.pack(...)
    if owner._callbackScheduled then
        return
    end

    owner._callbackScheduled = true
    task.defer(function()
        owner._callbackScheduled = false
        if owner._destroyed then
            owner._latestCallbackArguments = nil
            return
        end

        local arguments = owner._latestCallbackArguments
        owner._latestCallbackArguments = nil
        if not arguments then
            return
        end

        local ok, message = pcall(function()
            callback(table.unpack(arguments, 1, arguments.n))
        end)
        if not ok then
            warn("[RosaUI] callback error:", message)
        end
    end)
end

local function trim(value: string): string
    return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
end

local function lower(value: any): string
    return string.lower(tostring(value or ""))
end

local function imageSource(value: any): boolean
    if type(value) ~= "string" then
        return false
    end
    return string.sub(value, 1, 13) == "rbxassetid://"
        or string.sub(value, 1, 11) == "rbxasset://"
end

local function text(
    parent: Instance,
    value: string,
    size: number,
    color: Color3,
    font: Enum.Font?,
    properties: AnyObject?
): TextLabel
    local values: AnyObject = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = value,
        TextSize = size,
        TextColor3 = color,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = parent,
    }
    if properties then
        for key, propertyValue in pairs(properties) do
            values[key] = propertyValue
        end
    end
    return new("TextLabel", values) :: TextLabel
end

local function button(parent: Instance, properties: AnyObject?): TextButton
    local values: AnyObject = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Active = true,
        Selectable = true,
        Parent = parent,
    }
    if properties then
        for key, value in pairs(properties) do
            values[key] = value
        end
    end
    return new("TextButton", values) :: TextButton
end

local function icon(
    parent: Instance,
    value: any,
    color: Color3,
    size: UDim2,
    position: UDim2,
    zIndex: number
): GuiObject
    if imageSource(value) then
        return new("ImageLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = tostring(value),
            ImageColor3 = color,
            ScaleType = Enum.ScaleType.Fit,
            Size = size,
            Position = position,
            ZIndex = zIndex,
            Parent = parent,
        }) :: ImageLabel
    end
    return text(parent, tostring(value or "•"), 18, color, Enum.Font.GothamMedium, {
        Name = "Icon",
        Size = size,
        Position = position,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = zIndex,
    })
end

local function inside(gui: GuiObject, point: Vector2): boolean
    if not gui.Visible or gui.Parent == nil then
        return false
    end
    local p, s = gui.AbsolutePosition, gui.AbsoluteSize
    return point.X >= p.X and point.Y >= p.Y and point.X <= p.X + s.X and point.Y <= p.Y + s.Y
end

local function pointer(inputObject: InputObject?): Vector2
    if inputObject and inputObject.UserInputType == Enum.UserInputType.Touch then
        return Vector2.new(inputObject.Position.X, inputObject.Position.Y)
    end
    return UserInputService:GetMouseLocation()
end

local function textWidth(value: string, size: number, font: Enum.Font): number
    return TextService:GetTextSize(value, size, font, Vector2.new(1000, 100)).X
end

local function roundStep(value: number, step: number): number
    return if step <= 0 then value else math.floor(value / step + 0.5) * step
end

local function decimals(step: number): number
    local value = tostring(step)
    local point = string.find(value, ".", 1, true)
    return if point then math.clamp(#value - point, 0, 4) else 0
end

local function formatNumber(value: number, step: number, suffix: string?): string
    return string.format("%." .. tostring(decimals(step)) .. "f", value) .. (suffix or "")
end

local function rgbToHex(color: Color3): string
    return string.format("#%02X%02X%02X",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
    )
end

local function hexToColor(value: string): Color3?
    local normalized = string.gsub(trim(value), "#", "")
    if #normalized == 3 then
        normalized = string.sub(normalized, 1, 1) .. string.sub(normalized, 1, 1)
            .. string.sub(normalized, 2, 2) .. string.sub(normalized, 2, 2)
            .. string.sub(normalized, 3, 3) .. string.sub(normalized, 3, 3)
    end
    if #normalized ~= 6 or string.find(normalized, "[^%x]") then
        return nil
    end
    local r = tonumber(string.sub(normalized, 1, 2), 16)
    local g = tonumber(string.sub(normalized, 3, 4), 16)
    local b = tonumber(string.sub(normalized, 5, 6), 16)
    if not r or not g or not b then
        return nil
    end
    return Color3.fromRGB(r, g, b)
end

local function resolveParent(explicit: Instance?): Instance
    if explicit then
        return explicit
    end
    local player = Players.LocalPlayer
    if not player then
        error("[RosaUI] Run on the client or pass Config.Parent.")
    end
    return player:WaitForChild("PlayerGui")
end

local function copy(source: AnyObject): AnyObject
    local target: AnyObject = {}
    for key, value in pairs(source) do
        target[key] = value
    end
    return target
end

local function removeValue(array: { any }, value: any): boolean
    for index = #array, 1, -1 do
        if array[index] == value then
            table.remove(array, index)
            return true
        end
    end
    return false
end

function ComponentMethods:GetValue(): any
    return self._value
end

function ComponentMethods:SetVisible(visible: boolean)
    if self._root and self._root.Parent then
        self._root.Visible = visible
    end
end

function ComponentMethods:SetDisabled(disabled: boolean)
    self._disabled = disabled == true
    if self._render then
        self:_render(false)
    end
end

function ComponentMethods:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true

    local section = self._section
    if section then
        removeValue(section._components, self)
        removeValue(section._rows, self._root)
        for index = #section._searchRows, 1, -1 do
            if section._searchRows[index].Frame == self._root then
                table.remove(section._searchRows, index)
            end
        end
    end

    if self._window and self._window._activePopup
        and self._window._activePopup.Anchor == self._root
    then
        self._window:_closePopup()
    end

    self._maid:Destroy()
    if section and section._tab and not section._tab._destroyed then
        section._tab:_updateHeight()
    end
end

local function component(root: GuiObject, section: AnyObject): AnyObject
    local maid = Maid.new()
    maid:Add(root)
    local result: AnyObject = setmetatable({
        _root = root,
        Root = root,
        _section = section,
        _window = section._window,
        _maid = maid,
        _disabled = false,
        _destroyed = false,
    }, ComponentMethods)
    table.insert(section._components, result)
    section._maid:Add(result)
    return result
end

local function settingRow(
    section: AnyObject,
    titleValue: string,
    descriptionValue: string,
    height: number
): (TextButton, TextLabel, TextLabel, UIStroke)
    local window = section._window
    local row = button(section._content, {
        Name = "Setting_" .. string.gsub(titleValue, "%W+", "_"),
        BackgroundColor3 = window._theme.Surface,
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, height),
        LayoutOrder = #section._rows + 1,
        ZIndex = 20,
    })
    corner(row, 13)
    local edge = stroke(row, window._theme.Border, 0.72, 1)
    local titleLabel = text(row, titleValue, 13, window._theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(0.5, -30, 0, 22),
        Position = UDim2.fromOffset(14, 11),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 22,
    })
    local descriptionLabel = text(row, descriptionValue, 10, window._theme.TextMuted, Enum.Font.Gotham, {
        Size = UDim2.new(0.5, -30, 0, 30),
        Position = UDim2.fromOffset(14, 31),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 22,
    })

    local hover, press = false, false
    local function render()
        if row.Parent == nil then return end
        local color, transparency = window._theme.Surface, 0.72
        if press then
            color, transparency = window._theme.SurfacePressed, 0.42
        elseif hover then
            color, transparency = window._theme.SurfaceHover, 0.54
        elseif GuiService.SelectedObject == row then
            color, transparency = window._theme.SurfaceRaised, 0.34
        end
        tween(row, FAST, { BackgroundColor3 = color })
        tween(edge, FAST, { Transparency = transparency })
    end

    section._maid:Add(row.MouseEnter:Connect(function() hover = true; render() end))
    section._maid:Add(row.MouseLeave:Connect(function() hover = false; press = false; render() end))
    section._maid:Add(row.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch
        then
            press = true
            render()
        end
    end))
    section._maid:Add(row.InputEnded:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch
        then
            press = false
            render()
        end
    end))
    section._maid:Add(row.SelectionGained:Connect(render))
    section._maid:Add(row.SelectionLost:Connect(render))

    table.insert(section._rows, row)
    table.insert(section._searchRows, {
        Frame = row,
        Text = lower(titleValue .. " " .. descriptionValue),
    })
    return row, titleLabel, descriptionLabel, edge
end

local function controlBed(parent: Instance, window: AnyObject, width: number, height: number): Frame
    local frame = new("Frame", {
        BackgroundColor3 = window._theme.ControlDark,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(width, height),
        Parent = parent,
    }) :: Frame
    corner(frame, 9)
    stroke(frame, window._theme.Border, 0.72, 1)
    return frame
end

function WindowMethods:_bindAccent(ownerMaid: AnyObject, callback: (Color3) -> ())
    local binding = { Alive = true, Apply = callback }
    table.insert(self._accentBindings, binding)
    ownerMaid:Add(function() binding.Alive = false end)
    callback(self._accent)
end

function WindowMethods:SetAccent(color: Color3)
    if typeof(color) ~= "Color3" then
        return
    end
    self._accent = color
    self.Accent = color
    local live = {}
    for _, binding in ipairs(self._accentBindings) do
        if binding.Alive then
            table.insert(live, binding)
            local ok, message = pcall(binding.Apply, color)
            if not ok then warn("[RosaUI] accent binding error:", message) end
        end
    end
    self._accentBindings = live
end

function WindowMethods:GetAccent(): Color3
    return self._accent
end

function WindowMethods:_closePopup()
    local popup = self._activePopup
    if not popup then
        return
    end
    self._activePopup = nil
    if popup.Close then
        popup:Close()
    elseif popup.Maid then
        popup.Maid:Destroy()
    end
end

function WindowMethods:_positionPopover(frame: GuiObject, anchor: GuiObject, width: number)
    if frame.Parent == nil or anchor.Parent == nil then
        return
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local anchorPosition, anchorSize = anchor.AbsolutePosition, anchor.AbsoluteSize
    local frameSize = frame.AbsoluteSize
    local x = anchorPosition.X + anchorSize.X - width
    local y = anchorPosition.Y + anchorSize.Y + 8

    if y + frameSize.Y > viewport.Y - 10 then
        y = anchorPosition.Y - frameSize.Y - 8
    end

    x = math.clamp(x, 10, math.max(10, viewport.X - frameSize.X - 10))
    y = math.clamp(y, 10, math.max(10, viewport.Y - frameSize.Y - 10))
    frame.Position = UDim2.fromOffset(x, y)
end

function WindowMethods:_openDropdown(control: AnyObject)
    self:_closePopup()
    local popupMaid = Maid.new()
    local options = control._options
    local count = math.min(#options, 6)
    local popupHeight = math.max(52, count * 36 + 18)

    local popup = new("CanvasGroup", {
        Name = "DropdownPopover",
        BackgroundColor3 = self._theme.ShellRaised,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(238, popupHeight),
        GroupTransparency = 1,
        ZIndex = 300,
        Parent = self._overlay,
    }) :: CanvasGroup
    corner(popup, 14)
    stroke(popup, self._theme.BorderStrong, 0.34, 1)
    popupMaid:Add(popup)

    local shadow = new("Frame", {
        BackgroundColor3 = self._theme.Shadow,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 12, 1, 14),
        Position = UDim2.fromOffset(-6, 7),
        ZIndex = 299,
        Parent = popup,
    }) :: Frame
    corner(shadow, 17)

    local scroll = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -12, 1, -12),
        Position = UDim2.fromOffset(6, 6),
        CanvasSize = UDim2.fromOffset(0, #options * 36),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self._theme.BorderStrong,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 302,
        Parent = popup,
    }) :: ScrollingFrame
    local layout = list(scroll, Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Center)
    padding(scroll, 2, 2, 2, 2)

    local function selected(option: any): boolean
        return if control._multi
            then control._value[tostring(option)] == true
            else control._value == option
    end

    for index, option in ipairs(options) do
        local optionButton = button(scroll, {
            Name = "Option_" .. tostring(index),
            BackgroundColor3 = self._theme.Surface,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, 32),
            LayoutOrder = index,
            ZIndex = 304,
        })
        corner(optionButton, 8)
        local marker = new("Frame", {
            BackgroundColor3 = self._accent,
            BackgroundTransparency = selected(option) and 0 or 1,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(4, 18),
            Position = UDim2.new(0, 7, 0.5, -9),
            ZIndex = 306,
            Parent = optionButton,
        }) :: Frame
        corner(marker, 2)
        local label = text(optionButton, tostring(option), 12,
            selected(option) and self._theme.Text or self._theme.TextSecondary,
            Enum.Font.GothamMedium, {
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.fromOffset(20, 0),
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 306,
            })
        local check = text(optionButton, selected(option) and "✓" or "", 13, self._accent,
            Enum.Font.GothamBold, {
                Size = UDim2.fromOffset(24, 24),
                Position = UDim2.new(1, -30, 0.5, -12),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 306,
            })

        popupMaid:Add(optionButton.MouseEnter:Connect(function()
            tween(optionButton, FAST, {
                BackgroundTransparency = 0,
                BackgroundColor3 = self._theme.SurfaceHover,
            })
        end))
        popupMaid:Add(optionButton.MouseLeave:Connect(function()
            tween(optionButton, FAST, { BackgroundTransparency = 1 })
        end))
        popupMaid:Add(optionButton.Activated:Connect(function()
            control:_selectOption(option)
            local isSelected = selected(option)
            tween(marker, FAST, {
                BackgroundTransparency = isSelected and 0 or 1,
                BackgroundColor3 = self._accent,
            })
            check.Text = isSelected and "✓" or ""
            label.TextColor3 = isSelected and self._theme.Text or self._theme.TextSecondary
            if not control._multi then
                self:_closePopup()
            end
        end))
    end

    scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
    popup.Position = UDim2.fromOffset(
        control._root.AbsolutePosition.X,
        control._root.AbsolutePosition.Y + control._root.AbsoluteSize.Y + 8
    )
    self:_positionPopover(popup, control._root, 238)

    local object: AnyObject = {
        Frame = popup,
        Anchor = control._root,
        Maid = popupMaid,
        _closed = false,
    }
    function object:Close()
        if self._closed then return end
        self._closed = true
        local closing = tween(popup, FAST, {
            GroupTransparency = 1,
            Position = popup.Position + UDim2.fromOffset(0, -4),
        })
        if closing then
            popupMaid:Add(closing.Completed:Connect(function() popupMaid:Destroy() end))
        else
            popupMaid:Destroy()
        end
    end

    self._activePopup = object
    tween(popup, NORMAL, {
        GroupTransparency = 0,
        Position = popup.Position + UDim2.fromOffset(0, 2),
    })
end

function WindowMethods:_openColorPicker(control: AnyObject)
    self:_closePopup()
    local popupMaid = Maid.new()
    local popup = new("CanvasGroup", {
        Name = "ColorPickerPopover",
        BackgroundColor3 = self._theme.ShellRaised,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(244, 294),
        GroupTransparency = 1,
        ZIndex = 320,
        Parent = self._overlay,
    }) :: CanvasGroup
    corner(popup, 18)
    stroke(popup, self._theme.BorderStrong, 0.25, 1)
    popupMaid:Add(popup)

    local shadow = new("Frame", {
        BackgroundColor3 = self._theme.Shadow,
        BackgroundTransparency = 0.52,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-7, 9),
        Size = UDim2.new(1, 14, 1, 16),
        ZIndex = 319,
        Parent = popup,
    }) :: Frame
    corner(shadow, 21)

    local current: Color3 = control._value
    local hue, saturation, value = current:ToHSV()
    local transparency = control._transparency or 0
    local dragMode: string? = nil
    local activeTouch: InputObject? = nil

    local sv = new("Frame", {
        BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(212, 156),
        Position = UDim2.fromOffset(16, 16),
        Active = true,
        ZIndex = 324,
        Parent = popup,
    }) :: Frame
    corner(sv, 10)
    stroke(sv, self._theme.White, 0.82, 1)

    local whiteLayer = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 325,
        Parent = sv,
    }) :: Frame
    corner(whiteLayer, 10)
    new("UIGradient", {
        Color = ColorSequence.new(Color3.new(1, 1, 1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = whiteLayer,
    })

    local blackLayer = new("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 326,
        Parent = sv,
    }) :: Frame
    corner(blackLayer, 10)
    new("UIGradient", {
        Color = ColorSequence.new(Color3.new(0, 0, 0)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90,
        Parent = blackLayer,
    })

    local svMarker = new("Frame", {
        BackgroundColor3 = current,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(13, 13),
        Position = UDim2.fromScale(saturation, 1 - value),
        ZIndex = 330,
        Parent = sv,
    }) :: Frame
    corner(svMarker, 7)
    stroke(svMarker, Color3.new(1, 1, 1), 0, 2)

    local hueBar = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(212, 12),
        Position = UDim2.fromOffset(16, 184),
        Active = true,
        ZIndex = 324,
        Parent = popup,
    }) :: Frame
    corner(hueBar, 6)
    stroke(hueBar, self._theme.White, 0.86, 1)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0.00, 1, 1)),
            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
            ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
            ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1.00, 1, 1)),
        }),
        Parent = hueBar,
    })
    local hueMarker = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(5, 18),
        Position = UDim2.fromScale(hue, 0.5),
        ZIndex = 329,
        Parent = hueBar,
    }) :: Frame
    corner(hueMarker, 3)
    stroke(hueMarker, Color3.fromRGB(25, 25, 30), 0.2, 1)

    local alphaBar = new("Frame", {
        BackgroundColor3 = self._theme.ControlDark,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(212, 12),
        Position = UDim2.fromOffset(16, 205),
        Active = true,
        ClipsDescendants = true,
        ZIndex = 324,
        Parent = popup,
    }) :: Frame
    corner(alphaBar, 6)
    stroke(alphaBar, self._theme.White, 0.86, 1)

    for index = 0, 15 do
        new("Frame", {
            BackgroundColor3 = if index % 2 == 0
                then Color3.fromRGB(229, 229, 234)
                else Color3.fromRGB(174, 174, 183),
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(14, 12),
            Position = UDim2.fromOffset(index * 14, 0),
            ZIndex = 324,
            Parent = alphaBar,
        })
    end

    local alphaOverlay = new("Frame", {
        BackgroundColor3 = current,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 326,
        Parent = alphaBar,
    }) :: Frame
    corner(alphaOverlay, 6)
    local alphaGradient = new("UIGradient", {
        Color = ColorSequence.new(current),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Parent = alphaOverlay,
    }) :: UIGradient
    local alphaMarker = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(5, 18),
        Position = UDim2.fromScale(1 - transparency, 0.5),
        ZIndex = 329,
        Parent = alphaBar,
    }) :: Frame
    corner(alphaMarker, 3)
    stroke(alphaMarker, Color3.fromRGB(25, 25, 30), 0.2, 1)

    local hexBox = new("TextBox", {
        BackgroundColor3 = self._theme.ControlDark,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Text = rgbToHex(current),
        PlaceholderText = "#FF575A",
        PlaceholderColor3 = self._theme.TextMuted,
        TextColor3 = self._theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromOffset(98, 34),
        Position = UDim2.fromOffset(16, 229),
        ZIndex = 325,
        Parent = popup,
    }) :: TextBox
    corner(hexBox, 9)
    stroke(hexBox, self._theme.Border, 0.58, 1)

    local alphaLabel = text(popup,
        tostring(math.floor((1 - transparency) * 100 + 0.5)) .. "%",
        11, self._theme.TextSecondary, Enum.Font.GothamMedium, {
            BackgroundColor3 = self._theme.ControlDark,
            BackgroundTransparency = 0,
            Size = UDim2.fromOffset(58, 34),
            Position = UDim2.fromOffset(120, 229),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 325,
        })
    corner(alphaLabel, 9)
    stroke(alphaLabel, self._theme.Border, 0.58, 1)

    local close = button(popup, {
        BackgroundColor3 = self._theme.ControlDark,
        BackgroundTransparency = 0,
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.fromOffset(194, 229),
        ZIndex = 326,
    })
    corner(close, 17)
    stroke(close, self._theme.Border, 0.45, 1)
    text(close, "×", 18, self._theme.TextSecondary, Enum.Font.GothamMedium, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 327,
    })

    local swatchHost = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(212, 22),
        Position = UDim2.fromOffset(16, 268),
        ZIndex = 324,
        Parent = popup,
    }) :: Frame
    list(swatchHost, Enum.FillDirection.Horizontal, 9,
        Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local swatches = control._swatches or {
        Color3.fromRGB(255, 87, 90),
        Color3.fromRGB(255, 107, 116),
        Color3.fromRGB(255, 128, 138),
        Color3.fromRGB(245, 148, 160),
    }

    local function update(fireCallback: boolean)
        current = Color3.fromHSV(hue, saturation, value)
        sv.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        svMarker.Position = UDim2.fromScale(saturation, 1 - value)
        svMarker.BackgroundColor3 = current
        hueMarker.Position = UDim2.fromScale(hue, 0.5)
        alphaOverlay.BackgroundColor3 = current
        alphaGradient.Color = ColorSequence.new(current)
        alphaMarker.Position = UDim2.fromScale(1 - transparency, 0.5)
        hexBox.Text = rgbToHex(current)
        alphaLabel.Text = tostring(math.floor((1 - transparency) * 100 + 0.5)) .. "%"
        control:SetValue(current, transparency, not fireCallback)
    end

    for index, swatchColor in ipairs(swatches) do
        local swatch = button(swatchHost, {
            BackgroundColor3 = swatchColor,
            BackgroundTransparency = 0,
            Size = UDim2.fromOffset(24, 24),
            LayoutOrder = index,
            ZIndex = 326,
        })
        corner(swatch, 12)
        stroke(swatch, self._theme.White, 0.28, 1)
        popupMaid:Add(swatch.Activated:Connect(function()
            hue, saturation, value = swatchColor:ToHSV()
            update(true)
        end))
    end

    local function applySV(point: Vector2)
        local relative = point - sv.AbsolutePosition
        saturation = math.clamp(relative.X / math.max(1, sv.AbsoluteSize.X), 0, 1)
        value = 1 - math.clamp(relative.Y / math.max(1, sv.AbsoluteSize.Y), 0, 1)
        update(true)
    end
    local function applyHue(point: Vector2)
        hue = math.clamp((point.X - hueBar.AbsolutePosition.X) / math.max(1, hueBar.AbsoluteSize.X), 0, 1)
        update(true)
    end
    local function applyAlpha(point: Vector2)
        local opacity = math.clamp((point.X - alphaBar.AbsolutePosition.X) / math.max(1, alphaBar.AbsoluteSize.X), 0, 1)
        transparency = 1 - opacity
        update(true)
    end
    local function begin(mode: string, inputObject: InputObject)
        if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1
            and inputObject.UserInputType ~= Enum.UserInputType.Touch
        then return end
        dragMode = mode
        activeTouch = if inputObject.UserInputType == Enum.UserInputType.Touch then inputObject else nil
        local point = pointer(inputObject)
        if mode == "sv" then applySV(point)
        elseif mode == "hue" then applyHue(point)
        else applyAlpha(point) end
    end

    popupMaid:Add(sv.InputBegan:Connect(function(i) begin("sv", i) end))
    popupMaid:Add(hueBar.InputBegan:Connect(function(i) begin("hue", i) end))
    popupMaid:Add(alphaBar.InputBegan:Connect(function(i) begin("alpha", i) end))
    popupMaid:Add(UserInputService.InputChanged:Connect(function(inputObject)
        if not dragMode then return end
        if activeTouch then
            if inputObject ~= activeTouch then return end
        elseif inputObject.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        local point = pointer(inputObject)
        if dragMode == "sv" then applySV(point)
        elseif dragMode == "hue" then applyHue(point)
        else applyAlpha(point) end
    end))
    popupMaid:Add(UserInputService.InputEnded:Connect(function(inputObject)
        if activeTouch and inputObject ~= activeTouch then return end
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch
        then
            dragMode, activeTouch = nil, nil
        end
    end))
    popupMaid:Add(hexBox.FocusLost:Connect(function()
        local parsed = hexToColor(hexBox.Text)
        if parsed then
            hue, saturation, value = parsed:ToHSV()
            update(true)
        else
            hexBox.Text = rgbToHex(current)
        end
    end))

    local object: AnyObject = {
        Frame = popup,
        Anchor = control._root,
        Maid = popupMaid,
        _closed = false,
    }
    function object:Close()
        if self._closed then return end
        self._closed = true
        local closing = tween(popup, FAST, {
            GroupTransparency = 1,
            Position = popup.Position + UDim2.fromOffset(0, -5),
        })
        if closing then
            popupMaid:Add(closing.Completed:Connect(function() popupMaid:Destroy() end))
        else
            popupMaid:Destroy()
        end
    end

    popupMaid:Add(close.Activated:Connect(function() self:_closePopup() end))
    self._activePopup = object
    popup.Position = UDim2.fromOffset(
        control._root.AbsolutePosition.X,
        control._root.AbsolutePosition.Y + control._root.AbsoluteSize.Y + 8
    )
    self:_positionPopover(popup, control._root, 244)
    tween(popup, NORMAL, {
        GroupTransparency = 0,
        Position = popup.Position + UDim2.fromOffset(0, 2),
    })
end

function WindowMethods:_setCompact(compact: boolean)
    if self._compact == compact then
        return
    end
    self._compact = compact
    self._subtitle.Visible = not compact
    self._statusGroup.Visible = not compact
    for _, page in ipairs(self._pages) do
        for _, tab in ipairs(page._tabs) do
            tab:_setCompact(compact)
        end
    end
end

function WindowMethods:_clampWindowPosition()
    if not self._shell or self._shell.Parent == nil then
        return
    end
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local size = self._shell.AbsoluteSize
    local position = self._shell.Position
    self._shell.Position = UDim2.fromOffset(
        math.clamp(position.X.Offset, 8, math.max(8, viewport.X - size.X - 8)),
        math.clamp(position.Y.Offset, 8, math.max(8, viewport.Y - size.Y - 8))
    )
    self._basePosition = self._shell.Position
end

function WindowMethods:_updateResponsive(forceCenter: boolean?)
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local viewport = camera.ViewportSize
    local width = math.max(280, math.min(BASE_WIDTH, viewport.X - 18))
    local height = math.max(280, math.min(BASE_HEIGHT, viewport.Y - 18))

    self._scale.Scale = 1
    self._shell.Size = UDim2.fromOffset(width, height)
    self:_setCompact(width < 710)

    if forceCenter or not self._positionInitialized then
        self._shell.Position = UDim2.fromOffset(
            math.floor((viewport.X - width) * 0.5),
            math.floor((viewport.Y - height) * 0.5)
        )
        self._basePosition = self._shell.Position
        self._positionInitialized = true
    else
        task.defer(function()
            self:_clampWindowPosition()
        end)
    end
end

function WindowMethods:SetVisible(visible: boolean)
    if self._destroyed then return end
    visible = visible == true
    if self._visible == visible then return end
    self._visible = visible

    local basePosition = self._basePosition or self._shell.Position

    if visible then
        self._shell.Visible = true
        self._shell.GroupTransparency = 1
        self._shell.Position = basePosition + UDim2.fromOffset(0, 8)
        tween(self._shell, SLOW, {
            GroupTransparency = 0,
            Position = basePosition,
        })
    else
        self:_closePopup()
        local closing = tween(self._shell, NORMAL, {
            GroupTransparency = 1,
            Position = basePosition + UDim2.fromOffset(0, 6),
        })
        if closing then
            local completed: RBXScriptConnection?
            completed = closing.Completed:Connect(function(state)
                if completed then
                    completed:Disconnect()
                    completed = nil
                end
                if state == Enum.PlaybackState.Completed and not self._visible then
                    self._shell.Visible = false
                    self._shell.Position = basePosition
                end
            end)
        else
            self._shell.Visible = false
            self._shell.Position = basePosition
        end
    end
end

function WindowMethods:Toggle()
    self:SetVisible(not self._visible)
end

function WindowMethods:IsVisible(): boolean
    return self._visible == true
end

function WindowMethods:SetKeybind(keyCode: Enum.KeyCode)
    if typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode then
        self._keybind = keyCode
        self.Keybind = keyCode
    end
end

function WindowMethods:AddPage(config: AnyObject?): AnyObject
    config = config or {}
    local name = tostring(config.Name or config.Title or ("Page " .. tostring(#self._pages + 1)))
    local pageMaid = Maid.new()
    self._maid:Add(pageMaid)

    local navButton = button(self._navList, {
        Name = "Nav_" .. string.gsub(name, "%W+", "_"),
        BackgroundColor3 = self._theme.SurfaceRaised,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(44, 44),
        LayoutOrder = #self._pages + 1,
        ZIndex = 25,
    })
    corner(navButton, 12)
    pageMaid:Add(navButton)

    local navIcon = icon(navButton, config.Icon or "•", self._theme.TextMuted,
        UDim2.fromOffset(22, 22), UDim2.new(0.5, -11, 0.5, -11), 27)
    local activeMarker = new("Frame", {
        BackgroundColor3 = self._accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(4, 18),
        Position = UDim2.new(0, -9, 0.5, -9),
        ZIndex = 28,
        Parent = navButton,
    }) :: Frame
    corner(activeMarker, 2)

    local pageFrame = new("Frame", {
        Name = "Page_" .. string.gsub(name, "%W+", "_"),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 15,
        Parent = self._pageHost,
    }) :: Frame
    pageMaid:Add(pageFrame)

    local tabsArea = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 54),
        ZIndex = 18,
        Parent = pageFrame,
    }) :: Frame
    local tabsScroll = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(18, 8),
        Size = UDim2.new(1, -76, 0, 38),
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ZIndex = 20,
        Parent = tabsArea,
    }) :: ScrollingFrame
    local tabsLayout = list(tabsScroll, Enum.FillDirection.Horizontal, 7,
        Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local searchButton = button(tabsArea, {
        BackgroundColor3 = self._theme.Surface,
        BackgroundTransparency = 0.2,
        Size = UDim2.fromOffset(36, 36),
        Position = UDim2.new(1, -49, 0, 9),
        ZIndex = 24,
    })
    corner(searchButton, 12)
    stroke(searchButton, self._theme.Border, 0.74, 1)
    text(searchButton, "⌕", 20, self._theme.TextSecondary, Enum.Font.GothamMedium, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 26,
    })

    local searchFrame = new("Frame", {
        BackgroundColor3 = self._theme.SurfaceRaised,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(18, 8),
        Size = UDim2.new(1, -67, 0, 38),
        Visible = false,
        ZIndex = 30,
        Parent = tabsArea,
    }) :: Frame
    corner(searchFrame, 12)
    stroke(searchFrame, self._theme.BorderStrong, 0.5, 1)
    text(searchFrame, "⌕", 18, self._theme.TextMuted, Enum.Font.GothamMedium, {
        Size = UDim2.fromOffset(32, 38),
        Position = UDim2.fromOffset(4, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 32,
    })
    local searchBox = new("TextBox", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        PlaceholderText = "Search controls…",
        PlaceholderColor3 = self._theme.TextMuted,
        Text = "",
        TextColor3 = self._theme.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -78, 1, 0),
        Position = UDim2.fromOffset(38, 0),
        ZIndex = 32,
        Parent = searchFrame,
    }) :: TextBox
    local closeSearch = button(searchFrame, {
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -35, 0.5, -16),
        ZIndex = 33,
    })
    text(closeSearch, "×", 16, self._theme.TextSecondary, Enum.Font.GothamMedium, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 34,
    })

    local tabHost = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 54),
        Size = UDim2.new(1, 0, 1, -54),
        ClipsDescendants = true,
        ZIndex = 16,
        Parent = pageFrame,
    }) :: Frame

    local page: AnyObject = setmetatable({
        _window = self,
        _maid = pageMaid,
        _name = name,
        _navButton = navButton,
        _navIcon = navIcon,
        _activeMarker = activeMarker,
        _frame = pageFrame,
        _tabsScroll = tabsScroll,
        _tabsLayout = tabsLayout,
        _tabHost = tabHost,
        _searchFrame = searchFrame,
        _searchBox = searchBox,
        _tabs = {},
        _activeTab = nil,
        _selected = false,
        _destroyed = false,
        Name = name,
        Root = pageFrame,
    }, PageMethods)
    table.insert(self._pages, page)
    self._maid:Add(page)

    local function renderNav()
        local selected = page._selected
        tween(navButton, NORMAL, {
            BackgroundTransparency = selected and 0 or 1,
            BackgroundColor3 = selected and self._theme.SurfaceRaised or self._theme.Surface,
        })
        tween(activeMarker, NORMAL, { BackgroundTransparency = selected and 0 or 1 })
        if navIcon:IsA("ImageLabel") then
            tween(navIcon, NORMAL, {
                ImageColor3 = selected and self._theme.Text or self._theme.TextMuted,
            })
        else
            tween(navIcon, NORMAL, {
                TextColor3 = selected and self._theme.Text or self._theme.TextMuted,
            })
        end
    end

    pageMaid:Add(navButton.MouseEnter:Connect(function()
        if not page._selected then
            tween(navButton, FAST, {
                BackgroundTransparency = 0.35,
                BackgroundColor3 = self._theme.SurfaceHover,
            })
        end
    end))
    pageMaid:Add(navButton.MouseLeave:Connect(renderNav))
    pageMaid:Add(navButton.Activated:Connect(function() self:SelectPage(page) end))
    pageMaid:Add(searchButton.MouseEnter:Connect(function()
        tween(searchButton, FAST, {
            BackgroundColor3 = self._theme.SurfaceHover,
            BackgroundTransparency = 0,
        })
    end))
    pageMaid:Add(searchButton.MouseLeave:Connect(function()
        tween(searchButton, FAST, {
            BackgroundColor3 = self._theme.Surface,
            BackgroundTransparency = 0.2,
        })
    end))

    local function closeSearchField()
        searchFrame.Visible = false
        searchBox:ReleaseFocus()
        searchBox.Text = ""
    end
    pageMaid:Add(searchButton.Activated:Connect(function()
        searchFrame.Visible = true
        searchBox:CaptureFocus()
    end))
    pageMaid:Add(closeSearch.Activated:Connect(closeSearchField))
    pageMaid:Add(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if page._activeTab then
            page._activeTab:_applySearch(searchBox.Text)
        end
    end))
    pageMaid:Add(searchBox.InputBegan:Connect(function(inputObject)
        if inputObject.KeyCode == Enum.KeyCode.Escape then
            closeSearchField()
        end
    end))
    self:_bindAccent(pageMaid, function(accent)
        activeMarker.BackgroundColor3 = accent
        renderNav()
    end)
    renderNav()

    if #self._pages == 1 then
        self:SelectPage(page)
    end
    return page
end

function WindowMethods:SelectPage(pageOrName: any)
    local target: AnyObject? = nil
    if type(pageOrName) == "table" then
        target = pageOrName
    else
        for _, page in ipairs(self._pages) do
            if page._name == tostring(pageOrName) then
                target = page
                break
            end
        end
    end
    if not target or target._destroyed or self._activePage == target then
        return
    end
    self:_closePopup()
    for _, page in ipairs(self._pages) do
        local selected = page == target
        page._selected = selected
        page._frame.Visible = selected
        page._navButton.BackgroundTransparency = selected and 0 or 1
        page._navButton.BackgroundColor3 = selected and self._theme.SurfaceRaised or self._theme.Surface
        page._activeMarker.BackgroundTransparency = selected and 0 or 1
        if page._navIcon:IsA("ImageLabel") then
            page._navIcon.ImageColor3 = selected and self._theme.Text or self._theme.TextMuted
        else
            page._navIcon.TextColor3 = selected and self._theme.Text or self._theme.TextMuted
        end
    end
    self._activePage = target
end

function PageMethods:AddTab(config: AnyObject?): AnyObject
    config = config or {}
    local name = tostring(config.Name or config.Title or ("Tab " .. tostring(#self._tabs + 1)))
    local tabMaid = Maid.new()
    self._maid:Add(tabMaid)

    local width = math.clamp(math.floor(textWidth(name, 11, Enum.Font.GothamMedium) + 46), 82, 150)
    local tabButton = button(self._tabsScroll, {
        Name = "Tab_" .. string.gsub(name, "%W+", "_"),
        BackgroundColor3 = self._window._theme.SurfaceRaised,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(width, 36),
        LayoutOrder = #self._tabs + 1,
        ZIndex = 22,
    })
    corner(tabButton, 11)
    local tabStroke = stroke(tabButton, self._window._theme.Border, 1, 1)
    local tabIcon = icon(tabButton, config.Icon or "◉", self._window._theme.TextMuted,
        UDim2.fromOffset(18, 18), UDim2.fromOffset(12, 9), 24)
    local label = text(tabButton, name, 11, self._window._theme.TextMuted, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -38, 1, 0),
        Position = UDim2.fromOffset(34, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 24,
    })

    local tabFrame = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 18,
        Parent = self._tabHost,
    }) :: Frame
    tabMaid:Add(tabFrame)

    local scroll = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(16, 4),
        Size = UDim2.new(1, -25, 1, -10),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self._window._theme.BorderStrong,
        ScrollBarImageTransparency = 0.28,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
        ZIndex = 18,
        Parent = tabFrame,
    }) :: ScrollingFrame

    local content = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 0),
        ZIndex = 18,
        Parent = scroll,
    }) :: Frame

    local left = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0.5, -(COLUMN_GAP / 2), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 18,
        Parent = content,
    }) :: Frame
    local leftLayout = list(left, Enum.FillDirection.Vertical, 16,
        Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

    local right = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0.5, -(COLUMN_GAP / 2), 0, 0),
        Position = UDim2.new(0.5, COLUMN_GAP / 2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 18,
        Parent = content,
    }) :: Frame
    local rightLayout = list(right, Enum.FillDirection.Vertical, 16,
        Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

    local single = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 18,
        Parent = content,
    }) :: Frame
    local singleLayout = list(single, Enum.FillDirection.Vertical, 16,
        Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

    local tab: AnyObject = setmetatable({
        _window = self._window,
        _page = self,
        _maid = tabMaid,
        _name = name,
        _button = tabButton,
        _buttonStroke = tabStroke,
        _icon = tabIcon,
        _label = label,
        _frame = tabFrame,
        _scroll = scroll,
        _content = content,
        _leftColumn = left,
        _rightColumn = right,
        _singleColumn = single,
        _leftLayout = leftLayout,
        _rightLayout = rightLayout,
        _singleLayout = singleLayout,
        _sections = {},
        _selected = false,
        _compact = false,
        _destroyed = false,
        Name = name,
        Root = tabFrame,
    }, TabMethods)
    table.insert(self._tabs, tab)
    self._maid:Add(tab)

    local function render()
        local selected = tab._selected
        tween(tabButton, NORMAL, {
            BackgroundTransparency = selected and 0 or 1,
            BackgroundColor3 = selected and self._window._theme.SurfaceRaised
                or self._window._theme.Surface,
        })
        tween(tabStroke, NORMAL, { Transparency = selected and 0.7 or 1 })
        label.TextColor3 = selected and self._window._theme.Text or self._window._theme.TextMuted
        if tabIcon:IsA("ImageLabel") then
            tabIcon.ImageColor3 = selected and self._window._theme.Text or self._window._theme.TextMuted
        else
            tabIcon.TextColor3 = selected and self._window._theme.Text or self._window._theme.TextMuted
        end
    end

    tabMaid:Add(tabButton.MouseEnter:Connect(function()
        if not tab._selected then
            tween(tabButton, FAST, {
                BackgroundTransparency = 0.45,
                BackgroundColor3 = self._window._theme.SurfaceHover,
            })
        end
    end))
    tabMaid:Add(tabButton.MouseLeave:Connect(render))
    tabMaid:Add(tabButton.Activated:Connect(function() self:SelectTab(tab) end))

    local function updateHeight()
        task.defer(function()
            if tab._destroyed or content.Parent == nil then return end
            local height = if tab._compact
                then singleLayout.AbsoluteContentSize.Y
                else math.max(leftLayout.AbsoluteContentSize.Y, rightLayout.AbsoluteContentSize.Y)
            content.Size = UDim2.new(1, -8, 0, math.max(0, height + 10))
            scroll.CanvasSize = UDim2.fromOffset(0, math.max(0, height + 12))
        end)
    end
    tab._updateHeight = updateHeight

    tabMaid:Add(leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight))
    tabMaid:Add(rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight))
    tabMaid:Add(singleLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight))
    tabMaid:Add(content:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateHeight))
    self._window:_bindAccent(tabMaid, function() render() end)

    render()
    tab:_setCompact(self._window._compact)
    if #self._tabs == 1 then
        self:SelectTab(tab)
    end
    return tab
end

function PageMethods:SelectTab(tabOrName: any)
    local target: AnyObject? = nil
    if type(tabOrName) == "table" then
        target = tabOrName
    else
        for _, tab in ipairs(self._tabs) do
            if tab._name == tostring(tabOrName) then
                target = tab
                break
            end
        end
    end
    if not target or target._destroyed or self._activeTab == target then
        return
    end
    self._window:_closePopup()
    for _, tab in ipairs(self._tabs) do
        local selected = tab == target
        tab._selected = selected
        tab._frame.Visible = selected
        tab._button.BackgroundTransparency = selected and 0 or 1
        tab._button.BackgroundColor3 = selected and self._window._theme.SurfaceRaised
            or self._window._theme.Surface
        tab._buttonStroke.Transparency = selected and 0.7 or 1
        tab._label.TextColor3 = selected and self._window._theme.Text
            or self._window._theme.TextMuted
        if tab._icon:IsA("ImageLabel") then
            tab._icon.ImageColor3 = selected and self._window._theme.Text
                or self._window._theme.TextMuted
        else
            tab._icon.TextColor3 = selected and self._window._theme.Text
                or self._window._theme.TextMuted
        end
    end
    self._activeTab = target
    target:_applySearch(self._searchBox.Text)
    target:_updateHeight()
end

function PageMethods:AddSection(config: AnyObject?): AnyObject
    if #self._tabs == 0 then
        self:AddTab({ Name = "Overview", Icon = "◉" })
    end
    return self._tabs[1]:AddSection(config)
end

function PageMethods:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    local window = self._window
    removeValue(window._pages, self)
    local wasActive = window._activePage == self
    if wasActive then
        window._activePage = nil
    end

    self._maid:Destroy()

    if wasActive and not window._destroyed then
        for _, candidate in ipairs(window._pages) do
            if not candidate._destroyed then
                window:SelectPage(candidate)
                break
            end
        end
    end
end

function TabMethods:_setCompact(compact: boolean)
    compact = compact == true
    if self._compact == compact and #self._sections > 0 then
        self:_updateHeight()
        return
    end
    self._compact = compact
    self._leftColumn.Visible = not compact
    self._rightColumn.Visible = not compact
    self._singleColumn.Visible = compact
    for _, section in ipairs(self._sections) do
        if compact then
            section._root.Parent = self._singleColumn
        elseif section._side == "Right" then
            section._root.Parent = self._rightColumn
        else
            section._root.Parent = self._leftColumn
        end
    end
    self:_updateHeight()
end

function TabMethods:_applySearch(query: string)
    local normalized = lower(trim(query))
    local filtering = normalized ~= ""
    for _, section in ipairs(self._sections) do
        local visibleRows = 0
        for _, entry in ipairs(section._searchRows) do
            local visible = not filtering or string.find(entry.Text, normalized, 1, true) ~= nil
            entry.Frame.Visible = visible
            if visible then visibleRows = visibleRows + 1 end
        end
        section._root.Visible = not filtering or visibleRows > 0
    end
    self:_updateHeight()
end

function TabMethods:AddSection(config: AnyObject?): AnyObject
    config = config or {}
    local titleValue = tostring(config.Title or "Section")
    local descriptionValue = tostring(config.Description or "")
    local side = if string.lower(tostring(config.Side or "Left")) == "right" then "Right" else "Left"
    local sectionMaid = Maid.new()
    self._maid:Add(sectionMaid)

    local parent = if self._compact
        then self._singleColumn
        else if side == "Right" then self._rightColumn else self._leftColumn

    local root = new("Frame", {
        Name = "Section_" .. string.gsub(titleValue, "%W+", "_"),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #self._sections + 1,
        ZIndex = 19,
        Parent = parent,
    }) :: Frame
    sectionMaid:Add(root)
    local rootLayout = list(root, Enum.FillDirection.Vertical, 8,
        Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

    local headerHeight = if descriptionValue ~= "" then 40 else 28
    local header = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, headerHeight),
        LayoutOrder = 0,
        ZIndex = 20,
        Parent = root,
    }) :: Frame
    text(header, titleValue, 11, self._window._theme.TextSecondary, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -12, 0, 20),
        Position = UDim2.fromOffset(3, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 21,
    })
    if descriptionValue ~= "" then
        text(header, descriptionValue, 9, self._window._theme.TextMuted, Enum.Font.Gotham, {
            Size = UDim2.new(1, -12, 0, 18),
            Position = UDim2.fromOffset(3, 19),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 21,
        })
    end

    local content = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        ZIndex = 20,
        Parent = root,
    }) :: Frame
    local contentLayout = list(content, Enum.FillDirection.Vertical, 8,
        Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

    local section: AnyObject = setmetatable({
        _window = self._window,
        _tab = self,
        _maid = sectionMaid,
        _root = root,
        _content = content,
        _side = side,
        _rows = {},
        _searchRows = {},
        _components = {},
        _destroyed = false,
        Name = titleValue,
        Root = root,
    }, SectionMethods)
    table.insert(self._sections, section)
    self._maid:Add(section)

    sectionMaid:Add(contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self:_updateHeight()
    end))
    sectionMaid:Add(rootLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self:_updateHeight()
    end))
    self:_updateHeight()
    return section
end

function TabMethods:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    local page = self._page
    removeValue(page._tabs, self)
    local wasActive = page._activeTab == self
    if wasActive then
        page._activeTab = nil
    end

    self._maid:Destroy()

    if wasActive and not page._destroyed then
        for _, candidate in ipairs(page._tabs) do
            if not candidate._destroyed then
                page:SelectTab(candidate)
                break
            end
        end
    end
end

function SectionMethods:AddToggle(config: AnyObject?): AnyObject
    config = config or {}
    local titleValue = tostring(config.Title or "Toggle")
    local descriptionValue = tostring(config.Description or "")
    local row, titleLabel, descriptionLabel = settingRow(self, titleValue, descriptionValue, 68)
    local control = component(row, self)
    control._value = config.Default == true
    control._callback = config.Callback

    local track = new("Frame", {
        BackgroundColor3 = self._window._theme.Control,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(36, 20),
        Position = UDim2.new(1, -50, 0, 14),
        ZIndex = 24,
        Parent = row,
    }) :: Frame
    corner(track, 10)
    local trackStroke = stroke(track, self._window._theme.Border, 0.6, 1)
    local thumb = new("Frame", {
        BackgroundColor3 = self._window._theme.TextSecondary,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.fromOffset(3, 3),
        ZIndex = 25,
        Parent = track,
    }) :: Frame
    corner(thumb, 7)

    function control:_render(animate: boolean?)
        local enabled = self._value == true
        local disabled = self._disabled == true
        local info = if animate == false then TweenInfo.new(0) else NORMAL
        row.Active = not disabled
        row.Selectable = not disabled
        titleLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.Text
        descriptionLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.TextMuted
        tween(track, info, {
            BackgroundColor3 = if enabled then self._window._accent else self._window._theme.Control,
            BackgroundTransparency = if disabled then 0.35 else 0,
        })
        tween(trackStroke, info, {
            Color = if enabled
                then mix(self._window._accent, Color3.new(1, 1, 1), 0.18)
                else self._window._theme.Border,
            Transparency = if enabled then 0.46 else 0.6,
        })
        tween(thumb, info, {
            Position = if enabled then UDim2.fromOffset(19, 3) else UDim2.fromOffset(3, 3),
            BackgroundColor3 = if enabled
                then contrastText(self._window._accent)
                else self._window._theme.TextSecondary,
            BackgroundTransparency = if disabled then 0.38 else 0,
        })
    end

    function control:SetValue(value: boolean, silent: boolean?)
        value = value == true
        if self._value == value then
            self:_render(true)
            return
        end
        self._value = value
        self:_render(true)
        if not silent then invoke(self._callback, value) end
    end

    control._maid:Add(row.Activated:Connect(function()
        if not control._disabled then
            control:SetValue(not control._value)
        end
    end))
    self._window:_bindAccent(control._maid, function() control:_render(false) end)
    control:_render(false)
    return control
end

function SectionMethods:AddSlider(config: AnyObject?): AnyObject
    config = config or {}
    local titleValue = tostring(config.Title or "Slider")
    local descriptionValue = tostring(config.Description or "")
    local minimum = tonumber(config.Min) or 0
    local maximum = tonumber(config.Max) or 100
    if maximum < minimum then minimum, maximum = maximum, minimum end
    if maximum == minimum then maximum = minimum + 1 end
    local step = math.abs(tonumber(config.Step) or 1)
    if step == 0 then step = 1 end
    local defaultValue = tonumber(config.Default) or minimum
    local suffix = tostring(config.Suffix or "")

    local row, titleLabel, descriptionLabel = settingRow(self, titleValue, descriptionValue, 78)
    local control = component(row, self)
    control._min, control._max, control._step = minimum, maximum, step
    control._suffix, control._callback = suffix, config.Callback
    control._value = math.clamp(roundStep(defaultValue, step), minimum, maximum)

    local valueLabel = text(row, "", 10, self._window._theme.TextSecondary, Enum.Font.GothamMedium, {
        Size = UDim2.fromOffset(58, 20),
        Position = UDim2.new(1, -72, 0, 10),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 25,
    })
    local track = new("Frame", {
        BackgroundColor3 = self._window._theme.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(0.46, -18, 0, 8),
        Position = UDim2.new(0.52, 0, 0, 49),
        ZIndex = 24,
        Parent = row,
    }) :: Frame
    corner(track, 4)
    local fill = new("Frame", {
        BackgroundColor3 = self._window._accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        ZIndex = 25,
        Parent = track,
    }) :: Frame
    corner(fill, 4)
    local thumb = new("Frame", {
        BackgroundColor3 = self._window._theme.Text,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(12, 18),
        Position = UDim2.fromScale(0, 0.5),
        ZIndex = 27,
        Parent = track,
    }) :: Frame
    corner(thumb, 4)
    stroke(thumb, self._window._theme.BorderStrong, 0.35, 1)
    local hitbox = button(row, {
        Name = "SliderHitbox",
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, 0, 0, 30),
        Position = UDim2.new(0.5, 0, 0, 38),
        ZIndex = 29,
    })

    local dragging = false
    local activeTouch: InputObject? = nil
    local function alphaFromValue(value: number): number
        return math.clamp((value - minimum) / (maximum - minimum), 0, 1)
    end

    function control:_render(animate: boolean?)
        local alpha = alphaFromValue(self._value)
        local info = if animate == false then TweenInfo.new(0) else FAST
        local disabled = self._disabled == true
        row.Active = not disabled
        hitbox.Active = not disabled
        hitbox.Selectable = not disabled
        titleLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.Text
        descriptionLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.TextMuted
        valueLabel.Text = formatNumber(self._value, step, suffix)
        valueLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.TextSecondary
        tween(fill, info, {
            Size = UDim2.fromScale(alpha, 1),
            BackgroundColor3 = self._window._accent,
            BackgroundTransparency = if disabled then 0.55 else 0,
        })
        tween(thumb, info, {
            Position = UDim2.fromScale(alpha, 0.5),
            BackgroundTransparency = if disabled then 0.45 else 0,
        })
    end

    function control:SetValue(value: number, silent: boolean?)
        local normalized = math.clamp(roundStep(tonumber(value) or minimum, step), minimum, maximum)
        if math.abs(normalized - self._value) < 1e-6 then
            self:_render(false)
            return
        end
        self._value = normalized
        self:_render(not dragging)
        if not silent then invokeLatest(self, self._callback, normalized) end
    end

    local function setFromPoint(point: Vector2)
        local alpha = math.clamp(
            (point.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X),
            0,
            1
        )
        control:SetValue(minimum + (maximum - minimum) * alpha)
    end

    control._maid:Add(hitbox.InputBegan:Connect(function(inputObject)
        if control._disabled then return end
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch
        then
            dragging = true
            activeTouch = if inputObject.UserInputType == Enum.UserInputType.Touch
                then inputObject else nil
            tween(thumb, FAST, { Size = UDim2.fromOffset(15, 20) })
            setFromPoint(pointer(inputObject))
        end
    end))
    control._maid:Add(UserInputService.InputChanged:Connect(function(inputObject)
        if not dragging then return end
        if activeTouch then
            if inputObject ~= activeTouch then return end
        elseif inputObject.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        setFromPoint(pointer(inputObject))
    end))
    control._maid:Add(UserInputService.InputEnded:Connect(function(inputObject)
        if activeTouch and inputObject ~= activeTouch then return end
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch
        then
            dragging, activeTouch = false, nil
            tween(thumb, FAST, { Size = UDim2.fromOffset(12, 18) })
        end
    end))
    control._maid:Add(UserInputService.InputBegan:Connect(function(inputObject, processed)
        if processed or control._disabled or GuiService.SelectedObject ~= hitbox then return end
        if inputObject.KeyCode == Enum.KeyCode.Left
            or inputObject.KeyCode == Enum.KeyCode.DPadLeft
        then
            control:SetValue(control._value - step)
        elseif inputObject.KeyCode == Enum.KeyCode.Right
            or inputObject.KeyCode == Enum.KeyCode.DPadRight
        then
            control:SetValue(control._value + step)
        end
    end))

    self._window:_bindAccent(control._maid, function() control:_render(false) end)
    control:_render(false)
    return control
end

function SectionMethods:AddDropdown(config: AnyObject?): AnyObject
    config = config or {}
    local titleValue = tostring(config.Title or "Dropdown")
    local descriptionValue = tostring(config.Description or "")
    local row, titleLabel, descriptionLabel = settingRow(self, titleValue, descriptionValue, 68)
    local control = component(row, self)
    control._options, control._multi, control._callback = {}, config.Multi == true, config.Callback
    for _, option in ipairs(config.Options or {}) do table.insert(control._options, option) end

    if control._multi then
        control._value = {}
        if type(config.Default) == "table" then
            for _, option in ipairs(config.Default) do
                control._value[tostring(option)] = true
            end
        end
    else
        control._value = config.Default
        if control._value == nil and #control._options > 0 then
            control._value = control._options[1]
        end
    end

    local bed = controlBed(row, self._window, 142, 32)
    bed.Position = UDim2.new(1, -156, 0, 18)
    bed.ZIndex = 24
    local valueLabel = text(bed, "", 10, self._window._theme.TextSecondary, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 26,
    })
    text(bed, "⌄", 13, self._window._theme.TextMuted, Enum.Font.GothamMedium, {
        Size = UDim2.fromOffset(24, 32),
        Position = UDim2.new(1, -27, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 26,
    })

    local function display(): string
        if control._multi then
            local selected = {}
            for _, option in ipairs(control._options) do
                if control._value[tostring(option)] then
                    table.insert(selected, tostring(option))
                end
            end
            return if #selected == 0
                then tostring(config.Placeholder or "Select…")
                else table.concat(selected, ", ")
        end
        return if control._value == nil
            then tostring(config.Placeholder or "Select…")
            else tostring(control._value)
    end

    function control:_render()
        local disabled = self._disabled == true
        row.Active, row.Selectable = not disabled, not disabled
        titleLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.Text
        descriptionLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.TextMuted
        bed.BackgroundTransparency = if disabled then 0.35 else 0
        valueLabel.Text = display()
        valueLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.TextSecondary
    end

    function control:_selectOption(option: any)
        if self._multi then
            local key = tostring(option)
            self._value[key] = not self._value[key]
            self:_render()
            invoke(self._callback, copy(self._value))
        else
            self:SetValue(option)
        end
    end

    function control:SetValue(value: any, silent: boolean?)
        if self._multi then
            local nextValue: AnyObject = {}
            if type(value) == "table" then
                for key, selected in pairs(value) do
                    if type(key) == "number" then
                        nextValue[tostring(selected)] = true
                    elseif selected then
                        nextValue[tostring(key)] = true
                    end
                end
            end
            self._value = nextValue
        else
            self._value = value
        end
        self:_render()
        if not silent then
            invoke(self._callback, if self._multi then copy(self._value) else self._value)
        end
    end

    function control:SetOptions(options: { any }, preserveValue: boolean?)
        table.clear(self._options)
        for _, option in ipairs(options or {}) do table.insert(self._options, option) end
        if not preserveValue then
            self._value = if self._multi then {} else self._options[1]
        end
        self:_render()
    end

    function control:Open()
        if not self._disabled then self._window:_openDropdown(self) end
    end
    control._maid:Add(row.Activated:Connect(function() control:Open() end))
    control:_render()
    return control
end

function SectionMethods:AddButton(config: AnyObject?): AnyObject
    config = config or {}
    local titleValue = tostring(config.Title or "Action")
    local descriptionValue = tostring(config.Description or "")
    local row, titleLabel, descriptionLabel = settingRow(self, titleValue, descriptionValue, 68)
    local control = component(row, self)
    control._callback = config.Callback
    control._value = false

    row.Active, row.Selectable = false, false
    local action = button(row, {
        BackgroundColor3 = self._window._accent,
        BackgroundTransparency = 0,
        Size = UDim2.fromOffset(112, 32),
        Position = UDim2.new(1, -126, 0, 18),
        ZIndex = 25,
    })
    corner(action, 9)
    local actionStroke = stroke(action, mix(self._window._accent, Color3.new(1, 1, 1), 0.25), 0.45, 1)
    local actionLabel = text(action, tostring(config.Text or config.ButtonText or "Run"),
        11, contrastText(self._window._accent), Enum.Font.GothamBold, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 27,
        })

    function control:_render()
        local disabled = self._disabled == true
        action.Active, action.Selectable = not disabled, not disabled
        titleLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.Text
        descriptionLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.TextMuted
        action.BackgroundColor3 = self._window._accent
        action.BackgroundTransparency = if disabled then 0.55 else 0
        actionLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else contrastText(self._window._accent)
        actionStroke.Color = mix(self._window._accent, Color3.new(1, 1, 1), 0.25)
    end
    function control:Fire()
        if not self._disabled then invoke(self._callback) end
    end

    control._maid:Add(action.MouseEnter:Connect(function()
        if not control._disabled then
            tween(action, FAST, {
                BackgroundColor3 = mix(control._window._accent, Color3.new(1, 1, 1), 0.08),
            })
        end
    end))
    control._maid:Add(action.MouseLeave:Connect(function() control:_render() end))
    control._maid:Add(action.Activated:Connect(function()
        if control._disabled then return end
        tween(action, FAST, { Size = UDim2.fromOffset(108, 30) })
        task.delay(0.08, function()
            if action.Parent then tween(action, FAST, { Size = UDim2.fromOffset(112, 32) }) end
        end)
        control:Fire()
    end))
    self._window:_bindAccent(control._maid, function() control:_render() end)
    control:_render()
    return control
end

function SectionMethods:AddInput(config: AnyObject?): AnyObject
    config = config or {}
    local titleValue = tostring(config.Title or "Input")
    local descriptionValue = tostring(config.Description or "")
    local row, titleLabel, descriptionLabel = settingRow(self, titleValue, descriptionValue, 68)
    local control = component(row, self)
    control._value = tostring(config.Default or "")
    control._callback = config.Callback
    local numeric = config.Numeric == true
    row.Active, row.Selectable = false, false

    local box = new("TextBox", {
        BackgroundColor3 = self._window._theme.ControlDark,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        PlaceholderText = tostring(config.Placeholder or "Enter value…"),
        PlaceholderColor3 = self._window._theme.TextMuted,
        Text = control._value,
        TextColor3 = self._window._theme.TextSecondary,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.fromOffset(142, 32),
        Position = UDim2.new(1, -156, 0, 18),
        ZIndex = 25,
        Parent = row,
    }) :: TextBox
    corner(box, 9)
    local boxStroke = stroke(box, self._window._theme.Border, 0.58, 1)
    padding(box, 10, 10, 0, 0)

    function control:_render()
        local disabled = self._disabled == true
        box.TextEditable, box.Active, box.Selectable = not disabled, not disabled, not disabled
        titleLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.Text
        descriptionLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.TextMuted
        box.BackgroundTransparency = if disabled then 0.35 else 0
        box.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.TextSecondary
    end

    function control:SetValue(value: any, silent: boolean?)
        local nextValue = tostring(value or "")
        if numeric then
            local parsed = tonumber(nextValue)
            if not parsed then return end
            nextValue = tostring(parsed)
        end
        self._value = nextValue
        box.Text = nextValue
        if not silent then
            invoke(self._callback, if numeric then tonumber(nextValue) else nextValue)
        end
    end

    control._maid:Add(box.Focused:Connect(function()
        tween(boxStroke, FAST, { Color = control._window._accent, Transparency = 0.18 })
    end))
    control._maid:Add(box.FocusLost:Connect(function(enterPressed)
        tween(boxStroke, FAST, {
            Color = control._window._theme.Border,
            Transparency = 0.58,
        })
        control:SetValue(box.Text)
        if enterPressed and type(config.OnEnter) == "function" then
            invoke(config.OnEnter, if numeric then tonumber(control._value) else control._value)
        end
    end))
    if config.Continuous == true then
        control._maid:Add(box:GetPropertyChangedSignal("Text"):Connect(function()
            if control._disabled then return end
            control._value = box.Text
            invoke(control._callback, if numeric then tonumber(box.Text) else box.Text)
        end))
    end
    self._window:_bindAccent(control._maid, function()
        if box:IsFocused() then boxStroke.Color = control._window._accent end
    end)
    control:_render()
    return control
end

function SectionMethods:AddKeybind(config: AnyObject?): AnyObject
    config = config or {}
    local titleValue = tostring(config.Title or "Keybind")
    local descriptionValue = tostring(config.Description or "")
    local row, titleLabel, descriptionLabel = settingRow(self, titleValue, descriptionValue, 68)
    local control = component(row, self)
    local defaultKey = config.Default
    if typeof(defaultKey) ~= "EnumItem" or defaultKey.EnumType ~= Enum.KeyCode then
        defaultKey = Enum.KeyCode.Unknown
    end
    control._value, control._callback, control._listening = defaultKey, config.Callback, false
    row.Active, row.Selectable = false, false

    local keyButton = button(row, {
        BackgroundColor3 = self._window._theme.ControlDark,
        BackgroundTransparency = 0,
        Size = UDim2.fromOffset(112, 32),
        Position = UDim2.new(1, -126, 0, 18),
        ZIndex = 25,
    })
    corner(keyButton, 9)
    local keyStroke = stroke(keyButton, self._window._theme.Border, 0.58, 1)
    local keyLabel = text(keyButton, "", 10, self._window._theme.TextSecondary,
        Enum.Font.GothamMedium, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 27,
        })

    function control:_render()
        local disabled = self._disabled == true
        keyButton.Active, keyButton.Selectable = not disabled, not disabled
        titleLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.Text
        descriptionLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.TextMuted
        keyButton.BackgroundTransparency = if disabled then 0.35 else 0
        keyLabel.Text = if self._listening then "Press a key…"
            else if self._value == Enum.KeyCode.Unknown then "Unbound" else self._value.Name
        keyLabel.TextColor3 = if self._listening then self._window._accent
            else if disabled then self._window._theme.TextDisabled
            else self._window._theme.TextSecondary
        keyStroke.Color = if self._listening then self._window._accent else self._window._theme.Border
        keyStroke.Transparency = if self._listening then 0.15 else 0.58
    end

    function control:SetValue(keyCode: Enum.KeyCode, silent: boolean?)
        if typeof(keyCode) ~= "EnumItem" or keyCode.EnumType ~= Enum.KeyCode then return end
        self._value, self._listening = keyCode, false
        self._window._capturingKeybind = false
        self:_render()
        if not silent then invoke(self._callback, keyCode) end
    end

    control._maid:Add(keyButton.Activated:Connect(function()
        if control._disabled then return end
        control._listening = true
        control._window._capturingKeybind = true
        control:_render()
    end))
    control._maid:Add(UserInputService.InputBegan:Connect(function(inputObject, processed)
        if not control._listening or processed then return end
        if inputObject.KeyCode == Enum.KeyCode.Unknown then return end
        if inputObject.KeyCode == Enum.KeyCode.Escape then
            control._listening = false
            control._window._capturingKeybind = false
            control:_render()
            return
        end
        control:SetValue(inputObject.KeyCode)
    end))
    self._window:_bindAccent(control._maid, function() control:_render() end)
    control:_render()
    return control
end

function SectionMethods:AddColorPicker(config: AnyObject?): AnyObject
    config = config or {}
    local titleValue = tostring(config.Title or "Color")
    local descriptionValue = tostring(config.Description or "")
    local row, titleLabel, descriptionLabel = settingRow(self, titleValue, descriptionValue, 68)
    local control = component(row, self)
    local defaultColor = config.Default
    if typeof(defaultColor) ~= "Color3" then defaultColor = self._window._accent end
    control._value = defaultColor
    control._transparency = math.clamp(tonumber(config.Transparency) or 0, 0, 1)
    control._callback, control._swatches = config.Callback, config.Swatches

    local bed = controlBed(row, self._window, 142, 32)
    bed.Position = UDim2.new(1, -156, 0, 18)
    bed.ZIndex = 24
    local swatch = new("Frame", {
        BackgroundColor3 = defaultColor,
        BackgroundTransparency = control._transparency,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.fromOffset(7, 6),
        ZIndex = 26,
        Parent = bed,
    }) :: Frame
    corner(swatch, 10)
    stroke(swatch, self._window._theme.White, 0.3, 1)
    local hexLabel = text(bed, rgbToHex(defaultColor), 10, self._window._theme.TextSecondary,
        Enum.Font.GothamMedium, {
            Size = UDim2.new(1, -42, 1, 0),
            Position = UDim2.fromOffset(35, 0),
            ZIndex = 26,
        })

    function control:_render()
        local disabled = self._disabled == true
        row.Active, row.Selectable = not disabled, not disabled
        titleLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.Text
        descriptionLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.TextMuted
        bed.BackgroundTransparency = if disabled then 0.35 else 0
        swatch.BackgroundColor3 = self._value
        swatch.BackgroundTransparency = if disabled
            then math.max(self._transparency, 0.5)
            else self._transparency
        hexLabel.Text = rgbToHex(self._value)
        hexLabel.TextColor3 = if disabled then self._window._theme.TextDisabled
            else self._window._theme.TextSecondary
    end

    function control:SetValue(color: Color3, transparencyValue: number?, silent: boolean?)
        if typeof(color) ~= "Color3" then return end
        self._value = color
        if transparencyValue ~= nil then
            self._transparency = math.clamp(transparencyValue, 0, 1)
        end
        self:_render()
        if not silent then
            invokeLatest(self, self._callback, self._value, self._transparency)
        end
    end
    function control:GetTransparency(): number
        return self._transparency
    end
    function control:Open()
        if not self._disabled then self._window:_openColorPicker(self) end
    end
    control._maid:Add(row.Activated:Connect(function() control:Open() end))
    control:_render()
    return control
end

function SectionMethods:AddParagraph(config: AnyObject?): AnyObject
    config = config or {}
    local titleValue = tostring(config.Title or "Information")
    local bodyValue = tostring(config.Content or config.Description or "")
    local height = math.clamp(62 + math.floor(#bodyValue / 54) * 12, 76, 126)
    local row, titleLabel, descriptionLabel = settingRow(self, titleValue, bodyValue, height)
    local control = component(row, self)
    control._value = bodyValue
    row.Active, row.Selectable = false, false
    titleLabel.Size = UDim2.new(1, -28, 0, 22)
    descriptionLabel.Size = UDim2.new(1, -28, 1, -44)
    descriptionLabel.TextWrapped = true
    function control:SetValue(value: any)
        self._value = tostring(value or "")
        descriptionLabel.Text = self._value
    end
    control.SetContent = control.SetValue
    return control
end

function SectionMethods:AddSeparator(config: AnyObject?): AnyObject
    config = config or {}
    local labelValue = tostring(config.Text or "")
    local root = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, if labelValue == "" then 14 else 24),
        LayoutOrder = #self._rows + 1,
        ZIndex = 20,
        Parent = self._content,
    }) :: Frame
    new("Frame", {
        BackgroundColor3 = self._window._theme.Border,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0.5, 0),
        ZIndex = 21,
        Parent = root,
    })
    if labelValue ~= "" then
        local width = math.min(180, textWidth(labelValue, 9, Enum.Font.GothamMedium) + 16)
        text(root, labelValue, 9, self._window._theme.TextMuted, Enum.Font.GothamMedium, {
            BackgroundColor3 = self._window._theme.Shell,
            BackgroundTransparency = 0,
            Size = UDim2.fromOffset(width, 20),
            Position = UDim2.new(0.5, -width / 2, 0.5, -10),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 22,
        })
    end
    table.insert(self._rows, root)
    table.insert(self._searchRows, { Frame = root, Text = lower(labelValue) })
    return component(root, self)
end

function SectionMethods:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    local tab = self._tab
    removeValue(tab._sections, self)
    self._maid:Destroy()

    if not tab._destroyed then
        tab:_updateHeight()
    end
end

function WindowMethods:Notify(config: AnyObject?): AnyObject
    config = config or {}
    local titleValue = tostring(config.Title or "Notification")
    local descriptionValue = tostring(config.Description or "")
    local duration = math.max(0, tonumber(config.Duration) or 4)
    local severity = lower(config.Severity or "info")
    local tone = self._accent
    if severity == "success" then tone = self._theme.Success
    elseif severity == "warning" then tone = self._theme.Warning
    elseif severity == "error" then tone = self._theme.Error end

    local toastMaid = Maid.new()
    local wrapper = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(316, 80),
        LayoutOrder = self._toastSerial,
        ZIndex = 410,
        Parent = self._toastHost,
    }) :: Frame
    self._toastSerial = self._toastSerial + 1
    toastMaid:Add(wrapper)

    local card = new("CanvasGroup", {
        BackgroundColor3 = self._theme.ShellRaised,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(306, 72),
        Position = UDim2.fromOffset(22, 4),
        GroupTransparency = 1,
        ZIndex = 412,
        Parent = wrapper,
    }) :: CanvasGroup
    corner(card, 14)
    stroke(card, self._theme.BorderStrong, 0.38, 1)
    local toneBar = new("Frame", {
        BackgroundColor3 = tone,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(4, 38),
        Position = UDim2.fromOffset(10, 16),
        ZIndex = 414,
        Parent = card,
    }) :: Frame
    corner(toneBar, 2)
    text(card, titleValue, 12, self._theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.new(1, -64, 0, 20),
        Position = UDim2.fromOffset(24, 12),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 414,
    })
    text(card, descriptionValue, 10, self._theme.TextMuted, Enum.Font.Gotham, {
        Size = UDim2.new(1, -62, 0, 28),
        Position = UDim2.fromOffset(24, 32),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 414,
    })
    local close = button(card, {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -34, 0, 8),
        ZIndex = 416,
    })
    text(close, "×", 15, self._theme.TextMuted, Enum.Font.GothamMedium, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 417,
    })
    local progress = new("Frame", {
        BackgroundColor3 = tone,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Size = UDim2.new(1, -20, 0, 2),
        Position = UDim2.new(0, 10, 1, -5),
        ZIndex = 416,
        Parent = card,
    }) :: Frame
    corner(progress, 1)

    local notification: AnyObject = {
        Root = wrapper,
        _closed = false,
        _maid = toastMaid,
    }
    local function closeToast()
        if notification._closed then return end
        notification._closed = true
        removeValue(self._toasts, notification)
        local closing = tween(card, NORMAL, {
            GroupTransparency = 1,
            Position = UDim2.fromOffset(22, -4),
        })
        if closing then
            toastMaid:Add(closing.Completed:Connect(function() toastMaid:Destroy() end))
        else
            toastMaid:Destroy()
        end
    end
    notification.Close = closeToast
    notification.Destroy = function()
        notification._closed = true
        removeValue(self._toasts, notification)
        toastMaid:Destroy()
    end
    self._maid:Add(notification)
    toastMaid:Add(close.Activated:Connect(closeToast))
    tween(card, SLOW, {
        GroupTransparency = 0,
        Position = UDim2.fromOffset(0, 4),
    })

    if duration > 0 then
        tween(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Size = UDim2.fromOffset(0, 2),
        })
        toastMaid:Add(task.delay(duration, closeToast))
    else
        progress.Visible = false
    end

    table.insert(self._toasts, notification)
    while #self._toasts > 4 do
        local oldest = table.remove(self._toasts, 1)
        if oldest and not oldest._closed then oldest.Close() end
    end
    return notification
end

function WindowMethods:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    local popup = self._activePopup
    self._activePopup = nil
    if popup and popup.Maid then
        popup.Maid:Destroy()
    end

    self._maid:Destroy()
end

local function createChrome(window: AnyObject, config: AnyObject)
    local screen, theme = window._screen, window._theme

    local overlay = new("Frame", {
        Name = "Overlay",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 200,
        Parent = screen,
    }) :: Frame
    window._overlay = overlay

    local shell = new("CanvasGroup", {
        Name = "Window",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT),
        Position = UDim2.fromOffset(100, 100),
        GroupTransparency = 0,
        ZIndex = 10,
        Parent = screen,
    }) :: CanvasGroup
    window._shell = shell
    window._scale = new("UIScale", { Scale = 1, Parent = shell }) :: UIScale

    for index = 4, 1, -1 do
        local spread = index * 3
        local shadowFrame = new("Frame", {
            BackgroundColor3 = theme.Shadow,
            BackgroundTransparency = 0.78 + index * 0.035,
            BorderSizePixel = 0,
            Size = UDim2.new(1, spread * 2, 1, spread * 2),
            Position = UDim2.fromOffset(-spread, 4 + spread),
            ZIndex = 10,
            Parent = shell,
        }) :: Frame
        corner(shadowFrame, 24 + spread)
    end

    local body = new("Frame", {
        Name = "Body",
        BackgroundColor3 = theme.Shell,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 14,
        Parent = shell,
    }) :: Frame
    corner(body, 24)
    stroke(body, theme.BorderStrong, 0.42, 1)
    new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.96,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -30, 0, 1),
        Position = UDim2.fromOffset(15, 1),
        ZIndex = 18,
        Parent = body,
    })

    local header = new("Frame", {
        Name = "Header",
        BackgroundColor3 = theme.ShellRaised,
        BackgroundTransparency = 0.58,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
        ZIndex = 17,
        Parent = body,
    }) :: Frame
    window._header = header
    new("Frame", {
        BackgroundColor3 = theme.Border,
        BackgroundTransparency = 0.66,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.new(0, 12, 1, -1),
        ZIndex = 19,
        Parent = header,
    })

    local brand = new("Frame", {
        BackgroundColor3 = window._accent,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.fromOffset(18, 18),
        ZIndex = 21,
        Parent = header,
    }) :: Frame
    corner(brand, 10)
    local brandStroke = stroke(brand, window._accent, 0.35, 1)
    local brandLetter = text(brand, tostring(config.BrandLetter or "R"), 18,
        window._accent, Enum.Font.GothamBlack, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 23,
        })

    window._title = text(header, tostring(config.Title or "Brand name"), 11,
        theme.Text, Enum.Font.GothamBold, {
            Size = UDim2.fromOffset(250, 18),
            Position = UDim2.fromOffset(62, 18),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 22,
        })
    window._subtitle = text(header, tostring(config.Subtitle or "The slogan, if there is one."),
        9, theme.TextMuted, Enum.Font.Gotham, {
            Size = UDim2.fromOffset(270, 18),
            Position = UDim2.fromOffset(62, 35),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 22,
        })

    local status = new("Frame", {
        Name = "Status",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(220, 48),
        Position = UDim2.new(1, -236, 0, 11),
        ZIndex = 22,
        Parent = header,
    }) :: Frame
    window._statusGroup = status
    text(status, tostring(config.StatusTitle or "Past 0w1"), 11,
        theme.TextSecondary, Enum.Font.GothamMedium, {
            Size = UDim2.new(1, -52, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 23,
        })
    text(status, tostring(config.StatusText or "Tue, 3 Mar 2026"), 9,
        theme.TextMuted, Enum.Font.Gotham, {
            Size = UDim2.new(1, -52, 0, 18),
            Position = UDim2.fromOffset(0, 18),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 23,
        })
    local orb = new("Frame", {
        BackgroundColor3 = theme.Text,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(40, 40),
        Position = UDim2.new(1, -42, 0, 1),
        ZIndex = 24,
        Parent = status,
    }) :: Frame
    corner(orb, 20)
    text(orb, tostring(config.StatusIcon or "➤"), 18, theme.Shell, Enum.Font.GothamBold, {
        Size = UDim2.fromScale(1, 1),
        Rotation = -35,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 25,
    })

    local rail = new("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.Rail,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, HEADER_HEIGHT),
        Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -HEADER_HEIGHT),
        ZIndex = 16,
        Parent = body,
    }) :: Frame
    window._rail = rail
    new("Frame", {
        BackgroundColor3 = theme.Border,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 1, -22),
        Position = UDim2.new(1, -1, 0, 11),
        ZIndex = 18,
        Parent = rail,
    })

    local navList = new("Frame", {
        Name = "Navigation",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 1, -82),
        Position = UDim2.fromOffset(10, 14),
        ZIndex = 20,
        Parent = rail,
    }) :: Frame
    list(navList, Enum.FillDirection.Vertical, 8,
        Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)
    window._navList = navList

    local utility = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, 54),
        Position = UDim2.new(0, 10, 1, -62),
        ZIndex = 20,
        Parent = rail,
    }) :: Frame
    local settings = button(utility, {
        BackgroundColor3 = theme.SurfaceRaised,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(44, 44),
        Position = UDim2.new(0.5, -22, 0.5, -22),
        ZIndex = 22,
    })
    corner(settings, 12)
    text(settings, "⚙", 17, theme.TextMuted, Enum.Font.GothamMedium, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 24,
    })

    window._pageHost = new("Frame", {
        Name = "Workspace",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(SIDEBAR_WIDTH, HEADER_HEIGHT),
        Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -HEADER_HEIGHT),
        ClipsDescendants = true,
        ZIndex = 15,
        Parent = body,
    }) :: Frame

    local toastHost = new("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.fromOffset(320, 440),
        ZIndex = 400,
        Parent = overlay,
    }) :: Frame
    list(toastHost, Enum.FillDirection.Vertical, 8,
        Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Top)
    window._toastHost = toastHost

    window:_bindAccent(window._maid, function(accent)
        brand.BackgroundColor3 = accent
        brandStroke.Color = accent
        brandLetter.TextColor3 = accent
    end)
    window._maid:Add(settings.MouseEnter:Connect(function()
        tween(settings, FAST, {
            BackgroundTransparency = 0.35,
            BackgroundColor3 = theme.SurfaceHover,
        })
    end))
    window._maid:Add(settings.MouseLeave:Connect(function()
        tween(settings, FAST, { BackgroundTransparency = 1 })
    end))
    window._maid:Add(settings.Activated:Connect(function()
        window:Notify({
            Title = "Interface ready",
            Description = "Use a ColorPicker control to edit the accent live.",
            Duration = 3,
        })
    end))

    local dragHandle = button(header, {
        Name = "DragHandle",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -250, 1, 0),
        ZIndex = 20,
        Selectable = false,
    })
    window._dragHandle = dragHandle
    local dragging, dragStarted = false, false
    local dragInput: InputObject? = nil
    local dragStart = Vector2.zero
    local startPosition = shell.Position

    window._maid:Add(dragHandle.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1
            and inputObject.UserInputType ~= Enum.UserInputType.Touch
        then return end
        dragging, dragStarted, dragInput = true, false, inputObject
        dragStart = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
        startPosition = shell.Position
    end))
    window._maid:Add(UserInputService.InputChanged:Connect(function(inputObject)
        if not dragging or not dragInput then return end
        if dragInput.UserInputType == Enum.UserInputType.Touch then
            if inputObject ~= dragInput then return end
        elseif inputObject.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        local current = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
        local delta = current - dragStart
        if not dragStarted and delta.Magnitude < 7 then return end
        dragStarted = true
        shell.Position = startPosition + UDim2.fromOffset(delta.X, delta.Y)
        window:_clampWindowPosition()
    end))
    window._maid:Add(UserInputService.InputEnded:Connect(function(inputObject)
        if not dragging or not dragInput then return end
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch
        then
            dragging, dragStarted, dragInput = false, false, nil
            window:_clampWindowPosition()
            window._basePosition = shell.Position
        end
    end))
end

function Library.CreateWindow(config: AnyObject?): AnyObject
    config = config or {}
    local parent = resolveParent(config.Parent)
    local name = tostring(config.Name or "RosaUI")
    local previous = parent:FindFirstChild(name)
    if previous then
        local shutdown = previous:FindFirstChild("_RosaShutdown")
        if shutdown and shutdown:IsA("BindableEvent") then
            shutdown:Fire()
        end
        if previous.Parent then
            previous:Destroy()
        end
    end

    local maid = Maid.new()
    local screen = new("ScreenGui", {
        Name = name,
        IgnoreGuiInset = true,
        ResetOnSpawn = config.ResetOnSpawn == true,
        DisplayOrder = tonumber(config.DisplayOrder) or 50,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Enabled = true,
        Parent = parent,
    }) :: ScreenGui
    maid:Add(screen)

    local shutdownEvent = new("BindableEvent", {
        Name = "_RosaShutdown",
        Parent = screen,
    }) :: BindableEvent

    local theme = copy(THEME)
    if type(config.Theme) == "table" then
        for key, value in pairs(config.Theme) do
            if typeof(value) == "Color3" then theme[key] = value end
        end
    end
    local accent = config.Accent
    if typeof(accent) ~= "Color3" then accent = Color3.fromRGB(255, 87, 90) end
    local keybind = config.Keybind
    if typeof(keybind) ~= "EnumItem" or keybind.EnumType ~= Enum.KeyCode then
        keybind = Enum.KeyCode.RightShift
    end

    local window: AnyObject = setmetatable({
        _maid = maid,
        _screen = screen,
        _theme = theme,
        _accent = accent,
        _accentBindings = {},
        _pages = {},
        _activePage = nil,
        _activePopup = nil,
        _toasts = {},
        _toastSerial = 1,
        _visible = true,
        _destroyed = false,
        _compact = false,
        _positionInitialized = false,
        _basePosition = nil,
        _capturingKeybind = false,
        _keybind = keybind,
        Accent = accent,
        Keybind = keybind,
        Gui = screen,
        Root = screen,
    }, WindowMethods)

    createChrome(window, config)
    maid:Add(shutdownEvent.Event:Connect(function()
        window:Destroy()
    end))

    local cameraMaid = Maid.new()
    maid:Add(function()
        cameraMaid:Destroy()
    end)

    local function bindCamera(camera: Camera?)
        cameraMaid:Destroy()
        cameraMaid = Maid.new()

        if camera then
            cameraMaid:Add(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                window:_updateResponsive(false)
            end))
        end

        window:_updateResponsive(false)
    end

    bindCamera(workspace.CurrentCamera)
    maid:Add(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        bindCamera(workspace.CurrentCamera)
    end))
    maid:Add(UserInputService.InputBegan:Connect(function(inputObject, processed)
        if window._destroyed then
            return
        end

        local popup = window._activePopup
        if popup and (
            inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch
        ) then
            local point = pointer(inputObject)
            if not inside(popup.Frame, point) and not inside(popup.Anchor, point) then
                window:_closePopup()
            end
        end

        if processed or window._capturingKeybind then
            return
        end

        if inputObject.KeyCode == window._keybind then
            window:Toggle()
        end
    end))

    window:_updateResponsive(true)
    task.defer(function()
        if window._shell.Parent then
            local basePosition = window._basePosition or window._shell.Position
            window._shell.GroupTransparency = 1
            window._shell.Position = basePosition + UDim2.fromOffset(0, 8)
            tween(window._shell, SLOW, {
                GroupTransparency = 0,
                Position = basePosition,
            })
        end
    end)
    return window
end

function Library.CreateReferenceDemo(parent: Instance?): AnyObject
    local window = Library.CreateWindow({
        Parent = parent,
        Name = "RosaUI_ReferenceDemo",
        Title = "Brand name",
        Subtitle = "The slogan, if there is one.",
        BrandLetter = "R",
        StatusTitle = "Past 0w1",
        StatusText = "Tue, 3 Mar 2026",
        StatusIcon = "➤",
        Accent = Color3.fromRGB(255, 87, 90),
        Keybind = Enum.KeyCode.RightShift,
    })

    local combat = window:AddPage({ Name = "Combat", Icon = "◎" })
    window:AddPage({ Name = "Visuals", Icon = "◌" })
    window:AddPage({ Name = "Movement", Icon = "◈" })
    window:AddPage({ Name = "Profiles", Icon = "□" })
    window:AddPage({ Name = "Settings", Icon = "⚙" })

    combat:AddTab({ Name = "Aimbot", Icon = "◉" })
    combat:AddTab({ Name = "Triggerbot", Icon = "◉" })
    local recoil = combat:AddTab({ Name = "NoRecoil", Icon = "◎" })
    combat:AddTab({ Name = "More", Icon = "›" })

    local left = recoil:AddSection({
        Title = "Recoil control system",
        Side = "Left",
    })
    left:AddToggle({
        Title = "Enable recoil",
        Description = "Activates weapon recoil for realistic shooting mechanics.",
        Default = true,
    })
    left:AddToggle({
        Title = "Use horizontal jitter",
        Description = "Eliminates vertical recoil using horizontal shaping patterns.",
        Default = false,
    })
    left:AddDropdown({
        Title = "Selected primary weapon",
        Description = "Pick a main firearm configuration profile.",
        Options = { "AK-47", "SCAR", "DMR", "SMG" },
        Default = "AK-47",
    })
    left:AddSlider({
        Title = "Vertical offset",
        Description = "Adjusts upward recoil compensation amount.",
        Min = 0,
        Max = 1.5,
        Default = 0.8,
        Step = 0.05,
        Suffix = "F",
    })
    left:AddSlider({
        Title = "Horizontal offset",
        Description = "Controls side-to-side compensation.",
        Min = 0,
        Max = 1,
        Default = 0.5,
        Step = 0.05,
        Suffix = "F",
    })

    local right = recoil:AddSection({
        Title = "Automatic operator detection",
        Side = "Right",
    })
    right:AddToggle({
        Title = "Operator detection",
        Description = "Identifies and tracks target players automatically.",
        Default = true,
    })
    right:AddToggle({
        Title = "Configure detection area",
        Description = "Sets boundaries for target scanning zones.",
        Default = false,
    })
    right:AddDropdown({
        Title = "Manual operator selection",
        Description = "Allows manual selection of a specific target.",
        Options = { "ACE", "ASH", "JÄGER", "SLEDGE" },
        Default = "ACE",
    })

    local misc = recoil:AddSection({ Title = "Miscellaneous", Side = "Right" })
    misc:AddToggle({
        Title = "Perfect physical state",
        Description = "Maintains ideal character condition and stats.",
        Default = true,
    })
    misc:AddToggle({
        Title = "BunnyHop",
        Description = "Automates jump timing for continuous movement.",
        Default = false,
    })
    misc:AddSlider({
        Title = "Penetration walls",
        Description = "Controls the simulated penetration ratio.",
        Min = 0,
        Max = 100,
        Default = 85,
        Step = 1,
        Suffix = "%",
    })
    local accentPicker = misc:AddColorPicker({
        Title = "Interface accent",
        Description = "Live theme color used by active controls.",
        Default = Color3.fromRGB(255, 87, 90),
        Callback = function(color)
            window:SetAccent(color)
        end,
    })

    combat:SelectTab(recoil)
    task.defer(function()
        if accentPicker.Root.Parent then accentPicker:Open() end
    end)
    return window
end


-- API aliases keep the builder grammar familiar without creating duplicate owners.
Library.new = Library.CreateWindow
Library.Theme = THEME

WindowMethods.CreatePage = WindowMethods.AddPage
WindowMethods.CreateNotification = WindowMethods.Notify
PageMethods.CreateTab = PageMethods.AddTab
PageMethods.CreateSection = PageMethods.AddSection
TabMethods.CreateSection = TabMethods.AddSection
SectionMethods.CreateToggle = SectionMethods.AddToggle
SectionMethods.CreateSlider = SectionMethods.AddSlider
SectionMethods.CreateDropdown = SectionMethods.AddDropdown
SectionMethods.CreateButton = SectionMethods.AddButton
SectionMethods.CreateInput = SectionMethods.AddInput
SectionMethods.CreateKeybind = SectionMethods.AddKeybind
SectionMethods.CreateColorPicker = SectionMethods.AddColorPicker
SectionMethods.CreateParagraph = SectionMethods.AddParagraph
SectionMethods.CreateSeparator = SectionMethods.AddSeparator

function WindowMethods:GetPage(name: string): AnyObject?
    for _, page in ipairs(self._pages) do
        if not page._destroyed and page._name == name then
            return page
        end
    end
    return nil
end

function WindowMethods:SetTitle(value: string)
    self._title.Text = tostring(value)
end

function WindowMethods:SetSubtitle(value: string)
    self._subtitle.Text = tostring(value)
end

function WindowMethods:Center()
    self:_updateResponsive(true)
end

function PageMethods:GetTab(name: string): AnyObject?
    for _, tab in ipairs(self._tabs) do
        if not tab._destroyed and tab._name == name then
            return tab
        end
    end
    return nil
end

function TabMethods:GetSection(name: string): AnyObject?
    for _, section in ipairs(self._sections) do
        if not section._destroyed and section.Name == name then
            return section
        end
    end
    return nil
end

return table.freeze(Library)
