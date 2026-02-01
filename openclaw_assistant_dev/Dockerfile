ARG BUILD_FROM=ghcr.io/hassio-addons/base:17.2.5
FROM ${BUILD_FROM}

# Base image is Alpine (HA add-ons base). We install Node.js from Alpine edge.
# This avoids arch-specific manual Node downloads (needed for ARM/aarch64).

RUN apk add --no-cache \
    bash \
    git \
    openssh-client \
    ca-certificates \
    tzdata \
    jq \
    curl \
    tar \
    xz \
    libstdc++ \
    libgcc \
    libatomic \
    file \
    pax-utils \
    python3 \
    nginx \
    ttyd \
    nodejs \
    npm

# Node.js LTS installed from Alpine 3.21 repos.
RUN node -v && npm -v

# Install OpenClaw globally
RUN npm config set fund false && npm config set audit false \
 && npm install -g openclaw@2026.1.29

COPY run.sh /run.sh
COPY nginx.conf.tpl /etc/nginx/nginx.conf.tpl
COPY landing.html.tpl /etc/nginx/landing.html.tpl
RUN chmod +x /run.sh \
 && mkdir -p /run/nginx

CMD [ "/run.sh" ]
