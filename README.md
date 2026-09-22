# Skillcraft

面向 Codex 的个人技能库（Skills Repository）。收录日常开发、技术汇报、深度文档撰写与标准工程排版中高频使用的专业能力与工作流，所有技能均采用直观、通用的单单词（如 `ppt`、`code`、`write`、`word`）进行命名与分发。

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
    ├── write/                 # 通用技术文档纯文字撰写技能
    │   ├── SKILL.md           # 专业口吻、叙事手法与工程逻辑闭环
    │   ├── README.md          # 技能详细说明
    │   ├── agents/
    │   │   └── openai.yaml    # Codex 界面元数据与调用策略
    │   └── references/
    │       └── guide.md       # 纯文字撰写全书（因果推导、去 AI 感与注意事项）
    └── word/                  # Word (DOCX) 专业排版与格式规范技能
        ├── SKILL.md           # 标准工程报告排版格式系统与自检清单
        ├── README.md          # 技能详细说明
        ├── agents/
        │   └── openai.yaml    # Codex 界面元数据与调用策略
        └── references/
            ├── guide.md       # Word 标准工程报告排版规范指南
            └── math_omml.md   # Word 原生公式 (OMML) 排版避坑实战手册
```

## 收录技能

| 技能名称 | 目录 | 定位与核心能力 | 触发提示词 |
|---|---|---|---|
| `ppt` | `skills/ppt` | 隐私优先的克制蓝色技术与学术汇报 PPT，负责叙事规划、信息密度与交付审查 | `$ppt` |
| `code` | `skills/code` | 极简链路、静态优先、前后端契约严谨的代码编写与工程架构规范 | `$code` |
| `write` | `skills/write` | 通用技术文档纯文字撰写，专注于专业口吻、权衡驱动叙事、因果递进逻辑与核心注意事项（适用 Markdown、Wiki、RFC、方案白皮书等全文本场景） | `$write` |
| `word` | `skills/word` | Word (DOCX) 专业排版格式系统与矢量公式排版。**所有 Word 文档若无特殊要求默认强制采用标准工程报告排版格式** | `$word` |

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
# 仅安装 write
./scripts/install.sh --link write

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

### Write (纯文字技术文档撰写)

面向所有文档类工作的纯文本创作（系统架构方案、工程技术规范、算法设计说明、接口契约、技术白皮书、Wiki 知识库及工程复盘）。

- **核心特色**：彻底脱离排版格式束缚，聚焦纯文字的深度与精度。强调客观克制的工程师口吻、以“现实矛盾与设计权衡”为核心的叙事手法、严密的因果链条、公式正下方即刻解释、符号全局唯一性及系统异常防御闭环。**彻底杜绝一切 AI 套话、机械过渡与需求复述**。

```text
使用 $write 按照沉稳客观的专业口吻与权衡驱动叙事，将当前算法模块整理为一份高严谨度、因果递进的架构方案文档。
```

```text
使用 $write 重构当前设计说明，补充方案因果推导、逐一解释公式参数并消除所有 AI 套话与机械腔。
```

### Word (Word 专业排版与工程格式)

专注于 Word (`.docx`) 及正式工程技术报告、测试规范与总体方案的版式生成与排版质检。

- **核心特色**：**所有 Word 文档若无特殊要求，均默认且强制采用标准工程技术报告排版格式系统**。严格执行标准 A4 页面装订边距（上/下 $2.54\text{ cm}$，左/右 $3.17\text{ cm}$）、黑体标题梯队、宋体小四号常规体正文（首行缩进 2 字符、单倍行距、段前段后 0 磅）、$0.5\text{ 磅}$ 细实线居中表格、居中图表题注，以及基于 Office Math (OMML) 的原生矢量数学公式排版，彻底根除位图模糊与方框乱码。

```text
使用 $word 按照默认标准工程报告排版格式系统，将当前 Markdown 内容排版导出为标准规范的 Word 文档。
```

```text
使用 $word 检查并修正当前 .docx 文档的页面边距、黑体标题层级、宋体小四首行缩进、图表题注及公式 OMML 矢量排版。
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

1. **命名规范**：目录名与技能名务必保持一致，统一使用**单个直观英文单词**（如 `ppt`、`code`、`write`、`word`）或**无连字符的连续单词**（如 `styleguide`），严禁使用 `-` 连字符。
2. **必备文件**：每个技能目录必须包含完整的 `SKILL.md`，包含合法的 YAML frontmatter（`name` 与 `description`）。
3. **去 AI 感铁律**：无论在正文、提示词、代码注释还是系统指令中，**彻底杜绝 AI 感、机械八股与需求复述**。
4. **渐进披露**：通用流程与核心规则置于 `SKILL.md`，深度手册与可复用资源放入 `references/`，按需加载。
5. **运行验证**：新增或修改后必须执行 `./scripts/validate.sh` 确保校验通过。
