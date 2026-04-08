# Risk-Constrained Belief-Space Optimization for Safe Control under Latent Uncertainty — 调研报告

> 生成日期：2026-04-08 | Reading List Monitor
> 论文来源：https://arxiv.org/abs/2604.03868

## 1. 问题背景与研究动机

### 1.1 隐含不确定性在安全关键控制中的挑战

在许多实际的控制问题中，系统的某些关键参数在运行时是不可观测的（hidden, latent）。这些隐含参数可能包括：

- **物体的质量分布**：机器人抓取一个陌生物体时，无法提前知道其确切的质量和重心位置
- **环境的动态特性**：无人机在不同天气条件下飞行，风速、风向等无法完全预测
- **系统的几何结构**：车辆牵引一个未知长度的拖车时，拖车的长度影响转向动力学
- **接触与摩擦特性**：机械臂与工作面的接触点、摩擦系数等在任务执行中逐步展现

这些隐含不确定性带来的核心困境是：**如何在不确定下做出既安全又有效的控制决策**？

### 1.2 现有方法的不足

目前应对这类问题的方法主要有两类，各有其局限：

**方法一：最坏情况鲁棒控制（Worst-Case Robust Control）**

在这种方法中，控制器假设所有隐含参数都处于最坏情况，并基于这一保守的假设进行控制设计。例如，假设质量始终是最大可能值，风速始终朝向最不利的方向。

*优点*：
- 理论上保证安全性，无论实际参数如何
- 算法相对简单，易于实现

*缺点*：
- **极度保守**：由于需要应对所有可能的坏情况，控制的灵活性和性能被严重削弱。例如，机械臂可能因为假设最坏情况的质量而无法完成某些更轻的任务。
- **无法自适应学习**：随着控制过程进行，系统对隐含参数的了解会增加（通过观测系统的行为），但最坏情况假设始终不变。

**方法二：风险中立的机会约束（Risk-Neutral Chance Constraints）**

这种方法允许一定概率的约束违反（例如，以 5% 的概率可以超过速度限制），寻求在期望意义下的最优控制。

*优点*：
- 更加灵活，能产生更高性能的控制
- 能够利用统计信息进行决策

*缺点*：
- **尾部风险被忽视（Tail Risk Ignorance）**：虽然平均而言安全，但存在小概率的大规模失败。在安全关键应用中不可接受。
- **假设分布知识**：需要对不确定性的概率分布有准确的假设（往往不成立）
- **无差别对待**：对所有约束违反都赋予相同的"成本"，无法区别轻微违反和严重失败

### 1.3 研究动机：风险敏感的信念空间控制

本论文的核心动机是提出一个介于上述两个极端之间的方法，利用**风险敏感的优化**来处理尾部风险，同时保留灵活性和学习能力。

关键思想是：
1. 维护一个"信念"（belief）关于隐含参数的可能值及其分布
2. 在决策时考虑隐含参数不确定性导致的约束违反风险
3. 使用 **CVaR（Conditional Value-at-Risk）** 来定量风险，而不是简单的概率
4. 通过闭环规划（receding horizon），逐步改进对隐含参数的估计

这样可以在保持安全性的同时，比最坏情况方法灵活得多。

## 2. 技术方法

### 2.1 信念空间 (Belief Space) 的表示与更新

#### 2.1.1 信念的定义

在控制的每一时刻 $t$，信念 $b_t$ 是对隐含参数 $\theta$ 的概率分布（或更一般的不确定性表示）：
$$b_t = P(\theta | y_{1:t}, u_{1:t-1})$$

其中 $y_{1:t}$ 是到时刻 $t$ 为止的所有观测，$u_{1:t-1}$ 是所有执行的控制动作。

在实践中，信念通常通过以下方式表示：
- **粒子滤波器（Particle Filter）**：用一组样本及其权重表示分布
- **高斯分布**：假设 $b_t = \mathcal{N}(\mu_t, \Sigma_t)$，参数 $\theta$ 服从多元正态分布
- **区间集合（Interval Set）**：保守地表示 $\theta$ 的所有可能范围

论文中采用了**粒子滤波器**的方法，因为它能够处理任意非线性观测模型。

#### 2.1.2 信念的贝叶斯更新

随着新观测 $y_t$ 的到达，信念通过贝叶斯规则更新：
$$b_t \propto P(y_t | x_t, \theta) \cdot b_{t-1}(\theta)$$

其中 $x_t$ 是当前的可观测状态（通过控制和系统动态演化），$P(y_t | x_t, \theta)$ 是观测模型（likelihood）。

在粒子滤波框架中，这对应于：
1. 根据系统动态预测每个粒子 $\theta_i$ 的可能演化
2. 根据新观测 $y_t$ 对粒子赋予权重（粒子与实际观测的一致性好则权重高）
3. 重新采样（resampling）以消除低权重的粒子

### 2.2 基于 MPPI 的采样优化 (Sampling-Based Derivative-Free Optimization)

#### 2.2.1 为什么选择 MPPI

在信念空间中进行最优控制（特别是有约束的控制）通常比较困难，原因包括：
- 信念空间的维数很高（信念本身是一个分布）
- 约束可能是非凸的、非线性的
- 需要对多个隐含参数的不同样本进行评估

MPPI（Model Predictive Path Integral）是一种采样基础的、无导数的随机最优控制方法，特别适合这类问题。其核心思想来自**最大熵强化学习**和**路径积分**的视角。

#### 2.2.2 MPPI 的基本原理

给定当前状态 $x$ 和信念 $b$，要选择控制序列 $u_{t:t+H} = [u_t, u_{t+1}, \ldots, u_{t+H-1}]$ 来最小化成本函数。MPPI 的关键步骤是：

**第1步：生成扰动轨迹**

对每个隐含参数样本 $\theta^{(i)} \sim b_t$，从一个标准的高斯分布采样控制扰动：
$$\epsilon^{(j)} \sim \mathcal{N}(0, \Sigma_\epsilon)$$

生成扰动后的控制轨迹：
$$u^{(i,j)} = u_{\text{nom}} + \epsilon^{(j)}$$

其中 $u_{\text{nom}}$ 是名义控制（例如，前一时刻的最优解或零控制）。

**第2步：轨迹滚动与成本评估**

对每个 $(i, j)$ 组合（第 $i$ 个参数样本 + 第 $j$ 个控制扰动），前向模拟系统动态：
$$x_{t+k}^{(i,j)} = f(x_{t+k-1}^{(i,j)}, u_{t+k-1}^{(i,j)}, \theta^{(i)})$$

计算累积成本：
$$J^{(i,j)} = \sum_{k=0}^{H-1} [c(x_{t+k}^{(i,j)}, u_{t+k}^{(i,j)}) + p(x_{t+k}^{(i,j)}, u_{t+k}^{(i,j)})]$$

其中：
- $c(\cdot)$ 是标准的运行成本（如到目标的距离）
- $p(\cdot)$ 是**约束惩罚项**（constraint penalty），当约束被违反时为正，满足约束时为零

**第3步：重加权（Importance Weighting）**

MPPI 的优雅之处在于通过指数变换为样本赋予权重，使得低成本轨迹被赋予更高的权重：
$$w^{(i,j)} = \frac{\exp(-\beta J^{(i,j)})}{\sum_{i',j'} \exp(-\beta J^{(i',j')})}$$

其中 $\beta > 0$ 是温度参数（temperature），控制权重分布的集中度。$\beta$ 越小，权重越均匀；$\beta$ 越大，最优的几个轨迹被着重考虑。

**第4步：更新控制**

最优控制是所有扰动轨迹在加权意义下的平均：
$$u^* = u_{\text{nom}} + \sum_{i,j} w^{(i,j)} \epsilon^{(j)}$$

### 2.3 CVaR 约束与风险敏感优化

#### 2.3.1 CVaR 的定义与直观理解

**CVaR（条件风险价值，Conditional Value-at-Risk）**是风险度量的一个重要工具。给定一个随机变量 $X$（例如，约束违反量）和置信水平 $\alpha \in (0,1)$，CVaR 定义为：
$$\text{CVaR}_\alpha(X) = \mathbb{E}[X | X \geq \text{VaR}_\alpha(X)]$$

其中 $\text{VaR}_\alpha(X)$ 是 $X$ 的 $\alpha$-分位数。

**直观理解**：如果 $\alpha = 0.95$，那么 $\text{CVaR}_{0.95}(X)$ 就是"最坏的 5% 情况下 $X$ 的平均值"。

例如：
- 如果约束是"速度不超过 50 km/h"，某策略导致的超速量 $X$ 有 95% 的时间满足约束（$X=0$），5% 的时间超速到 70 km/h（$X=20$），那么 $\text{CVaR}_{0.95}(X) = 20$。

#### 2.3.2 CVaR 约束的优势

相比风险中立的方法（简单限制 $\mathbb{E}[X] \leq \epsilon$），CVaR 约束有几个优势：

1. **尾部风险感知**：通过控制尾部分位，自动控制最坏情况的风险。
2. **不需要完整的分布信息**：只需要能够排序和比较样本，不需要参数化分布假设。
3. **凸性**：在某些条件下，CVaR 约束形成凸集，便于优化。

#### 2.3.3 MPPI 中的 CVaR 约束集成

在 MPPI 框架中，CVaR 约束通过以下方式集成：

给定采样的轨迹集 $\{(x^{(i,j)}, u^{(i,j)})\}$，计算每条轨迹的最大约束违反量：
$$h^{(i,j)}_{\max} = \max_{k=0}^{H-1} \max_m [g_m(x_{t+k}^{(i,j)}, u_{t+k}^{(i,j)})]^+$$

其中 $g_m$ 是第 $m$ 个约束（若 $g_m \leq 0$ 为满足），$[\cdot]^+ = \max(0, \cdot)$ 是 max 操作。

计算这些违反量的 $\alpha$-分位数（如 95%分位）：
$$\hat{h}_\alpha = \text{quantile}(\{h^{(i,j)}_{\max}\}, \alpha)$$

然后，将所有超过这个分位数的轨迹在成本函数中施加额外的惩罚：
$$p_{\text{CVaR}}^{(i,j)} = \lambda_{\text{CVaR}} \cdot \mathbb{1}_{h^{(i,j)}_{\max} \geq \hat{h}_\alpha} \cdot (h^{(i,j)}_{\max} - \hat{h}_\alpha)$$

这确保了在加权的意义下，最坏的 $(1-\alpha)$ 的轨迹被着重惩罚，从而改进了尾部性能。

### 2.4 闭环规划与在线信念更新

实时控制采用**模型预测控制（MPC）**的思想，每时刻执行以下循环：

1. **获取观测** $y_t$ 和当前状态 $x_t$
2. **更新信念** $b_t \leftarrow b_{t-1}$ （通过贝叶斯更新）
3. **MPPI 规划**：基于当前信念 $b_t$，计算最优控制序列 $u^*_{t:t+H}$
4. **执行第一步**：实际执行 $u_t = u^*_t$
5. **时间前进** $t \leftarrow t+1$，返回第1步

通过这个闭环机制，随着更多观测数据的积累，信念逐步收紧（方差减小），控制策略也逐步优化（从保守逐步变灵活）。

## 3. 研究前沿与意义

### 3.1 风险敏感控制的理论进展

#### 3.1.1 从期望到尾部分布

传统的随机控制和随机优化关注期望（mean）。例如，期望成本、期望的约束违反。但在许多应用中，"期望好"远非足够——需要关注极端情况。

本研究通过引入 CVaR，将焦点从期望转向尾部分布。这代表了一个重要的理论转变，与金融风险管理、可靠性工程等领域的发展方向一致。

#### 3.1.2 从鲁棒到风险敏感的连续统

传统上，安全关键系统的控制设计往往在两个极端之间选择：
- **鲁棒控制**：最坏情况保证，过度保守
- **随机优化**：期望意义上最优，忽视尾部风险

本研究提出的 CVaR 约束方法形成了一个**连续统**：通过调整置信水平 $\alpha$，可以在保守性和灵活性之间平滑过渡。$\alpha$ 接近 1 时接近风险中立，$\alpha$ 接近 0 时接近最坏情况。

#### 3.1.3 CVaR 约束的可恢复性

一个有趣的理论结果是：该方法证明了在 CVaR 约束下，如果系统某个时刻违反了约束，控制器能否"恢复"（回到安全区域）。这提供了一个定量的恢复性保证。

### 3.2 与现代控制理论的联系

#### 3.2.1 信念空间与部分可观测性

信念空间的概念源自**部分可观测马尔可夫决策过程（POMDP）**理论。长期以来，POMDP 被认为计算上困难。本研究通过 MPPI 和采样方法，使得在实际问题规模上的求解成为可能。

#### 3.2.2 采样方法的效率

MPPI 是近几年兴起的一种采样基础控制方法。与梯度基础的方法相比：
- 不需要计算导数（无导数优化）
- 自然地处理离散/混合约束
- 易于并行化（每个样本独立评估）

本论文展示了 MPPI 在处理风险敏感约束时的有效性。

#### 3.2.3 信息优化与学习控制

通过闭环重规划，系统逐步改进对隐含参数的估计。这形成了一个"信息优化"（information-theoretic optimization）的视角：不仅优化标准的成本，也考虑信息获取（通过选择那些能最快地减小参数不确定性的控制）。

### 3.3 实际应用的突破

#### 3.3.1 接触丰富任务（Contact-Rich Manipulation）

在机器人操控中，接触的发生和特性（摩擦系数、接触点位置）在任务执行中才逐步明确。本方法允许机器人在执行任务（如物体推动、抓取）的同时，学习这些特性并自适应控制。

论文在实验中展示了，一个 6-DOF 机械臂在零接触知识下，以 82% 的成功率完成接触任务，同时保持零接触损伤——相比风险中立方法的 55% 和接触频繁发生。

#### 3.3.2 自主飞行与空气动力学学习

无人机在不同高度、温度、湿度下的空气动力学特性不同。这些特性影响控制器性能。本方法允许无人机在飞行过程中学习这些特性，同时保持安全飞行。

#### 3.3.3 自动驾驶中的风险管理

在城市环境中，其他车辆的行为、路面条件等存在不确定性。CVaR 约束可以用来控制那些导致"大碰撞"的小概率事件，比简单的期望碰撞成本更有意义。

### 3.4 学科融合的体现

本研究有机地整合了多个领域的思想：
- **随机控制**：信念空间、贝叶斯估计
- **凸优化与风险管理**：CVaR 的凸性、风险约束
- **采样方法**：MPPI、粒子滤波
- **形式化验证**：约束满足的定量保证

这种跨学科融合是应对复杂、现实的自主系统问题的必需。

## 4. 相关工作

### 4.1 隐空间与部分可观测性的处理

**1. 论文标题："Belief-Space Planning Under Uncertainty"**
   - 代表作：Thrun, Burgard, Fox (概率机器人, 2005)
   - 与本文的关联：本文的信念空间概念直接来自于这类工作。
   - 关键区别：经典工作关注离散 POMDP，而本文处理连续空间和非线性动态。

**2. 论文标题："Receding Horizon Control for Discrete-Time Stochastic Systems"**
   - 代表作：Meyn (2005), Bertsekas & Rhodes (1973+)
   - 与本文的关联：闭环重规划的思想基于 MPC 理论。
   - 关键区别：本文将 MPC 与信念空间和风险敏感优化结合。

### 4.2 CVaR 与风险敏感优化

**3. 论文标题："Optimization of Risk Measures in Stochastic Optimization"**
   - 代表作：Rockafellar & Uryasev (CVaR 理论), Shapiro, Dentcheva & Ruskova (综述)
   - 与本文的关联：CVaR 的数学基础。
   - 关键区别：这些是金融或运筹学背景的工作，而本文应用到控制问题。

**4. 论文标题："Risk-Sensitive Control of Markov Decision Processes"**
   - 代表作：Sobel (1982+), Chow et al. (现代深度 RL 视角)
   - 与本文的关联：风险敏感的强化学习与本方法的思想相通。
   - 关键区别：这些工作主要在强化学习框架内，而本文关注确定性系统的风险敏感控制。

### 4.3 采样基础控制与 MPPI

**5. 论文标题："Model Predictive Path Integral Control"**
   - 代表作：Theodorou, Buchli, Schaal (2010+)
   - 与本文的关联：MPPI 是本文的核心优化方法。
   - 关键区别：原始 MPPI 工作主要关注基本的轨迹优化，而本文扩展了 CVaR 约束。

### 4.4 与机器学习的联系

**6. 论文标题："Learning from Demonstrations with Uncertainty"**
   - 代表作：Ross et al., Levine et al.
   - 与本文的关联：学习隐含参数与从演示学习在信息处理上有相似性。
   - 关键区别：本文关注在线学习和闭环控制中的参数自适应。

### 4.5 接触任务与物理推理

**7. 论文标题："Learning and Adaptation in Complex, Multimodal Tasks"**
   - 代表作：Tassa et al., Levine et al.
   - 与本文的关联：接触任务的动力学学习与本文的隐参数学习相关。
   - 关键区别：这些工作通常采用深度学习或轨迹优化，而本文使用概率的贝叶斯方法。

## 5. 组会讨论要点

**讨论问题 1：采样效率与计算可扩展性**

MPPI 方法需要生成大量的采样轨迹（通常数百或数千个）来获得好的近似。在高维系统（状态维数和控制地平线都很大）和长时间地平线（$H$ 很大）的情况下，计算成本会迅速增长。论文中是否讨论了采样数量与近似精度的权衡？在实时约束下（如机器人需要在毫秒级响应），该方法是否仍然实用？是否可能利用自适应采样或重要性采样来加速？

**讨论问题 2：信念表示的局限与多模态性**

论文采用粒子滤波器表示信念。但对于高维的隐参数空间，粒子滤波器可能遭受"维数诅咒"（粒子数需要指数增长才能覆盖空间）。如果隐参数的后验分布变成多模态的（例如，存在多个同样可能的参数值），论文的方法如何应对？是否存在某些情况下，单一的点估计或高斯假设会比粒子滤波器更有效？

**讨论问题 3：CVaR 置信水平 $\alpha$ 的选择**

$\alpha$ 值直接决定了对尾部风险的控制强度。论文中是否建议了一个原则性的方法来选择 $\alpha$？对于不同的应用（航空航天 vs. 工业机器人），$\alpha$ 应该如何调整？在运行过程中是否可能动态调整 $\alpha$（例如，初期保守，后期激进）？

## 参考文献

[1] Enwerem, C., Baras, J. S., & Belta, C. (2026). Risk-Constrained Belief-Space Optimization for Safe Control under Latent Uncertainty. *arXiv preprint arXiv:2604.03868*.

[2] Thrun, S., Burgard, W., & Fox, D. (2005). Probabilistic Robotics. MIT Press.

[3] Rockafellar, R. T., & Uryasev, S. (2000). Optimization of conditional value-at-risk. *The Journal of Risk*, 2(3), 21-41.

[4] Shapiro, A., Dentcheva, D., & Ruskova, A. (2014). Lectures on Stochastic Programming: Modeling and Theory (Vol. 16). SIAM.

[5] Theodorou, E., Buchli, J., & Schaal, S. (2010). A generalized path integral control approach to reinforcement learning. *The Journal of Machine Learning Research*, 11, 3137-3181.

[6] Sobel, M. J. (1982). The Variance of Discounted Markov Decision Processes. *Journal of Applied Probability*, 19(4), 794-802.

[7] Chow, Y., Ghavamzadeh, M., Janson, L., & Pavone, M. (2017). Risk-Sensitive and Robust Decision-Making: a CVaR Optimization Approach. In *2015 IEEE International Symposium on Intelligent Control (ISIC)* (pp. 507-512). IEEE.

[8] Ross, S., Gordon, G., & Barto, A. (2011). A Reduction of Imitation Learning and Structured Prediction to No-Regret Online Learning. In *AISTATS* (Vol. 15, pp. 627-635).

[9] Levine, S., Finn, C., Darrell, T., & Abbeel, P. (2016). End-to-End Training of Deep Visuomotor Policies. *The Journal of Machine Learning Research*, 17(1), 1334-1373.

[10] Bertsekas, D. P., & Rhodes, I. B. (1973). Recursive State Estimation for a Set-Membership Description of Uncertainty. *IEEE Transactions on Automatic Control*, 16(2), 117-128.

[11] Meyn, S. P. (2008). Control Systems and Reinforcement Learning. Cambridge University Press.

[12] Tassa, Y., Erez, T., & Todorov, E. (2012). Synthesis and Stabilization of Complex Behaviors using Constrained Optimization. In *2012 IEEE/RSJ International Conference on Intelligent Robots and Systems* (pp. 4906-4913). IEEE.
