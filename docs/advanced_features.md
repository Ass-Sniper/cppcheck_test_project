# Advanced Static-Analysis Features

The reusable module keeps advanced behavior explicit in `.static-analysis/config.sh`, rather than encoding it in a project-specific launcher.

## Compile Databases

For CMake projects, configure with:

```bash
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

Then set:

```bash
ANALYSIS_COMPILE_DB="build/compile_commands.json"
```

Cppcheck uses the database when it exists. This is preferable to manually duplicating target-specific preprocessor definitions and include paths.

## Analyzer-Specific Arguments

Keep exceptional flags versioned with the project:

```bash
ANALYSIS_CPPCHECK_ARGS=(--inconclusive --check-level=exhaustive)
```

Use suppressions for reviewed false positives and keep the reason near the suppression. Do not use broad suppressions merely to make CI green.

## Cross Compilation

Set `ANALYSIS_PLATFORM` and the language standard to model the target's fundamental types:

```bash
ANALYSIS_PLATFORM="arm32-wchar_t2"
ANALYSIS_CPP_STANDARD="c++17"
```

When possible, prefer a target-generated compile database because it preserves compiler options and preprocessor definitions more accurately than a generic platform model.

## CI Policy

Run `cppcheck` for every merge request. Add `clang` where the build is reproducible in CI; `scan-build` executes the configured `ANALYSIS_BUILD_COMMAND` as an argument array, so shell operators are never reparsed accidentally.

Reports and Cppcheck cache remain under `.analysis/`. The `clean` command deletes that directory only, keeping build products under the build system's own ownership.
