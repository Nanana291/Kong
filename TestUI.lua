local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/LibThree.lua"))()

local Window = Library:Window({
    Name = "Test UI",
    SubName = "New Elements",
    Logo = 12345678,
    Compact = false,
    SelectedTab = 1
})

local Page = Window:Page({Name = "Main"})

local Section = Page:Section({Name = "Input List Test", Side = 1}) do
    local MyInputList = Section:InputList({
        Name = "Whitelist",
        Flag = "WhitelistList",
        Default = {"User1", "User2"},
        Placeholder = "Add user...",
        Callback = function(List)
            print("InputList Changed:", table.concat(List, ", "))
        end
    })

    Section:Button({
        Name = "Add 'Admin' to InputList",
        Callback = function()
            MyInputList:Add("Admin")
        end
    })

    Section:Button({
        Name = "Clear InputList",
        Callback = function()
            MyInputList:Clear()
        end
    })
end

local Section2 = Page:Section({Name = "Sortable List Test", Side = 2}) do
    local MySortableList = Section2:SortableList({
        Name = "Priority Queue",
        Flag = "PriorityList",
        Default = {"First", "Second", "Third"},
        Callback = function(List)
            print("SortableList Changed:", table.concat(List, ", "))
        end
    })

    Section2:Button({
        Name = "Add 'Last' to Queue",
        Callback = function()
            MySortableList:Add("Last")
        end
    })

    Section2:Button({
        Name = "Move 'Second' Up",
        Callback = function()
            MySortableList:MoveUp("Second")
        end
    })
end
