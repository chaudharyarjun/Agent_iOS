import SwiftUI

struct SurfaceView: View {
    @ObservedObject var state: AppState
    @ObservedObject var engine: AgentEngine
    @State private var filter: SurfaceFilter = .all
    @State private var selectedEndpoint: Endpoint? = nil
    @State private var selectedComponent: AndroidComponent? = nil

    enum SurfaceFilter: String, CaseIterable {
        case all, http, activity, service, receiver, provider, deeplink
        var label: String { rawValue.uppercased() }
    }

    var filteredEndpoints: [Endpoint] {
        filter == .all || filter == .http ? state.endpoints : []
    }
    var filteredComponents: [AndroidComponent] {
        guard filter != .http else { return [] }
        return state.components.filter { filter == .all || $0.type == filter.rawValue }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(SurfaceFilter.allCases, id: \.self) { f in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) { filter = f }
                            } label: {
                                Text(f.label)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(filter == f ? .accent : .textMuted)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(filter == f ? Color.accent.opacity(0.1) : Color.clear)
                                    .overlay(Capsule().stroke(filter == f ? Color.accent.opacity(0.4) : Color.border2, lineWidth: 1))
                                    .clipShape(Capsule())
                            }
                        }
                        Spacer()
                        AppButton(title: "Attack All", icon: "▶", style: .green, isSmall: true) {
                            Task { await engine.run(context: "all discovered endpoints and components") }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .background(Color.bg2)
                Divider().background(Color.border)

                if state.endpoints.isEmpty && state.components.isEmpty {
                    emptyState
                } else {
                    List {
                        if !filteredEndpoints.isEmpty {
                            Section {
                                ForEach(filteredEndpoints) { ep in
                                    EndpointRow(ep: ep, engine: engine)
                                        .listRowBackground(Color.bg2)
                                        .listRowSeparatorTint(Color.border)
                                }
                            } header: {
                                Text("HTTP ENDPOINTS (\(filteredEndpoints.count))")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.textMuted)
                                    .kerning(2)
                            }
                        }
                        if !filteredComponents.isEmpty {
                            Section {
                                ForEach(filteredComponents) { comp in
                                    ComponentRow(comp: comp, engine: engine)
                                        .listRowBackground(Color.bg2)
                                        .listRowSeparatorTint(Color.border)
                                }
                            } header: {
                                Text("COMPONENTS (\(filteredComponents.count))")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.textMuted)
                                    .kerning(2)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color.bg)
                }
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Attack Surface")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "07090d"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Text("\(state.endpoints.count + state.components.count)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.accent)
                        Text("items")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.textMuted)
                    }
                }
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 14) {
            Text("🗺").font(.system(size: 48))
            Text("Attack Surface Empty")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.textMuted)
            Text("Record a session or run the agent to populate the attack surface map.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.textDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            HStack(spacing: 10) {
                AppButton(title: "Run Recon", icon: "▶", style: .green) {
                    Task { await engine.run(context: "recon only, enumerate all components") }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Endpoint Row
struct EndpointRow: View {
    let ep: Endpoint
    @ObservedObject var engine: AgentEngine
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation { expanded.toggle() } } label: {
                HStack(spacing: 8) {
                    Text(ep.method)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(ep.methodColor)
                        .frame(width: 38, alignment: .leading)
                    Image(systemName: ep.authenticated ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 9))
                        .foregroundColor(ep.authenticated ? .accent : Color(hex: "ff6b35"))
                    Text(ep.url)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(hex: "9aaabb"))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: 6) {
                    Divider().background(Color.border)
                    HStack(spacing: 6) {
                        AppButton(title: "Fuzz", style: .dim, isSmall: true) {
                            Task { await engine.run(context: "fuzz endpoint \(ep.url) with sqli xss traversal") }
                        }
                        AppButton(title: "IDOR", style: .red, isSmall: true) {
                            Task { await engine.run(context: "test IDOR on endpoint \(ep.url)") }
                        }
                        AppButton(title: "Strip Auth", style: .blue, isSmall: true) {
                            Task { await engine.run(context: "strip auth and replay \(ep.url)") }
                        }
                    }
                    if !ep.params.isEmpty {
                        Text("Params: \(ep.params.keys.joined(separator: ", "))")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.bottom, 6)
            }
        }
    }
}

// MARK: - Component Row
struct ComponentRow: View {
    let comp: AndroidComponent
    @ObservedObject var engine: AgentEngine
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation { expanded.toggle() } } label: {
                HStack(spacing: 8) {
                    Text(comp.type.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(comp.typeColor)
                        .frame(width: 60, alignment: .leading)
                    Text(comp.displayName)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(hex: "9aaabb"))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: 6) {
                    Divider().background(Color.border)
                    HStack(spacing: 6) {
                        AppButton(title: "Attack", icon: "▶", style: .green, isSmall: true) {
                            Task { await engine.run(context: "attack component \(comp.displayName)") }
                        }
                        if comp.type == "provider" {
                            AppButton(title: "SQLi", style: .red, isSmall: true) {
                                Task { await engine.run(context: "test SQLi on provider \(comp.displayName)") }
                            }
                        }
                    }
                }
                .padding(.bottom, 6)
            }
        }
    }
}
