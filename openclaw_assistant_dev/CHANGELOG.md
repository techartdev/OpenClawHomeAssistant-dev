# Changelog

All notable changes to the OpenClaw Assistant Home Assistant Add-on will be documented in this file.

## [0.5.87] - 2026-02-25

### Added
- New add-on option `gateway_additional_allowed_origins` for extra Control UI origins in `lan_https` mode.

### Fixed
- `lan_https` startup no longer overwrites `gateway.controlUi.allowedOrigins` with defaults only.
- Control UI origins are now merged as: built-in defaults + existing config values + `gateway_additional_allowed_origins` (deduplicated).

## [0.5.86] - 2026-02-24

### Fixed
- `gateway_mode=remote` no longer crashes startup with `Gateway start blocked: set gateway.mode=local`.
- In `remote` mode the add-on no longer starts a local gateway service.
- In `remote` mode the add-on now starts `openclaw node run` and connects to `gateway.remote.url` (supports `ws://` and `wss://`).

### Added
- New add-on option `gateway_remote_url` (UI field).
- Add-on now writes `gateway.remote.url` in OpenClaw config from `gateway_remote_url` on startup.

## [0.5.85] - 2026-02-24

- Bump OpenClaw to 2026.2.23.
- DOCS: add exact tested setup recipes for `lan_reverse_proxy` and tailnet flow (`tailnet_https` + HA Tailscale add-on + NPM).

## [0.5.84] - 2026-02-23

### Fixed
- Fix `gateway_env_vars` crash on first variable export — `((env_count++))` returns exit code 1 when count is 0 under `set -e`, killing the startup script.

## [0.5.83] - 2026-02-23

### Added
- New add-on option `gateway_env_vars` that accepts a list of `{name, value}` objects from Home Assistant UI and safely injects values into the gateway process at startup (max 50 vars, key <=255 chars, value <=10000 chars).
- Guard `gateway_env_vars` from overriding reserved runtime/proxy/`OPENCLAW_*` keys.
- Keep legacy string/object input formats for backward compatibility.

## [0.5.82] - 2026-02-23

### Fixed
- **`web_fetch failed: fetch failed`**: changed `force_ipv4_dns` default to **true**. Node 22 tries IPv6 first; most HAOS VMs lack IPv6 egress, causing all outbound `web_fetch` / HTTP tool calls to time out.

### Added
- **`nginx_log_level` option** (`minimal` / `full`, default `minimal`): suppresses repetitive Home Assistant health-check and polling requests (`GET /`, `GET /v1/models`, `POST /tools/invoke`) from the nginx access log.

## [0.5.81] - 2026-02-23

### Changed
- **Upgraded OpenClaw to v2026.2.22-2** — includes major gateway/auth/pairing fixes and security hardening.
- Precreate `$OPENCLAW_CONFIG_DIR/identity` on startup to prevent `EACCES` errors on CLI commands that need device identity.

### Notes — v2026.2.22 impact on this add-on
- **Pairing fixes (loopback)**: v2026.2.22 auto-approves loopback scope-upgrade pairing requests, includes `operator.read`/`operator.write` in default scope bundles, and treats `operator.admin` as satisfying other scopes. This greatly improves `local_only` mode reliability.
- **`dangerouslyDisableDeviceAuth` security warning**: v2026.2.22 now emits a startup warning when this flag is active. The warning is **expected and harmless** for `lan_https` mode — the flag is still required because LAN browser connections through the HTTPS proxy are not considered loopback by the gateway. Token auth remains enforced.
- **Removed `food-order` skill**: no longer bundled; install from ClawHub if needed.
- **Gateway lock improvements**: stale-lock detection now uses port reachability, reducing false "already running" errors after unclean restarts.
- **Log file size cap**: new `logging.maxFileBytes` default (500 MB) prevents disk exhaustion from log storms.
- **`wss://` default for remote onboarding**: validates our HTTPS proxy approach as the correct direction.

## [0.5.80] - 2026-02-23

### Fixed
- **`lan_https` — error 1008 "pairing required"**: auto-set `gateway.controlUi.dangerouslyDisableDeviceAuth: true` to skip interactive device pairing (token auth remains enforced). Replaces the invalid `pairingMode` key that caused `Unrecognized key` config errors.
- Config helper now removes stale/invalid keys (e.g. `pairingMode`) from `controlUi` on startup.
- Landing page error translation now covers "pairing required" and "origin not allowed" errors with correct fix guidance.
- Dropdown translations for `access_mode`, `gateway_mode`, `gateway_bind_mode`, and `gateway_auth_mode` now show human-readable labels in all 6 languages.

## [0.5.79] - 2026-02-23

### Fixed
- **`lan_https` — error 1008 "origin not allowed"**: auto-configure `gateway.controlUi.allowedOrigins` with the HTTPS proxy origins (LAN IP, `homeassistant.local`, `homeassistant`) so the Control UI WebSocket is accepted.

## [0.5.78] - 2026-02-23

### Added
- **Disk-space monitoring on the landing page** — shows total / used / available with colour-coded indicator (🟢 / 🟡 / 🔴).
- **Low-disk warning banner** appears automatically when usage exceeds 90 %.
- **`oc-cleanup` terminal command** — interactive helper that shows cache sizes (npm, pnpm, OpenClaw, Homebrew, pycache, tmp) and lets users reclaim space with a menu-driven cleanup.
- Startup disk-space check with log warnings when the overlay is above 75 % or 90 %.

## [0.5.77] - 2026-02-23

### Added
- **`access_mode` preset option** — simplifies secure access configuration with one setting:
  - `custom` (default, backward-compatible): use individual gateway settings
  - `local_only`: loopback + token (Ingress/terminal only)
  - `lan_https`: **built-in HTTPS reverse proxy for LAN access** (recommended for phones/tablets)
  - `lan_reverse_proxy`: LAN bind + trusted-proxy for external reverse proxy (NPM, Caddy, Traefik)
  - `tailnet_https`: Tailscale interface bind + token auth
- **Built-in TLS certificate generation** (`lan_https` mode):
  - Auto-generates a local CA + server certificate on first startup
  - Server cert is regenerated automatically when LAN IP changes
  - CA certificate downloadable from the landing page for one-tap phone trust
  - nginx HTTPS server block terminates TLS and proxies to the loopback gateway
- **Overhauled landing page** with:
  - Real-time status cards (gateway health, secure context, access mode)
  - Access wizard with step-by-step guidance per mode
  - Error translation — maps raw errors like `1008: requires device identity` to friendly messages with fixes
  - CA certificate download button (lan_https mode)
  - Migration banner for users on `custom` mode recommending a preset
  - Collapsible reverse-proxy recipes (NPM / Caddy / Traefik / Tailscale)
- Added `openssl` to Docker image for TLS certificate generation.
- Translations for `access_mode` in all 6 languages (EN, BG, DE, ES, PL, PT-BR).

### Changed
- Gateway token is auto-constructed from detected LAN IP when `lan_https` is active and `gateway_public_url` is empty.
- Config helper now receives the effective internal port (gateway_port + 1 in lan_https mode).

## [0.5.76] - 2026-02-22

### Fixed
- Fix trusted-proxy startup crash by writing required nested `gateway.auth.trustedProxy` config.
- Add default `gateway.auth.trustedProxy.userHeader` = `x-forwarded-user` when `gateway_auth_mode=trusted-proxy`.

## [0.5.75] - 2026-02-22

### Changed
- Removed add-on option `allow_insecure_auth` (upstream Control UI now requires secure context/device identity).
- Added `gateway_auth_mode` option (`token` or `trusted-proxy`).
- Added `gateway_trusted_proxies` option (comma-separated IP/CIDR list).
- Startup config apply now writes `gateway.auth.mode` and `gateway.trustedProxies`.
- Updated docs/translations for HTTPS + reverse-proxy configuration.

## [0.5.74] - 2026-02-22

### Added
- New add-on option `http_proxy` for configuring outbound HTTP/HTTPS proxy from Home Assistant settings.
- Proxy shim (`openclaw-proxy-shim.cjs`) to enable undici/OpenClaw HTTP(S)_PROXY support at startup.

### Changed
- Export `HTTP_PROXY`, `HTTPS_PROXY`, `http_proxy`, and `https_proxy` from add-on config at startup.
- Apply default `NO_PROXY`/`no_proxy` bypass ranges for localhost and private network ranges.
- Add translations for the new `http_proxy` option.
- Document proxy configuration in README and DOCS.

## [0.5.73] - 2026-02-22

### Changed
- Bump OpenClaw to 2026.2.21-2.
- Add Home Assistant `share` and `media` mounts to the add-on (`map: share:rw, media:rw`).

## [0.5.72] - 2026-02-21
- Empty, fix rolled back

## [0.5.71] - 2026-02-21

### Changed
- Bump OpenClaw to 2026.2.19-2

## [0.5.70] - 2026-02-21

### Added
- Add new `gateway_bind_mode` values: `auto` and `tailnet`.

### Changed
- Update startup helper validation and CLI usage to support `auto|loopback|lan|tailnet` bind modes.
- Update add-on translations and docs for the expanded gateway bind mode options.

## [0.5.69] - 2026-02-18

### Changed
- Bump OpenClaw to 2026.2.17

## [0.5.68] - 2026-02-18

### Added
- New add-on option `force_ipv4_dns` to enable IPv4-first DNS ordering for Node network calls (`NODE_OPTIONS=--dns-result-order=ipv4first`), helping Telegram connectivity on IPv6-broken networks.

### Changed
- Added translations for `force_ipv4_dns` option.
- Updated docs with `force_ipv4_dns` configuration and Telegram network troubleshooting note.

## [0.5.67] - 2026-02-16

### Changed
- Bump OpenClaw to 2026.2.15

## [0.5.66] - 2026-02-14

### Changed
- Bump OpenClaw to 2026.2.13

## [0.5.65] - 2026-02-13

### Changed
- Bump OpenClaw to 2026.2.12

### Added
- Portuguese (Brazil) translation (`pt-BR.yaml`)

## [0.5.64] - 2026-02-12

### Changed
- Change nginx ingress port from 8099 to 48099 to avoid conflicts with NextCloud and other services
- Persist Homebrew and brew-installed packages across container rebuilds (symlink to `/config/.linuxbrew/`)

### Added
- SECURITY.md with risk documentation and disclaimer

### Improved
- Comprehensive DOCS.md overhaul (architecture, use cases, persistence, troubleshooting, FAQ)
- README.md rewritten as concise landing page with quick start guide
- New branding assets (icon.png, logo.png)
- Added Discord server link to README

## [0.5.63] - 2026-02-12

### Fixed
- Fix skills sync to use `HOME=/root` for reliable `npm root -g` resolution
- Built-in skills now correctly sync from image path instead of redirected npm prefix

## [0.5.62] - 2026-02-11

### Added
- Add `rsync` package to Docker image for reliable file syncing
- Persist OpenClaw built-in skills across container rebuilds (sync to `/config/.openclaw/skills/`)
- Persist user-installed npm/pnpm packages across rebuilds (redirect to `/config/.node_global/`)

### Fixed
- Improve nginx startup reliability with better port cleanup and PID file validation
- More specific `pkill` pattern for stale nginx cleanup
- Port availability verification before nginx start

## [0.5.61] - 2026-02-11

### Fixed
- Fix nginx port conflict on restart (PID file now written correctly)
- Stale nginx processes cleaned up automatically on startup

### Changed
- Updated Extended OpenAI Conversation integration docs

## [0.5.60] - 2026-02-11

### Changed
- Dockerfile improvements

## [0.5.59] - 2026-02-10

### Changed
- Bump OpenClaw to 2026.2.9

## [0.5.58] - 2026-02-10

### Added
- Configurable OpenAI-compatible Chat Completions endpoint (`enable_openai_api` option)
- Translations for new option (EN, BG, DE, ES, PL)

## [0.5.57] - 2026-02-09

### Added
- Shell improvements: fd, bat, ripgrep with aliases in `/etc/bash.bashrc`

## [0.5.56] - 2026-02-09

### Changed
- Make Homebrew installation optional for unsupported CPUs (graceful fallback)

## [0.5.55] - 2026-02-08

### Changed
- Bump OpenClaw to 2026.2.6-3

## [0.5.54] - 2026-02-08

### Added
- Install pnpm globally for OpenClaw skills support

## [0.5.53] - 2026-02-08

### Changed
- Bump OpenClaw to 2026.2.3-1

## [0.5.52] - 2026-02-08

### Added
- Configurable gateway mode (local/remote)

## [0.5.51] - 2026-02-08

### Added
- Configurable terminal port option with validation
- Improved terminal process cleanup

## [0.5.50] - 2026-02-08

### Added
- Persist OpenClaw directories (`OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACE_DIR`) across add-on updates

## [0.5.49] - 2026-02-08

### Added
- Nano text editor

## [0.5.48] - 2026-02-08

### Changed
- Chromium browser automation configuration guide in README

## [0.5.47] - 2026-02-07

### Added
- Chromium and ChromeDriver for website automation support

## [0.5.46] - 2026-02-07

### Changed
- Bump OpenClaw to 2026.2.2-3

## [0.5.45] - 2026-02-07

### Fixed
- Configure git safe.directory for Homebrew to prevent ownership warnings
- Force brew update after installation for latest package definitions

### Changed
- Bump OpenClaw to 2026.2.1

## [0.5.44] - 2026-02-07

### Fixed
- Replace `su` with `sudo` in brew-wrapper for better environment variable handling
- Preserve HOMEBREW_NO_AUTO_UPDATE, HOMEBREW_NO_ANALYTICS, HOME, and PATH when running as linuxbrew user

## [0.5.43] - 2026-02-07

### Added
- Brew wrapper script to allow root execution via linuxbrew user delegation
- PATH prioritizes wrapper over direct brew binary

## [0.5.42] - 2026-02-07

### Added
- Homebrew (Linuxbrew) installation during container build for OpenClaw skills support
- `build-essential` package for gcc/cc dependencies

## [0.5.41] - 2026-02-11

### Changed
- Update Dockerfile, config.yaml, and run.sh for enhancements
- Update icon and logo images for improved quality

## [0.5.40] - 2026-02-11

### Added
- Additional tools in Dockerfile

### Changed
- Improved nginx process management in run.sh

## [0.5.39] - 2026-02-10

### Fixed
- Fix OpenClaw installation command in Dockerfile

## [0.5.38] - 2026-02-10

### Changed
- Bump OpenClaw to 2026.2.9

## [0.5.37] - 2026-02-09

### Added
- OpenAI API integration for Home Assistant Assist pipeline
- Updated translations

## [0.5.36] - 2026-02-08

### Changed
- Documentation updates

## [0.5.35] - 2026-02-08

### Changed
- Update Dockerfile for Homebrew installation improvements

## [0.5.34] - 2026-02-08

### Added
- Install pnpm globally

### Changed
- Upgrade OpenClaw version to 2026.2.6-3

## [0.5.33] - 2026-02-06

### Changed
- Enhanced README with images and updated setup instructions

---

For the full commit history, see [GitHub commits](https://github.com/techartdev/OpenClawHomeAssistant-dev/commits/main).
