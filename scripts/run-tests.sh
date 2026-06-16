#!/usr/bin/env bash
# Run FKKit SPM unit tests on iOS Simulator (same flags as CI).
set -eo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="${DERIVED_DATA_PATH:-/tmp/DerivedData-FKKit}"
ENABLE_COVERAGE="${ENABLE_CODE_COVERAGE:-NO}"

if [[ -n "${SIMULATOR_UDID:-}" ]]; then
  DESTINATION="platform=iOS Simulator,id=${SIMULATOR_UDID}"
elif [[ -n "${SIMULATOR_NAME:-}" ]]; then
  DESTINATION="platform=iOS Simulator,name=${SIMULATOR_NAME}"
else
  UDID="$(python3 "${ROOT}/.github/scripts/pick_iphone_simulator_udid.py")"
  DESTINATION="platform=iOS Simulator,id=${UDID}"
fi

echo "FKKit test run"
echo "  destination: ${DESTINATION}"
echo "  derivedData: ${DERIVED}"
echo "  coverage:    ${ENABLE_COVERAGE}"

xcodebuild \
  -scheme FKKit-Package \
  -destination "${DESTINATION}" \
  -derivedDataPath "${DERIVED}" \
  CODE_SIGNING_ALLOWED=NO \
  SWIFT_STRICT_CONCURRENCY=complete \
  -enableCodeCoverage "${ENABLE_COVERAGE}" \
  test
