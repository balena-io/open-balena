# Getting started with openbalena

This guide will walk you through the steps of deploying an openBalena server,
that together with the balena CLI, will enable you to create and manage a fleet
of devices running on your own infrastructure, on premises or in the cloud. The
openBalena servers must be reachable by the devices, which is easiest to achieve
with cloud providers like AWS, Google Cloud, Digital Ocean and others.

This guide assumes a setup with two separate machines:

- The openBalena _server_, running Linux. These instructions were tested with an
  Ubuntu 18.04 x64 server.
- The _local machine_, running Linux, Windows or macOS where the balena CLI runs
  (as a client to the openBalena server). The local machine should also have a
  working installation of [Docker](https://docs.docker.com/get-docker/) so that
  application images can be built and deployed to your devices, although it is
  also possible to use balenaEngine on a balenaOS device instead of Docker.

### Preparing a server for openBalena

Login to the server via SSH and run the following commands.

1. First, install or update essential software:

   ```bash
   apt-get update && apt-get install -y build-essential git docker.io libssl-dev nodejs npm
   ```

2. Install docker-compose:

   ```bash
   curl -L https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose
   chmod +x /usr/local/bin/docker-compose
   ```

   Test your docker-compose installation with `$ docker-compose --version`.

3. Create a new user, assign admin permissions and add to `docker` group:

   ```bash
   adduser balena
   usermod -aG sudo balena
   usermod -aG docker balena
   ```

#### Install openBalena on the server

1. On the server still, login as the new user and change into the home directory:

   ```bash
   su balena
   cd ~
   ```

2. Clone the openBalena repository and change into the new directory:

   ```bash
   git clone https://github.com/balena-io/open-balena.git
   cd open-balena/
   ```

3. Run the `quickstart` script as below. This will create a new `config`
   directory and generate appropriate SSL certificates and configuration for the
   server. The provided email and password will be used to automatically create
   the user account for interacting with the server and will be needed later on
   for logging in via the balena CLI. Replace the domain name for the `-d`
   argument appropriately.

   ```bash
   ./scripts/quickstart -U <email@address> -P <password> -d mydomain.com
   ```

   For more available options, see the script's help:

   ```bash
   ./scripts/quickstart -h
   ```

4. At this point, the openBalena server can be started with:

   ```bash
   systemctl start docker
   ./scripts/compose up -d
   ```

   The `-d` argument spawns the containers as background services.

5. Tail the logs of the containers with:

   ```bash
   ./scripts/compose exec <service-name> journalctl -fn100
   ```

   Replace `<service-name>` with the name of any one of the services defined
   in `compose/services.yml`; eg. `api` or `registry`.

6. The server can be stopped with:

   ```bash
   ./scripts/compose stop
   ```

When updating openBalena to a new version, the steps are:

```bash
./scripts/compose down
git pull
./scripts/compose build
./scripts/compose up -d
```

#### Domain Configuration

The following CNAME records must be configured to point to the openBalena server:

```text
api.mydomain.com
registry.mydomain.com
vpn.mydomain.com
s3.mydomain.com
tunnel.mydomain.com
```

Check with your internet domain name registrar for instructions on how to
configure CNAME records.

#### Test the openBalena server

To confirm that everything is running correctly, try a simple request from the
local machine to the server:

```bash
curl -k https://api.mydomain.com/ping
OK
```

Congratulations! The openBalena server is up and running. The next step is to
setup the local machine to use the server, provision a device and deploy a
small project.

### Install self-signed certificates on the local machine

The installation of the openBalena server produces a few self-signed certificates
that must be installed on the local machine, so that it can securely communicate
with the server.

The root certificate is found at `config/certs/root/ca.crt` on the server. Copy
it to some folder on the local machine and keep a note the path -- it will be
used later during the CLI installation. Follow the steps below for the specific
platform of the local machine.

#### Linux:

```bash
sudo cp ca.crt /usr/local/share/ca-certificates/ca.crt
sudo update-ca-certificates
sudo systemctl restart docker
```

#### macOS:

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ca.crt
osascript -e 'quit app "Docker"' && open -a Docker
```

#### Windows:

```bash
certutil -addstore -f "ROOT" ca.crt
```

The Docker daemon on the local machine must then be restarted for Docker to
pick up the new certificate.

### Install the balena CLI on the local machine

Follow the [balena CLI installation
instructions](https://github.com/balena-io/balena-cli/blob/master/INSTALL.md)
to install the balena CLI on the local machine.

By default, the CLI targets the balenaCloud servers at `balena-cloud.com`, and
needs to be configured to target the openBalena server instead. Add the following
line to the CLI's configuration file, replacing `"mydomain.com"` with the domain
name of the openBalena server:

```yaml
balenaUrl: 'mydomain.com'
```

The CLI configuration file can be found at:

- On Linux or macOS: `~/.balenarc.yml`
- On Windows: `%UserProfile%\_balenarc.yml`

If the file does not already exist, just create it.

Wrapping up the CLI installation, set an environment variable that points to the
root certificate copied previously on the local machine. This step is to ensure
the CLI can securely interact with the openBalena server.

| Shell              | Command                                        |
| ------------------ | ---------------------------------------------- |
| bash               | `export NODE_EXTRA_CA_CERTS='/path/to/ca.crt'` |
| Windows cmd.exe    | `set NODE_EXTRA_CA_CERTS=C:\path\to\ca.crt`    |
| Windows PowerShell | `$Env:NODE_EXTRA_CA_CERTS="C:\path\to\ca.crt"` |

### Deploy an application

The commands below should be run on a terminal on the local machine (where the
balena CLI is installed). Ensure that the `NODE_EXTRA_CA_CERTS` environment
variable is set, as discussed above.

#### Login to openBalena

Run `balena login`, select `Credentials` and use the email and password
specified during quickstart to login to the openBalena server. At any time, the
`balena whoami` command may be used to check which server the CLI is logged in to.