# Icinga 2 Plugin Container

This repository contains an intermediate container image to be referenced in Icinga 2's main Containerfile.
It ships external check plugins which are not available in any package manager.

By extracting this step into its own container image - independent of Icinga 2's release cycle -, we are able to bump versions here whenever it seems necessary.
After updating this container image, the Icinga 2 container image can be rebuilt under the same release tag, but including the latest versions.

The following check commands are included:

- [`check_mssql_health`](https://github.com/lausser/check_mssql_health)
- [`check_nwc_health`](https://github.com/lausser/check_nwc_health)
- [`check_postgres`](https://github.com/bucardo/check_postgres)
- [`check_ssl_cert`](https://github.com/matteocorti/check_ssl_cert)

In addition, a CycloneDX SBOM describing all plugins and their version is included as well.

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
