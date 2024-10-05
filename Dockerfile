# Single stage Dockerfile
FROM ubuntu:noble

WORKDIR /opt

# Install runtime dependencies
RUN apt update && apt install -y --no-install-recommends \
    ca-certificates \
    curl \
    dos2unix \
    inetutils-ping \
    ipcalc \
    iptables \
    iproute2 \
    kmod \
    moreutils \
    net-tools \
    openvpn \
    procps \
    wireguard-tools \
    resolvconf \
    unrar \
    p7zip-full \
    unzip \
    zip \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download the statically compiled qbittorrent-nox and place it in /usr/local/bin
RUN curl -L -o /usr/local/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86_64-qbittorrent-nox \
    && chmod 755 /usr/local/bin/qbittorrent-nox \
    && chown nobody:nogroup /usr/local/bin/qbittorrent-nox

# Create user and make directories
RUN usermod -u 99 nobody && mkdir -p /downloads /config/qBittorrent /etc/openvpn /etc/qbittorrent

# Add OpenVPN and qBittorrent config files
ADD openvpn/ /etc/openvpn/
ADD qbittorrent/ /etc/qbittorrent/
RUN chmod +x /etc/qbittorrent/*.sh /etc/qbittorrent/*.init /etc/openvpn/*.sh

# Remove src_valid_mark from wg-quick
RUN sed -i /net\.ipv4\.conf\.all\.src_valid_mark/d `which wg-quick`

# Define volumes and expose ports
VOLUME /config /downloads
EXPOSE 8080 8999 8999/udp

CMD ["/bin/bash", "/etc/openvpn/start.sh"]
