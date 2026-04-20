# Trajectory Planning for Safe Dual Control with Active Exploration — 调研报告

> 生成日期：2026-04-21 | Reading List Monitor
> 论文来源：[arXiv:2604.15507](https://arxiv.org/abs/2604.15507)（Naveed, Singh, Agrawal, Panagou, April 2026）

## 1. 问题背景与研究动机

在模型参数存在不确定性的前提下规划安全轨迹，是机器人与自主控制长期以来的核心难题。常见做法是 **robust planning**，即以参数不确定集合的最坏情形作为设计基准（tube MPC、robust CBF、contraction-based planner 等），从而在闭环中保持 safety。这类方法虽然给出了 recursive feasibility 与 forward invariance 的形式化保证，但有两个代价：其一，轨迹被长期钉死在保守的 tube 中心；其二，系统不会主动利用执行过程中的数据去降低不确定度，因此 conservativeness 无法随时间收敛。

与之相对的思路是 **dual control**：控制器在完成 nominal 任务的同时，主动注入 exploration，使得 posterior 在线变窄。传统 dual control 一般把"information gain"作为目标函数中的加权项（weighted trade-off），但这带来两个新问题——(i) information term 与 safety constraint 之间的权衡是启发式的，缺乏 formal guarantee；(ii) 无限制的 exploration 会让系统显著偏离 nominal 任务，违反 mission-level 的性能预算。

Naveed 等人把上述张力形式化为一个 **budget-constrained dual control problem**：在确保 safety 的前提下，最大化参数不确定度的在线收缩量，同时把 exploration 所带来的 nominal 任务代价增量约束在一个显式 budget $B_{\text{exp}}$ 之内。本文核心贡献是提出 **Dual-gatekeeper** 框架，将 exploration 视为一个**可验证**（verifiable）的决策而非目标函数的一项：候选 informative policy 只有当其 safety 可以被 certify、且 predicted exploration cost 不超过 budget 时才被采纳；否则 fall back 到 robust baseline。作者对 quadrotor navigation 和 autonomous car racing 两个场景做了验证。

## 2. 技术方法

Dual-gatekeeper 沿袭了 Panagou 组 2024 年 T-RO 上提出的 **gatekeeper** 范式（Agrawal, Chen, Panagou, T-RO 40:4358–4375, 2024）——即通过在 nominal planner 下游插入一个 verification layer，用 finite-horizon numerical forward propagation 构造 recursively safe 的 committed trajectory，将局部安全性放大为 all-time safety。Dual-gatekeeper 的关键扩展在于让 committed trajectory 不仅 safe，还能"informative"。

**核心构件：**

- **Robust backup policy**（Definition 7）：一条在参数不确定集合的最坏情形下仍保持 safety 的 fallback policy，作为无论何时 explore 失败都能 retreat 到的 anchor。
- **Candidate segment pair**（Definitions 8–10）：每个 planning step 把候选轨迹拆分为 *conservative segment*（保守段，safety 直接由 robust backup 保证）+ *informative segment*（探索段，主动激励 parameter estimator）。informative segment 可能带来更大的 tracking error 或更激进的控制量，因此需要单独 certify。
- **Validity check**（Definition 11）：对每个 candidate 做两层检查——(i) safety 验证：informative segment 的 reachable set 是否仍落在 $\mathcal{S}$ 内、是否能 smoothly 接回 robust backup；(ii) budget 验证：该 candidate 相对 conservative baseline 的 *predicted* cost 增量是否在剩余 exploration budget 之内。两项都通过，才被采纳执行。
- **Uncertainty shrinkage prediction**：候选 informative segment 期望带来的 parameter uncertainty 收缩量用两种方式估计——simulation-based rollouts（Algorithm 1，对 nonlinear 动力学更 general）以及基于 regressor matrix 的 data-consistency 分析（Section V-B，对 affine-in-parameter 系统给出 closed-form bound）。

**Safety 机制两种实例化：**

1. **Tube MPC instantiation**（Section VI）：nominal trajectory 走 tube 中心，安全由 tightened constraints 保证，informative exploration 体现为允许轨迹在 tube 内做受约束的 persistent-excitation 式扰动。
2. **Gatekeeper filter instantiation**（Section VII）：nominal mission policy 与 safety verification 解耦，任意 policy（包括 learning-based）经过 gatekeeper certification 后才下发，informative candidates 在 certification 失败时被自动替换为 robust backup。

**形式化保证（Theorem 1）：**

在给定参数不确定集合、bounded disturbance 与若干 regularity 假设下，Dual-gatekeeper 同时给出——
(i) **Closed-loop safety for all time**：$x(t)\in\mathcal{S}(t),\ u(t)\in\mathcal{U},\ \forall t\geq t_0$；
(ii) **Budget feasibility**：$\sum_k \Delta \mathcal{J}^k_{\text{exp}}\leq B_{\text{exp}}$。

相较作者早期工作（Naveed 2025，finite-horizon 版本），本文的理论进步在于把 backup 的 finite-horizon 要求推广到 infinite-horizon setting，从而在长 mission 中无需反复重建完整 horizon backup。

## 3. 研究前沿与意义

Safe dual control / safe active exploration 在过去两三年是 CPS 与机器人控制交叉领域的热门方向，判断依据：

- **venue 分布**：T-RO、Automatica、CDC、L4DC、RA-L、ICRA 几乎每届都有多篇相关论文；ICRA 和 CoRL 连年有"Learning-based safe control"专题 workshop；CDC 2024/2025 有"Safe learning and control"的 invited session。
- **活跃研究组**：University of Michigan（Panagou 组，gatekeeper 系列）、Stanford ASL（Pavone 组，conformal + MPC）、ETH Zürich（Zeilinger 组，tube MPC、adaptive MPC）、UT Austin（Topcu 组，formal methods for safe RL）、UC Berkeley（Fisac 组，shielding-aware dual control）。
- **相关论文密度**：arXiv 上仅 2025–2026 年就出现多篇同类工作，如 *Dual MPC for Active Learning of Nonparametric Uncertainties* (2511.08542)、*Gaussian Process Dual MPC using Active Inference* (2512.15381)、*A Formal gatekeeper Framework for Safe Dual Control* (2510.06351)、*Dual Control for Interactive Autonomous Merging with Model Predictive Diffusion* (2502.09918)。

本文在这一谱系中的位置是：将 *exploration-as-verifiable-decision* 作为新范式，与主流的 *exploration-as-weighted-objective*（Barcelos, Parsi, Luo 等）形成鲜明对比，同时把 Panagou 组 gatekeeper 的 certification 机制自然扩展到 active learning 场景。它在 theoretical rigor（all-time safety + budget feasibility）与 practical flexibility（既能套 tube MPC，又能套 gatekeeper filter）之间提供了一个相对干净的折中。

## 4. 相关工作

1. **gatekeeper: Online Safety Verification and Control for Nonlinear Systems in Dynamic Environments**（Agrawal, Chen, Panagou, *IEEE T-RO* 40:4358–4375, 2024；[arXiv:2211.14361](https://arxiv.org/abs/2211.14361)）
   本文方法学的直接前身。gatekeeper 是一个在 nominal planner 与 feedback controller 之间的 online verification layer，通过 recursively constructing safe committed trajectories 来保证 all-time safety。Dual-gatekeeper 沿用其 verification 思路，但将"safe"的要求升级为"safe + informative + budget-compliant"。区别：原始 gatekeeper 默认参数已知且不主动利用数据收缩 uncertainty；Dual-gatekeeper 显式处理 parametric uncertainty 并把 exploration 纳入 verification loop。

2. **Active Uncertainty Reduction for Safe and Efficient Interaction Planning: A Shielding-Aware Dual Control Approach**（Hu, Isele, Bae, Fisac, *IJRR* 43(7), 2024；[arXiv:2302.00171](https://arxiv.org/abs/2302.00171)）
   处理的问题接近——human-robot interaction 中的 dual control，通过 active uncertainty reduction 提高交互效率，同时以 shielding 保证 safety。区别：Hu et al. 把 exploration 作为 soft objective 加权，并用 backup shield 兜底；Dual-gatekeeper 把 exploration 当 hard constraint 下的 verifiable candidate，不再依赖权重调参。此外，前者聚焦 interaction-level uncertainty（其他 agent 的 intent），本文聚焦 plant-level parametric uncertainty。

3. **Dual MPC for Active Learning of Nonparametric Uncertainties**（2025；[arXiv:2511.08542](https://arxiv.org/abs/2511.08542)）
   同期互补工作。用 GP posterior covariance 做 information proxy，在 caution（约束 tightening）与 exploration（driving 到高 covariance 区域）之间做 soft trade-off，处理 *nonparametric* uncertainty。区别：方法论偏向 Bayesian / nonparametric，safety 通过 probabilistic chance constraint 而非 deterministic certification；本文聚焦 *parametric* uncertainty 的 set-based 处理，safety 是 worst-case 意义下的 hard guarantee。

4. **A Formal gatekeeper Framework for Safe Dual Control with Active Exploration**（2025；[arXiv:2510.06351](https://arxiv.org/abs/2510.06351)）
   同作者组的早期/并行技术报告，与本文在概念上重合但内容更聚焦于 Formal Methods 风格的证明结构。可作为 Theorem 1 证明细节的补充参考。

5. **Adaptive Tube MPC with Persistent Excitation / Adaptive Tube-Based MPC for Parametric Uncertainty**（Lorenzen et al., *Automatica* 2020; Gonçalves & Aguirre 综述文献）
   代表传统 adaptive tube MPC 思路：利用 persistent excitation 在线收缩 parameter set，tube 随 set 收缩而收紧。与本文的关联：Dual-gatekeeper 的 Tube MPC instantiation 在概念上与 adaptive tube MPC 同源；关键区别是本文显式引入 *budget constraint* 限定 exploration 的代价，而 adaptive tube MPC 通常不对 excitation 的 task cost 做 bounding。

## 5. 组会讨论要点

1. **Verifiable exploration 的代价与可扩展性。**
   Dual-gatekeeper 的 verification 依赖 reachable set / uncertainty shrinkage 的在线估计。对于 high-dimensional 系统（比如 manipulator + 环境交互），Algorithm 1 的 simulation-based rollout 成本是否可接受？是否需要 learned surrogate（neural reachability、data-driven ROA）来替代精确 forward propagation？这与我们组在 neural CBF / conformal reachability 方向可以结合。

2. **Budget 的经济学 vs. 信息论解读。**
   论文把 $B_{\text{exp}}$ 定义为 excess predicted cost，但 budget 是随任务 unfold 动态消耗的。这是否可以反向设计：给定一个期望的 posterior 收缩率，推导所需的最小 budget？或者把 budget 动态分配看作 multi-armed bandit 下的 information-cost trade-off，与 Bayesian experimental design / information bottleneck 理论对接？

3. **与 conformal / distribution-free safety 结合。**
   当 parametric uncertainty 的刻画本身来自 learning-based estimator（而非 a priori box bound），Dual-gatekeeper 的 worst-case safety 是否仍成立？一个可能扩展是用 conformal prediction 给参数集合加上 PAC guarantee，然后再送进 gatekeeper verification，这与组里 conformalized reachability / CP-based MPC 的方向是天然契合点，可以考虑作为后续扩展实验。

## 参考文献

- Naveed, K. B.; Singh, M.; Agrawal, D. R.; Panagou, D. *Trajectory Planning for Safe Dual Control with Active Exploration.* arXiv:2604.15507, April 2026. https://arxiv.org/abs/2604.15507
- Agrawal, D. R.; Chen, R.; Panagou, D. *gatekeeper: Online Safety Verification and Control for Nonlinear Systems in Dynamic Environments.* *IEEE Transactions on Robotics* 40:4358–4375, 2024. https://arxiv.org/abs/2211.14361
- Hu, H.; Isele, D.; Bae, S.; Fisac, J. F. *Active Uncertainty Reduction for Safe and Efficient Interaction Planning: A Shielding-Aware Dual Control Approach.* *IJRR*, 2024. https://arxiv.org/abs/2302.00171
- *Dual MPC for Active Learning of Nonparametric Uncertainties.* arXiv:2511.08542, 2025. https://arxiv.org/abs/2511.08542
- *A Formal gatekeeper Framework for Safe Dual Control with Active Exploration.* arXiv:2510.06351, 2025. https://arxiv.org/abs/2510.06351
- *Gaussian Process Dual MPC using Active Inference: An Autonomous Vehicle Usecase.* arXiv:2512.15381, 2025. https://arxiv.org/abs/2512.15381
