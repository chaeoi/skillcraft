# 插图提取与无损复原技术手册 (Figure Extraction & Repair Manual)

在学术论文翻译流程中，插图是信息密度最高、也最容易出现裁切残损的环节。本手册收录从原 PDF 中高保真提取、修复和校验插图的硬核工程实践。

---

## 一、 核心痛点与历史血泪教训

1. **自动非白边缘裁切导致的灾难**：
   - 自动算法（如按照像素灰度 $<250$ 取外接矩形）极度不可靠。学术图表往往在四周具有浅色标注线、细长指示箭头、微小的刻度数字（如 `0`, `10`）、colorbar 标注或离散文字（如 `(a)`, `(b)`）。自动裁切会将其直接切除或拦腰切半。
   - **铁律**：永远不要直接使用全局自动化非白像素边界切图！
2. **多切片图遗漏半截**：
   - IEEE / Springer / Nature 等期刊中，排版引擎经常把一幅完整的逻辑大图打碎为 2 到 3 个独立的图片流（比如上方放曲线、下方放 X 轴与刻度，或者两张子图拼合）。
   - 如果只提取了其中一个 `xref`，会导致图片只有上半截或下半截。
3. **图号错配与文件复用**：
   - 提取过程中若缺乏严格复核，容易将两张相邻的实验图赋予重复的命名或误覆盖，导致 Markdown 中不同图题引用了完全相同的图文件。提取后必须通过 MD5 校验和图题索引确保全部插图独立且与原图一一对应。

---

## 二、 提取模式判定与工程实现

针对不同类型的原图，采用对应的最佳提取方案：

### 模式 A：单一独立高分辨率位图
当原图在 PDF 中本身就是一个完整的独立嵌入对象（可以通过 `doc.extract_image(xref)` 提取，且分辨率足够高）：
```python
import pymupdf
from PIL import Image

def extract_single_image(pdf_path, xref, out_path):
    doc = pymupdf.open(pdf_path)
    info = doc.extract_image(xref)
    doc.close()
    
    # 印刷 PDF 常见 CMYK 色彩空间，必须转为标准 sRGB
    import io
    im = Image.open(io.BytesIO(info["image"]))
    if im.mode != "RGB":
        im = im.convert("RGB")
    im.save(out_path, format="PNG")
    print(f"[A] Extracted {out_path}: {im.size}")
```

### 模式 B：多切片图垂直精准拼合
当一个图题对应上下两个切片（例如 `xref1` 和 `xref2`）时，直接在内存中建立垂直画布无缝拼接：
```python
from PIL import Image

def stitch_vertical_slices(top_path, bottom_path, out_path):
    top = Image.open(top_path).convert("RGB")
    bot = Image.open(bottom_path).convert("RGB")
    
    # 宽度对齐检查（通常切片同宽）
    w = max(top.width, bot.width)
    total_h = top.height + bot.height
    
    stitched = Image.new("RGB", (w, total_h), "white")
    stitched.paste(top, (0, 0))
    stitched.paste(bot, (0, top.height))
    stitched.save(out_path, format="PNG")
    print(f"[B] Stitched {out_path}: {stitched.size}")
```

### 模式 C：矢量图表与页面多构件定框高清渲染
当原图由矢量线条（Drawing ML）、文本标签和局部位图混合构成时，或者由散布在页面上的多个元素组成时，使用 `page.get_pixmap` 结合精确包围盒进行高清渲染提取：
```python
import pymupdf
from PIL import Image

def clip_figure_box(pdf_path, page_1based, box_pt, out_path, dpi=250):
    """
    box_pt: (x0, y0, x1, y1) in 72 pt/inch coordinates
    推荐增加 4~8 pt 的保护性留白，防止紧贴边缘
    """
    x0, y0, x1, y1 = box_pt
    margin = 5  # 5 pt 保护外延
    clip_rect = pymupdf.Rect(x0 - margin, y0 - margin, x1 + margin, y1 + margin)
    
    doc = pymupdf.open(pdf_path)
    page = doc[page_1based - 1]
    pix = page.get_pixmap(dpi=dpi, clip=clip_rect)
    doc.close()
    
    im = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
    im.save(out_path, format="PNG")
    print(f"[C] Clipped {out_path} ({im.size}) from p{page_1based}")
```

---

## 三、 边缘贴边与裁切质量自检

提取完成后，必须编写脚本快速扫描四周边缘是否有内容被贴边切断：

```python
import numpy as np
from PIL import Image

def check_edge_clipping(img_path, threshold=245, margin_px=6):
    """
    检查图片外围 margin_px 像素内是否有非纯白像素密集分布
    若某条边非白像素比例 > 0.05，需重点人工复核该边是否切断了标注
    """
    im = Image.open(img_path).convert("L")
    a = np.array(im)
    
    top = (a[:margin_px, :] < threshold).mean()
    bot = (a[-margin_px:, :] < threshold).mean()
    left = (a[:, :margin_px] < threshold).mean()
    right = (a[:, -margin_px:] < threshold).mean()
    
    return {"T": top, "B": bot, "L": left, "R": right}
```

- 如果 `T/B/L/R` 中有值大幅贴近或 $>0.10$：
  - 检查原 PDF：是不是坐标轴标题被切掉了？
  - 是不是最上方的曲线波峰被削掉了？
  - 是不是最右侧的图例框线被截断了？
  - 如有截断，立刻扩大定框范围重新截取。
