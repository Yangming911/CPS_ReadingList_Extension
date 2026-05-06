# Affordance Agent Harness: Verification-Gated Skill Orchestration — 调研报告

> 生成日期：2026-05-07 | Reading List Monitor
> 论文来源：arXiv:2605.00663 (2026-05) | https://arxiv.org/html/2605.00663v1

## 1. 问题背景与研究动机

近年的 *agentic harness*（围绕 LLM/VLM agent 的运行时框架）通常采用**固定流水线**的 skill orchestration：感知模块 → reasoning 模块 → 动作模块按预定义顺序串接。在 open-world 视觉推理任务中，这种固定结构难以处理跨技能不一致（不同 skill 给出冲突结果）、跨尺度不稳定（不同分辨率/视角下结论变化）、以及证据不足等问题。错误往往沿流水线传递到 late-fusion 层才显现，已无法挽回。

本文提出 **Affordance Agent Harness (A-Harness)**，把 skill orchestration 重新设计为一个**带预算约束、按 instance 自适应、由 verification gate 控制**的闭环运行时。其研究动机有三：(i) open-world 视觉推理需要"动态决定调用哪些 skill、何时停止、如何回退"，固定流水线 + 单次 fusion 无法满足；(ii) 计算/调用代价是部署 LLM agent 的现实瓶颈，需要显式的 cost control；(iii) 失败模式应被早期检测并触发**针对性恢复 (targeted recovery)**，而不是把所有错误延迟到末端。

## 2. 技术方法

A-Harness 的核心组件包括：

1. **Evidence store**：把异构 skill（detector、segmenter、VLM Q&A、retrieval、仿真等）的输出统一为带不确定性、带成本的 evidence record，存入共享 store。所有后续决策基于 evidence store 的当前快照。
2. **Verification gates**：在 commit 任何决策之前，运行三类相对性检验——
   - **Cross-skill agreement**：同一 query 由多个 skill 给出的结果是否一致；
   - **Cross-scale stability**：同一 skill 在不同尺度/输入扰动下结果是否稳定；
   - **Evidence sufficiency**：现有证据强度是否达到决策阈值。
   任何一项失败即触发 *targeted recovery*——例如重新调用更高精度的 skill、缩放输入、查询 episodic memory，而不是把不确定结果直接交给后续 fusion。
3. **Router**：基于当前 evidence store 与剩余 budget，自适应选择下一步调用的 skill 及其参数化（如分辨率、prompt 模板）。Router 是一个轻量 policy，可由专家规则、bandit 或小型 RL 训练得到。
4. **Two-tier episodic memory**：长期 memory 存储不同物体类别的成功 routing 轨迹，作为相同/相似 instance 出现时的 prior；短期 memory 在单次任务内复用已查询的 evidence，避免重复调用。
5. **Cost-aware stopping rule**：基于 marginal evidence value vs marginal cost 的判别终止 skill 调用，使 accuracy-cost trade-off 沿 Pareto 前沿移动。

实验上 A-Harness 在多个 open-world 视觉推理 benchmark 上比固定流水线 baseline 有稳定提升，且在相同 accuracy 下 skill 调用数显著降低，验证 *adaptive routing + verification-gated retries* 的价值独立于 backbone 选择。

## 3. 研究前沿与意义

Agentic harness 在 2025–2026 年成为热门子领域：从 Anthropic、OpenAI 的 production agent 框架，到 OpenReview 上大量"agent + tool use + verification"工作，社区已意识到"原始 LLM 调用不够，需要 disciplined runtime"。本文与 *Agentic Harness Engineering* (arXiv:2604.25850)、*Architectural Design Decisions in AI Agent Harnesses* (arXiv:2604.18071)、*HeavySkill* (arXiv:2605.02396) 等同期工作共同构成新的子文献群。

A-Harness 的独到处在于把 *verification gate* 作为一等公民，而不是把验证只作为 post-hoc 评测。这与机器人/CPS 社区的 runtime monitoring 与 conformal prediction 思路高度契合，意味着 LLM agent 与传统 control runtime 之间的接口正在被打通。

热度评估：相关 venue 包括 NeurIPS、ICML、ICLR 主会与 *Foundation Models for Decision Making*、*Workshop on Agentic AI* 等 workshop；机器人侧已开始出现在 CoRL、ICRA。活跃团队包括 Stanford、MIT、Berkeley、CMU、Penn、Princeton 以及主要工业实验室（Google DeepMind、Anthropic、Meta、Microsoft Research）。

## 4. 相关工作

- **Agentic Harness Engineering: Observability-Driven Automatic Evolution of Coding-Agent Harnesses** (arXiv:2604.25850)。强调通过观测和自动演化改进 harness，与本文 verification-gated 思路互补——前者改进 harness 本身，后者在固定 harness 内运行时 gating。
- **Architectural Design Decisions in AI Agent Harnesses** (arXiv:2604.18071)。系统化整理 harness 的架构设计空间，可作为本文方法的"设计坐标系"。
- **HeavySkill: Heavy Thinking as the Inner Skill in Agentic Harness** (arXiv:2605.02396)。把"depth of reasoning"作为可调用 skill 而非固定属性，与 A-Harness 的 router-based skill selection 在思路上同源。
- **Multi-Round Human-AI Collaboration with User-Specified Requirements**（已在 reading list 上）。把人加入循环作为 verification 的源头，是另一种 verification gate 的实现。
- **Safety Guardrails for LLM-Enabled Robots**（已在 reading list 上）。从机器人 safety 视角设计 LLM guardrail，本文的 verification gate 可视为更通用的、面向 open-world 推理的 guardrail 实例化。
- **Contextual Safety Reasoning and Grounding for Open-World Robots**（已在 reading list 上）。直接讨论 open-world 推理，与 A-Harness 的 evidence store + episodic memory 思路有融合潜力。

## 5. 组会讨论要点

1. **Verification gate 与 formal monitoring 的桥接**：本文的 cross-skill agreement / cross-scale stability 是经验式判据。能否把组里熟悉的 STL/LTL runtime monitoring 接入这些 gate——例如把"stability"形式化为某种 G(eventually) 规约——从而获得可证明的 trigger 条件？这与 reading list 上的 *Conformal Predictive Monitoring*、*Trace Repair for Temporal Behavior Trees* 等工作天然连接。
2. **Budget 与 safety 的 trade-off 分析**：A-Harness 强调 cost-aware，但在 safety-critical 机器人系统中，"省 skill 调用"未必是合理目标——更应优化"在给定 risk budget 下达成 task success"。能否把 risk-aware MPC（如 reading list 上的 *Parameter-Robust MPPI*、*Risk-Aware Robotics*）思路移植到 router policy 设计？
3. **Episodic memory 的安全注意事项**：跨 instance 复用 routing 轨迹时，若历史轨迹来源被污染（adversarial example, distribution shift），priors 反而会损害 fresh instance 的可靠性。组会可讨论是否需要在 memory 层加 *Data-Driven Reachability* 或 *eCP* 风格的 conformal-uncertainty 标注，以拒绝低置信度的 prior。

## 参考文献

1. *Affordance Agent Harness: Verification-Gated Skill Orchestration.* arXiv:2605.00663, 2026. https://arxiv.org/html/2605.00663v1
2. *Agentic Harness Engineering: Observability-Driven Automatic Evolution of Coding-Agent Harnesses.* arXiv:2604.25850. https://arxiv.org/abs/2604.25850
3. *Architectural Design Decisions in AI Agent Harnesses.* arXiv:2604.18071. https://arxiv.org/html/2604.18071v1
4. *HeavySkill: Heavy Thinking as the Inner Skill in Agentic Harness.* arXiv:2605.02396. https://arxiv.org/abs/2605.02396
5. *Natural-Language Agent Harnesses.* arXiv:2603.25723. https://arxiv.org/html/2603.25723v1
6. *VADER: Visual Affordance Detection and Error Recovery for Multi Robot Human Collaboration.* arXiv:2405.16021. https://arxiv.org/html/2405.16021v1
