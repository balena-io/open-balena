
## Host requirements

- Docker >= 18.05.0
- Docker Compose >= 1.11
- OpenSSL >= 1.0.0
- Python >= 2.7 or >=3.4

## Installation

### Debian/Ubuntu

Make sure you have the software listed above installed.

In a terminal, change into the `open-balena` directory and create a new
deployment:

    $ ./scripts/start-project

This will create a new directory, `demo`, and generate appropriate SSL
certificates and configuration for the platform. You can configure the
deployment name by passing it as the first argument to the `start-project`
command. If you wish to run the platform under a specific domain name,
you can specify it as the second argument. The default is `openbalena.local`.
For example:

    $ ./scripts/start-project -n mydeployment -d mydomain.com

You can create as many deployments as needed and switch between them using:

    $ ./scripts/select-project -n mydeployment

Remove all traces of a project by deleting its folder.

Start the platform with:

    $ ./scripts/compose up

Stop the platform with:

    $ ./scripts/compose stop

### macOS & Windows

On macOS and Windows you need Vagrant. `open-balena` is not being tested with
docker-machine. `open-balena` comes with an appropriate `Vagrantfile` for
setting up the VM, installing dependencies and starting the platform.

- Install Vagrant >= 2.0
- `$ vagrant plugin install vagrant-docker-compose`
- `$ vagrant up`

When provisioning completes and the VM has started, `open-balena` services
should be running inside the VM. You will need to expose these services to
the outside in order for them to be reachable by devices. To do so, you must
setup DNS for the domain name you've deployed the instance as to point to the
VM's IP address.
