GRPC_SWIFT_VERSION ?= 0.1.13

all: build push

build/export-lib-$(GRPC_SWIFT_VERSION).tar: ./swift/export-protoc-gen-swift/Dockerfile ./swift/export-protoc-gen-swift/export-libs
	mkdir -p build
	cd ./swift/export-protoc-gen-swift && docker run --rm -v$(PWD)/build:/export `docker build -q .` $(GRPC_SWIFT_VERSION) 

build: ./swift/resources/ld_library_path.patch build/export-lib-$(GRPC_SWIFT_VERSION).tar
	docker build --build-arg GRPC_SWIFT_VERSION=$(GRPC_SWIFT_VERSION) -t thethingsindustries/protoc .

push: build
	docker push thethingsindustries/protoc

clean:
	rm -rf build

.PHONY: all deps build push clean
