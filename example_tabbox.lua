local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violines-and-ots/violines-and-ots/refs/heads/main/LibTwo.lua"))()

local Window = Library:Window({
    Name = "Tabbox Example",
    SubName = "Advanced Layouts",
    Logo = "1234567890",
    Compact = false
})

local Page = Window:Page({Name = "Main", Icon = "rbxassetid://1234567890"})

-- Left Tabbox
local LeftTabBox = Page:AddLeftTabbox()

-- Icon tab 1
local IconTab = LeftTabBox:AddTab("trending-up")
IconTab:Label("This is the Trending tab")
IconTab:Button({Name = "Click Me", Callback = function() print("Clicked") end})

-- Icon tab 2
local SettingsTab = LeftTabBox:AddTab("settings")
SettingsTab:Label("This is the Settings tab")
SettingsTab:Toggle({Name = "Enabled", Default = true})

-- Right Tabbox
local RightTabBox = Page:AddRightTabbox()
local InfoTab = RightTabBox:AddTab("info")
InfoTab:Paragraph({Title = "Information", Text = "This is a right tabbox with an info icon."})

local UsersTab = RightTabBox:AddTab("users")
UsersTab:Label("User Management")
