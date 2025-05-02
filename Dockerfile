#syntax=docker.io/docker/dockerfile-upstream:1.15.1-labs
ARG IMAGE_TAG
FROM ${IMAGE_TAG} as build
RUN <<INSTALL_STACK
apt-get update && apt-get install -y \
  bbe \
  curl \
  libz3-dev \
  rsync
curl -sSL https://get.haskellstack.org/ | sh
INSTALL_STACK
COPY --exclude=Makefile . /build
WORKDIR /build
ARG INSTALL_NEW_GHC
ARG ROOT
RUN <<PREPARE
mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
printf "\nconfigure-options:\n  \$everything:\n  - --datadir=%s" "${ROOT}/share">> stack.yaml
PREPARE
RUN --mount=type=ssh stack build --dry-run
RUN <<INSTALL_PACKAGE
( test -z ${INSTALL_NEW_GHC+x}\
  || rm -rf /home/stackage/.stack/programs/x86_64-linux/ghc-* )
make -f Makefile.build -e build
INSTALL_PACKAGE
ARG PKG_DB
COPY Makefile /build
RUN <<MOVE_PKG_DB
make -e install
sed -e "s|/root/.stack/programs/.*/rts|${ROOT}/rts|" -e "s|/root/.stack/programs/.*/include|${ROOT}/include|" -i ${PKG_DB}/rts.conf || true
bash -c "shopt -s globstar && cp -r /root/.stack/programs/**/ghc-*/rts ${ROOT}/ && cp -r /root/.stack/**/include ${ROOT}" || true
stack exec -- ghc-pkg recache --package-db=${PKG_DB} && stack exec -- ghc-pkg check --package-db=${PKG_DB}
MOVE_PKG_DB
