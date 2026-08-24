#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$SCRIPT_DIR/static_analysis.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.static-analysis" "$TMPDIR/src" "$TMPDIR/fake-bin"
printf 'int main(void) { return 0; }\n' > "$TMPDIR/src/main.c"
cat > "$TMPDIR/.static-analysis/config.sh" <<'EOF'
ANALYSIS_SOURCE_DIRS=(src)
ANALYSIS_EXCLUDE_DIRS=()
ANALYSIS_INCLUDE_PATHS_FILE=".static-analysis/include_paths.txt"
ANALYSIS_SUPPRESSIONS_FILE=".static-analysis/suppressions.txt"
ANALYSIS_OUTPUT_DIR=".analysis"
ANALYSIS_PLATFORM="unix64"
ANALYSIS_CPP_STANDARD="c11"
ANALYSIS_BUILD_COMMAND=(true)
ANALYSIS_CPPCHECK_ARGS=()
EOF
cat > "$TMPDIR/fake-bin/cppcheck" <<'EOF'
#!/usr/bin/env bash
printf '<results version="2"><errors/></results>\n' >&2
EOF
chmod +x "$TMPDIR/fake-bin/cppcheck"

PATH="$TMPDIR/fake-bin:$PATH" "$RUNNER" --root "$TMPDIR" cppcheck
[[ -s "$TMPDIR/.analysis/cppcheck/results.xml" ]]
PATH="$TMPDIR/fake-bin:$PATH" "$RUNNER" --root "$TMPDIR" clean
[[ ! -e "$TMPDIR/.analysis" ]]
printf 'static-analysis smoke test passed\n'
