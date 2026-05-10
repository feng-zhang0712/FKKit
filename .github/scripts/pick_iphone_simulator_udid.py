#!/usr/bin/env python3
"""Print the UDID of an iPhone iOS Simulator that the *active* Xcode can use for xcodebuild test.

Uses `xcodebuild -showdestinations` so the choice matches the selected Xcode (e.g. 16.2 on GitHub
Hosted runners). `simctl list` alone can return newer iOS runtimes that older Xcode cannot target,
which yields xcodebuild exit code 70.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys


def main() -> None:
    root = os.environ.get("GITHUB_WORKSPACE") or os.getcwd()
    proc = subprocess.run(
        ["xcodebuild", "-scheme", "FKKit-Package", "-showdestinations"],
        cwd=root,
        text=True,
        capture_output=True,
        check=False,
    )
    combined = (proc.stdout or "") + (proc.stderr or "")
    if proc.returncode != 0:
        sys.stderr.write(combined)
        raise SystemExit(proc.returncode)

    start = combined.find("Available destinations")
    if start < 0:
        sys.stderr.write("No 'Available destinations' section in xcodebuild output.\n")
        sys.stderr.write(combined[:8000])
        raise SystemExit(1)

    rest = combined[start:]
    inel = rest.find("Ineligible destinations")
    block = rest if inel < 0 else rest[:inel]

    for line in block.splitlines():
        line = line.strip()
        if "platform:iOS Simulator" not in line:
            continue
        if "placeholder" in line:
            continue
        if "iPhone" not in line:
            continue
        m = re.search(r"id:([0-9A-Fa-f-]{36})", line)
        if not m:
            continue
        print(m.group(1))
        return

    sys.stderr.write(
        "No eligible iPhone iOS Simulator in xcodebuild -showdestinations "
        "(install a matching simulator runtime for this Xcode, or bump xcode-version).\n"
    )
    sys.stderr.write(block[:6000])
    raise SystemExit(1)


if __name__ == "__main__":
    main()
