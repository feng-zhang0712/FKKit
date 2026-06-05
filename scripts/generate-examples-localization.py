#!/usr/bin/env python3
"""Generate FKKitExamples app localization (11 BCP-47 languages)."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
sys.path.insert(0, str(SCRIPTS))

import importlib.util

_spec = importlib.util.spec_from_file_location(
    "generate_library_i18n",
    SCRIPTS / "generate-library-i18n.py",
)
_gli = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_gli)

LANGS = _gli.LANGS
escape = _gli.escape
write_strings = _gli.write_strings

from examples_i18n_menu import EXAMPLES_MENU  # noqa: E402

EXAMPLES_ROOT = ROOT / "Examples/FKKitExamples/FKKitExamples"
OUT_BASE = EXAMPLES_ROOT / "Resources"
EXTRACTED_JSON = ROOT / "scripts/examples_extracted_en.json"
TRANSLATIONS_DIR = SCRIPTS / "i18n_chunks"


def load_phrase_translations() -> dict[str, dict[str, str]]:
    merged: dict[str, dict[str, str]] = {}
    for path in sorted(TRANSLATIONS_DIR.glob("translations_*.json")):
        merged.update(json.loads(path.read_text(encoding="utf-8")))
    return merged


def parse_strings(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    return dict(re.findall(r'"([^"]+)"\s*=\s*"((?:\\.|[^"\\])*)";', path.read_text(encoding="utf-8")))


def load_i18n_demo(lang: str) -> dict[str, str]:
    return parse_strings(I18N_DEMO_SRC / f"{lang}.lproj/FKI18nDemo.strings")


def load_library_table(lang: str, module: str) -> dict[str, str]:
    rel = f"Sources/{module}/Resources/Localization/{lang}.lproj/Localizable.strings"
    return parse_strings(ROOT / rel)


def build_examples_table() -> dict[str, dict[str, str]]:
    extracted: dict[str, str] = {}
    if EXTRACTED_JSON.is_file():
        extracted = json.loads(EXTRACTED_JSON.read_text(encoding="utf-8"))

    phrase_translations = load_phrase_translations()
    table: dict[str, dict[str, str]] = {}

    def ensure(key: str, translations: dict[str, str]) -> None:
        table[key] = {lang: translations.get(lang, translations["en"]) for lang in LANGS}

    for key, translations in EXAMPLES_MENU.items():
        ensure(key, translations)

    for key, en in extracted.items():
        if key in table or key.startswith("fkcore.") or key.startswith("fkuikit."):
            continue
        if key.startswith("i18n.demo."):
            continue
        if en in phrase_translations:
            ensure(key, phrase_translations[en])
        else:
            ensure(key, {lang: en for lang in LANGS})

    for lang in LANGS:
        for key, value in load_i18n_demo(lang).items():
            if key not in table:
                table[key] = {l: load_i18n_demo(l).get(key, value) for l in LANGS}
            table[key][lang] = value

    return table


def merge_all() -> dict[str, dict[str, str]]:
    examples = build_examples_table()
    merged: dict[str, dict[str, str]] = {}

    for lang in LANGS:
        for key, value in load_library_table(lang, "FKCoreKit").items():
            merged.setdefault(key, {})[lang] = value
        for key, value in load_library_table(lang, "FKUIKit").items():
            merged.setdefault(key, {})[lang] = value

    for key, translations in examples.items():
        merged[key] = translations

    for key in merged:
        for lang in LANGS:
            merged[key].setdefault(lang, merged[key]["en"])

    return merged


def main() -> None:
    merged = merge_all()
    write_strings(OUT_BASE, "FKKitExamples", merged)


if __name__ == "__main__":
    main()
