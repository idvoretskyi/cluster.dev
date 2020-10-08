#!/bin/bash
# Script for the provision rancher machine

main() {
hostname_gen
deploy_ssh_keys
software_install
}

hostname_gen() {
  echo "Hostname generation"
  hostname "rancher-worker" && hostname > /etc/hostname
  echo "127.0.0.1 localhost `hostname`" > /etc/hosts
}

deploy_ssh_keys(){
  echo "${ssh_public_keys}" > /root/.ssh/authorized_keys
  echo "${ssh_private_key}" > /root/.ssh/id_rsa
  chmod 600 /root/.ssh/id_rsa
}


software_install() {
  echo "Install additional software here..."
  curl https://releases.rancher.com/install-docker/19.03.13.sh | bash
  cat <<EOF > /etc/sysctl.d/90-kubelet.conf
vm.overcommit_memory = 1
vm.panic_on_oom = 0
kernel.panic = 10
kernel.panic_on_oops = 1
kernel.keys.root_maxkeys = 1000000
kernel.keys.root_maxbytes = 25000000
EOF
  apt-get update
  apt-get install -y jq
  sysctl -p /etc/sysctl.d/90-kubelet.conf
  sudo usermod -aG docker ubuntu
  set -x
  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" --insecure)
  PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $${TOKEN}" -s http://169.254.169.254/latest/meta-data/local-ipv4 --insecure)
  PUBLIC_IP=$${PRIVATE_IP} # Set public ip same as private.
  # $(curl -H "X-aws-ec2-metadata-token: $${TOKEN}" -s http://169.254.169.254/latest/meta-data/public-ipv4)
  K8S_ROLES="--worker"

  LOGINRESPONSE=$(curl -s 'https://${rancher_domain}/v3-public/localProviders/local?action=login' -H 'content-type: application/json' --data-binary '{"username":"admin","password":"${rancher_password}"}' --insecure)
  LOGINTOKEN=$(echo $${LOGINRESPONSE} | jq -r .token)

  APIRESPONSE=$(curl -s 'https://${rancher_domain}/v3/token' -H 'content-type: application/json' -H "Authorization: Bearer $${LOGINTOKEN}" --data-binary '{"type":"token","description":"automation"}' --insecure)
  APITOKEN=$(echo $${APIRESPONSE} | jq -r .token)
  # Create cluster
  # CLUSTERRESPONSE=$(curl -s 'https://${rancher_domain}/v3/cluster' -H 'content-type: application/json' -H "Authorization: Bearer $${APITOKEN}" --data-binary '{"type":"cluster","nodes":[],"rancherKubernetesEngineConfig":{"ignoreDockerVersion":true},"name":"test-cluster"}' --insecure)

  # Extract clusterid to use for generating the docker run command
  CLUSTERID="local"
  #$(echo $${CLUSTERRESPONSE} | jq -r .id)
  AGENTIMAGE=$(curl -s -H "Authorization: Bearer $${APITOKEN}" https://${rancher_domain}/v3/settings/agent-image --insecure | jq -r .value)
  ROLEFLAGS="--etcd --controlplane --worker"

  RANCHERSERVER="https://${rancher_domain}"
  AGENTTOKEN=$(curl -s "https://${rancher_domain}/v3/clusterregistrationtoken" -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --data-binary "{\"type\":\"clusterRegistrationToken\",\"clusterId\":\"$${CLUSTERID}\"}" --insecure | jq -r .token)

  CACHECKSUM=$(curl -s -H "Authorization: Bearer $${APITOKEN}" https://${rancher_domain}/v3/settings/cacerts --insecure | jq -r .value | sha256sum | awk '{ print $1 }')
  AGENTCOMMAND="docker run -d --restart=unless-stopped -v /var/run/docker.sock:/var/run/docker.sock -v /etc/kubernetes:/etc/kubernetes -v /root/kubeconfig:/root/.kube/config:z --net=host $${AGENTIMAGE} $${ROLEFLAGS} --server $${RANCHERSERVER} --token $${AGENTTOKEN}"
  mkdir -p /etc/kubernetes
  curl -s -u $${LOGINTOKEN} 'https://${rancher_domain}/v3/clusters/local?action=generateKubeconfig' -X POST -H 'content-type: application/json' --insecure | jq -r .config > /root/kubeconfig
  # sudo docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run rancher/rancher-agent:v2.5.0 --server https://${rancher_domain} --token $${APITOKEN} --ca-checksum $${CACHECKSUM} --address $${PRIVATE_IP} --internal-address $${PRIVATE_IP} $${K8S_ROLES}
  $${AGENTCOMMAND}
}

main
