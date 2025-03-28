//
//  ListView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/28.
//

import SwiftUI

// 创建一个环境键用于控制分隔线显示
private struct ShowDividersKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

// 扩展EnvironmentValues
extension EnvironmentValues {
    var showDividers: Bool {
        get { self[ShowDividersKey.self] }
        set { self[ShowDividersKey.self] = newValue }
    }
}

// ListView组件
struct ListView<Content: View>: View {
    private let content: Content
    private let showDividers: Bool
    
    init(showDividers: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.showDividers = showDividers
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                content
            }
            .padding(.horizontal,16)
            .environment(\.showDividers, showDividers)
        }
        .background(Color("backgroundPrimaryColor"))
    }
}

// SectionView实现
struct SectionView<Header: View, Footer: View>: View {
    private let views: [AnyView]
    private let header: Header?
    private let footer: Footer?
    private let showDividers: Bool?
    @Environment(\.showDividers) private var parentShowDividers
    
    private var effectiveShowDividers: Bool {
        showDividers ?? parentShowDividers
    }
    
    // 原始初始化方法 - 不带header和footer
    init<V: View>(showDividers: Bool? = nil, _ views: V...) where Header == EmptyView, Footer == EmptyView {
        self.views = views.map { AnyView($0) }
        self.showDividers = showDividers
        self.header = nil
        self.footer = nil
    }
    
    // 带header初始化方法
    init<V: View>(showDividers: Bool? = nil, header: Header, _ views: V...) where Footer == EmptyView {
        self.views = views.map { AnyView($0) }
        self.showDividers = showDividers
        self.header = header
        self.footer = nil
    }
    
    // 带header和footer初始化方法
    init<V: View>(showDividers: Bool? = nil, header: Header, footer: Footer, _ views: V...) {
        self.views = views.map { AnyView($0) }
        self.showDividers = showDividers
        self.header = header
        self.footer = footer
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 显示header
            if let header = header {
                header
                    .foregroundStyle(Color("textSecondaryColor"))
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 5)
            }
            VStack(spacing:0){
                // 显示内容项
                ForEach(0..<views.count, id: \.self) { index in
                    HStack() {
                        views[index]
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color("textPrimaryColor"))
                    
                    if effectiveShowDividers && index < views.count - 1 {
                        Divider()
                            .padding(.leading)
                            .background(Color("textSecondaryColor"))
                            .padding(.leading, 15)
                    }
                }
            }
            .background(Color("backgroundSecondaryColor"))
            .cornerRadius(12)
            
            
            // 显示footer
            if let footer = footer {
                footer
                    .foregroundStyle(Color("textSecondaryColor"))
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 5)
                    .padding(.bottom, 10)
            }
        }
        
    }
}

// 便捷方法 - 使用String作为header
extension SectionView where Header == Text, Footer == EmptyView {
    init<V: View>(showDividers: Bool? = nil, header: String, _ views: V...) {
        self.views = views.map { AnyView($0) }
        self.showDividers = showDividers
        self.header = Text(header)
        self.footer = nil
    }
}

// 便捷方法 - 使用String作为footer
extension SectionView where Header == EmptyView, Footer == Text {
    init<V: View>(showDividers: Bool? = nil, footer: String, _ views: V...) {
        self.views = views.map { AnyView($0) }
        self.showDividers = showDividers
        self.header = nil
        self.footer = Text(footer)
    }
}

// 便捷方法 - 使用header构建器
extension SectionView where Footer == EmptyView {
    init<V: View>(showDividers: Bool? = nil, @ViewBuilder header: () -> Header, _ views: V...) {
        self.views = views.map { AnyView($0) }
        self.showDividers = showDividers
        self.header = header()
        self.footer = nil
    }
}

#Preview {
    ListView {
        // 不带header和footer
        SectionView(
            Text("第一项"),
            Text("第二项"),
            Text("最后一项")
        )
        
        // 带String header
        SectionView(header: "个人信息",
            Text("姓名"),
            Text("电话")
        )
        
        // 带ViewBuilder header
        SectionView(header: {
            HStack {
                Image(systemName: "gear")
                Text("设置")
            }
        },
            Text("通用设置"),
            Text("高级设置")
        )
        
        // 带footer
        SectionView(footer: "请谨慎操作",
            Text("删除账户"),
            Text("清除数据")
        )
        
        
    }
}
