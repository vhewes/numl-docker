if [ $(hostname) == "Heimdall" ]; then
  export APPTAINER_CACHEDIR=/raid/apptainer/.cache
fi  
apptainer build --fix-perms numl:torch1.13-cu11.7.sif docker://vhewes/numl:torch1.12-cu11.6
apptainer build --fix-perms numl:torch1.13-cu11.7.sif docker://vhewes/numl:torch1.13-cu11.7
