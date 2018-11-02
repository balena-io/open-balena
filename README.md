
## Host requirements

- Docker >= 18.05.0
- Docker Compose >= 1.11
- OpenSSL >= 1.0.0
- Python >= 2.7 or >=3.4
- NodeJS >= 4.0

## Installation

Make sure you have the software listed above installed.

In a terminal, clone the project with:

    $ git clone https://github.com/balena-io/open-balena.git

Change into the `open-balena` directory and run the configuration script.
This will create a new directory, `config`, and generate appropriate SSL
certificates and configuration for the instance.

    $ ./scripts/quickstart

You may optionally configure the instance to run under a custom domain name.
The default is `openbalena.local`. For example:

    $ ./scripts/quickstart -d mydomain.com

For more available options, see the script's help:

    $ ./scripts/quickstart -h

Start the instance with:

    $ ./scripts/compose up -d

Stop the instance with:

    $ ./scripts/compose stop

To remove all traces of the instance, run the following commands and finally
delete the configuration folder.

**WARNING**: This will remove *all* data.

    $ ./scripts/compose kill
    $ ./scripts/compose down
    $ docker volume rm openbalena_s3 openbalena_redis openbalena_db openbalena_registry

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
