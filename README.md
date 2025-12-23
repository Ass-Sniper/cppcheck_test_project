
# C++ 静态分析集成工具 (Cppcheck & Clang Automation)

本项目提供了一套自动化的 C++ 静态代码分析方案。通过封装 `Cppcheck` 和 `Clang Static Analyzer`，实现了路径自动搜索、配置归档管理、深度流分析以及交互式 HTML 报告的生成。

---

## 1. 项目结构

项目遵循以下目录层级逻辑，支持脚本自动溯源项目根路径：

```text
.
├── cppcheck/               # [配置归档] 存放屏蔽规则与嵌入式库定义
│   ├── suppressions.txt     # 错误忽略白名单
│   ├── embedded.cfg         # 嵌入式平台宏与函数行为定义
│   └── include_paths.txt    # 手动指定的额外头文件路径
├── src/                     # 源代码主目录
│   ├── main.cpp             # 项目入口及集成测试
│   ├── common/              # 自动搜寻此下的 include 文件夹
│   └── framework/           # 自动搜寻此下的 include 文件夹
├── include/                 # 公共头文件目录
├── Makefile                 # 支持 Clang 扫描的编译配置文件
├── tools/
│   └── cppcheck_launcher.sh # [核心] 集成 Cppcheck 与 Clang 扫描逻辑的脚本
└── README.md                # 项目说明文档

```

---

## 2. 核心功能

* **双扫描引擎支持**：
* **Cppcheck**：快速扫描语法、编码风格及基础逻辑错误。
* **Clang (scan-build)**：通过模拟执行路径，挖掘深层内存泄漏与逻辑缺陷。


* **配置归档管理**：所有扫描配置统一存放在 `cppcheck/` 目录。
* **智能包含路径**：自动递归查找 `src/` 下所有 `include` 目录并自动去重。
* **深度清理逻辑**：`clean` 指令可一键清除 Cppcheck 缓存、Clang 报告及 `Makefile` 编译产物。
* **CI/CD 友好**：支持 `--no-progress` 模式，并根据检测风险返回对应的退出码。

---

## 3. 快速上手

### 前提条件

```bash
sudo apt-get install cppcheck clang-tools w3m

```

### 基础操作流程

1. **初始化配置**（仅需一次）：
```bash
./tools/cppcheck_launcher.sh init

```


2. **执行标准扫描 (Cppcheck)**：
```bash
./tools/cppcheck_launcher.sh src/

```


3. **执行深度分析 (Clang)**：
需要项目根目录下存在 `Makefile` 或 `CMakeLists.txt`。
```bash
./tools/cppcheck_launcher.sh clang

```


4. **自定义编译扫描**（针对交叉编译或特定目标）：
```bash
CUSTOM_BUILD_CMD="make -f Makefile.arm" ./tools/cppcheck_launcher.sh clang

```


5. **清理环境**：
```bash
./tools/cppcheck_launcher.sh clean

```



---

## 4. 结果产物

### 交互式报告查看

* **Cppcheck 报告**：位于 `cppcheck_report/index.html`。
* **Clang 报告**：位于 `clang_report/` 目录下的日期子目录中。
* **命令行预览**：
```bash
# 使用 w3m 在终端直接查看报告摘要
w3m -M -dump cppcheck_report/index.html

```

### 终端摘要示例 (cppcheck)
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


### 终端摘要示例 (Clang)

```text
kay@kay-vm:cppcheck_test_project$ ./tools/cppcheck_launcher.sh clang
>>> 启动 Clang Static Analyzer...
>>> 检测到 Makefile，执行默认构建...
scan-build: Using '/usr/lib/llvm-10/bin/clang' for static analysis
/usr/share/clang/scan-build-10/bin/../libexec/c++-analyzer -Wall -Wextra -g -Iinclude -Isrc/common/lib_a/include -Isrc/framework/core/include -c src/main.cpp -o src/main.o
/usr/share/clang/scan-build-10/bin/../libexec/c++-analyzer -Wall -Wextra -g -Iinclude -Isrc/common/lib_a/include -Isrc/framework/core/include -c src/common/lib_a/src/style.cpp -o src/common/lib_a/src/style.o
src/common/lib_a/src/style.cpp: In function ‘void test_style(std::vector<std::__cxx11::basic_string<char> >)’:
src/common/lib_a/src/style.cpp:4:23: warning: comparison of integer expressions of different signedness: ‘int’ and ‘std::vector<std::__cxx11::basic_string<char> >::size_type’ {aka ‘long unsigned int’} [-Wsign-compare]
    4 |     for (int i = 0; i < v.size(); ++i) { // 建议使用 const reference 和 size_t
      |                     ~~^~~~~~~~~~
/usr/share/clang/scan-build-10/bin/../libexec/c++-analyzer -Wall -Wextra -g -Iinclude -Isrc/common/lib_a/include -Isrc/framework/core/include -c src/common/lib_a/src/uninit.cpp -o src/common/lib_a/src/uninit.o
/usr/share/clang/scan-build-10/bin/../libexec/c++-analyzer -Wall -Wextra -g -Iinclude -Isrc/common/lib_a/include -Isrc/framework/core/include -c src/framework/core/src/memory_leak.cpp -o src/framework/core/src/memory_leak.o
src/framework/core/src/memory_leak.cpp: In function ‘void test_error()’:
src/framework/core/src/memory_leak.cpp:2:10: warning: unused variable ‘p’ [-Wunused-variable]
    2 |     int* p = new int[10];
      |          ^
src/framework/core/src/memory_leak.cpp:2:10: warning: Value stored to 'p' during its initialization is never read
    int* p = new int[10];
         ^   ~~~~~~~~~~~
src/framework/core/src/memory_leak.cpp:4:1: warning: Potential leak of memory pointed to by 'p'
}
^
2 warnings generated.
src/common/lib_a/src/uninit.cpp: In function ‘void test_warning()’:
src/common/lib_a/src/uninit.cpp:4:5: warning: ‘x’ is used uninitialized in this function [-Wuninitialized]
    4 |     if (x > 0) { // x 未初始化，触发 warning
      |     ^~
src/common/lib_a/src/uninit.cpp:4:11: warning: The left operand of '>' is a garbage value
    if (x > 0) { // x 未初始化，触发 warning
        ~ ^
1 warning generated.
/usr/share/clang/scan-build-10/bin/../libexec/c++-analyzer src/main.o src/common/lib_a/src/style.o src/common/lib_a/src/uninit.o src/framework/core/src/memory_leak.o -o test_prog
scan-build: 3 bugs found.
scan-build: Run 'scan-view /home/kay/codebase/test/cppcheck_test_project/clang_report/2025-12-23-194136-130652-1' to examine bug reports.
---------------------------------------
>>> Clang 分析完成！
>>> 详细交互式报告请打开: /home/kay/codebase/test/cppcheck_test_project/clang_report/2025-12-23-194136-130652-1/index.html
---------------------------------------
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$ w3m -M -dump clang_report/2025-12-23-194136-130652-1/
index.html          report-28f310.html  report-388ac0.html  report-898f36.html  scanview.css        sorttable.js
kay@kay-vm:cppcheck_test_project$ w3m -M -dump clang_report/2025-12-23-194136-130652-1/index.html
cppcheck_test_project - scan-build results

      User:        kay@kay-vm
Working Directory: /home/kay/codebase/test/cppcheck_test_project
  Command Line:    make -j2
  Clang Version:   clang version 10.0.0-4ubuntu1
      Date:        Tue Dec 23 19:41:36 2025

Bug Summary

Bug Type                                    Quantity Display?
All Bugs                                    3          [ ]
                Dead store
Dead initialization                         1          [ ]
                Logic error
Result of operation is garbage or undefined 1          [ ]
               Memory error
Memory leak                                 1          [ ]

Reports

Bug    Bug Type ▾             File              Function/    Line Path
Group                                           Method            Length
Dead                          framework/core/                            View
store  Dead initialization    src/              test_error   2    1      Report
                              memory_leak.cpp
Memory                        framework/core/                            View
error  Memory leak            src/              test_error   4    2      Report
                              memory_leak.cpp
Logic  Result of operation is common/lib_a/src/ test_warning 4    2      View
error  garbage or undefined   uninit.cpp                                 Report

kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$ ./tools/cppcheck_launcher.sh clean
>>> 正在执行深度清理...
    [Already Clean] : cppcheck_cache
    [Already Clean] : cppcheck_report
    [Already Clean] : cppcheck_results.xml
    [Deleting Dir]  : /home/kay/codebase/test/cppcheck_test_project/clang_report
    [Deleting File] : /home/kay/codebase/test/cppcheck_test_project/test_prog
    [Invoke Make]   : 正在执行 make clean...
    [Status]        : Makefile 清理成功
>>> 清理完成。工作区已恢复至纯净状态。
kay@kay-vm:cppcheck_test_project$
kay@kay-vm:cppcheck_test_project$
```

---

## 5. Git 维护建议

为保持代码库整洁，建议在 `.gitignore` 中忽略以下路径：

```ignore
# 扫描产物
cppcheck_cache/
#忽略任意路径的该文件
**/cppcheck_results.xml
cppcheck_report/
clang_report/

# 编译产物
*.o
test_prog

```

---

## 6. 开发者守卫 (Git Hooks)

为了保证入库代码质量，建议所有开发者启用提交前自动扫描。

### 安装方法
```bash
chmod +x tools/install_hooks.sh
./tools/install_hooks.sh
```
---