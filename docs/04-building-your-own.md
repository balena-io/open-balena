# Building your own image

## How to start
In order to build your very own version of balenaOS for one of our supported boards, you will first need to make sure you have a working [Yocto environment setup](http://www.yoctoproject.org/docs/current/yocto-project-qs/yocto-project-qs.html).
Then pick the device type you want to build, in this example we will use the Raspberry Pi 3. So first we need to grab the [`balena-raspberrypi`](https://github.com/balena-os/balena-raspberrypi) and initialise all its submodules.
``` bash
git clone https://github.com/balena-os/balena-raspberrypi
cd balena-raspberrypi/
git submodule update --init --recursive
```
We can then use the helpful `BARYS` tool to setup up and start our build. To see all the functionality `BARYS` provides run `./balena-yocto-scripts/build/barys -h`
from with in the repo.

Now to actually build a development version of balenaOS for the Raspberry Pi 3, we can run the following:
``` bash
./balena-yocto-scripts/build/barys -m raspberrypi3
```

Now sit tight and maybe go and make several cups of tea, this is going to take a little while.

By default, the images are created in the `build/tmp/deploy/<yocto-machine-name>` directory with the file extension `.resinos-img` or `.balenaos-img`. Rename the file extension to `.img` to flash the image to a SD card or USB drive using [balenaEtcher](https://www.balena.io/etcher/).

## Supporting your Own Board

Pre-requisites: a [Yocto](https://www.yoctoproject.org) Board Support Package (BSP) layer for your particular board. It should be compatible to the Yocto releases balenaOS supports.

Repositories used to build balenaOS host Operating System (OS) are typically named `balena-<board-family>`. For example, consider [balena-raspberrypi](https://github.com/balena-os/balena-raspberrypi) which is used for building the OS for [Raspberryi Pi](https://raspberrypi.org), or [balena-intel](https://github.com/balena-os/balena-intel) repository which can be used to build a balena image for the Intel NUC boards.

Contributing support for a new board consist of creating a a Yocto package that includes:

* general hardware support for the specific board,
* the balenaOS-specific software features,
* deployment-specific features (i.e. settings to create SD card images or self-flashing images)

The following documentation walks you through the steps of creating such a Yocto package. Because of the substantial difference between the hardware of many boards, this document provides general directions, and often it might be helpful to see the examples of already supported boards. The list of the relevant repositories is found the end of this document.

### Board Support Repository Breakout

The `balena-<board-family>` repositories use [git submodules](https://git-scm.com/docs/git-submodule) for including required Yocto layers from the relevant sub-projects.

The root directory shall contain 2 directory entries:

* a `layers` directory
* [balena-yocto-scripts](https://github.com/balena-os/balena-yocto-scripts) git submodule.

_Note: you add submodules by `git submodule add <url> <directory>`, see the git documentation for more details._

The root directory generally also includes the following files:

* `CHANGELOG.md`
* `LICENSE`
* `README.md`
* `VERSION`

and one or more files named `<yocto-machine-name>.coffee`, one for each of the boards that the repository will add support for (eg. [`raspberry-pi3.coffee`](https://github.com/balena-os/balena-raspberrypi/blob/master/raspberrypi3.coffee) for Raspberry Pi 3 in `balena-raspberrypi`). This file contains information on the Yocto build for the specific board, in [CoffeeScript](http://coffeescript.org/) format. A minimal version of this file, using Raspberry Pi 3 as the example, would be:

``` coffeescript
module.exports =
  yocto:
    machine: 'raspberrypi3'
    image: 'balena-image'
    fstype: 'balenaos-img'
    version: 'yocto-jethro'
    deployArtifact: 'balena-image-raspberrypi3.balenaos-img'
    compressed: true
```

The `layers` directory contains the git submodules of the yocto layers used in the build process. This normally means the following components are present:

- [poky](https://www.yoctoproject.org/tools-resources/projects/poky)  at the version/revision required by the board BSP
- [meta-openembedded](https://github.com/openembedded/meta-openembedded) at the revision poky uses
- [meta-balena](https://github.com/balena-os/meta-balena) using the master branch
- [oe-meta-go](https://github.com/balena-os/oe-meta-go) using the master branch (there were no branches corresponding to the yocto releases at the time this howto was written)
- Yocto BSP layer for the board (for example, the BSP layer for Raspberry Pi is [meta-raspberrypi](https://github.com/agherzan/meta-raspberrypi))
- any additional Yocto layers required by the board BSP (check the Yocto BSP layer of the respective board for instructions on how to build the BSP and what are the Yocto dependencies of that particular BSP layer)

In addition to the above git submodules, the "layers" directory also contains a `meta-balena-<board-family>` directory (please note this directory is _not_ a git submodule, but an actual directory in the repository). This directory contains the required customization for making a board balena enabled. For example, the [balena-raspberrypi](https://github.com/balena-os/balena-raspberrypi) repository contains the directory `layers/meta-balena-raspberrypi` to supplement the BSP from `layers/meta-raspberrypi` git submodule, with any changes that might be required by balenaOS.

The layout so far looks as follows:

```
├── CHANGELOG.md
├── LICENSE
├── README.md
├── VERSION
├── layers
│   ├── meta-openembedded
│   ├── meta-<board-family>
│   ├── meta-balena
│   ├── meta-balena-<board-family>
│   ├── oe-meta-go
│   └── poky
├── <board>.coffee
└── balena-yocto-scripts
```

### meta-balena-`<board-family>` breakout

This directory contains:

* `COPYING.Apache-2.0` file with the [Apache Version 2.0 license](http://www.apache.org/licenses/LICENSE-2.0),
* `README.md` file specifying the supported boards

and a number of directories out of which the mandatory ones are:

- `conf` directory - contains the following files:
    - `layer.conf`, see the [layer.conf](https://github.com/balena-os/balena-raspberrypi/blob/master/layers/meta-balena-raspberrypi/conf/layer.conf) from `meta-balena-raspberrypi` for an example, and see [Yocto documentation](http://www.yoctoproject.org/docs/2.0/mega-manual/mega-manual.html#bsp-filelayout-layer)
    - `samples/bblayers.conf.sample` file in which all the required Yocto layers are listed, see this [bblayers.conf.sample](https://github.com/balena-os/balena-raspberrypi/blob/master/layers/meta-balena-raspberrypi/conf/samples/bblayers.conf.sample) from `meta-balena-raspberrypi` for an example, and see the [Yocto documentation](http://www.yoctoproject.org/docs/2.0/mega-manual/mega-manual.html#var-BBLAYERS)
    - `samples/local.conf.sample` file which defines part of the build configuration (see the meta-balena [README.md](https://github.com/balena-os/meta-balena/blob/master/README.md) for an overview of some of the variables use in the `local.conf.sample` file). An existing file can be used (e.g. [local.conf.sample](https://github.com/balena-os/balena-raspberrypi/blob/master/layers/meta-balena-raspberrypi/conf/samples/local.conf.sample)) but making sure the "Supported machines" area lists the appropriate machines this repository is used for. See also the [Yocto documentation](http://www.yoctoproject.org/docs/2.0/mega-manual/mega-manual.html#structure-build-conf-local.conf).

- `recipes-containers/docker-disk` directory, which contains `docker-balena-supervisor-disk.bbappend` that shall define the following variable(s):

    - `SUPERVISOR_REPOSITORY_<yocto-machine-name>`: this variable is used to specify the build of the supervisor. It can be one of (must match the architecture of the board):
        *  **balena/armv7hf-supervisor** (for armv7 boards),
        * **balena/i386-supervisor**
        (for x86 boards),
        * **balena/amd64-supervisor** (for x86-64 boards),
        * **balena/rpi-supervisor** (for raspberry pi 1),
        * **balena/armel-supervisor** (for armv5 boards).

    - `LED_FILE_<yocto-machine-name>`: this variable should point to the [Linux sysfs path of an unused LED](https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-class-led) if available for that particular board. This allows the unused LED to be flashed for quick visual device identification purposes. If no such unused LED exists, this variable shall not be used.

- `recipes-core/images` directory, which contains at least a `balena-image.bbappend` file. Depending on the type of board you are adding support for, you should have your device support either just `balena-image` or both `balena-image-flasher` and `balena-image`. Generally, `balena-image` is for boards that boot directly
from external storage (these boards do not have internal storage to install balena on). `balena-image-flasher` is used when the targeted board has internal storage so this flasher image is burned onto an SD card or USB stick that is used for the initial boot. When booted, this flasher image will automatically install balena on internal storage.

  The `balena-image.bbappend` file shall define the following variables:

    - `IMAGE_FSTYPES_<yocto-machine-name>`: this variable is used to declare the type of the produced image (it can be ext3, ext4, balenaos-img etc. The usual type for a board that can boot from SD card, USB, is "balenaos-img").

    - `BALENA_BOOT_PARTITION_FILES_<yocto-machine-name>`: this allows adding files from the build's deploy directory into the vfat formatted resin-boot partition (can be used to add bootloader config files, first stage bootloader, initramfs or anything else needed for the booting process to take place for your particular board). If the board uses different bootloader configuration files when booting from either external media (USB thumb drive, SD card etc.) or from internal media (mSATA, eMMC etc) then you would want make use of this variable to make sure the different bootloader configuration files get copied over and further manipulated as needed (see `INTERNAL_DEVICE_BOOTLOADER_CONFIG_<yocto-machine-name>` and `INTERNAL_DEVICE_BOOTLOADER_CONFIG_PATH_<yocto-machine-name>` below). Please note that you only reference these files here, it is the responsibility of a `.bb` or `.bbappend` to provide and deploy them (for bootloader config files this is done with an append typically in `recipes-bsp/<your board's bootloader>/<your board's bootloader>.bbappend`, see [balena-intel grub bbappend](https://github.com/balena-os/balena-intel/blob/master/layers/meta-balena-genericx86/recipes-bsp/grub/grub_%25.bbappend) for an example)

    It is a space separated list of items with the following format: *FilenameRelativeToDeployDir:FilenameOnTheTarget*. If *FilenameOnTheTarget* is omitted then the *FilenameRelativeToDeployDir* will be used.

    For example to have the Intel NUC `bzImage-intel-corei7-64.bin` copied from deploy directory over to the boot partition, renamed to `vmlinuz`:

    ```bash
    BALENA_BOOT_PARTITION_FILES_nuc = "bzImage-intel-corei7-64.bin:vmlinuz"
    ```

  The `balena-image-flasher.bbappend` file shall define the following variables:

    - `IMAGE_FSTYPES_<yocto-machine-name>` (see above)
    - `BALENA_BOOT_PARTITION_FILES_<yocto-machine-name>` (see above). For example, if the board uses different bootloader configuration files for booting from SD/USB and internal storage (see below the use of `INTERNAL_DEVICE_BOOTLOADER_CONFIG` variable), then make sure these files end up in the boot partition (i.e. they should be listed in this `BALENA_BOOT_PARTITION_FILES_<yocto-machine-name>` variable)

- `recipes-kernel/linux directory`: shall contain a `.bbappend` to the kernel recipe used by the respective board. This kernel `.bbappend` must "inherit kernel-balena" in order to add the necessary kernel configs for using with balena.

- `recipes-support/balena-init` directory - shall contain a `balena-init-flasher.bbappend` file if you intend to install balena to internal storage and hence use the flasher image. This shall define the following variables:

  - `INTERNAL_DEVICE_KERNEL_<yocto-machine-name>`: this variable is used to identify the internal storage where balena will be written to.
  - `INTERNAL_DEVICE_BOOTLOADER_CONFIG_<yocto-machine-name>`: this variable is used to specify the filename of the bootloader configuration file used by your board when booting from internal media (must be the same with the *FilenameOnTheTarget* parameter of the bootloader internal config file used in the `BALENA_BOOT_PARTITION_FILES_<yocto-machine-name>` variable from `recipes-core/images/balena-image-flasher.bbappend`)

  - `INTERNAL_DEVICE_BOOTLOADER_CONFIG_PATH_<yocto-machine-name>`: this variable is used to specify the relative path (including filename) to the resin-boot partition where `INTERNAL_DEVICE_BOOTLOADER_CONFIG_<yocto-machine-name>` will be copied to.

    For example, setting

    ```bash
    INTERNAL_DEVICE_BOOTLOADER_CONFIG_intel-corei7-64 = "grub.cfg_internal"
    ```
    and
    ```bash
    INTERNAL_DEVICE_BOOTLOADER_CONFIG_PATH_intel-corei7-64 = "/EFI/BOOT/grub.cfg"
    ```
    will result that after flashing the file `grub.cfg`_internal is copied with the name `grub.cfg` to the /EFI/BOOT/ directory on the resin-boot partition.


The directory structure then looks similar to this:
```
├── COPYING.Apache-2.0
├── README.md
├── conf
│   ├── layer.conf
│   └── samples
│       ├── bblayers.conf.sample
│       └── local.conf.sample
├── recipes-bsp
│   └── bootfiles
├── recipes-containers
│   └── docker-disk
│       └── docker-balena-supervisor-disk.bbappend
├── recipes-core
│   ├── images
│   │   └── balena-image.bbappend
├── recipes-kernel
│   └── linux
│       ├── linux-<board-family>-<version>
│       │   └── <patch files>
│       ├── linux-<board-family>_%.bbappend
│       └── linux-<board>_<version>.bbappend
└── recipes-support
    └── balena-init
        ├── files
        │   └── balena-init-board
        └── balena-init-board.bbappend
```

### Building

See the [meta-balena Readme](https://github.com/balena-os/meta-balena/blob/master/README.md) on how to build the new balenaOS image after setting up the new board package as defined above.

### Configure

The image(s) created during this build process are considered "unmanaged". These can be flashed onto devices and used for local development. If you would like to configure this image to connect to balenaCloud when provisioned, then you would need a "managed" image. A managed image is pre-configured to provision to balenaCloud when booted. Use the [balena CLI os configure command](https://www.balena.io/docs/reference/balena-cli/#os-configure-image) to configure your image for [supported device types](https://www.balena.io/docs/reference/hardware/devices).

### Troubleshooting

For specific examples on how board support is provided for existing devices, see the repositories in the [Supported Boards](/os/docs/supported-boards/) section.
