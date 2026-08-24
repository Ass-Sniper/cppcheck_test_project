#!/usr/bin/env bash

sa_info() {
    printf 'static-analysis: %s\n' "$*"
}

sa_die() {
    printf 'static-analysis: error: %s\n' "$*" >&2
    exit 2
}

sa_require_command() {
    command -v "$1" >/dev/null 2>&1 || sa_die "required command not found: $1"
}

sa_abspath() {
    local path="$1"
    if [[ "$path" = /* ]]; then
        printf '%s\n' "$path"
    else
        printf '%s/%s\n' "$SA_PROJECT_ROOT" "$path"
    fi
}

sa_load_config() {
    local config="$1"

    ANALYSIS_SOURCE_DIRS=(src)
    ANALYSIS_EXCLUDE_DIRS=(build third_party generated)
    ANALYSIS_INCLUDE_PATHS_FILE=".static-analysis/include_paths.txt"
    ANALYSIS_SUPPRESSIONS_FILE=".static-analysis/suppressions.txt"
    ANALYSIS_LIBRARY_FILE=""
    ANALYSIS_COMPILE_DB=""
    ANALYSIS_PLATFORM="unix64"
    ANALYSIS_CPP_STANDARD="c++11"
    ANALYSIS_OUTPUT_DIR=".analysis"
    ANALYSIS_BUILD_COMMAND=()
    ANALYSIS_CPPCHECK_ARGS=()

    [[ -f "$config" ]] || sa_die "configuration file not found: $config"
    # Project configuration is versioned alongside the project and is trusted.
    # shellcheck disable=SC1090
    source "$config"

    SA_OUTPUT_DIR="$(sa_abspath "$ANALYSIS_OUTPUT_DIR")"
    case "$SA_OUTPUT_DIR" in
        "$SA_PROJECT_ROOT"/*) ;;
        *) sa_die "ANALYSIS_OUTPUT_DIR must stay below the project root" ;;
    esac
}

sa_collect_include_flags() {
    local include_file include_path line
    SA_INCLUDE_FLAGS=()
    include_file="$(sa_abspath "$ANALYSIS_INCLUDE_PATHS_FILE")"
    [[ -f "$include_file" ]] || return 0

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" || "$line" == \#* ]] && continue
        include_path="$(sa_abspath "$line")"
        [[ -d "$include_path" ]] && SA_INCLUDE_FLAGS+=("-I$include_path")
    done < "$include_file"
}

sa_collect_scan_paths() {
    local path
    SA_SCAN_PATHS=()
    if [[ "$#" -gt 0 ]]; then
        for path in "$@"; do
            if [[ "$path" = /* ]]; then
                SA_SCAN_PATHS+=("$path")
            else
                SA_SCAN_PATHS+=("$SA_PROJECT_ROOT/$path")
            fi
        done
    else
        for path in "${ANALYSIS_SOURCE_DIRS[@]}"; do
            path="$(sa_abspath "$path")"
            [[ -e "$path" ]] && SA_SCAN_PATHS+=("$path")
        done
    fi
    [[ "${#SA_SCAN_PATHS[@]}" -gt 0 ]] || sa_die "no scan paths were found"
}

sa_clean_outputs() {
    [[ -e "$SA_OUTPUT_DIR" ]] || return 0
    sa_info "removing analysis output: $SA_OUTPUT_DIR"
    rm -rf -- "$SA_OUTPUT_DIR"
}
