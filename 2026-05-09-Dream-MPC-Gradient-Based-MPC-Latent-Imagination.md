# Dream-MPC: Gradient-Based Model Predictive Control with Latent Imagination — 调研报告

> 生成日期：2026-05-09 | Reading List Monitor
> 论文来源：[OpenReview (ICLR 2026 submission)](https://openreview.net/forum?id=uhoCh3pViS)
> 作者：匿名（Under Review）
> 项目主页：https://dream-mpc.github.io/

## 1. 问题背景与研究动机

Model-based reinforcement learning (MBRL) 中，Model Predictive Control (MPC) 与学习的 world model 相结合已成为主流范式。其中，TD-MPC 系列方法使用 policy network 生成动作候选，再通过 gradient-free 的采样优化方法（如 CEM 或 MPPI）在 latent space 中进行轨迹优化。

然而，gradient-free 方法的核心问题在于：需要采样大量（数百甚至数千条）动作序列才能找到好的解，在高维控制任务中计算开销显著。一个自然的替代方案是使用 gradient-based optimization，但已有研究实证表明 gradient-based 方法往往不如 gradient-free 方法——原因包括容易陷入局部最优、以及通过长 horizon 的 world model 反向传播时出现的梯度爆炸/消失问题。

Dream-MPC 的贡献在于系统性地解决了 gradient-based MPC 的上述缺陷，使其不仅能匹配而且能超越 gradient-free MPC 的性能。

## 2. 技术方法

Dream-MPC 的核心思路是：从 policy network rollout 中生成少量候选轨迹，然后用 gradient ascent 对每条轨迹进行优化。具体包含三个关键设计：

1. **Policy prior + local optimization**：不从随机分布采样（如 CEM），而是从学习好的 policy 出发，生成少量（而非大量）候选动作序列。每条序列再用 gradient ascent 局部优化。这相当于将 policy 作为 warm start，避免了 gradient-based 方法从差的初始点出发陷入局部最优的问题。

2. **Uncertainty regularization**：在优化目标中直接加入不确定性正则化项。World model 在远离训练数据的区域预测不准确，gradient-based 优化容易 exploit 这些不准确区域。通过惩罚 world model 的预测不确定性，约束优化轨迹停留在模型可靠的区域。

3. **Amortized optimization**：在时间维度上复用之前优化过的动作。由于相邻时间步的最优动作序列高度相关，可以用前一步的优化结果作为当前步的初始值，减少每步所需的优化迭代次数。

实验覆盖了 DeepMind Control Suite、Meta-World 和 HumanoidBench 共 24 个环境，Dream-MPC 集成到 TD-MPC2 和 BMPC 后均展现出显著的性能提升。此外，在使用视觉观测（image-based observations）的设置下也优于 MPPI。

## 3. 研究前沿与意义

Model-based RL 中的 planning 方法选择是一个持续的研究热点：

- **TD-MPC2**（Hansen et al., 2024）是当前 MBRL 的代表性工作，使用 MPPI 进行 gradient-free planning，在 104 个连续控制任务上表现出色。
- **DreamerV3**（Hafner et al., 2025）采用另一种范式：用 world model 的 rollout 直接训练 policy network，不在测试时做 planning。
- **BMPC**（Wang et al., 2025）在 TD-MPC2 基础上引入 imitation learning，进一步提升了 planning 效果。
- Gradient-based planning 此前被认为不如 gradient-free 方法，Dream-MPC 的工作挑战了这一共识。

本文的意义在于重新验证了 gradient-based MPC 在 latent space 中的可行性，为 MBRL 中的 planning 提供了新的设计选择。

常见发表 venue：ICLR, NeurIPS, ICML, CoRL。

## 4. 相关工作

1. **TD-MPC2: Scalable, Robust World Models for Continuous Control** (Hansen et al., 2024, arXiv:2310.16828)
   - 当前 MBRL 的基准方法之一，Dream-MPC 直接在其框架上集成和评估。
   - 关键区别：TD-MPC2 使用 MPPI（gradient-free），Dream-MPC 替换为 gradient-based optimization。

2. **BMPC** (Wang et al., 2025)
   - TD-MPC2 的扩展，通过 imitation learning 学习 MPC planner 的行为。
   - Dream-MPC 集成到 BMPC 后替换其 MPPI planner，效果更优。

3. **DreamerV3: Mastering Diverse Domains through World Models** (Hafner et al., 2025)
   - 纯 policy-based 的 MBRL 方法，不在测试时做 planning。
   - Dream-MPC 也在 Dreamer 框架上进行了集成实验，发现在训练时启用 planning 可以提升 sample efficiency。

4. **Dream to Control: Learning Behaviors by Latent Imagination** (Hafner et al., 2019, arXiv:1912.01603)
   - Dreamer 系列的起源，首次提出在 latent space 中通过 imagination 学习行为策略。
   - Dream-MPC 的名称致敬了该工作，但方法上从 policy learning 转向 MPC。

5. **TD-M(PC)²: Improving Temporal Difference MPC Through Policy Constraint** (ICLR 2025)
   - 通过 policy constraint 改善 TD-MPC 的 off-policy 数据利用。
   - 与 Dream-MPC 互补：前者改善数据利用，后者改善优化方法。

## 5. 组会讨论要点

1. **Gradient-based vs. gradient-free 的适用边界**：Dream-MPC 在 BMPC 上的提升比在 TD-MPC2 上更一致，作者指出这是因为 gradient-based MPC 需要好的初始 proposal。这意味着在什么条件下应该选择 gradient-based 方法？Policy prior 的质量是否是关键因素？

2. **Safety constraint 的集成**：Gradient-based MPC 天然适合加入梯度可计算的约束（如 differentiable CBF）。相比 MPPI 这类 sampling-based 方法，Dream-MPC 框架是否更容易融入安全约束？这与组内关于 safe MPC 的研究方向有直接关联。

3. **Uncertainty regularization 的局限性**：作者用 world model 的 ensemble disagreement 来估计不确定性。这种估计在 out-of-distribution 场景下是否可靠？是否可以引入 conformal prediction 等方法来提供更严格的不确定性量化？

## 参考文献

- Anonymous. (2025). Dream-MPC: Gradient-Based Model Predictive Control with Latent Imagination. Submitted to ICLR 2026. https://openreview.net/forum?id=uhoCh3pViS
- Hansen, N., et al. (2024). TD-MPC2: Scalable, Robust World Models for Continuous Control. arXiv:2310.16828. https://arxiv.org/abs/2310.16828
- Hafner, D., et al. (2025). Mastering Diverse Domains through World Models (DreamerV3). 
- Hafner, D., et al. (2019). Dream to Control: Learning Behaviors by Latent Imagination. arXiv:1912.01603. https://arxiv.org/abs/1912.01603
- Wang, et al. (2025). BMPC. arXiv:2503.18871. https://arxiv.org/abs/2503.18871
- Project website: https://dream-mpc.github.io/
