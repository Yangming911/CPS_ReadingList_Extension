#!/bin/bash
set -e
cd /Users/wangshuqi/helloworld/Reading_List
rm -f .git/index.lock
git add -A
git commit -m "Add research report for 2026-04-21: Trajectory Planning for Safe Dual Control with Active Exploration"
git push
echo "Push 完成!"
rm -f push-reports.sh
