![](https://github.com/TheThingsIndustries/docker-protobuf/workflows/Docker%20Image/badge.svg)

# Protocol Buffers + Docker
A lightweight `protoc` Docker image.
It started out as https://github.com/znly/docker-protobuf fork, but grew into a stand-alone project.

## What's included:
- [envoyproxy/protoc-gen-validate](https://github.com/envoyproxy/protoc-gen-validate)
- [mwitkow/go-proto-validators](https://github.com/mwitkow/go-proto-validators)
- [gogo/protobuf](https://github.com/gogo/protobuf)
- [golang/protobuf](https://github.com/golang/protobuf)
- [google/protobuf](https://github.com/google/protobuf)
- [grpc-ecosystem/grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway)
- [grpc/grpc](https://github.com/grpc/grpc)
- [pseudomuto/protoc-gen-doc](https://github.com/pseudomuto/protoc-gen-doc)
- [TheThingsIndustries/protoc-gen-fieldmask](https://github.com/TheThingsIndustries/protoc-gen-fieldmask)
- [TheThingsIndustries/protoc-gen-gogottn](https://github.com/TheThingsIndustries/protoc-gen-gogottn)

## Supported languages
- C#
- C++
- Go
- JavaScript
- Objective-C
- PHP
- Python
- Ruby

## Usage
```
$ docker run --rm -v<some-path>:<some-path> -w<some-path> thethingsindustries/protoc [OPTION] PROTO_FILES
```

For help try:
```
$ docker run --rm thethingsindustries/protoc --help
```
