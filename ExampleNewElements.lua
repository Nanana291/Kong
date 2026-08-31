local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/RepoOwner/RepoName/main/LibThree.lua"))()

local Window = Library:Window({
    Name = "New Elements Example",
    SubName = "Showcase",
    Logo = "123456789", -- Replace with an actual asset ID
    SelectedTab = 1
})

local Page = Window:Page({
    Name = "Showcase",
    Icon = "rbxassetid://123456789"
})

local Section = Page:Section({
    Name = "New Elements",
    Side = 1
})

-- Image Element
Section:Image({
    Image = "rbxassetid://4155801252", -- Example Image ID
    Size = UDim2.new(1, 0, 0, 100),
    ScaleType = Enum.ScaleType.Fit
})

-- ProgressBar Element
local Progress = Section:ProgressBar({
    Name = "Loading...",
    Default = 0.5,
    Color = Color3.fromRGB(0, 255, 0)
})

-- Demonstrate updating the progress bar
task.spawn(function()
    while true do
        for i = 0, 1, 0.01 do
            Progress:Set(i)
            task.wait(0.05)
        end
        task.wait(1)
        for i = 1, 0, -0.01 do
            Progress:Set(i)
            task.wait(0.05)
        end
        task.wait(1)
    end
end)

-- Standalone Colorpicker Element
Section:Colorpicker({
    Name = "Accent Color",
    Flag = "AccentColor",
    Default = Color3.fromRGB(255, 0, 0),
    Alpha = false,
    Callback = function(Color, Alpha)
        print("Color changed to:", Color)
    end
})

-- ChipSet Element
Section:ChipSet({
    Options = {"Apple", "Banana", "Cherry", "Date"},
    Default = {"Banana"},
    Callback = function(SelectedOptions)
        print("Selected chips:", table.concat(SelectedOptions, ", "))
    end
})
