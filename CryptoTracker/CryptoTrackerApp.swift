//
//  CryptoTrackerApp.swift
//  CryptoTracker
//
//  Created by Gokula on 01/11/23.
//

import SwiftUI

@main
struct CryptoTrackerApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            EmptyView().frame(width: 0, height: 0)
        }
    }
}
