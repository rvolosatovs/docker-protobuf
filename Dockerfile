FROM alpine:3.6
LABEL maintainer="Roman Volosatovs <rvolosatovs@thethingsnetwork.org>"

ARG GRPC_VERSION=1.4.2
ARG GRPC_JAVA_VERSION=1.4.0
ARG GRPC_SWIFT_VERSION=0.1.13
ARG PROTOBUF_C_VERSION=1.2.1
ARG PROTOBUF_SWIFT_VERSION=0.9.903
ENV GOPATH=/go

RUN apk add --no-cache build-base curl automake autoconf libtool git go zlib-dev
RUN git clone --recursive --depth=1 -b v${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc
ADD swift/resources/ld_library_path.patch /ld_library_path.patch
RUN cd /grpc/third_party/protobuf && \
    autoreconf -f -i -Wall,no-obsolete && \
    (cd ./src/google/protobuf/compiler/ && patch < /ld_library_path.patch) && \
    rm /ld_library_path.patch && \
    rm -rf autom4te.cache config.h.in~ && \
    ./configure --prefix=/usr --enable-static=no && \
    make && make install
RUN cd /grpc && \
    make plugins && make install-plugins prefix=/usr && \
    rm -rf `pwd`
RUN curl -L https://github.com/protobuf-c/protobuf-c/releases/download/v${PROTOBUF_C_VERSION}/protobuf-c-${PROTOBUF_C_VERSION}.tar.gz | tar xvz -C / && \
    cd /protobuf-c-${PROTOBUF_C_VERSION} && \
    ./configure --prefix=/usr && \
    make && make install && \
    rm -rf `pwd` && cd /
RUN curl -L https://github.com/grpc/grpc-java/archive/v${GRPC_JAVA_VERSION}.tar.gz | tar xvz -C / && \
    cd /grpc-java-${GRPC_JAVA_VERSION}/compiler/src/java_plugin/cpp && \
    g++ -I. *.cpp -lprotoc -lprotobuf -lpthread --std=c++0x -s -o protoc-gen-grpc-java && \
    install -c protoc-gen-grpc-java /usr/bin/ && \
    rm -rf /grpc-java-${GRPC_JAVA_VERSION} && cd /
RUN go get -v -ldflags "-w -s" \
        github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway \
        github.com/TheThingsNetwork/api/utils/protoc-gen-gogottn && \
    install -c $GOPATH/bin/* /usr/bin/ && \
    rm -rf $GOPATH
COPY /build/export-lib-${GRPC_SWIFT_VERSION}.tar /export-lib.tar
RUN tar xvf /export-lib.tar -C / && rm /export-lib.tar
RUN find /usr/lib -name "*.a" -delete -or -name "*.la" -delete
RUN apk del --no-cache build-base curl automake autoconf libtool git go zlib-dev && \
    apk add --no-cache libstdc++ make bash
ADD protoc-wrapper /usr/bin/protoc-wrapper
ENTRYPOINT ["protoc-wrapper", "-I/usr/include"]
