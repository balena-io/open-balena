# openBalena Getting Started Guide

This guide will walk you through the steps of deploying an openBalena server, that
together with the balena CLI, will enable you to create and manage a fleet of devices
running on your own infrastructure, on premises or in the cloud. The openBalena servers
must be reachable by the devices, which is easiest to achieve with cloud providers like
AWS, Google Cloud, Digital Ocean and others.

This guide assumes a setup with two separate machines:

- A _server_, running Linux with at least 2GB of memory. These instructions were tested
  with Ubuntu 20.04, 22.04 and 24.04 x64 servers. The server must have a working
  installation of [Docker Engine] and you must have root permissions.
- A _local machine_, running Linux, Windows or macOS where the balena CLI runs (as a
  client to the openBalena server). The local machine must also have a working
  installation of [Docker] so that application images can be built and deployed to your
  device. It is also possible to use [balenaEngine] on a [balenaOS] device instead of
  Docker.

Additionally, a _device type_ and compatible flash media supported by [balenaOS]
(e.g. Raspberry Pi) are required to complete the provisioning demo. Ensure the correct
power supply is available to power this device.

## Domain Configuration

The following DNS records must be configured to point to the openBalena server prior to
configuration:

```text
api.mydomain.com
ca.mydomain.com
cloudlink.mydomain.com
logs.mydomain.com
ocsp.mydomain.com
registry2.mydomain.com
s3.mydomain.com
tunnel.mydomain.com
```

Alternatively you may consider adding a single wildcard DNS record `*.mydomain.com`.

Check with your Internet domain name registrar for instructions on how to obtain a domain
name and configure records.

## Install openBalena on the server

1. Install or update essential software:

    ```bash
    sudo apt-get update && sudo apt-get install -y make openssl git jq
    ```

2. Install Docker Engine

    ```bash
    which docker || curl -fsSL https://get.docker.com | sh -
    ```

3. Create a new user with appropriate permissions:

    ```bash
    sudo useradd -s /bin/bash -m -G docker,sudo balena
    echo 'balena ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/balena
    ```

4. Switch user:

   ```bash
   sudo su balena
   ```

5. Clone the openBalena repository and change directory:

   ```bash
   git clone https://github.com/balena-io/open-balena.git ~/open-balena
   cd ~/open-balena
   ```

6. Start the server on your domain name:

   ```bash
   export DNS_TLD=mydomain.com
   make up
   ```

   Note down `SUPERUSER_EMAIL` and `SUPERUSER_PASSWORD` values to be used later.

7. Tail the logs of the containers with:

   ```bash
   docker compose logs -f api
   ```

   Replace `api` with the name of any one of the services from the [composition].

8. The server can be stopped with:

   ```bash
   make down
   ```

   The server can also be restarted using `make restart`.

To update openBalena, run:

```bash
make update
```

### Test the openBalena server

To confirm that everything is running correctly, try a simple request from the local
machine to the server after registering its CA certificate(s) with the host:

```bash
make self-signed
make verify
```

Note, if you've previously stopped the server with `make down`, run `make up` again first.

Congratulations! The openBalena server is up and running. The next step is to setup your
local machine to use this server, provision a device and deploy a small project.

### Install self-signed certificates on the local machine.

The installation of the openBalena server produces a self-signed certificate by default,
which must be trusted by all devices communicating with it. This type of configuration is
not recommended for production deployments, skip to [SSL Configuration](#ssl-configuration)
instead.

The root CA bundle can be found at `.balena/ca-${DNS_TLD}.pem` on the server. Follow the
steps below for your specific local machine platform after manually copying it across.

#### Linux:

```bash
sudo cp ca.pem /usr/local/share/ca-certificates/
sudo update-ca-certificates
sudo systemctl restart docker
```

#### macOS:

```bash
sudo security add-trusted-cert -d \
  -r trustRoot \
  -k /Library/Keychains/System.keychain \
  ca.pem

curl http://localhost/engine/restart \
  -H 'Content-Type: application/json' \
  -d '{"openContainerView": true}' \
  --unix-socket ~/Library/Containers/com.docker.docker/Data/backend.sock
```

#### Windows:

```PowerShell
certutil -addstore -f "ROOT" ca.pem
Stop-Service -Name Docker
Start-Service -Name Docker
```

### SSL Configuration

opeBalena server now uses automatic SSL configuration via ACME [DNS-01] challenge[^1]. Support
for the following DNS providers is currently implemented:

* Cloudflare
* Gandi

#### Cloudflare

Obtain a Cloudflare API token with write access to your openBalena domain name records:

```bash
export ACME_EMAIL=acme@mydomain.com
export CLOUDFLARE_API_TOKEN={{token}}
```

#### Gandi

Obtain a Gandi API token with write access to your openBalena domain name records:

```bash
export ACME_EMAIL=acme@mydomain.com
export GANDI_API_TOKEN={{token}}
```

#### Re-configure and test the server

```bash
make auto-pki
make verify
```

#### Custom SSL

openBalena server also supports custom/manual TLS configuration. You must supply your own
SSL certificate, private key and a full certificate signing chain. A wildcard SSL
certificate covering the whole domain is recommended.

1. After obtaining your certificate, run the following commands on openBalena server:

```bash
export HAPROXY_CRT="{{ base64 encoded server certificate }}"
export ROOT_CA="{{ .. intermediate certificates }}"
export HAPROXY_KEY="{{ .. private key }}"
```

Pipe the plaintext via `.. | openssl base64 -A` to encode.

2. Re-configure and test the server:

```bash
make pki-custom
make verify
```

### Install the balena CLI on the local machine

Follow the [balena CLI installation instructions] to install the balena CLI on the local
machine.

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

If the file does not already exist, just create it. Alternatively, `BALENARC_BALENA_URL`
environment variable can be set to point to `"mydomain.com"`.

Wrapping up the CLI installation, set an environment variable that points to the
root certificate copied previously on the local machine. This step is to ensure
the CLI can securely interact with the openBalena server when running self-signed PKI.
This step can be skipped if the server is operating with publicly trusted PKI.

| Shell              | Command                                        |
| ------------------ | ---------------------------------------------- |
| bash               | `export NODE_EXTRA_CA_CERTS='/path/to/ca.pem'` |
| Windows cmd.exe    | `set NODE_EXTRA_CA_CERTS=C:\path\to\ca.pem`    |
| Windows PowerShell | `$Env:NODE_EXTRA_CA_CERTS="C:\path\to\ca.pem"` |

### Deploy an application

The commands below should be run on a terminal on the local machine (where the
balena CLI is installed). Ensure that the `NODE_EXTRA_CA_CERTS` environment
variable is set, as discussed above.

#### Login to openBalena

Run `balena login`, select `Credentials` and use `SUPERUSER_EMAIL` and
`SUPERUSER_PASSWORD` generated during `make up` step to login to the openBalena server.
At any time, `balena whoami` command may be used to check which server the CLI is
authenticated with.

#### Create an application

Create a new application with `balena fleet create myApp`. Select the application's
default device type with the interactive prompt. The examples in this guide assume
a Raspberry Pi 3.

An application contains devices that share the same architecture (such as ARM or Intel),
and also contains code releases that are deployed to the devices. When a device is
provisioned, it is added to an application, but can be migrated to another application at
any time. There is no limit to the number of applications that can be created or to the
number of devices that can be provisioned.

At any time, the server can be queried for all the applications it knows about
with the following command:

```bash
balena fleets
 Id App name Slug        Device type  Device count Online devices
 ── ──────── ─────────── ──────────── ──────────── ──────────────
 1  myApp    admin/myapp raspberrypi3 0            0
```

#### Provision a new device

Once we have an application, it’s time to start provisioning devices. To do this,
first download a [balenaOS] image for your device. For this example we are using a
Raspberry Pi 3.

Unzip the downloaded image and use the balena CLI to configure it:

```bash
balena os configure --dev --fleet myApp ~/Downloads/raspberrypi3-5.2.8-v16.1.10.img
```

Flash the configured image to an SD card using [Etcher] or balena CLI:

```bash
sudo balena local flash ~/Downloads/raspberrypi3-5.2.8-v16.1.10.img
```

Insert the SD card into the device and power it on. The device will register with the
openBalena server and after about two minutes will be inspectable:

```bash
balena devices
ID UUID    DEVICE NAME DEVICE TYPE  FLEET       STATUS IS ONLINE SUPERVISOR VERSION OS VERSION
1  560dcc2 quiet-rock  raspberrypi3 admin/myapp Idle   true      16.1.10            balenaOS 5.2.8

balena device 560dcc2
== WANDERING RAIN
ID:                    1
DEVICE TYPE:           raspberrypi3
STATUS:                idle
IS ONLINE:             true
IP ADDRESS:            192.168.1.42
MAC ADDRESS:           B8:27:DE:AD:BE:EF
FLEET:                 admin/myapp
LAST SEEN:             1977-08-20T14:29:00.042Z
UUID:                  560dcc24b221c8a264d5bd981284801f
COMMIT:                N/a
SUPERVISOR VERSION:    16.1.10
IS WEB ACCESSIBLE:     false
OS VERSION:            balenaOS 5.2.8
DASHBOARD URL:         https://dashboard.mydomain.com/devices/560dcc24b221c8a264d5bd981284801f/summary
CPU USAGE PERCENT:     2
CPU TEMP C:            39
CPU ID:                00000000335956af
MEMORY USAGE MB:       140
MEMORY TOTAL MB:       971
MEMORY USAGE PERCENT:  14
STORAGE BLOCK DEVICE:  /dev/mmcblk0p6
STORAGE USAGE MB:      76
STORAGE TOTAL MB:      14121
STORAGE USAGE PERCENT: 1
```

Note, even though the dashboard URL is populated, there is no dashboard service in
openBalena.

It's time to deploy code to the device.

#### Deploy a project

Application release images are built on the local machine using the balena CLI. Ensure the
root certificate has been correctly installed on the local machine, as discussed above.

Let's create a trivial project that logs "Idling...". On an empty directory, create a new
file named `Dockerfile.template` with the following contents:

```dockerfile
FROM balenalib/%%BALENA_MACHINE_NAME%%-alpine

CMD [ "balena-idle" ]
```

Then build and deploy the project with:

```bash
balena deploy --noparent-check myApp
```

The project will have been successfully built when a friendly unicorn appears in the
terminal:

```bash
[Info]    No "docker-compose.yml" file found at "~/open-balena/balena-idle"
[Info]    Creating default composition with source: "~/open-balena/balena-idle"
[Info]    Everything is up to date (use --build to force a rebuild)
[Info]    Creating release...
[Info]    Pushing images to registry...
[Info]    Saving release...
[Success] Deploy succeeded!
[Success] Release: 50be7bdb0ea6819c91a5dd7bcd7635ad

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

This command packages up the local directory, creates a new Docker image from it and
pushes it to the openBalena server. In turn, the server will deploy it to all provisioned
devices and within a couple of minutes, they will all run the new release. Logs can be
viewed with:

```bash
balena logs --tail 560dcc2
[Logs]    [2024-05-02T15:59:31.383Z] Supervisor starting
[Logs]    [2024-05-02T15:59:37.552Z] Applying configuration change {"SUPERVISOR_VPN_CONTROL":"true"}
[Logs]    [2024-05-02T15:59:37.599Z] Applied configuration change {"SUPERVISOR_VPN_CONTROL":"true"}
[Logs]    [2024-05-02T15:59:40.331Z] Creating network 'default'
[Logs]    [2024-05-02T16:11:15.331Z] Supervisor starting
[Logs]    [2024-05-02T16:44:08.199Z] Creating volume 'resin-data'
[Logs]    [2024-05-02T16:44:08.572Z] Downloading image 'registry2.mydomain.com/v2/…
…
[Logs]    [2024-05-02T16:44:37.200Z] [main] Idling...
[Logs]    [2024-05-02T16:44:37.200Z] [main] Idling...
```

Enjoy Balenafying All the Things!

## Next steps

- Try out [local mode], which allows you to build and sync code to your device locally for
  rapid development.
- Develop an application with [multiple containers] to provide a more modular approach to
  application management.
- Manage your device fleet with the use of [configuration] and [environment] variables.
- Explore our [example projects] to give you an idea of more things you can do with
  balena.
- If you find yourself stuck or confused, help is just [a click away].
- Pin selected devices to selected code releases using [sample scripts].
- To change the superuser password after setting the credentials, follow this [forum post]


[^1]: If DNS validation is not an option, [acme.sh] or [certbot] can be used to manually
issue a certificate, which can then be set using the [custom SSL](#custom-ssl) workflow.


[local mode]: https://www.balena.io/docs/learn/develop/local-mode
[multiple containers]: https://www.balena.io/docs/learn/develop/multicontainer
[configuration]: https://www.balena.io/docs/learn/manage/configuration
[environment]: https://www.balena.io/docs/learn/manage/serv-vars
[example projects]: https://balena.io/blog/tags/etcher-featured
[a click away]: https://www.balena.io/support
[sample scripts]: https://github.com/balena-io-examples/staged-releases
[forum post]: https://forums.balena.io/t/upate-superuser-password/4738/6
[balena CLI installation instructions]: https://github.com/balena-io/balena-cli/blob/master/INSTALL.md
[Etcher]: https://balena.io/etcher
[balenaOS]: https://balena.io/os/#download
[balenaEngine]: https://www.balena.io/engine
[Docker]: https://docs.docker.com/get-docker
[Docker Engine]: https://docs.docker.com/engine/install
[Change cgroup version]: https://docs.docker.com/config/containers/runmetrics/#changing-cgroup-version
[composition]: https://github.com/balena-io/open-balena/blob/master/docker-compose.yml
[DNS-01]: https://letsencrypt.org/docs/challenge-types/#dns-01-challenge
[acme.sh]: https://github.com/acmesh-official/acme.sh
[certbot]: https://certbot.eff.org/
