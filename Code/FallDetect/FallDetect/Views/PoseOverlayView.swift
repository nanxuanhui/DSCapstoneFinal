import SwiftUI
import AVFoundation

struct PoseOverlayView: View {
    let pose: Pose?
    let viewSize: CGSize
    
    var body: some View {
        if let pose = pose {
            Canvas { context, size in
                // 绘制骨骼连接
                drawSkeleton(context: context, size: size, pose: pose)
                
                // 绘制关键点
                drawKeypoints(context: context, size: size, pose: pose)
            }
            .frame(width: viewSize.width, height: viewSize.height)
        }
    }
    
    // 绘制骨骼连接线
    private func drawSkeleton(context: GraphicsContext, size: CGSize, pose: Pose) {
        // 定义骨骼连接线
        let connections: [(Keypoint?, Keypoint?)] = [
            // 头部到颈部
            (pose.nose, pose.neck),
            
            // 上半身
            (pose.neck, pose.leftShoulder),
            (pose.neck, pose.rightShoulder),
            (pose.leftShoulder, pose.leftElbow),
            (pose.leftElbow, pose.leftWrist),
            (pose.rightShoulder, pose.rightElbow),
            (pose.rightElbow, pose.rightWrist),
            
            // 躯干
            (pose.neck, pose.leftHip),
            (pose.neck, pose.rightHip),
            (pose.leftHip, pose.rightHip),
            
            // 下半身
            (pose.leftHip, pose.leftKnee),
            (pose.leftKnee, pose.leftAnkle),
            (pose.rightHip, pose.rightKnee),
            (pose.rightKnee, pose.rightAnkle)
        ]
        
        // 绘制每条连接线
        for (start, end) in connections {
            guard let start = start, start.isValid, let end = end, end.isValid else {
                continue
            }
            
            // 将关键点坐标从比例(0-1)转换为实际像素
            let startX = start.position.x * size.width
            let startY = start.position.y * size.height
            let endX = end.position.x * size.width
            let endY = end.position.y * size.height
            
            // 创建路径
            var path = Path()
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
            
            // 绘制线条
            context.stroke(
                path,
                with: .color(Color.green),
                lineWidth: 3
            )
        }
    }
    
    // 绘制关键点
    private func drawKeypoints(context: GraphicsContext, size: CGSize, pose: Pose) {
        // 获取所有关键点
        let keypoints: [Keypoint?] = [
            pose.nose, pose.neck, 
            pose.leftShoulder, pose.rightShoulder,
            pose.leftElbow, pose.rightElbow,
            pose.leftWrist, pose.rightWrist,
            pose.leftHip, pose.rightHip,
            pose.leftKnee, pose.rightKnee,
            pose.leftAnkle, pose.rightAnkle,
            pose.leftEye, pose.rightEye,
            pose.leftEar, pose.rightEar
        ]
        
        // 绘制每个关键点
        for keypoint in keypoints {
            guard let keypoint = keypoint, keypoint.isValid else {
                continue
            }
            
            // 将关键点坐标从比例(0-1)转换为实际像素
            let x = keypoint.position.x * size.width
            let y = keypoint.position.y * size.height
            
            // 创建圆形路径
            let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
            let circlePath = Path(ellipseIn: rect)
            
            // 根据置信度调整颜色
            let color = Color(
                red: 1.0,
                green: Double(keypoint.confidence),
                blue: 0
            )
            
            // 绘制关键点
            context.fill(circlePath, with: .color(color))
        }
    }
} 