import SwiftUI

struct ContentView: View {
    @StateObject private var state  = AppState()
    @StateObject private var engine: AgentEngine
    @State private var selectedTab  = 0
    @State private var showConfig   = false

    init() {
        let s = AppState()
        _state  = StateObject(wrappedValue: s)
        _engine = StateObject(wrappedValue: AgentEngine(state: s))
        // Custom tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.027, green: 0.035, blue: 0.051, alpha: 0.97)
        appearance.shadowColor = UIColor(red: 0.08, green: 0.12, blue: 0.16, alpha: 1)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(red: 0, green: 1, blue: 0.53, alpha: 1)
        UITabBar.appearance().unselectedItemTintColor = UIColor(red: 0.23, green: 0.29, blue: 0.36, alpha: 1)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(state: state, engine: engine, selectedTab: $selectedTab)
                .tabItem { Label("Home", systemImage: "hexagon.fill") }
                .tag(0)

            RecorderView(state: state, engine: engine)
                .tabItem { Label("Record", systemImage: "record.circle") }
                .tag(1)

            SurfaceView(state: state, engine: engine)
                .tabItem {
                    Label {
                        Text("Surface")
                    } icon: {
                        Image(systemName: "map.fill")
                    }
                }
                .tag(2)
                .badge(state.endpoints.count + state.components.count > 0 ? state.endpoints.count + state.components.count : 0)

            AgentView(state: state, engine: engine)
                .tabItem { Label("Agent", systemImage: "brain.head.profile") }
                .tag(3)

            FindingsView(state: state, engine: engine)
                .tabItem { Label("Findings", systemImage: "exclamationmark.shield.fill") }
                .tag(4)
                .badge(state.findings.count > 0 ? state.findings.count : 0)
        }
        .sheet(isPresented: $showConfig) {
            ConfigSheet(state: state)
        }
        .onAppear {
            if state.targetPackage.isEmpty { showConfig = true }
        }
    }
}
