# On-the-fly LTLf Synthesis under Partial Observability — 调研报告

> 生成日期：2026-05-14 | Reading List Monitor
> 论文来源：arxiv 2508.04116 (A Compositional Framework for On-the-Fly LTLf Synthesis) — ECAI 2025；另见 arxiv 2009.10875 (LTLf Synthesis under Partial Observability)

## 1. 问题背景与研究动机

Reactive synthesis（反应式综合）是指从形式化规约自动生成满足给定性质的控制策略或程序的过程。当规约用 Linear Temporal Logic over finite traces (LTLf) 表达时，综合问题可以归约为一个两人博弈（two-player game），其中系统（protagonist）与环境（antagonist）交替行动，系统的目标是无论环境如何行动都能满足 LTLf 规约。

这一综合问题的核心计算瓶颈在于：需要将 LTLf 公式转化为确定性有限自动机（DFA），而这一步骤在最坏情况下的复杂度是 2EXPTIME-complete。当考虑 partial observability（部分可观测性）——即系统无法直接观测环境的全部状态——时，问题复杂度进一步提升至 2EXPTIME 甚至 3EXPTIME。

**现有方法的两种范式**：
1. **Compositional 方法**：先将 LTLf 公式分解为子公式，分别构造 DFA，再通过自动机运算组合。优势在于可利用 minimization 减小状态空间，劣势在于组合后的 DFA 可能仍然很大。
2. **On-the-fly（增量式）方法**：在博弈求解过程中按需构造 DFA，避免完整的 DFA 构造。优势在于只需探索可达状态，劣势在于无法利用 minimization。

本文的核心贡献在于提出了一个**组合式 on-the-fly 综合框架**，将两种范式的优势整合：在博弈求解过程中执行组合操作，既能利用 pruning 简化后续组合，又能通过 on-the-fly 方式避免完整 DFA 构造。当与 partial observability 结合时，这一框架有潜力解决此前因状态空间爆炸而无法处理的实例。

## 2. 技术方法

**问题形式化**：
- 输入：一组 LTLf 公式的合取 φ = φ₁ ∧ φ₂ ∧ ... ∧ φₙ（实际应用中常见的规约形式）
- 输出：一个反应式策略（如果可实现）或不可实现性证明
- 在 partial observability 下，系统只能观测到环境状态的部分投影

**组合式 On-the-fly 框架的关键技术**：

1. **分步组合（Incremental Composition）**：不一次性构造所有子公式的 product DFA，而是在博弈求解过程中逐步引入子公式的 DFA 并进行组合。每次组合后，对中间结果进行 pruning（剪枝）。

2. **两种组合变体**：
   - **先剪枝后组合（Prune-then-compose）**：先对当前中间结果进行 minimization，再与下一个子 DFA 组合。充分利用自动机最小化的优势。
   - **边组合边剪枝（Compose-with-pruning）**：在组合过程中同时进行剪枝，利用 on-the-fly 的思路引导组合方向，避免探索不可达状态。

3. **早期不可实现性检测（Early Unrealizability Detection）**：在部分子公式组合后即可判断规约是否不可实现，避免对所有子公式进行完整处理。

4. **Partial Observability 扩展**：在 partial observability 下，博弈从普通的两人博弈变为不完全信息博弈（imperfect-information game）。系统需要基于观测历史（而非真实状态）做出决策，这要求在 DFA 上的 belief-state 空间求解，复杂度显著增加。组合式 on-the-fly 方法在此场景下的优势更加明显，因为 belief space 的状态爆炸问题更为严重。

**实验结果**（基于 arxiv 2508.04116）：
- 框架被集成到 LydiaSyft 工具中
- 在标准 benchmark 上，能够求解大量其他 state-of-the-art solver（如 Strix、ltlsynt）无法处理的实例
- 两种组合变体各有适用场景，无绝对优劣

## 3. 研究前沿与意义

LTLf synthesis 是 formal methods 与 AI 交叉的一个经典且活跃的研究方向：

**热度指标**：
- SYNTCOMP（Reactive Synthesis Competition）每年举办，LTLf synthesis 是其中的重要赛道
- ECAI 2025、AAAI 2025、KR 2025 等 AI 顶会均接收了 LTLf synthesis 相关论文
- LTLf 与强化学习（RL）的结合是近年的热点（如 reading list 中已有的多篇相关论文）

**主要竞争方法**：
- Strix：基于 LTL（infinite trace）的 parity game solver，工程优化成熟
- ltlsynt：SPOT 工具套件中的 synthesis solver
- LydiaSyft：专门针对 LTLf 的组合式 symbolic synthesis 工具（本文框架的基础）
- Nike：基于 BDD 的 LTLf synthesis

**活跃研究组**：
- 华东师范大学（Geguang Pu, Jianwen Li 组）——本文作者
- Sapienza University of Rome（Giuseppe De Giacomo 组）——LTLf synthesis 的奠基性工作
- Rice University（Moshe Vardi 组）——formal methods 领域的领军人物
- University of Oxford（Foundations of Self-Programming Agents 课程组）

**常见发表 venue**：AAAI, IJCAI, ECAI, KR, CAV, TACAS, ATVA。

## 4. 相关工作

1. **"LTLf Synthesis under Partial Observability: From Theory to Practice"** (arxiv 2009.10875, Bansal & Giacomo 等)
   - 首次将 LTLf synthesis 系统性地扩展到 partial observability 设定
   - 与本文的关联：提供了 partial observability 下 LTLf synthesis 的理论框架和复杂度分析
   - 关键区别：未采用 on-the-fly 技术，DFA 构造是完整的

2. **"LydiaSyft: A Compositional Symbolic Synthesis Framework for LTLf"** (TACAS 2025, Zhu & Favorito)
   - 实现了完全组合式的 LTLf synthesis 工具，递归处理子公式并通过自动机运算组合
   - 与本文的关联：本文框架的基础工具平台
   - 关键区别：LydiaSyft 在博弈求解前完成全部 DFA 构造和组合，而本文在求解过程中执行组合

3. **"Hybrid Compositional Reasoning for Reactive Synthesis from Finite-Horizon Specifications"** (AAAI 2020, Bansal & Li 等, arxiv 1911.08145)
   - 提出混合状态表示（explicit + symbolic）用于 LTLf-to-DFA 转换
   - 与本文的关联：同为组合式 LTLf synthesis 的重要前驱工作
   - 关键区别：组合发生在 DFA 构造阶段，而非博弈求解阶段

4. **"Emerson-Lei and Manna-Pnueli Games for LTLf+ and PPLTL+ Synthesis"** (KR 2025)
   - 将 LTLf synthesis 推广到 LTLf+ 和 PPLTL+，使用 Emerson-Lei 博弈求解
   - 与本文的关联：同为 2025 年的 LTLf synthesis 新工作，探索不同的博弈求解策略
   - 关键区别：关注规约语言的扩展，而非求解框架的优化

5. **"LTLf Synthesis Under Unreliable Input"** (AAAI 2025, arxiv 2412.14728)
   - 考虑输入信号不可靠（unreliable）时的 LTLf synthesis
   - 与本文的关联：同为处理不完美信息下的 LTLf synthesis
   - 关键区别：不可靠输入（可能丢失或错误）vs 部分可观测性（只能观测子集）

## 5. 组会讨论要点

1. **与 RL + temporal logic 路线的互补性**：我们 reading list 中已有大量 RL + LTL/LTLf 的工作（如 PlatoLTL、Zero-Shot Instruction Following via LTL 等）。Synthesis-based 方法提供了完备性保证（如果可实现则一定能找到策略），而 RL 方法可扩展到更大的状态空间但缺乏完备性。两种路线能否在实际系统中互补——synthesis 提供安全骨架，RL 在骨架内优化性能？

2. **On-the-fly 方法的实际瓶颈**：虽然 on-the-fly 方法避免了完整 DFA 构造，但在 partial observability 下 belief space 的大小仍然可能是 doubly exponential。这一框架能处理的实际规约大小上限是多少？是否有启发式剪枝策略可以进一步提升可扩展性？

3. **与 CPS 安全验证的联系**：LTLf synthesis 产出的策略天然满足形式化规约，可以视为一种"正确 by construction"的安全保证。相比于 post-hoc 的 safety filter 或 CBF 方法，这种方法的优势和适用场景是什么？在实际机器人系统中，规约是否足够精确以使 synthesis 结果直接可用？

## 参考文献

- Li, Y., Xiao, S., Zhu, S., Li, J., & Pu, G. "A Compositional Framework for On-the-Fly LTLf Synthesis", ECAI 2025. arxiv 2508.04116. https://arxiv.org/abs/2508.04116
- Bansal, S., Li, Y., Tabajara, L.M., & Vardi, M.Y. "LTLf Synthesis under Partial Observability: From Theory to Practice", 2020. arxiv 2009.10875. https://arxiv.org/abs/2009.10875
- Zhu, S. & Favorito, M. "LydiaSyft: A Compositional Symbolic Synthesis Framework for LTLf", TACAS 2025.
- Bansal, S. & Li, Y. et al. "Hybrid Compositional Reasoning for Reactive Synthesis from Finite-Horizon Specifications", AAAI 2020. arxiv 1911.08145. https://arxiv.org/abs/1911.08145
- "LTLf Synthesis Under Unreliable Input", AAAI 2025. arxiv 2412.14728. https://arxiv.org/abs/2412.14728
- "Emerson-Lei and Manna-Pnueli Games for LTLf+ and PPLTL+ Synthesis", KR 2025.
