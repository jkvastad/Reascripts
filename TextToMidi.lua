-- http://lua-users.org/wiki/FileInputOutput
-- with modification for Reaper

local libPath = reaper.GetExtState("Testing","luaLibPath")
package.path = package.path..";"..libPath.."\\?.lua" --Not a path, but a ANSI C pattern: http://www.lua.org/pil/8.1.html
local noteUtils = require("noteUtils")


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


reaper.ShowConsoleMsg('Converting text to MIDI:\n')
reaper.ShowConsoleMsg(libPath)


-- tests the functions above, sanity check
local file = libPath..'Data\\note data.txt'
reaper.ShowConsoleMsg('file "'.. file.. '" exists: '.. tostring(file_exists(file))..'\n')
local lines = lines_from(file)

-- print all line numbers and their contents
for k,v in pairs(lines) do
	reaper.ShowConsoleMsg('line[' .. k .. ']'.. v..'\n')  
end


selectedTrack = reaper.GetSelectedTrack(0,0)
if not selectedTrack then
  reaper.ReaScriptError("!No track selected. Select a track.")
  os.exit()
else
  -- reaper.ShowConsoleMsg("selectedTrack is:"..select(2,reaper.GetTrackName(selectedTrack)).."\n")
end

cursorPosition = reaper.GetCursorPosition()
--reaper.ShowConsoleMsg("cursorPosition is:"..cursorPosition.."\n")
newMidiItem = reaper.CreateNewMIDIItemInProj(selectedTrack,cursorPosition,cursorPosition)
reaper.SetMediaItemLength(newMidiItem,10,true)
currentTake = reaper.GetTake(newMidiItem,0)

--[[
-- check note PPQPOS values
noteStart = reaper.MIDI_GetPPQPosFromProjQN(currentTake,1)
reaper.ShowConsoleMsg("noteStart is:"..noteStart.."\n")
noteEnd = reaper.MIDI_GetPPQPosFromProjQN(currentTake,2)
reaper.ShowConsoleMsg("noteEnd is:"..noteEnd.."\n")
--]]

--[[
TODO:
Add multiple notes
Read notes from file
Parse scientific pitch to MIDI
--]]


-- Thanks ChatGPT
local user_input_ok, user_input = reaper.GetUserInputs("Enter res_step_length PPQPOS", 1, "960 is a quarter note:", "")
local res_step_length = 960 --960 is quarter note

if user_input_ok then
  if user_input:match("^%d+$") then
    local number = tonumber(user_input)
    -- The user entered a valid number
    -- Use the 'number' variable for further processing
    res_step_length = number --960 is quarter note
    reaper.ShowConsoleMsg("res_step_length set to: " .. number)
  else
    -- The user did not enter a valid number
    reaper.ShowConsoleMsg("Invalid input. Please enter a number.")
  end
else
  -- The user canceled the dialog
  reaper.ShowConsoleMsg("Dialog canceled by the user.")
end

for k,v in pairs(lines) do
	local notes = noteUtils.stringToNotesAndOctaves(v)
	local note_start = 0
	local note_end = 0
	local note_MIDI_pitch = 60
	local first_note = true
	for i, set in ipairs(notes) do
		for j, note in ipairs(set) do
			if note.octave ~= nil then
				if not first_note then 
					reaper.MIDI_InsertNote(currentTake,false,false,note_start,note_end,0,note_MIDI_pitch,64,true)                    
				end
				first_note = false
				note_MIDI_pitch = noteUtils.toMIDIPitch(note.note,note.octave)
				note_start = note_end
			end
			note_end = note_end + res_step_length
		end
		reaper.MIDI_InsertNote(currentTake,false,false,note_start,note_end,0,note_MIDI_pitch,64,true)                    
	end
	reaper.MIDI_Sort(currentTake)
end


