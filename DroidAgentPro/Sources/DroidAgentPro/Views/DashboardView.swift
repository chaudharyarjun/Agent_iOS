import SwiftUI

// MARK: - Dashboard
struct DashboardView: View {
    @ObservedObject var state: AppState
    @ObservedObject var engine: AgentEngine
    @Binding var selectedTab: Int
    @State private var showConfig = false

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    dashboardContent
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("DroidAgent Pro")
            .navigationBarTitleDisplayMode(.inline)
            .navBarBackground(Color(hex: "07090d"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if state.isRunning {
                        StatusPill(text: state.currentPhase, color: .accent, animate: true)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showConfig = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.textMuted)
                            .font(.system(size: 14))
                    }
                }
            }
        }
        .sheet(isPresented: $showConfig) { ConfigSheet(state: state) }
    }

    @ViewBuilder
    private var dashboardContent: some View {
        // Target pill
        if !state.targetPackage.isEmpty {
            targetPill
        }

        // Severity grid
        SectionTitle(text: "Vulnerability Summary")
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            StatBox(value: state.criticalCount, label: "Critical", color: Color(hex: "ff2d55"))
            StatBox(value: state.highCount,     label: "High",     color: Color(hex: "ff6b35"))
            StatBox(value: state.mediumCount,   label: "Medium",   color: Color(hex: "ffcc00"))
            StatBox(value: state.lowCount,      label: "Low",      color: Color(hex: "00d4ff"))
        }

        // Surface grid
        SectionTitle(text: "Attack Surface")
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            StatBox(value: state.endpoints.count,  label: "Endpoints",  color: Color(hex: "00aaff"), size: .small)
            StatBox(value: state.components.count, label: "Components", color: Color(hex: "aa44ff"), size: .small)
            StatBox(value: state.sessions.count,   label: "Sessions",   color: .accent,             size: .small)
            StatBox(value: state.toolCallCount,    label: "Tool Calls", color: Color(hex: "ffaa00"), size: .small)
        }

        // Quick Actions
        SectionTitle(text: "Quick Actions")
        quickActions

        // Recent findings
        if !state.findings.isEmpty {
            SectionTitle(text: "Recent Findings")
            ForEach(state.findings.suffix(3).reversed()) { f in
                FindingRowCard(finding: f)
            }
        }

        // Setup prompt
        if state.targetPackage.isEmpty {
            setupPrompt
        }
    }

    private var targetPill: some View {
        HStack {
            Image(systemName: "target")
                .font(.system(size: 10))
                .foregroundColor(.accent)
            Text(state.targetPackage)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.accent.opacity(0.07))
        .overlay(Capsule().stroke(Color.accent.opacity(0.25), lineWidth: 1))
        .clipShape(Capsule())
    }

    private var quickActions: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                AppButton(
                    title: state.isRecording ? "Stop Rec" : "Record",
                    icon: state.isRecording ? "⏹" : "⏺",
                    style: state.isRecording ? .red : .blue,
                    isFullWidth: true,
                    isDisabled: state.targetPackage.isEmpty
                ) { selectedTab = 1 }

                AppButton(
                    title: state.isRunning ? "Running..." : "Run Agent",
                    icon: state.isRunning ? nil : "▶",
                    style: .green,
                    isFullWidth: true,
                    isDisabled: state.targetPackage.isEmpty || state.isRunning
                ) {
                    Task { await engine.run() }
                    selectedTab = 3
                }
            }
            HStack(spacing: 8) {
                AppButton(title: "Surface Map", icon: "🗺", style: .dim, isFullWidth: true) {
                    selectedTab = 2
                }
                AppButton(title: "Export", icon: "↓", style: .dim, isFullWidth: true) {
                    exportReport()
                }
            }
        }
    }

    private var setupPrompt: some View {
        AppCard(accent: Color(hex: "00aaff")) {
            VStack(alignment: .leading, spacing: 10) {
                Text("⚙ Setup Required")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "00aaff"))
                Text("Configure your suite API endpoint, target package, and Claude API key to begin.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.textMuted)
                    .lineSpacing(4)
                AppButton(title: "Configure", style: .blue, isFullWidth: true) {
                    showConfig = true
                }
            }
        }
    }

    func exportReport() {
        guard let data = state.exportReport() else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(state.targetPackage)_pentest.json")
        try? data.write(to: url)
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(av, animated: true)
    }
}

// MARK: - FindingRowCard (shared)
struct FindingRowCard: View {
    let finding: Finding
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(finding.severity.icon) \(finding.title)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(finding.severity.color)
                    .lineLimit(2)
                Spacer()
                SeverityBadge(severity: finding.severity)
            }
            if finding.category != nil || finding.mavsRef != nil || finding.cwe != nil {
                HStack(spacing: 4) {
                    if let cat = finding.category { TagView(text: cat) }
                    if let ref = finding.mavsRef  { TagView(text: "⊞ \(ref)", color: Color(hex: "00aaff")) }
                    if let cwe = finding.cwe       { TagView(text: "CWE-\(cwe)", color: Color(hex: "aa44ff")) }
                }
            }
            Text(finding.details.prefix(90) + (finding.details.count > 90 ? "..." : ""))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.textMuted)
                .lineSpacing(3)
        }
        .padding(13)
        .background(finding.severity.color.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(finding.severity.color.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Config Sheet
struct ConfigSheet: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    AppCard {
                        VStack(spacing: 12) {
                            LabeledField(label: "Suite REST API", text: $state.apiBase,
                                         placeholder: "http://localhost:8080", keyboardType: .URL)
                            LabeledField(label: "Target Package", text: $state.targetPackage,
                                         placeholder: "com.target.app")
                            LabeledField(label: "Claude API Key", text: $state.claudeApiKey,
                                         placeholder: "sk-ant-...", isSecure: true)
                        }
                    }
                    AppButton(title: "Save & Close", style: .green, isFullWidth: true) { dismiss() }
                    AppCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suite API Format")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "00aaff"))
                            Text("POST /api/drozer/execute\n{\"tool\": \"name\", \"args\": {}}\n\nPOST /api/recorder/start\nGET  /api/recorder/events/live\nPOST /api/recorder/stop")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.textMuted)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding(14)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .navBarBackground(Color(hex: "07090d"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.accent)
                }
            }
        }
    }
}
