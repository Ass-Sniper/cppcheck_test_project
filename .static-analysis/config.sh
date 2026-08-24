# Project-specific settings consumed by tools/static_analysis/static_analysis.sh.
ANALYSIS_SOURCE_DIRS=(src)
ANALYSIS_EXCLUDE_DIRS=(build .analysis third_party generated src/framework/external)
ANALYSIS_INCLUDE_PATHS_FILE=".static-analysis/include_paths.txt"
ANALYSIS_SUPPRESSIONS_FILE=".static-analysis/suppressions.txt"
ANALYSIS_LIBRARY_FILE=".static-analysis/embedded.cfg"
ANALYSIS_COMPILE_DB=""
ANALYSIS_PLATFORM="unix64"
ANALYSIS_CPP_STANDARD="c++11"
ANALYSIS_OUTPUT_DIR=".analysis"
ANALYSIS_BUILD_COMMAND=(make)

# Append project-specific Cppcheck flags here when needed.
ANALYSIS_CPPCHECK_ARGS=()
