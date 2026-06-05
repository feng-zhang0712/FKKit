#!/usr/bin/env python3
"""Compile partial translation modules into complete phrase tables."""

from __future__ import annotations

import ast
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHUNKS = ROOT / "scripts/i18n_chunks"
OUT = ROOT / "scripts/examples_i18n_phrases.json"
LANGS = ["en", "zh-Hans", "zh-Hant", "ja", "ko", "es", "fr", "de", "pt-BR", "ar", "ru"]


def load_t_from_py(path: Path) -> dict[str, dict[str, str]]:
    text = path.read_text(encoding="utf-8")
    table: dict[str, dict[str, str]] = {}

    if 'def t(' in text:
        ns: dict[str, object] = {}
        exec(compile(text, str(path), "exec"), ns)  # noqa: S102
        t_fn = ns["t"]
        dict_match = re.search(r"T\s*=\s*\{(.*)\}\s*(?:# fmt: on|$)", text, re.S)
        if not dict_match:
            return table
        body = dict_match.group(1)
        for match in re.finditer(r'"((?:\\.|[^"\\])*)"\s*:\s*t\((.*?)\)(?:,|\s*$)', body, re.S):
            en = ast.literal_eval(f'"{match.group(1)}"')
            args = [a.strip() for a in re.split(r',(?=(?:[^"]*"[^"]*")*[^"]*$)', match.group(2))]
            if len(args) != 11:
                continue
            table[en] = dict(zip(LANGS, [ast.literal_eval(a if a.startswith('"') else f'"{a}"') for a in args]))
        return table

    dict_match = re.search(r"T\s*=\s*\{(.*)\}\s*(?:# PART2_MARKER|# fmt: on|$)", text, re.S)
    if not dict_match:
        return table
    body = dict_match.group(1)
    for match in re.finditer(r'"((?:\\.|[^"\\])*)"\s*:\s*\{(.*?)\}', body, re.S):
        en = ast.literal_eval(f'"{match.group(1)}"')
        locales: dict[str, str] = {"en": en}
        for loc_match in re.finditer(r'"((?:\\.|[^"\\])*)"\s*:\s*"((?:\\.|[^"\\])*)"', match.group(2)):
            locales[loc_match.group(1)] = ast.literal_eval(f'"{loc_match.group(2)}"')
        for lang in LANGS:
            locales.setdefault(lang, en)
        table[en] = locales
    return table


def collect_partial() -> dict[str, dict[str, str]]:
    merged: dict[str, dict[str, str]] = {}
    for path in sorted(CHUNKS.glob("_*.py")):
        merged.update(load_t_from_py(path))
    return merged


def main() -> None:
    partial = collect_partial()
    all_en: set[str] = set()
    for i in range(4):
        chunk = json.loads((CHUNKS / f"chunk_{i}.json").read_text(encoding="utf-8"))
        all_en.update(chunk.keys())

    missing = sorted(all_en - partial.keys())
    print(f"Partial: {len(partial)} / {len(all_en)}; missing {len(missing)}")
    if missing:
        missing_path = CHUNKS / "missing_en.txt"
        missing_path.write_text("\n".join(missing) + "\n", encoding="utf-8")
        print(f"Wrote {missing_path.relative_to(ROOT)}")

    OUT.write_text(json.dumps(partial, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(partial)} phrases to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
