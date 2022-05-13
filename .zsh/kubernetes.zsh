# zsh completion
source <(kubectl completion zsh )

alias kubectl_s='kubectl -n kube-system'
alias sexec='kubectl -n kube-system exec -it'

function k8s_logs_by_application_label() {
	if [ $2 ]
	then
		kubectl -n $1 logs -l application=$2
	elif [ $1 ]
	then
		kubectl -n kube-system logs -l application=$1
	else
		kubectl -n kube-system logs
	fi
}
alias slog="k8s_logs_by_application_label"

function k8s_logs_by_application_label_f() {
	if [ $2 ]
	then
		kubectl -n $1 logs -f -l application=$2
	elif [ $1 ]
	then
		kubectl -n kube-system logs -f -l application=$1
	else
		kubectl -n kube-system logs -f
	fi
}
alias slogf="k8s_logs_by_application_label_f"

# get all pods filtered by application label, defaults to kube-system namespace
function k8s_pods_by_application_label() {
	if [ $2 ]
	then
		kubectl -n $1 get pods -o wide -l application=$2
	elif [ $1 ]
	then
		kubectl -n kube-system get pods -o wide -l application=$1
	else
		kubectl -n kube-system get pods -o wide
	fi
}
alias sapps="k8s_pods_by_application_label"
alias apps="k8s_pods_by_application_label default"

function k8s_pod_states_by_application_label() {
	k8s_pods_by_application_label $1 | awk '
	BEGIN{
		run=0; term=0;pend=0;other=0
	}
	$1 != "NAME"
	{
		if ($3 == "Running") {run=run+1}
		else if ($3 == "Terminating") {term=term+1}
		else if ($3 == "Pending") {pend=pend+1}
		else {other=other+1}
	}
	END{
		print "running: "run"\nterminating: "term"\npending: "pend"\nother: "other
	}'
}
alias states="k8s_pod_states_by_application_label"

function k8s_delete_pods_by_application_label() {
	PODS=$(k8s_pods_by_application_label $* | awk '$1 != "NAME" {print $1}' | xargs echo -n "$1")
	NS=kube-system
	if [ $2 ]
	then
		NS=$1
	fi
	set -x
	kubectl -n $NS delete pods $PODS
	set +x
}
alias dapps="k8s_delete_pods_by_application_label"

# get all replicasets which are not behaving well, defaults to kube-system namespace
function k8s_rs_desired_not_ready {
	if [ $1 ]
	then
		kubectl get rs -n $1 | awk '$2 != $3 || $2 != $4 {print $0}'
	else
		kubectl get rs -n kube-system | awk '$2 != $3 || $2 != $4 {print $0}'
	fi
}

function k8s_capacity_per_node () {
	kubectl get nodes -o jsonpath='{"CPU\tMemory\n"}{range .items[*]}{.status.capacity.cpu}{"\t"}{.status.capacity.memory}{"\n"}{end}'
}

# get all node taints
function k8s_nodes_taints_show () {
	kubectl get nodes -o template --template='{{printf "%-50s %-12s\n" "Node" "Taint"}}{{range.items}}{{printf	"%-50s %-12s" .metadata.name ( "None" | or (index .metadata.annotations "scheduler.alpha.kubernetes.io/taints")) }}{{ "\n" }}{{ end }}'
}

# show last 10 (re)started PODs
function k8s_pods_last10_restarted () {
	kubectl get pods --all-namespaces --sort-by='.status.containerStatuses[0].state.running.startedAt' -o jsonpath='{range .items[*]}{.metadata.name} restarts={.status.containerStatuses[0].restartCount} {.status.containerStatuses[0].state.running.startedAt} {"\n"}{end}' | tail -n 10
}

# pod application label selector
function k8s_pods_app () {
	if [ $1 ] && [ -z $2 ]
	then
		kubectl get pods -l application=$1
	elif [ $2 ]
	then
		kubectl get pods -l application=$1 -n $2
	else
		echo "you need to pass 1 or 2 args\n$0 <application-label> [<namespace>]"
	fi
}

# count pods per node
function k8s_pods_per_node_count () {
	kubectl get pods --all-namespaces -o json | jq '.items[] | .spec.nodeName' -r | sort | uniq -c | sort -n
}
# sum of requests per node
function k8s_cpu_requests_per_node_count () {
kubectl get pods --all-namespaces -o json | jq '.items[] | .spec.nodeName,.spec.containers[0].resources.requests.cpu' -r | ruby -e 'h={}; $stdin.readlines.map {|l| l.sub(/m$/, "")}.each_slice(2) {|a| h[a[0].gsub("\n","")] ||= 0; h[a[0].gsub("\n","")] += a[1].to_i}; h.map {|k,v| puts "#{k} #{v}m"}'
}
function k8s_mem_requests_per_node_count () {
	kubectl get pods --all-namespaces -o json | jq '.items[] | .spec.nodeName,.spec.containers[0].resources.requests.memory ' -r | ruby -e 'h={}; $stdin.readlines.map {|l| s=l.sub("Gi", "*1024").sub("Mi", ""); if s.match(/\A[\s0-9*]+\z/); eval(s) ; else l; end}.each_slice(2) {|a| h[a[0].gsub("\n","")] ||= 0; h[a[0].gsub("\n","")] += a[1].to_i}; h.map {|k,v| puts "#{k} #{v}"}'
}
# node utilization
function k8s_node_utilization () {
	kubectl describe --all-namespaces=true nodes | grep -A 4 "Allocated resources" | grep "%"
}

# pods per node
function k8s_pods_per_node () {
	kubectl get pods --all-namespaces -o json | jq '.items | map({podName: .metadata.name, nodeName: .spec.nodeName}) | group_by(.nodeName) | map({nodeName: .[0].nodeName, pods: map(.podName)})'
}

function k8s_node_external_ip () {
	if [ $1 ]
	then
		kubectl get nodes -l ${1} -o jsonpath='{range .items[*]}{.metadata.name} {.status.addresses[?(@.type=="ExternalIP")].address}{"\n"}{end}'
	else
		kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.addresses[?(@.type=="ExternalIP")].address}{"\n"}{end}'
	fi
}

function k8s_node_internal_ip () {
	if [ $1 ]
	then
		kubectl get nodes -l ${1} -o jsonpath='{range .items[*]}{.metadata.name} {.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'
	else
		kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'
	fi
}

function k8s_node_az () {
	if [ $1 ]
	then
		kubectl get nodes -l failure-domain.beta.kubernetes.io/zone=eu-central-1$1 -L failure-domain.beta.kubernetes.io/zone -o wide
	else
		kubectl get nodes -L failure-domain.beta.kubernetes.io/zone -o wide
	fi
}

function k8s_node_type () {
	if [ $1 ]
	then
		kubectl get nodes -l beta.kubernetes.io/instance-type=$1 -L beta.kubernetes.io/instance-type -o wide
	else
		kubectl get nodes -L beta.kubernetes.io/instance-type -o wide
	fi
}

function k8s_deployment_resource_req() {
	kubectl -n kube-system get deployment $1 -o yaml | grep resources: -A 6
}
