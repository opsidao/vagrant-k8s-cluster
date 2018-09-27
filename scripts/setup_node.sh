#!/bin/bash

set -e # Stop if anything fails

NODE_TYPE=$1

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

if [ $IS_MASTER_NODE = true ]
then
  echo "Initializing master node"
  kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address 192.168.2.100

  echo "Creating configuration for vagrant user"
  $AS_VAGRANT_USER 'mkdir -p /home/vagrant/.kube'
  rm -f /home/vagrant/.kube/config
  cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
  chown vagrant:vagrant /home/vagrant/.kube/config

  # echo "Giving the kubelet some time to start up"
  # sleep 10

  echo "Untainting master so it gets pods scheduled"
  $AS_VAGRANT_USER 'kubectl taint nodes --all node-role.kubernetes.io/master-'

  echo "Installing the calico pod network plugin"
  $AS_VAGRANT_USER 'kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml'
  $AS_VAGRANT_USER 'kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml'
else
  /usr/games/cowsay "Read this dude!"
  echo "There's one more thing left to do! You need to make your minion join the cluster."
  echo "Run this:"
  echo "   $ JOIN_COMMAND=\`vagrant ssh master -c 'kubeadm token create --print-join-command'\`"
  echo "   $ vagrant ssh minion -c \"sudo \$JOIN_COMMAND\""
  /usr/games/cowsay "Muuu"
fi

echo "Done"
