local Library = loadstring(readfile("LibEight.lua"))()

local Window = Library:Window({
    Name = "Test Description",
    SubName = "Testing Description Property",
    Logo = "122669828593160"
})

local Page = Window:Page({
    Name = "Main",
    Icon = "122669828593160"
})

local Section = Page:Section({
    Name = "Automation",
    Description = "Configure automated systems and advanced behavior settings for your modules. This description is long enough to wrap around the container and test the automatic sizing functionality.",
    Side = 1,
    Icon = "bot" -- Assuming 'bot' is not a valid asset ID, it might fail or show nothing, but LibSeven has icon logic.
})

Section:Toggle({
    Name = "Test Toggle",
    Default = false
})

print("TestDescription.lua executed successfully")

Section:Slider({
    Name = "Test Slider",
    Default = 50,
    Min = 0,
    Max = 100,
    Suffix = "%",
    Decimals = 1,
    Callback = function(Value)
        print("Slider value is now " .. tostring(Value))
    end
})
