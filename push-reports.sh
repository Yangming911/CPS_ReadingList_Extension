#!/bin/bash
set -e
cd /Users/wangshuqi/helloworld/Reading_List
rm -f .git/index.lock
git add -A
git commit -m "Add research report for 2026-04-24: Neural Jacobian Fields (Nature 2025)"
git push
echo "Push 完成!"
rm -f push-reports.sh
