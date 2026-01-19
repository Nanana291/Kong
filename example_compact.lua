local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violines-and-ots/violines-and-ots/refs/heads/main/LibTwo.lua"))()

local Window = Library:Window({
    Name = "Compact Mode Example",
    SubName = "Streamlined UI",
    Logo = "1234567890",
    Compact = true -- Start in compact mode
})

local Page = Window:Page({Name = "Main", Icon = "rbxassetid://1234567890"})

local Section = Page:Section({Name = "Features", Side = 1})

Section:Toggle({
    Name = "Compact Mode",
    Default = true,
    Callback = function(Value)
        Window:SetCompact(Value)
    end
})

Section:Discord({
    Name = "Imp Hub X",
    InviteLink = "https://discord.gg/fe4x5yXCFB"
})
