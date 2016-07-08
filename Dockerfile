FROM alpine:3.4
MAINTAINER Steeve Morin <steeve@zen.ly>

ENV GOPATH /go

RUN apk add --update build-base curl automake autoconf libtool git go zlib-dev && \
    curl -L https://github.com/google/protobuf/archive/v3.0.0-beta-3.1.tar.gz | tar xvz && \
    cd /protobuf-3.0.0-beta-3.1 && \
        ./autogen.sh && \
        ./configure --prefix=/usr && \
        make && make install && \
        rm -rf `pwd` && cd / && \
    curl -L https://github.com/grpc/grpc/archive/release-0_14_1.tar.gz | tar xvz && \
    cd /grpc-release-0_14_1 && \
        make plugins && make install-plugins prefix=/usr && \
        rm -rf `pwd` && cd / && \
    curl -L https://github.com/grpc/grpc-java/archive/v0.14.1.tar.gz | tar xvz && \
    cd /grpc-java-0.14.1/compiler/src/java_plugin/cpp && \
        GRPC_VERSION=0.14.1 g++ -I. -lprotoc -lprotobuf -lpthread --std=c++0x -s -o protoc-gen-grpc-java *.cpp && \
        install -c protoc-gen-grpc-java /usr/bin/ && \
        rm -rf /grpc-java-0.14.1 && cd / && \
    go get \
        go.pedge.io/protoeasy/cmd/protoeasy \
        github.com/golang/protobuf/protoc-gen-go \
        github.com/gogo/protobuf/protoc-gen-gofast \
        github.com/gogo/protobuf/protoc-gen-gogo \
        github.com/gogo/protobuf/protoc-gen-gogofast \
        github.com/gogo/protobuf/protoc-gen-gogofaster \
        github.com/gogo/protobuf/protoc-gen-gogoslick \
        github.com/gengo/grpc-gateway/protoc-gen-grpc-gateway \
        github.com/gengo/grpc-gateway/protoc-gen-swagger && \
    install -c /go/bin/* /usr/bin/ && \
    rm -rf /go/* && \
    curl -L https://github.com/peter-edge/pb/archive/master.tar.gz | tar xvz && \
        mkdir -p ${GOPATH}/src/go.pedge.io/protoeasy/vendor/go.pedge.io/pb/ && \
        mv pb-master/proto ${GOPATH}/src/go.pedge.io/protoeasy/vendor/go.pedge.io/pb/proto && \
        rm -rf pb-master && \
    apk del build-base curl automake autoconf libtool git go zlib-dev && \
    find /usr/lib -name "*.a" -or -name "*.la" -delete && \
    apk add libstdc++
