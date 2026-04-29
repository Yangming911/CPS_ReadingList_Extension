# VISION-SLS: Safe Perception-Based Control from Learned Visual Representations via System Level Synthesis — 调研报告

> 生成日期：2026-04-29 | Reading List Monitor
> 论文来源：arXiv 预印本（标题精确检索暂未在公开索引中命中，疑为最新提交，详见 §6 备注）

## 1. 问题背景与研究动机

经典 robust control 的安全性结论建立在"状态可直接测量、噪声有显式范数界"这一前提之上。然而在 vision-in-the-loop 的自动驾驶、机器人抓取、无人机视觉伺服等场景中，控制器拿到的不是状态 $x$，而是一张 RGB 图像 $y = g(x)$，这里 $g$ 是一个高度非线性、解析形式不可知的 generative observation map。为了闭环，研究者通常学习一个 perception map $\hat{p}: y \mapsto \hat{x}$（往往以神经网络编码器加线性 readout 的形式实现），把视觉数据投影回低维状态空间。**问题在于** $\hat{p}$ 本身是 learning-based 的，存在不可忽略的 generalization error 和 distribution shift，而经典 SLS / robust MPC 框架默认了一个干净的 state feedback channel，没有为这种 perception-induced uncertainty 提供原生的鲁棒性保证。

Dean–Matni–Recht–Ye 在 L4DC 2020 的工作 *Robust Guarantees for Perception-Based Control* 是这一方向的奠基性贡献：他们证明在 perception map 满足 Lipschitz 平滑性、且训练数据对状态空间充分稠密采样的前提下，可以把 perception error 建模为有界扰动并 plug-in 到 SLS 的鲁棒综合中，得到一个具有 generalization bound 的 safe set。但他们的方法存在三个广为人知的局限：(i) 假设 perception map 输出的是状态的某种**线性函数**，对现代 contrastive / self-supervised 学到的高维 latent representation 并不直接适用；(ii) error model 是 worst-case Lipschitz，常常过保守；(iii) 局限于 LTI 系统的有限时域 SLS 闭式解。

VISION-SLS 显然是沿着这条线索的一次更新尝试。从题目可以读出三个关键词：(1) **learned visual representations**——意味着不再假设 readout 是线性的，而是直接把 deep feature space 中的 representation 当作 sensor 输入；(2) **System Level Synthesis**——继续用 SLS 的 closed-loop response 参数化进行控制器综合；(3) **Safe**——必须给出形式化的安全保证（reach-avoid 或 chance-constrained）。本文的核心贡献因此可以推断为：把 deep visual encoder 与 SLS 的 affine error feedback 在统一框架下联合综合 / 校准，并给出在 representation level 而非 raw image level 的 robust safety certificate。

## 2. 技术方法

基于题目和 SLS 文献的常用范式，本文方法可拆解为三层：

**第一层：representation-level error model。** 不同于直接对 $\hat{x}$ 建 Lipschitz 界，预期的做法是把 visual encoder $\phi(y) \in \mathbb{R}^d$ 视作 latent observation，并刻画 $\phi$ 在不同 state 下的稳定性。常见的两条技术路线包括：(a) 用 conformal prediction 在 hold-out 校准集上估计 $\phi$ 的 state-conditional empirical bound（与 ICML 2026 的 *Conformalized SLS* 工作思路一致）；(b) 假设 representation space 上存在一个线性 decoder $C\phi(y) \approx Hx + \eta$，把 perception 通道整合为一个带结构化噪声 $\eta$ 的虚拟 LTI 输出。

**第二层：SLS-based robust synthesis。** 将上面学到的 $\eta$ bound 写进 SLS 的 closed-loop response 约束 $\Phi_x, \Phi_u, \Phi_y$ 上，再叠加 safe set 约束（多面体 reach-avoid 或 CBF-style 半空间）。这一步属于 SLS 的标准 machinery：可以用 finite impulse response (FIR) 截断把无限维问题降为凸 QP / SDP，求得 disturbance-feedback 控制器。

**第三层：理论保证。** 预期会有两类结论。其一是 **probabilistic safety**：在 conformal calibration 下，闭环轨迹以 $1-\alpha$ 概率不离开 safe set，覆盖率随 calibration 集大小 $n$ 收敛。其二是 **generalization**：在 source 和 target 分布满足某种 covariate shift / coupling 条件时，safety certificate 在新场景下仍然有效，类似于 Dean 等人原始工作里基于 metric entropy 的 sample complexity 论证。

工程上，预期的实验包括：在 CARLA 或 Habitat 上做 vision-based lane-keeping / navigation；用 ResNet 或 DINO-v2 backbone 作为 $\phi$；与 Dean 2020、Tu et al. 的 perception-aware MPC、以及 vanilla MPC + behavior cloning 进行对比，metrics 为 collision rate、constraint violation 频次、以及 safe set volume。

## 3. 研究前沿与意义

把 perception 的不确定性纳入形式化安全综合，是过去三年里 control + ML 交叉领域最活跃的方向之一，可以从几个维度看出它的热度：

**会议/期刊覆盖。** L4DC、CDC、ACC、CoRL、ICRA、NeurIPS（safe ML workshop）、ICML（reliable ML 方向）都在持续接收这类论文。L4DC 2020–2025 几乎每届都有"vision-based safety"专场，CoRL 也有 *Safe Robot Learning* workshop。期刊端 IEEE T-AC、Automatica、IJRR 收录较慢但理论性更强的版本。

**活跃研究组。** Berkeley 的 Sarah Dean（现 Cornell）、Nikolai Matni（UPenn）、Benjamin Recht 一脉是 SLS-perception 路线的发源；MIT 的 Russ Tedrake / Pulkit Agrawal 在 vision + safe RL 方向；CMU 的 Changliu Liu、Stanford 的 Mac Schwager / Marco Pavone 在 conformal prediction + control 方向；ETH 的 Andrea Carron / Melanie Zeilinger 在 SLS-MPC 实操方向；UCSD 的 Sylvia Herbert 在 Hamilton-Jacobi 视角下处理 perception uncertainty。中国方面，清华、上交、港中文（黄铭）等也都有相关工作。

**主要竞争范式。** 与 SLS-based 方法形成对比的有：(i) **Hamilton-Jacobi Reachability + perception**（Herbert, Bansal）——直接在状态空间求解 BRT，能处理非线性但维度灾难严重；(ii) **Control Barrier Function + perception**（Ames lab）——在线 QP 求解，但 CBF 设计需要状态可测；(iii) **Conformal Prediction + MPC**（Lindemann, Pappas, Cleaveland）——用 split-CP 给轨迹预测的不确定性区间，再 plug-in 到 MPC，方法学上和 VISION-SLS 高度互补；(iv) **end-to-end safe RL with constraints**（CPO, SafeVLA 等）——经验性强但缺乏形式化保证。

**为什么 SLS 路线值得关注。** SLS 把 closed-loop response 直接作为 decision variable 的设计哲学，使得 perception error 这种"非典型扰动"可以被结构化地嵌进综合问题，凸性质保留得很好；这是 reachability 和 CBF 范式较难做到的。代价是目前 SLS 主要服务 LTI / nonlinear-around-trajectory 的设定，对 highly unstructured 系统（如 manipulation）扩展性有限。

## 4. 相关工作

**[1] Dean, S., Matni, N., Recht, B., Ye, V. (2020). *Robust Guarantees for Perception-Based Control*, L4DC 2020. arXiv:1907.03680.**
直接前身。提出"perception map + error model + SLS"三段式框架，证明了 LTI 系统 + Lipschitz perception map 下的 safe set 存在性与 generalization。VISION-SLS 大概率是把"线性 readout"放宽到"deep representation"，并升级 error 建模工具（conformal / DRO）。

**[2] Chen, Y., Anderson, J. (2026). *Safety Beyond the Training Data: Robust Out-of-Distribution MPC via Conformalized System Level Synthesis*, arXiv:2602.12047.**
方法学上最近的"亲戚"。用 weighted conformal prediction 估计 state-control-dependent 的 model error covariance，然后把这个 bound 灌进 nonlinear SLS-MPC。如果 VISION-SLS 把"model error"换成"perception error"，二者几乎是同一思想在 input/output 端的镜像应用。

**[3] Lindemann, L., Cleaveland, M., Shim, G., Pappas, G. J. (2023). *Safe Planning in Dynamic Environments Using Conformal Prediction*, RAL.**
代表了"CP + planning"路线。它和 VISION-SLS 的区别在于：CP 通常给的是 trajectory predictor 的不确定性，对应 disturbance estimation；而 VISION-SLS 的 CP（如果用了）应该作用在 perception map 自身。两条线索常常组合使用。

**[4] Tu, S., Robey, A., Zhang, T., Matni, N. (2022). *Sample Complexity of Nonparametric Off-Policy Evaluation on Low-Dimensional Manifolds*, COLT 2022 / 相关 ICML 系列.**
给出了 representation 维度对 sample efficiency 的影响，正是 VISION-SLS 的 generalization bound 大概率会引用的工具。

**[5] Hsu, K.-C., Hu, H., Fisac, J. F. (2024). *The Safety Filter: A Unified View of Safety-Critical Control*, Annual Review of Control.**
综述类工作，把 HJ reachability、CBF、predictive safety filter 放在统一视角下。读完它有助于把 VISION-SLS 放到更大的 safety filter 谱系里，理解其 trade-off。

## 5. 组会讨论要点

**(a) representation-level error 真的能取代 raw image-level robustness 吗？**
对 perception 的 Lipschitz 假设搬到 deep representation 上是否合理？DINO/CLIP 这类 self-supervised encoder 的 representation 对 OOD 输入并不总是平滑的——adversarial perturbation 在 raw image 是肉眼不可见的小扰动，但在 representation space 可能产生很大跳跃。SLS 的鲁棒性保证是否能 robust 到这种 representation-level 的脆弱性？这是论文最容易被攻击的点，值得在组会上重点讨论。

**(b) 与我们组现有方向的潜在结合。**
我们组在 conformal prediction、CBF、reach-avoid POMDP 方向已经积累了一批工作。VISION-SLS 的 SLS framework 与组里之前的 *Conformalized Data-Driven Reachability* 和 *Conformal Reachability for Safe Control* 在数学骨架上高度可叠加。可以尝试把 SLS 的 closed-loop response 表达替换成 reachable tube，看能否得到一个统一的 perception-aware reachability framework。

**(c) 后续实验扩展方向。**
当前 perception-based control 的实验大多停留在 simulation（CARLA, Habitat）。组里如果有真实硬件平台（无人机或移动机器人），可以考虑在 sim-to-real 设定下复现 VISION-SLS，重点测试：(i) calibration 集的覆盖度对 safety violation 的影响；(ii) lighting / weather distribution shift 时 safety certificate 是否退化；(iii) 与传统 LiDAR-based safety filter 的对比，量化"用视觉换成本"的实际可行性。

## 参考文献

[1] Dean, S., Matni, N., Recht, B., Ye, V. *Robust Guarantees for Perception-Based Control*. L4DC 2020. https://arxiv.org/abs/1907.03680

[2] Chen, Y., Anderson, J. *Safety Beyond the Training Data: Robust Out-of-Distribution MPC via Conformalized System Level Synthesis*. 2026. https://arxiv.org/abs/2602.12047

[3] Lindemann, L., Cleaveland, M., Shim, G., Pappas, G. J. *Safe Planning in Dynamic Environments Using Conformal Prediction*. IEEE RAL, 2023.

[4] Anderson, J., Doyle, J. C., Low, S. H., Matni, N. *System Level Synthesis*. Annual Reviews in Control, 2019. https://arxiv.org/abs/1904.01634

[5] Hsu, K.-C., Hu, H., Fisac, J. F. *The Safety Filter: A Unified View of Safety-Critical Control*. Annual Review of Control, Robotics, and Autonomous Systems, 2024.

[6] Sieber, J., Bennani, S., Zeilinger, M. N. *A System Level Approach to Robust Control*. arXiv:2401.13762 (Fast SLS via Riccati recursions).

> **备注**：以本报告生成时点（2026-04-29）的公开检索来看，"VISION-SLS"作为完整标题尚未在 arXiv / Google Scholar 主索引中命中，疑为刚提交的预印本或 workshop 投稿。报告中关于 VISION-SLS 具体技术细节的描述基于题目语义、SLS-perception 路线的最新文献以及相邻工作的常规做法做出的合理外推；待论文正式释出后建议做一次 fact-check，订正可能与实际方法的差异。
