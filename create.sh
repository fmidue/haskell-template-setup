#!/usr/bin/env zsh
set -e
source env
export DOCKER_BUILDKIT=1
if ! [[ -v IMAGE_TAG ]]
then
  IMAGE_TAG=fpco/stack-build:$(sed -n 's/resolver: \(.*\)/\1/p' stack.yaml)
fi
if ! [[ -v PKG_DB ]]; then
  PKG_DB=${ROOT}/pkgdb
fi
echo using stack image with stack ${IMAGE_TAG}
docker build --build-arg="IMAGE_TAG=${IMAGE_TAG}" --build-arg="INSTALL_NEW_GHC=${INSTALL_NEW_GHC}" --build-arg="PKG_DB=${PKG_DB}" --build-arg="ROOT=${ROOT}" --ssh default -t haskell-template-setup .
docker create --name haskell-template-setup haskell-template-setup
rm -rf root
docker cp haskell-template-setup:$ROOT $PWD/root
docker rm -f haskell-template-setup
echo copied $ROOT to $PWD/root
