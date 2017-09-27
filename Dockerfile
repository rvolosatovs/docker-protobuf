ARG LLVM_VERSION=5.0.0
ARG SWIFT_VERSION=4.0
ARG TTN_VERSION=2.8.1
ARG GLIDE_VERSION=0.12.3
ARG PROTOBUF_C_VERSION=1.3.0
ARG RUST_PROTOBUF_VERSION=1.4.1
ARG GRPC_VERSION=1.6.2
ARG GRPC_JAVA_VERSION=1.6.1 
ARG GRPC_RUST_VERSION=0.2.1
ARG GRPC_SWIFT_VERSION=0.2.3
ARG PROTOC_GEN_LINT_VERSION=0.1.3
ARG PROTOC_GEN_DOC_VERSION=1.0.0-rc

FROM alpine:3.6 as protoc_builder

ARG PROTOBUF_C_VERSION
ARG GRPC_VERSION
ARG GRPC_JAVA_VERSION
ARG PROTOC_GEN_LINT_VERSION
ARG PROTOC_GEN_DOC_VERSION
ARG TTN_VERSION
ARG GLIDE_VERSION

RUN apk add --no-cache build-base curl automake autoconf libtool git zlib-dev

RUN mkdir -p /out
RUN git clone --recursive --depth=1 -b v${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc && \
    ln -s /grpc/third_party/protobuf /protobuf
RUN mkdir -p /grpc-java && \
    curl -L https://api.github.com/repos/grpc/grpc-java/tarball/v${GRPC_JAVA_VERSION} | tar xvz -C /grpc-java --strip-components=1
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
    install -c protoc-gen-grpc-java /out/usr/bin/
RUN cd /protobuf-c && \
    make install DESTDIR=/out
RUN find /out -name "*.a" -delete -or -name "*.la" -delete

RUN apk add --no-cache go
ENV GOPATH=/go \
    PATH=/go/bin/:$PATH

RUN mkdir -p ${GOPATH}/src/github.com/TheThingsNetwork/ttn && \
    curl -L https://api.github.com/repos/TheThingsNetwork/ttn/tarball/v${TTN_VERSION} | tar xvz -C ${GOPATH}/src/github.com/TheThingsNetwork/ttn --strip-components=1
RUN cd ${GOPATH}/src/github.com/TheThingsNetwork/ttn && \
    make dev-deps deps && \
    go install -v -ldflags '-w -s' ./utils/protoc-gen-gogottn

RUN go get -v -ldflags '-w -s' github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
    
RUN go get -d github.com/ckaznocha/protoc-gen-lint
RUN cd ${GOPATH}/src/github.com/ckaznocha/protoc-gen-lint && \
    git checkout v${PROTOC_GEN_LINT_VERSION} && \
    go install -v -ldflags '-w -s' .

RUN curl -L https://github.com/Masterminds/glide/releases/download/v${GLIDE_VERSION}/glide-v${GLIDE_VERSION}-linux-amd64.tar.gz | tar xvz --strip 1 -C /tmp && \
    install -c /tmp/glide /usr/bin
RUN mkdir -p ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    curl -L https://api.github.com/repos/pseudomuto/protoc-gen-doc/tarball/v${PROTOC_GEN_DOC_VERSION} | tar xvz --strip 1 -C ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc
RUN go install -v -ldflags '-w -s' github.com/pseudomuto/protoc-gen-doc

RUN install -c ${GOPATH}/bin/protoc-gen* /out/usr/bin/


FROM ubuntu:16.04 as swift_builder
RUN apt-get update && \
    apt-get install -y build-essential make tar xz-utils bzip2 gzip sed \
    libz-dev unzip patchelf curl libedit-dev python2.7 python2.7-dev libxml2 \
    git libxml2-dev uuid-dev libssl-dev bash patch
ARG SWIFT_VERSION
ARG LLVM_VERSION
RUN curl -L http://releases.llvm.org/${LLVM_VERSION}/clang+llvm-${LLVM_VERSION}-linux-x86_64-ubuntu16.04.tar.xz | tar --strip-components 1 -C /usr/local/ -xJv
RUN curl -L https://swift.org/builds/swift-${SWIFT_VERSION}-release/ubuntu1604/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-ubuntu16.04.tar.gz | tar --strip-components 1 -C / -xz
ARG GRPC_SWIFT_VERSION
RUN mkdir -p /grpc-swift && \
    curl -L https://api.github.com/repos/grpc/grpc-swift/tarball/${GRPC_SWIFT_VERSION} | tar --strip-components 1 -C /grpc-swift -xz
RUN apt-get install -y libcurl4-openssl-dev
RUN cd /grpc-swift/Plugin && \
    make
RUN mkdir -p /protoc-gen-swift && \
    cp /grpc-swift/Plugin/protoc-gen-swift /protoc-gen-swift/ && \
    cp /grpc-swift/Plugin/protoc-gen-swiftgrpc /protoc-gen-swift/
RUN cp /lib64/ld-linux-x86-64.so.2 \
        $(ldd /protoc-gen-swift/protoc-gen-swift /protoc-gen-swift/protoc-gen-swiftgrpc | awk '{print $3}' | grep /lib | sort | uniq) \
        /protoc-gen-swift/
RUN find /protoc-gen-swift/ -name 'lib*.so*' -exec patchelf --set-rpath /protoc-gen-swift {} \; && \
    for p in protoc-gen-swift protoc-gen-swiftgrpc; do \
        patchelf --set-interpreter /protoc-gen-swift/ld-linux-x86-64.so.2 /protoc-gen-swift/${p}; \
    done

    
FROM rust:1.20.0 as rust_builder
ARG RUST_PROTOBUF_VERSION
ARG GRPC_RUST_VERSION
RUN mkdir -p /out
RUN apt-get update && \
    apt-get install -y musl-tools
RUN rustup target add x86_64-unknown-linux-musl
ENV RUSTFLAGS='-C linker=musl-gcc'

RUN mkdir -p /rust-protobuf && \
    curl -L https://api.github.com/repos/stepancheg/rust-protobuf/tarball/v${RUST_PROTOBUF_VERSION} | tar xvz --strip 1 -C /rust-protobuf
RUN cd /rust-protobuf/protobuf && \
    cargo build --target=x86_64-unknown-linux-musl --release
RUN mkdir -p /out/usr/bin && \
    strip /rust-protobuf/target/x86_64-unknown-linux-musl/release/protoc-gen-rust && \
    install -c /rust-protobuf/target/x86_64-unknown-linux-musl/release/protoc-gen-rust /out/usr/bin/

RUN mkdir -p /grpc-rust && \
    curl -L https://api.github.com/repos/stepancheg/grpc-rust/tarball/v${GRPC_RUST_VERSION} | tar xvz --strip 1 -C /grpc-rust
RUN cd /grpc-rust/grpc-compiler && \
    cargo build --target=x86_64-unknown-linux-musl --release
RUN mkdir -p /out/usr/bin && \
    strip /grpc-rust/target/x86_64-unknown-linux-musl/release/protoc-gen-rust-grpc && \
    install -c /grpc-rust/target/x86_64-unknown-linux-musl/release/protoc-gen-rust-grpc /out/usr/bin/

FROM znly/upx as packer
COPY --from=protoc_builder /out/ /out/
RUN upx --lzma \
        /out/usr/bin/protoc \
        /out/usr/bin/grpc_* \
        /out/usr/bin/protoc-gen-*


FROM alpine:3.6
LABEL maintainer="Roman Volosatovs <rvolosatovs@thethingsnetwork.org>"
COPY --from=packer /out/ /
COPY --from=rust_builder /out/ /
COPY --from=swift_builder /protoc-gen-swift /protoc-gen-swift
RUN apk add --no-cache bash libstdc++ && \
for p in protoc-gen-swift protoc-gen-swiftgrpc; do \
        ln -s /protoc-gen-swift/${p} /usr/bin/${p}; \
    done

COPY protoc-wrapper /usr/bin/protoc-wrapper
ENTRYPOINT ["protoc-wrapper", "-I/usr/include"]
