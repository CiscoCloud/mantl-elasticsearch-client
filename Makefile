.PHONY: all build

all: build

build:
	docker build -t mantl-elasticsearch-client --rm .
