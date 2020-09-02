#!/usr/bin/env zsh
source env
if ! [[ -v RESOLVER ]]
then
  IMAGE_TAG=$(sed -n 's/resolver: \(.*\)/\1/p' stack.yaml)
fi
echo using stack image with tag ${IMAGE_TAG}
docker build --build-arg TAG=${IMAGE_TAG} -t haskell-template-setup .
docker create --name haskell-template-setup haskell-template-setup
rm -rf root
docker cp haskell-template-setup:$ROOT $PWD/root
docker rm -f haskell-template-setup
echo copied $ROOT to $PWD/root
