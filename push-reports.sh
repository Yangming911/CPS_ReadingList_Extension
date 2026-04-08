#!/bin/bash
set -e
cd /Users/wangshuqi/helloworld/Reading_List
rm -f .git/index.lock
git add -A
git commit -m "Add research reports for 2026-04-08: 8 new papers (Staggered Conformal Prediction, Set-Based Latent Safety, Product Constructions Temporal Inference, Risk-Constrained Belief-Space, Minimal Info Control Invariance, PAC Reachability Comparison, Inverse Safety Filtering, Goal-Conditioned Neural ODEs)"
git push
echo "Push 完成!"
rm -f push-reports.sh
