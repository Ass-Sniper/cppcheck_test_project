# Cppcheck 安装与升级指南 (Ubuntu 20.04)

本文档说明了如何在 Ubuntu 20.04 环境下安装和配置最新版本的 Cppcheck，以支持 C++20 标准及高级静态分析特性。

## 1. 为什么不使用 apt-get？

Ubuntu 20.04 默认仓库中的 Cppcheck 版本为 **1.90**。该版本：

* 不支持 C++17/20 的许多语法特性。
* 缺乏许多现代漏洞库（Library CFG）的支持。
* 分析准确度与最新的 2.x 版本相比有显著差距。

---

## 2. 安装最新版本 (推荐方案：Snap)

使用 `snap` 是获取最新稳定版/开发版最简单的方式。

### 安装步骤

```bash
# 1. 安装最新版 Cppcheck
sudo snap install cppcheck

# 2. 检查 snap 版本的路径
/snap/bin/cppcheck --version
# 预期输出: Cppcheck 2.14 dev (或类似 2.13.99)

```

### 替换系统默认版本

虽然安装了 snap 版，但系统默认命令 `cppcheck` 仍可能指向旧版。我们需要建立软链接：

```bash
# 1. 移除或备份旧版二进制文件
sudo mv /usr/bin/cppcheck /usr/bin/cppcheck.old

# 2. 创建软链接指向新版
sudo ln -s /snap/bin/cppcheck /usr/bin/cppcheck

# 3. 验证替换结果
which cppcheck
cppcheck --version

```

---

## 3. 编译安装方案 (可选)

如果你需要极致的性能或在不支持 snap 的容器环境中使用，可以从源码编译：

```bash
# 安装编译依赖
sudo apt update
sudo apt install -y cmake g++ libpcre3-dev python3

# 克隆源码并编译
git clone https://github.com/danmar/cppcheck.git
cd cppcheck
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# 安装
sudo make install

```

---

## 4. 关键参数适配说明 (针对 v2.x)

在 2.x 版本中，建议在脚本中使用以下参数以发挥最大威力：

| 参数 | 说明 |
| --- | --- |
| `--std=c++20` | 显式开启 C++20 支持（1.90 不支持此值）。 |
| `--library=std` | 加载标准库配置文件，减少对 `printf` 等函数的误报。 |
| `-j $(nproc)` | 开启多线程并行扫描，利用多核 CPU。 |
| `--check-level=exhaustive` | (2.1x+ 特有) 进行更深度的详尽分析。 |

---

## 5. 故障排除

### 报错：`cppcheck-htmlreport: command not found`

Snap 版的 Cppcheck 可能不包含 HTML 报告生成器。如果发现缺失，可以通过 `pip` 手动安装或使用源码中的脚本：

```bash
# 使用 Python 环境安装报告工具
sudo apt install python3-pip
pip3 install cppcheck-htmlreport

```

---
