# Icinga 2 Plugins Container

This repository contains an intermediate container image to be referenced in Icinga 2's main Containerfile.
It ships external check plugins which are not available in any package manager.

By extracting this step into its own container image - independent of Icinga 2's release cycle -,
we are able to bump versions here whenever it seems necessary.
After updating this container image, the Icinga 2 container image can be rebuilt under the same release tag,
but including the latest versions.

The following check commands are included:

- [`check_mssql_health`](https://github.com/lausser/check_mssql_health)
- [`check_nwc_health`](https://github.com/lausser/check_nwc_health)
- [`check_postgres`](https://github.com/bucardo/check_postgres)
- [`check_ssl_cert`](https://github.com/matteocorti/check_ssl_cert)

## Usage

The container image `ghcr.io/icinga/icinga2-plugins-container` contains the check plugins
as well as a list of required Debian packages, located under `/icinga2-plugins-debian-requirements`.
The content of the complete container image can be copied into the image, followed by installing the dependencies.

An example is available in `.github/workflows/container-image.Containerfile`, otherwise check Icinga 2.

## Release

There are different flavors of the images for different Debian releases.
Please note that this repository adheres to semantic versioning.

To release new container images, update the CHANGELOG.md, create a git tag, and publish a GitHub release.
The CI will take care of the rest.

## SBOM

A CycloneDX SBOM describing all plugins and their versions is also included in the container image.

```
$ podman build -t icinga2-plugins-container .
[ . . . ]

$ syft podman:icinga2-plugins-container -q --select-catalogers +sbom-cataloger
NAME                VERSION                                   TYPE
check_mssql_health  937f4f0aa7af90506924cb2b772e092e6538b348  UnknownPackage
check_nwc_health    22fcf6b5877e2e503316fed500581d538ae8cfea  UnknownPackage
check_postgres      UNKNOWN                                   cpan
check_postgres      d0bba94836b2029109c487ed0f800fecd61ab2e9  UnknownPackage
check_ssl_cert      86cbfac35ac339e52baea69a94029ab5b9134f10  UnknownPackage
```
