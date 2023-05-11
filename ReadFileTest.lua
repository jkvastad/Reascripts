-- http://lua-users.org/wiki/FileInputOutput
-- with modification for Reaper

local libPath = reaper.GetExtState("Testing","luaLibPath")

-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
  if not file_exists(file) then return {} end
  local lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return lines
end

reaper.ShowConsoleMsg('Testing read from file:\n')
reaper.ShowConsoleMsg(libPath)

-- tests the functions above
local file = libPath..'Data\\test.txt'
reaper.ShowConsoleMsg('file "'.. file.. '" exists: '.. tostring(file_exists(file))..'\n')
local lines = lines_from(file)


-- print all line numbers and their contents
for k,v in pairs(lines) do
	reaper.ShowConsoleMsg('line[' .. k .. ']'.. v..'\n')  
end
