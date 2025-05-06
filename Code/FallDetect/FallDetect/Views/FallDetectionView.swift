//
//  FallDetectionView.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import SwiftUI
import AVFoundation
import Vision

struct FallDetectionView: View {
    @StateObject private var viewModel = FallDetectionViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        PlatformAdaptiveView {
            // iOS device view
            ZStack {
                // Video preview layer
                VideoPreviewView(viewModel: viewModel)
                    .ignoresSafeArea()
                
                // Top status bar
                VStack {
                    HStack {
                        Spacer()
                        
                        if viewModel.isDetecting {
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                
                                Text("Detecting")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Record button
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            viewModel.toggleDetection()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.isDetecting ? Color.red : Color.blue)
                                    .frame(width: 70, height: 70)
                                
                                if viewModel.isDetecting {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 80, height: 80)
                                }
                            }
                        }
                        .padding(.trailing, 30)
                        .padding(.bottom, 40)
                    }
                }
                
                // Fall alert overlay
                if viewModel.fallDetected {
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            
                            VStack(spacing: 20) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                
                                Text("Fall Detected!")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Do you need emergency contact help?")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 30) {
                                    Button("Cancel Alert") {
                                        viewModel.cancelFallAlert()
                                    }
                                    .padding()
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    
                                    Button("Request Help") {
                                        viewModel.requestHelp()
                                    }
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(30)
                            .frame(width: geometry.size.width * 0.9)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(20)
                            
                            Spacer()
                        }
                        .frame(width: geometry.size.width)
                        .background(Color.red.opacity(0.3))
                    }
                }
            }
        } visionContent: {
            // Vision Pro specific view
            VStack {
                Text("Fall Detection - Vision Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.1))
                    
                    VStack(spacing: 30) {
                        HStack {
                            Spacer()
                            
                            VStack {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 40))
                                Text("Video Preview")
                            }
                            .frame(width: 340, height: 300)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(16)
                            
                            Spacer()
                        }
                        
                        Button(action: {
                            viewModel.toggleDetection()
                        }) {
                            Label(
                                viewModel.isDetecting ? "Stop Detection" : "Start Detection",
                                systemImage: viewModel.isDetecting ? "stop.fill" : "play.fill"
                            )
                            .font(.headline)
                            .padding()
                            .frame(width: 200)
                            .background(viewModel.isDetecting ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                .frame(height: 400)
                .padding()
                
                // Status panel
                VStack(alignment: .leading, spacing: 16) {
                    Text("Detection Status:")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(viewModel.isDetecting ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        
                        Text(viewModel.isDetecting ? "Monitoring" : "Not Monitoring")
                            .foregroundColor(viewModel.isDetecting ? .primary : .secondary)
                    }
                    
                    if viewModel.fallDetected {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            
                            Text("Fall Detected!")
                                .foregroundColor(.red)
                                .fontWeight(.bold)
                            
                            Button("Request Help") {
                                viewModel.requestHelp()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            Button("Cancel Alert") {
                                viewModel.cancelFallAlert()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(16)
                .padding()
            }
        }
    }
}

// Video preview view
struct VideoPreviewView: UIViewRepresentable {
    @ObservedObject var viewModel: FallDetectionViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        print("创建视频预览视图")
        
        if let playerLayer = viewModel.playerLayer {
            print("设置播放层")
            playerLayer.frame = view.frame
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            view.layer.addSublayer(playerLayer)
            print("播放层已添加到视图")
        } else {
            print("播放层为空")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        print("更新视频预览视图")
        if let playerLayer = viewModel.playerLayer {
            playerLayer.frame = uiView.frame
            print("更新播放层frame")
        }
    }
}

struct PlatformAdaptiveView<IOSContent: View, VisionContent: View>: View {
    var iosContent: () -> IOSContent
    var visionContent: () -> VisionContent
    
    init(@ViewBuilder iosContent: @escaping () -> IOSContent,
         @ViewBuilder visionContent: @escaping () -> VisionContent) {
        self.iosContent = iosContent
        self.visionContent = visionContent
    }
    
    var body: some View {
        #if os(visionOS)
        visionContent()
        #else
        iosContent()
        #endif
    }
}

// Camera preview view
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// 其他需要的视图和助手类...
