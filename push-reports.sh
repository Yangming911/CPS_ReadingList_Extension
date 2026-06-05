#!/bin/bash
set -e
cd /Users/wangshuqi/helloworld/Reading_List
rm -f .git/index.lock
git add -A
git commit -m "Revise 2026-06-05 reports: correct #3 (PAC RL, ICML 2026) & #4 (DiffReach, RSS 2026) from source papers"
git push
echo "Push 完成!"
rm -f push-reports.sh
