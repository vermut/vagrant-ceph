# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  # config.vm.box = "jdiprizio/centos-docker-io"

  config.vm.provider "virtualbox" do |v|
	  v.memory = 4096
	  v.cpus = 1
  end

  config.vm.provision "shell", path: "ceph-deployer.sh"
end
