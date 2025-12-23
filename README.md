
# C++ 静态分析集成工具 (Cppcheck Automation)

本项目提供了一套自动化的 C++ 静态代码分析方案。通过封装 `cppcheck`，实现了路径自动搜索、配置归档管理、结果彩色化显示以及交互式 HTML 报告的生成。

---

## 1. 项目结构

项目遵循以下目录层级逻辑，支持脚本自动溯源项目根路径：

```text
.
├── cppcheck/               # [配置归档] 存放屏蔽规则与嵌入式库定义 (运行 init 后生成)
│   ├── suppressions.txt     # 错误忽略白名单
│   └── embedded.cfg         # 嵌入式平台宏与函数行为定义
├── src/                     # 源代码主目录
│   ├── common/              # 自动搜寻此下的 include 文件夹
│   └── framework/           # 自动搜寻此下的 include 文件夹
├── docs/                    # 项目集成与安装文档
├── tools/
│   ├── cppcheck_launcher.sh # [核心] 集成进度条、配置加载与统计的启动脚本
│   └── docker/
│       └── static-analysis/ # Docker 环境下的分析适配脚本
├── README.md                # 项目说明文档
└── cppcheck_cache/         # [自动生成] 扫描缓存，加速二次检测

```

---

## 2. 核心功能

* **配置归档管理**：所有扫描配置统一存放在 `cppcheck/` 目录，避免根目录杂乱。
* **智能包含路径**：自动递归查找 `src/common` 和 `src/framework` 下的所有 `include` 目录，动态分行打印搜寻结果。
* **实时进度反馈**：在终端提供带有百分比的分析进度条（支持 `--no-progress` 关闭）。
* **彩色统计摘要**：扫描结束后，终端自动输出 `Error`, `Warning`, `Style` 等分级统计。
* **自动化 HTML 报告**：自动调用 `cppcheck-htmlreport` 生成带源码高亮的交互式网页。
* **CI/CD 友好**：根据 `Error` 或 `Warning` 的存在情况返回退出码（0 或 1），方便流水线集成。

---

## 3. 快速上手

### 前提条件

确保系统中安装了 `cppcheck` 及其 HTML 报告工具：

```bash
sudo apt-get install cppcheck

```

### 基础操作流程

1. **初始化配置**（仅需一次）：
在根目录下执行，生成 `cppcheck/` 配置文件模板。
```bash
./tools/cppcheck_launcher.sh init

```


2. **执行代码扫描**：
指定扫描 `src` 目录（脚本会自动关联头文件）。
```bash
./tools/cppcheck_launcher.sh src/

```


3. **清理生成物**：
删除缓存、XML 结果和 HTML 报告。
```bash
./tools/cppcheck_launcher.sh clean

```



---

## 4. 结果产物

### 终端输出示例

* **进度显示**：`>>> 当前分析进度: [ 45%]`
* **彩色摘要**：
* `[error]: 0 issues.` (绿色)
* `[warning]: 2 issues found.` (黄色)



### 网页报告

扫描完成后，打开以下文件查看详细缺陷描述及代码位置：
`cppcheck_report/index.html`

---

## 5. 脚本 Usage 详解

```bash
./tools/cppcheck_launcher.sh [命令|路径1] [路径2] ... [选项]

```

**核心控制：**

* `init`: 初始化配置。
* `clean`: 清理缓存与产物。
* `--no-progress`: 在 CI 环境中禁用动态进度条以保持日志整洁。

---

## 6. Git 维护建议

建议在项目的 `.gitignore` 中加入以下内容，避免提交临时产物：

```ignore
# Cppcheck 产物
cppcheck_cache/
cppcheck_results.xml
cppcheck_report/

```

---