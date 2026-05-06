# Beyond alignment: Why robotic foundation models need context-aware safety — 调研报告

> 生成日期：2026-05-07 | Reading List Monitor
> 论文来源：Science Robotics, 2026 | https://www.science.org/doi/10.1126/scirobotics.aef2191
> 作者团队：Alexander Robey 等（Penn Engineering、Carnegie Mellon University、University of Oxford）

## 1. 问题背景与研究动机

随着视觉-语言-动作（VLA）类 robotic foundation models 从实验室走入家庭、医院和仓储等真实场景，其安全问题从"模型是否会输出有害文本"转变为"是否会驱动一个具身平台造成物理伤害"。本文的核心论点是：当前主流的 alignment 方法（RLHF、constitutional AI、refusal training 等）均针对 disembodied 的 chatbot 体系——其威胁面是 token 空间，护栏对象是 pixel 与字符串。然而当 LLM/VLM 被嵌入机器人控制回路后，输出空间变成了关节力矩、抓取动作和移动速度，威胁随上下文（操作对象、周围人员、环境物理状态）剧烈变化，远超文本对齐能涵盖的范畴。

文章列举了多个证据：现有的 chatbot 风格 jailbreak（甚至简单的 prompt 注入）即可让 robotic foundation model 执行明显不安全的物理动作（如撞向人、抓取危险物品），而仅以输出端文本检查作为护栏的方法无法识别"行为本身在当前情境下不安全"。作者据此呼吁建立 layered, context-aware safety guardrails——将形式化方法、运行时监控、行为规范与具身上下文信息结合，形成多阶段安全检查点，并在训练阶段加入 context-rich safety data，而非仅依赖事后对齐微调。

## 2. 技术方法

本文是一篇 perspective/position paper，主要贡献在于框架性论述而非新算法。提出的 layered safety architecture 大致包含四个层级：

1. **Explicit behavioral rules**：通过形式化规约（如 LTL/STL、constitution-style rules）明确 robot 在不同 context 下被允许/禁止的行为类别，作为不可越过的硬约束。
2. **Multi-stage safety checkpoints**：在 perception → planning → low-level control 的每一阶段插入独立的安全检查器（例如 vision-based scene risk estimator、symbolic plan verifier、CBF/HJ-reachability 形式的运行时滤波器），形成 defense-in-depth。
3. **Context-rich safety training data**：构造包含真实物理交互、人员存在、危险物品识别等场景的 safety dataset，让 foundation model 在预训练或微调阶段就学习 context-dependent 风险评估，而非仅依赖输出端拒答。
4. **Runtime context tracking**：维护机器人当前任务、环境状态、人员位置等动态上下文信息，并将其作为安全决策的显式输入，使同一动作在不同情境下可以被允许或拒绝。

文章亦指出与传统 control-theoretic safety（CBF、HJ reachability、MPC with constraints）和 formal methods（model checking、shielding）的衔接问题，强调 foundation model 时代不能抛弃这些已有工具，而需要将它们与 learned components 协同设计。

## 3. 研究前沿与意义

机器人基础模型安全是 2025–2026 年迅速升温的研究方向。过去一年内的相关线索包括：Google DeepMind 的 *Generating Robot Constitutions & Benchmarks for Semantic Safety*（2025），CMU/Penn 的多篇关于 VLA jailbreak 的工作，以及多个新涌现的 venue：CoRL 2025/2026 的 *Safe Robot Learning* workshop、ICRA 2026 的 *Trustworthy Embodied AI* track、NeurIPS 2025 的 *Foundation Models for Decision Making* workshop 等。Science Robotics 接收 perspective 文章本身就反映了社区对该议题的共识——单纯沿用 LLM alignment 工具链已不够。

主要的竞争/互补方法可分为三派：(i) 形式化派（CBF/HJ/shielding），代表团队包括 Caltech (Ames)、UPenn (Pappas)、ETHZ；(ii) constitutional/规则派，以 Google DeepMind 和 Anthropic 的工作为代表；(iii) 运行时监控/异常检测派，以 MIT、UC Berkeley 的 OOD detection、conformal prediction 工作为代表。本文实际上是在呼吁三派融合而非取代。常见 venue 包括 Science Robotics、CoRL、ICRA、RSS、IJRR，以及 NeurIPS/ICML 的 safe RL track。

## 4. 相关工作

- **Towards Safe Robot Foundation Models Using Inductive Biases** (arXiv:2505.10219)。讨论如何在 robot foundation model 的网络结构与训练目标中嵌入 safety inductive bias，与本文的"context-rich training data"层互补。
- **Generating Robot Constitutions & Benchmarks for Semantic Safety** (arXiv:2503.08663)。Google DeepMind 提出基于自然语言 constitution 的 robot 行为规约方法，以及配套的 semantic safety benchmark。本文 explicit behavioral rules 层正是此类思路的代表。
- **Safe Learning for Contact-Rich Robot Tasks: A Survey from Classical Learning-Based Methods to Safe Foundation Models** (arXiv:2512.11908)。系统性综述，覆盖从经典 safe RL 到最新 safe foundation models 的方法谱系，可作为本文论点的"实证"补充。
- **Safety Guardrails for LLM-Enabled Robots**（已在 reading list 上）。聚焦 LLM 控制下的具体 guardrail 设计，是本文 layered architecture 的具体实例化方向。
- **Contextual Safety Reasoning and Grounding for Open-World Robots**（已在 reading list 上）。直接体现"context-aware"思想，可与本文 perspective 对照阅读。

## 5. 组会讨论要点

1. **形式化方法与 foundation model 的接口设计**：layered safety 中如何把 LTL/CBF/shielding 这类硬约束高效地接入 VLA 的输出端？是事后过滤（unsafe action → 拒绝），还是事前 shaping（把约束编码进 policy decoding）？两者在性能与可证安全性之间的权衡如何评估？这与组里在 *VISION-SLS*、*Bellman Value Decomposition* 等方向的工作有直接联系。
2. **Context 的形式化表示**：本文反复强调 context-aware，但 context 在论文中仍是较抽象的概念。组会可讨论：是否存在一个统一的"context schema"——例如 (任务、对象、人员分布、物理风险) 的多维向量——能被 perception 层稳定提取并传给 safety 层？这本质上是 perception-level safety 与 task-level safety 的耦合问题。
3. **评测基准缺失**：目前 robotic foundation model safety 缺乏被广泛接受的 benchmark，导致不同 layered safety 方案难以横向比较。可以讨论是否值得在组里牵头一个针对 CPS 形式化场景的 safety benchmark（结合 STL spec + 物理仿真 + jailbreak attack suite）。

## 参考文献

1. Robey, A. *et al.* Beyond alignment: Why robotic foundation models need context-aware safety. *Science Robotics*, 2026. https://www.science.org/doi/10.1126/scirobotics.aef2191
2. *Towards Safe Robot Foundation Models Using Inductive Biases.* arXiv:2505.10219. https://arxiv.org/abs/2505.10219
3. *Generating Robot Constitutions & Benchmarks for Semantic Safety.* arXiv:2503.08663. https://arxiv.org/html/2503.08663v1
4. *Safe Learning for Contact-Rich Robot Tasks: A Survey.* arXiv:2512.11908. https://arxiv.org/html/2512.11908v2
5. TechXplore 报道："What will it take to make AI-enabled robots safer?" https://techxplore.com/news/2026-04-ai-enabled-robots-safer.html
