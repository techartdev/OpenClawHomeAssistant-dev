#!/usr/bin/env python3
"""
Render nginx.conf and landing page HTML from templates.

Called by run.sh with the following env vars:
  GW_PUBLIC_URL, GW_TOKEN, TERMINAL_PORT,
  ENABLE_HTTPS_PROXY, HTTPS_PROXY_PORT,
  GATEWAY_INTERNAL_PORT, ACCESS_MODE
"""

import os
import subprocess
from pathlib import Path


def main():
    tpl = Path('/etc/nginx/nginx.conf.tpl').read_text()
    landing_tpl = Path('/etc/nginx/landing.html.tpl').read_text()

    public_url = os.environ.get('GW_PUBLIC_URL', '')
    terminal_port = os.environ.get('TERMINAL_PORT', '7681')
    enable_https = os.environ.get('ENABLE_HTTPS_PROXY', 'false') == 'true'
    https_port = os.environ.get('HTTPS_PROXY_PORT', '')
    internal_gw_port = os.environ.get('GATEWAY_INTERNAL_PORT', '')
    access_mode = os.environ.get('ACCESS_MODE', 'custom')

    # Token comes from environment (best-effort CLI query in run.sh)
    token = os.environ.get('GW_TOKEN', '')

    gw_path = '' if public_url.endswith('/') else '/'

    # ── nginx.conf ──────────────────────────────────────────────
    conf = tpl.replace('__TERMINAL_PORT__', terminal_port)

    # Build HTTPS gateway proxy block (only for lan_https mode)
    https_block = ''
    if enable_https and https_port and internal_gw_port:
        https_block = f"""
    # --- HTTPS Gateway Proxy (lan_https mode) ---
    server {{
        listen {https_port} ssl;

        ssl_certificate     /config/certs/gateway.crt;
        ssl_certificate_key /config/certs/gateway.key;
        ssl_protocols       TLSv1.2 TLSv1.3;
        ssl_ciphers         HIGH:!aNULL:!MD5;

        # Proxy all traffic to the loopback gateway with WebSocket support
        location / {{
            proxy_pass http://127.0.0.1:{internal_gw_port};
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
            proxy_buffering off;
        }}

        # Download the local CA certificate (install on phone for trusted access)
        location = /cert/ca.crt {{
            alias /etc/nginx/html/openclaw-ca.crt;
            default_type application/x-x509-ca-cert;
            add_header Content-Disposition 'attachment; filename="openclaw-ca.crt"';
        }}
    }}
"""

    conf = conf.replace('__HTTPS_GATEWAY_BLOCK__', https_block)
    Path('/etc/nginx/nginx.conf').write_text(conf)

    # ── landing page ────────────────────────────────────────────
    # If lan_https and no explicit public URL, auto-construct one
    if enable_https and not public_url:
        try:
            lan_ip = subprocess.check_output(
                ['hostname', '-I'], text=True, timeout=2
            ).split()[0]
        except Exception:
            lan_ip = '127.0.0.1'
        public_url = f'https://{lan_ip}:{https_port}'
        gw_path = '/'

    landing = landing_tpl.replace('__GATEWAY_TOKEN__', token)
    landing = landing.replace('__GATEWAY_PUBLIC_URL__', public_url)
    landing = landing.replace('__GW_PUBLIC_URL_PATH__', gw_path)
    landing = landing.replace('__ACCESS_MODE__', access_mode)
    landing = landing.replace('__HTTPS_PORT__', https_port if enable_https else '')

    out_dir = Path('/etc/nginx/html')
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / 'index.html'
    out_file.write_text(landing)

    # Ensure nginx can read it even if base image uses restrictive umask/permissions.
    try:
        out_dir.chmod(0o755)
        out_file.chmod(0o644)
    except Exception:
        pass


if __name__ == '__main__':
    main()
