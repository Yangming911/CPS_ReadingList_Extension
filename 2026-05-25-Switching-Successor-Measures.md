# Switching Successor Measures for Hierarchical Zero-shot Reinforcement Learning — 调研报告

> 生成日期：2026-05-25 | Reading List Monitor
> 论文来源：https://arxiv.org/abs/2605.13207

## 1. 问题背景与研究动机

Hierarchical reinforcement learning (HRL) 通过将长视野决策分解为更简单的子问题来提升泛化能力，这在机器人导航、长期规划等 CPS 相关任务中具有重要价值。然而，现有的 HRL 方法往往依赖于较为严格的设计假设：固定的 temporal abstraction（如 option 框架中的固定时间步长）、goal-conditioned 目标函数（将策略限制在 goal-reaching 任务上）、或人工设计的 subgoal（需要领域专家知识）。这些限制使得大多数 HRL 方法难以直接应用于一般的 reward function。

与此同时，zero-shot RL 通过预训练阶段学习通用的状态表征，使得 agent 在测试时无需额外训练即可适应新的 reward function。Successor measures 及其 forward-backward (FB) representation 是 zero-shot RL 的核心工具之一，但此前的工作主要产生"扁平"的非层次化策略，在长视野任务上性能受限。

本文的核心贡献是提出 **switching successor measures**，一种从经典 successor measures 自然推导出的扩展形式，能够在 zero-shot RL 框架中实现层次化控制——无需额外监督信号、固定时间视野或人工 subgoal 设计。

## 2. 技术方法

**Successor Measures 回顾**：Successor measures（Touati et al., 2023）将 successor features 推广到连续状态空间。给定策略 π，successor measure M^π(s, ·) 描述了从状态 s 出发、遵循 π 时对未来状态的 discounted 访问分布。Forward-backward (FB) representation 将 occupancy measure 分解为 forward representation（捕捉策略动态）和 backward representation（编码全局状态信息），通过离线无监督预训练学习线性化表征。

**Switching Successor Measures**：本文的关键理论创新。作者证明，层次化结构隐含地编码在标准 successor representation 中，可以无需额外学习即可恢复（Theorem 1）。Switching successor measures 允许 agent 在执行过程中"切换"子策略，从而自然地产生层次化行为。

**FB π-Switch 算法**：基于 switching successor measures，本文提出的具体算法。其核心设计包括：
- **High-level policy**：从 FB representation 中提取 subgoal 选择策略，决定何时以及向哪个子目标切换
- **Low-level policy**：同样从 FB representation 中导出的控制策略，负责执行到达 subgoal 的具体动作
- **三阶段训练**：(1) 离线预训练 FB representation；(2) 学习 high-level switching policy；(3) 部署时 zero-shot 组合。High-level policy 的学习可以自然地融入现有的 FB 训练流程

**关键优势**：与 HIQL 等现有层次化方法相比，FB π-Switch 消除了对固定 temporal abstraction、人工 subgoal 和额外监督的依赖，且不局限于 goal-reaching 任务，支持任意 reward function。

## 3. 研究前沿与意义

Zero-shot RL 和 hierarchical RL 的结合是 2025-2026 年 RL 研究的活跃方向：

- **Zero-shot RL** 近年发展迅速：Touati et al. (2023) 提出 FB representation，Sikchi et al. (2025) 提出在线 embedding 自适应，Zheng et al. (2025) 研究 robust zero-shot RL。这一方向试图解决 RL 的泛化瓶颈——预训练一次，适应多种任务。
- **Hierarchical RL** 从 option framework (Sutton et al., 1999) 发展至今，HIRO (Nachum et al., 2018)、HIQL (Park et al., 2023) 等方法逐步提升了层次化策略的性能，但设计约束仍然较多。
- 本文的贡献在于建立了两个方向之间的理论桥梁，证明层次化控制结构可以从 successor representation 中自然涌现。

活跃研究组包括：KTH（本文作者 Proutiere 团队）、Meta FAIR（Touati 等人的 FB representation 系列）、UC Berkeley（Eysenbach 的 contrastive RL）、Stanford（Chelsea Finn 团队的 hierarchical decision making）等。

主要发表 venue：NeurIPS、ICML、ICLR（主会议）以及 CoRL（机器人学习）。

## 4. 相关工作

1. **Successor Measures / Forward-Backward Representations** (Touati & Ollivier, 2023)
   - 提出 FB representation，将 occupancy measure 线性化，实现 zero-shot task adaptation。本文直接建立在这一框架之上，是其层次化扩展。

2. **HIQL: Offline Goal-Conditioned RL with Latent States as Actions** (Park et al., 2023)
   - 当前 state-of-the-art 的层次化 goal-conditioned RL 方法。FB π-Switch 在 goal-conditioned 任务上匹配 HIQL 的性能，同时支持更一般的 reward function。

3. **Proto Successor Measures: Representing the Behavior Space of an RL Agent** (Agarwal et al., 2024)
   - 提出 proto successor measures 来表征 RL agent 的行为空间。与本文使用 successor measure 提取层次化结构的思路相关但角度不同。

4. **Does Zero-Shot Reinforcement Learning Exist?** (Ollivier, 2023)
   - 对 zero-shot RL 可行性的理论分析，为 FB representation 及后续工作提供了理论基础。

5. **Compositional Planning with Jumpy World Models** (Farebrother et al., 2026)
   - 最新的 compositional planning 方法，通过 jumpy world model 实现多步规划。与本文的层次化分解思想互补。

## 5. 组会讨论要点

1. **与 temporal logic 约束的结合潜力**：FB π-Switch 的 switching mechanism 在概念上类似于 temporal logic 中的 until operator 或 automaton 的状态转移。是否可以在 high-level policy 层面引入 LTL/STL specification 来引导 subgoal 选择，从而实现 specification-guided hierarchical zero-shot RL？这与我们组在 temporal logic + RL 方面的多项工作高度相关。

2. **Safety 约束的融入**：目前 FB π-Switch 没有显式的安全性保证。能否在 low-level policy 的执行层面加入 CBF (control barrier function) 或 safety filter？Switching 发生时的安全性过渡（safety during mode switching）是一个值得探讨的问题。

3. **从 goal-conditioned 到 specification-conditioned**：本文强调了超越 goal-reaching 的能力。如果将 reward function 替换为 temporal logic specification 的 quantitative semantics（如 STL robustness），是否可以实现 zero-shot specification satisfaction？这可能是一个有价值的后续研究方向。

## 参考文献

- Stojanovic, S., & Proutiere, A. (2026). Switching Successor Measures for Hierarchical Zero-shot Reinforcement Learning. *arXiv:2605.13207*. https://arxiv.org/abs/2605.13207
- Touati, A., & Ollivier, Y. (2023). Does Zero-Shot Reinforcement Learning Exist? https://arxiv.org/abs/2209.14935
- Park, S., et al. (2023). HIQL: Offline Goal-Conditioned RL with Latent States as Actions. *ICML 2023*.
- Agarwal, R., et al. (2024). Proto Successor Measure: Representing the Behavior Space of an RL Agent. https://arxiv.org/abs/2411.19418
- Sutton, R. S., Precup, D., & Singh, S. (1999). Between MDPs and semi-MDPs: A framework for temporal abstraction in reinforcement learning. *Artificial Intelligence*.
- Nachum, O., et al. (2018). Data-Efficient Hierarchical Reinforcement Learning (HIRO). *NeurIPS 2018*.
- Farebrother, J., et al. (2026). Compositional Planning with Jumpy World Models.
- 项目主页：https://stestokth.github.io/switching-successors/
