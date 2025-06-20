# syntax=docker/dockerfile:1

ARG ALPINE_IMAGE_VERSION=latest
ARG DART_IMAGE_VERSION=latest
ARG GO_IMAGE_VERSION=latest
ARG NODE_IMAGE_VERSION=latest
ARG RUST_IMAGE_VERSION=latest
ARG SCALA_SBT_IMAGE_VERSION=graalvm-ce-22.3.3-b1-java17_1.9.9_2.12.18
ARG SWIFT_IMAGE_VERSION=latest
ARG XX_IMAGE_VERSION=latest


FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_IMAGE_VERSION} AS xx


FROM --platform=$BUILDPLATFORM golang:${GO_IMAGE_VERSION} AS go_host
COPY --from=xx / /
WORKDIR /
RUN mkdir -p /out
RUN apk add --no-cache \
        build-base \
        curl


FROM --platform=$BUILDPLATFORM go_host AS grpc_gateway
RUN mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway
ARG GRPC_GATEWAY_VERSION
RUN curl -sSL https://api.github.com/repos/grpc-ecosystem/grpc-gateway/tarball/${GRPC_GATEWAY_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway
WORKDIR ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-grpc-gateway ./protoc-gen-grpc-gateway
RUN go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-openapiv2 ./protoc-gen-openapiv2
RUN install -D /grpc-gateway-out/protoc-gen-grpc-gateway /out/usr/bin/protoc-gen-grpc-gateway
RUN install -D /grpc-gateway-out/protoc-gen-openapiv2 /out/usr/bin/protoc-gen-openapiv2
RUN mkdir -p /out/usr/include/protoc-gen-openapiv2/options
RUN install -D $(find ./protoc-gen-openapiv2/options -name '*.proto') -t /out/usr/include/protoc-gen-openapiv2/options
RUN xx-verify /out/usr/bin/protoc-gen-grpc-gateway
RUN xx-verify /out/usr/bin/protoc-gen-openapiv2


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_doc
RUN mkdir -p ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc
ARG PROTOC_GEN_DOC_VERSION
RUN curl -sSL https://api.github.com/repos/pseudomuto/protoc-gen-doc/tarball/${PROTOC_GEN_DOC_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc
WORKDIR ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /protoc-gen-doc-out/protoc-gen-doc ./cmd/protoc-gen-doc
RUN install -D /protoc-gen-doc-out/protoc-gen-doc /out/usr/bin/protoc-gen-doc
RUN xx-verify /out/usr/bin/protoc-gen-doc


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_openapi
RUN mkdir -p ${GOPATH}/src/github.com/solo-io/protoc-gen-openapi
ARG PROTOC_GEN_OPENAPI_VERSION
RUN curl -sSL https://api.github.com/repos/solo-io/protoc-gen-openapi/tarball/${PROTOC_GEN_OPENAPI_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/solo-io/protoc-gen-openapi
WORKDIR ${GOPATH}/src/github.com/solo-io/protoc-gen-openapi
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o _output/.bin/protoc-gen-openapi .
RUN install -D _output/.bin/protoc-gen-openapi /out/usr/bin/protoc-gen-openapi
RUN xx-verify /out/usr/bin/protoc-gen-openapi


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_go_grpc
RUN mkdir -p ${GOPATH}/src/github.com/grpc/grpc-go
ARG PROTOC_GEN_GO_GRPC_VERSION
RUN curl -sSL https://api.github.com/repos/grpc/grpc-go/tarball/${PROTOC_GEN_GO_GRPC_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc/grpc-go
WORKDIR ${GOPATH}/src/github.com/grpc/grpc-go/cmd/protoc-gen-go-grpc
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /golang-protobuf-out/protoc-gen-go-grpc .
RUN install -D /golang-protobuf-out/protoc-gen-go-grpc /out/usr/bin/protoc-gen-go-grpc
RUN xx-verify /out/usr/bin/protoc-gen-go-grpc


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_go
RUN mkdir -p ${GOPATH}/src/google.golang.org/protobuf
ARG PROTOC_GEN_GO_VERSION
RUN curl -sSL https://api.github.com/repos/protocolbuffers/protobuf-go/tarball/${PROTOC_GEN_GO_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/google.golang.org/protobuf
WORKDIR ${GOPATH}/src/google.golang.org/protobuf
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /golang-protobuf-out/protoc-gen-go ./cmd/protoc-gen-go
RUN install -D /golang-protobuf-out/protoc-gen-go /out/usr/bin/protoc-gen-go
RUN xx-verify /out/usr/bin/protoc-gen-go


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_go_vtproto
RUN mkdir -p ${GOPATH}/src/github.com/planetscale/vtprotobuf
ARG PROTOC_GEN_GO_VTPROTO_VERSION
RUN curl -sSL https://api.github.com/repos/planetscale/vtprotobuf/tarball/${PROTOC_GEN_GO_VTPROTO_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/planetscale/vtprotobuf
WORKDIR ${GOPATH}/src/github.com/planetscale/vtprotobuf
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /planetscale-vtprotobuf-out/ ./cmd/protoc-gen-go-vtproto
RUN install -D /planetscale-vtprotobuf-out/protoc-gen-go-vtproto /out/usr/bin/protoc-gen-go-vtproto
RUN xx-verify /out/usr/bin/protoc-gen-go-vtproto


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_gogo
RUN mkdir -p ${GOPATH}/src/github.com/gogo/protobuf
ARG PROTOC_GEN_GOGO_VERSION
RUN curl -sSL https://api.github.com/repos/gogo/protobuf/tarball/${PROTOC_GEN_GOGO_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/gogo/protobuf
WORKDIR ${GOPATH}/src/github.com/gogo/protobuf
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gofast ./protoc-gen-gofast
RUN go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogo ./protoc-gen-gogo
RUN go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogofast ./protoc-gen-gogofast
RUN go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogofaster ./protoc-gen-gogofaster
RUN go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogoslick ./protoc-gen-gogoslick
RUN go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogotypes ./protoc-gen-gogotypes
RUN go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gostring ./protoc-gen-gostring
RUN install -D $(find /gogo-protobuf-out -name 'protoc-gen-*') -t /out/usr/bin
RUN mkdir -p /out/usr/include/github.com/gogo/protobuf/protobuf/google/protobuf
RUN install -D $(find ./protobuf/google/protobuf -name '*.proto') -t /out/usr/include/github.com/gogo/protobuf/protobuf/google/protobuf
RUN install -D ./gogoproto/gogo.proto /out/usr/include/github.com/gogo/protobuf/gogoproto/gogo.proto
RUN xx-verify /out/usr/bin/protoc-gen-gogo


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_gotemplate
RUN mkdir -p ${GOPATH}/src/github.com/moul/protoc-gen-gotemplate
ARG PROTOC_GEN_GOTEMPLATE_VERSION
RUN curl -sSL https://api.github.com/repos/moul/protoc-gen-gotemplate/tarball/${PROTOC_GEN_GOTEMPLATE_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/moul/protoc-gen-gotemplate
WORKDIR ${GOPATH}/src/github.com/moul/protoc-gen-gotemplate
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /protoc-gen-gotemplate-out/protoc-gen-gotemplate .
RUN install -D /protoc-gen-gotemplate-out/protoc-gen-gotemplate /out/usr/bin/protoc-gen-gotemplate
RUN xx-verify /out/usr/bin/protoc-gen-gotemplate


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_gorm
RUN mkdir -p ${GOPATH}/src/github.com/infobloxopen/protoc-gen-gorm
ARG PROTOC_GEN_GORM_VERSION
RUN curl -sSL https://api.github.com/repos/infobloxopen/protoc-gen-gorm/tarball/${PROTOC_GEN_GORM_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/infobloxopen/protoc-gen-gorm
WORKDIR ${GOPATH}/src/github.com/infobloxopen/protoc-gen-gorm
RUN mkdir /protoc-gen-gorm-out
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /protoc-gen-gorm-out ./...
RUN install -D /protoc-gen-gorm-out/protoc-gen-gorm /out/usr/bin/protoc-gen-gorm
RUN install -D ./proto/options/gorm.proto /out/usr/include/github.com/infobloxopen/protoc-gen-gorm/options/gorm.proto
RUN install -D ./proto/types/types.proto /out/usr/include/github.com/infobloxopen/protoc-gen-gorm/types/types.proto
RUN xx-verify /out/usr/bin/protoc-gen-gorm


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_govalidators
RUN mkdir -p ${GOPATH}/src/github.com/mwitkow/go-proto-validators
ARG PROTOC_GEN_GOVALIDATORS_VERSION
RUN curl -sSL https://api.github.com/repos/mwitkow/go-proto-validators/tarball/${PROTOC_GEN_GOVALIDATORS_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/mwitkow/go-proto-validators
WORKDIR ${GOPATH}/src/github.com/mwitkow/go-proto-validators
RUN mkdir /go-proto-validators-out
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /go-proto-validators-out ./...
RUN install -D /go-proto-validators-out/protoc-gen-govalidators /out/usr/bin/protoc-gen-govalidators
RUN install -D ./validator.proto /out/usr/include/github.com/mwitkow/go-proto-validators/validator.proto
RUN xx-verify /out/usr/bin/protoc-gen-govalidators


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_gql
RUN mkdir -p ${GOPATH}/src/github.com/danielvladco/go-proto-gql
ARG PROTOC_GEN_GQL_VERSION
RUN curl -sSL https://api.github.com/repos/danielvladco/go-proto-gql/tarball/${PROTOC_GEN_GQL_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/danielvladco/go-proto-gql
WORKDIR ${GOPATH}/src/github.com/danielvladco/go-proto-gql
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /go-proto-gql-out/protoc-gen-gql ./protoc-gen-gql
RUN go build -ldflags '-w -s' -o /go-proto-gql-out/protoc-gen-gogql ./protoc-gen-gogql
RUN install -D /go-proto-gql-out/protoc-gen-gql /out/usr/bin/protoc-gen-gql
RUN install -D /go-proto-gql-out/protoc-gen-gogql /out/usr/bin/protoc-gen-gogql
RUN xx-verify /out/usr/bin/protoc-gen-gql
RUN xx-verify /out/usr/bin/protoc-gen-gogql


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_validate
ARG PROTOC_GEN_VALIDATE_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/bufbuild/protoc-gen-validate
RUN curl -sSL https://api.github.com/repos/bufbuild/protoc-gen-validate/tarball/${PROTOC_GEN_VALIDATE_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/bufbuild/protoc-gen-validate
WORKDIR ${GOPATH}/src/github.com/bufbuild/protoc-gen-validate
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /protoc-gen-validate-out/protoc-gen-validate .
RUN install -D /protoc-gen-validate-out/protoc-gen-validate /out/usr/bin/protoc-gen-validate
RUN install -D ./validate/validate.proto /out/usr/include/github.com/bufbuild/protoc-gen-validate/validate/validate.proto
RUN xx-verify /out/usr/bin/protoc-gen-validate


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_jsonschema
RUN mkdir -p ${GOPATH}/src/github.com/chrusty/protoc-gen-jsonschema
ARG PROTOC_GEN_JSONSCHEMA_VERSION
RUN curl -sSL https://api.github.com/repos/chrusty/protoc-gen-jsonschema/tarball/${PROTOC_GEN_JSONSCHEMA_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/chrusty/protoc-gen-jsonschema
WORKDIR ${GOPATH}/src/github.com/chrusty/protoc-gen-jsonschema
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /protoc-gen-jsonschema/protoc-gen-jsonschema ./cmd/protoc-gen-jsonschema
RUN install -D /protoc-gen-jsonschema/protoc-gen-jsonschema /out/usr/bin/protoc-gen-jsonschema
RUN install -D ./options.proto /out/usr/include/github.com/chrusty/protoc-gen-jsonschema/options.proto
RUN xx-verify /out/usr/bin/protoc-gen-jsonschema


FROM --platform=$BUILDPLATFORM go_host AS protoc_gen_bq_schema
RUN mkdir -p ${GOPATH}/src/github.com/googlecloudplatform/protoc-gen-bq-schema
ARG PROTOC_GEN_BQ_SCHEMA_VERSION
RUN curl -sSL https://api.github.com/repos/googlecloudplatform/protoc-gen-bq-schema/tarball/${PROTOC_GEN_BQ_SCHEMA_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/googlecloudplatform/protoc-gen-bq-schema
WORKDIR ${GOPATH}/src/github.com/googlecloudplatform/protoc-gen-bq-schema
RUN go mod download
ARG TARGETPLATFORM
RUN xx-go --wrap
RUN go build -ldflags '-w -s' -o /protoc-gen-bq-schema/protoc-gen-bq-schema .
RUN install -D /protoc-gen-bq-schema/protoc-gen-bq-schema /out/usr/bin/protoc-gen-bq-schema
RUN install -D ./bq_field.proto /out/usr/include/github.com/googlecloudplatform/protoc-gen-bq-schema/bq_field.proto
RUN install -D ./bq_table.proto /out/usr/include/github.com/googlecloudplatform/protoc-gen-bq-schema/bq_table.proto
RUN xx-verify /out/usr/bin/protoc-gen-bq-schema


FROM alpine:${ALPINE_IMAGE_VERSION} AS grpc_web
# Use Bazel 7 until grpc-web is updated to support Bazel 8+ with v1.6.0+
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
        bazel7 \
        build-base \
        curl 
ARG GRPC_WEB_VERSION
RUN mkdir -p /grpc-web
RUN curl -sSL https://api.github.com/repos/grpc/grpc-web/tarball/${GRPC_WEB_VERSION} | tar xz --strip 1 -C /grpc-web
WORKDIR /grpc-web
RUN bazel --batch build //javascript/net/grpc/web/generator:all
RUN install -D /grpc-web/bazel-bin/javascript/net/grpc/web/generator/protoc-gen-grpc-web /out/usr/bin/protoc-gen-grpc-web


FROM --platform=$BUILDPLATFORM rust:${RUST_IMAGE_VERSION} AS rust_target
COPY --from=xx / /
WORKDIR /
RUN mkdir -p /out
RUN apk add --no-cache \
        build-base \
        clang \
        curl \
        lld


FROM --platform=$BUILDPLATFORM rust_target AS protoc_gen_rust
RUN mkdir -p /rust-protobuf
ARG PROTOC_GEN_RUST_VERSION
RUN curl -sSL https://api.github.com/repos/stepancheg/rust-protobuf/tarball/${PROTOC_GEN_RUST_VERSION} | tar xz --strip 1 -C /rust-protobuf
WORKDIR /rust-protobuf/protobuf-codegen
RUN --mount=type=cache,target=/root/.cargo/git/db \
    --mount=type=cache,target=/root/.cargo/registry/cache \
    --mount=type=cache,target=/root/.cargo/registry/index \
    cargo fetch
ARG TARGETPLATFORM
RUN xx-cargo --config profile.release.strip=true build --release
RUN install -D /rust-protobuf/target/$(xx-cargo --print-target-triple)/release/protoc-gen-rs /out/usr/bin/protoc-gen-rs
RUN xx-verify /out/usr/bin/protoc-gen-rs


FROM --platform=$BUILDPLATFORM rust_target AS grpc_rust
RUN mkdir -p /grpc-rust
ARG GRPC_RUST_VERSION
RUN curl -sSL https://api.github.com/repos/stepancheg/grpc-rust/tarball/${GRPC_RUST_VERSION} | tar xz --strip 1 -C /grpc-rust
WORKDIR /grpc-rust/grpc-compiler
RUN --mount=type=cache,target=/root/.cargo/git/db \
    --mount=type=cache,target=/root/.cargo/registry/cache \
    --mount=type=cache,target=/root/.cargo/registry/index \
    cargo fetch
ARG TARGETPLATFORM
RUN xx-cargo --config profile.release.strip=true build --release
RUN install -D /grpc-rust/target/$(xx-cargo --print-target-triple)/release/protoc-gen-rust-grpc /out/usr/bin/protoc-gen-rust-grpc
RUN xx-verify /out/usr/bin/protoc-gen-rust-grpc


FROM --platform=$BUILDPLATFORM swift:${SWIFT_IMAGE_VERSION}-noble AS swift_target
ARG SWIFT_IMAGE_VERSION
ARG SWIFT_SDK_CHECKSUM
RUN apt-get update && \
    apt-get install -y curl
RUN export SWIFT_SDK_VERSION=$(echo ${SWIFT_IMAGE_VERSION} | sed -E 's/([0-9]+\.[0-9]+)\.0/\1/') && \
    swift sdk install \
    https://download.swift.org/swift-$SWIFT_SDK_VERSION-release/static-sdk/swift-$SWIFT_SDK_VERSION-RELEASE/swift-$SWIFT_SDK_VERSION-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz \
    --checksum ${SWIFT_SDK_CHECKSUM}

FROM --platform=$BUILDPLATFORM swift_target AS grpc_gen_swift
ARG PROTOC_GEN_SWIFT_VERSION
RUN mkdir -p /grpc-swift
RUN curl -sSL https://api.github.com/repos/grpc/grpc-swift/tarball/${PROTOC_GEN_SWIFT_VERSION} | tar xz --strip 1 -C /grpc-swift
WORKDIR /grpc-swift
ARG TARGETOS TARGETARCH
RUN <<EOF
    case ${TARGETARCH} in
      "amd64")  SWIFTARCH=x86_64  ;;
      "arm64")  SWIFTARCH=aarch64 ;;
      *)        echo "ERROR: Machine arch ${TARGETARCH} not supported." ;;
    esac
    swift build -c release --product protoc-gen-swift --swift-sdk $SWIFTARCH-swift-linux-musl
    install -D /grpc-swift/.build/release/protoc-gen-swift /out/usr/bin/protoc-gen-swift
EOF

FROM --platform=$BUILDPLATFORM swift_target AS grpc_swift
ARG GRPC_SWIFT_VERSION
RUN mkdir -p /grpc-swift-protobuf
RUN curl -sSL https://api.github.com/repos/grpc/grpc-swift-protobuf/tarball/${GRPC_SWIFT_VERSION} | tar xz --strip 1 -C /grpc-swift-protobuf
WORKDIR /grpc-swift-protobuf
ARG TARGETOS TARGETARCH
RUN <<EOF
    case ${TARGETARCH} in
      "amd64")  SWIFTARCH=x86_64  ;;
      "arm64")  SWIFTARCH=aarch64 ;;
      *)        echo "ERROR: Machine arch ${TARGETARCH} not supported." ;;
    esac
    swift build -c release --product protoc-gen-grpc-swift --swift-sdk $SWIFTARCH-swift-linux-musl
    install -D /grpc-swift-protobuf/.build/release/protoc-gen-grpc-swift /out/usr/bin/protoc-gen-grpc-swift
EOF

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_IMAGE_VERSION} AS alpine_host
COPY --from=xx / /
WORKDIR /
RUN mkdir -p /out
RUN apk add --no-cache \
        curl \
        unzip


FROM --platform=$BUILDPLATFORM alpine_host AS googleapis
RUN mkdir -p /googleapis
ARG GOOGLE_API_VERSION
RUN curl -sSL https://api.github.com/repos/googleapis/googleapis/tarball/${GOOGLE_API_VERSION} | tar xz --strip 1 -C /googleapis
WORKDIR /googleapis
RUN install -D ./google/api/annotations.proto /out/usr/include/google/api/annotations.proto
RUN install -D ./google/api/field_behavior.proto /out/usr/include/google/api/field_behavior.proto
RUN install -D ./google/api/http.proto /out/usr/include/google/api/http.proto
RUN install -D ./google/api/httpbody.proto /out/usr/include/google/api/httpbody.proto


FROM --platform=$BUILDPLATFORM alpine_host AS protoc_gen_lint
RUN mkdir -p /protoc-gen-lint-out
ARG TARGETOS TARGETARCH PROTOC_GEN_LINT_VERSION
RUN curl -sSLO https://github.com/ckaznocha/protoc-gen-lint/releases/download/${PROTOC_GEN_LINT_VERSION}/protoc-gen-lint_${TARGETOS}_${TARGETARCH}.zip
WORKDIR /protoc-gen-lint-out
RUN unzip -q /protoc-gen-lint_${TARGETOS}_${TARGETARCH}.zip
RUN install -D /protoc-gen-lint-out/protoc-gen-lint /out/usr/bin/protoc-gen-lint
ARG TARGETPLATFORM
RUN xx-verify /out/usr/bin/protoc-gen-lint


FROM --platform=$BUILDPLATFORM alpine:${ALPINE_IMAGE_VERSION} AS protoc_gen_pbandk
RUN apk add --no-cache \
        curl \
        git \
        openjdk17
ARG PROTOC_GEN_PBANDK_VERSION
RUN mkdir -p /pbandk
# We need to use my fork of the repo and this version increment hack until https://github.com/streem/pbandk/pull/248 is merged
RUN git clone https://github.com/strophy/pbandk.git
WORKDIR /pbandk
RUN echo ${PROTOC_GEN_PBANDK_VERSION} | awk -F. '{print $1 "." $2 "." $3+1}' > next-version.txt
RUN ./gradlew :protoc-gen-pbandk:protoc-gen-pbandk-jvm:bootJar
RUN install -D /pbandk/protoc-gen-pbandk/jvm/build/libs/protoc-gen-pbandk-jvm-$(cat next-version.txt)-SNAPSHOT-jvm8.jar /out/usr/bin/protoc-gen-pbandk


FROM sbtscala/scala-sbt:${SCALA_SBT_IMAGE_VERSION} AS protoc_gen_scala
ARG TARGETARCH
ARG PROTOC_GEN_SCALA_VERSION
ARG NATIVE_IMAGE_INSTALLED=true
ARG JAVA_OPTS="-Djdk.lang.Process.launchMechanism=vfork"
# Skip arm64 build due to https://github.com/spring-projects/spring-boot/issues/33429
RUN <<EOF
    mkdir -p /scala-protobuf
    mkdir -p /out
    if [ "${TARGETARCH}" = "arm64" ]; then
      echo "Skipping arm64 build due to error in Native Image toolchain"
      exit 0
    fi
    curl -sS --retry 5 --retry-delay 10 --retry-connrefused -L https://api.github.com/repos/scalapb/ScalaPB/tarball/${PROTOC_GEN_SCALA_VERSION} | tar xz --strip 1 -C /scala-protobuf
    cd /scala-protobuf
    gu install native-image
    ./make_reflect_config.sh
    sbt protocGenScalaNativeImage/nativeImage
    install -D /scala-protobuf/target/protoc-gen-scala /out/usr/bin/protoc-gen-scala
EOF


FROM dart:${DART_IMAGE_VERSION} AS protoc_gen_dart
RUN mkdir -p /dart-protobuf
ARG PROTOC_GEN_DART_VERSION
RUN curl -sS --retry 5 --retry-delay 10 --retry-connrefused -L https://api.github.com/repos/google/protobuf.dart/tarball/protoc_plugin-${PROTOC_GEN_DART_VERSION} | tar xz --strip 1 -C /dart-protobuf
WORKDIR /dart-protobuf/protoc_plugin
# Use Dart mirror to work around connectivity problems to default host when building in QEMU
# https://stackoverflow.com/questions/70729747
ARG PUB_HOSTED_URL=https://pub.flutter-io.cn
RUN dart pub get
RUN dart compile exe --verbose bin/protoc_plugin.dart -o protoc_plugin
RUN install -D /dart-protobuf/protoc_plugin/protoc_plugin /out/usr/bin/protoc-gen-dart


FROM --platform=$BUILDPLATFORM alpine_host AS upx
RUN mkdir -p /upx
ARG BUILDARCH BUILDOS UPX_VERSION
RUN curl -sSL https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-${BUILDARCH}_${BUILDOS}.tar.xz | tar xJ --strip 1 -C /upx
RUN install -D /upx/upx /usr/local/bin/upx
COPY --from=googleapis /out/ /out/
COPY --from=grpc_gateway /out/ /out/
COPY --from=grpc_gen_swift /out/ /out/
COPY --from=grpc_rust /out/ /out/
COPY --from=grpc_swift /out/ /out/
COPY --from=grpc_web /out/ /out/
COPY --from=protoc_gen_bq_schema /out/ /out/
COPY --from=protoc_gen_doc /out/ /out/
COPY --from=protoc_gen_go /out/ /out/
COPY --from=protoc_gen_go_grpc /out/ /out/
COPY --from=protoc_gen_go_vtproto /out/ /out/
COPY --from=protoc_gen_gogo /out/ /out/
COPY --from=protoc_gen_gorm /out/ /out/
COPY --from=protoc_gen_gotemplate /out/ /out/
COPY --from=protoc_gen_govalidators /out/ /out/
COPY --from=protoc_gen_gql /out/ /out/
COPY --from=protoc_gen_jsonschema /out/ /out/
COPY --from=protoc_gen_lint /out/ /out/
COPY --from=protoc_gen_openapi /out/ /out/
COPY --from=protoc_gen_rust /out/ /out/
COPY --from=protoc_gen_scala /out/ /out/
COPY --from=protoc_gen_validate /out/ /out/
RUN find /out/usr/bin/ -type f \
        -name 'protoc-gen-*' | \
        xargs -P $(nproc) -I{} \
        upx --lzma {}
RUN find /out -name "*.a" -delete -or -name "*.la" -delete


FROM node:${NODE_IMAGE_VERSION}
LABEL org.opencontainers.image.authors="Romāns Volosatovs <rvolosatovs@riseup.net>, Leon White <badfunkstripe@gmail.com>"
ARG PROTOC_GEN_NANOPB_VERSION PROTOC_GEN_TS_VERSION TARGETARCH
RUN apk add --no-cache \
      --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
      --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community/ \
      --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main/ \
        bash \
        grpc \
        grpc-java \
        grpc-plugins \
        protobuf \
        protobuf-dev \
        protobuf-c-compiler \
        protoc-gen-js \
        openjdk21-jre \
        python3
RUN npm install -g ts-protoc-gen@${PROTOC_GEN_TS_VERSION}
RUN rm /usr/lib/python3.12/EXTERNALLY-MANAGED && \
    python3 -m ensurepip && pip3 install --no-cache setuptools nanopb==${PROTOC_GEN_NANOPB_VERSION}
COPY --from=upx /out/ /
COPY --from=protoc_gen_dart /out/ /
COPY --from=protoc_gen_dart /runtime/ /
COPY --from=protoc_gen_pbandk /out/ /
RUN ln -s /usr/bin/grpc_cpp_plugin /usr/bin/protoc-gen-grpc-cpp && \
    ln -s /usr/bin/grpc_csharp_plugin /usr/bin/protoc-gen-grpc-csharp && \
    ln -s /usr/bin/grpc_node_plugin /usr/bin/protoc-gen-grpc-js && \
    ln -s /usr/bin/grpc_objective_c_plugin /usr/bin/protoc-gen-grpc-objc && \
    ln -s /usr/bin/grpc_php_plugin /usr/bin/protoc-gen-grpc-php && \
    ln -s /usr/bin/grpc_python_plugin /usr/bin/protoc-gen-grpc-python && \
    ln -s /usr/bin/grpc_ruby_plugin /usr/bin/protoc-gen-grpc-ruby && \
    ln -s /usr/bin/protoc-gen-go-grpc /usr/bin/protoc-gen-grpc-go && \
    ln -s /usr/bin/protoc-gen-rust-grpc /usr/bin/protoc-gen-grpc-rust
COPY protoc-wrapper /usr/bin/protoc-wrapper
RUN mkdir -p /test && \
    protoc-wrapper \
        --bq-schema_out=/test \
        --c_out=/test \
        --dart_out=/test \
        --go_out=/test \
        --go-grpc_out=/test \
        --gorm_out=/test \
        --gotemplate_out=/test \
        --govalidators_out=/test \
        --gql_out=/test \
        --grpc-cpp_out=/test \
        --grpc-csharp_out=/test \
        --grpc-gateway_out=/test \
        --grpc-go_out=/test \
        --go-vtproto_out=/test \
        --grpc-java_out=/test \
        --grpc-js_out=/test \
        --grpc-objc_out=/test \
        --grpc-php_out=/test \
        --grpc-python_out=/test \
        --grpc-ruby_out=/test \
        --grpc-rust_out=/test \
        --grpc-swift_out=/test \
        --grpc-web_out=import_style=commonjs,mode=grpcwebtext:/test \
        --java_out=/test \
        --js_out=import_style=commonjs:/test \
        --jsonschema_out=/test \
        --lint_out=/test \
        --nanopb_out=/test \
        --openapi_out=/test \
        --openapiv2_out=/test \
        --pbandk_out=/test \
        --php_out=/test \
        --python_out=/test \
        --rs_out=/test \
        --ruby_out=/test \
        --swift_out=/test \
        --ts_out=/test \
        --validate_out=lang=go:/test \
        google/protobuf/any.proto && \
    protoc-wrapper \
        --gogo_out=/test \
        google/protobuf/any.proto && \
    if ! [ "${TARGETARCH}" = "arm64" ]; then \
        protoc-wrapper \
            --scala_out=/test \
            google/protobuf/any.proto ; \
    fi && \
    rm -rf /test
ENTRYPOINT ["protoc-wrapper", "-I/usr/include"]
