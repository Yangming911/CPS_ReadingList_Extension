# Distributionally Robust Safety Under Arbitrary Uncertainties: A Safety Filtering Approach — 调研报告

> 生成日期：2026-05-14 | Reading List Monitor
> 论文来源：未找到确切的 arxiv 链接，以下基于标题和相关文献进行调研

## 1. 问题背景与研究动机

在安全关键系统（如自动驾驶、机器人导航、无人机避障）中，safety filter 是一种广泛使用的架构：它不替换原有控制器，而是在控制指令即将导致不安全行为时进行干预和修正。传统的 safety filter 通常依赖于精确的系统动力学模型和已知的扰动分布，但在实际部署中，系统面临的不确定性来源多样且往往无法精确刻画——包括模型误差、环境扰动、传感器噪声等。

本文的核心问题是：**当不确定性的分布本身也是未知的（即"arbitrary uncertainties"）时，如何设计一个既能提供严格安全保证、又不过于保守的 safety filter？**

传统方法的不足主要体现在两方面：一是 robust control 方法通常假设 worst-case 扰动，导致过于保守；二是 stochastic 方法假设已知扰动分布，在 distribution shift 下安全保证失效。Distributionally robust optimization (DRO) 提供了一条中间路径：通过定义一个包含真实分布的 ambiguity set，在该集合内的最坏情况下优化，既比纯 robust 方法灵活，又比纯 stochastic 方法鲁棒。

本文的贡献在于将 DRO 框架与 safety filtering 机制结合，针对动力学中的任意不确定性（不限定特定分布族）提出了一种新的安全过滤方法，能在保证概率安全性的同时减少保守性。

## 2. 技术方法

基于标题和相关领域文献，本文可能采用以下技术路径：

**Distributionally robust control barrier function (DR-CBF)**：将经典 control barrier function 的约束从确定性或单一分布推广到 ambiguity set 上的 worst-case 期望或风险度量。具体来说，safety filter 的优化问题可以表述为：

- 在名义控制输入附近寻找最小修正量
- 约束条件要求 CBF 的期望下降率在 ambiguity set 内的所有分布下都满足安全条件
- Ambiguity set 通常基于 Wasserstein 距离或 moment-based 约束构造

**关键技术要素**可能包括：

1. **Ambiguity set 的构造**：基于有限采样数据，使用 Wasserstein ball 或矩约束定义不确定性分布的范围，其半径可根据数据量和置信度自适应调整。

2. **Tractable reformulation**：将 DRO 问题通过对偶理论转化为可高效求解的凸优化（如 SDP 或 SOCP），使其适用于实时控制。

3. **Safety certificate**：提供理论保证，证明在 ambiguity set 覆盖真实分布的条件下，系统状态始终保持在安全集合内的概率不低于指定阈值。

相关工作（如 arxiv 2501.03137）已展示了 distributionally robust control barrier certificate 结合 sum-of-squares programming 的可行性；arxiv 2309.08821 则将 DRO 与 CVaR 风险度量结合用于运动规划中的 safety filtering。本文可能在此基础上进一步放松对不确定性结构的假设。

## 3. 研究前沿与意义

Distributionally robust safety 是近两年 CPS 和机器人安全领域的一个高度活跃的研究方向，主要证据包括：

- 2024-2026 年间大量相关论文发表在 L4DC、CDC、ICRA、RSS、NeurIPS 等顶会
- Distributionally robust CBF 的概念在 2024 年后迅速扩展，出现了 DR-ACBF（针对 UAV）、sensor-based DR-CBF（基于传感器数据）等变体
- Safety filtering 作为一种模块化安全架构，与 learning-based control 的结合是当前的热点问题

**主要竞争方法**包括：
- Robust CBF（worst-case 方法，保守但简单）
- Stochastic CBF / chance-constrained CBF（假设已知分布）
- Conformal prediction-based safety（数据驱动，distribution-free）
- Risk-sensitive safety filter（基于 CVaR 等风险度量）

**活跃研究组**：UT Dallas CONLab（Ufuk Topcu 组）、MIT LIDS、Stanford ASL、UPenn GRASP Lab 等。

**常见发表 venue**：CDC、ACC、L4DC、ICRA、RSS、IROS、NeurIPS、AAAI。

## 4. 相关工作

1. **"Distributionally Robust CVaR-Based Safety Filtering for Motion Planning in Uncertain Environments"** (arxiv 2309.08821)
   - 提出基于 CVaR 的 distributionally robust safety filter，用于移动机器人避障
   - 与本文的关联：同样是 DRO + safety filtering 的组合，但侧重于运动规划中的障碍物避让
   - 关键区别：使用 CVaR 作为风险度量，可能对不确定性类型有更具体的假设

2. **"Distributionally Robust Control Synthesis for Stochastic Systems with Safety and Reach-Avoid Specifications"** (arxiv 2501.03137)
   - 引入 distributionally robust control barrier certificate，基于 Wasserstein ambiguity set
   - 与本文的关联：提供了 DR-CBF 的理论基础和 SOS programming 的求解框架
   - 关键区别：侧重于控制综合（synthesis）而非在线 filtering

3. **"Distributed Risk-Sensitive Safety Filters for Uncertain Discrete-Time Systems"** (arxiv 2506.07347)
   - 提出面向多智能体系统的 risk-sensitive safety filter，使用指数风险算子
   - 与本文的关联：同为 safety filter 框架下处理不确定性
   - 关键区别：针对离散时间多智能体系统，使用风险敏感（而非 distributionally robust）方法

4. **"Sensor-Based Distributionally Robust Control for Safe Robot Navigation in Dynamic Environments"** (arxiv 2405.18251)
   - 直接从距离传感器数据构造 DR-CBF 约束
   - 与本文的关联：同为 DR-CBF 方法，但从传感器端切入
   - 关键区别：强调 sensor-based 实现，不需要显式的状态估计

5. **"Probabilistic Control Barrier Functions: Safety in Probability for Discrete-Time Stochastic Systems"** (arxiv 2510.01501)
   - 提出概率 CBF 用于离散时间随机系统的有限时间安全保证
   - 与本文的关联：同为处理不确定性下的 CBF 安全保证
   - 关键区别：采用概率 CBF 而非 distributionally robust 框架

## 5. 组会讨论要点

1. **保守性与计算效率的权衡**：Ambiguity set 的大小直接影响安全保证的强度和控制的保守性。实际部署中，如何根据在线数据自适应调整 ambiguity set 的半径？是否可以结合 conformal prediction 的思路实现 distribution-free 的自适应？

2. **与组内 conformal prediction 方向的联系**：我们组在 conformal prediction for safety 方面已有积累（如 conformal reachability、PAC guarantees for reachability）。DRO-based safety filter 和 conformal prediction-based safety filter 在理论保证和实际性能上有何互补？是否可以将 conformal prediction 的覆盖率保证嵌入 DRO 的 ambiguity set 构造中？

3. **对 learning-based controller 的适用性**：当底层控制器是神经网络策略时，safety filter 的实时性要求更高。DRO-based filter 的在线计算开销是否可接受？是否需要离线预计算一部分安全集合？

## 参考文献

- "Distributionally Robust CVaR-Based Safety Filtering for Motion Planning in Uncertain Environments", arxiv 2309.08821. https://arxiv.org/abs/2309.08821
- "Distributionally Robust Control Synthesis for Stochastic Systems with Safety and Reach-Avoid Specifications", arxiv 2501.03137. https://arxiv.org/abs/2501.03137
- "Distributed Risk-Sensitive Safety Filters for Uncertain Discrete-Time Systems", arxiv 2506.07347. https://arxiv.org/abs/2506.07347
- "Sensor-Based Distributionally Robust Control for Safe Robot Navigation in Dynamic Environments", arxiv 2405.18251. https://arxiv.org/abs/2405.18251
- "Probabilistic Control Barrier Functions: Safety in Probability for Discrete-Time Stochastic Systems", arxiv 2510.01501. https://arxiv.org/abs/2510.01501
- "Distributionally Robust Safety Verification of Neural Networks via Worst-Case CVaR", arxiv 2509.17413. https://arxiv.org/abs/2509.17413
