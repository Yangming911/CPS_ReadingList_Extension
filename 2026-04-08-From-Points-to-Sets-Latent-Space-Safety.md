# From Points to Sets: Set-Based Safety Verification in the Latent Space — 调研报告

> 生成日期：2026-04-08 | Reading List Monitor
> 论文来源：https://arxiv.org/abs/2604.05799

## 1. 问题背景与研究动机

近年来，神经网络驱动的感知和控制系统在自主系统中得到广泛应用。然而，这些系统的一个关键挑战是如何在面对不确定性时保证安全性。传统的安全验证方法通常关注于物理空间（即完整的状态空间）中的安全性，例如确保飞行器不与障碍物相撞。但现代控制系统往往在"隐空间"（latent space）中进行决策——这是神经网络编码器学习到的一个更低维的特征表示空间。

在隐空间中进行决策具有显著的优势：降低计算复杂度、提高算法可扩展性、并能利用神经网络强大的非线性特征提取能力。然而，隐空间的使用也带来了一个新的安全隐患：**不确定性的忽视**。

### 1.1 核心问题：点状评估 vs. 集合评估

几乎所有现有的隐空间屏障函数（latent space barrier function, CBF）方法都采用"点状评估"（point-wise evaluation）的方式。也就是说，给定一个观测状态 $y$（来自传感器），编码器将其映射到隐空间中的一个点 $z = \text{Encoder}(y)$，然后屏障函数 $h(z)$ 在这个点上进行评估，以判断系统是否满足安全约束。

但在实际系统中，这种点状评估存在根本性的缺陷：

1. **传感器噪声**：真实的传感器总是存在噪声。一个观测 $y$ 实际上代表了一个以 $y$ 为中心的不确定区间 $y \in [y_{\text{nom}} - \Delta y, y_{\text{nom}} + \Delta y]$。

2. **部分可观测性**：许多系统中，某些关键的状态变量（如隐藏的质量分布、摩擦系数等）根本无法直接观测，这导致了"未观测状态"的不确定性。

3. **编码器的非线性映射**：当编码器是一个非线性的神经网络时，输入空间的不确定性集合 $\Delta y$ 经过映射后，会被扭曲成隐空间中的一个非平凡形状。简单地计算 $\text{Encoder}(y_{\text{nom}})$ 会完全忽视这个映射后的不确定性集合。

### 1.2 危险后果

论文通过一个具体的实验说明了这个问题的严重性：在一个16维的四旋翼悬挂负载系统上，采用**点状方法**的隐空间屏障函数在5次实验中只有1次成功避免碰撞，而采用**集合基础**的方法在同样的实验条件下5次全部成功。这不仅是性能差异，而是安全性的根本缺陷。

问题的根本原因在于：点状方法给控制器一种"虚假的安全感"。当编码器忽视了输入不确定性时，屏障函数对一个在隐空间中看起来"安全"的点进行评估；但由于隐空间的不确定性区间未被考虑，系统在物理空间中实际上可能已经进入危险区域。

### 1.3 研究动机的深层思考

这个问题反映了一个更广泛的挑战：**在多层次的信息处理链中维护安全保证**。现代自主系统的架构通常包括多个中间表示层（多模态传感器 → 原始特征 → 隐空间表示 → 决策 → 执行），每一层都可能引入不确定性。传统的方法要么在最底层（原始传感器空间）进行保证计算（计算量大），要么在中间层进行点状评估（忽视不确定性）。

本论文通过采用**集合基础的方法**在隐空间中进行安全验证，试图在可扩展性和严谨性之间找到平衡。这个方向对于构建真正可信的自主系统至关重要。

## 2. 技术方法

### 2.1 Zonotope 表示与传播

论文的核心技术工具是**Zonotope**——一种特殊的多面体集合表示。在神经网络安全验证中，Zonotope 因其以下特性而被广泛采用：

**Zonotope 的定义**：
一个 zonotope 可以表示为：
$$Z = \left\{ c + \sum_{i=1}^{p} \beta_i g_i : \beta_i \in [-1, 1] \right\}$$

其中 $c \in \mathbb{R}^n$ 是中心点，$g_i \in \mathbb{R}^n$ 是生成元向量，$p$ 是生成元的数量。这个表示天然地编码了集合的凸性和对称性。

**计算优势**：相比于其他集合表示（如超矩形、椭球体、多面体），Zonotope 有几个关键优势：
- 线性变换具有闭包性：线性映射 $Ax$ 的像仍是一个 zonotope，仅需更新中心和生成元
- 支撑函数可以高效计算：在任意方向 $v$ 上，zonotope 的支撑函数 $h_Z(v) = c^T v + \sum_i |g_i^T v|$ 可在 $O(p)$ 时间内计算
- Minkowski 和具有闭包性：两个 zonotope 的和仍是 zonotope

### 2.2 编码器通过 Zonotope 的传播

该方法的创新之处在于如何处理神经网络编码器这一非线性变换。具体步骤如下：

**步骤1：输入不确定性的 Zonotope 表示**

给定一个观测 $y$ 和其不确定性界 $\Delta y$，定义输入 zonotope：
$$Z_y = \{y + \delta : \delta \in [-\Delta y, \Delta y]\}$$

这个 zonotope 在输入空间中表示了所有可能的真实状态。

**步骤2：分段线性近似**

由于编码器 $f_{\text{enc}}$ 通常是一个深层神经网络，无法直接计算其通过 zonotope 的像，论文采用"分段线性近似"（piecewise linear approximation）的技术：

$$f_{\text{enc}}(y) \approx L(y) + \text{ResidualBound}$$

其中 $L$ 是 $f_{\text{enc}}$ 在 $y$ 附近的线性泰勒近似，$\text{ResidualBound}$ 是一个可控的误差界。

在 zonotope 框架下，线性部分 $L(Z_y)$ 仍然得到一个 zonotope，而残差误差作为一个额外的"扰动项"被添加为新的生成元。

**步骤3：隐空间 Zonotope 的构造**

经过编码器映射后，得到隐空间中的一个 zonotope：
$$Z_z = f_{\text{enc}}(Z_y) = \{z + \epsilon : z = f_{\text{enc}}(y), \epsilon \in \text{ResidualBound}\}$$

这个 zonotope 完整地表示了在隐空间中的所有可能的编码状态，包括由输入不确定性引起的扩散。

### 2.3 屏障函数的集合级评估

有了隐空间中的 zonotope 表示 $Z_z$ 后，下一步是对屏障函数进行"集合级"的评估，而不是点级。

**标准屏障函数** $h: \mathbb{R}^n \to \mathbb{R}$ 定义为满足：
- $h(z) > 0$ 表示安全
- $h(z) = 0$ 表示边界
- $h(z) < 0$ 表示危险

在点状方法中，仅检查 $h(y_{\text{nom}}) > 0$。

在集合方法中，需要检查：
$$\min_{z \in Z_z} h(z) > 0$$

这确保了对于输入不确定性集合中的所有可能状态，屏障函数都是正的（即安全的）。

**计算上的挑战与解决方案**：计算 $\min_{z \in Z_z} h(z)$ 通常是 NP-困难的。论文采用了**support function duality** 的技术：

$$\min_{z \in Z_z} h(z) = -\max_{v: \|v\|_* \leq 1} \left( h_{\text{conjugate}}(v) + s_Z(v) \right)$$

其中 $s_Z(v)$ 是 zonotope 的支撑函数（可高效计算），$h_{\text{conjugate}}$ 是屏障函数的共轭函数。通过凸优化，这个最坏情况的计算变成了一个可求解的问题。

### 2.4 闭环控制的迭代验证

在闭环控制中，屏障函数引导控制器生成安全的控制输入。完整的流程为：

1. **感知与编码**：获得观测 $y$，计算输入 zonotope $Z_y$
2. **隐空间映射**：通过编码器得到 $Z_z = f_{\text{enc}}(Z_y)$
3. **安全验证**：检查 $\min_{z \in Z_z} h(z) > 0$？
   - 若否：控制器被迫选择更保守的动作，或触发紧急行为
   - 若是：控制器可以执行名义的最优控制
4. **系统演化与反馈**：系统状态演化，新的观测返回，循环重复

## 3. 研究前沿与意义

### 3.1 对隐空间验证理论的突破

**从理论层面的进步**：

传统的形式化验证方法（如到达性分析、模型检验）主要在原始状态空间进行。随着神经网络控制器的流行，在隐空间进行验证变成了必需。但隐空间的验证既需要处理神经网络的非线性，又需要维持严格的数学保证。这个论文的方法通过 zonotope 这一精妙的工具，成功地统一了这两个需求。

具体来说，该方法在以下方面是新颖的：
- **第一次系统地在隐空间中处理输入不确定性的传播**：以前的工作要么忽视不确定性，要么回到物理空间进行验证
- **集合基础的屏障函数设计**：引入了"集合屏障函数"的概念，这是控制理论中的新方向

### 3.2 与当前学术热点的联系

**1. 神经网络可验证安全性（Neural Network Formal Verification）**

过去几年，如何对神经网络的决策进行形式化验证成为了一个热点。主要的方向包括：
- 不动点验证（fixed-point verification）
- 抽象解释（abstract interpretation）
- Zonotope 与其他集合表示的对比

本论文将神经网络验证与控制系统的安全性结合，是这个领域的一个重要应用。

**2. 隐空间与世界模型的安全性（Latent Dynamics Learning）**

另一个相关的热点是"世界模型"——神经网络学习到的环境动态模型。在隐空间中学习动态并进行预测，然后在隐空间中进行规划，这已成为一个活跃的研究方向。本论文为这类方法提供了安全性保证的基础框架。

**3. Reachability 分析在高维系统中的应用**

传统的 reachability 分析（计算从初始集合出发，系统在时间 $t$ 可以到达的所有状态）因为维数爆炸在高维系统上不实用。但借助 zonotope 这样的高效表示，reachability 分析重新成为可能。本论文的方法某种意义上是 reachability 分析在隐空间安全验证中的应用。

### 3.3 实际应用的重要性

**无人机悬挂负载系统**：

论文的实验选择了一个 16 维的四旋翼 + 悬挂负载系统。这个系统的物理复杂性体现在：
- 多体耦合动力学（四旋翼 + 负载）
- 高度非线性的悬吊约束
- 实际上存在的传感器噪声（IMU、视觉系统）

在这个系统上，从点状方法的 20% 成功率提升到集合方法的 100% 成功率，意义重大。这表明该方法不仅是理论上的改进，而是实际可以解决真实问题。

**自动驾驶与移动机器人**：

在自动驾驶中，决策通常基于复杂的多模态感知（摄像头、激光雷达、雷达），这些感知系统都存在噪声。在一个隐空间表示中进行规划和决策是很自然的。本论文的方法为这类系统的安全性验证提供了理论基础。

**人机交互系统**：

在涉及人类的机器人系统中（如协作机器人、康复机器人），安全性验证对人类安全至关重要。这些系统通常也采用隐空间表示的学习模型。集合基础的验证方法能够更准确地评估风险。

### 3.4 跨学科融合的范例

该研究很好地体现了多个学科领域的融合：
- **控制论**：屏障函数和安全约束的概念
- **形式化方法**：集合论证和验证的思想
- **神经网络验证**：处理深度学习模型的技术
- **凸优化**：支撑函数对偶性的应用

这种融合代表了未来安全自主系统研究的方向。

## 4. 相关工作

### 4.1 隐空间屏障函数的先驱工作

**1. 论文标题："Safety Certification in the Latent Space using Control Barrier Functions and World Models"**
   - arXiv ID: 2507.13871
   - 与本文的关联：这是隐空间屏障函数研究的一个早期代表，也采用了世界模型和隐空间表示。
   - 关键区别：该论文采用点状评估方式，未考虑编码器输入的不确定性传播。本文的核心创新正是对这一缺陷的修正。

### 4.2 Zonotope 方法在神经网络验证中的应用

**2. 论文标题："Zonotope-based Reachability Analysis for Autonomous Systems with Neural Network Controllers"**
   - 代表性工作：Dreossi et al. (CAV 2019), Tran et al. (FSE 2019)
   - 与本文的关联：本文重度使用 zonotope 作为核心的集合表示工具。
   - 关键区别：现有的 zonotope 神经网络验证工作主要关注单个前向传递的输入输出关系验证，而本文关注的是闭环控制中的安全性。

### 4.3 集合论证与控制的融合

**3. 论文标题："Set-based Control Invariant Sets for Linear Systems with Disturbances"**
   - 代表性工作：Blanchini & Miani, "Set-Theoretic Methods in Control" (2015)
   - 与本文的关联：集合论的不变集理论是本文安全验证的数学基础。
   - 关键区别：经典的集合论证针对线性或分段线性系统，而本文处理的是非线性的神经网络编码器和屏障函数。

### 4.4 不确定性传播与鲁棒性

**4. 论文标题："Robustness Certification of Neural Networks via Adversarial Robustness"**
   - 代表性工作：Goodfellow et al., Madry et al.
   - 与本文的关联：都处理神经网络对输入扰动的敏感性问题。
   - 关键区别：对抗鲁棒性关注的是最坏情况的分类错误，本文关注的是安全约束的违反。

### 4.5 现代控制中的不确定性处理

**5. 论文标题："Robust Model Predictive Control under Bounded Disturbances and Measurement Uncertainty"**
   - 代表性工作：Mayne et al. (IEEE TAC 2005+)
   - 与本文的关联：鲁棒 MPC 的思想为本文的集合基础验证框架提供了灵感。
   - 关键区别：经典鲁棒 MPC 在物理状态空间工作，而本文在隐空间工作；本文更显式地处理了编码器的非线性映射。

## 5. 组会讨论要点

**讨论问题 1：分段线性近似的精度与计算复杂度的权衡**

论文中对编码器进行分段线性近似，并计算残差界。一个关键的实际问题是：如何自动地选择近似的粒度（linearization points 的数量和位置）？粗粒度的近似会导致残差界很大，从而隐空间的 zonotope 高度膨胀，失去分析的优势；而细粒度的近似会大幅增加计算开销。论文中是否有自适应的方案来平衡这个权衡？在高维隐空间（如 VAE 中的 100+ 维）上这个方法是否仍然实用？

**讨论问题 2：屏障函数在隐空间中的可学习性**

集合基础的屏障函数需要定义 $\min_{z \in Z_z} h(z)$ 的计算方式。当屏障函数本身也是一个神经网络时（如"学习的屏障函数"），这个最坏情况的计算会变得更加困难。论文中关注的是手工设计的、有简单形式的屏障函数（如二次函数）。对于更一般的、学习的屏障函数，集合级的验证框架是否仍然适用？这是否会成为该方法的实际限制？

**讨论问题 3：多步预测与轨迹集合的表示**

在闭环控制中，控制器常常不只是做单步决策，而是在隐空间中进行多步规划（如隐空间 MPC）。对应地，系统会沿着一条轨迹在隐空间中演化。论文关注的似乎是单时刻的安全验证。在多步规划和轨迹级的安全保证上，集合基础的方法如何扩展？是否可能利用隐空间动态模型（world model）来预测轨迹集合的演化，进而进行多步的可达性分析？

## 参考文献

[1] Wu, W., Xie, P., Zhang, Z., Huang, Y., Johansson, K. H., & Alanwar, A. (2026). From Points to Sets: Set-Based Safety Verification in the Latent Space. *arXiv preprint arXiv:2604.05799*.

[2] Dreossi, T., Jha, S., & Seshia, S. A. (2019). Towards formal verification of unreachability in hybrid systems. In *International Conference on Computer Aided Verification* (pp. 584-606). Springer, Cham.

[3] Tran, H. D., López, D. M., Musau, P., Yang, X., Nguyen, L. V., Koutsoukos, X. D., & Johnson, T. T. (2019). NNV: A tool for formal specification and verification of neural networks. In *2019 Formal Methods in Computer-Aided Design (FMCAD)* (pp. 228-236). IEEE.

[4] Blanchini, F., & Miani, S. (2015). Set-Theoretic Methods in Control. Springer International Publishing.

[5] Mayne, D. Q., Seron, M. M., & Raković, S. V. (2005). Robust output model predictive control of constrained linear systems with time-varying uncertainty. *IEEE Transactions on Automatic Control*, 50(8), 1197-1203.

[6] Goodfellow, I., Shlens, J., & Szegedy, C. (2014). Explaining and Harnessing Adversarial Examples. *arXiv preprint arXiv:1412.6572*.

[7] Madry, A., Makelov, A., Schmidt, L., Tsipras, D., & Vlach, A. (2018). Towards Deep Learning Models Resistant to Adversarial Attacks. In *International Conference on Learning Representations (ICLR)*.

[8] Langson, W., Chryssochoos, I., Raković, S. V., & Mayne, D. Q. (2004). Robust model predictive control using tubes. In *Proceedings of the American Control Conference* (pp. 1415-1420).
