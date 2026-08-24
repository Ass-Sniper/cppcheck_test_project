# C/C++ Static Analysis Module

This repository demonstrates a reusable, project-local static-analysis module for C and C++ code. It presents one CLI around Cppcheck and Clang Static Analyzer instead of scattering analyzer commands, paths, and report cleanup rules across scripts.

## Layout

```text
.
├── .static-analysis/                 # Versioned settings for this project
├── .analysis/                        # Generated reports and caches (ignored)
├── tools/
│   ├── static_analysis/              # Reusable module
│   │   ├── adapters/                 # Cppcheck and scan-build adapters
│   │   ├── lib/                      # Configuration and path helpers
│   │   └── tests/                    # Tool-independent smoke test
│   ├── cppcheck_launcher.sh          # Backward-compatible wrapper
│   └── install_hooks.sh              # Optional staged-file pre-commit hook
└── docs/reusable_static_analysis.md  # Reuse contract and configuration reference
```

## Usage

Install Cppcheck for the primary check and `scan-build` from Clang for the optional path-sensitive check.

```bash
tools/static_analysis/static_analysis.sh cppcheck
tools/static_analysis/static_analysis.sh clang
tools/static_analysis/static_analysis.sh clean
```

Cppcheck emits `.analysis/cppcheck/results.xml` and, when `cppcheck-htmlreport` is installed, an HTML report under `.analysis/cppcheck/report/`. A warning or error produces a non-zero exit status suitable for CI. `clean` removes only `.analysis/`; it never invokes the project's build clean target.

For projects with accurate CMake compile commands, set `ANALYSIS_COMPILE_DB` in `.static-analysis/config.sh` to `build/compile_commands.json`. The compile database then supplies per-file defines, include paths and language options. Without it, the configured source roots and include-path file are used.

The legacy command remains available for existing CI jobs:

```bash
tools/cppcheck_launcher.sh [src-or-file ...]
tools/cppcheck_launcher.sh clang
tools/cppcheck_launcher.sh clean
```

## Reuse and Verification

See [the reusable module guide](docs/reusable_static_analysis.md) for the integration contract and configuration example. Verify the module plumbing without installing analyzers:

```bash
tools/static_analysis/tests/smoke_test.sh
```

Install an optional pre-commit hook with `tools/install_hooks.sh`. It scans staged C/C++ files only; set `STATIC_ANALYSIS_PRE_COMMIT_CLANG=1` to include `scan-build`.
