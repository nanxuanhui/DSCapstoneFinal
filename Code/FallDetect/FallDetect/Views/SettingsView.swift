//
//  SettingsView.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import SwiftUI
import SwiftData
import UserNotifications
import AVFoundation
#if os(visionOS)
import RealityKit
#endif

// Class for global font size management
class FontSizeManager: ObservableObject {
    @Published var sizeMultiplier: CGFloat
    
    static let shared = FontSizeManager()
    
    init() {
        let savedIndex = UserDefaults.standard.integer(forKey: "fontSizeIndex")
        self.sizeMultiplier = Self.getMultiplier(for: savedIndex)
    }
    
    static func getMultiplier(for index: Int) -> CGFloat {
        switch index {
        case 0: return 0.85  // Small
        case 1: return 1.0   // Medium (default)
        case 2: return 1.15  // Large
        case 3: return 1.3   // Extra Large
        default: return 1.0
        }
    }
    
    func updateSize(index: Int) {
        self.sizeMultiplier = Self.getMultiplier(for: index)
        UserDefaults.standard.set(index, forKey: "fontSizeIndex")
    }
}

// 扩展字体修饰符
extension View {
    func dynamicFontSize(style: Font.TextStyle) -> some View {
        self.modifier(DynamicFontSizeModifier(style: style))
    }
}

// 字体大小修饰器 - 修复版本
struct DynamicFontSizeModifier: ViewModifier {
    @ObservedObject private var fontSizeManager = FontSizeManager.shared
    let style: Font.TextStyle
    
    func body(content: Content) -> some View {
        content
            .font(getFont(for: style))
    }
    
    private func getFont(for style: Font.TextStyle) -> Font {
        // 根据字体样式和缩放比例返回合适的字体
        switch style {
        case .largeTitle:
            return .system(size: 34 * fontSizeManager.sizeMultiplier, weight: .bold)
        case .title:
            return .system(size: 28 * fontSizeManager.sizeMultiplier, weight: .semibold)
        case .title2:
            return .system(size: 22 * fontSizeManager.sizeMultiplier, weight: .semibold)
        case .title3:
            return .system(size: 20 * fontSizeManager.sizeMultiplier, weight: .semibold)
        case .headline:
            return .system(size: 17 * fontSizeManager.sizeMultiplier, weight: .semibold)
        case .body:
            return .system(size: 17 * fontSizeManager.sizeMultiplier)
        case .callout:
            return .system(size: 16 * fontSizeManager.sizeMultiplier)
        case .subheadline:
            return .system(size: 15 * fontSizeManager.sizeMultiplier)
        case .footnote:
            return .system(size: 13 * fontSizeManager.sizeMultiplier)
        case .caption:
            return .system(size: 12 * fontSizeManager.sizeMultiplier)
        case .caption2:
            return .system(size: 11 * fontSizeManager.sizeMultiplier)
        @unknown default:
            return .system(size: 17 * fontSizeManager.sizeMultiplier)
        }
    }
}

struct SettingsView: View {
    @State private var preferredColorScheme: Int = UserDefaults.standard.integer(forKey: "preferredColorScheme")
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("vibrationEnabled") private var vibrationEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("emergencyContactsEnabled") private var emergencyContactsEnabled: Bool = true
    @AppStorage("fontSizeIndex") private var fontSizeIndex: Int = 1 // 0:Small 1:Medium 2:Large 3:Extra Large
    @AppStorage("accentColorIndex") private var accentColorIndex: Int = 0 // 0:Blue 1:Green 2:Purple 3:Orange
    @AppStorage("cameraAccess") private var cameraAccess: Bool = true
    @AppStorage("microphoneAccess") private var microphoneAccess: Bool = true
    @AppStorage("locationAccess") private var locationAccess: Bool = true
    @AppStorage("dataAnalysis") private var dataAnalysis: Bool = false
    
    @ObservedObject private var fontSizeManager = FontSizeManager.shared
    
    @State private var activeColorScheme: ColorScheme? = nil
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad || ProcessInfo.processInfo.isiOSAppOnMac {
                // iPad and Vision Pro interface - using clean grid layout
                simpleGridLayout
            } else {
                // iPhone interface - using grouped form
                iPhoneLayout
            }
        }
        .preferredColorScheme(activeColorScheme)
        .onAppear {
            // Ensure fontSizeIndex is synchronized with FontSizeManager
            fontSizeManager.updateSize(index: fontSizeIndex)
            applyColorScheme(preferredColorScheme)
        }
    }
    
    private func applyColorScheme(_ value: Int) {
        switch value {
        case 1:  // Light
            activeColorScheme = .light
        case 2:  // Dark
            activeColorScheme = .dark
        default: // System
            activeColorScheme = nil
        }
        UserDefaults.standard.set(value, forKey: "preferredColorScheme")
    }
    
    // Clean grid layout for iPad and Vision Pro
    var simpleGridLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Page title
                Text("Settings")
                    .dynamicFontSize(style: .largeTitle)
                    .bold()
                    .padding(.top)
                
                // Settings groups
                settingsGroupView(title: "Notification Settings") {
                    SimpleToggleRow(title: "Enable Notifications", isOn: $notificationsEnabled)
                    SimpleToggleRow(title: "Vibration Alerts", isOn: $vibrationEnabled)
                    SimpleToggleRow(title: "Sound Alerts", isOn: $soundEnabled)
                    SimpleToggleRow(title: "Emergency Contact Notifications", isOn: $emergencyContactsEnabled)
                }
                
                #if !os(visionOS)
                settingsGroupView(title: "Appearance") {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Theme")
                            .dynamicFontSize(style: .headline)
                        
                        Picker("", selection: Binding(
                            get: { self.preferredColorScheme },
                            set: { newValue in
                                self.preferredColorScheme = newValue
                                self.applyColorScheme(newValue)
                            }
                        )) {
                            Text("System").tag(0)
                            Text("Light").tag(1)
                            Text("Dark").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Text("Font Size")
                            .dynamicFontSize(style: .headline)
                            .padding(.top, 5)
                        
                        Picker("", selection: Binding(
                            get: { self.fontSizeIndex },
                            set: { newValue in
                                self.fontSizeIndex = newValue
                                self.fontSizeManager.updateSize(index: newValue)
                            }
                        )) {
                            Text("Small").tag(0)
                            Text("Medium").tag(1)
                            Text("Large").tag(2)
                            Text("Extra Large").tag(3)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.vertical, 5)
                }
                #endif
                
                settingsGroupView(title: "Privacy") {
                    SimpleToggleRow(title: "Camera Access", isOn: $cameraAccess)
                    SimpleToggleRow(title: "Microphone Access", isOn: $microphoneAccess)
                    SimpleToggleRow(title: "Location Access", isOn: $locationAccess)
                    SimpleToggleRow(title: "Data Analysis", isOn: $dataAnalysis)
                    
                    Button(action: {}) {
                        Text("Delete All Data")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                    .padding(.top, 5)
                }
                
                // App data section
                settingsGroupView(title: "App Data") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Fall Detection Storage: 24.5 MB")
                            .dynamicFontSize(style: .body)
                        Text("Other Cache Files: 5.2 MB")
                            .dynamicFontSize(style: .body)
                    }
                    .padding(.vertical, 5)
                    
                    Button(action: {}) {
                        Text("Clear Cache")
                            .dynamicFontSize(style: .body)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                    .padding(.top, 5)
                }
                
                // Support section
                settingsGroupView(title: "Support") {
                    Button(action: {}) {
                        HStack {
                            Text("Help Center")
                                .dynamicFontSize(style: .body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)
                    
                    Button(action: {}) {
                        HStack {
                            Text("Contact Support")
                                .dynamicFontSize(style: .body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)
                    
                    Button(action: {}) {
                        HStack {
                            Text("About")
                                .dynamicFontSize(style: .body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                // Version info
                Text("Version 1.0.0")
                    .dynamicFontSize(style: .footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            }
            .padding()
        }
    }
    
    // iPhone layout using grouped form
    var iPhoneLayout: some View {
        Form {
            Section(header: Text("Notifications")) {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                Toggle("Vibration Alerts", isOn: $vibrationEnabled)
                Toggle("Sound Alerts", isOn: $soundEnabled)
                Toggle("Emergency Contact Notifications", isOn: $emergencyContactsEnabled)
            }
            
            #if !os(visionOS)
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: Binding(
                    get: { self.preferredColorScheme },
                    set: { newValue in
                        self.preferredColorScheme = newValue
                        self.applyColorScheme(newValue)
                    }
                )) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                
                Picker("Font Size", selection: Binding(
                    get: { self.fontSizeIndex },
                    set: { newValue in
                        self.fontSizeIndex = newValue
                        self.fontSizeManager.updateSize(index: newValue)
                    }
                )) {
                    Text("Small").tag(0)
                    Text("Medium").tag(1)
                    Text("Large").tag(2)
                    Text("Extra Large").tag(3)
                }
            }
            #endif
            
            Section(header: Text("Privacy")) {
                Toggle("Camera Access", isOn: $cameraAccess)
                Toggle("Microphone Access", isOn: $microphoneAccess)
                Toggle("Location Access", isOn: $locationAccess)
                Toggle("Data Analysis", isOn: $dataAnalysis)
                
                Button("Delete All Data", role: .destructive) {}
            }
            
            Section(header: Text("App Data")) {
                HStack {
                    Text("Fall Detection Storage")
                    Spacer()
                    Text("24.5 MB")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Other Cache Files")
                    Spacer()
                    Text("5.2 MB")
                        .foregroundColor(.gray)
                }
                
                Button("Clear Cache") {}
            }
            
            Section(header: Text("Support")) {
                NavigationLink("Help Center") {}
                NavigationLink("Contact Support") {}
                NavigationLink("About") {}
            }
            
            Section {
                HStack {
                    Spacer()
                    Text("Version 1.0.0")
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
        .navigationTitle("Settings")
    }
    
    // Settings group view
    func settingsGroupView<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .dynamicFontSize(style: .headline)
                .padding(.top, 5)
            
            VStack(spacing: 12) {
                content()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}

// Simple toggle row
struct SimpleToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .dynamicFontSize(style: .body)
    }
}

// 判断是否在Vision Pro上运行的扩展
extension ProcessInfo {
    var isiOSAppOnMac: Bool {
        #if os(visionOS)
        return true
        #else
        return false
        #endif
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

// 在相机管理器类中
class CameraManager {
    private var captureSession: AVCaptureSession?
    
    func setupCamera() {
        #if os(visionOS)
        // Vision Pro 摄像头设置
        setupVisionProCamera()
        #else
        // iOS/iPad 摄像头设置 - 仅使用后置摄像头
        setupMobileCamera()
        #endif
    }
    
    #if os(visionOS)
    private func setupVisionProCamera() {
        // Vision Pro 直接使用系统摄像头，不需要指定位置
        let session = AVCaptureSession()
        
        // 查找任何可用摄像头设备
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            print("无法访问摄像头")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            
            // 配置其余会话设置...
            self.captureSession = session
        } catch {
            print("摄像头设置错误: \(error)")
        }
    }
    #else
    private func setupMobileCamera() {
        // iOS/iPad - 仅使用后置摄像头
        let session = AVCaptureSession()
        
        // 明确请求后置广角摄像头
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back // 仅指定后置摄像头
        )
        
        guard let device = deviceDiscoverySession.devices.first else {
            print("无法找到后置摄像头")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            
            // 配置其余会话设置...
            self.captureSession = session
        } catch {
            print("摄像头设置错误: \(error)")
        }
    }
    #endif
    
    // 其余摄像头管理方法...
} 