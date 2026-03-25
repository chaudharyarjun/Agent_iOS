import SwiftUI

struct AgentView: View {
    @ObservedObject var state: AppState
    @ObservedObject var engine: AgentEngine
    @State private var agentMode: AgentMode = .full
    @State private var scrollProxy: ScrollViewProxy? = nil

    enum AgentMode: String, CaseIterable {
        case full    = "Full Attack"
        case auth    = "Auth Only"
        case traffic = "Traffic"
        case storage = "Storage"
        case comps   = "Components"

        var context: String? {
            switch self {
            case .full:    return nil
            case .auth:    return "focus only on authentication and session testing: JWT, session fixation, brute force, biometrics"
            case .traffic: return "focus on captured HTTP traffic: replay, fuzz, IDOR, strip auth"
            case .storage: return "focus on storage: SharedPrefs, SQLite, external storage, clipboard"
            case .comps:   return "focus on Android components: activities, services, receivers, providers"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mode selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(AgentMode.allCases, id: \.self) { mode in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) { agentMode = mode }
                            } label: {
                                Text(mode.rawValue.uppercased())
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(agentMode == mode ? .accent : .textMuted)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(agentMode == mode ? Color.accent.opacity(0.1) : Color.clear)
                                    .overlay(Capsule().stroke(agentMode == mode ? Color.accent.opacity(0.4) : Color.border2, lineWidth: 1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .background(Color.bg2)
                Divider().background(Color.border)

                // Terminal
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            if state.logs.isEmpty {
                                VStack(spacing: 12) {
                                    Text("⬡").font(.system(size: 48))
                                    Text("Configure target and launch")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(.textMuted)
                                    Text("40+ tools · Drozer · Frida · JWT · WebView · Upload")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.textDim)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            } else {
                                ForEach(state.logs) { log in
                                    LogLineView(log: log)
                                        .id(log.id)
                                }
                                if state.isRunning {
                                    Text("▌")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(.accent)
                                        .id("cursor")
                                }
                            }
                        }
                        .padding(12)
                    }
                    .background(Color(hex: "020406"))
                    .onChange(of: state.logs.count) { _ in
                        withAnimation { proxy.scrollTo(state.isRunning ? "cursor" : state.logs.last?.id) }
                    }
                }

                Divider().background(Color.border)

                // Bottom toolbar
                HStack(spacing: 10) {
                    if state.isRunning {
                        StatusPill(text: "\(state.currentPhase) · \(state.toolCallCount) calls", animate: true)
                    } else if !state.logs.isEmpty {
                        Text("Done · \(state.toolCallCount) calls · \(state.findings.count) findings")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.textMuted)
                    }
                    Spacer()
                    if !state.isRunning {
                        AppButton(title: "Clear", style: .dim, isSmall: true) {
                            state.logs = []
                        }
                    }
                    if state.isRunning {
                        AppButton(title: "Abort", icon: "⊘", style: .red, isSmall: true) {
                            engine.abort()
                        }
                    } else {
                        AppButton(title: "Launch", icon: "▶", style: .green, isSmall: true,
                                  isDisabled: state.targetPackage.isEmpty || state.claudeApiKey.isEmpty) {
                            Task { await engine.run(context: agentMode.context) }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.bg2)
            }
            .background(Color(hex: "020406").ignoresSafeArea())
            .navigationTitle("Agent Terminal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "07090d"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Log Line
struct LogLineView: View {
    let log: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(log.timestamp, style: .time)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Color(hex: "1e2a38"))
                .frame(width: 60, alignment: .leading)
            Text(log.text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(log.type.color.opacity(log.type == .toolResult ? 0.5 : 1))
                .lineLimit(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, log.type.isIndented ? 12 : 0)
        .overlay(alignment: .leading) {
            if log.type.isIndented {
                Rectangle()
                    .fill(Color(hex: "1e2a38"))
                    .frame(width: 2)
            }
        }
    }
}
