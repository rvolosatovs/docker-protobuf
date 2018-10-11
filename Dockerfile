ARG ALPINE_VERSION
ARG GO_VERSION
ARG GRPC_GATEWAY_VERSION
ARG GRPC_JAVA_VERSION
ARG GRPC_RUST_VERSION
ARG GRPC_SWIFT_VERSION
ARG GRPC_VERSION
ARG PROTOBUF_C_VERSION
ARG PROTOC_GEN_DOC_VERSION
ARG PROTOC_GEN_GOGOTTN_VERSION
ARG PROTOC_GEN_LINT_VERSION
ARG RUST_PROTOBUF_VERSION
ARG RUST_VERSION
ARG SWIFT_VERSION
ARG UPX_VERSION

FROM alpine:${ALPINE_VERSION} as protoc_builder
RUN apk add --no-cache build-base curl automake autoconf libtool git zlib-dev

ARG GRPC_VERSION
RUN mkdir -p /out
RUN git clone --recursive --depth=1 -b v${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc && \
    ln -s /grpc/third_party/protobuf /protobuf

ARG GRPC_JAVA_VERSION
RUN mkdir -p /grpc-java && \
    curl -sSL https://api.github.com/repos/grpc/grpc-java/tarball/v${GRPC_JAVA_VERSION} | tar xz -C /grpc-java --strip-components=1

ARG PROTOBUF_C_VERSION
RUN mkdir -p /protobuf-c && \
    curl -sSL https://api.github.com/repos/protobuf-c/protobuf-c/tarball/v${PROTOBUF_C_VERSION} | tar xz -C /protobuf-c --strip-components=1

RUN cd /protobuf && \
    autoreconf -f -i -Wall,no-obsolete && \
    ./configure --prefix=/usr --enable-static=no && \
    make -j2 && make install
RUN cd grpc && \
    make -j2 plugins
RUN cd /grpc-java/compiler/src/java_plugin/cpp && \
    g++ \
        -I. -I/protobuf/src \
        *.cpp \
        -L/protobuf/src/.libs \
        -lprotoc -lprotobuf -lpthread --std=c++0x -s \
        -o protoc-gen-grpc-java
RUN cd /protobuf-c && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make -j2

RUN cd /protobuf && make install DESTDIR=/out
RUN cd /grpc && make install-plugins prefix=/out/usr
RUN cd /grpc-java/compiler/src/java_plugin/cpp && install -Ds protoc-gen-grpc-java /out/usr/bin/protoc-gen-grpc-java
RUN cd /protobuf-c && make install DESTDIR=/out
RUN find /out -name "*.a" -delete -or -name "*.la" -delete


FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} as go_builder
RUN apk add --no-cache build-base curl git

ARG PROTOC_GEN_GOGOTTN_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn && \
    curl -sSL https://api.github.com/repos/TheThingsIndustries/protoc-gen-gogottn/tarball/v${PROTOC_GEN_GOGOTTN_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn && \
    cd ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn && \
    make deps && \
    go install -ldflags '-w -s' .

ARG PROTOC_GEN_GOVALIDATORS_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/mwitkow/go-proto-validators && \
    curl -sSL https://github.com/mwitkow/go-proto-validators/archive/${PROTOC_GEN_GOVALIDATORS_VERSION}.tar.gz | tar -xz --strip 1 -C ${GOPATH}/src/github.com/mwitkow/go-proto-validators &&\
    cd ${GOPATH}/src/github.com/mwitkow/go-proto-validators/protoc-gen-govalidators && \
    go get . && \
    go install .

ARG GRPC_GATEWAY_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    curl -sSL https://api.github.com/repos/grpc-ecosystem/grpc-gateway/tarball/v${GRPC_GATEWAY_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    cd ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    go get -ldflags '-w -s' ./protoc-gen-grpc-gateway && \
    go get -ldflags '-w -s' ./protoc-gen-swagger

ARG PROTOC_GEN_LINT_VERSION
RUN curl -sSLO https://github.com/ckaznocha/protoc-gen-lint/releases/download/v${PROTOC_GEN_LINT_VERSION}/protoc-gen-lint_linux_amd64.zip && \
    unzip -q protoc-gen-lint_linux_amd64.zip && \
    mv protoc-gen-lint ${GOPATH}/bin

ARG PROTOC_GEN_DOC_VERSION
RUN curl -sSL https://github.com/pseudomuto/protoc-gen-doc/releases/download/v${PROTOC_GEN_DOC_VERSION}/protoc-gen-doc-${PROTOC_GEN_DOC_VERSION}.linux-amd64.go1.10.tar.gz | tar xz --strip 1 -C ${GOPATH}/bin

RUN for p in ${GOPATH}/bin/protoc-gen*; do install -Ds ${p} /out/usr/bin/${p#"${GOPATH}/bin/"}; done && \
    mkdir -p /out/usr/include/github.com/gogo && mv ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn/vendor/github.com/gogo/protobuf /out/usr/include/github.com/gogo && \
    mv ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis/google /out/usr/include/


FROM swift:${SWIFT_VERSION} as swift_builder
RUN apt-get update && \
    apt-get install -y unzip patchelf

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


FROM alpine:${ALPINE_VERSION} as packer
RUN apk add --no-cache curl
ARG UPX_VERSION
RUN mkdir -p /upx && curl -sSL https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz | tar xJ --strip 1 -C /upx && \
    install -D /upx/upx /usr/local/bin/upx

COPY --from=protoc_builder /out/ /out/
COPY --from=rust_builder /out/ /out/
COPY --from=go_builder /out/ /out/
COPY --from=swift_builder /protoc-gen-swift /out/protoc-gen-swift
RUN upx --lzma \
        /out/usr/bin/protoc \
        /out/usr/bin/grpc_* \
        /out/usr/bin/protoc-gen-*


FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Roman Volosatovs <rvolosatovs@thethingsnetwork.org>"
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
