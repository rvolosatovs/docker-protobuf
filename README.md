# Protocol Buffers + Docker
All inclusive protoc suite, powered by Docker and Alpine Linux.

## What's included:
- protobuf 3.0.0
- gRPC 1.0.0
- Google Well Known Types are automatically included (via `google/`)
- Go related tools compiled with 1.7, gRPC support is built-in:
  - github.com/golang/protobuf/protoc-gen-go
  - github.com/gogo/protobuf/protoc-gen-gofast
  - github.com/gogo/protobuf/protoc-gen-gogo
  - github.com/gogo/protobuf/protoc-gen-gogofast
  - github.com/gogo/protobuf/protoc-gen-gogofaster
  - github.com/gogo/protobuf/protoc-gen-gogoslick

## Supported languages
- C++
- C#
- Java / JavaNano (Android)
- JavaScript
- Objective-C
- Python
- Ruby
- Go

## Usage
```
$ docker run --rm znly/protoc --help
Usage: /usr/bin/protoc [OPTION] PROTO_FILES
```

Don't forget you need to bind mount your files:
```
$ docker run --rm -v $(pwd) -w $(pwd) znly/protoc --python_out=. myfile.proto
```

## Google Well Known Types
They are embedded in the image and are included by `protoc` automatically.
They accessible via `google/protobuf/`:
```protobuf
syntax = "proto3";

import "google/protobuf/timestamp.proto";
import "google/protobuf/duration.proto";
```

## Image Size
The current currently sits at ~290mb and one layer. Most the space is spent on Go tools.
