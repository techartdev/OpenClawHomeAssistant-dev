# Changelog

All notable changes to the OpenClaw Assistant Home Assistant Add-on will be documented in this file.

## [0.5.68] - 2026-02-18

### Added
- New add-on option `force_ipv4_dns` to enable IPv4-first DNS ordering for Node network calls (`NODE_OPTIONS=--dns-result-order=ipv4first`), helping Telegram connectivity on IPv6-broken networks.

### Changed
- Added translations for `force_ipv4_dns` option.

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
