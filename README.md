![](https://github.com/rvolosatovs/docker-protobuf/actions/workflows/dockerimage.yml/badge.svg)

# Protocol Buffers + Docker
An all-inclusive `protoc` Docker image.
It started out as https://github.com/znly/docker-protobuf fork, but grew into a stand-alone project.

## What's included:
- [apple/swift-protobuf](https://github.com/apple/swift-protobuf)
- [bufbuild/protoc-gen-validate](https://github.com/bufbuild/protoc-gen-validate)
- [chrusty/protoc-gen-jsonschema](https://github.com/chrusty/protoc-gen-jsonschema)
- [ckaznocha/protoc-gen-lint](https://github.com/ckaznocha/protoc-gen-lint)
- [danielvladco/go-proto-gql](https://github.com/danielvladco/go-proto-gql)
- [google/protobuf.dart](https://github.com/google/protobuf.dart)
- [googleapis/googleapis](https://github.com/googleapis/googleapis)
- [googlecloudplatform/protoc-gen-bq-schema](https://github.com/googlecloudplatform/protoc-gen-bq-schema)
- [grpc-ecosystem/grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway)
- [grpc/grpc-go](https://github.com/grpc/grpc-go)
- [grpc/grpc-java](https://github.com/grpc/grpc-java)
- [grpc/grpc-swift-protobuf](https://github.com/grpc/grpc-swift-protobuf)
- [grpc/grpc-web](https://github.com/grpc/grpc-web)
- [grpc/grpc](https://github.com/grpc/grpc)
- [improbable-eng/ts-protoc-gen](https://github.com/improbable-eng/ts-protoc-gen)
- [infobloxopen/protoc-gen-gorm](https://github.com/infobloxopen/protoc-gen-gorm)
- [moul/protoc-gen-gotemplate](https://github.com/moul/protoc-gen-gotemplate)
- [mwitkow/go-proto-validators](https://github.com/mwitkow/go-proto-validators)
- [nanopb/nanopb](https://github.com/nanopb/nanopb)
- [planetscale/vtprotobuf](https://github.com/planetscale/vtprotobuf/)
- [protobuf-c/protobuf-c](https://github.com/protobuf-c/protobuf-c)
- [protocolbuffers/protobuf-go](https://github.com/protocolbuffers/protobuf-go)
- [protocolbuffers/protobuf-javascript](https://github.com/protocolbuffers/protobuf-javascript)
- [protocolbuffers/protobuf](https://github.com/protocolbuffers/protobuf)
- [pseudomuto/protoc-gen-doc](https://github.com/pseudomuto/protoc-gen-doc)
- [scalapb/scalapb](https://github.com/scalapb/scalapb) (not on `arm64`, [tracking issue](https://github.com/spring-projects/spring-boot/issues/33429))
- [solo-io/protoc-gen-openapi](https://github.com/solo-io/protoc-gen-openapi)
- [stepancheg/grpc-rust](https://github.com/stepancheg/grpc-rust)
- [stepancheg/rust-protobuf](https://github.com/stepancheg/rust-protobuf)
- [streem/pbandk](https://github.com/streem/pbandk)

## Supported languages
- C
- C#
- C++
- Dart
- Go
- Java / Java Lite (Android)
- JavaScript
- Kotlin
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
