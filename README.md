# Fall Detection Algorithm for Elderly People Living Alone Based on ARKit and YOLOv5

## Project Overview
FallDetect is an application designed for elderly people living alone, utilizing ARKit and YOLOv5 for real-time fall detection. By leveraging advanced computer vision technologies, the app monitors the user's activity and promptly alerts in case of a fall.

## Key Features
- Real-time fall detection
- Multi-platform support (iOS, iPadOS, visionOS)
- Immersive spatial experience (visionOS)
- Adaptive user interface
- Real-time health monitoring
- Emergency alert system

## Technical Highlights
- Real-time motion capture based on ARKit
- YOLOv5 object detection algorithm
- Modern UI with SwiftUI
- 3D spatial interaction (visionOS)
- Adaptive layout design
- Real-time data processing

## System Requirements
- iOS 15.0+
- iPadOS 15.0+
- visionOS 1.0+ (partial features)

## Development Environment
- Xcode 15.0+
- Swift 5.9+
- SwiftUI
- ARKit
- RealityKit (visionOS)

## Project Structure
```
FallDetect/
├── FallDetect/
│   ├── Views/          # View components
│   ├── Model/          # Data models
│   ├── Models/         # Business logic models
│   └── Assets.xcassets # Asset files
├── FallDetectTests/    # Unit tests
└── FallDetectUITests/  # UI tests
```

## Installation Guide

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd FallDetect
   ```

2. **Open the project in Xcode**  
   Open `FallDetect.xcodeproj` or `FallDetect.xcworkspace` with Xcode.

3. **Install dependencies**  
   If you are using CocoaPods, run:
   ```bash
   pod install
   ```
   If you are using Swift Package Manager, dependencies will be resolved automatically by Xcode.

4. **Build and run the project**  
   Select your target device (iPhone, iPad, or visionOS simulator) and click the Run button in Xcode.

5. **Grant camera and motion permissions**  
   The app requires camera and motion access. Please allow these permissions when prompted.

## Usage Instructions
1. Launch the app and select "Start Monitoring" to begin fall detection.
2. Adjust detection sensitivity and other parameters in the settings.
3. The system will automatically monitor the user's activity.
4. An alert will be triggered automatically if a fall is detected.

## Notes
- Camera permission is required on first use.
- It is recommended to use the app in well-lit environments.
- Ensure the device has sufficient storage and battery.

## Team Members & Contributions

- **Saniya Pandita** (UI Developer)  
  Responsible for UI design and user experience optimization, developed adaptive UI for multiple platforms, and improved overall interaction and usability.

- **Jayadithya Nalajala** (Full Stack Developer)  
  Responsible for overall application architecture and front-end/back-end integration, implemented data flow, module integration, and system performance optimization.

- **Sai Jahnavi Devabhakthuni** (ML and Data Engineer)  
  Responsible for YOLOv5 model training and integration, developed the fall detection algorithm, and built the data processing pipeline.

- **Hui Jin** (AI Developer)  
  Responsible for integrating ARKit with AI algorithms, implemented real-time motion capture and fall event recognition, and contributed to the core functionality.