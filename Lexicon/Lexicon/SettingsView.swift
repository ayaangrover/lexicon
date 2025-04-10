//
//  SettingsView.swift
//  Lexicon
//
//  Created by Ayaan Grover on 4/3/25.
//


import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Settings")
                    .font(.largeTitle)
                    .padding()
                // Add settings options here
                Spacer()
            }
            .navigationBarTitle("Settings", displayMode: .inline)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}