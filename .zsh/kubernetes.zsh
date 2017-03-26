# zsh completion
source <(kubectl completion zsh )
# get all node taints
function k8s_taints_show () {
  kubectl get nodes -o template --template='{{printf "%-50s %-12s\n" "Node" "Taint"}}{{range.items}}{{printf  "%-50s %-12s" .metadata.name ( "None" | or (index .metadata.annotations "scheduler.alpha.kubernetes.io/taints")) }}{{ "\n" }}{{ end }}'
}