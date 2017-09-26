[![Build Status](https://travis-ci.org/TheThingsIndustries/docker-protobuf.svg?branch=master)](https://travis-ci.org/TheThingsIndustries/docker-protobuf)

# Protocol Buffers + Docker
All-inclusive protoc suite, powered by Docker and Alpine Linux.

## What's included:
- https://github.com/google/protobuf `protoc`
- https://github.com/protobuf-c/protobuf-c `protoc-c`
- https://github.com/grpc/grpc plugin
- https://github.com/grpc/grpc-swift plugin
- https://github.com/grpc/grpc-java plugin
- https://github.com/grpc-ecosystem/grpc-gateway plugin
- Google well-known type protos(automatically included)

## Supported languages
- C
- C++
- C#
- Java / JavaNano (Android)
- JavaScript
- Go
- Objective-C
- PHP
- Python
- Ruby
- Rust
- Swift

## Usage
```
$ docker run --rm -v<some-path>:<some-path> -w<some-path> TheThingsIndustries/protoc [OPTION] PROTO_FILES
```

For help try:
```
$ docker run --rm TheThingsIndustries/protoc --help
```

## Image Size
The current image is about ~200mb and one layer. Most the space is spent on Go tools.
All the binaries are UPX'ed. Including the Swift stdlib.
