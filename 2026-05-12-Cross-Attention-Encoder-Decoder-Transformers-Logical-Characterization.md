# Cross-Attention and Encoder–Decoder Transformers: A Logical Characterization — 调研报告

> 生成日期：2026-05-12 | Reading List Monitor
> 论文来源：https://arxiv.org/abs/2605.07705

## 1. 问题背景与研究动机

Transformer 架构的表达能力（expressiveness）是理论计算机科学与深度学习交叉领域的核心问题之一。近年来，研究者通过形式语言理论和数理逻辑的工具，系统地刻画了不同 Transformer 变体能够识别的语言类别。然而，此前的绝大多数工作仅关注 encoder-only（使用 unmasked self-attention）或 decoder-only（使用 causal masked self-attention）两类架构，而原始 Transformer 论文（Vaswani et al., 2017）提出的 encoder-decoder 架构——其核心的 cross-attention 机制使 decoder 能够关注 encoder 的输出——一直缺乏精确的逻辑刻画。

这一空白具有实际意义：encoder-decoder 架构至今仍被广泛应用于机器翻译（如 NLLB）、图像/视频生成（如 Latent Diffusion Models、Open-Sora）等需要 cross-attention 的场景。本文由 Tampere University 的 Ahvonen、Heiman、Kuusisto、Moreno 和 Selin 五位作者完成，据作者所知，这是首个对 cross-attention 和 encoder-decoder Transformer 给出逻辑刻画的工作。

## 2. 技术方法

本文在 **floating-point 数值精度**和 **soft-attention** 的实际设定下研究 encoder-decoder Transformer 的表达能力，提出了一个三方等价的刻画框架。

**核心逻辑工具：GPTL⁻ 逻辑。** 作者引入了一种新的时序逻辑 GPTL⁻（一种 global-past temporal logic 的变体），它在命题逻辑的基础上增加了两类模态算子：

- **Counting global modality**（⟨G⟩≥k）：作用于 encoder 输入，允许对 encoder 序列中满足某个性质的位置进行计数，对应 cross-attention 的信息汇聚能力。
- **Past modality**（⟨P⟩）：作用于 decoder 输入，允许回溯 decoder 中已生成的历史位置，对应 decoder 的 causal masked self-attention。

**核心自动机模型：CPG-automata。** 作者同时定义了 counting past-global distributed automata（CPG-automata），一种分布式自动机模型，用于作为 Transformer 和逻辑之间的桥梁。

**主要定理（Theorem 6）：** 以下三者具有相同的表达能力：
1. 去掉最终 softmax 层的 floating-point encoder-decoder Transformer
2. GPTL⁻ 逻辑
3. CPG-automata

证明通过三个方向的翻译完成：

- **Logic ⇒ Transformers（Theorem 3）**：将 GPTL⁻ 公式的每个子公式的真值逐一计算——布尔运算由 MLP 层实现，counting global modality ⟨G⟩≥k 通过 cross-attention 层利用 underflow 技巧（来自 Ahvonen et al. 2026 关于 graph transformer 的工作）实现计数，past modality ⟨P⟩ 则通过 decoder 的 masked self-attention 实现。
- **Transformers ⇒ Automata（Theorem 4）**：将 Transformer 的每个子层（self-attention、cross-attention、MLP）编码为 CPG-automata 的一步转移。关键在于 cross-attention 子层可以被 CPG-automata 的 global 组件模拟，而 softmax 归一化的有限精度特性（Proposition 1）保证了这一编码的可行性。
- **Automata ⇒ Logic（Theorem 5）**：利用 type 公式（编码一个点的完整局部信息的公式）将 CPG-automata 的状态转移翻译为 GPTL⁻ 公式。

**Autoregressive 设定（Theorem 7）**：作者进一步讨论了 autoregressive generation 场景——即 Transformer 循环地生成 token 直到输出 EOS。在这一设定中，需要保留最终的 softmax 层，且等价关系需要相对于一个 similarity relation ∼ 来定义（因为 softmax 输出中的微小浮点差异可能导致不同的 argmax 选择）。Theorem 7 表明：对于任意 similarity relation ∼，encoder-decoder Transformer（含 softmax）、GPTL⁻ 和 CPG-automata 三者在 ∼ 下仍具有相同的表达能力。

**架构鲁棒性**：论文在 Appendix B 中证明，其刻画结果对若干架构变体保持成立，包括 multi-head cross-attention（vs. single-head）、不同的 masking 策略、以及 layer normalization 的有无。

## 3. 研究前沿与意义

**Transformer 形式表达能力刻画**是一个近年来快速发展的热门方向：

- Strobl, Merrill 等人在 TACL 2024 发表的综述 "What Formal Languages Can Transformers Express?" 全面梳理了该方向的进展，但明确指出 encoder-decoder 的理论分析相对匮乏——本文正是填补这一空白。
- 同一作者团队（Ahvonen, Heiman, Kuusisto 等）此前已在 graph transformer 领域建立了 PL+GC 逻辑刻画（AAAI 2026），本文的 GPTL⁻ 逻辑正是 PL+GC 向序列 encoder-decoder 架构的自然推广。
- Barceló 等人（ICLR 2024）对 hard attention encoder 给出了基于一阶逻辑 + 数值谓词的刻画；Li & Cotterell 对 fixed-precision decoder-only Transformer 给出了 LTL[◇⁻] 刻画。本文补齐了 encoder-decoder 这一缺失的拼图。

**活跃研究组**：Tampere University（Ahvonen, Kuusisto 等）、Pablo Barceló 团队（PUC Chile）、David Chiang 团队（Notre Dame）、William Merrill（NYU）、Lena Strobl（Oxford/McGill）等。

**常见发表 venue**：ICLR, NeurIPS, ICML, AAAI, TACL, ACL, LICS 等。

## 4. 相关工作

### 4.1 Expressive Power of Graph Transformers via Logic
- **作者**：Ahvonen, Funk, Heiman, Kuusisto, Lutz
- **会议**：AAAI 2026（同时有 arXiv 扩展版 2508.01067）
- **与本文的关联**：这是本文最直接的前序工作，由同一核心团队完成。该文为 floating-point graph transformer 建立了 PL+GC 逻辑刻画。本文的关键技术工具（如利用 underflow 进行计数的 Proposition 2、softmax 有限精度的 Proposition 1）均来自该文。GPTL⁻ 可以理解为 PL+GC 从图结构到序列 encoder-decoder 结构的特化与扩展。
- **关键区别**：前者处理的是图上的单一 Transformer（无 encoder-decoder 分离），而本文需要处理 cross-attention 连接两个不同序列的情况，引入了 past modality 和 global modality 的分离。

### 4.2 Logical Languages Accepted by Transformer Encoders with Hard Attention
- **作者**：Barceló, Kozachinskiy, Lin, Podolskii
- **会议**：ICLR 2024
- **与本文的关联**：该文对 hard attention encoder 建立了基于一阶逻辑 + 一元数值谓词的刻画（UHAT 对应 FO[<, MOD]，AHAT 在此基础上增加 counting terms）。本文选择了不同的技术路线：研究 soft attention + floating-point 设定，并使用时序逻辑而非一阶逻辑作为刻画工具。
- **关键区别**：attention 机制不同（hard vs. soft）、数值模型不同（exact vs. floating-point）、逻辑框架不同（一阶逻辑 vs. 时序逻辑）、架构不同（encoder-only vs. encoder-decoder）。

### 4.3 Logical Characterizations of Recurrent Graph Neural Networks with Reals and Floats
- **作者**：Ahvonen, Heiman, Kuusisto, Lutz
- **会议**：NeurIPS 2024
- **与本文的关联**：同一团队的另一项工作，为 recurrent GNN 建立了逻辑刻画。展示了 floating-point 设定下逻辑刻画的一般方法论，其中的 type 公式技术被本文的 Automata ⇒ Logic 方向证明所使用。
- **关键区别**：处理的是循环图神经网络而非 Transformer。

### 4.4 Characterizing the Expressivity of Fixed-precision Transformer Language Models (Li & Cotterell)
- **与本文的关联**：该文对 fixed-precision decoder-only Transformer 给出了 LTL[◇⁻] 时序逻辑刻画。本文的 GPTL⁻ 逻辑可以看作在 LTL[◇⁻] 的 past modality 基础上，增加了 counting global modality 来捕获 cross-attention 的额外表达能力。
- **关键区别**：前者仅限 decoder-only（无 cross-attention），本文完整刻画了 encoder-decoder 架构。

### 4.5 Tighter Bounds on the Expressivity of Transformer Encoders
- **作者**：Chiang, Cholak, Pillay
- **会议**：ICML 2023
- **与本文的关联**：该文在电路复杂性框架下给出了 encoder 表达能力的更紧界（FOC[+;MOD]）。代表了与逻辑刻画互补的另一条技术路线——电路复杂性方法。
- **关键区别**：方法论不同（电路复杂性 vs. 时序逻辑直接刻画）；架构不同（encoder-only vs. encoder-decoder）。

## 5. 组会讨论要点

1. **GPTL⁻ 的两个模态算子精确对应了架构中的两种 attention 机制**：counting global modality 对应 cross-attention（decoder 对 encoder 的全局查询与计数），past modality 对应 decoder 的 causal self-attention（回顾已生成的历史）。这种"逻辑算子 ↔ 架构组件"的一一对应关系非常优雅，值得讨论：如果我们修改架构（例如增加 encoder 的 self-attention 对应的模态算子），逻辑刻画会如何变化？这是否能指导新架构的设计？

2. **与 CPS 形式化验证的联系**：本文的刻画结果表明 encoder-decoder Transformer（在 fixed-depth、floating-point 设定下）的表达能力被 GPTL⁻ 精确界定——这是一个可判定的逻辑。这意味着对于使用 encoder-decoder 架构的 learning-enabled 组件，至少在原则上可以对其输入-输出行为进行形式化推理。对于我们组关注的 perception-based safety（如 VISION-SLS、GUARDIAN 等工作），如果感知模块使用 encoder-decoder 架构，那么了解其表达能力边界对于设计 sound 的 safety filter 至关重要。

3. **Autoregressive 设定中的 similarity relation**：Theorem 7 中引入的 ∼ 关系是一个有趣的理论工具。在实际系统中，softmax 输出的微小差异可能导致完全不同的 token 选择（argmax 的不稳定性），这与 CPS 中对 numerical robustness 的关注一脉相承。论文的局限性部分也提到了未考虑 positional encoding（如 RoPE）的影响——这可能影响实际系统中刻画的适用性，值得进一步探讨。

## 参考文献

1. Ahvonen, V., Funk, M., Heiman, D., Kuusisto, A., & Lutz, C. (2026). Expressive Power of Graph Transformers via Logic. *AAAI 2026*, pp. 19569–19579. https://arxiv.org/abs/2508.01067

2. Ahvonen, V., Heiman, D., Kuusisto, A., & Lutz, C. (2024). Logical Characterizations of Recurrent Graph Neural Networks with Reals and Floats. *NeurIPS 2024*, pp. 104205–104249.

3. Barceló, P., Kozachinskiy, A., Lin, A. W., & Podolskii, V. (2024). Logical Languages Accepted by Transformer Encoders with Hard Attention. *ICLR 2024*, pp. 22077–22087.

4. Chiang, D., Cholak, P., & Pillay, A. (2023). Tighter Bounds on the Expressivity of Transformer Encoders. *ICML 2023*.

5. Strobl, L., Merrill, W., Weiss, G., Chiang, D., & Angluin, D. (2024). What Formal Languages Can Transformers Express? A Survey. *TACL*, 12, 543–561. https://direct.mit.edu/tacl/article/doi/10.1162/tacl_a_00663

6. Vaswani, A. et al. (2017). Attention Is All You Need. *NeurIPS 2017*.

7. Li, A. & Cotterell, R. Characterizing the Expressivity of Fixed-precision Transformer Language Models.

8. Yang, A., Chiang, D., & Angluin, D. (2024). Masked Hard-Attention Transformers Recognize Exactly the Star-Free Languages. https://arxiv.org/abs/2310.13897
