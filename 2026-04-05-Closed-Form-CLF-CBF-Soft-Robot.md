# A Closed-Form CLF-CBF Controller for Whole-Body Continuum Soft Robot Collision Avoidance — 调研报告

> 生成日期：2026-04-05 | Reading List Monitor
> 论文来源：[CatalyzeX](https://www.catalyzex.com/paper/a-closed-form-clf-cbf-controller-for-whole)

## 1. 问题背景与研究动机

Continuum soft robot（连续体软体机器人）因其材料柔顺性而具备天然的被动安全性，在人机协作、微创手术等场景中具有广阔的应用前景。然而，仅靠材料层面的被动安全性不足以保证可靠的碰撞回避——当软体机器人在复杂环境中执行任务时，仍然需要**主动控制策略**来确保 whole-body collision avoidance（全身碰撞回避）。

现有方法主要包括两类：(1) sampling-based motion planning（基于采样的运动规划），计算开销大且缺乏形式化安全保证；(2) 基于在线优化的 CLF-CBF quadratic programming（二次规划），虽然提供形式化保证但存在实时性瓶颈和 feasibility 问题。对于软体机器人而言，其高维的构型空间（连续弯曲/伸长）使得这些问题更加突出。

本文的核心贡献是推导出一个**解析形式（closed-form）**的 CLF-CBF 控制器，完全避免了在线优化求解器，实现了相比标准 CLF-CBF QP 快 **10 倍**、相比 sampling-based planner 快 **100 倍**的计算效率，同时保持了严格的稳定性（CLF）和安全性（CBF）保证。

## 2. 技术方法

本文的技术路线建立在 Control Lyapunov Function（CLF）和 Control Barrier Function（CBF）的统一框架之上，其核心创新在于推导出 closed-form 的控制律。

**Control Lyapunov Function (CLF)：** CLF 保证系统的稳定性和目标导向行为。通过构造 Lyapunov 函数 V(x)，使得控制输入能够保证 V̇(x) ≤ -αV(x)，从而实现渐近稳定性和轨迹跟踪。

**Control Barrier Function (CBF)：** CBF 用于编码安全约束。定义安全集合为 {x : h(x) ≥ 0}，通过保证 ḣ(x) ≥ -γh(x)，确保系统状态始终停留在安全区域内，从而实现碰撞回避。

**Closed-Form 综合（核心创新）：** 传统 CLF-CBF 方法需要在每个控制步求解一个 QP 来同时满足 CLF 和 CBF 约束。本文的关键贡献在于推导出显式的解析控制律，直接计算出满足两类约束的控制输入，无需任何在线优化循环。这不仅消除了 QP 求解的计算负担，还避免了在线优化可能出现的 feasibility 问题。

**连续体软体机器人建模：** 采用 piecewise constant strain（PCS）模型或 Cosserat rod 模型描述软体机器人的运动学。主要考虑 tendon-driven（腱驱动）的执行机构，处理高维构型空间和欠驱动动力学。

**实时距离计算：** 使用可微的 signed distance field 进行 3D whole-body 碰撞检测，确保距离度量对控制输入可微，从而能够嵌入 CBF 框架中。

## 3. 研究前沿与意义

CLF-CBF 与软体机器人的结合是一个**正在快速发展的前沿方向**（2024–2025 年）。主要依据：

- 2024–2025 年间出现了多篇高影响力论文，涵盖 closed-form CLF-CBF、high-order CBF for soft robots、optimization-free CBF 等主题
- ICRA、IROS、RoboSoft 等顶级机器人会议上，soft robotics safety track 的投稿量持续增长
- 该方向处于三个成熟领域的交汇点：控制理论（CLF-CBF 理论趋于成熟）、软体机器人（应用日益广泛）、safety-critical systems（形式化保证需求增长）

**主要发表 venue：**
- IEEE ICRA（International Conference on Robotics and Automation），录取率约 25–30%
- IEEE IROS（Intelligent Robots and Systems），2025 年录取率约 46%
- IEEE RoboSoft（Soft Robotics Conference），专业化 venue，影响力增长中
- RSS（Robotics: Science and Systems），录取率约 20%，理论导向

**活跃研究组：**
- Georgia Tech Aerospace Robotics Lab：CBF 理论及应用
- MIT Humanoid Robotics Group：全身控制与形式化保证
- UC San Diego Gravish Lab：软体机器人与具身智能
- Caltech AMES Group（Aaron Ames）：CBF 理论奠基工作
- Berkeley Hybrid Robotics Lab：safety-critical 与自适应控制

## 4. 相关工作

**1. Contact-Aware Safety in Soft Robots Using High-Order CBF and Lyapunov Functions**
- 来源：arXiv:2505.03841 (2025)
- 与本文的关联：本文方法的直接扩展，将 closed-form 方法推广到接触力约束
- 关键区别：使用 High-Order CBF (HOCBF) 和 HOCLF，结合 Piecewise Cosserat-Segment 动力学，处理力约束而非仅几何约束

**2. Humanoid Self-Collision Avoidance Using Whole-Body Control with CBF**
- 来源：arXiv:2207.00692 (2022)
- 与本文的关联：将 CBF 应用于刚性人形机器人的全身控制
- 关键区别：面向刚性系统，软体机器人额外面临连续变形带来的建模和控制挑战

**3. Optimization-free Smooth Control Barrier Function for Polygonal Collision Avoidance**
- 来源：arXiv:2502.16293 (2025)
- 与本文的关联：同属 optimization-free CBF 方向的并行发展
- 关键区别：针对多边形障碍物的平滑 CBF，使用保守的多边形碰撞检测；本文面向连续体软体机器人的 3D 全身碰撞回避

**4. Safe Control for Soft-Rigid Robots with Self-Contact using CBF**
- 来源：arXiv:2311.03189 (2023)
- 与本文的关联：将 CBF 应用于 soft-rigid 混合系统的自碰撞回避
- 关键区别：使用 Piecewise Constant Curvature 运动学处理自碰撞场景

**5. Universal Formula Families for Safe Stabilization of Single-Input Nonlinear Systems**
- 来源：arXiv:2603.22654 (2025)
- 与本文的关联：为 closed-form CLF-CBF 综合提供数学理论基础
- 关键区别：偏向理论，推导了安全稳定化反馈律的通用公式族

## 5. 组会讨论要点

**1. Closed-Form 方案的适用性边界**
本文通过解析方法避免了在线优化，但 closed-form 解的存在性依赖于特定的系统结构和约束形式。讨论：对于哪些类型的 CBF 和系统动力学，closed-form 解是可推导的？当障碍物数量增加或形状更复杂时，解析解是否仍然存在？这直接关系到方法的 scalability。

**2. 与我们组研究方向的潜在联系**
我们组的工作涉及 CPS 的 safety verification 和 barrier certificate。本文的 CBF 方法本质上是一种 barrier certificate 在控制器设计中的应用。可以探讨：(1) 能否将我们的 barrier certificate synthesis 方法与软体机器人的运动学模型结合？(2) 对于 learning-enabled 的软体机器人控制器，如何验证其满足 CBF 约束？

**3. 建模假设对安全保证的影响**
Piecewise constant strain 等简化模型与实际软体机器人行为之间存在 modeling gap。在 sim-to-real transfer 中，这种 gap 是否会破坏 CBF 提供的形式化安全保证？是否需要鲁棒 CBF（robust CBF）来处理建模不确定性？文中声称的 10×/100× 加速在实际硬件实验中是否得到了验证？

## 参考文献

1. "A Closed-Form CLF-CBF Controller for Whole-Body Continuum Soft Robot Collision Avoidance." https://www.catalyzex.com/paper/a-closed-form-clf-cbf-controller-for-whole
2. "Contact-Aware Safety in Soft Robots Using High-Order CBF and Lyapunov Functions." arXiv:2505.03841, 2025. https://arxiv.org/abs/2505.03841
3. "Humanoid Self-Collision Avoidance Using Whole-Body Control with Control Barrier Functions." arXiv:2207.00692, 2022. https://arxiv.org/abs/2207.00692
4. "Optimization-free Smooth Control Barrier Function for Polygonal Collision Avoidance." arXiv:2502.16293, 2025. https://arxiv.org/abs/2502.16293
5. "Safe Control for Soft-Rigid Robots with Self-Contact using Control Barrier Functions." arXiv:2311.03189, 2023. https://arxiv.org/abs/2311.03189
6. "Universal Formula Families for Safe Stabilization of Single-Input Nonlinear Systems." arXiv:2603.22654, 2025. https://arxiv.org/abs/2603.22654
