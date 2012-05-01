# Make white pixel versions of images.

default: images

IMAGES = $(wildcard *.png)

.SUFFIXES: .wng .png

.png.wng:
	convert $< -channel A -separate PNG:$*.alpha
	convert $< +matte -fill white -colorize 100% PNG:$*.box
	convert PNG:$*.box PNG:$*.box PNG:$*.box PNG:$*.alpha -channel RGBA -combine PNG32:$*.wng
	rm -f $*.box $*.alpha

images: $(patsubst %.png,%.wng,$(IMAGES))
	for img in $(IMAGES); do mv $${img%.png}.wng mojo/$${img%.png}-highlight.png; cp $$img mojo/.; done

run:
	/Applications/CoronaSDK/simulator Rainbows/main.lua
