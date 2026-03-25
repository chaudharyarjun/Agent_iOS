import SwiftUI

struct RecorderView: View {
    @ObservedObject var state: AppState
    @ObservedObject var engine: AgentEngine

    var recTime: String {
        let m = state.recordingDuration / 60
        let s = state.recordingDuration % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    // Control Card
                    AppCard(accent: state.isRecording ? Color(hex: "ff2d55") : Color.border) {
                        VStack(alignment: .leading, spacing: 12) {
                            if state.isRecording {
                                HStack {
                                    Circle().fill(Color(hex: "ff2d55")).frame(width: 8, height: 8)
                                        .opacity(1).animation(.easeInOut(duration: 0.6).repeatForever(), value: state.isRecording)
                                    Text("RECORDING")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(hex: "ff2d55"))
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text(recTime)
                                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color(hex: "ff2d55"))
                                        Text("\(state.liveEvents.count) events")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.textMuted)
                                    }
                                }
                                Text("Interact with \(state.targetPackage) — log in, upload, browse, comment...")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.textMuted)
                                    .lineSpacing(3)
                                AppButton(title: "Stop & Analyze", icon: "⏹", style: .red, isFullWidth: true) {
                                    Task { await engine.stopRecording() }
                                }
                            } else {
                                Text("Session Recorder")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach([
                                        "1. Press Start Recording",
                                        "2. Use the target app — login, upload, browse",
                                        "3. All traffic, intents, crypto & storage captured",
                                        "4. Press Stop & Analyze",
                                        "5. Run Agent to attack everything recorded"
                                    ], id: \.self) { step in
                                        Text(step)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.textMuted)
                                            .lineSpacing(2)
                                    }
                                }
                                AppButton(title: "Start Recording", icon: "⏺", style: .blue,
                                          isFullWidth: true, isDisabled: state.targetPackage.isEmpty) {
                                    Task { await engine.startRecording() }
                                }
                            }
                        }
                    }

                    // Live feed
                    if state.isRecording && !state.liveEvents.isEmpty {
                        SectionTitle(text: "Live Event Feed")
                        AppCard {
                            VStack(spacing: 0) {
                                ForEach(state.liveEvents.suffix(15).reversed()) { evt in
                                    HStack(alignment: .top, spacing: 8) {
                                        EventBadge(type: evt.type)
                                        Text(evt.summary)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(Color(hex: "889aaa"))
                                            .lineLimit(2)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(evt.timestamp, style: .time)
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.textDim)
                                    }
                                    .padding(.vertical, 6)
                                    if evt.id != state.liveEvents.suffix(15).first?.id {
                                        Divider().background(Color.border)
                                    }
                                }
                            }
                        }
                    }

                    // What's captured
                    SectionTitle(text: "Captured Hooks")
                    let captures: [(String, String, [String])] = [
                        ("🌐", "HTTP Traffic",    ["Request/response headers","Auth tokens & cookies","Request bodies","TLS handshake"]),
                        ("⚙️", "Android Intents",  ["Activity launches","Service binds","Broadcast sends","Deeplink invocations"]),
                        ("🔐", "Crypto Ops",       ["Encryption keys","IV values","Cipher algorithms","KeyStore access"]),
                        ("🗄️", "Storage Access",   ["Files read/written","SQLite queries","SharedPreferences","External storage"]),
                        ("🔑", "Auth & Session",   ["Login attempts","Session tokens","OAuth flows","Biometric calls"]),
                        ("🔒", "Network Security", ["Certificate chains","Pinning logic","TrustManagers","Proxy detection"]),
                    ]
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(captures, id: \.0) { (icon, title, items) in
                            AppCard(padding: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(icon) \(title)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.primary)
                                    ForEach(items, id: \.self) { item in
                                        Text("· \(item)")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.textMuted)
                                    }
                                }
                            }
                        }
                    }

                    // Past sessions
                    if !state.sessions.isEmpty {
                        SectionTitle(text: "Recorded Sessions (\(state.sessions.count))")
                        ForEach(state.sessions) { session in
                            AppCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.sessionId)
                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                            .foregroundColor(.primary)
                                        Text("\(session.timestamp, style: .date) · \(session.events.count) events · \(session.endpoints.count) endpoints")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.textMuted)
                                    }
                                    Spacer()
                                    AppButton(title: "Attack", icon: "▶", style: .green, isSmall: true) {
                                        state.activeSessionId = session.sessionId
                                        Task { await engine.run(context: "session \(session.sessionId)") }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Session Recorder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "07090d"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
