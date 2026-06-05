#!/bin/bash
set -e
cd /Users/wangshuqi/helloworld/Reading_List
rm -f .git/index.lock
rm -f "2026-06-05-Value-Functions-as-Supermartingale-Certificates.md"
git add -A
git commit -m "Add research reports for 2026-06-05: Supermartingale Value Functions & Spec Embeddings"
git push
echo "Push 完成!"
rm -f push-reports.sh
