
这个脚本是一个用于 **C++ 静态代码分析** 的自动化工具。它封装了 `cppcheck` 工具，旨在扫描代码中的潜在漏洞、编程错误和风格问题，并生成格式化的报告。

以下是对该脚本功能的详细分析：

---

### 1. 核心功能流程

脚本的执行逻辑可以分为以下几个阶段：

1. **环境初始化**：确定项目根目录，加载外部函数库，并自动搜索所有的 `include` 头文件目录。
2. **执行扫描 (`run_cppcheck`)**：配置 `cppcheck` 的参数（如并发数、排除目录、错误等级等）并开始扫描。
3. **结果处理 (`output_results`)**：解析扫描生成的日志文件，统计不同严重程度（Severity）的问题数量。
4. **可视化输出 (`colorize_severity`)**：根据问题的严重程度，在终端用不同的颜色打印统计结果。
5. **状态反馈**：根据是否包含 `error` 或 `warning` 等级的问题，决定脚本最终的退出状态码（Exit Code）。

---

### 2. 关键代码段深度解析

#### A. 自动化路径管理

```bash
scriptdir="$(cd "${0%/*}" && pwd)"
rootdir="${scriptdir%/*/*/*}"
INCLUDES=()
while IFS='' read -r line; do INCLUDES+=("-I$line"); done < <(find -L "$rootdir/common" "$rootdir/framework" -type d -name include)

```

* **根目录定位**：通过脚本位置向上推三级目录找到项目根目录，保证了脚本在不同环境下执行的路径兼容性。
* **自动查找头文件**：使用 `find` 命令递归查找 `common` 和 `framework` 文件夹下所有名为 `include` 的目录，并自动加上 `-I` 前缀。这样开发者在增加新模块时，不需要手动修改脚本的包含路径。

#### B. 扫描参数配置 (`run_cppcheck`)

脚本对 `cppcheck` 进行了精细化配置：

* **并发加速**：`-j"$(nproc)"` 使用当前机器的所有 CPU 核心并行扫描，极大缩短扫描时间。
* **黑名单过滤**：通过多个 `-i` 参数排除了 `unit_tests`（单元测试）、`external`（外部第三方库）和 `build`（编译产物）目录，确保只检查核心业务代码。
* **精确格式**：使用 `--template` 自定义输出格式，方便后续用 `grep` 和 `sed` 进行解析。
* **抑制误报**：使用 `--inline-suppr`（允许在代码注释中忽略警告）和 `--suppressions-list`（外部忽略列表文件）。

#### C. 结果分类与退出逻辑

```bash
case "$s" in
    error|warning)
        status=1
        ;;
    *);;
esac

```

* **严格程度控制**：脚本会将结果分为 `error`, `warning`, `style`, `performance`, `portability` 五类。
* **CI/CD 友好**：只有当出现 **error** 或 **warning** 时，脚本才会返回非零状态码（`status=1`）。这意味着在持续集成流程中，如果是 `style`（风格问题），构建仍能通过，但如果是 `error`，构建会报错停止。

---

### 3. 统计结果示例

脚本运行结束后，会在终端输出类似下表的效果（带有颜色）：

| 严重程度 | 终端颜色 | 是否触发脚本失败 |
| --- | --- | --- |
| **Error** | 红色 (Red) | **是** |
| **Warning** | 黄色 (Yellow) | **是** |
| **Style** | 蓝色 (Blue) | 否 |
| **Performance** | 紫色 (Magenta) | 否 |
| **Portability** | 青色 (Cyan) | 否 |
| **OK (0 issues)** | 灰色 (Gray) | 否 |

---

### 4. 脚本优点总结

* **易读性高**：输出结果经过了 `sed "s|$rootdir/||g"` 处理，去掉了冗长的绝对路径，只显示相对路径。
* **可维护性**：通过 `source functions.sh` 实现了代码复用（虽然脚本中只用到了 `err` 函数）。
* **智能化**：自动识别硬件核心数和头文件路径，无需人工干预扫描环境。

**建议：**
如果你希望在本地开发时使用，可以直接运行 `./script_name.sh <源码目录>`。如果你是在 Docker 或 CI 环境下使用，请确保已预装 `cppcheck` 软件包。

您是想针对这个脚本进行修改（例如增加某种检查类型），还是在配置 CI 流程时遇到了问题？


---

为了测试[该脚本](https://gitlab.com/prpl-foundation/prplmesh/prplMesh/-/blob/master/tools/docker/static-analysis/cppcheck.sh)，我们需要构建一个符合其**目录深度逻辑**（即脚本位于根目录向下三层的 `tools/xxx/xxx/` 目录）的虚拟项目。

以下是一个 Bash 脚本，它可以一键生成整个测试环境，并包含一些“故意写错”的 C++ 代码，用来验证脚本的检测能力。

### 1. 创建测试环境的脚本 (`setup_test_project.sh`)

你可以直接运行这个脚本：

```bash
#!/bin/bash

# 定义项目根目录名称
PROJECT_NAME="cppcheck_test_project"
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

echo "正在创建项目目录结构..."

# 1. 创建脚本要求的目录结构 (rootdir = scriptdir 的向上三级)
# 对应脚本路径: rootdir/tools/docker/static-analysis/check.sh
mkdir -p tools/docker/static-analysis
mkdir -p common/lib_a/include
mkdir -p common/lib_a/src
mkdir -p framework/core/include
mkdir -p framework/core/src
mkdir -p framework/external          # 应该被忽略的目录
mkdir -p framework/platform/nbapi/unit_tests # 应该被忽略的目录

# 2. 创建必要的辅助文件
touch tools/functions.sh
echo "#!/bin/bash" > tools/functions.sh
echo "err() { echo \"[ERROR] \$1\"; }" >> tools/functions.sh

touch tools/docker/static-analysis/suppressions.txt

# 3. 创建带有错误的 C++ 源文件进行测试

# 文件 A: 包含一个内存泄漏 (Severity: error)
cat <<EOF > framework/core/src/memory_leak.cpp
void test_error() {
    int* p = new int[10];
    // 故意不 delete，触发 error
}
EOF

# 文件 B: 包含一个未初始化的变量 (Severity: warning)
cat <<EOF > common/lib_a/src/uninit.cpp
#include <iostream>
void test_warning() {
    int x; 
    if (x > 0) { // x 未初始化，触发 warning
        std::cout << x << std::endl;
    }
}
EOF

# 文件 C: 性能建议 (Severity: performance/style)
cat <<EOF > common/lib_a/src/style.cpp
#include <string>
#include <vector>
void test_style(std::vector<std::string> v) {
    for (int i = 0; i < v.size(); ++i) { // 建议使用 const reference 和 size_t
        std::string s = v[i];
    }
}
EOF

# 文件 D: 被忽略目录下的错误 (不应出现在结果中)
cat <<EOF > framework/external/bad_code.cpp
void hidden_error() {
    int* p = 0;
    *p = 10; // 空指针解引用，但该目录被 -i 忽略了
}
EOF

# 4. 将你分析的脚本写入对应位置
# (这里直接引用你提供的脚本内容，存为 check.sh)
cat <<'EOF' > tools/docker/static-analysis/check.sh
#!/bin/bash
scriptdir="$(cd "${0%/*}" && pwd)"
rootdir="${scriptdir%/*/*/*}"
. "${rootdir}/tools/functions.sh"
OUTPUT_FILE="$rootdir/cppcheck_results.txt"
INCLUDES=()
while IFS='' read -r line; do INCLUDES+=("-I$line"); done < <(find -L "$rootdir/common" "$rootdir/framework" -type d -name include)

usage() {
    echo "usage: $(basename "$0") <source> [source]"
}

run_cppcheck() {
    cppcheck --template='{file}:{line}:{column}: {severity}: {message} [{id}]\n{code}' \
             --force --error-exitcode=1 --enable=warning,style,information,performance,portability \
             -i"$rootdir/framework/platform/nbapi/unit_tests" \
             -i"$rootdir/framework/external" \
             -i"$rootdir/build" \
             --inline-suppr \
             --suppressions-list="$rootdir"/tools/docker/static-analysis/suppressions.txt \
             -rp="$rootdir" -j$(nproc) -q "${INCLUDES[@]}" "$@" 2>&1 | sed "s|$rootdir/||g" | tee "$OUTPUT_FILE"
}

colorize_severity() {
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
    for s in $severities; do
        nb_issues="$(grep -Ec "^[^ ]+ $s:" "$OUTPUT_FILE")"
        if [ "$nb_issues" -gt 0 ] ; then
            colorize_severity "$s" "$nb_issues issues with severity $s"
            [[ "$s" == "error" || "$s" == "warning" ]] && status=1
        else
            colorize_severity "ok" "0 issues with severity $s"
        fi
    done
    return $status
}

if ! command -v cppcheck > /dev/null ; then
    echo "Please install cppcheck!"
    exit 1
fi

run_cppcheck "$@"
output_results
EOF

chmod +x tools/docker/static-analysis/check.sh

echo "测试项目已就绪！"
echo "项目根目录: $(pwd)"
echo "执行以下命令运行测试:"
echo "cd tools/docker/static-analysis && ./check.sh ../../../common ../../../framework"

```

---

### 2. 测试项目结构说明

创建后的目录结构如下所示：

* **`common/` 和 `framework/**`：存放源代码，包含脚本会自动搜索的 `include` 目录。
* **`framework/external/`**：包含错误代码，但根据脚本的 `-i` 参数，这里的错误**不应**被报告。
* **`tools/docker/static-analysis/check.sh`**：脚本所在位置，符合 `rootdir="${scriptdir%/*/*/*}"` 的三级向上回溯逻辑。

---

### 3. 如何验证功能

1. **运行脚本**：
```bash
cd cppcheck_test_project/tools/docker/static-analysis
./check.sh ../../../common ../../../framework

```


2. **观察输出结果**：
* 你应该能看到 **红色** 的 `error` 统计（来自 `memory_leak.cpp`）。
* 你应该能看到 **黄色** 的 `warning` 统计（来自 `uninit.cpp`）。
* 你应该能看到 **蓝色/紫色** 的 `style` 或 `performance` 统计。
* 脚本最后的退出码应该是 `1`（因为存在 error 和 warning）。


3. **验证路径脱敏**：
查看 `cppcheck_results.txt`，文件名应该是 `common/lib_a/src/uninit.cpp` 而不是完整的绝对路径。

你想让我帮你进一步修改脚本，比如让它支持自动生成 HTML 格式的报告吗？


---

太棒了！既然你的环境中已经安装了 `cppcheck-htmlreport`，我们可以将脚本升级为**“双模输出”**：既在终端看到彩色摘要，又生成一份交互式的 HTML 报告。

`cppcheck-htmlreport` 的原理是读取 `cppcheck` 生成的 **XML 格式**结果，然后将其转化为网页。

### 修改后的脚本逻辑

为了支持 HTML 报告，我们需要做两个核心改动：

1. **修改 `run_cppcheck**`：增加 `--xml` 参数，让输出变为 XML 格式。
2. **增加 HTML 转换步骤**：调用 `cppcheck-htmlreport` 处理生成的 XML。

---

### 升级版脚本

你可以直接替换原有的脚本内容：

```bash
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

main() {
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

```

---

### 主要改进点说明：

1. **XML 数据源**：`cppcheck` 运行命令中添加了 `--xml --xml-version=2`。这让 `cppcheck-htmlreport` 能够读取更丰富的元数据（比如错误代码片段、具体的分类 ID）。
2. **HTML 自动生成**：新增加了 `generate_html_report` 函数。它会自动创建目录并将 XML 转化为一个包含可视化图表和源码高亮的网站。
3. **统计逻辑适配**：由于输出变成了 XML，原来的 `grep` 匹配规则失效了。我将其修改为 `grep -c "severity=\"$s\""`，这样依然可以在终端看到实时的统计摘要。
4. **报告路径反馈**：执行结束后，脚本会打印出 `file:///.../index.html` 的路径，你可以在浏览器中直接打开它。

### 如何使用：

1. **运行脚本**：按照之前的测试方式运行升级后的脚本。
2. **查看结果**：
* **终端**：看到彩色的分级统计。
* **本地**：在项目根目录下会多出一个 `cppcheck_report/` 文件夹。


3. **打开报告**：
```bash
# 如果你在有图形界面的 Linux 上
xdg-open ../../../cppcheck_report/index.html

```



HTML 报告非常强大，它允许你点击文件名直接跳转到源代码对应的行，并查看错误的详细解释。这对于修复复杂的 `style` 或 `performance` 问题非常有帮助。

下一步，你想把这个生成的 HTML 报告自动集成到持续集成（如 Jenkins 或 GitLab CI）的产物中吗？

---
