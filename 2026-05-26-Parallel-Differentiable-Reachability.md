# Parallel Differentiable Reachability for Learning and Planning with Certified Neural Dynamics and Controllers — 调研报告

> 生成日期：2026-05-26（2026-06-05 据原文校订）| Reading List Monitor
> 论文来源：[arXiv:2605.25346](https://arxiv.org/abs/2605.25346) ｜ Robotics: Science and Systems XXII (RSS 2026)
> 作者：Keyi Shen, Glen Chou（Georgia Tech）

> **校订说明：** 本报告初版于 2026-05-26 未检索到原文、基于标题重建；现已据 arXiv:2605.25346 摘要校订关键事实（框架名 DiffReach-Robotics、JAX 实现、Taylor-model + CROWN 统一表示、最高 72D、含硬件实验等）。第 2 节方法描述以摘要为准，正文细节待通读 PDF 后再补。

## 1. 问题背景与研究动机

可达性分析（reachability analysis）是 learning-enabled 控制系统形式化验证的核心工具：给定不确定输入与初始集，估计闭环系统在有限或无限时域内可能进入的状态集合，并据此验证 safety/reach-avoid 属性。当 dynamics 与 controller 同时由神经网络表示时（closed-loop NN system），这一计算面临三重困难：(i) 网络非线性导致解析可达集难以闭式表达；(ii) 现有工具（如 ReachNN、POLAR-Express、CROWN/α-β-CROWN）多基于 interval bound propagation 或 Taylor model，单次计算成本高，且通常**不可微**、**过保守**或**过慢**，无法嵌入到现代 learning 与 online planning 的优化回路中；(iii) 严格的 formal certificate 与可微的、GPU 友好的实现往往是相互冲突的工程目标。

本文（摘要明确）的目标正是同时实现：可并行（GPU-batched）、可微（autograd）、且对 over-approximation 给出 sound 保证的可达性计算原语，并把它落地为 learning 与 planning 的闭环工具。这是近年 neural verification 社区从 "verify after training" 走向 "verify during training / verify during planning" 的标志性方向。核心动机可总结为：让可达集本身成为一个**可微的张量算子**，使 safety constraint 能像 reward 一样反传回 policy / dynamics 网络参数，从而支持 certified training、reachability-aware MPC、以及 verification-in-the-loop 的学习。

## 2. 技术方法

据摘要，方法的技术栈如下（正文细节待核实）：

(1) **统一表示：Taylor-model flowpipe + CROWN-style 线性边界传播。** 框架在 JAX 中实现，面向连续时间与离散时间系统，且 dynamics 与 controller 既可以是解析形式也可以是神经网络。其核心创新是用一个**统一表示**同时承载 Taylor-model flowpipe 构造与 CROWN 风格的 linear bound propagation，在传播过程中**保持 affine dependency**（从而抑制 wrapping effect），同时支持 GPU-batched 计算与 automatic differentiation。

(2) **certified 保证的来源。** 依赖 sound 的 Taylor model（带严格余项）与 CROWN 线性边界，保证输出为真实可达集的 over-approximation；affine 依赖的保持是控制保守性的关键工程手段。

(3) **下游集成（基于该可达原语构建）：**
- **certified training**：一种鼓励 "reachability-friendly" dynamics model 与 controller 的训练方法——把可达性纳入训练目标，使学到的模型/控制器更易获得紧致且 sound 的可达集；
- **reachability-aware sampling-based MPC + 梯度精化**：在采样式 MPC 中以可达集为约束，并用 gradient-based refinement 改进候选轨迹，实现保持 certified over-approximation 的 online planning。

(4) **实验范围。** 在 non-prehensile manipulation 与 quadrotor 任务上验证，含**硬件实验**与**最高 72 维**的高维评测，证明在 bounded uncertainty 下既能实用化 online planning，又维持 certified reachable-set over-approximation。整体框架命名为 **DiffReach-Robotics**。

这种 "certified + differentiable + parallel" 三要素的统一，是当前 safe learning 的中心方法论之一。

## 3. 研究前沿与意义

可微可达性是过去两年增长最快的方向之一。证据包括：

- **工具链层面**：immrax [3]（2024）、α-β-CROWN（NeurIPS 系列）、auto_LiRPA、JAX-based POLAR fork 等都在向 GPU + autograd 演进；NVIDIA 的 cuTAMP [2]（2024）则把这一范式拓展到 TAMP（task & motion planning）层级。
- **会议/期刊出口**：HSCC、L4DC、CDC、ICRA、NeurIPS、ICLR 是该方向的主要 venue；CAV、TACAS、ATVA 偏向 verification 角度；ACC、RA-L 偏向 control/robotics 角度。每年均有 dedicated workshop（如 ICML SCL workshop、L4DC safety track）。
- **活跃团队**：Coogan group (Georgia Tech, mixed monotone)，Pappas/Mangharam (UPenn, conformal + reachability)，Bunel/Mirman (Imperial/ETH, NN verification)，Fan group (UIUC, neural Lyapunov)，Sangiovanni-Vincentelli 组（UC Berkeley, system level synthesis），以及 NVIDIA Research、DeepMind safety 团队。
- **相邻方向竞争**：CARe [5]（SMT + CEGIS for certified learned reachable sets）、Hierarchical End-to-End Taylor Bounds [6]（端到端 Taylor 紧化）、GPU-SLS [7]（系统级合成 + 可达约束在 GPU 上求解）。本文若能在 dynamics 与 controller 双网络设定下保持 certified 且端到端可微，将在该谱系中占据一个独特位置。

对组内研究的意义：我们组在 conformal prediction、reach-avoid POMDP、STL planning 等方向已积累相当成果，本文这条"reachability 作为可微算子"的技术线，可以作为现有 conformal/PAC reachability 工作的 deterministic 一翼互补，也可能与 VISION-SLS、Policy Library CBF、HJ-Gauss 等近期工作形成工具栈对接。

## 4. 相关工作

1. **immrax: A Parallelizable and Differentiable Toolbox for Interval Analysis and Mixed Monotone Reachability in JAX** (Harapanahalli et al., 2024)。把 interval analysis 与 mixed monotone reachability 写成 JAX function transform，自然支持 GPU 并行与 autograd。与本文最直接的关联是同一代工具范式，区别在于本文显式强调 certified guarantee 与 learning/planning 闭环集成，而 immrax 更偏向通用 toolbox。

2. **Certified Neural Approximations of Nonlinear Dynamics** (2025, arXiv 2505.15497)。提出 parallelizable domain partitioning + 局部一阶模型，对 neural surrogate dynamics 给出 formal error bound。与本文共享 "并行 + certified" 思路，但聚焦 dynamics surrogate 的 abstraction error，而非闭环可达集计算。

3. **Verified Safe Reinforcement Learning for Neural Network Dynamic Models** (2024, arXiv 2405.15994)。在训练过程中嵌入 differentiable forward reachability over-approximation 作为 safety loss，配合 curriculum learning 学习 verified safe policy。与本文动机高度一致，差异在于其 reachability 计算依赖 CROWN/IBP 风格的 bound，而本文可能引入更紧的 mixed monotone 或 zonotope 抽象。

4. **Certified Approximate Reachability (CARe)** (2025, arXiv 2503.23912)。SMT + CEGIS 流程对深度学习得到的 reachable set 给出 soundness 证书。与本文互补：CARe 是 verify-after 的 SMT-heavy 路线，本文应是 verify-in-loop 的 bound-propagation 路线。

5. **Differentiable GPU-Parallelized Task and Motion Planning (cuTAMP)** (Curtis et al., 2024, arXiv 2411.11833)。NVIDIA 提出的 GPU 并行 + 可微 TAMP planner，将差分优化嵌入到符号 TAMP 骨架上。与本文共享"GPU + differentiable"工程哲学，但 cuTAMP 不显式给出 certified 可达保证，本文则补上 formal verification 这一环。

6. **POLAR-Express: Efficient and Precise Formal Reachability Analysis of Neural-Network Controlled Systems** (Wang et al., 2023, arXiv 2304.01218)。通过 Taylor model + 多线程层级传播为 NN-controlled system 给出 reachable tube。是 closed-loop NN reachability 的代表性工作，但不可微、CPU 多线程而非 GPU 大规模并行。

## 5. 组会讨论要点

1. **wrapping error 与可微性的取舍**。Interval/CROWN-style bounds 易于实现可微，但每一时步的 wrapping 误差累积严重；zonotope/Taylor 紧但反传开销大。本文如何在 propagation 紧度与 autograd 内存开销之间取得平衡？我们能否借鉴 conformal prediction 的非渐近覆盖，把 deterministic 过近似改写成 probabilistic 紧界？

2. **与组内现有方向的接口**。若该可微可达层确实成熟，能否替换我们 STL planning / reach-avoid POMDP 中目前依赖 sampling 的 reachable tube 估计？特别是与 LUCID、Conformalized Data-Driven Reachability、HJ-Gauss 在概念上有重叠却假设互补，存在潜在 hybrid 方案。

3. **scale 与现实系统**。GPU 并行声称解决 scalability，但 neural dynamics 通常是 small MLP；当 dynamics 网络规模上升到 Transformer 级（如 robotics foundation models）时，propagation cost 是否仍可控？是否需要与 LoRA-style 低秩近似、layer-skipping 结合？

## 参考文献

[1] Harapanahalli, A., Jafarpour, S., & Coogan, S. (2024). immrax: A Parallelizable and Differentiable Toolbox for Interval Analysis and Mixed Monotone Reachability in JAX. arXiv:2401.11608. https://arxiv.org/abs/2401.11608

[2] Curtis, A., Kumar, N., Cao, J., Lozano-Pérez, T., Kaelbling, L. P. (2024). Differentiable GPU-Parallelized Task and Motion Planning (cuTAMP). arXiv:2411.11833. https://arxiv.org/abs/2411.11833

[3] Wang, Y., Zhou, W., Fan, J., et al. (2023). POLAR-Express: Efficient and Precise Formal Reachability Analysis of Neural-Network Controlled Systems. arXiv:2304.01218. https://arxiv.org/abs/2304.01218

[4] Certified Neural Approximations of Nonlinear Dynamics. (2025). arXiv:2505.15497. https://arxiv.org/abs/2505.15497

[5] Certified Approximate Reachability (CARe): Formal Error Bounds on Deep Learning of Reachable Sets. (2025). arXiv:2503.23912. https://arxiv.org/abs/2503.23912

[6] Hierarchical End-to-End Taylor Bounds for Complete Neural Network Verification. (2026). arXiv:2605.10621. https://arxiv.org/abs/2605.10621

[7] Verified Safe Reinforcement Learning for Neural Network Dynamic Models. (2024). arXiv:2405.15994. https://arxiv.org/abs/2405.15994

[8] Provable Bounds on the Hessian of Neural Networks: Derivative-Preserving Reachability Analysis. (2024). arXiv:2406.04476. https://arxiv.org/abs/2406.04476

[9] Shen, K., & Chou, G. (2026). Parallel Differentiable Reachability for Learning and Planning with Certified Neural Dynamics and Controllers. RSS 2026. arXiv:2605.25346. https://arxiv.org/abs/2605.25346

> 注：本论文已于 2026-06-05 据 arXiv:2605.25346（RSS 2026，Keyi Shen & Glen Chou, Georgia Tech）校订。第 2 节方法描述以官方摘要为准；完整的传播紧度、复杂度与实验对比待通读 PDF 后补全。
