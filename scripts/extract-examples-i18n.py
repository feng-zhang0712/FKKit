#!/usr/bin/env python3
"""Extract user-facing English strings from FKKitExamples into a key catalog."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXAMPLES = ROOT / "Examples/FKKitExamples/FKKitExamples"
OUT = ROOT / "scripts/examples_extracted_en.json"

SKIP_PREFIXES = (
    "http://",
    "https://",
    "file://",
    "com.",
    "org.",
    "sf.",
    "SFSymbol",
    "#",
    "0x",
    "0123456789",
)

LITERAL_PATTERNS = [
    re.compile(r'\b(?:title|subtitle|message|placeholder|accessibilityLabel|accessibilityHint)\s*:\s*"((?:\\.|[^"\\])*)"'),
    re.compile(r'\.setTitle\(\s*"((?:\\.|[^"\\])*)"'),
    re.compile(r'UIButton\.(?:configuration\(\)|Configuration\.filled\(\))\s*\n?\s*.*?title:\s*"((?:\\.|[^"\\])*)"', re.S),
    re.compile(r'(?:text|prompt|label|header|footer|description|name|caption)\s*:\s*"((?:\\.|[^"\\])*)"', re.I),
    re.compile(r'UIAlertAction\(title:\s*"((?:\\.|[^"\\])*)"'),
    re.compile(r'addAction\(UIAlertAction\(title:\s*"((?:\\.|[^"\\])*)"'),
]


def slug(text: str, limit: int = 36) -> str:
    base = re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")
    return base[:limit] or "text"


def hash_suffix(*parts: str) -> str:
    return hashlib.sha1("|".join(parts).encode()).hexdigest()[:10]


def should_skip(value: str) -> bool:
    if not value or len(value.strip()) < 2:
        return True
    if value.startswith(SKIP_PREFIXES):
        return True
    if re.fullmatch(r"[\d._\-/\\]+", value):
        return True
    if re.fullmatch(r"[A-Za-z0-9_]+", value) and value.isupper():
        return True
    return False


def scenario_key(rel_path: Path, field: str, text: str) -> str:
    rel = rel_path.as_posix().lower()
    rel = rel.replace("examples/fkkitexamples/fkkitexamples/examples/", "examples_")
    rel = rel.replace("/", "_").replace(".swift", "")
    return f"examples.scenario.{rel}.{slug(text)}.{hash_suffix(rel, field, text)}"


def hub_key(vc_stem: str, index: int, field: str) -> str:
    return f"examples.hub.{vc_stem.lower()}.{index}.{field}"


def extract_menu_from_swift(catalog: dict[str, str]) -> None:
    import sys

    sys.path.insert(0, str(ROOT / "scripts"))
    from examples_i18n_menu import EXAMPLES_MENU  # noqa: WPS433

    catalog.update({k: v["en"] for k, v in EXAMPLES_MENU.items()})


def extract_i18n_demo(catalog: dict[str, str]) -> None:
    for path in EXAMPLES.rglob("FKI18nDemo.strings"):
        for key, value in re.findall(
            r'"([^"]+)"\s*=\s*"((?:\\.|[^"\\])*)";',
            path.read_text(encoding="utf-8"),
        ):
            catalog[key] = value


def extract_from_hub(path: Path, catalog: dict[str, str]) -> None:
    text = path.read_text(encoding="utf-8")
    idx = 0
    for pattern in LITERAL_PATTERNS[:1]:
        for match in pattern.finditer(text):
            field = "subtitle" if "subtitle" in match.string[max(0, match.start() - 20):match.start()] else "title"
            if "subtitle" in match.string[match.start():match.end() + 1]:
                field = "subtitle"
            elif "title" in match.string[match.start():match.end() + 1]:
                field = "title"
            value = match.group(1)
            if should_skip(value):
                continue
            key = hub_key(path.stem, idx if field == "subtitle" else idx, field)
            if field == "title":
                catalog.setdefault(hub_key(path.stem, idx, "title"), value)
            else:
                catalog[hub_key(path.stem, idx, "subtitle")] = value
                idx += 1


def extract_literals(path: Path, catalog: dict[str, str]) -> None:
    rel = path.relative_to(EXAMPLES)
    text = path.read_text(encoding="utf-8")
    if path.name.endswith("ExamplesHubViewController.swift"):
        extract_from_hub(path, catalog)
        return
    if "ExampleMenuViewController" in path.name:
        return

    seen: set[str] = set()
    for pattern in LITERAL_PATTERNS:
        for match in pattern.finditer(text):
            value = match.group(1)
            if should_skip(value) or value in seen:
                continue
            seen.add(value)
            field = "text"
            key = scenario_key(rel, field, value)
            while key in catalog and catalog[key] != value:
                key = scenario_key(rel, field + "_dup", value + key[-4:])
            catalog[key] = value


def main() -> None:
    catalog: dict[str, str] = {}
    extract_menu_from_swift(catalog)
    extract_i18n_demo(catalog)

    for path in sorted(EXAMPLES.rglob("*.swift")):
        if "Tests" in path.parts:
            continue
        extract_literals(path, catalog)

    OUT.write_text(json.dumps(dict(sorted(catalog.items())), indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {len(catalog)} keys to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
