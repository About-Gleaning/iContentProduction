# Markdown 换行问题深度分析

## 问题现象
用户报告：换行还是没有显示出来

## AI 返回的内容格式
```
**视频脚本：AI的转折点——从"锯齿智能"到安全超级智能**  \n*时长：约12分钟 | 风格：口语化、逻辑清晰、富有启发性*\n\n---\n\n### **【开场白｜0:00 - 0:50】**\n\n（镜头缓缓推进...
```

注意：AI 已经在某些行尾添加了 `  \n`（两个空格 + 换行），这是标准的 Markdown 硬换行语法。

## 可能的问题

### 1. SwiftUI AttributedString 的 Markdown 解析限制
SwiftUI 的 `AttributedString(markdown:)` 可能对某些 Markdown 语法支持不完整。

### 2. 解析选项问题
- `.inlineOnlyPreservingWhitespace` - 只处理内联元素
- `.full` - 完整的 Markdown 语法

### 3. 硬换行语法
标准 Markdown 硬换行需要：
- 行尾两个空格 + 换行符：`text  \n`
- 或者使用反斜杠：`text\\\n`

## 测试方案

### 方案 1：使用 HTML 换行标签
```swift
content.replacingOccurrences(of: "\n", with: "<br>")
```

### 方案 2：使用反斜杠换行
```swift
content.replacingOccurrences(of: "\n", with: "\\\n")
```

### 方案 3：完全绕过 Markdown，使用 AttributedString 手动构建
```swift
var attributedString = AttributedString(content)
// 手动处理粗体、斜体等格式
```

### 方案 4：使用第三方 Markdown 库
如 `MarkdownUI` 或 `Down`

## 推荐解决方案

由于 SwiftUI 的 Markdown 支持有限，建议采用混合方案：

1. **保留简单格式**：粗体、斜体、代码
2. **手动处理换行**：不依赖 Markdown 的换行规则
3. **使用 Text + AttributedString 手动构建**

## 实现代码

```swift
struct MarkdownText: View {
    let content: String
    var fontSize: CGFloat = 14
    var lineSpacing: CGFloat = 4
    
    var body: some View {
        if let attributedString = parseMarkdown(content) {
            Text(attributedString)
                .font(.system(size: fontSize))
                .lineSpacing(lineSpacing)
                .textSelection(.enabled)
        } else {
            Text(content)
                .font(.system(size: fontSize))
                .lineSpacing(lineSpacing)
                .textSelection(.enabled)
        }
    }
    
    private func parseMarkdown(_ text: String) -> AttributedString? {
        // 方案：先处理换行，再解析 Markdown
        let lines = text.components(separatedBy: "\n")
        var result = AttributedString()
        
        for (index, line) in lines.enumerated() {
            if let lineAttr = try? AttributedString(markdown: line) {
                result.append(lineAttr)
            } else {
                result.append(AttributedString(line))
            }
            
            // 添加换行（除了最后一行）
            if index < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }
        
        return result
    }
}
```

## 测试用例

```swift
let testText = """
第一行
第二行
**粗体文本**
第四行
"""

// 期望输出：
// 第一行
// 第二行
// **粗体文本** (粗体显示)
// 第四行
```
