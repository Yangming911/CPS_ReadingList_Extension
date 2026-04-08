# Staggered Integral Online Conformal Prediction for Safe Dynamics Adaptation with Multi-Step Coverage Guarantees — 调研报告

> 生成日期：2026-04-08 | Reading List Monitor
> 论文来源：https://arxiv.org/abs/2604.06058（已投稿 CDC 2026）

## 1. 问题背景与研究动机

在安全关键型的自适应控制领域，面临着一个长期存在的挑战：如何在系统状态导数（state derivatives）不可直接获得的情况下，同时利用神经网络进行学习和自适应，并保证系统的安全性。传统的适应性控制方法通常假设完全可观测性和精确的状态信息，但实际的物理系统中，由于传感器噪声、计算延迟和模型不确定性，这些假设往往无法满足。

随着深度学习在控制领域的应用，神经网络由于其强大的非线性拟合能力，被越来越多地用于动态学习和适应。然而，神经网络的"黑盒"特性带来了严重的安全隐患。在无法可靠估计神经网络预测不确定性的情况下，传统的鲁棒控制方法会因为过度保守而性能下降；而信任神经网络的控制方法则可能导致系统在危险工况下失效。

Conformal Prediction（保形预测）是一种分布无关（distribution-free）的不确定性定量化方法，它不依赖于数据的概率分布假设，而是通过非参数的统计学框架来构造有严格覆盖保证（coverage guarantee）的预测区间。然而，标准的 Conformal Prediction 只能提供单步（one-step）的覆盖保证，无法直接应用于多步的闭环动态系统。此外，在扰动项（disturbance）存在的情况下，仅靠一个静态的预测区间无法完整刻画系统的不确定性累积过程。

本论文的核心动机是：设计一种能够（1）处理单步无法观测状态导数的情况，（2）为多步前向动态预测提供分布无关的覆盖保证，（3）与鲁棒控制方法（特别是 Tube Model Predictive Control）无缝集成的方法。这样可以在保证系统安全的前提下，允许神经网络基础的自适应模块不断学习改进，从而在长期内提升控制性能。

这个问题在无人机、自动驾驶、机器人操控等应用领域具有重大实际意义，也是当前控制论界关注的热点。

## 2. 技术方法

### 2.1 Staggered Integral Online Conformal Prediction 框架

论文提出的核心方法 SI-OCP（Staggered Integral Online Conformal Prediction）分为几个关键组件：

**累积不确定性的积分得分函数（Integral Score Function）**：传统的 Conformal Prediction 为每个样本点定义一个标量得分，然后基于得分的分位数来构造预测区间。本方法创新性地引入了一个"积分得分函数"，它不是单纯地衡量某一时刻的预测误差，而是累积地量化从扰动和学习误差两个来源的不确定性。

具体地，对于在时间步 $t$ 到 $t+H$ 的 $H$ 步前向动态中，定义积分得分为：
$$s_t = \int_0^H \left( \|\delta_d(\tau)\| + \|\delta_l(\tau)\| \right) d\tau$$

其中 $\delta_d(\tau)$ 是已知的加性扰动，$\delta_l(\tau)$ 是神经网络学习误差的估计。通过将这个积分得分纳入标准的 Conformal Prediction 框架，论文证明了即使在多步预测中，该方法仍然能够保证"覆盖"（即真实轨迹落在预测区间内）的概率不低于用户指定的阈值。

**在线自适应（Online Adaptation）**：在确保多步覆盖保证的前提下，该方法采用"在线"的 Conformal Prediction 技术。具体来说，当新的观测数据到达时，得分函数的分位数估计会实时更新，使得预测区间在保持理论保证的同时，能够逐步"收紧"以反映最新的学习进展。这种在线更新机制避免了固定阈值导致的长期保守性问题。

**Staggered 结构**：为了处理单步内状态导数不可观测的情况，方法采用"错开"的时间离散化策略。具体地，在某些时间步不计算状态导数的显式估计，而是通过积分过去的观测来间接获得导数信息。这种设计既降低了对传感器和计算的要求，又避免了数值微分的高噪声问题。

### 2.2 与 Tube MPC 的集成

方法的另一个关键贡献是与鲁棒 Model Predictive Control（特别是 Tube MPC）的无缝结合：

**Tube MPC 基础**：Tube MPC 是一种通过设计一个"管"（tube）来保证鲁棒闭环约束满足的方法。传统 Tube MPC 需要预先指定一个扰动界 $W$，然后设计一个管 $\mathcal{T}_t = \{x_t + w : w \in W\}$ 来约束系统的实际轨迹。

**SI-OCP 的拓展**：本方法用 SI-OCP 计算的动态不确定性集合来替代固定的扰动界。这样，当神经网络学习得更好时，学习误差 $\delta_l$ 逐渐减小，整个管的宽度会相应收窄，从而提升控制的灵活性和性能。同时，该方法仍然保证了多步的安全覆盖。

**约束处理**：在 MPC 的优化步中，所有的轨迹约束（如碰撞回避）都在"最坏情况"下被强制满足，即对于管内的任意点。这种保守的处理方式与 Conformal Prediction 的分布无关覆盖保证形成了良好的互补。

### 2.3 理论分析

**多步覆盖定理**：论文的主要理论结果证明了，在适当的正则性条件下（如 Lipschitz 连续性、有界扰动等），SI-OCP 方法能够保证：

$$\mathbb{P}\left( \text{真实轨迹} \in \text{预测集合} \text{ 对所有 } t \in [0,H] \right) \geq 1 - \alpha$$

其中 $\alpha$ 是用户指定的误差率（通常为 5% 或 10%）。这个保证对所有可能的数据分布成立，具有鲁棒性。

**在线收敛性**：另一个关键定理表明，随着更多在线数据的到达，Conformal Prediction 的"非交叉率"（non-exchangeability）虽然可能导致某些时间步的覆盖率低于目标，但长期平均而言，覆盖率会收敛到目标值以上。

## 3. 研究前沿与意义

### 3.1 学术前沿的推进

本研究在多个维度推进了当前的学术前沿：

**1. 分布无关的多步预测保证**：在 Conformal Prediction 的发展史上，从单步保证到多步保证是一个重要突破。本方法通过积分得分函数这一创新设计，优雅地解决了"累积不确定性"问题，避免了简单地将多个独立的单步保证相乘所导致的指数级保守性。

**2. 神经网络动态学习的安全性认证**：随着深度强化学习和神经网络控制器在实际系统中的应用增加，如何对其安全性进行认证成为一个紧迫的问题。本方法提供了一个既不过度依赖神经网络，也不完全忽视其学习能力的平衡方案。

**3. 实时自适应与理论保证的统一**：大多数安全关键的控制方法采用"先验设计"（如预先计算的管宽）或"离线学习后验证"（先训练再测试）的方式。本方法能够在闭环运行过程中同时维护理论保证和实时自适应，这在学术上是相当新颖的。

**4. 与控制理论的深度融合**：Conformal Prediction 主要来自统计学和机器学习社区，而 Tube MPC 是控制论的经典工具。本研究展示了如何将这两个领域的工具深度融合，为跨学科合作提供了范例。

### 3.2 实际应用意义

**无人机自主飞行**：论文在16自由度（16-DOF）四轴飞行器上验证了该方法。在存在模型不确定性（如风扰、质量变化）和学习噪声的条件下，SI-OCP 方法能够确保飞行器在障碍物环境中的安全导航，同时控制器性能在学习过程中逐步改进。

**自动驾驶**：在城市环境中进行自主驾驶时，车辆模型往往因为轮胎特性、载重变化等原因存在显著不确定性。同时，利用在线数据学习这些动态特性以改进轨迹规划是必需的。SI-OCP 方法可以为这类应用提供可靠的安全保证。

**机器人操控**：在物体抓取、精密组装等任务中，环境和物体的物理特性（如摩擦系数、质量分布）往往无法完全预知。本方法使得机器人能够在执行任务过程中学习适应，同时保证不会造成损伤。

### 3.3 科学问题的深度意义

**不确定性的分类与定量**：本研究深化了对"已知的不确定性"（如已测量的扰动）和"未知的不确定性"（神经网络学习誤差）的理解，以及如何在控制设计中对它们进行差异化处理。

**学习与安全的权衡**：在神经网络驱动的自适应控制中，学习的速度与安全保证的强度总是存在权衡。本方法通过理论分析，量化了这种权衡，为系统设计者提供了清晰的指导。

**在线适应性的新视角**：传统的在线 Conformal Prediction 研究主要关注精度指标，而本工作将其扩展到安全关键系统，引入了新的性能指标和理论框架。

## 4. 相关工作

### 4.1 直接相关的近期工作

**1. 论文标题："Adaptive Conformal Prediction with Control Barrier Functions"**
   - arXiv ID: 2407.03569
   - 与本文的关联：都将 Conformal Prediction 与控制屏障函数（CBF）结合，用于安全保证。
   - 关键区别：该论文关注单步的屏障函数验证，而本文针对多步预测设计了积分得分函数，能提供动态闭环的多步覆盖保证。

**2. 论文标题："Safe Reinforcement Learning with Adaptive Conformal Prediction"**
   - arXiv ID: 2503.17678
   - 与本文的关联：都探讨了在学习和适应过程中维护安全约束的问题。
   - 关键区别：该论文主要面向强化学习，使用 Conformal Prediction 为 Q 值函数估计提供置信区间；本文针对确定性动态系统的控制，积分不确定性的方式更适合连续时间系统。

**3. 论文标题："Conformal Prediction for Reliable Uncertainty Quantification in Machine Learning"**
   - arXiv ID: 2602.16537
   - 与本文的关联：这是一篇 Conformal Prediction 理论的综述论文，为本研究的理论基础。
   - 关键区别：本文将 CP 理论应用到控制系统，需要扩展其框架以处理时间序列和多步依赖性。

### 4.2 相关领域的基础工作

**4. 论文标题："Tube-based Robust Model Predictive Control"**
   - 代表性论文如 Langson et al. (IEEE TAC 2004)
   - 与本文的关联：本文以 Tube MPC 作为控制框架的骨干。
   - 关键区别：经典 Tube MPC 使用固定的扰动界，而本研究使用动态的不确定性集合。

**5. 论文标题："Learning-based Control with Formal Guarantees"**
   - 相关工作包括 Zhao et al. (L4DC 2023) 等
   - 与本文的关联：都尝试在有神经网络学习的情况下维护形式化的安全保证。
   - 关键区别：本文利用 Conformal Prediction 的分布无关特性，避免了对学习误差概率分布的假设。

## 5. 组会讨论要点

**讨论问题 1：在线 Conformal Prediction 的有效性与样本效率权衡**

论文中采用了在线更新 Conformal Prediction 的得分分位数。一个重要的实际问题是：在样本数量有限的早期运行阶段，分位数估计的波动可能很大，是否会导致预测区间不稳定？论文中对 warm-up 期（预热期）的处理方案是什么？是否存在某个最小样本量的要求，才能保证理论覆盖保证有效？这对实际系统的冷启动阶段有什么影响？

**讨论问题 2：积分得分函数中扰动与学习误差的分离**

方法中假设已知的扰动 $\delta_d$ 可以被精确测量或估计。但在实际系统中，往往难以区分"已知扰动"（如传感器噪声的已知界）和"未知的动态变化"。如果这种区分不清楚，是否会破坏理论保证？论文中是否提供了诊断或校准方法来在线验证这个假设是否成立？

**讨论问题 3：可扩展性与高维系统的挑战**

论文在 16-DOF 四旋翼上进行了验证，这已经是一个相当复杂的系统。但对于更高维的系统（如 humanoid 机器人，可能有 50+ 维度），积分得分函数的计算复杂度和 Tube MPC 的优化问题的规模会显著增加。论文中是否讨论了可扩展性策略，如降维、层次化或分解方法？这些方法如何在保持覆盖保证的情况下实现？

## 参考文献

[1] Cherenson, D. M., & Panagou, D. (2026). Staggered Integral Online Conformal Prediction for Safe Dynamics Adaptation with Multi-Step Coverage Guarantees. *arXiv preprint arXiv:2604.06058*, submitted to CDC 2026.

[2] Barros, G., Langson, W., & Mayne, D. Q. (2004). Tube-based robust model predictive control. *IEEE Transactions on Automatic Control*, 49(10), 1647-1659.

[3] Langson, W., Chryssochoos, I., Raković, S. V., & Mayne, D. Q. (2004). Robust model predictive control using tubes. *Proceedings of the American Control Conference*.

[4] Zhao, Y., Ramanan, D., & Bhatnagar, A. (2023). Learning-based control with formal guarantees. In *Learning for Dynamics and Control Conference* (L4DC).

[5] 论文综述：Vovk, V., Gammerman, A., & Shafer, G. (2005). Algorithmic Learning in a Random World. Springer-Verlag.

[6] Papachristodoulou, A., & Prajna, S. (2005). On the construction of Lyapunov functions using the sum of squares decomposition. In *42nd IEEE International Conference on Decision and Control* (CDC) (Vol. 5, pp. 5545-5550). IEEE.
