#!/bin/bash
# Reading List Monitor - 定时执行脚本
# 由 launchd 调用，通过 Claude Code 非交互模式执行 reading list 检查

set -euo pipefail

# ---- 配置 ----
REPO_DIR="/Users/wangshuqi/helloworld/Reading_List"
LOG_DIR="${REPO_DIR}/logs"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# ---- 初始化 ----
mkdir -p "${LOG_DIR}"
cd "${REPO_DIR}"

echo "========================================"
echo "Reading List Monitor - ${TIMESTAMP}"
echo "========================================"

# 检查 claude 命令是否可用
if ! command -v claude &> /dev/null; then
    # 尝试常见的安装路径
    CLAUDE_PATHS=(
        "/usr/local/bin/claude"
        "$HOME/.claude/bin/claude"
        "$HOME/.local/bin/claude"
        "/opt/homebrew/bin/claude"
    )
    CLAUDE_CMD=""
    for path in "${CLAUDE_PATHS[@]}"; do
        if [ -x "$path" ]; then
            CLAUDE_CMD="$path"
            break
        fi
    done

    if [ -z "$CLAUDE_CMD" ]; then
        echo "ERROR: claude command not found. Please ensure Claude Code is installed."
        echo "Install with: brew install claude-code"
        exit 1
    fi
else
    CLAUDE_CMD="claude"
fi

echo "Using Claude Code at: $(which ${CLAUDE_CMD} 2>/dev/null || echo ${CLAUDE_CMD})"

# 执行 reading list 检查
# 使用 --print 模式（非交互），指定项目目录
"${CLAUDE_CMD}" -p \
    --project-dir "${REPO_DIR}" \
    "请执行 /project:check-reading-list 命令。按照命令中的完整流程执行：检查 Overleaf reading list、发现新论文则生成调研报告、git push、生成微信通知。如果没有新论文则简单报告即可。" \
    2>&1 | tee "${LOG_DIR}/run-${TIMESTAMP}.log"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "Monitor completed successfully at $(date)"
else
    echo ""
    echo "ERROR: Monitor failed with exit code ${EXIT_CODE} at $(date)"
fi

exit $EXIT_CODE
