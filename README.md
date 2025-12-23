
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

```text
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$ ./tools/cppcheck_launcher.sh init
>>> 已创建模板: /home/kay/codebase/test/cppcheck_test_project/cppcheck/suppressions.txt
>>> 已创建模板: /home/kay/codebase/test/cppcheck_test_project/cppcheck/embedded.cfg
>>> 初始化流程结束。
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$ ./tools/cppcheck_launcher.sh src/
>>> 正在组装头文件包含路径...
    [Config]: 正在从 /home/kay/codebase/test/cppcheck_test_project/cppcheck/include_paths.txt 加载自定义路径...
    [Auto]: 正在扫描目录树以发现 'include' 文件夹...
>>> 已加载的包含路径清单:
    - /home/kay/codebase/test/cppcheck_test_project/include
    - /home/kay/codebase/test/cppcheck_test_project/src/common/lib_a/include
    - /home/kay/codebase/test/cppcheck_test_project/src/framework/core/include
>>> 搜寻完毕，共加载 3 个唯一路径。
>>> 启动扫描 [项目根目录: /home/kay/codebase/test/cppcheck_test_project]

>>> 成功！报告: /home/kay/codebase/test/cppcheck_test_project/cppcheck_report/index.html
---------------------------------------
扫描摘要:
  [error]: 3 issues.
  [warning]: 0 issues.
  [style]: 8 issues.
  [performance]: 0 issues.
  [portability]: 0 issues.
---------------------------------------
>>> 检测到风险，请检查报告。
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$ w3m

Command 'w3m' not found, but can be installed with:

sudo apt install w3m

kay@kay-vm:cppcheck_test_project$ sudo apt install w3m
Reading package lists... Done
Building dependency tree
Reading state information... Done
The following packages were automatically installed and are no longer required:
  cmake-data libjsoncpp1 librhash0 python3-attr python3-cached-property python3-docker python3-dockerpty python3-docopt python3-importlib-metadata
  python3-jsonschema python3-more-itertools python3-pyrsistent python3-texttable python3-websocket python3-zipp
Use 'sudo apt autoremove' to remove them.
Suggested packages:
  cmigemo dict dict-wn dictd libsixel-bin mpv w3m-el w3m-img xsel
The following NEW packages will be installed:
  w3m
0 upgraded, 1 newly installed, 0 to remove and 47 not upgraded.
Need to get 916 kB of archives.
After this operation, 2,572 kB of additional disk space will be used.
Get:1 http://mirrors.aliyun.com/ubuntu focal-updates/main amd64 w3m amd64 0.5.3-37ubuntu0.2 [916 kB]
Fetched 916 kB in 6s (143 kB/s)
Selecting previously unselected package w3m.
(Reading database ... 290561 files and directories currently installed.)
Preparing to unpack .../w3m_0.5.3-37ubuntu0.2_amd64.deb ...
Unpacking w3m (0.5.3-37ubuntu0.2) ...
Setting up w3m (0.5.3-37ubuntu0.2) ...
Processing triggers for man-db (2.9.1-1) ...
Processing triggers for mime-support (3.64ubuntu1) ...
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$ w3m -M -dump cppcheck_report/index.html
Cppcheck report - Static Analysis:

Defect summary;

[*] Toggle all

Show #        Defect ID
[*]  4  unusedFunction
[*]  3  missingIncludeSystem
[*]  2  unreadVariable
[*]  1  checkersReport
[*]  1  constVariablePointer
[*]  1  memleak
[*]  1  nullPointer
[*]  1  uninitvar
[*]  1  unusedAllocatedMemory
     15 total

Statistics

Line          Id           CWE  Severity                 Message

                                           Active checkers: 162/592 (use
0    checkersReport            information --checkers-report=<filename> to see
                                           details)
/home/kay/codebase/test/cppcheck_test_project/src/common/lib_a/src/style.cpp
                                           Include file: <string> not found.
1    missingIncludeSystem      information Please note: Cppcheck does not need
                                           standard library headers to get
                                           proper results.
                                           Include file: <vector> not found.
2    missingIncludeSystem      information Please note: Cppcheck does not need
                                           standard library headers to get
                                           proper results.
3    unusedFunction        561 style       The function &apos;test_style&apos;
                                           is never used.
/home/kay/codebase/test/cppcheck_test_project/src/common/lib_a/src/uninit.cpp
                                           Include file: <iostream> not found.
1    missingIncludeSystem      information Please note: Cppcheck does not need
                                           standard library headers to get
                                           proper results.
2    unusedFunction        561 style       The function &apos;test_warning&
                                           apos; is never used.
/home/kay/codebase/test/cppcheck_test_project/src/framework/core/src/
memory_leak.cpp
1    unusedFunction        561 style       The function &apos;test_error&apos;
                                           is never used.
/home/kay/codebase/test/cppcheck_test_project/src/framework/external/
bad_code.cpp
1    unusedFunction        561 style       The function &apos;hidden_error&
                                           apos; is never used.
src/common/lib_a/src/style.cpp
5    unreadVariable        563 style       Variable &apos;s&apos; is assigned a
                                           value that is never used.
src/common/lib_a/src/uninit.cpp
4    uninitvar             457 error       Uninitialized variable: x
src/framework/core/src/memory_leak.cpp
2    constVariablePointer  398 style       Variable &apos;p&apos; can be
                                           declared as pointer to const
2    unreadVariable        563 style       Variable &apos;p&apos; is assigned a
                                           value that is never used.
2    unusedAllocatedMemory 563 style       Variable &apos;p&apos; is allocated
                                           memory that is never used.
4    memleak               401 error       Memory leak: p
src/framework/external/bad_code.cpp
3    nullPointer           476 error       Null pointer dereference: p

Cppcheck 2.14 dev - a tool for static C/C++ code analysis Internet: http://
cppcheck.net IRC: irc://irc.freenode.net/cppcheck

kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$ ./tools/cppcheck_launcher.sh clean
>>> 正在清理分析痕迹...
    [Deleting Dir]: /home/kay/codebase/test/cppcheck_test_project/cppcheck_cache
    [Deleting Dir]: /home/kay/codebase/test/cppcheck_test_project/cppcheck_report
    [Deleting File]: /home/kay/codebase/test/cppcheck_test_project/cppcheck_results.xml
>>> 清理完成。所有临时统计结果与报告已移除。
kay@kay-vm:cppcheck_test_project$
```


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