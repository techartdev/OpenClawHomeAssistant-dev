ARG BUILD_FROM=ghcr.io/hassio-addons/base:14.0.2
FROM ${BUILD_FROM}

# Base image is Alpine (HA add-ons base). We install Node.js from Alpine edge.
# This avoids arch-specific manual Node downloads (needed for ARM/aarch64).

RUN apk add --no-cache \
    --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
    --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
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
    nodejs-current \
    npm

# Node.js is installed from Alpine edge (nodejs-current + npm) above.
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
