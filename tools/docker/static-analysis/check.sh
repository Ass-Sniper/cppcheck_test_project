#!/usr/bin/env bash
# Docker/CI compatibility entry point; all behavior lives in static_analysis.sh.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
exec "$PROJECT_ROOT/tools/static_analysis/static_analysis.sh" --root "$PROJECT_ROOT" cppcheck "$@"
