#!/usr/bin/env bash
# Compatibility entry point. New integrations should invoke static_analysis.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$SCRIPT_DIR/static_analysis/static_analysis.sh"

case "${1:-}" in
    --no-progress)
        shift
        ;;
    init)
        exec "$RUNNER" --root "$(cd "$SCRIPT_DIR/.." && pwd)" init
        ;;
    clean)
        exec "$RUNNER" --root "$(cd "$SCRIPT_DIR/.." && pwd)" clean
        ;;
    clang)
        shift
        exec "$RUNNER" --root "$(cd "$SCRIPT_DIR/.." && pwd)" clang "$@"
        ;;
esac

exec "$RUNNER" --root "$(cd "$SCRIPT_DIR/.." && pwd)" cppcheck "$@"
