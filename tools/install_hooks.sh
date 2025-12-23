#!/bin/bash

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GIT_HOOK_DIR="$PROJECT_ROOT/.git/hooks"
PRE_COMMIT_FILE="$GIT_HOOK_DIR/pre-commit"

echo ">>> 正在安装 Git Hooks..."

# 检查 .git 目录是否存在
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo ">>> [错误] 未发现 .git 目录。请确保在 Git 仓库根目录下运行此脚本。"
    exit 1
fi

# 写入 pre-commit 逻辑
cat <<'EOF' > "$PRE_COMMIT_FILE"
#!/bin/bash

# 自动获取项目根目录
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
LAUNCHER="$PROJECT_ROOT/tools/cppcheck_launcher.sh"

echo "-------------------------------------------------------"
echo ">>> [Git Hook] 正在进行提交前强制扫描..."
echo "-------------------------------------------------------"

# 1. 运行 Cppcheck
$LAUNCHER src/ --no-progress
if [ $? -ne 0 ]; then
    echo ""
    echo ">>> [拦截] Cppcheck 发现风险，请修复后再提交！"
    echo "-------------------------------------------------------"
    exit 1
fi

# 2. 运行 Clang
echo ">>> [Git Hook] Cppcheck 通过，启动 Clang 深度分析..."
$LAUNCHER clang
if [ $? -ne 0 ]; then
    echo ""
    echo ">>> [拦截] Clang 发现逻辑缺陷，请修复后再提交！"
    echo "-------------------------------------------------------"
    exit 1
fi

echo ">>> [成功] 双重扫描通过，允许提交。"
echo "-------------------------------------------------------"
exit 0
EOF

# 赋予执行权限
chmod +x "$PRE_COMMIT_FILE"

echo ">>> [完成] pre-commit hook 已安装并激活。"
echo ">>> 现在每次执行 'git commit' 时，系统都会自动为您进行代码体检。"