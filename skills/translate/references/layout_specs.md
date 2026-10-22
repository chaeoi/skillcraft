# 自适应插图尺寸策略与 Word 最终版式标准 (Figure Sizing & Word Layout Specs)

在生成和交付正式 Word (`.docx`) 论文译文时，插图尺寸是决定版面专业度与视觉舒适度的关键因素。本规范阐述“基于长宽比自适应控高控宽”的数学逻辑与排版落地实现。

---

## 一、 版心空间几何与失衡痛点剖析

### 1. 标准 A4 页面几何
- **纸张规格**：A4（宽 $21.0\text{ cm}$ / $8.27\text{ in}$，高 $29.7\text{ cm}$ / $11.69\text{ in}$）；
- **常规边距**：
  - 上下边距：$2.54\text{ cm}$（$1.0\text{ in}$）
  - 左右边距：$3.17\text{ cm}$（$1.25\text{ in}$）
- **版心净尺寸**：
  - **版心净宽**：$21.0 - 2 \times 3.17 = 14.66\text{ cm}$（约 **$5.77\text{ in}$** / $5280\text{ twips}$ / $5278120\text{ EMU}$）
  - **版心净高**：$29.7 - 2 \times 2.54 = 24.62\text{ cm}$（约 **$9.69\text{ in}$**）

### 2. 传统单一边界策略的严重弊端
若简单设定：
```python
MAX_IMAGE_WIDTH = 5.00 * EMU_PER_INCH
MAX_IMAGE_HEIGHT = 5.00 * EMU_PER_INCH
```
当遇到纵向长图（如 $w:h = 1:1.6$）或方形图（$w:h = 1:1$）时：
- 图片高度会被硬性顶满到 **$5.00\text{ in}$（$12.7\text{ cm}$）**！
- 加上段前、段后、五号字图题及题注后空，纵向总高度超过 $14.5\text{ cm}$，直接霸占整页版心高度的 $60\%$ 以上；
- 导致该页剩余文字只有 2~3 行，甚至因排不下直接被挤到下一页，形成严重的“排版断层”、“大面积视觉空白”与强烈的“巨图突兀感”。

---

## 二、 基于纵横比（Aspect Ratio）的动态自适应边界引擎

为了让所有类型的插图（从全景多列序列图到微距纵向结构图）均能与小四号正文自然呼应，采用以下分段函数计算目标包围盒：

设图片宽度为 $w$，高度为 $h$，纵横比为 $R = \frac{w}{h}$：

$$
(\text{Max\_Width}, \text{Max\_Height}) = \begin{cases}
(4.00\text{ in}, 3.60\text{ in}), & R < 0.9 \quad \text{（纵向高图 / 竖直结构图）} \\
(4.25\text{ in}, 3.40\text{ in}), & 0.9 \le R < 1.3 \quad \text{（近方形图 / 紧凑框图）} \\
(4.90\text{ in}, 3.20\text{ in}), & 1.3 \le R < 2.2 \quad \text{（标准横向实验曲线 / 复合子图）} \\
(5.15\text{ in}, 2.30\text{ in}), & R \ge 2.2 \quad \text{（全景条幅图 / 多时序连续帧图带）}
\end{cases}
$$

### 缩放因子计算
计算等比例缩放系数 $s$：
$$s = \min\left(1.0, \frac{\text{Max\_Width}}{w}, \frac{\text{Max\_Height}}{h}\right)$$

缩放后尺寸：
$$w' = \text{round}(w \cdot s), \quad h' = \text{round}(h \cdot s)$$

---

## 三、 Python (WordprocessingML / DrawingML) 落地实现

在 Pandoc 导出 docx 后，解压 `word/document.xml` 执行以下严格遵循 **ECMA-376 架构标准** 与 **原生 XML 命名空间规范** 的尺寸与版式后处理（注意：`word/styles.xml` 必须保持 Pandoc 干净的原生基线，严禁对其样式节点大面积注入 `pPr`，以防破坏 Word 样式继承树并引发样式解析异常）：

### 1. 命名空间前缀保护与 lxml 解析铁律（核心避坑）
**标准命名空间前缀破坏问题**：Python 自带的 `xml.etree.ElementTree` 在重新序列化 OpenXML 文档时，默认会丢失原始的 `w:`, `m:`, `r:`, `a:`, `wp:`, `pic:` 前缀，改写为自动生成的 `ns0:`, `ns1:`, `ns4:`。Microsoft Word（特别是桌面端较新版本）内部依赖标准的前缀绑定及部件声明，面对被重写前缀的文档，会直接弹窗警告**“发现无法读取的内容，是否修复”**！

**强制规程**：必须使用 **`lxml.etree`**（或显式注册所有全局命名空间前缀映射），以 `standalone="yes"` 输出，完整保留 `<w:document>`, `<m:oMath>`, `<wp:extent>` 等原生标准前缀。

### 2. ECMA-376 严格子元素排序规范（Word 严格解析合规）
**微软 Word 的严格验证机制**：Word 对 `<w:pPr>`（段落属性）内部子元素的排列顺序有强 Schema 约束（必须严格满足 ECMA-376 规定的序列：`pStyle -> keepNext -> ... -> numPr -> ... -> jc -> ... -> rPr -> sectPr`）。如果使用 `etree.SubElement(ppr, "jc")` 盲目追加到末尾，或者将 `keepNext` 插在 `jc` 之后，就会破坏 Schema 顺序，导致桌面版 Microsoft Word 打开时判定为非法 XML。同时，全局样式表 `word/styles.xml` 切勿盲目注入非必要 `w:pPr`，避免破坏继承树导致样式解析回退。

因此，任何对 `document.xml` 中 `pPr` 属性进行增删改的操作，必须统一执行 Schema 排序重组函数：

```python
SCHEMA_PPR_ORDER = [
    "pStyle", "keepNext", "keepLines", "pageBreakBefore", "framePr",
    "widowControl", "numPr", "pBdr", "shd", "tabs", "suppressAutoHyphens",
    "kinsoku", "wordWrap", "overflowPunct", "topLinePunct", "autoSpaceDE",
    "autoSpaceDN", "bidi", "adjustRightInd", "snapToGrid", "spacing", "ind",
    "contextualSpacing", "mirrorIndents", "suppressOverlap", "jc",
    "textDirection", "textAlignment", "textboxTightWrap", "outlineLvl",
    "divId", "cnfStyle", "rPr", "sectPr", "pPrChange"
]
order_map = {tag: i for i, tag in enumerate(SCHEMA_PPR_ORDER)}

def reorder_ppr(ppr):
    """确保 pPr 子元素严格按照 ECMA-376 标准顺序排列，杜绝 Word 报错修复"""
    children = list(ppr)
    for c in children:
        ppr.remove(c)
    sorted_children = sorted(
        children,
        key=lambda c: order_map.get(c.tag.split("}")[-1], 999)
    )
    for c in sorted_children:
        ppr.append(c)
```

### 3. 插图自适应尺寸缩放与结构分区对齐完整 Python 实现

```python
import os
import shutil
import zipfile
from pathlib import Path
from lxml import etree

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
WP_NS = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
A_NS = "http://schemas.openxmlformats.org/drawingml/2006/main"

EMU_PER_INCH = 914400

SCHEMA_PPR_ORDER = [
    "pStyle", "keepNext", "keepLines", "pageBreakBefore", "framePr",
    "widowControl", "numPr", "pBdr", "shd", "tabs", "suppressAutoHyphens",
    "kinsoku", "wordWrap", "overflowPunct", "topLinePunct", "autoSpaceDE",
    "autoSpaceDN", "bidi", "adjustRightInd", "snapToGrid", "spacing", "ind",
    "contextualSpacing", "mirrorIndents", "suppressOverlap", "jc",
    "textDirection", "textAlignment", "textboxTightWrap", "outlineLvl",
    "divId", "cnfStyle", "rPr", "sectPr", "pPrChange"
]
order_map = {tag: i for i, tag in enumerate(SCHEMA_PPR_ORDER)}

def reorder_ppr(ppr):
    """确保 pPr 子元素严格按照 ECMA-376 标准顺序排列，杜绝 Word 报错修复"""
    children = list(ppr)
    for c in children:
        ppr.remove(c)
    sorted_children = sorted(
        children,
        key=lambda c: order_map.get(c.tag.split("}")[-1], 999)
    )
    for c in sorted_children:
        ppr.append(c)

def _compute_target_bounds(aspect_ratio: float):
    if aspect_ratio < 0.9:
        max_w = round(4.00 * EMU_PER_INCH)
        max_h = round(3.60 * EMU_PER_INCH)  # 严格控高，杜绝撑爆
    elif aspect_ratio < 1.3:
        max_w = round(4.25 * EMU_PER_INCH)
        max_h = round(3.40 * EMU_PER_INCH)
    elif aspect_ratio < 2.2:
        max_w = round(4.90 * EMU_PER_INCH)
        max_h = round(3.20 * EMU_PER_INCH)
    else:
        max_w = round(5.15 * EMU_PER_INCH)
        max_h = round(2.30 * EMU_PER_INCH)
    return max_w, max_h

def fit_drawing(drawing):
    extent = drawing.find(f".//{{{WP_NS}}}extent")
    transform_extent = drawing.find(f".//{{{A_NS}}}xfrm/{{{A_NS}}}ext")
    if extent is None:
        return
    width = int(extent.get("cx", "0"))
    height = int(extent.get("cy", "0"))
    if not width or not height:
        return
        
    aspect_ratio = width / height
    max_w, max_h = _compute_target_bounds(aspect_ratio)
    scale = min(1.0, max_w / width, max_h / height)
    
    fitted_w = str(round(width * scale))
    fitted_h = str(round(height * scale))
    
    extent.set("cx", fitted_w)
    extent.set("cy", fitted_h)
    if transform_extent is not None:
        transform_extent.set("cx", fitted_w)
        transform_extent.set("cy", fitted_h)

def postprocess_docx(raw_docx_path: str, final_docx_path: str):
    """
    对 Pandoc 生成的 docx 进行后处理：
    1. 保持 styles.xml 为纯净原生基线，绝不乱改样式继承树；
    2. 针对 document.xml 实施精准的结构分区对齐注入与 ECMA-376 pPr 顺序重排；
    3. 自适应计算插图尺寸并注入 keepNext 与水平居中。
    """
    tmp_dir = Path("/tmp/docx_unpack")
    if tmp_dir.exists():
        shutil.rmtree(tmp_dir)
    tmp_dir.mkdir(parents=True, exist_ok=True)
    
    with zipfile.ZipFile(raw_docx_path, "r") as z:
        z.extractall(tmp_dir)
        
    doc_xml_path = tmp_dir / "word" / "document.xml"
    parser = etree.XMLParser(remove_blank_text=False)
    droot = etree.parse(str(doc_xml_path), parser).getroot()
    
    # 结构分区对齐
    in_front_matter = True
    for p in droot.iter(f"{{{W_NS}}}p"):
        ppr = p.find(f"{{{W_NS}}}pPr")
        sid = ""
        if ppr is not None:
            pstyle = ppr.find(f"{{{W_NS}}}pStyle")
            if pstyle is not None:
                sid = pstyle.get(f"{{{W_NS}}}val", "")
        text = "".join(p.itertext()).strip()
        
        # 遇摘要、导读或正文主章节，结束文首元数据区
        if sid.startswith("Heading3") and any(k in text for k in ("编者导读", "摘要", "引言", "Abstract", "Introduction")):
            in_front_matter = False
            
        has_img = p.find(f".//{{{W_NS}}}drawing") is not None
        is_caption = sid in ("ImageCaption", "Caption", "TableCaption")
        is_heading = sid.startswith("Heading")
        
        if ppr is None:
            ppr = etree.Element(f"{{{W_NS}}}pPr")
            p.insert(0, ppr)
            
        jc = ppr.find(f"{{{W_NS}}}jc")
        if jc is None:
            jc = etree.SubElement(ppr, f"{{{W_NS}}}jc")
            
        if has_img:
            jc.set(f"{{{W_NS}}}val", "center")
            if ppr.find(f"{{{W_NS}}}keepNext") is None:
                etree.SubElement(ppr, f"{{{W_NS}}}keepNext")
        elif is_caption:
            jc.set(f"{{{W_NS}}}val", "center")
        elif is_heading:
            jc.set(f"{{{W_NS}}}val", "left")
        elif in_front_matter:
            jc.set(f"{{{W_NS}}}val", "left")
        else:
            jc.set(f"{{{W_NS}}}val", "both")
            
        reorder_ppr(ppr)
        
    # 插图尺寸自适应缩放
    for drawing in droot.iter(f"{{{W_NS}}}drawing"):
        fit_drawing(drawing)
        
    # 以 standalone="yes" 保存 document.xml，保留全部标准命名空间前缀
    doc_tree = etree.ElementTree(droot)
    doc_tree.write(
        str(doc_xml_path),
        xml_declaration=True,
        encoding="UTF-8",
        standalone="yes"
    )
    
    # 重新封包为目标 docx
    if os.path.exists(final_docx_path):
        os.remove(final_docx_path)
    with zipfile.ZipFile(final_docx_path, "w", zipfile.ZIP_DEFLATED) as z_out:
        for root, dirs, files in os.walk(tmp_dir):
            for file in files:
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, tmp_dir)
                z_out.write(full_path, rel_path)
```

---

## 四、 页面级辅助版式标准

1. **结构分区对齐规范（核心红线：严密区分元数据与正文）**：
   - **论文文首元数据（Front-Matter Metadata）必须左对齐**：
     - 包括论文主标题下方的作者列表、工作单位列表、通信作者联系方式、收录期刊信息及 DOI 等；
     - **技术痛点与避坑**：在 Markdown 转 Word 时，若使用行尾双空格换行，Pandoc 会生成带 `<w:br/>` 的单个段落。如果在后处理中对这类段落施加 `<w:jc w:val="both"/>`，Word 的两端对齐排版引擎会强行将每一行短文本拉伸至整页宽度，导致作者名与机构名之间出现数厘米的怪异间距！
     - **实施方案**：在 Markdown 撰写时，机构清单统一使用标准数字有序列表（`1. ...`），各元数据项之间使用标准空行隔开；在 OpenXML 后处理中，精准识别文首区域（进入“摘要/Abstract”或正文主章节之前），显式注入 `<w:jc w:val="left"/>`。
   - **学术正文主体严格实行两端对齐**：
     - 正文论述主体（引言、原理、制备与表征、实验、应用、结论与讨论等）必须严格实行**两端对齐**（Justified，即 `<w:jc w:val="both"/>`），绝对严禁使用默认左对齐。中西文、数学公式符号与参考文献混排时，两端对齐能够彻底消除右侧参差不齐的“毛边”，呈现严整规矩的学术刊物版面；
     - 样式层级（`Normal`、`BodyText`、`FirstParagraph`、`Compact`）在正文区段必须显式保证 `<w:jc w:val="both"/>`。
   - **各级标题显式指定左对齐**：
     - 各级标题（`Heading 1` ~ `Heading 9`）显式指定左对齐（`<w:jc w:val="left"/>`），防止因短标题两端对齐造成汉字字间距失常分散。
2. **插图段落属性**：
   - `<w:jc w:val="center"/>` 水平居中；
   - 段前 6 pt，段后 0 pt；
   - 注入 `<w:keepNext/>`，确保插图与紧随其后的图题始终处于同一页，杜绝插图在上一页底部、图题被甩到下一页顶部的孤立现象。
3. **图题与表题格式**：
   - 字体：中文黑体（SimHei），西文 Times New Roman；
   - 字号：五号（9.5 pt / `<w:sz w:val="19"/>`）；
   - 对齐：水平居中（`<w:jc w:val="center"/>`）；
   - 间距：段前 4 pt，段后 8 pt，单倍行距。
4. **表格规范**：
   - 居中对齐，标准学术三线表（顶底 1.5 pt，表头底 0.75 pt，无竖线）；
   - 注入 `<w:cantSplit/>` 保护行完整性；表头行注入 `<w:tblHeader w:val="true"/>` 启用跨页重复表头。
