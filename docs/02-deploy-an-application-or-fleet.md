## Deploy an application

The commands below should be run on a terminal on the local machine (where the
balena CLI is installed). Ensure that the `NODE_EXTRA_CA_CERTS` environment
variable is set, as discussed above.

### Login to openBalena

Run `balena login`, select `Credentials` and use the email and password
specified during quickstart to login to the openBalena server. At any time, the
`balena whoami` command may be used to check which server the CLI is logged in to.

### Create an application

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

### Provision a new device

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

### Deploy a project

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