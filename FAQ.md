# FAQ

## How do I know if my device will work with openBalena?

Any device that can run balenaOS will work with openBalena. BalenaOS supports many different device types and multiple architectures. Check out the full list of supported devices [here](https://balena.io/os/#download).
Note that for the beta release, openBalena will only support the Raspberry Pi family, the Intel NUC, the NVIDIA Jetson TX2, and the balenaFin.

## What are the requirements for my development machine to run openBalena?

To run openBalena server, your machine will need the following:

- Docker >= 18.05.0
- Docker Compose >= 1.11
- OpenSSL >= 1.0.0
- python >= 2.7 or >=3.4

To control an existing openBalena instance with the CLI:

- node.js >= 6
- Docker >= 18.05.0

## What’s the difference between openBalena and balenaCloud?

Whilst openBalena and balenaCloud share the same core technology, there are some key differences. First, openBalena is self-hosted, whereas balenaCloud is hosted by balena and therefore handles security, maintenance, scaling, and reliability of all the backend services. OpenBalena is also single user, whereas balenaCloud supports multiple users and organizations. OpenBalena also lacks some of the commercial features that define balenaCloud, such as the web-based dashboard and updates with binary container deltas.

## How do I move from openBalena to balenaCloud and vice versa?

We’ve added a feature to balenaOS giving devices the ability to join and leave a server. In practice, this means that balena customers will always have the option of setting up an open source server and no longer using the cloud service, while open source users can always migrate to balenaCloud if they need a ready-to-use, commercially supported platform. At balena, we want our relationship to be defined by the value we provide, not by the lockin that is created by the inability to move. We see openBalena as a big step towards removing those barriers to exit (and entry!).

## Why should I use containers in my IoT project?

Linux containers have become a standard tool in cloud development and deployment workflows. The benefits are numerous, including portability across platforms, easy dependency management, minimal overhead, and more control for developers over how their code runs. The popularity of containers continues to grow: Docker, an open source container engine, has seen especially high traction, with one study showing a 40% increase in adoption over the course of a year. It’s clear that containers matter, and we think they matter even more for the Internet of Things.

## How can I contribute to openBalena?

All of openBalena is hosted on GitHub. The best place to start is by visiting the [central repository](https://github.com/balena-io/open-balena) and check for open issues. You can also contribute to openBalena’s client-side software such as [balenaOS](https://github.com/balena-os/meta-balena), [balenaEngine](https://github.com/balena-os/balena-engine), the [balena CLI](https://github.com/balena-io/balena-cli), and the [balena SDK](https://github.com/balena-io/balena-sdk).
