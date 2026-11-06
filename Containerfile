# SPDX-FileCopyrightText: 2026 Icinga GmbH <https://icinga.com>
# SPDX-License-Identifier: GPL-2.0-or-later

FROM debian:trixie-slim AS build-plugins

ENV CHECK_MSSQL_HEALTH_REF=747af4c3c261790341da164b58d84db9c7fa5480
ENV CHECK_NWC_HEALTH_REF=a5295475c9bbd6df9fe7432347f7c5aba16b49df
ENV CHECK_POSTGRES_REF=58de936fdfe4073413340cbd9061aa69099f1680
ENV CHECK_SSL_CERT_REF=341b5813108fb2367ada81e866da989ea4fb29e7

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        autoconf \
        automake \
        make && \
    rm -rf /var/lib/apt/lists/*

ADD https://github.com/lausser/check_mssql_health.git#${CHECK_MSSQL_HEALTH_REF} /check_mssql_health
ADD https://github.com/lausser/check_nwc_health.git#${CHECK_NWC_HEALTH_REF} /check_nwc_health
ADD https://github.com/bucardo/check_postgres.git#${CHECK_POSTGRES_REF} /check_postgres
ADD https://github.com/matteocorti/check_ssl_cert.git#${CHECK_SSL_CERT_REF} /check_ssl_cert

WORKDIR /check_mssql_health
RUN mkdir bin && \
    autoconf && \
    autoreconf && \
    ./configure "--build=$(uname -m)-unknown-linux-gnu" --libexecdir=/usr/lib/nagios/plugins && \
    make && \
    make install DESTDIR="$(pwd)/bin"

WORKDIR /check_nwc_health
RUN mkdir bin && \
    autoreconf && \
    ./configure "--build=$(uname -m)-unknown-linux-gnu" --libexecdir=/usr/lib/nagios/plugins && \
    make && \
    make install DESTDIR="$(pwd)/bin"

WORKDIR /check_postgres
RUN mkdir bin && \
    perl Makefile.PL INSTALLSITESCRIPT=/usr/lib/nagios/plugins && \
    make && \
    make install DESTDIR="$(pwd)/bin" && \
    # This is necessary because of this build error: cannot copy to non-directory: /var/lib/docker/.../merged/usr/local/man
    rm -rf bin/usr/local/man

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

COPY --from=build-plugins /check_mssql_health/bin/ /
COPY --from=build-plugins /check_nwc_health/bin/ /
COPY --from=build-plugins /check_postgres/bin/ /
COPY --from=build-plugins /check_ssl_cert/check_ssl_cert /usr/lib/nagios/plugins/check_ssl_cert
COPY --from=build-plugins /sbom/plugins.cdx.json /usr/share/sbom/plugins.cdx.json
