#!/bin/bash
cd ~
script=Mambaforge-$(uname)-$(uname -m).sh
wget https://github.com/conda-forge/miniforge/releases/latest/download/$script
bash $script -b -p ./mambaforge
rm $script
mambaforge/condabin/conda init
wget https://raw.githubusercontent.com/vhewes/numl-docker/main/numl.yml
mambaforge/condabin/conda env create -f numl.yml
rm numl.yml
cmd="\"source ~/.bashrc\""
echo $cmd
if ! grep -qv $cmd ~/.bash_profile; then
  echo $cmd >> ~/.bash_profile
fi

echo "numl environment successfully initialised! log out and log back in, and activate with \"conda activate numl\""
