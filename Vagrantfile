# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

# Enable Parallel in Vagrant
ENV['VAGRANT_NO_PARALLEL'] = 'yes'


Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  
  # Define Nodes Number
  Nodes = NODES_NUMBER
  
  (1..Nodes).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.box = "ubuntu/jammy64"
      node.vm.hostname = "node#{i}"
      node.vm.network "private_network", ip: "172.16.16.10#{i}"
      node.vm.synced_folder "./data#{i}", "/vagrant_data"
      node.vm.provider "virtualbox" do |v|
        v.name = "node#{i}"
        v.memory = 512
        v.cpus = 1
      end
    end
  end

  config.vm.provision "shell", inline: <<-SHELL
    echo "hi from" $HOSTNAME
  SHELL

end
