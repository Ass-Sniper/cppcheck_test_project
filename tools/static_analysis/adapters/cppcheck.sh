#!/usr/bin/env bash

sa_cppcheck_count() {
    local severity="$1"
    grep -c "severity=\"$severity\"" "$SA_XML_FILE" 2>/dev/null || true
}

sa_run_cppcheck() {
    local path count status=0 jobs
    local -a arguments=() scan_args=()

    sa_require_command cppcheck
    mkdir -p "$SA_OUTPUT_DIR/cppcheck/cache" "$SA_OUTPUT_DIR/cppcheck/report"
    SA_XML_FILE="$SA_OUTPUT_DIR/cppcheck/results.xml"
    jobs="${ANALYSIS_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}"

    sa_collect_include_flags
    arguments=(--xml --xml-version=2 --enable=all --inline-suppr --force
        "--cppcheck-build-dir=$SA_OUTPUT_DIR/cppcheck/cache"
        "--platform=$ANALYSIS_PLATFORM" "--std=$ANALYSIS_CPP_STANDARD"
        "-rp=$SA_PROJECT_ROOT" "-j$jobs")
    arguments+=("${SA_INCLUDE_FLAGS[@]}" "${ANALYSIS_CPPCHECK_ARGS[@]}")

    path="$(sa_abspath "$ANALYSIS_SUPPRESSIONS_FILE")"
    [[ -f "$path" ]] && arguments+=("--suppressions-list=$path")
    if [[ -n "$ANALYSIS_LIBRARY_FILE" ]]; then
        path="$(sa_abspath "$ANALYSIS_LIBRARY_FILE")"
        [[ -f "$path" ]] && arguments+=("--library=$path")
    fi
    for path in "${ANALYSIS_EXCLUDE_DIRS[@]}"; do
        path="$(sa_abspath "$path")"
        [[ -e "$path" ]] && arguments+=("-i$path")
    done

    if [[ -n "$ANALYSIS_COMPILE_DB" ]]; then
        path="$(sa_abspath "$ANALYSIS_COMPILE_DB")"
        if [[ -f "$path" ]]; then
            arguments+=("--project=$path")
        else
            scan_args=("${SA_SCAN_PATHS[@]}")
        fi
    else
        scan_args=("${SA_SCAN_PATHS[@]}")
    fi

    sa_info "running cppcheck"
    if ! cppcheck "${arguments[@]}" "${scan_args[@]}" 2> "$SA_XML_FILE" >/dev/null; then
        sa_die "cppcheck execution failed; inspect $SA_XML_FILE"
    fi
    [[ -s "$SA_XML_FILE" ]] || sa_die "cppcheck produced an empty XML report"

    if command -v cppcheck-htmlreport >/dev/null 2>&1; then
        cppcheck-htmlreport --file="$SA_XML_FILE" \
            --report-dir="$SA_OUTPUT_DIR/cppcheck/report" \
            --source-dir="$SA_PROJECT_ROOT" --title="Static Analysis" >/dev/null
    fi

    printf '%s\n' '----------------------------------------'
    for path in error warning style performance portability; do
        count="$(sa_cppcheck_count "$path")"
        printf '[%s] %s issues\n' "$path" "$count"
        [[ "$path" == error || "$path" == warning ]] && [[ "$count" -gt 0 ]] && status=1
    done
    printf '%s\n' "XML report: $SA_XML_FILE"
    [[ -f "$SA_OUTPUT_DIR/cppcheck/report/index.html" ]] &&
        printf '%s\n' "HTML report: $SA_OUTPUT_DIR/cppcheck/report/index.html"
    return "$status"
}
