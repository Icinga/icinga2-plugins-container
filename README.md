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

## Container Image Content

The final container image contains

- the check plugins located under `/usr/lib/nagios/plugins/`,
- the required Debian packages in the `/debian-packages` file, and
- a CycloneDX SBOM in `/plugins.cdx.json`.

## Manual Testing

Next to the main `Containerfile`, there is another `Containerfile` for testing available as `.github/workflows/container-image.Containerfile`.
While this is used in the CI to verify the build, it can also be used locally.

```
$ # Build the main container image
$ podman build -t plugins .

$ # Build the testing container image
$ podman build -t plugins-test -f .github/workflows/container-image.Containerfile .

$ # Test the testing container
$ podman run -t --rm plugins-test
[ . . . ]
```

## Release

There are different flavors of the images for different Debian releases.
Please note that this repository adheres to semantic versioning.

To release new container images, update the CHANGELOG.md, create a git tag, and publish a GitHub release.
The CI will take care of the rest.

## SBOM

A CycloneDX SBOM describing all plugins and their versions is also included in the container image.

```
$ podman build -t plugins .
[ . . . ]

$ syft podman:plugins -q --select-catalogers +sbom-cataloger
NAME                VERSION                                   TYPE
check_mssql_health  937f4f0aa7af90506924cb2b772e092e6538b348  UnknownPackage
check_nwc_health    22fcf6b5877e2e503316fed500581d538ae8cfea  UnknownPackage
check_postgres      d0bba94836b2029109c487ed0f800fecd61ab2e9  UnknownPackage
check_ssl_cert      86cbfac35ac339e52baea69a94029ab5b9134f10  UnknownPackage
```
