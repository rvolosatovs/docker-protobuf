![](https://github.com/TheThingsIndustries/docker-protobuf/workflows/Docker%20Image/badge.svg)

# Protocol Buffers + Docker
A lightweight `protoc` Docker image.
It started out as https://github.com/znly/docker-protobuf fork, but grew into a stand-alone project.

## What's included:
- https://github.com/ckaznocha/protoc-gen-lint
- https://github.com/danielvladco/go-proto-gql
- https://github.com/dart-lang/protobuf
- https://github.com/envoyproxy/protoc-gen-validate
- https://github.com/mwitkow/go-proto-validators
- https://github.com/gogo/protobuf
- https://github.com/golang/protobuf
- https://github.com/google/protobuf
- https://github.com/grpc-ecosystem/grpc-gateway
- https://github.com/grpc/grpc
- https://github.com/grpc/grpc-go
- https://github.com/grpc/grpc-java
- https://github.com/grpc/grpc-swift
- https://github.com/grpc/grpc-web
- https://github.com/improbable-eng/ts-protoc-gen
- https://github.com/protobuf-c/protobuf-c
- https://github.com/pseudomuto/protoc-gen-doc
- https://github.com/stepancheg/grpc-rust
- https://github.com/stepancheg/rust-protobuf
- https://github.com/TheThingsIndustries/protoc-gen-fieldmask
- https://github.com/TheThingsIndustries/protoc-gen-gogottn

## Supported languages
- C
- C#
- C++
- Dart
- Go
- Java / JavaNano (Android)
- JavaScript
- Objective-C
- PHP
- Python
- Ruby
- Rust
- Swift
- Typescript

## Usage
```
$ docker run --rm -v<some-path>:<some-path> -w<some-path> thethingsindustries/protoc [OPTION] PROTO_FILES
```

For help try:
```
$ docker run --rm thethingsindustries/protoc --help
```
