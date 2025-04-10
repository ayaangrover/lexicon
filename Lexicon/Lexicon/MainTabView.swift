import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            AppView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            ChatView()
                .tabItem {
                    Image(systemName: "message")
                    Text("AI Chat")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}
