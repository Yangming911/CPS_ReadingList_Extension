# Policy Library CBF: Finite-Horizon Safety at Runtime via Parallel Rollouts — 调研报告

> 生成日期：2026-05-19 | Reading List Monitor
> 论文来源：[arXiv:2605.16588](https://arxiv.org/abs/2605.16588)
> 作者：Taekyung Kim, Hideki Okamoto, Bardh Hoxha, Georgios Fainekos, Dimitra Panagou
> 提交日期：2026-05-15

## 1. 问题背景与研究动机

在非结构化环境中实现安全关键自主系统面临重大挑战：约束条件随环境动态演化，需要在线完成安全认证。传统的 Control Barrier Function (CBF) 安全滤波器通常依赖单一的 backup policy（如紧急制动），这种设计在以下场景中存在局限性：

- 单一 backup policy 可能过于保守，导致不必要的干预（false positive safety intervention）。
- 在环境突变时（如路面摩擦突然改变），单一 backup policy 可能无法覆盖所有安全场景。
- 不同的安全威胁可能需要不同的应对策略（如制动 vs. 转向 vs. 加速驶离）。

本文提出了 **Policy Library Control Barrier Function (PL-CBF)**，一种基于策略库的运行时安全滤波器。其核心思想是维护一个 fallback policy 的库，通过并行的有限时域 rollout 评估每个策略的安全性，选择侵入性最小的安全模式，并通过求解二次规划（QP）对名义策略进行最小修改来保证安全。

## 2. 技术方法

**策略库并行评估**：PL-CBF 在每个控制时步维护一个预定义的 fallback policy 库。每个 policy 被并行地在有限时域内 roll out（前向仿真），评估其在未来一段时间内是否能保证系统安全。

**最小侵入性选择**：在所有安全的 fallback policy 中，PL-CBF 选择与当前名义策略偏差最小的那个作为备选。这确保了安全滤波器的干预尽可能"轻柔"——只在真正需要时才偏离名义行为。

**基于 QP 的安全约束执行**：选定 fallback policy 后，通过求解一个二次规划问题，对名义控制输入进行最小修改，使得系统状态始终保持在安全集内（类似于经典 CBF-QP 的框架）。

**有限时域语言度量分析**：论文的理论贡献在于引入了有限时域语言度量（finite-horizon language metric）来刻画闭环行为，并基于此分析策略库需要满足什么样的覆盖性要求才能保证有限时域安全。

**实验验证**：
- 4 状态平面双积分器（planar double-integrator）
- 8 状态高速公路驾驶（含突变摩擦的非线性车辆模型）
- 12 状态 3D 四旋翼在拥挤动态环境中导航

所有场景均展示了相比单策略安全滤波器更好的安全覆盖率，同时保持毫秒级运行时间。

## 3. 研究前沿与意义

CBF 安全滤波器是近年来安全控制领域最活跃的研究方向之一。从 Ames et al. 的经典 CBF 理论出发，该领域已经发展出多个重要分支：

- **Runtime safety filter**：将 CBF 作为独立的安全层叠加在任意名义控制器之上，是目前最受工业界关注的应用模式。
- **Robust/Policy CBF**：RPCBF (Knoedler et al., 2024) 提出了在运行时构建对模型误差和扰动鲁棒的 CBF 系统。
- **学习与 CBF 结合**：CBF-RL 等方法将 CBF 安全滤波器集成到强化学习训练过程中。

PL-CBF 的独特贡献在于**将策略库的概念引入 CBF 框架**，解决了单一 backup policy 的覆盖性不足问题。这一思路与 motion planning 中的 contingency planning 和 multi-modal planning 有概念上的联系。

活跃的研究组包括 University of Michigan 的 Dimitra Panagou 组（CBF 与多机器人安全）、Caltech 的 Aaron Ames 组（CBF 理论基础）、Toyota Research Institute 的安全自主驾驶组。常见 venue 包括 L4DC、CDC、ICRA、RSS、RA-L 等。

## 4. 相关工作

1. **RPCBF: Constructing Robust Safety Filters via Policy Control Barrier Functions** (Knoedler et al., 2024, arXiv:2410.11157) — 提出了在运行时构建对模型误差和扰动鲁棒的 CBF 系统。与 PL-CBF 的区别在于 RPCBF 使用单一 policy 但增强鲁棒性，而 PL-CBF 通过策略库增加覆盖性。两者的思路互补。

2. **CBF-RL: Safety Filtering Reinforcement Learning in Training with Control Barrier Functions** (arXiv:2510.14959, 2025) — 将 CBF 安全滤波器集成到 RL 训练中。PL-CBF 可以作为 CBF-RL 的升级版安全滤波器，提供更好的安全覆盖。

3. **Full-Body Dynamic Safety for Robot Manipulators: 3D Poisson Safety Functions for CBF-Based Safety Filters** — 使用 3D Poisson safety function 为机械臂构建全身动态安全滤波器。与 PL-CBF 处于不同的系统层面（manipulation vs. navigation），但共享 CBF-QP 的基本框架。

4. **Can Control Barrier Functions Keep Automated Vehicles Safe in Live Freeway Traffic?** (CPS-IoT Week 2025) — 在真实高速公路交通中测试 CBF 监控的自动驾驶车辆。提供了 CBF 在实际部署中面临的挑战的第一手经验。PL-CBF 的策略库方法可能有助于解决其中发现的覆盖性问题。

5. **Combinatorial Control Barrier Functions: Nested Boolean and p-choose-r Compositions** — 通过布尔组合和 p-choose-r 组合来构建更复杂的安全约束。与 PL-CBF 的策略库思想在概念上不同但目标相似：增强 CBF 框架的表达能力和灵活性。

## 5. 组会讨论要点

1. **策略库的设计是否需要领域专家知识？** 如何自动生成或学习一个好的 fallback policy 库是一个开放问题。一个可能的方向是使用 RL 或 motion planning 算法自动生成多样化的安全策略集合。

2. **PL-CBF 与我们组在 safety filter 和 barrier certificate 方面的工作高度相关。** 特别是，如果将 PL-CBF 与 HJ reachability-based safety filter 结合（例如用 HJ-Gauss 计算的值函数来指导策略库的选择），可能实现更强的安全保证。

3. **并行 rollout 的计算开销在高维系统中是否可控？** 虽然论文报告了毫秒级运行时间，但策略库的规模和 rollout 时域长度都会影响实时性。在更复杂的系统（如多机器人协调）中，实时约束可能更紧。是否可以通过 GPU 并行化或 learned dynamics model 加速 rollout？

## 参考文献

- Kim, T., Okamoto, H., Hoxha, B., Fainekos, G., & Panagou, D. (2026). Policy Library CBF: Finite-Horizon Safety at Runtime via Parallel Rollouts. arXiv:2605.16588. https://arxiv.org/abs/2605.16588
- Knoedler, B. et al. (2024). RPCBF: Constructing Robust Safety Filters via Policy Control Barrier Functions at Runtime. arXiv:2410.11157. https://arxiv.org/abs/2410.11157
- Ames, A. D. et al. (2019). Control Barrier Functions: Theory and Applications. ECC 2019.
- Chen, Y. et al. (2025). CBF-RL: Safety Filtering Reinforcement Learning in Training with Control Barrier Functions. arXiv:2510.14959. https://arxiv.org/abs/2510.14959
- Hobbs, K. et al. (2025). Can Control Barrier Functions Keep Automated Vehicles Safe in Live Freeway Traffic? CPS-IoT Week 2025.
