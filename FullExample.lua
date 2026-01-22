--[[
    Full Example for LibTwo.lua
    Demonstrates practically all available elements and functions.
]]

-- 1. Load the Library
local Library = loadfile("LibTwo.lua")()

-- 2. Create the Window
local Window = Library:Window({
    Name = "Full Example Script",
    SubName = "Showcasing LibTwo Features",
    Logo = "120959262762131", -- Example Asset ID
    SelectedTab = 1, -- Selects the first tab by default
    Compact = false -- Set to true to hide sidebar text
})

-- 3. Create Keybind List
local KeybindList = Library:KeybindList("Keybinds")
KeybindList:SetVisibility(true)

-- ============================================================================
-- Page 1: Main Elements (Toggles, Sliders, Dropdowns)
-- ============================================================================
local MainTab = Window:Page({Name = "Main Elements", Icon = "138827881557940", Columns = 2})

-- Section 1: Toggles & Sliders (Left Side)
local ToggleSection = MainTab:Section({Name = "Toggles & Sliders", Side = 1})

ToggleSection:Label("Standard Toggle")
local MyToggle = ToggleSection:Toggle({
    Name = "Enable Aimbot",
    Flag = "AimbotToggle",
    Default = true,
    Callback = function(Value)
        print("Aimbot Toggled:", Value)
    end
})

-- Toggle with Settings (Keybind inside) and Colorpicker
MyToggle:Settings() -- Adds a settings cog
MyToggle:Colorpicker({
    Flag = "AimbotColor",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Color, Alpha)
        print("Aimbot Color Changed:", Color)
    end
})

ToggleSection:Divider({Title = "Sliders"})

ToggleSection:Slider({
    Name = "WalkSpeed",
    Flag = "WalkSpeedSlider",
    Min = 16,
    Max = 500,
    Default = 16,
    Suffix = " studs",
    Callback = function(Value)
        print("WalkSpeed:", Value)
    end
})

ToggleSection:Slider({
    Name = "Precise Slider",
    Flag = "PreciseSlider",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Decimals = 2,
    Suffix = "%",
    Callback = function(Value)
        print("Precise Value:", Value)
    end
})

-- Section 2: Dropdowns (Right Side)
local DropdownSection = MainTab:Section({Name = "Dropdowns", Side = 2})

DropdownSection:Dropdown({
    Name = "Target Mode",
    Flag = "TargetDropdown",
    Items = {"Head", "Torso", "Random"},
    Default = "Head",
    Callback = function(Value)
        print("Target Mode:", Value)
    end
})

DropdownSection:Dropdown({
    Name = "Multi Selection",
    Flag = "MultiDropdown",
    Items = {"Esp Box", "Esp Tracers", "Esp Name", "Esp Health"},
    Default = {"Esp Box", "Esp Name"},
    Multi = true,
    Callback = function(Value)
        print("Multi Selection:", table.concat(Value, ", "))
    end
})

DropdownSection:Divider({Title = "Priority Dropdown"})

-- New Priority Dropdown
DropdownSection:PriorityDropdown({
    Name = "Target Priority",
    Flag = "PriorityList",
    Items = {"Players", "NPCs", "Bosses"},
    Default = {Players = {Selected = true, Priority = 1}}, -- Advanced default state
    Callback = function(Name, Selected, Priority)
        print("Priority Update:", Name, Selected, Priority)
    end
})

-- ============================================================================
-- Page 2: Inputs & Text (Textboxes, Keybinds, Labels)
-- ============================================================================
local InputTab = Window:Page({Name = "Inputs & Text", Icon = "138827881557940", Columns = 2})

local InputSection = InputTab:Section({Name = "User Input", Side = 1})

InputSection:Textbox({
    Name = "Player Name",
    Flag = "PlayerTextbox",
    Placeholder = "Enter name...",
    Callback = function(Text)
        print("Textbox Input:", Text)
    end
})

InputSection:Textbox({
    Name = "Teleport Delay",
    Flag = "NumTextbox",
    Placeholder = "Seconds",
    Numeric = true,
    Finished = true, -- Only fires callback on Enter/FocusLost
    Callback = function(Value)
        print("Numeric Input:", Value)
    end
})

InputSection:Keybind({
    Name = "Panic Key",
    Flag = "PanicBind",
    Default = Enum.KeyCode.RightAlt,
    Mode = "Toggle", -- Toggle, Hold, or Always
    Callback = function(Active)
        print("Panic Key Active:", Active)
    end
})

local TextSection = InputTab:Section({Name = "Text & Visuals", Side = 2})

TextSection:Label("This is a simple label")
TextSection:Label("Label with Colorpicker"):Colorpicker({
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(Color)
        print("Label Color:", Color)
    end
})

TextSection:Divider() -- Simple line divider

TextSection:Paragraph({
    Name = "Important Info",
    Text = "This is a paragraph element.\nIt supports multiple lines of text.",
    Icon = "1234567890" -- Optional Asset ID
})

-- ============================================================================
-- Page 3: Lists & Tabboxes (Listbox, Nested Tabs)
-- ============================================================================
local ListTab = Window:Page({Name = "Lists & Tabs", Icon = "138827881557940", Columns = 2})

local ListSection = ListTab:Section({Name = "Listboxes", Side = 1})

ListSection:Listbox({
    Name = "Player List",
    Flag = "PlayerList",
    Items = {"Player1", "Player2", "Player3", "Player4", "Player5"},
    Size = 150, -- Height in pixels
    Callback = function(Value)
        print("Selected Player:", Value)
    end
})

local TabboxSection = ListTab:Section({Name = "Nested Tabboxes", Side = 2})

-- Add a Tabbox inside a Section (Left variant aligned)
local MyTabbox = TabboxSection:AddLeftTabbox("My Tabbox")

-- Add Tabs to the Tabbox
local Tab1 = MyTabbox:AddTab("Settings")
local Tab2 = MyTabbox:AddTab("Credits")

-- Add elements to Tabs
Tab1:Toggle({Name = "Tab Toggle", Callback = print})
Tab1:Label("This is inside a Tabbox!")

Tab2:Paragraph({Name = "Created By", Text = "Your Name Here"})
Tab2:Button({Name = "Click Me", Callback = function() print("Button Clicked") end})

-- ============================================================================
-- Page 4: Misc & Verification (Discord, Notifications)
-- ============================================================================
local MiscTab = Window:Page({Name = "Misc", Icon = "138827881557940", Columns = 2})

local DiscordSection = MiscTab:Section({Name = "Community", Side = 1})

-- New Discord Element
DiscordSection:Discord({
    Name = "Project Obsidian", -- Server Name
    InviteLink = "https://discord.gg/inviteCodeHere", -- Full Link or Code
    TargetServerID = "1287193618226090005" -- Optional: Verifies server ID
})

local NotifSection = MiscTab:Section({Name = "Notifications", Side = 2})

NotifSection:Button({
    Name = "Send Notification",
    Callback = function()
        Library:Notification({
            Title = "Success",
            Description = "Operation completed successfully!",
            Duration = 5,
            Icon = "138827881557940"
        })
    end
})

NotifSection:Button({
    Name = "Select Main Tab",
    Callback = function()
        Window:SelectTab(MainTab)
    end
})

-- ============================================================================
-- Initialization Complete
-- ============================================================================

-- Send a welcome notification
Library:Notification({
    Title = "Welcome",
    Description = "Full Example Script Loaded",
    Duration = 5
})

print("UI Loaded!")
