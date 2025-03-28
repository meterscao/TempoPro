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

// 使用可变参数的SectionView实现
struct SectionView: View {
    private let views: [AnyView]
    private let showDividers: Bool?
    @Environment(\.showDividers) private var parentShowDividers
    
    private var effectiveShowDividers: Bool {
        showDividers ?? parentShowDividers
    }
    
    init<V: View>(showDividers: Bool? = nil, _ views: V...) {
        self.views = views.map { AnyView($0) }
        self.showDividers = showDividers
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<views.count, id: \.self) { index in
                HStack(){
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
                        .padding(.leading,15)
                }
            }
        }
        .background(Color("backgroundSecondaryColor"))
        .cornerRadius(12)
    }
}

#Preview {
    ListView {
        SectionView(
            Text("第一项"),
            Text("第二项"),
            Text("最后一项")
        )
        
        SectionView(
            Text("另一个部分的第一项"),
            Text("另一个部分的最后一项")
        )
    }
}
