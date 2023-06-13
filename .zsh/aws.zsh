ec2_instance_connect () {
	tf=$(mktemp)
	aws ec2 describe-instances --instance-ids $@ > $tf

	for inst AZ in $(jq -r '.Reservations[].Instances[] | "\(.InstanceId) \(.Placement.AvailabilityZone)"' $tf)
	do
		aws ec2-instance-connect send-ssh-public-key \
			--instance-id $inst \
			--availability-zone $AZ \
			--instance-os-user ubuntu \
			--ssh-public-key file://$HOME/.ssh/suess_rsa.pub
	done

	cssh -l ubuntu $(jq -r '.Reservations[].Instances[].PublicIpAddress' $tf)
}

ec2_node_connect () {
	if [ ${#@} -gt 1 ]
	then
	  tf=$(mktemp)
	  kubectl get nodes $@ -o json > $tf

	  for AZ_INSTANCE in $(jq -r '.items[].spec.providerID' $tf | cut -d "/" -f4-5)
	  do
	    AZ=$(echo $AZ_INSTANCE | cut -d "/" -f1)
	    INSTANCE_ID=$(echo $AZ_INSTANCE | cut -d "/" -f2)
	    aws ec2-instance-connect send-ssh-public-key \
		--instance-id $INSTANCE_ID \
		--availability-zone $AZ \
		--instance-os-user ubuntu \
		--ssh-public-key file://$HOME/.ssh/suess_rsa.pub
	    #--ssh-public-key file://$HOME/.ssh/sandor-lab_ed25519.pub
	  done
	  cssh -l ubuntu $(jq -r '.items[].status.addresses[] | select(.type=="ExternalIP") | .address' $tf)

        elif [ ${#@} -eq 1 ]
        then
	  tf=$(mktemp)
	  kubectl get nodes $@ -o json > $tf
          AZ_INSTANCE=$(jq -r '.spec.providerID' $tf | cut -d "/" -f4-5)
	  AZ=$(echo $AZ_INSTANCE | cut -d "/" -f1)
	  INSTANCE_ID=$(echo $AZ_INSTANCE | cut -d "/" -f2)
	  aws ec2-instance-connect send-ssh-public-key \
	      --instance-id $INSTANCE_ID \
	      --availability-zone $AZ \
	      --instance-os-user ubuntu \
	      --ssh-public-key file://$HOME/.ssh/suess_rsa.pub
	  cssh -l ubuntu $(jq -r '.status.addresses[] | select(.type=="ExternalIP") | .address' $tf)

        else
          echo "ec2_node_connect <k8s-node> [<k8s-node>..]"
        fi
}

ec2_label_connect () {
	tf=$(mktemp)
	kubectl get nodes -l $1 -o json > $tf

	for AZ_INSTANCE in $(jq -r '.items[].spec.providerID' $tf | cut -d "/" -f4-5)
	do
		AZ=$(echo $AZ_INSTANCE | cut -d "/" -f1)
		INSTANCE_ID=$(echo $AZ_INSTANCE | cut -d "/" -f2)
		aws ec2-instance-connect send-ssh-public-key \
			--instance-id $INSTANCE_ID \
			--availability-zone $AZ \
			--instance-os-user ubuntu \
			--ssh-public-key file://$HOME/.ssh/suess_rsa.pub &
	done
        sleep 10
	cssh -l ubuntu $(jq -r '.items[].status.addresses[] | select(.type=="ExternalIP") | .address' $tf)
}
ec2_label_ssh () {
	tf=$(mktemp)
	kubectl get nodes -l $1 -o json > $tf

	cssh -l ubuntu $(jq -r '.items[].status.addresses[] | select(.type=="ExternalIP") | .address' $tf)
}

aws_instance_name_to_instanceID () {
	aws ec2 describe-instances | jq -r ".Reservations[].Instances[] | select(.PrivateDnsName == \"$1\") | .InstanceId"
}

aws_etcd_instance_ids_and_names () {
	aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.Tags[].Value == "etcd-cluster-etcd") | "\(.InstanceId) \(.PrivateDnsName)"' | sort | uniq
}
