# Formal Specification Embeddings for Neuro-Symbolic Autonomy — 调研报告

> 生成日期：2026-06-05 | Reading List Monitor
> 论文来源：[OpenReview PDF](https://openreview.net/pdf?id=AUUPc6vBGd) ｜ AAMAS 2026（第 25 届 Autonomous Agents and Multiagent Systems 国际会议，Paphos, Cyprus, May 25–29, 2026），6 页
> 作者：Beyazit Yalcinkaya, Marcell Vazquez-Chanlatte, Sanjit A. Seshia（UC Berkeley + Nissan ATC）

## 1. 问题背景与研究动机

本文研究 reinforcement learning（RL）中如何把 **formal specification（形式化规范）嵌入为可供策略条件化的连续表征**，以同时获得"形式化正确性保证"与"跨任务泛化"两个通常相互冲突的目标。

研究动机来自两条路线长期的割裂。一方面，formal specification（如 LTL、reward machines、可组合规范语言）因具有良定义的 operational semantics、对 long-horizon 时序目标的简洁编码以及 compositional 结构，被广泛用于定义 RL 任务，并能为学到的策略提供 correctness guarantee；但已有方法要么局限于**单一固定目标**（augmented state space 上做 reward shaping，难以泛化），要么依赖在规范诱导出的 automaton 上做 **symbolic planning / goal-conditioned 路径跟随**，因策略 myopia 导致 **sub-optimal** 行为。另一方面，foundation model 时代流行用 natural language 与 demonstration 作为指令模态，借助 pretrained text/image embedding 学习 task-conditioned policy，泛化性与可扩展性好，但这些模态本身**语义模糊**（自然语言有多义、示范可能次优或冲突），因而**牺牲了形式化正确性保证**。

本文（及作者前序 RAD Embeddings 工作）的核心诉求，是在这两者之间架桥：学习一种**可证明正确（provably correct）的预训练 automata embedding**，使条件于该 embedding 的策略既保留形式化语义的正确性保证，又具备跨大类任务的泛化与最优性。需要说明：本文是一篇 6 页的 overview/综述性质论文，系统性地串联并陈述作者此前在 NeurIPS 2024、NeuS 2025、多智能体 CoRR 2025 等处提出的 RAD Embeddings 框架及其应用。

## 2. 技术方法

**任务表示：DFA 与 DFA space。** 任务用 Deterministic Finite Automaton（DFA）表示。论文假设接受是吸收的（一旦接受前缀，后缀不改变接受判定），并通过最小化得到规范形式。关键概念是 **DFA space** D：给定一组 DFA，其在所有有限字 progression（读入 word 后再 minimize）下闭包形成的空间。智能体被给定任务 A 后，须学会执行 A 的所有 sub-DFA，即在 DFA space 中导航到接受态 DFA A⊤。

**正确性定义（基于 bisimulation）。** 编码器 Ψ: D → Z 被称为 *provably correct*，当且仅当对任意 A, A′，Ψ(A)=Ψ(A′) ⇔ A 与 A′ bisimilar。bisimilar 的 DFA 语言相同、代表同一任务，因此正确编码器必须是关于 bisimulation 的结构保持映射——把"语义相同"的任务映到同一 embedding，把"语义不同"的任务区分开。

**训练方法：automata bisimulation game。** 作者把学习正确编码器转化为求解一个单人 Markov game：状态是 DFA 对 (A, A′)，动作是共享字母表 Σ 中的符号，转移是同步 progression (A/σ, A′/σ)，reward 为 r(A,σ)−r(A′,σ)（命中接受态 +1、拒绝态 −1、否则 0）。value function 直接定义为两个 DFA **归一化 embedding 的欧氏距离** V(A,A′)=‖Ψ(A)/‖Ψ(A)‖ − Ψ(A′)/‖Ψ(A′)‖‖，并以 Bellman backup 学习。由于该 V 满足非负、对角为零、对称、三角不等式，它构成 latent space 上的 **pseudometric / bisimulation metric**——V(A,A′)=0 当且仅当两 DFA bisimilar，从而最优编码器 Ψ* 自动满足正确性定义。直观上，策略在一回合内生成一段"证据串"来证明两个 DFA 不 bisimilar。

**先验任务分布：ReachAvoidDerived (RAD) DFAs。** 由于 DFA space 虽有限但极大、无法枚举，作者用一个生成式先验分布 ι_D 采样训练样本：从一串 one-step Reach / ReachAvoid 子问题出发，对 stuttering 符号小概率扰动，再做若干次随机 mutate（改变 transition、令接受态为 sink、minimize），得到比 Reach、ReachAvoid、Parity、ReachAvoidRedemption 等任务类更丰富的结构。经验上，在 RAD DFA 上训练的策略能泛化到其它任务类（单/多智能体均验证）。

**编码器架构：GATv2 图注意力网络。** 把 DFA 表示为图（节点=状态，边=转移；节点特征 one-hot 编码 initial/accepting/rejecting；边特征编码字母约束），用带边特征的 GATv2 做 message passing。对 n 状态 DFA 做 n 步消息传递，保证初始状态节点聚合到全图信息，最终取初始状态节点的特征向量作为该任务的 embedding。对 Boolean 组合（如 k 个 DFA 合取会指数膨胀），引入特殊的 conjunction 语法节点避免显式构造组合 DFA。

**下游应用与理论收益。** 得到 provably correct 编码器后，可把"DFA 上的问题"等价重写为"RAD Embedding 上的问题"，从而**解耦表征学习与控制学习**，提升 sample efficiency。两个落地场景：(i) **AC-RL**（Automata-Conditioned RL）——目标 J(π)=Pr[A/L(τ)=A⊤]，条件于整个 DFA（而非诱导自动机的某个状态）以克服 goal-conditioned 的 myopia，再改为条件于 RAD Embedding 仍保最优；(ii) **ACC-MARL**（Automata-Conditioned Cooperative MARL）——每个 agent 分配一个 DFA，去中心化策略条件于全体 agent 的 RAD Embeddings，目标是满足所有 DFA 的合取，借 embedding 的唯一性保证团队最优。

## 3. 研究前沿与意义

specification-guided RL 与 automata-conditioned RL 是近年 formal methods × RL 交叉的活跃方向。证据包括 reward machines（Toro Icarte et al., JAIR 2022）、LTL2Action（Vaezipoor et al., ICML 2021）、Discounted-LTL policy synthesis（Alur et al., CAV 2023）、LTL-Constrained Policy Optimization（Shah et al., TMLR 2025）等持续产出，发表集中在 NeurIPS / ICML / ICLR（学习侧）、CAV / IJCAI（形式化侧）以及 AAMAS / CoRL（智能体与机器人侧，本文即 AAMAS 2026）。

本文所属的"automata embedding"子方向，主要竞争/对照方法有三类：(i) 单目标 specification→reward 路线（Sadigh et al. CDC 2014、Shah et al. TMLR 2025），保证强但不泛化；(ii) automaton 上 symbolic planning + goal-conditioned 路线（Jothimurugan et al. NeurIPS 2021；Qiu, Mao, Zhu NeurIPS 2023），泛化但因 myopia 次优；(iii) 指令 embedding 路线（LTL2Action；以及 π0、RT-1、RoboCLIP 等用 language/demo embedding 的 foundation-model 控制），泛化但无形式化保证。RAD Embeddings 的定位是同时拿下泛化与正确性，并可与 text/image embedding 互补叠加。活跃研究组以 Seshia（UC Berkeley）、McIlraith（Toronto）、Alur/Bastani（UPenn）等为代表。

## 4. 相关工作

1. **Compositional Automata Embeddings for Goal-Conditioned RL**（Yalcinkaya et al., NeurIPS 2024，[ref 20]）：RAD Embeddings 的原始提出工作，定义 RAD DFA 任务分布并验证单智能体泛化。与本文关联：本文是其 overview 与推广，核心方法直接来自此文。

2. **Provably Correct Automata Embeddings for Optimal Automata-Conditioned RL**（Yalcinkaya et al., NeuS 2025，[ref 21]）：给出 bisimulation game 与正确性定义的完整证明（V(A,A′)=0 ⇔ Ψ(A)=Ψ(A′)）。与本文关联：本文第 3 节正确性结论的证明出处。区别在于本文略去证明、聚焦框架与应用串联。

3. **Automata-Conditioned Cooperative Multi-Agent RL**（Yalcinkaya et al., CoRR 2025，[ref 22]）：把 RAD Embeddings 推广到去中心化多智能体团队（ACC-MARL）。与本文关联：本文第 5 节的来源。关键区别：从单 DFA 条件化扩展到 n 个 DFA 合取的团队最优。

4. **LTL2Action: Generalizing LTL Instructions for Multi-Task RL**（Vaezipoor et al., ICML 2021，[ref 17]）：用 LTL 公式条件化学习多任务策略的代表作。与本文区别：LTL2Action 直接编码 LTL 公式，泛化仍是核心挑战；RAD 经 bisimulation 提供可证明正确的 automata 表征。

5. **Reward Machines**（Toro Icarte et al., JAIR 2022，[ref 8]）/ **Compositional RL from Logical Specifications**（Jothimurugan et al., NeurIPS 2021，[ref 10]）：分别代表"利用 reward 结构"与"automaton 上组合式 RL"两条主线。与本文区别：前者偏单任务 reward 结构，后者依赖 symbolic planning 易致次优；本文用预训练 embedding 解耦表征与控制以兼顾最优与泛化。

## 5. 组会讨论要点

- **bisimulation metric 作为表征学习目标的优劣。** 本文把"正确性"严格定义为对 bisimulation 的结构保持，并用归一化 embedding 的欧氏距离构造 bisimulation metric。值得讨论：这种度量在 embedding 维度有限、训练未完全收敛时，对"语义接近但不 bisimilar"任务的区分是否稳健？pseudometric 的三角不等式在近似 Ψ 下还能多大程度保持？

- **与我们组方向的衔接。** 我们组在 LTL/automata、reach-avoid、安全控制方面有积累。RAD Embeddings 把任意 DFA 任务映成可条件化的向量，若与组内 reach-avoid value function、safety filter 结合，或可探索"规范 embedding 条件下的安全策略"，把多任务泛化能力引入安全关键控制。Boolean 组合用语法节点规避指数膨胀的技巧也值得借鉴到我们的规范编码中。

- **后续实验/开放问题。** 论文 Discussion 自身点出两条：(i) 真实机器人/部分可观、含噪感知、hybrid 连续-离散动力学下部署 RAD-conditioned 策略；(ii) **逆问题**——从 demonstration/自然语言数据中合成 formal specification（用生成式模型做 specification synthesis），进而打通"指令模态→规范→RAD Embedding→控制"的端到端管线。组会可讨论逆问题的可行路径与评测方式。

## 参考文献

- Yalcinkaya, Vazquez-Chanlatte, Seshia. *Formal Specification Embeddings for Neuro-Symbolic Autonomy.* AAMAS 2026. https://openreview.net/pdf?id=AUUPc6vBGd
- Yalcinkaya et al. *Compositional Automata Embeddings for Goal-Conditioned Reinforcement Learning.* NeurIPS 2024.
- Yalcinkaya et al. *Provably Correct Automata Embeddings for Optimal Automata-Conditioned Reinforcement Learning.* NeuS (PMLR vol. 288), 2025, 661–675.
- Yalcinkaya, Vazquez-Chanlatte, Shah, Krasowski, Seshia. *Automata-Conditioned Cooperative Multi-Agent Reinforcement Learning.* arXiv:2511.02304, 2025.
- Vaezipoor, Li, Toro Icarte, McIlraith. *LTL2Action: Generalizing LTL Instructions for Multi-Task RL.* ICML 2021 (PMLR vol. 139), 10497–10508.
- Toro Icarte, Klassen, Valenzano, McIlraith. *Reward Machines: Exploiting Reward Function Structure in RL.* JAIR 73 (2022), 173–208.
- Jothimurugan, Bansal, Bastani, Alur. *Compositional Reinforcement Learning from Logical Specifications.* NeurIPS 2021, 10026–10039.
- Brody, Alon, Yahav. *How Attentive are Graph Attention Networks? (GATv2).* ICLR 2022.
