//
//  MarkdownTestView.swift
//  iContentProduction
//
//  Created by AI Assistant on 2025/12/05.
//  用于测试 Markdown 换行显示
//

import SwiftUI

struct MarkdownTestView: View {
    @State private var testContent = """
**视频脚本：AI的转折点——从"锯齿智能"到安全超级智能**
*时长：约12分钟 | 风格：口语化、逻辑清晰、富有启发性*

---

### **【开场白｜0:00 - 0:50】**

（镜头缓缓推进，背景为动态流动的数据流与神经网络可视化）

大家好。你有没有过这样的体验？问一个AI写一段代码，它三下五除二就给你了，看起来挺像那么回事。但一运行——报错。

你指出问题，它立刻道歉，改！结果呢？新bug出现了。再指出来，它又改……最后居然退回到最初的版本。就像两个人在原地打转，谁也说服不了谁。

这不是个例。这背后，其实藏着当前人工智能最深的危机之一——我们造出来的系统，正在变成一种**"高分低能"的矛盾体"。**
"""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Markdown 换行测试")
                .font(.title)
                .bold()
            
            Divider()
            
            HStack(alignment: .top, spacing: 20) {
                // 原始文本
                VStack(alignment: .leading) {
                    Text("原始 Text 显示")
                        .font(.headline)
                    
                    ScrollView {
                        Text(testContent)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Markdown 渲染
                VStack(alignment: .leading) {
                    Text("MarkdownScrollView 显示")
                        .font(.headline)
                    
                    MarkdownScrollView(content: testContent, backgroundColor: Color.white)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
            
            Divider()
            
            // 显示处理后的内容（调试用）
            VStack(alignment: .leading) {
                Text("处理后的内容（调试）")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal) {
                    Text(processedContent)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.blue)
                }
                .frame(height: 60)
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private var processedContent: String {
        testContent
            .replacingOccurrences(of: "\n\n", with: "<<<PARAGRAPH>>>")
            .replacingOccurrences(of: "\n", with: "  \\n")
            .replacingOccurrences(of: "<<<PARAGRAPH>>>", with: "\\n\\n")
    }
}

#Preview {
    MarkdownTestView()
}
