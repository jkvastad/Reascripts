-- Using Luas debug library, see https://www.lua.org/pil/23.1.html
local info = debug.getinfo(1,'S')
-- Using Luas string library's match function with pattern for directories
-- For match function see https://www.lua.org/manual/5.4/manual.html#pdf-string.match
-- For Lua patterns see https://www.lua.org/pil/20.2.html and https://www.lua.org/manual/5.4/manual.html#6.4.1
local libPath = info.source:match[[^@?(.*[\/])[^\/]-$]]
local section = "Testing"
local key = "luaLibPath"

reaper.SetExtState("Testing", "luaLibPath", libPath, true)
reaper.ShowMessageBox("The section "..section.." has set the key "..key.." to "..libPath, "Reaper Info", 0)

--[[
-- Run setLibPath in the folder you wish to use as a library folder. (Run it by going into reaper, choose Actions -> Show action list... -> New Action... -> Load ReaScript -> navigate to this .lua file, wherever it may be)
-- After running the above, use it in your lua files with e.g.
local libPath = reaper.GetExtState("Testing","luaLibPath")
package.path = package.path..";"..libPath
loadfile(libPath.."noteUtils.lua")()
noteUtils.doSomething(neat)
--]]