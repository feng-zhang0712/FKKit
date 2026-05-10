#!/usr/bin/env python3
"""Print the UDID of an available iPhone iOS Simulator (for xcodebuild -destination)."""

from __future__ import annotations

import json
import subprocess
import sys


def main() -> None:
    raw = subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "available", "-j"],
        text=True,
    )
    data = json.loads(raw)
    # Prefer the lowest iOS runtime that still has an available iPhone. Newer GitHub images list iOS 26
    # before 18.x; picking newest first breaks when the job uses an older Xcode (e.g. 16.2).
    for runtime in sorted(data.get("devices", {})):
        if "iOS" not in runtime:
            continue
        for dev in data["devices"][runtime]:
            if not dev.get("isAvailable", False):
                continue
            if "iPhone" not in dev.get("deviceTypeIdentifier", ""):
                continue
            print(dev["udid"])
            return
    sys.stderr.write("No available iPhone simulator found.\n")
    raise SystemExit(1)


if __name__ == "__main__":
    main()
