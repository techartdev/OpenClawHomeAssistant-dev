#!/usr/bin/env python3
"""
OpenClaw config helper for Home Assistant add-on.
Safely reads/writes openclaw.json without corrupting it.
"""

import json
import os
import re
import sys
from pathlib import Path

CONFIG_PATH = Path(os.environ.get("OPENCLAW_CONFIG_PATH", "/config/.openclaw/openclaw.json"))

# IPv4 address validation regex
IPV4_REGEX = re.compile(r'^(\d{1,3}\.){3}\d{1,3}$')


def is_valid_ip(ip: str) -> bool:
    """Validate IPv4 address format."""
    if not ip:
        # Treat empty IP as "no override configured" and consider it acceptable.
        return True
    
    if not IPV4_REGEX.match(ip):
        return False
    
    # Check each octet is 0-255
    parts = ip.split('.')
    if len(parts) != 4:
        return False
    
    for part in parts:
        try:
            num = int(part)
            if num < 0 or num > 255:
                return False
        except ValueError:
            return False
    
    return True


def read_config():
    """Read and parse openclaw.json."""
    if not CONFIG_PATH.exists():
        return None
    try:
        return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, IOError) as e:
        print(f"ERROR: Failed to read config: {e}", file=sys.stderr)
        return None


def write_config(cfg):
    """Write config back to file with nice formatting."""
    try:
        CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
        CONFIG_PATH.write_text(json.dumps(cfg, indent=2) + "\n", encoding="utf-8")
        return True
    except IOError as e:
        print(f"ERROR: Failed to write config: {e}", file=sys.stderr)
        return False


def get_gateway_setting(key, default=None):
    """Get a gateway setting from config."""
    cfg = read_config()
    if cfg is None:
        return default
    return cfg.get("gateway", {}).get(key, default)


def set_gateway_setting(key, value):
    """Set a gateway setting, preserving other config."""
    cfg = read_config()
    if cfg is None:
        cfg = {}
    
    if "gateway" not in cfg:
        cfg["gateway"] = {}
    
    cfg["gateway"][key] = value
    return write_config(cfg)


def apply_lan_mode_settings(lan_mode: bool, bind_ip: str, port: int):
    """
    Apply LAN mode settings to OpenClaw config.
    
    Args:
        lan_mode: True for LAN access, False for loopback only
        bind_ip: IP address to bind to (e.g., "0.0.0.0" or "192.168.1.10")
        port: Port number to listen on
    """
    cfg = read_config()
    if cfg is None:
        cfg = {}
    
    if "gateway" not in cfg:
        cfg["gateway"] = {}
    
    gateway = cfg["gateway"]
    
    # Determine bind value
    if lan_mode:
        # Validate bind_ip format
        if bind_ip and not is_valid_ip(bind_ip):
            print(f"ERROR: Invalid bind_ip '{bind_ip}'. Must be a valid IPv4 address or '0.0.0.0'")
            return False
        desired_bind = bind_ip if bind_ip else "0.0.0.0"
    else:
        desired_bind = "loopback"
    
    current_bind = gateway.get("bind", "")
    current_port = gateway.get("port", 18789)
    
    changes = []
    
    if current_bind != desired_bind:
        gateway["bind"] = desired_bind
        changes.append(f"bind: {current_bind} -> {desired_bind}")
    
    # Only update port when LAN mode is enabled
    # When in loopback mode, port is typically managed by OpenClaw internally
    if lan_mode and current_port != port:
        gateway["port"] = port
        changes.append(f"port: {current_port} -> {port}")
    
    if changes:
        if write_config(cfg):
            print(f"INFO: Updated gateway settings: {', '.join(changes)}")
            return True
        else:
            print("ERROR: Failed to write config")
            return False
    else:
        print(f"INFO: Gateway settings already correct (bind={desired_bind}, port={port})")
        return True


def main():
    """CLI entry point for use by run.sh"""
    if len(sys.argv) < 2:
        print("Usage: oc_config_helper.py <command> [args...]")
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == "apply-lan-mode":
        if len(sys.argv) != 5:
            print("Usage: oc_config_helper.py apply-lan-mode <true|false> <bind_ip> <port>")
            sys.exit(1)
        lan_mode = sys.argv[2].lower() == "true"
        bind_ip = sys.argv[3]
        port = int(sys.argv[4])
        success = apply_lan_mode_settings(lan_mode, bind_ip, port)
        sys.exit(0 if success else 1)
    
    elif cmd == "get":
        if len(sys.argv) != 3:
            print("Usage: oc_config_helper.py get <key>")
            sys.exit(1)
        key = sys.argv[2]
        value = get_gateway_setting(key)
        if value is not None:
            print(value)
        sys.exit(0)
    
    elif cmd == "set":
        if len(sys.argv) != 4:
            print("Usage: oc_config_helper.py set <key> <value>")
            sys.exit(1)
        key = sys.argv[2]
        value = sys.argv[3]
        # Try to convert to int if it looks like a number
        try:
            value = int(value)
        except ValueError:
            pass
        success = set_gateway_setting(key, value)
        sys.exit(0 if success else 1)
    
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)


if __name__ == "__main__":
    main()
