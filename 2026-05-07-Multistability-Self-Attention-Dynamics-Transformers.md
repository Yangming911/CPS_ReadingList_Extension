# Multistability of Self-Attention Dynamics in Transformers — 调研报告

> 生成日期：2026-05-07 | Reading List Monitor
> 论文来源：arXiv:2511.11553 (2025-11-14) | https://arxiv.org/abs/2511.11553
> 作者：Claudio Altafini (Linköping University)

## 1. 问题背景与研究动机

Transformer 的强大表现力已无须赘述，但学界对 self-attention 内部"为什么收敛、收敛到哪里、收敛过程长什么样"仍缺乏严格刻画。本文从动力系统视角出发，把 self-attention 的逐层迭代抽象为一个连续时间的 multiagent 动力系统：每个 token 是一个 agent，attention 矩阵决定 agent 之间的耦合方式，value 矩阵承担类似"耦合权重"的角色。这一视角把 attention 与经典 multiagent 共识动力学（consensus dynamics）以及 PCA 类的 Oja flow 联系起来，使得我们可以借用控制理论中关于稳定性、不变集、平衡点分类的成熟工具来分析 transformer。

研究动机有二：(i) 从理论侧解释 transformer 在足够深之后是否会"塌缩"为某种简单结构（rank collapse、token uniformity 等已知现象的更一般形式）；(ii) 从应用侧理解为何同一组权重在不同输入下会收敛到差别很大的表示——即多平衡点共存（multistability）的现象。这对理解 representation engineering、activation steering、in-context learning 的可控性都有直接意义。

## 2. 技术方法

文章把单头 self-attention 的连续时间近似写成一种带 softmax 耦合的 multiagent ODE，并证明这个 ODE 在某种意义下与 multiagent 版本的 **Oja flow** 等价——后者是经典的、计算矩阵主特征向量的连续时间算法，此处对应的矩阵就是 value 矩阵 $V$。基于这一映射，作者将系统的平衡点分为四类：

1. **Consensus equilibria**：所有 token 收敛到同一向量（对应 rank collapse）。
2. **Bipartite consensus equilibria**：token 分成两个对称的群，方向相反但大小相同。
3. **Clustering equilibria**：token 形成多个紧致簇。
4. **Polygonal equilibria**：token 排布成对称多边形结构。

主要理论结论是：(a) 前三类平衡点经常**同时**渐近稳定（multistability），意味着初始 token 配置（即输入 prompt）会决定收敛终态；(b) 前两类平衡点**总是与 $V$ 的特征向量对齐**，且经常但不总是与主特征向量对齐——这从一个侧面解释了 attention 头之间为什么呈现一定的"特征方向偏好"；(c) 文章给出 attractor basin 的部分刻画，可用于预测给定输入会落入哪一类平衡点。

方法论层面，作者主要使用了 Lyapunov 函数构造、对称性论证（permutation-equivariance 与 sign-symmetry）、以及线性化稳定性分析。这些工具直接来自 multiagent control 与 nonlinear systems 教材，对 CPS 背景的读者非常友好。

## 3. 研究前沿与意义

把 transformer 的 forward pass 视为 ODE / dynamical system 是 2023 年以来逐步形成的一个独立子领域。代表工作包括 Geshkovski–Letrouit–Polyanskiy–Rigollet 关于 "particle dynamics of transformers" 的系列论文，以及 ICLR/NeurIPS 上多篇关于 *token uniformity*、*rank collapse*、*metastability in attention* 的分析。本文沿这条路线，通过把 attention 与 Oja flow 等价化，把分析工具从纯 PDE/measure-flow 扩展到了控制理论框架，方法论较新颖。

热度评估：相关 workshop 已较成熟，例如 NeurIPS 的 *Mathematics of Modern Machine Learning*、*Symmetry and Geometry in Neural Representations*；ICML 的 *Theory of Foundation Models*；ICLR 主会近两年也出现了多篇 attention dynamics 论文。除 ML 三大会外，控制类期刊如 *IEEE TAC*、*Automatica*、*SIAM J. Control* 也开始接收此类工作。Altafini 本人长期研究 multiagent 系统中的 signed networks / bipartite consensus，本文是把他在控制领域的经典结果"移植"到 transformer 的自然延伸。

## 4. 相关工作

- **Dynamic metastability in the self-attention model** (arXiv:2410.06833)。从 mean-field/measure flow 角度刻画 attention 的亚稳定性，与本文的离散平衡点分类互补。
- **The underlying structures of self-attention: symmetry, directionality, and emergent dynamics in Transformer training** (arXiv:2502.10927)。聚焦训练动力学下 attention 的对称性涌现，是本文 forward dynamics 视角的训练阶段对偶。
- **On the Role of Attention Masks and LayerNorm in Transformers** (arXiv:2405.18781)。指出 mask 与 LayerNorm 如何改变 attention 的不变流形，可与本文平衡点分类结合分析。
- **Local Linearity of LLMs Enables Activation Steering via Model-Based Linear Optimal Control**（已在 reading list 上）。从 LQR/线性最优控制角度操控 LLM 表征，与本文的非线性多平衡点视角形成有趣对照。
- **Preemptive Detection and Steering of LLM Misalignment via Latent Reachability**（已在 reading list 上）。把 reachability analysis 用于 LLM 状态空间，本文给出的平衡点结构正是此类 reachability 计算的天然几何对象。

## 5. 组会讨论要点

1. **Multistability 与 LLM safety/steering 的接口**：如果 attention 真的有多个共存平衡点，那么"不安全"的输出可能对应某些特定 attractor basin。是否可以基于本文的平衡点分类设计 safety filter——在推理过程中检测到状态轨迹将进入"危险" attractor 时进行干预？这可与组里的 reachability-based steering 工作直接对接。
2. **Attractor basin 的可计算性**：文章给出的平衡点刻画基于连续时间近似与简化的 single-head 假设；多头 + 残差连接 + LayerNorm 的真实 transformer 上 basin 估计的难度有多大？是否有数值方法（Lyapunov function search、SOS programming）能给出可证明的吸引域？这是 CPS 形式化方法可以贡献的方向。
3. **从 forward dynamics 到 training dynamics**：本文几乎全部讨论 forward 阶段；如果把 weight 的训练演化也看作 outer dynamics，与 forward dynamics 形成 two-time-scale 系统，是否能解释训练过程中观察到的 phase transition？这与 ML 理论方向的最新进展是潜在合作点。

## 参考文献

1. Altafini, C. *Multistability of Self-Attention Dynamics in Transformers.* arXiv:2511.11553, 2025. https://arxiv.org/abs/2511.11553
2. *Dynamic metastability in the self-attention model.* arXiv:2410.06833. https://arxiv.org/abs/2410.06833
3. *The underlying structures of self-attention.* arXiv:2502.10927. https://arxiv.org/abs/2502.10927
4. *On the Role of Attention Masks and LayerNorm in Transformers.* arXiv:2405.18781. https://arxiv.org/html/2405.18781
5. *Dissecting the Interplay of Attention Paths in a Statistical Mechanics Theory of Transformers.* arXiv:2405.15926. https://arxiv.org/html/2405.15926
