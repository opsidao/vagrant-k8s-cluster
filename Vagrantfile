# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/xenial64'

  config.vm.provision('ansible') do |ansible|
    ansible.playbook = 'node.yml'
  end

  config.vm.provider 'virtualbox' do |v|
    v.customize ['modifyvm', :id, '--memory', 2048]
    v.customize ['modifyvm', :id, '--cpus', 2]
  end

  config.vm.define 'master' do |master|
    master.vm.hostname = 'master'
    master.vm.network 'private_network', ip: '192.168.2.100'
    master.vm.synced_folder 'synced/', '/home/vagrant/synced'
  end

  config.vm.define 'minion' do |minion|
    minion.vm.hostname = 'minion'
    minion.vm.network 'private_network', ip: '192.168.2.101'
  end
end
