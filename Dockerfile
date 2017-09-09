FROM alpine:3.6 as protoc_builder
RUN apk add --no-cache build-base curl automake autoconf libtool git zlib-dev

ENV GRPC_VERSION=1.6.0              \
    GRPC_JAVA_VERSION=1.6.1         \
    PROTOBUF_VERSION=3.4.0          \
    DESTDIR=/out

RUN mkdir -p /protobuf && \
    curl -L https://github.com/google/protobuf/archive/v${PROTOBUF_VERSION}.tar.gz | tar xvz --strip-components=1 -C /protobuf
RUN git clone --depth 1 --recursive -b v${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc && \
    rm -rf grpc/third_party/protobuf && \
    ln -s /protobuf /grpc/third_party/protobuf
RUN mkdir -p /grpc-java && \
    curl -L https://github.com/grpc/grpc-java/archive/v${GRPC_JAVA_VERSION}.tar.gz | tar xvz --strip-components=1 -C /grpc-java
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
RUN cd /protobuf && \
    make install DESTDIR=${DESTDIR}
RUN cd /grpc && \
    make install-plugins prefix=${DESTDIR}/usr
RUN cd /grpc-java/compiler/src/java_plugin/cpp && \
    install -c protoc-gen-grpc-java ${DESTDIR}/usr/bin/
RUN find ${DESTDIR} -name "*.a" -delete -or -name "*.la" -delete

RUN apk add --no-cache go
ENV GOPATH=/go
RUN go get -u -v -ldflags '-w -s' \
        github.com/golang/protobuf/protoc-gen-go \
        github.com/gogo/protobuf/protoc-gen-gofast \
        github.com/gogo/protobuf/protoc-gen-gogo \
        github.com/gogo/protobuf/protoc-gen-gogofast \
        github.com/gogo/protobuf/protoc-gen-gogofaster \
        github.com/gogo/protobuf/protoc-gen-gogoslick \
        github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger \
        github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway && \
        github.com/johanbrandhorst/protobuf/protoc-gen-gopherjs && \
        github.com/ckaznocha/protoc-gen-lint && \
    install -c /go/bin/* ${DESTDIR}/usr/bin/


FROM swiftdocker/swift:3.1.1 as swift_builder
RUN apt-get update && \
    apt-get install -y libz-dev unzip patchelf

ENV SWIFT_GRPC_VERSION=0.2.2

RUN mkdir -p /grpc-swift && \
    curl -L https://github.com/grpc/grpc-swift/archive/${SWIFT_GRPC_VERSION}.tar.gz | tar xvz --strip-components=1 -C /grpc-swift
RUN cd grpc-swift/Plugin && \
    make
RUN mkdir -p /protoc-gen-swift/
RUN cp grpc-swift/Plugin/protoc-gen-swift* /protoc-gen-swift/
RUN cp /lib64/ld-linux-x86-64.so.2 \
        $(ldd grpc-swift/Plugin/protoc-gen-swift* | awk '{print $3}' | grep /lib | sort | uniq) \
        /protoc-gen-swift/

RUN find /protoc-gen-swift/ -name 'lib*.so*' -exec patchelf --set-rpath /protoc-gen-swift {} \; && \
    for p in protoc-gen-swift protoc-gen-swiftgrpc; do \
        patchelf --set-interpreter /protoc-gen-swift/ld-linux-x86-64.so.2 /protoc-gen-swift/${p}; \
    done


FROM znly/upx as packer
COPY --from=protoc_builder /out/ /out/
RUN upx --lzma \
        /out/usr/bin/* \
        /out/usr/local/bin/*
RUN rm -rf \
        /out/usr/bin/protoc \
        /out/usr/lib/libproto*


FROM alpine:3.6
RUN apk add --no-cache libstdc++
COPY --from=packer /out/ /
COPY --from=swift_builder /protoc-gen-swift /protoc-gen-swift
RUN for p in protoc-gen-swift protoc-gen-swiftgrpc; do \
        ln -s /protoc-gen-swift/${p} /usr/bin/${p}; \
    done
RUN apk add --no-cache curl && \
    mkdir -p /protobuf/google/protobuf && \
        for f in any duration descriptor empty struct timestamp wrappers; do \
            curl -L -o /protobuf/google/protobuf/${f}.proto https://raw.githubusercontent.com/google/protobuf/master/src/google/protobuf/${f}.proto; \
        done && \
    mkdir -p /protobuf/google/api && \
        for f in annotations http; do \
            curl -L -o /protobuf/google/api/${f}.proto https://raw.githubusercontent.com/grpc-ecosystem/grpc-gateway/master/third_party/googleapis/google/api/${f}.proto; \
        done && \
    mkdir -p /protobuf/github.com/gogo/protobuf/gogoproto && \
        curl -L -o /protobuf/github.com/gogo/protobuf/gogoproto/gogo.proto https://raw.githubusercontent.com/gogo/protobuf/master/gogoproto/gogo.proto && \
    apk del curl
ENTRYPOINT ["/usr/local/bin/protoc", "-I/protobuf"]
