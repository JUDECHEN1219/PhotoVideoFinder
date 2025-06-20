//
//  NewVideoApp.swift
//  NewVideo
//
//  Created by Shaojun Chen on 6/19/25.
//

import SwiftUI

@main
struct NewVideoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: ThumbnailCache.self)
        }
    }
}
