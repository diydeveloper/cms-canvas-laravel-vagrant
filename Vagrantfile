# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box = "ubuntu/trusty64"

    config.vm.provider "virtualbox" do |v|
  		v.memory = 2048
  		v.cpus = 2
	end

    # Forward ports to Apache and MySQL
    config.vm.network "forwarded_port", guest: 80, host: 8080
    config.vm.network "forwarded_port", guest: 3306, host: 3306

    # config.vm.synced_folder "www/", "/var/www"
	
    config.vm.provision "shell", path: "Vagrant.bootstrap.sh"
end
