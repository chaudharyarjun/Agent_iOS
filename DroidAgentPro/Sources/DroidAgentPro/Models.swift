import Foundation
import SwiftUI

// MARK: - Severity
enum Severity: String, CaseIterable, Codable {
    case CRITICAL, HIGH, MEDIUM, LOW, INFO

    var color: Color {
        switch self {
        case .CRITICAL: return Color(hex: "ff2d55")
        case .HIGH:     return Color(hex: "ff6b35")
        case .MEDIUM:   return Color(hex: "ffcc00")
        case .LOW:      return Color(hex: "00d4ff")
        case .INFO:     return Color(hex: "8888aa")
        }
    }

    var order: Int {
        switch self {
        case .CRITICAL: return 0
        case .HIGH:     return 1
        case .MEDIUM:   return 2
        case .LOW:      return 3
        case .INFO:     return 4
        }
    }

    var icon: String {
        switch self {
        case .CRITICAL: return "🔴"
        case .HIGH:     return "🟠"
        case .MEDIUM:   return "🟡"
        case .LOW:      return "🔵"
        case .INFO:     return "⚪"
        }
    }
}

// MARK: - Finding
struct Finding: Identifiable, Codable {
    let id: UUID
    var title: String
    var severity: Severity
    var category: String?
    var component: String?
    var details: String
    var proof: String?
    var remediation: String?
    var mavsRef: String?
    var cwe: String?
    var timestamp: Date

    init(title: String, severity: Severity, category: String? = nil,
         component: String? = nil, details: String, proof: String? = nil,
         remediation: String? = nil, mavsRef: String? = nil, cwe: String? = nil) {
        self.id = UUID()
        self.title = title
        self.severity = severity
        self.category = category
        self.component = component
        self.details = details
        self.proof = proof
        self.remediation = remediation
        self.mavsRef = mavsRef
        self.cwe = cwe
        self.timestamp = Date()
    }
}

// MARK: - Endpoint
struct Endpoint: Identifiable, Codable {
    let id: UUID
    var method: String
    var url: String
    var authenticated: Bool
    var params: [String: String]
    var statusCode: Int
    var requestId: String

    init(method: String, url: String, authenticated: Bool = false,
         params: [String: String] = [:], statusCode: Int = 200, requestId: String = UUID().uuidString) {
        self.id = UUID()
        self.method = method
        self.url = url
        self.authenticated = authenticated
        self.params = params
        self.statusCode = statusCode
        self.requestId = requestId
    }

    var methodColor: Color {
        switch method.uppercased() {
        case "GET":    return Color(hex: "00aaff")
        case "POST":   return Color(hex: "00ff88")
        case "DELETE": return Color(hex: "ff2d55")
        case "PUT":    return Color(hex: "ffcc00")
        default:       return Color(hex: "8888aa")
        }
    }
}

// MARK: - Component
struct AndroidComponent: Identifiable, Codable {
    let id: UUID
    var type: String  // activity, service, receiver, provider, deeplink
    var component: String?
    var action: String?
    var extras: [String: String]

    init(type: String, component: String? = nil, action: String? = nil, extras: [String: String] = [:]) {
        self.id = UUID()
        self.type = type
        self.component = component
        self.action = action
        self.extras = extras
    }

    var displayName: String { component ?? action ?? "Unknown" }

    var typeColor: Color {
        switch type {
        case "activity": return Color(hex: "00aaff")
        case "service":  return Color(hex: "aa44ff")
        case "receiver": return Color(hex: "ffcc00")
        case "provider": return Color(hex: "00ff88")
        case "deeplink": return Color(hex: "ff6b35")
        default:         return Color(hex: "8888aa")
        }
    }
}

// MARK: - Session
struct RecordingSession: Identifiable, Codable {
    let id: UUID
    var sessionId: String
    var timestamp: Date
    var events: [RecordedEvent]
    var endpoints: [Endpoint]
    var components: [AndroidComponent]

    init(sessionId: String) {
        self.id = UUID()
        self.sessionId = sessionId
        self.timestamp = Date()
        self.events = []
        self.endpoints = []
        self.components = []
    }
}

// MARK: - Recorded Event
struct RecordedEvent: Identifiable, Codable {
    let id: UUID
    var type: String  // http, intent, crypto, file, storage, auth
    var summary: String
    var timestamp: Date
    var raw: String?

    init(type: String, summary: String, raw: String? = nil) {
        self.id = UUID()
        self.type = type
        self.summary = summary
        self.timestamp = Date()
        self.raw = raw
    }

    var typeColor: Color {
        switch type {
        case "http":    return Color(hex: "00aaff")
        case "intent":  return Color(hex: "aa44ff")
        case "crypto":  return Color(hex: "ffcc00")
        case "file":    return Color(hex: "00ff88")
        case "auth":    return Color(hex: "ff2d55")
        default:        return Color(hex: "8888aa")
        }
    }
}

// MARK: - Log Entry
struct LogEntry: Identifiable {
    let id = UUID()
    var type: LogType
    var text: String
    var timestamp: Date = Date()

    enum LogType {
        case system, agent, think, toolCall, toolResult, vuln, error

        var color: Color {
            switch self {
            case .system:     return Color(hex: "00ff88")
            case .agent:      return Color(hex: "00aaff")
            case .think:      return Color(hex: "7788aa")
            case .toolCall:   return Color(hex: "ffcc00")
            case .toolResult: return Color(hex: "445566")
            case .vuln:       return Color(hex: "ff2d55")
            case .error:      return Color(hex: "ff4444")
            }
        }

        var isIndented: Bool { self == .think }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var apiBase: String {
        didSet { UserDefaults.standard.set(apiBase, forKey: "da_api") }
    }
    @Published var targetPackage: String {
        didSet { UserDefaults.standard.set(targetPackage, forKey: "da_pkg") }
    }
    @Published var claudeApiKey: String {
        didSet { UserDefaults.standard.set(claudeApiKey, forKey: "da_key") }
    }

    @Published var findings: [Finding] = []
    @Published var endpoints: [Endpoint] = []
    @Published var components: [AndroidComponent] = []
    @Published var sessions: [RecordingSession] = []
    @Published var activeSessionId: String? = nil

    @Published var logs: [LogEntry] = []
    @Published var isRunning: Bool = false
    @Published var isRecording: Bool = false
    @Published var currentPhase: String = "IDLE"
    @Published var toolCallCount: Int = 0
    @Published var recordingDuration: Int = 0
    @Published var liveEvents: [RecordedEvent] = []

    init() {
        self.apiBase       = UserDefaults.standard.string(forKey: "da_api") ?? "http://localhost:8080"
        self.targetPackage = UserDefaults.standard.string(forKey: "da_pkg") ?? ""
        self.claudeApiKey  = UserDefaults.standard.string(forKey: "da_key") ?? ""
    }

    var criticalCount: Int { findings.filter { $0.severity == .CRITICAL }.count }
    var highCount: Int     { findings.filter { $0.severity == .HIGH }.count }
    var mediumCount: Int   { findings.filter { $0.severity == .MEDIUM }.count }
    var lowCount:  Int     { findings.filter { $0.severity == .LOW }.count }

    func addLog(_ type: LogEntry.LogType, _ text: String) {
        DispatchQueue.main.async {
            self.logs.append(LogEntry(type: type, text: text))
        }
    }

    func addFinding(_ finding: Finding) {
        DispatchQueue.main.async {
            self.findings.append(finding)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    func addEndpoint(_ ep: Endpoint) {
        DispatchQueue.main.async {
            if !self.endpoints.contains(where: { $0.url == ep.url }) {
                self.endpoints.append(ep)
            }
        }
    }

    func addComponent(_ comp: AndroidComponent) {
        DispatchQueue.main.async {
            self.components.append(comp)
        }
    }

    func exportReport() -> Data? {
        let report: [String: Any] = [
            "target": targetPackage,
            "date": ISO8601DateFormatter().string(from: Date()),
            "summary": [
                "critical": criticalCount, "high": highCount,
                "medium": mediumCount, "low": lowCount,
                "endpoints": endpoints.count, "components": components.count,
                "tool_calls": toolCallCount
            ],
            "findings": findings.sorted { $0.severity.order < $1.severity.order }.map { f in [
                "title": f.title, "severity": f.severity.rawValue,
                "category": f.category ?? "", "component": f.component ?? "",
                "details": f.details, "proof": f.proof ?? "",
                "remediation": f.remediation ?? "",
                "masvs_ref": f.mavsRef ?? "", "cwe": f.cwe ?? ""
            ]}
        ]
        return try? JSONSerialization.data(withJSONObject: report, options: .prettyPrinted)
    }
}

// MARK: - Color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)         / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Claude Tool Definition
struct ClaudeTool: Codable {
    let name: String
    let description: String
    let input_schema: [String: AnyCodable]
}

struct AnyCodable: Codable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self)    { value = i; return }
        if let d = try? c.decode(Double.self)  { value = d; return }
        if let b = try? c.decode(Bool.self)    { value = b; return }
        if let s = try? c.decode(String.self)  { value = s; return }
        if let a = try? c.decode([AnyCodable].self) { value = a.map(\.value); return }
        if let o = try? c.decode([String: AnyCodable].self) { value = o.mapValues(\.value); return }
        value = NSNull()
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let i as Int:    try c.encode(i)
        case let d as Double: try c.encode(d)
        case let b as Bool:   try c.encode(b)
        case let s as String: try c.encode(s)
        case let a as [Any]:  try c.encode(a.map { AnyCodable($0) })
        case let o as [String: Any]: try c.encode(o.mapValues { AnyCodable($0) })
        default: try c.encodeNil()
        }
    }
}
