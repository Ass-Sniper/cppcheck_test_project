#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    printf 'install_hooks: run this script from a Git worktree.\n' >&2
    exit 2
}
HOOK_DIR="$PROJECT_ROOT/.git/hooks"
HOOK_FILE="$HOOK_DIR/pre-commit"
RUNNER="$PROJECT_ROOT/tools/static_analysis/static_analysis.sh"

[[ -x "$RUNNER" ]] || {
    printf 'install_hooks: analysis runner is not executable: %s\n' "$RUNNER" >&2
    exit 2
}
mkdir -p "$HOOK_DIR"

if [[ -f "$HOOK_FILE" ]] && ! grep -q 'managed by tools/install_hooks.sh' "$HOOK_FILE"; then
    backup="$HOOK_FILE.before-static-analysis.$(date +%Y%m%d%H%M%S)"
    mv "$HOOK_FILE" "$backup"
    printf 'install_hooks: backed up existing hook to %s\n' "$backup"
fi

cat > "$HOOK_FILE" <<'EOF'
#!/usr/bin/env bash
# managed by tools/install_hooks.sh
set -euo pipefail

project_root="$(git rev-parse --show-toplevel)"
mapfile -t changed_files < <(git diff --cached --name-only --diff-filter=ACMR -- \
    '*.c' '*.cc' '*.cpp' '*.cxx' '*.h' '*.hh' '*.hpp')

[[ "${#changed_files[@]}" -gt 0 ]] || exit 0
"$project_root/tools/static_analysis/static_analysis.sh" --root "$project_root" cppcheck "${changed_files[@]}"

if [[ "${STATIC_ANALYSIS_PRE_COMMIT_CLANG:-0}" == 1 ]]; then
    "$project_root/tools/static_analysis/static_analysis.sh" --root "$project_root" clang
fi
EOF
chmod +x "$HOOK_FILE"
printf 'install_hooks: installed %s\n' "$HOOK_FILE"
