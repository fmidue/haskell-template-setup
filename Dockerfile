# syntax=docker.io/docker/dockerfile:1.7-labs
ARG IMAGE_TAG
FROM ${IMAGE_TAG} as build
RUN apt-get update && apt-get install -y \
    bbe \
    curl \
    libz3-dev \
    rsync
RUN curl -sSL https://get.haskellstack.org/ | sh
COPY . /build
WORKDIR /build
ARG INSTALL_NEW_GHC
RUN stack build --dry-run\
 && ( test -z ${INSTALL_NEW_GHC+x}\
  || rm -rf /home/stackage/.stack/programs/x86_64-linux/ghc-* )
ARG PKG_DB
ARG ROOT
RUN make -e build\
 && make -e install
RUN sed -e "s|/root/.stack/programs/.*/rts|${ROOT}/rts|" -e "s|/root/.stack/programs/.*/include|${ROOT}/include|" -i ${PKG_DB}/rts.conf || true
RUN bash -c "shopt -s globstar && cp -r /root/.stack/programs/**/ghc-*/rts ${ROOT}/ && cp -r /root/.stack/**/include ${ROOT}" || true
RUN stack exec -- ghc-pkg recache --package-db=${PKG_DB} && stack exec -- ghc-pkg check --package-db=${PKG_DB}
