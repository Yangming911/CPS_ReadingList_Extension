#!/bin/bash
set -e
cd /Users/wangshuqi/helloworld/Reading_List
rm -f .git/index.lock
git add -A
git commit -m "Add research reports for 2026-04-28: WayPlan multi-robot bi-level planning + 3D Poisson safety functions for full-body manipulator CBF"
git push
echo "Push 完成!"
rm -f push-reports.sh
