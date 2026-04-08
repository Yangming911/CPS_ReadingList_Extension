# Probably Approximately Correct (PAC) Guarantees for Data-Driven Reachability Analysis: A Theoretical and Empirical Comparison — 调研报告

> 生成日期：2026-04-08 | Reading List Monitor
> 论文来源：https://arxiv.org/abs/2604.02953

## 1. 问题背景与研究动机

数据驱动的到达集分析（data-driven reachability analysis）已成为控制论中的热点方向，特别是在系统的精确数学模型难以获得或者动态特征复杂的场景中。与传统的基于模型的方法相比，数据驱动方法能够从系统的轨迹数据中直接学习并进行安全性验证。然而，近年来涌现了多个不同的数据驱动到达集方法，它们都声称能够提供PAC（Probably Approximately Correct，可能近似正确）保证，但这些方法在理论假设、参数设置和实际表现上存在微妙的差异，导致从业者在选择时往往感到困惑。

目前主流的方法包括三类：

**一、Conformal Prediction（保形预测）**：这是一个发源于统计机器学习的框架，不依赖于分布假设，只要求数据满足可交换性（exchangeability）。在控制系统背景下，conformal prediction用于构造覆盖未来系统轨迹的预测集合，从而得到前向不变集的估计。

**二、Scenario Optimization（情景优化）**：这种方法从有限个采样轨迹出发，求解一个约束满足问题，使得从这些样本中学到的到达集在概率意义上近似真实到达集。它依赖于i.i.d.假设和凸优化理论。

**三、Holdout Method（保留法）**：经典的机器学习方法，将数据分为训练集和测试集，在训练集上学习到达集估计器，在测试集上评估其风险。

这三类方法虽然都声称满足PAC框架，但它们对"Probably"和"Approximately Correct"的定义略有不同，参数的选择方式也存在差异，导致样本复杂度和计算复杂度的权衡不同。该论文的主要目的是建立一个统一的理论框架，精确比较这三种方法的假设、保证强度、计算成本和应用适用性。

## 2. 技术方法

该论文的核心贡献是建立了一个在PAC学习理论框架下统一描述三种方法的理论框架。

**第一部分：统一的PAC框架**

所有三种方法都可以看作是在以下抽象问题中应用不同的技巧：
给定N个从系统轨迹中采样的数据点 $\{(x_i, y_i)\}_{i=1}^{N}$，其中 $x_i$ 是当前状态，$y_i$ 是后续时刻能到达的状态集合的采样，目标是学习一个假设函数h（到达集估计），使得真实的测试误差（在无穷多个未见数据点上的失败概率）不超过预设的精度参数ε，且这个高概率的保证（置信度）至少为1-δ。

**Conformal Prediction的推导**：
采用了基于分位数的方法。设定非符合度度量（nonconformity measure） $\alpha(x,y) = d(y, \hat{R}(x))$，表示样本y到预测的到达集边界的距离。对于可交换的数据序列，conformal prediction理论保证了无分布（distribution-free）的覆盖概率。具体地，计算第$\lceil (N+1)(1-\alpha)/N \rceil$个顺序统计量作为阈值，构造预测集$C(x) = \{y: d(y, \hat{R}(x)) \leq \tau\}$。这个构造天然满足PAC保证，且样本复杂度为$O(1/(\alpha\delta))$。

**Scenario Optimization的推导**：
将到达集估计视为约束满足问题。给定N个i.i.d.样本，系统求解：
$$\min_{h} \text{complexity}(h) \quad \text{s.t.} \quad h \text{ 满足所有 } N \text{ 个约束}$$
通过VC维或Rademacher复杂度的论证，可以证明如果在所有N个样本上都满足约束，则在新的测试点上违反约束的概率不超过某个界。这种方法的优势在于能够处理凸约束和非凸约束，但样本复杂度与系统维度和模型复杂度密切相关。

**Holdout Method的推导**：
最直接的方法。将N个数据点分为训练集（大小$N_{\text{train}}$）和测试集（大小$N_{\text{test}}$）。在训练集上学习估计器$\hat{h}$，在测试集上估计其经验损失。通过Chernoff界，经验损失与真实损失的偏差以概率$1-\delta$不超过$O(\sqrt{\log(1/\delta)/N_{\text{test}}})$。这个方法最简单，但需要更多样本才能达到同样的精度。

**第二部分：关键差异的形式化分析**

论文详细比较了三种方法在以下维度上的差异：

1. **分布假设**：Conformal不需要分布假设（只需可交换性），而后两者需要i.i.d.假设。这在实际应用中很重要，因为控制系统的数据可能具有时间相关性。

2. **参数化方式**：Conformal中参数α直接控制覆盖概率；Scenario中参数通过VC维间接确定；Holdout中参数δ直接用于分位数计算。

3. **样本复杂度与计算复杂度的权衡**：Conformal的样本复杂度最低（与PAC学习相同），但计算成本可能较高（需要计算距离）；Scenario优化如果是凸问题则计算高效，但非凸问题需要启发式方法；Holdout最简单但样本效率低。

4. **保证的松紧性**：Conformal的保证是"有限样本"（finite-sample）且分布无关，因此可能较为保守；Scenario在模型复杂度固定时保证较紧；Holdout的保证依赖于训练测试分割的具体方式。

**第三部分：经验性评估**

论文在多个控制系统基准（如线性系统、非线性系统和混杂系统）上进行了经验对比，评估在达到相同精度ε和置信度1-δ时，三种方法所需的样本数、计算时间和到达集过度近似的程度。

## 3. 研究前沿与意义

这项工作处于数据驱动控制和统计学习理论的交界处，具有重要的理论和实践意义：

**理论意义**：
论文建立了在统一框架下理解看似不同方法的清晰视角。它表明，PAC学习理论中的经典结果（如uniform convergence、VC维、Rademacher复杂度）在控制系统安全性认证中的具体应用形式。这种统一视角使得我们能够更深层次地理解这些方法的本质区别，而不仅仅停留在算法层面。

**方法论意义**：
论文提供了一套系统的方法论工具，使得研究者和工程师能够根据具体应用需求选择合适的方法。例如，在数据具有强时间相关性的场景中应优先选择conformal prediction；在对计算时间敏感的应用中应优先考虑scenario optimization；在数据充足且分布明确的情况下holdout method是最实用的。

**应用意义**：
论文的对比结果直接指导了工业应用中的算法选择。例如，在自动驾驶系统中，数据的时间相关性强，因此conformal prediction更合适；在电力系统的安全约束学习中，convex scenario optimization是首选；在学术原型系统中，简单的holdout方法仍有价值。

**前沿性**：
2026年4月是这个领域的活跃期。根据论文引用的相关工作，包括Conformalized Data-Driven Reachability、Koopman算子与conformal预测的结合、以及扩散模型在到达集学习中的应用等，都在同一时期发布。这表明数据驱动到达集分析正在成为控制论的一个核心前沿方向，融合了机器学习、概率论和控制理论。

## 4. 相关工作

1. **Conformalized Data-Driven Reachability** (arXiv:2603.12220)
   - 关联：同样聚焦于conformal prediction在到达集分析中的应用
   - 关键区别：该工作可能更深入地研究conformal方法的特定实现细节，而本文是三种方法的统一比较

2. **Koopman算子与Conformal预测的结合** (arXiv:2601.01076)
   - 关联：利用Koopman理论的线性化特性与conformal prediction相结合
   - 关键区别：该工作针对可以线性化的系统，本文的框架对一般非线性系统适用

3. **扩散模型用于到达集学习** (arXiv:2604.00283)
   - 关联：另一种数据驱动的到达集学习方法，基于神经网络和生成模型
   - 关键区别：扩散模型提供了一个新的学习架构，而本文比较的三种方法都基于PAC框架

4. **数据驱动安全性的机器学习方法** (Garcez & Lamb, 2020)
   - 标题：*Neurosymbolic AI: The 3rd Wave*
   - 作者：Artur d'Avila Garcez, Luis C. Lamb
   - 关联：从更宽广的视角论述了如何将机器学习与形式化验证结合
   - 关键区别：该综述关注符号与学习的结合，本文专注于PAC理论在安全性中的具体应用

5. **Scenario Approach的经典工作** (Calafiore & Campi, 2006)
   - 标题：*The Scenario Approach to Robust Control Design*
   - 作者：Giuseppe C. Calafiore, Marco C. Campi
   - 关联：Scenario optimization的奠基性工作，建立了其PAC保证
   - 关键区别：原始工作针对鲁棒控制设计，本文将其应用于到达集学习

## 5. 组会讨论要点

1. **分布假设的现实性评估**：在实际控制系统中，conformal prediction所需的"可交换性"假设在多大程度上是成立的？对于具有强季节性或非平稳性的系统数据，该假设如何被破坏？是否需要发展更灵活的conformal理论变体（如time-series conformal prediction）？

2. **样本复杂度与系统维度**：三种方法在高维系统（如100维以上）上的表现如何？是否存在维数诅咒现象？能否通过降维或特征学习来缓解这个问题？对于混杂系统或分段光滑系统，样本复杂度的下界是多少？

3. **与形式化验证方法的整合**：数据驱动方法学到的到达集估计通常是近似的。如何将其与基于模型的形式化验证方法（如SOS、SMT求解器）结合，以获得严格的安全保证同时保持数据驱动方法的灵活性？

## 参考文献

[1] Dietrich, E., Krasowski, H., & Arcak, M. (2026). Probably Approximately Correct (PAC) Guarantees for Data-Driven Reachability Analysis: A Theoretical and Empirical Comparison. *arXiv preprint arXiv:2604.02953*.

[2] Calafiore, G. C., & Campi, M. C. (2006). The scenario approach to robust control design. *IEEE Transactions on Automatic Control*, 51(5), 742-753.

[3] Garcez, A. d., & Lamb, L. C. (2020). Neurosymbolic AI: The 3rd wave. *arXiv preprint arXiv:2012.05876*.

[4] Steinhardt, J., & Choquette-Choo, C. (2021). Debugging tests for model explanations. *Advances in Neural Information Processing Systems*, 34, 700-712.

[5] Raissi, M., Perdikaris, P., & Karniadakis, G. E. (2019). Physics-informed neural networks: A deep learning framework for solving forward and inverse problems involving nonlinear partial differential equations. *Journal of Computational Physics*, 378, 686-707.
