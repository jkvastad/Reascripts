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
      storeNote(notes, i, selected, muted, startppqpos, endppqpos, chan, pitch, vel)
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


local TWELVE_TET = {"A","A#","B","C","C#","D","D#","E","F","F#","G","G#"}
local NOTE_AS_MIDI = {}
for i,note in pairs(TWELVE_TET) do
  NOTE_AS_MIDI[note] = i+20 -- A0 is MIDI value 21
end
local HARMONIC_AS_MIDI = {0,12,19,24,28,31,34,36,38,39} -- First 10 harmonics

local function toMIDI(note,octave,harmonic)
  return NOTE_AS_MIDI[note] + octave*12 + HARMONIC_AS_MIDI[harmonic]
end

local FUNDAMENTAL_OCTAVE_HARMONIC = {}
for _,note in pairs(TWELVE_TET) do 
  local octaves = {}
  for octave=0,9 do
    local harmonics = {}
    for harmonic=1,10 do
      harmonics[harmonic] = toMIDI(note,octave,harmonic)
    end
    octaves[octave] = harmonics
  end
  FUNDAMENTAL_OCTAVE_HARMONIC[note] = octaves
end

-- E.g. getMIDIForFOH("A#",3,5)
local function getMIDIForFOH(fundamental, octave, harmonic)
  return FUNDAMENTAL_OCTAVE_HARMONIC[fundamental][octave][harmonic]
end


noteUtils = {
notesInTake = notesInTake,
notesInSelectedItem = notesInSelectedItem,
newMIDIFromNotes = newMIDIFromNotes,
getLengthFromTakeSource = getLengthFromTakeSource,
getMIDIForFOH = getMIDIForFOH
}
