# Local Linearity of LLMs Enables Activation Steering via Model-Based Linear Optimal Control — 调研报告

> 生成日期：2026-04-23 | Reading List Monitor
> 论文来源：[arXiv:2604.19018](https://arxiv.org/abs/2604.19018)（Skifstad, Yang, Chou, April 2026）

## 1. 问题背景与研究动机

Inference-time alignment 是近两年 LLM safety 领域快速兴起的一条支线：相对于 RLHF / DPO 这类需要重新训练或 fine-tune 的方法，**activation steering**（又称 representation engineering）直接在 forward pass 中对 hidden state 施加 additive 扰动，从而在推理时动态调节输出的 toxicity、truthfulness、refusal rate 等行为属性。这类方法的吸引力在于：数据代价低（几百条对比样本即可）、不改变权重、可插拔、可组合。

然而，截至本文投稿前，主流 steering 方法（ITI、ActAdd、Linear-AcT、Mean-AcT 等）几乎都可以被形式化为**开环（open-loop）干预**：离线计算一个 steering 方向 $v_k$，在线按固定强度 $\alpha$ 把 $z_k$ 替换为 $z_k + \alpha v_k$。这种策略忽略了一个关键事实——transformer 是一个**前向层间动力系统**，单层的扰动会通过后续层的非线性传播而被放大或衰减，导致实际效果难以预测。近期 Nguyen et al. (2510.04309) 的 PID Steering 已经把这一问题定性为"现有方法等价于 proportional controller"，并引入 integral/derivative 项改善 tracking；但 PID 的 gain 仍需手动调节，且缺乏对 plant dynamics（即 transformer 本身）的显式建模。

本文（Skifstad, Yang, Chou, Georgia Tech Trustworthy Robotics Lab）的出发点正是这一空缺：**能否把 transformer 层间演化建模为一个 dynamical system，并用 model-based optimal control 的工具（LQR）来综合 feedback steering policy？** 作者的答案是肯定的，核心洞察为——尽管 transformer block 整体是非线性的，但**在典型 activation trajectory 的邻域内，层间映射的 local Jacobian 高度相似**，即 LLM 的层间动力学可以用一个 *locally linear time-varying*（LTV）系统很好地近似。这一发现把 LLM alignment 直接搭到了 classical linear optimal control 的已有理论之上，允许作者给出带 formal tracking guarantee 的 steering policy。

核心贡献可以概括为三点：(i) 对多种 LLM 架构（Gemma-2-2B, Llama-3-8B, Qwen-2.5-14B）经验证明了层间 Jacobian 的 subspace alignment 很高，支持 locally-linear 建模；(ii) 提出 **A-LQR**——把 finite-horizon LQR 套用到 LLM layer dynamics 上，以 layer-wise Jacobian 为 plant model，在线基于实际 activation 做 feedback 计算 steering control；(iii) 设计 **LFS (Linear Feature Setpoint)** 信号，以 layer-wise activation 在"benign 方向 $v_k$"上的 scalar projection 作为 semantic target，支持 adaptive、可组合、不依赖 offline supervision 的 reference 生成。

## 2. 技术方法

### 2.1 LLM 作为 LTV 系统

设 transformer 的第 $k$ 层映射为 $\phi_k$，即 $z_{k+1} = \phi_k(z_k + u_k)$，其中 $u_k$ 是在第 $k$ 层注入的 steering control。作者在 nominal trajectory $\{\bar z_k\}$（通常取 benign prompts 的 mean activation）附近做一阶 Taylor 展开：

$$\delta z_{k+1} = A_k \delta z_k + B_k \delta u_k, \quad A_k := \left.\tfrac{\partial \phi_k}{\partial z}\right|_{\bar z_k},\ B_k := I.$$

离线通过 automatic differentiation 计算 $A_k$；$B_k$ 取单位阵是因为 steering 以 additive 方式注入。关键的 *empirical* 观察是：从不同 prompt 出发采样得到的 $A_k$ 集合之间，其 top-$m$ singular subspace 的 alignment（用 generalized subspace similarity 度量，Eq. 24）可以达到 0.5–0.8，且"语义相近"的 prompts 其 alignment 更高。作者进一步展示 $A_k$ 的 spectrum 被少数 dominant mode 主导，使 locally-linear 近似的 modeling error 在闭环下 Lipschitz-bounded。

### 2.2 A-LQR：层间 finite-horizon LQR

在 LTV 近似下，steering 问题化为 $\ell$-step（$\ell$ 为层数）finite-horizon LQR：

$$\min_{\{\delta u_k\}} \ \delta z_T^\top Q_T \delta z_T + \sum_{k=0}^{T-1}\bigl(\delta z_k^\top Q_k \delta z_k + \delta u_k^\top R_k \delta u_k\bigr),\ \text{s.t. }\delta z_{k+1} = A_k \delta z_k + B_k \delta u_k.$$

通过 backward Riccati recursion 得到 feedback gain $K_k = \Gamma_k B_k^\top S_{k+1} A_k$（$\Gamma_k = (B_k^\top S_{k+1} B_k + R_k)^{-1}$）。在线阶段对每个 prompt 的实际 $z_k$ 施加 $u_k^* = K_k(\bar z_k - z_k) + \text{feedforward}(\beta_k^*)$，即**闭环**地把 activation 推向 target setpoint。复杂度为 $O(\ell d^3)$（CPU）或 $O(\log \ell \cdot \log^2 d)$（GPU），一次性 offline 可完成 gain 预计算。

### 2.3 LFS: Linear Feature Setpoint

直接为 $d$-维 activation 指定 $\bar z_k$ 不现实（高维且 prompt-dependent）。作者把 reference 降维到一维 *feature strength* 上：取 positive/negative 对比集的 mean 差 $e_k = z_{k,+} - z_{k,-}$，归一化得到方向 $v_k = e_k / \|e_k\|_2$，并定义标量 feature $\beta_k := v_k^\top z_k$。Setpoint 按 layer-wise 活动幅度自适应缩放：

$$\beta_k^* = \lambda \mu_k,\ \mu_k = \|e_k\|_2,\ \lambda\in\mathbb{R}\ \text{是唯一超参数}.$$

Theorem 4.1 证明在此目标下，*minimum-norm* perturbation 是 $z_k' = z_k + (\beta_k^* - \beta_k) v_k$，从而回到 A-LQR 的 tracking 形式。这一 setpoint 设计的巧妙之处在于：(a) 仅需少量对比样本（~几百）即可估计 $v_k$ 和 $\mu_k$；(b) $\lambda$ 作为唯一全局 knob 可以在 deployment 时直接调节 steering intensity；(c) 对 toxicity、truthfulness、refusal 等不同任务只需替换对比集即可复用全套框架。

### 2.4 理论保证

Theorem 4.2 给出 setpoint tracking error 的上界：在 LTV 近似 residual 的 local Lipschitz constant $L_k$ 可估的前提下，闭环 tracking error 被 $L_k$、控制权重 $R_k$ 与 horizon $\ell$ 的函数显式 bound。作者在 Gemma-2-2B 上经验估计 $L_k$ 并验证该 bound 在所有层都 hold（Fig. 3），为 steering 效果提供了**非平凡的 formal guarantee**——这是 ITI 等 open-loop 方法无法给出的。

### 2.5 实验

- **Toxicity regulation (RealToxicityPrompts)**：A-LQR 将 toxicity rate 从 4.16% 降至 0.18% (Gemma-2-2B)、5.14%→0.12% (Llama-3-8B)、3.26%→0.12% (Qwen-2.5-14B)，同时保持 MMLU、Dist-2、PPL 近乎不变。
- **Truthfulness (TruthfulQA)**：T×I 分数 48.64→67.81 (Gemma) 与 53.17→76.28 (Qwen)，优于 ITI、NL-ITI、Linear-AcT。
- **Jailbreaking (AdvBench)**：A-LQR+（全 token 变体）达到 96–97% attack success，与 AAS 齐平或更高。
- Baseline 覆盖面较完整：ITI、ActAdd、Mean/Linear-AcT、PID-AcT（来自 Nguyen et al.）、ODESteer、自提的 S-PID；但**未与 CAST、conceptor-based steering、ASM 等近期方法直接对比**，这是一个可追问的点。

## 3. 研究前沿与意义

Inference-time activation steering / representation engineering 自 2023 年 ITI 和 ActAdd 以来，是 LLM alignment 领域增长最快的细分方向之一，判断依据：

- **venue 与活跃度**：ICLR 2025 spotlight（CAST）、NeurIPS 2024/2025 有 representation engineering workshop、Anthropic 和 DeepMind 在 2025 年分别发布 steering-based safety tooling。arXiv 上 2025–2026 年出现了数十篇直接相关工作，涉及 conceptor、state-space、PID、ODE-based、diffusion-based 等多种控制与表征技术组合。
- **活跃研究组**：MIT CSAIL（ITI 系列）、Anthropic（refusal vector、sparse autoencoder steering）、Oxford / UCL（representation engineering survey）、Georgia Tech（本文作者 Chou 的 Trustworthy Robotics Lab，近年从 safe robotics 切入 safe LLM）、ETH Zürich（PID Steering、conceptor）。
- **会议/venue**：NeurIPS、ICLR、ICML（主会）；Safety/Alignment workshop；控制学派则发表在 CDC、L4DC、Automatica（如 PID Steering）。

本文的独特定位在于：它是我们所见**第一个把 finite-horizon LQR 这类 model-based optimal control 工具系统地对接到 LLM steering** 的工作。相比 PID Steering 仅用 SISO 反馈律，本文用 MIMO 的 state-space LQR 利用了 layer-wise Jacobian 所包含的**plant model 信息**，并给出 tracking guarantee。这种"用控制理论工具改造 alignment"的路线，与最近 Chou 组同方向工作（Trustworthy Robotics Lab 从 barrier certificate 扩展到 LLM safety filter）高度一致。

从 CPS / 形式化方法的视角看，本文值得关注的地方在于：**它把 LLM forward pass 视作一个 dynamical system 的做法，为后续引入 Lyapunov-type 稳定性分析、CBF-style safety filter、reachability analysis 打开了 interface**。这与我们组在 neural ODE、closed-loop verification、conformal reachability 等方向的工作有明显交集。

## 4. 相关工作

1. **Inference-Time Intervention: Eliciting Truthful Answers from a Language Model**（Li et al., NeurIPS 2023；[arXiv:2306.03341](https://arxiv.org/abs/2306.03341)）
   Activation steering 的经典工作。通过 linear probe 在 attention heads 上定位 "truthfulness direction" $v$，在 inference 时对 top-$K$ heads 施加 $z\leftarrow z + \alpha v$。把 TruthfulQA 上 Alpaca 的表现从 32.5% 推到 65.1%。与本文关系：ITI 是 A-LQR 的 **open-loop degenerate case**（$K_k\equiv 0$、只用 feedforward $\alpha v$）；本文用 LFS 生成 setpoint、用 A-LQR 做 closed-loop tracking，可视为 ITI 在控制论语义下的完整版。

2. **Activation Steering with a Feedback Controller (PID Steering)**（Nguyen et al., 2025；[arXiv:2510.04309](https://arxiv.org/abs/2510.04309)）
   最近邻工作，首次把 activation steering 显式建模为控制问题，指出 ActAdd/ITI 等价于 proportional controller，并引入 integral+derivative 项。与本文关系：两者都用 control-theoretic framing，但 PID Steering 不建模 plant dynamics（仅调 gain），本文通过 Jacobian 构造 plant model 并用 LQR 得到 optimal feedback；PID Steering 的 gain 需要 per-task 调参，而 A-LQR 的 $(Q,R)$ 权重有明确物理含义。作者在实验中引入 S-PID 基线（PID 追踪 LFS），可视为二者的 hybrid 消融。

3. **Conditional Activation Steering (CAST)**（Lee et al., ICLR 2025 spotlight）
   解决 "vanilla steering 永远开着" 的问题：把 hidden state 投影到一个 "condition vector" 上，只有当输入匹配某条件时才 trigger steering。与本文关系：CAST 解决的是 *when to steer*，本文解决的是 *how to steer*；二者正交，可组合（例如，用 CAST 的 gating 信号决定是否激活 A-LQR 控制器）。本文未将 CAST 纳入基线是一个潜在 gap。

4. **From Steering Vectors to Conceptors: Compositional Affine Activation Steering for LLMs**（Postmus et al., 2024；[arXiv:2410.16314](https://arxiv.org/abs/2410.16314)）
   提出用 conceptor（soft projection matrix）作为 affine steering 操作子，支持多概念组合、subspace-level 控制。与本文关系：conceptor 给出 *representation-level* 的几何工具（把高维 activation 集合压缩成软投影），而 A-LQR 在 *dynamics-level* 做时序反馈控制。二者处理 activation 的层次互补；conceptor 可作为 A-LQR 的 feature direction $v_k$ 的替代生成器。

5. **Representation Engineering for Large-Language Models: Survey and Research Challenges**（2025；[arXiv:2502.17601](https://arxiv.org/abs/2502.17601)）
   截至 2025 年初对 representation engineering 的综述。整合了 probing、steering、monitoring 三类方法，并指出 steering 在 refusal / sentiment 上 robust 但在 factual recall / reasoning 上失灵。可作为本文所属 sub-field 的全景索引。

## 5. 组会讨论要点

1. **A-LQR 的 formal guarantee 是否真实可转化为 alignment-level 的 safety？**
   Theorem 4.2 给出的是 feature setpoint 的 tracking error bound（scalar $\beta_k$ 层面），但 alignment 的终极目标是 output token 分布的 property（toxicity rate、truthfulness）。从 feature tracking 到 output distribution 之间还有 softmax + sampling + evaluation metric 三层传递，tracking bound 并不等于 output-level 的 probabilistic safety。这个 gap 能不能用 **conformal prediction** 的方式 bridge？我们组在 conformal reachability 上的工作是否可以套到 LLM steering 上给出 output-level 的 $(1-\epsilon)$ guarantee？

2. **Local linearity 假设的适用边界**
   作者在 benign activation 邻域附近 linearize。如果 adversarial prompt（例如 AdvBench 中的 jailbreak suffix）把 activation 推出 linearization region，A-LQR 是否还有效？Fig. 3 的 Lipschitz 估计是否在 worst-case 下仍成立？这直接关系到把它当作 safety filter 用的可行性。

3. **与 CBF-style safety filter 的结合**
   A-LQR 本质是 tracking controller，不是 safety filter：它让 activation 更接近 target，但没有刻画"什么区域绝对不能进入"。我们组在 control barrier function 上的工作（包括 decentralized CBF、CBF 的 learnability）是否可以直接对接？例如，把"toxic subspace"定义为 super-level set of a neural barrier function $h(z)$，再用 A-LQR + CBF-QP 的组合做 safety-critical steering。这样得到的 filter 会比纯 tracking 在 OOD prompt 上更 robust。

## 参考文献

- Skifstad, Yang, Chou. *Local Linearity of LLMs Enables Activation Steering via Model-Based Linear Optimal Control*. arXiv:2604.19018, 2026. [[link]](https://arxiv.org/abs/2604.19018)
- Li, Patel, et al. *Inference-Time Intervention: Eliciting Truthful Answers from a Language Model*. NeurIPS 2023. [[arXiv:2306.03341]](https://arxiv.org/abs/2306.03341)
- Nguyen et al. *Activation Steering with a Feedback Controller* (PID Steering). arXiv:2510.04309, 2025. [[link]](https://arxiv.org/abs/2510.04309)
- Lee et al. *Conditional Activation Steering*. ICLR 2025 spotlight.
- Postmus et al. *From Steering Vectors to Conceptors: Compositional Affine Activation Steering for LLMs*. arXiv:2410.16314, 2024. [[link]](https://arxiv.org/abs/2410.16314)
- Turner et al. *Steering Language Models With Activation Engineering* (ActAdd). arXiv:2308.10248, 2023. [[link]](https://arxiv.org/abs/2308.10248)
- Bartoszcze et al. *Representation Engineering for Large-Language Models: Survey and Research Challenges*. arXiv:2502.17601, 2025. [[link]](https://arxiv.org/abs/2502.17601)
- Trustworthy Robotics Lab (Glen Chou, Georgia Tech). [[homepage]](https://glenchou.github.io/)
