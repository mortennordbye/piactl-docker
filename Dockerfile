#############################################
# 1) Builder: auto-detect, download & extract PIA installer
#############################################
FROM ubuntu:22.04 AS builder

# install tools + deps needed to fetch & extract
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl psmisc iptables libnl-3-200 libnl-route-3-200 grep sed coreutils && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user to run the installer
RUN useradd -m builder
USER builder
WORKDIR /home/builder

RUN set -eux; \
    # 1) grab the PIA Linux page
    html=$(curl -fsSL https://www.privateinternetaccess.com/download/linux-vpn); \
    # 2) extract the installer URL
    installer_url=$(echo "$html" \
      | grep -oE 'https://installers\.privateinternetaccess\.com/download/pia-linux-[0-9]+\.[0-9]+\.[0-9]+-[0-9]{5}\.run' \
      | head -1); \
    echo "Downloading installer: $installer_url"; \
    # 3) fetch + unpack as normal user
    curl -fsSL "$installer_url" -o pia.run; \
    chmod +x pia.run; \
    sh pia.run --target /opt/piavpn --nox11 --unattended

# Switch back to root to copy files
USER root

#############################################
# 2) Final: minimal runtime image
#############################################
FROM ubuntu:22.04

# copy over the extracted install
COPY --from=builder /opt/piavpn /opt/piavpn

# runtime deps
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      iptables libnl-3-200 libnl-route-3-200 psmisc && \
    rm -rf /var/lib/apt/lists/*

# put piactl on PATH
ENV PATH=/opt/piavpn/bin:$PATH
ENTRYPOINT ["piactl"]
CMD ["--help"]
