# Safety Certification is Classification — 调研报告

> 生成日期：2026-05-09 | Reading List Monitor
> 论文来源：[arXiv:2605.06087](https://arxiv.org/abs/2605.06087)
> 作者：Oliver Schön, Licio Romao, Sadegh Soudjani
> 提交日期：2026-05-07

## 1. 问题背景与研究动机

本文研究的核心问题是：如何为存在不确定性的动态系统提供安全性证明（safety certification）。现有方法的主流思路是利用轨迹数据估计转移概率，然后通过 dynamic programming (DP) 递归地计算安全概率。然而，这种递归计算会导致 **compounding error**——随着 certification horizon $T$ 的增长，误差逐步累积，最终使得安全概率的下界退化为无意义的 vacuous bound。

作者的核心洞察在于：safety certification 本质上是一个 **分类问题**。与其通过 DP 递归地逐步估计转移概率再乘积得到安全概率，不如直接从轨迹数据出发，一步到位地估计 $T$-step 安全概率。这一视角的转变带来了两个关键优势：(1) 避免了 compounding error；(2) 能够处理 non-Markovian dynamics——这是传统 DP 方法无法覆盖的场景。

## 2. 技术方法

作者提出了一个基于 **kernel embedding** 的框架。具体而言：

- 将安全认证问题建模为对轨迹数据的二分类问题：给定初始状态，判断系统在 $T$ 步内是否保持安全。
- 利用 reproducing kernel Hilbert space (RKHS) 中的 kernel mean embedding 来表示状态分布与安全集的关系，从而直接估计安全概率。
- 该框架具有很强的统一性：作者证明了经典的 barrier certificate 方法和 robust Markov model 方法都是该框架的特例。这意味着现有方法可以被理解为在特定核函数和假设下的分类器。
- 由于直接估计避免了递归，safety probability 的估计误差不随 horizon $T$ 增长而累积，理论上保证了 long-horizon 场景下的可靠性。

实验在一个神经网络控制的四旋翼（neural-controlled quadrotor）上进行，验证了：(1) 直接估计器在长 horizon 下保持稳定；(2) DP-based certificate 在同样条件下会悄然失效（silently go unsound）；(3) 在 non-Markovian 系统上，传统方法完全失效，而本文方法依然有效。

## 3. 研究前沿与意义

Data-driven safety verification 是近年来 CPS/控制/形式化方法领域的一个高度活跃方向。主要驱动力包括：

- 学习型控制器（如神经网络控制器）的广泛使用使得传统的 model-based verification 难以直接应用。
- Conformal prediction、PAC learning 等统计工具被引入安全验证，催生了大量工作。
- Barrier certificate 的数据驱动学习成为热门子方向。

本文与同组此前的工作（如 LUCID、data-driven barrier certificates via conditional mean embeddings）一脉相承，代表了 Soudjani 研究组在 kernel methods + safety verification 方向的最新进展。该框架将 safety certification 重新表述为分类问题的思路具有启发性，可能影响后续方法的设计。

常见发表 venue 包括：CDC, L4DC, HSCC, NeurIPS (safety track), AAAI, IJCAI。

## 4. 相关工作

1. **Data-Driven Distributionally Robust Safety Verification Using Barrier Certificates and Conditional Mean Embeddings** (Schön, Romao, Soudjani, 2024, arXiv:2403.10497)
   - 同一研究组的前期工作，使用 conditional mean embedding 构建 distributionally robust 的 barrier certificate。
   - 与本文的关联：本文可以看作是对该工作的进一步推广，从 barrier certificate 的间接方法转向直接分类方法。

2. **LUCID: Learning-Enabled Uncertainty-Aware Certification of Stochastic Dynamical Systems** (arXiv:2512.11750)
   - 提出了 learning-enabled 的不确定性感知安全认证方法。
   - 与本文互补：LUCID 关注不确定性量化，本文关注消除 compounding error。

3. **Probably Approximately Correct (PAC) Guarantees for Data-Driven Reachability Analysis** (已在 reading list 中)
   - 从 PAC learning 角度提供 data-driven reachability 的理论保证。
   - 关键区别：PAC 方法通常假设 Markovian dynamics，而本文明确处理 non-Markovian 场景。

4. **Kernel-Based Learning of Safety Barriers** (arXiv:2601.12002)
   - 利用核方法学习 safety barrier。
   - 与本文共享 RKHS 工具箱，但目标不同：前者学习 barrier function，本文直接估计安全概率。

5. **Conformalized Data-Driven Reachability Analysis with PAC Guarantees** (已在 reading list 中)
   - 结合 conformal prediction 与 reachability analysis。
   - 本文的分类视角提供了一种不同于 conformal prediction 的统计框架。

## 5. 组会讨论要点

1. **Non-Markovian dynamics 的实际意义**：在哪些实际 CPS 场景中系统动力学是 non-Markovian 的？神经网络控制器中的 recurrent 结构是否是一个典型例子？这对我们组现有基于 Markov 假设的方法有什么启示？

2. **分类精度与安全保证的权衡**：将 safety certification 转化为分类问题后，分类器的 false negative（将不安全判为安全）直接影响安全保证的可靠性。作者如何处理这一问题？是否有类似 conformal prediction 的 coverage guarantee？

3. **与 barrier certificate 方法的实际比较**：论文声称 barrier certificate 是其框架的特例，但在实践中，kernel embedding 方法的计算代价和数据需求是否显著高于直接求解 barrier certificate？在什么规模的系统上该方法具有实用性？

## 参考文献

- Schön, O., Romao, L., & Soudjani, S. (2026). Safety Certification is Classification. arXiv:2605.06087. https://arxiv.org/abs/2605.06087
- Schön, O., Romao, L., & Soudjani, S. (2024). Data-Driven Distributionally Robust Safety Verification Using Barrier Certificates and Conditional Mean Embeddings. arXiv:2403.10497. https://arxiv.org/abs/2403.10497
- Romao, L., et al. (2025). LUCID: Learning-Enabled Uncertainty-Aware Certification of Stochastic Dynamical Systems. arXiv:2512.11750. https://arxiv.org/abs/2512.11750
- Schön, O., et al. (2026). Kernel-Based Learning of Safety Barriers. arXiv:2601.12002. https://arxiv.org/abs/2601.12002
- Prajna, S., & Jadbabaie, A. (2004). Safety Verification of Hybrid Systems Using Barrier Certificates. HSCC 2004. https://link.springer.com/chapter/10.1007/978-3-540-24743-2_32
