local Library = loadstring(readfile("LibThree.lua"))()

-- 1. Create the Window
local Window = Library:Window({
    Name = "AutoLoad Example",
    SubName = "Configuration System",
    Logo = 122669828593160, -- Example Asset ID
    Compact = false,
    SelectedTab = 1
})

-- 2. Create Tabs and Sections
local MainTab = Window:Page({
    Name = "Main",
    Icon = "pencil" -- Lucide icon name
})

local MainSection = MainTab:Section({
    Name = "Features",
    Side = 1
})

-- 3. Add Elements (These will be saved/loaded)
MainSection:Toggle({
    Name = "Enable Aimbot",
    Flag = "AimbotEnabled", -- Unique flag is required for saving
    Default = false,
    Callback = function(Value)
        print("Aimbot:", Value)
    end
})

MainSection:Slider({
    Name = "WalkSpeed",
    Flag = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 100,
    Decimals = 1,
    Callback = function(Value)
        if game.Players.LocalPlayer and game.Players.LocalPlayer.Character then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end
})

MainSection:InputList({
    Name = "Whitelisted Players",
    Flag = "Whitelist",
    Placeholder = "Player Name",
    Callback = function(List)
        print("Whitelist updated:", table.concat(List, ", "))
    end
})

-- 4. Create the Settings Page
-- This adds the "Configs" section where you can Save, Load, and "Set As Autoload"
Library:CreateSettingsPage(Window)

-- 5. Load the Autoload Config
-- Call this at the very end to automatically load the config marked as 'Autoload'
Library:LoadAutoloadConfig()
