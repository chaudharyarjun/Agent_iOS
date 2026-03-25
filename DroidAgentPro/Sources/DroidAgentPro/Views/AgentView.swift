import SwiftUI

// MARK: - Agent View
struct AgentView: View {
    @ObservedObject var state: AppState
    @ObservedObject var engine: AgentEngine
    @State private var agentMode: AgentMode = .full

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                AgentModeSelector(agentMode: $agentMode)
                Divider().background(Color.border)
                AgentTerminal(state: state)
                Divider().background(Color.border)
                AgentToolbar(state: state, engine: engine, agentMode: $agentMode)
            }
            .background(Color(hex: "020406").ignoresSafeArea())
            .navigationTitle("Agent Terminal")
            .navigationBarTitleDisplayMode(.inline)
            .navBarBackground(Color(hex: "07090d"))
        }
    }
}

// MARK: - Agent Mode
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

// MARK: - Mode Selector
struct AgentModeSelector: View {
    @Binding var agentMode: AgentMode

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(AgentMode.allCases, id: \.self) { mode in
                    AgentModeButton(mode: mode, isSelected: agentMode == mode) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            agentMode = mode
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color.bg2)
    }
}

struct AgentModeButton: View {
    let mode: AgentMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(mode.rawValue.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .accent : .textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accent.opacity(0.1) : Color.clear)
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color.accent.opacity(0.4) : Color.border2,
                        lineWidth: 1
                    )
                )
                .clipShape(Capsule())
        }
    }
}

// MARK: - Terminal
struct AgentTerminal: View {
    @ObservedObject var state: AppState

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 2) {
                    terminalContent
                }
                .padding(12)
            }
            .background(Color(hex: "020406"))
            .onChange(of: state.logs.count) { _ in
                withAnimation {
                    if state.isRunning {
                        proxy.scrollTo("cursor")
                    } else {
                        proxy.scrollTo(state.logs.last?.id)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var terminalContent: some View {
        if state.logs.isEmpty {
            TerminalEmptyState()
        } else {
            ForEach(state.logs) { log in
                LogLineView(log: log).id(log.id)
            }
            if state.isRunning {
                Text("▌")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.accent)
                    .id("cursor")
            }
        }
    }
}

struct TerminalEmptyState: View {
    var body: some View {
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
    }
}

// MARK: - Toolbar
struct AgentToolbar: View {
    @ObservedObject var state: AppState
    @ObservedObject var engine: AgentEngine
    @Binding var agentMode: AgentMode

    var body: some View {
        HStack(spacing: 10) {
            toolbarStatus
            Spacer()
            if !state.isRunning && !state.logs.isEmpty {
                AppButton(title: "Clear", style: .dim, isSmall: true) {
                    state.logs = []
                }
            }
            if state.isRunning {
                AppButton(title: "Abort", icon: "⊘", style: .red, isSmall: true) {
                    engine.abort()
                }
            } else {
                AppButton(
                    title: "Launch",
                    icon: "▶",
                    style: .green,
                    isSmall: true,
                    isDisabled: state.targetPackage.isEmpty || state.claudeApiKey.isEmpty
                ) {
                    Task { await engine.run(context: agentMode.context) }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.bg2)
    }

    @ViewBuilder
    private var toolbarStatus: some View {
        if state.isRunning {
            StatusPill(text: "\(state.currentPhase) · \(state.toolCallCount) calls", animate: true)
        } else if !state.logs.isEmpty {
            Text("Done · \(state.toolCallCount) calls · \(state.findings.count) findings")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.textMuted)
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
