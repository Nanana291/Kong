local Library = loadfile("LibTwo.lua")()

local Window = Library:Window({
    Name = "Example Window",
    SubName = "Priority Dropdown Showcase"
})

local Page = Window:Page({
    Name = "Main",
    Icon = "rbxassetid://123456789"
})

local Section = Page:Section({
    Name = "Features"
})

-- Priority Dropdown Example
Section:PriorityDropdown({
    Name = "Target Priority",
    Flag = "TargetPriorityFlag",
    Items = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},

    -- Default can be a list of strings (sets selected = true, priority = 1)
    -- or a table with details:
    Default = {
        ["Head"] = { Selected = true, Priority = 1 },
        ["Torso"] = { Selected = true, Priority = 2 },
        ["Left Arm"] = { Selected = false, Priority = 5 } -- You can define unselected items with priority too
    },

    Callback = function(OptionName, IsSelected, Priority)
        -- This callback fires whenever an option is toggled OR its priority changes
        print("Update -> Option:", OptionName, "| Selected:", IsSelected, "| Priority:", Priority)

        -- You can also access the full state via Library.Flags["TargetPriorityFlag"]
        local FullState = Library.Flags["TargetPriorityFlag"]
        for name, data in pairs(FullState) do
            if data.Selected then
                print("   Active:", name, "Priority:", data.Priority)
            end
        end
    end
})

-- To test updating it programmatically later:
--[[
task.wait(5)
print("Updating Dropdown Programmatically...")
Section.Elements[1]:Set({
    ["Head"] = { Selected = true, Priority = 10 },
    ["Torso"] = { Selected = false, Priority = 1 }
})
]]
