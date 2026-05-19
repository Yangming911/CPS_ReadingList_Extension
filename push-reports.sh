#!/bin/bash
set -e
cd /Users/wangshuqi/helloworld/Reading_List
rm -f .git/index.lock
git add -A
git commit -m "Add 5 research reports for 2026-05-19: ETL monitoring, POMDP synthesis, HJ-Gauss, PL-CBF, FM meets LLMs"
git push
echo "Push 完成!"
rm -f push-reports.sh
