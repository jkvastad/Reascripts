local function helloWorld()
	reaper.ShowMessageBox("Hello World from noteUtils", "Testing correct paths", 0)
end

local function getLengthFromTakeSource(take)
  return reaper.TimeMap_QNToTime(
    reaper.GetMediaSourceLength(
    reaper.GetMediaItemTake_Source(
    take)))
end

local function storeNote(notes, i, selected, muted, startppqpos, endppqpos, chan, pitch, vel)
  notes[i] = {}
  notes[i].selected = selected
  notes[i].muted = muted
  notes[i].startppqpos = startppqpos
  notes[i].endppqpos = endppqpos
  notes[i].chan = chan
  notes[i].pitch = pitch
  notes[i].vel = vel
end


local function notesInTake(take)
  local notes = {}
  local _, noteCount = reaper.MIDI_CountEvts(take)
  
    for i = 0, noteCount - 1 do
      local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i )
      storeNote(notes, i+1, selected, muted, startppqpos, endppqpos, chan, pitch, vel) -- lua uses 1 indexing
    end
  return notes
end


local function notesInSelectedItem()
  local item = reaper.GetSelectedMediaItem(0,0)
  if not item then 
    reaper.ShowMessageBox("No item selected! Select an item.", "Error in script", 0)
    reaper.ReaScriptError("!No item selected! Select an item.") 
  end
  return notesInTake((reaper.GetTake(item,0)))
end


local function newMIDIFromNotes(track, position, notes)
  local newMIDIItem = reaper.CreateNewMIDIItemInProj(track,position,position+1)
  local currentTake = reaper.GetTake(newMIDIItem,0)
  for _,note in pairs(notes) do
    reaper.MIDI_InsertNote(
    currentTake,
    note.selected,
    note.muted,
    note.startppqpos,
    note.endppqpos,
    note.chan,
    note.pitch,
    note.vel,
    true)
  end
  reaper.MIDI_Sort(currentTake)
  local newMIDILength = getLengthFromTakeSource(currentTake)
  reaper.SetMediaItemLength(newMIDIItem,newMIDILength,true)
  return newMIDIItem
end


local TWELVE_TET = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"} -- start at C as scientific pitch notation increments octaves at C
local NOTE_AS_MIDI = {}
for i,note in pairs(TWELVE_TET) do
  NOTE_AS_MIDI[note] = i+11 -- C0 is MIDI value 12
  --reaper.ShowConsoleMsg(note.." "..NOTE_AS_MIDI[note].." ")
end
local HARMONIC_AS_MIDI = {0,12,19,24,28,31,34,36,38,39} -- First 10 harmonics

local function toMIDIPitch(note,octave,harmonic)
  harmonic = harmonic or 1	  
  return NOTE_AS_MIDI[note] + octave*12 + HARMONIC_AS_MIDI[harmonic]
end

local function stringToNotesAndOctaves(notes_with_octaves)
-- thanks ChatGPT!

	local note_pattern = "([%ab#%-]+)(%d*)" -- pattern to match note and octave	

	local notes = {} -- table to store sets of notes

	for set in notes_with_octaves:gmatch("[^|]+") do -- iterate over sets separated by '|'
	  local set_notes = {} -- table to store notes in the current set
	  for note, octave in set:gmatch(note_pattern) do -- iterate over notes and octaves in the set
		octave = octave ~= "" and tonumber(octave) or nil -- convert octave to number, or nil if not present
		table.insert(set_notes, {note = note, octave = octave}) -- add note and octave as a tuple to the current set
	  end
	  table.insert(notes, set_notes) -- add current set to the list of sets
	end
	
	
	return notes
end

local function updateMIDIPitches(newMIDIPitches,notes)
  if #newMIDIPitches ~= #notes then
    reaper.ReaScriptError("!Number of pitches (" .. #newMIDIPitches .. ") does not match number of notes (" .. #notes .. ")\n")
  end
  for k in pairs(notes) do
    notes[k].pitch = newMIDIPitches[k]
  end
end


local function transposeMIDIToOctave(MIDIItem, note, octave)
  local newCentralPitch = toMIDIPitch(note,octave,1)
  local currentTake = reaper.GetTake(MIDIItem,0)
  local _, numberOfNotes = reaper.MIDI_CountEvts(currentTake)
  for i = 0, numberOfNotes do
    local _, _, _, _, _, _, notePitch = reaper.MIDI_GetNote(currentTake, i)
    local newNotePitch = notePitch
    while newNotePitch < newCentralPitch - 6 do newNotePitch = newNotePitch + 12 end
    while newNotePitch > newCentralPitch + 6 do newNotePitch = newNotePitch - 12 end
    reaper.MIDI_SetNote(currentTake, i, nil, nil, nil, nil, nil, newNotePitch, nil, nil)
    reaper.MIDI_Sort(currentTake)
  end
end 


return {
--functions
helloWorld = helloWorld,
notesInTake = notesInTake,
notesInSelectedItem = notesInSelectedItem,
newMIDIFromNotes = newMIDIFromNotes,
getLengthFromTakeSource = getLengthFromTakeSource,
toMIDIPitch = toMIDIPitch,
stringToNotesAndOctaves = stringToNotesAndOctaves,
updateMIDIPitches = updateMIDIPitches,
transposeMIDIToOctave = transposeMIDIToOctave,
--constants
TWELVE_TET = TWELVE_TET
}
