
# ussh: an almost invisible ssh connection
function ussh () {
  ssh -o UserKnownHostsFile=/dev/null -T $1 /bin/bash -i
}

