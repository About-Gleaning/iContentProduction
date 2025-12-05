# Markdown 支持说明

## 概述

iContentProduction 应用现在已全面支持 Markdown 格式。所有内容显示和编辑区域都可以使用 Markdown 语法来格式化文本。

## 支持的 Markdown 功能

### 基本格式

- **粗体文本**: `**粗体**` 或 `__粗体__`
- *斜体文本*: `*斜体*` 或 `_斜体_`
- ***粗斜体***: `***粗斜体***`
- ~~删除线~~: `~~删除线~~`
- `行内代码`: `` `代码` ``

### 标题

```markdown
# 一级标题
## 二级标题
### 三级标题
#### 四级标题
##### 五级标题
###### 六级标题
```

### 列表

**无序列表**:
```markdown
- 项目 1
- 项目 2
  - 子项目 2.1
  - 子项目 2.2
```

**有序列表**:
```markdown
1. 第一项
2. 第二项
3. 第三项
```

### 链接和图片

- 链接: `[链接文本](https://example.com)`
- 图片: `![图片说明](图片URL)`

### 引用

```markdown
> 这是一段引用文本
> 可以跨越多行
```

### 代码块

````markdown
```python
def hello():
    print("Hello, World!")
```
````

### 分隔线

```markdown
---
```

## 在应用中使用 Markdown

### 1. AI 聊天界面 (AIChatView)

所有 AI 回复的消息都会自动渲染 Markdown 格式。例如，AI 可以返回：

```markdown
这是一个**重要**的回答：

1. 首先做这个
2. 然后做那个
3. 最后检查结果

> 注意：这是一个提示
```

### 2. 内容详情页 (DetailView)

- **章节概要**：支持 Markdown 格式显示
- **内容正文**：完整的 Markdown 渲染
- **AI 重新生成预览**：对比查看时支持 Markdown

### 3. 内容编辑器 (EditContentView)

在编辑内容时，可以：
- 使用 **编辑** 模式输入 Markdown 文本
- 切换到 **预览** 模式查看渲染效果
- 实时在两种模式之间切换

### 4. 新建内容 (NewContentView - Step 4)

生成内容后，Step 4 的内容编辑区域支持：
- 编辑模式：直接编辑 Markdown 文本
- 预览模式：查看格式化后的效果

## 技术实现

应用使用了三个自定义组件：

### MarkdownText
用于显示简单的 Markdown 文本。

```swift
MarkdownText(content: "**粗体** 和 *斜体*", fontSize: 14)
```

### MarkdownScrollView
用于显示可滚动的 Markdown 内容。

```swift
MarkdownScrollView(
    content: markdownContent, 
    backgroundColor: .white
)
```

### MarkdownEditor
带编辑/预览切换功能的编辑器。

```swift
MarkdownEditor(text: $contentBody, minHeight: 200)
```

## 示例内容

### 视频脚本示例

```markdown
# 开场白

**主持人**: 大家好！欢迎来到今天的节目。

## 第一部分：介绍

今天我们将讨论以下内容：

1. Markdown 的基本语法
2. 如何在应用中使用
3. 实用技巧分享

> 💡 提示：Markdown 让内容格式化变得简单而优雅

## 第二部分：演示

让我们看一个代码示例：

\```swift
let message = "Hello, Markdown!"
print(message)
\```

## 结语

感谢收看！更多信息请访问 [我们的网站](https://example.com)
```

### 小红书内容示例

```markdown
# 💄 今日分享：超实用的小技巧 ✨

大家好呀~ 今天给大家分享几个**超级实用**的技巧：

## 📝 要点总结

- ⭐ 重点一：*简洁明了*
- ⭐ 重点二：**图文并茂**
- ⭐ 重点三：***互动性强***

> 💭 小贴士：记得点赞收藏哦！

---

❤️ 喜欢的话记得关注我~ 
```

## 注意事项

1. **兼容性**：使用 SwiftUI 原生的 `AttributedString` Markdown 解析，需要 macOS 12+ 或 iOS 15+
2. **性能**：大量内容使用 Markdown 渲染时可能会略微影响性能
3. **降级处理**：如果 Markdown 解析失败，会自动降级为纯文本显示
4. **文本选择**：所有 Markdown 渲染的内容都支持文本选择和复制

## 最佳实践

1. **合理使用标题**：使用标题层级来组织内容结构
2. **善用列表**：列表让内容更易读
3. **代码块**：技术内容使用代码块包裹
4. **引用强调**：重要提示使用引用格式
5. **链接引用**：外部资源使用链接形式

## 故障排除

如果 Markdown 没有正确渲染：

1. 检查 Markdown 语法是否正确
2. 确保使用的是标准 Markdown 语法
3. 复杂的 HTML 标签可能不被支持
4. 如有问题会自动降级为纯文本显示
