# SPDX-FileCopyrightText: 2026 Icinga GmbH <https://icinga.com>
# SPDX-License-Identifier: GPL-2.0-or-later

ARG DEBIAN_VERSION="trixie"

FROM debian:${DEBIAN_VERSION}-slim AS build-plugins

ENV CHECK_MSSQL_HEALTH_REF=937f4f0aa7af90506924cb2b772e092e6538b348
ENV CHECK_NWC_HEALTH_REF=22fcf6b5877e2e503316fed500581d538ae8cfea
ENV CHECK_POSTGRES_REF=d0bba94836b2029109c487ed0f800fecd61ab2e9
ENV CHECK_SSL_CERT_REF=86cbfac35ac339e52baea69a94029ab5b9134f10

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        autoconf \
        automake \
        ca-certificates \
        make \
        git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /check_mssql_health
RUN git clone --recurse-submodules https://github.com/lausser/check_mssql_health.git . && \
    git checkout "$CHECK_MSSQL_HEALTH_REF" && \
    mkdir bin && \
    autoreconf && \
    ./configure "--build=$(uname -m)-unknown-linux-gnu" --libexecdir=/usr/lib/nagios/plugins && \
    make && \
    make install DESTDIR="$(pwd)/bin"

WORKDIR /check_nwc_health
RUN git clone --recurse-submodules https://github.com/lausser/check_nwc_health.git . && \
    git checkout "$CHECK_NWC_HEALTH_REF" && \
    mkdir bin && \
    autoreconf && \
    ./configure "--build=$(uname -m)-unknown-linux-gnu" --libexecdir=/usr/lib/nagios/plugins && \
    make && \
    make install DESTDIR="$(pwd)/bin"

WORKDIR /check_postgres
RUN git clone --recurse-submodules https://github.com/bucardo/check_postgres.git . && \
    git checkout "$CHECK_POSTGRES_REF" && \
    mkdir bin && \
    perl Makefile.PL INSTALLSITESCRIPT=/usr/lib/nagios/plugins && \
    make && \
    make install DESTDIR="$(pwd)/bin" && \
    # This is necessary because of this build error: cannot copy to non-directory: /var/lib/docker/.../merged/usr/local/man
    rm -rf bin/usr/local/man

WORKDIR /check_ssl_cert
RUN git clone --recurse-submodules https://github.com/matteocorti/check_ssl_cert.git . && \
    git checkout "$CHECK_SSL_CERT_REF"

WORKDIR /deb-requirements
RUN cat - <<EOF > packages
bc
bind9-dnsutils
bind9-host
ca-certificates
curl
file
libfile-slurp-perl
libjson-perl
libjson-xs-perl
openssl
EOF

WORKDIR /sbom
RUN sep=""; sbomComponent() { \
        printf '%s{"type":"application","name":"%s","version":"%s","licenses":[{"license":{"id":"%s"}}],"purl":"pkg:github/%s/%s@%s"}' \
            "$sep" "$2" "$3" "$4" "$1" "$2" "$3"; \
        sep=","; \
    } && \
    { \
        printf '{"bomFormat":"CycloneDX","specVersion":"1.7","components":['; \
        sbomComponent lausser     check_mssql_health "$CHECK_MSSQL_HEALTH_REF" GPL-2.0-only; \
        sbomComponent lausser     check_nwc_health   "$CHECK_NWC_HEALTH_REF"   GPL-2.0-only; \
        sbomComponent bucardo     check_postgres     "$CHECK_POSTGRES_REF"     BSD-2-Clause; \
        sbomComponent matteocorti check_ssl_cert     "$CHECK_SSL_CERT_REF"     GPL-3.0-only; \
        printf ']}\n'; \
    } | tee plugins.cdx.json

FROM scratch

COPY --from=build-plugins /check_mssql_health/bin/usr/lib/nagios/plugins/* /usr/lib/nagios/plugins/
COPY --from=build-plugins /check_nwc_health/bin/usr/lib/nagios/plugins/* /usr/lib/nagios/plugins/
COPY --from=build-plugins /check_postgres/bin/usr/lib/nagios/plugins/* /usr/lib/nagios/plugins/
COPY --from=build-plugins /check_ssl_cert/check_ssl_cert /usr/lib/nagios/plugins/

COPY --from=build-plugins /deb-requirements/packages /debian-packages
COPY --from=build-plugins /sbom/plugins.cdx.json /plugins.cdx.json
