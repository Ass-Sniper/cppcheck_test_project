#!/usr/bin/env bash

sa_run_scan_build() {
    local -a command_to_run=()

    sa_require_command scan-build
    mkdir -p "$SA_OUTPUT_DIR/scan-build"
    if [[ "${#ANALYSIS_BUILD_COMMAND[@]}" -gt 0 ]]; then
        command_to_run=("${ANALYSIS_BUILD_COMMAND[@]}")
    elif [[ -f "$SA_PROJECT_ROOT/Makefile" ]]; then
        command_to_run=(make)
    else
        sa_die "set ANALYSIS_BUILD_COMMAND for scan-build"
    fi

    sa_info "running scan-build: ${command_to_run[*]}"
    (
        cd "$SA_PROJECT_ROOT"
        scan-build --status-bugs -o "$SA_OUTPUT_DIR/scan-build" "${command_to_run[@]}"
    )
}
