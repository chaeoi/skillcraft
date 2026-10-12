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

在仓库根目录下运行标准化工具链：

```bash
# 1. 修复转义控制符与损坏的括号
python3 tools/repair_markdown.py

# 2. 编译生成带有自适应尺寸与专业版式的 Word 文档
python3 tools/compile_all_docx.py

# 3. 静态合法性校验（公式、图片存在性、页面标头）
python3 tools/validate_repository.py
```

---

## 阶段五：逐页目检验收与交付归档

1. **PDF 渲染目检**：
   - 使用 LibreOffice Headless 批量转出 PDF：
     ```bash
     soffice --headless --convert-to pdf --outdir /tmp/check papers/translations/*.docx
     ```
2. **三项关键视觉核对**：
   - **插图核对**：抽查图像是否有贴边截断、坐标轴缺失或模糊；
   - **尺寸协调性**：检查是否有图片撑满整页（高度 $>3.6$ 英寸），确认图文混排比例协调；
   - **公式与表格**：检查公式是否为清晰的矢量 OMML，表格三线表是否居中且无单元格文字撕裂。
3. **成果交付**：
   - 产物集中收纳于 `papers/translations/<Paper Title>.docx`。
