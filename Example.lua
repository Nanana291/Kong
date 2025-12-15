--[[
    Kong UI Library - Complete Example
    This file demonstrates all available elements and functions
]]

-- Load the library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nanana291/Kong/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nanana291/Kong/main/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nanana291/Kong/main/SaveManager.lua"))()

--// Create Window
local Window = Library:CreateWindow({
    Title = "Kong Library",
    Icon = "crown", -- Lucide icon name
    Size = UDim2.fromOffset(580, 460),
    Position = UDim2.fromOffset(100, 100),
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = false,
    ToggleKeybind = Enum.KeyCode.RightControl,
    NotifySide = "Right", -- "Left" or "Right"
    Footer = "Kong Library v1.0",
})

--// Create Tabs
local MainTab = Window:AddTab({
    Title = "Main",
    Icon = "home",
    Description = "Main features and controls",
})

local ElementsTab = Window:AddTab({
    Title = "Elements",
    Icon = "layout-grid",
    Description = "All available UI elements",
})

local NotifyTab = Window:AddTab({
    Title = "Notifications",
    Icon = "bell",
    Description = "Notification system examples",
})

local SettingsTab = Window:AddTab({
    Title = "Settings",
    Icon = "settings",
    Description = "Configuration and themes",
})

--// Main Tab Content
local MainLeftGroupbox = MainTab:AddLeftGroupbox("Welcome")
local MainRightGroupbox = MainTab:AddRightGroupbox("Quick Actions")

MainLeftGroupbox:AddLabel({
    Text = "Welcome to Kong UI Library!",
})

MainLeftGroupbox:AddDivider()

MainLeftGroupbox:AddLabel({
    Text = "This is a comprehensive UI library for Roblox with modern design and animations.",
    DoesWrap = true,
})

MainLeftGroupbox:AddSpacer(10)

MainLeftGroupbox:AddButton({
    Text = "Visit GitHub",
    Callback = function()
        setclipboard("https://github.com/Nanana291/Kong")
        Library:Notify({
            Title = "Copied!",
            Description = "GitHub link copied to clipboard",
            Type = "success",
            Time = 3,
        })
    end,
})

MainRightGroupbox:AddButton({
    Text = "Test Notification",
    Variant = "Default", -- "Default" or "Outline"
    Callback = function()
        Library:Notify({
            Title = "Hello!",
            Description = "This is a test notification",
            Type = "info",
            Time = 5,
        })
    end,
})

MainRightGroupbox:AddButton({
    Text = "Success Alert",
    Callback = function()
        Library:Notify({
            Title = "Success",
            Description = "Operation completed successfully",
            Type = "success",
            Time = 4,
        })
    end,
})

MainRightGroupbox:AddButton({
    Text = "Error Alert",
    Callback = function()
        Library:Notify({
            Title = "Error",
            Description = "Something went wrong",
            Type = "error",
            Time = 4,
        })
    end,
})

MainRightGroupbox:AddButton({
    Text = "Warning Alert",
    Callback = function()
        Library:Notify({
            Title = "Warning",
            Description = "Please be careful",
            Type = "warning",
            Time = 4,
        })
    end,
})

--// Elements Tab Content
local ToggleGroup = ElementsTab:AddLeftGroupbox("Toggles")
local SliderGroup = ElementsTab:AddLeftGroupbox("Sliders")
local InputGroup = ElementsTab:AddRightGroupbox("Inputs")
local DropdownGroup = ElementsTab:AddRightGroupbox("Dropdowns")

-- Toggle Examples
ToggleGroup:AddToggle("MyToggle", {
    Text = "Basic Toggle",
    Default = false,
    Tooltip = "This is a basic toggle",
    Callback = function(Value)
        print("Toggle changed to:", Value)
    end,
})

ToggleGroup:AddToggle("ToggleWithKeybind", {
    Text = "Toggle with Keybind",
    Default = true,
    Callback = function(Value)
        print("Keybind toggle:", Value)
    end,
}):AddKeyPicker("ToggleKeybind", {
    Default = "F",
    Mode = "Toggle", -- "Toggle", "Hold", "Always"
    Text = "Toggle Keybind",
})

ToggleGroup:AddToggle("ToggleWithColor", {
    Text = "Toggle with ColorPicker",
    Default = false,
    Callback = function(Value)
        print("Color toggle:", Value)
    end,
}):AddColorPicker("ToggleColor", {
    Default = Color3.fromRGB(129, 61, 212),
    Transparency = 0,
    Callback = function(Value)
        print("Color changed:", Value)
    end,
})

-- Slider Examples
SliderGroup:AddSlider("BasicSlider", {
    Text = "Basic Slider",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(Value)
        print("Slider value:", Value)
    end,
})

SliderGroup:AddSlider("PreciseSlider", {
    Text = "Precise Slider",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Callback = function(Value)
        print("Precise value:", Value)
    end,
})

SliderGroup:AddSlider("CompactSlider", {
    Text = "Compact Slider",
    Default = 25,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = true,
    Callback = function(Value)
        print("Compact slider:", Value)
    end,
})

-- Input Examples
InputGroup:AddInput("BasicInput", {
    Text = "Basic Input",
    Default = "",
    Placeholder = "Enter text...",
    Numeric = false,
    MaxLength = 50,
    Callback = function(Value)
        print("Input value:", Value)
    end,
})

InputGroup:AddInput("NumericInput", {
    Text = "Numeric Input",
    Default = "100",
    Placeholder = "Enter number...",
    Numeric = true,
    Callback = function(Value)
        print("Numeric value:", Value)
    end,
})

InputGroup:AddInput("AutoCompleteInput", {
    Text = "AutoComplete Input",
    Default = "",
    Placeholder = "Type to search...",
    AutoComplete = true,
    CompleteOptions = {"Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"},
    Callback = function(Value)
        print("AutoComplete value:", Value)
    end,
})

-- Dropdown Examples
DropdownGroup:AddDropdown("BasicDropdown", {
    Text = "Basic Dropdown",
    Values = {"Option 1", "Option 2", "Option 3", "Option 4"},
    Default = 1,
    Multi = false,
    Callback = function(Value)
        print("Dropdown value:", Value)
    end,
})

DropdownGroup:AddDropdown("MultiDropdown", {
    Text = "Multi-Select Dropdown",
    Values = {"Red", "Green", "Blue", "Yellow", "Purple"},
    Default = {"Red", "Blue"},
    Multi = true,
    Callback = function(Value)
        print("Multi dropdown:", Value)
    end,
})

DropdownGroup:AddDropdown("SearchableDropdown", {
    Text = "Searchable Dropdown",
    Values = {"Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta"},
    Default = 1,
    Searchable = true,
    Callback = function(Value)
        print("Searchable dropdown:", Value)
    end,
})

DropdownGroup:AddDropdown("PlayerDropdown", {
    Text = "Player Dropdown",
    SpecialType = "Player",
    Callback = function(Value)
        print("Selected player:", Value)
    end,
})

--// Notifications Tab Content
local NotifyTypesGroup = NotifyTab:AddLeftGroupbox("Notification Types")
local NotifyOptionsGroup = NotifyTab:AddRightGroupbox("Notification Options")

NotifyTypesGroup:AddButton({
    Text = "Info Notification",
    Callback = function()
        Library:Notify({
            Title = "Information",
            Description = "This is an info notification with the default accent color.",
            Type = "info",
            Time = 5,
        })
    end,
})

NotifyTypesGroup:AddButton({
    Text = "Success Notification",
    Callback = function()
        Library:Notify({
            Title = "Success!",
            Description = "The operation was completed successfully.",
            Type = "success",
            Time = 5,
        })
    end,
})

NotifyTypesGroup:AddButton({
    Text = "Error Notification",
    Callback = function()
        Library:Notify({
            Title = "Error",
            Description = "An error occurred while processing your request.",
            Type = "error",
            Time = 5,
        })
    end,
})

NotifyTypesGroup:AddButton({
    Text = "Warning Notification",
    Callback = function()
        Library:Notify({
            Title = "Warning",
            Description = "Please review your settings before continuing.",
            Type = "warning",
            Time = 5,
        })
    end,
})

NotifyTypesGroup:AddButton({
    Text = "Loading Notification",
    Callback = function()
        local Notif = Library:Notify({
            Title = "Loading...",
            Description = "Please wait while we process your request.",
            Type = "loading",
            Persist = true,
        })

        -- Simulate loading
        task.delay(3, function()
            Notif:SetType("success")
            Notif:ChangeTitle("Complete!")
            Notif:ChangeDescription("Your request has been processed.")
            task.delay(2, function()
                Notif:Destroy()
            end)
        end)
    end,
})

NotifyOptionsGroup:AddButton({
    Text = "With SubText",
    Callback = function()
        Library:Notify({
            Title = "Notification",
            Description = "This notification has additional subtext.",
            SubText = "Click here for more info",
            Type = "info",
            Time = 6,
        })
    end,
})

NotifyOptionsGroup:AddButton({
    Text = "With Buttons",
    Callback = function()
        Library:Notify({
            Title = "Confirm Action",
            Description = "Are you sure you want to proceed?",
            Type = "warning",
            Persist = true,
            Closable = false,
            Buttons = {
                {
                    Text = "Cancel",
                    Variant = "default",
                    Callback = function(notif)
                        notif:Destroy()
                    end,
                },
                {
                    Text = "Confirm",
                    Variant = "primary",
                    Callback = function(notif)
                        notif:SetType("success")
                        notif:ChangeTitle("Confirmed!")
                        notif:ChangeDescription("Action has been confirmed.")
                        task.delay(2, function()
                            notif:Destroy()
                        end)
                    end,
                },
            },
        })
    end,
})

NotifyOptionsGroup:AddButton({
    Text = "With Progress",
    Callback = function()
        local Notif = Library:Notify({
            Title = "Downloading...",
            Description = "Downloading file: example.zip",
            Type = "info",
            Progress = 0,
            Persist = true,
        })

        -- Simulate progress
        task.spawn(function()
            for i = 1, 100 do
                task.wait(0.05)
                Notif:SetProgress(i / 100)
                Notif:ChangeDescription(string.format("Downloading file: example.zip (%d%%)", i))
            end

            Notif:SetType("success")
            Notif:ChangeTitle("Download Complete!")
            Notif:ChangeDescription("File has been downloaded successfully.")
            task.delay(3, function()
                Notif:Destroy()
            end)
        end)
    end,
})

NotifyOptionsGroup:AddButton({
    Text = "Custom Color",
    Callback = function()
        Library:Notify({
            Title = "Custom Notification",
            Description = "This notification uses a custom color.",
            Type = "custom",
            Color = Color3.fromRGB(255, 100, 200),
            Icon = "heart",
            Time = 5,
        })
    end,
})

NotifyOptionsGroup:AddButton({
    Text = "Clickable Notification",
    Callback = function()
        Library:Notify({
            Title = "Click Me!",
            Description = "Click this notification to trigger an action.",
            Type = "info",
            Time = 8,
            OnClick = function(notif)
                notif:SetType("success")
                notif:ChangeTitle("Clicked!")
                notif:ChangeDescription("You clicked the notification!")
            end,
        })
    end,
})

NotifyOptionsGroup:AddButton({
    Text = "Wide Notification",
    Callback = function()
        Library:Notify({
            Title = "Wide Notification",
            Description = "This notification has a custom width of 400 pixels.",
            Type = "info",
            Width = 400,
            Time = 5,
        })
    end,
})

--// Settings Tab Content
local ThemeGroup = SettingsTab:AddLeftGroupbox("Theme")
local ConfigGroup = SettingsTab:AddRightGroupbox("Configuration")

-- Theme Manager Integration
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("Kong")
ThemeManager:ApplyToGroupbox(ThemeGroup)

-- Save Manager Integration
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("Kong/configs")
SaveManager:BuildConfigSection(ConfigGroup)
SaveManager:IgnoreThemeSettings()

-- Additional Settings
local MiscGroup = SettingsTab:AddLeftGroupbox("Miscellaneous")

MiscGroup:AddButton({
    Text = "Unload Library",
    Callback = function()
        Library:Notify({
            Title = "Unloading...",
            Description = "The library will be unloaded in 2 seconds.",
            Type = "warning",
            Time = 2,
        })
        task.delay(2, function()
            Library:Unload()
        end)
    end,
})

MiscGroup:AddButton({
    Text = "Copy Discord Invite",
    Callback = function()
        setclipboard("discord.gg/example")
        Library:Notify({
            Title = "Copied!",
            Description = "Discord invite link copied to clipboard.",
            Type = "success",
            Time = 3,
        })
    end,
})

MiscGroup:AddToggle("WatermarkToggle", {
    Text = "Show Watermark",
    Default = false,
    Callback = function(Value)
        -- Toggle watermark visibility
        print("Watermark:", Value)
    end,
})

--// Tabbox Example (Multiple tabs in one groupbox)
local TabboxGroup = ElementsTab:AddLeftTabbox("Tabbox Example")

local Tab1 = TabboxGroup:AddTab("Tab 1")
local Tab2 = TabboxGroup:AddTab("Tab 2")
local Tab3 = TabboxGroup:AddTab("Tab 3")

Tab1:AddToggle("Tab1Toggle", {
    Text = "Toggle in Tab 1",
    Default = false,
})

Tab1:AddSlider("Tab1Slider", {
    Text = "Slider in Tab 1",
    Default = 50,
    Min = 0,
    Max = 100,
})

Tab2:AddButton({
    Text = "Button in Tab 2",
    Callback = function()
        print("Tab 2 button clicked!")
    end,
})

Tab2:AddInput("Tab2Input", {
    Text = "Input in Tab 2",
    Default = "",
    Placeholder = "Type here...",
})

Tab3:AddLabel({
    Text = "This is Tab 3",
})

Tab3:AddDropdown("Tab3Dropdown", {
    Text = "Dropdown in Tab 3",
    Values = {"Choice A", "Choice B", "Choice C"},
    Default = 1,
})

--// Dependency Example
local DependencyGroup = ElementsTab:AddRightGroupbox("Dependencies")

local MainToggle = DependencyGroup:AddToggle("MainToggle", {
    Text = "Enable Feature",
    Default = false,
})

DependencyGroup:AddToggle("SubToggle1", {
    Text = "Sub-feature 1",
    Default = false,
}):SetDependency(MainToggle, true) -- Only visible when MainToggle is true

DependencyGroup:AddToggle("SubToggle2", {
    Text = "Sub-feature 2",
    Default = false,
}):SetDependency(MainToggle, true)

DependencyGroup:AddSlider("DependentSlider", {
    Text = "Dependent Slider",
    Default = 50,
    Min = 0,
    Max = 100,
}):SetDependency(MainToggle, true)

--// KeyPicker Modes Example
local KeyPickerGroup = ElementsTab:AddRightGroupbox("KeyPicker Modes")

KeyPickerGroup:AddLabel({
    Text = "Different KeyPicker modes:",
})

KeyPickerGroup:AddToggle("ToggleModeExample", {
    Text = "Toggle Mode",
    Default = false,
}):AddKeyPicker("ToggleModeKey", {
    Default = "G",
    Mode = "Toggle",
    Text = "Toggle Mode Key",
    Callback = function(Value)
        print("Toggle mode key:", Value)
    end,
})

KeyPickerGroup:AddToggle("HoldModeExample", {
    Text = "Hold Mode",
    Default = false,
}):AddKeyPicker("HoldModeKey", {
    Default = "H",
    Mode = "Hold",
    Text = "Hold Mode Key",
    Callback = function(Value)
        print("Hold mode key:", Value)
    end,
})

--// Initial notification
Library:Notify({
    Title = "Kong Library Loaded",
    Description = "Welcome! Explore all features in the tabs above.",
    Type = "success",
    Time = 5,
})

--// Accessing options later
--[[
    You can access any option by its index:

    Library.Options.MyToggle.Value -- Get toggle value
    Library.Options.MyToggle:SetValue(true) -- Set toggle value

    Library.Options.BasicSlider.Value -- Get slider value
    Library.Options.BasicSlider:SetValue(75) -- Set slider value

    Library.Options.BasicInput.Value -- Get input value
    Library.Options.BasicInput:SetValue("New text") -- Set input value

    Library.Options.BasicDropdown.Value -- Get dropdown value
    Library.Options.BasicDropdown:SetValue("Option 2") -- Set dropdown value
]]

--// Unload callback
Library:OnUnload(function()
    print("Kong Library has been unloaded!")
end)
