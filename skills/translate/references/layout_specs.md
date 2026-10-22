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

在 Pandoc 导出 docx 后，解压 `word/document.xml` 并修改 `wp:inline` 节点的 `wp:extent` 与 `a:xfrm/a:ext`：

```python
EMU_PER_INCH = 914400
WP_NS = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
A_NS = "http://schemas.openxmlformats.org/drawingml/2006/main"

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
```

---

## 四、 页面级辅助版式标准

1. **正文段落对齐规范（核心红线）**：
   - **严格实行两端对齐**（Justified，即 `<w:jc w:val="both"/>`），绝对严禁使用默认左对齐。中西文、数学公式符号与参考文献混排时，两端对齐能够彻底消除右侧参差不齐的“毛边”，呈现严整规矩的学术刊物版面；
   - 样式层级（`Normal`、`BodyText`、`FirstParagraph`、`Compact`）必须显式声明 `<w:jc w:val="both"/>`，段落级 `pPr` 亦注入保证兼容；
   - 各级标题（`Heading 1` ~ `Heading 9`）显式指定左对齐（`<w:jc w:val="left"/>`），防止因短标题两端对齐造成汉字字间距失常分散。
2. **插图段落属性**：
   - `<w:jc w:val="center"/>` 水平居中；
   - 段前 6 pt，段后 0 pt；
   - 注入 `<w:keepNext/>`，确保插图与紧随其后的图题始终处于同一页，杜绝插图在上一页底部、图题被甩到下一页顶部的孤立现象。
3. **图题格式**：
   - 字体：中文黑体（SimHei），西文 Times New Roman；
   - 字号：五号（9.5 pt / `<w:sz w:val="19"/>`）；
   - 对齐：水平居中（`<w:jc w:val="center"/>`）；
   - 间距：段前 4 pt，段后 8 pt，单倍行距。
4. **表格规范**：
   - 居中对齐，标准学术三线表（顶底 1.5 pt，表头底 0.75 pt，无竖线）；
   - 注入 `<w:cantSplit/>` 保护行完整性；表头行注入 `<w:tblHeader w:val="true"/>` 启用跨页重复表头。
