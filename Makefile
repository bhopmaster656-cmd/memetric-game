GAME_FILE := CityLife.rbxlx

.PHONY: all build clean

all: build

build: $(GAME_FILE)

$(GAME_FILE): default.project.json $(shell find src -type f)
	rojo build default.project.json -o $(GAME_FILE)

clean:
	rm -f $(GAME_FILE)

serve:
	rojo serve default.project.json
