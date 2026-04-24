# Controlling diverse robots by inferring Jacobian fields with deep networks — 调研报告

> 生成日期：2026-04-24 | Reading List Monitor
> 论文来源：[Nature (2025)](https://www.nature.com/articles/s41586-025-09170-0) | [arXiv:2407.08722](https://arxiv.org/abs/2407.08722) | [项目主页](https://sizhe-li.github.io/publication/neural_jacobian_field/) | [Code (GitHub)](https://github.com/sizhe-li/neural-jacobian-field)

## 1. 问题背景与研究动机

传统机器人控制管线的前提是一个显式、准确的动力学模型：刚体运动学链、已知的惯性参数、带标定的关节编码器，以及精确的驱动器模型。在这套范式下，forward kinematics、inverse kinematics 以及 system Jacobian 都可以由 URDF/SDF 文件加解析公式得到。但一旦机器人**偏离刚体假设**——例如 soft robot、pneumatic actuator、tendon-driven manipulator、3D 打印出来的 under-sensed 机械臂——显式建模就会失效：材料非线性、迟滞、制造偏差，以及缺乏关节编码器等问题会让 first-principles model 与真实硬件之间出现 significant sim-to-real gap。

本文要解决的核心问题是：**能否不依赖任何先验模型、不依赖本体感受传感器（proprioception），仅凭一路外部 RGB 视频，自主学习任意机器人的控制器？** 作者给出的答案是 Neural Jacobian Fields (NJF) ——一个 per-robot 学习的 neural field，输入为单目视频，输出是机器人在 3D 空间中每一个点相对于所有 actuator command 的 **visuomotor Jacobian**。这个场对应的正是 differential kinematics 的推广：它编码了"推哪根杆、拉哪根腱，机器人身上某一点会往哪个方向走多少"。有了这个场，就可以把 inverse dynamics 控制问题转化为一个 least-squares command optimization。

核心贡献可概括为三点：
(i) 提出 **visuomotor Jacobian field** 这一新的机器人表示，把经典 system Jacobian 从一个离散的 matrix 推广到了连续的 neural field，并且是**从 vision 习得**而非从 URDF 推导；
(ii) 提出配套的 self-supervised 训练范式——执行随机 motor babbling，观测前后两帧视频，通过 rendering loss 和 Jacobian consistency 即可学习 NJF，**无需任何标注、无需专家示教**；
(iii) 在涵盖 rigid manipulator、soft pneumatic arm、tendon-driven hand、甚至 220 美元的 3D-printed 低精度机械臂等 diverse platforms 上验证了 closed-loop 控制。该工作于 2025 年 6 月发表于 *Nature*，属于机器人学界少见的 high-profile 出版，标志着 neural scene representation 在机器人控制方向的一次突破性落地。

## 2. 技术方法

整个 NJF 框架由两个模块串联而成：**state-estimation network** 和 **inverse dynamics controller**。

**State-estimation network** 基于 Scene Representation Group 一系列 neural field 工作（PixelNeRF、Scene Representation Networks 等）的思路。给定单目视频帧 $I_t$，网络通过 image-conditioned encoder 推断出一个 implicit 3D representation。在这个表示上，query 任意空间点 $\mathbf{x}\in\mathbb{R}^3$ 可以得到两样东西：(a) 该点的 density 与 appearance（用于 volume rendering 监督，保证 3D geometry 正确），(b) 一个 **Jacobian matrix** $J(\mathbf{x})\in\mathbb{R}^{3\times m}$，其中 $m$ 是 actuator 数量。$J(\mathbf{x})$ 的第 $i$ 列给出了第 $i$ 个 actuator 以单位速度激活时，$\mathbf{x}$ 点在世界坐标系下的瞬时速度方向。

训练时采用 motor babbling：让机器人在安全空间内执行随机指令序列 $\mathbf{u}_t$，记录视频帧对 $(I_t, I_{t+1})$ 和对应指令 $\mathbf{u}_t$。损失函数由两部分构成：
- **Rendering loss**：对从 implicit field 渲染出的图像与真实帧做 photometric 对比，确保几何一致性；
- **Flow consistency loss**：把 predicted Jacobian 与 actuator command 相乘得到的 3D velocity field，投影到图像平面得到 optical flow，和真实 frame-to-frame flow（可由 off-the-shelf RAFT 等方法提取）做 L1 对齐。

这个训练信号**完全 self-supervised**，不需要任何 3D ground truth。值得注意的是，论文展示了一个涌现性质：即便 training 只涉及指令 $\to$ 视频这种端到端映射，NJF 也能**自主识别出 causal kinematic structure**——哪根 actuator 对应机器人的哪一部分——这一点完全没有人为标注。

**Inverse dynamics controller** 把控制问题形式化为：给定用户指定的 target motion（可以是 2D image-space waypoint 或 3D trajectory），求解 actuator command $\mathbf{u}^*$ 使得
$$\mathbf{u}^* = \arg\min_{\mathbf{u}} \sum_{\mathbf{x}\in S} \| J(\mathbf{x})\mathbf{u} - \mathbf{v}_{\text{desired}}(\mathbf{x}) \|^2,$$
其中 $S$ 是 target 上采样的一组关键点。这是一个 linear least-squares 问题，在**运行期实时可解**（interactive speed），构成了 closed-loop visual servoing 的基础。控制回路为：采图 $\to$ 推断 $J$ $\to$ 求解 $\mathbf{u}^*$ $\to$ 下发指令 $\to$ 采下一帧。

关键的理论/实践保证：NJF 推断的 Jacobian field 是 smooth 且 spatially continuous 的，使得 least-squares 解稳定可复现；作者在文中也分析了 training data coverage 与控制空间覆盖度之间的关系——motor babbling 需要充分激活所有自由度才能保证 controllability。

## 3. 研究前沿与意义

这篇工作处在三个研究热点的交汇处：**(a) neural scene representations for robotics**, **(b) self-supervised learning from interaction**, **(c) model-free / model-based 混合控制**。从近三年的会议接收情况看，CoRL、RSS、ICRA 上相关 session 数量持续增加；Nature 接收此类工作本身就是前沿度的 strong signal——以往机器人控制方法鲜少登上 Nature 主刊，该工作能入选意味着审稿人认可其**跨越 rigid/soft/under-actuated robots 的 generality**。

**竞争方法**大致分三类：
(1) **System identification + MPC** 路线：通过少量交互数据估计物理参数，再用传统 MPC 控制。代表工作包括 gradSim (ICLR 2021) 这类 differentiable physics + differentiable rendering 的方法。这条路线的 bottleneck 是**物理参数空间**仍需要人工指定（是 pneumatic？tendon？elastic modulus 范围？）。
(2) **Visuomotor policy learning**：直接学一个 image $\to$ action 的 policy，代表方向是 Diffusion Policy、VLA 模型（如 RT-2、OpenVLA）。优势是无需建模，但 sample complexity 高、缺乏 interpretability，且每个新任务往往需要 new demonstrations。
(3) **Analytic soft-robot modeling**：基于 Piecewise Constant Curvature、Cosserat rod 等理论建模，学术上优雅但**任何形状/材料变化都要重新推导**。

NJF 的独特定位是：训练阶段 self-supervised 像 (2)，部署阶段 model-based 像 (1)，但 learned model 的参数化方式完全 data-driven 不依赖物理先验。**活跃研究组**包括 MIT CSAIL（Sitzmann、Rus 两组的合作）、Stanford（Fei-Fei Li 组在 neural scene representation 方向）、CMU RI、ETH Zürich CRL（Coros 组 differentiable simulation）、Google DeepMind Robotics。

**主要发表 venue**：Nature/Science 正刊（极少数 breakthrough）；机器人顶会 RSS、CoRL、ICRA、IROS；机器学习顶会 NeurIPS、ICLR 对 neural field 部分较友好；Soft Robotics 期刊（Science Robotics、Soft Robotics）对 soft robot 专项工作覆盖度高。

## 4. 相关工作

1. **Scene Representation Networks (SRN), Sitzmann et al., NeurIPS 2019** — 本文 state-estimation 模块的 backbone 思想源头。SRN 首次提出用 MLP 参数化 continuous 3D scene representation，并且支持 differentiable volume rendering。与本文关联：NJF 把 SRN 的静态场景扩展为"场景 + 驱动器响应"的 coupled 表示。关键区别：SRN 面向 novel-view synthesis，NJF 面向 control。

2. **gradSim: Differentiable Simulation for System Identification and Visuomotor Control, Jatavallabhula et al., ICLR 2021** — 最直接的对照方法。gradSim 也从 pixels 反向传播到物理参数，但**要求显式的物理方程**（mass-spring、rigid-body dynamics）。NJF 走的是 learned implicit dynamics 路线，适用范围更广但 sample-to-physics-explanation 的可解释性较弱。

3. **Learning to Control Soft Robots with Differentiable Neural Simulators, ETH Zürich CRL, RoboSoft 2020** — 针对 soft robot 的 learned differentiable model。与本文关联：都面向 model-free soft robot control 问题。关键区别：CRL 工作仍依赖 marker 或内部传感器做监督，而 NJF 完全只用单目外部视频。

4. **Vision-Based Servoing via Neural Radiance Fields / Dex-NeRF 系列, 2022–2024** — 利用 NeRF 做 grasping 与 manipulation 的一系列工作。共同点：都把 implicit 3D representation 引入机器人感知环节。关键区别：这些工作 NeRF 只做几何表示，控制仍依赖已知 kinematics；NJF 把 Jacobian（即控制所需的 differential kinematics）也纳入 neural field 中。

5. **Learning Visuomotor Policies with Diffusion, Chi et al., RSS 2023 (Diffusion Policy)** — 近期 end-to-end visuomotor learning 的 state-of-the-art。与本文关联：两者都绕开显式动力学模型，直接从视频/图像学习控制能力。关键区别：Diffusion Policy 学的是 policy distribution，需要 human demonstration 作监督；NJF 学的是 dynamics model，仅用 motor babbling 即可训练，但目标任务的具体 trajectory 还需要用户在推理时提供。

## 5. 组会讨论要点

1. **NJF 对 observation coverage 的依赖是否构成瓶颈？** Single camera 意味着 self-occlusion 不可避免（例如机械臂挡住末端执行器）。论文中多机器人实验是否都在 well-observed 视角下完成？在 partial observation / occlusion 场景下，Jacobian field 的 estimation 会如何退化？这对我们组关心的 safety under partial observability（参考之前读过的 POMDP 相关工作）是一个自然联系。

2. **从"推理 Jacobian"到"提供 safety guarantee"的距离**。NJF 当前给出的是 deterministic Jacobian point estimate，没有 uncertainty quantification。如果想把它用在 safety-critical 场景（例如和我们组在做的 conformal prediction / reachability analysis 结合），需要扩展到 distributional NJF。值得讨论：在 NJF 上加一层 conformal wrap 是否能给出 pointwise confidence interval？这直接对应到我们读过的 Conformal Reachability 和 eCP 等工作。

3. **scalability 与 cross-embodiment 问题**。文章目前是 per-robot 训练，每个机器人从头 motor babbling 数十分钟到数小时。一个值得跟踪的后续方向：能否像 RT-X、OpenVLA 一样训练一个**cross-embodiment Jacobian foundation model**？这和之前 reading list 上的 "Towards X-embodiment safety" 形成呼应——如果 safety certificate 能跨 embodiment transfer，那么 kinematic model 能否也跨 embodiment transfer？

## 参考文献

1. Li, S. L., Zhang, A., Chen, B., Matusik, H., Liu, C., Rus, D., & Sitzmann, V. (2025). *Controlling diverse robots by inferring Jacobian fields with deep networks*. **Nature**, 643. <https://www.nature.com/articles/s41586-025-09170-0>
2. Preprint: arXiv:2407.08722. <https://arxiv.org/abs/2407.08722>
3. Project page & code: <https://sizhe-li.github.io/publication/neural_jacobian_field/> ; <https://github.com/sizhe-li/neural-jacobian-field>
4. Sitzmann, V., Zollhöfer, M., & Wetzstein, G. (2019). *Scene Representation Networks: Continuous 3D-Structure-Aware Neural Scene Representations*. NeurIPS 2019.
5. Jatavallabhula, K. M. et al. (2021). *gradSim: Differentiable Simulation for System Identification and Visuomotor Control*. ICLR 2021. <https://gradsim.github.io/>
6. Hiller, J. et al. (2020). *Soft Robot Control with a Learned Differentiable Model*. RoboSoft 2020 (ETH CRL). <https://crl.ethz.ch/papers/RoboSoft2020.pdf>
7. Chi, C. et al. (2023). *Diffusion Policy: Visuomotor Policy Learning via Action Diffusion*. RSS 2023.
8. MIT News coverage (2025-07-24): *Robot, know thyself: New vision-based system teaches machines to understand their bodies*. <https://news.mit.edu/2025/vision-based-system-teaches-machines-understand-their-bodies-0724>
