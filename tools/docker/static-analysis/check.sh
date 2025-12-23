#!/bin/bash

# ... (前面的路径定义保持不变)
scriptdir="$(cd "${0%/*}" && pwd)"
rootdir="${scriptdir%/*/*/*}"

. "${rootdir}/tools/functions.sh"

# 定义文件路径
XML_FILE="$rootdir/cppcheck_results.xml"
REPORT_DIR="$rootdir/cppcheck_report"
INCLUDES=()

# 自动查找头文件目录
while IFS='' read -r line; do INCLUDES+=("-I$line"); done < <(find -L "$rootdir/common" "$rootdir/framework" -type d -name include)

run_cppcheck() {
    echo "Running cppcheck and generating XML..."
    # 1. 修改输出为 XML 格式，输出到 $XML_FILE
    # 注意：cppcheck 的 XML 默认输出到 stderr (2)，所以用 2> 重定向
    cppcheck --xml --xml-version=2 \
             --template='{file}:{line}:{column}: {severity}: {message} [{id}]\n{code}' \
             --force \
             --error-exitcode=1 \
             --enable=warning,style,information,performance,portability \
             -i"$rootdir/framework/external" \
             -i"$rootdir/build" \
             --inline-suppr \
             --suppressions-list="$rootdir"/tools/docker/static-analysis/suppressions.txt \
             -rp="$rootdir" \
             -j"$(nproc)" \
             "${INCLUDES[@]}" \
             "$@" 2> "$XML_FILE"
    
    # 为了保持终端也有输出，我们可以简单处理一下 XML (可选)
    # 或者直接在下一步通过解析 XML 来输出彩色统计
}

generate_html_report() {
    if command -v cppcheck-htmlreport > /dev/null ; then
        echo "Generating HTML report in $REPORT_DIR..."
        mkdir -p "$REPORT_DIR"
        cppcheck-htmlreport --file="$XML_FILE" \
                           --report-dir="$REPORT_DIR" \
                           --source-dir="$rootdir" \
                           --title="Project Static Analysis Report"
        echo "Report generated: file://$REPORT_DIR/index.html"
    else
        echo "Warning: cppcheck-htmlreport not found, skipping HTML generation."
    fi
}

colorize_severity() {
    # ... (保持原来的颜色定义不变)
    local severity="$1" msg="$2"
    case "$severity" in
        error) printf '\033[1;31m%s\033[0m\n' "$msg" ;;
        warning) printf '\033[1;33m%s\033[0m\n' "$msg" ;;
        style) printf '\033[1;34m%s\033[0m\n' "$msg" ;;
        performance) printf '\033[1;35m%s\033[0m\n' "$msg" ;;
        portability) printf '\033[1;36m%s\033[0m\n' "$msg" ;;
        ok) printf '\033[1;90m%s\033[0m\n' "$msg" ;;
    esac
}

output_results() {
    local severities="portability performance style warning error"
    local status=0
    echo "---------------------------------------"
    echo "Summary of Issues:"
    for s in $severities; do
        # 针对 XML 格式重新编写统计逻辑
        # 在 XML 中，严重程度是以 severity="error" 这种形式存在的
        nb_issues=$(grep -c "severity=\"$s\"" "$XML_FILE")
        
        if [ "$nb_issues" -gt 0 ] ; then
            colorize_severity "$s" "[$s]: $nb_issues issues found."
            [[ "$s" == "error" || "$s" == "warning" ]] && status=1
        else
            colorize_severity "ok" "[$s]: 0 issues."
        fi
    done
    return $status
}

usage() {
    cat <<EOF
用法: $(basename "$0") [源码路径1] [源码路径2] ...

描述:
    该脚本封装了 cppcheck，用于扫描 C++ 源代码中的潜在错误。
    它会自动搜索 common 和 framework 目录下的 include 文件夹并加入包含路径。

功能:
    1. 在终端输出彩色分级统计摘要。
    2. 生成详细的 XML 结果文件。
    3. 自动生成交互式 HTML 报告。

输出产物:
    - 统计摘要: 直接显示在终端。
    - XML 报告:  \$rootdir/cppcheck_results.xml
    - HTML 报告: \$rootdir/cppcheck_report/index.html

退出状态码:
    0: 未发现 Error 或 Warning。
    1: 发现至少一个 Error 或 Warning，或者脚本运行出错。

示例:
    $(basename "$0") ../../../common ../../../framework
EOF
}

main() {

    # 如果没有参数，或者第一个参数是 -h 或 --help
    if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        usage
        exit 0
    fi

    if ! command -v cppcheck > /dev/null ; then
        echo "Error: cppcheck is required!"
        exit 1
    fi

    run_cppcheck "$@"
    generate_html_report
    output_results
    exit $?
}

main "$@"