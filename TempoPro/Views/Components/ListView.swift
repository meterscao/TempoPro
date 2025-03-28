//
//  ListView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/28.
//

import SwiftUI

// 定义边缘枚举类型
enum Edge {
    case top, bottom, leading, trailing
    case all
    
    var swiftUIEdge: SwiftUI.Edge? {
        switch self {
        case .top: return .top
        case .bottom: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        case .all: return nil
        }
    }
}

// 创建一个环境键用于控制分隔线显示
private struct ShowDividersKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

// 创建环境键存储内边距
private struct ContentInsetKey: EnvironmentKey {
    static let defaultValue: [Edge: CGFloat] = [:]
}

// 扩展EnvironmentValues
extension EnvironmentValues {
    var showDividers: Bool {
        get { self[ShowDividersKey.self] }
        set { self[ShowDividersKey.self] = newValue }
    }
    
    var contentInsets: [Edge: CGFloat] {
        get { self[ContentInsetKey.self] }
        set { self[ContentInsetKey.self] = newValue }
    }
}

// ListView组件
struct ListView<Content: View>: View {
    private let content: Content
    private let showDividers: Bool
    private var insets: [Edge: CGFloat] = [:] // 存储内边距的属性
    
    init(showDividers: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.showDividers = showDividers
        // 设置默认内边距
        self.insets = [
            .top: 20,
            .bottom: 20,
            .leading: 20,
            .trailing: 20
        ]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                content
            }
            .padding(.leading, insets[.leading] ?? 20)
            .padding(.trailing, insets[.trailing] ?? 20)
            .padding(.top, insets[.top] ?? 20)
            .padding(.bottom, insets[.bottom] ?? 20)
            .environment(\.showDividers, showDividers)
            .environment(\.contentInsets, insets)
        }
        .background(Color("backgroundPrimaryColor"))
    }
    
    // 添加contentInset函数，创建新视图实例
    func contentInset(_ edge: Edge, _ value: CGFloat) -> ListView {
        var newListView = self
        newListView.insets[edge] = value
        
        // 如果是.all，设置所有边缘
        if edge == .all {
            newListView.insets[.top] = value
            newListView.insets[.bottom] = value
            newListView.insets[.leading] = value
            newListView.insets[.trailing] = value
        }
        
        return newListView
    }
    
    // 重置特定方向的内边距到默认值
    func resetContentInset(_ edge: Edge) -> ListView {
        var newListView = self
        
        switch edge {
        case .top:
            newListView.insets[.top] = 20
        case .bottom:
            newListView.insets[.bottom] = 20
        case .leading:
            newListView.insets[.leading] = 20
        case .trailing:
            newListView.insets[.trailing] = 20
        case .all:
            newListView.insets[.top] = 20
            newListView.insets[.bottom] = 20
            newListView.insets[.leading] = 20
            newListView.insets[.trailing] = 20
        }
        
        return newListView
    }
}

// 自定义Section视图
struct SectionView<Content: View, Header: View, Footer: View>: View {
    private let content: Content
    private let header: Header
    private let footer: Footer
    private let showDividers: Bool?
    @Environment(\.showDividers) private var parentShowDividers
    @Environment(\.contentInsets) private var contentInsets
    
    private var effectiveShowDividers: Bool {
        showDividers ?? parentShowDividers
    }
    
    // 主初始化方法 - 完全符合系统Section语法
    init(
        showDividers: Bool? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer
    ) {
        self.content = content()
        self.header = header()
        self.footer = footer()
        self.showDividers = showDividers
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 显示header
            if !(header is EmptyView) {
                header
                    .foregroundStyle(Color("textSecondaryColor"))
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 5)
            }
            
            // 内容带分隔线
            VStack(spacing: 0) {
                DividedContent(showDividers: effectiveShowDividers) {
                    content
                }
            }
            .background(Color("backgroundSecondaryColor"))
            .cornerRadius(12)
            
            // 显示footer
            if !(footer is EmptyView) {
                footer
                    .foregroundStyle(Color("textSecondaryColor"))
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 5)
            }
        }
    }
}

// 使用_VariadicView实现自动分隔线
struct DividedContent<Content: View>: View {
    let content: Content
    let showDividers: Bool
    
    init(showDividers: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.showDividers = showDividers
    }
    
    var body: some View {
        _VariadicView.Tree(DividedLayout(showDividers: showDividers)) {
            content
        }
    }
    
    // 负责布局和分隔线的内部结构
    struct DividedLayout: _VariadicView_MultiViewRoot {
        let showDividers: Bool
        
        @ViewBuilder
        func body(children: _VariadicView.Children) -> some View {
            let last = children.last?.id
            
            ForEach(children) { child in
                child
                    .padding(.horizontal, 16)
                    .padding(.vertical,10)
                    .frame(minHeight: 44)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color("textPrimaryColor"))
                
                if showDividers && child.id != last {
                    Divider()
                        .background(.white.opacity(0.05))
                        .padding(.leading, 16)
                }
            }
        }
    }
}

// 简化初始化方法 - 只有content，无header和footer
extension SectionView where Header == EmptyView, Footer == EmptyView {
    init(showDividers: Bool? = nil, @ViewBuilder content: () -> Content) {
        self.init(
            showDividers: showDividers,
            content: content,
            header: { EmptyView() },
            footer: { EmptyView() }
        )
    }
}

// 简化初始化方法 - 有content和header，无footer
extension SectionView where Footer == EmptyView {
    init(showDividers: Bool? = nil, @ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header) {
        self.init(
            showDividers: showDividers,
            content: content,
            header: header,
            footer: { EmptyView() }
        )
    }
}

// 简化初始化方法 - 有content和footer，无header
extension SectionView where Header == EmptyView {
    init(showDividers: Bool? = nil, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.init(
            showDividers: showDividers,
            content: content,
            header: { EmptyView() },
            footer: footer
        )
    }
}

// 方便的初始化方法 - 字符串header
extension SectionView where Header == Text, Footer == EmptyView {
    init(showDividers: Bool? = nil, header: String, @ViewBuilder content: () -> Content) {
        self.init(
            showDividers: showDividers,
            content: content,
            header: { Text(header) },
            footer: { EmptyView() }
        )
    }
}

// 方便的初始化方法 - 字符串footer
extension SectionView where Header == EmptyView, Footer == Text {
    init(showDividers: Bool? = nil, @ViewBuilder content: () -> Content, footer: String) {
        self.init(
            showDividers: showDividers,
            content: content,
            header: { EmptyView() },
            footer: { Text(footer) }
        )
    }
}

// 同时带有字符串header和footer的便捷初始化方法
extension SectionView where Header == Text, Footer == Text {
    init(showDividers: Bool? = nil, header: String, @ViewBuilder content: () -> Content, footer: String) {
        self.init(
            showDividers: showDividers,
            content: content,
            header: { Text(header) },
            footer: { Text(footer) }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("上方内容")
            .padding()
            .background(Color.gray.opacity(0.2))
        
        ListView {
            // 基本用法示例
            SectionView {
                Text("第一项")
                Text("第二项")
                Text("第三项")
            }
            
            // 带header的示例
            SectionView(header: "个人信息") {
                Text("姓名: 张三")
                Text("电话: 123-4567-8910")
                Text("邮箱: zhangsan@example.com")
            }
        }
        .border(Color.red)
        
        // 自定义内边距
        ListView {
            SectionView(header: "自定义内边距") {
                Text("上内边距: 50")
                Text("下内边距: 10")
                Text("左右内边距: 默认16")
            }
        }
        .contentInset(.top, 50)
        .contentInset(.bottom, 10)
        .border(Color.blue)
        
        Text("下方内容")
            .padding()
            .background(Color.gray.opacity(0.2))
    }
}
