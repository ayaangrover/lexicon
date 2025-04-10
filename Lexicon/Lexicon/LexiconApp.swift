//
//  LexiconApp.swift
//  Lexicon
//
//  Created by Ayaan Grover on 3/29/25.
//

import SwiftUI
import FirebaseCore

@main
struct LexiconApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
