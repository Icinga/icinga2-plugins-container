# SPDX-FileCopyrightText: 2026 Icinga GmbH <https://icinga.com>
# SPDX-License-Identifier: GPL-2.0-or-later

ARG DEBIAN_VERSION="trixie"

FROM debian:${DEBIAN_VERSION}-slim

COPY --from=plugins / /

RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
        $(cat /icinga2-plugins-debian-requirements) && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/lib/nagios/plugins
CMD set -e; \
    for c in mssql_health nwc_health postgres.pl ssl_cert; do \
        test -x "check_$c"; \
        "./check_$c" --version || true; \
        echo; \
    done
