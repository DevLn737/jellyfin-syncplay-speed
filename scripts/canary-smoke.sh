#!/usr/bin/env bash
set -euo pipefail

base_url="${CANARY_BASE_URL:-http://127.0.0.1:18096}"

curl --fail --silent --show-error "${base_url}/health"
curl --fail --silent --show-error --output /dev/null "${base_url}/web/index.html"

echo "Canary HTTP health and Web client checks passed: ${base_url}"
