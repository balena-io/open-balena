Vagrant.require_version '>= 2.2.0'

Vagrant.configure('2') do |config|
  config.vagrant.plugins = [
    'vagrant-vbguest',
    'vagrant-docker-compose'
  ]

  config.vm.define 'openbalena'
  config.vm.hostname = 'openbalena-vagrant'
  config.vm.box = 'bento/ubuntu-18.04'

  config.vm.network "public_network",
    use_dhcp_assigned_default_route: true

  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', '/home/vagrant/openbalena'

  config.ssh.forward_agent = true

  config.vm.provision :docker

  $provision = <<-SCRIPT
    DOCKER_COMPOSE_VERSION=1.24.0

    touch /home/vagrant/.bashrc
    grep -Fxq 'source /home/vagrant/openbalena/.openbalenarc' /home/vagrant/.bashrc || echo 'source /home/vagrant/openbalena/.openbalenarc' >> /home/vagrant/.bashrc

    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
    source "/home/vagrant/.nvm/nvm.sh" # This loads nvm
    nvm install 10.15.0 && nvm use 10.15.0

    # Install a newer version of docker-compose
    (cd /usr/local/bin; \
    sudo curl -o docker-compose --silent --location https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-Linux-x86_64; \
    sudo chmod a+x docker-compose)
  SCRIPT

  config.vm.provision :shell, privileged: false, inline: $provision

end
