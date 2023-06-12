ARG TAG=20.04
FROM ubuntu:${TAG} as build
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
RUN sed -e 's|/root/.stack/programs/.*/rts|/autotool/default/rts|' -e 's|/root/.stack/programs/.*/include|/autotool/default/include|' -i /autotool/default/pkgdb/rts.conf
RUN bash -c "shopt -s globstar && cp -r /root/.stack/programs/**/ghc-*/rts /autotool/default/ && cp -r /root/.stack/**/include /autotool/default"
RUN stack exec -- ghc-pkg recache --package-db=/autotool/default/pkgdb && stack exec -- ghc-pkg check --package-db=/autotool/default/pkgdb
