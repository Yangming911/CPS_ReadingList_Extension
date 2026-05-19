# HJ-Gauss: A Monte-Carlo HJ Reachability Scheme — 调研报告

> 生成日期：2026-05-19 | Reading List Monitor
> 论文来源：[arXiv:2605.18566](https://arxiv.org/abs/2605.18566)
> 作者：Lekan Molu, Venkatraman Renganathan, Namhoon Cho
> 提交日期：2026-05-18

## 1. 问题背景与研究动机

Backward Reachable Tubes (BRTs) 通过求解粘性 Hamilton-Jacobi (HJ) 偏微分方程来提供安全证书（safety certificates），是可信赖机器学习中控制器验证和规划算法安全保证的基础工具。然而，经典的基于网格的 HJ 求解器（如 Level Set Toolbox、helperOC）需要 O(M^n) 的内存开销（M 为每维网格点数，n 为状态维度），这导致维度灾难（curse of dimensionality）——通常仅能处理 4-6 维系统。

本文提出了 **HJ-Gauss**，一种基于 Monte Carlo 采样的 HJ 可达性计算方法。其核心思想是通过局部 PDE 线性化实现 frozen-coefficient 采样方案：一个广义的 Cole-Hopf 型变换将非线性 HJ 方程化为一系列线性热方程，其解具有 Gaussian heat-kernel 表示。由此，值函数及其空间梯度可通过在 Gaussian 密度上的 Monte Carlo 期望的 roll-out 来恢复。

这是一个**无存储、无网格**的算法，内存复杂度仅为 N·n（N 为采样数），完全解耦了内存与维度的关系，使得在网格方法根本不可行的高维问题上进行可达性分析成为可能。

## 2. 技术方法

**Cole-Hopf 型变换**：这是整个方法的数学核心。经典的 Cole-Hopf 变换可将 Burgers 方程（一种特殊的非线性 PDE）转化为线性热方程。本文将这一思想推广到一般的粘性 HJ PDE：通过适当的指数变换，将非线性 HJ 方程局部线性化为一系列线性热方程。

**Gaussian Heat-Kernel 表示**：线性热方程的基本解是 Gaussian kernel，因此解可以表示为 Gaussian 密度的卷积。这一表示天然适合 Monte Carlo 采样——只需从 Gaussian 分布中采样，即可近似计算值函数。

**Monte Carlo Picard 迭代**：由于变换是局部的（frozen-coefficient），全局解需要通过 Picard 迭代逐步求精。论文证明了该迭代方案的条件线性收敛性，以及 O(N^{-1/2}) 的有限样本集中不等式（concentration bound）。

**实验验证**：在 pursuit-evasion 博弈上验证，相对 L² 误差为 0.03-0.20，每个 2D 切片的 CPU 计算时间为 14-26 秒。最关键的是，该方法可扩展到 n=45 维的多智能体博弈——这是经典网格方法完全无法触及的规模。

## 3. 研究前沿与意义

高维 HJ 可达性计算是安全控制领域的核心瓶颈问题，近年来涌现了多条技术路线：

- **基于神经网络的方法**：DeepReach (Bansal et al., 2020) 使用正弦激活函数的神经网络直接拟合 HJ 值函数，可处理约 10 维系统。后续 Hofgard et al. (2024) 提供了收敛保证。
- **基于核方法/采样的方法**：本文属于此类，优势在于有明确的误差界和收敛保证，且不需要训练神经网络。
- **分解方法**：利用系统的结构（如解耦子系统）分解高维问题。

HJ-Gauss 的独特优势在于**同时具备无网格特性和严格的理论保证**——DeepReach 虽然也是无网格的，但其误差分析直到 2024 年才有理论结果。HJ-Gauss 的 45 维验证结果是目前已知的最高维度 HJ 可达性计算。

活跃的研究组包括 Stanford 的 Tomlin/Bansal 组（DeepReach）、CMU 的 Safe AI Lab。常见 venue 包括 L4DC、CDC、ACC、ICRA、CoRL 等。

## 4. 相关工作

1. **DeepReach** (Bansal & Tomlin, 2020) — 基于物理信息神经网络（PINN）的 HJ 值函数求解器，使用正弦激活函数。可扩展到约 10 维系统。与 HJ-Gauss 的关键区别：DeepReach 需要训练神经网络（可能收敛慢或陷入局部最优），HJ-Gauss 基于 Monte Carlo 采样，计算流程更直接。

2. **Convergence Guarantees for Neural Network-Based HJ Reachability** (Hofgard et al., 2024, arXiv:2410.02904) — 为 DeepReach 提供了收敛保证：如果损失函数收敛到零，则神经网络近似一致收敛到经典解。HJ-Gauss 在理论保证上更直接（有限样本集中不等式）。

3. **Reachability Barrier Networks** (2025, arXiv:2505.11755) — 将 HJ 可达性学习与 barrier function 结合，用修改版的 DeepReach 学习光滑的 control barrier function。与 HJ-Gauss 互补：一个提供值函数，一个提供 barrier certificate。

4. **Scalable Verification of Neural Control Barrier Functions Using Linear Bound Propagation** — 使用线性界传播（LBP）技术验证神经 CBF 的正确性。如果 HJ-Gauss 的值函数可以用作 CBF，那么 LBP 验证技术可以进一步确保安全保证的可靠性。

5. **Data-Driven Reachable Set Computation using Adaptive Gaussian Process Classification and Monte Carlo Methods** (arXiv:1910.02500) — 同样使用 Monte Carlo 和 Gaussian 方法进行可达集计算，但基于 Gaussian Process 分类而非 PDE 求解。与 HJ-Gauss 的根本区别在于是否求解 HJ PDE。

## 5. 组会讨论要点

1. **Cole-Hopf 变换的局部线性化精度对最终结果的影响如何？** 特别是在高度非线性的动力学系统（如接触力学、柔性机器人）中，frozen-coefficient 近似的误差是否会积累？是否存在系统类别上的适用性限制？

2. **HJ-Gauss 与我们组在 reachability analysis 和 safety filter 方面的工作有直接关联。** 如果 HJ-Gauss 能够在高维系统上高效计算 BRT，那么它可以直接用于构建基于 HJ 的 safety filter（如 value function-based CBF）。值得探索的方向：能否将 HJ-Gauss 与在线安全滤波器结合，实现实时安全保证？

3. **45 维的多智能体博弈验证令人印象深刻，但实际应用中这些高维系统的 BRT 是否具有物理意义？** 高维 BRT 的可视化和解读是一个开放问题。另外，采样数 N 随维度的增长率虽然是线性的，但为了保持固定精度，实际需要多少采样？O(N^{-1/2}) 的收敛率在高维情况下是否足够快？

## 参考文献

- Molu, L., Renganathan, V., & Cho, N. (2026). HJ-Gauss: A Monte-Carlo HJ Reachability Scheme. arXiv:2605.18566. https://arxiv.org/abs/2605.18566
- Bansal, S. & Tomlin, C. (2020). DeepReach: A Deep Learning Approach to High-Dimensional Reachability. arXiv:2011.02082. https://arxiv.org/abs/2011.02082
- Hofgard, E. et al. (2024). Convergence Guarantees for Neural Network-Based Hamilton-Jacobi Reachability. arXiv:2410.02904. https://arxiv.org/abs/2410.02904
- Herbert, S. et al. (2017). Hamilton-Jacobi Reachability: A Brief Overview and Recent Advances. arXiv:1709.07523. https://arxiv.org/abs/1709.07523
- Borquez, J. et al. (2025). Reachability Barrier Networks. arXiv:2505.11755. https://arxiv.org/abs/2505.11755
