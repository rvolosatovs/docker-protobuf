[![Build Status](https://travis-ci.org/TheThingsIndustries/docker-protobuf.svg?branch=master)](https://travis-ci.org/TheThingsIndustries/docker-protobuf)

# Protocol Buffers + Docker
A lightweight `protoc` Docker image.
It started out as https://github.com/znly/docker-protobuf fork, but grew into a stand-alone project.

## What's included:
- https://github.com/ckaznocha/protoc-gen-lint
- https://github.com/google/protobuf
- https://github.com/grpc-ecosystem/grpc-gateway
- https://github.com/grpc/grpc
- https://github.com/grpc/grpc-java
- https://github.com/grpc/grpc-swift
- https://github.com/grpc/grpc-web
- https://github.com/protobuf-c/protobuf-c
- https://github.com/pseudomuto/protoc-gen-doc
- https://github.com/stepancheg/grpc-rust
- https://github.com/stepancheg/rust-protobuf
- https://github.com/TheThingsIndustries/protoc-gen-gogottn
- google/protobuf, gogo/protobuf, grpc-gateway protos (passed to protoc by default)

## Supported languages
- C
- C#
- C++
- Go
- Java / JavaNano (Android)
- JavaScript
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
