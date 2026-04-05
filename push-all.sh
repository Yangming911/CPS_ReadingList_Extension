#!/bin/bash
# 一键推送所有文件到 GitHub
# 用法: bash push-all.sh

set -e
cd /Users/wangshuqi/helloworld/Reading_List

echo "==> 清理 git lock..."
rm -f .git/index.lock

echo "==> 同步远程仓库（已有 .gitignore commit）..."
git fetch origin master
git reset origin/master

echo "==> 暂存所有文件..."
git add -A

echo "==> 提交..."
git commit -m "Add research reports (2026-04-05), automation scripts, and state file

- 2 paper reports: CLF-CBF Soft Robot, Distributed Privacy-Preserving Monitoring
- Scripts: parse_reading_list.py, run-monitor.sh, setup-schedule.sh, launchd plist
- Claude Code custom command: check-reading-list.md
- State file: reading-list-state.json"

echo "==> 推送到 GitHub..."
git push -u origin master

echo ""
echo "==> 完成! 查看: https://github.com/Yangming911/CPS_ReadingList_Extension"

# 自清理
rm -f push-all.sh
