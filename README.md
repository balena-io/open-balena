<img alt="openBalena" src="docs/assets/openbalena-logo.svg" height="82">

---

OpenBalena is a platform to deploy and manage connected devices. Devices run
[balenaOS][balena-os-website], a host operating system designed for running
containers on IoT devices, and are managed via the [balena CLI][balena-cli],
which you can use to configure your application containers, push updates, check
status, view logs, and so forth. OpenBalena’s backend services, composed of
battle-tested components that we’ve run in production on [balenaCloud][balena-cloud-website]
for years, can store device information securely and reliably, allow remote
management via a built-in VPN service, and efficiently distribute container
images to your devices.

To learn more about openBalena, visit [balena.io/open][open-balena-website].


## Features

- **Simple provisioning**: Adding devices to your fleet is a breeze
- **Easy updates**: Remotely update the software on your devices with a single command
- **Container-based**: Benefit from the power of virtualization, optimized for the edge
- **Scalable**: Deploy and manage one device, or one million
- **Powerful API & SDK**: Extend openBalena to fit your needs
- **Built-in VPN**: Access your devices regardless of their network environment


## Roadmap

OpenBalena is currently in beta. While fully functional, it lacks features we
consider important before we can comfortably call it production-ready. During
this phase, don’t be alarmed if things don’t work as expected just yet (and
please let us know about any bugs or errors you encounter!). The following
improvements and new functionality is planned:

- Full documentation
- Full test suite
- Simplified deployment
- Remote host OS updates
- Support for custom device types


## Contributing

Everyone is welcome to contribute to openBalena. There are many different ways
to get involved apart from submitting pull requests, including helping other
users on the [forums][forums], reporting or triaging [issues][issue-tracker],
reviewing and discussing [pull requests][pulls], or just spreading the word.

All of openBalena is hosted on GitHub. Apart from its constituent components,
which are the [API][open-balena-api], [VPN][open-balena-vpn], [Registry][open-balena-registry],
[S3 storage service][open-balena-s3], and [Database][open-balena-db], contributions
are also welcome to its client-side software such as the [balena CLI][balena-cli],
the [balena SDK][balena-sdk], [balenaOS][balena-os] and [balenaEngine][balena-engine].


## Getting Started

Our [Getting Started][getting-started] guide is the most direct path to getting
an openBalena installation up and running and successfully deploying your
application to your device(s).


## Documentation

While we're still working on the project documentation, please refer to the
[balenaCloud documentation][documentation]. BalenaCloud is built on top of
openBalena, so the core concepts and functionality is identical. The following
sections are of particular interest:

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

## openBalena vs balenaCloud

Whilst openBalena and balenaCloud share the same core technology, there are some key differences:

| openBalena  | balenaCloud  |
|---|---|
| self hosted | hosted by balena |
| single user | multi-user and orgs  |
| no dashboard | full dashboard |

## Getting Help

You are welcome to submit any questions, participate in discussions and request
help with any issue in [openBalena forums][forums]. The balena team frequents
these forums and will be happy to help. You can also ask other community members
for help, or contribute by answering questions posted by fellow openBalena users.
Please do not use the issue tracker for support-related questions.


## License

OpenBalena is licensed under the terms of AGPL v3. See [LICENSE](LICENSE) for details.


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
