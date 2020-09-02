#!/usr/bin/env zsh
RESOLVER=$(sed -n 's/resolver: \(.*\)/\1/p' stack.yaml)
echo using resolver: ${RESOLVER}
source env
docker build --build-arg TAG=${RESOLVER} -t haskell-template-setup .
docker create --name haskell-template-setup haskell-template-setup
docker cp haskell-template-setup:$ROOT $PWD/root
docker rm -f haskell-template-setup
echo copied $ROOT to $PWD/root/$(basename $ROOT)
