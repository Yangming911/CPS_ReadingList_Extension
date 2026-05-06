# Value Functions for Temporal Logic: Optimal Policies and Safety Filters — 调研报告

> 生成日期：2026-05-07 | Reading List Monitor
> 论文来源：arXiv:2605.01051 (2026-05-01) | https://arxiv.org/abs/2605.01051
> 作者：Oswin So 等（共 4 名作者）

## 1. 问题背景与研究动机

针对 reach、avoid、reach-avoid 三类基本目标的 Bellman 方程已经被研究得很透彻——HJ reachability、CBF 与 RL 中的 *value iteration* 都对这类目标有成熟工具。然而，一旦把目标推广到一般的 **temporal logic (TL)** 规约（如 LTL 的 nested Until、Globally、Globally-Until 组合），无折扣无限时段下"value optimal"与"policy optimal"之间的关系就变得微妙：即使 value function 是最优的，对其贪心 (greedy) 得到的 policy 也未必能完成任务——存在一类 pathological policy 会**无限期地推迟**任务完成而保持 value 不变（因为无限时段、无折扣下"今天满足"和"明天满足"对 reach 类目标的 value 完全相等）。

本文即针对这一长期被忽视的"value-optimal 但 policy 不可用"问题，给出严格刻画并提出修复方案。研究动机有两条：(i) 把 Bellman 形式的 RL/optimal control 工具完整地推广到 TL 任务，弥补"reach/avoid 之外几乎没有可证最优算法"的空白；(ii) 把 Q function 不仅用于求解任务，还用作复杂 TL 规约的 **safety filter**，从而在已部署的非 TL-aware 控制器之外提供一个轻量级的"TL 监督器"。

## 2. 技术方法

文章的核心技术贡献分两部分：

**(a) Non-Markovian policy construction for TL optimality.** 作者证明：对 nested Until / Globally / Globally-Until 这类组合规约，仅依赖当前状态的 Markov policy 即使取 value-greedy 也可能失败；他们构造一类**基于状态历史**（具体是当前 sub-formula 的 progression 状态）的 non-Markovian policy，证明其相对于**定量鲁棒性 (quantitative robustness) score** 是最优的。所谓 quantitative robustness，是把 STL/LTL 规约的离散满足关系替换为连续的 robustness 值（类似 STL 的 robust semantics），这样 value function 就能传达"还差多少能满足"的信息，而不仅是 0/1。

**(b) Q function as TL safety filter.** 给定一个由其它机制（RL、MPC、人类）输出的候选 action，作者定义"TL safety filter"为：若候选 action 会使 quantitative robustness 的 Q value 显著下降到不可接受阈值之下，则替换为 Q-greedy action。该思路把已有 reach-avoid safety filter（HJ-based、CBF-based）推广到任意 TL 规约，理论上能涵盖 *Bellman Value Decomposition for Task Logic in Safe Optimal Control*（已在 reading list 上）等工作的 unifying view。

方法论上，文章重度依赖 LTL/STL progression（formula rewriting）、quantitative semantics、以及 max-plus / supremum-Bellman 算子的不动点性质。证明思路对组里熟悉 STL/LTL 的同学非常友好。

## 3. 研究前沿与意义

把 TL 与 value-based RL 结合是 CPS-AI 交叉的核心方向，过去五年涌现了大量工作（*Reward Machines*, *LTL2Action*, *DeepSynth*, *Skrynnik et al. 2023*, …），但这些工作多数关注 LTL→reward 的设计，而非"value optimality 与 policy optimality 是否一致"这一更基础的问题。本文把后者作为主线，理论密度较高，预计将成为该方向的 reference 之一。

热度评估：相关 venue 包括 NeurIPS / ICML 的 safe RL 与 formal methods track、CDC / L4DC / HSCC / FoSSaCS / CAV 的形式化方法 track。活跃团队包括 Penn (Pappas, Tabuada)、MIT (Belta — 已退休但学派延续, Slotine, Roy)、UCB (Tomlin)、CMU (Kara), Northwestern (Fan), Oxford (Kwiatkowska), Caltech (Murray, Ames), 以及 RL 侧的 DeepMind / Toronto (Toro Icarte) / Cambridge (Aknine)。本文 first author Oswin So 此前在 LTL-RL 与 Lyapunov-based learning 方向有连续产出，本文延续这一线索。

常见 venue 包括 NeurIPS、ICML、ICLR、CDC、L4DC、CoRL、AAAI、IJCAI；期刊侧 *IEEE T-AC*、*Automatica*、*JAIR* 也接收此类工作。

## 4. 相关工作

- **Bellman Value Decomposition for Task Logic in Safe Optimal Control**（已在 reading list 上）。把 task logic 规约分解为子 value function 求和的工作，与本文 Q-function-based safety filter 在思想上同源；本文则更系统地解决了 policy-vs-value optimality 这一 foundational 问题。
- **Universal Safety Controllers with Learned Prophecies**（已在 reading list 上）。用 prophecy 变量补全 LTL 完整可观测性，与本文 non-Markovian policy 的 history-augmentation 思路相通。
- **Deep Policy Optimization with Temporal Logic Constraints** (arXiv:2404.11578)。把 TL 约束直接注入 policy gradient，是本文 value-based 路线的对偶；本文给出的反例表明纯 policy gradient 也可能受同类 pathology 影响。
- **Conformal Signal Temporal Logic for Robust Reinforcement Learning Control: A Case Study** (arXiv:2602.14322)。把 conformal prediction 与 STL RL 结合，可作为本文 safety filter 在不确定性下推广的潜在方向。
- **Safe and Optimal Learning from Preferences via Weighted Temporal Logic with Applications in Robotics and Formula 1** (arXiv:2511.08502)。从偏好学习角度重新定义 weighted TL，与本文 quantitative robustness 是不同的连续化方案，可对照讨论。

## 5. 组会讨论要点

1. **Quantitative robustness 的选择敏感度**：本文的 value function 直接挂在 quantitative robustness 上，但 STL 文献中存在多种 robustness 定义（Donzé–Maler, AGM, Time-Aware 等）。这些定义对 value 的 well-definedness、policy 最优性结论是否仍然成立？若不同 robustness 给出不同 optimal policy，"哪一个是真正的最优"就需要重新审视。
2. **Non-Markovian policy 的可学习性**：理论上构造的 non-Markovian policy 依赖 formula progression state（指数级增长）。在实际 RL 训练中如何把这一 augmented state 高效编码进 neural policy？是否需要类似 *Reward Machine* 的紧凑自动机表示？这与组里在 LTL-conditioned RL 方向的工作可直接合作。
3. **Safety filter 的部署形态**：把 Q function 作为通用 TL safety filter 是吸引人的工程主张，但 Q 的训练成本通常远高于 control synthesis 本身。能否设计一个"轻量级 safety filter"——例如只需 sub-formula level 的 Q，再通过 compositional 方式拼接——以降低部署门槛？这与组里 *Combinatorial Control Barrier Functions* 等组合性工作有共鸣。

## 参考文献

1. So, O. *et al.* *Value Functions for Temporal Logic: Optimal Policies and Safety Filters.* arXiv:2605.01051, 2026. https://arxiv.org/abs/2605.01051
2. *Deep Policy Optimization with Temporal Logic Constraints.* arXiv:2404.11578. https://arxiv.org/html/2404.11578v1
3. *Conformal Signal Temporal Logic for Robust Reinforcement Learning Control.* arXiv:2602.14322. https://arxiv.org/html/2602.14322
4. *Temporal Logic Specification-Conditioned Decision Transformer for Offline Safe RL.* arXiv:2402.17217. https://arxiv.org/html/2402.17217
5. *Safe and Optimal Learning from Preferences via Weighted Temporal Logic.* arXiv:2511.08502. https://arxiv.org/abs/2511.08502
6. *Towards Safe Autonomous Intersection Management: Temporal Logic-based Safety Filters for Vehicle Coordination.* arXiv:2408.14870. https://arxiv.org/html/2408.14870
