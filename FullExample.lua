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
local ToggleSettings = MyToggle:Settings() -- Adds a settings cog
MyToggle:Colorpicker({
    Flag = "AimbotColor",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Color, Alpha)
        print("Aimbot Color Changed:", Color)
    end
})

ToggleSection:Divider({Title = "Sliders"})

local MySlider = ToggleSection:Slider({
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

local MyDropdown = DropdownSection:Dropdown({
    Name = "Target Mode",
    Flag = "TargetDropdown",
    Items = {"Head", "Torso", "Random"},
    Default = "Head",
    Callback = function(Value)
        print("Target Mode:", Value)
    end
})

local MultiDropdown = DropdownSection:Dropdown({
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
local PrioDropdown = DropdownSection:PriorityDropdown({
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

local MyTextbox = InputSection:Textbox({
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

local MyKeybind = InputSection:Keybind({
    Name = "Panic Key",
    Flag = "PanicBind",
    Default = Enum.KeyCode.RightAlt,
    Mode = "Toggle", -- Toggle, Hold, or Always
    Callback = function(Active)
        print("Panic Key Active:", Active)
    end
})

local TextSection = InputTab:Section({Name = "Text & Visuals", Side = 2})

local MyLabel = TextSection:Label("This is a simple label")
local LabelColor = TextSection:Label("Label with Colorpicker"):Colorpicker({
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(Color)
        print("Label Color:", Color)
    end
})

TextSection:Divider() -- Simple line divider

local MyParagraph = TextSection:Paragraph({
    Name = "Important Info",
    Text = "This is a paragraph element.\nIt supports multiple lines of text.",
    Icon = "1234567890" -- Optional Asset ID
})

-- ============================================================================
-- Page 3: Lists & Tabboxes (Listbox, Nested Tabs)
-- ============================================================================
local ListTab = Window:Page({Name = "Lists & Tabs", Icon = "138827881557940", Columns = 2})

local ListSection = ListTab:Section({Name = "Listboxes", Side = 1})

local MyListbox = ListSection:Listbox({
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
-- Page 5: Runtime Updates (Showing off functions)
-- ============================================================================
local RuntimeTab = Window:Page({Name = "Functions", Icon = "138827881557940", Columns = 1})
local FuncSection = RuntimeTab:Section({Name = "Test Functions", Side = 1})

FuncSection:Paragraph({
    Name = "Instructions",
    Text = "Click the buttons below to trigger runtime updates on elements in other tabs."
})

FuncSection:Button({
    Name = "Update Label Text",
    Callback = function()
        MyLabel:SetText("Updated Text: " .. tostring(math.random(1, 100)))
        Window:SelectTab(InputTab)
    end
})

FuncSection:Button({
    Name = "Toggle Visibility (Label)",
    Callback = function()
        -- Toggles visibility of the label created on Page 2
        -- Note: We don't track visibility state here, just flipping it blindly or setting true/false
        MyLabel:SetVisibility(false)
        task.delay(1, function() MyLabel:SetVisibility(true) end)
        Window:SelectTab(InputTab)
    end
})

FuncSection:Button({
    Name = "Set Toggle State (True)",
    Callback = function()
        MyToggle:Set(true)
        Window:SelectTab(MainTab)
    end
})

FuncSection:Button({
    Name = "Set Slider Value (100)",
    Callback = function()
        MySlider:Set(100)
        Window:SelectTab(MainTab)
    end
})

FuncSection:Button({
    Name = "Refresh Dropdown List",
    Callback = function()
        MyDropdown:Refresh({"New A", "New B", "New C"})
        MyDropdown:Set("New A")
        Window:SelectTab(MainTab)
    end
})

FuncSection:Button({
    Name = "Update Paragraph",
    Callback = function()
        MyParagraph:SetTitle("Updated Title")
        MyParagraph:SetText("This paragraph has been updated via code at " .. os.time())
        Window:SelectTab(InputTab)
    end
})

FuncSection:Button({
    Name = "Set Textbox Value",
    Callback = function()
        MyTextbox:Set("Scripted Input")
        Window:SelectTab(InputTab)
    end
})

FuncSection:Button({
    Name = "Set Keybind (E)",
    Callback = function()
        MyKeybind:Set(Enum.KeyCode.E)
        Window:SelectTab(InputTab)
    end
})

FuncSection:Button({
    Name = "Update Listbox",
    Callback = function()
        MyListbox:Refresh({"Admin", "Mod", "User", "Guest"})
        MyListbox:Set("Admin")
        Window:SelectTab(ListTab)
    end
})

FuncSection:Button({
    Name = "Set Colorpicker (Blue)",
    Callback = function()
        LabelColor:Set(Color3.fromRGB(0, 0, 255))
        Window:SelectTab(InputTab)
    end
})

FuncSection:Button({
    Name = "Toggle Compact Mode",
    Callback = function()
        -- Toggles between icon-only and full text sidebar
        Window:SetCompact(not Window.Compact) -- Accessing internal state if exposed, or just flipping toggle
        -- Since Window.Compact is exposed in the table passed to creation, let's assume we can track it or toggle it.
        -- If Window object updates its .Compact property:
        -- Window:SetCompact(true/false)
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
