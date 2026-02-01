-- InputListExample.lua
local Library = loadstring(readfile("LibThree.lua"))()

local Window = Library:Window({
    Name = "InputList Example",
    SubName = "Testing New Element",
    Logo = 122669828593160 -- Example logo
})

local Page = Window:Page({
    Name = "Main Page",
    Icon = 122669828593160
})

local Section = Page:Section({
    Name = "Test Section"
})

local InputList = Section:InputList({
    Name = "My Input List",
    Placeholder = "Add an item...",
    Callback = function(List)
        print("List Updated! Content:")
        for i, v in ipairs(List) do
            print(i, v)
        end
    end
})

Section:Button({
    Name = "Print List Table",
    Callback = function()
        local List = InputList:GetTable()
        print("Current List:")
        for i, v in ipairs(List) do
            print(i, v)
        end
    end
})

Section:Button({
    Name = "Add 'Hello'",
    Callback = function()
        InputList:Add("Hello")
    end
})

Section:Button({
    Name = "Remove 'Hello'",
    Callback = function()
        InputList:Remove("Hello")
    end
})
