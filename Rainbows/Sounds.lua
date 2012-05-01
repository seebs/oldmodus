local Sounds = {}

Sounds.wavs = {}

Sounds.offset = 0

for i = 2, 12 do
  local name = Util.sprintf("%03d.wav", i)
  local sound = audio.loadSound(name)
  table.insert(Sounds.wavs, sound)
end
audio.setVolume(0.4, 0)

function Sounds.play(hue)
  hue = (hue % 6) + 1 + Sounds.offset
  if hue == 6 or hue == 12 then
    if Sounds.offset == 6 then
      Sounds.offset = 0
      hue = 1
    else
      Sounds.offset = 6
    end
  end
  audio.play(Sounds.wavs[hue])
end

return Sounds
