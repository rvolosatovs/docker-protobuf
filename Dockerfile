ARG ALPINE_VERSION
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

FROM alpine:${ALPINE_VERSION} as protoc_builder

RUN apk add --no-cache build-base curl automake autoconf libtool git zlib-dev

ARG GRPC_VERSION
RUN mkdir -p /out
RUN git clone --recursive --depth=1 -b v${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc && \
    ln -s /grpc/third_party/protobuf /protobuf

ARG GRPC_JAVA_VERSION
RUN mkdir -p /grpc-java && \
    curl -L https://api.github.com/repos/grpc/grpc-java/tarball/v${GRPC_JAVA_VERSION} | tar xvz -C /grpc-java --strip-components=1

ARG PROTOBUF_C_VERSION
RUN mkdir -p /protobuf-c && \
    curl -L https://api.github.com/repos/protobuf-c/protobuf-c/tarball/v${PROTOBUF_C_VERSION} | tar xvz -C /protobuf-c --strip-components=1

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

RUN cd /protobuf && \
    make install DESTDIR=/out
RUN cd /grpc && \
    make install-plugins prefix=/out/usr
RUN cd /grpc-java/compiler/src/java_plugin/cpp && \
    install protoc-gen-grpc-java /out/usr/bin/
RUN cd /protobuf-c && \
    make install DESTDIR=/out
RUN find /out -name "*.a" -delete -or -name "*.la" -delete

RUN apk add --no-cache go
ENV GOPATH=/go \
    PATH=/go/bin/:$PATH

ARG PROTOC_GEN_GOGOTTN_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn && \
    curl -L https://api.github.com/repos/TheThingsIndustries/protoc-gen-gogottn/tarball/v${PROTOC_GEN_GOGOTTN_VERSION} | tar xvz --strip 1 -C ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn
RUN cd ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn && \
    make deps && \
    go install -v -ldflags '-w -s' .

ARG GRPC_GATEWAY_VERSION
RUN go get -d github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
RUN cd ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    git checkout v${GRPC_GATEWAY_VERSION} && \
    go install -v -ldflags '-w -s' ./protoc-gen-grpc-gateway
    
ARG PROTOC_GEN_LINT_VERSION
RUN curl -LO https://github.com/ckaznocha/protoc-gen-lint/releases/download/v${PROTOC_GEN_LINT_VERSION}/protoc-gen-lint_linux_amd64.zip && \
    unzip protoc-gen-lint_linux_amd64.zip && \
    install protoc-gen-lint ${GOPATH}/bin

ARG PROTOC_GEN_DOC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    curl -L https://github.com/pseudomuto/protoc-gen-doc/releases/download/v${PROTOC_GEN_DOC_VERSION}/protoc-gen-doc-${PROTOC_GEN_DOC_VERSION}.linux-amd64.go1.10.tar.gz | tar xvz --strip 1 -C ${GOPATH}/bin

RUN install ${GOPATH}/bin/protoc-gen* /out/usr/bin/


FROM swift:${SWIFT_VERSION} as swift_builder

RUN apt-get update && \
    apt-get install -y unzip patchelf

ARG GRPC_SWIFT_VERSION
RUN mkdir -p /grpc-swift && \
    curl -L https://api.github.com/repos/grpc/grpc-swift/tarball/${GRPC_SWIFT_VERSION} | tar --strip-components 1 -C /grpc-swift -xz
RUN cd /grpc-swift && \
    make
RUN mkdir -p /protoc-gen-swift && \
    install /grpc-swift/protoc-gen-swift /protoc-gen-swift/ && \
    install /grpc-swift/protoc-gen-swiftgrpc /protoc-gen-swift/
RUN cp /lib64/ld-linux-x86-64.so.2 \
        $(ldd /protoc-gen-swift/protoc-gen-swift /protoc-gen-swift/protoc-gen-swiftgrpc | awk '{print $3}' | grep /lib | sort | uniq) \
        /protoc-gen-swift/
RUN find /protoc-gen-swift/ -name 'lib*.so*' -exec patchelf --set-rpath /protoc-gen-swift {} \; && \
    for p in protoc-gen-swift protoc-gen-swiftgrpc; do \
        patchelf --set-interpreter /protoc-gen-swift/ld-linux-x86-64.so.2 /protoc-gen-swift/${p}; \
    done

    
FROM rust:${RUST_VERSION} as rust_builder
RUN mkdir -p /out
RUN apt-get update && \
    apt-get install -y musl-tools
RUN rustup target add x86_64-unknown-linux-musl
ENV RUSTFLAGS='-C linker=musl-gcc'

ARG RUST_PROTOBUF_VERSION
RUN mkdir -p /rust-protobuf && \
    curl -L https://api.github.com/repos/stepancheg/rust-protobuf/tarball/v${RUST_PROTOBUF_VERSION} | tar xvz --strip 1 -C /rust-protobuf
RUN cd /rust-protobuf/protobuf-codegen && \
    cargo build --target=x86_64-unknown-linux-musl --release
RUN mkdir -p /out/usr/bin && \
    strip /rust-protobuf/target/x86_64-unknown-linux-musl/release/protoc-gen-rust && \
    install /rust-protobuf/target/x86_64-unknown-linux-musl/release/protoc-gen-rust /out/usr/bin/

ARG GRPC_RUST_VERSION
RUN mkdir -p /grpc-rust && \
    curl -L https://api.github.com/repos/stepancheg/grpc-rust/tarball/v${GRPC_RUST_VERSION} | tar xvz --strip 1 -C /grpc-rust
RUN cd /grpc-rust/grpc-compiler && \
    cargo build --target=x86_64-unknown-linux-musl --release
RUN mkdir -p /out/usr/bin && \
    strip /grpc-rust/target/x86_64-unknown-linux-musl/release/protoc-gen-rust-grpc && \
    install /grpc-rust/target/x86_64-unknown-linux-musl/release/protoc-gen-rust-grpc /out/usr/bin/

FROM znly/upx as packer
COPY --from=protoc_builder /out/ /out/
RUN upx --lzma \
        /out/usr/bin/protoc \
        /out/usr/bin/grpc_* \
        /out/usr/bin/protoc-gen-*


FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Roman Volosatovs <rvolosatovs@thethingsnetwork.org>"
COPY --from=packer /out/ /
COPY --from=rust_builder /out/ /
COPY --from=swift_builder /protoc-gen-swift /protoc-gen-swift
RUN apk add --no-cache bash libstdc++ && \
for p in protoc-gen-swift protoc-gen-swiftgrpc; do \
        ln -s /protoc-gen-swift/${p} /usr/bin/${p}; \
    done

RUN ln -s /usr/bin/grpc_node_plugin /usr/bin/grpc_js_plugin
RUN ln -s /usr/bin/grpc_objective_c_plugin /usr/bin/grpc_objc_plugin

RUN for lang in cpp csharp js objc php python ruby; do ln -s /usr/bin/grpc_${lang}_plugin /usr/bin/protoc-gen-${lang}-grpc; done

RUN ln -s /usr/bin/protoc-gen-swiftgrpc /usr/bin/protoc-gen-swift-grpc

COPY protoc-wrapper /usr/bin/protoc-wrapper
ENTRYPOINT ["protoc-wrapper", "-I/usr/include"]
