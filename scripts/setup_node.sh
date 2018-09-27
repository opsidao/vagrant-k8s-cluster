#!/bin/bash

set -e # Stop if anything fails

NODE_TYPE=$1

CALICO_NODE_CONFIG='
{
  "name": "kubernetes-network",
  "cniVersion": "0.1.0",
  "type": "calico",
  "kubernetes": {
      "kubeconfig": "/etc/kubernetes/admin.conf"
  },
  "ipam": {
      "type": "calico-ipam"
  }
}
'

AS_VAGRANT_USER="runuser -l vagrant -c "

if [ "$NODE_TYPE" = "master" ]
then
  IS_MASTER_NODE=true
else
  IS_MASTER_NODE=false
fi

echo "Disabling swap, kubelet won't work properly with it on"

swapoff -a

echo "Adding kubernetes apt repository"

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

echo "Installing dependencies"

apt-get update
apt-get install -y docker.io apt-transport-https curl kubelet kubeadm kubectl cowsay

apt-mark hold kubelet kubeadm kubectl

function install_calico_node {
  echo "Installing calico plugins"
  wget -N -P /opt/cni/bin https://github.com/projectcalico/cni-plugin/releases/download/v2.0.6/calico
  wget -N -P /opt/cni/bin https://github.com/projectcalico/cni-plugin/releases/download/v2.0.6/calico-ipam
  chmod +x /opt/cni/bin/calico /opt/cni/bin/calico-ipam

  echo "Downloading calicoctl"
  wget https://github.com/projectcalico/calicoctl/releases/download/v2.0.6/calicoctl
  chmod +x calicoctl

  echo "Starting calico/node"
  # This will succceed, but the command fails anyway... let's ignore it
  ETCD_ENDPOINTS=http://10.0.2.15:2379 ./calicoctl node run --node-image=quay.io/calico/node:v3.0.8 || true

  echo "Creating config file for calico/node"
  mkdir -p /etc/cni/net.d/

  echo $CALICO_NODE_CONFIG > /etc/cni/net.d/10-kubernetes.conf
}

if [ $IS_MASTER_NODE = true ]
then
  echo "Initializing master node"
  kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address 192.168.2.100

  echo "Creating configuration for vagrant user"
  $AS_VAGRANT_USER 'mkdir -p /home/vagrant/.kube'
  rm -f /home/vagrant/.kube/config
  cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
  chown vagrant:vagrant /home/vagrant/.kube/config

  echo "Untainting master so it gets pods scheduled"
  $AS_VAGRANT_USER 'kubectl taint nodes --all node-role.kubernetes.io/master-'

  echo "Installing the calico pod network plugin"
  $AS_VAGRANT_USER 'kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml'
  $AS_VAGRANT_USER 'kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml'

  install_calico_node
else
  install_calico_node

  /usr/games/cowsay "Read this dude!"
  echo "There's one more thing left to do! You need to make your minion join the cluster."
  echo "Run this:"
  echo "   $ JOIN_COMMAND=\`vagrant ssh master -c 'kubeadm token create --print-join-command'\`"
  echo "   $ vagrant ssh minion -c \"sudo \$JOIN_COMMAND\""
  /usr/games/cowsay "Muuu"
fi

echo "Done"
