#!/usr/bin/ruby -w

$rainbows = %w{red orange yellow green blue purple}
modes = [
  "Spiraling Shape",
  "Painting Hexes",
  "Knights",
  "Bouncing Spline",
  "Cascade",
  "Lissajous Figures",
  "Raindrops",
  "Spiraling Shapes",
  "Wandering Color",
  "Cascade 2",
  "Bouncing Lines",
  "Knights 2",
]

$counter = 0

def nr()
  r = $rainbows[$counter]
  $counter = ($counter + 1) % $rainbows.length
  r
end

out = ""
#"Miracle Modus".each_char do |c|
#  if c.match(%r{\W})
#    out << c
#  else
#    out << "<span class='neon_#{rainbows[counter]}'>#{c}</span>"
#    counter = (counter + 1) % rainbows.length
#  end
#end
#puts out

modes.each do |m|
  puts "    <div>"
  puts "    <h4 class='neon_#{nr()}'>#{m}</h4>"
  puts "      <div class='illo'><a name='#{m}'><img src='images/13.17.49.png' alt='screen shot'></a></div>"
  puts "      <div class='indent'>"
  puts "      <p><span class='neon_#{nr()}'>Shapes:</span> </p>"
  puts "      <p><span class='neon_#{nr()}'>Sounds:</span> </p>"
  puts "      <p><span class='neon_#{nr()}'>Interaction:</span> </p>"
  puts "      <p><span class='neon_#{nr()}'>Notes:</span> </p>"
  puts "      </div>"
  puts "    </div>"
  nr()
  nr()
end
