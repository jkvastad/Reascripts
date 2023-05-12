local libPath = reaper.GetExtState("Testing","luaLibPath")
package.path = package.path..";"..libPath
loadfile(libPath.."noteUtils.lua")()

-- Example harmonics pattern: "F3454646F#34546F365"
-- Reads as: "From fundamental tone F, octave 3, get MIDI pitch for harmonic 4, then 5, then 4, then 6 etc. until new fundamental tone F#, octave 3, etc...
-- Harmonics are lowered by two octaves for convenience
-- 9th harmonic is the highest allowed
local function harmonicsToMIDIPitches(harmonics)
  local harmonicsPattern = [[^(%u?#?)(%d)]]
  local currentFundamental = "Z"
  local currentOctave = 0
  local newMIDIPitches = {}
  local i = 0
  while true do
    i,j,note,number = string.find(harmonics,harmonicsPattern, i+1)
    if i == nil then break end
    if #note ~= 0 then
      i = j
      currentFundamental = note
      currentOctave = tonumber(number)
      goto continue
    end
    table.insert(newMIDIPitches,noteUtils.toMIDIPitch(currentFundamental,currentOctave - 2,tonumber(number))) -- primarily harmonics 456789 are used so offset with 2 octaves
    ::continue::
  end
  return newMIDIPitches
end

  
local function newHarmonicsFromPattern(pattern, fundamentals, octaves)
  if #fundamentals ~= #octaves then
    reaper.ReaScriptError("!Number of fundamentals (" .. #fundamentals .. ") does not match number of octaves (" .. #octaves .. ")\n")
  end
  
  local fundamentalsWithOctaves = {}
  for i in pairs(fundamentals) do
    fundamentalsWithOctaves[i] = fundamentals[i] .. octaves[i]
  end
  
  local newHarmonics = pattern
  for i,fundamentalWithOctave in pairs(fundamentalsWithOctaves) do
    newHarmonics = string.gsub(newHarmonics,"X", fundamentalWithOctave, 1)
  end
  
  return newHarmonics
end

-- Harmonics pattern e.g. "X454646X34546X65" where X is to be substituted for corresponding fundamental and octave in the collections
local function newHarmonicsCollection(harmonicsPattern, fundamentalsCollection, octavesCollection)
  if #fundamentalsCollection ~= #octavesCollection then
    reaper.ReaScriptError("!Number of fundamentalsCollection (" .. #fundamentalsCollection .. ") does not match number of octavesCollection (" .. #octavesCollection .. ")\n")
  end
  
  local harmonicsCollection = {}
  for i in pairs(fundamentalsCollection) do
    table.insert(harmonicsCollection,newHarmonicsFromPattern(harmonicsPattern,fundamentalsCollection[i], octavesCollection[i]))
  end
  
  return harmonicsCollection
end


local function notesCollectionFromHarmonicsCollection(notes,harmonicsCollection)
  local notesCollection = {}
  for _,harmonics in pairs(harmonicsCollection) do
    local newNotes = {}
    for i,note in pairs(notes)do
      local newNote = {}
      for k,v in pairs(note) do
        newNote[k] = v
      end
      newNotes[i] = newNote
    end
    local newMIDIPitches = harmonicsToMIDIPitches(harmonics)
    noteUtils.updateMIDIPitches(newMIDIPitches,newNotes)
    table.insert(notesCollection,newNotes)    
  end
  return notesCollection
end


local function newMIDIsFromNotesCollection(track, position, notesCollection, qnOffset)
  local currentPosition = position
  local newMIDIs = {}
  for _, notes in pairs(notesCollection) do
    local newMIDI = noteUtils.newMIDIFromNotes(track, currentPosition, notes)
    table.insert(newMIDIs,newMIDI)
    currentPosition = currentPosition + reaper.GetMediaItemInfo_Value(newMIDI, "D_LENGTH") + reaper.TimeMap_QNToTime(qnOffset)
  end
  return newMIDIs
end


-- local fundamentalsCollection, octavesCollection = harmonicUtils.allSimplePermutedFundamentals({"C","X","C"}, 3)
-- returns collections of the type {"C","C","C"}, {3,3,3}, {"C","C#","C"}, {3,3,3}, etc.
local function allSimplePermutedFundamentals(fundamentals, octave)    
  indexes = {}
  for k,v in pairs(fundamentals) do
    if v == "X" then table.insert(indexes,k) end
  end
  
  local fundamentalsCollection = {}
  for _, fundamental in pairs(noteUtils.TWELVE_TET) do
    local newFundamentals = {table.unpack(fundamentals)}
    for _,index in pairs(indexes) do
      newFundamentals[index] = fundamental
    end
    table.insert(fundamentalsCollection,newFundamentals)
  end    
  
  local octavesCollection = {}
  for i = 1, #noteUtils.TWELVE_TET do
    local octaves = {}
    for k = 1, #fundamentals do 
     octaves[k] = octave
    end
    octavesCollection[i] = octaves
  end
  
  return fundamentalsCollection, octavesCollection
end


return {
harmonicsToMIDIPitches = harmonicsToMIDIPitches,
newHarmonicsFromPattern = newHarmonicsFromPattern,
newHarmonicsCollection = newHarmonicsCollection,
notesCollectionFromHarmonicsCollection = notesCollectionFromHarmonicsCollection,
newMIDIsFromNotesCollection = newMIDIsFromNotesCollection,
allSimplePermutedFundamentals = allSimplePermutedFundamentals
}
