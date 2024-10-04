# Stage 1: Build stage for qBittorrent
FROM ubuntu:noble AS builder

WORKDIR /build

# Install build dependencies
RUN apt update && apt upgrade -y && apt install -y --no-install-recommends \
    libboost-dev \
    libtorrent-rasterbar-dev \
    libssl-dev \
    qt6-base-dev \
    qt6-base-dev-tools \
    qt6-tools-dev \
    libqt6core6 \
    qt6-base-private-dev \
    zlib1g-dev \
    cmake \
    ninja-build \
    python3 \
    build-essential \
    ca-certificates \
    curl \
    git \
    jq \
    pkg-config

# Compile and install qBittorrent
RUN apt update && apt install -y --no-install-recommends \
    qtbase5-dev \
    qttools5-dev \
    && QBITTORRENT_RELEASE=$(curl -sX GET "https://api.github.com/repos/qBittorrent/qBittorrent/tags" | jq '.[] | select(.name | index ("alpha") | not) | select(.name | index ("beta") | not) | select(.name | index ("rc") | not) | .name' | head -n 1 | tr -d '"') \
    && curl -o qBittorrent-${QBITTORRENT_RELEASE}.tar.gz -L "https://github.com/qbittorrent/qBittorrent/archive/${QBITTORRENT_RELEASE}.tar.gz" \
    && tar -xzf qBittorrent-${QBITTORRENT_RELEASE}.tar.gz \
    && cd qBittorrent-${QBITTORRENT_RELEASE} \
    && cmake -G Ninja -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DGUI=OFF -DQT6=ON -DCMAKE_CXX_STANDARD=17 \
    && cmake --build build --parallel $(nproc) \
    && cmake --install build

# Stage 2: Final image, copy qBittorrent from builder and install runtime dependencies
FROM ubuntu:noble

# Set working directory
WORKDIR /opt

# Create user and make directories
RUN usermod -u 99 nobody && mkdir -p /downloads /config/qBittorrent /etc/openvpn /etc/qbittorrent

# Install runtime dependencies
RUN apt update && apt install -y --no-install-recommends \
    ca-certificates \
    dos2unix \
    inetutils-ping \
    libtorrent-rasterbar-dev \
    ipcalc \
    iptables \
    iproute2 \
    kmod \
    libqt6network6 \
    libqt6xml6 \
    libqt6sql6 \
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

# Copy compiled qBittorrent and other necessary files from the builder stage
COPY --from=builder /usr/local /usr/local
ADD openvpn/ /etc/openvpn/
ADD qbittorrent/ /etc/qbittorrent/
RUN chmod +x /etc/qbittorrent/*.sh /etc/qbittorrent/*.init /etc/openvpn/*.sh

# Remove src_valid_mark from wg-quick
RUN sed -i /net\.ipv4\.conf\.all\.src_valid_mark/d `which wg-quick`

# Define volumes and expose ports
VOLUME /config /downloads
EXPOSE 8080 8999 8999/udp

CMD ["/bin/bash", "/etc/openvpn/start.sh"]
