# SPDX-FileCopyrightText: 2026 Icinga GmbH <https://icinga.com>
# SPDX-License-Identifier: GPL-2.0-or-later

ARG DEBIAN_VERSION="trixie"
ARG PLUGINS=ghcr.io/icinga/icinga2-plugins-container:${DEBIAN_VERSION}

FROM ${PLUGINS} AS plugins

FROM debian:${DEBIAN_VERSION}-slim

COPY --from=plugins /usr/lib/nagios/plugins/* /usr/lib/nagios/plugins/
COPY --from=plugins /plugins.cdx.json /usr/share/sbom/

RUN --mount=from=plugins,target=/plugins \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
        $(cat /plugins/debian-packages) && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/lib/nagios/plugins
CMD set -e; \
    for c in mssql_health nwc_health postgres.pl ssl_cert; do \
        test -x "check_$c"; \
        "./check_$c" --version || true; \
        echo; \
    done
