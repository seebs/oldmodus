local Sounds = {}

Sounds.wavs = {}

Sounds.offset = 0

Sounds.scale = { 0, 3, 5, 7, 10, 12 }

for i = 1, 25 do
  local name = Util.sprintf("bell%03d.wav", i)
  local sound = audio.loadSound(name)
  table.insert(Sounds.wavs, sound)
end
audio.setVolume(0.7, 0)

function Sounds.playexact(tone, volume)
  local c = audio.play(Sounds.wavs[(tone - 1) % #Sounds.wavs + 1])
  if c then
    audio.setVolume(volume or 0.7, c)
  end
end

function Sounds.play(hue)
  local note = ((hue or math.random(#Rainbow.hues)) % #Rainbow.hues) + 1
  local offset = 1
  if math.random(2) == 2 then
    offset = offset + 12
  end
  local c = audio.play(Sounds.wavs[Sounds.scale[note] + offset])
  if c then
    audio.setVolume(0.7, c)
  end
end

return Sounds
