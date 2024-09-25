# syntax=docker.io/docker/dockerfile:1.7-labs
ARG IMAGE_TAG=ubuntu:20.04
FROM ${IMAGE_TAG} as build
RUN apt-get update && apt-get install -y \
    bbe \
    curl \
    libz3-dev \
    rsync
RUN curl -sSL https://get.haskellstack.org/ | sh
COPY . /build
WORKDIR /build
RUN export IFS='#'; for i in $(sed 's/#.*$//' env | tr '\n' '#'); do export $i; done\
 && ( test -z ${INSTALL_NEW_GHC+x}\
  || rm -rf /home/stackage/.stack/programs/x86_64-linux/ghc-* )\
 && unset IFS\
 && make -e build\
 && make -e install
RUN sed -e 's|/root/.stack/programs/.*/rts|/autotool/default/rts|' -e 's|/root/.stack/programs/.*/include|/autotool/default/include|' -i /autotool/default/pkgdb/rts.conf || true
RUN bash -c "shopt -s globstar && cp -r /root/.stack/programs/**/ghc-*/rts /autotool/default/ && cp -r /root/.stack/**/include /autotool/default" || true
RUN stack exec -- ghc-pkg recache --package-db=/autotool/default/pkgdb && stack exec -- ghc-pkg check --package-db=/autotool/default/pkgdb
