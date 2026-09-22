# Skillcraft

面向 Codex 的个人技能库（Skills Repository）。收录日常开发、技术汇报与深度工程文档撰写中高频使用的专业能力与工作流，所有技能均采用直观、通用的单单词（如 `ppt`、`code`、`word`）进行命名与分发。

## 仓库架构

```text
skillcraft/
├── README.md                  # 仓库总览、架构说明与使用文档
├── AGENTS.md                  # 仓库开发与协作守则（杜绝 AI 感与需求复述）
├── .gitignore                 # 忽略临时文件与构建产物
├── scripts/                   # 自动化运维与质检脚本
│   ├── install.sh             # 一键安装或符号链接至 ~/.codex/skills
│   └── validate.sh            # 技能格式与 frontmatter 静态校验脚本
└── skills/                    # 核心技能目录（单单词规范）
    ├── ppt/                   # PPT 汇报生成与审查技能
    │   ├── SKILL.md           # 核心指令、叙事结构与交付检查
    │   ├── README.md          # 技能详细说明
    │   ├── agents/
    │   │   └── openai.yaml    # Codex 界面元数据与调用策略
    │   └── references/
    │       └── styleguide.md  # 视觉系统、版式与样式规范
    ├── code/                  # 代码编写与架构工程规范技能
    │   ├── SKILL.md           # 核心执行流与决策树
    │   ├── README.md          # 技能详细说明
    │   ├── agents/
    │   │   └── openai.yaml    # Codex 界面元数据与调用策略
    │   └── references/
    │       └── guide.md       # 详细工程准则与工作流
    └── word/                  # 通用技术文档与工程规范撰写技能
        ├── SKILL.md           # 通用文字手法、闭环准则、去AI感与排版规范
        ├── README.md          # 技能详细说明
        ├── agents/
        │   └── openai.yaml    # Codex 界面元数据与调用策略
        └── references/
            ├── guide.md       # 深度撰写指南（全文档适用准则与六要素闭环）
            └── math_omml.md   # Word 公式生成与排版避坑实战手册
```

## 收录技能

| 技能名称 | 目录 | 定位与核心能力 | 触发提示词 |
|---|---|---|---|
| `ppt` | `skills/ppt` | 隐私优先的克制蓝色技术与学术汇报 PPT，负责叙事规划、信息密度与交付审查 | `$ppt` |
| `code` | `skills/code` | 极简链路、静态优先、前后端契约严谨的代码编写与工程架构规范 | `$code` |
| `word` | `skills/word` | 通用技术文档与工程规范撰写，手法与注意事项适用于所有文档类工作（设计文档、方案规范、白皮书、Markdown、Word、PDF 等全载体） | `$word` |

---

## 快速开始

### 1. 安装到 Codex

使用内置的安装脚本将技能分发至 Codex 本地技能目录（`~/.codex/skills`）：

```bash
# 开发模式（推荐：创建软链接，本地修改实时生效）
./scripts/install.sh --link

# 复制模式（独立拷贝）
./scripts/install.sh
```

也可以按需安装单个技能：

```bash
# 仅安装 word
./scripts/install.sh --link word

# 仅安装 ppt
./scripts/install.sh --link ppt

# 仅安装 code
./scripts/install.sh --link code
```

安装完成后，在 Codex 中新建会话或打开新轮次即可直接调用生效。

### 2. 本地格式校验

提交或修改技能后，运行验证脚本确保所有技能均符合规范：

```bash
./scripts/validate.sh
```

---

## 技能使用

### Word (通用技术文档与工程规范撰写)

面向所有文档类工作（系统架构方案、工程技术规范、算法解析、接口文档、技术白皮书、Wiki 及 Word/Markdown/PDF 排版）。

- **核心特色**：文字叙述手法与注意事项普适于所有文档类工作。严格落实六要素逻辑闭环（输入 $\to$ 处理 $\to$ 公式 $\to$ 判定 $\to$ 输出 $\to$ 异常分支）、公式参数**在正下方即刻逐一解释**、区分已实现与待确认三层技术边界、真实可计算数值实施例，并在涉及 Word/PDF 排版时基于 OMML 原生矢量公式彻底杜绝方框乱码。

```text
使用 $word 按照通用技术文档规范，将当前核心算法整理为一份高严谨度、高可读性的工程设计文档。
```

```text
使用 $word 重构技术文档，补充公式推导、逐一解释参数含义并消除所有 AI 套话与机械复述。
```

### PPT (演示文稿汇报)

适用于学术汇报、技术复盘、研究进展和管理简报。通常与 Codex 内置的底层 `pptx` 工具协同工作。

```text
使用 $ppt 将这份材料整理成简洁、成熟、内容充实且默认匿名化的中文汇报 PPT。
```

```text
使用 $ppt 修改 progress.pptx。把背景压缩为一页，重点呈现当前阶段进展、两个核心技术难点与后续排期；所有涉密身份信息按默认规则匿名化。
```

### Code (代码工程规范)

将实战中沉淀的工程品味内化为协作准则，支持显式调用与隐式工程遵循。

```text
使用 $code 设计并实现一个静态工具的前端界面，要求纯原生 JS 驱动、最小链路。
```

```text
使用 $code 审查当前项目架构，检查前后端契约、配置收敛性与测试用例完备性。
```

---

## 技能开发与扩展规范

添加新技能到 `skillcraft` 时，请遵循以下约定：

1. **命名规范**：目录名与技能名务必保持一致，统一使用**单个直观英文单词**（如 `ppt`、`code`、`word`）或**无连字符的连续单词**（如 `styleguide`），严禁使用 `-` 连字符。
2. **必备文件**：每个技能目录必须包含完整的 `SKILL.md`，包含合法的 YAML frontmatter（`name` 与 `description`）。
3. **去 AI 感铁律**：无论在正文、提示词、代码注释还是系统指令中，**彻底杜绝 AI 感、机械八股与需求复述**。
4. **渐进披露**：通用流程与核心规则置于 `SKILL.md`，深度手册与可复用资源放入 `references/`，按需加载。
5. **运行验证**：新增或修改后必须执行 `./scripts/validate.sh` 确保校验通过。
