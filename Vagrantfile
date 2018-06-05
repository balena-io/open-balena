Vagrant.require_version '>= 2.0.0'

[ 'vagrant-vbguest', 'vagrant-docker-compose' ].each do |p|
  unless Vagrant.has_plugin?(p)
    raise "Please install missing plugin: vagrant plugin install #{p}"
  end
end

Vagrant.configure('2') do |config|
  config.vm.define 'open-balena-vm'
  config.vm.box = 'bento/ubuntu-16.04'
  config.vm.box_url = 'https://vagrantcloud.com/bento/boxes/ubuntu-16.04/versions/201803.24.0/providers/virtualbox.box'

  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', '/home/vagrant/open-balena'
  config.vm.network 'public_network', bridge: ENV.fetch('OPENBALENA_BRIDGE', true)

  config.ssh.forward_agent = true

  config.vm.provision :docker
  config.vm.provision :docker_compose

  # FIXME: remove node
  config.vm.provision :shell, inline: 'apt-get install nodejs'

  # FIXME: remove `docker login`
  config.vm.provision :shell, inline: "docker login --username resindev --password #{ENV.fetch('DOCKERHUB_PASSWORD')}"
  config.vm.provision :shell, inline: '/home/vagrant/open-balena/scripts/start-project'
  config.vm.provision :shell, inline: '/home/vagrant/open-balena/scripts/run-fig-command up -d', run: 'always'
end
