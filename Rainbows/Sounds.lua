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

function Sounds.play(hue)
  local note = ((hue or math.random(#Rainbow.hues)) % #Rainbow.hues) + 1
  local offset = 1
  if math.random(2) == 2 then
    offset = offset + 12
  end
  audio.play(Sounds.wavs[Sounds.scale[note] + offset])
end

return Sounds
