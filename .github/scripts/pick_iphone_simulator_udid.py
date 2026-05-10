#!/usr/bin/env python3
"""Print a UDID for an iOS Simulator that the *active* Xcode can use with `xcodebuild test`.

Uses `xcodebuild -showdestinations` (not raw `simctl list`) so the UDID matches the selected
Xcode. Prefer iPhone, then iPad, then any non-placeholder iOS Simulator.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys


def _score_line(line: str) -> int | None:
    """Lower is better. None = skip."""
    if "platform:iOS Simulator" not in line or "placeholder" in line:
        return None
    m = re.search(r"id:([0-9A-Fa-f-]{36})", line)
    if not m:
        return None
    if "iPhone" in line:
        return 0
    if "iPad" in line:
        return 1
    return 2


def _pick_from_text(text: str) -> str | None:
    start = text.find("Available destinations")
    if start < 0:
        return None
    rest = text[start:]
    inel = rest.find("Ineligible destinations")
    block = rest if inel < 0 else rest[:inel]

    best: tuple[int, str] | None = None
    for line in block.splitlines():
        s = _score_line(line)
        if s is None:
            continue
        m = re.search(r"id:([0-9A-Fa-f-]{36})", line)
        if not m:
            continue
        udid = m.group(1)
        cand = (s, udid)
        if best is None or cand[0] < best[0]:
            best = cand
    return best[1] if best else None


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

    udid = _pick_from_text(combined)
    if udid:
        print(udid)
        return

    # Fallback: older xcodebuild layouts or localized headers — scan full output.
    best: tuple[int, str] | None = None
    for line in combined.splitlines():
        s = _score_line(line)
        if s is None:
            continue
        m = re.search(r"id:([0-9A-Fa-f-]{36})", line)
        if not m:
            continue
        cand = (s, m.group(1))
        if best is None or cand[0] < best[0]:
            best = cand

    if best:
        print(best[1])
        return

    sys.stderr.write(
        "No concrete iOS Simulator (non-placeholder) in xcodebuild -showdestinations.\n"
        "For Swift packages this often happens before the graph is resolved (IDE: supported platforms empty).\n"
        "Run: xcodebuild -scheme FKKit-Package -resolvePackageDependencies … first, or use an explicit\n"
        "-destination 'platform=iOS Simulator,name=…,OS=…' as in .github/workflows/ci.yml.\n"
    )
    sys.stderr.write(combined[:8000])
    raise SystemExit(1)


if __name__ == "__main__":
    main()
