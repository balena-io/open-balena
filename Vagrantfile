Vagrant.require_version '>= 2.0.0'

[ 'vagrant-vbguest', 'vagrant-docker-compose' ].each do |p|
  unless Vagrant.has_plugin?(p)
    raise "Please install missing plugin: vagrant plugin install #{p}"
  end
end

Vagrant.configure('2') do |config|
  config.vm.define 'openbalena'
  config.vm.hostname = 'openbalena-vagrant'
  config.vm.box = 'bento/ubuntu-18.04'

  config.vm.network "public_network",
    use_dhcp_assigned_default_route: true

  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', '/home/vagrant/openbalena'

  config.ssh.forward_agent = true

  config.vm.provision :docker
  config.vm.provision :docker_compose

  $provision = <<-SCRIPT
    touch /home/vagrant/.bashrc
    grep -Fxq 'source /home/vagrant/openbalena/.openbalenarc' /home/vagrant/.bashrc || echo 'source /home/vagrant/openbalena/.openbalenarc' >> /home/vagrant/.bashrc

    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
    source "/home/vagrant/.nvm/nvm.sh" # This loads nvm
    nvm install 10.15.0 && nvm use 10.15.0
  SCRIPT

  config.vm.provision :shell, privileged: false, inline: $provision

end
