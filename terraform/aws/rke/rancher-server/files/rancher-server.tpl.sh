#!/bin/bash
# Script for the provision rancher machine

main() {
hostname_gen
deploy_ssh_keys
data_volume_process
software_install
}

hostname_gen() {
  echo "Hostname generation"
  hostname "rancher-server" && hostname > /etc/hostname
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
  atp-get install -y jq

}

main
