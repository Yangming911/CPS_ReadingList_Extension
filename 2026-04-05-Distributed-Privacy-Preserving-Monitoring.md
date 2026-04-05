# Distributed Privacy-Preserving Monitoring — 调研报告

> 生成日期：2026-04-05 | Reading List Monitor
> 论文来源：[arXiv:2603.20107](https://arxiv.org/abs/2603.20107)

## 1. 问题背景与研究动机

Runtime verification（运行时验证）是形式化方法的一个重要分支，其核心思想是在系统运行过程中持续监测系统行为是否满足给定的 specification。然而，在许多实际场景中，**隐私**成为一个不可忽视的问题：系统（System）不希望监控方（Monitor）获知其完整的执行轨迹（trace），而监控方也不希望系统获知其所验证的 specification。例如，银行的交易监控系统需要验证合规性，但交易数据和合规规则都属于敏感信息。

传统的 runtime verification 方案面临两难：要么将 specification 暴露给系统，要么将 trace 暴露给监控方。已有工作尝试使用 fully homomorphic encryption（FHE）等重量级密码学工具实现隐私保护，但计算开销极大，难以满足实时监控的需求。

本文提出了一种**分布式隐私保护监控**框架，核心思想是将监控功能分布到多个参与方中（要求至少一方诚实），利用高效的 **secret-sharing scheme** 替代昂贵的加密原语，从而在保证双向隐私的同时实现高效的持续监控。

**核心贡献：**
- 提出了首个支持**有状态（stateful）**持续监控的分布式隐私保护协议，解决了先前 secret-sharing 方案仅支持一次性计算的局限
- 实现了双向隐私保证：监控方仅获知最终判定结果（满足/违反），系统不获知 specification 内容
- 通信开销为线性级别（初始化后每个观测步骤仅需单次消息交换）

**作者团队：** Mahyar Karimi、K.S. Thejaswini、Roderick Bloem、Thomas A. Henzinger，分别来自 ISTA（奥地利科学技术研究所）和 TU Graz（格拉茨理工大学）。Thomas Henzinger 是形式化方法领域的顶尖学者，曾长期领导 ISTA 的相关研究。

## 2. 技术方法

本文的技术路线可以概括为以下几个层面：

**分布式监控架构：** 将单一 monitor 的功能分布到多个参与方，采用 semi-honest adversary model（半诚实对手模型），要求至少一方保持诚实。这种架构上的改变使得可以使用 secret-sharing 而非 FHE，显著降低计算复杂度。

**Secret Sharing 基础：** 采用 Shamir secret sharing 或类似方案，将 specification 的内部状态和系统 trace 分别以 share 的形式分布到各参与方。关键技术难点在于 share conversion——在 arithmetic share 和 Boolean share 之间的高效转换，以支持 temporal logic specification 中的混合运算。

**有状态监控协议：** 这是本文最核心的创新点。先前的 secret-sharing 方案局限于 one-shot execution，无法处理需要维护内部状态的持续监控场景。本文设计了能够在多轮观测中保持状态秘密性的协议，同时维持 information-theoretic privacy guarantee。

**Specification 支持：** 框架支持 LTL（Linear Temporal Logic）和 STL（Signal Temporal Logic）等时序逻辑规范，通过将 specification 转换为 automata 或兼容 secret-sharing 的评估算法来实现。

**性能特征：** 初始化阶段完成 share 分发后，每个时间步仅需线性级别的通信开销；计算复杂度为多项式级别，相比 FHE 方案的指数级开销有质的提升。

## 3. 研究前沿与意义

隐私保护监控是一个**快速发展的研究方向**，近年来出现了明显的发表量增长。主要证据包括：

- 2024–2025 年间出现了多篇相关高质量论文，包括同一作者团队在 CCS 2025 上的前序工作
- 顶级会议开始接受此方向的论文：CCS 2025、RV 2024–2025、CAV 等
- 多个独立研究组从不同角度切入：ISTA（secret sharing）、Oregon State/UC Berkeley（garbled circuits）、University of Delaware（stream monitoring）

该方向的驱动力主要来自**监管需求**的增长（GDPR、医疗器械标准、金融合规等），以及 CPS 场景中对实时、隐私保护监控的实际需求。

**主要发表 venue：**
- 形式化方法方向：CAV、RV（Runtime Verification）、HSCC
- 安全方向：CCS、ESORICS
- CPS 方向：ICCPS、CPS-IoT Week

**活跃研究组：**
- ISTA（Thomas Henzinger 组）：形式化方法与监控
- TU Graz（Roderick Bloem 组）：形式化验证与综合
- Oregon State（Mike Rosulek 组）：密码学基础

## 4. 相关工作

**1. Monitoring in the Dark: Privacy-Preserving Runtime Verification of Cyber-Physical Systems**
- 作者：Charles Koll, Preston Tan, Mike Rosulek, Houssam Abbas
- 来源：arXiv:2505.16059 (2025)
- 与本文的关联：解决同一问题但使用 garbled circuits 而非 secret sharing，适用于 STL specification 的隐私保护监控
- 关键区别：garbled circuits 方案的通信开销更大但不需要多方参与的假设，适合不同场景

**2. Privacy-Preserving Runtime Verification**
- 作者：T.A. Henzinger, M. Karimi, K.S. Thejaswini
- 来源：CCS 2025
- 与本文的关联：同一作者团队的前序工作，建立了隐私保护 runtime verification 的基础协议
- 关键区别：前序工作侧重于理论框架和安全性证明，本文侧重于分布式实现和有状态监控

**3. Privacy-Preserving Distributed Stream Monitoring**
- 作者：Arik Friedman, Lior Sharfman 等
- 来源：学术会议 (2014)
- 与本文的关联：分布式隐私保护监控的早期工作，处理任意函数的分布式监控
- 关键区别：侧重于统计聚合函数，不支持 temporal logic specification

**4. PriStream: Privacy-Preserving Distributed Stream Monitoring System**
- 来源：INFOCOM 2016
- 与本文的关联：实用的分布式隐私保护流监控系统
- 关键区别：面向百分位数等特定统计指标，而非形式化 specification

**5. Monitoring Temporal Information Flow**
- 作者：Rayna Dimitrova 等
- 来源：ISOLA 2012
- 与本文的关联：从 temporal logic 角度研究信息流的隐私属性（SecLTL with Hide operator）
- 关键区别：关注 specification 层面的信息流建模，而非监控协议本身的隐私保护

## 5. 组会讨论要点

**1. 技术方案的取舍：Secret Sharing vs. Garbled Circuits vs. FHE**
三种密码学方案各有利弊：FHE 不需要多方假设但计算极重；garbled circuits 通信开销大但不需要诚实方假设；secret sharing 最轻量但需要至少一个诚实参与方。在 CPS 实际部署中，哪种方案更具可行性？semi-honest adversary model 在工业场景中是否足够？

**2. 与我们组研究方向的联系**
我们组关注 CPS 的 safety verification 和 temporal logic specification。本文的隐私保护监控框架是否可以应用于我们的 runtime verification 工作？特别是在多方协作的 CPS 场景（如多机器人系统、智能交通）中，监控协议的隐私性可能是一个重要的实际需求。

**3. 开放问题与后续方向**
- 如何处理**异步通信**和网络故障场景下的隐私保护监控？
- 对于包含 learning-enabled component 的 CPS，如何在保护训练数据隐私的同时进行 runtime verification？
- 多个 privacy-preserving monitor 的组合性（compositionality）问题：能否将多个独立的隐私监控器组合为更大的系统级监控方案？

## 参考文献

1. M. Karimi, K.S. Thejaswini, R. Bloem, T.A. Henzinger. "Distributed Privacy-Preserving Monitoring." arXiv:2603.20107, 2026. https://arxiv.org/abs/2603.20107
2. C. Koll, P. Tan, M. Rosulek, H. Abbas. "Monitoring in the Dark: Privacy-Preserving Runtime Verification of Cyber-Physical Systems." arXiv:2505.16059, 2025. https://arxiv.org/abs/2505.16059
3. T.A. Henzinger, M. Karimi, K.S. Thejaswini. "Privacy-Preserving Runtime Verification." CCS 2025. https://dl.acm.org/doi/10.1145/3719027.3765137
4. A. Friedman, L. Sharfman et al. "Privacy-Preserving Distributed Stream Monitoring." 2014.
5. R. Dimitrova et al. "Monitoring Temporal Information Flow." ISOLA 2012.
