#!/bin/bash
set -e
cd /Users/wangshuqi/helloworld/Reading_List
rm -f .git/index.lock
git add -A
git commit -m "Add research reports for 2026-05-07: 6 new papers (Beyond Alignment, Multistability of Self-Attention, Risk-Aware DR for MPPI, Compositional Diffusion, TL Value Functions, Affordance Agent Harness)"
git push
echo "Push 完成!"
rm -f push-reports.sh
