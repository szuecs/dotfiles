# add current kubernetes cluster and namespace (if set) to the prompt.
# Prefix with `gke:` if this is a google container engine cluser.
#
#   ‹cluster-01›
#   ‹gke:cluster-01›
#   ‹gke:cluster-01/production›
#
function kube_info() {
  local PREFIX="‹"
  local SUFFIX="›"
  local COLOR="%{${FG[140]}%}"

  local cluster=$(kubectl config current-context 2>/dev/null)
  if [[ -z "$cluster" ]]; then
    return
  fi
  local cluster_shortname=$(awk -F_ '{print $NF}' <<< "$cluster")
  local namespace=$(kubectl config view -o jsonpath --template "{.contexts[?(@.name==\"$cluster\")].context.namespace}" 2>/dev/null)

  if [[ "$cluster" == gke* ]]; then
    local cluster_shortname="gke:$cluster_shortname"
  fi

  if [[ ! -z "$namespace" ]]; then
    namespace="/$namespace"
  fi
  echo "$COLOR$PREFIX$cluster_shortname$namespace$SUFFIX%{${reset_color}%} "
}
