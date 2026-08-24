# Reusable Static Analysis Module

`tools/static_analysis/` is a small Bash module for projects that need a consistent C/C++ static-analysis entry point without hard-coding their directory layout.

## Contract

- `tools/static_analysis/static_analysis.sh` owns command parsing and report lifecycle.
- `tools/static_analysis/lib/common.sh` owns configuration loading and path normalization.
- `tools/static_analysis/adapters/` isolates analyzer-specific behavior.
- `.static-analysis/config.sh` is the only project-specific configuration file.
- Generated files live below `.analysis/`; `clean` removes only that directory.

## Project Configuration

The configuration is Bash so lists remain shell-safe arrays:

```bash
ANALYSIS_SOURCE_DIRS=(src lib)
ANALYSIS_EXCLUDE_DIRS=(build generated third_party)
ANALYSIS_INCLUDE_PATHS_FILE=".static-analysis/include_paths.txt"
ANALYSIS_SUPPRESSIONS_FILE=".static-analysis/suppressions.txt"
ANALYSIS_COMPILE_DB="build/compile_commands.json"
ANALYSIS_PLATFORM="unix64"
ANALYSIS_CPP_STANDARD="c++17"
ANALYSIS_BUILD_COMMAND=(cmake --build build)
```

When `ANALYSIS_COMPILE_DB` points to an existing `compile_commands.json`, Cppcheck uses it as the source of truth for defines, include paths, language mode and individual translation-unit options. Otherwise it scans `ANALYSIS_SOURCE_DIRS` with the configured include and suppression files.

## Integration

Copy `tools/static_analysis/` into a project, add `.static-analysis/config.sh`, and run:

```bash
tools/static_analysis/static_analysis.sh cppcheck
tools/static_analysis/static_analysis.sh clang
tools/static_analysis/static_analysis.sh clean
```

`tools/install_hooks.sh` installs an opt-in pre-commit hook. It analyzes staged C/C++ files only. Export `STATIC_ANALYSIS_PRE_COMMIT_CLANG=1` when the hook should also run the project's configured `scan-build` build.

Run `tools/static_analysis/tests/smoke_test.sh` after modifying the module. The test uses a temporary project and fake Cppcheck binary, so it verifies command, configuration and output-path behavior without depending on a local analyzer installation.
