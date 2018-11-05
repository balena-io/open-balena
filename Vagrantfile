Vagrant.require_version '>= 2.0.0'

[ 'vagrant-vbguest', 'vagrant-docker-compose' ].each do |p|
  unless Vagrant.has_plugin?(p)
    raise "Please install missing plugin: vagrant plugin install #{p}"
  end
end

Vagrant.configure('2') do |config|
  config.vm.define 'openbalenavm'
  config.vm.box = 'bento/ubuntu-16.04'
  config.vm.box_url = 'https://vagrantcloud.com/bento/boxes/ubuntu-16.04/versions/201808.24.0/providers/virtualbox.box'

  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', '/home/vagrant/open-balena'
  config.vm.network 'public_network', bridge: ENV.fetch('OPENBALENA_BRIDGE', '')

  config.ssh.forward_agent = true

  config.vm.provision :docker
  config.vm.provision :docker_compose

  # FIXME: remove node
  config.vm.provision :shell, inline: 'apt-get update && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*'

  config.vm.provision :shell, privileged: false,
    inline: "cd /home/vagrant/open-balena && ./scripts/quickstart -p -d #{ENV.fetch('OPENBALENA_DOMAIN', 'openbalena.local')}"

  config.vm.provision :shell, privileged: false,
    inline: "echo 'cd ~/open-balena' >> ~/.bashrc"
end
