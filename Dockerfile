ARG ALPINE_VERSION
ARG GO_VERSION
ARG RUST_VERSION
ARG SWIFT_VERSION

FROM alpine:${ALPINE_VERSION} as protoc_builder
RUN apk add --no-cache build-base curl automake autoconf libtool git zlib-dev

RUN mkdir -p /out

ARG GRPC_VERSION
RUN git clone --recursive --depth=1 -b v${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc && \
    ln -s /grpc/third_party/protobuf /protobuf && \
    cd /protobuf && \
    ./autogen.sh && \
    ./configure --prefix=/usr --enable-static=no && \
    make && \
    make check && \
    make install && \
    make install DESTDIR=/out && \
    cd /grpc && \
    make install-plugins prefix=/out/usr

ARG PROTOBUF_C_VERSION
RUN mkdir -p /protobuf-c && \
    curl -sSL https://api.github.com/repos/protobuf-c/protobuf-c/tarball/v${PROTOBUF_C_VERSION} | tar xz -C /protobuf-c --strip-components=1 && \
    cd /protobuf-c && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make && make install DESTDIR=/out

ARG GRPC_JAVA_VERSION
RUN mkdir -p /grpc-java && \
    curl -sSL https://api.github.com/repos/grpc/grpc-java/tarball/v${GRPC_JAVA_VERSION} | tar xz -C /grpc-java --strip-components=1 && \
    cd /grpc-java && \
    g++ \
        -I. -I/protobuf/src \
        compiler/src/java_plugin/cpp/*.cpp \
        -L/protobuf/src/.libs \
        -lprotoc -lprotobuf -lpthread --std=c++0x -s \
        -o protoc-gen-grpc-java && \
    install -Ds protoc-gen-grpc-java /out/usr/bin/protoc-gen-grpc-java

ARG GRPC_WEB_VERSION
RUN mkdir -p /grpc-web && \
    curl -sSL https://api.github.com/repos/grpc/grpc-web/tarball/${GRPC_WEB_VERSION} | tar xz -C /grpc-web --strip-components=1 && \
    cd /grpc-web && \
    make install-plugin && \
    install -Ds /usr/local/bin/protoc-gen-grpc-web /out/usr/bin/protoc-gen-grpc-web


FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} as go_builder
RUN apk add --no-cache build-base curl git
ENV GO111MODULE=on

ARG PROTOC_GEN_DOC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    curl -sSL https://api.github.com/repos/pseudomuto/protoc-gen-doc/tarball/v${PROTOC_GEN_DOC_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    cd ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    go build -ldflags '-w -s' -o /protoc-gen-doc-out/protoc-gen-doc ./cmd/protoc-gen-doc && \
    install -Ds /protoc-gen-doc-out/protoc-gen-doc /out/usr/bin/protoc-gen-doc

ARG PROTOC_GEN_FIELDMASK_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-fieldmask && \
    curl -sSL https://api.github.com/repos/TheThingsIndustries/protoc-gen-fieldmask/tarball/v${PROTOC_GEN_FIELDMASK_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-fieldmask && \
    cd ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-fieldmask && \
    go build -ldflags '-w -s' -o /protoc-gen-fieldmask-out/protoc-gen-fieldmask . && \
    install -Ds /protoc-gen-fieldmask-out/protoc-gen-fieldmask /out/usr/bin/protoc-gen-fieldmask

ARG PROTOC_GEN_GO_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/golang/protobuf && \
    curl -sSL https://github.com/golang/protobuf/archive/v${PROTOC_GEN_GO_VERSION}.tar.gz | tar -xz --strip 1 -C ${GOPATH}/src/github.com/golang/protobuf &&\
    cd ${GOPATH}/src/github.com/golang/protobuf && \
    go build -ldflags '-w -s' -o /golang-protobuf-out/protoc-gen-go ./protoc-gen-go && \
    install -Ds /golang-protobuf-out/protoc-gen-go /out/usr/bin/protoc-gen-go

ARG PROTOC_GEN_GOGO_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/gogo/protobuf && \
    curl -sSL https://github.com/gogo/protobuf/archive/v${PROTOC_GEN_GOGO_VERSION}.tar.gz | tar -xz --strip 1 -C ${GOPATH}/src/github.com/gogo/protobuf &&\
    cd ${GOPATH}/src/github.com/gogo/protobuf && \
    go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogo ./protoc-gen-gogo && \
    install -Ds /gogo-protobuf-out/protoc-gen-gogo /out/usr/bin/protoc-gen-gogo && \
    mkdir -p /out/usr/include/github.com/gogo/protobuf/protobuf/google/protobuf && \
    install -D $(find ./protobuf/google/protobuf -name '*.proto') -t /out/usr/include/github.com/gogo/protobuf/protobuf/google/protobuf && \
    install -D ./gogoproto/gogo.proto /out/usr/include/github.com/gogo/protobuf/gogoproto/gogo.proto

ARG PROTOC_GEN_GOGOTTN_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn && \
    curl -sSL https://api.github.com/repos/TheThingsIndustries/protoc-gen-gogottn/tarball/v${PROTOC_GEN_GOGOTTN_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn && \
    cd ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn && \
    go build -ldflags '-w -s' -o /protoc-gen-gogottn-out/protoc-gen-gogottn . && \
    install -Ds /protoc-gen-gogottn-out/protoc-gen-gogottn /out/usr/bin/protoc-gen-gogottn

ARG PROTOC_GEN_LINT_VERSION
RUN cd / && \
    curl -sSLO https://github.com/ckaznocha/protoc-gen-lint/releases/download/v${PROTOC_GEN_LINT_VERSION}/protoc-gen-lint_linux_amd64.zip && \
    mkdir -p /protoc-gen-lint-out && \
    cd /protoc-gen-lint-out && \
    unzip -q /protoc-gen-lint_linux_amd64.zip && \
    install -Ds /protoc-gen-lint-out/protoc-gen-lint /out/usr/bin/protoc-gen-lint

ARG PROTOC_GEN_VALIDATE_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/lyft/protoc-gen-validate && \
    curl -sSL https://api.github.com/repos/lyft/protoc-gen-validate/tarball/v${PROTOC_GEN_VALIDATE_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/lyft/protoc-gen-validate && \
    cd ${GOPATH}/src/github.com/lyft/protoc-gen-validate && \
    go build -ldflags '-w -s' -o /protoc-gen-validate-out/protoc-gen-validate . && \
    install -Ds /protoc-gen-validate-out/protoc-gen-validate /out/usr/bin/protoc-gen-validate && \
    install -D ./validate/validate.proto /out/usr/include/github.com/lyft/protoc-gen-validate/validate/validate.proto

ARG GRPC_GATEWAY_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    curl -sSL https://api.github.com/repos/grpc-ecosystem/grpc-gateway/tarball/v${GRPC_GATEWAY_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    cd ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-grpc-gateway ./protoc-gen-grpc-gateway && \
    go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-swagger ./protoc-gen-swagger && \
    install -Ds /grpc-gateway-out/protoc-gen-grpc-gateway /out/usr/bin/protoc-gen-grpc-gateway && \
    install -Ds /grpc-gateway-out/protoc-gen-swagger /out/usr/bin/protoc-gen-swagger && \
    mkdir -p /out/usr/include/google/api && \
    install -D $(find ./third_party/googleapis/google/api -name '*.proto') -t /out/usr/include/google/api && \
    mkdir -p /out/usr/include/google/rpc && \
    install -D $(find ./third_party/googleapis/google/rpc -name '*.proto') -t /out/usr/include/google/rpc


FROM rust:${RUST_VERSION}-slim as rust_builder
RUN apt-get update && apt-get install -y musl-tools curl
RUN rustup target add x86_64-unknown-linux-musl
ENV RUSTFLAGS='-C linker=musl-gcc'

ARG RUST_PROTOBUF_VERSION
RUN mkdir -p /rust-protobuf && \
    curl -sSL https://api.github.com/repos/stepancheg/rust-protobuf/tarball/v${RUST_PROTOBUF_VERSION} | tar xz --strip 1 -C /rust-protobuf && \
    cd /rust-protobuf/protobuf-codegen && cargo build --target=x86_64-unknown-linux-musl --release && \
    install -Ds /rust-protobuf/target/x86_64-unknown-linux-musl/release/protoc-gen-rust /out/usr/bin/protoc-gen-rust

ARG GRPC_RUST_VERSION
RUN mkdir -p /grpc-rust && curl -sSL https://api.github.com/repos/stepancheg/grpc-rust/tarball/v${GRPC_RUST_VERSION} | tar xz --strip 1 -C /grpc-rust && \
    cd /grpc-rust/grpc-compiler && cargo build --target=x86_64-unknown-linux-musl --release && \
    install -Ds /grpc-rust/target/x86_64-unknown-linux-musl/release/protoc-gen-rust-grpc /out/usr/bin/protoc-gen-rust-grpc


FROM swift:${SWIFT_VERSION} as swift_builder
RUN apt-get update && \
    apt-get install -y unzip patchelf libnghttp2-dev

ARG GRPC_SWIFT_VERSION
RUN mkdir -p /grpc-swift && \
    curl -sSL https://api.github.com/repos/grpc/grpc-swift/tarball/${GRPC_SWIFT_VERSION} | tar --strip-components 1 -C /grpc-swift -xz && \
    cd /grpc-swift && make && \
    install -Ds /grpc-swift/protoc-gen-swift /protoc-gen-swift/protoc-gen-swift && \
    install -Ds /grpc-swift/protoc-gen-swiftgrpc /protoc-gen-swift/protoc-gen-swiftgrpc && \
    cp /lib64/ld-linux-x86-64.so.2 \
        $(ldd /protoc-gen-swift/protoc-gen-swift /protoc-gen-swift/protoc-gen-swiftgrpc | awk '{print $3}' | grep /lib | sort | uniq) \
        /protoc-gen-swift/ && \
    find /protoc-gen-swift/ -name 'lib*.so*' -exec patchelf --set-rpath /protoc-gen-swift {} \; && \
    for p in protoc-gen-swift protoc-gen-swiftgrpc; do \
        patchelf --set-interpreter /protoc-gen-swift/ld-linux-x86-64.so.2 /protoc-gen-swift/${p}; \
    done


FROM alpine:${ALPINE_VERSION} as packer
RUN apk add --no-cache curl

ARG UPX_VERSION
RUN mkdir -p /upx && curl -sSL https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz | tar xJ --strip 1 -C /upx && \
    install -D /upx/upx /usr/local/bin/upx

COPY --from=protoc_builder /out/ /out/
COPY --from=go_builder /out/ /out/
COPY --from=rust_builder /out/ /out/
COPY --from=swift_builder /protoc-gen-swift /out/protoc-gen-swift
RUN upx --lzma \
        /out/usr/bin/protoc \
        /out/usr/bin/grpc_* \
        /out/usr/bin/protoc-gen-*
RUN find /out -name "*.a" -delete -or -name "*.la" -delete

FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Roman Volosatovs <roman@thethingsnetwork.org>"
COPY --from=packer /out/ /
RUN apk add --no-cache bash libstdc++ && \
    for p in protoc-gen-swift protoc-gen-swiftgrpc; do ln -s /protoc-gen-swift/${p} /usr/bin/${p}; done && \
    ln -s /usr/bin/grpc_cpp_plugin /usr/bin/protoc-gen-grpc-cpp && \
    ln -s /usr/bin/grpc_csharp_plugin /usr/bin/protoc-gen-grpc-csharp && \
    ln -s /usr/bin/grpc_objective_c_plugin /usr/bin/protoc-gen-grpc-objc && \
    ln -s /usr/bin/grpc_node_plugin /usr/bin/protoc-gen-grpc-js && \
    ln -s /usr/bin/grpc_php_plugin /usr/bin/protoc-gen-grpc-php && \
    ln -s /usr/bin/grpc_python_plugin /usr/bin/protoc-gen-grpc-python && \
    ln -s /usr/bin/grpc_ruby_plugin /usr/bin/protoc-gen-grpc-ruby && \
    ln -s /usr/bin/protoc-gen-swiftgrpc /usr/bin/protoc-gen-grpc-swift
COPY protoc-wrapper /usr/bin/protoc-wrapper
ENTRYPOINT ["protoc-wrapper", "-I/usr/include"]
