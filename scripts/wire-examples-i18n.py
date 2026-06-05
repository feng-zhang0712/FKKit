#!/usr/bin/env python3
"""Replace hub/scenario title/subtitle literals with FKExamplesI18n lookups."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXAMPLES = ROOT / "Examples/FKKitExamples/FKKitExamples"
CATALOG = ROOT / "scripts/examples_extracted_en.json"

TITLE_SUBTITLE = re.compile(
    r"(?P<prefix>\b(?:title|subtitle)\s*:\s*)"
    r'(?P<value>FKExamplesI18n\.string\("[^"]+"\)|"(?:\\.|[^"\\])*")'
)


def ensure_import(source: str) -> str:
    if "import FKCoreKit" in source:
        return source
    if "import UIKit" in source:
        return source.replace("import UIKit", "import UIKit\nimport FKCoreKit", 1)
    if "import SwiftUI" in source:
        return source.replace("import SwiftUI", "import SwiftUI\nimport FKCoreKit", 1)
    return "import FKCoreKit\n" + source


def build_lookup(catalog: dict[str, str]) -> tuple[dict[str, list[str]], dict[str, str]]:
    all_keys: dict[str, list[str]] = {}
    for key, value in catalog.items():
        all_keys.setdefault(value, []).append(key)
    scenario = {v: k for k, v in catalog.items() if k.startswith("examples.scenario.")}
    return all_keys, scenario


def pick_hub_key(keys: list[str], hub_id: str) -> str:
    hub_keys = [k for k in keys if f".{hub_id}." in k.lower() or f".{hub_id.replace('viewcontroller', '')}." in k.lower()]
    if hub_keys:
        return sorted(hub_keys)[0]
    return sorted(keys)[0]


def wire_file(path: Path, all_keys: dict[str, list[str]], scenario: dict[str, str], hub_id: str | None) -> bool:
    text = path.read_text(encoding="utf-8")
    changed = False

    def repl(match: re.Match[str]) -> str:
        nonlocal changed
        value = match.group("value")
        if value.startswith("FKExamplesI18n"):
            return match.group(0)
        literal = value[1:-1]
        if hub_id:
            keys = all_keys.get(literal, [])
            if not keys:
                return match.group(0)
            key = pick_hub_key(keys, hub_id)
        else:
            key = scenario.get(literal)
            if not key:
                return match.group(0)
        changed = True
        return f'{match.group("prefix")}FKExamplesI18n.string("{key}")'

    updated = TITLE_SUBTITLE.sub(repl, text)
    if not changed:
        return False
    path.write_text(ensure_import(updated), encoding="utf-8")
    return True


def main() -> None:
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    all_keys, scenario = build_lookup(catalog)
    wired = 0

    for path in sorted(EXAMPLES.rglob("*ExamplesHubViewController.swift")):
        if wire_file(path, all_keys, scenario, path.stem.lower()):
            wired += 1
            print(f"Hub {path.relative_to(ROOT)}")

    for path in sorted(EXAMPLES.rglob("*.swift")):
        if "ExamplesHubViewController" in path.name or "ExampleMenuViewController" in path.name:
            continue
        if "/Examples/" not in path.as_posix():
            continue
        if wire_file(path, all_keys, scenario, None):
            wired += 1
            print(f"Scenario {path.relative_to(ROOT)}")

    print(f"Updated {wired} files")


if __name__ == "__main__":
    main()
