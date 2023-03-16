![](https://github.com/rvolosatovs/docker-protobuf/workflows/Docker%20Image/badge.svg)

# Protocol Buffers + Docker
An all-inclusive `protoc` Docker image.
It started out as https://github.com/znly/docker-protobuf fork, but grew into a stand-alone project.

## What's included:
- [bufbuild/protoc-gen-validate](https://github.com/bufbuild/protoc-gen-validate)
- [chrusty/protoc-gen-jsonschema](https://github.com/chrusty/protoc-gen-jsonschema)
- [ckaznocha/protoc-gen-lint](https://github.com/ckaznocha/protoc-gen-lint)
- [danielvladco/go-proto-gql](https://github.com/danielvladco/go-proto-gql)
- [dart-lang/protobuf](https://github.com/dart-lang/protobuf)
- [envoyproxy/protoc-gen-validate](https://github.com/envoyproxy/protoc-gen-validate)
- [gogo/protobuf](https://github.com/gogo/protobuf)
- [golang/protobuf](https://github.com/protocolbuffers/protobuf-go)
- [google/protobuf](https://github.com/google/protobuf)
- [grpc-ecosystem/grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway)
- [grpc/grpc-go](https://github.com/grpc/grpc-go)
- [grpc/grpc-java](https://github.com/grpc/grpc-java)
- [grpc/grpc-swift](https://github.com/grpc/grpc-swift) (not on `arm64`, tracking issue: https://github.com/rvolosatovs/docker-protobuf/issues/89)
- [grpc/grpc-web](https://github.com/grpc/grpc-web)
- [grpc/grpc](https://github.com/grpc/grpc)
- [improbable-eng/ts-protoc-gen](https://github.com/improbable-eng/ts-protoc-gen)
- [infobloxopen/protoc-gen-gorm](https://github.com/infobloxopen/protoc-gen-gorm)
- [moul/protoc-gen-gotemplate](https://github.com/moul/protoc-gen-gotemplate)
- [mwitkow/go-proto-validators](https://github.com/mwitkow/go-proto-validators)
- [nanopb/nanopb](https://github.com/nanopb/nanopb)
- [protobuf-c/protobuf-c](https://github.com/protobuf-c/protobuf-c)
- [pseudomuto/protoc-gen-doc](https://github.com/pseudomuto/protoc-gen-doc)
- [scalapb/scalapb](https://github.com/scalapb/scalapb)
- [stepancheg/grpc-rust](https://github.com/stepancheg/grpc-rust)
- [stepancheg/rust-protobuf](https://github.com/stepancheg/rust-protobuf)

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
- Scala
- Swift
- Typescript

## Usage
```
$ docker run --rm -v<some-path>:<some-path> -w<some-path> rvolosatovs/protoc [OPTION] PROTO_FILES
```

For help try:
```
$ docker run --rm rvolosatovs/protoc --help
```
