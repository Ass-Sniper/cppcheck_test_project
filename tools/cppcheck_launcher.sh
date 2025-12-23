#!/bin/bash

# ============================================================
# 通用 Cppcheck 启动器 (增强集成版)
# ============================================================

# ------------------------------------------------------------
# 0. 路径自动定位 (确保在任何目录下执行都能找到根目录)
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 假设脚本位于 tools/ 目录下，向上回退一级即为项目根目录
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
    cat <<EOF
用法: $(basename "$0") [命令|路径1] [路径2] ... [选项]

核心命令:
  init              在 cppcheck/ 目录下初始化屏蔽规则和嵌入式定义模板
  clean             清理缓存目录 (.cppcheck_cache)、报告和 XML
  [路径]            指定扫描目录 (例如: ./src)。支持多个路径。

选项:
  --no-progress     禁用动态进度条 (非交互式环境/CI 建议使用)
  -h, --help        显示帮助信息

EOF
    exit 1
}

# ------------------------------------------------------------
# 1. 环境与参数预处理
# ------------------------------------------------------------
[[ "$1" == "--help" || "$1" == "-h" || $# -eq 0 ]] && usage

SHOW_PROGRESS=true
SCAN_PATHS=()
EXTRA_ARGS=()
MODE=""

# 解析参数
for arg in "$@"; do
    case "$arg" in
        init|clean) MODE="$arg" ;;
        --no-progress) SHOW_PROGRESS=false ;;
        -*) EXTRA_ARGS+=("$arg") ;;
        *) 
            if [ -d "$arg" ]; then
                SCAN_PATHS+=("$(cd "$arg" && pwd)")
            else
                EXTRA_ARGS+=("$arg")
            fi
            ;;
    esac
done

# 配置与输出路径
CONF_DIR="$PROJECT_ROOT/cppcheck"
SUPPRESS_FILE="$CONF_DIR/suppressions.txt"
EMBEDDED_CFG="$CONF_DIR/embedded.cfg"
BUILD_DIR="$PROJECT_ROOT/cppcheck_cache"
REPORT_DIR="$PROJECT_ROOT/cppcheck_report"
XML_FILE="$PROJECT_ROOT/cppcheck_results.xml"

# ------------------------------------------------------------
# 2. 指令处理 (init / clean)
# ------------------------------------------------------------
if [[ "$MODE" == "clean" ]]; then
    echo ">>> 正在清理分析痕迹..."
    
    # 定义待清理列表
    TARGETS=("$BUILD_DIR" "$REPORT_DIR" "$XML_FILE")
    
    for item in "${TARGETS[@]}"; do
        if [[ -e "$item" ]]; then
            # 根据文件类型显示不同的前缀
            if [[ -d "$item" ]]; then
                echo "    [Deleting Dir]: $item"
            else
                echo "    [Deleting File]: $item"
            fi
            rm -rf "$item"
        else
            echo "    [Skipping]: $item (不存在)"
        fi
    done

    echo ">>> 清理完成。所有临时统计结果与报告已移除。"
    exit 0
fi

if [[ "$MODE" == "init" ]]; then
    [ ! -d "$CONF_DIR" ] && mkdir -p "$CONF_DIR" && echo ">>> 创建配置目录: $CONF_DIR"
    
    # 初始化屏蔽规则
    if [ ! -f "$SUPPRESS_FILE" ]; then
        cat <<EOF > "$SUPPRESS_FILE"
# ==========================================================
# Cppcheck 屏蔽规则配置文件
# Cppcheck 屏蔽规则 (格式: id:file:line)
# ==========================================================
# --- [嵌入式硬件相关] ---
knownConditionTrueFalse:src/drivers/*
readReadOnlyViolation
nullPointer:src/bsp/*

# --- [中断与并发] ---
unusedFunction:src/interrupts.c
variableScope:src/main.c

# --- [语法与宏适配] ---
syntaxError:include/cmsis/*
unknownMacro:src/arch/cpu.c

# --- [目录级排除] ---
*:vendor/*
*:sdk/*
*:rtos/FreeRTOS/*
*:build/*
*:generated/*

# --- [代码建议与风格] ---
passedByValue

# --- [误报屏蔽] ---
unmatchedSuppression
EOF
        echo ">>> 已创建模板: $SUPPRESS_FILE"
    fi

    # 初始化嵌入式定义
    if [ ! -f "$EMBEDDED_CFG" ]; then
        cat <<EOF > "$EMBEDDED_CFG"
<?xml version="1.0"?>
<def format="2">
  <define name="__attribute__(x)" value=""/>
  <define name="__asm__(x)" value=""/>
  <define name="__inline" value="inline"/>
  <define name="__volatile__" value="volatile"/>
  <define name="__packed" value=""/>
  
  <define name="__irq" value=""/>
  <define name="__interrupt" value=""/>

  <define name="REG32(addr)" value="(*(volatile uint32_t *)(addr))"/>
  <define name="WRITE_REG(reg, val)" value="((reg) = (val))"/>
  <define name="READ_REG(reg)" value="(reg)"/>

  <function name="SystemReset">
    <noreturn>true</noreturn>
  </function>

  <memory>
    <alloc init="true">OS_Malloc</alloc>
    <dealloc>OS_Free</dealloc>
  </memory>
</def>
EOF
        echo ">>> 已创建模板: $EMBEDDED_CFG"
    fi
    echo ">>> 初始化流程结束。"
    exit 0
fi

# ------------------------------------------------------------
# 3. 扫描准备 (头文件搜寻 & 缓存创建)
# ------------------------------------------------------------
mkdir -p "$BUILD_DIR"
[[ ${#SCAN_PATHS[@]} -eq 0 ]] && SCAN_PATHS+=("$PROJECT_ROOT/src")

# 定义配置文件路径
INCLUDE_CONF="$PROJECT_ROOT/cppcheck/include_paths.txt"
INCLUDES=()

echo ">>> 正在组装头文件包含路径..."

# --- 1. 从配置文件解析 (手动部分) ---
if [[ -f "$INCLUDE_CONF" ]]; then
    echo "    [Config]: 正在从 $INCLUDE_CONF 加载自定义路径..."
    while IFS='' read -r line || [[ -n "$line" ]]; do
        # 过滤注释行 (#) 和空行
        clean_line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [[ "$clean_line" =~ ^#.*$ ]] || [[ -z "$clean_line" ]] && continue
        
        # 将相对路径转为绝对路径并检查目录是否存在
        abs_path=$(realpath -m "$PROJECT_ROOT/$clean_line")
        if [[ -d "$abs_path" ]]; then
            INCLUDES+=("-I$abs_path")
        else
            echo "      ! 忽略不存在的目录: $clean_line"
        fi
    done < "$INCLUDE_CONF"
fi

# --- 2. 自动搜寻 (find 扫描部分) ---
echo "    [Auto]: 正在扫描目录树以发现 'include' 文件夹..."
while IFS='' read -r line; do 
    if [[ -n "$line" ]]; then
        INCLUDES+=("-I$line")
    fi
done < <(find -L "${SCAN_PATHS[@]}" -type d -name include 2>/dev/null)

# --- 3. 去重与分行结果展示 ---
# 利用 printf 和 sort -u 对数组内容进行去重
if [[ ${#INCLUDES[@]} -gt 0 ]]; then
    # 重新排序并去重
    mapfile -t UNIQUE_INCLUDES < <(printf "%s\n" "${INCLUDES[@]}" | sort -u)
    INCLUDES=("${UNIQUE_INCLUDES[@]}")

    echo ">>> 已加载的包含路径清单:"
    for inc in "${INCLUDES[@]}"; do
        echo "    - ${inc#-I}"
    done
else
    echo "    [!] 未发现任何有效头文件路径。"
fi

echo ">>> 搜寻完毕，共加载 ${#INCLUDES[@]} 个唯一路径。"

# ------------------------------------------------------------
# 4. 执行扫描
# ------------------------------------------------------------
# 基础参数组
ARGS=("--xml" "--xml-version=2" "--enable=all" "--inline-suppr" "--force")
ARGS+=("--cppcheck-build-dir=$BUILD_DIR")
ARGS+=("-rp=$PROJECT_ROOT" "-j$(nproc)")
ARGS+=("${INCLUDES[@]}")

# 加载配置
[ -f "$SUPPRESS_FILE" ] && ARGS+=("--suppressions-list=$SUPPRESS_FILE")
[ -f "$EMBEDDED_CFG" ] && ARGS+=("--library=$EMBEDDED_CFG")

# 平台适配
[[ "$ARCH" == "arm" ]] && ARGS+=("--platform=arm32-wchar_t4") || ARGS+=("--platform=unix64")

echo ">>> 启动扫描 [项目根目录: $PROJECT_ROOT]"

# 环境适配：非终端强制关闭进度条
[[ ! -t 1 ]] && SHOW_PROGRESS=false

if [[ "$SHOW_PROGRESS" == "true" ]]; then
    # 进度显示模式：使用 tee 保证流不被完全拦截
    # 重点修复：将 stderr 同时导向文件和管道，防止 XML 为空
    cppcheck "${ARGS[@]}" "${SCAN_PATHS[@]}" "${EXTRA_ARGS[@]}" --progress 2>&1 >/dev/null | while read -r line; do
        if [[ "$line" == *"progress"* ]]; then
            percent=$(echo "$line" | sed 's/[^0-9]//g')
            printf "\r>>> 分析进度: [%-3s%%]" "$percent"
        fi
    done
    echo ""
fi

# 核心：确保生成最终 XML 结果 (即使进度条失败，此步也会确保 XML 存在)
cppcheck "${ARGS[@]}" "${SCAN_PATHS[@]}" "${EXTRA_ARGS[@]}" 2> "$XML_FILE" > /dev/null

# ------------------------------------------------------------
# 5. 生成报告与彩色摘要
# ------------------------------------------------------------
# 验证 XML 是否有效
if [ ! -s "$XML_FILE" ]; then
    echo ">>> [错误] XML 结果文件为空，分析可能未正常运行。"
    exit 1
fi

if command -v cppcheck-htmlreport > /dev/null ; then
    mkdir -p "$REPORT_DIR"
    cppcheck-htmlreport --file="$XML_FILE" --report-dir="$REPORT_DIR" --source-dir="$PROJECT_ROOT" --title="Static Analysis" > /dev/null
	echo ">>> 成功！报告: $REPORT_DIR/index.html"
fi

colorize_severity() {
    local severity="$1" msg="$2"
    case "$severity" in
        error) printf '\033[1;31m%s\033[0m\n' "$msg" ;;
        warning) printf '\033[1;33m%s\033[0m\n' "$msg" ;;
        ok) printf '\033[1;32m%s\033[0m\n' "$msg" ;;
        *) printf '\033[1;34m%s\033[0m\n' "$msg" ;;
    esac
}

STATUS=0
echo "---------------------------------------"
echo "扫描摘要:"
for s in error warning style performance portability; do
    count=$(grep -c "severity=\"$s\"" "$XML_FILE")
    if [ "$count" -gt 0 ] ; then
        colorize_severity "$s" "  [$s]: $count issues."
        [[ "$s" == "error" || "$s" == "warning" ]] && STATUS=1
    else
        colorize_severity "ok" "  [$s]: 0 issues."
    fi
done
echo "---------------------------------------"

[[ $STATUS -eq 0 ]] && echo ">>> 检测通过！" || echo ">>> 检测到风险，请检查报告。"
exit $STATUS