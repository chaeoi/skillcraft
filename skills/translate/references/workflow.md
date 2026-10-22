# 论文翻译标准化作业全流程 (Standard Translation Workflow)

本指南规范了从原始文献引入到交付最终 Word 成果的端到端标准化工作流。

---

## 阶段一：资产录入与目录初始化

1. **原件归档**：
   - 将原始英文论文 PDF 放入 `papers/originals/<Paper Title>.pdf`；
   - 确认 PDF 文件名即为论文英文官方全称，不使用缩写或中文重命名；
   - 原始 PDF 设为只读状态，任何流程步骤严禁对该文件执行写操作。
2. **初始化中间稿与图片目录**：
   - 创建工作目录 `papers/intermediate/images/<Paper Title>/`；
   - 创建 Markdown 工作文件 `papers/intermediate/<Paper Title>.md`；
   - 从模板（`templates/paper.md`）初始化元数据头：
     ```markdown
     # 中文译文标题
     ## Original English Title
     
     **作者**：...  
     **机构**：...  
     **期刊 / 会议**：...  
     **年份**：...  
     **DOI**：...  
     **原件**：`../originals/<Paper Title>.pdf`  
     **最终译文**：`../translations/<Paper Title>.docx`  
     
     ---
     ```

---

## 阶段二：图表高精度提取与校准

1. **插图定位与清单盘点**：
   - 通读原 PDF，建立原图清单（Figure 1, 2, ..., N），记录每张图在原 PDF 中的页码、构成形式（单张位图、多切片拼图、多子图组合、矢量图表）；
   - 严禁漏图，严禁跳过附录或方法章节的细分实验图。
2. **提取模式选择**：
   - **嵌入高分位图**：使用 `pymupdf`（`doc.extract_image(xref)`）直接提取无损原始分辨率图像；
   - **多切片拼图**：使用 Python 脚本将同一图题下的上下切片无缝垂直拼接；
   - **矢量示意图/页面组合图**：使用 `page.get_pixmap(dpi=200~250, clip=rect)` 针对图框区域进行高采样渲染截取，保留 5~10 pt 的外延保护边距；
   - **颜色空间转换**：若原图为 CMYK（常用于印刷期刊），必须转换为标准 sRGB 保存为 PNG。
3. **图像命名与索引**：
   - 统一保存至 `papers/intermediate/images/<Paper Title>/figN.cleaned.png`；
   - 校验图片 MD5，确保无重复错配文件。

---

## 阶段三：双语翻译与结构化 Markdown 编排

1. **摘要与引言翻译**：
   - 逐段严谨对照翻译，保留核心研究动机、科学问题与创新点；
   - 杜绝 AI 的主观解释或引申，保持严谨客观的学术口吻。
2. **公式转译与编号**：
   - 块级公式采用 `$$... \qquad (N)$$` 格式；
   - 检查定界符、绝对值符号（`\lvert ... \rvert`）及字符转义。
3. **表格转译**：
   - 表头与单元格数据如实还原；
   - 严格保证 Markdown 表格的分隔行（`|:---|:---|`）与各行列数一致。
4. **图题与图注**：
   - 紧随图片后插入中文图题，如 `![图 1：系统架构示意图](images/<Paper Title>/fig1.cleaned.png)`；
   - 针对复杂的子图说明，在图下方紧跟图注段落。

---

## 阶段四：自动化编译与排版流水线

Agent 在当前工作目录下执行自动化编译与版式后处理（详细 Python 实现逻辑见 [references/layout_specs.md](layout_specs.md)）：

1. **语法与公式预检**：修复转义控制符与损坏的定界符（如 `\right` 残留 `ight`、`\lvert` 冲突等）；
2. **Pandoc 编译**：
   ```bash
   pandoc papers/intermediate/<Paper Title>.md \
     -f markdown+tex_math_dollars \
     -t docx \
     -o papers/translations/<Paper Title>.docx \
     --resource-path papers/intermediate \
     --standalone
   ```
3. **OpenXML 版式与尺寸后处理（基于结构分区的对齐注入与 ECMA-376 严格排序）**：
   - **保持 `word/styles.xml` 原生干净基线**：严禁向 `styles.xml` 批量注入 `pPr` 属性，避免污染 Word 样式继承树，确保样式定义合规解析；
   - 提取解包 `.docx`，根据图片长宽比（Aspect Ratio）自动缩放 `wp:extent` 和 `a:ext`，严格控高防止撑满版面；
   - **在 `word/document.xml` 中以段落级别注入结构分区对齐属性**：
     - **文首元数据（Front-Matter Metadata）**：作者、单位机构、通讯作者、DOI 等段落严格注入**左对齐**（`<w:jc w:val="left"/>`），杜绝因两端对齐导致的字距严重拉伸变形；
     - **正文主体段落（Body Text）**：引言、实验、讨论及结论等学术正文段落严格注入**两端对齐**（`<w:jc w:val="both"/>`）；
     - **章节标题（Headings）**：各级标题指定为**左对齐**（`<w:jc w:val="left"/>`）；
     - **插图与图表题（Drawings & Captions）**：注入水平居中（`<w:jc w:val="center"/>`）与 `keepNext` 同页保护。
   - **ECMA-376 Schema 子元素严格排序（杜绝 Word 报修复错误）**：
     - 对 `document.xml` 中的所有修改过的 `<w:pPr>` 节点执行标准序列排序（`pStyle -> keepNext -> numPr -> ... -> jc -> ... -> rPr -> sectPr`），序列化时使用 `lxml.etree` 配合 `standalone="yes"` 输出，确保标准命名空间前缀原样保留。
4. **静态合法性校验**：检查公式定界符、禁用 `\tag`、图片存在性与无重复配置。

---

## 阶段五：逐页目检验收与交付归档（每次修改必检步骤）

**特别铁律**：无论是首次编译完成，还是后续进行任何微调、文字修正或版式优化，**每一次修改后都必须强制执行本验收目检闭环**，绝不容许未经验证即交付。

1. **PDF 渲染目检**：
   - 使用 LibreOffice Headless 批量转出 PDF：
     ```bash
     soffice --headless --convert-to pdf --outdir /tmp/check papers/translations/*.docx
     ```
2. **三项关键视觉与结构核对**：
   - **文首元数据核对（核心防线）**：提取第 1 页文本块，检查作者列表与机构单位是否为规范左对齐，确保无异常拉伸空格或字符断裂；
   - **正文两端对齐与密度核对**：抽查正文各页，确认左右版心边缘垂直规整（两端对齐生效），版面文字密度饱满，无突兀空行断层；
   - **插图与表格核对**：抽查图像是否有贴边截断、坐标轴缺失或模糊；检查是否有图片撑满整页（高度 $>3.6$ 英寸）；检查公式是否为清晰的矢量 OMML，表格是否居中且无单元格文字撕裂。
3. **成果交付**：
   - 确认全流程检验无误后，产物集中收纳于 `papers/translations/<Paper Title>.docx`。
