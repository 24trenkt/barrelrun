
# when creating new .asm files add them to the following list
SOURCES = src/graphics.asm src/main.asm
OBJECTS = $(patsubst src/%.asm,build/%.o,$(SOURCES))

.PHONY: all clean

all: game.gb

game.gb: $(OBJECTS)
	rgblink --dmg --tiny --map game.map --sym game.sym -o game.gb $(OBJECTS)
	rgbfix -v -p 0xFF game.gb

build/%.o: src/%.asm src/*.inc assets/*.tlm assets/*.chr | build
	rgbasm -o $@ $<

build:
	mkdir -p build

clean:
	rm -rf build
	rm game.gb game.map game.sym
