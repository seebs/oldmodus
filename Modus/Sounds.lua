local Sounds = {}
local floor = math.floor

Sounds.wavs = { }
Sounds.counts = { bell = 16, breath = 16, off = 0 }
Sounds.names = { bell = "Metal Bell", breath = "Airy Bell", off = "Off" }
Sounds.offset = 0

for name, count in pairs(Sounds.counts) do
  Sounds.wavs[name] = {}
  for i = 1, count do
    local filename = Util.sprintf("%s%03d.wav", name, i)
    local sound = audio.loadSound(filename)
    table.insert(Sounds.wavs[name], sound)
  end
end
audio.setVolume(1.0, 0)

local timbre
local tones
local tonecount
local octavecount = 1

function Sounds.update()
  timbre = Settings.default_overrides.timbre or Settings.default.timbre
  tonecount = Sounds.counts[timbre] or 0
  octavecount = floor((tonecount - 6) / 5) + 1

  Sounds.wavs[timbre] = Sounds.wavs[timbre] or {}
  tones = Sounds.wavs[timbre]

  if tonecount == 0 then
    Sounds.quiet = true
  end

  if #tones < tonecount then
    for i = 1, tonecount do
      local filename = Util.sprintf("%s%03d.wav", name, i)
      local sound = audio.loadSound(filename)
      tones[#tones + 1] = sound
    end
  end
  Util.printf("Sound update: timbre %s, %d tones.", timbre, tonecount)
end

function Sounds.list()
  local names = {}
  for name, count in pairs(Sounds.names) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names, Sounds.names
end

function Sounds.suppress(flag)
  if tonecount == 0 then
    Sounds.quiet = true
  else
    Sounds.quiet = flag
  end
end

function Sounds.playexact(tone, volume)
  if Sounds.quiet then
    return
  end
  local c = audio.play(tones[(tone - 1) % #tones + 1])
  Sounds.volume(c, volume or 1.0)
end

local offset = 0

function Sounds.volume(c, volume)
  volume = (volume or 1)
  if c and c ~= 0 then
    audio.setVolume(volume, c)
  end
end

function Sounds.playoctave(hue, octave, volume)
  if Sounds.quiet then
    return
  end
  -- Util.printf("hue %d, octave %d", hue, octave)
  hue = hue or math.random(#Rainbow.hues)
  note = (hue - 1) % #Rainbow.hues + 1
  local off = (((octave or 0) % octavecount) * 5)
  off = off % (tonecount - 1)
  -- Util.printf("=> tone %d", note + off)
  local c = audio.play(tones[note + off])
  Sounds.volume(c, volume or 1.0)
end

local octave_changer = 6

function Sounds.play(hue, volume)
  if Sounds.quiet then
    return
  end
  local note = ((hue or math.random(#Rainbow.hues)) % #Rainbow.hues) + 1

  if note == octave_changer then
    offset = offset + 5
    octave_changer = ((octave_changer - 2) % #Rainbow.hues) + 1
    if offset + 6 > tonecount then
      offset = 0
    end
  end
  -- Util.printf("hue %d, note %d, total %d", hue, note, note + offset)
  local c = audio.play(tones[note + offset])
  Sounds.volume(c, volume or 1.0)
end

return Sounds
