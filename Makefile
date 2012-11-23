# Make white pixel versions of images.

SDK ?= SDK

default: run

IMAGES = $(wildcard *.png)

.SUFFIXES: .wng .png

.png.wng:
	convert $< -channel A -separate PNG:$*.alpha
	convert $< +matte -fill white -colorize 100% PNG:$*.box
	convert PNG:$*.box PNG:$*.box PNG:$*.box PNG:$*.alpha -channel RGBA -combine PNG32:$*.wng
	rm -f $*.box $*.alpha

images: $(patsubst %.png,%.wng,$(IMAGES))
	for img in $(IMAGES); do mv $${img%.png}.wng Modus/$${img%.png}-highlight.png; cp $$img Modus/.; done

run:
	/Applications/Corona$(SDK)/"Corona Terminal" Modus/main.lua

perf:
	/Applications/Corona$(SDK)/"Corona Terminal" Perftest/main.lua

ipa:
	(cd ~/Desktop; mkdir Payload; mv Modus.app Payload; zip -r Payload.zip Payload; mv Payload/Modus.app .; rmdir Payload; mv Payload.zip Payload.ipa)

perms:
	cp ~/Desktop/Modus.apk .; ./cleanperms Modus.apk
