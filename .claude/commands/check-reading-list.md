# Reading List Monitor — Claude Code Custom Command

你是一个自动化的论文 Reading List 监控器。你的任务是：检查导师在 Overleaf 上的 Reading List 是否有新论文，为每篇新论文生成一份中文调研报告，然后 git push 到 GitHub，最后生成一条微信群通知消息。

## 配置信息

- **Overleaf 项目**：从 `config.local.json` 的 `overleaf_project_url` 字段读取
- **本地 Git 仓库**：`/Users/wangshuqi/helloworld/Reading_List`
- **GitHub 远程仓库**：`https://github.com/Yangming911/CPS_ReadingList_Extension`
- **状态文件**：`/Users/wangshuqi/helloworld/Reading_List/reading-list-state.json`
- **解析脚本**：`/Users/wangshuqi/helloworld/Reading_List/scripts/parse_reading_list.py`

## 执行流程

### Step 1: 从 Overleaf 提取论文列表

使用 Overleaf 的 git 接口拉取最新的 LaTeX 源码：

```bash
# 从 config.local.json 读取 Overleaf git URL
OVERLEAF_GIT_URL=$(python3 -c "import json; print(json.load(open('config.local.json'))['overleaf_git_url'])")

# 如果 overleaf-source 目录不存在，先 clone
if [ ! -d /tmp/overleaf-reading-list ]; then
    git clone "$OVERLEAF_GIT_URL" /tmp/overleaf-reading-list
else
    cd /tmp/overleaf-reading-list && git pull
fi
```

> **注意**：如果 git clone 失败（Overleaf git 需要认证），请改用以下备选方案：
> 1. 用 `curl` 配合用户的浏览器 cookie 获取页面内容
> 2. 或者直接打开 Chrome 浏览器手动获取页面文本
> 3. 将获取的文本保存到 `/tmp/overleaf-raw.txt`

找到 LaTeX 主文件（通常是 `main.tex`），读取其中 `\begin{enumerate}` 到 `\end{enumerate}` 之间的内容。

### Step 2: 解析论文列表

使用解析脚本提取论文标题：

```bash
cd /Users/wangshuqi/helloworld/Reading_List
python3 scripts/parse_reading_list.py \
    --input /tmp/overleaf-reading-list/main.tex \
    --output /tmp/parsed-papers.json \
    --state reading-list-state.json \
    --compare
```

如果没有找到 main.tex，也可以把原始页面文本传给脚本：

```bash
python3 scripts/parse_reading_list.py \
    --input /tmp/overleaf-raw.txt \
    --output /tmp/parsed-papers.json \
    --state reading-list-state.json \
    --compare
```

读取 `/tmp/parsed-papers.json`，查看 `new_papers` 列表。

- 如果 `new_count` 为 0，报告"没有新论文"并结束。
- 如果是首次运行（`is_first_run: true`），建立 baseline，不生成报告。
- 否则，对每篇新论文执行 Step 3。

### Step 3: 为每篇新论文生成调研报告

对 `new_papers` 中的每篇论文：

#### 3.1 调研阶段

1. **搜索论文**：用 web search 搜索 `"<论文标题>" arxiv` 或 `"<论文标题>" PDF`
2. **找到原文**：定位 arxiv 链接、会议论文页、或作者主页
3. **阅读摘要**：从论文着陆页获取 abstract 和关键细节
4. **搜索相关工作**：找 3-5 篇密切相关的论文
5. **评估研究版图**：这是否是热门方向？哪些 venue 发表这类工作？

#### 3.2 撰写报告

**语言要求：报告正文使用中文撰写，学术专有名词保留英文原文。**

报告结构如下：

```markdown
# [论文英文原标题] — 调研报告

> 生成日期：YYYY-MM-DD | Reading List Monitor
> 论文来源：[arxiv/会议链接（如有）]

## 1. 问题背景与研究动机

这篇论文解决的是什么问题？为什么这个问题重要？
现有方法的不足之处在哪里？本文的核心贡献是什么？
（假设读者具备 CPS/控制/形式化方法方向的研究生水平背景知识。）

## 2. 技术方法

简要描述论文提出的方法论。使用了哪些关键技术？
核心算法或框架是什么？有哪些重要的理论保证？

## 3. 研究前沿与意义

这是一个热门的研究方向吗？有哪些证据？
主要的竞争方法有哪些？哪些研究组在这个领域比较活跃？
常见的发表 venue 有哪些？

## 4. 相关工作

列出并简要介绍 3-5 篇密切相关的论文。每篇需说明：
- 论文标题与作者
- 与本文的关联
- 关键区别

## 5. 组会讨论要点

2-3 个适合在研究组会上讨论的问题或角度。

## 参考文献

所有提及论文的完整引用格式，尽量附上链接。
```

基调：**学术严谨**，面向研究组内部调研综述。避免空泛的夸赞，用具体的技术细节说明创新点。篇幅 1500-2500 字。

#### 3.3 保存报告

保存到本地仓库：
```
/Users/wangshuqi/helloworld/Reading_List/YYYY-MM-DD-<sanitized-short-title>.md
```
例如：`2026-04-05-Can-LLMs-Perform-Synthesis.md`

### Step 4: 更新状态文件

更新 `reading-list-state.json`：
- 设置 `last_checked` 为当前时间戳
- 将所有新检测到的论文添加到 `known_papers`

### Step 5: Git Commit 和 Push

```bash
cd /Users/wangshuqi/helloworld/Reading_List
git pull --rebase
git add *.md reading-list-state.json
git commit -m "Add research report(s) for YYYY-MM-DD: [简要论文标题]"
git push
```

如果 push 失败，打印错误信息并提示用户检查 SSH 配置。

### Step 6: 生成微信群通知

生成一条活泼有趣的微信通知消息，用于用户粘贴到群聊中。格式要求：
- 随性、有趣、不拘一格（这是给研究组群聊的，不是正式公告）
- 简要提及新论文的主题，引起大家兴趣
- 附上 GitHub 报告链接：`https://github.com/Yangming911/CPS_ReadingList_Extension`
- 每次风格要有变化，不要用同一个模板

示例风格（但每次请创作全新的）：
- "Reading List 更新啦! 导师新加了一篇关于 [topic] 的论文，快来看看调研报告~ [link]"
- "叮咚~ 新论文上架！这次是关于 [topic]，感兴趣的同学速看 [link]"

**最后，把微信消息打印到终端，方便用户直接复制。**

## 错误处理

- **Overleaf 不可访问**：提示用户检查网络和登录状态
- **没有新论文**：正常，报告"自上次检查以来没有新论文"
- **Git push 失败**：报告已保存在本地仓库，提示用户手动 push
- **论文在线未找到**：根据标题尽可能撰写报告，注明"全文未找到"
