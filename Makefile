ENVFILE ?= .env
include $(ENVFILE)
export $(shell sed 's/=.*//' $(ENVFILE))

.PHONY: tiles
.ONESHELL:

all: tiles localhost

tiles: data/muenster-regbez.osm.pbf
	tilemaker $< --output=tiles/ --config resources/config-mapstew.json --process resources/process-mapstew.lua
	jq '.tiles = ["<URL_PREFIX>/tiles/{z}/{x}/{y}.pbf"]' tiles/metadata.json >tiles/metadata.json.bak
	mv tiles/metadata.json.bak tiles/metadata.json
	osmconvert $< --out-timestamp | TZ=Europe/Berlin xargs date --iso-8601=minutes -d >tiles/timestamp

clean:
	rm -rf tiles/ data/ && git reset --hard

data/muenster-regbez.osm.pbf:
	scripts/get-pbf-file.sh

localhost:
	ls *html tiles/metadata.json styles/* | xargs sed -i 's#<URL_PREFIX>#http://localhost:8000#'
	# This script launch a simple server which enables CORS, so can co-works with Maputnik to tune styles
	scripts/simple_cors_server.py &
	xdg-open http://localhost:8000
