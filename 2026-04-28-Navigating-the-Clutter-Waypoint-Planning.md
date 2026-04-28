# Navigating the Clutter: Waypoint-Based Bi-Level Planning for Multi-Robot Systems — 调研报告

> 生成日期：2026-04-28 | Reading List Monitor
> 论文来源：[arXiv:2604.21138](https://arxiv.org/abs/2604.21138)

## 1. 问题背景与研究动机

多机器人系统在密集障碍环境（cluttered environments）下的协同导航是 task and motion planning（TAMP）领域中长期存在的难题。传统流派将其拆为两层：上层用 PDDL/HTN 等符号规划做任务分配与序列决策，下层用 RRT、PRM 或基于优化的方法生成可执行轨迹。这种两层之间的接口往往非常受限——上层做决策时对下层运动可行性几乎无感知，导致一旦任务计划下发，运动层频繁回退、整体成功率随机器人数量与障碍密度急剧下降。

近年 LLM-based planner 在单机器人长程任务上取得了显著进展，但直接迁移到多机器人 cluttered scenarios 时暴露两个核心缺陷：(i) LLM 输出的高层动作（"go to A then pick B"）与底层运动可行性脱钩，**motion-agnostic** 的失败率高；(ii) 直接让 LLM 生成完整 trajectory（VLA-style）又面临 token 预算膨胀与几何精度不足的问题。本文关注的正是这两类失败模式之间的 trade-off：能否让 LLM 在保持任务级推理能力的同时，注入足够的运动可行性反馈，又不至于陷入完整轨迹生成的复杂度？

作者提出 **WayPlan** 框架，核心贡献是引入 **waypoint** 作为 task 与 motion 之间的中间表示——既比纯符号动作更具几何含义，又比稠密 trajectory 远轻量。该表示让 LLM-based task planner 与 LLM-based motion planner 能够联合优化（jointly optimized），并最终通过 RRT 等经典 motion planner 把 waypoint 序列细化为 collision-free pose trajectory。

## 2. 技术方法

WayPlan 由两个 LLM-based planner 组成：

- **Task planner**：解析高层任务、生成子目标与机器人间分工，并向 motion planner 提出关于关键 waypoint 的提议。
- **Motion planner**：在感知到的占据栅格 / 场景图上，对 task planner 提出的 waypoint 做几何与可行性筛选；对不可行的 waypoint 触发 task 层重写或修补。

两层之间通过 waypoint 序列耦合。Waypoint 的优势在于：(i) 比一组 free-form 自然语言子目标更可验证，因为它有明确的几何坐标；(ii) 比 dense trajectory 信息密度更高，LLM 推理一两步就能覆盖较长路径；(iii) 与传统 sampling-based motion planner 的接口天然契合——RRT 可以直接将连续 waypoint 之间的段做 collision check。

整体流程可以理解为一种 "LLM-in-the-loop" 的 hierarchical TAMP：上层 LLM 生成 waypoint 草案，下层 LLM 与 RRT 共同把它细化为可执行轨迹，失败时反馈到上层进行 replan。这种 joint optimization 在文中通过实验对比体现：相比 motion-agnostic baseline 与 VLA-based baseline，WayPlan 在 BoxNet3D-OBS 这一密集障碍多机器人 benchmark 上随机器人数量（最高 9 台）增长时仍保持显著的成功率优势。

## 3. 研究前沿与意义

LLM 驱动的 multi-robot task and motion planning 是 2024–2026 年的明显热点。从 ICRA、IROS、CoRL、RSS 等会议看，仅围绕 "LLM + multi-robot planning" 主题，每届都有专门 session 或 workshop（例如 ICRA 2025 的 "LLM-Modulo Planning" workshop、CoRL 关于 foundation models for robotics 的多个 track）。

主要研究方向可以归为四类：

- **PDDL-bridge 流派**：让 LLM 翻译自然语言到 PDDL 然后交给 classical planner（如 CoMuRoS、Hierarchical LLM Multi-Agent Framework）。
- **Scene-graph grounded 流派**：用 3D 场景图作为 LLM 与 motion planner 的桥梁（如 Language-Grounded Hierarchical Planning with Multi-Robot 3D Scene Graphs）。
- **Temporal logic / formal methods 流派**：把 LLM 输出约束为 LTL/STL，再由形式化 planner 执行（如 T³ Planner）。
- **Waypoint / intermediate-geometry 流派**：本文 WayPlan 即属于此类，在 LLM 与 sampling-based planner 之间引入轻量几何中间表示。

主要 venue 包括 RSS、CoRL、ICRA、IROS，期刊侧 IJRR、T-RO 也开始接收此类工作。在这个圈子里活跃的实验室包括 MIT-CSAIL（Tedrake、Tenenbaum 联合组）、Stanford ASL、CMU 的 Salakhutdinov / Liu 组、UC Berkeley 的 Goldberg / Levine 组、Princeton 的 Majumdar 组等。

## 4. 相关工作

1. **CoMuRoS / LLM-Based Generalizable Hierarchical Task Planning** ([arXiv:2511.22354](https://arxiv.org/abs/2511.22354))
   异构机器人团队的分层任务规划；使用 LLM Task Manager 做任务分类与子任务分配，强调事件驱动的 replanning。与本文的差异在于：CoMuRoS 偏向集中决策—去中心化执行的工程框架，几何运动可行性主要依赖各机器人本地运动模块；WayPlan 把几何 waypoint 直接嵌入 LLM 的推理回路，更紧的 task–motion 耦合。

2. **T³ Planner: A Self-Correcting LLM Framework for Robotic Motion Planning with Temporal Logic** ([arXiv:2510.16767](https://arxiv.org/abs/2510.16767))
   也以 waypoint 为中间表示，但把时间逻辑（LTL/STL）作为正确性骨架；其 Trajectory Planner 在 timed waypoints 上跑 motion controller。WayPlan 与之互补：T³ 强约束于 temporal specification，WayPlan 偏重 cluttered geometry 中的可行性 feedback。

3. **Language-Grounded Hierarchical Planning and Execution with Multi-Robot 3D Scene Graphs** ([arXiv:2506.07454](https://arxiv.org/abs/2506.07454))
   用 3D scene graph 作为 LLM 落地的语义表示，把自然语言指令翻译为 PDDL 目标后由 classical planner 执行。它强在语义-几何对齐，弱在密集障碍下的 motion 可行性反馈；WayPlan 没有显式 scene graph，但在 motion planner 端做了更充分的几何耦合。

4. **Hierarchical LLM-Based Multi-Agent Framework with Prompt Optimization for Multi-Robot Task Planning** ([arXiv:2602.21670](https://arxiv.org/abs/2602.21670))
   将多机器人协作建模为多 LLM agent；当下层 PDDL 求解失败时，用 TextGrad 风格的文本梯度反向更新上层 prompt。这是另一种 task–motion 闭环的实现方式，但其反馈信号是 PDDL 求解器层面的，几何 waypoint 不显式参与；WayPlan 在 waypoint 层就做了几何拒绝，更早过滤不可行计划。

5. **Hierarchical Large Scale Multi-Robot Path (Re)Planning** ([arXiv:2407.02777](https://arxiv.org/abs/2407.02777))
   纯几何/经典视角的多机器人分层 path planning；不使用 LLM，但其分层思想（abstract roadmap + local refinement）与 WayPlan 的 task-motion 分层在数学结构上同源。可作为 WayPlan 在不依赖 LLM 时的 ablation 对照。

## 5. 组会讨论要点

- **Waypoint 作为中间表示的形式化代价**：waypoint 比 PDDL 动作"几何更丰富"、比 trajectory"信息更稀疏"，但具体多少 waypoint 才足以让 RRT 顺利衔接？文中是否给出了 waypoint 密度与成功率的 trade-off 分析？这是一条可以深挖的实验维度。

- **与我们组现有方向的潜在联系**：我们组在 STL/LTL planning、conformal prediction、neural CBF 等方向积累较多。一个有意思的扩展方向是把 WayPlan 中"motion-agnostic LLM 决策不可信"这个观察上升为形式化条件——例如在 waypoint 之间加入 conformal coverage guarantee，或者用 STL robustness 作为 task planner 的奖励信号。这与我们 reading list 上若干 conformal motion planning 工作（Adaptive Conformal Prediction for Motion Planning among Dynamic Agents、Conformalized Non-uniform Sampling）形成自然的桥梁。

- **关于 BoxNet3D-OBS 评测的局限**：仿真 benchmark 可控但同质化严重，9 个机器人的几何模型与障碍分布是否真正逼近 cluttered warehouse 场景？是否考虑过加入感知噪声、partial observability 的实验？后者会引入 belief-space planning（与 reading list 里"Risk-Constrained Belief-Space Optimization"等工作相关）。

## 参考文献

1. WayPlan 原文：Navigating the Clutter: Waypoint-Based Bi-Level Planning for Multi-Robot Systems. arXiv:2604.21138. https://arxiv.org/abs/2604.21138
2. CoMuRoS：LLM-Based Generalizable Hierarchical Task Planning and Execution for Heterogeneous Robot Teams with Event-Driven Replanning. arXiv:2511.22354.
3. T³ Planner：A Self-Correcting LLM Framework for Robotic Motion Planning with Temporal Logic. arXiv:2510.16767.
4. Language-Grounded Hierarchical Planning and Execution with Multi-Robot 3D Scene Graphs. arXiv:2506.07454.
5. Hierarchical LLM-Based Multi-Agent Framework with Prompt Optimization for Multi-Robot Task Planning. arXiv:2602.21670.
6. Hierarchical Large Scale Multi-Robot Path (Re)Planning. arXiv:2407.02777.
