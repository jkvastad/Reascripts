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
end
local HARMONIC_AS_MIDI = {0,12,19,24,28,31,34,36,38,39} -- First 10 harmonics

local function toMIDIPitch(note,octave,harmonic)
  return NOTE_AS_MIDI[note] + octave*12 + HARMONIC_AS_MIDI[harmonic]
end


local function updateMIDIPitches(newMIDIPitches,notes)
  if #newMIDIPitches ~= #notes then
    reaper.ReaScriptError("!Number of pitches (" .. #newMIDIPitches .. ") does not match number of notes (" .. #notes .. ")\n")
  end
  for k in pairs(notes) do
    notes[k].pitch = newMIDIPitches[k]
  end
end


local function harmonicsToMIDI(harmonics)
  local harmonicsPattern = [[^(%u?#?)(%d)]]
  currentFundamental = "Z"
  currentOctave = 0
  newMIDIPitches = {}
  i = 0
  while true do
    i,j,note,number = string.find(harmonics,harmonicsPattern, i+1)
    if i == nil then break end
    if #note ~= 0 then
      i = j
      currentFundamental = note
      currentOctave = tonumber(number)
      goto continue
    end
    table.insert(newMIDIPitches,toMIDIPitch(currentFundamental,currentOctave - 2,tonumber(number))) -- primarily harmonics 456789 are used so offset with 2 octaves
    ::continue::
  end
  return newMIDIPitches
end


noteUtils = {
notesInTake = notesInTake,
notesInSelectedItem = notesInSelectedItem,
newMIDIFromNotes = newMIDIFromNotes,
getLengthFromTakeSource = getLengthFromTakeSource,
updateMIDIPitches = updateMIDIPitches,
harmonicsToMIDI = harmonicsToMIDI,
toMIDIPitch = toMIDIPitch
}
