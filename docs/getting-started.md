# Openbalena Getting Started Guide

This guide will walk you through the steps of deploying an openBalena server,
that together with the balena CLI, will enable you to create and manage a fleet
of devices running on your own infrastructure, on premises or in the cloud. The
openBalena servers must be reachable by the devices, which is easiest to achieve
with cloud providers like AWS, Google Cloud, Digital Ocean and others.

This guide assumes a setup with two separate machines:

- The openBalena _server_, running Linux. These instructions were tested with an
  Ubuntu 22.04 x64 server.
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

4. Enable cgroup v1. The balena containers want to start systemd inside the container but this is not possible with just cgroups2.

   ```bash
   echo 'GRUB_CMDLINE_LINUX=systemd.unified_cgroup_hierarchy=false' | tee /etc/default/grub.d/cgroup.cfg
   update-grub
   reboot
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

### Deploy a fleet

The commands below should be run on a terminal on the local machine (where the
balena CLI is installed). Ensure that the `NODE_EXTRA_CA_CERTS` environment
variable is set, as discussed above.

#### Login to openBalena

Run `balena login`, select `Credentials` and use the email and password
specified during quickstart to login to the openBalena server. At any time, the
`balena whoami` command may be used to check which server the CLI is logged in to.

#### Create a fleet

Create a new fleet with `balena fleet create myApp`. Select the fleet's
default device type with the interactive prompt. The examples in this guide assume
a Raspberry Pi 3.

A fleet contains devices that share the same architecture (such as ARM
or Intel i386), and also contains code releases that are deployed to the devices.
When a device is provisioned, it is added to a fleet, but can be migrated
to another fleets at any time. There is no limit to the number of fleets
that can be created or to the number of devices that can be provisioned.

At any time, the server can be queried for all the fleets it knows about
with the following command:

```bash
balena fleets
 Id App name Slug        Device type  Device count Online devices 
 ── ──────── ─────────── ──────────── ──────────── ────────────── 
 1  myApp    admin/myapp raspberrypi3 0            0              
```

#### Provision a new device

Once we have a fleet, it’s time to start provisioning devices. To do this,
first download a balenaOS image from [balena.io](https://balena.io/os/#download).
Pick the development image that is appropriate for your device.

Unzip the downloaded image and use the balena CLI to configure it:

```bash
balena os configure ~/Downloads/raspberrypi3-4.1.1-v14.13.13.img --fleet myApp
```

Flash the configured image to an SD card using [Etcher](https://balena.io/etcher).
Insert the SD card into the device and power it on. The device will register with
the openBalena server and after about two minutes will be inspectable:

```bash
balena devices
ID UUID    DEVICE NAME DEVICE TYPE  FLEET       STATUS IS ONLINE SUPERVISOR VERSION OS VERSION     DASHBOARD URL
1  81c1fb6 sleek-dream raspberrypi3 admin/myapp Idle   true      14.13.13           balenaOS 4.1.1 https://dashboard.openbalena.flux-dev.cloud/devices/81c1fb61b7882b5cc59b33bc22d18023/summary

balena device 81c1fb6
== SLEEK DREAM
ID:                    1
DEVICE TYPE:           raspberrypi3
STATUS:                idle
IS ONLINE:             true
IP ADDRESS:            192.168.178.58 2a02:a463:2679:1:2153:866c:4b2e:3aac
MAC ADDRESS:           B8:27:EB:0A:15:34 B8:27:EB:5F:40:61
FLEET:                 admin/myapp
LAST SEEN:             2023-10-31T09:49:45.965Z
UUID:                  81c1fb61b7882b5cc59b33bc22d18023
COMMIT:                N/a
SUPERVISOR VERSION:    14.13.13
IS WEB ACCESSIBLE:     false
OS VERSION:            balenaOS 4.1.1
DASHBOARD URL:         https://dashboard.openbalena.flux-dev.cloud/devices/81c1fb61b7882b5cc59b33bc22d18023/summary
CPU USAGE PERCENT:     48
CPU TEMP C:            59
CPU ID:                000000008c0a1534
MEMORY USAGE MB:       144
MEMORY TOTAL MB:       971
MEMORY USAGE PERCENT:  15
STORAGE BLOCK DEVICE:  /dev/mmcblk0p6
STORAGE USAGE MB:      75
STORAGE TOTAL MB:      13741
STORAGE USAGE PERCENT: 1
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
balena deploy myApp
```

The project will have been successfully built when a friendly unicorn appears in
the terminal:

```bash
[Info]    No "docker-compose.yml" file found at ...
...
[Info]    Creating release...
[Info]    Pushing images to registry...
[Info]    Saving release...
[Success] Deploy succeeded!
[Success] Release: 821e084db0730de5a0e4005ed4c4a331

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
balena logs 81c1fb6 --tail
[Logs]    [2023-10-31T09:49:38.094Z] Supervisor starting
[Logs]    [2023-10-31T09:49:46.469Z] Creating network 'default'
[Logs]    [2023-10-31T09:54:42.238Z] Creating volume 'resin-data'
[Logs]    [2023-10-31T09:54:42.448Z] Downloading image ...
...
[Logs]    [2023-10-31T09:56:02.381Z] [main] Idling...
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
