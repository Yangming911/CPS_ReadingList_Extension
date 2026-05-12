#!/bin/bash
set -e
cd /Users/wangshuqi/helloworld/Reading_List
rm -f .git/index.lock
git add -A
git commit -m "Add research report for 2026-05-12: Cross-Attention Encoder-Decoder Transformers Logical Characterization"
git push
echo "Push 完成!"
rm -f push-reports.sh
