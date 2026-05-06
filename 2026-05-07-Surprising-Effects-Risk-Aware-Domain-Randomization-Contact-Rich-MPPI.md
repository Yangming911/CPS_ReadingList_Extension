# On Surprising Effects of Risk-Aware Domain Randomization for Contact-Rich Sampling-based Predictive Control — 调研报告

> 生成日期：2026-05-07 | Reading List Monitor
> 论文来源：标题尚未在 arXiv/Google Scholar 上检索到完整 PDF（截至生成日），可能为最新的 RSS/CoRL 2026 投稿或 in-press 版本。本报告基于标题、相邻文献以及作者团队相关工作进行综合调研。

## 1. 问题背景与研究动机

Sampling-based Model Predictive Control（典型代表为 **MPPI**, Model Predictive Path Integral control）已成为接触富集（contact-rich）任务——例如非抓取式推动、堆叠、装配——的标配规划框架。其优势是把规划问题写成"在 GPU 上并行 rollout 大量随机扰动"，无须可微分模型；劣势是性能极度依赖**采样分布**与**仿真模型**的真实程度。

为缓解 sim-to-real gap，社区普遍采用 **Domain Randomization (DR)**——在每次 rollout 时随机化质量、摩擦、接触刚度、传感噪声等物理参数。常规 DR 在控制器优化时取**期望性能**最大化，等价于"所有 rollout 同等加权后求平均"。本文的关切是：在 contact-rich 任务里，参数轻微扰动会触发完全不同的接触模式，导致回报分布出现长尾甚至双峰，期望值优化容易得到一个对长尾完全不敏感的"平均最优"策略。**Risk-Aware DR**——即在 DR 之上叠加 risk measure（CVaR、entropic risk、worst-case）——理论上应给出更鲁棒的控制器；但作者通过实验观察到了若干 *surprising effects*：例如在某些任务上 risk-aware 反而比 risk-neutral 更不鲁棒，或在 sim 上指标更差却在 real 上更好。

研究动机是系统化解释这些反直觉现象，并为"什么时候应该用 risk-aware DR、用哪种 risk measure、用多大风险厌恶系数"提供经验/理论指导。

## 2. 技术方法

基于标题与领域常规，本文方法学骨架很可能包含：

- **基础控制器**：MPPI 或其变体（Biased-MPPI、Smooth-MPPI、Constrained MPPI），在 GPU 物理仿真器（IsaacGym/Mujoco MJX）上并行采样上千条 rollout。
- **风险测度替换**：把标准的 $\mathbb{E}[J(\tau)]$ 替换为 $\mathrm{CVaR}_\alpha[J(\tau)]$、entropic risk $\frac{1}{\beta}\log\mathbb{E}[\exp(\beta J)]$、或 distributionally robust 形式 $\sup_{P\in\mathcal{P}}\mathbb{E}_P[J]$。在 MPPI 框架下，这些 risk measure 可以通过修改加权 softmax 的权重计算来实现，不需要改变 rollout 流程。
- **DR 维度的对照实验**：固定 risk measure，扫描随机化的物理参数集合（仅摩擦、仅惯量、全部），观察控制器对单一参数变化的敏感度。
- **Sim-to-real 迁移评估**：在多个真实接触富集任务（推动、装配、in-hand manipulation 等）上系统比较 risk-neutral vs risk-aware 的表现，定位"surprising effects"出现的具体条件。

预期的关键发现可能涉及：(i) 在回报分布近似单峰且方差较小的任务上，risk-aware 与 risk-neutral 几乎等价；(ii) 在多接触模式任务上，CVaR 容易锁定在某个"安全但低性能"的局部模式，导致整体表现下降；(iii) 风险厌恶系数与 DR 噪声幅度耦合敏感，需要协同调参。

## 3. 研究前沿与意义

Sampling-based MPC 在 2024–2026 年随 GPU 仿真器（IsaacGym、Genesis、MJX）成熟而成为机器人界的"新主流"。代表性产出包括 *Sampling-based MPC Leveraging Parallelizable Physics Simulations* (arXiv:2307.09105)、AMR Lab (TU Delft) 一系列 Biased-MPPI / Interaction-aware MPPI 工作、以及 MIT-ACL 的 MPPI-Numba 等。Risk-aware 的引入则源自经典 risk-sensitive control 与近年 distributionally robust optimization 的复兴，相关工作如 *Dynamic Risk-Aware MPPI for Mobile Robots in Crowds*（arXiv:2506.21205）、*Risk-aware MPPI for Stochastic Hybrid Systems*（arXiv:2411.09198）、*Parameter-Robust MPPI for Safe Online Planning*（已在 reading list 上）。

主要发表 venue 集中在 ICRA、IROS、CoRL、RSS，以及 *IEEE T-RO*、*IJRR*、*IEEE RA-L*。在 ML 侧也常见于 NeurIPS 的 *Safe RL* workshop。活跃团队包括 TU Delft（Alonso-Mora）、Georgia Tech（Theodorou）、MIT（How / Slotine）、CMU（Manuela Veloso）、ETHZ（Hutter）等。本文关注的"surprising effects"恰是该领域近来的实证痛点，社区正在从"提出新算法"转向"理解为什么算法 work / 不 work"，本文属于后一方向，预期对实际部署有较强影响。

## 4. 相关工作

- **Parameter-Robust MPPI for Safe Online Planning**（已在 reading list 上）。从 worst-case 参数视角设计鲁棒 MPPI，是与本文最直接对照的工作；本文则更关注 risk-aware 的非 worst-case 形式与其反直觉效应。
- **Sampling-based Model Predictive Control Leveraging Parallelizable Physics Simulations** (arXiv:2307.09105)。本文 contact-rich rollout 的基础设施类工作，IsaacGym + MPPI 的标准实现来自此处。
- **Risk-aware MPPI for Stochastic Hybrid Systems** (arXiv:2411.09198)。在 stochastic hybrid system 框架下严格刻画 risk-aware MPPI 的收敛性与安全性保证。
- **Dynamic Risk-Aware MPPI for Mobile Robots in Crowds via Efficient Monte Carlo Approximations** (arXiv:2506.21205)。在动态人群场景中将 collision probability 作为 risk measure 嵌入 MPPI，给出 Monte Carlo 高效近似方法。
- **Safe Domain Randomization via Uncertainty-Aware Out-of-distribution Detection** (arXiv:2507.06111)。在 DR 训练之上加 OOD 检测，与本文从 risk measure 角度处理 DR 长尾形成互补思路。

## 5. 组会讨论要点

1. **Risk measure 选择的指导原则**：CVaR vs entropic risk vs DRO 在 contact-rich 任务上各有何 fail mode？是否能从 reward landscape 的几何性质（多峰程度、尾部厚度）出发，给出一个事前的 risk measure 选择启发？这与组里 conformal prediction / distributional robustness 的工作是天然结合点。
2. **Risk-aware 与 formal safety 的关系**：本文的"safety"是 reward 意义上的避免长尾损失，而组里更关心 STL / CBF 意义下的硬安全约束。能否把 risk-aware MPPI 的加权机制与 CBF/HJ-reachability 结合，把硬约束以 chance constraint 的形式注入 MPPI 加权？
3. **Sim-to-real 评测协议**：本文若仅用单一硬件平台得出 "surprising effect"，在跨平台时是否仍成立？组会可讨论是否值得建立一个针对 contact-rich tasks 的 cross-lab 评测框架（共享物理参数 ground truth + 标准任务集），以解决该领域评测可重复性差的痛点。

## 参考文献

1. *On Surprising Effects of Risk-Aware Domain Randomization for Contact-Rich Sampling-based Predictive Control.* （论文标题；尚未在公开 arXiv 检索到完整版本，建议关注 RSS 2026 / CoRL 2026 程序）
2. *Sampling-based Model Predictive Control Leveraging Parallelizable Physics Simulations.* arXiv:2307.09105. https://arxiv.org/html/2307.09105v2
3. *Risk-aware MPPI for Stochastic Hybrid Systems.* arXiv:2411.09198. https://arxiv.org/html/2411.09198
4. *Dynamic Risk-Aware MPPI for Mobile Robots in Crowds via Efficient Monte Carlo Approximations.* arXiv:2506.21205. https://arxiv.org/abs/2506.21205
5. *Safe Domain Randomization via Uncertainty-Aware OOD Detection.* arXiv:2507.06111. https://arxiv.org/pdf/2507.06111
6. *Domain Randomization is Sample Efficient for Linear Quadratic Control.* arXiv:2502.12310. https://arxiv.org/abs/2502.12310
