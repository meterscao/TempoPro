import SwiftUI

struct MetronomeToolbarView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager
    @State private var showingStatsView = false
    @State private var showingSetTimerView = false
    
    // 定义按钮数据模型
    struct ToolbarButtonItem: Identifiable {
        let id = UUID()
        let image: String
        let action: () -> Void
    }
    
    // 按钮数据
    private var buttons: [ToolbarButtonItem] {
        [
            ToolbarButtonItem(image: "icon-wheel") {
                playlistManager.openPlaylistsSheet()
            },
            ToolbarButtonItem(image: "icon-timer") {
                showingSetTimerView = true
            },
            
            ToolbarButtonItem(image: "icon-play-list") {
                playlistManager.openPlaylistsSheet()
            },
            ToolbarButtonItem(image: "icon-clap") {
                // 拍手动作
            },
            ToolbarButtonItem(image: "icon-analysis") {
                showingStatsView = true
            }
        ]
    }
    
    var body: some View {
        GeometryReader { geometry in
            // 计算按钮尺寸
            let buttonWidth = (geometry.size.width - CGFloat(buttons.count - 1) * 2) / CGFloat(buttons.count)
            let toolbarHeight = buttonWidth + 2 // 按钮高度 + 上边框高度
            
            VStack(spacing: 0) {
                // 上边框
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 2)
                
                // 工具栏内容
                HStack(spacing: 0) {
                    ForEach(Array(buttons.enumerated()), id: \.element.id) { index, button in
                        if index > 0 {
                            // 分隔线
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 2)
                        }
                        
                        // 按钮
                        ToolbarButton(
                            image: button.image,
                            action: button.action
                        )
                        .frame(width: buttonWidth, height: buttonWidth) // 明确设置按钮宽高
                    }
                }
                .frame(height: buttonWidth)
                .background(theme.primaryColor.opacity(0.3))
            }
            .frame(height: toolbarHeight)
        }
        .frame(height: computeToolbarHeight()) // 设置整个GeometryReader的精确高度
        .sheet(isPresented: $playlistManager.showPlaylistsSheet) {
            PlaylistListView()
                .environmentObject(playlistManager)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingStatsView) {
            PracticeStatsView()
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingSetTimerView) {
            SetTimerView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
    }
    
    // 计算工具栏的精确高度
    private func computeToolbarHeight() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let buttonWidth = (screenWidth - CGFloat(buttons.count - 1) * 2) / CGFloat(buttons.count)
        return buttonWidth + 2 // 按钮高度 + 上边框高度
    }
    
    struct ToolbarButton: View {
        let image: String
        let action: () -> Void
        
        @State private var backgroundColor: Color = Color.clear
        
        var body: some View {
            VStack {
                Image(image)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // 填充整个分配的空间
            .contentShape(Rectangle())
            .background(backgroundColor)
            .onTapGesture {
                action()
            }
        }
    }
}

#Preview {
    MetronomeToolbarView()
}
