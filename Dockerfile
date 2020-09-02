ARG TAG=16.11
FROM fpco/stack-build:${TAG} as build
RUN apt-get update && apt-get install -y \
    bbe \
    curl \
    rsync
COPY . /build
WORKDIR /build
RUN export IFS='#'; for i in $(sed 's/#.*$//' env | tr '\n' '#'); do export $i; done\
 && ( test -z ${INSTALL_NEW_GHC+x}\
  || rm -rf /home/stackage/.stack/programs/x86_64-linux/ghc-* )\
 && unset IFS\
 && make -e build\
 && make -e install
