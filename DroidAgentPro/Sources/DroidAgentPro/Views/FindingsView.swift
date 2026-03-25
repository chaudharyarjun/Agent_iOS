import SwiftUI

struct FindingsView: View {
    @ObservedObject var state: AppState
    @ObservedObject var engine: AgentEngine
    @State private var severityFilter: Severity? = nil
    @State private var selectedFinding: Finding? = nil
    @State private var showExportSheet = false
    @State private var exportData: Data? = nil

    var filtered: [Finding] {
        let sorted = state.findings.sorted { $0.severity.order < $1.severity.order }
        guard let f = severityFilter else { return sorted }
        return sorted.filter { $0.severity == f }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterStrip
                Divider().background(Color.border)
                if filtered.isEmpty {
                    emptyState
                } else {
                    findingsList
                }
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Findings (\(state.findings.count))")
            .navigationBarTitleDisplayMode(.inline)
            .navBarBackground(Color(hex: "07090d"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if let data = state.exportReport() {
                            exportData = data
                            showExportSheet = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.accent)
                    }
                }
            }
            .sheet(item: $selectedFinding) { finding in
                FindingDetailSheet(finding: finding)
            }
            .sheet(isPresented: $showExportSheet) {
                if let data = exportData {
                    ShareSheetView(data: data, filename: "\(state.targetPackage)_pentest.json")
                }
            }
        }
    }

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterButton(label: "ALL (\(state.findings.count))", color: .accent, isActive: severityFilter == nil) {
                    severityFilter = nil
                }
                ForEach(Severity.allCases, id: \.self) { sev in
                    let count = state.findings.filter { $0.severity == sev }.count
                    filterButton(label: "\(sev.rawValue) (\(count))", color: sev.color, isActive: severityFilter == sev) {
                        severityFilter = (severityFilter == sev) ? nil : sev
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color.bg2)
    }

    private var findingsList: some View {
        List {
            ForEach(filtered) { finding in
                Button { selectedFinding = finding } label: {
                    FindingListRow(finding: finding)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.bg2)
                .listRowSeparatorTint(Color.border)
                .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
            }
        }
        .listStyle(.plain)
        .listBackground(Color.bg)
        .background(Color.bg)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("🔍").font(.system(size: 48))
            Text("No Findings Yet")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.textMuted)
            Text("Run the agent to discover vulnerabilities.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.textDim)
            AppButton(title: "Run Agent", icon: "▶", style: .green) {
                Task { await engine.run() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func filterButton(label: String, color: Color, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(isActive ? color : .textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isActive ? color.opacity(0.12) : Color.clear)
                .overlay(Capsule().stroke(isActive ? color.opacity(0.5) : Color.border2, lineWidth: 1))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Finding List Row
struct FindingListRow: View {
    let finding: Finding
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text("\(finding.severity.icon) \(finding.title)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(finding.severity.color)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                SeverityBadge(severity: finding.severity)
            }
            if finding.category != nil || finding.mavsRef != nil || finding.cwe != nil {
                HStack(spacing: 4) {
                    if let cat = finding.category { TagView(text: cat) }
                    if let ref = finding.mavsRef  { TagView(text: "⊞ \(ref)", color: Color(hex: "00aaff")) }
                    if let cwe = finding.cwe      { TagView(text: "CWE-\(cwe)", color: Color(hex: "aa44ff")) }
                }
            }
            Text(finding.details.prefix(100) + (finding.details.count > 100 ? "..." : ""))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.textMuted)
                .lineSpacing(2)
            if let comp = finding.component {
                HStack(spacing: 4) {
                    Image(systemName: "cube.fill").font(.system(size: 8))
                    Text(comp)
                }
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Color(hex: "334455"))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Finding Detail Sheet
struct FindingDetailSheet: View {
    let finding: Finding
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        Text(finding.title)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(finding.severity.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SeverityBadge(severity: finding.severity)
                    }
                    HStack(spacing: 6) {
                        if let cat = finding.category { TagView(text: cat) }
                        if let ref = finding.mavsRef  { TagView(text: "⊞ \(ref)", color: Color(hex: "00aaff")) }
                        if let cwe = finding.cwe      { TagView(text: "CWE-\(cwe)", color: Color(hex: "aa44ff")) }
                    }
                    if let comp = finding.component { infoRow("Component", value: comp) }
                    detailBlock("Details", text: finding.details, color: Color(hex: "8899aa"))
                    if let proof = finding.proof {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(text: "Proof / PoC")
                            Text(proof)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color(hex: "6677aa"))
                                .lineSpacing(3)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(hex: "020408"))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    if let rem = finding.remediation {
                        detailBlock("Remediation", text: rem, color: Color(hex: "556677"))
                    }
                }
                .padding(16)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle(finding.severity.rawValue)
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

    func infoRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.textMuted)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color(hex: "8899aa"))
        }
    }

    func detailBlock(_ title: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: title)
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(color)
                .lineSpacing(4)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheetView: UIViewControllerRepresentable {
    let data: Data
    let filename: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
