![logo](/docs/assets/openbalena-logo.svg)

**openbalena is an open source platform to manage IoT and edge device fleets at scale.**

## Highlights
- **Simple provisioning**: Adding devices to your fleet is a breeze
- **Easy updates**: Remotely update the software on your devices with a single command
- **Container-based**: Benefit from the power of virtualization, optimized for the edge
- **Scalable**: Deploy and manage one device, or one million
- **Powerful API & SDK**: Extend openBalena to fit your needs
- **Built-in VPN**: Access your devices regardless of their network environment

## Setup and Configuration

Our [Getting Started guide][getting-started] is the most direct path to getting an openbalena installation up and running and successfully deploying your application to your device(s).

## Motivation

openbalena is a platform that helps you deploy and manage connected devices. Devices run [balenaOS][balena-os-website], a host operating system designed for running containers on IoT devices, and are managed via the [balena CLI][balena-cli], which you can use to configure your application containers, push updates, check status, view logs, and more.

openbalena’s backend services, composed of battle-tested components that we’ve run in production on [balenaCloud][balena-cloud-website] for years, can store device information securely and reliably, allow remote management via a built-in VPN service, and efficiently distribute container images to your devices.

To learn more about openbalena, visit [balena.io/open][open-balena-website].

### Documentation

Check out our Getting Started guide in the [docs](/docs), as well as additional resources. Since balenaCloud is built on top of openbalena, their core concepts and functionality are identical. This means you can refer to the [balenaCloud documentation][documentation]. The following sections are of particular interest:

- [Overview / A balena primer](https://balena.io/docs/learn/welcome/primer)
- [Overview / Core Concepts](https://balena.io/docs/learn/welcome/concepts)
- [Overview / Going to production](https://balena.io/docs/learn/welcome/production-plan)
- [Develop / Define a container](https://balena.io/docs/learn/develop/dockerfile)
- [Develop / Multiple containers](https://balena.io/docs/learn/develop/multicontainer)
- [Develop / Runtime](https://balena.io/docs/learn/develop/runtime)
- [Develop / Interact with hardware](https://balena.io/docs/learn/develop/hardware)
- [Deploy / Optimize your builds](https://balena.io/docs/learn/deploy/build-optimization)
- [Reference](https://balena.io/docs/reference)
- [FAQ](https://balena.io/docs/faq/troubleshooting/faq)

### Compatibility

The current release of openBalena has the following minimum version requirements:

- balenaOS v2.58.3
- balena CLI v12.38.5

If you are updating from previous openBalena versions, ensure you update the balena
CLI and reprovision any devices to at least the minimum required versions in order
for them to be fully compatible with this release, as some features may not work.

### Contributing to openbalena

Everyone is welcome to contribute to openBalena. There are many different ways
to get involved apart from submitting pull requests, including helping other
users on the [forums][forums], reporting or triaging [issues][issue-tracker],
reviewing and discussing [pull requests][pulls], or just spreading the word.

All of openbalena is hosted on GitHub. Apart from its constituent components,
which are the [API][open-balena-api], [VPN][open-balena-vpn], [Registry][open-balena-registry],
[S3 storage service][open-balena-s3], and [Database][open-balena-db], contributions
are also welcome to its client-side software such as the [balena CLI][balena-cli],
the [balena SDK][balena-sdk], [balenaOS][balena-os] and [balenaEngine][balena-engine].

### License

openbalena is licensed under the terms of AGPL v3. See [LICENSE](LICENSE) for details.

[balena-cli]: https://github.com/balena-io/balena-cli
[balena-cloud-website]: https://balena.io/cloud
[balena-engine]: https://github.com/balena-os/balena-engine
[balena-os-website]: https://balena.io/os
[balena-os]: https://github.com/balena-os/meta-balena
[balena-sdk]: https://github.com/balena-io/balena-sdk
[documentation]: https://balena.io/docs/learn/welcome/introduction/
[forums]: https://forums.balena.io/c/open-balena
[getting-started]: https://balena.io/open/docs/getting-started
[issue-tracker]: https://github.com/balena-io/open-balena/issues
[open-balena-api]: https://github.com/balena-io/open-balena-api
[open-balena-db]: https://github.com/balena-io/open-balena-db
[open-balena-registry]: https://github.com/balena-io/open-balena-registry
[open-balena-s3]: https://github.com/balena-io/open-balena-s3
[open-balena-vpn]: https://github.com/balena-io/open-balena-vpn
[open-balena-website]: https://balena.io/open
[pulls]: https://github.com/balena-io/open-balena/pulls
