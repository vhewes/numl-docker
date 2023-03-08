#!/bin/bash

function build_torch {
  if [[ $# != 2 ]]; then
    echo error: you must provide PyTorch and CUDA versions as arguments
    exit
  fi
  torch=$1
  cuda=$2
  tag=torch${torch}-cu${cuda}
  echo Generating image tag $tag with PyTorch version $torch and CUDA version $cuda
  docker build --rm -t vhewes/numl:$tag --build-arg TORCH=$torch --build-arg CUDA=$cuda --target pytorch .
}

docker build --no-cache --rm -t vhewes/numl:base --target base .
build_torch 1.12 11.6
build_torch 1.13 11.7
docker build --rm -t vhewes/numl:torch1.13-cu11.7-pandana \
        --build-arg TORCH=1.13 --build-arg CUDA=11.7 \
	--build-arg SSH_KEY="$(cat ~/.ssh/id_ed25519)" \
	--target nova .
