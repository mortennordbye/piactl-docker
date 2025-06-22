#############################################
# 1) Builder: download & extract PIA installer
#############################################
FROM ubuntu:22.04 AS builder

ARG PIA_VERSION
ENV PIA_VERSION=${PIA_VERSION}

# install tools + deps needed to extract
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl psmisc iptables libnl-3-200 libnl-route-3-200 && \
    rm -rf /var/lib/apt/lists/*

# fetch installer and extract into /opt/piavpn
WORKDIR /tmp
RUN curl -fsSL \
      https://installers.privateinternetaccess.com/download/pia-linux-${PIA_VERSION}.run \
      -o pia.run && \
    chmod +x pia.run && \
    # --target extracts files without running services
    sh pia.run --target /opt/piavpn --nox11 --unattended

#############################################
# 2) Final: minimal runtime image
#############################################
FROM ubuntu:22.04

# Copy extracted PIA install
COPY --from=builder /opt/piavpn /opt/piavpn

# Ensure runtime deps
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      iptables libnl-3-200 libnl-route-3-200 psmisc && \
    rm -rf /var/lib/apt/lists/*

# put piactl on PATH
ENV PATH=/opt/piavpn/bin:$PATH
ENTRYPOINT ["piactl"]
CMD ["--help"]
