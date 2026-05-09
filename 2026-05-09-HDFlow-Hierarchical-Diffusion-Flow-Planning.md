# HDFlow: Hierarchical Diffusion-Flow Planning for Long-horizon Robotic Assembly — 调研报告

> 生成日期：2026-05-09 | Reading List Monitor
> 论文来源：[OpenReview (ICLR 2026 submission)](https://openreview.net/forum?id=nokbt6AbcM)
> 作者：Gireesh Nandiraju, Yuanliang Ju, Chaoyi Xu, Weiheng Liu, Yuxuan Wan, He Wang
> 项目主页：https://hdflow-page.github.io/

## 1. 问题背景与研究动机

Long-horizon manipulation（长时域操作任务）是机器人领域的核心挑战之一，要求系统同时具备高层策略推理能力和底层精确控制能力。典型场景如家具组装，需要机器人按正确顺序完成数十个接触丰富的子任务。

近年来，生成式模型（特别是 diffusion model）在机器人规划中展现了巨大潜力，但存在两个关键瓶颈：(1) 缺乏层次化分解的原则性框架——单一模型难以同时处理高层探索和底层精细执行；(2) 迭代去噪过程的计算开销大，难以满足实时执行需求。

HDFlow 的核心创新在于提出了一种 **混合架构**：用 diffusion model 做高层规划（擅长探索），用 rectified flow model 做底层轨迹生成（速度快、轨迹平滑）。这种分工利用了两类生成模型各自的优势。

## 2. 技术方法

HDFlow 的架构分为两层：

- **高层 diffusion planner**：在学习到的 latent space 中生成一系列战略性 subgoal。Diffusion model 的多步去噪过程天然适合高层探索——通过随机性实现多样化的子目标序列。
- **底层 rectified flow planner**：以高层生成的 subgoal 为条件，生成稠密、平滑的执行轨迹。Rectified flow 基于 ODE 求解，只需少量步数即可生成高质量轨迹，显著快于 diffusion 的多步去噪。

关键技术特点包括：

- Latent space 的使用使得高层规划在紧凑的表示空间中进行，降低了计算复杂度。
- 两层之间通过 subgoal conditioning 连接，低层 flow planner 可以高效地在子目标之间插值生成轨迹。
- 在四个具有挑战性的家具组装任务上进行了评估，HDFlow 显著优于现有 state-of-the-art 方法。

## 3. 研究前沿与意义

Diffusion model 在机器人规划中的应用是 2023-2026 年最活跃的研究方向之一：

- **Diffusion Policy**（Chi et al., 2023/2025）开创性地将 diffusion model 用于 visuomotor policy learning，已成为该领域的基础工作。
- **Rectified flow** 作为 diffusion 的高效替代受到越来越多关注，如 RecFlow Policy 将 rectified flow 用于加速动作生成。
- 层次化规划与生成模型的结合是当前的前沿趋势，如 Simple Hierarchical Planning with Diffusion、CHD: Coupled Hierarchical Diffusion 等。

主要研究组包括 Columbia University (Shuran Song 组)、UC Berkeley (Pieter Abbeel 组)、Peking University (He Wang 组) 等。

常见发表 venue：ICLR, NeurIPS, CoRL, RSS, ICRA, IROS。

## 4. 相关工作

1. **Diffusion Policy: Visuomotor Policy Learning via Action Diffusion** (Chi et al., 2023, IJRR 2025)
   - 将 diffusion model 引入机器人 visuomotor policy learning 的开创性工作。
   - 与 HDFlow 的区别：Diffusion Policy 是单层架构，不区分高层/底层；HDFlow 通过层次化设计解决了单一 diffusion model 在长时域任务上的局限性。

2. **RecFlow Policy: Fast and Accurate Visuomotor Policy Learning via Rectified Action Flow** (OpenReview)
   - 用 rectified flow 替代 diffusion 来加速动作生成。
   - 与 HDFlow 的关联：HDFlow 的底层 planner 也采用 rectified flow，但 RecFlow 是单层架构，而 HDFlow 在高层保留了 diffusion 的探索能力。

3. **Simple Hierarchical Planning with Diffusion** (Du et al., 2024, arXiv:2401.02644)
   - 探索层次化 diffusion 规划的早期工作。
   - 关键区别：HDFlow 明确将 diffusion 和 flow 分配到不同层级，而非在两层都使用 diffusion。

4. **CHD: Coupled Hierarchical Diffusion for Long-Horizon Tasks** (arXiv:2505.07261)
   - 另一个针对长时域任务的层次化 diffusion 方法。
   - 与 HDFlow 互补：CHD 探索两层 diffusion 的耦合训练，HDFlow 则通过异构生成模型实现效率与效果的平衡。

5. **DiffuserLite: Towards Real-time Diffusion Planning** (NeurIPS 2024)
   - 关注 diffusion planning 的实时性问题。
   - 与 HDFlow 的联系：两者都试图解决 diffusion 在实时应用中的速度瓶颈，但策略不同——DiffuserLite 优化单一 diffusion 模型，HDFlow 用 flow model 替代底层。

## 5. 组会讨论要点

1. **Diffusion vs. Flow 的分工是否最优？** 作者将 diffusion 放在高层、flow 放在底层的设计选择背后的直觉是 diffusion 擅长探索而 flow 速度快。但反过来是否也有道理？Flow model 在高层是否会因为确定性过强而缺乏探索？

2. **Latent space 的质量对系统性能的影响**：高层 planner 在 latent space 中生成 subgoal，这意味着 latent space 的表达能力直接决定了规划质量。在实际部署中，如何保证 latent space 能有效编码任务相关的关键信息？

3. **与 CPS 安全性的结合**：长时域规划中的安全约束如何融入 HDFlow 框架？能否在高层 subgoal 生成时加入 safety constraint（如 CBF），同时在底层 flow planner 中保证轨迹的物理可行性？

## 参考文献

- Nandiraju, G., Ju, Y., Xu, C., Liu, W., Wan, Y., & Wang, H. (2025). HDFlow: Hierarchical Diffusion-Flow Planning for Long-horizon Robotic Assembly. Submitted to ICLR 2026. https://openreview.net/forum?id=nokbt6AbcM
- Chi, C., et al. (2023/2025). Diffusion Policy: Visuomotor Policy Learning via Action Diffusion. IJRR. https://diffusion-policy.cs.columbia.edu/
- Du, Y., et al. (2024). Simple Hierarchical Planning with Diffusion. arXiv:2401.02644. https://arxiv.org/abs/2401.02644
- (2025). CHD: Coupled Hierarchical Diffusion for Long-Horizon Tasks. arXiv:2505.07261. https://arxiv.org/abs/2505.07261
- (2024). DiffuserLite: Towards Real-time Diffusion Planning. NeurIPS 2024. https://proceedings.neurips.cc/paper_files/paper/2024/file/dd6a47bc0aad6f34aa5e77706d90cdc4-Paper-Conference.pdf
