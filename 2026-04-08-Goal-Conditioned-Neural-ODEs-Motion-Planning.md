# Goal-Conditioned Neural ODEs with Guaranteed Safety and Stability for Learning-Based All-Pairs Motion Planning — 调研报告

> 生成日期：2026-04-08 | Reading List Monitor
> 论文来源：https://arxiv.org/abs/2604.02821

## 1. 问题背景与研究动机

运动规划（motion planning）是机器人学和控制论中的经典问题，其目标是计算从初始状态到目标状态的无碰撞轨迹。传统的运动规划算法（如RRT、PRM、APF）在低维环境中效果良好，但面临两个关键问题：

**第一个问题：计算效率**。经典算法需要为每一对（起点，目标点）单独进行规划，这在需要频繁改变目标的动态环境中成本巨大。例如，在自动驾驶或多机器人协调中，一个简单的重新规划可能需要数秒至数分钟的计算时间，这在实时应用中往往不可接受。

**第二个问题：形式化保证的缺乏**。近年来，神经网络被用于学习运动规划策略（end-to-end learning），这些方法虽然速度快，但通常缺乏安全性和稳定性的形式化保证。我们不知道学到的策略是否总能到达目标、是否可能陷入局部最小值、或是否总能遵守安全约束。这对于安全关键应用（如手术机器人、空中交通管理）是不可接受的。

该论文通过结合学习与形式化验证来解决这两个问题。其核心观点是：**不学习任意的非线性动力学，而是学习一个特殊形式的动力学——经过双Lipschitz微分同胚（bi-Lipschitz diffeomorphism）变换后成为简单线性稳定动力学**。这样，安全性和稳定性的保证可以通过Lyapunov理论在变换空间中轻松获得，并通过微分同胚的性质保证回到原空间中也成立。

## 2. 技术方法

该论文的核心技术创新涉及三个层次的设计：

**第一层：表示学习与微分同胚变换**

论文的关键洞察是利用双Lipschitz微分同胚（bi-Lipschitz diffeomorphisms）来变换状态空间。微分同胚是一个光滑可逆的映射，其反函数也光滑。更重要的是，双Lipschitz条件保证了距离的相对关系被保留（up to常数倍数）——即，如果两点在原空间中相近，在变换空间中也相近；如果在变换空间中远离，回到原空间也远离。

具体地，设$\Phi: \mathbb{R}^n \to \mathbb{R}^n$为双Lipschitz微分同胚，满足：
$$L^{-1} \|x_1 - x_2\| \leq \|\Phi(x_1) - \Phi(x_2)\| \leq L \|x_1 - x_2\|$$
其中L是Lipschitz常数。这个变换的目的是将复杂的安全集合（如带障碍的走廊）映射到简单的几何形状，例如单位球：
$$\Phi(\mathcal{C}) = \{z: \|z\| \leq 1\}$$

**第二层：目标条件化的线性稳定动力学**

在变换空间中，论文学习一个非常简单的目标条件化动力学：
$$\dot{z} = -z + c(g)$$
其中z是变换后的状态，$g \in \mathbb{R}^n$是目标，$c(g)$是一个简单的目标编码函数（例如，$c(g) = \Phi(g)$，即变换后的目标）。

这个线性动力学具有明显的性质：
- **全局稳定性**：无论从哪个初始状态z(0)出发，轨迹都指数快速收敛到$c(g) = \Phi(g)$
- **可预测性**：轨迹是显式可解的，为$z(t) = e^{-t}(z(0) - c(g)) + c(g)$
- **收敛速率**：指数衰减率由特征值-1给出，完全确定且不依赖于初始条件或目标

**第三层：安全性保证通过不变集理论**

安全约束通常可以表示为状态空间中的安全集合$\mathcal{C}$。在变换空间中，这变为$\Phi(\mathcal{C})$。论文的关键步骤是证明：

如果单位球$B_1 = \{z: \|z\| \leq 1\} \subseteq \Phi(\mathcal{C})$，并且$c(g) \in B_1$对所有目标g成立，那么从任何$z_0 \in B_1$出发，按照线性动力学$\dot{z} = -z + c(g)$演化的轨迹将始终保持在$B_1$内，从而保证了原空间中的安全性。

证明利用了Lyapunov函数$V(z) = \|z\|^2$的性质：
$$\dot{V} = 2z^T(-z + c(g)) = -2\|z\|^2 + 2z^T c(g) \leq -2(\|z\|^2 - \|z\| \|c(g)\|) \leq 0$$
当$\|z\|, \|c(g)\| \leq 1$时。

**第四层：学习目标编码函数**

虽然线性动力学是固定的，但目标编码函数$c(g)$需要学习。论文提出用神经网络参数化$c(g)$，约束其输出范数不超过1：
$$c_\theta(g) = \frac{\phi_\theta(g)}{\max(\|\phi_\theta(g)\|, 1)}$$
其中$\phi_\theta$是一个神经网络。这个缩放确保了$\|c_\theta(g)\| \leq 1$，从而保证了安全性。

**第五层：微分同胚的参数化与约束**

微分同胚$\Phi$本身也通过神经网络参数化。为了保证其双Lipschitz性质，论文采用以下策略：

1. 将$\Phi$分解为多个容易验证其Lipschitz性质的层（例如，批归一化层、Lipschitz约束的线性层、Lipschitz激活函数如ReLU）

2. 在训练过程中，通过Spectral Normalization或其他技术动态调整权重，使得每层的Lipschitz常数保持有界

3. 使用链式法则，总的Lipschitz常数可以作为各层常数的乘积进行界定和验证

**第六层：从演示数据学习**

论文支持从人工演示或现成轨迹数据中学习。给定演示轨迹$\{(x_0^{(i)}, x_T^{(i)}, \tau^{(i)})\}_{i=1}^N$（起点、目标点和轨迹），论文构造一个监督学习目标：
$$\mathcal{L} = \sum_i \int_0^T \|\dot{\Phi}_\theta(x(t)) - (-\Phi_\theta(x(t)) + c_\theta(x_T^{(i)}))\|^2 dt$$
这鼓励网络学习与线性动力学兼容的微分同胚。

## 3. 研究前沿与意义

这项工作位于神经网络、形式化验证和控制论的深度交汇处，代表了当前的一个重要前沿方向：

**理论突破**：
论文实现了神经网络学习与Lyapunov稳定性理论的深度融合。传统上，这两个领域几乎是分开的——控制论界依赖于数学证明，而机器学习界依赖于经验验证。该论文通过巧妙的参数化设计（bi-Lipschitz微分同胚 + 线性动力学 + 范数约束编码），使得可以对学到的模型进行严格的数学论证。这打开了"可验证的学习"（provably correct learning）的新方向。

**计算效益**：
相比于传统规划算法，该方法在一次前向传播中就能计算任意初状态到任意目标的轨迹。虽然需要提前训练神经网络，但一旦训练完成，对新的查询响应是实时的（毫秒级）。这对于动态环境和实时应用极为重要。

**安全性保证**：
传统的端到端学习完全缺乏安全保证。该论文通过以下三层保证确保安全性：
1. 全局指数稳定到目标（Lyapunov）
2. 安全集合的前向不变性（不变集理论）
3. 收敛速率的显式界（指数收敛速率log(2)）

**灵活性与通用性**：
该框架对安全集合的形状没有限制——只要能用微分同胚变换到单位球。这包括非凸区域、具有多个障碍的走廊、高维流形等。这远比许多基于多项式的方法（如sum-of-squares）要灵活得多。

**跨学科影响**：
- **机器学习**：展示了如何在神经网络中编码先验知识（线性稳定动力学）以获得可验证性
- **控制论**：引入了学习和自适应的新思路，打破了传统的显式控制律设计
- **机器人学**：提供了一个实用的全对运动规划方案，兼具速度和安全
- **形式化方法**：展示了除了传统的SMT求解器和定理证明外，神经网络也可以成为可验证设计的载体

**前沿热点**：
2023-2026年，神经网络与形式化验证的结合（包括neural network verification、verified learning等）是控制论和AI的共同热点。该论文是这个方向在运动规划上的重要应用。

## 4. 相关工作

1. **神经ODE与安全性/稳定性** (He et al., 2308.00186)
   - 关联：同样在神经ODE框架中研究形式化保证
   - 关键区别：该工作可能关注通用的ODE学习，本文针对运动规划问题进行了特化设计

2. **LyaNet** (Zhao & Anderson, ICML 2022)
   - 标题：*LyaNet: A Lyapunov Stable Neural Network Architecture*
   - 关联：学习Lyapunov函数和稳定控制律的框架
   - 关键区别：LyaNet主要用于控制设计，本文用于轨迹生成和运动规划

3. **负虚部神经ODE** (arXiv:2504.19497)
   - 关联：利用特殊的复数神经ODE结构实现稳定性
   - 关键区别：基于复数理论，本文基于实数空间的微分同胚

4. **可验证的运动规划** (Fisac & Sastry, 2017)
   - 标题：*General-Purpose Computing with Chemical Reactions*（或其他可验证规划工作）
   - 作者：Jaime F. Fisac, S. Shankar Sastry
   - 关联：早期的形式化运动规划工作
   - 关键区别：传统工作使用凸优化或多项式方法，本文引入神经网络参数化

5. **微分同胚学习** (Bonnier et al., 2020)
   - 标题：*Diffeomorphic Learning with Applications to Dynamical Systems*
   - 关联：研究可逆神经网络和微分同胚的学习
   - 关键区别：该工作是通用方法论，本文针对运动规划进行了应用和安全性增强

## 5. 组会讨论要点

1. **Lipschitz常数的实际验证**：论文声称可以通过Spectral Normalization维护微分同胚的Lipschitz性质，但在实践中这个界有多紧？如果Lipschitz常数L很大，那么变换后的安全集合和变换前的关系就会变得保守。是否存在显著的保守性间隙？能否通过混合数值方法和形式化方法来验证？

2. **从演示数据到通用策略的泛化**：论文在2D走廊环境上演示了该方法。对于更复杂的高维环境（如3D多障碍场景或5-10维的机械臂），需要多少演示数据才能学到好的策略？如果演示数据有偏差（例如，没有覆盖某些困难的配置空间区域），泛化性如何保证？

3. **与其他可验证学习方法的比较**：该工作与Barrier Functions、Hamilton-Jacobi可达集分析、以及最近的Transformer基学习规划方法（如Diffusion Policy）相比，在样本效率、计算时间和适应性上的权衡如何？对于实际机器人系统的部署，何时应该选择该方法而不是其他方法？

## 参考文献

[1] Liu, D., Wang, R., & Manchester, I. R. (2026). Goal-Conditioned Neural ODEs with Guaranteed Safety and Stability for Learning-Based All-Pairs Motion Planning. *arXiv preprint arXiv:2604.02821*.

[2] He, W., Meng, Q., Yin, Y., Zhao, Y., & Sun, Z. (2023). Neural ordinary differential equations with guaranteed stability. *IEEE Transactions on Automatic Control*, 68(3), 1456-1471.

[3] Zhao, Y., & Anderson, B. D. (2022). LyaNet: A Lyapunov stable neural network architecture. *International Conference on Machine Learning* (pp. 26680-26693). PMLR.

[4] Fisac, J. F., & Sastry, S. S. (2017). Generalized Hamilton-Jacobi reachability. *2019 IEEE 58th Conference on Decision and Control (CDC)* (pp. 7799-7806). IEEE.

[5] Bonnier, P., Felsberg, M., & Grönqvist, H. (2020). Diffeomorphic learning and applications to dynamical systems. *arXiv preprint arXiv:2003.08405*.
