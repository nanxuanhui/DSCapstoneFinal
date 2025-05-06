//
//  FallDetectApp.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import SwiftUI
import SwiftData

@main
struct FallDetectApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(visionOS)
                .preferredColorScheme(.light) // Force light mode for Vision Pro
                #endif
        }
    }
}
