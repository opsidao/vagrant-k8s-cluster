# Requirements

You need the following dependencies available in your host machine, just the latest versions for now:

- [Ansible](https://www.ansible.com/)
- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/)

# Basic architecture

This will run two virtualbox machines:

- master: available only from the host machine in the ip 192.168.2.100
- minion: available only from the host machine in the ip 192.168.2.101

They will both be configured to have a common pod network using [Project calico](https://www.projectcalico.org/).

# Provisioning the cluster

With the dependencies installed, just run `vagrant up` from this folder and wait for your two virtual machines to be provisiones.

Don't worry if you see some step fail, that's expected, as long as the whole process doesn't fail, you should be fine.

At the end of the provisioning of your minion virtual machine, you will see a message prompting you to run the following command:

```shell
vagrant ssh minion -c "sudo `vagrant ssh master -c 'sudo kubeadm token create --print-join-command'`"
```

As soon as you execute that command, after the provisioning has been succesfull, you can do the following to check that all is working properly:

```shell
host> $ vagrant ssh master
master> $ kubectl get nodes --watch
```

You should already see your two nodes listed, but it can take a little bit for the minion to become ready... just give it a minute (in my case is around 40 seconds)
