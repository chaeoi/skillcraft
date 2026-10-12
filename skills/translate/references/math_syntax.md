# LaTeX 公式转 OMML 严谨语法与避坑手册 (Math Syntax & OMML Craft)

在 Markdown 撰写中，数学公式通过 Pandoc 转译为 Word 原生 Office Math (OMML) 矢量公式对象。由于 Pandoc 对某些 LaTeX 宏包与语法的支持存在特定边界，必须遵循本手册规范，杜绝公式渲染异常、排版坍塌或乱码。

---

## 一、 块级公式与行内公式标准语法

### 1. 块级独立公式 (Display Math)
- 独立成段，公式上下各留一个空行；
- 使用双美元符 `$$` 包裹；
- 公式编号写在公式末尾，统一采用 `\qquad (编号)` 格式：
  ```markdown
  $$m \ddot{x} + c \dot{x} + k x = F(t) \qquad (1)$$
  ```
- **核心禁忌**：
  - **严禁使用 `\tag{1}` 或 `\tag*{(1)}`**：Pandoc 在转为 docx 时，对 `\tag` 会出现无法生成编号、吞没公式内容或引发解析警告的缺陷；
  - **严禁使用 `\begin{equation}` / `\end{equation}` 环境**：部分 Pandoc 版本对环境标签支持不一致，直接使用 `$$...$$` 最为稳固。

### 2. 行内嵌入公式 (Inline Math)
- 使用单美元符 `$x$` 包裹；
- 变量、符号、上下标及简短物理量必须成对闭合；
- **核心禁忌**：
  - 严禁出现未闭合的单 `$`，奇数个 `$` 会导致文档从该处之后全部文字被错误识别为公式，导致大面积正文排版溃散。

---

## 二、 高频避坑与转义字符保护

### 1. 反斜杠转义与控制字符冲突 (Python 转义陷阱)
在很多自动化文本替换与数据清洗脚本中，未经过保护的字符串替换会将 LaTeX 语法当成控制字符破坏：
- **`\text{}` 破坏**：`\text` 如果在 Python 普通字符串中直接写，`\t` 会被当成制表符（Tab）；
  - **正确做法**：始终使用原生字符串 `r"\text{...}"` 或双反斜杠 `\\text{...}`。
- **`\right` 破坏**：`\r` 容易被解释为回车（Carriage Return），导致公式中出现 `ight)` 乱码；
  - **正确做法**：确保替换规则中反斜杠完整转义，并在校验脚本中加入 `(?<![r\\])ight[)\\}]` 正则拦截。

### 2. Markdown 表格内部公式与竖线冲突
- Markdown 表格使用 `|` 分隔列；
- 如果公式中包含绝对值、范数或矩阵行列式：
  - 绝对值严禁直接书写 `|x|`，这会直接把 Markdown 表格腰斩撕裂！
  - **正确做法**：必须使用 LaTeX 命令 `\lvert x \rvert`：
    ```markdown
    | 参数 | 计算公式 | 约束范围 |
    | :--- | :--- | :--- |
    | 跟踪误差 | $e(t) = \lvert \theta_{ref} - \theta_{act} \rvert$ | $\le 0.05\text{ rad}$ |
    ```

### 3. 多行公式与方程组
- 涉及矩阵与方程组时，使用标准 AMS 矩阵环境：
  ```markdown
  $$\begin{bmatrix} x \\ y \\ \theta \end{bmatrix} = \begin{bmatrix} \cos\alpha & -\sin\alpha & 0 \\ \sin\alpha & \cos\alpha & 0 \\ 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} x_0 \\ y_0 \\ \theta_0 \end{bmatrix} \qquad (2)$$
  ```
- 分段函数使用 `\begin{cases} ... \end{cases}`：
  ```markdown
  $$K(\theta) = \begin{cases} K_1, & \theta < \theta_{thresh} \\ K_2, & \theta \ge \theta_{thresh} \end{cases} \qquad (3)$$
  ```

---

## 三、 公式自动化合规检测脚本

将以下逻辑集成在 `tools/validate_repository.py` 中，进行提交前静态卡口校验：

```python
import re

def validate_math(text, filename=""):
    errors = []
    # 1. 检查美元符奇偶性
    if text.count("$") % 2 != 0:
        errors.append(f"{filename}: 存在奇数个 $ 符号，公式定界符未闭合！")
    
    # 2. 检查非法 \tag{}
    if "\\tag{" in text:
        errors.append(f"{filename}: 发现不支持的 \\tag 宏，请改用 \\qquad (N)")
        
    # 3. 检查反斜杠破损形成的 ight
    if re.search(r"(?<![r\\])ight[)\\}]", text):
        errors.append(f"{filename}: 发现受损的 \\right 符号（残留 ight）")
        
    # 4. 检查表格内未转义的单个绝对值竖线
    for line in text.splitlines():
        if line.strip().startswith("|") and re.search(r"\$[^\$]*\|[^\$]*\$", line):
            errors.append(f"{filename}: 表格内公式包含裸竖线，请替换为 \\lvert ... \\rvert")
            
    return errors
```
