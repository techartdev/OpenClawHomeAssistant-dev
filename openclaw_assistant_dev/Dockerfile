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
 && npm install -g openclaw@2026.1.29 \
 # Workaround for platforms where @mariozechner/clipboard native prebuilds are missing
 # (e.g. aarch64 Alpine/musl on Raspberry Pi). Clipboard is optional for the HA add-on.
 && node -e "const fs=require('fs'); const p='/usr/local/lib/node_modules/openclaw/node_modules/@mariozechner/clipboard/index.js'; if(!fs.existsSync(p)){process.exit(0)}; let s=fs.readFileSync(p,'utf8'); const needle=`if (!nativeBinding) {\n  if (loadError) {\n    throw loadError\n  }\n  throw new Error(\`Failed to load native binding\`)\n}\n`; if(s.includes('PapurHa-clipboard-fallback')){process.exit(0)}; if(!s.includes(needle)){console.error('Unexpected clipboard index.js format; cannot patch'); process.exit(1)}; const repl=`if (!nativeBinding) {\n  // PapurHa-clipboard-fallback: In the HA add-on we can run headless.\n  // If native clipboard bindings are unavailable (common on some musl/ARM builds),\n  // fall back to no-op implementations so OpenClaw can still start.\n  nativeBinding = {\n    availableFormats: () => [],\n    getText: async () => '',\n    setText: async () => {},\n    hasText: async () => false,\n    getImageBinary: async () => null,\n    getImageBase64: async () => null,\n    setImageBinary: async () => {},\n    setImageBase64: async () => {},\n    hasImage: async () => false,\n    getHtml: async () => null,\n    setHtml: async () => {},\n    hasHtml: async () => false,\n    getRtf: async () => null,\n    setRtf: async () => {},\n    hasRtf: async () => false,\n    clear: async () => {},\n    watch: () => ({ close: () => {} }),\n    callThreadsafeFunction: () => {}\n  }\n}\n`; s=s.replace(needle,repl); fs.writeFileSync(p,s); console.log('Patched clipboard fallback:',p);"

COPY run.sh /run.sh
COPY nginx.conf.tpl /etc/nginx/nginx.conf.tpl
COPY landing.html.tpl /etc/nginx/landing.html.tpl
RUN chmod +x /run.sh \
 && mkdir -p /run/nginx

CMD [ "/run.sh" ]
