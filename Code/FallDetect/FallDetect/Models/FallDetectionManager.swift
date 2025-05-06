//
//  FallDetectionManager.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import Vision
import CoreML
import AVFoundation
import UIKit
import SwiftUI

// 修改类声明，继承自 NSObject
class FallDetectionManager: NSObject {
    static let shared = FallDetectionManager()
    
    private var yoloModel: VNCoreMLModel?
    private var isModelLoaded = false
    
    @AppStorage("fallDetectionSensitivity") private var sensitivity: Double = 0.7
    
    // 将 init 方法修改为覆盖 NSObject 的 init
    private override init() {
        super.init()
        loadModel()
    }
    
    func loadModel() {
        // 加载YOLOv5摔倒检测模型
        guard let modelURL = Bundle.main.url(forResource: "FallDetectionYOLO", withExtension: "mlmodelc") else {
            print("找不到摔倒检测模型")
            return
        }
        
        do {
            let model = try MLModel(contentsOf: modelURL)
            yoloModel = try VNCoreMLModel(for: model)
            isModelLoaded = true
            print("摔倒检测模型加载成功")
        } catch {
            print("加载摔倒检测模型失败: \(error)")
        }
    }
    
    func reloadModel() {
        isModelLoaded = false
        loadModel()
    }
    
    func processFrame(_ pixelBuffer: CVPixelBuffer, completion: @escaping (Bool, Double) -> Void) {
        #if os(visionOS)
        // Vision Pro上的模拟处理逻辑
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            // 随机模拟检测结果
            let shouldDetect = Double.random(in: 0...1) > 0.95
            let confidence = Double.random(in: 0.7...0.95)
            completion(shouldDetect, confidence)
        }
        #else
        // 实际的模型处理
        guard isModelLoaded, let model = yoloModel else {
            completion(false, 0.0)
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation],
                  error == nil else {
                completion(false, 0.0)
                return
            }
            
            // 分析检测结果，确定是否有摔倒
            let (fallDetected, confidence) = self.analyzeFallDetection(results: results)
            completion(fallDetected, confidence)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("执行视觉请求失败: \(error)")
            completion(false, 0.0)
        }
        #endif
    }
    
    private func analyzeFallDetection(results: [VNRecognizedObjectObservation]) -> (Bool, Double) {
        // 分析结果判断是否摔倒
        for observation in results {
            if let firstLabel = observation.labels.first,
               firstLabel.identifier == "fall" && 
               firstLabel.confidence >= Float(sensitivity) {
                return (true, Double(firstLabel.confidence))
            }
        }
        return (false, 0.0)
    }
    
    func captureFrame(from session: AVCaptureSession) -> UIImage? {
        #if os(visionOS)
        // Vision Pro上返回占位图像
        let size = CGSize(width: 1080, height: 1920)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.darkGray.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            let text = "Vision Pro 模拟摔倒图像"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
        #else
        // 正常的截图逻辑
        guard let videoOutput = session.outputs.first as? AVCaptureVideoDataOutput,
              let connection = videoOutput.connection(with: .video) else {
            return nil
        }
        
        let outputRect = CGRect(x: 0, y: 0, width: 1080, height: 1920)
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = outputRect
        
        let captureImage = UIGraphicsImageRenderer(size: outputRect.size).image { context in
            videoPreviewLayer.render(in: context.cgContext)
        }
        
        return captureImage
        #endif
    }
    
    func setupCamera() {
        #if os(visionOS)
        // Vision Pro 特定的相机设置
        // 使用 WorldSensing 框架
        setupVisionProCamera()
        #else
        // 常规 iOS 相机设置
        setupRegularCamera()
        #endif
    }
    
    func setupRegularCamera() {
        // iOS设备的相机设置代码
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // 检查相机权限
        checkCameraPermission { granted in
            guard granted else {
                print("没有相机权限")
                return
            }
            
            // 配置相机输入
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  session.canAddInput(videoInput) else {
                print("无法配置相机输入")
                return
            }
            
            session.addInput(videoInput)
            
            // 配置视频输出
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            
            session.commitConfiguration()
            
            // 开始运行会话
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }
    
    func setupVisionProCamera() {
        #if os(visionOS)
        print("配置 Vision Pro 相机")
        // Vision Pro 相机设置代码
        // 在实际代码中这里应该使用 visionOS 的相关 API
        #else
        print("当前设备不是 Vision Pro，无法使用专用相机配置")
        #endif
    }
    
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }
}

// 现在正确扩展 FallDetectionManager 实现 AVCaptureVideoDataOutputSampleBufferDelegate
extension FallDetectionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 处理视频帧
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // 在这里可以调用已有的 processFrame 方法
        // processFrame(pixelBuffer) { detected, confidence in
        //    // 处理检测结果
        // }
    }
} 