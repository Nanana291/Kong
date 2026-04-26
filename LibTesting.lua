--[[
    Imp Hub X UI safe loader.
    Keep this file small and syntax-safe so load failures show the real stage/error.
]]

local UI_URL = "https://raw.githubusercontent.com/Nanana291/Kong/refs/heads/main/LibSeventy.lua"
local TypeOf = typeof or type

local function FormatError(Stage, Message)
    return string.format("[Imp Hub X UI Loader] %s failed for %s\n%s", Stage, UI_URL, tostring(Message))
end

local function Raise(Stage, Message)
    error(FormatError(Stage, Message), 0)
end

local HttpOk, Source = pcall(function()
    return game:HttpGet(UI_URL)
end)

if not HttpOk then
    Raise("HttpGet", Source)
end

if type(Source) ~= "string" or Source == "" then
    Raise("HttpGet", "empty or non-string response: " .. TypeOf(Source))
end

if type(loadstring) ~= "function" then
    Raise("loadstring", "loadstring is not available/enabled in this executor")
end

local Chunk, CompileError = loadstring(Source)
if type(Chunk) ~= "function" then
    Raise("compile", CompileError or "loadstring returned nil without an error message")
end

local function Traceback(ErrorMessage)
    if debug and type(debug.traceback) == "function" then
        return debug.traceback(tostring(ErrorMessage), 2)
    end

    return tostring(ErrorMessage)
end

local RunOk, Library = xpcall(Chunk, Traceback)
if not RunOk then
    Raise("runtime", Library)
end

if type(Library) ~= "table" then
    Raise("return", "expected Library table, got " .. TypeOf(Library))
end

return Library
