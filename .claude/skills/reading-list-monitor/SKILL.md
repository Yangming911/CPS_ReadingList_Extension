---
name: reading-list-monitor
description: >
  Automatically monitor a supervisor's reading list on Overleaf (SJTU LaTeX) for newly added papers,
  then generate academic research reports for each new paper and push them to GitHub. Use this skill
  whenever the user mentions: reading list updates, paper monitoring, literature survey generation,
  new paper reports, Overleaf reading list, or wants to check if their advisor added new papers.
  Also trigger when the user says things like "check my reading list", "any new papers?",
  "generate reports for new papers", "run the reading list monitor", or "push paper reports to GitHub".
---

# Reading List Monitor

This skill monitors a LaTeX-formatted reading list hosted on SJTU Overleaf, detects newly added papers, and generates academic research reports for each new entry. Reports are pushed to a public GitHub repository, and a ready-to-paste WeChat notification message is generated.

## Overview

The reading list lives on SJTU Overleaf. The URL is stored locally in `config.local.json` (field: `overleaf_project_url`). Read this file at runtime to get the actual URL.

It is a LaTeX document using `\begin{enumerate}` with `\item` entries. New papers are always added at the **top** of the list (earliest `\item` entries = newest papers). The skill needs to:

1. Open the Overleaf page in Chrome and extract the paper list
2. Compare against the previously known state to find new entries
3. For each new paper, research it and write an academic report
4. Push reports to `https://github.com/Yangming911/CPS_ReadingList_Extension`
5. Generate a WeChat notification message the user can copy-paste

## Local Repository Path

All generated reports and the state file are stored in the local Git repository:

```
/Users/wangshuqi/helloworld/Reading_List
```

This directory is a git clone of `https://github.com/Yangming911/CPS_ReadingList_Extension`. Reports are saved here and pushed to GitHub via `git push`.

## Prerequisites

Before first use, ensure the following are set up:

### Chrome Login
The user must be logged into SJTU Overleaf in Chrome:
1. The Overleaf host (see `config.local.json`) — for accessing the reading list project

**⚠️ Overleaf 只读原则：访问 Overleaf 页面时仅允许读取页面文本，严禁任何点击、输入、编辑、删除操作。这是导师的文档，任何误操作都可能造成不可挽回的后果。**

### Git Repository
The local repo at `/Users/wangshuqi/helloworld/Reading_List` must be:
1. A valid git clone of `https://github.com/Yangming911/CPS_ReadingList_Extension`
2. Have git push access configured (SSH key or credential helper)
3. Be on the correct branch (typically `main`)

### State File
The skill maintains a state file at `/Users/wangshuqi/helloworld/Reading_List/reading-list-state.json` to track which papers have been seen. On first run, all current papers are recorded as "seen" (no reports generated), establishing a baseline. This state file is also committed to the repo.

## Step-by-Step Execution

### Step 1: Extract the Current Paper List from Overleaf

**⚠️ CRITICAL: READ-ONLY ACCESS — The Overleaf page must be treated as strictly read-only. Under NO circumstances should this skill click, type, edit, delete, or modify anything on the Overleaf page. The ONLY permitted actions are: navigating to the page, waiting for it to load, and extracting text via `get_page_text`. Do NOT click into the editor, do NOT use `form_input`, do NOT use `javascript_tool` to modify DOM content, and do NOT interact with any buttons or menus on the page.**

Use Chrome browser automation to access the Overleaf project:

1. Read the Overleaf URL from `config.local.json` (field: `overleaf_project_url`), then navigate to it
2. Wait for the editor to load (look for the source code editor content)
3. Extract the page text using `get_page_text` (READ-ONLY — do not interact with the page in any other way)
4. Parse the LaTeX source to extract paper titles from `\item` entries

The parsing logic should:
- Find all text between `\begin{enumerate}` and `\end{enumerate}`
- Extract each `\item` entry's title text
- Handle multi-line titles (some titles span multiple lines before the next `\item`)
- Ignore any commentary or notes after the title (like the "XY: Diffusion LLM??? anyone wants to tell me what is it ???reference:..." note — keep only the primary title before any "?" commentary or "reference:" markers, but use judgment since some paper titles legitimately contain "?")
- Preserve the order (first item = newest paper)

Use the Python script at `scripts/parse_reading_list.py` to do the parsing:

```bash
python3 scripts/parse_reading_list.py --input <raw_text_file> --output <parsed_json>
```

### Step 2: Compare Against Known State

Read the state file `/Users/wangshuqi/helloworld/Reading_List/reading-list-state.json`. Its structure:

```json
{
  "last_checked": "2026-04-04T10:00:00",
  "known_papers": [
    "Can LLMs Perform Synthesis?",
    "Constrained and Robust Policy Synthesis with ..."
  ]
}
```

Compare the current list against `known_papers`:
- Any paper title in the current list that is NOT in `known_papers` is considered **new**
- Since new papers appear at the top, the new ones will be the first N entries that aren't in the known list
- If this is the first run (no state file exists), create the state file with all current papers and report "Baseline established — no new papers to report this time"

### Step 3: Generate Research Reports

For **each** new paper, generate an independent academic research report. This is the core value of the skill, so invest real effort here.

#### Research Phase
For each new paper title:
1. **Search the web** for the paper using queries like:
   - `"<paper title>" arxiv`
   - `"<paper title>" PDF`
   - `<paper title> <key terms>`
2. **Find the actual paper** — look for arxiv links, conference proceedings, or author pages
3. **Read the abstract and key details** from the paper's landing page
4. **Search for related work** — find 3-5 closely related papers in the same area
5. **Assess the research landscape** — is this a hot topic? What conferences/venues publish in this area?

#### Report Writing

**语言要求：报告正文使用中文撰写，学术专有名词（如 barrier certificate、reachability analysis、signal temporal logic 等）保留英文原文。** 这样既保证了组内同学阅读的流畅性，又避免了术语翻译造成的歧义。

Write each report in Markdown with this structure:

```markdown
# [论文英文原标题] — 调研报告

> 生成日期：YYYY-MM-DD | Reading List Monitor
> 论文来源：[arxiv/会议链接（如有）]

## 1. 问题背景与研究动机

这篇论文解决的是什么问题？为什么这个问题重要？
现有方法的不足之处在哪里？本文的核心贡献是什么？
（假设读者具备 CPS/控制/形式化方法方向的研究生水平背景知识，但可能不熟悉这个具体子领域。）

## 2. 技术方法

简要描述论文提出的方法论。使用了哪些关键技术？
（例如：基于优化的方法、learning-based 方法、formal verification、model checking 等）
核心算法或框架是什么？有哪些重要的理论保证？

## 3. 研究前沿与意义

这是一个热门的研究方向吗？有哪些证据？（近年发表量、相关 workshop、竞赛等）
主要的竞争方法有哪些？哪些研究组在这个领域比较活跃？
常见的发表 venue 有哪些（会议/期刊）？

## 4. 相关工作

列出并简要介绍 3-5 篇密切相关的论文。每篇需说明：
- 论文标题与作者（如能找到）
- 与本文的关联：解决的是类似问题还是互补的问题？
- 关键区别：方法、假设、适用范围上有何不同？

## 5. 组会讨论要点

2-3 个适合在研究组会上讨论的问题或角度：
- 本文有哪些局限性或开放问题？
- 与我们组现有的研究方向有什么潜在联系？
- 有哪些值得尝试的后续实验或扩展方向？

## 参考文献

所有提及论文的完整引用格式，尽量附上链接。
```

基调应当**学术严谨**——这是面向研究组的调研综述，不是科普博客。使用精确的技术术语，引用具体方法，提供有深度的分析而非泛泛而谈。避免空泛的夸赞（如"开创性的""突破性的"），取而代之用具体的技术细节说明创新点。

#### File Naming
Save each report to the local repo directory: `/Users/wangshuqi/helloworld/Reading_List/YYYY-MM-DD-<sanitized-short-title>.md`

For example: `/Users/wangshuqi/helloworld/Reading_List/2026-04-04-Can-LLMs-Perform-Synthesis.md`

### Step 4: Generate Self-Deleting Push Script

Cowork sandbox 无法直接执行 `git push`（挂载文件系统不支持 `.git/index.lock` 删除，且 sandbox 没有用户 SSH 密钥）。因此，**生成一个自删除的 shell 脚本**写入本地仓库，用户只需在终端执行一行命令即可完成 push。

将以下脚本保存到 `/Users/wangshuqi/helloworld/Reading_List/push-reports.sh`：

```bash
#!/bin/bash
set -e
cd /Users/wangshuqi/helloworld/Reading_List
rm -f .git/index.lock
git add -A
git commit -m "Add research report(s) for YYYY-MM-DD: [简要论文标题]"
git push
echo "Push 完成!"
rm -f push-reports.sh
```

其中 commit message 的日期和标题替换为实际值。脚本要点：
- `rm -f .git/index.lock` 清理可能残留的锁文件
- `git add -A` 暂存所有变更（报告、state.json、.gitignore 等）
- `set -e` 确保任何步骤失败时立即停止
- 最后一行 `rm -f push-reports.sh` 让脚本执行完后自行删除

**重要：不要尝试在 sandbox 中执行 git 命令。** 只需生成脚本文件，用户执行。

### Step 5: Generate WeChat Notification

Create a fun, attention-grabbing message for the user to paste into their WeChat group. The message should:
- Be casual and energetic (this is for a group chat, not a formal announcement)
- Mention what the new paper(s) are about in an intriguing way
- **为每篇论文单独附上其 GitHub 上 MD 文件的直接链接**（不要只放 repo 链接）
- Vary the style — don't use the same template every time

#### 构造每篇报告的 GitHub 链接

每篇报告的链接可以根据文件名**提前预测**（即使尚未 push）。格式为：

```
https://github.com/Yangming911/CPS_ReadingList_Extension/blob/master/<filename>.md
```

例如，文件名 `2026-04-05-Closed-Form-CLF-CBF-Soft-Robot.md` 对应链接：
`https://github.com/Yangming911/CPS_ReadingList_Extension/blob/master/2026-04-05-Closed-Form-CLF-CBF-Soft-Robot.md`

这意味着在 Step 3 完成文件命名后，就可以立即构造出链接，无需等待 push 完成。

#### 消息风格示例

（每次请创作全新的，不要复用模板）
- "Reading List 更新啦！导师新加了两篇论文：\n1. 关于 [topic1] → [link1]\n2. 关于 [topic2] → [link2]\n调研报告已出，快来看~"
- "叮咚~ 新论文上架！\n· [简述1] [link1]\n· [简述2] [link2]\n欢迎讨论~"

### Step 6: Update State

After successful processing, update `/Users/wangshuqi/helloworld/Reading_List/reading-list-state.json`:
- Set `last_checked` to the current timestamp
- Add all newly detected papers to `known_papers`
- This file is included in the git commit (Step 4), so it's also tracked on GitHub

### Step 7: Final Output — 一次性汇报给用户

完成 Step 1-6 后（即报告已生成、state 已更新、push 脚本已写入），在**对话中一次性**向用户呈现以下三项内容。这是整个 skill 执行的最终输出，格式必须清晰、可直接操作：

#### 7.1 Push 命令（一行）

给出用户需要在终端执行的单行命令：

```
bash /Users/wangshuqi/helloworld/Reading_List/push-reports.sh
```

#### 7.2 微信群通知消息（可直接复制粘贴）

包含每篇报告的独立 GitHub 链接。链接根据文件名预测构造（格式见 Step 5），**无需等待 push 完成**。例如：

> Reading List 双更！导师新加的两篇论文调研报告已出炉：
> 1. CLF-CBF 软体机器人碰撞回避 → https://github.com/Yangming911/CPS_ReadingList_Extension/blob/master/2026-04-05-Closed-Form-CLF-CBF-Soft-Robot.md
> 2. 隐私保护分布式监控 → https://github.com/Yangming911/CPS_ReadingList_Extension/blob/master/2026-04-05-Distributed-Privacy-Preserving-Monitoring.md
> 感兴趣的同学快来看~

#### 7.3 本次执行摘要

简要说明：
- 检测到几篇新论文
- 生成了哪些报告文件
- state.json 是否已更新

**这三项内容必须在同一条对话消息中完整呈现，让用户一眼看到所有需要的信息。** 用户复制粘贴微信消息后，在终端执行一行命令即可完成全部流程——无需来回对话。

## Error Handling

- **Overleaf not accessible**: Check if Chrome is logged in. Suggest the user open the Overleaf page manually and log in.
- **No new papers**: Report "No new papers detected since last check on [date]." — this is normal and expected most days.
- **Git push fails**: Check if SSH keys or credentials are configured. Save reports locally first — they're already in the repo directory and can be pushed manually later.
- **Paper not found online**: Write what you can based on the title and note that the full paper was not found. Suggest the user check if it's a preprint or internal document.

## Scheduling

This skill is designed to be run daily. It can be set up as a scheduled task:
```
Schedule: Every day at 9:00 AM (0 9 * * *)
```
The user can also trigger it manually at any time by saying "check my reading list" or similar.
