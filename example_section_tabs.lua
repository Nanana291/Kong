local Library = loadfile("LibTwo.lua")()

local Window = Library:Window({
    Name = "Section Tabbox Example",
    SubName = "Demonstrating Tabboxes inside Sections",
    Logo = 12345678,
    Compact = false
})

local Page = Window:Page({Name = "Main"})

-- Create a Section
local Section = Page:Section({Name = "Tabbox Container", Side = 1})

Section:Label("This is a normal section label.")

-- 1. Add a Left Tabbox to the Section
-- Note: 'AddLeftTabbox' and 'AddRightTabbox' are aliases for 'Tabbox' in Sections,
-- but they are kept for consistency with Page-level tabboxes.
local LeftBox = Section:AddLeftTabbox()

local Tab1 = LeftBox:AddTab("Settings")
Tab1:Toggle({Name = "Enabled", Default = true})
Tab1:Slider({Name = "Speed", Default = 16, Min = 0, Max = 100})

local Tab2 = LeftBox:AddTab("Visuals")
Tab2:Label("ESP Settings")
Tab2:Colorpicker({Name = "ESP Color", Default = Color3.fromRGB(255, 0, 0)})

Section:Divider({Title = "Separator"})

-- 2. Add a Right Tabbox to the Section
local RightBox = Section:AddRightTabbox()

local Tab3 = RightBox:AddTab("Misc")
Tab3:Button({Name = "Server Hop", Callback = function() print("Hopping...") end})

local Tab4 = RightBox:AddTab("Credits")
Tab4:Label("Created by Jules")
Tab4:Label("UI Library: LibTwo")
