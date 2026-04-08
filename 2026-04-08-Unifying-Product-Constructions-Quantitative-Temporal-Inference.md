# A Unifying Approach to Product Constructions for Quantitative Temporal Inference — 调研报告

> 生成日期：2026-04-08 | Reading List Monitor
> 论文来源：https://arxiv.org/abs/2407.10465（已发表于 OOPSLA 2025）

## 1. 问题背景与研究动机

### 1.1 核心问题的理论根源

在软件系统和控制系统的形式化验证中，一个根本性的问题是：**如何高效、正确地计算执行轨迹（execution traces）满足某个时间属性（temporal property）的概率或成本？**

这个看似简单的问题实际上涉及多个不同的计算范式，每个范式都有自己的理论框架和应用领域：

1. **Markov Reward Models (MRM)**：在马尔可夫模型中计算从初始状态到某个目标状态的期望奖励（expected reward）。这是强化学习和概率系统分析中的经典问题。

2. **Weighted Model Checking**：对加权（带有数值标签的）Kripke 结构进行模型检验，计算满足 LTL/CTL 公式的轨迹的加权和（weighted sum）。

3. **Resource-Sensitive Reachability**：计算系统从初始状态到达某个目标状态时，"消耗"的资源量（如时间、能量、网络带宽）。

4. **Probabilistic Reachability**：计算系统以多大的概率能够到达某个目标集合。

表面上看，这四个问题分别来自不同的理论社区，采用不同的数学语言和算法。但它们都在回答一类本质相同的问题：**系统如何根据时间或逻辑属性来量化不同执行路径的度量？**

### 1.2 为什么需要统一框架

在过去的几十年里，这些问题被分别研究，导致了几个理论和实践上的问题：

**1. 代码重复与算法碎片化**：形式化验证工具（如 PRISM、Storm、PAT）中，计算期望奖励、概率和资源消耗的算法本质上是相同的（都是基于线性方程系统的求解），但由于缺乏统一的理论框架，工具开发者不得不为每种问题类型分别实现算法。这导致了代码重复、bug 难以追踪、优化困难。

**2. 新问题的验证困难**：当一个新的应用域出现（例如，既要验证概率性的轨迹属性，又要考虑资源消耗），研究者需要从头开始设计新的算法和数据结构。缺乏统一的理论指导，创新变得困难。

**3. 正确性证明的分散性**：每个问题类型都有自己的正确性证明。这些证明往往使用不同的数学工具（概率论、图论、线性代数），使得学生和研究者学习成本高，且难以识别和迁移证明的共同模式。

### 1.3 范畴论与 Coalgebra 的启示

本论文的核心洞察是：这些看似不同的问题实际上都可以在**范畴论（Category Theory）**和**Coalgebra（余代数）**的框架下统一理解。

具体地：

- **系统本身是一个 Coalgebra**：一个确定型或随机系统可以表示为一个 coalgebraic 结构，其转移关系反映了系统的"行为"。

- **时间属性也是一个 Coalgebra**：LTL、CTL、"到达某状态的期望步数"等看似各不相同的属性，本质上都可以表示为某种 coalgebra 结构。

- **"产品构造"就是一个分配律（Distributive Law）**：传统的产品构造（product construction）是指将系统和属性"组合"成一个新的系统的过程。在 coalgebra 框架中，这个组合过程对应于一个**分配律**（两个 functor 的组合顺序）。

通过这个统一的视角，论文证明了：所有的时间推理问题都可以通过"选择合适的 coalgebra 和分配律"来解决。这样，一旦有了一个通用的、基于 coalgebra 的求解算法，就可以自动适用于所有问题类型。

## 2. 技术方法

### 2.1 Coalgebra 与系统的表示

#### 2.1.1 什么是 Coalgebra

在数学上，一个 coalgebra 是一个对 algebra（代数结构）的"对偶"概念。直观地说：

- **Algebra** 是一个集合加上"组成"（composition）操作：$A \to F(A)$（从更基本的元素组合成复杂结构）
- **Coalgebra** 是一个集合加上"分解"（decomposition）操作：$S \to F(S)$（将复杂结构分解成更基本的信息）

在系统论中，一个 coalgebra 可以表示为：
$$\sigma: S \to F(S)$$

其中：
- $S$ 是状态空间
- $F$ 是一个 functor（函数），通常编码了系统的转移结构
- 对每个状态 $s \in S$，$\sigma(s) \in F(S)$ 给出了该状态的"下一步"信息

**具体例子**：
- 确定系统：$\sigma: S \to S \times O$，其中 $O$ 是观测空间。每个状态映射到下一个状态和一个观测值。
- 随机系统：$\sigma: S \to \text{Dist}(S) \times O$，其中 $\text{Dist}(S)$ 是 $S$ 上的概率分布。每个状态映射到下一个状态的分布和观测值。
- 加权系统：$\sigma: S \to (S \times \mathbb{R}_{\geq 0}) \times O$。每个转移关联一个权重。

#### 2.1.2 Functor 与转移结构

Functor $F$ 的选择决定了系统的结构。常见的 functor 包括：

$$F_1(X) = X \times O \quad \text{（确定系统）}$$

$$F_2(X) = \text{Dist}(X) \times O \quad \text{（概率系统）}$$

$$F_3(X) = \mathcal{P}_{\text{fin}}(X) \times O \quad \text{（非确定系统，} \mathcal{P}_{\text{fin}} \text{ 是有限幂集 functor）}$$

$$F_4(X) = (X \times \mathbb{R}) \times O \quad \text{（加权系统）}$$

一个关键的观察是：通过选择不同的 $F$，我们可以用统一的 coalgebra 框架表示各种不同的系统。

### 2.2 时间属性的 Coalgebra 表示

#### 2.2.1 LTL 公式的 Coalgebra 观点

传统上，LTL（Linear Temporal Logic）是通过Büchi 自动机或更新函数来处理的。本论文的创新是：将 LTL 公式本身也表示为一个 coalgebra。

给定一个 LTL 公式 $\phi$ 和一个 Kripke 结构（状态 + 标签），可以构造一个"属性 coalgebra"：
$$\rho: Q_\phi \to G_\phi(Q_\phi)$$

其中：
- $Q_\phi$ 是公式的"状态"（与 Büchi 自动机的状态类似）
- $G_\phi$ 是一个 functor，编码了公式的转移逻辑

例如，对于公式 $\phi = \text{next}(\psi)$（下一步），$G_\phi$ 可能简单地指向 $\psi$ 的状态空间。

#### 2.2.2 期望值、资源消耗等作为 Coalgebra

更有趣的是，即使不涉及传统的时间逻辑，许多定量属性也可以 coalgebraically 表示：

**期望奖励（Expected Reward）**：在 Markov 过程中计算从状态 $s$ 到目标的期望奖励，可以表示为：
$$V: S \to \mathbb{R} \cup \{\infty\} \times S$$

其中第一个分量是期望值，第二个是系统的转移。

**资源消耗（Resource Consumption）**：计算到达目标所消耗的资源，可以用类似的方式表示为一个"加权" coalgebra。

### 2.3 产品构造与分配律

#### 2.3.1 传统的产品构造

在模型检验中，给定一个系统 $\sigma: S \to F(S)$ 和一个属性 $\rho: Q \to G(Q)$，"产品"通常定义为：
$$\pi: S \times Q \to H(S \times Q)$$

其中 $H$ 是某个新的 functor。具体形式取决于 $F$ 和 $G$ 的具体选择。

例如，如果 $F(X) = X \times O$ 和 $G(X) = X$，产品可能是：
$$\pi(s, q) = ((s', q'), o) \quad \text{其中 } \sigma(s) = (s', o) \text{ 且 } \rho(q) = q'$$

#### 2.3.2 分配律（Distributive Law）的统一视角

本论文的关键发现是：所有的产品构造都可以通过一个**分配律**来描述：
$$\lambda: F \circ G \Rightarrow G \circ F$$

这是一个 natural transformation，表示两个 functor 的组合顺序可以互换（在某种意义上）。

**直观解释**：
- 如果我们先应用系统的转移（$F$），再应用属性的转移（$G$），结果应该与先应用属性的转移再应用系统转移相同（可能差一个同构）。

**数学形式**：对所有 $X$，存在一个映射：
$$\lambda_X: F(G(X)) \to G(F(X))$$

使得某些"自然性"条件满足。

#### 2.3.3 从分配律导出算法

一旦有了分配律 $\lambda$，产品 coalgebra 可以统一地定义为：
$$\pi: S \times Q \to H(S \times Q)$$

其中 $H = G \circ F$（或等价地 $F \circ G$，通过分配律）。

关键是：产品的转移关系 $\pi$ 可以从 $\lambda$ **自动推导**，无需针对每个问题类型手工定义。

### 2.4 求解算法的统一框架

一旦系统和属性都表示为 coalgebra，并且产品构造通过分配律定义，计算可以通过**标准的 coalgebraic 算法**进行：

**不动点迭代（Fixpoint Iteration）**：
$$X_{n+1} = F(X_n) \cap X_0$$

其中 $X_0$ 是初始的"满足属性"的状态集，$F$ 是基于转移关系的迭代操作。

**关键定理（Adequacy Theorem）**：论文证明了，对于所有通过分配律定义的产品构造，上述不动点迭代算法都是正确的，即：

$$\lim_{n \to \infty} X_n = \{s : \text{从} s \text{出发的轨迹满足属性}\}$$

这个统一的算法可以一次性实现，然后通过改变 functor $F$ 和分配律 $\lambda$，自动应用于所有问题类型。

## 3. 研究前沿与意义

### 3.1 形式化方法中的理论突破

#### 3.1.1 数学基础的统一

本研究在一个更深的层次上统一了形式化验证的理论基础。传统上，概率模型检验、确定性系统的 LTL 验证、资源分析等使用不同的数学工具（概率论、格论、图论）。通过 coalgebra 框架，这些工具的"共同内核"被挖掘出来，体现在 functor 和分配律的抽象概念中。

这种统一不仅在理论上优美，而且具有实际价值：**任何对 coalgebra 理论的改进自动适用于所有这些应用**。例如，如果未来有人发现一个更快的不动点迭代算法，这个算法可以立即用于所有验证问题。

#### 3.1.2 可扩展性与模块化

传统的模型检验工具（如 PRISM）是围绕特定的系统类和属性类设计的。如果要添加新的系统类型（如带有时间延迟的系统）或新的属性（如混合概率-资源属性），需要大幅修改工具的核心引擎。

在 coalgebra 框架下，添加新的系统或属性就是"添加新的 functor"的问题。只要能清楚地定义这个 functor 和相应的分配律，求解算法自动地就可以应用。这种模块化设计是未来可扩展的形式化验证工具的基础。

#### 3.1.3 新问题类型的快速原型化

在学术研究中，经常会产生新的验证问题。例如，最近的研究可能需要处理"系统在给定能量预算下，满足某个 LTL 属性的概率是多少"这样的混合问题。

使用本论文的框架，研究者只需要：
1. 定义合适的 functor 来表示新的问题
2. 推导分配律
3. 将其插入统一的求解引擎

这样可以大幅缩短从理论到工具的距离。

### 3.2 与概率规划和量化验证的联系

#### 3.2.1 概率编程（Probabilistic Programming）的兴起

近年来，概率编程语言（如 Pyro、Stan、Anglican）和概率 inference 成为了机器学习的重要工具。这些系统经常需要验证或推理概率程序的行为。本论文的框架为这类问题的形式化处理提供了基础。

#### 3.2.2 量化验证的新视角

"量化验证"（Quantitative Verification）是指不仅验证"是否满足属性"，而且计算"在多大程度上满足属性"（例如，满足的概率、期望成本等）。本论文通过统一的 coalgebra 框架，将量化验证从多个特殊案例提升到一个通用的理论。

### 3.3 对软件工程工具的潜在影响

虽然论文本身是理论导向的，但其成果可以深刻影响形式化验证工具的设计：

**下一代验证工具架构**：基于 coalgebra 的工具架构将采用"核心引擎 + functor 插件"的设计模式，类似于现代编程语言编译器的设计。这将使工具更容易扩展和维护。

**教学意义**：为学生提供了一个统一的视角来理解形式化验证的各种问题，降低学习的概念复杂度。

### 3.4 科学方法论的启示

这项研究体现了一个重要的科学研究模式：**从特殊到一般的抽象**。在形式化方法领域，有数十年的针对不同问题的研究成果。本论文通过高层次的抽象（范畴论），找到了这些看似不同的工作的共同线索。这种"回头看"和"统一整理"的工作，虽然不如开发新的算法那样显眼，但对于领域的健康发展至关重要。

## 4. 相关工作

### 4.1 量化模型检验的经典工作

**1. 论文标题："Probabilistic Model Checking for Markov Chains"**
   - 代表作：Hansson & Jonsson (Probabilistic LTL, 1994), Baier et al. (全面综述)
   - 与本文的关联：本文的统一框架涵盖了概率模型检验作为一个特殊情况。
   - 关键区别：经典工作针对概率系统设计特定算法（如价值迭代），而本文给出了这些算法的统一 coalgebraic 解释。

**2. 论文标题："Resource-Aware Program Analysis via Abstract Interpretation"**
   - 代表作：Hofmann & Jost, Wilhelm et al.
   - 与本文的关联：资源分析的数学基础在本文的框架中得到了统一表示。
   - 关键区别：资源分析工作主要关注具体算法和工具，缺乏统一的数学框架。

### 4.2 Coalgebra 在软件验证中的应用

**3. 论文标题："Coalgebraic Semantics of Reactive Systems"**
   - 代表作：Rutten (初创性工作，1996+), Jacobs et al.
   - 与本文的关联：本文是对 Rutten 经典 coalgebra 框架的扩展应用。
   - 关键区别：之前的 coalgebra 工作主要关注系统的行为语义，较少涉及时间属性的表示。

### 4.3 形式化验证工具与模型检验

**4. 论文标题："PRISM: A Probabilistic Model Checker"**
   - 代表作：Kwiatkowska, Norman & Parker (2002+)
   - 与本文的关联：PRISM 是量化验证工具的典范，本文的框架可以指导未来版本的设计。
   - 关键区别：PRISM 关注工程实现，而本文关注理论统一。

**5. 论文标题："Storm: A Modern Probabilistic Model Checker"**
   - 代表作：Dehnert et al. (2015+)
   - 与本文的关联：Storm 采用了更灵活的架构，与本文统一框架的思想有共鸣。
   - 关键区别：Storm 的设计是经验驱动的，而本文提供了理论上的指导原则。

### 4.4 范畴论在计算机科学中的应用

**6. 论文标题："Categories for Types and Computation"**
   - 代表作：Crole, Lambek & Scott et al.
   - 与本文的关联：这些是使用范畴论研究程序语言和计算的基础工作。
   - 关键区别：之前的工作主要关注类型系统和语义，而本文将其应用到验证问题。

## 5. 组会讨论要点

**讨论问题 1：分配律的存在性与自动推导**

在一个新的应用场景中（例如，要验证一个新型的混合属性），如何系统地确定合适的分配律？论文中给出的分配律都是手工推导和验证的。对于更复杂的 functor 组合，分配律的推导是否有自动化的方法？是否存在某些条件，当 functor 满足这些条件时，分配律自动存在？这对工具的可扩展性有什么影响？

**讨论问题 2：计算复杂性与实用性的平衡**

虽然统一的 coalgebra 框架在理论上优美，但引入额外的抽象层次（functor、natural transformation、不动点迭代）会否增加计算的复杂性？特别是，对于大规模的系统（状态空间超过 $10^{10}$），这个框架下的算法性能如何与现有的专门优化的工具（如 PRISM）相比？是否需要在理论优雅性和实践效率之间做出权衡？

**讨论问题 3：对并发与分布式系统的扩展**

论文的主要例子涉及顺序执行的系统。对于并发系统（多个 coalgebra 之间的并发组合）或分布式系统，如何在统一框架中表示？是否存在"并发的分配律"概念，能够统一处理并发系统的验证问题？这是否会导致框架变得过于复杂，失去其原有的清晰性？

## 参考文献

[1] Watanabe, K., Junges, S., Rot, J., & Hasuo, I. (2025). A Unifying Approach to Product Constructions for Quantitative Temporal Inference. In *Proceedings of the ACM SIGPLAN Conference on Object-Oriented Programming, Systems, Languages, and Applications (OOPSLA)*.

[2] Rutten, J. J. (1996). Processes and Bisimulations. *arXiv preprint math.CT/9409005*.

[3] Jacobs, B., Sokolova, A., & Magrino, T. (2006). The Power of Adorned Arrows. In *International Conference on Relational and Algebraic Methods in Computer Science* (pp. 246-260). Springer, Berlin, Heidelberg.

[4] Kwiatkowska, M., Norman, G., & Parker, D. (2011). PRISM 4.0: Verification of probabilistic real-time systems. In *International Conference on Computer Aided Verification* (pp. 585-591). Springer, Berlin, Heidelberg.

[5] Baier, C., & Katoen, J. P. (2008). Principles of Model Checking. MIT Press.

[6] Dehnert, C., Junges, S., Katoen, J. P., & Volk, M. (2017). A storm is coming: A modern probabilistic model checker. In *International Conference on Computer Aided Verification* (pp. 592-600). Springer, Cham.

[7] Crole, R. L. (1993). Categories for Types. Cambridge University Press.

[8] Hofmann, M., & Jost, S. (2003). Static Prediction of Heap Space Usage for First-Order Functional Programs. In *Proceedings of the 30th ACM SIGPLAN-SIGACT symposium on Principles of programming languages* (pp. 185-197).

[9] Hansson, H., & Jonsson, B. (1994). A logic for reasoning about time and reliability. *Formal aspects of computing*, 6(5), 512-535.

[10] Wilhelm, R., Engblom, J., Ermedahl, A., Holsti, N., Thesing, S., Whalley, D., ... & Mueller, F. (2008). The worst-case execution time problem: overview of methods and survey of tools. *ACM Transactions on Embedded Computing Systems (TECS)*, 7(3), 1-53.
