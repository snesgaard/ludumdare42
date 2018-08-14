
src=$(wildcard src/*.aseprite)
jsons=$(addprefix ./build/, $(notdir $(src:.aseprite=.json)))
atlas=./atlas.png
info=./index.lua
aseprite=~/.steam/steam/steamapps/common/Aseprite/aseprite
texatlas_script=/repos/artwork_n_stuff/texatlas.py

all: create_build_dirs $(atlas)

debug:
	@echo $(jsons)

$(atlas): $(jsons)
	@python $(texatlas_script) $^ -i $(info) -s $(atlas)

build/%.json: src/%.aseprite
	@$(aseprite) -b $< --sheet $(@:.json=.png) --data $@ \
	           --list-slices  --trim --format json-array\
	           --list-tags

create_build_dirs:
	@mkdir -p build

clean:
	@rm -rf build
	@rm -f $(info)
	@rm -f $(atlas)
