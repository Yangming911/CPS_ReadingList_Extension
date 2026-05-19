# Synthesizing POMDP Policies: Sampling Meets Model-checking via Learning — 调研报告

> 生成日期：2026-05-19 | Reading List Monitor
> 论文来源：[arXiv:2605.14440](https://arxiv.org/abs/2605.14440)
> 作者：Debraj Chakraborty, Anirban Majumdar, Prince Mathew, Sayan Mukherjee, Jean-François Raskin
> 提交日期：2026-05-14
> 会议：CAV 2026（第38届 International Conference on Computer Aided Verification，里斯本）

## 1. 问题背景与研究动机

Partially Observable Markov Decision Processes (POMDPs) 是不确定性下决策的标准框架，但其策略综合（policy synthesis）面临根本性的两难困境：

- **基于采样的方法**（如 POMCP、DESPOT）具有良好的可扩展性，但缺乏形式化的正确性保证，不适用于安全关键应用。
- **形式化综合方法**提供 correctness-by-construction 保证，但面临可扩展性瓶颈——一般性的 POMDP 综合问题是不可判定的（undecidable）。

本文的核心贡献是提出了一个**将采样、自动机学习（automata learning）和 model checking 三者整合的综合框架**，以 Angluin 的 L* 算法为灵感，利用采样作为 membership oracle、model checking 作为 equivalence oracle，从而能够综合出具有形式化保证的 finite-state controller (FSC)。该框架在采样诱导的策略是 regular 的前提下，建立了相对完备性（relative completeness）结果。

## 2. 技术方法

论文的技术框架巧妙地将三个传统上独立的方法论统一起来：

**L* 学习框架的适配**：经典的 L* 算法通过 membership query 和 equivalence query 交互式地学习一个未知的 regular language。本文将这一范式适配到 POMDP 策略综合问题中：
- **Membership oracle**：通过对 POMDP 的采样（simulation）来回答"某个 observation-action 序列是否属于目标策略"的查询。
- **Equivalence oracle**：通过 model checking 来验证当前学习到的 FSC 是否满足给定的形式化规约（如 threshold-safety 性质）。如果不满足，model checker 返回反例用于进一步学习。

**Finite-State Controller 综合**：学习过程的输出是一个 FSC，它本质上是一个 deterministic finite automaton (DFA)，将 observation 历史映射到动作选择。FSC 的有限状态结构使得后续的 model checking 变得可行。

**形式化保证**：论文证明了该框架的 relative completeness——如果目标策略确实是 regular 的（即可以被某个 FSC 实现），那么算法在有限步内会收敛到一个满足规约的 FSC。

实验结果表明，该方法成功求解了对现有形式化综合工具（如 PAYNT、Storm）仍具挑战性的 threshold-safety 问题。

## 3. 研究前沿与意义

POMDP 策略综合是形式化方法和 AI 规划领域的核心问题。近年来，这一领域呈现出几个重要趋势：

- **学习与形式化方法的融合**：越来越多的工作尝试结合机器学习的可扩展性和形式化方法的正确性保证，本文正是这一趋势的代表。
- **FSC 作为可解释策略表示**：相比于神经网络策略，FSC 具有可解释性和可验证性，是 safety-critical 场景的理想选择。

本文被 CAV 2026 接收，CAV 是形式化验证领域的顶级会议。活跃的研究组包括 Université libre de Bruxelles 的 Jean-François Raskin 组（自动机理论与博弈论）、Masaryk University 的 POMDP 验证组（PAYNT 工具的开发者）。其他相关 venue 包括 TACAS、AAAI、IJCAI、FM 等。

## 4. 相关工作

1. **Inductive Synthesis of Finite-State Controllers for POMDPs** (Andriushchenko et al., 2022, arXiv:2203.10803) — 提出了基于归纳综合的 FSC 构造方法，使用命题逻辑公式符号化表示设计空间，通过冲突驱动的剪枝加速搜索。与本文的区别在于不使用采样，直接在模型上搜索，因此可扩展性受限。

2. **Supervisor Synthesis of POMDP based on Automata Learning** (Wang et al., 2017/2021, arXiv:1703.08262) — 同样基于 L* 算法的 POMDP 监督控制综合框架，使用 DFA 作为控制器形式。本文在此基础上引入了 model checking 作为 equivalence oracle，提供了更强的形式化保证。

3. **Finite-State Controllers for (Hidden-Model) POMDPs using Deep Reinforcement Learning** (arXiv:2602.08734, 2026) — Lexpop 方法，使用深度 RL 训练神经策略后通过自动机学习提取 FSC。与本文互补：Lexpop 先学习再提取，本文在学习过程中就保持形式化保证。

4. **1-2-3-Go! Policy Synthesis for Parameterized MDPs via Decision-Tree Learning** (arXiv:2410.18293, 2024) — 通过在小实例上 model checking 获得最优策略，再用决策树学习泛化到大实例。思路与本文类似地结合了学习和 model checking，但针对的是完全可观察的参数化 MDP。

5. **Model-Based Learning of Near-Optimal Finite-Window Policies in POMDPs** (arXiv:2604.01024, 2026) — 基于有限窗口的模型学习方法，提供样本复杂度保证。与本文的形式化保证类型不同（PAC-style vs. correctness-by-construction）。

## 5. 组会讨论要点

1. **L* 算法的 membership oracle 依赖采样，那么采样效率对整体框架的可扩展性影响如何？** 对于大规模 POMDP，采样可能需要大量 simulation 来获得可靠的 membership 判断。是否有 active sampling 策略可以加速这一过程？

2. **"策略是 regular"这一前提假设在实际中是否过强？** 许多实际最优策略可能需要无限记忆（即非 regular），此时框架只能保证找到近似解。是否可以扩展到 ω-regular 或 pushdown 自动机策略类？

3. **本文与我们组在 LTL-based RL 和 temporal logic planning 方面的工作有直接联系。** 特别是对于 POMDP 场景下的 temporal logic 规约满足问题，本文提供了一个有形式化保证的综合方案。值得探索的方向：能否将该框架与基于 temporal logic 的 reward shaping 方法结合？

## 参考文献

- Chakraborty, D., Majumdar, A., Mathew, P., Mukherjee, S., & Raskin, J.-F. (2026). Synthesizing POMDP Policies: Sampling Meets Model-checking via Learning. arXiv:2605.14440. https://arxiv.org/abs/2605.14440
- Andriushchenko, R. et al. (2022). Inductive Synthesis of Finite-State Controllers for POMDPs. arXiv:2203.10803. https://arxiv.org/abs/2203.10803
- Wang, Y. et al. (2017). Supervisor Synthesis of POMDP based on Automata Learning. arXiv:1703.08262. https://arxiv.org/abs/1703.08262
- Carr, S. et al. (2026). Finite-State Controllers for (Hidden-Model) POMDPs using Deep Reinforcement Learning. arXiv:2602.08734. https://arxiv.org/abs/2602.08734
- Raskin, J.-F. et al. (2024). 1-2-3-Go! Policy Synthesis for Parameterized MDPs via Decision-Tree Learning. arXiv:2410.18293. https://arxiv.org/abs/2410.18293
