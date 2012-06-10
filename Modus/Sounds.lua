local Sounds = {}

Sounds.wavs = { }
Sounds.counts = { bell = 16, breath = 16 }

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

local tones = Sounds.wavs[Settings.default.tone]
local tonecount = Sounds.counts[Settings.default.tone]

function Sounds.suppress(flag)
  Sounds.quiet = flag
end

function Sounds.playexact(tone, volume)
  if Sounds.quiet then
    return
  end
  local c = audio.play(tones[(tone - 1) % #tones + 1])
  Sounds.volume(c, volume)
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
  hue = hue or math.random(#Rainbow.hues)
  note = (hue - 1) % #Rainbow.hues + 1
  local off = ((octave or 0) * 5)
  off = off % (tonecount - 1)
  local c = audio.play(tones[note + off])
  Sounds.volume(c, volume)
end

function Sounds.play(hue, volume)
  if Sounds.quiet then
    return
  end
  local note = ((hue or math.random(#Rainbow.hues)) % #Rainbow.hues) + 1
  if note == 6 then
    offset = offset + 5
    if offset + note > tonecount then
      offset = 0
    end
  end
  -- Util.printf("hue %d, note %d, total %d", hue, note, note + offset)
  local c = audio.play(tones[note + offset])
  Sounds.volume(c, volume)
end

return Sounds
