# Openbalena Getting Started Guide

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
it to some folder on the local machine and keep a note to the path -- it will be
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

#### Create an application

Create a new application with `balena app create myApp`. Select the application's
default device type with the interactive prompt. The examples in this guide assume
a Raspberry Pi 3.

An application contains devices that share the same architecture (such as ARM
or Intel i386), and also contains code releases that are deployed to the devices.
When a device is provisioned, it is added to an application, but can be migrated
to another application at any time. There is no limit to the number of applications
that can be created or to the number of devices that can be provisioned.

At any time, the server can be queried for all the applications it knows about
with the following command:

```bash
balena apps
ID APP NAME DEVICE TYPE  ONLINE DEVICES DEVICE COUNT
1  myApp    raspberrypi3
```

#### Provision a new device

Once we have an application, it’s time to start provisioning devices. To do this,
first download a balenaOS image from [balena.io](https://balena.io/os/#download).
Pick the development image that is appropriate for your device.

Unzip the downloaded image and use the balena CLI to configure it:

```bash
balena os configure ~/Downloads/balena-cloud-raspberrypi3-2.58.3+rev1-dev-v11.14.0.img --app myApp
```

Flash the configured image to an SD card using [Etcher](https://balena.io/etcher).
Insert the SD card into the device and power it on. The device will register with
the openBalena server and after about two minutes will be inspectable:

```bash
balena devices
ID UUID    DEVICE NAME  DEVICE TYPE  APPLICATION NAME STATUS IS ONLINE SUPERVISOR VERSION OS VERSION
4  59d7700 winter-tree  raspberrypi3 myApp            Idle   true      11.14.0            balenaOS 2.58.3+rev1

balena device 59d7700
== WINTER TREE
ID:                 4
DEVICE TYPE:        raspberrypi3
STATUS:             online
IS ONLINE:          true
IP ADDRESS:         192.168.43.247
APPLICATION NAME:   myApp
UUID:               59d7700755ec5de06783eda8034c9d3d
SUPERVISOR VERSION: 11.14.0
OS VERSION:         balenaOS 2.58.3+rev1
```

It's time to deploy code to the device.

#### Deploy a project

Application release images are built on the local machine using the balena CLI.
Ensure the root certificate has been correctly installed on the local machine,
as discussed above.

Let's create a trivial project that logs "Idling...". On an empty directory,
create a new file named `Dockerfile.template` with the following contents:

```dockerfile
FROM balenalib/%%BALENA_MACHINE_NAME%%-alpine

CMD [ "balena-idle" ]
```

Then build and deploy the project with:

```bash
balena deploy myApp --logs
```

The project will have been successfully built when a friendly unicorn appears in
the terminal:

```bash
[Info]    Compose file detected
...
[Info]    Creating release...
[Info]    Pushing images to registry...
[Info]    Saving release...
[Success] Deploy succeeded!
[Success] Release: f62a74c220b92949ec78761c74366046

			    \
			     \
			      \\
			       \\
			        >\/7
			    _.-(6'  \
			   (=___._/` \
			        )  \ |
			       /   / |
			      /    > /
			     j    < _\
			 _.-' :      ``.
			 \ r=._\        `.
			<`\\_  \         .`-.
			 \ r-7  `-. ._  ' .  `\
			  \`,      `-.`7  7)   )
			   \/         \|  \'  / `-._
			              ||    .'
			               \\  (
			                >\  >
			            ,.-' >.'
			           <.'_.''
			             <'
```

This command packages up the local directory, creates a new Docker image from
it and pushes it to the openBalena server. In turn, the server will deploy it to
all provisioned devices and within a couple of minutes, they will all run the
new release. Logs can be viewed with:

```bash
balena logs 59d7700 --tail
[Logs]    [10/28/2020, 11:40:16 AM] Supervisor starting
[Logs]    [10/28/2020, 11:40:50 AM] Creating network 'default'
[Logs]    [10/28/2020, 11:42:38 AM] Creating volume 'resin-data'
[Logs]    [10/28/2020, 11:42:40 AM] Downloading image …
…
[Logs]    [10/28/2020, 11:44:00 AM] [main] Idling...
```

Enjoy Balenafying All the Things!

## Next steps

- Try out [local mode](https://www.balena.io/docs/learn/develop/local-mode),
  which allows you to build and sync code to your device locally for rapid
  development.
- Develop an application with [multiple containers](https://www.balena.io/docs/learn/develop/multicontainer)
  to provide a more modular approach to application management.
- Manage your device fleet with the use of [configuration](https://www.balena.io/docs/learn/manage/configuration/)
  and [environment](https://www.balena.io/docs/learn/manage/serv-vars/) variables.
- Explore our [example projects](https://balena.io/blog/tags/etcher-featured/)
  to give you an idea of more things you can do with balena.
- If you find yourself stuck or confused, help is just [a click away](https://www.balena.io/support).
- Pin selected devices to selected code releases using
  [sample scripts](https://github.com/balena-io-examples/staged-releases).
- To change the superuser password after setting the credentials, follow this [forum post](https://forums.balena.io/t/upate-superuser-password/4738/6).
