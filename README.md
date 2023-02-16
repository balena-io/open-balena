![](./docs/images/openbalena-logo.svg)

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


## Getting Started

Our [Getting Started guide][getting-started] is the most direct path to getting
an openBalena installation up and running and successfully deploying your
application to your device(s).


## Compatibility

The current release of openBalena has the following minimum version requirements:

- balenaOS v2.58.3
- balena CLI v12.38.5

If you are updating from previous openBalena versions, ensure you update the balena
CLI and reprovision any devices to at least the minimum required versions in order
for them to be fully compatible with this release, as some features may not work.


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


## Getting Help

You are welcome to submit any questions, participate in discussions and request
help with any issue in [openBalena forums][forums]. The balena team frequents
these forums and will be happy to help. You can also ask other community members
for help, or contribute by answering questions posted by fellow openBalena users.
Please do not use the issue tracker for support-related questions.


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


## Differences between openBalena and balenaCloud

Whilst openBalena and balenaCloud share the same core technology, there are some key differences. First, openBalena is self-hosted, whereas balenaCloud is hosted by balena and therefore handles security, maintenance, scaling, and reliability of all the backend services. OpenBalena is also single user, whereas balenaCloud supports multiple users and organizations. OpenBalena also lacks some of the commercial features that define balenaCloud, such as the web-based dashboard and updates with binary container deltas.

The following table contains the main differences between both:

| openBalena                                                                                 | balenaCloud                                                                                                                                                                                               |
| ------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Device updates using full Docker images                                                    | Device updates using [delta images](https://www.balena.io/docs/learn/deploy/delta/)                                                                                                                       |
| Support for a single user                                                                  | Support for [multiple users](https://www.balena.io/docs/learn/manage/account/#application-members)                                                                                                        |
| Self-hosted deployment and scaling                                                         | balena-managed scaling and deployment                                                                                                                                                                     |
| Community support via [forums][forums]                                                     | Private support on [paid plans](https://www.balena.io/pricing/)                                                                                                                                           |
| Build locally and deploy via `balena-cli`                                                  | Build remotely with native builders using [`balena push`](https://www.balena.io/docs/learn/deploy/deployment/#balena-push) or  [`git push`](https://www.balena.io/docs/learn/deploy/deployment/#git-push) |
| No public device URL support                                                               | Serve websites directly from device with [public device URLs](https://www.balena.io/docs/learn/manage/actions/#enable-public-device-url)                                                                  |
| Management via `balena-cli` only                                                           | Cloud-based device management dashboard                                                                                                                                                                   |
| Download images from [balena.io][balena-os-website] and configure locally via `balena-cli` | Download configured images directly from the dashboard                                                                                                                                                    |
| No remote device diagnostics                                                               | Remote device diagnostics                                                                                                                                                                                 |

Additionally, refer back to the [roadmap](#roadmap) above for planned but not yet implemented features.


## License

OpenBalena is licensed under the terms of AGPL v3. See [LICENSE](https://github.com/balena-io/open-balena/blob/master/LICENSE) for details.


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

## FAQ

### How do you ensure continuity of openBalena? Are there security patches on openBalena? 
openBalena is an open source initiative which is mostly driven by us, but it also gets contributions from the community. We work to keep openBalena as up to date as our bandwidth allows, especially with security patches. That said, we do not have a policy or guarantee of a software release schedule. However, it is in our best interest to keep openBalena updated and patched since we also use it for balenaCloud.

### How do you ensure the “Join” command actually works between open and cloud?
The join command is not only used for moving from openBalena to balenaCloud, but it is used daily by our developers to move devices from developments and testing instances to production, and vice versa. The join command actually wraps the os-config command, which is the basic tool balena uses for configuring devices.

### Is it “production ready”?
While we actually have some rather large fleets using openBalena, we as a company consider it still to be in Beta status. We don’t perform regular testing on the platform like we do balenaCloud, and we do not yet have feature-parity between the various services we offer. 

### Can new device-types be added to openBalena?
Technically “yes”, but in a supported or balena-recommended fashion, “no”. The main reason is that until we regularly test the openBalena platform the way we do balenaCloud, there’s no scalable way for us to provide support for new device-types.

### Are there open-source UI dashboards from the community for openBalena?
Yes! Here are a few:
- [open-balena-admin / open-balena-ui](https://github.com/dcaputo-harmoni/open-balena-admin) by user [dcaputo-harmoni](https://github.com/dcaputo-harmoni) who first posted about [here](https://forums.balena.io/t/open-balena-admin-an-admin-interface-for-openbalena/355324) in our Forums :)
- [open-balena-dashboard](https://github.com/Razikus/open-balena-dashboard) by user [Razikus](https://github.com/Razikus)
