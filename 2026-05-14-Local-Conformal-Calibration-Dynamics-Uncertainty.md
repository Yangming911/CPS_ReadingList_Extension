# Local Conformal Calibration of Dynamics Uncertainty from Semantic Images — 调研报告

> 生成日期：2026-05-14 | Reading List Monitor
> 论文来源：与 arxiv 2409.08249 (LUCCa) 密切相关，可能为其扩展版本；另见 arxiv 2508.09346

## 1. 问题背景与研究动机

基于视觉感知的自主系统（如自动驾驶、机器人操作）面临一个核心挑战：系统的安全决策依赖于对未来状态的预测，而这些预测的不确定性来源复杂——既包括环境本身的随机性（aleatoric uncertainty），也包括模型对动态环境理解不足导致的认知不确定性（epistemic uncertainty）。当系统输入是高维语义图像（semantic images）时，不确定性的量化变得尤为困难。

本文解决的核心问题是：**如何从语义图像输入出发，利用 conformal prediction 的框架对动力学模型的预测不确定性进行局部校准（local calibration），使其在状态-动作空间的不同区域都能提供统计上有效的预测区间？**

现有方法的不足：
- 全局校准（global calibration）方法使用单一标定因子，无法反映不同状态区域预测精度的差异，导致在某些区域过于保守、在另一些区域不够安全
- 传统的 uncertainty quantification 方法（如 ensemble、MC dropout）缺乏有限样本下的理论保证
- 直接在图像空间进行不确定性传播计算上不可行

本文的贡献在于提出了一种局部化的 conformal calibration 方法，能根据当前状态和动作自适应调整预测区间的大小，同时为规划和控制提供概率安全保证。

## 2. 技术方法

本文的技术方法基于 Local Uncertainty Conformal Calibration (LUCCa) 框架，核心思路如下：

**基本架构**：
1. 一个预训练的动力学模型，输入当前状态（可能通过图像编码得到）和动作，输出下一步状态的预测分布（通常为多元正态分布）
2. 一个 conformal calibration 层，利用校准数据集调整预测分布的尺度

**局部校准机制**：
- 与全局方法不同，LUCCa 在状态-动作空间中为每个局部区域计算不同的 scaling factor
- 使用 k-nearest neighbor 或核函数定义"局部"的概念，使得在模型预测不准确的区域自动放大不确定性估计，在预测准确的区域缩小估计
- 这种局部化使得校准后的预测区间同时反映了 aleatoric 和 epistemic uncertainty

**从语义图像到动力学不确定性**：
- 语义图像通过编码器映射到潜在状态表示
- 动力学模型在潜在空间中进行预测
- Conformal calibration 在潜在空间中执行，校准后的不确定性区间可以映射回物理状态空间

**理论保证**：
- 对于任意有限校准数据集，LUCCa 保证在给定置信水平下，真实状态落入预测区间的概率不低于 1-α
- 当近似动力学为线性时，多步预测的覆盖率保证也成立
- 不需要对真实动力学函数或扰动分布做任何假设

**在安全规划中的应用**：
- 将校准后的不确定性区间作为约束嵌入 MPC 框架
- 规划器在考虑不确定性的前提下寻找到达目标且避开障碍物的轨迹
- 通过控制 α 参数调节安全性与任务完成率的权衡

## 3. 研究前沿与意义

Conformal prediction 在 CPS 安全领域的应用是 2023 年以来最受关注的研究方向之一，主要证据：

- 2024-2025 年间，L4DC、RSS、ICRA、NeurIPS 等顶会发表了大量 conformal prediction + robot safety 的工作
- 多个知名实验室（UPenn GRASP、Stanford ASL、Michigan ARM Lab、MIT LIDS）在此方向投入显著
- 相关 workshop 在 RSS 2024、NeurIPS 2024 等会议上出现

**主要竞争方法**：
- Gaussian process-based uncertainty quantification（有理论保证但扩展性差）
- Ensemble methods + calibration（经验性能好但缺乏 finite-sample 保证）
- Bayesian neural networks（理论优美但计算昂贵且校准困难）
- Scenario-based approaches（distribution-free 但样本效率低）

**活跃研究组**：
- University of Michigan ARM Lab（LUCCa 原作者）
- UPenn GRASP Lab（George Pappas 组，conformal prediction for MPC）
- Stanford ASL（Marco Pavone 组）
- Trustworthy Engineered Autonomy Lab（image-based safety prediction）

**常见发表 venue**：L4DC, RSS, ICRA, CDC, NeurIPS, ICLR, CoRL。

## 4. 相关工作

1. **"Quantifying Aleatoric and Epistemic Dynamics Uncertainty via Local Conformal Calibration" (LUCCa)** (arxiv 2409.08249, Michigan ARM Lab)
   - 提出 LUCCa 方法，通过局部 conformal calibration 同时量化 aleatoric 和 epistemic uncertainty
   - 与本文的关联：本文可能是 LUCCa 的扩展，将其应用到语义图像输入的场景
   - 关键区别：原始 LUCCa 论文侧重于低维状态空间，本文可能扩展到高维视觉输入

2. **"How Safe Will I Be Given What I Saw? Calibrated Prediction of Safety Chances for Image-Controlled Autonomy"** (arxiv 2508.09346)
   - 使用 VAE 和循环预测器从原始图像序列预测未来潜在轨迹，结合 conformal calibration 进行安全概率估计
   - 与本文的关联：同为从图像输入出发的安全预测，使用 conformal 方法提供统计保证
   - 关键区别：侧重于安全概率的预测而非动力学不确定性的校准

3. **"Safety-Critical Control with Uncertainty Quantification using Adaptive Conformal Prediction"** (arxiv 2407.03569)
   - 将 adaptive conformal prediction 与概率 CBF 结合用于安全关键控制
   - 与本文的关联：同为 conformal prediction + safety control 的结合
   - 关键区别：使用 adaptive（在线更新）的 conformal prediction，不专注于图像输入

4. **"Conformal Prediction for Uncertainty-Aware Planning with Diffusion Dynamics Model"** (NeurIPS 2023)
   - 将 conformal prediction 与 diffusion-based 动力学模型结合用于规划
   - 与本文的关联：同为 conformal prediction + 动力学模型 + 规划
   - 关键区别：使用 diffusion model 而非传统参数化动力学模型，全局校准而非局部校准

5. **"Conformal Reachability for Safe Control"** (已在组内 reading list 中)
   - 使用 conformal prediction 进行可达性分析，为安全控制提供概率保证
   - 与本文的关联：同为 conformal prediction 用于安全保证的工作
   - 关键区别：侧重于可达性分析而非动力学不确定性校准

## 5. 组会讨论要点

1. **局部校准 vs 全局校准的实际影响**：LUCCa 的核心创新在于"局部"校准。但在高维状态空间中，定义"局部"需要足够的校准数据密度，否则可能退化为全局校准。当输入是图像编码的潜在表示时，潜在空间的结构是否足够好以支持有意义的局部校准？

2. **与组内 conformal reachability 工作的结合可能**：LUCCa 提供的是逐步（step-wise）的不确定性校准，而 conformal reachability 关注的是整条轨迹的安全性。能否将 LUCCa 的局部校准机制嵌入 reachability analysis 中，得到更紧的可达集估计？

3. **从 semantic images 到安全保证的 end-to-end pipeline 的可靠性**：整个链条涉及图像编码、潜在空间动力学预测、conformal calibration 三个模块，每个模块都引入误差。当前的理论保证是否能覆盖整个 pipeline 的误差累积？特别是图像编码器的 representation shift 问题是否被充分考虑？

## 参考文献

- "Quantifying Aleatoric and Epistemic Dynamics Uncertainty via Local Conformal Calibration", Marques et al., arxiv 2409.08249. https://arxiv.org/abs/2409.08249
- LUCCa 项目主页: https://um-arm-lab.github.io/lucca/
- "How Safe Will I Be Given What I Saw? Calibrated Prediction of Safety Chances for Image-Controlled Autonomy", arxiv 2508.09346. https://arxiv.org/abs/2508.09346
- "Safety-Critical Control with Uncertainty Quantification using Adaptive Conformal Prediction", arxiv 2407.03569. https://arxiv.org/abs/2407.03569
- "Conformal Prediction for Uncertainty-Aware Planning with Diffusion Dynamics Model", NeurIPS 2023. https://openreview.net/forum?id=VeO03T59Sh
- "How Safe Am I Given What I See? Calibrated Prediction of Safety Chances for Image-Controlled Autonomy", arxiv 2308.12252. https://arxiv.org/abs/2308.12252
