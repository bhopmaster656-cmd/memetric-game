.PHONY: build serve install

OUTPUT = EvergreenCounty.rbxlx

install:
	aftman install

build: install
	rojo build default.project.json -o $(OUTPUT)

serve: install
	rojo serve default.project.json
