#!/usr/bin/env bash
# Run FKKit tests with code coverage and print a per-target summary (local trend only; CI does not gate on coverage).
set -eo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="${DERIVED_DATA_PATH:-/tmp/DerivedData-FKKit}"

export DERIVED_DATA_PATH="${DERIVED}"
export ENABLE_CODE_COVERAGE=YES

bash "${ROOT}/scripts/run-tests.sh"

XCRESULT="$(find "${DERIVED}/Logs/Test" -name '*.xcresult' -type d -print0 2>/dev/null | xargs -0 ls -td 2>/dev/null | head -1)"
if [[ -z "${XCRESULT}" ]]; then
  echo "No .xcresult bundle found under ${DERIVED}/Logs/Test" >&2
  exit 1
fi

echo ""
echo "=== Code coverage (targets) ==="
echo "Bundle: ${XCRESULT}"
xcrun xccov view --report --only-targets "${XCRESULT}"

echo ""
echo "Full report: xcrun xccov view --report '${XCRESULT}'"
