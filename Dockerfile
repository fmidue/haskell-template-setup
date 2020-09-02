ARG TAG=16.11
FROM fpco/stack-build:${TAG} as build
RUN apt-get update && apt-get install -y \
    bbe \
    curl \
    rsync
COPY . /build
WORKDIR /build
RUN for i in $(sed 's/#.*$//' env); do export $i; done \
 && make -e build \
 && make -e install
