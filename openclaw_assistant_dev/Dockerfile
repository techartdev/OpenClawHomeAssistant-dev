ARG BUILD_FROM
FROM ${BUILD_FROM}

# Base image is Debian Bookworm (glibc). This avoids musl-related native module issues
# that occur on Alpine (e.g. clipboard, node-llama-cpp).

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    git \
    openssh-client \
    ca-certificates \
    tzdata \
    jq \
    curl \
    tar \
    xz-utils \
    file \
    python3 \
    nginx \
    nodejs \
    npm \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install ttyd (web terminal) - not in Debian repos, download binary
ARG TARGETARCH
RUN ARCH=$(echo ${TARGETARCH:-$(dpkg --print-architecture)} | sed 's/aarch64/arm64/;s/armv7/armhf/;s/amd64/x86_64/') \
 && curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.${ARCH}" -o /usr/local/bin/ttyd \
 && chmod +x /usr/local/bin/ttyd

RUN node -v && npm -v

# Install OpenClaw globally
RUN npm config set fund false && npm config set audit false \
 && npm install -g openclaw@2026.1.30

COPY run.sh /run.sh
COPY nginx.conf.tpl /etc/nginx/nginx.conf.tpl
COPY landing.html.tpl /etc/nginx/landing.html.tpl
RUN chmod +x /run.sh \
 && mkdir -p /run/nginx

CMD [ "/run.sh" ]
