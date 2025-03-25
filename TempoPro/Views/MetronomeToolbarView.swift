import SwiftUI

struct MetronomeToolbarView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager
    @EnvironmentObject var practiceCoordinator: PracticeCoordinator
    @State private var showingStatsView = false
    @State private var showingCountDownTimerView = false
    @State private var showingStepTimerView = false
    
    // 定义按钮数据模型
    struct ToolbarButtonItem: Identifiable {
        let id = UUID()
        let image: String
        let action: () -> Void
    }
    
    // 按钮数据
    private var buttons: [ToolbarButtonItem] {
        [
            
            ToolbarButtonItem(image: "icon-timer") {
                showingCountDownTimerView = true
            },
            
            ToolbarButtonItem(image: "icon-stairs-arrow-up-right") {
                showingStepTimerView = true
            },

            ToolbarButtonItem(image: "icon-play-list") {
                playlistManager.openPlaylistsSheet()
            },
            
            ToolbarButtonItem(image: "icon-calendar-days") {
                showingStatsView = true
            }
        ]
    }
    
    // 判断是否显示倒计时信息
    private var shouldShowCountdownInfo: Bool {
        return practiceCoordinator.activeMode == .countdown && 
               (practiceCoordinator.practiceStatus == .running || 
                practiceCoordinator.practiceStatus == .paused)
    }
    
    // 获取倒计时显示文本
    private var countdownInfoText: String {
        if shouldShowCountdownInfo {
            return practiceCoordinator.getCountdownDisplayText()
        }
        return ""
    }
    
    var body: some View {
        GeometryReader { geometry in
            // 计算按钮尺寸
            let buttonWidth = (geometry.size.width - CGFloat(buttons.count - 1) * 2) / CGFloat(buttons.count)
            let toolbarHeight = buttonWidth + 2 // 按钮高度 + 上边框高度
            
            VStack(spacing: 0) {
                // 上边框带阴影
                ZStack(alignment: .top) {
                    // 黑色边框
                    Rectangle()
                        .fill(theme.backgroundColor)
                        .frame(height: 2)
                    
                    // 白色阴影（位于边框下方）
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 1)
                        .offset(y: 2) // 放在边框正下方
                }
                .frame(height: 2) // 为阴影留出空间
                
                // 工具栏内容
                HStack(spacing: 0) {
                    ForEach(Array(buttons.enumerated()), id: \.element.id) { index, button in
                        if index > 0 {
                            // 分隔线带阴影
                            ZStack(alignment:.leading) {
                                // 黑色分隔线
                                Rectangle()
                                    .fill(theme.backgroundColor)
                                    .frame(width: 2)
                                
                                // 白色阴影（位于分隔线右侧）
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 1)
                                    .offset(x: 2) // 放在分隔线右侧
                            }
                            .frame(width: 2) // 为阴影留出空间
                        }
                        
                        // 按钮
                        ZStack {
                            ToolbarButton(
                                image: button.image,
                                action: button.action
                            )
                            
                            // 在第一个按钮上方显示倒计时信息
                            if index == 0 && shouldShowCountdownInfo {
                                HStack(spacing:3) {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(countdownInfoText)
                                        .font(.custom("MiSansLatin-SemiBold", size: 13))
                                        .foregroundColor(theme.backgroundColor)
                                        .lineLimit(1)
                                }
                                .offset(y:-30)
                            }
                        }
                        .frame(width: buttonWidth, height: buttonWidth) // 明确设置按钮宽高
                    }
                }
                .frame(height: buttonWidth)
                .background(theme.primaryColor.opacity(0.3))
            }
            .frame(height: toolbarHeight)
        }
        .frame(height: computeToolbarHeight())
        .sheet(isPresented: $playlistManager.showPlaylistsSheet) {
            PlaylistListView()
                .environmentObject(playlistManager)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .compatibleCornerRadius(15)
                
        }
        .sheet(isPresented: $showingStatsView) {
            PracticeStatsView()
                .presentationDragIndicator(.hidden)
                .compatibleCornerRadius(15)
        }
        .sheet(isPresented: $showingCountDownTimerView) {
            CountDownPracticeView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .compatibleCornerRadius(15) 
                
        }

        .sheet(isPresented: $showingStepTimerView) {
            ProgressivePracticeView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .compatibleCornerRadius(15)
        }   
    }
    
    // 计算工具栏的精确高度
    private func computeToolbarHeight() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let buttonWidth = (screenWidth - CGFloat(buttons.count - 1) * 2) / CGFloat(buttons.count)
        return buttonWidth + 2 // 按钮高度 + 上边框高度（包括阴影）
    }
    
    struct ToolbarButton: View {
        let image: String
        let action: () -> Void
        
        @State private var isPressed = false
        @Environment(\.scenePhase) private var scenePhase
        @Environment(\.metronomeTheme) var theme
        var body: some View {
            VStack {
                Image(image)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(theme.backgroundColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .background(isPressed ? theme.backgroundColor.opacity(0.1) : Color.clear)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
            .onChange(of: scenePhase) { newPhase in
            if newPhase != .active {
                isPressed = false
            }
        }
        }
    }
}

#Preview {
    MetronomeToolbarView()
}
