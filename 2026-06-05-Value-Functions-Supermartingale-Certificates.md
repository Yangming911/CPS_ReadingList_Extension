# Value Functions as Supermartingale Certificates — 调研报告

> 生成日期：2026-06-05 | Reading List Monitor
> 论文来源：[arXiv:2605.31524](https://arxiv.org/abs/2605.31524)（Alessandro Abate 等）

## 1. 问题背景与研究动机

本文研究的核心问题是：如何为**一般状态空间**（包括可数无穷及连续状态空间）上的离散时间随机系统，建立对 ω-regular 性质（进而涵盖 linear temporal logic, LTL）**几乎必然满足（almost-sure satisfaction）**的形式化证书。

这个问题之所以重要，源于两条研究脉络长期存在的割裂：

一方面，面向 ω-regular 任务的 reinforcement learning（RL）方法（例如基于 LTL reward shaping、product MDP 的方法）在实践中能学到表现良好的策略，但**除有限状态/动作空间外，通常无法给出"学到的策略确实满足规范"的形式化保证**。学习与验证之间缺乏桥梁。

另一方面，formal verification 社区发展出的 supermartingale certificate 方法（如 ranking supermartingale 用于 almost-sure termination/reachability）能提供严格证明规则，但此前主要局限于 reachability、safety、reach-avoid、persistence、recurrence 等相对简单的性质，缺少覆盖完整 ω-regular 谱系的统一证书。

本文的核心贡献是：证明在**恰当的 reward 设计**下，一个几乎必然满足某 ω-regular 性质的策略所对应的 **value function**，本身就编码了该规范的一个 **Streett supermartingale certificate**。这一结果首次把 RL 的 value function 与形式化证书直接等同起来，从而让学习得到的对象天然携带可验证的正确性证明。

## 2. 技术方法

论文的方法论建立在随机过程的鞅收敛理论之上，核心技术要点如下：

**Streett supermartingale 的提出。** 作者利用 Robbins–Siegmund 收敛定理来刻画"几乎必然接受 Streett 条件"所需的 supermartingale 证书，并将这一类证书命名为 Streett supermartingale。由于任意 ω-regular 性质都可由确定性 Streett automaton 接受，因此对 Streett 接受条件的证书化即可覆盖全部 ω-regular（及 LTL）规范，统一了 reachability/safety/recurrence/persistence 等特例。

**Reward 设计与 value function 的等价性。** 论文提出（至少）两种 reward 设计，并证明在任一设计下，一个 almost-surely 满足 LTL 规范的策略的 value function 构成一个**有效的 Streett supermartingale**。换言之，原本只用于评估期望回报的 value function，被赋予了"证书"的形式化语义——它在系统演化中沿 Streett 接受结构提供所需的单调/下降性条件。

**一般状态空间上的处理。** 与只适用于有限模型的方法不同，本文的证书构造面向 countably infinite 与 continuous 状态空间，因此适用于带无穷状态的离散时间随机动态模型的验证与控制。

整体的理论保证是充分性证明规则（sufficient proof rule）：只要能找到满足条件的 Streett supermartingale，即可断定规范几乎必然成立；而本文进一步说明这样的证书可以由 value function 直接给出，从而把"寻找证书"与"学习/计算最优值函数"统一起来。

## 3. 研究前沿与意义

这是一个近年持续升温的研究方向。其热度的证据包括：supermartingale certificate 在 stochastic verification 中的系统化工作（如 Quantitative Supermartingale Certificates、Stochastic Omega-Regular Verification and Control with Supermartingales）近两年密集出现在 CAV、TACAS 等会议；2025 年底还出现了"A Hierarchy of Supermartingales for ω-Regular Verification"等进一步细化证书层级的工作。本文 2026 年 6 月才上线，正处在这一波研究的前沿。

主要的竞争/相关方法路线有三类：(i) 纯 formal verification 路线（abstraction、probabilistic model checking，如 PRISM/Storm），可给出严格保证但在连续/无穷状态上扩展性受限；(ii) learning-based 证书合成（neural supermartingale/barrier certificate 合成，配合 SMT 或 LP 验证）；(iii) LTL-guided RL（product MDP + reward shaping），实践效果好但保证薄弱。本文的价值正在于把 (iii) 的 value function 与 (i)/(ii) 的证书严格对接。

活跃研究组方面，Alessandro Abate（Oxford）一系，以及 Birmingham、IST Austria 等在 stochastic certificate 与 omega-regular 控制方向较为活跃。常见发表 venue 包括 CAV、TACAS、LICS、L4DC、NeurIPS（learning + control 交叉）及 IEEE TAC 等。

## 4. 相关工作

1. **Stochastic Omega-Regular Verification and Control with Supermartingales**（[arXiv:2405.17304](https://arxiv.org/abs/2405.17304)）：首次为 ω-regular 规范在一般随机过程上给出 supermartingale 证书的奠基性工作。与本文的关联：本文正是在其 Streett supermartingale 框架之上，进一步证明 value function 可充当该证书。关键区别在于本文引入了 RL 视角与 reward 设计的等价性结果。

2. **Quantitative Supermartingale Certificates**（Springer/CAV 版本，[PDF](https://arxiv.org/pdf/2504.05065)）：将 supermartingale 证书从定性（almost-sure）推广到定量（概率下界/期望界）。与本文互补：一者关注几乎必然满足，一者关注定量保证；两条线共同构成随机系统证书化的完整图景。

3. **A Hierarchy of Supermartingales for ω-Regular Verification**（[arXiv:2512.00270](https://arxiv.org/pdf/2512.00270)）：研究不同强度 supermartingale 证书之间的层级关系。与本文关联：为"何种证书对应何种规范片段"提供分类，可用于理解 value function 证书在该层级中的位置。

4. **Neural Supermartingale / Barrier Certificate 合成**（如 data-driven certificate synthesis 一类工作）：用神经网络拟合证书并以 SMT/LP 验证。与本文的区别：这些方法把证书当作独立学习对象，而本文指出 RL 已有的 value function 即可直接复用为证书，省去额外合成步骤。

5. **LTL-guided Reinforcement Learning（product MDP + reward shaping）**：面向 ω-regular 任务的主流 RL 框架。本文为这一框架提供了缺失的形式化"事后保证"——把学到的 value function 解读为正确性证书。

## 5. 组会讨论要点

- **保证的边界条件。** 本文的等价性建立在"策略 almost-surely 满足规范"这一前提之上。在实际 RL 训练中，策略往往只是近似满足，value function 也只是近似收敛——此时 value function 还能在多大程度上充当（近似/带误差的）证书？是否存在可量化的 slack？这是值得深挖的开放问题。

- **与我们组方向的潜在联系。** 我们组在 reachability、conformal prediction、safety filter 等方向有大量积累。本文把 LTL/ω-regular 的 value function 证书化，若能与组内的 reach-avoid value function（如 HJ reachability 的 value function）打通，或许能把"安全 value function 即安全证书"的直觉推广到完整时序规范，是一个有吸引力的交叉点。

- **后续实验方向。** 一个自然的扩展是：在连续状态的随机控制基准（如 stochastic navigation、带噪声的机器人导航）上，验证由 deep RL 学到的 value function 是否（数值上）满足 Streett supermartingale 条件，并量化违反程度；进一步可探索把证书条件作为正则项加入训练目标，得到"自带证书"的策略。

## 参考文献

- Abate et al. *Value Functions as Supermartingale Certificates.* arXiv:2605.31524, 2026. https://arxiv.org/abs/2605.31524
- *Stochastic Omega-Regular Verification and Control with Supermartingales.* arXiv:2405.17304, 2024. https://arxiv.org/abs/2405.17304
- *Quantitative Supermartingale Certificates.* arXiv:2504.05065, 2025. https://arxiv.org/pdf/2504.05065
- *A Hierarchy of Supermartingales for ω-Regular Verification.* arXiv:2512.00270, 2025. https://arxiv.org/pdf/2512.00270
