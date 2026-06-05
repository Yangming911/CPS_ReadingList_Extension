# Reinforcement Learning for Reachability: Guaranteeing Asymptotic Optimality — 调研报告

> 生成日期：2026-06-01 | Reading List Monitor
> 论文来源：未能在公开网络检索到该确切标题（可能为尚未被索引的最新预印本或在投稿件）。本报告基于标题语义与该子领域的近期文献撰写，相关方法定位与对比均有出处可循；待原文可获取后建议复核技术细节。

## 1. 问题背景与研究动机

reachability analysis 是 CPS 与安全控制的核心工具：给定一组目标集（target set）与障碍集（avoid set），reach-avoid 问题要刻画出 reach-avoid set——即存在控制策略，能在最坏扰动下安全抵达目标的初始状态集合。经典做法是求解 Hamilton-Jacobi (HJ) 偏微分方程 / 变分不等式（HJVI），其 value function 的零水平集恰好给出 reachable/reach-avoid set。HJ 方法理论上严格，但基于网格的求解器受 curse of dimensionality 限制，难以扩展到高维系统。

近年来 learning-based reachability 成为主流替代：用 RL / 神经网络逼近 reachability value function，从而处理高维、甚至 model-free 的场景（如 Fisac 等的 Safety Bellman Equation、Hsu 等的 reach-avoid Q-learning、Yu 等的 Reachability Constrained RL）。然而这类方法的一个长期痛点正是**理论保证的缺失**：RL 训练得到的 value function 是否真的收敛到真实的 reachability value？在什么意义下"最优"？很多工作只能给出局部最优（local optimum）或保守近似（conservative approximation），缺乏对**渐近最优性（asymptotic optimality）**的刻画。

本文标题中的"Guaranteeing Asymptotic Optimality"正是切入这一缺口。其核心问题应是：**设计一个用于 reachability/reach-avoid 计算的 RL 算法，并从理论上证明其在适当极限下（典型如 discount factor γ→1、迭代次数→∞、或样本量→∞）收敛到真实的 reachability value function / reach-avoid set，即渐近最优。** 这弥补了"可扩展但无保证"与"有保证但不可扩展"之间的鸿沟。

需要重点关注的难点在于：reach-avoid 问题的 Bellman backup 不是标准的 sum-of-rewards 形式，而是 min/max 嵌套（reach 取 max-over-time，avoid 取 min-over-time），其 time-discounted 版本的 contraction 性质与折扣因子和真实（undiscounted）reachability 之间存在 gap。把这个 gap 在 γ→1 时压到零，正是"asymptotic optimality"需要技术处理的核心。

## 2. 技术方法

根据标题与该领域通行做法，本文方法论应包含以下要素（具体形式待原文核实）：

**(1) Discounted reach-avoid Bellman 算子。** 将 reach-avoid value function 写成带折扣的 Bellman 递推形式（time-discounted reach-avoid Bellman backup），借助折扣因子 γ 使算子成为 contraction mapping，从而保证 Q-learning 类迭代收敛到唯一不动点。这是 Fisac et al. (Safety Bellman Equation) 与 Hsu et al. 的标准技巧。

**(2) 渐近最优性证明。** 关键贡献应是证明：当 γ→1 时，折扣不动点收敛到真实（undiscounted）reach-avoid value function，其零水平集收敛到真实 reach-avoid set。可能用到的工具包括：算子的单调性与 contraction 常数随 γ 的标度关系、Blackwell optimality（策略对所有足够接近 1 的折扣因子均最优）、以及 multi-time-scale stochastic approximation（如 RCRL 所用）来处理 actor-critic 的耦合收敛。

**(3) 与函数逼近的结合。** 为支撑高维可扩展性，value function 通常用神经网络参数化。这里"asymptotic optimality"可能进一步扩展为：在 tabular / 精确表征下严格成立，在神经网络逼近下给出 conservative 近似或概率性保证（类似 Conservative Q-Learning 把 super-zero level set 作为 reach-avoid set 的保守内逼近）。

**(4) 算法形式。** 很可能是一个 model-free 的 actor-critic 或 value-iteration 变体，配合特定的目标/障碍奖励塑形（reward shaping），并在训练中退火 γ（γ-annealing）以逼近 undiscounted 极限——这是把"渐近"落地为可执行算法的常见手段。

理论保证的核心命题预期为：*在标准 MDP/游戏假设下，所提算法产生的 value 序列以概率 1 收敛到 discounted reach-avoid 不动点，且该不动点随 γ→1 收敛到真实 reach-avoid value*——即兼具算法层面（迭代收敛）与问题层面（折扣→无折扣）的双重渐近最优。

## 3. 研究前沿与意义

HJ reachability × RL 是当前安全控制领域**极为活跃**的交叉方向，证据充分：

- 2024 年出现了专门的综述《Hamilton-Jacobi Reachability in Reinforcement Learning: A Survey》(arXiv:2407.09645)，标志该方向已成体系。
- 2026 年仍有持续产出，如《Formalizing the Relationship between Hamilton-Jacobi Reachability and Reinforcement Learning》(arXiv:2601.08050)、《Certifying Hamilton-Jacobi Reachability Learned via Reinforcement Learning》(arXiv:2602.16475)、以及面向应用的《Interacting safely with cyclists using HJ reachability and RL》(arXiv:2602.18097)。
- 主要竞争/相关方法谱系：Fisac et al. 的 Safety Bellman Equation（time-discounted safety）、Hsu et al. 的 reach-avoid Q-learning（ICRA/RSS 系）、Yu et al. 的 Reachability Constrained RL (ICML 2022)、Ganai et al. 的 Iterative Reachability Estimation / RESPO (NeurIPS 2023)，以及 Lipschitz-continuous value function 的 certifiable reachability learning (arXiv:2408.07866)。
- 活跃研究组：UC Berkeley（Claire Tomlin / Jaime Fisac 一系，现 Princeton）、Stanford、CMU 等在 HJ reachability 与 safe RL 上长期深耕。

常见发表 venue：会议方面有 NeurIPS、ICML、ICLR、CoRL、RSS、ICRA、L4DC、CDC、HSCC；期刊方面有 T-RO、IEEE T-AC、Automatica。本文若理论保证扎实，定位上很契合 L4DC / CDC / NeurIPS 这类强调"learning + 理论保证"的场子。

本文的意义在于：把 learning-based reachability 从"经验上 work、缺乏保证"推进到"有渐近最优性证明"，这对安全攸关（safety-critical）系统的可信部署是实质性的——只有当学到的 value function 能被证明逼近真实 reach-avoid set，才能放心地把它用作 safety filter 或 verification 工具。

## 4. 相关工作

1. **Bridging Hamilton-Jacobi Safety Analysis and Reinforcement Learning（Safety Bellman Equation）— Fisac, Lugovoy, Rubies-Royo, Ghosh, Tomlin (ICRA 2019)。** 提出 time-discounted safety Bellman backup，使 HJ safety value 可由收敛的 Q-learning 求得。本文很可能直接继承其 discounted-contraction 框架，并将"safety/reach-avoid"与"γ→1 的渐近最优性"做更彻底的理论刻画——关联紧密，区别在于本文强调 asymptotic optimality 的显式保证而非仅收敛到 discounted 不动点。

2. **Safety and Liveness Guarantees through Reach-Avoid Reinforcement Learning — Hsu, Rubies-Royo, Tomlin, Fisac (RSS 2021, arXiv:2112.12288)。** 推导 reach-avoid Bellman backup 并证明 reach-avoid Q-learning 收敛，给出 reach-avoid set 的保守近似。与本文解决同类问题，区别可能在于本文进一步把"保守近似"收紧为"渐近精确"，或对函数逼近下的最优性 gap 给出定量界。

3. **Reachability Constrained Reinforcement Learning — Yu, Ma, et al. (ICML 2022, arXiv:2205.07536)。** 用 multi-time-scale stochastic approximation 证明算法收敛到 local optimum 且能保证最大可行集。与本文互补：RCRL 关注"约束满足下的奖励最优"，本文关注"reachability value 本身的渐近最优"；二者可能共享 stochastic approximation 的收敛分析工具。

4. **Iterative Reachability Estimation for Safe RL (RESPO) — Ganai et al. (NeurIPS 2023, arXiv:2309.13528)。** 通过 reachability estimation function 在随机环境中维持可行集内的持久安全，理论上收敛到局部最优。与本文同属"reachability + 收敛保证"，区别在于 RESPO 偏 constrained-RL 框架与最小累计违规，本文更偏纯 reach-avoid value 的精确逼近。

5. **Certifiable Reachability Learning Using a New Lipschitz Continuous Value Function（arXiv:2408.07866）。** 通过 Lipschitz 连续 value function 为学到的 reachability 提供确定性安全证书。与本文目标一致（给 learning-based reachability 加保证），路线不同：该工作用 Lipschitz 正则 + 后验 certification，本文（据标题）走渐近最优性的收敛分析路线，二者可视为"certification"与"asymptotic exactness"两种互补的保证范式。

## 5. 组会讨论要点

1. **折扣 gap 与 γ-annealing 的实际代价。** 渐近最优性通常依赖 γ→1，但 γ 越接近 1，contraction 越弱、训练越不稳定、样本复杂度越高。值得讨论：本文是否给出收敛速率（rate）而不仅是渐近结论？γ→1 与神经网络逼近误差之间是否存在权衡？这直接关系到方法在我们关心的高维 CPS 上是否真正可用。

2. **与函数逼近下"保证退化"的关系。** 严格的渐近最优性多在 tabular 设定下成立，一旦引入神经网络，是变成概率性保证、保守内逼近，还是完全失去保证？这与我们组在 conformal / certificate 方向的工作（如把学到的 value 当作 barrier/safety filter）能否衔接——能否用本文的渐近最优 value 作为 conformal calibration 的基准量？

3. **可作为 safety filter 的可信度。** 如果 value function 只在渐近意义下最优，在有限训练预算下其零水平集会偏保守还是偏激进（safety-critical 场景下激进=危险）？建议跟进的实验：在已知解析 reach-avoid set 的低维 benchmark（如 double integrator、Dubins car）上量化收敛误差，再外推到高维，评估其作为 runtime safety filter 的可靠性。

## 参考文献

- [Reachability Constrained Reinforcement Learning (Yu et al., ICML 2022)](https://arxiv.org/abs/2205.07536)
- [Safety and Liveness Guarantees through Reach-Avoid Reinforcement Learning (Hsu et al., RSS 2021)](https://arxiv.org/pdf/2112.12288)
- [Iterative Reachability Estimation for Safe Reinforcement Learning / RESPO (Ganai et al., NeurIPS 2023)](https://arxiv.org/pdf/2309.13528)
- [Certifiable Reachability Learning Using a New Lipschitz Continuous Value Function](https://arxiv.org/pdf/2408.07866)
- [Hamilton-Jacobi Reachability in Reinforcement Learning: A Survey (2024)](https://arxiv.org/html/2407.09645v1)
- [Formalizing the Relationship between Hamilton-Jacobi Reachability and Reinforcement Learning (2026)](https://arxiv.org/html/2601.08050v1)
- [Certifying Hamilton-Jacobi Reachability Learned via Reinforcement Learning (2026)](https://arxiv.org/html/2602.16475v1)
- [Infinite-Horizon Reach-Avoid Zero-Sum Games via Deep Reinforcement Learning](https://arxiv.org/pdf/2203.10142)

*备注：本报告所列方法定位基于标题语义与近邻文献推断。该确切标题未在公开渠道检索到，建议在拿到原文（arXiv 或会议版）后核对其 Bellman 算子形式、渐近最优性定理的精确陈述与假设条件，再据此更新第 2、5 节。*
