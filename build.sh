#!/usr/bin/env bash
docker build \
--build-arg ALPINE_VERSION="${ALPINE_VERSION:-"3.14"}" \
--build-arg DART_PROTOBUF_VERSION="${DART_PROTOBUF_VERSION:-"2.0.0"}" \
--build-arg DART_VERSION="${DART_VERSION:-"2.13.4"}" \
--build-arg GOOGLE_API_VERSION="d9b32e92fa57c37e5af0dc03badfe741170c5849" \
--build-arg GO_VERSION="${GO_VERSION:-"1.17.0"}" \
--build-arg GRPC_GATEWAY_VERSION="${GRPC_GATEWAY_VERSION:-"2.3.0"}" \
--build-arg GRPC_JAVA_VERSION="${GRPC_JAVA_VERSION:-"1.36.0"}" \
--build-arg GRPC_RUST_VERSION="${GRPC_RUST_VERSION:-"0.8.2"}" \
--build-arg GRPC_SWIFT_VERSION="${GRPC_SWIFT_VERSION:-"1.0.0"}" \
--build-arg GRPC_VERSION="${GRPC_VERSION:-"1.36.4"}" \
--build-arg GRPC_WEB_VERSION="${GRPC_WEB_VERSION:-"1.2.1"}" \
--build-arg NODE_VERSION="${NODE_VERSION:-"14.17.5"}" \
--build-arg PROTOBUF_C_VERSION="${PROTOBUF_C_VERSION:-"1.3.3"}" \
--build-arg PROTOC_GEN_DOC_VERSION="${PROTOC_GEN_DOC_VERSION:-"1.4.1"}" \
--build-arg PROTOC_GEN_GO_GRPC_VERSION="${PROTOC_GEN_GO_GRPC_VERSION:-"1.36.0"}" \
--build-arg PROTOC_GEN_GO_VERSION="${PROTOC_GEN_GO_VERSION:-"1.5.1"}" \
--build-arg PROTOC_GEN_GOGO_VERSION="${PROTOC_GEN_GOGO_VERSION:-"1.3.2"}" \
--build-arg PROTOC_GEN_GOVALIDATORS_VERSION="${PROTOC_GEN_GOVALIDATORS_VERSION:-"0.3.2"}" \
--build-arg PROTOC_GEN_GQL_VERSION="${PROTOC_GEN_GQL_VERSION:-"0.8.0"}" \
--build-arg PROTOC_GEN_LINT_VERSION="${PROTOC_GEN_LINT_VERSION:-"0.2.1"}" \
--build-arg PROTOC_GEN_VALIDATE_VERSION="${PROTOC_GEN_VALIDATE_VERSION:-"0.6.1"}" \
--build-arg RUST_PROTOBUF_VERSION="${RUST_PROTOBUF_VERSION:-"2.22.1"}" \
--build-arg RUST_VERSION="${RUST_VERSION:-"1.50.0"}" \
--build-arg SWIFT_VERSION="${SWIFT_VERSION:-"5.2.5"}" \
--build-arg TS_PROTOC_GEN_VERSION="${TS_PROTOC_GEN_VERSION:-"0.14.0"}" \
--build-arg UPX_VERSION="${UPX_VERSION:-"3.96"}" \
${@} .
