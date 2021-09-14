# Define a build image...
FROM golang:1.17.1-alpine AS build

# Prep for build.
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOARCH=amd64

# The Hugo version to compile.  Set here and below.
ENV HUGO_VERSION=0.88.1

WORKDIR /root/hugo

# Basic packages to perform the build.
RUN apk --no-cache add \
    wget git gcc g++ \
    musl-dev

# Download the source and compile it.
RUN cd /root/hugo && \
    wget https://github.com/gohugoio/hugo/archive/v${HUGO_VERSION}.tar.gz -O /root/hugo.tar.gz && \
    tar -zxf ../hugo.tar.gz && cd hugo-${HUGO_VERSION} && \
    go build -ldflags '-extldflags "-fno-PIC -static"' -buildmode pie -tags 'extended osusergo netgo static_build'

# All done with build.

# ---

FROM alpine:latest

# The Hugo version to compile.  Set here and above.
ENV HUGO_VERSION=0.88.1

# Copy Hugo from build.
COPY --from=build /root/hugo/hugo-${HUGO_VERSION}/hugo /hugo

# Install basic packages.
RUN apk update && \
    apk add --no-cache wget tar gzip zip bzip2 ca-certificates \
    python3 python3-dev py3-pip bzip2 file unzip curl

# Install pip and aws-cli.
RUN pip install awscli \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT [ "/hugo" ]