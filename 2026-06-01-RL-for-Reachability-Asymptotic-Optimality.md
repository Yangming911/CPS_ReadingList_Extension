# Reinforcement Learning for Reachability: Guaranteeing Asymptotic Optimality — 调研报告

> 生成日期：2026-06-01（2026-06-05 据原文校订）| Reading List Monitor
> 论文来源：[arXiv:2605.24740](https://arxiv.org/abs/2605.24740) ｜ **ICML 2026**（含正文与附录）
> 作者：Amogh Palasamudram, Jakub Svoboda, Suguman Bansal, Krishnendu Chatterjee
> 主题分类：cs.LG（Machine Learning）, cs.GT（Computer Science and Game Theory）

> **重要校订说明：** 本报告初版（2026-06-01）在未取得原文的情况下，依标题"reachability"误判为 **Hamilton-Jacobi reach-avoid / 连续控制**方向，整体技术定位错误。取得 arXiv:2605.24740 摘要后确认：本文是一篇**理论 RL** 论文，研究的是 **MDP 上 reachability specification 的 PAC 学习**，与 HJ reachability、safety filter、连续状态 reach-avoid 无关。以下为据摘要重写的版本；正文定理细节待通读 PDF 后再补。

## 1. 问题背景与研究动机

本文研究的"reachability"是**序贯决策（sequential decision-making）意义下的 reachability specification**：在一个（通常未知的）Markov Decision Process 上，目标是最大化到达某目标状态集合的概率，即 reachability objective。这是 formal methods 与 RL 交叉处的基础问题——许多时序规范（safety、reachability、乃至 ω-regular 的片段）都可归约到 reachability。

研究动机来自该问题"理论保证薄弱"的现状。摘要指出：尽管 reachability 的 RL 十分基础，其**理论保证仍较少被探讨**；近期已有工作能做到**渐近收敛到最优策略（asymptotic convergence to optimal policies）**，但这类结果对**收敛动力学（convergence dynamics）本身提供的洞察有限**——只知道"极限处最优"，却不清楚"如何、以何种结构逼近最优"。

本文的核心诉求，是给出一个**对收敛过程有更深理论洞察**的替代方案：不满足于"极限最优"这一存在性结论，而是要刻画出逼近最优的机制，并据此重新证明"极限处可达到 exact optimality"。

## 2. 技术方法

据摘要，方法建立在 **PAC（Probably Approximately Correct）learning with assumptions** 之上，核心思路如下（定理细节待核实正文）：

**(1) 以 PAC learning 为骨架。** PAC learning 能在**有限时间**内、以**高置信度**给出**近最优（near-optimal）策略**。但经典 PAC 结果有一个前提：需要知道 MDP 的若干**内部参数**，典型如**最小转移概率（minimum transition probability）**等结构量。这在纯 RL（model-free / 未知模型）设定下通常是不可得的——这正是把 PAC 保证直接搬到 RL 的障碍。

**(2) 参数的迭代精化（iterative refinement）。** 本文的关键论点是：这些未知的内部 MDP 参数虽然一开始不可知，却**可以被迭代地估计、并随交互不断提高精度**。也就是说，不把"已知参数"当作硬前提，而是把它替换为"逐步收敛到真值的估计序列"。

**(3) 迭代满足 PAC 条件 ⇒ 极限处 exact optimality。** 通过**反复满足 PAC 条件**（每一轮用当前的参数估计触发一次 PAC 式的近最优保证，并随估计精度提高收紧近似），作者证明在极限处可达到**精确最优（exact optimality）**，而非仅近似最优。相比"直接给一个渐近收敛结论"，这条 PAC-迭代路线的好处是把"如何逼近"显式化，从而对 convergence dynamics 给出更细致的理论刻画。

**(4) 实验验证。** 在标准 benchmark 上的实证评估验证了上述关于 convergence dynamics 的理论洞察（即不仅极限最优，逼近过程也符合理论预测）。

简言之，本文不是提出新的连续控制可达性求解器，而是在**理论 RL** 层面，用"可迭代精化的 PAC 假设"替代"已知 MDP 参数"的不现实前提，从而把 PAC 的有限时间近最优保证升级为 RL 设定下的**渐近精确最优**保证，并对收敛过程给出更强的可解释性。

## 3. 研究前沿与意义

reachability objective 的理论 RL（带形式化保证的收敛分析）是 formal methods × RL 的活跃前沿，常见于 CAV、TACAS、AAAI、IJCAI、NeurIPS、ICML 等。本文被 **ICML 2026** 接收，cs.LG/cs.GT 分类，作者团队（Krishnendu Chatterjee、Suguman Bansal 等）长期工作在 quantitative verification、ω-regular RL、博弈与概率系统验证方向，正是该交叉领域的代表性研究力量（Chatterjee 在 IST Austria，Bansal 在 Georgia Tech，均以 specification-guided / formal RL 著称）。

定位上，本文与"另一条同样宣称 asymptotic optimality 的近期工作"形成直接对话——摘要中"A recent work achieves asymptotic convergence to optimal policies"指的应是同期用别的技术（如 ω-regular reward / discounted 收敛）证明渐近最优的工作；本文的差异化卖点是**用 PAC + 参数迭代精化提供更深的 convergence-dynamics 洞察**。这把讨论从"能否渐近最优"推进到"以何种有限时间、高置信度的结构逼近最优"，对 sample complexity 与可信部署有实际意义。

需要强调（纠正初版误判）：本文属于**tabular / 理论 MDP** 谱系，而非 Hamilton-Jacobi reachability、neural reach-avoid value function 那一支连续控制工作。两者同用"reachability"一词，但问题设定（离散 MDP 到达概率 vs. 连续动力学最坏扰动 reach-avoid set）与方法工具（PAC/sample complexity vs. HJ PDE/Bellman contraction）截然不同。

## 4. 相关工作

> 注：以下为基于摘要与作者群已知研究脉络的推断性定位；精确引用与对比待正文确认。

1. **"A recent work achieving asymptotic convergence to optimal policies"（摘要点名的对照工作）：** 本文的直接比较对象，同样证明 reachability RL 的渐近最优，但据摘要其对 convergence dynamics 洞察有限。本文以 PAC 路线提供更细的逼近刻画作为区别。建议在正文 Related Work 中定位该文确切出处。

2. **PAC RL / sample-complexity 理论（如 PAC-MDP、E³、R-MAX 谱系）：** 提供"有限时间、高置信度近最优"的经典框架，但通常需要已知或可探索得到的 MDP 结构量。本文的贡献正是放松"已知 minimum transition probability"等前提，改为迭代估计。

3. **ω-regular / LTL objectives 的 RL 与收敛保证（Chatterjee、Bansal 等团队的系列工作）：** reachability 是 ω-regular 规范的基础片段。本文可视为该研究线在"reachability + 收敛动力学"上的精细化。

4. **Quantitative verification of MDPs（probabilistic model checking, 如 PRISM/Storm 求解 reachability probability）：** 已知模型时的精确解参照系；本文处理的是模型未知、需在 RL 中边学边保证的情形。

5. **（与初版误列工作的关系）：** Fisac 等 Safety Bellman Equation、Hsu 等 reach-avoid Q-learning、Yu 等 RCRL 等属于 **HJ/连续 reach-avoid** 谱系，与本文**并非同一问题**，初版将它们列为近邻是误判，特此更正——它们至多在"reachability 一词"上同名。

## 5. 组会讨论要点

- **PAC 参数迭代精化的代价与速率。** 本文用"迭代估计 minimum transition probability 等内部参数"替代已知前提。值得讨论：估计这些结构量（尤其 minimum transition probability，往往是 sample complexity 的瓶颈量）本身的样本代价有多大？论文是否给出收敛**速率**而不仅是极限结论？这决定了该理论洞察能否转化为实际样本效率优势。

- **与组内 specification-guided RL 的衔接。** 我们组关注 LTL/automata、安全 RL。reachability 是这些规范的基础构件，本文"迭代满足 PAC 条件 ⇒ 极限精确最优"的论证范式，或可推广到更一般的 ω-regular reward（与本期另一篇 supermartingale 证书工作、以及 RAD Embeddings 工作恰可对照：一个谈证书、一个谈表征、本文谈收敛保证）。

- **理论假设的现实性。** PAC-with-assumptions 仍依赖一些结构性假设。组会可讨论：这些假设在我们实际关心的环境（大状态空间、稀疏奖励、近确定性转移）中是否成立或可估计？exact optimality 的"极限"结论对有限预算的工程部署意味着什么？

## 参考文献

- Palasamudram, Svoboda, Bansal, Chatterjee. *Reinforcement Learning for Reachability: Guaranteeing Asymptotic Optimality.* ICML 2026. arXiv:2605.24740. https://arxiv.org/abs/2605.24740
- （对照工作、PAC-MDP 谱系、ω-regular RL 等精确引用待正文 Related Work 确认后补全）

*备注：本报告已于 2026-06-05 据 arXiv:2605.24740 官方摘要整体重写，纠正了初版将本文误判为 HJ reachability/连续控制方向的错误。第 2、4 节的定理与引用细节仍待通读 PDF 正文后核校。*
