FROM alpine:3.4
MAINTAINER Steeve Morin <steeve@zen.ly>

ENV GRPC_VERSION 1.0.x
ENV PROTOBUF_VERSION 3.0.0
ENV GOPATH /go

RUN apk add --update build-base curl automake autoconf libtool git go zlib-dev && \
    curl -L https://github.com/google/protobuf/archive/v${PROTOBUF_VERSION}.tar.gz | tar xvz && \
    cd /protobuf-${PROTOBUF_VERSION} && \
        ./autogen.sh && \
        ./configure --prefix=/usr && \
        make && make install && \
        rm -rf `pwd` && cd / && \
    git clone --recursive -b v${GRPC_VERSION} https://github.com/grpc/grpc.git && \
    cd /grpc/third_party/protobuf && git checkout v${PROTOBUF_VERSION} && \
    cd /grpc && \
        make plugins && make install-plugins prefix=/usr && \
        rm -rf `pwd` && cd / && \
    curl -L https://github.com/grpc/grpc-java/archive/v${GRPC_VERSION}.tar.gz | tar xvz && \
    cd /grpc-java-${GRPC_VERSION}/compiler/src/java_plugin/cpp && \
        g++ -I. -lprotoc -lprotobuf -lpthread --std=c++0x -s -o protoc-gen-grpc-java *.cpp && \
        install -c protoc-gen-grpc-java /usr/bin/ && \
        rm -rf /grpc-java-${GRPC_VERSION} && cd / && \
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
