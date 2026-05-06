# Refining Compositional Diffusion for Reliable Long-Horizon Planning — 调研报告

> 生成日期：2026-05-07 | Reading List Monitor
> 论文来源：arXiv:2601.00126 (2025-12-31 / 2026-01-05) | https://arxiv.org/abs/2601.00126
> 注：导师列表中标题为 *Refining Compositional Diffusion for Reliable Long-Horizon Planning*；arXiv 上检索到的最相关版本为同作者团队的 *Compositional Diffusion with Guided Search for Long-Horizon Planning* (CDGS)，二者很可能为同一工作的不同稿次或姊妹论文。
> 作者：Utkarsh A. Mishra 等

## 1. 问题背景与研究动机

Diffusion-based planner 已成为 long-horizon 规划领域的有力候选——其优势是天然支持多模态轨迹分布，可通过 classifier guidance 灵活注入约束。但要把短时段 diffusion 扩展到长时段，主流做法是**组合 (compose)** 多个局部 diffusion model：每个局部模型只负责一段轨迹，再通过重叠区域的一致性约束拼接起来。这一思路在多步 manipulation、panoramic image synthesis、long video generation 上均有体现。

本文指出 compositional diffusion 的核心缺陷：**当局部分布是多模态时，简单的分布乘法/平均会"平均掉"互不相容的模式**，得到既不局部可行也不全局连贯的轨迹（mode averaging 现象）。例如，在拣选-放置任务中，局部"如何抓取"可能有左/右两个等价模式，"如何放置"也有两个等价模式，而合成时若不约束模式选择，往往得到"半左半右"的非物理解。研究动机就是设计一个能在 compositional 框架下**显式探索模式组合**的算法，避免 averaging，同时保留 compositional 训练的数据效率优势。

## 2. 技术方法

文章提出 **CDGS (Compositional Diffusion with Guided Search)**，把 search 嵌入 diffusion denoising 过程，分三个核心模块：

1. **Population-based mode sampling**：在每个 denoising 步维持一个由 $N$ 条候选轨迹组成的 population，每条轨迹从不同的局部模式组合中采样得到，从而显式覆盖多模态空间。
2. **Likelihood-based pruning**：利用每个局部 diffusion 的 score function 估计轨迹的 (近似) likelihood，剪掉那些在某个局部模型下显著不可行的候选——避免在不可行模式上浪费 compute。
3. **Iterative resampling for global consistency**：在重叠 segment 上用 message passing 风格的 resampling，让相邻 segment 在 noise space 上达成一致。这一步本质上是把 compositional planning 转写为图模型上的 belief propagation，但在 diffusion latent 空间中实现。

整个流程在推理时执行，无需额外训练。该论文还把方法泛化到非机器人域：用同一框架做 text-guided panoramic image generation 和 long video synthesis，体现"composition + guided search"的通用性。

理论侧，作者讨论了与 importance sampling、SMC (sequential Monte Carlo) 的联系——CDGS 可被看作以 diffusion score 为 proposal 的一类粒子滤波。这给出了收敛性的初步保证（在 population 大小趋向无穷时收敛到正确组合分布）。

## 3. 研究前沿与意义

Diffusion planner 自 *Diffuser* (Janner et al. 2022) 以来已成长为活跃的子领域，长时段是其公认软肋。近一年的相关方向包括：multiscale diffusion (*Extendable Planning via Multiscale Diffusion*, arXiv:2503.20102)、generative trajectory stitching (arXiv:2503.05153)、coupled hierarchical diffusion (arXiv:2505.07261)、以及实时化的 *DiffuserLite*。CDGS 与这些工作的差异在于：它强调"局部模型保持简单 + 推理时显式 search"，而其他方法多通过更复杂的训练（hierarchical、multiscale）来扩展时段。

热度评估：long-horizon diffusion planning 已成为 ICLR、NeurIPS、ICML、CoRL 的常见 track，每年都有 dedicated workshop（如 NeurIPS *Generative Models for Decision Making*、ICLR *Diffusion Models in Sequential Decision*）。机器人侧则集中在 RSS、CoRL、ICRA。活跃团队包括 MIT (Janner / Du)、Georgia Tech (Mishra / Garg)、Stanford (Finn)、CMU、UPenn、Tsinghua AI Lab 等。

## 4. 相关工作

- **Compositional Diffusion with Guided Search for Long-Horizon Planning** (arXiv:2601.00126)。即本文（同作者最相关版本）。https://arxiv.org/abs/2601.00126
- **Refining Diffusion Planner for Reliable Behavior Synthesis by Automatic Detection of Infeasible Plans** (arXiv:2310.19427)。从 restoration gap 角度检测并 reject 不可行 diffusion 轨迹，与 CDGS 的 likelihood-based pruning 思路不同但目标一致。
- **Generative Trajectory Stitching through Diffusion Composition** (arXiv:2503.05153)。直接处理 long-horizon trajectory stitching，与 CDGS 在 segment 拼接上的思路构成对照。
- **Extendable Planning via Multiscale Diffusion** (arXiv:2503.20102)。通过 multi-scale 训练实现长时段，是 CDGS"训练简单 + 推理 search"的对偶方案。
- **Discrete-Guided Diffusion for Scalable and Safe Multi-Robot Motion Planning**（已在 reading list 上）。把离散 guidance 与 diffusion planner 结合，做安全多机规划——可借鉴 CDGS 的 search 思路。
- **Simultaneous Multi-Robot Motion Planning with Projected Diffusion Models**（已在 reading list 上）。把约束以 projection 方式注入 diffusion，与 CDGS 的 likelihood pruning 在"如何处理硬约束"上可对照讨论。

## 5. 组会讨论要点

1. **Search 与 formal verification 的衔接**：CDGS 的 search 是基于 likelihood，本质上仍是软约束。能否把 STL/CBF 这类硬约束作为 search 的剪枝条件——例如在 pruning 阶段直接 reject 违反 STL 的候选轨迹？这与组里 *TeLoGraF* 等基于 graph encoding 的 STL planner 有融合空间。
2. **Mode averaging 与 safety 的潜在冲突**：在 safety-critical 场景中，mode averaging 不仅是性能问题，还可能是危险来源（"半左半右"轨迹可能直接撞向人）。如果 reading list 上 *When Environments Shift* 的 robust conformal 思路与 CDGS 结合，是否可以构造一个"mode-aware safety filter"？
3. **Compute 成本的实际可行性**：population-based search + iterative resampling 显著增加推理时计算量。在实时机器人系统上是否可承受？是否能借用组里在 *Conformal Reachability* / *Conformal Predictive Monitoring* 中的 anytime 思路，把 search budget 作为可调超参数动态分配？

## 参考文献

1. Mishra, U. A. *et al.* *Compositional Diffusion with Guided Search for Long-Horizon Planning.* arXiv:2601.00126, 2026. https://arxiv.org/abs/2601.00126
2. *Refining Diffusion Planner for Reliable Behavior Synthesis by Automatic Detection of Infeasible Plans.* arXiv:2310.19427. https://arxiv.org/abs/2310.19427
3. *Generative Trajectory Stitching through Diffusion Composition.* arXiv:2503.05153. https://arxiv.org/html/2503.05153v1
4. *Extendable Planning via Multiscale Diffusion.* arXiv:2503.20102. https://arxiv.org/html/2503.20102
5. *CHD: Coupled Hierarchical Diffusion for Long-Horizon Tasks.* arXiv:2505.07261. https://arxiv.org/html/2505.07261v1
6. *Compositional Visual Planning via Inference-Time Diffusion Scaling.* OpenReview. https://openreview.net/forum?id=EEONns7ae4
