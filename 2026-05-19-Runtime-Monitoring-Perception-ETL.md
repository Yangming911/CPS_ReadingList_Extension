# Runtime Monitoring of Perception-Based Autonomous Systems via Embedding Temporal Logic — 调研报告

> 生成日期：2026-05-19 | Reading List Monitor
> 论文来源：[arXiv:2605.12651](https://arxiv.org/abs/2605.12651)
> 作者：Parv Kapoor, Abigail Hammer, Ashish Kapoor, Karen Leung, Eunsuk Kang
> 提交日期：2026-05-12

## 1. 问题背景与研究动机

自主系统的 runtime monitoring 传统上依赖将连续传感器观测映射到基于低维状态变量定义的离散逻辑命题。然而，在以感知驱动的场景中，这种抽象方式面临根本性困难：所需的映射模块通常计算开销大、鲁棒性差，且与高层语义存在 misalignment。例如，对于一个操作机器人，如何用传统的 Signal Temporal Logic (STL) 谓词精确表达"靠近目标物体"或"远离危险区域"等视觉语义概念？

本文的核心贡献在于提出了 **Embedding Temporal Logic (ETL)**，一种直接在学习得到的 embedding 空间中执行监控的时序逻辑。ETL 通过观测 embedding 与参考 embedding 之间的距离来定义谓词，使规约能够捕获高层感知概念（如与视觉目标的相似性、对语义区域的回避等），这些概念在传统谓词框架下难以或无法表达。通过将这些谓词与时序算子组合，ETL 自然地表达了时序扩展的、序列化的感知行为。

## 2. 技术方法

ETL 的技术框架包含以下关键组件：

**Embedding 谓词定义**：ETL 中的原子谓词基于 embedding 空间中的距离度量。给定一个观测 embedding 和一个从参考观测导出的目标 embedding，谓词的满足性由两者之间的距离是否低于某个阈值决定。这种设计利用了预训练视觉模型（如 foundation model）学到的语义表示。

**时序算子组合**：ETL 支持标准的时序逻辑算子（如 eventually、always、until 等），使用户可以指定诸如"先到达A区域附近，然后避开B区域，最终到达C区域"等复杂的时序行为规约。

**Conformal calibration**：为了提供可靠的谓词评估，论文引入了 conformal prediction 方法来校准距离阈值。这一过程为谓词评估提供了面向安全的统计保证，使得监控器在不确定性下仍能做出可靠判断。

**有界 trace 上的监控算法**：论文提出了在有界 embedding trace 上评估 ETL 规约的监控算法，支持在线执行。

实验在多个 manipulation 环境中进行，结果表明 ETL 与 ground-truth 语义达成了较高的经验一致性，包括对时序组合行为的准确监控。

## 3. 研究前沿与意义

Runtime monitoring 和 runtime verification 是形式化方法与自主系统交叉领域的核心课题，近年来持续受到关注。传统方法主要基于 Signal Temporal Logic (STL) 和 Metric Temporal Logic (MTL)，在状态空间明确定义的系统中表现良好（如 PerceMon 工具用于自动驾驶感知系统监控）。

然而，随着 foundation model 和端到端学习系统的普及，传统的"感知→状态估计→逻辑监控"范式面临瓶颈。ETL 代表了一个新的研究方向：**直接在学习得到的表示空间中进行形式化推理**。这一思路与 Conformal Prediction 在安全保证中的广泛应用趋势相呼应。

活跃的研究组包括 CMU 的 Eunsuk Kang 组（软件工程与形式化方法）、University of Washington 的 Karen Leung 组（机器人安全）。常见的发表 venue 包括 ICRA、RSS、L4DC、CAV、RV (Runtime Verification) 等。

## 4. 相关工作

1. **PerceMon: Online Monitoring for Perception Systems** (Balakrishnan & Deshmukh, 2021) — 提出了 Timed Quality Temporal Logic (TQTL) 及其空间算子扩展，用于监控自动驾驶中的物体检测和跟踪算法。与 ETL 的区别在于 PerceMon 仍依赖传统的 bounding box 级别的谓词，而非 embedding 空间。

2. **Vision-Based Runtime Monitoring under Varying Specifications using Semantic Latent Representations** (arXiv:2605.13923, 2026) — 同样探索在语义潜空间中进行 runtime monitoring，但侧重于规约随环境变化的动态调整问题，与 ETL 的 conformal calibration 方法互补。

3. **STLCG++: A Masking Approach for Differentiable Signal Temporal Logic** — 提供了可微分的 STL 计算框架，使 STL 规约可以集成到基于梯度的优化中。ETL 在表达能力上更强（支持感知语义），但 STLCG++ 在可微性上有优势。

4. **Conformal Reachability for Safe Control** — 利用 conformal prediction 提供安全保证的 reachability 方法。与 ETL 共享了 conformal prediction 的技术工具，但应用在不同层面（控制 vs. 监控）。

5. **Pretrained Embeddings as a Behavior Specification Mechanism** (arXiv:2503.02012, 2025) — ETL 的早期工作，首次提出将预训练 embedding 作为行为规约机制的概念，本文是其在 runtime monitoring 方向的系统化扩展。

## 5. 组会讨论要点

1. **ETL 的谓词校准依赖于 conformal prediction，那么在分布漂移（distribution shift）场景下，校准的有效性如何保证？** 自主系统在部署中经常面临 out-of-distribution 输入，conformal guarantee 的前提假设（exchangeability）是否能够满足？这关系到 ETL 在实际部署中的可靠性。

2. **ETL 与我们组在 STL/LTL-based 安全验证方面的研究有天然的互补性。** 我们组已有大量基于传统时序逻辑的工作（如 barrier certificate、reachability analysis），ETL 提供了一条将这些框架扩展到感知驱动系统的路径。一个有趣的方向是：能否将 ETL 谓词与传统状态空间谓词混合使用？

3. **Embedding 空间的选择对 ETL 性能有多大影响？** 不同的预训练模型（CLIP、DINOv2 等）可能提供语义质量差异很大的 embedding。未来是否需要 task-specific 的 embedding 微调，还是通用 foundation model 的 embedding 就足够好？

## 参考文献

- Kapoor, P., Hammer, A., Kapoor, A., Leung, K., & Kang, E. (2026). Runtime Monitoring of Perception-Based Autonomous Systems via Embedding Temporal Logic. arXiv:2605.12651. https://arxiv.org/abs/2605.12651
- Balakrishnan, A. & Deshmukh, J. (2021). PerceMon: Online Monitoring for Perception Systems. arXiv:2108.08289. https://arxiv.org/abs/2108.08289
- Kapoor, P. et al. (2025). Pretrained Embeddings as a Behavior Specification Mechanism. arXiv:2503.02012. https://arxiv.org/abs/2503.02012
- Leung, K. et al. (2026). Vision-Based Runtime Monitoring under Varying Specifications using Semantic Latent Representations. arXiv:2605.13923. https://arxiv.org/abs/2605.13923
- Hofgard, E. et al. (2024). Convergence Guarantees for Neural Network-Based Hamilton-Jacobi Reachability. arXiv:2410.02904. https://arxiv.org/abs/2410.02904
