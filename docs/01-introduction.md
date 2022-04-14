# Introduction

To understand how openbalena works, let's start with learning about balenaOS.

## What is balenaOS?
balenaOS has been designed to include the minimal set of required components to reliably support operation of the Docker engine in embedded scenarios. It uses the Yocto framework as a foundation, systemd as the init system.

The networking stack consists of Network Manager, DNSmasq and Modem Manager. We have found these components to be a robust stack for dealing with the diversity of hardware and unpredictability of configuration of networks in which a device may be booted.

In addition, we include Avahi, OpenSSH, and OpenVPN, which add support for mDNS, SSH, and VPN connections respectively.

This foundation is uniquely suited to running arbitrary containers on a wide range of embedded devices which balenaOS supports. Balena has also made available a wide selection of base images for containers which are optimised for the same scenario and allow developers to create applications based on the Debian, Alpine, or Fedora distributions. That is not to say, of course, that any other container base image may not be used, but that the images by balena have been verified to work well with balenaOS, implementing patterns which are particularly suitable for embedded devices, like balenaOS itself.

![balenaOS components](/docs/assets/balenaOS-components.png)