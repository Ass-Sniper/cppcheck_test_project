#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/adapters/cppcheck.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/adapters/scan_build.sh"

usage() {
    cat <<'EOF'
Usage: static_analysis.sh [--root DIR] [--config FILE] <command> [paths...]

Commands:
  cppcheck [paths...]  Run Cppcheck and generate XML/HTML reports.
  clang                Run scan-build using ANALYSIS_BUILD_COMMAND.
  clean                Remove only .analysis output; never runs make clean.
  init                 Create a project configuration template when absent.
EOF
}

SA_PROJECT_ROOT=""
SA_CONFIG=""
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --root) SA_PROJECT_ROOT="$2"; shift 2 ;;
        --config) SA_CONFIG="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) break ;;
    esac
done

if [[ -z "$SA_PROJECT_ROOT" ]]; then
    if ! SA_PROJECT_ROOT="$(git -C "$SCRIPT_DIR/../.." rev-parse --show-toplevel 2>/dev/null)"; then
        SA_PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    fi
fi
SA_PROJECT_ROOT="$(cd "$SA_PROJECT_ROOT" && pwd)"
SA_CONFIG="${SA_CONFIG:-$SA_PROJECT_ROOT/.static-analysis/config.sh}"
command_name="${1:-cppcheck}"
[[ "$#" -gt 0 ]] && shift

if [[ "$command_name" == init ]]; then
    mkdir -p "$SA_PROJECT_ROOT/.static-analysis"
    if [[ ! -f "$SA_CONFIG" ]]; then
        cat > "$SA_CONFIG" <<'EOF'
ANALYSIS_SOURCE_DIRS=(src)
ANALYSIS_EXCLUDE_DIRS=(build third_party generated)
ANALYSIS_INCLUDE_PATHS_FILE=".static-analysis/include_paths.txt"
ANALYSIS_SUPPRESSIONS_FILE=".static-analysis/suppressions.txt"
ANALYSIS_PLATFORM="unix64"
ANALYSIS_CPP_STANDARD="c++11"
EOF
        sa_info "created $SA_CONFIG"
    fi
    exit 0
fi

sa_load_config "$SA_CONFIG"
case "$command_name" in
    cppcheck) sa_collect_scan_paths "$@"; sa_run_cppcheck ;;
    clang) sa_run_scan_build ;;
    clean) sa_clean_outputs ;;
    *) usage; exit 2 ;;
esac
