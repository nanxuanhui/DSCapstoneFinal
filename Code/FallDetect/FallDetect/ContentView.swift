//
//  ContentView.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import SwiftUI
import SwiftData
#if os(visionOS)
import RealityKit
import ARKit
#endif

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openWindow) private var openWindow
    
    #if os(visionOS)
    @State private var selectedTab = 0
    @State private var isShowingDetail = false
    @State private var detailContent: AnyView?
    @State private var orbitalAngle: Double = 0
    @State private var isAnimating = false
    @State private var floatingElements: [FloatingElement] = generateFloatingElements()
    @State private var hoveredCard: Int? = nil
    @State private var depthOffset: Double = 0
    #endif

    @State private var selectedTabiOS = 0

    var body: some View {
        #if os(visionOS)
        // 完全沉浸式空间体验
        immersiveSpaceLayout
        #else
        // iPhone和iPad通用界面
        deviceAdaptiveLayout
        #endif
    }
    
    #if os(visionOS)
    // 完全沉浸式空间布局
    var immersiveSpaceLayout: some View {
        ZStack {
            // 确保使用纯白色背景并铺满整个空间
            Color.white
                .ignoresSafeArea(.all)
                .environment(\.colorScheme, .light) // 强制使用浅色模式
            
            // 核心内容层 - 以用户为中心的环绕式设计
            GeometryReader { geometry in
                ZStack {
                    // 环形菜单 - 环绕用户的3D卡片
                    orbitalMenuLayout(in: geometry)
                    
                    // 中央焦点区 - 使用蓝色主题而非深色主题
                    if !isShowingDetail {
                        VStack {
                            Text("FallDetect")
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(.blue)
                                .shadow(color: .blue.opacity(0.4), radius: 10)
                            
                            Text("健康监测应用")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // 详情视图 - 使用白色背景
                    if isShowingDetail {
                        detailContent
                            .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.8)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color.white)
                                    .shadow(color: .gray.opacity(0.2), radius: 30)
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 1.2).combined(with: .opacity)
                            ))
                            .zIndex(100)
                            // 增加空间感的3D变换
                            .rotation3DEffect(
                                .degrees(3),
                                axis: (x: 0.1, y: 0.1, z: 0)
                            )
                    }
                }
            }
            
            // 底部快捷控制区 - 浮在用户前方
            VStack {
                Spacer()
                
                if !isShowingDetail {
                    HStack(spacing: 50) {
                        SpaceActionButton(title: "Start Monitoring", icon: "play.fill", color: .blue) {
                            selectedTab = 0
                            showDetailView(AnyView(FallDetectionView()))
                        }
                        
                        SpaceActionButton(title: "Settings", icon: "gearshape.fill", color: .green) {
                            selectedTab = 1
                            showDetailView(AnyView(SettingsView()))
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.black.opacity(0.3))
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 25)
                            )
                            .shadow(color: .white.opacity(0.1), radius: 10, y: -5)
                    )
                    .padding(.bottom, 30)
                }
            }
            
            // 返回按钮
            if isShowingDetail {
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                isShowingDetail = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("返回")
                            }
                            .padding()
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.3))
                                    .background(
                                        .ultraThinMaterial,
                                        in: Capsule()
                                    )
                            )
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .hoverEffect(.lift)
                        
                        Spacer()
                    }
                    .padding(.top, 30)
                    .padding(.leading, 30)
                    
                    Spacer()
                }
                .zIndex(150)
            }
        }
        // 添加空间交互
        .onAppear {
            startAnimations()
        }
        .onChange(of: selectedTab) { _, _ in
            hapticFeedback()
        }
        // 添加视线追踪交互
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                // 根据视线位置调整深度感
                depthOffset = (location.y / UIScreen.main.bounds.height - 0.5) * 20
            case .ended:
                depthOffset = 0
            }
        }
        // 添加手势交互
        .gesture(
            DragGesture()
                .onChanged { value in
                    // 拖动时产生轻微倾斜，增强3D效果
                    let dragX = value.translation.width / UIScreen.main.bounds.width
                    let dragY = value.translation.height / UIScreen.main.bounds.height
                    
                    withAnimation(.spring(response: 0.2)) {
                        orbitalAngle += dragX * 5
                    }
                }
                .onEnded { value in
                    // 计算最近的目标角度以对齐到最近的选项
                    let cardCount = 3
                    let segmentAngle = 360.0 / Double(cardCount)
                    let targetAngle = round(orbitalAngle / segmentAngle) * segmentAngle
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        orbitalAngle = targetAngle
                        selectedTab = Int(((targetAngle.truncatingRemainder(dividingBy: 360)) / segmentAngle).rounded()) % cardCount
                    }
                }
        )
        // 添加3D视角效果
        .dynamicViewModifier { content, geometryProxy in
            content
                .rotation3DEffect(
                    .degrees(depthOffset * 0.1),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .center,
                    anchorZ: 0,
                    perspective: 0.3
                )
        }
        .preferredColorScheme(.light) // 强制整个视图使用浅色模式
    }
    
    // 环形菜单布局
    func orbitalMenuLayout(in geometry: GeometryProxy) -> some View {
        ZStack {
            // 轨道环 - 半透明导轨
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: min(geometry.size.width, geometry.size.height) * 0.75)
                .blur(radius: 2)
            
            // 放置菜单项
            ForEach(0..<3) { index in
                let baseAngle = 120.0 * Double(index)
                let adjustedAngle = baseAngle + orbitalAngle
                let radians = adjustedAngle * .pi / 180.0
                
                let radius = min(geometry.size.width, geometry.size.height) * 0.375
                let xPos = cos(radians) * radius
                let yPos = sin(radians) * radius
                
                let isSelected = selectedTab == index
                let distance = abs(((adjustedAngle.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) - 180).magnitude)
                let opacity = 1.0 - min(distance / 180.0, 0.7)
                let scale = 1.0 - min(distance / 360.0, 0.3)
                
                SpaceCard(
                    title: menuTitles[index],
                    icon: menuIcons[index],
                    description: menuDescriptions[index],
                    color: menuColors[index],
                    isSelected: isSelected,
                    isHovered: hoveredCard == index
                ) {
                    withAnimation(.spring(response: 0.5)) {
                        selectedTab = index
                        showDetailView(detailViews[index])
                    }
                }
                .frame(width: 220 * scale, height: 220 * scale)
                .position(x: geometry.size.width / 2 + xPos, y: geometry.size.height / 2 + yPos)
                .opacity(opacity)
                .scaleEffect(scale)
                .zIndex(isSelected ? 10 : 1)
                .rotation3DEffect(
                    .degrees(adjustedAngle),
                    axis: (x: 0, y: 1, z: 0.2),
                    perspective: 0.3
                )
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3)) {
                        hoveredCard = hovering ? index : nil
                    }
                }
            }
        }
    }
    
    // 空间卡片 - 带有体积感的3D卡片
    struct SpaceCard: View {
        @Environment(\.colorScheme) private var colorScheme
        let title: String
        let icon: String
        let description: String
        let color: Color
        let isSelected: Bool
        let isHovered: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                // 前景卡面
                VStack(spacing: 15) {
                    // 浮动图标层
                    ZStack {
                        // 背景光晕
                        Circle()
                            .fill(color.opacity(0.3))
                            .frame(width: 90, height: 90)
                            .blur(radius: 10)
                        
                        // 前景图标
                        Image(systemName: icon)
                            .font(.system(size: 40))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(color)
                            .shadow(color: color.opacity(0.4), radius: 5)
                    }
                    // 悬浮效果
                    .offset(z: isHovered || isSelected ? 20 : 10)
                    
                    // 文本内容层
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    ZStack {
                        // 深度背景 - 适合白色主题
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.8))
                            .offset(z: -5)
                        
                        // 表面材质 - 玻璃效果，适合浅色主题
                        RoundedRectangle(cornerRadius: 25)
                            .fill(color.opacity(0.1))
                            .background(
                                .regularMaterial,  // 使用常规材质而非ultraThinMaterial
                                in: RoundedRectangle(cornerRadius: 25)
                            )
                        
                        // 光泽边缘 - 调整颜色使其在白色背景上明显
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        color.opacity(isSelected || isHovered ? 0.7 : 0.3),
                                        color.opacity(isSelected || isHovered ? 0.3 : 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected || isHovered ? 2.5 : 1.5
                            )
                    }
                )
                // 卡片阴影 - 适合白色背景
                .shadow(color: color.opacity(isSelected || isHovered ? 0.4 : 0.1), radius: isSelected || isHovered ? 15 : 5)
                // 卡片悬停状态
                .scaleEffect(isHovered ? 1.08 : 1.0)
                .scaleEffect(isSelected ? 1.12 : 1.0)
            }
            .buttonStyle(.plain)
            // 附加3D深度悬浮效果
            .offset(z: isHovered || isSelected ? 40 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isSelected)
        }
    }
    
    // 空间操作按钮
    struct SpaceActionButton: View {
        let title: String
        let icon: String
        let color: Color
        let action: () -> Void
        @State private var isHovered = false
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 10) {
                    // 图标部分
                    ZStack {
                        // 背景光晕 - 创造立体感
                        Circle()
                            .fill(color.opacity(0.5))
                            .frame(width: 60, height: 60)
                            .blur(radius: 10)
                            .offset(z: -5)
                        
                        // 按钮表面 - 带有深度和质感
                        Circle()
                            .fill(color)
                            .frame(width: 50, height: 50)
                            .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.8), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                        
                        // 图标
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .offset(z: isHovered ? 15 : 0)
                    
                    // 标题
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            // 悬停效果
            .scaleEffect(isHovered ? 1.15 : 1.0)
            .shadow(color: color.opacity(isHovered ? 0.6 : 0.3), radius: isHovered ? 15 : 5)
            .animation(.spring(response: 0.3), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
        }
    }
    
    // 背景星云效果
    struct SpaceNebulaBackground: View {
        @State private var phase: Double = 0
        private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
        
        var body: some View {
            TimelineView(.animation) { timeline in
                ZStack {
                    // 深空背景 - 根据模式自适应
                    Color(.systemBackground)  // 替代固定的黑色
                    
                    // 星云渐变层
                    ForEach(0..<3) { index in
                        NebulaLayer(
                            phase: phase + Double(index) * 0.2,
                            color1: index == 0 ? .blue : (index == 1 ? .purple : .indigo),
                            color2: index == 0 ? .teal : (index == 1 ? .blue : .cyan)
                        )
                        .blendMode(.screen)
                        .opacity(0.3 + Double(index) * 0.1)
                    }
                    
                    // 星星层
                    StarsLayer(phase: phase)
                        .blendMode(.screen)
                        .opacity(0.7)
                }
                .onReceive(timer) { _ in
                    withAnimation(.linear(duration: 0.05)) {
                        phase += 0.002
                    }
                }
            }
        }
    }
    
    // 星云层
    struct NebulaLayer: View {
        let phase: Double
        let color1: Color
        let color2: Color
        
        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                Canvas { context, size in
                    // 创建多层云状效果
                    for i in 1...5 {
                        let offset = sin(phase * Double.pi * 2 + Double(i)) * 50
                        let xPos = width / 2 + offset
                        let yPos = height / 2 + offset * cos(Double(i))
                        
                        let radius = min(width, height) * (0.3 + Double(i) * 0.1) * (0.8 + sin(phase + Double(i)) * 0.2)
                        
                        let path = Path { path in
                            path.addEllipse(in: CGRect(x: xPos - radius / 2, y: yPos - radius / 2, width: radius, height: radius))
                        }
                        
                        // 创建径向渐变效果
                        let gradient = Gradient(colors: [color1.opacity(0.4 - Double(i) * 0.05), color2.opacity(0.0)])
                        let shading = GraphicsContext.Shading.radialGradient(gradient, center: CGPoint(x: xPos, y: yPos), startRadius: 0, endRadius: radius)
                        
                        context.fill(path, with: shading)
                    }
                }
            }
        }
    }
    
    // 星星层
    struct StarsLayer: View {
        let phase: Double
        @State private var stars: [Star] = generateStars(count: 200)
        
        var body: some View {
            GeometryReader { geometry in
                Canvas { context, size in
                    for star in stars {
                        // 计算星星的位置和闪烁效果
                        let x = size.width * star.position.x
                        let y = size.height * star.position.y
                        let brightness = 0.3 + (sin(phase * 2 * .pi + star.flickerOffset) + 1) / 2 * 0.7
                        
                        // 绘制星星
                        let rect = CGRect(x: x - star.size / 2, y: y - star.size / 2, width: star.size, height: star.size)
                        let path = Path(ellipseIn: rect)
                        
                        context.addFilter(.blur(radius: star.size * 0.8))
                        context.fill(path, with: .color(star.color.opacity(brightness)))
                    }
                }
            }
        }
    }
    
    // 漂浮元素视图
    struct FloatingElementView: View {
        let element: FloatingElement
        @State private var phase: Double = 0
        @State private var isAppearing = false
        private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
        
        var body: some View {
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height / 2
                
                // 计算基于相位的位置
                let xOffset = sin(phase * element.speedFactor) * element.orbitRadius.width * size / 2
                let yOffset = cos(phase * element.speedFactor) * element.orbitRadius.height * size / 2
                let zOffset = sin(phase * element.speedFactor * 0.5) * 100
                
                // 漂浮元素
                element.icon
                    .font(.system(size: element.size))
                    .foregroundColor(element.color.opacity(0.2 + abs(sin(phase * 2)) * 0.3))
                    .shadow(color: element.color.opacity(0.5), radius: 10)
                    .position(x: centerX + xOffset, y: centerY + yOffset)
                    .offset(z: zOffset)
                    .scaleEffect(isAppearing ? 1.0 : 0.1)
                    .opacity(isAppearing ? 1.0 : 0)
                    .blendMode(.screen)
                    .onAppear {
                        // 随机初始相位
                        phase = Double.random(in: 0...1)
                        
                        // 出现动画
                        withAnimation(.easeInOut(duration: 1.5).delay(Double.random(in: 0...1.5))) {
                            isAppearing = true
                        }
                    }
                    .onReceive(timer) { _ in
                        // 恒定移动
                        phase += 0.01
                    }
            }
        }
    }
    
    // 漂浮元素数据结构
    struct FloatingElement: Identifiable {
        let id = UUID()
        let icon: Image
        let color: Color
        let size: CGFloat
        let orbitRadius: CGSize
        let speedFactor: Double
    }
    
    // 生成漂浮元素
    static func generateFloatingElements() -> [FloatingElement] {
        let icons = [
            "waveform", "heart", "brain.head.profile", 
            "figure.walk", "bubble.left", "star", 
            "drop", "leaf", "snowflake", "sun.max.stars"
        ]
        
        // 针对白色背景使用深色系颜色
        let colors: [Color] = [.blue, .indigo, .purple, .teal, .gray]
        
        var elements: [FloatingElement] = []
        
        for _ in 1...15 {
            let icon = icons.randomElement()!
            let color = colors.randomElement()!
            let size = CGFloat.random(in: 20...50)
            let orbitWidth = CGFloat.random(in: 0.3...0.9)
            let orbitHeight = CGFloat.random(in: 0.3...0.9)
            let speed = Double.random(in: 0.2...1.0)
            
            elements.append(
                FloatingElement(
                    icon: Image(systemName: icon),
                    color: color,
                    size: size,
                    orbitRadius: CGSize(width: orbitWidth, height: orbitHeight),
                    speedFactor: speed
                )
            )
        }
        
        return elements
    }
    
    // 星星数据结构
    struct Star {
        let position: CGPoint
        let size: CGFloat
        let color: Color
        let flickerOffset: Double
    }
    
    // 生成星星
    static func generateStars(count: Int) -> [Star] {
        var stars: [Star] = []
        
        for _ in 0..<count {
            let x = CGFloat.random(in: 0...1)
            let y = CGFloat.random(in: 0...1)
            let size = CGFloat.random(in: 1...3)
            
            // 随机选择星星颜色
            let colors: [Color] = [.white, .blue.opacity(0.8), .cyan.opacity(0.8)]
            let color = colors.randomElement()!
            
            // 随机闪烁偏移
            let flickerOffset = Double.random(in: 0...2 * .pi)
            
            stars.append(Star(position: CGPoint(x: x, y: y), size: size, color: color, flickerOffset: flickerOffset))
        }
        
        return stars
    }
    
    // 菜单数据
    private var menuTitles = ["Fall Detection", "Settings"]
    private var menuIcons = ["figure.fall.circle.fill", "gearshape.fill"]
    private var menuColors: [Color] = [.red, .orange]
    private var menuDescriptions = [
        "Real-time monitoring of body status, detecting accidental falls",
        "Customize app features and notification settings"
    ]
    
    // 详情视图数组
    private var detailViews: [AnyView] {
        [
            AnyView(FallDetectionView()),
            AnyView(SettingsView())
        ]
    }
    
    private func showDetailView(_ view: AnyView) {
        detailContent = view
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            isShowingDetail = true
        }
    }
    
    private func updateDetailView() {
        switch selectedTab {
        case 0:
            showDetailView(AnyView(FallDetectionView()))
        case 1:
            showDetailView(AnyView(SettingsView()))
        default:
            break
        }
    }
    
    private func startAnimations() {
        // 启动轨道旋转动画
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
    }
    
    private func hapticFeedback() {
        // 在实际应用中提供触觉反馈
        // UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    #endif
    
    // iPhone和iPad的自适应布局
    var deviceAdaptiveLayout: some View {
        DeviceAdaptiveView {
            // 紧凑视图（iPhone）
            TabView(selection: $selectedTabiOS) {
                FallDetectionView()
                    .tag(0)
                    .tabItem {
                        Label("Fall Detection", systemImage: "camera.fill")
                    }
                    .id("fallDetection")
                
                SettingsView()
                    .tag(1)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .id("settings")
            }
            .accentColor(.blue)
        } regularContent: {
            // 宽视图（iPad）
            TabView {
                FallDetectionView()
                    .tabItem {
                        Label("Fall Detection", systemImage: "camera.fill")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .accentColor(.blue)
            .tabViewStyle(.automatic)
            .font(.title3)
            .symbolRenderingMode(.hierarchical)
        }
    }
}

// 设备适配视图容器
struct DeviceAdaptiveView<CompactContent: View, RegularContent: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var compactContent: () -> CompactContent
    var regularContent: () -> RegularContent
    
    init(@ViewBuilder compactContent: @escaping () -> CompactContent,
         @ViewBuilder regularContent: @escaping () -> RegularContent) {
        self.compactContent = compactContent
        self.regularContent = regularContent
    }
    
    var body: some View {
        if horizontalSizeClass == .compact {
            compactContent()
        } else {
            regularContent()
        }
    }
}

// 平台检测
extension View {
    func onVisionOS<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(visionOS)
        return content()
        #else
        return self
        #endif
    }
    
    func oniOS<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(iOS)
        return content()
        #else
        return self
        #endif
    }
}

// 动态视图修饰器 - 用于复杂视觉效果
#if os(visionOS)
struct DynamicViewModifier: ViewModifier {
    let modifier: (Content, GeometryProxy) -> some View
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            self.modifier(content, geometry)
        }
    }
}

extension View {
    func dynamicViewModifier<Result: View>(_ modifier: @escaping (Self, GeometryProxy) -> Result) -> some View {
        return DynamicViewModifier { content, geometry in
            modifier(content as! Self, geometry)
        }.body(content: self)
    }
}
#endif

#Preview {
    ContentView()
}
