#!/bin/bash
# Reading List Monitor - 一键部署定时任务
# 用法: bash scripts/setup-schedule.sh [install|uninstall|status|run]

set -euo pipefail

REPO_DIR="/Users/wangshuqi/helloworld/Reading_List"
PLIST_SRC="${REPO_DIR}/scripts/com.readinglist.monitor.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.readinglist.monitor.plist"
LOG_DIR="${REPO_DIR}/logs"

usage() {
    echo "Reading List Monitor - 定时任务管理"
    echo ""
    echo "用法: bash $0 [命令]"
    echo ""
    echo "命令:"
    echo "  install    安装并启动定时任务（每天 9:00 AM 自动运行）"
    echo "  uninstall  卸载定时任务"
    echo "  status     查看定时任务状态"
    echo "  run        立即手动运行一次"
    echo "  logs       查看最近的运行日志"
    echo ""
}

install_schedule() {
    echo "==> 安装 Reading List Monitor 定时任务..."

    # 确保脚本可执行
    chmod +x "${REPO_DIR}/scripts/run-monitor.sh"

    # 创建日志目录
    mkdir -p "${LOG_DIR}"

    # 如果已存在，先卸载
    if [ -f "${PLIST_DST}" ]; then
        echo "    已存在旧的定时任务，先卸载..."
        launchctl unload "${PLIST_DST}" 2>/dev/null || true
    fi

    # 复制 plist 到 LaunchAgents
    cp "${PLIST_SRC}" "${PLIST_DST}"

    # 加载定时任务
    launchctl load "${PLIST_DST}"

    echo "==> 安装完成!"
    echo "    定时任务: 每天 09:00 AM 自动检查 Reading List"
    echo "    日志目录: ${LOG_DIR}"
    echo ""
    echo "    手动运行: bash $0 run"
    echo "    查看状态: bash $0 status"
    echo "    卸载:     bash $0 uninstall"
}

uninstall_schedule() {
    echo "==> 卸载 Reading List Monitor 定时任务..."

    if [ -f "${PLIST_DST}" ]; then
        launchctl unload "${PLIST_DST}" 2>/dev/null || true
        rm -f "${PLIST_DST}"
        echo "==> 已卸载."
    else
        echo "==> 未发现已安装的定时任务."
    fi
}

check_status() {
    echo "==> Reading List Monitor 状态"
    echo ""

    if [ -f "${PLIST_DST}" ]; then
        echo "    定时任务: 已安装"
        if launchctl list | grep -q "com.readinglist.monitor"; then
            echo "    运行状态: 已加载"
        else
            echo "    运行状态: 未加载（可能需要重新 install）"
        fi
    else
        echo "    定时任务: 未安装"
    fi

    echo ""

    # 显示状态文件信息
    STATE_FILE="${REPO_DIR}/reading-list-state.json"
    if [ -f "${STATE_FILE}" ]; then
        LAST_CHECKED=$(python3 -c "import json; print(json.load(open('${STATE_FILE}'))['last_checked'])" 2>/dev/null || echo "unknown")
        PAPER_COUNT=$(python3 -c "import json; print(len(json.load(open('${STATE_FILE}'))['known_papers']))" 2>/dev/null || echo "unknown")
        echo "    上次检查: ${LAST_CHECKED}"
        echo "    已知论文: ${PAPER_COUNT} 篇"
    else
        echo "    状态文件: 未创建（首次运行时会自动建立）"
    fi

    echo ""

    # 显示最近日志
    if [ -d "${LOG_DIR}" ]; then
        LATEST_LOG=$(ls -t "${LOG_DIR}"/run-*.log 2>/dev/null | head -1)
        if [ -n "${LATEST_LOG}" ]; then
            echo "    最近日志: ${LATEST_LOG}"
        fi
    fi
}

run_now() {
    echo "==> 手动运行 Reading List Monitor..."
    echo ""
    bash "${REPO_DIR}/scripts/run-monitor.sh"
}

show_logs() {
    if [ -d "${LOG_DIR}" ]; then
        LATEST_LOG=$(ls -t "${LOG_DIR}"/run-*.log 2>/dev/null | head -1)
        if [ -n "${LATEST_LOG}" ]; then
            echo "==> 最近日志: ${LATEST_LOG}"
            echo "========================================"
            cat "${LATEST_LOG}"
        else
            echo "==> 还没有运行日志."
        fi
    else
        echo "==> 日志目录不存在."
    fi
}

# ---- 主逻辑 ----
case "${1:-}" in
    install)   install_schedule ;;
    uninstall) uninstall_schedule ;;
    status)    check_status ;;
    run)       run_now ;;
    logs)      show_logs ;;
    *)         usage ;;
esac
