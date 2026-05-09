#!/bin/bash
set -e
cd /Users/wangshuqi/helloworld/Reading_List
rm -f .git/index.lock
git add -A
git commit -m "Add research reports for 2026-05-09: Safety Certification, HDFlow, Dream-MPC"
git push
echo "Push 完成!"
rm -f push-reports.sh
