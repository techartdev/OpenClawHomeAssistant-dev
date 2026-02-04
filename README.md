# OpenClaw Assistant – Home Assistant Add-on (DEV / Experimental)

This repository is the **DEV / experimental channel** for the OpenClaw Home Assistant add-on.

- It may contain **breaking changes**.
- It may be **unstable**.
- Updates may be pushed more frequently.

If you want the stable/released add-on, use the main repo instead:
- https://github.com/techartdev/OpenClawHomeAssistant

## What this repo is for

Use this repo if you:
- want to test new features/fixes before they go to stable
- want to help validate changes on different hardware (e.g. Raspberry Pi / ARM)

## How to install

Home Assistant → Settings → Add-ons → Add-on store → ⋮ → Repositories → add:
- `https://github.com/techartdev/OpenClawHomeAssistant-dev`

Then install **OpenClaw Assistant (DEV)**.

## Features

### Browser Automation (Chromium)

This add-on includes **Chromium** for website automation tasks. OpenClaw can use it for browser-based skills and automation.

#### Configuration

OpenClaw's browser tool uses its own control service/protocol. Configure it in one of two ways:

**Option 1: Via `openclaw.json`**

Add to `/config/.openclaw/openclaw.json`:

```json
{
  "browser": {
    "enabled": true,
    "headless": true,
    "noSandbox": true,
    "cdpUrl": "http://127.0.0.1:9222"
  }
}
```

**Option 2: Via Gateway Flags**

Start OpenClaw gateway with browser flags:

```bash
openclaw gateway --browser-headless --browser-no-sandbox
```

**Note:** The `noSandbox` flag is required in Docker containers due to security restrictions.

## Docs

For full documentation, see the stable repo docs (kept in sync as best-effort):
- https://github.com/techartdev/OpenClawHomeAssistant
