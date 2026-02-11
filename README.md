# OpenClaw Assistant – Home Assistant Add-on (DEV)

Run [OpenClaw](https://github.com/openclaw/openclaw) as a Home Assistant add-on — fully self-contained with a web terminal, AI gateway, and all dependencies included.

> **This is the DEV / experimental channel.** It may contain breaking changes and is updated more frequently. For the stable release, use: [techartdev/OpenClawHomeAssistant](https://github.com/techartdev/OpenClawHomeAssistant)

## Quick Start

1. **Add the repository**: Settings → Add-ons → Add-on store → ⋮ → Repositories → paste:
   ```
   https://github.com/techartdev/OpenClawHomeAssistant-dev
   ```
2. **Install** OpenClaw Assistant (DEV)
3. **Start** the add-on
4. **Open** the add-on page — you'll see a terminal
5. **Run** `openclaw onboard` in the terminal to set up your AI providers

## Key Features

- **AI Gateway** — OpenClaw server with chat, skills, and automation capabilities
- **Web Terminal** — browser-based terminal embedded in Home Assistant
- **Assist Pipeline** — use OpenClaw as a conversation agent via the OpenAI-compatible API
- **Browser Automation** — Chromium included for web scraping and automation skills
- **Persistent Storage** — skills, config, and workspace survive add-on updates
- **Bundled Tools** — git, vim, nano, bat, fd, ripgrep, curl, jq, python3, pnpm, Homebrew

## Supported Architectures

| Architecture | Supported |
|---|---|
| amd64 | ✅ |
| aarch64 (RPi 4/5) | ✅ |
| armv7 (RPi 3) | ✅ |

## Documentation

- **[Full documentation →](DOCS.md)** — installation, configuration, use cases, troubleshooting, and more
- **[Security Risks & Disclaimer →](SECURITY.md)** — important risks to understand before using this add-on
