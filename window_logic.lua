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
                            if Value ~= Colorpicker then
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
                    Debounce = false
                    Items["ColorpickerWindow"].Instance.Visible = Colorpicker.IsOpen
                    task.wait(0.2)
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

            Items["ColorpickerButton"]:Connect("MouseButton1Down", function()
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

                    SavedColor:Connect("MouseButton1Down", function()
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
            local Items = { } do
                Items["Notification"] = Instances:Create("Frame", {
                    Parent = Library.NotifHolder.Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.3499999940395355,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Data.Title,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UIPadding", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["Description"] = Instances:Create("TextLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.30000001192092896,
                    Text = Data.Description,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 20),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.XY,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Description"]:AddToTheme({TextColor3 = "Text"})

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 0, 0, Items["Description"].Instance.AbsoluteSize.Y + Items["Title"].Instance.AbsoluteSize.Y + 12),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 0, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                local IconData = Library:GetCustomIcon(Data.Icon)
                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    Image = IconData and IconData.Url or "",
                    ImageRectOffset = IconData and IconData.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = IconData and IconData.ImageRectSize or Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0, 0),
                    Size = UDim2New(0, 16, 0, 16),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                if not Data.IconColor then
                    Instances:Create("UIGradient", {
                        Parent = Items["Icon"].Instance,
                        Name = "\0",
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                    end})
                else
                    Instances:Create("UIGradient", {
                        Parent = Items["Icon"].Instance,
                        Name = "\0",
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, Data.IconColor.Start), RGBSequenceKeypoint(1, Data.IconColor.End)}
                    })
                end
            end

            local Size = Items["Notification"].Instance.AbsoluteSize
            Items["Notification"].Instance.Size = UDim2New(0, 0, 0, 0)

            for Index, Value in Items do
                if Value.Instance:IsA("Frame") then
                    Value.Instance.BackgroundTransparency = 1
                elseif Value.Instance:IsA("TextLabel") then
                    Value.Instance.TextTransparency = 1
                elseif Value.Instance:IsA("ImageLabel") then
                    Value.Instance.ImageTransparency = 1
                end
            end

            task.wait(0.2)

            Items["Notification"].Instance.AutomaticSize = Enum.AutomaticSize.Y

            Library:Thread(function()
                for Index, Value in Items do
                    if Value.Instance:IsA("Frame") then
                        Value:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {BackgroundTransparency = 0})
                    elseif Value.Instance:IsA("TextLabel") then
                        Value:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {TextTransparency = 0})
                    elseif Value.Instance:IsA("ImageLabel") then
                        Value:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {ImageTransparency = 0})
                    end
                end

                Items["Notification"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {Size = UDim2New(0, Size.X, 0, Size.Y)})
                Items["Accent"]:Tween(TweenInfo.new(Data.Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Size = UDim2New(1, 0, 0, 6)})

                task.delay(Data.Duration + 0.15, function()
                    for Index, Value in Items do
                        if Value.Instance:IsA("Frame") then
                            Value:Tween(nil, {BackgroundTransparency = 1})
                        elseif Value.Instance:IsA("TextLabel") then
                            Value:Tween(nil, {TextTransparency = 1})
                        elseif Value.Instance:IsA("ImageLabel") then
                            Value:Tween(nil, {ImageTransparency = 1})
                        end
                    end

                    Items["Notification"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {Size = UDim2New(0, 0, 0, 0)})
                    task.wait(0.5)
                    Items["Notification"]:Clean()
                end)
            end)
        end

        Library.Window = function(self, Data)
            Data = Data or { }

            local Window = {
                Name = Data.Name or Data.name or "Window",
                SubName = Data.SubName or Data.subname or "Fine-tuning for sure wins",
                Logo = Data.Logo or Data.logo or "1l20959262762131",

                Pages = { },
                Items = { },
                IsOpen = false,
                CurrentAlignment = "LeftTabs"
            }

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

                if IsMobile then
                    Instances:Create("UIScale", {
                        Parent = Items["MainFrame"].Instance,
                        Name = "\0",
                        Scale = 0.699999988079071
                    })
                end

                Items["MainFrame"]:MakeResizeable(Vector2New(Items["MainFrame"].Instance.AbsoluteSize.X, Items["MainFrame"].Instance.AbsoluteSize.Y), Vector2New(9999, 9999), OriginalSizes)
                Library:MakeBlurred(Items["MainFrame"], Window)

                Items["LeftTabs"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    Visible = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.15,
                    Size = UDim2New(0, 225, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["LeftTabs"]:AddToTheme({BackgroundColor3 = "Background"})

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

                if IsMobile then
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
                end

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

                Items["CloseButton"]:Connect("MouseButton1Down", function()
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
                    if IsMobile then
                        Items["FloatingButton"].Instance.BackgroundTransparency = Library.Flags["BackgroundTransparency"]
                    end

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
                                SettingsItems["Settings"].Instance.Size = UDim2New(0, 325, 0, 230)
                            end)

                            for Index, Value in Library.OpenFrames do
                                if Value ~= Settings then
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
                            Debounce = false
                            SettingsItems["Settings"].Instance.Visible = Settings.IsOpen
                            task.wait(0.2)
                            SettingsItems["Settings"].Instance.Parent = not Settings.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                        end)
                    end

                    SettingsItems["CloseButton"]:Connect("MouseButton1Down", function()
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

                Window.Items = Items
            end

            local Debounce = false

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

            if IsMobile then
                Items["FloatingButton"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Window:SetOpen(not Window.IsOpen)
                    end
                end)
            end

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
                for __, Value in Window.Pages do
                    if Value.Active then
                        for _, Value2 in Value.Sections do
                            task.spawn(function()
                                Value2:TweenElements(true)
                            end)
                        end
                    end
                end
            end

            --[[Library:Connect(UserInputService.InputBegan, function(Input)
                if tostring(Input.KeyCode) == Library.MenuKeybind or tostring(Input.UserInputType) == Library.MenuKeybind then
                    Window:SetOpen(not Window.IsOpen)
                end
            end)]]

            Window:SetCenter()
            task.wait()
            Window:SetOpen(true)
            return setmetatable(Window, Library)
        end

        Library.Category = function(self, Name)
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
                    Size = UDim2New(0, 200, 0, 40),
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

                local PageIcon = Library:GetCustomIcon(Page.Icon)
                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 18, 0, 18),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = PageIcon and PageIcon.Url or "",
                    ImageRectOffset = PageIcon and PageIcon.ImageRectOffset or Vector2New(0, 0),
                    ImageRectSize = PageIcon and PageIcon.ImageRectSize or Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 16, 0.5, 0),
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

            function Page:Turn(Bool)
                if Debounce then
                    return
                end

                Page.Active = Bool

                Debounce = true
                Items["Page"].Instance.Visible = Bool
                Items["Page"].Instance.Parent = Bool and Page.Window.Items["Content"].Instance or Library.UnusedHolder.Instance

                if Page.Active then
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 0.25})
                    Items["Page"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})

                    for Index, Value in Page.Sections do
                        task.spawn(function()
                            Value:TweenElements(true)
                        end)
                    end
                else
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 1})
                    Items["Page"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 60)})
                end

                local AllInstances = Items["Page"].Instance:GetDescendants()
                TableInsert(AllInstances, Items["Page"].Instance)

                local NewTween

                for Index, Value in AllInstances do
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

                Library:Connect(NewTween.Tween.Completed, function()
                    Debounce = false

                    if not Page.Active then
                        for Index, Value in Page.Sections do
                            task.spawn(function()
                                Value:TweenElements(false, true)
                            end)
                        end
                    end
                end)
            end

            Items["Inactive"]:Connect("MouseButton1Down", function()
                for Index, Value in Page.Window.Pages do
                    if Value == Page and Page.Active then
                        return
                    end

                    Value:Turn(Value == Page)
                end
            end)

            if #Page.Window.Pages == 0 then
                Page:Turn(true)
            end

            TableInsert(Page.Window.Pages, Page)
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
