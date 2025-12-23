#!/bin/bash

# ============================================================
# Cppcheck 高级集成脚本 (支持 2025 最新版本特性)
# ============================================================

# 配置路径
rootdir=$(cd "$(dirname "$0")/../../../"; pwd)
REPORT_DIR="$rootdir/cppcheck_report"
XML_FILE="$rootdir/cppcheck_results.xml"
BUILD_DIR="$rootdir/.cppcheck_cache" # 增量分析缓存目录

SRCDIR=()
SRCDIR+=("$rootdir/common")
SRCDIR+=("$rootdir/framework")

# 获取版本号 (例如: 2.14)
VER=$(cppcheck --version | awk '{print $2}' | sed 's/dev//g')
echo ">>> 检测到 Cppcheck 版本: $VER"

# 准备缓存目录
mkdir -p "$BUILD_DIR"

# 基础参数
ARGS=(
    "--xml"
    "--xml-version=2"
    "--enable=all"
    "--inline-suppr"
    "--suppress=missingIncludeSystem" # 忽略系统头文件缺失警告
    "--force"
)

# ------------------------------------------------------------
# 动态特性适配逻辑
# ------------------------------------------------------------

# 1. 适配 C++ 标准
if [[ $(echo "$VER >= 2.10" | bc -l) -eq 1 ]]; then
    ARGS+=("--std=c++20")
else
    ARGS+=("--std=c++11")
fi

# 2. 适配深度检查级别 (2.13+ 支持 --check-level)
if [[ $(echo "$VER >= 2.13" | bc -l) -eq 1 ]]; then
    echo ">>> 开启高级检查级别: exhaustive"
    ARGS+=("--check-level=exhaustive")
fi

# 3. 开启增量分析 (2.7+ 支持 --cppcheck-build-dir)
if [[ $(echo "$VER >= 2.7" | bc -l) -eq 1 ]]; then
    ARGS+=("--cppcheck-build-dir=$BUILD_DIR")
fi

# ------------------------------------------------------------
# 执行分析
# ------------------------------------------------------------
echo ">>> 正在执行代码分析..."

cppcheck "${ARGS[@]}" \
         -j"$(nproc)" \
         "$SRCDIR" \
         2> "$XML_FILE"

# ------------------------------------------------------------
# 生成 HTML 报告
# ------------------------------------------------------------
if command -v cppcheck-htmlreport > /dev/null; then
    echo ">>> 正在转换 HTML 报告..."
    cppcheck-htmlreport --file="$XML_FILE" \
                       --report-dir="$REPORT_DIR" \
                       --source-dir="$rootdir" \
                       --title="Advanced Analysis Report (v$VER)"
    echo ">>> 报告已生成: $REPORT_DIR/index.html"
else
    echo ">>> [提示] 未安装 cppcheck-htmlreport，仅生成 XML。"
fi