# Inductive Deductive Synthesis: Enabling AI to Generate Formally Verified Systems — 调研报告

> 生成日期：2026-05-25 | Reading List Monitor
> 论文来源：arxiv（近期预印本，确切 ID 尚未被搜索引擎收录；作者来自 UC Berkeley / Google / UC Santa Cruz）

## 1. 问题背景与研究动机

随着大语言模型（LLM）在代码生成领域的能力不断提升，"vibe coding"——即基于自然语言描述直接生成代码——已经成为业界常态。然而，LLM 生成的代码通常缺乏正确性保证，在安全关键系统（如分布式系统、并发程序、CPS 控制器等）中，这种不确定性是不可接受的。

传统的 formal verification 方法（如 deductive synthesis）可以提供数学层面的正确性证明，但对用户的形式化规约能力要求极高，且自动化程度有限。另一方面，inductive synthesis（如 CEGIS——counterexample-guided inductive synthesis）通过从示例中学习来降低规约门槛，但在处理复杂系统规约时仍存在可扩展性问题。

本文的核心思想是将这两种互补的 synthesis 范式统一起来：利用 LLM 的归纳推理能力（从大量代码和文档中学习的模式识别）与演绎推理系统（形式化验证器、定理证明器）的严格保证相结合，实现 AI 驱动的、带有形式化正确性保证的系统生成。

本文作者团队横跨 UC Berkeley 的 Sky Computing Lab（Ion Stoica, Matei Zaharia, Sylvia Ratnasamy, Aditya Parameswaran 等系统领域顶尖学者）、Google Research（Tomas Pfister, Chun-Liang Li, Rui Meng）以及 UC Santa Cruz 的 Mohsen Lesani（形式化验证领域专家，POPL/PLDI/CAV 常客），这种跨领域的作者组合本身就反映了该工作将 AI 系统与形式化方法深度融合的定位。

## 2. 技术方法

虽然论文全文尚未完全公开（可能为极近期的预印本），根据标题和作者背景推断，该工作很可能采用以下技术路线：

**Inductive 阶段**：利用 LLM（或基于 LLM 的 agent）从自然语言规约、示例或已有代码库中归纳生成候选程序和不变量。这一步骤类似于 oracle-guided inductive synthesis (OGIS) 框架中的 learner 角色。

**Deductive 阶段**：将生成的候选方案提交给形式化验证器（如 Dafny、Lean 或 Verus 的验证后端），进行演绎推理验证。验证失败时产生的 counterexample 反馈给 inductive 模块，形成 CEGIS 式的迭代循环。

**系统级关注**：区别于现有工作主要聚焦于单个函数或算法的验证，本文从标题看强调的是"Systems"层面——这可能涉及分布式协议、并发数据结构或多组件系统的验证。这与 Lesani 在 Chapar (POPL'16)、Hamsaz (POPL'19) 等工作中的分布式系统验证经验，以及 Berkeley 团队在 SkyDiscover 框架（AI 驱动的科学与算法发现）上的积累高度一致。

从分类信息（cs.AI, cs.DC, cs.LO, cs.PL）也可以看出，该工作横跨 AI、分布式计算、逻辑和编程语言四个方向，进一步佐证了其在"系统验证+AI"交叉领域的定位。

## 3. 研究前沿与意义

AI 辅助形式化验证是 2025-2026 年的热门方向，有多项标志性进展：

- **Vericoding** 概念在 POPL 2026 被正式提出，区别于"vibe coding"，强调从形式规约生成经过验证的代码。相关 benchmark 涵盖 Lean、Dafny、Verus 等验证语言。
- **AlphaVerus** 实现了 LLM 生成 Verified-HumanEval 33% 题目的通过率，展示了自改进翻译框架的潜力。
- **DeepSeek-Prover-V2**、**Harmonic Aristotle** 等系统在 Lean 定理证明上取得了显著进步。
- Martin Kleppmann 等人公开预测 "AI will make formal verification go mainstream"。

活跃的研究组包括：UC Berkeley（Seshia 的 Sciduction/OGIS 框架、Stoica/Zaharia 的 Sky Lab）、MIT（Chlipala 的 Coq 验证）、CMU（Solar-Lezama 的 Sketch 框架）、Microsoft Research（Dafny 生态）、Google DeepMind（AlphaProof）等。

主要发表 venue：POPL、PLDI、CAV、OOPSLA（PL/verification 侧）；NeurIPS、ICML、ICLR（AI/ML 侧）；NSDI、SOSP、OSDI（systems 侧）。

## 4. 相关工作

1. **Sciduction: Combining Induction, Deduction, and Structure for Verification and Synthesis** (Seshia et al., 2012/2015)
   - 提出了 SID 框架，将 inductive inference、deductive reasoning 和 structure hypotheses 统一用于验证与综合。本文可以视为在 LLM 时代对 Sciduction 思想的继承和发展。

2. **SEVerA: Verified Synthesis of Self-Evolving Agents** (Lesani 等, arxiv 2603.25111, 2026)
   - 同一作者（Lesani）的近期工作，提出 Formally Guarded Generative Models (FGGM)，用一阶逻辑为 LLM 的每次生成调用指定输出合约。与本文可能在技术上有密切关联。

3. **Towards AI-Assisted Synthesis of Verified Dafny Methods** (arxiv 2402.00247)
   - 展示 LLM 在 Dafny 验证代码生成上的可行性，代表了 AI 辅助形式化验证的早期探索。

4. **AlphaVerus: Bootstrapping Formally Verified Code Generation through Self-Improving Translation and Treefinement** (arxiv 2412.06176)
   - 提出自改进框架，通过迭代翻译和 tree search 实现验证代码生成，在 Verified-HumanEval 上达到 33% 通过率。

5. **An Inductive Synthesis Framework for Verifiable Reinforcement Learning** (Zhu et al., PLDI 2019)
   - 将神经网络验证问题框架化为 counterexample-guided inductive synthesis，结合不变量生成。虽然应用在 RL 领域，但其 CEGIS 循环思想与本文的 inductive-deductive 结合高度相关。

## 5. 组会讨论要点

1. **与 CPS 验证的潜在联系**：如果该框架能生成经过形式化验证的分布式协议或控制器代码，是否可以扩展到 CPS 安全性证明（如 barrier certificate 的自动生成与验证）？与我们组现有的 formal methods + RL/control 方向是否有结合点？

2. **Inductive-Deductive 循环的效率问题**：LLM 生成 → 验证器拒绝 → 反馈修正的循环在复杂系统上可能需要大量迭代。如何设计高效的 counterexample 利用策略？是否可以借鉴我们在 STL/LTL specification 上的经验来构造更有信息量的反馈？

3. **可信度边界**：即使代码经过形式化验证，规约本身是否正确仍需人工判断。在 CPS 场景下，如何确保 LLM 辅助生成的规约与实际物理约束一致？这是否可以通过 conformal prediction 等统计方法来提供额外保障？

## 参考文献

- Seshia, S. A. (2015). Sciduction: Combining Induction, Deduction, and Structure for Verification and Synthesis. *Proceedings of the IEEE*. https://arxiv.org/abs/1201.0979
- SEVerA: Verified Synthesis of Self-Evolving Agents. arxiv 2603.25111. https://arxiv.org/abs/2603.25111
- Towards AI-Assisted Synthesis of Verified Dafny Methods. arxiv 2402.00247. https://arxiv.org/abs/2402.00247
- AlphaVerus: Bootstrapping Formally Verified Code Generation. arxiv 2412.06176. https://arxiv.org/abs/2412.06176
- Zhu, H. et al. (2019). An Inductive Synthesis Framework for Verifiable Reinforcement Learning. *PLDI 2019*. https://arxiv.org/abs/1907.07273
- A benchmark for vericoding: formally verified program synthesis. *POPL 2026 / Dafny 2026*. https://arxiv.org/abs/2509.22908
