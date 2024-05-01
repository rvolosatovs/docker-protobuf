# syntax=docker/dockerfile:1.4

ARG ALPINE_IMAGE_VERSION
ARG DART_IMAGE_VERSION
ARG GO_IMAGE_VERSION
ARG NODE_IMAGE_VERSION
ARG RUST_IMAGE_VERSION
ARG SCALA_SBT_IMAGE_VERSION
ARG SWIFT_IMAGE_VERSION
ARG XX_IMAGE_VERSION


FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_IMAGE_VERSION} AS xx


FROM --platform=$BUILDPLATFORM golang:${GO_IMAGE_VERSION} as go_host
COPY --from=xx / /
WORKDIR /
RUN mkdir -p /out
RUN apk add --no-cache \
        build-base \
        curl


FROM --platform=$BUILDPLATFORM go_host as grpc_gateway
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


FROM --platform=$BUILDPLATFORM go_host as protoc_gen_doc
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


FROM --platform=$BUILDPLATFORM go_host as protoc_gen_go_grpc
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


FROM --platform=$BUILDPLATFORM go_host as protoc_gen_go
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


FROM --platform=$BUILDPLATFORM go_host as protoc_gen_gogo
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


FROM --platform=$BUILDPLATFORM go_host as protoc_gen_gotemplate
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


FROM --platform=$BUILDPLATFORM go_host as protoc_gen_gorm
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


FROM --platform=$BUILDPLATFORM go_host as protoc_gen_govalidators
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


FROM --platform=$BUILDPLATFORM go_host as protoc_gen_gql
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


FROM --platform=$BUILDPLATFORM go_host as protoc_gen_validate
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


FROM --platform=$BUILDPLATFORM go_host as protoc_gen_jsonschema
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


FROM alpine:${ALPINE_IMAGE_VERSION} as grpc_web
RUN apk add --no-cache \
        build-base \
        curl \
        protobuf-dev
RUN mkdir -p /grpc-web
ARG GRPC_WEB_VERSION
RUN curl -sSL https://api.github.com/repos/grpc/grpc-web/tarball/${GRPC_WEB_VERSION} | tar xz --strip 1 -C /grpc-web
WORKDIR /grpc-web
# RUN make -j$(nproc) install-plugin
# RUN install -Ds /usr/local/bin/protoc-gen-grpc-web /out/usr/bin/protoc-gen-grpc-web


FROM --platform=$BUILDPLATFORM rust:${RUST_IMAGE_VERSION} as rust_target
COPY --from=xx / /
WORKDIR /
RUN mkdir -p /out
RUN apk add --no-cache \
        build-base \
        clang \
        curl \
        lld


FROM --platform=$BUILDPLATFORM rust_target as protoc_gen_rust
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
RUN install -D /rust-protobuf/target/$(xx-cargo --print-target-triple)/release/protoc-gen-rust /out/usr/bin/protoc-gen-rust
RUN xx-verify /out/usr/bin/protoc-gen-rust


FROM --platform=$BUILDPLATFORM rust_target as grpc_rust
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


FROM swift:${SWIFT_IMAGE_VERSION} as grpc_swift
RUN apt-get update
RUN apt-get install -y \
        build-essential \
        curl \
        libnghttp2-dev \
        libssl-dev \
        patchelf \
        unzip \
        zlib1g-dev
ARG TARGETOS TARGETARCH GRPC_SWIFT_VERSION
RUN <<EOF
    mkdir -p /protoc-gen-swift
    # Skip arm64 build due to https://forums.swift.org/t/build-crash-when-building-in-qemu-using-new-swift-5-6-arm64-image/56090/
    # TODO: Remove this conditional once fixed
    if [ "${TARGETARCH}" = "arm64" ]; then
      echo "Skipping arm64 build due to error in Swift toolchain"
      exit 0
    fi
    case ${TARGETARCH} in
      "amd64")  SWIFT_LIB_DIR=/lib64 && SWIFT_LINKER=ld-${TARGETOS}-x86-64.so.2  ;;
      "arm64")  SWIFT_LIB_DIR=/lib   && SWIFT_LINKER=ld-${TARGETOS}-aarch64.so.1 ;;
      *)        echo "ERROR: Machine arch ${TARGETARCH} not supported." ;;
    esac
    mkdir -p /grpc-swift
    curl -sSL https://api.github.com/repos/grpc/grpc-swift/tarball/${GRPC_SWIFT_VERSION} | tar xz --strip 1 -C /grpc-swift
    cd /grpc-swift
    make
    make plugins
    install -Ds /grpc-swift/protoc-gen-swift /protoc-gen-swift/protoc-gen-swift
    install -Ds /grpc-swift/protoc-gen-grpc-swift /protoc-gen-swift/protoc-gen-grpc-swift
    cp ${SWIFT_LIB_DIR}/${SWIFT_LINKER} \
      $(ldd /protoc-gen-swift/protoc-gen-swift /protoc-gen-swift/protoc-gen-grpc-swift | awk '{print $3}' | grep /lib | sort | uniq) \
      /protoc-gen-swift/
    find /protoc-gen-swift/ -name 'lib*.so*' -exec patchelf --set-rpath /protoc-gen-swift {} \;
    for p in protoc-gen-swift protoc-gen-grpc-swift; do
      patchelf --set-interpreter /protoc-gen-swift/${SWIFT_LINKER} /protoc-gen-swift/${p}
    done
EOF


FROM --platform=$BUILDPLATFORM alpine:${ALPINE_IMAGE_VERSION} as alpine_host
COPY --from=xx / /
WORKDIR /
RUN mkdir -p /out
RUN apk add --no-cache \
        curl \
        unzip


FROM --platform=$BUILDPLATFORM alpine_host as googleapis
RUN mkdir -p /googleapis
ARG GOOGLE_API_VERSION
RUN curl -sSL https://api.github.com/repos/googleapis/googleapis/tarball/${GOOGLE_API_VERSION} | tar xz --strip 1 -C /googleapis
WORKDIR /googleapis
RUN install -D ./google/api/annotations.proto /out/usr/include/google/api/annotations.proto
RUN install -D ./google/api/field_behavior.proto /out/usr/include/google/api/field_behavior.proto
RUN install -D ./google/api/http.proto /out/usr/include/google/api/http.proto
RUN install -D ./google/api/httpbody.proto /out/usr/include/google/api/httpbody.proto


FROM --platform=$BUILDPLATFORM alpine_host as protoc_gen_lint
RUN mkdir -p /protoc-gen-lint-out
ARG TARGETOS TARGETARCH PROTOC_GEN_LINT_VERSION
RUN curl -sSLO https://github.com/ckaznocha/protoc-gen-lint/releases/download/${PROTOC_GEN_LINT_VERSION}/protoc-gen-lint_${TARGETOS}_${TARGETARCH}.zip
WORKDIR /protoc-gen-lint-out
RUN unzip -q /protoc-gen-lint_${TARGETOS}_${TARGETARCH}.zip
RUN install -D /protoc-gen-lint-out/protoc-gen-lint /out/usr/bin/protoc-gen-lint
ARG TARGETPLATFORM
RUN xx-verify /out/usr/bin/protoc-gen-lint


FROM alpine:${ALPINE_IMAGE_VERSION} as protoc_gen_js
COPY --from=xx / /
RUN mkdir -p /out
RUN apk add --no-cache \
    bash \
    build-base \
    curl \
    linux-headers \
    openjdk11-jdk \
    python3 \
    unzip \
    zip

ARG TARGETARCH
ARG PROTOC_GEN_JS_VERSION
ARG BAZEL_VERSION=6.1.0
RUN <<EOF
    # Skip arm64 build due to https://github.com/bazelbuild/bazel/issues/17220
    # TODO: Remove this conditional once fixed
    if [ "${TARGETARCH}" = "arm64" ]; then
      echo "Skipping arm64 build due to error in Bazel toolchain"
      exit 0
    fi
    apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ bazel6
    # Build protoc-gen-js
    # TODO: Remove when protoc-gen-js is available in Alpine
    # https://gitlab.alpinelinux.org/alpine/aports/-/issues/14399
    mkdir -p /protoc_gen_js
    cd /protoc_gen_js
    curl -sSL https://api.github.com/repos/protocolbuffers/protobuf-javascript/tarball/${PROTOC_GEN_JS_VERSION} | tar xz --strip 1 -C /protoc_gen_js
    bazel build plugin_files
    install -D /protoc_gen_js/bazel-bin/generator/protoc-gen-js /out/usr/bin/protoc-gen-js
    xx-verify /out/usr/bin/protoc-gen-js
EOF


FROM node:${NODE_IMAGE_VERSION} as protoc_gen_ts
ARG NODE_IMAGE_VERSION
ARG PROTOC_GEN_TS_VERSION
RUN npm install -g pkg ts-protoc-gen@${PROTOC_GEN_TS_VERSION}
RUN pkg \
        --compress Brotli \
        --targets node${NODE_IMAGE_VERSION%%.*}-alpine \
        -o protoc-gen-ts \
        /usr/local/lib/node_modules/ts-protoc-gen
RUN install -D protoc-gen-ts /out/usr/bin/protoc-gen-ts

FROM sbtscala/scala-sbt:${SCALA_SBT_IMAGE_VERSION} as protoc_gen_scala
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
    curl -sSL https://api.github.com/repos/scalapb/ScalaPB/tarball/${PROTOC_GEN_SCALA_VERSION} | tar xz --strip 1 -C /scala-protobuf
    cd /scala-protobuf
    gu install native-image
    ./make_reflect_config.sh
    sbt protocGenScalaNativeImage/nativeImage
    install -D /scala-protobuf/target/protoc-gen-scala /out/usr/bin/protoc-gen-scala
EOF

FROM dart:${DART_IMAGE_VERSION} as protoc_gen_dart
RUN apt-get update
RUN apt-get install -y curl
RUN mkdir -p /dart-protobuf
ARG PROTOC_GEN_DART_VERSION
RUN curl -sSL https://api.github.com/repos/google/protobuf.dart/tarball/protoc_plugin-${PROTOC_GEN_DART_VERSION} | tar xz --strip 1 -C /dart-protobuf
WORKDIR /dart-protobuf/protoc_plugin
# Use Dart mirror to work around connectivity problems to default host when building in QEMU
# https://stackoverflow.com/questions/70729747
ARG PUB_HOSTED_URL=https://pub.flutter-io.cn
RUN dart pub get
RUN dart compile exe --verbose bin/protoc_plugin.dart -o protoc_plugin
RUN install -D /dart-protobuf/protoc_plugin/protoc_plugin /out/usr/bin/protoc-gen-dart


FROM --platform=$BUILDPLATFORM alpine_host as upx
RUN mkdir -p /upx
ARG BUILDARCH BUILDOS UPX_VERSION
RUN curl -sSL https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-${BUILDARCH}_${BUILDOS}.tar.xz | tar xJ --strip 1 -C /upx
RUN install -D /upx/upx /usr/local/bin/upx
COPY --from=googleapis /out/ /out/
COPY --from=grpc_gateway /out/ /out/
COPY --from=grpc_rust /out/ /out/
COPY --from=grpc_swift /protoc-gen-swift /out/protoc-gen-swift
# COPY --from=grpc_web /out/ /out/
COPY --from=protoc_gen_doc /out/ /out/
COPY --from=protoc_gen_go /out/ /out/
COPY --from=protoc_gen_go_grpc /out/ /out/
COPY --from=protoc_gen_gogo /out/ /out/
COPY --from=protoc_gen_gorm /out/ /out/
COPY --from=protoc_gen_gotemplate /out/ /out/
COPY --from=protoc_gen_govalidators /out/ /out/
COPY --from=protoc_gen_gql /out/ /out/
COPY --from=protoc_gen_js /out/ /out/
COPY --from=protoc_gen_jsonschema /out/ /out/
COPY --from=protoc_gen_lint /out/ /out/
COPY --from=protoc_gen_rust /out/ /out/
COPY --from=protoc_gen_scala /out/ /out/
COPY --from=protoc_gen_validate /out/ /out/
ARG TARGETARCH
RUN find /out/usr/bin/ -type f \
        -name 'protoc-gen-*' | \
        xargs -P $(nproc) -I{} \
        upx --lzma {}
RUN find /out -name "*.a" -delete -or -name "*.la" -delete


FROM alpine:${ALPINE_IMAGE_VERSION}
LABEL org.opencontainers.image.authors="Romāns Volosatovs <rvolosatovs@riseup.net>, Leon White <badfunkstripe@gmail.com>"
ARG PROTOC_GEN_NANOPB_VERSION
RUN apk add --no-cache \
        bash \
        grpc \
        # grpc-java \
        grpc-plugins \
        pipx \
        protobuf \
        protobuf-dev \
        protobuf-c-compiler \
        python3 \
        rm -rf ~/.cache/* /usr/local/share/man /tmp/*   
COPY --from=upx /out/ /
COPY --from=protoc_gen_ts /out/ /
COPY --from=protoc_gen_dart /out/ /
COPY --from=protoc_gen_dart /runtime/ /
ENV PATH="${PATH}:/root/.local/bin"
RUN pipx install nanopb==${PROTOC_GEN_NANOPB_VERSION}
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
        --c_out=/test \
        --dart_out=/test \
        --go_out=/test \
        --gorm_out=/test \
        --gotemplate_out=/test \
        --govalidators_out=/test \
        --gql_out=/test \
        --grpc-cpp_out=/test \
        --grpc-csharp_out=/test \
        --grpc-go_out=/test \
        # --grpc-java_out=/test \
        --grpc-js_out=/test \
        --grpc-objc_out=/test \
        --grpc-php_out=/test \
        --grpc-python_out=/test \
        --grpc-ruby_out=/test \
        --grpc-rust_out=/test \
        # --grpc-web_out=import_style=commonjs,mode=grpcwebtext:/test \
        --java_out=/test \
        --jsonschema_out=/test \
        --lint_out=/test \
        --nanopb_out=/test \
        --php_out=/test \
        --python_out=/test \
        --ruby_out=/test \
        # --rust_out=/test \
        --ts_out=/test \
        --validate_out=lang=go:/test \
        google/protobuf/any.proto
RUN protoc-wrapper \
        --gogo_out=/test \
        google/protobuf/any.proto
ARG TARGETARCH
RUN <<EOF
    if ! [ "${TARGETARCH}" = "arm64" ]; then 
        ln -s /protoc-gen-swift/protoc-gen-grpc-swift /usr/bin/protoc-gen-grpc-swift
        ln -s /protoc-gen-swift/protoc-gen-swift /usr/bin/protoc-gen-swift
    fi
EOF
RUN <<EOF
    if ! [ "${TARGETARCH}" = "arm64" ]; then
        protoc-wrapper \
            --grpc-swift_out=/test \
            --js_out=import_style=commonjs:/test \
            --scala_out=/test \
            --swift_out=/test \
            google/protobuf/any.proto
    fi
EOF
RUN rm -rf /test
ENTRYPOINT ["protoc-wrapper", "-I/usr/include"]
